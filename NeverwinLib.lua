local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Neverwin = {}
Neverwin.__index = Neverwin

-- Internal Icon Mapping (Hyper-Stable Standard Assets)
Neverwin.Icons = {
    ["combat"] = "rbxassetid://6031068433",
    ["anti aim"] = "rbxassetid://6031094678",
    ["legitbot"] = "rbxassetid://6034502360",
    ["players"] = "rbxassetid://6031289129",
    ["weapon"] = "rbxassetid://6034401257",
    ["world"] = "rbxassetid://6035213600",
    ["local player"] = "rbxassetid://6034287525",
    ["scripts"] = "rbxassetid://6034825229",
    ["config"] = "rbxassetid://6035151525",
}

local function Create(class, properties, children)
    local element = Instance.new(class)
    for i, v in pairs(properties) do
        element[i] = v
    end
    if children then
        for _, child in pairs(children) do
            child.Parent = element
        end
    end
    return element
end

function Neverwin.new(title)
    local self = setmetatable({}, Neverwin)
    self.LayoutCount = 0

    -- Clear existing Neverwin GUIs to prevent ghosting
    local old = (gethui and gethui():FindFirstChild("Neverwin")) or CoreGui:FindFirstChild("Neverwin")
    if old then old:Destroy() end

    self.ScreenGui = Create("ScreenGui", {
        Name = "Neverwin",
        Parent = (gethui and gethui()) or CoreGui,
        ResetOnSpawn = false
    })

    self.Main = Create("Frame", {
        Name = "Main",
        Parent = self.ScreenGui,
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        Size = UDim2.new(0, 600, 0, 400),
        ClipsDescendants = false
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) })
    })

    self.Sidebar = Create("Frame", {
        Name = "Sidebar",
        Parent = self.Main,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Size = UDim2.new(0, 160, 1, 0)
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -10, 0, 0),
            Size = UDim2.new(0, 10, 1, 0)
        })
    })

    self.Title = Create("TextLabel", {
        Name = "Title",
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 15),
        Size = UDim2.new(1, -30, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = title:upper(),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.TabsContainer = Create("ScrollingFrame", {
        Name = "Tabs",
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(1, 0, 1, -100),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
        Create("UIPadding", { PaddingTop = UDim.new(0, 10) })
    })

    self.Content = Create("Frame", {
        Name = "Content",
        Parent = self.Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 0),
        Size = UDim2.new(1, -160, 1, 0)
    })

    self.UserProfile = Create("Frame", {
        Name = "UserProfile",
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -50),
        Size = UDim2.new(1, 0, 0, 50)
    })

    self.UserIcon = Create("ImageLabel", {
        Name = "Icon",
        Parent = self.UserProfile,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Position = UDim2.new(0, 15, 0.5, -15),
        Size = UDim2.new(0, 30, 0, 30),
        Image = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    self.UserName = Create("TextLabel", {
        Name = "Name",
        Parent = self.UserProfile,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 55, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = Players.LocalPlayer.DisplayName or Players.LocalPlayer.Name,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.TabFrames = {}
    self.CurrentTab = nil
    self.CharacterPreviewWindow = nil

    -- Dragging logic
    local dragging, dragInput, dragStart, startPos
    self.Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    self.Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            self.Main.Position = newPos
            
            if self.CharacterPreviewWindow then
                self.CharacterPreviewWindow.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset + 610, newPos.Y.Scale, newPos.Y.Offset)
            end
        end
    end)

    return self
end

function Neverwin:CreateCategory(name)
    self.LayoutCount = self.LayoutCount + 1
    return Create("TextLabel", {
        Name = name,
        Parent = self.TabsContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 25),
        Font = Enum.Font.GothamBold,
        Text = name:upper(),
        TextColor3 = Color3.fromRGB(80, 80, 80),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = self.LayoutCount
    })
end

function Neverwin:CreateTab(name, icon)
    self.LayoutCount = self.LayoutCount + 1
    local tab = {}
    
    local lookName = string.lower(string.gsub(name, "^%s*(.-)%s*$", "%1"))
    icon = icon or Neverwin.Icons[lookName] or "rbxassetid://6031763426"

    local button = Create("TextButton", {
        Name = name,
        Parent = self.TabsContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        AutoButtonColor = false,
        Font = Enum.Font.GothamSemibold,
        Text = "",
        LayoutOrder = self.LayoutCount
    })

    local btnContent = Create("Frame", {
        Parent = button,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0)
    }, {
        Create("UIPadding", { PaddingLeft = UDim.new(0, 15) }),
        Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center })
    })

    local iconLabel = Create("ImageLabel", {
        Name = "Icon",
        Parent = btnContent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 16, 0, 16),
        Image = icon,
        ImageColor3 = Color3.fromRGB(0, 170, 255)
    })

    local textLabel = Create("TextLabel", {
        Name = "Label",
        Parent = btnContent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local container = Create("ScrollingFrame", {
        Name = name .. "_Content",
        Parent = self.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255),
        Visible = false,
        ClipsDescendants = true
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
        Create("UIPadding", { PaddingTop = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15) })
    })

    table.insert(self.TabFrames, { button = button, label = textLabel, icon = iconLabel, container = container })

    button.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    function tab:CreateSection(title)
        local section = {}
        local frame = Create("Frame", {
            Name = title,
            Parent = container,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            Size = UDim2.new(0.9, 0, 0, 40),
            BorderSizePixel = 0
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
            Create("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
            Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
            Create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = title,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 0
            })
        })

        function section:CreateToggle(text, default, callback)
            local enabled = default or false
            local toggle = Create("Frame", {
                Name = text,
                Parent = frame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 25),
                LayoutOrder = #frame:GetChildren()
            })

            local label = Create("TextLabel", {
                Parent = toggle,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local bg = Create("Frame", {
                Parent = toggle,
                BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(40, 40, 40),
                Position = UDim2.new(1, -35, 0.5, -9),
                Size = UDim2.new(0, 35, 0, 18),
                BorderSizePixel = 0
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            local circle = Create("Frame", {
                Parent = bg,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                BorderSizePixel = 0
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            local btn = Create("TextButton", {
                Parent = toggle,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })

            btn.MouseButton1Click:Connect(function()
                enabled = not enabled
                TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(40, 40, 40) }):Play()
                TweenService:Create(circle, TweenInfo.new(0.2), { Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }):Play()
                callback(enabled)
            end)

            frame.Size = UDim2.new(0.9, 0, 0, frame.UIListLayout.AbsoluteContentSize.Y + 20)
            return toggle
        end

        function section:CreateSlider(text, min, max, default, callback)
            local slider = Create("Frame", {
                Name = text,
                Parent = frame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 40),
                LayoutOrder = #frame:GetChildren()
            })

            Create("TextLabel", {
                Parent = slider,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local valueLabel = Create("TextLabel", {
                Parent = slider,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -50, 0, 0),
                Size = UDim2.new(0, 50, 0, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(default),
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local bar = Create("Frame", {
                Parent = slider,
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                Position = UDim2.new(0, 0, 0, 25),
                Size = UDim2.new(1, 0, 0, 6),
                BorderSizePixel = 0
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            local fill = Create("Frame", {
                Parent = bar,
                BackgroundColor3 = Color3.fromRGB(0, 170, 255),
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BorderSizePixel = 0
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            local circle = Create("Frame", {
                Parent = bar,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new((default - min) / (max - min), -4, 0.5, -4),
                Size = UDim2.new(0, 10, 0, 10),
                BorderSizePixel = 0
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            local hitBox = Create("TextButton", {
                Parent = slider,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 20),
                Size = UDim2.new(1, 0, 0, 20),
                Text = ""
            })

            local dragging = false
            local function move(input)
                local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + (max - min) * pos)
                valueLabel.Text = tostring(val)
                
                TweenService:Create(fill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(pos, 0, 1, 0) }):Play()
                TweenService:Create(circle, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(pos, -5, 0.5, -5) }):Play()
                
                callback(val)
            end

            hitBox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    move(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    move(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            frame.Size = UDim2.new(0.9, 0, 0, frame.UIListLayout.AbsoluteContentSize.Y + 20)
            return slider
        end

        return section
    end

    return tab
end

function Neverwin:SelectTab(name)
    for _, t in pairs(self.TabFrames) do
        local isCurrent = t.button.Name == name
        t.container.Visible = isCurrent
        TweenService:Create(t.label, TweenInfo.new(0.2), { TextColor3 = isCurrent and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180) }):Play()
        TweenService:Create(t.icon, TweenInfo.new(0.2), { ImageColor3 = isCurrent and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 170, 255) }):Play()
    end
end

function Neverwin:CreateCharacterPreview()
    local windowPos = self.Main.Position
    local preview = Create("Frame", {
        Name = "CharacterPreview",
        Parent = self.ScreenGui,
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        Position = UDim2.new(windowPos.X.Scale, windowPos.X.Offset + 610, windowPos.Y.Scale, windowPos.Y.Offset),
        Size = UDim2.new(0, 200, 0, 400),
        BorderSizePixel = 0,
        ZIndex = 5
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("TextLabel", {
            Name = "Header",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 10),
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.GothamBold,
            Text = "PREVIEW",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            ZIndex = 6
        })
    })

    self.CharacterPreviewWindow = preview

    local viewport = Create("ViewportFrame", {
        Parent = preview,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 1, -40),
        ZIndex = 6
    })

    local cam = Instance.new("Camera")
    viewport.CurrentCamera = cam
    cam.Parent = viewport
    -- Point camera at the character and back it up
    cam.CFrame = CFrame.new(Vector3.new(0, 0.5, 9), Vector3.new(0, 0.5, 0))

    local baconId = 45184511
    local model = Players:CreateHumanoidModelFromUserId(baconId)
    model.Parent = viewport
    model:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 0, 0)) * CFrame.Angles(0, math.rad(180), 0))

    local rotating = false
    local lastMousePos
    local rotation = 180

    viewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            rotating = true
            lastMousePos = input.Position.X
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if rotating and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position.X - lastMousePos
            lastMousePos = input.Position.X
            rotation = rotation - delta
            model:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 0, 0)) * CFrame.Angles(0, math.rad(rotation), 0))
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            rotating = false
        end
    end)

    return preview
end

return Neverwin
