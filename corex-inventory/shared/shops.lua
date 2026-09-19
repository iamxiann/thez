if not Shops then
    Shops = {}
end

Shops["Weapon Vendor"] = {
    label = "Weapon Shop",
    type = "weapon",
    npc = {
        model = "s_m_y_ammucity_01",
        coords = vector4(-1240.0162, 7.6883, 46.7687, 245.4802),
        scenario = "WORLD_HUMAN_CLIPBOARD",
        icon = "fa-gun",
        interactLabel = "Weapon Shop",
        interactDistance = 2.5
    },
    blip = {
        enabled = true,
        sprite = 110,
        color = 1,
        scale = 0.5,
        label = "Weapon Shop"
    },
    items = {
        {name = "WEAPON_WRENCH", price = 550, currency = "cash"},
        {name = "WEAPON_STONE_HATCHET", price = 1750, currency = "cash"},
        {name = "WEAPON_GOLFCLUB", price = 500, currency = "cash"},
        {name = "WEAPON_CROWBAR", price = 700, currency = "cash"},
        {name = "WEAPON_DAGGER", price = 1400, currency = "cash"},
        {name = "WEAPON_BAT", price = 450, currency = "cash"},
        {name = "WEAPON_STUNROD", price = 1200, currency = "cash"},
        {name = "WEAPON_HATCHET", price = 950, currency = "cash"}
    }
}

Shops["Vehicle Dealer"] = {
    label = "Bike Rental",
    type = "vehicle",
    catalogId = "bike_rental",
    npc = {
        model = "s_m_m_autoshop_02",
        coords = vector4(-1352.4989, 124.4027, 55.2387, 2.9605),
        scenario = "WORLD_HUMAN_CLIPBOARD",
        icon = "fa-car",
        interactLabel = "Bike Rental",
        interactDistance = 2.5
    },
    spawnPoint = vector4(-1356.6730, 130.1151, 56.2388, 273.8515),
    blip = {
        enabled = true,
        sprite = 326,
        color = 3,
        scale = 0.5,
        label = "Bike Rental"
    },
    items = {}
}

local shopCount = 0
for _ in pairs(Shops) do shopCount = shopCount + 1 end
print('^2[COREX-INVENTORY] Shops configuration loaded (' .. shopCount .. ' shops)^0')
