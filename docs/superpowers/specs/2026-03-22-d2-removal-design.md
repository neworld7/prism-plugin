# D2 제거 + Design System Name Anchor 설계

**Date:** 2026-03-22
**Status:** Implemented
**Scope:** prism-plugin D2 단계 제거, Stitch 네이티브 디자인 시스템 일관성 활용

## 배경

### 발견된 사실

1. Stitch는 첫 화면 생성 시 자체적으로 디자인 시스템을 생성하고 이름을 부여한다 (예: "Bibliophile's Quietude", "The Midnight Archive (Literary Noir)")
2. 이후 프롬프트에서 해당 이름을 참조하면 Stitch가 동일한 색상/타이포/분위기를 자동 유지한다
3. `get_project` API의 `designTheme.designMd` 필드에 Stitch가 생성한 완전한 디자인 시스템 문서가 이미 존재한다
4. `designTheme`에 `namedColors` (40+ 시맨틱 토큰), `font`, `headlineFont`, `labelFont`, `roundness`, `spacingScale` 등 구조화된 토큰도 포함됨

### 문제

현재 D2 단계는 `design-md` 스킬을 호출하여 외부에서 DESIGN.md를 생성하는 "Push" 모델이다. 그러나 Stitch 자체가 D3에서 디자인 시스템을 이미 생성하므로 중복 작업이 발생하고, 크레딧과 시간이 낭비된다.

## 설계

### 변경 원칙

**"Stitch가 만든 디자인 시스템을 추출하여 재활용한다"** (Pull 모델)

### 1. 제거 대상

- D2 단계 전체 (`design-md` 스킬 호출)
- `./DESIGN.md` 파일 스와핑 메커니즘
- `.prism/directions/{name}/DESIGN.md` 백업/복원 로직
- SKILL.md의 D2 관련 설명, DESIGN.md 스와핑 섹션

### 2. 추가 대상

- D3 내부 "디자인 시스템 이름 추출" 단계
- `.prism/directions/{name}/design-identity.md` 경량 파일
- 이후 프롬프트에 이름 앵커 삽입 로직

### 3. 새로운 D3 흐름

**현재:**
```
D2: design-md 스킬 호출 → ./DESIGN.md 생성 → 백업
D3: create_project → generate_screen_from_text (순차)
```

**변경 후:**
```
D3: create_project
  → 첫 화면 generate_screen_from_text
  → get_project → designTheme에서 디자인 시스템 이름 + 핵심 메타데이터 추출
  → design-identity.md 저장 (첫 Feature + 첫 Direction일 때만)
  → 나머지 화면 generate_screen_from_text (프롬프트에 이름 앵커 삽입)
```

### 4. 디자인 시스템 이름 추출 로직

소스 2개 (우선순위 순):

1. **`outputComponents` 텍스트** — `generate_screen_from_text` 응답에서 추출
   - 패턴: `"the '{NAME}' design system"`, `"'{NAME}' aesthetic"`, `"'{NAME}' palette"` 등
   - 예: `"Bibliophile's Quietude"`, `"The Midnight Archive (Literary Noir)"`
   - 참고: "no output" 응답 시 이 소스 사용 불가

2. **`designTheme.designMd` 헤딩** — `get_project` 응답에서 추출
   - 첫 번째 `#` 헤딩의 제목 파싱
   - 예: `"# Design System Specification: The Midnight Archive (Literary Noir)"` → `"The Midnight Archive (Literary Noir)"`
   - 첫 화면 생성 후 `get_project` 호출로 항상 접근 가능 (더 안정적)

**Fallback 전략:**
- 소스 1 실패 (no output) → 기존 폴링으로 화면 생성 확인 후 `get_project`로 소스 2 시도
- 소스 2도 `designMd` 미생성 → 2번째 화면 생성 후 `get_project` 재시도
- 2회 시도 후에도 이름 미확보 → 이름 앵커 없이 진행 (Stitch 프로젝트 내부 일관성에 의존)

### 5. design-identity.md 포맷

```markdown
# Design Identity

| 항목 | 값 |
|------|------|
| Name | The Midnight Archive (Literary Noir) |
| Source Project | projects/18240846796420145622 |
| Color Mode | DARK |
| Roundness | ROUND_FOUR |
| Primary Font | NOTO_SERIF |
| Body Font | MANROPE |

## Anchor Phrase

> following the "The Midnight Archive (Literary Noir)" design system
```

**경량 저장 사유:** Stitch가 프로젝트 내에서 전체 디자인 토큰(40+ namedColors, spacingScale 등)을 이미 관리하므로 외부 복제 불필요. 앵커 이름 + 핵심 메타데이터만으로 이후 프롬프트에서 동일 시스템을 참조할 수 있다.

### 6. 프롬프트 앵커 삽입 방식

**같은 프로젝트 내 (첫 화면 이후):**
```
Continue using the "{Name}" design system established in this project.
```

**같은 Direction의 다른 Feature 프로젝트:**
```
Use the same "{Name}" design system — {Color Mode} mode, {Primary Font} typography, {Roundness} corners.
```

### 7. 판단 기준 변경

**현재:**
```
판단 기준: .prism/directions/{direction}/DESIGN.md 존재 여부
  미존재 → design-md 스킬 호출
  존재 → 복원
```

**변경 후:**
```
판단 기준: .prism/directions/{direction}/design-identity.md 존재 여부
  미존재 (첫 Feature, 새 Direction) → D3 첫 화면 생성 후 추출 → 저장
  존재 (이후 Feature, 같은 Direction) → Read → 앵커 문구를 프롬프트에 삽입
```

