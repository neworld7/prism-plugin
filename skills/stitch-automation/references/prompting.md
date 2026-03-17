# Stitch Prompting Guide

Best practices for crafting effective prompts for Stitch AI design generation.
Based on official documentation at stitch.withgoogle.com/docs/learn/prompting/.

## Prompt Structure

A good Stitch prompt includes these components:

### 1. Define Purpose
State the screen type: homepage, login, dashboard, settings, etc.
```
Design a mobile dashboard screen for a cryptocurrency tracking app.
```

### 2. List Core UI Components
Mention key sections: buttons, cards, charts, nav bars, forms.
```
Include a top navigation bar, portfolio summary card, trending crypto slider, and a bottom navigation menu.
```

### 3. Specify Layout and Structure
Use layout keywords: grid, stacked, scrollable, centered, sidebar, split.
```
Use a horizontal scroll for trending coins and a 2-column grid for top movers.
```

### 4. Set Style and Theme
Stitch understands: color schemes, corner radius, modern/minimal/professional.
```
Use a dark theme with rounded cards and modern fonts for a clean look.
```

### 5. Include Dynamic Content
Mention data types: prices, status, avatars, progress bars.
```
Each card should show the coin name, icon, current price, and percentage change in green or red.
```

### 6. Add Branding
App name, logo placement, specific colors.
```
App name 'CryptoTrack' should appear in the top bar, with a notification bell icon on the right.
```

## High-Level vs Detailed Prompts

**High-level** (quick exploration):
```
A modern e-commerce product page
```

**Detailed** (precise results):
```
Design a mobile e-commerce product page with a full-width hero image at the top,
product name and price below, a 5-star rating with review count, size selector pills,
an "Add to Cart" button in coral color, and a tabbed section for Description/Reviews/Shipping.
Use a clean white theme with subtle shadows.
```

**Rule:** Start high-level to explore, then refine with details.

## Setting the Vibe with Adjectives

Stitch responds well to atmosphere keywords:

| Category | Keywords |
|----------|----------|
| **Modern** | sleek, contemporary, cutting-edge, futuristic |
| **Minimal** | clean, simple, uncluttered, whitespace-heavy |
| **Professional** | corporate, business, trustworthy, polished |
| **Playful** | fun, colorful, vibrant, energetic, whimsical |
| **Elegant** | luxury, sophisticated, premium, refined |
| **Dark** | dark mode, nighttime, moody, high-contrast |

## Refining Screen by Screen

After initial generation, refine individual screens:

```
Fix alignment: Place the app name on the left side of the top nav bar, not centered.
Specify chart type: Use a circular pie chart, not a bar graph.
Clarify icons: Add bottom nav icons for Home, Portfolio, Market, Settings.
Improve section: Display news with thumbnail images on left and headlines on right.
Styling: Apply slightly transparent nav bar background with neon accent colors.
```

Each refinement call uses `edit_screens` with the specific instruction.

## Controlling App Theme

### Colors
```
Use a primary color of #3B82F6 (blue) with #10B981 (green) accents.
Background should be #F9FAFB (light gray).
```

### Fonts & Borders
```
Use rounded corners (16px radius) on all cards.
Body font should be Inter, headings in Poppins.
```

## Describing Desired Imagery

```
Add a hero illustration of a person using a laptop with floating UI elements.
Use abstract geometric shapes in the background.
Include app screenshots showing the dashboard in a phone mockup.
```

## Pro Tips

1. **Be specific about layout**: "3-column grid" is better than "show items"
2. **Name your app**: Stitch will incorporate it into the design
3. **Mention platform**: "iOS-style" or "Material Design" helps Stitch choose patterns
4. **State what NOT to include**: "No sidebar navigation" prevents unwanted elements
5. **Reference existing apps**: "Similar to Spotify's Now Playing screen" gives clear direction

## Flutter-Specific Prompting

When generating designs intended for Flutter conversion:

1. **Use mobile device type**: Always set `deviceType: "MOBILE"`
2. **Mention mobile patterns**: bottom nav, floating action button, app bar, drawer
3. **Avoid web-only patterns**: horizontal nav bars, multi-column layouts that don't translate well
4. **Name screens clearly**: "Login Screen", "Home Dashboard", "Profile Settings" — maps to Dart file names
5. **Keep components standard**: Cards, Lists, Grids, Tabs — these have direct Flutter equivalents

### Example Flutter-oriented prompt:
```
Design a mobile book library screen for a reading tracker app called 'ReadCodex'.
Top: App bar with search icon and filter button.
Body: Vertical list of book cards, each showing cover image (left), title, author,
progress bar, and page count. Cards should have rounded corners and subtle elevation.
Bottom: Navigation bar with Home, Library, Stats, Profile tabs.
Use a warm white theme with serif font for book titles.
iOS-style design with safe area padding.
```
