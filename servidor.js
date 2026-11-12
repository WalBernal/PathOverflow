// Repetidor de Path Overflow (prototipo, T262): un programa pequeño por el que pasan las
// partidas por internet. Los juegos no se conectan entre sí: el anfitrión y cada invitado
// se conectan a este servidor por WebSocket (salen de su red como cualquier página web,
// sin abrir puertos y también por datos móviles) y él reenvía lo que dice cada uno a los
// demás de su sala. No entiende ni guarda nada de la partida.
//
// Sin dependencias: solo Node (18 o más).   node tools/repetidor/servidor.js
//   PORT (o PUERTO): puerto en el que escucha (por defecto 47240).
//
// Protocolo:
//   - Conexión: ws://servidor/?sala=CODIGO&rol=anfitrion|invitado&v=VERSION
//   - Al entrar, el servidor manda un texto JSON: {"t":"hola","id":N,"peers":[ids]}.
//     El anfitrión es siempre el 1; cada invitado recibe un id propio.
//   - A los demás de la sala: {"t":"entra","id":N} y, al irse, {"t":"sale","id":N}.
//     Si se va el anfitrión, la sala se cierra para todos ({"t":"fin"}).
//   - Si no se puede entrar: {"t":"no","motivo":"sala"|"llena"|"version"|"ocupada"} y se cierra.
//   - Datos: tramas binarias. Los 4 primeros bytes (entero con signo, little-endian) son el
//     destino (0 = todos los demás); el servidor los cambia por el id de quien lo envía y
//     reenvía el resto tal cual.
'use strict';
const http = require('http');
const crypto = require('crypto');

const PORT = Number(process.env.PORT || process.env.PUERTO || 47240);
const MAX_PLAYERS = 4;
const MAX_ROOMS = 200;
const MAX_FRAME = 512 * 1024;          // bytes por mensaje
const MAX_BYTES_PER_SECOND = 256 * 1024; // por conexión
const IDLE_MS = 60 * 1000;             // sin tráfico: fuera

/** @type {Map<string, {version: string, peers: Map<number, any>}>} */
const rooms = new Map();
let nextGuest = 2;

const server = http.createServer((req, res) => {
  // Una página mínima: sirve para comprobar que está vivo (y para despertarlo si dormía).
  res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
  res.end(`Repetidor de Path Overflow: ${rooms.size} sala(s).\n`);
});

server.on('upgrade', (req, socket) => {
  const key = req.headers['sec-websocket-key'];
  if (!key || String(req.headers.upgrade || '').toLowerCase() !== 'websocket') {
    socket.destroy();
    return;
  }
  const accept = crypto.createHash('sha1').update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64');
  socket.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ' + accept + '\r\n\r\n');
  socket.setNoDelay(true);
  const url = new URL(req.url, 'http://x');
  const code = String(url.searchParams.get('sala') || '').toUpperCase().slice(0, 24);
  const role = url.searchParams.get('rol') === 'anfitrion' ? 'anfitrion' : 'invitado';
  const version = String(url.searchParams.get('v') || '').slice(0, 16);
  const conn = { socket, id: 0, room: null, buffer: Buffer.alloc(0), parts: [], partsOp: 0, last: Date.now(), windowStart: Date.now(), windowBytes: 0, closed: false };

  const refuse = (why) => { sendText(conn, { t: 'no', motivo: why }); close(conn); };
  if (!/^[A-Z0-9-]{3,24}$/.test(code)) return refuse('sala');
  let room = rooms.get(code);
  if (role === 'anfitrion') {
    if (room) return refuse('ocupada');
    if (rooms.size >= MAX_ROOMS) return refuse('llena');
    room = { version, peers: new Map() };
    rooms.set(code, room);
    conn.id = 1;
  } else {
    if (!room) return refuse('sala');
    if (room.version !== version) return refuse('version');
    if (room.peers.size >= MAX_PLAYERS) return refuse('llena');
    conn.id = nextGuest++;
    if (nextGuest > 0x7ffffff0) nextGuest = 2;
  }
  conn.room = code;
  sendText(conn, { t: 'hola', id: conn.id, peers: [...room.peers.keys()] });
  for (const other of room.peers.values()) sendText(other, { t: 'entra', id: conn.id });
  room.peers.set(conn.id, conn);

  socket.on('data', (chunk) => onData(conn, chunk));
  socket.on('close', () => leave(conn));
  socket.on('error', () => leave(conn));
});

