#! /usr/local/bin/lua
local io=require "io"
local os=require "os"
local string=require "string"

if (#arg ~= 2) then 
	print("wrong number of argument:"..#arg.." needs 2")
	print("example: ./json_encode ./source_file.json ./encoded_file.json")
	os.exit()
end


local file = io.open(arg[1], "r")
local str = file:read("*a")
file:close()

local i,j= str:find("/%*%%%d*%w*%*/") 
if (i and j) then
	--(str:sub(i,j):find("%w*%d"))
end

function findByEnclosure(str,l,r)
	local i,j = str:find(l..".-"..r)
	if i and j then
		local substr = str:sub(i,j)
		local m,n = substr:find(l)
		local o,p = substr:find(r)
		local substr = substr:sub(n+1,o-1)
		local r,s = substr:find("%w.*%w")
		local substr = substr:sub(r,s)
		return i,j,substr
	end
	return nil
end

function checkBalance(str,ll,lr, rl,rr)
	local balance = 0
	local case = 0
	local locStr = str	
	while (true) do
		local i,j,pattern= findByEnclosure(locStr,ll,lr)
		if i and j then
			balance = balance + 1
			local k,l = locStr:find(rl..pattern..rr)
			if k and l then
				balance = balance - 1
				locStr=locStr:sub(l)
				case = case + 1
			else
				print("file not balanced,expecting "..pattern)
				break
			end
		else
			break
		end
	end
	if (balance==0 and case>0) then
		return true
	else
		if (case==0) then
			print("no data found")
		end
		return false
	end
end

function extractContent(str,ll,lr,rl,rr)
	local i,j,pattern= findByEnclosure(str,ll,lr)
	if i and j then
		local k,l=str:find(rl..pattern..rr)	
		local subStr = str:sub(j+1, k-1)
		local m,n = subStr:find("%S.*%S")
		local content = subStr:sub(m,n)
		return pattern, content, l+1
	else
		return nil
	end
end

function stripEnclosure(str, l, r)
	local i,j,enclosure = str:find(l..".-"..r)
	local rtn = str	
	if i and j then
		local comment = rtn:sub(i,j)
		--print(comment)
		comment = comment:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?%)]","%%%1")
		rtn = rtn:gsub(comment, "")
	else 
		--print('nothing')
	end	

	return rtn
end

function stripAllEnclosure(str, l, r)
	local localStr = str
	local tempStr	= str

	localStr = stripEnclosure(localStr, l, r)
	
	while (localStr ~= tempStr) do
		localStr = tempStr
		tempStr = stripEnclosure(tempStr, l, r)
	end
	return localStr
end

local ll = "/%*%%"
local lr = "%*/"
local rl = "/%*"
local rr = "%%%*/"

res = checkBalance(str, ll, lr, rl, rr)
if res==false then
	os.exit()
end

local outString="{"
while(true) do 
	local key,value,pointer = extractContent(str, ll, lr, rl, rr)

	value = stripAllEnclosure(value,"/%*","%*/")
	value = stripAllEnclosure(value,"//","\n")
	--print(value)
	if (pointer) then	
		valueProcessed = value:gsub("[\"\\]", "\\%1")
		valueProcessed = valueProcessed:gsub("[\n\t]", "")
		outString = outString.."\""..key.."\":\""..valueProcessed.."\""
		--outString = valueProcessed
		str = str:sub(pointer) 
		local x = str:find(ll)
		if x then
			outString=outString..","
		else
			outString=outString.."}"
			break
		end
	end
end

local file = io.open(arg[2], "w")
file:write(outString)
file:close()
