--!native
--!strict
--!optimize 2

-- Variables
local runtime = "luau"
local isInit = false

--[[
    Detects the Luau runtime.
]]
local queryRuntime = function()
	-- Check for Roblox Runtime
	local isRoblox = pcall(function(...)
		print(getfenv().script.Name)
	end)
	if isRoblox then
		runtime = "rblx"
		isInit = true
		return -- Stops at here when running in Roblox
	end

	-- Detecting Lute Runtime
	local isLute = pcall(function(...)
		local lute = "@lute/fs"
		return require(lute) :: { any }
	end)
	if isLute and tostring(_VERSION):lower() == "luau" then
		runtime = "lute"
		isInit = true
		print("[!][LRT-Detector] - Lute Runtime detected.")
		return
	end

	-- Detecting Lune / Zune Runtimes
	local curRuntime = tostring(_VERSION):lower()
	if curRuntime:match("zune") == "zune" then
		runtime = "zune"
		print("[!][LRT-Detector] - Zune Runtime detected.")
	end
	if curRuntime:match("lune") == "lune" then
		runtime = "lune"
		print("[!][LRT-Detector] - Lune Runtime detected.")
	end

	isInit = true
end

local LRT_D = {}

--[[
    Performs a single check to detect Luau Virtual Machine Runtime.
]]
LRT_D.init = function()
	if not isInit then
		queryRuntime()
	end
end

--[[
    Gets the runtime of the Luau Virtual Machine.
]]
LRT_D.getRuntime = function(): string
	if not isInit then
		queryRuntime()
	end
	return runtime
end

--[[
    Returns true if the runtime is Lune.
]]
LRT_D.isLune = function(): boolean
	if not isInit then
		queryRuntime()
	end
	return runtime == "lune"
end

--[[
    Returns true if the runtime is Zune.
]]
LRT_D.isZune = function(): boolean
	if not isInit then
		queryRuntime()
	end
	return runtime == "zune"
end

--[[
    Returns true if the runtime is Lute.
]]
LRT_D.isLute = function(): boolean
	if not isInit then
		queryRuntime()
	end
	return runtime == "lute"
end

--[[
    Returns true if the runtime is Roblox.
]]
LRT_D.isRoblox = function(): boolean
	if not isInit then
		queryRuntime()
	end
	return runtime == "rblx"
end

return LRT_D
