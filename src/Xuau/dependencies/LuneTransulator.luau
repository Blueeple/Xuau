--!strict
--!native
--!optimize 2

-- Modules
local Debugger = require("../core/Debugger")
local LRT_Detector = require("./LRT-Detector")

-- Variables
-- [ Libaries ]
local libraries = {
	-- Shared / overlapping
	"fs",
	"net",
	"process",
	"task",
	"luau",

	-- Lune
	"serde",
	"stdio",
	"datetime",
	"roblox",

	-- Lute
	"crypto",
	"debugger",
	"io",
	"client",
	"server",
	"syntax",
	"cst",
	"parser",
	"system",
	"time",
	"vm",
}
local nativeLibs = {}
local nativeLuneLibraryLink = {
	fs = {
		-- Lune & Lute
		copy = 2,
		move = 2,
		readDir = function(curLib: { [string]: (...any) -> any }, path: string)
			local result = curLib["listdir"](path)
			local luneResult = {}
			for _, luteDir: { name: string } in result do
				luneResult[#luneResult + 1] = luteDir.name
			end
			return luneResult
		end,
		writeDir = function(curLib: { [string]: (...any) -> any }, path: string)
			curLib["mkdir"](path)
		end,
		writeFile = function(curLib: { [string]: (...any) -> any }, path: string, content: string)
			local file = curLib["open"](path, "w")
			curLib["write"](file, content)
			curLib["close"](file)
		end,
		readFile = function(curLib: { [string]: (...any) -> any }, path: string)
			local file = curLib["open"](path, "r")
			local content = curLib["read"](file)
			curLib["close"](file)
			return content
		end,
	},
	serde = require("./LuneModules/serde"),
}

-- [ Runtime ]
local runtime = LRT_Detector.getRuntime()

-- [ Internal ]
local isInit = false

-- [ Settings ]
local MERGE_SYS_PROCESS_IN_LUTE = true

local System = {
	cwd = "",
	os = "",
}

-- Functions
--[[
    Generates the runtime library for the given library name.

    Returns the library table.
]]
local GenerateRuntimeLibray = function(libName: string)
	local libPath = `@{runtime}/{libName:lower()}`
	local isRequired, lib = pcall(function(...)
		return require(libPath :: string) :: { [string]: (...any) -> any }
	end)
	if not isRequired or (MERGE_SYS_PROCESS_IN_LUTE and libName == "system") then
		return
	end

	local libFunctions = {}
	for funcName, func: (...any) -> () in lib do
		libFunctions[funcName] = func
	end
	if MERGE_SYS_PROCESS_IN_LUTE and libName == "process" and LRT_Detector.getRuntime() == "lute" then
		local luteSys_Path = "@lute/system"
		local sysTarget = require(luteSys_Path :: string) :: { [string]: (...any) -> any }
		for funcName, func: (...any) -> () in sysTarget do
			libFunctions[funcName] = func
		end
	end

	nativeLibs[libName] = libFunctions
end

--[[
    Normalize system data.
]]
local normalizeSystemData = function()
	if System.os:find("win") then
		System.os = "windows"
	elseif System.os:find("mac") or System.os:find("darwin") then
		System.os = "macos"
	elseif System.os:find("linux") or System.os:find("arch") then
		System.os = "linux"
	end

	--cwd checks here later
end

--[[
    Returns the result of the lib function call.

    - Designed to return the result of the Properties in Lune / Lute Libraries
    - **Use at YOUR OWN risk!**
]]
local doLibraryCall = function(libName: string, funcName: string, ...): any
	local lib = nativeLibs[libName]
	if not lib then
		Debugger.Warn(`Unable to find Library: '{libName}'`)
		Debugger.Warn("XuauVirtualOS Does not exist yet.")
		return
	end
	local target = lib[funcName] :: (...any) -> any
	if not target then
		Debugger.Warn(`Unable to find Function | Property {funcName} in Library {libName}`)
		return
	end
	if typeof(target) == "function" then
		return target(...)
	else
		return target :: any
	end
end

--[[
    Returns the result of the lib function call from Lune, with support for Lute eqivalents
]]
local luneLib_CallFunc = function(libName: string, funcName: string, ...)
	-- Variables
	local args = { ... }
	local lib = nativeLibs[libName] :: { [string]: (...any) -> any }
	if LRT_Detector.isLune() then
		return lib[funcName](unpack(args))
	elseif LRT_Detector.isLute() then
		local func = nativeLuneLibraryLink[libName][funcName] :: (...any) -> any
		return func(lib, unpack(args))
	else
		Debugger.Warn("Unsupported runtime for now!")
		return
	end
end

-- Module
local LRT_Lmapper = {}

--[[
    Scrapes the native libraries for the current runtime.
]]
LRT_Lmapper.loadRuntimeLibraries = function()
	if next(nativeLibs) then
		return
	end
	for _, LibName in libraries do
		GenerateRuntimeLibray(LibName)
	end
end

--[[
    Returns the native libraries for the current runtime.
]]
LRT_Lmapper.getNativeLibs = function()
	return nativeLibs
end

--[[
    Probes the native libraries between Lute and lune and see who shared functions per lib.
    - **DEBUGGING ONLY & Written using ChatGPT (No way I'm writting allat with no sleep)**
]]
LRT_Lmapper.probeNativeLibs = function()
	if LRT_Detector.getRuntime() == "lute" then
		local availableLibsForLune = {}
		Debugger.ApplyOverides("DO_OUTPUT", true)
		-- Lute stuff
		print("[!] - Libraries in Lute")
		Debugger.Out(nativeLibs)

		-- Probbing lune
		print("[!] - Probbing for Lune Libraries exposed in Lute runtime.")
		for _, LibName in libraries do
			local luneHas, lib = pcall(function(...)
				local path = "@lune/" .. LibName
				return require(path :: string) :: {}
			end)
			if luneHas then
				print("Library found: " .. LibName)
				availableLibsForLune[LibName:lower()] = lib
			end
		end
		Debugger.Out(availableLibsForLune)
		print("[!] - Comparing libs and closest functions, Via :match() and :find() and :lower()")
		print("[!] - using custom detection algorithim.")
		print("[!] - Checking for common libraries in Lute and Lune, Via Name cross-reference.")

		for LibName, _ in availableLibsForLune do
			if nativeLibs[LibName] then
				print(LibName .. " was found in Lute")
			end
		end

		-- Checking for common functions in each
		--[[Notes:
		    only the task library matches 1:1 so far

		]]
		print("[!] - Checking for common functions in each library")

		local perfectMatches = {} :: { [string]: boolean }
		local libsMatched = {} :: { [string]: {} }

		for LibName, luneLib in availableLibsForLune do
			if nativeLibs[LibName] then
				print("[A] - Checking in: " .. LibName)

				local luteCount = 0
				local luneCount = 0
				local commonCount = 0

				for FuncName, _ in luneLib do
					luneCount += 1

					if nativeLibs[LibName][FuncName :: string] then
						commonCount += 1
						print(FuncName :: string .. " was found in both Lute and Lune for [" .. LibName .. "]")
					end
				end

				for _ in nativeLibs[LibName] do
					luteCount += 1
				end

				local isPerfectMatch = luneCount == luteCount and commonCount == luneCount and luneCount > 0

				if isPerfectMatch then
					perfectMatches[LibName] = true
				end

				libsMatched[LibName] = {
					common = commonCount,
					lune = luneCount,
					lute = luteCount,
					perfect = isPerfectMatch,
				}

				Debugger.Out(libsMatched[LibName])
			end
		end
		Debugger.Out(libsMatched)
		print("[!] - Completed check phase 1")
	end
end

--[[
    Initializes the LRT Library Map.
]]
LRT_Lmapper.init = function()
	if isInit then
		return
	end
	if not next(nativeLibs) then
		LRT_Lmapper.loadRuntimeLibraries()
	end

	-- Libraries
	System.cwd = doLibraryCall("process", "cwd")
	System.os = string.lower(doLibraryCall("process", "os") :: string or "XuauVirualOS") :: string

	-- Normalization for Lute and Lune data
	normalizeSystemData()

	-- Init Process
	isInit = true
end

--[[
    Gets the file system function.
]]
LRT_Lmapper.getFileSystem = function()
	return {
		-- Directory
		readDir = function(path: string): { string }
			return luneLib_CallFunc("fs", "readDir", path) :: any
		end,
		writeDir = function(path: string)
			return luneLib_CallFunc("fs", "writeDir", path)
		end,
		-- File write / read
		writeFile = function(path: string, content: string)
			return luneLib_CallFunc("fs", "writeFile", path, content)
		end,
		readFile = function(path: string): string
			return luneLib_CallFunc("fs", "readFile", path) :: any
		end,
	}
end

--[[
    Gets the file system function.

    - Unstable as of now.
]]
LRT_Lmapper.getSerde = function()
	return {
		-- Directory
		decode = function(format: string, encoded: string): { string }
			return luneLib_CallFunc("serde", "decode", format, encoded) :: any
		end,
	}
end

return LRT_Lmapper
