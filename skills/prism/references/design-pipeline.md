# Design Pipeline — `/prism design <feature|all>`

Design 파이프라인 실행 가이드. Phase D1-D6.
Analyze 파이프라인은 `references/analyze-pipeline.md` 참조.

### Feature Routing (all 모드 전용)

> 단일 Feature 모드에서는 건너뛴다.

1. Read `.claude/prism-design-pipeline.local.md` → `feature` 필드 확인
2. `.prism/prompts.md`에서 해당 Feature 프롬프트만 추출

### D1: prompts.md 로드

**Goal:** 프롬프트를 로드한다.

**Steps:**
1. `.prism/prompts.md` 존재 확인
2. 없으면 `/prism analyze` 먼저 실행 안내
3. 있으면 해당 Feature의 프롬프트 로드

### D2: (제거됨 — Phase 번호 호환성을 위해 유지)

> D2는 v2.10.0에서 제거되었다. Stitch가 첫 화면 생성 시 디자인 시스템을 자동 생성하므로 외부 DESIGN.md 생성이 불필요하다.
> 디자인 시스템 일관성은 D3의 "Design System Name Anchor" 패턴으로 보장한다.
> 기존 D3-D6 번호를 유지한다.

### D3: 디자인 생성 — Feature별 프로젝트

**Goal:** Feature 프롬프트로 Stitch 디자인을 생성한다.

**Design Identity 판단 (D3 시작 시):**

`./DESIGN.md` 존재 여부로 분기:

**미존재 (첫 Feature — Preview에서 DESIGN.md가 아직 선택되지 않은 경우):**
```
1. create_project → 첫 화면 generate_screen_from_text
2. get_project → designTheme에서 추출:
   - 이름: designTheme.designMd 첫 # 헤딩 파싱 또는 outputComponents 텍스트
   - designMd 전문: designTheme.designMd (전체 디자인 시스템 스펙)
   - 메타데이터: colorMode, roundness, font, headlineFont, bodyFont
   - Fallback: designMd 미생성 → 2번째 화면 후 get_project 재시도 / 2회 실패 → 앵커 없이 진행
3. DESIGN.md 저장 (프로젝트 최상위):
   | 항목 | 값 |
   |------|------|
   | Name | {추출된 이름} |
   | Source Project | projects/{projectId} |
   | Color Mode | {designTheme.colorMode} |
   | Roundness | {designTheme.roundness} |
   | Primary Font | {designTheme.font 또는 headlineFont} |
   | Body Font | {designTheme.bodyFont} |
   + "## Design System Spec" 섹션에 designMd 전문 포함
4. 같은 프로젝트 내 나머지 화면도 DESIGN SYSTEM (REQUIRED) 블록을 포함한다.
   ⚠️ "Continue using the X design system" 텍스트 앵커는 사용하지 않는다.
   Stitch는 프롬프트 텍스트만으로 화면을 생성하므로, 텍스트 앵커만으로는
   디자인 토큰(hex 코드, 폰트명 등)을 기억하지 못한다.
```

**존재 (이후 Feature — 일반적인 경우):**
```
1. ./DESIGN.md를 읽어서 DESIGN SYSTEM (REQUIRED) 블록을 구성한다
2. create_project → generate_screen_from_text (모든 프롬프트에 DESIGN SYSTEM 블록 포함)
3. 프로젝트 내 나머지 화면도 동일한 DESIGN SYSTEM 블록을 상단에 포함한다
```

> **⚠️ 절대 규칙 (v4.1.1): 모든 generate_screen_from_text 호출에 DESIGN SYSTEM (REQUIRED) 블록을 포함한다.**
> Feature, 프로젝트, 화면 순서와 무관하게 예외 없음. "Continue using..." 텍스트 앵커는 금지.
> 이 규칙을 위반하면 Stitch가 다른 색상/폰트로 화면을 생성하여 디자인 시스템 일관성이 깨진다.

