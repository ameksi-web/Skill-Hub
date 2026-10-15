--[[
    Skill Hub — Skill Animator Module
    File: SkillAnimator/AnimationPresets.lua
    Description: Custom Vector Icon Registry (Lucide/Feather rbxassetid) +
                 Blox Fruits Skill Animation & VFX Presets
]]

local AnimationPresets = {}

-- ═══════════════════════════════════════════════════════════════════════════
--  CUSTOM VECTOR ICONS REGISTRY (LUCIDE / FEATHER RBXASSETID)
-- ═══════════════════════════════════════════════════════════════════════════

AnimationPresets.Icons = {
    Logo        = "rbxassetid://10734950309", -- Sparkles / Hub Crest
    AutoFarm    = "rbxassetid://10734975692", -- Swords / Combat
    Stats       = "rbxassetid://10709782497", -- BarChart / Stats
    Fruits      = "rbxassetid://10723374176", -- Flame / Devil Fruit
    Teleport    = "rbxassetid://10709818626", -- Compass / Navigation
    ESP         = "rbxassetid://10723346959", -- Eye / Visuals
    Animator    = "rbxassetid://10723354551", -- Film / Skill Animator
    Misc        = "rbxassetid://10734950309", -- Settings / Gear
    Play        = "rbxassetid://10734923549", -- Play Icon
    Stop        = "rbxassetid://10734972627", -- Stop / Square
    Loop        = "rbxassetid://10734940376", -- Repeat / Loop
    Speed       = "rbxassetid://10747384394", -- Zap / Lightning
    VFX         = "rbxassetid://10734982144", -- Wand / Effects
    Combo       = "rbxassetid://10723397898", -- Layers / Combo Chain
    Boss        = "rbxassetid://10734962068", -- Skull / Boss
    Search      = "rbxassetid://10734943674", -- Magnifying Glass
    Close       = "rbxassetid://10747384394", -- X / Close
    GlowCircle  = "rbxassetid://5028857084",  -- Soft Radial Glow
}

-- ═══════════════════════════════════════════════════════════════════════════
--  BLOX FRUITS & COMBAT ANIMATION PRESETS
-- ═══════════════════════════════════════════════════════════════════════════

