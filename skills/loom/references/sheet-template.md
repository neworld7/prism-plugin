## Analysis Sheet Template (Code+Simulator→Prompts)

Use this template for `/loom analyze` pipeline. Save to `.loom/{date}-{app}-analysis.md`.

프롬프트 블록은 **화면별로 독립 복사** 가능해야 한다. 사용자가 Stitch에 블록 단위로 붙여넣는다.

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

## 앱 컨텍스트

> {앱의 목적, 타겟 사용자, 전반적 분위기를 2-3줄로 요약}
> 예: "ReadCodex는 독서를 즐기는 사용자를 위한 읽기 추적 앱. 따뜻하고 책 향기 나는 분위기."

## Feature 요약

| # | Feature | 화면 수 | 핵심 화면 |
|---|---------|---------|-----------|
| 1 | 인증 | 3 | 로그인, 회원가입, 비밀번호 재설정 |
| 2 | 홈 | 2 | 대시보드, 알림 |
| ... | ... | ... | ... |

---

## Feature 1: {feature name}

### 화면 목록

| # | 화면 | 코드 파일 | 현재 상태 |
|---|------|-----------|-----------|
| 1 | 로그인 | lib/.../login_screen.dart | 기본 폼, 브랜딩 없음 |

### 사용자 흐름

이메일/비밀번호 입력 → 로그인 → 홈으로 이동
대안: 소셜 로그인 / 비밀번호 재설정 / 회원가입 이동

---

### 🎯 로그인

> **사용자 목표**: 기존 사용자가 빠르고 신뢰감 있게 앱에 접근

📋 **Stitch 프롬프트** ← Stitch에 붙여넣기

```
A warm, welcoming login screen for '{App Name}' {app category} app.

Centered app branding with tagline.
Clean email and password form with modern input styling.
Prominent sign-in button as the primary action.
Social login options (Google, Apple) below the form.
"Forgot password?" and "Sign up" links for alternative flows.

Mood: warm, trustworthy, minimal.
Mobile-first, iOS patterns. No sidebar.
All UI text, labels, buttons, placeholders, and content must be in Korean (한국어).
```

🔄 **변형 아이디어** — Variants 생성 시 참고
- 다크 모드 버전
- 일러스트레이션 배경
- 미니멀 원페이지 (로고 + 폼만)

---

### 🎯 회원가입

> **사용자 목표**: 새 사용자가 부담 없이 빠르게 계정 생성

📋 **Stitch 프롬프트** ← Stitch에 붙여넣기

```
A friendly, encouraging sign-up screen for '{App Name}'.

Step-by-step or single-form registration.
Name, email, password fields with clear labels.
Password strength indicator for guidance.
Terms acceptance checkbox.
Primary "Create Account" button.
"Already have an account? Sign in" link.

Mood: approachable, clean, encouraging.
Mobile-first. Similar to {reference app}'s onboarding.
All UI text, labels, buttons, placeholders, and content must be in Korean (한국어).
```

🔄 **변형 아이디어**
- 소셜 로그인 우선 버전
- 멀티스텝 온보딩
- 일러스트 + 진행 표시

---

## Feature 2: {feature name}

### 화면 목록
...

### 사용자 흐름
...

### 🎯 {screen name}
...
```
