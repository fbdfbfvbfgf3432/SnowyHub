--!strict
-- Snowy Hub — kill/HS tracking fixed (aim-based + trigger-based both credit),
-- widget bumped to 300x300 so nothing clips. Aim cframe-locked, mm2 universal.

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local CoreGui             = game:GetService("CoreGui")
local SoundService        = game:GetService("SoundService")
local ContentProvider     = game:GetService("ContentProvider")
local Workspace           = game:GetService("Workspace")
local Lighting            = game:GetService("Lighting")
local Stats               = game:GetService("Stats")
local HttpService         = game:GetService("HttpService")
local VirtualUser         = game:GetService("VirtualUser")
local TeleportService     = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player    = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local camera    = Workspace.CurrentCamera

pcall(function() RunService:UnbindFromRenderStep("SnowyFov") end)
pcall(function() RunService:UnbindFromRenderStep("SnowyAim") end)
pcall(function() RunService:UnbindFromRenderStep("SnowyEsp") end)
pcall(function() RunService:UnbindFromRenderStep("SnowyTrigger") end)
pcall(function()
    local parent = (gethui and gethui() or CoreGui)
    local old = parent:FindFirstChild("SnowyHubUI"); if old then old:Destroy() end
    local oldSplash = parent:FindFirstChild("KyokaSplash"); if oldSplash then oldSplash:Destroy() end
end)

local HUB_TITLE   = "Snowy Hub"
local HUB_SUB     = "藍染惣右介"
local HUB_TAG     = "V1.0"
local SPLASH_TIME = 8
local AUDIO_VOL   = 0.6
local HUB_NAME    = "Snowy Hub"
local HUB_VERSION = "V1.2"
local LOGO_ASPECT = 0.8325

local ACCENT  = Color3.fromRGB(124, 108, 255)
local ACCENT2 = Color3.fromRGB(42, 212, 255)
local GLASS   = Color3.fromRGB(207, 201, 255)
local BG_DARK = Color3.fromRGB(4, 3, 8)

local C_BG   = Color3.fromRGB(10, 7, 16)
local C_SIDE = Color3.fromRGB(14, 9, 20)
local C_LINE = Color3.fromRGB(50, 22, 70)
local C_DIM  = Color3.fromRGB(138, 122, 160)
local C_ACC  = Color3.fromRGB(170, 90, 255)
local C_GLOW = Color3.fromRGB(200, 130, 255)
local C_CARD = Color3.fromRGB(22, 12, 34)

local rng = Random.new()
local S = { cardRefreshes = {} }

local function getGuiParent()
    if gethui then local ok, h = pcall(gethui); if ok and h then return h end end
    if RunService:IsStudio() then return playerGui end
    return CoreGui
end

local function getCustom(name)
    if not (getcustomasset and isfile) then return "" end
    local okIs, exists = pcall(isfile, name)
    if not (okIs and exists) then return "" end
    local ok, asset = pcall(getcustomasset, name)
    if ok and asset then return asset end
    return ""
end

local BANNER_ID  = getCustom("banner.png")
if BANNER_ID == "" then BANNER_ID = getCustom("logo.png") end
local AUDIO_PATH = getCustom("splash.mp3")

local function makeGlassShard(parent, w, h)
    local s = Instance.new("Frame")
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.Size = UDim2.fromOffset(w, h)
    s.BackgroundColor3 = Color3.new(1, 1, 1)
    s.BorderSizePixel = 0
    s.ZIndex = 900
    s.Parent = parent
    Instance.new("UICorner", s).CornerRadius = UDim.new(0, 2)
    local g = Instance.new("UIGradient")
    g.Rotation = 140
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GLASS),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(17, 15, 28)),
        ColorSequenceKeypoint.new(0.66, BG_DARK),
        ColorSequenceKeypoint.new(1, ACCENT),
    })
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(0.18, 0.05),
        NumberSequenceKeypoint.new(0.7, 0.05),
        NumberSequenceKeypoint.new(1, 0.45),
    })
    g.Parent = s
    local st = Instance.new("UIStroke")
    st.Color = ACCENT; st.Transparency = 0.45; st.Thickness = 1; st.Parent = s
    return s, st
end

