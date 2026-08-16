-- FINAL 10s STABLE VERSION (FULL REQUEST + JSON PARSE, NO CHANGE)

local Blitbuffer = require("ffi/blitbuffer")
local TextWidget = require("ui/widget/textwidget")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local BD = require("ui/bidi")
local Font = require("ui/font")
local datetime = require("datetime")
local Screen = require("device").screen
local UIManager = require("ui/uimanager")
local ReaderView = require("apps/reader/modules/readerview")
local json = require("json")

local _paintTo = ReaderView.paintTo
local screen_width = Screen:getWidth()

-- =========================
-- 配置：目标币种
-- =========================
local TARGET_COINS = {
    "BTC_USDT",
    "ETH_USDT",
    "DOGE_USDT",
    "UNI_USDT",
}

-- =========================
-- CACHE
-- =========================
G_crypto_data = G_crypto_data or {
    text = "BTC: —  ETH: —  DOGE: —  UNI: —",
    fetching = false,
}

-- =========================
-- FETCH：一次全量请求 + JSON 解析
-- =========================
local function fetch()
    if G_crypto_data.fetching then return end
    G_crypto_data.fetching = true

    local ok = pcall(function()
        local http = require("socket/http")
        local ltn12 = require("ltn12")
        http.TIMEOUT = 3

        local t = {}
        local _, code = http.request{
            url = "https://api.gateio.ws/api/v4/spot/tickers",
            sink = ltn12.sink.table(t)
        }

        if code == 200 then
            local raw = table.concat(t)
            local data = json.decode(raw)

            if type(data) == "table" then
                -- 构建价格查找表
                local price_map = {}
                for _, item in ipairs(data) do
                    local pair = item.currency_pair
                    if pair then
                        price_map[pair] = item.last or "—"
                    end
                end

                -- 组装显示（只显示价格，不含涨跌幅）
                local parts = {}
                for _, target in ipairs(TARGET_COINS) do
                    local symbol = target:gsub("_USDT", "")
                    local price = price_map[target] or "—"
                    table.insert(parts, symbol .. ": " .. price)
                end

                G_crypto_data.text = table.concat(parts, "  ")
            end
        end
    end)

    G_crypto_data.fetching = false
end

-- =========================
-- 30 SECOND LOOP
-- =========================
local function loop()
    fetch()
    UIManager:scheduleIn(30, loop)
end

UIManager:scheduleIn(1, loop)

-- =========================
-- UI ONLY (NO TIME)
-- =========================
ReaderView.paintTo = function(self, bb, x, y)
    _paintTo(self, bb, x, y)

    if self.render_mode ~= nil then return end

    local widget = TextWidget:new{
        text = BD.auto(G_crypto_data.text:gsub(" ", "\u{00A0}")),
        face = Font:getFace("ffont", 19),
        fgcolor = Blitbuffer.COLOR_BLACK,
        padding = 0,
    }

    local header = CenterContainer:new{
        dimen = { w = screen_width, h = widget:getSize().h + 28 },
        VerticalGroup:new{
            VerticalSpan:new{ width = 28 },
            HorizontalGroup:new{
                HorizontalSpan:new{ width = 10 },
                widget,
                HorizontalSpan:new{ width = 10 },
            },
        },
    }

    header:paintTo(bb, x, y)
end