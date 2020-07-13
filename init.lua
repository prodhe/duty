-- Load and set namespace
local _, core = ...

-- Handler for console slash commands
function core:Console(arg)
	-- Print help
	if arg == "help" then
		s = [[

Console commands:

/duty - Open GUI (Key Bindings > Other > Duty)
/duty options - Show interface options
/duty defaults - Reset Duty to default settings]]
		core:Print(s)

	-- Open settings
	elseif arg == "options" then
		InterfaceOptionsFrame_OpenToCategory("Duty")
		InterfaceOptionsFrame_OpenToCategory("Duty") -- need this twice for some reason

	-- Open GUI
	elseif arg == "" then
		core.Duty:Toggle()

	-- Toggle debug
	elseif arg == "debug" then
		core:ToggleDebug()

	-- Reset and restore entire AddOn to default values
	elseif arg == "defaults" then
		core:RestoreDefaults()

	-- Print error
	else
		core:Print("Unknown command. Type '/duty help' for options.")
	end
end

-- Init is the main entry point
function core:Init(event, name)
	if (name ~= "Duty") then return end

	core:Debug("Core: Initializing")

	-- Set or load options
	core:LoadDB()
	
	core:Debug("Init: Create configuration panel.")
	core.Config:Create()

	core:Debug("Init: Create Duty module")
	core.Duty:Create()
	core.Duty:SetOpacity()
	core.Duty:Toggle()
	core.DutySlave:Create()
	core.DutySlave:SetOpacity()

	-- Init comms
	core:Debug("Init: Create Comms module")
	core.Comms:Init(function(player, text)
		core:Debug("comms init callback: " .. player .. ": " .. text)
		local tag, assignment, targets = strsplit(":", text, 3)
		if tag ~= "<DUTY>" then
			return
		end

		core.DutySlave:Set(assignment, targets)
	end)

	-- Functions for key binds
	_G["KeyBinding_ToggleDuty"] = function()
		core.Duty:Toggle()
	end

	-- Register slash command
	SLASH_DUTY1 = "/duty"
	SlashCmdList["DUTY"] = function(arg)
		core:Console(arg)
	end

	-- Register key bindings
	BINDING_HEADER_DUTY = "Duty"
	BINDING_NAME_DUTY_GUI = "Toggle GUI"

	-- Announce loaded
	core:Print("Loaded. Type /duty to open.")
end

-- Init on loaded
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", core.Init)
