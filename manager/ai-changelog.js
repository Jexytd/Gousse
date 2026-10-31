// Gousse Studio - AI Script Changelog & Release Notes Generator
// Automatically scans Luau script AST/features, git diffs, and exploit mechanics
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

function execPromise(cmd, cwd) {
  return new Promise((resolve) => {
    exec(cmd, { cwd }, (err, stdout, stderr) => {
      resolve({ err, stdout: stdout || '', stderr: stderr || '' });
    });
  });
}

const ICON_EMOJI_MAP = {
  'shopping-cart': '🛒',
  'mouse-pointer': '👆',
  'trending-up': '📈',
  'refresh-cw': '🔄',
  'play': '▶️',
  'zap': '⚡',
  'shield': '🛡️',
  'crosshair': '🎯',
  'eye': '👁️',
  'move': '🏃',
  'wrench': '🔧',
  'sliders': '🎛️',
  'activity': '📊',
  'box': '📦',
  'flame': '🔥',
  'terminal': '💻',
  'folder': '📁',
  'users': '👥'
};

function getEmojiForTab(tabName, iconName) {
  if (iconName && ICON_EMOJI_MAP[iconName.toLowerCase()]) {
    return ICON_EMOJI_MAP[iconName.toLowerCase()];
  }
  const lower = (tabName || '').toLowerCase();
  if (lower.includes('buy') || lower.includes('shop')) return '🛒';
  if (lower.includes('click') || lower.includes('tap')) return '👆';
  if (lower.includes('upgrade') || lower.includes('stat')) return '📈';
  if (lower.includes('rebirth') || lower.includes('reset')) return '🔄';
  if (lower.includes('game') || lower.includes('play')) return '🎮';
  if (lower.includes('combat') || lower.includes('attack') || lower.includes('kill')) return '⚔️';
  if (lower.includes('aim') || lower.includes('target')) return '🎯';
  if (lower.includes('esp') || lower.includes('visual')) return '👁️';
  if (lower.includes('move') || lower.includes('speed') || lower.includes('fly')) return '🚀';
  if (lower.includes('farm') || lower.includes('auto')) return '⚡';
  if (lower.includes('setting') || lower.includes('config')) return '⚙️';
  return '✨';
}

