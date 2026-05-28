package.path = "./Script/?.lua;" .. package.path

require("main")

local function assert_true(value, message)
    if not value then
        error(message or "assert_true failed", 2)
    end
end

assert_true(type(ItemBrowser_Open) == "function", "ItemBrowser_Open should be global")
assert_true(type(ItemBrowser_Close) == "function", "ItemBrowser_Close should be global")
assert_true(type(ItemBrowser_Toggle) == "function", "ItemBrowser_Toggle should be global")
assert_true(type(ItemBrowser_RegisterRuntimeProvider) == "function", "runtime provider registration should be global")
assert_true(type(OnGUI) == "function", "OnGUI should be global")

local called = false
ItemBrowser_RegisterRuntimeProvider("test-provider", function()
    called = true
    return {
        ["物品"] = {
            {
                ID = 777,
                Name = "运行时测试物品",
                Description = "由测试 provider 提供",
                Tag = "Runtime",
            },
        },
    }
end)

ItemBrowser_Open()
assert_true(called, "opening should load runtime providers before showing window")

ItemBrowser_Close()
ItemBrowser_Toggle()

print("main_smoke_spec passed")
