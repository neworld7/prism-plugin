---
name: prism
description: "Google Stitch AI design tool orchestrator — analyze, design, pipeline"
---

# /prism Command

Google Stitch AI design tool orchestration command.

## Usage

| Subcommand | Usage | Action |
|------------|-------|--------|
| `analyze` | `/prism analyze [app]` | 코드 분석 → Feature별 프롬프트 → .prism/analysis.md + prompts.md 산출 |
| `preview` | `/prism preview` | 핵심 화면 4-5개 × 7개 Direction 시안 생성 (LIGHT 모드) → 사용자 선택 → DESIGN.md |
| `design` | `/prism design <feature\|all>` | 디자인 생성 + 검증 루프 |
| `pipeline` | `/prism pipeline [app]` | analyze → preview → design 전체 자동화 (원스텝) |

## `/prism analyze [app]`

코드와 실행 화면을 분석하여 Feature별 UX-First 프롬프트를 산출한다.

### 실행 절차

1. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows.md
   ```

2. **Phase A1-A6 실행**:
   - A1-A4: prism 자체 (코드 분석, Feature 분리, 원시 프롬프트)
   - A5: Skill("enhance-prompt") 호출 → 프롬프트 최적화
   - A6: `.prism/analysis.md` 작성 + `.prism/prompts.md` 작성

3. **사용자 확인 요청**

`app` 인자 예시: `/prism analyze readcodex`, `/prism analyze bookflip`
인자 없으면 현재 프로젝트 이름 사용.

## `/prism preview`

A4.5 Design Preview 단계를 실행한다. 핵심 화면 4-5개로 7가지 디자인 시안(모두 LIGHT 모드)을 생성하고 사용자가 선택한다.

### 실행 절차

1. `.prism/analysis.md` 존재 확인 (없으면 `/prism analyze` 먼저 실행 안내)
2. 핵심 화면 4-5개 선정 → 사용자 확인
3. 7개 Direction 시안 정의 (7가지 스펙트럼 각 1개)
4. Direction별 Stitch 프로젝트 생성 + 화면 4-5개 배치 생성
5. 약 35개 화면 스크린샷 비교 → 사용자 선택
6. 선택된 Direction의 designTheme → `./DESIGN.md` 저장

## `/prism design <feature|all>`

공식 Stitch 스킬을 호출하여 디자인을 생성하고 검증한다.

### 실행 절차

1. **상태 파일 초기화**: `.claude/prism-design-pipeline.local.md` 생성
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

2. **analysis.md 확인**: `.prism/analysis.md` 존재 필수. 없으면 `/prism analyze` 먼저 실행 안내.

3. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows.md
   ```

4. **Phase D1-D6 실행** (D2는 제거됨):
   - D1: analysis.md 로드 (prism)
   - D3: Design Identity 판단 + Skill("stitch-design") → 디자인 생성
   - D4-D6: 검증 루프 (Stop hook 자동)

`feature` 인자 예시: `/prism design library`, `/prism design all`
인자 없으면 analysis.md의 Feature 목록 표시 후 선택 요청.

## `/prism pipeline [app]`

analyze → preview → design을 원스텝으로 자동 실행한다.

### 실행 절차

1. `/prism analyze [app]` 실행
2. 분석 요약 표시 후 자동 진행 (간략 요약만 출력, 명시적 거부 없으면 진행)
3. `/prism preview` 실행
4. `/prism design all` 실행
5. 전체 Feature 순차 처리

## Execution

1. Activate the `prism` skill
2. Execute the requested subcommand following the skill's workflow references

## No Arguments

If called without arguments (`/prism`), show the usage table above and ask what the user wants to do.

## Error Handling

- **공식 스킬 미설치**: 자동 설치 시도 → 실패 시 안내
- **인증 실패**: STITCH_API_KEY → gcloud ADC → 안내
- **Rate limit**: 파이프라인 시작 시 크레딧 안내
- **analysis.md 미존재**: `/prism analyze` 먼저 실행 안내
