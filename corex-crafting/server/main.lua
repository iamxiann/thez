local Corex = nil
local CraftingQueues = {}
local RecipeIndex = {}

local function Debug(msg)
    if Config.Debug then
        print('^5[COREX-CRAFTING] ^7' .. msg .. '^0')
    end
end

local function InitCorex()
    if Corex then return true end
    local ok, obj = pcall(function()
        return exports['corex-core']:GetCoreObject()
    end)
    if ok and obj then
        Corex = obj
        return true
    end
    return false
end

local function GetRecipeById(id)
    return RecipeIndex[id]
end

local function BuildRecipeIndex()
    for _, recipe in ipairs(Config.Recipes) do
        RecipeIndex[recipe.id] = recipe
    end
end

local function Notify(src, message, ntype)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = ntype or 'info' })
end

local function GetPlayerCoords(src)
    local ped = Corex.Functions.GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return Corex.Functions.GetCoords(ped)
end

local function IsNearWorkbench(src)
    local coords = GetPlayerCoords(src)
    if not coords then return false end

    local px, py, pz = coords.x or coords[1], coords.y or coords[2], coords.z or coords[3]

    for _, wb in ipairs(Config.Workbenches) do
        local wx, wy, wz = wb.coords.x, wb.coords.y, wb.coords.z
        local dx, dy, dz = px - wx, py - wy, pz - wz
        local distSq = dx * dx + dy * dy + dz * dz
        if distSq <= (wb.radius * wb.radius) then
            return true
        end
    end
    return false
end

local function HasBlueprint(src, recipeId)
    local ok, blueprints = pcall(function()
        return exports['corex-core']:GetMetaData(src, 'blueprints')
    end)
    if not ok or type(blueprints) ~= 'table' then return false end
    return blueprints[recipeId] == true
end

-- corex-skills hooks. All wrapped in pcall + neutral fallbacks so the
-- crafting resource keeps working when corex-skills is missing.
local NEUTRAL_CRAFT_MODS = {
    craftSpeed = 1.0, materialCost = 1.0, instaBuildChance = 0.0,
    unlocksRareRecipes = false
}

local function GetSkillMods(src)
    local ok, mods = pcall(function()
        return exports['corex-skills']:GetModifiers(src)
    end)
    if ok and type(mods) == 'table' then return mods end
    return NEUTRAL_CRAFT_MODS
end

-- Returns ok (bool), missingSkillId (string|nil) for recipe.requiresSkill /
-- recipe.requiresFlag style gates. Falls back to "ok" if corex-skills isn't
-- around so existing recipes never break.
local function PassesSkillGate(src, recipe)
    if not recipe then return true end
    local ok, allowed, _, missing = pcall(function()
        return exports['corex-skills']:CanCraftRecipe(src, recipe)
    end)
    if not ok then return true end
    if allowed == false then
        return false, missing
    end
    return true
end

