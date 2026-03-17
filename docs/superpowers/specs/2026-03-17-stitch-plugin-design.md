# Stitch Automation Plugin — Design Spec

## Overview

Google Stitch (stitch.withgoogle.com) AI design tool automation plugin for Claude Code. Provides bidirectional pipelines between code and design using the official Stitch Remote MCP server.

**Key principle:** Use the official Stitch MCP API for all design operations. Unlike the banani plugin which needs chrome-viewer for design creation (read-only MCP), Stitch MCP supports full read/write operations including design generation, editing, variants, and design system management. Chrome-viewer or Playwright may still be used for visual verification of implemented code screenshots (Design→Code pipeline Phase 5), but all Stitch design operations are MCP-only.

## Architecture

### Approach: MCP-Only Plugin

- All design operations (create, read, edit, generate variants, design systems) go through Stitch Remote MCP
- No chrome-viewer dependency
- Authentication via gcloud OAuth (ADC)
- Banani-style command/skill/hook wrapper pattern

### Plugin Structure

```
stitch-plugin/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace config
├── .mcp.json                    # Stitch Remote MCP server config
├── commands/
│   └── stitch.md                # /stitch slash command
├── skills/
│   └── stitch-automation/
│       ├── SKILL.md             # Skill main (activation + core workflow)
│       └── references/
│           ├── prompting.md     # Stitch prompting guide (from official docs)
│           ├── tools.md         # MCP tool reference (14 tools)
│           ├── workflows-design.md    # Code→Design pipeline
│           ├── workflows-implement.md # Design→Code pipeline
│           └── sheet-template.md      # Design sheet markdown template
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       ├── design-verify-stop.sh    # Stop hook (design verify loop)
│       └── code-verify-stop.sh      # Stop hook (code verify loop)
└── docs/
```

## MCP Server Configuration

### .mcp.json

```json
{
  "mcpServers": {
    "stitch": {
      "type": "http",
      "url": "https://stitch.googleapis.com/mcp"
    }
  }
}
```

### Authentication: OAuth (gcloud ADC)

Prerequisites:
1. `gcloud auth login` (user login via browser)
2. `gcloud auth application-default login` (ADC login via browser)

Auth check on skill activation: `gcloud auth application-default print-access-token`

**Note on MCP auth transport:** The Stitch Remote MCP server at `https://stitch.googleapis.com/mcp` uses HTTP transport. Claude Code's `claude mcp add stitch --transport http <url>` command handles OAuth token injection automatically when gcloud ADC credentials are available. No manual `Authorization` header configuration is needed in `.mcp.json`. If the auto-detection fails, the plugin skill should prompt the user to re-run the gcloud auth commands above.

### Official Stitch MCP Tools (14 total)

| # | Tool | Category | Read-Only | Notes |
|---|------|----------|-----------|-------|
| 1 | `create_project` | Project Management | No | |
| 2 | `get_project` | Project Management | Yes | |
| 3 | `delete_project` | Project Management | No | |
| 4 | `list_projects` | Project Management | Yes | |
| 5 | `list_screens` | Screen Management | Yes | |
| 6 | `get_screen` | Screen Management | Yes | Returns screen data including `downloadUrls` for HTML code and screenshot image |
| 7 | `generate_screen_from_text` | AI Generation | No | |
| 8 | `upload_screens_from_images` | AI Generation | No | |
| 9 | `edit_screens` | AI Generation | No | |
| 10 | `generate_variants` | AI Generation | No | |
| 11 | `create_design_system` | Design Systems | No | |
| 12 | `update_design_system` | Design Systems | No | |
| 13 | `list_design_systems` | Design Systems | Yes | |
| 14 | `apply_design_system` | Design Systems | No | |

**Note on screen code/image retrieval:** The official MCP's `get_screen` tool returns `downloadUrls` containing URLs for both HTML code and screenshot images. To download the actual content, use `web_fetch` on these URLs. The community proxy (`@_davideast/stitch-mcp`) provides convenience wrappers `get_screen_code` and `get_screen_image` that combine `get_screen` + download into a single call. Both approaches are valid — the plugin should prefer the official `get_screen` + `web_fetch` pattern but document the proxy alternative.

## Command System

### /stitch subcommands

