--!strict
-- Modules
local LRT_Detector = require("../dependencies/LRT-Detector")
local ConfigFetcter = require("../dependencies/ConfigFetcher")
local Debugger = require("../core/Debugger")
local LuneTransulator = require("../dependencies/LuneTransulator")

-- Lune Modules
local fs = LuneTransulator.getFileSystem()
local serde = LuneTransulator.getSerde()

-- Folder paths
local cwd = LuneTransulator.getProcess().cwd()

-- Module
local langLoader = { _langs = {} :: { [string]: any } }
langLoader.getLanguage = function(languageName: string)
    if LRT_Detector.isRoblox() then
        return {
            _Exists = true,
        }
    end
	if not ConfigFetcter.getConfig_Toml("path") or ConfigFetcter.getConfig_Toml("path") == "" then
		error("FATAL XUAU CRASH! Please Define a path in Xuau.toml")
	end
	if langLoader._langs[languageName] then
		return {
			_Exists = true,
			LangLibrary = langLoader._langs[languageName],
		}
	end
	local LangInfoPath = cwd .. ConfigFetcter.getConfig_Toml("path") .. "langInfo\\"
	Debugger.Out(`Getting Language: {languageName}`)

	local languagePath = LangInfoPath .. languageName:lower()
	if not fs.isDir(languagePath) then
		Debugger.Warn("Language not found: " .. languageName)
		return {
			_Exists = false,
		}
	end

	local LangInfoList = fs.readDir(languagePath) :: { string }
	local customLexer = {}
	local LangLibrary = {}
	for _, file in LangInfoList do
		local filePath = `{languagePath}\\{file}`
		if fs.isFile(filePath) then
		    -- Checking it's a Luau file
			if file:match("luau$") then
				--local module = require("./" .. filePath:match("^(.+)%.luau+$") :: string) :: {}
				continue
			end

			local content = fs.readFile(filePath)
			LangLibrary[file:match("^(.+)%..+$")] = serde.decode("json", content)
		end
	end
	langLoader._langs[languageName] = LangLibrary
	return {
		_Exists = true,
		LangLibrary = LangLibrary,
		customLexer = customLexer
	}
end

return langLoader
