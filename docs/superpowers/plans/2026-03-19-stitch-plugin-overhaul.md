# Stitch Plugin v0.2.0 Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stitch 플러그인을 v0.2.0으로 전면 개편 — 공식 스킬 포크, MCP 도구 업데이트, analyze 파이프라인 신설, 크레딧 전략 통합.

**Architecture:** 공식 Agent Skills 7개를 references/official/에 디렉토리째 포크하고, MCP 도구 참조를 8개로 축소 업데이트하며, /stitch analyze 커맨드를 신설하여 코드+시뮬레이터 분석 → 상세 프롬프트 산출 파이프라인을 추가한다. 기존 design/implement 파이프라인은 골격을 유지하면서 공식 스킬 참조, PRO/FLASH 크레딧 전략, DESIGN.md 폴백을 통합한다.

**Tech Stack:** Claude Code Plugin (markdown-based), Stitch Remote MCP (HTTP), gcloud ADC / STITCH_API_KEY

**Spec:** `docs/superpowers/specs/2026-03-19-stitch-plugin-overhaul-design.md`

---

## File Map

### 생성할 파일
| File | Responsibility |
|------|---------------|
| `skills/stitch-automation/references/official/` (7 dirs) | 공식 stitch-skills 포크 (원본 보존) |
| `skills/stitch-automation/references/workflows-analyze.md` | /stitch analyze 파이프라인 (신규) |
| `skills/stitch-automation/references/sdk.md` | @google/stitch-sdk 레퍼런스 (P2) |

### 수정할 파일
| File | Changes |
|------|---------|
| `.claude-plugin/plugin.json` | version 0.1.0 → 0.2.0 |
| `.claude-plugin/marketplace.json` | version 0.1.0 → 0.2.0 |
| `skills/stitch-automation/references/tools.md` | 14개 → 8개, 새 파라미터, deprecated 표기 |
| `skills/stitch-automation/SKILL.md` | 인증 플로우, Pattern 3 교체, analyze 참조 |
| `skills/stitch-automation/references/prompting.md` | enhance-prompt 참조 추가 |
| `skills/stitch-automation/references/workflows-design.md` | analysis.md 통합, PRO/FLASH, DESIGN.md 폴백 |
| `skills/stitch-automation/references/workflows-implement.md` | react-components/shadcn-ui 참조, get_screen name 필드 |
| `skills/stitch-automation/references/sheet-template.md` | analysis 산출물 템플릿 추가 |
| `commands/stitch.md` | analyze/design-md/remotion 서브커맨드, 인증/모델 업데이트 |

### 변경 없는 파일
| File | Reason |
|------|--------|
| `.mcp.json` | 동일한 Stitch Remote MCP URL |
| `hooks/hooks.json` | Stop hook 구조 변경 없음 |
| `hooks/scripts/design-verify-stop.sh` | 검증 루프 로직 유지 |
| `hooks/scripts/code-verify-stop.sh` | 검증 루프 로직 유지 |
| `skills/stitch-automation/references/cdp-iframe-helper.md` | chrome-viewer 패턴 유지 |

---

## Task 1: 공식 Agent Skills 포크

**Files:**
- Create: `skills/stitch-automation/references/official/stitch-design/`
- Create: `skills/stitch-automation/references/official/stitch-loop/`
- Create: `skills/stitch-automation/references/official/design-md/`
- Create: `skills/stitch-automation/references/official/enhance-prompt/`
- Create: `skills/stitch-automation/references/official/react-components/`
- Create: `skills/stitch-automation/references/official/remotion/`
- Create: `skills/stitch-automation/references/official/shadcn-ui/`

- [ ] **Step 1: github repo에서 공식 스킬 구조 확인**

```bash
# WebFetch로 repo 내용 확인
```
https://github.com/google-labs-code/stitch-skills 의 `skills/` 디렉토리 구조를 확인하여 각 스킬의 하위 파일 목록을 파악한다.

- [ ] **Step 2: 7개 스킬 디렉토리를 references/official/에 복제**

