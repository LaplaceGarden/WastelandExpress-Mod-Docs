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

local records = require("item_data_static")

assert_true(type(records) == "table", "static data should return a table")
assert_true(#records > 400, "static data should include the four item tables")

local category_count = {}
local found_water = false
local found_food = false
local found_equip = false
local found_parts = false

for _, record in ipairs(records) do
    category_count[record.sourceType] = (category_count[record.sourceType] or 0) + 1
    if record.name == "水" and tostring(record.id) == "1000" then
        found_water = true
        assert_equal(record.sourceType, "物品", "water should be categorized as item")
        assert_equal(record.sourceOrigin, "static", "generated records should be static")
    end
    if record.sourceType == "食物" then
        found_food = true
    elseif record.sourceType == "装备" then
        found_equip = true
    elseif record.sourceType == "配件" then
        found_parts = true
    end
end

assert_true(found_water, "static data should include water from 物品.csv")
assert_true(found_food, "static data should include food records")
assert_true(found_equip, "static data should include equipment records")
assert_true(found_parts, "static data should include parts records")
assert_true(category_count["物品"] > 50, "item category should have many records")

print("static_data_spec passed")