local function flyShard(shard, stroke, tx, ty, spin, dur, delay)
    task.delay(delay, function()
        if not shard or not shard.Parent then return end
        TweenService:Create(shard, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.fromOffset(tx, ty), Rotation = spin, BackgroundTransparency = 1,
        }):Play()
        if stroke and stroke.Parent then
            TweenService:Create(stroke, TweenInfo.new(dur * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
        end
    end)
end

local function spawnGridShatter(parent, rect, onDone)
    local cols, rows = 10, 7
    local cw, ch = rect.w / cols, rect.h / rows
    local pieces = {}
    for c = 0, cols - 1 do
        for r = 0, rows - 1 do
            local pieceW = cw * (0.95 + math.random() * 0.25)
            local pieceH = ch * (0.95 + math.random() * 0.25)
            local px = rect.x + c * cw + cw / 2 + (math.random() - 0.5) * cw * 0.3
            local py = rect.y + r * ch + ch / 2 + (math.random() - 0.5) * ch * 0.3
            local shard, stroke = makeGlassShard(parent, pieceW, pieceH)
            shard.Position = UDim2.fromOffset(px, py)
            shard.Rotation = (math.random() - 0.5) * 12
            shard.BackgroundTransparency = 0.05
            local dx = (px - (rect.x + rect.w / 2)) / (rect.w / 2)
            pieces[#pieces+1] = { frame = shard, stroke = stroke, x = px, y = py, dx = dx }
        end
    end
    for _, s in ipairs(pieces) do
        local delay = math.abs(s.dx) * 0.12 + rng:NextNumber(0, 0.06)
        local dur = rng:NextNumber(0.6, 0.9)
        local hDrift = rng:NextNumber(-0.35, 0.35) + s.dx * 0.35
        local tx = s.x + hDrift * rect.w * 0.5
        local ty = s.y + rng:NextNumber(0.9, 1.4) * rect.h
        local spin = rng:NextNumber(-320, 320)
        flyShard(s.frame, s.stroke, tx, ty, spin, dur, delay)
    end
    task.delay(1.2, function()
        for _, s in ipairs(pieces) do pcall(function() s.frame:Destroy() end) end
        if onDone then onDone() end
    end)
    return pieces
end

-- ============================================================
-- SPLASH
-- ============================================================
local function buildSplash()
    local splashGui = Instance.new("ScreenGui")
    splashGui.Name = "KyokaSplash"
    splashGui.ResetOnSpawn = false
    splashGui.IgnoreGuiInset = true
    splashGui.DisplayOrder = 999
    splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    splashGui.Parent = getGuiParent()

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = BG_DARK
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = splashGui

    for i = 1, 26 do
        local disc = Instance.new("Frame")
        disc.AnchorPoint = Vector2.new(0.5, 0.5)
        disc.Position = UDim2.fromScale(0.5, 0.45)
        disc.Size = UDim2.fromScale(1.3 * i / 26, 1.3 * i / 26)
        disc.BackgroundColor3 = Color3.fromRGB(20, 15, 44)
        disc.BackgroundTransparency = 1 - 0.14 * (1 - (i - 1) / 26)
        disc.BorderSizePixel = 0
        disc.ZIndex = 1
        disc.Parent = bg
        Instance.new("UICorner", disc).CornerRadius = UDim.new(1, 0)
        Instance.new("UIAspectRatioConstraint", disc).AspectRatio = 1
    end

    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(0.5, 0.42)
    box.Size = UDim2.fromOffset(280, 280)
    box.BackgroundTransparency = 1
    box.ZIndex = 10
    box.Parent = bg
    local boxScale = Instance.new("UIScale")
    boxScale.Scale = 0.9
    boxScale.Parent = box

    local CORE_D = 120
    for i = 1, 14 do
        local d = CORE_D + 116 * (i / 14)
        local alpha = 0.11 * (1 - (i - 1) / 14) ^ 1.6
        local g = Instance.new("Frame")
        g.AnchorPoint = Vector2.new(0.5, 0.5)
        g.Position = UDim2.fromScale(0.5, 0.5)
        g.Size = UDim2.fromOffset(d, d)
        g.BackgroundColor3 = ACCENT
        g.BackgroundTransparency = 1 - alpha
        g.BorderSizePixel = 0
        g.ZIndex = 8
        g.Parent = box
        Instance.new("UICorner", g).CornerRadius = UDim.new(1, 0)
    end

    local R = CORE_D / 2
    local focal = Vector2.new(0.38, 0.32) * CORE_D
    local center = Vector2.new(R, R)
    local stops = {
        {0, Color3.new(1,1,1)},{0.06, Color3.new(1,1,1)},{0.16, GLASS},
        {0.42, ACCENT},{0.75, Color3.fromRGB(42, 28, 112)},{1, Color3.fromRGB(14, 10, 36)},
    }
    local function sampleStops(t)
        for i = 2, #stops do
            if t <= stops[i][1] then
                local a, b = stops[i-1], stops[i]
                return a[2]:Lerp(b[2], math.clamp((t - a[1]) / math.max(b[1] - a[1], 1e-4), 0, 1))
            end
        end
        return stops[#stops][2]
    end
    local rg = (Vector2.new(CORE_D, CORE_D) - focal).Magnitude
    local tMax = (R + (focal - center).Magnitude) / rg
    local core = Instance.new("Frame")
    core.AnchorPoint = Vector2.new(0.5, 0.5)
    core.Position = UDim2.fromScale(0.5, 0.5)
    core.Size = UDim2.fromOffset(CORE_D, CORE_D)
    core.BackgroundTransparency = 1
    core.ZIndex = 10
    core.Parent = box
    for i = 0, 17 do
        local f = 1 - i / 18
        local pos = focal:Lerp(center, f)
        local c = Instance.new("Frame")
        c.AnchorPoint = Vector2.new(0.5, 0.5)
        c.Position = UDim2.fromOffset(pos.X, pos.Y)
        c.Size = UDim2.fromOffset(R * f * 2, R * f * 2)
        c.BackgroundColor3 = sampleStops(f * tMax)
        c.BorderSizePixel = 0
        c.ZIndex = 10 + i
        c.Parent = core
        Instance.new("UICorner", c).CornerRadius = UDim.new(1, 0)
    end

    local ringLayer = Instance.new("Frame")
    ringLayer.AnchorPoint = Vector2.new(0.5, 0.5)
    ringLayer.Position = UDim2.fromScale(0.5, 0.5)
    ringLayer.Size = UDim2.fromScale(1, 1)
    ringLayer.BackgroundTransparency = 1
    ringLayer.ZIndex = 9
    ringLayer.Parent = box

    local RING_THICK = 2
    local function makeRing(radius, count, dashed, color, transparency)
        local segs = {}
        for i = 1, count do
            local s = Instance.new("Frame")
            s.AnchorPoint = Vector2.new(0, 0.5)
            s.Size = UDim2.fromOffset(2, RING_THICK)
            s.BackgroundColor3 = color
            s.BackgroundTransparency = transparency
            s.BorderSizePixel = 0
            s.ZIndex = 9
            s.Parent = ringLayer
            segs[i] = s
        end
        return { Segs = segs, Radius = radius, Dashed = dashed, Base = transparency }
    end

    local ring1 = makeRing(75, 48, true, GLASS, 0.1)
    local ring2 = makeRing(85, 96, false, ACCENT2, 0.25)

    local c72, s72 = math.cos(math.rad(72)), math.sin(math.rad(72))
    local c20, s20 = math.cos(math.rad(20)), math.sin(math.rad(20))
    local c68, s68 = math.cos(math.rad(68)), math.sin(math.rad(68))
    local function proj1(a) local x, y = math.cos(a), math.sin(a); return x, y*c72, y*s72 end
    local function proj2(a)
        local x, y = math.cos(a), math.sin(a)
        local y1, z1 = y*c20, y*s20
        return x*c68 + z1*s68, y1, -x*s68 + z1*c68
    end

    local half = 140
    local function layoutRing(ring, proj, spin)
        local n = #ring.Segs
        local r = ring.Radius
        local arc = (ring.Dashed and 0.5 or 1) * math.pi * 2 / n
        for i, seg in ipairs(ring.Segs) do
            local a0 = (i - 1) / n * math.pi * 2 + spin
            local x0, y0, z0 = proj(a0)
            local x1, y1 = proj(a0 + arc)
            local px0, py0 = half + x0 * r, half + y0 * r
            local dx, dy = (x1 - x0) * r, (y1 - y0) * r
            seg.Position = UDim2.fromOffset(px0, py0)
            seg.Size = UDim2.fromOffset(math.sqrt(dx*dx + dy*dy) + (ring.Dashed and 0.6 or 1.2), RING_THICK)
            seg.Rotation = math.deg(math.atan2(dy, dx))
            seg.ZIndex = z0 >= 0 and 30 or 6
            seg.BackgroundTransparency = ring.Base + (z0 < 0 and 0.35 or 0)
        end
    end

    local orbImage = Instance.new("ImageLabel")
    orbImage.AnchorPoint = Vector2.new(0.5, 0.5)
    orbImage.Position = UDim2.fromScale(0.5, 0.5)
    orbImage.Size = UDim2.fromOffset(96, 96)
    orbImage.BackgroundTransparency = 1
    orbImage.Image = BANNER_ID
    orbImage.ImageTransparency = 1
    orbImage.ScaleType = Enum.ScaleType.Fit
    orbImage.ZIndex = 50
    orbImage.Parent = box

    local kanjiRow = Instance.new("Frame")
    kanjiRow.AnchorPoint = Vector2.new(0.5, 0.5)
    kanjiRow.Position = UDim2.new(0.5, 0, 0.5, 120)
    kanjiRow.Size = UDim2.fromOffset(240, 50)
    kanjiRow.BackgroundTransparency = 1
    kanjiRow.ZIndex = 60
    kanjiRow.Parent = bg

    local kanji = {}
    for i, ch in ipairs({"鏡","花","水","月"}) do
        local x = (i - 2.5) * 46
        local function glyph(z, color, transp)
            local g = Instance.new("TextLabel")
            g.AnchorPoint = Vector2.new(0.5, 0.5)
            g.Position = UDim2.new(0.5, x, 0.5, 0)
            g.Size = UDim2.fromOffset(60, 60)
            g.BackgroundTransparency = 1
            g.Text = ch
            g.Font = Enum.Font.GothamBold
            g.TextSize = 36
            g.TextColor3 = color
            g.TextTransparency = transp
            g.ZIndex = z
            g.Parent = kanjiRow
            return g
        end
        local halo = glyph(59, ACCENT, 1)
        local hs = Instance.new("UIStroke"); hs.Color = ACCENT; hs.Thickness = 3; hs.Transparency = 1; hs.Parent = halo
        local main = glyph(61, Color3.new(1, 1, 1), 1)
        local ms = Instance.new("UIStroke"); ms.Color = ACCENT; ms.Thickness = 1; ms.Transparency = 1; ms.Parent = main
        kanji[i] = { Main = main, MainStroke = ms, Halo = halo, HaloStroke = hs }
    end

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.new(0.5, 0, 0.5, 178)
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = string.upper(HUB_TITLE):gsub(".", "%0 "):gsub("%s+$", "")
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = GLASS
    title.TextTransparency = 1
    title.ZIndex = 60
    title.Parent = bg

    local subLbl = Instance.new("TextLabel")
    subLbl.AnchorPoint = Vector2.new(0.5, 0.5)
    subLbl.Position = UDim2.new(0.5, 0, 0.5, 200)
    subLbl.Size = UDim2.new(1, 0, 0, 16)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = HUB_SUB
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.TextSize = 12
    subLbl.TextColor3 = ACCENT
    subLbl.TextTransparency = 1
    subLbl.ZIndex = 60
    subLbl.Parent = bg

    local piste = Instance.new("Frame")
    piste.AnchorPoint = Vector2.new(0.5, 0.5)
    piste.Position = UDim2.new(0.5, 0, 0.5, 226)
    piste.Size = UDim2.fromOffset(280, 3)
    piste.BackgroundColor3 = Color3.fromRGB(27, 24, 48)
    piste.BorderSizePixel = 0
    piste.ZIndex = 60
    piste.Parent = bg
    Instance.new("UICorner", piste).CornerRadius = UDim.new(1, 0)

    local jauge = Instance.new("Frame")
    jauge.Size = UDim2.fromScale(0, 1)
    jauge.BackgroundColor3 = Color3.new(1, 1, 1)
    jauge.BorderSizePixel = 0
    jauge.ZIndex = 61
    jauge.Parent = piste
    Instance.new("UICorner", jauge).CornerRadius = UDim.new(1, 0)
    local jGrad = Instance.new("UIGradient")
    jGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(91, 73, 230)),
        ColorSequenceKeypoint.new(0.5, ACCENT),
        ColorSequenceKeypoint.new(1, ACCENT2),
    })
    jGrad.Parent = jauge

    local statusLbl = Instance.new("TextLabel")
    statusLbl.AnchorPoint = Vector2.new(0.5, 0.5)
    statusLbl.Position = UDim2.new(0.5, 0, 0.5, 248)
    statusLbl.Size = UDim2.new(1, 0, 0, 14)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Initializing"
    statusLbl.Font = Enum.Font.Code
    statusLbl.TextSize = 11
    statusLbl.TextColor3 = Color3.fromRGB(108, 106, 130)
    statusLbl.TextTransparency = 1
    statusLbl.ZIndex = 60
    statusLbl.Parent = bg

    local tagLbl = Instance.new("TextLabel")
    tagLbl.AnchorPoint = Vector2.new(1, 1)
    tagLbl.Position = UDim2.new(1, -20, 1, -20)
    tagLbl.Size = UDim2.fromOffset(200, 14)
    tagLbl.BackgroundTransparency = 1
    tagLbl.Text = HUB_TAG
    tagLbl.Font = Enum.Font.Gotham
    tagLbl.TextSize = 10
    tagLbl.TextColor3 = Color3.fromRGB(108, 106, 130)
    tagLbl.TextXAlignment = Enum.TextXAlignment.Right
    tagLbl.TextTransparency = 1
    tagLbl.Parent = bg

    local audio = nil
    if AUDIO_PATH ~= "" then
        local ok, snd = pcall(function()
            local s = Instance.new("Sound")
            s.Name = "SplashAudio"
            s.SoundId = AUDIO_PATH
            s.Volume = AUDIO_VOL
            s.Looped = false
            s.Parent = SoundService
            return s
        end)
        if ok and snd then
            audio = snd
            task.spawn(function()
                pcall(function() ContentProvider:PreloadAsync({ snd }) end)
                task.wait(0.2)
                pcall(function() snd.TimePosition = 0; snd:Play() end)
            end)
        end
    end

    local function burstOrb()
        local vp = splashGui.AbsoluteSize
        local cx = vp.X * 0.5
        local cy = vp.Y * 0.42
        for _ = 1, 40 do
            local sz = 14 + math.random() * 46
            local shard, stroke = makeGlassShard(bg, sz, sz * (0.5 + math.random()))
            shard.Position = UDim2.fromOffset(cx, cy)
            local a = math.random() * math.pi * 2
            local d = 200 + math.random() * 520
            local tx = cx + math.cos(a) * d
            local ty = cy + math.sin(a) * d
            local spin = (math.random() - 0.5) * 720
            task.delay(0, function()
                if not shard.Parent then return end
                TweenService:Create(shard, TweenInfo.new(0.9, Enum.EasingStyle.Quint), {
                    Position = UDim2.fromOffset(tx, ty), Rotation = spin, BackgroundTransparency = 1,
                }):Play()
                if stroke and stroke.Parent then
                    TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
                end
            end)
            task.delay(0.95, function() pcall(function() shard:Destroy() end) end)
        end
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromScale(0.5, 0.42)
        ring.Size = UDim2.fromOffset(240, 240)
        ring.BackgroundColor3 = ACCENT
        ring.BackgroundTransparency = 0.82
        ring.BorderSizePixel = 0
        ring.ZIndex = 88
        ring.Parent = bg
        Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
        local rs = Instance.new("UIStroke"); rs.Color = Color3.new(1, 1, 1); rs.Thickness = 2; rs.Parent = ring
        TweenService:Create(ring, TweenInfo.new(0.55), { Size = UDim2.fromOffset(280, 280), BackgroundTransparency = 1 }):Play()
        TweenService:Create(rs, TweenInfo.new(0.55), { Transparency = 1, Thickness = 6 }):Play()
        task.delay(0.6, function() pcall(function() ring:Destroy() end) end)
    end

    S.splash = {
        gui = splashGui, bg = bg, box = box, boxScale = boxScale,
        ring1 = ring1, ring2 = ring2, proj1 = proj1, proj2 = proj2,
        layoutRing = layoutRing, orbImage = orbImage, kanji = kanji,
        title = title, subLbl = subLbl, jauge = jauge,
        statusLbl = statusLbl, tagLbl = tagLbl, audio = audio,
        burstOrb = burstOrb,
    }
end

-- ============================================================
-- STATE
-- ============================================================
local feat = {
    aim_on = false, aim_tb = false, aim_wall = true,
    aim_fov = 300,
    aim_smooth = 0.35,
    aim_part = "Head",
    aim_mode = "Closest",
    esp_on = false, esp_box = true, esp_name = true,
    esp_dist = true, esp_tracer = false, esp_tb = false,
    esp_color = Color3.fromRGB(170, 90, 255),
    esp_tracer_from = "Bottom",
    fov_on = false, fov_val = 90,
    sky_color = nil,
    key_aim = Enum.KeyCode.K,
    key_esp = Enum.KeyCode.N,
    key_fov = Enum.KeyCode.J,
    key_trig = Enum.KeyCode.L,
    key_hub = Enum.KeyCode.RightShift,
    trig_on = false, trig_delay = 0.03, trig_fov = 12,
    trig_tb = true, trig_wall = false,
}

local extra = {
    fullbright = false, nofog = false, clock_time = 14, time_lock = false,
    watermark = true, crosshair = false,
    crosshair_color = Color3.fromRGB(255, 255, 255), crosshair_size = 10,
    anti_afk = true, chat_log = false, widget = true,
}

local sessionStats = {
    kills = 0, deaths = 0, headshots = 0, bodyshots = 0, misses = 0,
    shots = 0, killstreak = 0, best_streak = 0, start = tick(),
    damage_dealt = 0, last_kill = 0,
}

-- health memory: [plr] = last known HP
local healthTrack = {}
-- dmgCredit: [plr] = { at = tick, head = bool }
local dmgCredit = {}

local _savedLighting = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
}

local function isAlive(plr)
    local ch = plr.Character
    if not ch then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getTargetPart(plr, partName)
    local ch = plr.Character
    if not ch then return nil end
    if partName and ch:FindFirstChild(partName) then return ch:FindFirstChild(partName) end
    return ch:FindFirstChild("Head")
        or ch:FindFirstChild("HumanoidRootPart")
        or ch:FindFirstChild("UpperTorso")
        or ch:FindFirstChild("Torso")
end

