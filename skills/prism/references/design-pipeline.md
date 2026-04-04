# Design Pipeline — `/prism design <feature|all>`

> **v4.7.0:** Refero 레퍼런스 + Stitch AI 디자인 생성 **범용 파이프라인**.
> Refero에서 레이아웃/구조를 참조하고, Stitch에서 시각 디자인을 생성한다.
> 코드 작성은 `/prism implement`에서 별도로 진행한다.

---

## 전체 흐름

```
D1: 컨텍스트 로드 → 타겟 앱 화면 목록 + 레퍼런스 앱 정보 + 디자인 토큰
D2: Refero 매핑 → 각 화면에 레퍼런스 스크린/플로우 매칭
D3: 콘텐츠 치환 규칙 생성 → 레퍼런스 → 타겟 도메인 변환 맵
D4: Stitch 디자인 생성 → Refero description + 치환 규칙 + DESIGN.md 토큰 → generate_screen_from_text
D5: 검증 → 생성된 디자인과 레퍼런스 비교
D6: 완료
```

> **⚠️ 중요:** `/prism design`은 **시각 디자인 생성** 단계이다. 코드 작성이 아니다.
> 코드 작성은 `/prism implement`에서 진행한다.

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

### D4: Stitch 디자인 생성 — Refero + 치환 규칙 + DESIGN.md 토큰

**Goal:** Refero description의 레이아웃/구조를 참조하되, 치환 맵 + DESIGN.md 토큰을 결합하여 **Stitch에서 시각 디자인 화면을 생성**한다.

> **⚠️ 이 단계는 코드 작성이 아니다.** Stitch `generate_screen_from_text`로 디자인 목업을 생성하는 단계이다.

**프롬프트 구성 절차 (화면당):**

```
1. 프롬프트 소스 수집:
   a. .prism/prompts.md에서 해당 화면의 enhanced prompt 로드 (A11 산출물)
   b. refero_get_screen으로 Refero 레퍼런스의 상세 description 로드
   c. .prism/substitution-map.md에서 치환 규칙 로드
   d. ./DESIGN.md에서 디자인 시스템 토큰 로드

2. Stitch 프롬프트 합성:
   - Refero description의 레이아웃 구조를 기본 뼈대로 사용
   - 치환 맵으로 콘텐츠를 타겟 도메인으로 변환
   - DESIGN.md 토큰(색상, 폰트, radius 등)을 명시적으로 포함
   - analysis.md A5 Copy에서 UI 텍스트(한국어) 참조
   - ⚠️ DESIGN SYSTEM (REQUIRED) 블록을 프롬프트 상단에 반드시 포함

3. Stitch 화면 생성:
   mcp__stitch__generate_screen_from_text({
     projectId: "{Stitch 프로젝트 ID}",
     prompt: "{합성된 프롬프트}",
     deviceType: "MOBILE",
     modelId: "GEMINI_3_1_PRO"
   })

4. 타임아웃 처리:
   - 타임아웃 발생 시 25-35초 대기 후 list_screens로 생성 확인
   - 백그라운드 생성이 완료되었으면 정상 진행
   - 실패 시 1회 재시도

5. Flow 화면의 경우:
   - refero_get_flow로 전체 step 로드
   - 각 step을 개별 Stitch 화면으로 생성
   - step 간 전환 설명을 프롬프트에 포함
```

**프롬프트 템플릿:**

```
--- DESIGN SYSTEM (REQUIRED) ---
{DESIGN.md의 전체 디자인 규칙}
--- END DESIGN SYSTEM ---

{화면 이름} — {Feature명}

레이아웃 참조 (Refero {레퍼런스 앱} {화면 유형}):
{Refero description.layout 요약 — 치환 맵 적용 후}

콘텐츠:
{치환된 UI 요소 + 텍스트 목록}

특수 요구사항:
- {analysis.md에서 추출한 기능적 요구사항}
- 한국어 UI, 친근 존댓말 (-어요 체)
```

> **원칙:** 구조/레이아웃은 Refero에서 가져오고, 콘텐츠는 치환 맵으로 변환하고, 색상/폰트는 DESIGN.md 토큰을 적용한다. 생성 결과는 Stitch 프로젝트에 시각 디자인으로 저장된다.

### D5: 검증

**체크리스트:**

