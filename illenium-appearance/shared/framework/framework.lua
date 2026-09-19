Framework = {}

function Framework.Corex()
    return GetResourceState("corex-core") ~= "missing"
end

function Framework.ESX()
    return not Framework.Corex() and GetResourceState("es_extended") ~= "missing"
end

function Framework.QBCore()
    return not Framework.Corex() and GetResourceState("qb-core") ~= "missing"
end

function Framework.Ox()
    return not Framework.Corex() and GetResourceState("ox_core") ~= "missing"
end
