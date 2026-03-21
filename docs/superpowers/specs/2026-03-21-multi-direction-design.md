# Multi-Direction Design — Design Spec

## Overview

loom 플러그인에 `--directions N` 옵션을 추가하여, 동일한 analysis에서 N개의 디자인 방향(Direction)을 별도 Stitch 프로젝트로 생성한다. 각 프로젝트는 전체 화면 생성 + 검증 루프까지 완주한다.

### 핵심 원칙

1. **하위 호환** — `--directions 1`(기본값)일 때 기존 v1.0.0 흐름과 100% 동일
2. **3축 기반 Direction** — 아키타입, 레이아웃, 레퍼런스 앱 3개 축의 조합으로 근본적으로 다른 디자인 생성
3. **전체 생성 + 전체 검증** — N개 프로젝트 모두 전체 화면 생성 및 검증 루프 완주

## Command Interface

### `--directions` 옵션

```
/loom design library                     → --directions 1 (기본, 현재와 동일)
/loom design library --directions 3      → 3개 Direction으로 멀티
/loom design all --directions 2          → 모든 Feature × 2방향
/loom pipeline readcodex --directions 3  → 분석 → 3방향 → 모두 검증
```

- 범위: 1-5
- 기본값: 1
- `--directions 1`이면 Direction 생성/선택 단계(A4.5)를 스킵
- **파싱**: loom은 마크다운 기반 커맨드이므로 `--directions N`은 자연어에서 추출. SKILL.md/loom.md의 커맨드 설명에서 에이전트가 인자를 인식하여 파이프라인 분기에 사용.

## Pipeline Flow

### 단일 모드 (--directions 1, 기존 동작)

```
A1-A4 → A5 → A6 → D1-D2 → D3 → D4-D6 → VERIFIED
```

### 멀티 모드 (--directions N, N >= 2)

```
A1-A4 → [A4.5: Direction 생성] → A5 × N → A6
→ D1-D2 → D3 × N → D4-D6 × N (순차) → 모두 VERIFIED
```

## Phase A4.5: Direction 생성

`--directions N`이 2 이상일 때 활성화. A4 원시 프롬프트 완성 후 실행.

### 입력

- 앱 컨텍스트 (카테고리, 타겟 사용자, 기존 디자인 상태)
- A4 원시 프롬프트 (기능적 요구사항)

### 3축 프레임워크

| 축 | 역할 | 예시 값 |
|---|---|---|
| **아키타입** | 전체 디자인 언어 결정 | Editorial Elegance, Flat Modern, Glassmorphism, Dark Minimalism, Playful Pastel, Japanese Zen, Warm Organic |
| **레이아웃** | 화면 구조/배치 패턴 | Centered Stack, Split Screen, Bottom Sheet, Full-bleed Hero, Card-based, Centered Narrow |
| **레퍼런스 앱** | AI가 참조할 구체적 디자인 DNA | Notion, Linear, Stripe, Duolingo, Airbnb, 밀리의서재, Spotify |

나머지 축(정보 밀도, 타이포, 색상, 인터랙션)은 아키타입에서 자연스럽게 파생. enhance-prompt 스킬이 증폭.

### 출력 형식

각 Direction에 대해 상세 설명을 제공하여 사용자의 선택을 돕는다:

```
📐 Direction A: "{Direction 이름}"
  아키타입: {아키타입} — {핵심 특성 1줄}
  레이아웃: {레이아웃} — {구조 설명 1줄}
  레퍼런스: {레퍼런스 앱} — {해당 앱의 어떤 측면을 참조하는지}

  {이 방향이 앱에 적합한 이유 2-3줄. 타겟 사용자, 감성,
   경쟁 차별화 관점에서 설명. 사용자가 이 방향을 선택하면
   어떤 경험이 만들어지는지 구체적으로 서술.}
```

### 사용자 응답 처리

- "네" / "좋습니다" → N개 Direction 확정, A5로 진행
- "B를 X로 바꿔주세요" → Direction B 교체 후 재표시
- "하나 더 추가" → Direction 추가 (최대 5개)
- "A, C만 하겠습니다" → 선택된 Direction만 진행

## Phase A5 × N: enhance-prompt 분기

Direction이 확정되면 **원시 프롬프트 + Direction Context**를 조합하여 enhance-prompt를 N번 호출한다.

### Direction Context 삽입 방식

enhance-prompt 스킬은 별도 "direction" 파라미터를 받지 않으므로, 프롬프트 텍스트에 Direction Context 블록을 직접 삽입한다.

