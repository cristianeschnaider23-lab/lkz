-- LKZ Painel PC - interface local e controles sem biblioteca remota.
local OrionLib = {}
local controlDescriptions = {
    ["Team check"] = "Universal: exclui aliados da selecao de mira quando o jogo usa Teams do Roblox. Jogadores neutros continuam elegiveis. Nao reconhece times personalizados.",
    ["Distancia maxima"] = "Universal: limita a distancia fisica dos alvos em studs. Zero desativa o limite.",
    ["Poeira no fundo"] = "Painel: mostra pequenas particulas pretas flutuando atras dos controles.",
    ["Quantidade de particulas"] = "Painel: controla a quantidade de pontos de poeira. Menos pontos reduzem o custo visual.",
    ["Ativar ESP RGB"] = "Universal: destaca outros personagens com cores RGB, inclusive atraves de paredes. Depende de personagens compativeis com Highlight.",
    ["Velocidade RGB"] = "Universal: controla a velocidade da troca de cores do ESP.",
    ["Transparencia do preenchimento"] = "Universal: 0% deixa o preenchimento solido; 100% deixa apenas o contorno.",
    ["Ativar Aimbot"] = "Universal: segure a tecla de mira configurada para orientar a camera para a cabeca do jogador fisicamente mais proximo dentro do FOV. Nao altera projeteis ou dano.",
    ["Mostrar circulo FOV"] = "Universal: mostra a area de selecao da mira. Requer Drawing no executor.",
    ["Raio do FOV"] = "Universal: tamanho em pixels da area ao redor do mouse usada para selecionar alvos.",
    ["Forca da mira"] = "Universal: valores maiores orientam a camera mais rapidamente para o alvo.",
    ["Animacao do fundo"] = "Painel: liga ou pausa o movimento do gradiente vermelho e preto.",
    ["Velocidade da animacao"] = "Painel: ajusta o ritmo de movimento do fundo.",
    ["Escala do painel"] = "Painel: aumenta ou reduz o tamanho da interface.",
    ["Centralizar janela"] = "Painel: reposiciona a janela no centro da tela.",
    ["Salvar configuracoes agora"] = "Painel: grava as opcoes atuais no arquivo local do executor.",
    ["Encerrar painel"] = "Painel: remove a interface, os destaques e as conexoes ativas."
}
local HttpService = game:GetService("HttpService")
local configPath = "LKZ_PC_Config_v1.json"
local preferences, saveGeneration = {}, 0
local fileSupport = type(readfile) == "function" and type(writefile) == "function"
if fileSupport then
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(configPath))
    end)
    if ok and type(decoded) == "table" then preferences = decoded end
end
local function saveNow()
    if type(writefile) ~= "function" then return false end
    local ok = pcall(function()
        writefile(configPath, HttpService:JSONEncode(preferences))
    end)
    return ok
end
local function remember(key, value)
    if preferences[key] == value then return end
    preferences[key] = value
    saveGeneration = saveGeneration + 1
    local generation = saveGeneration
    task.delay(0.4, function()
        if generation == saveGeneration then saveNow() end
    end)
