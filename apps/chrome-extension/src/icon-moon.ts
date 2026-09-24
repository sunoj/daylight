/**
 * Canvas moon glyph for the toolbar action icon.
 * Exports: drawMoonGlyph
 * Deps: detail-cards moon limb helper, core moon phase
 */

import { getMoonPhase } from "@daylight/core-calendar";
import type { LocalDateKey } from "@daylight/domain";
import { getMoonLimb } from "./detail-cards";

export function drawMoonGlyph(
  context: OffscreenCanvasRenderingContext2D,
  date: LocalDateKey,
  color: string,
): void {
  const moon = getMoonPhase(date);
  const limb = getMoonLimb(moon.name);
  const waxing = limb === "right";
  const fraction = moon.illumination;
  const inset = 3;
  const size = 32 - inset * 2;
  const x = inset;
  const y = inset;
  const center = x + size / 2;
  const radius = size / 2;

  context.clearRect(0, 0, 32, 32);
  context.strokeStyle = color;
  context.fillStyle = color;
  context.lineWidth = 1.2;
  context.beginPath();
  context.arc(center, y + radius, radius, 0, 2 * Math.PI);
  context.stroke();

  if (fraction <= 0) return;
  if (fraction >= 1) {
    context.beginPath();
    context.arc(center, y + radius, radius, 0, 2 * Math.PI);
    context.fill();
    return;
  }
  if (limb === "none") return;

  const scaleX = Math.max(Math.abs(1 - 2 * fraction), 0.0001);
  const terminatorClockwise = waxing ? fraction >= 0.5 : fraction < 0.5;
  context.beginPath();
  context.moveTo(center, y);
  context.arc(center, y + radius, radius, -Math.PI / 2, Math.PI / 2, waxing);
  context.save();
  context.translate(center, y + radius);
  context.scale(scaleX, 1);
  context.arc(0, 0, radius, Math.PI / 2, -Math.PI / 2, terminatorClockwise);
  context.restore();
  context.closePath();
  context.fill();
}
