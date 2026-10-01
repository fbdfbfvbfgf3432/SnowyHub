-- Snowy Hub: loading screen + hub
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TITLE = "Snowy Hub"
local CREDIT = "Made By Crscx2210"
local SNOW_COUNT = 70
local ROTATE_SPEED = 45
local GLOW_COLOR = Color3.fromRGB(255, 30, 30)
local LOAD_TIME = 8

local HUB_NAME = "𝐂𝐫𝐬𝐜𝐱"
local HUB_NAME_CN = "克里斯克斯"
local HUB_VERSION = "V1.0"
local TOGGLE_KEY = Enum.KeyCode.RightShift

local AUDIO_FILE = "crscx_song.mp3"
local AUDIO_VOLUME = 0.3
local GLASS_VOLUME = 0.6
local LOGO_ASPECT = 0.8325

local function main()

local rng = Random.new()

local function getGuiParent()
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	return playerGui
end

local function getCustom(name)
	if not (getcustomasset and isfile) then return "" end
	if not isfile(name) then return "" end
	local ok, asset = pcall(getcustomasset, name)
	if ok and asset then return asset end
	return ""
end

local LOGO_ID = getCustom("snowy_logo.png")
if LOGO_ID == "" then LOGO_ID = getCustom("crscx_logo.png") end
local BANNER_ID = getCustom("snowy_banner.jpg")
if BANNER_ID == "" then BANNER_ID = getCustom("crscx_banner.jpg") end
local IMAGE_ID = LOGO_ID

local function loadSound()
	if not (isfile and getcustomasset) then return nil end
	if not isfile(AUDIO_FILE) then return nil end
	local ok, asset = pcall(getcustomasset, AUDIO_FILE)
	if not ok then return nil end
	local s = Instance.new("Sound")
	s.Name = "SnowyHubMusic"
	s.SoundId = asset
	s.Volume = AUDIO_VOLUME
	s.Looped = false
	s.Parent = SoundService
	return s
end

local sound = loadSound()

