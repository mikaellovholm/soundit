# SoundIt Style Guide — Blaxploitation Cinema

This guide defines the visual language for SoundIt, inspired by 1970s Blaxploitation film posters and cinema. Claude should reference this when making any UI decisions — colors, fonts, spacing, components, imagery.

## Mood

Confident, bold, warm, gritty. Think funk album cover meets vintage film poster. The app should feel like stepping into a 1970s cinema lobby — dark, warm-lit, with loud poster art on the walls. Never sterile or minimal. Textured over flat. Analog over digital.

## Color Palette

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| **Midnight** | `#1A1118` | Primary background — near-black with warm undertone |
| **Cocoa** | `#2E1E28` | Secondary background — cards, sheets, elevated surfaces |
| **Leather** | `#5C3A2E` | Tertiary — borders, dividers, subtle accents |

### Accent Colors

| Name | Hex | Usage |
|------|-----|-------|
| **Coffy Red** | `#D4371C` | Primary accent — buttons, active states, destructive actions |
| **Mustard Gold** | `#E8A917` | Secondary accent — highlights, badges, progress indicators |
| **Shaft Purple** | `#6B4FA0` | Tertiary accent — links, selected states, 3D shadow effects |
| **Foxy Orange** | `#E86A2C` | Warm accent — gradients paired with red or gold |

### Text Colors

| Name | Hex | Usage |
|------|-----|-------|
| **Cream** | `#F5E6D3` | Primary text on dark backgrounds |
| **Smoke** | `#A89585` | Secondary/muted text |
| **Hot White** | `#FFF8F0` | High-emphasis headings, titles |

### Status Colors

| Name | Hex | Usage |
|------|-----|-------|
| **Coffy Red** | `#D4371C` | Error states |
| **Mustard Gold** | `#E8A917` | Processing / in-progress |
| **Superfly Green** | `#4A9E5C` | Success / ready |
| **Shaft Purple** | `#6B4FA0` | Informational |

### Gradients

- **Poster Fade**: `Midnight` → `Cocoa` (vertical, for backgrounds)
- **Heat**: `Coffy Red` → `Foxy Orange` (horizontal/diagonal, for emphasis buttons)
- **Gold Rush**: `Mustard Gold` → `Foxy Orange` (for progress bars, loading states)

## Typography

### Display / Headlines

**Font**: Use iOS system fonts with heavy weights to approximate the chunky, high-impact poster lettering of the genre. Prefer `.bold` or `.heavy` weights with tight tracking.

- App title / hero text: `.largeTitle` weight `.black`, tracking `-0.5`
- Section headers: `.title2` weight `.bold`
- Card titles: `.headline` weight `.bold`

All headlines should feel dense and commanding — like painted poster lettering.

### Body Text

- Primary body: `.body` weight `.regular` in Cream
- Secondary/captions: `.caption` weight `.medium` in Smoke
- Buttons: `.headline` weight `.bold` in Hot White, all uppercase with `+1` tracking

### Style Rules

- Headlines: uppercase or title case — never sentence case
- Buttons: always uppercase
- Body: normal sentence case
- Letter-spacing on headlines should be slightly tighter than default
- Letter-spacing on uppercase buttons should be slightly wider than default

## Shapes & Layout

### Corner Radius

- Small elements (badges, chips): `6pt`
- Cards / sheets: `12pt`
- Buttons: `10pt`
- Full-round only for avatars or circular icons

### Shadows & Depth

Shadows should be warm-toned, not neutral gray:
- Card shadow: `Color("Midnight").opacity(0.6)`, radius `12`, y-offset `6`
- Elevated shadow: `Color.black.opacity(0.8)`, radius `20`, y-offset `10`

### Spacing

Use a `4pt` base grid. Common spacing values: `4, 8, 12, 16, 24, 32, 48`.

### Borders

Subtle `1pt` borders in `Leather` color to define card edges on dark backgrounds. Use `Coffy Red` or `Mustard Gold` for active/selected borders.

## Components

### Buttons

- **Primary**: `Heat` gradient background, `Hot White` uppercase text, `10pt` radius
- **Secondary**: `Leather` background with `Cream` text, `10pt` radius
- **Destructive**: Solid `Coffy Red` background, `Hot White` text
- All buttons should feel chunky — minimum `48pt` height, generous horizontal padding (`24pt+`)

### Cards / Grid Cells

- `Cocoa` background with `1pt` `Leather` border
- `12pt` corner radius
- Image fills top, text content below with `12pt` padding
- Status indicators use colored dot or badge in top-right corner

### Navigation & Bars

- Navigation bar: `Midnight` background, `Hot White` title text
- Tab bar / bottom actions: `Cocoa` background with `Leather` top border
- Active tab: `Mustard Gold` icon + label
- Inactive tab: `Smoke` icon + label

### Sheets / Modals

- `Cocoa` background
- Drag indicator in `Leather`
- Content uses standard spacing and text colors

### Status Badges

- Small rounded rectangle (`6pt` radius)
- Background: status color at `0.2` opacity
- Text: status color at full opacity, `.caption` weight `.bold`, uppercase

## Imagery & Texture

### Film Grain

Apply a subtle noise/grain texture overlay at low opacity (`0.03–0.05`) on backgrounds to evoke analog film. This is optional and should never affect readability.

### Iconography

- Prefer SF Symbols with `.bold` weight
- Tint icons in `Cream` (default) or accent colors (interactive)
- Icons should feel solid and substantial, not thin or outlined

### Empty States

- Use `Smoke` colored text with a large SF Symbol in `Leather`
- Messaging should be brief and confident in tone — no cutesy copy

## Do / Don't

**Do:**
- Use warm, dark backgrounds everywhere
- Make buttons and interactive elements feel bold and chunky
- Use accent colors sparingly for maximum impact
- Keep high contrast between text and backgrounds
- Use uppercase for headings and buttons

**Don't:**
- Use pure white (`#FFFFFF`) or pure black (`#000000`) backgrounds
- Use thin/light font weights for anything prominent
- Use cool grays or blues as neutral tones — always warm
- Make the UI feel minimal, sterile, or "tech-startup clean"
- Overuse accent colors — the dark warmth is the canvas, accents are the paint