> **⚠️ 핵심 교훈 (v3.4.2):** `"Continue using the X design system"` 텍스트 앵커만으로는 Stitch가 디자인 시스템을 인식하지 못한다. `./DESIGN.md`의 **실제 hex 코드, 폰트명, 스타일 규칙**을 `DESIGN SYSTEM (REQUIRED)` 블록으로 직접 포함해야 한다. 이 블록이 없으면 Stitch가 자체 해석한 **다른 색상/폰트를 생성**한다. enhance-prompt 스킬 경유 여부와 무관하게, 프롬프트에 실제 토큰이 포함되어야 한다.

**⚠️ 프로젝트 구조: Feature별 프로젝트 분리**

```
Feature별로 별도 Stitch 프로젝트를 생성한다:
→ 프로젝트 이름: "{App} · {시안명} · {Feature번호}. {Feature명}"
→ 예시: "{App} · Warm Organic · 1. Auth & Onboarding"
→ 예시: "{App} · Warm Organic · 2. Home"
→ 각 프로젝트에 해당 Feature의 모든 화면 (메인 + 서브 + 모달 + 상태)을 생성
→ 생성된 프로젝트 ID를 .prism/project-ids.md에 기록:
   | Feature | Project ID | Stitch URL |
   |---------|-----------|------------|
   | 1. Auth | 1234567890 | https://stitch.withgoogle.com/projects/1234567890 |
```

**실행 — 축 단위 배치 생성:**
```
1. create_project 호출 → 프로젝트 생성 (프로젝트 이름에 Feature 포함)
2. 해당 Feature의 화면을 축(Axis) 단위로 묶어서 배치 생성:
   - 1차 호출: Primary Screens (5-7개) — 핵심 화면 전체
   - 2차 호출: Screen States (3-5개) — empty, skeleton, error 상태
   - 3차 호출: Overlays (3-4개) — 바텀시트, 다이얼로그, 액션시트
   - 4차 호출: Interaction Modes (2-4개) — edit, search, filter 모드
3. 각 호출: generate_screen_from_text 1회 (해당 축의 화면을 간결하게 기술)
4. 생성 확인 후 다음 축으로
```

**배치 프롬프트 구조 — 2-Block 패턴 (Stitch 공식 가이드 + 디자인 토큰 주입):**

> **⚠️ 모든 배치 프롬프트에 DESIGN SYSTEM (REQUIRED) 블록을 반드시 포함한다.** 이 블록은 `./DESIGN.md`에서 추출한 실제 hex 코드, 폰트명, 스타일 규칙을 담는다. 5000자 이내를 준수하되 DESIGN SYSTEM 블록이 우선이며, Screen 설명을 간결하게 조정한다.

```
Design {N} {축 이름} screens for the {Feature} feature of {App} — {앱 설명 1줄}. {바이브 형용사}.

**DESIGN SYSTEM (REQUIRED) — "{디자인 시스템 이름}":**
- Platform: Mobile (390×844), Phone-first
- Theme: {Light/Dark}, {스타일 설명}
- Background: {이름} (#hex)
- Surface Low: {이름} (#hex)
- Surface Elevated: {이름} (#hex)
- Primary Accent: {이름} (#hex) — {용도}
- Secondary: {이름} (#hex) — {용도}
- Tertiary: {이름} (#hex) — {용도}
- Text Primary: (#hex)
- Display/Headline Font: {폰트명} ({사이즈})
- Body/Label Font: {폰트명} ({사이즈})
- Borders: {규칙}
- Corners: {규칙}
- Elevation: {규칙}

**Screen 1: {화면명}**
{간결한 설명 — 핵심 UI 요소만, 100-200자}

**Screen 2: {화면명}**
{간결한 설명}

...

All UI text must be in Korean (한국어).
```

**배치 프롬프트 예시 (도메인별 — 디자인 토큰 주입 포함):**

