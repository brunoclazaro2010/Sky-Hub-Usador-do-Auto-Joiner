local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remove GUI antiga se existir
local oldGui = playerGui:FindFirstChild("DarkGeminiMenu")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopMenu"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- =============================================
--          SERVER HOP MENU (ÚNICA COISA MANTIDA)
-- =============================================

local folderName = "SkyHub"
local blacklistFile = folderName .. "/ServerBlacklist.json"
local serverBlacklist = {}

-- Carregar blacklist
local function loadBlacklist()
    if isfile and isfile(blacklistFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(blacklistFile))
        end)
        if success and type(data) == "table" then
            serverBlacklist = data
        end
    end
end

local function saveBlacklist()
    if writefile then
        writefile(blacklistFile, HttpService:JSONEncode(serverBlacklist))
    end
end

local function addServerToBlacklist(id)
    if not id then return end
    table.insert(serverBlacklist, id)
    if #serverBlacklist >= 300 then
        serverBlacklist = {}
    end
    saveBlacklist()
end

local function isBlacklisted(id)
    for _, v in pairs(serverBlacklist) do
        if v == id then return true end
    end
    return false
end

-- Criação da janela Server Hop
local hopFrame = Instance.new("Frame", screenGui)
hopFrame.Name = "ServerHopMenu"
hopFrame.Size = UDim2.new(0, 200, 0, 280)
hopFrame.Position = UDim2.new(0.5, -100, 0.5, -140)
hopFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Instance.new("UICorner", hopFrame).CornerRadius = UDim.new(0, 10)
hopFrame.ZIndex = 10

local hopStroke = Instance.new("UIStroke", hopFrame)
hopStroke.Thickness = 3
hopStroke.Color = Color3.fromRGB(255, 255, 255)

local hopTitle = Instance.new("TextLabel", hopFrame)
hopTitle.Size = UDim2.new(1, 0, 0, 40)
hopTitle.Text = "SERVER HOP"
hopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
hopTitle.Font = Enum.Font.GothamBold
hopTitle.TextSize = 16
hopTitle.BackgroundTransparency = 1
hopTitle.ZIndex = 11

local statusLabel = Instance.new("TextLabel", hopFrame)
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 45)
statusLabel.Text = "Status: Aguardando"
statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 11
statusLabel.BackgroundTransparency = 1
statusLabel.ZIndex = 11

-- Caixa de texto (valor mínimo)
local inputFrame = Instance.new("Frame", hopFrame)
inputFrame.Size = UDim2.new(0.9, 0, 0, 35)
inputFrame.Position = UDim2.new(0.05, 0, 0, 75)
inputFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 8)
inputFrame.ZIndex = 11

local hopTextBox = Instance.new("TextBox", inputFrame)
hopTextBox.Size = UDim2.new(1, -10, 1, 0)
hopTextBox.Position = UDim2.new(0, 5, 0, 0)
hopTextBox.BackgroundTransparency = 1
hopTextBox.PlaceholderText = "Valor mínimo (ex: 1000000)"
hopTextBox.Text = ""
hopTextBox.TextColor3 = Color3.fromRGB(255, 215, 0)
hopTextBox.Font = Enum.Font.GothamBold
hopTextBox.TextSize = 13
hopTextBox.ClearTextOnFocus = false
hopTextBox.ZIndex = 12

-- Botões
local startBtn = Instance.new("TextButton", hopFrame)
startBtn.Size = UDim2.new(0.9, 0, 0, 40)
startBtn.Position = UDim2.new(0.05, 0, 0, 125)
startBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
startBtn.Text = "INICIAR SERVER HOP"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 13
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)
startBtn.ZIndex = 11

local stopBtn = Instance.new("TextButton", hopFrame)
stopBtn.Size = UDim2.new(0.9, 0, 0, 40)
stopBtn.Position = UDim2.new(0.05, 0, 0, 175)
stopBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
stopBtn.Text = "PARAR"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 13
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)
stopBtn.ZIndex = 11

local autoBtn = Instance.new("TextButton", hopFrame)
autoBtn.Size = UDim2.new(0.9, 0, 0, 40)
autoBtn.Position = UDim2.new(0.05, 0, 0, 225)
autoBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
autoBtn.Text = "MODO AUTOMÁTICO: OFF"
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextSize = 13
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 8)
autoBtn.ZIndex = 11

-- Variáveis de controle
local hopActive = false
local autoModeEnabled = false

-- Função principal de Server Hop
local function doServerHop()
    if not hopActive then return end

    statusLabel.Text = "Status: Buscando servidores..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

    local placeId = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"

    local success, content = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not content then
        statusLabel.Text = "Status: Erro na conexão"
        if autoModeEnabled and hopActive then
            task.wait(3)
            doServerHop()
        end
        return
    end

    local decoded = HttpService:JSONDecode(content)

    if decoded and decoded.data then
        for _, server in ipairs(decoded.data) do
            if not hopActive then break end

            if server.playing < server.maxPlayers 
               and server.id ~= game.JobId 
               and not isBlacklisted(server.id) then
                
                addServerToBlacklist(server.id)
                statusLabel.Text = "Status: Teleportando..."
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)

                pcall(function()
                    if autoModeEnabled then
                        writefile(folderName .. "/AutoMode.txt", "true")
                    end
                    TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
                end)

                task.wait(2)
                return
            end
        end

        statusLabel.Text = "Status: Nenhum servidor livre encontrado"
        if autoModeEnabled and hopActive then
            task.wait(2)
            doServerHop()
        end
    else
        statusLabel.Text = "Status: Lista vazia, tentando novamente..."
        if autoModeEnabled and hopActive then
            task.wait(2)
            doServerHop()
        end
    end
end

-- Conexões dos botões
startBtn.MouseButton1Click:Connect(function()
    hopActive = true
    local target = tonumber(hopTextBox.Text)
    
    if not target or target < 100000 then
        statusLabel.Text = "Status: Digite um valor válido!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    statusLabel.Text = "Status: Verificando servidor..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

    task.wait(1)

    local highest = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:find("%$") then
            local val = tonumber(obj.Text:match("[%d%.]+")) or 0
            if obj.Text:find("k") then val *= 1000
            elseif obj.Text:find("m") then val *= 1000000
            elseif obj.Text:find("b") then val *= 1000000000 end
            if val > highest then highest = val end
        end
    end

    if highest >= target then
        statusLabel.Text = "Alvo encontrado! (" .. highest .. ")"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        statusLabel.Text = "Pulando servidor..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
        doServerHop()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    hopActive = false
    autoModeEnabled = false
    statusLabel.Text = "Status: Parado"
    statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
end)

autoBtn.MouseButton1Click:Connect(function()
    autoModeEnabled = not autoModeEnabled
    if autoModeEnabled then
        hopActive = true
        autoBtn.Text = "MODO AUTOMÁTICO: ON"
        autoBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        statusLabel.Text = "Auto Mode: Ativado"
        doServerHop()
    else
        hopActive = false
        autoBtn.Text = "MODO AUTOMÁTICO: OFF"
        autoBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
        statusLabel.Text = "Auto Mode: Desativado"
    end
end)

-- Permitir arrastar a janela
local dragging = false
local dragInput
local dragStart
local startPos

hopFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = hopFrame.Position
    end
end)

hopFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        hopFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Inicialização
loadBlacklist()
hopFrame.Visible = true

print("✅ Apenas Server Hop carregado com sucesso!")
