---
name: Growth & Stability
colors:
  surface: '#f4fbf4'
  surface-dim: '#d4dcd5'
  surface-bright: '#f4fbf4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eef6ee'
  surface-container: '#e8f0e9'
  surface-container-high: '#e3eae3'
  surface-container-highest: '#dde4dd'
  on-surface: '#161d19'
  on-surface-variant: '#3c4a42'
  inverse-surface: '#2b322d'
  inverse-on-surface: '#ebf3eb'
  outline: '#6c7a71'
  outline-variant: '#bbcabf'
  surface-tint: '#006c49'
  primary: '#006c49'
  on-primary: '#ffffff'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#4edea3'
  secondary: '#545f73'
  on-secondary: '#ffffff'
  secondary-container: '#d5e0f8'
  on-secondary-container: '#586377'
  tertiary: '#505f76'
  on-tertiary: '#ffffff'
  tertiary-container: '#94a4bd'
  on-tertiary-container: '#2a3a4f'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#d3e4fe'
  tertiary-fixed-dim: '#b7c8e1'
  on-tertiary-fixed: '#0b1c30'
  on-tertiary-fixed-variant: '#38485d'
  background: '#f4fbf4'
  on-background: '#161d19'
  surface-variant: '#dde4dd'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  container-margin: 20px
  gutter: 16px
---

## Brand & Style
The design system is anchored in the intersection of organic growth and institutional reliability. The brand personality is "The Sophisticated Partner"—expert and composed, yet encouraging. It avoids the coldness of traditional banking by utilizing a Corporate Modern aesthetic that prioritizes clarity, generous whitespace, and high-quality finishing. 

The target audience consists of modern investors and professionals who value efficiency and transparency. To evoke trust, the UI employs a structured, balanced layout with subtle depth, ensuring the user feels in total control of their financial data at all times.

## Colors
The palette is designed to balance energy with authority. Emerald Green (#10B981) serves as the primary action color, used strategically for "positive" financial indicators, primary call-to-actions, and progress markers. Deep Navy (#1E293B) provides the grounding force, used for high-level navigation, headings, and primary text to establish professional stability.

Slate Gray (#64748B) handles secondary information and metadata, ensuring a clear visual hierarchy. Backgrounds should utilize a very soft neutral tint (#F8FAFC) to differentiate from pure white card surfaces, enhancing the sense of depth.

## Typography
Inter is selected for its exceptional legibility and systematic approach to data density. The typography system uses a tight scale for headlines to maintain a professional look, while body copy is given ample line height to ensure readability of complex financial figures. 

Headlines use Deep Navy to command attention. Data points—such as account balances—should utilize the `display-lg` or `headline-lg` styles with the primary Emerald Green color when representing growth or positive status.

## Layout & Spacing
This design system utilizes a fixed-width grid for desktop (12 columns) and a fluid layout for mobile (4 columns). The rhythm is based on a 4px baseline grid to ensure mathematical consistency across all components.

Information density should be kept moderate. Group related financial data within cards using `lg` (24px) padding, while using `xl` (32px) or `xxl` (48px) margins between distinct sections to create the requested "plenty of whitespace" effect.

## Elevation & Depth
Depth is achieved through ambient shadows rather than harsh lines. Surfaces use a "Layered White" approach where the main background is slightly off-white, and primary interactive cards are pure white with a very soft, diffused shadow (Blur: 12-16px, Opacity: 4-6%, Color: Deep Navy).

For modal overlays or high-priority alerts, a second tier of elevation is used with a slightly more pronounced shadow. Borders should be kept minimal—used only for form fields or secondary buttons—to maintain the clean, modern aesthetic.

## Shapes
The shape language is defined by a consistent 12px (0.75rem) corner radius for all primary containers and buttons. This "rounded" approach softens the professional Navy/Green palette, making the app feel accessible and modern. 

- **Primary Containers:** 12px (rounded-lg)
- **Buttons & Inputs:** 12px (rounded-lg)
- **Smaller Elements (Chips/Badges):** 8px (rounded-md)
- **Selection Indicators:** 4px (rounded-sm)

## Components

### Action Buttons
Primary buttons use a solid Emerald Green fill with white text to signify growth. Secondary buttons utilize a Deep Navy outline or a soft Slate Gray ghost style. Hover states should involve a subtle darkening of the green or a very light background tint for ghost buttons.

### Card-Based Layouts
Account summaries and credit cards are housed in white containers with 12px rounded corners. Each card should feature a subtle 1px border (#E2E8F0) and an ambient shadow. Content within cards is structured with primary balances at the top-left and secondary actions (like "Transfer" or "Details") at the bottom.

### Intuitive Form Fields
Inputs feature a 12px corner radius and a light gray border (#D1D5DB). Upon focus, the border transitions to Emerald Green with a soft outer glow. Labels use Slate Gray in `label-md` style, positioned above the field for maximum clarity.

### Financial Indicators
Status chips (e.g., "Pending," "Completed") use highly desaturated versions of their semantic colors (Green for success, Navy for info) with high-contrast text labels to ensure accessibility.

### Additional Components
- **Progress Bars:** Thin, 4px height bars in Emerald Green to track savings goals.
- **Data Tables:** High-legibility rows with Slate Gray dividers and Navy text for line items.