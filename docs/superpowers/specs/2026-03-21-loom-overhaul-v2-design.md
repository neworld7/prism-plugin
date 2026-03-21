# Loom Plugin v2 — Orchestration Overhaul Design Spec

## Overview

loom 플러그인을 "포크 관리" 모델에서 "오케스트레이션" 모델로 전환한다. 공식 Stitch 스킬(`enhance-prompt`, `stitch-design`, `design-md`)은 별도 설치하여 공식대로 사용하고, loom은 코드 분석과 파이프라인 흐름 제어에 집중한다.

### 핵심 원칙

1. **공식 스킬 위임** — MCP 도구 호출, 프롬프트 최적화, 디자인 시스템 생성은 공식 스킬에 위임
2. **loom 고유 가치** — 코드 분석(analyze), 파이프라인 오케스트레이션(pipeline), 검증 루프(Stop hook)
3. **최소 references** — 공식 스킬이 담당하는 영역의 자체 문서 제거

## Architecture

### 오케스트레이션 모델

```
loom (오케스트레이터)
  ├── analyze: loom 자체 로직 (코드+시뮬레이터 분석, Feature 분리)
  ├── enhance: Skill("enhance-prompt") 호출 → 프롬프트 최적화
  ├── design-system: Skill("design-md") 호출 → DESIGN.md 생성
  ├── generate: Skill("stitch-design") 호출 → 디자인 생성
  └── verify: loom 자체 로직 (Stop hook 검증 루프)
```

### MCP 호출 경계

- **생성/수정 도구** (`generate_screen_from_text`, `edit_screens`, `generate_variants`) → 공식 스킬(`stitch-design`)을 경유하여 호출
- **읽기 전용 도구** (`get_screen`, `list_screens`, `get_project`, `list_projects`) → loom이 검증 루프에서 직접 호출 가능
- **`web_fetch`** → loom이 스크린샷/HTML 다운로드를 위해 직접 호출 가능

### Skill() 호출 동작 모델

`Skill("stitch-design")` 호출 시 해당 스킬의 SKILL.md가 에이전트 컨텍스트에 주입되고, 에이전트가 스킬의 지시에 따라 MCP 도구를 호출한다. 즉 MCP 호출 **방법**은 공식 스킬이 정의하고, loom은 **언제/무엇을** 호출할지만 결정한다. loom의 파이프라인 흐름과 공식 스킬의 실행이 하나의 에이전트 세션 안에서 이루어진다.

### Plugin Structure

```
loom-plugin/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .mcp.json                          # 비어있음 (Stitch MCP는 글로벌 설정)
├── commands/
│   └── loom.md                        # /loom 커맨드 (analyze, design, pipeline)
├── skills/
│   └── loom/
│       ├── SKILL.md                   # 트리거, 인증, 공식 스킬 체크, 핵심 패턴
│       └── references/
│           ├── workflows-pipeline.md  # 통합 오케스트레이션 흐름
│           └── sheet-template.md      # 분석/디자인 산출물 템플릿
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       └── design-verify-stop.sh      # 검증 루프 (현재와 동일)
└── docs/
```

## 기존 SKILL.md 패턴 처리

현재 SKILL.md의 6개 Critical Patterns에 대한 처리:

| 패턴 | 현재 내용 | v1.0.0 처리 |
|---|---|---|
| Pattern 1 (Screen Data Retrieval) | `get_screen` + `web_fetch` 패턴 | **유지** — 검증 루프에서 loom이 읽기 전용 MCP로 직접 사용 |
| Pattern 2 (Screenshot Discipline) | MCP 도구 우선, 스크린샷은 마일스톤에서만 | **유지** — 검증 루프에 여전히 적용 |
| Pattern 3 (Design System — DESIGN.md) | MCP 폴백 분기 로직 | **삭제** — `Skill("design-md")`가 전담. MCP 도구 복구 여부와 무관하게 항상 공식 스킬 사용 |
| Pattern 4 (Error Recovery) | MCP 재시도/인증 안내 | **삭제** — 공식 스킬이 에러 처리 담당. 인증 체크만 loom에 유지 |
| Pattern 5 (크레딧 관리) | 일일 400 크레딧 체계 | **유지** — 파이프라인 시작 시 화면 수 안내는 loom이 담당 |
| Pattern 6 (Stitch 웹 탐색) | chrome-viewer CDP 패턴 | **유지** — analyze 파이프라인에서 시뮬레이터 조작 시 사용 |