-- ============================================================
-- HUB SHELL
-- ============================================================
local function buildHubShell()
    local BANNER_HUB = getCustom("gojo.jpg")
    local LOGO_HUB = getCustom("logo.png")
    if LOGO_HUB == "" then LOGO_HUB = getCustom("logo.jpg") end

    local hubGui = Instance.new("ScreenGui")
    hubGui.Name = "SnowyHubUI"
    hubGui.ResetOnSpawn = false
    hubGui.IgnoreGuiInset = true
    hubGui.DisplayOrder = 997
    hubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    hubGui.Parent = getGuiParent()

    local W, H = 920, 620
    local SIDE, HEAD, FOOT = 250, 62, 34

    local win = Instance.new("CanvasGroup")
    win.Name = "Window"
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = C_BG
    win.BorderSizePixel = 0
    win.GroupTransparency = 1
    win.Active = true
    win.Visible = false
    win.Parent = hubGui
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 16)

    local scale = Instance.new("UIScale")
    scale.Scale = 0.7
    scale.Parent = win

    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.fromScale(1, 1)
    bgFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = win
    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new(Color3.fromRGB(28, 14, 46), Color3.fromRGB(8, 5, 14))
    bgGrad.Rotation = 35
    bgGrad.Parent = bgFrame

    local side = Instance.new("Frame")
    side.Size = UDim2.new(0, SIDE, 1, -FOOT)
    side.BackgroundColor3 = C_SIDE
    side.BackgroundTransparency = 0.1
    side.BorderSizePixel = 0
    side.Parent = win
    local sideLine = Instance.new("Frame")
    sideLine.Size = UDim2.new(0, 1, 1, 0)
    sideLine.Position = UDim2.new(1, -1, 0, 0)
    sideLine.BackgroundColor3 = C_LINE
    sideLine.BorderSizePixel = 0
    sideLine.Parent = side

    local banner = Instance.new("ImageLabel")
    banner.Size = UDim2.new(1, 0, 0, 170)
    banner.BackgroundColor3 = Color3.fromRGB(24, 10, 40)
    banner.BorderSizePixel = 0
    banner.Image = BANNER_HUB
    banner.ScaleType = Enum.ScaleType.Crop
    banner.Parent = side

    local fade = Instance.new("Frame")
    fade.Size = UDim2.new(1, 0, 0, 110)
    fade.Position = UDim2.new(0, 0, 1, -110)
    fade.BackgroundColor3 = C_SIDE
    fade.BorderSizePixel = 0
    fade.Parent = banner
    local fadeGrad = Instance.new("UIGradient")
    fadeGrad.Rotation = 90
    fadeGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
    fadeGrad.Parent = fade

    local sideLogo = Instance.new("ImageLabel")
    sideLogo.Position = UDim2.fromOffset(14, 100)
    sideLogo.Size = UDim2.fromOffset(math.floor(58 * LOGO_ASPECT), 58)
    sideLogo.BackgroundTransparency = 1
    sideLogo.Image = LOGO_HUB
    sideLogo.ScaleType = Enum.ScaleType.Fit
    sideLogo.Parent = banner

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Position = UDim2.fromOffset(74, 100)
    nameLbl.Size = UDim2.fromOffset(168, 28)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 21
    nameLbl.TextColor3 = Color3.new(1, 1, 1)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Text = HUB_NAME
    nameLbl.Parent = banner

    local subLbl = Instance.new("TextLabel")
    subLbl.BackgroundTransparency = 1
    subLbl.Position = UDim2.fromOffset(74, 132)
    subLbl.Size = UDim2.fromOffset(168, 20)
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.TextSize = 14
    subLbl.TextColor3 = C_ACC
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Text = HUB_SUB
    subLbl.Parent = banner

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 68)
    card.Position = UDim2.new(0, 0, 1, -68)
    card.BackgroundTransparency = 1
    card.Parent = side
    local cardLine = Instance.new("Frame")
    cardLine.Size = UDim2.new(1, 0, 0, 1)
    cardLine.BackgroundColor3 = C_LINE
    cardLine.BorderSizePixel = 0
    cardLine.Parent = card

    local avatar = Instance.new("ImageLabel")
    avatar.Position = UDim2.fromOffset(14, 16)
    avatar.Size = UDim2.fromOffset(40, 40)
    avatar.BackgroundColor3 = Color3.fromRGB(30, 12, 46)
    avatar.BorderSizePixel = 0
    avatar.Parent = card
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
    local avStroke = Instance.new("UIStroke")
    avStroke.Color = C_ACC; avStroke.Thickness = 1.5; avStroke.Parent = avatar
    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and content then avatar.Image = content end
    end)

    local userLbl = Instance.new("TextLabel")
    userLbl.BackgroundTransparency = 1
    userLbl.Position = UDim2.fromOffset(64, 16)
    userLbl.Size = UDim2.fromOffset(174, 20)
    userLbl.Font = Enum.Font.GothamMedium
    userLbl.TextSize = 15
    userLbl.TextColor3 = Color3.new(1, 1, 1)
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    userLbl.Text = player.Name
    userLbl.Parent = card

    local roleLbl = Instance.new("TextLabel")
    roleLbl.BackgroundTransparency = 1
    roleLbl.Position = UDim2.fromOffset(64, 38)
    roleLbl.Size = UDim2.fromOffset(174, 14)
    roleLbl.Font = Enum.Font.GothamBold
    roleLbl.TextSize = 10
    roleLbl.TextColor3 = C_ACC
    roleLbl.TextXAlignment = Enum.TextXAlignment.Left
    roleLbl.Text = "Member"
    roleLbl.Parent = card

    local head = Instance.new("Frame")
    head.Name = "Header"
    head.Size = UDim2.new(1, -SIDE, 0, HEAD)
    head.Position = UDim2.fromOffset(SIDE, 0)
    head.BackgroundTransparency = 1
    head.Active = true
    head.Parent = win
    local headLine = Instance.new("Frame")
    headLine.Size = UDim2.new(1, 0, 0, 1)
    headLine.Position = UDim2.new(0, 0, 1, -1)
    headLine.BackgroundColor3 = C_LINE
    headLine.BorderSizePixel = 0
    headLine.Parent = head

    local titleBox = Instance.new("Frame")
    titleBox.AnchorPoint = Vector2.new(0, 0.5)
    titleBox.Position = UDim2.new(0, 26, 0.5, 0)
    titleBox.Size = UDim2.fromOffset(0, 26)
    titleBox.AutomaticSize = Enum.AutomaticSize.X
    titleBox.BackgroundTransparency = 1
    titleBox.Parent = head
    local titleList = Instance.new("UIListLayout")
    titleList.FillDirection = Enum.FillDirection.Horizontal
    titleList.VerticalAlignment = Enum.VerticalAlignment.Center
    titleList.Padding = UDim.new(0, 8)
    titleList.Parent = titleBox

    local hubTitle = Instance.new("TextLabel")
    hubTitle.BackgroundTransparency = 1
    hubTitle.Size = UDim2.fromOffset(0, 26)
    hubTitle.Font = Enum.Font.GothamBold
    hubTitle.TextSize = 22
    hubTitle.TextColor3 = Color3.new(1, 1, 1)
    hubTitle.TextXAlignment = Enum.TextXAlignment.Left
    hubTitle.Text = HUB_NAME
    hubTitle.AutomaticSize = Enum.AutomaticSize.X
    hubTitle.Parent = titleBox

    local hubTag = Instance.new("TextLabel")
    hubTag.BackgroundTransparency = 1
    hubTag.Size = UDim2.fromOffset(0, 26)
    hubTag.Font = Enum.Font.GothamBold
    hubTag.TextSize = 12
    hubTag.TextColor3 = C_DIM
    hubTag.TextXAlignment = Enum.TextXAlignment.Left
    hubTag.Text = HUB_VERSION
    hubTag.AutomaticSize = Enum.AutomaticSize.X
    hubTag.Parent = titleBox

    local statusDot = Instance.new("Frame")
    statusDot.AnchorPoint = Vector2.new(1, 0.5)
    statusDot.Position = UDim2.new(1, -68, 0.5, 0)
    statusDot.Size = UDim2.fromOffset(10, 10)
    statusDot.BackgroundColor3 = C_ACC
    statusDot.BorderSizePixel = 0
    statusDot.Parent = head
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -18, 0.5, 0)
    closeBtn.Size = UDim2.fromOffset(32, 32)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Color3.fromRGB(200, 190, 220)
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = head

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.fromOffset(SIDE, HEAD)
    content.Size = UDim2.new(1, -SIDE, 1, -(HEAD + FOOT))
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = win

    S.hubGui = hubGui
    S.win = win
    S.scale = scale
    S.side = side
    S.head = head
    S.closeBtn = closeBtn
    S.content = content
    S.W = W; S.H = H; S.SIDE = SIDE; S.HEAD = HEAD; S.FOOT = FOOT
    S.pages = {}
    S.tabButtons = {}
    S.activePage = nil
end

-- ============================================================
-- HELPERS
-- ============================================================
local function makePage(name)
    local page = Instance.new("Frame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = S.content
    S.pages[name] = page
    return page
end

local function showPage(name)
    for n, p in pairs(S.pages) do p.Visible = (n == name) end
    S.activePage = name
    for tabName, entry in pairs(S.tabButtons) do
        entry.setActive(tabName == name)
    end
end

local function makeStack(parent, canvasHeight)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(0, 78)
    scroll.Size = UDim2.new(1, 0, 1, -78)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = C_ACC
    scroll.CanvasSize = UDim2.fromOffset(0, canvasHeight or 1000)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = parent

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 24)
    pad.PaddingRight = UDim.new(0, 24)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 24)
    pad.Parent = scroll

    return scroll, list
end

local function makePageHeader(page, title, subtitle)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(24, 18)
    t.Size = UDim2.fromOffset(400, 28)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 22
    t.TextColor3 = Color3.new(1, 1, 1)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title
    t.Parent = page

    local s = Instance.new("TextLabel")
    s.BackgroundTransparency = 1
    s.Position = UDim2.fromOffset(24, 48)
    s.Size = UDim2.fromOffset(400, 20)
    s.Font = Enum.Font.GothamMedium
    s.TextSize = 13
    s.TextColor3 = C_DIM
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Text = subtitle
    s.Parent = page
end

local function makeSection(parent, label, order)
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, 24)
    holder.LayoutOrder = order
    holder.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextColor3 = C_DIM
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = holder
    return holder
end

local makeCard, makeSlider, makeDropdown, makeKeybind, makeBigColorGrid, makeActionButton

makeCard = function(parent, title, subtitle, getFn, setFn, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 66)
    c.BackgroundColor3 = C_CARD
    c.BackgroundTransparency = 0.15
    c.BorderSizePixel = 0
    c.LayoutOrder = order or 0
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke")
    cs.Color = C_LINE; cs.Thickness = 1; cs.Transparency = 0.3; cs.Parent = c

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(18, 11)
    t.Size = UDim2.new(1, -140, 0, 22)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.TextColor3 = Color3.new(1, 1, 1)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title
    t.Parent = c

    local s = Instance.new("TextLabel")
    s.BackgroundTransparency = 1
    s.Position = UDim2.fromOffset(18, 33)
    s.Size = UDim2.new(1, -140, 0, 18)
    s.Font = Enum.Font.GothamMedium
    s.TextSize = 12
    s.TextColor3 = C_DIM
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Text = subtitle
    s.Parent = c

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -18, 0.5, 0)
    btn.Size = UDim2.fromOffset(86, 30)
    btn.BackgroundColor3 = C_ACC
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = C_ACC
    btn.Text = "Off"
    btn.AutoButtonColor = false
    btn.Parent = c
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local bs = Instance.new("UIStroke")
    bs.Color = C_ACC; bs.Thickness = 1.5; bs.Transparency = 0.3; bs.Parent = btn

    local function refresh()
        local on = getFn()
        btn.Text = on and "On" or "Off"
        btn.TextColor3 = on and Color3.new(1,1,1) or C_ACC
        btn.BackgroundTransparency = on and 0.15 or 1
        bs.Transparency = on and 0.15 or 0.3
    end
    btn.MouseButton1Click:Connect(function() setFn(not getFn()); refresh() end)
    refresh()
    table.insert(S.cardRefreshes, refresh)
    return c
