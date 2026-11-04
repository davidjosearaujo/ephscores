// Builds docs/design/banner.png (the README banner, 1024x500): the logo, the
// name and the main features, in the app's identity. Run with the other docs
// images:  cd scripts/icons && npm run docs
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import sharp from 'sharp';
import { designDocs, renderLogo, text, useBundledFonts } from './common.mjs';

useBundledFonts();

const W = 1024, H = 500, NAVY = '#2C496C';
const chips = [
  ['Escalas gerais', 'Queimaduras'],
  ['Triagem START', 'Evolução do doente'],
];
// Chip width from the text length (Roboto at 22 px is about 12 px a letter).
const chipWidth = (s) => Math.round(s.length * 12 + 40);

let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
  <rect width="${W}" height="${H}" fill="#EAEBF3"/>
  <text x="416" y="232" font-family="Roboto" font-size="104" fill="${NAVY}"><tspan font-weight="800">EPH</tspan><tspan font-weight="400">Scores</tspan></text>
  ${text(420, 286, 'Escalas de emergência pré-hospitalar', 29, '#59606B')}`;
chips.forEach((row, r) => {
  let x = 420;
  for (const label of row) {
    const w = chipWidth(label);
    svg += `<rect x="${x}" y="${330 + r * 62}" width="${w}" height="46" rx="23" fill="#FFFFFF" stroke="#C4C9D4" stroke-width="2"/>`;
    svg += text(x + 20, 361 + r * 62, label, 22, NAVY, 500);
    x += w + 14;
  }
});
svg += '</svg>';

mkdirSync(designDocs, { recursive: true });
const output = join(designDocs, 'banner.png');
await sharp(Buffer.from(svg))
  .composite([{ input: await renderLogo(330), left: 56, top: 85 }])
  .png()
  .toFile(output);
console.log('  ', output);
