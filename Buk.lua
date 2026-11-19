--[[
    Buk  |  by Nobody  |  v2.0 (final)
    UI  : WindUI
    Abas: Main | Player | Esp | Settings
    Menu: RightShift (pode ser trocado em Settings > Menu Key)

    Novidades da v2.0 (a interface continua a mesma):
      - CFrame Speed: Wall Check com 3 raios (pega quinas) e deslizamento
        pela parede em vez de travar; outros jogadores não bloqueiam mais
      - ESP: desenhos criados só para o que está ligado (bem menos lag),
        parts do personagem em cache, caixa correta em R6 e R15
      - Auto-save: as opções são salvas sozinhas (e ao dar Unload)
      - Menu Key aceita tecla salva como texto ou como Enum
      - Carregamento da WindUI com nova tentativa e aviso na tela
]]

local VERSION = "2.0"

--------------------------------------------------------------------
-- Evita rodar duas vezes: descarrega a versão anterior primeiro
--------------------------------------------------------------------
local env = (getgenv and getgenv()) or _G
if env.Buk_Unload then
    pcall(env.Buk_Unload)
    task.wait(0.6)
end

--------------------------------------------------------------------
-- Serviços
--------------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local floor, min, max, clamp = math.floor, math.min, math.max, math.clamp

--------------------------------------------------------------------
-- WindUI (2 links, 2 tentativas)
--------------------------------------------------------------------
local function loadWindUI()
    local urls = {
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    }
    for attempt = 1, 2 do
        for _, url in ipairs(urls) do
            local ok, lib = pcall(function()
                return loadstring(game:HttpGet(url))()
            end)
            if ok and type(lib) == "table" then
                return lib
            end
        end
        if attempt < 2 then
            task.wait(1)
        end
    end
    return nil
end

local WindUI = loadWindUI()
if not WindUI then
    warn("[Buk] Não foi possível carregar a WindUI.")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = "Buk",
            Text     = "Falha ao carregar a interface. Verifique sua internet e execute de novo.",
            Duration = 6,
        })
    end)
    return
end

--------------------------------------------------------------------
-- Tema "Darker" (a WindUI não traz esse tema pronto, então é criado aqui)
--------------------------------------------------------------------
WindUI:AddTheme({
    Name        = "Darker",
    Background  = Color3.fromHex("#060608"),
    Accent      = Color3.fromHex("#0d0d11"),
    Dialog      = Color3.fromHex("#09090c"),
    Outline     = Color3.fromHex("#26262d"),
    Text        = Color3.fromHex("#f4f4f5"),
    Placeholder = Color3.fromHex("#71717a"),
    Button      = Color3.fromHex("#2a2a31"),
    Icon        = Color3.fromHex("#a1a1aa"),
    Toggle      = Color3.fromHex("#22c55e"),
    Slider      = Color3.fromHex("#0091ff"),
    Checkbox    = Color3.fromHex("#0091ff"),
    Primary     = Color3.fromHex("#0091ff"),
    PanelBackground             = Color3.fromHex("#ffffff"),
    PanelBackgroundTransparency = 0.97,
    LabelBackground             = Color3.fromHex("#ffffff"),
    LabelBackgroundTransparency = 0.97,
})

WindUI.TransparencyValue = 0.2 -- 0 = opaco | 1 = invisível

--------------------------------------------------------------------
-- Janela
--------------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title         = "Buk",
    Author        = "by Nobody",
    Icon          = "box",
    Folder        = "Buk", -- pasta usada para salvar as configurações
    Theme         = "Darker",
    Transparent   = true,
    Size          = UDim2.fromOffset(580, 460),
    SideBarWidth  = 180,
    HideSearchBar = true,
    ToggleKey     = Enum.KeyCode.RightShift,
    OpenButton    = {
        Title     = "Buk",
        Enabled   = true,
        Draggable = true,
        Color     = ColorSequence.new(
            Color3.fromHex("#0091ff"),
            Color3.fromHex("#7c3aed")
        ),
    },
    User = {
        Enabled   = true,
        Anonymous = false,
    },
})

if not Window then
    warn("[Buk] Já existe uma janela WindUI aberta.")
    return
end

pcall(function()
    Window:Tag({
        Title  = "v" .. VERSION,
        Color  = Color3.fromHex("#0091ff"),
        Border = true,
    })
end)