각 스킬 디렉토리의 모든 파일(SKILL.md, examples/, scripts/, resources/, references/, workflows/)을 원본 그대로 복사한다. 내용 수정 없음.

```bash
mkdir -p skills/stitch-automation/references/official
# 각 스킬 디렉토리 생성 후 파일 복사
```

- [ ] **Step 3: 업스트림 추적 주석 추가**

각 스킬 디렉토리의 SKILL.md 상단에 추적 주석을 추가한다:
```markdown
<!-- upstream: google-labs-code/stitch-skills@{latest-commit-hash}, synced: 2026-03-19 -->
```

- [ ] **Step 4: 포크 완료 확인**

```bash
ls -la skills/stitch-automation/references/official/
# 7개 디렉토리 존재 확인: stitch-design, stitch-loop, design-md, enhance-prompt, react-components, remotion, shadcn-ui
```

- [ ] **Step 5: 커밋**

```bash
git add skills/stitch-automation/references/official/
git commit -m "feat: fork official stitch-skills 7개 into references/official/"
```

---

## Task 2: 플러그인 매니페스트 버전 업데이트

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: plugin.json 버전 변경**

```json
// .claude-plugin/plugin.json
// "version": "0.1.0" → "version": "0.2.0"
```

- [ ] **Step 2: marketplace.json 버전 변경**

```json
// .claude-plugin/marketplace.json
// metadata.version: "0.1.0" → "0.2.0"
// plugins[0].version: "0.1.0" → "0.2.0"
```

- [ ] **Step 3: 확인**

```bash
grep -r '"version"' .claude-plugin/
# 모두 "0.2.0" 표시 확인
```

- [ ] **Step 4: 커밋**

```bash
git add .claude-plugin/
git commit -m "chore: bump plugin version to 0.2.0"
```

---

## Task 3: tools.md 업데이트 (MCP 도구 참조)

**Files:**
- Modify: `skills/stitch-automation/references/tools.md`

- [ ] **Step 1: 현재 tools.md 읽기**

`Read: skills/stitch-automation/references/tools.md` 전체 내용 확인.

- [ ] **Step 2: 제거된 도구 섹션 삭제**

`delete_project`과 `upload_screens_from_images` 섹션을 완전히 제거.

- [ ] **Step 3: 버그 누락 도구 표기**

Design Systems 섹션(create_design_system, update_design_system, list_design_systems, apply_design_system)에 다음 표기 추가:
```markdown
> ⚠️ **복구 대기**: 이 도구들은 현재 MCP 서버에서 버그로 누락됨 (Google 공식 확인).
> 대안: DESIGN.md 워크플로우 사용 (`references/official/design-md/` 참조)
> 참고: https://discuss.ai.google.dev/t/design-systems-category-missing-from-mcp-server-tools/126064
```

- [ ] **Step 3-1: list_projects에 view=shared 옵션 문서화**

`list_projects` 섹션의 filter 파라미터에 `view=shared` 옵션 추가:
```markdown
| `filter` | string | optional | `view=owned` (기본) or `view=shared` (공유 프로젝트) |
```

- [ ] **Step 4: get_screen deprecated 필드 표기**

`get_screen` 섹션에서:
- `name` 파라미터: required (format: `projects/{projectId}/screens/{screenId}`)
- `projectId`: deprecated (하위호환 유지, 향후 제거)
- `screenId`: deprecated (하위호환 유지, 향후 제거)

- [ ] **Step 5: modelId enum 추가**

AI Generation 도구들(generate_screen_from_text, edit_screens, generate_variants)에 추가:
```markdown
| `modelId` | string | optional | `MODEL_ID_UNSPECIFIED` (기본), `GEMINI_3_PRO` (50/월), `GEMINI_3_FLASH` (350/월) |
```

- [ ] **Step 6: deviceType enum 확장**

```markdown
### DeviceType
- `DEVICE_TYPE_UNSPECIFIED`
- `MOBILE` — mobile device layout
- `DESKTOP` — desktop/web layout
- `TABLET` — tablet layout (신규)
- `AGNOSTIC` — device-agnostic layout (신규)
```

