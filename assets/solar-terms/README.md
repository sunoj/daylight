# Solar-term icons

Each of the 24 terms has two independent vector masters:

- `compact-art.mjs`: the original compact silhouettes, using a 24-unit grid and 1.6-unit stroke. These remain unchanged by the detailed illustration redesign.
- `large-art.mjs`: botanical illustrations drawn on a 64-unit grid. Curved leaves, petals, feathers and grain have separate contour, fine engraving and translucent wash layers. The export normalizes coordinates and stroke widths to the shared 24-unit viewport.

Detailed illustrations use at most three restrained inks: moss green for botanical contours, muted ochre for sunlight, grain and flower centers, and mist blue for rain, dew, reflections, moonlight and ice. Each motif uses only the inks it needs. All three have lighter dark-mode variants so thin strokes remain legible. The palette in `art.mjs` generates Chrome theme variables and native colors together. Compact icons continue to inherit the surrounding text color.

Contours and the main vein have separate weights. Secondary veins are sampled from the actual leaf curves to avoid overshooting the margin. Grain uses plump kernels with a separate crease; petals have unequal lengths, shallow notches and open bases. Plum branches stop at flower boundaries, and lotus petals ink only their visible edges. Feather contours, curled lotus leaves and faceted snow crystals have dedicated geometry. Secondary marks and washes use reduced opacity, preserving clear gaps at 48 px. Cloud banks share a continuous canopy with a soft underside; droplets use a rounded body and separate refracted shadow, with reflection marks omitted below 2.5 drawing units. Dew rests against the leaf edge, and cold flower petals have selective blue fold shadows.

macOS uses the compact master at 20 pt beside the Luna moon readout and 24 pt beside the Sol moon row. Chrome uses the detailed master at 48 px in the selected day's solar-term card. Icons appear on the selected term date; ordinary dates retain the moon readout alone.

After editing either master, regenerate from the repository root:

```sh
node scripts/generate-solar-term-icons.mjs
# On macOS, also regenerate the native PNG review sheets:
node scripts/generate-solar-term-icons.mjs --png
```

This generates TypeScript artwork data, Chrome color variables, native AppKit paths and SVG review sheets. Do not edit generated platform paths directly. Geometry uses absolute `M`, `L`, `C` and `Z` commands; export converts the top-left artwork coordinates to AppKit's bottom-left coordinates.

See the [detailed illustrations](large-preview.svg) at twice their display size and at their actual 48 px size on a dark background, or [compare both masters](preview.svg). PNG equivalents are generated from the same native paths with the same stroke widths and opacity as the SVG renderer.
