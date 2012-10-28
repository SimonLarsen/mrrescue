-- XML parser from http://lua-users.org/wiki/LuaXml

local escaped = {
  ['&quot;'] = '"',
  ['&amp;'] = '&',
  ['&apos;'] = "'",
  ['&lt;'] = '<',
  ['&gt;'] = '>'
}

local xml = {}

---------------------------------------------------------------------------------------------------
local function args_to_table(s)
  local arg = {}
  string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
    for f, t in pairs(escaped) do
      a = string.gsub(a, f, t)
    end
    arg[w] = a
  end)
  return arg
end
    
---------------------------------------------------------------------------------------------------
function xml.string_to_table(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=args_to_table(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=args_to_table(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[#stack].label)
  end
  return stack[1]
end

---------------------------------------------------------------------------------------------------
local function args_to_string(args)
    if not args then return "" end
    local str = ""
    for k,v in pairs(args) do
        str = str .. string.format(' %s="%s"', k, tostring(v))
    end
    return str
end

---------------------------------------------------------------------------------------------------
local function expand(t, indent)
    indent = indent .. "    "
    local str = {}
    for i = 1,#t do
        if type(t[i]) == "table" then
            str[#str+1] = xml.table_to_string(t[i], indent)
        else
            str[#str+1] = indent
            str[#str+1] = t[i]
            str[#str+1] = "\n"
        end
    end
    return str
end

---------------------------------------------------------------------------------------------------
local function flatten (t)
  local n = { }
  local function flatten_aux(t)
    for k, v in ipairs(t) do
      if type(v) == "table" then
        flatten_aux(v)
      else
        n[#n+1] = v
      end
    end
  end
  flatten_aux(t)
  return n
end

---------------------------------------------------------------------------------------------------
function xml.table_to_string(t, indent)
    if not indent then indent = "" end
    local label = t.label
    local xarg = args_to_string(t.xarg)
    local str = {}
    if #t > 0 then
        local body = expand(t,indent)
        str = {indent, "<", label, xarg, ">\n", body, indent, "</", label, ">\n"}
    else
        str = {indent, "<", label, xarg, "/>\n"}
    end
    if indent == "" then
        return table.concat(flatten(str))
    else
        return str
    end
end

return xml

