--[[
    ╔══════════════════════════════════════╗
    ║  Buk                                 ║
    ║  Developed by: Linesketon02          ║
    ║  UI: WindUI                          ║
    ╚══════════════════════════════════════╝

    Abas: Main | Player | Auto Farm | ESP | Weapon | Aimbot MM2 | Troll | Extras | Settings
    Tecla para abrir/fechar: RightShift (muda em Settings > Menu Key)
    Celular: minimize a janela e use o botão "BUK" (arrastável) para abrir de novo
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
        tab_sheriff = "Aimbot MM2", tab_troll = "Troll", tab_settings = "Settings", tab_extras = "Extras",
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
        farm_under = "Underground Farm", farm_speed = "Farm Speed",
        sec_magic = "Magic Bullet", magic = "Magic Bullet",
        magic_part = "Aim Part", part_torso = "Torso", part_head = "Head",
        magic_predict = "Prediction (ping compensation)",
        wall_shot = "Shoot Through Walls",
        sec_fling = "Fling", fling = "Fling", fling_player = "Select Player",
        fling_notarget = "Select a player first.", fling_dead = "You need to be alive.",
        fling_norole = "No Sheriff/Murderer in the match right now.",
        fling_tdead = "That player isn't alive right now.", fling_left = "The player left. Fling stopped.",
        sec_menu = "Menu",
        sec_xray = "X-Ray", xray = "X-Ray", xray_level = "X-Ray Transparency (%)",
        sec_light = "Lighting", fullbright = "Fullbright", no_fog = "No Fog",
        sec_camera = "Camera", fov_on = "Custom Field of View", fov = "Field of View",
        unlock_zoom = "Unlock Camera Zoom",
        sec_walk = "Walk", walk_on = "Custom Walk Speed", walk_speed = "Walk Speed",
        sec_look = "Appearance", theme = "Theme", transparent = "Transparent Window", notifs = "Notifications",
        sec_config = "Settings File", autosave = "Auto Save", delete_btn = "Delete Saved Settings",
        deleted_text = "Saved settings deleted. Defaults load next time.",
        sec_util = "Utilities", anti_afk = "Anti-AFK", fps_boost = "FPS Boost",
        sec_server = "Server", rejoin = "Rejoin Server", hop = "Server Hop", copy_id = "Copy Server ID",
        rejoining = "Rejoining...", hop_search = "Looking for another server...",
        hop_none = "No other server found.", hop_fail = "Couldn't get the server list.",
        copied = "Server ID copied.", no_clip = "Your executor can't copy to the clipboard.",
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
    XRay        = false,
    XRayLevel   = 60,     -- % de transparência do mapa

    -- Extras
    Fullbright  = false,
    NoFog       = false,
    FovOn       = false,
    Fov         = 90,
    UnlockZoom  = false,
    WalkOn      = false,
    WalkSpeed   = 24,

    -- Sheriff
    MagicBullet = false,
    WallShot    = false,
    AimPart     = "Torso",
    AimPredict  = true,

    -- Auto Farm
    FarmOn    = false,
    FarmSpeed = 25, -- slider 25 a 30 (aba Auto Farm)
    FarmUnder = true, -- true: anda por BAIXO do mapa e sobe só pra pegar a moeda
    FarmSafe  = true,
    FarmLimit = 40,
    FarmReset = false,

    -- Troll (o Fling nunca liga sozinho; State.FlingTarget = nome do player escolhido)
    Fling = false,

    -- Menu
    MenuKey = Enum.KeyCode.RightShift,
    Notify      = true,   -- avisos na tela
    AutoSave    = false,  -- salva as opções sozinho
    AntiAFK     = false,
    FpsBoost    = false,
    Theme       = "Demon Slayer", -- tema da WindUI
    Transparent = true,   -- janela transparente
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
    if not NotifyImpl or State.Notify == false then return end
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
    "MagicBullet", "WallShot", "AimPart", "AimPredict",
    "FarmSafe", "FarmLimit", "FarmReset", "FarmUnder", "FarmSpeed",
    "XRay", "XRayLevel", "Fullbright", "NoFog", "FovOn", "Fov", "UnlockZoom", "WalkOn", "WalkSpeed",
    "Notify", "AutoSave", "AntiAFK", "FpsBoost", "Theme", "Transparent",
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

        -- "Dark" era o tema padrão antigo: passa pro Demon Slayer
        if State.Theme == "Dark" then
            State.Theme = "Demon Slayer"
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
        or State.MagicBullet or State.WallShot
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

-- Esp Name: cartão com bolinha (cor do role), nome e distância.
-- Fica bem ACIMA da cabeça: sobe NAME_STUDS_UP studs e ainda ganha uma folga fixa
-- em pixels (NAME_GAP_PX), então não cola na cabeça nem de perto nem de longe.
-- (a borda e a bolinha ganham a cor do role só se o ESP desse role estiver ligado)
local NAME_STUDS_UP = 2.6
local NAME_GAP_PX   = 8
local NAME_H        = 28

local function makeNameTag(accent)
    local gui = Instance.new("BillboardGui")
    gui.Name = "NameTag"
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(300, 100)
    gui.StudsOffset = Vector3.new(0, NAME_STUDS_UP, 0)
    gui.Parent = HighlightFolder

    -- o cartão nasce com a base um pouco acima do centro do billboard e cresce pra cima
    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 1)
    card.Position = UDim2.new(0.5, 0, 0.5, -NAME_GAP_PX)
    card.Size = UDim2.fromOffset(0, NAME_H)
    card.AutomaticSize = Enum.AutomaticSize.X
    card.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    card.BackgroundTransparency = 0.12
    card.BorderSizePixel = 0
    card.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, NAME_H / 2)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.15
    stroke.Parent = card

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 11)
    pad.PaddingRight = UDim.new(0, 13)
    pad.Parent = card

    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 7)
    list.Parent = card

    local dot = Instance.new("Frame")
    dot.LayoutOrder = 1
    dot.Size = UDim2.fromOffset(8, 8)
    dot.BackgroundColor3 = accent
    dot.BorderSizePixel = 0
    dot.Parent = card

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    local label = Instance.new("TextLabel")
    label.LayoutOrder = 2
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(0, NAME_H)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = WHITE
    label.RichText = true
    label.Text = ""
    label.Parent = card

    return gui, label, stroke, dot
