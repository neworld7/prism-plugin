# Multi-Direction Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/loom design --directions N` 옵션으로 N개 디자인 방향(Direction)을 별도 Stitch 프로젝트로 생성하고 각각 검증 루프까지 완주하는 기능 추가.

**Architecture:** 단일/멀티 모두 `directions/` 구조 사용. 3축(아키타입, 레이아웃, 레퍼런스) 기반 Direction 생성. enhance-prompt에 Direction Context를 프롬프트 텍스트로 삽입하여 N번 호출. Stop hook에 Direction 내부 루프 추가.

**Tech Stack:** Claude Code Plugin (markdown/JSON/bash), Stitch Remote MCP (HTTP), 공식 Stitch 스킬 3개

**Spec:** `docs/superpowers/specs/2026-03-21-multi-direction-design.md`

---

## File Map

| File | Responsibility |
|------|---------------|
| `skills/loom/references/workflows.md` | `workflows-pipeline.md`에서 리네이밍 + A4.5/A5×N/D3×N/D4-D6×N Phase 추가 + analysis.md/prompts.md 산출물 구조 통합 |
| `skills/loom/SKILL.md` | --directions 옵션, Direction 생성 패턴, directions/ 구조, DESIGN.md 스와핑 |
| `commands/loom.md` | --directions N 옵션, 멀티 모드 실행 절차 |
| `hooks/scripts/design-verify-stop.sh` | Direction 순차 전환 로직 (Feature 외부 × Direction 내부 이중 루프) |
| `.claude-plugin/plugin.json` | version 1.1.0 |
| `.claude-plugin/marketplace.json` | version 1.1.0 |

---

## Task 1: sheet-template.md 삭제 + workflows-pipeline.md → workflows.md 리네이밍

**Files:**
- Delete: `skills/loom/references/sheet-template.md`
- Rename: `skills/loom/references/workflows-pipeline.md` → `skills/loom/references/workflows.md`

- [ ] **Step 1: sheet-template.md 삭제**

```bash
rm skills/loom/references/sheet-template.md
```

- [ ] **Step 2: workflows-pipeline.md → workflows.md 리네이밍**

```bash
mv skills/loom/references/workflows-pipeline.md skills/loom/references/workflows.md
```

- [ ] **Step 3: 확인**

```bash
ls skills/loom/references/
```

Expected: `workflows.md`만 존재

- [ ] **Step 4: 커밋**

```bash
git add -u skills/loom/references/
git add skills/loom/references/workflows.md
git commit -m "refactor: sheet-template.md 삭제, workflows-pipeline.md → workflows.md 리네이밍

산출물 구조를 workflows.md에 통합. 파일명을 /loom pipeline 커맨드와 혼동 방지."
```

---

## Task 2: workflows.md에 멀티 Direction Phase 및 산출물 구조 추가

**Files:**
- Modify: `skills/loom/references/workflows.md`

- [ ] **Step 1: workflows.md를 전체 재작성**

기존 내용에서 변경점:
- A5를 "단일 모드"와 "멀티 모드(A4.5 + A5×N)"로 분기
- A6에 `directions/` 구조 기반 산출물 구조 (analysis.md + prompts.md) 통합
- D1에 Direction별 prompts.md 로드 추가
- D2에 DESIGN.md 스와핑 로직 추가
- D3-D6에 Direction 순차 처리 설명 추가
- sheet-template.md의 analysis.md 템플릿을 A6에 통합

Read the current file first, then Write the complete new content:

