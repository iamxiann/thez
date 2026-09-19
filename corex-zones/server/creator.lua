-- Restricted server command: grant command.czcreate to the appropriate admin group.
RegisterCommand('czcreate', function(source, args)
    if source <= 0 then return end
    local name = table.concat(args, ' '):sub(1, 80):gsub('[%c]', '')
    if name == '' then name = 'New Safe Zone' end
    TriggerClientEvent('corex-zones:client:startCreator', source, name)
end, true)
