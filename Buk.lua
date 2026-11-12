--[[
    Buk
    Created by: Line
    UI Library: WindUI

    Abas: Main (Full Bright, FPS Boost, Grudar nas Costas, Radar, Anti-Void, Trocar de Servidor) | Player (CFrame Speed até 300) | Esp | Painel (Lock On, Auto Desvio) | Mod (Câmera) | Settings
    Tecla para abrir/fechar o menu: RightShift
]]

local env = (getgenv and getgenv()) or _G

-- Evita duplicar: se o script já estiver rodando, descarrega a versão anterior
if env.BukHub and type(env.BukHub.Unload) == "function" then
    pcall(env.BukHub.Unload)
end

----------------------------------------------------------------
-- Services
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

----------------------------------------------------------------
-- WindUI
----------------------------------------------------------------
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

----------------------------------------------------------------
-- Estado
----------------------------------------------------------------
local State = {
    CFrameSpeed = false,
    SpeedValue = 30,

    ESP = {
        Name = false,
        Health = false,
        BoxCorner = false,
        MaxDistance = 2000,
        Color = Color3.fromRGB(255, 255, 255), -- branco (padrão)
    },
}

local Connections = {}
local Window -- definido mais abaixo
local Config -- definido mais abaixo

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

local lastNotify = {}

-- Aviso na tela, no máximo 1 a cada 2s por tipo (não enche a tela de notificação).
-- Fica aqui em cima porque várias partes do script usam.
local function notifyOnce(key, title, content)
    local now = os.clock()
    if lastNotify[key] and now - lastNotify[key] < 2 then
        return
    end
    lastNotify[key] = now
    WindUI:Notify({ Title = title, Content = content, Duration = 2 })
end

local function destroyGui(gui)
    if gui then
        pcall(function()
            gui:Destroy()
        end)
    end
end

----------------------------------------------------------------
-- ESP (Drawing API): Name, Health e Box Corner
----------------------------------------------------------------
local DrawingSupported = false
do
    local ok, obj = pcall(function()
        return Drawing.new("Line")
    end)
    if ok and obj then
        DrawingSupported = true
        pcall(function()
            obj:Remove()
        end)
    end
end

local ESPObjects = {}

local function newDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function setLine(line, ax, ay, bx, by, color)
    line.From = Vector2.new(ax, ay)
    line.To = Vector2.new(bx, by)
    line.Color = color
    line.Visible = true
end

local function createESP(plr)
    if not DrawingSupported or plr == LocalPlayer then
        return nil
    end
    if ESPObjects[plr] then
        return ESPObjects[plr]
    end

    local obj = {
        Name = newDrawing("Text", { Size = 14, Center = true, Outline = true, Visible = false }),
        Health = newDrawing("Text", { Size = 13, Center = true, Outline = true, Visible = false }),
        Corners = {},
    }
    for i = 1, 8 do
        obj.Corners[i] = newDrawing("Line", { Thickness = 1.5, Visible = false })
    end

    ESPObjects[plr] = obj
    return obj
end

local function hideESP(obj)
    obj.Name.Visible = false
    obj.Health.Visible = false
    for _, l in ipairs(obj.Corners) do
        l.Visible = false
    end
end

local function removeESP(plr)
    local obj = ESPObjects[plr]
    if not obj then
        return
    end
    ESPObjects[plr] = nil

    local function rm(d)
        pcall(function()
            d:Remove()
        end)
    end
    rm(obj.Name)
    rm(obj.Health)
    for _, l in ipairs(obj.Corners) do
        rm(l)
    end
end

local function updateESP(plr, obj, cfg)
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")

    if not (hum and root and head) or hum.Health <= 0 then
        return hideESP(obj)
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local origin = myRoot and myRoot.Position or Camera.CFrame.Position
    if (origin - root.Position).Magnitude > cfg.MaxDistance then
        return hideESP(obj)
    end

    local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
    if not onScreen then
        return hideESP(obj)
    end

    -- Caixa baseada na cabeça e nos pés
    local topV = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y / 2 + 0.2, 0))
    local botV = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

    local height = math.abs(botV.Y - topV.Y)
    local width = height * 0.6
    local cx = rootPos.X
    local x1, x2 = cx - width / 2, cx + width / 2
    local y1, y2 = topV.Y, botV.Y
    local color = cfg.Color

    -- 1. Esp Name
    if cfg.Name then
        obj.Name.Text = plr.DisplayName
        obj.Name.Position = Vector2.new(cx, y1 - 18)
        obj.Name.Color = color
        obj.Name.Visible = true
    else
        obj.Name.Visible = false
    end

    -- 2. Esp Health (vida atual / vida máxima)
    if cfg.Health then
        local maxHp = math.max(hum.MaxHealth, 1)
        local ratio = math.clamp(hum.Health / maxHp, 0, 1)
        obj.Health.Text = string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
        obj.Health.Position = Vector2.new(cx, y2 + 2)
        obj.Health.Color = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(70, 255, 110), ratio)
        obj.Health.Visible = true
    else
        obj.Health.Visible = false
    end

    -- 3. Esp Box Corner
    if cfg.BoxCorner then
        local l = math.max(4, math.min(width, height) * 0.28)
        local c = obj.Corners
        -- topo esquerdo
        setLine(c[1], x1, y1, x1 + l, y1, color)
        setLine(c[2], x1, y1, x1, y1 + l, color)
        -- topo direito
        setLine(c[3], x2, y1, x2 - l, y1, color)
        setLine(c[4], x2, y1, x2, y1 + l, color)
        -- base esquerda
        setLine(c[5], x1, y2, x1 + l, y2, color)
        setLine(c[6], x1, y2, x1, y2 - l, color)
        -- base direita
        setLine(c[7], x2, y2, x2 - l, y2, color)
        setLine(c[8], x2, y2, x2, y2 - l, color)
    else
        for _, line in ipairs(obj.Corners) do
            line.Visible = false
        end
    end
end

connect(RunService.RenderStepped, function()
    Camera = Workspace.CurrentCamera
    if not Camera then
        return
    end

    local cfg = State.ESP
    local anyOn = cfg.Name or cfg.Health or cfg.BoxCorner

    if anyOn then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local obj = ESPObjects[plr] or createESP(plr)
                if obj then
                    pcall(updateESP, plr, obj, cfg)
                end
            end
        end
    else
        for _, obj in pairs(ESPObjects) do
            hideESP(obj)
        end
    end
end)

connect(Players.PlayerRemoving, removeESP)

----------------------------------------------------------------
-- Player (CFrame)
----------------------------------------------------------------
connect(RunService.Heartbeat, function(dt)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local cam = Workspace.CurrentCamera
    if not (hum and root and cam) or hum.Health <= 0 then
        return
    end

    if State.CFrameSpeed then
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame += hum.MoveDirection * (State.SpeedValue * dt)
        end
    end
end)

----------------------------------------------------------------
-- Lock On (botão flutuante)
----------------------------------------------------------------
local LockOn = {
    Enabled = false, -- toggle da aba Painel (mostra o botão flutuante)
    Active = false, -- lock ativo (botão apertado)
    Target = nil, -- Player travado
    ButtonLocked = false, -- impede arrastar o botão
    PartName = "HumanoidRootPart",
    MaxDistance = 300,
    AutoSwitch = false, -- quando o alvo morre/sai/fica longe, pula sozinho pro próximo mais perto
}

local LockGui, LockButton
local BUTTON_SIZE = 64
local DRAG_THRESHOLD = 8 -- pixels que o dedo precisa mover para contar como arraste

local function getTargetPart(plr)
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        return nil
    end
    return char:FindFirstChild(LockOn.PartName) or char:FindFirstChild("HumanoidRootPart")
end

local function getOrigin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Position
    end
    local cam = Workspace.CurrentCamera
    return cam and cam.CFrame.Position or Vector3.zero
end