```markdown
# Loom Workflows

통합 워크플로우 실행 가이드. Analyze (A1-A6) → Design (D1-D6).

## Analyze Pipeline — `/loom analyze [app]`

### A1: 코드 분석

**Goal:** 프로젝트 소스 코드에서 모든 화면, 인터랙션, 상태를 추출한다.

**Steps:**

1. 프로젝트 스택 판별:
   - Flutter: `Glob: lib/**/*.dart`
   - React: `Glob: src/**/*.{tsx,jsx}`
   - Next.js: `Glob: app/**/*.{tsx,jsx}`

2. 화면/페이지 추출:
   - Flutter: `Grep: class.*Screen|class.*Page|class.*View` in `lib/`
   - React/Next: `Grep: export default|export function` in page files

3. 라우트/네비게이션 구조:
   - Flutter: `Grep: GoRoute|MaterialPageRoute|Navigator.push`
   - React/Next: 파일 기반 라우팅 or `Grep: useRouter|Link`

4. 인터랙션 추출:
   - `Grep: onTap|onPressed|onClick|onSubmit|GestureDetector`

5. 상태 추출:
   - `Grep: Loading|Error|Empty|CircularProgressIndicator|Shimmer|skeleton`

**Output:** 화면 목록, 인터랙션 목록, 상태 목록.

### A2: 시뮬레이터 스크린샷 캡처 및 분석

**Goal:** 실제 실행 화면을 캡처하고 시각적으로 분석하여 현재 디자인 상태를 파악한다.

**Steps:**

1. 앱 실행 확인:
   - Flutter: iOS 시뮬레이터 또는 Android 에뮬레이터 실행 여부 확인
   - React/Next.js: dev 서버 실행 여부 확인 (`localhost:{port}`)
   - 미실행 시 사용자에게 앱 실행 요청

2. **[필수] idb를 이용한 화면 조작 + 스크린샷 캡처:**

   코드 분석에서 발견된 화면/라우트를 **idb(iOS Development Bridge)로 직접 조작**하여 각 화면에 도달한 후 스크린샷을 캡처한다.

   - Flutter (iOS 시뮬레이터 — idb 사용):
     ```bash
     idb --help 2>/dev/null || pip install fb-idb
     idb list-targets
     idb ui tap {x} {y}
     idb ui swipe {x1} {y1} {x2} {y2}
     idb ui text "검색어"
     idb screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```

   - Flutter (idb 없을 시 폴백):
     ```bash
     xcrun simctl io booted screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```

   - React/Next.js:
     - chrome-viewer: `cv_navigate` → `cv_click` → `cv_screenshot`
     - Playwright: `browser_navigate` → `browser_click` → `browser_take_screenshot`

   **필수 절차:**
   1. A1에서 발견된 **모든 화면 목록**을 순회
   2. 각 화면에 idb 조작으로 도달
   3. 도달 후 스크린샷 캡처
   4. 스크롤이 필요한 화면은 상단/하단 모두 캡처
   5. 상태별 화면(로딩, 에러, 빈 상태)도 가능하면 트리거하여 캡처

3. 각 스크린샷 Read → 시각 분석:
   - 레이아웃 구조, 컴포넌트 유형, 색상 팔레트, 타이포그래피
   - 현재 디자인 품질/문제점
   - idb 조작 중 발견한 인터랙션 특성

**Output:** 화면별 스크린샷 + 시각 분석 메모.

### A3: Feature 분리

**Goal:** 코드 분석 + 스크린샷 분석 결과를 종합하여 Feature 단위로 화면을 분류한다.

**Steps:**

1. 화면을 기능 단위(Feature)로 그룹화
2. 각 Feature에 매핑: 포함 화면 목록, 인터랙션, 상태

**Output:** Feature 목록 + 화면/인터랙션/상태 매핑 구조.

### A4: Feature별 원시 프롬프트 작성

**Goal:** 각 화면에 대해 UX 중심 프롬프트 초안을 작성한다.

**철학:** Vibe Design — AI에 자유도를 주되 방향성은 명확히. 구현 디테일은 AI가 결정.

**프롬프트 요소:**
- 화면 목적 (1줄)
- 무드/바이브 (2-3 형용사)
- 핵심 섹션 (번호 매긴 고수준 레이아웃)
- UI 컴포넌트 (이름만)
- 사용자 흐름
- 앱 컨텍스트, 플랫폼, 레퍼런스, 제외 사항

**금지 사항:**
- ❌ hex 코드, px 값, 특정 폰트명
- ❌ border-radius, shadow, opacity 수치

**품질 기준:**
- 화면당 150-400자
- 프롬프트 지시문은 영어
- 마지막에 반드시: `All UI text, labels, buttons, placeholders, and content must be in Korean (한국어).`

**Output:** Feature별 원시 UX-First 프롬프트.

### A4.5: Direction 생성 (멀티 모드 전용)

> `--directions 1`이면 이 단계를 건너뛴다. Direction은 `default`로 자동 설정.

**Goal:** `--directions N` (N >= 2)일 때, 3축 기반으로 N개 디자인 방향을 추천하고 사용자 확인을 받는다.

**3축 프레임워크:**

| 축 | 역할 | 예시 값 |
|---|---|---|
| **아키타입** | 전체 디자인 언어 결정 | Editorial Elegance, Flat Modern, Glassmorphism, Dark Minimalism, Playful Pastel, Japanese Zen, Warm Organic |
| **레이아웃** | 화면 구조/배치 패턴 | Centered Stack, Split Screen, Bottom Sheet, Full-bleed Hero, Card-based, Centered Narrow |
| **레퍼런스 앱** | AI가 참조할 구체적 디자인 DNA | Notion, Linear, Stripe, Duolingo, Airbnb, 밀리의서재, Spotify |

**출력 형식:**

```
📐 Direction A: "{Direction 이름}"
  아키타입: {아키타입} — {핵심 특성 1줄}
  레이아웃: {레이아웃} — {구조 설명 1줄}
  레퍼런스: {레퍼런스 앱} — {해당 앱의 어떤 측면을 참조하는지}

  {이 방향이 앱에 적합한 이유 2-3줄.}
