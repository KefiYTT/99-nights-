--SAKURA ✿
--by Kefi
--UI v4.0.0

local PETAL_ICON = "flower-2"

local env = (getgenv and getgenv()) or _G
if env.SAKURA_CLEANUP then
    pcall(env.SAKURA_CLEANUP)
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "SAKURA ✿",
    SubTitle = "by Kefi • v4.0",
    Icon = PETAL_ICON,
    Author = "Kefi",
    Folder = "SAKURA_HUB",
    Size = UDim2.fromOffset(480, 420),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 210,
    BackgroundImageTransparency = 0.35,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = { Enabled = true, Anonymous = false, Callback = function() print("🌸 clicked") end },
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- =========================================================
-- Очистка
-- =========================================================

local running = true
local connections = {}

local function track(conn)
    table.insert(connections, conn)
    return conn
end

local activeBrings = {}
local cleanupCallbacks = {}

env.SAKURA_CLEANUP = function()
    running = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    for k in pairs(activeBrings) do activeBrings[k] = nil end
    for _, fn in ipairs(cleanupCallbacks) do pcall(fn) end
    pcall(function() Window:Destroy() end)
end

pcall(function()
    local RobloxGui = CoreGui:WaitForChild("RobloxGui", 5)
    if RobloxGui then
        local nf = RobloxGui:FindFirstChild("NotificationFrame") or RobloxGui:FindFirstChild("SendNotificationInfo")
        if nf then nf:Destroy() end
        track(RobloxGui.ChildAdded:Connect(function(child)
            if child.Name == "NotificationFrame" then child:Destroy() end
        end))
    end
end)

-- =========================================================
-- Хелперы
-- =========================================================

local function getHRPSafe()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function notify(title, content, duration)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = duration or 3, Icon = PETAL_ICON })
    end)
end

local function getRoot(obj)
    if obj:IsA("BasePart") then return obj end
    return obj.PrimaryPart
        or obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function getPos(obj)
    local ok, pos = pcall(function() return obj:GetPivot().Position end)
    if ok then return pos end
    local root = getRoot(obj)
    return root and root.Position
end

local function isLostChild(obj)
    return obj.Name:sub(1, 10) == "Lost Child"
end

local function isPlayerChar(obj)
    return Players:GetPlayerFromCharacter(obj) ~= nil
end

local function matchesList(list, name)
    if list[name] then return true end
    local stripped = name:gsub("^Cooked ", "")
    return list[stripped] == true
end

-- Поиск структур по всему workspace
local function findStructureByName(keywords)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local lower = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if lower:find(kw, 1, true) then return obj end
            end
        end
    end
    return nil
end

local function structurePos(obj)
    if not obj then return nil end
    return getPos(obj)
end

local function getCampfire()
    return findStructureByName({ "mainfire", "campfire", "main_fire", "firepit" })
end

local function getRecycler()
    return findStructureByName({ "recycl", "refine", "processor", "shredder" })
end

local function collectMapStructures()
    local found = {}
    local map = workspace:FindFirstChild("Map")
    local scanRoot = map or workspace
    for _, obj in ipairs(scanRoot:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Parent then
            local name = obj.Name
            if not found[name] then
                local ok, size = pcall(function()
                    if obj:IsA("BasePart") then return obj.Size end
                    return obj:GetExtentsSize()
                end)
                if ok and size and size.Magnitude > 10 then
                    found[name] = true
                end
            end
        end
    end
    local list = {}
    for name in pairs(found) do table.insert(list, name) end
    table.sort(list)
    return list
end

-- Кольцо радиуса
local function makeRing(getRadius, color)
    local ring, conn
    local function setEnabled(on)
        if on then
            if conn then return end
            ring = Instance.new("Part")
            ring.Name = "SakuraRing"
            ring.Shape = Enum.PartType.Cylinder
            ring.Anchored = true
            ring.CanCollide = false
            ring.CanQuery = false
            ring.CanTouch = false
            ring.CastShadow = false
            ring.Material = Enum.Material.Neon
            ring.Color = color or Color3.fromRGB(255, 106, 213)
            ring.Transparency = 0.8
            ring.Parent = workspace.CurrentCamera
            conn = RunService.Heartbeat:Connect(function()
                local hrp = getHRPSafe()
                if not (hrp and ring and ring.Parent) then return end
                local r = getRadius()
                ring.Size = Vector3.new(0.2, r * 2, r * 2)
                ring.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.9, 0)) * CFrame.Angles(0, 0, math.pi / 2)
            end)
        else
            if conn then conn:Disconnect() conn = nil end
            if ring then ring:Destroy() ring = nil end
        end
    end
    table.insert(cleanupCallbacks, function() setEnabled(false) end)
    return setEnabled
end

-- Вкладки
local Tab  = Window:Tab({ Title = "Главная",  Icon = "bird",     Locked = false })
local Tab2 = Window:Tab({ Title = "Принести", Icon = "package",  Locked = false })
local Tab3 = Window:Tab({ Title = "Игрок",    Icon = "user",     Locked = false })
local Tab4 = Window:Tab({ Title = "Бой",      Icon = "swords",   Locked = false })
local Tab5 = Window:Tab({ Title = "ESP",      Icon = "eye",      Locked = false })
local Tab6 = Window:Tab({ Title = "Разное",   Icon = "settings", Locked = false })
local Tab7 = Window:Tab({ Title = "Мобы",     Icon = "skull",    Locked = false })
local Tab8 = Window:Tab({ Title = "Функции+", Icon = "sparkles", Locked = false })
local Tab9 = Window:Tab({ Title = "Экстра",   Icon = "zap",      Locked = false }) -- 🆕 20 функций

Window:Tag({
    Title = "v4.0.0",
    Color = Color3.fromHex("#ff6ad5")
})

-- =========================================================
-- ВКЛАДКА 1: ГЛАВНАЯ
-- =========================================================

Tab:Section({ Title = "Дни", TextXAlignment = "Left", TextSize = 17 })

local flying = false
local radius = 150
local height = 100
local speed = 1
local angle = 0

Tab:Toggle({
    Title = "Авто-дни",
    Desc = "Летать по кругу над картой",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state) flying = state end
})

track(RunService.RenderStepped:Connect(function(dt)
    if flying then
        local hrp = getHRPSafe()
        if hrp then
            angle = angle + speed * dt
            local x = math.cos(angle) * radius
            local z = math.sin(angle) * radius
            hrp.CFrame = CFrame.new(Vector3.new(x, height, z), Vector3.new(0, height, 0))
        end
    end
end))

Tab:Section({ Title = "Фарм", TextXAlignment = "Left", TextSize = 17 })

Tab:Paragraph({
    Title = "Примечание",
    Desc = "Авто-фарм кролика в бета-режиме: возможна ошибка камеры, но скрипт продолжит работать",
    Color = "White",
})

local autoKill = false
local savedBunnyPosition
local bunny
local lastBunnyCheck = 0

local function findBunny()
    local characters = workspace:FindFirstChild("Characters")
    bunny = characters and characters:FindFirstChild("Bunny") or nil
end

track(RunService.RenderStepped:Connect(function(dt)
    if autoKill then
        lastBunnyCheck = lastBunnyCheck + dt
        if lastBunnyCheck >= 1 or not (bunny and bunny.Parent) then
            findBunny()
            lastBunnyCheck = 0
        end
        if bunny and bunny.PrimaryPart then
            local hrp = getHRPSafe()
            if hrp then
                hrp.CFrame = hrp.CFrame:Lerp(bunny.PrimaryPart.CFrame * CFrame.new(0, 0, -2), 0.3)
                local cam = workspace.CurrentCamera
                if cam then
                    VirtualUser:Button1Down(Vector2.new(0, 0), cam.CFrame)
                    VirtualUser:Button1Up(Vector2.new(0, 0), cam.CFrame)
                end
            end
        end
    end
end))

Tab:Toggle({
    Title = "Авто-убийство кролика",
    Desc = "Автоматически атаковать кролика",
    Icon = "bird",
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        autoKill = state
        if autoKill then
            local hrp = getHRPSafe()
            savedBunnyPosition = hrp and hrp.CFrame
            findBunny()
        else
            local hrp = getHRPSafe()
            if savedBunnyPosition and hrp then
                hrp.CFrame = savedBunnyPosition
            end
        end
    end
})

Tab:Section({ Title = "Дети", TextXAlignment = "Left", TextSize = 17 })

Tab:Button({
    Title = "Открыть все сундуки",
    Desc = "Открыть все сундуки на карте",
    Callback = function()
        pcall(function()
            local chestFolder = workspace.Items
            local remote = ReplicatedStorage.RemoteEvents:WaitForChild("RequestOpenItemChest")
            for _, v in ipairs(chestFolder:GetChildren()) do
                if v.Name:match("Item Chest") or v.Name == "Alien Chest" then
                    remote:FireServer(v)
                end
            end
        end)
    end
})

local function tweenToLostChild(childName)
    local root = getHRPSafe()
    if not root then return end
    local originalCFrame = root.CFrame

    local charactersFolder = workspace:FindFirstChild("Characters")
    local target = nil
    if charactersFolder then
        for _, child in ipairs(charactersFolder:GetChildren()) do
            if child.Name == childName then
                target = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
                if target then break end
            end
        end
    end

    if not target then
        notify("Ошибка", "Ребёнок не найден, или уровень костра слишком низкий", 3)
        return
    end

    local distance = (root.Position - target.Position).Magnitude
    local tweenTo = TweenService:Create(root, TweenInfo.new(distance / 500, Enum.EasingStyle.Linear),
        { CFrame = target.CFrame + Vector3.new(0, 3, 0) })
    tweenTo:Play()
    tweenTo.Completed:Wait()

    task.wait(15)

    if not running then return end
    root = getHRPSafe()
    if not root then return end
    local tweenBack = TweenService:Create(root, TweenInfo.new(1, Enum.EasingStyle.Linear), { CFrame = originalCFrame })
    tweenBack:Play()
end

for i = 1, 4 do
    local name = i == 1 and "Lost Child" or ("Lost Child" .. i)
    Tab:Button({
        Title = "Принести ребёнка" .. (i > 1 and (" " .. i) or ""),
        Desc = "Подойти, подождать 15с и вернуться",
        Callback = function() task.spawn(tweenToLostChild, name) end
    })
end

Tab:Section({ Title = "Готовка и еда", TextXAlignment = "Left", TextSize = 17 })

local eatConnection = nil

Tab:Toggle({
    Title = "Авто-еда",
    Desc = "Есть жареное мясо при голоде < 90%",
    Icon = "bird",
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        if eatConnection then
            eatConnection:Disconnect()
            eatConnection = nil
        end
        if not state then return end
        pcall(function()
            local requestConsume = ReplicatedStorage.RemoteEvents:WaitForChild("RequestConsumeItem")
            local hungryBar = player:WaitForChild("PlayerGui"):WaitForChild("Interface")
                :WaitForChild("StatBars"):WaitForChild("HungerBar"):WaitForChild("Bar")

            local eating = false
            local function eatFood()
                if eating then return end
                eating = true
                task.spawn(function()
                    pcall(function()
                        for _, item in ipairs(workspace.Items:GetChildren()) do
                            if item.Name == "Cooked Morsel" then
                                requestConsume:InvokeServer(item)
                                break
                            end
                        end
                    end)
                    task.wait(0.5)
                    eating = false
                end)
            end

            eatConnection = hungryBar:GetPropertyChangedSignal("Size"):Connect(function()
                if hungryBar.Size.X.Scale < 0.9 then eatFood() end
            end)
            track(eatConnection)
            if hungryBar.Size.X.Scale < 0.9 then eatFood() end
        end)
    end
})

