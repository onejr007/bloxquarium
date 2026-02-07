--[[
    AdminGui.client.luau (v30.0 - Integrated Database Editor)
    - Removed Modal system to prevent "Black Screen" issue.
    - Integrated Player Data Editor directly into the Database tab.
    - Added "Back" navigation for better UX.
    - Fixed UI redraw issues.
]]

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local TS      = game:GetService("TweenService")
local RunS    = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")

local Remote  = require(RS.Shared.RemoteClient)
local Assets  = require(RS.Shared.AssetManagerV3)

local Player  = Players.LocalPlayer
local IsInitialized = false

--// THEME CONFIG
local CFG = {
    CLR = {
        ACCENT    = Color3.fromRGB(0, 255, 180),
        PRIMARY   = Color3.fromRGB(10, 11, 15),
        SECONDARY = Color3.fromRGB(20, 22, 28),
        TERTIARY  = Color3.fromRGB(30, 33, 40),
        BORDER    = Color3.fromRGB(255, 255, 255),
        TEXT      = Color3.fromRGB(240, 240, 240),
        SUBTEXT   = Color3.fromRGB(120, 125, 140),
        ERROR     = Color3.fromRGB(255, 70, 70),
        SUCCESS   = Color3.fromRGB(70, 255, 120),
    },
    TWEEN = {
        FAST   = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        SMOOTH = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        BOUNCE = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        EXPO   = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    },
    FONT = {
        MAIN = Enum.Font.GothamMedium,
        BOLD = Enum.Font.GothamBold,
        MONO = Enum.Font.RobotoMono
    }
}

--// UI FACTORY & UTILS
local function New(c, p, t) 
    local i = Instance.new(c) 
    for k,v in pairs(t) do i[k] = v end 
    i.Parent = p 
    return i 
end

local function ApplyCorner(i, r) 
    return New("UICorner", i, {CornerRadius = UDim.new(0, r or 8)}) 
end

local function ApplyStroke(i, c, t, trans) 
    return New("UIStroke", i, {
        Thickness = t or 1, 
        Color = c or CFG.CLR.BORDER, 
        Transparency = trans or 0.85, 
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }) 
end

