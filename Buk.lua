--[[
    Buk — Duelos de Teletransporte
    Created by: Line
    UI Library: WindUI

    Abas: Main (Trocar de Servidor) | Aimbot (1v1 até 4v4) | Player (CFrame Speed, Shift Lock) | Esp | Mod (Câmera) | Settings
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
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

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
        Distance = false,
        BoxCorner = false,
        Tracer = false,
        TeamCheck = false,
        MaxDistance = 2000,
        Color = Color3.fromRGB(255, 255, 255), -- branco (padrão)
    },
}

local Aim = {
    Enabled = false, -- toggle da aba Aimbot (mostra os botões flutuantes)
    Active = false, -- aimbot ligado (botão AIM apertado)
    Target = nil, -- Player travado
    Part = nil, -- parte do alvo que está sendo seguida neste frame (nil = sem alvo válido)
    ButtonLocked = false, -- impede arrastar os botões
    Mode = "4v4", -- "1v1" | "2v2" | "3v3" | "4v4" (limite de players por perto)
    PartName = "HumanoidRootPart",
    Pick = "Perto de mim", -- primeiro alvo: "Perto de mim" | "Perto da mira"
    OnKill = "Aleatório", -- quem pegar quando o alvo morre: "Aleatório" | "Perto de mim" | "Perto da mira"
    Smooth = 0, -- 0 = trava total; quanto maior, mais devagar a câmera gira
    MaxDistance = 200, -- alcance para procurar alvo
    WallCheck = false, -- ignora quem está atrás de parede na hora de escolher o alvo
    FaceTarget = true, -- personagem sempre virado pro alvo
    NextScan = 0,
    IdleSince = nil,
    LastLock = nil, -- última vez que estava seguindo um alvo válido
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
local function notifyOnce(key, title, content)
    local now = os.clock()
    if lastNotify[key] and now - lastNotify[key] < 2 then
        return
    end
    lastNotify[key] = now
    WindUI:Notify({ Title = title, Content = content, Duration = 2 })
end

----------------------------------------------------------------
-- Helpers de alvo
----------------------------------------------------------------
local function getOrigin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Position
    end
    local cam = Workspace.CurrentCamera
    return cam and cam.CFrame.Position or Vector3.zero
end

-- Parte do corpo que o aimbot segue (nil se o player estiver morto ou sem personagem)
local function getTargetPart(plr)
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
        return nil
    end
    return char:FindFirstChild(Aim.PartName) or char:FindFirstChild("HumanoidRootPart")
end

----------------------------------------------------------------
-- Aliados (2v2): quem é do meu time nunca vira alvo
----------------------------------------------------------------
local Allies = {
    Manual = setmetatable({}, { __mode = "k" }), -- Player -> true (marcado pelo menu)
    Cache = {},
    CacheAt = 0,
}

-- Chave de time lida dos atributos (do Player e do personagem) que têm "team" no nome.
-- Serve para jogo que não usa o Team do Roblox mas guarda o time em atributo.
local function attrTeamKey(plr)
    local parts = {}
    local function scan(inst)
        if not inst then
            return
        end
        local ok, attrs = pcall(function()
            return inst:GetAttributes()
        end)
        if not ok then
            return
        end
        for name, value in pairs(attrs) do
            if string.find(string.lower(name), "team", 1, true) then
                local t = typeof(value)
                if t == "string" or t == "number" or t == "BrickColor" or t == "Color3" then
                    table.insert(parts, name .. "=" .. tostring(value))
                end
            end
        end
    end
    scan(plr)
    scan(plr.Character)
    if #parts == 0 then
        return nil
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

-- Só confia no time (Team do Roblox ou atributo) se existir alguém em outro time. Se o jogo
-- deixa todo mundo no mesmo time (ou sem time), isso não ajuda a achar aliado e é ignorado.
-- No 1v1 não existe aliado, então nada é marcado.
local function refreshAllies()
    local now = os.clock()
    if now - Allies.CacheAt < 0.2 then
        return
    end
    Allies.CacheAt = now

    if Aim.Mode == "1v1" then
        Allies.Cache = {}
        return
    end

    local myTeam = LocalPlayer.Team
    local myKey = attrTeamKey(LocalPlayer)
    local keys = {}
    local teamsUseful, keysUseful = false, false

    local all = Players:GetPlayers()
    for _, plr in ipairs(all) do
        if plr ~= LocalPlayer then
            local key = attrTeamKey(plr)
            keys[plr] = key
            if myTeam ~= nil and plr.Team ~= myTeam then
                teamsUseful = true
            end
            if myKey ~= nil and key ~= myKey then
                keysUseful = true
            end
        end
    end

    local cache = {}
    for _, plr in ipairs(all) do
        if plr ~= LocalPlayer then
            cache[plr] = (Allies.Manual[plr] == true)
                or (teamsUseful and plr.Team == myTeam)
                or (keysUseful and keys[plr] == myKey)
        end
    end
    Allies.Cache = cache
end

local function isAlly(plr)
    refreshAllies()
    return Allies.Cache[plr] == true
end

-- Marca como aliado o player mais perto de mim que ainda não é aliado
-- (no 3v3/4v4 dá pra apertar mais de uma vez, um aliado por toque)
local function markNearestAsAlly()
    local origin = getOrigin()
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not isAlly(plr) then
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - origin).Magnitude
                if d < bestDist then
                    best, bestDist = plr, d
                end
            end
        end
    end

    if not best then
        WindUI:Notify({ Title = "Aimbot", Content = "Ninguém por perto para marcar.", Duration = 2 })
        return
    end

    Allies.Manual[best] = true
    Allies.CacheAt = 0
    WindUI:Notify({ Title = "Aimbot", Content = best.DisplayName .. " marcado como aliado.", Duration = 2 })