end

makeSlider = function(parent, title, min, max, init, setFn, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 62)
    c.BackgroundColor3 = C_CARD
    c.BackgroundTransparency = 0.15
    c.BorderSizePixel = 0
    c.LayoutOrder = order or 0
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke")
    cs.Color = C_LINE; cs.Thickness = 1; cs.Transparency = 0.3; cs.Parent = c

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(18, 10)
    t.Size = UDim2.new(1, -110, 0, 20)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.TextColor3 = Color3.new(1,1,1)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title
    t.Parent = c

    local val = Instance.new("TextLabel")
    val.BackgroundTransparency = 1
    val.AnchorPoint = Vector2.new(1, 0)
    val.Position = UDim2.new(1, -18, 0, 10)
    val.Size = UDim2.fromOffset(90, 20)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 14
    val.TextColor3 = C_ACC
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Text = tostring(init)
    val.Parent = c

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(18, 42)
    bar.Size = UDim2.new(1, -36, 0, 8)
    bar.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
    bar.BorderSizePixel = 0
    bar.Parent = c
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale((init - min) / (max - min), 1)
    fill.BackgroundColor3 = C_ACC
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        fill.Size = UDim2.fromScale(rel, 1)
        local v = math.floor((min + (max - min) * rel) * 100 + 0.5) / 100
        val.Text = tostring(v)
        setFn(v)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return c
end

makeDropdown = function(parent, title, options, getFn, setFn, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 62)
    c.BackgroundColor3 = C_CARD
    c.BackgroundTransparency = 0.15
    c.BorderSizePixel = 0
    c.LayoutOrder = order or 0
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke")
    cs.Color = C_LINE; cs.Thickness = 1; cs.Transparency = 0.3; cs.Parent = c

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(18, 8)
    t.Size = UDim2.new(1, -36, 0, 20)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.TextColor3 = Color3.new(1,1,1)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title
    t.Parent = c

    local btn = Instance.new("TextButton")
    btn.Position = UDim2.fromOffset(18, 32)
    btn.Size = UDim2.new(1, -36, 0, 24)
    btn.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextColor3 = C_ACC
    btn.AutoButtonColor = false
    btn.Text = tostring(getFn()) .. "  v"
    btn.Parent = c
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local open = false
    local menu
    btn.MouseButton1Click:Connect(function()
        if open and menu then menu:Destroy(); menu = nil; open = false; return end
        open = true
        menu = Instance.new("Frame")
        menu.Position = UDim2.fromOffset(18, 58)
        menu.Size = UDim2.new(1, -36, 0, #options * 24)
        menu.BackgroundColor3 = Color3.fromRGB(22, 12, 34)
        menu.BorderSizePixel = 0
        menu.ZIndex = 20
        menu.Parent = c
        Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)
        local ms = Instance.new("UIStroke"); ms.Color = C_ACC; ms.Thickness = 1; ms.Transparency = 0.4; ms.Parent = menu
        for i, opt in ipairs(options) do
            local item = Instance.new("TextButton")
            item.Position = UDim2.fromOffset(0, (i-1)*24)
            item.Size = UDim2.new(1, 0, 0, 24)
            item.BackgroundTransparency = 1
            item.Font = Enum.Font.GothamMedium
            item.TextSize = 13
            item.TextColor3 = Color3.fromRGB(220, 210, 240)
            item.Text = "  " .. tostring(opt)
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.AutoButtonColor = false
            item.ZIndex = 21
            item.Parent = menu
            item.MouseEnter:Connect(function() item.TextColor3 = Color3.new(1,1,1) end)
            item.MouseLeave:Connect(function() item.TextColor3 = Color3.fromRGB(220, 210, 240) end)
            item.MouseButton1Click:Connect(function()
                setFn(opt); btn.Text = tostring(opt) .. "  v"
                menu:Destroy(); menu = nil; open = false
            end)
        end
    end)
    return c
end

makeKeybind = function(parent, title, getFn, setFn, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 50)
    c.BackgroundColor3 = C_CARD
    c.BackgroundTransparency = 0.15
    c.BorderSizePixel = 0
    c.LayoutOrder = order or 0
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke")
    cs.Color = C_LINE; cs.Thickness = 1; cs.Transparency = 0.3; cs.Parent = c

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(18, 0)
    t.Size = UDim2.new(1, -140, 1, 0)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.TextColor3 = Color3.new(1,1,1)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title
    t.Parent = c

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -18, 0.5, 0)
    btn.Size = UDim2.fromOffset(100, 28)
    btn.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = C_ACC
    btn.AutoButtonColor = false
    btn.Text = getFn().Name
    btn.Parent = c
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new("UIStroke"); bs.Color = C_ACC; bs.Thickness = 1; bs.Transparency = 0.4; bs.Parent = btn

    local capturing = false
    btn.MouseButton1Click:Connect(function()
        capturing = true; btn.Text = "..."; btn.TextColor3 = C_GLOW
    end)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not capturing then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            setFn(input.KeyCode); btn.Text = input.KeyCode.Name
            btn.TextColor3 = C_ACC; capturing = false
        end
    end)
    return c
end

makeBigColorGrid = function(parent, getFn, setFn, label, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 216)
    c.BackgroundColor3 = C_CARD
    c.BackgroundTransparency = 0.15
    c.BorderSizePixel = 0
    c.LayoutOrder = order or 0
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke")
    cs.Color = C_LINE; cs.Thickness = 1; cs.Transparency = 0.3; cs.Parent = c

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(18, 10)
    t.Size = UDim2.new(1, -110, 0, 20)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.TextColor3 = Color3.new(1,1,1)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = label or "Color"
    t.Parent = c

    local preview = Instance.new("Frame")
    preview.AnchorPoint = Vector2.new(1, 0)
    preview.Position = UDim2.new(1, -18, 0, 10)
    preview.Size = UDim2.fromOffset(70, 20)
    preview.BackgroundColor3 = getFn() or Color3.new(1,1,1)
    preview.BorderSizePixel = 0
    preview.Parent = c
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)
    local ps = Instance.new("UIStroke"); ps.Color = C_LINE; ps.Thickness = 1; ps.Transparency = 0.3; ps.Parent = preview

    local grid = Instance.new("Frame")
    grid.Position = UDim2.fromOffset(18, 40)
    grid.Size = UDim2.new(1, -36, 0, 168)
    grid.BackgroundTransparency = 1
    grid.Parent = c

    local gl = Instance.new("UIGridLayout")
    gl.CellSize = UDim2.fromOffset(30, 22)
    gl.CellPadding = UDim2.fromOffset(5, 5)
    gl.SortOrder = Enum.SortOrder.LayoutOrder
    gl.Parent = grid

    local palette = {}
    for i = 0, 5 do local v = 1 - i*0.18; table.insert(palette, Color3.new(v,v,v)) end
    for row = 0, 2 do
        local sat, val = ({1,1,0.6})[row+1], ({1,0.75,1})[row+1]
        for i = 0, 7 do table.insert(palette, Color3.fromHSV(i/8, sat, val)) end
    end
    for _, col in ipairs({
        Color3.fromRGB(170,90,255), Color3.fromRGB(120,60,220),
        Color3.fromRGB(42,212,255), Color3.fromRGB(255,80,140),
        Color3.fromRGB(255,180,60), Color3.fromRGB(0,230,180),
    }) do table.insert(palette, col) end

    for i, col in ipairs(palette) do
        local sw = Instance.new("TextButton")
        sw.BackgroundColor3 = col
        sw.BorderSizePixel = 0
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.LayoutOrder = i
        sw.Parent = grid
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 4)
        sw.MouseButton1Click:Connect(function() setFn(col); preview.BackgroundColor3 = col end)
    end
    return c
end

makeActionButton = function(parent, lbl, action, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 46)
    c.BackgroundColor3 = C_CARD
    c.BackgroundTransparency = 0.15
    c.BorderSizePixel = 0
    c.LayoutOrder = order or 0
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke")
    cs.Color = C_LINE; cs.Thickness = 1; cs.Transparency = 0.3; cs.Parent = c

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.Position = UDim2.fromScale(0.5, 0.5)
    btn.Size = UDim2.new(1, -22, 1, -12)
    btn.BackgroundColor3 = C_ACC
    btn.BackgroundTransparency = 0.15
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = lbl
    btn.AutoButtonColor = false
    btn.Parent = c
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        btn.Text = "Working..."
        task.spawn(function()
            local ok = pcall(action)
            btn.Text = ok and (lbl .. " Ok") or (lbl .. " Failed")
            task.wait(1.2)
            btn.Text = lbl
        end)
    end)
    return c
end

-- ============================================================
-- CONFIG + SERVER
-- ============================================================
local CONFIG_FILE = "snowy_config.json"

local function serializeFeat()
    local out = {}
    for k, v in pairs(feat) do
        if typeof(v) == "Color3" then
            out[k] = { __t = "Color3", R = v.R, G = v.G, B = v.B }
        elseif typeof(v) == "EnumItem" then
            out[k] = { __t = "Enum", Name = v.Name, Type = tostring(v.EnumType) }
        else
            out[k] = v
        end
    end
    return out
end

local function deserializeFeat(data)
    for k, v in pairs(data) do
        if type(v) == "table" and v.__t == "Color3" then
            feat[k] = Color3.new(v.R, v.G, v.B)
        elseif type(v) == "table" and v.__t == "Enum" then
            local enumType = v.Type:gsub("Enum%.", "")
            local ok, item = pcall(function() return Enum[enumType][v.Name] end)
            if ok then feat[k] = item end
        else
            feat[k] = v
        end
    end
end

local function saveConfig()
    if not writefile then return false end
    return (pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(serializeFeat())) end))
end

local function loadConfig()
    if not (isfile and readfile) then return false end
    if not isfile(CONFIG_FILE) then return false end
    return (pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        deserializeFeat(data)
    end))
end

