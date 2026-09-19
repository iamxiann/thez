local outfitCache = {}
local uniformCache = {}

local function isNearSurgeon(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    for i = 1, #Config.Stores do
        local store = Config.Stores[i]
        if store.type == "surgeon" then
            local surgeonCoords = vector3(store.coords.x, store.coords.y, store.coords.z)
            if #(playerCoords - surgeonCoords) <= Config.SurgeonUseDistance then
                return true
            end
        end
    end

    return false
end

if GetResourceState("qbx_core") ~= "missing" then
    exports.qbx_core:CreateUseableItem(Config.SurgeonCost, function(source, item)
        if not isNearSurgeon(source) then
            lib.notify(source, {
                title = _L("menu.surgeonShopTitle"),
                description = "Tiket hanya dapat digunakan di lokasi surgeon.",
                type = "error",
                position = Config.NotifyOptions.position
            })
            return
        end

        if not exports.ox_inventory:RemoveItem(source, Config.SurgeonCost, 1, nil, item.slot) then
            return
        end

        TriggerClientEvent("illenium-appearance:client:OpenSurgeonShop", source, true)
    end)
end

local function getMoneyForShop(shopType)
    local money = 0
    if shopType == "clothing" then
        money = Config.ClothingCost
    elseif shopType == "barber" then
        money = Config.BarberCost
    elseif shopType == "tattoo" then
        money = Config.TattooCost
    elseif shopType == "surgeon" then
        money = Config.SurgeonCost
    end

    return money
end

local function getOutfitsForPlayer(identifier)
    outfitCache[identifier] = {}
    local result = Database.PlayerOutfits.GetAllByIdentifier(identifier)
    for i = 1, #result, 1 do
        outfitCache[identifier][#outfitCache[identifier] + 1] = {
            id = result[i].id,
            name = result[i].outfitname,
            model = result[i].model,
            components = json.decode(result[i].components),
            props = json.decode(result[i].props)
        }
    end
end

local function GenerateUniqueCode()
    local code, exists
    repeat
        code = GenerateNanoID(Config.OutfitCodeLength)
        exists = Database.PlayerOutfitCodes.GetByCode(code)
    until not exists
    return code
end

-- Callback(s)

lib.callback.register("illenium-appearance:server:generateOutfitCode", function(source, outfitID)
    local identifier = Framework.GetPlayerID(source)
    outfitID = tonumber(outfitID)
    if not identifier or not outfitID then return end
    local playerOutfit = Database.PlayerOutfits.GetByID(outfitID)
    if not playerOutfit or playerOutfit.identifier ~= identifier then return end
    local existingOutfitCode = Database.PlayerOutfitCodes.GetByOutfitID(outfitID)
    if not existingOutfitCode then
        local code = GenerateUniqueCode()
        local id = Database.PlayerOutfitCodes.Add(outfitID, code)
        if not id then
            print("Something went wrong while generating outfit code")
            return
        end
        return code
    end
    return existingOutfitCode.code
end)

lib.callback.register("illenium-appearance:server:importOutfitCode", function(source, outfitName, outfitCode)
    local identifier = Framework.GetPlayerID(source)
    local existingOutfitCode = Database.PlayerOutfitCodes.GetByCode(outfitCode)
    if not existingOutfitCode then
        return nil
    end

    local playerOutfit = Database.PlayerOutfits.GetByID(existingOutfitCode.outfitid)
    if not playerOutfit then
        return
    end

    if playerOutfit.identifier == identifier then return end -- Validation when someone tried to duplicate own outfit
    if Database.PlayerOutfits.GetByOutfit(outfitName, identifier) then return end -- Validation duplicate outfit name, if validate on local id, someone can "spam error" server-sided

    local id = Database.PlayerOutfits.Add(identifier, outfitName, playerOutfit.model, playerOutfit.components, playerOutfit.props)

    if not id then
        print("Something went wrong while importing the outfit")
        return
    end

    if outfitCache[identifier] == nil then getOutfitsForPlayer(identifier) end
    outfitCache[identifier][#outfitCache[identifier] + 1] = {
        id = id,
        name = outfitName,
        model = playerOutfit.model,
        components = json.decode(playerOutfit.components),
        props = json.decode(playerOutfit.props)
    }

    return true
end)

lib.callback.register("illenium-appearance:server:getAppearance", function(source, model)
    local identifier = Framework.GetPlayerID(source)
    if not identifier then return end
    local appearance = Framework.GetAppearance(identifier, model)

    if _G.IlleniumAppearanceCanSaveHead and not _G.IlleniumAppearanceCanSaveHead(source, appearance) then
        local headBlend = appearance and appearance.headBlend
        if headBlend then
            for _, key in ipairs({ "shapeFirst", "shapeSecond", "shapeThird" }) do
                if tonumber(headBlend[key]) and tonumber(headBlend[key]) > 45 then
                    headBlend[key] = 0
                end
            end
        end
    end

    return appearance
end)

lib.callback.register("illenium-appearance:server:hasMoney", function(source, shopType)
    local money = getMoneyForShop(shopType)
    if Framework.HasMoney(source, "cash", money) then
        return true, money
    else
        return false, money
    end
end)

lib.callback.register("illenium-appearance:server:payForTattoo", function(source, tattoo)
    local src = source
    local cost = tattoo.cost or Config.TattooCost

    if Framework.RemoveMoney(src, "cash", cost) then
        lib.notify(src, {
            title = _L("purchase.tattoo.success.title"),
            description = string.format(_L("purchase.tattoo.success.description"), tattoo.label, cost),
            type = "success",
            position = Config.NotifyOptions.position
        })
        return true
    else
        lib.notify(src, {
            title = _L("purchase.tattoo.failure.title"),
            description = _L("purchase.tattoo.failure.description"),
            type = "error",
            position = Config.NotifyOptions.position
        })
        return false
    end
end)

lib.callback.register("illenium-appearance:server:getOutfits", function(source)
    local identifier = Framework.GetPlayerID(source)
    if outfitCache[identifier] == nil then
        getOutfitsForPlayer(identifier)
    end
    return outfitCache[identifier]
end)

lib.callback.register("illenium-appearance:server:getManagementOutfits", function(source, mType, gender)
    local job = Framework.GetJob(source)
    if mType == "Gang" then
        job = Framework.GetGang(source)
    end

    local grade = tonumber(job.grade.level)
    local managementOutfits = {}
    local result = Database.ManagementOutfits.GetAllByJob(mType, job.name, gender)

    for i = 1, #result, 1 do
        if grade >= result[i].minrank then
            managementOutfits[#managementOutfits + 1] = {
                id = result[i].id,
                name = result[i].name,
                model = result[i].model,
                gender = result[i].gender,
                components = json.decode(result[i].components),
                props = json.decode(result[i].props)
            }
        end
    end
    return managementOutfits
end)

lib.callback.register("illenium-appearance:server:getUniform", function(source)
    return uniformCache[Framework.GetPlayerID(source)]
end)

RegisterServerEvent("illenium-appearance:server:saveAppearance", function(appearance)
    local src = source
    local identifier = Framework.GetPlayerID(src)
    if appearance ~= nil then
        if _G.IlleniumAppearanceCanSaveHead and not _G.IlleniumAppearanceCanSaveHead(src, appearance) then
            lib.notify(src, {
                title = "Head Menu",
                description = "Head ini tidak terdaftar untuk identifier kamu.",
                type = "error",
                position = Config.NotifyOptions.position
            })
            return
        end

        local saved = Framework.SaveAppearance(appearance, identifier)
        TriggerClientEvent("illenium-appearance:client:appearanceSaved", src, saved == true)
    end
end)

RegisterServerEvent("illenium-appearance:server:chargeCustomer", function(shopType)
    local src = source
    local money = getMoneyForShop(shopType)
    if Framework.RemoveMoney(src, "cash", money) then
        lib.notify(src, {
            title = _L("purchase.store.success.title"),
            description = string.format(_L("purchase.store.success.description"), money, shopType),
            type = "success",
            position = Config.NotifyOptions.position
        })
    else
        lib.notify(src, {
            title = _L("purchase.store.failure.title"),
            description = _L("purchase.store.failure.description"),
            type = "error",
            position = Config.NotifyOptions.position
        })
    end
end)

RegisterNetEvent("illenium-appearance:server:saveOutfit", function(name, model, components, props)
    local src = source
    local identifier = Framework.GetPlayerID(src)
    if outfitCache[identifier] == nil then
        getOutfitsForPlayer(identifier)
    end
    if model and components and props then
        local id = Database.PlayerOutfits.Add(identifier, name, model, json.encode(components), json.encode(props))
        if not id then
            return
        end
        outfitCache[identifier][#outfitCache[identifier] + 1] = {
            id = id,
            name = name,
            model = model,
            components = components,
            props = props
        }
        lib.notify(src, {
            title = _L("outfits.save.success.title"),
            description = string.format(_L("outfits.save.success.description"), name),
            type = "success",
            position = Config.NotifyOptions.position
        })
    end
end)

RegisterNetEvent("illenium-appearance:server:updateOutfit", function(id, model, components, props)
    local src = source
    local identifier = Framework.GetPlayerID(src)
    if outfitCache[identifier] == nil then
        getOutfitsForPlayer(identifier)
    end
    if model and components and props then
        if Database.PlayerOutfits.Update(tonumber(id), identifier, model, json.encode(components), json.encode(props)) < 1 then return end
        local outfitName = ""
        for i = 1, #outfitCache[identifier], 1 do
            local outfit = outfitCache[identifier][i]
            if outfit.id == id then
                outfit.model = model
                outfit.components = components
                outfit.props = props
                outfitName = outfit.name
                break
            end
        end
        lib.notify(src, {
            title = _L("outfits.update.success.title"),
            description = string.format(_L("outfits.update.success.description"), outfitName),
            type = "success",
            position = Config.NotifyOptions.position
        })
    end
end)

RegisterNetEvent("illenium-appearance:server:saveManagementOutfit", function(outfitData)
    local src = source
    local id = Database.ManagementOutfits.Add(outfitData)
    if not id then
        return
    end

    lib.notify(src, {
        title = _L("outfits.save.success.title"),
            description = string.format(_L("outfits.save.success.description"), outfitData.Name),
        type = "success",
        position = Config.NotifyOptions.position
    })
end)

RegisterNetEvent("illenium-appearance:server:deleteManagementOutfit", function(id)
    Database.ManagementOutfits.DeleteByID(id)
end)

RegisterNetEvent("illenium-appearance:server:syncUniform", function(uniform)
    local src = source
    uniformCache[Framework.GetPlayerID(src)] = uniform
end)

RegisterNetEvent("illenium-appearance:server:deleteOutfit", function(id)
    local src = source
    local identifier = Framework.GetPlayerID(src)
    id = tonumber(id)
    if not id or not Database.PlayerOutfits.GetByID(id) then return end
    if Database.PlayerOutfits.DeleteByID(id, identifier) < 1 then return end
    Database.PlayerOutfitCodes.DeleteByOutfitID(id)

    for k, v in ipairs(outfitCache[identifier] or {}) do
        if v.id == id then
            table.remove(outfitCache[identifier], k)
            break
        end
    end
end)

RegisterNetEvent("illenium-appearance:server:resetOutfitCache", function()
    local src = source
    local identifier = Framework.GetPlayerID(src)
    if identifier then
        outfitCache[identifier] = nil
    end
end)

RegisterNetEvent("illenium-appearance:server:ChangeRoutingBucket", function()
    local src = source
    SetPlayerRoutingBucket(src, src)
end)

RegisterNetEvent("illenium-appearance:server:ResetRoutingBucket", function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

if Config.EnablePedMenu then
    lib.addCommand("pedmenu", {
        help = _L("commands.pedmenu.title"),
        params = {
            {
                name = "playerID",
                type = "number",
                help = "Target player's server id",
                optional = true
            },
        },
        restricted = Config.PedMenuGroup
    }, function(source, args)
        local target = source
        if args.playerID then
            local identifier = Framework.GetPlayerID(args.playerID)
            if identifier then
                target = args.playerID
            else
                lib.notify(source, {
                    title = _L("commands.pedmenu.failure.title"),
                    description = _L("commands.pedmenu.failure.description"),
                    type = "error",
                    position = Config.NotifyOptions.position
                })
                return
            end
        end
        TriggerClientEvent("illenium-appearance:client:openClothingShopMenu", target, true)
    end)
end

if Config.EnableJobOutfitsCommand then
    lib.addCommand("joboutfits", { help = _L("commands.joboutfits.title"), }, function(source)
        TriggerClientEvent("illenium-apearance:client:outfitsCommand", source, true)
    end)

    lib.addCommand("gangoutfits", { help = _L("commands.gangoutfits.title"), }, function(source)
        TriggerClientEvent("illenium-apearance:client:outfitsCommand", source)
    end)
end

lib.addCommand("clearstuckprops", { help = _L("commands.clearstuckprops.title") }, function(source)
    TriggerClientEvent("illenium-appearance:client:ClearStuckProps", source)
end)

lib.versionCheck("iLLeniumStudios/illenium-appearance")
