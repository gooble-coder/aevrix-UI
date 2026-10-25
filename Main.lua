-- AEVRIX UI - standalone Luau interface library
-- Original UI implementation; no verification or remote code loading.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
assert(LocalPlayer, "AevrixUI must run on the client")
local RootGui = LocalPlayer:WaitForChild("PlayerGui")

local UI = {}
UI.__index = UI
UI.Themes = {"Golden Lime", "Emerald", "Midnight"}
local PALETTES = {
    ["Golden Lime"] = {bg = Color3.fromRGB(11,16,14), surface = Color3.fromRGB(23,30,23), card = Color3.fromRGB(33,41,29), text = Color3.fromRGB(243,247,225), muted = Color3.fromRGB(164,181,148), accent = Color3.fromRGB(255,222,49), lime = Color3.fromRGB(132,255,58)},
    Emerald = {bg = Color3.fromRGB(9,18,17), surface = Color3.fromRGB(17,34,31), card = Color3.fromRGB(23,46,37), text = Color3.fromRGB(238,251,243), muted = Color3.fromRGB(150,186,163), accent = Color3.fromRGB(70,237,137), lime = Color3.fromRGB(121,255,187)},
    Midnight = {bg = Color3.fromRGB(14,17,27), surface = Color3.fromRGB(25,29,44), card = Color3.fromRGB(34,39,58), text = Color3.fromRGB(240,241,250), muted = Color3.fromRGB(155,165,194), accent = Color3.fromRGB(174,144,255), lime = Color3.fromRGB(94,209,255)}
}

local function create(className, props, parent)
    local object = Instance.new(className)
    for k, v in pairs(props or {}) do object[k] = v end
    object.Parent = parent
    return object
end
local function corner(parent, px) create("UICorner", {CornerRadius = UDim.new(0, px)}, parent) end
local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {Color=color, Transparency=transparency or 0, Thickness=thickness or 1}, parent)
end
local function padding(parent, p)
    create("UIPadding", {PaddingTop=UDim.new(0,p), PaddingBottom=UDim.new(0,p), PaddingLeft=UDim.new(0,p), PaddingRight=UDim.new(0,p)}, parent)
end
local function gradient(parent, a, b)
    create("UIGradient", {Color=ColorSequence.new(a,b), Rotation=10}, parent)
end
-- Reusable gold/lime gradient + dotted texture for every panel.
local function skin(panel, colors, columns, rows, transparency)
    panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    local gradientObject = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colors[1]),
            ColorSequenceKeypoint.new(0.46, colors[2]),
            ColorSequenceKeypoint.new(1, colors[3]),
        }),
        Rotation = 0,
    }, panel)
    if columns and rows then
        for x = 0, columns - 1 do
            for y = 0, rows - 1 do
                local dot = create("Frame", {
                    Name = "GridDot",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale((x+0.5)/columns, (y+0.5)/rows),
                    Size = UDim2.fromOffset(2, 2),
                    BackgroundColor3 = Color3.fromRGB(237, 255, 136),
                    BackgroundTransparency = transparency or 0.77,
                    BorderSizePixel = 0,
                    Active = false,
                }, panel)
                create("UICorner", {CornerRadius=UDim.new(1,0)}, dot)
            end
        end
    end
    return gradientObject
end

local PANEL = {
    Color3.fromRGB(53, 44, 10),
    Color3.fromRGB(17, 28, 14),
    Color3.fromRGB(45, 51, 10),
}
local SUBPANEL = {
    Color3.fromRGB(33, 37, 13),
    Color3.fromRGB(12, 22, 14),
    Color3.fromRGB(36, 43, 14),
}
local CONTROL = {
    Color3.fromRGB(35, 35, 13),
    Color3.fromRGB(18, 25, 15),
    Color3.fromRGB(38, 47, 16),
}

local function label(parent, text, size, color, bold)
    return create("TextLabel", {BackgroundTransparency=1, Text=text or "", Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize=size or 13, TextColor3=color, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true}, parent)
end
local function safeCallback(fn, ...)
    if type(fn) == "function" then
        local ok, err = pcall(fn, ...)
        if not ok then warn("[AEVRIX UI] callback error:", err) end
    end
end
local function paintButton(button, palette)
    button.BackgroundColor3 = palette.accent
    button.TextColor3 = Color3.fromRGB(17,23,12)
end