local function CreateHoverEffect(btn, target, hoverColor, originalColor)
    originalColor = originalColor or target.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TS:Create(target, CFG.TWEEN.FAST, {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(target, CFG.TWEEN.FAST, {BackgroundColor3 = originalColor}):Play()
    end)
end

local function Log(m) print(string.format(" <[HYPERION_ZENITH]> : %s", m:upper())) end

--// MAIN UI & TAB LOGIC
local function CreateHyperionInterface(parent)
    local Main = New("CanvasGroup", parent, {
        Name = "HyperionMain", 
        Size = UDim2.fromScale(0.8, 0.75), 
        Position = UDim2.fromScale(0.5, 0.55), 
        AnchorPoint = Vector2.new(0.5, 0.5), 
        BackgroundColor3 = CFG.CLR.PRIMARY, 
        GroupTransparency = 1, 
        Visible = false
    })
    ApplyCorner(Main, 14)
    ApplyStroke(Main, CFG.CLR.ACCENT, 1.5, 0.7)

    local Sidebar = New("Frame", Main, {
        Name = "Sidebar", 
        Size = UDim2.new(0, 220, 1, 0), 
        BackgroundColor3 = CFG.CLR.SECONDARY
    })
    ApplyStroke(Sidebar, nil, 1, 0.9)

    local LogoArea = New("Frame", Sidebar, {Size = UDim2.new(1, 0, 0, 100), BackgroundTransparency = 1})
    New("TextLabel", LogoArea, {
        Size = UDim2.fromScale(1, 1), 
        BackgroundTransparency = 1, 
        RichText = true, 
        Font = CFG.FONT.MONO, 
        TextSize = 18, 
        TextColor3 = CFG.CLR.TEXT, 
        Text = "<b>HYPERION</b><font color='#00FFB4'>_ZENITH</font>\n<font size='9' color='#808080'>ADMINISTRATION V2</font>"
    })

    local NavScroll = New("ScrollingFrame", Sidebar, {
        Position = UDim2.fromOffset(0, 100),
        Size = UDim2.new(1, 0, 1, -120), 
        BackgroundTransparency = 1, 
        ScrollBarThickness = 0, 
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    New("UIListLayout", NavScroll, {Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    New("UIPadding", NavScroll, {PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15)})

    local MainContent = New("Frame", Main, {
        Name = "MainContent", 
        Position = UDim2.fromOffset(220, 0),
        Size = UDim2.new(1, -220, 1, 0), 
        BackgroundTransparency = 1
    })
    
    local PageHeader = New("TextLabel", MainContent, {
        Size = UDim2.new(1, -60, 0, 80), 
        Position = UDim2.fromOffset(30, 0), 
        BackgroundTransparency = 1, 
        Font = CFG.FONT.BOLD, 
        TextSize = 24, 
        TextColor3 = CFG.CLR.TEXT, 
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local Container = New("CanvasGroup", MainContent, {
        Name = "Container", 
        Size = UDim2.new(1, -60, 1, -110), 
        Position = UDim2.fromOffset(30, 80), 
        BackgroundTransparency = 1
    })

    local activeTabName
    local navButtons = {}

    local function SwitchTab(tabName)
        if activeTabName == tabName then return end
        activeTabName = tabName
        
        for name, btn in pairs(navButtons) do
            local isSelected = (name == tabName)
            TS:Create(btn.Button, CFG.TWEEN.FAST, {BackgroundColor3 = isSelected and CFG.CLR.TERTIARY or Color3.new(0,0,0), BackgroundTransparency = isSelected and 0 or 1}):Play()
            TS:Create(btn.Label, CFG.TWEEN.FAST, {TextColor3 = isSelected and CFG.CLR.ACCENT or CFG.CLR.SUBTEXT}):Play()
            TS:Create(btn.Indicator, CFG.TWEEN.FAST, {BackgroundTransparency = isSelected and 0 or 1}):Play()
        end

        PageHeader.Text = tabName:upper()
        local fadeOut = TS:Create(Container, CFG.TWEEN.FAST, {GroupTransparency = 1, Position = UDim2.fromOffset(30, 90)})
        fadeOut:Play()

        fadeOut.Completed:Once(function()
            if activeTabName ~= tabName then return end
            for _, v in pairs(Container:GetChildren()) do v:Destroy() end

            if tabName == "Database" then
                local allPlayerData = {}
                local currentPage = 1
                local itemsPerPage = 8
                
                local ListFrame = New("Frame", Container, {Name = "ListFrame", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
                local EditFrame = New("Frame", Container, {Name = "EditFrame", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false})

                --// LIST VIEW LOGIC
                local Toolbar = New("Frame", ListFrame, {Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1})
                local SearchBox = New("TextBox", Toolbar, {
                    Size = UDim2.new(0, 250, 1, 0), 
                    PlaceholderText = "SEARCH PLAYER...", 
                    BackgroundColor3 = CFG.CLR.SECONDARY, 
                    TextColor3 = CFG.CLR.TEXT, 
                    Font = CFG.FONT.MAIN, 
                    TextSize = 13
                }); ApplyCorner(SearchBox, 6); ApplyStroke(SearchBox); New("UIPadding", SearchBox, {PaddingLeft = UDim.new(0, 12)})

                local Pagination = New("Frame", Toolbar, {Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(1, -200, 0, 0), BackgroundTransparency = 1})
                local prevB = New("TextButton", Pagination, {Size = UDim2.new(0, 35, 1, 0), Text = "<", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT}); ApplyCorner(prevB, 6)
                local PageLabel = New("TextLabel", Pagination, {Size = UDim2.new(0, 130, 1, 0), Position = UDim2.fromOffset(35, 0), Text = "PAGE 1/1", Font = CFG.FONT.BOLD, TextSize = 11, TextColor3 = CFG.CLR.SUBTEXT, BackgroundTransparency = 1})
                local nextB = New("TextButton", Pagination, {Size = UDim2.new(0, 35, 1, 0), Position = UDim2.new(1, -35, 0, 0), Text = ">", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT}); ApplyCorner(nextB, 6)

                local DataDisplay = New("ScrollingFrame", ListFrame, {
                    Position = UDim2.fromOffset(0, 60),
                    Size = UDim2.new(1, 0, 1, -100), 
                    BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = CFG.CLR.ACCENT, AutomaticCanvasSize = Enum.AutomaticSize.Y
                }); New("UIListLayout", DataDisplay, {Padding = UDim.new(0, 8)})

                local StatusLabel = New("TextLabel", ListFrame, {Size = UDim2.new(0.5, 0, 0, 30), Position = UDim2.new(0, 0, 1, -30), Text = "READY", Font = CFG.FONT.MONO, TextSize = 10, TextColor3 = CFG.CLR.SUBTEXT, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
                local refB = New("TextButton", ListFrame, {Size = UDim2.new(0, 100, 0, 30), Position = UDim2.new(1, -100, 1, -30), Text = "REFRESH", BackgroundColor3 = CFG.CLR.ACCENT, TextColor3 = CFG.CLR.PRIMARY, Font = CFG.FONT.BOLD, TextSize = 10}); ApplyCorner(refB, 4)

                local function showEditor(pData)
                    ListFrame.Visible = false
                    EditFrame.Visible = true
                    for _, v in pairs(EditFrame:GetChildren()) do v:Destroy() end

                    local BackBtn = New("TextButton", EditFrame, {Size = UDim2.new(0, 80, 0, 30), Text = "← BACK", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.BOLD, TextSize = 11}); ApplyCorner(BackBtn, 4)
                    New("TextLabel", EditFrame, {Size = UDim2.new(1, -100, 0, 30), Position = UDim2.fromOffset(90, 0), Text = "EDITING: " .. pData.name:upper(), Font = CFG.FONT.BOLD, TextSize = 14, TextColor3 = CFG.CLR.ACCENT, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
                    
                    local EditScroll = New("ScrollingFrame", EditFrame, {Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -100), BackgroundTransparency = 1, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y})
                    New("UIListLayout", EditScroll, {Padding = UDim.new(0, 12)})
                    
                    local inputs = {}
                    for key, val in pairs(pData) do
                        if key ~= "userId" and key ~= "name" and type(val) ~= "table" then
                            local row = New("Frame", EditScroll, {Size = UDim2.new(1, -10, 0, 50), BackgroundColor3 = CFG.CLR.SECONDARY}); ApplyCorner(row, 6); ApplyStroke(row, nil, 1, 0.9)
                            New("TextLabel", row, {Size = UDim2.new(0, 150, 1, 0), Position = UDim2.fromOffset(15, 0), Text = key:upper(), Font = CFG.FONT.BOLD, TextSize = 11, TextColor3 = CFG.CLR.SUBTEXT, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
                            local inp = New("TextBox", row, {Size = UDim2.new(1, -180, 0, 30), Position = UDim2.new(0, 165, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = tostring(val), Font = CFG.FONT.MONO, TextSize = 13, BackgroundColor3 = CFG.CLR.TERTIARY, TextColor3 = CFG.CLR.TEXT}); ApplyCorner(inp, 4); New("UIPadding", inp, {PaddingLeft = UDim.new(0, 10)})
                            inputs[key] = {inp = inp, originalType = type(val)}
                        end
                    end

                    local SaveBtn = New("TextButton", EditFrame, {Size = UDim2.new(0, 150, 0, 40), Position = UDim2.new(1, -150, 1, -40), Text = "SAVE CHANGES", BackgroundColor3 = CFG.CLR.ACCENT, TextColor3 = CFG.CLR.PRIMARY, Font = CFG.FONT.BOLD, TextSize = 12}); ApplyCorner(SaveBtn, 6)
                    
                    BackBtn.MouseButton1Click:Connect(function() EditFrame.Visible = false; ListFrame.Visible = true end)
                    SaveBtn.MouseButton1Click:Connect(function()
                        local newData = {}
                        for k, v in pairs(inputs) do
                            local txt = v.inp.Text
                            if v.originalType == "number" then newData[k] = tonumber(txt) or 0
                            elseif v.originalType == "boolean" then newData[k] = (txt:lower() == "true")
                            else newData[k] = txt end
                        end
                        Remote:FireServer("UpdatePlayerData", pData.userId, newData)
                        for idx, d in ipairs(allPlayerData) do
                            if tostring(d.userId) == tostring(pData.userId) then
                                for key, val in pairs(newData) do allPlayerData[idx][key] = val end
                                break
                            end
                        end
                        EditFrame.Visible = false; ListFrame.Visible = true
                        -- No need to renderPage here, it'll update on next search/refresh
                    end)
                end

                local function renderPage()
                    if not DataDisplay then return end
                    for _, child in ipairs(DataDisplay:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
                    local filtered = {}
                    local st = SearchBox.Text:lower()
                    for _, d in pairs(allPlayerData) do
                        if st == "" or (d.name:lower():find(st)) or (tostring(d.userId):find(st)) then table.insert(filtered, d) end
                    end
                    
                    local totalPages = math.max(1, math.ceil(#filtered / itemsPerPage))
                    currentPage = math.clamp(currentPage, 1, totalPages)
                    PageLabel.Text = string.format("PAGE %d / %d", currentPage, totalPages)
                    
                    local start = (currentPage - 1) * itemsPerPage + 1
                    local finish = math.min(start + itemsPerPage - 1, #filtered)
                    for i = start, finish do
                        local d = filtered[i]
                        local row = New("Frame", DataDisplay, {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = CFG.CLR.SECONDARY}); ApplyCorner(row, 6); ApplyStroke(row, nil, 1, 0.95)
                        New("TextLabel", row, {Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(15, 0), BackgroundTransparency = 1, Text = d.name:upper(), Font = CFG.FONT.BOLD, TextColor3 = CFG.CLR.TEXT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
                        local eB = New("TextButton", row, {Size = UDim2.new(0, 70, 0, 28), Position = UDim2.new(1, -85, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = "EDIT", BackgroundColor3 = CFG.CLR.TERTIARY, TextColor3 = CFG.CLR.ACCENT, Font = CFG.FONT.BOLD, TextSize = 10}); ApplyCorner(eB, 4)
                        eB.MouseButton1Click:Connect(function() showEditor(d) end)
                    end
                end

                local function fetchData()
                    StatusLabel.Text = "FETCHING..."
                    Remote:InvokeServer("RequestAllPlayerData"):andThen(function(data)
                        if not data or activeTabName ~= "Database" then return end
                        local arr = {}
                        for uid, p in pairs(data) do
                            p.userId = uid
                            local obj = Players:GetPlayerByUserId(tonumber(uid))
                            p.name = obj and obj.Name or "[OFFLINE]"
                            table.insert(arr, p)
                        end
                        allPlayerData = arr; renderPage()
                        StatusLabel.Text = "DATA SYNCED"; if SearchBox then SearchBox:CaptureFocus(); task.wait(); SearchBox:ReleaseFocus() end
                    end)
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(renderPage)
                prevB.MouseButton1Click:Connect(function() currentPage=math.max(1,currentPage-1); renderPage() end)
                nextB.MouseButton1Click:Connect(function() currentPage=currentPage+1; renderPage() end)
                refB.MouseButton1Click:Connect(fetchData); fetchData()
            else
                New("TextLabel", Container, {Size = UDim2.fromScale(1, 1), Text = "MODULE_OFFLINE", Font = CFG.FONT.MONO, TextSize = 20, TextColor3 = CFG.CLR.SUBTEXT, BackgroundTransparency = 1})
            end
            TS:Create(Container, CFG.TWEEN.EXPO, {GroupTransparency = 0, Position = UDim2.fromOffset(30, 80)}):Play()
        end)
    end

    for _, name in ipairs({"Overview", "Database", "Execution", "Networking", "Security", "Settings"}) do
        local btn = New("TextButton", NavScroll, {Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, Text = ""})
        ApplyCorner(btn, 6)
        local label = New("TextLabel", btn, {Size = UDim2.new(1,-15,1,0), Position=UDim2.fromOffset(15,0), BackgroundTransparency=1, Text=name:upper(), Font=CFG.FONT.BOLD, TextColor3=CFG.CLR.SUBTEXT, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left})
        local ind = New("Frame", btn, {Size=UDim2.new(0,3,0,18), Position=UDim2.new(0,2,0.5,0), AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=CFG.CLR.ACCENT, BackgroundTransparency=1}); ApplyCorner(ind, 2)
        btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
        navButtons[name] = {Button = btn, Label = label, Indicator = ind}
        CreateHoverEffect(btn, btn, CFG.CLR.TERTIARY, Color3.new(0,0,0))
    end
    SwitchTab("Overview")
    return Main
end

--// SYSTEM BOOT
function Boot()
    if IsInitialized then return end; IsInitialized = true
    Log("Zenith OS Online. Booting UI...")
    local SG = New("ScreenGui", Player.PlayerGui, {Name = "HyperionZenith", IgnoreGuiInset = true, ResetOnSpawn = false})
    local UI = CreateHyperionInterface(SG)
    local TBtn = New("ImageButton", SG, {Name = "ToggleButton", Size = UDim2.fromOffset(45, 45), Position = UDim2.new(0, 30, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = CFG.CLR.PRIMARY, Image = Assets.get("Admin_ico"), ImageColor3 = CFG.CLR.SUBTEXT, ZIndex = 10}); ApplyCorner(TBtn, 22); ApplyStroke(TBtn, CFG.CLR.ACCENT, 1.5, 0.6)
    
    local active = false
    TBtn.MouseButton1Click:Connect(function()
        active = not active; UI.Visible = true
        if active then
            TS:Create(UI, CFG.TWEEN.EXPO, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}):Play()
            TS:Create(TBtn, CFG.TWEEN.BOUNCE, {ImageColor3 = CFG.CLR.ACCENT, Rotation = 180, BackgroundColor3 = CFG.CLR.SECONDARY}):Play()
        else
            local tw = TS:Create(UI, CFG.TWEEN.SMOOTH, {GroupTransparency = 1, Position = UDim2.fromScale(0.5, 0.55)}); tw:Play()
            TS:Create(TBtn, CFG.TWEEN.BOUNCE, {ImageColor3 = CFG.CLR.SUBTEXT, Rotation = 0, BackgroundColor3 = CFG.CLR.PRIMARY}):Play()
            tw.Completed:Once(function() if not active then UI.Visible = false end end)
        end
    end)
    RunS.RenderStepped:Connect(function(dt) if active then local m, v = UIS:GetMouseLocation(), workspace.CurrentCamera.ViewportSize; UI.Position = UI.Position:Lerp(UDim2.new(0.5, (m.X - v.X/2)/500, 0.5, (m.Y - v.Y/2)/500), dt * 8) end end)
    Log("Boot sequence complete.")
end

Remote:On("AdminCheckResponse", function(isAdmin) if isAdmin then if Assets.IsReady() then Boot() else Assets.OnReady:Once(Boot) end end end)
Remote:FireServer("RequestAdminCheck")
