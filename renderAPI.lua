
local Render = {}

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

export type Renderer = {
    origin: Vector3,
    size: Vector2,
    distance: number,
    part: BasePart,
    drawings: { [string]: any },
    update: (self: Renderer) -> (),
}

local renderers = {}

function Render.CreateRenderer(size: {x: number, y: number}, distance: number, part: BasePart)
    local newRenderer: Renderer = {
        origin = Vector3.new(),
        size = Vector2.new(size.x, size.y),
        distance = distance,
        part = part,
        drawings = {}
    }

    function newRenderer:update()
        if not self.part or not self.part:IsDescendantOf(workspace) then
            for _, drawing in pairs(self.drawings) do
                drawing:Remove()
            end
            renderers[self] = nil
            return
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(self.part.Position)
        if onScreen and (Camera.CFrame.Position - self.part.Position).Magnitude <= self.distance then
            local distance = math.floor((Camera.CFrame.Position - self.part.Position).Magnitude)
            for _, drawing in pairs(self.drawings) do
                drawing.Visible = true

                if drawing.Type == "Square" or drawing.Type == "Quad" then
                    drawing.Position = Vector2.new(screenPos.X, screenPos.Y)

                elseif drawing.Type == "Text" then
                    if drawing._dynamicText then
                        local txt = drawing._dynamicText
                        if txt == "distance" then
                            drawing.Text = tostring(distance).."m"
                        elseif txt == "name" then
                            drawing.Text = self.part.Parent and self.part.Parent.Name or "Unknown"
                        end
                    end
                    drawing.Position = Vector2.new(screenPos.X, screenPos.Y) + (drawing._offset or Vector2.zero)

                elseif drawing.Type == "Line" then
                    local health = self.part.Parent:FindFirstChild("Humanoid") and self.part.Parent.Humanoid.Health or 0
                    local maxHealth = self.part.Parent:FindFirstChild("Humanoid") and self.part.Parent.Humanoid.MaxHealth or 100
                    drawing.From = Vector2.new(screenPos.X - self.size.X/2 - 5, screenPos.Y - self.size.Y/2)
                    drawing.To = Vector2.new(
                        screenPos.X - self.size.X/2 - 5, 
                        screenPos.Y - self.size.Y/2 + (self.size.Y * (1 - math.clamp(health/maxHealth, 0, 1)))
                    )
                end
            end
        else
            for _, drawing in pairs(self.drawings) do
                drawing.Visible = false
            end
        end
    end

    renderers[newRenderer] = true
    return newRenderer
end

function Render.new(props)
    local renderer = props.renderer
    local drawingType = props.type or "Square"

    local drawing = Drawing.new(drawingType)
    drawing.Color = props.color or Color3.fromRGB(255,255,255)
    drawing.Thickness = props.thickness or 1
    drawing.Size = props.size and Vector2.new(
        renderer.size.X * props.size.x,
        renderer.size.Y * props.size.y
    ) or Vector2.new(renderer.size.X, renderer.size.Y)
    drawing.Visible = false
    drawing.Filled = props.filled or false
    drawing.Transparency = props.transparency or 1
    drawing.Type = drawingType

    if drawingType == "Text" then
        drawing.Text = props.text or ""
        drawing.Size = props.textsize or 13
        drawing.Center = true
        drawing.Outline = props.outline or false
        drawing._offset = props.offset or Vector2.zero
        drawing._dynamicText = props.dynamicText
    end

    if drawingType == "Line" then
        drawing.From = Vector2.zero
        drawing.To = Vector2.zero
    end

    if props.gradient then
        task.spawn(function()
            local steps = props.gradient.steps or 5
            local colors = {
                props.gradient.one,
                props.gradient.second,
                props.gradient.third,
            }
            local idx = 1
            while drawing do
                drawing.Color = colors[idx]
                idx = idx % #colors + 1
                task.wait(1 / steps)
            end
        end)
    end

    renderer.drawings[tostring(drawing)] = drawing
    return drawing
end

RunService.RenderStepped:Connect(function()
    for renderer in pairs(renderers) do
        renderer:update()
    end
end)

return Render
