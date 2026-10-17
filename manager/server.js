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
