local cam = nil
local savedPedPos = nil
local savedPedHeading = nil
local active = false
local fov = 60.0

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function deg2rad(d) return d * 0.017453292519943295 end
local function rad2deg(r) return r * 57.29577951308232 end

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

        if Config.HideHud then
end
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
        if Config.HideHud then
end
    end
end

-- Core update loop when active
CreateThread(function()
    while true do
        if active and cam ~= nil then
            -- Disable some controls for a clean cinematic experience
            if Config.HideHud then
                HideHudAndRadarThisFrame()
                -- (Optional) hide weapon/select hints etc.
                HideHudComponentThisFrame(1)  -- Wanted Stars
                HideHudComponentThisFrame(2)  -- Weapon Icon
                HideHudComponentThisFrame(3)  -- Cash
                HideHudComponentThisFrame(4)  -- MP Cash
                HideHudComponentThisFrame(7)  -- Area Name
                HideHudComponentThisFrame(9)  -- Street Name
                HideHudComponentThisFrame(13) -- Cash Change
                HideHudComponentThisFrame(14) -- Reticle
                HideHudComponentThisFrame(19) -- Weapon Wheel
            end
            -- (We still read disabled controls using GetDisabledControlNormal)
            DisableAllControlActions(0)

            -- Re-enable the specific inputs we need to drive freecam
            -- Look axes
            EnableControlAction(0, 1, true)   -- LOOK_LR
            EnableControlAction(0, 2, true)   -- LOOK_UD
            -- Move axes
            -- Movement on arrow keys
            EnableControlAction(0, 174, true) -- INPUT_CELLPHONE_LEFT (Arrow Left)
            EnableControlAction(0, 175, true) -- INPUT_CELLPHONE_RIGHT (Arrow Right)
            EnableControlAction(0, 172, true) -- INPUT_CELLPHONE_UP (Arrow Up)
            EnableControlAction(0, 173, true) -- INPUT_CELLPHONE_DOWN (Arrow Down)
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
            local up = IsDisabledControlPressed(0, 22) and 1.0 or 0.0 -- Space
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
            -- apply movement (W/S forward/back, A/D left/right, Space up)
            pos = vector3(
                pos.x + (forward.x * moveY + right.x * moveX + upVec.x * (up - 0.0)) * speed * dt,
                pos.y + (forward.y * moveY + right.y * moveX + upVec.y * (up - 0.0)) * speed * dt,
                pos.z + (forward.z * moveY + right.z * moveX + upVec.z * (up - downMod * 1.0)) * speed * dt
            )

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
    if cam ~= nil then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
        ClearFocus()
    end
    if Config.HideHud then
end
end)