- [ ] **Step 7: generate_variants의 variantOptions 스키마 추가**

```markdown
| `variantOptions` | object | required | 변형 생성 옵션 (아래 참조) |

**variantOptions 스키마:**
| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `variantCount` | number | 3 | 생성할 변형 수 (1-5) |
| `creativeRange` | string | `EXPLORE` | `REFINE` (미세조정) / `EXPLORE` (균형) / `REIMAGINE` (급진적) |
| `aspects` | array | all | `LAYOUT`, `COLOR_SCHEME`, `IMAGES`, `TEXT_FONT`, `TEXT_CONTENT` |
```

- [ ] **Step 8: Rate Limit 섹션 업데이트**

```markdown
## Rate Limits

| 모델 | 한도 | 용도 |
|------|------|------|
| `GEMINI_3_PRO` | 50 생성/월 | 최초 프로덕션 품질 생성 |
| `GEMINI_3_FLASH` | 350 생성/월 | 미세 수정, 반복 편집 |

MCP에 할당량 조회 도구가 없으므로 rate limit은 생성 시도 중 에러 응답으로 감지.
```

- [ ] **Step 8-1: External References 추가**

파일 하단에:
```markdown
## External References

- Official docs: https://stitch.withgoogle.com/docs/
- MCP setup: https://stitch.withgoogle.com/docs/mcp/setup
- MCP reference: https://stitch.withgoogle.com/docs/mcp/reference
- Agent Skills: https://github.com/google-labs-code/stitch-skills
- SDK: https://github.com/google-labs-code/stitch-sdk
- Community proxy: https://github.com/davideast/stitch-mcp
- Design Systems MCP bug: https://discuss.ai.google.dev/t/design-systems-category-missing-from-mcp-server-tools/126064
```

- [ ] **Step 9: 확인**

tools.md에 8개 도구만 active로 표기되고, deprecated/누락 도구가 올바르게 표기되었는지 확인.

- [ ] **Step 10: 커밋**

```bash
git add skills/stitch-automation/references/tools.md
git commit -m "feat: update tools.md — 8 active tools, new params, deprecated fields"
```

---

## Task 4: SKILL.md 업데이트

**Files:**
- Modify: `skills/stitch-automation/SKILL.md`

- [ ] **Step 1: 현재 SKILL.md 읽기**

전체 내용 확인.

- [ ] **Step 2: 인증 플로우 업데이트**

Prerequisites > Authentication Check를 다음으로 교체:
```markdown
### Authentication Check

Before any Stitch MCP operation, verify auth (우선순위순):

**1. STITCH_API_KEY 확인:**
```bash
echo "${STITCH_API_KEY:0:10}" 2>/dev/null
```

**2. gcloud ADC 확인 (API Key 없을 때):**
```bash
gcloud auth application-default print-access-token 2>/dev/null | head -c 20
```

**둘 다 실패 시:**
> Stitch 인증이 필요합니다. 아래 중 하나를 설정해주세요:
> - `STITCH_API_KEY` 환경변수 (Stitch 웹 → 프로필 → Exports에서 발급)
> - `gcloud auth login` → `gcloud auth application-default login`
```

- [ ] **Step 3: Pattern 3 교체**

Pattern 3 (Design System Consistency)를 다음으로 교체:
```markdown
### Pattern 3: Design System — DESIGN.md 워크플로우

MCP 디자인 시스템 도구가 현재 버그로 누락됨. DESIGN.md 기반 워크플로우로 대체:

```
1. create_design_system 호출 시도
2. tool_not_found 에러 → DESIGN.md 워크플로우로 폴백:
   - Read: references/official/design-md/ 참조
   - 프로젝트에 .stitch/DESIGN.md 생성
   - 프롬프트에 DESIGN.md 컨텍스트 포함
3. MCP 도구 성공 시 → 기존 플로우 유지
```
```

- [ ] **Step 4: Design Pipeline 테이블에 analyze 추가**

