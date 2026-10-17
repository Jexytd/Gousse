---
name: potassium-mcp
description: >-
  Cheatsheet and runbook for interacting with the Potassium Luau executor MCP server.
  Use when connecting to Luau clients, executing scripts, reading console output,
  or managing Potassium editor tabs.
---

# Potassium MCP Cheatsheet & Workflow Guide

Potassium connects the AI agent to active Luau execution environments (e.g., Roblox client or studio sessions) and its built-in tabbed script editor.

## Tools Summary

| Tool | Action | Primary Parameters |
| :--- | :--- | :--- |
| `list_clients` | List active, authenticated client processes | None |
| `execute_script` | Run Luau source on one or all clients | `source` (string), `pid` (optional, default: all) |
| `read_console` | Fetch captured output / print logs | `after_cursor`, `wait_ms`, `limit`, `pid` |
| `clear_console` | Clear log history and UI console | None (cursors continue incrementing) |
| `tabs` | Inspect, open, edit, or close editor tabs | `action` (`list`, `read`, `open`, `write`, `activate`, `close`), `id`, `title`, `content` |

---

## Core Workflows

### 1. Discovering Clients
Discover connected clients first before targeting a specific PID:
```json
{
  "ServerName": "potassium",
  "ToolName": "list_clients",
  "Arguments": {}
}
```

### 2. Executing Luau & Reading Output (Cursor Pattern)
Potassium streams console output asynchronously. `execute_script` returns a cursor that guarantees you only read output produced *after* that dispatch:

1. **Execute Luau Script**:
   ```json
   {
     "ServerName": "potassium",
     "ToolName": "execute_script",
     "Arguments": {
       "pid": "<target_pid_or_null>",
       "source": "print('Hello from Potassium!')"
     }
   }
   ```
2. **Read Script Output with Cursor**:
   Pass the returned cursor into `after_cursor` and optionally specify `wait_ms` to wait for output:
   ```json
   {
     "ServerName": "potassium",
     "ToolName": "read_console",
     "Arguments": {
       "after_cursor": <cursor_number>,
       "wait_ms": 2000,
       "pid": "<target_pid_or_null>"
     }
   }
   ```

### 3. Editor Tab Management
Manipulate scripts open in Potassium's IDE interface:

- **List Open Tabs**:
  `tabs(action: "list")`
- **Read Tab Code**:
  `tabs(action: "read", id: "<tab_id>")`
- **Create / Open New Tab**:
  `tabs(action: "open", title: "script.luau", content: "-- code here")`
- **Update Tab Text**:
  `tabs(action: "write", id: "<tab_id>", content: "-- full replacement text")`
- **Switch Active Tab**:
  `tabs(action: "activate", id: "<tab_id>")`
- **Close Tab**:
  `tabs(action: "close", id: "<tab_id>")` (refuses if unsaved)

---

## Best Practices & Gotchas

1. **Always Use `after_cursor`**: When verifying results of `execute_script`, always pass the execution cursor to `read_console` to avoid inspecting stale logs from earlier runs.
2. **Use `wait_ms` for Asynchronous Calls**: For scripts that yield or execute across game frames, set `wait_ms` (up to 30,000ms).
3. **Reading Game State**: Potassium does not expose direct DOM/hierarchy exploration APIs like `roblox-mcp`. To inspect instances, serialize the target data with `execute_script` (e.g., `print(game.HttpService:JSONEncode(...))`) and read the console output.
