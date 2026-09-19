local WorkbenchPlacement = {}

local function DefaultNatives()
    return {
        SetCoords = function(entity, x, y, z)
            SetEntityCoordsNoOffset(entity, x, y, z, false, false, false)
        end,
        SetHeading = SetEntityHeading,
        PlaceOnGround = PlaceObjectOnGroundProperly,
        GetCoords = GetEntityCoords,
        Freeze = FreezeEntityPosition,
        SetMission = function(entity)
            SetEntityAsMissionEntity(entity, true, true)
        end
    }
end

function WorkbenchPlacement.Place(prop, workbench, natives)
    natives = natives or DefaultNatives()
    local coords = workbench.coords
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    local zOffset = tonumber(workbench.zOffset) or 0.0
    local spawnHeight = math.max(0.0, tonumber(workbench.groundProbeHeight) or 1.0)

    -- Probe from above so the native can resolve the model's real bounding box.
    natives.SetCoords(prop, x, y, z + spawnHeight)
    natives.SetHeading(prop, tonumber(workbench.heading) or 0.0)
    local grounded = natives.PlaceOnGround(prop) == true

    local finalX, finalY, finalZ = x, y, z
    if grounded then
        local actual = natives.GetCoords(prop)
        finalX, finalY, finalZ = actual.x, actual.y, actual.z
    end
    natives.SetCoords(prop, finalX, finalY, finalZ + zOffset)
    natives.Freeze(prop, true)
    natives.SetMission(prop)
    return grounded
end

_G.WorkbenchPlacement = WorkbenchPlacement
return WorkbenchPlacement
