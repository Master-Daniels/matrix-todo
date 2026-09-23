---
name: Architectural Brutalism
colors:
    surface: "#f9f9f9"
    surface-dim: "#dadada"
    surface-bright: "#f9f9f9"
    surface-container-lowest: "#ffffff"
    surface-container-low: "#f3f3f4"
    surface-container: "#eeeeee"
    surface-container-high: "#e8e8e8"
    surface-container-highest: "#e2e2e2"
    on-surface: "#1a1c1c"
    on-surface-variant: "#4c4546"
    inverse-surface: "#2f3131"
    inverse-on-surface: "#f0f1f1"
    outline: "#7e7576"
    outline-variant: "#cfc4c5"
    surface-tint: "#5e5e5e"
    primary: "#000000"
    on-primary: "#ffffff"
    primary-container: "#1b1b1b"
    on-primary-container: "#848484"
    inverse-primary: "#c6c6c6"
    secondary: "#5d5e66"
    on-secondary: "#ffffff"
    secondary-container: "#e3e1ec"
    on-secondary-container: "#63646c"
    tertiary: "#000000"
    on-tertiary: "#ffffff"
    tertiary-container: "#1a1c1d"
    on-tertiary-container: "#838485"
    error: "#ba1a1a"
    on-error: "#ffffff"
    error-container: "#ffdad6"
    on-error-container: "#93000a"
    primary-fixed: "#e2e2e2"
    primary-fixed-dim: "#c6c6c6"
    on-primary-fixed: "#1b1b1b"
    on-primary-fixed-variant: "#474747"
    secondary-fixed: "#e3e1ec"
    secondary-fixed-dim: "#c6c5cf"
    on-secondary-fixed: "#1a1b22"
    on-secondary-fixed-variant: "#46464e"
    tertiary-fixed: "#e2e2e3"
    tertiary-fixed-dim: "#c6c6c7"
    on-tertiary-fixed: "#1a1c1d"
    on-tertiary-fixed-variant: "#454748"
    background: "#f9f9f9"
    on-background: "#1a1c1c"
    surface-variant: "#e2e2e2"
typography:
    display:
        fontFamily: Megrim
        fontSize: 40px
        fontWeight: "700"
        lineHeight: 44px
        letterSpacing: -0.04em
    headline-lg:
        fontFamily: Megrim
        fontSize: 28px
        fontWeight: "600"
        lineHeight: 32px
        letterSpacing: -0.03em
    headline-md:
        fontFamily: Megrim
        fontSize: 22px
        fontWeight: "600"
        lineHeight: 26px
        letterSpacing: -0.02em
    headline-sm:
        fontFamily: Megrim
        fontSize: 18px
        fontWeight: "600"
        lineHeight: 22px
        letterSpacing: -0.01em
    body-lg:
        fontFamily: Megrim
        fontSize: 16px
        fontWeight: "400"
        lineHeight: 22px
        letterSpacing: 0em
    body-md:
        fontFamily: Megrim
        fontSize: 14px
        fontWeight: "400"
        lineHeight: 20px
        letterSpacing: 0em
    body-sm:
        fontFamily: Megrim
        fontSize: 12px
        fontWeight: "400"
        lineHeight: 16px
        letterSpacing: 0.01em
    label-lg:
        fontFamily: Space Mono
        fontSize: 13px
        fontWeight: "700"
        lineHeight: 16px
        letterSpacing: 0.08em
    label-md:
        fontFamily: Space Mono
        fontSize: 11px
        fontWeight: "400"
        lineHeight: 14px
        letterSpacing: 0.06em
    label-sm:
        fontFamily: Space Mono
        fontSize: 10px
        fontWeight: "400"
        lineHeight: 12px
        letterSpacing: 0.08em
    index-indicator:
        fontFamily: Space Mono
        fontSize: 11px
        fontWeight: "700"
        lineHeight: 11px
        letterSpacing: 0.1em