end

-- Marca como aliado quem o aimbot está seguindo agora (o aimbot já pula pro próximo inimigo)
local function markCurrentAsAlly()
    local target = Aim.Target
    if not (Aim.Active and target) then
        WindUI:Notify({ Title = "Aimbot", Content = "Nenhum alvo travado no momento.", Duration = 2 })
        return
    end
    Allies.Manual[target] = true
    Allies.CacheAt = 0
    WindUI:Notify({ Title = "Aimbot", Content = target.DisplayName .. " marcado como aliado.", Duration = 2 })
end

local function clearAllies()
    table.clear(Allies.Manual)
    Allies.CacheAt = 0
    WindUI:Notify({ Title = "Aimbot", Content = "Aliados marcados foram limpos.", Duration = 2 })
end

-- Diagnóstico: junta o que o jogo guarda de time/atributos de cada player e copia pro clipboard.
-- Serve pra descobrir como o jogo separa os times se a detecção automática falhar.
local function dumpPlayers()
    local function attrs(inst)
        local out = {}
        local ok, a = pcall(function()
            return inst:GetAttributes()
        end)
        if ok then
            for k, v in pairs(a) do
                table.insert(out, k .. "=" .. tostring(v))
            end
        end
        table.sort(out)
        return table.concat(out, ", ")
    end

    local lines = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        local extra = {}
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if
                    not child:IsA("BasePart")
                    and not child:IsA("Accessory")
                    and not child:IsA("Humanoid")
                    and not child:IsA("Clothing")
                    and not child:IsA("CharacterMesh")
                    and #extra < 15
                then
                    table.insert(extra, child.ClassName .. ":" .. child.Name)
                end
            end
        end
        table.insert(
            lines,
            string.format(
                "%s%s | Team=%s | TeamColor=%s | attrs[%s] | charAttrs[%s] | char[%s]",
                plr == LocalPlayer and "(EU) " or "",
                plr.Name,
                plr.Team and plr.Team.Name or "nil",
                tostring(plr.TeamColor),
                attrs(plr),
                char and attrs(char) or "",
                table.concat(extra, ", ")
            )
        )
    end

    local text = table.concat(lines, "\n")
    local copied = false
    if setclipboard then
        copied = pcall(setclipboard, text)
    end
    print(text)
    WindUI:Notify({
        Title = "Aimbot",
        Content = copied and "Info dos players copiada. Cole no chat."
            or "Sem clipboard no executor: a info saiu no console (F9).",
        Duration = 4,
    })
end

connect(Players.PlayerRemoving, function(plr)
    Allies.Manual[plr] = nil
end)

----------------------------------------------------------------
-- ESP (Drawing API): Name, Health (barra), Distância, Box Corner e Linha
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
local ESP_PARTS = { "Name", "Health", "Distance", "BarBack", "Bar", "Tracer" }
local HP_LOW = Color3.fromRGB(255, 60, 60)
local HP_FULL = Color3.fromRGB(70, 255, 110)

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
        Distance = newDrawing("Text", { Size = 13, Center = true, Outline = true, Visible = false }),
        BarBack = newDrawing("Line", { Thickness = 5, Color = Color3.fromRGB(0, 0, 0), Visible = false }),
        Bar = newDrawing("Line", { Thickness = 3, Visible = false }),
        Tracer = newDrawing("Line", { Thickness = 1, Visible = false }),
        Corners = {},
    }
    for i = 1, 8 do
        obj.Corners[i] = newDrawing("Line", { Thickness = 1.5, Visible = false })
    end

    ESPObjects[plr] = obj
    return obj
end

