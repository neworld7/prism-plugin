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

### delete_project

Deletes a project.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | required | Resource name. Format: `projects/{projectId}` |

### list_projects

Lists all accessible projects.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `filter` | string | optional | `view=owned` (default) or `view=shared` |

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
| `projectId` | string | required | Project ID without prefix |
| `screenId` | string | required | Screen ID without prefix |

**Output includes:**
- `downloadUrls.html` — URL to download the screen's HTML/CSS code
- `downloadUrls.screenshot` — URL to download the screen's screenshot image

**Usage pattern:**
```
1. get_screen(projectId, screenId)
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
| `deviceType` | string | optional | `MOBILE` or `DESKTOP` |
| `modelId` | string | optional | Model to use for generation |

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
| `deviceType` | string | optional | `MOBILE` or `DESKTOP` |
| `modelId` | string | optional | Model to use |

### upload_screens_from_images

Uploads images to create new screens.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | required | Project ID without prefix |
| `images` | array | required | Image data to upload |

### generate_variants

Generates variants of existing screens.

**Input:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `projectId` | string | required | Project ID without prefix |
| `selectedScreenIds` | array | required | Screen IDs to generate variants for |
| `prompt` | string | required | Variant generation prompt |
| `variantOptions` | object | required | Number of variants, creative range, aspects to focus on |
| `deviceType` | string | optional | `MOBILE` or `DESKTOP` |
| `modelId` | string | optional | Model to use |

## Design Systems

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
- `MOBILE` — mobile device layout
- `DESKTOP` — desktop/web layout

### ModelId
- Check `list_tools` output for current available models
- Default model is typically sufficient for most use cases

### ScreenType
- Standard screen types generated by Stitch

## Error Handling

- **Timeout on generation**: DO NOT RETRY immediately. Wait and check with `get_screen` or `list_screens`.
- **Auth failure**: Re-run `gcloud auth application-default login`
- **Rate limits**: Standard mode 350/month, Experimental mode 50/month
- **Invalid IDs**: Use `list_projects` / `list_screens` to get valid IDs
