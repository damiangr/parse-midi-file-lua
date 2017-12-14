
module(...,package.seeall)

local maxDefault = 10
local gap = "\t"

function typeof(var)
	local _type = type(var);
	if(_type ~= "table" and _type ~= "userdata") then
		return _type;
	end
	local _meta = getmetatable(var);
	if(_meta ~= nil and _meta._NAME ~= nil) then
		return _meta._NAME;
	else
		return _type;
	end
end

function tableToString(tableData,level,max,extra)
	local result = ""
	local margin = ""
	local level = level or 1
	local maxLevel = max or maxDefault

	local print = function(msg)
		result = result..tostring(msg).."\n"
	end
	if level> maxLevel then
		return
	end

	if level >1 then
		for i=2,level do
			margin = margin..gap
		end
	end
	if typeof(tableData) ~= "table" then
		return
	end
	if level == 1 then
		print(margin.."{")
	end
	--print(margin)
	local submargin = margin ..gap
	local indexedTable = {}
	for k,v in pairs(tableData) do
	   -- print(i)
		table.insert(indexedTable,{
			key = k,
			value = v
		})
	end
	for  i,data in ipairs(indexedTable) do
	    local k = data.key
		local v = data.value
		local key = ""
		local _last = i < #indexedTable and "," or ""
		if typeof(k) == "number" then

		else
			key = tostring(k).." = "
		end
		if typeof(v) == "table"  then
			if typeof(k)~= "number" then
				print(submargin..tostring(key).." {")
			else
				print(submargin.."{")
			end
			print(tableToString(v,level+1,maxLevel,_last))
		elseif typeof(v) == "string" then
			print(submargin..tostring(key)..'"'..tostring(v)..'"'.._last)
		else
			print(submargin..tostring(key)..tostring(v).._last)
		end
	end
	local last = margin.."}"
	if extra then
		last = last..extra
	end
	print(last)
	return result
end

function printTable(table,level,max)
	_G.print(tableToString(table,level,max))
end

function ensureFolderExists(dirPath)
	local path = system.pathForFile( dirPath, system.DocumentsDirectory)
	lfs.chdir(system.pathForFile("",system.DocumentsDirectory))
	local existed
	if path then 
		local attributes = lfs.attributes(dirPath)
		if attributes and attributes.mode == "directory" then 
			existed = true
		end
	end
	if not existed then 
		lfs.mkdir(dirPath)
	end
end