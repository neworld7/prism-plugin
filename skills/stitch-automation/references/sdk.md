# @google/stitch-sdk Reference

Programmatic TypeScript/JavaScript client for the Stitch API. Use this when you need to integrate Stitch into your own application, agent pipeline, or backend — rather than calling MCP tools directly.

## Installation

```bash
npm install @google/stitch-sdk
```

For Vercel AI SDK integration, also install `ai`:

```bash
npm install @google/stitch-sdk ai
```

## Authentication

Set `STITCH_API_KEY` in your environment. The `stitch` singleton reads it automatically.

```bash
export STITCH_API_KEY=your-api-key
```

Alternative: OAuth via `STITCH_ACCESS_TOKEN` + `GOOGLE_CLOUD_PROJECT`.

## Quick Start

```ts
import { stitch } from "@google/stitch-sdk";

const project = stitch.project("your-project-id");
const screen = await project.generate("A login page with email and password fields");
const html = await screen.getHtml();       // download URL for HTML
const imageUrl = await screen.getImage();  // download URL for screenshot PNG
```

---

## API Reference

### `stitch` singleton

Pre-configured `Stitch` instance. Reads `STITCH_API_KEY` from the environment. Lazily initialized on first use.

```ts
import { stitch } from "@google/stitch-sdk";
```

### `Stitch` class

Root class — manages projects and low-level tool calls.

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `projects()` | — | `Promise<Project[]>` | List all accessible projects |
| `project(id)` | `id: string` | `Project` | Reference a project by ID (no API call) |
| `listTools()` | — | `Promise<{ tools: Tool[] }>` | List available MCP tools |
| `callTool(name, args)` | `name: string`, `args: object` | `Promise<any>` | Call an MCP tool directly |

Example — create a project via tool call:

```ts
const result = await stitch.callTool("create_project", { title: "My App" });
```

### `Project` class

A Stitch project. Obtained from `stitch.projects()` or `stitch.project(id)`.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `id` | `string` | Alias for `projectId` |
| `projectId` | `string` | Bare project ID (no `projects/` prefix) |

**Methods:**

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `generate(prompt, deviceType?)` | `prompt: string`, `deviceType?: DeviceType` | `Promise<Screen>` | Generate a screen from a text prompt |
| `screens()` | — | `Promise<Screen[]>` | List all screens in the project |
| `getScreen(screenId)` | `screenId: string` | `Promise<Screen>` | Retrieve a specific screen by ID |

`DeviceType`: `"MOBILE"` | `"DESKTOP"` | `"TABLET"` | `"AGNOSTIC"`

Example:

```ts
const project = stitch.project("4044680601076201931");
const screens = await project.screens();
const screen = await project.generate("Dashboard with stat cards", "DESKTOP");
```

### `Screen` class

A generated UI screen. Provides access to HTML and screenshots.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `id` | `string` | Alias for `screenId` |
| `screenId` | `string` | Bare screen ID |
| `projectId` | `string` | Parent project ID |

**Methods:**

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `edit(prompt, deviceType?, modelId?)` | `prompt: string` | `Promise<Screen>` | Edit the screen with a text prompt |
| `variants(prompt, variantOptions, deviceType?, modelId?)` | `prompt: string`, `options: object` | `Promise<Screen[]>` | Generate design variants |
| `getHtml()` | — | `Promise<string>` | Get download URL for the screen's HTML |
| `getImage()` | — | `Promise<string>` | Get download URL for the screenshot |

`getHtml()` and `getImage()` use cached data when available. If the screen was loaded from `screens()` or `getScreen()`, they call `get_screen` automatically.

Example — edit and generate variants:

```ts
const edited = await screen.edit("Make the background dark and add a sidebar");
const editedHtml = await edited.getHtml();

const variants = await screen.variants("Try different color schemes", {
  variantCount: 3,
  creativeRange: "EXPLORE",
  aspects: ["COLOR_SCHEME", "LAYOUT"],
});
```

**`variantOptions` fields:**

| Field | Type | Default | Values |
|-------|------|---------|--------|
| `variantCount` | `number` | 3 | 1–5 |
| `creativeRange` | `string` | `"EXPLORE"` | `"REFINE"` / `"EXPLORE"` / `"REIMAGINE"` |
| `aspects` | `string[]` | all | `"LAYOUT"`, `"COLOR_SCHEME"`, `"IMAGES"`, `"TEXT_FONT"`, `"TEXT_CONTENT"` |

### `StitchToolClient`

Low-level MCP client. Use for explicit configuration (custom API key, base URL, timeout).

```ts
import { StitchToolClient } from "@google/stitch-sdk";

const client = new StitchToolClient({
  apiKey: "your-api-key",
  baseUrl: "https://stitch.googleapis.com/mcp",
  timeout: 300_000,
});

const result = await client.callTool("create_project", { title: "Agent Project" });
await client.close();
```

Auto-connects on first `callTool` or `listTools` call.

**`StitchToolClient` options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `apiKey` | `string` | `STITCH_API_KEY` | API key |
| `accessToken` | `string` | `STITCH_ACCESS_TOKEN` | OAuth token (alternative to API key) |
| `projectId` | `string` | `GOOGLE_CLOUD_PROJECT` | Cloud project ID (required with OAuth) |
| `baseUrl` | `string` | `https://stitch.googleapis.com/mcp` | MCP server URL |
| `timeout` | `number` | `300000` | Request timeout (ms) |

### `StitchProxy`

MCP proxy server — exposes Stitch tools through your own MCP server.

```ts
import { StitchProxy } from "@google/stitch-sdk";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const proxy = new StitchProxy({ apiKey: "..." });
const transport = new StdioServerTransport();
await proxy.start(transport);
```

---

## Vercel AI SDK Integration

`stitchTools()` converts Stitch MCP tools into Vercel AI SDK–compatible tool definitions.

```ts
import { generateText, stepCountIs } from "ai";
import { google } from "@ai-sdk/google";
import { stitchTools } from "@google/stitch-sdk/ai";

const { text, steps } = await generateText({
  model: google("gemini-2.5-flash"),
  tools: stitchTools(),
  prompt: "Create a project and generate a modern dashboard with a stat card",
  stopWhen: stepCountIs(5),
});

const toolCalls = steps.flatMap(s => s.toolCalls);
console.log(`Model called ${toolCalls.length} tools`);
```

Filter to specific tools with `include`:

```ts
const tools = stitchTools({
  include: ["create_project", "generate_screen_from_text", "get_screen"],
});
```

**`stitchTools()` options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `apiKey` | `string` | `STITCH_API_KEY` | Override env var |
| `include` | `string[]` | all tools | Expose only specific tool names |

---

## Error Handling

All domain class methods throw `StitchError` on failure.

```ts
import { stitch, StitchError } from "@google/stitch-sdk";

try {
  const project = stitch.project("bad-id");
  await project.screens();
} catch (error) {
  if (error instanceof StitchError) {
    console.error(error.code);        // e.g. "NOT_FOUND"
    console.error(error.message);     // human-readable
    console.error(error.recoverable); // boolean
  }
}
```

**Error codes:** `AUTH_FAILED`, `NOT_FOUND`, `PERMISSION_DENIED`, `RATE_LIMITED`, `NETWORK_ERROR`, `VALIDATION_ERROR`, `UNKNOWN_ERROR`

---

## Links

- GitHub: https://github.com/google-labs-code/stitch-sdk
- npm: https://www.npmjs.com/package/@google/stitch-sdk
- Stitch docs: https://stitch.withgoogle.com/docs/
