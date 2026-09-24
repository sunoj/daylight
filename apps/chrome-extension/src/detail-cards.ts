import { getMoonPhase, getSolarTerm, getSolarTermLabelZh } from "@daylight/core-calendar";
import type { LocalDateKey, MoonPhaseName, SolarTermName } from "@daylight/domain";
import { t } from "./locale";

export type MoonLimb = "left" | "right" | "none";

export interface SolarTermCardData {
  readonly term: SolarTermName;
  readonly label: string;
  readonly subtitle: string;
}

export interface MoonCardData {
  readonly phaseName: MoonPhaseName;
  readonly phaseLabel: string;
  readonly illumination: number;
  readonly info: string;
  readonly limb: MoonLimb;
}

export function getSolarTermCardData(date: LocalDateKey): SolarTermCardData | undefined {
  const term = getSolarTerm(date);
  if (!term) return undefined;
  return { term, label: getSolarTermLabelZh(term), subtitle: t("二十四节气") };
}

export function getMoonCardData(date: LocalDateKey): MoonCardData {
  const moon = getMoonPhase(date);
  const percent = Math.round(moon.illumination * 100);
  return {
    phaseName: moon.name,
    phaseLabel: getMoonPhaseLabel(moon.name),
    illumination: moon.illumination,
    info: t("{percent}% 照亮").replace("{percent}", String(percent)),
    limb: getMoonLimb(moon.name),
  };
}

export function getMoonLimb(phaseName: MoonPhaseName): MoonLimb {
  switch (phaseName) {
    case "waxing-crescent":
    case "first-quarter":
    case "waxing-gibbous":
      return "right";
    case "waning-gibbous":
    case "last-quarter":
    case "waning-crescent":
      return "left";
    case "new":
    case "full":
      return "none";
  }
}

export function moonDiscSvg(fraction: number, limb: MoonLimb, size = 40): string {
  const radius = size / 2 - 1;
  const center = size / 2;
  const value = clamp(fraction);
  const outline = `<circle cx="${center}" cy="${center}" r="${radius}" fill="none" stroke="currentColor" stroke-width="1.1"/>`;
  if (limb === "none") {
    const fill = value >= 0.5 ? `<circle cx="${center}" cy="${center}" r="${radius}" fill="currentColor"/>` : "";
    return svg(size, fill, outline);
  }
  if (value <= 0) return svg(size, "", outline);
  if (value >= 1) return svg(size, `<circle cx="${center}" cy="${center}" r="${radius}" fill="currentColor"/>`, outline);
  const rx = Math.max(Math.abs(1 - 2 * value) * radius, 0.0001);
  const outerSweep = limb === "right" ? 1 : 0;
  const terminatorSweep = limb === "right" ? Number(value >= 0.5) : Number(value < 0.5);
  const path = [
    `M ${center} ${center - radius}`,
    `A ${radius} ${radius} 0 0 ${outerSweep} ${center} ${center + radius}`,
    `A ${rx} ${radius} 0 0 ${terminatorSweep} ${center} ${center - radius}`,
    "Z",
  ].join(" ");
  return svg(size, `<path d="${path}" fill="currentColor"/>`, outline);
}

function getMoonPhaseLabel(phaseName: MoonPhaseName): string {
  return t({
    "new": "新月",
    "waxing-crescent": "娥眉月",
    "first-quarter": "上弦月",
    "waxing-gibbous": "盈凸月",
    "full": "满月",
    "waning-gibbous": "亏凸月",
    "last-quarter": "下弦月",
    "waning-crescent": "残月",
  }[phaseName]);
}

function clamp(value: number): number {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

function svg(size: number, fill: string, outline: string): string {
  return `<svg viewBox="0 0 ${size} ${size}" width="${size}" height="${size}" aria-hidden="true" focusable="false">${fill}${outline}</svg>`;
}
