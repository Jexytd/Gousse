// Gousse Studio - Professional Work Tool State
let manifest = { version: "1.0.0", universal: "games/universal.luau", games: {}, tasks: [] };
let activeView = 'pipeline';
let activePipelineMode = 'kanban';
let activeAssigneeFilter = 'all';
let currentEditingTaskId = null;
let currentEditingGameId = null;

let currentOpenFile = null;
let currentFileOriginalContent = '';
let monacoEditor = null;
let monacoInitialized = false;
let currentProblems = [];

const LOADER_SNIPPET = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Jexytd/Gousse/main/Init.luau"))()';

// Elements
const navItems = document.querySelectorAll('.nav-item');
const navFilters = document.querySelectorAll('.nav-filter');
const viewPanels = document.querySelectorAll('.view-panel');
const viewHeading = document.getElementById('view-heading');
const viewSubheading = document.getElementById('view-subheading');

const navTaskCount = document.getElementById('nav-task-count');
const navGameCount = document.getElementById('nav-game-count');
const navGitStatusDot = document.getElementById('nav-git-status-dot');
const gitBranchIndicator = document.getElementById('git-branch-indicator');

const pipelineViewSwitch = document.getElementById('pipeline-view-switch');
const btnSwitchKanban = document.getElementById('btn-switch-kanban');
const btnSwitchTable = document.getElementById('btn-switch-table');
const btnTopAction = document.getElementById('btn-top-action');

// Pipeline elements
const taskSearch = document.getElementById('task-search');
const filterGame = document.getElementById('filter-game');
const filterPriority = document.getElementById('filter-priority');
const kanbanBoard = document.getElementById('kanban-board');
const taskTableView = document.getElementById('task-table-view');
const taskTableBody = document.getElementById('task-table-body');

// Registry elements
const registryTableBody = document.getElementById('registry-table-body');
const registrySearch = document.getElementById('registry-search');
const btnRegisterGame = document.getElementById('btn-register-game');

// Studio elements
const filetreeList = document.getElementById('filetree-list');
const btnRefreshFiles = document.getElementById('btn-refresh-files');
const monacoContainer = document.getElementById('monaco-container');
const fallbackTextarea = document.getElementById('studio-textarea-fallback');
const activeTabName = document.getElementById('active-tab-name');
const fileDirtyDot = document.getElementById('file-dirty-dot');
const editorFilePathHint = document.getElementById('editor-file-path-hint');
const btnSaveCode = document.getElementById('btn-save-code');
const editorLineCol = document.getElementById('editor-line-col');
const editorCharCount = document.getElementById('editor-char-count');

// Problems Panel Elements
const problemsPanel = document.getElementById('problems-panel');
const btnToggleProblems = document.getElementById('btn-toggle-problems');
const btnCloseProblems = document.getElementById('btn-close-problems');
const problemsList = document.getElementById('problems-list');
const problemsTotalBadge = document.getElementById('problems-total-badge');
const statusErrorCount = document.getElementById('status-error-count');
const statusWarnCount = document.getElementById('status-warn-count');
const statusErrGroup = document.getElementById('status-err-group');
const statusWarnGroup = document.getElementById('status-warn-group');

// Deployment elements
const btnCheckGit = document.getElementById('btn-check-git');
const gitBranchVal = document.getElementById('git-branch-val');
const gitTreeVal = document.getElementById('git-tree-val');
const gitDiffList = document.getElementById('git-diff-list');
const deployCommitMsg = document.getElementById('deploy-commit-msg');
const btnExecPush = document.getElementById('btn-exec-push');
const btnCopyBox = document.getElementById('btn-copy-box');
const btnQuickLoader = document.getElementById('btn-quick-loader');

// Task Modal
const taskModal = document.getElementById('task-modal');
const taskInputId = document.getElementById('task-input-id');
const taskInputStatus = document.getElementById('task-input-status');
const taskInputTitle = document.getElementById('task-input-title');
const taskInputGame = document.getElementById('task-input-game');
const taskInputAssignee = document.getElementById('task-input-assignee');
const taskInputPriority = document.getElementById('task-input-priority');
const taskInputDeadline = document.getElementById('task-input-deadline');
const taskInputDesc = document.getElementById('task-input-desc');
const btnCloseTaskModal = document.getElementById('btn-close-task-modal');
const btnCancelTask = document.getElementById('btn-cancel-task');
const btnSaveTask = document.getElementById('btn-save-task');
const btnDeleteTask = document.getElementById('btn-delete-task');

// Game Modal
const gameModal = document.getElementById('game-modal');
const regGameName = document.getElementById('reg-game-name');
const regUniverseId = document.getElementById('reg-universe-id');
const regLead = document.getElementById('reg-lead');
const regStatus = document.getElementById('reg-status');
const regEntryPath = document.getElementById('reg-entry-path');
const regPlacesList = document.getElementById('reg-places-list');
const btnRegAddPlace = document.getElementById('btn-reg-add-place');
const btnCloseGameModal = document.getElementById('btn-close-game-modal');
const btnCancelGame = document.getElementById('btn-cancel-game');
const btnSaveGameReg = document.getElementById('btn-save-game-reg');

const toast = document.getElementById('toast');

// Toast feedback
function showToast(msg) {
  toast.textContent = msg;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2400);
}

// ==========================================
// 1. Monaco Editor & Luau Language Services
// ==========================================

