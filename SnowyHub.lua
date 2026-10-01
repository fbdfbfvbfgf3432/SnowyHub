-- Snowy Hub Loading Screen (8s, music, percentage, shatter finish)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// SETTINGS
local TITLE = "Snowy Hub"
local CREDIT = "Made By Crscx2210"
local IMAGE_URL = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcThy6L7s5cNwchYyyVge1BS6p9f34eumCuGhP0YF5CwBA&s=10"
local SNOW_COUNT = 70
local ROTATE_SPEED = 45          -- degrees per second
local GLOW_COLOR = Color3.fromRGB(255, 30, 30)
local LOAD_TIME = 8              -- seconds (loading screen + music length)

--// MUSIC
local AUDIO_FILE = "crscx_song.mp3"   -- put the mp3 in your executor's workspace folder
local AUDIO_URL = ""                   -- optional: direct .mp3 link if you'd rather download it
local AUDIO_VOLUME = 0.3               -- lower = quieter (0 to 1)
local GLASS_VOLUME = 0.6              -- glass break sound volume (0 to 1)

--// IMAGE FROM URL (needs request + writefile + getcustomasset)
local function loadImage(url)
	local req = request or http_request or (syn and syn.request)
	if req and writefile and getcustomasset then
		local ok, res = pcall(req, { Url = url, Method = "GET" })
		if ok and res and res.Body and #res.Body > 0 then
			local saved = pcall(writefile, "crscx_logo.png", res.Body)
			if saved then
				local ok2, asset = pcall(getcustomasset, "crscx_logo.png")
				if ok2 then
					return asset
				end
			end
		end
	end
	return ""
end

local IMAGE_ID = loadImage(IMAGE_URL)

--// SOUND SETUP
local function loadSound()
	if not (isfile and writefile and getcustomasset) then
		return nil
	end
	if not isfile(AUDIO_FILE) and AUDIO_URL ~= "" then
		local req = request or http_request or (syn and syn.request)
		if req then
			local ok, res = pcall(req, { Url = AUDIO_URL, Method = "GET" })
			if ok and res and res.Body and #res.Body > 0 then
				pcall(writefile, AUDIO_FILE, res.Body)
			end
		end
	end
	if not isfile(AUDIO_FILE) then
		return nil
	end
	local ok, asset = pcall(getcustomasset, AUDIO_FILE)
	if not ok then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = "SnowyHubMusic"
	s.SoundId = asset
	s.Volume = AUDIO_VOLUME
	s.Looped = false
	s.Parent = SoundService
	return s
end

local sound = loadSound()

--// GLASS BREAK SOUND (embedded - saved to your workspace automatically)
local GLASS_FILE = "crscx_glass.mp3"
local GLASS_B64 = [[
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
+QyODnb5z+celCpQmwzOpOZkuav3NzNeiVAqvM2aL5XUpD5Wytqr5GTRulekxNSPbP7GYtufNTZD
fa7/vMvT1/WQ6WQFMj9tVucNZ9gEK4FWukvPNgJL6+ZHYcBVLfH4LIOpCYABQh7ARqqsakwUBX1A
Sv/zUMTvHJPGHUIJR5mvsXszcPY4zeGhqUY9ttYaqFar6qqtVja/VWMezKpM2zN+zUSVZvqqpf+7
V2/qq39+ajjz/Umz61qfecS2ZcF31TkV9S/9gykev8Xqqvn+x/1mZj2q5M3+tVDVV4qqpKsAlh8P
Y4GAhRpMQU1FMy4xMDCqqqr/81LE8RszzgQAGYeBqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCqqqqqqqqqqqqqqv/zUMT6HewF3WIZh+Sqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqkxBTUUzLjEwMKqqqqqqqqqqqqr/81LEiQAA
A0gAAAAAqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
qqqqqqqqqqqqqv/zUsSJAAADSAAAAACqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
]]

local function b64decode(data)
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	data = string.gsub(data, "[^" .. chars .. "=]", "")
	return (data:gsub(".", function(x)
		if x == "=" then return "" end
		local r, f = "", (chars:find(x, 1, true) - 1)
		for i = 6, 1, -1 do
			r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
		end
		return r
	end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
		if #x ~= 8 then return "" end
		local c = 0
		for i = 1, 8 do
			c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
		end
		return string.char(c)
	end))
end

local function loadGlassSound()
	if not (isfile and writefile and getcustomasset) then
		return nil
	end
	if not isfile(GLASS_FILE) then
		local ok = pcall(function()
			writefile(GLASS_FILE, b64decode(GLASS_B64))
		end)
		if not ok then
			return nil
		end
	end
	local ok, asset = pcall(getcustomasset, GLASS_FILE)
	if not ok then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = "SnowyHubGlassBreak"
	s.SoundId = asset
	s.Volume = GLASS_VOLUME
	s.Looped = false
	s.Parent = SoundService
	return s
end

