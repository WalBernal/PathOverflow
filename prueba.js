// Prueba del repetidor (T263): lo arranca en este equipo junto a un servicio de cuentas de
// mentira y comprueba, con clientes WebSocket de verdad, quién entra y quién no, y que los
// mensajes llegan a quien tienen que llegar. Necesita Node 22 o más (cliente WebSocket).
//   node tools/repetidor/prueba.js        -> sale con código 1 si algo falla
'use strict';
const http = require('http');
const { start } = require('./servidor.js');

let failures = 0;
function check(ok, what) { if (!ok) { failures++; console.log('FALLO: ' + what); } }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Un cliente: junta lo que le llega y deja esperar a que pase algo.
function client(port, query, token) {
  const ws = new WebSocket(`ws://127.0.0.1:${port}/?${query}`);
  ws.binaryType = 'arraybuffer';
  const c = { ws, texts: [], data: [], closed: false };
  ws.addEventListener('open', () => { if (token !== undefined) ws.send(JSON.stringify({ token })); });
  ws.addEventListener('message', (e) => {
    if (typeof e.data === 'string') c.texts.push(JSON.parse(e.data));
    else c.data.push(Buffer.from(e.data));
  });
  ws.addEventListener('close', () => { c.closed = true; });
  ws.addEventListener('error', () => { c.closed = true; });
  c.until = async (cond, ms = 3000) => { const end = Date.now() + ms; while (Date.now() < end) { if (cond()) return true; await sleep(15); } return cond(); };
  c.said = (t) => c.texts.find((m) => m.t === t);
  c.send = (target, text) => { const b = Buffer.alloc(4 + Buffer.byteLength(text)); b.writeInt32LE(target, 0); b.write(text, 4); ws.send(b); };
  return c;
}

