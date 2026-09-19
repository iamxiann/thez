if not Framework.QBCore() then return end

local QBCore = exports["qb-core"]:GetCoreObject()

function Framework.GetPlayerID(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        return Player.PlayerData.license or GetPlayerIdentifierByType(src, "license")
    end
end

function Framework.HasMoney(src, type, money)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.money[type] >= money
end

function Framework.RemoveMoney(src, type, money)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.Functions.RemoveMoney(type, money)
end

function Framework.GetJob(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.job
end

function Framework.GetGang(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.gang
end

function Framework.SaveAppearance(appearance, identifier)
    Database.PlayerSkins.UpdateActiveField(identifier, 0)
    Database.PlayerSkins.DeleteByModel(identifier, appearance.model)
    Database.PlayerSkins.Add(identifier, appearance.model, json.encode(appearance), 1)
end

function Framework.GetAppearance(identifier, model)
    local result = Database.PlayerSkins.GetByIdentifier(identifier, model)
    if result then
        return json.decode(result)
    end
end
