-- CRYPTO PRICE PLUGIN - 居中显示 + 请求计数 + 价格变化才写入

local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local TextWidget = require("ui/widget/textwidget")
local Font = require("ui/font")
local Screen = require("device").screen
local Blitbuffer = require("ffi/blitbuffer")
local BD = require("ui/bidi")
local _ = require("gettext")
local json = require("json")
local logger = require("logger")
local DataStorage = require("datastorage")

-- ============================================================
-- 默认配置
-- ============================================================
local DEFAULT_INTERVAL = 30
local DEFAULT_COINS = {"BTC_USDT", "ETH_USDT", "DOGE_USDT", "UNI_USDT"}

local ALL_COINS = {
    {display = "BTC", pair = "BTC_USDT"},
    {display = "ETH", pair = "ETH_USDT"},
    {display = "DOGE", pair = "DOGE_USDT"},
    {display = "UNI", pair = "UNI_USDT"},
    {display = "OP", pair = "OP_USDT"},
    {display = "LDO", pair = "LDO_USDT"},
    {display = "WLD", pair = "WLD_USDT"},
}

local CACHE_FILE = DataStorage:getDataDir() .. "/crypto_price.txt"

-- ============================================================
-- 全局状态
-- ============================================================
if G_crypto_data == nil then
    G_crypto_data = {
        text = "BTC: —  ETH: —  DOGE: —  UNI: —",
        enabled = true,
        interval = DEFAULT_INTERVAL,
        selected_coins = DEFAULT_COINS,
        timer_id = nil,
        fetch_in_progress = false,
        has_curl = false,
        curl_checked = false,
        is_suspended = false,
        is_document_closed = false,
        price_text = "",
        last_price_text = "",
        request_count = 0,
    }
end

-- ============================================================
-- 插件主类
-- ============================================================
local CryptoPlugin = WidgetContainer:extend{
    name = "crypto_plugin",
    is_doc_only = true,
}

function CryptoPlugin:init()
    self.ui.menu:registerToMainMenu(self)

    if not G_crypto_data.curl_checked then
        G_crypto_data.curl_checked = true
        local handle = io.popen('curl --version 2>/dev/null | head -1')
        if handle then
            local result = handle:read("*all")
            handle:close()
            if result and #result > 5 then
                G_crypto_data.has_curl = true
            end
        end
    end

    G_crypto_data.price_text = G_crypto_data.text
    G_crypto_data.last_price_text = G_crypto_data.text

    self.text_widget = TextWidget:new{
        text = BD.auto(self:getDisplayText():gsub(" ", "\u{00A0}")),
        face = Font:getFace("ffont", 19),
        fgcolor = Blitbuffer.COLOR_BLACK,
        padding = 0,
    }
    self.last_painted_text = ""
    self.top_padding = 28

    if self.ui and self.ui.view and self.ui.view.registerViewModule then
        self.ui.view:registerViewModule("crypto_overlay", self)
    end

    G_crypto_data.is_document_closed = false

    if G_crypto_data.enabled and not G_crypto_data.is_suspended then
        UIManager:scheduleIn(2, function()
            self:startLoop()
            self:doFetch()
        end)
    end
end

-- ============================================================
-- 获取显示文本（价格 + 计数）
-- ============================================================
function CryptoPlugin:getDisplayText()
    local count_str = " #" .. G_crypto_data.request_count
    return G_crypto_data.price_text .. count_str
end

-- ============================================================
-- paintTo：居中显示
-- ============================================================
function CryptoPlugin:paintTo(bb, x, y)
    if not G_crypto_data.enabled then
        return
    end
    
    local display_text = self:getDisplayText()
    
    if self.last_painted_text ~= display_text then
        self.text_widget:setText(BD.auto(display_text:gsub(" ", "\u{00A0}")))
        self.last_painted_text = display_text
    end
    
    -- ⭐ 居中显示
    local widget_width = self.text_widget:getSize().w or 300
    local screen_width = bb:getWidth()
    local center_x = (screen_width - widget_width) / 2
    
    self.text_widget:paintTo(bb, center_x + x, self.top_padding + y)