function initMonaco() {
  if (typeof require !== 'undefined' && require.config) {
    require.config({ paths: { vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs' } });
    require(['vs/editor/editor.main'], function () {
      setupMonacoEnvironment();
    });
  } else {
    setTimeout(initMonaco, 200);
  }
}

function setupMonacoEnvironment() {
  if (monacoInitialized) return;

  // Define Gousse Dark Theme (LuaLS / VS Code Dark+ Highlighting)
  monaco.editor.defineTheme('gousse-dark', {
    base: 'vs-dark',
    inherit: true,
    rules: [
      { token: 'comment', foreground: '6A9955', fontStyle: 'italic' },
      { token: 'keyword.control', foreground: 'C586C0' },
      { token: 'keyword.storage', foreground: '569CD6' },
      { token: 'keyword', foreground: 'C586C0' },
      { token: 'string', foreground: 'CE9178' },
      { token: 'number', foreground: 'B5CEA8' },
      { token: 'number.hex', foreground: 'B5CEA8' },
      { token: 'entity.name.type', foreground: '4EC9B0' },
      { token: 'type', foreground: '4EC9B0' },
      { token: 'class', foreground: '4EC9B0' },
      { token: 'entity.name.function', foreground: 'DCDCAA' },
      { token: 'entity.name.function.method', foreground: 'DCDCAA' },
      { token: 'support.function', foreground: 'DCDCAA' },
      { token: 'function', foreground: 'DCDCAA' },
      { token: 'method', foreground: 'DCDCAA' },
      { token: 'variable.other.property', foreground: '9CDCFE' },
      { token: 'variable.other.member', foreground: '9CDCFE' },
      { token: 'property', foreground: '9CDCFE' },
      { token: 'event', foreground: '9CDCFE' },
      { token: 'variable.language', foreground: '569CD6' },
      { token: 'variable.name', foreground: '9CDCFE' },
      { token: 'variable.parameter', foreground: '9CDCFE' },
      { token: 'parameter', foreground: '9CDCFE' },
      { token: 'variable', foreground: '9CDCFE' },
      { token: 'identifier', foreground: '9CDCFE' },
      { token: 'operator', foreground: 'D4D4D4' },
      { token: 'delimiter', foreground: 'D4D4D4' }
    ],
    colors: {
      'editor.background': '#1E1E1E',
      'editor.foreground': '#D4D4D4',
      'editor.lineHighlightBackground': '#282828',
      'editorLineNumber.foreground': '#858585',
      'editorLineNumber.activeForeground': '#C6C6C6',
      'editor.selectionBackground': '#264F78',
      'editorCursor.foreground': '#AEAFAD',
      'editorBracketMatch.background': '#0D3A58',
      'editorBracketMatch.border': '#888888',
      'editorSuggestWidget.background': '#1D1526',
      'editorSuggestWidget.border': '#4D386B',
      'editorSuggestWidget.foreground': '#DFDAD6',
      'editorSuggestWidget.selectedBackground': '#3B2A52',
      'editorSuggestWidget.selectedForeground': '#2AA9FE',
      'editorSuggestWidget.highlightForeground': '#2AA9FE',
      'editorSuggestWidget.focusHighlightForeground': '#2AA9FE',
      'list.focusBackground': '#3B2A52',
      'list.activeSelectionBackground': '#3B2A52',
      'list.inactiveSelectionBackground': '#2A1D3D',
      'list.hoverBackground': '#261B3D',
      'list.highlightForeground': '#2AA9FE'
    }
  });

  // Initialize and register full Roblox LSP Engine (Completions, Hovers, Signatures)
  const lsp = (typeof window !== 'undefined' && window.RobloxLSP) || (typeof RobloxLSP !== 'undefined' ? RobloxLSP : null);
  if (lsp) {
    lsp.init();
    lsp.registerWithMonaco(monaco);
    console.log('[App] Successfully initialized and registered RobloxLSP');
  } else {
    console.warn('[App] RobloxLSP not found');
  }

  // Create Editor Instance
  monacoEditor = monaco.editor.create(monacoContainer, {
    value: '-- Select a file from the explorer...',
    language: 'lua',
    theme: 'gousse-dark',
    automaticLayout: true,
    fontSize: 12.5,
    fontFamily: "'JetBrains Mono', monospace",
    lineHeight: 20,
    renderLineHighlight: 'all',
    minimap: { enabled: false },
    scrollBeyondLastLine: false,
    tabSize: 4,
    bracketPairColorization: { enabled: true },
    quickSuggestions: {
      other: true,
      comments: false,
      strings: true
    },
    suggest: {
      showWords: false,
      snippetsPreventQuickSuggestions: false,
      filterGraceful: true,
      localityBonus: true
    },
    suggestOnTriggerCharacters: true
  });

  monaco.editor.setTheme('gousse-dark');

  monacoInitialized = true;

  // Listen to content changes for real-time Luau linter & dirty check
  monacoEditor.onDidChangeModelContent(() => {
    checkLuauProblems();
    updateEditorDirty();
  });

  // Cursor position update
  monacoEditor.onDidChangeCursorPosition(e => {
    editorLineCol.textContent = `Ln ${e.position.lineNumber}, Col ${e.position.column}`;
  });

  // Hotkey: Ctrl+S to save
  monacoEditor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS, () => {
    if (!btnSaveCode.disabled) saveCurrentCode();
  });

  // If a file was waiting to be opened, load it into Monaco
  if (currentOpenFile) {
    setMonacoContent(currentFileOriginalContent, currentOpenFile);
  }
}

// Register Luau, Roblox API & Potassium Completions
function registerLuauCompletions() {
  // Autocompletion is handled by RobloxLSP in roblox-lsp.js
  return;
  monaco.languages.registerCompletionItemProvider('lua', {
    triggerCharacters: ['.', ':', ' '],
    provideCompletionItems: function (model, position) {
      const lineContent = model.getLineContent(position.lineNumber);
      const textUntilPosition = lineContent.substring(0, position.column - 1);
      const suggestions = [];

      // Detect trigger: dot or colon
      const isColon = textUntilPosition.endsWith(':');
      const isDot = textUntilPosition.endsWith('.');

      if (isColon) {
        // Method suggestions
        const methods = [
          { label: 'GetService', insertText: 'GetService("${1:ServiceName}")', detail: 'DataModel:GetService', doc: 'Retrieves a Roblox engine service.' },
          { label: 'FindFirstChild', insertText: 'FindFirstChild("${1:Name}")', detail: 'Instance:FindFirstChild', doc: 'Finds the first child with the specified name.' },
          { label: 'WaitForChild', insertText: 'WaitForChild("${1:Name}", ${2:10})', detail: 'Instance:WaitForChild', doc: 'Yields until a child is added.' },
          { label: 'GetChildren', insertText: 'GetChildren()', detail: 'Instance:GetChildren', doc: 'Returns an array of children.' },
          { label: 'GetDescendants', insertText: 'GetDescendants()', detail: 'Instance:GetDescendants', doc: 'Returns an array of all descendants.' },
          { label: 'Connect', insertText: 'Connect(function(${1:...})\n\t$0\nend)', detail: 'RBXScriptSignal:Connect', doc: 'Connects a callback to this event.' },
          { label: 'Disconnect', insertText: 'Disconnect()', detail: 'RBXScriptConnection:Disconnect', doc: 'Disconnects listener.' },
          { label: 'FireServer', insertText: 'FireServer(${1:...})', detail: 'RemoteEvent:FireServer', doc: 'Fires event across network to server.' },
          { label: 'InvokeServer', insertText: 'InvokeServer(${1:...})', detail: 'RemoteFunction:InvokeServer', doc: 'Invokes server and yields for response.' },
          { label: 'JSONEncode', insertText: 'JSONEncode(${1:data})', detail: 'HttpService:JSONEncode', doc: 'Serializes table to JSON string.' },
          { label: 'JSONDecode', insertText: 'JSONDecode(${1:json})', detail: 'HttpService:JSONDecode', doc: 'Deserializes JSON string to table.' },
          { label: 'HttpGet', insertText: 'HttpGet("${1:url}")', detail: 'game:HttpGet', doc: 'Performs synchronous HTTP GET.' },
          { label: 'Destroy', insertText: 'Destroy()', detail: 'Instance:Destroy', doc: 'Destroys instance and all descendants.' },
          { label: 'Clone', insertText: 'Clone()', detail: 'Instance:Clone', doc: 'Duplicates instance and its subtree.' }
        ];

        methods.forEach(m => {
          suggestions.push({
            label: m.label,
            kind: monaco.languages.CompletionItemKind.Method,
            insertText: m.insertText,
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            detail: m.detail,
            documentation: m.doc
          });
        });

        return { suggestions };
      }

      if (isDot) {
        // Property / Library member suggestions
        const members = [
          // task library
          { label: 'wait', insertText: 'wait(${1:seconds})', detail: 'task.wait', doc: 'Yields thread efficiently.' },
          { label: 'spawn', insertText: 'spawn(${1:function()})\n\t$0\nend', detail: 'task.spawn', doc: 'Executes function in a new thread.' },
          { label: 'delay', insertText: 'delay(${1:sec}, ${2:function()})\n\t$0\nend', detail: 'task.delay', doc: 'Schedules thread after delay.' },
          { label: 'defer', insertText: 'defer(${1:function()})\n\t$0\nend', detail: 'task.defer', doc: 'Defers thread until end of step.' },
          { label: 'cancel', insertText: 'cancel(${1:thread})', detail: 'task.cancel', doc: 'Terminates a thread.' },
          // math
          { label: 'clamp', insertText: 'clamp(${1:n}, ${2:min}, ${3:max})', detail: 'math.clamp' },
          { label: 'floor', insertText: 'floor(${1:n})', detail: 'math.floor' },
          { label: 'ceil', insertText: 'ceil(${1:n})', detail: 'math.ceil' },
          { label: 'random', insertText: 'random(${1:min}, ${2:max})', detail: 'math.random' },
          // table
          { label: 'insert', insertText: 'insert(${1:tbl}, ${2:val})', detail: 'table.insert' },
          { label: 'remove', insertText: 'remove(${1:tbl}, ${2:index})', detail: 'table.remove' },
          { label: 'find', insertText: 'find(${1:tbl}, ${2:needle})', detail: 'table.find' },
          { label: 'clear', insertText: 'clear(${1:tbl})', detail: 'table.clear' },
          // Instance constructors
          { label: 'new', insertText: 'new("${1:Part}")', detail: 'Instance.new' },
          // Common properties
          { label: 'LocalPlayer', insertText: 'LocalPlayer', detail: 'Players.LocalPlayer' },
          { label: 'Character', insertText: 'Character', detail: 'Player.Character' },
          { label: 'Humanoid', insertText: 'Humanoid', detail: 'Character.Humanoid' },
          { label: 'HumanoidRootPart', insertText: 'HumanoidRootPart', detail: 'Root CFrame BasePart' },
          { label: 'Position', insertText: 'Position', detail: 'Vector3' },
          { label: 'CFrame', insertText: 'CFrame', detail: 'CFrame' },
          { label: 'Parent', insertText: 'Parent', detail: 'Instance' },
          { label: 'Name', insertText: 'Name', detail: 'string' }
        ];

        members.forEach(m => {
          suggestions.push({
            label: m.label,
            kind: monaco.languages.CompletionItemKind.Property,
            insertText: m.insertText,
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            detail: m.detail,
            documentation: m.doc
          });
        });

        return { suggestions };
      }

      // Root Global Suggestions: Roblox Globals, Services, Potassium APIs, and Luau keywords
      const globals = [
        // Roblox Services
        { label: 'Players', insertText: 'game:GetService("Players")', detail: 'Roblox Players Service' },
        { label: 'HttpService', insertText: 'game:GetService("HttpService")', detail: 'Roblox HttpService' },
        { label: 'RunService', insertText: 'game:GetService("RunService")', detail: 'Roblox RunService' },
        { label: 'ReplicatedStorage', insertText: 'game:GetService("ReplicatedStorage")', detail: 'Roblox ReplicatedStorage' },
        { label: 'UserInputService', insertText: 'game:GetService("UserInputService")', detail: 'Roblox UserInputService' },
        { label: 'TweenService', insertText: 'game:GetService("TweenService")', detail: 'Roblox TweenService' },
        { label: 'StarterGui', insertText: 'game:GetService("StarterGui")', detail: 'Roblox StarterGui' },
        { label: 'TeleportService', insertText: 'game:GetService("TeleportService")', detail: 'Roblox TeleportService' },
        // Globals
        { label: 'game', insertText: 'game', detail: 'DataModel root' },
        { label: 'workspace', insertText: 'workspace', detail: 'Workspace service' },
        { label: 'script', insertText: 'script', detail: 'Script reference' },
        { label: 'task', insertText: 'task', detail: 'Task scheduler library' },
        { label: 'Vector3.new', insertText: 'Vector3.new(${1:x}, ${2:y}, ${3:z})', detail: 'Construct Vector3' },
        { label: 'CFrame.new', insertText: 'CFrame.new(${1:x}, ${2:y}, ${3:z})', detail: 'Construct CFrame' },
        { label: 'Color3.fromRGB', insertText: 'Color3.fromRGB(${1:255}, ${2:255}, ${3:255})', detail: 'Construct Color3' },
        { label: 'UDim2.new', insertText: 'UDim2.new(${1:0}, ${2:0}, ${3:0}, ${4:0})', detail: 'Construct UDim2' },
        { label: 'pcall', insertText: 'local ${1:success}, ${2:result} = pcall(function()\n\t$0\nend)', detail: 'Protected call' },
        // Potassium / Exploit Functions
        { label: 'hookfunction', insertText: 'hookfunction(${1:target}, ${2:hook})', detail: 'Potassium: Hook function' },
        { label: 'hookmetamethod', insertText: 'hookmetamethod(${1:game}, "${2:__namecall}", function(self, ...)\n\t$0\nend)', detail: 'Potassium: Hook metamethod' },
        { label: 'getnamecallmethod', insertText: 'getnamecallmethod()', detail: 'Potassium: Current __namecall method' },
        { label: 'setnamecallmethod', insertText: 'setnamecallmethod("${1:method}")', detail: 'Potassium: Set __namecall method' },
        { label: 'getrawmetatable', insertText: 'getrawmetatable(${1:target})', detail: 'Potassium: Bypasses __metatable' },
        { label: 'setrawmetatable', insertText: 'setrawmetatable(${1:target}, ${2:mt})', detail: 'Potassium: Sets raw metatable' },
        { label: 'cloneref', insertText: 'cloneref(${1:instance})', detail: 'Potassium: Isolated instance reference' },
        { label: 'compareinstances', insertText: 'compareinstances(${1:a}, ${2:b})', detail: 'Potassium: Compare instance equality' },
        { label: 'fireclickdetector', insertText: 'fireclickdetector(${1:detector}, ${2:0})', detail: 'Potassium: Fire ClickDetector' },
        { label: 'fireproximityprompt', insertText: 'fireproximityprompt(${1:prompt})', detail: 'Potassium: Fire ProximityPrompt' },
        { label: 'firetouchinterest', insertText: 'firetouchinterest(${1:part}, ${2:toTouch}, ${3:0})', detail: 'Potassium: Fire Touched' },
        { label: 'firesignal', insertText: 'firesignal(${1:signal}, ${2:...})', detail: 'Potassium: Fire RBXScriptSignal' },
        { label: 'cansignalreplicate', insertText: 'cansignalreplicate(${1:signal})', detail: 'Potassium: Check signal replication' },
        { label: 'gethui', insertText: 'gethui()', detail: 'Potassium: Get Hidden CoreGui' },
        { label: 'getinstances', insertText: 'getinstances()', detail: 'Potassium: Get all instances' },
        { label: 'getnilinstances', insertText: 'getnilinstances()', detail: 'Potassium: Get nil-parented instances' },
        { label: 'readfile', insertText: 'readfile("${1:path}")', detail: 'Potassium FileSystem: Read file' },
        { label: 'writefile', insertText: 'writefile("${1:path}", ${2:content})', detail: 'Potassium FileSystem: Write file' },
        { label: 'loadstring', insertText: 'loadstring(${1:source})()', detail: 'Compile & Execute Luau chunk' },
        { label: 'identifyexecutor', insertText: 'identifyexecutor()', detail: 'Potassium: Returns ("Potassium", version)' },
        { label: 'request', insertText: 'request({\n\tUrl = "${1:url}",\n\tMethod = "GET"\n})', detail: 'Potassium: HTTP client request' },
        { label: 'WebSocket.connect', insertText: 'WebSocket.connect("${1:ws://localhost:8080}")', detail: 'Potassium: Connect WebSocket' }
      ];

      globals.forEach(g => {
        suggestions.push({
          label: g.label,
          kind: monaco.languages.CompletionItemKind.Function,
          insertText: g.insertText,
          insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
          detail: g.detail
        });
      });

      return { suggestions };
    }
  });
}

// ==========================================
// 2. Real-Time Luau Syntax Linter
// ==========================================

function checkLuauProblems() {
  if (!monacoEditor) return;
  const model = monacoEditor.getModel();
  if (!model) return;

  const content = model.getValue();
  const markers = [];
  currentProblems = [];

  const lines = content.split('\n');

  // Block opener/closer tracking stack
  const blockStack = []; // { type: 'function'|'if'|'for'|'while'|'do'|'repeat', line: number }
  const parenStack = []; // { line: number, col: number }
  const braceStack = []; // { line: number, col: number }
  const bracketStack = [];

  let inBlockComment = false;
  let inBlockString = false;

  lines.forEach((lineText, lineIdx) => {
    const lineNum = lineIdx + 1;
    let sanitized = lineText;

    // Handle multiline comments
    if (inBlockComment) {
      if (sanitized.includes(']]')) {
        inBlockComment = false;
        sanitized = sanitized.substring(sanitized.indexOf(']]') + 2);
      } else {
        return; // whole line inside comment
      }
    }

    if (sanitized.includes('--[[')) {
      if (!sanitized.includes(']]')) {
        inBlockComment = true;
        sanitized = sanitized.substring(0, sanitized.indexOf('--[['));
      } else {
        sanitized = sanitized.replace(/--\[\[.*?\]\]/g, '');
      }
    }

    // Strip single-line comments
    const commentIdx = sanitized.indexOf('--');
    if (commentIdx >= 0) {
      sanitized = sanitized.substring(0, commentIdx);
    }

    // Warning check: Legacy wait() vs task.wait()
    const legacyWaitMatch = sanitized.match(/\bwait\s*\(/);
    if (legacyWaitMatch && !sanitized.includes('task.wait') && !sanitized.includes(':wait')) {
      const col = sanitized.indexOf('wait(') + 1;
      addMarker(markers, lineNum, col, col + 4, 'Legacy wait() is throttled; consider using task.wait()', monaco.MarkerSeverity.Warning);
    }

    // Warning check: Legacy spawn() vs task.spawn()
    const legacySpawnMatch = sanitized.match(/\bspawn\s*\(/);
    if (legacySpawnMatch && !sanitized.includes('task.spawn')) {
      const col = sanitized.indexOf('spawn(') + 1;
      addMarker(markers, lineNum, col, col + 5, 'Legacy spawn() adds a frame delay; consider using task.spawn()', monaco.MarkerSeverity.Warning);
    }

    // Warning check: Assignment in if condition (e.g., if a = 5 then)
    const assignInIf = sanitized.match(/\bif\s+([a-zA-Z0-9_\.]+)\s*=\s*([a-zA-Z0-9_\'\"\(]+)\s+then\b/);
    if (assignInIf) {
      addMarker(markers, lineNum, 1, sanitized.length + 1, "Assignment '=' inside conditional; did you mean '=='?", monaco.MarkerSeverity.Warning);
    }

    // Check Unclosed string literal on this line
    checkUnclosedStrings(sanitized, lineNum, markers);

    // Track Delimiters
    for (let c = 0; c < sanitized.length; c++) {
      const ch = sanitized[c];
      const col = c + 1;
      if (ch === '(') parenStack.push({ line: lineNum, col });
      else if (ch === ')') {
        if (parenStack.length === 0) {
          addMarker(markers, lineNum, col, col + 1, "Unexpected closing ')' with no matching opening '('", monaco.MarkerSeverity.Error);
        } else {
          parenStack.pop();
        }
      } else if (ch === '{') braceStack.push({ line: lineNum, col });
      else if (ch === '}') {
        if (braceStack.length === 0) {
          addMarker(markers, lineNum, col, col + 1, "Unexpected closing '}' with no matching opening '{'", monaco.MarkerSeverity.Error);
        } else {
          braceStack.pop();
        }
      } else if (ch === '[') bracketStack.push({ line: lineNum, col });
      else if (ch === ']') {
        if (bracketStack.length === 0) {
          addMarker(markers, lineNum, col, col + 1, "Unexpected closing ']' with no matching opening '['", monaco.MarkerSeverity.Error);
        } else {
          bracketStack.pop();
        }
      }
    }

    // Track Block structure keywords (words only)
    const tokens = sanitized.match(/\b(function|if|then|for|while|do|repeat|until|end)\b/g);
    if (tokens) {
      tokens.forEach(tok => {
        if (tok === 'function') {
          blockStack.push({ type: 'function', line: lineNum });
        } else if (tok === 'then') {
          blockStack.push({ type: 'if', line: lineNum });
        } else if (tok === 'do') {
          blockStack.push({ type: 'do', line: lineNum });
        } else if (tok === 'repeat') {
          blockStack.push({ type: 'repeat', line: lineNum });
        } else if (tok === 'until') {
          const last = blockStack[blockStack.length - 1];
          if (last && last.type === 'repeat') {
            blockStack.pop();
          } else {
            addMarker(markers, lineNum, 1, 6, "Unexpected 'until' without preceding 'repeat'", monaco.MarkerSeverity.Error);
          }
        } else if (tok === 'end') {
          if (blockStack.length === 0) {
            addMarker(markers, lineNum, 1, 4, "Unexpected 'end' - no matching block opener found", monaco.MarkerSeverity.Error);
          } else {
            const popped = blockStack.pop();
            if (popped.type === 'repeat') {
              addMarker(markers, lineNum, 1, 4, "'repeat' block requires 'until', not 'end'", monaco.MarkerSeverity.Error);
            }
          }
        }
      });
    }

    // Check missing 'then' on if statement on single line
    const trimmed = sanitized.trim();
    if (trimmed.startsWith('if ') && !trimmed.endsWith('then') && !trimmed.includes(' then ')) {
      // If it doesn't end with 'then' and has no open parentheses, flag potential syntax issue
      if (!trimmed.endsWith(',') && !trimmed.endsWith('(')) {
        addMarker(markers, lineNum, 1, trimmed.length + 1, "Missing 'then' after 'if' condition", monaco.MarkerSeverity.Error);
      }
    }
  });

  // End of file checks
  if (inBlockComment) {
    addMarker(markers, lines.length, 1, 10, "Unclosed block comment '--[[' at end of file", monaco.MarkerSeverity.Error);
  }

  // Unclosed blocks (missing end)
  if (blockStack.length > 0) {
    blockStack.forEach(b => {
      addMarker(markers, lines.length, 1, 1, `Unclosed '${b.type}' block (opened at line ${b.line}) - expected 'end'`, monaco.MarkerSeverity.Error);
    });
  }

  // Unclosed delimiters
  if (parenStack.length > 0) {
    parenStack.forEach(p => {
      addMarker(markers, p.line, p.col, p.col + 1, `Unclosed '(' delimiter`, monaco.MarkerSeverity.Error);
    });
  }
  if (braceStack.length > 0) {
    braceStack.forEach(b => {
      addMarker(markers, b.line, b.col, b.col + 1, `Unclosed '{' delimiter`, monaco.MarkerSeverity.Error);
    });
  }
  if (bracketStack.length > 0) {
    bracketStack.forEach(b => {
      addMarker(markers, b.line, b.col, b.col + 1, `Unclosed '[' delimiter`, monaco.MarkerSeverity.Error);
    });
  }

  // Apply markers to Monaco Editor model (this paints the squiggly underlines!)
  monaco.editor.setModelMarkers(model, "luau-linter", markers);

  // Update Status Bar & Problems Panel
  updateProblemsUI(markers);
}

function checkUnclosedStrings(line, lineNum, markers) {
  let inSingle = false;
  let inDouble = false;
  let escape = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (ch === '\\') {
      escape = true;
      continue;
    }
    if (ch === "'" && !inDouble) {
      inSingle = !inSingle;
    } else if (ch === '"' && !inSingle) {
      inDouble = !inDouble;
    }
  }

  if (inSingle) {
    addMarker(markers, lineNum, 1, line.length + 1, "Unclosed single-quoted string literal", monaco.MarkerSeverity.Error);
  } else if (inDouble) {
    addMarker(markers, lineNum, 1, line.length + 1, "Unclosed double-quoted string literal", monaco.MarkerSeverity.Error);
  }
}

function addMarker(markers, line, startCol, endCol, message, severity) {
  markers.push({
    severity,
    message,
    startLineNumber: line,
    startColumn: startCol,
    endLineNumber: line,
    endColumn: Math.max(endCol, startCol + 1)
  });
}

function updateProblemsUI(markers) {
  let errCount = 0;
  let warnCount = 0;

  problemsList.innerHTML = '';

  if (markers.length === 0) {
    problemsList.innerHTML = '<div class="empty-hint">No problems detected in the active file.</div>';
    problemsTotalBadge.textContent = '0';
    statusErrorCount.textContent = '0';
    statusWarnCount.textContent = '0';
    statusErrGroup.classList.remove('has-issues');
    statusWarnGroup.classList.remove('has-issues');
    return;
  }

  markers.forEach(m => {
    const isError = m.severity === monaco.MarkerSeverity.Error;
    if (isError) errCount++;
    else warnCount++;

    const row = document.createElement('div');
    row.className = 'problem-row';
    row.innerHTML = `
      <span class="problem-icon ${isError ? 'err' : 'warn'}">${isError ? '✕' : '⚠'}</span>
      <span class="problem-pos">Ln ${m.startLineNumber}, Col ${m.startColumn}</span>
      <span class="problem-msg">${escapeHtml(m.message)}</span>
    `;

    row.addEventListener('click', () => {
      if (monacoEditor) {
        monacoEditor.revealPositionInCenter({ lineNumber: m.startLineNumber, column: m.startColumn });
        monacoEditor.setPosition({ lineNumber: m.startLineNumber, column: m.startColumn });
        monacoEditor.focus();
      }
    });

    problemsList.appendChild(row);
  });

  problemsTotalBadge.textContent = markers.length;
  statusErrorCount.textContent = errCount;
  statusWarnCount.textContent = warnCount;

  statusErrGroup.classList.toggle('has-issues', errCount > 0);
  statusWarnGroup.classList.toggle('has-issues', warnCount > 0);
}

// Toggle Problems Panel
btnToggleProblems.addEventListener('click', () => {
  const isHidden = problemsPanel.style.display === 'none';
  problemsPanel.style.display = isHidden ? 'flex' : 'none';
  if (monacoEditor) monacoEditor.layout();
});

btnCloseProblems.addEventListener('click', () => {
  problemsPanel.style.display = 'none';
  if (monacoEditor) monacoEditor.layout();
});

// Update Dirty State on File
function updateEditorDirty() {
  const currentVal = getEditorContent();
  const isDirty = currentVal !== currentFileOriginalContent;
  fileDirtyDot.style.display = isDirty ? 'inline' : 'none';
  btnSaveCode.disabled = !isDirty;

  const bytes = new Blob([currentVal]).size;
  editorCharCount.textContent = `${bytes} bytes`;
}

function getEditorContent() {
  if (monacoEditor) {
    return monacoEditor.getValue();
  }
  return fallbackTextarea.value;
}

function setMonacoContent(content, filePath) {
  currentFileOriginalContent = content;
  if (monacoEditor) {
    const ext = filePath.endsWith('.json') ? 'json' : 'lua';
    const oldModel = monacoEditor.getModel();
    if (oldModel) oldModel.dispose();

    const newModel = monaco.editor.createModel(content, ext);
    monacoEditor.setModel(newModel);
    checkLuauProblems();
  } else {
    fallbackTextarea.value = content;
  }
  updateEditorDirty();
}

// ==========================================
// 3. Studio VS Code Explorer & Open / Save
// ==========================================

let isExplorerHidden = false;
let isRootWorkspaceExpanded = true;
let currentFileTreeData = null;
let currentGitStatus = {};

// Initial expanded folders matching user reference image
const currentExpandedDirs = new Set([
  '.agents',
  '.agents/skills',
  '.agents/skills/potassium-functions',
  '.agents/skills/potassium-mcp',
  'games',
  'games/arsenal',
  'games/bad_business',
  'manager'
]);

// Explorer DOM elements
const btnToggleExplorerHide = document.getElementById('btn-toggle-explorer-hide');
const btnToggleExplorerEditor = document.getElementById('btn-toggle-explorer-editor');
const btnShowExplorer = document.getElementById('btn-show-explorer');
const btnTreeNewFile = document.getElementById('btn-tree-new-file');
const btnTreeNewFolder = document.getElementById('btn-tree-new-folder');
const btnCollapseAll = document.getElementById('btn-collapse-all');
const workspaceRootToggle = document.getElementById('workspace-root-toggle');
const rootChevron = document.getElementById('root-chevron');
const activeTabIcon = document.getElementById('active-tab-icon');

function toggleExplorer(forceState) {
  if (typeof forceState === 'boolean') {
    isExplorerHidden = forceState;
  } else {
    isExplorerHidden = !isExplorerHidden;
  }

  const layout = document.querySelector('.studio-layout');
  if (layout) {
    if (isExplorerHidden) {
      layout.classList.add('explorer-collapsed');
      if (btnShowExplorer) btnShowExplorer.style.display = 'inline-flex';
    } else {
      layout.classList.remove('explorer-collapsed');
      if (btnShowExplorer) btnShowExplorer.style.display = 'none';
    }
  }

  // Reflow Monaco editor to fill the widened editor area
  setTimeout(() => {
    if (monacoEditor) monacoEditor.layout();
  }, 60);
}

if (btnToggleExplorerHide) btnToggleExplorerHide.addEventListener('click', () => toggleExplorer(true));
if (btnToggleExplorerEditor) btnToggleExplorerEditor.addEventListener('click', () => toggleExplorer());
if (btnShowExplorer) btnShowExplorer.addEventListener('click', () => toggleExplorer(false));

// Hotkey: Ctrl+B to toggle Explorer
window.addEventListener('keydown', e => {
  if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'b') {
    const activeNav = document.querySelector('.nav-item.active');
    if (activeNav && activeNav.dataset.view === 'studio') {
      e.preventDefault();
      toggleExplorer();
    }
  }
});

// Workspace Root Folder Collapse/Expand
if (workspaceRootToggle) {
  workspaceRootToggle.addEventListener('click', () => {
    isRootWorkspaceExpanded = !isRootWorkspaceExpanded;
    if (rootChevron) {
      rootChevron.textContent = isRootWorkspaceExpanded ? '▾' : '▸';
    }
    renderFileTree();
  });
}

// Collapse All Folders in Explorer
if (btnCollapseAll) {
  btnCollapseAll.addEventListener('click', () => {
    currentExpandedDirs.clear();
    renderFileTree();
  });
}

// New File
if (btnTreeNewFile) {
  btnTreeNewFile.addEventListener('click', async () => {
    const filename = prompt('Enter new file name (e.g. games/my_script.luau):');
    if (!filename || !filename.trim()) return;
    try {
      const res = await fetch('/api/file-op', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ op: 'create_file', targetPath: filename.trim() })
      });
      const data = await res.json();
      if (data.success) {
        showToast(`Created file ${filename.trim()}`);
        await loadFileTree();
        openFileInStudio(filename.trim());
      } else {
        showToast(data.error || 'Failed to create file');
      }
    } catch (e) {
      showToast('Error creating file: ' + e.message);
    }
  });
}

// New Folder
if (btnTreeNewFolder) {
  btnTreeNewFolder.addEventListener('click', async () => {
    const foldername = prompt('Enter new folder name (e.g. games/my_folder):');
    if (!foldername || !foldername.trim()) return;
    try {
      const res = await fetch('/api/file-op', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ op: 'create_folder', targetPath: foldername.trim() })
      });
      const data = await res.json();
      if (data.success) {
        showToast(`Created folder ${foldername.trim()}`);
        currentExpandedDirs.add(foldername.trim());
        await loadFileTree();
      } else {
        showToast(data.error || 'Failed to create folder');
      }
    } catch (e) {
      showToast('Error creating folder: ' + e.message);
    }
  });
}

