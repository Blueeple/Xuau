--[=[
    Scripted by @Blueeple on @Github
]=]
print("[Xuau] - Starting")
local init = os.clock()

-- Types
type Configuration = {
	Language: string,
}

-- Critical Modules
local LRT_Detector = require("./Xuau/dependencies/LRT-Detector")
local LuneTranslator = require("./Xuau/dependencies/LuneTranslator")

-- Critical Inits
LRT_Detector.init()
LuneTranslator.init()

-- Modules
local ConfigFetcter = require("./Xuau/dependencies/ConfigFetcher")
local Debugger = require("./Xuau/core/Debugger")
local EZSignal = require("./Xuau/dependencies/EZSignal")
local lexer = require("./Xuau/core/lexer")
local langLoader = require("./Xuau/core/langLoader")

-- Lune
local fs = LuneTranslator.getFileSystem()

-- Variables
local runtime = LRT_Detector.getRuntime()
local isInitForLute = false

print(`[Xuau] - {runtime} | Applying Natives`)
-- Signals
EZSignal.new("Xuau")
EZSignal.new("Xuau-Parser")

-- [ Signal Binds ]

ConfigFetcter.onLoad(function()
	-- Configs
	local ForceDisableDebugOutput = ConfigFetcter.getConfig_Json("ForceDisableDebugOutput")
	local PreferedRuntime = ConfigFetcter.getConfig_Json("PreferedRuntime")

	if ForceDisableDebugOutput then
		Debugger.ApplyOverides("DO_OUTPUT", false)
	end

	if PreferedRuntime ~= nil and PreferedRuntime ~= LRT_Detector.getRuntime() then
		LuneTranslator.ForceRuntime(PreferedRuntime)
	end
end)

-- Module
local XuauEngine = {}
if not LRT_Detector.isLute() and not LRT_Detector.isRoblox() then
	ConfigFetcter.load()
	print(`[!][Xuau][Early] - Engine in [{string.format("%.2f", (os.clock() - init) * 1000)}ms].`)
end

--[=[
    Initializes the Xuau Engine.
    - Optional
]=]
XuauEngine.Init = function()
	if LRT_Detector.isLute() then
		ConfigFetcter.load()
		isInitForLute = true
	end
	print(`[!][Xuau] - Engine initialized in [{string.format("%.2f", (os.clock() - init) * 1000)}ms].`)
end

--[=[
    Reads the external File.
]=]
XuauEngine.ReadExternalFile = function(path: string)
    local fileExists = fs.isFile(path)
    if fileExists then
       return fs.readFile(path) 
    end
    Debugger.Out(`Failed to read path [{path}]`)
    return ""
end

--[=[
    
]=]
XuauEngine.CompileToLuau = function(language: string, code: string, Name: string)
	if not isInitForLute and LRT_Detector.isLute() then
		print("[!][Xuau] - Bootstrapper not initialized For Lute. Calling Init()...")
		XuauEngine.Init()
		isInitForLute = true
	elseif LRT_Detector.isRoblox() then
		print(`[!][Xuau] - Engine initialized in [{string.format("%.2f", (os.clock() - init) * 1000)}ms].`)
	end
	Debugger.Out("Compiling to Luau...")
	local vlang = langLoader.getLanguage(language)
	if not vlang._Exists then
		Debugger.Warn(`Language: {language} not found.`)
		Debugger.Warn(`Stopping execution.`)
		return
	end
	lexer.ReadCode(vlang :: any, code, Name)
end

return XuauEngine
