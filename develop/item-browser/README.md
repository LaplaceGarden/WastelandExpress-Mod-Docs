# Wasteland Express Item Browser Mod

游戏内物品查询 Mod。第一版提供一个 `物品图鉴` 悬浮按钮，点击后打开只读查询窗口，支持简约/详细双模式、搜索和分类筛选。

## 目录结构

```text
item-browser
├─ Script
│  ├─ main.lua
│  ├─ item_browser_core.lua
│  └─ item_data_static.lua
├─ tests
│  ├─ item_browser_core_spec.lua
│  ├─ main_smoke_spec.lua
│  └─ static_data_spec.lua
├─ tools
│  └─ generate_static_data.js
└─ superpowers
   ├─ specs
   └─ plans
```

## 玩家入口

进入游戏后，Mod 通过 `OnGUI` 在屏幕右侧显示 `物品图鉴` 按钮。点击按钮可以打开或关闭物品查询窗口。

控制台函数仍保留为调试入口：

```lua
ItemBrowser_Open()
ItemBrowser_Close()
ItemBrowser_Toggle()
```

## 数据策略

设计目标是运行时优先、静态数据兜底。

当前已文档化 API 没有公开“枚举完整物品列表”的接口，因此第一版代码提供运行时 provider 注册点：

```lua
ItemBrowser_RegisterRuntimeProvider("provider-name", function()
    return {
        ["物品"] = {
            { ID = 1000, Name = "水", Description = "基础资源" },
        },
        ["食物"] = {},
        ["装备"] = {},
        ["配件"] = {},
    }
end)
```

如果未来确认了游戏内部运行时物品表所在的 C# 类，可以通过这个 provider 接入。没有运行时 provider 时，Mod 使用 `Script/item_data_static.lua` 中的官方静态数据。

## 生成静态数据

静态数据来自仓库中的四张 CSV：

- `docs/database/物品.csv`
- `docs/database/食物.csv`
- `docs/database/装备.csv`
- `docs/database/配件.csv`

重新生成：

```bash
cd develop/item-browser
node tools/generate_static_data.js
```

## 本地测试

```bash
cd develop/item-browser
luajit tests/item_browser_core_spec.lua
luajit tests/static_data_spec.lua
luajit tests/main_smoke_spec.lua
luajit -b Script/main.lua /tmp/item-browser-main.luac
```

本地测试只能验证 Lua 逻辑、静态数据和语法。游戏内实际按钮位置、窗口渲染和运行时数据枚举需要在《废土快递》中验证。

## 当前限制

- 运行时完整物品枚举还需要进一步确认游戏内部数据类。
- 其他 Mod 新增物品只有在接入运行时 provider 后才能显示。
- 第一版 UI 使用 Unity IMGUI，视觉上偏工具窗口。
- `Preview.png` 尚未添加，发布到创意工坊前需要补齐封面。