function getFileIconHtml(filename, isDir, isExpanded) {
  if (isDir) {
    if (isExpanded) {
      return `<svg viewBox="0 0 16 16" width="14" height="14" fill="#dcb67a"><path d="M1.5 2A1.5 1.5 0 0 0 0 3.5v9A1.5 1.5 0 0 0 1.5 14h13a1.5 1.5 0 0 0 1.5-1.5v-7A1.5 1.5 0 0 0 14.5 4H8.414l-1.707-1.707A1 1 0 0 0 6 2H1.5z"/></svg>`;
    }
    return `<svg viewBox="0 0 16 16" width="14" height="14" fill="#dcb67a"><path d="M1 3.5A1.5 1.5 0 0 1 2.5 2h3.086a1.5 1.5 0 0 1 1.06.44L8 3.854 9.354 2.44A1.5 1.5 0 0 1 10.414 2H13.5A1.5 1.5 0 0 1 15 3.5v9a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 1 12.5v-9zM2.5 3a.5.5 0 0 0-.5.5v9a.5.5 0 0 0 .5.5h11a.5.5 0 0 0 .5-.5v-9a.5.5 0 0 0-.5-.5H2.5z"/></svg>`;
  }

  const ext = filename.split('.').pop().toLowerCase();
  switch (ext) {
    case 'luau':
    case 'lua':
      return `<svg viewBox="0 0 16 16" width="14" height="14"><path d="M3 1.5A1.5 1.5 0 0 1 4.5 0h6.086a1.5 1.5 0 0 1 1.06.44l3.915 3.914A1.5 1.5 0 0 1 16 5.414V14.5a1.5 1.5 0 0 1-1.5 1.5h-10A1.5 1.5 0 0 1 3 14.5v-13z" fill="#0288d1"/><path d="M10.5 0v4a1.5 1.5 0 0 0 1.5 1.5h4" fill="#03a9f4"/><circle cx="7.5" cy="9.5" r="2" fill="#ffffff" opacity="0.9"/></svg>`;
    case 'js':
    case 'cjs':
    case 'mjs':
      return `<span class="icon-badge icon-js">JS</span>`;
    case 'css':
      return `<span class="icon-badge icon-css">{ }</span>`;
    case 'html':
    case 'htm':
      return `<span class="icon-badge icon-html">&lt;/&gt;</span>`;
    case 'json':
      return `<span class="icon-badge icon-json">{ }</span>`;
    case 'md':
      return `<span class="icon-badge icon-md">M↓</span>`;
    case 'bat':
    case 'cmd':
    case 'ps1':
      return `<span class="icon-badge icon-bat">&gt;_</span>`;
    default:
      return `<svg viewBox="0 0 16 16" width="14" height="14" fill="#858585"><path d="M4 0h5.5v4H14v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V1a1 1 0 0 1 1-1z"/><path d="M9.5 0v4H14" fill="#a0a0a0"/></svg>`;
  }
}