function UI:CreateWindow(options)
    options = options or {}
    local palette = PALETTES[options.Theme] or PALETTES["Golden Lime"]
    local previous = RootGui:FindFirstChild("AevrixStandaloneUI")
    if previous then previous:Destroy() end
    local gui = create("ScreenGui", {Name="AevrixStandaloneUI", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, RootGui)
    local window = setmetatable({Gui=gui, Theme=options.Theme or "Golden Lime", Palette=palette, Tabs={}, Controls={}, MinimizeKey=options.MinimizeKey or Enum.KeyCode.RightControl, Visible=true, _connections={}, _saved={}, _folder=options.Folder or "AevrixUI", _storage=options.SaveConfig == true}, UI)
    local shade = create("Frame", {Name="Backdrop", Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=1, BorderSizePixel=0}, gui)
    local main = create("Frame", {Name="Main", AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(620,400), BackgroundColor3=palette.bg, BorderSizePixel=0, Active=true}, gui)
    corner(main,18)
    skin(main, PANEL, 45, 26, 0.7)
    stroke(main,palette.accent,0.06,1.8)
    window.Main, window.Shade = main,shade
    local topbar = create("Frame", {Name="Topbar", Size=UDim2.new(1,0,0,66), BackgroundColor3=palette.surface, BorderSizePixel=0},main)
    corner(topbar,18)
    skin(topbar, {Color3.fromRGB(78, 65, 12),Color3.fromRGB(19, 33, 15),Color3.fromRGB(65, 71, 16)}, 39, 5, 0.71)
    local cover = create("Frame", {Position=UDim2.new(0,0,1,-16), Size=UDim2.new(1,0,0,16), BackgroundColor3=palette.surface, BorderSizePixel=0},topbar)
    skin(cover, {Color3.fromRGB(78, 65, 12),Color3.fromRGB(19, 33, 15),Color3.fromRGB(65, 71, 16)})
    local line = create("Frame", {Position=UDim2.new(0,18,1,-2),Size=UDim2.new(1,-36,0,2), BackgroundColor3=palette.accent, BorderSizePixel=0},topbar)
    gradient(line,Color3.fromRGB(255, 223, 27),Color3.fromRGB(76, 255, 42))
    local title = label(topbar,options.Title or "AEVRIX",22,palette.text,true)
    title.Position=UDim2.fromOffset(21,8); title.Size=UDim2.fromOffset(430,29)
    gradient(title,Color3.fromRGB(255,240,113),Color3.fromRGB(118,255,48))
    local subtitle = label(topbar,options.SubTitle or "Premium Interface",11,palette.muted)
    subtitle.Position=UDim2.fromOffset(22,37); subtitle.Size=UDim2.fromOffset(420,19)
    local close = create("TextButton", {Text="×",Font=Enum.Font.GothamBold,TextSize=23,TextColor3=palette.text,BackgroundColor3=palette.card,Position=UDim2.new(1,-42,0,18),Size=UDim2.fromOffset(25,25)},topbar)
    corner(close,8); close.MouseButton1Click:Connect(function() window:Destroy() end)
    local sidebar = create("ScrollingFrame", {Name="Sidebar",Position=UDim2.fromOffset(12,77),Size=UDim2.new(0,154,1,-90),BackgroundColor3=palette.surface,BorderSizePixel=0,ScrollBarThickness=2,CanvasSize=UDim2.new()},main)
    corner(sidebar,12); skin(sidebar, SUBPANEL); stroke(sidebar,palette.accent,0.48,1); padding(sidebar,7)
    local sidebarLayout = create("UIListLayout", {Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},sidebar)
    sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sidebar.CanvasSize=UDim2.fromOffset(0,sidebarLayout.AbsoluteContentSize.Y+14) end)
    local content = create("Frame", {Name="Content",Position=UDim2.fromOffset(177,77),Size=UDim2.new(1,-190,1,-90),BackgroundColor3=palette.surface,BorderSizePixel=0,ClipsDescendants=true},main)
    corner(content,12)
    skin(content, SUBPANEL, 25, 19, 0.73)
    stroke(content,palette.lime,0.53,1)
    window.Sidebar,window.Content = sidebar,content
    local dragging, startInput, startPos = false,nil,nil
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true;startInput=input.Position;startPos=main.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    table.insert(window._connections,UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-startInput
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end))
    table.insert(window._connections,UserInputService.InputBegan:Connect(function(input,processed)
        if not processed and input.KeyCode==window.MinimizeKey then window:SetVisible(not window.Visible) end
    end))
    return window
