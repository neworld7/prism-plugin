# Design Pipeline — `/prism design <feature|all>`

> **v4.5.0:** Refero MCP의 실제 앱 스크린샷을 직접 참조하여 구현하는 **범용 파이프라인**.
> 어떤 앱을 만들든, 어떤 레퍼런스를 선택하든 동일한 프로세스가 적용된다.

---

## 전체 흐름

```
D1: 컨텍스트 로드 → 타겟 앱 화면 목록 + 레퍼런스 앱 정보
D2: Refero 매핑 → 각 화면에 레퍼런스 스크린/플로우 매칭
D3: 콘텐츠 치환 규칙 생성 → 레퍼런스 → 타겟 도메인 변환 맵
D4: 구현 → Refero description + 치환 규칙 기반 코드 작성
D5: 검증 → 레퍼런스와 구현 비교
D6: 완료
```

---

### D1: 컨텍스트 로드

**Goal:** 타겟 앱의 화면 목록과 레퍼런스 앱 정보를 확보한다.

**Steps:**
1. `.prism/analysis.md` 로드 → 타겟 앱 정보 추출:
   - 앱 이름, 도메인, 타겟 사용자
   - Feature 목록 + 화면 테이블 (화면 ID, 이름, 축 태그, 코드 파일)
   - 핵심 엔티티/데이터 모델 (A4에서 추출된 것)

2. `.prism/preview/index.md` 로드 → 레퍼런스 앱 정보 추출:
   - Primary/Secondary 레퍼런스 앱 이름
   - 선택된 디자인 방향 (Phase 3에서 확정된 것)

3. `./DESIGN.md` 로드 → 디자인 시스템 토큰:
   - 색상 팔레트, 타이포, 간격, 모서리 규칙

### D2: Refero 매핑

**Goal:** 타겟 앱의 각 화면에 대해 Refero에서 **가장 적합한 레퍼런스 스크린 또는 플로우**를 매칭한다.

#### Screen 매핑 (개별 화면)

**검색 쿼리 구성 규칙:**

축 태그(Axis Tag)와 화면의 기능적 역할을 조합하여 검색한다. 레퍼런스 앱 이름을 쿼리에 포함하면 해당 앱 우선, 생략하면 전체 DB에서 최적 매칭.

```
쿼리 패턴: "{레퍼런스앱?} {화면 기능 키워드}"

| 축 태그 | 쿼리 키워드 |
|---------|-----------|
| Primary (홈/대시보드) | "home feed" / "main dashboard" / "home screen" |
| Primary (목록/그리드) | "list view" / "grid gallery" / "collection" |
| Primary (상세) | "detail page" / "item detail" / "content detail" |
| Primary (에디터/폼) | "text editor" / "form input" / "compose" |
| Primary (타이머/도구) | "timer" / "player" / "tool screen" |
| Primary (통계/차트) | "analytics dashboard" / "stats chart" / "insights" |
| Primary (채팅/메시징) | "chat conversation" / "messaging" / "AI chat" |
| Primary (프로필) | "profile" / "account settings" / "user profile" |
| Primary (검색) | "search results" / "explore discover" |
| Primary (설정) | "settings preferences" / "app settings" |
| Data:empty | "empty state" / "no content placeholder" |
| Data:skeleton | "skeleton loading" / "placeholder shimmer" |
| Data:error | "error state retry" / "connection error" |
| Overlay:bottom-sheet | "bottom sheet" / "action sheet options" |
| Overlay:dialog | "confirmation dialog" / "alert modal" |
| Overlay:snackbar | "toast notification" / "snackbar" |
| Interaction:edit-mode | "edit mode selection" / "multi-select" |
| Interaction:search | "search bar filter" / "search active" |
| Interaction:drag | "drag reorder" / "sortable list" |
| Auth:login | "sign in" / "login form" |
| Auth:onboarding | "onboarding welcome" / "tutorial walkthrough" |
| Auth:free-tier | "paywall" / "subscription upgrade premium" |
```

**실행:**

```
각 화면에 대해:

1. refero_search_screens 호출:
   mcp__refero__refero_search_screens({
     query: "{레퍼런스앱} {화면 기능 키워드}",
     platform: "ios"
   })

2. 결과에서 최적 매칭 선정:
   - 레퍼런스 앱의 스크린 우선 (app_name 일치)
   - page_types, ux_patterns, ui_elements가 타겟 화면과 유사한 것
   - description의 레이아웃/구성요소가 타겟 화면의 요구사항과 맞는지 확인

3. 매칭이 안 되면:
   - 레퍼런스 앱 이름을 빼고 범용 키워드로 재검색
   - 그래도 안 되면 → "매핑 없음 — 자체 디자인" 표시
```