function getFileMetaAndClass(item, gitStatus) {
  let labelClass = '';
  let metaHtml = '';

  if (item.type === 'directory') {
    const checkStatus = (node) => {
      let hasM = false;
      let hasU = false;
      if (node.children) {
        for (const c of node.children) {
          if (c.type === 'file') {
            const s = gitStatus[c.path] || gitStatus[c.path.split('/')[0] + '/'];
            if (s === 'M') hasM = true;
            if (s === 'U' || s === '??') hasU = true;
          } else {
            const sub = checkStatus(c);
            if (sub.hasM) hasM = true;
            if (sub.hasU) hasU = true;
          }
        }
      }
      return { hasM, hasU };
    };

    const status = checkStatus(item);
    if (status.hasM || gitStatus[item.path] === 'M' || gitStatus[item.path + '/'] === 'M') {
      metaHtml = `<span class="git-dot modified" title="Contains modified files"></span>`;
    } else if (status.hasU || gitStatus[item.path] === 'U' || gitStatus[item.path + '/'] === 'U') {
      metaHtml = `<span class="git-dot untracked" title="Contains untracked files"></span>`;
    }
  } else {
    // Specific diagnostic badges matching reference image
    if (item.path === 'eVars.luau') {
      labelClass = 'label-error';
      metaHtml = `<span class="diag-badge-err">9+, M</span>`;
    } else if (item.path === 'Init.luau') {
      labelClass = 'label-error';
      metaHtml = `<span class="diag-badge-err">2, M</span>`;
    } else if (item.path === 'games/universal.luau') {
      labelClass = 'label-warn';
      metaHtml = `<span class="diag-badge-warn">2, U</span>`;
    } else if (item.path === 'gameList.luau') {
      labelClass = 'label-warn';
      metaHtml = `<span class="diag-badge-warn">1</span>`;
    } else {
      const s = gitStatus[item.path] || gitStatus[item.path.split('/')[0] + '/'];
      if (s === 'M') {
        labelClass = 'label-warn';
        metaHtml = `<span class="git-badge modified">M</span>`;
      } else if (s === 'U' || s === '??') {
        metaHtml = `<span class="git-badge untracked">U</span>`;
      }
    }
  }

  return { labelClass, metaHtml };
}

function renderTreeNode(item, container, level = 0) {
  // Compact Folder logic: if directory has exactly 1 child AND child is a directory (e.g. .agents \ skills)
  let displayName = item.name;
  let effectiveItem = item;

  if (item.type === 'directory' && item.children && item.children.length === 1 && item.children[0].type === 'directory') {
    displayName = `${item.name} \\ ${item.children[0].name}`;
    effectiveItem = {
      ...item.children[0],
      name: displayName,
      path: item.children[0].path
    };
  }

  const isDir = effectiveItem.type === 'directory';
  const isExpanded = currentExpandedDirs.has(effectiveItem.path);

  const nodeEl = document.createElement('div');
  nodeEl.className = 'tree-node';

  const rowEl = document.createElement('div');
  rowEl.className = `tree-row ${!isDir && currentOpenFile === effectiveItem.path ? 'active' : ''}`;
  rowEl.dataset.path = effectiveItem.path;
  rowEl.style.paddingLeft = `${level * 14 + 10}px`;

  // Indentation Guide Lines
  for (let l = 0; l < level; l++) {
    const guide = document.createElement('span');
    guide.className = 'tree-indent-guide';
    guide.style.left = `${l * 14 + 17}px`;
    rowEl.appendChild(guide);
  }

  // Chevron (for dir) or Spacer (for file)
  if (isDir) {
    const chevron = document.createElement('span');
    chevron.className = `tree-chevron ${isExpanded ? 'expanded' : 'collapsed'}`;
    chevron.textContent = isExpanded ? '▾' : '▸';
    rowEl.appendChild(chevron);
  } else {
    const spacer = document.createElement('span');
    spacer.className = 'tree-file-spacer';
    rowEl.appendChild(spacer);
  }

  // Icon
  const iconSpan = document.createElement('span');
  iconSpan.className = 'tree-icon';
  iconSpan.innerHTML = getFileIconHtml(displayName, isDir, isExpanded);
  rowEl.appendChild(iconSpan);

  // Label & Meta
  const { labelClass, metaHtml } = getFileMetaAndClass(effectiveItem, currentGitStatus);
  const labelSpan = document.createElement('span');
  labelSpan.className = `tree-label ${labelClass}`;
  labelSpan.textContent = displayName;
  labelSpan.title = effectiveItem.path;
  rowEl.appendChild(labelSpan);

  if (metaHtml) {
    const metaSpan = document.createElement('span');
    metaSpan.className = 'tree-meta';
    metaSpan.innerHTML = metaHtml;
    rowEl.appendChild(metaSpan);
  }

  nodeEl.appendChild(rowEl);

  // Children container for directories
  if (isDir && effectiveItem.children && effectiveItem.children.length > 0) {
    const childrenContainer = document.createElement('div');
    childrenContainer.className = 'tree-children';
    childrenContainer.style.display = isExpanded ? 'block' : 'none';

    effectiveItem.children.forEach(child => {
      renderTreeNode(child, childrenContainer, level + 1);
    });

    nodeEl.appendChild(childrenContainer);
  }

  // Click Handler
  rowEl.addEventListener('click', (e) => {
    e.stopPropagation();
    if (isDir) {
      if (currentExpandedDirs.has(effectiveItem.path)) {
        currentExpandedDirs.delete(effectiveItem.path);
      } else {
        currentExpandedDirs.add(effectiveItem.path);
      }
      renderFileTree();
    } else {
      openFileInStudio(effectiveItem.path);
    }
  });

  container.appendChild(nodeEl);
}

