if not Framework.Corex() then return end

function Framework.GetPlayerID(src)
    local player = exports['corex-core']:GetPlayer(src)
    return player and player.identifier
end

function Framework.HasMoney(src, moneyType, amount)
    return Framework.GetPlayerID(src) ~= nil and type(amount) == 'number' and amount >= 0
        and exports['corex-core']:HasMoney(src, moneyType, amount)
end

function Framework.RemoveMoney(src, moneyType, amount)
    if not Framework.HasMoney(src, moneyType, amount) then return false end
    if amount == 0 then return true end
    return exports['corex-core']:RemoveMoney(src, moneyType, amount)
end

function Framework.GetJob(src)
    local player = exports['corex-core']:GetPlayer(src)
    return player and player.metadata.job or { name = 'unemployed', grade = { level = 0 }, onduty = false }
end

function Framework.GetGang(src)
    local player = exports['corex-core']:GetPlayer(src)
    return player and player.metadata.gang or { name = 'none', grade = { level = 0 } }
end

local saving = {}

function Framework.SaveAppearance(appearance, identifier)
    if type(identifier) ~= 'string' or not identifier:match('^steam:%x+$') then return false end
    if type(appearance) ~= 'table' or type(appearance.model) ~= 'string' or #appearance.model > 255 then return false end
    if type(appearance.components) ~= 'table' or type(appearance.props) ~= 'table' then return false end
    if saving[identifier] then return false end
    local encoded = json.encode(appearance)
    if #encoded > 65535 then return false end
    saving[identifier] = true
    local ok, success = pcall(MySQL.transaction.await, {
        { query = 'UPDATE playerskins SET active = 0 WHERE identifier = ?', values = { identifier } },
        { query = 'DELETE FROM playerskins WHERE identifier = ? AND model = ?', values = { identifier, appearance.model } },
        { query = 'INSERT INTO playerskins (identifier, model, skin, active) VALUES (?, ?, ?, 1)', values = { identifier, appearance.model, encoded } }
    })
    saving[identifier] = nil
    return ok and success == true
end

function Framework.GetAppearance(identifier, model)
    if not identifier then return end
    local result = Database.PlayerSkins.GetByIdentifier(identifier, model)
    if result then
        local ok, appearance = pcall(json.decode, result)
        if ok and type(appearance) == 'table' then return appearance end
    end
end

exports('GetAppearance', function(src)
    return Framework.GetAppearance(Framework.GetPlayerID(src))
end)

exports('DeleteAppearance', function(src)
    local identifier = Framework.GetPlayerID(src)
    if not identifier or saving[identifier] then return false end
    Database.PlayerSkins.DeleteByIdentifier(identifier)
    return true
end)

lib.callback.register('illenium-appearance:server:saveCharacter', function(source, appearance)
    local identifier = Framework.GetPlayerID(source)
    if not identifier or type(appearance) ~= 'table' then return false end
    local player = exports['corex-core']:GetPlayer(source)
    if not player then return false end
    if player.metadata.appearancePending ~= true and exports['corex-core']:GetPlayerState(source) ~= 'loading' then return false end
    if _G.IlleniumAppearanceCanSaveHead and not _G.IlleniumAppearanceCanSaveHead(source, appearance) then
        return false
    end
    local saved = Framework.SaveAppearance(appearance, identifier)
    local currentPlayer = exports['corex-core']:GetPlayer(source)
    if not currentPlayer or currentPlayer.identifier ~= identifier or currentPlayer.charid ~= player.charid or not saved then return false end
    exports['corex-core']:SetMetaData(source, 'appearancePending', false)
    exports['corex-core']:SavePlayer(source)
    return true
end)
