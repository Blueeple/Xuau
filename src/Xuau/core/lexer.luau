--!strict
--!native
--!optimize 2
-- Types
type vLang_Cached = {
	-- Configs
	lexerMode: string,
	lineRate: number,
	useMultithreading: boolean,
	useGlobalLexer: boolean,
	-- Generated Maps
	mappings: { [string]: { _id: number, keys: { string } } },
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
		if Count > 296 and config.useMultithreading  then
			Debugger.Warn(`Lexer rate's above [512] lines with useMultithreading may cause performance bottlenecks, Count: [{Count}]`)
		end
		local lines = code:split("\n")
		local startTimer = os.clock()
		local loopMaxInterations = math.ceil(#lines / (Count / 4))
		tasksTracker[Name] = {}

		for batchIndex = 1, loopMaxInterations do
			local taskId = #tasksTracker[Name] + 1
			local comboLine = ""
			local firstLine = (batchIndex - 1) * Count + 1
			local lastLine = math.min(firstLine + Count - 1, #lines)
			local handler = function()
				for lineIndex = firstLine, lastLine do
					if lines[lineIndex] then
						local line = lines[lineIndex]:gsub("^%s+", "")
						if not line:match("^%s*$") then
							comboLine = `{comboLine}{line}║`
						end
					end
				end
				--print(comboLine)
				-- tokenization here
				-- use gsub & match maybe????
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
			if batchIndex == loopMaxInterations then
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
			-- Checking for userdata bloat and skipping
			if (LRT_Detector.isLute() and typeof(mapType) == "userdata") or typeof(mapType) == "userdata" then
				data = nil :: never
				continue
			end
			if currentAstId ~= data[1] then
				currentAstId = data[1] :: number
				table.remove(data, 1)
			end
			config.mappings[mapType] = { _id = currentAstId, keys = data }
		end
	end
	if not useCustomLexer then
		lexerModes[config.lexerMode](code, config.lineRate, Name, vlang._Name)
	else
		-- custom lexer implementation
	end
end

return Lexer