```

**사용자 응답 처리:**
- "네" → N개 Direction 확정, A5로 진행
- "B를 X로 바꿔주세요" → 교체 후 재표시
- "하나 더 추가" → 추가 (최대 5개)
- "A, C만" → 선택된 Direction만 진행

### A5: 프롬프트 최적화 — 공식 스킬 위임

**Goal:** 원시 프롬프트를 Stitch에 최적화된 프롬프트로 변환한다.

**단일 모드 (--directions 1):**
```
Skill("enhance-prompt") 호출 1회
→ A4에서 작성한 원시 프롬프트를 전달
→ 결과를 .loom/directions/default/prompts.md에 저장
```

**멀티 모드 (--directions N):**
```
각 Direction에 대해 Skill("enhance-prompt") 호출:
→ 원시 프롬프트 + Direction Context 블록 삽입
→ 결과를 .loom/directions/{direction-name}/prompts.md에 저장
```

**Direction Context 삽입 예시:**
```
원시 프롬프트 앞에 삽입:

**Direction: Cozy Reading Nook**
- Archetype: Warm Organic — natural textures, paper-like, serif typography
- Layout: Centered Generous — ample margins, vertical stack
- Reference: Inspired by 밀리의서재's warm, trustworthy onboarding
```

### A6: 산출물 저장

**Goal:** 분석 결과를 저장하고 사용자 확인을 받는다.

**파일 구조 (단일/멀티 동일):**

```
.loom/
  analysis.md                    ← 공통 (A1-A4 산출물)
  directions/
    default/                     ← 단일 모드
      prompts.md                 ← A5 결과
    {direction-name}/            ← 멀티 모드
      prompts.md                 ← A5 결과
```

**analysis.md 템플릿:**

```markdown
# {App} Analysis

| 항목 | 값 |
|------|------|
| App | {app name} |
| Date | {YYYY-MM-DD} |
| Stack | Flutter / React / Next.js |
| Device | Mobile / Desktop / Tablet |
| Total Features | N |
| Total Screens | N |

## 앱 컨텍스트

> {앱의 목적, 타겟 사용자, 전반적 분위기를 2-3줄로 요약}

## Feature 요약

| # | Feature | 화면 수 | 핵심 화면 |
|---|---------|---------|-----------|
| 1 | 인증 | 3 | 로그인, 회원가입, 비밀번호 재설정 |

## Feature 1: {feature name}

### 화면 목록

