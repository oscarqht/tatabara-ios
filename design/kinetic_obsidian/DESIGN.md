# Design System Documentation: The High-Performance Kinetic Aesthetic

## 1. Overview & Creative North Star: "The Neon Pulse"
This design system is built for the high-intensity, data-driven athlete. The North Star is **"The Neon Pulse"**—a philosophy that treats the interface not as a static tool, but as a living, glowing instrument. 

To move beyond the generic "fitness tracker" look, we employ **Kinetic Layering**. This breaks the traditional grid through intentional asymmetry, where data points "float" over deep-space backgrounds and timers are treated as editorial hero elements. We bypass the "template" look by utilizing extreme typographic contrast and depth created through luminosity rather than lines.

---

## 2. Colors: Tonal Depth & Radiant Accents
The palette is rooted in a deep obsidian base (`#0e0e0e`) to maximize contrast for the vibrant "Electric Lime" (`primary`) and "Cyan" (`secondary`) accents.

### Color Tokens
- **Background & Surfaces:**
  - `surface`: `#0e0e0e` (The void)
  - `surface_container_low`: `#131313` (Base sections)
  - `surface_container_highest`: `#262626` (Active cards)
- **Accents (The "Pulse"):**
  - `primary`: `#f4ffc8` (Electric Lime Highlight)
  - `primary_container`: `#cffc00` (The "Glow" base)
  - `secondary`: `#00f4fe` (Cyan Kinetic Action)

### The "No-Line" Rule
**Standard 1px borders are strictly prohibited.** Separation of concerns must be achieved through:
1.  **Background Shifts:** Placing a `surface_container_low` card against the `surface` background.
2.  **Negative Space:** Using a rigorous 8px-based spacing scale to define boundaries.
3.  **Luminous Edge:** Using a 10% opacity `primary` glow on the top edge of a container rather than a full border.

### The "Glass & Gradient" Rule
To achieve the "cool" high-tech feel, use **Glassmorphism** for all floating overlays (e.g., active timers, workout controls). 
- **Recipe:** `surface_container_highest` at 60% opacity + `backdrop-filter: blur(20px)`.
- **Gradients:** Use a linear gradient from `primary_container` to `primary` (45 degrees) for main CTAs to create a "liquid light" effect.

---

## 3. Typography: Editorial Authority
We utilize two distinct typefaces to create an "Editorial-meets-Technical" vibe. 

- **Display & Headlines (Space Grotesk):** This is our "High-Tech" voice. Its geometric, slightly wider stance feels intentional and premium. Use `display-lg` for active timer digits and `headline-md` for workout titles.
- **Body & Labels (Inter):** Our "Functional" voice. Highly legible at small sizes. Use `label-md` for technical data points (e.g., "BPM" or "KCALS").

**The Scale Principle:** Extreme contrast is key. A `display-lg` timer (56px) should live near a `label-sm` (11px) descriptor to create a sophisticated, non-uniform hierarchy.

---

## 4. Elevation & Depth: Tonal Layering
In this design system, height is measured by light, not shadows.

- **The Layering Principle:** Depth is achieved by stacking. A workout detail card should be `surface_container_highest` sitting on a `surface_container_low` background. This "Soft Lift" replaces the need for heavy shadows.
- **Ambient Glows:** Instead of grey shadows, use **Ambient Glows**. When a button is active, apply a drop-shadow using the `primary` color at 15% opacity with a 32px blur. It should look like the button is illuminating the surface beneath it.
- **The "Ghost Border" Fallback:** If a container requires definition against a similar background, use a 1px border of `outline_variant` at **15% opacity**. It should be felt, not seen.

---

## 5. Components: The Kinetic Toolkit

### Buttons (Action Triggers)
- **Primary:** Gradient fill (`primary_container` to `primary`). Text in `on_primary_fixed`. No border. High-glow on hover.
- **Secondary:** Transparent background with a `secondary` "Ghost Border" (20% opacity). Text in `secondary`.
- **Shape:** Use the `full` roundedness scale for a sleek, aerodynamic feel.

### Kinetic Timer (Hero Component)
- **Visuals:** Large `display-lg` digits in `primary`. 
- **Effect:** A subtle `primary_dim` outer glow (8px blur) that pulses in rhythm with the seconds.

### Workout Cards
- **Style:** No borders. Use `surface_container_low`. 
- **Hierarchy:** Forbid divider lines. Use `body-sm` in `on_surface_variant` to create a clear "gap" between data sets. Use vertical padding (24px) to separate the exercise name from the rep count.

### Input Fields
- **Style:** Minimalist under-line only. When focused, the line transitions from `outline_variant` to a `secondary` (Cyan) glow.
- **Background:** `surface_container_lowest`.

### Chips (Data Tags)
- **Style:** Small, `full` radius. Use `surface_variant` with `label-sm` text. These should feel like small "readouts" from a cockpit.

---

## 6. Do's and Don'ts

### Do:
- **Do** use intentional asymmetry. Align a timer to the left and a "Next Up" label to the far right to create tension.
- **Do** lean into "Pure Black" (`#000000`) for the lowest surface containers to make the lime accents "pop."
- **Do** use `backdrop-blur` for all navigation bars and modal overlays.

### Don't:
- **Don't** use 100% opaque borders. It kills the "high-tech" atmosphere.
- **Don't** use standard Material Design drop shadows. They look muddy on dark themes; use color-tinted glows instead.
- **Don't** clutter the screen. If a piece of data isn't vital for the current "rep," hide it or reduce its opacity to 30%.
- **Don't** use rounded corners below `0.5rem` (`lg`). Everything should feel smooth and continuous.

---

## Director’s Final Note
This design system is about the **energy of movement**. Every element should feel like it was machined from a single block of glass and lit from within. Avoid the "box" mentality; think in layers of light.