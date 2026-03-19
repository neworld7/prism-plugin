# Design/Implement Sheet Templates

## Design Sheet Template (Code→Design)

Use this template for `/stitch design` pipeline. Save to `docs/plans/{date}-{feature}-design-sheet.md`.

```markdown
# {Feature} Design Sheet

| 항목 | 값 |
|------|------|
| Feature | {feature name} |
| Date | {YYYY-MM-DD} |
| Stack | Flutter / React / Next.js |
| Device | Mobile / Desktop |
| Stitch Project ID | {projectId} |
| Design System ID | {designSystemId} |

## 화면 매핑

| # | Code Screen | Route | Stitch Screen | Status | Stitch Prompt |
|---|-------------|-------|---------------|--------|---------------|
| 1 | home_screen.dart | / | Home Dashboard | [NEW] | Design a mobile... |
| 2 | login_screen.dart | /login | Login Screen | [NEW] | Design a clean... |
| 3 | ... | ... | ... | ... | ... |

**Status**: [NEW] 신규 생성 / [EDIT] 수정 필요 / [OK] 이미 존재 / [DONE] 완료 / [SKIP] 건너뜀

## 인터랙션 체크리스트

- [ ] 네비게이션 (탭, 드로어, 뒤로가기)
- [ ] 폼 입력 (텍스트, 선택, 토글)
- [ ] 버튼 액션 (저장, 삭제, 공유)
- [ ] 리스트 인터랙션 (스크롤, 당겨서 새로고침, 스와이프)
- [ ] 모달/다이얼로그
- [ ] 검색

## 상태별 화면

| 상태 | 해당 화면 | Status |
|------|-----------|--------|
| 로딩 | Home, Library | [NEW] |
| 에러 | Network error | [NEW] |
| 빈 상태 | Library (no books) | [NEW] |

## 검증 결과

| 항목 | 카운트 |
|------|--------|
| MISSING_SCREEN | 0 |
| MISSING_INTERACTION | 0 |
| MISSING_STATE | 0 |
| total_gaps | 0 |

## 변경 우선순위

- [HIGH] 필수 화면 누락
- [MED] 인터랙션 누락
- [LOW] 스타일 미세 조정
```

---

## Implement Sheet Template (Design→Code)

Use this template for `/stitch implement` pipeline. Save to `docs/plans/{date}-{feature}-implement-sheet.md`.

```markdown
# {Feature} Implementation Sheet

| 항목 | 값 |
|------|------|
| Feature | {feature name} |
| Date | {YYYY-MM-DD} |
| Target Stack | Flutter / React / Next.js |
| Stitch Project ID | {projectId} |
| Design System ID | {designSystemId} |

## 화면 매핑

| # | Stitch Screen | Screen ID | Code File | Status | Notes |
|---|---------------|-----------|-----------|--------|-------|
| 1 | Home Dashboard | abc123 | lib/features/home/home_screen.dart | [EDIT] | 레이아웃 업데이트 |
| 2 | Login Screen | def456 | (none) | [NEW] | 신규 생성 |
| 3 | ... | ... | ... | ... | ... |

**Status**: [NEW] 신규 생성 / [EDIT] 수정 필요 / [OK] 일치 / [DONE] 완료 / [SKIP] 건너뜀

## 변환 전략

### Flutter
- HTML/Tailwind → Flutter Widget 매핑 규칙 적용
- 테마 색상: Stitch design system → Flutter ThemeData
- 네비게이션: Stitch screen structure → GoRouter routes

### React/Next.js
- Stitch HTML → 컴포넌트 분리
- Tailwind CSS 유지
- 상태 관리 추가

## 시각 검증 결과

| # | Screen | HIGH | MED | LOW | Status |
|---|--------|------|-----|-----|--------|
| 1 | Home | 0 | 0 | 1 | [DONE] |
| 2 | Login | 0 | 0 | 0 | [DONE] |

## 총 차이 요약

| 등급 | 카운트 |
|------|--------|
| HIGH | 0 |
| MED | 0 |
| LOW | 1 |
| total_diffs | 1 |
```

---

## Analysis Sheet Template (Code+Simulator→Prompts)

Use this template for `/stitch analyze` pipeline. Save to `docs/plans/{date}-{app}-analysis.md`.

```markdown
# {App} Analysis

| 항목 | 값 |
|------|------|
| App | {app name} |
| Date | {YYYY-MM-DD} |
| Stack | Flutter / React / Next.js |
| Device | Mobile / Desktop / Tablet |
| Total Features | N |
| Total Screens | N |

## Feature 요약

| # | Feature | 화면 수 | 핵심 화면 |
|---|---------|---------|-----------|
| 1 | 인증 | 3 | 로그인, 회원가입, 비밀번호 재설정 |
| 2 | 홈 | 2 | 대시보드, 알림 |
| ... | ... | ... | ... |

## Feature 1: {feature name}

### 화면 목록

| # | 화면 | 코드 파일 | 현재 상태 | 스크린샷 분석 요약 |
|---|------|-----------|-----------|-------------------|
| 1 | 로그인 | lib/.../login_screen.dart | 기본 폼 | 단순 이메일/비밀번호, 브랜딩 없음 |

### 인터랙션

- [ ] 이메일/비밀번호 입력
- [ ] 로그인 버튼 → 홈으로 이동
- [ ] "비밀번호 찾기" 링크
- [ ] 소셜 로그인 버튼

### 상태별 화면

| 상태 | 설명 |
|------|------|
| 로딩 | 로그인 처리 중 스피너 |
| 에러 | 잘못된 자격 증명 메시지 |

### Stitch 프롬프트

#### 로그인 화면
```
Design a mobile login screen for a reading tracker app called 'ReadCodex'.
Center: App logo with tagline "Track your reading journey".
Form: Email field with envelope icon, password field with eye toggle,
rounded input borders (12px), subtle shadow on focus.
Below form: "Forgot password?" link in muted text.
Primary CTA: "Sign In" button, full-width, coral (#FF6B6B) background,
white text, rounded (24px).
Bottom: "Don't have an account? Sign up" with link highlight.
Social login section: Google and Apple sign-in buttons with brand icons,
outlined style.
Use warm white (#FEFEFE) background, serif font for logo,
sans-serif (Inter) for body. iOS-style with safe area padding.
```

#### 회원가입 화면
```
...
```

## Feature 2: {feature name}
...
```
