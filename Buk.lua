--[[
    ╔══════════════════════════════════════╗
    ║  Buk                                 ║
    ║  Developed by: Linesketon02          ║
    ║  UI: Luna Interface Suite            ║
    ╚══════════════════════════════════════╝

    Abas: Main | Player | ESP | Weapon | Auto Farm | Aimbot MM2 | Troll | Copy Animation | Settings
    Tecla para abrir/fechar: RightShift (muda em Settings > Menu Key)
    Celular: botão flutuante "BUK" abre/fecha o menu (arraste para mudar de lugar)
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
        info_menu = "Tap the BUK floating button to hide or show the menu (drag it to move). The X button hides the menu too. On PC you can also use the Menu Key (Settings > Menu Key).",
        float_lock = "Lock BUK Button Position",
        close_confirm = "Tap again to unload the script.",
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
    MenuKey    = Enum.KeyCode.RightShift,
    BukBtnX    = 0.93,  -- posição do botão flutuante BUK (fração da largura da tela)
    BukBtnY    = 0.30,  -- posição do botão flutuante BUK (fração da altura da tela)
    BukBtnLock = false, -- trava o botão BUK (não deixa arrastar)
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
    "BukBtnX", "BukBtnY", "BukBtnLock",
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
--  15. INTERFACE (Luna Interface Suite)
--  Biblioteca Luna: funciona em PC e celular.
--  Fechar a janela (X) no celular deixa um botão flutuante para abrir
--  de novo; no PC use a tecla do menu (Settings > Menu Key).
-- ═══════════════════════════════════════════════════════════
local LUNA_URL = "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua"
local LunaLib  = nil
local buildUI, Unload, destroyUI

-- ícones dos avisos (Material, os nomes que a Luna conhece)
local NOTIFY_ICONS = {
    ["check"]          = "check_circle",
    ["triangle-alert"] = "report_problem",
    ["save"]           = "save",
}


-- ───────────── OCULTAR/MOSTRAR A INTERFACE + BOTÃO FLUTUANTE "BUK" ─────────────
-- A Luna, quando oculta a janela, deixa peças soltas na tela (barra de arrastar,
-- sombra, blur) que continuam pegando toque: era o "negócio invisível".
-- Aqui o script esconde TUDO da Luna por conta própria (menos os avisos) e o
-- botão BUK abre/fecha o menu. O X da janela e a tecla do menu usam o mesmo caminho.
local INERT_KEY = Enum.KeyCode.World95 -- tecla que ninguém aperta (desliga o atalho interno da Luna)
local BUK_W, BUK_H = 64, 38
local BUK_DRAG_MIN = 10

local LunaGui    = nil  -- ScreenGui da Luna
local BukGui     = nil  -- ScreenGui do botão BUK
local BukBtn     = nil
local BukStroke  = nil
local menuOpen   = true
local hiddenGui  = {}   -- [peça da Luna] = Visible de antes de ocultar
local hiddenBlur = {}   -- pastas "LunaBlur" da câmera retiradas enquanto o menu está oculto
local menuConns  = {}

local function findLunaGui()
    local roots = {}
    if gethui then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then
            roots[#roots + 1] = h
        end
    end
    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and core then
        roots[#roots + 1] = core
        local rg = core:FindFirstChild("RobloxGui")
        if rg then
            roots[#roots + 1] = rg
        end
    end
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then
        roots[#roots + 1] = pg
    end

    local fallback = nil
    for _, root in ipairs(roots) do
        local okList, kids = pcall(function()
            return root:GetChildren()
        end)
        if okList then
            for _, g in ipairs(kids) do
                if g:IsA("ScreenGui") and g.Name ~= "Luna-Old" and g:FindFirstChild("SmartWindow") then
                    local okT, title = pcall(function()
                        return g.SmartWindow.Title.Title.Text
                    end)
                    if okT and title == "Buk" then
                        return g
                    end
                    fallback = fallback or g
                end
            end
        end
    end
    return fallback
end

local function setLunaShown(show)
    local gui = LunaGui
    if not gui or not gui.Parent then return end

    if show then
        for obj, was in pairs(hiddenGui) do
            if obj.Parent then
                pcall(function()
                    obj.Visible = was
                end)
            end
        end
        table.clear(hiddenGui)

        local cam = Workspace.CurrentCamera
        for folder in pairs(hiddenBlur) do
            if cam then
                pcall(function()
                    folder.Parent = cam
                end)
            end
        end
        table.clear(hiddenBlur)
    else
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "Notifications" and hiddenGui[child] == nil then
                hiddenGui[child] = child.Visible
                child.Visible = false
            end
        end

        -- vidro/blur que a Luna desenha na câmera
        local cam = Workspace.CurrentCamera
        if cam then
            for _, f in ipairs(cam:GetChildren()) do
                if f.Name == "LunaBlur" then
                    hiddenBlur[f] = true
                    pcall(function()
                        f.Parent = nil
                    end)
                end
            end
        end
    end
end

local function refreshBukButton()
    if not BukBtn then return end
    pcall(function()
        BukStroke.Color = menuOpen and ACCENT or NAME_NEUTRAL
        BukBtn.TextColor3 = menuOpen and WHITE or Color3.fromRGB(200, 205, 225)
    end)
end

local function setMenuOpen(open)
    menuOpen = open and true or false
    setLunaShown(menuOpen)
    refreshBukButton()
end

local function buildBukButton()
    local cam = Workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)

    BukGui = newScreenGui("BukFloatGui", 2000000000)

    BukBtn = Instance.new("TextButton")
    BukBtn.Name = "BukFloatButton"
    BukBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    BukBtn.Position = UDim2.fromOffset(
        math.clamp(State.BukBtnX * vp.X, BUK_W / 2, vp.X - BUK_W / 2),
        math.clamp(State.BukBtnY * vp.Y, BUK_H / 2, vp.Y - BUK_H / 2)
    )
    BukBtn.Size = UDim2.fromOffset(BUK_W, BUK_H)
    BukBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    BukBtn.BackgroundTransparency = 0.1
    BukBtn.AutoButtonColor = false
    BukBtn.Font = Enum.Font.GothamBold
    BukBtn.TextSize = 16
    BukBtn.TextColor3 = WHITE
    BukBtn.Text = "BUK"
    BukBtn.Parent = BukGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = BukBtn

    BukStroke = Instance.new("UIStroke")
    BukStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BukStroke.Color = ACCENT
    BukStroke.Thickness = 2
    BukStroke.Transparency = 0.1
    BukStroke.Parent = BukBtn

    -- Arrastar move o botão (sem sair da tela); tocar sem arrastar abre/fecha o menu
    local dragging, moved = false, false
    local dragInput, dragStart, startCenter = nil, nil, nil

    menuConns[#menuConns + 1] = BukBtn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging    = true
        moved       = false
        dragInput   = input
        dragStart   = input.Position
        startCenter = Vector2.new(BukBtn.Position.X.Offset, BukBtn.Position.Y.Offset)

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            conn:Disconnect()
            dragging = false

            if moved then
                local c2 = Workspace.CurrentCamera
                local v2 = c2 and c2.ViewportSize or Vector2.new(1280, 720)
                State.BukBtnX = BukBtn.Position.X.Offset / math.max(v2.X, 1)
                State.BukBtnY = BukBtn.Position.Y.Offset / math.max(v2.Y, 1)
            else
                setMenuOpen(not menuOpen)
            end
        end)
    end)

    menuConns[#menuConns + 1] = UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragInput or State.BukBtnLock then return end

        if dragInput.UserInputType == Enum.UserInputType.Touch then
            if input ~= dragInput then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - dragStart
        if delta.Magnitude > BUK_DRAG_MIN then
            moved = true
        end
        if moved then
            local c2   = Workspace.CurrentCamera
            local v2   = c2 and c2.ViewportSize or Vector2.new(1280, 720)
            local half = Vector2.new(BUK_W, BUK_H) / 2
            local nx = math.clamp(startCenter.X + delta.X, half.X, v2.X - half.X)
            local ny = math.clamp(startCenter.Y + delta.Y, half.Y, v2.Y - half.Y)
            BukBtn.Position = UDim2.fromOffset(nx, ny)
        end
    end)

    refreshBukButton()
end

local function hookLunaControls()
    local gui = LunaGui
    if not gui then return end

    -- X da janela: usa o ocultar do script (o da Luna deixa peças soltas na tela)
    pcall(function()
        local close = gui.SmartWindow.Controls.Close
        local shield = Instance.new("TextButton")
        shield.Name = "BukCloseShield"
        shield.BackgroundTransparency = 1
        shield.Size = UDim2.fromScale(1, 1)
        shield.Text = ""
        shield.AutoButtonColor = false
        shield.ZIndex = 1000
        shield.Parent = close
        menuConns[#menuConns + 1] = shield.Activated:Connect(function()
            setMenuOpen(false)
        end)
    end)

    -- o botão de celular da própria Luna fica sempre escondido (quem abre é o BUK)
    pcall(function()
        local ms = gui:FindFirstChild("MobileSupport")
        if ms then
            ms.Visible = false
            menuConns[#menuConns + 1] = ms:GetPropertyChangedSignal("Visible"):Connect(function()
                if ms.Visible then
                    ms.Visible = false
                end
            end)
        end
    end)

    -- Tecla do menu (PC)
    menuConns[#menuConns + 1] = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == State.MenuKey then
            setMenuOpen(not menuOpen)
        end
    end)
end

destroyUI = function()
    NotifyImpl = nil
    FlingDropdown, FlingToggle, EmoteDropdown = nil, nil, nil

    for _, c in ipairs(menuConns) do
        pcall(function()
            c:Disconnect()
        end)
    end
    table.clear(menuConns)

    for f in pairs(hiddenBlur) do
        pcall(function()
            f:Destroy()
        end)
    end
    table.clear(hiddenBlur)
    table.clear(hiddenGui)

    pcall(function()
        if BukGui then
            BukGui:Destroy()
        end
    end)
    BukGui, BukBtn, BukStroke = nil, nil, nil
    menuOpen = true

    local gui = LunaGui
    LunaGui = nil

    local lib = LunaLib
    LunaLib = nil
    if lib then
        pcall(function()
            lib:Destroy()
        end)
    end
    pcall(function()
        if gui then
            gui:Destroy()
        end
    end)
end

buildUI = function()
    destroyUI()

    -- evita o aviso de "Luna deprecated" da própria biblioteca
    genv.ConfirmLuna = true

    local okGet, body = pcall(function()
        return game:HttpGet(LUNA_URL, true)
    end)
    if not okGet or type(body) ~= "string" or #body == 0 then
        error("Luna UI: could not download the library (check your internet / executor HttpGet)")
    end
    local chunk, compileErr = loadstring(body)
    if not chunk then
        error("Luna UI: could not compile the library: " .. tostring(compileErr))
    end
    local okRun, Luna = pcall(chunk)
    if not okRun or type(Luna) ~= "table" then
        error("Luna UI: could not start the library: " .. tostring(Luna))
    end
    LunaLib = Luna

    local uiReady = false -- evita que callbacks da criação mexam no State

    -- Avisos (usa as notificações da Luna)
    NotifyImpl = function(text, icon, duration)
        Luna:Notification({
            Title       = "Buk",
            Content     = tostring(text),
            Icon        = NOTIFY_ICONS[icon] or "info",
            ImageSource = "Material",
            Duration    = duration or 3,
        })
    end

    -- ───────────── JANELA ─────────────
    local Window = Luna:CreateWindow({
        Name           = "Buk",
        Subtitle       = "by Linesketon02",
        LoadingEnabled = false,
        KeySystem      = false,
        ConfigSettings = { ConfigFolder = "Buk" },
    })
    Window.Bind = INERT_KEY -- o atalho de teclado agora é do script (ocultar sem sobras na tela)

    local function newTab(titleKey, icon)
        return Window:CreateTab({
            Name        = L(titleKey),
            Icon        = icon,
            ImageSource = "Material",
            ShowTitle   = true,
        })
    end

    local TabMain     = newTab("tab_main", "home")
    local TabPlayer   = newTab("tab_player", "person")
    local TabVisuals  = newTab("tab_visuals", "visibility")
    local TabPick     = newTab("tab_pick", "pan_tool")
    local TabFarm     = newTab("tab_farm", "monetization_on")
    local TabSheriff  = newTab("tab_sheriff", "gps_fixed")
    local TabTroll    = newTab("tab_troll", "bolt")
    local TabEmotes   = newTab("tab_emotes", "content_copy")
    local TabSettings = newTab("tab_settings", "settings")

    -- ───────────── ajudantes ─────────────
    local function addToggle(sec, title, key, onChange)
        return sec:CreateToggle({
            Name         = title,
            CurrentValue = State[key] == true,
            Callback     = function(v)
                if not uiReady then return end
                State[key] = v and true or false
                if onChange then onChange(v) end
            end,
        })
    end

    local function addSlider(sec, title, key, min, max)
        return sec:CreateSlider({
            Name         = title,
            Range        = { min, max },
            Increment    = 1,
            CurrentValue = math.clamp(State[key], min, max),
            Callback     = function(v)
                if not uiReady then return end
                State[key] = tonumber(v) or State[key]
            end,
        })
    end

    -- Atualiza a lista de um dropdown de jogadores mantendo a seleção atual
    -- (a Luna exige uma opção válida ao trocar a lista)
    local function refreshPlayerDropdown(obj, guard, values, current, adopt)
        if not obj then return end

        local list = {}
        for _, v in ipairs(values) do
            list[#list + 1] = v
        end
        if current and not table.find(list, current) then
            list[#list + 1] = current
        end
        if #list == 0 then
            list[1] = L("none")
        end

        local chosen = (current and table.find(list, current)) and current or list[1]
        guard.busy = true
        pcall(function()
            obj:Set({ Options = list, CurrentOption = { chosen } })
        end)
        guard.busy = false

        if current == nil and chosen ~= L("none") then
            adopt(chosen)
        end
    end

    -- ───────────── MAIN ─────────────
    local InfoSec = TabMain:CreateSection(L("sec_info"))
    InfoSec:CreateLabel({ Text = L("info_author"), Style = 1 })
    InfoSec:CreateLabel({ Text = L("info_menu"), Style = 2 })

    -- ───────────── PLAYER ─────────────
    local MoveSec = TabPlayer:CreateSection(L("sec_move"))
    addToggle(MoveSec, L("cframe"), "CFrameOn")
    addSlider(MoveSec, L("cframe_speed"), "CFrameSpeed", 5, 100)
    addToggle(MoveSec, L("inf_jump"), "InfJump")
    addToggle(MoveSec, L("noclip"), "Noclip")

    local ProtectSec = TabPlayer:CreateSection(L("sec_protect"))
    addToggle(ProtectSec, L("anti_fling"), "AntiFling", function(v)
        if not v then
            restoreBackup(antiBackup)
        end
    end)

    -- ───────────── VISUALS (ESP) ─────────────
    local NameSec = TabVisuals:CreateSection(L("sec_name"))
    addToggle(NameSec, L("esp_name"), "EspName")

    local RolesSec = TabVisuals:CreateSection(L("sec_roles"))
    addToggle(RolesSec, L("role_inn"),  "RoleInnocent")
    addToggle(RolesSec, L("role_sher"), "RoleSheriff")
    addToggle(RolesSec, L("role_murd"), "RoleMurderer")

    local ItemsSec = TabVisuals:CreateSection(L("sec_items"))
    addToggle(ItemsSec, L("gun_drop"),      "GunDrop")
    addToggle(ItemsSec, L("arrow_murder"),  "ArrowMurder")
    addToggle(ItemsSec, L("arrow_sheriff"), "ArrowSheriff")

    -- ───────────── WEAPON ─────────────
    local PickSec = TabPick:CreateSection(L("sec_pick"))
    addToggle(PickSec, L("pick_auto"), "PickAuto")
    addToggle(PickSec, L("pick_screen"), "PickButton", setPickButtonVisible)

    local PickPcSec = TabPick:CreateSection(L("sec_pick_pc"))
    addToggle(PickPcSec, L("pick_key_on"), "PickKeyOn")
    PickPcSec:CreateBind({
        Name             = L("pick_key"),
        CurrentBind      = State.PickKey.Name,
        HoldToInteract   = false,
        Callback         = function() end, -- quem pega a arma é o próprio script
        OnChangedCallback = function(bind)
            if not uiReady then return end
            local kc = toKeyCode(bind)
            if kc then
                State.PickKey = kc
            end
        end,
    })

    -- ───────────── AUTO FARM ─────────────
    -- (o Auto Farm nunca liga sozinho na próxima execução)
    local FarmSec = TabFarm:CreateSection(L("sec_farm"))
    addToggle(FarmSec, L("farm_on"), "FarmOn")
    addSlider(FarmSec, L("farm_limit"), "FarmLimit", 10, 60)
    addToggle(FarmSec, L("farm_safe"), "FarmSafe")
    addToggle(FarmSec, L("farm_reset"), "FarmReset")

    -- ───────────── AIMBOT MM2 ─────────────
    local MagicSec = TabSheriff:CreateSection(L("sec_magic"))
    addToggle(MagicSec, L("magic"), "MagicBullet", function(v)
        if v then
            if not installAimHook() then
                notify(L("no_hook"), "triangle-alert", 4)
            end
        else
            magicAim = nil
        end
    end)
    MagicSec:CreateDropdown({
        Name            = L("magic_part"),
        Options         = { L("part_torso"), L("part_head") },
        CurrentOption   = { (State.AimPart == "Head") and L("part_head") or L("part_torso") },
        MultipleOptions = false,
        Callback        = function(option)
            if not uiReady then return end
            if option == L("part_head") then
                State.AimPart = "Head"
            elseif option == L("part_torso") then
                State.AimPart = "Torso"
            end
        end,
    })
    addToggle(MagicSec, L("magic_predict"), "AimPredict")

    local WallSec = TabSheriff:CreateSection(L("sec_wall"))
    addToggle(WallSec, L("wall_shot"), "WallShot", function(v)
        if v then
            if not installAimHook() then
                notify(L("no_hook"), "triangle-alert", 4)
            end
        else
            Aim.clearTags()
        end
    end)

    local AutoPickSec = TabSheriff:CreateSection(L("sec_autopick"))
    addToggle(AutoPickSec, L("autopick_gun"), "AutoPickGun")

    -- ───────────── TROLL ─────────────
    -- 1) Fling (liga/desliga)   2) Escolher o player   3) Velocidade sempre no máximo
    local FlingSec = TabTroll:CreateSection(L("sec_fling"))

    local flingToggleObj = addToggle(FlingSec, L("fling"), "Fling", function(v)
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
    -- o resto do script chama FlingToggle:Set(false) quando o Fling termina sozinho
    FlingToggle = {
        Set = function(_, v)
            pcall(function()
                flingToggleObj:Set({ CurrentValue = v and true or false })
            end)
        end,
    }

    local flingGuard = { busy = false }
    local flingNames = flingValues()
    local flingObj = FlingSec:CreateDropdown({
        Name            = L("fling_player"),
        Options         = flingNames,
        CurrentOption   = (State.FlingTarget and table.find(flingNames, State.FlingTarget)) and { State.FlingTarget } or {},
        MultipleOptions = false,
        Callback        = function(option)
            if flingGuard.busy then return end
            if type(option) == "string" then
                State.FlingTarget = (option ~= L("none")) and option or nil
            end
        end,
    })
    FlingDropdown = {
        Refresh = function(_, values)
            refreshPlayerDropdown(flingObj, flingGuard, values, State.FlingTarget, function(v)
                State.FlingTarget = v
            end)
        end,
    }

    -- ───────────── COPY ANIMATION ─────────────
    local CopySec = TabEmotes:CreateSection(L("sec_copy"))

    local emoteGuard = { busy = false }
    local emoteNames = flingList()
    local emoteObj = CopySec:CreateDropdown({
        Name            = L("copy_player"),
        Options         = emoteNames,
        CurrentOption   = (EmoteTarget and table.find(emoteNames, EmoteTarget)) and { EmoteTarget } or {},
        MultipleOptions = false,
        Callback        = function(option)
            if emoteGuard.busy then return end
            if type(option) == "string" then
                EmoteTarget = (option ~= L("none")) and option or nil
            end
        end,
    })
    EmoteDropdown = {
        Refresh = function(_, values)
            refreshPlayerDropdown(emoteObj, emoteGuard, values, EmoteTarget, function(v)
                EmoteTarget = v
            end)
        end,
    }

    CopySec:CreateButton({
        Name     = L("copy_refresh"),
        Callback = function()
            refreshEmoteList()
        end,
    })
    CopySec:CreateButton({
        Name     = L("copy_btn"),
        Callback = function()
            local ok, reason = copyAnimationFrom(EmoteTarget)
            if ok then
                notify(L(reason == "saved" and "copy_saved" or "copy_ok"), "check", 2.5)
            else
                local key = (reason == "dead" and "copy_dead")
                    or (reason == "noanim" and "copy_noanim")
                    or "copy_noplayer"
                notify(L(key), "triangle-alert", 3)
            end
        end,
    })
    CopySec:CreateButton({
        Name     = L("copy_restore"),
        Callback = function()
            if restoreAnimation() then
                notify(L("copy_restored"), "check", 2.5)
            end
        end,
    })

    local SavedSec = TabEmotes:CreateSection(L("sec_saved"))
    SavedSec:CreateButton({
        Name     = L("saved_use"),
        Callback = function()
            if not savedAnim then
                notify(L("saved_none"), "triangle-alert", 3)
            elseif applyAnimIds(savedAnim) then
                copiedAnim = savedAnim
                notify(L("saved_used"), "check", 2.5)
            else
                notify(L("copy_dead"), "triangle-alert", 3)
            end
        end,
    })
    SavedSec:CreateButton({
        Name     = L("saved_remove"),
        Callback = function()
            removeAnimFile()
            notify(L("saved_removed"), "check", 2.5)
        end,
    })

    -- ───────────── SETTINGS ─────────────
    local MenuSec = TabSettings:CreateSection(L("sec_menu"))
    MenuSec:CreateBind({
        Name             = L("menu_key"),
        CurrentBind      = State.MenuKey.Name,
        HoldToInteract   = false,
        Callback         = function() end,
        OnChangedCallback = function(bind)
            if not uiReady then return end
            local kc = toKeyCode(bind)
            if kc then
                State.MenuKey = kc
            end
        end,
    })

    addToggle(MenuSec, L("float_lock"), "BukBtnLock")

    MenuSec:CreateButton({
        Name     = L("save_btn"),
        Callback = function()
            if not Compat.files then
                notify(L("no_files"), "triangle-alert", 3)
                return
            end
            if saveConfig() then
                notify(L("saved_text"), "save", 2.5)
            else
                notify(L("save_fail_text"), "triangle-alert", 3)
            end
        end,
    })

    -- Unload: toque duas vezes (evita fechar sem querer)
    local unloadArmed = false
    MenuSec:CreateButton({
        Name     = L("unload_btn"),
        Callback = function()
            if unloadArmed then
                Unload()
                return
            end
            unloadArmed = true
            notify(L("close_confirm"), "triangle-alert", 2.5)
            task.delay(3, function()
                unloadArmed = false
            end)
        end,
    })

    -- Botão flutuante BUK + ocultar a interface sem deixar sobras
    LunaGui = findLunaGui()
    if LunaGui then
        hookLunaControls()
    else
        safeWarn("could not find the Luna window to hide it", "hide")
    end
    buildBukButton()

    uiReady = true
end

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