```
예시 A — 커머스 앱:
Design 5 primary screens for the Products feature of FreshCart — a grocery delivery app. Clean, modern, appetizing.

**DESIGN SYSTEM (REQUIRED) — "Fresh Market":**
- Platform: Mobile (390×844), Phone-first
- Theme: Light, clean, appetizing
- Background: White (#ffffff)
- Surface Low: Light Gray (#f8f9fa)
- Primary Accent: Fresh Green (#22c55e) — CTA, active states
- Secondary: Warm Orange (#f97316) — sale badges, prices
- Text Primary: Near Black (#18181b)
- Display Font: Plus Jakarta Sans (2rem)
- Body Font: Inter (1rem)
- Corners: Rounded (12px)
- Elevation: Soft shadows (8px blur, 8% opacity)

**Screen 1: 상품 목록 (그리드 뷰)**
2-column product grid with food images, names, prices, quantity steppers. Top category chips, floating cart button with badge, bottom navigation.

**Screen 2: 상품 목록 (리스트 뷰)**
Horizontal product cards with large image, name, price, weight. Add-to-cart button on each card.

**Screen 3: 상품 상세**
Hero product image, name, price, weight options. Nutrition info expandable section, related products carousel, sticky add-to-cart bar.

**Screen 4: 상품 검색**
Search bar with recent searches and voice input icon. Results as compact product cards with image, name, price.

**Screen 5: 카테고리 필터**
Full-screen category grid with icons and labels. Sub-category chips at top when category selected.

All UI text must be in Korean (한국어).
```

```
예시 B — 피트니스 앱:
Design 4 primary screens for the Dashboard feature of FitLog — a workout tracking app. Energetic, bold, motivating.

**DESIGN SYSTEM (REQUIRED) — "Active Pulse":**
- Platform: Mobile (390×844), Phone-first
- Theme: Dark, energetic, high-contrast
- Background: Deep Black (#0a0a0a)
- Surface Low: Dark Gray (#1c1c1e)
- Primary Accent: Electric Blue (#3b82f6) — CTA, progress rings
- Secondary: Neon Green (#22d3ee) — success, completed
- Tertiary: Coral (#f43f5e) — calories, heart rate
- Text Primary: White (#ffffff)
- Display Font: Satoshi (2.5rem bold)
- Body Font: Inter (1rem)
- Corners: Rounded (16px)
- Elevation: Glow shadows (primary color, 20% opacity)

**Screen 1: 오늘 대시보드**
Top greeting with streak badge. Summary cards for calories, steps, active minutes with circular progress rings. Recent workout list below.

**Screen 2: 운동 기록 상세**
Workout type icon, duration, calories burned. Heart rate chart, exercise breakdown list with sets/reps.

**Screen 3: 주간/월간 통계**
Toggle tabs for week/month. Bar chart for daily activity, line chart for trend. Category breakdown donut chart.

**Screen 4: 목표 설정**
Goal type selection (칼로리, 걸음수, 운동 시간). Slider for target value, weekly schedule checkboxes.

All UI text must be in Korean (한국어).
```

**모델 강제 규칙:**
`generate_screen_from_text` 호출 시 반드시 `modelId: "GEMINI_3_1_PRO"`를 명시한다.

**⚠️ Stitch API 배치 생성 규칙 (필수):**

Stitch `generate_screen_from_text`는 비동기적으로 동작한다. 배치 생성 시 다음 규칙을 반드시 지킨다:

1. **"no output" 응답 ≠ 실패** — API가 `(completed with no output)`을 반환해도 화면이 생성되었을 수 있다. **절대 즉시 재시도하지 않는다.**

2. **생성 확인은 `get_project`로** — `list_screens`는 빈 결과를 반환할 수 있으므로 사용하지 않는다. 대신 `get_project`의 `screenInstances` 배열에서 실제 화면 수를 확인한다.