function parseLuauFeatures(content) {
  const result = {
    window: null,
    tabs: [],
    toggles: [],
    sliders: [],
    dropdowns: [],
    buttons: [],
    keybinds: [],
    mechanics: []
  };

  if (!content || typeof content !== 'string') return result;

  // Window Title & SubTitle
  const winMatch = content.match(/CreateWindow\s*\(\s*\{([\s\S]*?)\}\s*\)/);
  if (winMatch) {
    const titleM = winMatch[1].match(/Title\s*=\s*["']([^"']+)["']/);
    const subM = winMatch[1].match(/SubTitle\s*=\s*["']([^"']+)["']/);
    result.window = {
      title: titleM ? titleM[1] : '',
      subtitle: subM ? subM[1] : ''
    };
  }

  // Tabs: CreateTab({ Name = "...", Icon = "..." })
  const tabRegex = /CreateTab\s*\(\s*\{([^}]+)\}/g;
  let tm;
  while ((tm = tabRegex.exec(content)) !== null) {
    const block = tm[1];
    const nameM = block.match(/Name\s*=\s*["']([^"']+)["']/);
    const iconM = block.match(/Icon\s*=\s*["']([^"']+)["']/);
    if (nameM) {
      result.tabs.push({
        name: nameM[1],
        icon: iconM ? iconM[1] : '',
        emoji: getEmojiForTab(nameM[1], iconM ? iconM[1] : '')
      });
    }
  }

  // Toggles: CreateToggle({ Name = "...", SubTitle = "..." })
  const togRegex = /CreateToggle\s*\(\s*\{([^}]+)\}/g;
  let gm;
  while ((gm = togRegex.exec(content)) !== null) {
    const block = gm[1];
    const nameM = block.match(/Name\s*=\s*["']([^"']+)["']/);
    const subM = block.match(/SubTitle\s*=\s*["']([^"']+)["']/);
    if (nameM) {
      result.toggles.push({
        name: nameM[1],
        subtitle: subM ? subM[1] : ''
      });
    }
  }

  // Sliders: CreateSlider({ Name = "...", Suffix = "..." })
  const sldRegex = /CreateSlider\s*\(\s*\{([^}]+)\}/g;
  let sm;
  while ((sm = sldRegex.exec(content)) !== null) {
    const block = sm[1];
    const nameM = block.match(/Name\s*=\s*["']([^"']+)["']/);
    const sufM = block.match(/Suffix\s*=\s*["']([^"']+)["']/);
    const minM = block.match(/Min\s*=\s*([0-9.]+)/);
    const maxM = block.match(/Max\s*=\s*([0-9.]+)/);
    if (nameM) {
      result.sliders.push({
        name: nameM[1],
        suffix: sufM ? sufM[1] : '',
        min: minM ? minM[1] : null,
        max: maxM ? maxM[1] : null
      });
    }
  }

  // Dropdowns: CreateDropdown({ Name = "...", Options = {...} })
  const dropRegex = /CreateDropdown\s*\(\s*\{([^}]+)\}/g;
  let dm;
  while ((dm = dropRegex.exec(content)) !== null) {
    const block = dm[1];
    const nameM = block.match(/Name\s*=\s*["']([^"']+)["']/);
    const optM = block.match(/Options\s*=\s*\{([^}]+)\}/);
    if (nameM) {
      result.dropdowns.push({
        name: nameM[1],
        options: optM ? optM[1].split(',').map(s => s.replace(/["'\s]/g, '')).filter(Boolean) : []
      });
    }
  }

  // Detect internal automation & exploit mechanics
  if (content.includes('TouchTransmitter')) {
    result.mechanics.push('TouchTransmitter automated interaction for instant button triggers');
  }
  if (content.includes('ClickDetector')) {
    result.mechanics.push('ClickDetector automated interaction hook');
  }
  if (content.includes('hookmetamethod') || content.includes('__namecall')) {
    result.mechanics.push('Metamethod __namecall packet interception');
  }
  if (content.includes('FireServer') || content.includes('InvokeServer')) {
    result.mechanics.push('Automated RemoteEvent / RemoteFunction network packet triggers');
  }
  if (content.includes('Raycast') || content.toLowerCase().includes('silent aim') || content.toLowerCase().includes('aimbot')) {
    result.mechanics.push('Raycast vector interception & combat targeting system');
  }
  if (content.includes('Drawing.new') || content.toLowerCase().includes('esp')) {
    result.mechanics.push('Drawing library ESP overlays & visual radar');
  }
  if (content.includes('Rebirth') || content.includes('REBIRTH')) {
    result.mechanics.push('Autonomous rebirth progression loop');
  }
  if (content.includes('Minigame') || content.includes('Drone') || content.includes('Rhythm')) {
    result.mechanics.push('Minigame automated controller');
  }
  if (content.includes('TweenInfo') || content.includes('TweenService')) {
    result.mechanics.push('TweenService coordinate traversal & teleport mechanics');
  }

  return result;
}

async function parseGitDiffs(rootDir, targetScriptRelPath) {
  let diffRes = await execPromise(`git diff HEAD -- "${targetScriptRelPath || '.'}"`, rootDir);
  let isRecentCommit = false;

  if (!diffRes.stdout || diffRes.stdout.trim().length === 0) {
    diffRes = await execPromise(`git show HEAD --stat -p -- "${targetScriptRelPath || '.'}"`, rootDir);
    isRecentCommit = true;
  }

  const rawDiff = diffRes.stdout || '';
  const changes = [];

  const addedLines = rawDiff.split('\n').filter(l => l.startsWith('+') && !l.startsWith('+++'));
  const removedLines = rawDiff.split('\n').filter(l => l.startsWith('-') && !l.startsWith('---'));

  for (const line of addedLines) {
    const text = line.substring(1).trim();
    if (text.startsWith('--') || text.length < 5) continue;

    if (text.includes('CreateTab')) {
      const m = text.match(/Name\s*=\s*["']([^"']+)["']/);
      if (m) changes.push(`Added new Tab module: **${m[1]}**`);
    } else if (text.includes('CreateToggle')) {
      const m = text.match(/Name\s*=\s*["']([^"']+)["']/);
      if (m && !changes.some(c => c.includes(m[1]))) changes.push(`Added Toggle: **${m[1]}**`);
    } else if (text.includes('CreateSlider')) {
      const m = text.match(/Name\s*=\s*["']([^"']+)["']/);
      if (m && !changes.some(c => c.includes(m[1]))) changes.push(`Added Slider: **${m[1]}**`);
    } else if (text.includes('TouchTransmitter') && !changes.some(c => c.includes('TouchTransmitter'))) {
      changes.push(`Implemented TouchTransmitter automation for instant plot interactions`);
    } else if ((text.includes('Lucide') || text.includes('ResolveIcon')) && !changes.some(c => c.includes('Lucide'))) {
      changes.push(`Integrated Lucide vector icon suite (819 icons)`);
    } else if (text.includes('DevMode') && !changes.some(c => c.includes('DevMode'))) {
      changes.push(`Added auto-detecting local DevMode for live script syncing`);
    } else if (text.includes('places') && text.includes('universeId') && !changes.some(c => c.includes('Universe ID'))) {
      changes.push(`Improved Universe ID & Place ID resolution in Universal Loader`);
    }
  }

  return {
    isRecentCommit,
    addedCount: addedLines.length,
    removedCount: removedLines.length,
    detectedHighlights: Array.from(new Set(changes))
  };
}

function resolveTargetScriptPath(targetName, rootDir) {
  if (!targetName) return null;
  const manifestPath = path.join(rootDir, 'games.json');
  if (!fs.existsSync(manifestPath)) return null;

  try {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf-8'));
    const games = manifest.games || {};

    const cleanTarget = targetName.toLowerCase();

    // Universal Script
    if (cleanTarget.includes('universal')) {
      return manifest.universal || 'games/universal.luau';
    }

    // Search direct game entries
    for (const [uid, g] of Object.entries(games)) {
      const gName = (g.name || '').toLowerCase();
      if (cleanTarget.includes(gName) || gName.includes(cleanTarget)) {
        // Check if subplace is specified
        if (g.places) {
          for (const [pid, p] of Object.entries(g.places)) {
            const pName = (p.name || '').toLowerCase();
            if (cleanTarget.includes(pName) || pName.includes(cleanTarget)) {
              if (p.script && fs.existsSync(path.join(rootDir, p.script))) {
                return p.script;
              }
            }
          }
        }
        if (g.entry && fs.existsSync(path.join(rootDir, g.entry))) {
          return g.entry;
        }
      }
    }

    // Try matching files in games/ directory directly
    const gamesDir = path.join(rootDir, 'games');
    if (fs.existsSync(gamesDir)) {
      const dirs = fs.readdirSync(gamesDir);
      for (const d of dirs) {
        const full = path.join(gamesDir, d);
        if (fs.statSync(full).isDirectory()) {
          const slug = d.replace(/_/g, ' ').toLowerCase();
          if (cleanTarget.includes(slug) || slug.includes(cleanTarget)) {
            const mainLuau = path.join(full, 'main.luau');
            if (fs.existsSync(mainLuau)) {
              return path.relative(rootDir, mainLuau).replace(/\\/g, '/');
            }
          }
        }
      }
    }
  } catch (_) {}

  return null;
}

function bumpVersion(currentVer) {
  if (!currentVer) return '1.0.1';
  const parts = currentVer.replace(/^v/, '').split('.').map(n => parseInt(n, 10) || 0);
  while (parts.length < 3) parts.push(0);
  parts[2] += 1;
  return parts.join('.');
}

async function generateAiChangelog({ target, mode = 'smart', rootDir }) {
  const scriptRelPath = resolveTargetScriptPath(target, rootDir);
  let scriptContent = '';
  if (scriptRelPath && fs.existsSync(path.join(rootDir, scriptRelPath))) {
    scriptContent = fs.readFileSync(path.join(rootDir, scriptRelPath), 'utf-8');
  }

  const features = parseLuauFeatures(scriptContent);
  const diffInfo = await parseGitDiffs(rootDir, scriptRelPath);

  const title = (features.window && features.window.title) || target || 'Gousse Studio Script';
  const lines = [];

  // Title header
  lines.push(`🚀 **${title} Update Release**`);

  if (mode === 'diff' && diffInfo.detectedHighlights.length > 0) {
    diffInfo.detectedHighlights.forEach(h => lines.push(`• ✨ ${h}`));
    lines.push(`• ⚡ Optimasi performa dan stabilitas eksekusi`);
  } else if (mode === 'features' || diffInfo.detectedHighlights.length === 0) {
    // Feature Breakdown Mode
    if (features.tabs.length > 0) {
      features.tabs.forEach(tab => {
        // Find toggles or sliders that correspond to this tab
        const relatedToggles = features.toggles.filter(t => {
          const tName = t.name.toLowerCase();
          const tabL = tab.name.toLowerCase();
          return tName.includes(tabL) || tabL.includes('auto') && tName.includes('auto');
        });

        if (relatedToggles.length > 0) {
          const togDescs = relatedToggles.slice(0, 2).map(t => t.name).join(', ');
          lines.push(`• ${tab.emoji} **${tab.name}**: ${togDescs}`);
        } else {
          lines.push(`• ${tab.emoji} **${tab.name}**: Modul otomasi dan fitur gameplay`);
        }
      });
    }

    if (features.mechanics.length > 0) {
      features.mechanics.slice(0, 2).forEach(m => lines.push(`• 🛠️ ${m}`));
    }

    lines.push(`• 🎨 GousseUI modern tactical theme dengan 819 Lucide vector icons`);
  } else {
    // Smart Mode: Combines Diffs with key features
    if (diffInfo.detectedHighlights.length > 0) {
      diffInfo.detectedHighlights.forEach(h => lines.push(`• ✨ ${h}`));
    }

    if (features.tabs.length > 0) {
      const tabSummary = features.tabs.map(t => `${t.emoji} ${t.name}`).join(' • ');
      lines.push(`• 📦 **Modul**: ${tabSummary}`);
    }

    if (features.mechanics.length > 0) {
      lines.push(`• 🛠️ **Mekanik**: ${features.mechanics[0]}`);
    }

    lines.push(`• ⚡ Optimasi performa, stabilitas bypass, dan latensi`);
  }

  // Determine suggested version
  let currentVer = '1.0.1';
  try {
    const whCfg = JSON.parse(fs.readFileSync(path.join(rootDir, 'manager/webhook-config.json'), 'utf-8'));
    if (whCfg && whCfg.version) currentVer = whCfg.version;
  } catch (_) {}

  const suggestedVersion = bumpVersion(currentVer);

  return {
    success: true,
    target: target || title,
    scriptPath: scriptRelPath,
    changelog: lines.join('\n'),
    suggestedVersion,
    featuresFound: {
      tabsCount: features.tabs.length,
      togglesCount: features.toggles.length,
      slidersCount: features.sliders.length,
      mechanicsCount: features.mechanics.length
    },
    diffInfo: {
      added: diffInfo.addedCount,
      removed: diffInfo.removedCount,
      highlights: diffInfo.detectedHighlights
    }
  };
}

module.exports = {
  parseLuauFeatures,
  parseGitDiffs,
  resolveTargetScriptPath,
  generateAiChangelog
};

