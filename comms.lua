-- Load and set namespace
local addonName, core = ...
core.Comms = {}
local Comms = core.Comms

local callback

function Comms:Init(handleFunc)
	Comms.Frame = CreateFrame("Frame", addonName .. "CommsFrame", UIParent)
	Comms.Frame:Hide()

	-- Set callback handler
	callback = handleFunc

	-- Events
	core:RegisterEvents(Comms.Frame, Comms.HandleEvents,
		"CHAT_MSG_WHISPER"
	)
end

-- Handle events and reposition some stuff that is otherwise immovable
function Comms:HandleEvents(event, arg1, ...)
	-- Receiving whisper
	if event == "CHAT_MSG_WHISPER" then
		core:Debug("Comms: HandleEvents:", event)
		Comms:HandleWhisper(arg1, ...)

	-- Registered but not handled...
	else
		core:Debug("Comms: HandleEvents: not handled:", event)
	end
end

function Comms:HandleWhisper(text, playerName, _, _, playerName2, ...)
	core:Debug("Comms: " .. playerName2 .. ": " .. text)
	callback(playerName2, text)
end