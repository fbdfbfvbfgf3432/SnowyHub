	--// =====================================================================
	--// ADDITION: state, ESP, tabs, Home page, Arsenal page (nothing below C_RED is touched)
	--// =====================================================================

	-- shared state — Home toggles and page toggles write to the same fields
	local state = {
		esp            = false,
		espTeamCheck   = true,
		espMaxDist     = 2000,
		espColor       = Color3.fromRGB(255, 70, 70),

		hitbox         = false,
		hitboxScale    = 2.5,
		silentAim      = false,
		silentFov      = 120,
		silentSmooth   = 0.2,
		noRecoil       = false,
		wallCheck      = true,
	}

	local Players   = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local Camera    = Workspace.CurrentCamera
	local LocalP    = Players.LocalPlayer

	--// ---------- ESP DRAWINGS ----------
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
		d.box.Color     = state.espColor
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
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local me = LocalP

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

			local topPos = head.Position + Vector3.new(0, 0.5, 0)
			local botPos = hrp.Position - Vector3.new(0, 3, 0)
			local top, topOn       = cam:WorldToViewportPoint(topPos)
			local bottom, botOn    = cam:WorldToViewportPoint(botPos)

			if not topOn or not botOn then
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
			d.box.Color    = state.espColor
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

	--// ---------- ARSENAL MODULES ----------
	-- hitbox expander: resizes Head + HumanoidRootPart locally, restored when toggled off
	local hitboxOriginals = {}
	local function applyHitbox(on)
		local char = LocalP.Character
		if not char then return end
		for _, name in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}) do
			local part = char:FindFirstChild(name)
			if not part or not part:IsA("BasePart") then continue end
			if on then
				if not hitboxOriginals[part] then
					hitboxOriginals[part] = {
						size = part.Size,
						massless = part.Massless,
					}
				end
				local orig = hitboxOriginals[part].size
				part.Size = Vector3.new(
					orig.X * state.hitboxScale,
					orig.Y * state.hitboxScale,
					orig.Z * state.hitboxScale
				)
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

	LocalP.CharacterAdded:Connect(function()
		hitboxOriginals = {}
		if state.hitbox then
			task.wait(0.5)
			applyHitbox(true)
		end
	end)

	-- silent aim: nearest target in FOV, respecting team + wall check
	local silentTarget = nil
	local function pickSilentTarget()
		local cam = Workspace.CurrentCamera
		if not cam then return nil end
		local me = LocalP
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
				local hit = Workspace:Raycast(cam.CFrame.Position, head.Position - cam.CFrame.Position, params)
				if hit and not hit.Instance:IsDescendantOf(char) then continue end
			end

			bestDist = d
			best = plr
		end
		return best
	end

	-- no recoil: keep Camera rotation locked to our own aim, strip kick
	local lastCamRot = nil

	-- master tick — called from the existing Heartbeat
	local aimT = 0
	local function arsenalTick(dt)
		ESP.tick()

		-- hitbox apply on state flip
		if state.hitbox and not hitboxOriginals.__applied then
			applyHitbox(true)
			hitboxOriginals.__applied = true
		elseif not state.hitbox and hitboxOriginals.__applied then
			applyHitbox(false)
			hitboxOriginals.__applied = false
		end

		-- silent aim: pick target, override mouse world position if executor supports
		if state.silentAim then
			local tgt = pickSilentTarget()
			silentTarget = tgt
			if tgt then
				local head = tgt.Character and tgt.Character:FindFirstChild("Head")
				if head then
					-- if executor exposes hookmetamethod, hijack Mouse.Hit
					if hookmetamethod then
						-- installed once per toggle; flag on the closure
						if not state.__silentHooked then
							state.__silentHooked = true
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
						end
					end
				end
			end
		end

		-- no recoil
		if state.noRecoil then
			local cam = Workspace.CurrentCamera
			if cam and lastCamRot then
				cam.CFrame = CFrame.new(cam.CFrame.Position) * lastCamRot
			end
		end
		if not state.noRecoil and Workspace.CurrentCamera then
			lastCamRot = Workspace.CurrentCamera.CFrame.Rotation
		elseif state.noRecoil and Workspace.CurrentCamera then
			lastCamRot = lastCamRot or Workspace.CurrentCamera.CFrame.Rotation
		end
	end

	--// ---------- UI HELPERS ----------
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

	-- card with a toggle button (writes to state, reads from state)
	local function makeCard(parent, y, title, subtitle, getFn, setFn)
		local card = Instance.new("Frame")
		card.Position = UDim2.fromOffset(20, y)
		card.Size = UDim2.new(1, -40, 0, 72)
		card.BackgroundColor3 = Color3.fromRGB(22, 12, 16)
		card.BackgroundTransparency = 0.15
		card.BorderSizePixel = 0
		card.Parent = parent
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = C_LINE
		cardStroke.Thickness = 1
		cardStroke.Transparency = 0.3
		cardStroke.Parent = card

		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromOffset(16, 12)
		t.Size = UDim2.new(1, -120, 0, 20)
		t.Font = Enum.Font.GothamBold
		t.TextSize = 15
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = title
		t.Parent = card

		local s = Instance.new("TextLabel")
		s.BackgroundTransparency = 1
		s.Position = UDim2.fromOffset(16, 34)
		s.Size = UDim2.new(1, -120, 0, 18)
		s.Font = Enum.Font.GothamMedium
		s.TextSize = 12
		s.TextColor3 = C_DIM
		s.TextXAlignment = Enum.TextXAlignment.Left
		s.Text = subtitle
		s.Parent = card

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
		btn.Parent = card
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = C_RED
		btnStroke.Thickness = 1.5
		btnStroke.Transparency = 0.3
		btnStroke.Parent = btn

		local function refresh()
			local on = getFn()
			btn.Text = on and "ON" or "OFF"
			btn.TextColor3 = on and Color3.new(1, 1, 1) or C_RED
			btn.BackgroundTransparency = on and 0.15 or 1
			btnStroke.Transparency = on and 0.15 or 0.3
		end

		btn.MouseButton1Click:Connect(function()
			setFn(not getFn())
			refresh()
		end)

		refresh()
		card.refresh = refresh
		return card
	end

	-- slider card
	local function makeSlider(parent, y, title, min, max, init, setFn)
		local card = Instance.new("Frame")
		card.Position = UDim2.fromOffset(20, y)
		card.Size = UDim2.new(1, -40, 0, 68)
		card.BackgroundColor3 = Color3.fromRGB(22, 12, 16)
		card.BackgroundTransparency = 0.15
		card.BorderSizePixel = 0
		card.Parent = parent
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = C_LINE
		cardStroke.Thickness = 1
		cardStroke.Transparency = 0.3
		cardStroke.Parent = card

		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromOffset(16, 10)
		t.Size = UDim2.new(1, -100, 0, 18)
		t.Font = Enum.Font.GothamBold
		t.TextSize = 14
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = title
		t.Parent = card

		local valLabel = Instance.new("TextLabel")
		valLabel.BackgroundTransparency = 1
		valLabel.AnchorPoint = Vector2.new(1, 0)
		valLabel.Position = UDim2.new(1, -16, 0, 10)
		valLabel.Size = UDim2.fromOffset(80, 18)
		valLabel.Font = Enum.Font.GothamBold
		valLabel.TextSize = 13
		valLabel.TextColor3 = C_RED
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.Text = tostring(init)
		valLabel.Parent = card

		local bar = Instance.new("Frame")
		bar.Position = UDim2.fromOffset(16, 44)
		bar.Size = UDim2.new(1, -32, 0, 6)
		bar.BackgroundColor3 = Color3.fromRGB(40, 20, 24)
		bar.BorderSizePixel = 0
		bar.Parent = card
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale((init - min) / (max - min), 1)
		fill.BackgroundColor3 = C_RED
		fill.BorderSizePixel = 0
		fill.Parent = bar
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

		local dragging = false
		local function updateFromX(x)
			local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local v = min + (max - min) * rel
			fill.Size = UDim2.fromScale(rel, 1)
			local rounded = math.floor(v * 10 + 0.5) / 10
			valLabel.Text = tostring(rounded)
			setFn(rounded)
		end

		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromX(input.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromX(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	--// ---------- SIDEBAR TABS ----------
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

		btn.MouseButton1Click:Connect(function()
			showPage(pageName)
		end)

		btn.MouseEnter:Connect(function()
			if activePage ~= pageName then btn.TextColor3 = Color3.fromRGB(210, 200, 210) end
		end)
		btn.MouseLeave:Connect(function()
			if activePage ~= pageName then btn.TextColor3 = C_DIM end
		end)

		tabButtons[pageName] = { button = btn, setActive = setActive }
	end

	-- content container already exists above; make the sidebar list sit between banner and user card
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

	-- // ---------- PAGES ----------
	local homePage = makePage("Home")
	local espPage  = makePage("Player ESP")
	local arsPage  = makePage("Arsenal")

	-- HOME
	makeLabel(homePage, "Home", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1),
		UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeLabel(homePage, "quick toggles — every switch mirrors its page",
		Enum.Font.GothamMedium, 12, C_DIM,
		UDim2.fromOffset(20, 44), UDim2.fromOffset(400, 18))

	makeCard(homePage, 76, "Player ESP", "box + name + distance over players",
		function() return state.esp end, function(v) state.esp = v end)
	makeCard(homePage, 156, "Arsenal — Silent Aim", "shots route to nearest target in FOV",
		function() return state.silentAim end, function(v) state.silentAim = v end)
	makeCard(homePage, 236, "Arsenal — Hitbox", "expand Head + torso for easier hits",
		function() return state.hitbox end, function(v) state.hitbox = v end)
	makeCard(homePage, 316, "Panic — all off", "kills ESP + aim + hitbox at once",
		function() return (state.esp or state.silentAim or state.hitbox) end,
		function() state.esp = false; state.silentAim = false; state.hitbox = false end)

	-- PLAYER ESP
	makeLabel(espPage, "Player ESP", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1),
		UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeLabel(espPage, "drawing-based. teammates hidden by default.",
		Enum.Font.GothamMedium, 12, C_DIM,
		UDim2.fromOffset(20, 44), UDim2.fromOffset(400, 18))

	makeCard(espPage, 76, "Enable ESP", "box + name + distance over players",
		function() return state.esp end, function(v) state.esp = v end)
	makeCard(espPage, 156, "Team check", "hide players on your team",
		function() return state.espTeamCheck end, function(v) state.espTeamCheck = v end)
	makeSlider(espPage, 236, "Max distance", 200, 5000, 2000,
		function(v) state.espMaxDist = v end)

	-- ARSENAL
	makeLabel(arsPage, "Arsenal", Enum.Font.GothamBold, 20, Color3.new(1, 1, 1),
		UDim2.fromOffset(20, 16), UDim2.fromOffset(300, 26))
	makeLabel(arsPage, "silent aim + hitbox + wall check, tuned for Arsenal's gun remotes",
		Enum.Font.GothamMedium, 12, C_DIM,
		UDim2.fromOffset(20, 44), UDim2.fromOffset(460, 18))

	makeCard(arsPage, 76, "Silent Aim", "route shots to nearest target in FOV",
		function() return state.silentAim end, function(v) state.silentAim = v end)
	makeCard(arsPage, 156, "Wall Check", "skip targets behind walls",
		function() return state.wallCheck end, function(v) state.wallCheck = v end)
	makeSlider(arsPage, 236, "Silent FOV (px)", 20, 500, 120,
		function(v) state.silentFov = v end)
	makeSlider(arsPage, 312, "Silent Smooth", 0, 1, 0.2,
		function(v) state.silentSmooth = v end)
	makeCard(arsPage, 388, "Hitbox Expander", "resize Head + torso locally",
		function() return state.hitbox end, function(v) state.hitbox = v end)
	makeSlider(arsPage, 468, "Hitbox Scale", 1.5, 6, 2.5,
		function(v) state.hitboxScale = v end)

	-- register tabs and default to Home
	makeTab("Home", 1, "Home")
	makeTab("Player ESP", 2, "Player ESP")
	makeTab("Arsenal", 3, "Arsenal")
	showPage("Home")
