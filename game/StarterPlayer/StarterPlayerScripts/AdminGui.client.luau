--[[
    AdminGui.client.luau (v28.0 - THE TEXTBOX HACK)

    - All previous attempts to fix the rendering bug have failed.
    - The user has consistently reported that the list ONLY appears after clicking the SearchBox.
    - This version implements a "hack" that programmatically focuses and then releases the SearchBox
      after data is fetched. This directly mimics the only user action known to work, forcing the
      elusive UI redraw that all other methods have failed to trigger.
    - This applies to both the initial load and the Refresh button.
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
        ACCENT    = Color3.fromRGB(0, 255, 200),
        PRIMARY   = Color3.fromRGB(4, 5, 7),
        SECONDARY = Color3.fromRGB(15, 17, 22),
        BORDER    = Color3.fromRGB(255, 255, 255),
        TEXT      = Color3.fromRGB(255, 255, 255),
        SUBTEXT   = Color3.fromRGB(140, 145, 160),
        ERROR     = Color3.fromRGB(255, 80, 80),
    },
    TWEEN = {
        SMOOTH = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        BOUNCE = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        EXPO   = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    }
}

--// UI FACTORY & UTILS
local function New(c, p, t) local i=Instance.new(c); for k,v in pairs(t) do i[k]=v end; i.Parent=p; return i end
local function Style(i, r, t) New("UICorner",i,{CornerRadius=UDim.new(0,r)}); return New("UIStroke",i,{Thickness=1.2,Color=CFG.CLR.BORDER,Transparency=t or 0.9,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function Log(m) print(string.format(" <[HYPERION_ZENITH]> : %s", m:upper())) end

--// EDIT MODAL
local function CreateEditModal(playerData, onSave)
    local modalBg = New("CanvasGroup", game.Players.LocalPlayer.PlayerGui.HyperionZenith, {Name="EditModalBg", Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(0,0,0), GroupTransparency=0.5, ZIndex=100})
    local modalFrame = New("Frame", modalBg, {Size=UDim2.new(0.4,0,0.6,0), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=CFG.CLR.SECONDARY}); Style(modalFrame,12,0.8)
    New("UIListLayout", modalFrame, {Padding=UDim.new(0,15), HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder})
    New("UIPadding", modalFrame, {PaddingTop=UDim.new(0,20), PaddingLeft=UDim.new(0,20), PaddingRight=UDim.new(0,20), PaddingBottom=UDim.new(0,10)})
    New("TextLabel", modalFrame, {LayoutOrder=1, Size=UDim2.new(1,0,0,30), Text="EDITING: "..tostring(playerData.name), Font=Enum.Font.RobotoMono, TextSize=18, TextColor3=CFG.CLR.TEXT, BackgroundTransparency=1})

    local inputs = {}
    local scroll = New("ScrollingFrame", modalFrame, {LayoutOrder=2, Size=UDim2.new(1,0,1,-80), BackgroundTransparency=1, ScrollBarThickness=5})
    New("UIListLayout", scroll, {Padding=UDim.new(0,5)})

    for key, value in pairs(playerData) do
        if key ~= "userId" and key ~= "name" and type(value) ~= "table" then -- Exclude non-editable fields
            local row = New("Frame", scroll, {Size=UDim2.new(1,0,0,30), BackgroundTransparency=1}); New("UIListLayout",row,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,10),VerticalAlignment=Enum.VerticalAlignment.Center})
            New("TextLabel", row, {Size=UDim2.new(0.3,0,1,0), Text=key, Font=Enum.Font.RobotoMono, TextSize=14, TextColor3=CFG.CLR.SUBTEXT, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left})
            local input = New("TextBox", row, {Size=UDim2.new(0.7,-10,1,0), Text=tostring(value), Font=Enum.Font.RobotoMono, TextSize=14, BackgroundColor3=CFG.CLR.PRIMARY, TextColor3=CFG.CLR.TEXT, ClearTextOnFocus=false}); Style(input,6,0.9)
            inputs[key] = {input=input, originalType=type(value)}
        end
    end

    local btnRow = New("Frame", modalFrame, {LayoutOrder=3, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1}); New("UIListLayout",btnRow,{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,10)})
    local saveBtn = New("TextButton", btnRow, {Size=UDim2.new(0,100,1,0), Text="Save", BackgroundColor3=CFG.CLR.ACCENT, TextColor3=CFG.CLR.PRIMARY, Font=Enum.Font.SourceSansBold, TextSize=16}); Style(saveBtn,6,0.9)
    local cancelBtn = New("TextButton", btnRow, {Size=UDim2.new(0,100,1,0), Text="Cancel", BackgroundColor3=CFG.CLR.PRIMARY, TextColor3=CFG.CLR.TEXT, Font=Enum.Font.SourceSansBold, TextSize=16}); Style(cancelBtn,6,0.9)

    cancelBtn.MouseButton1Click:Connect(function() modalBg:Destroy() end)
    saveBtn.MouseButton1Click:Connect(function()
        local newData = {}
        for key, val in pairs(inputs) do
            local text = val.input.Text
            if val.originalType == "number" then newData[key] = tonumber(text) or 0
            elseif val.originalType == "boolean" then newData[key] = (text:lower() == "true")
            else newData[key] = text end
        end
        onSave(newData)
        modalBg:Destroy()
    end)