파이프라인 테이블 앞에 Analyze Pipeline 섹션 추가:
```markdown
## Analyze Pipeline (코드+시뮬레이터 분석 → 프롬프트)

`/stitch analyze` 요청 시 아래 5단계를 따른다. design 파이프라인의 입력 자료를 산출한다.

| Phase | 내용 | 핵심 |
|-------|------|------|
| 1 | 코드 분석 | Glob/Grep으로 화면·인터랙션·상태 전수 조사 |
| 2 | 시뮬레이터 분석 | 스크린샷 캡처 + 시각 분석 |
| 3 | Feature 분리 | 코드+시각 분석 종합하여 Feature 단위 분리 |
| 4 | 프롬프트 작성 | Feature별 상세 Stitch 프롬프트 (PRO 원샷 품질) |
| 5 | 산출물 | docs/plans/{date}-{app}-analysis.md 작성 |

### Pipeline 실행 시 반드시 참조

```
Read: references/workflows-analyze.md     ← Phase별 실행 절차 상세
Read: references/official/enhance-prompt/  ← 프롬프트 최적화
Read: references/prompting.md             ← Stitch 프롬프팅 가이드
```
```

- [ ] **Step 5: Design Pipeline 설명에 analysis.md 통합 안내 추가**

```markdown
### analysis.md 통합

`/stitch design` 실행 시 `docs/plans/*-analysis.md`가 존재하면:
- Phase 1-3 생략, analysis.md의 프롬프트를 직접 사용
- analysis.md가 design-sheet를 대체
- Phase 4부터 실행
```

- [ ] **Step 6: 크레딧 전략 섹션 추가**

Pattern 4 (Error Recovery) 뒤에 추가:
```markdown
### Pattern 5: 크레딧 관리 — PRO/FLASH 이중 전략

| 단계 | 모델 | 용도 |
|------|------|------|
| 최초 전체 화면 생성 | `GEMINI_3_PRO` | 프로덕션 품질 원샷 |
| 미세 수정/반복 편집 | `GEMINI_3_FLASH` | edit_screens 세부 조정 |

**실행 순서:**
1. PRO로 전체 화면 한 번에 생성 (원샷 품질 프롬프트)
2. 검증 후 미세 수정은 FLASH로 edit_screens
3. Rate limit 감지 시 PRO → FLASH 전환 제안

**파이프라인 시작 시:**
- 생성할 화면 수를 사용자에게 알림: "총 N개 화면을 PRO로 생성합니다 (PRO 한도: 50/월)"
- 사용자 확인 후 진행
```

- [ ] **Step 7: Pattern 5 (chrome-viewer)를 Pattern 6으로 번호 변경**

기존 Pattern 5를 Pattern 6으로 리넘버링.

- [ ] **Step 8: Workflow Reference 테이블 업데이트**

```markdown
| Analyze pipeline (코드+시뮬레이터 분석) | `references/workflows-analyze.md` |
| Official: enhance-prompt | `references/official/enhance-prompt/` |
| Official: design-md | `references/official/design-md/` |
| Official: react-components | `references/official/react-components/` |
| Official: shadcn-ui | `references/official/shadcn-ui/` |
| Official: stitch-loop | `references/official/stitch-loop/` |
| Official: remotion | `references/official/remotion/` |
| Official: stitch-design | `references/official/stitch-design/` |
| SDK reference | `references/sdk.md` |
```

- [ ] **Step 9: 확인**

SKILL.md의 인증, 패턴, 파이프라인 테이블이 모두 올바른지 검토.

- [ ] **Step 10: 커밋**

```bash
git add skills/stitch-automation/SKILL.md
git commit -m "feat: update SKILL.md — dual auth, DESIGN.md fallback, analyze pipeline, credit strategy"
```

---

## Task 5: workflows-analyze.md 생성 (신규 파이프라인)

**Files:**
- Create: `skills/stitch-automation/references/workflows-analyze.md`

- [ ] **Step 1: 스펙의 Pipeline 0 섹션 참조**

`docs/superpowers/specs/2026-03-19-stitch-plugin-overhaul-design.md`의 "Pipeline 0: Analyze" 섹션을 기반으로 작성.

- [ ] **Step 2: workflows-analyze.md 작성**

스펙의 Phase 1-5를 상세 실행 절차로 확장한다. 기존 workflows-design.md의 Phase 1 형식을 따르되, 시뮬레이터 스크린샷 분석과 Feature 분리가 핵심 차별점:

```markdown
# Analyze Pipeline (workflows-analyze)

Phase 1-5 execution guide for `/stitch analyze [app]`.

## Phase 1: 코드 분석
(기존 workflows-design.md Phase 1과 동일한 패턴)

## Phase 2: 시뮬레이터 스크린샷 캡처 및 분석
(Flutter: xcrun simctl / React: chrome-viewer)

## Phase 3: Feature 분리
(코드+시각 분석 종합 → Feature 단위 매핑)

## Phase 4: Feature별 상세 프롬프트 작성
(references/official/enhance-prompt/ + references/prompting.md 참조)
(PRO 원샷 품질 목표)

## Phase 5: 산출물 작성
(docs/plans/{date}-{app}-analysis.md → 사용자 확인)
```

산출물 템플릿은 스펙의 "산출물 구조" 섹션을 그대로 사용.

- [ ] **Step 3: 확인**

Phase 1-5가 모두 구체적 실행 절차(Glob/Grep 명령, 스크린샷 명령, 파일 경로)를 포함하는지 검토.

- [ ] **Step 4: 커밋**

```bash
git add skills/stitch-automation/references/workflows-analyze.md
git commit -m "feat: add workflows-analyze.md — code+simulator analysis pipeline"
```

---

## Task 6: workflows-design.md 업데이트

**Files:**
- Modify: `skills/stitch-automation/references/workflows-design.md`

- [ ] **Step 1: 현재 파일 읽기**

전체 내용 확인.

- [ ] **Step 2: Phase 3 업데이트 — enhance-prompt 참조**

Phase 3 Steps에 추가:
```markdown
1-1. Read `references/official/enhance-prompt/` → 공식 프롬프트 최적화 로직 참조
```

- [ ] **Step 3: Phase 4 시작 부분에 analysis.md 통합 분기 추가**

Phase 4 상단에:
```markdown
**analysis.md 통합:**
- `docs/plans/*-analysis.md` 존재 시 → 해당 파일의 Feature별 프롬프트를 직접 사용 (Phase 1-3 산출물 대체)
- 없으면 → Phase 2 design sheet의 프롬프트 사용 (하위 호환)
```

- [ ] **Step 4: Phase 4 Step 2 — DESIGN.md 폴백 로직**

기존 `create_design_system` 호출 부분을 교체:
```markdown
2. Create design system (DESIGN.md 폴백):
   ```
   Try: create_design_system(projectId, theme: {...})
   If tool_not_found error:
     → Read references/official/design-md/
     → 프로젝트에 .stitch/DESIGN.md 생성
     → "MCP 디자인 시스템 도구가 현재 비활성입니다. DESIGN.md로 대체합니다."
   If success:
     → Save designSystemId (기존 플로우)
   ```
```

- [ ] **Step 5: Phase 4 Step 3 — modelId 추가**

generate_screen_from_text 호출에 modelId 추가:
```markdown
   generate_screen_from_text(
     projectId: "{projectId}",
     prompt: "{optimized prompt}",
     deviceType: "MOBILE" or "DESKTOP" or "TABLET" or "AGNOSTIC",
     modelId: "GEMINI_3_PRO"
   )
```

- [ ] **Step 6: Phase 6 — FLASH 모델 사용 명시**

Phase 6 Fix 섹션에:
```markdown
**모델:** 수정/재생성에는 `GEMINI_3_FLASH` 사용 (크레딧 절약)
- edit_screens(..., modelId: "GEMINI_3_FLASH")
- generate_screen_from_text(..., modelId: "GEMINI_3_FLASH")
```

- [ ] **Step 7: Phase 4 마지막에 stitch-loop 참조 추가**

```markdown
6. 멀티페이지 일괄 생성 옵션:
   - 화면 수가 5개 이상일 때 `references/official/stitch-loop/` 패턴 참조 가능
   - 단일 프롬프트로 여러 화면을 일괄 생성하여 크레딧 효율화
```

- [ ] **Step 8: 확인 후 커밋**

```bash
git add skills/stitch-automation/references/workflows-design.md
git commit -m "feat: update workflows-design.md — analysis.md integration, PRO/FLASH, DESIGN.md fallback"
```

---

## Task 7: workflows-implement.md 업데이트

**Files:**
- Modify: `skills/stitch-automation/references/workflows-implement.md`

- [ ] **Step 1: 현재 파일 읽기**

전체 내용 확인.

- [ ] **Step 2: Phase 1 — get_screen name 필드 전환**

get_screen 호출 패턴을 name 기반으로 업데이트:
```markdown
   get_screen(name: "projects/{projectId}/screens/{screenId}",
              projectId: "{projectId}",    # deprecated, 하위호환
              screenId: "{screenId}")       # deprecated, 하위호환
```

- [ ] **Step 3: Phase 4 — React 경로에 공식 스킬 참조 추가**

Phase 4 React/Next.js 섹션에:
```markdown
2. **React/Next.js:**
   ```
   Read references/official/react-components/ → 컴포넌트 변환 전략
   Read references/official/shadcn-ui/ → shadcn/ui 통합 가이드 (선택)
   ```
```

- [ ] **Step 4: 확인 후 커밋**

```bash
git add skills/stitch-automation/references/workflows-implement.md
git commit -m "feat: update workflows-implement.md — get_screen name field, react-components/shadcn refs"
```

---

## Task 8: prompting.md 업데이트

**Files:**
- Modify: `skills/stitch-automation/references/prompting.md`

- [ ] **Step 1: 현재 파일 읽기**

전체 내용 확인.

- [ ] **Step 2: 상단에 공식 enhance-prompt 참조 추가**

파일 상단에:
```markdown
> **공식 참조**: `references/official/enhance-prompt/`에 Google 공식 프롬프트 최적화 스킬이 포크되어 있습니다.
> 이 문서는 Stitch 프롬프팅 기본 가이드이며, enhance-prompt 스킬과 함께 사용하면 더 나은 결과를 얻을 수 있습니다.
```

- [ ] **Step 3: PRO 원샷 품질 섹션 추가**

Pro Tips 뒤에:
```markdown
## PRO 원샷 품질 전략

PRO 모델(50/월)로 첫 생성에서 최대 품질을 얻으려면:

1. **가능한 모든 디테일 포함**: 레이아웃, 컴포넌트, 색상, 폰트, 간격까지 명시
2. **시뮬레이터 분석 활용**: `/stitch analyze`로 사전 분석 → 현재 앱의 색상/분위기를 프롬프트에 반영
3. **네거티브 프롬프트**: "No sidebar", "No gradient background" 등 불필요한 요소 명시적 제외
4. **디바이스 명시**: `MOBILE`, `DESKTOP`, `TABLET`, `AGNOSTIC` 중 정확히 지정
5. **enhance-prompt 참조**: `references/official/enhance-prompt/` 로직으로 프롬프트 자동 강화
```

- [ ] **Step 4: 확인 후 커밋**

```bash
git add skills/stitch-automation/references/prompting.md
git commit -m "feat: update prompting.md — enhance-prompt ref, PRO one-shot strategy"
```

---

## Task 9: sheet-template.md 업데이트

**Files:**
- Modify: `skills/stitch-automation/references/sheet-template.md`

- [ ] **Step 1: 현재 파일 읽기**

전체 내용 확인.

- [ ] **Step 2: Analysis 산출물 템플릿 추가**

파일 마지막에 스펙의 "산출물 구조" 그대로 추가:

```markdown
---

## Analysis Sheet Template (Code+Simulator→Prompts)

Use this template for `/stitch analyze` pipeline. Save to `docs/plans/{date}-{app}-analysis.md`.

(스펙의 산출물 구조 마크다운 템플릿 전체 삽입)
```

- [ ] **Step 3: 확인 후 커밋**

```bash
git add skills/stitch-automation/references/sheet-template.md
git commit -m "feat: update sheet-template.md — add analysis sheet template"
```

---

## Task 10: commands/stitch.md 업데이트

**Files:**
- Modify: `commands/stitch.md`

- [ ] **Step 1: 현재 파일 읽기**

전체 내용 확인.

- [ ] **Step 2: Usage 테이블에 신규 서브커맨드 추가**

```markdown
| `analyze` | `/stitch analyze [app]` | 코드+시뮬레이터 분석 → Feature별 상세 프롬프트 → analysis.md 산출 |
| `design-md` | `/stitch design-md` | DESIGN.md 생성/업데이트 (official/design-md 참조) |
| `remotion` | `/stitch remotion` | **P2** 워크스루 영상 생성 (official/remotion 참조) |
```

- [ ] **Step 3: /stitch analyze 섹션 추가**

Usage 테이블 뒤, `/stitch design` 섹션 앞에:
```markdown
## `/stitch analyze [app]` — 코드+시뮬레이터 분석

코드와 실행 화면을 분석하여 Feature별 상세 프롬프트를 산출한다.

### 실행 절차

1. **파이프라인 레퍼런스 로드**:
   ```
   Read: references/workflows-analyze.md
   Read: references/official/enhance-prompt/
   Read: references/prompting.md
   ```

2. **Phase 1-5 실행** (workflows-analyze.md 참조)

3. **산출물**: `docs/plans/{date}-{app}-analysis.md`

4. **사용자 확인 요청**
```

- [ ] **Step 4: /stitch design 섹션 업데이트**

다음 변경사항을 `/stitch design` 섹션에 반영:

1. analysis.md 통합 분기 추가:
```markdown
### analysis.md 통합
- `docs/plans/*-analysis.md` 존재 시: Phase 1-3 생략, Phase 4부터 실행
- analysis.md의 Feature별 프롬프트를 직접 사용 (design-sheet 대체)
- 없으면: 기존 Phase 1-3 실행 (하위 호환)
```

2. Phase 4-5 실행 순서에서 `create_design_system`/`apply_design_system` 직접 호출 제거 → DESIGN.md 폴백 분기 추가:
```markdown
- create_design_system 호출 시도 → tool_not_found 시 DESIGN.md 워크플로우 전환
- "MCP 디자인 시스템 도구가 현재 비활성입니다. DESIGN.md로 대체합니다." 메시지
```

3. modelId 파라미터 추가:
```markdown
generate_screen_from_text(..., modelId: "GEMINI_3_PRO")
```

4. 크레딧 전략 안내:
```markdown
- PRO로 최초 전체 화면 생성 → 검증 후 미세 수정은 FLASH로 edit_screens
```

- [ ] **Step 5: /stitch implement 섹션 업데이트**

다음 변경사항을 `/stitch implement` 섹션에 반영:
```markdown
- Phase 4 React 경로: `references/official/react-components/` 참조 추가
- Phase 4 React+shadcn 경로: `references/official/shadcn-ui/` 참조 추가
- get_screen 호출: name 필드 우선 사용 안내
```

- [ ] **Step 6: /stitch design-md 섹션 추가**

```markdown
## `/stitch design-md` — DESIGN.md 생성/업데이트

1. `Read: references/official/design-md/` → 실행 절차 참조
2. 입력: Stitch 프로젝트 컨텍스트 또는 URL
3. 산출물: `.stitch/DESIGN.md`
```

- [ ] **Step 6: /stitch remotion 섹션 추가**

```markdown
## `/stitch remotion` — 워크스루 영상 생성 (P2)

1. `Read: references/official/remotion/` → 실행 절차 참조
2. 입력: Stitch 프로젝트
3. 산출물: Remotion 프로젝트 + MP4
4. **P2**: 초기 구현에서 제외 가능
```

- [ ] **Step 7: /stitch create, edit, variants 업데이트**

각 섹션에 새 deviceType/modelId 지원 명시.

- [ ] **Step 8: /stitch theme 업데이트**

```markdown
## `/stitch theme` — 디자인 시스템

1. `create_design_system` 호출 시도
2. **MCP 도구 없을 시**: DESIGN.md 워크플로우로 전환 (`/stitch design-md` 참조)
3. MCP 도구 사용 가능 시: 기존 플로우 유지
```

- [ ] **Step 9: 인증 에러 핸들링 업데이트**

Error Handling 섹션에서 gcloud 전용 안내를 이중 인증 안내로 변경:
```markdown
- STITCH_API_KEY 환경변수 (Stitch 웹 → 프로필 → Exports에서 발급)
- gcloud auth application-default login 실행
```

- [ ] **Step 10: Rate Limit 에러 핸들링 추가**

Error Handling 섹션에 Rate Limit 대응 로직 추가:
```markdown
### Rate Limit 대응

파이프라인 시작 시:
1. 생성할 화면 수 계산
2. "총 N개 화면을 PRO로 생성합니다 (PRO 한도: 50/월)" 안내
3. 사용자 확인 후 진행

생성 중 rate limit 에러 수신 시:
1. PRO rate limit → "PRO 한도에 도달했습니다. FLASH로 전환할까요?"
2. 사용자 승인 시 FLASH로 전환하여 계속
3. FLASH도 rate limit → 파이프라인 일시 정지
```

- [ ] **Step 11: 디자인 시스템 도구 누락 에러 핸들링 추가**

Error Handling 섹션에 추가:
```markdown
### 디자인 시스템 도구 누락

MCP create_design_system 호출 시 도구 미발견 →
자동으로 DESIGN.md 워크플로우로 전환 →
"MCP 디자인 시스템 도구가 현재 비활성 상태입니다. DESIGN.md 워크플로우로 대체합니다." 메시지
```

- [ ] **Step 12: 확인 후 커밋**

```bash
git add commands/stitch.md
git commit -m "feat: update stitch.md — analyze/design-md/remotion commands, dual auth, credit strategy"
```

---

## Task 11: SDK Reference 작성 (P2)

**Files:**
- Create: `skills/stitch-automation/references/sdk.md`

> **우선순위 P2** — Task 1-10 완료 후 진행. 초기 구현에서 제외 가능.

- [ ] **Step 1: sdk.md 작성**

스펙의 SDK Reference 섹션 기반으로 `@google/stitch-sdk` 사용법 문서화:
- Stitch, Project, Screen 클래스 API
- stitchTools() Vercel AI SDK 통합
- STITCH_API_KEY 인증
- npm install 방법

- [ ] **Step 2: 커밋**

```bash
git add skills/stitch-automation/references/sdk.md
git commit -m "feat: add sdk.md — @google/stitch-sdk reference (P2)"
```

---

## Task 12: 최종 통합 검증

- [ ] **Step 1: 전체 파일 구조 확인**

```bash
find skills/stitch-automation/references/ -type f | sort
```

expected:
```
references/cdp-iframe-helper.md
references/official/design-md/...
references/official/enhance-prompt/...
references/official/react-components/...
references/official/remotion/...
references/official/shadcn-ui/...
references/official/stitch-design/...
references/official/stitch-loop/...
references/prompting.md
references/sdk.md (P2)
references/sheet-template.md
references/tools.md
references/workflows-analyze.md
references/workflows-design.md
references/workflows-implement.md
```

- [ ] **Step 2: 상호 참조 검증**

각 파일에서 다른 파일을 참조하는 경로가 올바른지 확인:
```bash
grep -r "references/" skills/stitch-automation/ --include="*.md" | grep -v official/ | head -30
```

- [ ] **Step 3: MCP 도구 확인**

Stitch MCP 도구가 정상 로드되는지 확인:
```
ToolSearch query: "+stitch list_projects"
```

- [ ] **Step 4: 인증 확인**

```bash
echo "${STITCH_API_KEY:0:10}" 2>/dev/null || gcloud auth application-default print-access-token 2>/dev/null | head -c 20
```

- [ ] **Step 5: 최종 커밋**

```bash
git status
# 커밋되지 않은 변경이 있으면 해당 파일만 추가
git add skills/ commands/ .claude-plugin/
git commit -m "chore: v0.2.0 overhaul — final integration verification"
```