Tab:Button({
    Title = "Приготовить еду",
    Desc = "Положить сырую еду на костёр",
    Callback = function()
        pcall(function()
            local fire = getCampfire()
            local firePos = structurePos(fire)
            if not firePos then
                notify("Ошибка", "Костёр не найден!", 3)
                return
            end
            for _, item in ipairs(workspace.Items:GetChildren()) do
                if item:IsA("Model") and item.PrimaryPart and
                   (item.Name:find("Morsel") or item.Name:find("Steak")) then
                    ReplicatedStorage.RemoteEvents.RequestStartDraggingItem:FireServer(item)
                    item:PivotTo(CFrame.new(firePos + Vector3.new(0, 8, 0)))
                    ReplicatedStorage.RemoteEvents.StopDraggingItem:FireServer(item)
                end
            end
        end)
    end
})

-- =========================================================
-- ВКЛАДКА 2: ПРИНЕСТИ (⚡ БЫСТРО: параллельно, без лишних задержек)
-- =========================================================

local requestDrag = ReplicatedStorage.RemoteEvents.RequestStartDraggingItem
local stopDrag = ReplicatedStorage.RemoteEvents.StopDraggingItem

local LISTS = {
    Fuel = { ["Log"] = true, ["Coal"] = true, ["Oil Barrel"] = true, ["Fuel Canister"] = true,
        ["Cultist"] = true, ["Bear Corpse"] = true, ["Alpha Wolf Corpse"] = true,
        ["Wolf Corpse"] = true, ["Crossbow Cultist"] = true },
    Metal = { ["Bolt"] = true, ["Sheet Metal"] = true, ["UFO Junk"] = true, ["UFO Component"] = true,
        ["Broken Fan"] = true, ["Broken Radio"] = true, ["Broken Microwave"] = true, ["Tyre"] = true,
        ["Metal Chair"] = true, ["Old Car Engine"] = true, ["Cultist Experiment"] = true,
        ["Washing Machine"] = true, ["Cultist Prototype"] = true, ["UFO Scrap"] = true },
    Food = { ["Steak"] = true, ["BBQ Ribs"] = true, ["Candy Apple"] = true, ["Carrot"] = true,
        ["Berry"] = true, ["Cotton Candy"] = true, ["Chili"] = true, ["Lava Eel"] = true,
        ["Candy Corn"] = true, ["Morsel"] = true, ["Stew"] = true, ["Corn"] = true,
        ["Pumpkin"] = true, ["Casserole"] = true, ["Apple"] = true, ["Berry Juice"] = true,
        ["Ribs"] = true, ["Cake"] = true, ["Hearty Stew"] = true, ["Shark"] = true,
        ["Swordfish"] = true, ["Eel"] = true, ["Char"] = true, ["Mackerel"] = true,
        ["Salmon"] = true, ["Clownfish"] = true },
    Ammo = { ["Revolver Ammo"] = true, ["Rifle Ammo"] = true, ["Shotgun Ammo"] = true },
    Tools = { ["Bandage"] = true, ["Rifle"] = true, ["Revolver"] = true, ["Laser Cannon"] = true,
        ["Ray Gun"] = true, ["Laser Sword"] = true, ["Katana"] = true,
        ["Strong Flashlight"] = true, ["Old Flashlight"] = true },
    Sapling = { ["Sapling"] = true },
    Log = { ["Log"] = true },
    Coal = { ["Coal"] = true },
    Microwave = { ["Broken Microwave"] = true },
    Steak = { ["Steak"] = true },
}

local bringLabels = {
    Fuel = "Топливо", Metal = "Металл", Food = "Еду", Ammo = "Патроны",
    Tools = "Инструменты", Sapling = "Саженцы", Log = "Брёвна", Coal = "Уголь",
    Microwave = "Микроволновки", Steak = "Стейки",
}

Tab2:Section({ Title = "Куда приносить вещи", TextXAlignment = "Left", TextSize = 17 })

local bringTarget = "self"
local customStructureName = nil

Tab2:Button({
    Title = "🎯 К СЕБЕ",
    Desc = "Приносить вещи к игроку",
    Callback = function()
        bringTarget = "self"
        notify("Принести", "Цель: К СЕБЕ", 2)
    end
})

Tab2:Button({
    Title = "🔥 К КОСТРУ",
    Desc = "Приносить вещи к костру",
    Callback = function()
        bringTarget = "campfire"
        notify("Принести", "Цель: КОСТЁР", 2)
    end
})

Tab2:Button({
    Title = "♻️ К ПЕРЕРАБОТЧИКУ",
    Desc = "Приносить вещи к переработчику",
    Callback = function()
        local rec = getRecycler()
        if rec then
            bringTarget = "recycler"
            notify("Принести", "Переработчик найден: " .. rec.Name, 3)
        else
            notify("Принести", "Не найден автоматически — выбери вручную ниже!", 5)
        end
    end
})

Tab2:Section({ Title = "Своя структура (если не нашлось)", TextXAlignment = "Left", TextSize = 17 })

local structureOptions = collectMapStructures()
if #structureOptions == 0 then structureOptions = { "Структур не найдено" } end

Tab2:Dropdown({
    Title = "Выбери объект карты",
    Options = structureOptions,
    Default = structureOptions[1],
    Callback = function(value)
        if value and value ~= "Структур не найдено" then
            customStructureName = value
            bringTarget = "custom"
            notify("Принести", "Цель: " .. value, 2)
        end
    end
})

local function getBringTargetPos()
    if bringTarget == "campfire" then
        local pos = structurePos(getCampfire())
        if pos then return pos + Vector3.new(0, 6, 0) end
        return nil
    elseif bringTarget == "recycler" then
        local pos = structurePos(getRecycler())
        if pos then return pos + Vector3.new(0, 5, 0) end
        notify("Ошибка", "Переработчик не найден — выбери вручную выше!", 4)
        return nil
    elseif bringTarget == "custom" and customStructureName then
        local obj = workspace:FindFirstChild(customStructureName, true)
        local pos = structurePos(obj)
        if pos then return pos + Vector3.new(0, 5, 0) end
        return nil
    end
    return nil
end

-- ⚡ БЫСТРЫЙ ПРИНОС: параллельные воркеры + минимум задержек
local BRING_SAFE_RADIUS = 10
local bringToggles = {}

local function startBring(key)
    if activeBrings[key] then return end
    activeBrings[key] = true

    local list = LISTS[key]

    task.spawn(function()
        pcall(function()
            local hrp = getHRPSafe()
            local items = workspace:FindFirstChild("Items")
            if not (hrp and items) then return end

            local fixedTargetPos = getBringTargetPos()

            -- Собираем список предметов
            local toBring = {}
            for _, item in ipairs(items:GetChildren()) do
                if (item:IsA("Model") or item:IsA("BasePart")) and matchesList(list, item.Name) then
                    local pos = getPos(item)
                    if pos then
                        table.insert(toBring, item)
                    end
                end
            end

            if #toBring == 0 then
                activeBrings[key] = nil
                local tg = bringToggles[key]
                if tg then pcall(function() tg:Set(false) end) end
                notify("Принести", (bringLabels[key] or key) .. ": предметов не найдено", 2)
                return
            end

            -- ⚡ Параллельная переноска: 6 предметов одновременно
            local PARALLEL = 6
            local count = 0
            local done = 0
            local index = 0

            local function worker()
                while running and activeBrings[key] do
                    local i = nil
                    index = index + 1
                    if index <= #toBring then i = index end
                    if not i then break end

                    local item = toBring[i]
                    if item and item.Parent then
                        local targetPos = fixedTargetPos
                        if not targetPos then
                            local h = getHRPSafe()
                            if not h then break end
                            targetPos = h.Position + Vector3.new(0, 3, 0)
                        end

                        local itemPos = getPos(item)
                        if itemPos and (itemPos - targetPos).Magnitude > BRING_SAFE_RADIUS then
                            pcall(function()
                                requestDrag:FireServer(item)
                                item:PivotTo(CFrame.new(targetPos + Vector3.new(math.random(-3, 3), 1, math.random(-3, 3))))
                                stopDrag:FireServer(item)
                            end)
                            count = count + 1
                        end
                    end
                    done = done + 1
                end
            end

            local threads = {}
            for i = 1, math.min(PARALLEL, #toBring) do
                table.insert(threads, task.spawn(worker))
            end

            -- ждём завершения всех воркеров
            while done < #toBring and activeBrings[key] and running do
                task.wait(0.05)
            end

            activeBrings[key] = nil
            local tg = bringToggles[key]
            if tg then pcall(function() tg:Set(false) end) end

            local targetName = bringTarget == "campfire" and "к костру"
                or bringTarget == "recycler" and "к переработчику"
                or bringTarget == "custom" and "к " .. (customStructureName or "?")
                or "к тебе"
            notify("Принести", (bringLabels[key] or key) .. ": " .. count .. " шт. " .. targetName, 2)
        end)
    end)
end

Tab2:Section({ Title = "Категории", TextXAlignment = "Left", TextSize = 17 })

local bringGroups = {
    { key = "Fuel",      title = "Топливо" },
    { key = "Metal",     title = "Металл" },
    { key = "Food",      title = "Еда" },
    { key = "Ammo",      title = "Патроны" },
    { key = "Tools",     title = "Инструменты" },
    { key = "Sapling",   title = "Отдельные предметы" },
    { key = "Log" },
    { key = "Coal" },
    { key = "Microwave" },
    { key = "Steak" },
}

for _, group in ipairs(bringGroups) do
    if group.title then
        Tab2:Section({ Title = group.title, TextXAlignment = "Left", TextSize = 17 })
    end
    local key = group.key
    bringToggles[key] = Tab2:Toggle({
        Title = "Принести: " .. (bringLabels[key] or key),
        Desc = "⚡ Быстро: 6 предметов одновременно",
        Icon = "package",
        Type = "Toggle",
        Default = false,
        Callback = function(state)
            if state then startBring(key) else activeBrings[key] = nil end
        end
    })
end

Tab2:Section({ Title = "Управление", TextXAlignment = "Left", TextSize = 17 })

Tab2:Button({
    Title = "Принести ВСЁ ⚡",
    Desc = "Все категории сразу, параллельно",
    Callback = function()
        for _, group in ipairs(bringGroups) do
            task.spawn(startBring, group.key)
        end
    end
})

Tab2:Button({
    Title = "Остановить всё",
    Desc = "Отменить текущий принос",
    Callback = function()
        for key in pairs(activeBrings) do activeBrings[key] = nil end
        for _, tg in pairs(bringToggles) do
            pcall(function() tg:Set(false) end)
        end
        notify("Принести", "Остановлено", 2)
    end
})

-- =========================================================
-- ВКЛАДКА 3: ИГРОК
-- =========================================================

Tab3:Section({ Title = "Скорость", TextXAlignment = "Left", TextSize = 17 })

local speedEnabled = false
local selectedSpeed = 70
local originalSpeed = 16

local function enforceSpeed()
    if not speedEnabled then return end
    local hum = getHumanoid()
    if hum and hum.WalkSpeed ~= selectedSpeed then
        hum.WalkSpeed = selectedSpeed
    end
end

pcall(function() RunService:UnbindFromRenderStep("SakuraSpeed") end)
RunService:BindToRenderStep("SakuraSpeed", Enum.RenderPriority.Last.Value, enforceSpeed)
table.insert(cleanupCallbacks, function()
    pcall(function() RunService:UnbindFromRenderStep("SakuraSpeed") end)
    local hum = getHumanoid()
    if hum and speedEnabled then hum.WalkSpeed = originalSpeed end
end)
track(RunService.Stepped:Connect(enforceSpeed))
track(RunService.Heartbeat:Connect(enforceSpeed))

local speedChangedConn
local function hookHumanoid(hum)
    if speedChangedConn then
        speedChangedConn:Disconnect()
        speedChangedConn = nil
    end
    if hum then
        speedChangedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(enforceSpeed)
    end
end
table.insert(cleanupCallbacks, function() hookHumanoid(nil) end)

hookHumanoid(getHumanoid())
track(player.CharacterAdded:Connect(function(char)
    hookHumanoid(char:WaitForChild("Humanoid", 10))
end))

Tab3:Slider({
    Title = "Скорость ходьбы",
    Step = 1,
    Value = { Min = 20, Max = 300, Default = 70 },
    Callback = function(value) selectedSpeed = tonumber(value) or 70 end
})

Tab3:Toggle({
    Title = "Включить скорость",
    Desc = "Вкл/Выкл",
    Icon = "bird",
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        local hum = getHumanoid()
        if state then
            if hum and hum.WalkSpeed ~= selectedSpeed then
                originalSpeed = hum.WalkSpeed
            end
            speedEnabled = true
            enforceSpeed()
        else
            speedEnabled = false
            if hum then hum.WalkSpeed = originalSpeed end
        end
    end
})

Tab3:Section({ Title = "Режим бога", TextXAlignment = "Left", TextSize = 17 })

local godLoaded = false

Tab3:Toggle({
    Title = "Режим бога",
    Desc = "Бесконечное здоровье (отключается перезаходом)",
    Icon = "bird",
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        if state and not godLoaded then
            godLoaded = true
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/ProBaconHub/DATABASE/refs/heads/main/99%20Nights%20in%20the%20Forest/Infinite%20Health.lua"))()
            end)
        elseif not state then
            notify("Режим бога", "Перезайди, чтобы отключить", 3)
        end
    end
})

