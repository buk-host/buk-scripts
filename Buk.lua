--[[
    ╔══════════════════════════════════════╗
    ║  Buk                                 ║
    ║  Developed by: Linesketon02          ║
    ║  UI: Própria (sem biblioteca)        ║
    ╚══════════════════════════════════════╝

    Abas: Main | Player | ESP | Weapon | Auto Farm | Aimbot MM2 | Troll | Copy Animation | Settings
    Tecla para abrir/fechar: RightShift (muda em Settings > Menu Key)
    Botão "-" minimiza e vira um ícone flutuante (toque nele para abrir de novo)
]]

-- ═══════════════════════════════════════════════════════════
--  0. LIMPEZA (se já estiver carregado, descarrega o anterior)
-- ═══════════════════════════════════════════════════════════
local genv = (getgenv and getgenv()) or _G
if genv.BukUnload then
    pcall(genv.BukUnload)
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ═══════════════════════════════════════════════════════════
--  1. SERVIÇOS
-- ═══════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
--  2. COMPATIBILIDADE (funciona em qualquer executor)
-- ═══════════════════════════════════════════════════════════
local Compat = {}

Compat.files = (type(writefile) == "function")
    and (type(readfile) == "function")
    and (type(isfile) == "function")

function Compat.protect(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        end
    end)
end

function Compat.guiParent()
    if Compat._parent then
        return Compat._parent
    end

    local parent = nil
    if gethui then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then
            parent = h
        end
    end

    if not parent then
        local ok, core = pcall(function()
            return game:GetService("CoreGui")
        end)
        if ok and core then
            local probe = Instance.new("Folder")
            if pcall(function() probe.Parent = core end) then
                parent = core
            end
            pcall(function() probe:Destroy() end)
        end
    end

    parent = parent or LocalPlayer:WaitForChild("PlayerGui")
    Compat._parent = parent
    return parent
end

local GuiParent = Compat.guiParent()

-- ═══════════════════════════════════════════════════════════
--  3. CONSTANTES E CORES
-- ═══════════════════════════════════════════════════════════
local WHITE  = Color3.new(1, 1, 1)
local BLACK  = Color3.new(0, 0, 0)
local ACCENT = Color3.fromRGB(224, 58, 62)   -- vermelho MM2 (Murderer)

local ROLE_COLORS = {
    Innocent = Color3.fromRGB(74, 222, 128),
    Sheriff  = Color3.fromRGB(59, 130, 246),
    Murderer = Color3.fromRGB(239, 68, 68),
}
local GUN_COLOR = Color3.fromRGB(255, 215, 0)
local NAME_NEUTRAL = Color3.fromRGB(110, 114, 135)

local ESP_MAX_DIST  = 500  -- distância máxima fixa dos ESPs


-- ═══════════════════════════════════════════════════════════
--  4. IDIOMA (English fixo)
-- ═══════════════════════════════════════════════════════════
local Lang = "en"

local STR = {
    en = {
        tab_main = "Main", tab_player = "Player", tab_visuals = "ESP", tab_pick = "Weapon", tab_farm = "Auto Farm",
        tab_sheriff = "Aimbot MM2", tab_troll = "Troll", tab_emotes = "Copy Animation", tab_settings = "Settings",
        sec_move = "Movement", sec_protect = "Protection",
        cframe = "CFrame", cframe_speed = "CFrame Speed", inf_jump = "Infinite Jump",
        noclip = "Noclip", anti_fling = "Anti-Fling",
        sec_name = "Esp Name", esp_name = "Esp Name",
        sec_roles = "Esp Roles", role_inn = "Innocent", role_sher = "Sheriff", role_murd = "Murderer",
        sec_items = "Items & Arrows", items_dd = "Enable", gun_drop = "Gun Dropped",
        arrow_murder = "Arrow to Murderer", arrow_sheriff = "Arrow to Sheriff",
        sec_pick = "Weapon", pick_auto = "Auto Pick",
        pick_screen = "On-Screen Button", sec_pick_pc = "PC", pick_key_on = "Keyboard Shortcut",
        pick_key = "Shortcut Key", pick_cap = "GUN",
        sec_farm = "Farm Coins", farm_on = "Auto Farm", farm_limit = "Max Coins per Round",
        farm_safe = "Safe Mode", farm_reset = "Reset When Full",
        sec_magic = "Magic Bullet", magic = "Magic Bullet",
        magic_part = "Aim Part", part_torso = "Torso", part_head = "Head",
        magic_predict = "Prediction (ping compensation)",
        sec_wall = "Shoot Through Walls", wall_shot = "Shoot Through Walls",
        sec_autopick = "Auto Pick", autopick_gun = "Auto Pick Dropped Gun",
        sec_copy = "Copy", sec_saved = "Saved Animation", copy_player = "Select Player",
        copy_refresh = "Refresh Player List", copy_btn = "Copy Animation",
        copy_restore = "Restore My Animation",
        copy_ok = "Animation copied!", copy_saved = "Animation copied and saved!",
        saved_use = "Use Saved Animation", saved_remove = "Remove Saved Animation",
        saved_used = "Saved animation applied!", saved_none = "No saved animation.",
        saved_removed = "Saved animation removed.", copy_restored = "Animation restored.",
        copy_noplayer = "Select a player first.", copy_dead = "You need to be alive.",
        copy_noanim = "Couldn't read that player's animation.",
        sec_fling = "Fling", fling = "Fling", fling_player = "Select Player",
        fling_notarget = "Select a player first.", fling_dead = "You need to be alive.",
        fling_norole = "No Sheriff/Murderer in the match right now.",
        fling_tdead = "That player isn't alive right now.", fling_left = "The player left. Fling stopped.",
        sec_menu = "Menu",
        menu_key = "Menu Key", save_btn = "Save Settings", unload_btn = "Unload Script",
        loaded = "Loaded successfully! by Linesketon02",
        pick_ok = "Gun picked up!", pick_auto_ok = "Gun picked up automatically!",
        pick_nogun = "No dropped gun on the ground.", pick_dead = "You need to be alive.",
        pick_hasgun = "You already have the gun.", pick_fail = "Couldn't pick up the gun.",
        flash_ok = "PICKED!", flash_nogun = "NO GUN", flash_dead = "DEAD",
        flash_hasgun = "HAS GUN", flash_fail = "FAILED",
        farm_full = "Bag full! Auto Farm paused until the next round.",
        no_hook = "Your executor doesn't support Magic Bullet (hook).",
        saved_text = "Settings saved successfully.",
        save_fail_text = "Couldn't save the settings.",
        no_files = "Your executor can't save files (writefile).",
        sec_info = "Info", info_author = "Developed by: Linesketon02",
        info_menu = "Tap the minimize button (-) to hide the menu, then tap the floating Buk icon to open it again. You can also use the Menu Key (Settings).",
        close_confirm = "Tap X again to close the script.",
        none = "None", select = "Select", selected_n = "%d selected", press_key = "Press a key...",
    },
}

local function L(key, ...)
    local text = (STR[Lang] and STR[Lang][key]) or STR.en[key] or key
    if select("#", ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

-- ═══════════════════════════════════════════════════════════
--  5. ESTADO GLOBAL DAS OPÇÕES
-- ═══════════════════════════════════════════════════════════
local State = {
    -- Esp Roles (Chams)
    RoleInnocent = false,
    RoleSheriff  = false,
    RoleMurderer = false,

    -- Esp Name (nome acima da cabeça)
    EspName = false,

    -- Itens e setas
    GunDrop      = false,
    ArrowMurder  = false,
    ArrowSheriff = false,

    -- Weapon (Pick)
    PickAuto   = false,
    PickButton = false,
    PickKeyOn  = false,
    PickKey    = Enum.KeyCode.G,

    -- Main
    CFrameOn    = false,
    CFrameSpeed = 30,
    InfJump     = false,
    Noclip      = false,
    AntiFling   = false,

    -- Sheriff
    MagicBullet = false,
    WallShot    = false,
    AimPart     = "Torso",
    AimPredict  = true,
    AutoPickGun = false,

    -- Auto Farm
    FarmOn    = false,
    FarmSpeed = 22, -- fixo (sem slider)
    FarmSafe  = true,
    FarmLimit = 40,
    FarmReset = false,

    -- Troll (o Fling nunca liga sozinho; State.FlingTarget = nome do player escolhido)
    Fling = false,

    -- Menu
    MenuKey = Enum.KeyCode.RightShift,
}

-- true enquanto o Fling está rodando (pausa Noclip, Anti-Fling, CFrame e Auto Farm)
local flingRunning = false

-- ═══════════════════════════════════════════════════════════
--  5B. DESEMPENHO INTERNO
--  - Perf: valores fixos de otimização interna (antigo modo "Strong")
--      espStep     : tempo entre atualizações do ESP
--      cacheRefresh: de quanto em quanto tempo refaz listas de peças
--      arrowStep   : tempo entre atualizações das setas
--      roleStep    : cache da detecção de roles
-- ═══════════════════════════════════════════════════════════
local Perf = {
    espStep      = 1 / 30,
    cacheRefresh = 1,
    arrowStep    = 1 / 30,
    roleStep     = 0.25,
}

-- ═══════════════════════════════════════════════════════════
--  6. UTILIDADES
-- ═══════════════════════════════════════════════════════════
local alive       = true
local connections = {}
local NotifyImpl  = nil -- aviso na tela (criado pela interface)

local function track(conn)
    connections[#connections + 1] = conn
    return conn
end

-- Avisa cada erro só uma vez por módulo (evita spam no console)
local warned = {}
local function safeWarn(err, tag)
    tag = tag or "geral"
    if not warned[tag] then
        warned[tag] = true
        warn("[Buk] (" .. tag .. ") " .. tostring(err))
    end
end

-- Loop protegido: se der erro numa volta, o loop continua rodando
local function loop(tag, interval, fn)
    task.spawn(function()
        while alive do
            task.wait(type(interval) == "function" and interval() or interval)
            if not alive then break end
            local ok, err = pcall(fn)
            if not ok then safeWarn(err, tag) end
        end
    end)
end

local function notify(text, icon, duration)
    if not NotifyImpl then return end
    pcall(NotifyImpl, text, icon, duration)
end

local function newScreenGui(name, order)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = order or 0
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Compat.protect(gui)
    gui.Parent = GuiParent
    return gui
end

-- Mostra um erro na tela (caso o menu não consiga abrir)
local function showError(err)
    warn("[Buk] " .. tostring(err))
    pcall(function()
        local gui = newScreenGui("BukError", 999)

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.8, 0, 0.5, 0)
        box.Position = UDim2.new(0.1, 0, 0.25, 0)
        box.BackgroundColor3 = Color3.fromRGB(35, 10, 10)
        box.TextColor3 = WHITE
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.TextYAlignment = Enum.TextYAlignment.Top
        box.TextWrapped = true
        box.MultiLine = true
        box.ClearTextOnFocus = false
        box.Font = Enum.Font.Code
        box.TextSize = 16
        box.Text = "[Buk] " .. tostring(err)
        box.Parent = gui

        local close = Instance.new("TextButton")
        close.Size = UDim2.fromOffset(36, 36)
        close.Position = UDim2.new(0.9, -36, 0.25, 0)
        close.BackgroundColor3 = Color3.fromRGB(224, 58, 62)
        close.TextColor3 = WHITE
        close.Font = Enum.Font.GothamBold
        close.TextSize = 18
        close.Text = "X"
        close.ZIndex = 2
        close.Parent = gui
        close.MouseButton1Click:Connect(function()
            gui:Destroy()
        end)
    end)
end

local HighlightFolder = Instance.new("Folder")
HighlightFolder.Name = "BukHighlights"
HighlightFolder.Parent = GuiParent

local function toKeyCode(key)
    if typeof(key) == "EnumItem" then
        return key
    end
    local ok, result = pcall(function()
        return Enum.KeyCode[key]
    end)
    if ok then
        return result
    end
    return nil
end

local function keyFrom(value)
    if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
        return value
    end
    if type(value) == "string" then
        return toKeyCode(value)
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
--  6B. CONFIGURAÇÕES SALVAS (arquivo JSON)
-- ═══════════════════════════════════════════════════════════
local CONFIG_FILE = "Buk_Config.json"
local SAVE_KEYS = {
    "RoleInnocent", "RoleSheriff", "RoleMurderer", "EspName", "GunDrop", "ArrowMurder", "ArrowSheriff",
    "PickAuto", "PickButton", "PickKeyOn",
    "CFrameOn", "CFrameSpeed", "InfJump", "Noclip", "AntiFling",
    "MagicBullet", "WallShot", "AimPart", "AimPredict", "AutoPickGun",
    "FarmSafe", "FarmLimit", "FarmReset",
}

local function saveConfig()
    if not Compat.files then
        return false
    end
    local data = {}
    for _, k in ipairs(SAVE_KEYS) do
        data[k] = State[k]
    end
    data.PickKey = State.PickKey.Name
    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
    return ok
end

local function loadConfig()
    if not Compat.files then return end
    pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) ~= "table" then return end

        for _, k in ipairs(SAVE_KEYS) do
            local v = data[k]
            if v ~= nil and type(v) == type(State[k]) then
                State[k] = v
            end
        end
        local kc = toKeyCode(data.PickKey)
        if kc then
            State.PickKey = kc
        end
    end)
end

loadConfig()

-- ═══════════════════════════════════════════════════════════
--  7. ROLES (MM2) - detecção antecipada
--  1) Dados do jogo (GetPlayerData / PlayerDataChanged)
--  2) Plano B: Knife / Gun
-- ═══════════════════════════════════════════════════════════
local roleData = {}
local deadData = {}
local getPlayerDataRemote = nil

local function hasTool(player, toolName)
    local char = player.Character
    if char and char:FindFirstChild(toolName) then
        return true
    end
    local backpack = player:FindFirstChild("Backpack")
    return backpack ~= nil and backpack:FindFirstChild(toolName) ~= nil
