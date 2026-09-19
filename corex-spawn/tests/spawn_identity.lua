-- Run from the workspace root with Lua 5.4, or through Python lupa.
local script = assert(io.open('corex-spawn/server/main.lua')):read('*a')
local function fixture(code)
    local env = setmetatable({}, {__index = _G})
    env.Config = {Debug=false, DefaultSpawnLocation={x=1,y=2,z=3}, FirstSpawnLocation={x=4,y=5,z=6}}
    env.sent, env.handlers, env.now, env.lifecycle = {}, {}, 0, 'loading'
    env.identifier = 'steam:abc'
    local function getPlayer()
        if not env.identifier then return nil end
        -- Each export call returns a new table, as it does across Cfx resources.
        return {source=1, identifier=env.identifier, name='Test', money={}, metadata={hunger=100,thirst=100,stress=0,infection=0}}
    end
    env.exports = setmetatable({
        ['corex-core']={GetPlayer=getPlayer, GetPlayerState=function() return env.lifecycle end,
            SetPlayerState=function(_, _, state) env.lifecycle=state end},
        ['illenium-appearance']={GetAppearance=function()
            if env.afterAppearance then env.afterAppearance() end
            return {model='mp_m_freemode_01'}
        end}
    }, {__call=function() end})
    env.RegisterNetEvent = function(name, cb) env.handlers[name]=cb end
    env.AddEventHandler = env.RegisterNetEvent
    env.CreateThread = function() end
    env.RegisterCommand = function() end
    env.GetGameTimer = function() return env.now end
    env.Player = function() return {state={set=function() end}} end
    env.TriggerClientEvent = function(_, _, data) env.sent[#env.sent+1]=data end
    assert(load(code, 'spawn-server', 't', env))()
    env.player = getPlayer()
    return env
end
local old = script:gsub('    %-%- Exports return table copies.-    player = currentPlayer', '    if GetPlayer(source) ~= player then return end')
local before=fixture(old)
before.CheckAndSpawnPlayer(1,before.player)
assert(#before.sent==0, 'original guard must reproduce the missing spawn event')
local env=fixture(script)
env.CheckAndSpawnPlayer(1,env.player,{isRespawn=true})
assert(#env.sent==1, 'copied player tables must still spawn')
env.now=4999; env.CheckAndSpawnPlayer(1,env.player); assert(#env.sent==1)
env.now=5000; env.CheckAndSpawnPlayer(1,env.player)
assert(#env.sent==2 and env.sent[2].isRespawn, 'retry preserves respawn data')
env.source=1; env.handlers['corex-spawn:server:markSpawnReady']()
assert(env.lifecycle=='active', 'copied player tables must acknowledge spawn')
env.now=10000; env.CheckAndSpawnPlayer(1,env.player); assert(#env.sent==2)
for _, changed in ipairs({'steam:def', false}) do
    env=fixture(script)
    env.afterAppearance=function() env.identifier=changed end
    env.CheckAndSpawnPlayer(1,env.player)
    assert(#env.sent==0, 'changed or disconnected player must not receive spawn')
end
print('PASS: reproduced old failure; copied tables spawn and acknowledge; retry cooldown; active guard; identity change/disconnect rejected')
