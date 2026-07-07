# 逸剑风云决 UE4SS Mods

一些为《逸剑风云决》制作的 UE4SS Lua MOD，用于改善游戏体验和方便调试。

## MOD 列表

### YuAutoSaveMod

更优的自动存档 MOD。

功能：

- 在进入大地图或城镇等场景自动进行存档，内置判断条件，如果触发了CG、战斗等会自动跳过存档。
- 减少忘记手动存档导致进度丢失。

---

### YuCompareLootMod

切磋全掉落 MOD。

功能：

- 和NPC切磋后，物品全掉落。
- 支持游戏左侧漂浮提示和战利品结算面板同步显示（N网的类似Mod不会同步，我优化了一下）。

---

### YuSleepMusicMod

客栈休息公鸡叫醒 MOD。

功能：

- 在客栈休息结束时时播放公鸡叫。
- 改善休息场景的沉浸感。

注意：该 MOD 需要导入额外的音乐资产，额外需要以下步骤

1. 下载 [MusicMod.pak](LogicMods/MusicMod.pak)，千万不要改名
2. 将下载好的 `MusicMod.pak` 放到 `\游戏安装目录\Wandering_Sword\Content\Paks\LogicMods\` 中即可，如果没有 `LogicMods` 文件夹自己新建一个（这个目录一般安装好了 `UE4SS` 启动一次游戏会自动生成）。
---

### YuDebugTraceMod

调试辅助 MOD。

功能：

- 输出 Funcation Call Trace 等调试信息。
- 用于开发和调试其他 UE4SS MOD。

> 普通玩家无需安装。

---

## 安装要求

- 安装《逸剑风云决》
- UE4SS 指定游戏引擎 UE4 26.2

请确保已经正确安装 UE4SS。

## 安装方法

1. 安装 UE4SS

   去 [官网下载](https://github.com/UE4SS-RE/RE-UE4SS/releases) 最新的 `UE4SS_v3.x.x` 压缩包，解压放到 `\游戏安装目录\Wandering_Sword\Binaries\Win64\ue4ss\` 文件夹即可完成安装。
   
   按官方的安装方法，你也可以不创建 `ue4ss` 文件夹，直接放 `Win64` 下，这里为了方便卸载，直接创建一个 `ue4ss` 并解压到里面。
   
   > 确保 `UE4SS.dll` 路径为：`\游戏安装目录\Wandering_Sword\Binaries\Win64\ue4ss\UE4SS.dll`，可以对比一下。

2. 打开游戏目录：

    ```
    Wandering_Sword/
    └── Binaries/
        └── Win64/
            └── ue4ss/
    ```

3. 将需要使用的 MOD 文件夹复制到：

    ```
    ue4ss/Mods/
    ```
    
    例如：
    
    ```
    ue4ss/
    └── Mods/
        ├── YuAutoSaveMod/
        ├── YuCompareLootMod/
        ├── YuDebugTraceMod/
        └── YuSleepMusicMod/
        └── .../
    ```
    
    然后在 `mods.txt` 和 `mods.json` 中启用


4. 启动游戏即可。

## 目录结构

```
Mods/
├── YuAutoSaveMod
├── YuCompareLootMod
├── YuDebugTraceMod
└── YuSleepMusicMod
```

## 兼容性

- 游戏：逸剑风云决（Steam）
- 运行环境：UE4SS Lua Mods

不同版本游戏或 UE4SS 可能存在兼容性差异，请使用较新的 UE4SS 版本，并且配置为 UE4 26.2。


## License

仅供学习与交流使用。
