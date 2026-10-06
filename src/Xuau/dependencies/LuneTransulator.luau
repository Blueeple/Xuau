--!strict
--!native
--!optimize 2
-- Zune global types
type Serde = {
	gzip: {
		compress: (data: string) -> string,
		decompress: (data: string) -> string,
	},

	flate: {
		compress: (data: string) -> string,
		decompress: (data: string) -> string,
	},

	json: {
		encode: (value: any, indent: any?) -> string,
		decode: (data: string) -> any,
		indents: {
			none: number,
			two_spaces: number,
			four_spaces: number,
			tabs: number,
		},
		values: {
			null: any,
		},
	},

	json5: {
		encode: (value: any, indent: any?) -> string,
		decode: (data: string) -> any,
		indents: {
			none: number,
			two_spaces: number,
			four_spaces: number,
			tabs: number,
		},
		values: {
			null: any,
		},
	},

	yaml: {
		encode: (value: any) -> string,
		decode: (data: string) -> any,
	},

	base64: {
		encode: (data: string) -> string,
		decode: (data: string) -> string,
	},

	toml: {
		encode: (value: any) -> string,
		decode: (data: string) -> any,
	},

	brotli: {
		compress: (data: string) -> string,
		decompress: (data: string) -> string,
	},

	zstd: {
		compress: (data: string) -> string,
		decompress: (data: string) -> string,
	},

	lz4: {
		compress: (data: string) -> string,
		decompress: (data: string) -> string,
		compressFrame: (data: string) -> string,
		decompressFrame: (data: string) -> string,
	},

	zlib: {
		compress: (data: string) -> string,
		decompress: (data: string) -> string,
	},
}
type FSPath = {
	dirname: (path: string) -> string,
	basename: (path: string) -> string,
	extension: (path: string) -> string,
	stem: (path: string) -> string,
	join: (...any) -> string,
	resolve: (...any) -> string,
	relative: (from: string, to: string) -> string,
	isAbsolute: (path: string) -> boolean,
	globMatch: (path: string, pattern: string) -> boolean,
}
type FS = {
	makeDir: (path: string) -> (),
	deleteDir: (path: string) -> (),
	deleteFile: (path: string) -> (),
	createFile: (path: string) -> (),
	copy: (from: string, to: string) -> (),
	move: (from: string, to: string) -> (),
	embedFile: (path: string) -> (),
	readFile: (path: string) -> string,
	readFileSync: (path: string) -> string,
	writeFile: (path: string, data: string) -> (),
	writeFileSync: (path: string, data: string) -> (),
	realPath: (path: string) -> string,
	stat: (path: string) -> any,
	metadata: (path: string) -> any,
	entries: (path: string) -> { string },
	openFile: (path: string) -> any,
	watch: (path: string) -> any,
	getExePath: () -> string,

	path: FSPath,

	embeddedFiles: () -> { string },
	embeddedScripts: () -> { string },
	symlink: (from: string, to: string) -> (),
}
type Mem = {
	MAX_SIZE: number,

	len: (value: any) -> number,
	slice: (...any) -> any,
	copy: (...any) -> any,
	set: (...any) -> any,
	eql: (...any) -> boolean,
	eqlSlice: (...any) -> boolean,

	find: (...any) -> any,
	findPos: (...any) -> any,
	findLast: (...any) -> any,
	findAny: (...any) -> any,
	findAnyLast: (...any) -> any,
	findNone: (...any) -> any,
	findNoneLast: (...any) -> any,
	findScalar: (...any) -> any,
	findScalarPos: (...any) -> any,
	findScalarLast: (...any) -> any,

	findMin: (...any) -> any,
	findMax: (...any) -> any,
	findMinMax: (...any) -> any,
	max: (...any) -> any,
	min: (...any) -> any,

	startsWith: (...any) -> boolean,
	endsWith: (...any) -> boolean,
	trim: (...any) -> any,
	trimLeft: (...any) -> any,
	trimRight: (...any) -> any,

	cut: (...any) -> any,
	cutLast: (...any) -> any,
	cutPrefix: (...any) -> any,
	cutSuffix: (...any) -> any,
	cutScalar: (...any) -> any,
	cutScalarLast: (...any) -> any,

	replaceScalar: (...any) -> any,
	reverse: (...any) -> any,
	rotate: (...any) -> any,

	toVector2: (...any) -> any,
	toVector3: (...any) -> any,
	writeVector2: (...any) -> any,
	writeVector3: (...any) -> any,
}
type Thread = {
	receive: (...any) -> any,
	send: (...any) -> any,
	fromModule: (...any) -> any,
	fromBytecode: (...any) -> any,
	getCpuCount: () -> number,
	isThread: boolean,
}
type Time = {
	date: {
		now: () -> any,
		parse: (value: string) -> any,
		fromIsoDate: (value: string) -> any,
		fromUnixTimestamp: (value: number) -> any,
		fromUnixTimestampMillis: (value: number) -> any,
		fromUniversalTime: (...any) -> any,
		fromLocalTime: (...any) -> any,
	},

	instant: {
		now: () -> any,
	},

	timestamp: () -> number,
	timestampMillis: () -> number,
}
type Process = {
	exit: (code: number?) -> never,
	pid: () -> number,
	run: (...any) -> any,
	cwd: () -> string,

	os: string,
	arch: string,

	args: { string },
	env: { [string]: string },

	loadEnv: (...any) -> any,
	onSignal: (...any) -> any,
	create: (...any) -> any,
}
type Task = {
	defer: (thread: thread) -> (),
	cancel: (thread: thread) -> (),
	count: () -> number,
	spawn: (() -> (), ...any) -> thread,
	delay: (number, () -> (), ...any) -> thread,
	wait: (number?) -> number,
}
type Luau = {
	coverage: (...any) -> any,
	parse: (source: string) -> any,
	parseExpr: (source: string) -> any,
	compile: (source: string) -> string,
	load: (...any) -> any,
	garbagecollect: (...any) -> any,
}
type Platform = {
	getHostName: () -> string,
	getKernelVersion: () -> string,
	getFreeMemory: () -> number,
	getTotalMemory: () -> number,
	getPageSize: () -> number,

	async: string,
	abi: string,
	os: string,

	cpu: {
		arch: string,
		endian: string,
	},
}
type IO = {
	stdin: any,
	stdout: any,
	stderr: any,

	format: (...any) -> string,

	createBufferSink: (...any) -> any,
	createFixedBufferStream: (...any) -> any,

	terminal: {
		isTTY: boolean,
		getSize: () -> any,
		enableRawMode: () -> (),
		restoreMode: () -> (),
		getCurrentMode: () -> any,
	},
}