-- Resolve the recipe's skill gate to a UI-friendly { id, name, met } payload
-- so the NUI can show "Requires: Master Crafter (locked)" instead of just
-- greying out the recipe with no explanation.
-- Returns nil for recipes with no skill gate.
local function ResolveSkillRequirement(src, recipe)
    if not recipe then return nil end

    -- requiresFlag: find the skill that grants this flag (e.g.
    -- 'unlocksRareRecipes' is granted by k_master / "Master Crafter").
    if recipe.requiresFlag then
        local ok, info = pcall(function()
            return exports['corex-skills']:GetSkillForFlag(recipe.requiresFlag)
        end)
        if ok and type(info) == 'table' and info.id then
            local mods = GetSkillMods(src)
            return {
                id   = info.id,
                name = info.name or info.id,
                path = info.path,
                met  = mods[recipe.requiresFlag] == true,
                flag = recipe.requiresFlag
            }
        end
    end

    -- requiresSkill: single id or array. Show the first unmet one for the
    -- detail panel; if all are met, show the last one as "met".
    if recipe.requiresSkill then
        local ids = type(recipe.requiresSkill) == 'table' and recipe.requiresSkill or { recipe.requiresSkill }
        local unlocked = {}
        local ok, list = pcall(function()
            return exports['corex-skills']:GetUnlockedSkills(src)
        end)
        if ok and type(list) == 'table' then
            for _, id in ipairs(list) do unlocked[id] = true end
        end

        local pickId = nil
        for _, id in ipairs(ids) do
            if not unlocked[id] then pickId = id; break end
        end
        if not pickId then pickId = ids[#ids] end  -- all met → show the last as 'met'

        local infoOk, info = pcall(function()
            return exports['corex-skills']:GetSkillInfo(pickId)
        end)
        if infoOk and type(info) == 'table' then
            return {
                id   = info.id,
                name = info.name or info.id,
                path = info.path,
                met  = unlocked[info.id] == true
            }
        end
        -- corex-skills missing: still surface the raw id so the UI can label it.
        return { id = pickId, name = pickId, met = false }
    end

    return nil
end

-- Apply the materialCost modifier to a recipe's material list. Returns a new
-- table so we never mutate Config.Recipes. The minimum is always 1 so we
-- don't accidentally make recipes free.
local function ScaleMaterials(materials, costMul)
    if not materials then return {} end
    if not costMul or costMul == 1.0 then return materials end
    local scaled = {}
    for i, mat in ipairs(materials) do
        local count = math.max(1, math.ceil((tonumber(mat.count) or 0) * costMul))
        scaled[i] = { name = mat.name, count = count }
    end
    return scaled
end

local function GetItemCount(src, itemName)
    local ok, count = pcall(function()
        return exports['corex-inventory']:GetItemCount(src, itemName)
    end)
    if ok and type(count) == 'number' then return count end
    return 0
end

local function HasItem(src, itemName, count)
    local ok, result = pcall(function()
        return exports['corex-inventory']:HasItem(src, itemName, count)
    end)
    return ok and result == true
end

local function RemoveItem(src, itemName, count)
    local ok, result = pcall(function()
        return exports['corex-inventory']:RemoveItem(src, itemName, count)
    end)
    return ok and result == true
end

local function AddItemWithMeta(src, itemName, count, metadata)
    local ok, result = pcall(function()
        return exports['corex-inventory']:AddItem(src, itemName, count, metadata)
    end)
    return ok and result == true
end

local function AddItem(src, itemName, count)
    local ok, result = pcall(function()
        return exports['corex-inventory']:AddItem(src, itemName, count)
    end)
    return ok and result == true
end

local function GetItemInfo(itemName)
    local ok, def = pcall(function()
        return exports['corex-inventory']:GetItemData(itemName)
    end)
    if ok and def then return def end
    if not Config.Debug then return nil end
    print('^3[COREX-CRAFTING] GetItemInfo("' .. tostring(itemName) .. '") = nil^0')
    return nil
end

local function GetPlayerMaterials(src, recipe)
    -- Show the same scaled cost the server will actually charge so the UI
    -- doesn't lie to players who unlocked k_material.
    local mods = GetSkillMods(src)
    local scaledMats = ScaleMaterials(recipe.materials, mods.materialCost or 1.0)

    local mats = {}
    for _, mat in ipairs(scaledMats) do
        local owned = GetItemCount(src, mat.name)
        local def = GetItemInfo(mat.name)
        local img = def and def.image or 'default.png'
        mats[#mats + 1] = {
            name = mat.name,
            label = def and def.label or mat.name,
            image = 'https://cfx-nui-corex-inventory/html/images/' .. img,
            required = mat.count,
            owned = owned
        }
    end
    return mats
end

local function CanCraftRecipe(src, recipe, atWorkbench)
    if recipe.requiresWorkbench and not atWorkbench then
        return false, 'workbench'
    end

    if recipe.blueprint and not HasBlueprint(src, recipe.id) then
        return false, 'blueprint'
    end

    -- Skill gate (recipe.requiresSkill / recipe.requiresFlag, e.g. 'k_master').
    local passes, missing = PassesSkillGate(src, recipe)
    if not passes then
        return false, 'skill', missing
    end

    -- Material check uses the scaled cost so a player with k_material can
    -- actually craft when they're below the base cost but above the discount.
    local mods = GetSkillMods(src)
    local scaledMats = ScaleMaterials(recipe.materials, mods.materialCost or 1.0)
    for _, mat in ipairs(scaledMats) do
        if not HasItem(src, mat.name, mat.count) then
            return false, 'materials'
        end
    end

    local queue = CraftingQueues[src]
    if queue and #queue >= Config.MaxQueueSize then
        return false, 'queue_full'
    end

    return true, nil
end

local function GetServerTimeMs()
    return os.time() * 1000
end

local function BuildStateForClient(src, atWorkbench)
    local recipes = {}
    local queue = CraftingQueues[src] or {}
    local now = GetServerTimeMs()

    -- Single skill-mod read per state build keeps every recipe consistent.
    local mods = GetSkillMods(src)
    local speedMul = math.max(0.1, tonumber(mods.craftSpeed) or 1.0)

    for _, recipe in ipairs(Config.Recipes) do
        local materials = GetPlayerMaterials(src, recipe)
        local needsBlueprint = recipe.blueprint and not HasBlueprint(src, recipe.id)
        local canCraft, lockReason = CanCraftRecipe(src, recipe, atWorkbench)
        local skillLocked = lockReason == 'skill'

        local resultDef = GetItemInfo(recipe.result.name)
        local resultLabel = resultDef and resultDef.label or recipe.label or recipe.result.name
        local resultImage = resultDef and resultDef.image or 'default.png'
        local resultRarity = resultDef and resultDef.rarity or 'common'

        recipes[#recipes + 1] = {
            id = recipe.id,
            label = recipe.label,
            description = recipe.description,
            category = recipe.category,
            duration = math.max(250, math.floor((tonumber(recipe.duration) or 0) / speedMul)),
            requiresWorkbench = recipe.requiresWorkbench,
            blueprint = recipe.blueprint,
            materials = materials,
            resultName = resultLabel,
            resultImage = 'https://cfx-nui-corex-inventory/html/images/' .. resultImage,
            resultCount = recipe.result.count,
            rarity = resultRarity,
            canCraft = canCraft,
            locked = needsBlueprint or skillLocked,
            skillLocked = skillLocked,
            skillRequirement = ResolveSkillRequirement(src, recipe)
        }
    end

    local queueData = {}
    for _, entry in ipairs(queue) do
        local elapsed = now - entry.startTime
        local completed = elapsed >= entry.duration

        local qResultDef = GetItemInfo(entry.resultName)
        local qResultLabel = qResultDef and qResultDef.label or entry.label or entry.resultName
        local qResultImg = qResultDef and qResultDef.image or 'default.png'

        queueData[#queueData + 1] = {
            recipeId = entry.recipeId,
            resultName = qResultLabel,
            resultImage = 'https://cfx-nui-corex-inventory/html/images/' .. qResultImg,
            startTime = entry.startTime,
            duration = entry.duration,
            completed = completed,
            elapsed = math.min(elapsed, entry.duration)
        }
    end

    return {
        recipes = recipes,
        queue = queueData,
        maxQueue = Config.MaxQueueSize,
        atWorkbench = atWorkbench
    }
end

local function SendState(src)
    local atWorkbench = IsNearWorkbench(src)
    local state = BuildStateForClient(src, atWorkbench)
    TriggerClientEvent('corex-crafting:client:updateState', src, state)
end

-- -------------------------------------------------
-- NET EVENTS
-- -------------------------------------------------

RegisterNetEvent('corex-crafting:server:getState', function()
    local src = source
    if not InitCorex() then
        CreateThread(function()
            for _ = 1, 10 do
                Wait(500)
                if InitCorex() and Corex.Functions.GetPlayer(src) then
                    SendState(src)
                    return
                end
            end
        end)
        return
    end

    local player = Corex.Functions.GetPlayer(src)
    if not player then
        CreateThread(function()
            for _ = 1, 10 do
                Wait(500)
                if Corex.Functions.GetPlayer(src) then
                    SendState(src)
                    return
                end
            end
        end)
        return
    end

    SendState(src)
end)

RegisterNetEvent('corex-crafting:server:startCraft', function(recipeId)
    local src = source
    if not InitCorex() then return end

    if type(recipeId) ~= 'string' then return end

    local player = Corex.Functions.GetPlayer(src)
    if not player then return end

    local recipe = GetRecipeById(recipeId)
    if not recipe then
        Debug('Invalid recipe: ' .. tostring(recipeId))
        return
    end

    local atWorkbench = IsNearWorkbench(src)

    if recipe.requiresWorkbench and not atWorkbench then
        Notify(src, Config.Notifications.needsWorkbench, 'error')
        SendState(src)
        return
    end

    if recipe.blueprint and not HasBlueprint(src, recipe.id) then
        Notify(src, Config.Notifications.needsBlueprint, 'error')
        SendState(src)
        return
    end

    -- Skill gate (lockable recipes / blueprints behind k_master / k_modder).
    local passes, missing = PassesSkillGate(src, recipe)
    if not passes then
        Notify(src, ('Locked: requires skill (%s)'):format(tostring(missing or '?')), 'error')
        SendState(src)
        return
    end

    if not CraftingQueues[src] then
        CraftingQueues[src] = {}
    end

    if #CraftingQueues[src] >= Config.MaxQueueSize then
        Notify(src, string.format(Config.Notifications.queueFull, Config.MaxQueueSize), 'error')
        SendState(src)
        return
    end

    -- Skill modifiers: materialCost (k_material), craftSpeed (k_quick),
    -- instaBuildChance (k_insta).
    local mods = GetSkillMods(src)
    local scaledMats = ScaleMaterials(recipe.materials, mods.materialCost or 1.0)

    for _, mat in ipairs(scaledMats) do
        if not HasItem(src, mat.name, mat.count) then
            Notify(src, Config.Notifications.missingMaterials, 'error')
            SendState(src)
            return
        end
    end

    -- k_insta: 20% chance to skip the material cost AND the wait timer.
    local instaChance = tonumber(mods.instaBuildChance) or 0
    local instaProc   = instaChance > 0 and math.random() < instaChance

    local materialsRemoved = {}
    if not instaProc then
        for _, mat in ipairs(scaledMats) do
            local removed = RemoveItem(src, mat.name, mat.count)
            if not removed then
                for _, restored in ipairs(materialsRemoved) do
                    AddItem(src, restored.name, restored.count)
                end
                Notify(src, Config.Notifications.missingMaterials, 'error')
                SendState(src)
                return
            end
            materialsRemoved[#materialsRemoved + 1] = { name = mat.name, count = mat.count }
        end
    end

    -- Apply craftSpeed modifier (k_quick: 1.25 = 25% faster). Floor to ms,
    -- never below 250 ms so animations still play.
    local speedMul = math.max(0.1, tonumber(mods.craftSpeed) or 1.0)
    local duration = math.max(250, math.floor((tonumber(recipe.duration) or 0) / speedMul))
    if instaProc then
        duration = 250
        Notify(src, 'Insta-Build! Recipe completed instantly.', 'success')
    end

    local entry = {
        recipeId = recipe.id,
        label = recipe.label,
        startTime = GetServerTimeMs(),
        duration = duration,
        completed = false,
        resultName = recipe.result.name,
        resultCount = recipe.result.count
    }

    CraftingQueues[src][#CraftingQueues[src] + 1] = entry

    Debug('Player ' .. src .. ' started crafting: ' .. recipe.label)
    Notify(src, Config.Notifications.craftStarted, 'info')
    SendState(src)
end)

RegisterNetEvent('corex-crafting:server:takeCraft', function(queueIndex)
    local src = source
    if not InitCorex() then return end

    queueIndex = tonumber(queueIndex)
    if not queueIndex or queueIndex ~= queueIndex then return end
    queueIndex = math.floor(queueIndex)
    if queueIndex < 1 or queueIndex > 1000 then return end

    local player = Corex.Functions.GetPlayer(src)
    if not player then return end

    local queue = CraftingQueues[src]
    if not queue then return end

    if queueIndex > #queue then return end

    local entry = queue[queueIndex]
    if not entry then return end

    if entry.collecting then return end
    entry.collecting = true

    local now = GetServerTimeMs()
    local elapsed = now - entry.startTime
    if elapsed < entry.duration then
        entry.collecting = false
        Debug('Player ' .. src .. ' tried to take unfinished craft')
        return
    end

    -- k_solid / k_master: stamp the crafted item with a qualityBonus metadata
    -- so consumers (corex-survival item handlers) heal/cure for more.
    --   buildDurability = 1.30 (k_solid)        -> qualityBonus = 0.30
    --   buildDurability = 1.15 (k_master)        -> qualityBonus = 0.15
    --   both unlocked   -> aggregated 1.30 * 1.15 = 1.495 -> qualityBonus ≈ 0.50
    local mods = GetSkillMods(src)
    local quality = (tonumber(mods.buildDurability) or 1.0) - 1.0
    local addedMeta = nil
    if quality > 0.001 then
        addedMeta = { qualityBonus = quality, crafter = src }
    end

    local added
    if addedMeta then
        added = AddItemWithMeta(src, entry.resultName, entry.resultCount, addedMeta)
    else
        added = AddItem(src, entry.resultName, entry.resultCount)
    end
    if not added then
        entry.collecting = false
        Notify(src, Config.Notifications.noSpace, 'error')
        return
    end

    table.remove(queue, queueIndex)

    Debug('Player ' .. src .. ' collected: ' .. entry.label .. (addedMeta and (' [+' .. math.floor(quality*100) .. '% quality]') or ''))
    Notify(src, Config.Notifications.craftTaken, 'success')
    SendState(src)
end)

RegisterNetEvent('corex-crafting:server:cancelCraft', function(queueIndex)
    local src = source
    if not InitCorex() then return end

    queueIndex = tonumber(queueIndex)
    if not queueIndex then return end

    local player = Corex.Functions.GetPlayer(src)
    if not player then return end

    local queue = CraftingQueues[src]
    if not queue then return end

    if queueIndex < 1 or queueIndex > #queue then return end

    local entry = queue[queueIndex]
    if not entry then return end

    local now = GetServerTimeMs()
    local elapsed = now - entry.startTime
    if elapsed >= entry.duration then
        Debug('Player ' .. src .. ' tried to cancel completed craft')
        return
    end

    local recipe = GetRecipeById(entry.recipeId)
    if recipe then
        for _, mat in ipairs(recipe.materials) do
            local refund = math.floor(mat.count * 0.5)
            if refund > 0 then
                AddItem(src, mat.name, refund)
            end
        end
    end

    table.remove(queue, queueIndex)

    Debug('Player ' .. src .. ' cancelled craft: ' .. entry.label)
    Notify(src, 'Craft cancelled. 50% materials refunded.', 'info')
    SendState(src)
end)

RegisterNetEvent('corex-crafting:server:useBlueprint', function(blueprintItemName)
    local src = source
    if not InitCorex() then return end

    if type(blueprintItemName) ~= 'string' or #blueprintItemName == 0 or #blueprintItemName > 100 then return end
    if not string.match(blueprintItemName, '^blueprint_[%w_]+$') then
        Notify(src, 'Invalid blueprint name', 'error')
        return
    end

    local player = Corex.Functions.GetPlayer(src)
    if not player then return end

    if not HasItem(src, blueprintItemName, 1) then
        Notify(src, 'You do not have this blueprint', 'error')
        return
    end

    local recipeId = nil
    for _, recipe in ipairs(Config.Recipes) do
        if recipe.blueprint and type(recipe.id) == 'string' then
            local expectedBlueprintName = 'blueprint_' .. recipe.id:gsub('craft_', '')
            if blueprintItemName == expectedBlueprintName then
                recipeId = recipe.id
                break
            end
        end
    end

    if not recipeId then
        Notify(src, 'Invalid blueprint', 'error')
        return
    end

    if HasBlueprint(src, recipeId) then
        Notify(src, 'You already know this recipe', 'info')
        return
    end

    local removed = RemoveItem(src, blueprintItemName, 1)
    if not removed then
        Notify(src, 'Failed to use blueprint', 'error')
        return
    end

    local ok, blueprints = pcall(function()
        return exports['corex-core']:GetMetaData(src, 'blueprints')
    end)

    if not ok or type(blueprints) ~= 'table' then
        blueprints = {}
    end

    blueprints[recipeId] = true

    pcall(function()
        exports['corex-core']:SetMetaData(src, 'blueprints', blueprints)
    end)

    local recipe = GetRecipeById(recipeId)
    local label = recipe and recipe.label or recipeId
    Debug('Player ' .. src .. ' unlocked blueprint: ' .. label)
    Notify(src, 'Blueprint unlocked: ' .. label, 'success')
    SendState(src)
end)

-- -------------------------------------------------
-- COMPLETION CHECK LOOP
-- -------------------------------------------------

-- Completion check loop — back off when nothing is queued to avoid
-- a pointless 1Hz scan on an empty table.
CreateThread(function()
    while true do
        local now = GetServerTimeMs()
        local nextCompletionAt = nil

        for src, queue in pairs(CraftingQueues) do
            for i = 1, #queue do
                local entry = queue[i]
                if not entry.completed then
                    local completeAt = entry.startTime + entry.duration
                    if now >= completeAt then
                        entry.completed = true
                        TriggerClientEvent('corex-crafting:client:craftComplete', src, entry.recipeId)
                        Notify(src, Config.Notifications.craftComplete, 'success')
                        Debug('Craft completed for player ' .. src .. ': ' .. entry.label)
                    elseif not nextCompletionAt or completeAt < nextCompletionAt then
                        nextCompletionAt = completeAt
                    end
                end
            end
        end

        if nextCompletionAt then
            local delta = nextCompletionAt - GetServerTimeMs()
            Wait(math.max(500, math.min(delta, 15000)))
        else
            Wait(10000)
        end
    end
end)

-- -------------------------------------------------
-- CLEANUP
-- -------------------------------------------------

AddEventHandler('playerDropped', function()
    local src = source
    if CraftingQueues[src] then
        Debug('Cleaned up crafting queue for dropped player ' .. src)
        CraftingQueues[src] = nil
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    BuildRecipeIndex()
    InitCorex()
    Debug('Crafting system initialized with ' .. #Config.Recipes .. ' recipes')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CraftingQueues = {}
end)