```
원시 프롬프트 (A4, 공통):
  "A login screen for 'ReadCodex' reading tracker app.
   Centered app branding with tagline.
   Clean email and password form.
   Social login options (Google, Apple).
   Forgot password and sign up links.
   All UI text must be in Korean."

          ↓ Direction Context 삽입 ↓

Direction A용 (enhance-prompt 호출 1):
  "A login screen for 'ReadCodex' reading tracker app.

   **Direction: Cozy Reading Nook**
   - Archetype: Warm Organic — natural textures, paper-like, serif typography
   - Layout: Centered Generous — ample margins, vertical stack
   - Reference: Inspired by 밀리의서재's warm, trustworthy onboarding

   Centered app branding with tagline.
   Clean email and password form.
   Social login options (Google, Apple).
   Forgot password and sign up links.
   All UI text must be in Korean."

Direction B용 (enhance-prompt 호출 2):
  "A login screen for 'ReadCodex' reading tracker app.

   **Direction: Tech Library**
   - Archetype: Dark Minimalism — matte dark, sharp sans-serif, focused
   - Layout: Centered Narrow — tight content column, extreme focus
   - Reference: Inspired by Linear's dark, keyboard-centric interface

   Centered app branding with tagline.
   ..."
```

enhance-prompt는 LLM 기반 스킬이므로 프롬프트 텍스트에 포함된 Direction Context(아키타입, 레이아웃, 레퍼런스)를 자연어로 인식하여 해당 방향에 맞게 UI/UX 용어, 분위기, 색상 체계를 증폭한다. 공식 파라미터가 아닌 프롬프트 텍스트 삽입 방식이므로, 만약 Direction이 무시된 경우(결과 프롬프트에 Direction 특성이 반영되지 않은 경우) Direction Context를 프롬프트 최상단으로 이동하거나 더 강조하여 재호출한다.

## Phase A6: analysis.md 확장

멀티 모드에서 analysis.md에 Direction별로 프롬프트 세트를 분리 저장:

```markdown
# {App} Analysis

| 항목 | 값 |
|------|------|
| Directions | 3 |
| Direction A | Cozy Reading Nook |
| Direction B | Tech Library |
| Direction C | Illustrated Journey |

## Direction A: Cozy Reading Nook

아키타입: Warm Organic / 레이아웃: Centered Generous / 레퍼런스: 밀리의서재

### Feature 1: 인증

#### 🎯 로그인
📋 **Stitch 프롬프트**
(enhance-prompt Direction A 결과)

#### 🎯 회원가입
📋 **Stitch 프롬프트**
(enhance-prompt Direction A 결과)

---

## Direction B: Tech Library

아키타입: Dark Minimalism / 레이아웃: Centered Narrow / 레퍼런스: Linear

### Feature 1: 인증

#### 🎯 로그인
📋 **Stitch 프롬프트**
(enhance-prompt Direction B 결과)

...
```

단일 모드(`--directions 1`)에서는 Direction 섹션 없이 기존 구조 유지.

## Phase D3 × N: 멀티 프로젝트 생성

각 Direction별로 별도 Stitch 프로젝트를 생성한다:

```
Skill("stitch-design") 호출 × N:

  프로젝트 1: "{App} — {Direction A 이름}"
    → Direction A의 프롬프트 세트로 전체 Feature 화면 생성

  프로젝트 2: "{App} — {Direction B 이름}"
    → Direction B의 프롬프트 세트로 전체 Feature 화면 생성

  프로젝트 3: "{App} — {Direction C 이름}"
    → Direction C의 프롬프트 세트로 전체 Feature 화면 생성
```

프로젝트 이름에 Direction 이름을 포함하여 Stitch 웹에서 식별 가능.

## Phase D4-D6 × N: 멀티 프로젝트 검증

N개 프로젝트 모두 검증 루프를 순차 완주한다.

### 순차 처리 (병렬 불가 — Stop hook 상태 파일이 하나)

```
Direction A 프로젝트 검증:
  D4 (gaps 확인) → D5 (수정) → ... → DESIGN_VERIFIED
    ↓
Direction B 프로젝트 검증:
  D4 → D5 → ... → DESIGN_VERIFIED
    ↓
Direction C 프로젝트 검증:
  D4 → D5 → ... → DESIGN_VERIFIED
    ↓
모두 완료 → 상태 파일 삭제
```

### Feature × Direction 이중 루프 (all 모드)

`/loom design all --directions 3`일 때, **Feature가 외부 루프, Direction이 내부 루프**:

```
Feature 1:
  Direction A → D2(design-md) → D3(stitch-design) → D4-D6(검증) → VERIFIED
  Direction B → D2(design-md) → D3(stitch-design) → D4-D6(검증) → VERIFIED
  Direction C → D2(design-md) → D3(stitch-design) → D4-D6(검증) → VERIFIED
Feature 2:
  Direction A → D2 → D3 → D4-D6 → VERIFIED
  Direction B → D2 → D3 → D4-D6 → VERIFIED
  Direction C → D2 → D3 → D4-D6 → VERIFIED
...
마지막 Feature × 마지막 Direction → VERIFIED → 상태 파일 삭제
```