-- Полёт ПК + телефон
Tab3:Section({ Title = "Полёт", TextXAlignment = "Left", TextSize = 17 })

local flyEnabled = false
local flySpeed = 60
local flyBodyVelocity, flyBodyGyro
local mobileMove = Vector3.zero
local flyGui = nil

local function makeFlyButton(parent, text, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 64, 0, 64)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
    btn.BackgroundTransparency = 0.25
    btn.TextColor3 = Color3.fromRGB(255, 130, 220)
    btn.Text = text
    btn.TextSize = 22
    btn.Font = Enum.Font.SourceSansBold
    btn.BorderSizePixel = 0
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 106, 213)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4
    stroke.Parent = btn

    local pressing = false
    btn.MouseButton1Down:Connect(function() pressing = true end)
    btn.TouchStart:Connect(function() pressing = true end)
    local function release() pressing = false callback(false) end
    btn.MouseButton1Up:Connect(release)
    btn.TouchEnd:Connect(release)
    btn.MouseLeave:Connect(release)

    task.spawn(function()
        while running and flyGui and flyGui.Parent do
            if pressing then callback(true) end
            task.wait(0.03)
        end
    end)
end

local function showFlyButtons()
    if flyGui then return end
    pcall(function()
        flyGui = Instance.new("ScreenGui")
        flyGui.Name = "SakuraFlyMobile"
        flyGui.ResetOnSpawn = false
        flyGui.IgnoreGuiInset = true
        flyGui.Parent = player:WaitForChild("PlayerGui", 5)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0, 200, 0, 30)
        title.Position = UDim2.new(0, 12, 0.5, -240)
        title.BackgroundTransparency = 1
        title.Text = "✈️ SAKURA Полёт"
        title.TextColor3 = Color3.fromRGB(255, 130, 220)
        title.TextSize = 18
        title.Font = Enum.Font.SourceSansBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = flyGui

        local function setMove(vec) mobileMove = vec end

        makeFlyButton(flyGui, "▲", UDim2.new(0, 80, 0.5, -140), function(on)
            if on then setMove(workspace.CurrentCamera.CFrame.LookVector) else setMove(Vector3.zero) end
        end)
        makeFlyButton(flyGui, "▼", UDim2.new(0, 80, 0.5, 0), function(on)
            if on then setMove(-workspace.CurrentCamera.CFrame.LookVector) else setMove(Vector3.zero) end
        end)
        makeFlyButton(flyGui, "◀", UDim2.new(0, 10, 0.5, -70), function(on)
            if on then setMove(-workspace.CurrentCamera.CFrame.RightVector) else setMove(Vector3.zero) end
        end)
        makeFlyButton(flyGui, "▶", UDim2.new(0, 150, 0.5, -70), function(on)
            if on then setMove(workspace.CurrentCamera.CFrame.RightVector) else setMove(Vector3.zero) end
        end)
        makeFlyButton(flyGui, "⬆", UDim2.new(1, -80, 0.5, -140), function(on)
            if on then setMove(Vector3.new(0, 1, 0)) else setMove(Vector3.zero) end
        end)
        makeFlyButton(flyGui, "⬇", UDim2.new(1, -80, 0.5, 0), function(on)
            if on then setMove(Vector3.new(0, -1, 0)) else setMove(Vector3.zero) end
        end)
    end)
end

local function hideFlyButtons()
    if flyGui then
        pcall(function() flyGui:Destroy() end)
        flyGui = nil
    end
    mobileMove = Vector3.zero
end

table.insert(cleanupCallbacks, hideFlyButtons)

Tab3:Toggle({
    Title = "Полёт",
    Desc = "ПК: WASD + Space/Q. Телефон: кнопки на экране",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        flyEnabled = state
        local hrp = getHRPSafe()
        if state then
            if hrp then
                flyBodyVelocity = Instance.new("BodyVelocity")
                flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyBodyVelocity.Velocity = Vector3.zero
                flyBodyVelocity.Parent = hrp

                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                flyBodyGyro.P = 9000
                flyBodyGyro.Parent = hrp
            end
            showFlyButtons()
            notify("Полёт", "Включён", 2)
        else
            hideFlyButtons()
            if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
            local hum = getHumanoid()
            if hum then hum.PlatformStand = false end
        end
    end
})

Tab3:Slider({
    Title = "Скорость полёта",
    Step = 5,
    Value = { Min = 20, Max = 300, Default = 60 },
    Callback = function(value) flySpeed = tonumber(value) or 60 end
})

track(RunService.RenderStepped:Connect(function()
    if not flyEnabled then return end
    local hrp = getHRPSafe()
    local hum = getHumanoid()
    if not (hrp and flyBodyVelocity and flyBodyGyro and hum) then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local moveVec = mobileMove

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
        moveVec = moveVec + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
        moveVec = moveVec - Vector3.new(0, 1, 0)
    end

    if moveVec.Magnitude > 0 then
        flyBodyVelocity.Velocity = moveVec.Unit * flySpeed
    else
        flyBodyVelocity.Velocity = Vector3.zero
    end
    flyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
    hum.PlatformStand = true
end))

table.insert(cleanupCallbacks, function()
    if flyBodyVelocity then pcall(function() flyBodyVelocity:Destroy() end) end
    if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end)

local noclip = false
Tab3:Toggle({
    Title = "Noclip",
    Desc = "Проходить сквозь стены",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state) noclip = state end
})

track(RunService.Stepped:Connect(function()
    if noclip then
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end))

local jumpEnabled = false
local jumpPower = 120

Tab3:Slider({
    Title = "Сила прыжка",
    Step = 5,
    Value = { Min = 50, Max = 500, Default = 120 },
    Callback = function(value)
        jumpPower = tonumber(value) or 120
        if jumpEnabled then
            local hum = getHumanoid()
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = jumpPower
            end
        end
    end
})

Tab3:Toggle({
    Title = "Высокий прыжок",
    Desc = "Включить кастомную силу прыжка",
    Default = false,
    Callback = function(state)
        jumpEnabled = state
        local hum = getHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = state and jumpPower or 50
        end
    end
})

track(player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum and jumpEnabled then
        hum.UseJumpPower = true
        hum.JumpPower = jumpPower
    end
end))

Tab3:Section({ Title = "Телепорт", TextXAlignment = "Left", TextSize = 17 })

local tapTP = false
Tab3:Toggle({
    Title = "ТП по тапу/клику",
    Desc = "Телефон: тап. ПК: клик ЛКМ",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        tapTP = state
        if state then notify("Телепорт", "Тапай/кликай по земле", 3) end
    end
})

track(UserInputService.TouchTapInWorld:Connect(function(position, gameProcessed)
    if gameProcessed or not tapTP then return end
    local hrp = getHRPSafe()
    if hrp then
        local ray = workspace.CurrentCamera:ViewportPointToRay(position.X, position.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
        if result then
            hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 5, 0))
        else
            hrp.CFrame = CFrame.new(ray.Origin + ray.Direction.Unit * 200 + Vector3.new(0, 5, 0))
        end
    end
end))

track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not tapTP then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouse = player:GetMouse()
        local hrp = getHRPSafe()
        if mouse and mouse.Hit and hrp then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 5, 0))
        end
    end
end))

local antiAFK = false
Tab3:Toggle({
    Title = "Anti-AFK",
    Desc = "Не выкидывает за простой",
    Default = false,
    Callback = function(state)
        antiAFK = state
        if state then notify("Anti-AFK", "Включено", 2) end
    end
})

task.spawn(function()
    while running do
        if antiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
        task.wait(60)
    end
end)

Tab3:Section({ Title = "Другое", TextXAlignment = "Left", TextSize = 17 })

local infJump = false
Tab3:Toggle({
    Title = "Бесконечный прыжок",
    Desc = "Прыгать в воздухе",
    Default = false,
    Callback = function(state) infJump = state end
})

