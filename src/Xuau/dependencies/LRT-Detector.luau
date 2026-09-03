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
	end

	-- Detecting Runtime
	local isLune = pcall(function(...)
		local lune = "@lune/task"
		return require(lune) :: { any }
	end)
	local isLute = pcall(function(...)
		local lute = "@lute/fs"
		return require(lute) :: { any }
	end)

	-- Detect Lune/Lute runtime when both are present.
	if isLune and isLute then
		print("[!][LRT-Detector] - Detected Lune and Lute runtimes, Detecting Runtime...")
		local isRunningLune, warnfunc = pcall(function(...)
			return getfenv()["warn"] -- Only Lune / Roblox runtime has a warn global function
		end)
		if not isRunningLune and warnfunc then
			runtime = "lute"
			print("[!][LRT-Detector] - Lute Runtime detected.")
		end
	elseif isLune and not isLute then
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