-- Humanoid e HumanoidRootPart do player, só se ele estiver vivo (senão devolve nil, nil)
local function getAlive(plr)
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then
        return hum, root
    end
    return nil, nil
end

local function findNearestTarget()
    local origin = getOrigin()
    local best, bestDist = nil, LockOn.MaxDistance
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local part = getTargetPart(plr)
            if part then
                local d = (part.Position - origin).Magnitude
                if d <= bestDist then
                    best, bestDist = plr, d
                end
            end
        end
    end
    return best
end

local function refreshLockButton()
    if not LockButton then
        return
    end
    local stroke = LockButton:FindFirstChildOfClass("UIStroke")
    if LockOn.Active then
        LockButton.Text = "LOCK\nON"
        LockButton.BackgroundColor3 = Color3.fromRGB(24, 60, 38)
        if stroke then
            stroke.Color = Color3.fromRGB(70, 255, 110)
        end
    else
        LockButton.Text = "LOCK\nOFF"
        LockButton.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
        if stroke then
            stroke.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function setLockActive(active)
    if active then
        local target = findNearestTarget()
        if target then
            LockOn.Target = target
            LockOn.Active = true
        else
            LockOn.Target = nil
            LockOn.Active = false
            WindUI:Notify({
                Title = "Lock On",
                Content = "Nenhum player por perto.",
                Duration = 2,
            })
        end
    else
        LockOn.Target = nil
        LockOn.Active = false
    end
    refreshLockButton()
end

-- Coloca uma ScreenGui na tela: gethui/CoreGui (se o executor permitir), senão PlayerGui
local function mountGui(gui)
    local ok = pcall(function()
        gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Deixa um objeto arrastável (toque ou mouse). Só um toque (sem arrastar) = onClick, se tiver.
-- Com "Travar Botão" ligado nada arrasta e todo toque conta como clique.
local function makeDraggable(gui, obj, onClick)
    local pressInput, dragStart, startPos, moved

    obj.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
            return
        end
        if pressInput then
            return
        end

        pressInput = input
        dragStart = input.Position
        startPos = obj.Position
        moved = false

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then
                return
            end
            conn:Disconnect()
            if pressInput ~= input then
                return
            end
            pressInput = nil
            if onClick and (LockOn.ButtonLocked or not moved) then
                onClick()
            end
        end)
    end)

    connect(UserInputService.InputChanged, function(input)
        if not pressInput then
            return
        end
        local t = input.UserInputType
        local isMove = t == Enum.UserInputType.MouseMovement
            or (t == Enum.UserInputType.Touch and input == pressInput)
        if not isMove then
            return
        end

        local delta = input.Position - dragStart
        if delta.Magnitude >= DRAG_THRESHOLD then
            moved = true
        end

        if moved and not LockOn.ButtonLocked then
            local size = gui.AbsoluteSize
            local objSize = obj.AbsoluteSize
            local x = math.clamp(startPos.X.Offset + delta.X, 0, math.max(size.X - objSize.X, 0))
            local y = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(size.Y - objSize.Y, 0))
            obj.Position = UDim2.fromOffset(x, y)
        end
    end)
end

-- Cria um botão redondo flutuante e arrastável.
-- Toque = onClick | Arrastar = move o botão (a menos que "Travar Botão" esteja ligado)
local function createFloatingButton(name, text, posX, posY, onClick)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local btn = Instance.new("TextButton")
    btn.Name = name .. "Button"
    btn.Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
    btn.Position = UDim2.fromOffset(posX, posY)
    btn.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    btn.BackgroundTransparency = 0.15
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn

    mountGui(gui)
    makeDraggable(gui, btn, onClick)

    return gui, btn
end

local function createLockGui()
    if LockGui then
        return
    end
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(800, 600)

    LockGui, LockButton = createFloatingButton(
        "BukLockOn",
        "LOCK\nOFF",
        math.max(vp.X - BUTTON_SIZE - 240, 0),
        math.max(vp.Y * 0.5 - BUTTON_SIZE / 2, 0),
        function()
            setLockActive(not LockOn.Active)
        end
    )
    refreshLockButton()
end

local function setLockEnabled(state)
    LockOn.Enabled = state
    if state then
        createLockGui()
        if LockGui then
            LockGui.Enabled = true
        end
    else
        setLockActive(false)
        if LockGui then
            LockGui.Enabled = false
        end
    end
end

-- Roda depois do script de câmera do Roblox para a trava valer
pcall(function()
    RunService:UnbindFromRenderStep("BukLockOn")
end)
RunService:BindToRenderStep("BukLockOn", Enum.RenderPriority.Camera.Value + 1, function()
    if not (LockOn.Enabled and LockOn.Active) then
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end
    local target = LockOn.Target
    local part = target and getTargetPart(target)

    if not part or (part.Position - getOrigin()).Magnitude > LockOn.MaxDistance then
        -- alvo morreu, saiu ou ficou longe demais.
        -- findNearestTarget já ignora morto/longe, então nunca devolve o alvo que acabou de cair.
        local nextTarget = LockOn.AutoSwitch and findNearestTarget() or nil
        if not nextTarget then
            if LockOn.AutoSwitch then
                notifyOnce("lockLost", "Lock On", "Sem mais alvos por perto. Lock desligado.")
            end
            setLockActive(false)
            return
        end
        LockOn.Target = nextTarget
        part = getTargetPart(nextTarget)
    end

    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, part.Position)
end)

----------------------------------------------------------------
-- Grudar nas Costas (escolhe o player no menu + botão flutuante)
----------------------------------------------------------------
local Stick = {
    Enabled = false, -- mostra o botão flutuante
    Active = false, -- grudado agora (botão apertado)
    Waiting = false, -- true enquanto o alvo está morto: espera ele voltar pra grudar de novo
    Target = nil, -- Player escolhido no menu
    Distance = 3, -- quantos studs atrás do alvo você fica
    Options = {}, -- texto do dropdown -> Player
    LastBehind = nil, -- última direção "atrás" válida (se o alvo cair/ragdoll não vira de lado)
    Orbit = false, -- gira em volta do alvo em vez de ficar só atrás
    OrbitSpeed = 90, -- graus por segundo (slider no menu)
    OrbitDir = nil, -- direção atual da órbita (o script mexe sozinho)
}

local StickGui, StickButton
local StickDropdown -- criado lá embaixo, na aba Main
local STICK_NONE = "Nenhum"
local FLAT = Vector3.new(1, 0, 1)

local stickParams = RaycastParams.new()
stickParams.FilterType = Enum.RaycastFilterType.Exclude
stickParams.RespectCanCollide = true
local stickFilterMe, stickFilterThem

local function stickLabel(plr)
    return plr.DisplayName .. " (@" .. plr.Name .. ")"
end

-- Texto de cada opção do dropdown (menos você e quem está saindo), em ordem alfabética
local function buildStickOptions(leaving)
    local plrs = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr ~= leaving then
            table.insert(plrs, plr)
        end
    end
    table.sort(plrs, function(a, b)
        return stickLabel(a):lower() < stickLabel(b):lower()
    end)

    local labels = { STICK_NONE }
    table.clear(Stick.Options)
    for _, plr in ipairs(plrs) do
        local label = stickLabel(plr)
        Stick.Options[label] = plr
        table.insert(labels, label)
    end
    return labels
end

local function refreshStickButton()
    if not StickButton then
        return
    end
    local stroke = StickButton:FindFirstChildOfClass("UIStroke")
    if Stick.Active then
        StickButton.Text = "GRUDAR\nON"
        StickButton.BackgroundColor3 = Color3.fromRGB(24, 60, 38)
        if stroke then
            stroke.Color = Color3.fromRGB(70, 255, 110)
        end
    else
        StickButton.Text = "GRUDAR\nOFF"
        StickButton.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
        if stroke then
            stroke.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function setStickActive(active)
    Stick.Waiting = false
    Stick.OrbitDir = nil
    if active then
        local target = Stick.Target
        if not target then
            Stick.Active = false
            notifyOnce("stick", "Grudar nas Costas", "Escolha um player na aba Main primeiro.")
        elseif not getAlive(target) then
            Stick.Active = false
            notifyOnce("stick", "Grudar nas Costas", "Esse player não está vivo agora.")
        else
            Stick.Active = true
        end
    else
        Stick.Active = false
    end
    refreshStickButton()
