-- Load and set namespace
local _, core = ...
core.Duty = {}
local Duty = core.Duty

local f
local raidMembers = {}
local fAssignText = nil
local fAssignRow = {}

local dropdowns = {}
dropdowns.source = ""
dropdowns.assignment = ""
dropdowns.target = {}

local classes = {"Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"}
local icons = {"{Star}", "{Circle}", "{Diamond}", "{Triangle}", "{Moon}", "{Square}", "{Cross}", "{Skull}"}
local dropdownAssignmentList = {
	"Heal",
	"Tank",
	"Buff",
	"CC",
	"Interrupt",
	"Dispel",
	"Kite",
	"Puppeteer",
	"Power Infusion",
	"Smite",
	"Snowball"
}

-- Create the frame
function Duty:Create()
	core:Debug("Duty: Create")

	Duty:ParseRaidMembers()
	table.sort(dropdownAssignmentList, function(a,b)
		return (a < b)
	end)
	table.sort(classes, function(a,b)
		return (a < b)
	end)

	-- Create DutyFrame
	f = CreateFrame("Frame", "DutyFrame", UIParent, "UIPanelDialogTemplate")
	f.DialogBG = _G[f:GetName() .. "DialogBG"]
	f:SetSize(400, 70)
	f:SetAlpha(1)
	f.DialogBG:SetAlpha(0.8)
	f:SetPoint("CENTER", UIParent, "CENTER")
	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.title:SetPoint("CENTER", f.Title, "CENTER", 0, -7)
	f.title:SetText("Duty")

	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)

	f.world = Duty:CreateSectionFrame("TOPLEFT", f.DialogBG, "TOPLEFT", 0, 0, 400, 70)

	-- Dropdown menu
	f.sectionAssigns = Duty:CreateSectionFrame("TOPLEFT", f.world, "TOPLEFT", 5, -5, 380, 30)

	f.sectionAssigns.dropDownSource = Duty:CreateDropDown("TOPLEFT", f.sectionAssigns, "TOPLEFT", -15, 0, "DutyDropDownSource", 80, "Source", DutyDropDownInitSource)
	f.sectionAssigns.dropDownSource.SetValue = function(self, newValue)
		dropdowns.source = tostring(newValue)
		
		UIDropDownMenu_SetText(f.sectionAssigns.dropDownSource, newValue)

		-- Because this is called from a sub-menu, only that menu level is closed by default.
		-- Close the entire menu with this next call
		CloseDropDownMenus()
	end

	f.sectionAssigns.dropDownTarget = Duty:CreateDropDown("TOPLEFT", f.sectionAssigns.dropDownSource, "TOPRIGHT", -30, 0, "DutyDropDownTarget", 80, "Target", DutyDropDownInitTarget)
	f.sectionAssigns.dropDownTarget.SetValue = function(self, newValue)
		core:Debug("dropDownTarget: SetValue: " .. newValue)
		if not table.removeItem(dropdowns.target, tostring(newValue)) then
			dropdowns.target[#dropdowns.target+1] = tostring(newValue)
		end

		local str = ""
		for i=1,#dropdowns.target do
			if i == 1 then
				str = dropdowns.target[i]
			else
				str = str .. ", " .. dropdowns.target[i]
			end
		end
		UIDropDownMenu_SetText(f.sectionAssigns.dropDownTarget, str)
	end

	f.sectionAssigns.dropDownAssignment = Duty:CreateDropDown("TOPLEFT", f.sectionAssigns.dropDownTarget, "TOPRIGHT", -30, 0, "DutyDropDownTarget", 90, "Assignment", DutyDropDownInitAssignment)
	f.sectionAssigns.dropDownAssignment.SetValue = function(self, newValue)
		dropdowns.assignment = tostring(newValue)

		UIDropDownMenu_SetText(f.sectionAssigns.dropDownAssignment, newValue)
	end

	f.sectionAssigns.btnAdd = Duty:CreateButton("TOPLEFT", f.sectionAssigns.dropDownAssignment, "TOPRIGHT", -2, "+", 50, 0, function()
		core:Debug("add to assign list")
		if (dropdowns.source == "" or dropdowns.target == "") then
			core:Debug("SOURCE or TARGET may not be empty.")
			return
		end

		core.data.assignList[#core.data.assignList+1] = {
			["source"] = dropdowns.source,
			["assignment"] = dropdowns.assignment,
			["target"] = dropdowns.target
		}
		table.sort(core.data.assignList, function(a,b)
			return a.assignment < b.assignment
		end)
		Duty:ResetDropdowns()
		Duty:UpdateAssignsList()
	end)

	-- Show assigns
	f.sectionAssignsList = Duty:CreateSectionFrame("TOPLEFT", f.sectionAssigns.dropDownSource, "BOTTOMLEFT", 20, 0, 380, 100)
	fAssignText = core.Config:CreateText("TOPLEFT", f.sectionAssignsList, "TOPLEFT", 0, "", 12)
	fAssignText:SetJustifyH("LEFT")
	fAssignText:SetPoint("TOPLEFT",  f.sectionAssignsList, "TOPLEFT", 15, 0)

	-- Section buttons
	f.sectionButtons = Duty:CreateSectionFrame("TOPLEFT", f.world, "BOTTOMLEFT", 0, 30, 390, 30)
	f.sectionButtons.btnWhisper = Duty:CreateButton("TOPLEFT", f.sectionButtons, "TOPLEFT", 0, "Whisper", 100, 0, function()
		Duty:ParseRaidMembers() -- make sure the whisper is not abused

		for i=1,#core.data.assignList do
			local v = core.data.assignList[i]

			-- get all targets
			local t = ""
			for i, v in ipairs(v.target) do
				if i == 1 then
					t = v
				else
					t = t .. " " .. v
				end
			end

			if Duty:IsMemberInRaid(v.source) then
				local msg = "<DUTY>:"
				--if not v.assignment == "" then
					msg = msg .. v.assignment .. ":"
				--end
				msg = msg .. t
				SendChatMessage(msg, "WHISPER", nil, v.source)
			end
		end
	end)
	f.sectionButtons.btnSay = Duty:CreateButton("TOPLEFT", f.sectionButtons.btnWhisper, "TOPRIGHT", 0, "Announce", 100, 0, function()
		table.sort(core.data.assignList, function(a,b)
			return a.source < b.source
		end)

		for i=1,#core.data.assignList do
			local atext = ""
			local v = core.data.assignList[i]
			atext = atext .. v.source .. " : " .. v.assignment .. " :"
			for j=1,#v.target do
				atext = atext .. " " .. v.target[j]
			end
			atext = atext .. "\n"
			SendChatMessage(atext, "SAY", nil)
		end

		if #core.data.assignList > 0 then
			SendChatMessage("Duties announced!", "SAY", nil)
		end

		table.sort(core.data.assignList, function(a,b)
			return a.assignment < b.assignment
		end)
	end)
	f.sectionButtons.btnClear = Duty:CreateButton("TOPRIGHT", f.sectionButtons, "TOPRIGHT", 0, "Clear", 70, 0,  function()
		core.data.assignList = {}
		Duty:UpdateAssignsList()
	end)

	Duty:UpdateAssignsList()

	f:Hide()
end

-- Toggle
function Duty:Toggle()
	core:Debug("Duty: Toggle")
	f:SetShown(not f:IsShown())
	Duty:ParseRaidMembers()
end

-- Set size
function Duty:SetSize(w, h)
	core:Debug("Duty: SetSize: ", w, h)
	if w == nil or w == "" then
		w = 400
	end
	if h == nil or h == "" then
		h = 200
	end

	f:SetSize(w, h)
	f.world:SetSize(w, h)
end

-- Set opacity
function Duty:SetOpacity()
	core:Debug("Duty: SetOpacity: ", core.options.dutyOpacity)
	f.DialogBG:SetAlpha(core.options.dutyOpacity)
end

function Duty:UpdateAssignsList()
	core:Debug("UpdateAssignsList")
	Duty:ClearAssignRows()
	local total = #core.data.assignList

	for i=1,total do
		local v = core.data.assignList[i]
		Duty:AssignRow(i, v)
	end

	if total == 0 then
		Duty:SetSize(400, 70) -- original
	end
end

-- Parse raid members
function Duty:ParseRaidMembers()
	raidMembers = {}

	-- Add only yourself if not in raid
	if not IsInRaid() then
		raidMembers = {}
		raidMembers[#raidMembers+1] = {
			["name"] = GetUnitName("player"),
			["class"] = UnitClass("player"),
			["role"] = ""
		}
		return
	end

	-- Populate member list from active raid
	for i=1,40 do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		if name == nil then
			break
		end

		core:Debug(name)
		
		raidMembers[#raidMembers+1] = {
			["name"] = name,
			["class"] = class,
			["role"] = role
		}
	end

	table.sort(raidMembers, function(a,b)
		return (a.name < b.name)
	end)
end

function Duty:IsMemberInRaid(name)
	if name == GetUnitName("player") then
		return true
	end

	if not IsInRaid() then
		return false
	end

	for i=1,#raidMembers do
		if raidMembers[i].name == name then
			core:Debug(name)
			return true
		end
	end

	return false
end

-- Table functions
function table.contains(tbl, el)
	for _, v in ipairs(tbl) do
		if v == el then
			return true
		end
	end
	return false
end

function table.removeItem(tbl, el)
	for i, v in ipairs(tbl) do
		if v == el then
			table.remove(tbl, i)
			return true
		end
	end
	return false
end

-- Clears the vars and title text for the dropdowns
function Duty:ResetDropdowns()
	dropdowns.source = ""
	dropdowns.assignment = ""
	dropdowns.target = {}
	UIDropDownMenu_SetText(f.sectionAssigns.dropDownSource, "Source")
	UIDropDownMenu_SetText(f.sectionAssigns.dropDownTarget, "Target")
	UIDropDownMenu_SetText(f.sectionAssigns.dropDownAssignment, "Assignment")
end

-- Create an assignment row
function Duty:AssignRow(index, item)
	local row

	local atext = ""
	atext = atext .. item.assignment .. " : " .. item.source .. " :"
	local a = ""
	for i=1,#item.target do
		--atext = atext .. " " .. item.target[i]

		a = item.target[i]
		for j=1,#icons do
			if item.target[i] == icons[j] then
				a = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. j .. ":12:12:0:0|t"
			end
		end
		atext = atext .. " " .. a
	end

	if fAssignRow[index] == nil then
		row = Duty:CreateSectionFrame("TOPLEFT", f.sectionAssignsList, "TOPLEFT", -5, -12*index+6, 380, 12)
		row.text = core.Config:CreateText("TOPLEFT", row, "TOPLEFT", 0, atext, 12)
		row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 20, 0)
		row.text:SetJustifyH("LEFT")

		row.btnRemove = Duty:CreateButton("TOPLEFT", row, "TOPLEFT", 0, "-", 18, 12, function()
			core:Debug("AssignRow: Remove")
			table.remove(core.data.assignList, index)
			Duty:ClearAssignRows()
			Duty:UpdateAssignsList()
		end)
	else
		row = fAssignRow[index]
		row:SetPoint("TOPLEFT", f.sectionAssignsList, "TOPLEFT", -5, -12*index+6)
		row:Show()
		row.btnRemove:Show()
		row.text:SetText(atext)
	end

	-- Resize
	local w, h = row.text:GetStringWidth(), row.text:GetStringHeight()
	if w > 350 then
		Duty:SetSize(w+50, 70+h*index+20)
	else
		Duty:SetSize(400, 70+h*index+20)
	end

	fAssignRow[index] = row
