// Gousse Studio - ScreenGui Visual Designer & Sandbox Engine
// Author: Google Deepmind Antigravity Pair Programmer
// Description: Interactive Roblox UI Builder with Desktop/Mobile canvas, Explorer tree, live properties, drag & resize, and real-time auto-updating LocalScript generator.

(function () {
  'use strict';

  // Device Presets
  const VIEWPORT_PRESETS = {
    desktop_1080: { name: 'Desktop (1920x1080)', width: 1920, height: 1080, type: 'desktop', defaultScale: 0.42 },
    desktop_768: { name: 'Desktop (1366x768)', width: 1366, height: 768, type: 'desktop', defaultScale: 0.58 },
    mobile_iphone_h: { name: 'Mobile Landscape (844x390)', width: 844, height: 390, type: 'mobile', defaultScale: 0.95 },
    mobile_iphone_v: { name: 'Mobile Portrait (390x844)', width: 390, height: 844, type: 'mobile', defaultScale: 0.65 },
    tablet_ipad: { name: 'Tablet (1024x768)', width: 1024, height: 768, type: 'tablet', defaultScale: 0.62 }
  };

  // State
  const state = {
    selectedDeviceId: 'mobile_iphone_h',
    zoomScale: 0.95,
    autoFitZoom: true,
    mode: 'edit', // 'edit' or 'play'
    sizingMode: 'offset', // 'offset' or 'scale'
    selectedElementId: 'inst_main_frame',
    activeTab: 'properties', // 'properties' or 'code'
    isDragging: false,
    isResizing: false,
    resizeHandle: null,
    dragStart: { mouseX: 0, mouseY: 0, elemLeft: 0, elemTop: 0, elemWidth: 0, elemHeight: 0 },
    // Camera pan & navigation
    camera: { x: 0, y: 0 },
    isPanning: false,
    panStart: { mouseX: 0, mouseY: 0, camX: 0, camY: 0 },
    tool: 'select', // 'select' or 'hand'
    isSpacePressed: false,
    // Clipboard & History
    clipboard: null,
    undoStack: [],
    redoStack: [],
    maxHistory: 50,
    idCounter: 10,
    tree: {
      id: 'inst_root_screen_gui',
      className: 'ScreenGui',
      name: 'CustomScreenGui',
      properties: {
        ResetOnSpawn: false,
        ZIndexBehavior: 'Sibling',
        DisplayOrder: 0
      },
      children: [
        {
          id: 'inst_main_frame',
          className: 'Frame',
          name: 'MainFrame',
          properties: {
            Position: { X: { Scale: 0.5, Offset: 0 }, Y: { Scale: 0.5, Offset: 0 } },
            Size: { X: { Scale: 0, Offset: 350 }, Y: { Scale: 0, Offset: 230 } },
            AnchorPoint: { X: 0.5, Y: 0.5 },
            BackgroundColor3: '#0b0e14',
            BackgroundTransparency: 0,
            BorderSizePixel: 0,
            BorderColor3: '#1e293b',
            ClipsDescendants: false,
            Visible: true,
            ZIndex: 1
          },
          children: [
            {
              id: 'inst_corner_1',
              className: 'UICorner',
              name: 'WindowCorner',
              properties: { CornerRadius: { Scale: 0, Offset: 10 } },
              children: []
            },
            {
              id: 'inst_stroke_1',
              className: 'UIStroke',
              name: 'WindowStroke',
              properties: { Color: '#10b981', Thickness: 1.5, Transparency: 0.2 },
              children: []
            },
            {
              id: 'inst_header_frame',
              className: 'Frame',
              name: 'HeaderFrame',
              properties: {
                Position: { X: { Scale: 0, Offset: 0 }, Y: { Scale: 0, Offset: 0 } },
                Size: { X: { Scale: 1, Offset: 0 }, Y: { Scale: 0, Offset: 38 } },
                AnchorPoint: { X: 0, Y: 0 },
                BackgroundColor3: '#0f131b',
                BackgroundTransparency: 0,
                BorderSizePixel: 0,
                BorderColor3: '#1e293b',
                ClipsDescendants: false,
                Visible: true,
                ZIndex: 2
              },
              children: [
                {
                  id: 'inst_title_lbl',
                  className: 'TextLabel',
                  name: 'TitleLabel',
                  properties: {
                    Position: { X: { Scale: 0, Offset: 14 }, Y: { Scale: 0, Offset: 8 } },
                    Size: { X: { Scale: 1, Offset: -60 }, Y: { Scale: 0, Offset: 22 } },
                    AnchorPoint: { X: 0, Y: 0 },
                    BackgroundColor3: '#ffffff',
                    BackgroundTransparency: 1,
                    Text: 'Gousse ScreenGui Sandbox',
                    TextColor3: '#f8fafc',
                    TextSize: 13,
                    Font: 'GothamBold',
                    TextXAlignment: 'Left',
                    TextYAlignment: 'Center',
                    TextScaled: false,
                    TextWrapped: true,
                    Visible: true,
                    ZIndex: 3
                  },
                  children: []
                },
                {
                  id: 'inst_close_btn',
                  className: 'TextButton',
                  name: 'CloseButton',
                  properties: {
                    Position: { X: { Scale: 1, Offset: -30 }, Y: { Scale: 0, Offset: 7 } },
                    Size: { X: { Scale: 0, Offset: 24 }, Y: { Scale: 0, Offset: 24 } },
                    AnchorPoint: { X: 0, Y: 0 },
                    BackgroundColor3: '#f43f5e',
                    BackgroundTransparency: 0.15,
                    Text: '✕',
                    TextColor3: '#ffffff',
                    TextSize: 11,
                    Font: 'GothamBold',
                    TextXAlignment: 'Center',
                    TextYAlignment: 'Center',
                    Visible: true,
                    ZIndex: 4
                  },
                  children: [
                    {
                      id: 'inst_close_corner',
                      className: 'UICorner',
                      name: 'Corner',
                      properties: { CornerRadius: { Scale: 0, Offset: 5 } },
                      children: []
                    }
                  ]
                }
              ]
            },
            {
              id: 'inst_content_frame',
              className: 'Frame',
              name: 'ContentFrame',
              properties: {
                Position: { X: { Scale: 0, Offset: 14 }, Y: { Scale: 0, Offset: 50 } },
                Size: { X: { Scale: 1, Offset: -28 }, Y: { Scale: 1, Offset: -64 } },
                AnchorPoint: { X: 0, Y: 0 },
                BackgroundColor3: '#131923',
                BackgroundTransparency: 0,
                BorderSizePixel: 0,
                BorderColor3: '#1e293b',
                ClipsDescendants: false,
                Visible: true,
                ZIndex: 2
              },
              children: [
                {
                  id: 'inst_content_corner',
                  className: 'UICorner',
                  name: 'Corner',
                  properties: { CornerRadius: { Scale: 0, Offset: 8 } },
                  children: []
                },
                {
                  id: 'inst_desc_lbl',
                  className: 'TextLabel',
                  name: 'DescLabel',
                  properties: {
                    Position: { X: { Scale: 0, Offset: 12 }, Y: { Scale: 0, Offset: 10 } },
                    Size: { X: { Scale: 1, Offset: -24 }, Y: { Scale: 0, Offset: 40 } },
                    AnchorPoint: { X: 0, Y: 0 },
                    BackgroundColor3: '#ffffff',
                    BackgroundTransparency: 1,
                    Text: 'Interactive ScreenGui sandbox. Resize, reposition, round corners, and auto-generate clean Luau code.',
                    TextColor3: '#94a3b8',
                    TextSize: 11,
                    Font: 'Gotham',
                    TextXAlignment: 'Left',
                    TextYAlignment: 'Top',
                    TextScaled: false,
                    TextWrapped: true,
                    Visible: true,
                    ZIndex: 3
                  },
                  children: []
                },
                {
                  id: 'inst_exec_btn',
                  className: 'TextButton',
                  name: 'ExecuteButton',
                  properties: {
                    Position: { X: { Scale: 0.5, Offset: -75 }, Y: { Scale: 1, Offset: -46 } },
                    Size: { X: { Scale: 0, Offset: 150 }, Y: { Scale: 0, Offset: 34 } },
                    AnchorPoint: { X: 0.5, Y: 0 },
                    BackgroundColor3: '#10b981',
                    BackgroundTransparency: 0,
                    Text: 'Execute Script',
                    TextColor3: '#ffffff',
                    TextSize: 12,
                    Font: 'GothamBold',
                    TextXAlignment: 'Center',
                    TextYAlignment: 'Center',
                    Visible: true,
                    ZIndex: 4
                  },
                  children: [
                    {
                      id: 'inst_btn_corner_1',
                      className: 'UICorner',
                      name: 'Corner',
                      properties: { CornerRadius: { Scale: 0, Offset: 6 } },
                      children: []
                    },
                    {
                      id: 'inst_btn_localscript',
                      className: 'LocalScript',
                      name: 'OnClickScript',
                      properties: {
                        ScriptCode: "print('[Gousse Sandbox] Execute button clicked!')"
                      },
                      children: []
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  };

  // Helper: Find element by ID in tree
  function findElementById(node, id) {
    if (node.id === id) return node;
    if (node.children) {
      for (const child of node.children) {
        const found = findElementById(child, id);
        if (found) return found;
      }
    }
    return null;
  }

  // Helper: Find parent of element by ID
  function findParentOf(root, id) {
    if (root.children) {
      for (const child of root.children) {
        if (child.id === id) return root;
        const found = findParentOf(child, id);
        if (found) return found;
      }
    }
    return null;
  }

  // Collect all container instances eligible for parenting
  function collectContainers(node, excludeSubtreeId, list = []) {
    if (!node) return list;
    if (node.id === excludeSubtreeId) return list;
    if (['ScreenGui', 'Frame', 'ScrollingFrame'].includes(node.className)) {
      list.push(node);
    }
    if (node.children) {
      node.children.forEach(child => collectContainers(child, excludeSubtreeId, list));
    }
    return list;
  }

  // Move an element to a new parent container with undo support
  function reparentElement(elemId, newParentId) {
    if (elemId === newParentId) return;
    const elem = findElementById(state.tree, elemId);
    const oldParent = findParentOf(state.tree, elemId);
    const newParent = findElementById(state.tree, newParentId);
    if (!elem || !oldParent || !newParent) return;

    // Check if newParent is inside elem (prevent cyclic parenting)
    let check = newParent;
    while (check) {
      if (check.id === elemId) return;
      check = findParentOf(state.tree, check.id);
    }

    saveHistoryState(`Move ${elem.name} to ${newParent.name}`);
    const idx = oldParent.children.indexOf(elem);
    if (idx !== -1) oldParent.children.splice(idx, 1);
    if (!newParent.children) newParent.children = [];
    newParent.children.push(elem);

    renderExplorerTree();
    renderVirtualCanvas();
    renderPropertiesPanel();
    updateLocalScriptCode();
    if (typeof showToast === 'function') {
      showToast(`Moved "${elem.name}" to "${newParent.name}"`);
    }
  }

  // Smart container resolution when adding or pasting elements
  function resolveTargetParent(className) {
    const isModifier = ['UICorner', 'UIStroke', 'LocalScript'].includes(className);
    let selected = findElementById(state.tree, state.selectedElementId) || state.tree;

    if (isModifier) {
      if (['UICorner', 'UIStroke', 'LocalScript'].includes(selected.className)) {
        return findParentOf(state.tree, selected.id) || state.tree;
      }
      if (selected.className === 'ScreenGui') {
        const firstVisual = (selected.children || []).find(c => !['UICorner', 'UIStroke', 'LocalScript'].includes(c.className));
        return firstVisual || selected;
      }
      return selected;
    } else {
      // Visual elements (Frame, TextLabel, TextButton, TextBox, ImageLabel, ScrollingFrame)
      // Must not be placed inside modifiers
      if (['UICorner', 'UIStroke', 'LocalScript'].includes(selected.className)) {
        selected = findParentOf(state.tree, selected.id) || state.tree;
      }
      // If selected is a leaf element (TextLabel, TextBox, ImageLabel),
      // add as sibling in its parent container
      if (['TextLabel', 'TextBox', 'ImageLabel'].includes(selected.className)) {
        return findParentOf(state.tree, selected.id) || state.tree;
      }
      return selected;
    }
  }

  // Helper: Hex to RGB object
  function hexToRgb(hex) {
    const clean = (hex || '#000000').replace('#', '');
    const num = parseInt(clean, 16);
    return {
      r: (num >> 16) & 255,
      g: (num >> 8) & 255,
      b: num & 255
    };
  }

  // Helper: RGB object to Hex
  function rgbToHex(r, g, b) {
    return '#' + [r, g, b].map(x => {
      const hex = Math.round(x).toString(16);
      return hex.length === 1 ? '0' + hex : hex;
    }).join('');
  }

  // Helper: Escape HTML
  function escapeHtml(str) {
    if (typeof str !== 'string') return String(str || '');
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // Get official Roblox Studio icon for class
  function getGuiClassIcon(className) {
    const c = className || 'Frame';
    return `<img class="roblox-class-icon" src="/RobloxCustom/instance/16x/100/${encodeURIComponent(c)}.png" width="16" height="16" alt="${escapeHtml(c)}" onerror="if(!this.dataset.fallback){this.dataset.fallback='1';this.src='/RobloxCustom/instance/16x/100/Instance.png';}">`;
  }

  // ========================================================
  // Canvas Resolution & UDim2 Geometry Calculation
  // ========================================================

  function getViewportDimensions() {
    const preset = VIEWPORT_PRESETS[state.selectedDeviceId] || VIEWPORT_PRESETS.mobile_iphone_h;
    return { width: preset.width, height: preset.height, name: preset.name, type: preset.type };
  }

  function computeElementGeometry(elem, parentWidth, parentHeight) {
    const p = elem.properties || {};
    const pos = p.Position || { X: { Scale: 0, Offset: 0 }, Y: { Scale: 0, Offset: 0 } };
    const sz = p.Size || { X: { Scale: 0, Offset: 100 }, Y: { Scale: 0, Offset: 50 } };
    const ap = p.AnchorPoint || { X: 0, Y: 0 };

    const width = Math.max(0, parentWidth * (pos ? sz.X.Scale : 0) + sz.X.Offset);
    const height = Math.max(0, parentHeight * (pos ? sz.Y.Scale : 0) + sz.Y.Offset);
    const left = parentWidth * pos.X.Scale + pos.X.Offset - (width * (ap.X || 0));
    const top = parentHeight * pos.Y.Scale + pos.Y.Offset - (height * (ap.Y || 0));

    return { left, top, width, height };
  }

  // Find modifiers like UICorner or UIStroke in element children
  function getElementModifiers(elem) {
    let corner = null;
    let stroke = null;
    if (elem.children) {
      for (const child of elem.children) {
        if (child.className === 'UICorner' && !corner) corner = child;
        if (child.className === 'UIStroke' && !stroke) stroke = child;
      }
    }
    return { corner, stroke };
  }

  // ========================================================
  // Camera Pan & Viewport Transformation
  // ========================================================

  function updateCameraTransform() {
    const wrapper = document.getElementById('gui-canvas-viewport-wrapper');
    if (wrapper) {
      wrapper.style.transform = `translate(${state.camera.x}px, ${state.camera.y}px) scale(${state.zoomScale})`;
    }
  }

  function resetCamera() {
    state.camera = { x: 0, y: 0 };
    state.autoFitZoom = true;
    const dev = VIEWPORT_PRESETS[state.selectedDeviceId];
    if (dev) state.zoomScale = dev.defaultScale;
    renderVirtualCanvas();
    if (typeof showToast === 'function') showToast('Camera view reset to center');
  }

  function setTool(toolName) {
    state.tool = toolName;
    const btnSelect = document.getElementById('btn-gui-tool-select');
    const btnPan = document.getElementById('btn-gui-tool-pan');
    const viewportArea = document.querySelector('.gui-canvas-viewport-area');
    if (btnSelect) btnSelect.classList.toggle('active', toolName === 'select');
    if (btnPan) btnPan.classList.toggle('active', toolName === 'hand');
    if (viewportArea) {
      viewportArea.classList.toggle('tool-hand', toolName === 'hand');
    }
    if (typeof showToast === 'function') {
      showToast(toolName === 'hand' ? 'Hand Tool: Drag to move camera' : 'Select Tool: Select & Move elements');
    }
  }

  function startPanning(e) {
    state.isPanning = true;
    state.panStart = {
      mouseX: e.clientX,
      mouseY: e.clientY,
      camX: state.camera.x,
      camY: state.camera.y,
      targetId: e.target ? e.target.id : ''
    };
    const viewportArea = document.querySelector('.gui-canvas-viewport-area');
    if (viewportArea) viewportArea.classList.add('is-panning');
    window.addEventListener('mousemove', onPanMouseMove);
    window.addEventListener('mouseup', onPanMouseUp);
  }

  function onPanMouseMove(e) {
    if (!state.isPanning) return;
    const dx = e.clientX - state.panStart.mouseX;
    const dy = e.clientY - state.panStart.mouseY;
    state.camera.x = state.panStart.camX + dx;
    state.camera.y = state.panStart.camY + dy;
    updateCameraTransform();
  }

  function onPanMouseUp(e) {
    if (!state.isPanning) return;
    state.isPanning = false;
    const viewportArea = document.querySelector('.gui-canvas-viewport-area');
    if (viewportArea) viewportArea.classList.remove('is-panning');
    window.removeEventListener('mousemove', onPanMouseMove);
    window.removeEventListener('mouseup', onPanMouseUp);

    // If mouse was simply clicked on empty canvas screen without panning, select root ScreenGui
    if (e) {
      const dist = Math.hypot(e.clientX - state.panStart.mouseX, e.clientY - state.panStart.mouseY);
      if (dist < 5 && (state.panStart.targetId === 'gui-sandbox-screen' || state.panStart.targetId === 'gui-canvas-viewport-wrapper')) {
        selectElement('inst_root_screen_gui');
      }
    }
  }

  function setupCanvasViewportListeners() {
    const viewportArea = document.querySelector('.gui-canvas-viewport-area');
    if (!viewportArea || viewportArea.dataset.panSetup) return;
    viewportArea.dataset.panSetup = 'true';

    // Prevent default context menu on empty viewport canvas background
    viewportArea.addEventListener('contextmenu', (e) => {
      if (!e.target.closest('.gui-canvas-elem') && !e.target.closest('.gui-tree-row')) {
        e.preventDefault();
        hideContextMenu();
      }
    });

    document.addEventListener('click', (e) => {
      if (!e.target.closest('#gui-studio-context-menu')) {
        hideContextMenu();
      }
    });

    document.addEventListener('contextmenu', (e) => {
      if (!e.target.closest('.gui-canvas-elem') && !e.target.closest('.gui-tree-row') && !e.target.closest('#gui-studio-context-menu')) {
        hideContextMenu();
      }
    });

    viewportArea.addEventListener('mousedown', (e) => {
      hideContextMenu();

      // Middle click (button 1) always moves camera
      if (e.button === 1) {
        e.preventDefault();
        startPanning(e);
        return;
      }

      // Left click with hand tool or spacebar held
      if (e.button === 0 && (state.tool === 'hand' || state.isSpacePressed)) {
        e.preventDefault();
        startPanning(e);
        return;
      }

      // Right click (button 2) on empty canvas background moves camera
      if (e.button === 2 && (e.target === viewportArea || e.target.id === 'gui-canvas-viewport-wrapper' || e.target.id === 'gui-sandbox-screen')) {
        startPanning(e);
        return;
      }

      // Left click on background outside of canvas elements
      if (e.button === 0 && (e.target === viewportArea || e.target.id === 'gui-canvas-viewport-wrapper' || e.target.id === 'gui-sandbox-screen')) {
        startPanning(e);
      }
    });

    // Mouse wheel zoom (Ctrl + wheel) and pan (wheel / Shift + wheel)
    viewportArea.addEventListener('wheel', (e) => {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault();
        const zoomDelta = e.deltaY < 0 ? 0.08 : -0.08;
        state.zoomScale = Math.max(0.15, Math.min(2.5, state.zoomScale + zoomDelta));
        state.autoFitZoom = false;
        renderVirtualCanvas();
      } else {
        e.preventDefault();
        if (e.shiftKey) {
          state.camera.x -= e.deltaY * 0.8;
        } else {
          state.camera.y -= e.deltaY * 0.8;
          state.camera.x -= e.deltaX * 0.8;
        }
        updateCameraTransform();
      }
    }, { passive: false });
  }

  // ========================================================
  // Undo & Redo History System
  // ========================================================

  function saveHistoryState(actionName = 'Edit') {
    const snapshot = {
      tree: JSON.parse(JSON.stringify(state.tree)),
      selectedElementId: state.selectedElementId,
      action: actionName
    };
    state.undoStack.push(snapshot);
    if (state.undoStack.length > state.maxHistory) {
      state.undoStack.shift();
    }
    state.redoStack = [];
    updateUndoRedoUI();
  }

  function undo() {
    if (state.undoStack.length === 0) {
      if (typeof showToast === 'function') showToast('Nothing to undo');
      return;
    }
    const currentSnapshot = {
      tree: JSON.parse(JSON.stringify(state.tree)),
      selectedElementId: state.selectedElementId,
      action: 'State'
    };
    state.redoStack.push(currentSnapshot);
    const prevState = state.undoStack.pop();
    state.tree = prevState.tree;
    state.selectedElementId = prevState.selectedElementId;
    renderExplorerTree();
    renderVirtualCanvas();
    renderPropertiesPanel();
    updateLocalScriptCode();
    updateUndoRedoUI();
    if (typeof showToast === 'function') {
      showToast(`Undo: ${prevState.action || 'Action'}`);
    }
  }

  function redo() {
    if (state.redoStack.length === 0) {
      if (typeof showToast === 'function') showToast('Nothing to redo');
      return;
    }
    const currentSnapshot = {
      tree: JSON.parse(JSON.stringify(state.tree)),
      selectedElementId: state.selectedElementId,
      action: 'State'
    };
    state.undoStack.push(currentSnapshot);
    const nextState = state.redoStack.pop();
    state.tree = nextState.tree;
    state.selectedElementId = nextState.selectedElementId;
    renderExplorerTree();
    renderVirtualCanvas();
    renderPropertiesPanel();
    updateLocalScriptCode();
    updateUndoRedoUI();
    if (typeof showToast === 'function') {
      showToast(`Redo: ${nextState.action || 'Action'}`);
    }
  }

  function updateUndoRedoUI() {
    const btnUndo = document.getElementById('btn-gui-undo');
    const btnRedo = document.getElementById('btn-gui-redo');
    if (btnUndo) {
      btnUndo.disabled = state.undoStack.length === 0;
      btnUndo.classList.toggle('disabled', state.undoStack.length === 0);
    }
    if (btnRedo) {
      btnRedo.disabled = state.redoStack.length === 0;
      btnRedo.classList.toggle('disabled', state.redoStack.length === 0);
    }
    const btnPaste = document.getElementById('btn-gui-paste');
    const btnExpPaste = document.getElementById('btn-gui-exp-paste');
    const canPaste = !!state.clipboard;
    if (btnPaste) {
      btnPaste.disabled = !canPaste;
      btnPaste.classList.toggle('disabled', !canPaste);
    }
    if (btnExpPaste) {
      btnExpPaste.disabled = !canPaste;
      btnExpPaste.classList.toggle('disabled', !canPaste);
    }
  }

  // ========================================================
  // Copy & Paste Clipboard System
  // ========================================================

  function copySelectedElement() {
    if (!state.selectedElementId || state.selectedElementId === 'inst_root_screen_gui') {
      if (typeof showToast === 'function') showToast('Select an element to copy (cannot copy ScreenGui)');
      return;
    }
    const elem = findElementById(state.tree, state.selectedElementId);
    if (!elem) return;
    state.clipboard = JSON.parse(JSON.stringify(elem));
    updateUndoRedoUI();
    if (typeof showToast === 'function') {
      showToast(`Copied "${elem.name}" to clipboard`);
    }
  }

  function pasteElement() {
    if (!state.clipboard) {
      if (typeof showToast === 'function') showToast('Clipboard is empty');
      return;
    }
    saveHistoryState(`Paste ${state.clipboard.name}`);

    const targetParent = resolveTargetParent(state.clipboard.className);

    const cloned = JSON.parse(JSON.stringify(state.clipboard));
    reassignIds(cloned);
    cloned.name = `${cloned.name}_Copy`;

    if (cloned.properties && cloned.properties.Position) {
      cloned.properties.Position.X.Offset = (cloned.properties.Position.X.Offset || 0) + 15;
      cloned.properties.Position.Y.Offset = (cloned.properties.Position.Y.Offset || 0) + 15;
    }

    if (!targetParent.children) targetParent.children = [];
    targetParent.children.push(cloned);

    selectElement(cloned.id);
    updateLocalScriptCode();
    if (typeof showToast === 'function') {
      showToast(`Pasted "${cloned.name}" into "${targetParent.name}"`);
    }
  }

  function reassignIds(node) {
    state.idCounter++;
    node.id = `inst_${state.idCounter}`;
    if (node.children) {
      node.children.forEach(c => reassignIds(c));
    }
  }

  function nudgeSelectedElement(dx, dy) {
    if (!state.selectedElementId || state.selectedElementId === 'inst_root_screen_gui') return;
    const elem = findElementById(state.tree, state.selectedElementId);
    if (!elem || !elem.properties || !elem.properties.Position) return;

    saveHistoryState(`Nudge ${elem.name}`);
    elem.properties.Position.X.Offset = (elem.properties.Position.X.Offset || 0) + dx;
    elem.properties.Position.Y.Offset = (elem.properties.Position.Y.Offset || 0) + dy;
    renderVirtualCanvas();
    renderPropertiesPanel();
    updateLocalScriptCode();
  }

  // ========================================================
  // Global Keyboard Shortcuts (Hotkeys)
  // ========================================================

  let shortcutsInitialized = false;

  function setupKeyboardShortcuts() {
    if (shortcutsInitialized) return;
    shortcutsInitialized = true;

    window.addEventListener('keydown', (e) => {
      const guiView = document.getElementById('view-guisandbox');
      if (!guiView || !guiView.classList.contains('active')) return;

      const tag = document.activeElement ? document.activeElement.tagName.toLowerCase() : '';
      const isInput = tag === 'input' || tag === 'textarea' || tag === 'select' || (document.activeElement && document.activeElement.isContentEditable);

      // Space for camera pan cursor
      if (e.code === 'Space' && !isInput && !state.isSpacePressed) {
        e.preventDefault();
        state.isSpacePressed = true;
        const viewportArea = document.querySelector('.gui-canvas-viewport-area');
        if (viewportArea) viewportArea.classList.add('space-grab');
        return;
      }

      if (isInput) return;

      // Escape key cancels inline editing or closes context menu
      if (e.key === 'Escape') {
        hideContextMenu();
        if (activeInlineEditor) {
          activeInlineEditor.cancel();
          return;
        }
      }

      // Enter or F2 starts inline text editing for TextLabel, TextButton, TextBox
      if ((e.key === 'Enter' || e.key === 'F2') && !e.ctrlKey && !e.metaKey && !e.altKey) {
        const elem = findElementById(state.tree, state.selectedElementId);
        if (elem && ['TextLabel', 'TextButton', 'TextBox'].includes(elem.className)) {
          e.preventDefault();
          startInlineTextEditing(elem);
          return;
        }
      }

      const isCtrlOrCmd = e.ctrlKey || e.metaKey;

      // Undo: Ctrl+Z (without Shift)
      if (isCtrlOrCmd && e.key.toLowerCase() === 'z' && !e.shiftKey) {
        e.preventDefault();
        undo();
        return;
      }

      // Redo: Ctrl+Y or Ctrl+Shift+Z
      if ((isCtrlOrCmd && e.key.toLowerCase() === 'y') || (isCtrlOrCmd && e.shiftKey && e.key.toLowerCase() === 'z')) {
        e.preventDefault();
        redo();
        return;
      }

      // Copy: Ctrl+C
      if (isCtrlOrCmd && e.key.toLowerCase() === 'c') {
        e.preventDefault();
        copySelectedElement();
        return;
      }

      // Paste: Ctrl+V
      if (isCtrlOrCmd && e.key.toLowerCase() === 'v') {
        e.preventDefault();
        pasteElement();
        return;
      }

      // Duplicate: Ctrl+D
      if (isCtrlOrCmd && e.key.toLowerCase() === 'd') {
        e.preventDefault();
        duplicateSelectedElement();
        return;
      }

      // Delete: Delete or Backspace
      if (e.key === 'Delete' || e.key === 'Backspace') {
        e.preventDefault();
        if (state.selectedElementId && state.selectedElementId !== 'inst_root_screen_gui') {
          deleteElement(state.selectedElementId);
        }
        return;
      }

      // Arrow Keys Nudge
      if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
        e.preventDefault();
        const step = e.shiftKey ? 10 : 1;
        let dx = 0, dy = 0;
        if (e.key === 'ArrowUp') dy = -step;
        if (e.key === 'ArrowDown') dy = step;
        if (e.key === 'ArrowLeft') dx = -step;
        if (e.key === 'ArrowRight') dx = step;
        nudgeSelectedElement(dx, dy);
        return;
      }

      // Tool shortcuts: V for Select, H for Hand
      if (e.key.toLowerCase() === 'v' && !isCtrlOrCmd) {
        setTool('select');
        return;
      }
      if (e.key.toLowerCase() === 'h' && !isCtrlOrCmd) {
        setTool('hand');
        return;
      }

      // Zoom shortcuts: Ctrl+0 (Fit), Ctrl+= (Zoom In), Ctrl+- (Zoom Out)
      if (isCtrlOrCmd && (e.key === '0' || e.key === 'Numpad0')) {
        e.preventDefault();
        resetCamera();
        return;
      }
      if (isCtrlOrCmd && (e.key === '=' || e.key === '+' || e.key === 'NumpadAdd')) {
        e.preventDefault();
        state.autoFitZoom = false;
        state.zoomScale = Math.min(2.5, state.zoomScale + 0.1);
        renderVirtualCanvas();
        return;
      }
      if (isCtrlOrCmd && (e.key === '-' || e.key === '_' || e.key === 'NumpadSubtract')) {
        e.preventDefault();
        state.autoFitZoom = false;
        state.zoomScale = Math.max(0.2, state.zoomScale - 0.1);
        renderVirtualCanvas();
        return;
      }
    });

    window.addEventListener('keyup', (e) => {
      if (e.code === 'Space') {
        state.isSpacePressed = false;
        const viewportArea = document.querySelector('.gui-canvas-viewport-area');
        if (viewportArea) viewportArea.classList.remove('space-grab');
      }
    });
  }

  // ========================================================
  // Canvas Rendering (Virtual Screen Engine)
  // ========================================================

  function renderVirtualCanvas() {
    const screen = document.getElementById('gui-sandbox-screen');
    const viewportInfo = document.getElementById('gui-viewport-dimensions-badge');
    const zoomBadge = document.getElementById('gui-canvas-zoom-badge');
    if (!screen) return;

    const device = getViewportDimensions();
    screen.style.width = `${device.width}px`;
    screen.style.height = `${device.height}px`;
    screen.classList.toggle('mode-play', state.mode === 'play');

    // Apply viewport camera pan and zoom scale transform
    updateCameraTransform();

    if (viewportInfo) {
      viewportInfo.textContent = `${device.width} × ${device.height} px`;
    }
    if (zoomBadge) {
      zoomBadge.textContent = `${Math.round(state.zoomScale * 100)}%`;
    }

    screen.innerHTML = '';

    // Render tree recursively inside ScreenGui
    const root = state.tree;
    if (root.children) {
      root.children.forEach(child => {
        const dom = renderCanvasElement(child, device.width, device.height, 0, 0);
        if (dom) screen.appendChild(dom);
      });
    }

    // If an element is selected and mode is 'edit', render bounding box and handles
    if (state.mode === 'edit' && state.selectedElementId && state.selectedElementId !== 'inst_root_screen_gui') {
      renderSelectionOverlay(screen);
    }
  }

  function renderCanvasElement(elem, parentWidth, parentHeight, parentAbsLeft, parentAbsTop) {
    // Non-visual instances like UICorner, UIStroke, LocalScript are applied to parent
    if (['UICorner', 'UIStroke', 'LocalScript', 'UIGradient', 'UIPadding'].includes(elem.className)) {
      return null;
    }

    const p = elem.properties || {};
    if (p.Visible === false) return null;

    const geom = computeElementGeometry(elem, parentWidth, parentHeight);
    elem._computed = {
      left: geom.left,
      top: geom.top,
      width: geom.width,
      height: geom.height,
      absLeft: parentAbsLeft + geom.left,
      absTop: parentAbsTop + geom.top,
      parentWidth: parentWidth,
      parentHeight: parentHeight
    };

    const el = document.createElement('div');
    el.id = `canvas_node_${elem.id}`;
    el.className = `gui-canvas-elem gui-elem-${elem.className.toLowerCase()}`;
    el.dataset.elementId = elem.id;

    // Geometry
    el.style.left = `${geom.left}px`;
    el.style.top = `${geom.top}px`;
    el.style.width = `${geom.width}px`;
    el.style.height = `${geom.height}px`;
    el.style.zIndex = p.ZIndex || 1;

    // Appearance
    const bgTrans = p.BackgroundTransparency !== undefined ? p.BackgroundTransparency : 0;
    const bgColor = p.BackgroundColor3 || '#0b0e14';
    el.style.backgroundColor = bgTrans >= 1 ? 'transparent' : hexToRgba(bgColor, 1 - bgTrans);

    // Border
    if (p.BorderSizePixel && p.BorderSizePixel > 0) {
      el.style.border = `${p.BorderSizePixel}px solid ${p.BorderColor3 || '#30363d'}`;
    } else {
      el.style.border = 'none';
    }

    // Modifiers (UICorner, UIStroke)
    const { corner, stroke } = getElementModifiers(elem);
    if (corner) {
      const cp = corner.properties || {};
      const cRadius = (geom.height * (cp.CornerRadius?.Scale || 0)) + (cp.CornerRadius?.Offset || 0);
      el.style.borderRadius = `${Math.max(0, cRadius)}px`;
    }

    if (stroke) {
      const sp = stroke.properties || {};
      const sThick = sp.Thickness || 1;
      const sColor = sp.Color || '#10b981';
      const sTrans = sp.Transparency || 0;
      el.style.outline = `${sThick}px solid ${hexToRgba(sColor, 1 - sTrans)}`;
      el.style.outlineOffset = `-${sThick}px`;
    }

    if (p.ClipsDescendants) {
      el.style.overflow = 'hidden';
    }

    // Specific Class Renders
    if (elem.className === 'TextLabel' || elem.className === 'TextButton') {
      el.textContent = p.Text || '';
      el.style.color = p.TextColor3 || '#ffffff';
      el.style.fontSize = `${p.TextSize || 13}px`;
      el.style.fontFamily = getRobloxFontFamily(p.Font);
      el.style.display = 'flex';
      el.style.alignItems = getFlexAlignment(p.TextYAlignment || 'Center');
      el.style.justifyContent = getFlexAlignment(p.TextXAlignment || 'Center');
      el.style.textAlign = (p.TextXAlignment || 'Center').toLowerCase();
      el.style.whiteSpace = p.TextWrapped ? 'normal' : 'nowrap';
      el.style.wordBreak = p.TextWrapped ? 'break-word' : 'normal';

      if (elem.className === 'TextButton' && state.mode === 'play') {
        el.style.cursor = 'pointer';
        el.addEventListener('click', (e) => {
          e.stopPropagation();
          handlePlayButtonClick(elem);
        });
      }
    } else if (elem.className === 'TextBox') {
      const input = document.createElement('input');
      input.type = 'text';
      input.className = 'gui-canvas-textbox-inner';
      input.value = p.Text || '';
      input.placeholder = p.PlaceholderText || '';
      input.style.color = p.TextColor3 || '#ffffff';
      input.style.fontSize = `${p.TextSize || 13}px`;
      input.style.fontFamily = getRobloxFontFamily(p.Font);
      input.style.textAlign = (p.TextXAlignment || 'Left').toLowerCase();
      input.disabled = state.mode !== 'play';
      if (state.mode === 'play') {
        input.addEventListener('input', () => { p.Text = input.value; updateLocalScriptCode(); });
      }
      el.appendChild(input);
    } else if (elem.className === 'ImageLabel' || elem.className === 'ImageButton') {
      if (p.Image) {
        el.style.backgroundImage = `url('${p.Image}')`;
        el.style.backgroundSize = p.ScaleType === 'Fit' ? 'contain' : 'cover';
        el.style.backgroundPosition = 'center';
        el.style.backgroundRepeat = 'no-repeat';
      }
    }

    // Selection Click in Edit Mode
    if (state.mode === 'edit') {
      el.addEventListener('mousedown', (e) => {
        // Hand tool, spacebar held, or middle click delegates to camera pan
        if (state.tool === 'hand' || state.isSpacePressed || e.button === 1) {
          return;
        }
        if (e.button === 0) {
          e.stopPropagation();
          selectElement(elem.id);
          startDragging(e, elem);
        }
      });

      // Right-click context menu (Edit Text, duplicate, delete, etc.)
      el.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        e.stopPropagation();
        showContextMenu(e, elem);
      });

      // Double-click to inline edit text on TextLabel, TextButton, TextBox
      if (['TextLabel', 'TextButton', 'TextBox'].includes(elem.className)) {
        el.addEventListener('dblclick', (e) => {
          e.stopPropagation();
          startInlineTextEditing(elem);
        });
      }
    }

    // Render Children
    if (elem.children) {
      elem.children.forEach(child => {
        const childDom = renderCanvasElement(child, geom.width, geom.height, elem._computed.absLeft, elem._computed.absTop);
        if (childDom) el.appendChild(childDom);
      });
    }

    return el;
  }

  function hexToRgba(hex, alpha = 1) {
    const { r, g, b } = hexToRgb(hex);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }

  function getRobloxFontFamily(fontName) {
    switch (fontName) {
      case 'GothamBold':
      case 'GothamBlack':
        return "'Montserrat', 'Inter', -apple-system, sans-serif";
      case 'Gotham':
      case 'GothamMedium':
        return "'Inter', -apple-system, sans-serif";
      case 'BuilderSans':
      case 'BuilderSansBold':
        return "'Segoe UI', 'Inter', sans-serif";
      case 'Code':
        return "'JetBrains Mono', monospace";
      default:
        return "'Segoe UI', -apple-system, sans-serif";
    }
  }

  function getFlexAlignment(align) {
    switch (align) {
      case 'Left':
      case 'Top':
        return 'flex-start';
      case 'Right':
      case 'Bottom':
        return 'flex-end';
      case 'Center':
      default:
        return 'center';
    }
  }

  function handlePlayButtonClick(elem) {
    if (typeof showToast === 'function') {
      showToast(`[Sandbox Action] Button "${elem.name}" clicked!`);
    }
    // Check if element has a LocalScript child
    if (elem.children) {
      const scriptChild = elem.children.find(c => c.className === 'LocalScript');
      if (scriptChild && scriptChild.properties && scriptChild.properties.ScriptCode) {
        const code = scriptChild.properties.ScriptCode;
        if (typeof showToast === 'function') {
          showToast(`Executed Script: ${code}`);
        }
      }
    }
  }

  // ========================================================
  // Inline Text Editing Engine (Canvas & Explorer Direct Edit)
  // ========================================================

  let activeInlineEditor = null;

  function startInlineTextEditing(elem) {
    if (!elem) elem = findElementById(state.tree, state.selectedElementId);
    if (!elem || !['TextLabel', 'TextButton', 'TextBox'].includes(elem.className)) return;

    if (activeInlineEditor) {
      activeInlineEditor.commit();
    }

    selectElement(elem.id);

    const screen = document.getElementById('gui-sandbox-screen');
    const domNode = document.getElementById(`canvas_node_${elem.id}`);
    if (!screen || !domNode || !elem._computed) return;

    const p = elem.properties || {};
    const currentText = p.Text !== undefined ? p.Text : '';

    const editorWrap = document.createElement('div');
    editorWrap.className = 'gui-inline-text-editor-wrap';
    editorWrap.style.left = `${elem._computed.absLeft}px`;
    editorWrap.style.top = `${elem._computed.absTop}px`;
    editorWrap.style.width = `${elem._computed.width}px`;
    editorWrap.style.height = `${elem._computed.height}px`;

    const isMultiline = !!p.TextWrapped;
    const input = document.createElement(isMultiline ? 'textarea' : 'input');
    if (!isMultiline) input.type = 'text';
    input.className = 'gui-inline-text-input';
    input.value = currentText;

    input.style.color = p.TextColor3 || '#ffffff';
    input.style.fontSize = `${p.TextSize || 13}px`;
    input.style.fontFamily = getRobloxFontFamily(p.Font);
    input.style.textAlign = (p.TextXAlignment || 'Center').toLowerCase();
    input.style.lineHeight = isMultiline ? '1.4' : `${elem._computed.height}px`;
    if (isMultiline) {
      input.style.padding = '4px 6px';
      input.style.resize = 'none';
    }

    const { corner } = getElementModifiers(elem);
    if (corner) {
      const cp = corner.properties || {};
      const cRadius = (elem._computed.height * (cp.CornerRadius?.Scale || 0)) + (cp.CornerRadius?.Offset || 0);
      input.style.borderRadius = `${Math.max(0, cRadius)}px`;
    }

    domNode.style.visibility = 'hidden';

    const hint = document.createElement('div');
    hint.className = 'gui-inline-editor-hint';
    hint.innerHTML = '<span>Enter: <b>Apply</b></span> • <span>Esc: <b>Cancel</b></span>';
    editorWrap.appendChild(hint);
    editorWrap.appendChild(input);

    screen.appendChild(editorWrap);

    let finished = false;

    function commit() {
      if (finished) return;
      finished = true;
      const newText = input.value;
      if (editorWrap.parentNode) editorWrap.parentNode.removeChild(editorWrap);
      domNode.style.visibility = 'visible';
      activeInlineEditor = null;

      if (newText !== currentText) {
        saveHistoryState(`Edit Text of ${elem.name}`);
        p.Text = newText;
        renderVirtualCanvas();
        renderPropertiesPanel();
        updateLocalScriptCode();
        if (typeof showToast === 'function') {
          showToast(`Updated text to: "${newText}"`);
        }
      }
    }

    function cancel() {
      if (finished) return;
      finished = true;
      if (editorWrap.parentNode) editorWrap.parentNode.removeChild(editorWrap);
      domNode.style.visibility = 'visible';
      activeInlineEditor = null;
    }

    input.addEventListener('keydown', (e) => {
      e.stopPropagation();
      if (e.key === 'Enter' && (!isMultiline || !e.shiftKey)) {
        e.preventDefault();
        commit();
      } else if (e.key === 'Escape') {
        e.preventDefault();
        cancel();
      }
    });

    input.addEventListener('blur', () => {
      commit();
    });

    activeInlineEditor = { commit, cancel };

    setTimeout(() => {
      input.focus();
      input.select();
    }, 20);
  }

  // ========================================================
  // Roblox Studio Context Menu Engine
  // ========================================================

  function showContextMenu(e, elem) {
    if (e.preventDefault) e.preventDefault();
    if (e.stopPropagation) e.stopPropagation();

    hideContextMenu();

    if (elem) {
      selectElement(elem.id);
    }

    const menu = document.createElement('div');
    menu.id = 'gui-studio-context-menu';
    menu.className = 'gui-context-menu';

    const isTextElem = elem && ['TextLabel', 'TextButton', 'TextBox'].includes(elem.className);
    const items = [];

    if (isTextElem) {
      items.push({
        label: 'Edit Text',
        icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"></path><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path></svg>',
        shortcut: 'Enter',
        action: () => startInlineTextEditing(elem)
      });
      items.push({
        label: 'Quick Edit Text...',
        icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><line x1="9" y1="9" x2="15" y2="9"></line><line x1="12" y1="9" x2="12" y2="15"></line></svg>',
        action: () => {
          const val = prompt(`Edit Text for ${elem.name}:`, elem.properties.Text || '');
          if (val !== null && val !== elem.properties.Text) {
            saveHistoryState(`Edit Text of ${elem.name}`);
            elem.properties.Text = val;
            renderVirtualCanvas();
            renderPropertiesPanel();
            updateLocalScriptCode();
          }
        }
      });
      items.push({ separator: true });
    }

    if (elem && elem.id !== 'inst_root_screen_gui') {
      items.push({
        label: 'Rename Element',
        icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path></svg>',
        shortcut: 'F2',
        action: () => {
          const newName = prompt(`Rename instance:`, elem.name);
          if (newName && newName.trim() && newName.trim() !== elem.name) {
            saveHistoryState(`Rename ${elem.name}`);
            elem.name = newName.trim();
            renderExplorerTree();
            renderPropertiesPanel();
            updateLocalScriptCode();
          }
        }
      });
      items.push({
        label: 'Duplicate',
        icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>',
        shortcut: 'Ctrl+D',
        action: () => duplicateSelectedElement()
      });
      items.push({
        label: 'Copy',
        icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>',
        shortcut: 'Ctrl+C',
        action: () => copySelectedElement()
      });
    }

    items.push({
      label: 'Paste',
      icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path><rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect></svg>',
      shortcut: 'Ctrl+V',
      disabled: !state.clipboard,
      action: () => pasteElement()
    });

    if (elem && elem.id !== 'inst_root_screen_gui') {
      items.push({ separator: true });
      items.push({
        label: 'Bring to Front',
        icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"></polyline></svg>',
        action: () => {
          saveHistoryState(`Bring ${elem.name} to Front`);
          elem.properties.ZIndex = (elem.properties.ZIndex || 1) + 1;
          renderVirtualCanvas();
          renderPropertiesPanel();
          updateLocalScriptCode();
        }
      });
      items.push({
        label: 'Send to Back',
        icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"></polyline></svg>',
        action: () => {
          saveHistoryState(`Send ${elem.name} to Back`);
          elem.properties.ZIndex = Math.max(1, (elem.properties.ZIndex || 1) - 1);
          renderVirtualCanvas();
          renderPropertiesPanel();
          updateLocalScriptCode();
        }
      });
      items.push({ separator: true });
      items.push({
        label: 'Delete',
        icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>',
        danger: true,
        shortcut: 'Del',
        action: () => deleteElement(elem.id)
      });
    }

    items.forEach(it => {
      if (it.separator) {
        const sep = document.createElement('div');
        sep.className = 'gui-context-separator';
        menu.appendChild(sep);
        return;
      }
      const row = document.createElement('button');
      row.className = `gui-context-item ${it.danger ? 'is-danger' : ''} ${it.disabled ? 'is-disabled' : ''}`;
      if (it.disabled) row.disabled = true;

      const left = document.createElement('div');
      left.style.display = 'flex';
      left.style.alignItems = 'center';
      left.style.gap = '8px';
      left.innerHTML = `${it.icon || ''}<span>${it.label}</span>`;

      row.appendChild(left);
      if (it.shortcut) {
        const kbd = document.createElement('span');
        kbd.className = 'gui-context-kbd';
        kbd.textContent = it.shortcut;
        row.appendChild(kbd);
      }

      row.addEventListener('click', (ev) => {
        ev.stopPropagation();
        hideContextMenu();
        if (it.action) it.action();
      });

      menu.appendChild(row);
    });

    document.body.appendChild(menu);

    const menuW = menu.offsetWidth || 180;
    const menuH = menu.offsetHeight || 220;
    let posX = e.clientX || 100;
    let posY = e.clientY || 100;
    if (posX + menuW > window.innerWidth) posX = window.innerWidth - menuW - 8;
    if (posY + menuH > window.innerHeight) posY = window.innerHeight - menuH - 8;
    menu.style.left = `${posX}px`;
    menu.style.top = `${posY}px`;
  }

  function hideContextMenu() {
    const existing = document.getElementById('gui-studio-context-menu');
    if (existing && existing.parentNode) {
      existing.parentNode.removeChild(existing);
    }
  }

  // ========================================================
  // Selection Bounding Box & 8-Handle Resizing Overlay
  // ========================================================

  function renderSelectionOverlay(screen) {
    const elem = findElementById(state.tree, state.selectedElementId);
    if (!elem || !elem._computed) return;

    const overlay = document.createElement('div');
    overlay.className = 'gui-selection-overlay';
    overlay.style.left = `${elem._computed.absLeft}px`;
    overlay.style.top = `${elem._computed.absTop}px`;
    overlay.style.width = `${elem._computed.width}px`;
    overlay.style.height = `${elem._computed.height}px`;

    // Tooltip indicator showing Position & Size
    const tag = document.createElement('div');
    tag.className = 'gui-selection-tag';
    const p = elem.properties || {};
    const posStr = `{${p.Position?.X.Scale || 0}, ${p.Position?.X.Offset || 0}}, {${p.Position?.Y.Scale || 0}, ${p.Position?.Y.Offset || 0}}`;
    const szStr = `${Math.round(elem._computed.width)} × ${Math.round(elem._computed.height)} px`;
    tag.innerHTML = `<span><b>${escapeHtml(elem.name)}</b></span> • <span>${szStr}</span>`;
    overlay.appendChild(tag);

    // 8 Resize Handles
    const handles = ['nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w'];
    handles.forEach(dir => {
      const h = document.createElement('div');
      h.className = `gui-resize-handle handle-${dir}`;
      h.dataset.handle = dir;
      h.addEventListener('mousedown', (e) => {
        if (state.tool === 'hand' || state.isSpacePressed || e.button === 1 || e.button === 2) {
          return;
        }
        if (e.button !== 0) return;
        e.stopPropagation();
        startResizing(e, elem, dir);
      });
      overlay.appendChild(h);
    });

    screen.appendChild(overlay);
  }

  // ========================================================
  // Drag & Resize Mouse Interactivity
  // ========================================================

  function startDragging(e, elem) {
    if (state.mode !== 'edit' || !elem || !elem._computed) return;
    saveHistoryState(`Move ${elem.name}`);
    state.isDragging = true;
    state.isResizing = false;
    state.dragStart = {
      mouseX: e.clientX,
      mouseY: e.clientY,
      elemLeft: elem._computed.left,
      elemTop: elem._computed.top,
      parentWidth: elem._computed.parentWidth,
      parentHeight: elem._computed.parentHeight,
      initialPos: JSON.parse(JSON.stringify(elem.properties.Position || { X: { Scale: 0, Offset: 0 }, Y: { Scale: 0, Offset: 0 } }))
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  }

  function startResizing(e, elem, handle) {
    if (state.mode !== 'edit' || !elem || !elem._computed) return;
    saveHistoryState(`Resize ${elem.name}`);
    state.isResizing = true;
    state.isDragging = false;
    state.resizeHandle = handle;
    state.dragStart = {
      mouseX: e.clientX,
      mouseY: e.clientY,
      elemLeft: elem._computed.left,
      elemTop: elem._computed.top,
      elemWidth: elem._computed.width,
      elemHeight: elem._computed.height,
      parentWidth: elem._computed.parentWidth,
      parentHeight: elem._computed.parentHeight,
      initialSize: JSON.parse(JSON.stringify(elem.properties.Size || { X: { Scale: 0, Offset: 100 }, Y: { Scale: 0, Offset: 50 } })),
      initialPos: JSON.parse(JSON.stringify(elem.properties.Position || { X: { Scale: 0, Offset: 0 }, Y: { Scale: 0, Offset: 0 } }))
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  }

  function onMouseMove(e) {
    const elem = findElementById(state.tree, state.selectedElementId);
    if (!elem) return;

    const scale = state.zoomScale || 1;
    const deltaX = (e.clientX - state.dragStart.mouseX) / scale;
    const deltaY = (e.clientY - state.dragStart.mouseY) / scale;

    const p = elem.properties;
    const pW = state.dragStart.parentWidth || 800;
    const pH = state.dragStart.parentHeight || 600;

    if (state.isDragging) {
      if (state.sizingMode === 'scale') {
        const deltaScaleX = deltaX / pW;
        const deltaScaleY = deltaY / pH;
        p.Position.X.Scale = Number((state.dragStart.initialPos.X.Scale + deltaScaleX).toFixed(3));
        p.Position.Y.Scale = Number((state.dragStart.initialPos.Y.Scale + deltaScaleY).toFixed(3));
      } else {
        p.Position.X.Offset = Math.round(state.dragStart.initialPos.X.Offset + deltaX);
        p.Position.Y.Offset = Math.round(state.dragStart.initialPos.Y.Offset + deltaY);
      }
      renderVirtualCanvas();
      renderPropertiesPanel();
      updateLocalScriptCode();
    } else if (state.isResizing) {
      const h = state.resizeHandle;
      let newW = state.dragStart.elemWidth;
      let newH = state.dragStart.elemHeight;
      let newLeftDelta = 0;
      let newTopDelta = 0;

      if (h.includes('e')) newW += deltaX;
      if (h.includes('s')) newH += deltaY;
      if (h.includes('w')) { newW -= deltaX; newLeftDelta = deltaX; }
      if (h.includes('n')) { newH -= deltaY; newTopDelta = deltaY; }

      newW = Math.max(10, Math.round(newW));
      newH = Math.max(10, Math.round(newH));

      if (state.sizingMode === 'scale') {
        p.Size.X.Scale = Number((newW / pW).toFixed(3));
        p.Size.X.Offset = 0;
        p.Size.Y.Scale = Number((newH / pH).toFixed(3));
        p.Size.Y.Offset = 0;
      } else {
        p.Size.X.Offset = newW;
        p.Size.Y.Offset = newH;
      }

      if (newLeftDelta !== 0 || newTopDelta !== 0) {
        p.Position.X.Offset = Math.round(state.dragStart.initialPos.X.Offset + newLeftDelta);
        p.Position.Y.Offset = Math.round(state.dragStart.initialPos.Y.Offset + newTopDelta);
      }

      renderVirtualCanvas();
      renderPropertiesPanel();
      updateLocalScriptCode();
    }
  }

  function onMouseUp() {
    state.isDragging = false;
    state.isResizing = false;
    window.removeEventListener('mousemove', onMouseMove);
    window.removeEventListener('mouseup', onMouseUp);
  }

  // ========================================================
  // Hierarchy Explorer Tree Rendering
  // ========================================================

  function renderExplorerTree() {
    const container = document.getElementById('gui-hierarchy-tree');
    if (!container) return;
    container.innerHTML = '';

    const rootItem = createTreeNode(state.tree, 0);
    container.appendChild(rootItem);
  }

  function createTreeNode(node, depth = 0) {
    const wrap = document.createElement('div');
    wrap.className = 'gui-tree-node-wrap';

    const row = document.createElement('div');
    row.className = `gui-tree-row ${state.selectedElementId === node.id ? 'selected' : ''}`;
    row.style.paddingLeft = `${depth * 14 + 8}px`;

    const iconSpan = document.createElement('span');
    iconSpan.className = 'gui-tree-icon';
    iconSpan.innerHTML = getGuiClassIcon(node.className);

    const nameSpan = document.createElement('span');
    nameSpan.className = 'gui-tree-name';
    nameSpan.textContent = node.name;

    const classSpan = document.createElement('span');
    classSpan.className = 'gui-tree-class';
    classSpan.textContent = node.className;

    row.appendChild(iconSpan);
    row.appendChild(nameSpan);
    row.appendChild(classSpan);

    // Actions on tree item hover (Delete, Add Child)
    if (node.id !== 'inst_root_screen_gui') {
      const delBtn = document.createElement('button');
      delBtn.className = 'gui-tree-action-del';
      delBtn.title = 'Delete element';
      delBtn.textContent = '✕';
      delBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        deleteElement(node.id);
      });
      row.appendChild(delBtn);
    }

    row.addEventListener('click', (e) => {
      e.stopPropagation();
      selectElement(node.id);
    });

    row.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      e.stopPropagation();
      showContextMenu(e, node);
    });

    if (['TextLabel', 'TextButton', 'TextBox'].includes(node.className)) {
      row.addEventListener('dblclick', (e) => {
        e.stopPropagation();
        startInlineTextEditing(node);
      });
    }

    wrap.appendChild(row);

    if (node.children && node.children.length > 0) {
      const childrenBox = document.createElement('div');
      childrenBox.className = 'gui-tree-children';
      node.children.forEach(child => {
        childrenBox.appendChild(createTreeNode(child, depth + 1));
      });
      wrap.appendChild(childrenBox);
    }

    return wrap;
  }

  function selectElement(id) {
    state.selectedElementId = id;
    renderExplorerTree();
    renderVirtualCanvas();
    renderPropertiesPanel();
  }

  // ========================================================
  // Add & Delete Elements
  // ========================================================

  function addElement(className) {
    saveHistoryState(`Add ${className}`);
    state.idCounter++;
    const newId = `inst_${state.idCounter}`;
    const targetParent = resolveTargetParent(className);

    let newElement = {
      id: newId,
      className: className,
      name: `${className}_${state.idCounter}`,
      properties: {},
      children: []
    };

    switch (className) {
      case 'Frame':
        newElement.properties = {
          Position: { X: { Scale: 0.5, Offset: 0 }, Y: { Scale: 0.5, Offset: 0 } },
          Size: { X: { Scale: 0, Offset: 220 }, Y: { Scale: 0, Offset: 130 } },
          AnchorPoint: { X: 0.5, Y: 0.5 },
          BackgroundColor3: '#131923',
          BackgroundTransparency: 0,
          BorderSizePixel: 0,
          BorderColor3: '#1e293b',
          ClipsDescendants: false,
          Visible: true,
          ZIndex: 1
        };
        break;
      case 'TextLabel':
        newElement.properties = {
          Position: { X: { Scale: 0.5, Offset: 0 }, Y: { Scale: 0.5, Offset: 0 } },
          Size: { X: { Scale: 0, Offset: 180 }, Y: { Scale: 0, Offset: 30 } },
          AnchorPoint: { X: 0.5, Y: 0.5 },
          BackgroundColor3: '#ffffff',
          BackgroundTransparency: 1,
          Text: 'New Label',
          TextColor3: '#f8fafc',
          TextSize: 13,
          Font: 'Gotham',
          TextXAlignment: 'Center',
          TextYAlignment: 'Center',
          Visible: true,
          ZIndex: 2
        };
        break;
      case 'TextButton':
        newElement.properties = {
          Position: { X: { Scale: 0.5, Offset: 0 }, Y: { Scale: 0.5, Offset: 0 } },
          Size: { X: { Scale: 0, Offset: 130 }, Y: { Scale: 0, Offset: 34 } },
          AnchorPoint: { X: 0.5, Y: 0.5 },
          BackgroundColor3: '#10b981',
          BackgroundTransparency: 0,
          Text: 'Button',
          TextColor3: '#ffffff',
          TextSize: 13,
          Font: 'GothamBold',
          TextXAlignment: 'Center',
          TextYAlignment: 'Center',
          Visible: true,
          ZIndex: 3
        };
        newElement.children.push({
          id: `inst_${state.idCounter}_c`,
          className: 'UICorner',
          name: 'Corner',
          properties: { CornerRadius: { Scale: 0, Offset: 6 } },
          children: []
        });
        break;
      case 'TextBox':
        newElement.properties = {
          Position: { X: { Scale: 0.5, Offset: 0 }, Y: { Scale: 0.5, Offset: 0 } },
          Size: { X: { Scale: 0, Offset: 180 }, Y: { Scale: 0, Offset: 32 } },
          AnchorPoint: { X: 0.5, Y: 0.5 },
          BackgroundColor3: '#0f131b',
          BackgroundTransparency: 0,
          Text: '',
          PlaceholderText: 'Enter text...',
          TextColor3: '#ffffff',
          TextSize: 12,
          Font: 'Gotham',
          TextXAlignment: 'Left',
          TextYAlignment: 'Center',
          Visible: true,
          ZIndex: 2
        };
        newElement.children.push({
          id: `inst_${state.idCounter}_c`,
          className: 'UICorner',
          name: 'Corner',
          properties: { CornerRadius: { Scale: 0, Offset: 6 } },
          children: []
        });
        break;
      case 'ImageLabel':
        newElement.properties = {
          Position: { X: { Scale: 0.5, Offset: 0 }, Y: { Scale: 0.5, Offset: 0 } },
          Size: { X: { Scale: 0, Offset: 80 }, Y: { Scale: 0, Offset: 80 } },
          AnchorPoint: { X: 0.5, Y: 0.5 },
          BackgroundColor3: '#ffffff',
          BackgroundTransparency: 1,
          Image: 'rbxassetid://10709818534',
          Visible: true,
          ZIndex: 2
        };
        break;
      case 'ScrollingFrame':
        newElement.properties = {
          Position: { X: { Scale: 0.5, Offset: 0 }, Y: { Scale: 0.5, Offset: 0 } },
          Size: { X: { Scale: 0, Offset: 240 }, Y: { Scale: 0, Offset: 160 } },
          AnchorPoint: { X: 0.5, Y: 0.5 },
          BackgroundColor3: '#0f131b',
          BackgroundTransparency: 0,
          BorderSizePixel: 0,
          ScrollBarThickness: 6,
          Visible: true,
          ZIndex: 1
        };
        break;
      case 'UICorner':
        newElement.properties = {
          CornerRadius: { Scale: 0, Offset: 8 }
        };
        break;
      case 'UIStroke':
        newElement.properties = {
          Color: '#10b981',
          Thickness: 1.5,
          Transparency: 0
        };
        break;
      case 'LocalScript':
        newElement.properties = {
          ScriptCode: "print('Script initialized on: ' .. script.Parent.Name)"
        };
        break;
      default:
        break;
    }

    if (!targetParent.children) targetParent.children = [];
    targetParent.children.push(newElement);

    selectElement(newId);
    if (typeof showToast === 'function') {
      showToast(`Added ${newElement.name} to ${targetParent.name}`);
    }
    updateLocalScriptCode();
  }

  function deleteElement(id) {
    if (id === 'inst_root_screen_gui') return;
    saveHistoryState('Delete Element');
    const parent = findParentOf(state.tree, id);
    if (parent && parent.children) {
      parent.children = parent.children.filter(c => c.id !== id);
      selectElement(parent.id);
      if (typeof showToast === 'function') {
        showToast('Deleted element');
      }
      updateLocalScriptCode();
    }
  }

  function duplicateSelectedElement() {
    if (state.selectedElementId === 'inst_root_screen_gui') return;
    saveHistoryState('Duplicate Element');
    const elem = findElementById(state.tree, state.selectedElementId);
    const parent = findParentOf(state.tree, state.selectedElementId);
    if (!elem || !parent) return;

    state.idCounter++;
    const cloned = JSON.parse(JSON.stringify(elem));
    cloned.id = `inst_${state.idCounter}`;
    cloned.name = `${elem.name}_Copy`;
    if (cloned.properties && cloned.properties.Position) {
      cloned.properties.Position.X.Offset += 15;
      cloned.properties.Position.Y.Offset += 15;
    }

    parent.children.push(cloned);
    selectElement(cloned.id);
    if (typeof showToast === 'function') {
      showToast(`Duplicated ${elem.name}`);
    }
    updateLocalScriptCode();
  }

  // ========================================================
  // Properties Inspector Panel Rendering
  // ========================================================

  function renderPropertiesPanel() {
    const container = document.getElementById('gui-props-container');
    const headerTitle = document.getElementById('gui-props-header-name');
    const headerClass = document.getElementById('gui-props-header-class');
    const headerIcon = document.getElementById('gui-props-header-icon');
    if (!container) return;

    const elem = findElementById(state.tree, state.selectedElementId);
    if (!elem) {
      container.innerHTML = '<div class="empty-hint" style="padding: 24px; text-align:center;">Select an element to inspect properties</div>';
      return;
    }

    if (headerTitle) headerTitle.textContent = elem.name;
    if (headerClass) headerClass.textContent = elem.className;
    if (headerIcon) headerIcon.innerHTML = getGuiClassIcon(elem.className);

    container.innerHTML = '';

    const p = elem.properties || {};

    // Group 1: Identity
    const identityProps = [
      { label: 'Name', type: 'text', value: elem.name, onChange: v => { elem.name = v; renderExplorerTree(); updateLocalScriptCode(); } }
    ];

    if (elem.id !== 'inst_root_screen_gui') {
      const currentParent = findParentOf(state.tree, elem.id);
      const containers = collectContainers(state.tree, elem.id);
      identityProps.push({
        label: 'Parent',
        type: 'select',
        value: currentParent ? currentParent.id : 'inst_root_screen_gui',
        options: containers.map(c => c.id),
        optionLabels: containers.map(c => `${c.name} (${c.className})`),
        onChange: newParentId => reparentElement(elem.id, newParentId)
      });
      identityProps.push(
        { label: 'Visible', type: 'boolean', value: p.Visible !== false, onChange: v => { p.Visible = v; renderVirtualCanvas(); updateLocalScriptCode(); } },
        { label: 'ZIndex', type: 'number', value: p.ZIndex || 1, onChange: v => { p.ZIndex = Number(v) || 1; renderVirtualCanvas(); updateLocalScriptCode(); } }
      );
    } else {
      identityProps.push(
        { label: 'ResetOnSpawn', type: 'boolean', value: p.ResetOnSpawn !== false, onChange: v => { p.ResetOnSpawn = v; updateLocalScriptCode(); } },
        { label: 'DisplayOrder', type: 'number', value: p.DisplayOrder || 0, onChange: v => { p.DisplayOrder = Number(v) || 0; updateLocalScriptCode(); } }
      );
    }

    container.appendChild(createPropertyGroup('IDENTITY', identityProps));

    // Modifiers (UICorner / UIStroke / LocalScript)
    if (elem.className === 'UICorner') {
      container.appendChild(createPropertyGroup('ROUNDING (UICorner)', [
        {
          label: 'CornerRadius (px)',
          type: 'range',
          min: 0,
          max: 60,
          value: p.CornerRadius?.Offset || 0,
          onChange: v => {
            if (!p.CornerRadius) p.CornerRadius = { Scale: 0, Offset: 0 };
            p.CornerRadius.Offset = Number(v);
            renderVirtualCanvas();
            updateLocalScriptCode();
          }
        }
      ]));
      return;
    }

    if (elem.className === 'UIStroke') {
      container.appendChild(createPropertyGroup('STROKE (UIStroke)', [
        { label: 'Color', type: 'color', value: p.Color || '#10b981', onChange: v => { p.Color = v; renderVirtualCanvas(); updateLocalScriptCode(); } },
        { label: 'Thickness', type: 'range', min: 1, max: 10, value: p.Thickness || 1, onChange: v => { p.Thickness = Number(v); renderVirtualCanvas(); updateLocalScriptCode(); } },
        { label: 'Transparency', type: 'range', min: 0, max: 1, step: 0.05, value: p.Transparency || 0, onChange: v => { p.Transparency = Number(v); renderVirtualCanvas(); updateLocalScriptCode(); } }
      ]));
      return;
    }

    if (elem.className === 'LocalScript') {
      container.appendChild(createPropertyGroup('LOCAL SCRIPT LOGIC', [
        {
          label: 'Script Code',
          type: 'textarea',
          value: p.ScriptCode || '',
          onChange: v => { p.ScriptCode = v; updateLocalScriptCode(); }
        }
      ]));
      return;
    }

    // Group 2: Position (UDim2) & AnchorPoint
    if (p.Position) {
      container.appendChild(createPropertyGroup('POSITION (UDim2)', [
        {
          label: 'X (Scale, Offset)',
          type: 'dual-number',
          val1: p.Position.X.Scale,
          val2: p.Position.X.Offset,
          lbl1: 'Scale',
          lbl2: 'Offset',
          step1: 0.05,
          onChange: (s, o) => {
            p.Position.X.Scale = Number(s) || 0;
            p.Position.X.Offset = Number(o) || 0;
            renderVirtualCanvas();
            updateLocalScriptCode();
          }
        },
        {
          label: 'Y (Scale, Offset)',
          type: 'dual-number',
          val1: p.Position.Y.Scale,
          val2: p.Position.Y.Offset,
          lbl1: 'Scale',
          lbl2: 'Offset',
          step1: 0.05,
          onChange: (s, o) => {
            p.Position.Y.Scale = Number(s) || 0;
            p.Position.Y.Offset = Number(o) || 0;
            renderVirtualCanvas();
            updateLocalScriptCode();
          }
        },
        {
          label: 'AnchorPoint (X, Y)',
          type: 'dual-number',
          val1: p.AnchorPoint?.X || 0,
          val2: p.AnchorPoint?.Y || 0,
          lbl1: 'X',
          lbl2: 'Y',
          step1: 0.5,
          step2: 0.5,
          onChange: (x, y) => {
            if (!p.AnchorPoint) p.AnchorPoint = { X: 0, Y: 0 };
            p.AnchorPoint.X = Number(x) || 0;
            p.AnchorPoint.Y = Number(y) || 0;
            renderVirtualCanvas();
            updateLocalScriptCode();
          }
        }
      ]));
    }

    // Group 3: Size (UDim2)
    if (p.Size) {
      container.appendChild(createPropertyGroup('SIZE (UDim2)', [
        {
          label: 'X (Scale, Offset)',
          type: 'dual-number',
          val1: p.Size.X.Scale,
          val2: p.Size.X.Offset,
          lbl1: 'Scale',
          lbl2: 'Offset',
          step1: 0.05,
          onChange: (s, o) => {
            p.Size.X.Scale = Number(s) || 0;
            p.Size.X.Offset = Number(o) || 0;
            renderVirtualCanvas();
            updateLocalScriptCode();
          }
        },
        {
          label: 'Y (Scale, Offset)',
          type: 'dual-number',
          val1: p.Size.Y.Scale,
          val2: p.Size.Y.Offset,
          lbl1: 'Scale',
          lbl2: 'Offset',
          step1: 0.05,
          onChange: (s, o) => {
            p.Size.Y.Scale = Number(s) || 0;
            p.Size.Y.Offset = Number(o) || 0;
            renderVirtualCanvas();
            updateLocalScriptCode();
          }
        }
      ]));
    }

    // Group 4: Appearance & Rounding (UICorner)
    const { corner } = getElementModifiers(elem);
    const appearanceProps = [
      {
        label: 'Background Color',
        type: 'color',
        value: p.BackgroundColor3 || '#0b0e14',
        onChange: v => { p.BackgroundColor3 = v; renderVirtualCanvas(); updateLocalScriptCode(); }
      },
      {
        label: 'Transparency',
        type: 'range',
        min: 0,
        max: 1,
        step: 0.05,
        value: p.BackgroundTransparency !== undefined ? p.BackgroundTransparency : 0,
        onChange: v => { p.BackgroundTransparency = Number(v); renderVirtualCanvas(); updateLocalScriptCode(); }
      }
    ];

    if (['Frame', 'ScrollingFrame'].includes(elem.className)) {
      appearanceProps.push({
        label: 'ClipsDescendants',
        type: 'boolean',
        value: p.ClipsDescendants === true,
        onChange: v => { p.ClipsDescendants = v; renderVirtualCanvas(); updateLocalScriptCode(); }
      });
    }

    appearanceProps.push({
      label: 'Corner Radius (Round)',
      type: 'range',
      min: 0,
      max: 40,
      value: corner ? (corner.properties.CornerRadius?.Offset || 0) : 0,
      onChange: v => {
        let c = corner;
        if (!c) {
          state.idCounter++;
          c = {
            id: `inst_${state.idCounter}`,
            className: 'UICorner',
            name: 'Corner',
            properties: { CornerRadius: { Scale: 0, Offset: Number(v) } },
            children: []
          };
          if (!elem.children) elem.children = [];
          elem.children.push(c);
          renderExplorerTree();
        } else {
          c.properties.CornerRadius.Offset = Number(v);
        }
        renderVirtualCanvas();
        updateLocalScriptCode();
      }
    });

    container.appendChild(createPropertyGroup('APPEARANCE & ROUND', appearanceProps));

    // Group 5: Text Properties (if applicable)
    if (['TextLabel', 'TextButton', 'TextBox'].includes(elem.className)) {
      container.appendChild(createPropertyGroup('TEXT PROPERTIES', [
        {
          label: 'Text',
          type: 'text',
          value: p.Text || '',
          onChange: v => { p.Text = v; renderVirtualCanvas(); updateLocalScriptCode(); }
        },
        {
          label: 'Text Color',
          type: 'color',
          value: p.TextColor3 || '#ffffff',
          onChange: v => { p.TextColor3 = v; renderVirtualCanvas(); updateLocalScriptCode(); }
        },
        {
          label: 'Text Size',
          type: 'number',
          value: p.TextSize || 13,
          onChange: v => { p.TextSize = Number(v) || 13; renderVirtualCanvas(); updateLocalScriptCode(); }
        },
        {
          label: 'Font',
          type: 'select',
          options: ['Gotham', 'GothamBold', 'BuilderSans', 'BuilderSansBold', 'SourceSans', 'FredokaOne', 'Code'],
          value: p.Font || 'Gotham',
          onChange: v => { p.Font = v; renderVirtualCanvas(); updateLocalScriptCode(); }
        },
        {
          label: 'TextXAlignment',
          type: 'select',
          options: ['Left', 'Center', 'Right'],
          value: p.TextXAlignment || 'Center',
          onChange: v => { p.TextXAlignment = v; renderVirtualCanvas(); updateLocalScriptCode(); }
        },
        {
          label: 'TextWrapped',
          type: 'boolean',
          value: !!p.TextWrapped,
          onChange: v => { p.TextWrapped = v; renderVirtualCanvas(); updateLocalScriptCode(); }
        }
      ]));
    }
  }

  function createPropertyGroup(title, rows) {
    const group = document.createElement('div');
    group.className = 'dex-prop-group';

    const header = document.createElement('div');
    header.className = 'dex-prop-group-title';
    header.textContent = title;
    group.appendChild(header);

    rows.forEach(r => {
      const rowEl = document.createElement('div');
      rowEl.className = 'dex-prop-grid-row';

      const keyEl = document.createElement('span');
      keyEl.className = 'dex-prop-grid-key';
      keyEl.textContent = r.label;

      const valEl = document.createElement('div');
      valEl.className = 'dex-prop-grid-val';

      if (r.type === 'text') {
        const inp = document.createElement('input');
        inp.type = 'text';
        inp.className = 'gui-prop-input';
        inp.value = r.value !== undefined ? r.value : '';
        inp.addEventListener('input', () => r.onChange(inp.value));
        valEl.appendChild(inp);
      } else if (r.type === 'number') {
        const inp = document.createElement('input');
        inp.type = 'number';
        inp.className = 'gui-prop-input';
        inp.value = r.value !== undefined ? r.value : 0;
        inp.addEventListener('input', () => r.onChange(Number(inp.value)));
        valEl.appendChild(inp);
      } else if (r.type === 'boolean') {
        const pill = document.createElement('span');
        pill.className = `dex-val-boolean ${r.value ? 'is-true' : 'is-false'}`;
        pill.textContent = r.value ? 'true' : 'false';
        pill.style.cursor = 'pointer';
        pill.addEventListener('click', () => {
          r.value = !r.value;
          pill.className = `dex-val-boolean ${r.value ? 'is-true' : 'is-false'}`;
          pill.textContent = r.value ? 'true' : 'false';
          r.onChange(r.value);
        });
        valEl.appendChild(pill);
      } else if (r.type === 'color') {
        const wrap = document.createElement('div');
        wrap.style.display = 'flex';
        wrap.style.alignItems = 'center';
        wrap.style.gap = '6px';

        const colorPicker = document.createElement('input');
        colorPicker.type = 'color';
        colorPicker.className = 'gui-color-picker';
        colorPicker.value = r.value || '#000000';

        const textInp = document.createElement('input');
        textInp.type = 'text';
        textInp.className = 'gui-prop-input';
        textInp.style.width = '70px';
        textInp.value = r.value || '#000000';

        colorPicker.addEventListener('input', () => {
          textInp.value = colorPicker.value;
          r.onChange(colorPicker.value);
        });
        textInp.addEventListener('input', () => {
          if (textInp.value.startsWith('#') && textInp.value.length === 7) {
            colorPicker.value = textInp.value;
            r.onChange(textInp.value);
          }
        });

        wrap.appendChild(colorPicker);
        wrap.appendChild(textInp);
        valEl.appendChild(wrap);
      } else if (r.type === 'range') {
        const wrap = document.createElement('div');
        wrap.style.display = 'flex';
        wrap.style.alignItems = 'center';
        wrap.style.gap = '8px';
        wrap.style.width = '100%';

        const range = document.createElement('input');
        range.type = 'range';
        range.min = r.min !== undefined ? r.min : 0;
        range.max = r.max !== undefined ? r.max : 100;
        range.step = r.step !== undefined ? r.step : 1;
        range.value = r.value !== undefined ? r.value : 0;
        range.className = 'gui-range-slider';

        const badge = document.createElement('span');
        badge.className = 'badge-mini';
        badge.style.minWidth = '32px';
        badge.textContent = r.value;

        range.addEventListener('input', () => {
          badge.textContent = range.value;
          r.onChange(Number(range.value));
        });

        wrap.appendChild(range);
        wrap.appendChild(badge);
        valEl.appendChild(wrap);
      } else if (r.type === 'dual-number') {
        const wrap = document.createElement('div');
        wrap.style.display = 'grid';
        wrap.style.gridTemplateColumns = '1fr 1fr';
        wrap.style.gap = '4px';
        wrap.style.width = '100%';

        const inp1 = document.createElement('input');
        inp1.type = 'number';
        inp1.className = 'gui-prop-input';
        inp1.placeholder = r.lbl1;
        inp1.step = r.step1 || 'any';
        inp1.value = r.val1 !== undefined ? r.val1 : 0;

        const inp2 = document.createElement('input');
        inp2.type = 'number';
        inp2.className = 'gui-prop-input';
        inp2.placeholder = r.lbl2;
        inp2.step = r.step2 || '1';
        inp2.value = r.val2 !== undefined ? r.val2 : 0;

        const update = () => r.onChange(inp1.value, inp2.value);
        inp1.addEventListener('input', update);
        inp2.addEventListener('input', update);

        wrap.appendChild(inp1);
        wrap.appendChild(inp2);
        valEl.appendChild(wrap);
      } else if (r.type === 'select') {
        const sel = document.createElement('select');
        sel.className = 'gui-prop-input';
        (r.options || []).forEach((opt, idx) => {
          const optEl = document.createElement('option');
          optEl.value = opt;
          optEl.textContent = (r.optionLabels && r.optionLabels[idx]) ? r.optionLabels[idx] : opt;
          optEl.selected = opt === r.value;
          sel.appendChild(optEl);
        });
        sel.addEventListener('change', () => r.onChange(sel.value));
        valEl.appendChild(sel);
      } else if (r.type === 'textarea') {
        const area = document.createElement('textarea');
        area.className = 'gui-prop-textarea';
        area.value = r.value || '';
        area.rows = 4;
        area.addEventListener('input', () => r.onChange(area.value));
        valEl.appendChild(area);
      }

      rowEl.appendChild(keyEl);
      rowEl.appendChild(valEl);
      group.appendChild(rowEl);
    });

    return group;
  }

  // ========================================================
  // Real-Time Luau LocalScript Generator (Auto-Update Engine)
  // ========================================================

  function generateRobloxLuauScript(rootTree) {
    const lines = [];
    lines.push('-- ========================================================');
    lines.push('-- Generated by Gousse ScreenGui Studio');
    lines.push(`-- Date: ${new Date().toISOString().replace('T', ' ').slice(0, 19)}`);
    lines.push('-- Sandboxed Roblox GUI with Auto-Generated LocalScript');
    lines.push('-- ========================================================');
    lines.push('');
    lines.push('local Players = game:GetService("Players")');
    lines.push('local TweenService = game:GetService("TweenService")');
    lines.push('local localPlayer = Players.LocalPlayer');
    lines.push('local playerGui = localPlayer:WaitForChild("PlayerGui")');
    lines.push('');
    lines.push('-- Safe parenting invariant for exploit environments');
    lines.push('local function getSafeGuiParent(): Instance');
    lines.push('    if gethui then');
    lines.push('        local ok, hui = pcall(gethui)');
    lines.push('        if ok and hui then return hui end');
    lines.push('    end');
    lines.push('    local okCore, cg = pcall(function() return game:GetService("CoreGui") end)');
    lines.push('    if okCore and cg then return cg end');
    lines.push('    return playerGui');
    lines.push('end');
    lines.push('');
    lines.push('local parentContainer = getSafeGuiParent()');
    lines.push('');

    // Root ScreenGui
    const rootVar = sanitizeVarName(rootTree.name || 'customScreenGui');
    lines.push(`-- 1. Create ${rootTree.className}`);
    lines.push(`local ${rootVar} = Instance.new("${rootTree.className}")`);
    lines.push(`${rootVar}.Name = "${rootTree.name || 'ScreenGui'}"`);
    lines.push(`${rootVar}.ResetOnSpawn = ${rootTree.properties.ResetOnSpawn !== false}`);
    lines.push(`${rootVar}.ZIndexBehavior = Enum.ZIndexBehavior.Sibling`);
    lines.push(`${rootVar}.Parent = parentContainer`);
    lines.push('');

    // Recursive Child Instances
    function traverseChildren(node, parentVar) {
      if (!node.children) return;

      node.children.forEach(child => {
        const childVar = sanitizeVarName(child.name);
        const p = child.properties || {};

        lines.push(`-- [${child.className}]: ${child.name}`);
        lines.push(`local ${childVar} = Instance.new("${child.className}")`);
        lines.push(`${childVar}.Name = "${child.name}"`);

        // Common Transform
        if (p.Position) {
          lines.push(`${childVar}.Position = UDim2.new(${p.Position.X.Scale}, ${p.Position.X.Offset}, ${p.Position.Y.Scale}, ${p.Position.Y.Offset})`);
        }
        if (p.Size) {
          lines.push(`${childVar}.Size = UDim2.new(${p.Size.X.Scale}, ${p.Size.X.Offset}, ${p.Size.Y.Scale}, ${p.Size.Y.Offset})`);
        }
        if (p.AnchorPoint) {
          lines.push(`${childVar}.AnchorPoint = Vector2.new(${p.AnchorPoint.X || 0}, ${p.AnchorPoint.Y || 0})`);
        }

        // Appearance
        if (p.BackgroundColor3) {
          const rgb = hexToRgb(p.BackgroundColor3);
          lines.push(`${childVar}.BackgroundColor3 = Color3.fromRGB(${rgb.r}, ${rgb.g}, ${rgb.b})`);
        }
        if (p.BackgroundTransparency !== undefined) {
          lines.push(`${childVar}.BackgroundTransparency = ${p.BackgroundTransparency}`);
        }
        if (p.BorderSizePixel !== undefined) {
          lines.push(`${childVar}.BorderSizePixel = ${p.BorderSizePixel}`);
        }
        if (p.BorderColor3) {
          const brgb = hexToRgb(p.BorderColor3);
          lines.push(`${childVar}.BorderColor3 = Color3.fromRGB(${brgb.r}, ${brgb.g}, ${brgb.b})`);
        }
        if (p.ZIndex !== undefined) {
          lines.push(`${childVar}.ZIndex = ${p.ZIndex}`);
        }
        if (p.ClipsDescendants !== undefined) {
          lines.push(`${childVar}.ClipsDescendants = ${p.ClipsDescendants}`);
        }
        if (p.Visible !== undefined) {
          lines.push(`${childVar}.Visible = ${p.Visible}`);
        }

        // UICorner
        if (child.className === 'UICorner' && p.CornerRadius) {
          lines.push(`${childVar}.CornerRadius = UDim.new(${p.CornerRadius.Scale || 0}, ${p.CornerRadius.Offset || 0})`);
        }

        // UIStroke
        if (child.className === 'UIStroke') {
          if (p.Color) {
            const srgb = hexToRgb(p.Color);
            lines.push(`${childVar}.Color = Color3.fromRGB(${srgb.r}, ${srgb.g}, ${srgb.b})`);
          }
          if (p.Thickness !== undefined) {
            lines.push(`${childVar}.Thickness = ${p.Thickness}`);
          }
          if (p.Transparency !== undefined) {
            lines.push(`${childVar}.Transparency = ${p.Transparency}`);
          }
        }

        // Text Properties
        if (['TextLabel', 'TextButton', 'TextBox'].includes(child.className)) {
          if (p.Text !== undefined) lines.push(`${childVar}.Text = "${p.Text.replace(/"/g, '\\"')}"`);
          if (p.TextColor3) {
            const trgb = hexToRgb(p.TextColor3);
            lines.push(`${childVar}.TextColor3 = Color3.fromRGB(${trgb.r}, ${trgb.g}, ${trgb.b})`);
          }
          if (p.TextSize !== undefined) lines.push(`${childVar}.TextSize = ${p.TextSize}`);
          if (p.Font) lines.push(`${childVar}.Font = Enum.Font.${p.Font}`);
          if (p.TextXAlignment) lines.push(`${childVar}.TextXAlignment = Enum.TextXAlignment.${p.TextXAlignment}`);
          if (p.TextYAlignment) lines.push(`${childVar}.TextYAlignment = Enum.TextYAlignment.${p.TextYAlignment}`);
          if (p.TextWrapped !== undefined) lines.push(`${childVar}.TextWrapped = ${p.TextWrapped}`);
          if (p.TextScaled !== undefined) lines.push(`${childVar}.TextScaled = ${p.TextScaled}`);
        }

        if (child.className === 'TextBox' && p.PlaceholderText) {
          lines.push(`${childVar}.PlaceholderText = "${p.PlaceholderText.replace(/"/g, '\\"')}"`);
        }

        if (['ImageLabel', 'ImageButton'].includes(child.className) && p.Image) {
          lines.push(`${childVar}.Image = "${p.Image}"`);
        }

        // LocalScript Code
        if (child.className === 'LocalScript' && p.ScriptCode) {
          lines.push('');
          lines.push(`-- [LocalScript attached to ${parentVar}]`);
          lines.push(`task.spawn(function()`);
          lines.push(`    local script = ${childVar}`);
          lines.push(`    ${p.ScriptCode}`);
          lines.push(`end)`);
        }

        // Button Click Event Wiring
        if (child.className === 'TextButton') {
          lines.push(`${childVar}.Activated:Connect(function()`);
          lines.push(`    print("[Activated]: ${child.name} was clicked")`);
          lines.push(`end)`);
        }

        lines.push(`${childVar}.Parent = ${parentVar}`);
        lines.push('');

        // Recurse
        traverseChildren(child, childVar);
      });
    }

    traverseChildren(rootTree, rootVar);

    lines.push(`print("[ScreenGui Studio] ${rootTree.name} successfully deployed to client.")`);
    lines.push(`return ${rootVar}`);
    return lines.join('\n');
  }

  function sanitizeVarName(str) {
    const clean = String(str || 'element').replace(/[^a-zA-Z0-9]/g, '');
    if (!clean || /^[0-9]/.test(clean)) return `elem_${clean || 'obj'}`;
    return clean.charAt(0).toLowerCase() + clean.slice(1);
  }

  function updateLocalScriptCode() {
    const codeArea = document.getElementById('gui-script-code-area');
    const linesBadge = document.getElementById('gui-script-lines-badge');
    const source = generateRobloxLuauScript(state.tree);

    if (linesBadge) {
      linesBadge.textContent = `${source.split('\n').length} lines`;
    }

    if (codeArea) {
      if (typeof highlightLuauSyntax === 'function') {
        const lines = source.split('\n');
        const table = document.createElement('table');
        table.className = 'dex-reader-code-table';
        lines.forEach((l, idx) => {
          const tr = document.createElement('tr');
          const tdNum = document.createElement('td');
          tdNum.className = 'dex-reader-line-num';
          tdNum.textContent = idx + 1;
          const tdCode = document.createElement('td');
          tdCode.className = 'dex-reader-line-code';
          tdCode.innerHTML = highlightLuauSyntax(l);
          tr.appendChild(tdNum);
          tr.appendChild(tdCode);
          table.appendChild(tr);
        });
        codeArea.innerHTML = '';
        codeArea.appendChild(table);
      } else {
        codeArea.textContent = source;
      }
    }

    state.generatedScript = source;
  }

  let toolbarListenersSetup = false;

  function setupToolbarListeners() {
    if (toolbarListenersSetup) return;
    const deviceSelect = document.getElementById('gui-device-select');
    if (!deviceSelect) return; // DOM not ready yet
    toolbarListenersSetup = true;

    // Device Preset Selector
    if (deviceSelect) {
      Object.entries(VIEWPORT_PRESETS).forEach(([id, dev]) => {
        const opt = document.createElement('option');
        opt.value = id;
        opt.textContent = dev.name;
        opt.selected = id === state.selectedDeviceId;
        deviceSelect.appendChild(opt);
      });

      deviceSelect.addEventListener('change', () => {
        state.selectedDeviceId = deviceSelect.value;
        const dev = VIEWPORT_PRESETS[state.selectedDeviceId];
        if (state.autoFitZoom && dev) {
          state.zoomScale = dev.defaultScale;
        }
        renderVirtualCanvas();
      });
    }

    // Mode Toggle (Edit Mode vs Play / Test Sandbox)
    const btnModeEdit = document.getElementById('btn-gui-mode-edit');
    const btnModePlay = document.getElementById('btn-gui-mode-play');
    if (btnModeEdit && btnModePlay) {
      btnModeEdit.addEventListener('click', () => {
        state.mode = 'edit';
        btnModeEdit.classList.add('active');
        btnModePlay.classList.remove('active');
        renderVirtualCanvas();
        if (typeof showToast === 'function') showToast('Switched to Edit Mode (Drag & Resize enabled)');
      });

      btnModePlay.addEventListener('click', () => {
        state.mode = 'play';
        btnModePlay.classList.add('active');
        btnModeEdit.classList.remove('active');
        renderVirtualCanvas();
        if (typeof showToast === 'function') showToast('Switched to Play Sandbox (Interactive buttons & inputs)');
      });
    }

    // Sizing Mode Switch (Offset vs Scale)
    const btnSizingOffset = document.getElementById('btn-gui-size-offset');
    const btnSizingScale = document.getElementById('btn-gui-size-scale');
    if (btnSizingOffset && btnSizingScale) {
      btnSizingOffset.addEventListener('click', () => {
        state.sizingMode = 'offset';
        btnSizingOffset.classList.add('active');
        btnSizingScale.classList.remove('active');
        if (typeof showToast === 'function') showToast('Transform mode: Pixels (Offset)');
      });
      btnSizingScale.addEventListener('click', () => {
        state.sizingMode = 'scale';
        btnSizingScale.classList.add('active');
        btnSizingOffset.classList.remove('active');
        if (typeof showToast === 'function') showToast('Transform mode: Responsive (Scale)');
      });
    }

    // Zoom Controls
    const btnZoomIn = document.getElementById('btn-gui-zoom-in');
    const btnZoomOut = document.getElementById('btn-gui-zoom-out');
    const btnZoomFit = document.getElementById('btn-gui-zoom-fit');

    if (btnZoomIn) {
      btnZoomIn.addEventListener('click', () => {
        state.autoFitZoom = false;
        state.zoomScale = Math.min(2.0, state.zoomScale + 0.1);
        renderVirtualCanvas();
      });
    }
    if (btnZoomOut) {
      btnZoomOut.addEventListener('click', () => {
        state.autoFitZoom = false;
        state.zoomScale = Math.max(0.2, state.zoomScale - 0.1);
        renderVirtualCanvas();
      });
    }
    if (btnZoomFit) {
      btnZoomFit.addEventListener('click', () => {
        state.autoFitZoom = true;
        const dev = VIEWPORT_PRESETS[state.selectedDeviceId];
        if (dev) state.zoomScale = dev.defaultScale;
        renderVirtualCanvas();
      });
    }

    // Quick Add Element Buttons
    document.querySelectorAll('[data-gui-add]').forEach(btn => {
      btn.addEventListener('click', () => {
        const cls = btn.dataset.guiAdd;
        addElement(cls);
      });
    });

    // Inspector Tab Switcher (Properties vs LocalScript)
    const tabProps = document.getElementById('tab-gui-inspect-props');
    const tabScript = document.getElementById('tab-gui-inspect-script');
    const panelProps = document.getElementById('gui-panel-inspect-props');
    const panelScript = document.getElementById('gui-panel-inspect-script');

    if (tabProps && tabScript && panelProps && panelScript) {
      tabProps.addEventListener('click', () => {
        state.activeTab = 'properties';
        tabProps.classList.add('active');
        tabScript.classList.remove('active');
        panelProps.style.display = 'flex';
        panelScript.style.display = 'none';
      });

      tabScript.addEventListener('click', () => {
        state.activeTab = 'code';
        tabScript.classList.add('active');
        tabProps.classList.remove('active');
        panelScript.style.display = 'flex';
        panelProps.style.display = 'none';
        updateLocalScriptCode();
      });
    }

    // LocalScript Code Actions
    const btnCopyScript = document.getElementById('btn-gui-copy-script');
    if (btnCopyScript) {
      btnCopyScript.addEventListener('click', () => {
        if (state.generatedScript) {
          navigator.clipboard.writeText(state.generatedScript);
          if (typeof showToast === 'function') showToast('Copied ScreenGui Luau script to clipboard');
        }
      });
    }

    const btnRunRoblox = document.getElementById('btn-gui-run-roblox');
    if (btnRunRoblox) {
      btnRunRoblox.addEventListener('click', () => {
        if (!state.generatedScript) return;
        if (typeof executeLuauOnPotassium === 'function') {
          const targetPid = typeof activeTargetPid !== 'undefined' ? activeTargetPid : 'all';
          executeLuauOnPotassium(state.generatedScript, targetPid, 'studio');
          if (typeof showToast === 'function') showToast('Dispatched ScreenGui directly to active Roblox client!');
        } else {
          if (typeof showToast === 'function') showToast('Potassium executor bridge not ready');
        }
      });
    }

    const btnOpenStudio = document.getElementById('btn-gui-open-studio');
    if (btnOpenStudio) {
      btnOpenStudio.addEventListener('click', () => {
        if (!state.generatedScript) return;
        const fileName = `gui/${state.tree.name || 'ScreenGui'}.luau`;
        if (typeof switchView === 'function') switchView('studio');
        if (typeof setMonacoContent === 'function') {
          setMonacoContent(state.generatedScript, fileName);
        }
        if (typeof showToast === 'function') showToast(`Loaded ${fileName} into Script Studio`);
      });
    }

    // Tool Selection (Select vs Hand/Pan)
    const btnToolSelect = document.getElementById('btn-gui-tool-select');
    const btnToolPan = document.getElementById('btn-gui-tool-pan');
    if (btnToolSelect && btnToolPan) {
      btnToolSelect.addEventListener('click', () => setTool('select'));
      btnToolPan.addEventListener('click', () => setTool('hand'));
    }

    // Undo / Redo
    const btnUndo = document.getElementById('btn-gui-undo');
    const btnRedo = document.getElementById('btn-gui-redo');
    if (btnUndo) btnUndo.addEventListener('click', undo);
    if (btnRedo) btnRedo.addEventListener('click', redo);

    // Copy / Paste (Toolbar & Explorer)
    const btnCopy = document.getElementById('btn-gui-copy');
    const btnExpCopy = document.getElementById('btn-gui-exp-copy');
    const btnPaste = document.getElementById('btn-gui-paste');
    const btnExpPaste = document.getElementById('btn-gui-exp-paste');

    if (btnCopy) btnCopy.addEventListener('click', copySelectedElement);
    if (btnExpCopy) btnExpCopy.addEventListener('click', copySelectedElement);
    if (btnPaste) btnPaste.addEventListener('click', pasteElement);
    if (btnExpPaste) btnExpPaste.addEventListener('click', pasteElement);

    // Reset Camera
    const btnCamReset = document.getElementById('btn-gui-cam-reset');
    if (btnCamReset) btnCamReset.addEventListener('click', resetCamera);

    // Viewport pan & keyboard shortcuts
    setupCanvasViewportListeners();
    setupKeyboardShortcuts();
    updateUndoRedoUI();

    // Duplicate button
    const btnDuplicate = document.getElementById('btn-gui-duplicate');
    if (btnDuplicate) {
      btnDuplicate.addEventListener('click', duplicateSelectedElement);
    }
  }

  // ========================================================
  // Initialization
  // ========================================================

  function init() {
    setupToolbarListeners();
    renderExplorerTree();
    renderVirtualCanvas();
    renderPropertiesPanel();
    updateLocalScriptCode();
  }

  // Export to window
  window.GuiDesigner = {
    init,
    addElement,
    deleteElement,
    duplicateSelectedElement,
    copySelectedElement,
    pasteElement,
    undo,
    redo,
    resetCamera,
    setTool,
    selectElement,
    startInlineTextEditing,
    showContextMenu,
    hideContextMenu,
    renderVirtualCanvas,
    updateLocalScriptCode,
    getState: () => state
  };

  // Auto-init on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      setupToolbarListeners();
      init();
    });
  } else {
    setupToolbarListeners();
    init();
  }
})();
