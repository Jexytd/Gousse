const http = require('http');
const fs = require('fs');
const path = require('path');

// Default MCP Configuration
const MCP_CONFIG_PATH = path.join(
  process.env.USERPROFILE || 'C:\\Users\\Gouang',
  '.gemini',
  'config',
  'mcp_config.json'
);

function getMcpConfig() {
  try {
    if (fs.existsSync(MCP_CONFIG_PATH)) {
      const raw = fs.readFileSync(MCP_CONFIG_PATH, 'utf-8');
      const parsed = JSON.parse(raw);
      if (parsed.mcpServers && parsed.mcpServers.potassium) {
        return parsed.mcpServers.potassium;
      }
    }
  } catch (err) {
    console.error('[Potassium MCP] Error loading mcp_config.json:', err.message);
  }

  // Fallback defaults
  return {
    type: 'streamable-http',
    url: 'http://127.0.0.1:8225/mcp',
    headers: {
      'Authorization': 'Bearer V-xwsQ9W75J6sro5FF3Qvj03U_Q2XFqlw-BBOoXkWus'
    }
  };
}

/**
 * Call a tool on the Potassium MCP server via JSON-RPC 2.0
 */
function callPotassiumTool(toolName, args = {}) {
  return new Promise((resolve, reject) => {
    const config = getMcpConfig();
    const targetUrl = new URL(config.url || 'http://127.0.0.1:8225/mcp');

    const payload = JSON.stringify({
      jsonrpc: '2.0',
      id: Date.now() + Math.floor(Math.random() * 1000),
      method: 'tools/call',
      params: {
        name: toolName,
        arguments: args
      }
    });

    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
      'Content-Length': Buffer.byteLength(payload),
      ...(config.headers || {})
    };

    const req = http.request(
      {
        hostname: targetUrl.hostname,
        port: targetUrl.port || 8225,
        path: targetUrl.pathname,
        method: 'POST',
        headers,
        timeout: 10000
      },
      (res) => {
        let responseBody = '';
        res.on('data', chunk => { responseBody += chunk; });
        res.on('end', () => {
          try {
            const data = JSON.parse(responseBody);
            if (data.error) {
              return reject(new Error(data.error.message || 'MCP RPC Error'));
            }
            if (data.result && data.result.isError) {
              const errText = data.result.content?.[0]?.text || 'Tool returned error';
              return reject(new Error(errText));
            }

            // Return structuredContent if present, else fallback to parsed content text
            if (data.result && data.result.structuredContent) {
              return resolve(data.result.structuredContent);
            }
            if (data.result && data.result.content?.[0]?.text) {
              try {
                return resolve(JSON.parse(data.result.content[0].text));
              } catch (_) {
                return resolve({ text: data.result.content[0].text });
              }
            }
            resolve(data.result || {});
          } catch (e) {
            reject(new Error('Failed to parse MCP response: ' + responseBody.substring(0, 150)));
          }
        });
      }
    );

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('MCP server request timed out'));
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(payload);
    req.end();
  });
}

/**
 * High-level Potassium APIs
 */
const PotassiumBridge = {
  // Check if MCP server is online and list clients
  async getStatus() {
    try {
      const clientData = await callPotassiumTool('list_clients', {});
      const tabsData = await callPotassiumTool('tabs', { action: 'list' }).catch(() => ({ tabs: [] }));
      return {
        online: true,
        clients: clientData.clients || [],
        count: clientData.count || (clientData.clients ? clientData.clients.length : 0),
        tabs: tabsData.tabs || [],
        timestamp: Date.now()
      };
    } catch (err) {
      return {
        online: false,
        error: err.message,
        clients: [],
        count: 0,
        tabs: [],
        timestamp: Date.now()
      };
    }
  },

  // List all connected clients
  async listClients() {
    return await callPotassiumTool('list_clients', {});
  },

  // Execute Luau source on one or all clients
  async executeScript(source, pid = null) {
    if (!source || typeof source !== 'string') {
      throw new Error('source must be a non-empty string');
    }
    const args = { source };
    if (pid && pid !== 'all') {
      args.pid = String(pid);
    }
    return await callPotassiumTool('execute_script', args);
  },

  // Read console output logs
  async readConsole(options = {}) {
    const args = {};
    if (options.after_cursor !== undefined && options.after_cursor !== null) {
      args.after_cursor = Number(options.after_cursor);
    }
    if (options.wait_ms !== undefined && options.wait_ms !== null) {
      args.wait_ms = Math.min(30000, Number(options.wait_ms));
    }
    if (options.limit !== undefined && options.limit !== null) {
      args.limit = Math.min(1000, Number(options.limit));
    }
    if (options.pid && options.pid !== 'all') {
      args.pid = String(options.pid);
    }
    return await callPotassiumTool('read_console', args);
  },

  // Clear console log history
  async clearConsole() {
    return await callPotassiumTool('clear_console', {});
  },

  // Manage Potassium editor tabs
  async manageTabs(action, params = {}) {
    return await callPotassiumTool('tabs', { action, ...params });
  }
};

module.exports = {
  PotassiumBridge,
  callPotassiumTool
};
