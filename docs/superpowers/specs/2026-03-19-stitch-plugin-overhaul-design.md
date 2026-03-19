# Stitch Plugin Overhaul — Design Spec v0.2.0

## Overview

Google Stitch가 2026-03-18 대규모 업데이트(AI-Native Infinite Canvas, Gemini 3, 공식 Agent Skills/SDK 출시)를 단행함에 따라, stitch-automation 플러그인을 전면 개편한다.

**핵심 전략:** 공식 Agent Skills 7개를 포크/내재화하고, MCP 도구 참조를 업데이트하며, 기존 파이프라인 골격을 유지하면서 새 기능을 통합한다.

## Architecture

### Approach: 오케스트레이션 레이어 + 공식 스킬 내재화

- 플러그인 동작: Stitch Remote MCP (8개 도구) 직접 호출
- 공식 스킬: `google-labs-code/stitch-skills` 7개 전체를 `references/official/`에 디렉토리째 포크
- SDK: `references/sdk.md`에 문서화 (플러그인 자체는 MCP 사용, 사용자 앱 통합 시 참조)
- 인증: STITCH_API_KEY (우선) + gcloud ADC (대체)

### Plugin Structure

```
stitch-plugin/
├── .claude-plugin/
│   ├── plugin.json              # 버전 0.2.0
│   └── marketplace.json
├── .mcp.json                    # Official Stitch Remote MCP (STITCH_API_KEY는 환경변수로 자동 주입 — Claude Code MCP 클라이언트가 gcloud ADC 또는 환경변수 기반 인증을 자동 처리)
├── commands/
│   └── stitch.md                # 서브커맨드 업데이트
├── skills/
│   └── stitch-automation/
│       ├── SKILL.md             # 트리거/인증 업데이트
│       └── references/
│           ├── official/        # 공식 스킬 포크 (전체, 디렉토리째)
│           │   ├── stitch-design/
│           │   ├── stitch-loop/
│           │   ├── design-md/
│           │   ├── enhance-prompt/
│           │   ├── react-components/
│           │   ├── remotion/
│           │   └── shadcn-ui/
│           ├── tools.md         # MCP 8개 도구 + 새 파라미터
│           ├── sdk.md           # SDK 레퍼런스 (신규)
│           ├── prompting.md     # enhance-prompt 참조하도록 업데이트
│           ├── workflows-analyze.md   # 분석 파이프라인 (신규)
│           ├── workflows-design.md    # 파이프라인 업데이트
│           ├── workflows-implement.md # 파이프라인 업데이트
│           └── sheet-template.md      # 업데이트
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       ├── design-verify-stop.sh
│       └── code-verify-stop.sh
└── docs/
```

## MCP 도구 변경 사항

### 현재 작동하는 도구 (8개)

| # | Tool | Category | 변경 사항 |
|---|------|----------|-----------|
| 1 | `create_project` | Project | 변경 없음 |
| 2 | `get_project` | Project | 변경 없음 |
| 3 | `list_projects` | Project | `view=shared` 옵션 확인 |
| 4 | `list_screens` | Screen | 변경 없음 |
| 5 | `get_screen` | Screen | `name` 필수 (format: `projects/{projectId}/screens/{screenId}`), `projectId`/`screenId`는 deprecated(하위호환 유지, 향후 제거 예정). 워크플로우 호출 패턴을 `name` 기반으로 전환 |
| 6 | `generate_screen_from_text` | AI Generation | `modelId`, `deviceType` enum 확장 |
| 7 | `edit_screens` | AI Generation | `modelId`, `deviceType` enum 동일 확장 |
| 8 | `generate_variants` | AI Generation | `variantOptions` 전체 스키마 추가 |

### 제거된 도구

| Tool | 상태 |
|------|------|
| `delete_project` | MCP 서버에서 제거됨 |
| `upload_screens_from_images` | MCP 서버에서 제거됨 |

### 버그로 누락된 도구 (복구 대기)