| # | 화면 | 코드 파일 | 현재 상태 |
|---|------|-----------|-----------|
| 1 | 로그인 | lib/.../login_screen.dart | 기본 폼 |

### 사용자 흐름

이메일/비밀번호 입력 → 로그인 → 홈으로 이동

### 원시 프롬프트

#### 🎯 로그인

```
A warm, welcoming login screen for '{App Name}' {app category} app.
Centered app branding with tagline.
...
All UI text must be in Korean (한국어).
```
```

**prompts.md 템플릿 (Direction별):**

```markdown
# Direction: {Direction 이름}

아키타입: {아키타입} / 레이아웃: {레이아웃} / 레퍼런스: {레퍼런스}

## Feature 1: {feature name}

### 🎯 로그인
📋 **Stitch 프롬프트**
(enhance-prompt 결과)

### 🎯 회원가입
📋 **Stitch 프롬프트**
(enhance-prompt 결과)
```

---

## Design Pipeline — `/loom design <feature|all>`

### Direction Routing

1. `.loom/directions/` 에서 현재 Direction 디렉토리 확인
2. 해당 Direction의 `prompts.md`에서 Feature 프롬프트 로드
3. 해당 Direction의 `DESIGN.md`를 `./DESIGN.md`로 복원 (첫 Feature 이후)

### Feature Routing (all 모드 전용)

> 단일 Feature 모드에서는 건너뛴다.

1. Read `.claude/loom-design-pipeline.local.md` → `feature` 필드 확인
2. 현재 Direction의 prompts.md에서 해당 Feature 프롬프트만 추출

### D1: prompts.md 로드

**Goal:** 현재 Direction의 프롬프트를 로드한다.

**Steps:**
1. `.loom/directions/{direction}/prompts.md` 존재 확인
2. 없으면 `/loom analyze` 먼저 실행 안내
3. 있으면 해당 Feature의 프롬프트 로드

### D2: 디자인 시스템 — 공식 스킬 위임 + DESIGN.md 스와핑

**Goal:** Stitch 프로젝트의 디자인 시스템을 생성한다.

**첫 Feature에서:**
```
Skill("design-md") 호출 → ./DESIGN.md 생성
원본 보존: cp ./DESIGN.md .loom/directions/{direction}/DESIGN.md
```

**이후 Feature에서 (같은 Direction):**
```
.loom/directions/{direction}/DESIGN.md를 ./DESIGN.md로 복원
D2 재호출 불필요
```

**Direction 전환 시:**
```
새 Direction의 첫 Feature → D2 재호출 → DESIGN.md 새로 생성 → 보존
```

### D3: 디자인 생성 — 공식 스킬 위임

**Goal:** Feature 프롬프트로 Stitch 디자인을 생성한다.

**실행:**
```
Skill("stitch-design") 호출
→ 현재 Direction의 prompts.md에서 Feature 프롬프트 전달
→ 프로젝트 이름: "{App} — {Direction 이름}"
→ 생성된 프로젝트 ID를 .loom/directions/{direction}/project-id에 기록
```

### D4: 검증

**실행 주체:** loom 자체 (읽기 전용 MCP 직접 호출)

**Steps:**
1. 각 화면에 대해:
   ```
   get_screen(name: "projects/{projectId}/screens/{screenId}") → downloadUrls
   web_fetch(downloadUrl.screenshot) → /tmp/loom-{screenName}.png
   sips -Z 1200 /tmp/loom-{screenName}.png
   Read /tmp/loom-{screenName}.png → 시각 검증
   ```

2. 체크리스트 + gaps 카운트

**Transition:** gaps == 0 → D6, gaps > 0 → D5.

### D5: 수정 — 공식 스킬 위임

```
Skill("stitch-design") 호출
→ 수정 프롬프트 전달
```
**Transition:** D4로 복귀.

### D6: 완료

1. `<promise>DESIGN_VERIFIED</promise>` 출력
2. Stop hook이 감지:
   - Direction 내부 루프: 다음 Direction → block
   - Feature 외부 루프: 다음 Feature → block
   - 모두 완료 → 상태 파일 삭제 → allow

---

## 이중 루프: Feature(외부) × Direction(내부)

`/loom design all --directions 3`일 때:

```
Feature 1:
  Direction A → D2(design-md) → DESIGN.md 보존 → D3 → D4-D6 → VERIFIED
  Direction B → D2(design-md) → DESIGN.md 보존 → D3 → D4-D6 → VERIFIED
  Direction C → D2(design-md) → DESIGN.md 보존 → D3 → D4-D6 → VERIFIED