end

local function normalizeRole(r)
    if r == "Murderer" then
        return "Murderer"
    elseif r == "Sheriff" or r == "Hero" then
        return "Sheriff"
    elseif r == "Innocent" then
        return "Innocent"
    end
    return nil
end

local function readRoles(data)
    local out = {}
    if type(data) ~= "table" then return out end
    for name, info in pairs(data) do
        if type(name) == "string" and type(info) == "table" then
            local r = normalizeRole(info.Role)
            if r then out[name] = r end
        end
    end
    return out
end

local function readDead(data)
    local out = {}
    if type(data) ~= "table" then return out end
    for name, info in pairs(data) do
        if type(name) == "string" and type(info) == "table" then
            out[name] = (info.Dead == true)
        end
    end
    return out
end

local function replaceRoleData(data)
    roleData = readRoles(data)
    deadData = readDead(data)
end

local function mergeRoleData(data)
    for name, r in pairs(readRoles(data)) do roleData[name] = r end
    for name, d in pairs(readDead(data)) do deadData[name] = d end
end

-- Cache curto para não repetir a mesma busca várias vezes por frame
local roleCacheV = setmetatable({}, { __mode = "k" })
local roleCacheT = setmetatable({}, { __mode = "k" })

local function getRole(player)
    local now = os.clock()
    local t = roleCacheT[player]
    if t and now - t < Perf.roleStep then
        return roleCacheV[player]
    end

    local result
    local r = roleData[player.Name]
    if r and r ~= "Innocent" then
        result = r
    elseif hasTool(player, "Knife") then
        result = "Murderer"
    elseif hasTool(player, "Gun") then
        result = "Sheriff"
    else
        result = r or "Innocent"
    end

    roleCacheV[player] = result
    roleCacheT[player] = now
    return result
end

local function rolesNeeded()
    return State.RoleInnocent or State.RoleSheriff or State.RoleMurderer
end

local function roleDataNeeded()
    return rolesNeeded()
        or State.ArrowMurder or State.ArrowSheriff
        or State.MagicBullet or State.WallShot or State.AutoPickGun
        or State.FarmOn
        or (State.Fling and type(State.FlingTarget) == "string" and State.FlingTarget:sub(1, 1) == "[")
end

-- Liga nos remotes do jogo (em segundo plano)
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    if not remotes or not alive then return end

    local extras   = remotes:WaitForChild("Extras", 5)
    local gameplay = remotes:WaitForChild("Gameplay", 5)
    if not alive then return end

    local getter = extras and extras:FindFirstChild("GetPlayerData")
    if getter and getter:IsA("RemoteFunction") then
        getPlayerDataRemote = getter
    end

    local changed = gameplay and gameplay:FindFirstChild("PlayerDataChanged")
    if changed and changed:IsA("RemoteEvent") then
        track(changed.OnClientEvent:Connect(function(data)
            pcall(mergeRoleData, data)
        end))
    end
end)

-- Consulta os roles 2x por segundo (só quando algum recurso precisa)
do
    local invoking    = false
    local invokeToken = 0

    loop("roles", 0.5, function()
        if invoking or not getPlayerDataRemote or not roleDataNeeded() then
            return
        end

        invoking = true
        invokeToken = invokeToken + 1
        local myToken = invokeToken

        task.spawn(function()
            local ok, data = pcall(function()
                return getPlayerDataRemote:InvokeServer()
            end)
            if invokeToken == myToken then
                invoking = false
            end
            if ok and type(data) == "table" then
                replaceRoleData(data)
            end
        end)

        -- tempo limite: se o servidor não responder, libera a próxima consulta
        task.delay(3, function()
            if invokeToken == myToken then
                invoking = false
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════
--  8. ARMA DROPADA (busca compartilhada + ESP)
-- ═══════════════════════════════════════════════════════════
-- Etiqueta flutuante bonita (pílula escura com borda colorida)
local function makePillTag(tagName, offsetY, accent)
    local gui = Instance.new("BillboardGui")
    gui.Name = tagName
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(240, 30)
    gui.StudsOffset = Vector3.new(0, offsetY, 0)
    gui.Parent = HighlightFolder

    local pill = Instance.new("Frame")
    pill.AnchorPoint = Vector2.new(0.5, 0.5)
    pill.Position = UDim2.fromScale(0.5, 0.5)
    pill.Size = UDim2.fromOffset(0, 22)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.BackgroundColor3 = Color3.fromRGB(12, 10, 14)
    pill.BackgroundTransparency = 0.2
    pill.BorderSizePixel = 0
    pill.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 11)
    corner.Parent = pill

    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.1
    stroke.Parent = pill

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = pill

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(0, 22)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = WHITE
    label.RichText = true
    label.Text = ""
    label.Parent = pill

    return gui, label, stroke
end

local gunCache  = nil
local gunScanAt = 0

local function findGunDrop(forceDeep)
    if gunCache and gunCache.Parent and gunCache:IsDescendantOf(Workspace) then
        return gunCache
    end

    gunCache = Workspace:FindFirstChild("GunDrop")
    if not gunCache then
        local now = os.clock()
        if forceDeep or now - gunScanAt >= 1 then
            gunScanAt = now
            gunCache = Workspace:FindFirstChild("GunDrop", true)
        end
    end
    return gunCache
end

local function getGunPart(drop)
    if drop:IsA("BasePart") then
        return drop
    end
    if drop:IsA("Model") and drop.PrimaryPart then
        return drop.PrimaryPart
    end
    return drop:FindFirstChildWhichIsA("BasePart", true)
end

local gunHighlight = nil
local gunBillboard = nil
local gunLabel     = nil
local gunLastText  = nil

local function hideGunDrop()
    if gunHighlight then gunHighlight.Enabled = false end
    if gunBillboard then gunBillboard.Enabled = false end
end

local function updateGunDrop()
    if not State.GunDrop then
        hideGunDrop()
        return
    end

    local drop = findGunDrop(false)
    local part = drop and getGunPart(drop)
    if not part then
        hideGunDrop()
        return
    end

    if not gunHighlight or gunHighlight.Parent ~= HighlightFolder then
        gunHighlight = Instance.new("Highlight")
        gunHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        gunHighlight.FillColor = GUN_COLOR
        gunHighlight.OutlineColor = GUN_COLOR
        gunHighlight.FillTransparency = 0.35
        gunHighlight.OutlineTransparency = 0
        gunHighlight.Parent = HighlightFolder
    end
    if gunHighlight.Adornee ~= drop then
        gunHighlight.Adornee = drop
    end
    gunHighlight.Enabled = true

    if not gunBillboard or gunBillboard.Parent ~= HighlightFolder then
        gunBillboard, gunLabel = makePillTag("GunDropTag", 2.5, GUN_COLOR)
        gunLabel.TextColor3 = GUN_COLOR
        gunLastText = nil
    end
    if gunBillboard.Adornee ~= part then
        gunBillboard.Adornee = part
    end
    gunBillboard.Enabled = true

    local dist = (Camera.CFrame.Position - part.Position).Magnitude
    local text = string.format("Gun Dropped [%d]", math.floor(dist))
    if text ~= gunLastText then
        gunLastText = text
        gunLabel.Text = text
    end
end

-- ═══════════════════════════════════════════════════════════
--  9. ESP DE ROLES (Chams)
-- ═══════════════════════════════════════════════════════════
local roleHighlights = {} -- [player] = Highlight
local ROLE_KEYS = { Innocent = "RoleInnocent", Sheriff = "RoleSheriff", Murderer = "RoleMurderer" }

local nameTags = {} -- [player] = { gui, label, text }

local function removePlayer(player)
    local rh = roleHighlights[player]
    if rh then
        pcall(function() rh:Destroy() end)
        roleHighlights[player] = nil
    end

    local t = nameTags[player]
    if t then
        pcall(function() t.gui:Destroy() end)
        nameTags[player] = nil
    end
end

-- Esp Name: pílula com o nome e a distância acima da cabeça
-- (a borda ganha a cor do role só se o ESP desse role estiver ligado)
local function updateNameTag(player, char, show, role, dist)
    local t = nameTags[player]

    local head = show and char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
    if not head then
        if t and t.gui.Enabled then t.gui.Enabled = false end
        return
    end

    if not t or t.gui.Parent ~= HighlightFolder then
        if t then
            pcall(function() t.gui:Destroy() end)
        end
        local gui, label, stroke = makePillTag("NameTag", 2.4, NAME_NEUTRAL)
        t = { gui = gui, label = label, stroke = stroke, text = nil, color = NAME_NEUTRAL }
        nameTags[player] = t
    end

    if t.gui.Adornee ~= head then
        t.gui.Adornee = head
    end

    local color = (role and ROLE_COLORS[role]) or NAME_NEUTRAL
    if t.color ~= color then
        t.color = color
        t.stroke.Color = color
    end

    local nm = player.DisplayName
    if nm == nil or nm == "" then
        nm = player.Name
    end
    nm = nm:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")

    local text = string.format('%s <font color="#9ca3c0">[%d]</font>', nm, math.floor(dist or 0))
    if text ~= t.text then
        t.text = text
        t.label.Text = text
    end
    if not t.gui.Enabled then
        t.gui.Enabled = true
    end
end

local function updateRoleHighlight(player, char, role)
    local h = roleHighlights[player]

    if not role or not char then
        if h and h.Enabled then h.Enabled = false end
        return
    end

    if not h or h.Parent ~= HighlightFolder then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 0.6
        h.OutlineTransparency = 0
        h.Parent = HighlightFolder
        roleHighlights[player] = h
    end

    if h.Adornee ~= char then
        h.Adornee = char
    end
    local color = ROLE_COLORS[role]
    if h.FillColor ~= color then
        h.FillColor = color
        h.OutlineColor = color
    end
    if not h.Enabled then h.Enabled = true end
end

local function anyEspEnabled()
    return rolesNeeded() or State.GunDrop or State.EspName
end

local function stepPlayer(player, limit, camPos, needRoles)
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    local dist = nil
    if hum and root and hum.Health > 0 then
        dist = (camPos - root.Position).Magnitude
    end
    local inRange = dist ~= nil and dist <= limit

    local chamRole = nil
    if needRoles and inRange then
        local r = getRole(player)
        if State[ROLE_KEYS[r]] == true then
            chamRole = r
        end
    end
    updateRoleHighlight(player, char, chamRole)

    updateNameTag(player, char, State.EspName and inRange, chamRole, dist)
end

local function hideEverything()
    for _, h in pairs(roleHighlights) do
        h.Enabled = false
    end
    for _, t in pairs(nameTags) do
        t.gui.Enabled = false
    end
    hideGunDrop()
end

do
    local active = false
    local accum  = 0

    track(RunService.RenderStepped:Connect(function(dt)
        Camera = Workspace.CurrentCamera
        if not Camera then return end

        if not anyEspEnabled() then
            if active then
                active = false
                hideEverything()
            end
            return
        end
        active = true

        -- limita a taxa de atualização do ESP
        local stepT = Perf.espStep
        if stepT > 0 then
            accum = accum + dt
            if accum < stepT - 0.002 then return end
            accum = 0
        end

        local needRoles = rolesNeeded()
        local camPos    = Camera.CFrame.Position

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local ok, err = pcall(stepPlayer, player, ESP_MAX_DIST, camPos, needRoles)
                if not ok then safeWarn(err, "esp") end
            end
        end

        local okGun, errGun = pcall(updateGunDrop)
        if not okGun then safeWarn(errGun, "gundrop") end
    end))
end

track(Players.PlayerRemoving:Connect(removePlayer))

-- ═══════════════════════════════════════════════════════════
--  10. WEAPON - Pegar Arma Dropada (sem sair da posição)
--  1) toque remoto (firetouchinterest) -> não move o personagem
--  2) plano B: vai até a arma e VOLTA na hora pro mesmo lugar
-- ═══════════════════════════════════════════════════════════
local pickBusy = false

local function gunGone(target)
    return hasTool(LocalPlayer, "Gun") or not target:IsDescendantOf(Workspace)
end

local function waitGunGone(target, timeout)
    local t0 = os.clock()
    while os.clock() - t0 < timeout do
        if gunGone(target) then
            return true
        end
        task.wait(0.05)
    end
    return gunGone(target)
end

-- Retorna: ok (bool) e o motivo ("dead" | "nogun" | "hasgun" | "busy" | "fail")
local function pickGun(forceDeep)
    if pickBusy then
        return false, "busy"
    end

    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root and hum.Health > 0) then
        return false, "dead"
    end
    if hasTool(LocalPlayer, "Gun") then
        return false, "hasgun"
    end

    local drop = findGunDrop(forceDeep)
    if not drop then
        return false, "nogun"
    end
    local target = getGunPart(drop)
    if not target then
        return false, "nogun"
    end

    pickBusy = true

    -- Tudo protegido: pickBusy SEMPRE volta a false, mesmo se der erro
    local okRun, got = pcall(function()
        local success = false

        -- 1) Toque remoto
        if firetouchinterest then
            pcall(function()
                firetouchinterest(root, target, 0)
                task.wait()
                firetouchinterest(root, target, 1)
            end)
            success = waitGunGone(target, 0.4)
        end

        -- 2) Plano B: vai e volta
        if not success then
            local origin = root.CFrame
            pcall(function()
                root.CFrame = target.CFrame
                if firetouchinterest then
                    firetouchinterest(root, target, 0)
                    firetouchinterest(root, target, 1)
                end
            end)
            success = waitGunGone(target, 0.5)
            pcall(function()
                if root.Parent then
                    root.CFrame = origin
                    root.AssemblyLinearVelocity = Vector3.zero
                end
            end)
        end

        return success
    end)

    pickBusy = false

    if okRun and got then
        return true
    end
    return false, "fail"
end