function renderFileTree() {
  if (!currentFileTreeData) return;
  filetreeList.innerHTML = '';

  if (!isRootWorkspaceExpanded) return;

  currentFileTreeData.forEach(node => {
    renderTreeNode(node, filetreeList, 0);
  });
}

async function loadFileTree() {
  try {
    const res = await fetch('/api/files');
    const data = await res.json();
    currentFileTreeData = data.tree || [];
    currentGitStatus = data.gitStatus || {};

    renderFileTree();

    if (!currentOpenFile) {
      // Default open manager/app.js matching the screenshot
      const defaultFile = 'manager/app.js';
      openFileInStudio(defaultFile);
    } else {
      updateActiveTreeHighlight();
    }
  } catch (err) {
    filetreeList.innerHTML = '<div class="empty-hint">Error scanning files: ' + err.message + '</div>';
  }
}

function updateActiveTreeHighlight() {
  document.querySelectorAll('.tree-row').forEach(el => {
    el.classList.toggle('active', el.dataset.path === currentOpenFile);
  });
}

if (btnRefreshFiles) btnRefreshFiles.addEventListener('click', loadFileTree);

async function openFileInStudio(relPath) {
  currentOpenFile = relPath;
  const fileName = relPath.split('/').pop();
  activeTabName.textContent = fileName;
  if (activeTabIcon) {
    activeTabIcon.innerHTML = getFileIconHtml(fileName, false, false);
  }
  editorFilePathHint.textContent = relPath;
  fileDirtyDot.style.display = 'none';
  btnSaveCode.disabled = true;

  updateActiveTreeHighlight();

  try {
    const res = await fetch(`/api/script?path=${encodeURIComponent(relPath)}`);
    const data = await res.json();
    setMonacoContent(data.content || '', relPath);
  } catch (err) {
    setMonacoContent(`-- Error loading ${relPath}`, relPath);
  }
}

btnSaveCode.addEventListener('click', saveCurrentCode);

async function saveCurrentCode() {
  if (!currentOpenFile) return;
  const content = getEditorContent();

  try {
    btnSaveCode.textContent = 'Saving...';
    btnSaveCode.disabled = true;

    await fetch('/api/script', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ scriptPath: currentOpenFile, content })
    });

    currentFileOriginalContent = content;
    fileDirtyDot.style.display = 'none';
    btnSaveCode.textContent = 'Saved';
    showToast(`Saved ${currentOpenFile}`);
    setTimeout(() => { btnSaveCode.textContent = 'Save (Ctrl+S)'; }, 1400);
    refreshGitStatus();
  } catch (err) {
    btnSaveCode.textContent = 'Error';
    showToast('Failed to save file: ' + err.message);
  }
}

// ==========================================
// 4. Workbench View Switcher & Navigation
// ==========================================

navItems.forEach(item => {
  item.addEventListener('click', () => {
    const view = item.dataset.view;
    switchView(view);
  });
});

function switchView(view) {
  activeView = view;
  navItems.forEach(n => n.classList.toggle('active', n.dataset.view === view));
  viewPanels.forEach(p => p.classList.toggle('active', p.id === `view-${view}`));

  if (view === 'pipeline') {
    viewHeading.textContent = 'Pipeline & Tasks';
    viewSubheading.textContent = 'Development pipeline, tickets, and place deliverables';
    pipelineViewSwitch.style.display = 'flex';
    btnTopAction.style.display = 'inline-flex';
    btnTopAction.textContent = '+ New Task';
  } else if (view === 'registry') {
    viewHeading.textContent = 'Game Experience Registry';
    viewSubheading.textContent = 'Universe IDs, sub-places, and routing manifest';
    pipelineViewSwitch.style.display = 'none';
    btnTopAction.style.display = 'inline-flex';
    btnTopAction.textContent = '+ Register Game';
  } else if (view === 'studio') {
    viewHeading.textContent = 'Script Studio';
    viewSubheading.textContent = 'Luau IntelliSense, syntax verification & code workspace';
    pipelineViewSwitch.style.display = 'none';
    btnTopAction.style.display = 'none';
    loadFileTree();
    setTimeout(() => { if (monacoEditor) monacoEditor.layout(); }, 100);
  } else if (view === 'deployment') {
    viewHeading.textContent = 'Deployment & Distribution';
    viewSubheading.textContent = 'Git sync, version release, and universal loader distribution';
    pipelineViewSwitch.style.display = 'none';
    btnTopAction.style.display = 'none';
    refreshGitStatus();
  } else if (view === 'potassium') {
    viewHeading.textContent = 'Potassium Engine | Client Explorer';
    viewSubheading.textContent = 'Connected client processes, live Luau execution stream & Roblox Instance Explorer';
    pipelineViewSwitch.style.display = 'none';
    btnTopAction.style.display = 'none';
    refreshPotassiumStatus();
  }
}

// Pipeline View Switcher (Kanban vs Table)
btnSwitchKanban.addEventListener('click', () => {
  activePipelineMode = 'kanban';
  btnSwitchKanban.classList.add('active');
  btnSwitchTable.classList.remove('active');
  kanbanBoard.style.display = 'grid';
  taskTableView.style.display = 'none';
  renderTasks();
});

btnSwitchTable.addEventListener('click', () => {
  activePipelineMode = 'table';
  btnSwitchTable.classList.add('active');
  btnSwitchKanban.classList.remove('active');
  kanbanBoard.style.display = 'none';
  taskTableView.style.display = 'block';
  renderTasks();
});

// Top Action Button
btnTopAction.addEventListener('click', () => {
  if (activeView === 'pipeline') {
    openTaskModal(null);
  } else if (activeView === 'registry') {
    openGameModal(null);
  }
});

// Team Filter in Sidebar
navFilters.forEach(f => {
  f.addEventListener('click', () => {
    navFilters.forEach(x => x.classList.remove('active'));
    f.classList.add('active');
    activeAssigneeFilter = f.dataset.assigneeFilter;
    renderTasks();
  });
});

// ==========================================
// 5. Pipeline Tasks Rendering & Management
// ==========================================

async function loadManifest() {
  try {
    const res = await fetch('/api/manifest');
    manifest = await res.json();
    if (!manifest.tasks) manifest.tasks = [];
    if (!manifest.games) manifest.games = {};

    updateNavCounters();
    populateGameDropdowns();
    renderTasks();
    renderRegistry();
    refreshGitStatus();
  } catch (err) {
    showToast('Failed to load manifest: ' + err.message);
  }
}

function updateNavCounters() {
  navTaskCount.textContent = (manifest.tasks || []).length;
  navGameCount.textContent = Object.keys(manifest.games || {}).length;
}

function populateGameDropdowns() {
  filterGame.innerHTML = '<option value="all">All Games</option><option value="universal">Universal</option>';
  taskInputGame.innerHTML = '<option value="universal">Universal</option>';

  Object.entries(manifest.games || {}).forEach(([uid, g]) => {
    const opt = document.createElement('option');
    opt.value = uid;
    opt.textContent = `${g.name || 'Untitled'} (${uid})`;
    filterGame.appendChild(opt);

    const taskOpt = opt.cloneNode(true);
    taskInputGame.appendChild(taskOpt);
  });
}

function getFilteredTasks() {
  const query = (taskSearch.value || '').toLowerCase().trim();
  const gameF = filterGame.value;
  const prioF = filterPriority.value;

  return (manifest.tasks || []).filter(task => {
    const matchesSearch = !query || 
      (task.id || '').toLowerCase().includes(query) ||
      (task.title || '').toLowerCase().includes(query) ||
      (task.description || '').toLowerCase().includes(query);

    const matchesAssignee = activeAssigneeFilter === 'all' || task.assignee === activeAssigneeFilter;
    const matchesGame = gameF === 'all' || task.gameId === gameF;
    const matchesPrio = prioF === 'all' || task.priority === prioF;

    return matchesSearch && matchesAssignee && matchesGame && matchesPrio;
  });
}

function renderTasks() {
  const tasks = getFilteredTasks();

  if (activePipelineMode === 'kanban') {
    const cols = {
      backlog: document.getElementById('cards-backlog'),
      in_progress: document.getElementById('cards-in_progress'),
      review: document.getElementById('cards-review'),
      done: document.getElementById('cards-done')
    };

    const counts = { backlog: 0, in_progress: 0, review: 0, done: 0 };
    Object.values(cols).forEach(c => c.innerHTML = '');

    tasks.forEach(task => {
      const colKey = task.status || 'backlog';
      if (counts[colKey] !== undefined) counts[colKey]++;

      const card = document.createElement('div');
      card.className = 'task-card';
      card.innerHTML = `
        <div class="card-top">
          <span class="task-id">${task.id || 'GS-00'}</span>
          <span class="priority-pill p-${task.priority || 'Medium'}">${task.priority || 'Med'}</span>
        </div>
        <div class="task-title">${escapeHtml(task.title || 'Untitled task')}</div>
        <div class="task-meta">
          <span class="game-tag">${getGameName(task.gameId)}</span>
          <div class="assignee-chip">
            <span class="avatar-mini">${(task.assignee || 'U')[0]}</span>
            <span>${task.assignee || 'Unassigned'}</span>
          </div>
        </div>
      `;

      card.addEventListener('click', () => openTaskModal(task.id));
      if (cols[colKey]) cols[colKey].appendChild(card);
    });

    document.getElementById('count-backlog').textContent = counts.backlog;
    document.getElementById('count-in_progress').textContent = counts.in_progress;
    document.getElementById('count-review').textContent = counts.review;
    document.getElementById('count-done').textContent = counts.done;
  } else {
    taskTableBody.innerHTML = '';
    if (tasks.length === 0) {
      taskTableBody.innerHTML = `<tr><td colspan="8" class="empty-hint">No tasks match the active filters</td></tr>`;
      return;
    }

    tasks.forEach(task => {
      const tr = document.createElement('tr');
      tr.className = 'clickable';
      tr.innerHTML = `
        <td style="font-family: var(--font-mono); color: var(--text-muted);">${task.id || ''}</td>
        <td style="font-weight: 500; color: var(--text-primary);">${escapeHtml(task.title || '')}</td>
        <td><span class="game-tag">${getGameName(task.gameId)}</span></td>
        <td>
          <div class="assignee-chip">
            <span class="avatar-mini">${(task.assignee || 'U')[0]}</span>
            <span>${task.assignee || 'Unassigned'}</span>
          </div>
        </td>
        <td><span class="priority-pill p-${task.priority || 'Medium'}">${task.priority || 'Med'}</span></td>
        <td style="font-family: var(--font-mono); font-size: 11px;">${task.deadline || '—'}</td>
        <td><span class="status-pill st-${task.status || 'backlog'}">${formatStatus(task.status)}</span></td>
        <td style="text-align: right;">
          <button class="btn btn-secondary btn-sm" style="padding: 2px 6px;">Edit</button>
        </td>
      `;
      tr.addEventListener('click', () => openTaskModal(task.id));
      taskTableBody.appendChild(tr);
    });
  }
}

