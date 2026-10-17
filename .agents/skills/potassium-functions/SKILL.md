---
name: potassium-functions
description: >-
  Comprehensive reference and documentation for all Potassium Luau executor functions
  tested in eVars.luau. Use when writing, debugging, or verifying Luau exploit scripts
  targeting Potassium across Actor, Cache, Closure, Debug, FileSystem, Input, Instance,
  Metatable, Miscellaneous, RakNet, Reflection, Script, Signal, and WebSocket APIs.
---

# Potassium Luau Functions Reference

Official Documentation Source: [https://docs.potassium.pro/api-reference/introduction](https://docs.potassium.pro/api-reference/introduction)

This reference documents all functions checked in [eVars.luau](file:///c:/Users/Gouang/Desktop/Gousse/eVars.luau).

---

## Quick Navigation

1. [Actor Library](#1-actor-library)
2. [Cache Library](#2-cache-library)
3. [Closure Library](#3-closure-library)
4. [Debug Library](#4-debug-library)
5. [FileSystem Library](#5-filesystem-library)
6. [Input Library](#6-input-library)
7. [Instance Library](#7-instance-library)
8. [Metatable Library](#8-metatable-library)
9. [Miscellaneous Library](#9-miscellaneous-library)
10. [RakNet Library](#10-raknet-library)
11. [Reflection Library](#11-reflection-library)
12. [Script Library](#12-script-library)
13. [Signal Library](#13-signal-library)
14. [WebSocket Library](#14-websocket-library)
15. [eVars.luau Naming & Compatibility Map](#evarsluau-naming--compatibility-map)

---

## 1. Actor Library

Facilitates interaction, thread execution, and communication across parallel Luau actors.

### `create_comm_channel`
- **Signature**: `create_comm_channel(): (number, BindableEvent)`
- **Description**: Returns an identifier and a `BindableEvent` used in one-way communication between actors.
- **Example**:
  ```lua
  local id, channel = create_comm_channel()
  channel.Event:Connect(function(data)
      print("Received:", data)
  end)
  ```

### `getactors`
- **Signature**: `getactors(): { [number]: Actor }`
- **Description**: Returns a table of all active `Actor` instances in the game (excluding deleted ones).

### `getactorthreads`
- **Signature**: `getactorthreads(): { [number]: thread }`
- **Description**: Returns an array of every thread associated with every running actor.

### `getdeletedactors` *(tested as `getdeleteactors` in `eVars.luau`)*
- **Signature**: `getdeletedactors(): { [number]: Actor }`
- **Description**: Returns a table of actors that were deleted by the game while still executing.

### `get_comm_channel`
- **Signature**: `get_comm_channel(id: number): BindableEvent`
- **Description**: Retrieves a `BindableEvent` created by `create_comm_channel` via its numeric ID.
- **Example**:
  ```lua
  local channel = get_comm_channel(channelId)
  channel:Fire("Hello from parallel actor!")
  ```

### `is_parallel` *(tested as `isparallel` in `eVars.luau`)*
- **Signature**: `is_parallel(): boolean`
- **Description**: Returns `true` if the calling thread is currently executing inside a parallel actor context.

### `run_on_actor`
- **Signature**: `run_on_actor(actor: Actor, source: string, ...: any?): ()`
- **Description**: Executes Luau source code inside the context of the specified `Actor`.

### `run_on_thread`
- **Signature**: `run_on_thread(targetThread: thread, source: string, ...: any?): ()`
- **Description**: Spawns and runs Luau source code inside the specified thread context.

---

## 2. Cache Library

Controls the internal instance reference cache to evade detections or isolate instances.

### `cache.invalidate`
- **Signature**: `cache.invalidate(instance: Instance): ()`
- **Description**: Removes an instance reference from Potassium's internal instance reference cache. Subsequent lookups produce a fresh reference.

### `cache.iscached`
- **Signature**: `cache.iscached(instance: Instance): boolean`
- **Description**: Returns whether the specified instance exists within the internal reference cache.

### `cache.replace`
- **Signature**: `cache.replace(oldInstance: Instance, newInstance: Instance): ()`
- **Description**: Replaces an instance with another instance in the internal instance cache.

### `cloneref`
- **Signature**: `cloneref(instance: Instance): Instance`
- **Description**: Returns a clone of the instance reference that bypasses equality comparison detections with game scripts, while still pointing to the same native engine object.
- **Example**:
  ```lua
  local safePart = cloneref(workspace.Part)
  ```

### `compareinstances`
- **Signature**: `compareinstances(a: Instance, b: Instance): boolean`
- **Description**: Checks whether two distinct instance references point to the exact same native Roblox engine instance.

---

## 3. Closure Library

Function inspection, creation, hooking, and stack evasion.

### `getfunctionhash`
- **Signature**: `getfunctionhash(func: function): string`
- **Description**: Returns a cryptographic SHA hash of the function's bytecode.

### `isexecutorclosure`
- **Signature**: `isexecutorclosure(func: function): boolean`
- **Description**: Returns `true` if the function was created by Potassium or one of its scripts.
- **Aliases**: `checkclosure`, `isourclosure`

### `hookfunction`
- **Signature**: `hookfunction(target: function, hook: function): function`
- **Description**: Replaces `target` function with `hook`. Returns a copy of the original function.
- **Aliases**: `hookfunc`, `replaceclosure`
- **Example**:
  ```lua
  local oldPrint
  oldPrint = hookfunction(print, function(...)
      if select(1, ...) == "Sensitive" then return end
      return oldPrint(...)
  end)
  ```

### `isfunctionhooked`
- **Signature**: `isfunctionhooked(func: function): boolean`
- **Description**: Returns `true` if the specified function has been hooked via `hookfunction`.

### `isourthread` *(tested as `issourthread` in `eVars.luau`)*
- **Signature**: `isourthread(targetThread?: thread): boolean`
- **Description**: Returns `true` if the calling thread (or `targetThread`) was created by Potassium.
- **Aliases**: `checkcaller`

### `restorefunction`
- **Signature**: `restorefunction(func: function): ()`
- **Description**: Restores a previously hooked function to its original native/bytecode implementation.

### `setstackhidden`
- **Signature**: `setstackhidden(func: function, hidden: boolean): ()`
- **Description**: Hides the function from call-stack traces and stack inspection detections.

### `newlclosure`
- **Signature**: `newlclosure(func: function): function`
- **Description**: Wraps a function into a standard Luau closure.

### `islclosure`
- **Signature**: `islclosure(func: function): boolean`
- **Description**: Returns `true` if the function is a Luau closure (written in Luau, not C).

### `newcclosure`
- **Signature**: `newcclosure(func: function): function`
- **Description**: Wraps a Luau function into a C closure to conceal its call stack, upvalues, and bytecode from game scripts.

### `iscclosure`
- **Signature**: `iscclosure(func: function): boolean`
- **Description**: Returns `true` if the function is a C closure (e.g. engine built-ins or wrapped via `newcclosure`).

### `isnewcclosure`
- **Signature**: `isnewcclosure(func: function): boolean`
- **Description**: Returns `true` if the function was created using `newcclosure`.

### `loadstring`
- **Signature**: `loadstring(source: string, chunkname?: string): (function?, string?)`
- **Description**: Compiles Luau source string into an executable function. Returns `nil, errorMessage` on syntax error.

---

## 4. Debug Library

Low-level Luau bytecode, proto, upvalue, and stack inspection.

### `debug.getconstant`
- **Signature**: `debug.getconstant(func: function, index: number): any`
- **Description**: Returns the constant at `index` from the function's constant pool.

### `debug.getconstants`
- **Signature**: `debug.getconstants(func: function): { [number]: any }`
- **Description**: Returns all constants in the function's constant table.

### `debug.getupvalue`
- **Signature**: `debug.getupvalue(func: function, index: number): any`
- **Description**: Returns the upvalue at `index` for the specified closure.

### `debug.getupvalues`
- **Signature**: `debug.getupvalues(func: function): { [number]: any }`
- **Description**: Returns a table of all upvalues stored in the closure.

### `debug.getproto`
- **Signature**: `debug.getproto(func: function, index: number, active?: boolean): function | { [number]: function }`
- **Description**: Retrieves child function prototypes (inner functions) defined within `func`.

### `debug.getprotos`
- **Signature**: `debug.getprotos(func: function): { [number]: function }`
- **Description**: Returns an array of all cloned child prototypes contained inside `func`.

### `debug.getregistry`
- **Signature**: `debug.getregistry(): table`
- **Description**: Returns the global Luau registry table holding persistent references and metatables.

### `debug.setconstant`
- **Signature**: `debug.setconstant(func: function, index: number, value: any): ()`
- **Description**: Replaces the constant at `index` in the function's constant table.

### `debug.setupvalue`
- **Signature**: `debug.setupvalue(func: function, index: number, value: any): ()`
- **Description**: Replaces the value of the upvalue at `index` for the given closure.

### `debug.setstack`
- **Signature**: `debug.setstack(level: number, index: number, value: any): ()`
- **Description**: Directly modifies an object on the current call stack at the given frame `level` and slot `index`.

---

## 5. FileSystem Library

Workspace file and folder I/O (sandboxed inside Potassium's workspace directory).

### `delfile`
- **Signature**: `delfile(path: string): ()`
- **Description**: Deletes the file at `path`.

### `delfolder`
- **Signature**: `delfolder(path: string): ()`
- **Description**: Deletes the directory at `path` along with its contents.

### `appendfile`
- **Signature**: `appendfile(path: string, content: string): ()`
- **Description**: Appends text to an existing file.

### `dofile`
- **Signature**: `dofile(path: string): any`
- **Description**: Reads and executes a file immediately in the current environment.

### `isfile`
- **Signature**: `isfile(path: string): boolean`
- **Description**: Returns `true` if `path` exists and is a file.

### `listfiles`
- **Signature**: `listfiles(path: string): { [number]: string }`
- **Description**: Returns a list of all relative file paths inside directory `path`.

### `loadfile`
- **Signature**: `loadfile(path: string): (function?, string?)`
- **Description**: Loads and compiles the file into a function chunk without executing it.

### `makefolder`
- **Signature**: `makefolder(path: string): ()`
- **Description**: Creates a new folder at `path`.

### `readfile`
- **Signature**: `readfile(path: string): string`
- **Description**: Reads and returns the entire contents of `path`.

### `writefile`
- **Signature**: `writefile(path: string, content: string): ()`
- **Description**: Writes text to `path`, overwriting any existing contents.

---

## 6. Input Library

OS/Window level input simulation. Inputs are only dispatched when the Roblox client window is focused.

### `mouse1click`
- **Signature**: `mouse1click(): ()`
- **Description**: Simulates a left-click down and up sequence.

### `mouse1press` / `mouse1release`
- **Signature**: `mouse1press(): ()`, `mouse1release(): ()`
- **Description**: Simulates pressing down or releasing the left mouse button.

### `mouse2click`
- **Signature**: `mouse2click(): ()`
- **Description**: Simulates a right-click down and up sequence.

### `mouse2press` / `mouse2release`
- **Signature**: `mouse2press(): ()`, `mouse2release(): ()`
- **Description**: Simulates pressing down or releasing the right mouse button.

### `mousemoveabs`
- **Signature**: `mousemoveabs(x: number, y: number): ()`
- **Description**: Moves the mouse cursor to absolute client screen coordinates `(x, y)`.

### `mousemoverel`
- **Signature**: `mousemoverel(deltaX: number, deltaY: number): ()`
- **Description**: Moves the mouse cursor by relative offset `(deltaX, deltaY)`.

### `mousescroll`
- **Signature**: `mousescroll(pixels: number): ()`
- **Description**: Simulates mouse wheel scrolling by the specified amount (positive scrolls up, negative down).

---

## 7. Instance Library

Game instance traversal, CoreGui hiding, and interaction simulation.

### `fireclickdetector`
- **Signature**: `fireclickdetector(detector: ClickDetector, distance?: number, signal?: string): ()`
- **Description**: Fires a `ClickDetector`.
- **Parameters**:
  - `distance`: Simulated distance to player (default `0`).
  - `signal`: `"MouseClick"` (default), `"RightMouseClick"`, `"MouseHoverEnter"`, `"MouseHoverLeave"`.

### `fireproximityprompt`
- **Signature**: `fireproximityprompt(prompt: ProximityPrompt): ()`
- **Description**: Instantly triggers the `Triggered` signal on a `ProximityPrompt` bypassing hold duration.

### `firetouchinterest`
- **Signature**: `firetouchinterest(part: BasePart, toTouch: BasePart, touchType: number): ()`
- **Description**: Simulates physics touch events.
- **Parameters**: `touchType = 0` for `Touched`, `1` for `TouchEnded`.

### `getcallbackvalue`
- **Signature**: `getcallbackvalue(instance: Instance, property: string): function?`
- **Description**: Retrieves the callback function assigned to callback properties (e.g., `BindableFunction.OnInvoke`).

### `getcustomasset`
- **Signature**: `getcustomasset(path: string): string`
- **Description**: Loads a local file from the workspace directory and generates a temporary `rbxasset://` URI usable by ImageLabels and sounds.

### `gethui`
- **Signature**: `gethui(): Folder | ScreenGui`
- **Description**: Returns a secure GUI container parented outside normal game hierarchy, hidden from game scripts.

### `getinstances`
- **Signature**: `getinstances(): { [number]: Instance }`
- **Description**: Returns an array of every allocated `Instance` currently loaded in memory.

### `getnilinstances`
- **Signature**: `getnilinstances(): { [number]: Instance }`
- **Description**: Returns an array of instances whose `Parent` is `nil` (often cached or hidden assets).

### `getrendersteppedlist`
- **Signature**: `getrendersteppedlist(): { [number]: function }`
- **Description**: Returns all callbacks bound via `RunService:BindToRenderStep`.

---

## 8. Metatable Library

Metatable reading and metamethod manipulation.

### `getnamecallmethod`
- **Signature**: `getnamecallmethod(): string`
- **Description**: Returns the method name of the current `__namecall` invocation (e.g. `"FireServer"`, `"InvokeServer"`).

### `getrawmetatable`
- **Signature**: `getrawmetatable(target: table | userdata | Instance): table?`
- **Description**: Retrieves the metatable of `target`, bypassing `__metatable` locks.

### `hookmetamethod`
- **Signature**: `hookmetamethod(target: Instance | table | userdata, method: string, hook: function): function`
- **Description**: Hooks a metamethod (e.g., `"__index"`, `"__namecall"`, `"__newindex"`). Returns the original metamethod.
- **Example**:
  ```lua
  local oldNamecall
  oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
      local method = getnamecallmethod()
      if method == "FireServer" and tostring(self) == "ReportRemote" then
          return nil
      end
      return oldNamecall(self, ...)
  end)
  ```

### `isreadonly`
- **Signature**: `isreadonly(t: table): boolean`
- **Description**: Checks whether `t` is marked as read-only.

### `makereadonly` / `setreadonly`
- **Signature**: `makereadonly(t: table): ()`, `setreadonly(t: table, readonly: boolean): ()`
- **Description**: Modifies the read-only flag of a table.

### `setnamecallmethod`
- **Signature**: `setnamecallmethod(method: string): ()`
- **Description**: Modifies the active method string returned during `__namecall`.

### `setrawmetatable`
- **Signature**: `setrawmetatable(target: table | userdata | Instance, mt: table): ()`
- **Description**: Sets the metatable of `target` even if protected by `__metatable`.

---

## 9. Miscellaneous Library

Executor identification, HTTP requests, clipboard, and game engine settings.

### `clearteleportqueue`
- **Signature**: `clearteleportqueue(): ()`
- **Description**: Clears any queued scripts registered with `queueonteleport`.

### `getfpscap` / `setfpscap`
- **Signature**: `getfpscap(): number`, `setfpscap(fps: number): ()`
- **Description**: Gets or sets the target FPS limit for the Roblox client.

### `gethwid`
- **Signature**: `gethwid(): string`
- **Description**: Returns a unique hardware identifier string for the host machine.

### `getfflag` / `setfflag` / `getfflagtype`
- **Signature**:
  - `getfflag(flag: string): string`
  - `setfflag(flag: string, value: string): boolean`
  - `getfflagtype(flag: string): string`
- **Description**: Read and modify Roblox Fast Flags at runtime.

### `getobjects`
- **Signature**: `getobjects(assetId: string): { [number]: Instance }`
- **Description**: Loads and deserializes Roblox assets from `assetId` (equivalent to `game:GetObjects`).

### `httpget` *(or `game.HttpGet`)*
- **Signature**: `httpget(url: string): string`
- **Description**: Synchronously sends an HTTP GET request to `url` and returns the body string.

### `identifyexecutor`
- **Signature**: `identifyexecutor(): (name: string, version: string)`
- **Description**: Returns the executor name (`"Potassium"`) and current build version.

### `messagebox`
- **Signature**: `messagebox(text: string, caption: string, flags: number): number`
- **Description**: Spawns a native Windows message box modal and returns the user's clicked button ID.

### `request`
- **Signature**:
  ```lua
  request(options: {
      Url: string,
      Method?: string, -- "GET", "POST", etc.
      Headers?: { [string]: string },
      Body?: string,
      Cookies?: { [string]: string }
  }): {
      StatusCode: number,
      StatusMessage: string,
      Headers: { [string]: string },
      Body: string,
      Success: boolean
  }
  ```
- **Description**: Full-featured HTTP client supporting custom headers, verbs, and payloads.

### `saveinstance`
- **Signature**: `saveinstance(options?: table): ()`
- **Description**: Serializes and dumps the current game hierarchy or specific instances into a `.rbxl` or `.rbxm` file.

### `setclipboard` / `setrbxclipboard`
- **Signature**: `setclipboard(text: string): ()`, `setrbxclipboard(text: string): ()`
- **Description**: Copies text to the OS clipboard or Roblox Studio clipboard.

---

## 10. RakNet Library

Raw network packet interception and spoofing.

### `raknet`
`raknet` is a library table providing deep network hook functions:
- **`raknet.add_send_hook(callback: (packet: RakNetPacket) -> boolean?)`**: Intercepts packets before sending. Returning `true` drops the packet.
- **`raknet.remove_send_hook(hookId: any)`**: Unregisters a send hook.
- **`raknet.add_receive_hook(callback: (packet: RakNetPacket) -> boolean?)`**: Intercepts packets before client processing.
- **`raknet.remove_receive_hook(hookId: any)`**: Unregisters a receive hook.
- **`raknet.send(payload: string, priority: number, reliability: number, channel: number)`**: Injects a custom raw network packet into the connection.

---

## 11. Reflection Library

Access to hidden, non-scriptable properties and engine physics configurations.

### `getbspval`
- **Signature**: `getbspval(instance: Instance, property: string): string`
- **Description**: Reads unscriptable `BinaryString` properties (e.g. `Terrain.SmoothGrid`, `PartOperation.PhysicsData`).

### `gethiddenproperty` / `sethiddenproperty`
- **Signature**:
  - `gethiddenproperty(instance: Instance, property: string): (any, boolean)`
  - `sethiddenproperty(instance: Instance, property: string, value: any): boolean`
- **Description**: Gets or sets hidden / non-scriptable engine properties.

### `gethiddenproperties` / `getproperties`
- **Signature**:
  - `gethiddenproperties(instance: Instance): { [string]: any }`
  - `getproperties(instance: Instance): { [string]: any }`
- **Description**: Dumps a dictionary of all hidden properties or all properties on an instance.

### `getpcd`
- **Signature**: `getpcd(meshPart: TriangleMeshPart): (string, string)`
- **Description**: Returns the 16-byte hash and raw binary data corresponding to `PhysicalConfigData`.

### `getproximitypromptduration` / `setproximitypromptduration`
- **Signature**:
  - `getproximitypromptduration(prompt: ProximityPrompt): number`
  - `setproximitypromptduration(prompt: ProximityPrompt, duration: number): ()`
- **Description**: Reads or overrides prompt hold durations.

### `getsimulationradius` / `setsimulationradius`
- **Signature**: `getsimulationradius(): number`, `setsimulationradius(radius: number): ()`
- **Description**: Reads or modifies the physics simulation radius for `LocalPlayer`.

### `isnetworkowner`
- **Signature**: `isnetworkowner(part: BasePart): boolean`
- **Description**: Returns `true` if `LocalPlayer` has physics network ownership over `part`.

### `isscriptable` / `setscriptable`
- **Signature**:
  - `isscriptable(instance: Instance, property: string): boolean`
  - `setscriptable(instance: Instance, property: string, scriptable: boolean): ()`
- **Description**: Checks or toggles whether an engine property can be indexed or modified by Luau scripts.

---

## 12. Script Library

Inspection, decompilation, thread identification, and bytecode retrieval.

### `getloadedmodules`
- **Signature**: `getloadedmodules(): { [number]: ModuleScript }`
- **Description**: Returns all `ModuleScript` instances that have been required and loaded into memory.

### `getrunningscripts` / `getscripts`
- **Signature**: `getrunningscripts(): { [number]: LocalScript | ModuleScript }`, `getscripts(): { [number]: LocalScript | ModuleScript }`
- **Description**: Returns all currently executing scripts or all scripts in the game.

### `getscriptbytecode` / `dumpbytecode`
- **Signature**: `getscriptbytecode(script: LocalScript | ModuleScript): string`, `dumpbytecode(func: function): string`
- **Description**: Dumps raw compiled Luau bytecode.

### `getscriptclosure`
- **Signature**: `getscriptclosure(script: LocalScript | ModuleScript): function`
- **Description**: Retrieves the root closure/function of a script.

### `getscriptfromthread` / `getscriptthread`
- **Signature**:
  - `getscriptfromthread(thread: thread): (LocalScript | ModuleScript)?`
  - `getscriptthread(script: LocalScript | ModuleScript): thread?`
- **Description**: Maps execution threads to their associated scripts and vice versa.

### `getscripthash`
- **Signature**: `getscripthash(script: LocalScript | ModuleScript): string`
- **Description**: Returns a hash of the script's source/bytecode.

### `getthreadidentity` / `setthreadidentity`
- **Signature**: `getthreadidentity(): number`, `setthreadidentity(identity: number): ()`
- **Description**: Gets or sets the thread security identity level (e.g., 2 for game scripts, 7/8 for executor scripts).
- **Aliases**: `getidentity`, `setidentity`

### `decompile`
- **Signature**: `decompile(target: LocalScript | ModuleScript | function): string`
- **Description**: Disassembles and decompiles Luau bytecode into human-readable Luau source code.

---

## 13. Signal Library

Direct firing, inspection, and network replication of `RBXScriptSignal` connections.

### `firesignal`
- **Signature**: `firesignal(signal: RBXScriptSignal, ...: any?): ()`
- **Description**: Fires all client-side connected callbacks on an `RBXScriptSignal`.
- **Example**:
  ```lua
  firesignal(game.Players.LocalPlayer.Idled)
  ```

### `cansignalreplicate`
- **Signature**: `cansignalreplicate(signal: RBXScriptSignal): boolean`
- **Description**: Returns `true` if Roblox allows firing this signal across the network to the server.

### `getconnection` / `getconnections`
- **Signature**:
  - `getconnection(signal: RBXScriptSignal, index: number): Connection`
  - `getconnections(signal: RBXScriptSignal): { [number]: Connection }`
- **Description**: Returns objects representing listeners attached to the signal.
- **Connection methods**: `connection:Disable()`, `connection:Enable()`, `connection:Fire(...)`, `connection.Function`.

### `getsignalarguments` / `getsignalargumentsinfo`
- **Signature**:
  - `getsignalarguments(signal: RBXScriptSignal): { [number]: string }`
  - `getsignalargumentsinfo(signal: RBXScriptSignal): table`
- **Description**: Inspects expected argument types and replication metadata for the signal.

### `getsignalwhitelist`
- **Signature**: `getsignalwhitelist(): { [number]: SignalWhitelistInfo }`
- **Description**: Returns the list of `RBXScriptSignal` types in Roblox's network replication whitelist.

### `replicatesignal`
- **Signature**: `replicatesignal(signal: RBXScriptSignal, ...: any?): ()`
- **Description**: Forces the signal to replicate its invocation to the server (must be a replicable signal with valid arguments).

---

## 14. WebSocket Library

Full-duplex real-time communication via WebSockets.

### `WebSocket.connect`
- **Signature**: `WebSocket.connect(url: string): WebSocket`
- **Description**: Connects to a WebSocket server.
- **Object API**:
  ```lua
  local ws = WebSocket.connect("ws://localhost:8080")
  ws.OnMessage:Connect(function(msg)
      print("WS Received:", msg)
  end)
  ws.OnClose:Connect(function()
      print("WS Closed")
  end)
  ws:Send("Hello Server!")
  ws:Close()
  ```

---

## eVars.luau Naming & Compatibility Map

If checking compatibility against [eVars.luau](file:///c:/Users/Gouang/Desktop/Gousse/eVars.luau), observe the following name mappings and common aliases:

| `eVars.luau` Variable | Official Potassium Doc Name | Notes / Alias |
| :--- | :--- | :--- |
| `getdeleteactors` | `getdeletedactors` | Docs specify `getdeletedactors` with 'd' |
| `isparallel` | `is_parallel` | Docs specify `is_parallel` (underscore) |
| `issourthread` | `isourthread` | Docs specify `isourthread` / `checkcaller` |
| `cloneref` / `CLoneRef` | `cloneref` | Standard Luau reference isolation |
| `gethiddenproperties` / `GetHiddenProperteis` | `gethiddenproperties` | Fix spelling in label |
| `httpget or game.HttpGet` | `httpget` | Also exposed via `game:HttpGet` |
| `dumpbytecode` | `dumpbytecode` | Dumps function bytecode |
| `decompile` | `decompile` | Bytecode decompiler |
