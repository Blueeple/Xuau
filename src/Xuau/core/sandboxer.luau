
--[[
--!strict
-- optimize 2

-- basically a container for code / variable the cpp compiler is tryna take or use
-- Avoiding oop for minimum cpu overhead and utilizing indexed dod for maximum speeds

-- Types
export type ProtonLuauSandbox = {
	Name: string,
	Id: number,
	_Var: { [string]: { [number]: number | any } },
	_Func: { [string]: (...any) -> any },
	_RunnerThread: any?,
}

-- Modules
local EZSignal = require("../dependencies/EZSignal")
local SandboxTemplate = require("../templates/SandboxTemplate")
local astDefinitions = require("../langInfo/astDefinitions") :: { [string]: any }

-- Variables
local sanboxes = {} :: { [number]: ProtonLuauSandbox }
local cleanedUpIndexes = {} :: { number } -- indexes that were once in use but no longer used

-- Functions
local sFunc_ = {}

-- Base functions
local ConstSandbox = function(name: string, id: number): typeof(sanboxes[1])
	local newSandbox = table.clone(SandboxTemplate) :: typeof(sanboxes[1])
	newSandbox.Name = name
	newSandbox.Id = id
	return newSandbox
end

local checkForSanbox = function(id: number)
	if not sanboxes[id] then
		warn(`[{script.Name}] - Sandbox id: {id} doesn't exist.`)
		EZSignal.Fire("ProtonLuau", "-error#FatalSBError", "No sandbox found.")
		task.wait(0.3) -- Forces a compiler hang if above 250ms
	end

	return sanboxes[id]
end

local GetTypeId = function(typeName: string)
	local n = astDefinitions[typeName]
	if n then
		return n
	end
	EZSignal.Fire("ProtonLuau", "-error#TypeRequestSBError")
	return task.wait(0.3)
end

-- Executions controls
-- basically for handing c++ to luau execution and what not

-- Sandbox controls
sFunc_.new = function(fileName: string)
	if #cleanedUpIndexes > 0 then
		local idToReuse = cleanedUpIndexes[1]
		table.remove(cleanedUpIndexes, 1)
		sanboxes[idToReuse] = ConstSandbox(fileName, idToReuse)
		return idToReuse
	end

	local id = table.maxn(sanboxes) + 1
	table.insert(sanboxes, ConstSandbox(fileName, id))
	return id
end

sFunc_.newVar = @native function(id: number, Name: string, typeName: string, data: any)
	local Sandbox = checkForSanbox(id)

	if not Sandbox._Var[Name] then
		if compilerConfigs.utilizeBuffers then
			local typeId, CompData = 0, buffer.create(1) -- Type id is the id of the compresser used for handling said data type, also
			Sandbox._Var[Name] = { typeId, CompData } --
			return id
		end

		local typeId = GetTypeId(typeName)
		Sandbox._Var[Name] = { typeId, data }
		return id
	end
	return task.wait(0.3)
end

sFunc_.execute = @native function(id: number)
	local _Sandbox = checkForSanbox(id)
	-- does nothing for now
	return id
end

-- Module
local sandbox = {}

sandbox.new = sFunc_.new

return sandbox
]]