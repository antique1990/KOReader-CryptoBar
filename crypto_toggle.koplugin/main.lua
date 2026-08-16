-- CRYPTO PRICE PLUGIN - TOP 100 币种 + 最多选10个 + 换行显示

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
local MAX_SELECTED_COINS = 10

-- TOP 100 热门币种
local ALL_COINS = {
    {display = "BTC", pair = "BTC_USDT"},
    {display = "ETH", pair = "ETH_USDT"},
    {display = "DOGE", pair = "DOGE_USDT"},
    {display = "SOL", pair = "SOL_USDT"},
    {display = "XRP", pair = "XRP_USDT"},
    {display = "ADA", pair = "ADA_USDT"},
    {display = "AVAX", pair = "AVAX_USDT"},
    {display = "DOT", pair = "DOT_USDT"},
    {display = "LINK", pair = "LINK_USDT"},
    {display = "MATIC", pair = "MATIC_USDT"},
    {display = "LTC", pair = "LTC_USDT"},
    {display = "BCH", pair = "BCH_USDT"},
    {display = "NEAR", pair = "NEAR_USDT"},
    {display = "ATOM", pair = "ATOM_USDT"},
    {display = "ETC", pair = "ETC_USDT"},
    {display = "UNI", pair = "UNI_USDT"},
    {display = "OP", pair = "OP_USDT"},
    {display = "ARB", pair = "ARB_USDT"},
    {display = "APT", pair = "APT_USDT"},
    {display = "INJ", pair = "INJ_USDT"},
    {display = "ICP", pair = "ICP_USDT"},
    {display = "FIL", pair = "FIL_USDT"},
    {display = "RNDR", pair = "RNDR_USDT"},
    {display = "GRT", pair = "GRT_USDT"},
    {display = "VET", pair = "VET_USDT"},
    {display = "THETA", pair = "THETA_USDT"},
    {display = "FTM", pair = "FTM_USDT"},
    {display = "RUNE", pair = "RUNE_USDT"},
    {display = "ALGO", pair = "ALGO_USDT"},
    {display = "EGLD", pair = "EGLD_USDT"},
    {display = "HNT", pair = "HNT_USDT"},
    {display = "MNT", pair = "MNT_USDT"},
    {display = "CRO", pair = "CRO_USDT"},
    {display = "IMX", pair = "IMX_USDT"},
    {display = "ASTR", pair = "ASTR_USDT"},
    {display = "ROSE", pair = "ROSE_USDT"},
    {display = "MINA", pair = "MINA_USDT"},
    {display = "METIS", pair = "METIS_USDT"},
    {display = "WIF", pair = "WIF_USDT"},
    {display = "PEPE", pair = "PEPE_USDT"},
    {display = "SUI", pair = "SUI_USDT"},
    {display = "CKB", pair = "CKB_USDT"},
    {display = "JASMY", pair = "JASMY_USDT"},
    {display = "ORDI", pair = "ORDI_USDT"},
    {display = "AGIX", pair = "AGIX_USDT"},
    {display = "FET", pair = "FET_USDT"},
    {display = "BEAM", pair = "BEAM_USDT"},
    {display = "TRX", pair = "TRX_USDT"},
    {display = "MKR", pair = "MKR_USDT"},
    {display = "WLD", pair = "WLD_USDT"},
    {display = "AAVE", pair = "AAVE_USDT"},
    {display = "KAS", pair = "KAS_USDT"},
    {display = "BONK", pair = "BONK_USDT"},
    {display = "SAND", pair = "SAND_USDT"},
    {display = "GALA", pair = "GALA_USDT"},
    {display = "TIA", pair = "TIA_USDT"},
    {display = "FLOKI", pair = "FLOKI_USDT"},
    {display = "SEI", pair = "SEI_USDT"},
    {display = "ENA", pair = "ENA_USDT"},
    {display = "STRK", pair = "STRK_USDT"},
    {display = "PYTH", pair = "PYTH_USDT"},
    {display = "OSMO", pair = "OSMO_USDT"},
    {display = "JUP", pair = "JUP_USDT"},
    {display = "ONDO", pair = "ONDO_USDT"},
    {display = "ZRO", pair = "ZRO_USDT"},
    {display = "PENDLE", pair = "PENDLE_USDT"},
    {display = "W", pair = "W_USDT"},
    {display = "EOS", pair = "EOS_USDT"},
    {display = "XLM", pair = "XLM_USDT"},
    {display = "XMR", pair = "XMR_USDT"},
    {display = "ZEC", pair = "ZEC_USDT"},
    {display = "LDO", pair = "LDO_USDT"},
    {display = "TWT", pair = "TWT_USDT"},
    {display = "CAKE", pair = "CAKE_USDT"},
    {display = "AXS", pair = "AXS_USDT"},
    {display = "MANA", pair = "MANA_USDT"},
    {display = "QNT", pair = "QNT_USDT"},
    {display = "CHZ", pair = "CHZ_USDT"},
    {display = "1INCH", pair = "1INCH_USDT"},
    {display = "LUNC", pair = "LUNC_USDT"},
    {display = "FLOW", pair = "FLOW_USDT"},
    {display = "COMP", pair = "COMP_USDT"},
    {display = "NEO", pair = "NEO_USDT"},
    {display = "XTZ", pair = "XTZ_USDT"},
    {display = "IOTA", pair = "IOTA_USDT"},
    {display = "KAVA", pair = "KAVA_USDT"},
    {display = "BTT", pair = "BTT_USDT"},
    {display = "NOT", pair = "NOT_USDT"},
    {display = "DOGS", pair = "DOGS_USDT"},
    {display = "HMSTR", pair = "HMSTR_USDT"},
    {display = "TON", pair = "TON_USDT"},
    {display = "PEOPLE", pair = "PEOPLE_USDT"},
    {display = "MEME", pair = "MEME_USDT"},
    {display = "ALT", pair = "ALT_USDT"},
    {display = "PHA", pair = "PHA_USDT"},
    {display = "JTO", pair = "JTO_USDT"},
}