spacing:
    gutter: 0px
    margin: 0px
    space-xs: 0.25rem
    space-sm: 0.5rem
    space-md: 1rem
    space-lg: 1.5rem
    space-xl: 2rem
---

## Brand & Style

This design system embodies an uncompromising architectural brutalism tailored for high-focus mobile productivity, task tracking, and personal execution. Stripping away decorative ornamentation, soft shadows, and unnecessary gradients, the interface functions like a technical blueprint or structural ledger.

The target audience consists of builders, designers, engineers, and minimalists who value extreme clarity, structural density, and functional utility over playful consumer aesthetics.

The experience evokes precision, discipline, and uncompromising order:

- **Structural Blueprinting:** Every layout element is delineated by explicit 1px solid black bounding lines, forming an unbroken matrix of modular cells.
- **Indexical Taxonomy:** Information hierarchy relies on serial numbers (`01`, `02`, `03`), strict typographic scale, and technical monospaced indices.
- **Binary Dynamic:** Active, completed, or prioritized states do not use accent hues; instead, they trigger high-contrast inversions (black fills with crisp white typography).

## Colors

The palette is radically austere and strictly monochrome, drawing directly from technical schematics and Swiss editorial brutalism:

- **Primary (`#000000`):** The absolute structural anchor. Used for primary text, solid inverted active states, and 1px bounding grid borders.
- **Neutral Background (`#FFFFFF`):** The base canvas surface providing pure stark negative space within cells.
- **Tertiary Surface (`#F4F4F5`):** A cold, subtle architectural concrete tone applied selectively to secondary grid modules, disabled states, or alternating matrix cells to provide structural rhythm without introducing chroma.
- **Secondary Muted (`#71717A`):** Used for metadata, step indexing (e.g., cell index identifiers `01/`, `02/`), timestamps, and uncompleted secondary indicators.

Color never indicates state; state changes are communicated entirely through structural inversion (`#FFFFFF` on `#000000`), border weight emphasis, or strike-through typographic treatment.

## Typography

The typographic identity contrasts the geometric rigidity of Megrim with the algorithmic precision of Space Mono:

- **Headings & Body (Megrim):** Provides high structural presence with distinctive geometric angles and tight tracking. Used for screen titles, task titles, and primary reading copy.
- **Labels, Indices & Metadata (Space Mono):** Used for technical labeling, numeric counts, dates, status badges, and numbered matrix cells (`01`, `02`, `03`). All labels default to uppercase with extended letter spacing to mimic architectural specification sheets.
- **Rule of Composition:** Headers and body copy are set with tight leading, accentuating the , compact layout density.

## Layout & Spacing

The layout rejects conventional floating cards and loose gaps. Instead, it operates on a contiguous monolithic cell grid where elements share explicit structural lines:

- **Contiguous Grid (`gutter: 0px`, `margin: 0px`):** Top-level layout blocks share borders. Rather than margin-separated floating modules, the mobile screen is subdivided into touching quadrats framed by 1px solid black rules (`border-collapse` paradigm).
- **Edge-to-Edge Framework:** Mobile screens use edge-to-edge containers. Outer screen gutters are eliminated in favor of internal cell padding (`space-md` or `space-lg`).
- **Internal Padding Rhythm:**
    - `space-xs` (4px) and `space-sm` (8px) for badge internals, counters, and tightly associated metadata.
    - `space-md` (16px) for standard task rows and input field interiors.
    - `space-lg` (24px) for expansive hero blocks and primary matrix category containers.
    - `space-xl` (32px) reserved for major structural dividers and terminal action zones.
- **Grid Adaptability:** On mobile devices, tasks and categories stack into single-column or 2-column matrix arrangements (`50% / 50%` split). Larger screens expand the cell grid horizontally (3 or 4 columns) while keeping borders interconnected.

## Elevation & Depth

