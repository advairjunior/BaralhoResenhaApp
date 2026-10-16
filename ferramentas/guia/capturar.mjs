// Fotos do guia /como-jogar: uma noite de exemplo, jogo por jogo, com selfies de careta.
import puppeteer from 'puppeteer-core';

// Uso: com o servidor rodando na 5091 (ver docs/GUIA_COMO_JOGAR.md),
//   node capturar.mjs ../../servidor/BaralhoResenhaApp.Api/Paginas/como-jogar
const pasta = process.argv[2];
const base = 'http://localhost:5091';
const espera = (ms) => new Promise((r) => setTimeout(r, ms));
async function api(metodo, rota, token, corpo, bytes) {
  const h = {}; if (token) h.Authorization = `Bearer ${token}`;
  let body;
  if (bytes) { h['Content-Type'] = 'image/jpeg'; body = Buffer.from(bytes); }
  else if (corpo !== undefined) { h['Content-Type'] = 'application/json'; body = JSON.stringify(corpo); }
  const r = await fetch(base + rota, { method: metodo, headers: h, body });
  const t = await r.text(); if (!r.ok) throw new Error(`${rota}: ${t}`); return t ? JSON.parse(t) : null;
}
await espera(2500);
const b = await puppeteer.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true });
const DICAS = ['euNunca', 'jokenpo', 'duelo', 'elogio', 'votacao', 'apontar', 'bebaSe', 'regra', 'casais', 'tribunal', 'elogios', 'correio', 'mimica'];

const pagina = async () => {
  const p = await b.newPage();
  await p.setViewport({ width: 390, height: 844, deviceScaleFactor: 2, isMobile: true });
  await p.goto(base + '/', { waitUntil: 'load' });
  await espera(4500);
  return p;
};
const p0 = await pagina();
const selfie = (emoji, cor) => p0.evaluate(async (emoji, cor) => {
  const c = document.createElement('canvas'); c.width = c.height = 360;
  const g = c.getContext('2d'); g.fillStyle = cor; g.fillRect(0, 0, 360, 360);
  g.font = '230px "Segoe UI Emoji"'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(emoji, 180, 195);
  const bl = await new Promise((r) => c.toBlob(r, 'image/jpeg', 0.85));
  return [...new Uint8Array(await bl.arrayBuffer())];
}, emoji, cor);
const ROSTOS = { Advair: ['😎', '#3b82f6'], 'Júlia': ['😂', '#ec4899'], Caio: ['🥴', '#10b981'], Bruna: ['🤭', '#f59e0b'], Edu: ['🤠', '#8b5cf6'], Fabi: ['😜', '#ef4444'] };
const fotos = {};
for (const [n, [e, c]] of Object.entries(ROSTOS)) fotos[n] = await selfie(e, c);

/// Sala nova com fotos; devolve tokens e ids.
const novaSala = async (nomes = ['Advair', 'Júlia', 'Caio', 'Bruna']) => {
  const ana = await api('POST', '/api/salas', null, { nome: nomes[0] });
  const sala = `/api/salas/${ana.codigo}`;
  const turma = { [nomes[0]]: ana.token };
  for (const n of nomes.slice(1)) turma[n] = (await api('POST', `${sala}/jogadores`, null, { nome: n })).token;
  for (const n of nomes) await api('PUT', `${sala}/jogadores/eu/foto`, turma[n], undefined, fotos[n]);
  const ids = Object.fromEntries((await api('GET', sala, ana.token)).jogadores.map((j) => [j.nome, j.id]));
  return { codigo: ana.codigo, sala, turma, ids, nomes: Object.fromEntries(Object.entries(ids).map(([n, id]) => [id, n])) };
};
const comecar = async (s, config, condicao = () => true) => {
  await api('PUT', `${s.sala}/configuracao`, s.turma.Advair, { zonaSegura: true, ...config });
  let v = await api('POST', `${s.sala}/comecar`, s.turma.Advair);
  let n = 0;
  while (!condicao(v.rodada) && n++ < 200) v = await api('POST', `${s.sala}/tirar`, s.turma.Advair, { rodada: v.rodada.numero });
  return v;
};
const abrir = async (s, nome, ajuste) => {
  const p = await pagina();
  if (ajuste) {
    await p.setRequestInterception(true);
    p.on('request', async (req) => {
      if (req.method() !== 'GET' || new URL(req.url()).pathname !== s.sala) return req.continue();
      const visao = await (await fetch(req.url(), { headers: req.headers() })).json();
      ajuste(visao);
      req.respond({ status: 200, contentType: 'application/json', body: JSON.stringify(visao) });
    });
  }
  await p.evaluate((c, t, d) => {
    localStorage.setItem(`flutter.sala_${c}`, JSON.stringify(t));
    localStorage.setItem('flutter.dicas_vistas', JSON.stringify(d));
  }, s.codigo, s.turma[nome], DICAS);
  await p.goto(`${base}/#/sala/${s.codigo}`, { waitUntil: 'load' });
  await p.reload({ waitUntil: 'load' });
  await espera(4500);
  return p;
};
const rolar = async (p, px) => {
  await p.mouse.move(195, 500);
  for (let feito = 0; feito < px; feito += 300) { await p.mouse.wheel({ deltaY: Math.min(300, px - feito) }); await espera(120); }
  await espera(900);
};
const foto = (p, nome) => p.screenshot({ path: `${pasta}/${nome}.jpg`, type: 'jpeg', quality: 78 });

// Início.
await foto(p0, 'inicio');

// Sala de espera e noites prontas.
let s = await novaSala();
let p = await abrir(s, 'Advair');
await rolar(p, 300);
await foto(p, 'sala');
await rolar(p, 600);
await foto(p, 'noites');
await p.close();