## 공식 스킬 의존성

### 필수 스킬 3개

| 스킬 | 설치 명령 | 파이프라인 단계 |
|---|---|---|
| `enhance-prompt` | `npx skills add google-labs-code/stitch-skills --skill enhance-prompt --global` | analyze 후 프롬프트 최적화 |
| `stitch-design` | `npx skills add google-labs-code/stitch-skills --skill stitch-design --global` | 디자인 생성 |
| `design-md` | `npx skills add google-labs-code/stitch-skills --skill design-md --global` | 디자인 시스템 생성 |

### 체크 및 설치 흐름

SKILL.md 활성화 시:

1. 공식 스킬 존재 확인: Skill("enhance-prompt") 호출 가능한지 체크
2. 없으면 자동 설치 시도:
   ```bash
   npx skills add google-labs-code/stitch-skills --skill enhance-prompt --global
   npx skills add google-labs-code/stitch-skills --skill stitch-design --global
   npx skills add google-labs-code/stitch-skills --skill design-md --global
   ```
3. 설치 실패 시 사용자 안내:
   > "공식 Stitch 스킬을 설치해주세요: `npx skills add google-labs-code/stitch-skills --global`"

### Stitch MCP 인증 체크

우선순위순:

1. `STITCH_API_KEY` 환경변수 확인
2. `gcloud auth application-default print-access-token` 확인
3. 둘 다 없으면 사용자에게 택 1 안내

## Command System

### /loom 서브커맨드

| 커맨드 | 용도 | 실행 주체 |
|---|---|---|
| `/loom analyze [app]` | 코드+시뮬레이터 분석 → Feature별 프롬프트 산출 | loom 자체 |
| `/loom design <feature\|all>` | 디자인 생성 + 검증 루프 | 공식 스킬 호출 |
| `/loom pipeline [app]` | analyze → design 전체 자동화 | 오케스트레이션 |

인자 없이 `/loom` 실행 시 사용법 테이블을 표시하고 선택을 요청한다.

## Pipeline Flows

### `/loom analyze [app]` — loom 고유 로직

| Phase | 내용 | 실행 주체 |
|-------|------|-----------|
| 1 | 코드 분석 — Glob/Grep으로 화면·인터랙션·상태 추출 | loom |
| 2 | 시뮬레이터 스크린샷 캡처 + 시각 분석 | loom |
| 3 | Feature 분리 — 코드+시각 분석 종합 | loom |
| 4 | Feature별 원시 프롬프트 작성 | loom |
| 5 | 프롬프트 최적화 — Skill("enhance-prompt") 호출 | 공식 스킬 |
| 6 | 산출물 작성: `.loom/{date}-{app}-analysis.md` | loom |
| 7 | 사용자 확인 요청 | loom |

### `/loom design <feature|all>` — 공식 스킬 위임

| Phase | 내용 | 실행 주체 |
|-------|------|-----------|
| 1 | `.loom/*-analysis.md` 로드 (없으면 analyze 먼저 안내) | loom |
| 2 | 디자인 시스템 생성 — Skill("design-md") 호출 | 공식 스킬 |
| 3 | 디자인 생성 — Skill("stitch-design") 호출 (Feature 프롬프트 전달) | 공식 스킬 |
| 4 | 상태 파일 `phase`를 `verify`로 변경 | loom |
| 5 | 검증 루프 — 생성된 디자인 ↔ 프롬프트 크로스체크 | loom (Stop hook) |
| 6 | gaps > 0 → Skill("stitch-design")으로 수정 | 공식 스킬 |
| 7 | gaps == 0 → `<promise>DESIGN_VERIFIED</promise>` | loom |