end


--// MAIN UI & TAB LOGIC
local function CreateHyperionInterface(parent)
    local Main = New("CanvasGroup", parent, {Name="HyperionMain", Size=UDim2.fromScale(0.8,0.75), Position=UDim2.fromScale(0.5,0.52), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=CFG.CLR.PRIMARY, GroupTransparency=1, Visible=false}); Style(Main,14,0.75)
    New("UIPadding", Main, {PaddingTop=UDim.new(0,25), PaddingBottom=UDim.new(0,25), PaddingLeft=UDim.new(0,25), PaddingRight=UDim.new(0,25)})
    New("UIListLayout", Main, {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,20)})

    local NavPane = New("Frame", Main, {Name="NavPane", Size=UDim2.new(0.25,0,1,0), BackgroundColor3=CFG.CLR.SECONDARY, BackgroundTransparency=0.2}); Style(NavPane,10,0.85)
    New("TextLabel", NavPane, {Size=UDim2.new(1,0,0,60), BackgroundTransparency=1, RichText=true, Font=Enum.Font.RobotoMono, TextSize=16, TextColor3=CFG.CLR.TEXT, Text="<b>HYPERION</b>_ZENITH\n<font size='9' color='#00FFC8'>SECURED INTERFACE</font>"})
    local NavScroll = New("ScrollingFrame", NavPane, {Size=UDim2.new(1,-20,1,-80), Position=UDim2.fromOffset(10,70), BackgroundTransparency=1, ScrollBarThickness=0, AutomaticCanvasSize=Enum.AutomaticSize.Y}); New("UIListLayout",NavScroll,{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Center})

    local ContentPane = New("Frame", Main, {Name="ContentPane", Size=UDim2.new(0.72,0,1,0), BackgroundColor3=CFG.CLR.SECONDARY, BackgroundTransparency=0.4}); Style(ContentPane,10,0.9)
    local PageHeader = New("TextLabel", ContentPane, {Size=UDim2.new(1,-40,0,50), Position=UDim2.fromOffset(20,15), BackgroundTransparency=1, Font=Enum.Font.RobotoMono, TextSize=22, TextColor3=CFG.CLR.TEXT, TextXAlignment=Enum.TextXAlignment.Left})
    local Container = New("CanvasGroup", ContentPane, {Name="Container", Size=UDim2.new(1,-40,1,-80), Position=UDim2.fromOffset(20,75), BackgroundTransparency=1})

    local activeTabName -- Add this to track the current tab

    local function SwitchTab(tabName)
        activeTabName = tabName -- Set the new active tab
        PageHeader.Text = tabName:upper() .. "_PROTOCOL"
        local fadeOutTween = TS:Create(Container, CFG.TWEEN.SMOOTH, {GroupTransparency = 1, Position = UDim2.fromOffset(20, 95)})
        fadeOutTween:Play()

        fadeOutTween.Completed:Once(function()
            if activeTabName ~= tabName then return end -- Abort if tab has changed

            for _, v in pairs(Container:GetChildren()) do v:Destroy() end

            if tabName == "Database" then
                local allPlayerData = {}
                local currentPage = 1
                local itemsPerPage = 10
                local DataDisplay, SearchBox, PageLabel, StatusLabel

                local function updateLocalData(userId, newData)
                    for i, pData in ipairs(allPlayerData) do
                        if tostring(pData.userId) == tostring(userId) then
                            for k, v in pairs(newData) do allPlayerData[i][k] = v end
                            break
                        end
                    end
                end

                local function renderPage(forceSort)
                    if not DataDisplay or activeTabName ~= "Database" then return end -- Extra guard
                    for _, child in ipairs(DataDisplay:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

                    local searchText = SearchBox.Text:lower()
                    local filteredPlayerData = {}
                    if searchText == "" then
                        filteredPlayerData = allPlayerData
                    else
                        for _, data in pairs(allPlayerData) do
                            if (data.name and data.name:lower():find(searchText)) or (tostring(data.userId):lower():find(searchText)) then
                                table.insert(filteredPlayerData, data)
                            end
                        end
                    end
                    
                    if forceSort then table.sort(filteredPlayerData, function(a,b) return (a.lastSeen or 0) > (b.lastSeen or 0) end) end

                    local totalPages = math.max(1, math.ceil(#filteredPlayerData / itemsPerPage))
                    currentPage = math.clamp(currentPage, 1, totalPages)
                    PageLabel.Text = string.format("Page %d/%d", currentPage, totalPages)
                    StatusLabel.Text = string.format("Results: %d", #filteredPlayerData)

                    local startIndex = (currentPage - 1) * itemsPerPage + 1
                    local endIndex = math.min(startIndex + itemsPerPage - 1, #filteredPlayerData)

                    for i = startIndex, endIndex do
                        local pData = filteredPlayerData[i]
                        local eFrame = New("Frame", DataDisplay, {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1}); New("UIListLayout",eFrame,{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10)})
                        New("TextLabel", eFrame, {Size=UDim2.new(1,-120,1,0), BackgroundTransparency=1, Font=Enum.Font.RobotoMono, Text=string.format("%s (%s)", pData.name, pData.userId), TextColor3=CFG.CLR.TEXT, TextXAlignment=Enum.TextXAlignment.Left, TextSize=12})
                        local editBtn = New("TextButton", eFrame, {Size=UDim2.new(0,80,0,28), Text="Edit", BackgroundColor3=CFG.CLR.PRIMARY, TextColor3=CFG.CLR.TEXT, Font=Enum.Font.SourceSansBold, TextSize=14}); Style(editBtn,6,0.8)
                        editBtn.MouseButton1Click:Connect(function()
                            CreateEditModal(pData, function(newData)
                                Remote:FireServer("UpdatePlayerData", pData.userId, newData)
                                updateLocalData(pData.userId, newData)
                                renderPage(false)
                            end)
                        end)
                    end
                end

                local DBFrame = New("Frame", Container, {Name="DBFrame", Size=UDim2.fromScale(1,1), BackgroundTransparency=1}); New("UIListLayout",DBFrame,{Padding=UDim.new(0,10)})
                local HeaderFrame = New("Frame", DBFrame, {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1}); New("UIListLayout",HeaderFrame,{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10)})
                SearchBox = New("TextBox", HeaderFrame, {Size=UDim2.new(1,-420,1,0), PlaceholderText="Search...", BackgroundColor3=CFG.CLR.PRIMARY, TextColor3=CFG.CLR.TEXT, Font=Enum.Font.RobotoMono, TextSize=14}); Style(SearchBox,8,0.9)
                local PrevBtn = New("TextButton", HeaderFrame, {Size=UDim2.new(0,30,1,0), Text="<"}); Style(PrevBtn,6)
                PageLabel = New("TextLabel", HeaderFrame, {Size=UDim2.new(0,100,1,0), Text="Page 1/1", Font=Enum.Font.RobotoMono, TextSize=14, TextColor3=CFG.CLR.SUBTEXT, BackgroundTransparency=1})
                local NextBtn = New("TextButton", HeaderFrame, {Size=UDim2.new(0,30,1,0), Text=">"}); Style(NextBtn,6)
                local RefreshBtn = New("TextButton", HeaderFrame, {Size=UDim2.new(0,80,1,0), Text="Refresh"}); Style(RefreshBtn,6)
                StatusLabel = New("TextLabel", HeaderFrame, {Size=UDim2.new(0,150,1,0), Text="", Font=Enum.Font.RobotoMono, TextSize=12, TextColor3=CFG.CLR.SUBTEXT, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Right})
                DataDisplay = New("ScrollingFrame", DBFrame, {Name="DataDisplay", Size=UDim2.new(1,0,1,-50), BackgroundColor3=CFG.CLR.PRIMARY, BackgroundTransparency=0.5}); Style(DataDisplay,8,0.95); New("UIListLayout",DataDisplay,{Padding=UDim.new(0,2)})

                local function fetchData()
                    StatusLabel.Text = "Loading..."
                    Remote:InvokeServer("RequestAllPlayerData"):andThen(function(data)
                        if not data or activeTabName ~= tabName then Log("Data fetch aborted or failed."); return end
                        Log("All player data received.")
                        local dataArray = {}
                        for uid, pData in pairs(data) do
                            pData.userId = uid
                            local player = Players:GetPlayerByUserId(tonumber(uid))
                            if player then pData.name = player.Name
                            else pData.name = "[OFFLINE]" end
                            table.insert(dataArray, pData)
                        end
                        allPlayerData = dataArray
                        
                        if activeTabName ~= tabName then return end -- Final guard before render
                        renderPage(true)

                        -- FIXED: The "TextBox Hack". Programmatically focus the search box to force a redraw.
                        if SearchBox then
                            SearchBox:CaptureFocus()
                            task.wait()
                            SearchBox:ReleaseFocus()
                        end

                    end):catch(function(err) Log("Error fetching data: "..tostring(err)); StatusLabel.Text = "Error" end)
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function() renderPage(false) end)
                PrevBtn.MouseButton1Click:Connect(function() currentPage=math.max(1,currentPage-1); renderPage(false) end)
                NextBtn.MouseButton1Click:Connect(function() currentPage=currentPage+1; renderPage(false) end)
                RefreshBtn.MouseButton1Click:Connect(fetchData)
                
                fetchData() -- AUTO-FETCH ON TAB OPEN
            else
                local Grid=New("ScrollingFrame",Container,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=0,AutomaticCanvasSize=Enum.AutomaticSize.Y}); New("UIGridLayout",Grid,{CellPadding=UDim2.fromOffset(15,15),CellSize=UDim2.fromOffset(180,100)})
                for i=1,8 do Style(New("TextButton",Grid,{BackgroundColor3=CFG.CLR.PRIMARY,Text=""}),8,0.95) end
            end
            
            Container.Position = UDim2.fromOffset(20, 60)
            TS:Create(Container, CFG.TWEEN.EXPO, {GroupTransparency = 0, Position = UDim2.fromOffset(20, 75)}):Play()
        end)
    end

    for _, name in ipairs({"Overview", "Database", "Execution", "Networking", "Security", "Settings"}) do
        local btn = New("TextButton",NavScroll,{Size=UDim2.new(1,0,0,45),BackgroundColor3=CFG.CLR.PRIMARY,Text="",AutoButtonColor=false}); Style(btn,6,0.9)
        New("TextLabel",btn,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=name,Font=Enum.Font.SourceSansBold,TextColor3=CFG.CLR.SUBTEXT,TextSize=14})
        btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    end
    SwitchTab("Overview")
    return Main