-- ───────── Botão quadrado com ícone (Mobile) ─────────
local PICK_SIZE   = 62
local PICK_PRESS  = 54
local PickGui = newScreenGui("BukPickGui", 100)

local PickBtn = Instance.new("TextButton")
PickBtn.Name = "PickButton"
PickBtn.AnchorPoint = Vector2.new(0.5, 0.5)
PickBtn.Position = UDim2.new(0.92, 0, 0.45, 0)
PickBtn.Size = UDim2.fromOffset(PICK_SIZE, PICK_SIZE)
PickBtn.BackgroundColor3 = WHITE
PickBtn.BackgroundTransparency = 0.08
PickBtn.AutoButtonColor = false
PickBtn.Text = ""
PickBtn.Visible = false
PickBtn.Parent = PickGui

local PickStroke = Instance.new("UIStroke")
do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = PickBtn

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Color3.fromRGB(58, 24, 28), Color3.fromRGB(12, 10, 12))
    gradient.Rotation = 90
    gradient.Parent = PickBtn

    PickStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    PickStroke.Color = ACCENT
    PickStroke.Thickness = 2
    PickStroke.Transparency = 0.1
    PickStroke.Parent = PickBtn
end

local PickIcon = Instance.new("TextLabel")
PickIcon.BackgroundTransparency = 1
PickIcon.Position = UDim2.new(0, 0, 0, 5)
PickIcon.Size = UDim2.new(1, 0, 0, 36)
PickIcon.ZIndex = 2
PickIcon.Font = Enum.Font.GothamBold
PickIcon.TextSize = 28
PickIcon.TextColor3 = WHITE
PickIcon.Text = "🔫"
PickIcon.Parent = PickBtn

local PICK_LABEL_COLOR = Color3.fromRGB(200, 205, 225)

local PickLabel = Instance.new("TextLabel")
PickLabel.BackgroundTransparency = 1
PickLabel.Position = UDim2.new(0, 0, 1, -20)
PickLabel.Size = UDim2.new(1, 0, 0, 16)
PickLabel.ZIndex = 2
PickLabel.Font = Enum.Font.GothamBold
PickLabel.TextSize = 10
PickLabel.TextColor3 = PICK_LABEL_COLOR
PickLabel.Text = L("pick_cap")
PickLabel.Parent = PickBtn

local function refreshPickButton()
    PickLabel.Text = L("pick_cap")
end

local function setPickButtonVisible(v)
    PickBtn.Visible = v and true or false
end

local function tweenPickSize(px)
    pcall(function()
        TweenService:Create(PickBtn, TweenInfo.new(0.08), { Size = UDim2.fromOffset(px, px) }):Play()
    end)
end

local flashToken = 0
local function flashPick(text, color)
    flashToken = flashToken + 1
    local mine = flashToken
    PickLabel.Text = text
    PickLabel.TextColor3 = color
    PickStroke.Color = color
    task.delay(1, function()
        if mine == flashToken and PickBtn.Parent then
            PickLabel.Text = L("pick_cap")
            PickLabel.TextColor3 = PICK_LABEL_COLOR
            PickStroke.Color = ACCENT
        end
    end)
end

local PICK_FAIL_KEYS = {
    nogun  = { "pick_nogun",  "flash_nogun"  },
    dead   = { "pick_dead",   "flash_dead"   },
    hasgun = { "pick_hasgun", "flash_hasgun" },
    fail   = { "pick_fail",   "flash_fail"   },
}

-- Pegar manualmente (botão da tela e atalho de teclado usam a mesma função)
local function manualPick()
    local ok, reason = pickGun(true)
    if reason == "busy" then return end

    if ok then
        notify(L("pick_ok"), "check")
        flashPick(L("flash_ok"), ROLE_COLORS.Innocent)
    else
        local keys = PICK_FAIL_KEYS[reason] or PICK_FAIL_KEYS.fail
        notify(L(keys[1]), "triangle-alert")
        flashPick(L(keys[2]), ROLE_COLORS.Murderer)
    end
end

-- Arrastar move o botão (sem sair da tela), tocar sem arrastar pega a arma
do
    local dragging    = false
    local moved       = false
    local dragInput   = nil
    local dragStart   = nil
    local startCenter = nil

    PickBtn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging    = true
        moved       = false
        dragInput   = input
        dragStart   = input.Position
        startCenter = PickBtn.AbsolutePosition + PickBtn.AbsoluteSize / 2
        tweenPickSize(PICK_PRESS)

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                conn:Disconnect()
                dragging = false
                tweenPickSize(PICK_SIZE)
                if not moved then
                    task.spawn(manualPick)
                end
            end
        end)
    end)

    track(UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragInput then return end

        if dragInput.UserInputType == Enum.UserInputType.Touch then
            if input ~= dragInput then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - dragStart
        if delta.Magnitude > 10 then
            moved = true
        end
        if moved then
            local cam  = Workspace.CurrentCamera
            local vp   = cam and cam.ViewportSize or Vector2.new(1280, 720)
            local half = Vector2.new(PICK_SIZE, PICK_SIZE) / 2
            local nx = math.clamp(startCenter.X + delta.X, half.X, vp.X - half.X)
            local ny = math.clamp(startCenter.Y + delta.Y, half.Y, vp.Y - half.Y)
            PickBtn.Position = UDim2.fromOffset(nx, ny)
        end
    end))
end

-- Atalho de teclado (PC)
track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if State.PickKeyOn and State.PickKey and input.KeyCode == State.PickKey then
        task.spawn(manualPick)
    end
end))

-- Automático: pega assim que a arma cair
do
    local tries = setmetatable({}, { __mode = "k" })

    loop("autopick", 0.2, function()
        if not State.PickAuto or pickBusy or hasTool(LocalPlayer, "Gun") then
            return
        end

        local drop = findGunDrop(false)
        if drop and (tries[drop] or 0) < 4 then
            local ok, reason = pickGun(false)
            if ok then
                notify(L("pick_auto_ok"), "check")
            elseif reason == "fail" then
                tries[drop] = (tries[drop] or 0) + 1
                task.wait(1)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  11. AUTO FARM DE MOEDAS (MM2)
--  - Anda até cada moeda com Tween (velocidade fixa em 22)
--  - SÓ funciona dentro da partida (vivo, com roles definidos e mapa/moedas no jogo)
--  - Modo Seguro: pausas aleatórias, sorteia entre as 3 moedas mais
--    próximas e pausa se o murder chegar perto
--  - Moeda que não dá pra alcançar é descartada após 3 tentativas
--  Obs.: nenhum script garante 100% contra detecção. Use com moderação.
-- ═══════════════════════════════════════════════════════════
local farmContainer = nil
local farmVisited   = {}
local farmTries     = setmetatable({}, { __mode = "k" })
local farmCount     = 0
local farmFullFor   = nil
local farmMoving    = false
local farmScanAt    = 0
local farmIdleAt    = nil

local mnAt, mnVal = 0, false
local function murderNear(root, radius)
    local now = os.clock()
    if now - mnAt < 0.2 then
        return mnVal
    end
    mnAt  = now
    mnVal = false

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c = p.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 and (r.Position - root.Position).Magnitude <= radius then
                if getRole(p) == "Murderer" then
                    mnVal = true
                    break
                end
            end
        end
    end
    return mnVal
end

-- Você está DENTRO da partida? (vivo, participando da rodada e fora do vazio/limbo)
-- Fora disso o Auto Farm para sozinho e volta quando você entrar numa partida de novo.
-- Os dados do jogo podem oscilar por um instante, então existe uma tolerância de 2s
-- (menos quando você morre: aí para na hora).
local matchOkAt = 0
local function inMatch()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root and hum.Health > 0) then
        matchOkAt = 0
        return false -- morreu / sem personagem
    end

    local ok = true
    if deadData[LocalPlayer.Name] then
        ok = false -- o jogo marcou você como morto na rodada
    elseif getPlayerDataRemote and roleData[LocalPlayer.Name] == nil then
        ok = false -- sem role = está no lobby / não entrou na rodada
    elseif root.Position.Y <= Workspace.FallenPartsDestroyHeight + 50 then
        ok = false -- caiu no vazio / limbo
    end

    local now = os.clock()
    if ok then
        matchOkAt = now
        return true
    end
    return matchOkAt > 0 and now - matchOkAt < 2
end

local function findCoinContainer()
    if farmContainer and farmContainer:IsDescendantOf(Workspace) then
        return farmContainer
    end
    local now = os.clock()
    if now - farmScanAt < 1 then
        return nil
    end
    farmScanAt = now
    return Workspace:FindFirstChild("CoinContainer", true)
end

local function coinAvailable(coin)
    return coin:IsA("BasePart")
        and coin:FindFirstChild("CoinVisual") ~= nil
        and not farmVisited[coin]
end