--------------------------------------------------------------------
-- Utilidades
--------------------------------------------------------------------
local Connections = {}
local Unloaded    = false
local Config      = nil
local Ready       = false -- vira true depois que a config salva foi carregada
local Warned      = {}

local function notify(content, icon, duration)
    pcall(function()
        WindUI:Notify({
            Title    = "Buk",
            Content  = content,
            Icon     = icon or "info",
            Duration = duration or 3,
        })
    end)
end

local function warnOnce(tag, err)
    if not Warned[tag] then
        Warned[tag] = true
        warn("[Buk] " .. tag .. ": " .. tostring(err))
    end
end

local function connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Connections, conn)
    return conn
end

-- Auto-save: espera 2s sem mudanças e então salva (sem spam de notificação)
local saveToken = 0

local function queueSave()
    if not Ready or not Config or Unloaded then
        return
    end
    saveToken = saveToken + 1
    local token = saveToken
    task.delay(2, function()
        if token ~= saveToken or Unloaded or not Config then
            return
        end
        pcall(function()
            Config:Save()
        end)
    end)
end

-- Personagem em cache: evita FindFirstChild a cada frame
local Rig = { Char = nil, Hum = nil, Root = nil }

local function getRig()
    local char = LocalPlayer.Character
    if not char then
        return nil, nil
    end
    if Rig.Char ~= char then
        Rig.Char, Rig.Hum, Rig.Root = char, nil, nil
    end
    if not Rig.Hum or not Rig.Hum.Parent then
        Rig.Hum = char:FindFirstChildOfClass("Humanoid")
    end
    if not Rig.Root or not Rig.Root.Parent then
        Rig.Root = char:FindFirstChild("HumanoidRootPart")
    end
    return Rig.Hum, Rig.Root
end

local function applyMenuKey(value)
    local key = nil
    if typeof(value) == "EnumItem" then
        key = value
    elseif type(value) == "string" then
        local ok, result = pcall(function()
            return Enum.KeyCode[value]
        end)
        if ok then
            key = result
        end
    end
    if key then
        pcall(function()
            Window:SetToggleKey(key)
        end)
    end
end

--------------------------------------------------------------------
-- Estado
--------------------------------------------------------------------
local State = {
    CFrameSpeed  = false,
    Speed        = 50,
    WallCheck    = true,
    InfiniteJump = false,
}

local ESP = {
    Name         = false,
    Health       = false,
    Tracer       = false,
    Box          = false,
    TeamCheck    = false,
    ShowDistance = true,
    MaxDistance  = 5000,
    Color        = Color3.fromRGB(255, 70, 70),
    Objects      = {},
    Active       = false,
}

--------------------------------------------------------------------
-- Player: CFrame Speed
--------------------------------------------------------------------
-- O valor do slider é a velocidade TOTAL desejada (studs/s). O script
-- soma apenas o que falta por cima do WalkSpeed normal do jogo.
local WALL_PADDING = 2            -- distância mínima mantida da parede
local RAY_SPREAD   = 1            -- afastamento lateral dos raios extras
local RAY_OFFSETS  = { 0, 1, -1 } -- centro, direita, esquerda
local UP           = Vector3.new(0, 1, 0)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
pcall(function()
    rayParams.RespectCanCollide = true
end)

local rayChar    = nil
local lastFilter = 0

