// ========================================================================
// Gousse Studio - Roblox Language Server Protocol (LSP) Engine for Monaco
// Full Roblox API Surface, Class Inheritance, Enums, Hovers, and Signatures
// ========================================================================

const RobloxLSP = (function () {
  let apiData = { classes: {}, enums: {}, services: [] };
  let isLoaded = false;

  // Potassium Executor APIs (from eVars.luau & potassium-functions)
  const potassiumApis = {
    hookfunction: {
      sig: 'hookfunction(target: function, hook: function): function',
      doc: 'Hooks a Lua or C function and replaces its implementation. Returns a copy of the original function.'
    },
    hookmetamethod: {
      sig: 'hookmetamethod(target: Instance | table | userdata, method: string, hook: function): function',
      doc: 'Hooks a metamethod (e.g. __namecall, __index, __newindex) on an object. Returns the original metamethod.'
    },
    getnamecallmethod: {
      sig: 'getnamecallmethod(): string',
      doc: 'Returns the method name of the active __namecall invocation (e.g. "FireServer", "InvokeServer").'
    },
    setnamecallmethod: {
      sig: 'setnamecallmethod(method: string): ()',
      doc: 'Sets the method string returned during __namecall metamethod execution.'
    },
    getrawmetatable: {
      sig: 'getrawmetatable(target: Instance | table | userdata): table?',
      doc: 'Retrieves the metatable of target, bypassing __metatable protection locks.'
    },
    setrawmetatable: {
      sig: 'setrawmetatable(target: Instance | table | userdata, mt: table): ()',
      doc: 'Directly replaces the metatable of target even if locked.'
    },
    cloneref: {
      sig: 'cloneref(instance: Instance): Instance',
      doc: 'Returns a cloned instance reference that bypasses equality checks with game scripts.'
    },
    compareinstances: {
      sig: 'compareinstances(a: Instance, b: Instance): boolean',
      doc: 'Checks whether two distinct references point to the exact same native engine Instance.'
    },
    fireclickdetector: {
      sig: 'fireclickdetector(detector: ClickDetector, distance?: number, signal?: string): ()',
      doc: 'Fires ClickDetector signals ("MouseClick", "RightMouseClick", "MouseHoverEnter", "MouseHoverLeave").'
    },
    fireproximityprompt: {
      sig: 'fireproximityprompt(prompt: ProximityPrompt): ()',
      doc: 'Triggers a ProximityPrompt instantly without waiting for hold duration.'
    },
    firetouchinterest: {
      sig: 'firetouchinterest(part: BasePart, toTouch: BasePart, touchType: number): ()',
      doc: 'Simulates physics touch events. touchType: 0 = Touched, 1 = TouchEnded.'
    },
    firesignal: {
      sig: 'firesignal(signal: RBXScriptSignal, ...: any?): ()',
      doc: 'Fires all client-side connected callbacks on an RBXScriptSignal.'
    },
    cansignalreplicate: {
      sig: 'cansignalreplicate(signal: RBXScriptSignal): boolean',
      doc: 'Checks if an RBXScriptSignal is allowed by Roblox to replicate to the server.'
    },
    getconnections: {
      sig: 'getconnections(signal: RBXScriptSignal): { [number]: RBXScriptConnection }',
      doc: 'Returns an array of Connection objects listening to the specified signal.'
    },
    replicatesignal: {
      sig: 'replicatesignal(signal: RBXScriptSignal, ...: any?): ()',
      doc: 'Forces an RBXScriptSignal to replicate its invocation to the game server.'
    },
    gethui: {
      sig: 'gethui(): Folder | ScreenGui',
      doc: 'Returns a hidden CoreGui container that is completely invisible to game scripts.'
    },
    getinstances: {
      sig: 'getinstances(): { [number]: Instance }',
      doc: 'Returns a table containing all Instances currently loaded in memory.'
    },
    getnilinstances: {
      sig: 'getnilinstances(): { [number]: Instance }',
      doc: 'Returns an array of Instances whose Parent is nil.'
    },
    readfile: {
      sig: 'readfile(path: string): string',
      doc: 'Reads the entire contents of a workspace file.'
    },
    writefile: {
      sig: 'writefile(path: string, content: string): ()',
      doc: 'Writes content to a file in the workspace directory.'
    },
    appendfile: {
      sig: 'appendfile(path: string, content: string): ()',
      doc: 'Appends content to an existing file.'
    },
    isfile: {
      sig: 'isfile(path: string): boolean',
      doc: 'Checks if the specified path points to an existing file.'
    },
    listfiles: {
      sig: 'listfiles(path: string): { [number]: string }',
      doc: 'Returns an array of file paths inside the specified directory.'
    },
    loadfile: {
      sig: 'loadfile(path: string): (function?, string?)',
      doc: 'Loads and compiles a file into a Luau executable chunk without running it.'
    },
    identifyexecutor: {
      sig: 'identifyexecutor(): (name: string, version: string)',
      doc: 'Returns the executor name ("Potassium") and its build version.'
    },
    request: {
      sig: 'request(options: { Url: string, Method?: string, Headers?: table, Body?: string }): table',
      doc: 'Full-featured HTTP client supporting custom headers, verbs, and payloads.'
    },
    WebSocket: {
      sig: 'WebSocket.connect(url: string): WebSocket',
      doc: 'Opens a full-duplex WebSocket connection to the specified URL.'
    },
    getcustomasset: {
      sig: 'getcustomasset(path: string): string',
      doc: 'Generates a temporary content ID ("rbxasset://...") referencing a local file asset.'
    },
    getloadedmodules: {
      sig: 'getloadedmodules(): { [number]: ModuleScript }',
      doc: 'Returns an array of all ModuleScript instances currently cached in the Luau VM memory.'
    },
    getsignalarguments: {
      sig: 'getsignalarguments(signal: RBXScriptSignal): { [number]: any }',
      doc: 'Retrieves argument values and types associated with the given RBXScriptSignal.'
    },
    getsignalargumentsinfo: {
      sig: 'getsignalargumentsinfo(signal: RBXScriptSignal): table',
      doc: 'Returns comprehensive metadata and signature reflection info for an RBXScriptSignal.'
    },
    get_comm_channel: {
      sig: 'get_comm_channel(id: number): BindableEvent',
      doc: 'Retrieves an actor communication BindableEvent created via create_comm_channel by numeric ID.'
    },
    create_comm_channel: {
      sig: 'create_comm_channel(): (number, BindableEvent)',
      doc: 'Creates a cross-actor communication channel returning its channel ID and BindableEvent.'
    },
    getactors: {
      sig: 'getactors(): { [number]: Actor }',
      doc: 'Returns an array of all active Actor instances.'
    },
    getactorthreads: {
      sig: 'getactorthreads(): { [number]: thread }',
      doc: 'Returns an array of all execution threads associated with active actors.'
    },
    getrendersteppedlist: {
      sig: 'getrendersteppedlist(): { [number]: function }',
      doc: 'Returns all callbacks connected to the RenderStepped engine pipeline.'
    },
    getfpscap: {
      sig: 'getfpscap(): number',
      doc: 'Returns the current target framerate cap.'
    },
    setfpscap: {
      sig: 'setfpscap(cap: number): ()',
      doc: 'Sets client framerate cap limit.'
    },
    gethwid: {
      sig: 'gethwid(): string',
      doc: 'Returns unique client hardware identification string.'
    },
    getrunningscripts: {
      sig: 'getrunningscripts(): { [number]: LocalScript | ModuleScript }',
      doc: 'Returns an array of all currently executing LocalScripts and ModuleScripts.'
    },
    getscriptbytecode: {
      sig: 'getscriptbytecode(script: LuaSourceContainer): string',
      doc: 'Retrieves the compiled bytecode string for the target script.'
    },
    getscripthash: {
      sig: 'getscripthash(script: LuaSourceContainer): string',
      doc: 'Calculates the SHA hash of a script bytecode chunk.'
    },
    getscripts: {
      sig: 'getscripts(): { [number]: LocalScript | ModuleScript }',
      doc: 'Returns all script instances loaded in game memory.'
    },
    getthreadidentity: {
      sig: 'getthreadidentity(): number',
      doc: 'Returns current Luau security context thread identity.'
    },
    setthreadidentity: {
      sig: 'setthreadidentity(identity: number): ()',
      doc: 'Sets current Luau security context thread identity (0-8).'
    },
    gethiddenproperty: {
      sig: 'gethiddenproperty(instance: Instance, property: string): (any, boolean)',
      doc: 'Reads a hidden internal engine property bypassing script security.'
    },
    sethiddenproperty: {
      sig: 'sethiddenproperty(instance: Instance, property: string, value: any): boolean',
      doc: 'Modifies a hidden internal engine property.'
    }
  };

  // Common built-in methods and properties for all Roblox Instances
  const instanceCommonMethods = [
    { name: 'FindFirstChild', params: 'name: string, recursive?: boolean', ret: 'Instance?' },
    { name: 'WaitForChild', params: 'name: string, timeOut?: number', ret: 'Instance' },
    { name: 'GetChildren', params: '', ret: '{ [number]: Instance }' },
    { name: 'GetDescendants', params: '', ret: '{ [number]: Instance }' },
    { name: 'FindFirstChildOfClass', params: 'className: string', ret: 'Instance?' },
    { name: 'FindFirstAncestor', params: 'name: string', ret: 'Instance?' },
    { name: 'FindFirstAncestorOfClass', params: 'className: string', ret: 'Instance?' },
    { name: 'IsA', params: 'className: string', ret: 'boolean' },
    { name: 'Destroy', params: '', ret: '()' },
    { name: 'Clone', params: '', ret: 'Instance' },
    { name: 'GetPropertyChangedSignal', params: 'property: string', ret: 'RBXScriptSignal' },
    { name: 'SetAttribute', params: 'attribute: string, value: any', ret: '()' },
    { name: 'GetAttribute', params: 'attribute: string', ret: 'any' },
    { name: 'GetAttributes', params: '', ret: '{ [string]: any }' }
  ];

  const instanceCommonProps = [
    { name: 'Name', type: 'string' },
    { name: 'Parent', type: 'Instance?' },
    { name: 'ClassName', type: 'string' },
    { name: 'Archivable', type: 'boolean' }
  ];

  let monacoRef = null;

  // Initialize and fetch Roblox API dump from local server
  async function init() {
    try {
      const res = await fetch('/roblox-api-data.json');
      if (res.ok) {
        apiData = await res.json();
        isLoaded = true;
        console.log('[Roblox LSP] Loaded', Object.keys(apiData.classes).length, 'classes &', Object.keys(apiData.enums).length, 'enums.');
        if (monacoRef) {
          setupLuaLSSyntax(monacoRef, Object.keys(apiData.classes));
        }
      }
    } catch (e) {
      console.warn('[Roblox LSP] Offline mode active using built-in definitions');
    }
  }

  // Setup LuaLS / VS Code Highlighting (Monarch Tokens Provider)
  function setupLuaLSSyntax(monaco, additionalClasses = []) {
    if (!monaco || !monaco.languages) return;

    try {
      monaco.languages.register({ id: 'luau', extensions: ['.luau', '.lua'] });
    } catch (e) {}

    const commonRobloxClasses = [
      'BasePart', 'Part', 'MeshPart', 'WedgePart', 'Terrain', 'Model',
      'Folder', 'Camera', 'Workspace', 'DataModel', 'Players', 'Player',
      'Lighting', 'ReplicatedStorage', 'ServerStorage', 'ServerScriptService',
      'HttpService', 'RunService', 'TweenService', 'UserInputService',
      'ContextActionService', 'SoundService', 'GuiService', 'StarterGui',
      'StarterPack', 'StarterPlayer', 'CoreGui', 'TeleportService',
      'MarketplaceService', 'Debris', 'Instance', 'BrickColor', 'Color3',
      'Vector3', 'Vector2', 'CFrame', 'UDim', 'UDim2', 'Ray', 'RaycastParams',
      'RaycastResult', 'Region3', 'TweenInfo', 'NumberRange', 'NumberSequence',
      'ColorSequence', 'Font', 'Faces', 'Axes', 'Rect', 'PathfindingService',
      'ProximityPrompt', 'ClickDetector', 'Humanoid', 'Animation', 'AnimationTrack',
      'Animator', 'Sound', 'SurfaceAppearance', 'Attachment', 'Beam', 'Trail',
      'ParticleEmitter', 'Highlight', 'PointLight', 'SpotLight', 'SurfaceLight',
      'ScreenGui', 'BillboardGui', 'SurfaceGui', 'Frame', 'TextLabel',
      'TextButton', 'TextBox', 'ImageLabel', 'ImageButton', 'ScrollingFrame',
      'UIListLayout', 'UIGridLayout', 'UIPadding', 'UICorner', 'UIStroke',
      'UIGradient', 'UIScale', 'UIAspectRatioConstraint', 'RemoteEvent',
      'RemoteFunction', 'BindableEvent', 'BindableFunction', 'ModuleScript',
      'LocalScript', 'Script', 'RBXScriptSignal', 'RBXScriptConnection'
    ];

    const typesList = Array.from(new Set([
      ...commonRobloxClasses,
      ...additionalClasses,
      'number', 'string', 'boolean', 'table', 'thread', 'buffer', 'any', 'void', 'nil', 'unknown', 'never'
    ]));

    const monarchDef = {
      defaultToken: '',
      tokenPostfix: '.lua',

      keywordsControl: [
        'and', 'break', 'do', 'else', 'elseif', 'end', 'for',
        'function', 'if', 'in', 'not', 'or', 'repeat', 'return',
        'then', 'until', 'while', 'continue'
      ],

      keywordsStorage: [
        'local'
      ],

      builtinGlobals: [
        'game', 'workspace', 'script', 'Enum', 'shared', '_G', 'task',
        'true', 'false', 'nil'
      ],

      builtinFunctions: [
        'assert', 'collectgarbage', 'error', 'getmetatable', 'setmetatable',
        'ipairs', 'pairs', 'next', 'pcall', 'print', 'rawequal', 'rawget',
        'rawset', 'rawlen', 'select', 'tonumber', 'tostring', 'type', 'typeof',
        'unpack', 'warn', 'require', 'ypcall', 'loadstring',
        // Potassium APIs
        'hookfunction', 'hookmetamethod', 'getnamecallmethod', 'setnamecallmethod',
        'getrawmetatable', 'setrawmetatable', 'cloneref', 'compareinstances',
        'fireclickdetector', 'fireproximityprompt', 'firetouchinterest', 'firesignal',
        'cansignalreplicate', 'getconnections', 'replicatesignal', 'gethui',
        'getinstances', 'getnilinstances', 'readfile', 'writefile', 'appendfile',
        'isfile', 'listfiles', 'loadfile', 'identifyexecutor', 'request',
        'getcustomasset', 'getloadedmodules', 'getsignalarguments', 'getsignalargumentsinfo',
        'get_comm_channel', 'create_comm_channel', 'getactors', 'getactorthreads',
        'getrendersteppedlist', 'getfpscap', 'setfpscap', 'gethwid', 'getrunningscripts',
        'getscriptbytecode', 'getscripthash', 'getscripts', 'getthreadidentity',
        'setthreadidentity', 'gethiddenproperty', 'sethiddenproperty'
      ],

      types: typesList,

      brackets: [
        { token: 'delimiter.bracket', open: '{', close: '}' },
        { token: 'delimiter.array', open: '[', close: ']' },
        { token: 'delimiter.parenthesis', open: '(', close: ')' }
      ],

      tokenizer: {
        root: [
          // Whitespace & comments
          { include: '@whitespace' },

          // Strings
          [/\[([=]*)\[/, 'string', '@string_multiline.$1'],
          [/"([^"\\]|\\.)*"/, 'string'],
          [/'([^'\\]|\\.)*'/, 'string'],

          // Numbers
          [/0[xX][0-9a-fA-F]+/, 'number.hex'],
          [/\d+(\.\d+)?([eE][\-+]?\d+)?/, 'number'],

          // Colon transitions (Method calls or Type annotations)
          [/::/, 'delimiter'],
          [/:(?=\s*[a-zA-Z_])/, 'delimiter', '@afterColon'],

          // Dot transitions (Property access or Function calls)
          [/\.(?=\s*[a-zA-Z_])/, 'delimiter', '@afterDot'],

          // Function call by name: pairs(, print(, hookfunction(
          [/([a-zA-Z_]\w*)(\s*)(?=\()/, {
            cases: {
              '@keywordsControl': 'keyword.control',
              '@keywordsStorage': 'keyword.storage',
              '@builtinGlobals': 'variable.language',
              '@builtinFunctions': 'entity.name.function',
              '@types': 'entity.name.type',
              '@default': 'entity.name.function'
            }
          }],

          // Words / Identifiers
          [/[a-zA-Z_]\w*/, {
            cases: {
              '@keywordsControl': 'keyword.control',
              '@keywordsStorage': 'keyword.storage',
              '@builtinGlobals': 'variable.language',
              '@builtinFunctions': 'entity.name.function',
              '@types': 'entity.name.type',
              '@default': 'variable.name'
            }
          }],

          // Delimiters & brackets
          [/[{}()\[\]]/, '@brackets'],
          [/[;,.]/, 'delimiter'],
          [/[+\-*/%^#~=><&|]/, 'operator']
        ],

        afterColon: [
          // If identifier is a known Type (e.g. BasePart, number, string, Player)
          [/[a-zA-Z_]\w*/, {
            cases: {
              '@types': { token: 'entity.name.type', next: '@pop' },
              '@default': { token: 'entity.name.function.method', next: '@pop' }
            }
          }],
          { include: '@whitespace' },
          ['', '', '@pop']
        ],

        afterDot: [
          // If followed by (, it's a function call (e.g. BrickColor.random() or Vector3.new()
          [/([a-zA-Z_]\w*)(\s*)(?=\()/, { token: 'entity.name.function', next: '@pop' }],
          // Property / Member access
          [/[a-zA-Z_]\w*/, { token: 'variable.other.property', next: '@pop' }],
          { include: '@whitespace' },
          ['', '', '@pop']
        ],

        whitespace: [
          [/[ \t\r\n]+/, 'white'],
          [/--\[([=]*)\[/, 'comment', '@comment.$1'],
          [/--.*$/, 'comment']
        ],

        comment: [
          [/[^\]]+/, 'comment'],
          [/\]([=]*)\]/, {
            cases: {
              '$1==$S2': { token: 'comment', next: '@pop' },
              '@default': 'comment'
            }
          }],
          [/./, 'comment']
        ],

        string_multiline: [
          [/[^\]]+/, 'string'],
          [/\]([=]*)\]/, {
            cases: {
              '$1==$S2': { token: 'string', next: '@pop' },
              '@default': 'string'
            }
          }],
          [/./, 'string']
        ]
      }
    };

    const langConf = {
      comments: {
        lineComment: '--',
        blockComment: ['--[[', ']]']
      },
      brackets: [
        ['{', '}'],
        ['[', ']'],
        ['(', ')']
      ],
      autoClosingPairs: [
        { open: '{', close: '}' },
        { open: '[', close: ']' },
        { open: '(', close: ')' },
        { open: '"', close: '"' },
        { open: "'", close: "'" }
      ],
      surroundingPairs: [
        { open: '{', close: '}' },
        { open: '[', close: ']' },
        { open: '(', close: ')' },
        { open: '"', close: '"' },
        { open: "'", close: "'" }
      ]
    };

    ['lua', 'luau'].forEach(langId => {
      monaco.languages.setMonarchTokensProvider(langId, monarchDef);
      monaco.languages.setLanguageConfiguration(langId, langConf);
    });
  }

  // Resolve all inherited members for a class (e.g. Part inherits BasePart -> PVInstance -> Instance)
  function getAllMembers(className) {
    const methods = {};
    const props = {};
    const events = {};

    let current = className;
    const visited = new Set();

    while (current && !visited.has(current)) {
      visited.add(current);
      const classInfo = apiData.classes[current];
      if (!classInfo) break;

      if (classInfo.methods) {
        for (const [mName, mData] of Object.entries(classInfo.methods)) {
          if (!methods[mName]) methods[mName] = mData;
        }
      }
      if (classInfo.props) {
        for (const [pName, pData] of Object.entries(classInfo.props)) {
          if (!props[pName]) props[pName] = pData;
        }
      }
      if (classInfo.events) {
        for (const [eName, eData] of Object.entries(classInfo.events)) {
          if (!events[eName]) events[eName] = eData;
        }
      }

      current = classInfo.super;
    }

    return { methods, props, events };
  }

  // Register Monaco Providers
  function registerWithMonaco(monaco) {
    monacoRef = monaco;
    setupLuaLSSyntax(monaco, isLoaded ? Object.keys(apiData.classes) : []);

    if (monaco.languages && monaco.languages.onLanguage) {
      monaco.languages.onLanguage('lua', () => {
        setupLuaLSSyntax(monaco, isLoaded ? Object.keys(apiData.classes) : []);
      });
      monaco.languages.onLanguage('luau', () => {
        setupLuaLSSyntax(monaco, isLoaded ? Object.keys(apiData.classes) : []);
      });
    }
    const completionProvider = {
      triggerCharacters: ['.', ':', '"', "'", '('],
      provideCompletionItems: function (model, position) {
        const lineContent = model.getLineContent(position.lineNumber);
        const textUntilPosition = lineContent.substring(0, position.column - 1);
        const wordInfo = model.getWordUntilPosition(position);
        const defaultRange = new monaco.Range(
          position.lineNumber,
          wordInfo.startColumn,
          position.lineNumber,
          wordInfo.endColumn
        );
        const suggestions = [];

        function addSuggestion(item) {
          if (!item.range) item.range = defaultRange;
          suggestions.push(item);
        }

        // Context 1: game:GetService("...")
        if (textUntilPosition.match(/game\s*:\s*GetService\s*\(\s*["']([^"']*)$/)) {
          const serviceList = (apiData.services && apiData.services.length > 0)
            ? apiData.services
            : ['Players', 'HttpService', 'RunService', 'ReplicatedStorage', 'UserInputService', 'TweenService', 'StarterGui', 'TeleportService', 'Lighting', 'SoundService', 'MarketplaceService'];

          serviceList.forEach(s => {
            addSuggestion({
              label: s,
              kind: monaco.languages.CompletionItemKind.Class,
              insertText: s,
              detail: `Roblox Service: ${s}`,
              documentation: `Retrieves the ${s} singleton service.`
            });
          });
          return { suggestions };
        }

        // Context 2: Instance.new("...")
        if (textUntilPosition.match(/Instance\s*\.\s*new\s*\(\s*["']([^"']*)$/)) {
          const classNames = Object.keys(apiData.classes || {});
          const list = classNames.length > 0 ? classNames : ['Part', 'Model', 'Frame', 'TextLabel', 'RemoteEvent', 'RemoteFunction', 'Folder', 'Highlight', 'ProximityPrompt', 'Sound'];

          list.forEach(c => {
            addSuggestion({
              label: c,
              kind: monaco.languages.CompletionItemKind.Class,
              insertText: c,
              detail: `Create Instance: ${c}`
            });
          });
          return { suggestions };
        }

        // Context 3: Enum.<EnumName> or Enum.<EnumName>.<Item>
        const enumMatch = textUntilPosition.match(/Enum\s*\.\s*([a-zA-Z0-9_]*)$/);
        const enumItemMatch = textUntilPosition.match(/Enum\s*\.\s*([a-zA-Z0-9_]+)\s*\.\s*([a-zA-Z0-9_]*)$/);

        if (enumItemMatch) {
          const enumName = enumItemMatch[1];
          const items = (apiData.enums && apiData.enums[enumName]) || [];
          items.forEach(item => {
            addSuggestion({
              label: item,
              kind: monaco.languages.CompletionItemKind.EnumMember,
              insertText: item,
              detail: `Enum.${enumName}.${item}`
            });
          });
          return { suggestions };
        }

        if (enumMatch) {
          const enumNames = Object.keys(apiData.enums || {});
          const list = enumNames.length > 0 ? enumNames : ['KeyCode', 'EasingStyle', 'EasingDirection', 'UserInputType', 'Font', 'Material', 'CameraType'];
          list.forEach(e => {
            addSuggestion({
              label: e,
              kind: monaco.languages.CompletionItemKind.Enum,
              insertText: e,
              detail: `Enum.${e}`
            });
          });
          return { suggestions };
        }

        // Context 4: Method calls with colon (:)
        const colonMatch = textUntilPosition.match(/:\s*([a-zA-Z0-9_]*)$/);
        if (colonMatch) {
          instanceCommonMethods.forEach(m => {
            addSuggestion({
              label: m.name,
              kind: monaco.languages.CompletionItemKind.Method,
              insertText: `${m.name}(\${1})`,
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              detail: `(method) Instance:${m.name}(${m.params}): ${m.ret}`
            });
          });

          // Common Service / Instance specific methods
          const extraMethods = [
            { name: 'GetService', p: 'className: string', r: 'Instance' },
            { name: 'FireServer', p: '...: any', r: '()' },
            { name: 'InvokeServer', p: '...: any', r: 'any' },
            { name: 'Connect', p: 'listener: function', r: 'RBXScriptConnection' },
            { name: 'Disconnect', p: '', r: '()' },
            { name: 'Wait', p: '', r: '...any' },
            { name: 'JSONEncode', p: 'data: any', r: 'string' },
            { name: 'JSONDecode', p: 'json: string', r: 'table' },
            { name: 'HttpGet', p: 'url: string', r: 'string' },
            { name: 'PivotTo', p: 'targetCFrame: CFrame', r: '()' },
            { name: 'GetPivot', p: '', r: 'CFrame' }
          ];

          extraMethods.forEach(m => {
            addSuggestion({
              label: m.name,
              kind: monaco.languages.CompletionItemKind.Method,
              insertText: `${m.name}(\${1})`,
              insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
              detail: `(method) ${m.name}(${m.p}): ${m.r}`
            });
          });

          return { suggestions };
        }

        // Context 5: Property and member access with dot (.)
        const dotMatch = textUntilPosition.match(/\.\s*([a-zA-Z0-9_]*)$/);
        if (dotMatch) {
          // Task library
          if (textUntilPosition.match(/task\s*\.\s*[a-zA-Z0-9_]*$/)) {
            const taskMethods = [
              { name: 'wait', sig: 'wait(duration?: number): number' },
              { name: 'spawn', sig: 'spawn(fn: function, ...: any): thread' },
              { name: 'delay', sig: 'delay(sec: number, fn: function, ...: any): thread' },
              { name: 'defer', sig: 'defer(fn: function, ...: any): thread' },
              { name: 'cancel', sig: 'cancel(thread: thread): ()' }
            ];
            taskMethods.forEach(t => {
              addSuggestion({
                label: t.name,
                kind: monaco.languages.CompletionItemKind.Function,
                insertText: `${t.name}(\${1})`,
                insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                detail: `task.${t.sig}`
              });
            });
            return { suggestions };
          }

          // Properties from Instance
          instanceCommonProps.forEach(p => {
            addSuggestion({
              label: p.name,
              kind: monaco.languages.CompletionItemKind.Property,
              insertText: p.name,
              detail: `(property) Instance.${p.name}: ${p.type}`
            });
          });

          // BasePart, Player, Humanoid common properties
          const commonProps = [
            { name: 'Position', type: 'Vector3' },
            { name: 'CFrame', type: 'CFrame' },
            { name: 'Size', type: 'Vector3' },
            { name: 'Transparency', type: 'number' },
            { name: 'Anchored', type: 'boolean' },
            { name: 'CanCollide', type: 'boolean' },
            { name: 'Material', type: 'Enum.Material' },
            { name: 'Color', type: 'Color3' },
            { name: 'LocalPlayer', type: 'Player' },
            { name: 'Character', type: 'Model?' },
            { name: 'Humanoid', type: 'Humanoid?' },
            { name: 'HumanoidRootPart', type: 'BasePart?' },
            { name: 'Health', type: 'number' },
            { name: 'MaxHealth', type: 'number' },
            { name: 'WalkSpeed', type: 'number' },
            { name: 'JumpPower', type: 'number' },
            { name: 'Value', type: 'any' },
            { name: 'Text', type: 'string' },
            { name: 'Visible', type: 'boolean' }
          ];

          commonProps.forEach(p => {
            addSuggestion({
              label: p.name,
              kind: monaco.languages.CompletionItemKind.Property,
              insertText: p.name,
              detail: `(property) ${p.name}: ${p.type}`
            });
          });

          // Events
          const commonEvents = [
            { name: 'Touched', params: 'otherPart: BasePart' },
            { name: 'TouchEnded', params: 'otherPart: BasePart' },
            { name: 'Changed', params: 'property: string' },
            { name: 'Died', params: '' },
            { name: 'Triggered', params: 'player: Player' },
            { name: 'Heartbeat', params: 'step: number' },
            { name: 'RenderStepped', params: 'step: number' },
            { name: 'Stepped', params: 'time: number, step: number' },
            { name: 'OnClientEvent', params: '...any' }
          ];

          commonEvents.forEach(e => {
            addSuggestion({
              label: e.name,
              kind: monaco.languages.CompletionItemKind.Event,
              insertText: e.name,
              detail: `(event) ${e.name}: RBXScriptSignal(${e.params})`
            });
          });

          return { suggestions };
        }

        // Context 6: Root Globals (Roblox, Potassium, Luau standard libraries)
        // 1. Roblox Globals
        const rootGlobals = [
          { name: 'game', detail: 'DataModel', kind: monaco.languages.CompletionItemKind.Variable, sortText: '0_game' },
          { name: 'workspace', detail: 'Workspace', kind: monaco.languages.CompletionItemKind.Variable, sortText: '1_workspace' },
          { name: 'script', detail: 'Script', kind: monaco.languages.CompletionItemKind.Variable, sortText: '1_script' },
          { name: 'getmetatable', detail: '', insert: 'getmetatable(${1:object})', kind: monaco.languages.CompletionItemKind.Variable, sortText: '2_getmetatable' },
          { name: 'setmetatable', detail: '', insert: 'setmetatable(${1:table}, ${2:metatable})', kind: monaco.languages.CompletionItemKind.Variable, sortText: '2_setmetatable' },
          { name: 'Enum', detail: 'Enums', kind: monaco.languages.CompletionItemKind.Class, sortText: '1_Enum' },
          { name: 'shared', detail: 'table', kind: monaco.languages.CompletionItemKind.Variable, sortText: '1_shared' },
          { name: '_G', detail: 'table', kind: monaco.languages.CompletionItemKind.Variable, sortText: '1__G' },
          { name: 'task', detail: 'library', kind: monaco.languages.CompletionItemKind.Variable, sortText: '1_task' },
          { name: 'Vector3.new', insert: 'Vector3.new(${1:x}, ${2:y}, ${3:z})', detail: 'Vector3.new(x: number, y: number, z: number)' },
          { name: 'Vector3.zero', insert: 'Vector3.zero', detail: 'Vector3(0, 0, 0)' },
          { name: 'CFrame.new', insert: 'CFrame.new(${1:x}, ${2:y}, ${3:z})', detail: 'CFrame.new(x: number, y: number, z: number)' },
          { name: 'CFrame.Angles', insert: 'CFrame.Angles(${1:rx}, ${2:ry}, ${3:rz})', detail: 'CFrame.Angles(rx: number, ry: number, rz: number)' },
          { name: 'Color3.fromRGB', insert: 'Color3.fromRGB(${1:255}, ${2:255}, ${3:255})', detail: 'Color3.fromRGB(r: number, g: number, b: number)' },
          { name: 'Color3.fromHex', insert: 'Color3.fromHex("${1:#ffffff}")', detail: 'Color3.fromHex(hex: string)' },
          { name: 'UDim2.new', insert: 'UDim2.new(${1:0}, ${2:0}, ${3:0}, ${4:0})', detail: 'UDim2.new(sx: number, ox: number, sy: number, oy: number)' },
          { name: 'UDim2.fromScale', insert: 'UDim2.fromScale(${1:x}, ${2:y})', detail: 'UDim2.fromScale(x: number, y: number)' },
          { name: 'UDim2.fromOffset', insert: 'UDim2.fromOffset(${1:x}, ${2:y})', detail: 'UDim2.fromOffset(x: number, y: number)' },
          { name: 'TweenInfo.new', insert: 'TweenInfo.new(${1:time}, ${2:Enum.EasingStyle.Quad}, ${3:Enum.EasingDirection.Out})', detail: 'TweenInfo.new(time: number, style?: Enum, dir?: Enum)' },
          { name: 'Instance.new', insert: 'Instance.new("${1:Part}")', detail: 'Instance.new(className: string, parent?: Instance)' }
        ];

        rootGlobals.forEach(g => {
          addSuggestion({
            label: g.name,
            kind: g.kind || monaco.languages.CompletionItemKind.Variable,
            insertText: g.insert || g.name,
            insertTextRules: g.insert ? monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet : undefined,
            detail: g.detail,
            sortText: g.sortText || ('1_' + g.name)
          });
        });

        // 2. Potassium Functions
        for (const [k, v] of Object.entries(potassiumApis)) {
          addSuggestion({
            label: k,
            kind: monaco.languages.CompletionItemKind.Function,
            insertText: `${k}(\${1})`,
            insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
            detail: '',
            documentation: {
              value: `\`\`\`lua\n${v.sig}\n\`\`\`\n\n${v.doc}`
            },
            sortText: '2_' + k
          });
        }

        return { suggestions };
      }
    };

    // 2. Hover Provider (Interactive Markdown Documentation)
    const hoverProvider = {
      provideHover: function (model, position) {
        const wordInfo = model.getWordAtPosition(position);
        if (!wordInfo) return null;

        const word = wordInfo.word;

        // Check Potassium APIs
        if (potassiumApis[word]) {
          const api = potassiumApis[word];
          return {
            range: new monaco.Range(position.lineNumber, wordInfo.startColumn, position.lineNumber, wordInfo.endColumn),
            contents: [
              { value: `\`\`\`lua\n${api.sig}\n\`\`\`` },
              { value: `**Potassium API**\n\n${api.doc}` }
            ]
          };
        }

        // Check Common Roblox Methods
        const methodMatch = instanceCommonMethods.find(m => m.name === word);
        if (methodMatch) {
          return {
            range: new monaco.Range(position.lineNumber, wordInfo.startColumn, position.lineNumber, wordInfo.endColumn),
            contents: [
              { value: `\`\`\`lua\nfunction Instance:${methodMatch.name}(${methodMatch.params}): ${methodMatch.ret}\n\`\`\`` },
              { value: `**Roblox Instance Method**` }
            ]
          };
        }

        // Check Common Roblox Properties
        const propMatch = instanceCommonProps.find(p => p.name === word);
        if (propMatch) {
          return {
            range: new monaco.Range(position.lineNumber, wordInfo.startColumn, position.lineNumber, wordInfo.endColumn),
            contents: [
              { value: `\`\`\`lua\n(property) Instance.${propMatch.name}: ${propMatch.type}\n\`\`\`` },
              { value: `**Roblox Property**` }
            ]
          };
        }

        // Check Roblox Classes in API dump
        if (apiData.classes && apiData.classes[word]) {
          const classInfo = apiData.classes[word];
          return {
            range: new monaco.Range(position.lineNumber, wordInfo.startColumn, position.lineNumber, wordInfo.endColumn),
            contents: [
              { value: `\`\`\`lua\nclass ${word}${classInfo.super ? ' : ' + classInfo.super : ''}\n\`\`\`` },
              { value: `**Roblox Class Hierarchy**\nInherits from \`${classInfo.super || 'None'}\`` }
            ]
          };
        }

        // Check Roblox Enums in API dump
        if (apiData.enums && apiData.enums[word]) {
          const items = apiData.enums[word];
          return {
            range: new monaco.Range(position.lineNumber, wordInfo.startColumn, position.lineNumber, wordInfo.endColumn),
            contents: [
              { value: `\`\`\`lua\nEnum.${word}\n\`\`\`` },
              { value: `**Roblox Enum** (${items.length} items):\n\`${items.slice(0, 6).join('`, `')}${items.length > 6 ? '` ...' : '`'}` }
            ]
          };
        }

        // Built-in Roblox singletons
        if (word === 'game') {
          return {
            contents: [
              { value: `\`\`\`lua\n(global) game: DataModel\n\`\`\`` },
              { value: `Root of the Roblox instance hierarchy and provider of engine services.` }
            ]
          };
        }
        if (word === 'workspace') {
          return {
            contents: [
              { value: `\`\`\`lua\n(global) workspace: Workspace\n\`\`\`` },
              { value: `The 3D physical world space containing all physical parts and terrain.` }
            ]
          };
        }
        if (word === 'task') {
          return {
            contents: [
              { value: `\`\`\`lua\n(library) task\n\`\`\`` },
              { value: `Luau task scheduler library. Provides \`task.wait\`, \`task.spawn\`, \`task.delay\`, \`task.defer\`, and \`task.cancel\`.` }
            ]
          };
        }

        return null;
      }
    };

    // 3. Signature Help Provider (Active Parameter Documentation)
    const signatureHelpProvider = {
      signatureHelpTriggerCharacters: ['(', ','],
      provideSignatureHelp: function (model, position) {
        const lineContent = model.getLineContent(position.lineNumber);
        const textBefore = lineContent.substring(0, position.column - 1);

        // Match method or function call before open parenthesis
        const callMatch = textBefore.match(/([a-zA-Z0-9_\.:]+)\s*\(([^)]*)$/);
        if (!callMatch) return null;

        const fnName = callMatch[1].split(/[\.:]/).pop();
        const argsInside = callMatch[2];
        const activeParameter = (argsInside.match(/,/g) || []).length;

        // Check Potassium APIs
        if (potassiumApis[fnName]) {
          const api = potassiumApis[fnName];
          return {
            value: {
              activeParameter: activeParameter,
              activeSignature: 0,
              signatures: [{
                label: api.sig,
                documentation: api.doc,
                parameters: extractParameters(api.sig)
              }]
            },
            dispose: () => {}
          };
        }

        // Check Roblox Methods
        const method = instanceCommonMethods.find(m => m.name === fnName);
        if (method) {
          const sig = `Instance:${method.name}(${method.params}): ${method.ret}`;
          return {
            value: {
              activeParameter: activeParameter,
              activeSignature: 0,
              signatures: [{
                label: sig,
                documentation: `Roblox method ${method.name}`,
                parameters: extractParameters(sig)
              }]
            },
            dispose: () => {}
          };
        }

        // Check common constructors
        const constructors = {
          GetService: { sig: 'GetService(serviceName: string): Instance', doc: 'Retrieves an engine service.' },
          new: { sig: 'new(className: string, parent?: Instance): Instance', doc: 'Instantiates a new Roblox object.' },
          wait: { sig: 'task.wait(duration?: number): number', doc: 'Yields execution for duration seconds.' },
          spawn: { sig: 'task.spawn(fn: function, ...: any): thread', doc: 'Runs fn on a new thread immediately.' },
          delay: { sig: 'task.delay(duration: number, fn: function, ...: any): thread', doc: 'Schedules fn after delay.' }
        };

        if (constructors[fnName]) {
          const item = constructors[fnName];
          return {
            value: {
              activeParameter: activeParameter,
              activeSignature: 0,
              signatures: [{
                label: item.sig,
                documentation: item.doc,
                parameters: extractParameters(item.sig)
              }]
            },
            dispose: () => {}
          };
        }

        return null;
      }
    };

    // Register with both 'lua' and 'luau'
    ['lua', 'luau'].forEach(langId => {
      monaco.languages.registerCompletionItemProvider(langId, completionProvider);
      monaco.languages.registerHoverProvider(langId, hoverProvider);
      monaco.languages.registerSignatureHelpProvider(langId, signatureHelpProvider);
    });

    console.log('[Roblox LSP] Registered Completions, Hovers, and Signature Help for lua and luau with Monaco.');
  }

  function extractParameters(sig) {
    const start = sig.indexOf('(');
    const end = sig.indexOf(')');
    if (start === -1 || end === -1) return [];

    const paramStr = sig.substring(start + 1, end).trim();
    if (!paramStr) return [];

    return paramStr.split(',').map(p => ({
      label: p.trim(),
      documentation: ''
    }));
  }

  return {
    init,
    registerWithMonaco,
    setupLuaLSSyntax,
    reapplySyntax: () => {
      if (monacoRef) setupLuaLSSyntax(monacoRef, isLoaded ? Object.keys(apiData.classes) : []);
    },
    isLoaded: () => isLoaded,
    getAllMembers
  };
})();

if (typeof window !== 'undefined') {
  window.RobloxLSP = RobloxLSP;
}

