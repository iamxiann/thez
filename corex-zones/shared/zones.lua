--[[
    Builds real PolyZone objects from Config.SafeZones.

    This file runs as a shared_script, so BOTH client and server build the
    exact same set of zone objects independently from the same config data.
    PolyZone's isPointInside() is pure Lua math (no game natives), so this
    works safely on the server too -- which matters, because the server must
    NEVER trust the client's own "I'm in a safe zone" report. It keeps doing
    its own independent point-in-polygon check, same as it used to do its
    own independent distance check.
--]]

CorexZoneObjects = {}

local function BuildZoneObjects()
    CorexZoneObjects = {}

    if not Config.SafeZones then return end

    for i, zoneConfig in ipairs(Config.SafeZones) do
        if not zoneConfig.points or #zoneConfig.points < 3 then
            print(('[COREX-ZONES] ^1ERROR: Zone "%s" (#%d) needs at least 3 points, skipping^0')
                :format(zoneConfig.name or 'unnamed', i))
        else
            local ok, zoneObj = pcall(function()
                return PolyZone:Create(zoneConfig.points, {
                    name = zoneConfig.name or ('SafeZone_' .. i),
                    minZ = zoneConfig.minZ,
                    maxZ = zoneConfig.maxZ,
                    data = { configIndex = i },
                })
            end)

            if ok and zoneObj then
                CorexZoneObjects[i] = zoneObj
            else
                print(('[COREX-ZONES] ^1ERROR: Failed to build polygon zone "%s" (#%d)^0')
                    :format(zoneConfig.name or 'unnamed', i))
            end
        end
    end
end

BuildZoneObjects()

-- Returns the zone object (PolyZone instance) containing coords, and its
-- matching Config.SafeZones entry, or nil, nil if coords are in no zone.
function Corex_GetZoneObjectAt(coords)
    if not coords then return nil, nil end

    for i, zoneObj in pairs(CorexZoneObjects) do
        if zoneObj:isPointInside(coords) then
            return zoneObj, Config.SafeZones[i]
        end
    end

    return nil, nil
end

-- Simple boolean membership check (replaces the old radius-distance check).
-- Returns isInside (bool), zoneConfig (table or nil)
function Corex_IsCoordsInSafeZone(coords)
    local zoneObj, zoneConfig = Corex_GetZoneObjectAt(coords)
    return zoneObj ~= nil, zoneConfig
end