end

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
        local gui, label, stroke, dot = makeNameTag(NAME_NEUTRAL)
        t = { gui = gui, label = label, stroke = stroke, dot = dot, text = nil, color = NAME_NEUTRAL }
        nameTags[player] = t
    end

    if t.gui.Adornee ~= head then
        t.gui.Adornee = head
    end

    local color = (role and ROLE_COLORS[role]) or NAME_NEUTRAL
    if t.color ~= color then
        t.color = color
        t.stroke.Color = color
        t.dot.BackgroundColor3 = color
    end

    local nm = player.DisplayName
    if nm == nil or nm == "" then
        nm = player.Name
    end
    nm = nm:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")

    local text = string.format('%s  <font color="#9ca3c0" size="12">%dm</font>', nm, math.floor(dist or 0))
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
--  - SÓ funciona dentro da partida (vivo, com role definido e mapa/moedas no jogo)
--  - Underground Farm (padrão): você anda por BAIXO do mapa, sobe só no instante
--    de pegar a moeda e já desce de novo (nada de ficar voando por cima do mapa)
--  - Sem Underground: anda reto até a moeda (atravessa paredes)
--  - O movimento é feito frame a frame (sem Tween) e a posição fica travada:
--    sem tremedeira, sem cair no vazio e sem travar quando pausa ou desliga
--  - Modo Seguro: pausas aleatórias, sorteia entre as 3 moedas mais próximas e
--    espera parado se o murder chegar perto
--  - Moeda que não dá pra pegar é descartada após 3 tentativas
--  Obs.: nenhum script garante 100% contra detecção. Use com moderação.
-- ═══════════════════════════════════════════════════════════
local FARM_DEPTH = 9 -- Underground: quantos studs abaixo da moeda você anda

local Farm = {
    container = nil,   -- pasta das moedas do mapa atual
    visited   = {},    -- moedas já tocadas ou descartadas (não são alvo de novo)
    pending   = {},    -- moedas tocadas que ainda não sumiram (o servidor pode demorar)
    tries     = setmetatable({}, { __mode = "k" }),
    count     = 0,     -- moedas pegas nesta partida
    fullFor   = nil,   -- mapa em que a bolsa já encheu
    scanAt    = 0,
    idleAt    = nil,
    matchOkAt = 0,
    murderAt  = 0,
    murderVal = false,
    engaged   = false, -- true enquanto o script controla o seu personagem
    under     = false, -- true quando você está embaixo do mapa
    pos       = nil,   -- CFrame em que o personagem é mantido
    rootRef   = nil,   -- HumanoidRootPart que está sendo controlado
    safeCF    = nil,   -- último lugar seguro na superfície (pra voltar)
}

-- Tem um murder (vivo) perto dessa posição?
function Farm.murderNear(pos, radius)
    local now = os.clock()
    if now - Farm.murderAt < 0.2 then
        return Farm.murderVal
    end
    Farm.murderAt  = now
    Farm.murderVal = false

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c = p.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 and (r.Position - pos).Magnitude <= radius then
                if getRole(p) == "Murderer" then
                    Farm.murderVal = true
                    break
                end
            end
        end
    end
    return Farm.murderVal
end

-- Você está DENTRO da partida? (vivo, participando da rodada e fora do vazio/limbo)
-- Fora disso o Auto Farm para sozinho e volta quando você entrar numa partida de novo.
-- Os dados do jogo podem oscilar por um instante, então existe uma tolerância de 2s
-- (menos quando você morre: aí para na hora).
function Farm.inMatch()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root and hum.Health > 0) then
        Farm.matchOkAt = 0
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
        Farm.matchOkAt = now
        return true
    end
    return Farm.matchOkAt > 0 and now - Farm.matchOkAt < 2
end

function Farm.findContainer()
    if Farm.container and Farm.container:IsDescendantOf(Workspace) then
        return Farm.container
    end
    local now = os.clock()
    if now - Farm.scanAt < 1 then
        return nil
    end
    Farm.scanAt = now
    return Workspace:FindFirstChild("CoinContainer", true)
end

-- A moeda já foi coletada? (sumiu, perdeu o CoinVisual ou ele ficou invisível)
function Farm.isCollected(coin)
    if not coin.Parent then
        return true
    end
    local v = coin:FindFirstChild("CoinVisual")
    if not v then
        return true
    end
    if v:IsA("BasePart") and v.Transparency >= 0.95 then
        return true
    end
    return false
end

function Farm.coinAvailable(coin)
    return coin:IsA("BasePart")
        and not Farm.visited[coin]
        and not Farm.isCollected(coin)
end

function Farm.pickCoin(container, from)
    local list = {}
    for _, c in ipairs(container:GetChildren()) do
        if Farm.coinAvailable(c) then
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

-- Coloca o personagem numa posição e trava ele lá (zera velocidade e giro).
-- 'dir' (opcional) faz o personagem olhar na direção do movimento.
function Farm.setPos(root, p, dir)
    local cf = nil
    if dir then
        local flat = Vector3.new(dir.X, 0, dir.Z)
        if flat.Magnitude > 0.05 then
            cf = CFrame.lookAt(p, p + flat)
        end
    end
    if not cf then
        local old = Farm.pos
        cf = old and (CFrame.new(p) * (old - old.Position)) or CFrame.new(p)
    end
    Farm.pos = cf
    root.CFrame = cf
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

-- Solta o personagem. Se você estava embaixo do mapa, sobe de volta pra
-- superfície antes (só se o jogo não te levou pra outro lugar nesse meio tempo).
function Farm.release()
    local root, pos = Farm.rootRef, Farm.pos
    if Farm.engaged and Farm.under and Farm.safeCF
        and root and root.Parent and pos
        and (root.Position - pos.Position).Magnitude < 20 then
        root.CFrame = Farm.safeCF
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    Farm.engaged = false
    Farm.under   = false
    Farm.pos     = nil
    Farm.rootRef = nil
