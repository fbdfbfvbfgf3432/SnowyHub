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
local HUB_NAME = "𝐂𝐫𝐬𝐜𝐱"       -- shown in sidebar top-left + user card
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
--// HUB (opens after the glass breaks)
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

	--// ----- ADDITION: state + ESP + Arsenal (self-contained, nothing above touched) -----

	local state = {
		esp          = false,
		espTeamCheck = true,
		espMaxDist   = 2000,
		hitbox       = false,
		hitboxScale  = 2.5,
		silentAim    = false,
		silentFov    = 120,
		wallCheck    = true,
	}

	local ARSENAL_PLACE = 286090429

	local espDrawings = {}
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
		d.box.Color     = C_RED
		d.name.Size     = 14
		d.name.Center   = true
		d.name.Outline  = true
		d.name.Color    = Color3.new(1, 1, 1)
		d.dist.Size     = 12
		d.dist.Center   = true
		d.dist.Outline  = true
		d.dist.Color    = Color3.new(1, 1, 1)
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
				d.box.Visible  = false
				d.name.Visible = false
				d.dist.Visible = false
				continue
			end

			local dist = (cam.CFrame.Position - hrp.Position).Magnitude
			if dist > state.espMaxDist then
				d.box.Visible  = false
				d.name.Visible = false
				d.dist.Visible = false
				continue
			end

			local top, topOn    = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
			local bottom, botOn = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
			if not topOn or not botOn then
				d.box.Visible  = false
				d.name.Visible = false
				d.dist.Visible = false
				continue
			end

			local h = bottom.Y - top.Y
			if h <= 0 then
				d.box.Visible  = false
				d.name.Visible = false
				d.dist.Visible = false
				continue
			end
			local w = h * 0.55

			d.box.Size     = Vector2.new(w, h)
			d.box.Position = Vector2.new(top.X - w / 2, top.Y)
			d.box.Color    = C_RED
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

	-- Arsenal: hitbox + silent aim (guarded to Arsenal only)
	local hitboxOriginals = {}
	local function applyHitbox(on)
		local char = player.Character
		if not char then return end
		for _, name in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}) do
			local part = char:FindFirstChild(name)
			if not part or not part:IsA("BasePart") then continue end
			if on then
				if not hitboxOriginals[part] then
					hitboxOriginals[part] = { size = part.Size, massless = part.Massless }
				end
				local orig = hitboxOriginals[part].size
				part.Size = Vector3.new(orig.X * state.hitboxScale, orig.Y * state.hitboxScale, orig.Z * state.hitboxScale)
				part.Massless = true
				part.CanCollide = false
			else
				local orig = hitboxOriginals[part]
				if orig then
					part.Size = orig.size
					part.Massless = orig.massless
					part.CanCollide = (name == "HumanoidRootPart")
				end
			end
		end
	end

	player.CharacterAdded:Connect(function()
		hitboxOriginals = {}
		if state.hitbox then
			task.wait(0.5)
			applyHitbox(true)
		end
	end)

	local silentTarget = nil
	local function pickSilentTarget()
		local cam = workspace.CurrentCamera
		if not cam then return nil end
		local me = player
		local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
		local best, bestDist = nil, state.silentFov

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == me then continue end
			if plr.Team and me.Team and plr.Team == me.Team then continue end
			local char = plr.Character
			local head = char and char:FindFirstChild("Head")
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if not head or not hum or hum.Health <= 0 then continue end

			local sp, on = cam:WorldToViewportPoint(head.Position)
			if not on then continue end
			local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
			if d >= bestDist then continue end

			if state.wallCheck then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { me.Character, cam }
				local hit = workspace:Raycast(cam.CFrame.Position, head.Position - cam.CFrame.Position, params)
				if hit and not hit.Instance:IsDescendantOf(char) then continue end
			end

			bestDist = d
			best = plr
		end
		return best
	end

	local function arsenalTick(dt)
		ESP.tick()

		if game.PlaceId ~= ARSENAL_PLACE then return end

		if state.hitbox and not hitboxOriginals.__applied then
			applyHitbox(true)
			hitboxOriginals.__applied = true
		elseif not state.hitbox and hitboxOriginals.__applied then
			applyHitbox(false)
			hitboxOriginals.__applied = false
		end

		if state.silentAim then
			silentTarget = pickSilentTarget()
			if silentTarget and hookmetamethod and not state.__silentHooked then
				state.__silentHooked = true
				local ok = pcall(function()
					local mt = getrawmetatable(game)
					local oldIndex = mt.__index
					setreadonly(mt, false)
					mt.__index = newcclosure(function(self, key)
						if state.silentAim and key == "Hit" and checkcaller() == false and silentTarget then
							local h = silentTarget.Character and silentTarget.Character:FindFirstChild("Head")
							if h then return h.Position end
						end
						return oldIndex(self, key)
					end)
					setreadonly(mt, true)
				end)
				if not ok then state.__silentHooked = false end
			end
		end
	end

	--// ----- END ADDITION -----

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

	-- CONTENT (pages get parented in here)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(SIDE, HEAD)
	content.Size = UDim2.new(1, -SIDE, 1, -(HEAD + FOOT))
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = win

	--// ----- ADDITION: pages + sidebar tabs (below content so content exists) -----

	local pages = {}
	local tabButtons = {}
	local activePage = nil

	local function makePage(name)
		local page = Instance.new("Frame")
		page.Name = name
		page.Size = UDim2.fromScale(1, 1)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.Parent = content
		pages[name] = page
		return page
	end

	local function showPage(name)
		for n, p in pairs(pages) do p.Visible = (n == name) end
		activePage = name
		for tabName, entry in pairs(tabButtons) do
			entry.setActive(tabName == name)
		end
	end

	local function makeCard(parent, y, title, subtitle, getFn, setFn)
		local c = Instance.new("Frame")
		c.Position = UDim2.fromOffset(20, y)
		c.Size = UDim2.new(1, -40, 0, 72)
		c.BackgroundColor3 = Color3.fromRGB(22, 12, 16)
		c.BackgroundTransparency = 0.15
		c.BorderSizePixel = 0
		c.Parent = parent
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
		local cs = Instance.new("UIStroke")
		cs.Color = C_LINE
		cs.Thickness = 1
		cs.Transparency = 0.3
		cs.Parent = c

		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromOffset(16, 12)
		t.Size = UDim2.new(1, -120, 0, 20)
		t.Font = Enum.Font.GothamBold
		t.TextSize = 15
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = title
		t.Parent = c

		local s = Instance.new("TextLabel")
		s.BackgroundTransparency = 1
		s.Position = UDim2.fromOffset(16, 34)
		s.Size = UDim2.new(1, -120, 0, 18)
		s.Font = Enum.Font.GothamMedium
		s.TextSize = 12
