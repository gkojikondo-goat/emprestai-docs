// Folha de contato para revisão visual (ferramenta local, fora do repositório).
// Uso: node folha.mjs <pasta-das-fotos> <saida.jpg> TI-0001 TI-0004 ...
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

const [pasta, saida, ...patrimonios] = process.argv.slice(2);
const require = createRequire(path.join(pasta, '..', '..', 'package.json'));
const sharp = require('sharp');
const W = 400, H = 300, ROTULO = 28, COLS = 3;
const linhas = Math.ceil(patrimonios.length / COLS);
const pecas = [];
for (const [i, p] of patrimonios.entries()) {
  const x = (i % COLS) * W, y = Math.floor(i / COLS) * (H + ROTULO);
  const foto = await sharp(readFileSync(path.join(pasta, `${p}.jpg`))).resize(W, H).toBuffer();
  const svg = Buffer.from(`<svg width="${W}" height="${ROTULO}"><rect width="100%" height="100%" fill="#111"/><text x="8" y="20" font-size="18" fill="#fff" font-family="Arial">${p}</text></svg>`);
  pecas.push({ input: svg, left: x, top: y }, { input: foto, left: x, top: y + ROTULO });
}
await sharp({ create: { width: W * COLS, height: linhas * (H + ROTULO), channels: 3, background: '#000' } })
  .composite(pecas).jpeg({ quality: 80 }).toFile(saida);
console.log(`folha: ${saida}`);
