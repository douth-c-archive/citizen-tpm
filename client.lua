local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord

local consoleRem <const> = true -- console reminder; enabled by default.
local customRem <const> = false -- custom reminder (line 23).
local chatRem <const> = false -- disabled by default.
local commandName <const> = 'tpm'

TriggerEvent('chat:addSuggestion', '/' .. commandName, 'Teleport to your marked waypoint.')

local function notify(message)
    if consoleRem then
        print(message)
    end
    if chatRem then
        TriggerEvent('chat:addMessage', {
            color = {255,85,85},
            args = {"citizen-tpm", message}
        })
    end
    if customRem then
        -- Add your custom notification here.
    end
end

local function teleportToWaypoint()
    local blipMarker <const> = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blipMarker) then
        notify('client needs to set a waypoint first.')
        return 'marker'
    end
    
    -- Fade screen to hide how clients get teleported.
    DoScreenFadeOut(650)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local ped, coords <const> = PlayerPedId(), GetBlipInfoIdCoord(blipMarker)
    local oldCoords <const> = GetEntityCoords(ped)

    -- Unpack coords instead of having to unpack them while iterating.
    local x, y, groundZ, Z_START = coords['x'], coords['y'], 850.0, 950.0
    local found = false
    FreezeEntityPosition(ped, true)

    for i = Z_START, 0, -25.0 do
        local z = i
        if (i % 2) ~= 0 then
            z = Z_START - i
        end

        NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
        local curTime = GetGameTimer()
        while IsNetworkLoadingScene() do
            if GetGameTimer() - curTime > 1000 then
                break
            end
            Wait(0)
        end
        NewLoadSceneStop()
        SetEntityCoords(ped, x, y, z, false, false, false, true)

        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(x, y, z);
            if GetGameTimer() - curTime > 1000 then
                break
            end
            Wait(0)
        end
        -- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
        found, groundZ = GetGroundZFor_3dCoord(x, y, z, false);
        if found then
            Wait(0)
            SetEntityCoords(ped, x, y, groundZ, false, false, false, true)
            break
        end
        Wait(0)
    end

    -- Remove black screen once the loop has ended.
    DoScreenFadeIn(650);
    if not found then
        -- If we can't find the coords, set the coords to the old ones. We don't unpack them before since they aren't in a loop and only called once.
        SetEntityCoords(ped, oldCoords['x'], oldCoords['y'], oldCoords['z'] - 1.0, false, false, false, true)
        FreezeEntityPosition(ped, false)
        return false
    end

    -- If Z coord was found, set coords in found coords.
    FreezeEntityPosition(ped, false)
    RequestCollisionAtCoord(x, y, groundZ);
    SetEntityCoords(ped, x, y, groundZ, false, false, false, true)
    return true
end

RegisterCommand(commandName, function()
    local hasTeleported <const> = teleportToWaypoint()
    if not hasTeleported then
        notify('Could not teleport to desired location.')
        return
    elseif hasTeleported ~= 'marker' then
        notify('teleported successfully')
    end
end)

exports('TeleportToWaypoint', teleportToWaypoint)