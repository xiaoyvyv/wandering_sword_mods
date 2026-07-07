local UEHelpers = require("UEHelpers")

local MOD_NAME = "YuCompareLootMod"
local RETRY_INTERVAL_MS = 1000

local mNPCFuncLib
local mManagerFunLib
local mItemFuncLib

local mPendingRewardEntries
local mPreRollRewardEntries

local function log(message)
    print(string.format("[YuMod] [%s] %s\n", MOD_NAME, tostring(message)))
end

local function is_valid(obj)
    return obj and obj.IsValid and obj:IsValid()
end

local function item_specs_to_entries(itemSpecs)
    local entries = {}
    if not itemSpecs or not itemSpecs.ForEach then
        return entries
    end

    itemSpecs:ForEach(function(_, itemParam)
        local item = itemParam:get()
        if is_valid(item) then
            entries[#entries + 1] = {
                ItemDefId = item.ItemDefId,
                Num = item.Num,
                Raw = item
            }
        end
    end)

    return entries
end

local function log_entries(label, entries)
    local total = 0
    local parts = {}
    for index, entry in ipairs(entries or {}) do
        total = total + (entry.Num or 0)
        parts[#parts + 1] = string.format("#%d:%s x%s", index, tostring(entry.ItemDefId), tostring(entry.Num))
    end

    log(string.format("[Mod] %s: slots=%d total=%d [%s]", label, #(entries or {}), total, table.concat(parts, ", ")))
end

local function merge_entries_by_def_id(entries)
    local merged = {}
    local indexByDefId = {}

    for _, entry in ipairs(entries or {}) do
        local itemDefId = entry.ItemDefId
        local num = entry.Num or 1
        local raw = entry.Raw
        if itemDefId and num > 0 then
            local existingIndex = indexByDefId[itemDefId]
            if existingIndex then
                merged[existingIndex].Num = merged[existingIndex].Num + num
            else
                indexByDefId[itemDefId] = #merged + 1
                merged[#merged + 1] = {
                    ItemDefId = itemDefId,
                    Num = num,
                    Raw = raw
                }
            end
        end
    end

    return merged
end

local function make_item_spec(entry)
    if not is_valid(mItemFuncLib) then
        return nil
    end

    local ok, spec = pcall(function()
        return mItemFuncLib:MakeItemInfoSpec(entry.ItemDefId, entry.Num or 1, 0)
    end)
    if not ok or not is_valid(spec) then
        return nil
    end

    pcall(function()
        spec.ItemDefId = entry.ItemDefId
        spec.Num = entry.Num or 1
    end)

    return spec
end

local function overwrite_item_specs(itemSpecs, entries)
    if not itemSpecs or not itemSpecs.Empty then
        log("[Mod] 覆写 ItemSpecs 失败: 目标不是 TArray")
        return false
    end

    local specs = {}
    for _, entry in ipairs(entries or {}) do
        local item = make_item_spec(entry)
        if is_valid(item) then
            specs[#specs + 1] = item
            log(string.format(
                    "[Mod] 战利品展示准备：item=%s num=%s obj=%s",
                    tostring(item.ItemDefId),
                    tostring(item.Num),
                    tostring(item)
            ))
        end
    end

    if #specs == 0 then
        log("[Mod] 覆写 ItemSpecs 失败: 没有可写入的物品")
        return false
    end

    local ok, err = pcall(function()
        itemSpecs:Empty()
        for index, item in ipairs(specs) do
            itemSpecs[index] = item
        end
    end)

    if not ok then
        log("[Mod] 覆写 ItemSpecs 失败: " .. tostring(err))
        return false
    end

    return true
end

local function show_item_popups(entries)
    if not entries or #entries == 0 then
        return
    end

    local popupVM = FindFirstOf("JHNeoUICommonPopupMsgVM")
    if not is_valid(popupVM) then
        log("[Mod] 未找到 JHNeoUICommonPopupMsgVM，跳过左侧获得提示补齐")
        return
    end

    for _, entry in ipairs(entries) do
        local ok, err = pcall(function()
            popupVM:Show_ItemAcquiredByItem(entry.ItemDefId, entry.Num or 1)
        end)
        log(string.format(
                "[Mod] 左侧提示补齐 item=%s num=%s ok=%s err=%s",
                tostring(entry.ItemDefId),
                tostring(entry.Num),
                tostring(ok),
                tostring(ok and nil or err)
        ))
    end
end

local function hook()
    RegisterHook("/Script/JH.CompareSystem:RollItemAndDlgs", function(self, NPCId, Dlg, ItemSpecs)

        local npcIdValue = NPCId:get()
        local npcInfo = mNPCFuncLib:GetNPCInfoById(npcIdValue)
        if npcInfo and npcInfo:IsValid() then
            mPreRollRewardEntries = item_specs_to_entries(npcInfo.ItemSpecs)
            log_entries("Roll前NPC完整物品列表", mPreRollRewardEntries)
        else
            mPreRollRewardEntries = nil
        end

    end, function(self, ReturnValue, NPCId, Dlg, ItemSpecs)
        local npcIdValue = NPCId:get()
        local rollItemSpecs = ItemSpecs:get()

        log("[Mod] 抽取结果 NPC ID: " .. tostring(npcIdValue))

        local npcInfo = mNPCFuncLib:GetNPCInfoById(npcIdValue)
        local npcItemSpecs = npcInfo.ItemSpecs
        local npcSpecCount = #npcItemSpecs

        log("[Mod] Roll 结果格子数目: " .. tostring(#rollItemSpecs))
        log("[Mod] NPC Roll 剩余的物品格子数目: " .. tostring(#npcItemSpecs))

        local ItemManager = mManagerFunLib:GetItemManager()

        local remainingItems = {}
        if npcSpecCount > 0 then
            npcItemSpecs:ForEach(function(_, itemParam)
                local item = itemParam:get()
                if item and item:IsValid() then
                    remainingItems[#remainingItems + 1] = {
                        ItemDefId = item.ItemDefId,
                        Num = item.Num or 1
                    }
                end
            end)
        end

        mPendingRewardEntries = merge_entries_by_def_id(mPreRollRewardEntries)

        log_entries("完整奖励列表", mPendingRewardEntries)

        if npcSpecCount > 0 then
            for _, item in ipairs(remainingItems) do
                for _ = 1, item.Num do
                    ItemManager:TakeItemFromNPCPrivateBag(npcIdValue, item.ItemDefId)
                end
            end
        end

        local mPendingPopupEntries = merge_entries_by_def_id(remainingItems)
        ExecuteWithDelay(100, function()
            show_item_popups(mPendingPopupEntries)
        end)
    end)

    RegisterHook("/Script/JH.AsyncTaskOpenGatherResult:OpenGatherResult", function(self, WorldContextObject, InItems, InMoney)
        if not mPendingRewardEntries or #mPendingRewardEntries == 0 then
            return
        end

        local MyTargetArray = InItems:get()

        log_entries("战利品展示覆写", item_specs_to_entries(MyTargetArray))

        log("[Mod] 战利品展示覆写前格子数: " .. tostring(#MyTargetArray))
        overwrite_item_specs(MyTargetArray, mPendingRewardEntries)
        log("[Mod] 战利品展示覆写后格子数: " .. tostring(#MyTargetArray))

        log_entries("战利品展示列表转换原始数据后", item_specs_to_entries(MyTargetArray))
    end)
end

local function init_mod()
    mNPCFuncLib = StaticFindObject("/Script/JH.Default__NPCFuncLib")
    mManagerFunLib = StaticFindObject("/Script/JH.Default__ManagerFuncLib")
    mItemFuncLib = StaticFindObject("/Script/JH.Default__ItemFuncLib")

    if not mNPCFuncLib or not mNPCFuncLib:IsValid() then
        ExecuteWithDelay(RETRY_INTERVAL_MS * 2, init_mod)
        return
    end

    if not mManagerFunLib or not mManagerFunLib:IsValid() then
        ExecuteWithDelay(RETRY_INTERVAL_MS * 2, init_mod)
        return
    end

    if not mItemFuncLib or not mItemFuncLib:IsValid() then
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
