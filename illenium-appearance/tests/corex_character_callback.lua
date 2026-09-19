-- Run from the workspace root with Lua 5.4.
local file = assert(io.open('illenium-appearance/client/framework/corex/main.lua'))
local script = file:read('*a')
file:close()
local function fixture(code)
    local env = setmetatable({}, {__index=_G})
    env.Framework = {Corex=function() return true end, GetGender=function() return 'male' end}
    env.LocalPlayer = {state={}}
    env.client = {}
    env.lib = {notify=function() end}
    env.handlers = {}
    env.RegisterNetEvent = function(name, cb) env.handlers[name]=cb end
    env.exports = function(name, cb) env[name]=cb end
    env.opened = 0
    env.InitializeCharacter = function() env.opened=env.opened+1 end
    assert(load(code, 'corex-appearance', 't', env))()
    return env
end
local completed = 0
local callback = setmetatable({}, {__call=function() completed=completed+1 end})
local old = script:gsub('    %-%- Cfx deserializes callbacks.-    if characterCreatedCallback then return false end', "    if type(onSubmit) ~= 'function' or characterCreatedCallback then return false end")
local before = fixture(old)
assert(before.CreateCharacter(callback)==false and before.opened==0)
local env = fixture(script)
for _, invalid in ipairs({false, 1, 'callback', {}, setmetatable({}, {__call=true})}) do
    assert(env.CreateCharacter(invalid)==false)
end
assert(env.CreateCharacter(callback)==true and env.opened==1)
assert(env.CreateCharacter(callback)==false and env.opened==1, 'duplicate editor must be blocked')
env.handlers['illenium-appearance:client:appearanceSaved'](false)
assert(completed==0, 'failed save must not finish spawn')
env.handlers['illenium-appearance:client:appearanceSaved'](true)
env.handlers['illenium-appearance:client:appearanceSaved'](true)
assert(completed==1, 'successful save must finish exactly once')
assert(env.CreateCharacter(function() completed=completed+1 end)==true)
env.handlers['illenium-appearance:client:appearanceSaved'](true)
assert(completed==2)
print('PASS: reproduced callback rejection; callable table and function accepted; invalid/duplicate calls rejected; save acknowledgment runs once')