| Tool | 상태 | 대안 |
|------|------|------|
| `create_design_system` | Google 포럼에서 공식 인정 | DESIGN.md 워크플로우 사용 |
| `update_design_system` | 동일 | DESIGN.md 워크플로우 사용 |
| `list_design_systems` | 동일 | DESIGN.md 워크플로우 사용 |
| `apply_design_system` | 동일 | DESIGN.md 워크플로우 사용 |

### 기존 파일 업데이트 지시

- **tools.md**: 제거된 도구(`delete_project`, `upload_screens_from_images`) 섹션 삭제. 버그 누락 도구 4개는 "복구 대기 — DESIGN.md 워크플로우로 대체" 표기.
- **SKILL.md**: Pattern 3 (Design System Consistency)을 DESIGN.md 워크플로우 패턴으로 교체. MCP 도구 복구 시 자동 전환 분기 포함.
- **commands/stitch.md**: Phase 4-5 실행 순서에서 `create_design_system`/`apply_design_system` 직접 호출 제거, DESIGN.md 워크플로우로 교체. 신규 서브커맨드(`analyze`, `design-md`, `remotion`) 추가. 인증 플로우를 STITCH_API_KEY 우선으로 변경.

### 새 파라미터

**modelId enum:**
- `MODEL_ID_UNSPECIFIED` (기본값)
- `GEMINI_3_PRO` (Experimental, 50/월)
- `GEMINI_3_FLASH` (Standard, 350/월)

**deviceType enum:**
- `DEVICE_TYPE_UNSPECIFIED`
- `MOBILE`
- `DESKTOP`
- `TABLET` (신규)
- `AGNOSTIC` (신규)

**generate_variants의 variantOptions:**
```json
{
  "variantCount": 3,
  "creativeRange": "EXPLORE",
  "aspects": ["LAYOUT", "COLOR_SCHEME"]
}
```

- `variantCount`: 1-5, 기본값 3
- `creativeRange`: `REFINE` (미세조정) | `EXPLORE` (균형 탐색, 기본값) | `REIMAGINE` (급진적 재해석)
- `aspects`: `LAYOUT` | `COLOR_SCHEME` | `IMAGES` | `TEXT_FONT` | `TEXT_CONTENT` (복수 선택)

## 인증 시스템

### 우선순위

```
1. STITCH_API_KEY 환경변수 확인 (신규, 간편)
2. gcloud ADC 토큰 확인 (기존)
3. 둘 다 없으면 → 사용자에게 택 1 안내
```

### STITCH_API_KEY 발급 방법

Stitch 웹 UI → 프로필 메뉴 → Exports 패널에서 API Key 직접 발급

### gcloud ADC (기존)

```bash
gcloud auth login
gcloud auth application-default login
```

## 크레딧 관리 및 모델 전략

### 모델 용도 분리

| 단계 | 모델 | 한도 | 용도 |
|------|------|------|------|
| 최초 전체 화면 생성 | `GEMINI_3_PRO` | 50/월 | 프로덕션 품질의 원샷 생성 |
| 미세 수정/반복 편집 | `GEMINI_3_FLASH` | 350/월 | edit_screens로 세부 조정 |

### 크레딧 효율화 전략

1. **PRO 먼저, FLASH 나중**: 전체 화면을 PRO로 한 번에 생성 → 검증 후 미세 수정은 FLASH로 edit_screens
2. **원샷 품질 프롬프트**: enhance-prompt + analyze 산출물로 최대한 상세하게 작성하여 재생성 최소화
3. **edit_screens 우선**: 재생성 대신 편집으로 크레딧 절약
4. **Rate limit 감지**: MCP에 할당량 조회 도구가 없으므로, 생성 시도 중 rate limit 에러 응답으로 감지. 파이프라인 시작 시 생성할 화면 수를 사용자에게 알려 사전 판단 지원

### 파이프라인 적용

```
/stitch analyze → 상세 프롬프트 사전 준비 (크레딧 소비 없음)
/stitch design  → PRO로 전체 화면 원샷 생성
              → 검증 후 미세 수정은 FLASH로 edit_screens
```

