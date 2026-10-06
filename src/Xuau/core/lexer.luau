--!strict
--!native
--!optimize 2
-- Types
type vLang = {
    _Exists: boolean,
    lexHelper: {  }
}

-- Modules
local Debugger = require("./Debugger")
local EZSignal = require("../dependencies/EZSignal")
local EZFastLex = require("./EZFastLex")

-- Functions
--[=[
    Reads the given line of code in the preferred language and fires a signal with the characters for pharsing.
]=]
local ReadLine = function(line: string)
    return
end

--Module
local Lexer = {}

--[=[
    Reads the given code string and performs lexical analysis on each line.
    - Note to self: You probably want to figure out what a parser does :sob:
]=]
Lexer.ReadCode = function(vlang: vLang, code: string)
     print("|---VLANG-INFO---|")
    Debugger.Out(vlang)
    print("|-------CODE------|")
	for _, line in code:split("\n") do
		print(line)
	end
	print("|-------DONE------|")
end

return Lexer
