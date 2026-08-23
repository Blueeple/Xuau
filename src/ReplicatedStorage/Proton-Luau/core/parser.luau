--!strict
-- optimize 2

-- Modules
local Debugger = require("../core/Debugger")

-- Storage
local files = {} :: { [string]: { any } }

-- Namespaces
local parser = {}
local _functions = {}

-- Local functions
--[[]]
local generateRandomFileId = function(): string
	local fileId = "#"
	local chars = { "X", "Y", "Z", "Q", "R", "S", "T", "U", "V", "W", "M", "N", "F", "E", "W", "A", "0", "1", "3", "5", "7" }
	for i = 1, 23 do
		if i % 4 == 0 then
			fileId = fileId .. "-"
		else
			fileId = fileId .. chars[math.random(1, #chars)]
		end
	end
	return fileId
end

-- Parser
parser.newFile = function()
	local fileId = generateRandomFileId()
	files[fileId] = {}
	Debugger.Out("Created file: " .. fileId)
	return fileId
end

parser.parseLexerResult = function(lexerResult: {}) end

return parser