end

-- Chamado quando você escolhe alguém no dropdown. Se já estava grudado, passa a grudar no novo.
local function selectStickTarget(label)
    local plr = Stick.Options[label]
    Stick.Target = plr
    Stick.Waiting = false
    Stick.OrbitDir = nil
    if not plr then
        setStickActive(false)
    end
end

-- Atualiza a lista do dropdown (alguém entrou ou saiu). `leaving` = quem está saindo agora.
local function refreshStickList(leaving)
    if leaving and Stick.Target == leaving then
        Stick.Target = nil
        setStickActive(false)
        notifyOnce("stickLeft", "Grudar nas Costas", leaving.DisplayName .. " saiu do jogo.")
    end

    local labels = buildStickOptions(leaving)
    if not StickDropdown then
        return
    end

    local current = Stick.Target and stickLabel(Stick.Target) or STICK_NONE
    pcall(function()
        StickDropdown:Refresh(labels)
    end)
    pcall(function()
        StickDropdown:Select(current)
    end)
end

connect(Players.PlayerAdded, function()
    refreshStickList()
end)
connect(Players.PlayerRemoving, refreshStickList)

local function createStickGui()
    if StickGui then
        return
    end
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(800, 600)

    -- Fica logo abaixo do botão do Lock On
    StickGui, StickButton = createFloatingButton(
        "BukStick",
        "GRUDAR\nOFF",
        math.max(vp.X - BUTTON_SIZE - 240, 0),
        math.clamp(vp.Y * 0.5 + BUTTON_SIZE / 2 + 16, 0, math.max(vp.Y - BUTTON_SIZE, 0)),
        function()
            setStickActive(not Stick.Active)
        end
    )
    StickButton.TextSize = 11
    refreshStickButton()
end

local function setStickEnabled(state)
    Stick.Enabled = state
    if state then
        createStickGui()
    else
        setStickActive(false)
    end
    if StickGui then
        StickGui.Enabled = state
    end
end

-- Todo frame: fica atrás do alvo (ou orbitando), olhando pra ele, e acompanha ele pra onde for
connect(RunService.Heartbeat, function(dt)
    if not (Stick.Enabled and Stick.Active) then
        return
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) or hum.Health <= 0 then
        return
    end

    local target = Stick.Target
    local tRoot
    if target then
        local _, r = getAlive(target)
        tRoot = r
    end

    if not tRoot then
        -- alvo morto (ou renascendo): continua ligado e gruda de novo quando ele voltar
        if not Stick.Waiting then
            Stick.Waiting = true
            notifyOnce("stickWait", "Grudar nas Costas", "O alvo morreu. Eu grudo de novo quando ele voltar.")
        end
        return
    end
    Stick.Waiting = false

    -- "Atrás" = o lado contrário de pra onde o alvo está olhando (só no plano horizontal)
    local look = tRoot.CFrame.LookVector * FLAT
    local behind
    if look.Magnitude >= 0.05 then
        behind = -look.Unit
        Stick.LastBehind = behind
    else
        behind = Stick.LastBehind or Vector3.zAxis
    end

    -- Órbita: a direção gira aos poucos em volta do alvo (só com o toggle "Orbitar" ligado)
    if Stick.Orbit then
        Stick.OrbitDir = CFrame.Angles(0, math.rad(Stick.OrbitSpeed) * dt, 0) * (Stick.OrbitDir or behind)
        behind = Stick.OrbitDir
    end

    -- Parede atrás do alvo: fica mais perto dele em vez de entrar na parede
    if stickFilterMe ~= char or stickFilterThem ~= target.Character then
        stickFilterMe, stickFilterThem = char, target.Character
        stickParams.FilterDescendantsInstances = { char, target.Character }
    end
    local dist = Stick.Distance
    local hit = Workspace:Raycast(tRoot.Position, behind * (dist + 1.5), stickParams)
    if hit then
        dist = math.max(hit.Distance - 1.5, 1.5)
    end

    local pos = tRoot.Position + behind * dist
    root.CFrame = CFrame.lookAt(pos, Vector3.new(tRoot.Position.X, pos.Y, tRoot.Position.Z))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end)

----------------------------------------------------------------
-- Combate: Auto Desvio
----------------------------------------------------------------
local Combat = {
    FaceTarget = false,

    -- Auto Desvio: quando qualquer player chega perto, dá um passo pro lado
    Dodge = {
        Enabled = false,
        Range = 15,
        StepDistance = 10,
        Cooldown = 0.2,
        Last = 0,
        Busy = false, -- true enquanto o passo acontece (não empilha um desvio em cima do outro)
    },
}

-- Player vivo mais perto de você dentro da distância de detecção (ou nil)
local function findThreat(myRoot)
    local D = Combat.Dodge
    local best, bestDist = nil, D.Range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local hum, root = getAlive(plr)
            if hum and root then
                local d = (myRoot.Position - root.Position).Magnitude
                if d <= bestDist then
                    best, bestDist = root, d
                end
            end
        end
    end
    return best
end

-- Tem chão logo embaixo desse ponto? (pra não mandar o personagem pra fora do mapa)
local function hasGroundBelow(pos, params, depth)
    return Workspace:Raycast(pos, Vector3.new(0, -(depth or 60), 0), params) ~= nil
end

-- Escolhe um lado livre (sem parede e com chão) para desviar
local function pickDodgeDirection(myRoot, threatRoot, distance)
    local away = (myRoot.Position - threatRoot.Position) * Vector3.new(1, 0, 1)
    if away.Magnitude < 0.1 then
        away = myRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
    end
    if away.Magnitude < 0.1 then
        away = Vector3.zAxis
    end
    away = away.Unit

    local side = away:Cross(Vector3.yAxis)
    if math.random() < 0.5 then
        side = -side
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }

    for _, dir in ipairs({ side, -side, away }) do
        local hit = Workspace:Raycast(myRoot.Position, dir * (distance + 2), params)
        if not hit and hasGroundBelow(myRoot.Position + dir * distance, params, 60) then
            return dir
        end
    end
    return nil
end

local function performDodge(myRoot, threatRoot)
    local D = Combat.Dodge
    if D.Busy then
        return
    end

    local dir = pickDodgeDirection(myRoot, threatRoot, D.StepDistance)
    if not dir then
        return
    end

    -- Desliza rápido (6 frames) em vez de teleportar de uma vez
    D.Busy = true
    task.spawn(function()
        local steps = 6
        for _ = 1, steps do
            if not myRoot.Parent then
                break
            end
            myRoot.CFrame += dir * (D.StepDistance / steps)
            task.wait()
        end
        D.Busy = false
    end)
end

connect(RunService.Heartbeat, function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) or hum.Health <= 0 then
        return
    end

    local now = os.clock()

    -- Grudado nas costas de alguém: o Grudar manda na posição e na direção do personagem,
    -- então o Virar pro Alvo e o Auto Desvio ficam quietos enquanto isso.
    local sticking = Stick.Enabled and Stick.Active and not Stick.Waiting

    -- Virar pro alvo do Lock On
    if not sticking and Combat.FaceTarget and LockOn.Enabled and LockOn.Active and LockOn.Target then
        local part = getTargetPart(LockOn.Target)
        if part then
            local p = part.Position
            local flat = Vector3.new(p.X, root.Position.Y, p.Z)
            if (flat - root.Position).Magnitude > 0.5 then
                root.CFrame = CFrame.lookAt(root.Position, flat)
            end
        end
    end

    -- Auto Desvio
    local D = Combat.Dodge
    if D.Enabled and not sticking and not D.Busy and now - D.Last >= D.Cooldown then
        local threat = findThreat(root)
        if threat then
            D.Last = now
            performDodge(root, threat)
        end
    end
