--[=[
    Scripted by @Blueeple on @Github
]=]
print("[Xuau] - Starting")

-- Types
type Configuration = {
    Language: string,
}

-- Critical Modules
local LRT_Detector = require("./dependencies/LRT-Detector")
local LuneTransulator = require("./dependencies/LuneTransulator")

-- Critical Inits
LRT_Detector.init()
LuneTransulator.init()

-- Modules
local ConfigFetcter = require("./dependencies/ConfigFetcher")
local Debugger = require("./core/Debugger")
local EZSignal = require("./dependencies/EZSignal")
local lexer = require("./core/lexer")
local parser = require("./core/parser")
local langLoader = require("./core/langLoader")

-- Variables
local runtime = LRT_Detector.getRuntime()
local isInitForLute = false

print(`[Xuau] - {runtime} | Applying Natives`)
-- Signals
EZSignal.new("Xuau")
EZSignal.new("Xuau-Parser")

-- [ Signal Binds ]
EZSignal.BindTo("Xuau", function(intructionId: number, arg: string)
	print(intructionId, arg)
end)
EZSignal.BindTo("Xuau-Parser", function(charTable: { string })
	local _ = parser.newFile()
	Debugger.Out(charTable)
	--parser.parseLexerResult(charTable)
end)

ConfigFetcter.onLoad(function()
    -- Configs
    local ForceDisableDebugOutput = ConfigFetcter.getConfig_Json("ForceDisableDebugOutput")
    local PreferedRuntime = ConfigFetcter.getConfig_Json("PreferedRuntime")
    
    if ForceDisableDebugOutput then
        Debugger.ApplyOverides("DO_OUTPUT", false)
    end

    if PreferedRuntime ~= nil and PreferedRuntime ~= LRT_Detector.getRuntime() then
        LuneTransulator.ForceRuntime(PreferedRuntime)
    end
end)

-- Module
local XuauEngine = {}
if LRT_Detector.isLune() or LRT_Detector.isZune() then
    ConfigFetcter.load()
end

XuauEngine.Init = function()
    if LRT_Detector.isLute() then
        ConfigFetcter.load()
    end
    print("[!][Xuau] - Setup completed.")
end

XuauEngine.CompileToLuau = function(language: string, code: { string })
    if not isInitForLute and LRT_Detector.isLute() then
        print("[!][Xuau] - Bootstrapper not initialized For Lute. Calling Init()...")
        XuauEngine.Init()
        isInitForLute = true
    end
    Debugger.Out("Compiling to Luau...")
    local _lang = langLoader.getLanguage(language)
	lexer.ReadCode(code[1])
end

return XuauEngine
