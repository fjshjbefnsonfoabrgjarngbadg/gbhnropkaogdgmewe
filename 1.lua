--- V2
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
-- do
--     local function ResourceFileExists(resourceName, fileName)
--         local ok, file = pcall(LoadResourceFile, resourceName, fileName)
--         if not ok then return false end
--         return file ~= nil
--     end

--     local targetFile = "ai_sh-life_shield-module.lua"
--     local numResources = GetNumResources()

--     for i = 0, numResources - 1 do
--         local resourceName = GetResourceByFindIndex(i)
--         if resourceName and ResourceFileExists(resourceName, targetFile) then
--             -- stop the offending resource and notify

--             if type(MachoMenuNotification) == "function" then
--                 MachoMenuNotification("#", "              failed to inject")
--             end
--             return -- stop execution so injection doesn't continue
--         end
--     end
-- end
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

local MenuWindow = MachoMenuTabbedWindow("M4RSHAL", MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
MachoMenuSetKeybind(MenuWindow, 0x14)
MachoMenuSetAccent(MenuWindow, 75, 0, 130)

-- CreateRainbowInterface()
local EventTab = MachoMenuAddTab(MenuWindow, "Triggers")
local SettingTab = MachoMenuAddTab(MenuWindow, "Settings")

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
    -- Detect and stop all AN4 resources
local function StopAN4Resources()
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local rn = string.lower(resourceName)
            -- Add all keywords of resources you want to stop here
            if string.find(rn, "logs", 1, true)
            or string.find(rn, "an4-", 1, true)
            then
                MachoResourceStop(resourceName)
            end
        end
    end
end
    Wait(100)
    StopAN4Resources()

-- Tab Sections
local EventTabSections = { EventTabContent(EventTab) }
local SettingTabSections = { SettingTabContent(SettingTab) }


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

    -- Wait until either wasabi_bridge or lunar_bridge starts or timeout hits
    while GetResourceState("wasabi_bridge") ~= "started" and GetResourceState("lunar_bridge") ~= "started" and waitTime < timeout do
        Wait(500)
        waitTime = waitTime + 500
    end

    if GetResourceState("wasabi_bridge") == "started" or GetResourceState("lunar_bridge") == "started" then
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
            ["jim-consumables"] = function()
                MachoInjectResourceRaw( CheckResource("wasabi_bridge") and "wasabi_bridge" or CheckResource("lunar_bridge") and "lunar_bridge", [[
                    local function kjh_toggle()
                        TriggerServerEvent("jim-consumables:server:toggleItem", true, "]] .. ItemName .. [[", ]] .. ItemAmount .. [[)
                    end
                    kjh_toggle()
                ]])
            end,
        }
    else
        MachoMenuNotification("#error", "Invalid Item or Amount.")
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
            CheckResource("wasabi_bridge") and "wasabi_bridge" or
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
        MachoMenuNotification("[SPAWNED]", "Vehicle " .. CarName .. " spawned successfully!")
    else
        MachoMenuNotification("#Error", "Please enter a valid car name.")
    end