-- Modules
local Debugger = require("../core/Debugger")
local LRT_Detector = require("./LRT-Detector")

-- Variables
-- [ Libaries ]
local zuneGlobal = {} :: {
	Serde: Serde,
	FS: FS,
	Mem: Mem,
	Thread: Thread,
	Time: Time,
	Process: Process,
	Task: Task,
	Luau: Luau,
	Platform: Platform,
	IO: IO,
}
local libraries = {
	-- Shared
	"fs",
	"net",
	"process",
	"task",
	"luau",

	-- Lune
	"serde",
	"stdio",
	"datetime",
	"roblox",

	-- Lute
	"crypto",
	"debugger",
	"io",
	"client",
	"server",
	"syntax",
	"cst",
	"parser",
	"system",
	"time",
	"vm",
}
local nativeLibs = {}
local nativeExternalNamespaces = {} :: { [string]: { [string]: any } }
local registeredGlobals = {} :: { [string]: typeof(zuneGlobal) & {} }
local nativeLuneLibraryLink = {
	lute = {
		fs = {
			copy = function(curLib: { [string]: (...any) -> any }, source: string, destination: string, overwrite: boolean)
				if overwrite then
					curLib["remove"](destination)
				end
				curLib["copy"](source, destination)
			end,
			move = function(curLib: { [string]: (...any) -> any }, source: string, destination: string, overwrite: boolean)
				if overwrite then
					curLib["remove"](destination)
				end
				curLib["copy"](source, destination)
			end,
			readDir = function(curLib: { [string]: (...any) -> any }, path: string)
				local result = curLib["listdir"](path)
				local luneResult = {}
				for _, luteDir: { name: string } in result do
					luneResult[#luneResult + 1] = luteDir.name
				end
				return luneResult
			end,
			writeDir = function(curLib: { [string]: (...any) -> any }, path: string)
				curLib["mkdir"](path)
			end,
			writeFile = function(curLib: { [string]: (...any) -> any }, path: string, content: string)
				local file = curLib["open"](path, "w")
				curLib["write"](file, content)
				curLib["close"](file)
			end,
			readFile = function(curLib: { [string]: (...any) -> any }, path: string)
				local file = curLib["open"](path, "r")
				local content = curLib["read"](file)
				curLib["close"](file)
				return content
			end,
			isDir = function(curLib: { [string]: (...any) -> any }, path: string)
				return curLib["exists"](path)
			end,
			isFile = function(curLib: { [string]: (...any) -> any }, path: string)
				return curLib["exists"](path)
			end,
		},
		serde = {
			decode = function(_, format: string, data: string): string | { [string]: any }
				if format:lower() == "json" then
					local std_json = nativeExternalNamespaces["std"]["json"]
					return std_json.deserialize(data, false)
				elseif format:lower() == "toml" then
					local batteries_toml = nativeExternalNamespaces["batteries"]["toml"]
					return batteries_toml.deserialize(data, false)
				else
					return ""
				end
			end,
			encode = function(_, format: string, data: { string }): string | { [string]: any }
				if format:lower() == "json" then
					local std_json = nativeExternalNamespaces["std"]["json"]
					return std_json.serialize(data, false)
				elseif format:lower() == "toml" then
					local batteries_toml = nativeExternalNamespaces["batteries"]["toml"]
					return batteries_toml.serialize(data, false)
				else
					return ""
				end
			end,
		},
	},
	zune = {
		fs = {
			copy = function(curLib: { [string]: (...any) -> any }, source: string, destination: string, overwrite: boolean)
				curLib["copy"](source, destination, overwrite)
			end,
			move = function(curLib: { [string]: (...any) -> any }, source: string, destination: string, overwrite: boolean)
				curLib["move"](source, destination, overwrite)
			end,
			writeDir = function(curLib: { [string]: (...any) -> any }, path: string)
				curLib["makeDir"](path)
			end,
			readDir = function(curLib: { [string]: (...any) -> any }, path: string)
				local result = curLib["entries"](path)
				local luneResult = {}
				for _, luteDir: { name: string } in result do
					luneResult[#luneResult + 1] = luteDir.name
				end
				return luneResult
			end,
			writeFile = function(curLib: { [string]: (...any) -> any }, path: string, content: string)
				curLib["writeFileSync"](path, content)
			end,
			readFile = function(curLib: { [string]: (...any) -> any }, path: string)
				local content = curLib["readFile"](path, false)
				return content
			end,
			isDir = function(curLib: { [string]: (...any) -> any }, path: string)
				local parent = path
				local fileStats = curLib["stat"](parent) :: { kind: string }
				return fileStats.kind == "directory"
			end,
			isFile = function(curLib: { [string]: (...any) -> any }, path: string)
				local parent = path
				local fileStats = curLib["stat"](parent) :: { kind: string }
				return fileStats.kind == "file"
			end,
		},
		serde = {
			decode = function(curLib: { [string]: any }, format: string, data: string)
				local decoder_Format = curLib[format] :: { decode: (string) -> any }
				if decoder_Format then
					return decoder_Format["decode"](data)
				else
					error(`[LuneTransulator][Zune]: unknown 'serde' decode format: {format}`)
				end
			end,
			encode = function(curLib: { [string]: any }, format: string, data: string)
				local encoder_Format = curLib[format] :: { encode: (string) -> any }
				if encoder_Format then
					return encoder_Format["encode"](data)
				else
					error(`[LuneTransulator][Zune]: unknown 'serde' encode format: {format}`)
				end
			end,
		},
	},
	Roblox = {
		fs = {},
	},
} :: { [string]: { [string]: any } }

-- [ Runtime ]
local runtime = LRT_Detector.getRuntime()
local externalNamespaces = {
	lute = {
		_NonLuneFilePath = true,
		std = {
			"json",
		},
		batteries = {
			"toml",
		},
	},
	zune = {
		_NonLuneFilePath = true,
	},
}

-- [ Internal ]
local isInit = false

-- [ Settings ]
local MERGE_SYS_PROCESS_IN_LUTE = true

local System = {
	cwd = "",
	os = "",
}

-- Functions
--[[
    Generates the runtime library for the given library name.

    Returns the library table.
]]
local GenerateRuntimeLibray = function(libName: string)
	local libPath = `@{runtime}/{libName:lower()}`
	local isRequired, lib = pcall(function()
		return require(libPath :: string) :: { [string]: (...any) -> any }
	end)
	if not isRequired or (MERGE_SYS_PROCESS_IN_LUTE and libName == "system") then
		return
	end

	local libFunctions = table.clone(lib)
	if MERGE_SYS_PROCESS_IN_LUTE and libName == "process" and LRT_Detector.getRuntime() == "lute" then
		local luteSys_Path = "@lute/system"
		local sysTarget = require(luteSys_Path :: string) :: { [string]: (...any) -> any }
		for funcName, func: (...any) -> () in sysTarget do
			libFunctions[funcName] = func :: any
		end
	end
	nativeLibs[libName] = libFunctions
end

--[[
    Generates the runtime library for the external namespace libraries.

    Returns the library table.
]]
local GenerateRuntimeExternalLibray = function()
	if not externalNamespaces[runtime] then
		return
	end
	for namespace, libs in externalNamespaces[runtime] do
		if namespace == "_NonLuneFilePath" then
			namespace = nil :: any
			continue
		end
		Debugger.Warn(`Loading External namespace: {namespace}`)
		nativeExternalNamespaces[namespace] = {}
		for _, libName: string in libs do
			nativeExternalNamespaces[namespace][libName] = require(`@{namespace}/{libName}`) :: any
		end
	end
end

--[[
    Normalize system data.
]]
local normalizeSystemData = function()
	if System.os:find("win") then
		System.os = "windows"
	elseif System.os:find("mac") or System.os:find("darwin") then
		System.os = "macos"
	elseif System.os:find("linux") or System.os:find("arch") then
		System.os = "linux"
	end
end

--[[
    Returns the result of the lib function call.

    - Designed to return the result of the Properties in Lune / Lute Libraries
    - **Use at YOUR OWN risk!**
]]
local doLibraryCall = function(libName: string, funcName: string, ...): any
	local lib = nativeLibs[libName]
	if not lib then
		Debugger.Warn(`Unable to find Library: '{libName}'`)
		Debugger.Warn("XuauVirtualOS Does not exist yet.")
		return
	end
	local target = lib[funcName] :: (...any) -> any
	if not target then
		Debugger.Warn(`Unable to find Function | Property {funcName} in Library {libName}`)
		return
	end
	if typeof(target) == "function" then
		return target(...)
	else
		return target :: any
	end
end

--[[
    Returns the result of the lib function call from Lune, with support for Lute eqivalents
]]
local luneLib_CallFunc = function(libName: string, funcName: string, ...)
	-- Variables
	local args = { ... }
	local lib = nativeLibs[libName] :: { [string]: (...any) -> any }
	if LRT_Detector.isLune() then
		return lib[funcName](unpack(args))
	elseif LRT_Detector.getRuntime() ~= "luau" then
		local func = nativeLuneLibraryLink[runtime][libName][funcName] :: (...any) -> any
		if typeof(func) == "string" and func == "$luneMapped_global" then
			return registeredGlobals[runtime][libName][funcName](unpack(args))
		end
		if not func then
			Debugger.Warn(`'{runtime}' is missing '{funcName}' in Library '{libName}'!`)
			return
		end
		return func(lib, unpack(args))
	else
		Debugger.Warn("Unsupported runtime for now!")
		return
	end
end

-- Module
local LuneTransulator = {}

--[[
    Scrapes the native libraries for the current runtime.
]]
LuneTransulator.loadRuntimeLibraries = function()
	-- Zune detection
	if next(zuneGlobal :: { any }) ~= nil then
		for libName, lib in zuneGlobal :: { [string]: any } do
			nativeLibs[libName] = lib
		end
		return
	end
	if next(nativeLibs :: { [string]: any }) then
		return
	end
	for _, LibName in libraries do
		GenerateRuntimeLibray(LibName)
	end
	GenerateRuntimeExternalLibray()
end

--[[
    Returns the native libraries for the current runtime.
]]
LuneTransulator.getNativeLibs = function()
	return nativeLibs
end

--[[
    Initializes the LRT Library Map.
]]
LuneTransulator.init = function()
	if isInit then
		return
	end
	if not next(nativeLibs :: { [string]: any }) then
		if LRT_Detector.isZune() then
			zuneGlobal = getfenv()["zune"]
			registeredGlobals["zune"] = zuneGlobal
		end
		LuneTransulator.loadRuntimeLibraries()
	end

	-- Libraries
	System.cwd = doLibraryCall("process", "cwd")
	if externalNamespaces[runtime] and externalNamespaces[runtime]["_NonLuneFilePath"] then
		System.cwd = System.cwd .. "\\"
	end
	System.os = string.lower(doLibraryCall("process", "os") :: string or "XuauVirualOS") :: string

	-- Normalization for Lute and Lune data
	normalizeSystemData()

	-- Init Process
	isInit = true
end

--[[
    Forces the runtime to be used.
]]
LuneTransulator.ForceRuntime = function(newRuntime: string)
	if runtime == newRuntime then
		return
	end
	isInit = false
	runtime = newRuntime
	print(`[!][LuneTransulator][Warning] - Forcing the runtime can cause Xuau to be unstable.`)
	print(`[!][LuneTransulator] - Runtime was forced to {runtime} reloading...`)
	table.clear(nativeLibs)
	table.clear(nativeExternalNamespaces)
	print(`[!][LuneTransulator] - Clean up completed...`)
	LuneTransulator.init()
end

--[[
    Gets the file system function.
]]
LuneTransulator.getFileSystem = function()
	return {
		-- Directory
		readDir = function(path: string): { string }
			return luneLib_CallFunc("fs", "readDir", path) :: any
		end,
		writeDir = function(path: string)
			return luneLib_CallFunc("fs", "writeDir", path)
		end,
		-- File write / read
		writeFile = function(path: string, content: string)
			return luneLib_CallFunc("fs", "writeFile", path, content)
		end,
		readFile = function(path: string): string
			return luneLib_CallFunc("fs", "readFile", path) :: any
		end,
		-- isDir / isFile
		isDir = function(path: string): boolean
			return luneLib_CallFunc("fs", "isDir", path) :: any
		end,
		isFile = function(path: string): boolean
			return luneLib_CallFunc("fs", "isFile", path) :: any
		end,
		-- File system
		copy = function(source: string, destination: string, overwrite: boolean)
			return luneLib_CallFunc("fs", "copy", source, destination, overwrite)
		end,
		move = function(source: string, destination: string, overwrite: boolean)
			return luneLib_CallFunc("fs", "move", source, destination, overwrite)
		end,
		removeFile = function(path: string)
			return luneLib_CallFunc("fs", "removeFile", path)
		end,
		removeDir = function(path: string)
			return luneLib_CallFunc("fs", "removeDir", path)
		end,
	}
end

--[[
    Gets the file system function.
]]
LuneTransulator.getSerde = function()
	return {
		--
		--[[
		    Decodes a Json string into a Luau table.

            - Due to compatibility issues, only Json decode formatting works on Lute.
            - Toml only works when you configure lute's "batteries" dependencies.
            - Yaml, and Xml are not supported on Lute as of now, Until I create a workaround, or Lute gets updated.
		]]
		decode = function(format: string, encoded: string): { string }
			return luneLib_CallFunc("serde", "decode", format, encoded) :: any
		end,
		--[[
		    Encodes Luau tables to Json strings.

            - Due to compatibility issues, only Json encode formatting works on Lute.
            - Toml only works when you configure lute's "batteries" dependencies.
            - Yaml, and Xml are not supported on Lute as of now, Until I create a workaround, or Lute gets updated.
		]]
		encode = function(format: string, data: { string }): string
			return luneLib_CallFunc("serde", "encode", format, data) :: any
		end,
		compress = function(format: string, data: { string }): string
			return luneLib_CallFunc("serde", "compress", format, data) :: any
		end,
		decompress = function(format: string, data: string): { string }
			return luneLib_CallFunc("serde", "decompress", format, data) :: any
		end,
		hash = function(data: string): string
			return luneLib_CallFunc("serde", "hash", data) :: any
		end,
		hmac = function(data: string, key: string): string
			return luneLib_CallFunc("serde", "hmac", data, key) :: any
		end,
	}
end

--[[
    Gets the Process system functions
]]
LuneTransulator.getProcess = function()
	return {
		cwd = function(): string
			return System.cwd
		end,
	}
end

return LuneTransulator
