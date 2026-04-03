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
| `preview` | `/prism preview` | 핵심 화면 10개 × 7개 Direction 시안 생성 (LIGHT 모드) → 사용자 선택 → DESIGN.md |
| `design` | `/prism design <feature\|all>` | 디자인 생성 + 검증 루프 |
| `design resume` | `/prism design resume` | 크레딧 소진 등으로 중단된 design all 이어하기 |
| `pipeline` | `/prism pipeline [app]` | analyze → preview → design 전체 자동화 (원스텝) |
| `recolor` | `/prism recolor [from <source>]` | DESIGN.md 색상만 변경 (시안 참조 / 파일 참조 / 직접 입력) |

## `/prism analyze [app]`

코드와 실행 화면을 분석하여 Feature별 UX-First 프롬프트를 산출한다.

### 실행 절차

1. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/analyze-pipeline.md
   ```

2. **Phase A1-A12 실행**:
   - A1-A9: prism 자체 (코드 분석, Feature 분리, 원시 프롬프트)
   - A11: Skill("enhance-prompt") 호출 → 프롬프트 최적화
   - A12: `.prism/analysis.md` 작성 + `.prism/prompts.md` 작성

3. **사용자 확인 요청**

`app` 인자 예시: `/prism analyze readcodex`, `/prism analyze bookflip`
인자 없으면 현재 프로젝트 이름 사용.

## `/prism preview`

사용자 취향 인터뷰 → 레퍼런스 분석 → 1화면 검증 Gate → 3화면 확장으로 디자인을 확정한다 (LIGHT 모드).

### 실행 절차

1. `.prism/analysis.md` 존재 확인 (없으면 `/prism analyze` 먼저 실행 안내)
2. **사용자 취향 인터뷰** (필수): 좋아하는 앱/사이트 URL, 싫은 스타일, 감성 키워드
3. **레퍼런스 심층 분석**: 웹사이트=WebFetch, 모바일 앱=Refero MCP (실제 앱 스크린샷 분석)
4. **3개 Direction 정의** (레퍼런스 기반 변형): A 충실형 / B 도메인 특화 / C 차별화
5. **핵심 화면 3개 선정** (홈 + 상세 + 인터랙션) → 사용자 확인
6. **1화면 검증 Gate**: Direction A의 1화면만 먼저 생성 → 사용자 확인 필수
7. Gate 통과 → 나머지 2화면 확장 → DESIGN.md 확정 → `./DESIGN.md`로 복사

### 서브커맨드

| Usage | Action |
|-------|--------|
| `/prism preview` | 취향 인터뷰 → 레퍼런스 분석 → 3 Direction → 1화면 Gate → 확정 |
| `/prism preview add` | 새 시안 추가 (텍스트 / URL / 이미지 기반) |
| `/prism preview list` | 저장된 시안 목록 + 현재 활성 표시 |
| `/prism preview use <name>` | 저장된 시안을 `./DESIGN.md`로 활성화 |
| `/prism preview remove <name>` | 저장된 시안 삭제 |

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
   Read: references/analyze-pipeline.md
   ```

4. **Phase D1-D6 실행** (D2는 제거됨):
   - D1: analysis.md 로드 (prism)
   - D3: Design Identity 판단 + Skill("stitch-design") → 디자인 생성
   - D4-D6: 검증 루프 (Stop hook 자동)

`feature` 인자 예시: `/prism design library`, `/prism design all`
인자 없으면 analysis.md의 Feature 목록 표시 후 선택 요청.

### 크레딧 소진 시 이어하기

```bash
# 크레딧 소진으로 중단됨 (시안: Warm Organic, Feature 3에서 멈춤)

# 방법 1: 계정 전환 후 이어하기
/prism account neworld         # 다른 계정으로 전환 → 세션 재시작
/prism design resume            # Feature 3부터 이어서 생성

# 방법 2: 다른 시안으로 전환 작업
/prism preview use editorial-elegance   # 시안 전환 (Warm Organic 상태 자동 백업)
/prism design all                        # Editorial Elegance로 새로 시작

# 방법 3: 다시 Warm Organic으로 돌아와서 이어하기
/prism preview use warm-organic          # 시안 전환 (상태 자동 복원)
/prism design resume                     # Feature 3부터 이어서 생성
```

시안별 진행 상황은 `.claude/prism-pipelines/{시안이름}.local.md`에 독립 보존된다.

## `/prism pipeline [app]`

analyze → preview → design을 원스텝으로 자동 실행한다.

### 실행 절차

1. `/prism analyze [app]` 실행
2. 분석 요약 표시 후 자동 진행 (간략 요약만 출력, 명시적 거부 없으면 진행)
3. `/prism preview` 실행
4. `/prism design all` 실행
5. 전체 Feature 순차 처리

## `/prism recolor`

DESIGN.md의 색상 팔레트만 변경한다. 폰트, roundness, designMd 규칙 등은 유지. 3가지 입력 방식을 지원한다.

### 사용법