## 공식 Agent Skills 포크

### 포크 대상 (7개 전체)

| # | 스킬 | 용도 | 플러그인 내 활용 |
|---|------|------|-----------------|
| 1 | stitch-design | 통합 진입점: 프롬프트 강화 + 디자인 시스템 합성 + 화면 생성 | workflows-design.md Phase 3-4에서 참조 |
| 2 | stitch-loop | 단일 프롬프트로 멀티페이지 웹사이트 생성 | workflows-design.md Phase 4 멀티페이지 옵션 |
| 3 | design-md | DESIGN.md 파일 자동 생성 | MCP 디자인 시스템 도구 대안 |
| 4 | enhance-prompt | UI 아이디어를 Stitch 최적화 프롬프트로 변환 | workflows-analyze.md, prompting.md에서 참조 |
| 5 | react-components | Stitch 화면을 React 컴포넌트 시스템으로 변환 | workflows-implement.md Phase 4 React 경로 |
| 6 | remotion | Remotion 기반 워크스루 영상 생성 | /stitch remotion 커맨드 |
| 7 | shadcn-ui | shadcn/ui 컴포넌트 통합 가이드 | workflows-implement.md Phase 4 React+shadcn 경로 |

### 포크 관리

- 원본 보존: `references/official/` 하위에 디렉토리 구조째 복사
- 업스트림 추적 주석: 각 디렉토리에 `<!-- upstream: google-labs-code/stitch-skills@{commit}, synced: 2026-03-19 -->`
- 업데이트 주기: Stitch 메이저 업데이트 시 수동 확인 (별도 자동화 없음)

## Command System 업데이트

### /stitch 서브커맨드

| Command | 변경 | 설명 |
|---------|------|------|
| `/stitch analyze [app]` | **신규** | 코드+시뮬레이터 분석 → Feature 분리 → 상세 프롬프트 → analysis.md 산출 |
| `/stitch design [feature]` | 업데이트 | analysis.md를 입력으로 받아 PRO 생성 → FLASH 수정 |
| `/stitch implement [feature]` | 업데이트 | react-components/shadcn-ui 참조 |
| `/stitch verify-loop` | 유지 | 변경 없음 |
| `/stitch code-verify-loop` | 유지 | 변경 없음 |
| `/stitch cancel-loop` | 유지 | 변경 없음 |
| `/stitch status` | 유지 | 변경 없음 |
| `/stitch list` | 유지 | 변경 없음 |
| `/stitch create` | 업데이트 | 새 deviceType/modelId 지원 |
| `/stitch edit` | 업데이트 | 새 deviceType/modelId 지원 |
| `/stitch variants` | 업데이트 | variantOptions 전체 스키마 지원 |
| `/stitch theme` | 업데이트 | MCP 도구 복구 시까지 DESIGN.md 워크플로우로 전환 |
| `/stitch export` | 유지 | 변경 없음 |
| `/stitch design-md` | **신규** | DESIGN.md 생성/업데이트. 입력: 프로젝트 컨텍스트(Stitch 프로젝트 또는 URL). 산출물: `.stitch/DESIGN.md`. 실행: `official/design-md/` 워크플로우 참조 |
| `/stitch remotion` | **신규, P2** | 워크스루 영상 생성. 입력: Stitch 프로젝트. 산출물: Remotion 프로젝트 + MP4. 실행: `official/remotion/` 워크플로우 참조. 초기 구현에서 제외 가능 |

## Pipeline 0: Analyze (`/stitch analyze`) — 신규

### 목적

코드와 실제 실행 화면을 분석하여, Feature별 상세 Stitch 프롬프트를 포함한 분석 문서를 산출한다. `/stitch design`의 입력 자료가 된다.

### 산출물

`docs/plans/{date}-{app}-analysis.md` — 단일 파일에 전체 Feature와 프롬프트 포함

### Phase 1: 코드 분석

