--!native
--!optimize 2
--!strict
--# selene :allow(incorrect_standard_library_use)

-- Buffer operations
local Writes = {}
local Reads = {}

-- [ Operations ][ Write ]
-- [ Unsigned 8 ]
Writes.U8 = function(b: buffer, offset: number, value: number)
	buffer.writeu8(b, offset, value)
	return offset + 1
end

Writes.U16 = function(b: buffer, offset: number, value: number)
	buffer.writeu16(b, offset, value)
	return offset + 2
end

Writes.U24 = function(b: buffer, offset: number, value: number)
	buffer.writebits(b, offset * 8, 24, value)
	return offset + 3
end

Writes.U32 = function(b: buffer, offset: number, value: number)
	buffer.writeu32(b, offset, value)
	return offset + 4
end

-- [ Signed 8 ]
Writes.S8 = function(b: buffer, offset: number, value: number)
	buffer.writei8(b, offset, value)
	return offset + 1
end

Writes.S16 = function(b: buffer, offset: number, value: number)
	buffer.writei16(b, offset, value)
	return offset + 2
end

Writes.S24 = function(b: buffer, offset: number, value: number)
	buffer.writebits(b, offset * 8, 24, value + 8388608)
	return offset + 3
end

Writes.S32 = function(b: buffer, offset: number, value: number)
	buffer.writei32(b, offset, value)
	return offset + 4
end

-- [ Float ]
Writes.F16 = function(b: buffer, offset: number, value: number)
	local bitOffset = offset * 8
	if value == 0 then
		buffer.writebits(b, bitOffset, 16, 0b0_00000_0000000000)
	elseif value >= 65520 then
		buffer.writebits(b, bitOffset, 16, 0b0_11111_0000000000)
	elseif value <= -65520 then
		buffer.writebits(b, bitOffset, 16, 0b1_11111_0000000000)
	elseif value ~= value then
		buffer.writebits(b, bitOffset, 16, 0b0_11111_0000000001)
	else
		local sign = 0
		if value < 0 then
			sign = 1
			value = -value
		end
		local mantissa, exponent = math.frexp(value)
		buffer.writebits(b, bitOffset + 0, 10, mantissa * 2048 - 1023.5)
		buffer.writebits(b, bitOffset + 10, 5, exponent + 14)
		buffer.writebits(b, bitOffset + 15, 1, sign)
	end
	return offset + 2
end

Writes.F24 = function(b: buffer, offset: number, value: number)
	local bitOffset = offset * 8
	if value == 0 then
		buffer.writebits(b, bitOffset, 24, 0b0_000000_00000000000000000)
	elseif value >= 4294959104 then
		buffer.writebits(b, bitOffset, 24, 0b0_111111_00000000000000000)
	elseif value <= -4294959104 then
		buffer.writebits(b, bitOffset, 24, 0b1_111111_00000000000000000)
	elseif value ~= value then
		buffer.writebits(b, bitOffset, 24, 0b0_111111_00000000000000001)
	else
		local sign = 0
		if value < 0 then
			sign = 1
			value = -value
		end
		local mantissa, exponent = math.frexp(value)
		buffer.writebits(b, bitOffset + 0, 17, mantissa * 262144 - 131071.5)
		buffer.writebits(b, bitOffset + 17, 6, exponent + 30)
		buffer.writebits(b, bitOffset + 23, 1, sign)
	end
	return offset + 3
end

Writes.F32 = function(b: buffer, offset: number, value: number)
	buffer.writef32(b, offset, value)
	return offset + 4
end

Writes.F64 = function(b: buffer, offset: number, value: number)
	buffer.writef64(b, offset, value)
	return offset + 8
end

-- [ Operations ][ Read ]
-- [ Unsigned 8 ]
Reads.U8 = function(b: buffer, offset: number)
	return buffer.readu8(b, offset), offset + 1
end

Reads.U16 = function(b: buffer, offset: number)
	return buffer.readu16(b, offset), offset + 2
end

Reads.U24 = function(b: buffer, offset: number)
	return buffer.readbits(b, offset * 8, 24), offset + 3
end

Reads.U32 = function(b: buffer, offset: number)
	return buffer.readu32(b, offset), offset + 4
end

-- [ Signed 8 ]
Reads.S8 = function(b: buffer, offset: number)
	return buffer.readi8(b, offset), offset + 1
end

Reads.S16 = function(b: buffer, offset: number)
	return buffer.readi16(b, offset), offset + 2
