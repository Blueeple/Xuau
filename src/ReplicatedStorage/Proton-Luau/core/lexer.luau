 --!strict
--!native
--!optimize 2
-- Since I'm still learning how stuff works in @native mode I MIGHT mess some core things.

-- Modules
local EZSignal = require("../dependencies/EZSignal")
local EZFastLex = require("./EZFastLex")

-- Functions
--[=[
    Reads the given line of code in the preferred language and fires a signal with the characters for pharsing.
]=]
local ReadLine = function(line: string)
	local chars = {}
	local cursor = 1
	local decomp = function()
		EZSignal.Fire("ProtonLuau", 2, "!lineStart")
		while cursor <= #line do
			table.insert(chars, line:sub(cursor, cursor))
			cursor += 1
		end
		EZFastLex.Lex(chars)
	end
	decomp()
	EZSignal.Fire("ProtonLuau-Parser", chars)
end

--Module
local Lexer = {}

--[=[
    Reads the given code string and performs lexical analysis on each line.
    - Note to self: You probably want to figure out what a parser does :sob:
]=]
Lexer.ReadCode = function(code: string)
	local lines = {} :: { [number]: string }
	EZSignal.Fire("ProtonLuau", 2, "!codeStart")

	for _, line in code:split("\n") do
		ReadLine(line)
		table.insert(lines, line)
	end
	EZSignal.Fire("ProtonLuau", 2, "!codeEnd")
end

return Lexer