Feature 2:
  Direction A → DESIGN.md 복원 → D3 → D4-D6 → VERIFIED
  Direction B → DESIGN.md 복원 → D3 → D4-D6 → VERIFIED
  Direction C → DESIGN.md 복원 → D3 → D4-D6 → VERIFIED
...
```
```

- [ ] **Step 2: 커밋**

```bash
git add skills/loom/references/workflows.md
git commit -m "feat: workflows.md — 멀티 Direction Phase(A4.5, A5×N, D3×N) + 산출물 구조 통합"
```

---

## Task 3: SKILL.md 업데이트 — --directions, directions/ 구조, DESIGN.md 스와핑

**Files:**
- Modify: `skills/loom/SKILL.md`

- [ ] **Step 1: SKILL.md를 전체 재작성**

Read the current file first, then Write with these changes:
- `references/workflows-pipeline.md` → `references/workflows.md`
- `references/sheet-template.md` 참조 제거
- `--directions N` 옵션 설명 추가
- Direction 생성 (3축 프레임워크) 섹션 추가
- `.loom/directions/` 구조 설명 추가
- DESIGN.md 스와핑 패턴 추가
- Analyze/Design Pipeline에 Direction 분기 설명 추가

핵심 추가 내용:

```markdown
## --directions 옵션

`/loom design`과 `/loom pipeline`에서 사용 가능:

| 사용법 | 동작 |
|--------|------|
| `/loom design library` | 단일 Direction (default), 기존 동작 |
| `/loom design library --directions 3` | 3개 Direction으로 멀티 생성 |
| `/loom pipeline app --directions 3` | 분석 → 3방향 → 모두 검증 |

범위: 1-5, 기본값: 1.

## Direction 생성 (3축 프레임워크)

`--directions N` (N >= 2)일 때, A4 완료 후 자동 활성화:

| 축 | 역할 | 예시 값 |
|---|---|---|
| 아키타입 | 전체 디자인 언어 | Editorial Elegance, Dark Minimalism, Playful Pastel... |
| 레이아웃 | 화면 구조 | Split Screen, Bottom Sheet, Centered Card... |
| 레퍼런스 앱 | 참조 디자인 DNA | Notion, Linear, Duolingo, 밀리의서재... |

각 Direction에 추천 이유, 타겟 사용자, 감성을 상세 설명하여 선택을 돕는다.
사용자가 수정/교체/추가 가능 (최대 5개).

## 파일 구조 — .loom/directions/

단일/멀티 모두 동일한 `directions/` 구조:

```
.loom/
  analysis.md                    ← 공통 (A1-A4)
  directions/
    default/                     ← --directions 1
      prompts.md, DESIGN.md, project-id
    {direction-name}/            ← --directions N
      prompts.md, DESIGN.md, project-id
./DESIGN.md                      ← 활성 Direction 복제본
```

Direction 정리: `rm -rf .loom/directions/{name}/`

## DESIGN.md 스와핑

`./DESIGN.md`는 프로젝트 루트 (공식 design-md 스킬 요구사항).
Direction 전환 시:
1. D2: Skill("design-md") → ./DESIGN.md 생성
2. 보존: cp ./DESIGN.md .loom/directions/{name}/DESIGN.md
3. 이후 Feature: .loom/directions/{name}/DESIGN.md → ./DESIGN.md 복원
```

Workflow Reference 테이블을 다음으로 변경:

```markdown
## Workflow Reference

| Task | Reference File |
|------|----------------|
| 전체 워크플로우 (analyze + design) | `references/workflows.md` |
```

- [ ] **Step 2: 커밋**

