--[[
    Skill Hub — Skill Animator Module
    File: SkillAnimator/ComboSequencer.lua
    Description: Automated Blox Fruits Skill Combo Sequencer (Z/X/C/V/F)
                 with Weapon Switching, Hold Timing, and Synchronized VFX
]]

local Players             = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer         = Players.LocalPlayer

local ComboSequencer = {}
ComboSequencer.IsRunning   = false
ComboSequencer.LoopCombo   = false
ComboSequencer.ActiveSteps = {}

local function equipToolByCategory(category)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == category then
            return
        end
    end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == category then
            hum:EquipTool(tool)
            return
        end
    end
end

local function pressSkillKey(keyName, holdDuration)
    local keyCode = Enum.KeyCode[keyName] or Enum.KeyCode.Z
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(math.max(holdDuration or 0.12, 0.05))
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

function ComboSequencer.ExecuteChain(steps, vfxEngine, onStepCallback)
    if ComboSequencer.IsRunning then return end
    ComboSequencer.IsRunning = true

    task.spawn(function()
        repeat
            for idx, step in ipairs(steps) do
                if not ComboSequencer.IsRunning then break end
                if onStepCallback then
                    pcall(onStepCallback, idx, step)
                end
                equipToolByCategory(step.Weapon or "Melee")
                task.wait(0.06)
                if vfxEngine and step.VFX then
                    pcall(function() vfxEngine.PlayPreset(step.VFX) end)
                end
                pressSkillKey(step.Key or "Z", step.Hold or 0.15)
                task.wait(math.max(step.Delay or 0.3, 0.08))
            end
        until not ComboSequencer.LoopCombo or not ComboSequencer.IsRunning

        ComboSequencer.IsRunning = false
        if onStepCallback then
            pcall(onStepCallback, 0, nil)
        end
    end)
end

function ComboSequencer.Stop()
    ComboSequencer.IsRunning = false
    ComboSequencer.LoopCombo = false
end

return ComboSequencer
