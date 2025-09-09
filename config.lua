-- mu-vision: simple, standalone freecam
Config = {}

-- Base movement speed (meters per second). Hold SHIFT to multiply, CTRL to slow.
Config.BaseSpeed = 6.0
Config.FastMultiplier = 4.0
Config.SlowMultiplier = 0.25

-- Mouse sensitivity for rotation (higher = faster)
Config.MouseSensitivity = 6.0

-- Min/Max camera FOV (degrees) for zoom
Config.MinFov = 15.0
Config.MaxFov = 90.0
Config.FovStep = 2.0

-- Hide HUD/radar each frame while freecam is active
Config.HideHud = true

-- Disable player combat controls while active
Config.DisableCombat = true

-- Limit how far the camera can move from the anchor (player position on toggle)
Config.EnableDistanceLimits = true
Config.MinDistance = 1.0   -- meters (0 = no near limit)
Config.MaxDistance = 150.0 -- meters (set higher/lower to taste)


-- Optional: show an on-screen controls helper via lation_ui (if resource is running)
Config.UseLationUI = true

Config.LationUICompact = true
