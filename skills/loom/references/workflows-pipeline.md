# Loom Orchestration Pipeline

통합 파이프라인 실행 가이드. Analyze (A1-A6) → Design (D1-D6).

## Analyze Pipeline — `/loom analyze [app]`

### A1: 코드 분석

**Goal:** 프로젝트 소스 코드에서 모든 화면, 인터랙션, 상태를 추출한다.

**Steps:**

1. 프로젝트 스택 판별:
   - Flutter: `Glob: lib/**/*.dart`
   - React: `Glob: src/**/*.{tsx,jsx}`
   - Next.js: `Glob: app/**/*.{tsx,jsx}`

2. 화면/페이지 추출:
   - Flutter: `Grep: class.*Screen|class.*Page|class.*View` in `lib/`
   - React/Next: `Grep: export default|export function` in page files

3. 라우트/네비게이션 구조:
   - Flutter: `Grep: GoRoute|MaterialPageRoute|Navigator.push`
   - React/Next: 파일 기반 라우팅 or `Grep: useRouter|Link`

4. 인터랙션 추출:
   - `Grep: onTap|onPressed|onClick|onSubmit|GestureDetector`

5. 상태 추출:
   - `Grep: Loading|Error|Empty|CircularProgressIndicator|Shimmer|skeleton`

**Output:** 화면 목록, 인터랙션 목록, 상태 목록.

### A2: 시뮬레이터 스크린샷 캡처 및 분석

**Goal:** 실제 실행 화면을 캡처하고 시각적으로 분석하여 현재 디자인 상태를 파악한다.

**Steps:**

1. 앱 실행 확인:
   - Flutter: iOS 시뮬레이터 또는 Android 에뮬레이터 실행 여부 확인
   - React/Next.js: dev 서버 실행 여부 확인 (`localhost:{port}`)
   - 미실행 시 사용자에게 앱 실행 요청

2. **[필수] idb를 이용한 화면 조작 + 스크린샷 캡처:**

   코드 분석에서 발견된 화면/라우트를 **idb(iOS Development Bridge)로 직접 조작**하여 각 화면에 도달한 후 스크린샷을 캡처한다.

   - Flutter (iOS 시뮬레이터 — idb 사용):
     ```bash
     idb --help 2>/dev/null || pip install fb-idb
     idb list-targets
     idb ui tap {x} {y}
     idb ui swipe {x1} {y1} {x2} {y2}
     idb ui text "검색어"
     idb screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```

   - Flutter (idb 없을 시 폴백):
     ```bash
     xcrun simctl io booted screenshot /tmp/analyze-{screen}.png
     sips -Z 1200 /tmp/analyze-{screen}.png
     ```

   - React/Next.js:
     - chrome-viewer: `cv_navigate` → `cv_click` → `cv_screenshot`
     - Playwright: `browser_navigate` → `browser_click` → `browser_take_screenshot`

   **필수 절차:**
   1. A1에서 발견된 **모든 화면 목록**을 순회
   2. 각 화면에 idb 조작으로 도달
   3. 도달 후 스크린샷 캡처
   4. 스크롤이 필요한 화면은 상단/하단 모두 캡처
   5. 상태별 화면(로딩, 에러, 빈 상태)도 가능하면 트리거하여 캡처

3. 각 스크린샷 Read → 시각 분석:
   - 레이아웃 구조, 컴포넌트 유형, 색상 팔레트, 타이포그래피
   - 현재 디자인 품질/문제점
   - idb 조작 중 발견한 인터랙션 특성

**Output:** 화면별 스크린샷 + 시각 분석 메모.

### A3: Feature 분리

**Goal:** 코드 분석 + 스크린샷 분석 결과를 종합하여 Feature 단위로 화면을 분류한다.

**Steps:**

1. 화면을 기능 단위(Feature)로 그룹화
2. 각 Feature에 매핑: 포함 화면 목록, 인터랙션, 상태

**Output:** Feature 목록 + 화면/인터랙션/상태 매핑 구조.

### A4: Feature별 원시 프롬프트 작성

**Goal:** 각 화면에 대해 UX 중심 프롬프트 초안을 작성한다.

**철학:** Vibe Design — AI에 자유도를 주되 방향성은 명확히. 구현 디테일은 AI가 결정.

**프롬프트 요소:**
- 화면 목적 (1줄)
- 무드/바이브 (2-3 형용사)
- 핵심 섹션 (번호 매긴 고수준 레이아웃)
- UI 컴포넌트 (이름만)
- 사용자 흐름
- 앱 컨텍스트, 플랫폼, 레퍼런스, 제외 사항

