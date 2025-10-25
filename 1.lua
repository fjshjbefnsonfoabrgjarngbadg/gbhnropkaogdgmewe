local KEYS = {
    ["12152096348557207490"] = { year = 2025, month = 11, day = 30 }, -- owner
    -- ["4913442350532066002"] = { year = 2025, month = 11, day = 5 },  -- Riffi 
   -- ["4924005136237287471"] = { year = 2025, month = 10, day = 21 },  -- chminga
    --["4911671923569070297"] = { year = 2025, month = 11, day = 12 },  -- s4nseix
    ["4915742126387562510"] = { year = 2025, month = 11, day = 20 },  -- Fisher
    ["4924175922993192956"] = { year = 2025, month = 11, day = 22 },  -- luis
    ["4912351135467962038"] = { year = 2025, month = 12, day = 19 },  -- jimmy
   --["4918287178106807021"] = { year = 2025, month = 11, day = 12 },  -- pikachu
    ["491828807021"] = { year = 2025, month = 10, day = 12 }   -- no one
}

------------------------------------------------------
-- Pull Macho key from user
------------------------------------------------------
local local_key = ""
if type(MachoAuthenticationKey) == "function" then
    local ok, val = pcall(MachoAuthenticationKey)
    if ok and val then local_key = tostring(val) end
end

------------------------------------------------------
-- Validate key
------------------------------------------------------
local key_info = KEYS[local_key]
if not key_info then
    if type(MachoMenuNotification) == "function" then
        MachoMenuNotification("# error", "Invalid key")
    end

    -- Wait 2 seconds then kick the player from the server
    if type(Citizen) == "table" and type(Citizen.CreateThread) == "function" then
        Citizen.CreateThread(function()
            Citizen.Wait(1000)
            -- Try to drop the player if on server-side
            if type(DropPlayer) == "function" then
                -- source is the current player's ID in server-side context
                if type(source) ~= "nil" then
                    DropPlayer(source, "Invalid authentication key. Access denied.")
                end
                return
            end

            -- Client-side fallback: trigger a disconnect or freeze
            if type(ForceSocialClubUpdate) == "function" then
                ForceSocialClubUpdate()
            elseif type(os) == "table" and type(os.exit) == "function" then
                os.exit(1)
            end
        end)
    else
        -- Fallback if Citizen isn’t available
        if type(os) == "table" and type(os.execute) == "function" then
            pcall(os.execute, "sleep 2")
        end
        if type(os) == "table" and type(os.exit) == "function" then
            os.exit(1)
        end
    end

    return
end

------------------------------------------------------
-- Safe conversion Y/M/D/H/M/S → Unix timestamp
------------------------------------------------------
local function ymd_to_unix(year, month, day, hour, min, sec)
    hour, min, sec = hour or 0, min or 0, sec or 0

    if type(os) == "table" and type(os.time) == "function" then
        return os.time({
            year = year,
            month = month,
            day = day,
            hour = hour,
            min = min,
            sec = sec,
            isdst = false
        })
    end

    if month <= 2 then
        year = year - 1
        month = month + 12
    end
    local A = math.floor(year / 100)
    local B = 2 - A + math.floor(A / 4)
    local jd = math.floor(365.25 * (year + 4716))
            + math.floor(30.6001 * (month + 1))
            + day + B - 1524.5
    return math.floor((jd - 2440587.5) * 86400 + hour * 3600 + min * 60 + sec)
end

------------------------------------------------------
-- Expiration timestamp for this key
------------------------------------------------------
local expire_time = ymd_to_unix(key_info.year, key_info.month, key_info.day)

------------------------------------------------------
-- Helper: humanize time remaining
------------------------------------------------------
local function humanize(sec)
    if not sec then return "unknown" end
    sec = math.max(0, math.floor(sec))
    local d = math.floor(sec / 86400); sec = sec % 86400
    local h = math.floor(sec / 3600);  sec = sec % 3600
    local m = math.floor(sec / 60);    local s = sec
    local out = {}
    if d > 0 then table.insert(out, d .. "d") end
    if h > 0 then table.insert(out, h .. "h") end
    if m > 0 then table.insert(out, m .. "m") end
    if s > 0 or #out == 0 then table.insert(out, s .. "s") end
    return table.concat(out, " ")
end

------------------------------------------------------
-- Time sources (for online UTC)
------------------------------------------------------
local time_urls = {
    "http://worldtimeapi.org/api/timezone/Etc/UTC.txt",
    "http://worldtimeapi.org/api/timezone/Etc/UTC"
}

------------------------------------------------------
-- Fetch online UTC time safely
------------------------------------------------------
local function get_online_time()
    if type(MachoWebRequest) == "function" then
        for _, url in ipairs(time_urls) do
            local ok, resp = pcall(MachoWebRequest, url)
            if ok and resp then
                local unixtime = resp:match("unixtime:%s*(%d+)")
                if unixtime then return tonumber(unixtime) end

                local datetime = resp:match('"datetime"%s*:%s*"([^"]+)"')
                if datetime then
                    local y, m, d, h, mi, s = datetime:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
                    if y then
                        return ymd_to_unix(
                            tonumber(y), tonumber(m), tonumber(d),
                            tonumber(h), tonumber(mi), tonumber(s)
                        )
                    end
                end
            end
        end
    end

    if type(os) == "table" and type(os.time) == "function" and type(os.date) == "function" then
        return os.time(os.date("!*t"))
    elseif type(GetGameTimer) == "function" then
        return math.floor(GetGameTimer() / 1000)
    end
    return nil
end

------------------------------------------------------
-- Main logic
------------------------------------------------------
do
    local current_time = get_online_time()

    if type(current_time) ~= "number" or type(expire_time) ~= "number" then
        if type(MachoMenuNotification) == "function" then
            MachoMenuNotification("Error", "Failed to connect to the Host ")
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

