--test
local consoleRem <const> = true -- enabled by default.
local chatRem <const> = false -- disabled by default.
local commandName <const> = 'tpm'

TriggerEvent('chat:addSuggestion', '/' .. commandName, "Teleport to your marked waypoint.")

local function teleportToWaypoint()
    local blipMarker <const> = GetFirstBlipInfoId(8)
    if DoesBlipExist(blipMarker) then
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do
            Wait(0)
        end
        local ped, coords <const> = PlayerPedId(), GetBlipInfoIdCoord(blipMarker)
        local oldCoords = GetEntityCoords(ped)
        local x, y, groundZ, Z_START = coords['x'], coords['y'], 850.0, 950.0
        local found = false
        FreezeEntityPosition(ped, true)
        for i = Z_START, 0, -25.0 do
            local z = i
            -- vmenu implementation
            if (i % 2) ~= 0 then
                z = Z_START - i
            end

            RequestCollisionAtCoord(x, y, z);
            NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)

            local curTime = GetGameTimer()
            while IsNetworkLoadingScene() do
                if GetGameTimer() - curTime > 1000 then
                    break
                end
                Wait(0)
            end
            SetEntityCoords(ped, x, y, z, false, false, false, true)

            while not HasCollisionLoadedAroundEntity(ped) do
                RequestCollisionAtCoord(x, y, z);
                if GetGameTimer() - curTime > 1000 then
                    break
                end
                Wait(0)
            end
            NewLoadSceneStop()
            found, groundZ = GetGroundZFor_3dCoord(x, y, z, false);
            if found then
                Wait(0)
                SetEntityCoords(ped, x, y, groundZ, false, false, false, true)
                break
            end
            Wait(0)
        end

        DoScreenFadeIn(500);
        if not found then
            print('not found')
            SetEntityCoords(ped, oldCoords['x'], oldCoords['y'], oldCoords['z'] - 1.0, false, false, false, true)
            FreezeEntityPosition(ped, false)
            return false
        end
        FreezeEntityPosition(ped, false)
        RequestCollisionAtCoord(x, y, groundZ);
        SetEntityCoords(ped, x, y, groundZ, false, false, false, true)
        --print(x, y, groundZ)
        return true
    end
    return false
end

RegisterCommand(commandName, function()
    local hasTeleported <const> = teleportToWaypoint()
end)

exports('TeleportToWaypoint', teleportToWaypoint)