// Repetidor de Path Overflow (T262-T263): un programa pequeño por el que pasan las partidas
// por internet. Los juegos no se conectan entre sí: el anfitrión y cada invitado se
// conectan a este servidor por WebSocket (salen de su red como cualquier página web, sin
// abrir puertos y también por datos móviles) y él reenvía lo que dice cada uno a los demás
// de su sala. No entiende ni guarda nada de la partida.
//
// Sin dependencias: solo Node (18 o más).   node servidor.js
//   PORT (o PUERTO): puerto en el que escucha (por defecto 47240).
//   NUBE_URL y NUBE_CLAVE_PUBLICA: la dirección y la clave **pública** del proyecto de
//     cuentas (Supabase). Con las dos puestas, solo entra quien tenga la sesión de su cuenta
//     iniciada (para poder cortar a quien moleste). Sin ellas entra cualquiera: para
//     probar en un equipo. Aquí nunca va una clave secreta.
//
// Protocolo:
//   - Conexión: ws://servidor/?sala=CODIGO&rol=anfitrion|invitado&v=VERSION
//   - Lo primero que manda el juego es un texto JSON {"token":"…"} con su sesión (vacío si
//     no tiene). El servidor la comprueba con el servicio de cuentas y no la guarda.
//   - Al entrar, el servidor manda {"t":"hola","id":N,"peers":[ids]}. El anfitrión es
//     siempre el 1; cada invitado recibe un id propio.
//   - A los demás de la sala: {"t":"entra","id":N} y, al irse, {"t":"sale","id":N}.
//     Si se va el anfitrión, la sala se cierra para todos ({"t":"fin"}).
//   - Si no se puede entrar: {"t":"no","motivo":…} y se cierra. Motivos: "sala" (no existe o
//     código mal escrito), "llena", "version", "ocupada" (ya hay una con ese código),
//     "cuenta" (sin sesión válida), "repetida" (esa cuenta ya está en la sala).
//   - Datos: tramas binarias. Los 4 primeros bytes (entero con signo, little-endian) son el
//     destino (0 = todos los demás); el servidor los cambia por el id de quien lo envía y
//     reenvía el resto tal cual.
'use strict';
const http = require('http');
const crypto = require('crypto');

const MAX_PLAYERS = 4;
const MAX_ROOMS = 200;
const MAX_FRAME = 512 * 1024;            // bytes por mensaje
const MAX_BYTES_PER_SECOND = 256 * 1024; // por conexión
const IDLE_MS = 60 * 1000;               // sin tráfico: fuera
const AUTH_MS = 10 * 1000;               // para presentarse

/**
 * Arranca un repetidor. `options`: {port, authUrl, authKey, quiet}.
 * Devuelve {server, rooms, close()}.
 */