local function serverHop()
    task.spawn(function()
        local ok, result = pcall(function()
            local req = request or http_request or (syn and syn.request) or (http and http.request)
            if not req then return nil end
            local resp = req({ Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET" })
            if not resp then return nil end
            local body = resp.Body or resp.body
            if type(body) ~= "string" then return nil end
            return HttpService:JSONDecode(body)
        end)
        if not ok or not result or not result.data then return end
        for _, server in ipairs(result.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player) end)
                return
            end
        end
    end)
end

local function rejoin()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
end

-- ============================================================
-- PAGES
-- ============================================================
local function buildHomePage()
    local p = makePage("Home")
    makePageHeader(p, "Home", "Aim Driver: cframe (universal)")
    local scroll = makeStack(p, 1600)

    local ord = 0
    local function N() ord = ord + 1; return ord end

    makeCard(scroll, "Aimbot (K)", "Toggle On = Locks Closest Target",
        function() return feat.aim_on end, function(v) feat.aim_on = v end, N())
    makeDropdown(scroll, "Target Mode", {"Closest","Nearest","Lowest HP"},
        function() return feat.aim_mode end, function(v) feat.aim_mode = v end, N())
    makeCard(scroll, "Through Walls", "Ignore Line-Of-Sight Raycast",
        function() return feat.aim_wall end, function(v) feat.aim_wall = v end, N())
    makeCard(scroll, "Team Check", "Skip Teammates",
        function() return feat.aim_tb end, function(v) feat.aim_tb = v end, N())
    makeSlider(scroll, "Aim Fov (Px)", 20, 800, feat.aim_fov,
        function(v) feat.aim_fov = v end, N())
    makeSlider(scroll, "Smoothing (0 = snap)", 0, 0.9, feat.aim_smooth,
        function(v) feat.aim_smooth = v end, N())
    makeDropdown(scroll, "Target Part", {"Head","HumanoidRootPart","UpperTorso","Torso"},
        function() return feat.aim_part end, function(v) feat.aim_part = v end, N())

    makeSection(scroll, "Triggerbot", N())

    makeCard(scroll, "Triggerbot (L)", "Auto-Fire When Crosshair On Enemy",
        function() return feat.trig_on end, function(v) feat.trig_on = v end, N())
    makeCard(scroll, "Trigger · Team Check", "Skip Teammates",
        function() return feat.trig_tb end, function(v) feat.trig_tb = v end, N())
    makeCard(scroll, "Trigger · Through Walls", "Fire Even If Wall Between",
        function() return feat.trig_wall end, function(v) feat.trig_wall = v end, N())
    makeSlider(scroll, "Trigger Delay (s)", 0, 0.5, feat.trig_delay,
        function(v) feat.trig_delay = v end, N())

    makeSection(scroll, "Visuals", N())

    makeCard(scroll, "Player Esp (N)", "Box + Name + Distance",
        function() return feat.esp_on end, function(v) feat.esp_on = v end, N())
    makeCard(scroll, "Boxes", "Draw Body Boxes",
        function() return feat.esp_box end, function(v) feat.esp_box = v end, N())
    makeCard(scroll, "Names", "Draw Player Names",
        function() return feat.esp_name end, function(v) feat.esp_name = v end, N())
    makeCard(scroll, "Distance", "Show Meters To Target",
        function() return feat.esp_dist end, function(v) feat.esp_dist = v end, N())
    makeCard(scroll, "Tracers", "Line From Screen Edge",
        function() return feat.esp_tracer end, function(v) feat.esp_tracer = v end, N())
    makeDropdown(scroll, "Tracer Origin", {"Bottom","Center","Mouse"},
        function() return feat.esp_tracer_from end, function(v) feat.esp_tracer_from = v end, N())
    makeCard(scroll, "Esp Team Check", "Skip Teammates",
        function() return feat.esp_tb end, function(v) feat.esp_tb = v end, N())
    makeBigColorGrid(scroll, function() return feat.esp_color end,
        function(c) feat.esp_color = c end, "Esp Color", N())
end

local function buildBindsPage()
    local p = makePage("Binds")
    makePageHeader(p, "Binds", "Click a box, press a key to rebind")
    local scroll = makeStack(p, 700)

    local ord = 0
    local function N() ord = ord + 1; return ord end

    makeKeybind(scroll, "Toggle Aimbot", function() return feat.key_aim end,
        function(k) feat.key_aim = k end, N())
    makeKeybind(scroll, "Toggle ESP", function() return feat.key_esp end,
        function(k) feat.key_esp = k end, N())
    makeKeybind(scroll, "Toggle Fov", function() return feat.key_fov end,
        function(k) feat.key_fov = k end, N())
    makeKeybind(scroll, "Toggle Trigger", function() return feat.key_trig end,
        function(k) feat.key_trig = k end, N())
    makeKeybind(scroll, "Toggle Hub UI", function() return feat.key_hub end,
        function(k) feat.key_hub = k end, N())
end

local function buildCustomizePage()
    local p = makePage("Customize")
    makePageHeader(p, "Customize", "World + Colors")
    local scroll = makeStack(p, 700)

    local ord = 0
    local function N() ord = ord + 1; return ord end

    makeCard(scroll, "Fov Extender (J)", "Override Camera Fov",
        function() return feat.fov_on end,
        function(v) feat.fov_on = v; if not v then camera.FieldOfView = S.savedFov end end, N())
    makeSlider(scroll, "Fov Value", 70, 120, feat.fov_val,
        function(v) feat.fov_val = v; if feat.fov_on then camera.FieldOfView = v end end, N())

    makeSection(scroll, "Sky Color", N())
    makeBigColorGrid(scroll, function() return feat.sky_color end,
        function(c)
            feat.sky_color = c
            for _, s in ipairs(Lighting:GetChildren()) do
                if s:IsA("Sky") then s:Destroy() end
            end
            local atm = Lighting:FindFirstChild("SnowyAtmo") or Instance.new("Atmosphere")
            atm.Name = "SnowyAtmo"; atm.Density = 0.3
            atm.Color = c; atm.Decay = c
            atm.Glare = 0; atm.Haze = 0; atm.Parent = Lighting
            local cc = Lighting:FindFirstChild("SnowyCC") or Instance.new("ColorCorrectionEffect")
            cc.Name = "SnowyCC"
            cc.TintColor = c:Lerp(Color3.new(1,1,1), 0.6)
            cc.Saturation = -0.05
            cc.Parent = Lighting
        end, "Sky", N())
end

local function buildVisualPage()
    local p = makePage("Visual")
    makePageHeader(p, "Visual", "Cosmetics + Hud")
    local scroll = makeStack(p, 1100)

    local ord = 0
    local function N() ord = ord + 1; return ord end

    makeCard(scroll, "Stats Widget", "Live K/D/HS% Panel",
        function() return extra.widget end, function(v) extra.widget = v end, N())
    makeCard(scroll, "Fullbright", "Brighter Ambient Lighting",
        function() return extra.fullbright end,
        function(v)
            extra.fullbright = v
            if v then
                Lighting.Ambient = Color3.fromRGB(178, 178, 178)
                Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
                Lighting.Brightness = 3
            else
                Lighting.Ambient = _savedLighting.Ambient
                Lighting.OutdoorAmbient = _savedLighting.OutdoorAmbient
                Lighting.Brightness = _savedLighting.Brightness
            end
        end, N())
    makeCard(scroll, "No Fog", "Clear Atmosphere",
        function() return extra.nofog end,
        function(v)
            extra.nofog = v
            if v then
                Lighting.FogEnd = 1e6; Lighting.FogStart = 0
            else
                Lighting.FogEnd = _savedLighting.FogEnd; Lighting.FogStart = _savedLighting.FogStart
            end
        end, N())
    makeCard(scroll, "Lock Time", "Freeze World Clock",
        function() return extra.time_lock end,
        function(v) extra.time_lock = v; if v then Lighting.ClockTime = extra.clock_time end end, N())
    makeSlider(scroll, "Time Of Day (0-24)", 0, 24, extra.clock_time,
        function(v) extra.clock_time = v; if extra.time_lock then Lighting.ClockTime = v end end, N())

    makeSection(scroll, "Hud", N())
    makeCard(scroll, "Watermark", "Fps/Ping/Time Display",
        function() return extra.watermark end, function(v) extra.watermark = v end, N())
    makeCard(scroll, "Custom Crosshair", "Draw Your Own Cross",
        function() return extra.crosshair end, function(v) extra.crosshair = v end, N())
    makeSlider(scroll, "Crosshair Size", 4, 30, extra.crosshair_size,
        function(v) extra.crosshair_size = v end, N())
    makeBigColorGrid(scroll, function() return extra.crosshair_color end,
        function(c) extra.crosshair_color = c end, "Crosshair Color", N())

    makeSection(scroll, "Session", N())
    makeActionButton(scroll, "Reset Session Stats", function()
        sessionStats.kills = 0
        sessionStats.deaths = 0
        sessionStats.headshots = 0
        sessionStats.bodyshots = 0
        sessionStats.misses = 0
        sessionStats.shots = 0
        sessionStats.killstreak = 0
        sessionStats.best_streak = 0
        sessionStats.start = tick()
    end, N())
end

local function buildUtilityPage()
    local p = makePage("Utility")
    makePageHeader(p, "Utility", "Session + Server + Players")
    local scroll = makeStack(p, 1100)

    local ord = 0
    local function N() ord = ord + 1; return ord end

    makeCard(scroll, "Anti-Afk", "Prevent Idle Kick",
        function() return extra.anti_afk end, function(v) extra.anti_afk = v end, N())
    makeCard(scroll, "Chat Logger", "Save Chat To File",
        function() return extra.chat_log end, function(v) extra.chat_log = v end, N())

    makeSection(scroll, "Config", N())
    makeActionButton(scroll, "Save Config", saveConfig, N())
    makeActionButton(scroll, "Load Config", loadConfig, N())

    makeSection(scroll, "Server", N())
    makeActionButton(scroll, "Rejoin Server", rejoin, N())
    makeActionButton(scroll, "Server Hop", serverHop, N())

    makeSection(scroll, "Session Info", N())
    local statsCard = Instance.new("Frame")
    statsCard.Size = UDim2.new(1, 0, 0, 62)
    statsCard.BackgroundColor3 = C_CARD
    statsCard.BackgroundTransparency = 0.15
    statsCard.BorderSizePixel = 0
    statsCard.LayoutOrder = N()
    statsCard.Parent = scroll
    Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 10)
    local ss = Instance.new("UIStroke")
    ss.Color = C_LINE; ss.Thickness = 1; ss.Transparency = 0.3; ss.Parent = statsCard
    local statsLbl = Instance.new("TextLabel")
    statsLbl.BackgroundTransparency = 1
    statsLbl.Position = UDim2.fromOffset(18, 0)
    statsLbl.Size = UDim2.new(1, -36, 1, 0)
    statsLbl.Font = Enum.Font.Code
    statsLbl.TextSize = 14
    statsLbl.TextColor3 = C_ACC
    statsLbl.TextXAlignment = Enum.TextXAlignment.Left
    statsLbl.Text = string.format("Players: %d  |  Uptime: 0S", #Players:GetPlayers())
    statsLbl.Parent = statsCard

    local sessionStart = tick()
    task.spawn(function()
        while true do
            task.wait(1)
            local secs = math.floor(tick() - sessionStart)
            statsLbl.Text = string.format("Players: %d  |  Uptime: %dS", #Players:GetPlayers(), secs)
        end
    end)

    makeSection(scroll, "Players", N())

    local playersHolder = Instance.new("Frame")
    playersHolder.Size = UDim2.new(1, 0, 0, 0)
    playersHolder.AutomaticSize = Enum.AutomaticSize.Y
    playersHolder.BackgroundColor3 = C_CARD
    playersHolder.BackgroundTransparency = 0.15
    playersHolder.BorderSizePixel = 0
    playersHolder.LayoutOrder = N()
    playersHolder.Parent = scroll
    Instance.new("UICorner", playersHolder).CornerRadius = UDim.new(0, 10)
    local phStroke = Instance.new("UIStroke")
    phStroke.Color = C_LINE; phStroke.Thickness = 1; phStroke.Transparency = 0.3; phStroke.Parent = playersHolder
    local phList = Instance.new("UIListLayout")
    phList.Padding = UDim.new(0, 2); phList.SortOrder = Enum.SortOrder.Name; phList.Parent = playersHolder
    local phPad = Instance.new("UIPadding")
    phPad.PaddingTop = UDim.new(0, 8); phPad.PaddingBottom = UDim.new(0, 8)
    phPad.PaddingLeft = UDim.new(0, 8); phPad.PaddingRight = UDim.new(0, 8)
    phPad.Parent = playersHolder

    local playerRows = {}
    local function makeRow(name)
        local row = Instance.new("Frame")
        row.Name = name
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.Parent = playersHolder

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.fromOffset(0, 0)
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = name
        lbl.Parent = row

        local tp = Instance.new("TextButton")
        tp.AnchorPoint = Vector2.new(1, 0.5)
        tp.Position = UDim2.new(1, -74, 0.5, 0)
        tp.Size = UDim2.fromOffset(66, 22)
        tp.BackgroundColor3 = C_ACC
        tp.BackgroundTransparency = 0.3
        tp.BorderSizePixel = 0
        tp.Font = Enum.Font.GothamBold
        tp.TextSize = 12
        tp.TextColor3 = Color3.new(1,1,1)
        tp.Text = "Tp"
        tp.AutoButtonColor = false
        tp.Parent = row
        Instance.new("UICorner", tp).CornerRadius = UDim.new(0, 6)
        tp.MouseButton1Click:Connect(function()
            local target = Players:FindFirstChild(name)
            local ch = target and target.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            local myCh = player.Character
            local myRoot = myCh and myCh:FindFirstChild("HumanoidRootPart")
            if root and myRoot then
                myRoot.CFrame = root.CFrame + Vector3.new(0, 3, -6)
            end
        end)

        local track = Instance.new("TextButton")
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, -4, 0.5, 0)
        track.Size = UDim2.fromOffset(66, 22)
        track.BackgroundColor3 = C_ACC
        track.BackgroundTransparency = 0.3
        track.BorderSizePixel = 0
        track.Font = Enum.Font.GothamBold
        track.TextSize = 12
        track.TextColor3 = Color3.new(1,1,1)
        track.Text = "Track"
        track.AutoButtonColor = false
        track.Parent = row
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 6)
        track.MouseButton1Click:Connect(function()
            local target = Players:FindFirstChild(name)
            local ch = target and target.Character
            local part = ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
            if part then S.currentTarget = part end
        end)
        return row
    end

    local function refreshPlayerList()
        local seen = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            seen[plr.Name] = true
            if not playerRows[plr.Name] then
                playerRows[plr.Name] = makeRow(plr.Name)
            end
        end
        for name, row in pairs(playerRows) do
            if not seen[name] then
                row:Destroy(); playerRows[name] = nil
            end
        end
    end
    Players.PlayerAdded:Connect(function() refreshPlayerList() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.2); refreshPlayerList() end)
    refreshPlayerList()
