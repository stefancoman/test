-- Check if gamesense is already loaded
if getgenv().gamesense and getgenv().gamesense.loaded then
    warn("GS ALREADY LOADED GG")
else
    -- Initialize gamesense
    getgenv().gamesense = {
        ["loaded"] = true
    }
    
    -- Services
    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Debris = game:GetService("Debris")
    
    -- URL for loading external libraries
    local baseUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/ "
    
    -- Load libraries
    local Library = loadstring(game:HttpGet(baseUrl .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(baseUrl .. "addons/ThemeManager.lua"))()
    local SaveManager = loadstring(game:HttpGet(baseUrl .. "addons/SaveManager.lua"))()
    
    -- Library shortcuts
    local Options = Library.Options
    local Toggles = Library.Toggles
    
    -- Library settings
    Library.ForceCheckbox = false
    Library.ShowToggleFrameInKeybinds = true
    
    -- Create main window
    local Window = Library:CreateWindow({
        ["Title"] = "gamesense.mps",
        ["Footer"] = "version: 1.0-B",
        ["Icon"] = 70680258649133,
        ["NotifySide"] = "Right",
        ["ShowCustomCursor"] = true
    })
    
    -- Tab storage
    local Tabs = {}
    
    -- Prediction storage
    local Prediction = {
        ["BallPrediction"] = {}
    }
    
    -- GUI protection
    local protectgui = protectgui or function() end
    
    -- Core GUI getter
    local gethui = gethui or function()
        return game:GetService("CoreGui")
    end
    
    -- Game variables
    local isAlternativeGame = false
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character
    local Humanoid = Character:WaitForChild("Humanoid")
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    local Balls = nil
    local BallList = {}
    
    -- Find ball container
    if workspace:FindFirstChild("Balls", true) then
        Balls = workspace:FindFirstChild("Balls", true)
    else
        local children = workspace:GetChildren()
        isAlternativeGame = true
        
        for _, child in pairs(children) do
            if child.Name == "fakeBaIlExpIoiter" or child.Name == "fakeBall" or 
               child.Name == "MPS" or child.Name == "TPS" or child.Name == "CSF" or
               child.Name == "lî´ì„ì®ilì·ìµiì´ì¬ì®iIì·ì„ì¬ilì¶ì„ì®ilì´ì•ì¬Iìµìƒì¹iì´ì¬ì¨" then
                table.insert(BallList, child)
            end
        end
    end
    
    -- Create screen GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = tostring(math.random(100000, 999999))
    ScreenGui.IgnoreGuiInset = true
    pcall(protectgui, ScreenGui)
    
    if not pcall(function()
        ScreenGui.Parent = gethui()
    end) then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Dumbass image
    local DumbassImage = Instance.new("ImageLabel")
    DumbassImage.Name = "Dumbass"
    DumbassImage.AnchorPoint = Vector2.new(1, 1)
    DumbassImage.BackgroundTransparency = 1
    DumbassImage.Position = UDim2.new(1, 25, 1, 15)
    DumbassImage.Size = UDim2.new(0, 150, 0, 300)
    DumbassImage.Image = "rbxassetid://95334651149795"
    DumbassImage.Visible = false
    DumbassImage.Parent = ScreenGui
    
    -- Reach visualizer
    local ReachSphere = Instance.new("Part")
    ReachSphere.Name = tostring(math.random(100000, 999999))
    ReachSphere.Shape = Enum.PartType.Ball
    ReachSphere.Size = Vector3.new(10, 10, 10)
    ReachSphere.CFrame = CFrame.new(math.huge, math.huge, math.huge)
    ReachSphere.Anchored = true
    ReachSphere.CanCollide = false
    ReachSphere.CanTouch = false
    ReachSphere.CanQuery = false
    ReachSphere.Massless = true
    ReachSphere.Transparency = 0.9
    ReachSphere.Material = Enum.Material.SmoothPlastic
    ReachSphere.CastShadow = false
    ReachSphere.Parent = workspace
    
    -- Track active constraints
    local ActiveConstraints = {}
    
    -- Physics-based touch simulation (stealth mode)
    local function simulateNaturalTouch(ball, characterPart, duration)
        duration = duration or 0.05
        
        if ActiveConstraints[ball] then return end
        
        ActiveConstraints[ball] = true
        
        local ballAttachment = Instance.new("Attachment")
        ballAttachment.Name = "NaturalTouchBall"
        ballAttachment.Parent = ball
        
        local partAttachment = Instance.new("Attachment")
        partAttachment.Name = "NaturalTouchPart"
        partAttachment.Parent = characterPart
        
        local alignPosition = Instance.new("AlignPosition")
        alignPosition.Name = "NaturalTouchAlign"
        alignPosition.ApplyAtCenterOfMass = true
        alignPosition.Attachment0 = ballAttachment
        alignPosition.Attachment1 = partAttachment
        alignPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
        alignPosition.MaxAxesForce = Vector3.new(2000, 2000, 2000)
        alignPosition.Responsiveness = 150
        alignPosition.Parent = ball
        
        task.wait(duration)
        
        Debris:AddItem(ballAttachment, 0)
        Debris:AddItem(partAttachment, 0)
        Debris:AddItem(alignPosition, 0)
        
        ActiveConstraints[ball] = nil
    end
    
    -- Math helpers for prediction
    local function solveQuadratic(a, b, c)
        local solution1 = (-b + math.sqrt(b * b - 4 * a * c)) / (2 * a)
        local solution2 = (-b - math.sqrt(b * b - 4 * a * c)) / (2 * a)
        return solution1 < solution2 and solution2 or solution1
    end
    
    local function calculatePosition(v0, t, startPos, g)
        local yPos = v0.Y * t + 0.5 * -g * (t * t)
        return startPos + Vector3.new(v0.X * t, yPos, v0.Z * t)
    end
    
    local function predictBallPosition(velocity, startPos, gravity, accuracy)
        local time = solveQuadratic(0.5 * -gravity, velocity.Y, startPos.Y)
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        if isAlternativeGame then
            raycastParams.FilterDescendantsInstances = {BallList}
        else
            raycastParams.FilterDescendantsInstances = {Balls}
        end
        
        local currentPos = startPos
        
        for i = 1, accuracy do
            local segmentTime = time * (1 / accuracy * i)
            local predictedPos = calculatePosition(velocity, segmentTime, currentPos, gravity)
            local raycastResult = workspace:Raycast(startPos, predictedPos - startPos)
            
            if raycastResult then
                local hitY = raycastResult.Position.Y
                return calculatePosition(velocity, solveKinematic(-gravity, velocity.Y, hitY, currentPos.Y), currentPos, gravity)
            end
            
            currentPos = predictedPos
        end
        
        return currentPos + Vector3.new(velocity.X, 0, velocity.Z) * time + 
               Vector3.new(0, v0.Y * time + 0.5 * -gravity * (time * time), 0)
    end
    
    local function clearPrediction(predictionType)
        for _, instance in pairs(Prediction[predictionType]) do
            if instance:IsA("Instance") then
                instance:Destroy()
            end
        end
        Prediction[predictionType] = {}
    end
    
    local function createBallPrediction(ball)
        local predictedPos = predictBallPosition(
            ball.AssemblyLinearVelocity, 
            ball.Position, 
            workspace.Gravity, 
            Options.BallPredAccuracy.Value
        )
        
        local startAttachment = Instance.new("Attachment")
        startAttachment.Name = tostring(math.random(100000, 999999))
        startAttachment.WorldPosition = ball.Position
        startAttachment.Parent = workspace.Terrain
        table.insert(Prediction.BallPrediction, startAttachment)
        
        local endAttachment = Instance.new("Attachment")
        endAttachment.Name = tostring(math.random(100000, 999999))
        endAttachment.WorldPosition = predictedPos
        endAttachment.Parent = workspace.Terrain
        table.insert(Prediction.BallPrediction, endAttachment)
        
        local beam = Instance.new("Beam")
        beam.Name = tostring(math.random(100000, 999999))
        beam.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Options.BallPredTrailColor1.Value), 
            ColorSequenceKeypoint.new(1, Options.BallPredTrailColor2.Value)
        })
        beam.LightEmission = 0
        beam.LightInfluence = 0
        beam.Brightness = 1
        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, Options.BallPredTrailColor1.Transparency), 
            NumberSequenceKeypoint.new(1, Options.BallPredTrailColor2.Transparency)
        })
        beam.Attachment0 = startAttachment
        beam.Attachment1 = endAttachment
        beam.FaceCamera = true
        beam.Width0 = Options.BallPredTrailSize.Value
        beam.Width1 = Options.BallPredTrailSize.Value
        beam.Parent = ball
        table.insert(Prediction.BallPrediction, beam)
    end
    
    -- Create tabs
    Tabs.Reach = Window:AddTab("Reach", "footprints")
    Tabs.Ball = Window:AddTab("Ball", "volleyball")
    Tabs.Character = Window:AddTab("Character", "volleyball")
    Tabs.Visuals = Window:AddTab("Visuals", "eye")
    Tabs.Config = Window:AddTab("UI Settings", "settings")
    
    -- Reach tab setup
    local ReachLeft = Tabs.Reach:AddLeftGroupbox("Main")
    local ReachRight = Tabs.Reach:AddRightTabbox()
    
    local ReachMain = nil
    local ReachShoot = nil
    local ReachPass = nil
    local ReachLong = nil
    local ReachTackle = nil
    local ReachDribble = nil
    local ReachSave = nil
    
    if UserInputService.TouchEnabled then
        ReachMain = ReachRight:AddTab("Main")
    else
        ReachShoot = ReachRight:AddTab("Shoot")
        ReachPass = ReachRight:AddTab("Pass")
        ReachLong = ReachRight:AddTab("Long")
        ReachTackle = ReachRight:AddTab("Tackle")
        ReachDribble = ReachRight:AddTab("Dribble")
        ReachSave = ReachRight:AddTab("Save")
    end
    
    ReachLeft:AddToggle("ReachMasterToggle", {
        ["Text"] = "Enabled",
        ["Tooltip"] = "Master toggle for reach."
    })
    
    ReachLeft:AddToggle("ReachVisualizerToggle", {
        ["Text"] = "Visualizer",
        ["Tooltip"] = "Visualizer of the reach sphere."
    }):AddColorPicker("ReachVisualizerColor", {
        ["Default"] = Color3.new(1, 1, 1),
        ["Title"] = "Visualizer Color.",
        ["Transparency"] = 0.9
    })
    
    local function addReachSettings(tab, actionName)
        tab:AddToggle("Reach" .. actionName .. "Toggle", {
            ["Text"] = "Enabled",
            ["Tooltip"] = "Toggle for " .. string.lower(actionName) .. " reach."
        })
        
        tab:AddToggle("InfiniteReach" .. actionName .. "Toggle", {
            ["Text"] = "Infinite Reach",
            ["Risky"] = true,
            ["Tooltip"] = "Makes the " .. string.lower(actionName) .. " reach infinite."
        })
        
        tab:AddToggle("Reach" .. actionName .. "CompToggle", {
            ["Text"] = "Comp Reach",
            ["Tooltip"] = "Reaches only if you dont have network ownership."
        })
        
        -- NEW: Touch method selector
        tab:AddDropdown("Reach" .. actionName .. "Method", {
            ["Values"] = { "firetouchinterest", "Natural Physics", "Hybrid" },
            ["Default"] = "firetouchinterest",
            ["Text"] = "Touch Method",
            ["Tooltip"] = "firetouchinterest: Instant, most effective. Natural: Physics-based, stealthier. Hybrid: Randomly alternates."
        })
        
        -- NEW: Randomization slider
        tab:AddSlider("Reach" .. actionName .. "Randomization", {
            ["Text"] = "Randomization %",
            ["Default"] = 0,
            ["Min"] = 0,
            ["Max"] = 50,
            ["Rounding"] = 0,
            ["Tooltip"] = "Adds random delay/variation to make touches less predictable. 0 = disabled."
        })
        
        tab:AddSlider("Reach" .. actionName .. "Radius", {
            ["Text"] = "Reach Radius",
            ["Default"] = 10,
            ["Min"] = 0,
            ["Max"] = 300,
            ["Rounding"] = 1,
            ["Tooltip"] = "Sets the " .. string.lower(actionName) .. " reach radius (sphere)."
        })
        
        tab:AddSlider("Reach" .. actionName .. "OffsetX", {
            ["Text"] = "Offset X",
            ["Default"] = 0,
            ["Min"] = -10,
            ["Max"] = 10,
            ["Rounding"] = 1,
            ["Tooltip"] = "Sets the " .. string.lower(actionName) .. " reach X offset."
        })
        
        tab:AddSlider("Reach" .. actionName .. "OffsetY", {
            ["Text"] = "Offset Y",
            ["Default"] = 0,
            ["Min"] = -10,
            ["Max"] = 10,
            ["Rounding"] = 1,
            ["Tooltip"] = "Sets the " .. string.lower(actionName) .. " reach Y offset."
        })
        
        tab:AddSlider("Reach" .. actionName .. "OffsetZ", {
            ["Text"] = "Offset Z",
            ["Default"] = 0,
            ["Min"] = -10,
            ["Max"] = 10,
            ["Rounding"] = 1,
            ["Tooltip"] = "Sets the " .. string.lower(actionName) .. " reach Z offset."
        })
        
        tab:AddDropdown("Reach" .. actionName .. "BallSelector", {
            ["Values"] = { "Closest to character", "Furthest to character" },
            ["Default"] = "Closest to character",
            ["Text"] = "Ball selection",
            ["Tooltip"] = "Choose which ball should be the prority for reach."
        })
    end
    
    if UserInputService.TouchEnabled then
        addReachSettings(ReachMain, "Main")
    else
        addReachSettings(ReachShoot, "Shoot")
        addReachSettings(ReachPass, "Pass")
        addReachSettings(ReachLong, "Long")
        addReachSettings(ReachTackle, "Tackle")
        addReachSettings(ReachDribble, "Dribble")
        addReachSettings(ReachSave, "Save")
    end
    
    -- Ball tab
    local BallLeft = Tabs.Ball:AddLeftGroupbox("Main")
    local BallRight = Tabs.Ball:AddRightGroupbox("Macros")
    
    BallLeft:AddToggle("BallPredToggle", {
        ["Text"] = "Ball Prediction",
        ["Tooltip"] = "Predicts where the ball will land.",
        ["Default"] = false
    }):AddColorPicker("BallPredTrailColor1", {
        ["Default"] = Color3.new(1, 1, 1),
        ["Title"] = "Color",
        ["Transparency"] = 0
    }):AddColorPicker("BallPredTrailColor2", {
        ["Default"] = Color3.new(1, 1, 1),
        ["Title"] = "Color",
        ["Transparency"] = 0
    })
    
    BallLeft:AddSlider("BallPredTrailSize", {
        ["Text"] = "Trail Size",
        ["Default"] = 0.1,
        ["Min"] = 0.01,
        ["Max"] = 0.5,
        ["Rounding"] = 2
    })
    
    BallLeft:AddSlider("BallPredHZ", {
        ["Text"] = "Refresh Rate",
        ["Default"] = 0.1,
        ["Min"] = 0,
        ["Max"] = 1,
        ["Rounding"] = 2
    })
    
    BallLeft:AddSlider("BallPredThreshold", {
        ["Text"] = "Prediction Threshold",
        ["Default"] = 25,
        ["Min"] = 0,
        ["Max"] = 100,
        ["Rounding"] = 0
    })
    
    BallLeft:AddSlider("BallPredAccuracy", {
        ["Text"] = "Prediction Accuracy",
        ["Default"] = 5,
        ["Min"] = 1,
        ["Max"] = 10,
        ["Rounding"] = 0
    })
    
    BallRight:AddToggle("HomboloMacroToggle", {
        ["Text"] = "Hombolo Macro",
        ["Tooltip"] = "Makes the ball always be over your head.",
        ["Default"] = false
    }):AddKeyPicker("HomboloMacroKeybind", {
        ["Default"] = "None",
        ["SyncToggleState"] = true,
        ["Mode"] = "Toggle",
        ["Text"] = "Hombolo Macro"
    })
    
    -- Character tab
    local CharacterLeft = Tabs.Character:AddLeftGroupbox("Humanoid")
    
    CharacterLeft:AddToggle("CharSpeedToggle", {
        ["Text"] = "Speed",
        ["Tooltip"] = "Changes how fast the character moves. (CFrame based)",
        ["Default"] = false
    })
    
    CharacterLeft:AddSlider("CharSpeed", {
        ["Text"] = "Speed Value",
        ["Default"] = 0,
        ["Min"] = 0,
        ["Max"] = 10,
        ["Rounding"] = 1
    })
    
    -- Visuals tab
    local VisualsLighting = Tabs.Visuals:AddLeftGroupbox("Lighting")
    local VisualsBall = Tabs.Visuals:AddRightGroupbox("Ball")
    local VisualsOther = Tabs.Visuals:AddRightGroupbox("Other")
    
    VisualsLighting:AddToggle("SkyboxColorToggle", {
        ["Text"] = "Skybox Color",
        ["Tooltip"] = "Changes the skybox color of your chocie.",
        ["Default"] = false
    }):AddColorPicker("SkyboxColor", {
        ["Default"] = Color3.new(1, 1, 1),
        ["Title"] = "Skybox Color"
    }):AddColorPicker("SkyboxDecay", {
        ["Default"] = Color3.new(1, 1, 1),
        ["Title"] = "Skybox Decay"
    })
    
    VisualsLighting:AddSlider("SkyboxGlare", {
        ["Text"] = "Skybox Glare",
        ["Default"] = 1,
        ["Min"] = 0,
        ["Max"] = 10,
        ["Rounding"] = 2
    })
    
    VisualsLighting:AddSlider("SkyboxHaze", {
        ["Text"] = "Skybox Haze",
        ["Default"] = 1,
        ["Min"] = 0,
        ["Max"] = 10,
        ["Rounding"] = 2
    })
    
    VisualsLighting:AddDivider()
    
    VisualsLighting:AddToggle("CorrectionToggle", {
        ["Text"] = "Correction",
        ["Tooltip"] = "Lets you correct the lighting in the game.",
        ["Default"] = false
    }):AddColorPicker("CorrectionColor", {
        ["Default"] = Color3.new(1, 1, 1),
        ["Title"] = "Tint Color"
    })
    
    VisualsLighting:AddSlider("CorrectionBrightness", {
        ["Text"] = "Brightness",
        ["Default"] = 0,
        ["Min"] = -1,
        ["Max"] = 1,
        ["Rounding"] = 2
    })
    
    VisualsLighting:AddSlider("CorrectionContrast", {
        ["Text"] = "Contrast",
        ["Default"] = 0,
        ["Min"] = -1,
        ["Max"] = 1,
        ["Rounding"] = 2
    })
    
    VisualsLighting:AddSlider("CorrectionSaturation", {
        ["Text"] = "Saturation",
        ["Default"] = 0,
        ["Min"] = -1,
        ["Max"] = 1,
        ["Rounding"] = 2
    })
    
    VisualsOther:AddToggle("DumbassToggle", {
        ["Text"] = "Dumbass on your screen",
        ["Tooltip"] = "What do you even want to know?",
        ["Default"] = false
    })
    
    -- Config tab
    local ConfigLeft = Tabs.Config:AddLeftGroupbox("Menu")
    
    ConfigLeft:AddToggle("KeybindMenuOpen", {
        ["Default"] = Library.KeybindFrame.Visible,
        ["Text"] = "Open Keybind Menu",
        ["Callback"] = function(Value)
            Library.KeybindFrame.Visible = Value
        end
    })
    
    ConfigLeft:AddToggle("ShowCustomCursor", {
        ["Text"] = "Custom Cursor",
        ["Default"] = true,
        ["Callback"] = function(Value)
            Library.ShowCustomCursor = Value
        end
    })
    
    ConfigLeft:AddDropdown("NotificationSide", {
        ["Values"] = { "Left", "Right" },
        ["Default"] = "Right",
        ["Text"] = "Notification Side",
        ["Callback"] = function(Value)
            Library:SetNotifySide(Value)
        end
    })
    
    ConfigLeft:AddDropdown("DPIDropdown", {
        ["Values"] = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        ["Default"] = "100%",
        ["Text"] = "DPI Scale",
        ["Callback"] = function(Value)
            local scale = Value:gsub("%%", "")
            Library:SetDPIScale(tonumber(scale))
        end
    })
    
    ConfigLeft:AddDivider()
    
    ConfigLeft:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
        ["Default"] = "RightShift",
        ["NoUI"] = true,
        ["Text"] = "Menu keybind"
    })
    
    Library.ToggleKeybind = Options.MenuKeybind
    
    -- Setup theme and save managers
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    ThemeManager:SetFolder("gamesense-mps")
    SaveManager:SetFolder("gamesense-mps/mps")
    SaveManager:BuildConfigSection(Tabs.Config)
    ThemeManager:ApplyToTab(Tabs.Config)
    SaveManager:LoadAutoloadConfig()
    
    -- Randomization helper
    local function getRandomizedValue(baseValue, percentage)
        if percentage <= 0 then return baseValue end
        local variation = baseValue * (percentage / 100)
        return baseValue + math.random(-variation * 100, variation * 100) / 100
    end
    
    -- Event handlers
    Toggles.DumbassToggle:OnChanged(function()
        DumbassImage.Visible = Toggles.DumbassToggle.Value
    end)
    
    -- Skybox color
    local Atmosphere = nil
    local OriginalAtmosphere = nil
    
    Toggles.SkyboxColorToggle:OnChanged(function()
        if Toggles.SkyboxColorToggle.Value then
            if Lighting:FindFirstChildOfClass("Atmosphere") then
                OriginalAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
                OriginalAtmosphere.Parent = nil
            end
            
            if Atmosphere then Atmosphere:Destroy() end
            
            Atmosphere = Instance.new("Atmosphere")
            Atmosphere.Name = tostring(math.random(100000, 999999))
            Atmosphere.Density = 0
            Atmosphere.Offset = 0
            Atmosphere.Color = Options.SkyboxColor.Value
            Atmosphere.Decay = Options.SkyboxDecay.Value
            Atmosphere.Glare = Options.SkyboxGlare.Value
            Atmosphere.Haze = Options.SkyboxHaze.Value
            Atmosphere.Parent = Lighting
        else
            if Atmosphere then Atmosphere:Destroy() end
            
            if OriginalAtmosphere then
                OriginalAtmosphere.Parent = Lighting
                OriginalAtmosphere = nil
            end
        end
    end)
    
    Options.SkyboxColor:OnChanged(function()
        if Atmosphere then Atmosphere.Color = Options.SkyboxColor.Value end
    end)
    
    Options.SkyboxDecay:OnChanged(function()
        if Atmosphere then Atmosphere.Decay = Options.SkyboxDecay.Value end
    end)
    
    Options.SkyboxGlare:OnChanged(function()
        if Atmosphere then Atmosphere.Glare = Options.SkyboxGlare.Value end
    end)
    
    Options.SkyboxHaze:OnChanged(function()
        if Atmosphere then Atmosphere.Haze = Options.SkyboxHaze.Value end
    end)
    
    -- Color correction
    local ColorCorrection = nil
    local OriginalColorCorrection = nil
    
    Toggles.CorrectionToggle:OnChanged(function()
        if Toggles.CorrectionToggle.Value then
            if Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
                OriginalColorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                OriginalColorCorrection.Parent = nil
            end
            
            if ColorCorrection then ColorCorrection:Destroy() end
            
            ColorCorrection = Instance.new("ColorCorrectionEffect")
            ColorCorrection.Name = tostring(math.random(100000, 999999))
            ColorCorrection.Brightness = Options.CorrectionBrightness.Value
            ColorCorrection.Contrast = Options.CorrectionContrast.Value
            ColorCorrection.Saturation = Options.CorrectionSaturation.Value
            ColorCorrection.TintColor = Options.CorrectionColor.Value
            ColorCorrection.Parent = Lighting
        else
            if ColorCorrection then ColorCorrection:Destroy() end
            
            if OriginalColorCorrection then
                OriginalColorCorrection.Parent = Lighting
                OriginalColorCorrection = nil
            end
        end
    end)
    
    Options.CorrectionColor:OnChanged(function()
        if ColorCorrection then ColorCorrection.TintColor = Options.CorrectionColor.Value end
    end)
    
    Options.CorrectionBrightness:OnChanged(function()
        if ColorCorrection then ColorCorrection.Brightness = Options.CorrectionBrightness.Value end
    end)
    
    Options.CorrectionContrast:OnChanged(function()
        if ColorCorrection then ColorCorrection.Contrast = Options.CorrectionContrast.Value end
    end)
    
    Options.CorrectionSaturation:OnChanged(function()
        if ColorCorrection then ColorCorrection.Saturation = Options.CorrectionSaturation.Value end
    end)
    
    -- Hombolo macro
    local BallAttachment = nil
    local HeadAttachment = nil
    local BallAlignPosition = nil
    local TargetBall = nil
    
    Toggles.HomboloMacroToggle:OnChanged(function()
        if Toggles.HomboloMacroToggle.Value then
            if HumanoidRootPart and Character:FindFirstChild("Head") then
                local ballList = isAlternativeGame and BallList or Balls:GetChildren()
                
                table.sort(ballList, function(a, b)
                    return (a.Position - HumanoidRootPart.Position).Magnitude < (b.Position - HumanoidRootPart.Position).Magnitude
                end)
                
                if #ballList > 0 then
                    TargetBall = ballList[1]
                    
                    BallAttachment = Instance.new("Attachment")
                    BallAttachment.Name = tostring(math.random(100000, 999999))
                    BallAttachment.Parent = TargetBall
                    
                    HeadAttachment = Instance.new("Attachment")
                    HeadAttachment.Name = tostring(math.random(100000, 999999))
                    HeadAttachment.Parent = Character.Head
                    
                    BallAlignPosition = Instance.new("AlignPosition")
                    BallAlignPosition.Name = tostring(math.random(100000, 999999))
                    BallAlignPosition.ApplyAtCenterOfMass = true
                    BallAlignPosition.Attachment0 = BallAttachment
                    BallAlignPosition.Attachment1 = HeadAttachment
                    BallAlignPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
                    BallAlignPosition.MaxAxesForce = Vector3.new(math.huge, 0, math.huge)
                    BallAlignPosition.Responsiveness = 200
                    BallAlignPosition.Parent = TargetBall
                end
            end
        else
            if BallAttachment then BallAttachment:Destroy() end
            if HeadAttachment then HeadAttachment:Destroy() end
            if BallAlignPosition then BallAlignPosition:Destroy() end
            TargetBall = nil
        end
    end)
    
    -- Character added
    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        Character = newCharacter
        Humanoid = Character:WaitForChild("Humanoid")
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        
        local success = pcall(function()
            for _, func in pairs(getgc(true)) do
                if typeof(func) == "function" then
                    local funcName = debug.info(func, "n")
                    
                    if funcName == "reachcheck" or funcName == "touchingcheck" then
                        hookfunction(func, newcclosure(function()
                            return false
                        end))
                    elseif funcName == "IsBallBoundingHitbox" then
                        hookfunction(func, newcclosure(function()
                            return true
                        end))
                    end
                end
            end
        end)
        
        if not success then
            Library:Notify({
                ["Title"] = "Critical Error",
                ["Description"] = "Your executor does not support hookfunction!",
                ["Time"] = 10
            })
        end
    end)
    
    -- Initial hook
    local success = pcall(function()
        for _, func in pairs(getgc(true)) do
            if typeof(func) == "function" then
                local funcName = debug.info(func, "n")
                
                if funcName == "reachcheck" or funcName == "touchingcheck" then
                    hookfunction(func, newcclosure(function()
                        return false
                    end))
                elseif funcName == "IsBallBoundingHitbox" then
                    hookfunction(func, newcclosure(function()
                        return true
                    end))
                end
            end
        end
    end)
    
    if not success then
        Library:Notify({
            ["Title"] = "Critical Error",
            ["Description"] = "Your executor does not support hookfunction!",
            ["Time"] = 10
        })
    end
    
    -- Update ball list for alternative games
    if isAlternativeGame then
        workspace.ChildAdded:Connect(function()
            BallList = {}
            for _, child in pairs(workspace:GetChildren()) do
                if child.Name == "fakeBaIlExpIoiter" or child.Name == "fakeBall" or 
                   child.Name == "MPS" or child.Name == "TPS" or child.Name == "CSF" or
                   child.Name == "lî´ì„ì®ilì·ìµiì´ì¬ì®iIì·ì„ì¬ilì¶ì„ì®ilì´ì•ì¬Iìµìƒì¹iì´ì¬ì¨" then
                    table.insert(BallList, child)
                end
            end
        end)
        
        workspace.ChildRemoved:Connect(function()
            BallList = {}
            for _, child in pairs(workspace:GetChildren()) do
                if child.Name == "fakeBaIlExpIoiter" or child.Name == "fakeBall" or 
                   child.Name == "MPS" or child.Name == "TPS" or child.Name == "CSF" or
                   child.Name == "lî´ì„ì®ilì·ìµiì´ì¬ì®iIì·ì„ì¬ilì¶ì„ì®ilì´ì•ì¬Iìµìƒì¹iì´ì¬ì¨" then
                    table.insert(BallList, child)
                end
            end
        end)
    end
    
    -- Main reach loop
    RunService.RenderStepped:Connect(function(deltaTime)
        if HumanoidRootPart and Humanoid then
            if Toggles.ReachMasterToggle.Value then
                local currentAction = nil
                local isInfinite = false
                
                if UserInputService.TouchEnabled and Toggles.ReachMainToggle and Toggles.ReachMainToggle.Value then
                    currentAction = "Main"
                    isInfinite = Toggles.InfiniteReachMainToggle.Value
                elseif (Character:FindFirstChild("Shoot") or Character:FindFirstChild("Kick")) and Toggles.ReachShootToggle.Value then
                    currentAction = "Shoot"
                    isInfinite = Toggles.InfiniteReachShootToggle.Value
                elseif Character:FindFirstChild("Pass") and Toggles.ReachPassToggle.Value then
                    currentAction = "Pass"
                    isInfinite = Toggles.InfiniteReachPassToggle.Value
                elseif Character:FindFirstChild("Long") and Toggles.ReachLongToggle.Value then
                    currentAction = "Long"
                    isInfinite = Toggles.InfiniteReachLongToggle.Value
                elseif Character:FindFirstChild("Tackle") and Toggles.ReachTackleToggle.Value then
                    currentAction = "Tackle"
                    isInfinite = Toggles.InfiniteReachTackleToggle.Value
                elseif Character:FindFirstChild("Dribble") and Toggles.ReachDribbleToggle.Value then
                    currentAction = "Dribble"
                    isInfinite = Toggles.InfiniteReachDribbleToggle.Value
                elseif (Character:FindFirstChild("Save") or Character:FindFirstChild("Clear") or Character:FindFirstChild("GK")) and Toggles.ReachSaveToggle.Value then
                    currentAction = "Save"
                    isInfinite = Toggles.InfiniteReachSaveToggle.Value
                end
                
                local reachCenter = HumanoidRootPart.Position
                if currentAction then
                    reachCenter = HumanoidRootPart.CFrame * Vector3.new(
                        Options["Reach" .. currentAction .. "OffsetX"].Value,
                        Options["Reach" .. currentAction .. "OffsetY"].Value,
                        Options["Reach" .. currentAction .. "OffsetZ"].Value
                    )
                end
                
                if Toggles.ReachVisualizerToggle.Value and currentAction then
                    ReachSphere.Size = Vector3.new(
                        Options["Reach" .. currentAction .. "Radius"].Value * 2,
                        Options["Reach" .. currentAction .. "Radius"].Value * 2,
                        Options["Reach" .. currentAction .. "Radius"].Value * 2
                    )
                    ReachSphere.CFrame = CFrame.new(reachCenter)
                    ReachSphere.Color = Options.ReachVisualizerColor.Value
                    ReachSphere.Transparency = Options.ReachVisualizerColor.Transparency
                else
                    ReachSphere.CFrame = CFrame.new(math.huge, math.huge, math.huge)
                end
                
                task.spawn(function()
                    RunService.Heartbeat:Wait()
                    
                    local touchingParts = {}
                    
                    if isInfinite then
                        touchingParts = isAlternativeGame and BallList or Balls:GetChildren()
                    elseif currentAction then
                        local radius = Options["Reach" .. currentAction .. "Radius"].Value
                        local overlapParams = OverlapParams.new()
                        overlapParams.FilterType = Enum.RaycastFilterType.Include
                        overlapParams.FilterDescendantsInstances = isAlternativeGame and BallList or {Balls}
                        
                        touchingParts = workspace:GetPartsInRadius(reachCenter, radius, overlapParams)
                    end
                    
                    table.sort(touchingParts, function(a, b)
                        return (a.Position - HumanoidRootPart.Position).Magnitude < (b.Position - HumanoidRootPart.Position).Magnitude
                    end)
                    
                    if #touchingParts > 0 then
                        local closestBall = touchingParts[1]
                        
                        if currentAction and Toggles["Reach" .. currentAction .. "CompToggle"].Value and 
                           (closestBall:FindFirstChild("Owner") or closestBall:FindFirstChild("owner")) then
                            local owner = closestBall:WaitForChild("Owner") or closestBall:WaitForChild("owner")
                            if owner.Value == LocalPlayer or owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer.UserId then
                                return
                            end
                        end
                        
                        -- Randomization
                        local randomPercent = Options["Reach" .. currentAction .. "Randomization"].Value
                        if math.random(1, 100) <= randomPercent then
                            task.wait(math.random(1, 3) / 100)
                        end
                        
                        -- Touch method selection
                        local method = Options["Reach" .. currentAction .. "Method"].Value
                        if method == "firetouchinterest" or (method == "Hybrid" and math.random(1, 2) == 1) then
                            -- Original method - instant and effective
                            for _, part in pairs(Character:GetChildren()) do
                                if part:IsA("Part") then
                                    firetouchinterest(part, closestBall, 0)
                                    firetouchinterest(part, closestBall, 1)
                                end
                            end
                        else
                            -- Natural physics method - stealthier
                            simulateNaturalTouch(closestBall, HumanoidRootPart, 0.05)
                        end
                    end
                end)
            else
                ReachSphere.CFrame = CFrame.new(math.huge, math.huge, math.huge)
            end
        end
    end)
    
    -- Speed
    RunService.Heartbeat:Connect(function(deltaTime)
        if HumanoidRootPart and Humanoid and Toggles.CharSpeedToggle.Value and Character.PrimaryPart then
            Character.PrimaryPart:PivotTo(Character.PrimaryPart.CFrame + Humanoid.MoveDirection * deltaTime * Options.CharSpeed.Value)
        end
    end)
    
    -- Ball prediction
    task.spawn(function()
        while task.wait(Options.BallPredHZ.Value) do
            clearPrediction("BallPrediction")
            
            if Toggles.BallPredToggle.Value then
                if isAlternativeGame then
                    for _, ball in pairs(BallList) do
                        if ball.AssemblyLinearVelocity.Magnitude > Options.BallPredThreshold.Value then
                            createBallPrediction(ball)
                        end
                    end
                else
                    for _, ball in pairs(Balls:GetChildren()) do
                        if ball.AssemblyLinearVelocity.Magnitude > Options.BallPredThreshold.Value then
                            createBallPrediction(ball)
                        end
                    end
                end
            end
        end
    end)
    
    -- Notification
    Library:Notify({
        ["Title"] = "Successfully Loaded!",
        ["Description"] = "Creator: @bb6e8091174043e899a5adca956772dd",
        ["Time"] = 10
    })
end