end

function UI:SetVisible(value)
    self.Visible=value
    self.Main.Visible=value
    self.Shade.Visible=value
end
function UI:Toggle() self:SetVisible(not self.Visible) end
function UI:Destroy()
    for _, connection in ipairs(self._connections) do connection:Disconnect() end
    self._connections={}
    if self.Gui then self.Gui:Destroy() end
end
function UI:AddTab(options)
    options=type(options)=="string" and {Title=options} or (options or {})
    local p=self.Palette
    local button=create("TextButton",{Name="TabButton",Text=options.Title or "Tab",Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=p.muted,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=p.card,BackgroundTransparency=0.5,Size=UDim2.new(1,0,0,36)},self.Sidebar)
    corner(button,8); skin(button, CONTROL, 9, 2, 0.8); padding(button,11)
    local page=create("ScrollingFrame",{Name=options.Title or "Tab",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,Visible=false,CanvasSize=UDim2.new()},self.Content)
    padding(page,12)
    local layout=create("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},page)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+28) end)
    local tab={Window=self,Page=page,Button=button,Palette=p}
    function tab:Select()
        for _, other in ipairs(self.Window.Tabs) do
            other.Page.Visible=false;other.Button.TextColor3=p.muted;other.Button.BackgroundTransparency=0.5
        end
        page.Visible=true;button.TextColor3=p.text;button.BackgroundTransparency=0
        button.BackgroundColor3=p.card
    end
    button.MouseButton1Click:Connect(function()tab:Select()end)
    table.insert(self.Tabs,tab)
    if #self.Tabs==1 then tab:Select() end
    return setmetatable(tab,{__index={
        AddSection=function(t,titleText)
            local section=create("Frame",{Name="Section",Size=UDim2.new(1,-2,0,42),BackgroundColor3=p.card,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y},t.Page)
            corner(section,10); skin(section, SUBPANEL); stroke(section,p.accent,0.57,1); padding(section,10)
            local lay=create("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},section)
            local titleLabel=label(section,titleText or "Section",12,p.accent,true)
            titleLabel.Size=UDim2.new(1,0,0,19)
            return t.Window:_section(section,p)
        end,
        AddButton=function(t,opts)return t:AddSection("Actions"):AddButton(opts)end,
        AddToggle=function(t,id,opts)return t:AddSection("Options"):AddToggle(id,opts)end,
        AddSlider=function(t,id,opts)return t:AddSection("Options"):AddSlider(id,opts)end,
        AddDropdown=function(t,id,opts)return t:AddSection("Options"):AddDropdown(id,opts)end,
        AddKeybind=function(t,id,opts)return t:AddSection("Options"):AddKeybind(id,opts)end,
        AddInput=function(t,id,opts)return t:AddSection("Options"):AddInput(id,opts)end
    }})
end

function UI:_section(container,p)
    local s={Window=self,Container=container,Palette=p}
    function s:_row(titleText,description,height)
        local row=create("Frame",{Size=UDim2.new(1,0,0,height or 51),BackgroundColor3=p.surface,BorderSizePixel=0},container)
        corner(row,8)
        skin(row, CONTROL, 16, 3, 0.84)
        local name=label(row,titleText or "Option",12,p.text,true)
        name.Position=UDim2.fromOffset(9,6);name.Size=UDim2.new(1,-115,0,21)
        if description then
            local desc=label(row,description,10,p.muted)
            desc.Position=UDim2.fromOffset(9,27);desc.Size=UDim2.new(1,-18,0,20)
        end
        return row
    end
    function s:AddButton(opts)
        opts=opts or {}; local row=self:_row(opts.Title or "Button",opts.Description)
        local b=create("TextButton",{Text=opts.ButtonText or "RUN",Font=Enum.Font.GothamBold,TextSize=11,Size=UDim2.fromOffset(80,28),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0)},row)
        corner(b,8);paintButton(b,p);gradient(b,Color3.fromRGB(255,224,27),Color3.fromRGB(111,255,29))
        b.MouseButton1Click:Connect(function()safeCallback(opts.Callback)end)
        return b
    end
    function s:AddToggle(id,opts)
        opts=opts or {};local value=opts.Default==true;local row=self:_row(opts.Title or id,opts.Description)
        local b=create("TextButton",{Text=value and "ON" or "OFF",Font=Enum.Font.GothamBold,TextSize=11,Size=UDim2.fromOffset(62,28),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0)},row)
        corner(b,8)
        local toggleGradient = gradient(b,Color3.fromRGB(255,223,32),Color3.fromRGB(120,255,45))
        local ctrl={}
        function ctrl:SetValue(v)
            value=not not v;b.Text=value and "ON" or "OFF";b.BackgroundColor3=value and p.accent or p.card
            b.TextColor3=value and p.bg or p.muted; b.UIGradient.Enabled=value; self.Window._saved[id]=value;safeCallback(opts.Callback,value)
        end
        ctrl.Window=self.Window
        b.MouseButton1Click:Connect(function()ctrl:SetValue(not value)end)
        ctrl:SetValue(value);self.Window.Controls[id]=ctrl
        return ctrl
    end
    function s:AddSlider(id,opts)
        opts=opts or {};local minimum=opts.Min or 0;local maximum=math.max(opts.Max or 100,minimum+0.001);local step=opts.Rounding or 1
        local row=self:_row(opts.Title or id,opts.Description,68)
        local valueLabel=label(row,"",11,p.accent,true);valueLabel.Position=UDim2.new(1,-65,0,7);valueLabel.Size=UDim2.fromOffset(58,19);valueLabel.TextXAlignment=Enum.TextXAlignment.Right
        local bar=create("Frame",{Position=UDim2.new(0,11,0,49),Size=UDim2.new(1,-22,0,8),BackgroundColor3=p.card,BorderSizePixel=0,Active=true},row);corner(bar,8)
        local fill=create("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=p.accent,BorderSizePixel=0},bar);corner(fill,8);gradient(fill,p.accent,p.lime)
        local value=minimum; local ctrl={}
        function ctrl:SetValue(v)
            value=math.clamp(math.floor((tonumber(v) or minimum)/step+0.5)*step,minimum,maximum)
            fill.Size=UDim2.fromScale((value-minimum)/(maximum-minimum),1);valueLabel.Text=tostring(value)
            self.Window._saved[id]=value;safeCallback(opts.Callback,value)
        end
        ctrl.Window=self.Window
        local sliding=false
        local function setByX(x)
            local ratio=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
            ctrl:SetValue(minimum+ratio*(maximum-minimum))
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then sliding=true;setByX(input.Position.X)end
        end)
        table.insert(self.Window._connections,UserInputService.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then setByX(input.Position.X)end
        end))
        table.insert(self.Window._connections,UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then sliding=false end
        end))
        ctrl:SetValue(opts.Default or minimum);self.Window.Controls[id]=ctrl
        return ctrl
    end
    function s:AddDropdown(id,opts)
        opts=opts or {};local values=opts.Values or {};local row=self:_row(opts.Title or id,opts.Description,51)
        local b=create("TextButton",{Text="Select  ▾",Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=p.text,BackgroundColor3=p.card,Size=UDim2.fromOffset(130,29),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0)},row)
        corner(b,8)
        local popup=create("Frame",{Size=UDim2.fromOffset(150,math.min(#values,7)*29+12),BackgroundColor3=p.card,BorderSizePixel=0,Visible=false,ZIndex=30},self.Window.Gui)
        corner(popup,10);stroke(popup,p.accent,0.45);padding(popup,6)
        create("UIListLayout",{Padding=UDim.new(0,2)},popup)
        local ctrl={Window=self.Window}
        function ctrl:SetValue(v)
            b.Text=tostring(v).."  ▾";self.Window._saved[id]=v;safeCallback(opts.Callback,v);popup.Visible=false
        end
        local function populate()
            for _,child in ipairs(popup:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            popup.Size=UDim2.fromOffset(150, math.min(#values,7)*29+12)
            for _,item in ipairs(values) do
                local itemButton=create("TextButton",{Text=tostring(item),Font=Enum.Font.Gotham,TextSize=11,TextColor3=p.text,BackgroundColor3=p.surface,Size=UDim2.new(1,0,0,27),ZIndex=31},popup)
                corner(itemButton,6);itemButton.MouseButton1Click:Connect(function()ctrl:SetValue(item)end)
            end
        end
        function ctrl:SetValues(v) values=v or {};populate() end
        b.MouseButton1Click:Connect(function()
            popup.Position=UDim2.fromOffset(b.AbsolutePosition.X, b.AbsolutePosition.Y+b.AbsoluteSize.Y+3)
            popup.Visible=not popup.Visible
        end)
        populate();ctrl:SetValue(opts.Default or values[1] or "None");self.Window.Controls[id]=ctrl
        return ctrl
    end
    function s:AddInput(id,opts)
        opts=opts or {};local row=self:_row(opts.Title or id,opts.Description,58)
        local input=create("TextBox",{PlaceholderText=opts.Placeholder or "Type here...",Text=tostring(opts.Default or ""),ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=12,TextColor3=p.text,PlaceholderColor3=p.muted,BackgroundColor3=p.card,Position=UDim2.new(0,9,0,31),Size=UDim2.new(1,-18,0,22)},row);corner(input,6)
        local ctrl={Window=self.Window}
        function ctrl:SetValue(value) input.Text=tostring(value);self.Window._saved[id]=input.Text;safeCallback(opts.Callback,input.Text) end
        input.FocusLost:Connect(function()ctrl:SetValue(input.Text)end)
        self.Window.Controls[id]=ctrl;return ctrl
    end
    function s:AddKeybind(id,opts)
        opts=opts or {};local chosen=opts.Default or Enum.KeyCode.RightControl;local listening=false
        local row=self:_row(opts.Title or id,opts.Description)
        local button=create("TextButton",{Text=chosen.Name,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=p.text,BackgroundColor3=p.card,Size=UDim2.fromOffset(110,28),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0)},row);corner(button,8)
        local ctrl={Window=self.Window}
        function ctrl:SetValue(value)
            if typeof(value)=="EnumItem" then chosen=value end
            button.Text=chosen.Name;self.Window._saved[id]=chosen.Name;safeCallback(opts.ChangedCallback,chosen)
        end
        button.MouseButton1Click:Connect(function()listening=true;button.Text="Press a key"end)
        table.insert(self.Window._connections,UserInputService.InputBegan:Connect(function(input,processed)
            if listening and input.KeyCode~=Enum.KeyCode.Unknown then listening=false;ctrl:SetValue(input.KeyCode)
            elseif not processed and input.KeyCode==chosen then safeCallback(opts.Callback,chosen) end
        end))
        self.Window.Controls[id]=ctrl;return ctrl
    end
    return s
end

function UI:Notify(opts)
    opts=opts or {};local p=self.Palette
    local card=create("Frame",{Name="Notification",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-18),Size=UDim2.fromOffset(294,76),BackgroundColor3=p.surface,ZIndex=50},self.Gui)
    corner(card,10);stroke(card,p.accent,0.35)
    local title=label(card,opts.Title or "AEVRIX",13,p.accent,true);title.Position=UDim2.fromOffset(12,8);title.Size=UDim2.new(1,-24,0,21);title.ZIndex=51
    local body=label(card,opts.Content or opts.Description or "",11,p.text);body.Position=UDim2.fromOffset(12,30);body.Size=UDim2.new(1,-24,0,35);body.ZIndex=51
    task.delay(opts.Duration or 4,function()if card.Parent then card:Destroy() end end)
end
function UI:SetTheme(theme)
    -- Theme selection is saved for the next window creation. Rebuild to recolor all controls.
    if PALETTES[theme] then self.Theme=theme;self.Palette=PALETTES[theme] end
end
function UI:SaveSettings()
    if not self._storage then return false end
    if type(writefile)~="function" or type(makefolder)~="function" or type(isfolder)~="function" then return false end
    local ok=pcall(function()
        if not isfolder(self._folder) then makefolder(self._folder) end
        writefile(self._folder.."/options.json",HttpService:JSONEncode({Theme=self.Theme,Values=self._saved}))
    end)
    return ok
end
function UI:LoadSettings()
    if not self._storage or type(readfile)~="function" or type(isfile)~="function" then return false end
    local path=self._folder.."/options.json"
    if not isfile(path) then return false end
    local ok,data=pcall(function()return HttpService:JSONDecode(readfile(path))end)
    if not ok or type(data)~="table" then return false end
    if PALETTES[data.Theme] then self.Theme=data.Theme end
    for id,value in pairs(data.Values or {}) do
        local control=self.Controls[id]
        if control and type(control.SetValue)=="function" then
            if type(value)=="string" and Enum.KeyCode[value] and id:lower():find("keybind") then value=Enum.KeyCode[value] end
            control:SetValue(value)
        end
    end
    return true
end

return UI
