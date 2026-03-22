---
name: prism
description: "Google Stitch AI design tool orchestrator. Code analysis → design pipeline via official Stitch skills. Use when user mentions stitch, 스티치, prism, /prism, 디자인 파이프라인."
---

# Prism Skill

Google Stitch AI design tool을 공식 스킬을 통해 오케스트레이션한다. prism은 코드 분석, 파이프라인 흐름 제어, 검증 루프를 담당하고, 디자인 생성/프롬프트 최적화는 공식 Stitch 스킬에 위임한다. 디자인 시스템은 Stitch가 자체 생성하며 Design Identity로 관리한다.

## When to Use

Activate when user:
- Mentions "stitch", "스티치", "stitch.withgoogle.com"
- Asks to create/edit design screens using Stitch
- Wants to generate design variants or manage design systems
- References AI UI design with Stitch
- Asks for UI/UX 디자인, 화면 디자인, 디자인 생성 (in Stitch context)

## Prerequisites

### 1. 공식 Stitch 스킬 체크

파이프라인 실행 전 공식 스킬 2개가 설치되어 있는지 확인:

```bash
# 설치 시도 (없으면 자동 설치)
npx skills add google-labs-code/stitch-skills --skill enhance-prompt --global 2>/dev/null
npx skills add google-labs-code/stitch-skills --skill stitch-design --global 2>/dev/null
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
- **읽기 전용 도구** (`get_screen`, `list_screens`, `get_project`, `list_projects`) → prism이 검증 루프에서 직접 호출 가능
- **`web_fetch`** → prism이 스크린샷/HTML 다운로드를 위해 직접 호출 가능

## Analyze Pipeline

`/prism analyze` 요청 시. 파이프라인 레퍼런스를 로드하고 실행한다:

```
Read: references/workflows.md
```

Phase A1-A6을 따른다. A5에서 Skill("enhance-prompt")를 호출하여 프롬프트를 최적화.

> **⚠️ 중요**: 프롬프트에 hex 코드, px 값, 특정 폰트명을 포함하지 않는다.

## Design Pipeline

`/prism design` 요청 시. 파이프라인 레퍼런스를 로드하고 실행한다:

```
Read: references/workflows.md
```

Phase D1-D6을 따른다 (D2는 제거됨):
- D3: Design Identity 판단 + Skill("stitch-design") → 디자인 생성
- D4: prism이 직접 검증 (읽기 전용 MCP)
- D5: Skill("stitch-design") → 수정

Phase D4-D6 검증 루프는 **Stop hook**이 자동 관리한다.
상태 파일 `.claude/prism-design-pipeline.local.md`에 `phase: verify`가 설정되면
Stop hook이 `<promise>DESIGN_VERIFIED</promise>` 감지까지 루프를 반복한다.

### All 모드: Feature-by-Feature 순차 처리

`/prism design all` 실행 시 모든 Feature를 순차 처리:

1. Feature 1 디자인 생성 → 검증 루프 → `DESIGN_VERIFIED`
2. Stop hook이 다음 Feature로 상태 파일 전환
3. 반복...
4. 마지막 Feature 완료 → 상태 파일 삭제 → allow

### 완료 조건
- [ ] 코드의 모든 화면이 Stitch 디자인에 1:1 매핑
- [ ] 모든 버튼/인터랙션이 디자인에 반영
- [ ] 상태별 화면(로딩, 에러, 엠티)이 포함
- [ ] 검증 루프에서 누락 0건 확인

## --directions 옵션

`/prism design`과 `/prism pipeline`에서 사용 가능:

| 사용법 | 동작 |
|--------|------|
| `/prism design library` | 단일 Direction (default), 기존 동작 |
| `/prism design library --directions 3` | 3개 Direction으로 멀티 생성 |
| `/prism pipeline app --directions 3` | 분석 → 3방향 → 모두 검증 |

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

## 파일 구조 — .prism/directions/

단일/멀티 모두 동일한 `directions/` 구조:

```
.prism/
  analysis.md                    ← 공통 (A1-A4)
  directions/
    default/                     ← --directions 1
      prompts.md, design-identity.md, project-ids.md
    {direction-name}/            ← --directions N
      prompts.md, design-identity.md, project-ids.md
```

Direction 정리: `rm -rf .prism/directions/{name}/`

## Design Identity

디자인 시스템은 D3에서 Stitch가 자동 생성한다. 첫 Feature 프로젝트의 `designTheme.designMd` 전문을 저장하여 이후 Feature 프로젝트에서 동일한 디자인 시스템을 재현한다.

**판단 기준:** `.prism/directions/{direction}/design-identity.md` 존재 여부
- **미존재**: D3 첫 화면 생성 후 `get_project` → `designTheme`에서 이름 + 메타데이터 + designMd 전문 추출 → 저장
- **존재**: Read → 새 Feature 프로젝트의 첫 프롬프트에 designMd 전문 삽입 (크로스 프로젝트 일관성 80-90%)

**design-identity.md 포맷:**
```
# Design Identity
| 항목 | 값 |
|------|------|
| Name | {디자인 시스템 이름} |
| Source Project | projects/{projectId} |
| Color Mode | {colorMode} |
| Roundness | {roundness} |
| Primary Font | {font} |
| Body Font | {bodyFont} |

## Design System Spec
{designTheme.designMd 전문}
```

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
| 전체 워크플로우 (analyze + design) | `references/workflows.md` |