end

-- Anda em linha reta até 'goal' (Vector3), frame a frame, na velocidade 'speed'.
-- Retorna: "arrived" | "murder" | "gone" | "timeout" | "stopped"
function Farm.glide(root, hum, coin, goal, speed)
    local t0      = os.clock()
    local maxTime = (goal - Farm.pos.Position).Magnitude / speed + 3

    while true do
        if not (alive and State.FarmOn) or flingRunning then
            return "stopped"
        end
        if not (root.Parent and hum.Parent and hum.Health > 0) then
            return "stopped"
        end
        if not coin.Parent then
            return "gone"
        end
        if not Farm.inMatch() then
            return "stopped"
        end
        if State.FarmSafe and Farm.murderNear(Farm.pos.Position, 30) then
            return "murder"
        end
        if os.clock() - t0 > maxTime then
            return "timeout"
        end

        local dt = math.min(RunService.Heartbeat:Wait(), 0.1)
        if not Farm.pos then
            return "stopped" -- o Auto Farm foi solto enquanto esperava o frame
        end
        local from = Farm.pos.Position
        local diff = goal - from
        local dist = diff.Magnitude
        local step = speed * dt
        if dist <= step then
            Farm.setPos(root, goal)
            return "arrived"
        end
        Farm.setPos(root, from + diff / dist * step, diff)
    end
end

-- Espera a moeda sumir (foi coletada). Retorna true se coletou.
function Farm.waitCollected(coin)
    local t0 = os.clock()
    while alive and State.FarmOn and not Farm.isCollected(coin) and os.clock() - t0 < 0.4 do
        task.wait()
    end
    return Farm.isCollected(coin)
end

-- Moedas que o servidor confirmou depois (sumiram com atraso) entram na contagem
function Farm.sweepPending()
    for coin in pairs(Farm.pending) do
        if Farm.isCollected(coin) then
            Farm.pending[coin] = nil
            Farm.count = Farm.count + 1
        end
    end
end

-- Mantém o personagem travado na posição enquanto o Auto Farm está no controle
-- (é isso que segura você embaixo do mapa nas pausas, sem cair)
track(RunService.Heartbeat:Connect(function()
    if not Farm.engaged then return end
    local root = Farm.rootRef
    if not (root and root.Parent and Farm.pos) then return end
    root.CFrame = Farm.pos
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end))

