---
name: stitch
description: "Google Stitch AI design tool automation — design pipeline, code pipeline, screen CRUD, design systems, variants"
---

# /stitch Command

Google Stitch AI design tool automation command.

## Usage

Parse user arguments to determine the subcommand:

| Subcommand | Usage | Action |
|------------|-------|--------|
| `design` | `/stitch design [feature]` | **코드→디자인 파이프라인** (Phase 1-7, 디자인 검증 루프 포함) |
| `implement` | `/stitch implement [feature]` | **디자인→코드 파이프라인** (Phase 1-7, 시각 검증 루프 포함) |
| `verify-loop` | `/stitch verify-loop` | 디자인 검증 루프만 단독 시작 |
| `code-verify-loop` | `/stitch code-verify-loop` | 코드 검증 루프만 단독 시작 |
| `cancel-loop` | `/stitch cancel-loop` | 진행 중인 검증 루프 즉시 취소 |
| `status` | `/stitch status` | 현재 파이프라인 상태 표시 |
| `list` | `/stitch list` | 프로젝트/화면 목록 |
| `create` | `/stitch create '프로젝트명' 또는 '프롬프트'` | 프로젝트 또는 화면 생성 |
| `edit` | `/stitch edit '화면명' '수정 프롬프트'` | 화면 편집 |
| `variants` | `/stitch variants '화면명'` | 디자인 변형 생성 |
| `theme` | `/stitch theme` | 디자인 시스템 생성/적용 |
| `export` | `/stitch export html\|image` | 화면 HTML/이미지 다운로드 |
| `analyze` | `/stitch analyze [app]` | 코드+시뮬레이터 분석 → Feature별 상세 프롬프트 → analysis.md 산출 |
| `design-md` | `/stitch design-md` | DESIGN.md 생성/업데이트. 입력: 프로젝트 컨텍스트. 산출물: `.stitch/DESIGN.md` |
| `remotion` | `/stitch remotion` | **P2** 워크스루 영상 생성. 입력: Stitch 프로젝트. 산출물: Remotion 프로젝트 + MP4 |

## `/stitch analyze [app]` — 코드+시뮬레이터 분석

코드와 실행 화면을 분석하여 Feature별 상세 프롬프트를 산출한다. `/stitch design`의 입력 자료가 된다.

### 실행 절차

1. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-analyze.md
   Read: references/official/enhance-prompt/
   Read: references/prompting.md
   ```

2. **Phase 1-5 실행** (workflows-analyze.md 참조)

3. **산출물**: `docs/plans/{date}-{app}-analysis.md`

4. **사용자 확인 요청** — 산출물을 승인해야 `/stitch design`에서 사용 가능

`app` 인자 예시: `/stitch analyze readcodex`, `/stitch analyze bookflip`
인자 없으면 현재 프로젝트 이름 사용.

## `/stitch design [feature]` — 전체 파이프라인

가장 핵심적인 서브커맨드. Phase 1-7을 자동 실행한다.

### 실행 절차

1. **상태 파일 초기화**: `.claude/stitch-design-pipeline.local.md` 생성
   ```yaml
   ---
   phase: analysis
   feature: {feature 또는 "all"}
   session_id: {현재 세션 ID}
   iteration: 0
   max_iterations: 5
   ---
   ```

1-1. **analysis.md 확인**: `docs/plans/*-analysis.md` 존재 시 Phase 1-3 생략, Phase 4부터 실행

2. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-design.md
   Read: references/sheet-template.md
   Read: references/prompting.md
   ```

3. **Phase 1-2**: 코드 분석 → 디자인 시트 작성 → **사용자 확인 요청**

4. **Phase 3**: 프롬프트 최적화

5. **Phase 4**: Stitch MCP로 디자인 생성
   - `create_project`
   - 디자인 시스템: `create_design_system` 시도 → 실패 시 DESIGN.md 워크플로우 전환
   - `generate_screen_from_text(... modelId: "GEMINI_3_1_PRO")` × N
   - 검증 후 수정은 `edit_screens(... modelId: "GEMINI_3_1_FLASH")`

6. **Phase 4 완료 후**: 상태 파일의 `phase`를 `verify`로 변경 → 검증 루프 자동 시작
   - Stop hook이 `<promise>DESIGN_VERIFIED</promise>` 감지까지 루프 반복

`feature` 인자 예시: `/stitch design library`, `/stitch design dashboard`
인자 없으면 전체 앱 대상 (feature 선택 프롬프트 표시).

## `/stitch implement [feature]` — 디자인→코드 파이프라인

Stitch 디자인을 실제 코드에 반영하는 **역방향 파이프라인**. Phase 1-7을 자동 실행한다.

### 실행 절차

1. **상태 파일 초기화**: `.claude/stitch-implement-pipeline.local.md` 생성
   ```yaml
   ---
   phase: collect
   feature: {feature 또는 "all"}
   session_id: {현재 세션 ID}
   iteration: 0
   max_iterations: 5
   target_stack: flutter
   ---
   ```

2. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-implement.md
   Read: references/tools.md
   ```

3. **Phase 1-2**: Stitch 디자인 수집 + 코드 매핑

4. **Phase 3**: 코드 시트 작성 → `docs/plans/` 에 생성 → **사용자 확인 요청**

5. **Phase 4**: 시트 기반으로 코드 작성/수정
   - Flutter: 기존 변환 전략
   - React: `Read references/official/react-components/` → 컴포넌트 변환
   - React + shadcn: `Read references/official/shadcn-ui/` → shadcn/ui 통합

6. **Phase 4 완료 후**: 상태 파일의 `phase`를 `code_verify`로 변경 → 시각 검증 루프 자동 시작

## `/stitch verify-loop` — 디자인 검증 루프 단독

1. `.claude/stitch-design-pipeline.local.md` 생성 (phase: verify)
   ```yaml
   ---
   phase: verify
   feature: {feature 또는 "all"}
   session_id: {현재 세션 ID}
   iteration: 0
   max_iterations: 5
   ---
   ```
2. `Read: references/workflows-design.md` Phase 5 절차 실행
3. Stop hook이 자동으로 루프 관리

## `/stitch code-verify-loop` — 코드 검증 루프 단독

1. `.claude/stitch-implement-pipeline.local.md` 생성 (phase: code_verify)
   ```yaml
   ---
   phase: code_verify
   feature: {feature 또는 "all"}
   session_id: {현재 세션 ID}
   iteration: 0
   max_iterations: 5
   target_stack: flutter
   ---
   ```
2. `Read: references/workflows-implement.md` Phase 5 절차 실행
3. Stop hook이 자동으로 루프 관리

## `/stitch cancel-loop` — 루프 취소

진행 중인 모든 검증 루프를 즉시 종료.

```bash
rm -f .claude/stitch-design-pipeline.local.md .claude/stitch-implement-pipeline.local.md
```
"검증 루프가 취소되었습니다." 메시지 출력

## `/stitch status` — 상태 확인

두 상태 파일을 읽어 현재 상태 표시:
- 현재 phase, feature, project_id
- iteration / max_iterations
- target_stack (implement only)

상태 파일이 없으면 "활성 파이프라인 없음" 출력.

## `/stitch list` — 목록

```
list_projects(filter: "view=owned") → 프로젝트 목록 표시
```
프로젝트 선택 후 `list_screens(projectId)` → 화면 목록 표시

## `/stitch create` — 생성

프로젝트 또는 화면 생성:
- 프로젝트: `create_project(title: "...")`
- 화면: `generate_screen_from_text(projectId, prompt, deviceType)`

인자에 따라 분기:
- 인자 없음 → 프로젝트 생성 or 화면 생성 선택
- `'프로젝트명'` → `create_project`
- `'프롬프트'` (프로젝트 컨텍스트 있을 때) → `generate_screen_from_text`

**v0.2.0**: `deviceType`에 `TABLET`, `AGNOSTIC` 추가. `modelId`로 `GEMINI_3_1_PRO` 또는 `GEMINI_3_1_FLASH` 지정 가능.

## `/stitch edit` — 편집

`edit_screens(projectId, selectedScreenIds: [...], prompt: "수정 프롬프트")`

프로젝트와 화면 선택이 필요하면 `list_projects` → `list_screens`로 안내.

**v0.2.0**: `deviceType`에 `TABLET`, `AGNOSTIC` 추가. `modelId`로 `GEMINI_3_1_PRO` 또는 `GEMINI_3_1_FLASH` 지정 가능.

## `/stitch variants` — 변형

`generate_variants(projectId, selectedScreenIds: [...], prompt, variantOptions)`

**v0.2.0 variantOptions**: `creativeRange` (`REFINE`/`EXPLORE`/`REIMAGINE`), `aspects` (`LAYOUT`/`COLOR_SCHEME`/`IMAGES`/`TEXT_FONT`/`TEXT_CONTENT`), `variantCount` (1-5).

## `/stitch theme` — 디자인 시스템

1. `create_design_system` 호출 시도
2. **MCP 도구 없을 시**: DESIGN.md 워크플로우로 전환 (`/stitch design-md` 참조)
   - "MCP 디자인 시스템 도구가 현재 비활성 상태입니다. DESIGN.md 워크플로우로 대체합니다."
3. MCP 도구 사용 가능 시: 기존 플로우 유지
   - `list_design_systems(projectId)` → 기존 시스템 확인
   - 없으면 `create_design_system(...)` / 있으면 `update_design_system(...)`
   - `apply_design_system(projectId, designSystemId)`

## `/stitch export` — 내보내기

- `html`: `get_screen` → `web_fetch(downloadUrl.html)` → 파일 저장
- `image`: `get_screen` → `web_fetch(downloadUrl.screenshot)` → 파일 저장

## `/stitch design-md` — DESIGN.md 생성/업데이트

1. `Read: references/official/design-md/` → 실행 절차 참조
2. 입력: Stitch 프로젝트 컨텍스트 또는 URL
3. 산출물: `.stitch/DESIGN.md`
4. 기존 DESIGN.md가 있으면 업데이트, 없으면 생성

## `/stitch remotion` — 워크스루 영상 생성 (P2)

1. `Read: references/official/remotion/` → 실행 절차 참조
2. 입력: Stitch 프로젝트
3. 산출물: Remotion 프로젝트 + MP4
4. **P2**: 초기 구현에서 제외 가능

## Execution

1. Activate the `stitch-automation` skill — it contains all MCP tool patterns, workflows, and safety patterns.
2. Execute the requested subcommand following the skill's workflow references.

## No Arguments

If called without arguments (`/stitch`), show the usage table above and ask what the user wants to do.

## Error Handling

- **인증 실패**:
  1. STITCH_API_KEY 확인 → 없으면
  2. gcloud ADC 토큰 확인 → 만료/없으면
  3. 안내: "아래 중 하나를 설정해주세요:
     - STITCH_API_KEY 환경변수 (Stitch 웹 → 프로필 → Exports에서 발급)
     - gcloud auth application-default login 실행"

- **Rate limit 대응**:
  - 파이프라인 시작 시: "총 N개 화면 생성 예정 (일일 한도: 400 크레딧)" 안내
  - 크레딧 소진 시: 파이프라인 일시 정지, 다음 날 리셋 대기 안내
  - 

- **디자인 시스템 도구 누락**:
  - create_design_system 호출 시 도구 미발견 → DESIGN.md 워크플로우 자동 전환
  - "MCP 디자인 시스템 도구가 현재 비활성 상태입니다. DESIGN.md 워크플로우로 대체합니다."

- If project/screen not found: show list and ask user to select
- If generation fails: retry up to 3 times, then report error
