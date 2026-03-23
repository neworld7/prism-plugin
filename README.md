# Prism — Google Stitch AI Design Orchestrator

**Version:** 3.2.0
**Author:** Taekwan Kim

Claude Code 플러그인으로, Google Stitch AI 디자인 도구를 오케스트레이션하여 코드 분석부터 디자인 생성까지 자동화합니다.

## 설치

```bash
# Claude Code 플러그인으로 설치
claude plugins add prism-plugins
```

### 사전 요구사항

- Stitch MCP 서버 연결: `claude mcp add stitch --transport http -s user https://stitch.googleapis.com/mcp`
- Stitch 공식 스킬 2개:
  ```bash
  npx skills add google-labs-code/stitch-skills --skill enhance-prompt --global
  npx skills add google-labs-code/stitch-skills --skill stitch-design --global
  ```

## Quick Start

```bash
# 1. 전체 자동화 (analyze → preview → design)
/prism pipeline readcodex

# 2. 단계별 실행
/prism analyze readcodex     # 코드 분석 → Feature 분리
/prism preview               # 7개 시안 생성 → 선택
/prism design all             # 전체 Feature 디자인 생성
```

## 커맨드

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
| `pipeline` | `/prism pipeline [app]` | analyze → preview → design 원스텝 |

### `/prism account`

| 사용법 | 설명 |
|--------|------|
| `/prism account` | 등록된 계정 목록 + 현재 활성 표시 |
| `/prism account <name>` | 해당 계정으로 전환 (세션 재시작 필요) |

## 파이프라인

```
Analyze (A1 → A3 → A4 → A4.5 → A5 → A6)
│
├── A1: 코드 분석 (6축 Screen State Matrix)
├── A3: Feature 분리 (병합 금지, Feature당 15-20개 화면)
├── A4: 프롬프트 작성 (Stitch 공식 가이드 준수, 100-300자/화면)
├── A4.5: Design Preview
│   ├── 시장 리서치 (WebSearch — 경쟁앱, 도메인 트렌드)
│   ├── 7개 시안 생성 (LIGHT 고정, 7가지 스펙트럼)
│   ├── 시안당 10개 핵심 화면 = 약 70개 미리보기
│   ├── 선택적 저장 → .prism/preview/{name}/
│   └── 활성 시안 → ./DESIGN.md
├── A5: enhance-prompt 스킬 호출
└── A6: 산출물 저장

Design (D1 → D3 → D4 → D5 → D6)
│
├── D1: prompts.md 로드
├── D3: Feature별 Stitch 프로젝트 + 축 단위 배치 생성
│   ├── 1차: Primary Screens (5-7개)
│   ├── 2차: Screen States (3-5개)
│   ├── 3차: Overlays (3-4개)
│   └── 4차: Interaction Modes (2-4개)
├── D4: 스크린샷 검증
├── D5: 수정 (1-2가지씩, what + how)
└── D6: VERIFIED → Stop hook → 다음 Feature
```

## 파일 구조

```
프로젝트/
├── DESIGN.md                        ← 활성 시안 (enhance-prompt 자동 읽기)
├── .prism/
│   ├── analysis.md                  ← 코드 분석 결과
│   ├── prompts.md                   ← 최적화된 프롬프트
│   ├── project-ids.md               ← Feature별 Stitch 프로젝트 ID
│   └── preview/
│       ├── project-ids.md           ← 시안 프로젝트 ID
│       └── {direction-name}/        ← 저장된 시안
│           ├── DESIGN.md
│           └── screenshots/
```

## 디자인 시스템 일관성

```
./DESIGN.md (프로젝트 최상위)
  ↓ enhance-prompt 스킬이 자동 읽기
  ↓ 모든 generate_screen_from_text 프롬프트에 디자인 토큰 주입
  ↓ Feature별 프로젝트에도 동일 적용
  + 이름 앵커 항상 유지 ("Continue using the {Name} design system...")
```

- **./DESIGN.md**: enhance-prompt 공식 스킬이 자동 읽기
- **시안 전환**: `/prism preview use <name>` → ./DESIGN.md 교체
- **크로스 프로젝트**: designMd 전문 + 이름 앵커로 80-90% 재현

## 멀티 계정

3개 Google 계정의 API 키로 크레딧 한도 우회.

```
일일 크레딧: 400 × 3계정 = 1,200/일
```

### 설정

계정 저장: `~/.claude/prism-accounts.json`
인증 방식: `x-goog-api-key` 헤더 (`~/.claude.json` mcpServers.stitch.headers)

### 전환

```bash
/prism account           # 현재 계정 확인
/prism account iamtkk7   # 전환 → 세션 재시작
```

## Design Preview 시안 관리

### 최초 생성

```bash
/prism preview
# → 시장 리서치 (경쟁앱 분석, 도메인 트렌드)
# → 7개 스펙트럼별 시안 생성 (각 10개 화면)
# → "저장할 시안: 1, 3, 5 / 활성: 3"
```

### 시안 추가

```bash
/prism preview add                     # AI 리서치 기반 제안
/prism preview add 네이버 블로그 느낌    # 텍스트 설명
/prism preview add [이미지 첨부]        # 이미지 참조
```

### 시안 전환/관리

```bash
/prism preview list                    # 저장된 시안 목록
/prism preview use warm-organic        # 시안 전환
/prism preview remove playful-pastel   # 시안 삭제
```

## 7가지 디자인 스펙트럼 (LIGHT 모드 고정)

| # | 스펙트럼 | 예시 | 차별화 |
|---|---------|------|--------|
| 1 | 따뜻한/감성적 | Warm Organic | Serif, 크림 톤, 종이 질감 |
| 2 | 차분한/미니멀 | Japanese Zen | 넓은 여백, 모노톤, 직선 |
| 3 | 세련된/프리미엄 | Editorial Elegance | 고급 타이포, 매거진 레이아웃 |
| 4 | 밝은/모던 | Flat Modern | 그리드, 산세리프, 컬러풀 |
| 5 | 친근한/유쾌 | Playful Pastel | 파스텔, 둥근 모서리, 일러스트 |
| 6 | 대담한/표현적 | Glassmorphism | 비대칭, 블러, 실험적 |
| 7 | 자연적/유기적 | Earthy Natural | 그린/테라코타, 유기적 곡선 |

## 프롬프트 작성 (Stitch 공식 가이드 기반)

- **Simple → Complex**: 간결하게 시작, edit으로 세분화
- **Vibe 형용사**: warm, minimal, editorial 등으로 분위기 설정
- **UI/UX 키워드**: navigation bar, card layout, floating action button
- **화면당 100-300자**, 5000자 이내
- **한 번에 1-2가지 변경**만
- **수정 시 what + how**: "On the library screen, make the grid 3 columns."

## 버전 이력

| 버전 | 변경 |
|------|------|
| 3.2.0 | 공식 프롬프트 가이드 개편, A2 제거, ./DESIGN.md 전환, 리서치 기반 시안, preview add/list/use/remove |
| 3.1.0 | /prism account 멀티 계정 전환 (x-goog-api-key) |
| 3.0.0 | Design Preview 완성 (7시안 × LIGHT), Direction 제거 |
| 2.12.0 | Direction 멀티 시스템 제거, /prism preview 도입 |
| 2.11.1 | D3 축 단위 배치 생성 |
| 2.11.0 | Feature당 15-20개 화면, 상한 제거 |
| 2.10.0 | D2 제거, Design System Name Anchor |