end
function Duty:ClearAssignRows()
	core:Debug("ClearAssignRows")
	n1, n2 = #core.data.assignList, #fAssignRow
	if n2 > n1 then
		for i=n1+1,n2 do
			fAssignRow[i]:Hide()
			fAssignRow[i].btnRemove:Hide()
			fAssignRow[i].text:SetText("")
		end
	end
end

-- Create a section frame
function Duty:CreateSectionFrame(point, relativeFrame, relativePoint, xOffset, yOffset, width, height)
	local sf = CreateFrame("Frame", nil, f)
	sf:SetSize(width, height)
	sf:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset)
	return sf
end

-- Create a clickable button
function Duty:CreateButton(point, relativeFrame, relativePoint, yOffset, text, width, height, handlerFunc)
	local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
	btn:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
	if height == 0 then height = 22 end
	btn:SetSize(width, height)
	btn:SetText(text)
	btn:SetNormalFontObject("GameFontNormal")
	btn:SetHighlightFontObject("GameFontHighlight")
	btn:SetScript("OnClick", function(self) handlerFunc(self) end)
	return btn
end

-- Create a dropdown menu
function Duty:CreateDropDown(point, relativeFrame, relativePoint, xOffset, yOffset, frameName, width, initialText, initFunc)
	local dropDown = CreateFrame("Frame", frameName, relativeFrame, "UIDropDownMenuTemplate")
	dropDown:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset)
	UIDropDownMenu_SetWidth(dropDown, width)
	UIDropDownMenu_SetText(dropDown, initialText)

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(dropDown, initFunc)

	return dropDown
