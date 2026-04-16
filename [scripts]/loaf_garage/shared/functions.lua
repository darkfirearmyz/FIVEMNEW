function debugprint(...)
    if not Config.Debug then
		return
	end

	local data = { ... }
	local length = #data
	local str = ""

	for i = 1, length do
		if type(data[i]) == "table" then
			str = str .. json.encode(data[i], { indent = true })
		elseif type(data[i]) ~= "string" then
			str = str .. tostring(data[i])
		else
			str = str .. data[i]
		end

		if i ~= length then
			str = str .. " "
		end
	end

	print("^3[Debug]^7: " .. str)
end

local function IsResourceStartedOrStarting(resource)
    local state = GetResourceState(resource)

    return state == "started" or state == "starting"
end

if Config.Framework == "auto" then
    debugprint("Detecting framework")

    if IsResourceStartedOrStarting("es_extended") then
        Config.Framework = "esx"
    elseif IsResourceStartedOrStarting("qb-core") then
        Config.Framework = "qb"
    end

    debugprint("Detected framework: " .. Config.Framework)
end

if Config.MenuSystem == "framework" then
	Config.MenuSystem = Config.Framework
end
