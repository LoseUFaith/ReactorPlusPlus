-- coding=utf-8
--[[
reactor++.lua By Creepercdn
Since 2021/8/18 UTC+8:00
A automatic reactor script for IC2 and OC.

A version from reactor2.lua(By odixus, https://www.mcmod.cn/post/693.html)
--]] local component = require("component")
local event = require("event")
local filesystem = require("filesystem")
local serialization = require("serialization")
local shell = require("shell")
local term = require("term")
local tty = require("tty")

local function getCom(t) -- Get component
    if component.list(t) then
        return component.proxy(component.list(t)())
    else
        return nil
    end
end

local function putTable(t, f) -- save table to file
    if type(t) == "table" then
        local file = filesystem.open(f, "w")
        file:write(serialization.serialize(t))
        file:close()
        return true
    else
        return false
    end
end

local function getTable(f) -- get table from file
    if filesystem.exists(f) then
        local file = io.open(f, "r")
        local fileSize = filesystem.size(f)
        local fileRead = file:read(fileSize)
        local fileContent = fileRead
        file:close()
        return serialization.unserialize(fileContent)
    else
        return false
    end
end

local gpu = getCom("gpu")

-- DO NOT USE CLEAR! USE FG AND BG  WHILE AND BG ARE BACKGROUND.
local RED, YELLOW, GREEN, BLUE, PURPLE, CYAN, WHITE, BG, FG, BLACK, CLEAR

--[[ local RED, YELLOW, GREEN, BLUE, CLEAR = "\27[31m", "\27[33m", "\27[32m",
                                        "\27[36m", "\27[0m" -- ANSI escape code for colorful console (4 bit) ]]

-- 0: 3bit color; 1: one dark; 2: monokai; 3: neon, 4: colorful colors
local function initColor(type)
    local palette
    -- Don't worry! Add a theme is a easy work.
    -- Use terminal.sexy! It is awesome!
    -- https://terminal.sexy/
    -- BG FG BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE
    if type==0 then
        palette = {0x000000,0xFFFFFF,0x000000,0xFF0000,0x00FF00,0xFFFF00,0x0000FF,0xFF00FF,0x00FFFF,0xFFFFFF}
    elseif type==1 then
        palette = {0x21252B,0xABB2BF,0x21252B,0xE06C75,0x98C379,0xE5C07B,0x61AFEF,0xC678DD,0x56B6C2,0xABB2BF}
    elseif type==2 then
        palette = {0x272822,0xf8f8f2,0x272822,0xf92672,0xa6e22e,0xf4bf75,0x66d9ef,0xae81ff,0xa1efe4,0xf8f8f2}
    elseif type==3 then
        palette = {0x171717,0xf8f8f8,0x171717,0xd81765,0x97d01a,0xffa800,0x16b1fb,0xff2491,0x0fdcb6,0xebebeb}
    elseif type==4 then
        palette = {0x000000,0xffffff,0x151515,0xed4c7a,0xa6e179,0xffdf6b,0x79d2ff,0xe85b92,0x87a8af,0xe2f1f6}
    end
    gpu.setBackground(palette[1])
    gpu.setForeground(palette[2])
    RED = function()
        gpu.setForeground(palette[4])
        return ""
    end
    YELLOW = function()
        gpu.setForeground(palette[6])
        return ""
    end
    GREEN = function()
        gpu.setForeground(palette[5])
        return ""
    end
    BLUE = function()
        gpu.setForeground(palette[7])
        return ""
    end
    PURPLE = function()
        gpu.setForeground(palette[8])
        return ""
    end
    CYAN = function()
        gpu.setForeground(palette[9])
        return ""
    end
    WHITE = function()
        gpu.setBackground(palette[10])
        return ""
    end
    BG = function()
        gpu.setBackground(palette[1])
        return ""
    end
    FG = function()
        gpu.setForeground(palette[2])
        return ""
    end
    BLACK = function ()
        gpu.setForeground(palette[3])
        return ""
    end
end

-- fucking lua
initColor(getTable("/home/reactor.cfg")["theme"] or 0)
-- Q: What the fuck is "or 0"?
-- A: Just try it.
-- > =0 or 0
-- 0
-- > = nil or 0
-- 0
-- > = 255 or 0
-- 255
-- > = {} or 0
-- table: 0x0064c2c0
-- > = "i love python" or 0
-- i love python
-- >
-- A: So, "or 0" can convert nil to 0.
-- Q: But, why there are no Ternary Operator?
-- A: I think you should ask Roberto Ierusalimschy, Waldemar Celes and Luiz Henrique de Figueiredo. They are authors of Lua.

local function colorPrint(color, text)
    color()
    print(text)
    FG()
end

local function colorWrite(color, text)
    color()
    term.write(text)
    FG()
end

--[[
A list for auto detect (and replace) reactor items.
format:
{
[XX]={damage=YY,item=ZZ}
}

XX: string, a item id. The script will check this item.
YY: int, means the item's damage value. If the item's damage value lower than this value, when item is nil, the reactor will stop, otherwise it will replace it with ZZ.
ZZ: string, a item id. The item will replaced with.
--]]

local items_IC2 = {
    ["IC2:reactorUraniumQuaddepleted"] = {item = "IC2:reactorUraniumQuad"},
    ["IC2:reactorMOXQuaddepleted"] = {item = "IC2:reactorMOXQuad"},
    ["IC2:reactorUraniumDualdepleted"] = {item = "IC2:reactorUraniumDual"},
    ["IC2:reactorMOXDualdepleted"] = {item = "IC2:reactorMOXDual"},
    ["IC2:reactorUraniumSimpledepleted"] = {item = "IC2:reactorUraniumSimple"},
    ["IC2:reactorMOXSimpledepleted"] = {item = "IC2:reactorMOXSimple"},
    ["IC2:reactorReflector"] = {damage = 0.01, item = "IC2:reactorReflector"},
    ["IC2:reactorReflectorThick"] = {
        damage = 0.01,
        item = "IC2:reactorReflectorThick"
    },
    ["IC2:reactorCondensator"] = {
        damage = 0.01,
        item = "IC2:reactorCondensator"
    },
    ["IC2:reactorCondensatorLap"] = {
        damage = 0.01,
        item = "IC2:reactorCondensatorLap"
    },
    ["IC2:reactorCoolantSix"] = {damage = 0.05, item = "IC2:reactorCoolantSix"},
    ["IC2:reactorCoolantTriple"] = {
        damage = 0.1,
        item = "IC2:reactorCoolantTriple"
    },
    ["IC2:reactorCoolantSimple"] = {
        damage = 0.2,
        item = "IC2:reactorCoolantSimple"
    },
    ["IC2:reactorVent"] = {damage = 0.8},
    ["IC2:reactorVentCore"] = {damage = 0.8},
    ["IC2:reactorVentGold"] = {damage = 0.8},
    ["IC2:reactorVentDiamond"] = {damage = 0.8},
    ["IC2:reactorHeatSwitch"] = {damage = 0.8},
    ["IC2:reactorHeatSwitchCore"] = {damage = 0.8},
    ["IC2:reactorHeatSwitchSpread"] = {damage = 0.8},
    ["IC2:reactorHeatSwitchDiamond"] = {damage = 0.8},
    ["fm:depleted_coaxium_rod"] = {item="fm:coaxium_rod"},
    ["fm:depleted_coaxium_rod_dual"] = {item="fm:coaxium_rod_dual"},
    ["fm:depleted_coaxium_rod_quad"] = {item="fm:coaxium_rod_quad"},
    ["fm:depleted_cesium_rod"] = {item="fm:cesium_rod"},
    ["fm:depleted_cesium_rod_dual"] = {item="fm:cesium_rod_dual"},
    ["fm:depleted_cesium_rod_quad"] = {item="fm:cesium_rod_quad"}
}

-- Q: When will GregTech update to 1.16?
-- A: When Worlds Collide.
-- When worlds collide, you can run, but no can hide!
local items_gt5 = {
    ["IC2:reactorReflector"] = {damage = 0.01, item = "IC2:reactorReflector"},
    ["IC2:reactorReflectorThick"] = {
        damage = 0.01,
        item = "IC2:reactorReflectorThick"
    },
    ["IC2:reactorCondensator"] = {
        damage = 0.01,
        item = "IC2:reactorCondensator"
    },
    ["IC2:reactorCondensatorLap"] = {
        damage = 0.01,
        item = "IC2:reactorCondensatorLap"
    },
    ["IC2:reactorCoolantSix"] = {damage = 0.05, item = "IC2:reactorCoolantSix"},
    ["IC2:reactorCoolantTriple"] = {
        damage = 0.1,
        item = "IC2:reactorCoolantTriple"
    },
    ["IC2:reactorCoolantSimple"] = {
        damage = 0.2,
        item = "IC2:reactorCoolantSimple"
    },
    ["IC2:reactorVent"] = {damage = 0.8},
    ["IC2:reactorVentCore"] = {damage = 0.8},
    ["IC2:reactorVentGold"] = {damage = 0.8},
    ["IC2:reactorVentDiamond"] = {damage = 0.8},
    ["IC2:reactorHeatSwitch"] = {damage = 0.8},
    ["IC2:reactorHeatSwitchCore"] = {damage = 0.8},
    ["IC2:reactorHeatSwitchSpread"] = {damage = 0.8},
    ["IC2:reactorHeatSwitchDiamond"] = {damage = 0.8},
    ["gregtech:gt.60k_Helium_Coolantcell"] = {
        damage = 0.2,
        item = "gregtech:gt.60k_Helium_Coolantcell"
    },
    ["gregtech:gt.180k_Helium_Coolantcell"] = {
        damage = 0.1,
        item = "gregtech:gt.180k_Helium_Coolantcell"
    },
    ["gregtech:gt.360k_Helium_Coolantcell"] = {
        damage = 0.05,
        item = "gregtech:gt.360k_Helium_Coolantcell"
    },
    ["gregtech:gt.60k_NaK_Coolantcell"] = {
        damage = 0.2,
        item = "gregtech:gt.60k_NaK_Coolantcell"
    },
    ["gregtech:gt.180k_NaK_Coolantcell"] = {
        damage = 0.1,
        item = "gregtech:gt.180k_NaK_Coolantcell"
    },
    ["gregtech:gt.360k_NaK_Coolantcell"] = {
        damage = 0.05,
        item = "gregtech:gt.360k_NaK_Coolantcell"
    },
    ["IC2:reactorUraniumQuaddepleted"] = {
        item = "gregtech:gt.reactorUraniumQuad"
    },
    ["IC2:reactorUraniumDualdepleted"] = {
        item = "gregtech:gt.reactorUraniumDual"
    },
    ["IC2:reactorUraniumSimpledepleted"] = {
        item = "gregtech:gt.reactorUraniumSimple"
    },
    ["IC2:reactorMOXQuaddepleted"] = {item = "gregtech:gt.reactorMOXQuad"},
    ["IC2:reactorMOXDualdepleted"] = {item = "gregtech:gt.reactorMOXDual"},
    ["IC2:reactorMOXSimpledepleted"] = {item = "gregtech:gt.reactorMOXSimple"},
    ["gregtech:gt.Quad_NaquadahcellDep"] = {
        item = "gregtech:gt.Quad_Naquadahcell"
    },
    ["gregtech:gt.Double_NaquadahcellDep"] = {
        item = "gregtech:gt.Double_Naquadahcell"
    },
    ["gregtech:gt.NaquadahcellDep"] = {item = "gregtech:gt.Naquadahcell"},
    ["gregtech:gt.Quad_ThoriumcellDep"] = {
        item = "gregtech:gt.Quad_Thoriumcell"
    },
    ["gregtech:gt.Double_ThoriumcellDep"] = {
        item = "gregtech:gt.Double_Thoriumcell"
    },
    ["gregtech:gt.ThoriumcellDep"] = {item = "gregtech:gt.Thoriumcell"}
}

local rs = getCom("redstone")
local reactor = getCom("reactor_chamber")
local transfer = getCom("transposer")


local function paddingMid(s, t) -- print text with padding middle
    local tt = t
    if not tt then tt = " " end
    local w, h = tty.gpu().getViewport()
    local nLeft = math.floor((w - string.len(s)) / 2)
    return string.rep(tt, nLeft) .. s ..
               string.rep(tt, w - nLeft - string.len(s))
end

local function paddingLeft(s, t)
    local tt = t
    if not tt then tt = " " end
    local w, h = tty.gpu().getViewport()
    return s .. string.rep(tt, w - string.len(s))
end

local function getKey() -- get value 0~5
    local result = -1
    while (not result) or (result < 0) or (result > 5) do
        result = tonumber(io.read())
    end
    return result
end

local function getConfig()
    -- Config sides. If there are config file and using the config, read the config and prompt, otherwise reconfigure.
    local cfg = getTable("/home/reactor.cfg")
    shell.execute("resolution 50 16")
    term.clear()
    if cfg then
        colorPrint(BLUE, "Current configuration:")
        colorPrint(BLUE, "------------------------------------------")
        for key, s in pairs(cfg) do print(key .. ": " .. s) end
        colorPrint(BLUE, "------------------------------------------")
        colorPrint(BLUE, "0:down 1:top 2:north 3:south 4:west 5:east")
        colorPrint(BLUE, "------------------------------------------")
        colorPrint(YELLOW, "Do you want to use this config? [Y/n]")
        if io.read() == "n" then cfg = nil end
    end
    if not cfg then
        term.clear()
        cfg = {}
        colorPrint(BLUE, "Please config the sides:")
        colorPrint(BLUE, "------------------------------------------")
        colorPrint(BLUE, "0:down 1:top 2:north 3:south 4:west 5:east")
        colorPrint(BLUE, "------------------------------------------")
        -- redstone output side relative to the redstone adapter
        colorWrite(GREEN, "which side does [REDSTONE] Output? ")
        cfg["redstone"] = getKey()
        -- reactor side relative to the transposer
        colorWrite(GREEN, "which side does REACTOR towards [TRANSPOSER]? ")
        cfg["reactor"] = getKey()
        -- fuel box relative to the transposer
        colorWrite(GREEN, "which side does FuelBox towards [TRANSPOSER]? ")
        cfg["fuelbox"] = getKey()
        -- waste box relative to the transposer
        colorWrite(GREEN, "which side does WasteBox towards [TRANSPOSER]? ")
        cfg["wastebox"] = getKey()
        -- overheat ratio
        colorWrite(GREEN, "what is overheat temperature ratio?(0.0001~1) ")
        cfg["overheat"] = getKey()
        -- mod version
        colorWrite(GREEN, "Which MOD are you using?(1=ic2,2=gt5)")
        cfg["mod"] = getKey()
        -- theme
        colorWrite(GREEN, "What theme do you want to use? 0: 3bit color; 1: one dark; 2: monokai; 3: neno; 4: Coloful Colors")
        cfg["theme"] = getKey()

        putTable(cfg, "/home/reactor.cfg")
    end
    initColor(cfg["theme"])
    colorPrint(GREEN, "Config successful!")

    ---@diagnostic disable-next-line: undefined-field
    os.sleep(1);
    shell.execute("resolution 32 6")
    term.clear()

    return cfg
end

local function keyDown(t) -- get key. it t defined, the function will wait the key elapsed t most.
    local result
    if t then
        _, _, result = event.pull(t, "key_down")
    else
        _, _, result = event.pull("key_down")
    end
    if not result then result = 0 end
    return result
end

---------------script starts---------------------
local w1, h1 = tty.gpu().getViewport() -- origin size
local items -- gt5 or ic2 items table
if rs and reactor and transfer then -- if components defined
    local cfg = getConfig()
    -- work start
    local w, h = tty.gpu().getViewport()
    local command = "s"
    while true do
        if cfg.mod == 1 then
            items = items_IC2
        elseif cfg.mod == 2 then
            items = items_gt5
        else
            colorPrint(RED, "Wrong MOD type! Exiting!");
            rs.setOutput(cfg["redstone"], 0);
            break
        end
        local heat = reactor.getHeat()
        local heatMax = reactor.getMaxHeat()
        local running = reactor.producesEnergy()
        local overheated = false

        -- fucking lua, too.
        term.setCursor(1, 1)
        colorWrite(BLUE, paddingLeft("DATE/TIME:    " .. os.date()))
        term.setCursor(1, 2)
        colorWrite((overheated and RED or GREEN),
                   paddingLeft("Heat:         " .. heat .. "  / " .. heatMax))
        term.setCursor(1, 3)
        colorWrite((overheated and RED or GREEN), paddingLeft(
                       string.rep("#", math.floor(w * heat / heatMax)), "."))
        term.setCursor(1, 4)
        term.write(paddingLeft(" "))
        term.setCursor(1, 5)

        if running then
            colorWrite(GREEN, paddingMid("<<< RUNNING >>>"))
        else
            colorWrite(RED, paddingMid("<<< STOP >>>"))
        end
        term.setCursor(1, 6)
        colorWrite(YELLOW, "[Run] [Stop] [eXit] [Config] " .. command)

        if heat / heatMax > cfg["overheat"] then -- stop if overheat
            if running then rs.setOutput(cfg["redstone"], 0) end
            overheated = true
        else
            overheated = false
            -- check the items need to replace or stop

            local item_in_reactor = transfer.getAllStacks(cfg["reactor"])
                                        .getAll()
            local ready = true
            for i = 0, #item_in_reactor - 4 do
                if item_in_reactor[i] and items[item_in_reactor[i].name] then -- check if this slot has item and this item is recorded in items table
                    -- check if low damage (no damage or damage lower than the damage in items table).
                    local lowDamage = ((not items[item_in_reactor[i].name]
                                          .damage) or
                                          ((item_in_reactor[i].maxDamage -
                                              item_in_reactor[i].damage) <=
                                              (items[item_in_reactor[i].name]
                                                  .damage *
                                                  item_in_reactor[i].maxDamage)))
                    ready = (ready and (not lowDamage)) -- don't start if there are low damage item
                    if lowDamage then
                        if running then
                            -- stop reactor before replace item
                            rs.setOutput(cfg["redstone"], 0)
                            running = false
                        end
                        if items[item_in_reactor[i].name].item then -- can replace
                            transfer.transferItem(cfg["reactor"],
                                                  cfg["wastebox"], 1, i + 1)
                            -- find item can be replaced with
                            local boxLocation = 0
                            while boxLocation == 0 do
                                local item_in_box =
                                    transfer.getAllStacks(cfg["fuelbox"])
                                        .getAll()
                                local k = 0
                                while (boxLocation == 0) and (k <= #item_in_box) do
                                    if item_in_box[k] and
                                        (item_in_box[k].name ==
                                            items[item_in_reactor[i].name].item) then
                                        boxLocation = k + 1
                                        break
                                    end
                                    k = k + 1
                                end
                                -- replace if can replace, otherwise wait
                                if (boxLocation > 0) and
                                    transfer.transferItem(cfg["fuelbox"],
                                                          cfg["reactor"], 1,
                                                          boxLocation, i + 1) then
                                    break
                                else
                                    term.setCursor(1, 4)
                                    colorWrite(RED, paddingMid("Fuel shortage!"))
                                    ---@diagnostic disable-next-line: undefined-field
                                    os.sleep(1)
                                end
                            end
                        end
                    end
                end
            end
            -- start if command=r and ready
            if (command == "r") and (not running) and ready then
                rs.setOutput(cfg["redstone"], 15)
            end
        end
        local key = keyDown(0.2) -- capture key
        if key == 115 then -- press s key means stop
            command = "s";
            rs.setOutput(cfg["redstone"], 0);
        elseif key == 114 then -- press r means run
            command = "r"
        elseif key == 120 then -- press x means exit
            rs.setOutput(cfg["redstone"], 0);
            break
        elseif key == 99 then -- press c, stop reactor before config, means config
            rs.setOutput(cfg["redstone"], 0)
            cfg = getConfig()
        end
    end
    shell.execute("resolution " .. w1 .. " " .. h1) -- restore to origin size
else
    colorPrint(RED, "Please check components: REDSTONE, TRANSPOSER, REACTOR")
end
