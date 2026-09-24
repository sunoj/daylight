/** Optical masters shared by Chrome SVG and native AppKit renderers. */
import { compactArt } from './compact-art.mjs';
import { largeArt } from './large-art.mjs';

export const art = Object.fromEntries(Object.entries(compactArt).map(([term, small]) => {
  if (!largeArt[term]) throw new Error(`Missing detailed solar-term master: ${term}`);
  return [term, { small, large: largeArt[term] }];
}));

// Three restrained botanical inks, with brighter dark-mode values for fine strokes.
export const solarTermPalette = {
  botanical: { light: '#5E7257', dark: '#B4C3AA', css: '--solar-term-botanical' },
  warm: { light: '#9A7B43', dark: '#D1B783', css: '--solar-term-warm' },
  cool: { light: '#688595', dark: '#A8C6D5', css: '--solar-term-cool' },
};
