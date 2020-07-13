-- Load and set namespace
local _, core = ...

-- Stored default options.
core.options = {}
core.data = {}
core.options.debug = false -- print debug statements
core.options.dutyOpacity = 1
core.options.dutyShowFrame = true
core.data.assignList = {}

-- LoadDB tries to load the SavedVariables
function core:LoadDB()
	if _G["DUTYDB"] == nil then
		_G["DUTYDB"] = {
			options = core.options,
			data = core.data
		}
		core:Debug("Core: LoadDB: defaults")
	else
		-- Check if options are nil or not and then link it to core.options
		if _G["DUTYDB"].options then
			core.options = _G["DUTYDB"].options
		else
			_G["DUTYDB"].options = core.options
		end

		core.data = _G["DUTYDB"].data
		core:Debug("Core: LoadDB: user")
	end
end

function core:RestoreDefaults()
	_G["DUTYDB"].options = nil
	core:Print("Restored defaults.")
	ReloadUI()
end

-- Print is a prefixed print function
function core:Print(...)
	print("|cff" .. "f59c0a" .. "Duty:|r", ...)
end

-- Debug is a prefixed print function, which only prints if debug is activated
function core:Debug(...)
	if core.options.debug then
		print("|cff" .. "f59c0a" .. "DEBUG:|r", ...)
	end
end
function core:ToggleDebug()
	if core.options.debug then
		core.options.debug = false
		core:Print("Debugging off.")
	else
		core.options.debug = true
		core:Print("Debugging on.")
	end
end

-- RegisterEvents sets events for the obj using the handlerFunc
function core:RegisterEvents(obj, handlerFunc, ...)
	core:Debug("Core: RegisterEvents:", tostringall(...))
	for i = 1, select("#", ...) do
		local ev = select(i, ...)
		obj:RegisterEvent(ev)
	end
	obj:SetScript("OnEvent", handlerFunc)
end

-- A better remove from list than table.remove
function core:ArrayRemove(t, fnKeep)
    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end