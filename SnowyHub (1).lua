-- Snowy Hub: loading screen + hub
-- Settings are at the top. The big blocks of letters at the very bottom are the
-- embedded images and sound, so you don't need any extra files for them.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// LOADING SCREEN SETTINGS
local TITLE = "Snowy Hub"
local CREDIT = "Made By Crscx2210"
local SNOW_COUNT = 70
local ROTATE_SPEED = 45          -- degrees per second
local GLOW_COLOR = Color3.fromRGB(255, 30, 30)
local LOAD_TIME = 8              -- seconds (loading screen + music length)

--// HUB SETTINGS
local HUB_NAME = nil             -- nil = show the Roblox name of whoever runs the script, or put "Crscx2210"
local HUB_NAME_CN = "克里斯克斯"    -- "Crscx" written in Chinese
local HUB_VERSION = "V1.0"
local TOGGLE_KEY = Enum.KeyCode.RightShift   -- show / hide the hub

--// MUSIC
local AUDIO_FILE = "crscx_song.mp3"   -- put the mp3 in your executor's workspace folder
local AUDIO_URL = ""                   -- optional: direct .mp3 link if you'd rather download it
local AUDIO_VOLUME = 0.3               -- lower = quieter (0 to 1)
local GLASS_VOLUME = 0.6               -- glass break sound volume (0 to 1)

--// EMBEDDED DATA (filled in at the bottom of the file)
local DATA = {}
local LOGO_ASPECT = 0.8325    -- logo width / height

local function main()

local rng = Random.new()

--// HELPERS
local function getGuiParent()
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then
			return h
		end
	end
	return playerGui
end

local B64 = {}
do
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	for i = 1, #chars do
		B64[string.byte(chars, i)] = i - 1
	end
end

local function b64decode(data)
	data = string.gsub(data, "[^%w%+/=]", "")
	local out, n = {}, 0
	for i = 1, #data, 4 do
		local a, b, c, d = string.byte(data, i, i + 3)
		local v = (B64[a] or 0) * 262144 + (B64[b] or 0) * 4096 + (B64[c] or 0) * 64 + (B64[d] or 0)
		local b1 = math.floor(v / 65536)
		local b2 = math.floor(v / 256) % 256
		local b3 = v % 256
		n += 1
		if c == 61 then
			out[n] = string.char(b1)
		elseif d == 61 then
			out[n] = string.char(b1, b2)
		else
			out[n] = string.char(b1, b2, b3)
		end
	end
	return table.concat(out)
end

-- writes an embedded file into the workspace and returns a usable asset id
local function saveAsset(fileName, b64)
	if not (writefile and getcustomasset) then
		return ""
	end
	local ok = pcall(function()
		writefile(fileName, b64decode(b64))
	end)
	if not ok then
		return ""
	end
	local ok2, asset = pcall(getcustomasset, fileName)
	if ok2 and asset then
		return asset
	end
	return ""
end

local LOGO_ID = saveAsset("snowy_logo.png", DATA.LOGO)
local BANNER_ID = saveAsset("snowy_banner.jpg", DATA.BANNER)
local IMAGE_ID = LOGO_ID

--// MUSIC SETUP
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

--// GLASS BREAK SOUND
local glassSound
do
	local asset = saveAsset("snowy_glass.mp3", DATA.GLASS)
	if asset ~= "" then
		glassSound = Instance.new("Sound")
		glassSound.Name = "SnowyHubGlassBreak"
		glassSound.SoundId = asset
		glassSound.Volume = GLASS_VOLUME
		glassSound.Looped = false
		glassSound.Parent = SoundService
	end
end

--// LOADING GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SnowyHub"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getGuiParent()

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

--// ROTATING LOGO + GLOW
local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.fromScale(0.5, 0.47)
holder.Size = UDim2.fromOffset(math.floor(190 * LOGO_ASPECT), 190)
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

--// PERCENT + STATUS
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

