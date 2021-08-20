-- coding=utf-8
--[[
reactor++.lua By Creepercdn
Since 2021/8/18 UTC+8:00
A automatic reactor script for IC2 and OC.
ONLY TESTED ON 1.12.2
ONLY FOR 1.12.2

A version from reactor2.lua(By odixus, https://www.mcmod.cn/post/693.html)

Some themes can found on https://xcolors.herokuapp.com/
--]]
local component = require("component")
local event = require("event")
local filesystem = require("filesystem")
local serialization = require("serialization")
local shell = require("shell")
local term = require("term")
-- Don't use tty API. It is obsolete. You should use gpu Component API

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

-- DO NOT USE CLEAR! USE FG AND BG  BG IS BACKGROUND.
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
    if type == 0 then
        palette = {
            0x000000, 0xFFFFFF, 0x000000, 0xFF0000, 0x00FF00, 0xFFFF00,
            0x0000FF, 0xFF00FF, 0x00FFFF, 0xFFFFFF
        }
    elseif type == 1 then
        palette = {
            0x21252B, 0xABB2BF, 0x21252B, 0xE06C75, 0x98C379, 0xE5C07B,
            0x61AFEF, 0xC678DD, 0x56B6C2, 0xABB2BF
        }
    elseif type == 2 then
        palette = {
            0x272822, 0xf8f8f2, 0x272822, 0xf92672, 0xa6e22e, 0xf4bf75,
            0x66d9ef, 0xae81ff, 0xa1efe4, 0xf8f8f2
        }
    elseif type == 3 then
        palette = {
            0x171717, 0xf8f8f8, 0x171717, 0xd81765, 0x97d01a, 0xffa800,
            0x16b1fb, 0xff2491, 0x0fdcb6, 0xebebeb
        }
    elseif type == 4 then
        palette = {
            0x000000, 0xffffff, 0x151515, 0xed4c7a, 0xa6e179, 0xffdf6b,
            0x79d2ff, 0xe85b92, 0x87a8af, 0xe2f1f6
        }
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
        gpu.setForeground(palette[10])
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
    BLACK = function()
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
-- table: 0xFFFFFFFF
-- > = "i love python" or 0
-- i love python
-- >
-- A: So, "or 0" can convert nil to 0.
-- Q: But, why there are no Ternary Operator?
-- A: I think you should ask Roberto Ierusalimschy, Waldemar Celes and Luiz Henrique de Figueiredo. They are authors of Lua.

local function colorPrint(color, text) -- colorful print()
    color()
    print(text)
    FG()
end

local function colorWrite(color, text) -- colorful term.write
    color()
    term.write(text)
    FG()
end

--[[
A list for auto detect (and replace) reactor items.
format:
{
[XX]={{damage=YY,item=ZZ,metafrom=AA,metato=BB}}
}

XX: string, a item id. The script will check this item.
AA: XX's meta value. Default to 0.
YY: float, means the item's damage value ratio. If the item's damage value lower than this value, when item is nil, the reactor will stop, otherwise it will replace it with ZZ.
ZZ: string, a item id. The item will replaced with.
BB: ZZ's meta value. Default to any.

if there are same XX, add multi capture group.
--]]

local items = {
    ["ic2:nuclear"] = {
        {item = "ic2:reactorUraniumQuad", metafrom = 13},
        {item = "ic2:reactorMOXQuad", metafrom = 16},
        {item = "ic2:reactorUraniumDual", metafrom = 12},
        {item = "ic2:reactorMOXDual", metafrom = 15},
        {item = "ic2:reactorUraniumSimple", metafrom = 11},
        {item = "ic2:reactorMOXSimple", metafrom = 14}
    },
    ["ic2:reactorReflector"] = {{damage = 0.01, item = "ic2:reactorReflector"}},
    ["ic2:reactorReflectorThick"] = {{
        damage = 0.01,
        item = "ic2:reactorReflectorThick"
    }},
    ["ic2:lzh_condensator"] = {{damage = 0.01, item = "ic2:lzh_condensator"}},
    ["ic2:rsh_condensator"] = {{damage = 0.01, item = "ic2:rsh_condensator"}},
    ["ic2:hex_heat_storage"] = {{damage = 0.05, item = "ic2:hex_heat_storage"}},
    ["ic2:tri_heat_storage"] = {{damage = 0.1, item = "ic2:tri_heat_storage"}},
    ["ic2:heat_storage"] = {{damage = 0.2, item = "ic2:heat_storage"}},
    ["ic2:heat_vent"] = {{damage = 0.8}},
    ["ic2:reactor_heat_vent"] = {{damage = 0.8}},
    ["ic2:overclocked_heat_vent"] = {{damage = 0.8}},
    ["ic2:advanced_heat_vemt"] = {{damage = 0.8}},
    ["ic2:heat_exchanger"] = {{damage = 0.8}},
    ["ic2:reactor_heat_exchanger"] = {{damage = 0.8}},
    ["ic2:component_heat_exchanger"] = {{damage = 0.8}},
    ["ic2:advanced_heat_exchanger"] = {{damage = 0.8}},
    ["fm:depleted_coaxium_rod"] = {{item = "fm:coaxium_rod"}},
    ["fm:depleted_coaxium_rod_dual"] = {{item = "fm:coaxium_rod_dual"}},
    ["fm:depleted_coaxium_rod_quad"] = {{item = "fm:coaxium_rod_quad"}},
    ["fm:depleted_cesium_rod"] = {{item = "fm:cesium_rod"}},
    ["fm:depleted_cesium_rod_dual"] = {{item = "fm:cesium_rod_dual"}},
    ["fm:depleted_cesium_rod_quad"] = {{item = "fm:cesium_rod_quad"}}
}

-- Q: When will GregTech update to 1.16?
-- A: When Worlds Collide.
-- When worlds collide, you can run, but no can hide!
-- In memory of Stephen Hillenburg.

local rs = getCom("redstone")
local reactor = getCom("reactor_chamber")
local transfer = getCom("transposer")

local function paddingMid(s, t) -- print text with padding middle
    local tt = t
    if not tt then tt = " " end
    local w, h = gpu.getViewport()
    local nLeft = math.floor((w - string.len(s)) / 2)
    return string.rep(tt, nLeft) .. s ..
               string.rep(tt, w - nLeft - string.len(s))
end

local function paddingLeft(s, t)
    local tt = t
    if not tt then tt = " " end
    local w, h = gpu.getViewport()
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
        -- theme
        colorWrite(GREEN,
                   "What theme do you want to use? 0: 3bit color; 1: one dark; 2: monokai; 3: neno; 4: Coloful Colors")
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
local w1, h1 = gpu.getViewport() -- origin size
if rs and reactor and transfer then -- if components defined
    local cfg = getConfig()
    -- work start
    local w, h = gpu.getViewport()
    local command = "s"
    local overheated = false
    while true do
        local heat = reactor.getHeat()
        local heatMax = reactor.getMaxHeat()
        local running = reactor.producesEnergy()

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
            running = false
            overheated = true
        else
            overheated = false
            -- check the items need to replace or stop
            -- it is fucking to rebuild shit code

            local item_in_reactor = transfer.getAllStacks(cfg["reactor"]).getAll()
            local ready = true
            for i = 0, #item_in_reactor - 4 do -- "-4" is for liquid reactor
                if item_in_reactor[i] and items[item_in_reactor[i].name] then -- check if this slot has item and this item is recorded in items table (only id)
                    for captureGroup in items[item_in_reactor[i].name] do -- emurate the capture groups
                        local lowDamage=true -- if doesn't specify meta and no damage value, just replace it (e.g. depleted rods)
                        -- if maxDamage isn't zero, there are no metadata.
                        -- if ((it have damage) or (doesn't specify meta value) or ((there are meta value) and (meta value equals)))
                        if (item_in_reactor[i].maxDamage ~= 0) or (not captureGroup.metafrom) or (captureGroup.metafrom and (captureGroup.metafrom == item_in_reactor[i].damage)) then
                            if (not item_in_reactor[i].maxDamage == 0) then -- if it have damage
                                lowDamage = (
                                    (not captureGroup.damage) -- if doesn't specify damage, just replace it! (the item is need to replace)
                                    or (
                                        (item_in_reactor[i].maxDamage - item_in_reactor[i].damage)
                                        <= (captureGroup.damage * item_in_reactor[i].maxDamage)
                                    )
                                )
                            end
                            if lowDamage then
                                ready = false
                                if running then
                                    -- stop reactor before replace item
                                    rs.setOutput(cfg["redstone"], 0)
                                    running = false
                                end
                                if captureGroup.item then -- can replace
                                    transfer.transferItem(cfg["reactor"], cfg["wastebox"], 1, i + 1) -- don't understand, daren't modify
                                    -- find item can be replaced with
                                    local boxLocation = 0
                                    while boxLocation == 0 do
                                        local item_in_box = transfer.getAllStacks(cfg["fuelbox"]).getAll()

                                        -- however, for is best.
                                        --[[ while (boxLocation == 0) and (k <= #item_in_box) do -- if you don't understand why use while, please see reference of boxLocation.
                                            if item_in_box[k] and (item_in_box[k].name == captureGroup.item) then
                                                boxLocation = k + 1
                                                break
                                            end
                                            k = k + 1
                                        end ]]

                                        for idx=1, #item_in_box, 1 do
                                            if((item_in_box[idx] == captureGroup.item) and ((not captureGroup.metato) or (not item_in_box[idx].maxDamage == 0) or (captureGroup.metato == item_in_box[idx].damage))) then
                                                boxLocation = idx+1
                                                break
                                            end
                                        end

                                        -- replace if can replace, otherwise wait
                                        if not (boxLocation > 0) and transfer.transferItem(cfg["fuelbox"], cfg["reactor"], 1, boxLocation, i + 1) then
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
                    -- check if low damage (no damage or damage lower than the damage in items table).
                    
                    -- don't start if there are low damage item
                end
            end
            -- start if command=r and ready
            if (command == "r") and (not running) and ready and (not overheated) then
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
