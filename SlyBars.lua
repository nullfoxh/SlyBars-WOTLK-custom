	--[[

		SlyBars
			A combopoint and energy tracker for WoW TBC 2.4.3

			by null
			https://github.com/nullfoxh/SlyBars-WOTLK-custom

	]]--

	local energycolor = { 255/255, 225/255, 26/255 }
	local combocolor = {
		[1] = { 208/255, 120/255, 72/255 },
		[2] = { 240/255, 190/255, 89/255 },
		[3] = { 216/255, 231/255, 92/255 },
		[4] = { 139/255, 243/255, 83/255 },
		[5] = {  60/255, 255/255, 73/255 }
	}

	local font = "Interface\\AddOns\\SlyBars\\homespun.ttf"
	local texture = "Interface\\AddOns\\SlyBars\\statusbar.tga"

	---------------------------------------------------------------------------------------------

	local class = select(2, UnitClass("player"))
	local lastTick, nextTick, points, configMode = 0, 0, 0, false
	local curEnergy, maxEnergy, inCombat, smoothing
	local stealthed, haveTarget, powerType, initialized, isDead
	local GetTime, UnitIsDead, UnitIsDeadOrGhost, MAX_COMBO_POINTS, format,        min
		= GetTime, UnitIsDead, UnitIsDeadOrGhost, MAX_COMBO_POINTS, string.format, math.min
	local UnitMana, UnitManaMax, UnitPowerType, IsStealthed, GetComboPoints, UnitCanAttack
		= UnitMana, UnitManaMax, UnitPowerType, IsStealthed, GetComboPoints, UnitCanAttack
	local GetWeaponEnchantInfo = GetWeaponEnchantInfo

	local p = function(s) print("|cffa0f6aaSlyBars|r: "..s) end

	SlyBars = CreateFrame("Frame", nil, UIParent)

	---------------------------------------------------------------------------------------------

	local function CreateTex(frame, a, b, x, y, layer, tex)
		local bg = frame:CreateTexture(nil, layer or "BACKGROUND")
		bg:SetPoint("TOPLEFT", frame, a or -1, b or 1)
		bg:SetPoint("BOTTOMRIGHT", frame, x or 1, y or -1)
		bg:SetTexture(tex or "Interface\\ChatFrame\\ChatFrameBackground")
		bg:SetVertexColor(0, 0, 0)
		return bg
	end

	local function CreateFrames()

		SlyBars:SetWidth(SBC.frameWidth)
		SlyBars:SetHeight(SBC.frameHeight)
		SlyBars:SetPoint("CENTER", UIParent, "CENTER", SBC.frameX, SBC.frameY)

		-- energy
		local e = CreateFrame("Frame", nil, SlyBars)
		e:SetFrameStrata("BACKGROUND")
		e:SetWidth(SBC.frameWidth)
		e:SetHeight(SBC.energyHeight)
		e:SetPoint("BOTTOMLEFT", SlyBars, "BOTTOMLEFT")
		SlyBars.energy = e

		-- bar
		e.bar = CreateFrame("StatusBar", nil, e)
		e.bar:SetStatusBarTexture(texture)
		e.bar:SetPoint("TOPLEFT", 1, -1)
		e.bar:SetPoint("BOTTOMRIGHT", -1, 1)
		e.bar:SetMinMaxValues(0, maxEnergy)
		e.bar:SetValue(curEnergy)

		-- bg
		local r, g, b = unpack(energycolor)
		e.bar:SetStatusBarColor(r, g ,b)
		e.bg = CreateTex(e, 0, 0, 0, 0, "BACKGROUND")
		e.bd = CreateTex(e, 1, -1, -1, 1, "BORDER", texture)
		e.bd:SetVertexColor(r, g, b, 0.25)

		-- text
		e.text = e:CreateFontString(nil, "OVERLAY")
		e.text:SetFont(font, SBC.fontSize, "OUTLINE")
		e.text:SetShadowColor(0, 0, 0)
		e.text:SetShadowOffset(1, -1)
		e.text:SetPoint("TOP", e, "BOTTOM", 0, 0)
		e.text:SetJustifyH("CENTER")
		e.text:SetTextColor(r, g, b)
		e.text:SetText(curEnergy)
		if not SBC.showText then
			e.text:Hide()
		end

		-- spark
		e.spark = e.bar:CreateTexture(nil, "OVERLAY")
		e.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		e.spark:SetBlendMode("ADD")
		e.spark:SetWidth(SBC.energyHeight+4)
		e.spark:SetHeight(SBC.energyHeight+4)
		if not SBC.showSpark then
			e.spark:Hide()
		end
		
		-- combopoints
		SlyBars.cp = {}
		for i = 1, MAX_COMBO_POINTS do
			local c = CreateFrame("Frame", nil, SlyBars)
			c:SetWidth((SBC.frameWidth+MAX_COMBO_POINTS-1)/MAX_COMBO_POINTS)
			c:SetHeight(SBC.comboHeight)
			c:SetFrameStrata("BACKGROUND")

			c.bg = CreateTex(c, 0, 0, 0, 0, "BACKGROUND")
			c.bd = CreateTex(c, 1, -1, -1, 1, "ARTWORK", texture)
			c.fg = CreateTex(c, 1, -1, -1, 1, "ARTWORK", texture)
			c.fg:Hide()
	 
			local r, g, b = unpack(combocolor[i])
			c.fg:SetVertexColor(r, g, b)
			c.bd:SetVertexColor(r, g, b, 0.25)

			SlyBars.cp[i] = c

			if i > 1 then
				c:SetPoint("TOPLEFT", SlyBars.cp[i-1], "TOPRIGHT", -1, 0)
			else
				c:SetPoint("BOTTOMLEFT", SlyBars.energy, "TOPLEFT", 0, -1)
			end
		end
	end

	---------------------------------------------------------------------------------------------

	local function UpdateFrames()
		curEnergy = UnitMana("player")
		maxEnergy = UnitManaMax("player")
		powerType = UnitPowerType("player")
		SlyBars.energy.bar:SetMinMaxValues(0, maxEnergy)
		SlyBars.energy.bar:SetValue(curEnergy)
		if SBC.showText then
			SlyBars.energy.text:SetText(curEnergy)
		end
	end

	local function StartFrameFade(frame, show)
		if show and frame.hidden then
			UIFrameFadeIn(frame, SBC.fadeInTime, 0, 1)
			frame.hidden = false
		elseif not show and not frame.hidden then
			UIFrameFadeOut(frame, SBC.fadeOutTime, 1, 0)
			frame.hidden = true
		end
	end

	local function UpdateEnergy()
		local newEnergy = UnitMana("player")

		if SBC.smoothBars then
			if smoothing then
				SlyBars.energy.bar:SetValue(curEnergy)
			else
				smoothing = true
			end
			SlyBars.energy.bar.start = curEnergy
			SlyBars.energy.bar.target = newEnergy
			SlyBars.energy.bar.startTime = GetTime()
		else
			SlyBars.energy.bar:SetValue(newEnergy)
		end

		if SBC.showText then
			SlyBars.energy.text:SetText(newEnergy)
		end

		if SBC.showSpark then
			if newEnergy == curEnergy + 20 then
				local time = GetTime()
				lastTick = time
				nextTick = time + 2
			end
		end
		curEnergy = newEnergy
	end

	local function UpdateCombo()
		points = GetComboPoints("player", "target")
		for i = 1, MAX_COMBO_POINTS do
			if i > points then
				SlyBars.cp[i].fg:Hide()
			else
				SlyBars.cp[i].fg:Show()
			end
		end
	end

	local function CheckPoisons()
		if UnitLevel("player") < 20 or not SBC.poisonReminder then
			return
		end

		local msg
		local mh, _, _, _, offh = GetWeaponEnchantInfo()

		if not mh and not offh then
			msg = "Missing both poisons!"
		elseif not mh and not SBC.ignoreMhPoison then
			msg = "Missing main hand poison!"
		elseif not offh then
			msg = "Missing off-hand poison!"
		end

		if msg then
			ZoneTextString:SetText(msg)
			ZoneTextFrame.startTime = GetTime()
			ZoneTextFrame.fadeInTime = 0
			ZoneTextFrame.holdTime = 3
			ZoneTextFrame.fadeOutTime = 1
			ZoneTextString:SetTextColor(1, 0, 0)
			PVPInfoTextString:SetText("")
			ZoneTextFrame:Show()
		end
	end

	local function ShouldShowFrame()
		if isDead then
			return false
		end

		if points > 0 or curEnergy ~= maxEnergy then
			return true
		end

		if stealthed or inCombat then
			return true
		end

		if haveTarget then
			return true
		end

		return false
	end

	local function UpdateTarget()
		haveTarget = UnitCanAttack("player", "target") and not UnitIsDead("target")
	end

	---------------------------------------------------------------------------------------------

	local function OnEvent(self, event, unit)

		if event == "ADDON_LOADED" then
			if unit == "SlyBars" then
				self:InitAddon()
			else
				return
			end
		elseif not initialized then
			UpdateFrames()
			initialized = true
		end

		if event == "UNIT_COMBO_POINTS" then
			UpdateCombo()

		elseif event == "UNIT_ENERGY" then
			UpdateEnergy()

		elseif event == "PLAYER_TARGET_CHANGED" then
			UpdateTarget()
			UpdateCombo()

		elseif event == "PLAYER_REGEN_DISABLED" then
			CheckPoisons()
			inCombat = true

		elseif event == "PLAYER_REGEN_ENABLED" then
			inCombat = false
			UpdateTarget()

		elseif event == "UNIT_INVENTORY_CHANGED" then
			if inCombat then
				CheckPoisons()
			end
			return

		elseif event == "UNIT_MAXENERGY" then
			UpdateFrames()

		elseif event == "UPDATE_STEALTH" then
			stealthed = IsStealthed()

		elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or "PLAYER_UNGHOST" then
			isDead = UnitIsDeadOrGhost("player")

		elseif event == "UNIT_DISPLAYPOWER" and unit == "player" then
			powerType = UnitPowerType("player")
			if powerType == 3 then
				UpdateFrames()
			end

		elseif event == "PLAYER_LOGIN" then
			UpdateFrames()
			stealthed = IsStealthed()
		end

		-- show/hide
		if class == "DRUID" and powerType ~= 3 then
			StartFrameFade(SlyBars, false)
		elseif SBC.fadeFrame then
			if ShouldShowFrame() then
				StartFrameFade(SlyBars, true)
			else
				StartFrameFade(SlyBars, false)
			end
		else
			StartFrameFade(SlyBars, true)
		end
	end

	local function OnUpdate(self, elapsed)
		if SBC.showSpark then
			local time = GetTime()

			if nextTick == 0 then
				lastTick = time
				nextTick = time + 2
			elseif time > nextTick then
				lastTick = nextTick
				nextTick = nextTick + 2
			end

			if not SlyBars.hidden then
				local pct = (time - lastTick) * 0.5
				SlyBars.energy.spark:SetPoint("CENTER", SlyBars.energy.bar, "LEFT", pct * SBC.frameWidth, 0)
			end
		end

		if smoothing then
			local cur = SlyBars.energy.bar:GetValue()
			local start = SlyBars.energy.bar.start
			local target = SlyBars.energy.bar.target

			local pct = min(1, (GetTime() - SlyBars.energy.bar.startTime) / SBC.smoothTime)
			local new = start + (target - start) * pct

			if new ~= cur then
				SlyBars.energy.bar:SetValue(new)
			end

			if pct == 1 then
				smoothing = false
			end
		end
	end

	---------------------------------------------------------------------------------------------

	function SlyBars:InitAddon()
		SlyBars:UnregisterEvent("ADDON_LOADED")

		if not SBC then
			SBC = SlyBars.GetDefaultConfig()
		end

		stealthed = IsStealthed()
		curEnergy = UnitMana("player")
		maxEnergy = UnitManaMax("player")
		powerType = UnitPowerType("player")

		CreateFrames()

		if class == "DRUID" or SBC.fadeFrame then
			SlyBars:SetAlpha(0)
			SlyBars.hidden = true
		end

		SlyBars:RegisterEvent("UNIT_ENERGY")
		SlyBars:RegisterEvent("UNIT_MAXENERGY")
		SlyBars:RegisterEvent("UNIT_COMBO_POINTS")
		SlyBars:RegisterEvent("PLAYER_TARGET_CHANGED")
		SlyBars:RegisterEvent("PLAYER_LOGIN")

		if SBC.fadeFrame then
			SlyBars:EnableFading()
		end

		if class == "ROGUE" and SBC.poisonReminder then
			SlyBars:RegisterEvent("UNIT_INVENTORY_CHANGED")
		end

		if class == "DRUID" then
			SlyBars:RegisterEvent("UNIT_DISPLAYPOWER")
		end

		if SBC.showSpark or SBC.smoothBars then
			SlyBars:SetScript("OnUpdate", OnUpdate)
		end

		if SBC.showMsg then
			p("Loaded. Get updates from https://github.com/nullfoxh/SlyBars")
		end
	end

	do
		if class == "ROGUE" or class == "DRUID" then
			SlyBars:SetScript("OnEvent", OnEvent)
			SlyBars:RegisterEvent("ADDON_LOADED")
		end
	end

	---------------------------------------------------------------------------------------------

	function SlyBars.GetDefaultConfig()
		return {
			frameX = 0,
			frameY = -275,
			frameWidth = 125,
			frameHeight = 7,
			comboHeight = 7,
			energyHeight = 7,
			frameX = 0,
			frameY = -275,
			showSpark = true,
			smoothBars = true,
			smoothTime = 0.1,
			showMsg = true,
			showText = true,
			fontSize = 20,
			fadeFrame = true,
			fadeInTime = 0.07,
			fadeOutTime = 0.15,
			poisonReminder = true,
			ignoreMhPoison = false
		}
	end

	local function ToggleConfigMode(enable)
		if enable or not configMode then

			StartFrameFade(SlyBars, true)
		
			SlyBars:SetMovable(true)
			SlyBars:EnableMouse(true)
			SlyBars:EnableMouseWheel(true)

			SlyBars:SetScript("OnMouseDown", function(self, button)
				if button == "LeftButton" and not self.isMoving then
					self.isMoving = true
					self:StartMoving()
				end
			end)

			SlyBars:SetScript("OnMouseUp", function(self, button)
				if button == "LeftButton" and self.isMoving then
					self.isMoving = false
					self:StopMovingOrSizing()
					self:SaveFramePosition()
				end
			end)
			
			SlyBars:SetScript("OnMouseWheel", function(self, dir)
				if IsShiftKeyDown() then
					if dir == 1 then
						self:MoveFrameBy(1, 0)
					else
						self:MoveFrameBy(-1, 0)
					end
				elseif IsAltKeyDown() and IsControlKeyDown() then
					self:SetComboHeight(SBC.comboHeight+dir)
				elseif IsControlKeyDown() then
					self:SetFrameWidth(SBC.frameWidth+dir)
				elseif IsAltKeyDown() then
					self:SetEnergyHeight(SBC.energyHeight+dir)
				else
					if dir == 1 then
						self:MoveFrameBy(0, 1)
					else
						self:MoveFrameBy(0, -1)
					end
				end
			end)

			configMode = true
			p("config mode enabled.")
			p("You can now mouse-over the frame and use the mousescroll to move or resize the frame.")
			p("Mousescroll up/down for horizontal position. Hold shift for vertical position.")
			p("Hold control to change the frame's width. Hold alt to change energy bar's height.")
			p("Hold control and alt to change combopoint frame's height.")
		else
			SlyBars:SetMovable(false)
			SlyBars:EnableMouse(false)
			SlyBars:EnableMouseWheel(false)
			SlyBars:SetScript("OnMouseUp", nil)
			SlyBars:SetScript("OnMouseDown", nil)
			SlyBars:SetScript("OnMouseWheel", nil)
			configMode = false
			p("config mode disabled.")

			if SBC.fadeFrame then
				if ShouldShowFrame() then
					StartFrameFade(SlyBars, true)
				else
					StartFrameFade(SlyBars, false)
				end
			end
		end
	end

	-- Save position after mouse drag finished
	function SlyBars:SaveFramePosition()
		local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
		SBC.frameX = xOfs
		SBC.frameY = yOfs
	end

	function SlyBars:SetFramePos(x, y)
		local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
		if not x then x = xOfs end
		if not y then y = yOfs end
		self:ClearAllPoints()
		self:SetPoint(point, relativeTo, relativePoint, x, y)
		self:SaveFramePosition()
	end

	function SlyBars:MoveFrameBy(x, y)
		self:SetFramePos(SBC.frameX + x, SBC.frameY + y)
	end

	function SlyBars:SetFrameWidth(width)
		self:SetWidth(width)
		self.energy:SetWidth(width)
		for i = 1, MAX_COMBO_POINTS do
			self.cp[i]:SetWidth((width+MAX_COMBO_POINTS-1)/MAX_COMBO_POINTS)
		end
		SBC.frameWidth = width
	end

	function SlyBars:UpdateFrameHeight()
		SBC.frameHeight = SBC.energyHeight + SBC.comboHeight + 3
		self:SetHeight(SBC.frameHeight)
	end

	function SlyBars:SetComboHeight(height)
		for i = 1, MAX_COMBO_POINTS do
			self.cp[i]:SetHeight(height)
		end
		SBC.comboHeight = height
		self:UpdateFrameHeight()
	end

	function SlyBars:SetEnergyHeight(height)
		self.energy:SetHeight(height)
		SBC.energyHeight = height
		self:UpdateFrameHeight()
	end

	function SlyBars:EnableFading()
		self:RegisterEvent("PLAYER_DEAD")
		self:RegisterEvent("PLAYER_ALIVE")
		self:RegisterEvent("PLAYER_UNGHOST")
		self:RegisterEvent("UPDATE_STEALTH")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	end

	function SlyBars:DisableFading()
		self:UnregisterEvent("PLAYER_DEAD")
		self:UnregisterEvent("PLAYER_ALIVE")
		self:UnregisterEvent("PLAYER_UNGHOST")
		self:UnregisterEvent("UPDATE_STEALTH")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	end

	---------------------------------------------------------------------------------------------

	SLASH_SLYBARS1 = "/sb"
	SLASH_SLYBARS2 = "/slybars"
	SlashCmdList.SLYBARS = function(args)
		local cmd, val = strsplit(" ", args:lower(), 2)

		if cmd == "c" or cmd == "config" or cmd == "lock" or cmd == "unlock" then
			ToggleConfigMode()

		elseif cmd == "reset" then
			-- i'm lazy ok
			SBC = SlyBars.GetDefaultConfig()
			ReloadUI()

		elseif cmd == "x" or cmd == "xpos" then
			if val then
				SlyBars:SetFramePos(tonumber(val), nil)
				p("Frame x-position set to: "..val)
			else
				p(format("Frame x-position is currently set to %d. To change use: /sb x <number>", SBC.frameX))
			end
		
		elseif cmd == "y" or cmd == "ypos" then
			if val then
				SlyBars:SetFramePos(nil, tonumber(val))
				p("Frame y-position set to: "..val)
			else
				p(format("Frame y-position is currently set to %d. To change use: /sb y <number>", SBC.frameY))
			end

		elseif cmd == "w" or cmd == "width" then
			if val then
				SlyBars:SetFrameWidth(tonumber(val))
				p("Frame width set to: "..val)
			else
				p(format("Frame width is currently set to %d. To change use: /sb width <number>", SBC.frameWidth))
			end

		elseif cmd == "ch" or cmd == "comboheight" then
			if val then
				SlyBars:SetFrameHeight(tonumber(val))
				p("Combopoint height set to: "..val)
			else
				p(format("Combopoint height is currently set to %d. To change use: /sb comboheight <number>", SBC.comboHeight))
			end

		elseif cmd == "eh" or cmd == "energyheight" then
			if val then
				SlyBars:SetEnergyHeight(tonumber(val))
				p("Energy height set to: "..val)
			else
				p(format("Energy height is currently set to %d. To change use: /sb energyheight <number>", SBC.energyHeight))
			end

		elseif  cmd == "t" or cmd == "text" then
			if not SBC.showText then
				SlyBars.energy.text:SetText(curEnergy)
				SlyBars.energy.text:Show()
				SBC.showText = true
				p("Energy text is now shown.")
			else
				SlyBars.energy.text:Hide()
				SBC.showText = false
				p("Energy text is now hidden.")
			end

		elseif cmd == "fontsize" then
			if val then
				SlyBars.energy.text:SetFont(font, val, "OUTLINE")
				SBC.fontSize = val
				p("Font size set to: "..val)
			else
				p(format("Font size is currently set to %d. To change use: /sb fontsize <number>", SBC.fontSize))
			end

		elseif cmd == "tick" or cmd == "spark" then
			if not SBC.showSpark then
				SBC.showSpark = true
				if not SlyBars:GetScript("OnUpdate") then
					SlyBars:SetScript("OnUpdate", OnUpdate)
				end
				SlyBars.energy.spark:Show()
				p("Energy tick is now shown.")
			else
				SBC.showSpark = false
				SlyBars.energy.spark:Hide()
				p("Energy tick is now hidden.")
			end

		elseif cmd == "smooth" or cmd == "smoothing" then
			if not SBC.smoothBars then
				SBC.smoothBars = true
				if not SlyBars:GetScript("OnUpdate") then
					SlyBars:SetScript("OnUpdate", OnUpdate)
				end
				p("Bar smoothing enabled.")
			else
				SBC.smoothBars = false
				p("Bar smoothing disabled.")
			end

		elseif cmd == "f" or cmd == "fade" then
			if not SBC.fadeFrame then
				self:EnableFading()
				SBC.fadeFrame = true
				print("Fading enabled.")
			else
				self:DisableFading()
				StartFrameFade(SlyBars, true)
				SBC.fadeFrame = false
				print("Fading disabled.")
			end

		elseif cmd == "fadein" then
			if val then
				SBC.fadeInTime = val
				p("Fade out time set to: "..val)
			else
				p(format("Fade in time is currently set to %d. To change use: /sb fadein <number>", SBC.fadeInTime))
			end

		elseif cmd == "fadeout" then
			if val then
				SBC.fadeOutTime = val
				p("Fade in time set to: "..val)
			else
				p(format("Fade out time is currently set to %d. To change use: /sb fadeout <number>", SBC.fadeOutTime))
			end

		elseif cmd == "reminder" or  cmd == "poison" then
			if not SBC.poisonReminder then
				SlyBars:RegisterEvent("UNIT_INVENTORY_CHANGED")
				SBC.poisonReminder = true
				print("Poison reminder enabled.")
			else
				SlyBars:UnregisterEvent("UNIT_INVENTORY_CHANGED")
				SBC.poisonReminder = false
				print("Poison reminder disabled.")
			end
		
		elseif cmd == "ignoremh" then
			if not SBC.ignoreMhPoison then
				SBC.ignoreMhPoison = true
				print("Main-Hand Poison reminder disabled.")
			else
				SBC.ignoreMhPoison = false
				print("Main-Hand Poison reminder enabled.")
			end

		elseif cmd == "commands" or  cmd == "help" then
			p("The available commands are:")
			local args = {
						"config", "xpos", "ypos", "width", "comboheight",
						"energyheight", "text", "fontsize", "spark", "smooth",
						"fade", "fadein", "fadeout", "reminder", "ignoremh"
					}

			for i, v in ipairs(args) do
				p("  "..v)
			end
		else
			p("Type /sb help for the available commands.")
		end
	end