local function hideESP(obj)
    for _, key in ipairs(ESP_PARTS) do
        obj[key].Visible = false
    end
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
    for _, key in ipairs(ESP_PARTS) do
        rm(obj[key])
    end
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

    -- Ignorar aliados (meu time, ou marcado na aba Aimbot)
    if cfg.TeamCheck and isAlly(plr) then
        return hideESP(obj)
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local origin = myRoot and myRoot.Position or Camera.CFrame.Position
    local dist = (origin - root.Position).Magnitude
    if dist > cfg.MaxDistance then
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
    local below = y2 + 2 -- onde começa o texto embaixo da caixa

    -- 1. Esp Name
    if cfg.Name then
        obj.Name.Text = plr.DisplayName
        obj.Name.Position = Vector2.new(cx, y1 - 18)
        obj.Name.Color = color
        obj.Name.Visible = true
    else
        obj.Name.Visible = false
    end

    -- 2. Esp Health: barra do lado esquerdo da caixa + vida atual/máxima embaixo
    if cfg.Health then
        local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local hpColor = HP_LOW:Lerp(HP_FULL, ratio)
        local bx = math.floor(x1 - 6)

        setLine(obj.BarBack, bx, y1 - 1, bx, y2 + 1, Color3.fromRGB(0, 0, 0))
        setLine(obj.Bar, bx, y2, bx, y2 - (y2 - y1) * ratio, hpColor)

        obj.Health.Text = string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
        obj.Health.Position = Vector2.new(cx, below)
        obj.Health.Color = hpColor
        obj.Health.Visible = true
        below += 14
    else
        obj.BarBack.Visible = false
        obj.Bar.Visible = false
        obj.Health.Visible = false
    end

    -- 3. Esp Distância (em studs, embaixo da caixa)
    if cfg.Distance then
        obj.Distance.Text = string.format("[%d]", math.floor(dist))
        obj.Distance.Position = Vector2.new(cx, below)
        obj.Distance.Color = color
        obj.Distance.Visible = true
    else
        obj.Distance.Visible = false
    end

    -- 4. Esp Linha: do meio de baixo da tela até os pés do player
    if cfg.Tracer then
        local vp = Camera.ViewportSize
        setLine(obj.Tracer, vp.X / 2, vp.Y, cx, y2, color)
    else
        obj.Tracer.Visible = false
    end

    -- 5. Esp Box Corner
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
    local anyOn = cfg.Name or cfg.Health or cfg.Distance or cfg.BoxCorner or cfg.Tracer

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
-- Aimbot (1v1 e 2v2): botões flutuantes, mira e trava da câmera
----------------------------------------------------------------
local AimGui, AimButton -- botão AIM (liga/desliga)
local SwitchGui, SwitchButton -- botão TROCA ALVO (só no 2v2)
local AimDotGui, AimDotFrame -- mira (anel + ponto) que aparece no alvo

-- Quantos players (aliados + inimigos) podem estar por perto para o aimbot ligar.
-- 1v1 = 1, 2v2 = 3, 3v3 = 5, 4v4 = 7 (todo mundo menos eu). Mais que isso (lobby cheio,
-- outra partida do lado) o aimbot não liga, assim ele não puxa a câmera pra qualquer um.
local MAX_NEAR = { ["1v1"] = 1, ["2v2"] = 3, ["3v3"] = 5, ["4v4"] = 7 }
local IDLE_OFF_AFTER = 8 -- segundos sem nenhum inimigo até o aimbot se desligar sozinho

-- Tamanhos do dropdown "Tamanho da mira": anel (px), ponto do meio (px) e espessura do anel
local AIM_DOT_SIZES = {
    Fino = { ring = 26, dot = 4, thick = 1.5 },
    ["Médio"] = { ring = 34, dot = 6, thick = 2 },
    Grosso = { ring = 44, dot = 8, thick = 2.5 },
    Grande = { ring = 58, dot = 10, thick = 3 },
}
local AimDot = {
    Preset = AIM_DOT_SIZES["Médio"],
    Color = Color3.fromRGB(255, 60, 60), -- cor do ponto do meio
}
local BUTTON_SIZE = 64
local DRAG_THRESHOLD = 8 -- pixels que o dedo precisa mover para contar como arraste

local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude

-- O alvo está visível (sem parede no meio entre a câmera e ele)?
local function isVisible(cam, plr, part)
    local myChar = LocalPlayer.Character
    wallParams.FilterDescendantsInstances = myChar and { myChar } or {}
    local origin = cam.CFrame.Position
    local hit = Workspace:Raycast(origin, part.Position - origin, wallParams)
    return hit == nil or (plr.Character ~= nil and hit.Instance:IsDescendantOf(plr.Character))
end

-- Inimigos vivos dentro do alcance (sem aliados), do melhor para o pior alvo.
-- Também devolve quantos players (aliados ou não) estão por perto, para o limite do modo.
local function scanEnemies(pick)
    pick = pick or Aim.Pick
    local cam = Workspace.CurrentCamera
    local origin = getOrigin()
    local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
    local center = Vector2.new(vp.X / 2, vp.Y / 2)

    local enemies, near = {}, 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local part = getTargetPart(plr)
            if part then
                local dist = (part.Position - origin).Magnitude
                if dist <= Aim.MaxDistance then
                    near += 1
                    if not isAlly(plr) and (not Aim.WallCheck or not cam or isVisible(cam, plr, part)) then
                        local score = dist
                        if pick == "Perto da mira" and cam then
                            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                            if onScreen then
                                score = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            else
                                score = 1e6 + dist
                            end
                        end
                        table.insert(enemies, { plr = plr, score = score })
                    end
                end
            end
        end
    end

    table.sort(enemies, function(a, b)
        return a.score < b.score
    end)
    return enemies, near
end

local function overLimit(near)
    return near > (MAX_NEAR[Aim.Mode] or 7)
end