### `/loom pipeline [app]` — 원스텝 자동화

| Phase | 내용 |
|-------|------|
| 1 | `/loom analyze [app]` 실행 |
| 2 | 분석 요약 표시 후 자동 진행 (간략 요약만 출력, 명시적 거부 없으면 진행) |
| 3 | `/loom design all` 실행 |
| 4 | 전체 Feature 순차 처리 (Feature-by-Feature 루프) |

### All 모드: Feature-by-Feature 순차 처리

`/loom design all` 또는 `/loom pipeline` 실행 시 모든 Feature를 순차 처리:

1. Feature 1 디자인 생성 → 검증 루프 → `DESIGN_VERIFIED`
2. Stop hook이 다음 Feature로 상태 파일 전환
3. Feature 2 디자인 생성 → 검증 루프 → `DESIGN_VERIFIED`
4. 반복...
5. 마지막 Feature 완료 → 상태 파일 삭제 → allow

## workflows-pipeline.md 구성

기존 `workflows-analyze.md`와 `workflows-design.md`를 공식 스킬 위임에 맞게 재구성하여 하나의 파일로 통합한다.

### Phase 구성

| Phase | 내용 | 출처 | 실행 주체 |
|-------|------|------|-----------|
| A1. 코드 분석 | Glob/Grep으로 화면·인터랙션·상태 추출 | analyze 유지 | loom |
| A2. 시뮬레이터 분석 | idb/chrome-viewer로 스크린샷 캡처+분석 | analyze 유지 | loom |
| A3. Feature 분리 | 코드+시각 분석 종합하여 Feature 단위 분류 | analyze 유지 | loom |
| A4. 원시 프롬프트 작성 | Feature별 UX-First 프롬프트 초안 | analyze 유지 (Vibe Design 원칙 적용) | loom |
| A5. 프롬프트 최적화 | Skill("enhance-prompt") 호출 | **신규** (기존 자체 prompting.md 대체) | 공식 스킬 |
| A6. 산출물 작성 | `.loom/{date}-{app}-analysis.md` | analyze 유지 | loom |
| D1. analysis.md 로드 | Feature 프롬프트 로드 | design 유지 | loom |
| D2. 디자인 시스템 | Skill("design-md") 호출 | **신규** (기존 MCP 폴백 대체) | 공식 스킬 |
| D3. 디자인 생성 | Skill("stitch-design") 호출 | **신규** (기존 MCP 직접 호출 대체) | 공식 스킬 |
| D4. 검증 | `get_screen` + `web_fetch`로 스크린샷 비교, gaps 카운트 | design 유지 | loom |
| D5. 수정 | gaps > 0 → Skill("stitch-design")으로 수정 | design 변경 (MCP→스킬) | 공식 스킬 |
| D6. 완료 | `<promise>DESIGN_VERIFIED</promise>` | design 유지 | loom |

### 기존 파일에서 삭제되는 내용

- `workflows-analyze.md`의 프롬프트 예시 중 hex 코드/px 값 포함 예시 → UX-First Vibe Design 원칙에 맞게 수정
- `workflows-design.md`의 MCP 직접 호출 절차 (Phase 4 `generate_screen_from_text` 호출 상세) → Skill 위임으로 대체
- `workflows-design.md`의 배치 분할 기준/크레딧 효과 → 공식 스킬이 관리

### 기존 파일에서 유지되는 내용

- `workflows-analyze.md`의 Phase 1-3 전체 (코드 분석, 시뮬레이터, Feature 분리)
- `workflows-analyze.md`의 Phase 4 프롬프트 작성 원칙 (Vibe Design, 금지 사항)
- `workflows-design.md`의 검증 로직 (Phase 5 gaps 카운트, Phase 6 수정 판단)
- `workflows-design.md`의 Feature Routing (all 모드 전용)
- `sheet-template.md`의 Analysis Sheet Template (유지), Design Sheet Template (삭제 — 공식 스킬이 대체)

