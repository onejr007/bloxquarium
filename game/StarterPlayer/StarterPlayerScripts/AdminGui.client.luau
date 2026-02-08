--[[
    AdminGui.client.luau (v31.0 - Hyperion Zenith Edition)
    - Strictly Added Admin Management into the Settings Tab.
    - Preserved Header GUI, Edit Function, and all v30.0 structures.
    - Implemented Add/Remove admin logic within the existing Container system.
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
    if t then
        for k,v in pairs(t) do i[k] = v end 
    end
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
    local activeSubTabName -- Persist sub-tab for Shop
    local navButtons = {}

    local SCHEMAS = {
        Fish = {name="New Fish", price=100, rarity="common", desc="Description", exp=10, buyAble=true, typeSwim="normal", mInfoName="", mInfoScale=1, mInfoRotate=0, mDropName="", mDropScale=1, mDropRotate=0},
        Egg = {name="New Egg", price=500, rarity="common", mInfoName="", mInfoScale=1, mInfoRotate=0},
        Food = {name="New Food", price=10, rarity="common", desc="Description", addExp=5, addHungerCD=20, mDropName="", mDropScale=1, mDropRotate=0},
        Mutation = {name="New Mutation", coinMultipler=1.2}
    }

    local function SwitchTab(tabName, subTabName)
        if activeTabName == tabName and not subTabName then return end
        activeTabName = tabName
        if subTabName then activeSubTabName = subTabName end
        
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

            elseif tabName == "Shop" then
                local ShopSubContent = New("Frame", Container, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5})
                local SubNav = New("Frame", ShopSubContent, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 6})
                New("UIListLayout", SubNav, {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)})
                
                local ContentArea = New("Frame", ShopSubContent, {Size = UDim2.new(1, 0, 1, -35), Position = UDim2.fromOffset(0, 35), BackgroundTransparency = 1, ZIndex = 5})
                local activeSub = activeSubTabName or "Cycle"

                local function renderSub(subName, data)
                    activeSubTabName = subName
                    for _, v in pairs(ContentArea:GetChildren()) do v:Destroy() end
                    local Scroll = New("ScrollingFrame", ContentArea, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 5}); New("UIListLayout", Scroll, {Padding = UDim.new(0, 10)})
                    New("UIPadding", Scroll, {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 20)})

                    if subName == "Cycle" then
                        -- Cooldown
                        local regenBtn = New("TextButton", Scroll, {Size = UDim2.new(0, 200, 0, 35), Text = "REGENERATE SHOP CYCLE", BackgroundColor3 = CFG.CLR.ERROR, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.BOLD, TextSize = 10}); ApplyCorner(regenBtn, 6)
                        regenBtn.MouseButton1Click:Connect(function() regenBtn.Text = "..."; Remote:InvokeServer("ResetShopCooldown"):andThen(function() SwitchTab("Shop", "Cycle") end) end)

                        -- List Items
                        if data.shop and data.shop.item then
                            for id, stock in pairs(data.shop.item) do
                                local r = New("Frame", Scroll, {Size = UDim2.new(1, -10, 0, 45), BackgroundColor3 = CFG.CLR.SECONDARY}); ApplyCorner(r, 6)
                                New("TextLabel", r, {Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.fromOffset(10, 0), Text = id, Font = CFG.FONT.MAIN, TextColor3 = CFG.CLR.TEXT, BackgroundTransparency = 1, TextXAlignment = 0, TextSize = 10})
                                local inp = New("TextBox", r, {Size = UDim2.new(0, 50, 0, 28), Position = UDim2.new(0.4, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = tostring(stock), BackgroundColor3 = CFG.CLR.TERTIARY, TextColor3 = CFG.CLR.ACCENT, Font = CFG.FONT.MONO, TextSize = 10}); ApplyCorner(inp, 4)
                                local s = New("TextButton", r, {Size = UDim2.new(0, 50, 0, 28), Position = UDim2.new(1, -115, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = "SAVE", BackgroundColor3 = CFG.CLR.SUCCESS, TextColor3 = CFG.CLR.PRIMARY, Font = CFG.FONT.BOLD, TextSize = 9}); ApplyCorner(s, 4)
                                s.MouseButton1Click:Connect(function() s.Text = "..."; Remote:InvokeServer("UpdateShopStock", id, tonumber(inp.Text) or 0):andThen(function() s.Text = "SAVE" end) end)
                                local db = New("TextButton", r, {Size = UDim2.new(0, 50, 0, 28), Position = UDim2.new(1, -60, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = "DEL", BackgroundColor3 = CFG.CLR.ERROR, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.BOLD, TextSize = 9}); ApplyCorner(db, 4)
                                db.MouseButton1Click:Connect(function() db.Text = "..."; Remote:InvokeServer("RemoveItemFromShop", id):andThen(function() SwitchTab("Shop", "Cycle") end) end)
                            end
                        end

                        -- Add Item Dropdown
                        local addRow = New("Frame", Scroll, {Size = UDim2.new(1, -10, 0, 40), BackgroundTransparency = 1, ZIndex = 10})
                        local dropBtn = New("TextButton", addRow, {Size = UDim2.new(0, 150, 1, 0), Text = "SELECT ITEM...", BackgroundColor3 = CFG.CLR.TERTIARY, TextColor3 = CFG.CLR.SUBTEXT, Font = CFG.FONT.MAIN, TextSize = 10, ZIndex = 11}); ApplyCorner(dropBtn, 6)
                        local addStock = New("TextBox", addRow, {Size = UDim2.new(0, 50, 1, 0), Position = UDim2.fromOffset(155, 0), PlaceholderText = "STOCK", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.MAIN, TextSize = 10, ZIndex = 11}); ApplyCorner(addStock, 6)
                        local addB = New("TextButton", addRow, {Size = UDim2.new(0, 60, 1, 0), Position = UDim2.fromOffset(210, 0), Text = "ADD", BackgroundColor3 = CFG.CLR.ACCENT, TextColor3 = CFG.CLR.PRIMARY, Font = CFG.FONT.BOLD, TextSize = 10, ZIndex = 11}); ApplyCorner(addB, 6)
                        
                        -- Dropdown List parented to ShopSubContent to avoid clipping
                        local dropList = New("ScrollingFrame", ShopSubContent, {Size = UDim2.new(0, 150, 0, 120), Position = UDim2.new(0, 30, 0, 140), BackgroundColor3 = CFG.CLR.SECONDARY, Visible = false, ZIndex = 20, AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2}); ApplyCorner(dropList, 4); ApplyStroke(dropList)
                        New("UIListLayout", dropList)
                        local selId = ""
                        for id, _ in pairs(data.chance or {}) do
                            local b = New("TextButton", dropList, {Size = UDim2.new(1, 0, 0, 28), Text = id, TextColor3 = CFG.CLR.TEXT, BackgroundTransparency = 1, Font = CFG.FONT.MAIN, TextSize = 10, ZIndex = 21}); b.MouseButton1Click:Connect(function() selId = id; dropBtn.Text = id; dropList.Visible = false end)
                        end
                        dropBtn.MouseButton1Click:Connect(function() dropList.Visible = not dropList.Visible end)
                        addB.MouseButton1Click:Connect(function() if selId ~= "" then Remote:InvokeServer("AddItemToShop", selId, tonumber(addStock.Text) or 1):andThen(function() SwitchTab("Shop", "Cycle") end) end end)

                    elseif subName == "Chance" then
                        for id, cfg in pairs(data.chance or {}) do
                            local r = New("Frame", Scroll, {Size = UDim2.new(1, -10, 0, 50), BackgroundColor3 = CFG.CLR.SECONDARY}); ApplyCorner(r, 6)
                            New("TextLabel", r, {Size = UDim2.new(0.25, 0, 1, 0), Position = UDim2.fromOffset(10, 0), Text = id, Font = CFG.FONT.BOLD, TextColor3 = CFG.CLR.TEXT, BackgroundTransparency = 1, TextXAlignment = 0, TextSize = 9})
                            local function miniInp(x, val, l)
                                New("TextLabel", r, {Size = UDim2.new(0, 35, 0, 12), Position = UDim2.fromOffset(x, 5), Text = l, Font = CFG.FONT.MONO, TextSize = 7, TextColor3 = CFG.CLR.SUBTEXT, BackgroundTransparency = 1})
                                local i = New("TextBox", r, {Size = UDim2.new(0, 35, 0, 22), Position = UDim2.fromOffset(x, 20), Text = tostring(val), BackgroundColor3 = CFG.CLR.TERTIARY, TextColor3 = CFG.CLR.ACCENT, Font = CFG.FONT.MONO, TextSize = 9}); ApplyCorner(i, 4)
                                return i
                            end
                            local iC = miniInp(90, cfg.chance, "CHANCE")
                            local iMi = miniInp(130, cfg.stockMin, "MIN")
                            local iMa = miniInp(170, cfg.stockMax, "MAX")
                            local s = New("TextButton", r, {Size = UDim2.new(0, 45, 0, 28), Position = UDim2.new(1, -100, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = "SAVE", BackgroundColor3 = CFG.CLR.ACCENT, TextColor3 = CFG.CLR.PRIMARY, Font = CFG.FONT.BOLD, TextSize = 8}); ApplyCorner(s, 6)
                            s.MouseButton1Click:Connect(function() s.Text = "..."; Remote:InvokeServer("UpdateChanceData", id, {chance = tonumber(iC.Text) or 0, stockMin = tonumber(iMi.Text) or 0, stockMax = tonumber(iMa.Text) or 0}):andThen(function() s.Text = "SAVE" end) end)
                            local db = New("TextButton", r, {Size = UDim2.new(0, 45, 0, 28), Position = UDim2.new(1, -50, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = "DEL", BackgroundColor3 = CFG.CLR.ERROR, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.BOLD, TextSize = 8}); ApplyCorner(db, 6)
                            db.MouseButton1Click:Connect(function() db.Text = "..."; Remote:InvokeServer("RemoveItemFromChance", id):andThen(function() SwitchTab("Shop", "Chance") end) end)
                        end
                        -- Add Item Row
                        local addR = New("Frame", Scroll, {Size = UDim2.new(1, -10, 0, 40), BackgroundTransparency = 1})
                        local ni = New("TextBox", addR, {Size = UDim2.new(0, 100, 1, 0), PlaceholderText = "NEW ID", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.MAIN, TextSize = 10}); ApplyCorner(ni, 6)
                        local nc = New("TextBox", addR, {Size = UDim2.new(0, 35, 1, 0), Position = UDim2.fromOffset(105, 0), PlaceholderText = "%", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.MAIN, TextSize = 10}); ApplyCorner(nc, 6)
                        local nmi = New("TextBox", addR, {Size = UDim2.new(0, 35, 1, 0), Position = UDim2.fromOffset(145, 0), PlaceholderText = "MIN", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.MAIN, TextSize = 10}); ApplyCorner(nmi, 6)
                        local nma = New("TextBox", addR, {Size = UDim2.new(0, 35, 1, 0), Position = UDim2.fromOffset(185, 0), PlaceholderText = "MAX", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.MAIN, TextSize = 10}); ApplyCorner(nma, 6)
                        local nb = New("TextButton", addR, {Size = UDim2.new(0, 50, 1, 0), Position = UDim2.fromOffset(225, 0), Text = "ADD", BackgroundColor3 = CFG.CLR.SUCCESS, TextColor3 = CFG.CLR.PRIMARY, Font = CFG.FONT.BOLD, TextSize = 9}); ApplyCorner(nb, 6)
                        nb.MouseButton1Click:Connect(function() if ni.Text ~= "" then Remote:InvokeServer("AddItemToChance", ni.Text, {chance = tonumber(nc.Text) or 0, stockMin = tonumber(nmi.Text) or 0, stockMax = tonumber(nma.Text) or 0}):andThen(function() SwitchTab("Shop", "Chance") end) end end)

                    elseif subName == "Fish" or subName == "Egg" or subName == "Food" or subName == "Mutation" then
                        local catData = data.items and data.items[subName] or {}
                        for id, item in pairs(catData) do
                            local r = New("Frame", Scroll, {Size = UDim2.new(1, -10, 0, 40), BackgroundColor3 = CFG.CLR.SECONDARY}); ApplyCorner(r, 6)
                            New("TextLabel", r, {Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromOffset(10, 0), Text = item.name or id, Font = CFG.FONT.MAIN, TextColor3 = CFG.CLR.TEXT, BackgroundTransparency = 1, TextXAlignment = 0, TextSize = 11})
                            local eb = New("TextButton", r, {Size = UDim2.new(0, 50, 0, 28), Position = UDim2.new(1, -115, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = "EDIT", BackgroundColor3 = CFG.CLR.TERTIARY, TextColor3 = CFG.CLR.ACCENT, Font = CFG.FONT.BOLD, TextSize = 9}); ApplyCorner(eb, 4)
                            local db = New("TextButton", r, {Size = UDim2.new(0, 50, 0, 28), Position = UDim2.new(1, -60, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = "DEL", BackgroundColor3 = CFG.CLR.ERROR, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.BOLD, TextSize = 9}); ApplyCorner(db, 4)
                            
                            db.MouseButton1Click:Connect(function() db.Text = "..."; Remote:InvokeServer("DeleteItemData", subName, id):andThen(function() SwitchTab("Shop", subName) end) end)
                            eb.MouseButton1Click:Connect(function() 
                                -- Simple editor for item data
                                Scroll.Visible = false
                                local Edit = New("Frame", ContentArea, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
                                local eSc = New("ScrollingFrame", Edit, {Size = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y}); New("UIListLayout", eSc, {Padding = UDim.new(0, 5)})
                                local back = New("TextButton", Edit, {Size = UDim2.new(0, 80, 0, 30), Position = UDim2.new(0, 0, 1, -40), Text = "BACK", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT}); ApplyCorner(back, 4)
                                local save = New("TextButton", Edit, {Size = UDim2.new(0, 80, 0, 30), Position = UDim2.new(1, -80, 1, -40), Text = "SAVE", BackgroundColor3 = CFG.CLR.SUCCESS, TextColor3 = CFG.CLR.PRIMARY}); ApplyCorner(save, 4)
                                
                                local fields = {}
                                for k, v in pairs(item) do
                                    if type(v) ~= "table" then
                                        local fr = New("Frame", eSc, {Size = UDim2.new(1, -10, 0, 40), BackgroundColor3 = CFG.CLR.TERTIARY}); ApplyCorner(fr, 4)
                                        New("TextLabel", fr, {Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromOffset(10, 0), Text = k, Font = CFG.FONT.MONO, TextSize = 10, TextColor3 = CFG.CLR.SUBTEXT, BackgroundTransparency = 1, TextXAlignment = 0})
                                        local ti = New("TextBox", fr, {Size = UDim2.new(0.5, 0, 0.7, 0), Position = UDim2.new(0.45, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = tostring(v), TextColor3 = CFG.CLR.TEXT, BackgroundColor3 = CFG.CLR.SECONDARY}); ApplyCorner(ti, 4)
                                        fields[k] = {ti = ti, ot = type(v)}
                                    end
                                end
                                back.MouseButton1Click:Connect(function() Edit:Destroy(); Scroll.Visible = true end)
                                save.MouseButton1Click:Connect(function()
                                    local nd = {}
                                    for k, f in pairs(fields) do 
                                        local t = f.ti.Text
                                        if f.ot == "number" then nd[k] = tonumber(t) or 0 elseif f.ot == "boolean" then nd[k] = (t:lower() == "true") else nd[k] = t end
                                    end
                                    Remote:InvokeServer("UpdateItemData", subName, id, nd):andThen(function() SwitchTab("Shop", subName) end)
                                end)
                            end)
                        end
                        -- Add New Item Btn
                        local addB = New("TextButton", Scroll, {Size = UDim2.new(1, -10, 0, 35), Text = "+ ADD NEW " .. subName:upper(), BackgroundColor3 = CFG.CLR.TERTIARY, TextColor3 = CFG.CLR.ACCENT}); ApplyCorner(addB, 6)
                        addB.MouseButton1Click:Connect(function() 
                            local nid = "id_" .. subName:lower() .. "_" .. os.time()
                            local schema = SCHEMAS[subName] or {name = "New " .. subName}
                            Remote:InvokeServer("AddItemData", subName, nid, schema):andThen(function() SwitchTab("Shop", subName) end)
                        end)
                    end
                end

                Remote:InvokeServer("GetShopAdminData"):andThen(function(data)
                    if not data or activeTabName ~= "Shop" then return end
                    for _, sub in ipairs({"Cycle", "Chance", "Fish", "Egg", "Food", "Mutation"}) do
                        local b = New("TextButton", SubNav, {Size = UDim2.new(0, 60, 1, 0), Text = sub:upper(), BackgroundColor3 = activeSub == sub and CFG.CLR.ACCENT or CFG.CLR.SECONDARY, TextColor3 = activeSub == sub and CFG.CLR.PRIMARY or CFG.CLR.SUBTEXT, Font = CFG.FONT.BOLD, TextSize = 8}); ApplyCorner(b, 4)
                        b.MouseButton1Click:Connect(function()
                            activeSub = sub
                            for _, child in ipairs(SubNav:GetChildren()) do if child:IsA("TextButton") then child.BackgroundColor3 = CFG.CLR.SECONDARY; child.TextColor3 = CFG.CLR.SUBTEXT end end
                            b.BackgroundColor3 = CFG.CLR.ACCENT; b.TextColor3 = CFG.CLR.PRIMARY
                            renderSub(sub, data)
                        end)
                    end
                    renderSub(activeSub, data)
                end)

            elseif tabName == "Admin" then --// ADMIN MANAGEMENT (ADDED)
                local admins, page, limit = {}, 1, 8
                
                local Toolbar = New("Frame", Container, {Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1})
                local AdminInp = New("TextBox", Toolbar, {Size = UDim2.new(0, 250, 1, 0), PlaceholderText = "NAME OR ID TO ADD...", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT, Font = CFG.FONT.MAIN, TextSize = 13}); ApplyCorner(AdminInp, 6); ApplyStroke(AdminInp); New("UIPadding", AdminInp, {PaddingLeft = UDim.new(0, 12)})
                
                local AddBtn = New("TextButton", Toolbar, {Size = UDim2.new(0, 100, 1, 0), Position = UDim2.fromOffset(260, 0), Text = "ADD ADMIN", BackgroundColor3 = CFG.CLR.SUCCESS, TextColor3 = CFG.CLR.PRIMARY, Font = CFG.FONT.BOLD, TextSize = 10}); ApplyCorner(AddBtn, 6)
                
                local Pag = New("Frame", Toolbar, {Size = UDim2.new(0, 150, 1, 0), Position = UDim2.new(1, -150, 0, 0), BackgroundTransparency = 1})
                local pB = New("TextButton", Pag, {Size = UDim2.new(0, 30, 1, 0), Text = "<", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT}); ApplyCorner(pB, 6)
                local nB = New("TextButton", Pag, {Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -30, 0, 0), Text = ">", BackgroundColor3 = CFG.CLR.SECONDARY, TextColor3 = CFG.CLR.TEXT}); ApplyCorner(nB, 6)
                local pL = New("TextLabel", Pag, {Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(35, 0), Text = "1/1", Font = CFG.FONT.BOLD, TextSize = 10, TextColor3 = CFG.CLR.SUBTEXT, BackgroundTransparency = 1})

                local Scroll = New("ScrollingFrame", Container, {Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 1, -100), BackgroundTransparency = 1, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y}); New("UIListLayout", Scroll, {Padding = UDim.new(0, 8)})

                local function render()
                    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
                    local maxP = math.max(1, math.ceil(#admins/limit))
                    page = math.clamp(page, 1, maxP); pL.Text = page.."/"..maxP
                    for i = (page-1)*limit+1, math.min(page*limit, #admins) do
                        local d = admins[i]
                        local r = New("Frame", Scroll, {Size = UDim2.new(1,0,0,50), BackgroundColor3 = CFG.CLR.SECONDARY}); ApplyCorner(r, 6); ApplyStroke(r, nil, 1, 0.95)
                        New("TextLabel", r, {Size=UDim2.new(1,-100,1,0), Position=UDim2.fromOffset(15,0), Text=string.format("%s (%s)", d.name:upper(), d.userId), Font=CFG.FONT.BOLD, TextColor3=CFG.CLR.TEXT, BackgroundTransparency=1, TextXAlignment=0, TextSize=11})
                        local rb = New("TextButton", r, {Size=UDim2.new(0,80,0,28), Position=UDim2.new(1,-95,.5,0), AnchorPoint=Vector2.new(0,.5), Text="REMOVE", BackgroundColor3=CFG.CLR.ERROR, TextColor3=CFG.CLR.TEXT, Font=CFG.FONT.BOLD, TextSize=10}); ApplyCorner(rb, 4)
                        rb.MouseButton1Click:Connect(function() rb.Text = "..."; Remote:InvokeServer("RemoveAdmin", d.userId):andThen(function() SwitchTab("Admin") end) end)
                    end
                end

                local function fetch() Remote:InvokeServer("RequestAdminList"):andThen(function(l) admins = l; render() end) end

                AddBtn.MouseButton1Click:Connect(function()
                    if AdminInp.Text == "" then return end
                    AddBtn.Text = "WAIT..."; Remote:InvokeServer("AddAdmin", AdminInp.Text):andThen(function() AddBtn.Text = "ADD ADMIN"; AdminInp.Text = ""; fetch() end)
                end)

                pB.MouseButton1Click:Connect(function() page=math.max(1,page-1); render() end)
                nB.MouseButton1Click:Connect(function() page=page+1; render() end)
                fetch()
            else
                New("TextLabel", Container, {Size = UDim2.fromScale(1, 1), Text = "MODULE_OFFLINE", Font = CFG.FONT.MONO, TextSize = 20, TextColor3 = CFG.CLR.SUBTEXT, BackgroundTransparency = 1})
            end
            TS:Create(Container, CFG.TWEEN.EXPO, {GroupTransparency = 0, Position = UDim2.fromOffset(30, 80)}):Play()
        end)
    end

    for _, name in ipairs({"Overview", "Database", "Shop", "Admin"}) do
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