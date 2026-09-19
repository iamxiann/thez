local utils = require 'client.utils'

local function getCore()
    local ok, core = pcall(function()
        return exports['corex-core']:GetCoreObject()
    end)

    if ok and core and core.Functions then
        return core
    end
end

local Corex = getCore()

AddEventHandler('corex:client:coreReady', function(coreObj)
    if coreObj and coreObj.Functions then
        Corex = coreObj
    end
end)

local playerItems = utils.getItems()

local function rebuildItemCounts(inventory)
    table.wipe(playerItems)

    if type(inventory) ~= 'table' then
        return
    end

    for i = 1, #inventory do
        local item = inventory[i]
        local name = item and item.name
        local count = item and item.count

        if type(name) == 'string' and name ~= '' then
            playerItems[name] = (playerItems[name] or 0) + (tonumber(count) or 0)
        end
    end
end

-- RegisterNetEvent diperlukan agar FiveM mengizinkan event ini
-- diterima dari server (via TriggerClientEvent). Tanpanya, FiveM
-- memblokir event dan log "was not safe for net".
RegisterNetEvent('corex-inventory:client:syncInventory')
AddEventHandler('corex-inventory:client:syncInventory', function(inventory)
    rebuildItemCounts(inventory)
end)

local function normalizeGroups(meta)
    if type(meta) ~= 'table' then return {} end

    -- We accept several shapes:
    -- meta.job / meta.job2: string or { name=string, grade=number }
    -- meta.group: string
    -- meta.groups: { [name]=true|number|{grade=?} } OR array of names
    local groups = {}

    local function addGroup(name, grade)
        if type(name) ~= 'string' or name == '' then return end
        groups[#groups + 1] = { name = name, grade = tonumber(grade) or 0 }
    end

    local function addAny(value)
        if type(value) == 'string' then
            addGroup(value, 0)
        elseif type(value) == 'table' then
            if type(value.name) == 'string' then
                addGroup(value.name, value.grade)
            end
        end
    end

    addAny(meta.job)
    addAny(meta.job2)
    addAny(meta.group)

    if type(meta.groups) == 'table' then
        if table.type(meta.groups) == 'array' then
            for i = 1, #meta.groups do
                addAny(meta.groups[i])
            end
        else
            for name, v in pairs(meta.groups) do
                if v == true then
                    addGroup(name, 0)
                elseif type(v) == 'number' then
                    addGroup(name, v)
                elseif type(v) == 'table' then
                    addGroup(name, v.grade)
                end
            end
        end
    end

    return groups
end

---@diagnostic disable-next-line: duplicate-set-field
function utils.hasPlayerGotGroup(filter)
    if not filter then return true end

    local core = Corex or getCore()
    if not core or not core.Functions or type(core.Functions.GetMetaData) ~= 'function' then
        return true
    end

    local ok, meta = pcall(core.Functions.GetMetaData)
    if not ok then return true end

    local groups = normalizeGroups(meta)
    if #groups == 0 then return false end

    local filterType = type(filter)

    if filterType == 'string' then
        for i = 1, #groups do
            if groups[i].name == filter then
                return true
            end
        end
        return false
    end

    if filterType ~= 'table' then
        return false
    end

    local tableType = table.type(filter)

    if tableType == 'array' then
        for j = 1, #filter do
            local name = filter[j]
            if type(name) == 'string' then
                for i = 1, #groups do
                    if groups[i].name == name then
                        return true
                    end
                end
            end
        end
        return false
    end

    -- hash: { groupName = minGrade }
    for name, minGrade in pairs(filter) do
        if type(name) == 'string' then
            local required = tonumber(minGrade) or 0
            for i = 1, #groups do
                local g = groups[i]
                if g.name == name and (g.grade or 0) >= required then
                    return true
                end
            end
        end
    end

    return false
end