local DEFAULT_COINS = {"BTC_USDT", "ETH_USDT", "DOGE_USDT", "SOL_USDT"}
local CACHE_FILE = DataStorage:getDataDir() .. "/crypto_price.txt"

-- ============================================================
-- 根据 selected_coins 生成默认显示文本
-- ============================================================
local function generateDefaultText(coins)
    local parts = {}
    for _, target in ipairs(coins) do
        local symbol = target:gsub("_USDT", "")
        table.insert(parts, symbol .. ": —")
    end
    return table.concat(parts, "  ")
end

-- ============================================================
-- 全局状态
-- ============================================================
local saved_coins = G_reader_settings:readSetting("crypto_selected_coins", DEFAULT_COINS)

if G_crypto_data == nil then
    G_crypto_data = {
        text = generateDefaultText(saved_coins),
        enabled = true,
        interval = DEFAULT_INTERVAL,
        selected_coins = saved_coins,
        timer_id = nil,
        fetch_in_progress = false,
        has_curl = false,
        curl_checked = false,
        is_suspended = false,
        is_document_closed = false,
        price_text = generateDefaultText(saved_coins),
        last_price_text = "",
        request_count = 0,
    }
else
    -- 如果已有数据，同步更新 text 和 price_text
    if G_crypto_data.selected_coins then
        local default_text = generateDefaultText(G_crypto_data.selected_coins)
        G_crypto_data.text = default_text
        if not G_crypto_data.price_text or G_crypto_data.price_text == "" then
            G_crypto_data.price_text = default_text
        end
    end
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
    CryptoPlugin.instance = self

    -- 退出后重新进入，重置状态
    if G_crypto_data.is_document_closed then
        G_crypto_data.is_document_closed = false
        G_crypto_data.request_count = 0
        G_crypto_data.price_text = G_crypto_data.text
        G_crypto_data.last_price_text = G_crypto_data.text
        G_crypto_data.fetch_in_progress = false
    end

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

    if G_crypto_data.enabled and not G_crypto_data.is_suspended then
        UIManager:scheduleIn(2, function()
            self:startLoop()
            self:doFetch()
        end)
    end
end

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
    local num_coins = #G_crypto_data.selected_coins
    
    if num_coins <= 5 then
        if self.last_painted_text ~= display_text then
            self.text_widget:setText(BD.auto(display_text:gsub(" ", "\u{00A0}")))
            self.last_painted_text = display_text
        end
        local widget_width = self.text_widget:getSize().w or 300
        local screen_width = bb:getWidth()
        local center_x = (screen_width - widget_width) / 2
        self.text_widget:paintTo(bb, center_x + x, self.top_padding + y)
    else
        -- 超过5个分两行
        local selected_displays = {}
        for _, target in ipairs(G_crypto_data.selected_coins) do
            local symbol = target:gsub("_USDT", "")
            table.insert(selected_displays, symbol)
        end
        
        local price_data = {}
        for part in G_crypto_data.price_text:gmatch("[^%s]+") do
            table.insert(price_data, part)
        end
        
        local first_line_parts = {}
        local second_line_parts = {}
        local price_idx = 1
        
        for i, symbol in ipairs(selected_displays) do
            local price_part = ""
            for j = price_idx, #price_data do
                if price_data[j] == symbol .. ":" then
                    price_part = symbol .. ": " .. (price_data[j+1] or "—")
                    price_idx = j + 2
                    break
                end
            end
            if price_part == "" then
                price_part = symbol .. ": —"
            end
            
            if i <= 5 then
                table.insert(first_line_parts, price_part)
            else
                table.insert(second_line_parts, price_part)
            end
        end
        
        local first_line = table.concat(first_line_parts, "  ")
        local second_line = table.concat(second_line_parts, "  ") .. " #" .. G_crypto_data.request_count
        
        local widget1 = TextWidget:new{
            text = BD.auto(first_line:gsub(" ", "\u{00A0}")),
            face = Font:getFace("ffont", 19),
            fgcolor = Blitbuffer.COLOR_BLACK,
            padding = 0,
        }
        local w1 = widget1:getSize().w or 300
        local screen_width = bb:getWidth()
        local cx1 = (screen_width - w1) / 2
        widget1:paintTo(bb, cx1 + x, self.top_padding + y)
        
        local widget2 = TextWidget:new{
            text = BD.auto(second_line:gsub(" ", "\u{00A0}")),
            face = Font:getFace("ffont", 19),
            fgcolor = Blitbuffer.COLOR_BLACK,
            padding = 0,
        }
        local w2 = widget2:getSize().w or 300
        local cx2 = (screen_width - w2) / 2
        local line_height = (widget1:getSize().h or 30) + 4
        widget2:paintTo(bb, cx2 + x, self.top_padding + y + line_height)
        
        self.last_painted_text = first_line .. second_line
    end
