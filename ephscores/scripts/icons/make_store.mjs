// Builds the Google Play listing graphics in docs/store/:
//   pt/          phone screenshots (1080x1920) = a raw emulator capture from
//                docs/store/raw/ framed under a caption, and the feature graphic
//                (1024x500).
// The raw captures are 1080x1920 screenshots of the app (UI in Portuguese).
// Run:  cd scripts/icons && npm run store
import { mkdirSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import sharp from 'sharp';
import { designDocs, renderLogo, text, useBundledFonts } from './common.mjs';

useBundledFonts();

const store = join(designDocs, '..', 'store');
const NAVY = '#2C496C';
const W = 1080, H = 1920;
const SHOT_W = 880, SHOT_H = Math.round((SHOT_W * 1920) / 1080), SHOT_TOP = H - SHOT_H;
const CORNER = 56;

// One entry per raw capture, in file order: [title, subtitle].
const captions = {
  pt: [
    ['Tudo num só painel', 'Sinais vitais, escalas e Vias Verdes'],
    ['Sinais vitais', 'Registados uma vez, como no verbete'],
    ['Escalas automáticas', 'NEWS2 preenchida pelos sinais vitais'],
    ['Vias Verdes', 'AVC, Coronária, Sépsis e Trauma'],
    ['Avaliação da dor', 'Faces, FLACC e índice de choque'],
    ['Evolução do doente', 'Tendência e resumo para copiar'],
    ['Regra dos nove', 'Grau por região e SCQ em tempo real'],
    ['Triagem START', 'Prioridade, passo a passo'],
  ],
};

const banner = {
  pt: {
    tagline: 'Escalas de emergência pré-hospitalar',
    chips: [['Sinais vitais', 'Vias Verdes'], ['Escalas', 'Evolução do doente']],
  },
};

const roundedTop = Buffer.from(
  `<svg xmlns="http://www.w3.org/2000/svg" width="${SHOT_W}" height="${SHOT_H}"><path d="M0 ${SHOT_H}V${CORNER}Q0 0 ${CORNER} 0H${SHOT_W - CORNER}Q${SHOT_W} 0 ${SHOT_W} ${CORNER}V${SHOT_H}Z" fill="#fff"/></svg>`,
);

async function screenshot(file, [title, subtitle], out) {
  const shot = await sharp(file)
    .resize(SHOT_W, SHOT_H)
    .composite([{ input: roundedTop, blend: 'dest-in' }])
    .png()
    .toBuffer();
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
    <rect width="${W}" height="${H}" fill="${NAVY}"/>
    <text x="${W / 2}" y="170" text-anchor="middle" font-family="Roboto" font-size="84" font-weight="800" fill="#FFFFFF">${title}</text>
    <text x="${W / 2}" y="250" text-anchor="middle" font-family="Roboto" font-size="46" font-weight="400" fill="#C9D6E6">${subtitle}</text>
  </svg>`;
  await sharp(Buffer.from(svg))
    .composite([{ input: shot, left: (W - SHOT_W) / 2, top: SHOT_TOP }])
    .png()
    .toFile(out);
}

// Same layout as the README banner (make_banner.mjs), in either language.
async function featureGraphic({ tagline, chips }, out) {
  const w = 1024, h = 500;
  const chipWidth = (s) => Math.round(s.length * 12 + 40);
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">
    <rect width="${w}" height="${h}" fill="#EAEBF3"/>
    <text x="416" y="232" font-family="Roboto" font-size="104" fill="${NAVY}"><tspan font-weight="800">EPH</tspan><tspan font-weight="400">Scores</tspan></text>
    ${text(420, 286, tagline, 29, '#59606B')}`;
  chips.forEach((row, r) => {
    let x = 420;
    for (const label of row) {
      const cw = chipWidth(label);
      svg += `<rect x="${x}" y="${330 + r * 62}" width="${cw}" height="46" rx="23" fill="#FFFFFF" stroke="#C4C9D4" stroke-width="2"/>`;
      svg += text(x + 20, 361 + r * 62, label, 22, NAVY, 500);
      x += cw + 14;
    }
  });
  svg += '</svg>';
  await sharp(Buffer.from(svg))
    .composite([{ input: await renderLogo(330), left: 56, top: 85 }])
    .png()
    .toFile(out);
}

const raws = readdirSync(join(store, 'raw')).filter((f) => f.endsWith('.png')).sort();
for (const lang of ['pt']) {
  const dir = join(store, lang);
  mkdirSync(dir, { recursive: true });
  for (const [i, file] of raws.entries()) {
    const out = join(dir, `phone-${String(i + 1).padStart(2, '0')}.png`);
    await screenshot(join(store, 'raw', file), captions[lang][i], out);
    console.log('  ', out);
  }
  const out = join(dir, 'feature-graphic.png');
  await featureGraphic(banner[lang], out);
  console.log('  ', out);
}