end)

----------------------------------------------------------------
-- Main: Full Bright + FPS Boost
----------------------------------------------------------------
local Bright = {
    Enabled = false,
    Original = nil, -- valores originais da iluminação
    Atmos = setmetatable({}, { __mode = "k" }), -- Atmosphere -> valores originais
}

-- Chamada a cada frame (no BindToRenderStep da câmera), então o jogo não desfaz
local function applyBright()
    if not Bright.Enabled then
        return
    end

    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
    Lighting.Ambient = Color3.fromRGB(190, 190, 190)
    Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)

    -- FindFirstChildOfClass não cria tabela nova a cada frame (GetChildren criava: pesa no celular)
    local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmos then
        if Bright.Atmos[atmos] == nil then
            Bright.Atmos[atmos] = { Density = atmos.Density, Haze = atmos.Haze, Offset = atmos.Offset }
        end
        atmos.Density = 0
        atmos.Haze = 0
    end
end

local function setBrightEnabled(state)
    if state then
        if Bright.Original == nil then
            Bright.Original = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogStart = Lighting.FogStart,
                FogEnd = Lighting.FogEnd,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
        Bright.Enabled = true
        applyBright()
    else
        Bright.Enabled = false
        if Bright.Original then
            for prop, value in pairs(Bright.Original) do
                pcall(function()
                    Lighting[prop] = value
                end)
            end
        end
        Bright.Original = nil
        for atmos, old in pairs(Bright.Atmos) do
            if atmos.Parent then
                pcall(function()
                    atmos.Density = old.Density
                    atmos.Haze = old.Haze
                    atmos.Offset = old.Offset
                end)
            end
        end
        table.clear(Bright.Atmos)
    end
end

local Perf = {
    Enabled = false,
    OrigShadows = nil,
    OrigQuality = nil,
    Disabled = setmetatable({}, { __mode = "k" }), -- efeitos que o script desligou
    Conns = {},
}

local function disableEffect(inst)
    if
        (
            inst:IsA("ParticleEmitter")
            or inst:IsA("Trail")
            or inst:IsA("Beam")
            or inst:IsA("Smoke")
            or inst:IsA("Fire")
            or inst:IsA("Sparkles")
            or inst:IsA("PostEffect")
        ) and inst.Enabled
    then
        Perf.Disabled[inst] = true
        inst.Enabled = false
    end
end

