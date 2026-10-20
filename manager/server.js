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
    try {
      let pid = parsedUrl.searchParams.get('pid');
      let targetPath = parsedUrl.searchParams.get('path') || 'game';

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
      return sendJson(res, 500, { success: false, error: err.message });
    }
  }

  // Live Instance Properties Query API
  if (pathname === '/api/potassium/query-properties' && (req.method === 'GET' || req.method === 'POST')) {
    try {
      let pid = parsedUrl.searchParams.get('pid');
      let targetPath = parsedUrl.searchParams.get('path');
      if (req.method === 'POST') {
        const body = await parseBody(req);
        pid = body.pid || pid;
        targetPath = body.path || targetPath;
      }
      if (!targetPath) return sendJson(res, 400, { error: 'Missing path parameter' });

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

  -- 1. INSTANCE Category (standard to all Instances)
  local instProps = {
    { name = "Name", type = "string", value = tostring(inst.Name) },
    { name = "ClassName", type = "string", value = tostring(inst.ClassName) },
    { name = "Parent", type = "Instance", value = inst.Parent and (inst.Parent.ClassName .. "(" .. inst.Parent.Name .. ")") or "nil" },
    { name = "Archivable", type = "boolean", value = inst.Archivable }
  }
  table.insert(groups, { category = "INSTANCE", properties = instProps })

  -- 2. Class Specific Categories
  if inst:IsA("Player") then
    local playerProps = {
      { name = "Character", type = "Instance", value = inst.Character and ("Model(" .. inst.Character.Name .. ")") or "nil" },
      { name = "UserId", type = "number", value = inst.UserId },
      { name = "DisplayName", type = "string", value = tostring(inst.DisplayName or inst.Name) },
      { name = "Team", type = "Instance", value = inst.Team and ("Team(" .. inst.Team.Name .. ")") or "nil" }
    }
    table.insert(groups, { category = "PLAYER", properties = playerProps })
  elseif inst:IsA("BasePart") then
    local partProps = {
      { name = "Position", type = "Vector3", value = tostring(inst.Position) },
      { name = "Size", type = "Vector3", value = tostring(inst.Size) },
      { name = "Orientation", type = "Vector3", value = tostring(inst.Orientation) },
      { name = "CFrame", type = "CFrame", value = tostring(inst.CFrame) },
      { name = "Anchored", type = "boolean", value = inst.Anchored },
      { name = "CanCollide", type = "boolean", value = inst.CanCollide },
      { name = "Transparency", type = "number", value = inst.Transparency },
      { name = "Material", type = "string", value = tostring(inst.Material.Name) },
      { name = "Color", type = "Color3", value = tostring(inst.Color) }
    }
    table.insert(groups, { category = "PART", properties = partProps })
  elseif inst:IsA("Model") then
    local modelProps = {
      { name = "PrimaryPart", type = "Instance", value = inst.PrimaryPart and (inst.PrimaryPart.ClassName .. "(" .. inst.PrimaryPart.Name .. ")") or "nil" },
      { name = "WorldPivot", type = "CFrame", value = tostring(inst.WorldPivot) }
    }
    table.insert(groups, { category = "MODEL", properties = modelProps })
  elseif inst:IsA("Humanoid") then
    local humProps = {
      { name = "Health", type = "number", value = math.floor(inst.Health * 10) / 10 },
      { name = "MaxHealth", type = "number", value = math.floor(inst.MaxHealth * 10) / 10 },
      { name = "WalkSpeed", type = "number", value = inst.WalkSpeed },
      { name = "JumpPower", type = "number", value = inst.JumpPower },
      { name = "RigType", type = "string", value = tostring(inst.RigType.Name) }
    }
    table.insert(groups, { category = "HUMANOID", properties = humProps })
  elseif inst:IsA("ValueBase") then
    local valProps = {
      { name = "Value", type = type(inst.Value), value = tostring(inst.Value) }
    }
    table.insert(groups, { category = "DATA", properties = valProps })
  elseif inst:IsA("GuiObject") then
    local guiProps = {
      { name = "Visible", type = "boolean", value = inst.Visible },
      { name = "ZIndex", type = "number", value = inst.ZIndex },
      { name = "Position", type = "UDim2", value = tostring(inst.Position) },
      { name = "Size", type = "UDim2", value = tostring(inst.Size) },
      { name = "BackgroundColor3", type = "Color3", value = tostring(inst.BackgroundColor3) }
    }
    table.insert(groups, { category = "GUI", properties = guiProps })
  elseif inst:IsA("LayerCollector") then
    local layerProps = {
      { name = "Enabled", type = "boolean", value = inst.Enabled },
      { name = "DisplayOrder", type = "number", value = inst.DisplayOrder or 0 },
      { name = "ResetOnSpawn", type = "boolean", value = inst.ResetOnSpawn }
    }
    table.insert(groups, { category = "GUI LAYER", properties = layerProps })
  elseif inst:IsA("LuaSourceContainer") then
    local sProps = {
      { name = "Disabled", type = "boolean", value = inst.Disabled or false }
    }
    table.insert(groups, { category = "SCRIPT", properties = sProps })
  elseif inst == game then
    local dmProps = {
      { name = "PlaceId", type = "number", value = game.PlaceId },
      { name = "GameId", type = "number", value = game.GameId },
      { name = "JobId", type = "string", value = tostring(game.JobId) },
      { name = "PlaceVersion", type = "number", value = game.PlaceVersion },
      { name = "CreatorId", type = "number", value = game.CreatorId }
    }
    table.insert(groups, { category = "DATAMODEL", properties = dmProps })
  end

  pcall(function()
    local attrs = inst:GetAttributes()
    local attrProps = {}
    for k, v in pairs(attrs) do
      table.insert(attrProps, { name = tostring(k), type = type(v), value = tostring(v) })
    end
    if #attrProps > 0 then
      table.insert(groups, { category = "ATTRIBUTES", properties = attrProps })
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
      return sendJson(res, 500, { success: false, error: err.message });
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