-- Ignora o seu personagem E o dos outros jogadores (só paredes bloqueiam)
local function refreshRayFilter(char)
    local now = os.clock()
    if rayChar == char and now - lastFilter < 1 then
        return
    end
    rayChar    = char
    lastFilter = now

    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            list[#list + 1] = plr.Character
        end
    end
    rayParams.FilterDescendantsInstances = list
end

-- Lança 3 raios (centro + ombros). Retorna quanto dá pra andar e a
-- normal da parede mais próxima (nil se o caminho está livre).
local function castWall(origin, dir, dist)
    local side  = dir:Cross(UP)
    local reach = dist + WALL_PADDING
    local allowed, normal = dist, nil

    for i = 1, #RAY_OFFSETS do
        local from = origin + side * (RAY_OFFSETS[i] * RAY_SPREAD)
        local hit  = Workspace:Raycast(from, dir * reach, rayParams)
        if hit then
            local free = max(hit.Distance - WALL_PADDING, 0)
            if free < allowed then
                allowed, normal = free, hit.Normal
            end
        end
    end

    return allowed, normal
end

local function cframeStep(dt)
    if not State.CFrameSpeed then
        return
    end

    local hum, root = getRig()
    if not hum or not root or hum.Health <= 0 or hum.Sit or root.Anchored then
        return
    end

    local walk = hum.WalkSpeed
    if walk <= 0 then
        return -- personagem travado pelo jogo (stun, cutscene...)
    end

    local dir = hum.MoveDirection
    local mag = dir.Magnitude
    if mag < 0.01 then
        return
    end

    local extra = State.Speed - walk
    if extra <= 0 then
        return
    end

    local unit = dir / mag
    local dist = extra * min(dt, 0.1) * min(mag, 1)
    local step = unit * dist

    -- Wall Check: encurta o passo e desliza ao longo da parede
    if State.WallCheck then
        refreshRayFilter(Rig.Char)

        local origin = root.Position
        local allowed, normal = castWall(origin, unit, dist)
        step = unit * allowed

        if normal then
            local rest  = dist - allowed
            local slide = unit - normal * unit:Dot(normal)
            slide = Vector3.new(slide.X, 0, slide.Z)

            local slideMag = slide.Magnitude
            if slideMag > 0.05 and rest > 0.001 then
                local slideDir = slide / slideMag
                local slideOk  = castWall(origin + step, slideDir, rest * slideMag)
                step = step + slideDir * slideOk
            end
        end
    end

    if step.Magnitude > 0.001 then
        root.CFrame = root.CFrame + step
    end
end

connect(RunService.Heartbeat, function(dt)
    local ok, err = pcall(cframeStep, dt)
    if not ok then
        warnOnce("CFrame Speed", err)
    end
end)

--------------------------------------------------------------------
-- Player: Infinite Jump
--------------------------------------------------------------------
connect(UserInputService.JumpRequest, function()
    if not State.InfiniteJump then
        return
    end
    local hum = getRig()
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

--------------------------------------------------------------------
-- ESP (usa a Drawing API do executor)
--------------------------------------------------------------------
local HAS_DRAWING = type(Drawing) == "table" and type(Drawing.new) == "function"

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local GREEN = Color3.fromRGB(0, 255, 0)
local RED   = Color3.fromRGB(255, 0, 0)

-- Cada "slot" é um desenho. Só é criado quando o recurso está ligado.
-- O 3º valor (true) indica que o desenho usa a cor escolhida no ESP.
local SLOT_SPEC = {
    Name       = { "Text", { Size = 13, Font = 2, Center = true, Outline = true, Color = WHITE } },
    HealthBack = { "Line", { Thickness = 4, Color = BLACK } },
    Health     = { "Line", { Thickness = 2, Color = GREEN } },
    Tracer     = { "Line", { Thickness = 1 }, true },
}

local CORNER_SLOTS = {}
for i = 1, 8 do
    local slot = "Corner" .. i
    CORNER_SLOTS[i] = slot
    SLOT_SPEC[slot] = { "Line", { Thickness = 2 }, true }
end

local FEATURE_SLOTS = {
    Name   = { "Name" },
    Health = { "HealthBack", "Health" },
    Tracer = { "Tracer" },
    Box    = CORNER_SLOTS,
}

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for key, value in pairs(props) do
        pcall(function()
            d[key] = value
        end)
    end
    return d
end

local function killDrawing(d)
    pcall(function()
        if d.Remove then
            d:Remove()
        elseif d.Destroy then
            d:Destroy()
        end
    end)
end

local function createObject(plr)
    local obj = {
        D        = {}, -- desenhos já criados, por slot
        Vis      = {}, -- quais estão visíveis agora
        LastText = "",
        Char     = nil,
        Hum      = nil,
        Root     = nil,
        Head     = nil,
    }
    ESP.Objects[plr] = obj
    return obj
end

local function createDrawing(obj, slot)
    local spec = SLOT_SPEC[slot]
    local d = newDrawing(spec[1], spec[2])
    if spec[3] then
        pcall(function()
            d.Color = ESP.Color
        end)
    end
    obj.D[slot] = d
    return d
end

-- Liga/desliga um desenho. Retorna o desenho quando ligado (senão nil).
local function setVis(obj, slot, on)
    local d = obj.D[slot]
    if on then
        if not d then
            d = createDrawing(obj, slot)
        end
        if not obj.Vis[slot] then
            obj.Vis[slot] = true
            d.Visible = true
        end
        return d
    end
    if d and obj.Vis[slot] then
        obj.Vis[slot] = false
        d.Visible = false
    end
    return nil
end

local function hideObject(obj)
    for slot, shown in pairs(obj.Vis) do
        if shown then
            obj.Vis[slot] = false
            local d = obj.D[slot]
            if d then
                d.Visible = false
            end
        end
    end
end

local function freeSlot(obj, slot)
    local d = obj.D[slot]
    if d then
        obj.D[slot] = nil
        killDrawing(d)
    end
    obj.Vis[slot] = nil
    if slot == "Name" then
        obj.LastText = ""
    end
end

-- Quando um recurso é desligado, apaga os desenhos dele da memória
local function freeFeature(key)
    local slots = FEATURE_SLOTS[key]
    if not slots then
        return
    end
    for _, obj in pairs(ESP.Objects) do
        for _, slot in ipairs(slots) do
            freeSlot(obj, slot)
        end
    end
end

local function removeObject(plr)
    local obj = ESP.Objects[plr]
    if not obj then
        return
    end
    ESP.Objects[plr] = nil

    for _, d in pairs(obj.D) do
        killDrawing(d)
    end
    obj.D, obj.Vis = {}, {}
end

local function clearESP()
    for plr in pairs(ESP.Objects) do
        removeObject(plr)
    end
end

local function applyESPColor()
    for _, obj in pairs(ESP.Objects) do
        for slot, d in pairs(obj.D) do
            if SLOT_SPEC[slot][3] then
                pcall(function()
                    d.Color = ESP.Color
                end)
            end
        end
    end
end

local function v2(x, y)
    return Vector2.new(floor(x), floor(y))
end

local function setLine(line, x1, y1, x2, y2)
    line.From = v2(x1, y1)
    line.To   = v2(x2, y2)
end

-- Atualiza o cache de Humanoid / Root / Head do jogador
local function syncRig(obj, plr)
    local char = plr.Character
    if char ~= obj.Char then
        obj.Char, obj.Hum, obj.Root, obj.Head = char, nil, nil, nil
    end
    if not char then
        return false
    end
    if not obj.Hum or not obj.Hum.Parent then
        obj.Hum = char:FindFirstChildOfClass("Humanoid")
    end
    if not obj.Root or not obj.Root.Parent then
        obj.Root = char:FindFirstChild("HumanoidRootPart")
    end
    if not obj.Head or not obj.Head.Parent then
        obj.Head = char:FindFirstChild("Head")
    end
    return obj.Hum ~= nil and obj.Root ~= nil
end

local function updateObject(plr, obj, camera, origin, viewport)
    if not syncRig(obj, plr) then
        hideObject(obj)
        return
    end

    local hum, root, head = obj.Hum, obj.Root, obj.Head

    if hum.Health <= 0 then
        hideObject(obj)
        return
    end

    if ESP.TeamCheck and plr.Team ~= nil and plr.Team == LocalPlayer.Team then
        hideObject(obj)
        return
    end

    local rootPos = root.Position
    local dist = (origin - rootPos).Magnitude
    if dist > ESP.MaxDistance then
        hideObject(obj)
        return
    end

    -- Caixa 2D a partir do topo da cabeça e dos pés (serve para R6 e R15)
    local topWorld
    if head then
        topWorld = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0)
    else
        topWorld = rootPos + Vector3.new(0, 2.6, 0)
    end

    local feet
    if hum.RigType == Enum.HumanoidRigType.R6 then
        feet = 3
    else
        feet = max(hum.HipHeight + root.Size.Y / 2, 2.5)
    end
    local botWorld = rootPos - Vector3.new(0, feet + 0.1, 0)

    local top = camera:WorldToViewportPoint(topWorld)
    local bot = camera:WorldToViewportPoint(botWorld)

    -- Z <= 0: o jogador está atrás da câmera
    if top.Z <= 0 or bot.Z <= 0 then
        hideObject(obj)
        return
    end

    local topY    = min(top.Y, bot.Y)
    local botY    = max(top.Y, bot.Y)
    local height  = botY - topY
    local width   = height * 0.55
    local centerX = (top.X + bot.X) / 2
    local left    = centerX - width / 2
    local right   = centerX + width / 2

    -- Esp Name
    local nameD = setVis(obj, "Name", ESP.Name)
    if nameD then
        local label = plr.DisplayName
        if ESP.ShowDistance then
            label = label .. " [" .. floor(dist) .. "m]"
        end
        if obj.LastText ~= label then
            obj.LastText = label
            nameD.Text   = label
        end
        nameD.Position = v2(centerX, topY - 17)
    end

    -- Esp Health (barra vertical à esquerda da caixa)
    local back = setVis(obj, "HealthBack", ESP.Health)
    local bar  = setVis(obj, "Health", ESP.Health)
    if back and bar then
        local pct  = clamp(hum.Health / max(hum.MaxHealth, 1), 0, 1)
        local barX = left - 5
        setLine(back, barX, botY + 1, barX, topY - 1)
        setLine(bar, barX, botY, barX, botY - height * pct)
        bar.Color = RED:Lerp(GREEN, pct)
    end

    -- Esp Line Bottom (do centro inferior da tela até os pés do jogador)
    local tracer = setVis(obj, "Tracer", ESP.Tracer)
    if tracer then
        setLine(tracer, viewport.X / 2, viewport.Y, centerX, botY)
    end

    -- Esp Box Corner (apenas os cantos da caixa)
    local c = {}
    for i = 1, 8 do
        c[i] = setVis(obj, CORNER_SLOTS[i], ESP.Box)
    end
    if c[1] then
        local len = max(width * 0.3, 3)
        -- topo esquerdo
        setLine(c[1], left,  topY, left + len,  topY)
        setLine(c[2], left,  topY, left,        topY + len)
        -- topo direito
        setLine(c[3], right, topY, right - len, topY)
        setLine(c[4], right, topY, right,       topY + len)
        -- base esquerda
        setLine(c[5], left,  botY, left + len,  botY)
        setLine(c[6], left,  botY, left,        botY - len)
        -- base direita
        setLine(c[7], right, botY, right - len, botY)
        setLine(c[8], right, botY, right,       botY - len)
    end
end

local function renderESP()
    local anyOn = ESP.Name or ESP.Health or ESP.Tracer or ESP.Box

    -- Tudo desligado: remove os desenhos e não gasta nada
    if not anyOn then
        if ESP.Active then
            ESP.Active = false
            clearESP()
        end
        return
    end
    ESP.Active = true

    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local origin = camera.CFrame.Position
    local _, myRoot = getRig()
    if myRoot then
        origin = myRoot.Position
    end

    local viewport = camera.ViewportSize

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local obj = ESP.Objects[plr] or createObject(plr)
            updateObject(plr, obj, camera, origin, viewport)
        end
    end
end

if HAS_DRAWING then
    local espErrors = 0

    connect(RunService.RenderStepped, function()
        local ok, err = pcall(renderESP)
        if ok then
            espErrors = 0
            return
        end

        -- Rede de segurança: se falhar várias vezes seguidas, desliga o ESP
        espErrors = espErrors + 1
        warnOnce("ESP", err)
        if espErrors >= 10 then
            espErrors = 0
            ESP.Name, ESP.Health, ESP.Tracer, ESP.Box = false, false, false, false
            pcall(clearESP)
            notify("O ESP foi desativado por causa de um erro (veja o console).", "x", 5)
        end
    end)

    connect(Players.PlayerRemoving, removeObject)
end

local drawingWarned = false

local function setESP(key, state)
    state = state and true or false

    if state and not HAS_DRAWING then
        if not drawingWarned then
            drawingWarned = true
            notify("Seu executor não suporta a Drawing API (necessária para o ESP).", "info", 4)
        end
        return
    end

    ESP[key] = state
    if not state then
        freeFeature(key)
    end
end

--------------------------------------------------------------------
-- Unload (limpa tudo e fecha a janela)
--------------------------------------------------------------------
local function Cleanup()
    Ready              = false
    State.CFrameSpeed  = false
    State.InfiniteJump = false
    ESP.Name, ESP.Health, ESP.Tracer, ESP.Box = false, false, false, false

    for _, conn in ipairs(Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(Connections)

    clearESP()

    env.Buk_Unload = nil
end

local function Unload()
    if Unloaded then
        return
    end

    -- Salva antes de fechar (a janela ainda existe, então é seguro)
    if Config and Ready then
        pcall(function()
            Config:Save()
        end)
    end

    Unloaded = true
    Cleanup()
    pcall(function()
        Window:Destroy()
    end)
end

env.Buk_Unload = Unload

-- Se o usuário fechar a janela pelo botão X, também limpa tudo
pcall(function()
    Window:OnDestroy(function()
        if not Unloaded then
            Unloaded = true
            Cleanup()
        end
    end)
end)

local function confirmUnload()
    local ok = pcall(function()
        Window:Dialog({
            Title   = "Unload Script",
            Content = "Isso remove o Buk, desliga o ESP e fecha a janela. Deseja continuar?",
            Buttons = {
                {
                    Title    = "Cancelar",
                    Variant  = "Secondary",
                    Callback = function() end,
                },
                {
                    Title    = "Unload",
                    Variant  = "Primary",
                    Callback = function()
                        Unload()
                    end,
                },
            },
        })
    end)
    if not ok then
        Unload()
    end
end

--------------------------------------------------------------------
-- Interface
--------------------------------------------------------------------
local function newSection(tab, title, icon)
    return tab:Section({
        Title     = title,
        Icon      = icon,
        Box       = true,
        BoxBorder = true,
        Opened    = true,
    })
end

-- Aba 1: Main (vazia) ---------------------------------------------
Window:Tab({
    Title = "Main",
    Icon  = "house",
    CustomEmptyPage = {
        Icon     = "lucide:sparkles",
        IconSize = 48,
        Title    = "Nothing here yet",
        Desc     = "Buk by Nobody",
    },
})

-- Aba 2: Player ----------------------------------------------------
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon  = "user",
})