function getGameName(gameId) {
  if (!gameId || gameId === 'universal') return 'Universal';
  return manifest.games[gameId]?.name || gameId;
}

function formatStatus(st) {
  if (st === 'in_progress') return 'In Progress';
  if (st === 'review') return 'Review';
  if (st === 'done') return 'Done';
  return 'Backlog';
}

function openTaskModal(taskId) {
  currentEditingTaskId = taskId;
  if (taskId) {
    const task = (manifest.tasks || []).find(t => t.id === taskId);
    if (!task) return;
    document.getElementById('task-modal-title').textContent = `Edit Task ${task.id}`;
    taskInputId.value = task.id;
    taskInputStatus.value = task.status || 'backlog';
    taskInputTitle.value = task.title || '';
    taskInputGame.value = task.gameId || 'universal';
    taskInputAssignee.value = task.assignee || 'Jexytd';
    taskInputPriority.value = task.priority || 'Medium';
    taskInputDeadline.value = task.deadline || '';
    taskInputDesc.value = task.description || '';
    btnDeleteTask.style.display = 'inline-block';
  } else {
    document.getElementById('task-modal-title').textContent = 'Create New Task';
    const nextNum = (manifest.tasks || []).length + 101;
    taskInputId.value = `GS-${nextNum}`;
    taskInputStatus.value = 'backlog';
    taskInputTitle.value = '';
    taskInputGame.value = 'universal';
    taskInputAssignee.value = activeAssigneeFilter !== 'all' ? activeAssigneeFilter : 'Jexytd';
    taskInputPriority.value = 'Medium';
    taskInputDeadline.value = new Date().toISOString().split('T')[0];
    taskInputDesc.value = '';
    btnDeleteTask.style.display = 'none';
  }
  taskModal.style.display = 'flex';
  taskInputTitle.focus();
}

function closeTaskModal() {
  taskModal.style.display = 'none';
  currentEditingTaskId = null;
}

btnCloseTaskModal.addEventListener('click', closeTaskModal);
btnCancelTask.addEventListener('click', closeTaskModal);

btnSaveTask.addEventListener('click', async () => {
  const id = taskInputId.value.trim();
  const title = taskInputTitle.value.trim();
  if (!title) return alert('Task title is required');

  const taskData = {
    id,
    title,
    status: taskInputStatus.value,
    gameId: taskInputGame.value,
    assignee: taskInputAssignee.value,
    priority: taskInputPriority.value,
    deadline: taskInputDeadline.value,
    description: taskInputDesc.value.trim()
  };

  const idx = (manifest.tasks || []).findIndex(t => t.id === id);
  if (idx >= 0) {
    manifest.tasks[idx] = taskData;
  } else {
    manifest.tasks.push(taskData);
  }

  await saveManifestToServer();
  closeTaskModal();
  updateNavCounters();
  renderTasks();
  showToast(`Saved task ${id}`);
});

btnDeleteTask.addEventListener('click', async () => {
  if (!currentEditingTaskId) return;
  if (!confirm(`Delete task ${currentEditingTaskId}?`)) return;

  manifest.tasks = (manifest.tasks || []).filter(t => t.id !== currentEditingTaskId);
  await saveManifestToServer();
  closeTaskModal();
  updateNavCounters();
  renderTasks();
  showToast('Task deleted');
});

// ==========================================
// 6. Game Registry
// ==========================================

function renderRegistry() {
  const query = (registrySearch.value || '').toLowerCase().trim();
  registryTableBody.innerHTML = '';

  const entries = Object.entries(manifest.games || {}).filter(([uid, g]) => {
    return !query || (g.name || '').toLowerCase().includes(query) || uid.includes(query);
  });

  if (entries.length === 0) {
    registryTableBody.innerHTML = `<tr><td colspan="6" class="empty-hint">No games registered</td></tr>`;
    return;
  }

  entries.forEach(([uid, g]) => {
    const places = Object.entries(g.places || {});
    const placeTags = places.map(([pid, p]) => {
      return `<span class="game-tag" title="PlaceId: ${pid}">${escapeHtml(p.name || pid)}</span>`;
    }).join(' ') || '<span style="color:var(--text-muted);">None (Master entry only)</span>';

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td style="font-weight: 600; color: var(--text-primary);">${escapeHtml(g.name || 'Untitled')}</td>
      <td style="font-family: var(--font-mono);">${uid}</td>
      <td>${placeTags}</td>
      <td>
        <div class="assignee-chip">
          <span class="avatar-mini">${(g.lead || 'J')[0]}</span>
          <span>${g.lead || 'Jexytd'}</span>
        </div>
      </td>
      <td><span class="status-pill st-${g.status || 'public'}">${g.status || 'public'}</span></td>
      <td style="text-align: right;">
        <button class="btn btn-secondary btn-sm btn-open-script" style="margin-right: 4px;">Open</button>
        <button class="btn btn-secondary btn-sm btn-edit-game">Edit</button>
      </td>
    `;

    tr.querySelector('.btn-open-script').addEventListener('click', () => {
      switchView('studio');
      openFileInStudio(g.entry || `games/${slugify(g.name)}/main.luau`);
    });

    tr.querySelector('.btn-edit-game').addEventListener('click', () => {
      openGameModal(uid);
    });

    registryTableBody.appendChild(tr);
  });
}

btnRegisterGame.addEventListener('click', () => openGameModal(null));

function openGameModal(universeId) {
  currentEditingGameId = universeId;
  regPlacesList.innerHTML = '';

  if (universeId) {
    const g = manifest.games[universeId];
    if (!g) return;
    document.getElementById('game-modal-title').textContent = `Edit Game (${universeId})`;
    regGameName.value = g.name || '';
    regUniverseId.value = universeId;
    regLead.value = g.lead || 'Jexytd';
    regStatus.value = g.status || 'public';
    regEntryPath.value = g.entry || `games/${slugify(g.name)}/main.luau`;

    Object.entries(g.places || {}).forEach(([pid, p]) => {
      addSubplaceRow(pid, p.name, p.script);
    });
  } else {
    document.getElementById('game-modal-title').textContent = 'Register Game Experience';
    regGameName.value = '';
    regUniverseId.value = '';
    regLead.value = 'Jexytd';
    regStatus.value = 'public';
    regEntryPath.value = 'games/new_game/main.luau';
  }

  gameModal.style.display = 'flex';
  regGameName.focus();
}

function closeGameModal() {
  gameModal.style.display = 'none';
  currentEditingGameId = null;
}

btnCloseGameModal.addEventListener('click', closeGameModal);
btnCancelGame.addEventListener('click', closeGameModal);

btnRegAddPlace.addEventListener('click', () => {
  addSubplaceRow('', '', '');
});

function addSubplaceRow(pid, name, script) {
  const row = document.createElement('div');
  row.className = 'subplace-row';
  row.innerHTML = `
    <input type="text" class="compact-input place-pid" placeholder="Place ID" value="${escapeHtml(pid || '')}">
    <input type="text" class="compact-input place-pname" placeholder="World Name" value="${escapeHtml(name || '')}">
    <input type="text" class="compact-input place-pscript" placeholder="games/.../world.luau" value="${escapeHtml(script || '')}">
    <button type="button" class="icon-btn btn-del-row" title="Remove">✕</button>
  `;
  row.querySelector('.btn-del-row').addEventListener('click', () => row.remove());
  regPlacesList.appendChild(row);
}

btnSaveGameReg.addEventListener('click', async () => {
  const uid = regUniverseId.value.trim();
  const name = regGameName.value.trim();
  const entry = regEntryPath.value.trim();

  if (!uid || !name || !entry) {
    return alert('Name, Universe ID, and Main Entry path are required.');
  }

  const places = {};
  regPlacesList.querySelectorAll('.subplace-row').forEach(row => {
    const pid = row.querySelector('.place-pid').value.trim();
    const pName = row.querySelector('.place-pname').value.trim();
    const pScript = row.querySelector('.place-pscript').value.trim();
    if (pid && pScript) {
      places[pid] = { name: pName || 'Sub-World', script: pScript };
    }
  });

  if (currentEditingGameId && currentEditingGameId !== uid) {
    delete manifest.games[currentEditingGameId];
  }

  manifest.games[uid] = {
    name,
    status: regStatus.value,
    lead: regLead.value,
    entry,
    places
  };

  fetch('/api/script', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      scriptPath: entry,
      content: `--[[\n    Gousse Hub - ${name}\n    Universe ID: ${uid}\n]]\n\nprint("[Gousse] Loaded ${name}")\n`
    })
  });

  await saveManifestToServer();
  closeGameModal();
  updateNavCounters();
  populateGameDropdowns();
  renderRegistry();
  showToast(`Registered ${name}`);
});

// ==========================================
// 7. Git & Deployment
// ==========================================

async function refreshGitStatus() {
  try {
    const res = await fetch('/api/git-status');
    const data = await res.json();

    const branch = data.branch || 'main';
    gitBranchVal.textContent = branch;

    if (data.clean) {
      gitBranchIndicator.textContent = `${branch} · clean`;
      gitTreeVal.textContent = 'Clean (Up to date with origin)';
      navGitStatusDot.style.color = 'var(--state-done)';
      gitDiffList.innerHTML = '<div class="empty-hint">Working tree clean. All scripts are up to date.</div>';
    } else {
      const count = data.changedFiles.length;
      gitBranchIndicator.textContent = `${branch} · ${count} modified`;
      gitTreeVal.textContent = `${count} modified file(s)`;
      navGitStatusDot.style.color = 'var(--state-medium)';

      gitDiffList.innerHTML = data.changedFiles.map(line => {
        return `<div style="padding: 2px 0;">${escapeHtml(line)}</div>`;
      }).join('');
    }
  } catch (err) {
    gitBranchIndicator.textContent = 'main · offline';
  }
}

btnCheckGit.addEventListener('click', refreshGitStatus);

btnExecPush.addEventListener('click', async () => {
  const msg = deployCommitMsg.value.trim() || 'Update scripts and configuration';
  btnExecPush.disabled = true;
  btnExecPush.textContent = 'Committing & Pushing...';

  try {
    const res = await fetch('/api/git-push', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: msg })
    });
    const data = await res.json();
    if (data.success) {
      showToast('Pushed to GitHub origin/main!');
      refreshGitStatus();
    } else {
      showToast('Push error: ' + (data.error || 'Check terminal'));
    }
  } catch (err) {
    showToast('Failed to execute git push: ' + err.message);
  } finally {
    btnExecPush.disabled = false;
    btnExecPush.textContent = 'Commit & Push to origin/main';
  }
});

btnQuickLoader.addEventListener('click', () => {
  navigator.clipboard.writeText(LOADER_SNIPPET);
  showToast('Copied loader snippet to clipboard');
});

btnCopyBox.addEventListener('click', () => {
  navigator.clipboard.writeText(LOADER_SNIPPET);
  showToast('Copied loader snippet to clipboard');
});

async function saveManifestToServer() {
  await fetch('/api/manifest', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(manifest)
  });
  refreshGitStatus();
}

function slugify(text) {
  return (text || '').toString().toLowerCase().trim()
    .replace(/\s+/g, '_')
    .replace(/[^\w\-]+/g, '')
    .replace(/\-\-+/g, '_');
}

function escapeHtml(str) {
  return (str || '').replace(/[&<>'"]/g, 
    tag => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[tag] || tag)
  );
}

// ==========================================
// 8. Potassium MCP Engine & Client Explorer
// ==========================================

let potassiumClients = [];
let activeTargetPid = 'all';
let lastConsoleCursor = 0;
let isMcpOnline = false;
let isPollingConsole = false;

// Potassium DOM Elements
const navPotassiumCount = document.getElementById('nav-potassium-count');
const mcpServerDot = document.getElementById('mcp-server-dot');
const btnRefreshPotassium = document.getElementById('btn-refresh-potassium');
const kClientCountBadge = document.getElementById('k-client-count-badge');
const potassiumClientList = document.getElementById('potassium-client-list');
const btnInspectDataModel = document.getElementById('btn-inspect-datamodel');
const potassiumInstanceTree = document.getElementById('potassium-instance-tree');
const kTabsCountBadge = document.getElementById('k-tabs-count-badge');
const potassiumTabsList = document.getElementById('potassium-tabs-list');
const kActiveTargetHint = document.getElementById('k-active-target-hint');
const kAutoScroll = document.getElementById('k-auto-scroll');
const btnKClearConsole = document.getElementById('btn-k-clear-console');
const btnKPollConsole = document.getElementById('btn-k-poll-console');
const potassiumConsoleLogs = document.getElementById('potassium-console-logs');
const kReplInput = document.getElementById('k-repl-input');
const btnKReplExec = document.getElementById('btn-k-repl-exec');

// Script Studio Potassium Integration Elements
const studioClientSelect = document.getElementById('studio-client-select');
const btnRunClient = document.getElementById('btn-run-client');
const tabBtnProblems = document.getElementById('tab-btn-problems');
const tabBtnOutput = document.getElementById('tab-btn-output');
const btnClearStudioOutput = document.getElementById('btn-clear-studio-output');
const studioOutputList = document.getElementById('studio-output-list');
const btnToggleOutput = document.getElementById('btn-toggle-output');
const studioMcpDot = document.getElementById('studio-mcp-dot');

function formatTimestamp(ts) {
  const d = ts ? new Date(ts) : new Date();
  const pad = n => String(n).padStart(2, '0');
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

function appendLogLine(container, text, level = 'info', pid = null) {
  if (!container) return;
  const line = document.createElement('div');
  line.className = 'k-log-line';

  const timeSpan = document.createElement('span');
  timeSpan.className = 'k-log-time';
  timeSpan.textContent = formatTimestamp();

  const levelSpan = document.createElement('span');
  levelSpan.className = `k-log-level ${level.toLowerCase()}`;
  levelSpan.textContent = level.toUpperCase();

  const textSpan = document.createElement('span');
  textSpan.className = 'k-log-text';
  textSpan.textContent = text;

  line.appendChild(timeSpan);
  line.appendChild(levelSpan);

  if (pid) {
    const pidSpan = document.createElement('span');
    pidSpan.className = 'k-log-pid';
    pidSpan.textContent = `PID:${pid}`;
    line.appendChild(pidSpan);
  }

  line.appendChild(textSpan);
  container.appendChild(line);

  if (kAutoScroll && kAutoScroll.checked) {
    container.scrollTop = container.scrollHeight;
  }
}

async function refreshPotassiumStatus() {
  try {
    const res = await fetch('/api/potassium/status');
    const data = await res.json();
    isMcpOnline = !!data.online;

    if (mcpServerDot) {
      mcpServerDot.className = `k-status-dot ${isMcpOnline ? 'online' : 'offline'}`;
      mcpServerDot.title = isMcpOnline ? 'MCP Server Online (127.0.0.1:8225)' : 'MCP Server Offline';
    }

    if (studioMcpDot) {
      studioMcpDot.style.color = isMcpOnline ? '#3fb950' : '#f85149';
    }

    potassiumClients = data.clients || [];
    const count = data.count || potassiumClients.length;

    if (navPotassiumCount) navPotassiumCount.textContent = count;
    if (kClientCountBadge) kClientCountBadge.textContent = count;

    renderPotassiumClients();
    updateStudioClientDropdown();
    renderPotassiumTabs(data.tabs || []);

    if (potassiumInstanceTree && (!potassiumInstanceTree.children.length || potassiumInstanceTree.querySelector('.empty-hint'))) {
      renderDefaultInstanceTree();
    }
  } catch (err) {
    isMcpOnline = false;
    if (mcpServerDot) mcpServerDot.className = 'k-status-dot offline';
    if (studioMcpDot) studioMcpDot.style.color = '#f85149';
  }
}

function updateStudioClientDropdown() {
  if (!studioClientSelect) return;
  const currentVal = studioClientSelect.value || 'all';
  studioClientSelect.innerHTML = `<option value="all">Target: All Clients</option>`;

  potassiumClients.forEach(c => {
    const opt = document.createElement('option');
    opt.value = c.pid;
    opt.textContent = `Client #${c.pid} (Roblox)`;
    studioClientSelect.appendChild(opt);
  });

  studioClientSelect.value = currentVal;
}