local function setPerfEnabled(state)
    if state then
        if Perf.Enabled then
            return
        end
        Perf.Enabled = true

        Perf.OrigShadows = Lighting.GlobalShadows
        Lighting.GlobalShadows = false
        pcall(function()
            Perf.OrigQuality = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        -- Efeitos novos (skills, golpes) também são desligados
        local function onAdded(inst)
            pcall(disableEffect, inst)
        end
        table.insert(Perf.Conns, Workspace.DescendantAdded:Connect(onAdded))
        table.insert(Perf.Conns, Lighting.DescendantAdded:Connect(onAdded))

        -- Efeitos que já existem (varre aos poucos pra não travar)
        task.spawn(function()
            local n = 0
            for _, container in ipairs({ Workspace, Lighting }) do
                for _, inst in ipairs(container:GetDescendants()) do
                    if not Perf.Enabled then
                        return
                    end
                    pcall(disableEffect, inst)
                    n += 1
                    if n % 400 == 0 then
                        task.wait()
                    end
                end
            end
        end)
    else
        Perf.Enabled = false

        for _, c in ipairs(Perf.Conns) do
            pcall(function()
                c:Disconnect()
            end)
        end
        table.clear(Perf.Conns)

        for inst in pairs(Perf.Disabled) do
            if inst.Parent then
                pcall(function()
                    inst.Enabled = true
                end)
            end
        end
        table.clear(Perf.Disabled)

        if Perf.OrigShadows ~= nil then
            Lighting.GlobalShadows = Perf.OrigShadows
        end
        if Perf.OrigQuality ~= nil then
            pcall(function()
                settings().Rendering.QualityLevel = Perf.OrigQuality
            end)
        end
        Perf.OrigShadows, Perf.OrigQuality = nil, nil
    end
end

----------------------------------------------------------------
-- Main: Radar e Anti-Void
----------------------------------------------------------------
----- Radar -----
local Radar = {
    Enabled = false,
    Range = 150, -- alcance em studs (a borda do círculo)
    Size = 150, -- tamanho do círculo em pixels
    Dots = {}, -- Player -> bolinha
}

local RadarGui, RadarFrame
local DOT_SIZE = 7

local function createRadarGui()
    if RadarGui then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BukRadar"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 997
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- O fundo é um TextButton só pra receber o toque de arrastar
    local frame = Instance.new("TextButton")
    frame.Name = "Radar"
    frame.AutoButtonColor = false
    frame.Text = ""
    frame.BorderSizePixel = 0
    frame.Size = UDim2.fromOffset(Radar.Size, Radar.Size)
    frame.Position = UDim2.fromOffset(12, 70)
    frame.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    frame.BackgroundTransparency = 0.35
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.3
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    -- Círculo do meio (metade do alcance)
    local ring = Instance.new("Frame")
    ring.Name = "Ring"
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.Size = UDim2.fromScale(0.5, 0.5)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Parent = frame
    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = ring
    local ringStroke = Instance.new("UIStroke")
    ringStroke.Thickness = 1
    ringStroke.Color = Color3.fromRGB(255, 255, 255)
    ringStroke.Transparency = 0.8
    ringStroke.Parent = ring

    -- Cruz no centro
    local function addLine(name, size)
        local line = Instance.new("Frame")
        line.Name = name
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.fromScale(0.5, 0.5)
        line.Size = size
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.BackgroundTransparency = 0.85
        line.BorderSizePixel = 0
        line.Parent = frame
    end
    addLine("LineH", UDim2.new(1, -12, 0, 1))
    addLine("LineV", UDim2.new(0, 1, 1, -12))

    -- Você (centro) e a seta que mostra "pra frente" (a câmera sempre aponta pra cima)
    local me = Instance.new("Frame")
    me.Name = "Me"
    me.AnchorPoint = Vector2.new(0.5, 0.5)
    me.Position = UDim2.fromScale(0.5, 0.5)
    me.Size = UDim2.fromOffset(8, 8)
    me.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    me.BorderSizePixel = 0
    me.ZIndex = 3
    me.Parent = frame
    local meCorner = Instance.new("UICorner")
    meCorner.CornerRadius = UDim.new(1, 0)
    meCorner.Parent = me

    local north = Instance.new("TextLabel")
    north.Name = "Front"
    north.AnchorPoint = Vector2.new(0.5, 0)
    north.Position = UDim2.new(0.5, 0, 0, 3)
    north.Size = UDim2.fromOffset(12, 10)
    north.BackgroundTransparency = 1
    north.BorderSizePixel = 0
    north.Font = Enum.Font.GothamBold
    north.TextSize = 9
    north.Text = "▲"
    north.TextColor3 = Color3.fromRGB(255, 255, 255)
    north.TextTransparency = 0.35
    north.ZIndex = 3
    north.Parent = frame

    mountGui(gui)
    makeDraggable(gui, frame, nil)

    RadarGui, RadarFrame = gui, frame
end

local function getDot(plr)
    local dot = Radar.Dots[plr]
    if dot and dot.Parent then
        return dot
    end
    if not RadarFrame then
        return nil
    end

    dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
    dot.BorderSizePixel = 0
    dot.ZIndex = 2
    dot.Visible = false
    dot.Parent = RadarFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot

    Radar.Dots[plr] = dot
    return dot
end

local function removeDot(plr)
    local dot = Radar.Dots[plr]
    Radar.Dots[plr] = nil
    destroyGui(dot)
end

local function setRadarEnabled(state)
    Radar.Enabled = state
    if state then
        createRadarGui()
    end
    if RadarGui then
        RadarGui.Enabled = state
    end
end

local function setRadarSize(size)
    Radar.Size = size
    if RadarFrame then
        RadarFrame.Size = UDim2.fromOffset(size, size)
    end
end

connect(Players.PlayerRemoving, removeDot)

-- Cada frame: pega a direção da câmera e põe cada player no círculo (frente = pra cima)
connect(RunService.RenderStepped, function()
    if not (Radar.Enabled and RadarFrame) then
        return
    end
    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    local look = cam.CFrame.LookVector
    local forward = Vector3.new(look.X, 0, look.Z)
    if forward.Magnitude < 0.05 then
        -- câmera olhando reto pra cima/baixo: usa a direção "de cima" dela
        local up = cam.CFrame.UpVector
        forward = Vector3.new(up.X, 0, up.Z)
    end
    if forward.Magnitude < 0.01 then
        forward = Vector3.new(0, 0, -1)
    end
    forward = forward.Unit
    local right = forward:Cross(Vector3.yAxis)

    local origin = getOrigin()
    local radius = RadarFrame.AbsoluteSize.X / 2 - DOT_SIZE
    local color = State.ESP.Color

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local _, root = getAlive(plr)
            if root then
                local dot = getDot(plr)
                if dot then
                    local offset = root.Position - origin
                    local dx = offset:Dot(right)
                    local dz = offset:Dot(forward)
                    local dist = math.sqrt(dx * dx + dz * dz)

                    local x, y = 0, 0
                    if dist > 0.01 then
                        -- passou do alcance: fica grudado na borda (mostra a direção)
                        local k = (math.min(dist, Radar.Range) / Radar.Range) * radius / dist
                        x, y = dx * k, -dz * k
                    end

                    local isTarget = LockOn.Active and LockOn.Target == plr
                    local size = isTarget and DOT_SIZE + 3 or DOT_SIZE
                    dot.Position = UDim2.new(0.5, x, 0.5, y)
                    dot.Size = UDim2.fromOffset(size, size)
                    dot.BackgroundColor3 = isTarget and Color3.fromRGB(255, 60, 60) or color
                    dot.BackgroundTransparency = dist > Radar.Range and 0.55 or 0
                    dot.Visible = true
                end
            else
                local dot = Radar.Dots[plr]
                if dot then
                    dot.Visible = false
                end
            end
        end
    end
end)

----- Anti-Void -----
local AntiVoid = {
    Enabled = false,
    FallDistance = 80, -- queda (em studs) sem chão embaixo antes de te devolver
    LastSafe = nil, -- CFrame do último lugar onde você estava pisando em chão
    Char = nil,
    LastCheck = 0,
    LastRescue = 0,
}

local voidParams = RaycastParams.new()
voidParams.FilterType = Enum.RaycastFilterType.Exclude

connect(RunService.Heartbeat, function()
    if not AntiVoid.Enabled then
        return
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) or hum.Health <= 0 then
        return
    end

    -- Personagem novo (respawn): esquece o chão da vida anterior
    if AntiVoid.Char ~= char then
        AntiVoid.Char = char
        AntiVoid.LastSafe = nil
    end

    -- Confere 10 vezes por segundo (mais que isso não precisa)
    local now = os.clock()
    if now - AntiVoid.LastCheck < 0.1 then
        return
    end
    AntiVoid.LastCheck = now

    -- Pisando em chão: guarda esse lugar como seguro
    if hum.FloorMaterial ~= Enum.Material.Air then
        AntiVoid.LastSafe = root.CFrame
        return
    end

    local safe = AntiVoid.LastSafe
    if not safe then
        return
    end

    local pos = root.Position
    -- Perto da altura em que o Roblox destrói quem cai do mapa: volta na hora
    local belowMap = pos.Y < Workspace.FallenPartsDestroyHeight + 40
    if not belowMap then
        if safe.Position.Y - pos.Y < AntiVoid.FallDistance then
            return -- ainda não caiu o bastante
        end
        -- Tem chão lá embaixo? Então não é vazio, é só uma queda grande: deixa cair
        voidParams.FilterDescendantsInstances = { char }
        if Workspace:Raycast(pos, Vector3.new(0, -2000, 0), voidParams) then
            return
        end
    end

    if now - AntiVoid.LastRescue < 1 then
        return
    end
    AntiVoid.LastRescue = now

    root.CFrame = safe + Vector3.new(0, 3, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    notifyOnce("void", "Anti-Void", "Você caiu fora do mapa. Voltei pro último chão seguro.")
end)

----- Trocar de Servidor -----
local Hop = {
    Mode = "Mais cheio", -- "Mais cheio" | "Mais vazio" | "Aleatório"
    Busy = false,
    MaxPages = 3, -- quantas páginas da lista (100 servidores cada) ele busca, no máximo
    MaxTries = 5, -- quantos servidores tenta antes de desistir e só reentrar no jogo
}

-- GET que funciona em vários executores: game:HttpGet, ou request/http_request
local function httpGet(url)
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 0 then
        return body
    end

    local req = (syn and syn.request) or http_request or request
    if req then
        local ok2, res = pcall(req, { Url = url, Method = "GET" })
        if ok2 and type(res) == "table" and type(res.Body) == "string" and (res.StatusCode or 200) == 200 then
            return res.Body
        end
    end
    return nil
end

-- Servidores públicos com vaga, já sem o servidor onde você está, na ordem do modo escolhido.
-- Devolve uma lista vazia se o executor não deixar buscar (ou a Roblox recusar).
local function fetchServers()
    local random = Hop.Mode == "Aleatório"
    local order = (Hop.Mode == "Mais vazio") and "Asc" or "Desc" -- Desc = mais cheio primeiro
    local want = random and 50 or Hop.MaxTries
    local found = {}
    local cursor = nil

    for _ = 1, Hop.MaxPages do
        local url = string.format(
            "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&excludeFullGames=true&limit=100",
            tostring(game.PlaceId),
            order
        )
        if cursor then
            url ..= "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local body = httpGet(url)
        if not body then
            break
        end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if not ok or type(data) ~= "table" or type(data.data) ~= "table" then
            break
        end

        for _, server in ipairs(data.data) do
            if
                server.id ~= game.JobId
                and type(server.playing) == "number"
                and type(server.maxPlayers) == "number"
                and server.playing < server.maxPlayers
            then
                table.insert(found, server)
            end
        end

        cursor = data.nextPageCursor
        if type(cursor) ~= "string" or #found >= want then
            break
        end
    end

    if random then
        for i = #found, 2, -1 do
            local j = math.random(i)
            found[i], found[j] = found[j], found[i]
        end
    end
    return found
end

-- Sem lista (ou nenhum servidor aceitou): só reentra no jogo
local function reenterGame(reason)
    WindUI:Notify({
        Title = "Trocar de Servidor",
        Content = reason .. " Reentrando no jogo...",
        Duration = 4,
    })
    task.wait(1)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

local function hopServer()
    if Hop.Busy then
        notifyOnce("hop", "Trocar de Servidor", "Já estou trocando, aguarde.")
        return
    end
    Hop.Busy = true

    task.spawn(function()
        WindUI:Notify({
            Title = "Trocar de Servidor",
            Content = "Procurando servidor (" .. string.lower(Hop.Mode) .. ")...",
            Duration = 3,
        })

        local ok, servers = pcall(fetchServers)
        if not ok or #servers == 0 then
            reenterGame("Não consegui a lista de servidores.")
            task.wait(10) -- se o teleporte falhar, libera o botão de novo
            Hop.Busy = false
            return
        end

        -- Se o servidor encher antes de você entrar, o teleporte falha: tenta o próximo da lista
        local failed = false
        local conn = TeleportService.TeleportInitFailed:Connect(function()
            failed = true
        end)

        local success = false
        for i = 1, math.min(#servers, Hop.MaxTries) do
            local server = servers[i]
            failed = false
            local started = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            end)
            if started then
                local t0 = os.clock()
                while not failed and os.clock() - t0 < 8 do
                    task.wait(0.25)
                end
                if not failed then
                    success = true -- sem erro em 8s: o teleporte está acontecendo
                    break
                end
            end
        end
        conn:Disconnect()

        if not success then
            reenterGame("Os servidores encheram ou o teleporte foi bloqueado.")
            task.wait(10)
        end
        Hop.Busy = false
    end)
end

-- Pede confirmação antes (um toque sem querer te tiraria da partida)
local function confirmHop()
    local shown = pcall(function()
        WindUI:Popup({
            Title = "Trocar de Servidor",
            Content = "Você vai sair desta partida e entrar em outro servidor ("
                .. string.lower(Hop.Mode)
                .. "). Continuar?",
            Icon = "server",
            Buttons = {
                { Title = "Cancelar", Variant = "Secondary", Callback = function() end },
                { Title = "Trocar", Variant = "Primary", Callback = hopServer },
            },
        })
    end)
    if not shown then
        hopServer() -- se o popup não abrir nesta versão do WindUI, troca direto
    end
end

----------------------------------------------------------------
-- Mod: Câmera (FOV travado + câmera longe travada)
----------------------------------------------------------------
local FOV = {
    Enabled = false,
    Value = 100,
    Original = nil, -- FOV que o jogo usava antes de ligar
    Watch = nil, -- conexão que desfaz qualquer mudança de FOV na hora
}

local CamLock = {
    Enabled = false,
    Distance = 50,
    OriginalMax = nil,
    OriginalMin = nil,
}

local function applyFOV()
    if not FOV.Enabled then
        return
    end
    local cam = Workspace.CurrentCamera
    if cam and cam.FieldOfView ~= FOV.Value then
        cam.FieldOfView = FOV.Value
    end
end

-- Min = Max = distância: o zoom (pinça/scroll) não muda mais a distância da câmera
local function lockZoomNow()
    local d = CamLock.Distance
    if LocalPlayer.CameraMaxZoomDistance == d and LocalPlayer.CameraMinZoomDistance == d then
        return
    end
    if d >= LocalPlayer.CameraMaxZoomDistance then
        LocalPlayer.CameraMaxZoomDistance = d
        LocalPlayer.CameraMinZoomDistance = d
    else
        LocalPlayer.CameraMinZoomDistance = d
        LocalPlayer.CameraMaxZoomDistance = d
    end
end

local function applyCamLock()
    if CamLock.Enabled then
        pcall(lockZoomNow)
    end
end

-- Vigia o FOV da câmera: se o Roblox ou o jogo mudar, volta no mesmo instante
local function watchFOV()
    if FOV.Watch then
        FOV.Watch:Disconnect()
        FOV.Watch = nil
    end
    local cam = Workspace.CurrentCamera
    if FOV.Enabled and cam then
        FOV.Watch = cam:GetPropertyChangedSignal("FieldOfView"):Connect(applyFOV)
    end
end

local function setFOVEnabled(state)
    local cam = Workspace.CurrentCamera
    if state then
        if cam and FOV.Original == nil then
            FOV.Original = cam.FieldOfView
        end
        FOV.Enabled = true
        watchFOV()
        applyFOV()
    else
        FOV.Enabled = false
        watchFOV() -- só desconecta
        if cam and FOV.Original then
            cam.FieldOfView = FOV.Original
        end
        FOV.Original = nil
    end
end

local function setCamLockEnabled(state)
    if state then
        if CamLock.OriginalMax == nil then
            CamLock.OriginalMax = LocalPlayer.CameraMaxZoomDistance
            CamLock.OriginalMin = LocalPlayer.CameraMinZoomDistance
        end
        CamLock.Enabled = true
        applyCamLock()
    else
        CamLock.Enabled = false
        if CamLock.OriginalMax then
            pcall(function()
                LocalPlayer.CameraMinZoomDistance = CamLock.OriginalMin
                LocalPlayer.CameraMaxZoomDistance = CamLock.OriginalMax
            end)
        end
        CamLock.OriginalMax, CamLock.OriginalMin = nil, nil
    end
end

-- Roda por último no frame (prioridade máxima): nada consegue passar por cima
pcall(function()
    RunService:UnbindFromRenderStep("BukFOV")
end)
RunService:BindToRenderStep("BukFOV", Enum.RenderPriority.Last.Value, function()
    applyFOV()
    applyCamLock()
    applyBright()
end)

-- Se o jogo trocar a câmera, passa a vigiar a nova
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    watchFOV()
    applyFOV()
end)