1. 프로젝트 스택 판별:
   - Flutter: `Glob: lib/**/*.dart`
   - React: `Glob: src/**/*.{tsx,jsx}`
   - Next.js: `Glob: app/**/*.{tsx,jsx}`

2. 화면/페이지 추출:
   - Flutter: `Grep: class.*Screen|class.*Page|class.*View`
   - React/Next: `Grep: export default|export function` in page files

3. 라우트/네비게이션 구조:
   - Flutter: `Grep: GoRoute|MaterialPageRoute|Navigator.push`
   - React/Next: 파일 기반 라우팅 or `Grep: useRouter|Link`

4. 인터랙션 추출:
   - `Grep: onTap|onPressed|onClick|onSubmit|GestureDetector`

5. 상태 추출:
   - `Grep: Loading|Error|Empty|CircularProgressIndicator|Shimmer|skeleton`

### Phase 2: 시뮬레이터 스크린샷 캡처 및 분석

1. 앱 실행 확인 (시뮬레이터/에뮬레이터 또는 dev 서버)

2. 화면별 스크린샷 캡처:
   - Flutter: `xcrun simctl io booted screenshot /tmp/analyze-{screen}.png` + `sips -Z 1200`
   - React/Next.js: chrome-viewer `cv_screenshot` 또는 Playwright `browser_take_screenshot`

3. 각 스크린샷 Read → 시각 분석:
   - 레이아웃 구조 (헤더, 본문, 푸터, 네비게이션)
   - 컴포넌트 유형 (카드, 리스트, 폼, 버튼, 아이콘)
   - 색상 팔레트, 타이포그래피
   - 현재 디자인 품질/문제점

### Phase 3: Feature 분리

코드 분석 + 스크린샷 분석 결과를 종합하여 Feature 단위로 분리:

```
예시:
Feature 1: 인증 (로그인, 회원가입, 비밀번호 재설정)
Feature 2: 홈 대시보드 (메인 피드, 알림, 퀵 액션)
Feature 3: 라이브러리 (목록, 검색, 필터, 상세)
Feature 4: 프로필 (설정, 통계, 편집)
```

각 Feature에 포함되는 화면, 인터랙션, 상태를 매핑.

### Phase 4: Feature별 상세 프롬프트 작성

`references/official/enhance-prompt/` + `references/prompting.md` 참조하여:

1. Feature별로 포함된 각 화면에 대해 상세 프롬프트 작성
2. 프롬프트에 포함할 내용:
   - 화면 목적 (페이지 유형)
   - 핵심 UI 컴포넌트 목록
   - 레이아웃/구조 명세
   - 스타일/테마 지시 (스크린샷에서 추출한 색상/분위기)
   - 동적 콘텐츠 유형
   - 브랜딩 (앱 이름, 아이콘 배치)
   - 디바이스 타입
3. PRO 원샷 품질 목표: 한 번의 생성으로 완성도 높은 결과가 나오도록 충분히 상세하게

### Phase 5: 산출물 작성

`docs/plans/{date}-{app}-analysis.md` 작성 → 사용자 확인 요청

산출물 구조:
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

## Feature 요약

| # | Feature | 화면 수 | 핵심 화면 |
|---|---------|---------|-----------|
| 1 | 인증 | 3 | 로그인, 회원가입, 비밀번호 재설정 |
| 2 | 홈 | 2 | 대시보드, 알림 |
| ... | ... | ... | ... |

## Feature 1: {feature name}

### 화면 목록

| # | 화면 | 코드 파일 | 현재 상태 | 스크린샷 분석 요약 |
|---|------|-----------|-----------|-------------------|
| 1 | 로그인 | lib/.../login_screen.dart | 기본 폼 | 단순 이메일/비밀번호, 브랜딩 없음 |

### 인터랙션

- [ ] 이메일/비밀번호 입력
- [ ] 로그인 버튼 → 홈으로 이동
- [ ] "비밀번호 찾기" 링크
- [ ] 소셜 로그인 버튼

### 상태별 화면

