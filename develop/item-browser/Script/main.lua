package.path = "./Script/?.lua;Script/?.lua;" .. package.path

local core = require("item_browser_core")
local staticRecords = require("item_data_static")

local runtimeProviders = {}
local runtimeProviderNames = {}
local providerErrors = {}
local dataLoaded = false
local records = {}
local state = core.createState(records)

local categories = { "全部", "物品", "食物", "装备", "配件" }

local function log_once(key, message)
    if providerErrors[key] then
        return
    end
    providerErrors[key] = true
    print(message)
end

local function merge_runtime_bucket(target, source)
    if type(source) ~= "table" then
        return
    end

    for _, category in ipairs({ "物品", "食物", "装备", "配件" }) do
        local list = source[category]
        if type(list) == "table" then
            target[category] = target[category] or {}
            for _, record in ipairs(list) do
                target[category][#target[category] + 1] = record
            end
        end
    end
end

local function load_runtime_records()
    local runtimeRecords = {}

    for index, provider in ipairs(runtimeProviders) do
        local ok, result = pcall(provider)
        if ok then
            merge_runtime_bucket(runtimeRecords, result)
        else
            local name = runtimeProviderNames[index] or ("provider-" .. tostring(index))
            log_once("provider:" .. name, "[ItemBrowser] runtime provider failed: " .. name .. " - " .. tostring(result))
        end
    end

    return runtimeRecords
end

local function load_records()
    local runtimeRecords = load_runtime_records()
    records = core.buildRecords(runtimeRecords, staticRecords)
    core.setRecords(state, records)
    dataLoaded = true

    local filtered = core.getFilteredRecords(state)
    if not state.selectedId and filtered[1] then
        state.selectedId = filtered[1].id
    end
end

local function ensure_loaded()
    if not dataLoaded then
        load_records()
    end
end

function ItemBrowser_RegisterRuntimeProvider(name, provider)
    if type(provider) ~= "function" then
        print("[ItemBrowser] runtime provider ignored because it is not a function: " .. tostring(name))
        return false
    end

    runtimeProviders[#runtimeProviders + 1] = provider
    runtimeProviderNames[#runtimeProviderNames + 1] = tostring(name or ("provider-" .. tostring(#runtimeProviders)))
    dataLoaded = false
    return true
end

function ItemBrowser_Open()
    ensure_loaded()
    state.windowVisible = true
    state.buttonVisible = true
end

function ItemBrowser_Close()
    state.windowVisible = false
end

function ItemBrowser_Toggle()
    if state.windowVisible then
        ItemBrowser_Close()
    else
        ItemBrowser_Open()
    end
end

local function unity()
    if CS and CS.UnityEngine then
        return CS.UnityEngine
    end
    return nil
end

local function make_rect(UnityEngine, x, y, width, height)
    return UnityEngine.Rect(x, y, width, height)
end

local function current_screen(UnityEngine)
    local screen = UnityEngine.Screen
    local width = 1280
    local height = 720
    if screen then
        width = screen.width or width
        height = screen.height or height
    end
    return width, height
end

local function find_selected(filtered)
    for _, record in ipairs(filtered) do
        if tostring(record.id) == tostring(state.selectedId) then
            return record
        end
    end
    return filtered[1]
end

local function text_or_dash(value)
    if value == nil or value == "" then
        return "-"
    end
    return tostring(value)
end

local function summary(record)
    if not record then
        return "请选择一个物品"
    end

    local lines = {
        "名称: " .. text_or_dash(record.name),
        "ID: " .. text_or_dash(record.id),
        "分类: " .. text_or_dash(record.sourceType) .. " / 来源: " .. text_or_dash(record.sourceOrigin),
        "等级: " .. text_or_dash(record.level) .. "    重量: " .. text_or_dash(record.weight) .. "    价格: " .. text_or_dash(record.price),
        "标签: " .. text_or_dash(record.tag),
        "特性: " .. text_or_dash(record.characteristic),
        "BuffID: " .. text_or_dash(record.buffId),
        "Func: " .. text_or_dash(record.func),
        "NeedSource: " .. text_or_dash(record.needSource),
        "描述: " .. text_or_dash(record.description),
    }

    return table.concat(lines, "\n")
end

local function draw_top_bar(GUI, Rect, x, y, width)
    GUI.Label(Rect(x, y, 80, 24), "搜索")
    local nextSearch = GUI.TextField(Rect(x + 42, y, width - 310, 24), state.searchText or "")
    if nextSearch ~= state.searchText then
        core.setSearch(state, nextSearch)
    end

    local buttonX = x + width - 255
    for _, category in ipairs(categories) do
        local label = category
        local w = category == "全部" and 48 or 42
        if GUI.Button(Rect(buttonX, y, w, 24), label) then
            core.setCategory(state, category)
            state.selectedId = nil
        end
        buttonX = buttonX + w + 4
    end
end

local function draw_mode_buttons(GUI, Rect, x, y)
    if GUI.Button(Rect(x, y, 58, 24), "简约") then
        core.setMode(state, "simple")
    end
    if GUI.Button(Rect(x + 64, y, 58, 24), "详细") then
        core.setMode(state, "detail")
    end
    if GUI.Button(Rect(x + 128, y, 58, 24), "关闭") then
        ItemBrowser_Close()
    end
end

local function draw_simple(GUI, Rect, x, y, width, height, filtered)
    local listWidth = math.floor(width * 0.46)
    local rowHeight = 24
    local maxRows = math.max(1, math.floor((height - 76) / rowHeight))
    local offset = state.scroll or 0

    if offset > 0 and GUI.Button(Rect(x, y, listWidth, 22), "上一页") then
        state.scroll = math.max(0, offset - maxRows)
    end

    GUI.Label(Rect(x, y + 26, 60, 22), "ID")
    GUI.Label(Rect(x + 65, y + 26, 150, 22), "名称")
    GUI.Label(Rect(x + listWidth - 74, y + 26, 70, 22), "分类")

    local rowY = y + 50
    for i = 1, maxRows do
        local record = filtered[offset + i]
        if record then
            local label = text_or_dash(record.id) .. "  " .. text_or_dash(record.name)
            if GUI.Button(Rect(x, rowY, listWidth - 78, rowHeight), label) then
                state.selectedId = record.id
            end
            GUI.Label(Rect(x + listWidth - 74, rowY + 3, 70, 20), text_or_dash(record.sourceType))
        end
        rowY = rowY + rowHeight
    end

    if offset + maxRows < #filtered and GUI.Button(Rect(x, y + height - 24, listWidth, 22), "下一页") then
        state.scroll = offset + maxRows
    end

    local selected = find_selected(filtered)
    if selected then
        state.selectedId = selected.id
    end

    local detailX = x + listWidth + 14
    GUI.Label(Rect(detailX, y + 26, width - listWidth - 18, 24), "详情")
    GUI.TextArea(Rect(detailX, y + 54, width - listWidth - 18, height - 58), summary(selected))
end

local function detail_row(record)
    return table.concat({
        text_or_dash(record.id),
        text_or_dash(record.name),
        text_or_dash(record.sourceType),
        text_or_dash(record.level),
        text_or_dash(record.weight),
        text_or_dash(record.price),
        text_or_dash(record.tag),
    }, " | ")
end

local function draw_detail(GUI, Rect, x, y, width, height, filtered)
    local rowHeight = 23
    local maxRows = math.max(1, math.floor((height - 58) / rowHeight))
    local offset = state.detailScroll or 0

    GUI.Label(Rect(x, y + 24, width, 22), "ID | 名称 | 分类 | 等级 | 重量 | 价格 | 标签")

    local rowY = y + 48
    for i = 1, maxRows do
        local record = filtered[offset + i]
        if record then
            if GUI.Button(Rect(x, rowY, width, rowHeight), detail_row(record)) then
                state.selectedId = record.id
            end
        end
        rowY = rowY + rowHeight
    end

    if offset > 0 and GUI.Button(Rect(x, y, 80, 22), "上一页") then
        state.detailScroll = math.max(0, offset - maxRows)
    end
    if offset + maxRows < #filtered and GUI.Button(Rect(x + 88, y, 80, 22), "下一页") then
        state.detailScroll = offset + maxRows
    end
end

local function draw_window(windowId)
    local UnityEngine = unity()
    if not UnityEngine then
        return
    end

    local GUI = UnityEngine.GUI
    local Rect = function(x, y, width, height)
        return make_rect(UnityEngine, x, y, width, height)
    end

    local width = 780
    local height = 520
    GUI.Label(Rect(16, 22, 160, 24), "物品图鉴")
    draw_mode_buttons(GUI, Rect, width - 212, 18)
    draw_top_bar(GUI, Rect, 16, 52, width - 32)

    local filtered = core.getFilteredRecords(state)
    if #filtered == 0 then
        GUI.Label(Rect(16, 95, width - 32, 32), "没有找到匹配物品")
    elseif state.mode == "detail" then
        draw_detail(GUI, Rect, 16, 92, width - 32, height - 108, filtered)
    else
        draw_simple(GUI, Rect, 16, 92, width - 32, height - 108, filtered)
    end

    if GUI.DragWindow then
        GUI.DragWindow()
    end
end

function OnGUI()
    local UnityEngine = unity()
    if not UnityEngine then
        return false
    end

    ensure_loaded()

    local GUI = UnityEngine.GUI
    local Rect = function(x, y, width, height)
        return make_rect(UnityEngine, x, y, width, height)
    end

    local screenWidth, _ = current_screen(UnityEngine)
    if state.buttonVisible and GUI.Button(Rect(screenWidth - 112, 90, 96, 28), "物品图鉴") then
        ItemBrowser_Toggle()
    end

    if state.windowVisible then
        local windowRect = Rect(math.max(10, screenWidth - 820), 130, 800, 540)
        GUI.Window(902528, windowRect, draw_window, "物品图鉴")
    end

    return false
end

return {
    open = ItemBrowser_Open,
    close = ItemBrowser_Close,
    toggle = ItemBrowser_Toggle,
    registerRuntimeProvider = ItemBrowser_RegisterRuntimeProvider,
}