**금지 사항:**
- ❌ hex 코드, px 값, 특정 폰트명
- ❌ border-radius, shadow, opacity 수치

**품질 기준:**
- 화면당 150-400자
- 프롬프트 지시문은 영어
- 마지막에 반드시: `All UI text, labels, buttons, placeholders, and content must be in Korean (한국어).`

**Output:** Feature별 원시 UX-First 프롬프트.

### A5: 프롬프트 최적화 — 공식 스킬 위임

**Goal:** 원시 프롬프트를 Stitch에 최적화된 프롬프트로 변환한다.

**실행:**
```
Skill("enhance-prompt") 호출
→ A4에서 작성한 원시 프롬프트를 전달
→ 공식 스킬이 UI/UX 키워드, 분위기, 디자인 시스템 컨텍스트를 추가
→ 최적화된 프롬프트를 반환
```

**Output:** Stitch 최적화된 프롬프트.

### A6: 산출물 작성

**Goal:** 분석 결과를 단일 마크다운 파일로 작성하고 사용자 확인을 받는다.

**Steps:**
1. 파일 경로: `.loom/{date}-{app}-analysis.md`
2. `references/sheet-template.md`의 Analysis Sheet Template에 따라 작성
3. 사용자 확인 요청

**Output:** `.loom/{date}-{app}-analysis.md`

---

## Design Pipeline — `/loom design <feature|all>`

### Feature Routing (all 모드 전용)

> 단일 Feature 모드에서는 건너뛴다.

1. Read `.claude/loom-design-pipeline.local.md` → `feature` 필드 확인
2. analysis.md에서 해당 Feature 프롬프트만 추출
3. 다른 Feature의 프롬프트는 무시

### D1: analysis.md 로드

**Goal:** 분석 산출물에서 Feature 프롬프트를 로드한다.

**Steps:**
1. `.loom/*-analysis.md` 존재 확인
2. 없으면 사용자에게 `/loom analyze` 먼저 실행 안내
3. 있으면 해당 Feature의 프롬프트 로드

### D2: 디자인 시스템 — 공식 스킬 위임

**Goal:** Stitch 프로젝트의 디자인 시스템을 생성한다.

**실행:**
```
Skill("design-md") 호출
→ 프로젝트 컨텍스트와 analysis.md의 분위기/스타일 정보 전달
→ 공식 스킬이 DESIGN.md 생성
```

### D3: 디자인 생성 — 공식 스킬 위임

**Goal:** Feature 프롬프트로 Stitch 디자인을 생성한다.

**실행:**
```
Skill("stitch-design") 호출
→ analysis.md의 Feature 프롬프트 전달
→ 공식 스킬이 create_project, generate_screen_from_text 등 MCP 도구 호출
→ 생성된 프로젝트/화면 정보 반환
```

생성 완료 후 상태 파일의 `phase`를 `verify`로 변경.

### D4: 검증

**Goal:** 생성된 디자인을 analysis.md의 프롬프트와 크로스체크한다.

**실행 주체:** loom 자체 (읽기 전용 MCP 직접 호출)

**Steps:**
1. 각 화면에 대해:
   ```
   get_screen(name: "projects/{projectId}/screens/{screenId}") → downloadUrls
   web_fetch(downloadUrl.screenshot) → /tmp/loom-{screenName}.png
   sips -Z 1200 /tmp/loom-{screenName}.png
   Read /tmp/loom-{screenName}.png → 시각 검증
   ```

2. 체크리스트:
   - [ ] 화면이 존재하고 설명과 매칭
   - [ ] 핵심 UI 컴포넌트 존재
   - [ ] 인터랙션이 시각적으로 표현
   - [ ] 상태 화면 포함

3. gaps 카운트:
   ```
   MISSING_SCREEN: N
   MISSING_INTERACTION: N
   MISSING_STATE: N
   total_gaps: N
   ```

**Transition:** gaps == 0 → D6, gaps > 0 → D5.

### D5: 수정 — 공식 스킬 위임

**Goal:** 검증에서 발견된 gaps를 수정한다.

**실행:**
```
Skill("stitch-design") 호출
→ 수정이 필요한 화면과 수정 프롬프트 전달
→ 공식 스킬이 edit_screens 또는 generate_screen_from_text 호출
```

**Transition:** D4로 복귀.

### D6: 완료

1. `<promise>DESIGN_VERIFIED</promise>` 출력
2. Stop hook이 감지하고:
   - 단일 Feature: 상태 파일 삭제 → allow
   - All + 다음 Feature: 상태 파일 전환 → block → 다음 Feature로
   - All + 마지막: 상태 파일 삭제 → allow
