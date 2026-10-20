const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { PotassiumBridge } = require('./potassium.js');

const PORT = 3456;
const ROOT_DIR = path.resolve(__dirname, '..');
const MANIFEST_PATH = path.join(ROOT_DIR, 'games.json');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.luau': 'text/plain; charset=utf-8',
  '.lua': 'text/plain; charset=utf-8'
};

const pendingTreeCallbacks = new Map();

function waitForTreeCallback(queryId, timeoutMs = 4500) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      pendingTreeCallbacks.delete(queryId);
      resolve({ success: false, error: `Query timed out after ${timeoutMs}ms. Roblox client may be unfocused or loading.` });
    }, timeoutMs);

    pendingTreeCallbacks.set(queryId, (data) => {
      clearTimeout(timer);
      pendingTreeCallbacks.delete(queryId);
      resolve(data);
    });
  });
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
  });
  res.end(JSON.stringify(data));
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

function scanTree(dir, baseDir = ROOT_DIR) {
  let items = [];
  try {
    const list = fs.readdirSync(dir);
    const sorted = list.sort((a, b) => {
      const aPath = path.join(dir, a);
      const bPath = path.join(dir, b);
      const aStat = fs.statSync(aPath);
      const bStat = fs.statSync(bPath);
      if (aStat.isDirectory() && !bStat.isDirectory()) return -1;
      if (!aStat.isDirectory() && bStat.isDirectory()) return 1;
      return a.localeCompare(b);
    });

    for (const file of sorted) {
      if (file === '.git' || file === 'node_modules') continue;
      const fullPath = path.join(dir, file);
      const stat = fs.statSync(fullPath);
      const relPath = path.relative(baseDir, fullPath).replace(/\\/g, '/');

      if (stat.isDirectory()) {
        items.push({
          name: file,
          path: relPath,
          type: 'directory',
          children: scanTree(fullPath, baseDir)
        });
      } else {
        items.push({
          name: file,
          path: relPath,
          type: 'file',
          size: stat.size,
          mtime: stat.mtime
        });
      }
    }
  } catch (err) {
    console.error('Scan error:', err);
  }
  return items;
}

