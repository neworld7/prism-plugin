---
name: stitch-automation
description: "Google Stitch AI design tool automation. Design pipeline, code pipeline, screen CRUD, design systems, variants. Use when user mentions stitch, 스티치, stitch.withgoogle.com, Stitch 디자인, Stitch MCP."
---

# Stitch Automation Skill

Automate Google Stitch AI design tool via the official Stitch Remote MCP server.

## When to Use

Activate when user:
- Mentions "stitch", "스티치", "stitch.withgoogle.com"
- Asks to create/edit design screens using Stitch
- Wants to generate design variants or manage design systems
- References AI UI design with Stitch
- Asks for UI/UX 디자인, 화면 디자인, 디자인 생성 (in Stitch context)

## Prerequisites

### Authentication Check

Before any Stitch MCP operation, verify auth (우선순위순):

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

### MCP Tool Availability

Verify Stitch MCP tools are loaded:
```
ToolSearch query: "+stitch list_projects"
```

If not found, the `.mcp.json` in this plugin should auto-register the Stitch MCP server.

## Analyze Pipeline (코드+시뮬레이터 분석 → 프롬프트)

`/stitch analyze` 요청 시 아래 5단계를 따른다. design 파이프라인의 입력 자료를 산출한다.

| Phase | 내용 | 핵심 |
|-------|------|------|
| 1 | 코드 분석 | Glob/Grep으로 화면·인터랙션·상태 전수 조사 |
| 2 | 시뮬레이터 분석 | 스크린샷 캡처 + 시각 분석 |
| 3 | Feature 분리 | 코드+시각 분석 종합하여 Feature 단위 분리 |
| 4 | 프롬프트 작성 | Feature별 UX-First Vibe Design 프롬프트 (hex/px/폰트명 금지) |
| 5 | 산출물 | docs/plans/{date}-{app}-analysis.md 작성 |

### Pipeline 실행 시 반드시 참조

```
Read: references/workflows-analyze.md     ← Phase별 실행 절차 상세
Read: references/prompting.md             ← UX-First Vibe Design 프롬프트 원칙 (최우선)
```

> **⚠️ 중요**: analyze 프롬프트에 hex 코드, px 값, 특정 폰트명을 포함하지 않는다.
> 색상은 자연어("warm coral"), 크기는 형용사("rounded", "generous spacing")로 표현.
> `enhance-prompt/` 레퍼런스의 hex/px 예시는 analyze에서 따르지 않는다.

## Design Pipeline (코드→디자인 워크플로우)

Stitch의 주 용도는 **코드→프로덕션 디자인 전환 파이프라인**이다.
`/stitch design` 또는 디자인 관련 요청 시 아래 7단계를 따른다.

| Phase | 내용 | 핵심 |
|-------|------|------|
| 1 | 코드 분석 | Glob/Grep으로 화면·인터랙션·상태 전수 조사 |
| 2 | 디자인 시트 작성 | `docs/plans/` 에 코드 vs 디자인 비교 문서 |
| 3 | 프롬프트 최적화 | Stitch에 최적화된 프롬프트 작성 |
| 4 | Stitch 디자인 생성 | MCP로 프로젝트/화면/디자인시스템 생성 |
| 5 | 검증 | 코드 ↔ Stitch 크로스체크, gaps 카운트 |
| 6 | 누락분 수정 | gaps > 0이면 edit_screens 또는 재생성 |
| 7 | 루프 | 5→6 반복, gaps == 0이면 종료 |

### analysis.md 통합

`/stitch design` 실행 시 `docs/plans/*-analysis.md`가 존재하면:
- Phase 1-3 생략, analysis.md의 프롬프트를 직접 사용
- analysis.md가 design-sheet를 대체
- Phase 4부터 실행

### Pipeline 실행 시 반드시 참조

```
Read: references/workflows-design.md   ← Phase별 실행 절차 상세
Read: references/sheet-template.md      ← 디자인 시트 마크다운 템플릿
Read: references/prompting.md           ← Stitch 프롬프팅 가이드
```

