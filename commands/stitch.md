---
name: stitch
description: "Google Stitch AI design tool automation — analyze, design, implement 파이프라인"
---

# /stitch Command

Google Stitch AI design tool automation command.

## Usage

Parse user arguments to determine the subcommand:

| Subcommand | Usage | Action |
|------------|-------|--------|
| `analyze` | `/stitch analyze [app]` | 코드+시뮬레이터 분석 → Feature별 UX-First 프롬프트 → analysis.md 산출 |
| `design` | `/stitch design [feature]` | **코드→디자인 파이프라인** (Phase 1-7, 일괄 생성 + 검증 루프) |
| `implement` | `/stitch implement [feature]` | **디자인→코드 파이프라인** (Phase 1-7, 시각 검증 루프) |

> MCP 직접 호출 (`list_projects`, `create_project`, `edit_screens`, `generate_variants` 등)은
> Stitch MCP 도구를 직접 사용하세요. 이 커맨드는 파이프라인 자동화에 집중합니다.

## `/stitch analyze [app]` — 코드+시뮬레이터 분석

코드와 실행 화면을 분석하여 Feature별 UX-First 프롬프트를 산출한다. `/stitch design`의 입력 자료.

### 실행 절차

1. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-analyze.md
   Read: references/prompting.md
   ```

2. **Phase 1-5 실행** (workflows-analyze.md 참조)

3. **산출물**: `.stitch/{date}-{app}-analysis.md`

4. **사용자 확인 요청** — 산출물을 승인해야 `/stitch design`에서 사용 가능

`app` 인자 예시: `/stitch analyze readcodex`, `/stitch analyze bookflip`
인자 없으면 현재 프로젝트 이름 사용.

## `/stitch design [feature]` — 코드→디자인 파이프라인

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

1-1. **analysis.md 확인**: `.stitch/*-analysis.md` 존재 시 Phase 1-3 생략, Phase 4부터 실행

2. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-design.md
   Read: references/sheet-template.md
   Read: references/prompting.md
   ```

3. **Phase 1-2**: 코드 분석 → 디자인 시트 작성 → **사용자 확인 요청**

4. **Phase 3**: 프롬프트 최적화

5. **Phase 4**: Stitch MCP로 디자인 생성 (Feature 단위 일괄 생성)
   - `create_project`
   - `generate_screen_from_text(... modelId: "GEMINI_3_1_PRO")` — Feature당 1회 호출
   - 검증 후 수정도 `edit_screens(... modelId: "GEMINI_3_1_PRO")`

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

4. **Phase 3**: 코드 시트 작성 → `.stitch/` 에 생성 → **사용자 확인 요청**

5. **Phase 4**: 시트 기반으로 코드 작성/수정

6. **Phase 4 완료 후**: 상태 파일의 `phase`를 `code_verify`로 변경 → 시각 검증 루프 자동 시작

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

- If project/screen not found: show list and ask user to select
- If generation fails: retry up to 3 times, then report error
