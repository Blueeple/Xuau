--!strict
--!native
--!optimize 2

-- Modules
local Debugger = require("../core/Debugger")
local LRT_Detector = require("./LRT-Detector")
local LuneTransulator = require("./LuneTransulator")

-- Functions

if not LRT_Detector.isRoblox() then
	local fs = LuneTransulator.getFileSystem()
	local _serde = LuneTransulator.getSerde()
	local XuauConfigJson: any

	return {
		load = function()
			if not XuauConfigJson then
				XuauConfigJson = fs.readFile("./src/Xuau/config/XuauConfig.json") -- Fix this yo use cwd
			end
		end,
		getConfig = function(Name: string): any
			print(XuauConfigJson)
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