end

-- ============================================================
-- TABS + FOOTER
-- ============================================================
local function buildTabs()
    local sideTabs = Instance.new("Frame")
    sideTabs.Position = UDim2.fromOffset(0, 178)
    sideTabs.Size = UDim2.new(1, 0, 1, -(178 + 68))
    sideTabs.BackgroundTransparency = 1
    sideTabs.Parent = S.side
    local sideList = Instance.new("UIListLayout")
    sideList.Padding = UDim.new(0, 5); sideList.SortOrder = Enum.SortOrder.LayoutOrder; sideList.Parent = sideTabs
    local sidePad = Instance.new("UIPadding")
    sidePad.PaddingLeft = UDim.new(0, 12); sidePad.PaddingRight = UDim.new(0, 12)
    sidePad.PaddingTop = UDim.new(0, 8); sidePad.Parent = sideTabs

    local function makeTab(name, order, pageName)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(28, 14, 42)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 14
        btn.TextColor3 = C_DIM
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Text = "  " .. name
        btn.AutoButtonColor = false
        btn.LayoutOrder = order
        btn.Parent = sideTabs
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local bar = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(0, 0.5)
        bar.Position = UDim2.new(0, 0, 0.5, 0)
        bar.Size = UDim2.fromOffset(3, 20)
        bar.BackgroundColor3 = C_ACC
        bar.BackgroundTransparency = 1
        bar.BorderSizePixel = 0
        bar.Parent = btn
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local function setActive(on)
            btn.TextColor3 = on and Color3.new(1,1,1) or C_DIM
            btn.BackgroundTransparency = on and 0.85 or 1
            bar.BackgroundTransparency = on and 0 or 1
        end
        btn.MouseButton1Click:Connect(function() showPage(pageName) end)
        btn.MouseEnter:Connect(function()
            if S.activePage ~= pageName then btn.TextColor3 = Color3.fromRGB(210, 195, 240) end
        end)
        btn.MouseLeave:Connect(function()
            if S.activePage ~= pageName then btn.TextColor3 = C_DIM end
        end)
        S.tabButtons[pageName] = { button = btn, setActive = setActive }
    end

    makeTab("Home",      1, "Home")
    makeTab("Binds",     2, "Binds")
    makeTab("Customize", 3, "Customize")
    makeTab("Visual",    4, "Visual")
    makeTab("Utility",   5, "Utility")
    showPage("Home")
end

local function buildFooter()
    local foot = Instance.new("Frame")
    foot.Size = UDim2.new(1, 0, 0, S.FOOT)
    foot.Position = UDim2.new(0, 0, 1, -S.FOOT)
    foot.BackgroundColor3 = Color3.fromRGB(7, 5, 11)
    foot.BackgroundTransparency = 0.2
    foot.BorderSizePixel = 0
    foot.Parent = S.win

    local fl = Instance.new("Frame")
    fl.Size = UDim2.new(1, 0, 0, 1)
    fl.BackgroundColor3 = C_LINE
    fl.BorderSizePixel = 0
    fl.Parent = foot

    local flText = Instance.new("TextLabel")
    flText.BackgroundTransparency = 1
    flText.Position = UDim2.new(0, S.SIDE + 26, 0.5, -8)
    flText.Size = UDim2.fromOffset(260, 16)
    flText.Font = Enum.Font.GothamMedium
    flText.TextSize = 11
    flText.TextColor3 = C_DIM
    flText.TextXAlignment = Enum.TextXAlignment.Left
    flText.Text = "Snowy Hub  ·  " .. HUB_VERSION
    flText.Parent = foot

    local hint = Instance.new("Frame")
    hint.AnchorPoint = Vector2.new(1, 0.5)
    hint.Position = UDim2.new(1, -18, 0.5, 0)
    hint.Size = UDim2.fromOffset(0, 16)
    hint.AutomaticSize = Enum.AutomaticSize.X
    hint.BackgroundTransparency = 1
    hint.Parent = foot
    local hintList = Instance.new("UIListLayout")
    hintList.FillDirection = Enum.FillDirection.Horizontal
    hintList.VerticalAlignment = Enum.VerticalAlignment.Center
    hintList.Padding = UDim.new(0, 6); hintList.Parent = hint
    local greenDot = Instance.new("Frame")
    greenDot.Size = UDim2.fromOffset(7, 7)
    greenDot.BackgroundColor3 = Color3.fromRGB(60, 220, 110)
    greenDot.BorderSizePixel = 0
    greenDot.LayoutOrder = 1; greenDot.Parent = hint
    Instance.new("UICorner", greenDot).CornerRadius = UDim.new(1, 0)
    local hintText = Instance.new("TextLabel")
    hintText.BackgroundTransparency = 1
    hintText.Size = UDim2.fromOffset(0, 16)
    hintText.Font = Enum.Font.GothamMedium
    hintText.TextSize = 11
    hintText.TextColor3 = C_DIM
    hintText.TextXAlignment = Enum.TextXAlignment.Left
    hintText.Text = feat.key_hub.Name .. " To Hide"
    hintText.AutomaticSize = Enum.AutomaticSize.X
    hintText.TextTruncate = Enum.TextTruncate.None
    hintText.LayoutOrder = 2
    hintText.Parent = hint

    local border = Instance.new("Frame")
    border.Position = UDim2.fromOffset(1, 1)
    border.Size = UDim2.new(1, -2, 1, -2)
    border.BackgroundTransparency = 1
    border.ZIndex = 50
    border.Parent = S.win
    Instance.new("UICorner", border).CornerRadius = UDim.new(0, 15)
    local borderStroke = Instance.new("UIStroke")
    borderStroke.Color = Color3.fromRGB(200, 130, 255)
    borderStroke.Thickness = 2
    borderStroke.Transparency = 0
    borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    borderStroke.Parent = border

    local innerGlow = Instance.new("Frame")
    innerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    innerGlow.Position = UDim2.fromScale(0.5, 0.5)
    innerGlow.Size = UDim2.new(1, 2, 1, 2)
    innerGlow.BackgroundTransparency = 1
    innerGlow.ZIndex = 51
    innerGlow.Parent = S.win
    Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 16)
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(220, 180, 255)
    innerStroke.Thickness = 1
    innerStroke.Transparency = 0.4
    innerStroke.Parent = innerGlow
end

-- ============================================================
-- SHOW / HIDE
-- ============================================================
S.shown = true
S.busy = false

local function closeHub()
    if S.busy or not S.shown then return end
    S.busy = true
    local winPos = S.win.AbsolutePosition - S.hubGui.AbsolutePosition
    local winSize = S.win.AbsoluteSize
    local rect = { x = winPos.X, y = winPos.Y, w = winSize.X, h = winSize.Y }
    S.win.Visible = false
    spawnGridShatter(S.hubGui, rect, function() S.shown = false; S.busy = false end)
end