This system eliminates physical depth metaphors, drop shadows, and soft ambient blurs. Depth is strictly planar and architectural:

- **Zero Shadows:** Elevation tokens (`box-shadow`) are universally `none`.
- **Structural 1px Boundaries:** Layer separation is achieved exclusively using `1px solid #000000` rules.
- **Inverted Inset State:** When an element is selected, active, or in focus, depth is manifested as a total binary surface inversion: the background shifts from `#FFFFFF` to `#000000` and typography switches to `#FFFFFF`.
- **Tonal Sub-Level:** Secondary modules or nested subtasks adopt `#F4F4F5` backgrounds while maintaining the 1px solid black border, creating an explicit visual hierarchy without breaking the flat plane.
- **Modal Overlays:** Modals and bottom sheets do not use soft blur scrims. They use an opaque white or black container with a 2px top border or a dense 50% technical stipple/hatch overlay.

## Shapes

Sharpness is an absolute invariant across the entire system:

- **0px Border-Radius Everywhere:** Every button, cell, input, pill, badge, and modal container has a `border-radius` of `0px`.
- **Rectilinear Discipline:** No rounded corners, circular avatars, or soft pills are permitted. User avatars and progress indicators are rendered as solid black squares or sharp monospaced textual badges.
- **Orthogonal Integrity:** All dividers and borders must meet at clean 90-degree right angles, reinforcing the blueprint ethos.

## Components

### Buttons

- **Primary Action Button:** Full 1px solid `#000000` border, `#000000` fill, and `#FFFFFF` uppercase label in Space Mono (`label-lg`). `0px` radius. Hover/active states invert to `#FFFFFF` fill with `#000000` text.
- **Secondary Button:** 1px solid `#000000` border, `#FFFFFF` fill, `#000000` text. On tap/active, inverts to solid `#000000`.
- **Ghost Action:** Underlined text button with a sharp 1px text underline and an adjacent right-aligned arrow (`->`).

### Numbered Grid Cells & Task Cards

- **Structure:** Bounded by `1px solid #000000` borders on all shared sides.
- **Cell Header:** Top-left metadata counter (`01/`, `02/`, `03/`) set in Space Mono (`index-indicator`, `#71717A`), positioned precisely at `space-sm` padding.
- **Cell Body:** Task title in Megrim (`headline-sm` or `body-lg`).
- **Completed State:** Background transitions to `#F4F4F5`, title text receives a 1px solid black line-through strikethrough, and index updates to `[OK]`.
- **Active State:** Whole cell inverts to `#000000` background with `#FFFFFF` text.

### Checkboxes & Selection Controls

- **Checkbox:** Square bounding box (`18px x 18px`), `1px solid #000000`, `0px` radius.
- **Checked Indicator:** Not a curved checkmark, but an inverted solid black square fill (`#000000`) or a sharp diagonal cross mark (`X`) rendered in Space Mono.

### Text Inputs & Form Fields

- **Container:** Rectilinear box with `1px solid #000000` perimeter and `space-md` internal padding. Background is `#FFFFFF`.
- **Typography:** Megrim (`body-md`) for typed value; Space Mono uppercase (`label-sm`, `#71717A`) for sticky inset top labels.
- **Focus State:** Border weight thickens to `2px solid #000000`, or the field container inverts temporarily upon submission.

### Filter Chips & Tags

- **Appearance:** Modular rectangular blocks with `1px solid #000000`, `0px` radius, padding `4px 8px`.
- **Typography:** Uppercase Space Mono (`label-sm`).
- **Active State:** Solid black fill with white text.

### Bottom Navigation & Tab Bars

- **Frame:** Anchored directly to viewport bottom with `border-top: 1px solid #000000`. Zero floating gaps or rounded corners.
- **Tabs:** Split into equal fractional grid segments (`flex: 1`) separated by `1px solid #000000` vertical dividers.
- **Active Tab:** Inverted black cell with white label and mono numeric index.
