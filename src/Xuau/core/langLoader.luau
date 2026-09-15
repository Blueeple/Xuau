--!strict
-- Modules
local ConfigFetcter = require("../dependencies/ConfigFetcher")
local Debugger = require("../core/Debugger")
local LuneTransulator = require("../dependencies/LuneTransulator")

-- Lune Modules
local fs = LuneTransulator.getFileSystem()
local process = LuneTransulator.getProcess()

-- Folder paths
local XuauPath = process.cwd()
local LangInfoPath = XuauPath

-- Module
local langLoader = {}

langLoader.getLanguage = function(languageName: string)
    if not ConfigFetcter.getConfig_Toml("path") or ConfigFetcter.getConfig_Toml("path") == "" then
        error("FATAL XUAU CRASH!")
    end
    LangInfoPath = LangInfoPath .. ConfigFetcter.getConfig_Toml("path") .. "langInfo\\"
    Debugger.Out(`Getting Language: {languageName}`)
    
	local languagePath = LangInfoPath .. languageName:lower()
	if not fs.isDir(languagePath) then
	    print(languagePath)
		Debugger.Warn("Language not found: " .. languageName)
		return {
			_Exists = false,
		}
	end

	local LanguageData = fs.readDir(languagePath)
	Debugger.Out(LanguageData)

	return {
		_Exists = true,
	}
end

return langLoader
