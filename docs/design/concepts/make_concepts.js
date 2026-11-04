// Draws the logo/icon concepts as SVG and renders a contact sheet.
// Usage: node make_concepts.js <output-dir>   (needs `npm i sharp`; the sheet
// uses the Roboto font if it is installed, otherwise the system default).
const sharp = require('sharp'), fs = require('fs'), path = require('path');
const OUT = process.argv[2];
const NAVY = '#2C496C', WHITE = '#FFFFFF', LIGHT = '#C9DDFF', TILE_DARK = '#1B2F47';
const C = 256;

// Star of Life = three bars rotated 60 degrees apart.
function star(fill, { len = 440, w = 118, rx = 14 } = {}) {
  const bar = a => `<rect x="${C - w / 2}" y="${C - len / 2}" width="${w}" height="${len}" rx="${rx}" fill="${fill}" transform="rotate(${a} ${C} ${C})"/>`;
  return bar(0) + bar(60) + bar(120);
}
const polar = (r, deg) => [C + r * Math.cos(deg * Math.PI / 180), C + r * Math.sin(deg * Math.PI / 180)];
function arc(r, a0, a1) {
  const [x0, y0] = polar(r, a0), [x1, y1] = polar(r, a1);
  return `M${x0.toFixed(1)} ${y0.toFixed(1)} A${r} ${r} 0 ${(a1 - a0) > 180 ? 1 : 0} 1 ${x1.toFixed(1)} ${y1.toFixed(1)}`;
}

// Each concept draws its art for a theme: {fg: star colour, mark: colour of the
// detail drawn over the star, tile: background}.
const concepts = [
  { id: '1-clean-star', name: 'Clean star',
    art: t => star(t.fg) },
  { id: '2-star-pulse', name: 'Star + pulse',
    art: t => star(t.fg) + `<path d="M150 262H205L228 222L254 312L284 188L308 262H362" fill="none" stroke="${t.mark}" stroke-width="17" stroke-linecap="round" stroke-linejoin="round"/>` },
  { id: '3-star-trend', name: 'Star + trend',
    art: t => star(t.fg) +
      `<path d="M160 292L256 236L352 188" fill="none" stroke="${t.mark}" stroke-width="12" stroke-linecap="round"/>` +
      [[160, 292], [256, 236], [352, 188]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="21" fill="${t.mark}"/>`).join('') },
  { id: '4-badge', name: 'Badge (cut-out)',
    art: t => {
      const pts = [90, 150, 210, 270, 330, 30].map(a => polar(222, a).map(n => n.toFixed(1)).join(',')).join(' ');
      // The badge is the foreground colour; the star is cut out in the tile colour.
      return `<polygon points="${pts}" fill="${t.fg}" stroke="${t.fg}" stroke-width="40" stroke-linejoin="round"/>` +
        `<g transform="translate(${C} ${C}) scale(0.62) translate(${-C} ${-C})">${star(t.cut)}</g>`;
    } },
  { id: '5-gauge', name: 'Star in gauge',
    art: t => {
      const seg = (a0, a1, col) => `<path d="${arc(226, a0, a1)}" fill="none" stroke="${t.ring || col}" stroke-width="34" stroke-linecap="butt"/>`;
      return seg(137, 223, '#34A853') + seg(227, 313, '#FBBC04') + seg(317, 43 + 360, '#EA4335') +
        `<g transform="translate(${C} ${C}) scale(0.62) translate(${-C} ${-C})">${star(t.fg)}</g>`;
    } },
];

const themes = {
  light: { tile: WHITE, fg: NAVY, mark: WHITE, cut: WHITE },
  dark: { tile: NAVY, fg: WHITE, mark: NAVY, cut: NAVY },
  mono: { tile: LIGHT, fg: '#10263F', mark: LIGHT, cut: LIGHT, ring: '#10263F' },
};
const svgOf = (c, theme, size, rounded = true) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 512 512">` +
  `<rect width="512" height="512" rx="${rounded ? 112 : 0}" fill="${theme.tile}"/>${c.art(theme)}</svg>`;
// A nested <svg> so the same art can be placed at any size inside the sheet.
const place = (c, theme, x, y, size) =>
  `<svg x="${x}" y="${y}" width="${size}" height="${size}" viewBox="0 0 512 512">` +
  `<rect width="512" height="512" rx="112" fill="${theme.tile}"/>${c.art(theme)}</svg>`;

// Individual files (light tile + a transparent-background mono shape).
for (const c of concepts) fs.writeFileSync(path.join(OUT, `${c.id}.svg`), svgOf(c, themes.light, 512));

// Contact sheet.
const rowH = 250, head = 70, W = 1480, H = head + rowH * concepts.length + 20;
const text = (x, y, s, size, fill, weight = 400) =>
  `<text x="${x}" y="${y}" font-family="Roboto" font-size="${size}" font-weight="${weight}" fill="${fill}">${s}</text>`;
let body = `<rect width="${W}" height="${H}" fill="#EAEBF3"/>` +
  text(30, 42, 'EPHScores — logo / icon concepts', 28, NAVY, 700) +
  [['Light', 330], ['Dark', 590], ['Single colour (Android themed icon)', 850], ['Real sizes: 96 / 64 / 48 / 32 px', 1160]]
    .map(([s, x]) => text(x, 62, s, 15, '#59606B', 500)).join('');
concepts.forEach((c, i) => {
  const y = head + i * rowH + 20;
  body += text(30, y + 100, `${i + 1}`, 64, NAVY, 700) + text(30, y + 140, c.name, 20, '#202124', 500);
  body += place(c, themes.light, 330, y, 210) + place(c, themes.dark, 590, y, 210) + place(c, themes.mono, 850, y, 210);
  let x = 1160;
  for (const s of [96, 64, 48, 32]) { body += place(c, themes.light, x, y + 50, s); x += s + 18; }
  body += place(c, themes.dark, 1160, y + 160, 40) + place(c, themes.dark, 1160 + 58, y + 160, 32);
});
const sheet = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${body}</svg>`;
fs.writeFileSync(path.join(OUT, 'contact-sheet.svg'), sheet);
sharp(Buffer.from(sheet), { density: 72 }).png().toFile(path.join(OUT, 'contact-sheet.png')).then(() => console.log('ok', W, H));
