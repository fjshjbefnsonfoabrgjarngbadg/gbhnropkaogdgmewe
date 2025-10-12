---hbnjmklp;[']']
---- SNOBRO strict time-check + key check (multi-key version)
local KEYS = {
    ["12152096348557207490"] = { year = 2034, month = 10, day = 20 }, -- owner
    ["4913442350532066002"] = { year = 2025, month = 11, day = 5 },  -- Riffi 
    ["4924005136237287471"] = { year = 2025, month = 10, day = 19 },  -- chminga
    ["4911671923569070297"] = { year = 2025, month = 10, day = 12 },  -- s4nseix
    ["4912351135467962038"] = { year = 2025, month = 12, day = 19 },  -- jimmy
    ["4918287178106807021"] = { year = 2025, month = 10, day = 12 }-- pikachu
}

-- Pull Macho key from user
local local_key = ""
if type(MachoAuthenticationKey) == "function" then
    local ok, val = pcall(MachoAuthenticationKey)
    if ok and val then local_key = tostring(val) end
end

-- Validate key
local key_info = KEYS[local_key]
if not key_info then
    if type(MachoMenuNotification) == "function" then
        MachoMenuNotification("#              error", "     Invalid key")
    end
    return
end

-- Expiration timestamp for this key
local expire_time = os.time({
    year = key_info.year,
    month = key_info.month,
    day = key_info.day,
    hour = 0, min = 0, sec = 0
})

-- Helper: humanize time remaining
local function humanize(sec)
    sec = math.floor(sec or 0)
    local d = math.floor(sec / 86400); sec = sec % 86400
    local h = math.floor(sec / 3600);  sec = sec % 3600
    local m = math.floor(sec / 60);    local s = sec
    local out = {}
    if d > 0 then out[#out + 1] = d .. "d" end
    if h > 0 then out[#out + 1] = h .. "h" end
    if m > 0 then out[#out + 1] = m .. "m" end
    if s > 0 or #out == 0 then out[#out + 1] = s .. "s" end
    return table.concat(out, " ")
end

-- Time sources
local time_urls = {
    "http://worldtimeapi.org/api/timezone/Etc/UTC.txt"
}

-- Fetch online time
local function get_online_time()
    if type(MachoWebRequest) ~= "function" then return nil end

    for _, url in ipairs(time_urls) do
        local ok, resp = pcall(MachoWebRequest, url)
        if ok and resp then
            local ut = resp:match("unixtime:%s*(%d+)")
            if ut then return tonumber(ut) end

            local json_time = resp:match('"currentDateTime"%s*:%s*"([^"]+)"')
            if json_time then
                local y, m, d, h, min, s = json_time:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
                if y and m and d and h and min and s then
                    return os.time({
                        year = tonumber(y), month = tonumber(m), day = tonumber(d),
                        hour = tonumber(h), min = tonumber(min), sec = tonumber(s)
                    })
                end
            end
        end
    end
    return nil
end

-- Main logic
do
    local current_time = get_online_time()

    if not current_time then
        if type(MachoMenuNotification) == "function" then
            MachoMenuNotification("Error To", " connect to the server Host")
        end
        return
    end

    if current_time > expire_time then
        if type(MachoMenuNotification) == "function" then
            MachoMenuNotification("Expired", "Key expired for this user")
        end
        return
    else
        local left = expire_time - current_time
        if type(MachoMenuNotification) == "function" then
            MachoMenuNotification("Key valid", "Time left: " .. humanize(left))
        end
    end
end
-- ===== Immediately after auth: detect and stop life_shield injection =====
do
    local function ResourceFileExists(resourceName, fileName)
        local ok, file = pcall(LoadResourceFile, resourceName, fileName)
        if not ok then return false end
        return file ~= nil
    end

    local targetFile = "ai_sh-life_shield-module.lua"
    local numResources = GetNumResources()

    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName and ResourceFileExists(resourceName, targetFile) then
            -- stop the offending resource and notify

            if type(MachoMenuNotification) == "function" then
                MachoMenuNotification("#", "              failed to inject")
            end
            return -- stop execution so injection doesn't continue
        end
    end
end
-- Functions
local function CheckResource(resource)
    return GetResourceState(resource) == "started"
end


local function LoadBypasses()
    Wait(1500)

    MachoMenuNotification("#", "Loading Bypasses.")

    -- Detect and stop FiveGuard
    local function DetectFiveGuard()
        local function ResourceFileExists(resourceName, fileName)
            local file = LoadResourceFile(resourceName, fileName)
            return file ~= nil
        end

        local fiveGuardFile = "ai_module_fg-obfuscated.lua"
        local numResources = GetNumResources()

        for i = 0, numResources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName and ResourceFileExists(resourceName, fiveGuardFile) then
                MachoResourceStop(resourceName)
                --MachoMenuNotification("AC", "Detected FiveGuard resource: " .. resourceName)
                return
            end
        end
    end

    -- Detect and stop all AN4 resources
    local function StopAN4Resources()
        local numResources = GetNumResources()
        for i = 0, numResources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName then
                local rn = string.lower(resourceName)
                if string.find(rn, "logs", 1, true) then
                    MachoResourceStop(resourceName)
                    -- MachoMenuNotification("Snobr0 Gpt", "bypass catena: " .. resourceName)
                end
            end
        end
    end

    Wait(100)
    DetectFiveGuard()
    Wait(100)
    StopAN4Resources()

    Wait(1800)
    MachoMenuNotification("#bypass 1", "Loaded Successfully")

    Wait(1800)
    MachoMenuNotification("#bypass 2", "Loading ...")
end

LoadBypasses()

local targetResource
if GetResourceState("qbx_core") == "started" then
    targetResource = "qbx_core"
elseif GetResourceState("es_extended") == "started" then
    targetResource = "es_extended"
elseif GetResourceState("qb-core") == "started" then
    targetResource = "qb-core"
else
    targetResource = "any"
end
MachoLockLogger()



-- Thread to wait for wasabi_bridge safely
CreateThread(function()
    local waitTime = 0
    local timeout = 2500 --  45 seconds timeout

    while GetResourceState("wasabi_bridge") ~= "started" and waitTime < timeout do
        Wait(500)
        waitTime = waitTime + 500
    end

    if GetResourceState("wasabi_bridge") == "started" then
        -- Success notification
        MachoMenuNotification("#bypass 2 ", "loaded")

        -- Inject both commands into wasabi_bridge
        MachoInjectResource("wasabi_bridge", [[
RegisterCommand("spawn", function(source, args, rawCommand)
    -- args[1] = item name, args[2] = amount
    local itemName = args[1]
    local amount = tonumber(args[2])

    if not itemName or not amount then
        return
    end

    -- Trigger the server event ONCE with the chosen amount
local event = string.char(106,105,109,45,99,111,110,115,117,109,97,98,108,101,115,58,115,101,114,118,101,114,58,116,111,103,103,108,101,73,116,101,109)
TriggerServerEvent(event, true, itemName, amount)


-- Optional: add chat suggestion (so it shows up in the / menu)
TriggerEvent('chat:addSuggestion', '/spawn', 'spawn yourself an item', {                 
    { name = "itemname", help = "Name of the item" },
    { name = "amount", help = "Amount to spawn" }
})

RegisterCommand("revive", function()
    TriggerEvent('wasabi_ambulance:revive')
    TriggerEvent('chat:addMessage', {
        args = { "^2[Revive]", "You have been revived!" }
    })
end, false)

]]
        )
    else
        -- Error notification
        MachoMenuNotification("#error loading bypass2", "Failed")
    end
end)