track(UserInputService.JumpRequest:Connect(function()
    if infJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- =========================================================
-- ВКЛАДКА 4: БОЙ
-- =========================================================

local MAX_TARGETS_PER_TICK = 15
local TREE_NAMES = { ["Small Tree"] = true, ["TreeBig1"] = true, ["TreeBig2"] = true }

local function getWeapon()
    local inv = player:FindFirstChild("Inventory")
    if not inv then return nil end
    local w = inv:FindFirstChild("Old Axe")
        or inv:FindFirstChild("Good Axe")
        or inv:FindFirstChild("Strong Axe")
        or inv:FindFirstChild("Chainsaw")
    if w then return w end
    for _, tool in ipairs(inv:GetChildren()) do
        if tool.Name:find("Axe") then return tool end
    end
    return nil
end

Tab4:Section({ Title = "Аура убийства", TextXAlignment = "Left", TextSize = 17 })

local ActiveKillAura = false
local KillAuraRadius = 70

Tab4:Slider({
    Title = "Радиус ауры убийства",
    Step = 1,
    Value = { Min = 20, Max = 300, Default = 70 },
    Callback = function(value) KillAuraRadius = tonumber(value) or 70 end
})

local setKillRing = makeRing(function() return KillAuraRadius end)

Tab4:Toggle({
    Title = "Показывать радиус",
    Desc = "Розовый круг вокруг тебя",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state) setKillRing(state) end
})

Tab4:Toggle({
    Title = "Аура убийства",
    Desc = "Бьёт всё в радиусе вокруг тебя",
    Default = false,
    Callback = function(state)
        ActiveKillAura = state
        if not state then return end
        task.spawn(function()
            while running and ActiveKillAura do
                pcall(function()
                    local hrp = getHRPSafe()
                    local weapon = getWeapon()
                    local chars = workspace:FindFirstChild("Characters")
                    if not (hrp and weapon and chars) then return end

                    local myPos = hrp.Position
                    local targets = {}
                    for _, mob in ipairs(chars:GetChildren()) do
                        if mob:IsA("Model") and mob ~= player.Character
                            and not isLostChild(mob) and not isPlayerChar(mob) then
                            local hum = mob:FindFirstChildOfClass("Humanoid")
                            if not (hum and hum.Health <= 0) then
                                local p = getPos(mob)
                                if p then
                                    local d = (p - myPos).Magnitude
                                    if d <= KillAuraRadius then
                                        table.insert(targets, { mob = mob, d = d })
                                    end
                                end
                            end
                        end
                    end

                    table.sort(targets, function(a, b) return a.d < b.d end)
                    for i = 1, math.min(#targets, MAX_TARGETS_PER_TICK) do
                        local mob = targets[i].mob
                        task.spawn(function()
                            pcall(function()
                                ReplicatedStorage.RemoteEvents.ToolDamageObject:InvokeServer(
                                    mob, weapon, 999, hrp.CFrame)
                            end)
                        end)
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
})

Tab4:Section({ Title = "Аура деревьев", TextXAlignment = "Left", TextSize = 17 })

local ActiveAutoChopTree = false
local ChopRadius = 100

Tab4:Slider({
    Title = "Радиус рубки",
    Step = 1,
    Value = { Min = 20, Max = 150, Default = 100 },
    Callback = function(value) ChopRadius = tonumber(value) or 100 end
})

local setChopRing = makeRing(function() return ChopRadius end, Color3.fromRGB(106, 255, 106))

Tab4:Toggle({
    Title = "Показывать радиус рубки",
    Desc = "Зелёный круг вокруг тебя",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state) setChopRing(state) end
})

Tab4:Toggle({
    Title = "Аура деревьев",
    Desc = "Рубить все деревья в радиусе",
    Icon = "bird",
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        ActiveAutoChopTree = state
        if not state then return end
        task.spawn(function()
            while running and ActiveAutoChopTree do
                pcall(function()
                    local hrp = getHRPSafe()
                    local weapon = getWeapon()
                    local map = workspace:FindFirstChild("Map")
                    if not (hrp and weapon and map) then return end

                    local myPos = hrp.Position
                    local targets = {}
                    local function scan(folder)
                        if not folder then return end
                        for _, tree in ipairs(folder:GetChildren()) do
                            if tree:IsA("Model") and TREE_NAMES[tree.Name] then
                                local p = getPos(tree)
                                if p then
                                    local d = (p - myPos).Magnitude
                                    if d <= ChopRadius then
                                        table.insert(targets, { tree = tree, d = d })
                                    end
                                end
                            end
                        end
                    end
                    scan(map:FindFirstChild("Foliage"))
                    scan(map:FindFirstChild("Landmarks"))

                    table.sort(targets, function(a, b) return a.d < b.d end)
                    for i = 1, math.min(#targets, MAX_TARGETS_PER_TICK) do
                        local tree = targets[i].tree
                        task.spawn(function()
                            pcall(function()
                                ReplicatedStorage.RemoteEvents.ToolDamageObject:InvokeServer(
                                    tree, weapon, 999, hrp.CFrame)
                            end)
                        end)
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
})

Tab4:Section({ Title = "Охота", TextXAlignment = "Left", TextSize = 17 })

Tab4:Button({
    Title = "ТП к ближайшему мобу",
    Desc = "Телепорт к ближайшему врагу",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local hrp = getHRPSafe()
                local chars = workspace:FindFirstChild("Characters")
                if not (hrp and chars) then return end

                local closest, closestDist = nil, math.huge
                for _, mob in ipairs(chars:GetChildren()) do
                    if mob:IsA("Model") and mob ~= player.Character
                        and not isLostChild(mob) and not isPlayerChar(mob) then
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if not (hum and hum.Health <= 0) then
                            local p = getPos(mob)
                            if p then
                                local d = (p - hrp.Position).Magnitude
                                if d < closestDist then
                                    closestDist = d
                                    closest = p
                                end
                            end
                        end
                    end
                end

                if closest then
                    hrp.CFrame = CFrame.new(closest + Vector3.new(0, 3, 3))
                    notify("Охота", "ТП к мобу (" .. math.floor(closestDist) .. " м)", 2)
                else
                    notify("Охота", "Мобы не найдены", 2)
                end
            end)
        end)
    end
})

local autoAttack = false
Tab4:Toggle({
    Title = "Авто-атака",
    Desc = "Автоматически бить тем, что в руках",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        autoAttack = state
        if state then
            task.spawn(function()
                while running and autoAttack do
                    pcall(function()
                        local cam = workspace.CurrentCamera
                        if cam then
                            VirtualUser:Button1Down(Vector2.new(0, 0), cam.CFrame)
                            VirtualUser:Button1Up(Vector2.new(0, 0), cam.CFrame)
                        end
                    end)
                    task.wait(0.2)
                end
            end)
        end
    end
})

-- =========================================================
-- ВКЛАДКА 5: ESP
-- =========================================================

local function makeESP(cfg)
    Tab5:Section({ Title = cfg.title, TextXAlignment = "Left", TextSize = 17 })

    local espToken = 0
    local tracked = {}

    local function handle(obj)
        if tracked[obj] then return end
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
        local root = getRoot(obj)
        if not root then return end
        if not cfg.filter(obj) then return end

        local hl = Instance.new("Highlight")
        hl.Name = cfg.id .. "Highlight"
        hl.FillColor = cfg.fill
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.Adornee = obj
        hl.Parent = obj

        local bb = Instance.new("BillboardGui")
        bb.Name = cfg.id .. "Billboard"
        bb.Adornee = root
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = obj

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = obj.Name
        text.TextColor3 = cfg.text
        text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        text.TextStrokeTransparency = 0
        text.TextSize = 14
        text.Font = Enum.Font.SourceSansBold
        text.Parent = bb

        tracked[obj] = { hl = hl, bb = bb, label = text, root = root, name = obj.Name }
    end

    local function clearAll()
        espToken = espToken + 1
        for _, data in pairs(tracked) do
            pcall(function() data.hl:Destroy() end)
            pcall(function() data.bb:Destroy() end)
        end
        tracked = {}
    end

    table.insert(cleanupCallbacks, clearAll)

    Tab5:Toggle({
        Title = cfg.title .. " ESP",
        Desc = cfg.desc,
        Icon = "eye",
        Type = "Toggle",
        Default = false,
        Callback = function(state)
            if not state then
                clearAll()
                return
            end
            espToken = espToken + 1
            local myToken = espToken
            task.spawn(function()
                local tick = 0
                while running and espToken == myToken do
                    if tick % 4 == 0 then
                        local container = cfg.container()
                        if container then
                            for _, obj in ipairs(container:GetChildren()) do
                                handle(obj)
                            end
                        end
                    end
                    tick = tick + 1

                    local hrp = getHRPSafe()
                    for obj, data in pairs(tracked) do
                        if not obj.Parent or not data.root.Parent then
                            pcall(function() data.hl:Destroy() end)
                            pcall(function() data.bb:Destroy() end)
                            tracked[obj] = nil
                        else
                            local parts = {}
                            if cfg.distance and hrp then
                                local d = math.floor((data.root.Position - hrp.Position).Magnitude)
                                table.insert(parts, d .. "м")
                            end
                            if cfg.showHP then
                                local hum = obj:FindFirstChildOfClass("Humanoid")
                                if hum then
                                    table.insert(parts, math.floor(hum.Health) .. " HP")
                                end
                            end
                            if #parts > 0 then
                                data.label.Text = data.name .. " [" .. table.concat(parts, " | ") .. "]"
                            else
                                data.label.Text = data.name
                            end
                        end
                    end
                    task.wait(0.25)
                end
            end)
        end
    })
end

local function itemsFolder() return workspace:FindFirstChild("Items") end
local function charsFolder() return workspace:FindFirstChild("Characters") end

makeESP({
    title = "Дети", id = "Child", desc = "потерянные дети",
    container = charsFolder,
    filter = function(o) return o:IsA("Model") and isLostChild(o) end,
    fill = Color3.fromRGB(255, 105, 180), text = Color3.fromRGB(255, 255, 255),
    distance = true,
})

makeESP({
    title = "Мобы", id = "Mob", desc = "волки, медведи (дистанция + HP)",
    container = charsFolder,
    filter = function(o)
        return o:IsA("Model") and not isLostChild(o) and not isPlayerChar(o)
    end,
    fill = Color3.fromRGB(255, 60, 60), text = Color3.fromRGB(255, 200, 200),
    distance = true, showHP = true,
})

makeESP({
    title = "Топливо", id = "Fuel", desc = "брёвна, уголь и др.",
    container = itemsFolder,
    filter = function(o) return matchesList(LISTS.Fuel, o.Name) end,
    fill = Color3.fromRGB(255, 215, 0), text = Color3.fromRGB(255, 255, 0),
})

makeESP({
    title = "Металл", id = "Metal", desc = "болты, металл и др.",
    container = itemsFolder,
    filter = function(o) return matchesList(LISTS.Metal, o.Name) end,
    fill = Color3.fromRGB(180, 180, 255), text = Color3.fromRGB(255, 0, 0),
})

makeESP({
    title = "Еда", id = "Food", desc = "вся еда на карте",
    container = itemsFolder,
    filter = function(o) return matchesList(LISTS.Food, o.Name) end,
    fill = Color3.fromRGB(0, 255, 0), text = Color3.fromRGB(255, 255, 255),
})

makeESP({
    title = "Инструменты", id = "Tools", desc = "оружие и инструменты",
    container = itemsFolder,
    filter = function(o) return matchesList(LISTS.Tools, o.Name) end,
    fill = Color3.fromRGB(140, 0, 255), text = Color3.fromRGB(200, 120, 255),
})

makeESP({
    title = "Сундуки", id = "Chest", desc = "все сундуки",
    container = itemsFolder,
    filter = function(o) return o.Name:match("Chest") ~= nil end,
    fill = Color3.fromRGB(255, 140, 0), text = Color3.fromRGB(255, 200, 100),
})

makeESP({
    title = "Деревья", id = "Tree", desc = "рубимые деревья",
    container = function()
        local map = workspace:FindFirstChild("Map")
        return map and map:FindFirstChild("Foliage")
    end,
    filter = function(o) return o:IsA("Model") and TREE_NAMES[o.Name] end,
    fill = Color3.fromRGB(0, 180, 80), text = Color3.fromRGB(150, 255, 150),
})

makeESP({
    title = "Патроны", id = "Ammo", desc = "все патроны",
    container = itemsFolder,
    filter = function(o) return matchesList(LISTS.Ammo, o.Name) end,
    fill = Color3.fromRGB(255, 255, 100), text = Color3.fromRGB(255, 255, 150),
})

makeESP({
    title = "Игроки", id = "Player", desc = "другие игроки",
    container = charsFolder,
    filter = function(o) return o:IsA("Model") and isPlayerChar(o) end,
    fill = Color3.fromRGB(170, 0, 255), text = Color3.fromRGB(220, 150, 255),
    distance = true,
})

Tab5:Section({ Title = "Инфо", TextXAlignment = "Left", TextSize = 17 })

local counterLabel
Tab5:Toggle({
    Title = "Счётчик рядом",
    Desc = "Сколько мобов и детей в радиусе 100м",
    Default = false,
    Callback = function(state)
        if state then
            pcall(function()
                local screenGui = Instance.new("ScreenGui")
                screenGui.Name = "SakuraCounter"
                screenGui.ResetOnSpawn = false
                screenGui.Parent = player:WaitForChild("PlayerGui", 5)

                counterLabel = Instance.new("TextLabel")
                counterLabel.Size = UDim2.new(0, 250, 0, 60)
                counterLabel.Position = UDim2.new(0, 10, 0.4, 0)
                counterLabel.BackgroundTransparency = 0.4
                counterLabel.BackgroundColor3 = Color3.new(0, 0, 0)
                counterLabel.TextColor3 = Color3.fromRGB(255, 106, 213)
                counterLabel.TextSize = 16
                counterLabel.Font = Enum.Font.SourceSansBold
                counterLabel.Text = "Загрузка..."
                counterLabel.Parent = screenGui
            end)
        else
            pcall(function()
                local gui = player.PlayerGui:FindFirstChild("SakuraCounter")
                if gui then gui:Destroy() end
                counterLabel = nil
            end)
        end
    end
})

task.spawn(function()
    while running do
        if counterLabel and counterLabel.Parent then
            pcall(function()
                local hrp = getHRPSafe()
                local chars = workspace:FindFirstChild("Characters")
                if hrp and chars then
                    local mobs, children = 0, 0
                    for _, m in ipairs(chars:GetChildren()) do
                        if m:IsA("Model") then
                            local p = getPos(m)
                            if p and (p - hrp.Position).Magnitude <= 100 then
                                if isLostChild(m) then
                                    children = children + 1
                                elseif not isPlayerChar(m) then
                                    mobs = mobs + 1
                                end
                            end
                        end
                    end
                    counterLabel.Text = "🌸 Рядом (100м):\nМобы: " .. mobs .. " | Дети: " .. children
                end
            end)
        end
        task.wait(5)
    end
end)

Tab5:Section({ Title = "Трейсеры", TextXAlignment = "Left", TextSize = 17 })

local tracersEnabled = false
local tracerLines = {}

Tab5:Toggle({
    Title = "Трейсеры к детям",
    Desc = "Линии от центра экрана к детям",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        tracersEnabled = state
        if not state then
            for _, line in pairs(tracerLines) do
                pcall(function() line:Remove() end)
            end
            tracerLines = {}
        end
    end
})

table.insert(cleanupCallbacks, function()
    for _, line in pairs(tracerLines) do
        pcall(function() line:Remove() end)
    end
end)

track(RunService.RenderStepped:Connect(function()
    if not tracersEnabled then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        local chars = workspace:FindFirstChild("Characters")
        if not (cam and chars) then return end

        local seen = {}
        for _, child in ipairs(chars:GetChildren()) do
            if isLostChild(child) then
                local root = getRoot(child)
                if root then
                    local screenPos, onScreen = cam:WorldToViewportPoint(root.Position)
                    local key = tostring(child)
                    seen[key] = true

                    local line = tracerLines[key]
                    if not line then
                        line = Drawing.new("Line")
                        line.Color = Color3.fromRGB(255, 105, 180)
                        line.Thickness = 1.5
                        line.Transparency = 1
                        tracerLines[key] = line
                    end

                    if onScreen then
                        line.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                        line.To = Vector2.new(screenPos.X, screenPos.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end
            end
        end

        for key, line in pairs(tracerLines) do
            if not seen[key] then
                pcall(function() line:Remove() end)
                tracerLines[key] = nil
            end
        end
    end)
end))

-- =========================================================
-- ВКЛАДКА 6: РАЗНОЕ
-- =========================================================

local FullBrightConnection
local savedLighting = nil

local function restoreLighting()
    if savedLighting then
        for prop, value in pairs(savedLighting) do
            pcall(function() Lighting[prop] = value end)
        end
        savedLighting = nil
    end
end

table.insert(cleanupCallbacks, function()
    if FullBrightConnection then
        FullBrightConnection:Disconnect()
        FullBrightConnection = nil
    end
    restoreLighting()
end)

Tab6:Section({ Title = "Освещение", TextXAlignment = "Left", TextSize = 17 })

Tab6:Toggle({
    Title = "Полная яркость",
    Desc = "Убрать темноту",
    Default = false,
    Callback = function(state)
        if state then
            if FullBrightConnection then return end
            savedLighting = {
                Ambient = Lighting.Ambient,
                ColorShift_Bottom = Lighting.ColorShift_Bottom,
                ColorShift_Top = Lighting.ColorShift_Top,
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
            }
            FullBrightConnection = RunService.RenderStepped:Connect(function()
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
                Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 1e6
            end)
        else
            if FullBrightConnection then
                FullBrightConnection:Disconnect()
                FullBrightConnection = nil
            end
            restoreLighting()
        end
    end
})

Tab6:Section({ Title = "Камера", TextXAlignment = "Left", TextSize = 17 })

Tab6:Slider({
    Title = "FOV (поле зрения)",
    Step = 1,
    Value = { Min = 60, Max = 120, Default = 70 },
    Callback = function(value)
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then cam.FieldOfView = tonumber(value) or 70 end
        end)
    end
})

Tab6:Toggle({
    Title = "Снять лимит зума",
    Desc = "Отодвигать камеру очень далеко",
    Default = false,
    Callback = function(state)
        pcall(function()
            if state then
                player.CameraMaxZoomDistance = 2000
            else
                player.CameraMaxZoomDistance = 128
            end
        end)
    end
})

table.insert(cleanupCallbacks, function()
    pcall(function() player.CameraMaxZoomDistance = 128 end)
end)

Tab6:Section({ Title = "Оптимизация", TextXAlignment = "Left", TextSize = 17 })

Tab6:Button({
    Title = "FPS Boost",
    Desc = "Убрать текстуры/частицы",
    Callback = function()
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                end
            end
            Lighting.GlobalShadows = false
            notify("Оптимизация", "FPS Boost применён", 2)
        end)
    end
})

Tab6:Button({
    Title = "Убрать туман",
    Desc = "Полностью убрать туман",
    Callback = function()
        pcall(function()
            Lighting.FogEnd = 1e6
            Lighting.FogStart = 1e6
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("Atmosphere") then obj.Density = 0 end
            end
            notify("Оптимизация", "Туман убран", 2)
        end)
    end
})

Tab6:Section({ Title = "Телепорты", TextXAlignment = "Left", TextSize = 17 })

Tab6:Button({
    Title = "Телепорт к костру",
    Desc = "Телепорт над главным костром",
    Callback = function()
        pcall(function()
            local hrp = getHRPSafe()
            local pos = structurePos(getCampfire())
            if hrp and pos then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            else
                notify("Ошибка", "Костёр не найден", 2)
            end
        end)
    end
})

Tab6:Button({
    Title = "Телепорт к переработчику",
    Desc = "Телепорт к переработчику",
    Callback = function()
        pcall(function()
            local hrp = getHRPSafe()
            local pos = structurePos(getRecycler())
            if hrp and pos then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            else
                notify("Ошибка", "Не найден — выбери вручную в Принести", 5)
            end
        end)
    end
})

Tab6:Button({
    Title = "ТП наверх (высота 500)",
    Desc = "Взлететь высоко над текущей точкой",
    Callback = function()
        pcall(function()
            local hrp = getHRPSafe()
            if hrp then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 500, 0)
            end
        end)
    end
})

Tab6:Button({
    Title = "ТП к случайному игроку",
    Desc = "Телепорт к случайному игроку",
    Callback = function()
        pcall(function()
            local hrp = getHRPSafe()
            local targets = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(targets, plr)
                end
            end
            if hrp and #targets > 0 then
                local target = targets[math.random(1, #targets)]
                hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                notify("Телепорт", "ТП к " .. target.Name, 2)
            else
                notify("Телепорт", "Игроки не найдены", 2)
            end
        end)
    end
})

local tpButtons = {}

local function addPlayerTP(plr)
    if tpButtons[plr.Name] then return end
    tpButtons[plr.Name] = true
    Tab6:Button({
        Title = "ТП: " .. plr.Name,
        Desc = "Телепорт к " .. plr.Name,
        Callback = function()
            pcall(function()
                local hrp = getHRPSafe()
                local target = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp and target then
                    hrp.CFrame = target.CFrame + Vector3.new(0, 3, 0)
                end
            end)
        end
    })
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then addPlayerTP(plr) end
end

track(Players.PlayerAdded:Connect(function(plr)
    task.wait(2)
    if running and plr ~= player then
        pcall(function() addPlayerTP(plr) end)
    end
end))

Tab6:Section({ Title = "Сервер", TextXAlignment = "Left", TextSize = 17 })

Tab6:Button({
    Title = "Перезайти (Rejoin)",
    Desc = "Перезайти на этот же сервер",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, player)
        end)
    end
})

Tab6:Button({
    Title = "Скопировать Job ID",
    Desc = "Для захода на конкретный сервер",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard('game:GetService("TeleportService"):TeleportToPlaceInstance(' ..
                    game.PlaceId .. ', "' .. game.JobId .. '", game.Players.LocalPlayer)')
                notify("Сервер", "Job ID скопирован", 2)
            else
                notify("Сервер", "setclipboard не поддерживается", 3)
            end
        end)
    end
})

