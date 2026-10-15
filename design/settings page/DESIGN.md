---
name: Architectural Minimal Brutalism
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#4c4546'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f1f1'
  outline: '#7e7576'
  outline-variant: '#cfc4c5'
  surface-tint: '#5e5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1b1b1b'
  on-primary-container: '#848484'
  inverse-primary: '#c6c6c6'
  secondary: '#5e5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e3e2e2'
  on-secondary-container: '#646464'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#1b1b1b'
  on-tertiary-container: '#848484'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c6'
  on-primary-fixed: '#1b1b1b'
  on-primary-fixed-variant: '#474747'
  secondary-fixed: '#e3e2e2'
  secondary-fixed-dim: '#c7c6c6'
  on-secondary-fixed: '#1b1c1c'
  on-secondary-fixed-variant: '#464747'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c6'
  on-tertiary-fixed: '#1b1b1b'
  on-tertiary-fixed-variant: '#474747'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 36px
    fontWeight: '600'
    lineHeight: 44px
  headline-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Space Grotesk
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-md:
    fontFamily: Space Grotesk
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  label-sm:
    fontFamily: Space Grotesk
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 12px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.5rem
  margin-mobile: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

The brand personality merges modern architectural drafting discipline with brutalist clarity and gallery-grade minimalism. It serves design-conscious professionals, architects, engineers, and focused knowledge workers who demand zero ambient noise, maximum functional intent, and serene everyday utility.

The emotional tone is calm, decisive, unadorned, and grounded. Visual tension is achieved not through ornamental gradients or simulated lighting, but through structural line-work, stark black-and-white contrast, deliberate negative space, and rigid geometric proportions.

## Colors

The palette is rooted in strict monochrome values paired with warm, paper-inspired surface undertones:
- **Canvas Base**: Pure white `#FFFFFF` for primary focus cards and deep contrast.
- **Surface Level 1**: `#FBFBFB` for top-level view backgrounds, creating soft separation from physical display bezels.
- **Surface Level 2**: `#F4F4F4` for inset metadata zones, secondary cards, and structural separators.
- **Structural Black**: `#000000` for 1px structural framing, primary icons, and primary typography.
- **Secondary Neutral**: `#767676` for secondary metrics, timestamps, and low-priority task details.

Do not use decorative accent hues or semantic color fills (e.g., green checkmarks or red warnings); critical states are communicated through filled black geometries, structural strikes, and line weighting.

## Typography

Typography establishes an architectural blueprint aesthetic. **Space Grotesk** governs all headers, counters, and systemic metadata labels with geometric precision. **Inter** handles task titles, body notes, and multiline descriptions to preserve neutral, high-density legibility.

All labels in Space Grotesk should be rendered in uppercase with subtle positive letter tracking (+0.05em to +0.08em) to evoke precision-milled technical documentation.

## Layout & Spacing

The layout is constructed on an absolute 8pt grid with 4pt micro-subdivisions, referencing the mathematical discipline of drafting paper. 

- **Mobile Viewport**: Relies on a single-column stacked card hierarchy framed by `margin-mobile` (1.25rem / 20px). Task entries utilize generous internal padding (`space-lg` / 24px) to ensure unhurried, comfortable tap targets.
- **Tablet / Expanded**: Transitions to an asymmetric dual-pane layout: a persistent architectural index on the left (fixed 320px) and a drafting canvas/detail workspace on the right, separated by a crisp 1px solid `#000000` vertical hairline.

## Elevation & Depth

This design system completely eliminates drop shadows, blurs, skeuomorphic shading, and colored ambient glows. Elevation is structural, mechanical, and layered:

1. **Card Deck Layering**: Depth is conveyed through a physical card deck metaphor—stacking rectangular layers sequentially with hard 1px solid `#000000` architectural borders and alternating background tones (`#FFFFFF` on `#FBFBFB` on `#F4F4F4`).
2. **Offset Accents**: For active states or modal overlays, apply a hard 2px or 4px solid black offset drop shadow with 0px blur radius (pure geometric translation).
3. **Drafting Dividing Lines**: Use crisp 1px hairline rules (`#000000` or `#E5E5E5`) to segment internal card sections without increasing visual weight.

## Shapes

The shape system strictly enforces `roundedness: 0` (0px radius) across all visual primitives. Cards, buttons, sheets, badges, dialogs, and form elements must feature razor-sharp 90-degree right angles. Soft corners, pills, or rounded tabs are strictly prohibited.

## Components

### Buttons
- **Primary Button**: Solid `#000000` fill, pure `#FFFFFF` Space Grotesk uppercase text, 0px border radius, 48px fixed height on mobile, 1px `#000000` border.
- **Secondary Button**: Pure `#FFFFFF` or `#FBFBFB` surface, 1px solid `#000000` border, `#000000` Space Grotesk text. On tap/hover, invert instantly to solid black fill with white text.

### Todo Cards & Deck Hierarchy
- Constructed as razor-sharp rectangles with a solid 1px `#000000` hairline border and `#FFFFFF` fill.
- Internal padding: `space-lg` (20px–24px).
- Completed tasks: Strike-through typography (`line-through`), title color shifts to `#767676`, and the card surface changes from `#FFFFFF` to `#F4F4F4`.
- Stacked Deck Mode: Consecutive tasks in a group can overlap vertically with a 4px visible top border offset, creating a physical drafting ledger deck.

### Checkboxes
- 20x20px square with a 1px solid `#000000` border and 0px radius.
- Unchecked: `#FFFFFF` fill.
- Checked: Inverts to a solid `#000000` square containing an inset 8x8px pure `#FFFFFF` centered square or a sharp 45-degree architectural slash line.

### Input Fields
- Underlined or fully boxed 1px solid `#000000` perimeter with zero border radius.
- Background: `#FFFFFF` or `#FBFBFB`.
- Focus state: Border transitions to 2px solid `#000000`. Placeholders styled in `#767676` Inter.

### Chips & Metadata Tags
- Rectangular blocks with 1px solid `#000000` borders, zero corner radius, horizontal padding of `space-sm` (8px), vertical padding of `space-xs` (4px).
- Typography: Space Grotesk `label-sm` in all caps.

### Counter & Progress Indicator
- Custom architectural ratio component (e.g., `04 / 12 COMPLETED`) rendered in uppercase Space Grotesk, flanked by a 1px thick segmented black tracking line.