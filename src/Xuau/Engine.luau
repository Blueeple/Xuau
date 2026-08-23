--[=[
    Scripted by @Blueeple on @Github
]=]
print("[Xuau] - Started.")

-- Critical Modules
local LRT_Detector = require("./dependencies/LRT-Detector")
local LuneTransulator = require("./dependencies/LuneTransulator")

-- Critical Inits
LRT_Detector.init()
LuneTransulator.init()

-- Modules
local ConfigFetcter = require("./dependencies/ConfigFetcter")
local Debugger = require("./core/Debugger")
local EZSignal = require("./dependencies/EZSignal")
local lexer = require("./core/lexer")
local parser = require("./core/parser")

-- Variables
local runtime = LRT_Detector.getRuntime()
local isInitForLute = false
local XuauConfig = {}

print(`[Xuau] - {runtime} | Applying Natives`)
if LRT_Detector.isLune() then
    ConfigFetcter.load()
end

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

-- Module
local XuauEngine = {}

XuauEngine.Init = function()
    if LRT_Detector.isLute and next(XuauConfig) == nil then
        XuauConfig = ConfigFetcter.load()
    end
    --ConfigFetcter.getConfig("")
end

XuauEngine.CompileToLuau = function(code: { string })
    if not isInitForLute and LRT_Detector.isLute() then
        print("[!][Xuau] - Engine not initialized For Lute. Calling Init()...")
        XuauEngine.Init()
        isInitForLute = true
    end
    
    Debugger.Out("Compiling to Luau...")
	lexer.ReadCode(code[1])
end

return XuauEngine