#### Flow 매핑 (멀티스텝 화면)

analysis.md에서 `Multi-State` 축 태그가 붙은 화면들은 개별 Screen이 아닌 **Flow 단위**로 매칭한다.

```
mcp__refero__refero_search_flows({
  query: "{플로우 기능 키워드}",
  platform: "ios"
})

| 플로우 유형 | 쿼리 키워드 |
|-----------|-----------|
| 온보딩 | "onboarding" / "signing up" / "welcome tutorial" |
| 로그인 | "sign in" / "logging in" / "authentication" |
| 촬영/스캔 | "camera capture" / "scan document" / "photo upload" |
| 완료/축하 | "completion" / "success celebration" / "goal achieved" |
| 타이머/세션 | "timer session" / "workout session" / "meditation" |
| 결제/구독 | "subscription" / "checkout" / "upgrade premium" |
| 검색→결과 | "search flow" / "filter and results" |
| 생성/작성 | "create new" / "compose post" / "add item" |

→ flow_id로 상세 확인:
  mcp__refero__refero_get_flow({ flow_id: {id} })
→ 각 step의 화면 description + 전환 로직 확보
```

#### 매핑 파일 (.prism/refero-mapping.md)

```markdown
# {앱 이름} · Refero Mapping

## 레퍼런스
- Primary: {앱1} ({선택 이유})
- Secondary: {앱2} ({선택 이유})

## Feature {N}: {Feature명}

### Screen 매핑
| # | 타겟 화면 | Refero ID | 참조 앱 | 화면 유형 | URL |
|---|----------|-----------|--------|----------|-----|
| {id} | {화면명} | {screen_id} | {앱} | {type} | https://refero.design/s/{id} |
| {id} | {화면명} | — | — | 자체 디자인 | — |

### Flow 매핑
| # | 타겟 플로우 | Refero Flow ID | 참조 앱 | Steps | URL |
|---|-----------|----------------|--------|-------|-----|
| F-{n} | {플로우명} | {flow_id} | {앱} | {n} | https://refero.design/f/{id} |
```

> **매핑률 목표:** 80% 이상. 미달 시 추가 검색 또는 레퍼런스 앱 확장 제안.

### D3: 콘텐츠 치환 규칙 생성

**Goal:** 레퍼런스 앱의 도메인을 타겟 앱의 도메인으로 변환하는 **치환 맵**을 자동 생성한다.

> **이 단계가 "범용성"의 핵심.** 레퍼런스가 Instagram이든 Airbnb이든 Spotify이든, 타겟이 독서 앱이든 피트니스 앱이든, 치환 규칙만 바꾸면 동일한 파이프라인이 작동한다.

**자동 생성 프로세스:**

```
1. analysis.md의 "앱 컨텍스트"에서 타겟 앱의 핵심 엔티티 추출:
   예: 독서 앱 → Book, Note, Quote, ReadingSession, Club
   예: 피트니스 앱 → Workout, Exercise, Meal, Goal, Challenge

2. Refero 레퍼런스의 description에서 원본 앱의 핵심 엔티티 추출:
   예: Instagram → Post, Story, Reel, Comment, Profile
   예: Airbnb → Listing, Booking, Review, Host, Experience

3. 엔티티 간 역할 매핑 (자동 추론):
   | 역할 | 레퍼런스 (Instagram) | 타겟 (독서 앱) |
   |------|--------------------|--------------| 
   | 메인 콘텐츠 | Post (사진/영상) | Book (표지 이미지) |
   | 콘텐츠 목록 | Feed | 서재 / 책 목록 |
   | 콘텐츠 상세 | Post Detail | 책 상세 |
   | 사용자 반응 | Like/Comment/Share | 진행률/메모/인용구 |
   | 실시간 콘텐츠 | Story | 읽고 있는 책 |
   | 사용자 프로필 | Profile + grid | 프로필 + 독서 통계 |
   | 탐색 | Explore grid | 추천/탐색 |
   | 소셜 | DM/Comment | 클럽/토론 |

4. 치환 맵을 .prism/substitution-map.md에 저장
```