local SpeedSection = newSection(PlayerTab, "Speed", "gauge")

SpeedSection:Toggle({
    Title = "CFrame Speed",
    Desc  = "Move o personagem pelo CFrame para andar mais rápido",
    Flag  = "Player_CFrameSpeed",
    Value = false,
    Callback = function(state)
        State.CFrameSpeed = state
        queueSave()
    end,
})

SpeedSection:Slider({
    Title = "Speed",
    Desc  = "Velocidade total desejada (16 a 120)",
    Flag  = "Player_Speed",
    Step  = 1,
    Value = { Min = 16, Max = 120, Default = 50 },
    Callback = function(value)
        State.Speed = value
        queueSave()
    end,
})

SpeedSection:Toggle({
    Title = "Wall Check",
    Desc  = "Evita atravessar paredes com o CFrame Speed",
    Flag  = "Player_WallCheck",
    Value = true,
    Callback = function(state)
        State.WallCheck = state
        queueSave()
    end,
})

local JumpSection = newSection(PlayerTab, "Jump", "chevrons-up")

JumpSection:Toggle({
    Title = "Infinite Jump",
    Desc  = "Pule infinitamente no ar",
    Flag  = "Player_InfiniteJump",
    Value = false,
    Callback = function(state)
        State.InfiniteJump = state
        queueSave()
    end,
})