### 8. 이중 루프 변경

```
Feature 1:
  Direction A → D3(첫 화면 → 이름 추출 → identity 저장 → 나머지) → D4-D6 → VERIFIED
  Direction B → D3(첫 화면 → 이름 추출 → identity 저장 → 나머지) → D4-D6 → VERIFIED
Feature 2:
  Direction A → identity Read → D3(앵커 포함 프롬프트로 전체 생성) → D4-D6 → VERIFIED
  Direction B → identity Read → D3(앵커 포함 프롬프트로 전체 생성) → D4-D6 → VERIFIED
```

핵심: 같은 Direction의 이후 Feature에서는 design-identity.md의 앵커 문구만 읽어서 프롬프트에 삽입. 파일 복사/스와핑 없음.

### 9. A5 (enhance-prompt) 변경

**현재:**
```
단일 모드: enhance-prompt 스킬이 .stitch/DESIGN.md 또는 .prism/directions/{direction}/DESIGN.md를 자동 Read
멀티 모드: DESIGN.md 경로를 명시적으로 전달 — ".prism/directions/{direction-name}/DESIGN.md"
```

**변경 후:**
```
단일/멀티 모드 공통:
- enhance-prompt 스킬에 DESIGN.md 경로 전달 안 함
- Direction Context 블록은 그대로 유지 (아키타입/레이아웃/레퍼런스)
- 디자인 토큰(hex, 폰트명)은 프롬프트에 넣지 않음 — Stitch가 자체 결정
- 디자인 시스템 이름 앵커는 D3 단계에서 삽입 (A5 시점에는 아직 이름 미확정)
```

**enhance-prompt의 DESIGN.md 자동 Read 대응:**
enhance-prompt 스킬이 독자적으로 `./DESIGN.md`나 `.stitch/DESIGN.md`를 찾으려 시도할 수 있다. 파일이 없으면 graceful하게 건너뛰는지 확인 필요. 에러가 발생하면 빈 `./DESIGN.md` 파일을 남겨두는 것을 고려.

**A4 원시 프롬프트 규칙 업데이트:**
기존 "어떻게 보일지는 A5+D2에서 처리" → "어떻게 보일지는 Stitch가 자체 결정 (D3에서 디자인 시스템 자동 생성)"로 변경.

### 10. 파일 구조 변경

**현재:**
```
.prism/
  analysis.md
  directions/
    default/
      prompts.md, DESIGN.md, project-ids.md
    {direction-name}/
      prompts.md, DESIGN.md, project-ids.md
./DESIGN.md              ← 활성 복제본
```

**변경 후:**
```
.prism/
  analysis.md
  directions/
    default/
      prompts.md, design-identity.md, project-ids.md
    {direction-name}/
      prompts.md, design-identity.md, project-ids.md
```

- `./DESIGN.md` 루트 파일 제거 (스와핑 불필요)
- `DESIGN.md` → `design-identity.md`로 대체 (경량, 10줄 미만)

### 11. Phase 번호

D2 제거 후 기존 Phase 번호(D3-D6)를 유지한다. 기존 문서 참조, Stop hook 메시지, 사용자 학습 비용을 고려하여 리넘버링하지 않는다. D1 → D3 → D4 → D5 → D6 순서로 진행.

### 12. 마이그레이션

기존에 `.prism/directions/{name}/DESIGN.md`가 존재하는 프로젝트: `rm -rf .prism/` 후 `/prism analyze`부터 재실행. design-identity.md는 다음 `/prism design` 실행 시 D3에서 자동 생성된다.

## 수정 대상 파일

| 파일 | 변경 내용 |
|------|-----------|
| `skills/prism/references/workflows.md` | D2 섹션 제거, D3에 이름 추출 단계 추가, 이중 루프 업데이트, A5 DESIGN.md 참조 제거, A4 "A5+D2" 참조 업데이트 |
| `skills/prism/SKILL.md` | D2 관련 설명 제거, design-identity.md 설명 추가, 파일 구조 업데이트, DESIGN.md 스와핑 섹션 제거, Prerequisites에서 `design-md` 스킬 설치 커맨드 제거 |
| `commands/prism.md` | D2 스킬 호출 설명 제거, D3 변경 반영 |
| `hooks/scripts/design-verify-stop.sh` | 89번 줄 Direction 전환 reason: "DESIGN.md 복원 또는 D2 실행" → "design-identity.md Read → 앵커 삽입 후 D3 실행"으로 변경 |

## 영향도

- **크레딧 절약**: Direction당 1회의 design-md 스킬 호출 제거
- **파이프라인 단순화**: D2 단계 제거, 파일 스와핑 제거
- **의존성 감소**: `design-md` 스킬 설치 불필요 (Prerequisites에서 제거)

## 리스크

1. **첫 화면 품질 의존**: 첫 화면의 디자인 품질에 전체 Direction이 좌우됨 (기존에도 동일)
2. **크로스 프로젝트 일관성**: 같은 Direction의 다른 Feature 프로젝트에서 이름 앵커만으로 Stitch가 정확히 동일한 디자인 시스템을 재현하는지 검증 필요. 실험 결과(ReadCodex 5개 Feature 연속 생성)에서는 이름 앵커로 충분했으나, 복잡한 디자인 시스템에서는 보완이 필요할 수 있음
3. **보완 전략** (일관성 부족 시): `designTheme.designMd` 전문을 첫 화면 프롬프트에 삽입하거나, `create_project` 시 theme 설정 파라미터를 활용하는 방식으로 단계적 강화 가능