local glassSound
do
	local asset = getCustom("snowy_glass.mp3")
	if asset == "" then asset = getCustom("crscx_glass.mp3") end
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
makeTitle(Color3.fromRGB(255, 60, 60), -1, 5, 0.35)
makeTitle(Color3.fromRGB(60, 120, 255), 1, 5, 0.35)
makeTitle(Color3.fromRGB(235, 235, 235), 0, 6, 0)

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

	local state = {
		esp = false, espTeamCheck = true, espMaxDist = 2000,
		hitbox = false, hitboxScale = 2.5,
		silentAim = false, silentFov = 120, wallCheck = true,
	}
	local ARSENAL_PLACE = 286090429

	local espDrawings = {}
	local ESP = {}

	local function espEnsure(plr)
		if espDrawings[plr] then return espDrawings[plr] end
		if not Drawing then return nil end
		local ok, d = pcall(function()
			return { box = Drawing.new("Square"), name = Drawing.new("Text"), dist = Drawing.new("Text") }
		end)
		if not ok or not d then return nil end
		d.box.Thickness = 1; d.box.Filled = false; d.box.Color = C_RED
		d.name.Size = 14; d.name.Center = true; d.name.Outline = true; d.name.Color = Color3.new(1,1,1)
		d.dist.Size = 12; d.dist.Center = true; d.dist.Outline = true; d.dist.Color = Color3.new(1,1,1)
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
			if state.espTeamCheck and plr.Team and me.Team and plr.Team == me.Team then hide = true end
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local head = char and char:FindFirstChild("Head")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hide or not hrp or not head or not hum or hum.Health <= 0 then
				d.box.Visible = false; d.name.Visible = false; d.dist.Visible = false
				continue
			end
			local dist = (cam.CFrame.Position - hrp.Position).Magnitude
			if dist > state.espMaxDist then
				d.box.Visible = false; d.name.Visible = false; d.dist.Visible = false
				continue
			end
			local top, topOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
			local bottom, botOn = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
			if not topOn or not botOn then
				d.box.Visible = false; d.name.Visible = false; d.dist.Visible = false
				continue
			end
			local h = bottom.Y - top.Y
			if h <= 0 then
				d.box.Visible = false; d.name.Visible = false; d.dist.Visible = false
				continue
			end
			local w = h * 0.55
			d.box.Size = Vector2.new(w, h)
			d.box.Position = Vector2.new(top.X - w/2, top.Y)
			d.box.Visible = true
			d.name.Text = plr.Name
			d.name.Position = Vector2.new(top.X, top.Y - 16)
			d.name.Visible = true
			d.dist.Text = string.format("%dm", math.floor(dist))
			d.dist.Position = Vector2.new(top.X, bottom.Y + 2)
			d.dist.Visible = true
		end
	end

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

	local silentTarget = nil
	local function pickSilentTarget()
		local cam = workspace.CurrentCamera
		if not cam then return nil end
		local me = player
		local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
		local best, bestDist = nil, state.silentFov
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == me then continue end
			if plr.Team and me.Team and plr.Team == me.Team then continue end
			local char = plr.Character
			local head = char and char:FindFirstChild("Head")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
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

	local function arsenalTick()
		ESP.tick()
		if game.PlaceId ~= ARSENAL_PLACE then return end
		if state.hitbox and not hitboxOriginals.__applied then
			applyHitbox(true); hitboxOriginals.__applied = true
		elseif not state.hitbox and hitboxOriginals.__applied then
			applyHitbox(false); hitboxOriginals.__applied = false
		end
		if state.silentAim then
			silentTarget = pickSilentTarget()
			if silentTarget and hookmetamethod and not state.__silentHooked then
				state.__silentHooked = true
				pcall(function()
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
			end
		end
	end

	local function makeLine(parent, size, pos)
		local l = Instance.new("Frame")
		l.Size = size; l.Position = pos
		l.BackgroundColor3 = C_LINE; l.BorderSizePixel = 0
		l.Parent = parent
		return l
	end

	local function makeLabel(parent, text, font, size, color, pos, sz)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Text = text; t.Font = font; t.TextSize = size
		t.TextColor3 = color; t.Position = pos; t.Size = sz
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.Parent = parent
		return t
	end

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

	local bgFrame = Instance.new("Frame")
	bgFrame.Size = UDim2.fromScale(1, 1)
	bgFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = win
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new(Color3.fromRGB(26, 10, 15), Color3.fromRGB(9, 7, 10))
	bgGrad.Rotation = 35
	bgGrad.Parent = bgFrame

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
	fadeGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
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
		if ok and content then avatar.Image = content end
	end)
	makeLabel(card, displayName, Enum.Font.GothamMedium, 14, Color3.new(1, 1, 1),
		UDim2.fromOffset(62, 15), UDim2.fromOffset(158, 18))
	makeLabel(card, "MEMBER", Enum.Font.GothamBold, 10, C_RED,
		UDim2.fromOffset(62, 35), UDim2.fromOffset(158, 14))

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
	local hubTitle = makeLabel(titleBox, "Snowy Hub", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1), UDim2.new(), UDim2.fromOffset(0, 24))
	hubTitle.AutomaticSize = Enum.AutomaticSize.X
	hubTitle.TextTruncate = Enum.TextTruncate.None
	local hubTag = makeLabel(titleBox, HUB_VERSION, Enum.Font.GothamBold, 11, C_DIM, UDim2.new(), UDim2.fromOffset(0, 24))
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

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(SIDE, HEAD)
	content.Size = UDim2.new(1, -SIDE, 1, -(HEAD + FOOT))
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = win

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
		cs.Color = C_LINE; cs.Thickness = 1; cs.Transparency = 0.3; cs.Parent = c
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
		s.TextColor3 = C_DIM
		s.TextXAlignment = Enum.TextXAlignment.Left
		s.Text = subtitle
		s.Parent = c
		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -16, 0.5, 0)
		btn.Size = UDim2.fromOffset(78, 28)
		btn.BackgroundColor3 = C_RED
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.TextColor3 = C_RED
		btn.Text = "OFF"
		btn.AutoButtonColor = false
		btn.Parent = c
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		local bs = Instance.new("UIStroke")
		bs.Color = C_RED; bs.Thickness = 1.5; bs.Transparency = 0.3; bs.Parent = btn
		local function refresh()
			local on = getFn()
			btn.Text = on and "ON" or "OFF"
			btn.TextColor3 = on and Color3.new(1,1,1) or C_RED
			btn.BackgroundTransparency = on and 0.15 or 1
			bs.Transparency = on and 0.15 or 0.3
		end
		btn.MouseButton1Click:Connect(function()
			setFn(not getFn())
			refresh()
		end)
		refresh()
		
		return c
	end

	local function makeSlider(parent, y, title, min, max, init, setFn)
		local c = Instance.new("Frame")
		c.Position = UDim2.fromOffset(20, y)
		c.Size = UDim2.new(1, -40, 0, 68)
		c.BackgroundColor3 = Color3.fromRGB(22, 12, 16)
		c.BackgroundTransparency = 0.15
		c.BorderSizePixel = 0
		c.Parent = parent
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
		local cs = Instance.new("UIStroke")
		cs.Color = C_LINE; cs.Thickness = 1; cs.Transparency = 0.3; cs.Parent = c
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromOffset(16, 10)
		t.Size = UDim2.new(1, -100, 0, 18)
		t.Font = Enum.Font.GothamBold
		t.TextSize = 14
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = title
		t.Parent = c
		local val = Instance.new("TextLabel")
		val.BackgroundTransparency = 1
		val.AnchorPoint = Vector2.new(1, 0)
		val.Position = UDim2.new(1, -16, 0, 10)
		val.Size = UDim2.fromOffset(80, 18)
		val.Font = Enum.Font.GothamBold
		val.TextSize = 13
		val.TextColor3 = C_RED
		val.TextXAlignment = Enum.TextXAlignment.Right
		val.Text = tostring(init)
		val.Parent = c
		local bar = Instance.new("Frame")
		bar.Position = UDim2.fromOffset(16, 44)
		bar.Size = UDim2.new(1, -32, 0, 6)
		bar.BackgroundColor3 = Color3.fromRGB(40, 20, 24)
		bar.BorderSizePixel = 0
		bar.Parent = c
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale((init - min) / (max - min), 1)
		fill.BackgroundColor3 = C_RED
		fill.BorderSizePixel = 0
		fill.Parent = bar
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
		local dragging = false
		local function update(x)
			local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			fill.Size = UDim2.fromScale(rel, 1)
			local v = math.floor((min + (max - min) * rel) * 10 + 0.5) / 10
			val.Text = tostring(v)
			setFn(v)
		end
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(input.Position.X)
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
	end

	local sideTabs = Instance.new("Frame")
	sideTabs.Position = UDim2.fromOffset(0, 160)
	sideTabs.Size = UDim2.new(1, 0, 1, -(160 + 64))
	sideTabs.BackgroundTransparency = 1
	sideTabs.Parent = side
	local sideList = Instance.new("UIListLayout")
	sideList.Padding = UDim.new(0, 4)
	sideList.SortOrder = Enum.SortOrder.LayoutOrder
	sideList.Parent = sideTabs
	local sidePad = Instance.new("UIPadding")
	sidePad.PaddingLeft = UDim.new(0, 10)
	sidePad.PaddingRight = UDim.new(0, 10)
	sidePad.PaddingTop = UDim.new(0, 8)
	sidePad.Parent = sideTabs

	local function makeTab(name, order, pageName)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -20, 0, 34)
		btn.BackgroundColor3 = Color3.fromRGB(28, 14, 18)
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 13
		btn.TextColor3 = C_DIM
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Text = "  " .. name
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.Parent = sideTabs
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.Position = UDim2.fromOffset(0, 0.5)
		bar.Size = UDim2.fromOffset(3, 18)
		bar.BackgroundColor3 = C_RED
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
			if activePage ~= pageName then btn.TextColor3 = Color3.fromRGB(210, 200, 210) end
		end)
		btn.MouseLeave:Connect(function()
			if activePage ~= pageName then btn.TextColor3 = C_DIM end
		end)
		tabButtons[pageName] = { button = btn, setActive = setActive }
	end

	local homePage = makePage("Home")
	local espPage = makePage("Player ESP")
	local arsPage = makePage("Arsenal")

	makeLabel(homePage, "Home", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1), UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeLabel(homePage, "quick toggles", Enum.Font.GothamMedium, 12, C_DIM, UDim2.fromOffset(20, 44), UDim2.fromOffset(400, 18))
	makeCard(homePage, 76, "Player ESP", "box + name + distance", function() return state.esp end, function(v) state.esp = v end)
	makeCard(homePage, 156, "Silent Aim", "shots to nearest target", function() return state.silentAim end, function(v) state.silentAim = v end)
	makeCard(homePage, 236, "Hitbox", "expand Head + torso", function() return state.hitbox end, function(v) state.hitbox = v end)
	makeCard(homePage, 316, "Panic", "all off",
		function() return (state.esp or state.silentAim or state.hitbox) end,
		function() state.esp = false; state.silentAim = false; state.hitbox = false end)

	makeLabel(espPage, "Player ESP", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1), UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeCard(espPage, 76, "Enable ESP", "box + name + distance", function() return state.esp end, function(v) state.esp = v end)
	makeCard(espPage, 156, "Team check", "hide teammates", function() return state.espTeamCheck end, function(v) state.espTeamCheck = v end)
	makeSlider(espPage, 236, "Max distance", 200, 5000, 2000, function(v) state.espMaxDist = v end)

	makeLabel(arsPage, "Arsenal", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1), UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeCard(arsPage, 76, "Silent Aim", "shots to nearest target", function() return state.silentAim end, function(v) state.silentAim = v end)
	makeCard(arsPage, 156, "Wall Check", "skip walled targets", function() return state.wallCheck end, function(v) state.wallCheck = v end)
	makeSlider(arsPage, 236, "Silent FOV", 20, 500, 120, function(v) state.silentFov = v end)
	makeCard(arsPage, 312, "Hitbox Expander", "resize Head + torso", function() return state.hitbox end, function(v) state.hitbox = v end)
	makeSlider(arsPage, 388, "Hitbox Scale", 1.5, 6, 2.5, function(v) state.hitboxScale = v end)

	makeTab("Home", 1, "Home")
	makeTab("Player ESP", 2, "Player ESP")
	makeTab("Arsenal", 3, "Arsenal")
	showPage("Home")

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
		hubFlakes[i] = { frame = f, x = rng:NextNumber(0,1), y = rng:NextNumber(0,1),
			speed = rng:NextNumber(0.02, 0.07), phase = rng:NextNumber(0, math.pi * 2) }
	end

	local hubT = 0
	local snowConn = RunService.Heartbeat:Connect(function(dt)
		hubT += dt
		for _, f in ipairs(hubFlakes) do
			f.y += f.speed * dt
			if f.y > 1.05 then f.y = -0.05; f.x = rng:NextNumber(0, 1) end
			f.frame.Position = UDim2.fromScale(f.x + math.sin(hubT + f.phase) * 0.01, f.y)
		end
		arsenalTick()
	end)

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
	local hintText = makeLabel(hint, keyName .. " TO HIDE", Enum.Font.GothamMedium, 10, C_DIM, UDim2.new(), UDim2.fromOffset(0, 14))
	hintText.AutomaticSize = Enum.AutomaticSize.X
	hintText.TextTruncate = Enum.TextTruncate.None
	hintText.LayoutOrder = 2

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

	local dragging, dragStart, startPos = false, nil, nil
	head.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = win.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

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
				if not shown then win.Visible = false end
			end)
		end
	end
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 70, 80) }):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(200, 195, 205) }):Play()
	end)
	closeBtn.MouseButton1Click:Connect(function() setShown(false) end)
	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == TOGGLE_KEY then setShown(not shown) end
	end)
	hubGui.Destroying:Connect(function() snowConn:Disconnect() end)
	TweenService:Create(win, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
	TweenService:Create(scale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

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
		if leaving then leaveT += dt end
		local vis = math.clamp(t0 / 0.7, 0, 1) * (1 - math.clamp(leaveT / 0.5, 0, 1))
		local pulse = (math.sin(t0 * 3) + 1) / 2
		local base = 0.8 - pulse * 0.3
		glowL.ImageTransparency = 1 - vis * (1 - base)
	end)
	task.wait(1.8)
	leaving = true
	if onFade then task.spawn(onFade) end
	TweenService:Create(logoL, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
	TweenService:Create(holderScale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1.2 }):Play()
	task.wait(0.6)
	pulseConn:Disconnect()
	logoGui:Destroy()
end

local conn
local function shatterScreen()
	local COLS, ROWS = 10, 6
	local W, H = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
	local cw, ch = W / COLS, H / ROWS
	local shardLayer = Instance.new("Frame")
	shardLayer.Size = UDim2.fromScale(1, 1)
	shardLayer.BackgroundTransparency = 1
	shardLayer.ZIndex = 50
	shardLayer.Parent = gui
	local pieces = {}
	for c = 0, COLS - 1 do
		for r = 0, ROWS - 1 do
			local x0, y0 = c * cw, r * ch
			local shard = Instance.new("CanvasGroup")
			shard.AnchorPoint = Vector2.new(0.5, 0.5)
			shard.Position = UDim2.fromOffset(x0 + cw/2, y0 + ch/2)
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
			table.insert(pieces, { shard = shard, cx = x0 + cw/2, cy = y0 + ch/2 })
		end
	end
	if conn then conn:Disconnect() end
	bg.Visible = false
	if glassSound then glassSound:Play() end
	task.wait(0.12)
	for _, p in ipairs(pieces) do
		local dx, dy = p.cx / W - 0.5, p.cy / H - 0.5
		local dist = math.sqrt(dx*dx + dy*dy)
		local delay = dist * 0.5 + rng:NextNumber(0, 0.12)
		local dur = rng:NextNumber(1.0, 1.5)
		local spread = rng:NextNumber(0.6, 1.5)
		local tx = p.cx + dx * spread * W * 0.9
		local ty = p.cy + dy * spread * H * 0.9 + rng:NextNumber(0.4, 1.0) * H
		task.delay(delay, function()
			TweenService:Create(p.shard, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromOffset(tx, ty), Rotation = rng:NextNumber(-220, 220), GroupTransparency = 1 }):Play()
		end)
	end
	task.spawn(function()
		task.wait(0.5)
		revealLogo(buildHub)
	end)
	task.wait(2.6)
	gui:Destroy()