local function openHub()
    if S.busy or S.shown then return end
    S.busy = true
    S.win.Visible = true
    S.scale.Scale = 0.7
    S.win.GroupTransparency = 1
    TweenService:Create(S.scale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    TweenService:Create(S.win, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
    task.delay(0.55, function() S.shown = true; S.busy = false end)
end

-- ============================================================
-- STATS WIDGET (300x300, TextSize 13)
-- ============================================================
local function initStatsWidget()
    local statsWidget = Instance.new("Frame")
    statsWidget.Name = "SnowyStats"
    statsWidget.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
    statsWidget.BackgroundTransparency = 0.2
    statsWidget.BorderSizePixel = 0
    statsWidget.Size = UDim2.fromOffset(300, 300)
    statsWidget.Position = UDim2.fromOffset(12, 12)
    statsWidget.ZIndex = 500
    statsWidget.Active = true
    statsWidget.Parent = S.hubGui
    Instance.new("UICorner", statsWidget).CornerRadius = UDim.new(0, 10)
    local swStroke = Instance.new("UIStroke", statsWidget)
    swStroke.Color = C_ACC; swStroke.Thickness = 1.5; swStroke.Transparency = 0.3

    local swTitle = Instance.new("TextLabel", statsWidget)
    swTitle.BackgroundTransparency = 1
    swTitle.Size = UDim2.new(1, -16, 0, 28)
    swTitle.Position = UDim2.fromOffset(14, 8)
    swTitle.Font = Enum.Font.GothamBold
    swTitle.TextSize = 17
    swTitle.TextColor3 = C_ACC
    swTitle.TextXAlignment = Enum.TextXAlignment.Left
    swTitle.Text = "Snowy · Stats"

    local divider = Instance.new("Frame", statsWidget)
    divider.Position = UDim2.fromOffset(14, 40)
    divider.Size = UDim2.new(1, -28, 0, 1)
    divider.BackgroundColor3 = C_LINE
    divider.BorderSizePixel = 0

    local swBody = Instance.new("TextLabel", statsWidget)
    swBody.BackgroundTransparency = 1
    swBody.Size = UDim2.new(1, -28, 1, -58)
    swBody.Position = UDim2.fromOffset(14, 50)
    swBody.Font = Enum.Font.Code
    swBody.TextSize = 13
    swBody.TextColor3 = Color3.fromRGB(230, 220, 245)
    swBody.TextXAlignment = Enum.TextXAlignment.Left
    swBody.TextYAlignment = Enum.TextYAlignment.Top
    swBody.TextWrapped = false
    swBody.Text = "loading..."

    S.statsWidget = statsWidget
    S.swBody = swBody

    local dragging, dragStart, startPos
    statsWidget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = statsWidget.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            statsWidget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function initWatermark()
    local watermark = Instance.new("TextLabel")
    watermark.AnchorPoint = Vector2.new(1, 0)
    watermark.Position = UDim2.new(1, -12, 0, 12)
    watermark.Size = UDim2.fromOffset(380, 18)
    watermark.BackgroundTransparency = 1
    watermark.Font = Enum.Font.Code
    watermark.TextSize = 12
    watermark.TextColor3 = Color3.fromRGB(220, 210, 240)
    watermark.TextStrokeTransparency = 0.3
    watermark.TextXAlignment = Enum.TextXAlignment.Right
    watermark.ZIndex = 500
    watermark.Text = ""
    watermark.Parent = S.hubGui
    S.watermark = watermark

    local crosshair = Instance.new("Frame")
    crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
    crosshair.Position = UDim2.fromScale(0.5, 0.5)
    crosshair.Size = UDim2.fromOffset(20, 20)
    crosshair.BackgroundTransparency = 1
    crosshair.Visible = false
    crosshair.ZIndex = 500
    crosshair.Parent = S.hubGui
    local ch_h = Instance.new("Frame", crosshair)
    ch_h.AnchorPoint = Vector2.new(0.5, 0.5); ch_h.Position = UDim2.fromScale(0.5, 0.5)
    ch_h.Size = UDim2.new(1, 0, 0, 1); ch_h.BackgroundColor3 = Color3.new(1,1,1); ch_h.BorderSizePixel = 0
    local ch_v = Instance.new("Frame", crosshair)
    ch_v.AnchorPoint = Vector2.new(0.5, 0.5); ch_v.Position = UDim2.fromScale(0.5, 0.5)
    ch_v.Size = UDim2.new(0, 1, 1, 0); ch_v.BackgroundColor3 = Color3.new(1,1,1); ch_v.BorderSizePixel = 0
    S.crosshair = crosshair
    S.ch_h = ch_h
    S.ch_v = ch_v
end

-- ============================================================
-- AIM (cframe only)
-- ============================================================
local function pickTarget()
    local vp = camera.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local camPos = camera.CFrame.Position
    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and isAlive(plr) then
            local sameTeam = feat.aim_tb and plr.Team and player.Team and plr.Team == player.Team
            if not sameTeam then
                local part = getTargetPart(plr)
                if part then
                    local score
                    if feat.aim_mode == "Nearest" then
                        score = (part.Position - camPos).Magnitude
                    elseif feat.aim_mode == "Lowest HP" then
                        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                        score = hum and hum.Health or math.huge
                    else
                        local sp, onScreen = camera:WorldToViewportPoint(part.Position)
                        if not onScreen or sp.Z <= 0 then
                            score = nil
                        else
                            score = math.sqrt((sp.X - cx)^2 + (sp.Y - cy)^2)
                            if score > feat.aim_fov then score = nil end
                        end
                    end
                    if score and score < bestScore then
                        if feat.aim_wall then
                            best = part; bestScore = score
                        else
                            local origin = camPos
                            local dir = part.Position - origin
                            local rp = RaycastParams.new()
                            rp.FilterType = Enum.RaycastFilterType.Exclude
                            rp.FilterDescendantsInstances = { player.Character, camera }
                            local hit = Workspace:Raycast(origin, dir, rp)
                            if not hit or hit.Instance:IsDescendantOf(part.Parent) then
                                best = part; bestScore = score
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function initAim()
    RunService:BindToRenderStep("SnowyAim", Enum.RenderPriority.Camera.Value + 10, function(dt)
        if not feat.aim_on then S.currentTarget = nil; return end
        if S.currentTarget then
            local ch = S.currentTarget.Parent
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 or not S.currentTarget.Parent then
                S.currentTarget = nil
            end
        end
        if not S.currentTarget then
            S.currentTarget = pickTarget()
        end
        if not S.currentTarget then return end
        local origin = camera.CFrame.Position
        local want = CFrame.lookAt(origin, S.currentTarget.Position)
        local smooth = feat.aim_smooth or 0
        local alpha
        if smooth <= 0.001 then
            alpha = 1
        else
            alpha = 1 - math.pow(smooth, dt * 60)
            alpha = math.clamp(alpha, 0.02, 1)
        end
        camera.CFrame = camera.CFrame:Lerp(want, alpha)
    end)
end

local function initTrigger()
    RunService:BindToRenderStep("SnowyTrigger", Enum.RenderPriority.Camera.Value + 5, function()
        if not feat.trig_on then return end
        if (tick() - (S.trigLastFire or 0)) < feat.trig_delay then return end
        local origin = camera.CFrame.Position
        local dir = camera.CFrame.LookVector * 500
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { player.Character, camera }
        local hit = Workspace:Raycast(origin, dir, rp)
        if not hit then return end
        local hitChar = hit.Instance:FindFirstAncestorOfClass("Model")
        if not hitChar then return end
        local hitPlr = Players:GetPlayerFromCharacter(hitChar)
        if not hitPlr or hitPlr == player then return end
        if not isAlive(hitPlr) then return end
        if feat.trig_tb and hitPlr.Team and player.Team and hitPlr.Team == player.Team then return end
        if not feat.trig_wall then
            local tp = getTargetPart(hitPlr, "HumanoidRootPart")
            if tp then
                local wDir = tp.Position - origin
                local wRP = RaycastParams.new()
                wRP.FilterType = Enum.RaycastFilterType.Exclude
                wRP.FilterDescendantsInstances = { player.Character, camera, hitChar }
                if Workspace:Raycast(origin, wDir, wRP) then return end
            end
        end
        S.trigLastFire = tick()
        pcall(function()
            local InputHandler = require(game:GetService("ReplicatedStorage").CAM.Client.Components.Client.InputHandler)
            if InputHandler and InputHandler.VirtualPress then
                InputHandler.VirtualPress("Combat")
                task.delay(0.06, function() pcall(function() InputHandler.VirtualRelease("Combat") end) end)
                return
            end
        end)
        local vp = camera.ViewportSize
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(vp.X/2, vp.Y/2, 0, true, game, 0)
            task.wait(0.04)
            VirtualInputManager:SendMouseButtonEvent(vp.X/2, vp.Y/2, 0, false, game, 0)
        end)
        -- trigger counts as our damage
        local isHead = hit.Instance.Name == "Head"
        dmgCredit[hitPlr] = { at = tick(), head = isHead }
    end)
end

local function initEsp()
    local espFolder = Instance.new("Folder")
    espFolder.Name = "SnowyESP"
    espFolder.Parent = S.hubGui
    local espEntries = {}

    local function makeEspFor(plr)
        local box = Instance.new("Frame")
        box.BorderSizePixel = 0
        box.BackgroundTransparency = 1
        box.ZIndex = 2
        box.Visible = false
        box.Parent = espFolder
        local stroke = Instance.new("UIStroke")
        stroke.Color = feat.esp_color; stroke.Thickness = 1.5; stroke.Parent = box
        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextStrokeTransparency = 0.4
        nameLbl.TextColor3 = feat.esp_color
        nameLbl.ZIndex = 3
        nameLbl.Visible = false
        nameLbl.Parent = espFolder
        local distLbl = Instance.new("TextLabel")
        distLbl.BackgroundTransparency = 1
        distLbl.Font = Enum.Font.GothamMedium
        distLbl.TextSize = 11
        distLbl.TextStrokeTransparency = 0.4
        distLbl.TextColor3 = feat.esp_color
        distLbl.ZIndex = 3
        distLbl.Visible = false
        distLbl.Parent = espFolder
        local tracer = Instance.new("Frame")
        tracer.BorderSizePixel = 0
        tracer.BackgroundColor3 = feat.esp_color
        tracer.ZIndex = 2
        tracer.Visible = false
        tracer.AnchorPoint = Vector2.new(0.5, 0)
        tracer.Parent = espFolder
        espEntries[plr] = { box = box, stroke = stroke, name = nameLbl, dist = distLbl, tracer = tracer }
    end

    local function clearEspFor(plr)
        local e = espEntries[plr]
        if not e then return end
        for _, v in pairs(e) do if typeof(v) == "Instance" then pcall(function() v:Destroy() end) end end
        espEntries[plr] = nil
    end

    for _, p in ipairs(Players:GetPlayers()) do if p ~= player then makeEspFor(p) end end
    Players.PlayerAdded:Connect(function(p) if p ~= player then makeEspFor(p) end end)
    Players.PlayerRemoving:Connect(function(p) clearEspFor(p) end)

    RunService:BindToRenderStep("SnowyEsp", Enum.RenderPriority.Camera.Value + 2, function()
        for plr, e in pairs(espEntries) do
            local alive = isAlive(plr)
            local show = feat.esp_on and alive
                and not (feat.esp_tb and plr.Team and player.Team and plr.Team == player.Team)
            if not show then
                e.box.Visible = false; e.name.Visible = false
                e.dist.Visible = false; e.tracer.Visible = false
            else
                local ch = plr.Character
                local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head"))
                if root then
                    local topS, onTop = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.6, 0))
                    local botS = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.6, 0))
                    if onTop then
                        local h = botS.Y - topS.Y
                        local w = h * 0.55
                        local cx = (topS.X + botS.X) * 0.5
                        e.box.Visible = feat.esp_box
                        e.box.Position = UDim2.fromOffset(cx - w/2, topS.Y)
                        e.box.Size = UDim2.fromOffset(w, h)
                        e.stroke.Color = feat.esp_color
                        local dist = (camera.CFrame.Position - root.Position).Magnitude
                        e.name.Visible = feat.esp_name
                        e.name.Position = UDim2.fromOffset(cx - 60, topS.Y - 16)
                        e.name.Size = UDim2.fromOffset(120, 14)
                        e.name.Text = plr.Name
                        e.name.TextColor3 = feat.esp_color
                        e.dist.Visible = feat.esp_dist
                        e.dist.Position = UDim2.fromOffset(cx - 40, botS.Y + 2)
                        e.dist.Size = UDim2.fromOffset(80, 14)
                        e.dist.Text = string.format("%d m", dist)
                        e.dist.TextColor3 = feat.esp_color
                        if feat.esp_tracer then
                            local vp = camera.ViewportSize
                            local fx, fy
                            if feat.esp_tracer_from == "Bottom" then
                                fx, fy = vp.X/2, vp.Y
                            elseif feat.esp_tracer_from == "Center" then
                                fx, fy = vp.X/2, vp.Y/2
                            else
                                local mp = UserInputService:GetMouseLocation()
                                fx, fy = mp.X, mp.Y
                            end
                            local dx, dy = cx - fx, botS.Y - fy
                            e.tracer.Visible = true
                            e.tracer.Position = UDim2.fromOffset(fx, fy)
                            e.tracer.Size = UDim2.fromOffset(1.4, math.sqrt(dx*dx + dy*dy))
                            e.tracer.Rotation = math.deg(math.atan2(dx, -dy))
                            e.tracer.BackgroundColor3 = feat.esp_color
                        else
                            e.tracer.Visible = false
                        end
                    else
                        e.box.Visible = false; e.name.Visible = false
                        e.dist.Visible = false; e.tracer.Visible = false
                    end
                else
                    e.box.Visible = false; e.name.Visible = false
                    e.dist.Visible = false; e.tracer.Visible = false
                end
            end
        end
    end)
end

local function initFov()
    S.savedFov = camera.FieldOfView
    RunService:BindToRenderStep("SnowyFov", Enum.RenderPriority.Camera.Value + 1, function()
        if feat.fov_on then camera.FieldOfView = feat.fov_val end
    end)
    camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if not feat.fov_on then S.savedFov = camera.FieldOfView end
    end)
end

