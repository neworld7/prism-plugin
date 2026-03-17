---
name: stitch-automation
description: "Google Stitch AI design tool automation. Design pipeline, code pipeline, screen CRUD, design systems, variants. Use when user mentions stitch, 스티치, stitch.withgoogle.com, Stitch 디자인, Stitch MCP."
---

# Stitch Automation Skill

Automate Google Stitch AI design tool via the official Stitch Remote MCP server.

## When to Use

Activate when user:
- Mentions "stitch", "스티치", "stitch.withgoogle.com"
- Asks to create/edit design screens using Stitch
- Wants to generate design variants or manage design systems
- References AI UI design with Stitch
- Asks for UI/UX 디자인, 화면 디자인, 디자인 생성 (in Stitch context)

## Prerequisites

### Authentication Check

Before any Stitch MCP operation, verify auth:
```bash
gcloud auth application-default print-access-token 2>/dev/null | head -c 20
```

If token fetch fails, prompt user:
> Stitch MCP 인증이 필요합니다. 아래 명령을 순서대로 실행해주세요:
> 1. `gcloud auth login`
> 2. `gcloud auth application-default login`

### MCP Tool Availability

Verify Stitch MCP tools are loaded:
```
ToolSearch query: "+stitch list_projects"
```

If not found, the `.mcp.json` in this plugin should auto-register the Stitch MCP server.

## Design Pipeline (코드→디자인 워크플로우)

Stitch의 주 용도는 **코드→프로덕션 디자인 전환 파이프라인**이다.
`/stitch design` 또는 디자인 관련 요청 시 아래 7단계를 따른다.

| Phase | 내용 | 핵심 |
|-------|------|------|
| 1 | 코드 분석 | Glob/Grep으로 화면·인터랙션·상태 전수 조사 |
| 2 | 디자인 시트 작성 | `docs/plans/` 에 코드 vs 디자인 비교 문서 |
| 3 | 프롬프트 최적화 | Stitch에 최적화된 프롬프트 작성 |
| 4 | Stitch 디자인 생성 | MCP로 프로젝트/화면/디자인시스템 생성 |
| 5 | 검증 | 코드 ↔ Stitch 크로스체크, gaps 카운트 |
| 6 | 누락분 수정 | gaps > 0이면 edit_screens 또는 재생성 |
| 7 | 루프 | 5→6 반복, gaps == 0이면 종료 |

### Pipeline 실행 시 반드시 참조

```
Read: references/workflows-design.md   ← Phase별 실행 절차 상세
Read: references/sheet-template.md      ← 디자인 시트 마크다운 템플릿
Read: references/prompting.md           ← Stitch 프롬프팅 가이드
```

Phase 5-7 검증 루프는 **Stop hook**이 자동 관리한다.
상태 파일 `.claude/stitch-design-pipeline.local.md`에 `phase: verify`가 설정되면
Stop hook이 `<promise>DESIGN_VERIFIED</promise>` 감지까지 루프를 반복한다.

### 완료 조건
- [ ] 코드의 모든 화면이 Stitch 디자인에 1:1 매핑
- [ ] 모든 버튼/인터랙션이 디자인에 반영
- [ ] 상태별 화면(로딩, 에러, 엠티)이 포함
- [ ] 검증 루프에서 누락 0건 확인

## Implement Pipeline (디자인→코드 워크플로우)

Stitch 디자인을 실제 코드에 반영하는 **역방향 파이프라인**.
`/stitch implement` 또는 "디자인을 코드로", "코드에 반영" 요청 시 아래 7단계를 따른다.

| Phase | 내용 | 핵심 |
|-------|------|------|
| 1 | 디자인 수집 | Stitch MCP로 프로젝트/스크린 데이터 수집 |
| 2 | 코드 매핑 | Stitch 스크린 ↔ 기존 코드 파일 대응표 작성 |
| 3 | 구현 계획 | 코드 시트 작성 (화면별 변환 전략) → 사용자 확인 |
| 4 | 코드 구현 | 시트 기반으로 Flutter/React 코드 작성/수정 |
| 5 | 시각 검증 | 구현 코드 스크린샷 ↔ Stitch 디자인 스크린샷 비교 |
| 6 | 차이 수정 | 불일치 항목 코드 수정 |
| 7 | 루프 | 5→6 반복, 차이 0이면 종료 |

### Pipeline 실행 시 반드시 참조

```
Read: references/workflows-implement.md   ← Phase별 실행 절차 상세
Read: references/tools.md                 ← MCP 도구 파라미터 참조
```

Phase 5-7 검증 루프는 **Stop hook**이 자동 관리한다.
상태 파일 `.claude/stitch-implement-pipeline.local.md`에 `phase: code_verify`가 설정되면
Stop hook이 `<promise>CODE_VERIFIED</promise>` 감지까지 루프를 반복한다.

### 시각 검증 핵심

1. **Stitch 디자인 스크린샷**: `get_screen` → `web_fetch(downloadUrl)`
2. **구현 코드 스크린샷**:
   - Flutter: `xcrun simctl io booted screenshot /tmp/{screen}.png` + `sips -Z 1200`
   - React/Next.js: chrome-viewer `cv_screenshot` 또는 Playwright `browser_take_screenshot`
3. **비교**: 두 이미지를 나란히 Read → 레이아웃/색상/컴포넌트/콘텐츠 차이 분석
4. **차이 리포트**: HIGH(누락)/MED(구조)/LOW(폴리싱) 분류
5. **코드 수정 후 재검증**: diffs == 0이면 `<promise>CODE_VERIFIED</promise>`

### 완료 조건
- [ ] 모든 대상 화면이 코드로 구현됨
- [ ] 구현 코드 스크린샷이 Stitch 디자인과 시각적 일치
- [ ] HIGH/MED 차이 0건
- [ ] 코드 시트의 모든 항목이 [DONE]

## Critical Patterns

### Pattern 1: Screen Data Retrieval

Stitch MCP의 `get_screen`은 `downloadUrls`를 반환한다.
HTML 코드와 스크린샷 이미지를 실제로 가져오려면 `web_fetch`가 필요:

```
1. get_screen(projectId, screenId) → response with downloadUrls
2. web_fetch(response.downloadUrls.html) → HTML/CSS code
3. web_fetch(response.downloadUrls.screenshot) → screenshot image
```

### Pattern 2: Screenshot Discipline

- **MCP 도구 우선**: 가능하면 `get_screen` 데이터로 상태 확인
- **스크린샷**: 시각 검증 마일스톤에서만 사용
- **리사이즈 필수**: `sips -Z 1200 <file>` (컨텍스트 오버플로우 방지)

### Pattern 3: Design System Consistency

여러 화면 생성 시 디자인 일관성 유지:
```
1. create_design_system → 테마 정의
2. generate_screen_from_text → 화면 생성
3. apply_design_system → 생성된 화면에 디자인 시스템 적용
```

### Pattern 4: Error Recovery

- MCP 도구 실패 → 3회까지 재시도 (1s, 2s, 4s backoff)
- Auth 만료 → `gcloud auth application-default login` 재실행 안내
- Rate limit → Stitch 생성 한도 안내 (Standard 350/month, Experimental 50/month)

## Workflow Reference

| Task | Reference File |
|------|----------------|
| Code → Design pipeline (코드를 디자인으로) | `references/workflows-design.md` |
| Design → Code pipeline (디자인을 코드로) | `references/workflows-implement.md` |
| Stitch prompting best practices | `references/prompting.md` |
| MCP tool parameters & usage | `references/tools.md` |
| Design/implement sheet template | `references/sheet-template.md` |