3. **배치 생성 후 확인 절차:**
   ```
   generate_screen_from_text 호출 (1회, N개 화면 기술)
   ↓
   outputComponents 있으면 → 성공, 생성된 화면 수 확인
   outputComponents 없으면 ("no output") → 15초 간격 폴링 시작 (최대 120초)
   ↓
   매 15초마다 get_project → screenInstances 배열 확인
   ↓
   N개 이상 증가 감지 → 즉시 성공 처리
   120초까지 미증가 → 축을 2분할하여 재시도 (예: 5개 → 3개 + 2개)
   ```

4. **재시도 전 중복 체크** — `screenInstances`에 이미 존재하는 화면은 재생성하지 않는다.

5. **화면 수 기록** — 각 배치 호출 전에 `get_project`로 현재 `screenInstances.length`를 기록해두어 생성 후 비교한다.

6. **배치 실패 시 분할 전략** — N개 배치가 실패하면 축을 2분할:
   - 5개 → 3개 + 2개
   - 7개 → 4개 + 3개
   - 분할 후에도 실패 → 1개씩 개별 생성으로 폴백

7. **크레딧 소진 감지 및 안전 중단:**

   Stitch API가 rate limit 또는 크레딧 소진 에러를 반환하면:

   ```
   1. 현재 진행 상황을 상태 파일에 저장:
      - completed_screens: 이미 생성된 화면 목록 ("|" 구분)
      - current_axis: 현재 처리 중인 축 (primary/states/overlays/interactions)
      - project_id: 현재 Feature의 Stitch 프로젝트 ID
      - design_name: 현재 시안 이름 (DESIGN.md의 Name 필드)
   2. 상태 파일을 시안별 백업: .claude/prism-pipelines/{design_name}.local.md
   3. .prism/project-ids.md에 현재까지 생성된 프로젝트 ID 기록
   4. 사용자에게 안내:

      ⚠️ 크레딧이 소진되었습니다.

      시안: {design_name}
      진행 상황: Feature {current}/{total} ({feature_name}) — 축 {axis}, 화면 {n}개 생성 완료
      완료된 Feature: {completed_features}

      이어하기:
        1. /prism account <다른계정> → 세션 재시작
        2. /prism design resume

      또는 다른 시안으로 전환:
        1. /prism preview use <다른시안>
        2. /prism design all (새로 시작)
        나중에 돌아오기: /prism preview use {design_name} → /prism design resume
   ```

**시안별 상태 파일 관리:**

```
.claude/
  prism-design-pipeline.local.md     ← 현재 활성 (Stop hook이 읽는 파일)
  prism-pipelines/                   ← 시안별 상태 백업
    warm-organic.local.md
    editorial-elegance.local.md
```

- `/prism design all` 실행 시: ./DESIGN.md에서 시안 이름 추출 → 해당 시안의 상태 파일 로드 (있으면 resume, 없으면 신규)
- `/prism preview use <name>` 시안 전환 시: 현재 상태 파일을 `.claude/prism-pipelines/{현재시안}.local.md`에 백업 → 새 시안의 상태 파일을 활성화
- 모든 Feature 완료 시: 상태 파일 삭제 (활성 + 백업 모두)

**`/prism design resume` — 중단된 파이프라인 이어하기:**

