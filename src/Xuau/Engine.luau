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
local LRT_Detector = require("./dependencies/LRT-Detector")
local LuneTranslator = require("./dependencies/LuneTranslator")

-- Critical Inits
LRT_Detector.init()
LuneTranslator.init()

-- Modules
local ConfigFetcter = require("./dependencies/ConfigFetcher")
local Debugger = require("./core/Debugger")
local EZSignal = require("./dependencies/EZSignal")
local lexer = require("./core/lexer")
--local parser = require("./core/parser")
local langLoader = require("./core/langLoader")

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
    print(`[!][Xuau] - Engine early init in {os.clock() - init}s.`)
end

XuauEngine.Init = function()
    if LRT_Detector.isLute() then
        ConfigFetcter.load()
        isInitForLute = true
    end
    print(`[!][Xuau] - Engine initialized in {os.clock() - init}s.`)
end

XuauEngine.CompileToLuau = function(language: string, code: { string })
    if not isInitForLute and LRT_Detector.isLute() then
        print("[!][Xuau] - Bootstrapper not initialized For Lute. Calling Init()...")
        XuauEngine.Init()
        isInitForLute = true
    elseif LRT_Detector.isRoblox() then
        print(`[!][Xuau] - Engine initialized in {os.clock() - init}s.`)
    end
    Debugger.Out("Compiling to Luau...")
    local vlang = langLoader.getLanguage(language)
    if not vlang._Exists then
        Debugger.Warn(`Language: {language} not found.`)
        Debugger.Warn(`Stopping execution.`)
        return
    end
	lexer.ReadCode(vlang :: any, code[1])
end

return XuauEngine
