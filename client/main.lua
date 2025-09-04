local cam = nil
local active = false
local fov = 60.0
local savedPedPos = nil
local savedPedHeading = nil

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function deg2rad(d) return d * 0.017453292519943295 end

-- Convert rotation (pitch=x, roll=y, yaw=z) to forward direction
local function rotationToDirection(rot)
    local z = deg2rad(rot.z)
    local x = deg2rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function normalize(v)
    local mag = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
    if mag == 0.0 then return vector3(0.0, 0.0, 0.0) end
    return vector3(v.x/mag, v.y/mag, v.z/mag)
end

local function cross(a, b)
    return vector3(
        a.y*b.z - a.z*b.y,
        a.z*b.x - a.x*b.z,
        a.x*b.y - a.y*b.x
    )
end

local function toggleFreecam()
    active = not active

    local ped = PlayerPedId()
    if active then
        -- Save & freeze player so position is preserved
        savedPedPos = GetEntityCoords(ped)
        savedPedHeading = GetEntityHeading(ped)
        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
        SetEntityInvincible(ped, true)

        -- start from player pos & headings
        local pos = savedPedPos
        local rot = GetGameplayCamRot(2)
        fov = clamp(GetGameplayCamFov(), Config.MinFov, Config.MaxFov)

        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov, false, 2)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
        SetFocusArea(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
    else
        -- Unfreeze and restore player
        if savedPedPos ~= nil then
            SetEntityCoordsNoOffset(ped, savedPedPos.x, savedPedPos.y, savedPedPos.z, false, false, false)
            SetEntityHeading(ped, savedPedHeading or GetEntityHeading(ped))
        end
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetEntityInvincible(ped, false)

        if cam ~= nil then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(cam, false)
            cam = nil
        end
        ClearFocus()
    end
end

-- Core update loop when active
CreateThread(function()
    while true do
        if active and cam ~= nil then
            -- Hide HUD/minimap per-frame while active (no global state change)
            if Config.HideHud then
                HideHudAndRadarThisFrame()
                HideHudComponentThisFrame(1)  -- Wanted stars
                HideHudComponentThisFrame(2)  -- Weapon icon
                HideHudComponentThisFrame(3)  -- Cash
                HideHudComponentThisFrame(4)  -- MP Cash
                HideHudComponentThisFrame(7)  -- Area Name
                HideHudComponentThisFrame(9)  -- Street Name
                HideHudComponentThisFrame(13) -- Cash Change
                HideHudComponentThisFrame(14) -- Reticle
                HideHudComponentThisFrame(19) -- Weapon Wheel
            end

            -- Disable some controls for a clean cinematic experience
            DisableAllControlActions(0)

            -- Re-enable the specific inputs we need to drive freecam
            -- Look axes
            EnableControlAction(0, 1, true)   -- LOOK_LR
            EnableControlAction(0, 2, true)   -- LOOK_UD
            -- Movement on arrow keys
            EnableControlAction(0, 174, true) -- Arrow Left
            EnableControlAction(0, 175, true) -- Arrow Right
            EnableControlAction(0, 172, true) -- Arrow Up
            EnableControlAction(0, 173, true) -- Arrow Down
            -- Up / Down
            EnableControlAction(0, 22, true)  -- JUMP (Space) -> UP
            EnableControlAction(0, 36, true)  -- DUCK (Ctrl) -> DOWN modifier + slow
            EnableControlAction(0, 21, true)  -- SPRINT (Shift) -> fast
            -- Zoom with mouse wheel (Replay FOV controls)
            EnableControlAction(0, 241, true) -- REPLAY_FOVINCREASE (Wheel Up)
            EnableControlAction(0, 242, true) -- REPLAY_FOVDECREASE (Wheel Down)

            -- Optionally block combat
            if Config.DisableCombat then
                DisableControlAction(0, 24, true) -- attack
                DisableControlAction(0, 25, true) -- aim
                DisableControlAction(0, 140, true) -- melee
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisablePlayerFiring(PlayerId(), true)
            end

            local dt = GetFrameTime()

            -- Read rotation deltas from mouse
            local lookX = GetDisabledControlNormal(0, 1)  -- -1..1
            local lookY = GetDisabledControlNormal(0, 2)  -- -1..1
            local rot = GetCamRot(cam, 2)

            local sens = Config.MouseSensitivity
            rot = vector3(
                clamp(rot.x - lookY * sens, -89.0, 89.0), -- pitch
                0.0,                                      -- roll fixed
                (rot.z - lookX * sens) % 360.0            -- yaw
            )
            SetCamRot(cam, rot.x, rot.y, rot.z, 2)

            -- Zoom / FOV
            if IsDisabledControlPressed(0, 241) then -- wheel up -> zoom in
                fov = clamp(fov - Config.FovStep, Config.MinFov, Config.MaxFov)
            elseif IsDisabledControlPressed(0, 242) then -- wheel down -> zoom out
                fov = clamp(fov + Config.FovStep, Config.MinFov, Config.MaxFov)
            end
            SetCamFov(cam, fov)

            -- Movement
            -- Arrow Left/Right -> strafe
            local moveX = 0.0
            if IsDisabledControlPressed(0, 175) then
                moveX = 1.0
            elseif IsDisabledControlPressed(0, 174) then
                moveX = -1.0
            end

            -- Arrow Up/Down -> forward/back
            local moveY = 0.0
            if IsDisabledControlPressed(0, 172) then
                moveY = 1.0
            elseif IsDisabledControlPressed(0, 173) then
                moveY = -1.0
            end

            local upKey = IsDisabledControlPressed(0, 22) and 1.0 or 0.0 -- Space
            local downMod = IsDisabledControlPressed(0, 36) and 1.0 or 0.0 -- Ctrl

            local forward = rotationToDirection(rot)
            local right = normalize(cross(forward, vector3(0.0, 0.0, 1.0)))
            local upVec = vector3(0.0, 0.0, 1.0)

            local speed = Config.BaseSpeed
            if IsDisabledControlPressed(0, 21) then -- Shift to go fast
                speed = speed * Config.FastMultiplier
            elseif downMod > 0.5 then               -- Ctrl to go slow
                speed = speed * Config.SlowMultiplier
            end

            local pos = GetCamCoord(cam)
            -- apply movement (forward/back, strafe, vertical). Down uses Ctrl as "down" when pressed.
            pos = vector3(
                pos.x + (forward.x * moveY + right.x * moveX + upVec.x * (upKey - downMod)) * speed * dt,
                pos.y + (forward.y * moveY + right.y * moveX + upVec.y * (upKey - downMod)) * speed * dt,
                pos.z + (forward.z * moveY + right.z * moveX + upVec.z * (upKey - downMod)) * speed * dt
            )

            -- Distance limits from anchor (savedPedPos)
            if Config.EnableDistanceLimits and savedPedPos ~= nil then
                local anchor = savedPedPos
                local diff = vector3(pos.x - anchor.x, pos.y - anchor.y, pos.z - anchor.z)
                local dist = math.sqrt(diff.x*diff.x + diff.y*diff.y + diff.z*diff.z)
                local minD = Config.MinDistance or 0.0
                local maxD = Config.MaxDistance or 1000000.0

                if dist < minD then
                    -- If too close, push camera out along its forward direction
                    local fwd = rotationToDirection(rot)
                    pos = vector3(anchor.x + fwd.x * minD, anchor.y + fwd.y * minD, anchor.z + fwd.z * minD)
                elseif dist > maxD and dist > 0.001 then
                    -- If too far, clamp back to the sphere surface
                    local scale = maxD / dist
                    pos = vector3(anchor.x + diff.x * scale, anchor.y + diff.y * scale, anchor.z + diff.z * scale)
                end
            end

            SetCamCoord(cam, pos.x, pos.y, pos.z)
            SetFocusArea(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
        else
            Wait(200)
        end
        Wait(0)
    end
end)

-- Command + key mapping (F9 by default)
RegisterCommand('muvision', function()
    toggleFreecam()
end, false)

RegisterKeyMapping('muvision', 'Toggle MU-Vision Freecam', 'keyboard', 'F9')

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    if cam ~= nil then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
        ClearFocus()
    end
    -- Restore ped if we were active
    if savedPedPos ~= nil then
        SetEntityCoordsNoOffset(ped, savedPedPos.x, savedPedPos.y, savedPedPos.z, false, false, false)
        SetEntityHeading(ped, savedPedHeading or GetEntityHeading(ped))
    end
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
end)