-- =========================================================
-- ВКЛАДКА 7: МОБЫ
-- =========================================================

local antiWolfEnabled = false
local trackedWolves = {}
local holdConnection = nil
local includeCultists = false

local function isWolfModel(m)
    if not m or not m:IsA("Model") then return false end
    local name = m.Name:lower()
    local keywords = { "wolf", "bear" }
    if includeCultists then table.insert(keywords, "cultist") end
    for _, keyword in ipairs(keywords) do
        if name:find(keyword, 1, true) then return true end
    end
    return false
end

local function collectParts(model)
    local parts = {}
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(parts, d) end
    end
    return parts
end

local function saveOriginalState(model)
    if trackedWolves[model] then return end
    local info = { parts = {} }
    for _, p in ipairs(collectParts(model)) do
        info.parts[p] = { Anchored = p.Anchored, CanCollide = p.CanCollide, CFrame = p.CFrame }
    end
    trackedWolves[model] = info
end

local function restoreModel(model)
    local info = trackedWolves[model]
    if not info then return end
    for part, props in pairs(info.parts) do
        if part and part.Parent then
            pcall(function()
                part.CFrame = props.CFrame
                part.Anchored = props.Anchored
                part.CanCollide = props.CanCollide
            end)
        end
    end
    trackedWolves[model] = nil
end

local function neutralizeAndHold(model, basePos, index)
    saveOriginalState(model)
    pcall(function()
        for _, p in ipairs(collectParts(model)) do
            p.Anchored = true
            p.CanCollide = false
        end
        model:PivotTo(CFrame.new(basePos + Vector3.new(index * 2, 0, 0)))
    end)
end

local function stopAntiWolf()
    antiWolfEnabled = false
    if holdConnection then
        holdConnection:Disconnect()
        holdConnection = nil
    end
    for model in pairs(trackedWolves) do restoreModel(model) end
    trackedWolves = {}
end

table.insert(cleanupCallbacks, stopAntiWolf)

Tab7:Section({ Title = "Анти-мобы", TextXAlignment = "Left", TextSize = 17 })

Tab7:Toggle({
    Title = "Анти-волк / Анти-медведь",
    Desc = "Заморозить враждебных мобов над тобой",
    Default = false,
    Callback = function(state)
        if state then
            if holdConnection then return end
            antiWolfEnabled = true
            holdConnection = RunService.Heartbeat:Connect(function()
                if not antiWolfEnabled then return end
                local hrp = getHRPSafe()
                if not hrp then return end
                local basePos = hrp.Position + Vector3.new(0, 10, 0)
                local folder = workspace:FindFirstChild("Characters") or workspace
                local index = 0
                for _, m in ipairs(folder:GetChildren()) do
                    if isWolfModel(m) then
                        neutralizeAndHold(m, basePos, index)
                        index = index + 1
                    end
                end
            end)
            notify("Анти-мобы", "ВКЛЮЧЕНО", 2)
        else
            stopAntiWolf()
            notify("Анти-мобы", "ВЫКЛЮЧЕНО", 2)
        end
    end
})

Tab7:Toggle({
    Title = "Также культистов",
    Desc = "Замораживать и культистов",
    Default = false,
    Callback = function(state) includeCultists = state end
})

Tab7:Section({ Title = "Взаимодействие", TextXAlignment = "Left", TextSize = 17 })

local instantInteract = false
Tab7:Toggle({
    Title = "Мгновенное взаимодействие",
    Desc = "Мгновенно активировать костёр, верстак и т.д.",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state) instantInteract = state end
})