local function pickCoin(container, from)
    local list = {}
    for _, c in ipairs(container:GetChildren()) do
        if coinAvailable(c) then
            list[#list + 1] = { coin = c, dist = (c.Position - from).Magnitude }
        end
    end
    if #list == 0 then
        return nil
    end

    table.sort(list, function(a, b)
        return a.dist < b.dist
    end)

    local idx = 1
    if State.FarmSafe then
        idx = math.random(1, math.min(3, #list))
    end
    return list[idx].coin
end

-- Anda até a moeda. Retorna: "reached" | "murder" | "gone" | "timeout" | "stopped"
local function farmMoveTo(root, hum, coin)
    local goal = coin.CFrame
    local dist = (root.Position - goal.Position).Magnitude
    local dur  = math.max(dist / math.max(State.FarmSpeed, 1), 0.05)
    local tween = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = goal })

    local done = false
    local conn = tween.Completed:Connect(function()
        done = true
    end)
    tween:Play()

    local result = "timeout"
    local t0 = os.clock()
    while alive and State.FarmOn and os.clock() - t0 < dur + 1.5 do
        if done then
            result = "reached"
            break
        end
        if not (root.Parent and coin.Parent and hum.Health > 0) then
            result = "gone"
            break
        end
        if not inMatch() then
            result = "stopped"
            break
        end
        if State.FarmSafe and murderNear(root, 30) then
            result = "murder"
            break
        end
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait()
    end

    conn:Disconnect()
    tween:Cancel()

    if result == "timeout" and not (alive and State.FarmOn) then
        result = "stopped"
    end
    return result
end

-- Atravessa paredes só enquanto anda até a moeda (lista de peças em cache)
do
    local parts, partsAt, partsChar = {}, 0, nil

    track(RunService.Stepped:Connect(function()
        if not (State.FarmOn and farmMoving) then return end

        local char = LocalPlayer.Character
        if not char then return end

        local now = os.clock()
        if char ~= partsChar or now - partsAt > Perf.cacheRefresh then
            partsChar, partsAt, parts = char, now, {}
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    parts[#parts + 1] = d
                end
            end
        end

        for i = 1, #parts do
            local part = parts[i]
            if part.CanCollide and part.Parent then
                part.CanCollide = false
            end
        end
    end))
end

loop("farm", 0.03, function()
    if not State.FarmOn then
        farmMoving = false
        return
    end
    if flingRunning then return end -- Fling ativo: o Auto Farm espera

    -- Fora da partida (morreu, lobby, limbo...): não faz nada
    if not inMatch() then
        farmMoving = false
        return
    end

    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local container = findCoinContainer()

    -- Mapa novo = partida nova: zera o contador
    if container ~= farmContainer then
        farmContainer = container
        farmVisited   = {}
        farmTries     = setmetatable({}, { __mode = "k" })
        farmCount     = 0
        farmFullFor   = nil
    end

    if not (hum and root and hum.Health > 0 and container) or farmFullFor == container then
        return
    end

    if farmCount >= State.FarmLimit then
        farmFullFor = container
        notify(L("farm_full"), "check")
        if State.FarmReset then
            hum.Health = 0
        end
        return
    end

    -- Murder perto: fica parado e espera
    if State.FarmSafe and murderNear(root, 30) then
        return
    end

    local coin = pickCoin(container, root.Position)
    if not coin then
        -- sem moeda livre: depois de 3s libera as já visitadas que ainda existem
        farmIdleAt = farmIdleAt or os.clock()
        if os.clock() - farmIdleAt > 3 then
            farmIdleAt = nil
            farmVisited = {}
            farmTries   = setmetatable({}, { __mode = "k" })
        end
        return
    end
    farmIdleAt = nil

    farmMoving = true
    local okMove, result = pcall(farmMoveTo, root, hum, coin)
    farmMoving = false

    if not okMove then
        safeWarn(result, "farm-move")
        return
    end

    if result == "reached" then
        -- espera só o tempo de a moeda ser coletada e já segue pra próxima
        local t0 = os.clock()
        while coin.Parent and coin:FindFirstChild("CoinVisual") and os.clock() - t0 < 0.35 do
            task.wait()
        end
        if not coin.Parent or not coin:FindFirstChild("CoinVisual") then
            farmCount = farmCount + 1
            farmVisited[coin] = true
        else
            -- não coletou: tenta de novo (até 3 vezes) em vez de ignorar a moeda pra sempre
            farmTries[coin] = (farmTries[coin] or 0) + 1
            if farmTries[coin] >= 3 then
                farmVisited[coin] = true
            end
        end

        if State.FarmSafe then
            task.wait(0.02 + math.random() * 0.08)
        end

    elseif result == "timeout" then
        -- moeda que não dá pra alcançar: desiste depois de 3 tentativas
        farmTries[coin] = (farmTries[coin] or 0) + 1
        if farmTries[coin] >= 3 then
            farmVisited[coin] = true
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
--  12. MAIN: CFrame, Infinite Jump, Noclip, Anti-Fling
-- ═══════════════════════════════════════════════════════════

-- CFrame (só funciona no ar, pulando e correndo)
local function isInAir(hum)
    if hum.FloorMaterial ~= Enum.Material.Air then
        return false
    end
    local st = hum:GetState()
    return st == Enum.HumanoidStateType.Jumping
        or st == Enum.HumanoidStateType.Freefall
end

track(RunService.Heartbeat:Connect(function(dt)
    if not State.CFrameOn then return end
    if (State.FarmOn and farmMoving) or flingRunning then return end

    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) or hum.Health <= 0 then return end
    if not isInAir(hum) then return end

    local dir = hum.MoveDirection
    if dir.Magnitude < 0.1 then return end

    root.CFrame = root.CFrame + (dir * State.CFrameSpeed * dt)
end))

-- Infinite Jump
track(UserInputService.JumpRequest:Connect(function()
    if not State.InfJump then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

-- Noclip e Anti-Fling (guardam o CanCollide original para restaurar ao desligar)
local noclipBackup = setmetatable({}, { __mode = "k" })
local antiBackup   = setmetatable({}, { __mode = "k" })

local function restoreBackup(backup)
    for part, original in pairs(backup) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = original
            end)
        end
        backup[part] = nil
    end
end

do
    local noclipWas   = false
    local noclipChar  = nil
    local noclipParts = {}
    local noclipAt    = 0
    local antiParts   = {}
    local antiAt      = 0

    track(RunService.Stepped:Connect(function()
        -- Noclip (lista de peças em cache). Pausa enquanto o Fling roda
        -- (o Fling precisa de colisão pra funcionar).
        if State.Noclip and not flingRunning then
            noclipWas = true
            local char = LocalPlayer.Character
            if char then
                local now = os.clock()
                if char ~= noclipChar or now - noclipAt > Perf.cacheRefresh then
                    noclipChar  = char
                    noclipAt    = now
                    noclipParts = {}
                    for _, d in ipairs(char:GetDescendants()) do
                        if d:IsA("BasePart") then
                            noclipParts[#noclipParts + 1] = d
                        end
                    end
                end
                for i = 1, #noclipParts do
                    local part = noclipParts[i]
                    if part.CanCollide and part.Parent then
                        if noclipBackup[part] == nil then
                            noclipBackup[part] = true
                        end
                        part.CanCollide = false
                    end
                end
            end
        elseif noclipWas then
            noclipWas  = false
            noclipChar = nil
            restoreBackup(noclipBackup)
        end

        -- Anti-Fling: tira a colisão dos OUTROS jogadores com você
        -- (pausa enquanto o Fling roda, senão o alvo não seria atingido)
        if State.AntiFling and not flingRunning then
            local now = os.clock()
            if now - antiAt > math.min(Perf.cacheRefresh, 0.75) then
                antiAt    = now
                antiParts = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        for _, part in ipairs(p.Character:GetChildren()) do
                            if part:IsA("BasePart") then
                                antiParts[#antiParts + 1] = part
                            end
                        end
                    end
                end
            end
            for i = 1, #antiParts do
                local part = antiParts[i]
                if part.CanCollide and part.Parent then
                    if antiBackup[part] == nil then
                        antiBackup[part] = true
                    end
                    part.CanCollide = false
                end
            end
        else
            antiAt = 0
            if flingRunning then
                restoreBackup(antiBackup)
            end
        end
    end))
end

-- Anti-Fling: se começar a girar/voar rápido demais, zera a velocidade
track(RunService.Heartbeat:Connect(function()
    if not State.AntiFling or flingRunning then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if root.AssemblyAngularVelocity.Magnitude > 100
        or root.AssemblyLinearVelocity.Magnitude > 300 then
        root.AssemblyAngularVelocity = Vector3.zero
        root.AssemblyLinearVelocity  = Vector3.zero
    end
end))

-- ═══════════════════════════════════════════════════════════
--  12B. TROLL: FLING
--  - Gira o seu personagem em alta velocidade em cima do player escolhido
--  - Força sempre no máximo (sem slider de velocidade)
--  - Guarda a posição de origem e volta pra ela quando desliga
--  - Pausa Noclip / Anti-Fling / CFrame / Auto Farm enquanto roda
-- ═══════════════════════════════════════════════════════════
local FLING_LIN = 9e7 -- força máxima (fixa)
local FLING_ANG = 9e8
local FLING_OFFSETS = {
    CFrame.new(0, 1.5, 0),
    CFrame.new(0, -1.5, 0),
    CFrame.new(2.25, 1.5, -2.25),
    CFrame.new(-2.25, -1.5, 2.25),
}

local flingToken    = 0
local FlingDropdown = nil -- preenchidos pelo buildUI
local FlingToggle   = nil

local function flingList(leaving)
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p ~= leaving then
            names[#names + 1] = p.Name
        end
    end
    table.sort(names, function(a, b)
        return a:lower() < b:lower()
    end)
    return names
end

-- Alvos específicos (os nomes de jogador não podem ter "[", então não conflita)
local FLING_ROLE_TARGETS = { ["[Sheriff]"] = "Sheriff", ["[Murderer]"] = "Murderer" }

-- Lista do dropdown do Fling: [Sheriff], [Murderer] e depois os jogadores
local function flingValues(leaving)
    local values = { "[Sheriff]", "[Murderer]" }
    for _, n in ipairs(flingList(leaving)) do
        values[#values + 1] = n
    end
    return values
end

-- Acha quem está com o role escolhido (prefere quem está vivo, então troca sozinho
-- se o Sheriff morrer e outro jogador pegar a arma)
local function flingRolePlayer(role)
    local fallback = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and getRole(p) == role then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and not deadData[p.Name] then
                return p
            end
            fallback = fallback or p
        end
    end
    return fallback
end

local function refreshFlingList(leaving)
    if not FlingDropdown then return end
    pcall(function()
        FlingDropdown:Refresh(flingValues(leaving))
    end)
end

track(Players.PlayerAdded:Connect(function()
    refreshFlingList()
end))
track(Players.PlayerRemoving:Connect(function(p)
    refreshFlingList(p)
end))

-- Retorna: char, humanoid, root (ou nil se você estiver morto)
local function flingMyChar()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 and root.Parent then
        return char, hum, root
    end
    return nil
end

-- Retorna: player (nil se saiu do jogo), humanoid e root (nil se morto/respawnando)
local function flingTargetInfo()
    local name = State.FlingTarget
    local role = type(name) == "string" and FLING_ROLE_TARGETS[name] or nil
    local p
    if role then
        p = flingRolePlayer(role)
    else
        p = type(name) == "string" and Players:FindFirstChild(name) or nil
    end
    if not (p and p:IsA("Player")) or p == LocalPlayer then
        return nil
    end
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health > 0 then
        return p, h, r
    end
    return p, nil, nil
end

-- Segura o personagem parado num lugar (zera a velocidade/giro)
local function flingSettle(root, cf, frames)
    for _ = 1, frames do
        if not root.Parent then return end
        root.CFrame = cf
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait()
    end
end

local function flingLoop(myToken)
    -- se um Fling anterior ainda está terminando, espera ele acabar
    local waited = os.clock()
    while flingRunning and os.clock() - waited < 1.5 do
        task.wait()
    end
    if not alive or flingToken ~= myToken then return end

    flingRunning = true
    local reason     = "off"
    local origin     = nil
    local oldDestroy = nil

    local okRun, err = pcall(function()
        local _, _, startRoot = flingMyChar()
        if not startRoot then
            reason = "dead"
            return
        end
        origin = startRoot.CFrame

        -- evita morrer no void enquanto você está girando
        pcall(function()
            oldDestroy = Workspace.FallenPartsDestroyHeight
            Workspace.FallenPartsDestroyHeight = 0 / 0
        end)

        local angle, idx = 0, 0
        local cycleStart = os.clock()

        while alive and flingToken == myToken and State.Fling do
            local _, cHum, cRoot = flingMyChar()
            if not cRoot then
                reason = "dead"
                break
            end

            local target, tHum, tRoot = flingTargetInfo()
            if not target then
                reason = FLING_ROLE_TARGETS[State.FlingTarget] and "norole" or "left"
                break
            end

            if tHum and tRoot then
                -- a câmera acompanha o alvo (evita enjoo com seu personagem girando)
                pcall(function()
                    local cam = Workspace.CurrentCamera
                    if cam and cam.CameraSubject ~= tHum then
                        cam.CameraSubject = tHum
                    end
                end)

                local speed = tRoot.AssemblyLinearVelocity.Magnitude
                if speed > 500 or os.clock() - cycleStart > 2 then
                    -- o alvo já voou (ou não funcionou): volta pro lugar e tenta de novo
                    flingSettle(cRoot, origin, 12)
                    task.wait(0.25)
                    cycleStart = os.clock()
                else
                    angle = angle + 100
                    idx = idx % #FLING_OFFSETS + 1
                    local lead = tHum.MoveDirection * (speed / 1.25)
                    cRoot.CFrame = CFrame.new(tRoot.Position + lead)
                        * FLING_OFFSETS[idx]
                        * CFrame.Angles(math.rad(angle), 0, 0)
                    cRoot.AssemblyLinearVelocity  = Vector3.new(FLING_LIN, FLING_LIN * 10, FLING_LIN)
                    cRoot.AssemblyAngularVelocity = Vector3.new(FLING_ANG, FLING_ANG, FLING_ANG)
                    task.wait()
                end
            else
                -- alvo morto/respawnando: fica parado e espera (a origem acompanha você)
                pcall(function()
                    local cam = Workspace.CurrentCamera
                    if cam and cHum and cam.CameraSubject ~= cHum then
                        cam.CameraSubject = cHum
                    end
                end)
                origin = cRoot.CFrame
                cycleStart = os.clock()
                task.wait(0.2)
            end
        end
    end)

    if not okRun then
        reason = "error"
        safeWarn(err, "fling")
    end

    -- Limpeza (sempre roda): volta pra posição original e restaura câmera/altura de queda
    pcall(function()
        local _, hum2, root2 = flingMyChar()
        if root2 and origin then
            flingSettle(root2, origin, 20)
        end
        local cam = Workspace.CurrentCamera
        if cam and hum2 then
            cam.CameraSubject = hum2
        end
    end)
    pcall(function()
        if oldDestroy ~= nil then
            Workspace.FallenPartsDestroyHeight = oldDestroy
        end
    end)
    flingRunning = false

    -- Parou sozinho (morreu, o alvo saiu...): desliga o botão
    if reason ~= "off" and alive and flingToken == myToken then
        State.Fling = false
        if reason == "dead" then
            notify(L("fling_dead"), "triangle-alert", 3)
        elseif reason == "left" then
            notify(L("fling_left"), "triangle-alert", 3)
        elseif reason == "norole" then
            notify(L("fling_norole"), "triangle-alert", 3)
        end
        pcall(function()
            if FlingToggle then
                FlingToggle:Set(false)
            end
        end)
    end
end

local function stopFling()
    flingToken = flingToken + 1 -- o loop percebe, limpa tudo e termina
end

-- Retorna: ok (bool) e o motivo ("dead" | "notarget" | "tdead")
local function startFling()
    if not flingMyChar() then
        return false, "dead"
    end
    local target, tHum, tRoot = flingTargetInfo()
    if not target then
        if FLING_ROLE_TARGETS[State.FlingTarget] then
            return false, "norole"
        end
        return false, "notarget"
    end
    if not (tHum and tRoot) then
        return false, "tdead"
    end

    flingToken = flingToken + 1
    task.spawn(flingLoop, flingToken)
    return true
end

-- ═══════════════════════════════════════════════════════════
--  13. AIMBOT MM2: Magic Bullet, Shoot Through Walls e Auto Pick
--  - Magic Bullet: a bala do SEU tiro vai direto pro murder (posição lida na hora do tiro)
--  - Shoot Through Walls: parede não bloqueia o tiro (raycast da Gun + tag WeaponPassthrough)
--  - Auto Pick Dropped Gun: só pega a arma dropada (não atira sozinho)
-- ═══════════════════════════════════════════════════════════
local magicAim  = nil
local forcedAim = nil

local function getGun()
    local char = LocalPlayer.Character
    local g = char and char:FindFirstChild("Gun")
    if g and g:IsA("Tool") then
        return g, true
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    g = bp and bp:FindFirstChild("Gun")
    if g and g:IsA("Tool") then
        return g, false
    end
    return nil, false
end

-- Retorna o personagem e o HumanoidRootPart se o jogador estiver vivo
local function playerAliveChar(p)
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health > 0 and not deadData[p.Name] then
        return c, r
    end
    return nil, nil
end

local murdCache, murdAt = nil, 0
local function findMurderer()
    local now = os.clock()
    if now - murdAt < 0.1 then
        return murdCache
    end
    murdAt    = now
    murdCache = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and getRole(p) == "Murderer" and playerAliveChar(p) then
            murdCache = p
            break
        end
    end
    return murdCache
end

-- Estado do Aimbot MM2 (tudo numa tabela só, pra não estourar o limite de variáveis locais)
local Aim = {
    active   = false, -- true quando dá pra atirar (vivo, com Gun, não é murder, murder vivo)
    char     = nil,   -- personagem do murder
    root     = nil,   -- HumanoidRootPart do murder
    head     = nil,   -- Head do murder
    gun      = nil,   -- a Tool "Gun"
    equipped = false, -- Gun na mão
    ping     = 0.1,   -- ping em segundos (compensação do tiro)
    tagged   = {},    -- peças que EU marquei como atravessáveis (Shoot Through Walls)
    taggedN  = 0,
}

-- Ping atual em segundos
function Aim.pingNow()
    local ok, v = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and type(v) == "number" then
        return v / 1000
    end
    local ok2, p = pcall(function()
        return LocalPlayer:GetNetworkPing()
    end)
    if ok2 and type(p) == "number" then
        return p
    end
    return 0.1
end

-- Ponto de mira (lido NA HORA do tiro, então nunca fica velho):
-- Torso (HumanoidRootPart) ou Head + previsão de movimento pelo ping
function Aim.point()
    local root = Aim.root
    if not (root and root.Parent) then
        return nil
    end

    local part = root
    if State.AimPart == "Head" and Aim.head and Aim.head.Parent then
        part = Aim.head
    end

    local pos = part.Position
    if State.AimPredict then
        local vel = root.AssemblyLinearVelocity
        vel = Vector3.new(vel.X, 0, vel.Z)
        if vel.Magnitude > 60 then
            vel = vel.Unit * 60
        end
        pos = pos + vel * math.clamp(Aim.ping, 0, 0.3)
    end
    return pos
end

-- Shoot Through Walls (parte 1): remove as marcas que EU coloquei
function Aim.clearTags()
    for part in pairs(Aim.tagged) do
        pcall(function()
            CollectionService:RemoveTag(part, "WeaponPassthrough")
        end)
        Aim.tagged[part] = nil
    end
    Aim.taggedN = 0
end

-- Shoot Through Walls (parte 2): tudo que estiver entre você e o murder
-- recebe a tag "WeaponPassthrough" (a mesma que o jogo usa pras peças que a bala atravessa)
function Aim.markWalls(fromPos, toPos, mChar)
    if Aim.taggedN > 250 then
        Aim.clearTags()
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local ex  = { LocalPlayer.Character, mChar }
    local dir = toPos - fromPos

    for _ = 1, 12 do
        params.FilterDescendantsInstances = ex
        local hit = Workspace:Raycast(fromPos, dir, params)
        if not hit then break end

        local part = hit.Instance
        if not part then break end
        ex[#ex + 1] = part

        if part:IsA("BasePart") and not part:IsA("Terrain")
            and not CollectionService:HasTag(part, "WeaponPassthrough") then
            CollectionService:AddTag(part, "WeaponPassthrough")
            Aim.tagged[part] = true
            Aim.taggedN = Aim.taggedN + 1
        end
    end
end

-- Em qual argumento do remote vai a posição do tiro?
function Aim.findSlot(args, count)
    local a2 = typeof(args[2])
    if a2 == "CFrame" or a2 == "Vector3" then
        return 2
    end
    for i = 1, count do
        if typeof(args[i]) == "Vector3" then
            return i
        end
    end
    for i = count, 1, -1 do
        if typeof(args[i]) == "CFrame" then
            return i
        end
    end
    return nil
end

-- Esse remote é o tiro da Gun?
function Aim.isShootRemote(inst)
    local parent = inst.Parent
    return inst.Name:lower():find("shoot", 1, true) ~= nil
        or (parent ~= nil and parent.Name == "CreateBeam")
end

-- O raycast veio do script da Gun (e não de outro script do jogo)?
function Aim.callerIsGun()
    if not getcallingscript then
        return true
    end
    local ok, scr = pcall(getcallingscript)
    if not ok or typeof(scr) ~= "Instance" then
        return true
    end

    local node, depth = scr, 0
    while node and depth < 12 do
        if node == Aim.gun then
            return true
        end
        node  = node.Parent
        depth = depth + 1
    end

    local n = scr.Name:lower()
    return n:find("knife", 1, true) ~= nil or n:find("gun", 1, true) ~= nil
end

-- Hook do tiro (precisa de executor com hookmetamethod ou getrawmetatable)
local hookInstalled = false
local oldNamecall   = nil

local function aimHandler(self, ...)
    if not (alive and Aim.active) or typeof(self) ~= "Instance" then
        return oldNamecall(self, ...)
    end

    local method = getnamecallmethod()

    if not (checkcaller and checkcaller()) then
        -- 1) MAGIC BULLET: troca a posição do tiro pela posição do murder
        if State.MagicBullet
            and (method == "FireServer" or method == "InvokeServer")
            and Aim.isShootRemote(self) then

            local aim = Aim.point()
            if aim then
                local args  = { ... }
                local count = select("#", ...)
                local slot  = Aim.findSlot(args, count)

                if slot then
                    if typeof(args[slot]) == "CFrame" then
                        args[slot] = CFrame.new(aim)
                    else
                        args[slot] = aim
                    end
                    State.MagicShots = (State.MagicShots or 0) + 1
                    if setnamecallmethod then
                        setnamecallmethod(method)
                    end
                    return oldNamecall(self, unpack(args, 1, count))
                end
            end

        -- 2) SHOOT THROUGH WALLS: o raycast da Gun só enxerga o murder (parede não bloqueia)
        elseif State.WallShot and Aim.equipped
            and method == "Raycast" and self == Workspace then

            local origin, direction = ...
            if typeof(origin) == "Vector3" and typeof(direction) == "Vector3"
                and Aim.char and Aim.char.Parent and Aim.callerIsGun() then

                -- com Magic Bullet ligado, o raio também aponta direto pro murder
                local aim = State.MagicBullet and Aim.point()
                if aim then
                    local to = aim - origin
                    if to.Magnitude > 0.1 then
                        direction = to.Unit * math.max(direction.Magnitude, to.Magnitude + 5)
                    end
                end

                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Include
                params.FilterDescendantsInstances = { Aim.char }
                params.IgnoreWater = true

                if setnamecallmethod then
                    setnamecallmethod(method)
                end
                return oldNamecall(self, origin, direction, params)
            end
        end
    end

    if setnamecallmethod then
        setnamecallmethod(method)
    end
    return oldNamecall(self, ...)
end

local function installAimHook()
    if hookInstalled then
        return true
    end
    if not getnamecallmethod then
        return false
    end

    local fn = newcclosure and newcclosure(aimHandler) or aimHandler

    if hookmetamethod then
        local ok, old = pcall(hookmetamethod, game, "__namecall", fn)
        if ok and old ~= nil then
            oldNamecall = old
            hookInstalled = true
            return true
        end
    end

    local ok = pcall(function()
        local mt = getrawmetatable(game)
        oldNamecall = mt.__namecall
        if setreadonly then
            setreadonly(mt, false)
        elseif make_writeable then
            make_writeable(mt)
        end
        mt.__namecall = fn
        if setreadonly then
            setreadonly(mt, true)
        end
    end)

    hookInstalled = (ok and oldNamecall ~= nil)
    return hookInstalled
end

-- Escolhe o alvo (~20x por segundo) e mantém o ponto de mira sempre atualizado
do
    local scanAt, pingAt, wallAt = 0, 0, 0
    State.MagicStatus = "off"

    local function clearTarget()
        Aim.active, Aim.equipped = false, false
        Aim.char, Aim.root, Aim.head, Aim.gun = nil, nil, nil, nil
        magicAim = nil
        if Aim.taggedN > 0 then
            Aim.clearTags()
        end
    end

    track(RunService.Heartbeat:Connect(function()
        if not (State.MagicBullet or State.WallShot) then
            if Aim.active or Aim.taggedN > 0 then
                clearTarget()
            end
            State.MagicStatus = "off"
            return
        end

        local now = os.clock()

        if now - pingAt > 0.5 then
            pingAt = now
            Aim.ping = Aim.pingNow()
        end

        if now - scanAt >= 0.05 then
            scanAt = now

            local ok, err = pcall(function()
                if not hookInstalled then
                    clearTarget()
                    State.MagicStatus = "nohook"
                    return
                end

                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not (char and root) then
                    clearTarget()
                    State.MagicStatus = "dead"
                    return
                end

                local gun, equipped = getGun()
                if not gun then
                    clearTarget()
                    State.MagicStatus = "nogun"
                    return
                end
                if getRole(LocalPlayer) == "Murderer" then
                    clearTarget()
                    State.MagicStatus = "murderer"
                    return
                end

                local murderer = findMurderer()
                if not murderer then
                    clearTarget()
                    State.MagicStatus = "nomurder"
                    return
                end
                local mChar, mRoot = playerAliveChar(murderer)
                if not mRoot then
                    clearTarget()
                    State.MagicStatus = "nomurder"
                    return
                end

                Aim.char, Aim.root, Aim.head = mChar, mRoot, mChar:FindFirstChild("Head")
                Aim.gun, Aim.equipped = gun, equipped
                Aim.active = true
                State.MagicStatus = "ready"

                -- Shoot Through Walls: marca o que está entre você e o murder
                if State.WallShot and now - wallAt >= 0.12 then
                    wallAt = now
                    Aim.markWalls(root.Position, mRoot.Position, mChar)
                end
            end)

            if not ok then
                clearTarget()
                safeWarn(err, "magic")
            end
        end

        magicAim = Aim.active and Aim.point() or nil
    end))
end

-- Auto Pick Dropped Gun (só pega a arma dropada, não atira)
do
    local tries = setmetatable({}, { __mode = "k" })

    loop("autopickgun", 0.1, function()
        if not State.AutoPickGun then return end

        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and root and hum.Health > 0) then return end
        if getRole(LocalPlayer) == "Murderer" then return end
        if pickBusy or hasTool(LocalPlayer, "Gun") then return end

        local drop = findGunDrop(false)
        if drop and (tries[drop] or 0) < 4 then
            local ok, reason = pickGun(false)
            if ok then
                notify(L("pick_auto_ok"), "check")
            elseif reason == "fail" then
                tries[drop] = (tries[drop] or 0) + 1
                task.wait(1)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  14. SETAS pro Murder / Sheriff (só quando estão fora da tela)
-- ═══════════════════════════════════════════════════════════
local trackedMurderer = nil
local trackedSheriff  = nil

-- Descobre quem é o Murderer e o Sheriff (vivos) ~5x por segundo
loop("track-roles", function() return math.max(0.2, Perf.roleStep) end, function()
    if not (State.ArrowMurder or State.ArrowSheriff) then
        trackedMurderer = nil
        trackedSheriff  = nil
        return
    end

    local m, s = nil, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                local role = getRole(p)
                if role == "Murderer" then
                    m = p
                elseif role == "Sheriff" then
                    s = p
                end
            end
        end
    end
    trackedMurderer = m
    trackedSheriff  = s
end)

local ArrowGui = newScreenGui("BukArrowGui", 90)

local function makeArrow(color)
    local arrow = Instance.new("TextLabel")
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Size = UDim2.fromOffset(34, 34)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▲"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 30
    arrow.TextColor3 = color
    arrow.TextStrokeTransparency = 0
    arrow.TextStrokeColor3 = BLACK
    arrow.Visible = false
    arrow.Parent = ArrowGui

    -- distância (separada da seta para não girar junto)
    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Size = UDim2.fromOffset(60, 14)
    label.BackgroundTransparency = 1
    label.Text = ""
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = BLACK
    label.Visible = false
    label.Parent = ArrowGui

    return { arrow = arrow, label = label }
end

local ArrowMurder  = makeArrow(ROLE_COLORS.Murderer)
local ArrowSheriff = makeArrow(ROLE_COLORS.Sheriff)

local function updateArrow(pair, target, enabled)
    local arrow, label = pair.arrow, pair.label
    local cam  = Workspace.CurrentCamera
    local char = target and target.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not (enabled and cam and root) then
        arrow.Visible = false
        label.Visible = false
        return
    end

    local viewport = cam.ViewportSize
    local sp = cam:WorldToViewportPoint(root.Position)
    local onScreen = sp.Z > 0 and sp.X >= 0 and sp.X <= viewport.X and sp.Y >= 0 and sp.Y <= viewport.Y
    if onScreen then
        arrow.Visible = false
        label.Visible = false
        return
    end

    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local dir = Vector2.new(sp.X - center.X, sp.Y - center.Y)
    if sp.Z < 0 then
        dir = -dir
    end
    if dir.Magnitude < 1 then
        dir = Vector2.new(0, 1)
    end
    dir = dir.Unit

    -- Prende a seta na borda da tela (com margem)
    local margin = 55
    local mx = math.max(center.X - margin, 1)
    local my = math.max(center.Y - margin, 1)
    local s  = math.min(
        mx / math.max(math.abs(dir.X), 0.0001),
        my / math.max(math.abs(dir.Y), 0.0001)
    )
    local pos = center + dir * s

    arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
    arrow.Rotation = math.deg(math.atan2(dir.X, -dir.Y))
    arrow.Visible  = true

    local dist = (cam.CFrame.Position - root.Position).Magnitude
    label.Text     = string.format("%d", math.floor(dist))
    label.Position = UDim2.fromOffset(pos.X, pos.Y + 24)
    label.Visible  = true
end

do
    local acc   = 0
    local wasOn = false

    track(RunService.RenderStepped:Connect(function(dt)
        local on = State.ArrowMurder or State.ArrowSheriff
        if not on then
            if wasOn then
                wasOn = false
                pcall(function()
                    updateArrow(ArrowMurder,  nil, false)
                    updateArrow(ArrowSheriff, nil, false)
                end)
            end
            return
        end
        wasOn = true

        local stepT = Perf.arrowStep
        if stepT > 0 then
            acc = acc + dt
            if acc < stepT - 0.002 then return end
            acc = 0
        end

        local ok, err = pcall(function()
            updateArrow(ArrowMurder,  trackedMurderer, State.ArrowMurder)
            updateArrow(ArrowSheriff, trackedSheriff,  State.ArrowSheriff)
        end)
        if not ok then safeWarn(err, "arrows") end
    end))
end

-- ═══════════════════════════════════════════════════════════
--  14C. EMOTES: copiar a animação de outro jogador
--  - Lê as animações (idle, walk, run, jump, fall, climb) do jogador
--    escolhido e aplica em você. Não precisa de ID nem de compra.
--  - Reaplica sozinho quando você renasce. "Restore" volta ao normal.
--  Obs.: só toca se a animação for pública (pacotes oficiais do Roblox).
-- ═══════════════════════════════════════════════════════════
local copiedAnim     = nil -- ["pasta/nome"] = AnimationId
local animBackup     = nil -- [Animation] = AnimationId original
local animBackupChar = nil
local EmoteDropdown  = nil
local EmoteTarget    = nil

-- Animação salva em arquivo (continua depois de fechar o script)
local ANIM_FILE = "Buk_Animation.json"
local savedAnim = nil

local function saveAnimFile(ids)
    if not Compat.files then return false end
    return (pcall(function()
        writefile(ANIM_FILE, HttpService:JSONEncode(ids))
    end))
end

local function loadAnimFile()
    if not Compat.files then return nil end
    local ok, data = pcall(function()
        if not isfile(ANIM_FILE) then return nil end
        local t = HttpService:JSONDecode(readfile(ANIM_FILE))
        if type(t) ~= "table" then return nil end
        local ids, n = {}, 0
        for k, v in pairs(t) do
            if type(k) == "string" and type(v) == "string" then
                ids[k] = v
                n = n + 1
            end
        end
        if n > 0 then
            return ids
        end
        return nil
    end)
    if ok then
        return data
    end
    return nil
end

local function removeAnimFile()
    savedAnim = nil
    if not Compat.files then return end
    pcall(function()
        if type(delfile) == "function" then
            if isfile(ANIM_FILE) then
                delfile(ANIM_FILE)
            end
        else
            writefile(ANIM_FILE, "{}")
        end
    end)
end

savedAnim = loadAnimFile()

local function readAnimIds(char)
    local animate = char and char:FindFirstChild("Animate")
    if not animate then return nil end
    local ids, n = {}, 0
    for _, d in ipairs(animate:GetDescendants()) do
        if d:IsA("Animation") and d.AnimationId ~= "" then
            ids[d.Parent.Name .. "/" .. d.Name] = d.AnimationId
            n = n + 1
        end
    end
    if n > 0 then
        return ids
    end
    return nil
end

local function reloadAnimate(hum, animate)
    pcall(function()
        animate.Disabled = true
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                t:Stop(0)
            end
        end
        task.wait()
        animate.Disabled = false
    end)
end

local function applyAnimIds(ids)
    local char    = LocalPlayer.Character
    local hum     = char and char:FindFirstChildOfClass("Humanoid")
    local animate = char and char:FindFirstChild("Animate")
    if not (hum and animate and hum.Health > 0) then
        return false
    end

    if animBackupChar ~= char then
        animBackupChar = char
        animBackup = {}
        for _, d in ipairs(animate:GetDescendants()) do
            if d:IsA("Animation") then
                animBackup[d] = d.AnimationId
            end
        end
    end

    for _, d in ipairs(animate:GetDescendants()) do
        if d:IsA("Animation") then
            local id = ids[d.Parent.Name .. "/" .. d.Name]
            if id then
                d.AnimationId = id
            end
        end
    end

    reloadAnimate(hum, animate)
    return true
end

-- Retorna: ok (bool) e o motivo ("noplayer" | "noanim" | "dead")
local function copyAnimationFrom(name)
    if not name then
        return false, "noplayer"
    end
    local p = Players:FindFirstChild(name)
    local ids = p and readAnimIds(p.Character)
    if not ids then
        return false, "noanim"
    end
    if not applyAnimIds(ids) then
        return false, "dead"
    end
    copiedAnim = ids
    savedAnim  = ids
    if saveAnimFile(ids) then
        return true, "saved"
    end
    return true, "nosave"
end

local function restoreAnimation()
    copiedAnim = nil
    local char    = LocalPlayer.Character
    local hum     = char and char:FindFirstChildOfClass("Humanoid")
    local animate = char and char:FindFirstChild("Animate")
    if hum and animate and animBackupChar == char and animBackup then
        for d, id in pairs(animBackup) do
            if d.Parent then
                d.AnimationId = id
            end
        end
        reloadAnimate(hum, animate)
        return true
    end
    return false
end

-- Renasceu? Aplica a animação copiada de novo
track(LocalPlayer.CharacterAdded:Connect(function(char)
    if not copiedAnim then return end
    task.spawn(function()
        local animate = char:WaitForChild("Animate", 10)
        if not animate then return end
        task.wait(0.6)
        if alive and copiedAnim and LocalPlayer.Character == char then
            pcall(applyAnimIds, copiedAnim)
        end
    end)
end))

local function refreshEmoteList(leaving)
    if not EmoteDropdown then return end
    pcall(function()
        EmoteDropdown:Refresh(flingList(leaving))
    end)
end

track(Players.PlayerAdded:Connect(function()
    refreshEmoteList()
end))
track(Players.PlayerRemoving:Connect(function(p)
    refreshEmoteList(p)
end))

-- ═══════════════════════════════════════════════════════════
--  15. INTERFACE (própria, sem nenhuma biblioteca)
--  Janela preta transparente com abas na lateral, botão
--  flutuante ao minimizar e avisos no canto da tela.
-- ═══════════════════════════════════════════════════════════
local UIGui     = nil
local NotifyGui = nil
local buildUI, Unload, destroyUI

local function defineUI()
    local UIState = { Listening = false }

    local Theme = {
        Window  = Color3.fromRGB(0, 0, 0),
        Panel   = Color3.fromRGB(8, 8, 8),
        Element = Color3.fromRGB(20, 20, 22),
        Hover   = Color3.fromRGB(44, 44, 48),
        Off     = Color3.fromRGB(62, 62, 68),
        Text    = Color3.fromRGB(245, 245, 245),
        SubText = Color3.fromRGB(150, 150, 156),
        Accent  = ACCENT,
        Good    = Color3.fromRGB(74, 222, 128),
        Warn    = Color3.fromRGB(251, 176, 64),
    }
    local WINDOW_T  = 0.2   -- transparência da janela
    local PANEL_T   = 0.45  -- transparência da barra lateral
    local ELEMENT_T = 0.3   -- transparência dos botões/linhas

    destroyUI = function()
        NotifyImpl = nil
        pcall(function()
            if UIGui then UIGui:Destroy() end
        end)
        pcall(function()
            if NotifyGui then NotifyGui:Destroy() end
        end)
        UIGui, NotifyGui = nil, nil
    end

    -- ───────────── ferramentas de desenho ─────────────
    local function make(class, props, parent)
        local inst = Instance.new(class)
        for k, v in pairs(props) do
            inst[k] = v
        end
        if parent then
            inst.Parent = parent
        end
        return inst
    end

    local function round(inst, radius)
        return make("UICorner", { CornerRadius = UDim.new(0, radius) }, inst)
    end

    local function outline(inst, transparency, color, thickness)
        return make("UIStroke", {
            Color           = color or WHITE,
            Transparency    = transparency or 0.88,
            Thickness       = thickness or 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, inst)
    end

    local function pad(inst, l, t, r, b)
        return make("UIPadding", {
            PaddingLeft   = UDim.new(0, l),
            PaddingTop    = UDim.new(0, t),
            PaddingRight  = UDim.new(0, r),
            PaddingBottom = UDim.new(0, b),
        }, inst)
    end

    local function tween(inst, time, props)
        pcall(function()
            TweenService:Create(
                inst,
                TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                props
            ):Play()
        end)
    end

    local function newText(parent, props)
        local p = {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Font                   = Enum.Font.GothamMedium,
            TextSize               = 16,
            TextColor3             = Theme.Text,
            TextXAlignment         = Enum.TextXAlignment.Left,
        }
        for k, v in pairs(props) do
            p[k] = v
        end
        return make("TextLabel", p, parent)
    end

    -- chama um callback sem deixar um erro dele derrubar a interface
    local function fire(callback, ...)
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback, ...)
        if not ok then
            safeWarn(err, "ui")
        end
    end

    local function screenSize()
        if UIGui and UIGui.AbsoluteSize.X > 0 then
            return UIGui.AbsoluteSize
        end
        local cam = Workspace.CurrentCamera or Camera
        return cam.ViewportSize
    end

    local function isPress(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
    end

    -- Arrastar (mouse e toque). onTap roda se soltar sem ter arrastado.
    local function makeDraggable(handle, target, onTap)
        local dragging   = false
        local moved      = false
        local startInput = nil
        local startPos   = nil
        local startX, startY = 0, 0

        handle.InputBegan:Connect(function(input)
            if dragging or not isPress(input) then return end
            dragging   = true
            moved      = false
            startInput = input
            startPos   = input.Position
            startX     = target.Position.X.Offset
            startY     = target.Position.Y.Offset

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    conn:Disconnect()
                    dragging = false
                    if not moved and onTap then
                        fire(onTap)
                    end
                end
            end)
        end)

        track(UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input ~= startInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end
            local dx = input.Position.X - startPos.X
            local dy = input.Position.Y - startPos.Y
            if not moved and (math.abs(dx) > 6 or math.abs(dy) > 6) then
                moved = true
            end
            if moved then
                local screen = screenSize()
                local size   = target.AbsoluteSize
                target.Position = UDim2.fromOffset(
                    math.clamp(startX + dx, -size.X + 90, screen.X - 90),
                    math.clamp(startY + dy, 0, screen.Y - 40)
                )
            end
        end))
    end

    -- ───────────── avisos (notificações) ─────────────
    local function setupNotify()
        NotifyGui = newScreenGui("BukNotify", 200)

        local holder = make("Frame", {
            Name                   = "Holder",
            AnchorPoint            = Vector2.new(1, 0),
            Position               = UDim2.new(1, -16, 0, 16),
            Size                   = UDim2.new(0, 300, 1, -32),
            BackgroundTransparency = 1,
        }, NotifyGui)
        make("UIListLayout", {
            Padding             = UDim.new(0, 8),
            SortOrder           = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        }, holder)

        local order = 0
        local cards = {}

        NotifyImpl = function(text, icon, duration)
            order = order + 1

            local color = Theme.Accent
            if icon == "triangle-alert" then
                color = Theme.Warn
            elseif icon == "check" or icon == "save" then
                color = Theme.Good
            end

            local card = make("Frame", {
                Size                   = UDim2.new(0, 290, 0, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                BackgroundColor3       = Theme.Window,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = order,
            }, holder)
            round(card, 10)
            local st = outline(card, 1, color, 1)
            pad(card, 16, 10, 14, 10)
            make("UIListLayout", {
                Padding   = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, card)

            local title = newText(card, {
                Text             = "Buk",
                Font             = Enum.Font.GothamBold,
                TextSize         = 13,
                TextColor3       = color,
                TextTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 16),
                LayoutOrder      = 1,
            })
            local msg = newText(card, {
                Text             = tostring(text),
                TextSize         = 15,
                TextWrapped      = true,
                TextTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                LayoutOrder      = 2,
            })

            tween(card, 0.2, { BackgroundTransparency = 0.12 })
            tween(st, 0.2, { Transparency = 0.45 })
            tween(title, 0.2, { TextTransparency = 0 })
            tween(msg, 0.2, { TextTransparency = 0 })

            cards[#cards + 1] = card
            while #cards > 4 do
                local old = table.remove(cards, 1)
                pcall(function() old:Destroy() end)
            end

            task.delay(math.max(duration or 2.5, 1), function()
                if not card.Parent then return end
                tween(card, 0.25, { BackgroundTransparency = 1 })
                tween(st, 0.25, { Transparency = 1 })
                tween(title, 0.25, { TextTransparency = 1 })
                tween(msg, 0.25, { TextTransparency = 1 })
                task.wait(0.3)
                local i = table.find(cards, card)
                if i then table.remove(cards, i) end
                pcall(function() card:Destroy() end)
            end)
        end
    end

    -- ───────────── a janela ─────────────
    local function createWindow(cfg)
        UIGui = newScreenGui("BukUI", 50)

        local vp     = screenSize()
        local width  = math.clamp(math.floor(vp.X * 0.62), 460, 760)
        local height = math.clamp(math.floor(vp.Y * 0.78), 300, 500)
        width  = math.min(width,  vp.X - 16)
        height = math.min(height, vp.Y - 16)

        local sideW = (width >= 600) and 168 or 138
        local TOP_H = 52

        local window = make("Frame", {
            Name                   = "Window",
            Position               = UDim2.fromOffset(
                math.floor((vp.X - width) / 2),
                math.floor((vp.Y - height) / 2)
            ),
            Size                   = UDim2.fromOffset(width, height),
            BackgroundColor3       = Theme.Window,
            BackgroundTransparency = WINDOW_T,
            BorderSizePixel        = 0,
            Active                 = true,
        }, UIGui)
        round(window, 14)
        outline(window, 0.82)

        -- ícone flutuante (aparece quando o menu está minimizado)
        local icon = make("TextButton", {
            Name                   = "Icon",
            Position               = UDim2.fromOffset(20, math.floor(vp.Y * 0.3)),
            Size                   = UDim2.fromOffset(60, 60),
            BackgroundColor3       = Theme.Window,
            BackgroundTransparency = 0.15,
            AutoButtonColor        = false,
            Text                   = "Buk",
            Font                   = Enum.Font.GothamBold,
            TextSize               = 18,
            TextColor3             = Theme.Text,
            Visible                = false,
        }, UIGui)
        round(icon, 30)
        outline(icon, 0.1, Theme.Accent, 2)

        local function setOpen(open)
            window.Visible = open
            icon.Visible   = not open
        end

        makeDraggable(icon, icon, function()
            setOpen(true)
        end)

        -- barra de cima
        local top = make("Frame", {
            Name                   = "Top",
            Size                   = UDim2.new(1, 0, 0, TOP_H),
            BackgroundTransparency = 1,
            Active                 = true,
        }, window)
        makeDraggable(top, window)

        newText(top, {
            Text     = cfg.Title,
            Font     = Enum.Font.GothamBold,
            TextSize = 22,
            Position = UDim2.fromOffset(18, 6),
            Size     = UDim2.new(0.5, 0, 0, 26),
        })
        newText(top, {
            Text       = cfg.Author,
            TextSize   = 13,
            TextColor3 = Theme.SubText,
            Position   = UDim2.fromOffset(18, 31),
            Size       = UDim2.new(0.5, 0, 0, 16),
        })

        make("Frame", {
            Position               = UDim2.fromOffset(0, TOP_H),
            Size                   = UDim2.new(1, 0, 0, 1),
            BackgroundColor3       = WHITE,
            BackgroundTransparency = 0.9,
            BorderSizePixel        = 0,
        }, window)

        local function topButton(text, xOffset)
            local b = make("TextButton", {
                Position               = UDim2.new(1, xOffset, 0, 7),
                Size                   = UDim2.fromOffset(38, 38),
                BackgroundColor3       = Theme.Element,
                BackgroundTransparency = ELEMENT_T,
                AutoButtonColor        = false,
                Text                   = text,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 20,
                TextColor3             = Theme.Text,
            }, top)
            round(b, 10)
            return b
        end

        local minBtn   = topButton("-", -92)
        local closeBtn = topButton("X", -48)

        minBtn.Activated:Connect(function()
            setOpen(false)
        end)

        -- fechar precisa de dois toques (evita descarregar sem querer no celular)
        local closeArmed = false
        closeBtn.Activated:Connect(function()
            if closeArmed then
                if Unload then Unload() end
                return
            end
            closeArmed = true
            closeBtn.BackgroundColor3 = Theme.Accent
            closeBtn.BackgroundTransparency = 0.1
            notify(L("close_confirm"), "triangle-alert", 2.5)
            task.delay(2.5, function()
                closeArmed = false
                if closeBtn.Parent then
                    closeBtn.BackgroundColor3 = Theme.Element
                    closeBtn.BackgroundTransparency = ELEMENT_T
                end
            end)
        end)

        -- corpo: barra lateral + conteúdo
        local body = make("Frame", {
            Name                   = "Body",
            Position               = UDim2.fromOffset(0, TOP_H + 1),
            Size                   = UDim2.new(1, 0, 1, -(TOP_H + 1)),
            BackgroundTransparency = 1,
        }, window)

        local side = make("ScrollingFrame", {
            Name                   = "Side",
            Position               = UDim2.fromOffset(8, 8),
            Size                   = UDim2.new(0, sideW, 1, -16),
            BackgroundColor3       = Theme.Panel,
            BackgroundTransparency = PANEL_T,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 0,
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            ScrollingDirection     = Enum.ScrollingDirection.Y,
        }, body)
        round(side, 10)
        make("UIListLayout", {
            Padding   = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, side)
        pad(side, 8, 8, 8, 8)

        local content = make("Frame", {
            Name                   = "Content",
            Position               = UDim2.fromOffset(sideW + 16, 8),
            Size                   = UDim2.new(1, -(sideW + 24), 1, -16),
            BackgroundTransparency = 1,
            ClipsDescendants       = true,
        }, body)

        local tabs = {}

        local function selectTab(chosen)
            for _, t in ipairs(tabs) do
                local on = (t == chosen)
                t.page.Visible = on
                t.btn.BackgroundTransparency = on and 0.15 or 1
                t.btn.TextColor3 = on and Theme.Text or Theme.SubText
            end
        end

        local Win = {}

        function Win.Tab(name)
            local btn = make("TextButton", {
                Name                   = name,
                Size                   = UDim2.new(1, 0, 0, 44),
                BackgroundColor3       = Theme.Accent,
                BackgroundTransparency = 1,
                AutoButtonColor        = false,
                Text                   = name,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 15,
                TextColor3             = Theme.SubText,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                LayoutOrder            = #tabs + 1,
            }, side)
            round(btn, 8)
            pad(btn, 14, 0, 6, 0)

            local page = make("ScrollingFrame", {
                Name                   = name,
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                ScrollBarThickness     = 4,
                ScrollBarImageColor3   = WHITE,
                ScrollBarImageTransparency = 0.6,
                CanvasSize             = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize    = Enum.AutomaticSize.Y,
                ScrollingDirection     = Enum.ScrollingDirection.Y,
                Visible                = false,
            }, content)
            make("UIListLayout", {
                Padding   = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, page)
            pad(page, 4, 2, 10, 14)

            local tabObj = { btn = btn, page = page }
            tabs[#tabs + 1] = tabObj

            btn.Activated:Connect(function()
                selectTab(tabObj)
            end)
            if #tabs == 1 then
                selectTab(tabObj)
            end

            local order = 0

            local function row(h)
                order = order + 1
                local f = make("Frame", {
                    Size                   = UDim2.new(1, 0, 0, h),
                    BackgroundColor3       = Theme.Element,
                    BackgroundTransparency = ELEMENT_T,
                    BorderSizePixel        = 0,
                    LayoutOrder            = order,
                }, page)
                round(f, 10)
                outline(f, 0.9)
                return f
            end

            local Tab = {}

            function Tab.Section(title)
                order = order + 1
                local s = newText(page, {
                    Text           = string.upper(title),
                    Font           = Enum.Font.GothamBold,
                    TextSize       = 13,
                    TextColor3     = Theme.SubText,
                    Size           = UDim2.new(1, 0, 0, 30),
                    TextYAlignment = Enum.TextYAlignment.Bottom,
                    LayoutOrder    = order,
                })
                pad(s, 6, 0, 0, 4)
            end

            function Tab.Label(text)
                order = order + 1
                local l = newText(page, {
                    Text           = text,
                    TextSize       = 15,
                    TextColor3     = Theme.SubText,
                    TextWrapped    = true,
                    Size           = UDim2.new(1, 0, 0, 0),
                    AutomaticSize  = Enum.AutomaticSize.Y,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    LayoutOrder    = order,
                })
                pad(l, 6, 2, 6, 2)
            end

            function Tab.Toggle(title, value, callback)
                local state = value and true or false
                local f = row(52)

                newText(f, {
                    Text     = title,
                    Position = UDim2.fromOffset(16, 0),
                    Size     = UDim2.new(1, -90, 1, 0),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })

                local trackBar = make("Frame", {
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, -16, 0.5, 0),
                    Size             = UDim2.fromOffset(48, 26),
                    BackgroundColor3 = Theme.Off,
                    BorderSizePixel  = 0,
                }, f)
                round(trackBar, 13)
                local knob = make("Frame", {
                    AnchorPoint      = Vector2.new(0, 0.5),
                    Position         = UDim2.new(0, 3, 0.5, 0),
                    Size             = UDim2.fromOffset(20, 20),
                    BackgroundColor3 = WHITE,
                    BorderSizePixel  = 0,
                }, trackBar)
                round(knob, 10)

                local function paint(animate)
                    local color = state and Theme.Accent or Theme.Off
                    local pos   = state and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                    if animate then
                        tween(trackBar, 0.15, { BackgroundColor3 = color })
                        tween(knob, 0.15, { Position = pos })
                    else
                        trackBar.BackgroundColor3 = color
                        knob.Position = pos
                    end
                end
                paint(false)

                local hit = make("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    AutoButtonColor        = false,
                    Text                   = "",
                }, f)
                hit.Activated:Connect(function()
                    state = not state
                    paint(true)
                    fire(callback, state)
                end)

                local obj = {}
                -- muda só o visual (não chama o callback)
                function obj:Set(v)
                    state = v and true or false
                    paint(true)
                end
                return obj
            end

            function Tab.Slider(title, min, max, value, callback)
                local f = row(70)
                local current = min

                newText(f, {
                    Text     = title,
                    Position = UDim2.fromOffset(16, 8),
                    Size     = UDim2.new(1, -110, 0, 22),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                local valLbl = newText(f, {
                    Position       = UDim2.new(1, -86, 0, 8),
                    Size           = UDim2.fromOffset(70, 22),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextColor3     = Theme.SubText,
                })

                local hit = make("TextButton", {
                    Position               = UDim2.new(0, 16, 0, 36),
                    Size                   = UDim2.new(1, -32, 0, 28),
                    BackgroundTransparency = 1,
                    AutoButtonColor        = false,
                    Text                   = "",
                }, f)
                local bar = make("Frame", {
                    AnchorPoint      = Vector2.new(0, 0.5),
                    Position         = UDim2.new(0, 0, 0.5, 0),
                    Size             = UDim2.new(1, 0, 0, 8),
                    BackgroundColor3 = Theme.Off,
                    BorderSizePixel  = 0,
                }, hit)
                round(bar, 4)
                local fill = make("Frame", {
                    Size             = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel  = 0,
                }, bar)
                round(fill, 4)
                local knob = make("Frame", {
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = UDim2.new(0, 0, 0.5, 0),
                    Size             = UDim2.fromOffset(22, 22),
                    BackgroundColor3 = WHITE,
                    BorderSizePixel  = 0,
                }, bar)
                round(knob, 11)

                local function apply(v, notifyChange)
                    v = math.clamp(math.floor((tonumber(v) or min) + 0.5), min, max)
                    current = v
                    local alpha = (max > min) and ((v - min) / (max - min)) or 0
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                    valLbl.Text = tostring(v)
                    if notifyChange then
                        fire(callback, v)
                    end
                end
                apply(value or min, false)

                local function fromX(x)
                    local w = math.max(hit.AbsoluteSize.X, 1)
                    local a = math.clamp((x - hit.AbsolutePosition.X) / w, 0, 1)
                    local v = math.floor(min + a * (max - min) + 0.5)
                    if v ~= current then
                        apply(v, true)
                    end
                end

                local dragging   = false
                local startInput = nil

                hit.InputBegan:Connect(function(input)
                    if dragging or not isPress(input) then return end
                    dragging   = true
                    startInput = input
                    page.ScrollingEnabled = false -- não rola a página enquanto arrasta o slider
                    fromX(input.Position.X)

                    local conn
                    conn = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            conn:Disconnect()
                            dragging = false
                            page.ScrollingEnabled = true
                        end
                    end)
                end)

                track(UserInputService.InputChanged:Connect(function(input)
                    if not dragging then return end
                    if input == startInput or input.UserInputType == Enum.UserInputType.MouseMovement then
                        fromX(input.Position.X)
                    end
                end))

                local obj = {}
                function obj:Set(v)
                    apply(v, false)
                end
                return obj
            end

            -- Dropdown: multi = false -> selected é um texto, callback(texto)
            --           multi = true  -> selected é { [texto] = true }, callback({ [texto] = true })
            function Tab.Dropdown(title, values, selected, multi, callback)
                local list    = values or {}
                local chosen  = {}
                local single  = nil
                local open    = false
                local options = {}

                if multi then
                    for k, v in pairs(selected or {}) do
                        if v then chosen[k] = true end
                    end
                elseif type(selected) == "string" then
                    single = selected
                end

                order = order + 1
                local box = make("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 0),
                    AutomaticSize          = Enum.AutomaticSize.Y,
                    BackgroundColor3       = Theme.Element,
                    BackgroundTransparency = ELEMENT_T,
                    BorderSizePixel        = 0,
                    LayoutOrder            = order,
                }, page)
                round(box, 10)
                outline(box, 0.9)
                make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, box)

                local head = make("TextButton", {
                    Size                   = UDim2.new(1, 0, 0, 52),
                    BackgroundTransparency = 1,
                    AutoButtonColor        = false,
                    Text                   = "",
                    LayoutOrder            = 1,
                }, box)
                newText(head, {
                    Text     = title,
                    Position = UDim2.fromOffset(16, 0),
                    Size     = UDim2.new(0.5, -16, 1, 0),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                local sumLbl = newText(head, {
                    Position       = UDim2.new(0.5, 0, 0, 0),
                    Size           = UDim2.new(0.5, -48, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextColor3     = Theme.SubText,
                    TextTruncate   = Enum.TextTruncate.AtEnd,
                })
                local arrow = newText(head, {
                    Text           = "+",
                    Font           = Enum.Font.GothamBold,
                    Position       = UDim2.new(1, -36, 0, 0),
                    Size           = UDim2.fromOffset(24, 52),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextColor3     = Theme.SubText,
                })

                local optFrame = make("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 0),
                    AutomaticSize          = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Visible                = false,
                    LayoutOrder            = 2,
                }, box)
                make("UIListLayout", {
                    Padding   = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, optFrame)
                pad(optFrame, 8, 0, 8, 8)

                local function summary()
                    if multi then
                        local n = 0
                        for _, name in ipairs(list) do
                            if chosen[name] then n = n + 1 end
                        end
                        if n == 0 then return L("none") end
                        return L("selected_n", n)
                    end
                    if single and table.find(list, single) then
                        return single
                    end
                    return L("select")
                end

                local function paint()
                    for _, o in ipairs(options) do
                        local on
                        if multi then
                            on = chosen[o.name] == true
                        else
                            on = (single == o.name)
                        end
                        o.mark.BackgroundColor3 = on and Theme.Accent or Theme.Off
                        o.btn.BackgroundTransparency = on and 0.4 or 0.75
                    end
                    sumLbl.Text = summary()
                end

                local function setOpen(v)
                    open = v
                    optFrame.Visible = v
                    arrow.Text = v and "-" or "+"
                end

                local function build()
                    for _, o in ipairs(options) do
                        pcall(function() o.btn:Destroy() end)
                    end
                    options = {}

                    for i, name in ipairs(list) do
                        local ob = make("TextButton", {
                            Size                   = UDim2.new(1, 0, 0, 42),
                            BackgroundColor3       = Theme.Hover,
                            BackgroundTransparency = 0.75,
                            AutoButtonColor        = false,
                            Text                   = "",
                            LayoutOrder            = i,
                        }, optFrame)
                        round(ob, 8)
                        newText(ob, {
                            Text         = name,
                            TextSize     = 15,
                            Position     = UDim2.fromOffset(14, 0),
                            Size         = UDim2.new(1, -52, 1, 0),
                            TextTruncate = Enum.TextTruncate.AtEnd,
                        })
                        local mark = make("Frame", {
                            AnchorPoint      = Vector2.new(1, 0.5),
                            Position         = UDim2.new(1, -14, 0.5, 0),
                            Size             = UDim2.fromOffset(18, 18),
                            BackgroundColor3 = Theme.Off,
                            BorderSizePixel  = 0,
                        }, ob)
                        round(mark, 5)

                        ob.Activated:Connect(function()
                            if multi then
                                if chosen[name] then
                                    chosen[name] = nil
                                else
                                    chosen[name] = true
                                end
                                paint()
                                local copy = {}
                                for k, v in pairs(chosen) do copy[k] = v end
                                fire(callback, copy)
                            else
                                single = name
                                paint()
                                setOpen(false)
                                fire(callback, name)
                            end
                        end)

                        options[#options + 1] = { name = name, btn = ob, mark = mark }
                    end
                    paint()
                end

                head.Activated:Connect(function()
                    setOpen(not open)
                end)

                build()

                local obj = {}
                function obj:Refresh(newValues)
                    list = newValues or {}
                    build()
                end
                return obj
            end

            function Tab.Keybind(title, key, callback)
                local f = row(52)
                local listening = false

                newText(f, {
                    Text     = title,
                    Position = UDim2.fromOffset(16, 0),
                    Size     = UDim2.new(1, -170, 1, 0),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                local btnKey = make("TextButton", {
                    AnchorPoint            = Vector2.new(1, 0.5),
                    Position               = UDim2.new(1, -12, 0.5, 0),
                    Size                   = UDim2.fromOffset(136, 36),
                    BackgroundColor3       = Theme.Hover,
                    BackgroundTransparency = 0.3,
                    AutoButtonColor        = false,
                    Text                   = key.Name,
                    Font                   = Enum.Font.GothamMedium,
                    TextSize               = 15,
                    TextColor3             = Theme.Text,
                }, f)
                round(btnKey, 8)

                btnKey.Activated:Connect(function()
                    if listening then return end
                    listening = true
                    UIState.Listening = true
                    btnKey.Text = L("press_key")
                end)

                track(UserInputService.InputBegan:Connect(function(input)
                    if not listening then return end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    listening = false
                    task.defer(function()
                        UIState.Listening = false
                    end)
                    if input.KeyCode == Enum.KeyCode.Escape then
                        btnKey.Text = key.Name
                        return
                    end
                    key = input.KeyCode
                    btnKey.Text = key.Name
                    fire(callback, key)
                end))
            end

            function Tab.Button(title, callback)
                order = order + 1
                local b = make("TextButton", {
                    Size                   = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3       = Theme.Element,
                    BackgroundTransparency = ELEMENT_T,
                    AutoButtonColor        = false,
                    Text                   = title,
                    Font                   = Enum.Font.GothamMedium,
                    TextSize               = 16,
                    TextColor3             = Theme.Text,
                    LayoutOrder            = order,
                }, page)
                round(b, 10)
                outline(b, 0.8)
                b.Activated:Connect(function()
                    b.BackgroundColor3 = Theme.Accent
                    b.BackgroundTransparency = 0.2
                    tween(b, 0.3, { BackgroundColor3 = Theme.Element, BackgroundTransparency = ELEMENT_T })
                    fire(callback)
                end)
            end

            return Tab
        end

        -- tecla do menu: abre/fecha
        track(UserInputService.InputBegan:Connect(function(input, processed)
            if processed or UIState.Listening then return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == State.MenuKey then
                setOpen(not window.Visible)
            end
        end))

        function Win.SetOpen(v)
            setOpen(v)
        end

        return Win
    end

    local function addToggle(tab, title, key, onChange)
        return tab.Toggle(title, State[key], function(v)
            State[key] = v and true or false
            if onChange then onChange(v) end
        end)
    end

    local function addSlider(tab, title, key, min, max)
        return tab.Slider(title, min, max, math.clamp(State[key], min, max), function(v)
            State[key] = tonumber(v) or State[key]
        end)
    end

    buildUI = function()
        destroyUI()
        setupNotify()

        local Window = createWindow({
            Title  = "Buk",
            Author = "by Linesketon02",
        })

        local MainTab     = Window.Tab(L("tab_main"))
        local PlayerTab   = Window.Tab(L("tab_player"))
        local VisualsTab  = Window.Tab(L("tab_visuals"))
        local PickTab     = Window.Tab(L("tab_pick"))
        local FarmTab     = Window.Tab(L("tab_farm"))
        local SheriffTab  = Window.Tab(L("tab_sheriff"))
        local TrollTab    = Window.Tab(L("tab_troll"))
        local EmotesTab   = Window.Tab(L("tab_emotes"))
        local SettingsTab = Window.Tab(L("tab_settings"))

        -- ───────────── MAIN ─────────────
        MainTab.Section(L("sec_info"))
        MainTab.Label(L("info_author"))
        MainTab.Label(L("info_menu"))

        -- ───────────── PLAYER ─────────────
        PlayerTab.Section(L("sec_move"))
        addToggle(PlayerTab, L("cframe"), "CFrameOn")
        addSlider(PlayerTab, L("cframe_speed"), "CFrameSpeed", 5, 100)
        addToggle(PlayerTab, L("inf_jump"), "InfJump")
        addToggle(PlayerTab, L("noclip"), "Noclip")

        PlayerTab.Section(L("sec_protect"))
        addToggle(PlayerTab, L("anti_fling"), "AntiFling", function(v)
            if not v then
                restoreBackup(antiBackup)
            end
        end)

        -- ───────────── VISUALS ─────────────
        VisualsTab.Section(L("sec_name"))
        addToggle(VisualsTab, L("esp_name"), "EspName")

        VisualsTab.Section(L("sec_roles"))
        addToggle(VisualsTab, L("role_inn"),  "RoleInnocent")
        addToggle(VisualsTab, L("role_sher"), "RoleSheriff")
        addToggle(VisualsTab, L("role_murd"), "RoleMurderer")

        -- Itens e Setas: um único menu com as 3 opções (marque quantas quiser)
        VisualsTab.Section(L("sec_items"))

        local ITEM_OPTIONS = {
            { label = L("gun_drop"),      key = "GunDrop"      },
            { label = L("arrow_murder"),  key = "ArrowMurder"  },
            { label = L("arrow_sheriff"), key = "ArrowSheriff" },
        }
        local itemValues   = {}
        local itemSelected = {}
        for _, it in ipairs(ITEM_OPTIONS) do
            itemValues[#itemValues + 1] = it.label
            if State[it.key] then
                itemSelected[it.label] = true
            end
        end

        VisualsTab.Dropdown(L("items_dd"), itemValues, itemSelected, true, function(chosen)
            for _, it in ipairs(ITEM_OPTIONS) do
                State[it.key] = chosen[it.label] == true
            end
        end)

        -- ───────────── WEAPON ─────────────
        PickTab.Section(L("sec_pick"))
        addToggle(PickTab, L("pick_auto"), "PickAuto")
        addToggle(PickTab, L("pick_screen"), "PickButton", setPickButtonVisible)

        PickTab.Section(L("sec_pick_pc"))
        addToggle(PickTab, L("pick_key_on"), "PickKeyOn")
        PickTab.Keybind(L("pick_key"), State.PickKey, function(keyCode)
            State.PickKey = keyCode
        end)

        -- ───────────── AUTO FARM ─────────────
        -- (o Auto Farm nunca liga sozinho na próxima execução)
        FarmTab.Section(L("sec_farm"))
        addToggle(FarmTab, L("farm_on"), "FarmOn")
        addSlider(FarmTab, L("farm_limit"), "FarmLimit", 10, 60)
        addToggle(FarmTab, L("farm_safe"), "FarmSafe")
        addToggle(FarmTab, L("farm_reset"), "FarmReset")

        -- ───────────── SHERIFF ─────────────
        SheriffTab.Section(L("sec_magic"))
        addToggle(SheriffTab, L("magic"), "MagicBullet", function(v)
            if v then
                if not installAimHook() then
                    notify(L("no_hook"), "triangle-alert", 4)
                end
            else
                magicAim = nil
            end
        end)
        SheriffTab.Dropdown(
            L("magic_part"),
            { L("part_torso"), L("part_head") },
            (State.AimPart == "Head") and L("part_head") or L("part_torso"),
            false,
            function(option)
                if option == L("part_head") then
                    State.AimPart = "Head"
                elseif option == L("part_torso") then
                    State.AimPart = "Torso"
                end
            end
        )
        addToggle(SheriffTab, L("magic_predict"), "AimPredict")

        SheriffTab.Section(L("sec_wall"))
        addToggle(SheriffTab, L("wall_shot"), "WallShot", function(v)
            if v then
                if not installAimHook() then
                    notify(L("no_hook"), "triangle-alert", 4)
                end
            else
                Aim.clearTags()
            end
        end)

        SheriffTab.Section(L("sec_autopick"))
        addToggle(SheriffTab, L("autopick_gun"), "AutoPickGun")

        -- ───────────── TROLL ─────────────
        -- 1) Fling (liga/desliga)   2) Escolher o player   3) Velocidade sempre no máximo
        TrollTab.Section(L("sec_fling"))

        FlingToggle = addToggle(TrollTab, L("fling"), "Fling", function(v)
            if v then
                local ok, reason = startFling()
                if not ok then
                    State.Fling = false
                    local key = (reason == "dead" and "fling_dead")
                        or (reason == "tdead" and "fling_tdead")
                        or (reason == "norole" and "fling_norole")
                        or "fling_notarget"
                    notify(L(key), "triangle-alert", 3)
                    task.defer(function()
                        if FlingToggle then
                            FlingToggle:Set(false)
                        end
                    end)
                end
            else
                stopFling()
            end
        end)

        local flingNames = flingValues()
        FlingDropdown = TrollTab.Dropdown(
            L("fling_player"),
            flingNames,
            (State.FlingTarget and table.find(flingNames, State.FlingTarget)) and State.FlingTarget or nil,
            false,
            function(option)
                if type(option) == "string" then
                    State.FlingTarget = option
                end
            end
        )

        -- ───────────── EMOTES ─────────────
        EmotesTab.Section(L("sec_copy"))

        local emoteNames = flingList()
        EmoteDropdown = EmotesTab.Dropdown(
            L("copy_player"),
            emoteNames,
            (EmoteTarget and table.find(emoteNames, EmoteTarget)) and EmoteTarget or nil,
            false,
            function(option)
                if type(option) == "string" then
                    EmoteTarget = option
                end
            end
        )

        EmotesTab.Button(L("copy_refresh"), function()
            refreshEmoteList()
        end)
        EmotesTab.Button(L("copy_btn"), function()
            local ok, reason = copyAnimationFrom(EmoteTarget)
            if ok then
                notify(L(reason == "saved" and "copy_saved" or "copy_ok"), "check", 2.5)
            else
                local key = (reason == "dead" and "copy_dead")
                    or (reason == "noanim" and "copy_noanim")
                    or "copy_noplayer"
                notify(L(key), "triangle-alert", 3)
            end
        end)
        EmotesTab.Button(L("copy_restore"), function()
            if restoreAnimation() then
                notify(L("copy_restored"), "check", 2.5)
            end
        end)

        EmotesTab.Section(L("sec_saved"))
        EmotesTab.Button(L("saved_use"), function()
            if not savedAnim then
                notify(L("saved_none"), "triangle-alert", 3)
            elseif applyAnimIds(savedAnim) then
                copiedAnim = savedAnim
                notify(L("saved_used"), "check", 2.5)
            else
                notify(L("copy_dead"), "triangle-alert", 3)
            end
        end)
        EmotesTab.Button(L("saved_remove"), function()
            removeAnimFile()
            notify(L("saved_removed"), "check", 2.5)
        end)

        -- ───────────── SETTINGS ─────────────
        SettingsTab.Section(L("sec_menu"))
        SettingsTab.Keybind(L("menu_key"), State.MenuKey, function(keyCode)
            State.MenuKey = keyCode
        end)
        SettingsTab.Button(L("save_btn"), function()
            if not Compat.files then
                notify(L("no_files"), "triangle-alert", 3)
                return
            end
            if saveConfig() then
                notify(L("saved_text"), "save", 2.5)
            else
                notify(L("save_fail_text"), "triangle-alert", 3)
            end
        end)
        SettingsTab.Button(L("unload_btn"), function()
            Unload()
        end)
    end
end

defineUI()

-- ═══════════════════════════════════════════════════════════
--  16. FINALIZAÇÃO
-- ═══════════════════════════════════════════════════════════
Unload = function()
    if not alive then return end
    alive = false
    farmMoving = false
    magicAim   = nil
    forcedAim  = nil
    Aim.active = false
    pcall(Aim.clearTags) -- devolve as peças que viraram "atravessáveis"
    State.Fling = false -- o loop do Fling percebe, volta pra origem e termina

    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end

    -- devolve a colisão original (Noclip e Anti-Fling)
    pcall(function() restoreBackup(noclipBackup) end)
    pcall(function() restoreBackup(antiBackup) end)

    for player in pairs(roleHighlights) do
        removePlayer(player)
    end

    task.spawn(function() pcall(restoreAnimation) end)
    pcall(function() ArrowGui:Destroy() end)
    pcall(function() PickGui:Destroy() end)
    pcall(function() HighlightFolder:Destroy() end)
    pcall(destroyUI)

    genv.BukUnload = nil
end

genv.BukUnload = function()
    Unload()
    pcall(destroyUI)
end

-- Abre o menu (se der erro, mostra o motivo na tela)
local okBuild, errBuild = xpcall(function()
    buildUI()
end, function(e)
    return debug.traceback(tostring(e), 2)
end)

if okBuild then
    -- aplica as opções carregadas do arquivo que têm efeito imediato
    setPickButtonVisible(State.PickButton)
    if State.MagicBullet or State.WallShot then
        pcall(installAimHook)
    end
    notify(L("loaded"), "check", 4)
else
    showError(errBuild)
end
