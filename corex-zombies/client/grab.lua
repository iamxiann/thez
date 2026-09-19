ZX = ZX or {}

local GrabRuntime = {}

local function DefaultApi()
    return {
        IsNetworked = NetworkGetEntityIsNetworked,
        HasControl = NetworkHasControlOfEntity,
        RequestControl = NetworkRequestControlOfEntity,
        Now = GetGameTimer,
        Wait = Wait,
        Exists = DoesEntityExist,
        IsDead = function(entity) return IsPedDeadOrDying(entity, true) end,
        Detach = function(entity) DetachEntity(entity, true, false) end,
        Freeze = FreezeEntityPosition,
        ClearTasks = ClearPedTasksImmediately,
        StopScene = NetworkStopSynchronisedScene
    }
end

function GrabRuntime.AcquireControl(entity, timeoutMs, api)
    api = api or DefaultApi()
    if not api.Exists(entity) then return false end
    if not api.IsNetworked(entity) then return true end
    if api.HasControl(entity) then return true end

    local deadline = api.Now() + math.max(0, tonumber(timeoutMs) or 750)
    repeat
        api.RequestControl(entity)
        if api.HasControl(entity) then return true end
        api.Wait(0)
    until api.Now() >= deadline or not api.Exists(entity)

    return api.Exists(entity) and api.HasControl(entity) or false
end

function GrabRuntime.CanContinue(session, api)
    api = api or DefaultApi()
    if not session or not api.Exists(session.player) or not api.Exists(session.zombie) then
        return false
    end
    if api.IsDead(session.player) or api.IsDead(session.zombie) then return false end
    if api.IsNetworked(session.zombie) and not api.HasControl(session.zombie) then return false end
    return true
end

function GrabRuntime.Cleanup(session, api)
    api = api or DefaultApi()
    if not session then return end

    if session.scene then pcall(api.StopScene, session.scene) end
    if session.player and api.Exists(session.player) then
        pcall(api.Detach, session.player)
        pcall(api.Freeze, session.player, false)
        pcall(api.ClearTasks, session.player)
    end
    if session.zombie and api.Exists(session.zombie) then
        pcall(api.ClearTasks, session.zombie)
    end
end

ZX.GrabRuntime = GrabRuntime
return GrabRuntime