| Command | Function | Core MCP Tools |
|---------|----------|---------------|
| `/stitch design [feature]` | Code→Design full pipeline | `create_project`, `generate_screen_from_text`, `create_design_system` |
| `/stitch implement [feature]` | Design→Code full pipeline | `list_projects`, `get_screen` + `web_fetch` |
| `/stitch verify-loop` | Design verify loop standalone | `get_screen` + `web_fetch`, `edit_screens` |
| `/stitch code-verify-loop` | Code verify loop standalone | `get_screen` + `web_fetch` |
| `/stitch cancel-loop` | Cancel active loop (deletes state files) | — |
| `/stitch status` | Show current pipeline state | — (reads state file) |
| `/stitch create` | Create project or screen | `create_project`, `generate_screen_from_text` |
| `/stitch edit` | Edit screen | `edit_screens` |
| `/stitch variants` | Generate design variants | `generate_variants` |
| `/stitch theme` | Create/apply design system | `create_design_system`, `apply_design_system` |
| `/stitch export` | Download screen HTML/image | `get_screen` + `web_fetch` |
| `/stitch list` | List projects/screens | `list_projects`, `list_screens` |

## Pipeline 1: Code→Design (`/stitch design`)

### Phase 1: Code Analysis
- Glob/Grep to explore project source code
- Extract screens, interactions, states (loading/error/empty)
- Map route structure and component hierarchy

### Phase 2: Design Sheet
- Compile Phase 1 results into markdown design sheet
- Draft per-screen prompts (based on Stitch prompting guide)
- Save to `docs/plans/{date}-{feature}-design-sheet.md`

### Phase 3: Prompt Optimization
- Optimize prompts for Stitch (UI/UX keywords, atmosphere, theme hints)
- Determine device type (mobile/desktop)

### Phase 4: Stitch Design Generation
- `create_project` → create project
- `create_design_system` → define consistent theme
- `generate_screen_from_text` → generate per-screen designs
- `apply_design_system` → apply design system
- `generate_variants` → generate variants if needed

### Phase 5: Verification
- `get_screen` + `web_fetch(downloadUrl)` → retrieve generated design screenshots
- Cross-check against design sheet checklist
- Count gaps: MISSING_SCREEN, MISSING_INTERACTION, MISSING_STATE

### Phase 6: Fix
- If gaps > 0: `edit_screens` to fix or `generate_screen_from_text` to regenerate
- Return to Phase 5

### Phase 7: Completion
- If gaps == 0: output `<promise>DESIGN_VERIFIED</promise>`
- Record final results in design sheet
- Clean up state file

### State File: `.claude/stitch-design-pipeline.local.md`

```yaml
---
phase: verify
feature: library
project_id: "4044680601076201931"
session_id: {unique-id}
iteration: 2
max_iterations: 5
---
```

## Pipeline 2: Design→Code (`/stitch implement`)

### Phase 1: Stitch Design Collection
- `list_projects` → select target project
- `list_screens` → enumerate all screens
- `get_screen` → retrieve screen data with `downloadUrls`
- `web_fetch(downloadUrl)` → download screenshots and HTML/CSS code

### Phase 2: Code Mapping
- Explore existing project code (Glob/Grep)
- Build Stitch screen ↔ code file mapping table
- Classify: `[NEW]` / `[EDIT]` / `[OK]`

### Phase 3: Implementation Plan Sheet
- Define per-screen conversion strategy
- **Flutter (primary target)**: Stitch HTML → Flutter Widget tree
  - HTML structure → Scaffold/AppBar/Column/Row mapping
  - Tailwind colors/spacing → Flutter Theme mapping
  - Images → `Image.asset` / `Image.network`
- **React/Next.js (secondary target)**: Use Stitch HTML nearly as-is
  - Tailwind CSS based — minimal conversion
  - Component splitting + state management
- Save to `docs/plans/{date}-{feature}-implement-sheet.md`

### Phase 4: Code Implementation
- Implement sequentially per plan sheet
- Flutter: `lib/features/{feature}/presentation/` screens
- React: `src/components/` or `app/` pages

### Phase 5: Visual Verification
- `get_screen` + `web_fetch(downloadUrl)` → get Stitch design screenshot
- Compare with implemented code screenshot:
  - Flutter → `xcrun simctl io booted screenshot /tmp/{screen}.png`
  - Web (React/Next.js) → chrome-viewer `cv_screenshot` or Playwright `browser_take_screenshot`