task.spawn(function()
    while running do
        if instantInteract then
            pcall(function()
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.HoldDuration > 0 then
                        prompt.HoldDuration = 0
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- =========================================================
-- ВКЛАДКА 8: ФУНКЦИИ+ (прошлые 20)
-- =========================================================

Tab8:Section({ Title = "Быстрый принос", TextXAlignment = "Left", TextSize = 17 })

local clickBring = false
Tab8:Toggle({
    Title = "Click Bring",
    Desc = "Тап/клик по вещи — она летит к тебе",
    Icon = PETAL_ICON,
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        clickBring = state
        if state then notify("Click Bring", "Тапай по вещам", 3) end
    end
})

local function clickBringAt(position)
    pcall(function()
        local cam = workspace.CurrentCamera
        local hrp = getHRPSafe()
        if not (cam and hrp) then return end
        local ray = cam:ViewportPointToRay(position.X, position.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
        if not result then return end

        local items = workspace:FindFirstChild("Items")
        if not items then return end

        local closest, closestDist = nil, 12
        for _, item in ipairs(items:GetChildren()) do
            if item:IsA("Model") or item:IsA("BasePart") then
                local pos = getPos(item)
                if pos then
                    local d = (pos - result.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = item
                    end
                end
            end
        end

        if closest then
            requestDrag:FireServer(closest)
            closest:PivotTo(CFrame.new(hrp.Position + Vector3.new(0, 3, 0)))
            stopDrag:FireServer(closest)
            notify("Click Bring", "Взято: " .. closest.Name, 1.5)
        end
    end)
end

track(UserInputService.TouchTapInWorld:Connect(function(position, gameProcessed)
    if gameProcessed or not clickBring then return end
    clickBringAt(position)
end))

track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not clickBring then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        clickBringAt(UserInputService:GetMouseLocation())
    end
end))

Tab8:Section({ Title = "Автоматизация", TextXAlignment = "Left", TextSize = 17 })

local autoFeedFire = false
local feedRadius = 60

Tab8:Toggle({
    Title = "Авто-кормление костра",
    Desc = "Автоматически кидать брёвна/уголь в костёр",
    Icon = "flame",
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        autoFeedFire = state
        if state then notify("Костёр", "Авто-кормление включено", 2) end
    end
})

Tab8:Slider({
    Title = "Радиус поиска топлива",
    Step = 10,
    Value = { Min = 20, Max = 300, Default = 60 },
    Callback = function(value) feedRadius = tonumber(value) or 60 end
})

task.spawn(function()
    while running do
        if autoFeedFire then
            pcall(function()
                local firePos = structurePos(getCampfire())
                if firePos then
                    local items = workspace:FindFirstChild("Items")
                    if items then
                        for _, item in ipairs(items:GetChildren()) do
                            if (item:IsA("Model") or item:IsA("BasePart"))
                                and (matchesList(LISTS.Log, item.Name) or matchesList(LISTS.Coal, item.Name)) then
                                local pos = getPos(item)
                                if pos and (pos - firePos).Magnitude <= feedRadius then
                                    requestDrag:FireServer(item)
                                    item:PivotTo(CFrame.new(firePos + Vector3.new(0, 6, 0)))
                                    stopDrag:FireServer(item)
                                    task.wait(0.5)
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

local autoCollect = false
local collectRadius = 50

Tab8:Toggle({
    Title = "Авто-сбор предметов",
    Desc = "Автоматически подбирать еду/мелочь рядом",
    Icon = "hand",
    Type = "Toggle",
    Default = false,
    Callback = function(state) autoCollect = state end
})

Tab8:Slider({
    Title = "Радиус сбора",
    Step = 10,
    Value = { Min = 10, Max = 150, Default = 50 },
    Callback = function(value) collectRadius = tonumber(value) or 50 end
})

local COLLECT_NAMES = {
    ["Berry"] = true, ["Carrot"] = true, ["Corn"] = true, ["Pumpkin"] = true,
    ["Apple"] = true, ["Chili"] = true, ["Bandage"] = true, ["Bolt"] = true,
    ["Sapling"] = true, ["Candy Apple"] = true, ["Cotton Candy"] = true, ["Candy Corn"] = true,
}

task.spawn(function()
    while running do
        if autoCollect then
            pcall(function()
                local hrp = getHRPSafe()
                local items = workspace:FindFirstChild("Items")
                if hrp and items then
                    for _, item in ipairs(items:GetChildren()) do
                        if (COLLECT_NAMES[item.Name] or matchesList(LISTS.Food, item.Name)) then
                            local pos = getPos(item)
                            if pos and (pos - hrp.Position).Magnitude <= collectRadius then
                                requestDrag:FireServer(item)
                                item:PivotTo(CFrame.new(hrp.Position + Vector3.new(0, 1, 0)))
                                stopDrag:FireServer(item)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.8)
    end
end)

Tab8:Section({ Title = "Выживание", TextXAlignment = "Left", TextSize = 17 })

local autoHeal = false
Tab8:Toggle({
    Title = "Авто-лечение",
    Desc = "Бандаж при HP < 50%",
    Icon = "heart",
    Type = "Toggle",
    Default = false,
    Callback = function(state) autoHeal = state end
})

task.spawn(function()
    while running do
        if autoHeal then
            pcall(function()
                local hum = getHumanoid()
                if hum and hum.Health < hum.MaxHealth * 0.5 then
                    local requestConsume = ReplicatedStorage.RemoteEvents:WaitForChild("RequestConsumeItem", 5)
                    for _, item in ipairs(workspace.Items:GetChildren()) do
                        if item.Name == "Bandage" then
                            requestConsume:InvokeServer(item)
                            break
                        end
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

local autoJump = false
Tab8:Toggle({
    Title = "Авто-прыжок",
    Desc = "Прыгать при движении",
    Default = false,
    Callback = function(state) autoJump = state end
})

task.spawn(function()
    while running do
        if autoJump then
            pcall(function()
                local hum = getHumanoid()
                if hum and hum.MoveDirection.Magnitude > 0 then
                    hum.Jump = true
                end
            end)
        end
        task.wait(0.6)
    end
end)

Tab8:Section({ Title = "Точки телепорта", TextXAlignment = "Left", TextSize = 17 })

local waypoints = { nil, nil, nil }

for i = 1, 3 do
    Tab8:Button({
        Title = "Слот " .. i .. ": Сохранить позицию",
        Desc = "Запомнить текущее место",
        Callback = function()
            local hrp = getHRPSafe()
            if hrp then
                waypoints[i] = hrp.CFrame
                notify("Точки", "Слот " .. i .. " сохранён", 2)
            end
        end
    })

    Tab8:Button({
        Title = "Слот " .. i .. ": Телепорт",
        Desc = "ТП к сохранённой точке",
        Callback = function()
            local hrp = getHRPSafe()
            if hrp and waypoints[i] then
                hrp.CFrame = waypoints[i]
            else
                notify("Точки", "Слот " .. i .. " пуст", 2)
            end
        end
    })
end

local savedReturnPos = nil

Tab8:Button({
    Title = "Запомнить место (для возврата)",
    Desc = "Перед дальней поездкой",
    Callback = function()
        local hrp = getHRPSafe()
        if hrp then
            savedReturnPos = hrp.CFrame
            notify("Возврат", "Место запомнено", 2)
        end
    end
})

Tab8:Button({
    Title = "Вернуться на место",
    Desc = "ТП к запомненному месту",
    Callback = function()
        local hrp = getHRPSafe()
        if hrp and savedReturnPos then
            hrp.CFrame = savedReturnPos
        else
            notify("Возврат", "Сначала запомни место", 2)
        end
    end
})

Tab8:Section({ Title = "Инфо на экране", TextXAlignment = "Left", TextSize = 17 })

local hudLabel
Tab8:Toggle({
    Title = "HUD (FPS + координаты)",
    Desc = "FPS и твои координаты на экране",
    Default = false,
    Callback = function(state)
        if state then
            pcall(function()
                local gui = Instance.new("ScreenGui")
                gui.Name = "SakuraHUD"
                gui.ResetOnSpawn = false
                gui.Parent = player:WaitForChild("PlayerGui", 5)

                hudLabel = Instance.new("TextLabel")
                hudLabel.Size = UDim2.new(0, 220, 0, 55)
                hudLabel.Position = UDim2.new(0, 10, 0, 10)
                hudLabel.BackgroundTransparency = 0.5
                hudLabel.BackgroundColor3 = Color3.new(0, 0, 0)
                hudLabel.TextColor3 = Color3.fromRGB(255, 106, 213)
                hudLabel.TextSize = 14
                hudLabel.Font = Enum.Font.SourceSansBold
                hudLabel.Text = "..."
                hudLabel.Parent = gui
            end)
        else
            pcall(function()
                local gui = player.PlayerGui:FindFirstChild("SakuraHUD")
                if gui then gui:Destroy() end
                hudLabel = nil
            end)
        end
    end
})

local fpsCounter = 0
track(RunService.RenderStepped:Connect(function() fpsCounter = fpsCounter + 1 end))

task.spawn(function()
    while running do
        if hudLabel and hudLabel.Parent then
            pcall(function()
                local hrp = getHRPSafe()
                local pos = hrp and hrp.Position or Vector3.zero
                hudLabel.Text = string.format("🌸 SAKURA\nFPS: %d | X:%d Y:%d Z:%d",
                    fpsCounter, math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
            end)
        end
        fpsCounter = 0
        task.wait(1)
    end
end)

Tab8:Button({
    Title = "Копировать координаты",
    Desc = "В буфер обмена",
    Callback = function()
        pcall(function()
            local hrp = getHRPSafe()
            if hrp then
                local text = string.format("Vector3.new(%d, %d, %d)",
                    math.floor(hrp.Position.X), math.floor(hrp.Position.Y), math.floor(hrp.Position.Z))
                if setclipboard then
                    setclipboard(text)
                    notify("Координаты", "Скопировано: " .. text, 2)
                else
                    notify("Координаты", text, 3)
                end
            end
        end)
    end
})

Tab8:Button({
    Title = "Убрать погодные эффекты",
    Desc = "Дожд, туман и частицы погоды",
    Callback = function()
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") and (obj.Name:lower():find("rain") or obj.Name:lower():find("snow")) then
                    obj.Enabled = false
                end
            end
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("Atmosphere") then obj.Density = 0 end
            end
            notify("Погода", "Эффекты убраны", 2)
        end)
    end
})

local nightVision = false
Tab8:Toggle({
    Title = "Ночное зрение",
    Desc = "Тёплое освещение",
    Default = false,
    Callback = function(state)
        nightVision = state
        pcall(function()
            if state then
                Lighting.Ambient = Color3.fromRGB(120, 80, 60)
                Lighting.OutdoorAmbient = Color3.fromRGB(120, 80, 60)
                Lighting.Brightness = 1.5
            else
                Lighting.Ambient = Color3.fromRGB(127, 127, 127)
                Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
                Lighting.Brightness = 1
            end
        end)
    end
})

Tab8:Button({
    Title = "ТП к ближайшему дереву",
    Desc = "Быстро добраться до дерева",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local hrp = getHRPSafe()
                local map = workspace:FindFirstChild("Map")
                if not (hrp and map) then return end

                local closest, closestDist = nil, math.huge
                local function scan(folder)
                    if not folder then return end
                    for _, tree in ipairs(folder:GetChildren()) do
                        if tree:IsA("Model") and TREE_NAMES[tree.Name] then
                            local p = getPos(tree)
                            if p then
                                local d = (p - hrp.Position).Magnitude
                                if d < closestDist then
                                    closestDist = d
                                    closest = p
                                end
                            end
                        end
                    end
                end
                scan(map:FindFirstChild("Foliage"))
                scan(map:FindFirstChild("Landmarks"))

                if closest then
                    hrp.CFrame = CFrame.new(closest + Vector3.new(0, 5, 5))
                    notify("Дерево", "ТП (" .. math.floor(closestDist) .. " м)", 2)
                end
            end)
        end)
    end
})

Tab8:Button({
    Title = "ТП к ближайшему сундуку",
    Desc = "Быстро добраться до сундука",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local hrp = getHRPSafe()
                local items = workspace:FindFirstChild("Items")
                if not (hrp and items) then return end

                local closest, closestDist = nil, math.huge
                for _, item in ipairs(items:GetChildren()) do
                    if item.Name:match("Chest") then
                        local pos = getPos(item)
                        if pos then
                            local d = (pos - hrp.Position).Magnitude
                            if d < closestDist then
                                closestDist = d
                                closest = pos
                            end
                        end
                    end
                end

                if closest then
                    hrp.CFrame = CFrame.new(closest + Vector3.new(0, 5, 0))
                    notify("Сундук", "ТП (" .. math.floor(closestDist) .. " м)", 2)
                end
            end)
        end)
    end
})

Tab8:Section({ Title = "Защита", TextXAlignment = "Left", TextSize = 17 })

local antiVoid = false
Tab8:Toggle({
    Title = "Анти-падение в пустоту",
    Desc = "Если падаешь ниже Y=-20 — вернуть наверх",
    Default = false,
    Callback = function(state) antiVoid = state end
})

task.spawn(function()
    while running do
        if antiVoid then
            pcall(function()
                local hrp = getHRPSafe()
                if hrp and hrp.Position.Y < -20 then
                    hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
                end
            end)
        end
        task.wait(0.3)
    end
end)

local positionLock = false
local lockedPos = nil

Tab8:Toggle({
    Title = "Заморозка позиции",
    Desc = "Тебя не сдвинуть с места",
    Default = false,
    Callback = function(state)
        positionLock = state
        if state then
            local hrp = getHRPSafe()
            lockedPos = hrp and hrp.Position
            if lockedPos then notify("Заморозка", "Позиция зафиксирована", 2) end
        end
    end
})

track(RunService.Heartbeat:Connect(function()
    if positionLock and lockedPos then
        pcall(function()
            local hrp = getHRPSafe()
            if hrp and (hrp.Position - lockedPos).Magnitude > 2 then
                hrp.CFrame = CFrame.new(lockedPos)
            end
        end)
    end
end))

Tab8:Button({
    Title = "Собрать ВСЁ рядом (25м)",
    Desc = "Подобрать все предметы в радиусе 25 метров",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local hrp = getHRPSafe()
                local items = workspace:FindFirstChild("Items")
                if not (hrp and items) then return end

                local count = 0
                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") or item:IsA("BasePart") then
                        local pos = getPos(item)
                        if pos and (pos - hrp.Position).Magnitude <= 25 then
                            pcall(function()
                                requestDrag:FireServer(item)
                                item:PivotTo(CFrame.new(hrp.Position + Vector3.new(0, 1, 0)))
                                stopDrag:FireServer(item)
                            end)
                            count = count + 1
                        end
                    end
                end
                notify("Сбор", "Собрано предметов: " .. count, 2)
            end)
        end)
    end
})