// Eu Nunca: responder e "conta essa história".
let v = await comecar(s, { nivel: 'Resenha', modos: ['EuNunca'] });
p = await abrir(s, 'Júlia');
await rolar(p, 450);
await foto(p, 'eununca');
await api('POST', `${s.sala}/respostas`, s.turma.Caio, { rodada: v.rodada.numero, resposta: 'ja' });
for (const n of ['Advair', 'Júlia', 'Bruna']) await api('POST', `${s.sala}/respostas`, s.turma[n], { rodada: v.rodada.numero, resposta: 'nunca' });
await espera(2500);
await rolar(p, 200);
await foto(p, 'historia');
await p.close();

// Votação: o suspense com a foto do mais votado.
s = await novaSala();
v = await comecar(s, { nivel: 'Resenha', modos: ['MaisProvavel'] }, (r) => r.votacao && !r.elogio && !r.duelistas.length);
p = await abrir(s, 'Bruna');
for (const [n, alvo] of [['Advair', 'Caio'], ['Júlia', 'Caio'], ['Caio', 'Júlia'], ['Bruna', 'Caio']])
  await api('POST', `${s.sala}/respostas`, s.turma[n], { rodada: v.rodada.numero, resposta: s.ids[alvo] });
await espera(4300);
await foto(p, 'votacao');
await p.close();

// Tribunal: o que quem vota vê.
s = await novaSala();
v = await comecar(s, { nivel: 'Resenha', modos: ['Tribunal'] }, (r) => !r.elogio);
const jurado = Object.keys(s.turma).find((n) => s.ids[n] !== v.rodada.alvo);
p = await abrir(s, jurado);
await rolar(p, 450);
await foto(p, 'tribunal');
await p.close();

// Correio: escrever e ler os bilhetes.
s = await novaSala();
v = await comecar(s, { nivel: 'Resenha', modos: ['Correio'] });
const alvoCorreio = s.nomes[v.rodada.alvo];
const escritores = Object.keys(s.turma).filter((n) => n !== alvoCorreio);
p = await abrir(s, escritores[0]);
await rolar(p, 650);
await foto(p, 'correio');
const bilhetes = ['Rei do churrasco', 'Tio do pavê 🥸', 'Sumido do grupo'];
for (const [i, n] of escritores.entries()) await api('POST', `${s.sala}/respostas`, s.turma[n], { rodada: v.rodada.numero, resposta: bilhetes[i] });
await espera(2500);
await rolar(p, 200);
await foto(p, 'bilhetes');
await p.close();

// Pedra, papel e tesoura.
s = await novaSala();
v = await comecar(s, { nivel: 'Resenha', modos: ['MaisProvavel'] }, (r) => r.jokenpo && !r.goles);
p = await abrir(s, s.nomes[v.rodada.duelistas[0]]);
await rolar(p, 600);
await foto(p, 'jokenpo');
await p.close();

// Duelo votado.
s = await novaSala();
v = await comecar(s, { nivel: 'Resenha', modos: ['MaisProvavel'] }, (r) => r.duelistas.length && !r.jokenpo);
p = await abrir(s, Object.keys(s.turma).find((n) => !v.rodada.duelistas.includes(s.ids[n])));
await rolar(p, 600);
await foto(p, 'duelo');
await p.close();

// Imagem e Ação, com dois times (6 pessoas): a tela de quem faz a mímica.
s = await novaSala(['Advair', 'Júlia', 'Caio', 'Bruna', 'Edu', 'Fabi']);
v = await comecar(s, { nivel: 'Resenha', modos: ['ImagemEAcao'] });
p = await abrir(s, s.nomes[v.rodada.times[0].mimico]);
await rolar(p, 600);
await foto(p, 'mimica');
await p.close();

// Regra-relâmpago com entrevista.
s = await novaSala();
v = await comecar(s, { nivel: 'Resenha', modos: ['RegraRelampago'] }, (r) => true);
let tentativas = 0;
while (v.regra?.desafio?.tipo !== 'Entrevista' && tentativas++ < 80) v = await api('POST', `${s.sala}/tirar`, s.turma.Advair, { rodada: v.rodada.numero });
p = await abrir(s, 'Advair');
await rolar(p, 550);
await foto(p, 'regra');
await p.close();

// Dose de verdade e a mão de cartas na manga.
s = await novaSala();
v = await comecar(s, { nivel: 'Resenha', modos: ['BebaSe'] }, (r) => r.goles);
await api('POST', `${s.sala}/bebi`, s.turma.Advair, { rodada: v.rodada.numero });
p = await abrir(s, 'Advair', (visao) => { visao.minhaMao = ['Escudo', 'BatataQuente', 'Dobra']; });
await foto(p, 'dose');
await rolar(p, 900);
await foto(p, 'mao');
await p.close();

// Fim da noite: prêmios.
s = await novaSala();
v = await comecar(s, { nivel: 'Resenha', modos: ['BebaSe'] });
for (let i = 0; i < 4; i++) {
  await api('POST', `${s.sala}/bebi`, s.turma.Caio, { rodada: v.rodada.numero });
  if (i % 2 === 0) await api('POST', `${s.sala}/bebi`, s.turma['Júlia'], { rodada: v.rodada.numero });
  v = await api('POST', `${s.sala}/proxima`, s.turma.Advair, { rodada: v.rodada.numero });
}
await api('POST', `${s.sala}/encerrar`, s.turma.Advair);
p = await abrir(s, 'Bruna');
await foto(p, 'premios');
await p.close();

await b.close();
console.log('ok');
