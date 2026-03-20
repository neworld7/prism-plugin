# Design→Code Pipeline (workflows-implement)

Phase 1-7 execution guide for `/stitch implement [feature]`.

> **핵심 원칙: 기능 보존 + UI 리스킨**
> 이 파이프라인의 목적은 **기존 기능 코드의 UI/레이아웃을 Stitch 디자인에 맞게 변경**하는 것이다.
> 비즈니스 로직, 상태 관리, API 호출, 네비게이션 로직은 그대로 보존하고,
> **위젯 트리/컴포넌트 구조, 스타일링, 레이아웃만** Stitch 디자인과 1:1 매칭한다.

## Feature Routing (all 모드 전용)

> 단일 Feature 모드에서는 이 단계를 건너뛴다.

**Goal:** all 모드에서 현재 Feature의 스크린만 선별하여 처리.

**Steps:**

1. Read `.claude/stitch-implement-pipeline.local.md` → `feature` 필드 확인
2. Stitch 프로젝트에서 해당 Feature 스크린만 대상으로 설정
3. 다른 Feature의 스크린은 무시 (이미 완료됨 or 아직 차례 아님)

**Transition:** 해당 Feature 스크린 선별 → Phase 1.

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
   | Stitch Screen | Code File | Status | 보존할 기능 |
   |---------------|-----------|--------|-------------|
   | Home Dashboard | lib/features/home/home_screen.dart | [RESKIN] | API fetch, 상태관리, nav |
   | Login Screen | lib/features/auth/login_screen.dart | [RESKIN] | auth 로직, validation |
   | Profile | lib/features/profile/profile_screen.dart | [OK] | — |
   | New Feature | (none) | [NEW] | — |
   ```

   - `[RESKIN]` — 코드 존재, UI/레이아웃을 Stitch에 맞게 변경 (기능 보존)
   - `[NEW]` — 코드 없음, 새로 생성
   - `[OK]` — 이미 디자인 일치

   **대부분의 화면은 `[RESKIN]`** — 기능은 이미 구현되어 있고 디자인만 다른 상태.

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

5. Save to `.stitch/{date}-{feature}-implement-sheet.md`
6. **사용자 확인 요청** — 시트를 승인해야 Phase 4로 진행

**Transition:** User approves the implementation sheet.

## Phase 4: Code Implementation (기능 보존 + UI 리스킨)

**Goal:** 기존 기능 코드의 UI/레이아웃을 Stitch 디자인에 맞게 변경. 비즈니스 로직은 그대로 보존.

> **⚠️ 절대 규칙**: 기존 코드의 상태 관리, API 호출, 비즈니스 로직, 네비게이션 로직을 삭제하거나 변경하지 않는다.
> 변경 대상은 **위젯 트리 구조, 스타일 값, 레이아웃 속성**뿐이다.

**Steps:**

For each screen (ordered by dependency):

0. **Stitch HTML 속성 추출 (필수, 코드 수정 전 반드시 실행):**
   ```
   web_fetch(downloadUrl.html) → Stitch HTML 다운로드
   HTML 내 CSS/Tailwind 클래스에서 아래 속성을 정확히 추출:

   레이아웃: flex-direction, justify-content, align-items, gap
   크기: width, height, min-height, max-width
   간격: padding, margin (px 단위 정확히)
   보더: border-width, border-color, border-radius
   타이포그래피: font-size, font-weight, line-height, letter-spacing
   버튼: height, padding-x, padding-y, border-radius, font-size
   카드/컨테이너: padding, border-radius, box-shadow, gap
   아이콘: width, height (size)

   → 추출 결과를 implement sheet에 화면별로 기록
   → 이 값들이 코드 수정의 기준 (대략적 추정 금지)
   ```

1. **[RESKIN] 기존 파일 수정 (대부분의 경우):**

   기존 코드 파일을 열고, **build() 메서드 / return JSX 내부의 UI 부분만** 수정한다.

   ```
   보존 (절대 건드리지 않음):
   ─────────────────────────
   - import 문 (기능 관련)
   - 상태 변수 (useState, StateNotifier, BLoC, Provider 등)
   - API 호출 (fetch, dio, http, repository 등)
   - 이벤트 핸들러의 비즈니스 로직 (onTap 내부의 navigate, submit 등)
   - 라이프사이클 (initState, useEffect, dispose 등)

   변경 (Stitch 디자인에 맞춤):
   ─────────────────────────
   - 위젯 트리 / JSX 구조 (Container→Card, Column 순서 등)
   - 스타일 값 (padding, margin, border-radius, font-size, color)
   - 버튼 크기·모양 (height, borderRadius, padding)
   - 카드/컨테이너 크기·보더·그림자
   - 텍스트 스타일 (fontSize, fontWeight, color)
   - 아이콘 크기·색상
   - 간격 (gap, SizedBox, spacer)
   - 레이아웃 구조 (Row↔Column, flex 비율, alignment)
   ```

2. **Flutter 리스킨 패턴:**
   ```
   기존 파일: lib/features/{feature}/presentation/{screen_name}_screen.dart
   → 파일 내 build() 메서드의 위젯 트리만 Stitch에 맞게 재구성
   → 추출한 px 값을 1:1 매핑:
     padding: 16px → EdgeInsets.all(16)
     border-radius: 12px → BorderRadius.circular(12)
     font-size: 14px → fontSize: 14
     height: 48px → SizedBox(height: 48) or minimumSize: Size.fromHeight(48)
     gap: 8px → SizedBox(height/width: 8)
     border: 1px solid → Border.all(width: 1, color: ...)
   → 기존 onTap, onPressed 콜백의 내부 로직은 그대로 유지
   → 기존 상태 변수(isLoading, data, error 등)를 새 위젯 트리에 연결
   ```

3. **React/Next.js 리스킨 패턴:**
   ```
   Read references/official/react-components/ → 컴포넌트 변환 전략

   기존 파일: src/components/{ScreenName}.tsx (or app/{route}/page.tsx)
   → return (...) 내부의 JSX만 Stitch HTML 구조로 교체
   → Stitch HTML의 Tailwind 클래스를 그대로 적용
     (p-4, rounded-xl, h-12, gap-3, border, text-sm 등)
   → 기존 useState, useEffect, 이벤트 핸들러는 보존
   → 새 JSX에 기존 상태/핸들러를 재연결
   ```

4. **[NEW] 신규 화면 (해당되는 경우에만):**
   ```
   Stitch에만 존재하고 기존 코드에 없는 화면 → 새 파일 생성
   Stitch HTML 구조를 기반으로 위젯/컴포넌트 작성
   ```

5. After each screen:
   - Mark as `[DONE]` in implement sheet
   - **기능 테스트**: 기존 기능(탭, 네비게이션, 데이터 로딩)이 정상 동작하는지 확인
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
   HIGH: Layout structure mismatch (flex direction, container nesting 다름)
   HIGH: Button/card/input size mismatch (height, width, padding이 Stitch와 다름)
   MED: Border-radius, border-width, font-size, font-weight 차이
   MED: Spacing/gap mismatch (padding, margin, gap이 4px+ 차이)
   LOW: 1-2px 미세 차이, 색상 톤 미세 차이
   ```
   **⚠️ 레이아웃·크기 차이는 HIGH — 색상만 맞고 레이아웃이 다르면 미완성.**

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

**Goal:** Mark current Feature's pipeline as complete.

**Steps:**

1. Output: `<promise>CODE_VERIFIED</promise>`
2. Update implement sheet with final results (all `[DONE]`)
3. Stop hook이 promise를 감지하고:
   - **단일 Feature 모드**: 상태 파일 삭제 → allow (세션 종료)
   - **All 모드 + 다음 Feature 있음**: 상태 파일 전환 → block (다음 Feature 구현 지시)
   - **All 모드 + 마지막 Feature**: 상태 파일 삭제 → allow (세션 종료) → 빌드/테스트 실행

**All 모드에서 다음 Feature로 전환되면 Feature Routing → Phase 1로 돌아간다.**
