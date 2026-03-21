# Loom Plugin v1.0.0 Orchestration Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** loom 플러그인을 포크 관리 모델에서 오케스트레이션 모델로 전환 — 공식 Stitch 스킬(enhance-prompt, stitch-design, design-md)을 호출하고, loom은 코드 분석과 파이프라인 흐름 제어에 집중.

**Architecture:** 공식 스킬 3개를 Skill() 도구로 위임 호출. 생성/수정 MCP 도구는 공식 스킬이 담당하고, 읽기 전용 MCP 도구(get_screen 등)는 loom이 검증 루프에서 직접 사용. Stop hook으로 검증 루프 자동화.

**Tech Stack:** Claude Code Plugin (markdown/JSON/bash), Stitch Remote MCP (HTTP), gcloud OAuth / STITCH_API_KEY

**Spec:** `docs/superpowers/specs/2026-03-21-loom-overhaul-v2-design.md`

---

## File Map

| File | Responsibility |
|------|---------------|
| `skills/loom/SKILL.md` | 스킬 트리거, 인증 체크, 공식 스킬 체크/설치, 오케스트레이션 패턴, 검증 루프 |
| `skills/loom/references/workflows-pipeline.md` | 통합 파이프라인 Phase A1-A6, D1-D6 실행 절차 |
| `skills/loom/references/sheet-template.md` | Analysis Sheet Template (Design Sheet 삭제) |
| `commands/loom.md` | /loom 커맨드 (analyze, design, pipeline) |
| `hooks/scripts/design-verify-stop.sh` | 검증 루프 Stop hook (메시지 수정) |
| `.claude-plugin/plugin.json` | 플러그인 메타데이터 v1.0.0 |
| `.claude-plugin/marketplace.json` | 마켓플레이스 설정 v1.0.0 |

---

## Task 1: 구 reference 파일 삭제

**Files:**
- Delete: `skills/loom/references/tools.md`
- Delete: `skills/loom/references/prompting.md`
- Delete: `skills/loom/references/workflows-analyze.md`
- Delete: `skills/loom/references/workflows-design.md`

- [ ] **Step 1: 4개 파일 삭제**

```bash
rm skills/loom/references/tools.md
rm skills/loom/references/prompting.md
rm skills/loom/references/workflows-analyze.md
rm skills/loom/references/workflows-design.md
```

- [ ] **Step 2: 삭제 확인**

```bash
ls skills/loom/references/
```

Expected: `sheet-template.md`만 남아있음

- [ ] **Step 3: 커밋**

```bash
git add -u skills/loom/references/
git commit -m "chore: 공식 스킬에 위임되는 구 reference 파일 4개 삭제

tools.md, prompting.md, workflows-analyze.md, workflows-design.md 삭제.
공식 스킬(enhance-prompt, stitch-design, design-md)이 담당."
```

---

## Task 2: sheet-template.md에서 Design Sheet Template 삭제

**Files:**
- Modify: `skills/loom/references/sheet-template.md`

- [ ] **Step 1: Design Sheet Template 섹션 삭제**

파일의 1-63번줄 (Design Sheet Template + 구분선 + 빈줄)을 삭제한다. Analysis Sheet Template (64번줄 이후)만 유지.

수정 후 파일은 아래로 시작해야 한다:

```markdown
# Analysis Sheet Template (Code+Simulator→Prompts)

Use this template for `/loom analyze` pipeline. Save to `.loom/{date}-{app}-analysis.md`.
```

- [ ] **Step 2: 삭제 후 파일 확인**

```bash
head -5 skills/loom/references/sheet-template.md
```

Expected: `# Analysis Sheet Template` 또는 `## Analysis Sheet Template`로 시작

> **Note:** 현재 Analysis Sheet Template의 프롬프트 예시는 이미 UX-First Vibe Design 스타일로 작성되어 있으므로 추가 수정 불필요.

- [ ] **Step 3: 커밋**