end

-- ============================================================
-- updateText：只有价格变化时才更新
-- ============================================================
function CryptoPlugin:updateText(new_text)
    if not new_text or new_text == "" then
        new_text = generateDefaultText(G_crypto_data.selected_coins)
    end
    
    if new_text == G_crypto_data.last_price_text then
        return
    end
    
    G_crypto_data.last_price_text = new_text
    G_crypto_data.price_text = new_text
end

-- ============================================================
-- 读取缓存（带重试）
-- ============================================================
function CryptoPlugin:readPriceFromCache(retry_count)
    retry_count = retry_count or 0
    
    if not G_crypto_data.enabled then return end
    if G_crypto_data.is_document_closed then return end

    local file = io.open(CACHE_FILE, "r")
    if not file then
        if retry_count < 3 then
            UIManager:scheduleIn(1, function()
                self:readPriceFromCache(retry_count + 1)
            end)
        end
        return
    end
    
    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        if retry_count < 3 then
            UIManager:scheduleIn(1, function()
                self:readPriceFromCache(retry_count + 1)
            end)
        end
        return
    end

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
-- 发起请求（2.5秒后读取 + 重试）
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
-- 息屏/唤醒/退出
-- ============================================================
function CryptoPlugin:onSuspend()
    G_crypto_data.is_suspended = true
    self:stopLoop()
end

function CryptoPlugin:onResume()
    G_crypto_data.is_suspended = false
    if G_crypto_data.enabled and not G_crypto_data.is_document_closed then
        UIManager:scheduleIn(1, function()
            self:startLoop()
            self:doFetch()
        end)
    end
end

function CryptoPlugin:onCloseDocument()
    G_crypto_data.is_document_closed = true
    self:stopLoop()
    if self.ui and self.ui.view and self.ui.view.deregisterViewModule then
        self.ui.view:deregisterViewModule("crypto_overlay")
    end
end

-- ============================================================
-- 币种选择（保存到持久化存储）
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
                    if #G_crypto_data.selected_coins >= MAX_SELECTED_COINS then
                        UIManager:show(InfoMessage:new{
                            text = "⚠️ 最多选择 " .. MAX_SELECTED_COINS .. " 个币种"
                        })
                        return
                    end
                    table.insert(G_crypto_data.selected_coins, coin.pair)
                end
                
                -- 保存到持久化存储
                G_reader_settings:saveSetting("crypto_selected_coins", G_crypto_data.selected_coins)
                
                -- 更新显示文本
                G_crypto_data.text = generateDefaultText(G_crypto_data.selected_coins)
                G_crypto_data.price_text = G_crypto_data.text
                G_crypto_data.last_price_text = ""
                
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
        text = _("₿ Crypto Price"),
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
                text = "选择币种 (" .. #G_crypto_data.selected_coins .. "/" .. MAX_SELECTED_COINS .. "个)",
                sub_item_table = self:buildCoinSelectionMenu(),
            },
            {
                text = _("↻ 立即刷新"),
                callback = function()
                    if G_crypto_data and G_crypto_data.enabled then
                        G_crypto_data.fetch_in_progress = false
                        self:doFetch()
                        UIManager:show(InfoMessage:new{ text = "↻ 刷新" })
                    else
                        UIManager:show(InfoMessage:new{ text = "⚠️ 请先开启" })
                    end
                end,
            },
        },
    }
end

-- ============================================================
-- 全局切换函数（供 Quick Settings 调用）
-- ============================================================
function _G.toggleCryptoPrice()
    if not G_crypto_data then return end
    
    G_crypto_data.enabled = not G_crypto_data.enabled

    if G_crypto_data.enabled then
        G_crypto_data.price_text = G_crypto_data.text
        G_crypto_data.last_price_text = G_crypto_data.text
        G_crypto_data.is_suspended = false
        G_crypto_data.is_document_closed = false
        G_crypto_data.request_count = 0
        if CryptoPlugin and CryptoPlugin.instance then
            CryptoPlugin.instance:startLoop()
            CryptoPlugin.instance:doFetch()
        end
        UIManager:show(InfoMessage:new{ text = "✅ Crypto ON" })
    else
        if CryptoPlugin and CryptoPlugin.instance then
            CryptoPlugin.instance:stopLoop()
        end
        G_crypto_data.price_text = "币价已关闭"
        UIManager:show(InfoMessage:new{ text = "❌ Crypto OFF" })
    end
end

-- 暴露插件到全局
CryptoPlugin = CryptoPlugin

return CryptoPlugin