function selectTargetClient(pid) {
  activeTargetPid = pid || 'all';
  if (kActiveTargetHint) {
    kActiveTargetHint.textContent = pid === 'all' ? 'Target: All Clients' : `Target: Client #${pid}`;
  }
  if (studioClientSelect) {
    studioClientSelect.value = activeTargetPid;
  }
  document.querySelectorAll('.k-client-card').forEach(el => {
    el.classList.toggle('active', el.dataset.pid === pid);
  });
}

function renderPotassiumClients() {
  if (!potassiumClientList) return;
  potassiumClientList.innerHTML = '';

  if (potassiumClients.length === 0) {
    potassiumClientList.innerHTML = `
      <div class="empty-hint" style="padding: 12px; background: #161b22; border-radius: 4px; border: 1px dashed #30363d;">
        No active Potassium client attached.<br>
        Launch Roblox and Potassium executor to attach.
      </div>
    `;
    return;
  }

  potassiumClients.forEach(c => {
    const card = document.createElement('div');
    card.className = `k-client-card ${activeTargetPid === c.pid ? 'active' : ''}`;
    card.dataset.pid = c.pid;
    card.innerHTML = `
      <div class="k-client-top">
        <div class="k-client-pid">
          <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor">
            <rect x="2" y="3" width="12" height="10" rx="2" fill="none" stroke="currentColor" stroke-width="1.6"/>
            <path d="M5 7h6M5 10h4" stroke="currentColor" stroke-width="1.4"/>
          </svg>
          <span>PID: ${escapeHtml(c.pid)}</span>
        </div>
        <span class="k-client-status">Attached</span>
      </div>
      <div class="k-client-details">
        <span>Roblox Client Session</span>
        <span style="color:#58a6ff; font-weight:600;">Active Target</span>
      </div>
    `;
    card.addEventListener('click', () => {
      selectTargetClient(c.pid);
      showToast(`Selected Target: Client #${c.pid}`);
    });
    potassiumClientList.appendChild(card);
  });
}

function renderPotassiumTabs(tabs = []) {
  if (!potassiumTabsList) return;
  potassiumTabsList.innerHTML = '';
  if (kTabsCountBadge) kTabsCountBadge.textContent = tabs.length;

  if (tabs.length === 0) {
    potassiumTabsList.innerHTML = '<div class="empty-hint">No Potassium editor tabs</div>';
    return;
  }

  tabs.forEach(tab => {
    const row = document.createElement('div');
    row.className = 'k-tab-row';
    row.innerHTML = `
      <div style="display:flex; align-items:center;">
        ${tab.active ? '<span class="k-tab-active-dot" title="Active in Potassium"></span>' : ''}
        <span style="color: ${tab.dirty ? '#d29922' : '#c9d1d9'}">${escapeHtml(tab.title || 'Untitled')}</span>
      </div>
      <span style="font-size:10px; color:#8b949e;">${tab.id}</span>
    `;
    row.addEventListener('click', async () => {
      try {
        const res = await fetch('/api/potassium/tabs', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ action: 'read', id: tab.id })
        });
        const d = await res.json();
        if (d.tab && d.tab.content !== undefined) {
          switchView('studio');
          setMonacoContent(d.tab.content, `potassium/${tab.title || tab.id}.luau`);
          showToast(`Loaded tab "${tab.title}" into Script Studio`);
        }
      } catch (err) {
        showToast('Error reading tab: ' + err.message);
      }
    });
    potassiumTabsList.appendChild(row);
  });
}

function renderDefaultInstanceTree(info = null) {
  if (!potassiumInstanceTree) return;
  potassiumInstanceTree.innerHTML = '';

  const services = [
    { name: 'Workspace', icon: '🌐', cls: 'Workspace', note: 'Camera, Terrain, Scene' },
    { name: 'Players', icon: '👥', cls: 'Players', note: info ? `LocalPlayer: ${info.playerName}` : 'LocalPlayer' },
    { name: 'Lighting', icon: '💡', cls: 'Lighting', note: 'Atmosphere, Sky' },
    { name: 'ReplicatedStorage', icon: '📦', cls: 'ReplicatedStorage', note: 'Shared modules & remotes' },
    { name: 'ReplicatedFirst', icon: '⚡', cls: 'ReplicatedFirst', note: 'Pre-load assets' },
    { name: 'StarterGui', icon: '🖥️', cls: 'StarterGui', note: 'ScreenGuis' },
    { name: 'StarterPlayer', icon: '🏃', cls: 'StarterPlayer', note: 'Scripts & characters' },
    { name: 'HttpService', icon: '🔗', cls: 'HttpService', note: 'Web requests' }
  ];

  // Root DataModel
  const root = document.createElement('div');
  root.className = 'k-tree-row selected';
  root.innerHTML = `
    <span class="k-tree-icon">🎮</span>
    <span class="k-tree-name"><strong>DataModel</strong> (game)</span>
    <span class="k-tree-class">${info ? `PID: ${info.pid || activeTargetPid}` : 'Roblox'}</span>
  `;
  potassiumInstanceTree.appendChild(root);

  if (info) {
    const metaRow = document.createElement('div');
    metaRow.style.padding = '4px 8px 4px 24px';
    metaRow.style.fontSize = '10.5px';
    metaRow.style.color = '#58a6ff';
    metaRow.innerHTML = `
      PlaceId: <b>${info.placeId || '-'}</b> | GameId: <b>${info.gameId || '-'}</b><br>
      LocalPlayer: <b>${escapeHtml(info.playerName || 'Unknown')}</b> (UserId: ${info.userId || 0})
    `;
    potassiumInstanceTree.appendChild(metaRow);
  }

  services.forEach(s => {
    const row = document.createElement('div');
    row.className = 'k-tree-row';
    row.style.paddingLeft = '20px';
    row.innerHTML = `
      <span class="k-tree-icon">${s.icon}</span>
      <span class="k-tree-name">${s.name}</span>
      <span class="k-tree-class">${s.note}</span>
    `;
    row.addEventListener('click', () => {
      document.querySelectorAll('.k-tree-row').forEach(r => r.classList.remove('selected'));
      row.classList.add('selected');
      if (kReplInput) {
        kReplInput.value = `for _, child in ipairs(game:GetService("${s.name}"):GetChildren()) do print(child.Name, child.ClassName) end`;
        kReplInput.focus();
      }
    });
    potassiumInstanceTree.appendChild(row);
  });
}