| 상태 | 설명 |
|------|------|
| 로딩 | 로그인 처리 중 스피너 |
| 에러 | 잘못된 자격 증명 메시지 |

### Stitch 프롬프트

#### 로그인 화면
```
Design a mobile login screen for a reading tracker app called 'ReadCodex'.
Center: App logo with tagline "Track your reading journey".
Form: Email field with envelope icon, password field with eye toggle,
rounded input borders (12px), subtle shadow on focus.
Below form: "Forgot password?" link in muted text.
Primary CTA: "Sign In" button, full-width, coral (#FF6B6B) background,
white text, rounded (24px).
Bottom: "Don't have an account? Sign up" with link highlight.
Social login section: Google and Apple sign-in buttons with brand icons,
outlined style.
Use warm white (#FEFEFE) background, serif font for logo,
sans-serif (Inter) for body. iOS-style with safe area padding.
```

#### 회원가입 화면
```
...
```

## Feature 2: {feature name}
...
```

## Pipeline 1: Code→Design (`/stitch design`) 업데이트

### 변경된 흐름

```
/stitch analyze → docs/plans/{date}-{app}-analysis.md 산출
                    ↓
/stitch design [feature] → analysis.md에서 해당 Feature의 프롬프트 로드
                         → Phase 4부터 실행 (Phase 1-3 생략)
```

`/stitch design`에 analysis.md가 없으면 기존 Phase 1-3 실행 (하위 호환).
analysis.md가 존재하면 기존 design-sheet.md 생성을 생략하고, analysis.md가 design-sheet를 대체한다.

### Phase 4: Stitch Design Generation — 업데이트
- **입력**: analysis.md의 Feature별 프롬프트
- **모델 전략**: PRO로 전체 화면 최초 생성 → FLASH로 미세 수정
- **디자인 시스템**: DESIGN.md 워크플로우 사용 (`references/official/design-md/` 참조)
  - 분기 로직: `create_design_system` 호출 시도 → `tool_not_found` 에러 시 DESIGN.md 워크플로우로 폴백 → MCP 도구 성공 시 기존 플로우 유지
- **멀티페이지**: `stitch-loop` 패턴 참조하여 일괄 생성 옵션 제공
- **deviceType**: `TABLET`, `AGNOSTIC` 추가 지원

### Phase 5-7: Verification Loop — 업데이트
- Phase 6 수정 시 `FLASH` 모델 사용 (edit_screens)
- 나머지 골격 유지

## Pipeline 2: Design→Code (`/stitch implement`) 업데이트

### Phase 1-2: Collection & Mapping — 변경 없음
- `get_screen`에서 `name` 필드 우선 사용 (deprecated 필드 대비)

### Phase 3: Implementation Plan Sheet — 변경 없음

### Phase 4: Code Implementation — 업데이트
- **React 경로**: `references/official/react-components/` 참조
- **React + shadcn 경로**: `references/official/shadcn-ui/` 참조
- **Flutter 경로**: 기존 유지 (공식에 없는 우리 고유 가치)

### Phase 5-7: Visual Verification Loop — 변경 없음 (골격 유지)

## SDK Reference (신규, P2)

**우선순위: P2** — 플러그인 핵심 기능(MCP, 파이프라인, 커맨드) 구현 후 별도 작성. 초기 구현 범위에서 제외 가능.

`references/sdk.md`에 `@google/stitch-sdk` 사용법 문서화:

- `Stitch` 클래스: `projects()`, `project(id)`, `listTools()`, `callTool(name, args)`
- `Project` 클래스: `generate(prompt, deviceType?)`, `screens()`, `getScreen(screenId)`
- `Screen` 클래스: `edit(prompt)`, `variants(prompt, options)`, `getHtml()`, `getImage()`
- `stitchTools()`: Vercel AI SDK 통합
- 인증: `STITCH_API_KEY` 환경변수
- 용도: 사용자가 앱 코드에서 Stitch를 프로그래매틱하게 통합할 때 참조

## Error Handling 업데이트

### 인증 실패

```
1. STITCH_API_KEY 확인 → 없으면
2. gcloud ADC 토큰 확인 → 만료/없으면
3. 안내: "아래 중 하나를 설정해주세요:
   - STITCH_API_KEY 환경변수 (Stitch 웹 → 프로필 → Exports에서 발급)
   - gcloud auth application-default login 실행"
