# Code→Design Pipeline (workflows-design)

Phase 1-7 execution guide for `/stitch design [feature]`.

## Phase 1: Code Analysis

**Goal:** Extract all screens, interactions, and states from the project source code.

**Steps:**

1. Determine project stack:
   - Flutter: `Glob: lib/**/*.dart`
   - React: `Glob: src/**/*.{tsx,jsx}`
   - Next.js: `Glob: app/**/*.{tsx,jsx}`

2. Find screens/pages:
   - Flutter: `Grep: class.*Screen|class.*Page|class.*View` in `lib/`
   - React/Next: `Grep: export default|export function` in page files

3. Find routes/navigation:
   - Flutter: `Grep: GoRoute|MaterialPageRoute|Navigator.push`
   - React/Next: File-based routing or `Grep: useRouter|Link`

4. Find interactions:
   - `Grep: onTap|onPressed|onClick|onSubmit|GestureDetector`

5. Find states:
   - `Grep: Loading|Error|Empty|CircularProgressIndicator|Shimmer|skeleton`

**Output:** Screen list, interaction list, state list → recorded in state file.

**Transition:** Move to Phase 2 when code analysis is complete.

## Phase 2: Design Sheet

**Goal:** Create a structured design sheet mapping code to Stitch designs.

**Steps:**

1. Read `references/sheet-template.md` for format
2. Fill in:
   - 메타 테이블: feature, date, project stack, device type
   - 화면 매핑 테이블: code screen → Stitch screen name, status `[NEW]`
   - 인터랙션 체크리스트: button/nav/form interactions
   - 상태별 화면: loading, error, empty variants
   - 프롬프트 초안: per-screen Stitch prompt
3. Save to `docs/plans/{date}-{feature}-design-sheet.md`
4. **사용자 확인 요청** — 시트를 승인해야 Phase 3로 진행

**Transition:** User approves the design sheet.

## Phase 3: Prompt Optimization

**Goal:** Optimize prompts for Stitch's AI generation.

**Steps:**

1. Read `references/prompting.md`
1-1. Read `references/official/enhance-prompt/` → 공식 프롬프트 최적화 로직 참조
2. For each screen prompt:
   - Add UI/UX keywords (modern, clean, minimal, etc.)
   - Add atmosphere/vibe adjectives
   - Specify device type explicitly
   - Include component details (nav bar, cards, buttons, etc.)
   - Add branding if applicable
3. Determine `deviceType`: `MOBILE` for Flutter, `DESKTOP` for web
4. Update prompts in the design sheet

**Transition:** All prompts optimized → Phase 4.

## Phase 4: Stitch Design Generation

**Goal:** Create Stitch project and generate all screens.

**analysis.md 통합:**
- `docs/plans/*-analysis.md` 존재 시 → 해당 파일의 Feature별 프롬프트를 직접 사용 (Phase 1-3 산출물 대체)
- 없으면 → Phase 2 design sheet의 프롬프트 사용 (하위 호환)

**Steps:**

1. Create project:
   ```
   create_project(title: "{feature} Design")
   → Save projectId to state file
   ```

2. Create design system (DESIGN.md 폴백):
   ```
   Try: create_design_system(projectId, theme: {...})
   If tool_not_found error:
     → Read references/official/design-md/
     → 프로젝트에 .stitch/DESIGN.md 생성
     → "MCP 디자인 시스템 도구가 현재 비활성입니다. DESIGN.md로 대체합니다."
   If success:
     → Save designSystemId (기존 플로우)
   ```

3. Generate screens (one by one):
   ```
   For each screen in design sheet:
     generate_screen_from_text(
       projectId: "{projectId}",
       prompt: "{optimized prompt}",
       deviceType: "MOBILE" or "DESKTOP" or "TABLET" or "AGNOSTIC",
       modelId: "GEMINI_3_PRO"
     )
     → Record screenId in design sheet
     → Mark screen as [DONE]
   ```

   **Important:** Each generation can take 1-3 minutes. Do NOT retry on timeout.

4. Apply design system:
   ```
   apply_design_system(projectId, designSystemId)
   ```

5. Generate variants if needed:
   ```
   generate_variants(projectId, selectedScreenIds, prompt, variantOptions)
   ```

6. 멀티페이지 일괄 생성 옵션:
   - 화면 수가 5개 이상일 때 `references/official/stitch-loop/` 패턴 참조 가능
   - 단일 프롬프트로 여러 화면을 일괄 생성하여 크레딧 효율화

7. Update state file:
   ```yaml
   phase: verify
   project_id: "{projectId}"
   ```


**Transition:** All screens generated → Phase 5 (verification loop starts).

## Phase 5: Verification

**Goal:** Cross-check generated designs against the design sheet.

**Steps:**

1. For each screen in the design sheet:
   ```
   get_screen(projectId, screenId) → downloadUrls
   web_fetch(downloadUrl.screenshot) → /tmp/stitch-{screenName}.png
   sips -Z 1200 /tmp/stitch-{screenName}.png
   Read /tmp/stitch-{screenName}.png → visual inspection
   ```

2. Check against design sheet checklist:
   - [ ] Screen exists and matches description
   - [ ] Key UI components present (nav, cards, buttons, etc.)
   - [ ] Interactions are visually represented
   - [ ] States (loading/error/empty) are included

3. Count gaps:
   ```
   MISSING_SCREEN: count of screens not generated
   MISSING_INTERACTION: count of interactions not reflected
   MISSING_STATE: count of missing state screens
   total_gaps: sum of all
   ```

4. Record in state file body.

**Transition:** If gaps == 0 → Phase 7. If gaps > 0 → Phase 6.

## Phase 6: Fix

**Goal:** Fix gaps found in verification.

**모델:** 수정/재생성에는 `GEMINI_3_FLASH` 사용 (크레딧 절약)
- edit_screens(..., modelId: "GEMINI_3_FLASH")
- generate_screen_from_text(..., modelId: "GEMINI_3_FLASH")

**Steps:**

For each gap:
- Missing screen → `generate_screen_from_text` with new prompt
- Missing interaction → `edit_screens` with fix prompt
- Missing state → `generate_screen_from_text` for state variant

**Transition:** Return to Phase 5.

## Phase 7: Completion

**Goal:** Mark pipeline as complete.

**Steps:**

1. Output: `<promise>DESIGN_VERIFIED</promise>`
2. Update design sheet with final results (all `[DONE]`)
3. State file is auto-cleaned by Stop hook

**The Stop hook will detect the promise and allow the session to end.**
