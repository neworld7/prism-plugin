# Prism — Google Stitch AI Design Orchestrator

**Version:** 3.4.2
**Author:** Taekwan Kim

Claude Code 플러그인으로, Google Stitch AI 디자인 도구를 오케스트레이션하여 코드 분석부터 디자인 생성까지 자동화합니다.

## 목차

- [설치](#설치)
- [Quick Start](#quick-start)
- [아키텍처 개요](#아키텍처-개요)
- [커맨드 레퍼런스](#커맨드-레퍼런스)
- [Analyze 파이프라인](#analyze-파이프라인)
- [Design Preview (시안 생성)](#design-preview-시안-생성)
- [Design 파이프라인](#design-파이프라인)
- [DESIGN.md 관리](#designmd-관리)
- [검증 루프 (Stop Hook)](#검증-루프-stop-hook)
- [멀티 계정](#멀티-계정)
- [크레딧 관리](#크레딧-관리)
- [파일 구조](#파일-구조)
- [플러그인 컴포넌트](#플러그인-컴포넌트)
- [프롬프트 작성 가이드](#프롬프트-작성-가이드)
- [트러블슈팅](#트러블슈팅)
- [버전 이력](#버전-이력)

---

## 설치

```bash
# Claude Code 플러그인으로 설치
claude plugins add prism-plugins
```

### 사전 요구사항

1. **Stitch MCP 서버 연결:**
   ```bash
   claude mcp add stitch --transport http -s user https://stitch.googleapis.com/mcp
   ```

2. **Stitch 공식 스킬 2개:**
   ```bash
   npx skills add google-labs-code/stitch-skills --skill enhance-prompt --global
   npx skills add google-labs-code/stitch-skills --skill stitch-design --global
   ```

3. **API 키:**
   [Google AI Studio](https://aistudio.google.com/apikey)에서 발급 → `~/.claude/prism-accounts.json`에 설정 (아래 [멀티 계정](#멀티-계정) 참조)

---

## Quick Start

```bash
# 전체 자동화 (analyze → preview → design)
/prism pipeline readcodex

# 단계별 실행
/prism analyze readcodex     # 1. 코드 분석 → Feature 분리 → 프롬프트 생성
/prism preview               # 2. 7개 시안 생성 → 비교 → 선택
/prism design all             # 3. 전체 Feature 디자인 생성
```

---

## 아키텍처 개요

Prism은 **오케스트레이터**로, 직접 디자인을 생성하지 않고 공식 Stitch 스킬에 위임합니다.

```
┌─────────────────────────────────────────────────────┐
│  Prism (오케스트레이터)                                │
│  - 코드 분석, Feature 분리, 파이프라인 흐름 제어         │
│  - 검증 루프 (D4-D6), 상태 파일 관리                    │
│  - 읽기 전용 MCP 직접 호출 (get_screen, list_screens)   │
└──────────┬──────────────────────┬───────────────────┘
           │                      │
           ▼                      ▼
┌──────────────────┐   ┌───────────────────────┐
│  stitch-design   │   │  enhance-prompt       │
│  (공식 스킬)      │   │  (공식 스킬)           │
│  - 디자인 생성/수정 │   │  - 프롬프트 최적화      │
│  - generate_screen│   │  - ./DESIGN.md 자동 읽기│
│  - edit_screens   │   │  - 디자인 토큰 주입      │
└──────────────────┘   └───────────────────────┘
           │                      │
           ▼                      ▼
┌─────────────────────────────────────────────────────┐
│  Stitch MCP (stitch.googleapis.com/mcp)             │
│  - generate_screen_from_text, edit_screens           │
│  - get_project, get_screen, list_screens, list_projects │
└─────────────────────────────────────────────────────┘
```

### MCP 호출 경계

| 호출 주체 | 도구 | 유형 |
|-----------|------|------|
| 공식 스킬 경유 | `generate_screen_from_text`, `edit_screens`, `generate_variants` | 생성/수정 |
| Prism 직접 호출 | `get_screen`, `list_screens`, `get_project`, `list_projects` | 읽기 전용 |
| Prism 직접 호출 | `web_fetch` | 스크린샷/HTML 다운로드 |

### 스킬 호출 체인

D3 디자인 생성 시 스킬이 체인으로 호출됩니다:

```
Prism: Skill("stitch-design")
  └→ stitch-design 내부: Skill("enhance-prompt")
       └→ ./DESIGN.md 자동 읽기
       └→ 디자인 토큰(색상, 폰트, 간격) 주입
       └→ 최적화된 프롬프트 → generate_screen_from_text 호출
```

따라서 D3에서 디자인 토큰을 수동 삽입할 필요가 없습니다.

---

## 커맨드 레퍼런스

### `/prism`

| 서브커맨드 | 사용법 | 설명 |
|-----------|--------|------|
| `analyze` | `/prism analyze [app]` | 코드 분석 → Feature별 프롬프트 |
| `preview` | `/prism preview` | 시장 리서치 → 7개 시안 × 10개 화면 생성 |
| `preview add` | `/prism preview add` | 새 시안 추가 (AI 제안 / 텍스트 / 이미지) |
| `preview list` | `/prism preview list` | 저장된 시안 목록 |
| `preview use` | `/prism preview use <name>` | 시안 전환 (./DESIGN.md 교체) |
| `preview remove` | `/prism preview remove <name>` | 시안 삭제 |
| `design` | `/prism design <feature\|all>` | 디자인 생성 + 검증 루프 |
| `design resume` | `/prism design resume` | 중단된 design all 이어하기 |
| `pipeline` | `/prism pipeline [app]` | analyze → preview → design 원스텝 |

### `/prism account`

| 사용법 | 설명 |
|--------|------|
| `/prism account` | 등록된 계정 목록 + 현재 활성 표시 |
| `/prism account <name>` | 해당 계정으로 전환 (세션 재시작 필요) |

---

## Analyze 파이프라인

`/prism analyze [app]` — 코드베이스를 분석하여 Feature별 UX-First 프롬프트를 산출합니다.

### 실행 흐름 (Phase A1 → A6)

```
A1  코드 심층 분석          ─── Screen State Matrix 7축으로 모든 화면 요소 추출
 ↓
A3  Feature 분리            ─── 기능 단위로 그룹핑 (병합 금지, Feature당 15-20개 화면)
 ↓
A4  프롬프트 작성            ─── Stitch 공식 가이드 기반, 화면당 100-300자
 ↓
A4.5 Design Preview         ─── 7개 시안 생성 (별도 /prism preview로도 실행 가능)
 ↓
A5  enhance-prompt 호출      ─── 공식 스킬로 프롬프트 최적화 + 디자인 토큰 주입
 ↓
A6  산출물 저장              ─── .prism/analysis.md + .prism/prompts.md
```

### Screen State Matrix (7축 코드 분석)

코드에서 추출하는 7가지 축 (Scott Hurff UI Stack + Apple HIG 2026 + Material Design 3 기반):

| 축 | 추출 대상 | 예시 패턴 |
|----|-----------|-----------|
| **Primary Screens** | 메인 라우트/페이지 | `class.*Screen`, `GoRoute`, `page.tsx` |
| **Data States** | empty, partial, loading, error, populated | `EmptyState`, `isLoading`, `ErrorWidget` |
| **Overlays** | 모달, 바텀시트, 다이얼로그, 스낵바 | `showModalBottomSheet`, `AlertDialog` |
| **Interaction Modes** | 편집, 드래그, 스와이프, 검색, 키보드 | `_isEditMode`, `ReorderableListView` |
| **App Lifecycle** | 스플래시, 권한, 오프라인, 온보딩, 완료 | `SplashScreen`, `Onboarding`, `CompletionScreen` |
| **Auth & Entitlement** | 로그인/비로그인, 무료/프리미엄, 역할 분기 | `isLoggedIn`, `isPremium`, `isAdmin` |
| **Environment Variants** | 폰/태블릿, iOS/Android, 접근성, 동기화 | `MediaQuery`, `Platform.isIOS`, `Semantics` |

> **실용적 적용:** Primary Screens × Data States를 필수 매트릭스로, 나머지 5축은 해당 화면에 관련된 항목만 선택적으로 표기합니다.
> Flutter, React, Next.js 모두 지원. 동일한 축의 의미를 유지하되 패턴을 스택에 맞게 변환합니다.

### 산출물

| 파일 | 내용 |
|------|------|
| `.prism/analysis.md` | Feature 목록, 화면 구성, 데이터 흐름, 네비게이션 구조 |
| `.prism/prompts.md` | Feature별 Stitch 생성용 최적화 프롬프트 |

---

## Design Preview (시안 생성)

`/prism preview` — 핵심 화면 10개 × 디자인 Direction 7개 = 약 70개 화면을 Stitch로 생성하여 비교합니다.

### 실행 흐름

```
1  analysis.md 로드          ─── /prism analyze 결과 필요
 ↓
2  핵심 화면 10개 선정        ─── 앱의 대표 화면 추출 → 사용자 확인
 ↓
3  시장 리서치               ─── WebSearch로 경쟁앱, 도메인 트렌드 조사
 ↓
4  7개 Direction 정의        ─── 디자인 스펙트럼 각 1개씩 (아래 참조)
 ↓
5  Direction별 Stitch 프로젝트 생성
   → 화면 10개 배치 생성      ─── 7개 프로젝트 × 10개 화면
 ↓
6  ~70개 화면 스크린샷 비교   ─── 한눈에 비교
 ↓
7  저장할 시안 선택           ─── 예: "1, 3, 5" → .prism/preview/{name}/에 저장
 ↓
8  활성 시안 선택             ─── 예: "3" → ./DESIGN.md로 복사
```

### 7가지 디자인 스펙트럼 (LIGHT 모드 고정)

시안 이름은 알고리즘으로 자동 생성되는 것이 아니라, **7가지 디자인 스펙트럼에 대응하는 고정 시맨틱 이름**입니다:

| # | 스펙트럼 | 시안 이름 | 특징 |
|---|---------|-----------|------|
| 1 | 따뜻한/감성적 | **Warm Organic** | Serif, 크림 톤, 종이 질감 |
| 2 | 차분한/미니멀 | **Japanese Zen** | 넓은 여백, 모노톤, 직선 |
| 3 | 세련된/프리미엄 | **Editorial Elegance** | 고급 타이포, 매거진 레이아웃 |
| 4 | 밝은/모던 | **Flat Modern** | 그리드, 산세리프, 컬러풀 |
| 5 | 친근한/유쾌 | **Playful Pastel** | 파스텔, 둥근 모서리, 일러스트 |
| 6 | 대담한/표현적 | **Glassmorphism** | 비대칭, 블러, 실험적 |
| 7 | 자연적/유기적 | **Earthy Natural** | 그린/테라코타, 유기적 곡선 |

### Stitch 프로젝트 네이밍

각 Direction별 Stitch 프로젝트는 다음 형식으로 생성됩니다:
```
{앱이름} — {시안이름}
예: "ReadCodex — Warm Organic"
```

### 시안 관리 커맨드

```bash
/prism preview                          # 생성 + 비교 + 선택
/prism preview add                      # AI 리서치 기반 새 시안 제안
/prism preview add 네이버 블로그 느낌     # 텍스트 설명으로 새 시안
/prism preview add [이미지 첨부]         # 이미지 참조로 새 시안
/prism preview list                     # 저장된 시안 목록
/prism preview use warm-organic         # 시안 전환 (상태 파일 자동 스왑)
/prism preview remove playful-pastel    # 시안 삭제
```

---

## Design 파이프라인

`/prism design <feature|all>` — 공식 Stitch 스킬을 호출하여 Feature별 디자인을 생성하고 검증합니다.

### Feature별 독립 프로젝트

**각 Feature마다 별도 Stitch 프로젝트가 생성됩니다** (하나로 합치지 않음):

```
{앱} · {시안명} · {번호}. {Feature명}

ReadCodex · Warm Organic · 1. Auth & Onboarding
ReadCodex · Warm Organic · 2. Library
ReadCodex · Warm Organic · 3. Stats
ReadCodex · Warm Organic · 4. Explore
```

### Feature당 화면 구성 (15~20개)

Screen State Matrix 7축 기반으로 화면을 생성합니다. 배치 생성은 주요 4개 축 단위:

| 축 | 개수 | 예시 |
|----|------|------|
| **Primary Screens** | 5~7개 | 책장, 책 상세, 검색 |
| **Data States** | 4~6개 | `서재 (empty)`, `서재 (partial)`, `서재 (skeleton)`, `서재 (error)` |
| **Overlays** | 3~4개 | 정렬/필터 바텀시트, 삭제 확인 다이얼로그 |
| **Interaction Modes** | 2~4개 | `서재 (edit mode)`, `서재 (search active)` |

나머지 3축(App Lifecycle, Auth & Entitlement, Environment Variants)은 해당 Feature에 관련된 항목만 선택적으로 추가합니다.

### 화면 이름 규칙

Feature/화면 맥락에서 자동 도출됩니다:

```
서재 (책장, 그리드 뷰)          ← Primary
서재 (empty)                    ← Data: empty
서재 (partial)                  ← Data: partial
서재 (skeleton)                 ← Data: loading
정렬/필터 바텀시트               ← Overlay
서재 (edit mode)                ← Interaction Mode
서재 (비로그인)                  ← Auth: logged-out
```

### 축 단위 배치 생성 (D3)

한 번에 전부가 아니라 **축 단위로 배치 생성**합니다:

```
1차 배치: Primary Screens (5-7개) → generate_screen_from_text
2차 배치: Screen States (3-5개)   → generate_screen_from_text
3차 배치: Overlays (3-4개)        → generate_screen_from_text
4차 배치: Interaction Modes (2-4개) → generate_screen_from_text
```

### 실행 흐름 (Phase D1 → D6)

```
D1  prompts.md 로드           ─── analysis.md에서 대상 Feature 프롬프트 추출
 ↓
D3  디자인 생성               ─── Design Identity 판단 + Skill("stitch-design")
    ├── ./DESIGN.md 없음       → 첫 Feature에서 designTheme 추출 → ./DESIGN.md 생성
    └── ./DESIGN.md 있음       → enhance-prompt가 자동으로 토큰 주입
 ↓
D4  스크린샷 검증             ─── 코드 대비 누락 화면 체크
 ↓
D5  수정                     ─── 1-2가지씩, what + how 명시
 ↓
D6  VERIFIED                 ─── Stop hook이 다음 Feature로 전환
```

> D2는 v2.10.0에서 제거되었습니다.

### All 모드: Feature-by-Feature 순차 처리

`/prism design all` 실행 시:

```
Feature 1 생성 → 검증 루프 → DESIGN_VERIFIED
  ↓ Stop hook이 다음 Feature로 상태 전환
Feature 2 생성 → 검증 루프 → DESIGN_VERIFIED
  ↓ ...
Feature N 생성 → 검증 루프 → DESIGN_VERIFIED
  ↓ 상태 파일 삭제 → 완료
```

### 상태 파일

`.claude/prism-design-pipeline.local.md`에 YAML frontmatter로 진행 상황을 추적합니다:

```yaml
---
phase: generation          # generation | verify | done_max_iter
feature: Library           # 현재 처리 중인 Feature
session_id: abc123         # 세션 ID (다른 세션에서의 충돌 방지)
iteration: 0               # 현재 검증 반복 횟수
max_iterations: 5          # 최대 검증 반복 (기본 5)
all_features: Auth|Library|Stats  # all 모드일 때: 전체 Feature 목록
current_index: 1           # all 모드일 때: 현재 인덱스
completed_features: Auth   # all 모드일 때: 완료된 Feature 목록
design_name: warm-organic  # 현재 시안 이름
completed_screens: ...     # resume용: 이미 생성된 화면
current_axis: overlays     # resume용: 현재 처리 중인 축
project_id: projects/xxx   # resume용: Stitch 프로젝트 ID
---
```

### 크레딧 소진 시 이어하기

```bash
# Warm Organic 시안으로 design all → Feature 3에서 크레딧 소진

# 방법 1: 계정 전환 후 이어하기
/prism account neworld                 # 다른 계정으로 전환 → 세션 재시작
/prism design resume                   # Feature 3부터 이어서

# 방법 2: 다른 시안으로 전환 작업
/prism preview use editorial-elegance  # 시안 전환 (Warm Organic 상태 자동 백업)
/prism design all                      # Editorial Elegance 독립 진행

# 방법 3: 다시 Warm Organic으로 돌아와서 이어하기
/prism preview use warm-organic        # 상태 자동 복원
/prism design resume                   # Feature 3부터 이어서
```

---

## DESIGN.md 관리

DESIGN.md는 디자인 시스템의 단일 소스로, 시안별로 독립 보관되며 활성 시안만 프로젝트 루트에 존재합니다.

### 파일 레이아웃

```
./DESIGN.md                              ← 활성 시안 (1개만 존재)

.prism/preview/
  ├── index.md                           ← 시안 목록 + 프로젝트 ID + 활성 표시
  ├── warm-organic/
  │   ├── DESIGN.md                      ← 시안 템플릿 보관
  │   └── screenshots/
  ├── editorial-elegance/
  │   ├── DESIGN.md
  │   └── screenshots/
  └── japanese-zen/
      ├── DESIGN.md
      └── screenshots/
```

### 활성화 흐름

```
/prism preview
  ↓ 7개 Direction 생성 (각각 Stitch 프로젝트)
  ↓ 사용자: "1, 3, 5 저장"
  ↓ Stitch designTheme.designMd → .prism/preview/{name}/DESIGN.md에 각각 저장
  ↓ 사용자: "3번 활성화"
  ↓ .prism/preview/editorial-elegance/DESIGN.md → ./DESIGN.md 복사
```

### 시안 전환 시 동작

`/prism preview use <name>` 실행 시:

```
1. 현재 상태 백업
   .claude/prism-design-pipeline.local.md
   → .claude/prism-pipelines/{현재시안}.local.md

2. 새 시안 DESIGN.md 활성화
   .prism/preview/{새시안}/DESIGN.md → ./DESIGN.md

3. 새 시안 상태 복원 (있으면)
   .claude/prism-pipelines/{새시안}.local.md
   → .claude/prism-design-pipeline.local.md
```

**진행 상태가 시안별로 독립 보존**되므로, 크레딧 소진 후 다른 시안으로 전환했다가 돌아와도 이어서 작업할 수 있습니다.

### DESIGN.md 포맷

```markdown
# Design Identity
| 항목 | 값 |
|------|------|
| Name | {디자인 시스템 이름} |
| Source Project | projects/{projectId} |
| Color Mode | {colorMode} |
| Roundness | {roundness} |
| Primary Font | {font} |
| Body Font | {bodyFont} |

## Design System Spec
{designTheme.designMd 전문}
```

### 디자인 시스템 일관성 — 단일 DESIGN.md 원칙

> **핵심 규칙: `./DESIGN.md`가 프로젝트 루트에 존재하면, 모든 Feature 프로젝트는 반드시 동일한 디자인 시스템을 사용해야 합니다.**
>
> Feature 1이든 Feature 10이든, 어떤 Feature의 Stitch 프로젝트를 생성하더라도 루트 `./DESIGN.md`에 정의된 디자인 토큰(색상, 폰트, 간격, 둥근 모서리 등)이 일관되게 적용됩니다. Feature별로 다른 디자인 시스템을 사용하는 것은 허용되지 않습니다.

```
./DESIGN.md (프로젝트 최상위 — 단일 소스)
  ↓ enhance-prompt 스킬이 자동 읽기
  ↓ 모든 Feature의 generate_screen_from_text 프롬프트에 동일한 디자인 토큰 주입
  ↓ Feature 1, 2, 3, ... N 모두 같은 디자인 시스템 적용
  + 이름 앵커 항상 유지 ("Continue using the {Name} design system...")
```

이 구조가 보장하는 것:
- **Feature 간 시각적 일관성**: Auth 화면과 Library 화면이 같은 색상/폰트/간격 사용
- **크로스 프로젝트 재현**: designMd 전문 + 이름 앵커로 80-90% 재현
- **자동 적용**: D3에서 수동으로 디자인 토큰을 삽입할 필요 없음 — enhance-prompt가 처리
- **Design Identity 생성 시점**: 첫 Feature 프로젝트의 `designTheme.designMd`에서 추출 → 이후 모든 Feature에 동일 적용

다른 디자인 시스템을 사용하고 싶다면, `/prism preview use <name>`으로 시안을 전환하여 `./DESIGN.md` 자체를 교체해야 합니다. Feature 단위로 부분 전환은 불가합니다.

---

## 검증 루프 (Stop Hook)

디자인 검증은 **Stop hook**이 자동으로 관리합니다. 코드로 직접 루프를 제어할 필요가 없습니다.

### 동작 원리

```
hooks/hooks.json
  └── Stop 이벤트 → hooks/scripts/design-verify-stop.sh 실행
```

상태 파일에 `phase: verify`가 설정되면, Stop hook은 매 응답 종료 시 다음을 확인합니다:

1. **`<promise>DESIGN_VERIFIED</promise>` 감지됨**
   - 단일 Feature: 상태 파일 삭제 → 완료
   - All 모드: 다음 Feature로 상태 전환 → block 응답으로 다음 Feature 생성 유도
   - 마지막 Feature: 상태 파일 삭제 → 완료

2. **감지 안 됨 (누락 있음)**
   - iteration 카운터 증가
   - block 응답으로 D4 재검증 유도
   - `max_iterations` (기본 5) 초과 시 `phase: done_max_iter`로 전환 → 루프 종료

### Stop Hook 상태 머신

```
generation ──(D3 완료)──→ verify ──(VERIFIED)──→ 다음 Feature 또는 완료
                            │
                            ├──(미검증)──→ iteration++ → verify (재검증)
                            │
                            └──(max_iter 초과)──→ done_max_iter → 종료
```

### 세션 안전장치

상태 파일에 `session_id`가 기록되어 있으면, 다른 세션에서 실행된 Stop hook은 무시됩니다. 같은 프로젝트에서 여러 세션을 열어도 충돌하지 않습니다.

---

## 멀티 계정

3개 Google 계정의 API 키로 크레딧 한도를 확장합니다.

```
일일 크레딧: 400 × 3계정 = 1,200/일
```

### 초기 설정

최초 사용 시 `~/.claude/prism-accounts.json`을 직접 생성합니다:

```json
{
  "active": "myaccount",
  "accounts": [
    {
      "name": "myaccount",
      "email": "user@gmail.com",
      "apiKey": "AIza..."
    },
    {
      "name": "secondaccount",
      "email": "user2@gmail.com",
      "apiKey": "AIza..."
    }
  ]
}
```

API 키는 [Google AI Studio](https://aistudio.google.com/apikey)에서 발급받습니다.

### 인증 방식

계정 전환 시 `~/.claude.json`의 `mcpServers.stitch.headers.x-goog-api-key`가 업데이트됩니다. 세션 재시작 후 적용됩니다.

### 전환

```bash
/prism account           # 현재 계정 확인
/prism account iamtkk7   # 전환 → 세션 재시작 필요
```

---

## 크레딧 관리

### 일일 크레딧 체계

| 항목 | 한도 | 주기 |
|------|------|------|
| 일일 크레딧 | **400** | 매일 리셋 |
| Redesign Credits | **15** | 매일 리셋 |

### 모델 선택 전략

| 단계 | 모드 | 용도 |
|------|------|------|
| 기본 (생성/수정 모두) | Thinking with 3 Pro (`GEMINI_3_1_PRO`) | 프로덕션 품질, 깊은 추론 |
| 스타일 실험 | Redesign (Nano Banana Pro) | Vibe Design, 별도 15 크레딧 |

> 일일 400 크레딧이면 PRO 기본 사용에 충분합니다.

### 파이프라인 시작 시

- 생성할 화면 수를 사용자에게 알림: "총 N개 화면 생성 예정 (일일 한도: 400 크레딧)"
- 사용자 확인 후 진행

---

## 파일 구조

### 프로젝트 산출물

```
프로젝트/
├── DESIGN.md                           ← 활성 시안 (enhance-prompt 자동 읽기)
├── .claude/
│   ├── prism-design-pipeline.local.md  ← 현재 활성 상태 파일
│   └── prism-pipelines/                ← 시안별 상태 백업
│       ├── warm-organic.local.md
│       └── editorial-elegance.local.md
├── .prism/
│   ├── analysis.md                     ← 코드 분석 결과 (A1-A4)
│   ├── prompts.md                      ← 최적화된 프롬프트 (A5)
│   ├── project-ids.md                  ← Feature별 Stitch 프로젝트 ID
│   └── preview/
│       ├── index.md                    ← 시안 목록 + 프로젝트 ID + 활성 시안
│       └── {direction-name}/           ← 저장된 시안
│           ├── DESIGN.md
│           └── screenshots/
```

### 전역 설정

```
~/.claude/
├── prism-accounts.json                 ← 멀티 계정 설정 (API 키)
└── .claude.json                        ← mcpServers.stitch.headers (인증)
```

---

## 플러그인 컴포넌트

### 디렉토리 구조

```
prism-plugin/
├── .claude-plugin/
│   └── plugin.json                     ← 플러그인 매니페스트
├── commands/
│   ├── prism.md                        ← /prism 커맨드 정의
│   └── account.md                      ← /prism account 커맨드 정의
├── skills/
│   └── prism/
│       ├── SKILL.md                    ← 스킬 정의 (트리거, 실행 로직)
│       └── references/
│           └── workflows.md            ← 전체 워크플로우 상세 (A1-A6, D1-D6)
├── hooks/
│   ├── hooks.json                      ← Hook 이벤트 바인딩
│   └── scripts/
│       └── design-verify-stop.sh       ← Stop hook: 검증 루프 자동화
└── docs/
    └── superpowers/                    ← 설계 문서 아카이브
        ├── plans/                      ← 기능별 계획서
        └── specs/                      ← 기능별 설계서
```

### 컴포넌트 역할

| 컴포넌트 | 파일 | 역할 |
|----------|------|------|
| **커맨드** | `commands/prism.md` | `/prism` 슬래시 커맨드 진입점, 서브커맨드 라우팅 |
| **커맨드** | `commands/account.md` | `/prism account` 계정 전환, python3 스크립트 실행 |
| **스킬** | `skills/prism/SKILL.md` | 트리거 조건, MCP 경계, Design Identity 관리, Critical Patterns |
| **레퍼런스** | `skills/prism/references/workflows.md` | A1-A6, D1-D6 전체 워크플로우 상세 절차 |
| **Hook** | `hooks/hooks.json` | Stop 이벤트에 검증 스크립트 바인딩 |
| **Hook 스크립트** | `hooks/scripts/design-verify-stop.sh` | DESIGN_VERIFIED 감지, Feature 전환, iteration 관리 |

---

## 프롬프트 작성 가이드

Stitch 공식 가이드 + v3.4.2 디자인 토큰 주입 패턴:

- **DESIGN SYSTEM (REQUIRED) 블록 필수** — `./DESIGN.md`에서 추출한 실제 hex 코드, 폰트명, 스타일 규칙을 모든 프롬프트에 포함
- **Simple → Complex**: 간결하게 시작, edit으로 세분화
- **Vibe 형용사**: warm, minimal, editorial 등으로 분위기 설정
- **UI/UX 키워드**: navigation bar, card layout, floating action button
- **화면당 100-300자**, DESIGN SYSTEM 블록 포함 5000자 이내
- **한 번에 1-2가지 변경**만
- **수정 시 what + how**: "On the product list screen, make the grid 3 columns."
- ~~hex 코드, px 값, 특정 폰트명 포함 금지~~ → **v3.4.2에서 폐기** — 토큰을 포함해야 Stitch가 정확히 반영

---

## 트러블슈팅

### 공식 스킬 미설치

```bash
npx skills add google-labs-code/stitch-skills --skill enhance-prompt --global
npx skills add google-labs-code/stitch-skills --skill stitch-design --global
```

### 인증 실패

1. `~/.claude/prism-accounts.json` 존재 확인
2. API 키 유효성 확인 ([Google AI Studio](https://aistudio.google.com/apikey))
3. `/prism account` 으로 현재 활성 계정 확인

### analysis.md 미존재

`/prism design` 실행 전에 반드시 `/prism analyze`를 먼저 실행해야 합니다.

### Stitch MCP 도구 미발견

```bash
# MCP 서버 연결 확인
claude mcp add stitch --transport http -s user https://stitch.googleapis.com/mcp
```

### chrome-viewer로 Stitch 웹 탐색 시

Stitch는 cross-origin iframe 구조(`app-companion-430619.appspot.com`)이므로:
- `cv_click_element`, `cv_evaluate`는 메인 프레임만 접근 → iframe 내부 조작 불가
- CDP(Chrome DevTools Protocol)로 iframe 탭에 직접 WebSocket 연결 필요
- 페이지에서 요소를 찾을 때 반드시 전체 스크롤 후 판단 (최소 3회 확인)

---

## 버전 이력

| 버전 | 변경 |
|------|------|
| 3.4.2 | **DESIGN SYSTEM (REQUIRED) 블록 필수화** — 텍스트 앵커만으로는 Stitch가 디자인 시스템 미인식. hex/font/style 토큰 직접 주입 패턴으로 전환. "hex 금지" 규칙 폐기. A4 프롬프트 구조, D3 배치 프롬프트, 예시 전면 업데이트 |
| 3.4.1 | 도메인 중립 예시 전면 교체 — ReadCodex/도서앱 편향 54건 제거, 커머스+피트니스 2개 도메인 예시 |
| 3.4.0 | Screen State Matrix 6축→7축 재구성: Data States(partial 추가), App Lifecycle(System States+Transitions 병합), Auth & Entitlement(신규), Environment Variants(신규), keyboard-visible 추가. README 전면 재작성, 단일 DESIGN.md 원칙 강조 |
| 3.3.1 | loom→prism 잔존 리네임, 파일 구조 문서 정합성(index.md), D4 체크리스트 구체화, 스킬 호출 체인 문서화, sed 이식성, 계정 초기 설정 문서화, 트리거 키워드 확장 |
| 3.3.0 | design resume (크레딧 소진 이어하기), 시안별 상태 파일 분리, 시안 10개 화면, 시장 리서치 제안 |
| 3.2.0 | 공식 프롬프트 가이드 개편, A2 제거, ./DESIGN.md 전환, preview add/list/use/remove |
| 3.1.0 | /prism account 멀티 계정 전환 (x-goog-api-key) |
| 3.0.0 | Design Preview 완성 (7시안 × LIGHT), Direction 제거 |
| 2.12.0 | Direction 멀티 시스템 제거, /prism preview 도입 |
| 2.11.1 | D3 축 단위 배치 생성 |
| 2.11.0 | Feature당 15-20개 화면, 상한 제거 |
| 2.10.0 | D2 제거, Design System Name Anchor |