```bash
git add skills/loom/references/sheet-template.md
git commit -m "refactor: sheet-template에서 Design Sheet Template 삭제, 프롬프트 예시를 Vibe Design으로 수정"
```

---

## Task 3: workflows-pipeline.md 생성

**Files:**
- Create: `skills/loom/references/workflows-pipeline.md`

- [ ] **Step 1: workflows-pipeline.md 작성**

기존 `workflows-analyze.md`(Phase 1-5)와 `workflows-design.md`(Phase 1-7)를 통합하되 공식 스킬 위임에 맞게 재구성. 스펙의 Phase A1-A6, D1-D6 구성을 따른다.

**유지할 내용:**
- `workflows-analyze.md`의 Phase 1-3 전체 (코드 분석, 시뮬레이터, Feature 분리)
- `workflows-analyze.md`의 Phase 4 프롬프트 작성 원칙 (Vibe Design, 금지 사항)
- `workflows-design.md`의 검증 로직 (Phase 5 gaps 카운트)
- `workflows-design.md`의 Feature Routing (all 모드 전용)

**삭제/변경할 내용:**
- `workflows-analyze.md`의 Phase 4에서 `prompting.md` 참조 → 삭제 (enhance-prompt 스킬이 대체)
- `workflows-design.md`의 Phase 4 MCP 직접 호출 → `Skill("stitch-design")` 위임으로 교체
- `workflows-design.md`의 Phase 2-3 (Design Sheet + Prompt Optimization) → 삭제 (analysis.md 필수)
- `workflows-design.md`의 Phase 6 MCP 직접 호출 → `Skill("stitch-design")` 위임으로 교체
- 배치 분할 기준/크레딧 효과 → 삭제 (공식 스킬이 관리)

파일 내용:

```markdown
# Loom Orchestration Pipeline

통합 파이프라인 실행 가이드. Analyze (A1-A6) → Design (D1-D6).

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

### A5: 프롬프트 최적화 — 공식 스킬 위임

**Goal:** 원시 프롬프트를 Stitch에 최적화된 프롬프트로 변환한다.

**실행:**
```
Skill("enhance-prompt") 호출
→ A4에서 작성한 원시 프롬프트를 전달
→ 공식 스킬이 UI/UX 키워드, 분위기, 디자인 시스템 컨텍스트를 추가
→ 최적화된 프롬프트를 반환
```

**Output:** Stitch 최적화된 프롬프트.

### A6: 산출물 작성

**Goal:** 분석 결과를 단일 마크다운 파일로 작성하고 사용자 확인을 받는다.

**Steps:**
1. 파일 경로: `.loom/{date}-{app}-analysis.md`
2. `references/sheet-template.md`의 Analysis Sheet Template에 따라 작성
3. 사용자 확인 요청

**Output:** `.loom/{date}-{app}-analysis.md`

---

## Design Pipeline — `/loom design <feature|all>`

### Feature Routing (all 모드 전용)

> 단일 Feature 모드에서는 건너뛴다.

1. Read `.claude/loom-design-pipeline.local.md` → `feature` 필드 확인
2. analysis.md에서 해당 Feature 프롬프트만 추출
3. 다른 Feature의 프롬프트는 무시

### D1: analysis.md 로드

**Goal:** 분석 산출물에서 Feature 프롬프트를 로드한다.

**Steps:**
1. `.loom/*-analysis.md` 존재 확인
2. 없으면 사용자에게 `/loom analyze` 먼저 실행 안내
3. 있으면 해당 Feature의 프롬프트 로드

### D2: 디자인 시스템 — 공식 스킬 위임

**Goal:** Stitch 프로젝트의 디자인 시스템을 생성한다.

**실행:**
```
Skill("design-md") 호출
→ 프로젝트 컨텍스트와 analysis.md의 분위기/스타일 정보 전달
→ 공식 스킬이 DESIGN.md 생성
```

### D3: 디자인 생성 — 공식 스킬 위임

**Goal:** Feature 프롬프트로 Stitch 디자인을 생성한다.

**실행:**
```
Skill("stitch-design") 호출
→ analysis.md의 Feature 프롬프트 전달
→ 공식 스킬이 create_project, generate_screen_from_text 등 MCP 도구 호출
→ 생성된 프로젝트/화면 정보 반환
```

생성 완료 후 상태 파일의 `phase`를 `verify`로 변경.

### D4: 검증

**Goal:** 생성된 디자인을 analysis.md의 프롬프트와 크로스체크한다.

**실행 주체:** loom 자체 (읽기 전용 MCP 직접 호출)

**Steps:**
1. 각 화면에 대해:
   ```
   get_screen(name: "projects/{projectId}/screens/{screenId}") → downloadUrls
   web_fetch(downloadUrl.screenshot) → /tmp/loom-{screenName}.png
   sips -Z 1200 /tmp/loom-{screenName}.png
   Read /tmp/loom-{screenName}.png → 시각 검증
   ```

2. 체크리스트:
   - [ ] 화면이 존재하고 설명과 매칭
   - [ ] 핵심 UI 컴포넌트 존재
   - [ ] 인터랙션이 시각적으로 표현
   - [ ] 상태 화면 포함

3. gaps 카운트:
   ```
   MISSING_SCREEN: N
   MISSING_INTERACTION: N
   MISSING_STATE: N
   total_gaps: N
   ```

**Transition:** gaps == 0 → D6, gaps > 0 → D5.

### D5: 수정 — 공식 스킬 위임

**Goal:** 검증에서 발견된 gaps를 수정한다.

**실행:**
```
Skill("stitch-design") 호출
→ 수정이 필요한 화면과 수정 프롬프트 전달
→ 공식 스킬이 edit_screens 또는 generate_screen_from_text 호출
```

**Transition:** D4로 복귀.

### D6: 완료

1. `<promise>DESIGN_VERIFIED</promise>` 출력
2. Stop hook이 감지하고:
   - 단일 Feature: 상태 파일 삭제 → allow
   - All + 다음 Feature: 상태 파일 전환 → block → 다음 Feature로
   - All + 마지막: 상태 파일 삭제 → allow
```

- [ ] **Step 2: 커밋**

```bash
git add skills/loom/references/workflows-pipeline.md
git commit -m "feat: workflows-pipeline.md — 통합 오케스트레이션 파이프라인 (A1-A6, D1-D6)"
```

---

## Task 4: SKILL.md 전면 재작성

**Files:**
- Modify: `skills/loom/SKILL.md`

- [ ] **Step 1: SKILL.md를 완전히 재작성**

기존 파일을 전체 교체한다. 아래 내용으로 작성:

```markdown
---
name: loom
description: "Google Stitch AI design tool orchestrator. Code analysis → design pipeline via official Stitch skills. Use when user mentions stitch, 스티치, loom, /loom, 디자인 파이프라인."
---

# Loom Skill

Google Stitch AI design tool을 공식 스킬을 통해 오케스트레이션한다. loom은 코드 분석, 파이프라인 흐름 제어, 검증 루프를 담당하고, 디자인 생성/프롬프트 최적화/디자인 시스템은 공식 Stitch 스킬에 위임한다.

## When to Use

Activate when user:
- Mentions "stitch", "스티치", "stitch.withgoogle.com"
- Asks to create/edit design screens using Stitch
- Wants to generate design variants or manage design systems
- References AI UI design with Stitch
- Asks for UI/UX 디자인, 화면 디자인, 디자인 생성 (in Stitch context)

## Prerequisites

### 1. 공식 Stitch 스킬 체크

파이프라인 실행 전 공식 스킬 3개가 설치되어 있는지 확인:

```bash
# 설치 시도 (없으면 자동 설치)
npx skills add google-labs-code/stitch-skills --skill enhance-prompt --global 2>/dev/null
npx skills add google-labs-code/stitch-skills --skill stitch-design --global 2>/dev/null
npx skills add google-labs-code/stitch-skills --skill design-md --global 2>/dev/null
```

설치 실패 시 사용자에게 안내:
> "공식 Stitch 스킬을 설치해주세요: `npx skills add google-labs-code/stitch-skills --global`"

### 2. Stitch MCP 인증 체크

**1. STITCH_API_KEY 확인:**
```bash
echo "${STITCH_API_KEY:0:10}" 2>/dev/null
```

**2. gcloud ADC 확인 (API Key 없을 때):**
```bash
gcloud auth application-default print-access-token 2>/dev/null | head -c 20
```

**둘 다 실패 시:**
> Stitch 인증이 필요합니다. 아래 중 하나를 설정해주세요:
> - `STITCH_API_KEY` 환경변수 (Stitch 웹 → 프로필 → Exports에서 발급)
> - `gcloud auth login` → `gcloud auth application-default login`

### 3. Stitch MCP 도구 확인

```
ToolSearch query: "+stitch list_projects"
```

## MCP 호출 경계

- **생성/수정 도구** (`generate_screen_from_text`, `edit_screens`, `generate_variants`) → 공식 스킬(`stitch-design`)을 경유
- **읽기 전용 도구** (`get_screen`, `list_screens`, `get_project`, `list_projects`) → loom이 검증 루프에서 직접 호출 가능
- **`web_fetch`** → loom이 스크린샷/HTML 다운로드를 위해 직접 호출 가능

## Analyze Pipeline

`/loom analyze` 요청 시. 파이프라인 레퍼런스를 로드하고 실행한다:

```
Read: references/workflows-pipeline.md
```

Phase A1-A6을 따른다. A5에서 Skill("enhance-prompt")를 호출하여 프롬프트를 최적화.

> **⚠️ 중요**: 프롬프트에 hex 코드, px 값, 특정 폰트명을 포함하지 않는다.

## Design Pipeline

`/loom design` 요청 시. 파이프라인 레퍼런스를 로드하고 실행한다:

```
Read: references/workflows-pipeline.md
Read: references/sheet-template.md
```

Phase D1-D6을 따른다:
- D2: Skill("design-md") → 디자인 시스템 생성
- D3: Skill("stitch-design") → 디자인 생성
- D4: loom이 직접 검증 (읽기 전용 MCP)
- D5: Skill("stitch-design") → 수정

Phase D4-D6 검증 루프는 **Stop hook**이 자동 관리한다.
상태 파일 `.claude/loom-design-pipeline.local.md`에 `phase: verify`가 설정되면
Stop hook이 `<promise>DESIGN_VERIFIED</promise>` 감지까지 루프를 반복한다.

### All 모드: Feature-by-Feature 순차 처리

`/loom design all` 실행 시 모든 Feature를 순차 처리:

1. Feature 1 디자인 생성 → 검증 루프 → `DESIGN_VERIFIED`
2. Stop hook이 다음 Feature로 상태 파일 전환
3. 반복...
4. 마지막 Feature 완료 → 상태 파일 삭제 → allow

### 완료 조건
- [ ] 코드의 모든 화면이 Stitch 디자인에 1:1 매핑
- [ ] 모든 버튼/인터랙션이 디자인에 반영
- [ ] 상태별 화면(로딩, 에러, 엠티)이 포함
- [ ] 검증 루프에서 누락 0건 확인

## Critical Patterns

### Pattern 1: Screen Data Retrieval

Stitch MCP의 `get_screen`은 `downloadUrls`를 반환한다.
HTML 코드와 스크린샷 이미지를 실제로 가져오려면 `web_fetch`가 필요:

```
1. get_screen(name: "projects/{projectId}/screens/{screenId}") → downloadUrls
2. web_fetch(downloadUrls.html) → HTML/CSS code
3. web_fetch(downloadUrls.screenshot) → screenshot image
```

### Pattern 2: Screenshot Discipline

- **MCP 도구 우선**: 가능하면 `get_screen` 데이터로 상태 확인
- **스크린샷**: 시각 검증 마일스톤에서만 사용
- **리사이즈 필수**: `sips -Z 1200 <file>` (컨텍스트 오버플로우 방지)

### Pattern 3: 크레딧 관리 — 일일 크레딧 체계

| 항목 | 한도 | 주기 |
|------|------|------|
| 일일 크레딧 | **400** | 매일 리셋 |
| Redesign Credits | **15** | 매일 리셋 |

**모델 선택 전략:**
| 단계 | 모드 | 용도 |
|------|------|------|
| 기본 (생성/수정 모두) | Thinking with 3 Pro (`GEMINI_3_1_PRO`) | 프로덕션 품질, 깊은 추론 |
| 스타일 실험 | Redesign (Nano Banana Pro) | Vibe Design, 별도 15 크레딧 |

> 일일 400 크레딧이면 PRO 기본 사용에 충분. FLASH는 속도가 필요할 때만 선택적 사용.

**파이프라인 시작 시:**
- 생성할 화면 수를 사용자에게 알림: "총 N개 화면 생성 예정 (일일 한도: 400 크레딧)"
- 사용자 확인 후 진행

### Pattern 4: Stitch 웹 페이지 탐색 (chrome-viewer 사용 시)

Stitch 웹 앱은 cross-origin iframe 구조이다. chrome-viewer 사용 시 반드시 아래 규칙을 따른다.

#### 4a. 반드시 전체 페이지 스크롤 후 판단

페이지에서 특정 섹션을 찾을 때, 뷰포트에 보이는 영역만 보고 "없다"고 판단하면 안 된다.
반드시 페이지 끝까지 스크롤한 후 판단해야 한다.

```
1. cv_scroll(delta_y=99999) → 바닥까지 스크롤
2. cv_screenshot → 하단 확인
3. cv_scroll(delta_y=-99999) → 상단으로 복귀
4. 필요 시 중간 지점도 확인
```

"이 페이지에 X가 없다"고 말하기 전에 최소 3회 스크롤 확인.

#### 4b. Cross-origin iframe은 CDP 직접 접근

Stitch는 실제 콘텐츠가 cross-origin iframe에 렌더링됨:
```
stitch.withgoogle.com (메인 프레임) → 비어있음
  └── app-companion-430619.appspot.com (iframe) → 실제 콘텐츠
```

**cv_click_element, cv_evaluate는 메인 프레임만 접근 → iframe 내부 요소 조작 불가.**

해결: CDP(Chrome DevTools Protocol)로 iframe 탭에 직접 WebSocket 연결:
```python
import urllib.request, json, asyncio, websockets

# 1. iframe 탭 찾기
tabs = json.loads(urllib.request.urlopen('http://localhost:9222/json/list').read())
iframe_tab = next(t for t in tabs if 'app-companion' in t['url'])

# 2. WebSocket으로 직접 연결 후 JS 실행
async with websockets.connect(iframe_tab['webSocketDebuggerUrl']) as ws:
    ws.send(json.dumps({
        'method': 'Runtime.evaluate',
        'params': {'expression': '...'}
    }))
```

**패턴 인식:** URL에 `app-companion`, `appspot.com` 등이 있으면 CDP 직접 접근을 먼저 시도.

## Workflow Reference

| Task | Reference File |
|------|----------------|
| 전체 파이프라인 (analyze + design) | `references/workflows-pipeline.md` |
| 산출물 템플릿 | `references/sheet-template.md` |
```

- [ ] **Step 2: 커밋**

```bash
git add skills/loom/SKILL.md
git commit -m "feat: SKILL.md 전면 재작성 — 공식 스킬 오케스트레이션 모델로 전환"
```

---

## Task 5: commands/loom.md 재작성

**Files:**
- Modify: `commands/loom.md`

- [ ] **Step 1: loom.md를 재작성 — pipeline 서브커맨드 추가, MCP 직접 호출 제거**

```markdown
---
name: loom
description: "Google Stitch AI design tool orchestrator — analyze, design, pipeline"
---

# /loom Command

Google Stitch AI design tool orchestration command.

## Usage

| Subcommand | Usage | Action |
|------------|-------|--------|
| `analyze` | `/loom analyze [app]` | 코드+시뮬레이터 분석 → Feature별 프롬프트 → analysis.md 산출 |
| `design` | `/loom design <feature\|all>` | 공식 스킬로 디자인 생성 + 검증 루프 |
| `pipeline` | `/loom pipeline [app]` | analyze → design 전체 자동화 (원스텝) |

## `/loom analyze [app]`

코드와 실행 화면을 분석하여 Feature별 UX-First 프롬프트를 산출한다.

### 실행 절차

1. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-pipeline.md
   ```

2. **Phase A1-A6 실행**:
   - A1-A4: loom 자체 (코드 분석, 시뮬레이터, Feature 분리, 원시 프롬프트)
   - A5: Skill("enhance-prompt") 호출 → 프롬프트 최적화
   - A6: `.loom/{date}-{app}-analysis.md` 작성

3. **사용자 확인 요청**

`app` 인자 예시: `/loom analyze readcodex`, `/loom analyze bookflip`
인자 없으면 현재 프로젝트 이름 사용.

## `/loom design <feature|all>`

공식 Stitch 스킬을 호출하여 디자인을 생성하고 검증한다.

### 실행 절차

1. **상태 파일 초기화**: `.claude/loom-design-pipeline.local.md` 생성
   ```yaml
   ---
   phase: generation
   feature: {feature}
   session_id: {현재 세션 ID}
   iteration: 0
   max_iterations: 5
   all_features: {all일 때: feature1|feature2|...}
   current_index: {all일 때: 0}
   completed_features: {all일 때: 빈 값}
   ---
   ```

2. **analysis.md 확인**: `.loom/*-analysis.md` 존재 필수. 없으면 `/loom analyze` 먼저 실행 안내.

3. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-pipeline.md
   Read: references/sheet-template.md
   ```

4. **Phase D1-D6 실행**:
   - D1: analysis.md 로드 (loom)
   - D2: Skill("design-md") → 디자인 시스템
   - D3: Skill("stitch-design") → 디자인 생성
   - D4-D6: 검증 루프 (Stop hook 자동)

`feature` 인자 예시: `/loom design library`, `/loom design all`
인자 없으면 analysis.md의 Feature 목록 표시 후 선택 요청.

## `/loom pipeline [app]`

analyze → design을 원스텝으로 자동 실행한다.

### 실행 절차

1. `/loom analyze [app]` 실행
2. 분석 요약 표시 후 자동 진행 (간략 요약만 출력, 명시적 거부 없으면 진행)
3. `/loom design all` 실행
4. 전체 Feature 순차 처리

## Execution

1. Activate the `loom` skill
2. Execute the requested subcommand following the skill's workflow references

## No Arguments

If called without arguments (`/loom`), show the usage table above and ask what the user wants to do.

## Error Handling

- **공식 스킬 미설치**: 자동 설치 시도 → 실패 시 안내
- **인증 실패**: STITCH_API_KEY → gcloud ADC → 안내
- **Rate limit**: 파이프라인 시작 시 크레딧 안내
- **analysis.md 미존재**: `/loom analyze` 먼저 실행 안내
```

- [ ] **Step 2: 커밋**

```bash
git add commands/loom.md
git commit -m "feat: /loom 커맨드 재작성 — pipeline 서브커맨드 추가, 공식 스킬 위임"
```

---

## Task 6: design-verify-stop.sh 메시지 수정

**Files:**
- Modify: `hooks/scripts/design-verify-stop.sh`

- [ ] **Step 1: Feature 전환 메시지 수정 (98번줄)**

기존:
```
"reason": "Feature '${CURRENT_FEATURE}' 디자인 검증 완료! (${NEXT_INDEX}/${TOTAL})\\n\\n다음 Feature: '${NEXT_FEATURE}'\\n\\n1. Read .claude/loom-design-pipeline.local.md → 현재 feature 확인\\n2. analysis.md에서 '${NEXT_FEATURE}' Feature 프롬프트 로드\\n3. Stitch MCP로 '${NEXT_FEATURE}' 디자인 생성 (Phase 4)\\n4. 생성 완료 후 phase를 verify로 변경하고 검증 시작\\n\\nreferences/workflows-design.md Phase 4 절차를 따르세요."
```

수정:
```
"reason": "Feature '${CURRENT_FEATURE}' 디자인 검증 완료! (${NEXT_INDEX}/${TOTAL})\\n\\n다음 Feature: '${NEXT_FEATURE}'\\n\\n1. Read .claude/loom-design-pipeline.local.md → 현재 feature 확인\\n2. analysis.md에서 '${NEXT_FEATURE}' Feature 프롬프트 로드\\n3. Skill(stitch-design)으로 '${NEXT_FEATURE}' 디자인 생성 (Phase D3)\\n4. 생성 완료 후 phase를 verify로 변경하고 검증 시작\\n\\nreferences/workflows-pipeline.md Phase D3 절차를 따르세요."
```

- [ ] **Step 2: 재시도 메시지 수정 (122-126번줄)**

기존:
```
"reason": "디자인 검증 루프를 계속합니다.\n\n1. Read .claude/loom-design-pipeline.local.md → 남은 gaps 확인\n2. gaps > 0: Stitch MCP edit_screens로 누락분 수정 또는 generate_screen_from_text로 재생성 → Phase 5 재검증\n3. gaps == 0: <promise>DESIGN_VERIFIED</promise> 출력\n\nreferences/workflows-design.md Phase 5 절차를 따르세요."
```

수정:
```
"reason": "디자인 검증 루프를 계속합니다.\n\n1. Read .claude/loom-design-pipeline.local.md → 남은 gaps 확인\n2. gaps > 0: Skill(stitch-design)으로 누락분 수정 또는 재생성 → Phase D4 재검증\n3. gaps == 0: <promise>DESIGN_VERIFIED</promise> 출력\n\nreferences/workflows-pipeline.md Phase D4 절차를 따르세요."
```

- [ ] **Step 3: 커밋**

```bash
git add hooks/scripts/design-verify-stop.sh
git commit -m "fix: Stop hook 메시지를 공식 스킬 위임 방식으로 업데이트"
```

---

## Task 7: 플러그인 매니페스트 버전 범프

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: plugin.json 수정**

```json
{
  "name": "loom",
  "version": "1.0.0",
  "description": "Google Stitch AI design tool orchestrator for Claude Code — code analysis, design pipeline via official Stitch skills",
  "author": {
    "name": "Taekwan Kim"
  },
  "keywords": ["loom", "stitch", "design", "orchestrator", "automation", "google"]
}
```

- [ ] **Step 2: marketplace.json 수정**

```json
{
  "name": "loom",
  "owner": {
    "name": "Taekwan Kim"
  },
  "metadata": {
    "description": "Google Stitch AI design tool orchestrator — code→design pipeline via official skills",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "loom",
      "source": "./",
      "description": "Google Stitch AI design tool orchestrator — analyze, design pipeline, verification loops",
      "version": "1.0.0",
      "author": {
        "name": "Taekwan Kim"
      },
      "keywords": ["loom", "stitch", "design", "orchestrator", "automation"]
    }
  ]
}
```

- [ ] **Step 3: 커밋**

```bash
git add .claude-plugin/
git commit -m "chore: bump plugin version to 1.0.0 — orchestration overhaul"
```