local glassSound = loadGlassSound()

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SnowyHub"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parent = playerGui
if gethui then
	local ok, h = pcall(gethui)
	if ok and h then parent = h end
end
gui.Parent = parent

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.new(0, 0, 0)
bg.BorderSizePixel = 0
bg.ZIndex = 1
bg.Parent = gui

--// SNOW
local snowLayer = Instance.new("Frame")
snowLayer.Size = UDim2.fromScale(1, 1)
snowLayer.BackgroundTransparency = 1
snowLayer.ZIndex = 2
snowLayer.ClipsDescendants = true
snowLayer.Parent = bg

local rng = Random.new()
local flakes = {}

local function resetFlake(f, randomY)
	f.x = rng:NextNumber(0, 1)
	f.y = randomY and rng:NextNumber(0, 1) or -0.05
	f.speed = rng:NextNumber(0.04, 0.14)
	f.sway = rng:NextNumber(0.005, 0.03)
	f.phase = rng:NextNumber(0, math.pi * 2)
	local s = rng:NextInteger(3, 9)
	f.frame.Size = UDim2.fromOffset(s, s)
	f.frame.BackgroundTransparency = rng:NextNumber(0.1, 0.5)
end

for i = 1, SNOW_COUNT do
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.ZIndex = 2
	frame.Parent = snowLayer
	Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)

	local f = { frame = frame }
	resetFlake(f, true)
	table.insert(flakes, f)
end

--// ROTATING IMAGE + GLOW
local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.fromScale(0.5, 0.47)
holder.Size = UDim2.fromOffset(180, 180)
holder.BackgroundTransparency = 1
holder.ZIndex = 5
holder.Parent = bg

local glow = Instance.new("ImageLabel")
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.5)
glow.Size = UDim2.fromScale(1.35, 1.35)
glow.BackgroundTransparency = 1
glow.Image = IMAGE_ID
glow.ImageColor3 = GLOW_COLOR
glow.ImageTransparency = 0.6
glow.ZIndex = 5
glow.Parent = holder

local img = Instance.new("ImageLabel")
img.AnchorPoint = Vector2.new(0.5, 0.5)
img.Position = UDim2.fromScale(0.5, 0.5)
img.Size = UDim2.fromScale(1, 1)
img.BackgroundTransparency = 1
img.Image = IMAGE_ID
img.ZIndex = 6
img.Parent = holder

--// TITLE (calligraphic + chromatic fringe)
local function makeTitle(color, offsetX, z, transparency)
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.new(0.5, offsetX, 0.62, 0)
	l.Size = UDim2.fromOffset(500, 60)
	l.BackgroundTransparency = 1
	l.Text = TITLE
	l.Font = Enum.Font.Fondamento
	l.TextSize = 52
	l.TextColor3 = color
	l.TextTransparency = transparency
	l.ZIndex = z
	l.Parent = bg
	return l
end

makeTitle(Color3.fromRGB(255, 60, 60), -1, 5, 0.35)   -- red fringe (left)
makeTitle(Color3.fromRGB(60, 120, 255), 1, 5, 0.35)   -- blue fringe (right)
makeTitle(Color3.fromRGB(235, 235, 235), 0, 6, 0)

--// CREDIT
local credit = Instance.new("TextLabel")
credit.AnchorPoint = Vector2.new(0.5, 0.5)
credit.Position = UDim2.fromScale(0.5, 0.675)
credit.Size = UDim2.fromOffset(400, 28)
credit.BackgroundTransparency = 1
credit.Text = CREDIT
credit.Font = Enum.Font.Fondamento
credit.TextSize = 22
credit.TextColor3 = Color3.fromRGB(170, 170, 170)
credit.ZIndex = 5
credit.Parent = bg

--// LOAD BAR
local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.72)
barBack.Size = UDim2.fromOffset(260, 4)
barBack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
barBack.BorderSizePixel = 0
barBack.ZIndex = 5
barBack.Parent = bg
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = GLOW_COLOR
barFill.BorderSizePixel = 0
barFill.ZIndex = 6
barFill.Parent = barBack
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

--// PERCENT
local percent = Instance.new("TextLabel")
percent.AnchorPoint = Vector2.new(0.5, 0.5)
percent.Position = UDim2.fromScale(0.5, 0.755)
percent.Size = UDim2.fromOffset(200, 28)
percent.BackgroundTransparency = 1
percent.Text = "0%"
percent.Font = Enum.Font.GothamBold
percent.TextSize = 22
percent.TextColor3 = Color3.fromRGB(255, 70, 70)
percent.ZIndex = 5
percent.Parent = bg

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.Position = UDim2.fromScale(0.5, 0.795)
status.Size = UDim2.fromOffset(300, 20)
status.BackgroundTransparency = 1
status.Text = "checking integrity..."
status.Font = Enum.Font.Code
status.TextSize = 13
status.TextColor3 = Color3.fromRGB(150, 150, 150)
status.ZIndex = 5
status.Parent = bg

