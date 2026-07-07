local UEHelpers = require("UEHelpers")

local MOD_NAME = "YuAutoSaveMod"
local RETRY_INTERVAL_MS = 1000

local EWorldStateType = {
    None = 0,
    Scene = 1,
    IntoFight = 2,
    Fighting = 3,
    IntoScene = 4,
    CG = 5,
    ChangeScene = 6,
    SkipingCG = 7,
    GameSystemActived = 8,
    EWorldStateType_MAX = 9,
}

local mManagerFunLib
local mNeedAutoSaveGame = false

local function log(message)
    print(string.format("[YuMod] [%s] %s\n", MOD_NAME, tostring(message)))
end

local function can_save_now(gi)
    if not gi or not gi:IsValid() then
        return false, "gameinstance invalid"
    end

    if gi.WorldStateType ~= EWorldStateType.Scene then
        return false, "world state = " .. tostring(gi.WorldStateType)
    end

    if gi.bDisableInputMove then
        return false, "input move disabled"
    end

    if gi.bIsFighting then
        return false, "fighting"
    end

    if gi.bWorldMapOpening then
        return false, "world map opening"
    end

    return true, "ok"
end

local function try_save()
    local ok, save_reason = can_save_now(UEHelpers:GetWorld().OwningGameInstance)
    if not ok then
        log("[AutoSave] 当前无法自动保存: " .. tostring(save_reason))
    else
        local saveManager = mManagerFunLib:GetSaveManager()
        saveManager:AutoSave()
        log("[AutoSave] 自动保存成功")
    end
end


local function hook()
    RegisterHook("/Script/JH.FightMapLoadingWidget:HandleShowSceneMapAnimalEnd", function()
    end, function()
        if mNeedAutoSaveGame then
            mNeedAutoSaveGame = false
            try_save()
        end
    end)

    RegisterLoadMapPostHook(function(_, World)
        local mapName = tostring(World:get():GetFullName())
        if not string.find(mapName, "NewGame", 1, true) then
            mNeedAutoSaveGame = true
        end
    end)
end

local function init_mod()
    mManagerFunLib = StaticFindObject("/Script/JH.Default__ManagerFuncLib")

    if not mManagerFunLib or not mManagerFunLib:IsValid() then
        ExecuteWithDelay(RETRY_INTERVAL_MS * 2, init_mod)
        return
    end

    hook()
end

local function register_mod(init_callback)
    local ok = pcall(function()
        return UEHelpers.GetPlayerController()
    end)

    if ok then
        init_callback()
        return
    end

    local pre_id
    local post_id
    pre_id, post_id = RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
        if pre_id and post_id then
            UnregisterHook("/Script/Engine.PlayerController:ClientRestart", pre_id, post_id)
        end
        ExecuteWithDelay(RETRY_INTERVAL_MS, init_callback)
    end)
end

register_mod(init_mod)
log("模组加载成功")
