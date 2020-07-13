-- Load and set namespace
local addonName, core = ...
core.Config = {}
local Config = core.Config

local f

-- Create the config frame
function Config:Create()
	core:Debug("Config: Create")

	-- Create ConfigFrame
	f = CreateFrame("Frame", "DutyConfigFrame", UIParent)

	-- Add to Blizzard Interface Options
	f.name = "Duty"
	InterfaceOptions_AddCategory(f)

	-- Title
	f.sectionHeader = Config:CreateSectionFrame("TOPLEFT", f, "TOPLEFT", 17, -16, 100, 30)
	f.headerTitle = Config:CreateHeaderText("TOPLEFT", f.sectionHeader, "TOPLEFT", 0, "Duty", 30)
	f.headerTitle:SetFont("Fonts/MORPHEUS.ttf", 30) -- override with Diablo font

	-- Section system
	f.sectionSystem = Config:CreateSectionFrame("TOPLEFT", f.sectionHeader, "BOTTOMLEFT", 0, -20, 285, 150)
	f.sectionSystem.header = Config:CreateHeaderText("TOPLEFT", f.sectionSystem, "TOPLEFT", 0, "System", 16)
	f.sectionSystem.checkbtnDebug = Config:CreateCheckButton("TOPLEFT", f.sectionSystem.header, "BOTTOMLEFT", -5, "ChkBtnDebug", "Console debug", "Enable to print a lot of internal console debug messages.", core.options.debug, function(self)
		core:ToggleDebug()
	end)
	f.sectionSystem.btnDefaults = Config:CreateButton("TOPLEFT", f.sectionSystem.checkbtnDebug, "BOTTOMLEFT", -10, "Reset to defaults", function()
		core:RestoreDefaults()
	end)

	-- Section gui
	f.sectionGUI = Config:CreateSectionFrame("TOPLEFT", f.sectionSystem, "TOPRIGHT", 20, 0, 285, 150)
	f.sectionGUI.header = Config:CreateHeaderText("TOPLEFT", f.sectionGUI, "TOPLEFT", 0, "Panel", 16)
	f.sectionGUI.btnGUI = Config:CreateButton("TOPLEFT", f.sectionGUI.header, "BOTTOMLEFT", -10, "Toggle", function()
		core.Duty:Toggle()
	end)
	f.sectionGUI.sliderOpacity = Config:CreateSlider("TOPLEFT", f.sectionGUI.btnGUI, "BOTTOMLEFT", -20, "SliderScale", "Opacity", "Adjust to set the opacity of the Duty panel.", "Transparent", "Opaque", 0, 10, core.options.dutyOpacity*10, 1, function(self, value)
		local s = math.ceil(value*100)/1000
		core.options.dutyOpacity = s
		core.Duty:SetOpacity()
		core.DutySlave:SetOpacity()
	end)
	f.sectionGUI.sliderOpacity:SetPoint("TOPLEFT", f.sectionGUI.btnGUI, "BOTTOMLEFT", 10, -20)
	f.sectionGUI.sliderOpacity:SetEnabled(true)
end

-- Create a section frame
function Config:CreateSectionFrame(point, relativeFrame, relativePoint, xOffset, yOffset, width, height)
	local sf = CreateFrame("Frame", nil, f)
	sf:SetSize(width, height)
	sf:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset)
	return sf
end

-- Create a header text
function Config:CreateHeaderText(point, relativeFrame, relativePoint, yOffset, text, size)
    local t = relativeFrame:CreateFontString(nil, "ARTWORK")
	t:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
    -- t:SetFont("Fonts/MORPHEUS.ttf", size)
	t:SetFont("Fonts/FRIZQT__.ttf", size)
    t:SetJustifyV("CENTER")
    t:SetJustifyH("CENTER")
    t:SetText(text)
	t:SetTextColor(1, 0.9, 0, 1)
    return t
end

-- Create text
function Config:CreateText(point, relativeFrame, relativePoint, yOffset, text, size)
    local t = relativeFrame:CreateFontString(nil, "ARTWORK")
	t:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
    -- t:SetFont("Fonts/MORPHEUS.ttf", size)
	t:SetFont("Fonts/FRIZQT__.ttf", size)
    t:SetJustifyV("CENTER")
    t:SetJustifyH("CENTER")
    t:SetText(text)
    return t
end

-- Create a check button with title and tooltip
function Config:CreateCheckButton(point, relativeFrame, relativePoint, yOffset, name, text, tooltip, checked, handlerFunc)
	local btn = CreateFrame("CheckButton", "DutyConfig" .. name, f, "ChatConfigCheckButtonTemplate")
	btn.text = _G[btn:GetName().."Text"]
	btn.text:SetText(text)
	btn.text:SetPoint("LEFT", btn, "RIGHT", 4, 0)
	btn.tooltip = tooltip
	btn:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
	btn:SetScale(1.1)
	btn:SetChecked(checked)
	btn:SetScript("OnClick", function(self) handlerFunc(self) end)
	return btn
end

-- Create a clickable button
function Config:CreateButton(point, relativeFrame, relativePoint, yOffset, text, handlerFunc)
	local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
	btn:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
	btn:SetSize(145, 22)
	btn:SetText(text)
	btn.tooltip = "Hejhej"
	btn:SetNormalFontObject("GameFontNormal")
	btn:SetHighlightFontObject("GameFontHighlight")
	btn:SetScript("OnClick", function(self) handlerFunc(self) end)
	return btn
end

-- Create a slider with title
function Config:CreateSlider(point, relativeFrame, relativePoint, yOffset, gname, title, tooltip, lowText, highText, minVal, maxVal, initVal, stepVal, handlerFunc)
	local slider = CreateFrame("Slider", addonName .. gname, f, "OptionsSliderTemplate")
	slider:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValue(initVal)
	slider:SetValueStep(stepVal)
	slider:SetObeyStepOnDrag(true)
	slider.tooltipText = tooltip
	slider.lowText = _G[slider:GetName().."Low"]
	slider.lowText:SetText(lowText)
	slider.highText = _G[slider:GetName().."High"]
	slider.highText:SetText(highText)
	slider.text = _G[slider:GetName().."Text"]
	slider.text:SetText(title)
	slider:SetScript("OnValueChanged", function(self, value)
		handlerFunc(self, value)
	end)
	return slider
end

-- Create an input text editing box
function Config:CreateInputBox(point, relativeFrame, relativePoint, yOffset, title, w, initVal, handleFunc)
	local e = CreateFrame("EditBox", nil, f)
	e:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
	e.title_text = Config:CreateText("TOP", e, "TOP", 12, title, 12)
	e:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 26,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4}
	})
	e:SetBackdropColor(0.1,0.1,0.1,1)
	e:SetFontObject(GameFontNormal)
	e:SetJustifyH("CENTER")
	e:SetJustifyV("CENTER")
	e:SetSize(w, 25)
	e:SetMultiLine(false)
	e:SetAutoFocus(false)
	e:SetMaxLetters(3)
	e:SetText(initVal)
	e:SetCursorPosition(0)

	e:SetScript("OnEnterPressed", function(self)
		handleFunc(self)
		self:ClearFocus()
	end)
	e:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	return e
end