Tab8:Button({
    Title = "Слетать к костру и вернуться",
    Desc = "ТП к костру, 3 сек, ТП обратно",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local hrp = getHRPSafe()
                if not hrp then return end
                local start = hrp.CFrame
                local firePos = structurePos(getCampfire())
                if not firePos then
                    notify("Ошибка", "Костёр не найден", 2)
                    return
                end
                hrp.CFrame = CFrame.new(firePos + Vector3.new(0, 5, 0))
                task.wait(3)
                if running then
                    hrp = getHRPSafe()
                    if hrp then hrp.CFrame = start end
                end
            end)
        end)
    end
})

-- =========================================================
-- 🆕 ВКЛАДКА 9: ЭКСТРА — 20 НОВЫХ ФУНКЦИЙ
-- =========================================================

Tab9:Section({ Title = "Фарм и авто", TextXAlignment = "Left", TextSize = 17 })

-- 1. Авто-рубка одного дерева (ближайшего, добивать пока не упадёт)
local autoFinishTree = false
Tab9:Toggle({
    Title = "1. Добивание дерева",
    Desc = "Автоматически рубить ближайшее дерево до конца",
    Icon = "axe",
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        autoFinishTree = state
        if state then
            task.spawn(function()
                while running and autoFinishTree do
                    pcall(function()
                        local hrp = getHRPSafe()
                        local weapon = getWeapon()
                        local map = workspace:FindFirstChild("Map")
                        if not (hrp and weapon and map) then return end

                        local closest, closestDist = nil, math.huge
                        local function scan(folder)
                            if not folder then return end
                            for _, tree in ipairs(folder:GetChildren()) do
                                if tree:IsA("Model") and TREE_NAMES[tree.Name] and tree.Parent then
                                    local p = getPos(tree)
                                    if p and (p - hrp.Position).Magnitude <= 60 then
                                        local d = (p - hrp.Position).Magnitude
                                        if d < closestDist then
                                            closestDist = d
                                            closest = tree
                                        end
                                    end
                                end
                            end
                        end
                        scan(map:FindFirstChild("Foliage"))
                        scan(map:FindFirstChild("Landmarks"))

                        if closest then
                            ReplicatedStorage.RemoteEvents.ToolDamageObject:InvokeServer(
                                closest, weapon, 999, hrp.CFrame)
                        end
                    end)
                    task.wait(0.25)
                end
            end)
        end
    end
})

-- 2. Авто-крафт досок (Logs to Planks — положить брёвна к костру и ждём)
local autoLogsToFire = false
Tab9:Toggle({
    Title = "2. Авто-скидка брёвен в костёр",
    Desc = "Кидать все брёвна в костёр автоматически",
    Default = false,
    Callback = function(state)
        autoLogsToFire = state
    end
})