local BTN_ON_BG = Color3.fromRGB(24, 60, 38)
local BTN_OFF_BG = Color3.fromRGB(14, 14, 16)
local BTN_ON_STROKE = Color3.fromRGB(70, 255, 110)
local BTN_OFF_STROKE = Color3.fromRGB(255, 255, 255)
local BTN_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Texto e cor de um botão flutuante (ligado/desligado), com transição suave
local function setButtonState(btn, active, text)
    if not btn then
        return
    end
    btn.Text = text
    TweenService:Create(btn, BTN_TWEEN, { BackgroundColor3 = active and BTN_ON_BG or BTN_OFF_BG }):Play()
    local stroke = btn:FindFirstChildOfClass("UIStroke")
    if stroke then
        TweenService:Create(stroke, BTN_TWEEN, { Color = active and BTN_ON_STROKE or BTN_OFF_STROKE }):Play()
    end
end

local function refreshAimButton()
    setButtonState(AimButton, Aim.Active, Aim.Active and "AIM\nON" or "AIM\nOFF")
end

local function refreshSwitchVisibility()
    if SwitchGui then
        SwitchGui.Enabled = Aim.Enabled and Aim.Mode ~= "1v1"
    end
end

local function hideAimDot()
    if AimDotFrame then
        AimDotFrame.Visible = false
    end
end

-- Liga o aimbot no inimigo mais bem colocado; desliga se não tiver como ligar
local function setAimActive(active)
    if active then
        local enemies, near = scanEnemies()
        if overLimit(near) then
            Aim.Target, Aim.Active = nil, false
            notifyOnce(
                "aimLimit",
                "Aimbot",
                string.format(
                    "Tem %d players por perto, mais que o modo %s aguenta. Diminua o Alcance se tiver outra arena perto.",
                    near,
                    Aim.Mode
                )
            )
        elseif #enemies == 0 then
            Aim.Target, Aim.Active = nil, false
            notifyOnce("aimNone", "Aimbot", "Nenhum inimigo por perto.")
        else
            Aim.Target = enemies[1].plr
            Aim.Active = true
            Aim.IdleSince = nil
            Aim.LastLock = os.clock()
        end
    else
        Aim.Target, Aim.Active = nil, false
    end

    Aim.Part = nil
    refreshAimButton()
    if not Aim.Active then
        hideAimDot()
    end
end

-- Troca pro próximo inimigo vivo (botão TROCA ALVO). Se o aimbot estiver desligado, liga.
-- A ordem do ciclo é fixa (por UserId), então com 3-4 inimigos ele passa por todos.
local function switchTarget()
    if not (Aim.Active and Aim.Target) then
        setAimActive(true)
        return
    end

    local enemies = scanEnemies()
    if #enemies == 0 then
        notifyOnce("aimNone", "Aimbot", "Nenhum inimigo por perto.")
        return
    end

    table.sort(enemies, function(a, b)
        return a.plr.UserId < b.plr.UserId
    end)

    local nextTarget = enemies[1].plr
    for i, e in ipairs(enemies) do
        if e.plr == Aim.Target then
            nextTarget = enemies[i % #enemies + 1].plr
            break
        end
    end

    Aim.Target = nextTarget
    Aim.IdleSince = nil
    Aim.LastLock = os.clock()
    hideAimDot() -- a mira reaparece no novo alvo com a animação
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
-- Com "Travar Botões" ligado nada arrasta e todo toque conta como clique.
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
            if onClick and (Aim.ButtonLocked or not moved) then
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

        if moved and not Aim.ButtonLocked then
            local size = gui.AbsoluteSize
            local objSize = obj.AbsoluteSize
            local x = math.clamp(startPos.X.Offset + delta.X, 0, math.max(size.X - objSize.X, 0))
            local y = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(size.Y - objSize.Y, 0))
            obj.Position = UDim2.fromOffset(x, y)
        end
    end)
end

-- Cria um botão redondo flutuante e arrastável.
-- Toque = onClick | Arrastar = move o botão (a menos que "Travar Botões" esteja ligado)
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

    -- Feedback ao tocar: a borda engrossa enquanto o dedo está apertando
    btn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
            return
        end
        TweenService:Create(stroke, BTN_TWEEN, { Thickness = 4 }):Play()
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then
                return
            end
            conn:Disconnect()
            TweenService:Create(stroke, BTN_TWEEN, { Thickness = 2 }):Play()
        end)
    end)

    mountGui(gui)
    makeDraggable(gui, btn, onClick)

    return gui, btn
end

local function getViewport()
    local cam = Workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(800, 600)
end

local function createAimGui()
    if AimGui then
        return
    end
    local vp = getViewport()

    AimGui, AimButton = createFloatingButton(
        "BukAim",
        "AIM\nOFF",
        math.max(vp.X - BUTTON_SIZE - 240, 0),
        math.max(vp.Y * 0.5 - BUTTON_SIZE / 2, 0),
        function()
            setAimActive(not Aim.Active)
        end
    )
    refreshAimButton()
end

local function createSwitchGui()
    if SwitchGui then
        return
    end
    local vp = getViewport()

    SwitchGui, SwitchButton = createFloatingButton(
        "BukAimSwitch",
        "TROCA\nALVO",
        math.max(vp.X - BUTTON_SIZE - 240, 0),
        math.max(vp.Y * 0.5 + BUTTON_SIZE / 2 + 12, 0),
        switchTarget
    )
end