```
구조 일치:
- [ ] 레이아웃 구조가 Refero 레퍼런스와 동일
- [ ] 컴포넌트 배치 순서 동일
- [ ] 네비게이션 패턴 동일

디자인 시스템 일치:
- [ ] DESIGN.md의 색상 토큰이 정확히 반영
- [ ] 타이포 위계 (serif headline + sans body) 동일
- [ ] 카드 스타일 (shadow only, no borders) 적용
- [ ] 여백/간격 수준 유사

콘텐츠 적합:
- [ ] 타겟 앱 도메인으로 적절히 치환
- [ ] UI 텍스트가 앱 보이스와 일치 (analysis.md A5)
- [ ] 기능 요소가 누락 없이 반영 (analysis.md A2)
```

**검증 방법:**
1. `get_screen`으로 Stitch 생성 화면의 스크린샷 확인
2. Refero 레퍼런스 URL (refero.design/s/{id})과 레이아웃 비교
3. DESIGN.md 토큰 적용 여부 확인
4. 체크리스트 pass/fail → gaps > 0이면 `edit_screens`로 수정 후 재검증

### D6: 완료

1. Feature 매핑 + 구현 + 검증 완료
2. 상태 파일 업데이트 (completed_features에 추가)
3. 다음 Feature 또는 전체 완료

---

## Feature 루프

```
Feature 0 → D1 → D2(매핑) → D3(치환규칙) → D4(Stitch 생성) → D5(검증) → D6
Feature 1 → D1 → D2 → D3 → D4(Stitch 생성) → D5(검증) → D6
...
```

> **D3(치환 규칙)은 첫 Feature에서 1회 생성 후 이후 Feature에서 재사용한다.** 새로운 엔티티가 등장하면 치환 맵에 추가.
> **D4에서 생성된 화면은 Stitch 프로젝트에 저장된다.** 코드 변환은 `/prism implement`에서 진행.

---

## `/prism export <feature|all>` — Stitch → Figma 내보내기

**Goal:** Stitch 네이티브 "Figma 내보내기" 기능을 CDP(Chrome DevTools Protocol)로 자동화하여 디자인을 Figma로 완벽 이전한다.

> **왜 CDP인가:** Stitch는 cross-origin iframe(`app-companion-430619.appspot.com`)에서 렌더링되어 cv 도구로 직접 접근이 불가하다. CDP WebSocket으로 iframe 탭에 직접 연결하여 Stitch 네이티브 "Figma 내보내기" 버튼을 자동화한다. 이 방식은 Stitch "Copy to Figma"와 동일한 결과를 제공한다.

**사전 요구사항:**
- Chrome이 디버그 모드로 실행 중: `open -a "Google Chrome" --args --remote-debugging-port=9222`
- chrome-viewer 서버 실행 중 (포트 6080)
- Stitch에 로그인된 상태 (Chrome 브라우저에서)

**실행 절차:**

**Phase 0: 화면 수 사전 감지**
```
list_screens(projectId) → 화면 수 확인
16개 이하: ⌘+A 전체 선택 경로
17개 이상: 16개씩 배치 분할 경로
```

**Phase 1: CDP 연결 + 프로젝트 열기**
```
1. http://localhost:9222/json/list에서 탭 목록 조회
2. Stitch 메인 탭 찾기 (stitch.withgoogle.com)
3. 메인 탭에서 Page.navigate로 프로젝트 URL 이동
4. iframe 탭 polling (wait_for_iframe_ready):
   - 1초 간격으로 탭 목록 재조회
   - app-companion URL에 project_id가 포함된 탭 찾기
   - body.innerHTML.length > 5000이면 로드 완료
   - 최대 30초 타임아웃
```

**Phase 2: 화면 선택 + Figma 내보내기**

**경로 A — 16개 이하 (⌘+A):**
```
1. "내보내기" 버튼 클릭 (textContent.includes('내보내기'))
2. Input.dispatchKeyEvent로 ⌘+A (모두 선택)
3. "Figma" 옵션 클릭 (span.textContent === 'Figma')
4. "변환" 버튼 클릭 → 변환 진행 (수 초)
5. "변환"이 "복사"로 변경될 때까지 대기 (최대 60초)
6. "복사" 버튼 클릭 → Figma 클립보드에 복사
7. Figma에서 ⌘+V로 붙여넣기 (사용자 수동 또는 use_figma 자동화)
```

