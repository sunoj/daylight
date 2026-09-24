/** Solar-term optical masters, shared with the native macOS renderer. */
import { solarTermIconData, solarTermIconPalette } from "./solar-term-icon-data";

export const solarTermIconTerms = Object.keys(solarTermIconData) as readonly (keyof typeof solarTermIconData)[];
export type SolarTermIconVariant = "small" | "large";

export function solarTermIconSvg(term: string, size = 24, variant: SolarTermIconVariant = size > 24 ? "large" : "small"): string {
  const key = term.trim();
  if (!Object.prototype.hasOwnProperty.call(solarTermIconData, key)) return "";
  const shapes = solarTermIconData[key as keyof typeof solarTermIconData][variant];
  const dimension = Number.isFinite(size) && size > 0 ? size : 24;
  const paths = shapes.map(shape => {
    const palette = shape.tone === "inherit" ? undefined : solarTermIconPalette[shape.tone];
    const color = palette ? `var(${palette.css}, ${palette.light})` : "currentColor";
    return shape.mode === "fill"
      ? `<path d="${shape.d}" fill="${color}" stroke="none" opacity="${shape.opacity}"/>`
      : `<path d="${shape.d}" fill="none" stroke="${color}" stroke-width="${shape.width}" stroke-linecap="round" stroke-linejoin="round" opacity="${shape.opacity}"/>`;
  }).join("");
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${dimension}" height="${dimension}" viewBox="0 0 24 24" data-variant="${variant}" aria-hidden="true">${paths}</svg>`;
}