end

-- ============================================================
-- updateText：只有价格变化时才更新
-- ============================================================
function CryptoPlugin:updateText(new_text)
    if not new_text or new_text == "" then
        new_text = "BTC: —  ETH: —  DOGE: —  UNI: —"
    end
    
    -- 只有价格变化时才更新
    if new_text == G_crypto_data.last_price_text then
        return
    end
    
    G_crypto_data.last_price_text = new_text
    G_crypto_data.price_text = new_text
end

-- ============================================================
-- 读取缓存
-- ============================================================
function CryptoPlugin:readPriceFromCache()
    if G_crypto_data.is_document_closed then
        return
    end

    local file = io.open(CACHE_FILE, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()

    if not content or content == "" then return end

    local ok, data = pcall(json.decode, content)
    if not ok or type(data) ~= "table" then return end

    local price_map = {}
    for _, item in ipairs(data) do
        if item.currency_pair and item.last then
            price_map[item.currency_pair] = item.last
        end
    end

    local parts = {}
    for _, target in ipairs(G_crypto_data.selected_coins) do
        local symbol = target:gsub("_USDT", "")
        local price = price_map[target] or "—"
        table.insert(parts, symbol .. ": " .. price)
    end

    local new_text = table.concat(parts, "  ")
    self:updateText(new_text)
end

-- ============================================================
-- 发起请求
-- ============================================================
function CryptoPlugin:doFetch()
    if not G_crypto_data.enabled then return end
    if G_crypto_data.fetch_in_progress then return end
    if G_crypto_data.is_suspended then return end
    if G_crypto_data.is_document_closed then return end
    
    if not G_crypto_data.has_curl then
        self:updateText("curl不可用")
        return
    end

    G_crypto_data.fetch_in_progress = true

    -- ⭐ 请求计数 +1
    G_crypto_data.request_count = G_crypto_data.request_count + 1

    local cmd = 'curl -s -m 5 "https://api.gateio.ws/api/v4/spot/tickers" > "' .. CACHE_FILE .. '" 2>/dev/null &'
    os.execute(cmd)

    UIManager:scheduleIn(2.5, function()
        G_crypto_data.fetch_in_progress = false
        self:readPriceFromCache()
    end)
end

-- ============================================================
-- 定时器
-- ============================================================
function CryptoPlugin:startLoop()
    if G_crypto_data.is_document_closed then
        return
    end

    if self.timer_id then
        UIManager:unschedule(self.timer_id)
        self.timer_id = nil
    end

    if G_crypto_data.is_suspended then return end

    local interval = G_crypto_data.interval or DEFAULT_INTERVAL
    if interval < 5 then interval = 5 end

    local function loop()
        if G_crypto_data.enabled and not G_crypto_data.is_suspended and not G_crypto_data.is_document_closed then
            self:doFetch()
            self.timer_id = UIManager:scheduleIn(interval, loop)
        else
            self.timer_id = nil
        end
    end

    self.timer_id = UIManager:scheduleIn(interval, loop)
end

function CryptoPlugin:stopLoop()
    if self.timer_id then
        UIManager:unschedule(self.timer_id)
        self.timer_id = nil
    end
end

-- ============================================================
-- 息屏事件
-- ============================================================
function CryptoPlugin:onSuspend()
    G_crypto_data.is_suspended = true
    self:stopLoop()
end

-- ============================================================
-- 唤醒事件
-- ============================================================
function CryptoPlugin:onResume()
    G_crypto_data.is_suspended = false
    if G_crypto_data.enabled and not G_crypto_data.is_document_closed then
        UIManager:scheduleIn(1, function()
            self:startLoop()
            self:doFetch()
        end)
    end
end

-- ============================================================
-- 退出书籍
-- ============================================================
function CryptoPlugin:onCloseDocument()
    G_crypto_data.is_document_closed = true
    self:stopLoop()
    if self.ui and self.ui.view and self.ui.view.deregisterViewModule then
        self.ui.view:deregisterViewModule("crypto_overlay")
    end
end

-- ============================================================
-- 币种选择
-- ============================================================
function CryptoPlugin:buildCoinSelectionMenu()
    local sub_items = {}
    for _, coin in ipairs(ALL_COINS) do
        table.insert(sub_items, {
            text = coin.display,
            checked_func = function()
                for _, p in ipairs(G_crypto_data.selected_coins) do
                    if p == coin.pair then return true end
                end
                return false
            end,
            callback = function()
                local found = false
                for i, p in ipairs(G_crypto_data.selected_coins) do
                    if p == coin.pair then
                        table.remove(G_crypto_data.selected_coins, i)
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(G_crypto_data.selected_coins, coin.pair)
                end
                self:doFetch()
                UIManager:show(InfoMessage:new{
                    text = "✅ 币种已更新，共 " .. #G_crypto_data.selected_coins .. " 个"
                })
            end,
        })
    end
    return sub_items
end

-- ============================================================
-- 菜单
-- ============================================================
function CryptoPlugin:addToMainMenu(menu_items)
    menu_items.crypto_toggle = {
        text = _("💰 Crypto Price"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("开启币价"),
                checked_func = function()
                    return G_crypto_data.enabled
                end,
                callback = function()
                    G_crypto_data.enabled = not G_crypto_data.enabled
                    if G_crypto_data.enabled then
                        G_crypto_data.price_text = G_crypto_data.text
                        G_crypto_data.last_price_text = G_crypto_data.text
                        G_crypto_data.is_suspended = false
                        G_crypto_data.is_document_closed = false
                        G_crypto_data.request_count = 0
                        self:startLoop()
                        self:doFetch()
                        UIManager:show(InfoMessage:new{ text = "✅ 币价显示已开启" })
                    else
                        self:stopLoop()
                        G_crypto_data.price_text = "币价已关闭"
                        UIManager:show(InfoMessage:new{ text = "❌ 币价显示已关闭" })
                    end
                end,
            },
            {
                text = "刷新间隔",
                sub_item_table = {
                    {text = "10 秒", checked_func = function() return (G_crypto_data.interval or DEFAULT_INTERVAL) == 10 end, callback = function() G_crypto_data.interval = 10; if G_crypto_data.enabled then self:startLoop() end; UIManager:show(InfoMessage:new{ text = "⏱ 已设为 10 秒" }) end},
                    {text = "20 秒", checked_func = function() return (G_crypto_data.interval or DEFAULT_INTERVAL) == 20 end, callback = function() G_crypto_data.interval = 20; if G_crypto_data.enabled then self:startLoop() end; UIManager:show(InfoMessage:new{ text = "⏱ 已设为 20 秒" }) end},
                    {text = "30 秒", checked_func = function() return (G_crypto_data.interval or DEFAULT_INTERVAL) == 30 end, callback = function() G_crypto_data.interval = 30; if G_crypto_data.enabled then self:startLoop() end; UIManager:show(InfoMessage:new{ text = "⏱ 已设为 30 秒" }) end},
                    {text = "60 秒", checked_func = function() return (G_crypto_data.interval or DEFAULT_INTERVAL) == 60 end, callback = function() G_crypto_data.interval = 60; if G_crypto_data.enabled then self:startLoop() end; UIManager:show(InfoMessage:new{ text = "⏱ 已设为 60 秒" }) end},
                },
            },
            {
                text = "选择币种 (" .. #G_crypto_data.selected_coins .. "个)",
                sub_item_table = self:buildCoinSelectionMenu(),
            },
            {
                text = _("🔄 立即刷新"),
                callback = function()
                    if G_crypto_data and G_crypto_data.enabled then
                        G_crypto_data.fetch_in_progress = false
                        self:doFetch()
                        UIManager:show(InfoMessage:new{ text = "🔄 刷新" })
                    else
                        UIManager:show(InfoMessage:new{ text = "⚠️ 请先开启" })
                    end
                end,
            },
        },
    }
end

return CryptoPlugin