-- Mira (estilo GTA) que fica em cima do alvo enquanto o aimbot está ativo:
-- anel fino com um ponto no meio. Quando trava, o anel encolhe até o alvo.
local function applyAimDotSize()
    if not AimDotFrame then
        return
    end
    local p = AimDot.Preset
    AimDotFrame.Size = UDim2.fromOffset(p.ring, p.ring)
    AimDot.RingStroke.Thickness = p.thick
    AimDot.ShadowStroke.Thickness = p.thick + 2
    AimDot.Center.Size = UDim2.fromOffset(p.dot, p.dot)
end

local function createAimDot()
    if AimDotGui then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BukAimDot"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 998
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Caixa invisível do tamanho do anel, centrada no alvo
    local box = Instance.new("Frame")
    box.Name = "Dot"
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = gui

    -- Grupo dos anéis: é ele que encolhe na animação de travar
    local group = Instance.new("Frame")
    group.Name = "Rings"
    group.AnchorPoint = Vector2.new(0.5, 0.5)
    group.Position = UDim2.fromScale(0.5, 0.5)
    group.Size = UDim2.fromScale(1, 1)
    group.BackgroundTransparency = 1
    group.BorderSizePixel = 0
    group.Parent = box

    local scale = Instance.new("UIScale")
    scale.Parent = group

    local function makeRing(name, color, transparency)
        local ring = Instance.new("Frame")
        ring.Name = name
        ring.Size = UDim2.fromScale(1, 1)
        ring.BackgroundTransparency = 1
        ring.BorderSizePixel = 0
        ring.Parent = group

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ring

        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Transparency = transparency
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = ring
        return stroke
    end

    -- Anel escuro por baixo (contorno): a mira aparece em qualquer fundo
    local shadowStroke = makeRing("Shadow", Color3.fromRGB(0, 0, 0), 0.55)
    local ringStroke = makeRing("Ring", Color3.fromRGB(255, 255, 255), 0)

    -- Ponto do meio (a cor dele dá pra mudar no menu)
    local center = Instance.new("Frame")
    center.Name = "Center"
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Position = UDim2.fromScale(0.5, 0.5)
    center.BackgroundColor3 = AimDot.Color
    center.BorderSizePixel = 0
    center.Parent = box

    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = center

    local centerStroke = Instance.new("UIStroke")
    centerStroke.Thickness = 1
    centerStroke.Color = Color3.fromRGB(0, 0, 0)
    centerStroke.Transparency = 0.2
    centerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    centerStroke.Parent = center

    AimDot.Scale, AimDot.RingStroke, AimDot.ShadowStroke, AimDot.Center =
        scale, ringStroke, shadowStroke, center

    mountGui(gui)
    AimDotGui, AimDotFrame = gui, box
    applyAimDotSize()
end

local function setAimDotSize(preset)
    AimDot.Preset = preset
    applyAimDotSize()
end

local function setAimDotColor(color)
    AimDot.Color = color
    if AimDot.Center then
        AimDot.Center.BackgroundColor3 = color
    end
end

-- Efeito de travar: o anel começa grande e meio apagado e encolhe até o alvo
local AIM_DOT_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function playAimDotAnim()
    if not AimDot.Scale then
        return
    end
    AimDot.Scale.Scale = 2.4
    AimDot.RingStroke.Transparency = 0.8
    TweenService:Create(AimDot.Scale, AIM_DOT_TWEEN, { Scale = 1 }):Play()
    TweenService:Create(AimDot.RingStroke, AIM_DOT_TWEEN, { Transparency = 0 }):Play()
end

-- Põe a mira em cima da parte travada (some se ela estiver fora da tela).
-- Toda vez que ela volta a aparecer (travou agora, trocou de alvo, o alvo renasceu), toca a animação.
local function updateAimDot(cam, part)
    if not AimDotFrame then
        return
    end
    local pos, onScreen = cam:WorldToViewportPoint(part.Position)
    if onScreen then
        AimDotFrame.Position = UDim2.fromOffset(pos.X, pos.Y)
        if not AimDotFrame.Visible then
            AimDotFrame.Visible = true
            playAimDotAnim()
        end
    else
        AimDotFrame.Visible = false
    end
end

local function setAimEnabled(state)
    Aim.Enabled = state
    if state then
        createAimGui()
        createSwitchGui()
        createAimDot()
        if AimGui then
            AimGui.Enabled = true
        end
        refreshSwitchVisibility()
    else
        setAimActive(false)
        if AimGui then
            AimGui.Enabled = false
        end
        if SwitchGui then
            SwitchGui.Enabled = false
        end
    end
end