-- Aba 3: Esp -------------------------------------------------------
local EspTab = Window:Tab({
    Title = "Esp",
    Icon  = "eye",
})

local FeaturesSection = newSection(EspTab, "Features", "scan-eye")

FeaturesSection:Toggle({
    Title = "Esp Name",
    Desc  = "Mostra o nome dos jogadores",
    Flag  = "Esp_Name",
    Value = false,
    Callback = function(state)
        setESP("Name", state)
        queueSave()
    end,
})

FeaturesSection:Toggle({
    Title = "Esp Health",
    Desc  = "Mostra a barra de vida dos jogadores",
    Flag  = "Esp_Health",
    Value = false,
    Callback = function(state)
        setESP("Health", state)
        queueSave()
    end,
})

FeaturesSection:Toggle({
    Title = "Esp Line Bottom",
    Desc  = "Linha do centro inferior da tela até cada jogador",
    Flag  = "Esp_LineBottom",
    Value = false,
    Callback = function(state)
        setESP("Tracer", state)
        queueSave()
    end,
})

FeaturesSection:Toggle({
    Title = "Esp Box Corner",
    Desc  = "Caixa em cantos ao redor dos jogadores",
    Flag  = "Esp_BoxCorner",
    Value = false,
    Callback = function(state)
        setESP("Box", state)
        queueSave()
    end,
})