각 Direction의 프로젝트마다 D2(design-md)를 개별 호출하여 Direction에 맞는 디자인 시스템을 생성한다.

## State Management

### 상태 파일 확장

기존 필드에 Direction 관련 필드를 추가:

```yaml
---
phase: verify
feature: library
direction: "Cozy Reading Nook"
direction_index: 0
total_directions: 3
completed_directions: ""
project_ids: "id1|id2|id3"
session_id: {unique-id}
iteration: 2
max_iterations: 5
all_features: auth|home|library|profile
current_index: 2
completed_features: auth|home
---
```

새 필드:
- `direction`: 현재 Direction 이름
- `direction_index`: 현재 Direction 인덱스 (0부터)
- `total_directions`: 전체 Direction 수
- `completed_directions`: 완료된 Direction 목록 (파이프 구분)
- `project_ids`: Direction별 프로젝트 ID (파이프 구분, D3 실행 시 점진적으로 append)

`project_ids`는 초기에 비어있고, 각 Direction의 D3 단계에서 `create_project` 반환값을 append한다:
- Direction A 생성 후: `project_ids: "id1"`
- Direction B 생성 후: `project_ids: "id1|id2"`
- Direction C 생성 후: `project_ids: "id1|id2|id3"`

단일 모드(`--directions 1`)에서는 이 필드들이 없으므로 기존 동작 100% 호환.

### Stop Hook 확장

`design-verify-stop.sh`에 Direction 순차 전환 로직을 추가. 기존 Feature 전환과 동일 패턴:

```
DESIGN_VERIFIED 감지 시:
  1. total_directions 필드 확인
  2. 없으면 → 기존 로직 (Feature 전환 또는 완료)
  3. 있으면 → Direction이 내부 루프:
     a. 다음 Direction 있음 (direction_index < total_directions - 1)
        → direction_index++, phase→generation, iteration→0, block
        → "다음 Direction으로 D2(design-md) → D3(stitch-design) 실행"
     b. 마지막 Direction (direction_index == total_directions - 1)
        → completed_directions 업데이트, direction_index→0 리셋
        → Feature 전환 로직으로 이동:
           - all 모드 + 다음 Feature → Feature 전환, block
           - 마지막 Feature → 상태 파일 삭제, allow
```

**루프 순서**: Feature(외부) × Direction(내부). Direction 전환이 Feature 전환보다 먼저 평가된다.

## 완료 시 출력

```
✅ 3개 Direction 디자인 완료!

  📐 Direction A "Cozy Reading Nook" — Project ID: 4044680601076201931
  📐 Direction B "Tech Library" — Project ID: 5155791712187312042
  📐 Direction C "Illustrated Journey" — Project ID: 6266802823298423153

Stitch 웹에서 비교하세요: https://stitch.withgoogle.com
각 프로젝트의 전체 화면이 검증 완료되었습니다.
```

## File Changes

### 수정할 파일

| 파일 | 변경 내용 |
|---|---|
| `skills/loom/SKILL.md` | `--directions` 옵션, Direction 생성 패턴, 멀티 검증 흐름 추가 |
| `commands/loom.md` | `--directions N` 옵션 추가, 멀티 모드 실행 절차 |
| `skills/loom/references/workflows-pipeline.md` | Phase A4.5, A5×N, D3×N, D4-D6×N 추가 |
| `hooks/scripts/design-verify-stop.sh` | Direction 순차 전환 로직 추가 |
| `.claude-plugin/plugin.json` | version 1.0.0 → 1.1.0 |
| `.claude-plugin/marketplace.json` | version 1.0.0 → 1.1.0 |

### 변경 없는 파일

| 파일 | 이유 |
|---|---|
| `skills/loom/references/sheet-template.md` | Direction은 analysis.md 내부에 저장. 멀티 모드의 analysis.md 구조는 workflows-pipeline.md에서 정의 |
| `hooks/hooks.json` | Stop hook 구조 동일 |
| `.mcp.json` | 비어있음 |

### 버전

v1.0.0 → v1.1.0. 하위 호환 기능 추가 (기본 `--directions 1`이 기존 동작).

## 크레딧 영향

| 구성 | 크레딧 소비 (Feature 3개 기준) |
|---|---|
| `--directions 1` (기존) | ~3 (Feature당 1) + 검증 수정분 |
| `--directions 3` | ~9 (3 Feature × 3 Direction) + 검증 수정분 × 3 |
| `--directions 5` | ~15 + 검증 수정분 × 5 |

크레딧 소비는 Stitch 디자인 생성(generate_screen_from_text, edit_screens) 기준. enhance-prompt와 design-md는 Skill() 호출로 에이전트 컨텍스트 내에서 실행되며 Stitch 크레딧을 소비하지 않음.

일일 400 크레딧 기준, `--directions 3`은 충분히 여유. `--directions 5`도 Feature 수가 적으면 가능.
