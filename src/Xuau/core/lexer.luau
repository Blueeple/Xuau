--!strict
-- Types
type vLang_Cached = {
	-- Configs
	lexerMode: string,
	lineRate: number,
	useMultithreading: boolean,
	useXuauLexer: boolean,
	-- Generated Maps
	mappings: { [string]: { _id: string, keys: { string } } },
}

-- Modules
local LRT_Detector = require("../dependencies/LRT-Detector")
local Debugger = require("./Debugger")
local EZSignal = require("../dependencies/EZSignal")
local LuneTranslator = require("../dependencies/LuneTranslator")
local langLoader = require("../core/langLoader")

-- Lune
local Task = LuneTranslator.getTask()

-- EZSignal
local XuauLexer = EZSignal.new(`Xuau_Lexer-Internal({tostring(debug.info(1, "f"))})`)

-- EZSignal Binds
EZSignal.BindTo(XuauLexer, function(taskId: number)
	--Debugger.Warn(`Task: {taskId}`)
end)

-- Variables
local tasksTracker = {} :: { [string]: { thread } }
local languageCache = {} :: { [string]: vLang_Cached & { [string]: any } }
local lexerModes = {
	--[[
        Processes approximately `math.clamp(math.floor(Count), 1, 256)` lines per cycle.

        `Recomended (32)`
    ]]
	quickMultMode1 = function(code: string, Count: number, Name: string, langName: string)
		local config = languageCache[langName]
		if Count > 323 and config.useMultithreading then
			Debugger.Warn(`Lexer rate's above [512] lines with useMultithreading may cause performance bottlenecks, Count: [{Count}]`)
		end
		if LRT_Detector.isZune() and config.useMultithreading then
		    Debugger.Warn(`Detected [Zune] runtime using Multithreading may result in ZERO performance gain.`)
		end
		local lineSplitter = "║"
		local lines = code:split("\n")
		local startTimer = os.clock()
		local loopMaxIterations = math.ceil(#lines / math.max(1, math.floor(Count)))
		tasksTracker[Name] = {}

		for batchIndex = 1, loopMaxIterations do
			local taskId = #tasksTracker[Name] + 1
			local firstLine = (batchIndex - 1) * Count + 1
			local lastLine = math.min(firstLine + Count - 1, #lines)
			local forTokens = {} :: { string }
			local _tokenizedLines = {} :: { string }
			local handler = function()
				for lineIndex = firstLine, lastLine do
					if lines[lineIndex] then
						local line = lines[lineIndex]:gsub("^%s+", "")
						if not line:match("^%s*$") then
							table.insert(forTokens, line)
						end
					end
				end
				local rawCode_Merged = table.concat(forTokens, lineSplitter)
				local keysToSeek = {} :: { string }
				local languageMappings = languageCache[langName].mappings
				for _, TokenData: { _id: string, keys: { string } } in languageMappings do
					for tokenIndex = 1, #TokenData.keys do
						local tokenToCheck = TokenData.keys[tokenIndex]
						if rawCode_Merged:find(tokenToCheck, 1, true) then
							table.insert(keysToSeek, tokenToCheck)
						end
					end
				end
				for _, Line in forTokens do
					local cursor = 1
					while cursor <= #Line do
						local byte = string.byte(Line, cursor)
						if byte == 32 or byte == 9 then
							--print("Space and tab")
							cursor += 1
						elseif byte == 10 then
							--print("Newline")
							cursor += 1
						else
							--print("Token")
							cursor += 1
						end
					end
				end
			end
			if config.useMultithreading then
				local thread = Task.spawn(function(...)
					EZSignal.Fire(XuauLexer, taskId)
					handler()
				end)
				table.insert(tasksTracker[Name], thread)
			else
				EZSignal.Fire(XuauLexer, taskId)
				handler()
			end
			if batchIndex == loopMaxIterations then
				Debugger.Out(`Tasks: [{#tasksTracker[Name]}]`)
				Debugger.Out(`Processed file: [{Name}] in [{string.format("%.2f", (os.clock() - startTimer) * 1000)}ms].`)
			end
		end
	end,
}

--Module
local Lexer = {}

--[=[
    Reads the given code string and performs lexical analysis on each line.
    - Note to self: You probably want to figure out what a parser does :sob:
]=]
Lexer.ReadCode = function(vlang: langLoader.vLang_Root, code: string, Name: string)
	-- Variables
	local useCustomLexer = next(vlang.customLexer) ~= nil
	local lexerRuleset = vlang.lexerRuleset
	local config = {} :: vLang_Cached
	if not languageCache[vlang._Name] then
		languageCache[vlang._Name] = {}
		config = languageCache[vlang._Name]
		config["mappings"] = {}
		for configName: string, value: any in lexerRuleset do
			config[configName] = value
		end

		local currentAstId = 0
		for mapType, data: { string | number } in vlang.langLexerMappings :: { [string]: {} } do
			if currentAstId ~= data[1] then
				currentAstId = data[1] :: number
				table.remove(data, 1)
			end
			config.mappings[mapType] = { _id = tostring(currentAstId), keys = data }
		end
	end
	if not useCustomLexer or config.useXuauLexer then
		lexerModes[config.lexerMode](code, config.lineRate, Name, vlang._Name)
	else
		-- custom lexer implementation
	end
end

return Lexer
