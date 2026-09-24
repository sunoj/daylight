/**
 * Toolbar theme detection and icon foreground colours for the action icon.
 * Exports: ToolbarTheme, resolveToolbarTheme, resolveIconColors
 * Deps: none
 */

export type ToolbarTheme = "light" | "dark" | "unknown";

export interface IconColors {
  readonly foreground: string;
}

const LIGHT_TOOLBAR_FOREGROUND = "#1B1B1A";
const DARK_TOOLBAR_FOREGROUND = "#ECEBE7";
const UNKNOWN_TOOLBAR_FOREGROUND = "#8A8984";

export function resolveToolbarTheme(prefersDark: boolean): ToolbarTheme {
  return prefersDark ? "dark" : "light";
}

export function resolveIconColors(theme: ToolbarTheme): IconColors {
  if (theme === "dark") return { foreground: DARK_TOOLBAR_FOREGROUND };
  if (theme === "light") return { foreground: LIGHT_TOOLBAR_FOREGROUND };
  return { foreground: UNKNOWN_TOOLBAR_FOREGROUND };
}
