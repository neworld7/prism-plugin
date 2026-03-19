# Stitch Prompting Guide

> **공식 참조**: `references/official/enhance-prompt/`에 Google 공식 프롬프트 최적화 스킬이 포크되어 있습니다.
> 이 문서는 Stitch 프롬프팅 기본 가이드이며, enhance-prompt 스킬과 함께 사용하면 더 나은 결과를 얻을 수 있습니다.

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

## Vibe Design 전략

Stitch AI의 창의성을 최대화하면서 방향성을 잡는 접근법.

**핵심 원칙**: 디테일을 지정할수록 AI의 자유도가 줄어든다. UX 목표와 분위기만 전달하고, 시각적 구현은 AI에게 맡겨라.

### ✅ 프롬프트에 포함할 것
1. **사용자 목표**: 이 화면에서 사용자가 달성하려는 것
2. **무드/바이브**: 2-3개 형용사로 분위기 전달
3. **핵심 섹션**: 번호 매긴 고수준 레이아웃 구조
4. **UI 컴포넌트 이름**: card, nav bar, CTA button (크기/색상 안 줌)
5. **앱 컨텍스트**: 앱 이름, 카테고리
6. **네거티브**: "No sidebar", "No gradient" 등 제외 사항
7. **레퍼런스** (선택): "Similar to Spotify's Now Playing"
8. **디바이스**: `MOBILE`, `DESKTOP`, `TABLET`, `AGNOSTIC`

### ❌ 프롬프트에 포함하지 않을 것
- hex 코드 (#FF6B6B 등) → "warm coral accent" 같은 자연어 사용
- px 값 (12px, 24px 등) → "rounded corners", "generous spacing" 사용
- 특정 폰트명 (Inter, Poppins 등) → "modern sans-serif", "friendly typography" 사용
- border-radius, shadow, opacity 수치
- 정확한 간격/마진/패딩 값

### 프롬프트 분량 가이드
- **화면당 150-400자** 적정 (5,000자 이상은 컴포넌트 누락 위험)
- 짧을수록 AI가 더 다양한 해석 가능 → 변형(Variants)에 유리
- 영어로 작성 (Stitch AI 최적화)

### 좋은 프롬프트 예시
```
A clean, welcoming login screen for 'ReadCodex' reading tracker app.

Centered app branding with tagline. Modern email/password form.
Prominent sign-in button. Social login options (Google, Apple).
"Forgot password?" and "Sign up" links for alternative flows.

Mood: warm, trustworthy, bookish. Mobile-first, iOS patterns.
No sidebar. No dark theme.
```

### 나쁜 프롬프트 예시
```
Design a mobile login screen with email field (envelope icon, border-radius 12px,
#F3F4F6 background), password field (eye toggle, same styling), coral (#FF6B6B)
sign-in button (full-width, 24px radius, 16px padding), Inter font for body at 14px,
Poppins Bold for heading at 24px, warm white (#FEFEFE) background...
```
→ AI가 지시를 그대로 따르느라 창의적 대안을 탐색하지 않음

### 변형(Variants) 전략
- 기본 프롬프트를 짧고 열린 형태로 유지하면 `generate_variants`로 다양한 시안 확보 가능
- 변형 시 `creativeRange: "EXPLORE"` 또는 `"REIMAGINE"` 사용
- 각 화면에 2-3개 변형 방향 메모 (다크 모드, 일러스트 배경, 미니멀 등)