- Classify diffs: `HIGH` (missing elements), `MED` (color/layout), `LOW` (spacing)

### Phase 6: Fix
- Fix code based on diffs
- Return to Phase 5

### Phase 7: Completion
- If total diffs == 0: output `<promise>CODE_VERIFIED</promise>`
- Record final results in implementation sheet

### State File: `.claude/stitch-implement-pipeline.local.md`

```yaml
---
phase: code_verify
feature: library
project_id: "4044680601076201931"
session_id: {unique-id}
iteration: 1
max_iterations: 5
target_stack: flutter
---
```

## Skill System

### Auto-Activation Triggers (SKILL.md)
- Keywords: "stitch", "스티치", "stitch.withgoogle.com"
- Design context: "UI 디자인", "화면 디자인", "디자인 생성" (within Stitch project)

### On Activation
1. Check Stitch MCP tool availability
2. Verify auth status (`gcloud auth application-default print-access-token`)
3. Load workflow references

## Hook System

### hooks.json

```json
{
  "Stop": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/design-verify-stop.sh",
          "timeout": 10
        },
        {
          "type": "command",
          "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/code-verify-stop.sh",
          "timeout": 10
        }
      ]
    }
  ]
}
```

### design-verify-stop.sh
- Check if `.claude/stitch-design-pipeline.local.md` exists
- Read YAML frontmatter: phase, iteration, max_iterations
- If `phase: verify` and no `<promise>DESIGN_VERIFIED</promise>` signal:
  - Increment iteration
  - Inject re-verification prompt
- If iteration > max_iterations: auto-terminate loop

### code-verify-stop.sh
- Check if `.claude/stitch-implement-pipeline.local.md` exists
- Read YAML frontmatter: phase, iteration, max_iterations
- If `phase: code_verify` and no `<promise>CODE_VERIFIED</promise>` signal:
  - Increment iteration
  - Inject re-verification prompt
- If iteration > max_iterations: auto-terminate loop

### No PostToolUse Hook
Unlike banani (which needs DOM change verification after chrome-viewer operations), Stitch MCP API calls are server-side — no client-side verification needed.

## Comparison with Banani Plugin

| Aspect | Banani | Stitch |
|--------|--------|--------|
| Design creation | chrome-viewer (browser automation) | Stitch MCP (`generate_screen_from_text`) |
| Design reading | banani MCP (`banani_get_selected_designs`) | Stitch MCP (`get_screen` + `web_fetch` for code/image) |
| Design editing | chrome-viewer (DOM manipulation) | Stitch MCP (`edit_screens`) |
| Theme/design system | chrome-viewer (UI clicks) | Stitch MCP (`create_design_system`, `apply_design_system`) |
| Authentication | Browser session (cookie-based) | gcloud OAuth ADC |
| PostToolUse hook | Yes (DOM change verification) | No (server-side API) |
| Stop hooks | Yes (verify loops) | Yes (verify loops, same pattern) |
| DOM selectors | Yes (selectors.md) | No (not needed) |
| Target stacks | Flutter | Flutter (primary), React/Next.js (secondary) |

## Error Handling

### MCP Tool Call Failures
- Network error / timeout → retry up to 3 times with exponential backoff
- Auth token expired → prompt user to re-run `gcloud auth application-default login`
- Invalid project/screen ID → clear error message with `list_projects` / `list_screens` suggestion

### Design Generation Failures
- `generate_screen_from_text` timeout (>60s) → retry with simplified prompt
- Empty/malformed response → log error, skip screen, continue pipeline
- Rate limit exceeded → pause and inform user of Stitch generation limits (Standard: 350/month, Experimental: 50/month)

### Pipeline State Recovery
- If state file exists but session is stale (>24h) → prompt user to resume or cancel
- If state file is corrupted → delete and restart pipeline
- `/stitch cancel-loop` → deletes both `.claude/stitch-design-pipeline.local.md` and `.claude/stitch-implement-pipeline.local.md`

## External References

- Official docs: https://stitch.withgoogle.com/docs/
- MCP setup: https://stitch.withgoogle.com/docs/mcp/setup
- MCP reference: https://stitch.withgoogle.com/docs/mcp/reference
- Agent Skills: https://github.com/google-labs-code/stitch-skills
- Community proxy: https://github.com/davideast/stitch-mcp