--// SHATTER FINISH (the screen itself breaks into pieces, nothing changes visually before it breaks)
local conn -- animation loop connection (defined below)

local function shatterScreen()
	local COLS, ROWS = 10, 6
	local W, H = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
	local cw, ch = W / COLS, H / ROWS

	local shardLayer = Instance.new("Frame")
	shardLayer.Size = UDim2.fromScale(1, 1)
	shardLayer.BackgroundTransparency = 1
	shardLayer.ZIndex = 50
	shardLayer.Parent = gui

	-- every piece is a cut-out of the real loading screen
	local pieces = {}
	for c = 0, COLS - 1 do
		for r = 0, ROWS - 1 do
			local x0, y0 = c * cw, r * ch

			local shard = Instance.new("CanvasGroup")
			shard.AnchorPoint = Vector2.new(0.5, 0.5)
			shard.Position = UDim2.fromOffset(x0 + cw / 2, y0 + ch / 2)
			shard.Size = UDim2.fromOffset(cw + 1, ch + 1)
			shard.BackgroundTransparency = 1
			shard.BorderSizePixel = 0
			shard.ZIndex = 50
			shard.Parent = shardLayer

			local copy = bg:Clone()
			copy.Position = UDim2.fromOffset(-x0 + 0.5, -y0 + 0.5)
			copy.Size = UDim2.fromOffset(W, H)
			copy.Visible = true
			copy.Parent = shard

			table.insert(pieces, {
				shard = shard,
				cx = x0 + cw / 2,
				cy = y0 + ch / 2,
			})
		end
	end

	-- swap the real screen for the pieces (looks identical)
	if conn then conn:Disconnect() end
	bg.Visible = false

	if glassSound then
		glassSound:Play()
	end

	task.wait(0.12)

	-- break outward from the center
	for _, p in ipairs(pieces) do
		local dx, dy = p.cx / W - 0.5, p.cy / H - 0.5
		local dist = math.sqrt(dx * dx + dy * dy)
		local delay = dist * 0.5 + rng:NextNumber(0, 0.12)
		local dur = rng:NextNumber(1.0, 1.5)
		local spread = rng:NextNumber(0.6, 1.5)

		local tx = p.cx + dx * spread * W * 0.9
		local ty = p.cy + dy * spread * H * 0.9 + rng:NextNumber(0.4, 1.0) * H

		task.delay(delay, function()
			local info = TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(p.shard, info, {
				Position = UDim2.fromOffset(tx, ty),
				Rotation = rng:NextNumber(-220, 220),
				GroupTransparency = 1,
			}):Play()
		end)
	end

	-- >>> run your hub / main script here (the game is revealed as the pieces fall) <<<

	task.wait(2.6)
	gui:Destroy()
end

--// ANIMATION LOOP + LOADING PROGRESS
local t = 0
local finished = false
local fadingMusic = false
local lastPct = -1

if sound then
	sound.TimePosition = 0
	sound:Play()
end

conn = RunService.RenderStepped:Connect(function(dt)
	t += dt

	-- rotate image
	holder.Rotation = (holder.Rotation + ROTATE_SPEED * dt) % 360

	-- pulsing glow
	local pulse = (math.sin(t * 3) + 1) / 2
	glow.ImageTransparency = 0.35 + pulse * 0.5
	local gs = 1.25 + pulse * 0.2
	glow.Size = UDim2.fromScale(gs, gs)

	-- snow
	for _, f in ipairs(flakes) do
		f.y += f.speed * dt
		local xOff = math.sin(t * 1.5 + f.phase) * f.sway
		f.frame.Position = UDim2.fromScale(f.x + xOff, f.y)
		if f.y > 1.05 then
			resetFlake(f, false)
		end
	end

	-- progress (8 seconds total, eased)
	local p = math.clamp(t / LOAD_TIME, 0, 1)
	local eased = 0.5 - 0.5 * math.cos(math.pi * p)
	barFill.Size = UDim2.fromScale(eased, 1)

	local pct = math.floor(eased * 100 + 0.5)
	if pct ~= lastPct then
		lastPct = pct
		percent.Text = pct .. "%"
		if pct < 25 then
			status.Text = "checking integrity..."
		elseif pct < 55 then
			status.Text = "loading modules..."
		elseif pct < 85 then
			status.Text = "preparing interface..."
		elseif pct < 100 then
			status.Text = "almost done..."
		else
			status.Text = "done"
		end
	end

	-- music fade-out during the last second
	if sound and not fadingMusic and t >= LOAD_TIME - 1 then
		fadingMusic = true
		TweenService:Create(sound, TweenInfo.new(1), { Volume = 0 }):Play()
	end

	-- finished -> shatter
	if p >= 1 and not finished then
		finished = true
		task.spawn(function()
			task.wait(0.15)
			if sound then
				sound:Stop()
				sound:Destroy()
			end
			shatterScreen()
		end)
	end
end)