```bash
git add skills/loom/SKILL.md
git commit -m "feat: SKILL.md — --directions 옵션, directions/ 구조, DESIGN.md 스와핑 추가"
```

---

## Task 4: commands/loom.md 업데이트 — --directions 옵션

**Files:**
- Modify: `commands/loom.md`

- [ ] **Step 1: loom.md를 전체 재작성**

Read the current file first, then Write with these changes:
- Usage 테이블에 `--directions` 열 추가
- `/loom analyze`의 A6 산출물 경로를 `.loom/analysis.md` + `.loom/directions/` 구조로 변경
- `/loom design`의 `--directions N` 옵션 설명 추가
- `/loom pipeline`의 `--directions N` 전달 설명 추가
- `references/workflows-pipeline.md` → `references/workflows.md`
- `references/sheet-template.md` 참조 제거
- analysis.md 경로 `.loom/*-analysis.md` → `.loom/analysis.md`
- 상태 파일에 Direction 필드 추가

핵심 변경: Usage 테이블

```markdown
| Subcommand | Usage | Action |
|------------|-------|--------|
| `analyze` | `/loom analyze [app]` | 코드+시뮬레이터 분석 → Feature별 프롬프트 → .loom/analysis.md + directions/ 산출 |
| `design` | `/loom design <feature\|all> [--directions N]` | 공식 스킬로 디자인 생성 + 검증 루프. N개 Direction (기본 1) |
| `pipeline` | `/loom pipeline [app] [--directions N]` | analyze → design 전체 자동화 (원스텝) |
```

상태 파일 확장 (design 실행 절차 내):

```yaml
---
phase: generation
feature: {feature}
direction: "default"
direction_index: 0
total_directions: 1
all_directions: "default"
completed_directions: ""
session_id: {현재 세션 ID}
iteration: 0
max_iterations: 5
all_features: {all일 때: feature1|feature2|...}
current_index: {all일 때: 0}
completed_features: {all일 때: 빈 값}
---
```

- [ ] **Step 2: 커밋**

```bash
git add commands/loom.md
git commit -m "feat: /loom 커맨드 — --directions N 옵션, directions/ 구조 반영"
```

---

## Task 5: design-verify-stop.sh — Direction 내부 루프 추가

**Files:**
- Modify: `hooks/scripts/design-verify-stop.sh`

- [ ] **Step 1: Direction 전환 로직 추가**

Read the current file first. `DESIGN_VERIFIED` 감지 블록 (53번줄~) 내에서, 기존 Feature 전환 로직 **앞에** Direction 전환 로직을 삽입한다.

**로직 순서 (Feature 외부 × Direction 내부):**

```
DESIGN_VERIFIED 감지:
  1. TOTAL_DIRECTIONS 확인
  2. TOTAL_DIRECTIONS > 1 이면:
     a. DIRECTION_INDEX < TOTAL_DIRECTIONS - 1 → 다음 Direction으로 전환
     b. 마지막 Direction → DIRECTION_INDEX 리셋 → Feature 전환 로직으로 이동
  3. TOTAL_DIRECTIONS 없거나 1이면 → 기존 Feature 전환 로직
```

구체적 변경:

기존 53번줄의 `if echo "$INPUT" | grep -q "<promise>${COMPLETION_PROMISE}</promise>"` 블록 내부에서, `ALL_FEATURES` 체크 **앞에** 다음 코드를 삽입:

