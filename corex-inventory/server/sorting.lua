InventorySorting = {}

function InventorySorting.QuickSlotItems(items, getDefinition, cols, rows)
    local covered, anchors, locked = {}, {}, {}
    for index, item in ipairs(items) do
        local definition = getDefinition(item.name)
        local w = definition.size and definition.size.w or 1
        local h = definition.size and definition.size.h or 1
        local anchor = item.x .. ',' .. item.y
        anchors[anchor] = index
        for y = item.y, item.y + h - 1 do
            for x = item.x, item.x + w - 1 do
                local key = x .. ',' .. y
                if key ~= anchor then covered[key] = true end
            end
        end
    end

    local quickSlot = 1
    for y = 1, rows do
        if quickSlot > 6 then break end
        for x = 1, cols do
            if quickSlot > 6 then break end
            local key = x .. ',' .. y
            if not covered[key] then
                if anchors[key] then locked[anchors[key]] = true end
                quickSlot = quickSlot + 1
            end
        end
    end
    return locked
end

-- Plan against server-owned data without changing any item until all items fit.
function InventorySorting.Plan(items, getDefinition, cols, rows, locked)
    if type(items) ~= 'table' or type(cols) ~= 'number' or type(rows) ~= 'number'
        or cols ~= math.floor(cols) or rows ~= math.floor(rows)
        or cols < 1 or rows < 1 or cols > 64 or rows > 64 then
        return nil, 'Invalid inventory grid.'
    end

    local ordered, area = {}, 0
    for index, item in ipairs(items) do
        if index > cols * rows or type(item) ~= 'table' or type(item.name) ~= 'string' then
            return nil, 'Invalid inventory items.'
        end
        local definition = getDefinition(item.name)
        if not definition then return nil, 'An item definition is missing.' end
        local w = definition.size and definition.size.w or 1
        local h = definition.size and definition.size.h or 1
        if type(w) ~= 'number' or type(h) ~= 'number' or w ~= math.floor(w) or h ~= math.floor(h)
            or w < 1 or h < 1 or w > cols or h > rows then
            return nil, 'An item does not fit this grid.'
        end
        area = area + w * h
        if not (locked and locked[index]) then
            ordered[#ordered + 1] = { index = index, w = w, h = h, name = string.lower(definition.label or item.name) }
        end
    end
    if area > cols * rows then return nil, 'Not enough space to sort these items.' end

    local checks = 0
    -- Different packing orders help mixed rectangular items fit without rotation.
    for strategy = 1, 3 do
        table.sort(ordered, function(a, b)
            local firstA = strategy == 1 and a.w * a.h or strategy == 2 and a.h or a.w
            local firstB = strategy == 1 and b.w * b.h or strategy == 2 and b.h or b.w
            if firstA ~= firstB then return firstA > firstB end
            if a.h ~= b.h then return a.h > b.h end
            if a.w ~= b.w then return a.w > b.w end
            if a.name ~= b.name then return a.name < b.name end
            return a.index < b.index
        end)
        local occupied, positions, complete = {}, {}, true
        if locked then
            for index in pairs(locked) do
                local item = items[index]
                local definition = getDefinition(item.name)
                local w = definition.size and definition.size.w or 1
                local h = definition.size and definition.size.h or 1
                if type(item.x) ~= 'number' or type(item.y) ~= 'number'
                    or item.x ~= math.floor(item.x) or item.y ~= math.floor(item.y)
                    or item.x < 1 or item.y < 1
                    or item.x + w - 1 > cols or item.y + h - 1 > rows then
                    complete = false
                    break
                end
                positions[index] = { x = item.x, y = item.y }
                for dy = 0, h - 1 do
                    for dx = 0, w - 1 do
                        local key = (item.y + dy - 1) * cols + item.x + dx
                        if occupied[key] then complete = false break end
                        occupied[key] = true
                    end
                    if not complete then break end
                end
                if not complete then break end
            end
        end
        if complete then
            for _, entry in ipairs(ordered) do
                local position
                for y = 1, rows - entry.h + 1 do
                    for x = 1, cols - entry.w + 1 do
                        local free = true
                        for dy = 0, entry.h - 1 do
                            for dx = 0, entry.w - 1 do
                                checks = checks + 1
                                if checks > 250000 then return nil, 'Unable to sort this layout. Items were not moved.' end
                                if occupied[(y + dy - 1) * cols + x + dx] then free = false break end
                            end
                            if not free then break end
                        end
                        if free then position = { x = x, y = y } break end
                    end
                    if position then break end
                end
                if not position then complete = false break end
                positions[entry.index] = position
                for dy = 0, entry.h - 1 do
                    for dx = 0, entry.w - 1 do
                        occupied[(position.y + dy - 1) * cols + position.x + dx] = true
                    end
                end
            end
        end
        if complete then return positions end
    end
    return nil, 'Unable to fit a sorted layout. Items were not moved.'
end