----------------------------------------------------------------
-- Unload
----------------------------------------------------------------
local function Unload()
    State.CFrameSpeed = false
    LockOn.Enabled = false
    LockOn.Active = false
    LockOn.Target = nil
    LockOn.AutoSwitch = false
    Combat.FaceTarget = false
    Combat.Dodge.Enabled = false
    setFOVEnabled(false)
    setBrightEnabled(false)
    setPerfEnabled(false)
    setCamLockEnabled(false)
    Stick.Enabled = false
    Stick.Active = false
    Stick.Target = nil
    Radar.Enabled = false
    AntiVoid.Enabled = false
    destroyGui(StickGui)
    StickGui, StickButton = nil, nil
    destroyGui(RadarGui)
    RadarGui, RadarFrame = nil, nil
    table.clear(Radar.Dots)
    pcall(function()
        RunService:UnbindFromRenderStep("BukFOV")
    end)
    pcall(function()
        RunService:UnbindFromRenderStep("BukLockOn")
    end)
    if LockGui then
        pcall(function()
            LockGui:Destroy()
        end)
        LockGui = nil
        LockButton = nil
    end
    for _, key in ipairs({ "Name", "Health", "BoxCorner" }) do
        State.ESP[key] = false
    end

    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    table.clear(Connections)

    for plr in pairs(ESPObjects) do
        removeESP(plr)
    end

    if Window then
        pcall(function()
            Window:Destroy()
        end)
    end

    env.BukHub = nil
end

env.BukHub = { Unload = Unload }