-- Atravessa paredes e chão enquanto o Auto Farm está no controle (lista de peças em cache)
do
    local parts, partsAt, partsChar = {}, 0, nil

    track(RunService.Stepped:Connect(function()
        if not (State.FarmOn and Farm.engaged) then return end

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
    -- desligado / Fling ativo: solta o personagem
    if not State.FarmOn or flingRunning then
        if Farm.engaged then Farm.release() end
        return
    end

    -- Fora da partida (morreu, lobby, limbo...): não faz nada
    if not Farm.inMatch() then
        if Farm.engaged then Farm.release() end
        return
    end

    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local container = Farm.findContainer()

    -- Mapa novo = partida nova: zera o contador
    if container ~= Farm.container then
        Farm.release()
        Farm.container = container
        Farm.visited   = {}
        Farm.pending   = {}
        Farm.tries     = setmetatable({}, { __mode = "k" })
        Farm.count     = 0
        Farm.fullFor   = nil
    end

    if not (hum and root and hum.Health > 0 and container) or Farm.fullFor == container then
        if Farm.engaged then Farm.release() end
        return
    end

    -- Personagem novo (respawn): recomeça do zero
    if Farm.engaged and Farm.rootRef ~= root then
        Farm.engaged, Farm.under, Farm.pos, Farm.rootRef = false, false, nil, nil
    end

    Farm.sweepPending()

    -- Bolsa cheia: sobe de volta, para até a próxima rodada (e reseta se pedido)
    if Farm.count >= State.FarmLimit then
        Farm.fullFor = container
        Farm.release()
        notify(L("farm_full"), "check")
        if State.FarmReset then
            hum.Health = 0
        end
        return
    end

    -- Desligou o Underground com você embaixo do mapa: sobe de volta
    if Farm.engaged and Farm.under and not State.FarmUnder then
        Farm.release()
    end

    local from = (Farm.engaged and Farm.pos or root.CFrame).Position

    -- Murder perto: espera. Embaixo do mapa fica travado onde está;
    -- na superfície solta o personagem (ele volta pro chão).
    if State.FarmSafe and Farm.murderNear(from, 30) then
        if Farm.engaged and not Farm.under then
            Farm.release()
        end
        return
    end

    local coin = Farm.pickCoin(container, from)
    if not coin then
        -- sem moeda livre: sobe depois de 1s e, depois de 3s, tenta de novo as que não confirmaram
        Farm.idleAt = Farm.idleAt or os.clock()
        local idle = os.clock() - Farm.idleAt
        if idle > 1 and Farm.engaged then
            Farm.release()
        end
        if idle > 3 then
            Farm.idleAt = nil
            -- só libera de novo (1 tentativa extra) as moedas tocadas que não confirmaram;
            -- as que já foram coletadas NUNCA voltam a ser alvo
            for c in pairs(Farm.pending) do
                if (Farm.tries[c] or 0) < 2 then
                    Farm.visited[c] = nil
                    Farm.pending[c] = nil
                end
            end
        end
        return
    end
    Farm.idleAt = nil

    -- Assume o controle do personagem
    if not Farm.engaged then
        Farm.engaged = true
        Farm.under   = false
        Farm.rootRef = root
        Farm.pos     = root.CFrame
        Farm.safeCF  = root.CFrame
    end

    local coinPos = coin.Position
    local speed   = math.max(State.FarmSpeed, 1)
    local result

    if State.FarmUnder then
        local depthY = coinPos.Y - FARM_DEPTH
        if not Farm.under then
            -- mergulha na vertical (direto embaixo de onde você está)
            local p = Farm.pos.Position
            Farm.setPos(root, Vector3.new(p.X, depthY, p.Z))
            Farm.under = true
        end
        result = Farm.glide(root, hum, coin, Vector3.new(coinPos.X, depthY, coinPos.Z), speed)
    else
        result = Farm.glide(root, hum, coin, coinPos, speed)
    end

    if result == "stopped" then
        Farm.release()
        return
    end

    if result == "arrived" then
        if State.FarmUnder then
            -- sobe até a moeda (esse é o ponto de volta seguro se parar agora)
            Farm.setPos(root, coinPos)
            Farm.under  = false
            Farm.safeCF = CFrame.new(coinPos + Vector3.new(0, 2, 0))
        end

        if firetouchinterest then
            pcall(function()
                firetouchinterest(root, coin, 0)
                firetouchinterest(root, coin, 1)
            end)
        end

        -- a moeda já conta como visitada: não volta nela agora (mesmo se o servidor demorar pra confirmar)
        Farm.visited[coin] = true
        if Farm.waitCollected(coin) then
            Farm.count = Farm.count + 1
        else
            -- sem confirmação ainda: fica pendente (conta quando sumir)
            Farm.tries[coin]   = (Farm.tries[coin] or 0) + 1
            Farm.pending[coin] = true
        end

        -- já desce de volta pra baixo do mapa
        if State.FarmUnder and Farm.engaged and root.Parent then
            Farm.setPos(root, Vector3.new(coinPos.X, coinPos.Y - FARM_DEPTH, coinPos.Z))
            Farm.under = true
        end

        if State.FarmSafe then
            task.wait(0.02 + math.random() * 0.08)
        end

    elseif result == "timeout" then
        -- moeda que não dá pra alcançar: desiste depois de 3 tentativas
        Farm.tries[coin] = (Farm.tries[coin] or 0) + 1
        if Farm.tries[coin] >= 3 then
            Farm.visited[coin] = true
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
    if Farm.engaged or flingRunning then return end

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
--  12A. X-RAY (aba Main) e EXTRAS (aba Extras)
--  - Tudo é lido do State por loops (liga/desliga sem precisar de callback)
--  - Cada recurso guarda o valor original e devolve ao desligar / descarregar
--    (o Unload chama tudo que estiver em Extra.restore)
-- ═══════════════════════════════════════════════════════════
local Extra = { restore = {} }

-- X-Ray: deixa o mapa transparente só pra você (LocalTransparencyModifier não replica)
do
    local XRay = {
        on      = false,
        token   = 0,
        applied = nil,
        touched = setmetatable({}, { __mode = "k" }),
        queue   = {},
    }

    function XRay.value()
        return math.clamp(State.XRayLevel, 10, 95) / 100
    end

    -- Não mexe em: jogadores/NPCs, ferramentas, moedas e a arma dropada
    function XRay.skip(part)
        if part.Name == "GunDrop" then return true end
        local a = part.Parent
        while a and a ~= Workspace do
            if a.Name == "CoinContainer" or a.Name == "GunDrop" then return true end
            if a:IsA("Tool") or a:IsA("Accessory") then return true end
            if a:IsA("Model") and a:FindFirstChildOfClass("Humanoid") then return true end
            a = a.Parent
        end
        return false
    end

    function XRay.tryPart(part)
        if XRay.touched[part] then return end
        if not part:IsA("BasePart") or part:IsA("Terrain") then return end
        if part.Transparency >= 0.9 or XRay.skip(part) then return end
        XRay.touched[part] = true
        pcall(function()
            part.LocalTransparencyModifier = XRay.value()
        end)
    end

    -- Varre o Workspace em pedaços (não trava o jogo em mapa grande)
    function XRay.sweep()
        XRay.token = XRay.token + 1
        local my, n = XRay.token, 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if not (alive and State.XRay) or XRay.token ~= my then return end
            XRay.tryPart(d)
            n = n + 1
            if n % 300 == 0 then task.wait() end
        end
    end

    function XRay.clear()
        XRay.token = XRay.token + 1
        XRay.on, XRay.applied, XRay.queue = false, nil, {}
        for part in pairs(XRay.touched) do
            if part.Parent then
                pcall(function()
                    part.LocalTransparencyModifier = 0
                end)
            end
            XRay.touched[part] = nil
        end
    end
    Extra.restore[#Extra.restore + 1] = XRay.clear

    -- peças que aparecem depois (mapa novo, respawn...) entram numa fila
    track(Workspace.DescendantAdded:Connect(function(d)
        if XRay.on and d:IsA("BasePart") then
            XRay.queue[#XRay.queue + 1] = d
        end
    end))

    loop("xray", 0.5, function()
        if not State.XRay then
            if XRay.on then XRay.clear() end
            return
        end

        if not XRay.on then
            XRay.on = true
            XRay.applied = XRay.value()
            XRay.sweep()
        end

        -- mexeu no slider: reaplica em tudo
        local v = XRay.value()
        if v ~= XRay.applied then
            XRay.applied = v
            for part in pairs(XRay.touched) do
                if part.Parent then
                    pcall(function()
                        part.LocalTransparencyModifier = v
                    end)
                end
            end
        end

        local q = XRay.queue
        XRay.queue = {}
        for i = 1, #q do
            if q[i].Parent then
                XRay.tryPart(q[i])
            end
            if i % 300 == 0 then task.wait() end
        end
    end)
end

-- Extras: Fullbright, No Fog, FOV, Zoom e Walk Speed
do
    local Lighting = game:GetService("Lighting")

    local function setProps(obj, props)
        for k, v in pairs(props) do
            pcall(function()
                obj[k] = v
            end)
        end
    end

    -- Fullbright e No Fog
    local fullBackup, fogBackup = nil, nil
    local FULL_LIGHT = Color3.fromRGB(178, 178, 178)

    local function restoreLight()
        if fullBackup then
            setProps(Lighting, fullBackup)
            fullBackup = nil
        end
        if fogBackup then
            setProps(Lighting, fogBackup)
            fogBackup = nil
        end
    end
    Extra.restore[#Extra.restore + 1] = restoreLight

    loop("lighting", 0.25, function()
        if State.Fullbright then
            fullBackup = fullBackup or {
                Brightness     = Lighting.Brightness,
                ClockTime      = Lighting.ClockTime,
                GlobalShadows  = Lighting.GlobalShadows,
                Ambient        = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
            setProps(Lighting, {
                Brightness     = 2,
                ClockTime      = 14,
                GlobalShadows  = false,
                Ambient        = FULL_LIGHT,
                OutdoorAmbient = FULL_LIGHT,
            })
        elseif fullBackup then
            setProps(Lighting, fullBackup)
            fullBackup = nil
        end

        if State.NoFog then
            fogBackup = fogBackup or { FogEnd = Lighting.FogEnd }
            setProps(Lighting, { FogEnd = 1e6 })
        elseif fogBackup then
            setProps(Lighting, fogBackup)
            fogBackup = nil
        end
    end)

    -- Field of View
    local fovBackup = nil
    track(RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        if not cam then return end
        if State.FovOn then
            fovBackup = fovBackup or cam.FieldOfView
            cam.FieldOfView = State.Fov
        elseif fovBackup then
            cam.FieldOfView = fovBackup
            fovBackup = nil
        end
    end))
    Extra.restore[#Extra.restore + 1] = function()
        local cam = Workspace.CurrentCamera
        if cam and fovBackup then
            cam.FieldOfView = fovBackup
        end
        fovBackup = nil
    end

    -- Zoom da câmera liberado
    local zoomBackup = nil
    local function restoreZoom()
        if zoomBackup then
            LocalPlayer.CameraMaxZoomDistance = zoomBackup.max
            LocalPlayer.CameraMinZoomDistance = zoomBackup.min
            zoomBackup = nil
        end
    end
    Extra.restore[#Extra.restore + 1] = restoreZoom

    loop("zoom", 0.5, function()
        if State.UnlockZoom then
            zoomBackup = zoomBackup or {
                max = LocalPlayer.CameraMaxZoomDistance,
                min = LocalPlayer.CameraMinZoomDistance,
            }
            LocalPlayer.CameraMaxZoomDistance = 500
            LocalPlayer.CameraMinZoomDistance = 0
        else
            restoreZoom()
        end
    end)

    -- Walk Speed (pausa enquanto o Auto Farm ou o Fling controlam o personagem)
    local walkBackup = setmetatable({}, { __mode = "k" })
    track(RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        if State.WalkOn and not Farm.engaged and not flingRunning then
            if walkBackup[hum] == nil then
                walkBackup[hum] = hum.WalkSpeed
            end
            if hum.WalkSpeed ~= State.WalkSpeed then
                hum.WalkSpeed = State.WalkSpeed
            end
        elseif walkBackup[hum] ~= nil then
            hum.WalkSpeed = walkBackup[hum]
            walkBackup[hum] = nil
        end
    end))
    Extra.restore[#Extra.restore + 1] = function()
        for hum, speed in pairs(walkBackup) do
            if hum.Parent then
                pcall(function()
                    hum.WalkSpeed = speed
                end)
            end
            walkBackup[hum] = nil
        end
    end
end

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
--  13. AIMBOT MM2: Magic Bullet e Shoot Through Walls
--  - Magic Bullet: a bala do SEU tiro vai direto pro murder (posição lida na hora do tiro)
--  - Shoot Through Walls: parede não bloqueia o tiro (raycast da Gun + tag WeaponPassthrough)
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
--  14B. EXTRAS DA ABA SETTINGS
--  Anti-AFK, FPS Boost, Rejoin, Server Hop, Copiar ID do servidor e Auto Save
-- ═══════════════════════════════════════════════════════════
local Util = {
    afkConn   = nil, -- conexão do Anti-AFK
    fpsBackup = nil, -- valores originais (FPS Boost)
}

-- Anti-AFK: o Roblox não te desconecta por ficar parado
function Util.setAntiAfk(on)
    if Util.afkConn then
        pcall(function() Util.afkConn:Disconnect() end)
        Util.afkConn = nil
    end
    if on then
        Util.afkConn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end)
    end
end

-- FPS Boost: sombras e qualidade gráfica no mínimo (desligar devolve o original)
function Util.setFpsBoost(on)
    local Lighting = game:GetService("Lighting")
    if on then
        if Util.fpsBackup then return end
        local backup = {}
        Util.fpsBackup = backup
        pcall(function()
            backup.shadows = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
        end)
        pcall(function()
            backup.quality = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    else
        local backup = Util.fpsBackup
        if not backup then return end
        Util.fpsBackup = nil
        pcall(function()
            if backup.shadows ~= nil then
                Lighting.GlobalShadows = backup.shadows
            end
        end)
        pcall(function()
            if backup.quality ~= nil then
                settings().Rendering.QualityLevel = backup.quality
            end
        end)
    end
end

-- Rejoin: volta pro mesmo servidor (se estiver sozinho, entra num servidor novo)
function Util.rejoin()
    local TeleportService = game:GetService("TeleportService")
    notify(L("rejoining"), "refresh-cw", 3)
    if #Players:GetPlayers() <= 1 then
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    else
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end
end

-- Server Hop: pula pra outro servidor público que não esteja cheio
function Util.serverHop()
    notify(L("hop_search"), "search", 3)
    local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId)
        .. "/servers/Public?sortOrder=Asc&limit=100"

    local okGet, body = pcall(function()
        return game:HttpGet(url)
    end)
    local okJson, data = false, nil
    if okGet and type(body) == "string" then
        okJson, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)
    end
    if not (okJson and type(data) == "table" and type(data.data) == "table") then
        notify(L("hop_fail"), "triangle-alert", 3)
        return
    end

    local list = {}
    for _, s in ipairs(data.data) do
        if type(s) == "table" and s.id ~= game.JobId
            and type(s.playing) == "number" and type(s.maxPlayers) == "number"
            and s.playing < s.maxPlayers - 1 then
            list[#list + 1] = s.id
        end
    end
    if #list == 0 then
        notify(L("hop_none"), "triangle-alert", 3)
        return
    end

    local TeleportService = game:GetService("TeleportService")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, list[math.random(1, #list)], LocalPlayer)
    end)
end

-- Copia o ID do servidor (JobId)
function Util.copyServerId()
    local copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if type(copy) ~= "function" then
        notify(L("no_clip"), "triangle-alert", 3)
        return
    end
    if pcall(copy, tostring(game.JobId)) then
        notify(L("copied"), "check", 2.5)
    else
        notify(L("no_clip"), "triangle-alert", 3)
    end
end

-- Auto Save: salva as opções a cada 20s (e ao descarregar o script)
loop("autosave", 20, function()
    if State.AutoSave then
        saveConfig()
    end
end)

-- ═══════════════════════════════════════════════════════════
--  15. INTERFACE (WindUI)
--  Minimize a janela e use o botão "BUK" (botão de abrir da WindUI,
--  arrastável) para abrir de novo. No PC use também a tecla do menu
--  (Settings > Menu Key).
-- ═══════════════════════════════════════════════════════════
local WINDUI_URLS = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
}
local WindUILib    = nil
local WindUIWindow = nil
local buildUI, Unload, destroyUI

local function loadWindUI()
    local lastErr = "no url worked"
    for _, url in ipairs(WINDUI_URLS) do
        local okGet, body = pcall(function()
            return game:HttpGet(url, true)
        end)
        if okGet and type(body) == "string" and #body > 0 then
            local chunk, compileErr = loadstring(body)
            if chunk then
                local okRun, lib = pcall(chunk)
                if okRun and type(lib) == "table" then
                    return lib
                end
                lastErr = tostring(lib)
            else
                lastErr = tostring(compileErr)
            end
        else
            lastErr = tostring(body)
        end
    end
    error("WindUI: could not load the library (check your internet / executor HttpGet): " .. lastErr)
end

destroyUI = function()
    NotifyImpl = nil
    FlingDropdown, FlingToggle = nil, nil

    local win = WindUIWindow
    WindUIWindow = nil
    WindUILib = nil
    if win then
        pcall(function()
            win:Destroy()
        end)
    end
end

buildUI = function()
    destroyUI()

    local WindUI = loadWindUI()
    WindUILib = WindUI

    local uiReady = false -- evita que callbacks da criação mexam no State

    -- ───────────── TEMAS (Demon Slayer) ─────────────
    local function hex(h)
        return Color3.fromHex(h)
    end
    local function addTheme(def)
        pcall(function()
            WindUI:AddTheme(def)
        end)
    end

    -- Tanjiro: preto e verde do haori + vermelho do hanafuda
    addTheme({
        Name        = "Demon Slayer",
        Accent      = hex("#1f9d55"),
        Dialog      = hex("#0b1a12"),
        Outline     = hex("#86efac"),
        Text        = hex("#ecfdf5"),
        Placeholder = hex("#3f7a5a"),
        Background  = hex("#070d0a"),
        Button      = hex("#14532d"),
        Icon        = hex("#ff6b6b"),
    })
    -- Nezuko: rosa com verde do bambu
    addTheme({
        Name        = "Nezuko",
        Accent      = hex("#ec4899"),
        Dialog      = hex("#2a0a1a"),
        Outline     = hex("#fbcfe8"),
        Text        = hex("#fdf2f8"),
        Placeholder = hex("#9d174d"),
        Background  = hex("#14040c"),
        Button      = hex("#be185d"),
        Icon        = hex("#86efac"),
    })
    -- Rengoku: respiração das chamas
    addTheme({
        Name        = "Rengoku",
        Accent      = hex("#f97316"),
        Dialog      = hex("#2a0f05"),
        Outline     = hex("#fed7aa"),
        Text        = hex("#fff7ed"),
        Placeholder = hex("#9a3412"),
        Background  = hex("#140603"),
        Button      = hex("#c2410c"),
        Icon        = hex("#facc15"),
    })
    -- Zenitsu: respiração do trovão
    addTheme({
        Name        = "Zenitsu",
        Accent      = hex("#facc15"),
        Dialog      = hex("#1f1a05"),
        Outline     = hex("#fef08a"),
        Text        = hex("#fefce8"),
        Placeholder = hex("#a16207"),
        Background  = hex("#0f0c02"),
        Button      = hex("#a16207"),
        Icon        = hex("#fde047"),
    })

    -- tema salvo (se o nome não existir mais na WindUI, volta pro Dark)
    local startTheme = "Dark"
    pcall(function()
        local themes = WindUI:GetThemes()
        if type(themes) == "table" and themes[State.Theme] then
            startTheme = State.Theme
        end
    end)
    State.Theme = startTheme

    -- Avisos (usa as notificações da WindUI; os ícones são nomes do Lucide)
    NotifyImpl = function(text, icon, duration)
        WindUI:Notify({
            Title    = "Buk",
            Content  = tostring(text),
            Icon     = icon or "info",
            Duration = duration or 3,
        })
    end

    -- ───────────── JANELA ─────────────
    local Window = WindUI:CreateWindow({
        Title        = "Buk",
        Author       = "by Linesketon02",
        Folder       = "Buk",
        Icon         = "flame",
        Theme        = startTheme,
        Transparent  = State.Transparent,
        Size         = UDim2.fromOffset(500, 330),
        SideBarWidth = 170,
    })
    if not Window then
        error("WindUI: could not create the window (another WindUI window may already be open)")
    end
    WindUIWindow = Window

    -- Botão de abrir com o nome BUK (arrastável, aparece em PC e celular)
    pcall(function()
        Window:EditOpenButton({
            Title      = "BUK",
            Color      = ColorSequence.new(Color3.fromHex("#1f9d55"), Color3.fromHex("#e03a3e")),
            Enabled    = true,
            Draggable  = true,
            OnlyMobile = false,
        })
    end)
    pcall(function()
        Window:SetToggleKey(State.MenuKey)
    end)

    local function newTab(titleKey, icon)
        return Window:Tab({
            Title = L(titleKey),
            Icon  = icon,
        })
    end

    -- ordem das abas no menu (o ícone da Main é "house": o nome antigo "home" não existe mais no Lucide)
    local TabMain     = newTab("tab_main", "house")
    local TabPlayer   = newTab("tab_player", "user")
    local TabFarm     = newTab("tab_farm", "coins")
    local TabVisuals  = newTab("tab_visuals", "eye")
    local TabPick     = newTab("tab_pick", "crosshair")
    local TabSheriff  = newTab("tab_sheriff", "target")
    local TabTroll    = newTab("tab_troll", "zap")
    local TabExtras   = newTab("tab_extras", "sparkles")
    local TabSettings = newTab("tab_settings", "settings")

    -- ───────────── ajudantes ─────────────
    -- Seção da WindUI (se a versão não tiver seção com elementos, usa a própria aba)
    local function newSection(tab, title, opened)
        local ok, sec = pcall(function()
            return tab:Section({ Title = title, Opened = opened ~= false })
        end)
        if ok and type(sec) == "table" and type(sec.Toggle) == "function" then
            return sec
        end
        return tab
    end

    local function addToggle(sec, title, key, onChange)
        return sec:Toggle({
            Title    = title,
            Value    = State[key] == true,
            Default  = State[key] == true,
            Callback = function(v)
                if not uiReady then return end
                State[key] = v and true or false
                if onChange then onChange(v) end
            end,
        })
    end

    local function addSlider(sec, title, key, min, max)
        return sec:Slider({
            Title    = title,
            Step     = 1,
            Value    = { Min = min, Max = max, Default = math.clamp(State[key], min, max) },
            Callback = function(v)
                if not uiReady then return end
                State[key] = tonumber(v) or State[key]
            end,
        })
    end

    -- ───────────── MAIN ─────────────
    local XraySec = newSection(TabMain, L("sec_xray"))
    addToggle(XraySec, L("xray"), "XRay")
    addSlider(XraySec, L("xray_level"), "XRayLevel", 20, 90)

    -- ───────────── PLAYER ─────────────
    local MoveSec = newSection(TabPlayer, L("sec_move"))
    addToggle(MoveSec, L("cframe"), "CFrameOn")
    addSlider(MoveSec, L("cframe_speed"), "CFrameSpeed", 5, 100)
    addToggle(MoveSec, L("inf_jump"), "InfJump")
    addToggle(MoveSec, L("noclip"), "Noclip")

    local ProtectSec = newSection(TabPlayer, L("sec_protect"))
    addToggle(ProtectSec, L("anti_fling"), "AntiFling", function(v)
        if not v then
            restoreBackup(antiBackup)
        end
    end)

    -- ───────────── AUTO FARM ─────────────
    -- (o Auto Farm nunca liga sozinho na próxima execução)
    local FarmSec = newSection(TabFarm, L("sec_farm"))
    addToggle(FarmSec, L("farm_on"), "FarmOn")
    addSlider(FarmSec, L("farm_speed"), "FarmSpeed", 25, 30)
    addToggle(FarmSec, L("farm_under"), "FarmUnder")
    addSlider(FarmSec, L("farm_limit"), "FarmLimit", 10, 60)
    addToggle(FarmSec, L("farm_safe"), "FarmSafe")
    addToggle(FarmSec, L("farm_reset"), "FarmReset")

    -- ───────────── VISUALS (ESP) ─────────────
    local NameSec = newSection(TabVisuals, L("sec_name"))
    addToggle(NameSec, L("esp_name"), "EspName")

    local RolesSec = newSection(TabVisuals, L("sec_roles"))
    addToggle(RolesSec, L("role_inn"),  "RoleInnocent")
    addToggle(RolesSec, L("role_sher"), "RoleSheriff")
    addToggle(RolesSec, L("role_murd"), "RoleMurderer")

    local ItemsSec = newSection(TabVisuals, L("sec_items"))
    addToggle(ItemsSec, L("gun_drop"),      "GunDrop")
    addToggle(ItemsSec, L("arrow_murder"),  "ArrowMurder")
    addToggle(ItemsSec, L("arrow_sheriff"), "ArrowSheriff")

    -- ───────────── WEAPON ─────────────
    local PickSec = newSection(TabPick, L("sec_pick"))
    addToggle(PickSec, L("pick_auto"), "PickAuto")
    addToggle(PickSec, L("pick_screen"), "PickButton", setPickButtonVisible)

    local PickPcSec = newSection(TabPick, L("sec_pick_pc"))
    addToggle(PickPcSec, L("pick_key_on"), "PickKeyOn")
    PickPcSec:Keybind({
        Title    = L("pick_key"),
        Value    = State.PickKey.Name,
        Callback = function(v) -- quem pega a arma é o próprio script
            if not uiReady then return end
            local kc = toKeyCode(v)
            if kc then
                State.PickKey = kc
            end
        end,
    })

    -- ───────────── AIMBOT MM2 ─────────────
    local MagicSec = newSection(TabSheriff, L("sec_magic"))
    addToggle(MagicSec, L("magic"), "MagicBullet", function(v)
        if v then
            if not installAimHook() then
                notify(L("no_hook"), "triangle-alert", 4)
            end
        else
            magicAim = nil
        end
    end)
    MagicSec:Dropdown({
        Title    = L("magic_part"),
        Values   = { L("part_torso"), L("part_head") },
        Value    = (State.AimPart == "Head") and L("part_head") or L("part_torso"),
        Multi    = false,
        Callback = function(option)
            if not uiReady then return end
            if type(option) == "table" then option = option[1] end
            if option == L("part_head") then
                State.AimPart = "Head"
            elseif option == L("part_torso") then
                State.AimPart = "Torso"
            end
        end,
    })
    addToggle(MagicSec, L("magic_predict"), "AimPredict")
    addToggle(MagicSec, L("wall_shot"), "WallShot", function(v)
        if v then
            if not installAimHook() then
                notify(L("no_hook"), "triangle-alert", 4)
            end
        else
            Aim.clearTags()
        end
    end)


    -- ───────────── TROLL ─────────────
    -- 1) Fling (liga/desliga)   2) Escolher o player   3) Velocidade sempre no máximo
    local FlingSec = newSection(TabTroll, L("sec_fling"))

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
                flingToggleObj:Set(v and true or false)
            end)
        end,
    }

    local flingGuard = { busy = false }
    local flingNames = flingValues()
    local flingStart = (State.FlingTarget and table.find(flingNames, State.FlingTarget)) and State.FlingTarget or nil
    local flingObj = FlingSec:Dropdown({
        Title    = L("fling_player"),
        Values   = flingNames,
        Value    = flingStart,
        Multi    = false,
        Callback = function(option)
            if flingGuard.busy then return end
            if type(option) == "table" then option = option[1] end
            if type(option) == "string" then
                State.FlingTarget = option
            end
        end,
    })
    FlingDropdown = {
        -- troca a lista mantendo o jogador escolhido (mesmo que ele tenha saído)
        Refresh = function(_, values)
            local keep = State.FlingTarget
            local list = {}
            for _, v in ipairs(values) do
                list[#list + 1] = v
            end
            if keep and not table.find(list, keep) then
                list[#list + 1] = keep
            end

            flingGuard.busy = true
            pcall(function()
                flingObj:Refresh(list)
            end)
            if keep then
                pcall(function()
                    flingObj:Select(keep)
                end)
            end
            flingGuard.busy = false
            State.FlingTarget = keep
        end,
    }

    -- ───────────── EXTRAS ─────────────
    local LightSec = newSection(TabExtras, L("sec_light"))
    addToggle(LightSec, L("fullbright"), "Fullbright")
    addToggle(LightSec, L("no_fog"), "NoFog")

    local CamSec = newSection(TabExtras, L("sec_camera"))
    addToggle(CamSec, L("fov_on"), "FovOn")
    addSlider(CamSec, L("fov"), "Fov", 70, 120)
    addToggle(CamSec, L("unlock_zoom"), "UnlockZoom")

    local WalkSec = newSection(TabExtras, L("sec_walk"))
    addToggle(WalkSec, L("walk_on"), "WalkOn")
    addSlider(WalkSec, L("walk_speed"), "WalkSpeed", 16, 50)

    -- ───────────── SETTINGS ─────────────
    local MenuSec = newSection(TabSettings, L("sec_menu"))
    MenuSec:Keybind({
        Title    = L("menu_key"),
        Value    = State.MenuKey.Name,
        Callback = function(v)
            if not uiReady then return end
            local kc = toKeyCode(v)
            if kc then
                State.MenuKey = kc
                pcall(function()
                    Window:SetToggleKey(kc)
                end)
            end
        end,
    })

    -- Unload: toque duas vezes (evita fechar sem querer)
    local unloadArmed = false
    MenuSec:Button({
        Title    = L("unload_btn"),
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

    local LookSec = newSection(TabSettings, L("sec_look"))
    local themeNames = {}
    pcall(function()
        for name in pairs(WindUI:GetThemes()) do
            themeNames[#themeNames + 1] = name
        end
    end)
    table.sort(themeNames)
    if #themeNames > 0 then
        LookSec:Dropdown({
            Title    = L("theme"),
            Values   = themeNames,
            Value    = State.Theme,
            Multi    = false,
            Callback = function(option)
                if not uiReady then return end
                if type(option) == "table" then option = option.Title or option[1] end
                if type(option) == "string" then
                    State.Theme = option
                    pcall(function()
                        WindUI:SetTheme(option)
                    end)
                end
            end,
        })
    end
    addToggle(LookSec, L("transparent"), "Transparent", function(v)
        pcall(function()
            Window:ToggleTransparency(v)
        end)
    end)
    addToggle(LookSec, L("notifs"), "Notify")

    local CfgSec = newSection(TabSettings, L("sec_config"))
    addToggle(CfgSec, L("autosave"), "AutoSave")
    CfgSec:Button({
        Title    = L("save_btn"),
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
    CfgSec:Button({
        Title    = L("delete_btn"),
        Callback = function()
            if not (Compat.files and type(delfile) == "function") then
                notify(L("no_files"), "triangle-alert", 3)
                return
            end
            local ok = pcall(function()
                if isfile(CONFIG_FILE) then
                    delfile(CONFIG_FILE)
                end
            end)
            if ok then
                notify(L("deleted_text"), "trash-2", 3)
            else
                notify(L("save_fail_text"), "triangle-alert", 3)
            end
        end,
    })

    local UtilSec = newSection(TabSettings, L("sec_util"))
    addToggle(UtilSec, L("anti_afk"), "AntiAFK", Util.setAntiAfk)
    addToggle(UtilSec, L("fps_boost"), "FpsBoost", Util.setFpsBoost)

    local SrvSec = newSection(TabSettings, L("sec_server"))
    SrvSec:Button({
        Title    = L("rejoin"),
        Callback = function()
            task.spawn(Util.rejoin)
        end,
    })
    SrvSec:Button({
        Title    = L("hop"),
        Callback = function()
            task.spawn(Util.serverHop)
        end,
    })
    SrvSec:Button({
        Title    = L("copy_id"),
        Callback = function()
            Util.copyServerId()
        end,
    })

    pcall(function()
        TabMain:Select()
    end)

    uiReady = true
end

-- ═══════════════════════════════════════════════════════════
--  16. FINALIZAÇÃO
-- ═══════════════════════════════════════════════════════════
Unload = function()
    if not alive then return end
    if State.AutoSave then pcall(saveConfig) end
    alive = false
    pcall(Util.setAntiAfk, false)
    pcall(Util.setFpsBoost, false)
    pcall(Farm.release) -- sobe de volta pra superfície se estava embaixo do mapa
    magicAim   = nil
    forcedAim  = nil
    Aim.active = false
    pcall(Aim.clearTags) -- devolve as peças que viraram "atravessáveis"
    for _, fn in ipairs(Extra.restore) do -- X-Ray, Lighting, FOV, Zoom e Walk Speed voltam ao normal
        pcall(fn)
    end
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
    if State.AntiAFK then Util.setAntiAfk(true) end
    if State.FpsBoost then Util.setFpsBoost(true) end
    if State.MagicBullet or State.WallShot then
        pcall(installAimHook)
    end
    notify(L("loaded"), "check", 4)
else
    showError(errBuild)
end