end

-- The init functions for the dropdowns (will be passed to UIDropDownMenu_Initialize)
function DutyDropDownInitSource(self, level, menuList)
		local info = UIDropDownMenu_CreateInfo() -- reuse list for better memory management

		Duty:ParseRaidMembers() -- stay up to date, even though it is inefficient

		if (level or 1) == 1 then
			-- Display the 0-9, 10-19, ... groups
			for i=1,#classes do
				info.text, info.checked = classes[i], false
				info.menuList, info.hasArrow, info.notCheckable, info.keepShownOnClick = i, true, true, true
				UIDropDownMenu_AddButton(info)
			end
		else
			for i=1,#raidMembers do
				if raidMembers[i].class == classes[menuList] then
					local name = raidMembers[i].name
					info.text, info.arg1, info.checked = name, name, name == dropdowns.source
					-- info.menuList = i
					info.func = self.SetValue
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
end
function DutyDropDownInitTarget(self, level, menuList)
		local info = UIDropDownMenu_CreateInfo() -- reuse list for better memory management

		Duty:ParseRaidMembers() -- stay up to date, even though it is inefficient

		if (level or 1) == 1 then
			for i=1,#classes do
				info.text, info.checked = classes[i], false
				info.menuList, info.hasArrow, info.notCheckable, info.keepShownOnClick = i, true, true, true
				UIDropDownMenu_AddButton(info)
			end

			info.text, info.checked = "Groups", false
			info.menuList, info.hasArrow, info.notCheckable, info.keepShownOnClick = #classes+1, true, true, true
			UIDropDownMenu_AddButton(info)

			info.text, info.checked = "Icons", false
			info.menuList, info.hasArrow, info.notCheckable, info.keepShownOnClick = #classes+2, true, true, true
			UIDropDownMenu_AddButton(info)
		else
			for i=1,#raidMembers do
				if raidMembers[i].class == classes[menuList] then
					local name = raidMembers[i].name
					info.text, info.arg1, info.keepShownOnClick, info.isNotRadio, info.checked = name, name, true, true, table.contains(dropdowns.target, name)
					info.func = self.SetValue
					UIDropDownMenu_AddButton(info, level)
				end
			end

			if menuList == 10 then
				for i=1,8 do
					info.text, info.arg1, info.keepShownOnClick, info.isNotRadio, info.checked = i, i, true, true, table.contains(dropdowns.target, tostring(i))
					info.func = self.SetValue
					UIDropDownMenu_AddButton(info, level)
				end
				info.text, info.arg1, info.keepShownOnClick, info.isNotRadio, info.checked = "Raid", "Raid", true, true, table.contains(dropdowns.target, "Raid")
				info.func = self.SetValue
				UIDropDownMenu_AddButton(info, level)
			end

			
			if menuList == 11 then
				for i=1,#icons do
					local t = icons[i]
					info.text, info.arg1, info.keepShownOnClick, info.isNotRadio, info.checked = t, t, true, true, table.contains(dropdowns.target, t)
					info.func = self.SetValue
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
end
function DutyDropDownInitAssignment(self, level, menuList)
		local info = UIDropDownMenu_CreateInfo() -- reuse list for better memory management

		info.func = self.SetValue
		for _, v in ipairs(dropdownAssignmentList) do
			info.text, info.arg1, info.isNotRadio, info.keepShownOnClick, info.checked = v, v, false, false, v == dropdowns.assignment
			UIDropDownMenu_AddButton(info, level)
		end
end