AnimationPresets.Animations = {
    {
        Id       = "godhuman_flurry",
        Name     = "Godhuman — Soaring Beast Flurry",
        Category = "Fighting Style",
        AnimId   = "rbxassetid://522635514",
        Speed    = 1.45,
        Weight   = 1.0,
        Looped   = false,
        VFX      = "GoldenShockwave",
        Accent   = Color3.fromRGB(250, 204, 21),
    },
    {
        Id       = "sanguine_devour",
        Name     = "Sanguine Art — Bloodbane Drain",
        Category = "Fighting Style",
        AnimId   = "rbxassetid://616163682",
        Speed    = 1.35,
        Weight   = 1.0,
        Looped   = false,
        VFX      = "CrimsonSlash",
        Accent   = Color3.fromRGB(239, 68, 68),
    },
    {
        Id       = "dragon_talon_inferno",
        Name     = "Dragon Talon — Talon Ignition",
        Category = "Fighting Style",
        AnimId   = "rbxassetid://616158929",
        Speed    = 1.25,
        Weight   = 1.0,
        Looped   = false,
        VFX      = "DragonEmber",
        Accent   = Color3.fromRGB(249, 115, 22),
    },
    {
        Id       = "electric_claw_blitz",
        Name     = "Electric Claw — Thunderclap Slash",
        Category = "Fighting Style",
        AnimId   = "rbxassetid://656117878",
        Speed    = 1.65,
        Weight   = 1.0,
        Looped   = false,
        VFX      = "CyanLightning",
        Accent   = Color3.fromRGB(56, 189, 248),
    },
    {
        Id       = "kitsune_tails_barrage",
        Name     = "Kitsune — Fox Fire Disruption",
        Category = "Mythical Fruit",
        AnimId   = "rbxassetid://707853694",
        Speed    = 1.50,
        Weight   = 1.0,
        Looped   = false,
        VFX      = "KitsuneAzureFlame",
        Accent   = Color3.fromRGB(34, 211, 238),
    },
    {
        Id       = "dragon_rework_cataclysm",
        Name     = "Dragon (East/West) — Imperial Cataclysm",
        Category = "Mythical Fruit",
        AnimId   = "rbxassetid://616168032",
        Speed    = 1.15,
        Weight   = 1.0,
        Looped   = false,
        VFX      = "ConquerorHakiBurst",
        Accent   = Color3.fromRGB(220, 38, 38),
    },
    {
        Id       = "dough_awakened_pierce",
        Name     = "Awakened Dough — Piercing Clothesline",
        Category = "Mythical Fruit",
        AnimId   = "rbxassetid://656118852",
        Speed    = 1.40,
        Weight   = 1.0,
        Looped   = false,
        VFX      = "GoldenShockwave",
        Accent   = Color3.fromRGB(253, 224, 71),
    },
    {
        Id       = "cdk_dimensional_slash",
        Name     = "Cursed Dual Katana — Revolving Ravager",
        Category = "Mythical Sword",
        AnimId   = "rbxassetid://522638767",
        Speed    = 1.55,
        Weight   = 1.0,
        Looped   = false,
        VFX      = "CrimsonSlash",
        Accent   = Color3.fromRGB(168, 85, 247),
    },
    {
        Id       = "levitation_aura_idle",
        Name     = "Awakened Race V4 — Sovereign Float Loop",
        Category = "Aura & Pose",
        AnimId   = "rbxassetid://616006778",
        Speed    = 0.85,
        Weight   = 1.0,
        Looped   = true,
        VFX      = "ConquerorHakiBurst",
        Accent   = Color3.fromRGB(129, 140, 248),
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
--  DEFAULT SKILL COMBO CHAINS (Z / X / C / V)
-- ═══════════════════════════════════════════════════════════════════════════

AnimationPresets.Combos = {
    ["One-Shot Godhuman + Kitsune + CDK"] = {
        {Weapon = "Melee",      Key = "C", Hold = 0.25, Delay = 0.35, VFX = "GoldenShockwave"},
        {Weapon = "Blox Fruit", Key = "C", Hold = 0.10, Delay = 0.40, VFX = "KitsuneAzureFlame"},
        {Weapon = "Blox Fruit", Key = "X", Hold = 0.15, Delay = 0.30, VFX = "KitsuneAzureFlame"},
        {Weapon = "Sword",      Key = "Z", Hold = 0.30, Delay = 0.35, VFX = "CrimsonSlash"},
        {Weapon = "Melee",      Key = "Z", Hold = 0.15, Delay = 0.25, VFX = "GoldenShockwave"},
        {Weapon = "Melee",      Key = "X", Hold = 0.10, Delay = 0.20, VFX = "GoldenShockwave"},
    },
    ["Sanguine Art + Dragon + Shark Anchor"] = {
        {Weapon = "Melee",      Key = "Z", Hold = 0.20, Delay = 0.35, VFX = "CrimsonSlash"},
        {Weapon = "Sword",      Key = "X", Hold = 0.20, Delay = 0.30, VFX = "CyanLightning"},
        {Weapon = "Sword",      Key = "Z", Hold = 0.15, Delay = 0.30, VFX = "CyanLightning"},
        {Weapon = "Blox Fruit", Key = "Z", Hold = 0.25, Delay = 0.40, VFX = "DragonEmber"},
        {Weapon = "Blox Fruit", Key = "C", Hold = 0.35, Delay = 0.45, VFX = "ConquerorHakiBurst"},
        {Weapon = "Melee",      Key = "C", Hold = 0.15, Delay = 0.25, VFX = "CrimsonSlash"},
    },
    ["Portal V + CDK + Godhuman Burst"] = {
        {Weapon = "Blox Fruit", Key = "Z", Hold = 0.10, Delay = 0.30, VFX = "CyanLightning"},
        {Weapon = "Sword",      Key = "X", Hold = 0.20, Delay = 0.30, VFX = "CrimsonSlash"},
        {Weapon = "Sword",      Key = "Z", Hold = 0.35, Delay = 0.35, VFX = "CrimsonSlash"},
        {Weapon = "Melee",      Key = "Z", Hold = 0.15, Delay = 0.25, VFX = "GoldenShockwave"},
        {Weapon = "Melee",      Key = "C", Hold = 0.25, Delay = 0.30, VFX = "GoldenShockwave"},
    },
}

return AnimationPresets