```

### 디자인 시스템 도구 누락

```
MCP create_design_system 호출 시 도구 미발견 →
자동으로 DESIGN.md 워크플로우로 전환 →
"MCP 디자인 시스템 도구가 현재 비활성 상태입니다. DESIGN.md 워크플로우로 대체합니다." 메시지
```

### Rate Limit 대응

MCP에 할당량 조회 도구가 없으므로, rate limit은 생성 시도 중 에러 응답으로 감지한다.

```
파이프라인 시작 시:
1. 생성할 화면 수 계산
2. 사용자에게 "총 N개 화면을 PRO로 생성합니다 (PRO 한도: 50/월)" 안내
3. 사용자 확인 후 진행

생성 중 rate limit 에러 수신 시:
1. PRO rate limit → "PRO 한도에 도달했습니다. FLASH로 전환할까요?" 확인
2. 사용자 승인 시 FLASH로 전환하여 계속
3. FLASH도 rate limit → 파이프라인 일시 정지, 사용자에게 알림
```

## Stitch 웹 UI 신규 기능 (참고)

플러그인이 직접 활용하지는 않지만, 문맥 파악을 위해 기록:

- AI-Native Infinite Canvas: 무한 캔버스 기반 디자인 플랫폼
- Voice Canvas: 음성 대화로 디자인
- Design Agent: 프로젝트 전체 컨텍스트 추론
- Agent Manager: 병렬 아이디어 작업
- Manual Editing: 텍스트/이미지 직접 수정 (재프롬프트 불필요)
- Instant Prototypes: 화면 간 연결하여 인터랙티브 프로토타입 생성

## Migration from v0.1.0

| v0.1.0 | v0.2.0 | 변경 |
|--------|--------|------|
| 14개 MCP 도구 (문서화 기준, 실제 동작은 이미 일부 제한) | 8개 MCP 도구 (실제 동작 확인) | 6개 제거/누락 |
| gcloud ADC only | STITCH_API_KEY + gcloud ADC | 인증 이중화 |
| `create_design_system` MCP | DESIGN.md 워크플로우 | 디자인 시스템 관리 방식 전환 |
| 자체 프롬프팅 가이드만 | 공식 enhance-prompt 포크 통합 | 프롬프트 최적화 강화 |
| React 기본 변환만 | react-components + shadcn-ui 참조 | React 변환 품질 향상 |
| 모델 미지정 | PRO(생성) + FLASH(수정) 이중 전략 | 크레딧 효율화 |
| Phase 1-3에서 분석+프롬프트 | `/stitch analyze` 별도 분리 | 코드+시뮬레이터 분석 → 상세 프롬프트 사전 준비 |
| 없음 | /stitch analyze | 코드+시뮬레이터 분석 커맨드 |
| 없음 | /stitch design-md | DESIGN.md 전용 커맨드 |
| 없음 | /stitch remotion | 워크스루 영상 커맨드 |
| 없음 | references/sdk.md | SDK 레퍼런스 |
| 없음 | references/official/ (7개 스킬) | 공식 스킬 포크 |

## External References

- Official docs: https://stitch.withgoogle.com/docs/
- MCP setup: https://stitch.withgoogle.com/docs/mcp/setup
- MCP reference: https://stitch.withgoogle.com/docs/mcp/reference
- Agent Skills: https://github.com/google-labs-code/stitch-skills
- SDK: https://github.com/google-labs-code/stitch-sdk
- Community proxy: https://github.com/davideast/stitch-mcp
- Design Systems MCP bug: https://discuss.ai.google.dev/t/design-systems-category-missing-from-mcp-server-tools/126064