task.spawn(function()
    while running do
        if autoLogsToFire then
            pcall(function()
                local firePos = structurePos(getCampfire())
                local items = workspace:FindFirstChild("Items")
                if firePos and items then
                    for _, item in ipairs(items:GetChildren()) do
                        if item.Name == "Log" then
                            local pos = getPos(item)
                            if pos and (pos - firePos).Magnitude > 6 then
                                requestDrag:FireServer(item)
                                item:PivotTo(CFrame.new(firePos + Vector3.new(0, 6, 0)))
                                stopDrag:FireServer(item)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- 3. Авто-подбор детей рядом (приносить их)
local autoBringChildren = false
Tab9:Toggle({
    Title = "3. Авто-подбор детей",
    Desc = "Автоматически подходить к детям рядом (бета)",
    Icon = "baby",
    Type = "Toggle",
    Default = false,
    Callback = function(state)
        autoBringChildren = state
    end
})

task.spawn(function()
    while running do
        if autoBringChildren then
            pcall(function()
                local hrp = getHRPSafe()
                local chars = workspace:FindFirstChild("Characters")
                if hrp and chars then
                    for _, child in ipairs(chars:GetChildren()) do
                        if isLostChild(child) then
                            local p = getPos(child)
                            if p and (p - hrp.Position).Magnitude <= 60 then
                                -- подходим к ребёнку
                                hrp.CFrame = CFrame.new(p + Vector3.new(0, 2, 2))
                                task.wait(2)
                                break
                            end
                        end
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

-- 4. Авто-сбор дров из поваленных деревьев
local autoCollectLogs = false
Tab9:Toggle({
    Title = "4. Авто-сбор брёвен",
    Desc = "Подбирать появившиеся брёвна рядом (после рубки)",
    Default = false,
    Callback = function(state)
        autoCollectLogs = state
    end
})

task.spawn(function()
    while running do
        if autoCollectLogs then
            pcall(function()
                local hrp = getHRPSafe()
                local items = workspace:FindFirstChild("Items")
                if hrp and items then
                    for _, item in ipairs(items:GetChildren()) do
                        if item.Name == "Log" then
                            local pos = getPos(item)
                            if pos and (pos - hrp.Position).Magnitude <= 40 then
                                requestDrag:FireServer(item)
                                item:PivotTo(CFrame.new(hrp.Position + Vector3.new(0, 1, 0)))
                                stopDrag:FireServer(item)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- 5. Авто-скрытие при опасности (мобы рядом → прыгнуть на дерево)
local autoEvade = false
Tab9:Toggle({
    Title = "5. Авто-уклонение",
    Desc = "Моб ближе 15м → телепорт вверх на 30м",
    Icon = "shield",
    Type = "Toggle",
    Default = false,
    Callback = function(state) autoEvade = state end
})

task.spawn(function()
    while running do
        if autoEvade then
            pcall(function()
                local hrp = getHRPSafe()
                local chars = workspace:FindFirstChild("Characters")
                if hrp and chars then
                    for _, mob in ipairs(chars:GetChildren()) do
                        if mob:IsA("Model") and not isLostChild(mob) and not isPlayerChar(mob)
                            and mob ~= player.Character then
                            local p = getPos(mob)
                            if p then
                                local d = (p - hrp.Position).Magnitude
                                if d <= 15 then
                                    local hum = mob:FindFirstChildOfClass("Humanoid")
                                    if not (hum and hum.Health <= 0) then
                                        hrp.CFrame = hrp.CFrame + Vector3.new(0, 30, 0)
                                        notify("Уклонение", "Моб рядом! Прыжок вверх", 1.5)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- 6. Автопринятие смертей (анти-смерть через respawn при HP=0)
local antiDeath = false
Tab9:Toggle({
    Title = "6. Анти-смерть (respawn)",
    Desc = "При HP=0 мгновенный respawn",
    Default = false,
    Callback = function(state) antiDeath = state end
})

task.spawn(function()
    while running do
        if antiDeath then
            pcall(function()
                local hum = getHumanoid()
                if hum and hum.Health <= 0 then
                    player.Character:Destroy()
                    player:LoadCharacter()
                    notify("Анти-смерть", "Respawn выполнен", 2)
                    task.wait(3)
                end
            end)
        end
        task.wait(0.3)
    end
end)

Tab9:Section({ Title = "Визуал", TextXAlignment = "Left", TextSize = 17 })

-- 7. Скрыть UI игры (чистый экран)
local hideGameUI = false
Tab9:Toggle({
    Title = "7. Скрыть UI игры",
    Desc = "Чистый экран без интерфейса игры",
    Default = false,
    Callback = function(state)
        hideGameUI = state
        pcall(function()
            local gui = player.PlayerGui:FindFirstChild("Interface")
            if gui then
                gui.Enabled = not state
            end
        end)
    end
})

-- 8. Увеличить дистанцию видимости имён ESP
local espMaxDistance = 5000
Tab9:Slider({
    Title = "8. Дистанция ESP имён",
    Step = 100,
    Value = { Min = 100, Max = 10000, Default = 5000 },
    Callback = function(value) espMaxDistance = tonumber(value) or 5000 end
})

-- (применяется к BillboardGui — через пересоздание не делаем, для простоты информационный)

-- 9. Крутящаяся сакура-декорация над головой (флер)
local sakuraDecor = false
local sakuraPart
Tab9:Toggle({
    Title = "9. Сакура над головой",
    Desc = "Крутящийся цветок над тобой 🌸",
    Default = false,
    Callback = function(state)
        sakuraDecor = state
        if state then
            pcall(function()
                sakuraPart = Instance.new("Part")
                sakuraPart.Name = "SakuraDecor"
                sakuraPart.Size = Vector3.new(1.5, 1.5, 1.5)
                sakuraPart.Anchored = true
                sakuraPart.CanCollide = false
                sakuraPart.CanQuery = false
                sakuraPart.Material = Enum.Material.Neon
                sakuraPart.Color = Color3.fromRGB(255, 130, 200)
                sakuraPart.Shape = Enum.PartType.Ball
                sakuraPart.Parent = workspace.CurrentCamera
            end)
        else
            if sakuraPart then sakuraPart:Destroy() sakuraPart = nil end
        end
    end
})

local decorAngle = 0
track(RunService.RenderStepped:Connect(function(dt)
    if sakuraDecor and sakuraPart and sakuraPart.Parent then
        local hrp = getHRPSafe()
        if hrp then
            decorAngle = decorAngle + dt * 2
            sakuraPart.CFrame = CFrame.new(hrp.Position + Vector3.new(
                math.cos(decorAngle) * 2, 4, math.sin(decorAngle) * 2))
        end
    end
end))

table.insert(cleanupCallbacks, function()
    if sakuraPart then pcall(function() sakuraPart:Destroy() end) end
end)

-- 10. Радужный ник над головой
local rainbowName = false
local rainbowBillboard
Tab9:Toggle({
    Title = "10. Радужный ник",
    Desc = "Цветной текст над твоей головой",
    Default = false,
    Callback = function(state)
        rainbowName = state
        if state then
            pcall(function()
                local hrp = getHRPSafe()
                if not hrp then return end
                rainbowBillboard = Instance.new("BillboardGui")
                rainbowBillboard.Size = UDim2.new(0, 200, 0, 40)
                rainbowBillboard.StudsOffset = Vector3.new(0, 4, 0)
                rainbowBillboard.AlwaysOnTop = true
                rainbowBillboard.Adornee = hrp
                rainbowBillboard.Parent = hrp

                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 1, 0)
                text.BackgroundTransparency = 1
                text.Text = player.Name .. " ✿"
                text.TextSize = 16
                text.Font = Enum.Font.SourceSansBold
                text.TextStrokeTransparency = 0
                text.Parent = rainbowBillboard
            end)
        else
            if rainbowBillboard then rainbowBillboard:Destroy() rainbowBillboard = nil end
        end
    end
})

task.spawn(function()
    local hue = 0
    while running do
        if rainbowName and rainbowBillboard then
            pcall(function()
                local label = rainbowBillboard:FindFirstChildWhichIsA("TextLabel")
                if label then
                    hue = (hue + 0.01) % 1
                    label.TextColor3 = Color3.fromHSV(hue, 1, 1)
                end
            end)
        end
        task.wait(0.05)
    end
end)

table.insert(cleanupCallbacks, function()
    if rainbowBillboard then pcall(function() rainbowBillboard:Destroy() end) end
end)

-- 11. Скрыть траву (для видимости)
Tab9:Button({
    Title = "11. Скрыть всю траву",
    Desc = "Лучше видно землю и предметы",
    Callback = function()
        pcall(function()
            local map = workspace:FindFirstChild("Map")
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj.Name:lower():find("grass") or obj.Name:lower():find("bush") then
                        if obj:IsA("BasePart") then
                            obj.Transparency = 1
                            obj.CanCollide = false
                        elseif obj:IsA("Model") then
                            for _, p in ipairs(obj:GetDescendants()) do
                                if p:IsA("BasePart") then
                                    p.Transparency = 1
                                    p.CanCollide = false
                                end
                            end
                        end
                    end
                end
            end
            notify("Визуал", "Трава скрыта", 2)
        end)
    end
})

-- 12. Скрыть листву деревьев (видеть сквозь)
Tab9:Button({
    Title = "12. Прозрачная листва",
    Desc = "Видеть сквозь листья деревьев",
    Callback = function()
        pcall(function()
            local map = workspace:FindFirstChild("Map")
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj.Name:lower():find("leaf") or obj.Name:lower():find("foliage") then
                        if obj:IsA("BasePart") then
                            obj.Transparency = 0.85
                        end
                    end
                end
            end
            notify("Визуал", "Листва прозрачная", 2)
        end)
    end
})

Tab9:Section({ Title = "Сервер и социальное", TextXAlignment = "Left", TextSize = 17 })

-- 13. Пинг сервера (измерение)
Tab9:Button({
    Title = "13. Замерить пинг",
    Desc = "Показать задержку до сервера",
    Callback = function()
        task.spawn(function()
            local t0 = os.clock()
            local remote = ReplicatedStorage.RemoteEvents:FindFirstChild("Ping")
            if remote then
                pcall(function() remote:FireServer() end)
            end
            -- приблизительный замер через NetworkStats
            local ping = 0
            pcall(function()
                local stats = game:GetService("Stats"):FindFirstChild("Network")
                if stats then
                    local serverStats = stats:FindFirstChild("Server")
                    if serverStats then
                        ping = serverStats:FindFirstChild("Ping") and serverStats.Ping.Value or 0
                    end
                end
            end)
            notify("Пинг", (ping > 0 and ping .. " мс" or "не измерить напрямую"), 3)
        end)
    end
})

-- 14. Чат-спамер (медленный, чтобы не бан)
local chatSpam = false
local spamMessage = "🌸 SAKURA by Kefi 🌸"

Tab9:Toggle({
    Title = "14. Чат-спамер",
    Desc = "Отправлять сообщение каждые 5 сек",
    Default = false,
    Callback = function(state) chatSpam = state end
})

Tab9:Input({
    Title = "Сообщение спама",
    Default = "🌸 SAKURA by Kefi 🌸",
    Callback = function(value) spamMessage = value end
})

task.spawn(function()
    while running do
        if chatSpam then
            pcall(function()
                local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents", true)
                if chatRemote then
                    local sayMessage = chatRemote:FindFirstChild("SayMessageRequest")
                    if sayMessage then
                        sayMessage:FireServer(spamMessage, "All")
                    end
                end
            end)
        end
        task.wait(5)
    end
end)

-- 15. Список игроков на сервере
Tab9:Button({
    Title = "15. Кто на сервере",
    Desc = "Показать всех игроков с пингом",
    Callback = function()
        local names = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            table.insert(names, plr.Name)
        end
        notify("Сервер", #names .. " игроков: " .. table.concat(names, ", "), 8)
    end
})

-- 16. Таймер сессии (сколько ты играешь)
local sessionStart = os.clock()
local sessionLabel

Tab9:Toggle({
    Title = "16. Таймер сессии",
    Desc = "Сколько ты играешь на экране",
    Default = false,
    Callback = function(state)
        if state then
            pcall(function()
                local gui = Instance.new("ScreenGui")
                gui.Name = "SakuraSession"
                gui.ResetOnSpawn = false
                gui.Parent = player:WaitForChild("PlayerGui", 5)

                sessionLabel = Instance.new("TextLabel")
                sessionLabel.Size = UDim2.new(0, 200, 0, 30)
                sessionLabel.Position = UDim2.new(0, 10, 0, 70)
                sessionLabel.BackgroundTransparency = 0.5
                sessionLabel.BackgroundColor3 = Color3.new(0, 0, 0)
                sessionLabel.TextColor3 = Color3.fromRGB(255, 106, 213)
                sessionLabel.TextSize = 14
                sessionLabel.Font = Enum.Font.SourceSansBold
                sessionLabel.Text = "..."
                sessionLabel.Parent = gui
            end)
        else
            pcall(function()
                local gui = player.PlayerGui:FindFirstChild("SakuraSession")
                if gui then gui:Destroy() end
                sessionLabel = nil
            end)
        end
    end
})

task.spawn(function()
    while running do
        if sessionLabel and sessionLabel.Parent then
            pcall(function()
                local elapsed = os.clock() - sessionStart
                local mins = math.floor(elapsed / 60)
                local secs = math.floor(elapsed % 60)
                sessionLabel.Text = string.format("🌸 В игре: %d мин %d сек", mins, secs)
            end)
        end
        task.wait(1)
    end
end)

-- 17. Авто-очистка инвентаря (выкинуть лишнее — нет ремоута, просто info)
Tab9:Button({
    Title = "17. Инфо об инвентаре",
    Desc = "Что у тебя в инвентаре",
    Callback = function()
        pcall(function()
            local inv = player:FindFirstChild("Inventory")
            if inv then
                local names = {}
                for _, item in ipairs(inv:GetChildren()) do
                    table.insert(names, item.Name)
                end
                notify("Инвентарь", #names .. " предметов: " .. table.concat(names, ", "), 8)
            else
                notify("Инвентарь", "Инвентарь не найден", 2)
            end
        end)
    end
})

-- 18. Все ремоуты игры (для изучения)
Tab9:Button({
    Title = "18. Список ремоутов",
    Desc = "Все RemoteEvents игры (в консоль F9)",
    Callback = function()
        pcall(function()
            local events = ReplicatedStorage.RemoteEvents:GetChildren()
            print("=== SAKURA: РЕМОУТЫ ИГРЫ ===")
            for _, ev in ipairs(events) do
                print(ev.Name, ev.ClassName)
            end
            print("=============================")
            notify("Ремоуты", #events .. " шт. — смотри консоль (F9)", 4)
        end)
    end
})

-- 19. Авто-возврат к костру если далеко (на ночь)
local autoReturnNight = false
Tab9:Toggle({
    Title = "19. Авто-возврат ночью",
    Desc = "Когда ClockTime > 18 (ночь) — ТП к костру",
    Default = false,
    Callback = function(state) autoReturnNight = state end
})

task.spawn(function()
    while running do
        if autoReturnNight then
            pcall(function()
                local time = Lighting.ClockTime
                if time >= 18 or time <= 6 then
                    local hrp = getHRPSafe()
                    local firePos = structurePos(getCampfire())
                    if hrp and firePos and (hrp.Position - firePos).Magnitude > 100 then
                        hrp.CFrame = CFrame.new(firePos + Vector3.new(0, 5, 0))
                        notify("Ночь", "Авто-возврат к костру", 2)
                        task.wait(5)
                    end
                end
            end)
        end
        task.wait(10)
    end
end)

-- 20. Мини-карта (метка костра всегда на экране)
Tab9:Section({ Title = "Навигация", TextXAlignment = "Left", TextSize = 17 })

local fireMarker = false
local markerBillboard

Tab9:Toggle({
    Title = "20. Метка костра",
    Desc = "Стрелка-подсказка к костру (даже далеко)",
    Default = false,
    Callback = function(state)
        fireMarker = state
        if state then
            pcall(function()
                local fire = getCampfire()
                local root = fire and getRoot(fire)
                if root then
                    markerBillboard = Instance.new("BillboardGui")
                    markerBillboard.Size = UDim2.new(0, 100, 0, 40)
                    markerBillboard.StudsOffset = Vector3.new(0, 10, 0)
                    markerBillboard.AlwaysOnTop = true
                    markerBillboard.MaxDistance = 10000
                    markerBillboard.Adornee = root
                    markerBillboard.Parent = root

                    local text = Instance.new("TextLabel")
                    text.Size = UDim2.new(1, 0, 1, 0)
                    text.BackgroundTransparency = 1
                    text.Text = "🔥 КОСТЁР"
                    text.TextColor3 = Color3.fromRGB(255, 150, 50)
                    text.TextSize = 18
                    text.Font = Enum.Font.SourceSansBold
                    text.TextStrokeTransparency = 0
                    text.Parent = markerBillboard
                else
                    notify("Метка", "Костёр не найден", 2)
                    fireMarker = false
                end
            end)
        else
            if markerBillboard then markerBillboard:Destroy() markerBillboard = nil end
        end
    end
})

table.insert(cleanupCallbacks, function()
    if markerBillboard then pcall(function() markerBillboard:Destroy() end) end
end)

notify("SAKURA v4.0", "Готово! Bring ускорен + 20 новых функций 🌸", 4)
print("[SAKURA] v4.0 Загружено. By Kefi 🌸")