-- Roda por último no frame, depois de qualquer script de câmera (do Roblox ou do jogo)
pcall(function()
    RunService:UnbindFromRenderStep("BukAim")
end)
RunService:BindToRenderStep("BukAim", Enum.RenderPriority.Last.Value, function(dt)
    if not (Aim.Enabled and Aim.Active) then
        Aim.Part = nil
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then
        Aim.Part = nil
        return
    end
    local now = os.clock()

    -- O alvo atual ainda vale? (no servidor, vivo, não é aliado e não foi parar longe)
    local part = nil
    local target = Aim.Target
    if target and target.Parent == Players and not isAlly(target) then
        part = getTargetPart(target)
        if part and (part.Position - getOrigin()).Magnitude > Aim.MaxDistance * 1.25 then
            part = nil -- saiu da luta (foi pro lobby / espectador)
        end
    end

    -- Sem alvo válido (você matou, ele saiu, virou aliado...): puxa pra outro inimigo VIVO,
    -- nunca pro seu time. Se ficar um tempo sem nenhum inimigo, o aimbot se desliga sozinho.
    if not part then
        Aim.Part = nil
        hideAimDot()
        if now >= Aim.NextScan then
            Aim.NextScan = now + 0.2
            local kill = Aim.OnKill
            local enemies, near = scanEnemies(kill == "Aleatório" and "Perto de mim" or kill)
            -- no meio da luta o limite de players não bloqueia a troca (só vale pra ligar do zero)
            local fighting = Aim.LastLock ~= nil and now - Aim.LastLock < IDLE_OFF_AFTER
            if #enemies > 0 and (fighting or not overLimit(near)) then
                local pick = (kill == "Aleatório") and enemies[math.random(#enemies)] or enemies[1]
                Aim.Target = pick.plr
                Aim.IdleSince = nil
            else
                Aim.Target = nil
                Aim.IdleSince = Aim.IdleSince or now
                if now - Aim.IdleSince >= IDLE_OFF_AFTER then
                    notifyOnce("aimIdle", "Aimbot", "Sem inimigos por perto. Aimbot desligado.")
                    setAimActive(false)
                end
            end
        end
        return
    end

    Aim.Part = part
    Aim.LastLock = now
    Aim.IdleSince = nil

    local camPos = cam.CFrame.Position
    if (part.Position - camPos).Magnitude > 0.1 then
        local goal = CFrame.lookAt(camPos, part.Position)
        if Aim.Smooth > 0 then
            local alpha = 1 - (Aim.Smooth / 100) ^ (dt * 60)
            cam.CFrame = cam.CFrame:Lerp(goal, alpha)
        else
            cam.CFrame = goal
        end
    end
    updateAimDot(cam, part)
end)

-- Personagem sempre virado pro alvo
connect(RunService.Heartbeat, function()
    if not (Aim.Enabled and Aim.Active and Aim.FaceTarget and Aim.Part and Aim.Part.Parent) then
        return
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) or hum.Health <= 0 then
        return
    end

    local p = Aim.Part.Position
    local flat = Vector3.new(p.X, root.Position.Y, p.Z)
    if (flat - root.Position).Magnitude > 0.5 then
        root.CFrame = CFrame.lookAt(root.Position, flat)
    end
end)

----------------------------------------------------------------
-- Player: Shift Lock
----------------------------------------------------------------
local Shift = {
    Active = false, -- ligado pelo toggle da aba Player
    Offset = Vector3.new(1.75, 0, 0), -- câmera por cima do ombro (igual ao Shift Lock do Roblox)
    Saved = setmetatable({}, { __mode = "k" }), -- Humanoid -> AutoRotate e CameraOffset de antes
}

-- Devolve o personagem ao que era antes do Shift Lock
local function restoreShift(hum)
    local saved = hum and Shift.Saved[hum]
    if not saved then
        return
    end
    Shift.Saved[hum] = nil
    pcall(function()
        hum.AutoRotate = saved.AutoRotate
        hum.CameraOffset = saved.CameraOffset
    end)
end

local function setShiftActive(active)
    Shift.Active = active
    if not active then
        local char = LocalPlayer.Character
        restoreShift(char and char:FindFirstChildOfClass("Humanoid"))
    end
end

-- Roda logo depois da câmera: o personagem vira pra onde a câmera aponta
pcall(function()
    RunService:UnbindFromRenderStep("BukShift")
end)
RunService:BindToRenderStep("BukShift", Enum.RenderPriority.Camera.Value + 2, function()
    if not Shift.Active then
        return
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local cam = Workspace.CurrentCamera
    if not (hum and root and cam) or hum.Health <= 0 or hum.Sit then
        return
    end

    if not Shift.Saved[hum] then
        Shift.Saved[hum] = { AutoRotate = hum.AutoRotate, CameraOffset = hum.CameraOffset }
    end
    hum.AutoRotate = false
    hum.CameraOffset = hum.CameraOffset:Lerp(Shift.Offset, 0.3)

    -- Com o Aimbot travado, vira pro alvo; senão, pra onde a câmera aponta
    local dir = cam.CFrame.LookVector
    if Aim.Enabled and Aim.Active and Aim.Part and Aim.Part.Parent then
        dir = Aim.Part.Position - root.Position
    end
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude > 0.01 then
        root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
    end
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
end)

-- Se o jogo trocar a câmera, passa a vigiar a nova
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    watchFOV()
    applyFOV()
end)

----------------------------------------------------------------
-- Unload
----------------------------------------------------------------
local function destroyGui(gui)
    if gui then
        pcall(function()
            gui:Destroy()
        end)
    end
end