function onData(conn, chunk) {
  conn.last = Date.now();
  if (conn.last - conn.windowStart > 1000) { conn.windowStart = conn.last; conn.windowBytes = 0; }
  conn.windowBytes += chunk.length;
  if (conn.windowBytes > MAX_BYTES_PER_SECOND) return close(conn);
  conn.buffer = conn.buffer.length ? Buffer.concat([conn.buffer, chunk]) : chunk;
  for (;;) {
    const buf = conn.buffer;
    if (buf.length < 2) return;
    const fin = (buf[0] & 0x80) !== 0;
    const opcode = buf[0] & 0x0f;
    const masked = (buf[1] & 0x80) !== 0;
    let len = buf[1] & 0x7f;
    let offset = 2;
    if (len === 126) { if (buf.length < 4) return; len = buf.readUInt16BE(2); offset = 4; }
    else if (len === 127) { if (buf.length < 10) return; const big = buf.readBigUInt64BE(2); if (big > BigInt(MAX_FRAME)) return close(conn); len = Number(big); offset = 10; }
    if (len > MAX_FRAME || !masked) return close(conn);   // los clientes siempre enmascaran
    if (buf.length < offset + 4 + len) return;
    const mask = buf.subarray(offset, offset + 4);
    const payload = Buffer.allocUnsafe(len);
    for (let i = 0; i < len; i++) payload[i] = buf[offset + 4 + i] ^ mask[i & 3];
    conn.buffer = buf.subarray(offset + 4 + len);
    if (opcode === 0x8) return close(conn);
    if (opcode === 0x9) { frame(conn, 0xA, payload); continue; }   // ping -> pong
    if (opcode === 0xA) continue;
    if (opcode === 0x1 || opcode === 0x2) { conn.parts = [payload]; conn.partsOp = opcode; }
    else if (opcode === 0x0) { conn.parts.push(payload); if (conn.parts.reduce((n, p) => n + p.length, 0) > MAX_FRAME) return close(conn); }
    if (fin && conn.partsOp) {
      const whole = conn.parts.length === 1 ? conn.parts[0] : Buffer.concat(conn.parts);
      const op = conn.partsOp;
      conn.parts = []; conn.partsOp = 0;
      if (op === 0x2) relay(conn, whole);   // (los textos de los clientes no se usan)
    }
  }
}

function relay(conn, data) {
  const room = rooms.get(conn.room);
  if (!room || data.length < 4) return;
  const target = data.readInt32LE(0);
  data.writeInt32LE(conn.id, 0);
  if (target === 0) {
    for (const other of room.peers.values()) if (other !== conn) frame(other, 0x2, data);
  } else {
    const other = room.peers.get(target);
    if (other && other !== conn) frame(other, 0x2, data);
  }
}

function frame(conn, opcode, payload) {
  if (conn.closed) return;
  const len = payload.length;
  let head;
  if (len < 126) { head = Buffer.from([0x80 | opcode, len]); }
  else if (len < 65536) { head = Buffer.alloc(4); head[0] = 0x80 | opcode; head[1] = 126; head.writeUInt16BE(len, 2); }
  else { head = Buffer.alloc(10); head[0] = 0x80 | opcode; head[1] = 127; head.writeBigUInt64BE(BigInt(len), 2); }
  conn.socket.write(head);
  conn.socket.write(payload);
}

function sendText(conn, obj) { frame(conn, 0x1, Buffer.from(JSON.stringify(obj), 'utf8')); }

function close(conn) {
  if (conn.closed) return;
  frame(conn, 0x8, Buffer.alloc(0));
  conn.closed = true;
  conn.socket.end();
  leave(conn);
}

function leave(conn) {
  conn.closed = true;
  const room = rooms.get(conn.room);
  conn.room = null;
  if (!room || room.peers.get(conn.id) !== conn) return;
  room.peers.delete(conn.id);
  if (conn.id === 1) {
    // Se fue el anfitrión: la sala se acaba para todos.
    for (const other of [...room.peers.values()]) { sendText(other, { t: 'fin' }); close(other); }
    for (const [code, r] of rooms) if (r === room) rooms.delete(code);
  } else {
    for (const other of room.peers.values()) sendText(other, { t: 'sale', id: conn.id });
  }
}

setInterval(() => {
  const now = Date.now();
  for (const room of rooms.values()) for (const conn of [...room.peers.values()]) if (now - conn.last > IDLE_MS) close(conn);
}, 10 * 1000).unref();

server.listen(PORT, () => console.log(`Repetidor de Path Overflow escuchando en el puerto ${PORT}`));
