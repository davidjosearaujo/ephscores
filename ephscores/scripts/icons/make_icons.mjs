// Generates every launcher and web icon from the single master logo,
// assets/brand/logo.svg. Run after editing the SVG, then commit the results:
//
//   cd scripts/icons && npm install && npm run generate
//   cd ../.. && dart run flutter_launcher_icons     # Android/iOS resources
//
// The Android themed (monochrome) icon must be a single colour, so it is the
// badge with the star cut out; the three coloured arms exist only in the
// full-colour versions.
import { mkdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const master = readFileSync(join(root, 'assets/brand/logo.svg'), 'utf8');
const out = (p) => join(root, p);
const BLACK = '#000000';

/** Renders SVG text at exactly px x px (vector-sharp, no resampling). */
const render = (svg, px) =>
  sharp(Buffer.from(svg), { density: (72 * px) / 512 }).resize(px, px).png().toBuffer();

/** The badge only, in black, with the star cut out (transparent). */
async function badgeWithStarCutOut(px) {
  const badge = master
    .replace(/<g id="star"[\s\S]*<\/svg>/, '</svg>')
    .replaceAll('#2C496C', BLACK);
  // The star's outline is the clip path: use its rectangles directly, since
  // cutting out the coloured wedges would leave seams where they meet.
  const rects = master.match(/<clipPath id="star-shape">([\s\S]*?)<\/clipPath>/)[1];
  const transform = master.match(/<g id="star" transform="([^"]*)"/)[1];
  const star = master
    .replace(/<defs>[\s\S]*<\/defs>/, '')
    .replace(/<polygon id="badge"[^>]*\/>/, '')
    .replace(/<g id="star"[\s\S]*<\/svg>/, `<g transform="${transform}" fill="${BLACK}">${rects}</g></svg>`);
  return sharp(await render(badge, px))
    .composite([{ input: await render(star, px), blend: 'dest-out' }])
    .png()
    .toBuffer();
}

/**
 * Places the logo on a square canvas. `scale` is the logo's share of the
 * canvas; `radius` rounds the tile (0 = full bleed); `bg` null = transparent.
 */
async function icon(file, size, { scale, bg = null, radius = 0, mono = false }) {
  const px = Math.round(size * scale);
  const logo = mono ? await badgeWithStarCutOut(px) : await render(master, px);
  let img = sharp({
    create: { width: size, height: size, channels: 4, background: bg ?? { r: 0, g: 0, b: 0, alpha: 0 } },
  }).composite([{ input: logo, gravity: 'center' }]);
  if (radius > 0) {
    const mask = Buffer.from(
      `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}"><rect width="${size}" height="${size}" rx="${size * radius}"/></svg>`,
    );
    img = sharp(await img.png().toBuffer()).composite([{ input: mask, blend: 'dest-in' }]);
  }
  mkdirSync(dirname(out(file)), { recursive: true });
  await img.png().toFile(out(file));
  console.log('  ', file);
}

const white = { r: 255, g: 255, b: 255, alpha: 1 };
console.log('Generating icons from assets/brand/logo.svg');
await Promise.all([
  // Android / iOS source images (flutter_launcher_icons).
  icon('assets/icon/app_icon.png', 1024, { scale: 0.82, bg: white }),
  // Adaptive icon layers. Full size on purpose: flutter_launcher_icons already
  // insets them by 16% per side to stay inside the launcher's safe zone.
  icon('assets/icon/app_icon_foreground.png', 1024, { scale: 1 }),
  icon('assets/icon/app_icon_monochrome.png', 1024, { scale: 1, mono: true }),
  icon('assets/icon/play_store_512.png', 512, { scale: 0.82, bg: white }),
  // Web app / PWA.
  icon('web/icons/Icon-192.png', 192, { scale: 0.78, bg: white, radius: 0.22 }),
  icon('web/icons/Icon-512.png', 512, { scale: 0.78, bg: white, radius: 0.22 }),
  icon('web/icons/Icon-maskable-192.png', 192, { scale: 0.7, bg: white }),
  icon('web/icons/Icon-maskable-512.png', 512, { scale: 0.7, bg: white }),
  // iOS fills transparent areas with black, so the touch icon is opaque.
  icon('web/icons/apple-touch-icon.png', 180, { scale: 0.8, bg: white }),
  // Transparent: the hexagon alone reads best in a browser tab.
  icon('web/favicon.png', 64, { scale: 1 }),
]);
