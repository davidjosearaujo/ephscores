// Builds docs/design/logo-preview.png: the logo as it appears in each place it
// is used. Run after `npm run generate`, so the icons it shows are current:
//
//   cd scripts/icons && npm run preview
//
// Text uses the Roboto font bundled in assets/fonts, so it looks the same on
// any machine.
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const output = join(root, '..', 'docs', 'design', 'logo-preview.png');
const P = (f) => join(root, f);

// Point fontconfig at the bundled fonts before anything is rendered.
const conf = join(mkdtempSync(join(tmpdir(), 'ephscores-fonts-')), 'fonts.conf');
writeFileSync(
  conf,
  `<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig><dir>${P('assets/fonts')}</dir><cachedir>${dirname(conf)}</cachedir></fontconfig>`,
);
process.env.FONTCONFIG_FILE = conf;

const S = 220, g = 24, top = 70;
const shape = (d, inner) =>
  Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${d}" height="${d}">${inner}</svg>`);
const circle = (d) => shape(d, `<circle cx="${d / 2}" cy="${d / 2}" r="${d / 2}"/>`);
const tile = (d, bg, mask) =>
  sharp({ create: { width: d, height: d, channels: 4, background: bg } })
    .composite([{ input: mask, blend: 'dest-in' }])
    .png()
    .toBuffer();
const logoSvg = (px) =>
  sharp(P('assets/brand/logo.svg'), { density: (72 * px) / 512 }).resize(px, px).png().toBuffer();
const onSurface = async (bg, px) =>
  sharp({ create: { width: S, height: S, channels: 4, background: bg } })
    .composite([{ input: await logoSvg(px), gravity: 'center' }])
    .png()
    .toBuffer();

const items = [];
items.push(['App icon (legacy, iOS)', await sharp(P('assets/icon/app_icon.png')).resize(S, S).png().toBuffer()]);
// The launcher tool insets the adaptive layer by 16%, then a circular mask applies.
const fg = await sharp(P('assets/icon/app_icon_foreground.png')).resize(Math.round(S * 0.68)).png().toBuffer();
items.push([
  'Android adaptive icon',
  await sharp(await tile(S, '#ffffff', circle(S))).composite([{ input: fg, gravity: 'center' }]).png().toBuffer(),
]);
const mono = await sharp(P('assets/icon/app_icon_monochrome.png')).resize(Math.round(S * 0.68)).png().toBuffer();
items.push([
  'Android themed icon',
  await sharp(await tile(S, '#e4dcff', circle(S))).composite([{ input: mono, gravity: 'center' }]).png().toBuffer(),
]);
items.push(['Web app / PWA icon', await sharp(P('web/icons/Icon-512.png')).resize(S, S).png().toBuffer()]);
items.push(['On a dark surface', await onSurface('#111318', 150)]);
items.push(['On the navy header', await onSurface('#2C496C', 130)]);

const W = g + items.length * (S + g);
const smallY = top + S + 90;
const H = smallY + 96 + 50;
const comp = items.map(([, img], i) => ({ input: img, left: g + i * (S + g), top }));
let x = g;
for (const px of [96, 64, 48, 32, 24, 16]) {
  comp.push({ input: await sharp(P('assets/icon/app_icon.png')).resize(px, px).png().toBuffer(), left: x, top: smallY });
  x += px + 22;
}
const text = (tx, y, s, size, fill, weight = 400) =>
  `<text x="${tx}" y="${y}" font-family="Roboto" font-size="${size}" font-weight="${weight}" fill="${fill}">${s}</text>`;
let labels = text(g, 44, 'EPHScores — logo and icons (generated from assets/brand/logo.svg)', 26, '#2C496C', 700);
items.forEach(([name], i) => (labels += text(g + i * (S + g), top + S + 26, name, 15, '#202124', 500)));
labels += text(g, smallY - 14, 'Real sizes: 96 / 64 / 48 / 32 / 24 / 16 px', 15, '#59606B', 500);
const background = Buffer.from(
  `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><rect width="${W}" height="${H}" fill="#EAEBF3"/>${labels}</svg>`,
);
mkdirSync(dirname(output), { recursive: true });
await sharp(background).composite(comp).png().toFile(output);
console.log('  ', output);