----------------------------------------------------------------
-- Temas
----------------------------------------------------------------
-- Darker: visual padrão do WindUI (Dark), só que mais escuro
WindUI:AddTheme({
    Name = "Darker",

    Accent = Color3.fromHex("#0d0d0f"),
    Dialog = Color3.fromHex("#0a0a0a"),
    Outline = Color3.fromHex("#FFFFFF"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#6b6b6b"),
    Background = Color3.fromHex("#050505"),
    Button = Color3.fromHex("#3f3f46"),
    Icon = Color3.fromHex("#a1a1aa"),
})

-- Demon Slayer (opcional, escolha em Settings > Aparência)
WindUI:AddTheme({
    Name = "Demon Slayer",

    Accent = Color3.fromHex("#10291d"),
    Dialog = Color3.fromHex("#0a1610"),
    Outline = Color3.fromHex("#e63946"),
    Text = Color3.fromHex("#f1f5ee"),
    Placeholder = Color3.fromHex("#7c8f84"),
    Background = Color3.fromHex("#070d0a"),
    Button = Color3.fromHex("#1f5c3a"),
    Icon = Color3.fromHex("#ff5a68"),
    Toggle = Color3.fromHex("#e63946"),
    Slider = Color3.fromHex("#e63946"),
})

----------------------------------------------------------------
-- Janela
----------------------------------------------------------------
WindUI.TransparencyValue = 0.25

local WINDOW_W, WINDOW_H = 580, 460

-- Janela sólida por padrão: com transparência, o jogo (personagens, objetos) aparecia
-- "fantasma" por trás do menu e atrapalhava a leitura. Dá pra ligar em Settings > Aparência.
Window = WindUI:CreateWindow({
    Title = "Buk",
    Author = "Created by Line",
    Folder = "Buk",
    Icon = "swords",
    Theme = "Darker",
    Transparent = false,
    Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
    ToggleKey = Enum.KeyCode.RightShift,
})

if not Window then
    return
end

-- O WindUI calcula o tamanho (escala) da janela só uma vez, na hora que ela abre. Se a tela
-- ainda estava mudando nesse momento (jogo carregando, celular girando), a janela fica grande
-- ou pequena demais e bugada. Aqui a escala é recalculada sempre que o tamanho da tela muda.
local function fitWindow()
    if not Window or Window.IsFullscreen then
        return
    end
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize
    if not vp or vp.X < 100 or vp.Y < 100 then
        return
    end
    local scale = math.clamp(math.min((vp.X - 80) / WINDOW_W, (vp.Y - 80) / WINDOW_H), 0.3, 1)
    local current = Window:GetUIScale() or 1
    if math.abs(scale - current) > 0.05 then
        Window:SetUIScale(scale)
    end
end

local viewportConn
local function watchViewport()
    if viewportConn then
        viewportConn:Disconnect()
        viewportConn = nil
    end
    local cam = Workspace.CurrentCamera
    if cam then
        viewportConn = connect(cam:GetPropertyChangedSignal("ViewportSize"), function()
            pcall(fitWindow)
        end)
    end
end

watchViewport()
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    watchViewport()
    pcall(fitWindow)
end)
task.delay(1, function()
    pcall(fitWindow)
end)

-- Config (salvar/carregar configurações)
do
    local CM = Window.ConfigManager
    local ok, result = pcall(function()
        if CM.Config then
            return CM:Config("Buk_v2")
        end
        return CM:CreateConfig("Buk_v2")
    end)
    if ok then
        Config = result
    end
end

----------------------------------------------------------------
-- 1. Main (Full Bright, FPS Boost)
----------------------------------------------------------------
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
})

MainTab:Toggle({
    Title = "Full Bright",
    Desc = "Clareia o mapa e tira a névoa pra você enxergar tudo, até nos lugares escuros.",
    Flag = "main_fullbright",
    Value = false,
    Callback = function(state)
        setBrightEnabled(state)
    end,
})

MainTab:Toggle({
    Title = "FPS Boost",
    Desc = "Desliga sombras, efeitos e partículas pra ganhar FPS no celular.",
    Flag = "main_fps_boost",
    Value = false,
    Callback = function(state)
        setPerfEnabled(state)
    end,
})

----- Grudar nas Costas -----
local StickSection = MainTab:Section({ Title = "Grudar nas Costas", Opened = true })

-- Sem Flag de propósito: o player escolhido não é salvo (na próxima partida a lista é outra)
StickDropdown = StickSection:Dropdown({
    Title = "Escolher Player",
    Desc = "Escolha em quem grudar. A lista atualiza sozinha quando alguém entra ou sai.",
    Values = buildStickOptions(),
    Value = STICK_NONE,
    Callback = function(selected)
        selectStickTarget(selected)
    end,
})

StickSection:Toggle({
    Title = "Botão Grudar",
    Desc = "Mostra um botão flutuante (igual ao Lock On). Toque nele pra ir até o player escolhido e ficar grudado nas costas dele, seguindo ele pra onde for. Toque de novo pra soltar.",
    Flag = "stick_button",
    Value = false,
    Callback = function(state)
        setStickEnabled(state)
    end,
})

StickSection:Slider({
    Title = "Distância atrás do alvo",
    Flag = "stick_distance",
    Step = 1,
    Value = { Min = 2, Max = 10, Default = 3 },
    Callback = function(value)
        Stick.Distance = value
    end,
})

StickSection:Toggle({
    Title = "Orbitar",
    Desc = "Em vez de ficar só atrás, você gira em volta do alvo enquanto está grudado.",
    Flag = "stick_orbit",
    Value = false,
    Callback = function(state)
        Stick.Orbit = state
        Stick.OrbitDir = nil
    end,
})

StickSection:Slider({
    Title = "Velocidade da órbita (graus/s)",
    Flag = "stick_orbit_speed",
    Step = 10,
    Value = { Min = 30, Max = 360, Default = 90 },
    Callback = function(value)
        Stick.OrbitSpeed = value
    end,
})

----- Radar -----
local RadarSection = MainTab:Section({ Title = "Radar", Opened = true })

RadarSection:Toggle({
    Title = "Radar",
    Desc = "Mini-mapa redondo com os players por perto. Gira junto com a sua câmera (frente = pra cima). Dá pra arrastar.",
    Flag = "radar_enabled",
    Value = false,
    Callback = function(state)
        setRadarEnabled(state)
    end,
})

RadarSection:Slider({
    Title = "Alcance do Radar",
    Desc = "Distância até a borda do círculo. Quem está mais longe fica meio apagado na borda.",
    Flag = "radar_range",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 150 },
    Callback = function(value)
        Radar.Range = value
    end,
})

RadarSection:Slider({
    Title = "Tamanho do Radar",
    Flag = "radar_size",
    Step = 10,
    Value = { Min = 100, Max = 220, Default = 150 },
    Callback = function(value)
        setRadarSize(value)
    end,
})

----- Anti-Void -----
local VoidSection = MainTab:Section({ Title = "Anti-Void", Opened = true })

VoidSection:Toggle({
    Title = "Anti-Void",
    Desc = "Se você cair fora do mapa, volta pro último chão em que pisou, antes de morrer.",
    Flag = "antivoid_enabled",
    Value = false,
    Callback = function(state)
        AntiVoid.Enabled = state
        if not state then
            AntiVoid.LastSafe = nil
        end
    end,
})

VoidSection:Slider({
    Title = "Queda sem chão (studs)",
    Desc = "Se você cair mais que isso e não tiver chão embaixo, volta. Menor = volta mais rápido.",
    Flag = "antivoid_fall",
    Step = 10,
    Value = { Min = 40, Max = 300, Default = 80 },
    Callback = function(value)
        AntiVoid.FallDistance = value
    end,
})

----- Trocar de Servidor -----
local HopSection = MainTab:Section({ Title = "Servidor", Opened = true })

HopSection:Dropdown({
    Title = "Servidor de destino",
    Desc = "Mais cheio = o servidor com mais gente que ainda tem vaga.",
    Values = { "Mais cheio", "Mais vazio", "Aleatório" },
    Value = "Mais cheio",
    Flag = "hop_mode",
    Callback = function(selected)
        Hop.Mode = selected
    end,
})

HopSection:Button({
    Title = "Trocar de Servidor",
    Desc = "Te leva pra outro servidor do jogo. Se o seu executor não deixar buscar a lista de servidores, só reentra no jogo.",
    Icon = "server",
    Callback = function()
        confirmHop()
    end,
})

----------------------------------------------------------------
-- 2. Player (CFrame)
----------------------------------------------------------------
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

PlayerTab:Toggle({
    Title = "CFrame Speed",
    Flag = "cframe_speed",
    Value = false,
    Callback = function(state)
        State.CFrameSpeed = state
    end,
})

PlayerTab:Slider({
    Title = "Velocidade",
    Flag = "cframe_speed_value",
    Step = 1,
    Value = { Min = 1, Max = 300, Default = 30 },
    Callback = function(value)
        State.SpeedValue = value
    end,
})

----------------------------------------------------------------
-- 3. Esp
----------------------------------------------------------------
local EspTab = Window:Tab({
    Title = "Esp",
    Icon = "eye",
})

EspTab:Toggle({
    Title = "Esp Name",
    Flag = "esp_name",
    Value = false,
    Callback = function(state)
        State.ESP.Name = state
    end,
})