local function Unload()
    State.CFrameSpeed = false
    Aim.Enabled = false
    Aim.Active = false
    Aim.Target = nil
    Aim.Part = nil
    setShiftActive(false)
    setFOVEnabled(false)
    setCamLockEnabled(false)
    for _, name in ipairs({ "BukFOV", "BukAim", "BukShift" }) do
        pcall(function()
            RunService:UnbindFromRenderStep(name)
        end)
    end

    destroyGui(AimGui)
    destroyGui(SwitchGui)
    destroyGui(AimDotGui)
    AimGui, AimButton = nil, nil
    SwitchGui, SwitchButton = nil, nil
    AimDotGui, AimDotFrame = nil, nil
    table.clear(Allies.Manual)

    for _, key in ipairs({ "Name", "Health", "Distance", "BoxCorner", "Tracer", "TeamCheck" }) do
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

-- Janela sólida por padrão: com transparência, o jogo aparecia "fantasma" por trás do menu.
-- Dá pra ligar em Settings > Aparência.
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

-- Botão de abrir o menu (celular) no mesmo estilo escuro do tema
pcall(function()
    Window:EditOpenButton({
        Title = "Buk",
        Icon = "swords",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("#ffffff"), Color3.fromHex("#8a8a93")),
    })
end)

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
            return CM:Config("Buk_Duelos")
        end
        return CM:CreateConfig("Buk_Duelos")
    end)
    if ok then
        Config = result
    end
end

----------------------------------------------------------------
-- 1. Main (Trocar de Servidor)
----------------------------------------------------------------
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
})

local HopSection = MainTab:Section({ Title = "Servidor", Opened = true })

HopSection:Dropdown({
    Title = "Servidor de destino",
    Values = { "Mais cheio", "Mais vazio", "Aleatório" },
    Value = "Mais cheio",
    Flag = "hop_mode",
    Callback = function(selected)
        Hop.Mode = selected
    end,
})

HopSection:Button({
    Title = "Trocar de Servidor",
    Icon = "server",
    Callback = function()
        confirmHop()
    end,
})

----------------------------------------------------------------
-- 2. Aimbot (1v1 e 2v2)
----------------------------------------------------------------
local AimTab = Window:Tab({
    Title = "Aimbot",
    Icon = "crosshair",
})

----- Aimbot -----
local AimMainSection = AimTab:Section({ Title = "Aimbot", Opened = true })

AimMainSection:Toggle({
    Title = "Aimbot",
    Desc = "Mostra o botão AIM na tela. Aperte nele no começo da luta.",
    Icon = "crosshair",
    Flag = "aim_enabled",
    Value = false,
    Callback = function(state)
        setAimEnabled(state)
    end,
})

AimMainSection:Dropdown({
    Title = "Modo da partida",
    Desc = "Limite de players por perto pra ligar (1v1=1, 2v2=3, 3v3=5, 4v4=7). 4v4 serve pra todos os modos. A partir do 2v2 aparece o botão TROCA ALVO.",
    Values = { "1v1", "2v2", "3v3", "4v4" },
    Value = "4v4",
    Flag = "aim_mode",
    Callback = function(selected)
        Aim.Mode = selected
        refreshSwitchVisibility()
    end,
})

AimMainSection:Toggle({
    Title = "Travar Botões",
    Desc = "Impede de arrastar os botões da tela sem querer.",
    Flag = "aim_button_locked",
    Value = false,
    Callback = function(state)
        Aim.ButtonLocked = state
    end,
})

----- Mira -----
local AimCfgSection = AimTab:Section({ Title = "Mira", Opened = true })

AimCfgSection:Dropdown({
    Title = "Mirar em",
    Values = { "Corpo", "Cabeça" },
    Value = "Corpo",
    Flag = "aim_part",
    Callback = function(selected)
        Aim.PartName = (selected == "Cabeça") and "Head" or "HumanoidRootPart"
    end,
})

AimCfgSection:Dropdown({
    Title = "Primeiro alvo",
    Desc = "Qual inimigo o aimbot pega quando você aperta AIM.",
    Values = { "Perto de mim", "Perto da mira" },
    Value = "Perto de mim",
    Flag = "aim_pick",
    Callback = function(selected)
        Aim.Pick = selected
    end,
})

AimCfgSection:Dropdown({
    Title = "Ao matar o alvo",
    Desc = "Quem o aimbot pega quando o alvo morre. Sempre um inimigo vivo, nunca o seu time.",
    Values = { "Aleatório", "Perto de mim", "Perto da mira" },
    Value = "Aleatório",
    Flag = "aim_on_kill",
    Callback = function(selected)
        Aim.OnKill = selected
    end,
})

AimCfgSection:Slider({
    Title = "Suavidade",
    Desc = "0 = trava total. Quanto maior, mais devagar a câmera gira pro alvo.",
    Flag = "aim_smooth",
    Step = 1,
    Value = { Min = 0, Max = 90, Default = 0 },
    Callback = function(value)
        Aim.Smooth = math.clamp(value, 0, 90)
    end,
})

AimCfgSection:Slider({
    Title = "Alcance",
    Desc = "Só procura alvo dentro dessa distância. Diminua se tiver outra arena perto.",
    Flag = "aim_range",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(value)
        Aim.MaxDistance = value
    end,
})

AimCfgSection:Toggle({
    Title = "Checar parede",
    Desc = "Ignora inimigo que está atrás de parede na hora de escolher o alvo.",
    Flag = "aim_wallcheck",
    Value = false,
    Callback = function(state)
        Aim.WallCheck = state
    end,
})