local OptionsSection = newSection(EspTab, "Options", "sliders-horizontal")

OptionsSection:Toggle({
    Title = "Team Check",
    Desc  = "Esconde os jogadores do seu time",
    Flag  = "Esp_TeamCheck",
    Value = false,
    Callback = function(state)
        ESP.TeamCheck = state
        queueSave()
    end,
})

OptionsSection:Toggle({
    Title = "Show Distance",
    Desc  = "Mostra a distância ao lado do nome",
    Flag  = "Esp_ShowDistance",
    Value = true,
    Callback = function(state)
        ESP.ShowDistance = state
        queueSave()
    end,
})

OptionsSection:Slider({
    Title = "Max Distance",
    Desc  = "Distância máxima para mostrar o ESP (studs)",
    Flag  = "Esp_MaxDistance",
    Step  = 50,
    Value = { Min = 100, Max = 5000, Default = 5000 },
    Callback = function(value)
        ESP.MaxDistance = value
        queueSave()
    end,
})

OptionsSection:Colorpicker({
    Title   = "Esp Color",
    Desc    = "Cor da caixa e da linha",
    Flag    = "Esp_Color",
    Default = Color3.fromRGB(255, 70, 70),
    Callback = function(color)
        ESP.Color = color
        applyESPColor()
        queueSave()
    end,
})