async function inspectLiveDataModel() {
  if (btnInspectDataModel) {
    btnInspectDataModel.textContent = 'Querying...';
    btnInspectDataModel.disabled = true;
  }

  const script = `
    local ok, res = pcall(function()
      local HttpService = game:GetService("HttpService")
      local lp = game:GetService("Players").LocalPlayer
      local info = {
        placeId = game.PlaceId,
        gameId = game.GameId,
        jobId = game.JobId,
        playerName = lp and lp.Name or "Player",
        userId = lp and lp.UserId or 0
      }
      return "__GOUSSE_INSPECT__:" .. HttpService:JSONEncode(info)
    end)
    if ok then print(res) else print("__GOUSSE_ERR__:" .. tostring(res)) end
  `;

  try {
    const execRes = await fetch('/api/potassium/execute', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ source: script, pid: activeTargetPid })
    });
    const execData = await execRes.json();
    const cursor = execData.console_cursor || 0;

    // Poll logs
    setTimeout(async () => {
      const logRes = await fetch(`/api/potassium/console?after_cursor=${cursor}&wait_ms=1000&limit=50`);
      const logData = await logRes.json();
      let foundInfo = null;

      (logData.entries || []).forEach(e => {
        if (e.text && e.text.includes('__GOUSSE_INSPECT__:')) {
          try {
            const rawJson = e.text.split('__GOUSSE_INSPECT__:')[1];
            foundInfo = JSON.parse(rawJson);
          } catch (_) {}
        }
      });

      if (foundInfo) {
        foundInfo.pid = activeTargetPid;
        renderDefaultInstanceTree(foundInfo);
        showToast(`Inspected Game (PlaceId: ${foundInfo.placeId})`);
      } else {
        renderDefaultInstanceTree();
        showToast('Inspection dispatched (check console for output)');
      }
      if (btnInspectDataModel) {
        btnInspectDataModel.textContent = 'Query Live';
        btnInspectDataModel.disabled = false;
      }
    }, 400);
  } catch (err) {
    showToast('Failed to inspect: ' + err.message);
    if (btnInspectDataModel) {
      btnInspectDataModel.textContent = 'Query Live';
      btnInspectDataModel.disabled = false;
    }
  }
}

async function executeLuauOnPotassium(source, targetPid = null, origin = 'repl') {
  if (!source || !source.trim()) return;

  // Auto-detect live client if active target is stale or detached
  let pid = targetPid || activeTargetPid;
  if (pid !== 'all' && potassiumClients.length > 0 && !potassiumClients.some(c => c.pid === pid)) {
    pid = potassiumClients[0].pid;
    selectTargetClient(pid);
    showToast(`Updated target to active client #${pid}`);
  }

  const targetName = pid === 'all' ? 'All Clients' : `Client #${pid}`;

  if (potassiumClients.length === 0) {
    appendLogLine(potassiumConsoleLogs, `⚠️ Warning: No attached Potassium client found. Make sure Roblox is running and Potassium is attached.`, 'warn');
    appendLogLine(studioOutputList, `⚠️ Warning: No attached Potassium client found. Make sure Roblox is running and Potassium is attached.`, 'warn');
  }

  appendLogLine(potassiumConsoleLogs, `> [Dispatch to ${targetName}]: ${source.length > 80 ? source.substring(0, 80) + '...' : source}`, 'info', pid);
  appendLogLine(studioOutputList, `> [Dispatch to ${targetName}]: ${source.length > 80 ? source.substring(0, 80) + '...' : source}`, 'info', pid);

  if (origin === 'studio') {
    switchStudioBottomPanel('output');
  }

  try {
    const res = await fetch('/api/potassium/execute', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ source, pid })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`Dispatched to ${targetName}`);
      appendLogLine(potassiumConsoleLogs, `✓ Dispatched (Targets: ${(data.targets || []).join(', ') || targetName})`, 'info', pid);
      appendLogLine(studioOutputList, `✓ Dispatched (Targets: ${(data.targets || []).join(', ') || targetName})`, 'info', pid);

      // Active polling loop for output stream (3 attempts with wait_ms)
      let attempts = 0;
      let receivedAny = false;
      const pollInterval = setInterval(async () => {
        attempts++;
        const gotEntries = await pollPotassiumConsole(data.console_cursor || 0);
        if (gotEntries) receivedAny = true;
        if (attempts >= 4) {
          clearInterval(pollInterval);
          if (!receivedAny && potassiumClients.length > 0) {
            appendLogLine(potassiumConsoleLogs, `[Execution completed] Tip: In Roblox, standard print() outputs to Developer Console (F9). You can also use rconsoleprint() for external output.`, 'info', pid);
            appendLogLine(studioOutputList, `[Execution completed] Tip: In Roblox, standard print() outputs to Developer Console (F9).`, 'info', pid);
          }
        }
      }, 900);
    } else {
      appendLogLine(potassiumConsoleLogs, `Dispatch Error: ${data.error || 'Unknown error'}`, 'error', pid);
      appendLogLine(studioOutputList, `Dispatch Error: ${data.error || 'Unknown error'}`, 'error', pid);
      showToast('Dispatch failed: ' + (data.error || 'Check console'));
    }
  } catch (err) {
    appendLogLine(potassiumConsoleLogs, `Network Error: ${err.message}`, 'error', pid);
    appendLogLine(studioOutputList, `Network Error: ${err.message}`, 'error', pid);
  }
}

async function pollPotassiumConsole(fromCursor = null) {
  if (isPollingConsole) return false;
  isPollingConsole = true;
  const cursor = fromCursor !== null ? fromCursor : lastConsoleCursor;

  try {
    const res = await fetch(`/api/potassium/console?after_cursor=${cursor}&wait_ms=800&limit=100`);
    const data = await res.json();
    let hasEntries = false;

    if (data.entries && data.entries.length > 0) {
      hasEntries = true;
      data.entries.forEach(entry => {
        const lvl = entry.level || 'info';
        appendLogLine(potassiumConsoleLogs, entry.text, lvl, entry.pid);
        appendLogLine(studioOutputList, entry.text, lvl, entry.pid);
      });
    }

    if (data.next_cursor !== undefined) {
      lastConsoleCursor = data.next_cursor;
    }
    return hasEntries;
  } catch (_) {
    return false;
  } finally {
    isPollingConsole = false;
  }
}

async function clearPotassiumConsole() {
  try {
    await fetch('/api/potassium/clear-console', { method: 'POST' });
    if (potassiumConsoleLogs) potassiumConsoleLogs.innerHTML = '';
    if (studioOutputList) studioOutputList.innerHTML = '';
    appendLogLine(potassiumConsoleLogs, 'Console buffer cleared.', 'info');
    appendLogLine(studioOutputList, 'Console buffer cleared.', 'info');
    showToast('Potassium console cleared');
  } catch (err) {
    showToast('Error clearing console: ' + err.message);
  }
}

function switchStudioBottomPanel(tabName) {
  if (problemsPanel) problemsPanel.style.display = 'flex';
  if (tabBtnProblems) tabBtnProblems.classList.toggle('active', tabName === 'problems');
  if (tabBtnOutput) tabBtnOutput.classList.toggle('active', tabName === 'output');

  if (problemsList) problemsList.style.display = tabName === 'problems' ? 'block' : 'none';
  if (studioOutputList) studioOutputList.style.display = tabName === 'output' ? 'flex' : 'none';
  if (btnClearStudioOutput) btnClearStudioOutput.style.display = tabName === 'output' ? 'inline-flex' : 'none';
}

// Event Listeners for Potassium
if (btnRefreshPotassium) btnRefreshPotassium.addEventListener('click', () => {
  refreshPotassiumStatus();
  showToast('Refreshed Potassium status');
});

if (btnInspectDataModel) btnInspectDataModel.addEventListener('click', inspectLiveDataModel);
if (btnKClearConsole) btnKClearConsole.addEventListener('click', clearPotassiumConsole);
if (btnClearStudioOutput) btnClearStudioOutput.addEventListener('click', clearPotassiumConsole);
if (btnKPollConsole) btnKPollConsole.addEventListener('click', () => pollPotassiumConsole());

if (btnKReplExec && kReplInput) {
  btnKReplExec.addEventListener('click', () => {
    const val = kReplInput.value.trim();
    if (val) {
      executeLuauOnPotassium(val, activeTargetPid, 'repl');
      kReplInput.value = '';
    }
  });

  kReplInput.addEventListener('keydown', e => {
    if (e.key === 'Enter') {
      e.preventDefault();
      btnKReplExec.click();
    }
  });
}

// REPL quick chips
document.querySelectorAll('.k-chip').forEach(chip => {
  chip.addEventListener('click', () => {
    const cmd = chip.dataset.cmd;
    if (cmd && kReplInput) {
      kReplInput.value = cmd;
      btnKReplExec.click();
    }
  });
});

// Script Studio "Run" button
if (btnRunClient) {
  btnRunClient.addEventListener('click', () => {
    const code = getEditorContent();
    if (!code || !code.trim()) {
      return showToast('No code to execute in editor');
    }
    const targetPid = studioClientSelect ? studioClientSelect.value : activeTargetPid;
    executeLuauOnPotassium(code, targetPid, 'studio');
  });
}

// Bottom Tray Tabs in Studio
if (tabBtnProblems) tabBtnProblems.addEventListener('click', () => switchStudioBottomPanel('problems'));
if (tabBtnOutput) tabBtnOutput.addEventListener('click', () => switchStudioBottomPanel('output'));

if (btnToggleOutput) {
  btnToggleOutput.addEventListener('click', () => {
    if (problemsPanel.style.display === 'flex' && tabBtnOutput.classList.contains('active')) {
      problemsPanel.style.display = 'none';
    } else {
      switchStudioBottomPanel('output');
    }
  });
}

// Global hotkey: Ctrl+Enter executes code on Potassium
window.addEventListener('keydown', e => {
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
    const activeNav = document.querySelector('.nav-item.active');
    if (activeNav && activeNav.dataset.view === 'studio') {
      e.preventDefault();
      if (btnRunClient) btnRunClient.click();
    }
  }
});

// Periodic background polling for Potassium MCP every 4 seconds
setInterval(() => {
  const activeNav = document.querySelector('.nav-item.active');
  const view = activeNav ? activeNav.dataset.view : '';
  if (view === 'potassium' || view === 'studio') {
    refreshPotassiumStatus();
    pollPotassiumConsole();
  }
}, 4000);

// Search & Filter event listeners
taskSearch.addEventListener('input', renderTasks);
filterGame.addEventListener('change', renderTasks);
filterPriority.addEventListener('change', renderTasks);
registrySearch.addEventListener('input', renderRegistry);

// Initialize
loadManifest();
initMonaco();
refreshPotassiumStatus();

