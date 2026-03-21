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
