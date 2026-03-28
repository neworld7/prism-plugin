# Prism Workflows

통합 워크플로우 인덱스. 각 파이프라인은 별도 파일로 분리되어 있다.

| Pipeline | File | Phases |
|----------|------|--------|
| Analyze | `references/analyze-pipeline.md` | A1-A12 (코드 분석 → 프롬프트 생성) |
| Design | `references/design-pipeline.md` | D1-D6 (디자인 생성 → 검증 루프) |

## 실행 순서

```
/prism analyze [app]  → analyze-pipeline.md (A1-A12)
/prism preview        → analyze-pipeline.md (A10)
/prism design [feat]  → design-pipeline.md (D1-D6)
/prism pipeline [app] → analyze-pipeline.md → design-pipeline.md
```