```
1. .claude/prism-design-pipeline.local.md 존재 확인
   없으면 → "중단된 파이프라인이 없습니다." 안내
2. 상태 파일에서 진행 상황 읽기:
   - design_name: 시안 이름
   - feature: 현재 Feature
   - completed_features: 완료된 Feature 목록
   - completed_screens: 해당 Feature에서 이미 생성된 화면
   - current_axis: 중단된 축
   - project_id: 기존 Stitch 프로젝트 ID (있으면 재사용)
3. 현재 ./DESIGN.md의 시안 이름과 상태 파일의 design_name 일치 확인
   불일치 시 → 경고: "현재 활성 시안({현재})과 중단된 시안({상태})이 다릅니다. /prism preview use {상태} 후 resume하세요."
4. 진행 상황 표시:
   "시안: {design_name}"
   "Feature {current}/{total} ({name}) 이어서 생성합니다."
   "완료된 Feature: {list}"
   "이미 생성된 화면: {n}개"
5. 중단 지점부터 D3 재개:
   - project_id가 있으면 기존 프로젝트에 화면 추가
   - completed_screens에 있는 화면은 건너뛰기
   - 남은 축부터 배치 생성 계속
6. Feature 완료 후 정상 흐름으로 복귀 (D4-D6 → 다음 Feature)
```

### D4: 검증

**실행 주체:** prism 자체 (읽기 전용 MCP 직접 호출)

**Steps:**
1. 각 화면에 대해:
   ```
   get_screen(name: "projects/{projectId}/screens/{screenId}") → downloadUrls
   web_fetch(downloadUrl.screenshot) → /tmp/prism-{screenName}.png
   sips -Z 1200 /tmp/prism-{screenName}.png
   Read /tmp/prism-{screenName}.png → 시각 검증
   ```

2. 검증 체크리스트 (항목별 pass/fail → gaps 카운트):
   - [ ] 코드의 모든 Primary Screen이 Stitch 화면에 1:1 매핑되는가
   - [ ] 모든 버튼/인터랙션 요소가 디자인에 반영되었는가
   - [ ] 상태별 화면(empty, skeleton/loading, error)이 포함되었는가
   - [ ] 오버레이(바텀시트, 다이얼로그, 스낵바)가 누락 없이 있는가
   - [ ] UI 텍스트가 한국어인가 (영어 placeholder 잔존 여부)
   - [ ] 디자인 시스템(색상, 타이포, 간격)이 DESIGN.md와 일관적인가
   - [ ] 레이아웃이 모바일 비율(390×844)에 적합한가

**Transition:** gaps == 0 → D6, gaps > 0 → D5.

### D5: 수정 — 공식 스킬 위임

**Stitch 공식 수정 원칙:**
- **한 번에 1-2가지만 수정** — 여러 변경을 한 프롬프트에 넣지 않음
- **what + how 명시** — 무엇을 어떻게 바꿀지 구체적으로
- **요소를 구체적으로 참조** — "primary button on sign-up form", "image in hero section"
- 수정이 예상과 다르면 **표현을 바꿔서 재시도**

**수정 프롬프트 구조:**
```
On {화면명}, {what을 how로 변경}.
```

**수정 프롬프트 예시:**
```
"On the product list screen, make the grid 3 columns instead of 2."
"On the detail page, add a horizontal scroll of related items at the bottom."
"Change the floating action button color to match the primary accent."
```

```
Skill("stitch-design") 호출
→ 수정 프롬프트 전달 (1-2가지 변경만)
→ 수정 결과 확인 → 예상과 다르면 표현 바꿔서 재시도
```
**Transition:** D4로 복귀.

### D6: 완료

1. `<promise>DESIGN_VERIFIED</promise>` 출력
2. Stop hook이 감지:
   - 다음 Feature → block
   - 모든 Feature 완료 → 상태 파일 삭제 → allow

---

## Feature 루프

`/prism design all`일 때:

```
Feature 1 → ./DESIGN.md에서 designMd 추출 → D3(배치 생성) → D4-D6 → VERIFIED
Feature 2 → ./DESIGN.md에서 designMd 추출 → D3(배치 생성) → D4-D6 → VERIFIED
Feature 3 → ./DESIGN.md에서 designMd 추출 → D3(배치 생성) → D4-D6 → VERIFIED
...
```

**핵심:** 모든 Feature 프로젝트는 A10에서 선택된 동일한 디자인 시스템(./DESIGN.md)을 공유한다.