end)
-- Common Exploits section: add Revive button
MachoMenuButton(EventTabSections[3], "Revive", function()
     MachoInjectResourceRaw( CheckResource("wasabi_bridge") and "wasabi_bridge" or CheckResource("lunar_bridge") and "lunar_bridge", [[
    TriggerEvent('wasabi_ambulance:revive')
    ]])
    MachoMenuNotification("[REVIVE]", "Revived")
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
            MachoMenuNotification("CRASHer", "Failed - System error!")
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

    MachoMenuNotification("CRASH", "completed successfully")
end)
--SECTION OF DEV 
MachoMenuButton(EventTabSections[4], "Bypass Noclip", function()
    MachoMenuNotification("Bypass", "Loaded")
   MachoInjectResourceRaw( CheckResource("wasabi_bridge") and "wasabi_bridge" or CheckResource("lunar_bridge") and "lunar_bridge", [[
   Citizen.CreateThread(function()
    -- try to get the export table once, but accept that it might appear later
    local waveShield = nil

    -- safe WaveShield functions (no parameters needed, non-weapon, non-spawn)
    local functions = {
        "hasTeleported",
        "hasChangedPedModel",
        "healthRefilled",
        "playerRevived",
        "proofsEnabled",
        "canBeDamaged",
        "isInvincible",
        "isVisible",
        "resettedStamina",
        "disableE2",
        "disableAllControls",
    }

    while true do
        -- refresh reference in case resource started after this script
        if not waveShield then
            waveShield = exports["WaveShield"]
        end

        if waveShield then
            for _, fname in ipairs(functions) do
                local fn = waveShield[fname]
                if type(fn) == "function" then
                    --print(("^2Calling WaveShield function: %s^7"):format(fname))
                    local ok, err = pcall(fn, waveShield)
                    if not ok then
                        --print(("^1WaveShield function %s threw an error: %s^7"):format(fname, tostring(err)))
                    end
                else
                   --print(("^3WaveShield function not found: %s^7"):format(fname))
                end
            end
        end

        Citizen.Wait(1000) -- wait 1 second before next loop
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
      MachoInjectResourceRaw( CheckResource("wasabi_bridge") and "wasabi_bridge" or CheckResource("lunar_bridge") and "lunar_bridge", [[
      local freecam = {
    enabled = false,
    cam = nil,
    features = { "Default", "Teleport", "Shoot", "Taze All Nearby" },
    currentFeature = 1,
    pistols = {
        { label = "Pistol", model = "weapon_pistol" },
        { label = "Smg Mk2 ", model = "weapon_smg_mk2" },
        { label = "Pumps Sotgun", model = "weapon_pumpshotgun" },
        { label = "AP Pistol", model = "weapon_appistol" },
        { label = "Stun Gun", model = "weapon_stungun" }
    },
    currentPistol = 1
}

-- Convert camera rotation into direction vector
local function rotationToDirection(rot)
    local radZ = math.rad(rot.z)
    local radX = math.rad(rot.x)
    local cosX = math.cos(radX)
    return vector3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
end

-- Draw crosshair
local function drawCrosshair()
    SetTextFont(0)
    SetTextScale(0.3, 0.3)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName("+")
    EndTextCommandDisplayText(0.5, 0.5)
end

-- Draw feature list
local function drawFeatureList()
    local x, baseY, lineH = 0.5, 0.80, 0.025
    for i, feature in ipairs(freecam.features) do
        SetTextFont(0)
        SetTextScale(0.25, 0.25)
        SetTextCentre(true)
        if i == freecam.currentFeature then
            SetTextColour(255, 0, 0, 255)
            if feature == "Shoot" then
                local pistol = freecam.pistols[freecam.currentPistol]
                feature = ("Q | %s (%s) | E"):format(feature, pistol.label)
            end
        else
            SetTextColour(255, 255, 255, 255)
        end
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(feature)
        EndTextCommandDisplayText(x, baseY + (i * lineH))
    end
end

-- Toggle Freecam
local function toggleFreecam()
    freecam.enabled = not freecam.enabled

    if freecam.enabled then
        local coords = GetGameplayCamCoord()
        local rot = GetGameplayCamRot(2)
        freecam.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, 70.0, false, 2)
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

-- Main loop
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

            if feature == "Teleport" then
                if IsControlJustPressed(0, 24) then -- Left click
                    local ped = PlayerPedId()
                    SetEntityCoords(ped, coords.x, coords.y, coords.z)
                end
            elseif feature == "Shoot" then
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
            elseif feature == "Taze All Nearby" then
                if IsControlJustPressed(0, 24) then
                    local stunHash = GetHashKey("weapon_stungun")
                    GiveWeaponToPed(PlayerPedId(), stunHash, 255, false, true)
                    SetCurrentPedWeapon(PlayerPedId(), stunHash, true)
                    local peds = GetGamePool("CPed")
                    for _, ped in ipairs(peds) do
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
        MachoMenuNotification("[DEV - COMPILE ERR]", tostring(compileErr))
        return
    end
    local ok, runErr = pcall(chunk)
    if not ok then
        MachoMenuNotification("[DEV - RUNTIME ERR]", tostring(runErr))
    else
        MachoMenuNotification("[UNDER DEV]", "Click 2 executed input successfully.")
    end
end)
-- Settings Tab
MachoMenuButton(SettingTabSections[1], "Unload", function()
    MachoInjectResourceRaw(CheckResource("wasabi_bridge") and "wasabi_bridge" or CheckResource("lunar_bridge") and "lunar_bridge", [[
        Unloaded = true
    ]])

    MachoInjectResourceRaw((CheckResource("core") and "core") or (CheckResource("es_extended") and "es_extended") or (CheckResource("qb-core") and "qb-core") or (CheckResource("wasabi_bridge") and "wasabi_bridge"), [[
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
       
    else
        -- Error notification
        MachoMenuNotification("#error loading bypass", "Failed")
    end
end)