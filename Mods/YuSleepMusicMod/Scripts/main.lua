local UEHelpers = require("UEHelpers")

local MOD_NAME = "YuSleepMusicMod"
local RETRY_INTERVAL_MS = 1000

local mManagerFunLib
local mEnvFuncLib

local isPlayedSleepMusic = false

local function log(message)
    print(string.format("[YuMod] [%s] %s\n", MOD_NAME, tostring(message)))
end

local function hook()
    RegisterHook("/Script/JH.JHNeoUISubsystem:HideAllForSleepSystem", function()
    end, function()
        local Sound = StaticFindObject("/Game/Mods/MusicMod/Rooster.Rooster")
        local World = UEHelpers.GetWorld()

        mEnvFuncLib:PauseBackgroundMusic(World, true)

        local GameplayStatics = UEHelpers.GetGameplayStatics()

        GameplayStatics:PlaySound2D(
                World,
                Sound,
                0.2,
                1,
                0,
                CreateInvalidObject(),
                CreateInvalidObject(),
                true
        )

        isPlayedSleepMusic = true
    end)

    RegisterHook("/Script/JH.FightMapLoadingWidget:HandleShowSceneMapAnimalEnd", function()
    end, function()
        if isPlayedSleepMusic then
            isPlayedSleepMusic = false

            mEnvFuncLib:PlayBackgroundMusic(UEHelpers.GetWorld())

            log("[MusicMod] 恢复背景音乐")
        end
    end)
end

local function init_mod()
    mManagerFunLib = StaticFindObject("/Script/JH.Default__ManagerFuncLib")
    mEnvFuncLib = StaticFindObject("/Script/JH.Default__EnvironmentFuncLib")

    if not mManagerFunLib or not mManagerFunLib:IsValid() then
        ExecuteWithDelay(RETRY_INTERVAL_MS * 2, init_mod)
        return
    end

    if not mEnvFuncLib or not mEnvFuncLib:IsValid() then
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
