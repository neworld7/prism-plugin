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