EspTab:Toggle({
    Title = "Esp Health",
    Desc = "Mostra a vida no formato atual/máxima",
    Flag = "esp_health",
    Value = false,
    Callback = function(state)
        State.ESP.Health = state
    end,
})

EspTab:Toggle({
    Title = "Esp Box Corner",
    Flag = "esp_box_corner",
    Value = false,
    Callback = function(state)
        State.ESP.BoxCorner = state
    end,
})

EspTab:Colorpicker({
    Title = "Cor do Esp",
    Flag = "esp_color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        State.ESP.Color = color
    end,
})

EspTab:Slider({
    Title = "Distância máxima",
    Flag = "esp_max_distance",
    Step = 50,
    Value = { Min = 100, Max = 5000, Default = 2000 },
    Callback = function(value)
        State.ESP.MaxDistance = value
    end,
})

----------------------------------------------------------------
-- 4. Painel (Lock On, Auto Desvio)
----------------------------------------------------------------
local PainelTab = Window:Tab({
    Title = "Painel",
    Icon = "layout-dashboard",
})

----- Lock On -----
local LockSection = PainelTab:Section({ Title = "Lock On", Opened = true })

LockSection:Toggle({
    Title = "Lock On",
    Desc = "Mostra um botão flutuante. Aperte nele para travar a câmera no player mais próximo.",
    Flag = "lockon_enabled",
    Value = false,
    Callback = function(state)
        setLockEnabled(state)
    end,
})

LockSection:Toggle({
    Title = "Trocar Sozinho ao Morrer",
    Desc = "Quando o alvo morre, sai ou fica longe demais, a trava pula sozinha pro próximo mais perto em vez de desligar.",
    Flag = "lockon_auto_switch",
    Value = false,
    Callback = function(state)
        LockOn.AutoSwitch = state
    end,
})

LockSection:Toggle({
    Title = "Travar Botão",
    Desc = "Deixa os botões flutuantes (Lock On e Grudar) e o Radar parados: eles não andam mais quando você toca.",
    Flag = "lockon_button_locked",
    Value = false,
    Callback = function(state)
        LockOn.ButtonLocked = state
    end,
})

LockSection:Toggle({
    Title = "Virar pro Alvo",
    Desc = "Com o Lock On ativo, seu personagem fica virado pro alvo (as skills saem na direção dele).",
    Flag = "lockon_face",
    Value = false,
    Callback = function(state)
        Combat.FaceTarget = state
    end,
})

LockSection:Dropdown({
    Title = "Alvo do Lock On",
    Values = { "Corpo", "Cabeça" },
    Value = "Corpo",
    Flag = "lockon_part",
    Callback = function(selected)
        LockOn.PartName = (selected == "Cabeça") and "Head" or "HumanoidRootPart"
    end,
})

LockSection:Slider({
    Title = "Distância máxima do Lock On",
    Flag = "lockon_max_distance",
    Step = 10,
    Value = { Min = 20, Max = 1000, Default = 300 },
    Callback = function(value)
        LockOn.MaxDistance = value
    end,
})

----- Auto Desvio -----
local DodgeSection = PainelTab:Section({ Title = "Auto Desvio", Opened = true })

DodgeSection:Toggle({
    Title = "Auto Desvio",
    Desc = "Quando qualquer player chega perto de você, seu personagem dá um passo pro lado sozinho.",
    Flag = "dodge_enabled",
    Value = false,
    Callback = function(state)
        Combat.Dodge.Enabled = state
    end,
})

DodgeSection:Slider({
    Title = "Distância de detecção",
    Desc = "Se um player chegar mais perto que isso, você desvia.",
    Flag = "dodge_range",
    Step = 1,
    Value = { Min = 5, Max = 40, Default = 15 },
    Callback = function(value)
        Combat.Dodge.Range = value
    end,
})

DodgeSection:Slider({
    Title = "Distância do passo",
    Flag = "dodge_step",
    Step = 1,
    Value = { Min = 4, Max = 25, Default = 10 },
    Callback = function(value)
        Combat.Dodge.StepDistance = value
    end,
})

DodgeSection:Slider({
    Title = "Intervalo entre desvios (ms)",
    Flag = "dodge_cooldown",
    Step = 10,
    Value = { Min = 100, Max = 200, Default = 200 },
    Callback = function(value)
        -- clamp: se uma config antiga salva (ex: 600) for carregada, não passa do limite novo
        Combat.Dodge.Cooldown = math.clamp(value, 100, 200) / 1000
    end,
})

----------------------------------------------------------------
-- Mod (Câmera)
----------------------------------------------------------------
local ModTab = Window:Tab({
    Title = "Mod",
    Icon = "wrench",
})

----- Câmera -----
local CamSection = ModTab:Section({ Title = "Câmera", Opened = true })

CamSection:Toggle({
    Title = "FOV",
    Desc = "Aumenta o campo de visão pra enxergar mais longe. Fica travado: o Roblox e o jogo não conseguem mudar.",
    Flag = "fov_enabled",
    Value = false,
    Callback = function(state)
        setFOVEnabled(state)
    end,
})

CamSection:Slider({
    Title = "Valor do FOV",
    Flag = "fov_value",
    Step = 1,
    Value = { Min = 70, Max = 120, Default = 100 },
    Callback = function(value)
        FOV.Value = value
        applyFOV()
    end,
})

CamSection:Toggle({
    Title = "Câmera Longe (Travada)",
    Desc = "Deixa a câmera afastada na distância escolhida e trava: o zoom (pinça/scroll) não muda mais.",
    Flag = "cam_lock",
    Value = false,
    Callback = function(state)
        setCamLockEnabled(state)
    end,
})

CamSection:Slider({
    Title = "Distância da Câmera",
    Flag = "cam_distance",
    Step = 1,
    Value = { Min = 10, Max = 300, Default = 50 },
    Callback = function(value)
        CamLock.Distance = value
        applyCamLock()
    end,
})

----------------------------------------------------------------
-- 5. Settings
----------------------------------------------------------------
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

-- Lista: Aparência
local AppearanceSection = SettingsTab:Section({ Title = "Aparência", Opened = true })

AppearanceSection:Dropdown({
    Title = "Tema",
    Values = { "Darker", "Dark", "Demon Slayer" },
    Value = "Darker",
    Flag = "theme",
    Callback = function(selected)
        WindUI:SetTheme(selected)
    end,
})

AppearanceSection:Toggle({
    Title = "Janela transparente",
    Desc = "Deixa o menu meio transparente. Se o jogo ficar aparecendo 'fantasma' por trás, deixe desligado.",
    Flag = "ui_transparent",
    Value = false,
    Callback = function(state)
        pcall(function()
            Window:ToggleTransparency(state)
        end)
    end,
})

-- Lista: Settings File
local FileSection = SettingsTab:Section({ Title = "Settings File", Opened = true })

FileSection:Button({
    Title = "Save Settings",
    Icon = "save",
    Callback = function()
        local ok = Config and pcall(function()
            Config:Save()
        end)
        WindUI:Notify({
            Title = "Buk",
            Content = ok and "Configurações salvas com sucesso!" or "Não foi possível salvar as configurações.",
            Duration = 3,
            Icon = ok and "check" or "x",
        })
    end,
})

FileSection:Button({
    Title = "Unload Script",
    Icon = "power",
    Callback = Unload,
})

----------------------------------------------------------------
-- Finalização
----------------------------------------------------------------
if Config then
    pcall(function()
        Config:Load() -- carrega as configurações salvas anteriormente
    end)
end

if not DrawingSupported then
    WindUI:Notify({
        Title = "Buk",
        Content = "Seu executor não suporta a Drawing API. O Esp não vai funcionar.",
        Duration = 6,
        Icon = "triangle-alert",
    })
end

WindUI:Notify({
    Title = "Buk",
    Content = "Script carregado! Pressione RightShift para abrir/fechar.",
    Duration = 4,
    Icon = "swords",
})
