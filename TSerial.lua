--- TSerial v1.3, a simple table serializer which turns tables into Lua script
-- @author Taehl (SelfMadeSpirit@gmail.com)
TSerial = {}

--- Serializes a table into a string, in form of Lua script.
-- @param t table to be serialized (may not contain any circular reference)
-- @param drop if true, unserializable types will be silently dropped instead of raising errors
-- if drop is a function, it will be called to serialize unsupported types
-- @param indent if true, output "human readable" mode with newlines and indentation (for debug)
-- @return string recreating given table
function TSerial.pack(t, drop, indent)
	assert(type(t) == "table", "Can only TSerial.pack tables.")
	local s, indent = "{"..(indent and "\n" or ""), indent and math.max(type(indent)=="number" and indent or 0,0)
	for k, v in pairs(t) do
		local tk, tv, skip = type(k), type(v)
		if tk == "boolean" then k = k and "[true]" or "[false]"
		elseif tk == "string" then if string.format("%q",k) ~= '"'..k..'"' then k = '['..string.format("%q",k)..']' end
		elseif tk == "number" then k = "["..k.."]"
		elseif tk == "table" then k = "["..TSerial.pack(k, drop, indent and indent+1).."]"
		elseif type(drop) == "function" then k = "["..string.format("%q",drop(k)).."]"
		elseif drop then skip = true
		else error("Attempted to TSerial.pack a table with an invalid key: "..tostring(k))
		end
		if tv == "boolean" then v = v and "true" or "false"
		elseif tv == "string" then v = string.format("%q", v)
		elseif tv == "number" then	-- no change needed
		elseif tv == "table" then v = TSerial.pack(v, drop, indent and indent+1)
		elseif type(drop) == "function" then v = "["..string.format("%q",drop(v)).."]"
		elseif drop then skip = true
		else error("Attempted to TSerial.pack a table with an invalid value: "..tostring(v))
		end
		if not skip then s = s..string.rep("\t",indent or 0)..k.."="..v..","..(indent and "\n" or "") end
	end
	return s..string.rep("\t",(indent or 1)-1).."}"
end

--- Loads a table into memory from a string (like those output by Tserial.pack)
-- @param s a string of Lua defining a table, such as "{2,4,8,ex="ample"}"
-- @return a table recreated from the given string
function TSerial.unpack(s)
	assert(type(s) == "string", "Can only TSerial.unpack strings.")
	assert(loadstring("TSerial.table="..s))()
	local t = TSerial.table
	TSerial.table = nil
	return t
end