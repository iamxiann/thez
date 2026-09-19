local creator
local freecam = exports['fivem-freecam']
local help = '[C] Tambah/hapus titik | [K] Edit titik | [N] Batal edit\n[Scroll] Tinggi | [H] Selesai | [Backspace] Batal'

local function stopCreator()
    if not creator then return end
    local settings = creator.settings
    creator = nil
    lib.hideTextUI()
    if GetResourceState('fivem-freecam') == 'started' then
        freecam:SetActive(false)
        for key, value in pairs(settings) do freecam:SetKeyboardSetting(key, value) end
    end
end

local function bounds(points, height)
    local low, high = math.huge, -math.huge
    for _, point in ipairs(points) do
        low = math.min(low, point.z)
        high = math.max(high, point.z)
    end
    return low, high + height
end

local function finishCreator()
    local points = creator.points
    if creator.edit then
        return lib.notify({description = 'Selesaikan edit dengan K atau batalkan dengan N.', type = 'error'})
    end
    local area = 0
    for i, point in ipairs(points) do
        local nextPoint = points[i % #points + 1]
        area = area + point.x * nextPoint.y - nextPoint.x * point.y
    end
    if #points < 3 or math.abs(area) < 0.01 then
        return lib.notify({description = 'Minimal 3 titik yang membentuk area.', type = 'error'})
    end
    -- Non-adjacent edges must not cross or touch.
    local function cross(a, b, c)
        return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    end
    for i, a in ipairs(points) do
        local b = points[i % #points + 1]
        for j = i + 1, #points do
            if j ~= i + 1 and not (i == 1 and j == #points) then
                local c, d = points[j], points[j % #points + 1]
                if math.max(a.x, b.x) >= math.min(c.x, d.x)
                    and math.max(c.x, d.x) >= math.min(a.x, b.x)
                    and math.max(a.y, b.y) >= math.min(c.y, d.y)
                    and math.max(c.y, d.y) >= math.min(a.y, b.y)
                    and cross(a, b, c) * cross(a, b, d) <= 0
                    and cross(c, d, a) * cross(c, d, b) <= 0 then
                    return lib.notify({description = 'Garis zona saling berpotongan. Edit atau hapus titik.', type = 'error'})
                end
            end
        end
    end
    local minZ, maxZ = bounds(points, creator.height)
    local lines = {'{', ('    name = %q,'):format(creator.name), '    points = {'}
    for _, point in ipairs(points) do
        lines[#lines + 1] = ('        vector2(%.4f, %.4f),'):format(point.x, point.y)
    end
    lines[#lines + 1] = '    },'
    lines[#lines + 1] = ('    minZ = %.4f,\n    maxZ = %.4f,'):format(minZ, maxZ)
    lines[#lines + 1] = ('    blip = { enabled = true, sprite = 487, color = 2, scale = 1.0, label = %q },'):format(creator.name)
    lines[#lines + 1] = '},'
    local output = table.concat(lines, '\n')
    stopCreator()
    print('[COREX-ZONES] Paste into Config.SafeZones:\n' .. output)
    lib.setClipboard(output)
    lib.notify({description = 'Zona disalin ke clipboard dan F8. Tempel ke Config.SafeZones, lalu restart corex-zones.', duration = 10000})
end

RegisterNetEvent('corex-zones:client:startCreator', function(name)
    if source ~= 65535 or creator then return end
    if GetResourceState('fivem-freecam') ~= 'started' then
        return lib.notify({description = 'Jalankan fivem-freecam terlebih dahulu.', type = 'error'})
    end
    if freecam:IsActive() then
        return lib.notify({description = 'Tutup freecam yang sedang aktif terlebih dahulu.', type = 'error'})
    end
    creator = {name = name, points = {}, height = 5.0, settings = {}}
    for key, value in pairs({BASE_MOVE_MULTIPLIER = 0.1, FAST_MOVE_MULTIPLIER = 2, SLOW_MOVE_MULTIPLIER = 2}) do
        creator.settings[key] = freecam:GetKeyboardSetting(key)
        freecam:SetKeyboardSetting(key, value)
    end
    freecam:SetActive(true)
    freecam:SetFov(45.0)
    lib.showTextUI(help)
    CreateThread(function()
        while creator do
            Wait(0)
            if not creator then break end
            if GetResourceState('fivem-freecam') ~= 'started' then stopCreator() break end
            local position = freecam:GetPosition()
            if creator.ray then
                local status, hit, coords = GetShapeTestResult(creator.ray)
                if status ~= 1 then
                    creator.ray = nil
                    creator.cursor = status == 2 and (hit == true or hit == 1) and coords or nil
                end
            end
            if not creator.ray then
                local target = freecam:GetTarget(100.0)
                creator.ray = StartShapeTestRay(position.x, position.y, position.z, target.x, target.y, target.z, 1, PlayerPedId(), 7)
            end
            local cursor = creator.cursor
            creator.nearest = nil
            if cursor then
                for i, point in ipairs(creator.points) do
                    if #(point - cursor) < 0.5 then creator.nearest = i break end
                end
                DrawLine(position.x, position.y, position.z, cursor.x, cursor.y, cursor.z, 0, 255, 0, 255)
                DrawMarker(28, cursor.x, cursor.y, cursor.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 0.15,
                    creator.nearest and 255 or 0, creator.nearest and 0 or 255, 0, 255, false, false, 2, false, nil, nil, false)
            end
            local low, high = bounds(creator.points, creator.height)
            for i, point in ipairs(creator.points) do
                local nextPoint = creator.points[i % #creator.points + 1]
                local green = creator.edit == i and 255 or 0
                DrawLine(point.x, point.y, low, point.x, point.y, high, 255, green, 0, 255)
                DrawLine(point.x, point.y, low, nextPoint.x, nextPoint.y, low, 255, green, 0, 255)
                DrawLine(point.x, point.y, high, nextPoint.x, nextPoint.y, high, 255, green, 0, 255)
                DrawPoly(point.x, point.y, low, nextPoint.x, nextPoint.y, low, point.x, point.y, high, 255, 0, 0, 80)
                DrawPoly(nextPoint.x, nextPoint.y, low, point.x, point.y, low, point.x, point.y, high, 255, 0, 0, 80)
                DrawPoly(point.x, point.y, high, nextPoint.x, nextPoint.y, low, nextPoint.x, nextPoint.y, high, 255, 0, 0, 80)
                DrawPoly(nextPoint.x, nextPoint.y, low, point.x, point.y, high, nextPoint.x, nextPoint.y, high, 255, 0, 0, 80)
            end
            if IsDisabledControlJustPressed(0, 14) then creator.height = math.max(0.5, creator.height - 0.5) end
            if IsDisabledControlJustPressed(0, 15) then creator.height = math.min(1000.0, creator.height + 0.5) end
            if IsDisabledControlJustPressed(0, 306) then creator.edit = nil end
            if IsDisabledControlJustPressed(0, 177) then stopCreator()
            elseif IsDisabledControlJustPressed(0, 104) then finishCreator() end
        end
    end)
end)

RegisterCommand('corex_zone_point', function()
    if not creator or not creator.cursor or creator.edit then return end
    if creator.nearest then
        table.remove(creator.points, creator.nearest)
    elseif #creator.points < 128 then
        creator.points[#creator.points + 1] = creator.cursor
    end
end, false)
RegisterKeyMapping('corex_zone_point', 'COREX Zones: tambah/hapus titik', 'keyboard', 'C')

RegisterCommand('corex_zone_edit', function()
    if not creator or not creator.cursor then return end
    if creator.edit then
        if creator.nearest and creator.nearest ~= creator.edit then return end
        creator.points[creator.edit] = creator.cursor
        creator.edit = nil
    else
        creator.edit = creator.nearest
    end
end, false)
RegisterKeyMapping('corex_zone_edit', 'COREX Zones: edit titik', 'keyboard', 'K')
RegisterCommand('czcancel', stopCreator, false)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() or resource == 'fivem-freecam' then stopCreator() end
end)
