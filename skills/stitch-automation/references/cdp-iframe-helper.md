# CDP Iframe Helper Patterns

Stitch 웹 앱은 cross-origin iframe 구조이다. chrome-viewer의 cv_* 도구는 메인 프레임만 접근 가능하므로,
iframe 내부 조작이 필요할 때는 아래 CDP 패턴을 사용한다.

## 왜 필요한가

```
stitch.withgoogle.com (메인 프레임)
  └── app-companion-430619.appspot.com (cross-origin iframe, 실제 콘텐츠)
```

- `cv_click_element("텍스트")` → 메인 프레임만 검색 → "not found"
- `cv_evaluate("iframe.contentDocument...")` → cross-origin 차단
- `cv_click(x, y)` → 리사이즈 변환 좌표 오차로 실패 가능

## 기본 패턴: iframe 탭 찾기 → JS 실행

```python
import asyncio, websockets, json, urllib.request

async def run_in_stitch_iframe(js_expression):
    """Stitch iframe에서 JS를 실행하고 결과를 반환한다."""
    tabs = json.loads(urllib.request.urlopen('http://localhost:9222/json/list').read())

    # app-companion iframe 탭 찾기
    iframe_tab = next(
        (t for t in tabs if 'app-companion' in t.get('url', '') and 'settings' in t.get('url', '')),
        None
    )
    if not iframe_tab:
        return {'error': 'iframe tab not found', 'tabs': [t['url'][:60] for t in tabs]}

    async with websockets.connect(iframe_tab['webSocketDebuggerUrl']) as ws:
        await ws.send(json.dumps({
            'id': 1,
            'method': 'Runtime.evaluate',
            'params': {'expression': js_expression}
        }))
        resp = json.loads(await asyncio.wait_for(ws.recv(), timeout=10))
        return resp.get('result', {}).get('result', {}).get('value', 'N/A')
```

## 패턴 1: 버튼 클릭

```python
result = await run_in_stitch_iframe('''
    (() => {
        const btn = [...document.querySelectorAll('button')]
            .find(b => b.textContent.includes('키 만들기'));
        if (btn) { btn.click(); return 'clicked: ' + btn.textContent.trim(); }
        return 'not found. buttons: ' + [...document.querySelectorAll('button')]
            .map(b => b.textContent.trim()).join(' | ');
    })()
''')
```

## 패턴 2: 페이지 텍스트 추출

```python
result = await run_in_stitch_iframe('''
    document.body.innerText
''')
```

## 패턴 3: 스크린샷 (CDP)

```python
import base64

async def screenshot_stitch_iframe(save_path):
    tabs = json.loads(urllib.request.urlopen('http://localhost:9222/json/list').read())
    iframe_tab = next(t for t in tabs if 'app-companion' in t['url'])

    async with websockets.connect(iframe_tab['webSocketDebuggerUrl']) as ws:
        await ws.send(json.dumps({
            'id': 1,
            'method': 'Page.captureScreenshot',
            'params': {'format': 'jpeg', 'quality': 60}
        }))
        resp = json.loads(await asyncio.wait_for(ws.recv(), timeout=10))
        img = base64.b64decode(resp['result']['data'])
        with open(save_path, 'wb') as f:
            f.write(img)
        return len(img)
```

## 패턴 4: 네비게이션

cv_navigate는 메인 프레임을 이동하므로, iframe도 자동으로 갱신된다.
따라서 네비게이션은 cv_navigate를 그대로 사용해도 된다.

```
cv_navigate("https://stitch.withgoogle.com/settings")
→ 메인 프레임 이동 → iframe도 /settings로 자동 로드
```

## 패턴 5: 전체 페이지 스크롤 탐색

페이지에서 특정 섹션을 찾을 때, 반드시 전체 스크롤 후 판단:

```
1. cv_navigate → 페이지 로드
2. sleep 3 → 로딩 대기
3. cv_scroll(delta_y=99999) → 바닥까지 스크롤
4. cv_screenshot → 하단 확인
5. cv_scroll(delta_y=-99999) → 상단 복귀
6. 필요 시 중간도 확인

"이 페이지에 X가 없다"고 말하기 전에 반드시 페이지 끝까지 확인할 것.
```

## 언제 어떤 도구를 쓸까

| 작업 | 도구 | 이유 |
|------|------|------|
| 페이지 이동 | `cv_navigate` | 메인+iframe 동시 이동 |
| 메인 프레임 스크린샷 | `cv_screenshot` | 빠르고 간단 |
| iframe 내부 클릭 | CDP `Runtime.evaluate` → `.click()` | cross-origin 우회 |
| iframe 내부 텍스트 읽기 | CDP `Runtime.evaluate` → `.innerText` | cross-origin 우회 |
| iframe 스크린샷 | CDP `Page.captureScreenshot` | iframe만 캡처 가능 |
| 스크롤 | `cv_scroll` | 메인 프레임 스크롤 (iframe 포함) |
