Database.PlayerSkins = {}

function Database.PlayerSkins.UpdateActiveField(identifier, active)
    MySQL.update.await("UPDATE playerskins SET active = ? WHERE identifier = ?", {active, identifier}) -- Make all the skins inactive / active
end

function Database.PlayerSkins.DeleteByModel(identifier, model)
    MySQL.query.await("DELETE FROM playerskins WHERE identifier = ? AND model = ?", {identifier, model})
end

function Database.PlayerSkins.Add(identifier, model, appearance, active)
    MySQL.insert.await("INSERT INTO playerskins (identifier, model, skin, active) VALUES (?, ?, ?, ?)", {identifier, model, appearance, active})
end

function Database.PlayerSkins.GetByIdentifier(identifier, model)
    local query = "SELECT skin FROM playerskins WHERE identifier = ?"
    local queryArgs = {identifier}
    if model ~= nil then
        query = query .. " AND model = ?"
        queryArgs[#queryArgs + 1] = model
    else
        query = query .. " AND active = ?"
        queryArgs[#queryArgs + 1] = 1
    end
    return MySQL.scalar.await(query, queryArgs)
end

function Database.PlayerSkins.DeleteByIdentifier(identifier)
    MySQL.query.await("DELETE FROM playerskins WHERE identifier = ?", { identifier })
end

function Database.PlayerSkins.GetAll()
    return MySQL.query.await("SELECT * FROM playerskins")
end