| 방식 | 사용법 | 설명 |
|------|--------|------|
| 시안 참조 | `/prism recolor from <시안이름>` | 저장된 시안의 색상을 가져옴 |
| 파일 참조 | `/prism recolor from <DESIGN.md 경로>` | 지정한 DESIGN.md에서 색상 추출 |
| 직접 입력 | `/prism recolor` | hex 코드 직접 입력 |

**예시:**
```bash
# 저장된 시안에서 색상 가져오기
/prism recolor from japanese-zen
/prism recolor from earthy-natural

# 특정 DESIGN.md 파일에서 색상 참조
/prism recolor from .prism/preview/playful-pastel/DESIGN.md

# 인자 없이 실행 → hex 직접 입력
/prism recolor
```

### 실행 절차

1. **현재 DESIGN.md 읽기**: `./DESIGN.md` 존재 필수. 없으면 안내.

2. **색상 소스 결정** (인자에 따라 분기):

   **`from <시안이름>` — 저장된 시안에서 가져오기:**
   ```
   1. .prism/preview/<시안이름>/DESIGN.md 읽기
   2. 해당 파일에서 4개 seed 색상 추출:
      - overridePrimaryColor, overrideSecondaryColor
      - overrideTertiaryColor, overrideNeutralColor
   3. 추출된 색상을 사용자에게 표시 후 확인
   ```

   **`from <파일경로>` — 지정 파일에서 가져오기:**
   ```
   1. 지정된 DESIGN.md 파일 읽기
   2. Design Identity 테이블 또는 Named Colors에서 4색 추출
   3. 테이블에 없으면 overrideXxxColor 패턴으로 grep
   4. 추출된 색상을 사용자에게 표시 후 확인
   ```

   **인자 없음 — 직접 입력:**
   ```
   1. 현재 4색 표시
   2. AskUserQuestion으로 새 색상 입력 받기
      - 4개 중 바꾸고 싶은 것만 입력 (나머지 유지)
      - hex 코드 또는 색상 이름 (AI가 hex 변환)
   ```

3. **변경 전후 색상 비교 표시**:
   ```
   색상 변경 미리보기:
                   현재                    →  새 색상
   Primary:   #041627 (Navy)           →  #2D4B37 (Forest Green)
   Secondary: #775a19 (Gold)           →  #C36A4B (Terracotta)
   Tertiary:  #e9c176 (Gold Light)     →  #D9B99B (Sand)
   Neutral:   #fbf9f5 (Cream)          →  #F4F1EA (Linen)

   적용하시겠습니까?
   ```

4. **Stitch 프로젝트 디자인 시스템 업데이트**:
   - `.prism/project-ids.md`에서 모든 Feature 프로젝트 ID 로드
   - 각 프로젝트에 대해:
     a. `list_design_systems(projectId)` → asset ID 확인
     b. `update_design_system` 호출:
        - `overridePrimaryColor`, `overrideSecondaryColor`, `overrideTertiaryColor`, `overrideNeutralColor` 변경
        - `displayName`, `headlineFont`, `bodyFont`, `labelFont`, `roundness`, `colorMode`, `colorVariant` 유지
        - `designMd` 유지 (색상 참조는 5단계에서 치환)
     c. `get_project` → 새로운 `designTheme.namedColors` + `designMd` 가져오기
     d. `apply_design_system(projectId, screenInstances, assetId)` → 모든 화면에 일괄 적용

5. **DESIGN.md 업데이트**:
   - Design Identity 테이블의 색상 값 업데이트
   - Named Colors 토큰 맵을 Stitch가 생성한 새 토큰으로 교체
   - Design System Spec을 Stitch가 생성한 새 designMd로 교체
     (Stitch가 새 색상에 맞게 designMd 내 hex 참조를 자동 재생성)

6. **.prism/preview/{현재 활성 시안}/DESIGN.md도 동기화**

7. **결과 확인**: 변경된 색상 + 영향받은 프로젝트 수 + Stitch 링크

### 색상만 변경, 나머지 유지

**변경되는 것:**
- 4개 seed 색상 (`overridePrimaryColor`, `overrideSecondaryColor`, `overrideTertiaryColor`, `overrideNeutralColor`)
- `namedColors` 전체 (~55개 토큰, Stitch가 새 seed에서 자동 재생성)
- `designMd` 내 색상 참조 (Stitch가 새 designMd를 자동 생성)

**유지되는 것:**
- `displayName` (디자인 시스템 이름)
- `headlineFont`, `bodyFont`, `labelFont` (서체)
- `roundness` (모서리)
- `colorMode` (Light/Dark)
- `colorVariant` (Fidelity 등)
- `spacingScale`
- 디자인 규칙의 구조 (No-Line Rule, Ghost Border, Ink Mist 등 — Stitch가 새 색상에 맞게 재작성)

### 주의사항

- recolor 후 기존 화면에 `apply_design_system`으로 새 색상이 일괄 적용됨
- 크레딧 소비: `update_design_system`은 무료, `apply_design_system`은 화면당 크레딧 소비 가능
- 아직 생성되지 않은 Feature의 화면에는 영향 없음 (다음 `design` 실행 시 새 DESIGN.md 참조)
- `from` 참조 시 원본 시안의 DESIGN.md는 변경되지 않음 (색상만 복사)

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