Phase 5-7 검증 루프는 **Stop hook**이 자동 관리한다.
상태 파일 `.claude/stitch-design-pipeline.local.md`에 `phase: verify`가 설정되면
Stop hook이 `<promise>DESIGN_VERIFIED</promise>` 감지까지 루프를 반복한다.

### 완료 조건
- [ ] 코드의 모든 화면이 Stitch 디자인에 1:1 매핑
- [ ] 모든 버튼/인터랙션이 디자인에 반영
- [ ] 상태별 화면(로딩, 에러, 엠티)이 포함
- [ ] 검증 루프에서 누락 0건 확인

## Implement Pipeline (디자인→코드 워크플로우)

Stitch 디자인을 실제 코드에 반영하는 **역방향 파이프라인**.
`/stitch implement` 또는 "디자인을 코드로", "코드에 반영" 요청 시 아래 7단계를 따른다.

| Phase | 내용 | 핵심 |
|-------|------|------|
| 1 | 디자인 수집 | Stitch MCP로 프로젝트/스크린 데이터 수집 |
| 2 | 코드 매핑 | Stitch 스크린 ↔ 기존 코드 파일 대응표 작성 |
| 3 | 구현 계획 | 코드 시트 작성 (화면별 변환 전략) → 사용자 확인 |
| 4 | 코드 구현 | 시트 기반으로 Flutter/React 코드 작성/수정 |
| 5 | 시각 검증 | 구현 코드 스크린샷 ↔ Stitch 디자인 스크린샷 비교 |
| 6 | 차이 수정 | 불일치 항목 코드 수정 |
| 7 | 루프 | 5→6 반복, 차이 0이면 종료 |

### Pipeline 실행 시 반드시 참조

```
Read: references/workflows-implement.md   ← Phase별 실행 절차 상세
Read: references/tools.md                 ← MCP 도구 파라미터 참조
```

Phase 5-7 검증 루프는 **Stop hook**이 자동 관리한다.
상태 파일 `.claude/stitch-implement-pipeline.local.md`에 `phase: code_verify`가 설정되면
Stop hook이 `<promise>CODE_VERIFIED</promise>` 감지까지 루프를 반복한다.

### 시각 검증 핵심

1. **Stitch 디자인 스크린샷**: `get_screen` → `web_fetch(downloadUrl)`
2. **구현 코드 스크린샷**:
   - Flutter: `xcrun simctl io booted screenshot /tmp/{screen}.png` + `sips -Z 1200`
   - React/Next.js: chrome-viewer `cv_screenshot` 또는 Playwright `browser_take_screenshot`
3. **비교**: 두 이미지를 나란히 Read → 레이아웃/색상/컴포넌트/콘텐츠 차이 분석
4. **차이 리포트**: HIGH(누락)/MED(구조)/LOW(폴리싱) 분류
5. **코드 수정 후 재검증**: diffs == 0이면 `<promise>CODE_VERIFIED</promise>`

### 완료 조건
- [ ] 모든 대상 화면이 코드로 구현됨
- [ ] 구현 코드 스크린샷이 Stitch 디자인과 시각적 일치
- [ ] HIGH/MED 차이 0건
- [ ] 코드 시트의 모든 항목이 [DONE]

## Critical Patterns

### Pattern 1: Screen Data Retrieval

Stitch MCP의 `get_screen`은 `downloadUrls`를 반환한다.
HTML 코드와 스크린샷 이미지를 실제로 가져오려면 `web_fetch`가 필요:

```
1. get_screen(projectId, screenId) → response with downloadUrls
2. web_fetch(response.downloadUrls.html) → HTML/CSS code
3. web_fetch(response.downloadUrls.screenshot) → screenshot image
```

### Pattern 2: Screenshot Discipline

- **MCP 도구 우선**: 가능하면 `get_screen` 데이터로 상태 확인
- **스크린샷**: 시각 검증 마일스톤에서만 사용
- **리사이즈 필수**: `sips -Z 1200 <file>` (컨텍스트 오버플로우 방지)

