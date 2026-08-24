--!strict
--!native
--!optimize 2

-- Modules
local Debugger = require("../core/Debugger")
local LRT_Detector = require("./LRT-Detector")
local LuneTransulator = require("./LuneTransulator")

-- Functions

if not LRT_Detector.isRoblox() then
	local process = LuneTransulator.getProcess()
	local fs = LuneTransulator.getFileSystem()
	local serde = LuneTransulator.getSerde()

	local cwd = process.cwd()
	local cwdDir = {} :: { string }
	local XuauConfig_Json: any
	local XuauConfig_Luau = {}

	return {
		load = function()
			if not XuauConfig_Json then
				--local XuauLockFile = fs

				XuauConfig_Json = fs.readFile("./src/Xuau/config/XuauConfig.json") -- Fix this yo use cwd
				cwdDir = fs.readDir(cwd)

				XuauConfig_Luau = serde.decode("json", XuauConfig_Json)
				Debugger.Out(serde.encode("json", XuauConfig_Luau))

				-- Find Xuau in the current directory
				local Folders = {}
				for _, folder: string in cwdDir do
					if fs.isDir(folder) then
						Folders[#Folders + 1] = folder
					end
				end
				Debugger.Out(Folders)
			end
		end,
		getConfig = function(Name: string): any
			Debugger.Out(XuauConfig_Json)
			return ""
		end,
	}
end

-- Roblox implementation
local path = "../config/XuauConfig"
local XuauConfig = require(path) :: { [string]: any }
return {
	load = function()
		Debugger.Warn("The 'Load' function is not needed in Roblox, Consider removing it.")
		return
	end,
	getConfig = function(Name: string): any
		return XuauConfig[Name]
	end,
}