**경로 B — 17개 이상 (16개씩 배치):**
```
screens를 16개씩 chunk: [[0..15], [16..19]]
각 배치에 대해:
  1. "내보내기" 버튼 클릭
  2. 내보내기 패널에서 해당 배치의 화면만 개별 클릭 선택
  3. "Figma" 옵션 클릭 → "변환" 클릭
  4. "복사" 버튼 출현 대기 → "복사" 클릭
  5. Figma에서 ⌘+V
  6. 다음 배치로 반복
```

**Phase 3: 결과 기록**
```
1. .prism/figma-ids.md에 Feature별 Figma 파일 URL 기록
2. 안내: "Figma에서 미세 조정 후 /prism implement <feature> 실행"
```

**CDP 코드 패턴:**

```python
import urllib.request, json, asyncio, websockets

# --- iframe 탭 대기 (프로젝트 전환 후) ---
async def wait_for_iframe_ready(project_id, timeout=30):
    import time
    deadline = time.time() + timeout
    while time.time() < deadline:
        tabs = json.loads(urllib.request.urlopen('http://localhost:9222/json/list').read())
        for t in tabs:
            if 'app-companion' in t.get('url','') and project_id in t.get('url',''):
                async with websockets.connect(t['webSocketDebuggerUrl']) as ws:
                    await ws.send(json.dumps({'id': 1, 'method': 'Runtime.evaluate',
                        'params': {'expression': 'document.body?.innerHTML?.length || 0'}}))
                    resp = json.loads(await ws.recv())
                    body_len = resp.get('result',{}).get('result',{}).get('value',0)
                    if body_len > 5000:
                        return t['webSocketDebuggerUrl']
        await asyncio.sleep(1)
    raise TimeoutError(f"iframe not ready for {project_id}")

# --- 단일 Feature export ---
async def export_feature(project_id, screen_count):
    ws_url = await wait_for_iframe_ready(project_id)
    async with websockets.connect(ws_url) as ws:
        if screen_count <= 16:
            # 경로 A: ⌘+A
            await click_export(ws)
            await cmd_a(ws)
            await click_figma_convert(ws)
        else:
            # 경로 B: 배치
            batches = [list(range(i, min(i+16, screen_count))) for i in range(0, screen_count, 16)]
            for batch in batches:
                await click_export(ws)
                await select_screens_by_index(ws, batch)
                await click_figma_convert(ws)
                await asyncio.sleep(3)

async def click_export(ws):
    await ws.send(json.dumps({'id': 10, 'method': 'Runtime.evaluate', 'params': {
        'expression': "Array.from(document.querySelectorAll('button')).find(b => b.textContent.includes('내보내기'))?.click()"
    }}))
    await ws.recv()
    await asyncio.sleep(1)

async def cmd_a(ws):
    for evt_type in ['keyDown', 'keyUp']:
        await ws.send(json.dumps({'id': 20, 'method': 'Input.dispatchKeyEvent', 'params': {
            'type': evt_type, 'modifiers': 4, 'key': 'a', 'code': 'KeyA', 'windowsVirtualKeyCode': 65
        }}))
        await ws.recv()
    await asyncio.sleep(1)

async def select_screens_by_index(ws, indices):
    """내보내기 패널에서 특정 화면만 개별 클릭 선택"""
    for idx in indices:
        await ws.send(json.dumps({'id': 30+idx, 'method': 'Runtime.evaluate', 'params': {
            'expression': f"document.querySelectorAll('[data-screen-id], [role=\"checkbox\"], .screen-thumbnail')[{idx}]?.click()"
        }}))
        await ws.recv()
        await asyncio.sleep(0.1)

async def click_figma_convert_copy(ws):
    # 1. Figma 선택
    await ws.send(json.dumps({'id': 40, 'method': 'Runtime.evaluate', 'params': {
        'expression': "(() => { const s = Array.from(document.querySelectorAll('span')).find(s => s.textContent.trim() === 'Figma'); s?.click(); s?.parentElement?.click(); })()"
    }}))
    await ws.recv()
    await asyncio.sleep(2)
    
    # 2. "변환" 클릭 → Stitch가 Figma 포맷으로 변환
    await ws.send(json.dumps({'id': 41, 'method': 'Runtime.evaluate', 'params': {
        'expression': "Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === '변환')?.click()"
    }}))
    await ws.recv()
    
    # 3. "변환" → "복사"로 버튼 변경 대기 (최대 60초)
    for _ in range(60):
        await asyncio.sleep(1)
        await ws.send(json.dumps({'id': 42, 'method': 'Runtime.evaluate', 'params': {
            'expression': "!!Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === '복사')"
        }}))
        resp = json.loads(await ws.recv())
        has_copy = resp.get('result',{}).get('result',{}).get('value', False)
        if has_copy: break
    
    # 4. "복사" 클릭 → Figma 클립보드에 복사
    await ws.send(json.dumps({'id': 43, 'method': 'Runtime.evaluate', 'params': {
        'expression': "Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === '복사')?.click()"
    }}))
    await ws.recv()
    await asyncio.sleep(2)
    # → 이후 Figma에서 ⌘+V로 붙여넣기
```