-- Aba 4: Settings --------------------------------------------------
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon  = "settings",
})

local AppearanceSection = newSection(SettingsTab, "Appearance", "palette")

AppearanceSection:Toggle({
    Title = "Darker Theme",
    Desc  = "Ativa o tema Darker (desligado volta para o Dark padrão)",
    Flag  = "Theme_Darker",
    Value = true,
    Callback = function(state)
        pcall(function()
            WindUI:SetTheme(state and "Darker" or "Dark")
        end)
        queueSave()
    end,
})

AppearanceSection:Toggle({
    Title = "Transparent",
    Desc  = "Deixa o fundo da janela semitransparente",
    Flag  = "Theme_Transparent",
    Value = true,
    Callback = function(state)
        pcall(function()
            Window:ToggleTransparency(state)
        end)
        queueSave()
    end,
})

local InterfaceSection = newSection(SettingsTab, "Interface", "keyboard")

local MenuKeybind = InterfaceSection:Keybind({
    Title = "Menu Key",
    Desc  = "Tecla para abrir e fechar a janela",
    Flag  = "UI_MenuKey",
    Value = "RightShift",
    Callback = function(key)
        applyMenuKey(key)
        queueSave()
    end,
})

local ConfigSection = newSection(SettingsTab, "Configuration", "save")

ConfigSection:Button({
    Title = "Save Settings",
    Desc  = "Salva todas as opções atuais (também salva sozinho)",
    Icon  = "save",
    Callback = function()
        if not Config then
            notify("Não foi possível salvar: seu executor não suporta writefile.", "x", 4)
            return
        end

        local ok, result = pcall(function()
            return Config:Save()
        end)

        if ok and result then
            notify("Configurações salvas com sucesso!", "check", 3)
        else
            notify("Falha ao salvar as configurações.", "x", 4)
        end
    end,
})

ConfigSection:Button({
    Title = "Unload Script",
    Desc  = "Remove o script, o ESP e fecha a janela",
    Icon  = "trash-2",
    Callback = function()
        confirmUnload()
    end,
})

--------------------------------------------------------------------
-- Config: registra os elementos com Flag e carrega o que foi salvo
-- (criado por último, depois que todos os elementos já existem)
--------------------------------------------------------------------
if Window.ConfigManager then
    local ok, cfg = pcall(function()
        return Window.ConfigManager:CreateConfig("Buk", true)
    end)

    if ok and cfg then
        Config = cfg
        pcall(function()
            Config:Load()
        end)
    end
end

-- A partir daqui, qualquer mudança dispara o auto-save
Ready = true

-- Garante que a tecla do menu salva seja aplicada
pcall(function()
    local key = MenuKeybind and MenuKeybind.Value
    if key ~= nil then
        applyMenuKey(key)
    end
end)

-- Abre direto na aba Player (a Main é vazia)
pcall(function()
    PlayerTab:Select()
end)

notify("Buk v" .. VERSION .. " carregado! Abra/feche o menu com a Menu Key (padrão: RightShift).", "check", 4)