async function main() {
  if (typeof WebSocket === 'undefined') { console.log('Hace falta Node 22 o más para esta prueba.'); process.exit(1); }
  // El servicio de cuentas de mentira: acepta los tokens «bueno-…» y dice de quién son.
  let asked = 0;
  const accounts = http.createServer((req, res) => {
    asked++;
    const token = String(req.headers.authorization || '').replace('Bearer ', '');
    const ok = req.url === '/auth/v1/user' && req.headers.apikey === 'clave-publica' && token.startsWith('bueno-');
    res.writeHead(ok ? 200 : 401, { 'content-type': 'application/json' });
    res.end(JSON.stringify(ok ? { id: 'usuario-' + token.slice(6, 12) } : { msg: 'no' }));
  });
  await new Promise((r) => accounts.listen(47251, r));
  const good = (who) => 'bueno-' + who.padEnd(6, '_') + '-'.repeat(30);

  // --- Sin pedir cuenta (para probar en un equipo) ---
  const open = start({ port: 47250, authUrl: '', authKey: '', quiet: true });
  await sleep(100);
  check(!open.withAuth, 'sin dirección de cuentas, no las pide');
  let h = client(47250, 'sala=KERNEL-42&rol=anfitrion&v=5.4.0');
  check(await h.until(() => h.said('hola')) && h.said('hola').id === 1 && h.said('hola').peers.length === 0, 'el anfitrión abre la sala y es el 1');
  let g = client(47250, 'sala=kernel-42&rol=invitado&v=5.4.0');
  check(await g.until(() => g.said('hola')) && g.said('hola').id > 1 && g.said('hola').peers[0] === 1, 'el invitado entra (el código vale en minúsculas) y sabe que está el anfitrión');
  check(await h.until(() => h.said('entra')) && h.said('entra').id === g.said('hola').id, 'el anfitrión se entera de quién entra');
  g.send(1, 'hola anfitrión');
  h.send(0, 'hola a todos');
  check(await h.until(() => h.data.length === 1) && h.data[0].readInt32LE(0) === g.said('hola').id && h.data[0].subarray(4).toString() === 'hola anfitrión',
    'lo que manda el invitado llega al anfitrión con su id delante');
  check(await g.until(() => g.data.length === 1) && g.data[0].readInt32LE(0) === 1 && g.data[0].subarray(4).toString() === 'hola a todos', 'lo del anfitrión para todos llega al invitado');
  let g2 = client(47250, 'sala=KERNEL-42&rol=invitado&v=5.4.0');
  await g2.until(() => g2.said('hola'));
  g.send(g2.said('hola').id, 'entre invitados');
  check(await g2.until(() => g2.data.length === 1) && h.data.length === 1, 'un mensaje con destino solo le llega a ese destino');
  let wrong = client(47250, 'sala=KERNEL-42&rol=invitado&v=5.3.0');
  check(await wrong.until(() => wrong.said('no')) && wrong.said('no').motivo === 'version', 'otra versión: no entra');
  let nowhere = client(47250, 'sala=NOEXISTE-1&rol=invitado&v=5.4.0');
  check(await nowhere.until(() => nowhere.said('no')) && nowhere.said('no').motivo === 'sala', 'una sala que no existe: no entra');
  let dup = client(47250, 'sala=KERNEL-42&rol=anfitrion&v=5.4.0');
  check(await dup.until(() => dup.said('no')) && dup.said('no').motivo === 'ocupada', 'dos anfitriones con el mismo código: el segundo no');
  let bad = client(47250, 'sala=x&rol=invitado&v=5.4.0');
  check(await bad.until(() => bad.said('no')) && bad.said('no').motivo === 'sala', 'un código mal escrito: no entra');
  let g3 = client(47250, 'sala=KERNEL-42&rol=invitado&v=5.4.0');
  await g3.until(() => g3.said('hola'));
  let fifth = client(47250, 'sala=KERNEL-42&rol=invitado&v=5.4.0');
  check(await fifth.until(() => fifth.said('no')) && fifth.said('no').motivo === 'llena', 'caben cuatro: el quinto no');
  g2.ws.close();
  check(await h.until(() => h.texts.some((m) => m.t === 'sale' && m.id === g2.said('hola').id)), 'si un invitado se va, los demás se enteran');
  h.ws.close();
  check(await g.until(() => g.said('fin') && g.closed) && await g3.until(() => g3.closed), 'si se va el anfitrión, la sala se cierra para todos');
  await sleep(100);
  check(open.rooms.size === 0, 'y la sala desaparece');
  await open.close();

  // --- Solo con cuenta ---
  const closed = start({ port: 47250, authUrl: 'http://127.0.0.1:47251/', authKey: 'clave-publica', quiet: true });
  await sleep(100);
  check(closed.withAuth, 'con dirección y clave pública, pide cuenta');
  h = client(47250, 'sala=SUDO-7&rol=anfitrion&v=5.4.0', good('ana'));
  check(await h.until(() => h.said('hola')) && h.said('hola').id === 1, 'con la sesión iniciada, el anfitrión entra');
  const none = client(47250, 'sala=SUDO-7&rol=invitado&v=5.4.0', '');
  check(await none.until(() => none.said('no')) && none.said('no').motivo === 'cuenta', 'sin sesión: no entra');
  const fake = client(47250, 'sala=SUDO-7&rol=invitado&v=5.4.0', 'malo-' + 'x'.repeat(40));
  check(await fake.until(() => fake.said('no')) && fake.said('no').motivo === 'cuenta', 'con una sesión falsa: no entra');
  const sneaky = client(47250, 'sala=SUDO-7&rol=invitado&v=5.4.0');   // no dice nada y manda datos
  await sleep(200);
  if (sneaky.ws.readyState === 1) sneaky.send(1, 'colado');
  await sleep(200);
  check(h.data.length === 0, 'quien no se ha presentado no puede mandar nada a la sala');
  sneaky.ws.close();
  const same = client(47250, 'sala=SUDO-7&rol=invitado&v=5.4.0', good('ana'));
  check(await same.until(() => same.said('no')) && same.said('no').motivo === 'repetida', 'la misma cuenta dos veces en la sala: no');
  g = client(47250, 'sala=SUDO-7&rol=invitado&v=5.4.0', good('luis'));
  check(await g.until(() => g.said('hola')) && g.said('hola').peers[0] === 1 && asked === 4, 'otra cuenta con sesión entra, y cada entrada se comprobó con el servicio de cuentas');
  let threw = false;
  try { start({ port: 47259, authUrl: 'http://x', authKey: 'sb_secret_abc', quiet: true }); } catch { threw = true; }
  check(threw, 'con una clave secreta en vez de la pública, no arranca');
  h.ws.close();
  await sleep(100);
  await closed.close();
  await new Promise((r) => { accounts.closeAllConnections?.(); accounts.close(r); });
  console.log(`repetidor: ${failures} fallo(s)`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((e) => { console.log('FALLO: ' + (e && e.stack || e)); process.exit(1); });