-- ============================================================
-- STATS TRACKER — fixes kill/HS counting for aimbot-only users
-- watches every enemy health drop, credits if we're aimed at them
-- or recently shot them via trigger
-- ============================================================
local function initStatsTracker()
    task.spawn(function()
        while true do
            task.wait(0.1)
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player then
                    local ch = plr.Character
                    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local last = healthTrack[plr]
                        local now = hum.Health
                        if last == nil then last = hum.MaxHealth end

                        if last > now then
                            -- enemy took damage this tick. was it us?
                            local aimingAt = S.currentTarget and S.currentTarget.Parent == ch
                            local recentTrigger = dmgCredit[plr] and (tick() - dmgCredit[plr].at) < 2.0
                            local aimingHead = aimingAt and feat.aim_part == "Head" and S.currentTarget.Name == "Head"
                            if aimingAt or recentTrigger then
                                local dmg = last - now
                                sessionStats.shots = sessionStats.shots + 1
                                sessionStats.damage_dealt = sessionStats.damage_dealt + dmg
                                if recentTrigger then
                                    if dmgCredit[plr].head then
                                        sessionStats.headshots = sessionStats.headshots + 1
                                    else
                                        sessionStats.bodyshots = sessionStats.bodyshots + 1
                                    end
                                elseif aimingHead then
                                    sessionStats.headshots = sessionStats.headshots + 1
                                else
                                    sessionStats.bodyshots = sessionStats.bodyshots + 1
                                end
                                dmgCredit[plr] = { at = tick(), head = aimingHead }
                            end
                        end

                        if last > 0 and now <= 0 then
                            local rd = dmgCredit[plr]
                            if rd and (tick() - rd.at) < 5 then
                                sessionStats.kills = sessionStats.kills + 1
                                sessionStats.killstreak = sessionStats.killstreak + 1
                                if sessionStats.killstreak > sessionStats.best_streak then
                                    sessionStats.best_streak = sessionStats.killstreak
                                end
                                sessionStats.last_kill = tick()
                            end
                            dmgCredit[plr] = nil
                        end

                        healthTrack[plr] = now
                    end
                end
            end
            local myCh = player.Character
            local myHum = myCh and myCh:FindFirstChildOfClass("Humanoid")
            if myHum then
                local last = healthTrack[player]
                if last and last > 0 and myHum.Health <= 0 then
                    sessionStats.deaths = sessionStats.deaths + 1
                    sessionStats.killstreak = 0
                end
                healthTrack[player] = myHum.Health
            end
        end
    end)
end

local function initAntiAfk()
    player.Idled:Connect(function()
        if not extra.anti_afk then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

local function initChatLog()
    local path = "snowy_chatlog.txt"
    local function appendChat(name, msg)
        if not extra.chat_log then return end
        pcall(function()
            local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(name) .. ": " .. tostring(msg) .. "\n"
            if isfile and isfile(path) then
                writefile(path, readfile(path) .. line)
            elseif writefile then
                writefile(path, line)
            end
        end)
    end
    for _, p in ipairs(Players:GetPlayers()) do
        p.Chatted:Connect(function(msg) appendChat(p.Name, msg) end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.Chatted:Connect(function(msg) appendChat(p.Name, msg) end)
    end)
end

local function initStatsLoop()
    local fpsCounter, fpsAcc, fpsTimer = 0, 0, 0
    RunService.RenderStepped:Connect(function(dt)
        fpsCounter = fpsCounter + 1
        fpsAcc = fpsAcc + dt
        if fpsAcc >= 0.5 then
            fpsTimer = math.floor(fpsCounter / fpsAcc)
            fpsCounter, fpsAcc = 0, 0
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.25)
            local uptime = math.floor(tick() - sessionStats.start)
            local h = math.floor(uptime / 3600)
            local m = math.floor((uptime % 3600) / 60)
            local s = uptime % 60
            local uptime_str = string.format("%02d:%02d:%02d", h, m, s)
            local total_hits = sessionStats.headshots + sessionStats.bodyshots
            local hs_pct = total_hits > 0 and math.floor((sessionStats.headshots / total_hits) * 100) or 0
            local kd = sessionStats.deaths > 0 and (sessionStats.kills / sessionStats.deaths) or sessionStats.kills
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)

            if S.statsWidget then
                S.statsWidget.Visible = extra.widget
                if extra.widget then
                    S.swBody.Text = table.concat({
                        "Kills:       " .. sessionStats.kills,
                        "Deaths:      " .. sessionStats.deaths,
                        "K/D:         " .. string.format("%.2f", kd),
                        "Headshots:   " .. sessionStats.headshots,
                        "Bodyshots:   " .. sessionStats.bodyshots,
                        "HS %:        " .. hs_pct .. "%",
                        "Streak:      " .. sessionStats.killstreak,
                        "Best Streak: " .. sessionStats.best_streak,
                        "Damage:      " .. math.floor(sessionStats.damage_dealt),
                        "Uptime:      " .. uptime_str,
                        "FPS:         " .. fpsTimer,
                        "Ping:        " .. ping .. " ms",
                    }, "\n")
                end
            end

            if S.watermark then
                S.watermark.Visible = extra.watermark
                if extra.watermark then
                    S.watermark.Text = string.format("Snowy Hub v%s  |  %dFps  |  %dMs  |  %dK/%dD  |  %s",
                        HUB_VERSION, fpsTimer, ping, sessionStats.kills, sessionStats.deaths, os.date("%H:%M:%S"))
                end
            end

            if S.crosshair then
                S.crosshair.Visible = extra.crosshair
                S.crosshair.Size = UDim2.fromOffset(extra.crosshair_size * 2, extra.crosshair_size * 2)
                S.ch_h.BackgroundColor3 = extra.crosshair_color
                S.ch_v.BackgroundColor3 = extra.crosshair_color
            end
        end
    end)
end

-- ============================================================
-- INPUT
-- ============================================================
local function refreshAllCards()
    for _, fn in ipairs(S.cardRefreshes) do
        pcall(fn)
    end
end

local function initInput()
    UserInputService.InputBegan:Connect(function(input, gp)
        if not S.hubGui or not S.hubGui.Parent then return end
        if gp then return end
        if input.KeyCode == feat.key_hub then
            if S.shown then closeHub() else openHub() end
            return
        end
        if input.KeyCode == feat.key_aim then
            feat.aim_on = not feat.aim_on
            refreshAllCards()
        elseif input.KeyCode == feat.key_esp then
            feat.esp_on = not feat.esp_on
            refreshAllCards()
        elseif input.KeyCode == feat.key_fov then
            feat.fov_on = not feat.fov_on
            if not feat.fov_on then camera.FieldOfView = S.savedFov end
            refreshAllCards()
        elseif input.KeyCode == feat.key_trig then
            feat.trig_on = not feat.trig_on
            refreshAllCards()
        end
    end)
end

local function initDrag()
    local dragging, dragStart, startPos = false, nil, nil
    S.head.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = S.win.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            S.win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    S.closeBtn.MouseEnter:Connect(function()
        TweenService:Create(S.closeBtn, TweenInfo.new(0.15), { TextColor3 = C_GLOW }):Play()
    end)
    S.closeBtn.MouseLeave:Connect(function()
        TweenService:Create(S.closeBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(200, 190, 220) }):Play()
    end)
    S.closeBtn.MouseButton1Click:Connect(closeHub)
end

-- ============================================================
-- SPLASH LOOP
-- ============================================================
local function initSplashLoop()
    local splash = S.splash
    local splashGui = splash.gui

    for i, k in ipairs(splash.kanji) do
        task.delay(0.2 + (i - 1) * 0.22, function()
            local info = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            k.Main.TextSize = 61; k.Halo.TextSize = 61
            k.Halo.TextTransparency = 0.5; k.HaloStroke.Thickness = 6
            k.HaloStroke.Transparency = 0.82
            TweenService:Create(k.Main, info, { TextSize = 36, TextTransparency = 0 }):Play()
            TweenService:Create(k.MainStroke, info, { Transparency = 0.7 }):Play()
            TweenService:Create(k.Halo, info, { TextSize = 36, TextTransparency = 0.78 }):Play()
            TweenService:Create(k.HaloStroke, info, { Thickness = 2.5, Transparency = 0.9 }):Play()
        end)
    end

    task.delay(0.5, function()
        TweenService:Create(splash.title, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
        TweenService:Create(splash.subLbl, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
        TweenService:Create(splash.statusLbl, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
        TweenService:Create(splash.tagLbl, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
        TweenService:Create(splash.boxScale, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), { Scale = 1 }):Play()
        TweenService:Create(splash.orbImage, TweenInfo.new(1.2), { ImageTransparency = 0 }):Play()
    end)

    local clock = 0
    local lastPct = -1
    local finished = false

    local function statusForPct(p)
        if p < 20 then return "Initializing" end
        if p < 45 then return "Checking Integrity" end
        if p < 70 then return "Loading Modules" end
        if p < 90 then return "Preparing Interface" end
        return "Ready — Universal Aim"
    end

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        clock += dt
        splash.boxScale.Scale = 0.9 + (math.sin(clock * math.pi * 2 / 2.2) + 1) * 0.06
        splash.layoutRing(splash.ring1, splash.proj1, clock * math.pi * 2 / 4)
        splash.layoutRing(splash.ring2, splash.proj2, -clock * math.pi * 2 / 6)
        if splash.orbImage.ImageTransparency < 1 then
            local sz = 96 + math.sin(clock * 3) * 5
            splash.orbImage.Size = UDim2.fromOffset(sz, sz)
        end
        local p = math.clamp(clock / SPLASH_TIME, 0, 1)
        local eased = 0.5 - 0.5 * math.cos(math.pi * p)
        splash.jauge.Size = UDim2.fromScale(eased, 1)
        local pct = math.floor(eased * 100 + 0.5)
        if pct ~= lastPct then
            lastPct = pct
            splash.statusLbl.Text = statusForPct(pct)
        end
        if p >= 1 and not finished then
            finished = true
            conn:Disconnect()
            splash.burstOrb()
            task.wait(0.3)
            local vp = splashGui.AbsoluteSize
            local cols, rows = 10, 7
            local cw, ch = vp.X / cols, vp.Y / rows
            local pieces = {}
            for c = 0, cols - 1 do
                for r = 0, rows - 1 do
                    local pieceW = cw * (0.95 + math.random() * 0.25)
                    local pieceH = ch * (0.95 + math.random() * 0.25)
                    local px = c * cw + cw / 2 + (math.random() - 0.5) * cw * 0.3
                    local py = r * ch + ch / 2 + (math.random() - 0.5) * ch * 0.3
                    local shard, stroke = makeGlassShard(S.hubGui, pieceW, pieceH)
                    shard.Position = UDim2.fromOffset(px, py)
                    shard.Rotation = (math.random() - 0.5) * 12
                    shard.BackgroundTransparency = 0.05
                    local dx = (px - vp.X / 2) / (vp.X / 2)
                    pieces[#pieces+1] = { frame = shard, stroke = stroke, x = px, y = py, dx = dx }
                end
            end
            splashGui.Enabled = false
            S.win.Visible = true
            S.scale.Scale = 0.7
            S.win.GroupTransparency = 1
            TweenService:Create(S.scale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            TweenService:Create(S.win, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
            for _, s in ipairs(pieces) do
                local delay = math.abs(s.dx) * 0.12 + rng:NextNumber(0, 0.06)
                local dur = rng:NextNumber(0.6, 0.9)
                local hDrift = rng:NextNumber(-0.35, 0.35) + s.dx * 0.35
                flyShard(s.frame, s.stroke,
                    s.x + hDrift * vp.X * 0.5,
                    s.y + rng:NextNumber(0.9, 1.4) * vp.Y,
                    rng:NextNumber(-320, 320), dur, delay)
            end
            if splash.audio then
                TweenService:Create(splash.audio, TweenInfo.new(0.8), { Volume = 0 }):Play()
            end
            task.delay(0.05, function() pcall(function() splashGui:Destroy() end) end)
            task.delay(1.2, function()
                for _, s in ipairs(pieces) do pcall(function() s.frame:Destroy() end) end
                if splash.audio then
                    pcall(function() splash.audio:Stop() end)
                    pcall(function() splash.audio:Destroy() end)
                end
            end)
        end
    end)
end

-- ============================================================
-- BOOT
-- ============================================================
buildSplash()
buildHubShell()
initWatermark()
initStatsWidget()
initEsp()
initAim()
initTrigger()
initFov()
buildHomePage()
buildBindsPage()
buildCustomizePage()
buildVisualPage()
buildUtilityPage()
buildTabs()
buildFooter()
initInput()
initDrag()
initStatsTracker()
initAntiAfk()
initChatLog()
initStatsLoop()
initSplashLoop()