end
do
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local player = Players.LocalPlayer
    local root, window, content, navigation
    local listeners, tabs = {}, {}
    local animationEnabled, animationSpeed = true, 1
    local dustEnabled, dustAmount = true, 24
    local bindingCapture = nil
    local function on(signal, fn)
        local c = signal:Connect(fn)
        table.insert(listeners, c)
        return c
    end
    local function make(class, properties, parent)
        local instance = Instance.new(class)
        for k, v in pairs(properties) do instance[k] = v end
        instance.Parent = parent
        return instance
    end
    local function round(object, radius)
        make("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, object)
    end
    local function text(parent, value, size)
        return make("TextLabel", {BackgroundTransparency = 1, Text = value,
            TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamMedium,
            TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
            Size = size or UDim2.new(1,-16,1,0), Position = UDim2.fromOffset(8,0)}, parent)
    end
    local function button(parent, value, size, position)
        local b = make("TextButton", {Text = value, Size = size, Position = position or UDim2.new(),
            BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
            TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamMedium,
            TextSize = 14, AutoButtonColor = true}, parent)
        round(b)
        make("UIGradient", {Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(4,4,6)),
            ColorSequenceKeypoint.new(0.7,Color3.fromRGB(12,7,10)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(62,7,17))
        }), Rotation = 15}, b)
        -- O gradiente afeta o desenho do TextButton, mas nao o texto deste filho.
        b.TextTransparency = 1
        local caption = make("TextLabel", {Name = "ReadableCaption", BackgroundTransparency = 1,
            Size = UDim2.new(1,-12,1,0), Position = UDim2.fromOffset(6,0),
            Text = b.Text, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamMedium,
            TextSize = 14, TextWrapped = true, TextStrokeColor3 = Color3.new(0,0,0),
            TextStrokeTransparency = 0.65, Active = false, ZIndex = b.ZIndex + 1}, b)
        on(b:GetPropertyChangedSignal("Text"), function() caption.Text = b.Text end)
        on(b:GetPropertyChangedSignal("Font"), function()
            caption.Font = b.Font == Enum.Font.Gotham and Enum.Font.GothamMedium or b.Font
        end)
        on(b:GetPropertyChangedSignal("ZIndex"), function() caption.ZIndex = b.ZIndex + 1 end)
        make("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1, Transparency = 0.05, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
        return b
    end
    local function invoke(fn, value)
        if not fn then return true end
        local ok, err = pcall(fn, value)
        if not ok then warn("[LKZ Painel] " .. tostring(err)) end
        return ok
    end
    function OrionLib:Destroy()
        for _, c in ipairs(listeners) do c:Disconnect() end
        table.clear(listeners)
        if root then root:Destroy() root = nil end
    end
    function OrionLib:MakeNotification(options)
        warn("[LKZ Painel] " .. tostring(options.Content))
        if root then
            local label = text(root, options.Content, UDim2.new(0,590,0,48))
            label.Position = UDim2.new(0.5,-295,1,-65)
            label.BackgroundTransparency = 0
            label.BackgroundColor3 = Color3.fromRGB(28,28,28)
            label.TextWrapped = true
            round(label)
            task.delay(options.Time or 5, function() label:Destroy() end)
        end
    end
    function OrionLib:MakeWindow(options)
        root = make("ScreenGui", {Name = "LKZPainelPC", ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100}, player:WaitForChild("PlayerGui"))
        window = make("Frame", {Size = UDim2.fromOffset(615,390),
            Position = UDim2.new(0.5,-307,0.5,-195), BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel = 0}, root)
        round(window, 12)
        make("UIStroke", {Color = Color3.new(0,0,0), Thickness = 3, Transparency = 0}, window)
        local gradient = make("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(210,12,30)),
                ColorSequenceKeypoint.new(0.32, Color3.fromRGB(95,6,18)),
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(22,5,11)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(5,5,9))
            }), Rotation = 32
        }, window)
        -- Camadas decorativas ficam atras da interface e nao capturam cliques.
        local backdrop = make("Frame", {Name = "AnimatedBackdrop", Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1, Active = false}, window)
        round(backdrop,12)
        local ribbons = {}
        for i = 1, 3 do
            local ribbon = make("Frame", {AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.fromScale(0.4,0.5), Size = UDim2.fromScale(1.8,0.85),
                BackgroundColor3 = i == 2 and Color3.fromRGB(1,1,3) or Color3.fromRGB(240,8,28),
                BackgroundTransparency = i == 2 and 0.3 or 0.73,
                BorderSizePixel = 0, ZIndex = 1, Active = false}, backdrop)
            make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.5,0.05),
                NumberSequenceKeypoint.new(1,1)
            })}, ribbon)
            ribbons[i] = ribbon
        end
        local dust = {}
        local random = Random.new(2819)
        for i = 1, 32 do
            local size = random:NextInteger(2,6)
            local dot = make("Frame", {Name = "Dust", Size = UDim2.fromOffset(size,size),
                BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.3,
                BorderSizePixel = 0, ZIndex = 2, Active = false}, backdrop)
            round(dot, size)
            dust[i] = {object = dot, x = random:NextNumber(0.03,0.97),
                y = random:NextNumber(), speed = random:NextNumber(0.015,0.035),
                phase = random:NextNumber(0, math.pi*2)}
        end
        -- Pool fixo: nenhum objeto ou conexao e criado por quadro. Pausa com a janela oculta.
        local elapsed, budget = 0, 0
        on(game:GetService("RunService").Heartbeat, function(dt)
            if not window.Visible or not root.Enabled then return end
            if animationEnabled then elapsed = elapsed + dt * animationSpeed end
            budget = budget + dt
            if budget < 1/30 then return end
            budget = budget % (1/30)
            gradient.Rotation = 32 + math.sin(elapsed * 0.24) * 36
            gradient.Offset = Vector2.new(math.sin(elapsed * 0.31) * 0.22, math.cos(elapsed * 0.22) * 0.17)
            for i, ribbon in ipairs(ribbons) do
                ribbon.Position = UDim2.fromScale(0.5 + math.sin(elapsed * 0.16 + i*2) * 0.23,
                    0.5 + math.cos(elapsed * 0.2 + i) * 0.35)
                ribbon.Rotation = -32 + math.sin(elapsed * 0.12 + i) * 24
            end
            for i, particle in ipairs(dust) do
                local dot = particle.object
                dot.Visible = dustEnabled and i <= dustAmount
                if dot.Visible then
                    dot.Position = UDim2.fromScale(math.clamp(particle.x + math.sin(elapsed*0.3+particle.phase)*0.035,0.025,0.975),
                        0.03 + ((particle.y-elapsed*particle.speed)%1)*0.92)
                    dot.BackgroundTransparency = 0.25 + (math.sin(elapsed*0.55+particle.phase)+1)*0.2
                end
            end
        end)
        local divider = make("Frame", {Position = UDim2.fromOffset(14,48),
            Size = UDim2.new(1,-28,0,1), BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.05, ZIndex = 5}, window)
        -- Atalho da janela configurado na aba Aparencia.
        local title = text(window, options.Name, UDim2.new(1,-90,0,48))
        title.ZIndex = 5
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        local close = button(window,"X",UDim2.fromOffset(32,30),UDim2.new(1,-40,0,8))
        close.ZIndex = 5
        on(close.Activated,function()
            if options.CloseCallback then invoke(options.CloseCallback) else self:Destroy() end
        end)
        navigation = make("Frame",{Position = UDim2.fromOffset(8,55),
            Size = UDim2.new(0,140,1,-63),BackgroundTransparency = 1, ZIndex = 5},window)
        make("UIListLayout",{Padding = UDim.new(0,6)},navigation)
        content = make("Frame",{Position = UDim2.fromOffset(158,55),
            Size = UDim2.new(1,-166,1,-63),BackgroundTransparency = 1, ZIndex = 5},window)
        local dragging, startMouse, startPosition
        title.Active = true
        on(title.InputBegan,function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true startMouse = UIS:GetMouseLocation() startPosition = window.Position
            end
        end)
        on(UIS.InputEnded,function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        on(UIS.InputChanged,function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = UIS:GetMouseLocation() - startMouse
                window.Position = startPosition + UDim2.fromOffset(delta.X,delta.Y)
            end
        end)
        local api = {}
        function api:MakeTab(settings)
            local page = make("ScrollingFrame",{Size = UDim2.fromScale(1,1),
                BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.new(0,0,0),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = #tabs == 0},content)
            make("UIListLayout",{Padding = UDim.new(0,6),SortOrder = Enum.SortOrder.LayoutOrder},page)
            local selector = button(navigation,settings.Name,UDim2.new(1,0,0,34))
            selector.BackgroundTransparency = 0
            selector.BackgroundColor3 = Color3.new(1,1,1)
            selector.Font = #tabs == 0 and Enum.Font.GothamBold or Enum.Font.Gotham
            table.insert(tabs,{page = page,button = selector})
            on(selector.Activated,function()
                for _, item in ipairs(tabs) do
                    item.page.Visible = item.page == page
                    item.button.BackgroundTransparency = 0
                    item.button.BackgroundColor3 = Color3.new(1,1,1)
                    item.button.Font = item.page.Visible and Enum.Font.GothamBold or Enum.Font.Gotham
                    local tabGradient = item.button:FindFirstChildOfClass("UIGradient")
                    if tabGradient then tabGradient.Rotation = item.page.Visible and 15 or 65 end
                end
            end)
            local tab, order = {}, 0
            local function row(height)
                order = order + 1
                local r = make("Frame",{Size = UDim2.new(1,-7,0,height),
                    BackgroundColor3 = Color3.fromRGB(9,8,11),BorderSizePixel = 0,
                    LayoutOrder = order, BackgroundTransparency = 0.17},page)
                round(r, 8)
                make("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1.5, Transparency = 0.05}, r)
                local accent = make("Frame", {Size = UDim2.new(0,2,1,-16), Position = UDim2.fromOffset(0,8),
                    BackgroundColor3 = Color3.new(0,0,0), BorderSizePixel = 0}, r)
                round(accent, 2)
                return r
            end
            function tab:AddGameInfo()
                local card = row(100)
                local fallback = text(card, "JOGO", UDim2.fromOffset(76,76))
                fallback.Position = UDim2.fromOffset(12,12)
                fallback.TextXAlignment = Enum.TextXAlignment.Center
                local image = make("ImageLabel", {Size = UDim2.fromOffset(76,76),
                    Position = UDim2.fromOffset(12,12), BackgroundTransparency = 1,
                    Image = game.GameId > 0 and ("rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150") or ""}, card)
                round(image,8)
                local name = text(card, "Carregando nome do jogo...", UDim2.new(1,-112,0,48))
                name.Position = UDim2.fromOffset(100,10)
                name.TextWrapped = true
                name.Font = Enum.Font.GothamBold
                local ids = text(card, "Place: " .. tostring(game.PlaceId), UDim2.new(1,-112,0,26))
                ids.Position = UDim2.fromOffset(100,62)
                task.spawn(function()
                    local market = game:GetService("MarketplaceService")
                    local ok, info = pcall(function()
                        return market:GetProductInfoAsync(game.PlaceId, Enum.InfoType.Asset)
                    end)
                    if not ok then
                        ok, info = pcall(function() return market:GetProductInfo(game.PlaceId) end)
                    end
                    if name.Parent then
                        name.Text = ok and type(info) == "table" and tostring(info.Name or "Nome indisponivel") or "Nome indisponivel"
                    end
                end)
            end
            function tab:AddSection(s) text(row(28),s.Name) return self end
            function tab:AddParagraph(heading, body)
                local label = text(row(76),heading .. "\n" .. body)
                label.TextWrapped = true
            end
            function tab:AddBind(s)
                local r = row(40)
                text(r,s.Name,UDim2.new(1,-160,1,0))
                local selectKey = button(r,"",UDim2.fromOffset(140,28),UDim2.new(1,-148,0,6))
                local key = settings.Name .. ":bind:" .. s.Name
                local value = type(preferences[key]) == "string" and preferences[key] or (s.Default or "None")
                local validMouse = {MouseButton1 = true, MouseButton2 = true, MouseButton3 = true}
                local function valid(name)
                    if name == "None" or validMouse[name] then return true end
                    local ok = pcall(function() return Enum.KeyCode[name] end)
                    return ok
                end
                if not valid(value) then value = s.Default or "None" end
                local function display() selectKey.Text = value == "None" and "Sem tecla" or value end
                local function set(name)
                    if not valid(name) then return end
                    value = name
                    remember(key,name)
                    display()
                end
                local function matches(input)
                    return input.KeyCode.Name == value or input.UserInputType.Name == value
                end
                on(selectKey.Activated,function()
                    if bindingCapture then bindingCapture.cancel() end
                    bindingCapture = {owner = selectKey, cancel = display}
                    selectKey.Text = "Tecla? Esc limpa"
                end)
                on(UIS.InputBegan,function(input,processed)
                    if bindingCapture then
                        if bindingCapture.owner ~= selectKey then return end
                        local chosen = input.KeyCode.Name
                        if chosen == "Escape" then chosen = "None"
                        elseif chosen == "Unknown" then
                            chosen = input.UserInputType.Name
                            if not s.AllowMouse or not validMouse[chosen] then return end
                        end
                        set(chosen)
                        -- Bloqueia outros atalhos durante este mesmo evento.
                        local captured = bindingCapture
                        task.defer(function() if bindingCapture == captured then bindingCapture = nil end end)
                        return
                    end
                    if processed or UIS:GetFocusedTextBox() or value == "None" then return end
                    if matches(input) and s.Callback then invoke(s.Callback) end
                end)
                display()
                return {Set = function(_,v) set(v) end, IsDown = function()
                    if bindingCapture or UIS:GetFocusedTextBox() or value == "None" then return false end
                    if validMouse[value] then return UIS:IsMouseButtonPressed(Enum.UserInputType[value]) end
                    return UIS:IsKeyDown(Enum.KeyCode[value])
                end}
            end
            function tab:AddToggle(s)
                if controlDescriptions[s.Name] then self:AddParagraph("Sobre esta funcao", controlDescriptions[s.Name]) end
                local r = row(40)
                text(r,s.Name,UDim2.new(1,-55,1,0))
                local hit = button(r,"",UDim2.fromScale(1,1))
                hit.BackgroundTransparency = 1
                local box = make("TextLabel",{Position = UDim2.new(1,-34,0,8),
                    Size = UDim2.fromOffset(24,24), BackgroundColor3 = Color3.fromRGB(63,29,39),
                    Text = "", TextColor3 = Color3.new(1,1,1),TextSize = 18,
                    Font = Enum.Font.GothamBold,BorderSizePixel = 0},hit)
                round(box,4)
                local key = settings.Name .. ":" .. s.Name
                local saved = preferences[key]
                local value = type(saved) == "boolean" and saved or s.Default == true
                if type(saved) == "boolean" then value = saved end
                local function set(v)
                    value = v == true
                    box.Text = value and "✓" or ""
                    box.BackgroundColor3 = value and Color3.fromRGB(205,24,50) or Color3.fromRGB(63,29,39)
                    invoke(s.Callback,value)
                    remember(key,value)
                end
                on(hit.Activated,function() set(not value) end)
                set(value)
                self:AddBind({Name = "Atalho: " .. s.Name, Callback = function() set(not value) end})
                return {Set = function(_,v) set(v) end}
            end
            function tab:AddSlider(s)
                if controlDescriptions[s.Name] then self:AddParagraph("Sobre este ajuste", controlDescriptions[s.Name]) end
                local r = row(64)
                local label = text(r,"",UDim2.new(1,-16,0,26))
                local bar = button(r,"",UDim2.new(1,-20,0,18),UDim2.fromOffset(10,35))
                local fill = make("Frame",{BackgroundColor3 = Color3.fromRGB(225,35,60),
                    BorderSizePixel = 0,Size = UDim2.new()},bar)
                round(fill)
                local key = settings.Name .. ":" .. s.Name
                local saved = preferences[key]
                local value, sliding = type(saved) == "number" and saved == saved and saved or s.Default, false
                local function set(v)
                    local step = s.Increment or 1
                    value = math.clamp(s.Min + math.floor((v-s.Min)/step+0.5)*step,s.Min,s.Max)
                    fill.Size = UDim2.fromScale((value-s.Min)/(s.Max-s.Min),1)
                    label.Text = s.Name .. ": " .. tostring(value) .. " " .. (s.ValueName or "")
                    invoke(s.Callback,value)
                    remember(key,value)
                end
                local function move()
                    local inset = game:GetService("GuiService"):GetGuiInset()
                    local x = UIS:GetMouseLocation().X - inset.X
                    set(s.Min + math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)*(s.Max-s.Min))
                end
                on(bar.InputBegan,function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true move() end
                end)
                on(UIS.InputChanged,function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then move() end
                end)
                on(UIS.InputEnded,function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
                set(value)
                return {Set = function(_,v) set(v) end}
            end
            function tab:AddButton(s)
                if controlDescriptions[s.Name] then self:AddParagraph("Sobre esta acao", controlDescriptions[s.Name]) end
                local r = row(38)
                local b = button(r,s.Name,UDim2.fromScale(1,1))
                on(b.Activated,function() invoke(s.Callback) end)
            end
            return tab
        end
        self._initVisual = function()
            local visual = api:MakeTab({Name = "Aparencia"})
            visual:AddSection({Name = "PERSONALIZAR PAINEL"})
            visual:AddBind({Name = "Mostrar / ocultar janela", Default = "Insert", Callback = function() window.Visible = not window.Visible end})
            visual:AddToggle({Name = "Animacao do fundo", Default = true, Callback = function(v) animationEnabled = v end})
            visual:AddToggle({Name = "Poeira no fundo", Default = true, Callback = function(v) dustEnabled = v end})
            visual:AddSlider({Name = "Quantidade de particulas", Min = 0, Max = 32, Default = 24,
                Increment = 1, ValueName = "particulas", Callback = function(v) dustAmount = v end})
            visual:AddSlider({Name = "Velocidade da animacao", Min = 10, Max = 200, Default = 100,
                Increment = 5, ValueName = "%", Callback = function(v) animationSpeed = v / 100 end})
            visual:AddSlider({Name = "Escala do painel", Min = 70, Max = 120, Default = 100,
                Increment = 5, ValueName = "%", Callback = function(v)
                    local scale = window:FindFirstChildOfClass("UIScale")
                    if not scale then scale = make("UIScale", {}, window) end
                    scale.Scale = v / 100
                end})
            visual:AddButton({Name = "Centralizar janela", Callback = function()
                window.AnchorPoint = Vector2.new(0.5,0.5)
                window.Position = UDim2.fromScale(0.5,0.5)
            end})
            visual:AddButton({Name = "Salvar configuracoes agora", Callback = function()
                self:MakeNotification({Content = saveNow() and "Configuracoes salvas." or "Nao foi possivel salvar. Verifique o suporte a arquivos do executor.", Time = 5})
            end})
            visual:AddParagraph("Configuracoes", fileSupport and "Suas ultimas opcoes sao restauradas ao executar, incluindo os controles de ESP e Aimbot." or "Sem leitura/escrita de arquivos neste ambiente. As opcoes ficam somente nesta sessao.")
        end
        return api
    end
    function OrionLib:Init()
        if self._initVisual then self._initVisual() end
    end
end

-- Integracao PC: ESP RGB e Aimbot.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local me = Players.LocalPlayer
local env = getgenv and getgenv() or _G
local previous = env.OrionPCController
if previous and previous.Destroy then previous.Destroy() end

local state = {
    esp = false, aim = false, showFOV = true,
    radius = 150, smooth = 0.35, speed = 0.2, transparency = 0.45, teamCheck = false, maxDistance = 0
}
local connections, tracked, highlights = {}, {}, {}
local circle, destroyed = nil, false
local controller = {}
env.OrionPCController = controller
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
local function removeHighlight(player)
    if highlights[player] then highlights[player]:Destroy() end
    highlights[player] = nil
end
local function applyHighlight(player, character)
    removeHighlight(player)
    if not state.esp or destroyed or player == me then return end
    local h = Instance.new("Highlight")
    h.Name = "OrionPC_RGB"
    h.Adornee = character
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency = state.transparency
    h.OutlineTransparency = 0
    h.FillColor = Color3.fromHSV((os.clock() * state.speed) % 1, 1, 1)
    h.OutlineColor = h.FillColor
    h.Parent = character
    highlights[player] = h
end
local function untrack(player)
    if tracked[player] then
        for _, c in ipairs(tracked[player]) do c:Disconnect() end
    end
    tracked[player] = nil
    removeHighlight(player)
end
local function track(player)
    if player == me or tracked[player] or not state.esp then return end
    tracked[player] = {
        player.CharacterAdded:Connect(function(character)
            applyHighlight(player, character)
        end),
        player.CharacterRemoving:Connect(function() removeHighlight(player) end)
    }
    if player.Character then applyHighlight(player, player.Character) end
end
local function setESP(value)
    state.esp = value and not destroyed
    if state.esp then
        for _, player in ipairs(Players:GetPlayers()) do track(player) end
    else
        local list = {}
        for player in pairs(tracked) do table.insert(list, player) end
        for _, player in ipairs(list) do untrack(player) end
    end
end
local function notify(message)
    OrionLib:MakeNotification({Name = "Orion PC", Content = message,
        Image = "rbxassetid://4483345998", Time = 6})
end
local function ensureCircle()
    if circle then return true end
    local ok, result = pcall(function()
        local c = Drawing.new("Circle")
        circle = c
        c.Thickness = 1.5
        c.Color = Color3.fromRGB(0, 255, 255)
        c.Filled = false
        c.Transparency = 0.8
        c.Visible = false
        return c
    end)
    if not ok then
        if circle then pcall(function() circle:Remove() end) end
        circle = nil
        return false
    end
    return result ~= nil
end
local function closestTarget(camera, mouse)
    local character = me.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local health = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not health or health.Health <= 0 then return nil end
    local closest, distance = nil, math.huge
    -- Viewport coordinates exclude the top GUI inset; mouse coordinates include it.
    local inset = GuiService:GetGuiInset()
    local viewportMouse = mouse - inset
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= me and not (state.teamCheck and not me.Neutral and not player.Neutral and me.Team ~= nil and player.Team == me.Team) then
            local model = player.Character
            local head = model and model:FindFirstChild("Head")
            local targetRoot = model and model:FindFirstChild("HumanoidRootPart")
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            if head and head:IsA("BasePart") and targetRoot and humanoid and humanoid.Health > 0 then
                local point, visible = camera:WorldToViewportPoint(head.Position)
                local screenDistance = (Vector2.new(point.X, point.Y) - viewportMouse).Magnitude
                if visible and screenDistance <= state.radius then
                    local physicalDistance = (targetRoot.Position - root.Position).Magnitude
                    if physicalDistance < distance and (state.maxDistance == 0 or physicalDistance <= state.maxDistance) then
                        closest, distance = head, physicalDistance
                    end
                end
            end
        end
    end
    return closest
end
function controller.Destroy()
    if destroyed then return end
    destroyed = true
    state.aim = false
    setESP(false)
    for _, c in ipairs(connections) do c:Disconnect() end
    table.clear(connections)
    if circle then pcall(function() circle:Remove() end) circle = nil end
    pcall(function() OrionLib:Destroy() end)
    if env.OrionPCController == controller then env.OrionPCController = nil end
end

local Window = OrionLib:MakeWindow({
    Name = "LKZ PAINEL | PC",
    HidePremium = true, SaveConfig = false, IntroEnabled = false,
    CloseCallback = function() controller.Destroy() end
})
local Home = Window:MakeTab({Name = "Inicio"})
Home:AddGameInfo()
Home:AddParagraph("Jogo atual", "Nome e icone identificados pelos IDs do Roblox. Isso identifica a experiencia, mas nao analisa suas mecanicas ou garante compatibilidade.")
Home:AddParagraph("Compatibilidade", "Universal indica uso de personagens e camera padrao do Roblox. Funcoes de um jogo especifico precisam de integracao propria.")
local ESP = Window:MakeTab({Name = "ESP", Icon = "rbxassetid://4483345998", PremiumOnly = false})
ESP:AddSection({Name = "ESP RGB"})
ESP:AddToggle({Name = "Ativar ESP RGB", Default = false, Callback = setESP})
ESP:AddSlider({Name = "Velocidade RGB", Min = 1, Max = 100, Default = 20,
    Increment = 1, ValueName = "%", Callback = function(v) state.speed = v / 100 end})
ESP:AddSlider({Name = "Transparencia do preenchimento", Min = 0, Max = 100,
    Default = 45, Increment = 1, ValueName = "%", Callback = function(v)
        state.transparency = v / 100
        for _, h in pairs(highlights) do h.FillTransparency = state.transparency end
    end})
local Aim = Window:MakeTab({Name = "Aimbot", Icon = "rbxassetid://4483345998", PremiumOnly = false})
Aim:AddParagraph("Como usar", "Ative e segure a tecla configurada abaixo (padrao: botao direito). Alvo: cabeca do jogador mais proximo do seu personagem dentro do FOV.")
Aim:AddToggle({Name = "Ativar Aimbot", Default = false, Callback = function(v)
    state.aim = v and not destroyed
    if state.aim and state.showFOV and not ensureCircle() then
        notify("Drawing indisponivel: o circulo FOV nao pode ser exibido neste ambiente.")
    end
    if circle then circle.Visible = state.aim and state.showFOV end
end})
local aimInput = Aim:AddBind({Name = "Segurar para mirar", Default = "MouseButton2", AllowMouse = true})
Aim:AddToggle({Name = "Team check", Default = false, Callback = function(v) state.teamCheck = v end})
Aim:AddSlider({Name = "Distancia maxima", Min = 0, Max = 5000, Default = 0,
    Increment = 50, ValueName = "studs (0 = sem limite)", Callback = function(v) state.maxDistance = v end})
Aim:AddToggle({Name = "Mostrar circulo FOV", Default = true, Callback = function(v)
    state.showFOV = v
    if v and state.aim and not ensureCircle() then notify("Drawing indisponivel neste ambiente.") end
    if circle then circle.Visible = v and state.aim end
end})
Aim:AddSlider({Name = "Raio do FOV", Min = 25, Max = 600, Default = 150,
    Increment = 1, ValueName = "px", Callback = function(v) state.radius = v end})
Aim:AddSlider({Name = "Forca da mira", Min = 1, Max = 100, Default = 35,
    Increment = 1, ValueName = "%", Callback = function(v) state.smooth = v / 100 end})
local Settings = Window:MakeTab({Name = "Configuracoes", Icon = "rbxassetid://4483345998", PremiumOnly = false})
Settings:AddParagraph("PC", "O atalho da janela pode ser alterado em Aparencia (padrao: Insert). Clique nos atalhos para escolher teclas; Esc remove o atalho. As opcoes sao salvas. Encerrar painel remove os efeitos.")
Settings:AddButton({Name = "Encerrar painel", Callback = controller.Destroy})
connect(Players.PlayerAdded, track)
connect(Players.PlayerRemoving, untrack)
connect(RunService.RenderStepped, function(dt)
    if destroyed then return end
    if state.esp then
        local color = Color3.fromHSV((os.clock() * state.speed) % 1, 1, 1)
        for player, h in pairs(highlights) do
            if h.Parent then h.FillColor = color h.OutlineColor = color
            else highlights[player] = nil end
        end
    end
    local camera = Workspace.CurrentCamera
    local mouse = UIS:GetMouseLocation()
    if circle then
        circle.Position = mouse
        circle.Radius = state.radius
        circle.Visible = state.aim and state.showFOV and camera ~= nil
    end
    if state.aim and camera and aimInput:IsDown()
        and UIS:GetFocusedTextBox() == nil then
        local target = closestTarget(camera, mouse)
        if target then
            local origin = camera.CFrame.Position
            if (target.Position - origin).Magnitude > 0.001 then
                -- Preserva a forca original a 60 FPS e ajusta para outras taxas.
                local alpha = 1 - (1 - state.smooth) ^ (math.min(dt, 0.1) * 60)
                camera.CFrame = camera.CFrame:Lerp(CFrame.new(origin, target.Position), alpha)
            end
        end
    end
end)
local initialized, initError = pcall(function() OrionLib:Init() end)
if not initialized then controller.Destroy() error(initError) end