```bash
  # --- Direction loop (inner) ---
  TOTAL_DIRECTIONS=$(get_field "total_directions")
  if [ -n "$TOTAL_DIRECTIONS" ] && [ "$TOTAL_DIRECTIONS" -gt 1 ]; then
    DIRECTION_INDEX=$(get_field "direction_index")
    DIRECTION_INDEX="${DIRECTION_INDEX:-0}"
    CURRENT_DIRECTION=$(get_field "direction")
    ALL_DIRECTIONS=$(get_field "all_directions")
    COMPLETED_DIRS=$(get_field "completed_directions")

    if [ -z "$COMPLETED_DIRS" ]; then
      NEW_COMPLETED_DIRS="$CURRENT_DIRECTION"
    else
      NEW_COMPLETED_DIRS="${COMPLETED_DIRS}|${CURRENT_DIRECTION}"
    fi

    NEXT_DIR_INDEX=$((DIRECTION_INDEX + 1))

    if [ "$NEXT_DIR_INDEX" -lt "$TOTAL_DIRECTIONS" ]; then
      # Next direction exists — advance direction
      NEXT_DIRECTION=$(echo "$ALL_DIRECTIONS" | cut -d'|' -f$((NEXT_DIR_INDEX + 1)))

      sed -i '' "s/^phase:.*/phase: generation/" "$STATE_FILE"
      sed -i '' "s/^direction:.*/direction: ${NEXT_DIRECTION}/" "$STATE_FILE"
      sed -i '' "s/^direction_index:.*/direction_index: ${NEXT_DIR_INDEX}/" "$STATE_FILE"
      sed -i '' "s/^iteration:.*/iteration: 0/" "$STATE_FILE"
      if grep -q "^completed_directions:" "$STATE_FILE"; then
        sed -i '' "s/^completed_directions:.*/completed_directions: ${NEW_COMPLETED_DIRS}/" "$STATE_FILE"
      else
        sed -i '' "/^---$/a\\
completed_directions: ${NEW_COMPLETED_DIRS}" "$STATE_FILE"
      fi

      cat <<HOOK_OUTPUT
{
  "decision": "block",
  "reason": "Direction '${CURRENT_DIRECTION}' 검증 완료! (${NEXT_DIR_INDEX}/${TOTAL_DIRECTIONS})\\n\\n다음 Direction: '${NEXT_DIRECTION}'\\n\\n1. Read .claude/loom-design-pipeline.local.md → 현재 direction 확인\\n2. .loom/directions/${NEXT_DIRECTION}/DESIGN.md → ./DESIGN.md 복원 또는 D2 실행\\n3. .loom/directions/${NEXT_DIRECTION}/prompts.md 로드\\n4. Skill(stitch-design)으로 디자인 생성\\n5. 생성 완료 후 phase를 verify로 변경\\n\\nreferences/workflows.md Design Pipeline 절차를 따르세요."
}
HOOK_OUTPUT
      exit 0
    fi

    # Last direction — update completed_directions, reset direction_index
    sed -i '' "s/^direction_index:.*/direction_index: 0/" "$STATE_FILE"
    if grep -q "^completed_directions:" "$STATE_FILE"; then
      sed -i '' "s/^completed_directions:.*/completed_directions: ${NEW_COMPLETED_DIRS}/" "$STATE_FILE"
    else
      sed -i '' "/^---$/a\\
completed_directions: ${NEW_COMPLETED_DIRS}" "$STATE_FILE"
    fi
    # Reset direction to first for next feature
    FIRST_DIRECTION=$(echo "$ALL_DIRECTIONS" | cut -d'|' -f1)
    sed -i '' "s/^direction:.*/direction: ${FIRST_DIRECTION}/" "$STATE_FILE"

    # Fall through to feature transition logic below
  fi
```

또한, Feature 전환 블록 메시지(98번줄)에서 `references/workflows-pipeline.md` → `references/workflows.md`로 변경.

재시도 메시지(124번줄)에서도 `references/workflows-pipeline.md` → `references/workflows.md`로 변경.

- [ ] **Step 2: 커밋**

```bash
git add hooks/scripts/design-verify-stop.sh
git commit -m "feat: Stop hook — Direction 내부 루프 추가 (Feature×Direction 이중 루프)"
```

---

## Task 6: 플러그인 매니페스트 v1.1.0 범프

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: plugin.json 수정**

Read first, then update `version` to `"1.1.0"`.

- [ ] **Step 2: marketplace.json 수정**

Read first, then update both `metadata.version` and `plugins[0].version` to `"1.1.0"`.

- [ ] **Step 3: 커밋**

```bash
git add .claude-plugin/
git commit -m "chore: bump plugin version to 1.1.0 — multi-direction design"
```