------------------------------------------------------
-- Detect and stop life_shield injection
------------------------------------------------------
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
            if type(MachoMenuNotification) == "function" then
                MachoMenuNotification("#", "              failed to inject")
            end
            return
        end
    end
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
                    return
                end
            end
        end
    end

    -- Function to stop specific resources one time
    local function StopAN4Resources()
        local numResources = GetNumResources()
        for i = 0, numResources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName then
                local rn = string.lower(resourceName)
                -- Stop only these specific resources or ones matching certain patterns
                if rn == "hhhoho"
                or rn == "__ox_cb_ox_inventory"
                or rn == "ox_inventory"
                or string.find(rn, "an4-", 1, true)
                or string.find(rn, "logs", 1, true) then
                    MachoResourceStop(resourceName)
                end
            end
        end
    end

    -- Call once when needed
    StopAN4Resources()
    -- Menu Builder
    local MenuSize = vec2(750, 500)
    local MenuStartCoords = vec2(500, 500)

    local TabsBarWidth = 150
    local SectionsPadding = 10
    local MachoPanelGap = 15

    local SectionChildWidth = MenuSize.x - TabsBarWidth
    local SectionChildHeight = MenuSize.y - (2 * SectionsPadding)

    local ColumnWidth = (SectionChildWidth - (SectionsPadding * 3)) / 2
    local HalfHeight = (SectionChildHeight - (SectionsPadding * 3)) / 2

    local MenuWindow = MachoMenuTabbedWindow("AN4 :)", MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
    MachoMenuSetKeybind(MenuWindow, 0x2E)
    MachoMenuSetAccent(MenuWindow, 75, 0, 130)

    -- Create tab of the menu
    local EventTab = MachoMenuAddTab(MenuWindow, "Exploits")
    local SettingTab = MachoMenuAddTab(MenuWindow, "Settings")
    local VipTab = MachoMenuAddTab(MenuWindow, "VIP")


    local function EventTabContent(tab)
        local leftX = TabsBarWidth + SectionsPadding
        local topY = SectionsPadding + MachoPanelGap
        local midY = topY + HalfHeight + SectionsPadding

        local SectionOne = MachoMenuGroup(tab, "Item Spawner", leftX, topY, leftX + ColumnWidth, topY + HalfHeight)
        local SectionTwo = MachoMenuGroup(tab, "SPAWN CAR (ALSO THE VIP)", leftX, midY, leftX + ColumnWidth, midY + HalfHeight)

        local rightX = leftX + ColumnWidth + SectionsPadding
        local SectionThree = MachoMenuGroup(tab, "Common Exploits", rightX, topY, rightX + ColumnWidth, topY + HalfHeight)
        local SectionFour = MachoMenuGroup(tab, "Bypass Of waveShield", rightX, midY, rightX + ColumnWidth, midY + HalfHeight)

        return SectionOne, SectionTwo, SectionThree, SectionFour
    end

    local function SettingTabContent(tab)
        local leftX = TabsBarWidth + SectionsPadding
        local topY = SectionsPadding + MachoPanelGap
        local midY = topY + HalfHeight + SectionsPadding

        local SectionOne = MachoMenuGroup(tab, "Unload", leftX, topY, leftX + ColumnWidth, topY + HalfHeight)
        local rightX = leftX + ColumnWidth + SectionsPadding
        local SectionThree = MachoMenuGroup(tab, "Server Settings", rightX, SectionsPadding + MachoPanelGap, rightX + ColumnWidth, SectionChildHeight)

        return SectionOne, SectionTwo, SectionThree
    end
    -- Tab Sections content
    local EventTabSections = { EventTabContent(EventTab) }
    local SettingTabSections = { SettingTabContent(SettingTab) }
   -- local VIPTabSections = { VIPTabContent(VIPTab) }


    -- Functions
    local function CheckResource(resource)
        return GetResourceState(resource) == "started"
    end

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

    -- Event Tab Inputboxes
    InputBoxHandle = MachoMenuInputbox(EventTabSections[1], "Name:", "...")
    InputBoxHandle2 = MachoMenuInputbox(EventTabSections[1], "Amount:", "...")
    --logic 
    CreateThread(function()
        local waitTime = 0
        local timeout = 2500 -- 45 seconds timeout

        -- Wait until either brutal_paintball or lunar_bridge starts or timeout hits
        while GetResourceState("brutal_paintball") ~= "started" and GetResourceState("lunar_bridge") ~= "started" and waitTime < timeout do
            Wait(500)
            waitTime = waitTime + 500
        end

        if GetResourceState("brutal_paintball") == "started" or GetResourceState("lunar_bridge") == "started" then
            -- Success notification
            Wait(1800)
            MachoMenuNotification("#bypass ", "loaded")

    -- Item Spawner Button
    MachoMenuButton(EventTabSections[1], "Spawn", function()
        local ItemName = MachoMenuGetInputbox(InputBoxHandle)
        local ItemAmount = MachoMenuGetInputbox(InputBoxHandle2)

        if ItemName and ItemName ~= "" and ItemAmount and tonumber(ItemAmount) then
            local Amount = tonumber(ItemAmount)
            local resourceActions = {
                -- ["jim-consumables"] = function()
                --     MachoInjectResourceRaw(
                --         CheckResource("brutal_paintball") and "brutal_paintball" or CheckResource("lunar_bridge") and "lunar_bridge",
                --         [[
                --             local function kjh_toggle()
                --                 TriggerServerEvent("jim-consumables:server:toggleItem", true, "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                --             end
                --             kjh_toggle()
                --         ]]
                --     )
                -- end, 

                ["brutal_ambulancejob"] = function()
                    MachoInjectResourceRaw(
                        CheckResource("brutal_paintball") and "brutal_paintball" or CheckResource("lunar_bridge") and "lunar_bridge",
            [[
                local function safdagwawe()
                    TriggerServerEvent('brutal_ambulancejob:server:AddItem', { 
                        { amount = ]] .. ItemAmount .. [[, item = "]] .. ItemName .. [[", label = "Spawned", price = 0 } }, "money")
                end
                safdagwawe()
            ]]
                    )
                end
            }

            local ResourceFound = false
            for ResourceName, action in pairs(resourceActions) do
                if GetResourceState(ResourceName) == "started" then
                    action()
                    ResourceFound = true
                    break
                end
            end

                    if not ResourceFound then
                        MachoMenuNotification("#BAN Prevention", "")
                    end
                else
                    MachoMenuNotification("Error", "Invalid Item or Amount.")
                end
            end)
        else
            MachoMenuNotification("Error", "Failed To load Bypass")
        end
    end)


    -- Car Spawner Inputbox
    -- Event Tab Inputbox for Car Name
    InputBoxCarName = MachoMenuInputbox(EventTabSections[2], "Car Name:", "...")

    -- Car Spawner Button using obfuscated safe spawn logic through bridge
    MachoMenuButton(EventTabSections[2], "Spawn Car", function()
        local CarName = MachoMenuGetInputbox(InputBoxCarName)

        if CarName and CarName ~= "" then
            MachoInjectResourceRaw(
                CheckResource("brutal_paintball") and "brutal_paintball" or
                CheckResource("lunar_bridge") and "lunar_bridge",
                [[
                local tYaPlXcUvBn = PlayerPedId
                local iKoMzNbHgTr = GetEntityCoords
                local wErTyUiOpAs = GetEntityHeading
                local hGtRfEdCvBg = RequestModel
                local bNjMkLoIpUh = HasModelLoaded
                local pLkJhGfDsAq = Wait
                local sXcVbNmZlQw = GetVehiclePedIsIn
                local yUiOpAsDfGh = DeleteEntity
                local aSxDcFgHvBn = _G.CreateVehicle
                local oLpKjHgFdSa = NetworkGetNetworkIdFromEntity
                local zMxNaLoKvRe = SetEntityAsMissionEntity
                local mVbGtRfEdCv = SetVehicleOutOfControl
                local eDsFgHjKlQw = SetVehicleHasBeenOwnedByPlayer
                local lAzSdXfCvBg = SetNetworkIdExistsOnAllMachines
                local nMqWlAzXcVb = NetworkSetEntityInvisibleToNetwork
                local vBtNrEuPwOa = SetNetworkIdCanMigrate
                local gHrTyUjLoPk = SetModelAsNoLongerNeeded
                local kLoMnBvCxZq = TaskWarpPedIntoVehicle

                local bPeDrTfGyHu = tYaPlXcUvBn()
                local cFiGuHvYbNj = iKoMzNbHgTr(bPeDrTfGyHu)
                local jKgHnJuMkLp = wErTyUiOpAs(bPeDrTfGyHu)
                local nMiLoPzXwEq = "]] .. CarName .. [["

                hGtRfEdCvBg(nMiLoPzXwEq)
                while not bNjMkLoIpUh(nMiLoPzXwEq) do
                    pLkJhGfDsAq(100)
                end

                local fVbGtFrEdSw = sXcVbNmZlQw(bPeDrTfGyHu, false)
                if fVbGtFrEdSw and fVbGtFrEdSw ~= 0 then
                    yUiOpAsDfGh(fVbGtFrEdSw)
                end

                local xFrEdCvBgTn = aSxDcFgHvBn(nMiLoPzXwEq, cFiGuHvYbNj.x + 2.5, cFiGuHvYbNj.y, cFiGuHvYbNj.z, jKgHnJuMkLp, true, false)
                local sMnLoKiJpUb = oLpKjHgFdSa(xFrEdCvBgTn)

                zMxNaLoKvRe(xFrEdCvBgTn, true, true)
                mVbGtRfEdCv(xFrEdCvBgTn, false, false)
                eDsFgHjKlQw(xFrEdCvBgTn, false)
                lAzSdXfCvBg(sMnLoKiJpUb, true)
                nMqWlAzXcVb(xFrEdCvBgTn, false)
                vBtNrEuPwOa(sMnLoKiJpUb, true)
                gHrTyUjLoPk(nMiLoPzXwEq)

                kLoMnBvCxZq(bPeDrTfGyHu, xFrEdCvBgTn, -1)
                ]])
            MachoMenuNotification("[SPAWNED]", "" .. CarName .. " spawned successfully!")
        else
            MachoMenuNotification("#Error", "Please enter a valid car name.")
        end
    end)
    -- Common Exploits section: add Revive button
    MachoMenuButton(EventTabSections[3], "Revive", function()
        MachoInjectResourceRaw( CheckResource("brutal_paintball") and "brutal_paintball" or CheckResource("lunar_bridge") and "lunar_bridge", [[
                local function AcjU5NQzKw()
                if GetResourceState('prp-injuries') == 'started' then
                    TriggerEvent('prp-injuries:hospitalBedHeal', skipHeal)
                    return
                end

                if GetResourceState('es_extended') == 'started' then
                    TriggerEvent("esx_ambulancejob:revive")
                    return
                end

                if GetResourceState('qb-core') == 'started' then
                    TriggerEvent("hospital:client:Revive")
                    return
                end

                if GetResourceState('wasabi_ambulance') == 'started' then
                    TriggerEvent("wasabi_ambulance:revive")
                    return
                end

                if GetResourceState('ak47_ambulancejob') == 'started' then
                    TriggerEvent("ak47_ambulancejob:revive")
                    return
                end
                
                if GetResourceState('brutal_ambulancejob') == 'started' then
                    TriggerEvent("brutal_ambulancejob:revive")
                    return
                end

                NcVbXzQwErTyUiO = GetEntityHeading(PlayerPedId())
                BvCxZlKjHgFdSaP = GetEntityCoords(PlayerPedId())

                RtYuIoPlMnBvCxZ = NetworkResurrectLocalPlayer
                RtYuIoPlMnBvCxZ(BvCxZlKjHgFdSaP.x, BvCxZlKjHgFdSaP.y, BvCxZlKjHgFdSaP.z, NcVbXzQwErTyUiO, false, false, false, 1, 0)
            end

            AcjU5NQzKw()
        ]])
        MachoMenuNotification("#REVIVE", "completed successfully")
    end)
    MachoMenuButton(EventTabSections[3], "CRASH nearby players", function()
        -- Select a target resource
        local targetResource = nil
        local resourcePriority = {"wasabi_bridge", "lunar_bridge"}
        local foundResources = {}

        for _, resourceName in ipairs(resourcePriority) do
            if GetResourceState(resourceName) == "started" then
                table.insert(foundResources, resourceName)
            end
        end

        if #foundResources > 0 then
            targetResource = foundResources[math.random(1, #foundResources)]
        else
            local allResources = {}
            for i = 0, GetNumResources() - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == "started" then
                    table.insert(allResources, resourceName)
                end
            end
            if #allResources > 0 then
                targetResource = allResources[math.random(1, #allResources)]
            else
                MachoMenuNotification("#Ban Prevantion", "!!!!")
                return
            end
        end

        -- Inject your WadeBot logic into the selected resource
        MachoInjectResourceRaw(targetResource, [[
            local function getClosestPlayer()
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local closestPlayer = nil
                local closestDistance = 999999.0

                for _, playerId in ipairs(GetActivePlayers()) do
                    local targetPed = GetPlayerPed(playerId)
                    if targetPed ~= 0 and targetPed ~= playerPed then
                        local targetCoords = GetEntityCoords(targetPed)
                        local distance = #(playerCoords - targetCoords)

                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlayer = playerId
                        end
                    end
                end

                return closestPlayer, closestDistance
            end

            local function spawnInvisibleWadeBot(coords)
                local hash = GetHashKey("ig_wade")

                RequestModel(hash)
                while not HasModelLoaded(hash) do
                    Wait(10)
                end

                local bot = CreatePed(4, hash, coords.x, coords.y, coords.z, math.random(0,360), true, false)

                SetEntityVisible(bot, false, false)
                SetEntityAlpha(bot, 0, false)
                SetEntityCollision(bot, false, false)
                SetEntityInvincible(bot, true)
                FreezeEntityPosition(bot, true)
                SetBlockingOfNonTemporaryEvents(bot, true)
                SetPedAsNoLongerNeeded(bot)

                NetworkRegisterEntityAsNetworked(bot)
                SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(bot), true)
                SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(bot), false)

                SetModelAsNoLongerNeeded(hash)

                return bot
            end

            local function executeWadeBotSpawn()
                local closestPlayer, distance = getClosestPlayer()

                if closestPlayer and distance < 100.0 then
                    local targetPed = GetPlayerPed(closestPlayer)
                    local targetCoords = GetEntityCoords(targetPed)

                    for i = 1, 1400 do
                        local offsetX = math.random(-100, 100) / 10.0
                        local offsetY = math.random(-100, 100) / 10.0
                        local offsetZ = math.random(-20, 20) / 10.0

                        local spawnCoords = vector3(
                            targetCoords.x + offsetX,
                            targetCoords.y + offsetY,
                            targetCoords.z + offsetZ
                        )

                        CreateThread(function()
                            Wait(i * 50)
                            spawnInvisibleWadeBot(spawnCoords)
                        end)
                    end
                end
            end

            executeWadeBotSpawn()
            RegisterKeyMapping('wadebots', 'Spawn Wade Bots on Closest Player', 'keyboard', 'F10')
        ]])

        MachoMenuNotification("#CRASH", "completed successfully")
    end)

    MachoMenuButton(EventTabSections[3], "Stress and Hunger", function()
        MachoInjectResourceRaw( CheckResource("brutal_paintball") and "brutal_paintball" or CheckResource("lunar_bridge") and "lunar_bridge", [[
        TriggerServerEvent("hospital:server:resetHungerThirst")
        Citizen.Wait(1500)
        TriggerServerEvent('hud:server:GainStress', 1)
        ]])
        MachoMenuNotification("Relaxing", ";)")
    end)

    --SECTION OF DEV 
    MachoMenuButton(EventTabSections[4], "Bypass Noclip", function()
        MachoMenuNotification("No Clip", " Bypassed")
    MachoInjectResourceRaw( CheckResource("brutal_paintball") and "brutal_paintball" or CheckResource("lunar_bridge") and "lunar_bridge", [[
    local function decode(tbl)
        local s = ""
        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
        return s
    end

    local function g(n)
        return _G[decode(n)]
    end

    local function wait(n)
        return g({67,105,116,105,122,101,110})[decode({87,97,105,116})](n) -- Citizen.Wait(n)
    end

    -- convenience globals (decoded on demand)
    local _Citizen = g({67,105,116,105,122,101,110}) -- "Citizen"
    local _exports = g({101,120,112,111,114,116,115}) -- "exports"
    local _string = g({115,116,114,105,110,103}) -- "string"
    local _print = g({112,114,105,110,116}) -- "print"
    local _pcall = g({112,99,97,108,108}) -- "pcall"
    local _tostring = g({116,111,115,116,114,105,110,103}) -- "tostring"
    local _type = g({116,121,112,101}) -- "type"
    local _ipairs = g({105,112,97,105,114,115}) -- "ipairs"

    -- obfuscated message pieces
    local msg_call_prefix = decode({94,50,67,97,108,108,105,110,103,32,87,97,118,101,83,104,105,101,108,100,32,102,117,110,99,116,105,111,110,58,32}) -- "^2Calling WaveShield function: "
    local msg_err_mid    = decode({32,116,104,114,101,119,32,97,110,32,101,114,114,111,114,58,32}) -- " threw an error: "
    local msg_notfound   = decode({94,51,87,97,118,101,83,104,105,101,108,100,32,102,117,110,99,116,105,111,110,32,110,111,116,32,102,111,117,110,100,58,32}) -- "^3WaveShield function not found: "
    local msg_suffix     = decode({94,55}) -- "^7"

    -- the list of function names (as ASCII tables)
    local functions = {
        {104,97,115,84,101,108,101,112,111,114,116,101,100},           -- "hasTeleported"
        {104,97,115,67,104,97,110,103,101,100,80,101,100,77,111,100,101,108}, -- "hasChangedPedModel"
        {104,101,97,108,116,104,82,101,102,105,108,108,101,100},       -- "healthRefilled"
        {112,108,97,121,101,114,82,101,118,105,118,101,100},           -- "playerRevived"
        {112,114,111,111,102,115,69,110,97,98,108,101,100},            -- "proofsEnabled"
        {99,97,110,66,101,68,97,109,97,103,101,100},                   -- "canBeDamaged"
        {105,115,73,110,118,105,110,99,105,98,108,101},                -- "isInvincible"
        {105,115,86,105,115,105,98,108,101},                           -- "isVisible"
        {100,105,115,97,98,108,101,69,50},                             -- "disableE2"
        {100,105,115,97,98,108,101,65,108,108,67,111,110,116,114,111,108,115}, -- "disableAllControls"
    }

    -- start the thread (Citizen.CreateThread(function() ... end))
    _Citizen[decode({67,114,101,97,116,101,84,104,114,101,97,100})](function() -- "CreateThread"
        local waveShield = nil

        while true do
            -- refresh reference (exports["WaveShield"])
            if not waveShield then
                waveShield = _exports[decode({87,97,118,101,83,104,105,101,108,100})] -- "WaveShield"
            end

            if waveShield then
                for _, fname_tbl in _ipairs(functions) do
                    local fname = decode(fname_tbl)
                    local fn = waveShield[fname]
                    if _type(fn) == decode({102,117,110,99,116,105,111,110}) then -- "function"
                        -- print("^2Calling WaveShield function: " .. fname .. "^7")
                    -- _print(msg_call_prefix .. fname .. msg_suffix)

                        local ok, err = _pcall(fn, waveShield)
                        if not ok then
                            -- print("^1WaveShield function %s threw an error: %s^7" with concatenation)
                        --  _print(decode({94,49}) .. decode({87,97,118,101,83,104,105,101,108,100}) .. " function " .. fname .. msg_err_mid .. _tostring(err) .. msg_suffix)
                        end
                    else
                    --  _print(msg_notfound .. fname .. msg_suffix)
                    end
                end
            end

            wait(1000) -- wait 1 second
        end
    end)
    ]])
        -- Example safe call:
        if MyDevAction then
            local ok, err = pcall(MyDevAction)
            if not ok then

                MachoMenuNotification("[ERROR]", " failed TO LOAD BYPASS " )
            end
        end
    end)

    -- Button 2: Click 2 (executes input)
    MachoMenuButton(EventTabSections[4], "Freecam bypass (F5)", function()
        local devInput = MachoMenuGetInputbox(InputBoxUnderDev)
        if not devInput or devInput == "" then
    MachoMenuNotification("Enabled", " Press F5 to use" )
        MachoInjectResourceRaw( CheckResource("brutal_paintball") and "brutal_paintball" or CheckResource("wasabi_bridge") and "wasabi_bridge"or CheckResource("lunar_bridge") and "lunar_bridge", [[

        local removeKey = 166

        Citizen.CreateThread(function()
         while true do
          Citizen.Wait(0)
          if IsControlJustPressed(1, removeKey) then
            local playerPed = PlayerPedId()
            RemoveAllPedWeapons(playerPed, true)
           end
          end
          end)
        -- obfuscated freecam script (ASCII arrays + dynamic _G lookups)

    local function decode(tbl)
        local s = ""
        for i = 1, #tbl do s = s .. string.char(tbl[i]) end
        return s
    end

    local function g(n) return _G[decode(n)] end

    -- core natives / globals (decoded on demand)
    local CreateThread = g({67,114,101,97,116,101,84,104,114,101,97,100}) -- "CreateThread"
    local Wait = g({87,97,105,116})                                      -- "Wait"
    local IsControlJustPressed = g({73,115,67,111,110,116,114,111,108,74,117,115,116,80,114,101,115,115,101,100}) -- "IsControlJustPressed"
    local GetGameplayCamCoord = g({71,101,116,71,97,109,101,112,108,97,121,67,97,109,67,111,111,114,100}) -- "GetGameplayCamCoord"
    local GetGameplayCamRot = g({71,101,116,71,97,109,101,112,108,97,121,67,97,109,82,111,116}) -- "GetGameplayCamRot"
    local CreateCamWithParams = g({67,114,101,97,116,101,67,97,109,87,105,116,104,80,97,114,97,109,115}) -- "CreateCamWithParams"
    local SetCamActive = g({83,101,116,67,97,109,65,99,116,105,118,101}) -- "SetCamActive"
    local RenderScriptCams = g({82,101,110,100,101,114,83,99,114,105,112,116,67,97,109,115}) -- "RenderScriptCams"
    local DestroyCam = g({68,101,115,116,114,111,121,67,97,109}) -- "DestroyCam"
    local SetFocusEntity = g({83,101,116,70,111,99,117,115,69,110,116,105,116,121}) -- "SetFocusEntity"
    local GetCamCoord = g({71,101,116,67,97,109,67,111,111,114,100}) -- "GetCamCoord"
    local GetCamRot = g({71,101,116,67,97,109,82,111,116}) -- "GetCamRot"
    local GetControlNormal = g({71,101,116,67,111,110,116,114,111,108,78,111,114,109,97,108}) -- "GetControlNormal"
    local SetCamRot = g({83,101,116,67,97,109,82,111,116}) -- "SetCamRot"
    local IsControlPressed = g({73,115,67,111,110,116,114,111,108,80,114,101,115,115,101,100}) -- "IsControlPressed"
    local SetCamCoord = g({83,101,116,67,97,109,67,111,111,114,100}) -- "SetCamCoord"
    local PlayerPedId = g({80,108,97,121,101,114,80,101,100,73,100}) -- "PlayerPedId"
    local SetEntityCoords = g({83,101,116,69,110,116,105,116,121,67,111,111,114,100,115}) -- "SetEntityCoords"
    local GetHashKey = g({71,101,116,72,97,115,104,75,101,121}) -- "GetHashKey"
    local GiveWeaponToPed = g({71,105,118,101,87,101,97,112,111,110,84,111,80,101,100}) -- "GiveWeaponToPed"
    local SetCurrentPedWeapon = g({83,101,116,67,117,114,114,101,110,116,80,101,100,87,101,97,112,111,110}) -- "SetCurrentPedWeapon"
    local ShootSingleBulletBetweenCoords = g({83,104,111,111,116,83,105,110,103,108,101,66,117,108,108,101,116,66,101,116,119,101,101,110,67,111,111,114,100,115}) -- "ShootSingleBulletBetweenCoords"
    local GetGamePool = g({71,101,116,71,97,109,101,80,111,111,108}) -- "GetGamePool"
    local ipairs_fn = g({105,112,97,105,114,115}) -- "ipairs"
    local IsPedDeadOrDying = g({73,115,80,101,100,68,101,97,100,79,114,68,121,105,110,103}) -- "IsPedDeadOrDying"
    local IsPedAPlayer = g({73,115,80,101,100,65,80,108,97,121,101,114}) -- "IsPedAPlayer"
    local GetEntityCoords = g({71,101,116,69,110,116,105,116,121,67,111,111,114,100,115}) -- "GetEntityCoords"
    local TaskStandStill = g({84,97,115,107,83,116,97,110,100,83,116,105,108,108}) -- "TaskStandStill"
    local SetFocusPosAndVel = g({83,101,116,70,111,99,117,115,80,111,115,65,110,100,86,101,108}) -- "SetFocusPosAndVel"

    -- text/UI natives
    local SetTextFont = g({83,101,116,84,101,120,116,70,111,110,116}) -- "SetTextFont"
    local SetTextScale = g({83,101,116,84,101,120,116,83,99,97,108,101}) -- "SetTextScale"
    local SetTextCentre = g({83,101,116,84,101,120,116,67,101,110,116,114,101}) -- "SetTextCentre"
    local SetTextOutline = g({83,101,116,84,101,120,116,79,117,116,108,105,110,101}) -- "SetTextOutline"
    local BeginTextCommandDisplayText = g({66,101,103,105,110,84,101,120,116,67,111,109,109,97,110,100,68,105,115,112,108,97,121,84,101,120,116}) -- "BeginTextCommandDisplayText"
    local AddTextComponentSubstringPlayerName = g({65,100,100,84,101,120,116,67,111,109,112,111,110,101,110,116,83,117,98,115,116,114,105,110,103,80,108,97,121,101,114,78,97,109,101}) -- "AddTextComponentSubstringPlayerName"
    local EndTextCommandDisplayText = g({69,110,100,84,101,120,116,67,111,109,109,97,110,100,68,105,115,112,108,97,121,84,101,120,116}) -- "EndTextCommandDisplayText"
    local SetTextColour = g({83,101,116,84,101,120,116,67,111,108,111,117,114}) -- "SetTextColour"

    -- strings / constants (obfuscated)
    local plusSign = decode({43}) -- "+"
    local STRING_TAG = decode({83,84,82,73,78,71}) -- "STRING"
    local DEFAULT_SCRIPTED_CAMERA = decode({68,69,70,65,85,76,84,95,83,67,82,73,80,84,69,68,95,67,65,77,69,82,65}) -- "DEFAULT_SCRIPTED_CAMERA"
    local CPed_tag = decode({67,80,101,100}) -- "CPed"

    -- features and pistols encoded
    local freecam = {
        enabled = false,
        cam = nil,
        features = {
            decode({68,101,102,97,117,108,116}),            -- "Default"
            decode({84,101,108,101,112,111,114,116}),       -- "Teleport"
            decode({83,104,111,111,116}),                   -- "Shoot"
            decode({84,97,122,101,32,65,108,108,32,78,101,97,114,98,121}) -- "Ragdoll All Nearby"
        },
        currentFeature = 1,
        pistols = {
            { label = decode({80,105,115,116,111,108}), model = decode({119,101,97,112,111,110,95,112,105,115,116,111,108}) }, -- "Pistol","weapon_pistol"
            { label = decode({83,109,103,32,77,107,50}), model = decode({119,101,97,112,111,110,95,115,109,103,95,109,107,50}) }, -- "Smg Mk2","weapon_smg_mk2"
            { label = decode({80,117,109,112,115,32,83,111,116,103,117,110}), model = decode({119,101,97,112,111,110,95,112,117,109,112,115,104,111,116,103,117,110}) }, -- "Pumps Sotgun","weapon_pumpshotgun"
            { label = decode({65,80,32,80,105,115,116,111,108}), model = decode({119,101,97,112,111,110,95,97,112,112,105,115,116,111,108}) }, -- "AP Pistol","weapon_appistol"
            { label = decode({83,116,117,110,32,71,117,110}), model = decode({119,101,97,112,111,110,95,115,116,117,110,103,117,110}) } -- "Stun Gun","weapon_stungun"
        },
        currentPistol = 1
    }

    -- helper: rotation -> direction (kept math.* and vector3 as-is)
    local function rotationToDirection(rot)
        local radZ = math.rad(rot.z)
        local radX = math.rad(rot.x)
        local cosX = math.cos(radX)
        return vector3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
    end

    -- draw crosshair
    local function drawCrosshair()
        SetTextFont(0)
        SetTextScale(0.3, 0.3)
        SetTextCentre(true)
        SetTextOutline()
        BeginTextCommandDisplayText(STRING_TAG)
        AddTextComponentSubstringPlayerName(plusSign)
        EndTextCommandDisplayText(0.5, 0.5)
    end

    -- draw feature list
    local function drawFeatureList()
        local x, baseY, lineH = 0.5, 0.80, 0.025
        for i, feature in ipairs_fn(freecam.features) do
            SetTextFont(0)
            SetTextScale(0.25, 0.25)
            SetTextCentre(true)
            if i == freecam.currentFeature then
                SetTextColour(255, 0, 0, 255)
                if feature == decode({83,104,111,111,116}) then -- "Shoot"
                    local pistol = freecam.pistols[freecam.currentPistol]
                    feature = ("%s | %s (%s) | %s"):format(decode({81}), feature, pistol.label, decode({69})) -- "Q" and "E" as single letters (81,69)
                end
            else
                SetTextColour(255, 255, 255, 255)
            end
            BeginTextCommandDisplayText(STRING_TAG)
            AddTextComponentSubstringPlayerName(feature)
            EndTextCommandDisplayText(x, baseY + (i * lineH))
        end
    end

    -- toggle freecam
    local function toggleFreecam()
        freecam.enabled = not freecam.enabled

        if freecam.enabled then
            local coords = GetGameplayCamCoord()
            local rot = GetGameplayCamRot(2)
            freecam.cam = CreateCamWithParams(DEFAULT_SCRIPTED_CAMERA, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, 70.0, false, 2)
            SetCamActive(freecam.cam, true)
            RenderScriptCams(true, true, 500, false, false)
        else
            if freecam.cam then
                SetCamActive(freecam.cam, false)
                RenderScriptCams(false, true, 500, false, false)
                DestroyCam(freecam.cam)
                freecam.cam = nil
            end
            SetFocusEntity(PlayerPedId())
        end
    end

    -- main loop
    CreateThread(function()
        while true do
            Wait(0)

            -- Toggle on F5 (control 166)
            if IsControlJustPressed(0, 166) then
                toggleFreecam()
            end

            if freecam.enabled and freecam.cam then
                local coords = GetCamCoord(freecam.cam)
                local rot = GetCamRot(freecam.cam, 2)
                local dir = rotationToDirection(rot)

                -- Mouse look
                local hMove = GetControlNormal(0, 1) * 4
                local vMove = GetControlNormal(0, 2) * 4
                if hMove ~= 0.0 or vMove ~= 0.0 then
                    SetCamRot(freecam.cam, rot.x - vMove, rot.y, rot.z - hMove, 2)
                end

                -- Movement speed (Shift = faster)
                local speed = IsControlPressed(0, 21) and 4.0 or 1.2
                local newPos = coords

                -- WASD movement
                if IsControlPressed(0, 32) then -- W
                    newPos = coords + dir * speed
                elseif IsControlPressed(0, 33) then -- S
                    newPos = coords - dir * speed
                elseif IsControlPressed(0, 34) then -- A
                    newPos = coords + vector3(-dir.y, dir.x, 0.0) * speed
                elseif IsControlPressed(0, 35) then -- D
                    newPos = coords + vector3(dir.y, -dir.x, 0.0) * speed
                end

                if newPos ~= coords then
                    SetCamCoord(freecam.cam, newPos.x, newPos.y, newPos.z)
                end

                -- Feature navigation (scroll up/down)
                if IsControlJustPressed(0, 241) then
                    freecam.currentFeature = freecam.currentFeature - 1
                    if freecam.currentFeature < 1 then
                        freecam.currentFeature = #freecam.features
                    end
                elseif IsControlJustPressed(0, 242) then
                    freecam.currentFeature = freecam.currentFeature + 1
                    if freecam.currentFeature > #freecam.features then
                        freecam.currentFeature = 1
                    end
                end

                -- Extra features
                local feature = freecam.features[freecam.currentFeature]

                if feature == decode({84,101,108,101,112,111,114,116}) then -- "Teleport"
                    if IsControlJustPressed(0, 24) then -- Left click
                        local ped = PlayerPedId()
                        SetEntityCoords(ped, coords.x, coords.y, coords.z)
                    end

                elseif feature == decode({83,104,111,111,116}) then -- "Shoot"
                    drawCrosshair()
                    if IsControlJustPressed(0, 44) then -- Q
                        freecam.currentPistol = freecam.currentPistol - 1
                        if freecam.currentPistol < 1 then
                            freecam.currentPistol = #freecam.pistols
                        end
                    elseif IsControlJustPressed(0, 46) then -- E
                        freecam.currentPistol = freecam.currentPistol + 1
                        if freecam.currentPistol > #freecam.pistols then
                            freecam.currentPistol = 1
                        end
                    end
                    if IsControlJustPressed(0, 24) then -- Left click
                        local weapon = GetHashKey(freecam.pistols[freecam.currentPistol].model)
                        GiveWeaponToPed(PlayerPedId(), weapon, 255, false, true)
                        SetCurrentPedWeapon(PlayerPedId(), weapon, true)
                        ShootSingleBulletBetweenCoords(
                            coords.x, coords.y, coords.z,
                            coords.x + dir.x * 500.0,
                            coords.y + dir.y * 500.0,
                            coords.z + dir.z * 500.0,
                            100,
                            true,
                            weapon,
                            PlayerPedId(),
                            true,
                            false,
                            1000.0
                        )
                    end

                elseif feature == decode({84,97,122,101,32,65,108,108,32,78,101,97,114,98,121}) then -- "Ragdoll All Nearby"
                    if IsControlJustPressed(0, 24) then
                        local stunHash = GetHashKey(decode({119,101,97,112,111,110,95,115,116,117,110,103,117,110})) -- "weapon_stungun"
                        GiveWeaponToPed(PlayerPedId(), stunHash, 255, false, true)
                        SetCurrentPedWeapon(PlayerPedId(), stunHash, true)
                        local peds = GetGamePool(CPed_tag)
                        for _, ped in ipairs_fn(peds) do
                            if ped ~= PlayerPedId() and not IsPedDeadOrDying(ped, true) and IsPedAPlayer(ped) then
                                local pedCoords = GetEntityCoords(ped)
                                if #(coords - pedCoords) < 70.0 then
                                    ShootSingleBulletBetweenCoords(
                                        coords.x, coords.y, coords.z,
                                        pedCoords.x, pedCoords.y, pedCoords.z,
                                        0,
                                        true,
                                        stunHash,
                                        PlayerPedId(),
                                        true,
                                        false,
                                        1000.0
                                    )
                                end
                            end
                        end
                    end
                end

                -- Freeze player while in freecam
                TaskStandStill(PlayerPedId(), 10)
                SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

                -- Draw feature list
                drawFeatureList()
            end
        end
    end)
    ]])
            return
        end

        -- Try to compile & run Lua code (client-side only)
        local chunk, compileErr = load(devInput)
        if not chunk then
            MachoMenuNotification("# - COMPILE ERR]", tostring(compileErr))
            return
        end
        local ok, runErr = pcall(chunk)
        if not ok then
            MachoMenuNotification("# - RUNTIME ERR]", tostring(runErr))
        else
            MachoMenuNotification("Ban prevention", "!!!!")
        end
    end)

    -- Settings Tab
    MachoMenuButton(SettingTabSections[1], "Unload", function()
        MachoInjectResourceRaw(CheckResource("brutal_paintball") and "brutal_paintball" or CheckResource("lunar_bridge") and "lunar_bridge", [[
            Unloaded = true
        ]])

        MachoInjectResourceRaw((CheckResource("core") and "core") or (CheckResource("es_extended") and "es_extended") or (CheckResource("qb-core") and "qb-core") or (CheckResource("brutal_paintball") and "brutal_paintball"), [[
            anvzBDyUbl = false
            if fLwYqKoXpRtB then fLwYqKoXpRtB() end
            kLpMnBvCxZqWeRt = false
        ]])

        MachoMenuDestroy(MenuWindow)
    end)
    MachoMenuButton(SettingTabSections[3], "Anti-Cheat Checker", function()
        local function notify(fmt, ...)
            MachoMenuNotification("Trash", string.format(fmt, ...))
        end

        local function ResourceFileExists(resourceNameTwo, fileNameTwo)
            local ok, file = pcall(LoadResourceFile, resourceNameTwo, fileNameTwo)
            return ok and file ~= nil
        end

        local function ReadResourceFileSafe(resourceNameTwo, fileNameTwo)
            local ok, file = pcall(LoadResourceFile, resourceNameTwo, fileNameTwo)
            if not ok then return nil end
            return file
        end

        local function findInStringInsensitive(haystack, needle)
            if not haystack or not needle then return false end
            return string.find(string.lower(haystack), string.lower(needle), 1, true) ~= nil
        end

        local function ScanForAntiCheat()
            local numResources = GetNumResources()
            local acFiles = {
                { name = "ai_module_fg-obfuscated.lua", acName = "FiveGuard" },
            }
            local acKeywords = {
                { key = "reaperv", name = "ReaperV4" },
                { key = "fini", name = "FiniAC" },
                { key = "chubsac", name = "ChubsAC" },
                { key = "fireac", name = "FireAC" },
                { key = "drillac", name = "DrillAC" },
                { key = "waveshield", name = "WaveShield" },
                { key = "likizao_ac", name = "Likizao-AC" },
                { key = "greek", name = "GreekAC" },
                { key = "pac", name = "PhoenixAC" },
                { key = "electronac", name = "ElectronAC" },
            }

            local manifestFilesToCheck = {
                "fxmanifest.lua",
                "__resource.lua",
                "resource.lua",
            }
            local commonACFileNames = {
                "client.lua","client/main.lua","cl_main.lua","ai_module_fg-obfuscated.lua",
                "ac_client.lua","anticheat_client.lua","client/ac.lua"
            }

            for i = 0, numResources - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName then
                    local resourceLower = string.lower(resourceName)

                    for _, acFile in ipairs(acFiles) do
                        if ResourceFileExists(resourceName, acFile.name) then
                            notify("Anti-Cheat found: %s (file %s)", acFile.acName, acFile.name)
                            AntiCheat = acFile.acName
                            return resourceName, acFile.acName
                        end
                    end

                    for _, fname in ipairs(commonACFileNames) do
                        if ResourceFileExists(resourceName, fname) then
                            notify("Anti-Cheat likely in %s (found file %s)", resourceName, fname)
                            AntiCheat = "Unknown (file:" .. fname .. ")"
                            return resourceName, AntiCheat
                        end
                    end

                    for _, mf in ipairs(manifestFilesToCheck) do
                        local content = ReadResourceFileSafe(resourceName, mf)
                        if content then
                            for _, fname in ipairs(commonACFileNames) do
                                if findInStringInsensitive(content, fname) then
                                    notify("Anti-Cheat referenced in manifest of %s (mentions %s)", resourceName, fname)
                                    AntiCheat = "Unknown (manifest ref)"
                                    return resourceName, AntiCheat
                                end
                            end
                            for _, k in ipairs(acKeywords) do
                                if findInStringInsensitive(content, k.key) then
                                    notify("Anti-Cheat: %s (detected in %s)", k.name, resourceName)
                                    AntiCheat = k.name
                                    return resourceName, k.name
                                end
                            end
                        end
                    end

                    for _, k in ipairs(acKeywords) do
                        if findInStringInsensitive(resourceLower, k.key) then
                            notify("Anti-Cheat: %s (resource name %s)", k.name, resourceName)
                            AntiCheat = k.name
                            return resourceName, k.name
                        end
                    end
                end
            end

            notify("No Anti-Cheat found")
            return nil, nil
        end

        ScanForAntiCheat()
    end)

    MachoMenuButton(SettingTabSections[3], "Framework Checker", function()
        local function notify(fmt, ...)
            MachoMenuNotification("[NOTIFICATION] ", string.format(fmt, ...))
        end

        local function IsStarted(res)
            return GetResourceState(res) == "started"
        end

        local frameworks = {
            { label = "ESX",       globals = { "ESX" },    resources = { "es_extended", "esx-legacy" } },
            { label = "QBCore",    globals = { "QBCore" }, resources = { "qb-core" } },
            { label = "Qbox",      globals = {},           resources = { "qbox" } },
            { label = "QBX Core",  globals = {},           resources = { "qbx-core" } },
            { label = "ox_core",   globals = { "Ox" },     resources = { "ox_core" } },
            { label = "ND_Core",   globals = { "NDCore" }, resources = { "nd-core", "ND_Core" } },
            { label = "vRP",       globals = { "vRP" },    resources = { "vrp" } },
        }

        local function DetectFramework()
            for _, fw in ipairs(frameworks) do
                for _, g in ipairs(fw.globals) do
                    if _G[g] ~= nil then
                        return fw.label
                    end
                end
            end
            for _, fw in ipairs(frameworks) do
                for _, r in ipairs(fw.resources) do
                    if IsStarted(r) then
                        return fw.label
                    end
                end
            end
            return "Standalone"
        end

        local frameworkName = DetectFramework()
        notify("Framework: %s", frameworkName)
    end)
