-- Load and set namespace
local _, core = ...
core.DutySlave = {}
local DutySlave = core.DutySlave

local f
local raidMembers = {}

local fsAssignRow = nil

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
	"Snowball"
}

-- Create "client" side of the addon
function DutySlave:Create()
	-- Create DutyFrame
	f = CreateFrame("Frame", "DutySlaveFrame", UIParent, nil)
	f:SetSize(200, 35)
	f:SetAlpha(1)
	f:SetPoint("CENTER", UIParent, "CENTER")

	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 26,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4}
	})
	f:SetBackdropColor(0.1,0.1,0.1,1)

	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)

	f.world = core.Duty:CreateSectionFrame("TOPLEFT", f, "TOPLEFT", 0, 0, 200, 35)
	f.sectionAssigns = core.Duty:CreateSectionFrame("TOPLEFT", f.world, "TOPLEFT", 10, -10, 180, 15)

	DutySlave:Set("", "")
	f:Hide()
end

-- Toggle
function DutySlave:Toggle()
	core:Debug("DutySlave: Toggle")
	fs:SetShown(not fs:IsShown())
end

-- Set opacity
function DutySlave:SetOpacity()
	core:Debug("DutySlave: SetOpacity: ", core.options.dutyOpacity)
	f:SetAlpha(core.options.dutyOpacity)
end

-- Set size
function DutySlave:SetSize(w, h)
	core:Debug("DutySlave: SetSize: ", w, h)
	if w == nil or w == "" then
		w = 200
	end
	if h == nil or h == "" then
		h = 35
	end

	f:SetSize(w, h)
	f.world:SetSize(w, h)
end

-- Set data for the slave/client
function DutySlave:Set(assignment, targets)
	DutySlave:AssignRow(assignment, targets)
	f:Show()
end

-- Create an assignment row
function DutySlave:AssignRow(assignment, targets)
	local row

	local atext = ""
	if assignment ~= "" then
		atext = atext .. assignment .. ": "
	end
	local a = ""
	local ts = strsplit2table(targets, " ")
	for i=1,#ts do
		a = ts[i]
		for j=1,#icons do
			if ts[i] == icons[j] then
				a = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. j .. ":12:12:0:0|t"
			end
		end
		atext = atext .. a .. " "
	end

	if fsAssignRow == nil then
		core:Debug("SlaveAssignRow: Creating fsAssignRow frame")
		row = core.Duty:CreateSectionFrame("TOPLEFT", f.sectionAssigns, "TOPLEFT", 0, 0, 180, 80)
		row.text = core.Config:CreateText("TOPLEFT", row, "TOPLEFT", 0, atext, 14)
		row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
		row.text:SetJustifyH("LEFT")
	else
		core:Debug("SlaveAssignRow: Reusing fsAssignRow frame")
		row = fsAssignRow
		row:SetPoint("TOPLEFT", f.sectionAssigns, "TOPLEFT", 0, 0)
		row:Show()
		row.text:SetText(atext)
	end
	
	--row.text:SetText("|A:groupfinder-icon-role-large-tank:16:16:0:0|a Tank")
	--row.text:SetText("|A:alliance_icon_and_flag-icon:16:16:0:0|a Tank")

	-- Resize
	local w, h = row.text:GetStringWidth(), row.text:GetStringHeight()
	DutySlave:SetSize(w+20, h+20)

	fsAssignRow = row
end

function strsplit2table(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end