local M = {}

local CATEGORIES = { "物品", "食物", "装备", "配件" }
local CATEGORY_SET = {
    ["全部"] = true,
    ["物品"] = true,
    ["食物"] = true,
    ["装备"] = true,
    ["配件"] = true,
}

local function first_value(source, names, default_value)
    for _, name in ipairs(names) do
        if source[name] ~= nil and source[name] ~= "" then
            return source[name]
        end
    end
    return default_value or ""
end

local function as_text(value)
    if value == nil then
        return ""
    end
    return tostring(value)
end

local function lower_ascii(value)
    return string.lower(as_text(value))
end

local function record_key(record)
    return as_text(record.sourceType) .. ":" .. as_text(record.id)
end

local function id_sort_value(record)
    return tonumber(record.id) or 999999999
end

function M.normalizeRecord(raw, sourceType, sourceOrigin)
    raw = raw or {}

    return {
        id = first_value(raw, { "id", "ID", "Id" }),
        name = first_value(raw, { "name", "Name", "PeopleName" }),
        internalName = first_value(raw, { "internalName", "EName", "Type" }),
        sourceType = sourceType or first_value(raw, { "sourceType" }, "物品"),
        sourceOrigin = sourceOrigin or first_value(raw, { "sourceOrigin" }, "runtime"),
        level = first_value(raw, { "level", "Level" }),
        weight = first_value(raw, { "weight", "Weight" }),
        price = first_value(raw, { "price", "Price" }),
        iconId = first_value(raw, { "iconId", "IconID", "Image" }),
        description = first_value(raw, { "description", "Description" }),
        tag = first_value(raw, { "tag", "Tag" }),
        characteristic = first_value(raw, { "characteristic", "Characteristic" }),
        buffId = first_value(raw, { "buffId", "BuffID" }),
        func = first_value(raw, { "func", "Func" }),
        funcPlus = first_value(raw, { "funcPlus", "FuncPlus" }),
        needSource = first_value(raw, { "needSource", "NeedSource" }),
        attackRange = first_value(raw, { "attackRange", "AttackRange" }),
        rawFields = raw,
    }
end

local function append_record(records, seen, record)
    if record.id == "" then
        return
    end

    local key = record_key(record)
    if seen[key] then
        return
    end

    seen[key] = true
    records[#records + 1] = record
end

function M.buildRecords(runtimeRecords, staticRecords)
    local records = {}
    local seen = {}

    runtimeRecords = runtimeRecords or {}
    for _, category in ipairs(CATEGORIES) do
        local list = runtimeRecords[category] or {}
        for _, raw in ipairs(list) do
            append_record(records, seen, M.normalizeRecord(raw, category, "runtime"))
        end
    end

    staticRecords = staticRecords or {}
    for _, raw in ipairs(staticRecords) do
        append_record(records, seen, M.normalizeRecord(raw, raw.sourceType or "物品", raw.sourceOrigin or "static"))
    end

    table.sort(records, function(left, right)
        local left_id = id_sort_value(left)
        local right_id = id_sort_value(right)
        if left_id == right_id then
            return as_text(left.sourceType) < as_text(right.sourceType)
        end
        return left_id < right_id
    end)

    return records
end

function M.createState(records)
    return {
        buttonVisible = true,
        windowVisible = false,
        mode = "simple",
        searchText = "",
        category = "全部",
        selectedId = nil,
        scroll = 0,
        detailScroll = 0,
        records = records or {},
        _filteredCache = nil,
        _cacheKey = nil,
    }
end

local function invalidate(state)
    state._filteredCache = nil
    state._cacheKey = nil
end

function M.setMode(state, mode)
    if mode == "simple" or mode == "detail" then
        state.mode = mode
    end
end

function M.setSearch(state, text)
    state.searchText = as_text(text)
    invalidate(state)
end

function M.setCategory(state, category)
    if CATEGORY_SET[category] then
        state.category = category
        invalidate(state)
    end
end

function M.setRecords(state, records)
    state.records = records or {}
    invalidate(state)
end

function M.matchesSearch(record, searchText)
    local query = lower_ascii(searchText)
    if query == "" then
        return true
    end

    local fields = {
        record.id,
        record.name,
        record.internalName,
        record.description,
        record.tag,
        record.characteristic,
        record.buffId,
        record.func,
        record.funcPlus,
        record.needSource,
        record.attackRange,
    }

    for _, value in ipairs(fields) do
        if string.find(lower_ascii(value), query, 1, true) then
            return true
        end
    end

    return false
end

function M.getFilteredRecords(state)
    local cache_key = as_text(state.category) .. "\n" .. as_text(state.searchText) .. "\n" .. tostring(#state.records)
    if state._cacheKey == cache_key and state._filteredCache then
        return state._filteredCache
    end

    local filtered = {}
    for _, record in ipairs(state.records or {}) do
        local category_matches = state.category == "全部" or record.sourceType == state.category
        if category_matches and M.matchesSearch(record, state.searchText) then
            filtered[#filtered + 1] = record
        end
    end

    state._cacheKey = cache_key
    state._filteredCache = filtered
    return filtered
end

return M
