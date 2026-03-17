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

2. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-design.md
   Read: references/sheet-template.md
   Read: references/prompting.md
   ```

3. **Phase 1-2**: 코드 분석 → 디자인 시트 작성 → **사용자 확인 요청**

4. **Phase 3**: 프롬프트 최적화

5. **Phase 4**: Stitch MCP로 디자인 생성
   - `create_project` → `create_design_system` → `generate_screen_from_text` × N → `apply_design_system`

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

## `/stitch edit` — 편집

`edit_screens(projectId, selectedScreenIds: [...], prompt: "수정 프롬프트")`

프로젝트와 화면 선택이 필요하면 `list_projects` → `list_screens`로 안내.

## `/stitch variants` — 변형

`generate_variants(projectId, selectedScreenIds: [...], prompt, variantOptions)`

## `/stitch theme` — 디자인 시스템

1. `list_design_systems(projectId)` → 기존 시스템 확인
2. 없으면 `create_design_system(...)` / 있으면 `update_design_system(...)`
3. `apply_design_system(projectId, designSystemId)`

## `/stitch export` — 내보내기

- `html`: `get_screen` → `web_fetch(downloadUrl.html)` → 파일 저장
- `image`: `get_screen` → `web_fetch(downloadUrl.screenshot)` → 파일 저장

## Execution

1. Activate the `stitch-automation` skill — it contains all MCP tool patterns, workflows, and safety patterns.
2. Execute the requested subcommand following the skill's workflow references.

## No Arguments

If called without arguments (`/stitch`), show the usage table above and ask what the user wants to do.

## Error Handling

- If MCP auth fails: prompt user to run `gcloud auth application-default login`
- If project/screen not found: show list and ask user to select
- If generation fails: retry up to 3 times, then report error
- If rate limit hit: inform user of Stitch limits and pause