**치환 맵 파일 (.prism/substitution-map.md):**

```markdown
# 콘텐츠 치환 맵

## 엔티티 치환
| 레퍼런스 | 타겟 |
|---------|------|
| {원본 엔티티} | {타겟 엔티티} |

## UI 요소 치환
| 레퍼런스 UI | 타겟 UI |
|-----------|--------|
| {원본 요소} | {타겟 요소} |

## 텍스트 치환
| 레퍼런스 텍스트 | 타겟 텍스트 |
|-------------|-----------|
| {원본} | {타겟 — analysis.md A5 Copy에서 추출} |
```

### D4: 구현 — Refero Description + 치환 규칙

**Goal:** Refero description의 레이아웃/구조/스타일을 그대로 가져오되, 치환 맵에 따라 콘텐츠를 변환하여 타겟 앱 코드를 작성한다.

**구현 절차 (화면당):**

```
1. refero_get_screen으로 상세 description 로드

2. description에서 구현 스펙 추출:
   - 레이아웃 구조 (vertical stack, grid, horizontal scroll 등)
   - 컴포넌트 목록 + 배치 순서
   - 색상, 타이포 위계, 간격/패딩
   - 아이콘 스타일, 모서리, 그림자
   - 특수 효과 (gradient, blur 등)

3. 치환 맵 적용:
   - description의 원본 엔티티 → 타겟 엔티티로 교체
   - description의 원본 텍스트 → 타겟 텍스트로 교체 (analysis.md A5 Copy 참조)
   - description의 원본 색상 → DESIGN.md 토큰으로 교체

4. 코드 작성:
   - description의 레이아웃 → 프레임워크 위젯/컴포넌트
   - DESIGN.md의 디자인 토큰 적용
   - analysis.md A2 Functional Scan의 기능 요소 반영 (버튼, 네비게이션, 인터랙션)

5. Flow 화면의 경우:
   - refero_get_flow로 전체 step 로드
   - step 간 전환 로직을 코드에 반영
   - 각 step을 개별 화면 또는 상태로 구현
```

> **원칙:** 구조/레이아웃/스타일은 Refero에서 가져오고, 콘텐츠/기능은 analysis.md에서 가져온다. 색상/폰트는 DESIGN.md 토큰을 적용한다.

### D5: 검증

**체크리스트:**

```
구조 일치:
- [ ] 레이아웃 구조가 Refero 레퍼런스와 동일
- [ ] 컴포넌트 배치 순서 동일
- [ ] 네비게이션 패턴 동일

스타일 일치:
- [ ] 색상 절제도가 레퍼런스와 유사
- [ ] 타이포 위계 동일
- [ ] 아이콘 스타일 일관
- [ ] 여백/간격 수준 유사

콘텐츠 적합:
- [ ] 타겟 앱 도메인으로 적절히 치환
- [ ] UI 텍스트가 앱 보이스와 일치 (analysis.md A5)
- [ ] 기능 요소가 누락 없이 반영 (analysis.md A2)
```

**검증 방법:**
1. 구현된 화면 스크린샷 촬영 (시뮬레이터 또는 브라우저)
2. Refero 레퍼런스 URL (refero.design/s/{id})과 비교
3. 체크리스트 pass/fail → gaps > 0이면 D4로 돌아가서 수정

### D6: 완료

1. Feature 매핑 + 구현 + 검증 완료
2. 상태 파일 업데이트 (completed_features에 추가)
3. 다음 Feature 또는 전체 완료

---

## Feature 루프

```
Feature 0 → D1 → D2(매핑) → D3(치환규칙) → D4(구현) → D5(검증) → D6
Feature 1 → D1 → D2 → D3 → D4 → D5 → D6
...
```

> **D3(치환 규칙)은 첫 Feature에서 1회 생성 후 이후 Feature에서 재사용한다.** 새로운 엔티티가 등장하면 치환 맵에 추가.

---

## `/prism design resume`

```
1. .claude/prism-design-pipeline.local.md 존재 확인
2. 상태에서 진행 상황 읽기 (mode, feature, completed_features, mapping_status)
3. 중단 지점부터 재개 (매핑 중 → D2, 구현 중 → D4)
```

---

## Stitch 모드 (선택적)

```
/prism design all --stitch
```

Refero 대신 기존 Stitch AI 생성 파이프라인 사용. 기본값은 Refero 모드.
