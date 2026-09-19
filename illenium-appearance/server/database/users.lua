Database.Users = {}

function Database.Users.UpdateSkinForUser(identifier, skin)
    return MySQL.update.await("UPDATE users SET skin = ? WHERE identifier = ?", {skin, identifier})
end

function Database.Users.GetSkinByIdentifier(identifier)
    return MySQL.single.await("SELECT skin FROM users WHERE identifier = ?", {identifier})
end

function Database.Users.GetAll()
    return MySQL.query.await("SELECT * FROM users")
end