### Pattern 3: Design System — DESIGN.md 워크플로우

MCP 디자인 시스템 도구가 현재 버그로 누락됨. DESIGN.md 기반 워크플로우로 대체:

```
1. create_design_system 호출 시도
2. tool_not_found 에러 → DESIGN.md 워크플로우로 폴백:
   - Read: references/official/design-md/ 참조
   - 프로젝트에 .stitch/DESIGN.md 생성
   - 프롬프트에 DESIGN.md 컨텍스트 포함
3. MCP 도구 성공 시 → 기존 플로우 유지
```

### Pattern 4: Error Recovery

- MCP 도구 실패 → 3회까지 재시도 (1s, 2s, 4s backoff)
- Auth 만료 → `gcloud auth application-default login` 재실행 안내
- Rate limit → Stitch 일일 크레딧 한도 안내 (일일 400 크레딧 + Redesign 15 크레딧)

### Pattern 5: 크레딧 관리 — 일일 크레딧 체계

| 항목 | 한도 | 주기 | 설명 |
|------|------|------|------|
| 일일 크레딧 | **400** | 매일 리셋 | 모든 모드 공유 (Thinking 3 Pro, 3.0 Flash, 2.5 Pro, Fast) |
| Redesign Credits | **15** | 매일 리셋 | Redesign (Nano Banana Pro) 전용 |

**모델 선택 전략:**
| 단계 | 모드 | 용도 |
|------|------|------|
| 기본 (생성/수정 모두) | Thinking with 3 Pro (`GEMINI_3_1_PRO`) | 프로덕션 품질, 깊은 추론 |
| 스타일 실험 | Redesign (Nano Banana Pro) | Vibe Design, 별도 15 크레딧 |

> 일일 400 크레딧이면 PRO 기본 사용에 충분. FLASH는 속도가 필요할 때만 선택적 사용.

**파이프라인 시작 시:**
- 생성할 화면 수를 사용자에게 알림: "총 N개 화면 생성 예정 (일일 한도: 400 크레딧)"
- 사용자 확인 후 진행

### Pattern 6: Stitch 웹 페이지 탐색 (chrome-viewer 사용 시)

Stitch 웹 앱은 cross-origin iframe 구조이다. chrome-viewer 사용 시 반드시 아래 규칙을 따른다.

#### 6a. 반드시 전체 페이지 스크롤 후 판단

페이지에서 특정 섹션을 찾을 때, 뷰포트에 보이는 영역만 보고 "없다"고 판단하면 안 된다.
반드시 페이지 끝까지 스크롤한 후 판단해야 한다.

```
1. cv_scroll(delta_y=99999) → 바닥까지 스크롤
2. cv_screenshot → 하단 확인
3. cv_scroll(delta_y=-99999) → 상단으로 복귀
4. 필요 시 중간 지점도 확인
```

"이 페이지에 X가 없다"고 말하기 전에 최소 3회 스크롤 확인.

#### 6b. Cross-origin iframe은 CDP 직접 접근

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
| Code → Design pipeline (코드를 디자인으로) | `references/workflows-design.md` |
| Design → Code pipeline (디자인을 코드로) | `references/workflows-implement.md` |
| Stitch prompting best practices | `references/prompting.md` |
| MCP tool parameters & usage | `references/tools.md` |
| Design/implement sheet template | `references/sheet-template.md` |
| CDP iframe helper (Stitch 웹 조작) | `references/cdp-iframe-helper.md` |
| Analyze pipeline (코드+시뮬레이터 분석) | `references/workflows-analyze.md` |
| Official: enhance-prompt | `references/official/enhance-prompt/` |
| Official: design-md | `references/official/design-md/` |
| Official: react-components | `references/official/react-components/` |
| Official: shadcn-ui | `references/official/shadcn-ui/` |
| Official: stitch-loop | `references/official/stitch-loop/` |
| Official: remotion | `references/official/remotion/` |
| Official: stitch-design | `references/official/stitch-design/` |
| SDK reference | `references/sdk.md` |