function start(options = {}) {
  const port = Number(options.port ?? process.env.PORT ?? process.env.PUERTO ?? 47240);
  const authUrl = String(options.authUrl ?? process.env.NUBE_URL ?? '').replace(/\/+$/, '');
  const authKey = String(options.authKey ?? process.env.NUBE_CLAVE_PUBLICA ?? '');
  const withAuth = authUrl !== '' && authKey !== '';
  if (/^sb_secret_|service_role/.test(authKey)) throw new Error('NUBE_CLAVE_PUBLICA es una clave secreta: aquí va la pública.');

  /** @type {Map<string, {version: string, peers: Map<number, any>}>} */
  const rooms = new Map();
  let nextGuest = 2;

  const server = http.createServer((req, res) => {
    // Una página mínima: sirve para comprobar que está vivo (y para despertarlo si dormía).
    res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8', 'cache-control': 'no-store' });
    res.end(`Repetidor de Path Overflow: ${rooms.size} sala(s).${withAuth ? ' Solo con cuenta.' : ''}\n`);
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
    const conn = {
      socket, id: 0, room: null, user: '', admitted: false, asking: false,
      code: String(url.searchParams.get('sala') || '').toUpperCase().slice(0, 24),
      role: url.searchParams.get('rol') === 'anfitrion' ? 'anfitrion' : 'invitado',
      version: String(url.searchParams.get('v') || '').slice(0, 16),
      buffer: Buffer.alloc(0), parts: [], partsOp: 0, last: Date.now(), windowStart: Date.now(), windowBytes: 0, closed: false,
    };
    socket.on('data', (chunk) => onData(conn, chunk));
    socket.on('close', () => leave(conn));
    socket.on('error', () => leave(conn));
    if (!/^[A-Z0-9-]{3,24}$/.test(conn.code)) return refuse(conn, 'sala');
    if (!withAuth) return admit(conn);
    conn.authTimer = setTimeout(() => { if (!conn.admitted) refuse(conn, 'cuenta'); }, AUTH_MS);
  });

  function refuse(conn, why) { sendText(conn, { t: 'no', motivo: why }); close(conn); }

  // Comprueba la sesión con el servicio de cuentas. No se guarda ni se registra el token.
  async function authenticate(conn, token) {
    if (conn.admitted || conn.asking || conn.closed) return;
    conn.asking = true;
    let user = '';
    try {
      if (typeof token === 'string' && token.length > 20 && token.length < 4096) {
        const r = await fetch(authUrl + '/auth/v1/user', { headers: { apikey: authKey, authorization: 'Bearer ' + token }, signal: AbortSignal.timeout(8000) });
        if (r.ok) { const j = await r.json(); if (j && typeof j.id === 'string') user = j.id; }
      }
    } catch { /* sin respuesta del servicio de cuentas: no entra */ }
    clearTimeout(conn.authTimer);
    if (conn.closed) return;
    if (user === '') return refuse(conn, 'cuenta');
    conn.user = user;
    admit(conn);
  }

  function admit(conn) {
    let room = rooms.get(conn.code);
    if (conn.role === 'anfitrion') {
      if (room) return refuse(conn, 'ocupada');
      if (rooms.size >= MAX_ROOMS) return refuse(conn, 'llena');
      room = { version: conn.version, peers: new Map() };
      rooms.set(conn.code, room);
      conn.id = 1;
    } else {
      if (!room) return refuse(conn, 'sala');
      if (room.version !== conn.version) return refuse(conn, 'version');
      if (room.peers.size >= MAX_PLAYERS) return refuse(conn, 'llena');
      if (conn.user !== '') for (const other of room.peers.values()) if (other.user === conn.user) return refuse(conn, 'repetida');
      conn.id = nextGuest++;
      if (nextGuest > 0x7ffffff0) nextGuest = 2;
    }
    conn.room = conn.code;
    conn.admitted = true;
    sendText(conn, { t: 'hola', id: conn.id, peers: [...room.peers.keys()] });
    for (const other of room.peers.values()) sendText(other, { t: 'entra', id: conn.id });
    room.peers.set(conn.id, conn);
  }

  function onData(conn, chunk) {
    conn.last = Date.now();
    if (conn.last - conn.windowStart > 1000) { conn.windowStart = conn.last; conn.windowBytes = 0; }
    conn.windowBytes += chunk.length;
    if (conn.windowBytes > MAX_BYTES_PER_SECOND) return close(conn);
    conn.buffer = conn.buffer.length ? Buffer.concat([conn.buffer, chunk]) : chunk;
    for (;;) {
      if (conn.closed) return;
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
        if (op === 0x2) { if (conn.admitted) relay(conn, whole); }
        else if (withAuth && !conn.admitted) {
          // El saludo: {"token":"…"}.
          let token = '';
          try { token = JSON.parse(whole.toString('utf8')).token; } catch { /* no era JSON */ }
          authenticate(conn, token);
        }
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
    clearTimeout(conn.authTimer);
    conn.socket.end();
    leave(conn);
  }

  function leave(conn) {
    conn.closed = true;
    clearTimeout(conn.authTimer);
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

  const sweep = setInterval(() => {
    const now = Date.now();
    for (const room of rooms.values()) for (const conn of [...room.peers.values()]) if (now - conn.last > IDLE_MS) close(conn);
  }, 10 * 1000);
  sweep.unref();

  server.listen(port, () => { if (!options.quiet) console.log(`Repetidor de Path Overflow escuchando en el puerto ${port}${withAuth ? ' (solo con cuenta)' : ' (sin pedir cuenta)'}`); });
  return { server, rooms, withAuth, close: () => new Promise((done) => { clearInterval(sweep); server.closeAllConnections?.(); server.close(() => done()); }) };
}

module.exports = { start };
if (require.main === module) start();
