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
		bs.Color = C_RED
		bs.Thickness = 1.5
		bs.Transparency = 0.3
		bs.Parent = btn

		local function refresh()
			local on = getFn()
			btn.Text = on and "ON" or "OFF"
			btn.TextColor3 = on and Color3.new(1, 1, 1) or C_RED
			btn.BackgroundTransparency = on and 0.15 or 1
			bs.Transparency = on and 0.15 or 0.3
		end
		btn.MouseButton1Click:Connect(function()
			setFn(not getFn())
			refresh()
		end)
		refresh()
		c.refresh = refresh
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
		cs.Color = C_LINE
		cs.Thickness = 1
		cs.Transparency = 0.3
		cs.Parent = c
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
			btn.TextColor3 = on and Color3.new(1, 1, 1) or C_DIM
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
	local espPage  = makePage("Player ESP")
	local arsPage  = makePage("Arsenal")

	makeLabel(homePage, "Home", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1),
		UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeLabel(homePage, "quick toggles",
		Enum.Font.GothamMedium, 12, C_DIM,
		UDim2.fromOffset(20, 44), UDim2.fromOffset(400, 18))
	makeCard(homePage, 76, "Player ESP", "box + name + distance",
		function() return state.esp end, function(v) state.esp = v end)
	makeCard(homePage, 156, "Silent Aim", "route shots to nearest target",
		function() return state.silentAim end, function(v) state.silentAim = v end)
	makeCard(homePage, 236, "Hitbox", "expand Head + torso",
		function() return state.hitbox end, function(v) state.hitbox = v end)
	makeCard(homePage, 316, "Panic", "all off",
		function() return (state.esp or state.silentAim or state.hitbox) end,
		function() state.esp = false; state.silentAim = false; state.hitbox = false end)

	makeLabel(espPage, "Player ESP", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1),
		UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeCard(espPage, 76, "Enable ESP", "box + name + distance",
		function() return state.esp end, function(v) state.esp = v end)
	makeCard(espPage, 156, "Team check", "hide teammates",
		function() return state.espTeamCheck end, function(v) state.espTeamCheck = v end)
	makeSlider(espPage, 236, "Max distance", 200, 5000, 2000,
		function(v) state.espMaxDist = v end)

	makeLabel(arsPage, "Arsenal", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1),
		UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeCard(arsPage, 76, "Silent Aim", "shots to nearest target",
		function() return state.silentAim end, function(v) state.silentAim = v end)
	makeCard(arsPage, 156, "Wall Check", "skip walled targets",
		function() return state.wallCheck end, function(v) state.wallCheck = v end)
	makeSlider(arsPage, 236, "Silent FOV", 20, 500, 120,
		function(v) state.silentFov = v end)
	makeCard(arsPage, 312, "Hitbox Expander", "resize Head + torso",
		function() return state.hitbox end, function(v) state.hitbox = v end)
	makeSlider(arsPage, 388, "Hitbox Scale", 1.5, 6, 2.5,
		function(v) state.hitboxScale = v end)

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
		arsenalTick(dt)
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
	local hintText = makeLabel(hint, keyName .. " TO HIDE", Enum.Font.GothamMedium, 10, C_DIM,
		UDim2.new(), UDim2.fromOffset(0, 14))
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

--// LOGO REVEAL
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
			table.insert(pieces, { shard = shard, cx = x0 + cw / 2, cy = y0 + ch / 2 })
		end
	end
	if conn then conn:Disconnect() end
	bg.Visible = false
	if glassSound then glassSound:Play() end
	task.wait(0.12)
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
			TweenService:Create(p.shard, info, { Position = UDim2.fromOffset(tx, ty), Rotation = rng:NextNumber(-220, 220), GroupTransparency = 1 }):Play()
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

if sound then
	sound.TimePosition = 0
	sound:Play()
end

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
