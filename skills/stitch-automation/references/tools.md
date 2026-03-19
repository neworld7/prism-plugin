# Stitch MCP Tools Reference

Official Stitch Remote MCP server tools at `https://stitch.googleapis.com/mcp`.

## ID Format Rules

- `projectId`: numeric string without `projects/` prefix. Example: `"4044680601076201931"`
- `screenId`: hex string without `screens/` prefix. Example: `"98b50e2ddc9943efb387052637738f61"`
- `name` (resource name): Full format `projects/{projectId}` or `projects/{projectId}/screens/{screenId}`

## Project Management

### create_project

Creates a new Stitch project (container for UI designs).

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | optional | Project title |

**Tip:** Recommend creating a design system before generating screens.

### get_project

Retrieves project details including metadata, theme, device type, and screen instances.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | required | Resource name. Format: `projects/{projectId}` |

### list_projects

Lists all accessible projects.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `filter` | string | optional | `view=owned` (기본) or `view=shared` (공유 프로젝트) |

## Screen Management

### list_screens

Lists all screens within a project.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | required | Project ID without prefix |

### get_screen

Retrieves screen details including `downloadUrls` for HTML code and screenshot image.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | required | Full resource name: `projects/{projectId}/screens/{screenId}` |
| `projectId` | string | deprecated | ~~Project ID without prefix~~ (backward compatible, will be removed) |
| `screenId` | string | deprecated | ~~Screen ID without prefix~~ (backward compatible, will be removed) |

**Output includes:**
- `downloadUrls.html` — URL to download the screen's HTML/CSS code
- `downloadUrls.screenshot` — URL to download the screen's screenshot image

**Usage pattern:**
```
1. get_screen(name: "projects/{projectId}/screens/{screenId}")
2. web_fetch(response.downloadUrls.html) → HTML code
3. web_fetch(response.downloadUrls.screenshot) → screenshot PNG
```

## AI Generation

### generate_screen_from_text

Generates a new screen from a text prompt. **Can take several minutes. DO NOT RETRY on timeout.**

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | required | Project ID without prefix |
| `prompt` | string | required | Text prompt describing the screen |
| `deviceType` | string | optional | `MOBILE`, `DESKTOP`, `TABLET`, or `AGNOSTIC` |
| `modelId` | string | optional | `MODEL_ID_UNSPECIFIED` (기본), `GEMINI_3_1_PRO` (50/월), `GEMINI_3_1_FLASH` (350/월) |

**Output:** May include `output_components` with suggestions. If suggestions are present, show them to the user and let them pick one, then call again with the suggestion as the prompt.

**Important:** If the call fails due to connection error, the generation may still succeed server-side. Use `list_screens` or `get_screen` to check.

### edit_screens

Edits existing screens using a text prompt. **Can take several minutes. DO NOT RETRY on timeout.**

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | required | Project ID without prefix |
| `selectedScreenIds` | array | required | Screen IDs to edit (without prefix) |
| `prompt` | string | required | Edit instruction |
| `deviceType` | string | optional | `MOBILE`, `DESKTOP`, `TABLET`, or `AGNOSTIC` |
| `modelId` | string | optional | `MODEL_ID_UNSPECIFIED` (기본), `GEMINI_3_1_PRO` (50/월), `GEMINI_3_1_FLASH` (350/월) |

### generate_variants

Generates variants of existing screens.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | required | Project ID without prefix |
| `selectedScreenIds` | array | required | Screen IDs to generate variants for |
| `prompt` | string | required | Variant generation prompt |
| `variantOptions` | object | required | Number of variants, creative range, aspects to focus on |
| `deviceType` | string | optional | `MOBILE`, `DESKTOP`, `TABLET`, or `AGNOSTIC` |
| `modelId` | string | optional | `MODEL_ID_UNSPECIFIED` (기본), `GEMINI_3_1_PRO` (50/월), `GEMINI_3_1_FLASH` (350/월) |

**variantOptions schema:**
| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `variantCount` | number | 3 | 생성할 변형 수 (1-5) |
| `creativeRange` | string | `EXPLORE` | `REFINE` (미세조정) / `EXPLORE` (균형) / `REIMAGINE` (급진적) |
| `aspects` | array | all | `LAYOUT`, `COLOR_SCHEME`, `IMAGES`, `TEXT_FONT`, `TEXT_CONTENT` (복수 선택) |

## Design Systems

> ⚠️ **복구 대기**: 이 도구들은 현재 MCP 서버에서 버그로 누락됨 (Google 공식 확인).
> 대안: DESIGN.md 워크플로우 사용 (`references/official/design-md/` 참조)
> 참고: https://discuss.ai.google.dev/t/design-systems-category-missing-from-mcp-server-tools/126064

### create_design_system

Creates a new design system for consistent theming across screens.

**Input:** Theme configuration including colors, fonts, appearance mode.

### update_design_system

Updates an existing design system.

### list_design_systems

Lists all design systems for a project.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | required | Project ID without prefix |

### apply_design_system

Applies a design system to screens in a project.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | required | Project ID without prefix |
| `designSystemId` | string | required | Design system ID to apply |

## Enums

### DeviceType
- `DEVICE_TYPE_UNSPECIFIED`
- `MOBILE` — mobile device layout
- `DESKTOP` — desktop/web layout
- `TABLET` — tablet layout (신규)
- `AGNOSTIC` — device-agnostic layout (신규)

### ModelId
- `MODEL_ID_UNSPECIFIED` — 기본 모델 (대부분의 경우 충분)
- `GEMINI_3_1_PRO` — 최고 품질, 50 생성/월
- `GEMINI_3_1_FLASH` — 빠른 반복, 350 생성/월

### ScreenType
- Standard screen types generated by Stitch

## Error Handling

- **Timeout on generation**: DO NOT RETRY immediately. Wait and check with `get_screen` or `list_screens`.
- **Auth failure**: Re-run `gcloud auth application-default login`
- **Rate limits**: See Rate Limits section below.
- **Invalid IDs**: Use `list_projects` / `list_screens` to get valid IDs

## Rate Limits

| 모델 | 한도 | 용도 |
|------|------|------|
| `GEMINI_3_1_PRO` | 50 생성/월 | 최초 프로덕션 품질 생성 |
| `GEMINI_3_1_FLASH` | 350 생성/월 | 미세 수정, 반복 편집 |

MCP에 할당량 조회 도구가 없으므로 rate limit은 생성 시도 중 에러 응답으로 감지.

## External References

- Official docs: https://stitch.withgoogle.com/docs/
- MCP setup: https://stitch.withgoogle.com/docs/mcp/setup
- MCP reference: https://stitch.withgoogle.com/docs/mcp/reference
- Agent Skills: https://github.com/google-labs-code/stitch-skills
- SDK: https://github.com/google-labs-code/stitch-sdk
- Community proxy: https://github.com/davideast/stitch-mcp
- Design Systems MCP bug: https://discuss.ai.google.dev/t/design-systems-category-missing-from-mcp-server-tools/126064