## State Management

### 상태 파일: `.claude/loom-design-pipeline.local.md`

```yaml
---
phase: verify
feature: library
session_id: {unique-id}
iteration: 2
max_iterations: 5
all_features: auth|home|library|profile
current_index: 2
completed_features: auth|home
---
```

라이프사이클:
1. `/loom design` 시작 시 생성
2. 파이프라인 진행에 따라 `phase`, `iteration` 업데이트
3. 모든 Feature 검증 완료 시 삭제

### Stop Hook: `design-verify-stop.sh`

현재 로직 그대로 유지. 변경점:
- **재시도 메시지** (122번줄): "Stitch MCP edit_screens로 수정" → "Skill(stitch-design)으로 수정"
- **Feature 전환 메시지** (98번줄): "Stitch MCP로 디자인 생성 (Phase 4)" → "Skill(stitch-design)으로 디자인 생성"
- **참조 경로**: `references/workflows-design.md` → `references/workflows-pipeline.md`

## File Changes

### 수정할 파일

| 파일 | 변경 내용 |
|---|---|
| `skills/loom/SKILL.md` | 전면 재작성 — 공식 스킬 체크/설치, 오케스트레이션 패턴, MCP 직접 호출 제거 |
| `commands/loom.md` | `/loom pipeline` 서브커맨드 추가, 공식 스킬 위임 방식으로 변경 |
| `hooks/scripts/design-verify-stop.sh` | 재시도 메시지만 수정 |
| `.claude-plugin/plugin.json` | version 범프, description 업데이트 |
| `.claude-plugin/marketplace.json` | version 범프, description 업데이트 |

### 생성할 파일

| 파일 | 내용 |
|---|---|
| `skills/loom/references/workflows-pipeline.md` | 통합 파이프라인 흐름 (analyze→enhance→design→verify) |

### 삭제할 파일

| 파일 | 이유 |
|---|---|
| `skills/loom/references/tools.md` | 공식 스킬이 MCP 호출 담당 |
| `skills/loom/references/prompting.md` | `enhance-prompt` 스킬이 대체 |
| `skills/loom/references/workflows-analyze.md` | `workflows-pipeline.md`로 통합 |
| `skills/loom/references/workflows-design.md` | `workflows-pipeline.md`로 통합 |

### 변경 없는 파일

| 파일 | 이유 |
|---|---|
| `.mcp.json` | 비어있음 |
| `hooks/hooks.json` | Stop hook 구조 동일 |
| `skills/loom/references/sheet-template.md` | loom 고유 산출물 포맷 (Design Sheet Template 삭제, Analysis Sheet Template 유지) |

### 버전 번호

v0.8.0 → v1.0.0. 포크 모델에서 오케스트레이션 모델로의 아키텍처 전환이므로 1.0.0 메이저 릴리스.

## 현재 vs 개편 비교

| 항목 | 현재 (v0.8.0) | 개편 후 (v1.0.0) |
|---|---|---|
| MCP 호출 | loom이 직접 (tools.md 참조) | 공식 스킬이 담당 |
| 프롬프트 최적화 | loom 자체 (prompting.md) | Skill("enhance-prompt") |
| 디자인 시스템 | loom 자체 DESIGN.md 생성 | Skill("design-md") |
| 디자인 생성 | loom이 MCP 직접 호출 | Skill("stitch-design") |
| references 파일 수 | 5개 | 2개 |
| 공식 스킬 의존성 | 없음 | 3개 필수 |
| 커맨드 | analyze, design | analyze, design, pipeline |
| 코드 분석 | loom 고유 | loom 고유 (변경 없음) |
| 검증 루프 | Stop hook | Stop hook (변경 없음) |
