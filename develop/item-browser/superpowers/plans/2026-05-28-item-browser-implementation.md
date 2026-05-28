# Item Browser Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Wasteland Express Lua Mod under `develop/item-browser` that adds an in-game `物品图鉴` button and a dual-mode item browser window.

**Architecture:** Split pure item-browser behavior from game UI. `item_browser_core.lua` owns normalization, deduping, search, filter, and state transitions; `main.lua` owns `OnGUI`, the floating button, and the window. Static fallback data is generated from repository CSV files into `Script/item_data_static.lua`; runtime providers are attempted first and static data fills gaps.

**Tech Stack:** Lua 5.1-compatible code for xLua/LuaJIT, Unity IMGUI via `CS.UnityEngine.GUI`, Node.js for build-time CSV-to-Lua generation, LuaJIT for local unit tests.

---

### Task 1: Core Search And Filtering

**Files:**
- Create: `develop/item-browser/tests/item_browser_core_spec.lua`
- Create: `develop/item-browser/Script/item_browser_core.lua`

- [ ] **Step 1: Write failing tests**

Create `tests/item_browser_core_spec.lua` with assertions for normalization, runtime/static dedupe, category filtering, text search, and mode switching.

- [ ] **Step 2: Run failing tests**

Run: `cd develop/item-browser && luajit tests/item_browser_core_spec.lua`
Expected: FAIL because `Script/item_browser_core.lua` does not exist.

- [ ] **Step 3: Implement core module**

Create `Script/item_browser_core.lua` with:
- `normalizeRecord(raw, sourceType, sourceOrigin)`
- `buildRecords(runtimeRecords, staticRecords)`
- `createState(records)`
- `setMode(state, mode)`
- `setSearch(state, text)`
- `setCategory(state, category)`
- `getFilteredRecords(state)`

- [ ] **Step 4: Run tests**

Run: `cd develop/item-browser && luajit tests/item_browser_core_spec.lua`
Expected: PASS.

### Task 2: Static Data Generator

**Files:**
- Create: `develop/item-browser/tools/generate_static_data.js`
- Create: `develop/item-browser/Script/item_data_static.lua`
- Create: `develop/item-browser/tests/static_data_spec.lua`

- [ ] **Step 1: Write failing test**

Create `tests/static_data_spec.lua` requiring `Script/item_data_static.lua` and asserting that the generated data includes all four categories and at least one known item such as `水`.

- [ ] **Step 2: Run failing test**

Run: `cd develop/item-browser && luajit tests/static_data_spec.lua`
Expected: FAIL because `Script/item_data_static.lua` does not exist.

- [ ] **Step 3: Implement generator**

Create `tools/generate_static_data.js` to read the four CSV files from `../../docs/database`, decode UTF-8 or GBK using Node's `TextDecoder`, parse CSV safely enough for current data, and emit a Lua table.

- [ ] **Step 4: Generate data and run tests**

Run: `cd develop/item-browser && node tools/generate_static_data.js`
Run: `cd develop/item-browser && luajit tests/static_data_spec.lua`
Expected: PASS.

### Task 3: Game UI Entrypoint

**Files:**
- Create: `develop/item-browser/Script/main.lua`

- [ ] **Step 1: Create UI script**

Create `Script/main.lua` with:
- `ItemBrowser_Open()`
- `ItemBrowser_Close()`
- `ItemBrowser_Toggle()`
- `OnGUI()` rendering a floating `物品图鉴` button and the dual-mode window
- runtime provider registration via `ItemBrowser_RegisterRuntimeProvider(name, fn)`
- runtime-first data load with static fallback

- [ ] **Step 2: Syntax check**

Run: `cd develop/item-browser && luajit -bl Script/main.lua >/tmp/item-browser-main-bytecode.txt`
Expected: command succeeds without syntax errors.

### Task 4: Project Documentation

**Files:**
- Create: `develop/item-browser/README.md`

- [ ] **Step 1: Write usage docs**

Document the Mod directory structure, player entry button, runtime-first/static-fallback data strategy, local test commands, and known runtime-enumeration limitation.

- [ ] **Step 2: Run verification**

Run:
- `cd develop/item-browser && luajit tests/item_browser_core_spec.lua`
- `cd develop/item-browser && luajit tests/static_data_spec.lua`
- `cd develop/item-browser && luajit -bl Script/main.lua >/tmp/item-browser-main-bytecode.txt`

Expected: all commands pass.