end

--// SYSTEM BOOT
function Boot()
    if IsInitialized then return end; IsInitialized = true
    Log("Zenith OS Online. Booting UI...")
    local SG = New("ScreenGui",Player.PlayerGui,{Name="HyperionZenith",IgnoreGuiInset=true,ResetOnSpawn=false})
    local UI = CreateHyperionInterface(SG)
    local TRoot = New("Frame",SG,{Name="ToggleRoot",Size=UDim2.fromOffset(55,55),Position=UDim2.new(0,40,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundTransparency=1})
    local TIcon = New("ImageButton",TRoot,{Name="TIcon",Size=UDim2.fromScale(0.8,0.8),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image=Assets.get("Admin_ico"),ImageColor3=CFG.CLR.SUBTEXT})
    local active = false
    TIcon.MouseButton1Click:Connect(function()
        active = not active
        UI.Visible = true
        if active then
            TS:Create(UI,CFG.TWEEN.EXPO,{GroupTransparency=0,Position=UDim2.fromScale(0.5,0.5)}):Play()
            TS:Create(TIcon,CFG.TWEEN.BOUNCE,{ImageColor3=CFG.CLR.ACCENT,Rotation=180}):Play()
        else
            local tw=TS:Create(UI,CFG.TWEEN.SMOOTH,{GroupTransparency=1,Position=UDim2.fromScale(0.5,0.55)}); tw:Play()
            TS:Create(TIcon,CFG.TWEEN.BOUNCE,{ImageColor3=CFG.CLR.SUBTEXT,Rotation=0}):Play()
            tw.Completed:Once(function() if not active then UI.Visible=false end end)
        end
    end)
    RunS.RenderStepped:Connect(function(dt) if active then local m,v=UIS:GetMouseLocation(),workspace.CurrentCamera.ViewportSize; UI.Position=UI.Position:Lerp(UDim2.new(0.5,(m.X-v.X/2)/450,0.5,(m.Y-v.Y/2)/450),dt*6) end end)
    Log("Boot sequence complete. UI is active.")
end

--// AUTH
Remote:On("AdminCheckResponse", function(isAdmin) if isAdmin then if Assets.IsReady() then Boot() else Assets.OnReady:Once(Boot) end end end)
Log("Requesting Admin Status From Server...")
Remote:FireServer("RequestAdminCheck")