--// =====================================================================
--// HUB (opens after the glass breaks) - empty on purpose, add features in the content area
--// =====================================================================
local function buildHub()
	local displayName = HUB_NAME or player.Name

	local hubGui = Instance.new("ScreenGui")
	hubGui.Name = "SnowyHubUI"
	hubGui.ResetOnSpawn = false
	hubGui.IgnoreGuiInset = true
	hubGui.DisplayOrder = 998
	hubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hubGui.Parent = getGuiParent()

	local W, H = 820, 520
	local SIDE, HEAD, FOOT = 230, 56, 30

	local C_BG = Color3.fromRGB(11, 8, 12)
	local C_SIDE = Color3.fromRGB(15, 9, 13)
	local C_LINE = Color3.fromRGB(60, 17, 24)
	local C_DIM = Color3.fromRGB(135, 125, 135)
	local C_RED = Color3.fromRGB(255, 70, 70)
		--// HOME + ESP STATE (additive, nothing else reads these)
	local state = {
		esp = false,
		espTeamCheck = true,
		espMaxDist = 2000,
	}

	--// DRAWING-BASED PLAYER ESP
	local espDrawings = {}   -- [player] = { box, name, dist }
	local ESP = {}

	local function espCleanup(plr)
		local d = espDrawings[plr]
		if not d then return end
		for _, obj in pairs(d) do
			if obj and obj.Remove then pcall(function() obj:Remove() end) end
		end
		espDrawings[plr] = nil
	end

	local function espEnsure(plr)
		if espDrawings[plr] then return espDrawings[plr] end
		if not Drawing then return nil end
		local ok, d = pcall(function()
			return {
				box  = Drawing.new("Square"),
				name = Drawing.new("Text"),
				dist = Drawing.new("Text"),
			}
		end)
		if not ok or not d then return nil end
		d.box.Thickness = 1
		d.box.Filled    = false
		d.box.Color     = Color3.fromRGB(255, 70, 70)
		d.name.Size     = 14
		d.name.Center   = true
		d.name.Outline  = true
		d.dist.Size     = 12
		d.dist.Center   = true
		d.dist.Outline  = true
		espDrawings[plr] = d
		return d
	end

	ESP.tick = function()
		if not Drawing then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local me = player

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == me then continue end

			local d = espEnsure(plr)
			if not d then continue end

			local hide = not state.esp
			if state.espTeamCheck and plr.Team and me.Team and plr.Team == me.Team then
				hide = true
			end

			local char = plr.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			local head = char and char:FindFirstChild("Head")
			local hum  = char and char:FindFirstChildOfClass("Humanoid")

			if hide or not hrp or not head or not hum or hum.Health <= 0 then
				d.box.Visible = false
				d.name.Visible = false
				d.dist.Visible = false
				continue
			end

			local dist = (cam.CFrame.Position - hrp.Position).Magnitude
			if dist > state.espMaxDist then
				d.box.Visible = false
				d.name.Visible = false
				d.dist.Visible = false
				continue
			end

			local top    = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
			local bottom = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
			local topOnScreen    = select(2, cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)))
			local bottomOnScreen = select(2, cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)))

			if not topOnScreen or not bottomOnScreen then
				d.box.Visible = false
				d.name.Visible = false
				d.dist.Visible = false
				continue
			end

			local h = bottom.Y - top.Y
			if h <= 0 then
				d.box.Visible = false
				d.name.Visible = false
				d.dist.Visible = false
				continue
			end
			local w = h * 0.55

			d.box.Size     = Vector2.new(w, h)
			d.box.Position = Vector2.new(top.X - w / 2, top.Y)
			d.box.Visible  = true

			d.name.Text     = plr.Name
			d.name.Position = Vector2.new(top.X, top.Y - 16)
			d.name.Visible  = true

			d.dist.Text     = string.format("%dm", math.floor(dist))
			d.dist.Position = Vector2.new(top.X, bottom.Y + 2)
			d.dist.Visible  = true
		end
	end

	Players.PlayerRemoving:Connect(espCleanup)

	local function makeLine(parent, size, pos)
		local l = Instance.new("Frame")
		l.Size = size
		l.Position = pos
		l.BackgroundColor3 = C_LINE
		l.BorderSizePixel = 0
		l.Parent = parent
		return l
	end

	local function makeLabel(parent, text, font, size, color, pos, sz, align)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Text = text
		t.Font = font
		t.TextSize = size
		t.TextColor3 = color
		t.Position = pos
		t.Size = sz
		t.TextXAlignment = align or Enum.TextXAlignment.Left
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.Parent = parent
		return t
	end

	-- window (CanvasGroup so it can fade in/out as one piece)
	local win = Instance.new("CanvasGroup")
	win.Name = "Window"
	win.AnchorPoint = Vector2.new(0.5, 0.5)
	win.Position = UDim2.fromScale(0.5, 0.5)
	win.Size = UDim2.fromOffset(W, H)
	win.BackgroundColor3 = C_BG
	win.BorderSizePixel = 0
	win.GroupTransparency = 1
	win.Active = true
	win.Parent = hubGui
	Instance.new("UICorner", win).CornerRadius = UDim.new(0, 14)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = win

	-- soft red-tinted background
	local bgFrame = Instance.new("Frame")
	bgFrame.Size = UDim2.fromScale(1, 1)
	bgFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = win
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new(Color3.fromRGB(26, 10, 15), Color3.fromRGB(9, 7, 10))
	bgGrad.Rotation = 35
	bgGrad.Parent = bgFrame

	-- SIDEBAR
	local side = Instance.new("Frame")
	side.Size = UDim2.new(0, SIDE, 1, -FOOT)
	side.BackgroundColor3 = C_SIDE
	side.BackgroundTransparency = 0.1
	side.BorderSizePixel = 0
	side.Parent = win
	makeLine(side, UDim2.new(0, 1, 1, 0), UDim2.new(1, -1, 0, 0))

	local banner = Instance.new("ImageLabel")
	banner.Size = UDim2.new(1, 0, 0, 150)
	banner.BackgroundColor3 = Color3.fromRGB(30, 8, 10)
	banner.BorderSizePixel = 0
	banner.Image = BANNER_ID
	banner.ScaleType = Enum.ScaleType.Crop
	banner.Parent = side

	local fade = Instance.new("Frame")
	fade.Size = UDim2.new(1, 0, 0, 100)
	fade.Position = UDim2.new(0, 0, 1, -100)
	fade.BackgroundColor3 = C_SIDE
	fade.BorderSizePixel = 0
	fade.Parent = banner
	local fadeGrad = Instance.new("UIGradient")
	fadeGrad.Rotation = 90
	fadeGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	fadeGrad.Parent = fade

	local sideLogo = Instance.new("ImageLabel")
	sideLogo.Position = UDim2.fromOffset(14, 86)
	sideLogo.Size = UDim2.fromOffset(math.floor(52 * LOGO_ASPECT), 52)
	sideLogo.BackgroundTransparency = 1
	sideLogo.Image = LOGO_ID
	sideLogo.Parent = banner

	makeLabel(banner, displayName, Enum.Font.GothamBold, 20, Color3.new(1, 1, 1),
		UDim2.fromOffset(66, 90), UDim2.fromOffset(152, 26))
	makeLabel(banner, HUB_NAME_CN, Enum.Font.GothamMedium, 13, C_RED,
		UDim2.fromOffset(66, 118), UDim2.fromOffset(152, 18))

	-- user card (bottom of the sidebar)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 64)
	card.Position = UDim2.new(0, 0, 1, -64)
	card.BackgroundTransparency = 1
	card.Parent = side
	makeLine(card, UDim2.new(1, 0, 0, 1), UDim2.fromOffset(0, 0))

	local avatar = Instance.new("ImageLabel")
	avatar.Position = UDim2.fromOffset(14, 14)
	avatar.Size = UDim2.fromOffset(38, 38)
	avatar.BackgroundColor3 = Color3.fromRGB(40, 14, 18)
	avatar.BorderSizePixel = 0
	avatar.Parent = card
	Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
	local avStroke = Instance.new("UIStroke")
	avStroke.Color = Color3.fromRGB(200, 30, 40)
	avStroke.Thickness = 1.5
	avStroke.Parent = avatar

	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and content then
			avatar.Image = content
		end
	end)

	makeLabel(card, displayName, Enum.Font.GothamMedium, 14, Color3.new(1, 1, 1),
		UDim2.fromOffset(62, 15), UDim2.fromOffset(158, 18))
	makeLabel(card, "MEMBER", Enum.Font.GothamBold, 10, C_RED,
		UDim2.fromOffset(62, 35), UDim2.fromOffset(158, 14))

	-- HEADER
	local head = Instance.new("Frame")
	head.Name = "Header"
	head.Size = UDim2.new(1, -SIDE, 0, HEAD)
	head.Position = UDim2.fromOffset(SIDE, 0)
	head.BackgroundTransparency = 1
	head.Active = true
	head.Parent = win
	makeLine(head, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1))

	local titleBox = Instance.new("Frame")
	titleBox.AnchorPoint = Vector2.new(0, 0.5)
	titleBox.Position = UDim2.new(0, 24, 0.5, 0)
	titleBox.Size = UDim2.fromOffset(0, 24)
	titleBox.AutomaticSize = Enum.AutomaticSize.X
	titleBox.BackgroundTransparency = 1
	titleBox.Parent = head
	local titleList = Instance.new("UIListLayout")
	titleList.FillDirection = Enum.FillDirection.Horizontal
	titleList.VerticalAlignment = Enum.VerticalAlignment.Center
	titleList.Padding = UDim.new(0, 8)
	titleList.Parent = titleBox

	local hubTitle = makeLabel(titleBox, "Snowy Hub", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1),
		UDim2.new(), UDim2.fromOffset(0, 24))
	hubTitle.AutomaticSize = Enum.AutomaticSize.X
	hubTitle.TextTruncate = Enum.TextTruncate.None
	local hubTag = makeLabel(titleBox, HUB_VERSION, Enum.Font.GothamBold, 11, C_DIM,
		UDim2.new(), UDim2.fromOffset(0, 24))
	hubTag.AutomaticSize = Enum.AutomaticSize.X
	hubTag.TextTruncate = Enum.TextTruncate.None

	local redDot = Instance.new("Frame")
	redDot.AnchorPoint = Vector2.new(1, 0.5)
	redDot.Position = UDim2.new(1, -62, 0.5, 0)
	redDot.Size = UDim2.fromOffset(9, 9)
	redDot.BackgroundColor3 = Color3.fromRGB(255, 50, 60)
	redDot.BorderSizePixel = 0
	redDot.Parent = head
	Instance.new("UICorner", redDot).CornerRadius = UDim.new(1, 0)

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -16, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(30, 30)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(200, 195, 205)
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = head

	-- CONTENT (empty - this is where your features go)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(SIDE, HEAD)
	content.Size = UDim2.new(1, -SIDE, 1, -(HEAD + FOOT))
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = win

	-- a little drifting snow in the empty area
	local hubFlakes = {}
	for i = 1, 26 do
		local f = Instance.new("Frame")
		local s = rng:NextInteger(2, 5)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromOffset(s, s)
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BackgroundTransparency = rng:NextNumber(0.55, 0.9)
		f.BorderSizePixel = 0
		f.Parent = content
		Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
		hubFlakes[i] = {
			frame = f,
			x = rng:NextNumber(0, 1),
			y = rng:NextNumber(0, 1),
			speed = rng:NextNumber(0.02, 0.07),
			phase = rng:NextNumber(0, math.pi * 2),
		}
	end

	local hubT = 0
	local snowConn = RunService.Heartbeat:Connect(function(dt)
		hubT += dt
		for _, f in ipairs(hubFlakes) do
			f.y += f.speed * dt
			if f.y > 1.05 then
				f.y = -0.05
				f.x = rng:NextNumber(0, 1)
			end
			f.frame.Position = UDim2.fromScale(f.x + math.sin(hubT + f.phase) * 0.01, f.y)
	
		end
			ESP.tick()
	end)

	-- FOOTER
	local foot = Instance.new("Frame")
	foot.Size = UDim2.new(1, 0, 0, FOOT)
	foot.Position = UDim2.new(0, 0, 1, -FOOT)
	foot.BackgroundColor3 = Color3.fromRGB(8, 6, 9)
	foot.BackgroundTransparency = 0.2
	foot.BorderSizePixel = 0
	foot.Parent = win
	makeLine(foot, UDim2.new(1, 0, 0, 1), UDim2.fromOffset(0, 0))

	makeLabel(foot, "SNOWY HUB  ·  " .. HUB_VERSION, Enum.Font.GothamMedium, 10, C_DIM,
		UDim2.new(0, SIDE + 24, 0.5, -7), UDim2.fromOffset(240, 14))

	local hint = Instance.new("Frame")
	hint.AnchorPoint = Vector2.new(1, 0.5)
	hint.Position = UDim2.new(1, -16, 0.5, 0)
	hint.Size = UDim2.fromOffset(0, 14)
	hint.AutomaticSize = Enum.AutomaticSize.X
	hint.BackgroundTransparency = 1
	hint.Parent = foot
	local hintList = Instance.new("UIListLayout")
	hintList.FillDirection = Enum.FillDirection.Horizontal
	hintList.VerticalAlignment = Enum.VerticalAlignment.Center
	hintList.Padding = UDim.new(0, 6)
	hintList.Parent = hint

	local greenDot = Instance.new("Frame")
	greenDot.Size = UDim2.fromOffset(6, 6)
	greenDot.BackgroundColor3 = Color3.fromRGB(60, 220, 110)
	greenDot.BorderSizePixel = 0
	greenDot.LayoutOrder = 1
	greenDot.Parent = hint
	Instance.new("UICorner", greenDot).CornerRadius = UDim.new(1, 0)

	local keyName = (TOGGLE_KEY == Enum.KeyCode.RightShift) and "RSHIFT" or string.upper(TOGGLE_KEY.Name)
	local hintText = makeLabel(hint, keyName .. " TO HIDE", Enum.Font.GothamMedium, 10, C_DIM,
		UDim2.new(), UDim2.fromOffset(0, 14))
	hintText.AutomaticSize = Enum.AutomaticSize.X
	hintText.TextTruncate = Enum.TextTruncate.None
	hintText.LayoutOrder = 2

	-- red border on top of everything
	local border = Instance.new("Frame")
	border.Position = UDim2.fromOffset(1, 1)
	border.Size = UDim2.new(1, -2, 1, -2)
	border.BackgroundTransparency = 1
	border.ZIndex = 50
	border.Parent = win
	Instance.new("UICorner", border).CornerRadius = UDim.new(0, 13)
	local borderStroke = Instance.new("UIStroke")
	borderStroke.Color = Color3.fromRGB(150, 24, 34)
	borderStroke.Thickness = 1.5
	borderStroke.Transparency = 0.25
	borderStroke.Parent = border

	-- DRAGGING (hold the header)
	local dragging, dragStart, startPos = false, nil, nil
	head.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = win.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	-- SHOW / HIDE
	local shown = true
	local function setShown(v)
		shown = v
		if v then
			win.Visible = true
			TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
			TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		else
			TweenService:Create(win, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 }):Play()
			TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.94 }):Play()
			task.delay(0.22, function()
				if not shown then
					win.Visible = false
				end
			end)
		end
	end

	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 70, 80) }):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(200, 195, 205) }):Play()
	end)
	closeBtn.MouseButton1Click:Connect(function()
		setShown(false)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == TOGGLE_KEY then
			setShown(not shown)
		end
	end)

	hubGui.Destroying:Connect(function()
		snowConn:Disconnect()
	end)

	-- OPEN ANIMATION
	TweenService:Create(win, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
	TweenService:Create(scale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

--// LOGO REVEAL (transparent logo on top of the game - you can keep playing)
local function revealLogo(onFade)
	local logoGui = Instance.new("ScreenGui")
	logoGui.Name = "SnowyHubLogo"
	logoGui.IgnoreGuiInset = true
	logoGui.ResetOnSpawn = false
	logoGui.DisplayOrder = 997
	logoGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	logoGui.Parent = getGuiParent()

	local h = 250
	local logoHolder = Instance.new("Frame")
	logoHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	logoHolder.Position = UDim2.fromScale(0.5, 0.5)
	logoHolder.Size = UDim2.fromOffset(math.floor(h * LOGO_ASPECT), h)
	logoHolder.BackgroundTransparency = 1
	logoHolder.Parent = logoGui

	local holderScale = Instance.new("UIScale")
	holderScale.Scale = 0.65
	holderScale.Parent = logoHolder

	local glowL = Instance.new("ImageLabel")
	glowL.AnchorPoint = Vector2.new(0.5, 0.5)
	glowL.Position = UDim2.fromScale(0.5, 0.5)
	glowL.Size = UDim2.fromScale(1.4, 1.4)
	glowL.BackgroundTransparency = 1
	glowL.Image = LOGO_ID
	glowL.ImageColor3 = GLOW_COLOR
	glowL.ImageTransparency = 1
	glowL.ZIndex = 1
	glowL.Parent = logoHolder

	local logoL = Instance.new("ImageLabel")
	logoL.AnchorPoint = Vector2.new(0.5, 0.5)
	logoL.Position = UDim2.fromScale(0.5, 0.5)
	logoL.Size = UDim2.fromScale(1, 1)
	logoL.BackgroundTransparency = 1
	logoL.Image = LOGO_ID
	logoL.ImageTransparency = 1
	logoL.ZIndex = 2
	logoL.Parent = logoHolder

	TweenService:Create(logoL, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0 }):Play()
	TweenService:Create(holderScale, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local t0, leaveT, leaving = 0, 0, false
	local pulseConn = RunService.RenderStepped:Connect(function(dt)
		t0 += dt
		if leaving then
			leaveT += dt
		end
		local vis = math.clamp(t0 / 0.7, 0, 1) * (1 - math.clamp(leaveT / 0.5, 0, 1))
		local pulse = (math.sin(t0 * 3) + 1) / 2
		local base = 0.8 - pulse * 0.3
		glowL.ImageTransparency = 1 - vis * (1 - base)
	end)

	task.wait(1.8)

	leaving = true
	if onFade then
		task.spawn(onFade)
	end
	TweenService:Create(logoL, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
	TweenService:Create(holderScale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1.2 }):Play()

	task.wait(0.6)
	pulseConn:Disconnect()
	logoGui:Destroy()
end

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
	if conn then
		conn:Disconnect()
	end
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

	-- logo appears over the game, then the hub opens
	task.spawn(function()
		task.wait(0.5)
		revealLogo(buildHub)
	end)

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

	-- rotate logo
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

end -- main

--// EMBEDDED IMAGES + SOUND (don't edit)
DATA.LOGO = [[
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
UMoRUGQAAAAASUVORK5CYII=
]]

DATA.BANNER = [[
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
F5E6fsw1Ot1bZ5jJP+5ohVKGn9dSaecI1f5fHVf6UcSXLwatPpXKC09uFXHlP7nKyIp/lMiZdplB
6apqG6zbydWLXTsrrhU9m7z2LNHTKtWSjNNJcZNum1N06nC7CocuJrumZXXez0qxt4lKOM6bQ1VT
0KxrM+5902b49XlZKNfUIuE2uZLhMw16Ke7E8qGcxm/JPVNZptPpPTuxKa+mSK3qmdxYplbbPY0W
n1d9rWl/czy2+yR8l+u9JVpuqJVyi24rcl8lC/VWuoqnRpp7IS7td2eLq9Zdq7XZfNyk/LNGHDc3
yfoxeV5WPJLlFLWEQMg2nmFlc9rJ3ttsrLaFu4ONFkVT+KFSU5PJFtW1nTi4T4LLvoTObLVCctP2
jLhDJ0oZWSHBnSjTRByS+CUss6ROSS2VSUMlcY7mDrlp9nUEpGmqpZyVOlxjlFmn3PuQpmnFPGkq
RdtceRzImb9pFbwnkrNzS3pETe0imKc8oibUlks00cLI9IglytL6L0SQSVM9FAAHDoAABTqYRjNN
IOpWxX3Juv8AVhuUV/QzfxLi014LltnnXWOX+zOJQdU8I5uio85yanKFkN0nyZvTlJvKeCaf5M14
0up72U8vscvg20NVKWYp5M1sctskmZ7xtLbKgTggkUgAAAAAAAAAAAAAAAAAA6hJxeYvBC5ZfTU7
bFVFe9/JxnVvfR6fSdbs3qyWJNYX3PYrhVd7YyfbMjw6OnXy1FcXHCT90s8I19Z11enl/DaN42cT
kv8AcZbjlXR6mDyXE/Mt1Nz3enW8Qj2wUT6jdGKozhJ5T+5TTPfVGUu7OpJY7I4oS6Zsq3U7ll+r
6vqVXCN1jbgvavg8TUamzUTcrJNmmXKkrPfXnv5RmvodeJRe6D7NF2OZR53k3bWl6KGQS+5BceeA
AAC7TvEioJ4DJS9PZrs5ksHVi/aM0bWjtX+1pkNM1rLDbf5Kk3jCJ3PGGdUNepz2Zovp2pSiuGdb
0VRjqpdJmN8kwWWTOGOS2NalFY7ndkFDbJnxX8lEW08o0yqxHGSY1wS57kdl1Yqpr6Oq574pMJuE
mkQpRhyTTNTm89iLNCfpN9leZTsLpPCeTpqMZZRTbYm+Dns61/DTbfZXHLlhG+qO2KRm00cybZrX
Yjkf0W+JH/UyQAVG4AAAAAAp6VVO+uz+WKMeorasxHvk60Oqnppva8KXc03zrk1KPfuaO5o8iVOX
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
ZAAAAAACeAMAA//Z
]]

DATA.GLASS = [[
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

main()
