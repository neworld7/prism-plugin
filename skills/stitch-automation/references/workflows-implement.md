# Design→Code Pipeline (workflows-implement)

Phase 1-7 execution guide for `/stitch implement [feature]`.

## Phase 1: Stitch Design Collection

**Goal:** Collect all design data from the Stitch project.

**Steps:**

1. List projects:
   ```
   list_projects(filter: "view=owned")
   → Show project list to user
   → User selects project (or auto-detect from state file)
   → Save projectId
   ```

2. List screens:
   ```
   list_screens(projectId)
   → Record all screen names and IDs
   ```

3. Download screen data:
   ```
   For each screen:
     get_screen(name: "projects/{projectId}/screens/{screenId}",
                projectId: "{projectId}",    # deprecated, 하위호환
                screenId: "{screenId}")       # deprecated, 하위호환
     → metadata + downloadUrls
     web_fetch(downloadUrl.html) → save to /tmp/stitch-{screenName}.html
     web_fetch(downloadUrl.screenshot) → save to /tmp/stitch-{screenName}.png
     sips -Z 1200 /tmp/stitch-{screenName}.png
   ```

**Output:** Screen data files in /tmp, screen inventory in state file.

**Transition:** All screen data collected → Phase 2.

## Phase 2: Code Mapping

**Goal:** Map Stitch screens to existing code files.

**Steps:**

1. Explore existing code:
   - Flutter: `Glob: lib/**/*.dart` → find screens/pages
   - React: `Glob: src/**/*.{tsx,jsx}` → find components/pages
   - Next.js: `Glob: app/**/*.{tsx,jsx}` → find route pages

2. Build mapping table:
   ```
   | Stitch Screen | Code File | Status |
   |---------------|-----------|--------|
   | Home Dashboard | lib/features/home/home_screen.dart | [EDIT] |
   | Login Screen | (none) | [NEW] |
   | Profile | lib/features/profile/profile_screen.dart | [OK] |
   ```

   - `[NEW]` — no code exists, needs creation
   - `[EDIT]` — code exists but needs update
   - `[OK]` — code already matches design

**Transition:** Mapping complete → Phase 3.

## Phase 3: Implementation Plan Sheet

**Goal:** Create a detailed plan for code conversion.

**Steps:**

1. Read `references/sheet-template.md` (implement variant)
2. For each `[NEW]` and `[EDIT]` screen:
   - Analyze Stitch HTML structure
   - Plan widget/component tree
   - Map Tailwind classes to target framework

3. **Flutter conversion strategy:**
   ```
   HTML <div> → Container/Column/Row
   HTML <nav> → AppBar/BottomNavigationBar
   HTML <button> → ElevatedButton/TextButton
   HTML <img> → Image.network/Image.asset
   HTML <input> → TextField
   HTML <ul>/<li> → ListView/ListTile
   Tailwind flex → Row/Column with MainAxisAlignment
   Tailwind grid → GridView
   Tailwind p-4 → EdgeInsets.all(16)
   Tailwind text-xl → TextStyle(fontSize: 20)
   Tailwind bg-blue-500 → Color(0xFF3B82F6)
   Tailwind rounded-lg → BorderRadius.circular(8)
   ```

4. **React/Next.js conversion strategy:**
   ```
   Stitch HTML → nearly as-is (Tailwind-based)
   Split into components
   Add state management (useState/useEffect)
   Add routing (Next.js file-based or React Router)
   ```

5. Save to `docs/plans/{date}-{feature}-implement-sheet.md`
6. **사용자 확인 요청** — 시트를 승인해야 Phase 4로 진행

**Transition:** User approves the implementation sheet.

## Phase 4: Code Implementation

**Goal:** Write actual code based on the plan sheet.

**Steps:**

For each screen (ordered by dependency):

1. **Flutter:**
   ```
   Create: lib/features/{feature}/presentation/{screen_name}_screen.dart
   - Import material.dart and project theme
   - Build widget tree matching Stitch HTML structure
   - Apply theme colors from design system
   - Add navigation connections
   ```

2. **React/Next.js:**
   ```
   Read references/official/react-components/ → 컴포넌트 변환 전략

   Create: src/components/{ScreenName}.tsx (or app/{route}/page.tsx)
   - Copy relevant Stitch HTML structure
   - Split into sub-components
   - Add interactivity (onClick, useState)
   - Connect to routing
   ```

3. After each screen:
   - Mark as `[DONE]` in implement sheet
   - Run project build to verify no errors

4. Update state file:
   ```yaml
   phase: code_verify
   ```

**Transition:** All screens implemented → Phase 5 (verification loop starts).

## Phase 5: Visual Verification

**Goal:** Compare implemented code visually against Stitch designs.

**Steps:**

1. Get Stitch design screenshots:
   ```
   For each screen:
     get_screen(projectId, screenId) → downloadUrls
     web_fetch(downloadUrl.screenshot) → /tmp/stitch-{screen}.png
     sips -Z 1200 /tmp/stitch-{screen}.png
   ```

2. Get implementation screenshots:
   ```
   Flutter:
     xcrun simctl io booted screenshot /tmp/impl-{screen}.png
     sips -Z 1200 /tmp/impl-{screen}.png
     (navigate to each screen in simulator first)

   React/Next.js:
     cv_screenshot or playwright browser_take_screenshot
     → /tmp/impl-{screen}.png
     sips -Z 1200 /tmp/impl-{screen}.png
   ```

3. Compare:
   ```
   Read /tmp/stitch-{screen}.png
   Read /tmp/impl-{screen}.png
   → Analyze: layout, colors, components, spacing, typography
   ```

4. Classify diffs:
   ```
   HIGH: Missing elements (buttons, sections, images)
   MED: Color mismatch, layout structure differences
   LOW: Spacing, font size, minor alignment
   ```

5. Record diffs in state file and implement sheet.

**Transition:** If total HIGH+MED == 0 → Phase 7. If > 0 → Phase 6.

## Phase 6: Fix

**Goal:** Fix visual differences between design and implementation.

**Steps:**

For each HIGH/MED diff:
1. Identify the specific code section
2. Compare with Stitch HTML for the correct structure
3. Fix the code
4. Rebuild and re-screenshot

**Transition:** Return to Phase 5.

## Phase 7: Completion

**Goal:** Mark pipeline as complete.

**Steps:**

1. Output: `<promise>CODE_VERIFIED</promise>`
2. Update implement sheet with final results (all `[DONE]`)
3. State file is auto-cleaned by Stop hook

**The Stop hook will detect the promise and allow the session to end.**
