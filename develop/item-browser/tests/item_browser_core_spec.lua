package.path = "./Script/?.lua;" .. package.path

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assert_equal failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "assert_true failed", 2)
    end
end

local core = require("item_browser_core")

local runtime_records = {
    {
        ID = 1000,
        Name = "Mod水",
        EName = "ModWater",
        Description = "来自运行时的水",
        Tag = "Water|Runtime",
        Weight = 1,
        Price = 99,
    },
    {
        ID = 9001,
        Name = "测试配件",
        Description = "外部 Mod 添加的配件",
        Tag = "Parts|Runtime",
        Weight = 3,
        Price = 120,
    },
}

local static_records = {
    {
        id = 1000,
        name = "水",
        sourceType = "物品",
        sourceOrigin = "static",
        description = "基础资源",
        tag = "Water",
        weight = 2,
        price = 12,
    },
    {
        id = 2000,
        name = "罐头",
        sourceType = "食物",
        sourceOrigin = "static",
        description = "可以食用",
        tag = "Food",
        weight = 1,
        price = 20,
    },
}

local records = core.buildRecords({
    ["物品"] = { runtime_records[1] },
    ["配件"] = { runtime_records[2] },
}, static_records)

assert_equal(#records, 3, "runtime and static records should dedupe by category and id")
assert_equal(records[1].sourceOrigin, "runtime", "runtime record should win duplicate id")
assert_equal(records[1].name, "Mod水", "runtime record should replace static duplicate")

local state = core.createState(records)
assert_equal(state.mode, "simple", "default mode should be simple")
assert_equal(state.category, "全部", "default category should be all")

core.setMode(state, "detail")
assert_equal(state.mode, "detail", "detail mode should be accepted")

core.setMode(state, "bad-mode")
assert_equal(state.mode, "detail", "invalid mode should be ignored")

core.setCategory(state, "配件")
local filtered = core.getFilteredRecords(state)
assert_equal(#filtered, 1, "category filter should narrow records")
assert_equal(filtered[1].name, "测试配件", "category filter should return matching item")

core.setCategory(state, "全部")
core.setSearch(state, "modwater")
filtered = core.getFilteredRecords(state)
assert_equal(#filtered, 1, "search should match internal English name case-insensitively")
assert_equal(filtered[1].id, 1000, "search should return water runtime record")

core.setSearch(state, "9001")
filtered = core.getFilteredRecords(state)
assert_equal(#filtered, 1, "numeric search should match id")
assert_equal(filtered[1].sourceType, "配件", "numeric search should preserve source type")

core.setSearch(state, "不存在")
filtered = core.getFilteredRecords(state)
assert_equal(#filtered, 0, "unmatched search should return empty list")

local normalized = core.normalizeRecord({
    ID = "42",
    Name = "样例",
    Level = "3",
    IconID = "7",
    Characteristic = "Mass:1",
}, "物品", "runtime")

assert_equal(normalized.id, "42", "normalize should keep string ids")
assert_equal(normalized.name, "样例", "normalize should map Name")
assert_equal(normalized.level, "3", "normalize should map Level")
assert_equal(normalized.iconId, "7", "normalize should map IconID")
assert_equal(normalized.characteristic, "Mass:1", "normalize should map Characteristic")
assert_true(normalized.rawFields ~= nil, "normalize should keep raw fields")

print("item_browser_core_spec passed")