AimCfgSection:Toggle({
    Title = "Personagem olha pro alvo",
    Flag = "aim_face_target",
    Value = true,
    Callback = function(state)
        Aim.FaceTarget = state
    end,
})

----- Aliados (2v2 a 4v4) -----
local AimAllySection = AimTab:Section({ Title = "Aliados (2v2 a 4v4)", Opened = true })

AimAllySection:Button({
    Title = "Marcar alvo atual como aliado",
    Desc = "Use se o aimbot travar no seu parceiro: marca ele e já pula pro próximo inimigo.",
    Icon = "user-check",
    Callback = function()
        markCurrentAsAlly()
    end,
})

AimAllySection:Button({
    Title = "Marcar Aliado (mais perto)",
    Desc = "Marca quem está mais perto de você e ainda não é aliado. Aperte de novo pra marcar o próximo.",
    Icon = "users",
    Callback = function()
        markNearestAsAlly()
    end,
})

AimAllySection:Button({
    Title = "Limpar Aliados",
    Icon = "eraser",
    Callback = function()
        clearAllies()
    end,
})

AimAllySection:Button({
    Title = "Copiar info dos players",
    Desc = "Diagnóstico: se o aimbot errar o time, aperte aqui e cole o texto no chat pra eu ajustar.",
    Icon = "clipboard",
    Callback = function()
        dumpPlayers()
    end,
})

----- Visual da mira -----
local AimDotSection = AimTab:Section({ Title = "Visual da mira", Opened = false })

AimDotSection:Dropdown({
    Title = "Tamanho da mira",
    Values = { "Fino", "Médio", "Grosso", "Grande" },
    Value = "Médio",
    Flag = "aim_dot_size",
    Callback = function(selected)
        setAimDotSize(AIM_DOT_SIZES[selected] or AIM_DOT_SIZES["Médio"])
    end,
})

AimDotSection:Colorpicker({
    Title = "Cor do ponto",
    Flag = "aim_dot_color",
    Default = Color3.fromRGB(255, 60, 60),
    Callback = function(color)
        setAimDotColor(color)
    end,
})

----------------------------------------------------------------
-- 3. Player (CFrame)
----------------------------------------------------------------
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

PlayerTab:Toggle({
    Title = "CFrame Speed",
    Icon = "zap",
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
    Value = { Min = 1, Max = 1000, Default = 30 },
    Callback = function(value)
        State.SpeedValue = math.clamp(value, 1, 1000)
    end,
})

PlayerTab:Toggle({
    Title = "Shift Lock",
    Icon = "lock",
    Flag = "shift_lock",
    Value = false,
    Callback = function(state)
        setShiftActive(state)
    end,
})

----------------------------------------------------------------
-- 4. Esp
----------------------------------------------------------------
local EspTab = Window:Tab({
    Title = "Esp",
    Icon = "eye",
})

----- Mostrar -----
local EspShowSection = EspTab:Section({ Title = "Mostrar", Opened = true })

EspShowSection:Toggle({
    Title = "Esp Name",
    Icon = "user",
    Flag = "esp_name",
    Value = false,
    Callback = function(state)
        State.ESP.Name = state
    end,
})

EspShowSection:Toggle({
    Title = "Esp Health",
    Icon = "heart",
    Flag = "esp_health",
    Value = false,
    Callback = function(state)
        State.ESP.Health = state
    end,
})

EspShowSection:Toggle({
    Title = "Esp Distância",
    Icon = "ruler",
    Flag = "esp_distance",
    Value = false,
    Callback = function(state)
        State.ESP.Distance = state
    end,
})

EspShowSection:Toggle({
    Title = "Esp Box Corner",
    Icon = "scan",
    Flag = "esp_box_corner",
    Value = false,
    Callback = function(state)
        State.ESP.BoxCorner = state
    end,
})

EspShowSection:Toggle({
    Title = "Esp Linha",
    Icon = "route",
    Flag = "esp_tracer",
    Value = false,
    Callback = function(state)
        State.ESP.Tracer = state
    end,
})

----- Ajustes -----
local EspCfgSection = EspTab:Section({ Title = "Ajustes", Opened = true })

EspCfgSection:Colorpicker({
    Title = "Cor do Esp",
    Flag = "esp_color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        State.ESP.Color = color
    end,
})

EspCfgSection:Slider({
    Title = "Distância máxima",
    Flag = "esp_max_distance",
    Step = 50,
    Value = { Min = 100, Max = 5000, Default = 2000 },
    Callback = function(value)
        State.ESP.MaxDistance = value
    end,
})

EspCfgSection:Toggle({
    Title = "Ignorar Aliados",
    Icon = "users",
    Flag = "esp_team_check",
    Value = false,
    Callback = function(state)
        State.ESP.TeamCheck = state
    end,
})

----------------------------------------------------------------
-- 5. Mod (Câmera)
----------------------------------------------------------------
local ModTab = Window:Tab({
    Title = "Mod",
    Icon = "wrench",
})

----- Câmera -----
local CamSection = ModTab:Section({ Title = "Câmera", Opened = true })

CamSection:Toggle({
    Title = "FOV",
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
-- 6. Settings
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
        Content = "Seu executor não suporta a Drawing API. O Esp não vai funcionar (o Aimbot funciona normal).",
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
