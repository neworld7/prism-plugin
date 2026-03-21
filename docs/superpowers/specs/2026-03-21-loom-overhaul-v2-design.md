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

loom은 Stitch MCP 도구를 직접 호출하지 않는다. 모든 MCP 상호작용은 공식 스킬이 담당한다.

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
| 2 | 산출물 자동 승인 (사용자 확인 스킵) |
| 3 | `/loom design all` 실행 |
| 4 | 전체 Feature 순차 처리 (Feature-by-Feature 루프) |

### All 모드: Feature-by-Feature 순차 처리

`/loom design all` 또는 `/loom pipeline` 실행 시 모든 Feature를 순차 처리:

1. Feature 1 디자인 생성 → 검증 루프 → `DESIGN_VERIFIED`
2. Stop hook이 다음 Feature로 상태 파일 전환
3. Feature 2 디자인 생성 → 검증 루프 → `DESIGN_VERIFIED`
4. 반복...
5. 마지막 Feature 완료 → 상태 파일 삭제 → allow

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

현재 로직 그대로 유지. 변경점 하나:
- 재시도 메시지에서 "Stitch MCP edit_screens로 수정" → "Skill(stitch-design)으로 수정"으로 지시문 변경

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
| `references/workflows-pipeline.md` | 통합 파이프라인 흐름 (analyze→enhance→design→verify) |

### 삭제할 파일

| 파일 | 이유 |
|---|---|
| `references/tools.md` | 공식 스킬이 MCP 호출 담당 |
| `references/prompting.md` | `enhance-prompt` 스킬이 대체 |
| `references/workflows-analyze.md` | `workflows-pipeline.md`로 통합 |
| `references/workflows-design.md` | `workflows-pipeline.md`로 통합 |

### 변경 없는 파일

| 파일 | 이유 |
|---|---|
| `.mcp.json` | 비어있음 |
| `hooks/hooks.json` | Stop hook 구조 동일 |
| `references/sheet-template.md` | loom 고유 산출물 포맷 |

## 현재 vs 개편 비교

| 항목 | 현재 (v0.8.0) | 개편 후 (v2.0.0) |
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
