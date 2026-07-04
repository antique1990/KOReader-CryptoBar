local Blitbuffer = require("ffi/blitbuffer")
local TextWidget = require("ui/widget/textwidget")
local CenterContainer = require("ui/widget/container/centercontainer")
local Font = require("ui/font")
local datetime = require("datetime")
local Screen = require("device").screen
local UIManager = require("ui/uimanager")
local ReaderView = require("apps/reader/modules/readerview")

local _paintTo = ReaderView.paintTo
local screen_width = Screen:getWidth()

-- =========================
-- STATE
-- =========================
G_crypto_data = G_crypto_data or {
    text = "  |  BTC: —  ETH: —  SOL: —",
    running = false,
}

-- =========================
-- SAFE FETCH (NO CONCURRENCY)
-- =========================
local function fetch()
    if G_crypto_data.running then return end
    G_crypto_data.running = true

    local ok = pcall(function()
        local http = require("socket.http")
        local ltn12 = require("ltn12")
        http.TIMEOUT = 2

        local function get(url)
            local t = {}
            http.request{
                url = url,
                sink = ltn12.sink.table(t)
            }
            return table.concat(t or "")
        end

        local function parse(b)
            return string.match(b or "", '"last"%s*:%s*"?(%d+%.?%d*)"?"') or "—"
        end

        G_crypto_data.text =
            string.format(
                "  |  BTC: %s  ETH: %s  SOL: %s",
                parse(get("https://api.gateio.ws/api/v4/spot/tickers?currency_pair=BTC_USDT")),
                parse(get("https://api.gateio.ws/api/v4/spot/tickers?currency_pair=ETH_USDT")),
                parse(get("https://api.gateio.ws/api/v4/spot/tickers?currency_pair=SOL_USDT"))
            )
    end)

    G_crypto_data.running = false
end

-- =========================
-- SINGLE TIMER LOOP (IMPORTANT FIX)
-- =========================
local function loop()
    fetch()
    UIManager:scheduleIn(5, loop)
end

UIManager:scheduleIn(1, loop)

-- =========================
-- UI ONLY
-- =========================
ReaderView.paintTo = function(self, bb, x, y)
    _paintTo(self, bb, x, y)

    if self.render_mode ~= nil then return end

    local time = datetime.secondsToHour(os.time())

    local widget = TextWidget:new{
        text = time .. G_crypto_data.text,
        face = Font:getFace("ffont", 19),
        fgcolor = Blitbuffer.COLOR_BLACK,
        padding = 0,
    }

    local header = CenterContainer:new{
        dimen = { w = screen_width, h = widget:getSize().h + 28 },
        widget,
    }

    header:paintTo(bb, x, y)
end