end

local t = 0
local finished = false
local fadingMusic = false
local lastPct = -1
if sound then sound.TimePosition = 0; sound:Play() end

conn = RunService.RenderStepped:Connect(function(dt)
	t += dt
	holder.Rotation = (holder.Rotation + ROTATE_SPEED * dt) % 360
	local pulse = (math.sin(t * 3) + 1) / 2
	glow.ImageTransparency = 0.35 + pulse * 0.5
	local gs = 1.25 + pulse * 0.2
	glow.Size = UDim2.fromScale(gs, gs)
	for _, f in ipairs(flakes) do
		f.y += f.speed * dt
		local xOff = math.sin(t * 1.5 + f.phase) * f.sway
		f.frame.Position = UDim2.fromScale(f.x + xOff, f.y)
		if f.y > 1.05 then resetFlake(f, false) end
	end
	local p = math.clamp(t / LOAD_TIME, 0, 1)
	local eased = 0.5 - 0.5 * math.cos(math.pi * p)
	barFill.Size = UDim2.fromScale(eased, 1)
	local pct = math.floor(eased * 100 + 0.5)
	if pct ~= lastPct then
		lastPct = pct
		percent.Text = pct .. "%"
		if pct < 25 then status.Text = "checking integrity..."
		elseif pct < 55 then status.Text = "loading modules..."
		elseif pct < 85 then status.Text = "preparing interface..."
		elseif pct < 100 then status.Text = "almost done..."
		else status.Text = "done" end
	end
	if sound and not fadingMusic and t >= LOAD_TIME - 1 then
		fadingMusic = true
		TweenService:Create(sound, TweenInfo.new(1), { Volume = 0 }):Play()
	end
	if p >= 1 and not finished then
		finished = true
		task.spawn(function()
			task.wait(0.15)
			if sound then sound:Stop(); sound:Destroy() end
			shatterScreen()
		end)
	end
end)

end -- main
main()
