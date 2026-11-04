// Helpers shared by the icon, preview and banner generators.
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

/** The Flutter project folder (ephscores/). */
export const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
/** Where the design docs and their images live. */
export const designDocs = join(root, '..', 'docs', 'design');
/** A path inside the Flutter project. */
export const P = (file) => join(root, file);

/** The single master logo, as SVG text. */
export const master = readFileSync(P('assets/brand/logo.svg'), 'utf8');

/** Renders square SVG text (512-unit viewBox) at exactly px x px, vector-sharp. */
export const render = (svg, px) =>
  sharp(Buffer.from(svg), { density: (72 * px) / 512 }).resize(px, px).png().toBuffer();

/** The logo as it is, px x px. */
export const renderLogo = (px) => render(master, px);

/**
 * Makes text in generated images use the Roboto bundled in assets/fonts, so
 * the result is the same on any machine. Call before rendering any text.
 */
export function useBundledFonts() {
  const conf = join(mkdtempSync(join(tmpdir(), 'ephscores-fonts-')), 'fonts.conf');
  writeFileSync(
    conf,
    `<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig><dir>${P('assets/fonts')}</dir><cachedir>${dirname(conf)}</cachedir></fontconfig>`,
  );
  process.env.FONTCONFIG_FILE = conf;
}

/** An SVG <text> element in Roboto. */
export const text = (x, y, s, size, fill, weight = 400) =>
  `<text x="${x}" y="${y}" font-family="Roboto" font-size="${size}" font-weight="${weight}" fill="${fill}">${s}</text>`;
