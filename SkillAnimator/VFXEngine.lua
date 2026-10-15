--[[
    Skill Hub — Skill Animator Module
    File: SkillAnimator/VFXEngine.lua
    Description: Procedural 3D Skill VFX & Character Aura Renderer for Blox Fruits
]]

local TweenService = game:GetService("TweenService")
local Workspace    = game:GetService("Workspace")
local Debris       = game:GetService("Debris")
local Players      = game:GetService("Players")

local LocalPlayer  = Players.LocalPlayer
local VFXEngine    = {}

VFXEngine.PersistentAuraEnabled = false
VFXEngine.CurrentAuraColor      = Color3.fromRGB(56, 189, 248)

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Create a glowing neon part that tweens and self-cleans
local function spawnNeonPart(shape, cframe, startSize, endSize, color, duration, material)
    local p = Instance.new("Part")
    p.Name = "SkillAnimator_VFX"
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = false
    p.Shape = shape or Enum.PartType.Ball
    p.Material = material or Enum.Material.Neon
    p.Color = color
    p.Size = startSize
    p.CFrame = cframe
    p.Transparency = 0.15
    p.Parent = Workspace

    TweenService:Create(
        p,
        TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {
            Size = endSize,
            Transparency = 1,
        }
    ):Play()

    Debris:AddItem(p, duration + 0.05)
    return p
end

-- Spawn radial slash crescent ring
local function spawnSlashArc(originCF, color, scale, duration)
    for i = 1, 3 do
        local angle = math.rad((i - 2) * 32)
        local slashCF = originCF * CFrame.Angles(math.rad(math.random(-25, 25)), angle, math.rad(math.random(-35, 35)))
        local part = spawnNeonPart(
            Enum.PartType.Block,
            slashCF,
            Vector3.new(0.4, 0.4, 2),
            Vector3.new(0.15, scale * 1.4, scale * 2.8),
            color,
            duration
        )
        local mesh = Instance.new("SpecialMesh", part)
        mesh.MeshType = Enum.MeshType.Sphere
    end
end

-- Spawn lightning bolts radiating from origin
local function spawnLightningArcs(originPos, color, boltCount, radius)
    for _ = 1, boltCount do
        task.spawn(function()
            local prev = originPos
            local dir = Vector3.new(math.random(-100, 100), math.random(-20, 80), math.random(-100, 100)).Unit
            for seg = 1, 5 do
                local nextPos = prev + dir * (radius / 5) + Vector3.new(
                    math.random(-3, 3),
                    math.random(-3, 3),
                    math.random(-3, 3)
                )
                local dist = (nextPos - prev).Magnitude
                local segPart = Instance.new("Part")
                segPart.Name = "SkillAnimator_Bolt"
                segPart.Anchored = true
                segPart.CanCollide = false
                segPart.Material = Enum.Material.Neon
                segPart.Color = color
                segPart.Size = Vector3.new(0.28, 0.28, dist)
                segPart.CFrame = CFrame.lookAt((prev + nextPos) / 2, nextPos)
                segPart.Parent = Workspace

                TweenService:Create(segPart, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
                    Transparency = 1,
                    Size = Vector3.new(0.05, 0.05, dist),
                }):Play()
                Debris:AddItem(segPart, 0.38)
                prev = nextPos
                task.wait(0.02)
            end
        end)
    end
end

-- Trigger named VFX preset
function VFXEngine.PlayPreset(presetName)
    local root = getRoot()
    if not root then return end
    local cf = root.CFrame

    if presetName == "ConquerorHakiBurst" then
        spawnNeonPart(Enum.PartType.Ball, cf, Vector3.new(2, 2, 2), Vector3.new(46, 46, 46), Color3.fromRGB(220, 38, 38), 0.65)
        spawnNeonPart(Enum.PartType.Ball, cf, Vector3.new(1, 1, 1), Vector3.new(32, 32, 32), Color3.fromRGB(17, 24, 39), 0.55)
        spawnLightningArcs(cf.Position, Color3.fromRGB(239, 68, 68), 8, 24)
        spawnSlashArc(cf, Color3.fromRGB(248, 113, 113), 18, 0.45)

    elseif presetName == "KitsuneAzureFlame" then
        spawnNeonPart(Enum.PartType.Ball, cf, Vector3.new(2, 2, 2), Vector3.new(28, 28, 28), Color3.fromRGB(34, 211, 238), 0.50)
        spawnSlashArc(cf, Color3.fromRGB(56, 189, 248), 16, 0.40)
        spawnLightningArcs(cf.Position, Color3.fromRGB(103, 232, 249), 6, 18)

    elseif presetName == "CrimsonSlash" then
        spawnSlashArc(cf * CFrame.new(0, 0, -4), Color3.fromRGB(239, 68, 68), 20, 0.38)
        spawnNeonPart(Enum.PartType.Ball, cf, Vector3.new(1.5, 1.5, 1.5), Vector3.new(22, 22, 22), Color3.fromRGB(185, 28, 28), 0.42)

    elseif presetName == "GoldenShockwave" then
        spawnNeonPart(Enum.PartType.Cylinder, cf * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.8, 3, 3), Vector3.new(0.2, 36, 36), Color3.fromRGB(250, 204, 21), 0.50)
        spawnSlashArc(cf, Color3.fromRGB(253, 224, 71), 15, 0.35)

    elseif presetName == "CyanLightning" then
        spawnLightningArcs(cf.Position, Color3.fromRGB(56, 189, 248), 10, 22)
        spawnNeonPart(Enum.PartType.Ball, cf, Vector3.new(2, 2, 2), Vector3.new(24, 24, 24), Color3.fromRGB(14, 165, 233), 0.40)

    elseif presetName == "DragonEmber" then
        spawnNeonPart(Enum.PartType.Cylinder, cf * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(40, 2, 2), Vector3.new(45, 22, 22), Color3.fromRGB(249, 115, 22), 0.55)
        spawnLightningArcs(cf.Position, Color3.fromRGB(251, 146, 60), 7, 20)
    end
end

-- Persistent Sovereign Aura Loop
task.spawn(function()
    while task.wait(0.22) do
        if VFXEngine.PersistentAuraEnabled then
            pcall(function()
                local root = getRoot()
                if root then
                    local offset = Vector3.new(math.random(-35, 35) / 10, -2.5, math.random(-35, 35) / 10)
                    local startCF = CFrame.new(root.Position + offset)
                    local endPart = spawnNeonPart(
                        Enum.PartType.Ball,
                        startCF,
                        Vector3.new(0.65, 1.8, 0.65),
                        Vector3.new(0.1, 4.2, 0.1),
                        VFXEngine.CurrentAuraColor,
                        0.55
                    )
                    TweenService:Create(endPart, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
                        CFrame = startCF + Vector3.new(0, 6.5, 0),
                    }):Play()
                end
            end)
        end
    end
end)

return VFXEngine
