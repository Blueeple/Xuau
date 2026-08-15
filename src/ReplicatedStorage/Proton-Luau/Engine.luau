--[=[
    Scripted by @Blueeple on @Github
]=]
print("[ProtonLuau] - Started")

-- Modules
local LRT_Detector = require("./dependencies/LRT-Detector")
local EZSignal = require("./dependencies/EZSignal")
local parser = require("./core/parser")
local lexer = require("./core/lexer")
local Debugger = require("./core/Debugger")

-- Variables
local runtime = LRT_Detector.getRuntime()
local currentFile = {} :: typeof(parser.newFile())

print(`[Proton-Luau] - {runtime} | Applying Natives`)

-- Module
local LuauProtonEngine = {}

-- Signals
EZSignal.new("ProtonLuau")
EZSignal.new("ProtonLuau-Parser")

-- [ Signal Binds ]
EZSignal.BindTo("ProtonLuau", function(intructionId: number, arg: string)
	print(intructionId, arg)
end)
EZSignal.BindTo("ProtonLuau-Parser", function(charTable: { string })
	currentFile = parser.newFile()
	parser.parseLexerResult(charTable)

	if currentFile then
		Debugger.Out(currentFile)
	end
end)

LuauProtonEngine.CompileToLuau = function(code: { string })
	lexer.ReadCode(code[1])
end

return LuauProtonEngine
