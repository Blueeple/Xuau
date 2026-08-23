--[=[
	DOD Native signal system.
]=]
--!native
--!optimize 2
--!strict

-- Variables
local script = { Name = "EZSignal" }
local Signals = {} :: { [string]: { (...any) -> () } }
local ToBindLater = {} :: { [string]: { (...any) -> () } }

local EZSignal = {}

--[=[
    Creates a new signal.
]=]
EZSignal.new = function(Name: string)
	if Signals[Name] then
		print(`[{script.Name}] - {Name} already exists.`)
		return ""
	end

	Signals[Name] = {}
	if ToBindLater[Name] then
		coroutine.wrap(function()
			for _, Bind in ToBindLater[Name] do
				table.insert(Signals[Name], Bind)
			end
			ToBindLater[Name] = nil
		end)()
	end

	return Name
end

--[=[
    Adds a function to be fired in a signal
]=]
EZSignal.BindTo = function(Name: string, func: (...any) -> ())
	if Signals[Name] then
		table.insert(Signals[Name], func)
	else
		print(`[{script}] - Signal {Name} does not exist.`)
	end
end

--[=[
    Same as BindTo but waits until the function exists (I'm NOT cleaning up for you)
]=]
EZSignal.BindToAsync = function(Name: string, func: (...any) -> ())
	if Signals[Name] then
		EZSignal.BindTo(Name, func)
		return
	end
	if ToBindLater[Name] then
		table.insert(ToBindLater[Name], func)
		return
	end
	if not ToBindLater[Name] then
		ToBindLater[Name] = {}
		table.insert(ToBindLater[Name], func)
	end
end

--[=[
    Unbinds functions from signals.
]=]
EZSignal.UnBind = function(Name: string, func: (...any) -> ())
	if Signals[Name] then
		local Index = table.find(Signals[Name], func)
		if not Index then
			print(`[{script.Name}] - Function {func} doesn't exist.`)
		end

		table.remove(Signals[Name], Index)
	else
		print(`[{script.Name}] - Signal does not exist.`)
	end
end

--[=[
    Unbinds every functions from signal.
]=]
EZSignal.UnBindAll = function(Name: string)
	if Signals[Name] then
		Signals[Name] = {}
	else
		print(`[{script.Name}] - Signal does not exist.`)
	end
end

--[=[
    Fires signals.
]=]
EZSignal.Fire = function(Name: string, ...)
	if not Signals[Name] then
		print(`[{script.Name}] - No signal named: {Name} exists.`)
		return
	end
	coroutine.wrap(function(...)
		for _, func in Signals[Name] do
			func(...)
		end
	end)(...)
end

--[=[
    Fires signals and cleans up right after such.
]=]
EZSignal.FireOnce = function(Name: string, ...)
	local FunctionsToFire = Signals[Name]
	if not FunctionsToFire then
		return
	end
	coroutine.wrap(function(...)
		for _, func in FunctionsToFire do
			func(...)
		end
	end)(...)
end

--[=[
    Gets the number of Binds in bind to later
]=]
EZSignal.GetBindToLater = function()
	local count = 0
	for _, _ in ToBindLater do
		count += 1
	end
	return count
end

--[=[
    Cleans up BindToLater
]=]
EZSignal.CleanUpBindToLater = function()
	ToBindLater = {}
end

return EZSignal