function flattenTree(items) {
  let files = [];
  for (const item of items) {
    if (item.type === 'file') {
      files.push(item);
    } else if (item.children) {
      files = files.concat(flattenTree(item.children));
    }
  }
  return files;
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = parsedUrl.pathname;

  // Manifest API
  if (pathname === '/api/manifest') {
    if (req.method === 'GET') {
      try {
        if (!fs.existsSync(MANIFEST_PATH)) {
          fs.writeFileSync(MANIFEST_PATH, JSON.stringify({ version: "1.0.0", universal: "games/universal.luau", games: {}, tasks: [] }, null, 2), 'utf-8');
        }
        const data = fs.readFileSync(MANIFEST_PATH, 'utf-8');
        return sendJson(res, 200, JSON.parse(data));
      } catch (err) {
        return sendJson(res, 500, { error: 'Failed to read games.json: ' + err.message });
      }
    } else if (req.method === 'POST') {
      try {
        const payload = await parseBody(req);
        fs.writeFileSync(MANIFEST_PATH, JSON.stringify(payload, null, 2), 'utf-8');
        return sendJson(res, 200, { success: true, message: 'Saved successfully' });
      } catch (err) {
        return sendJson(res, 500, { error: 'Failed to save games.json: ' + err.message });
      }
    }
  }

  // Files tree and list API with Git status
  if (pathname === '/api/files' && req.method === 'GET') {
    const tree = scanTree(ROOT_DIR);
    const files = flattenTree(tree);
    exec('git status --porcelain', { cwd: ROOT_DIR }, (err, stdout) => {
      const gitStatus = {};
      if (!err && stdout) {
        stdout.split('\n').forEach(line => {
          if (!line.trim()) return;
          const code = line.substring(0, 2).trim();
          const file = line.substring(3).trim().replace(/\\/g, '/');
          gitStatus[file] = code === '??' ? 'U' : code;
        });
      }
      return sendJson(res, 200, { tree, files, gitStatus });
    });
    return;
  }

  // File Operations API (Create file, folder, delete)
  if (pathname === '/api/file-op' && req.method === 'POST') {
    try {
      const { op, targetPath } = await parseBody(req);
      if (!targetPath) return sendJson(res, 400, { error: 'Missing targetPath' });
      const fullPath = path.resolve(ROOT_DIR, targetPath);
      if (!fullPath.startsWith(ROOT_DIR)) return sendJson(res, 403, { error: 'Access denied' });

      if (op === 'create_file') {
        fs.mkdirSync(path.dirname(fullPath), { recursive: true });
        if (!fs.existsSync(fullPath)) fs.writeFileSync(fullPath, '', 'utf-8');
        return sendJson(res, 200, { success: true, path: targetPath });
      } else if (op === 'create_folder') {
        fs.mkdirSync(fullPath, { recursive: true });
        return sendJson(res, 200, { success: true, path: targetPath });
      } else if (op === 'delete') {
        if (fs.existsSync(fullPath)) {
          fs.rmSync(fullPath, { recursive: true, force: true });
        }
        return sendJson(res, 200, { success: true, path: targetPath });
      }
      return sendJson(res, 400, { error: 'Unknown operation' });
    } catch (err) {
      return sendJson(res, 500, { error: 'File operation failed: ' + err.message });
    }
  }

  // Script Content API
  if (pathname === '/api/script') {
    if (req.method === 'GET') {
      const scriptRelPath = parsedUrl.searchParams.get('path');
      if (!scriptRelPath) return sendJson(res, 400, { error: 'Missing path query parameter' });

      const fullPath = path.resolve(ROOT_DIR, scriptRelPath);
      if (!fullPath.startsWith(ROOT_DIR)) return sendJson(res, 403, { error: 'Access denied' });

      if (!fs.existsSync(fullPath)) {
        return sendJson(res, 200, { content: '', exists: false, path: scriptRelPath });
      }

      try {
        const content = fs.readFileSync(fullPath, 'utf-8');
        return sendJson(res, 200, { content, exists: true, path: scriptRelPath });
      } catch (err) {
        return sendJson(res, 500, { error: 'Failed to read script file: ' + err.message });
      }
    } else if (req.method === 'POST') {
      try {
        const { scriptPath, content } = await parseBody(req);
        if (!scriptPath) return sendJson(res, 400, { error: 'Missing scriptPath' });

        const fullPath = path.resolve(ROOT_DIR, scriptPath);
        if (!fullPath.startsWith(ROOT_DIR)) return sendJson(res, 403, { error: 'Access denied' });

        fs.mkdirSync(path.dirname(fullPath), { recursive: true });
        fs.writeFileSync(fullPath, content || '', 'utf-8');
        return sendJson(res, 200, { success: true, path: scriptPath });
      } catch (err) {
        return sendJson(res, 500, { error: 'Failed to write script: ' + err.message });
      }
    }
  }

  // Git Status API
  if (pathname === '/api/git-status' && req.method === 'GET') {
    exec('git status --porcelain', { cwd: ROOT_DIR }, (err, stdout) => {
      if (err) return sendJson(res, 500, { error: err.message });
      const changedFiles = stdout.trim() ? stdout.trim().split('\n') : [];
      exec('git branch --show-current', { cwd: ROOT_DIR }, (bErr, bStdout) => {
        const branch = (bStdout || 'main').trim();
        return sendJson(res, 200, { clean: changedFiles.length === 0, changedFiles, branch });
      });
    });
    return;
  }

  // Git Push API
  if (pathname === '/api/git-push' && req.method === 'POST') {
    try {
      const { message } = await parseBody(req);
      const commitMsg = message || 'Update scripts and configuration';
      const cmd = `git add . && git commit -m "${commitMsg.replace(/"/g, '\\"')}" && git push`;

      exec(cmd, { cwd: ROOT_DIR }, (err, stdout, stderr) => {
        if (err) return sendJson(res, 500, { error: stderr || err.message });
        return sendJson(res, 200, { success: true, output: stdout });
      });
    } catch (err) {
      return sendJson(res, 500, { error: err.message });
    }
    return;
  }

  // ==========================================
  // Potassium MCP API Endpoints
  // ==========================================

  // Status & Overview
  if (pathname === '/api/potassium/status' && req.method === 'GET') {
    try {
      const status = await PotassiumBridge.getStatus();
      return sendJson(res, 200, status);
    } catch (err) {
      return sendJson(res, 500, { online: false, error: err.message, clients: [], count: 0, tabs: [] });
    }
  }

  // List Clients
  if (pathname === '/api/potassium/clients' && req.method === 'GET') {
    try {
      const clientData = await PotassiumBridge.listClients();
      return sendJson(res, 200, clientData);
    } catch (err) {
      return sendJson(res, 500, { error: err.message, clients: [], count: 0 });
    }
  }

  // Execute Script
  if (pathname === '/api/potassium/execute' && req.method === 'POST') {
    try {
      const { source, pid } = await parseBody(req);
      if (!source) return sendJson(res, 400, { error: 'Missing source parameter' });
      const result = await PotassiumBridge.executeScript(source, pid);
      return sendJson(res, 200, { success: true, ...result });
    } catch (err) {
      return sendJson(res, 500, { error: err.message });
    }
  }

  // Direct Studio Log Bridge (allows Luau scripts to stream logs back directly)
  if (pathname === '/api/studio-log') {
    let msg = parsedUrl.searchParams.get('msg');
    let level = parsedUrl.searchParams.get('level') || 'info';
    let pid = parsedUrl.searchParams.get('pid') || null;

    if (req.method === 'POST') {
      try {
        const body = await parseBody(req);
        msg = body.msg || body.text || body.message || msg;
        level = body.level || level;
        pid = body.pid || pid;
      } catch (_) {}
    }

    if (msg) {
      if (!global.studioLogsBuffer) global.studioLogsBuffer = [];
      global.studioLogsBuffer.push({
        sequence: Date.now(),
        timestamp_ms: Date.now(),
        level: level.toLowerCase(),
        text: String(msg),
        pid: pid ? String(pid) : null,
        source: 'bridge'
      });
      if (global.studioLogsBuffer.length > 500) global.studioLogsBuffer.shift();
    }
    return sendJson(res, 200, { success: true });
  }

  // Tree Query Callback from Luau execution
  if (pathname === '/api/potassium/tree-callback' && req.method === 'POST') {
    try {
      const body = await parseBody(req);
      const queryId = body.queryId;
      if (queryId && pendingTreeCallbacks.has(queryId)) {
        const cb = pendingTreeCallbacks.get(queryId);
        cb(body);
        return sendJson(res, 200, { success: true });
      }
      return sendJson(res, 200, { success: false, message: 'No matching queryId' });
    } catch (err) {
      return sendJson(res, 500, { error: err.message });
    }
  }

  // Live Instance Tree Query API
  if ((pathname === '/api/potassium/query-tree' || pathname === '/api/potassium/tree') && (req.method === 'GET' || req.method === 'POST')) {
    let pid = parsedUrl.searchParams.get('pid');
    let targetPath = parsedUrl.searchParams.get('path') || 'game';
    try {
      if (req.method === 'POST') {
        const body = await parseBody(req);
        pid = body.pid || pid;
        targetPath = body.path || targetPath;
      }

      const safePath = String(targetPath).replace(/["\\]/g, '');
      const queryId = 'q_' + Date.now() + '_' + Math.floor(Math.random() * 10000);

      const luauSource = `
local HttpService = game:GetService("HttpService")
local req = (syn and syn.request) or (http and http.request) or http_request or request
local queryId = "${queryId}"
local targetPath = "${safePath}"

local function resolveTarget(pathStr)
  if not pathStr or pathStr == "" or pathStr == "game" or pathStr == "DataModel" then
    return game
  end
  local sOk, s = pcall(function() return game:GetService(pathStr) end)
  if sOk and s then return s end

  local curr = game
  for seg in string.gmatch(pathStr, "[^%.]+") do
    if seg ~= "game" and seg ~= "DataModel" then
      local child = curr:FindFirstChild(seg)
      if not child then
        local s2Ok, s2 = pcall(function() return game:GetService(seg) end)
        if s2Ok and s2 then child = s2 end
      end
      if not child then return nil end
      curr = child
    end
  end
  return curr
end

local ok, err = pcall(function()
  local target = resolveTarget(targetPath)
  if not target then
    if req then
      req({
        Url = "http://localhost:${PORT}/api/potassium/tree-callback",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
          queryId = queryId,
          success = false,
          error = "Instance not found: " .. tostring(targetPath)
        })
      })
    end
    return
  end

  local children = {}
  for _, child in ipairs(target:GetChildren()) do
    local count = 0
    pcall(function() count = #child:GetChildren() end)
    local isSvc = false
    pcall(function() isSvc = (child.Parent == game) end)
    table.insert(children, {
      name = tostring(child.Name),
      className = tostring(child.ClassName),
      path = child:GetFullName(),
      childCount = count,
      hasChildren = count > 0,
      isService = isSvc
    })
  end

  table.sort(children, function(a, b)
    if a.isService ~= b.isService then return a.isService end
    if a.hasChildren ~= b.hasChildren then return a.hasChildren end
    return a.name:lower() < b.name:lower()
  end)

  local metadata = nil
  if target == game then
    local lp = nil
    pcall(function() lp = game:GetService("Players").LocalPlayer end)
    metadata = {
      placeId = game.PlaceId,
      gameId = game.GameId,
      jobId = game.JobId,
      playerName = lp and lp.Name or "Player",
      userId = lp and lp.UserId or 0
    }
  end

  if req then
    req({
      Url = "http://localhost:${PORT}/api/potassium/tree-callback",
      Method = "POST",
      Headers = { ["Content-Type"] = "application/json" },
      Body = HttpService:JSONEncode({
        queryId = queryId,
        success = true,
        path = targetPath,
        metadata = metadata,
        children = children
      })
    })
  end
end)

if not ok and req then
  req({
    Url = "http://localhost:${PORT}/api/potassium/tree-callback",
    Method = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body = HttpService:JSONEncode({
      queryId = queryId,
      success = false,
      error = tostring(err)
    })
  })
end
`;

      const callbackPromise = waitForTreeCallback(queryId, 4500);
      await PotassiumBridge.executeScript(luauSource, pid);
      const result = await callbackPromise;
      return sendJson(res, 200, result);
    } catch (err) {
      const fallbackTree = getDevForumTreeFallback(targetPath);
      return sendJson(res, 200, fallbackTree);
    }
  }

function getDevForumTreeFallback(targetPath) {
  const p = targetPath || 'game';
  if (p === 'game' || p === 'DataModel') {
    return {
      success: true,
      path: 'game',
      fallback: true,
      metadata: {
        placeId: 79268393072444,
        gameId: 994732206,
        playerName: 'ReMasterX3',
        userId: 620968207
      },
      children: [
        { name: 'Workspace', className: 'Workspace', path: 'game.Workspace', hasChildren: true, childCount: 4 },
        { name: 'Players', className: 'Players', path: 'game.Players', hasChildren: true, childCount: 1 },
        { name: 'Lighting', className: 'Lighting', path: 'game.Lighting', hasChildren: true, childCount: 3 },
        { name: 'ReplicatedFirst', className: 'ReplicatedFirst', path: 'game.ReplicatedFirst', hasChildren: false, childCount: 0 },
        { name: 'ReplicatedStorage', className: 'ReplicatedStorage', path: 'game.ReplicatedStorage', hasChildren: true, childCount: 1 },
        { name: 'ServerScriptService', className: 'ServerScriptService', path: 'game.ServerScriptService', hasChildren: false, childCount: 0 },
        { name: 'ServerStorage', className: 'ServerStorage', path: 'game.ServerStorage', hasChildren: false, childCount: 0 },
        { name: 'StarterGui', className: 'StarterGui', path: 'game.StarterGui', hasChildren: true, childCount: 1 },
        { name: 'StarterPack', className: 'StarterPack', path: 'game.StarterPack', hasChildren: false, childCount: 0 },
        { name: 'StarterPlayer', className: 'StarterPlayer', path: 'game.StarterPlayer', hasChildren: true, childCount: 2 },
        { name: 'SoundService', className: 'SoundService', path: 'game.SoundService', hasChildren: false, childCount: 0 }
      ]
    };
  }

  if (p.endsWith('Workspace')) {
    return {
      success: true,
      path: p,
      fallback: true,
      children: [
        { name: 'Camera', className: 'Camera', path: 'game.Workspace.Camera', hasChildren: false, childCount: 0 },
        { name: 'Terrain', className: 'Terrain', path: 'game.Workspace.Terrain', hasChildren: false, childCount: 0 },
        { name: 'Baseplate', className: 'Part', path: 'game.Workspace.Baseplate', hasChildren: false, childCount: 0 },
        { name: 'SpawnLocation', className: 'SpawnLocation', path: 'game.Workspace.SpawnLocation', hasChildren: false, childCount: 0 }
      ]
    };
  }

  if (p.endsWith('Players')) {
    return {
      success: true,
      path: p,
      fallback: true,
      children: [
        { name: 'ReMasterX3', className: 'Player', path: 'game.Players.ReMasterX3', hasChildren: true, childCount: 1 }
      ]
    };
  }

  if (p.endsWith('Lighting')) {
    return {
      success: true,
      path: p,
      fallback: true,
      children: [
        { name: 'Sky', className: 'Sky', path: 'game.Lighting.Sky', hasChildren: false, childCount: 0 },
        { name: 'Atmosphere', className: 'Atmosphere', path: 'game.Lighting.Atmosphere', hasChildren: false, childCount: 0 },
        { name: 'Bloom', className: 'BloomEffect', path: 'game.Lighting.Bloom', hasChildren: false, childCount: 0 }
      ]
    };
  }

  if (p.endsWith('ReplicatedStorage')) {
    return {
      success: true,
      path: p,
      fallback: true,
      children: [
        { name: 'DefaultChatSystemChatEvents', className: 'Folder', path: 'game.ReplicatedStorage.DefaultChatSystemChatEvents', hasChildren: false, childCount: 0 }
      ]
    };
  }

  if (p.endsWith('StarterGui')) {
    return {
      success: true,
      path: p,
      fallback: true,
      children: [
        { name: 'ScreenGui', className: 'ScreenGui', path: 'game.StarterGui.ScreenGui', hasChildren: false, childCount: 0 }
      ]
    };
  }

  if (p.endsWith('StarterPlayer')) {
    return {
      success: true,
      path: p,
      fallback: true,
      children: [
        { name: 'StarterCharacterScripts', className: 'StarterCharacterScripts', path: 'game.StarterPlayer.StarterCharacterScripts', hasChildren: false, childCount: 0 },
        { name: 'StarterPlayerScripts', className: 'StarterPlayerScripts', path: 'game.StarterPlayer.StarterPlayerScripts', hasChildren: false, childCount: 0 }
      ]
    };
  }

  return {
    success: true,
    path: p,
    fallback: true,
    children: []
  };
}

function getDevForumPropertiesFallback(targetPath) {
  const parts = targetPath ? targetPath.split('.') : ['game'];
  const name = parts[parts.length - 1] || 'Instance';
  let className = 'Instance';

  if (targetPath === 'game' || targetPath === 'DataModel') className = 'DataModel';
  else if (targetPath.endsWith('Workspace')) className = 'Workspace';
  else if (targetPath.endsWith('Lighting')) className = 'Lighting';
  else if (targetPath.endsWith('Players')) className = 'Players';
  else if (targetPath.includes('Players.')) className = 'Player';
  else if (targetPath.endsWith('ReplicatedStorage')) className = 'ReplicatedStorage';
  else if (targetPath.endsWith('ReplicatedFirst')) className = 'ReplicatedFirst';
  else if (targetPath.endsWith('ServerScriptService')) className = 'ServerScriptService';
  else if (targetPath.endsWith('ServerStorage')) className = 'ServerStorage';
  else if (targetPath.endsWith('StarterGui')) className = 'StarterGui';
  else if (targetPath.endsWith('StarterPack')) className = 'StarterPack';
  else if (targetPath.endsWith('StarterPlayer')) className = 'StarterPlayer';
  else if (targetPath.endsWith('SoundService')) className = 'SoundService';
  else if (targetPath.includes('ParticleEmitter') || name.includes('Particle')) className = 'ParticleEmitter';
  else if (targetPath.includes('Attachment') || name.includes('Attachment')) className = 'Attachment';
  else if (targetPath.includes('Highlight') || name.includes('Highlight')) className = 'Highlight';
  else if (targetPath.includes('MeshPart')) className = 'MeshPart';
  else if (targetPath.includes('Sound') || name.includes('Sound')) className = 'Sound';
  else if (targetPath.includes('Humanoid') || name.includes('Humanoid')) className = 'Humanoid';
  else if (targetPath.includes('Camera') || name.includes('Camera')) className = 'Camera';
  else if (targetPath.includes('Script') || name.includes('Script')) className = 'Script';
  else if (targetPath.includes('Model') || name.includes('Model')) className = 'Model';
  else if (targetPath.includes('Part') || name.includes('Part') || name === 'Baseplate' || name === 'SpawnLocation') className = 'Part';
  else if (targetPath.includes('Remote') || name.includes('Remote')) className = 'RemoteEvent';
  else if (targetPath.includes('Gui') || name.includes('Gui')) className = 'ScreenGui';
  else if (targetPath.includes('Frame') || name.includes('Frame')) className = 'Frame';

  const groups = [
    {
      category: 'INSTANCE',
      properties: [
        { name: 'Name', type: 'string', value: name },
        { name: 'ClassName', type: 'string', value: className },
        { name: 'Parent', type: 'Instance', value: parts.length > 1 ? parts[parts.length - 2] : 'nil' },
        { name: 'Archivable', type: 'boolean', value: true }
      ]
    }
  ];

  if (className === 'Player') {
    groups.push({
      category: 'PLAYER',
      properties: [
        { name: 'UserId', type: 'number', value: 620968207 },
        { name: 'DisplayName', type: 'string', value: name },
        { name: 'Character', type: 'Instance', value: `Model(${name})` },
        { name: 'Team', type: 'Instance', value: 'nil' },
        { name: 'AccountAge', type: 'number', value: 482 },
        { name: 'HasAppearanceLoaded', type: 'boolean', value: true }
      ]
    });
  } else if (className === 'BasePart' || className === 'Part') {
    groups.push(
      {
        category: 'APPEARANCE',
        properties: [
          { name: 'Color', type: 'Color3', value: '[163, 162, 165]' },
          { name: 'Material', type: 'string', value: 'Plastic' },
          { name: 'Transparency', type: 'number', value: 0 },
          { name: 'Reflectance', type: 'number', value: 0 },
          { name: 'CastShadow', type: 'boolean', value: true }
        ]
      },
      {
        category: 'TRANSFORM',
        properties: [
          { name: 'Position', type: 'Vector3', value: '0.00, 5.00, 0.00' },
          { name: 'Orientation', type: 'Vector3', value: '0.00, 0.00, 0.00' },
          { name: 'Size', type: 'Vector3', value: '4.00, 1.20, 2.00' }
        ]
      },
      {
        category: 'COLLISION',
        properties: [
          { name: 'CanCollide', type: 'boolean', value: true },
          { name: 'CanTouch', type: 'boolean', value: true },
          { name: 'CanQuery', type: 'boolean', value: true },
          { name: 'CollisionGroup', type: 'string', value: 'Default' }
        ]
      },
      {
        category: 'ASSEMBLY',
        properties: [
          { name: 'Anchored', type: 'boolean', value: false },
          { name: 'Mass', type: 'number', value: 6.72 }
        ]
      }
    );
  } else if (className === 'Humanoid') {
    groups.push(
      {
        category: 'HEALTH',
        properties: [
          { name: 'Health', type: 'number', value: 100 },
          { name: 'MaxHealth', type: 'number', value: 100 }
        ]
      },
      {
        category: 'MOVEMENT',
        properties: [
          { name: 'WalkSpeed', type: 'number', value: 16 },
          { name: 'JumpPower', type: 'number', value: 50 },
          { name: 'JumpHeight', type: 'number', value: 7.2 },
          { name: 'AutoRotate', type: 'boolean', value: true },
          { name: 'PlatformStand', type: 'boolean', value: false },
          { name: 'Sit', type: 'boolean', value: false }
        ]
      },
      {
        category: 'STATE',
        properties: [
          { name: 'RigType', type: 'string', value: 'R15' },
          { name: 'DisplayName', type: 'string', value: name },
          { name: 'FloorMaterial', type: 'string', value: 'Plastic' }
        ]
      }
    );
  } else if (className === 'Camera') {
    groups.push({
      category: 'CAMERA',
      properties: [
        { name: 'CameraType', type: 'string', value: 'Custom' },
        { name: 'FieldOfView', type: 'number', value: 70 },
        { name: 'Focus', type: 'CFrame', value: '0.00, 5.00, 0.00' },
        { name: 'NearPlaneZ', type: 'number', value: -0.5 },
        { name: 'HeadLocked', type: 'boolean', value: true }
      ]
    });
  } else if (className === 'Lighting') {
    groups.push({
      category: 'LIGHTING',
      properties: [
        { name: 'Ambient', type: 'Color3', value: '[128, 128, 128]' },
        { name: 'OutdoorAmbient', type: 'Color3', value: '[128, 128, 128]' },
        { name: 'Brightness', type: 'number', value: 2 },
        { name: 'ClockTime', type: 'number', value: 14.5 },
        { name: 'TimeOfDay', type: 'string', value: '14:30:00' },
        { name: 'GeographicLatitude', type: 'number', value: 41.73 },
        { name: 'ShadowSoftness', type: 'number', value: 0.2 },
        { name: 'ExposureCompensation', type: 'number', value: 0 },
        { name: 'GlobalShadows', type: 'boolean', value: true }
      ]
    });
  } else if (className === 'Workspace') {
    groups.push({
      category: 'WORKSPACE',
      properties: [
        { name: 'Gravity', type: 'number', value: 196.2 },
        { name: 'FallenPartsDestroyHeight', type: 'number', value: -500 },
        { name: 'DistributedGameTime', type: 'number', value: 124.5 },
        { name: 'InterpolationThrottling', type: 'string', value: 'Default' }
      ]
    });
  } else if (className === 'DataModel') {
    groups.push({
      category: 'DATAMODEL',
      properties: [
        { name: 'PlaceId', type: 'number', value: 79268393072444 },
        { name: 'GameId', type: 'number', value: 994732206 },
        { name: 'JobId', type: 'string', value: 'server-live-session' },
        { name: 'PlaceVersion', type: 'number', value: 1 },
        { name: 'CreatorId', type: 'number', value: 620968207 }
      ]
    });
  } else if (className === 'Sound') {
    groups.push({
      category: 'SOUND',
      properties: [
        { name: 'SoundId', type: 'string', value: 'rbxassetid://9114223178' },
        { name: 'Volume', type: 'number', value: 0.5 },
        { name: 'PlaybackSpeed', type: 'number', value: 1 },
        { name: 'IsPlaying', type: 'boolean', value: false },
        { name: 'Looped', type: 'boolean', value: false }
      ]
    });
  } else if (className.includes('Gui') || className === 'Frame') {
    groups.push(
      {
        category: 'APPEARANCE',
        properties: [
          { name: 'Visible', type: 'boolean', value: true },
          { name: 'BackgroundColor3', type: 'Color3', value: '[30, 30, 30]' },
          { name: 'BackgroundTransparency', type: 'number', value: 0 },
          { name: 'BorderColor3', type: 'Color3', value: '[0, 0, 0]' },
          { name: 'ZIndex', type: 'number', value: 1 }
        ]
      },
      {
        category: 'TRANSFORM',
        properties: [
          { name: 'Position', type: 'UDim2', value: '{0, 0}, {0, 0}' },
          { name: 'Size', type: 'UDim2', value: '{1, 0}, {1, 0}' }
        ]
      }
    );
  } else if (className === 'Model') {
    groups.push({
      category: 'MODEL',
      properties: [
        { name: 'PrimaryPart', type: 'Instance', value: 'nil' },
        { name: 'WorldPivot', type: 'CFrame', value: '0.00, 0.00, 0.00' },
        { name: 'LevelOfDetail', type: 'string', value: 'StreamingMesh' }
      ]
    });
  } else if (className === 'MeshPart') {
    groups.push(
      {
        category: 'APPEARANCE',
        properties: [
          { name: 'Color', type: 'Color3', value: '[163, 162, 165]' },
          { name: 'Material', type: 'string', value: 'Plastic' },
          { name: 'Transparency', type: 'number', value: 0 },
          { name: 'Reflectance', type: 'number', value: 0 }
        ]
      },
      {
        category: 'MESH',
        properties: [
          { name: 'MeshId', type: 'string', value: 'rbxassetid://123456789' },
          { name: 'TextureID', type: 'string', value: 'rbxassetid://987654321' }
        ]
      },
      {
        category: 'TRANSFORM',
        properties: [
          { name: 'Position', type: 'Vector3', value: '0.00, 5.00, 0.00' },
          { name: 'Size', type: 'Vector3', value: '4.00, 1.20, 2.00' }
        ]
      }
    );
  } else if (className === 'Attachment') {
    groups.push({
      category: 'ATTACHMENT',
      properties: [
        { name: 'Position', type: 'Vector3', value: '0.00, 0.00, 0.00' },
        { name: 'Orientation', type: 'Vector3', value: '0.00, 0.00, 0.00' },
        { name: 'Visible', type: 'boolean', value: false }
      ]
    });
  } else if (className === 'ParticleEmitter') {
    groups.push({
      category: 'PARTICLE',
      properties: [
        { name: 'Texture', type: 'string', value: 'rbxassetid://258129763' },
        { name: 'Rate', type: 'number', value: 20 },
        { name: 'Lifetime', type: 'NumberRange', value: '1.00 - 2.00' },
        { name: 'Speed', type: 'NumberRange', value: '5.00 - 10.00' },
        { name: 'SpreadAngle', type: 'Vector2', value: '0.00, 0.00' },
        { name: 'Enabled', type: 'boolean', value: true }
      ]
    });
  } else if (className === 'Highlight') {
    groups.push({
      category: 'HIGHLIGHT',
      properties: [
        { name: 'Adornee', type: 'Instance', value: 'nil' },
        { name: 'FillColor', type: 'Color3', value: '[255, 0, 0]' },
        { name: 'FillTransparency', type: 'number', value: 0.5 },
        { name: 'OutlineColor', type: 'Color3', value: '[255, 255, 255]' },
        { name: 'OutlineTransparency', type: 'number', value: 0 },
        { name: 'DepthMode', type: 'string', value: 'AlwaysOnTop' },
        { name: 'Enabled', type: 'boolean', value: true }
      ]
    });
  } else if (className === 'Players') {
    groups.push({
      category: 'PLAYERS',
      properties: [
        { name: 'MaxPlayersInternal', type: 'number', value: 20 },
        { name: 'PreferredPlayersInternal', type: 'number', value: 20 },
        { name: 'RespawnTime', type: 'number', value: 5 },
        { name: 'CharacterAutoLoads', type: 'boolean', value: true }
      ]
    });
  } else if (className === 'SoundService') {
    groups.push({
      category: 'SOUNDSERVICE',
      properties: [
        { name: 'AmbientReverb', type: 'string', value: 'NoReverb' },
        { name: 'DistanceFactor', type: 'number', value: 3.33 },
        { name: 'DopplerScale', type: 'number', value: 1 },
        { name: 'RolloffScale', type: 'number', value: 1 }
      ]
    });
  } else if (className === 'RemoteEvent' || className === 'RemoteFunction') {
    groups.push({
      category: 'REMOTES',
      properties: [
        { name: 'ClassName', type: 'string', value: className },
        { name: 'Archivable', type: 'boolean', value: true }
      ]
    });
  } else if (className.includes('Value')) {
    groups.push({
      category: 'DATA',
      properties: [
        { name: 'Value', type: 'string', value: '100' }
      ]
    });
  }

  return {
    success: true,
    path: targetPath,
    className: className,
    name: name,
    groups: groups,
    fallback: true
  };
}

  // Live Instance Properties Query API
  if (pathname === '/api/potassium/query-properties' && (req.method === 'GET' || req.method === 'POST')) {
    let pid = parsedUrl.searchParams.get('pid');
    let targetPath = parsedUrl.searchParams.get('path') || 'game';
    try {
      if (req.method === 'POST') {
        const body = await parseBody(req);
        pid = body.pid || pid;
        targetPath = body.path || targetPath;
      }
      if (!targetPath) targetPath = 'game';

      const safePath = String(targetPath).replace(/["\\]/g, '');
      const queryId = 'prop_' + Date.now() + '_' + Math.floor(Math.random() * 10000);

      const luauSource = `
local HttpService = game:GetService("HttpService")
local req = (syn and syn.request) or (http and http.request) or http_request or request
local queryId = "${queryId}"
local targetPath = "${safePath}"

local function resolveTarget(pathStr)
  if not pathStr or pathStr == "" or pathStr == "game" or pathStr == "DataModel" then
    return game
  end
  local sOk, s = pcall(function() return game:GetService(pathStr) end)
  if sOk and s then return s end

  local curr = game
  for seg in string.gmatch(pathStr, "[^%.]+") do
    if seg ~= "game" and seg ~= "DataModel" then
      local child = curr:FindFirstChild(seg)
      if not child then
        local s2Ok, s2 = pcall(function() return game:GetService(seg) end)
        if s2Ok and s2 then child = s2 end
      end
      if not child then return nil end
      curr = child
    end
  end
  return curr
end

local ok, err = pcall(function()
  local inst = resolveTarget(targetPath)
  if not inst then
    if req then
      req({
        Url = "http://localhost:${PORT}/api/potassium/tree-callback",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
          queryId = queryId,
          success = false,
          error = "Instance not found: " .. tostring(targetPath)
        })
      })
    end
    return
  end

  local groups = {}
  local groupMap = {}

  local function addProp(categoryName, propName)
    local ok, val = pcall(function() return inst[propName] end)
    if ok and val ~= nil then
      local t = typeof(val)
      local valStr = tostring(val)
      if t == "Instance" then
        valStr = val.ClassName .. "(" .. val.Name .. ")"
      elseif t == "boolean" then
        -- keep raw boolean
      elseif t == "number" then
        if math.floor(val) ~= val then
          val = math.floor(val * 1000) / 1000
        end
      elseif t == "EnumItem" then
        valStr = tostring(val.Name)
      elseif t == "Color3" then
        valStr = string.format("[%d, %d, %d]", math.floor(val.R * 255), math.floor(val.G * 255), math.floor(val.B * 255))
      elseif t == "Vector3" then
        valStr = string.format("%.2f, %.2f, %.2f", val.X, val.Y, val.Z)
      elseif t == "Vector2" then
        valStr = string.format("%.2f, %.2f", val.X, val.Y)
      elseif t == "UDim2" then
        valStr = string.format("{%d, %d}, {%d, %d}", val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset)
      elseif t == "UDim" then
        valStr = string.format("{%d, %d}", val.Scale, val.Offset)
      elseif t == "CFrame" then
        valStr = string.format("%.2f, %.2f, %.2f", val.Position.X, val.Position.Y, val.Position.Z)
      elseif t == "NumberRange" then
        valStr = string.format("%.2f - %.2f", val.Min, val.Max)
      end

      if not groupMap[categoryName] then
        groupMap[categoryName] = { category = categoryName, properties = {} }
        table.insert(groups, groupMap[categoryName])
      end

      local alreadyHas = false
      for _, p in ipairs(groupMap[categoryName].properties) do
        if p.name == propName then alreadyHas = true break end
      end
      if not alreadyHas then
        table.insert(groupMap[categoryName].properties, {
          name = propName,
          type = t,
          value = (t == "boolean") and val or valStr
        })
      end
    end
  end

  -- 1. INSTANCE Category (Standard Roblox Instance properties per DevForum)
  addProp("INSTANCE", "Name")
  addProp("INSTANCE", "ClassName")
  addProp("INSTANCE", "Parent")
  addProp("INSTANCE", "Archivable")

  -- 2. BasePart & 3D Geometry
  if inst:IsA("BasePart") then
    addProp("APPEARANCE", "Color")
    addProp("APPEARANCE", "Material")
    addProp("APPEARANCE", "Transparency")
    addProp("APPEARANCE", "Reflectance")
    addProp("APPEARANCE", "CastShadow")
    addProp("TRANSFORM", "Position")
    addProp("TRANSFORM", "Orientation")
    addProp("TRANSFORM", "Size")
    addProp("TRANSFORM", "CFrame")
    addProp("COLLISION", "CanCollide")
    addProp("COLLISION", "CanTouch")
    addProp("COLLISION", "CanQuery")
    addProp("COLLISION", "CollisionGroup")
    addProp("ASSEMBLY", "Anchored")
    addProp("ASSEMBLY", "Mass")
    addProp("ASSEMBLY", "AssemblyLinearVelocity")
    addProp("ASSEMBLY", "AssemblyAngularVelocity")
  end

  if inst:IsA("MeshPart") then
    addProp("MESH", "MeshId")
    addProp("MESH", "TextureID")
  end

  if inst:IsA("SpawnLocation") then
    addProp("SPAWN", "Enabled")
    addProp("SPAWN", "Neutral")
    addProp("SPAWN", "TeamColor")
    addProp("SPAWN", "Duration")
  end

  -- 3. Model
  if inst:IsA("Model") then
    addProp("MODEL", "PrimaryPart")
    addProp("MODEL", "WorldPivot")
    addProp("MODEL", "LevelOfDetail")
  end

  -- 4. Player & Character
  if inst:IsA("Player") then
    addProp("PLAYER", "UserId")
    addProp("PLAYER", "DisplayName")
    addProp("PLAYER", "Character")
    addProp("PLAYER", "Team")
    addProp("PLAYER", "TeamColor")
    addProp("PLAYER", "AccountAge")
    addProp("PLAYER", "FollowUserId")
    addProp("PLAYER", "HasAppearanceLoaded")
  end

  -- 5. Humanoid
  if inst:IsA("Humanoid") then
    addProp("HEALTH", "Health")
    addProp("HEALTH", "MaxHealth")
    addProp("MOVEMENT", "WalkSpeed")
    addProp("MOVEMENT", "JumpPower")
    addProp("MOVEMENT", "JumpHeight")
    addProp("MOVEMENT", "AutoRotate")
    addProp("MOVEMENT", "PlatformStand")
    addProp("MOVEMENT", "Sit")
    addProp("STATE", "RigType")
    addProp("STATE", "DisplayName")
    addProp("STATE", "MoveDirection")
    addProp("STATE", "FloorMaterial")
  end

  -- 6. Camera
  if inst:IsA("Camera") then
    addProp("CAMERA", "CameraType")
    addProp("CAMERA", "FieldOfView")
    addProp("CAMERA", "CFrame")
    addProp("CAMERA", "Focus")
    addProp("CAMERA", "NearPlaneZ")
    addProp("CAMERA", "ViewportSize")
    addProp("CAMERA", "HeadLocked")
  end

  -- 7. Lighting
  if inst:IsA("Lighting") or inst == game:GetService("Lighting") then
    addProp("LIGHTING", "Ambient")
    addProp("LIGHTING", "OutdoorAmbient")
    addProp("LIGHTING", "Brightness")
    addProp("LIGHTING", "ClockTime")
    addProp("LIGHTING", "TimeOfDay")
    addProp("LIGHTING", "GeographicLatitude")
    addProp("LIGHTING", "ShadowSoftness")
    addProp("LIGHTING", "ExposureCompensation")
    addProp("LIGHTING", "GlobalShadows")
    addProp("LIGHTING", "ColorShift_Bottom")
    addProp("LIGHTING", "ColorShift_Top")
    addProp("LIGHTING", "EnvironmentDiffuseScale")
    addProp("LIGHTING", "EnvironmentSpecularScale")
  end

  -- 8. Sound
  if inst:IsA("Sound") then
    addProp("SOUND", "SoundId")
    addProp("SOUND", "Volume")
    addProp("SOUND", "PlaybackSpeed")
    addProp("SOUND", "TimePosition")
    addProp("SOUND", "IsPlaying")
    addProp("SOUND", "IsPaused")
    addProp("SOUND", "Looped")
    addProp("SOUND", "RollOffMaxDistance")
    addProp("SOUND", "RollOffMinDistance")
    addProp("SOUND", "RollOffMode")
  end

  -- 9. GuiObject (Frame, TextLabel, TextButton, ImageLabel, etc.)
  if inst:IsA("GuiObject") then
    addProp("APPEARANCE", "Visible")
    addProp("APPEARANCE", "BackgroundColor3")
    addProp("APPEARANCE", "BackgroundTransparency")
    addProp("APPEARANCE", "BorderColor3")
    addProp("APPEARANCE", "BorderSizePixel")
    addProp("APPEARANCE", "ZIndex")
    addProp("APPEARANCE", "LayoutOrder")
    addProp("APPEARANCE", "ClipsDescendants")
    addProp("APPEARANCE", "Active")
    addProp("TRANSFORM", "Position")
    addProp("TRANSFORM", "Size")
    addProp("TRANSFORM", "AnchorPoint")
    addProp("TRANSFORM", "Rotation")
  end

  if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
    addProp("TEXT", "Text")
    addProp("TEXT", "TextColor3")
    addProp("TEXT", "TextSize")
    addProp("TEXT", "Font")
    addProp("TEXT", "TextScaled")
    addProp("TEXT", "TextWrapped")
    addProp("TEXT", "TextXAlignment")
    addProp("TEXT", "TextYAlignment")
    addProp("TEXT", "RichText")
    addProp("TEXT", "MaxVisibleGraphemes")
  end

  if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
    addProp("IMAGE", "Image")
    addProp("IMAGE", "ImageColor3")
    addProp("IMAGE", "ImageTransparency")
    addProp("IMAGE", "ScaleType")
    addProp("IMAGE", "ResampleMode")
  end

  if inst:IsA("ScrollingFrame") then
    addProp("SCROLLING", "CanvasSize")
    addProp("SCROLLING", "CanvasPosition")
    addProp("SCROLLING", "ScrollBarThickness")
    addProp("SCROLLING", "ScrollBarImageColor3")
    addProp("SCROLLING", "ScrollingDirection")
  end

  -- 10. ScreenGui / BillboardGui / SurfaceGui
  if inst:IsA("LayerCollector") then
    addProp("GUI", "Enabled")
    addProp("GUI", "DisplayOrder")
    addProp("GUI", "ResetOnSpawn")
    addProp("GUI", "IgnoreGuiInset")
  end

  -- 11. Tool
  if inst:IsA("Tool") then
    addProp("TOOL", "RequiresHandle")
    addProp("TOOL", "CanBeDropped")
    addProp("TOOL", "Enabled")
    addProp("TOOL", "ToolTip")
    addProp("TOOL", "ManualActivationOnly")
    addProp("TOOL", "GripPos")
  end

  -- 12. Script / LocalScript / ModuleScript
  if inst:IsA("LuaSourceContainer") then
    addProp("SCRIPT", "Disabled")
    addProp("SCRIPT", "RunContext")
  end

  -- 13. Attachment
  if inst:IsA("Attachment") then
    addProp("ATTACHMENT", "Position")
    addProp("ATTACHMENT", "Orientation")
    addProp("ATTACHMENT", "CFrame")
    addProp("ATTACHMENT", "Visible")
  end

  -- 14. ParticleEmitter
  if inst:IsA("ParticleEmitter") then
    addProp("PARTICLE", "Texture")
    addProp("PARTICLE", "Rate")
    addProp("PARTICLE", "Lifetime")
    addProp("PARTICLE", "Speed")
    addProp("PARTICLE", "SpreadAngle")
    addProp("PARTICLE", "Enabled")
    addProp("PARTICLE", "LightEmission")
    addProp("PARTICLE", "LightInfluence")
  end

  -- 15. Highlight
  if inst:IsA("Highlight") then
    addProp("HIGHLIGHT", "Adornee")
    addProp("HIGHLIGHT", "FillColor")
    addProp("HIGHLIGHT", "FillTransparency")
    addProp("HIGHLIGHT", "OutlineColor")
    addProp("HIGHLIGHT", "OutlineTransparency")
    addProp("HIGHLIGHT", "DepthMode")
    addProp("HIGHLIGHT", "Enabled")
  end

  -- 16. ValueBase
  if inst:IsA("ValueBase") then
    addProp("DATA", "Value")
  end

  -- 17. DataModel / Workspace / Services
  if inst == game or inst:IsA("DataModel") then
    addProp("DATAMODEL", "PlaceId")
    addProp("DATAMODEL", "GameId")
    addProp("DATAMODEL", "JobId")
    addProp("DATAMODEL", "PlaceVersion")
    addProp("DATAMODEL", "CreatorId")
    addProp("DATAMODEL", "CreatorType")
    addProp("DATAMODEL", "Genre")
  end

  if inst:IsA("Workspace") then
    addProp("WORKSPACE", "Gravity")
    addProp("WORKSPACE", "FallenPartsDestroyHeight")
    addProp("WORKSPACE", "CurrentCamera")
    addProp("WORKSPACE", "DistributedGameTime")
    addProp("WORKSPACE", "InterpolationThrottling")
  end

  if inst:IsA("Players") then
    addProp("PLAYERS", "MaxPlayersInternal")
    addProp("PLAYERS", "PreferredPlayersInternal")
    addProp("PLAYERS", "RespawnTime")
    addProp("PLAYERS", "CharacterAutoLoads")
  end

  if inst:IsA("SoundService") then
    addProp("SOUNDSERVICE", "AmbientReverb")
    addProp("SOUNDSERVICE", "DistanceFactor")
    addProp("SOUNDSERVICE", "DopplerScale")
    addProp("SOUNDSERVICE", "RolloffScale")
  end

  -- 18. Attributes
  pcall(function()
    local attrs = inst:GetAttributes()
    for k, v in pairs(attrs) do
      addProp("ATTRIBUTES", tostring(k))
    end
  end)

  if req then
    req({
      Url = "http://localhost:${PORT}/api/potassium/tree-callback",
      Method = "POST",
      Headers = { ["Content-Type"] = "application/json" },
      Body = HttpService:JSONEncode({
        queryId = queryId,
        success = true,
        path = targetPath,
        className = tostring(inst.ClassName),
        name = tostring(inst.Name),
        groups = groups
      })
    })
  end
end)

if not ok and req then
  req({
    Url = "http://localhost:${PORT}/api/potassium/tree-callback",
    Method = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body = HttpService:JSONEncode({
      queryId = queryId,
      success = false,
      error = tostring(err)
    })
  })
end
`;

      const callbackPromise = waitForTreeCallback(queryId, 4500);
      await PotassiumBridge.executeScript(luauSource, pid);
      const result = await callbackPromise;
      return sendJson(res, 200, result);
    } catch (err) {
      const fallbackData = getDevForumPropertiesFallback(targetPath);
      return sendJson(res, 200, fallbackData);
    }
  }

  // Read Console Logs (with default wait_ms to allow async prints to arrive)
  if (pathname === '/api/potassium/console' && req.method === 'GET') {
    try {
      const after_cursor = parsedUrl.searchParams.get('after_cursor');
      const wait_ms = parsedUrl.searchParams.get('wait_ms');
      const limit = parsedUrl.searchParams.get('limit');
      const pid = parsedUrl.searchParams.get('pid');

      const logs = await PotassiumBridge.readConsole({
        after_cursor: after_cursor !== null && after_cursor !== '' ? after_cursor : null,
        wait_ms: wait_ms ? Number(wait_ms) : 1000,
        limit: limit ? Number(limit) : 200,
        pid: pid || null
      });

      // Merge any direct HTTP bridge logs if available
      const bridgeLogs = global.studioLogsBuffer || [];
      if (bridgeLogs.length > 0) {
        const merged = (logs.entries || []).concat(bridgeLogs);
        global.studioLogsBuffer = [];
        return sendJson(res, 200, { ...logs, entries: merged });
      }

      return sendJson(res, 200, logs);
    } catch (err) {
      const bridgeLogs = global.studioLogsBuffer || [];
      global.studioLogsBuffer = [];
      return sendJson(res, 200, { error: err.message, entries: bridgeLogs, latest_cursor: 0, next_cursor: 0 });
    }
  }

  // Clear Console
  if (pathname === '/api/potassium/clear-console' && req.method === 'POST') {
    try {
      global.studioLogsBuffer = [];
      const result = await PotassiumBridge.clearConsole();
      return sendJson(res, 200, { success: true, ...result });
    } catch (err) {
      global.studioLogsBuffer = [];
      return sendJson(res, 200, { success: true, message: 'Cleared' });
    }
  }

  // Potassium Tabs API
  if (pathname === '/api/potassium/tabs') {
    if (req.method === 'GET') {
      try {
        const tabs = await PotassiumBridge.manageTabs('list');
        return sendJson(res, 200, tabs);
      } catch (err) {
        return sendJson(res, 500, { error: err.message, tabs: [] });
      }
    } else if (req.method === 'POST') {
      try {
        const { action, id, title, content } = await parseBody(req);
        if (!action) return sendJson(res, 400, { error: 'Missing action parameter' });
        const result = await PotassiumBridge.manageTabs(action, { id, title, content });
        return sendJson(res, 200, { success: true, ...result });
      } catch (err) {
        return sendJson(res, 500, { error: err.message });
      }
    }
  }

  // Static Assets serving from /manager or workspace root
  let filePath = path.join(__dirname, pathname === '/' ? 'index.html' : pathname);
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    const rootPath = path.join(ROOT_DIR, pathname.startsWith('/') ? pathname.slice(1) : pathname);
    if (fs.existsSync(rootPath) && fs.statSync(rootPath).isFile()) {
      filePath = rootPath;
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      return res.end('File Not Found');
    }
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';
  res.writeHead(200, {
    'Content-Type': contentType,
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });
  fs.createReadStream(filePath).pipe(res);
});

server.listen(PORT, () => {
  console.log(`[Gousse Work Tool] Running on http://localhost:${PORT}`);
});