**Stitch iframe 접근 패턴 (Pattern 4b 참조):**

Stitch 웹 앱은 cross-origin iframe 구조:
```
stitch.withgoogle.com (메인 프레임) → 빈 셸
  └── app-companion-430619.appspot.com (iframe) → 실제 UI
```

cv 도구는 메인 프레임만 접근 가능하므로, CDP WebSocket으로 iframe 탭에 직접 연결해야 한다.

**Feature별 순차 export (`/prism export all`):**

```
1. .prism/project-ids.md에서 모든 Feature 프로젝트 ID 로드
2. 메인 Stitch 탭 찾기 (stitch.withgoogle.com)
3. 각 Feature에 대해:
   a. 메인 탭에서 Page.navigate → 해당 프로젝트 URL
   b. wait_for_iframe_ready(project_id) → iframe 로드 대기
   c. list_screens(projectId) → 화면 수 확인
   d. export_feature(project_id, screen_count) 실행
   e. 실패 시: 에러 기록 + 다음 Feature 계속 진행
4. .prism/figma-ids.md에 결과 기록
5. 실패한 Feature 요약 표시
```

> **개별 선택 DOM 선택자 주의:** `select_screens_by_index`의 선택자(`[data-screen-id]`, `[role="checkbox"]`, `.screen-thumbnail`)는 Stitch UI의 실제 DOM에 의존한다. 최초 실행 시 내보내기 패널의 DOM 구조를 Runtime.evaluate로 덤프하여 정확한 선택자를 확정해야 한다.

## `/prism implement <feature|all>` — Figma → Code 반영

**Goal:** Figma에서 미세 조정된 디자인을 프로젝트 코드에 반영한다.

**실행 절차:**

```
1. .prism/figma-ids.md에서 Feature의 Figma 파일 key 확인
   없으면 → "/prism export <feature> 먼저 실행" 안내
2. .prism/export-state.md에서 사용된 Fallback Level 확인
3. Level에 따라 코드 생성 소스 결정:
   L1/L2: Figma → get_design_context로 코드 참조 + 스크린샷 추출
   L3: Stitch HTML에서 직접 코드 생성 (Figma는 참조용)
4. 각 화면에 대해:
   a. get_design_context(fileKey, nodeId) → 코드 참조 + 스크린샷
   b. 프로젝트 스택에 맞게 코드 변환 (Flutter/React/Next.js)
   c. analysis.md의 코드 파일 경로 참조 → 해당 파일에 코드 작성
5. 빌드/테스트 실행 → 오류 수정
6. 시뮬레이터/브라우저 스크린샷 → Figma 디자인과 비교 검증
```

**Figma → Code 변환 규칙:**
- `get_design_context`가 반환하는 코드는 **참조용** — 프로젝트 스택/패턴에 맞게 적응
- 프로젝트에 기존 컴포넌트가 있으면 재사용 (새로 생성하지 않음)
- DESIGN.md의 디자인 토큰을 코드의 테마/스타일 시스템에 매핑
- 코드 파일 경로는 analysis.md의 A1 코드 분석 결과에서 참조

---

## `/prism design resume`

```
1. .claude/prism-design-pipeline.local.md 존재 확인
2. 상태에서 진행 상황 읽기 (mode, feature, completed_features, mapping_status)
3. 중단 지점부터 재개 (매핑 중 → D2, 구현 중 → D4)
```

---

## 파이프라인 모드

`/prism design`은 항상 **Stitch 디자인 생성 모드**로 동작한다.
Refero는 레이아웃/구조 참조용이며, 최종 결과물은 Stitch 프로젝트의 시각 디자인이다.

코드 작성은 별도 단계:
- `/prism export` → Stitch → Figma 내보내기
- `/prism implement` → Figma 디자인 → 프로젝트 코드 반영
