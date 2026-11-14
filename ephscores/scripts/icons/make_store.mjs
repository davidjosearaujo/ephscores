// Builds the Google Play listing graphics in docs/store/:
//   pt/          phone screenshots (1080x1920) = a raw emulator capture from
//                docs/store/raw/ framed under a caption, and the feature graphic
//                (1024x500: the brand beside the app's result cards).
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
    ['Tudo num só painel', 'Avaliação, Vias Verdes e PCR à mão'],
    ['PCR: SBV/DAE', 'Metrónomo, ciclos, choques e SIV/SAV'],
    ['Escalas automáticas', 'NEWS2 preenchida pelos sinais vitais'],
    ['Vias Verdes', 'AVC, Coronária, Sépsis e Trauma'],
    ['Mapa de lesões', 'Marque o tipo de lesão em cada região'],
    ['Grávida e parto', 'Alertas, tempos e APGAR'],
    ['CHAMU', 'História clínica como no verbete'],
    ['Evolução e ISBAR', 'Tendência e resumo para partilhar'],
  ],
};

// Feature graphic: the tagline, a note, and the result cards of the app
// (title, detail, value, colour of the value), two columns from the top.
const GREEN = '#34A853', AMBER = '#FBBC04', RED = '#EA4335';
const banner = {
  pt: {
    tagline: ['Escalas de emergência', 'pré-hospitalar'],
    note: '100 % offline · Android e iPhone',
    cards: [
      ['PCR', '3 ciclos', '06:54', NAVY],
      ['NEWS2', 'Risco alto', '18', RED],
      ['ECG', 'Ligeiro', '13', GREEN],
      ['Sépsis', 'Via Verde', '4/4', RED],
      ['RTS', 'Alterado', '11', AMBER],
      ['APGAR', '5.º minuto', '9', GREEN],
      ['Queimado', 'Regra dos nove', '27%', AMBER],
      ['CHAMU', '5 de 5', '5/5', GREEN],
    ],
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

// The Google Play feature graphic: the brand on navy, with the app's own
// result cards (the colours of the traffic light) beside it. Either language.
async function featureGraphic({ tagline, note, cards }, out) {
  const w = 1024, h = 500;
  const CARD_W = 228, CARD_H = 84, GAP = 12, LEFT = 516, TOP = 50, STAGGER = 26;
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">
    <rect width="${w}" height="${h}" fill="${NAVY}"/>
    <rect x="56" y="64" width="112" height="112" rx="28" fill="#FFFFFF"/>
    <text x="192" y="131" font-family="Roboto" font-size="56" fill="#FFFFFF"><tspan font-weight="800">EPH</tspan><tspan font-weight="400">Scores</tspan></text>
    ${tagline.map((line, i) => text(58, 236 + i * 40, line, 32, '#C9D6E6')).join('')}
    <rect x="58" y="332" width="44" height="10" rx="5" fill="${GREEN}"/>
    <rect x="110" y="332" width="44" height="10" rx="5" fill="${AMBER}"/>
    <rect x="162" y="332" width="44" height="10" rx="5" fill="${RED}"/>
    ${text(58, 412, note, 24, '#FFFFFF', 500)}`;
  cards.forEach(([title, detail, value, colour], i) => {
    const x = LEFT + (i % 2) * (CARD_W + GAP);
    const y = TOP + Math.floor(i / 2) * (CARD_H + GAP) + (i % 2) * STAGGER;
    const pill = Math.max(60, value.length * 15 + 30);
    const dark = colour === AMBER;
    svg += `<rect x="${x}" y="${y}" width="${CARD_W}" height="${CARD_H}" rx="22" fill="#FFFFFF"/>
      ${text(x + 18, y + 38, title, 23, NAVY, 800)}
      ${text(x + 18, y + 62, detail, 16, '#59606B')}
      <rect x="${x + CARD_W - pill - 14}" y="${y + 20}" width="${pill}" height="44" rx="13" fill="${colour}"/>
      <text x="${x + CARD_W - 14 - pill / 2}" y="${y + 51}" text-anchor="middle" font-family="Roboto" font-size="25" font-weight="800" fill="${dark ? '#202124' : '#FFFFFF'}">${value}</text>`;
  });
  svg += '</svg>';
  await sharp(Buffer.from(svg))
    .composite([{ input: await renderLogo(92), left: 66, top: 74 }])
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
