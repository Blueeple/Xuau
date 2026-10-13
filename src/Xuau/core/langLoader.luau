--!strict
-- Types
export type vLang_Root = {
	_Name: string,
	_Exists: boolean,
	customLexer: { [string]: (...any) -> any },
	langLexerMappings: {
		keywords: { number | string },
		boolean: { number | string }
	},
	lexerRuleset: { [string]: any },
}

-- Modules
local LRT_Detector = require("../dependencies/LRT-Detector")
local ConfigFetcter = require("../dependencies/ConfigFetcher")
local Debugger = require("../core/Debugger")
local LuneTranslator = require("../dependencies/LuneTranslator")

-- Lune Modules
local fs = LuneTranslator.getFileSystem()
local serde = LuneTranslator.getSerde()

-- Folder paths
local cwd = LuneTranslator.getProcess().cwd()

-- Variables
local macros = {
	customLexer = function(vLangRoot: vLang_Root, content: any)
		local lexerModule = content :: { [string]: (...any) -> any }
		lexerModule["_name"] = nil
		vLangRoot.customLexer = lexerModule
	end,
	langLexerMappings = function(vLangRoot: vLang_Root, content: any)
		local mappings = content :: string
		vLangRoot.langLexerMappings = serde.decode("json", mappings)
	end,
	lexerRules = function(vLangRoot: vLang_Root, content: any)
		local ruleset = content
		vLangRoot.lexerRuleset = serde.decode("json", ruleset)
	end,
} :: { [string]: (vLangRoot: vLang_Root, ...any) -> () }

-- Module
local langLoader = { _langs = {} :: { [string]: any } }
langLoader.getLanguage = function(languageName: string)
	if LRT_Detector.isRoblox() then
		return {
			_Exists = true,
			-- XuauVOS implementation later
		}
	end
	if not ConfigFetcter.getConfig_Toml("path") or ConfigFetcter.getConfig_Toml("path") == "" then
		error("FATAL XUAU CRASH! Please Define a path in Xuau.toml")
	end
	if langLoader._langs[languageName] then
		return langLoader._langs[languageName]
	end
	local LangInfoPath = cwd .. ConfigFetcter.getConfig_Toml("path") .. "langInfo/"
	Debugger.Out(`Getting Language: {languageName}`)

	local languagePath = LangInfoPath .. languageName:lower()
	if not fs.isDir(languagePath) then
		Debugger.Warn("Language not found: " .. languageName)
		return {
			_Exists = false,
		}
	end

	local LangInfoList = fs.readDir(languagePath) :: { string }
	local vLangRoot: vLang_Root = {
		_Name = languageName,
		_Exists = false,
		customLexer = {},
		langLexerMappings = {} :: any,
		lexerRuleset = {},
	}

	for _, file in LangInfoList do
		local filePath = string.gsub(`{languagePath}/{file}`, "\\", "/")
		if fs.isFile(filePath) then
			local module = nil :: { [string]: any }?

			if file:match("luau$") then
				local name = file:gsub(".luau", "")
				module = require(`../langInfo/{languageName}/{name}`) :: { [string]: any }
				module["_name"] = name
			end
			if module and macros[module["_name"]] then
				macros[module["_name"]](vLangRoot, module)
				continue
			end

			local content = fs.readFile(filePath)
			local isJsonFile = file:match(".json") == ".json"
			local fileName = file:gsub(".json", "")

			if isJsonFile and macros[fileName] then
				macros[fileName](vLangRoot, content)
			end
		end
	end

	langLoader._langs[languageName] = vLangRoot
	vLangRoot._Exists = true
	return vLangRoot
end

return langLoader