end

Reads.S24 = function(b: buffer, offset: number)
	return buffer.readbits(b, offset * 8, 24), offset + 3
end

Reads.S32 = function(b: buffer, offset: number)
	return buffer.readi32(b, offset), offset + 4
end

-- [ Float ]
Reads.F16 = function(b: buffer, offset: number)
	local bitOffset = offset * 8
	local mantissa = buffer.readbits(b, bitOffset + 0, 10)
	local exponent = buffer.readbits(b, bitOffset + 10, 5)
	local sign = buffer.readbits(b, bitOffset + 15, 1)
	if mantissa == 0b0000000000 then
		if exponent == 0b00000 then
			return 0, offset + 2
		end
		if exponent == 0b11111 then
			return if sign == 0 then math.huge else -math.huge, offset + 2
		end
	elseif exponent == 0b11111 then
		return 0 / 0, offset + 2
	end
	if sign == 0 then
		return (mantissa / 1024 + 1) * 2 ^ (exponent - 15), offset + 2
	else
		return -(mantissa / 1024 + 1) * 2 ^ (exponent - 15), offset + 2
	end
end

Reads.F24 = function(b: buffer, offset: number)
	local bitOffset = offset * 8
	local mantissa = buffer.readbits(b, bitOffset + 0, 17)
	local exponent = buffer.readbits(b, bitOffset + 17, 6)
	local sign = buffer.readbits(b, bitOffset + 23, 1)
	if mantissa == 0b00000000000000000 then
		if exponent == 0b000000 then
			return 0, offset + 3
		end
		if exponent == 0b111111 then
			return if sign == 0 then math.huge else -math.huge, offset + 3
		end
	elseif exponent == 0b111111 then
		return 0 / 0, offset + 3
	end
	if sign == 0 then
		return (mantissa / 131072 + 1) * 2 ^ (exponent - 31), offset + 3
	else
		return -(mantissa / 131072 + 1) * 2 ^ (exponent - 31), offset + 3
	end
end

Reads.F32 = function(b: buffer, offset: number)
	return buffer.readf32(b, offset), offset + 4
end

Reads.F64 = function(b: buffer, offset: number)
	return buffer.readf64(b, offset), offset + 8
end

-- [ Buffer Engine ]
local BufferEngine = {}
BufferEngine._Buffers = {} :: { { b: buffer, R: number, W: number } }

-- Read and write operations
BufferEngine._R = Reads
BufferEngine._W = Writes

BufferEngine.new = function(Size: number | buffer)
	if typeof(Size) == "buffer" then
		table.insert(BufferEngine._Buffers, { b = Size, R = 0, W = 0 })
		return #BufferEngine._Buffers
	end
	table.insert(BufferEngine._Buffers, { b = buffer.create(Size), R = 0, W = 0 })
	return #BufferEngine._Buffers
end

BufferEngine.destroy = function(bufferId: number) -- fix ts later
	if BufferEngine._Buffers[bufferId] then
		BufferEngine._Buffers[bufferId] = nil
	else
		warn(`[{script.Name}] - Cannot find buffer with Id: {bufferId}!`)
	end
end

BufferEngine.WriteString = function(bufferId: number, text: string)
	local object = BufferEngine._Buffers[bufferId]
	local b = object.b
	local W = object.W

	buffer.writestring(b, W, text)
	object.W += string.len(text)
end

BufferEngine.ReadString = function(bufferId: number, Count: number)
	local object = BufferEngine._Buffers[bufferId]
	local b = object.b
	local R = object.R

	local text = buffer.readstring(b, R, Count)
	object.R += string.len(text)
	return text
end

BufferEngine.Write = function(bufferId: number, operation: string, value: number)
	local object = BufferEngine._Buffers[bufferId]
	local b = object.b
	local W = object.W

	if Writes[operation] then
		object.W += Writes[operation](b, W, value) :: number
	else
		warn(`[{script.Name}] - Operation: {operation} not found!`)
	end
end

BufferEngine.Read = function(bufferId: number, operation: string)
	local object = BufferEngine._Buffers[bufferId]
	local b = object.b
	local R = object.R

	if Reads[operation] then
		local v, rOffset: number = Reads[operation](b, R)
		object.R += rOffset
		return v
	else
		warn(`[{script.Name}] - Operation: {operation} not found!`)
	end
	return 0
end

return BufferEngine
-- a bit of reworking is need with how fuctions work