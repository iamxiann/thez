Database.PlayerOutfits = {}

function Database.PlayerOutfits.GetAllByIdentifier(identifier)
    return MySQL.query.await("SELECT * FROM player_outfits WHERE identifier = ?", {identifier})
end

function Database.PlayerOutfits.GetByID(id)
    return MySQL.single.await("SELECT * FROM player_outfits WHERE id = ?", {id})
end

function Database.PlayerOutfits.GetByOutfit(name, identifier) -- for validate duplicate name before insert
    return MySQL.single.await("SELECT * FROM player_outfits WHERE outfitname = ? AND identifier = ?", {name, identifier})
end

function Database.PlayerOutfits.Add(identifier, outfitName, model, components, props)
   return MySQL.insert.await("INSERT INTO player_outfits (identifier, outfitname, model, components, props) VALUES (?, ?, ?, ?, ?)", {
        identifier,
        outfitName,
        model,
        components,
        props
    })
end

function Database.PlayerOutfits.Update(outfitID, identifier, model, components, props)
    return MySQL.update.await("UPDATE player_outfits SET model = ?, components = ?, props = ? WHERE id = ? AND identifier = ?", {
        model,
        components,
        props,
        outfitID,
        identifier
    })
end

function Database.PlayerOutfits.DeleteByID(id, identifier)
    return MySQL.update.await("DELETE FROM player_outfits WHERE id = ? AND identifier = ?", { id, identifier })
end
