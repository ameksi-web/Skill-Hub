local __S=(function() local floor,sub,tonumber,char=math.floor,string.sub,tonumber,string.char local function m(a,b) local r=0 for _=1,32 do if b%2==1 then r=(r+a)%4294967296 end a=(a*2)%4294967296 b=floor(b/2) end return r end local function x(a,b) if type(bit32)=="table" and type(bit32.bxor)=="function" then return bit32.bxor(a,b) end local r,bit=0,1 for _=1,32 do if a%2~=b%2 then r=r+bit end a,b,bit=floor(a/2),floor(b/2),bit*2 end return r end return function(blob) local seed=tonumber(sub(blob,1,8),16) or 1 if seed==0 then seed=1 end local out={} local n=#blob for i=9,n-1,2 do local byte=tonumber(sub(blob,i,i+1),16) if not byte then return "" end seed=x(seed,(seed*8192)%4294967296) seed=x(seed,floor(seed/131072)) seed=x(seed,(seed*32)%4294967296) out[#out+1]=char(x(byte,seed%256)) end return table.concat(out) end end)();    
                                                           
                                                                              
                                                                                 
                                                                               
                                                                               
                                                    
                                                                                
                                                                              
             
                                                                                                               
                                                                                                                    
                                                                                                                  
                                                                                                                          
                                                                                                                               
                                                                                                                           
                                                                                                                             
                                                                                              
                                                       
  

local Players             = game:GetService(__S("fd24942f4f36c3e2479b91"))
local ReplicatedStorage   = game:GetService(__S("9b5c0de0c28cddad242fd777468e9d37de4ad0ee25"))
local Workspace           = game:GetService(__S("39938791569642ed3bd3c1d55b"))
local TweenService        = game:GetService(__S("d7cb01428769f7a64efe88b275ad562a"))
local UserInputService    = game:GetService(__S("76027af3a8bf560693851a41fb91a946bae7a4c5"))
local RunService          = game:GetService(__S("1439f4a4e09ca1db21d638519e90"))
                                                                   
                                                                             
                                     
local VirtualUser, VirtualInputManager
pcall(function() VirtualUser = game:GetService(__S("b2716e55de2c25199df8437b6d5b94")) end)
pcall(function() VirtualInputManager = game:GetService(__S("50a8e806c406998e2b3a8afc60d38223520274c67eaa6d")) end)
local TeleportService     = game:GetService(__S("eee061b7082887284237aeddf9fc7268f3ddeb"))
local Lighting            = game:GetService(__S("8d17db68b980ab3980e211dd"))
local StatsService        = game:GetService(__S("2b4f55195ccc00c22b"))
local Debris              = game:GetService(__S("c986ceca019390fb1eab"))

local LocalPlayer         = Players.LocalPlayer

                                                                                 
local SharedEnv = (getgenv and getgenv()) or _G or {}

                                                                              
                                                                            
                                                        
                                                                               
                                                                               
                                                                          
                                                           
                                                                           
                                                                            
                                                                                
                                                             
                                                
                                                    
local Config
local StepErrorCounts, StepErrorPrintCap = {}, 2
local function SkillHubStep(name, fn, ...)
    local result = table.pack(pcall(fn, ...))
    if not result[1] and Config.LogStepErrors ~= false then
        local seen = (StepErrorCounts[name] or 0)
        if seen < StepErrorPrintCap then
            StepErrorCounts[name] = seen + 1
            print(string.format(__S("67be487b18eb995c85398c2b5b2dbe56324b0c2a476f04bbe78ebd3fba2716f842aa2a2921"), tostring(name), tostring(result[2])))
        end
    end
    return table.unpack(result, 1, result.n)
end

local ExecutorName, ExecutorVersion = __S("05f5c22c01a40028dc7382"), __S("a42d3bddc3b127072183ea")
do
    local ok, name = pcall(function() return identifyexecutor and identifyexecutor() end)
    if ok and type(name) == __S("4264b58e173da09800d7") then
        local first, rest = string.match(name, __S("e09c2f3f9cb47c28ad76e17282f9a3728738"))
        ExecutorName = first or name
        ExecutorVersion = (rest ~= "" and rest) or __S("7ed3a8f0a399fd59c237f0")
    end
end

local function capabilityTable()
    local function has(name)
        local value
        local ok = pcall(function() value = _ENV[name] end)
        if ok and value ~= nil then return true end
        SkillHubStep(__S("1d0b22a1a3cf9c85ea530e50533e3b"), function()
            local env = getgenv and getgenv()
            if type(env) == __S("bb429c528276018a86") then value = env[name] end
            if value == nil and type(_G) == __S("597a16036aa41a62be") then value = _G[name] end
        end)
        if value == nil then return false end
        local t = type(value)
        return (t == __S("f7b18fb411105cc00566d071")) or (t == __S("95e909659305f6b5c0")) or (t == __S("34208316a21dc89ec89a81de"))
    end
    return {
        { name = __S("d257fcc7481ace0868a7add6675576ba82ff"),        ok = has(__S("708f767830f1aae50ad59076bfe08ac0faab")) },
        { name = __S("0ec6f02920a97247e6bbca941a711b55"),          ok = has(__S("acfe69da5007a69fac2e9faa4a0c2821")) },
        { name = __S("4b35e38b67d16b5e1f664ffdb7a28f"),           ok = has(__S("e96d5d3c1721da5de518a49d13990a")) },
        { name = __S("87a4d6ed16b85ece00f7f1"),               ok = has(__S("25dc509e3e425a8a693866")) },
        { name = __S("c413ca4fc40b4846ae28cb6001f2650dd1c1dfe411"),     ok = has(__S("624b4400a3a136b797a188f52aee9498b9d1ad356d")) },
        { name = __S("0082bdb1380bbf3f094710f6c2c8fb785e890b562b"),     ok = has(__S("9eba37621ac0514984280916792b3b6382391a124e")) },
        { name = __S("3cf1b1135d183b0ddcdb36e9df392285fc36"),        ok = has(__S("db292ac41b5b57c5781687525cc957323ef0")) },
        { name = __S("7960a47586c87ca6f7deb8"),               ok = has(__S("17981e264ca9b3d8327ff2")) },
        { name = __S("b5cf97d79e192b164ff3b7c34e0d56da"),          ok = has(__S("5407118880062202b86e9793251009a0")) },
        { name = __S("f23e8b3944d43a7767fe0c4c362df20c007aceaea6"),     ok = has(__S("907604ea0e5e1d93f9d018e6118e6b4ccca8221c44")) },
    }
end

local function diagnosticsText()
    local caps = capabilityTable()
    local lines = {
        string.format(__S("2ead7e9bc1acbd2d926a9544b5a6b7f7d859018d18c4bac192c39885"), ExecutorName, ExecutorVersion),
        string.format(__S("cce4f84c8a1ae80edd89d941c1730288397bc875918818fdc8879fbc2a0a5bd2104d72d1"), game.PlaceId, CURRENT_SEA, tostring(SEA_DETECT_SOURCE)),
        string.format(__S("6b1c71fd84e6daaafd3faee8a5cc2fbd7124fe529640300cf388501b239786779ea893e420ce0c029988873838e2565b387b5fcac7ef1e74"),
            Config.HookEngine and __S("0953ebae78a05b4735794d") or __S("a78b655f6005ad"), HookRegistry.namecallActive and __S("45c2df1079d801") or __S("e3fa58c1de27"), HookRegistry.hits or 0),
        string.format(__S("8231d2728e3f636170770bfed3dfa3231fb6a6aa438f5fd9ff2939dee2b651ce699b702de383c2df7a090cd9b52028cc245945f80beb5f6058")),
        string.format(__S("20694c2306cf28b03ad259572a25ff494d24053c0dc6e516a93d863444017d86394c531bf2afc7dcc4a73665cf4c59844ad58b94560ba2f4f939f700c283ac2c24c08aaa1629"),
            SyntheticInput.userReady and __S("bea0c5d496a1") or __S("5cd83f8555e4509d41ced461"),
            SyntheticInput.vimReady and __S("fb0fb9360ddc") or __S("994732e74e127cea0858e0f3"),
            tostring(Config.UseVirtualInput)),
        "",
    }
    local ok_list, bad_list = {}, {}
    for _, cap in ipairs(caps) do
        table.insert(cap.ok and ok_list or bad_list, cap.name)
    end
    table.insert(lines, __S("377eac985d123127226f21129e42cc8975ad14dd") .. (#ok_list > 0 and table.concat(ok_list, __S("d5b626491a1a")) or __S("73ed9ffabe")))
    table.insert(lines, __S("122519ab3653650efe2e97bbec6b17bffea1e821") .. (#bad_list > 0 and table.concat(bad_list, __S("b05c935c8b86")) or __S("4e940d0d5a")))
    return table.concat(lines, "\n")
end

                                                                               
                                                                               
                                                                                 
                                                                                 
                                                                                        
                                                                                  
                                                                            
do
    local previous = SharedEnv.SkillHubInstance
    if type(previous) == __S("eccb86bec45405f2d0") and type(previous.unload) == __S("8b03006f8e7d34915f752f85") then
        pcall(previous.unload)
        print(__S("293a7a20a4b8807283e79052e477bf7de4160a7a4fde84f3a451c598685af04cacfafc3d2930ad5e2220c9bcf25bf0239ac081b9a8a4f96ad9d0af2734fa580e263221dc82"))
    end
end

                                                                              
                                                                           
                                                                              

local CustomIcons = {
    HubCrest    = __S("c771f3d1a6147799767c640c37ff96499f654da9502910704d083cc9"),                    
    AutoFarm    = __S("65a96d823cf4e247d144b034a477edfa8de9355c6a0d6cb52d7ce317"),                  
    Stats       = __S("03e0e733c2d27a9fa7cc243bbd4082c65be28ad0b4f627eef4ec8130"),                        
    Fruits      = __S("a21860e4541fa05054aee3ce0056bf9e9472354fd46f3e2c8f53377a"),                     
    Teleport    = __S("404fda950902e82edfec5717d3a22efd6f549d7483da2995cbf6ca41"),                      
    ESP         = __S("de875446139a23cf4e33e84eb77a21e617c5f66d417d04af8e2e4337"),              
    Animator    = __S("7cbecdf7e54b0d2dd58d088c889f239f88ecccf756704d093609955d"),                         
    Settings    = __S("1af647a8fb205a97547db9c2a533be346b78caca814000c4b3e15181"),                 
    Boss        = __S("b92dc159e87c595067c2a3e78f0daff99cf028d07c74cc7c0740f860"),              
    Lightning   = __S("57653b0a7a48976d733b0c2ce65667e2a75383c14260e39f0a4fcc58"),                       
    Shield      = __S("f59cb4bb8cc88333467c2bc35d5c08e7056c57c88d817fd7fd8cd1cd"),                  
    Play        = __S("93d42e6c12025df6f77197c895a83ef2cb70a6618b143653c42d2016"),              
    Stop        = __S("320ba81dcbd6cdad3ffe2458d63e04357d38dc8f9e0fd87616321948"),              
    Loop        = __S("d04321cee1be68e6c6423cb7b0aa42a3428b60f6e2194df59a13020e"),                 
    Wand        = __S("6e7a9b7f27def42a2905c0d78cfb98f5de8e7e5be731eafe9f02b61b"),                
    Layers      = __S("0cb215300886f96b8bf2978c12f5dd3abc55ad7e5b9ecf5de472a90b"),                   
    Search      = __S("aae98ee169bc563cf57fbade58519f8fe501754d2cab7521578b316d"),                 
    RadialGlow  = __S("492108929919fbe045a1ea9b9a56568535fa78b6321d7cae2043a2"),                        
                                   
    PvP         = __S("e7588243d9423ec87b2eb7ec837509b1b12fce1200efba6670ae80d5"),                      
    Players     = __S("858ffbf47e72940344976a441b494cfe27e82a73073fba4e7baa3699"),                                
    Aim         = __S("23c775a5ee95886a734fea57a8b7ca37a6612bea242b3d1035795474"),                     
    Fly         = __S("c1feef56ae7b39c8925dd54e9c4623e35b39c8aeb60853cd5cda09d2"),                              
    Water       = __S("603669077e28bfaee7fb89d922770b685311df4d9275ac736622643b"),                       
    Magnet      = __S("fe6de2b87726fa6f5718dd6faeb388433f412befc770dbc0a0fdb1af"),                        
    Server      = __S("9ca55c692fe80caf47213d62ee58114c49444af2acaaeb724c5683f7"),                         
}

                                                                              
                                                                           
                                                                                  
                                                                              
                                                                              

                                                                              
                                                                        
                                                                          
                                                                             
                                                                   
                                                                          
                                                               
                                                                              

local SEA_PLACE_IDS = {
    [1] = { [2753915549] = true },
    [2] = { [4442272183] = true },
    [3] = { [7449423635] = true },
}

                                                                           
local SEA_SIGNATURES = {
    [1] = {
        Locations = {
            [__S("3adcd61ad8c4c30bee8c692c3e6717")] = 6, [__S("d9144fcb6e8e31ef0db9bd6e2b1e0ded34f96cbf342eb0dd55")] = 6, [__S("774bc97cfdf4e062e353d2a7621a8c06f8ea319497a510d02d")] = 6,
            [__S("1583432d6ea809aff3656073bcc71884b66e")] = 6, [__S("b3babcde64cb09e05193")] = 6, [__S("51f2368fb810e0bbc091de2e55967838ea")] = 5,
            [__S("f029b0403da9036bde0b741c80a24edace")] = 5, [__S("8e6129f1eb7378d5b0e2404e92d97b8ad760fa")] = 5, [__S("2c98a3a221c815dc6719332e9ce5595439ee")] = 5,
            [__S("cad01d53421f062057a983d05f1fb75c1b92")] = 5, [__S("690797047ab1b5774dd9c2d131faec6b91b892")] = 5, [__S("073f10b5673be3cd4c0b7cc3ff497f5e2f78")] = 5,
            [__S("a5768a667f352f74797a")] = 4, [__S("43ae0417d233f09e2bea43797b5e675a324f")] = 4,
        },
        Mobs = { [__S("e1e57dc8442e2354dd23")] = 2, [__S("801cf7796d2b51171855")] = 2, [__S("1e54712a30ba484af1")] = 2, [__S("bc8beadb351949a57c32b0")] = 2, [__S("5ac3648c75baf2cd5cd9")] = 2, [__S("f8fade3db7218a84b22c6c")] = 2 },
    },
    [2] = {
        Locations = {
            [__S("973257ee42ba66d08ff1cd7c4ec16300c8ec7b")] = 6, [__S("3569d19f15691eaf125af6cb3489")] = 6, [__S("d3a14b50f2783155d836c91525")] = 6,
            [__S("71d8c5017e981572b8871feb4bd783")] = 6, [__S("10103eb21821c86b44e428c878eb")] = 6, [__S("ae47b8636033dd56c6f128b2e502bd88d311c4e4")] = 6,
            [__S("4c7f32142e4fe804cdacf8396a41")] = 5, [__S("eab6abc50a4ddb76215d7a19504c6ea4")] = 5, [__S("88ee2576e52d2d017689e6696791ab61aa")] = 5,
            [__S("27259f27c4af6dc0")] = 5, [__S("c55d18d8f892f74714")] = 5,
        },
        Mobs = { [__S("639492897812005b2a426a50ee5b4d")] = 2, [__S("01cc0c3a9250eee109dbec1199")] = 2, [__S("a00385eb5749bf3b3ed8")] = 3, [__S("3e3aff9c1e8eb4c004d3")] = 3, [__S("dc72794d8a1f5b1041f4")] = 3, [__S("7aa9f2fe56f3cba974f42a6dece50367")] = 2, [__S("18e16cafc2c4eccefcb72ea537bb75381262")] = 2 },
    },
    [3] = {
        Locations = {
            [__S("b718e660bac88e64288838787a")] = 6, [__S("55506011d0757790abdbe9a48308d01b")] = 6, [__S("f387d9c25a0ae34e04470a799d00")] = 6,
            [__S("91bf53739d30fad505f9a32f91905f5c49c97c")] = 6, [__S("2ff6cd24ce1cf940a967d11021267f79ad65a810c8")] = 6, [__S("ce2e46d527fecebd5fb627645259b1cbf47a")] = 6,
            [__S("6c65c086488a904f1dff27b68b93c991")] = 6, [__S("0a9d3a37ee135715235447c5674fd7989f7b")] = 5, [__S("a8d4b3e85708c6dc7637de47fd94858a9f65")] = 6,
            [__S("470c2d99767d063cf2804cdfc92c1de92485bd9d4078")] = 6, [__S("e543a74a16444141addb4ec4ba360f6269f6")] = 5, [__S("837b20fb1a9b820bab393e24851ad18cb3")] = 5,
        },
        Mobs = { [__S("21b29aac4f7495447b4a1a1ffc0e60496a98bd896de3")] = 3, [__S("bfea145d3f503d3bb5975a487d4a627ec3b824")] = 3, [__S("5e218e0e52830d6b332d0c1a9395317450")] = 3, [__S("fc5907bf8c5ca8e5d50a671568a484f4")] = 3, [__S("9a908170a90950e112ad3e1a174639fb415d")] = 3, [__S("38c7fb2199a66ec929d9a9fb228d49")] = 3, [__S("d6ff74d286619012a177f3f1bce10cf83e")] = 3, [__S("7536ee8383f4ae402579a4359c56bee1056e817bd6a1")] = 3, [__S("136e683463233d0f82f093a2bf73b636f3ed")] = 3 },
    },
}

local SEA_LABELS = { [1] = __S("b1a5e1e54f38c2ff387a81b4e6"), [2] = __S("4fdd5b96b2f3858dd08b43bddfcd"), [3] = __S("ee14d5476d8ca0b82211a0d85c") }
local CONFIG_SEA_OVERRIDE = __S("8c4c4ef85098c2d2")
local SEA_DETECT_SOURCE = __S("2a83c8a952db1535d8")
local CURRENT_SEA = 1

local function readRawLevel()
    local d = LocalPlayer:FindFirstChild(__S("c8bb425a263881f7"))
    local lv = d and d:FindFirstChild(__S("66f2bc0bbe3d430a1b"))
    return (lv and lv.Value) or 0
end

                                                                            
local function scanWorldNames()
    local locNames, exactNames = {}, {}
    local function addName(name, isLocation)
        if type(name) ~= __S("052a35bc413287ba80d9") or name == "" then return end
        local lower = name:lower()
        exactNames[lower] = true
        if isLocation then table.insert(locNames, lower) end
    end

    pcall(function()
        for _, child in ipairs(Workspace:GetChildren()) do
            addName(child.Name, true)
            local locs = child:FindFirstChild(__S("a361af6d07120354d8fea9e1d2")) or child:FindFirstChild(__S("4199291e6ab2680a53e1c0"))
            if locs then
                for _, loc in ipairs(locs:GetChildren()) do addName(loc.Name, true) end
            end
        end
        for _, folderName in ipairs({ __S("dfd0a2cf2e55e7baaa4a82"), __S("7e081c8082ae2cca"), __S("1c3f9631bc96224a38da84282d37"), __S("ba770fe296adf5987a0b74d55a"), __S("58ae8993be3e67b4915ebd112a51"), __S("f6e603442f444fc228cb83f4b0"), __S("951d7cf57d09e82c718867") }) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    addName(child.Name, folderName == __S("3354f6a6ea85d5831e3f2e3106") or folderName == __S("d18c70575dbedcc91b27d6"))
                end
            end
        end
    end)

    return locNames, exactNames
end

local function computeSeaScores()
    local locNames, exactNames = scanWorldNames()
    local scores = { [1] = 0, [2] = 0, [3] = 0 }

    for sea = 1, 3 do
        local sig = SEA_SIGNATURES[sea]
        for key, weight in pairs(sig.Locations) do
            for _, name in ipairs(locNames) do
                if name:find(key, 1, true) then
                    scores[sea] += weight
                    break
                end
            end
        end
        for key, weight in pairs(sig.Mobs) do
            if exactNames[key] then scores[sea] += weight end
        end
    end
    return scores
end

local function bestScoredSea(scores)
    local best, bestScore, tied = nil, 0, false
    for sea = 1, 3 do
        local sc = scores[sea] or 0
        if sc > bestScore then
            best, bestScore, tied = sea, sc, false
        elseif sc == bestScore and sc > 0 then
            tied = true
        end
    end
    return (not tied) and best or nil, bestScore
end

local function detectSeaFromPlaceId()
    for sea = 1, 3 do
        if SEA_PLACE_IDS[sea][game.PlaceId] then return sea end
    end
    return nil
end

                                               
local function resolveSea()
    local scores = computeSeaScores()
    local mapSea, mapScore = bestScoredSea(scores)
    local placeSea = detectSeaFromPlaceId()

                                                             
    if mapSea and mapScore >= 12 then return mapSea, __S("6fc3ea0804c1fd"), scores end
    if placeSea then return placeSea, __S("0dfb63b9efdb9a54f1"), scores end
    if mapSea then return mapSea, __S("ac32dd6a68f516"), scores end

                                                                     
    local lv = readRawLevel()
    if lv >= 1500 then return 3, __S("4a6a571bd3a611155a"), scores end
    if lv >= 700 then return 2, __S("e8a1d0ccfc5386e599"), scores end
    return 1, __S("86d94a7d1a24eb4c2f"), scores
end

                                                                            
local function refreshSea()
    if CONFIG_SEA_OVERRIDE ~= __S("2510c42e25ccd5f8") then
        local forced = tonumber(CONFIG_SEA_OVERRIDE)
        if forced then
            CURRENT_SEA = forced
            SEA_DETECT_SOURCE = __S("c3483ddf0bb36be952da")
        end
        return CURRENT_SEA
    end
    local sea, source = resolveSea()
    if sea then
        CURRENT_SEA = sea
        SEA_DETECT_SOURCE = source
    end
    return CURRENT_SEA
end

refreshSea()

                                                                                  
local FRUIT_RARITY = {
    { name = __S("617fb790d54913aaa391"),    color = Color3.fromRGB(148, 163, 184), fruits = {
        __S("ffb731411c5b6d624e62"), __S("9deeaaf2b9701593"), __S("3c2624a3f8b7a2d69c"), __S("da5d9e5434185d13"), __S("789518056c527958"), __S("16cc91b6f80d8e81b633"), __S("b5040b67713423f7"), __S("533b851807195450b0"), __S("f172fec94f20e2b83b"),
    } },
    { name = __S("8faa787a7d338b208a8d2497"),  color = Color3.fromRGB(74, 222, 128), fruits = {
        __S("2de1f22b9f83fecd97"), __S("cc196bdc8b78423726b7"), __S("6a50e58d14ac77"), __S("08885f3efadc6d18"), __S("a6bfd8efba509946"), __S("44f752a095c403b88fb438"), __S("e32ecc512707e098"), __S("81664602a25bc543099d"), __S("1f9dbfb314ea19aba35a"), __S("bdd539645a2f586ffd45ad"),
    } },
    { name = __S("5c0cb3153075da7b"),      color = Color3.fromRGB(56, 189, 248), fruits = {
        __S("fa442cc66420d29f7e"), __S("987ba677ca346eac59"), __S("36b320285e18203b61"), __S("d4ea99d940b2a0b289"), __S("7322138a011f77cfb4d1"), __S("11598d3b8867ef40"), __S("af9106ec5990809f5c5b"), __S("4dc8809d23054aa07b"), __S("ebfffa4ee507e9"), __S("8a3773ffe91b961489db"),
    } },
    { name = __S("286eedb090918b871eef476dfe"), color = Color3.fromRGB(250, 204, 21), fruits = {
        __S("c6a6676194a14ff264e439"), __S("64dde1129d6df318bea3"), __S("03155ac317c4774478d3"), __S("a14cd4746542d207"), __S("3f844e25e738b7c442c62764"), __S("ddbbc7d6f1cafc366dc8cb"),
    } },
    { name = __S("7bf34187ebaecc683612967e"),  color = Color3.fromRGB(244, 114, 182), fruits = {
        __S("1a2abb38132528156360ec"), __S("b86234e90227da6991"), __S("5699ae9a9b7557ac22"), __S("f4d1284b14a594715997"), __S("9308a1fcd1a7393f04"), __S("31401bad147ddbcd0bca71"), __S("cf77955ef70007"),
        __S("6daf0f0f7bb786452a15"), __S("0be688c013ee05dfcbab33"), __S("aa1e0271201224e9"), __S("48557c22c1b7ac71363973"), __S("e68cf5d38574a7ed6c26"), __S("84c46f849a158dbff0b0c4a5312ea18a6e"), __S("22fbe935ff2aa61144bf9bb744d2dc9385"),
    } },
}

local FRUITS_LIST = {}
local FRUIT_RARITY_OF = {}
for _, tier in ipairs(FRUIT_RARITY) do
    for _, fName in ipairs(tier.fruits) do
        table.insert(FRUITS_LIST, fName)
        FRUIT_RARITY_OF[fName] = tier
    end
end
                                                                            
FRUIT_RARITY_OF[__S("c13362e6356c857c8678")] = FRUIT_RARITY_OF[__S("5f6adc97cfbe9dd316e0d06130280df691")] or FRUIT_RARITY_OF[__S("fda2564810a405760fdfc554")]
FRUIT_RARITY_OF[__S("9bd9cff9ee872543aea5d3157fb0")] = FRUIT_RARITY_OF[__S("3a1149aa7cd62123c1")]
FRUIT_RARITY_OF[__S("d848c35b410ef38c2f81973edd8fe3a5cb")] = FRUIT_RARITY_OF[__S("76803d0c573cd592824f4e")]
                                                                                
                                                                               
FRUIT_RARITY_OF[__S("14b7b6bd6130c78703ce49271037")]        = FRUIT_RARITY_OF[__S("b2ef306ebdd0c56002")]
FRUIT_RARITY_OF[__S("5126aa1fd9b87ec1f307d5e7a34ca12d6d")]     = FRUIT_RARITY_OF[__S("ef5e23d0463aad1768c35c")]
FRUIT_RARITY_OF[__S("8d959d81a0574ee50bdd86e390e484fedf")]     = FRUIT_RARITY_OF[__S("2bcd1732009f0b6bfa")]
FRUIT_RARITY_OF[__S("ca0490e3563b1df4a05978cc29a7cc8befbf7dbe")]  = FRUIT_RARITY_OF[__S("683c0a94112a1931b720")]
FRUIT_RARITY_OF[__S("067384456be3fa5e073ab359d23aefa4401f1cd237")] = FRUIT_RARITY_OF[__S("a4aafdf6bb1f27e5653b3f")]
FRUIT_RARITY_OF[__S("42e277a77ef998a40d49cd675803a2")]       = FRUIT_RARITY_OF[__S("e119f158b8ba7e93")]
FRUIT_RARITY_OF[__S("7f516b0970de4c464950301698978692a081e4")]   = FRUIT_RARITY_OF[__S("1d88e4bad888e6154e4d")]
table.sort(FRUITS_LIST)

local function getFruitTier(fruitName)
    if not fruitName then return { name = __S("bbc05e6b98effa627399e5"), color = Color3.fromRGB(167, 139, 250) } end
    local clean = tostring(fruitName):gsub(__S("59f7d81c8640582008a9"), ""):gsub(__S("f82f51cd6050a06bda"), "")
    clean = clean:gsub(__S("9666cb7ee45220c1"), ""):gsub(__S("349e452f57d62f01"), "")
                                                                        
    local exact = FRUIT_RARITY_OF[clean]
    if exact then return exact end
    for name, tier in pairs(FRUIT_RARITY_OF) do
        if clean:find(name, 1, true) then return tier end
    end
    return { name = __S("d2d5bee0b158e2d50426ee"), color = Color3.fromRGB(167, 139, 250) }
end

local FRUIT_STORE_CODES = {}
for _, fName in ipairs(FRUITS_LIST) do
    FRUIT_STORE_CODES[fName] = fName .. __S("710d389173") .. fName
end

local RAID_CHIPS = {
    __S("0f44b24202a1a11665"), __S("ad7c2bf3fb4eab"), __S("4bb3a5a496cef2cd14"), __S("e9eb1f55b92c173b42"), __S("8822990623824e3b"), __S("265a12b7c202631f223a"),
    __S("c4918c687410f3acad3c"), __S("62c90619d111d87179"), __S("01007fca34cb0726bb0c"), __S("9f37f97bc4091f24"), __S("3d6f732cd995534de942c8"), __S("dba6ecdde71c3ef316"),
}

                                                                                     
                                                               
local FIGHTING_STYLES = {
    { name = __S("79de668e6a8c3f123d89"),          remote = __S("1815e03fb440209be3aa733114"),         tier = __S("b64d59f03f52e2d9a8763b1c8b38"),   tool = __S("5484d3a1baf83dc60246") },
    { name = __S("f2bc4d52b80a59a97f51617d090b8e0b5b1157"), remote = __S("90f3c703086f4bfc9b71cc54a0f4dafe6c6d330470"), tier = __S("2f2b40b43fbcfa6922db393a6f"),   tool = __S("cd62ba657357fa983065cc9347c90b05d0efee") },
    { name = __S("6b9a34169809d2e30372bab980"),       remote = __S("09d1adc7d1fe10336aef2f9a08568f"),      tier = __S("a80927783d49"),           tool = __S("4640a129394864db48642d4d87") },
    { name = __S("e4781ada6ea6d223875186"),         remote = __S("82af948b56b3d8cbf82386abc153"),       tier = __S("20e70e3c7a31"),           tool = __S("bf1e87edd9a989ef3be06d") },
    { name = __S("5d56019eea05f210fad7e2e41a736d9a967b"),  remote = __S("fb8d7b4fdf18f539ebfe18d87c3d56b8953d8193"), tier = __S("99c4f500a431"),           tool = __S("37fc6eb162cb140fba85659b9ee042ebb104") },
    { name = __S("d633e862196a35431d706d14ba004d231b"),   remote = __S("746b6213a5584ebe328e6c2a5bf1b4f3b8eb02"),  tier = __S("12a2dbc45fb2"),           tool = __S("b0da5575eb55fa2631396d79bf867f6b49") },
    { name = __S("4f11cf268f7d19fd008f4d35b16a"),      remote = __S("ed4948d77c0d551815e6b1a8b3abfcef6c"),    tier = __S("8b80c2883614"),           tool = __S("29b83c39b562ec851328569ddf9a") },
    { name = __S("c7efb5ea6753b45bfe2d69540fa2"),      remote = __S("66272f9b134b273abd9bde4de2b6f121"),     tier = __S("045ea94c413b"),           tool = __S("a29622fdfda8dc2f28d5beb085e5") },
    { name = __S("40cd9cae1150ac7c0183e49ed4be956915979e"), remote = __S("df05165ffa3d59031e331da6d5da8e52cd0e7ec5b2"),tier = __S("7d3c9010394a"),           tool = __S("1b7409c154efa9c9cfb00173c3e3a3333cba13") },
    { name = __S("b9ab8372d53d43f02c1bba952fed3e87cc"),   remote = __S("57e2fd2342ef1eb534b591f64963076563efd9"),  tier = __S("f61a76d4620f"),           tool = __S("9451f08540e96f99f94cc1e59cdea4a5db") },
    { name = __S("32896a36b501709da3396602dbee476a"),    remote = __S("d0c0e3e7db5d6f067065813394727483d0ae"),   tier = __S("6ef85d98cbd5"),           tool = __S("0d2fd749ae6de857d77c55968e6f387d") },
    { name = __S("ab6750fac17e297a01d47a16"),        remote = __S("499ecaab4cb0ffcf8671725523d2eb"),      tier = __S("e7d6445ce469a8a6d5be6a37f660935fa1"), tool = __S("860dbe0dccda7ba90f63da0e") },
    { name = __S("244537be5414049a62f59dc9c4a2ad81"),    remote = __S("c27cb16fe5976f315db2f1742f9b5d0d4e66"),   tier = __S("60b42b209e3acfd54d3bf03f0fa2b59b01"), tool = __S("feeba4d19a60bd3194b0faec61a3ad0d") },
}

local FIGHTING_STYLE_TOOLS   = {}                                                          
local FIGHTING_STYLE_REMOTES = {}                                           
local FIGHTING_STYLE_ORDER   = {}                     

for _, style in ipairs(FIGHTING_STYLES) do
    FIGHTING_STYLE_TOOLS[style.name:lower()] = style.name
    FIGHTING_STYLE_TOOLS[style.tool:lower()] = style.name
    FIGHTING_STYLE_TOOLS[style.name:lower():gsub(__S("9d231e82be6a"), "")] = style.name
    FIGHTING_STYLE_TOOLS[style.tool:lower():gsub(__S("3b5a98339857"), "")] = style.name
    FIGHTING_STYLE_REMOTES[style.name] = style.remote
    table.insert(FIGHTING_STYLE_ORDER, string.format(__S("d99211e4763fd698338ee178"), style.name, style.tier))
end

                                                                                 
local FIGHTING_STYLE_TIPS = {
    [__S("77c98b95a57c828614")] = true, [__S("1601054634f76cc6ab3d06403711e809cc3c")] = true, [__S("b4387ef7f737dbe534")] = true, [__S("526ff8a8d62647f000b6")] = true,
    [__S("f0a77259ad9cc197e5015e6c75")] = true, [__S("8edeec0a606eff3f8ad3a1")] = true, [__S("2d1665bb6da5de268c8b6f0439a5f6e9fb5e")] = true, [__S("cb4ddf6cd8b3c6dbc2f4fa1f03527be30c")] = true,
    [__S("6985591dea5e4933f82ecf5d1df8c4")] = true, [__S("07bcd2cecfd5f40275db445b8714")] = true, [__S("a5f44c7f6641eb06bbc78c85fcf5")] = true, [__S("442bc630f5ed3d53dc3b028d2fa64547376c16")] = true,
    [__S("e2633fe18b760cc58b3b1fc9aa9456353b")] = true, [__S("809ab992e26104fe6d67e26023c71534")] = true, [__S("1ed23343b9a6843b51bbeaa3")] = true, [__S("bd09acf42c16590d437c642a726a6cc2")] = true,
    [__S("5b4126a5fdf9ec41275bae9a29")] = true, [__S("f978a05667a6d876")] = false,
}

                                                                                     
local SWORD_KEYWORDS = {
    __S("97b01a07ecc2d8a7d6"), __S("35e793b8123cacd2eb"), __S("d41f0d69c310d929e8"), __S("7256871a2b26553ed36c"), __S("108e00cbe32690d225d539"), __S("aec57a7cea090a1942c0"), __S("4cfcf42d45bfad212f1faa"), __S("eb346ddeca2c1e6240"),
    __S("896be78f6a59122970f7"), __S("27a3614041a33ce9"), __S("c5dadaf1aa68e738"), __S("641254a2a5bfc16ae0ec9eff57"), __S("0249ce53b6f496910ba22d037155"), __S("a081480434b729c1"), __S("3eb8c1b5d381f9"), __S("dcf03b66db5445a8"), __S("7b27b51711301d687b42"), __S("195f2ec899d2d5e4c942"),
}
local GUN_KEYWORDS = {
    __S("b796a879e6b74508113ffc2792"), __S("55ce222a69642c6e5818b9b4bc"), __S("f4059bdb8799f0b1128a"), __S("923d158cf8a5e3fcd1"), __S("30748f3d165c5d2a577851"), __S("ceac08ee9b3aacd0e4c3"), __S("6ce3829f57327190339a"), __S("0b1afc506be4aa648404df"), __S("a9527601af7a79"),
}
local FRUIT_KEYWORDS = { __S("4789efb24b8b15b849"), __S("e5c16963d141c26829"), __S("83f8e31492a0dc4ff79c6b"), __S("22305cc555bad5bc7414"), __S("c067d6760e35c931782ff9"), __S("5e9f50275cae41c0ce"), __S("fcd6c9d88d24713abf43bb"), __S("9b0e4389854257ec2607") }

local function isMeleeTool(tool)
    if not tool or not tool:IsA(__S("3945bd3a7f4c180d")) then return false end
    local tip = tostring(tool.ToolTip or ""):lower()
    if FIGHTING_STYLE_TIPS[tip] then return true end
    if FIGHTING_STYLE_TOOLS[tool.Name:lower()] then return true end
    if FIGHTING_STYLE_TOOLS[tool.Name:lower():gsub(__S("d77d36eb7e6b"), "")] then return true end
    local attr = tool:GetAttribute(__S("75b4b09cf8a779529db46c350e61")) or tool:GetAttribute(__S("13ec2a4dab6729ba")) or tool:GetAttribute(__S("b223a3fe838713164f"))
    if type(attr) == __S("505b1daf2b401f7f90ad") and FIGHTING_STYLE_TIPS[attr:lower()] then return true end
    return false
end

local function toolMatchesCategory(tool, weaponType)
    if not tool or not tool:IsA(__S("ee929760ebc88c72")) then return false end
    local tip = tostring(tool.ToolTip or ""):lower()
    local name = tool.Name:lower()
    local want = tostring(weaponType or __S("8cca111188fd312f9d")):lower()

    if want == __S("2b018ac243d9c56458") then
        return isMeleeTool(tool)
    elseif want == __S("c9390473db2f11496c") then
        if tip == __S("67707e24cde47a1717") or tip == __S("05a7f7d56881df43d613") then return true end
        if tool:GetAttribute(__S("a3df718618f90db20d645d")) then return true end
        for _, kw in ipairs(SWORD_KEYWORDS) do if name:find(kw, 1, true) then return true end end
        return false
    elseif want == __S("4216eb37085053") or want == __S("e04e64e8c600287d") then
        if tip == __S("7e85de99158260") or tip == __S("1cbd584af782b473") then return true end
        if tool:GetAttribute(__S("baf4d1fb175708b689")) then return true end
        for _, kw in ipairs(GUN_KEYWORDS) do if name:find(kw, 1, true) then return true end end
        return false
    else              
        if tip == __S("592c4bace2a29d6eb1b6dfdee1ca") or tip == __S("f763c55dff14a82a66") then return true end
        if tool:GetAttribute(__S("959b3f0e1ad0da9f9c85fc")) or tool:GetAttribute(__S("33d2b8bf32ec935b7bc63fa5f8812630")) then return true end
        for _, kw in ipairs(FRUIT_KEYWORDS) do if name:find(kw, 1, true) then return true end end
        return false
    end
end

local BOSSES_BY_SEA = {
    [1] = {
        __S("d20a327046fe5e6edb7ad38b689d8f7f69c4d8c5"), __S("7041ac21e13eb261f5"), __S("0e7925d28a8dff3e"), __S("acb09f830e626b7365fbb77fe3f7"), __S("4ae81934e52db0abedc4f6339cc8558e"),
        __S("e91f92e5970b426bf649474f2e5e8f1f"), __S("87570c9623ff901983f7"), __S("258e864727c89005d91298ce03df9e27"), __S("c3c5fff81657d6a9"), __S("61fd79a9201d5e5c4bba8d2e5c94076520"),
        __S("0034f35a9341ab68e3ff7b2f7da75831"), __S("9e6c6d0b1a761bb8cd52"), __S("3ca3e6bc12b4cd33383212dafad930"), __S("dadb606d8501265008b7"),
    },
    [2] = {
        __S("7912da1eb2580ddc08640c"), __S("174a53cfdccaa6928660"), __S("b581cd80de506e6190bf"), __S("53b947311ade732b1ce0ee40"), __S("f1f0c0e2c72924ce94adfee560351b2fff"),
        __S("90283a93ad49a370626db4e665e193ffc2f9"), __S("2e5fb4448bcc4eb1f1b8b710d6"), __S("cc972df50e6adf081e"), __S("6acea7a69aeff19bb528152a9692540e5cc06d24d8f22213"), __S("09062157b54a2349d7cfd4ec2bd72f"),
    },
    [3] = {
        __S("a73d9b08b5cbe773ca"), __S("457514b90020f16cbf659f57f571edb6"), __S("e3ac8e6a511d32f126fcc80af53242d9"), __S("81e4081b2b3a898ce44d355d6530ad294ca2309e"),
        __S("201b81cc3f2c16e36e9b98d4e60f129b2ce8d02a"), __S("be52fb7dcf389de7fe2c"), __S("5c8a752e4aab23a744044e42412177"), __S("fac1eedf51292377a10e17dc853a"),
        __S("98f9689086eebebd06d0490bb43dbe"), __S("3730e24119a6ec0d894dca78ba4f"), __S("d5685bf28b61958095dc117cd59073991a74ba683aa27c"), __S("739fd5a3a2bab966eccb792d649b894d4ab9d117ac0095"),
    },
}

local ISLAND_TELEPORTS = {
    [1] = {
        [__S("11d74f5459fb9e00fe6e253608326d40725e4b12712abf9877")] = CFrame.new(1071, 16, 1426),
        [__S("b00ec905818921a16f1981f5775d66f244d8902bdad37b8da4")] = CFrame.new(-2573, 7, 2046),
        [__S("4e4642b633d4c00a72cbd1017cb415")]           = CFrame.new(-655, 8, 1436),
        [__S("ec7dbc673522183f0f5f")]                = CFrame.new(-1612, 37, 149),
        [__S("8ab5361813f7bb271c9808b1a7844bac1707")]        = CFrame.new(-1181, 5, 3803),
        [__S("28ecafc967c3943c4de4")]                = CFrame.new(944, 21, 4373),
        [__S("c724297ad9c50309274a72a133b2b19df7dc")]        = CFrame.new(1347, 105, -1319),
        [__S("655ba32b7975224b3201e28a31b7647120058e")]       = CFrame.new(-4914, 51, 4281),
        [__S("03931cdc94249ebe5c39894eb05133a8e189")]        = CFrame.new(-4869, 733, -2667),
        [__S("a1ca968d55997229119d53c10a65d8a8a078")]        = CFrame.new(-7894, 5547, -380),
        [__S("4002103eecfa0fba3bd9")]                = CFrame.new(4875, 6, 734),
        [__S("de3989ef8e1db673da6de84a9b")]             = CFrame.new(-1427, 7, -2792),
        [__S("7c7103a0afcd148ba607230cb4b3c9513a")]         = CFrame.new(-5247, 13, 8504),
        [__S("1aa87d5185e7d3d177d3db41ad6548f4d25d0f")]       = CFrame.new(61163, 12, 1819),
        [__S("b8dff702fb4fe02573e8c607f7e2ba2563")]         = CFrame.new(5127, 60, 4105),
    },
    [2] = {
        [__S("571770b3184bd183f1c88b2da10a907bd2acd2")]       = CFrame.new(-394, 118, 1245),
        [__S("f54eea64864e1419")]                  = CFrame.new(-380, 77, 255),
        [__S("938664153acd8054ffdb3c50856d65595349")]        = CFrame.new(-390, 332, 673),
        [__S("31bdddc6038572b795667e79a48a")]            = CFrame.new(-2448, 73, -3210),
        [__S("cff55777fdd6339c7477f40c62")]             = CFrame.new(-5411, 49, -721),
        [__S("6e2cd128ffb62d4c027c02fa72da8d6bf6")]         = CFrame.new(753, 408, -5274),
        [__S("0c644ad9ceeca7e790164d4040266db9c0df5ec4c5be38")]   = CFrame.new(-6475, 250, -4490),
        [__S("aa9bc48a2c3791c2d67ca018c686dd")]           = CFrame.new(923, 125, 32885),
        [__S("48d33e3bd80544e06150d244f48b")]            = CFrame.new(6148, 294, -6741),
        [__S("e70ab7ecb16ae5a0cbc97d4567abe5101c10c81c")]      = CFrame.new(-3032, 317, -10075),
        [__S("8542319dc14b42ca07658c5fdbf6")]            = CFrame.new(3780, 23, -3499),
    },
    [3] = {
        [__S("2379ab4ed66fbc8feee91f7f21")]             = CFrame.new(-290, 44, 5368),
        [__S("c1b124ff209bf79206fde61d3dd1000567281ee0ab54bd")]   = CFrame.new(5749, 611, -276),
        [__S("5fe89eb008fdb10d633dfdc722fe")]            = CFrame.new(2681, 1682, -7190),
        [__S("fe20186151288df9da7373b39bb4e9b08b9a24")]       = CFrame.new(-13274, 532, -7579),
        [__S("9c57921255ec6e3ef62c1b502d434581adad8d04")]      = CFrame.new(-12548, 337, -7481),
        [__S("3a8f0bc37bc17fc7ba09392e80621eda814baf9a89")]     = CFrame.new(-5075, 314, -3150),
        [__S("d8c685740801e1a225f6cb81ace9482a277e")]        = CFrame.new(-9515, 142, 5535),
        [__S("76fdff25dadb74484b60c9227c7658b679f0155443888ead")]  = CFrame.new(-1884, 19, -11666),
        [__S("153578d6b57f0858cc11ee2d7657d335")]          = CFrame.new(-16218, 9, 445),
        [__S("b36cf2876df1a7da26bfae2903d17bb823d8")]        = CFrame.new(28286, 14897, 102),
    },
}

                                                                              
                                                                           
local ISLAND_TELEPORTS_ALL = {}
for sea = 1, 3 do
    local list = ISLAND_TELEPORTS[sea]
    if list then
        for islandName, cf in pairs(list) do
            ISLAND_TELEPORTS_ALL[string.format(__S("51a46c385a7d6ff5269b5c08bc4b"), sea, islandName)] = cf
        end
    end
end

                                                                                 
                                                                              
                                   
local function resolveIslandCFrame(islandName)
    if not islandName or islandName == "" then return nil end
    local roots = { Workspace }
    for _, folderName in ipairs({ __S("efdbe5e957d165"), __S("8e135f9a636d3898395e20"), __S("2c4ad94bf687d981bbcea6ed37"), __S("ca8252fc8507dda4b2") }) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then table.insert(roots, folder) end
    end
    local wanted = { islandName, islandName .. __S("68b9ccad7bf5de5316f6ed"), islandName .. __S("06f1465e6ad62f1db270") }
    for _, root in ipairs(roots) do
        for _, candidate in ipairs(wanted) do
            local model = root:FindFirstChild(candidate)
            if model and (model:IsA(__S("a528c00fb6a8b9ba8c")) or model:IsA(__S("436039c02e26c0951f9319e3"))) then
                local ok, cf = pcall(function()
                    local boxCF, size = model:GetBoundingBox()
                    return CFrame.new(boxCF.Position + Vector3.new(0, size.Y / 2 + 14, 0))
                end)
                if ok and cf then return cf end
            end
        end
    end
    return nil
end

local ISLAND_LIST_ALL = {}
for label in pairs(ISLAND_TELEPORTS_ALL) do table.insert(ISLAND_LIST_ALL, label) end
table.sort(ISLAND_LIST_ALL)

local BOSS_LIST_ALL = {}
for sea = 1, 3 do
    for _, bossName in ipairs(BOSSES_BY_SEA[sea] or {}) do
        table.insert(BOSS_LIST_ALL, string.format(__S("e197b3717ebf77d6152edf136ce6"), sea, bossName))
    end
end

                                                                             
local SEA_EVENT_SIGNATURES = {
    { Name = __S("7fcf2d22a3da534aa441c8c2d4d65693"),      Keys = { __S("1e06a6d3699d13feefdfa24f31a1faf7") },                 Color = Color3.fromRGB(239, 68, 68) },
    { Name = __S("bc3e2084bfc71f19cee3c9d525"),         Keys = { __S("5a759a3540367aa6d197dbb85e") },                    Color = Color3.fromRGB(56, 189, 248) },
    { Name = __S("f8ad13e61d08b18c3afa31d909"),         Keys = { __S("96e48d97cfcfd10c4fe5b4b3ae") },                    Color = Color3.fromRGB(248, 113, 113) },
    { Name = __S("351c0748b9d0956f7610"),            Keys = { __S("d35380f9d4af54faa646") },                        Color = Color3.fromRGB(168, 85, 247) },
    { Name = __S("718afaaa280fbf251d95b9846e1a5c29f2"),     Keys = { __S("0fc2745b72d06675250a") },                        Color = Color3.fromRGB(244, 114, 182) },
    { Name = __S("adf9ee0c5b4668afcd7e5d01417c611476a5"),    Keys = { __S("4c3167bd75da5ebd5ff7bafb8cfec3fec9e9"), __S("ea68e16ea70e70ae3669b69de662832bbab2") }, Color = Color3.fromRGB(250, 204, 21) },
    { Name = __S("88a05b1f6ea1036ed1f8bfbeb851a0f6bf19de326550"),Keys = { __S("26d7d4d046fa09b4a5200903715b34") },                   Color = Color3.fromRGB(74, 222, 128) },
    { Name = __S("c50f4e816d112570f1868159361b16d1b219e49e"),  Keys = { __S("6346c832313fe224e558e4ce948020") },                   Color = Color3.fromRGB(148, 163, 184) },
    { Name = __S("017e41e34fd6715af6da8cec047cf40d"),      Keys = { __S("9fb5bb947a96ffd76489021f965f"), __S("3ded35456ad90812bdcdf5727d4ab492") },    Color = Color3.fromRGB(136, 170, 203) },
    { Name = __S("dc24aef62277c165306af2e0fa40e61ae4"),     Keys = { __S("7a5c28a70a09ad97fa3f8e9d3a8a4bc32c") },                 Color = Color3.fromRGB(223, 181, 133) },
    { Name = __S("1893a258f6565ea0bef769c9e032a5173b100a8dea10"),Keys = { __S("b6cb1c0941a7e1f2bc1a"), __S("550295ba020d5200fdc9a20bc0") },           Color = Color3.fromRGB(125, 211, 252) },
}

local QUEST_DATABASE = {
    [1] = {
        {MinLv = 1,   MaxLv = 9,   Mob = __S("f33a0f6b421990e2fbed"),              Quest = __S("9171891cd7011431eabd166431063385"),      QNum = 1, QPos = CFrame.new(1059, 16, 1549),   MPos = CFrame.new(1145, 17, 1634)},
        {MinLv = 10,  MaxLv = 29,  Mob = __S("2fa902cdd8f1fbd87cdc"),              Quest = __S("cde07c7e2330b6fbf0a969dc708def"),       QNum = 1, QPos = CFrame.new(-1598, 36, 153),   MPos = CFrame.new(-1448, 50, 63)},
        {MinLv = 30,  MaxLv = 59,  Mob = __S("6c17f62fd69beb2e35ec"),              Quest = __S("0a4f6fe05b35a1f20ff8a3baef33f2"),       QNum = 1, QPos = CFrame.new(-1140, 4, 3829),   MPos = CFrame.new(-1201, 40, 3857)},
        {MinLv = 60,  MaxLv = 89,  Mob = __S("a886e9916ff91aed13cb228df18cbf2ce2"),       Quest = __S("46be63424dd1fd3c1ad3a67de61f5f"),       QNum = 1, QPos = CFrame.new(894, 6, 4392),     MPos = CFrame.new(984, 16, 4417)},
        {MinLv = 90,  MaxLv = 119, Mob = __S("e4f5dcf3d51c49291cf6ec682bc609"),         Quest = __S("832d56a40b63eef3c1da62c027"),         QNum = 1, QPos = CFrame.new(1386, 87, -1298),  MPos = CFrame.new(1356, 106, -1328)},
        {MinLv = 120, MaxLv = 189, Mob = __S("2164d055e125b776f596a95e3f05d7923732803ac5df71"), Quest = __S("bf9c4a062548021934e8b2f2556cc1b0"),      QNum = 1, QPos = CFrame.new(-5039, 28, 4324),  MPos = CFrame.new(-4710, 16, 4296)},
        {MinLv = 190, MaxLv = 249, Mob = __S("5dd3c3b795ea6988448c3cb5"),            Quest = __S("fc0b3d688b20a0d39a18b3f5d7ab9c5ed3"),     QNum = 1, QPos = CFrame.new(5308, 2, 474),     MPos = CFrame.new(5098, 2, 474)},
        {MinLv = 250, MaxLv = 299, Mob = __S("9a42b7193dcfde4289ccc615e6629c69"),        Quest = __S("387a30cad8184aadf8ad1a61c64fa68f5298"),    QNum = 1, QPos = CFrame.new(-1580, 7, -2986),  MPos = CFrame.new(-1820, 51, -2740)},
        {MinLv = 300, MaxLv = 374, Mob = __S("d6b1aa7b49c9c383fd39c19dcbb6f32629cd5850"),    Quest = __S("74e9242c171009dad3a830e0a8b1"),        QNum = 1, QPos = CFrame.new(-5313, 12, 8515),  MPos = CFrame.new(-5411, 11, 8454)},
        {MinLv = 375, MaxLv = 449, Mob = __S("13209dddd61e48d238354238de24bf75e9965c"),     Quest = __S("b158178e5c8e51361afb000bb413890d"),      QNum = 1, QPos = CFrame.new(61122, 18, 1569),  MPos = CFrame.new(60878, 18, 1543)},
        {MinLv = 450, MaxLv = 624, Mob = __S("4f8f913fcc3ad46cc63abc09c644cd"),         Quest = __S("edc70af06f58e372ea1b29bb244ac58f"),      QNum = 1, QPos = CFrame.new(-4721, 845, -1954), MPos = CFrame.new(-4710, 845, -1927)},
        {MinLv = 625, MaxLv = 699, Mob = __S("8bfe84a1d3514beb3d785042e84047d512"),       Quest = __S("2a35fe524bd28f584e3903f80102fcf0cd"),     QNum = 1, QPos = CFrame.new(5259, 39, 4050),   MPos = CFrame.new(5551, 78, 3930)},
    },
    [2] = {
        {MinLv = 700,  MaxLv = 774,  Mob = __S("c86d780347c1cd2e06a9"),            Quest = __S("66a4f1b41c431e5b1912716745e8"),        QNum = 1, QPos = CFrame.new(-429, 72, 1836),   MPos = CFrame.new(-728, 52, 2345)},
        {MinLv = 775,  MaxLv = 874,  Mob = __S("04dc6b654ebb4925ede28721c8f5eb"),       Quest = __S("a313e5164fc01c62ced66ab87df5"),        QNum = 1, QPos = CFrame.new(638, 73, 918),     MPos = CFrame.new(1068, 137, 1322)},
        {MinLv = 875,  MaxLv = 949,  Mob = __S("414b5ec703d843a252c2a331254f2211bb07541829"), Quest = __S("df82d878b31f4c9c8ef23c31663525ff"),      QNum = 1, QPos = CFrame.new(-2440, 73, -3216), MPos = CFrame.new(-2821, 73, -3070)},
        {MinLv = 950,  MaxLv = 999,  Mob = __S("7dba52294c81687d9114"),            Quest = __S("1bf1cbda25ebda3a5c5246a19edd53"),       QNum = 1, QPos = CFrame.new(-5497, 48, -795),  MPos = CFrame.new(-5657, 173, -601)},
        {MinLv = 1000, MaxLv = 1099, Mob = __S("ba29458b74217e52c5cde54a8dece6f9"),      Quest = __S("5860bf3c4c321adc3a5782862689869634cd1df723"), QNum = 1, QPos = CFrame.new(609, 400, -5372),  MPos = CFrame.new(549, 427, -5563)},
        {MinLv = 1100, MaxLv = 1249, Mob = __S("f69838ed838e24d10381a9aad7f8800d9fa046"),   Quest = __S("94cfb29e994491f7504ce618ba399125"),      QNum = 1, QPos = CFrame.new(-6064, 15, -4902), MPos = CFrame.new(-5707, 15, -4513)},
        {MinLv = 1250, MaxLv = 1349, Mob = __S("33072c4f5b0de190fabf49801348a0e7d5"),     Quest = __S("d13ea6004cb3a127599b79e30630"),        QNum = 1, QPos = CFrame.new(1037, 125, 32911), MPos = CFrame.new(1212, 150, 33059)},
        {MinLv = 1350, MaxLv = 1424, Mob = __S("6f761fb190d89b2db4ad83fa63592f4aac3e"),    Quest = __S("0dad996224ee56f10323f4e6953e"),        QNum = 1, QPos = CFrame.new(5667, 26, -6486),  MPos = CFrame.new(5966, 62, -6179)},
        {MinLv = 1425, MaxLv = 1499, Mob = __S("abe5131383fc604234d17d637b59b4"),       Quest = __S("4a1c8cc480f18083ea52bf34426ee410cbd9"),    QNum = 1, QPos = CFrame.new(-3054, 236, -10142), MPos = CFrame.new(-3028, 64, -9775)},
    },
    [3] = {
        {MinLv = 1500, MaxLv = 1574, Mob = __S("e85406756806123220ca51e7633ae0a62397a0383ac4"), Quest = __S("868b802611c8afda3bf8ed2670d23787673d8d"),  QNum = 1, QPos = CFrame.new(-290, 44, 5581),   MPos = CFrame.new(-246, 55, 5564)},
        {MinLv = 1575, MaxLv = 1699, Mob = __S("24c2f9d70f73e286aabb804d1c48c52c84e403f5a90f7b"),Quest = __S("c2fa7388298f1412db467b7fe4a938ace87a3f"),  QNum = 1, QPos = CFrame.new(6737, 127, -712),  MPos = CFrame.new(6709, 55, -1104)},
        {MinLv = 1700, MaxLv = 1774, Mob = __S("6131ed397f256c9eda6eca707fd1f75321194e62"),   Quest = __S("ff6966ea7dfc51e3da365d77545eb8a8e21ded89"), QNum = 1, QPos = CFrame.new(2180, 29, -6738),  MPos = CFrame.new(2286, 73, -7159)},
        {MinLv = 1775, MaxLv = 1974, Mob = __S("9da0e09b44ee9769afc9b302855727fe65fc"),     Quest = __S("3bd85a4cc09d5ebe0cccb611039391043fe9d1e874"),QNum = 1, QPos = CFrame.new(-10581, 331, -8761),MPos = CFrame.new(-10407, 331, -8368)},
        {MinLv = 1975, MaxLv = 2074, Mob = __S("da0fd3fd37284d9a43ba4dc471d80811f2f653"),    Quest = __S("78474daeffd8966ff33a06977a171b2fcf"),    QNum = 1, QPos = CFrame.new(-9479, 141, 5566), MPos = CFrame.new(-8763, 165, 6159)},
        {MinLv = 2075, MaxLv = 2449, Mob = __S("167ec75ff6ef2960c3ca52aa445b733b5b78"),     Quest = __S("b4b6411059f7719054d5859741f3"),       QNum = 1, QPos = CFrame.new(-2021, 38, -12028),MPos = CFrame.new(-2374, 38, -12125)},
        {MinLv = 2450, MaxLv = 2650, Mob = __S("52edbac1283d9bde20b43c215f9d59471eda82fd1ff5"), Quest = __S("f1253472139ac236cc757a1f5dc4"),       QNum = 2, QPos = CFrame.new(-16548, 56, 1051), MPos = CFrame.new(-16345, 35, 1002)},
    },
}

local ACTIVE_CODES = {
    __S("8f5cae23c40ec990dd7c92adfa9e"), __S("2d9427d450be9617a6d0d962a836e58b5dad39"), __S("cbcba18513ae3b9216de33307861"), __S("6a031b36570eecf680189c795411"),
    __S("083a94e771bf9b1c814638dfb989c8"), __S("a6720e9805ca8ea673b66b97"), __S("44a98849f358b5cd"), __S("e2e101fa668fb4c40408a6872dc90c"), __S("81187bab7fe1623b35d9"),
    __S("1f4ff55c08ef7647bae1eeea74"), __S("bd876f0dad79d2cecd1b0508712260605d439acac6e4c1"), __S("5bbee8bef937dfa1b4b281bc2b04b22b4443f9bef7"),
    __S("f9f6626fa12cbd63ca67479f27064f6e72cd50"), __S("982ddc20271e9d24a8c95020a2b5fb57"), __S("366555d13ffdf727e8b7"), __S("d49ccf82e032b9a07c34758dc84ab1a4"),
    __S("72d44933d93ac01249248eca6ce9fb8d1c"), __S("110bc2e4fcdc0135298445956c17b0a4cbc8341f569d"), __S("af433c9509d777d0e187e0d7954b91"),
}

                                                                              
                                
                                                                              

Config = {
    AutoFarmLevel       = false,
    AutoFarmNearest     = false,
    AutoFarmBoss        = false,
    AutoFarmAllBosses   = false,
    AutoFarmChests      = false,
    SelectedWeaponType  = __S("4d7ab64632a3777b35"),
    SelectedBoss        = string.format(__S("ebb22ff7a2349a8786d67dd1e2fd"), CURRENT_SEA, BOSSES_BY_SEA[CURRENT_SEA][1]),
    FarmDistance        = 18,
    TweenSpeed          = 260,
    BringMobs           = true,
    FastAttack          = true,
    AutoBuso            = true,
    AutoKen             = false,
    AutoRaceV3          = false,

    AutoStatMelee       = false,
    AutoStatDefense     = false,
    AutoStatSword       = false,
    AutoStatGun         = false,
    AutoStatFruit       = false,
    StatPointsBatch     = 3,

    SelectedFruit       = __S("89e9a9a84dde96f317e0b7"),
    AutoSniperStock     = false,
    AutoGrabMapFruits   = false,
    AutoStoreFruits     = false,
    AutoRandomFruit     = false,
    SelectedRaidChip    = __S("28212359ba7aa8b9f5"),
    AutoBuyRaidChip     = false,
    AutoRaidAura        = false,
    AutoAwaken          = false,

    SelectedIsland      = ISLAND_LIST_ALL[1] or __S("c6589d0a7bebc682f83db7bbc25120"),
    SelectedFightingStyle = FIGHTING_STYLE_ORDER[1],

    ESPPlayers          = false,
    ESPFruits           = false,
    ESPChests           = false,
    ESPIslands          = false,
    ESPBosses           = false,
    ESPPlayerLoadout    = true,
    ESPFruitRarity      = true,
    ESPTracers          = false,

                    
    SelectedPlayer      = "",
    AutoKillSelected    = false,
    AutoKillPvP         = false,
    AimLock             = false,
    AimLockSmoothness   = 0.28,
    AimLockFOV          = 300,
    SpectatePlayer      = false,
    PlayerHitbox        = false,
    PlayerHitboxSize    = 14,
    IgnoreFriendsPvP    = true,
    PvPSkills           = true,
    KillAuraAllPvP      = true,
    KillAuraRange       = 95,
    PvPAttackInterval   = 0.08,                                                            
    PvPSkillInterval    = 0.4,                                            
    PvPAutoAim          = true,                                                       
    PvPHoverHeight      = 6,                                                    
    PvPTargetMode       = __S("649016bbd60332b80db571"),                                  
    PvPFallbackNearest  = true,                                                                                  
    ExpandAllPvPHitbox  = false,                                                              
    HitboxWholeModel    = true,                                                  
    BuddhaAwareCombat   = true,

                         
    HitboxMobs          = true,
    SafeHookMode        = true,
    HookEngine          = false,                                                                  
    UseVirtualInput     = true,                                                                    
                                                                                                      
                                                                                               
                                                                                         
    CoreGuiWatch        = true,                                                                  
    NoDiagnostics       = false,                                                                   
    DebugTrace          = true,                                                              
    IncrementalUIBuild  = true,                                                                 
    LogStepErrors       = true,                                                                    
    HookHitCount        = 0,
    FreezeMobAnimations = false,
    HitboxMobsSize      = 55,
    HitboxMobsRange     = 420,
    ShowHitboxVisual    = false,
    PvPTweenDistance    = 9,
    DashInterval        = 0.32,

                        
    FlyEnabled          = false,
    FlySpeed            = 60,
    FlyHoldSeconds      = 1.2,                                                                
    FlyHoverIdle        = true,                                               
    FlyParked           = false,                                                               
    FlyBypassMode       = true,
    FlyAntiVoid         = true,
    FlyZeroWalkSpeed    = true,
    FlyJoinAutopilot    = true,

                      
    FruitMagnet         = false,
    FruitMagnetRadius   = 600,
    AutoStoreRolled     = true,
    RolledFruitName     = "",
    FruitNotify         = true,                                                           

                       
    WalkOnWater         = false,
    InfiniteGeppo       = false,
    InfiniteEnergy      = false,
    NoDashCooldown      = false,
    MirageFinder        = false,
    SeaEventTracker     = false,
    AutoCollectDrops    = false,
    NoFallDamage        = true,
    ServerStatusHUD     = true,
    SovereignHakiAura   = true,

                                              
    AutoAttackAlways    = false,
    FastAttackDelay     = 0.02,
    AttackRange         = 65,
    AttackPlayers       = false,
    HitboxExpander      = true,
    BypassAntiCheat     = true,
    AntiStun            = true,
    AutoSkillComboZ     = false,
    AutoSkillComboX     = false,
    AutoSkillComboC     = false,
    AutoSkillComboV     = false,

    WalkSpeedEnabled    = false,
    WalkSpeedValue      = 75,
    JumpPowerEnabled    = false,
    JumpPowerValue      = 120,
    NoClip              = false,
    AntiAFK             = true,
    ShowWatermarkHUD    = true,
    PreferExternalFluent = false,                                             
                                                                                   

                                                                              
    GuardMode          = __S("02c7906c5e1978c3"),                                 
                                                                                           
                                                                                             
    LicenseKey         = "",                                                   
    LicenseKeys        = {},                                                           
    SealedEndpoint     = "",                                                           
                                                                                        
                                                                                    
    RequestWatermark   = true,                                                        
    TamperAuditSeconds = 30,                                                                
}

                                                        
                                     
                                               
                                                                                
                                           
if SharedEnv.SkillHubNoHooks == true then
    Config.SafeHookMode = false
    Config.BypassAntiCheat = false
    print(__S("a0ff0a1df82ce2050fbe29dcfb96b67d8d9e3585dd733dfdaa9f23281f9e484e24ee01227684579f73ae9db8dae6d1a053a7faaa0f1a06db4acf051eed8d0d8394d6da4d3e5122a982b1299e51d967"))
end

                                                                       
                                        
if SharedEnv.SkillHubNoEvidence == true then
    Config.NoDiagnostics = true
    Config.CoreGuiWatch = false
    print(__S("3f3683ce12fa6099d04cad4a1f31e3ce2220bb2aefb038e2ac495b453bd60f2564912d2081e7eeb91bf96eb499c6e206cc108aa53241c40dc3429999aaf63048b7838812df135a7b3d9c810e54607e17934d1ef92c1b"))
end

                                                        
                                            
if SharedEnv.SkillHubNoVirtualInput == true then
    Config.UseVirtualInput = false
    print(__S("dd6dfd7f853333c8175a61be7f0051a59848cab1e1e64872b9ec674c4dcaed30667f734a01d6a4ad1cda3dcd2c50b815ef0c92ca3cb25acc5999b86fe7e7e0942586551eeb4d5f90846d"))
end

                                                    
                                      
if SharedEnv.SkillHubSafeMode == true then
    Config.AutoFarmLevel = false
    Config.AutoFarmNearest = false
    Config.AutoFarmBoss = false
    Config.AutoFarmAllBosses = false
    Config.AutoAttackAlways = false
    Config.AutoKillSelected = false
    Config.AutoKillPvP = false
    Config.AimLock = false
    Config.PlayerHitbox = false
    Config.HitboxMobs = false
    Config.FruitMagnet = false
    Config.FlyEnabled = false
    Config.SeaEventTracker = false
    Config.MirageFinder = false
    print(__S("7ba57730eac998264aed941ade3afdc430a4211de262a2bb6482e66898a2192f9e396720e7a8ec25d3abc4c139852b420fd13995f839d06acaa52a2c856278db89bfb36234be6bc8316c88b39e06"))
end

                                                                             
                                             
                                         
if SharedEnv.SkillHubMinimalMode == true then
    SharedEnv.SkillHubNoVirtualInput = true
    SharedEnv.SkillHubNoHooks = true
    SharedEnv.SkillHubSafeMode = true
    SharedEnv.SkillHubNoEsp = true
    Config.UseVirtualInput = false
    Config.SafeHookMode = false
    Config.BypassAntiCheat = false
    print(__S("19dcf0e17ae96daa1ea1c41bac9d34e9fe1245138e7c7908c3fe4d0aa4006a532ea56ebe4b32d34a1e56dc6ff8216276504a19578bfb8588586dd4c434e8bb67dcdca7c8eb9806cea5da6e709aebdc7b9fa5f16af91b7fff0475"))
end

if SharedEnv.SkillHubNoEsp == true then
    Config.ESPPlayers = false
    Config.ESPFruits = false
    Config.ESPChests = false
    Config.ESPBosses = false
    Config.ESPIslands = false
    Config.ESPTracers = false
    Config.SeaEventTracker = false
    Config.MirageFinder = false
end

                                                                               
                                                                             
                                                                                  
                                                                    
                                                                               
                                                      
                                                  
local ActionTrace = { items = {} }
local TRACE_MAX = 8

local function trace(action)
    if Config.DebugTrace == false then return end
    table.insert(ActionTrace.items, string.format(__S("b8146a9234c32fbc522408ce1ab202"), tostring(action), os.clock()))
    while #ActionTrace.items > TRACE_MAX do table.remove(ActionTrace.items, 1) end
end

                                                                               
                                                                               
                                                                            
                                                                             
                                                                        
                                                                            
                                                                            
                                                                             
                                                                            
                                                                     
                                                                           
local SkillHubEvidence = {
    boot = os.clock(), log = {}, max = 12, names = {}, numeric = {},
    readable = true, report = nil, watch = nil, identity = nil,
}

do
    local LF = string.char(10)

    local function coreGuiService()
        local ok, gui = pcall(function() return game:GetService(__S("564be4432183c32859f91e")) end)
        if ok and gui then return gui end
        return nil
    end

    local function identitySample()
        local ok, tb = pcall(function()
            return select(2, xpcall(
                function() error(__S("f4835df47914d9b04ad4c92ba703a28b54689619228243227ec7d61b"), 0) end,
                function(err) return debug.traceback(err, 2) end))
        end)
        if not ok or type(tb) ~= __S("92bad7a5b14cf330f774") then return __S("30f251560f251d4bcc8caef245f6bd00adc7e2a45b3f5e8b8a308f017b04916a") end
        local first, second = string.match(tb, __S("cf29cb076b2d4b") .. LF .. __S("6d6144b87ef6ae") .. LF .. __S("0b98be690bc9c8") .. LF .. __S("a9d0381a4e53f2"))
        if not first then return __S("4807b1cb21485eac1cba29acdfd0a8325c9cb8b42d836d96bc58c122840aa087") end
        return first .. (second and (__S("e63f2b7c74b360c784") .. second) or "")
    end

    local function creatorNote()
        local ok, tb = pcall(function() return debug.traceback("", 2) end)
        if not ok or type(tb) ~= __S("8476a52db7d778885a6c") then return __S("22ae1ede90182be6ca4c4e451889cabaace7eb4129") end
        local frames = {}
        for line in string.gmatch(tb, __S("c0e5988f8e08") .. LF .. __S("5f1d1240f7e7")) do
            local clean = string.gsub(line, __S("fd548bf13a2b6bfd"), "")
            local skip = clean == "" or clean == __S("9b8c05a2ad4dd66687268e6157237c") or clean == __S("39c37f53f4de6af7a037553097")
                or string.sub(clean, 1, 3) == __S("d7faf90412a090")
                or string.find(clean, __S("763272b5146bfc4f84c64ff45e43fee5a9279a"), 1, true)
                or string.find(clean, __S("1469ec6677e65030f5de758dc086a6"), 1, true)
                or string.find(clean, __S("b2a1661785fa3fcc0ea63c6869fa5f00"), 1, true)
                or string.find(clean, __S("50d8dfc81ce7ef09681d717e8baff352542917"), 1, true)
            if not skip then
                table.insert(frames, clean)
                if #frames >= 2 then break end
            end
        end
        if #frames == 0 then return __S("ef105979c83cac28c34b87b08aa33475c1bacb9af9ed1c0d9959077b6a6b4f081a7727167e575fed8d3f22a6e7eeed6709725641641ff3ccbb") end
        return table.concat(frames, __S("8d47d32afb1daaa0a04fe7"))
    end

                                                                                
                                                                             
                                                                                
                                      
    local lastNote = -1e9
    local function coreGuiAdded(inst)
        local okName, name = pcall(function() return inst.Name end)
        if not okName or type(name) ~= __S("2b7f4cdbfaa33a0d7e92") then return end
        local okCls, cls = pcall(function() return inst.ClassName end)
        cls = okCls and tostring(cls) or __S("c9b6c68ce0")
        local isScript = (cls == __S("67ee403dba0bde8cd4a2") or cls == __S("0625b9ee6e51160a69b219d4605adf") or cls == __S("a45d339fc565224003f04ffe52a296f1"))
        local isNumeric = string.match(name, __S("4294ad50714ba537d2")) ~= nil
        if not (isScript or isNumeric) then return end
        local now = os.clock()
        if now - lastNote < 0.1 then return end
        lastNote = now
        local numeric = isNumeric and __S("e0cc2701d73fbd5ef8fce2ecffc70230cb41cfbff3ce517557c94e76913c05a2c3533c8d9bec7bd1eedb16") or ""
        table.insert(SkillHubEvidence.log, string.format(
            __S("7f03a0b2635b31e6926c9eee500ded921e7b2b8bce936f4afed15c6a49e692485fac674cc0f6e353"),
            now, isScript and __S("1d3b1a630bf18ddde0839e") or "", cls, name, numeric, creatorNote()))
        while #SkillHubEvidence.log > SkillHubEvidence.max do table.remove(SkillHubEvidence.log, 1) end
    end

    local function coreGuiWatcher()
        local gui = coreGuiService()
        if not gui then
            SkillHubEvidence.readable = false
            return
        end
        pcall(function()
            for _, child in ipairs(gui:GetChildren()) do
                local ok, n = pcall(function() return child.Name end)
                if ok then
                    n = tostring(n)
                    table.insert(SkillHubEvidence.names, n)
                    if string.match(n, __S("bb72941432e1a995f2")) then table.insert(SkillHubEvidence.numeric, n) end
                end
            end
        end)
        if Config.CoreGuiWatch == false or Config.NoDiagnostics == true then return end
        pcall(function()
            gui.DescendantAdded:Connect(function(inst) pcall(coreGuiAdded, inst) end)
        end)
    end

    SkillHubEvidence.identity = identitySample
    SkillHubEvidence.watch = coreGuiWatcher

                                                                               
                                                                          
    SkillHubEvidence.report = function(reason)
        if Config.NoDiagnostics == true then
            print(__S("59aa0dc517d8c827380ea1717be9ad692702a58c761dd5305e9bd80ee5616d45b5c212991e64ebf5abea7a4c5f4582d76e1e63f869d7f56d1342ba36b95f9ae6d3777964cb6248ecc3ac58dac25b13a0d4871e874201299af787b8468a"))
            return
        end
        print(__S("f7e187768a7ab384a826cfc8bf7308ff") .. tostring(reason))
        print(string.format(__S("96190127398d5f8f29ece82ffb8e8606879dff100de6c5b14d5b05e2a7a1f70d3535f4d20a712f7ab6ea2060ac900f6cee507de84a6aac7b2445b09ab879bd6132e02b1d0869a73c897600f06d27f456197a5aa86267c5a75af9bb10990ab596bed184d2c9f849509f7fc6cb9b747952cf02ed4eae8468"),
            os.clock() - SkillHubEvidence.boot, Config.UseVirtualInput and __S("34507ad8b26f") or __S("d287f489adcff0"),
            tostring(Config.HookEngine), identitySample()))
        print(__S("70bf6e3a66585f6d79ff27b2fbb402ca240ea1aa7bffad66993389e9b2f5c67acd"))
        if #ActionTrace.items == 0 then
            print(__S("0ef6e7eb0e67e7cca2d5de1c15ba4a38456531616eac2ef574fe64055d691bf340ccc663f928bc919781896ff649beb50e1e218ff571e6dc7909f7e93a2ea3c27fcc7cc9d91baa227f618a592f727d"))
        end
        for _, item in ipairs(ActionTrace.items) do print(__S("ad2e619c7294772ccf024ef80a120c") .. item) end
        if not SkillHubEvidence.readable then
            print(__S("4b65db4d0b8fe2e607647e06f6007fb5fb79af4d184ba6818995c06ac49a4fc03e369f8bd47dd6ae14aa5ca1b12c1d45f1926516d9d0c4"))
        elseif #SkillHubEvidence.numeric > 0 then
            print(__S("e99d54febf3c544b05cce10c6b3a6bcd23dfda04114b404af6c2d5b6304e62fa808cae8885d7a74c584fd69a01c691ead3f0f26cd0b8fa8d1ea5cc26a676423b721e0efc06469dc4a6cb303cb3b88cc432be26b6d457")
                .. table.concat(SkillHubEvidence.numeric, __S("87d4ceaf6319")))
        else
            print(string.format(__S("260c4860c09f442ec0910316efffdd41170b15770db8d9ab1882f14c8c606ae1afb61cad4445c17e8b51b7cf5e06c850927c09b718bb083239135333ab992485fd90bc0c82966bd96e496caea322bc513cd9"),
                #SkillHubEvidence.names))
        end
        if #SkillHubEvidence.log == 0 then
            print(__S("c443c21111c9b9733da3f73809d074e038138cd8290ccdee20be1376f2cb98ed8ac52c4ba6a35514a9cf87132b540c6c9debc6951add1bb13a45c5f78e407ef43c017eb44d410db27a"))
        else
            print(__S("627b3bc20347e748de0cb2482391a03929222375217fb8ba66ceb9c258ce2360cf7c579fd691ff"))
            for _, item in ipairs(SkillHubEvidence.log) do print(__S("00b2b573fd01f1b18dc814a43ce22d") .. item) end
        end
    end
end

do
    local ok, LogService = pcall(function() return game:GetService(__S("9eea2f248f2b0c35b5ed4344c436")) end)
    if ok and LogService then
        local lastDump = -1e9
        pcall(function()
            LogService.MessageOut:Connect(function(message, msgType)
                if type(message) ~= __S("3d21a8d5bb6d2079b1e3") then return end
                if string.sub(message, 1, 11) == __S("db59228619b842935a75513edb52fd") then return end                                 
                                                                            
                                                                                
                                                                                
                                                                                 
                local mentionsNil = string.find(message, __S("79909c37d2510b0ca83d6cbc6f"), 1, true) ~= nil
                if not (mentionsNil
                    or string.find(message, __S("17c815e851c7027fb77202"), 1, true)
                    or string.find(message, __S("b5ff8f9933f9aba186ae00"), 1, true)) then return end
                if msgType ~= Enum.MessageType.MessageError then return end
                local now = os.clock()
                if now - lastDump < 5 then return end
                lastDump = now
                print(__S("5437094a3e4e375905f09eca38098688820482c8dc71737620ca27ffa5abb71551cd3fc719d05127d4b00813de") .. message)
                pcall(function() SkillHubEvidence.report(__S("f26e82fbf494f7bb6229b18ad2f0d0ce68ff6ebd139ff7bd7052f9cc89e8de8d4d0e6566f199b7e52aecd8c7c9a2f482d5")) end)
            end)
        end)
    end
end

                                                                              
                                                                            
                                                                             
                                                                            
                                                     
do
    local LF = string.char(10)
    local ok, SC = pcall(function() return game:GetService(__S("90a5fcace7b260a4f3aa9516a4b8bd97a2")) end)
    if ok and SC then
        local lastSCError = -1e9
        pcall(function()
            SC.Error:Connect(function(message, stack, script)
                if type(message) ~= __S("2edd765de5e914e550de") then return end
                if not string.find(message, __S("cd14f00e6ac62f398753d37e06"), 1, true) then return end
                local now = os.clock()
                if now - lastSCError < 5 then return end
                lastSCError = now
                print(__S("6b4c69bf993f94e3b88241caa98d0a5fc10264be2c45575e880be17e00f12e9455582616") .. message)
                if type(stack) == __S("0983e37035ad1bb687ff") then
                    local shown = 0
                    for line in string.gmatch(stack, __S("a7bb5d21b560") .. LF .. __S("45f2d6d2dbc8")) do
                        if shown < 3 then print(__S("e42a50837e80f46cc77e55ec448981") .. line) end
                        shown = shown + 1
                    end
                end
                if script ~= nil then
                    local okFull, full = pcall(function() return script:GetFullName() end)
                    local okCls, cls  = pcall(function() return script.ClassName end)
                    local owned = okFull and tostring(full) or __S("8261ca3478")
                    print(string.format(__S("209943e557ac7186e66ac901cca2f9f1a70bebe30eb782676d0e3da33d011e06c4"), owned, okCls and tostring(cls) or __S("bed0bd96f8")))
                    if string.find(owned, __S("5d08374714a27bffb96856"), 1, true) then
                        print(__S("fb3fb0f848c5124f36932a77f02875dce3145039eb45b1c17b7c3b0628d0bfc51b17037f636633779b850d5e18d142eb7364058e7ae2676ebd8b0deb1200311a41ba"))
                    elseif string.find(owned, __S("99772aa9d5f0f1508d0944f7"), 1, true) then
                        print(__S("37aea45ae80fcb210dc8e7efdfa876e4654a6bbcc8d0c6286eb2e1769da93b726ef830a1862cac57e4a6ff00d086e97ea76915e8d392554c2f3fc942d55b8d025d53"))
                    end
                else
                    print(__S("d5e61e0b389d09ca76b229e5dd2347bc1486c42b9de32d0b8c44709361a2a3086e676fa0e73f0e5e90a413ba2d71b7cc8bb0976cf98179"))
                end
                pcall(function() SkillHubEvidence.report(__S("741d97bc8f3039918110a9fca7bd5a474a7526d85f7f7ac17eb61f7186f344d6d078")) end)
            end)
        end)
    end
end

                                                                               
                                                        
pcall(function() SkillHubEvidence.watch() end)
pcall(function()
    print(string.format(__S("1255116d2a27c3d03b9551659eee63810d4e54d45d50e1df03966e24e94fadf06f482137ab448de20781ad13b913b4faaf2a863f9b4cb5d64d61689d8727de915f03ca3c890d24c0bc884f742f44202110fdc49410"),
        #SkillHubEvidence.names,
        #SkillHubEvidence.numeric > 0 and table.concat(SkillHubEvidence.numeric, __S("b08c8b1ee567")) or __S("4ec404cfafc44d85")))
    print(__S("ecfb7e80ee1b7e2687a2a84c4cfee3bfee2514f3191757482c260820c4ccd45e91de822b585289a10fbc38ee35e328768e0647c9db5b6f030613a79d901fed6f3b6ceb764e63133384f685c5af09b835c87f") .. SkillHubEvidence.identity())
    print("[Skill Hub] console watchlist armed · LogService.MessageOut + ScriptContext.Error · every \"attempt to call a nil value\" now prints our action trace, the CoreGui snapshot and the failing instance name")
end)

                                                                              
                                                                              
                                                                      
                                                           
                                                                                
                                                                         
local NoTween = {
    Play   = function() end,
    Cancel = function() end,
    Pause  = function() end,
}

local function isInstanceValue(v)
    if typeof == nil then return type(v) == __S("8b32f8313edd9dd188451e78") or type(v) == __S("296a71e21df506b499") end
    return typeof(v) == __S("c7a1eb93f3f976dfb57b017e")
end

function SafeTween(inst, info, props)
    if not isInstanceValue(inst) or type(props) ~= __S("65d9654408be46881e") then return NoTween end
    local ok, tw = pcall(TweenService.Create, TweenService, inst, info, props)
    if ok and tw ~= nil then return tw end
    return NoTween
end

                                                                               
                                                                                
                                                                                 
                                                                                
                                                                                 
                                                                           
                                               
                                                                                      
                                                                              
local SyntheticInput = {
    userReady    = VirtualUser ~= nil,
    vimReady     = VirtualInputManager ~= nil,
    userFails    = 0,
    vimFails     = 0,
    lastClick    = 0,
    lastKey      = 0,
    warnedUser   = false,
    warnedVim    = false,
}

local function virtualClick(force)
    if Config.UseVirtualInput == false then return false end
    if not SyntheticInput.userReady then return false end

    local now = os.clock()
    if not force and (now - SyntheticInput.lastClick) < 0.12 then return false end
    SyntheticInput.lastClick = now

    local ok = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.zero)
        task.delay(0.03, function()
            SkillHubStep(__S("0410def524ee7e541a88d272aa3709030fe3bb6b1eb9d457056f308afee4"), function() VirtualUser:Button1Up(Vector2.zero) end)
        end)
    end)
    if not ok then
        SyntheticInput.userFails = SyntheticInput.userFails + 1
        if SyntheticInput.userFails >= 3 and not SyntheticInput.warnedUser then
            SyntheticInput.warnedUser = true
            SyntheticInput.userReady = false
            print(__S("a24858a653a9d93d8b769bba8dfaf7af6ae737a9194d7f06268f56e72aa9ae84ca666cfa10a9f8a47a43b2ea1a2cefcebd3734e79b04de00fa46c5af59f9d7604eafa22c514f47558d63d57f20d4e106da668041ea1a5593484b92008c583cd3e3af7e30d0c3128ef37b14180874e8d0e03a565986af720e1d5f9ce2b4b25b7b962c3b46167ebc4a03ca5fffdce9a94ccaba9d34ce57824b9000ed6c0207b8378a3be7a05b5897c826ea"))
        end
        return false
    end
    return true
end

local function pressKey(keyCode, holdTime)
    if Config.UseVirtualInput == false then return false end
    if not SyntheticInput.vimReady then return false end

    local now = os.clock()
    if (now - SyntheticInput.lastKey) < 0.05 then return false end
    SyntheticInput.lastKey = now

    local ok = pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    end)
    task.delay(holdTime or 0.05, function()
        SkillHubStep(__S("407fd2579f4ae6ec0027173f8d52d0a35178cf98dd83eb4db7726de667fd38fd3783"), function()
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end)
    if not ok then
        SyntheticInput.vimFails = SyntheticInput.vimFails + 1
        if SyntheticInput.vimFails >= 3 and not SyntheticInput.warnedVim then
            SyntheticInput.warnedVim = true
            SyntheticInput.vimReady = false
            print(__S("deb74c08a841a772987d1973bc8c959e100edb6e83ac7eb1d0cce3a62c6b2d14f4fdaa51db001e3e4c4d9e2fb7dc1bf642dc2b7ea52c50329db994f7ddc2aedd7f17f95c5ee96560028d725a264ab1579c076dfd0b9b6ee1322086a8590b411de4dbad804b3fc71a1572857ebc8533d6383e893f51e1a9b9ea53051477c9384ca4206191db85665d869d8046d1ca68f514c52edfe3462203bb2a9953bab25e12"))
        end
        return false
    end
    return true
end

                                                                                   
                                                                     
local Hooks = {
    notify    = function() end,
    clearESP  = function() end,
    espTag    = function() end,
}

                                                                             
                                                                            
                                                                                
                
local MovementLink = {
    isFlyActive  = function() return false end,
                                                                             
                                                                           
    setFlyTarget = function() end,
    clearFlyTarget = function() end,
}

                                                                                 
                                                                                 
local HookRegistry = {
    installNamecall = function() end,
    namecallActive  = false,
}

                                                                             
                                                                                   
                                                                                    
local BLOCKED_REMOTE_PATTERNS = {
    __S("7ceec5b9549f768f0419b57482"), __S("1b263f6a8efb0c3dc50181120433"), __S("b95db91bc5322fc078608dc2ab4f"), __S("579532cc191351208691bcf506bba9750c"), __S("f5ccac7dafb666f2b6148a66"),
    __S("9404262efaedb008a3e22144a782f931cd7f"), __S("323b9fdfbc3f2a43f3a1e2d6e2cb66"), __S("d0731990586610adb47283511c89"), __S("6eaa934145a1ef3afd675821f38ece1c82"), __S("0ce20cf2a9f0283ca744253894"),
    __S("ab1986a38e6e8742bffbf8b9d6f5"), __S("49510054a94054358e016369e1de"), __S("e7887a052085fd54c8e9d4dae7f6ce7f191a9c2c"),
}

                                                                                   
local SeaEventState = {
    events = {},
    mirage = {},
    lastNotify = {},
}

                                                                         
RespawnQuietUntil = 0
markRespawnQuiet = nil


                                                                              
                                                            
  
                                                                                 
                                                                             
                                                  
  
                                                                             
                                                                         
                                                                              
                                                                              
                                                                                
                                                                                
                                                                                
                                                                            
                                                                                
                                                                               
                                                                                 
                                                                 
                                                                            
                                                                                
                                                                              
                                                                         
                                                                           
                                                                            
                                                                              
local Guard = {
    mode        = (Config.GuardMode or __S("85bff3b665a63458")),
    licensed    = true,
    compromised = false,
    hwid        = __S("23f76d677fe79134d2d0b8"),
    keyHash     = __S("c22ee718d0b2b94c"),
    fingerprint = __S("606660c94375481a03683d"),
    watched     = {},
    lastAudit   = 0,
    auditNote   = __S("fe9dda7a9d313c41da53e1c3ef7f84"),
    notes       = {},
}

                                                                           
local function guardMul32(a, b)
    local result = 0
    for _ = 1, 32 do
        if b % 2 == 1 then result = (result + a) % 4294967296 end
        a = (a * 2) % 4294967296
        b = math.floor(b / 2)
    end
    return result
end

local function guardXor(a, b)
                                                                             
                                                                       
    if type(bit32) == __S("9cd5542b173e1cfe70") and type(bit32.bxor) == __S("3b0ccddc019e927cc930e334") then return bit32.bxor(a, b) end
    local result, bit = 0, 1
    for _ = 1, 32 do
        if a % 2 ~= b % 2 then result = result + bit end
        a, b, bit = math.floor(a / 2), math.floor(b / 2), bit * 2
    end
    return result
end

local function guardHash32(text)
    local hash = 2166136261
    for index = 1, #text do
        hash = guardXor(hash, (string.byte(text, index) or 0) % 256)
        hash = guardMul32(hash, 16777619)
    end
    return string.format(__S("d944478d921a3635"), hash)
end

                                                                               
                                                            
local function guardUnseal(blob, tag)
    if type(blob) ~= __S("777bc13ee323592df83b") or blob == "" then return nil end
    local seed = tonumber(guardHash32(tag), 16) or 1
    if seed == 0 then seed = 1 end
    local out = {}
    for index = 1, #blob - 1, 2 do
        local byte = tonumber(string.sub(blob, index, index + 1), 16)
        if not byte then return nil end
        seed = guardXor(seed, (seed * 8192) % 4294967296)
        seed = guardXor(seed, math.floor(seed / 131072))
        seed = guardXor(seed, (seed * 32) % 4294967296)
        out[#out + 1] = string.char(guardXor(byte, seed % 256))
    end
    return table.concat(out)
end
                 

                                                                               
local Pristine = {}
do
    local function grab(object, name)
        local ok, value = pcall(function() return object[name] end)
        if ok and type(value) == __S("15b33aeffe7d5c2cabc83e57") then return value end
        return nil
    end
    Pristine.HttpGet = grab(game, __S("b3eab4a0b7e7183b8c8187"))
    Pristine.HttpPost = grab(game, __S("52222e514d3503fa39aed88d"))
    Pristine.loadstring = loadstring
    Pristine.info = (type(debug) == __S("f059a8021a4d1ca18b") and debug.info) or nil
end

function Guard.http(url)
    if type(url) ~= __S("8e9121b393b8249d553d") or not Pristine.HttpGet then return nil end
    local ok, body = pcall(Pristine.HttpGet, game, url)
    if ok and type(body) == __S("2cc89b6405d7c92b435f") then return body end
    return nil
end

                                                                               
local function globalsTable()
    if type(_G) == __S("cb00151530cd8dd165") then return _G end
    if type(SharedEnv) == __S("69378ec6e5de8ca00e") then return SharedEnv end
    return {}
end

local function rawHwid()
    local env = globalsTable()
    local candidates = {
        function() local fn = env.gethwid; if type(fn) == __S("076f0877c141180d98197a20") then return fn() end end,
        function() local fn = env.get_hwid; if type(fn) == __S("a5a682289ff905c0664627f4") then return fn() end end,
        function() if syn and syn.get_hwid then return syn.get_hwid() end end,
        function() return game:GetService(__S("43ddfbd9983de34e3d8ccc6f19a1d3b977a16901521d66")):GetClientId() end,
        function() local players = game:GetService(__S("e215758a88eac73f350f13")); return players.LocalPlayer and players.LocalPlayer.UserId end,
        function() return tostring(game.PlaceId) end,
    }
    for _, attempt in ipairs(candidates) do
        local ok, value = pcall(attempt)
        if ok and value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    return __S("804cef3b5bcf1e591bef55")
end

Guard.hwid = rawHwid()
Guard.keyHash = guardHash32(tostring(Config.LicenseKey or ""))
Guard.fingerprint = guardHash32(Guard.hwid .. __S("1e8468ec5cd7cb1924e07ff7c224"))

do
    local keys = Config.LicenseKeys
    if type(keys) == __S("bcbbe29dbdc2f6f941") and #keys > 0 then
        Guard.licensed = false
        for _, entry in ipairs(keys) do
            if tostring(entry) == Guard.keyHash then
                Guard.licensed = true
                break
            end
        end
    end
end

function Guard.blocked()
    if Guard.mode ~= __S("5af35c4ef6a1ccbc2e377e") then return false end
    return (not Guard.licensed) or Guard.compromised
end

                                                                               
function Guard.watchTable(prefix, sourceTable)
    if type(sourceTable) ~= __S("f92ad5ffe141c66ac2") then return 0 end
    local count = 0
    for key, value in pairs(sourceTable) do
        if type(value) == __S("97624fb0dc1cd5334b2ced08") then
            local identity = nil
            if Pristine.info then
                local ok, info = pcall(Pristine.info, value, __S("3599c96128"))
                if ok and type(info) == __S("d3d14312d8ab2816f249") then identity = info end
            end
            table.insert(Guard.watched, {
                name = tostring(prefix) .. __S("7208bcc345") .. tostring(key),
                fn = value,
                identity = identity,
            })
            count = count + 1
        end
    end
    return count
end

function Guard.audit()
    Guard.lastAudit = os.clock()
    if not Pristine.info then
        Guard.auditNote = __S("104036742664227fc7ce9e11d157f6f07ff18f0250b4eaea7f05f17d633b488923fa7d99c87285b53e9208d729a59e92c7fa3c32fa")
        return 0
    end
    local broken, checked = 0, 0
    for _, entry in ipairs(Guard.watched) do
        if entry.identity then
            checked = checked + 1
            local ok, info = pcall(Pristine.info, entry.fn, __S("ae77b025ef"))
            if not ok or info ~= entry.identity then
                broken = broken + 1
                if not entry.reported then
                    entry.reported = true
                    print(string.format(__S("4caf29d6c7372e4a3a228a00b06f7ba8bec33e0aaefadcaba61e59956c1bc19abb3a355a206bbdaa268f0ee267a406cd76d184585a04f1df917a8a197ba5102d67664860f9e987"), entry.name))
                end
            end
        end
    end
    Guard.auditNote = string.format(__S("eae6a3876992d5ec4cb9c5241ff65541e35eee98a413f17cb341c77f1d4a5e8ebffdc4112353"), checked, broken)
    if broken > 0 and not Guard.compromised then
        Guard.compromised = true
        print(__S("891e1d38bf96fea4725b6f9b7885ed54eae35163794645b82df79d1214a23a9dc1bacd6b065f0882788115a39ef1a041af76ae108c4e23f8e2f5802c874cc82380ea2c573f77fce7fa8f9e0e69e8868788cb83801c4bec84cbef95d1c7"))
    end
    return broken
end

function Guard.startAudit()
    if Config.GuardMode == __S("275596e9e2f8d9") then return end
    task.spawn(function()
        while true do
            task.wait(math.max(tonumber(Config.TamperAuditSeconds) or 30, 5))
            pcall(Guard.audit)
        end
    end)
end

                                                                               
function Guard.hookRadar()
    if type(getrawmetatable) ~= __S("c58d109a9356e5236826d83d") then return __S("63c48a4bca7def9eae5027bca9496e21a9bc06f321d102d3fa75edfc7d5ebc") end
    local ok, metatable = pcall(getrawmetatable, game)
    if not ok or type(metatable) ~= __S("01fc03fce968099c23") then return __S("a0337dadc99dcf356f2e65c4df9ec3b9a49e0fd9607114e34c59a0b993f601") end
    local namecall = metatable.__namecall
    if namecall == nil then return __S("3e6af75eb0cc14b89a99f42972959099f7b65fa51b0bd5306c579f473a7f3352ff4657c8c9a651") end
    local kind = __S("dca2710ffbc458dfe2b0931d9a6f67ea")
    if type(iscclosure) == __S("7ad9eac066b9d9af18ea45a8") then
        local okC, isC = pcall(iscclosure, namecall)
        if okC and isC == true then kind = __S("191164713d93629caee3560b91951fd49e5cc57e562fa01b1e04dd99d31bbcfd8dcc") end
    end
    if type(islclosure) == __S("b748de228255f816bc520529") then
        local okL, isL = pcall(islclosure, namecall)
        if okL and isL == true then kind = __S("558057d3e2bd18c981f0f8d0a7e997f4e4d301d8d74e4c991620bec8b2e2b6d16a521a599fab1e63") end
    end
    return __S("f3b7d184f8f44616280f4cd824ebe79c8e509e2f3961f85fe6") .. kind
end

                                                                               
function Guard.endpoint()
    if type(Config.SealedEndpoint) ~= __S("91ef4b3522c9a99a2224") or Config.SealedEndpoint == "" then return nil end
    local url = guardUnseal(Config.SealedEndpoint, Guard.fingerprint)
    if type(url) ~= __S("3026c4e6a8a827373560") or not string.match(url, __S("ce5e3e972fb5b53f1a125f4a3245")) then
        print(__S("6c95b8481d62372bbc2a7ea2e43cf86eb47af5ee5de606f97dad11e10472ff6653dd2a1180ecda6386129c947c47c939563535a8c4ae983eb1c6b58f729a8a8ad049556bc2d5fb4babe21212b43b967d48423468d6c402cfc8c843f51a08c5af1d"))
        return nil
    end
    return url
end

function Guard.requestHeaders()
    if Config.RequestWatermark == false then return {} end
    return { [__S("0acd31f9d828cbbb8d4bf578e46d4e5af5e8")] = Guard.fingerprint }
end

function Guard.report()
    local lines = {
        __S("a904abaa95fd59be0637a92ef3f07a0982310ec873") .. tostring(Guard.mode) .. (Guard.mode == __S("473c255bf52e1ffd245b1d") and __S("e5739f0cc58fd8ae21e49f1ed9d00b") or __S("83ab18bda351bf3f983e6a51b0e5e8a91951")),
        __S("21e2926edf38630cdf181a9ffbfc6ed339640954ea") .. Guard.fingerprint .. __S("c01a0c1f936e439778acc72ec15a097db74d4a370ed09b09dc326ab4a74fedb19b2d6d8e84272fd5a995ab185f073731531830221dc9"),
        __S("5e5185d049a23e88a5be1141a8ab67b0bd68d4493c") .. (Guard.licensed and __S("fc88ff81fc0753560754e584cbb0") or __S("9ac07932afe4fc2951ac7c4c859eb87c97684b1a6bd41ab86dd39889b214c3b9c49d071ef180a3613040b8dde8")) ..
            (type(Config.LicenseKeys) == __S("38f7f2e302ea598554") and #Config.LicenseKeys > 0 and "" or __S("d72f6c94aacb0277a741308d56c84bd357e2be55d9d6f099ac079f6e2b")),
        __S("7566e6458ba65b5def591bf37eef15d83bfaa8dc16") .. Guard.keyHash .. __S("139e5ff6268968785ee8a7f143a358ca7ac564bcf1ee4d311ba8de3415fd7ea2d6c0fa1afd6bedc788fbce0519493887c39fbf5902c53a3dc873e7"),
        __S("b1d5d9a763b6e719b16aefd0b74bf7bcb3034e4e0c") .. Guard.auditNote .. __S("500d53582b0af5ca4d18") .. tostring(#Guard.watched) .. __S("ee44cd09bb6ec298849b25510c4f98bff5cfb2a54b"),
        __S("8c7c46ba4755738239f136fbb2de86a2039f53ea03") .. Guard.hookRadar(),
        __S("2ab3c06be79d0ffc158893df0b2bb46d69f5f39505") .. (type(Config.SealedEndpoint) == __S("c8eb3a1cbb6aa9eb429e") and Config.SealedEndpoint ~= "" and __S("6722b3cd01199fd8290cf75aacaad218ecf312eae1a8b70f3f02d029b656") or __S("055a2d7eea5531ef")),
        __S("a391a72f67c95b04302be8d346c8ccd113766ba365") .. (Config.RequestWatermark == false and __S("41c920e03d04e8d380e296eba8f3ff2f4e") or __S("e0009a914f5f63592aaa7bf8fe0ff4f0")) .. __S("7e3814427a73c25fc8511a42518d1e833f8b964089e7d0ea78f8f671f1600dfaf32ca1f5e744f855ebaf633cdbdd2d2e12f290ec542c0834"),
    }
    return table.concat(lines, "\n")
end

print(string.format(__S("1c6f8df320feb30443bb084a8c1126ce8f41eb86293692f2963f69cfb7fd183070e6ebadbfc157c7032d46007bdf121ac0e88077391d2386fa6957f8e164db6613879b8275e9fb2d0e833ec0"),
    tostring(Guard.mode), Guard.fingerprint, Guard.licensed and __S("baa707a44267") or __S("58de81558d53f74762df04"), Guard.hookRadar()))

                                                                              
                                                                 
                                                                              


                                                                              
                   
                                                                        
                                                                  
                                                        
                                                                              
local EngineFactory = function(E)
    local BLOCKED_REMOTE_PATTERNS, BOSSES_BY_SEA, CURRENT_SEA, Config = E.BLOCKED_REMOTE_PATTERNS, E.BOSSES_BY_SEA, E.CURRENT_SEA, E.Config
    local CustomIcons, Debris, FIGHTING_STYLE_REMOTES, FIGHTING_STYLE_TOOLS = E.CustomIcons, E.Debris, E.FIGHTING_STYLE_REMOTES, E.FIGHTING_STYLE_TOOLS
    local FRUIT_STORE_CODES, HookRegistry, Hooks, LocalPlayer = E.FRUIT_STORE_CODES, E.HookRegistry, E.Hooks, E.LocalPlayer
    local MovementLink, Players, QUEST_DATABASE, ReplicatedStorage = E.MovementLink, E.Players, E.QUEST_DATABASE, E.ReplicatedStorage
    local RunService, SEA_DETECT_SOURCE, SEA_EVENT_SIGNATURES, SeaEventState = E.RunService, E.SEA_DETECT_SOURCE, E.SEA_EVENT_SIGNATURES, E.SeaEventState
    local SkillHubStep, StatsService, TweenService, UserInputService = E.SkillHubStep, E.StatsService, E.TweenService, E.UserInputService
    local VirtualUser, Workspace, getFruitTier, isMeleeTool = E.VirtualUser, E.Workspace, E.getFruitTier, E.isMeleeTool
    local pressKey, refreshSea, toolMatchesCategory, trace = E.pressKey, E.refreshSea, E.toolMatchesCategory, E.trace
    local Guard = E.Guard
    local virtualClick = E.virtualClick

local SAFE_GAMEPLAY_REMOTES = {
    [__S("f715fb06dfb3ff59f91a")]             = true,
    [__S("954d74b779c1b3fc03")]              = true,
    [__S("3384ee68befa0e27aae1a63d573648d7f1a2a80b94")]  = true,
    [__S("d1bc6819f442086fd975786a2975e54c91e4")]     = true,
    [__S("6ff3e1cabdb5950937acfdd8d82f0c78b1182e20baf6")] = true,
    [__S("0e2b5b7b8fd5ac8339b20d5aae")]          = true,
    [__S("ac62d52cdd215c15e7ce")]             = true,
}

local function isSuspiciousRemote(remoteObj)
    if not remoteObj or typeof(remoteObj) ~= __S("4a9a4edd94c0d9cad30c4499") then return false end
    local okIs, isRemote = pcall(function()
        return remoteObj:IsA(__S("e8d1c88efcb78724d044730c4c0afc")) or remoteObj:IsA(__S("8709423fcafc6ab226c842c97dce468597bb"))
    end)
    if not okIs or not isRemote then return false end

    local nameLower = tostring(remoteObj.Name):lower()
    if SAFE_GAMEPLAY_REMOTES[nameLower] then return false end
    for _, kw in ipairs(BLOCKED_REMOTE_PATTERNS) do
        if string.find(nameLower, kw, 1, true) then return true end
    end
    return false
end

local function initBloxFruitsAntiCheatBypass()
                                                                       
                                                                                    
                                                                                 
                                                                                    
                              
    if Config.HookEngine then
        pcall(function() HookRegistry.installNamecall() end)
    end

                                                                           
                                                                              
    pcall(function()
        local pScripts = LocalPlayer:FindFirstChild(__S("2540bbf05f264a707e60b6d479b76c0412"))
        if not pScripts then return end
        for _, desc in ipairs(pScripts:GetDescendants()) do
            if desc:IsA(__S("c37835a1eb939db9d1792facf9a70f")) then
                local n = string.lower(desc.Name)
                if string.find(n, __S("61afaf521131b06fb22c52f825"), 1, true) or string.find(n, __S("ffe7290301bf302b7dc156ea1d81"), 1, true)
                    or string.find(n, __S("9e1ea2b4e4a8ffe2404bb2853a5bb92abff3"), 1, true) or string.find(n, __S("3c561c65edb93da5f63796c1c7137398fc"), 1, true) then
                    pcall(function() desc.Disabled = true end)
                end
            end
        end
    end)
end

initBloxFruitsAntiCheatBypass()

                                                                                 
                                                                       
local function applyCharacterTweaks(char)
    local hum = char and char:FindFirstChildOfClass(__S("da8d961659d446d970937bbd"))
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
    if char:FindFirstChild(__S("78c50fc72acc490e")) then pcall(function() char.Stun.Value = 0 end) end
    if char:FindFirstChild(__S("16fc8978f37aa8b6")) then pcall(function() char.Busy.Value = false end) end
end

if LocalPlayer.Character then applyCharacterTweaks(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.35)
    applyCharacterTweaks(char)
end)

                                                                             
local lastSimRadiusWrite = 0
RunService.Heartbeat:Connect(function()
    if not Config.BypassAntiCheat and not Config.AntiStun then return end
    pcall(function()
                                                                                  
                                                                             
        if sethiddenproperty and (tick() - lastSimRadiusWrite) > 2 then
            lastSimRadiusWrite = tick()
            SkillHubStep(__S("b5340329cce1a0d932470abd22b795d5"), function()
                sethiddenproperty(LocalPlayer, __S("536b7cdab15f4edfcf02ff3df977e1dabde8d57a"), 9e9)
                sethiddenproperty(LocalPlayer, __S("f1a2f68b3fe1e9449619ffdecb1e46489c20df456b7f90"), 9e9)
            end)
        end

        local char = LocalPlayer.Character
        if not char then return end

                                               
        if Config.AntiStun then
            local stun = char:FindFirstChild(__S("8fda703cc1f89371"))
            if stun and (stun:IsA(__S("2e11e9ed52d6c10459f033e1")) or stun:IsA(__S("cc49639eadb819ea554f2fb528edb5"))) and stun.Value ~= 0 then
                stun.Value = 0
            end
            local busy = char:FindFirstChild(__S("6a80dd4ff9a1fb5e"))
            if busy and busy:IsA(__S("08b85700eeb0cf9d6f232aba1f")) and busy.Value == true then
                busy.Value = false
            end
        end

                                                                            
                                                                     

        if Config.AutoFarmLevel or Config.AutoFarmNearest or Config.AutoFarmBoss or Config.AutoFarmAllBosses then
            local hrp = char:FindFirstChild(__S("a6efd0b125cf253c6474d60808eaec00df93b07b"))
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end)

                                                                              
                                                              
                                                                              

local function getCommF()
    local remotes = ReplicatedStorage:FindFirstChild(__S("45274a62e5b9354b3950b8"))
    return remotes and remotes:FindFirstChild(__S("e35ec4131ed2e8dbd27f"))
end

local function invokeCommF(...)
    local comm = getCommF()
    if comm and comm:IsA(__S("81963dc4e1a331d6d47d10fd4bf70d4eaddd")) then
        local ok, res = pcall(function(...)
            return comm:InvokeServer(...)
        end, ...)
        if ok then return res end
    end
    return nil
end

local function getCharacter() return LocalPlayer.Character end
local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild(__S("1fcdb7752ca2f8ea2965dd364cdd3a2c6be79fda"))
end
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass(__S("be053126bef3fc8a46e0d817"))
end

local function getPlayerLevel()
    local data = LocalPlayer:FindFirstChild(__S("5c3caad7a01af5ad"))
    local lv = data and data:FindFirstChild(__S("fa742488f6f744b0df"))
    return (lv and lv.Value) or 1
end

local function getPlayerBeli()
    local data = LocalPlayer:FindFirstChild(__S("98ab9e392bb272b5"))
    local beli = data and data:FindFirstChild(__S("36e317ea07fc2159"))
    return (beli and beli.Value) or 0
end

local function getPlayerFragments()
    local data = LocalPlayer:FindFirstChild(__S("d51a919bab7f7fcc"))
    local frags = data and data:FindFirstChild(__S("73520b4c3760dc991822fa1327"))
    return (frags and frags.Value) or 0
end

local function formatNumber(n)
    local s = tostring(math.floor(n or 0))
    return s:reverse():gsub(__S("118984fd9e7070d98c0cd43f"), __S("afc0feae012b6e")):reverse():gsub(__S("4df8785fb816"), "")
end

                  
local activeTween = nil

local function stopTween()
    pcall(function() MovementLink.clearFlyTarget() end)
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
    local root = getRoot()
    if root and root:FindFirstChild(__S("ec2ff210b5baf7c1ca01c2cc9ad131b2e5e67e46")) then
        root.SkillHubAntiFall:Destroy()
    end
end

local function tweenTo(targetCFrame, speedOverride)
    local root = getRoot()
    if not root or not targetCFrame then return end

                                                                                  
                                                                                
                                                                        
    if MovementLink.isFlyActive() then
        MovementLink.setFlyTarget(targetCFrame, speedOverride)
        return
    end

    if not root:FindFirstChild(__S("8a676bc1dd45ca83f37075a31d6bbb399caf8176")) then
        local bv = Instance.new(__S("289ee57268d2724d1380f8a961242719"))
        bv.Name = __S("c6d65f23a924731efe87298d698c244f49a9b7dc")
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.zero
        bv.Parent = root
    end

    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist < 12 then
        root.CFrame = targetCFrame
        return
    end

    local duration = math.max(dist / math.max(Config.TweenSpeed, 100), 0.05)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    if activeTween then
        pcall(function() activeTween:Cancel() end)
    end
    activeTween = SafeTween(root, info, {CFrame = targetCFrame})
    activeTween:Play()
end

                                                                               
                                                                               
                                                                                 
                                                                                 
                                                                                 
                                      

local function isToolEquipped(toolName)
    local char = getCharacter()
    return char and char:FindFirstChild(toolName) ~= nil
end

local function collectTools()
    local list = {}
    local char = getCharacter()
    local backpack = LocalPlayer:FindFirstChild(__S("650dd8d47d65df570aec6f1a"))
    for _, container in ipairs({ char, backpack }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA(__S("03455285bb0e2b9a")) then table.insert(list, tool) end
            end
        end
    end
    return list
end

local function equipTool(tool)
    if not tool or not tool:IsA(__S("a17ccc367faa6ec6")) then return false end
    local char = getCharacter()
    local hum = getHumanoid()
    if not char then return false end
    if char:FindFirstChild(tool.Name) then return true end

    pcall(function()
        if hum then hum:EquipTool(tool) end
    end)
    if char:FindFirstChild(tool.Name) then return true end

                                                                                 
                                                                               
    pcall(function() tool.Parent = char end)
    return char:FindFirstChild(tool.Name) ~= nil
end

local function findToolByCategory(weaponType)
                                                                  
    local char = getCharacter()
    local equipped = char and char:FindFirstChildOfClass(__S("3fb445e75747ce99"))
    if equipped and toolMatchesCategory(equipped, weaponType) then return equipped end

    for _, tool in ipairs(collectTools()) do
        if toolMatchesCategory(tool, weaponType) then
            if not char or not char:FindFirstChild(tool.Name) then return tool end
        end
    end
    return nil
end

local function equipWeaponByType(weaponType)
    if not getCharacter() then return false end
    local tool = findToolByCategory(weaponType)
    if not tool then return false end
    return equipTool(tool)
end

                                                                              
                                                                                 
                                                                         
local function equipFightingStyle(styleQuery)
    if not styleQuery then return false end
    local key = tostring(styleQuery):lower():gsub(__S("ddebbf983184b00bfece9edde7c3"), ""):gsub(__S("7c2339491219dff1"), ""):gsub(__S("1a5ab2fadd6bf711"), "")
    local canonical = FIGHTING_STYLE_TOOLS[key] or FIGHTING_STYLE_TOOLS[key:gsub(__S("b8922cab0d99"), "")]
    if not canonical then return false end
    local remote = FIGHTING_STYLE_REMOTES[canonical]

    if remote then
        pcall(function() invokeCommF(remote, true) end)
        task.wait(0.3)
        pcall(function() invokeCommF(remote) end)
        task.wait(0.7)
    end

                                                                       
    local char = getCharacter()
    local target = nil
    for _, tool in ipairs(collectTools()) do
        local n = tool.Name:lower()
        if n == canonical:lower() or FIGHTING_STYLE_TOOLS[n] == canonical then target = tool break end
    end
    if not target then target = findToolByCategory(__S("56c9a65cb037a0ecae")) end
    if target and char and not char:FindFirstChild(target.Name) then
        equipTool(target)
        task.wait(0.15)
        if not char:FindFirstChild(target.Name) then equipTool(target) end
    end
    return char ~= nil and char:FindFirstChildOfClass(__S("f501200d797e0481")) ~= nil
end

                                                                               

local PVP_FLAG_NAMES = {
    __S("933899bec9109d"), __S("3170136f912bdf"), __S("cfa78d20710f5f"), __S("6ddf06d163b2ff93e81650d6873d"), __S("0c168082f1349390cbb2b493f594"), __S("aa4dfa3326db2efab27afa5aed8e"), __S("488573e4d18bcf96b9"), __S("e6bced951b992e1a1c"),
    __S("84f46746185e86533d71c1"), __S("232be0f79d5f9ede6cb3ba"), __S("c1635aa89ae6f37ee1"), __S("5f9ad459a1ff5b5b9a"), __S("fdd24e0a336f3b9a59"), __S("9c09c7bb016ec8bcfd6f69865e"), __S("3a41416c4a87ca555c4340e451"),
}

local function findPvpFlag(container)
    if not container then return nil, nil end
    for _, name in ipairs(PVP_FLAG_NAMES) do
        local v = container:FindFirstChild(name)
        if v and (v:IsA(__S("d878bb1dd24c360f595074acf3")) or v:IsA(__S("76b034ced365ecf2ae3ff469")) or v:IsA(__S("14e7ae7fc5513d5983eb3adc4a20d4")) or v:IsA(__S("b31f2830ef7ff522ed1d422bd16a32"))) then
            return v, name
        end
    end
    return nil, nil
end

                                                                                
local cachedSafeParts, safeCacheStamp = nil, 0
local function getSafeZoneParts()
    if cachedSafeParts and (os.clock() - safeCacheStamp) < 20 then return cachedSafeParts end
    local parts = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA(__S("5156a1e19631f3961d48c634")) and obj.Name:lower():find(__S("ef8e1b921fb18062"), 1, true) then
                table.insert(parts, obj)
            end
        end
    end)
    cachedSafeParts, safeCacheStamp = parts, os.clock()
    return parts
end

local function isInsideSafeZone(char)
    if not char then return false end
    local root = char:FindFirstChild(__S("8dc595431d0da8b8bc92cb388213922ae7713eed")) or char:FindFirstChild(__S("2bfd0ef410ec39a3803ee215c937")) or char:FindFirstChild(__S("ca3488a5c1d3bd24e5"))
    if not root then return false end
    local pos = root.Position
    for _, part in ipairs(getSafeZoneParts()) do
        if part and part.Parent then
            local rel = part.CFrame:PointToObjectSpace(pos)
            local size = part.Size
            if math.abs(rel.X) <= size.X / 2 + 1 and math.abs(rel.Y) <= size.Y / 2 + 4 and math.abs(rel.Z) <= size.Z / 2 + 1 then
                return true
            end
        end
    end
    return false
end

                                                 
local function getPvPStatus(plr)
    local grey, green, red, blue = Color3.fromRGB(148, 163, 184), Color3.fromRGB(34, 197, 94), Color3.fromRGB(239, 68, 68), Color3.fromRGB(56, 189, 248)
    if not plr then return false, __S("686c0256b05dd5532157a9"), grey end
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass(__S("06a37c071e2d3dd592872725"))
    if not char or not hum then return false, __S("a4daf5b802fb20fddc0b9c55c3480d77beaf"), grey end
    if hum.Health <= 0 then return false, __S("43126f6992b5f08e"), grey end

    if char:FindFirstChild(__S("e149e91a895532d2cbe92559c7d6")) then
        return false, __S("7f8162cb94b4e0a585a59af560067f80e84d84e3eb0a"), blue
    end

                                      
    local flag, flagName = findPvpFlag(char)
    if not flag then flag, flagName = findPvpFlag(plr:FindFirstChild(__S("1db8dc7cc390db69"))) end
    if not flag then flag, flagName = findPvpFlag(plr) end
    if not flag then
                                                                              
                                                                               
                                                                              
        local playerGui = plr:FindFirstChild(__S("bbf0562d073e5e2d4c919d67e7"))
        local main = playerGui and playerGui:FindFirstChild(__S("5a27cfde7df98859"))
        if main then flag, flagName = findPvpFlag(main) end
    end
    if flag then
        if flag.Value == true then return true, __S("f85f498f68909fe9b018ad357c7a") .. tostring(flagName), red end
        if flag.Value == false then return false, __S("9696c3408f4540576108b757e0a9bc") .. tostring(flagName), green end
    end

                                                                               
    for _, attr in ipairs({ __S("34ce3cf1296614"), __S("d305b6a25a9863"), __S("713d305398faf5d28b68923188b9"), __S("0f74aa0497412ec235") }) do
        local v = (pcall(function() return plr:GetAttribute(attr) end)) and plr:GetAttribute(attr) or nil
        if v ~= nil then
            return v and true or false, (v and __S("adac23b508af80846cb74bd427c83eb1ad28") or __S("4be39d6631f219713218327e9664dbac5e2e09")), (v and red or green)
        end
    end

    if isInsideSafeZone(char) then return false, __S("ea1b171758cddd60f23b8b5e9b"), blue end

                                                                                    
                                                          
    return true, __S("885290c81de5d84bfab3d1ce672867c9f555bbde6fa8393da20845ca7a3211"), red
end

local function canAttackPlayer(plr)
    local ok = getPvPStatus(plr)
    return ok
end

local function getPlayerBounty(plr)
    local data = plr and plr:FindFirstChild(__S("268a0a79bf66e9ad"))
    if data then
        for _, n in ipairs({ __S("c4c1842a4adeb17cccc4"), __S("62f8fddb784d44901c3fbff75cd528"), __S("0130778cae02b8749219f4d94a5ed402") }) do
            local v = data:FindFirstChild(n)
            if v and v:IsA(__S("9f67f13d6bd943e5e1c60be8aa")) then return tostring(v.Value) end
        end
    end
    return __S("3d9f6aee42")
end

                                                                      
local function getPlayerLoadout(plr)
    local out = {
        fruit = __S("dbd6e49fd3c92fad"), style = __S("7a0e5e50b1d0fd6329cb"), sword = __S("1845d801ee"), gun = __S("b67d51b25a"),
        level = __S("54b4cb6350"), bounty = __S("f2ec45147e"), total = __S("9123bec595"), hp = 0, maxHp = 0,
    }
    if not plr then return out end
    local data = plr:FindFirstChild(__S("2f5b387698772063"))
    local function readData(...)
        if not data then return nil end
        for _, n in ipairs({ ... }) do
            local v = data:FindFirstChild(n)
            if v and v:IsA(__S("cd92b2271a83aac8c28b92abc5")) then return tostring(v.Value) end
        end
        return nil
    end
    out.level  = readData(__S("6bca2bd8cc06fbf2aa")) or __S("0a01a589ce")
    out.bounty = getPlayerBounty(plr)
    out.total  = readData(__S("a8391f3a37995a2a")) or __S("467098ebd0")
    out.fruit  = readData(__S("e4a8129c857bdfe10a4818ade139"), __S("82df8c4d60cc7ab249"), __S("211705fe2e17cca6549f91cd266011f11781cf")) or __S("bf4e7faffc610969")

    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass(__S("5d85f960fc8663bc91b8ab0c"))
    if hum then
        out.hp = math.floor(hum.Health)
        out.maxHp = math.floor(hum.MaxHealth)
    end

    for _, container in ipairs({ char, plr:FindFirstChild(__S("fbbd73117c84bcec2ee93808")) }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA(__S("99f4ecc22000a76d")) then
                    local isFruit = toolMatchesCategory(tool, __S("382c667300fecdd660a3b0022d03"))
                    if isFruit and (out.fruit == __S("d663e024b9a76491") or out.fruit == "") then
                        out.fruit = tool.Name
                    elseif isMeleeTool(tool) and out.style == __S("749b59d5e66ff1763f89") then
                        out.style = tool.Name
                    elseif toolMatchesCategory(tool, __S("12d2d3866421a95f2e")) and out.sword == __S("b10a4d376c") then
                        out.sword = tool.Name
                    elseif toolMatchesCategory(tool, __S("4f41c6e8a12ce3")) and out.gun == __S("ed79409981") then
                        out.gun = tool.Name
                    end
                end
            end
        end
    end
    out.fruit = tostring(out.fruit):gsub(__S("8bb0ba4ad6b8036bd068"), "")
    out.style = tostring(out.style):gsub(__S("29e833fb106aed636ec4"), "")
    return out
end

local function getPlayerByName(query)
    if not query or query == "" then return nil end
    local q = tostring(query):lower():gsub(__S("c81fadac078f9744"), ""):gsub(__S("6657275d4604cb98"), "")
    if q == "" then return nil end
    local exact, partial
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local nm = plr.Name:lower()
            local dn = plr.DisplayName:lower()
            if nm == q or dn == q then
                exact = plr
            elseif not partial and (nm:find(q, 1, true) or dn:find(q, 1, true)) then
                partial = plr
            end
        end
    end
    return exact or partial
end

local function getPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr.Name) end
    end
    table.sort(list)
    return list
end

                                                                       
local function getBladeHitTargets(radius)
    local root = getRoot()
    if not root then return nil, {}, {} end

    local maxDist = radius or Config.AttackRange or 65
    local primaryPart = nil
    local bladeHits = {}
    local rawParts = {}

    local enemiesFolder = Workspace:FindFirstChild(__S("048ea10e3cb771d29f64b9"))
    if enemiesFolder then
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            local hum = mob:FindFirstChildOfClass(__S("a2c61abfdf3fba5fee5db9e8"))
            local hrp = mob:FindFirstChild(__S("40fd9470215d430514252fb496f33058da68a6d3"))
            local head = mob:FindFirstChild(__S("df350e213132aae7")) or hrp
            if hum and hum.Health > 0 and hrp and head then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist <= maxDist then
                    if not primaryPart then
                        primaryPart = head
                    end
                    table.insert(bladeHits, {mob, head})
                    table.insert(rawParts, head)
                end
            end
        end
    end

    if Config.AttackPlayers then
        local charsFolder = Workspace:FindFirstChild(__S("7d6c87d27a92bec3867ae954fa69"))
        local list = charsFolder and charsFolder:GetChildren() or Players:GetPlayers()
        for _, entry in ipairs(list) do
            local char = entry:IsA(__S("1ba40183393bb30660e5")) and entry.Character or entry
            if char and char ~= LocalPlayer.Character then
                local hum = char:FindFirstChildOfClass(__S("b9db7b3462ea94fe15f13bf7"))
                local hrp = char:FindFirstChild(__S("5812f4e5aacbb85738e5610f43989799c6bed4ad"))
                local head = char:FindFirstChild(__S("f64a6e9652bd8bb0")) or hrp
                if hum and hum.Health > 0 and hrp and head then
                    if (hrp.Position - root.Position).Magnitude <= maxDist then
                        if not primaryPart then primaryPart = head end
                        table.insert(bladeHits, {char, head})
                        table.insert(rawParts, head)
                    end
                end
            end
        end
    end

    return primaryPart, bladeHits, rawParts
end

                                                                            
local cachedCombatLib = nil
local function getActiveCombatController()
    local ok, controller = pcall(function()
        if not cachedCombatLib then
            local pScripts = LocalPlayer:FindFirstChild(__S("9481e847b390d142f5f77070cae96fc571"))
            local cfScript = pScripts and pScripts:FindFirstChild(__S("32b961f8986c2ea57ebbee361e921f78a6ff66"))
            if cfScript then
                cachedCombatLib = debug.getupvalue(require(cfScript), 2)
            end
        end
        return cachedCombatLib and cachedCombatLib.activeController
    end)
    if ok then return controller end
    return nil
end

                                                                         
                                                     
local function fireAttackPackets(primaryPart, bladeHits, rawParts, reachHint)
    if Guard.blocked() then return end
    local char = getCharacter()
    if not char or not primaryPart then return end
    bladeHits = bladeHits or {}
    rawParts = rawParts or {}

                                                                                                  
    if #bladeHits > 0 then
        SkillHubStep(__S("d0f0dba966c1c8b72c4abb795600c07382"), function()
            local modules = ReplicatedStorage:FindFirstChild(__S("6f28555ab6c82f768cf5d2"))
            local net = modules and modules:FindFirstChild(__S("0d5fcf0b9a9ee7"))
            if net then
                local regAtk = net:FindFirstChild(__S("ab9748bc2eb03c9fac26c813c8aa38a52605729bb5"))
                local regHit = net:FindFirstChild(__S("49cec26d7ec847980d50da9f9d631d7bbc39"))
                if regAtk then
                    regAtk:FireServer(0)
                end
                if regHit then
                    regHit:FireServer(primaryPart, bladeHits)
                end
            end
        end)
    end

                                                               
    pcall(function()
        local ac = getActiveCombatController()
        if ac and ac.equipped then
            ac.timeToNextAttack = 0
            ac.attacking = false
            ac.blocking = false
            ac.focusStart = 0
            ac.increment = 3
            ac.hitboxMagnitude = reachHint or Config.AttackRange or 65

            if #rawParts > 0 then
                local rem = ReplicatedStorage:FindFirstChild(__S("e8063c1e0e0ceab83683c164930858f4744904fa920b"))
                local validator = ReplicatedStorage:FindFirstChild(__S("863db5cf7fac0de5659823"))
                    and ReplicatedStorage.Remotes:FindFirstChild(__S("24752f805447b58e6bf5c5a7b3"))
                if validator and ac.blades and ac.blades[1] then
                    SkillHubStep(__S("c2aca931193d8cf31ec503345817da6370"), function()
                        ac:attack()
                    end)
                end
                if rem then
                    local tool = char:FindFirstChildOfClass(__S("60e422e22a3b49b6"))
                    if tool then
                        rem:FireServer(__S("ff1b9c9360ee48eb7e0f14aa762e9e01"), tostring(tool.Name))
                    end
                    rem:FireServer(__S("9d531644c139d1"), rawParts, 3, "")
                end
            end
        end
    end)

                                                            
    pcall(function()
        local equippedTool = char:FindFirstChildOfClass(__S("3b8a8ff57bc916d7"))
        if equippedTool then
            equippedTool:Activate()
        end
        virtualClick(false)
    end)
end

local function triggerFastAttack()
    local primaryPart, bladeHits, rawParts = getBladeHitTargets(Config.AttackRange)
    if primaryPart then
        fireAttackPackets(primaryPart, bladeHits, rawParts)
    end
end

                                                                                            
task.spawn(function()
    while true do
        local delayTime = math.clamp(Config.FastAttackDelay or 0.02, 0.01, 0.25)
        task.wait(delayTime)
        SkillHubStep(__S("d9c209a610c8d59d4f73464916417cc53a"), function()
            if os.clock() < RespawnQuietUntil then return end
            local isFarming = Config.AutoFarmLevel or Config.AutoFarmNearest or Config.AutoFarmBoss or Config.AutoFarmAllBosses
            if (isFarming and Config.FastAttack) or Config.AutoAttackAlways then
                if (os.clock() - (lastAttackTrace or 0)) > 2 then
                    lastAttackTrace = os.clock()
                    trace(__S("77f9835738378751912274c56f5a078f4af74179ea"))
                end
                triggerFastAttack()
            end
        end)
    end
end)

local function ensureBuso()
    if not Config.AutoBuso then return end
    local char = getCharacter()
    if char and not char:FindFirstChild(__S("1630fd08880a0e67081bab")) then
        invokeCommF(__S("b46876b964eea64c"))
    end
end

local function bringNearbyMobs(targetName, targetPos)
    if not Config.BringMobs then return end
    local enemies = Workspace:FindFirstChild(__S("529ff06a066eb5293dc986"))
    if not enemies then return end
    for _, mob in ipairs(enemies:GetChildren()) do
        if not targetName or mob.Name == targetName then
            local hrp = mob:FindFirstChild(__S("f0d76a1bb961d75eb17fda4884d2273f7b560a69"))
            local hum = mob:FindFirstChildOfClass(__S("8f0ee3ccdf4430efaaa3162f"))
            if hrp and hum and hum.Health > 0 and (hrp.Position - targetPos).Magnitude <= 350 then
                SkillHubStep(__S("2d465d7d44b61adbf78758a81b504d1442"), function()
                    hrp.CFrame = CFrame.new(targetPos)
                    hrp.CanCollide = false
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    if Config.HitboxExpander then
                        hrp.Size = Vector3.new(55, 55, 55)
                        hrp.Transparency = 1
                    end
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    if Config.FreezeMobAnimations then
                        local anim = hum:FindFirstChildOfClass(__S("cb7dd72ee3786485cd841dee"))
                        if anim then
                            for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                                pcall(function() track:Stop(0) end)
                            end
                        end
                    end
                end)
            end
        end
    end
end

local function getQuestForLevel(lv)
    local list = QUEST_DATABASE[CURRENT_SEA] or QUEST_DATABASE[1]
    local chosen = list[1]
    for _, q in ipairs(list) do
        if lv >= q.MinLv then chosen = q end
    end
    return chosen
end

                                                                              
                                                                                     
                                                                              

local PvPState = {
    target = nil,
    targetName = "",
    lastAttack = 0,
    lastSkill = 0,
    hitboxOriginals = {},
}

                                                                              
                                                                                 
                                                                                  
                                                                               
                                                                                  
                                                            

local GIANT_MARKER_NAMES = { __S("69b550df4a077575c753"), __S("07ecca906d6f53e4bb095563e6de"), __S("a6244441b0305933723c0d7e72"), __S("445bbdf2541e92c8ef1b6cd2c9847c36e4f4"), __S("e29337a3d7a2428c72"), __S("80cab154e632ec96ec4f0e") }

local function getCharBoundingBox(char)
    if not char then return nil, nil end
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if ok and cf and size then return cf, size end
    local hrp = char:FindFirstChild(__S("1f022b05fc51035d1f9064dca76b50a1f514f617"))
    if hrp then return hrp.CFrame, hrp.Size end
    return nil, nil
end

local giantCache = {}
local function computeGiantForm(char)
    local hum = char:FindFirstChildOfClass(__S("bd39a4b609d5f05f5910cbca"))
    if hum and (tonumber(hum.HipHeight) or 0) > 6 then return true end
    local ok, size = pcall(function() return char:GetExtentsSize() end)
    if ok and size and size.Y > 11 then return true end
    for _, marker in ipairs(GIANT_MARKER_NAMES) do
        if char:FindFirstChild(marker) then return true end
    end
    for _, attr in ipairs({ __S("5b711e675bffc92f48ba"), __S("f9a89818aa21d57a28"), __S("97e011c9d1b4740e6af0d22d31024f"), __S("36178b7a4f43c1acb7328b") }) do
        local v = char:GetAttribute(attr)
        if type(v) == __S("d44f052bfcca8efc86abe7") and v then return true end
    end
    local scale = char:GetAttribute(__S("72867edc61661cb642")) or char:GetAttribute(__S("10bdf88d68c74460"))
    if type(scale) == __S("aef5723ee9c8b45b4ebd") and scale > 1.6 then return true end
    return false
end

                                                                                 
local function isGiantForm(char)
    if not char or not char.Parent then return false end
    local now = os.clock()
    local cached = giantCache[char]
    if cached and (now - cached.t) < 0.4 then return cached.v end
    local result = computeGiantForm(char)
    giantCache[char] = { t = now, v = result }

    local count = 0
    for key in pairs(giantCache) do
        count = count + 1
        if count > 96 or not key.Parent then giantCache[key] = nil end
    end
    return result
end

local function isBuddhaUser(plr)
    if not plr then return false end
    local data = plr:FindFirstChild(__S("4d2cebef63aa636d"))
    local fruit = data and data:FindFirstChild(__S("eb6465a00c1406a6a8f9a7c601d1"))
    if fruit and tostring(fruit.Value):lower():find(__S("899bdf512b0828e32cc6"), 1, true) then return true end
    for _, container in ipairs({ plr.Character, plr:FindFirstChild(__S("27d359025931040b790768d0")) }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA(__S("c60ad2b369a041d7")) then
                    local original = tostring(tool:GetAttribute(__S("64424c64acd53fb60b9c2a528d8f9c90")) or ""):lower()
                    if original:find(__S("0279c6152a332ec676ac"), 1, true) or tool.Name:lower():find(__S("a0b13fc6408a9b53171e"), 1, true) then return true end
                end
            end
        end
    end
    return false
end

local function getCharacterCombatParts(char)
    if not char or char == LocalPlayer.Character then return nil end
    local hum = char:FindFirstChildOfClass(__S("3ee8b9775c576b327edb51d7"))
    local hrp = char:FindFirstChild(__S("dd2033288294f6383d6fd1e0c69ac886a34743d7"))
    local head = char:FindFirstChild(__S("7b57acd91755bfc7")) or hrp
    if not hum or not hrp or not head or hum.Health <= 0 then return nil end
    return { char = char, hum = hum, hrp = hrp, head = head }
end

local function castCombatSkills(inRange)
    if inRange == false then return end
    local now = os.clock()
    if now - (PvPState.lastSkill or 0) < math.clamp(Config.PvPSkillInterval or 0.4, 0.15, 1) then return end
    PvPState.lastSkill = now
    for _, key in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V }) do
        SkillHubStep(__S("198f268ae802d6272316e5f7fd4efe9692"), function()
            pressKey(key, 0.05)
            task.wait(0.05)
        end)
    end
end

                                                                             
local function buildAttackPayload(char)
    local hum = char and char:FindFirstChildOfClass(__S("b7c6a03bf37a1bdb61c74545"))
    local hrp = char and char:FindFirstChild(__S("55fe19ec6556639fa4ac285766a6af0c8fe9d18c"))
    if not hum or not hrp or hum.Health <= 0 then return nil end

    local head = char:FindFirstChild(__S("f435939d364e51e3")) or hrp
    local giant = Config.BuddhaAwareCombat ~= false and isGiantForm(char)
    local bbox, size = getCharBoundingBox(char)

    local bladeHits, rawParts, seen = {}, {}, {}
    local function addPart(part)
        if part and part:IsA(__S("926d0d4e6ed00c2c217249f3")) and not seen[part] then
            seen[part] = true
            table.insert(bladeHits, { char, part })
            table.insert(rawParts, part)
        end
    end

    if giant then
                                                                                  
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA(__S("30a486ffc005ddf5f0203a6b")) then addPart(d) end
        end
    end
    addPart(head)
    addPart(hrp)

                                                                                            
    local aimPoint = head.Position
    if giant and bbox and size then
        aimPoint = bbox.Position + Vector3.new(0, math.clamp(size.Y * 0.22, 2, 16), 0)
    end

    return {
        char = char, hum = hum, hrp = hrp, head = head,
        giant = giant, size = size, bbox = bbox,
        aimPoint = aimPoint, bladeHits = bladeHits, rawParts = rawParts,
    }
end

                                                                                       
local function attackCharacter(char)
    if Guard.blocked() then return false end
    local payload = buildAttackPayload(char)
    if not payload then return false end

                                                                   
    local range = (Config.AttackRange or 65) + (payload.giant and (payload.size and payload.size.Y * 0.6 or 25) or 0)

    local _, extraBlade, extraRaw = getBladeHitTargets(range)
    for _, entry in ipairs(extraBlade or {}) do
        if entry[1] ~= payload.char and not payload.rawParts[entry[2]] then
            table.insert(payload.bladeHits, entry)
            table.insert(payload.rawParts, entry[2])
        end
    end
    for _, part in ipairs(extraRaw or {}) do
        if part ~= payload.head then table.insert(payload.rawParts, part) end
    end

    fireAttackPackets(payload.head, payload.bladeHits, payload.rawParts, range)
    return true
end

local function tweenToPlayer(plr, distance)
    local payload = buildAttackPayload(plr and plr.Character)
    if not payload then return false end
    local base = (distance or Config.PvPTweenDistance or 12) + (Config.PvPHoverHeight or 0)
    if payload.giant and payload.size then
        base = base + math.clamp(payload.size.Y * 0.35, 6, 26)
    end
    tweenTo(payload.hrp.CFrame * CFrame.new(0, base, 0))
    return true
end

                                                                               
                                                                                   
                                                                                 
                                                                               
local function storeHitboxState(key, char)
    local store = PvPState.hitboxOriginals[key]
    if store then return store end
    store = { parts = {}, order = {} }
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA(__S("cedc00b037a45f2e2dd858b4")) then
            store.parts[d] = { size = d.Size, transparency = d.Transparency, collide = d.CanCollide, massless = d.Massless }
            table.insert(store.order, d)
        end
    end
    PvPState.hitboxOriginals[key] = store
    return store
end

local function setPlayerHitbox(plr, expand)
    local char = plr and plr.Character
    local hrp = char and char:FindFirstChild(__S("6d137a61c689952f0ea43c1a32462334668880a0"))
    if not hrp then return end
    local key = plr.Name

    if expand then
        local store = storeHitboxState(key, char)
        local target = math.clamp(Config.PlayerHitboxSize or 14, 4, 200)
        local factor = math.min(target / math.max(hrp.Size.X, 0.5), Config.HitboxWholeModel ~= false and 4 or 1)
        SkillHubStep(__S("0b4af4125b39f6a2b4f97c16beca0c622b"), function()
            for _, part in ipairs(store.order) do
                if part.Parent then
                    local orig = store.parts[part]
                    if part == hrp then
                        part.Size = Vector3.new(target, target, target)
                    else
                        part.Size = orig.size * factor
                    end
                    part.CanCollide = false
                    part.Massless = true
                    if Config.ShowHitboxVisual then
                        part.Transparency = part == hrp and 0.6 or math.max(orig.transparency, 0.7)
                    else
                        part.Transparency = orig.transparency
                    end
                end
            end
        end)
    else
        local store = PvPState.hitboxOriginals[key]
        if store then
            SkillHubStep(__S("a9826dc37324a162dfebc6b05c3fa0c030"), function()
                for _, part in ipairs(store.order) do
                    if part.Parent then
                        local orig = store.parts[part]
                        part.Size = orig.size
                        part.Transparency = orig.transparency
                        part.CanCollide = orig.collide
                        part.Massless = orig.massless
                    end
                end
            end)
            PvPState.hitboxOriginals[key] = nil
        end
    end
end

local function isFriend(plr)
    if not Config.IgnoreFriendsPvP then return false end
    local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
    return ok and res == true
end

                                                                          
local function pickAutoKillTarget(mode)
    local myRoot = getRoot()
    if not myRoot then return nil end
    mode = mode or Config.PvPTargetMode or __S("47b9e77471d71f69a15b79")
    local best, bestDist, bestScore = nil, math.huge, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local info = getCharacterCombatParts(plr.Character)
            if info and canAttackPlayer(plr) and not isFriend(plr) then
                local dist = (info.hrp.Position - myRoot.Position).Magnitude
                local score = dist
                if mode == __S("e5f1612563926e3207b1a7eb67") then
                    local hum = plr.Character and plr.Character:FindFirstChildOfClass(__S("8428dad6c78e9f0f3b2941fa"))
                    score = (hum and hum.Health) or math.huge
                elseif mode == __S("2260548748798f6c07eddc") then
                    score = (tonumber(getPlayerLevel(plr)) or 9999) * 1000 + dist
                end
                if score < bestScore then bestScore, bestDist, best = score, dist, plr end
            end
        end
    end
    return best, bestDist
end

                      
local SpectateState = { active = false, originalType = nil, originalSubject = nil }
local function setSpectate(plr)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local char = plr and plr.Character
    local hum = char and char:FindFirstChildOfClass(__S("c097ce38d8c9bc8546c6b2ee"))
    if hum then
        if not SpectateState.active then
            SpectateState.originalType = cam.CameraType
            SpectateState.originalSubject = cam.CameraSubject
            SpectateState.active = true
        end
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    elseif SpectateState.active then
        SkillHubStep(__S("5ecf47e99d2441ff4f3f55b4d707804fb3"), function()
            if SpectateState.originalSubject and SpectateState.originalSubject.Parent then
                cam.CameraSubject = SpectateState.originalSubject
            end
            if SpectateState.originalType then cam.CameraType = SpectateState.originalType end
        end)
        SpectateState.active = false
    end
end

                                                                               
                                                                           
                                                                              
                                                                               
local function aimCameraAt(target)
    local cam = Workspace.CurrentCamera
    local info = getCharacterCombatParts(target and target.Character)
    local myRoot = getRoot()
    if not cam or not info or not myRoot then return false end
    local fov = Config.AimLockFOV or 300
    if fov > 0 and (info.hrp.Position - myRoot.Position).Magnitude > fov then return false end

    local aimPos = info.head.Position
    if Config.BuddhaAwareCombat ~= false and isGiantForm(target.Character) then
        local bbox, size = getCharBoundingBox(target.Character)
        if bbox and size then aimPos = bbox.Position + Vector3.new(0, math.clamp(size.Y * 0.22, 2, 16), 0) end
    end
    local goal = CFrame.lookAt(cam.CFrame.Position, aimPos)
    local alpha = math.clamp(Config.AimLockSmoothness or 0.3, 0.05, 1)
    cam.CFrame = cam.CFrame:Lerp(goal, alpha)
    return true
end

                                                                   
task.spawn(function()
    while task.wait(0.06) do
        SkillHubStep(__S("fd06c19a6df2ecd4f25ec457b4bc19a9b5"), function()
            local target = nil
            local keepHitbox = {}

            if Config.AutoKillSelected then
                target = getPlayerByName(Config.SelectedPlayer)
                                                              
                if not target and Config.PvPFallbackNearest ~= false then target = pickAutoKillTarget() end
            end
            if not target and Config.AutoKillPvP then
                target = pickAutoKillTarget()
            end
            if not target and (Config.AimLock or Config.PlayerHitbox or Config.SpectatePlayer) then
                target = getPlayerByName(Config.SelectedPlayer)
            end

            PvPState.target = target
            PvPState.targetName = target and target.Name or ""

            if target then
                local info = getCharacterCombatParts(target.Character)
                if info then
                    local shouldFight = Config.AutoKillSelected or Config.AutoKillPvP
                    if shouldFight then
                        local now = os.clock()
                        local myRoot = getRoot()
                        local dist = myRoot and (info.hrp.Position - myRoot.Position).Magnitude or math.huge
                        local reach = (Config.AttackRange or 65) + 6

                                                                                               
                        if now - (PvPState.lastEquip or 0) > 1 then
                            local myChar = getCharacter()
                            if myChar and not myChar:FindFirstChildOfClass(__S("9b3e3b4b34853bf0")) then
                                PvPState.lastEquip = now
                                SkillHubStep(__S("3975b4fc590f3a12446e2ce543e2135fc03355a3"), function() equipWeaponByType(Config.SelectedWeaponType) end)
                            end
                        end

                                                                                  
                                                                                   
                                                        
                        if dist > (Config.PvPTweenDistance or 12) then
                            tweenToPlayer(target)
                            PvPState.lastFollow = now
                        elseif dist > reach and now - (PvPState.lastFollow or 0) > 0.35 then
                            PvPState.lastFollow = now
                            tweenToPlayer(target)
                        end

                        if now - (PvPState.lastAttack or 0) >= math.clamp(Config.PvPAttackInterval or 0.08, 0.05, 0.5) then
                            PvPState.lastAttack = now
                            attackCharacter(target.Character)

                                                                                          
                            if Config.AutoKillPvP and Config.KillAuraAllPvP ~= false then
                                local myPos = myRoot and myRoot.Position
                                for _, other in ipairs(Players:GetPlayers()) do
                                    if other ~= LocalPlayer and other ~= target and not isFriend(other) and canAttackPlayer(other) then
                                        local oInfo = getCharacterCombatParts(other.Character)
                                        if oInfo then
                                            local auraRange = Config.KillAuraRange or 95
                                            if not myPos or (oInfo.hrp.Position - myPos).Magnitude <= auraRange then
                                                attackCharacter(other.Character)
                                            end
                                        end
                                    end
                                end
                            end

                            if Config.PvPSkills ~= false then castCombatSkills(dist <= reach + 15) end
                        end
                    end
                    if Config.SpectatePlayer then setSpectate(target) end
                    if Config.PlayerHitbox then
                        setPlayerHitbox(target, true)
                        keepHitbox[target.Name] = true
                    end
                    if Config.PvPAutoAim ~= false and not Config.AimLock then
                        SkillHubStep(__S("d7ad2eadc18b4f504f80a2e63eac4b51"), function() aimCameraAt(target) end)
                    end
                end
            elseif Config.SpectatePlayer then
                setSpectate(nil)
            end

                                                                                
            if Config.PlayerHitbox and Config.ExpandAllPvPHitbox then
                local myRoot = getRoot()
                local myPos = myRoot and myRoot.Position
                local auraRange = math.max(Config.KillAuraRange or 95, 120)
                for _, other in ipairs(Players:GetPlayers()) do
                    if other ~= LocalPlayer and canAttackPlayer(other) and not isFriend(other) then
                        local oInfo = getCharacterCombatParts(other.Character)
                        if oInfo and (not myPos or (oInfo.hrp.Position - myPos).Magnitude <= auraRange) then
                            setPlayerHitbox(other, true)
                            keepHitbox[other.Name] = true
                        end
                    end
                end
            end

                                                                        
            if next(PvPState.hitboxOriginals) then
                for name in pairs(PvPState.hitboxOriginals) do
                    if not keepHitbox[name] or not Config.PlayerHitbox then
                        local plr = getPlayerByName(name)
                        if plr then setPlayerHitbox(plr, false) else PvPState.hitboxOriginals[name] = nil end
                    end
                end
            end
        end)
    end
end)

                                           
RunService.RenderStepped:Connect(function(dt)
    if not Config.AimLock then return end
    pcall(function() aimCameraAt(PvPState.target) end)
end)

                                                                              
                                                            
                                                                               
                                                             
                                                                              
                                                                                   
                                                                              

local MobHitboxStore = {}
local mobStoreCount = 0

task.spawn(function()
    while task.wait(0.35) do
        SkillHubStep(__S("75e4a85e64de8b9519a304d616310ab175"), function()
            local enemies = Workspace:FindFirstChild(__S("141c220f449995c8c2e1cf"))
            if not enemies then return end
            local root = getRoot()
            local size = math.clamp(Config.HitboxMobsSize or 55, 6, 200)
            local range = Config.HitboxMobsRange or 420

            for _, mob in ipairs(enemies:GetChildren()) do
                local hum = mob:FindFirstChildOfClass(__S("b2539bc0bdb53427b5e5af36"))
                local hrp = mob:FindFirstChild(__S("508b15714b56538d202183099601b023ad145182"))
                if hum and hrp and hum.Health > 0 and hrp.Parent then
                    local inRange = (not root) or (hrp.Position - root.Position).Magnitude <= range
                    if Config.HitboxMobs and inRange then
                        local store = MobHitboxStore[mob]
                        if not store then
                            store = { parts = {}, order = {}, baseSize = math.max(hrp.Size.X, 0.5) }
                            for _, d in ipairs(mob:GetDescendants()) do
                                if d:IsA(__S("eec28f22d323da30eb573025")) then
                                    store.parts[d] = { size = d.Size, transparency = d.Transparency, collide = d.CanCollide, massless = d.Massless }
                                    table.insert(store.order, d)
                                end
                            end
                            MobHitboxStore[mob] = store
                            mobStoreCount = mobStoreCount + 1
                        end
                                                                                        
                                                                                        
                                                                                          
                        local factor = 1
                        if Config.HitboxWholeModel ~= false then
                            factor = math.clamp(size / math.max(store.baseSize or hrp.Size.X, 0.5), 1, 4)
                        end
                        hrp.Size = Vector3.new(size, size, size)
                        hrp.CanCollide = false
                        hrp.Massless = true
                        for _, part in ipairs(store.order) do
                            if part ~= hrp and part.Parent then
                                if factor > 1 then
                                    local origPart = store.parts[part]
                                    if origPart then part.Size = origPart.size * factor end
                                end
                                part.CanCollide = false
                                part.Massless = true
                                if Config.ShowHitboxVisual then part.Transparency = math.max(part.Transparency, 0.75) end
                            end
                        end
                    elseif MobHitboxStore[mob] then
                        local store = MobHitboxStore[mob]
                        for _, part in ipairs(store.order) do
                            if part.Parent then
                                local orig = store.parts[part]
                                part.Size = orig.size
                                part.Transparency = orig.transparency
                                part.CanCollide = orig.collide
                                part.Massless = orig.massless
                            end
                        end
                        MobHitboxStore[mob] = nil
                        mobStoreCount = math.max(mobStoreCount - 1, 0)
                    end
                elseif MobHitboxStore[mob] then
                    local store = MobHitboxStore[mob]
                    for _, part in ipairs(store.order) do
                        if part.Parent then
                            local orig = store.parts[part]
                            part.Size = orig.size
                            part.Transparency = orig.transparency
                            part.CanCollide = orig.collide
                            part.Massless = orig.massless
                        end
                    end
                    MobHitboxStore[mob] = nil
                    mobStoreCount = math.max(mobStoreCount - 1, 0)
                end
            end

                                                             
            if mobStoreCount > 0 then
                for mob, store in pairs(MobHitboxStore) do
                    if not mob.Parent then
                        MobHitboxStore[mob] = nil
                        mobStoreCount = mobStoreCount - 1
                    end
                end
            end
        end)
    end
end)

                                                                              
                                                                           
                                                                                  
                                                                                  
                                            
                                                                         
                                                                            
                                                                                
                                                     
                                                                                
                                                                       
                                                                
                                                                              

local BLOCK_RESULT = {}
local originalNamecall = nil

                                                                               
                                                                    
local HANDLED_METHODS = {
    Kick = true, kick = true,
    FireServer = true, InvokeServer = true,
    FindPartOnRayWithIgnoreList = true, FindPartOnRay = true, Raycast = true,
}

local function namecallInterceptor(self, ...)
    if not Config.SafeHookMode then return nil end

    local method = getnamecallmethod()
    if type(method) ~= __S("8cfa08d3308306f1de43") or not HANDLED_METHODS[method] then return nil end
    HookRegistry.hits = (HookRegistry.hits or 0) + 1

                                    
    if method == __S("2b318284ff066432") or method == __S("c968fc3569cfb229") then
        if self == LocalPlayer then return BLOCK_RESULT end
        return nil
    end

                                                               
    if Config.BypassAntiCheat and (method == __S("67a075e62e81a8dbeb1ec76aa502") or method == __S("05d7ef976c7cdc958834ce0f733dbb22")) then
        if isSuspiciousRemote(self) then return BLOCK_RESULT end
    end

                                                                              
    if Config.AimLock and PvPState.target
        and (method == __S("a40f6948fdae442861621e4a1a988fed983db155730b44f2b8ec4f43bec2b1") or method == __S("4246e2f9131db7e7a3cd40d98bc99f2282") or method == __S("e07e5caaed90a5805cb4dc")) then
        local targetChar = PvPState.target.Character
        local info = getCharacterCombatParts(targetChar)
        if info then
            local aimPos = info.head.Position
            if Config.BuddhaAwareCombat ~= false and isGiantForm(targetChar) then
                local bbox, size = getCharBoundingBox(targetChar)
                if bbox and size then
                    aimPos = bbox.Position + Vector3.new(0, math.clamp(size.Y * 0.22, 2, 16), 0)
                end
            end

            local args = { ... }
            if method == __S("7eb5d65ba2d17a567dc3eee86e68b0c77619c4d7dd80d75b5975e8d0f1f646") and args[1] then
                local dir = aimPos - args[1].Origin
                if dir.Magnitude > 0.1 then
                    return true, { Ray.new(args[1].Origin, dir.Unit * math.clamp(dir.Magnitude + 8, 1, 600)), args[2], select(3, ...) }
                end
            elseif method == __S("1ced500c7c4eeab44b9adddfc3be4f085b") and args[1] then
                local dir = aimPos - args[1].Origin
                if dir.Magnitude > 0.1 then
                    return true, { Ray.new(args[1].Origin, dir.Unit * math.clamp(dir.Magnitude + 8, 1, 600)), select(2, ...) }
                end
            elseif method == __S("bb24c9bd66a8b8cfd37f23") and args[1] and args[2] then
                local dir = aimPos - args[1]
                if dir.Magnitude > 0.1 then
                    return true, { args[1], dir, select(3, ...) }
                end
            end
        end
    end

    return nil
end

                                                                           
local function unifiedNamecall(self, ...)
    local ok, flag, payload = pcall(namecallInterceptor, self, ...)

    if ok then
        if flag == BLOCK_RESULT then return nil end
        if flag == true and type(payload) == __S("595c436e42e22ab419") then
            local okCall, res = pcall(function() return originalNamecall(self, table.unpack(payload)) end)
            if okCall then return res end
        end
    end

    if type(originalNamecall) == __S("f793bd1f815589a0ffc73dcc") then
        return originalNamecall(self, ...)
    end
    return nil
end

HookRegistry.installNamecall = function()
    if HookRegistry.namecallActive then return end
    if not Config.HookEngine then return end                        
    if not Config.SafeHookMode then return end                               
    if not (hookmetamethod and getnamecallmethod) then return end

    local replacement = unifiedNamecall
    if newcclosure then
        local okWrap, wrapped = pcall(newcclosure, unifiedNamecall)
        if okWrap and type(wrapped) == __S("95cb36d03ed4c2ef0016de0e") then replacement = wrapped end
    end

    local ok, old = pcall(function()
        return hookmetamethod(game, __S("3402b081d79c647e41706fc58562"), replacement)
    end)
    if ok and type(old) == __S("d23a2a326a05efee99467f09") then
        originalNamecall = old
        HookRegistry.namecallActive = true
    end
end

HookRegistry.installNamecall()

                                                                              
                                                                               
                                                                                  
                                                                                 
                                         
                                                                                   
                                                                           
                                                                            
                                                                                
                                                                     
                                                                                
                                                                              

local FloorPad = { part = nil }

local function ensureFloorPad(offsetY)
    local root = getRoot()
    if not root then return nil end
    if not FloorPad.part or not FloorPad.part.Parent then
        local pad = Instance.new(__S("7071a3e315085109"))
        pad.Name = __S("0ea91d946a04cc4a8cec21cb4a7fe99edce719fdd7b0bfa0eb5c")
        pad.Size = Vector3.new(6, 0.4, 6)
        pad.Anchored = true
        pad.CanCollide = true
        pad.CanQuery = false
        pad.CanTouch = false
        pad.CastShadow = false
        pad.Massless = true
        pad.Transparency = 1
        pad.Material = Enum.Material.Plastic
        pad.Parent = Workspace
        FloorPad.part = pad
    end
    FloorPad.part.CFrame = CFrame.new(root.Position - Vector3.new(0, offsetY or 3.0, 0))
    return FloorPad.part
end

local function removeFloorPad()
    if FloorPad.part then
        pcall(function() FloorPad.part:Destroy() end)
        FloorPad.part = nil
    end
end

                                    
local function readFlyDirection()
    local cam = Workspace.CurrentCamera
    local dir = Vector3.zero
    if not cam then return dir, false end
    local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
    local pressed = false
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Vector3.new(look.X, 0, look.Z) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Vector3.new(look.X, 0, look.Z) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Vector3.new(right.X, 0, right.Z) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Vector3.new(right.X, 0, right.Z) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) pressed = true end
    if dir.Magnitude > 0 then dir = dir.Unit end
    return dir, pressed
end

local Fly = {
    conn           = nil,
    active         = false,
    parked         = false,
    bodyVel        = nil,
    bodyGyro       = nil,
    vel            = nil,
    autopilot      = nil,
    autopilotAt    = 0,
    autopilotSpeed = nil,
    manualHold     = 0,
    savedWalk      = nil,
}

local function flyDestroyBodies()
    if Fly.bodyVel then pcall(function() Fly.bodyVel:Destroy() end) Fly.bodyVel = nil end
    if Fly.bodyGyro then pcall(function() Fly.bodyGyro:Destroy() end) Fly.bodyGyro = nil end
end

local function flyEnsureBodies(root)
    if not root then return end

                                                                                
    if not (Fly.bodyGyro and Fly.bodyGyro.Parent == root) then
        if Fly.bodyGyro then pcall(function() Fly.bodyGyro:Destroy() end) end
        local bg = Instance.new(__S("ace09745232a8368efc50db8"))
        bg.Name = __S("4b1810f6867fe3c7d14ea3febc576b5daf8ab2")
        bg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
        bg.P = 3000
        bg.D = 120
        bg.CFrame = CFrame.lookAt(root.Position, root.Position + root.CFrame.LookVector)
        bg.Parent = root
        Fly.bodyGyro = bg
    end

                                                                              
                                                                                
    if Config.FlyBypassMode then
        if Fly.bodyVel then pcall(function() Fly.bodyVel:Destroy() end) Fly.bodyVel = nil end
    elseif not (Fly.bodyVel and Fly.bodyVel.Parent == root) then
        if Fly.bodyVel then pcall(function() Fly.bodyVel:Destroy() end) end
        local bv = Instance.new(__S("e94f8aa7a8e00e3cdbb8cf552d1f94f0"))
        bv.Name = __S("878704584db10c315f51ddaf9af90cd7c2355b3e0e0806")
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.P = 1250
        bv.Velocity = Vector3.zero
        bv.Parent = root
        Fly.bodyVel = bv
    end
end

local function flySetTarget(targetCFrame, speedOverride)
    if not targetCFrame then return end
    if Config.FlyJoinAutopilot == false then return end
    Fly.autopilot = targetCFrame.Position
    Fly.autopilotAt = os.clock()
    if speedOverride and tonumber(speedOverride) then
        Fly.autopilotSpeed = tonumber(speedOverride)
    end
end

local function flyClearTarget()
    Fly.autopilot = nil
    Fly.autopilotSpeed = nil
end

                                                                            
local function flyBrake(root)
    if Fly.bodyVel and Fly.bodyVel.Parent then
        Fly.bodyVel.Velocity = Vector3.zero
    end
    if root then
        SkillHubStep(__S("25be7e099b05c6701eaef7dcc3ff877f2d"), function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

local function flyDisable()
    if Fly.conn then
        pcall(function() Fly.conn:Disconnect() end)
        Fly.conn = nil
    end
    Fly.active = false
    Fly.parked = false
    Fly.manualHold = 0
    MovementLink.isFlyActive = function() return false end
    MovementLink.clearFlyTarget()
    flyBrake(getRoot())
    flyDestroyBodies()
    Fly.vel = nil
    Fly.autopilot = nil
    Fly.autopilotSpeed = nil

    local hum = getHumanoid()
    if hum and Fly.savedWalk then
        SkillHubStep(__S("c3f5f7ba369674fd04e292a7837511d212"), function()
            if hum.WalkSpeed == 0 then hum.WalkSpeed = Fly.savedWalk end
        end)
    end
    Fly.savedWalk = nil

    if not Config.WalkOnWater then removeFloorPad() end
end

local function flyStep(dt)
    local root, hum = getRoot(), getHumanoid()
    if not root or not hum or hum.Health <= 0 then flyDisable() return end

    flyEnsureBodies(root)
    hum.PlatformStand = false

                                                                                 
    if Config.FlyZeroWalkSpeed ~= false then
        if Fly.savedWalk == nil then Fly.savedWalk = hum.WalkSpeed end
        if hum.WalkSpeed ~= 0 then hum.WalkSpeed = 0 end
    end

    local speed = math.clamp(Fly.autopilotSpeed or Config.FlySpeed or 60, 10, 900)
    local dir, manual = readFlyDirection()
    if manual then
        Fly.manualHold = os.clock()
        Fly.autopilotSpeed = nil
        Fly.parked = false                                                         
    end

                                                                                 
                                                                              
                                                                              
                                                                               
    local autoPilotActive = false
    local manualRecently = (os.clock() - (Fly.manualHold or 0)) < math.clamp(Config.FlyHoldSeconds or 1.2, 0, 5)
    if not manual and not Fly.parked and not manualRecently and Fly.autopilot and (os.clock() - Fly.autopilotAt) < 1.5 then
        local delta = Fly.autopilot - root.Position
        if delta.Magnitude > 6 then
            dir = delta.Unit
            autoPilotActive = true
            if Config.FlyBypassMode then
                                                  
                speed = math.min(speed, math.max(delta.Magnitude * 2, 30))
            end
        elseif (os.clock() - Fly.autopilotAt) > 0.5 then
            Fly.autopilot = nil
            Fly.autopilotSpeed = nil
        end
    end

    local moving = manual or autoPilotActive
    local hovering = (not moving) and (Fly.parked or Config.FlyHoverIdle ~= false)
    local targetVel = moving and (dir * speed) or Vector3.zero

                                                                            
    local baseVel = Fly.vel or root.AssemblyLinearVelocity
    if Config.FlyBypassMode then
        local maxDelta = math.min(math.max(speed * 0.09, 5), 60)
        local delta = targetVel - baseVel
        if delta.Magnitude > maxDelta then targetVel = baseVel + delta.Unit * maxDelta end
                                                                                   
        local alpha
        if moving then
            alpha = math.clamp(dt * 14, 0.25, 0.9)
        elseif hovering then
            alpha = math.clamp(dt * 34, 0.45, 1)
        else
            alpha = math.clamp(dt * 12, 0.2, 0.7)
        end
        Fly.vel = baseVel:Lerp(targetVel, alpha)
        local snap = hovering and 4 or 0.8
        if Fly.vel.Magnitude < snap then Fly.vel = Vector3.zero end

                                                                                   
        root.AssemblyLinearVelocity = Fly.vel
    else
        Fly.vel = targetVel
        local bv = Fly.bodyVel
        if bv then bv.Velocity = targetVel else root.AssemblyLinearVelocity = targetVel end
    end

                                                                 
    local bg = Fly.bodyGyro
    if bg and bg.Parent then
        local face
        if manual and dir.Magnitude > 0.05 then
            face = Vector3.new(dir.X, 0, dir.Z)
        else
            local cam = Workspace.CurrentCamera
            local camLook = cam and cam.CFrame.LookVector or root.CFrame.LookVector
            face = Vector3.new(camLook.X, 0, camLook.Z)
        end
        if face.Magnitude < 0.05 then face = root.CFrame.LookVector end
        bg.CFrame = CFrame.lookAt(root.Position, root.Position + face.Unit)
    end

                                                                                
    ensureFloorPad(3.0)
    if hum:GetState() ~= Enum.HumanoidStateType.Running then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    end

                       
    if Config.FlyAntiVoid and root.Position.Y < -120 then
        Fly.vel = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = CFrame.new(root.Position.X, 60, root.Position.Z)
    end
end

                                                                                  
                                                                                  
local function flyPark(park)
    Fly.parked = park and true or false
    Fly.autopilot = nil
    Fly.autopilotSpeed = nil
    Fly.vel = Vector3.zero
    if Fly.parked then
        flyBrake(getRoot())
        MovementLink.clearFlyTarget()
        Hooks.notify(__S("622d716b4d404b752af538cbf005"), __S("0064eb1c37a6fa23da232a71f1afb830579fc26dc9edb104c9ae2eea1e0287c380d7eeff1a699a656072bd5a72288faa8f3bfc2b2704c793d8905d45cf66334c992f029d"), 3.5, CustomIcons.Stop)
    else
        Hooks.notify(__S("9e9c64cd693fcc"), __S("3cd3de7ea0a3404128c6f000df0080ccc44a3a18ac37196820d0208a02cd656c4d3235d58d509cc30611eafab6e819106afb84699d4004a21e68338b3ef9"), 2.5, CustomIcons.Fly)
    end
end

local function flyEnable()
    if Fly.active then return end
    Fly.active = true
    Fly.parked = false
    Fly.manualHold = 0
                                                                                  
                                                                 
    SkillHubStep(__S("db0b582f4e9f9748b78356a57c71"), function() stopTween() end)
    MovementLink.isFlyActive = function() return Fly.active end
    MovementLink.setFlyTarget = flySetTarget
    MovementLink.clearFlyTarget = flyClearTarget
    flyEnsureBodies(getRoot())
    Fly.conn = RunService.RenderStepped:Connect(function(dt)
        if not Config.FlyEnabled then flyDisable() return end
        pcall(function() flyStep(dt) end)
    end)
end

                                                       
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Config.FlyEnabled and not Fly.active then flyEnable() end
end)

local function setFlyState(enabled)
    Config.FlyEnabled = enabled
    if enabled then
        flyEnable()
        Hooks.notify(__S("7942d1e0ead9d6078fe40ecdd0dcafd3fef2"), __S("177a4b91737aeeb808024db517d268a7b88998ccaf28e9c59a7aece575837fb0c4a80a619249193f1d956e07602836178c651ac41ab765759adc9689873cdfc0075fd7e89f2bb0c444636ac4de794d38ad1528ecceddc1f82028727f10ff"), 4, CustomIcons.Fly)
    else
        flyDisable()
        Hooks.notify(__S("b5b1c5425b107aab5d70f05c5be8c419866b"), __S("53e93ef3ae17dd2220fec8"), 2, CustomIcons.Stop)
    end
end

                                     
task.spawn(function()
    while task.wait(0.12) do
        SkillHubStep(__S("f220b8a4937eedf537fae6dacc225b767c"), function()
            local hum, root = getHumanoid(), getRoot()
            local used = false
            if Config.WalkOnWater and hum and root then
                if hum.FloorMaterial == Enum.Material.Water or hum:GetState() == Enum.HumanoidStateType.Swimming then
                    ensureFloorPad(3.02)
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                    used = true
                end
            end
            if not used and not Config.FlyEnabled and FloorPad.part then removeFloorPad() end
        end)
    end
end)

                                                                                       
task.spawn(function()
    local lastGeppo = 0
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not Config.InfiniteGeppo then return end
        if input.KeyCode ~= Enum.KeyCode.Space and input.KeyCode ~= Enum.KeyCode.ButtonA then return end
        local hum, root = getHumanoid(), getRoot()
        if not hum or not root then return end
        if MovementLink.isFlyActive() then return end                           
        if hum:GetState() ~= Enum.HumanoidStateType.Freefall then return end
        local now = os.clock()
        if now - lastGeppo < 0.1 then return end
        lastGeppo = now
        SkillHubStep(__S("90583255b11406aff0c268204d219f910b"), function()
            pressKey(Enum.KeyCode.Space, 0.05)
            task.wait(0.05)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 68, root.AssemblyLinearVelocity.Z)
        end)
    end)
end)

                                                                                          
task.spawn(function()
    while task.wait(0.4) do
        if Config.InfiniteEnergy then
            SkillHubStep(__S("2e8fac06cc2d5fe76cabc060ce4f0807f3"), function()
                local data = LocalPlayer:FindFirstChild(__S("ccc725b72bad95d0"))
                if data then
                    for _, n in ipairs({ __S("6afe9f6884e6f28b7bbc"), __S("093619193eca88f299c3ebaab4"), __S("a76d92ca119733b1aa1911897323") }) do
                        local v = data:FindFirstChild(n)
                        if v and v:IsA(__S("45a50c7be05542bda68c0ec6fc7d3a")) then v.Value = 1000000 end
                    end
                end
                local char = getCharacter()
                local energy = char and char:FindFirstChild(__S("e3dc862ce5cb35bc74c2"))
                if energy and energy:IsA(__S("8213ffdd47aa6d0c53463a8d8eaa02")) then energy.Value = 1000000 end
                if Config.InfiniteEnergy then
                    invokeCommF(__S("204b798e11f78f79"))
                    if Config.AutoKen then invokeCommF(__S("be82f33fa6e287"), true) end
                end
            end)
        end
    end
end)

                        
task.spawn(function()
    local lastDash = 0
    while task.wait(0.05) do
        SkillHubStep(__S("5cba6cf04f95efdbdf776e58a19186cca8"), function()
            if not Config.NoDashCooldown then return end
            local hum, root = getHumanoid(), getRoot()
            if not hum or not root then return end
            if MovementLink.isFlyActive() then return end                                   
            if hum.MoveDirection.Magnitude < 0.1 then return end
            if hum:GetState() == Enum.HumanoidStateType.Freefall then return end
            local now = os.clock()
            if now - lastDash < (Config.DashInterval or 0.32) then return end
            lastDash = now
            local kick = hum.MoveDirection * 46
            root.AssemblyLinearVelocity = Vector3.new(kick.X, root.AssemblyLinearVelocity.Y, kick.Z)
            SkillHubStep(__S("faf1e6a1be07da3821af41c1e3ac64300c"), function()
                local rem = ReplicatedStorage:FindFirstChild(__S("99296052f1aa92d18f5ac6"))
                local commE = rem and rem:FindFirstChild(__S("3760da0330219e6264"))
                if commE then commE:FireServer(__S("d59853b467bcd8ff")) end
            end)
        end)
    end
end)

                                                                              
                                                                                    
                                                                              

local function magnetPart(handle, tweenFallback)
    local root = getRoot()
    if not handle or not root then return end
    if firetouchinterest then
        SkillHubStep(__S("73cfcd65b9db5cbc5da19c8bcacb066492"), function()
            firetouchinterest(root, handle, 0)
            firetouchinterest(root, handle, 1)
        end)
        SkillHubStep(__S("1207471689262dea18c84c6b84bfc70f3a"), function()
            firetouchinterest(handle, root, 0)
            firetouchinterest(handle, root, 1)
        end)
    end
    pcall(function()
        handle.CanCollide = false
        handle.AssemblyLinearVelocity = Vector3.zero
        handle.CFrame = root.CFrame * CFrame.new(0, -1.2, 0)
    end)
    if tweenFallback then tweenTo(root.CFrame) end
end

local function findFruitHandles(radius)
    local root = getRoot()
    local found = {}
    if not root then return found end
    local maxDist = radius or Config.FruitMagnetRadius or 600
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA(__S("b03ec0c700cc16fa")) or obj:IsA(__S("4e763a782906877f67")) or obj.Name:lower():find(__S("ecadb429fbf934830e"), 1, true) then
            local handle = obj:FindFirstChild(__S("8ae52dda9db1387667b5")) or obj:FindFirstChildWhichIsA(__S("291ca78b9f1e5e48266a9c65"))
            if handle and (handle.Position - root.Position).Magnitude <= maxDist then
                table.insert(found, { obj = obj, handle = handle, dist = (handle.Position - root.Position).Magnitude })
            end
        end
    end
    return found
end

task.spawn(function()
    while task.wait(0.05) do
        if Config.FruitMagnet then
            SkillHubStep(__S("c754213c48070b4d794e46845124898967"), function()
                for _, entry in ipairs(findFruitHandles()) do
                    magnetPart(entry.handle, false)
                end
            end)
        end
    end
end)

                                                                 
task.spawn(function()
    while task.wait(0.3) do
        if Config.AutoCollectDrops then
            SkillHubStep(__S("658b9aed2b7b842c671eb3708e31067ef2"), function()
                local root = getRoot()
                if not root then return end
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA(__S("03c3149ea2f0dc6b")) then
                        local handle = obj:FindFirstChild(__S("a1fa8e4fdef66679b243"))
                        if handle and (handle.Position - root.Position).Magnitude <= 900 then magnetPart(handle, false) end
                    elseif obj:IsA(__S("40320800f4b4b1b620")) then
                        local name = obj.Name:lower()
                        if name:find(__S("de6981b13a8b161c"), 1, true) or name:find(__S("7ca0fb6276af5f78c395"), 1, true) or name:find(__S("1ad875138d34d89b50"), 1, true) then
                            local handle = obj:FindFirstChildWhichIsA(__S("b90feec40d25fb503bd959c0"))
                            if handle and (handle.Position - root.Position).Magnitude <= 250 then magnetPart(handle, false) end
                        end
                    end
                end
            end)
        end
    end
end)

                                                                              
                                                                       
                                                                              

                                                                               
                                                                               
                                                                                
                                                                           
                                                                              
                                                        
                                                  
                                                                          
                                                                               
                                          
local watchedContainers = {}
local FRUIT_SEEN = setmetatable({}, { __mode = __S("574768751a") })
local FRUIT_LAST_NAME = {}
local FRUIT_LAST_REMOVED = {}
local FRUIT_REPEAT_WINDOW = 60
local FRUIT_MOVE_WINDOW = 8

local function fruitToolName(tool)
    local original = tool:GetAttribute(__S("f57ee226948ab14f22b2a478b75da0f3"))
    local name = tostring(original or tool.Name or __S("93b65bd7ae"))
    name = name:gsub(__S("31edd588c669120d53bd"), "")
    name = name:gsub(__S("d0254f398694505b"), ""):gsub(__S("6e5cc8ea2fc6e0c5"), "")
    return name
end

local function isFruitTool(tool)
    if not tool or not tool:IsA(__S("0c94429bac3df6ef")) then return false end
    if tool:GetAttribute(__S("aacbbc4c02ef14503b87f39efae43da5")) ~= nil then return true end
    if tool:GetAttribute(__S("490335fd0a622c5518b809")) == true then return true end
    if tool:FindFirstChild(__S("e73aafaea1824360b9e2")) == nil then return false end
    if toolMatchesCategory(tool, __S("8572295f51385588baf9d53cdbf9")) then return true end
    if FRUIT_RARITY_OF[tool.Name] ~= nil then return true end
    return tool.Name:lower():find(__S("23a9a31033fd58fac6"), 1, true) ~= nil
end

                                                    
local function announceFruit(tool, containerLabel)
    local name = fruitToolName(tool)
    local now = os.clock()
    local known = FRUIT_SEEN[tool] == true
    FRUIT_SEEN[tool] = true
    if known then return false end
    if containerLabel ~= __S("c1e11cc11fb19337be4902ac") then return false end
    if FRUIT_LAST_REMOVED[name] and (now - FRUIT_LAST_REMOVED[name]) < FRUIT_MOVE_WINDOW then return false end
    local previous = FRUIT_LAST_NAME[name]
    if previous and (now - previous) < FRUIT_REPEAT_WINDOW then return false end
    FRUIT_LAST_NAME[name] = now
    Config.RolledFruitName = name
    if Config.FruitNotify == false then return true end
    Hooks.notify(__S("601896727f6d1de908bdc3e173e17ad5d441"), name .. __S("fe50102309b10a442d5ba5e74b1f6b1c6ac9b5") .. getFruitTier(name).name, 4, CustomIcons.Fruits)
    return true
end

local function bindFruitWatcher(container, label)
    if not container or watchedContainers[container] then return end
    watchedContainers[container] = true
    container.ChildAdded:Connect(function(tool)
        task.wait(0.15)
        pcall(function()
            if not isFruitTool(tool) then return end
            if not announceFruit(tool, label) then return end
            if Config.AutoStoreRolled and Config.AutoStoreFruits ~= false and label == __S("9c8789d408a2b86660c6cf5c") then
                local fruitName = fruitToolName(tool)
                local code = FRUIT_STORE_CODES[fruitName] or (fruitName .. __S("3abf03858f") .. fruitName)
                task.wait(0.35)
                invokeCommF(__S("d8f67d360ddc80b6034e95425c2a"), code, tool)
            end
        end)
    end)
    container.ChildRemoved:Connect(function(tool)
        if tool and tool:IsA(__S("772df6e7ab8073e1")) then
            FRUIT_LAST_REMOVED[fruitToolName(tool)] = os.clock()
        end
    end)
end

local function bindAllFruitWatchers()
    bindFruitWatcher(LocalPlayer:FindFirstChild(__S("1565709801af77f05db045df")), __S("b39cea4901816ef6c7ee4314"))
    bindFruitWatcher(LocalPlayer.Character, __S("51d463fa8c0a39d19b0d3c23f1"))
end
bindAllFruitWatchers()
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    bindFruitWatcher(LocalPlayer:FindFirstChild(__S("f00bddabb6aa0abfc52fa532")), __S("8e43575c4a37d9d0a6799964"))
    bindFruitWatcher(char, __S("2c7ad10d635375ca9bc9ec5486"))
end)

                                                                              
                                                      
                                                                              

local function scanSeaEvents()
    local myRoot = getRoot()
    local found = {}
    local scanRoots = {}
    for _, child in ipairs(Workspace:GetChildren()) do table.insert(scanRoots, child) end
    for _, folderName in ipairs({ __S("cab24abe89e07066ce71d6"), __S("68e9c46fbe982603a3bead8837b4"), __S("07213e205c43bb2f"), __S("a558b7d14ddc4e"), __S("439031825be595d5d85942"), __S("e1c7ab335c2836cf927e934c30bf23c2") }) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then table.insert(scanRoots, folder) end
    end

    local visited = {}
    local function inspect(obj)
        if visited[obj] then return end
        visited[obj] = true
        local name = obj.Name
        if type(name) ~= __S("7fff24e486916e18a941") or #name < 4 then return end
        local lower = name:lower()
        for _, sig in ipairs(SEA_EVENT_SIGNATURES) do
            for _, key in ipairs(sig.Keys) do
                if lower:find(key, 1, true) then
                    local part = obj:IsA(__S("1e369e95c5198c085ce224db")) and obj or obj:FindFirstChildWhichIsA(__S("bc6e184617dcc0e2f390067e"))
                    if part then
                        table.insert(found, {
                            name = sig.Name, color = sig.Color, pos = part.Position,
                            obj = part, dist = myRoot and math.floor((part.Position - myRoot.Position).Magnitude) or 0,
                        })
                    end
                    return
                end
            end
        end
    end

    pcall(function()
        for _, top in ipairs(scanRoots) do
            inspect(top)
            for _, child in ipairs(top:GetChildren()) do
                inspect(child)
                for _, grand in ipairs(child:GetChildren()) do inspect(grand) end
            end
        end
    end)
    return found
end

task.spawn(function()
    while task.wait(3.5) do
        SkillHubStep(__S("5aa591f79749aa7a555cffc89edaccfd05"), function()
            if not Config.SeaEventTracker and not Config.MirageFinder then return end
            local events = scanSeaEvents()
            SeaEventState.events = events
            local mirage = {}
            for _, ev in ipairs(events) do
                if ev.name == __S("f8dd0ba8b1ec9570f6a0f44298e0d5f4af") or ev.name == __S("971485590d8e93cf65bf1bf81bb23f2a6b59") or ev.name == __S("354bff0afd34ad525a81126b0a9c7a9bae88ec563fce") or ev.name == __S("d38378bb81609b613de0d6f2baaa46f3dcc90ad97d25") then
                    table.insert(mirage, ev)
                end
            end
            SeaEventState.mirage = mirage

            if Config.SeaEventTracker then
                for _, ev in ipairs(events) do
                    local key = ev.name .. math.floor(ev.pos.X / 500) .. math.floor(ev.pos.Z / 500)
                    if not SeaEventState.lastNotify[key] then
                        SeaEventState.lastNotify[key] = true
                        local isSpecial = ev.name ~= __S("71baf26c3458a1fde63800da87b735ae97767dff")
                        if isSpecial or Config.MirageFinder then
                            Hooks.notify(ev.name .. __S("0ff26c1da53fcfaf6251549552"), string.format(__S("ae29e5ce632852461a53713953d92c32a7567efa125414fd66d4970d461bfc40"), ev.dist, ev.pos.X, ev.pos.Z), 4, CustomIcons.Teleport)
                        end
                    end
                end
            end
        end)
    end
end)

                                                                              
                                                              
                                                                              

local function getServerStatus()
    local ping = 0
    pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem[__S("4c615f7ffccd845806af630b4b")]:GetValue()) end)
    local region = __S("ea98d93030")
    pcall(function() region = tostring(game:GetService(__S("88d052e10b19cd3a436dd5a18b82bbf142af9c1494f861")).RobloxLocaleId) end)
    return {
        jobId = (game.JobId ~= "" and game.JobId:sub(1, 8)) or __S("2707cc928833afe9ec4947"),
        players = #Players:GetPlayers(),
        maxPlayers = Players.MaxPlayers,
        ping = ping,
        region = region,
        sea = CURRENT_SEA,
        source = SEA_DETECT_SOURCE,
        events = #(SeaEventState.events or {}),
        up = math.floor(time() - (game:GetService(__S("c53f4643ea5e23963c5b97746ffa")):IsStudio() and time() or 0)),
    }
end

                                                                                      
task.spawn(function()
    for _ = 1, 40 do
        task.wait(1.5)
        SkillHubStep(__S("6376bff4dd0847a6888fb05537a3b6ed12"), function()
            local before = CURRENT_SEA
            refreshSea()
            if CURRENT_SEA ~= before then
                LocalPlayer:SetAttribute(__S("01ae39a5bb9f11540a18e1ea2f46cc"), CURRENT_SEA)
            else
                LocalPlayer:SetAttribute(__S("9fe5b356e2d01b9bd8f04e98a7aef2"), CURRENT_SEA)
            end
        end)
    end
end)

                                                                              
                            
                                                                              

task.spawn(function()
    while task.wait(0.12) do
        SkillHubStep(__S("3e1d2d079421fdf362aff726560b8c8715"), function()
            local char = getCharacter()
            local root = getRoot()
            local hum  = getHumanoid()
            if not char or not root or not hum or hum.Health <= 0 then return end

            if Config.AutoFarmLevel then
                ensureBuso()
                equipWeaponByType(Config.SelectedWeaponType)
                local qData = getQuestForLevel(getPlayerLevel())
                local pGui = LocalPlayer:FindFirstChild(__S("dc54a6b889b1eb57a276080335"))
                local mainGui = pGui and pGui:FindFirstChild(__S("7a8c2069445f2fb8"))
                local questFrame = mainGui and mainGui:FindFirstChild(__S("18c39a1acbc824d32a"))

                if questFrame and not questFrame.Visible then
                    tweenTo(qData.QPos)
                    if (root.Position - qData.QPos.Position).Magnitude < 20 then
                        invokeCommF(__S("b6fb13cb9992008abf56638021fe"), qData.Quest, qData.QNum)
                    end
                else
                    local enemies = Workspace:FindFirstChild(__S("55328d7c37754c553d3714"))
                    local targetMob = nil
                    if enemies then
                        for _, mob in ipairs(enemies:GetChildren()) do
                            local mHum = mob:FindFirstChildOfClass(__S("f36a072de2ddcd37b175fa62"))
                            local mHrp = mob:FindFirstChild(__S("91a180de2b4c9ee175f456da9889e2f6a420ea84"))
                            if mob.Name == qData.Mob and mHum and mHum.Health > 0 and mHrp then
                                targetMob = mob
                                break
                            end
                        end
                    end

                    if targetMob then
                        local mHrp = targetMob.HumanoidRootPart
                        tweenTo(mHrp.CFrame * CFrame.new(0, Config.FarmDistance, 0))
                        bringNearbyMobs(qData.Mob, mHrp.Position)
                        if Config.FastAttack then triggerFastAttack() end
                    else
                        tweenTo(qData.MPos * CFrame.new(0, Config.FarmDistance, 0))
                    end
                end

            elseif Config.AutoFarmNearest then
                ensureBuso()
                equipWeaponByType(Config.SelectedWeaponType)
                local enemies = Workspace:FindFirstChild(__S("2fd8fa8fee0b0b2b4a9c7d"))
                local nearest, minDist = nil, math.huge
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mHum = mob:FindFirstChildOfClass(__S("ce107440c44c57527fbbec18"))
                        local mHrp = mob:FindFirstChild(__S("6c47edf1e59692d691a4aa1f24c3c63447b03a98"))
                        if mHum and mHum.Health > 0 and mHrp then
                            local d = (mHrp.Position - root.Position).Magnitude
                            if d < minDist then
                                minDist = d
                                nearest = mob
                            end
                        end
                    end
                end
                if nearest then
                    local mHrp = nearest.HumanoidRootPart
                    tweenTo(mHrp.CFrame * CFrame.new(0, Config.FarmDistance, 0))
                    bringNearbyMobs(nearest.Name, mHrp.Position)
                    if Config.FastAttack then triggerFastAttack() end
                end

            elseif Config.AutoFarmBoss or Config.AutoFarmAllBosses then
                ensureBuso()
                equipWeaponByType(Config.SelectedWeaponType)
                local enemies = Workspace:FindFirstChild(__S("0a7f67a242f909ac1ea60d"))
                local targetBoss = nil
                local seaBosses = BOSSES_BY_SEA[CURRENT_SEA] or {}

                local selectedBossName = tostring(Config.SelectedBoss):gsub(__S("a8b6e153e380562a8907a058602a2c"), "")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mHum = mob:FindFirstChildOfClass(__S("46ee5b04eb428d51f2685a77"))
                        local mHrp = mob:FindFirstChild(__S("e525d4b5a4dbd5c777a27b73eb007954f2240c40"))
                        if mHum and mHum.Health > 0 and mHrp then
                            if Config.AutoFarmBoss and mob.Name:find(selectedBossName, 1, true) then
                                targetBoss = mob
                                break
                            elseif Config.AutoFarmAllBosses then
                                local allBossNames = {}
                                for seaIdx = 1, 3 do
                                    for _, bName in ipairs(BOSSES_BY_SEA[seaIdx] or {}) do table.insert(allBossNames, bName) end
                                end
                                for _, bName in ipairs(allBossNames) do
                                    if mob.Name:find(bName, 1, true) then
                                        targetBoss = mob
                                        break
                                    end
                                end
                            end
                        end
                    end
                end

                if targetBoss then
                    local mHrp = targetBoss.HumanoidRootPart
                    tweenTo(mHrp.CFrame * CFrame.new(0, Config.FarmDistance, 0))
                    if Config.FastAttack then triggerFastAttack() end
                end
            end
        end)
    end
end)

                                        
task.spawn(function()
    while task.wait(0.35) do
        SkillHubStep(__S("835d4e66831042b323531b01ef86d098b1"), function()
            local keys = {
                {Enabled = Config.AutoSkillComboZ, Key = Enum.KeyCode.Z},
                {Enabled = Config.AutoSkillComboX, Key = Enum.KeyCode.X},
                {Enabled = Config.AutoSkillComboC, Key = Enum.KeyCode.C},
                {Enabled = Config.AutoSkillComboV, Key = Enum.KeyCode.V},
            }
            for _, k in ipairs(keys) do
                if k.Enabled then
                    pressKey(k.Key, 0.08)
                    task.wait(0.08)
                end
            end

            if Config.SovereignHakiAura then
                local root = getRoot()
                if root then
                    local offset = Vector3.new(math.random(-30, 30) / 10, -2.5, math.random(-30, 30) / 10)
                    local spark = Instance.new(__S("2194c8178cccf6b4"))
                    spark.Anchored = true
                    spark.CanCollide = false
                    spark.Shape = Enum.PartType.Ball
                    spark.Material = Enum.Material.Neon
                    spark.Color = Color3.fromRGB(56, 189, 248)
                    spark.Size = Vector3.new(0.6, 1.8, 0.6)
                    spark.CFrame = CFrame.new(root.Position + offset)
                    spark.Transparency = 0.2
                    spark.Parent = Workspace
                    SafeTween(spark, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
                        CFrame = spark.CFrame + Vector3.new(0, 6, 0),
                        Transparency = 1,
                        Size = Vector3.new(0.1, 3.8, 0.1),
                    }):Play()
                    Debris:AddItem(spark, 0.55)
                end
            end
        end)
    end
end)

                  
task.spawn(function()
    while task.wait(0.4) do
        SkillHubStep(__S("bfcc41c81f3bbbabdff7687c9a4d4c4bd4"), function()
            local batch = Config.StatPointsBatch
            if Config.AutoStatMelee   then invokeCommF(__S("5e03bb796e37327dec3d0fa8"), __S("fc3b352a88e00f9191"), batch) end
            if Config.AutoStatDefense then invokeCommF(__S("9a72aedbaeabf4a18ed07a3e"), __S("38aa288c35f74ef800d080"), batch) end
            if Config.AutoStatSword   then invokeCommF(__S("d6e1a23def14956aabb29caa"), __S("75191bee0f63a22239"), batch) end
            if Config.AutoStatGun     then invokeCommF(__S("1350959fefc655b61b5cda2d"), __S("b1880f5006b40f"), batch) end
            if Config.AutoStatFruit   then invokeCommF(__S("4fbf8901cf626701c27bd76c"), __S("edf702b266815d0cfd21f67934e169"), batch) end
        end)
    end
end)

                           
task.spawn(function()
    while task.wait(1.2) do
        SkillHubStep(__S("8c2e7c639f3ed6dddbb2ac7e0c10015cc3"), function()
            if Config.AutoSniperStock then
                invokeCommF(__S("2a65f614e008d0a005ae42d8c6"))
                invokeCommF(__S("c89d6fc5c756e8f5c543fbb5acc153fdee1028db"), Config.SelectedFruit, false)
            end
            if Config.AutoRandomFruit then
                invokeCommF(__S("66d4e976a822a410dcbd"), __S("050c6327b161cb"))
            end
            if Config.AutoGrabMapFruits then
                local root = getRoot()
                if root then
                    for _, obj in ipairs(Workspace:GetChildren()) do
                        if obj:IsA(__S("a343dcd860dfc26d")) or obj.Name:lower():find(__S("417b5689ba10c380f1")) then
                            local handle = obj:FindFirstChild(__S("dfb2d03aa8c8fac58d98"))
                            if handle and handle:IsA(__S("7dea49ebc2c1e92ecb3dd61e")) then
                                tweenTo(handle.CFrame)
                                break
                            end
                        end
                    end
                end
            end
            if Config.AutoStoreFruits then
                local containers = {LocalPlayer:FindFirstChild(__S("1c21c39c570929c526be2c60")), getCharacter()}
                for _, container in ipairs(containers) do
                    if container then
                        for _, tool in ipairs(container:GetChildren()) do
                            if tool:IsA(__S("ba593d4d41feb04f")) and tool.Name:find(__S("5890b6febf76d997c3")) then
                                local cleanName = tool.Name:gsub(__S("f6c830afc17d6e584064"), "")
                                local code = FRUIT_STORE_CODES[cleanName] or (cleanName .. __S("94ffaa60b4") .. cleanName)
                                invokeCommF(__S("33372411f899b46a63b875406377"), code, tool)
                            end
                        end
                    end
                end
            end
            if Config.AutoBuyRaidChip then
                invokeCommF(__S("d16e9dc2db961e49d1fe12cc"), __S("6fa6177364873e6ad351"), Config.SelectedRaidChip)
            end
            if Config.AutoAwaken then
                invokeCommF(__S("0ddd9124993a56b9071a85e3"), __S("ac150ad571a44af17e"))
                invokeCommF(__S("4a4c8486a93dc95399ac164a"), __S("e883fe3774e66d1380d7"))
            end
            if Config.AutoRaidAura then
                local enemies = Workspace:FindFirstChild(__S("86bb77e8ee6c8eabda0968"))
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local hum = mob:FindFirstChildOfClass(__S("24f2f19991af69a212bb640f"))
                        if hum and hum.Health > 0 then
                            pcall(function() hum.Health = 0 end)
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        SkillHubStep(__S("c32a6b4a66ed26ea37abdabcfad5c552bd"), function()
            if Config.AutoFarmChests then
                local root = getRoot()
                if root then
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA(__S("6161e4fbc678a45fa4962286")) and (v.Name == __S("ff995eac89733808b4e9") or v.Name == __S("9dd0d85d73f50f09d61e") or v.Name == __S("3c08520e2978a747691f")) then
                            tweenTo(v.CFrame)
                            break
                        end
                    end
                end
            end
            local hum = getHumanoid()
            if hum then
                                                                                       
                if Config.WalkSpeedEnabled and not Config.FlyEnabled then hum.WalkSpeed = Config.WalkSpeedValue end
                if Config.JumpPowerEnabled then hum.JumpPower = Config.JumpPowerValue end
            end
            if Config.AutoKen then invokeCommF(__S("da3fcbbf30cefb"), true) end
            if Config.AutoRaceV3 then
                local rem = ReplicatedStorage:FindFirstChild(__S("78774570cecc6d04e39ed2"))
                local commE = rem and rem:FindFirstChild(__S("16aebf2147511076a1"))
                if commE then commE:FireServer(__S("b4e638d2ed3fd79553ee953501f6b8f40f4aa4")) end
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    if Config.NoClip or Config.AutoFarmLevel or Config.AutoFarmBoss or Config.AutoFarmAllBosses then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA(__S("531db283c7f04ce252277b4c")) and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if not Config.AntiAFK then return end
    if VirtualUser and Config.UseVirtualInput ~= false then
        SkillHubStep(__S("f1552c349c7dc3f1b9300c5921a30fbbb772500b3a485aa5ad539ebe"), function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    else
                                                                           
                                                                            
                                             
        SkillHubStep(__S("8f8ca5e5bc56227a3cfc7c93fe316787"), function()
            local char = getCharacter()
            local hrp = char and char:FindFirstChild(__S("2dc41f966539f3214b19fd3a0a9acb8ceb746214"))
            local hum = char and char:FindFirstChildOfClass(__S("cbfb9947a6ae08f86b38f20b"))
            if hum and hrp then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 0.05, 0)
            end
        end)
    end
end)

                                                                              
              
                                                                              

local ESPFolder = Instance.new(__S("6a3312f84846f6932316"))
ESPFolder.Name = __S("086a8ca9c553ec3803b89a6bf454a0c91774d0")
                                                                             
pcall(function() ESPFolder.Parent = LocalPlayer:WaitForChild(__S("a6a2065afe8f22e0184dcb60e4")) end)

                                                                               
                                                                               
                                                                                
                                                                              
                                                                    
local espPool, espStamp = {}, 0

local function clearESP()
    for key, entry in pairs(espPool) do
        if entry.bb and entry.bb.Parent then entry.bb:Destroy() end
        espPool[key] = nil
    end
    ESPFolder:ClearAllChildren()
end

local function sweepESP()
    for key, entry in pairs(espPool) do
        if entry.stamp ~= espStamp then
            if entry.bb and entry.bb.Parent then entry.bb:Destroy() end
            espPool[key] = nil
        end
    end
end

local function createESPBillboard(adornee, titleText, subText, color, bodyText, height)
    if not adornee then return nil end

                                                                                 
    local entry = espPool[adornee]
    if not entry or not entry.bb or not entry.bb.Parent then
        entry = { bb = nil, main = nil, sub = nil, body = nil }
        espPool[adornee] = entry
    end
    entry.stamp = espStamp

    if entry.bb then
        if entry.main then
            entry.main.Text = titleText
            entry.main.TextColor3 = color
        end
        if entry.sub then entry.sub.Text = subText or "" end
        if entry.body then
            entry.body.Visible = bodyText ~= nil
            if bodyText then entry.body.Text = bodyText end
        end
        return entry.bb
    end

    local bb = Instance.new(__S("44d9800bc5a784b6a2dbbc8da0f9b110"))
    bb.Name = __S("e310f9bc0a5bba3855c71b")
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 200, 0, height or (bodyText and 72 or 42))
    bb.StudsOffset = Vector3.new(0, 3.6, 0)
    bb.AlwaysOnTop = true
    bb.Parent = ESPFolder

    local mainLbl = Instance.new(__S("8148736d4ba0817580e3cd87d3"), bb)
    mainLbl.Size = UDim2.new(1, 0, 0, bodyText and 20 or 22)
    mainLbl.BackgroundTransparency = 1
    mainLbl.Font = Enum.Font.GothamBold
    mainLbl.TextSize = 13
    mainLbl.TextColor3 = color
    mainLbl.TextStrokeTransparency = 0.25
    mainLbl.Text = titleText

    local subLbl = Instance.new(__S("1f7fed1e2419d094b68a627c6f"), bb)
    subLbl.Size = UDim2.new(1, 0, 0, bodyText and 16 or 18)
    subLbl.Position = UDim2.new(0, 0, 0, bodyText and 20 or 23)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.TextSize = 11
    subLbl.TextColor3 = Color3.fromRGB(226, 232, 240)
    subLbl.TextStrokeTransparency = 0.35
    subLbl.Text = subText or ""

    local bodyLbl = Instance.new(__S("bdb766cf2c17d1cdfe498061d2"), bb)
    bodyLbl.Size = UDim2.new(1, 0, 0, 36)
    bodyLbl.Position = UDim2.new(0, 0, 0, 36)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Font = Enum.Font.Gotham
    bodyLbl.TextSize = 10
    bodyLbl.TextWrapped = true
    bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
    bodyLbl.TextColor3 = Color3.fromRGB(203, 213, 225)
    bodyLbl.TextStrokeTransparency = 0.45
    bodyLbl.Text = bodyText or ""
    bodyLbl.Visible = bodyText ~= nil

    entry.bb = bb
    entry.main = mainLbl
    entry.sub = subLbl
    entry.body = bodyLbl

    return bb
end

                                                                                    
local tracerCache = {}
local function updateTracer(key, fromPos, toPos, color, visible)
    if not Drawing or not Drawing.new then return end
    local line = tracerCache[key]
    if not line then
        local ok, created = pcall(function() return Drawing.new(__S("5beee080d34a80f3")) end)
        if not ok or not created then return end
        created.Thickness = 1
        created.Transparency = 0.65
        tracerCache[key] = created
        line = created
    end
    line.From = fromPos
    line.To = toPos
    line.Color = color
    line.Visible = visible and true or false
end

local function clearTracers()
    for key, line in pairs(tracerCache) do
        pcall(function() line:Remove() end)
        tracerCache[key] = nil
    end
end

task.spawn(function()
    while task.wait(0.9) do
        SkillHubStep(__S("fa265a31ccfcc4dc69863998283cc3bd6e"), function()
            local myRoot = getRoot()
            local cam = Workspace.CurrentCamera
            if not myRoot or os.clock() < RespawnQuietUntil then return end

                                                                               
            espStamp = os.clock()
            trace(__S("985dd3e2d722dc40a6b4ec42"))

            if not Config.ESPTracers then
                for _, line in pairs(tracerCache) do pcall(function() line.Visible = false end) end
            end

                                                                               
            if Config.ESPPlayers then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hrp = plr.Character:FindFirstChild(__S("36954d934810a9fa7d22402d8f4e498e23b0c99d"))
                        local hum = plr.Character:FindFirstChildOfClass(__S("d4ccc744de6e54f7f210f244"))
                        if hrp and hum and hum.Health > 0 then
                            local dist = math.floor((hrp.Position - myRoot.Position).Magnitude)
                            local attackable, statusText, statusColor = getPvPStatus(plr)
                            local loadout = getPlayerLoadout(plr)
                            local title = string.format(__S("730440f55d689fba7928015a"), plr.DisplayName, tostring(loadout.level))
                            local sub = string.format(__S("113bbaa6949a99b7e5db92488223090f"), statusText, dist)

                            local body = nil
                            if Config.ESPPlayerLoadout then
                                body = string.format(
                                    "Fruit: %s (%s)\nStyle: %s  •  Sword: %s  •  Gun: %s\nHP: %d/%d  •  Bounty: %s",
                                    loadout.fruit, getFruitTier(loadout.fruit).name,
                                    loadout.style, loadout.sword, loadout.gun,
                                    math.floor(hum.Health), math.floor(hum.MaxHealth), loadout.bounty
                                )
                            end

                            createESPBillboard(hrp, title, sub, statusColor, body)
                            if Config.ESPTracers and cam then
                                updateTracer(__S("af733457bb9c7a0e") .. plr.Name, cam.ViewportSize / 2, (hrp.Position - myRoot.Position), statusColor, true)
                            end
                        end
                    end
                end
            end

                                                                              
            if Config.ESPFruits then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA(__S("4daaae08c9445357")) or obj.Name:lower():find(__S("ebe227b935bbfc64d1"), 1, true) then
                        local handle = obj:FindFirstChild(__S("8a19a16a3887d7002660")) or obj:FindFirstChildWhichIsA(__S("28511b1b80f1805458abdc40"))
                        if handle then
                            local dist = math.floor((handle.Position - myRoot.Position).Magnitude)
                            local fruitName = tostring(obj:GetAttribute(__S("c68894cc0bad46585103777fdd91157c")) or obj.Name):gsub(__S("64c00e7d9a59df6af0c0"), "")
                            local tier = getFruitTier(fruitName)
                            local color = Config.ESPFruitRarity and tier.color or Color3.fromRGB(250, 204, 21)
                            createESPBillboard(handle, fruitName .. __S("02f7882e17d8c21b41b3"), string.format(__S("a12f01dfd07fe6f5792745d5262bf9017198395645932211735cbdac"), tier.name, dist), color)
                        end
                    end
                end
            end

                                                                              
            if Config.ESPChests then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA(__S("3f667b90985c0ab97e3b245f")) and (obj.Name == __S("dd9df541f86c7e4f9ffa") or obj.Name == __S("7bd56ef2549f1fe63a9a") or obj.Name == __S("1a0ce8a38c2bc8d1ca01")) then
                        local dist = math.floor((obj.Position - myRoot.Position).Magnitude)
                        if dist < 2500 then
                            local label = obj.Name == __S("b8446254709084a5d308") and __S("567bdc05bc054ec1fdccc73d0994bde60e") or (obj.Name == __S("f4b355b677c07ffb53ac") and __S("92eacf67232a17e47c45a560382c") or __S("312249184bc7b75e11b298721e2d44f7"))
                            createESPBillboard(obj, label, string.format(__S("cf59c2c94c428198860c0c5f"), dist), Color3.fromRGB(74, 222, 128))
                        end
                    end
                end
            end

                                                                              
            if Config.ESPIslands then
                local map = Workspace:FindFirstChild(__S("6d913c7a8a5562c19847d0500c947566")) and Workspace._WorldOrigin:FindFirstChild(__S("0bc8b62b4129afdf4723e5649f"))
                if map then
                    for _, loc in ipairs(map:GetChildren()) do
                        if loc:IsA(__S("aa002fdc4382679f69018be9")) then
                            local dist = math.floor((loc.Position - myRoot.Position).Magnitude)
                            local lower = loc.Name:lower()
                            local color, tag = Color3.fromRGB(167, 139, 250), __S("4837a98d87b7ed7456ea")
                            if lower:find(__S("e66f233e172e345aba53")) then color, tag = Color3.fromRGB(244, 114, 182), __S("84a69cef7fe0e1cc523f")
                            elseif lower:find(__S("22de16a06e2f65ba749538")) then color, tag = Color3.fromRGB(250, 204, 21), __S("c115905155017f6d8e643b")
                            elseif lower:find(__S("5f4d0a02f45bf0adfb49f2d01de1f2")) then color, tag = Color3.fromRGB(74, 222, 128), __S("fd8483b35a8c475a59bae0b7848911")
                            elseif lower:find(__S("9bbbfd64fb35b449")) then color, tag = Color3.fromRGB(56, 189, 248), __S("39f377156930ee85de5514b81344c9af") end
                            createESPBillboard(loc, loc.Name, string.format(__S("d82af0c61ab10b588ea53ce40bf6c88366415eaa8f"), tag, dist), color)
                        end
                    end
                end
            end

                                                                             
            if (Config.SeaEventTracker or Config.MirageFinder) and #(SeaEventState.events or {}) > 0 then
                for idx, ev in ipairs(SeaEventState.events) do
                    if ev.obj and ev.obj.Parent then
                        local dist = math.floor((ev.obj.Position - myRoot.Position).Magnitude)
                        if dist < 4000 then
                            createESPBillboard(ev.obj, ev.name, string.format(__S("76626a77843422bb7ed3529fed85893f4f99b8a2b079e6eb"), dist), ev.color)
                        end
                    end
                end
            end

                                                                              
            if Config.ESPBosses then
                local enemies = Workspace:FindFirstChild(__S("1499e428a327370ea9702b"))
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local hrp = mob:FindFirstChild(__S("b2d15dd9a4c1e2446d0c67decfb6247bf2873ad4"))
                        local hum = mob:FindFirstChildOfClass(__S("5108d78afe2f6bff72021a39"))
                        if hrp and hum and hum.Health > 0 then
                            local dist = math.floor((hrp.Position - myRoot.Position).Magnitude)
                            createESPBillboard(hrp, mob.Name, string.format(__S("ef40513bc0d7ec98eaaa6ad94bebce91cfdc9564"), math.floor(hum.Health), dist), Color3.fromRGB(248, 113, 113))
                        end
                    end
                end
            end

            sweepESP()
        end)
    end
end)

Hooks.clearESP = function()
    clearESP()
    clearTracers()
end
Hooks.espTag = createESPBillboard

                                                                              
                                                      
                                                                              


    return {
        ESPFolder = ESPFolder,
        Fly = Fly,
        PvPState = PvPState,
        clearESP = clearESP,
        equipFightingStyle = equipFightingStyle,
        equipWeaponByType = equipWeaponByType,
        findFruitHandles = findFruitHandles,
        flyDisable = flyDisable,
        flyPark = flyPark,
        formatNumber = formatNumber,
        getCharBoundingBox = getCharBoundingBox,
        getCharacter = getCharacter,
        getHumanoid = getHumanoid,
        getPlayerBeli = getPlayerBeli,
        getPlayerByName = getPlayerByName,
        getPlayerFragments = getPlayerFragments,
        getPlayerLevel = getPlayerLevel,
        getPlayerLoadout = getPlayerLoadout,
        getPvPStatus = getPvPStatus,
        getRoot = getRoot,
        getServerStatus = getServerStatus,
        initBloxFruitsAntiCheatBypass = initBloxFruitsAntiCheatBypass,
        invokeCommF = invokeCommF,
        isBuddhaUser = isBuddhaUser,
        isGiantForm = isGiantForm,
        magnetPart = magnetPart,
        removeFloorPad = removeFloorPad,
        scanSeaEvents = scanSeaEvents,
        setFlyState = setFlyState,
        setPlayerHitbox = setPlayerHitbox,
        setSpectate = setSpectate,
        stopTween = stopTween,
        tweenTo = tweenTo,
        tweenToPlayer = tweenToPlayer,
    }
end

local Engines = EngineFactory({
    Guard = Guard,
    BLOCKED_REMOTE_PATTERNS = BLOCKED_REMOTE_PATTERNS,
    BOSSES_BY_SEA = BOSSES_BY_SEA,
    CURRENT_SEA = CURRENT_SEA,
    Config = Config,
    CustomIcons = CustomIcons,
    Debris = Debris,
    FIGHTING_STYLE_REMOTES = FIGHTING_STYLE_REMOTES,
    FIGHTING_STYLE_TOOLS = FIGHTING_STYLE_TOOLS,
    FRUIT_STORE_CODES = FRUIT_STORE_CODES,
    HookRegistry = HookRegistry,
    Hooks = Hooks,
    LocalPlayer = LocalPlayer,
    MovementLink = MovementLink,
    Players = Players,
    QUEST_DATABASE = QUEST_DATABASE,
    ReplicatedStorage = ReplicatedStorage,
    RunService = RunService,
    SEA_DETECT_SOURCE = SEA_DETECT_SOURCE,
    SEA_EVENT_SIGNATURES = SEA_EVENT_SIGNATURES,
    SeaEventState = SeaEventState,
    SkillHubStep = SkillHubStep,
    StatsService = StatsService,
    TweenService = TweenService,
    UserInputService = UserInputService,
    VirtualUser = VirtualUser,
    Workspace = Workspace,
    getFruitTier = getFruitTier,
    isMeleeTool = isMeleeTool,
    pressKey = pressKey,
    refreshSea = refreshSea,
    toolMatchesCategory = toolMatchesCategory,
    trace = trace,
    virtualClick = virtualClick,
})
local ESPFolder, Fly, PvPState, clearESP, equipFightingStyle, equipWeaponByType = Engines.ESPFolder, Engines.Fly, Engines.PvPState, Engines.clearESP, Engines.equipFightingStyle, Engines.equipWeaponByType
local findFruitHandles, flyDisable, formatNumber, getCharBoundingBox, getCharacter, getHumanoid = Engines.findFruitHandles, Engines.flyDisable, Engines.formatNumber, Engines.getCharBoundingBox, Engines.getCharacter, Engines.getHumanoid
local getPlayerBeli, getPlayerByName, getPlayerFragments, getPlayerLevel, getPlayerLoadout, getPvPStatus = Engines.getPlayerBeli, Engines.getPlayerByName, Engines.getPlayerFragments, Engines.getPlayerLevel, Engines.getPlayerLoadout, Engines.getPvPStatus
local getRoot, getServerStatus, initBloxFruitsAntiCheatBypass, invokeCommF, isBuddhaUser, isGiantForm = Engines.getRoot, Engines.getServerStatus, Engines.initBloxFruitsAntiCheatBypass, Engines.invokeCommF, Engines.isBuddhaUser, Engines.isGiantForm
local magnetPart, removeFloorPad, scanSeaEvents, setFlyState, setPlayerHitbox, setSpectate = Engines.magnetPart, Engines.removeFloorPad, Engines.scanSeaEvents, Engines.setFlyState, Engines.setPlayerHitbox, Engines.setSpectate
local stopTween, tweenTo, tweenToPlayer, flyPark = Engines.stopTween, Engines.tweenTo, Engines.tweenToPlayer, Engines.flyPark

                                                                                 
print(string.format(__S("8d77caec8205d03a9d46ade5d0bcd601557fd658fd70bd8efc9408cccf423c84df3a22f47a90ed7be3c51a44ed34f6c4c2"), Guard.watchTable(__S("2baf449d066d31c5ebbdd8"), Engines)))

                                                                              
                     
                                                                      
                                                            
                                                                              
local UIFactory = function(E)
    local CURRENT_SEA, Config, CustomIcons, Hooks = E.CURRENT_SEA, E.Config, E.CustomIcons, E.Hooks
    local LocalPlayer, Players, PvPState, RunService = E.LocalPlayer, E.Players, E.PvPState, E.RunService
    local SEA_DETECT_SOURCE, SkillHubStep, TweenService, UserInputService = E.SEA_DETECT_SOURCE, E.SkillHubStep, E.TweenService, E.UserInputService
    local Workspace, formatNumber, getPlayerBeli, getPlayerFragments = E.Workspace, E.formatNumber, E.getPlayerBeli, E.getPlayerFragments
    local getPlayerLevel, getPlayerLoadout, getPvPStatus, getRoot = E.getPlayerLevel, E.getPlayerLoadout, E.getPvPStatus, E.getRoot
    local getServerStatus, isBuddhaUser, isGiantForm, setSpectate = E.getServerStatus, E.isBuddhaUser, E.isGiantForm, E.setSpectate
    local trace, tweenToPlayer = E.trace, E.tweenToPlayer
    local Guard = E.Guard

                                                                                
                                                                               
                                                                                 
local ExternalFluent = nil

                                                                              
                                    
                                                                               
                                                                           
                                                                           
                                                                              

local Theme = {
                                                        
    BgApp           = Color3.fromRGB(9, 10, 12),
    BgSurface       = Color3.fromRGB(17, 19, 23),
    BgElevated      = Color3.fromRGB(23, 26, 31),
    BgRaised        = Color3.fromRGB(29, 33, 39),
    BgInset         = Color3.fromRGB(13, 15, 18),
    BgHover         = Color3.fromRGB(33, 37, 44),

                
    Hairline        = Color3.fromRGB(58, 63, 72),
    Stroke          = Color3.fromRGB(44, 49, 57),
    StrokeSoft      = Color3.fromRGB(35, 39, 46),

                 
    TextPrimary     = Color3.fromRGB(243, 244, 246),
    TextSecondary   = Color3.fromRGB(158, 165, 175),
    TextMuted       = Color3.fromRGB(110, 117, 127),
    TextFaint       = Color3.fromRGB(78, 84, 93),
    OnAccent        = Color3.fromRGB(13, 14, 17),

                                                                
    Accent          = Color3.fromRGB(126, 141, 255),         
    AccentSecondary = Color3.fromRGB(150, 158, 186),          
    AccentPurple    = Color3.fromRGB(173, 143, 222),          
    Iris            = Color3.fromRGB(126, 141, 255),
    Clay            = Color3.fromRGB(226, 132, 122),
    Sand            = Color3.fromRGB(223, 181, 133),
    Sage            = Color3.fromRGB(128, 182, 155),
    Mauve           = Color3.fromRGB(173, 143, 222),
    Steel           = Color3.fromRGB(150, 158, 186),
    Sky             = Color3.fromRGB(136, 170, 203),
    Rose            = Color3.fromRGB(201, 141, 178),

    Success         = Color3.fromRGB(122, 190, 146),
    Warning         = Color3.fromRGB(224, 184, 116),
    Danger          = Color3.fromRGB(223, 118, 116),

                                                            
    BgPrimary       = Color3.fromRGB(17, 19, 23),
    BgSidebar       = Color3.fromRGB(15, 17, 20),
    BgCard          = Color3.fromRGB(23, 26, 31),
    BgControl       = Color3.fromRGB(13, 15, 18),
    Border          = Color3.fromRGB(44, 49, 57),
    Neon            = Color3.fromRGB(126, 141, 255),
    Glass           = Color3.fromRGB(23, 26, 31),
    GlassLight      = Color3.fromRGB(29, 33, 39),
    OnGold          = Color3.fromRGB(13, 14, 17),
}

local UIFont      = Enum.Font.GothamMedium
local UIFontBold  = Enum.Font.GothamBold
local UIFontMono  = Enum.Font.Code

local RADIUS = { window = 20, panel = 14, card = 12, control = 10, chip = 8, pill = 999 }

                                                                               
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent ~= nil then pcall(function() inst.Parent = parent end) end
    return inst
end

local function corner(parent, radius)
    local c = Instance.new(__S("c9e6be4e2cb78534e52d2722"))
    c.CornerRadius = UDim.new(0, radius or RADIUS.card)
    if parent ~= nil then pcall(function() c.Parent = parent end) end
    return c
end

local function hairline(parent, color, thickness, transparency)
    local s = Instance.new(__S("681e37ff3a78ca8dc64ed715"))
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if parent ~= nil then pcall(function() s.Parent = parent end) end
    return s
end

local function pad(parent, all, extra)
    local p = Instance.new(__S("0655b1b0f4fdd6fa9d8b08be9d"))
    if all then
        p.PaddingTop = UDim.new(0, all)
        p.PaddingBottom = UDim.new(0, all)
        p.PaddingLeft = UDim.new(0, all)
        p.PaddingRight = UDim.new(0, all)
    end
    if extra then
        for side, value in pairs(extra) do p[__S("a48d2b61e1ebc98094b60e") .. side] = UDim.new(0, value) end
    end
    if parent ~= nil then pcall(function() p.Parent = parent end) end
    return p
end

local function tint(color, amount)                                                     
    return color:Lerp(Theme.BgElevated, amount or 0.86)
end

                                                                                
                                                                               
                                           
local function attachShadow(target, spread, transparency)
    local parent = target.Parent
    if not parent then return nil end
    spread = spread or 30
    local shadow = new(__S("42c4a51248d7faa7ea496d5e1b47"), {
        Name = __S("e0fc1ec3229862e678af"),
        BackgroundTransparency = 1,
        Image = CustomIcons.RadialGlow,
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.55,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = math.max((target.ZIndex or 1) - 1, 0),
    }, parent)

    local function sync()
        local pos, size = target.Position, target.Size
        shadow.Position = UDim2.new(pos.X.Scale, pos.X.Offset - spread / 2, pos.Y.Scale, pos.Y.Offset - spread / 2)
        shadow.Size = UDim2.new(size.X.Scale, size.X.Offset + spread, size.Y.Scale, size.Y.Offset + spread)
    end
    sync()
    target:GetPropertyChangedSignal(__S("7f3398747a5851d988b8abb8")):Connect(sync)
    target:GetPropertyChangedSignal(__S("1d6b1225a10bfb21")):Connect(sync)
    return shadow
end

                                                                               
                                                                             
local function addFinish(card, accent, opts)
    opts = opts or {}
    card.BackgroundColor3 = opts.base or Theme.BgElevated
    card.BorderSizePixel = 0
    corner(card, opts.radius or RADIUS.card)

    local stroke = hairline(card, opts.strokeColor or Theme.StrokeSoft, 1, 0.25)

    card.Active = opts.active ~= false
    local hoverColor = (opts.hoverColor or Theme.BgHover)
    local baseColor = card.BackgroundColor3
    local accentLine = nil
    if opts.accentLine then
        accentLine = new(__S("bba28bd6bcb8ffaa7d"), {
            BackgroundColor3 = accent or Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 2, 0, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            ZIndex = card.ZIndex + 1,
            BackgroundTransparency = 1,
        })
        corner(accentLine, 2)
    end

    if opts.interactive ~= false then
        card.MouseEnter:Connect(function()
            SafeTween(card, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { BackgroundColor3 = hoverColor }):Play()
            SafeTween(stroke, TweenInfo.new(0.16), { Color = opts.hoverStroke or Theme.Hairline, Transparency = opts.hoverStrokeTransparency or 0.72 }):Play()
        end)
        card.MouseLeave:Connect(function()
            SafeTween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundColor3 = baseColor }):Play()
            SafeTween(stroke, TweenInfo.new(0.2), { Color = opts.strokeColor or Theme.StrokeSoft, Transparency = 0.25 }):Play()
        end)
        card.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                SafeTween(card, TweenInfo.new(0.08), { BackgroundColor3 = baseColor:Lerp(Color3.new(0, 0, 0), 0.08) }):Play()
            end
        end)
        card.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                SafeTween(card, TweenInfo.new(0.14), { BackgroundColor3 = hoverColor }):Play()
            end
        end)
    end

    return stroke, accentLine
end

                                                                              
                                                                               
                                                                            
                                                
                                                             
                                                                               
                                                                     
local BadIconReported, BadIconCount = {}, 0

local GLYPH_OF_ASSET = {
    [CustomIcons.HubCrest]  = __S("59da0587112ccc6101"),
    [CustomIcons.AutoFarm]  = __S("f8117f38d0e46e6e2d86"),
    [CustomIcons.Stats]     = __S("9648f8e940ba0bcfd6"),
    [CustomIcons.Fruits]    = __S("3480729af583a726ef"),
    [CustomIcons.Teleport]  = __S("d2b7ec4b37b8f1f0c00b8c"),
    [CustomIcons.ESP]       = __S("70ef65fc317a91"),
    [CustomIcons.Animator]  = __S("0f26dfad34a408d4"),
    [CustomIcons.Settings]  = __S("ad5e595e83cfbc09"),
    [CustomIcons.Boss]      = __S("4b95d30f2615fdeed1"),
    [CustomIcons.Lightning] = __S("e9cd4cc0c8235b8d"),
    [CustomIcons.Shield]    = __S("8804c671e73e656212a2"),
    [CustomIcons.Play]      = __S("263c40228e04af23"),
    [CustomIcons.Stop]      = __S("c473b9d3e476f9ac"),
    [CustomIcons.Loop]      = __S("62ab3384a5dcb6d0"),
    [CustomIcons.Wand]      = __S("00e2ad3515aff3a2"),
    [CustomIcons.Layers]    = __S("9f1a26e6c9754b66d26f"),
    [CustomIcons.Search]    = __S("3d51a09785a9393e9d8d"),
    [CustomIcons.PvP]       = __S("db891a485b97eb0f36"),
    [CustomIcons.Players]   = __S("79c093f9856728de74"),
    [CustomIcons.Aim]       = __S("17f80daa6f21a7a9e04ea9"),
    [CustomIcons.Fly]       = __S("b62f875b7ba9afd0"),
    [CustomIcons.Water]     = __S("5467010caab467"),
    [CustomIcons.Magnet]    = __S("f29e7abd14576eb5dc70"),
    [CustomIcons.Server]    = __S("90d5f46e61eecd701a"),
}

local function drawVectorGlyph(holder, kind, color, size, zBase, out)
    out = out or {}
    local function put(px, py, w, h, rotation, radius, fill)
        local part = new(__S("2f0d6e1f3e068d823a"), {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = fill or color,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Position = UDim2.new(px, 0, py, 0),
            Size = UDim2.new(0, math.max(math.floor(w * size), 1), 0, math.max(math.floor(h * size), 1)),
            Rotation = rotation or 0,
            ZIndex = zBase,
        }, holder)
        corner(part, radius or math.floor(size / 2))
        table.insert(out, part)
        return part
    end

    if kind == __S("cd44e7d09c05ff8f329b") then
        put(0.5, 0.5, 0.13, 1.0, 45, 2)
        put(0.5, 0.5, 0.13, 1.0, -45, 2)
    elseif kind == __S("6b7c6181b465296bd0") then
        put(0.5, 0.43, 0.86, 0.72, 0, math.floor(size * 0.3))
        put(0.34, 0.41, 0.19, 0.19, 0, math.floor(size / 2), Theme.BgApp)
        put(0.66, 0.41, 0.19, 0.19, 0, math.floor(size / 2), Theme.BgApp)
        put(0.5, 0.79, 0.34, 0.17, 0, 2)
    elseif kind == __S("09b3db323b35924025") then
        put(0.24, 0.7, 0.15, 0.44, 0, 2)
        put(0.5, 0.6, 0.15, 0.66, 0, 2)
        put(0.76, 0.68, 0.15, 0.52, 0, 2)
    elseif kind == __S("a7eb54e33e119cb0ee") then
        put(0.5, 0.66, 0.8, 0.8, 0, math.floor(size / 2))
        put(0.75, 0.2, 0.34, 0.16, -18, math.floor(size / 2))
        put(0.5, 0.22, 0.08, 0.3, 0, 2)
    elseif kind == __S("4622ce94896781") then
        put(0.5, 0.5, 1.0, 0.62, 0, math.floor(size * 0.31))
        put(0.5, 0.5, 0.34, 0.34, 0, math.floor(size / 2), Theme.BgApp)
    elseif kind == __S("e45a48450fb717697b88d7") then
        put(0.5, 0.5, 1.0, 1.0, 0, math.floor(size / 2))
        put(0.5, 0.5, 0.6, 0.6, 0, math.floor(size / 2), Theme.BgApp)
        put(0.5, 0.5, 0.09, 0.42, 40, 2)
    elseif kind == __S("8291c1f6e6aea16a") then
        put(0.5, 0.16, 0.3, 0.3, 0, 2)
        put(0.5, 0.84, 0.3, 0.3, 0, 2)
        put(0.16, 0.5, 0.3, 0.3, 90, 2)
        put(0.84, 0.5, 0.3, 0.3, 90, 2)
        put(0.5, 0.5, 0.54, 0.54, 0, math.floor(size / 2))
        put(0.5, 0.5, 0.2, 0.2, 0, math.floor(size / 2), Theme.BgApp)
    elseif kind == __S("20c93ba73ba017ca") then
        put(0.44, 0.32, 0.15, 0.48, 18, 2)
        put(0.56, 0.68, 0.15, 0.48, 18, 2)
    elseif kind == __S("bf00b5585eacfc3513ed") then
        put(0.5, 0.46, 0.86, 0.9, 0, math.floor(size * 0.3))
        put(0.5, 0.42, 0.34, 0.13, 0, 2, Theme.BgApp)
        put(0.5, 0.5, 0.13, 0.5, 0, 2, Theme.BgApp)
    elseif kind == __S("5d382f09b54bff56") then
        put(0.42, 0.34, 0.13, 0.55, -32, 2)
        put(0.42, 0.66, 0.13, 0.55, 32, 2)
    elseif kind == __S("fb6fa8ba35741754") then
        put(0.5, 0.5, 0.6, 0.6, 0, 3)
    elseif kind == __S("99a7226b32b65d18") then
        put(0.5, 0.5, 0.86, 0.86, 0, math.floor(size / 2))
        put(0.5, 0.5, 0.5, 0.5, 0, math.floor(size / 2), Theme.BgApp)
        put(0.5, 0.12, 0.22, 0.22, 0, 2)
    elseif kind == __S("37de9c1c1eccac8dfea0") then
        put(0.5, 0.27, 0.8, 0.22, 0, 3)
        put(0.5, 0.51, 0.8, 0.22, 0, 3)
        put(0.5, 0.75, 0.8, 0.22, 0, 3)
    elseif kind == __S("d61615cda9be72fdc96f") then
        put(0.44, 0.42, 0.62, 0.62, 0, math.floor(size / 2))
        put(0.44, 0.42, 0.3, 0.3, 0, math.floor(size / 2), Theme.BgApp)
        put(0.76, 0.76, 0.15, 0.42, -45, 2)
    elseif kind == __S("744d8f7e2259c84a0119") then
        put(0.3, 0.44, 0.16, 0.6, 0, 2)
        put(0.7, 0.44, 0.16, 0.6, 0, 2)
        put(0.5, 0.74, 0.56, 0.16, 0, 2)
    elseif kind == __S("1285092f7ce7c799f2") then
        put(0.5, 0.5, 0.72, 0.72, 45, 3)
        put(0.5, 0.22, 0.2, 0.2, 0, math.floor(size / 2))
        put(0.5, 0.78, 0.2, 0.2, 0, math.floor(size / 2))
    else
        put(0.5, 0.5, 0.62, 0.62, 0, math.floor(size / 2))
        put(0.5, 0.5, 0.28, 0.28, 0, math.floor(size / 2), Theme.BgApp)
    end
    return out
end

local function iconTile(parent, iconAssetId, accentColor, sizePx, posUDim, zIdx, glyphKind)
    accentColor = accentColor or Theme.Accent
    local holder = new(__S("b0bc82e0d692302328"), {
        Name = __S("4ef3fc91486e6999bc083e62"),
        Size = UDim2.new(0, sizePx, 0, sizePx),
        Position = posUDim,
        BackgroundColor3 = tint(accentColor, 0.88),
        BorderSizePixel = 0,
        ZIndex = zIdx or 4,
    }, parent)
    corner(holder, math.max(math.floor(sizePx * 0.3), 6))
    hairline(holder, tint(accentColor, 0.55), 1, 0.55)

    local inner = math.max(sizePx - math.floor(sizePx * 0.42), 10)

                                                                             
    local kind = glyphKind or GLYPH_OF_ASSET[iconAssetId]
    if kind then
        local parts = drawVectorGlyph(holder, kind, accentColor, inner, (zIdx or 4) + 1)
        local proxy = setmetatable({}, {
            __index = function(_, key)
                if key == __S("ed2b76429a655e4e533269dc422135") then return accentColor end
                return nil
            end,
            __newindex = function(_, key, value)
                if key == __S("8b62eff35441b38cf3d24f36cbd1f4") then
                    for _, part in ipairs(parts) do part.BackgroundColor3 = value end
                elseif key == __S("299a69a4da1d5b6024") then
                    local newKind = GLYPH_OF_ASSET[value]
                    if newKind then
                        for _, part in ipairs(parts) do pcall(function() part:Destroy() end) end
                        for i = #parts, 1, -1 do parts[i] = nil end
                        drawVectorGlyph(holder, newKind, accentColor, inner, (zIdx or 4) + 1, parts)
                    end
                end
            end,
        })
        return holder, proxy
    end

    local img = new(__S("c7d1e355c1b3da0e68fe8a9d0e22"), {
        BackgroundTransparency = 1,
        Image = iconAssetId or CustomIcons.HubCrest,
        ImageColor3 = accentColor,
        ScaleType = Enum.ScaleType.Fit,
        Size = UDim2.new(0, inner, 0, inner),
        Position = UDim2.new(0.5, -inner / 2, 0.5, -inner / 2),
        ZIndex = (zIdx or 4) + 1,
    }, holder)

                                                                              
                                                                    
    task.delay(3, function()
        if not holder.Parent or not img.Parent then return end
        local loaded = true
        pcall(function() loaded = img.IsLoaded end)
        if loaded then return end
        if not BadIconReported[tostring(iconAssetId)] then
            BadIconReported[tostring(iconAssetId)] = true
            BadIconCount = BadIconCount + 1
            if BadIconCount <= 3 then
                print(string.format(__S("66095d06c917c4c2127097d1f9353c4593d777a09f4bdde66aee5dfb833f258958826fe75d2b487ce63f4633174b77431c6cb534a67cd8eb9dd66f4b2066cecee0f1e8e742c97fe9d89ea2"), tostring(iconAssetId)))
            elseif BadIconCount == 4 then
                print(__S("0440d6b727003d957a612610f6860ee17c9fd2bf7faf13643efc5affd95fa33fe91335a0a9218c4e44fdffa1717ac023638468d49b12eeda971accabdde8431dae546f845c494eed4791258842d6ca3701b9b9b0071092"))
            end
        end
        img.Visible = false
        drawVectorGlyph(holder, glyphKind or GLYPH_OF_ASSET[iconAssetId] or __S("a278506876d6f1"), accentColor, inner, (zIdx or 4) + 1)
    end)

    return holder, img
end

                                                 
local createVectorIconBadge = iconTile

                                                                               
local guiParent = LocalPlayer:WaitForChild(__S("40afca195faeccd56d5753e695"))
if guiParent:FindFirstChild(__S("dee743ca7642a681fea9da1f45231130235c9f5bf6c6")) then
    guiParent.SkillHubBloxFruits:Destroy()
end

local ScreenGui = new(__S("7d1ebd7b10447aa1e7f68289e2"), {
    Name = __S("1b56372c062f1f68e32cfd0716e326238cd331b1b3e7"),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    IgnoreGuiInset = true,
}, guiParent)

local UIScale = new(__S("b98db0dd83488513985a01"), {}, ScreenGui)
local function updateScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local sx = vp.X / 820
    local sy = vp.Y / 560
    UIScale.Scale = math.clamp(math.min(sx, sy), 0.62, 1)
end
updateScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal(__S("57c52a8e12fa1d698d231bf526f7ab91")):Connect(updateScale)
end

                                                                               
                                                                      
local Canvas = new(__S("f5fca43f8476cebea0"), {
    Name = __S("94341df0d6990445bd41"),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
}, ScreenGui)

local MainWindow = new(__S("326b97a16808258314"), {
    Name = __S("d0a311529b2eb0feea950ba14160"),
    Size = UDim2.new(0, 772, 0, 512),
    Position = UDim2.new(0.5, -386, 0.5, -256),
    BackgroundColor3 = Theme.BgSurface,
    BorderSizePixel = 0,
    ClipsDescendants = false,
}, Canvas)
corner(MainWindow, RADIUS.window)

attachShadow(MainWindow, 42, 0.5)

local winStroke = hairline(MainWindow, Theme.Stroke, 1, 0.2)

                                                                
local sheen = new(__S("6eda8b03584fe4f0a6"), {
    Name = __S("0d1204b4e53df34ddb"),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.965,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 132),
    ZIndex = 2,
}, MainWindow)
corner(sheen, RADIUS.window)
new(__S("ab497e6592199c451920b91eb037"), {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, sheen)

local WinClip = new(__S("4980f816f1beb74330"), {
    Name = __S("e7b871c7b0fe9812af0519416d28"),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    ClipsDescendants = true,
    ZIndex = 3,
}, MainWindow)
corner(WinClip, RADIUS.window)

                 
MainWindow.BackgroundTransparency = 1
winStroke.Transparency = 1
UIScale.Scale = UIScale.Scale * 0.985
SafeTween(MainWindow, TweenInfo.new(0.28, Enum.EasingStyle.Quart), { BackgroundTransparency = 0 }):Play()
SafeTween(winStroke, TweenInfo.new(0.32), { Transparency = 0.2 }):Play()
task.spawn(function()
    task.wait(0.05)
    SafeTween(UIScale, TweenInfo.new(0.34, Enum.EasingStyle.Quart), { Scale = math.clamp(math.min(Workspace.CurrentCamera.ViewportSize.X / 820, Workspace.CurrentCamera.ViewportSize.Y / 560), 0.62, 1) }):Play()
end)

                                                                               
local Topbar = new(__S("85efeb787ec4f0f42e"), {
    Name = __S("242765293c045aba3701132a"),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 58),
    ZIndex = 6,
}, WinClip)

local brandTile = iconTile(Topbar, CustomIcons.HubCrest, Theme.Accent, 30, UDim2.new(0, 18, 0.5, -15), 7)

local BrandTitle = new(__S("c25ededa4cb706a908d1a60fe5"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("6096588b1bf230e540d3c493a0"),
    TextColor3 = Theme.TextPrimary,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 58, 0, 12),
    Size = UDim2.new(0, 200, 0, 18),
    ZIndex = 7,
}, Topbar)

local VersionChip = new(__S("fecdd23c1ffc77dc80"), {
    BackgroundColor3 = Theme.BgInset,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 132, 0, 15),
    Size = UDim2.new(0, 46, 0, 15),
    ZIndex = 7,
}, Topbar)
corner(VersionChip, RADIUS.chip)
hairline(VersionChip, Theme.StrokeSoft, 1, 0.4)
new(__S("9d054beda538d1a3136f0a6852"), {
    BackgroundTransparency = 1,
    Font = UIFontMono,
    Text = __S("3b3cc59e0f0f787a8c"),
    TextColor3 = Theme.TextMuted,
    TextSize = 9,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 8,
}, VersionChip)

local BrandSub = new(__S("d9743f4f75971c3bd52617733d"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Text = __S("77abb900a7c927e51eb14880b81238408fd3cbe2e2972502"),
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 58, 0, 30),
    Size = UDim2.new(0, 260, 0, 14),
    ZIndex = 7,
}, Topbar)

                                             
local SearchShell = new(__S("15e332b14df1f0521e"), {
    BackgroundColor3 = Theme.BgInset,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -404, 0.5, -15),
    Size = UDim2.new(0, 236, 0, 30),
    ZIndex = 7,
}, Topbar)
corner(SearchShell, RADIUS.control)
local searchStroke = hairline(SearchShell, Theme.StrokeSoft, 1, 0.35)

iconTile(SearchShell, CustomIcons.Search, Theme.TextMuted, 16, UDim2.new(0, 8, 0.5, -8), 8)

local SearchBox = new(__S("b41aac62ddb61d403a70fb"), {
    BackgroundTransparency = 1,
    ClearTextOnFocus = false,
    Font = UIFont,
    PlaceholderColor3 = Theme.TextFaint,
    PlaceholderText = __S("5252261368f11ca42bc813dd01f234a734bba94cc029862239edaf"),
    Position = UDim2.new(0, 30, 0, 0),
    Size = UDim2.new(1, -38, 1, 0),
    Text = "",
    TextColor3 = Theme.TextSecondary,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8,
}, SearchShell)
SearchBox.Focused:Connect(function()
    SafeTween(searchStroke, TweenInfo.new(0.16), { Color = Theme.Accent, Transparency = 0.45 }):Play()
end)
SearchBox.FocusLost:Connect(function()
    SafeTween(searchStroke, TweenInfo.new(0.18), { Color = Theme.StrokeSoft, Transparency = 0.35 }):Play()
end)

                                          
local function ghostButton(parent, glyph, xOffset, danger)
    local btn = new(__S("f0899fc4a8a948cbf3601a1fdc6a"), {
        BackgroundColor3 = Theme.BgInset,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = UIFont,
        Position = UDim2.new(1, xOffset, 0.5, -13),
        Size = UDim2.new(0, 26, 0, 26),
        Text = glyph,
        TextColor3 = Theme.TextMuted,
        TextSize = 13,
        ZIndex = 8,
    }, parent)
    corner(btn, RADIUS.pill)

    btn.MouseEnter:Connect(function()
        SafeTween(btn, TweenInfo.new(0.14), {
            BackgroundTransparency = 0,
            BackgroundColor3 = danger and tint(Theme.Danger, 0.82) or Theme.BgRaised,
            TextColor3 = danger and Theme.Danger or Theme.TextPrimary,
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        SafeTween(btn, TweenInfo.new(0.18), {
            BackgroundTransparency = 1,
            TextColor3 = Theme.TextMuted,
        }):Play()
    end)
    return btn
end

local MinBtn = ghostButton(Topbar, __S("8ec1197520571b"), -66, false)
local CloseBtn = ghostButton(Topbar, __S("2cf893268ae884"), -36, true)

                                                                               
do
    local DragHandle = new(__S("cb300cd784b1a7022d"), {
        Name = __S("696786887715f801e2708213ed94"),
        Active = true,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -430, 1, 0),
        ZIndex = 6,
    }, Topbar)

    local dragging, dragInput, dragStart, startPos
    DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    DragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    DragHandle.Parent = Topbar
end

                              
new(__S("079f0039139b7031c8"), {
    BackgroundColor3 = Theme.StrokeSoft,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 57),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 6,
}, WinClip)

                                                                               
local Rail = new(__S("a5d679ea399f04d10a"), {
    Name = __S("440df39b76d60b99"),
    BackgroundColor3 = Theme.BgSidebar,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 58),
    Size = UDim2.new(0, 206, 1, -58),
    ZIndex = 4,
}, WinClip)

new(__S("e2456d4cbc8d39fec4"), {
    BackgroundColor3 = Theme.StrokeSoft,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    ZIndex = 5,
}, Rail)

local RailSection = new(__S("807ce6fd789e300a34ec0ad59a"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("1eb460ae70325c6d0ea7ae37e8af"),
    TextColor3 = Theme.TextFaint,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 18, 0, 12),
    Size = UDim2.new(1, -24, 0, 12),
    ZIndex = 5,
}, Rail)

local TabButtonContainer = new(__S("bcebda5f3cdf3c0d4454331bcd381fbb47c1"), {
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    Position = UDim2.new(0, 10, 0, 30),
    ScrollBarThickness = 0,
    Size = UDim2.new(1, -20, 1, -124),
    ZIndex = 5,
}, Rail)
new(__S("5b235410950185e2e351b25896d834c7"), {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, TabButtonContainer)

                                          
local IdCard = new(__S("f95acdc1f603d679fa"), {
    BackgroundColor3 = Theme.BgElevated,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 1, -110),
    Size = UDim2.new(1, -20, 0, 100),
    ZIndex = 5,
}, Rail)
corner(IdCard, RADIUS.panel)
hairline(IdCard, Theme.StrokeSoft, 1, 0.3)

local AvatarShell = new(__S("979247720a5220eb6f"), {
    BackgroundColor3 = tint(Theme.Accent, 0.7),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 12),
    Size = UDim2.new(0, 34, 0, 34),
    ZIndex = 6,
}, IdCard)
corner(AvatarShell, RADIUS.pill)
hairline(AvatarShell, tint(Theme.Accent, 0.4), 1, 0.5)

local AvatarInitials = new(__S("35c9c123212be233833703ed8a"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("d4013ad466"),
    TextColor3 = Theme.Accent,
    TextSize = 13,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 7,
}, AvatarShell)

local AvatarImg = new(__S("7238b485b885f01d68c6d889200a"), {
    BackgroundTransparency = 1,
    Image = "",
    Size = UDim2.new(1, 0, 1, 0),
    Visible = false,
    ZIndex = 8,
}, AvatarShell)
corner(AvatarImg, RADIUS.pill)

local IdName = new(__S("10702e36198981be9bfc21909a"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("aea7a7e7da650a405be1"),
    TextColor3 = Theme.TextPrimary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 54, 0, 14),
    Size = UDim2.new(1, -64, 0, 15),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 6,
}, IdCard)

local IdHandle = new(__S("4cdf21987ad81a7d832555e86a"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Text = __S("eb169b49f698fec2c4c0fa"),
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 54, 0, 29),
    Size = UDim2.new(1, -64, 0, 14),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 6,
}, IdCard)

local function miniStat(parent, xOffset, width, caption, value, valueColor)
    local holder = new(__S("894e14fa14ea3d6d3b"), {
        BackgroundColor3 = Theme.BgInset,
        BorderSizePixel = 0,
        Position = UDim2.new(0, xOffset, 0, 58),
        Size = UDim2.new(0, width, 0, 30),
        ZIndex = 6,
    }, parent)
    corner(holder, RADIUS.chip)
    hairline(holder, Theme.StrokeSoft, 1, 0.45)

    new(__S("27858eabb71acdb948a3e35204"), {
        BackgroundTransparency = 1,
        Font = UIFont,
        Text = caption,
        TextColor3 = Theme.TextFaint,
        TextSize = 8,
        Position = UDim2.new(0, 8, 0, 3),
        Size = UDim2.new(1, -12, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
    }, holder)

    local lbl = new(__S("c5bd085cb33cfd69d9d27516b2"), {
        BackgroundTransparency = 1,
        Font = UIFontMono,
        Text = value,
        TextColor3 = valueColor or Theme.TextSecondary,
        TextSize = 11,
        Position = UDim2.new(0, 8, 0, 13),
        Size = UDim2.new(1, -12, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
    }, holder)
    return lbl, holder
end

local FooterLvLbl = miniStat(IdCard, 12, 84, __S("63f4820d7b8e63f1b60ad9dc4d8c1fb288571020a859"), __S("022bfbbe21cf645eca6f"), Theme.TextSecondary)
local FooterBeliLbl = miniStat(IdCard, 102, 76, __S("a063756f4af50457"), __S("3e9aef205b9a0f"), Theme.Success)

                        
task.spawn(function()
    while task.wait(1) do
        if not ScreenGui.Parent then break end
        SkillHubStep(__S("dcd268d1f8f92aa916ed88e6e0f8b33e88"), function()
            FooterLvLbl.Text = string.format(__S("7b09e282cb670dfacabd69f7"), tostring(getPlayerLevel()), formatNumber(getPlayerFragments()))
            FooterBeliLbl.Text = __S("19415c337414") .. formatNumber(getPlayerBeli())
            BrandSub.Text = string.format(__S("b778d5e48434824ab7e90af7db2cbdf2537c12a1d92cd5b6645e26fd984643"), CURRENT_SEA, tostring(SEA_DETECT_SOURCE))
            IdName.Text = LocalPlayer.DisplayName
            IdHandle.Text = __S("55b04f9574") .. LocalPlayer.Name
            if AvatarInitials.Text == __S("f3e7c9463e") then
                AvatarInitials.Text = string.upper(string.sub(LocalPlayer.DisplayName, 1, 1))
            end
        end)
    end
end)

task.spawn(function()
    task.wait(0.4)
    pcall(function()
        local thumb = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        if thumb and thumb ~= "" then
            AvatarImg.Image = thumb
            AvatarImg.Visible = true
            AvatarInitials.Visible = false
        end
    end)
end)

                                                                               
local Content = new(__S("921f42f7718fc2f9f4"), {
    Name = __S("3056bca82afd6cc4c7b0e4"),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 206, 0, 58),
    Size = UDim2.new(1, -206, 1, -58),
    ZIndex = 4,
}, WinClip)

local HeaderBar = new(__S("ce8e36595deb2706da"), {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 56),
    ZIndex = 5,
}, Content)

local _, ActiveTabIconImg = iconTile(HeaderBar, CustomIcons.AutoFarm, Theme.Accent, 32, UDim2.new(0, 18, 0, 13), 6)

local ActiveTabTitle = new(__S("6cc5b00a3c807eeae5c384e6b8"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("0afd29bbdf96567cb55b49c7b9"),
    TextColor3 = Theme.TextPrimary,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 60, 0, 10),
    Size = UDim2.new(0, 300, 0, 18),
    ZIndex = 6,
}, HeaderBar)

local ActiveTabSub = new(__S("a934a36c94a65e72d7da1f6009"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Text = __S("476c1d1d78af788382decec9b1335a1e5b9729d88129a0869afdf444"),
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 60, 0, 28),
    Size = UDim2.new(0, 320, 0, 14),
    ZIndex = 6,
}, HeaderBar)

                                                
local headerChips = new(__S("e5a396ce558c527ab3"), {
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -400, 0, 17),
    Size = UDim2.new(0, 382, 0, 22),
    ZIndex = 6,
}, HeaderBar)
local chipLayout = new(__S("83db107f607d3bfd76e524f33a224261"), {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, headerChips)

local function statusChip(text, color)
    local chip = new(__S("22128a309c846e4b96"), {
        BackgroundColor3 = Theme.BgInset,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 20),
        ZIndex = 7,
        AutomaticSize = Enum.AutomaticSize.X,
    }, headerChips)
    corner(chip, RADIUS.pill)
    hairline(chip, Theme.StrokeSoft, 1, 0.4)
    pad(chip, nil, { Left = 8, Right = 8 })

    local dot = new(__S("c04a03e1fcfe5034bc"), {
        BackgroundColor3 = color or Theme.TextMuted,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0.5, -2),
        Size = UDim2.new(0, 4, 0, 4),
        ZIndex = 8,
    }, chip)
    corner(dot, RADIUS.pill)

    local lbl = new(__S("5e817d923f61ee0110078c743d"), {
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = UIFontMono,
        Position = UDim2.new(0, 17, 0, 0),
        Size = UDim2.new(0, 0, 1, 0),
        Text = text,
        TextColor3 = Theme.TextSecondary,
        TextSize = 9,
        ZIndex = 8,
    }, chip)

    return { chip = chip, dot = dot, label = lbl }
end

local ChipSea   = statusChip(__S("fcb8f74358787cd894"), Theme.Accent)
local ChipKill  = statusChip(__S("9af070f4a8b8d90c1c0eec1e9e79dc8b"), Theme.TextMuted)
local ChipFly   = statusChip(__S("3927eaa55a2aeca6a65ad0fc3609"), Theme.TextMuted)
local ChipNet   = statusChip(__S("d75f64560c8e9b85"), Theme.Sage)

new(__S("7596de07ea3935bfea"), {
    BackgroundColor3 = Theme.StrokeSoft,
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 55),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 5,
}, HeaderBar)

local PagesFolder = new(__S("13ce57b8e2035e5d7c"), {
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Position = UDim2.new(0, 18, 0, 60),
    Size = UDim2.new(1, -36, 1, -92),
    ZIndex = 4,
}, Content)

                                     
local StatusStrip = new(__S("b205d1699bf9cd1679"), {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 18, 1, -30),
    Size = UDim2.new(1, -36, 0, 22),
    ZIndex = 5,
}, Content)

local HotkeyHint = new(__S("503d4b1a41a9f5ca5063180622"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Text = __S("ee74c4cb4f3af0dabbdf890f8edbb0711e84f58f20362c10e1276bd28fc6fbd6d3b8091b5c62cde7350c3131b4169f58baad68e14383345e46f66250275a66f76cdf9ef81ae3ff539af53f558d5a84588761c36e404dde9345a7f2"),
    TextColor3 = Theme.TextFaint,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Size = UDim2.new(1, -140, 1, 0),
    ZIndex = 6,
}, StatusStrip)

local LiveClock = new(__S("8cac3e7c3984ba036cbde52df3"), {
    BackgroundTransparency = 1,
    Font = UIFontMono,
    Text = __S("2ae3b82d33927aa9708664d8"),
    TextColor3 = Theme.TextFaint,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Right,
    Position = UDim2.new(1, -140, 0, 0),
    Size = UDim2.new(0, 140, 1, 0),
    ZIndex = 6,
}, StatusStrip)

task.spawn(function()
    while task.wait(1) do
        if not ScreenGui.Parent then break end
        SkillHubStep(__S("c91b31dee30dad872197beb03d734ac650"), function()
            local t = os.date(__S("6752ab8f74fb"))
            LiveClock.Text = string.format(__S("058a2540d46f7ef38173c8836590c774afdf"), t.hour, t.min, t.sec)
        end)
    end
end)

                                                                               
local ToastHolder = new(__S("a3c19ef1788f4bc414"), {
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -336, 0, 14),
    Size = UDim2.new(0, 322, 1, -28),
    ZIndex = 100,
}, ScreenGui)
new(__S("41f918a201a84a3239b296387e0b58f7"), {
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
}, ToastHolder)

local toastOrder = 0
local function notify(title, message, duration, iconAsset)
    duration = duration or 3.5
    toastOrder = toastOrder + 1

    local card = new(__S("e0309253e8036c97f0"), {
        BackgroundColor3 = Theme.BgElevated,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        LayoutOrder = toastOrder,
        Size = UDim2.new(1, 0, 0, 62),
        ZIndex = 101,
    }, ToastHolder)
    addFinish(card, Theme.Accent, { base = Theme.BgElevated, interactive = false })
    card.BackgroundColor3 = Theme.BgElevated

    iconTile(card, iconAsset or CustomIcons.HubCrest, Theme.Accent, 28, UDim2.new(0, 12, 0, 10), 102)

    local titleLbl = new(__S("7e680c04a435434cd1975409fe"), {
        BackgroundTransparency = 1,
        Font = UIFontBold,
        Position = UDim2.new(0, 50, 0, 9),
        Size = UDim2.new(1, -62, 0, 16),
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 102,
    }, card)

    local messageLbl = new(__S("1c9f85b5d51dee51ae1ee91bf2"), {
        BackgroundTransparency = 1,
        Font = UIFont,
        Position = UDim2.new(0, 50, 0, 26),
        Size = UDim2.new(1, -62, 0, 26),
        Text = message,
        TextColor3 = Theme.TextSecondary,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 102,
    }, card)

    local progressTrack = new(__S("bad6ff66dd1da42908"), {
        BackgroundColor3 = Theme.BgInset,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 102,
    }, card)
    corner(progressTrack, RADIUS.pill)

    local progress = new(__S("590e791767aa92c16b"), {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 103,
    }, progressTrack)
    corner(progress, RADIUS.pill)
    SafeTween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()

                                                                                  
    card.Size = UDim2.new(1, 0, 0, 0)
    task.spawn(function()
        for _, child in ipairs(card:GetDescendants()) do
            if child:IsA(__S("f745f2c8c1f81fc005b8527398")) then child.Visible = false end
        end
        SafeTween(card, TweenInfo.new(0.26, Enum.EasingStyle.Quart), { Size = UDim2.new(1, 0, 0, 62) }):Play()
        task.wait(0.09)
        for _, child in ipairs(card:GetDescendants()) do
            if child:IsA(__S("957d6c7947a990f90192950c88")) then child.Visible = true end
        end
    end)

    task.delay(duration, function()
        if card and card.Parent then
            SafeTween(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
            for _, child in ipairs(card:GetDescendants()) do
                if child:IsA(__S("33b4e62a862df375828d05ca5f")) or child:IsA(__S("d1ec5fdb99aa4c1c6a98a67d5593")) then
                    SafeTween(child, TweenInfo.new(0.2), { TextTransparency = 1, ImageTransparency = 1 }):Play()
                end
            end
            task.wait(0.24)
            if card and card.Parent then card:Destroy() end
        end
    end)
end

Hooks.notify = function(title, message, duration, iconAsset)
    pcall(function() notify(title, message, duration, iconAsset) end)
end

                                                                              
local WatermarkBar = new(__S("7023d98ce3d1ebc917"), {
    Name = __S("0e5b533d1404badf3ab879558623bda7"),
    BackgroundColor3 = Theme.BgSurface,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, -252, 0, 10),
    Size = UDim2.new(0, 504, 0, 28),
    ZIndex = 85,
}, ScreenGui)
corner(WatermarkBar, RADIUS.pill)
hairline(WatermarkBar, Theme.Stroke, 1, 0.35)

iconTile(WatermarkBar, CustomIcons.HubCrest, Theme.Accent, 18, UDim2.new(0, 7, 0.5, -9), 86)

local WatermarkText = new(__S("ac92ccee1d4889c67e45548643"), {
    BackgroundTransparency = 1,
    Font = UIFontMono,
    Position = UDim2.new(0, 32, 0, 0),
    Size = UDim2.new(1, -40, 1, 0),
    Text = __S("4aca469fa031b92e87a6d7c0e43afac16d4f0002a571034b5e7fe7"),
    TextColor3 = Theme.TextSecondary,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 87,
}, WatermarkBar)

local StatusBar = new(__S("e901c05033bf58ecc1"), {
    Name = __S("87393a01ce09a6e23f54b7bdbf642ed42c320e"),
    BackgroundColor3 = Theme.BgInset,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, -252, 0, 42),
    Size = UDim2.new(0, 504, 0, 22),
    ZIndex = 84,
}, ScreenGui)
corner(StatusBar, RADIUS.pill)
hairline(StatusBar, Theme.StrokeSoft, 1, 0.45)

local StatusText = new(__S("2570b3b245f8f92956192f3377"), {
    BackgroundTransparency = 1,
    Font = UIFontMono,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -24, 1, 0),
    Text = __S("c3a82d6312c0164fe5c3e718c08bf8b18e"),
    TextColor3 = Theme.TextMuted,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 86,
}, StatusBar)

task.spawn(function()
    local lastTick = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function() frames = frames + 1 end)
    while task.wait(1) do
        if not ScreenGui.Parent then break end
        SkillHubStep(__S("61dfa714a7efa338ea2e23ea5ae46955ca"), function()
            local now = tick()
            local fps = math.floor(frames / math.max(now - lastTick, 0.01))
            frames = 0
            lastTick = now
            local status = getServerStatus()

            WatermarkBar.Visible = Config.ShowWatermarkHUD
            WatermarkText.Text = string.format(__S("001720c5d1d9fefba53140d6fb5af1eccd24c50fec029e4e4ac121af05e317e09c9f769ff621cdfe6f32041661df5b31c9b3dde56f9a459e6991077697"),
                CURRENT_SEA, string.upper(tostring(SEA_DETECT_SOURCE)), getPlayerLevel(), fps, status.ping)

            StatusBar.Visible = Config.ServerStatusHUD and Config.ShowWatermarkHUD
            local hunting = Config.AutoKillSelected or Config.AutoKillPvP
            StatusText.Text = string.format(
                __S("9e4e9a767c9d0b501931358d3afee86f23be0a28f1a7403f6594a5df1cc83bfca7b862f6d1ab7f59a1654bb4bc81ffdd7cb474f6a3557ed2fb9f7c0f285e"),
                status.jobId, status.players, status.maxPlayers,
                Config.AimLock and __S("3c861427a7581a417757d3") or (PvPState.target and (__S("dabd8dd86fa13b55f860c5") .. string.upper(tostring(PvPState.targetName))) or __S("78f50789bb35eb625d058b31")),
                hunting and __S("172c813a149e0d77ecfbb03c7a761c33") or __S("b563faeb3fba3ad96cc2eae939"),
                Config.FlyEnabled and __S("539b749c57ad") or __S("f1d2ee4d0fbe79"),
                status.events
            )
            StatusText.TextColor3 = hunting and Theme.Clay or Theme.TextMuted

                           
            ChipSea.label.Text = string.format(__S("900a67fe57b79bd073cebd796bc4df7c"), CURRENT_SEA, string.upper(tostring(SEA_DETECT_SOURCE)))
            ChipSea.dot.BackgroundColor3 = Theme.Accent
            ChipKill.label.Text = hunting and (__S("2e41e1af7e25a3c261ba49cd") .. (PvPState.targetName ~= "" and string.upper(PvPState.targetName) or __S("cc795b60eb7d5ba8"))) or __S("6ab0d511531597937bc22bdb004af3af")
            ChipKill.dot.BackgroundColor3 = hunting and Theme.Clay or Theme.TextFaint
            ChipFly.label.Text = Config.FlyEnabled and __S("08e84ec25cff208bcb59c525a9") or __S("a71fc8735d867b0c3dc628db89cc")
            ChipFly.dot.BackgroundColor3 = Config.FlyEnabled and Theme.Sage or Theme.TextFaint
            ChipNet.label.Text = string.format(__S("45574224286976390b1368e8ae04c3a0bc165b"), status.ping, fps)
            ChipNet.dot.BackgroundColor3 = (status.ping < 90) and Theme.Sage or ((status.ping < 180) and Theme.Sand or Theme.Clay)
        end)
    end
end)

                                                                              
local FloatBtn = new(__S("e38ebbd51b74cae43cbf8c97a5d0"), {
    BackgroundColor3 = Theme.BgSurface,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 20, 0.5, -21),
    Size = UDim2.new(0, 42, 0, 42),
    Text = "",
    ZIndex = 90,
}, ScreenGui)
corner(FloatBtn, RADIUS.pill)
local floatStroke = hairline(FloatBtn, Theme.Stroke, 1, 0.3)
attachShadow(FloatBtn, 26, 0.55)

iconTile(FloatBtn, CustomIcons.HubCrest, Theme.Accent, 22, UDim2.new(0, 10, 0.5, -11), 92)

FloatBtn.MouseEnter:Connect(function()
    SafeTween(FloatBtn, TweenInfo.new(0.16), { BackgroundTransparency = 0, Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0, 19, 0.5, -22) }):Play()
    SafeTween(floatStroke, TweenInfo.new(0.16), { Color = Theme.Hairline, Transparency = 0.7 }):Play()
end)
FloatBtn.MouseLeave:Connect(function()
    SafeTween(FloatBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.06, Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0, 20, 0.5, -21) }):Play()
    SafeTween(floatStroke, TweenInfo.new(0.2), { Color = Theme.Stroke, Transparency = 0.3 }):Play()
end)

                                                                               
local tabs = {}
local allSearchables = {}

local NoResults = new(__S("81c63586c9777e11959d8c840c"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Position = UDim2.new(0, 0, 0.5, -14),
    Size = UDim2.new(1, 0, 0, 28),
    Text = __S("1ffdaf37345e5b205f5e62f73683ae2dc256ba0b632c492e67c7604d89397b00"),
    TextColor3 = Theme.TextFaint,
    TextSize = 11,
    Visible = false,
    ZIndex = 9,
}, PagesFolder)

local function applySearch()
    local q = string.lower(SearchBox.Text or "")
    local anyVisible = false
    for _, entry in ipairs(allSearchables) do
        local show = (q == "") or (string.find(string.lower(entry.label), q, 1, true) ~= nil)
        entry.frame.Visible = show
        if show then anyVisible = true end
    end
    NoResults.Visible = (q ~= "") and (not anyVisible)
end

SearchBox:GetPropertyChangedSignal(__S("be3528e8a880ed3b")):Connect(applySearch)

                                                                               
local function createTab(iconAsset, name, accentOverride)
    local tabColor = accentOverride or Theme.Accent

    local btn = new(__S("5c6ca29912c68e12a5fdf41b237f"), {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Text = "",
        ZIndex = 5,
    }, TabButtonContainer)
    corner(btn, RADIUS.control)

    local pill = new(__S("faa41c4a1afbc95702"), {
        BackgroundColor3 = Theme.BgElevated,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 5,
    }, btn)
    corner(pill, RADIUS.control)
    local pillStroke = hairline(pill, Theme.Hairline, 1, 1)

    local bar = new(__S("98db95fbafdfb8faa3"), {
        BackgroundColor3 = tabColor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -9),
        Size = UDim2.new(0, 2, 0, 18),
        ZIndex = 7,
    }, btn)
    corner(bar, 2)

    local tile, tileIcon = iconTile(btn, iconAsset, tabColor, 24, UDim2.new(0, 11, 0.5, -12), 6)
    tile.BackgroundTransparency = 1

    local lbl = new(__S("37130fac6b10ebabf2c33dec8d"), {
        BackgroundTransparency = 1,
        Font = UIFont,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -52, 1, 0),
        Text = name,
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 6,
    }, btn)

    local page = new(__S("d54a895d9e04871738b9f19de3fbf6a5f24e"), {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        ScrollBarImageColor3 = tabColor,
        ScrollBarImageTransparency = 0.55,
        ScrollBarThickness = 3,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 4,
    }, PagesFolder)
    new(__S("7382030e4a8beb53a779a2013e6c72c1"), {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    pad(page, nil, { Right = 8, Bottom = 12 })

    local tabObj = {
        btn = btn, bar = bar, lbl = lbl, page = page, pill = pill, pillStroke = pillStroke,
        tile = tile, tileIcon = tileIcon,
        name = name, icon = iconAsset, color = tabColor, order = 0,
    }
    table.insert(tabs, tabObj)

    btn.MouseEnter:Connect(function()
        if page.Visible then return end
        SafeTween(btn, TweenInfo.new(0.16), { BackgroundTransparency = 0, BackgroundColor3 = Theme.BgRaised }):Play()
    end)
    btn.MouseLeave:Connect(function()
        if page.Visible then return end
        SafeTween(btn, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
    end)

    local function selectTab()
        for _, t in ipairs(tabs) do
            t.page.Visible = false
            SafeTween(t.pill, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            SafeTween(t.pillStroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
            SafeTween(t.bar, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            SafeTween(t.btn, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            SafeTween(t.tile, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            t.tileIcon.ImageColor3 = Theme.TextMuted
            t.lbl.TextColor3 = Theme.TextSecondary
            t.lbl.Font = UIFont
        end

        page.Visible = true
        SafeTween(pill, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
        SafeTween(pillStroke, TweenInfo.new(0.2), { Transparency = 0.86 }):Play()
        SafeTween(bar, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
        SafeTween(tile, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
        tileIcon.ImageColor3 = tabColor
        lbl.TextColor3 = Theme.TextPrimary
        lbl.Font = UIFontBold

        trace(__S("11b97cbfdcfc0dd4acc591f4992178f49d4d") .. tostring(name))
        ActiveTabTitle.Text = name
        ActiveTabSub.Text = string.format(__S("aff0f6704d66ce9c6b12506cb4c2f8617aef87a74d1675d798d61f14dda4fd0a1a1aae2325a3"), CURRENT_SEA)
        ActiveTabIconImg.Image = iconAsset
        ActiveTabIconImg.ImageColor3 = tabColor

                               
        page.Position = UDim2.new(0, 8, 0, 0)
        SafeTween(page, TweenInfo.new(0.22, Enum.EasingStyle.Quart), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        applySearch()
    end

                                                                            
    tabObj.Select = selectTab
    btn.MouseButton1Click:Connect(function()
        SkillHubStep(__S("4e287021a36a7c92b4f02e1f754dfd2867") .. tostring(name), selectTab)
    end)
    if #tabs == 1 then SkillHubStep(__S("ec5fe9d214ff3359fe8d1c9ff39f773313") .. tostring(name) .. __S("8a976383d0d78bc4098373"), selectTab) end

                                                                               
    function tabObj:AddSection(title)
        self.order = self.order + 1
        local sec = new(__S("28cedd34c64c1930d4"), {
            BackgroundTransparency = 1,
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 26),
        }, self.page)

        local dot = new(__S("c70656e54e6876f6eb"), {
            BackgroundColor3 = self.color,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 2, 0.5, -2),
            Size = UDim2.new(0, 4, 0, 4),
        }, sec)
        corner(dot, RADIUS.pill)

        new(__S("653dd09675b66e1c3786c6f53b"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(0.62, 0, 1, 0),
            Text = string.upper(title),
            TextColor3 = Theme.TextSecondary,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 3,
        }, sec)

        local divider = new(__S("03754a473f6d2fca81"), {
            BackgroundColor3 = Theme.StrokeSoft,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 3,
        }, sec)
        new(__S("a1acc3f864bf28406c4ca6696a0c"), {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.55, 0.65),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }, divider)
    end

                                                                               
                                                                                 
                                                                                
    local function uiPace(order)
        if Config.IncrementalUIBuild ~= false and order % 3 == 0 then
            task.wait()
        end
    end

    function tabObj:AddToggle(title, desc, defaultValue, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("3fe43da9e715c7f697"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 58),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or self.icon, self.color, 30, UDim2.new(0, 14, 0.5, -15), 5)

        new(__S("de1bb75a36c3b9bec10a705fa6"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 56, 0, 11),
            Size = UDim2.new(1, -170, 0, 16),
            Text = title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        new(__S("7c53310b268cdef271e7fabdbb"), {
            BackgroundTransparency = 1,
            Font = UIFont,
            Position = UDim2.new(0, 56, 0, 29),
            Size = UDim2.new(1, -170, 0, 16),
            Text = desc or "",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        local stateLbl = new(__S("1a8aaabc4698aa1ebd71e60434"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(1, -112, 0.5, -7),
            Size = UDim2.new(0, 30, 0, 14),
            Text = __S("b8c2246d45e47a"),
            TextColor3 = Theme.TextFaint,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 5,
        }, card)

        local track = new(__S("56f99e1ea5a4370916"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -68, 0.5, -12),
            Size = UDim2.new(0, 44, 0, 24),
            ZIndex = 5,
        }, card)
        corner(track, RADIUS.pill)
        local trackStroke = hairline(track, Theme.StrokeSoft, 1, 0.35)

        local knob = new(__S("f53117cf0d80f06ebd"), {
            BackgroundColor3 = Color3.fromRGB(238, 240, 244),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 3, 0.5, -9),
            Size = UDim2.new(0, 18, 0, 18),
            ZIndex = 6,
        }, track)
        corner(knob, RADIUS.pill)

        local state = defaultValue and true or false
        local function render(animate)
            local info = TweenInfo.new(animate and 0.2 or 0, Enum.EasingStyle.Quart)
            SafeTween(track, info, {
                BackgroundColor3 = state and tint(self.color, 0.52) or Theme.BgInset,
            }):Play()
            SafeTween(trackStroke, info, {
                Color = state and self.color or Theme.StrokeSoft,
                Transparency = state and 0.45 or 0.35,
            }):Play()
            SafeTween(knob, info, {
                Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            }):Play()
            stateLbl.Text = state and __S("93689180e369") or __S("31a00b315da51a")
            stateLbl.TextColor3 = state and self.color or Theme.TextFaint
        end
        render(false)

        local click = new(__S("cfd784e2f340cea08f17b8b4355b"), {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
            ZIndex = 7,
        }, card)
        click.MouseButton1Click:Connect(function()
            state = not state
            render(true)
            if callback then task.spawn(callback, state) end
        end)

        table.insert(allSearchables, { frame = card, label = title .. __S("6e0efe93fd") .. (desc or "") })
    end

                                                                               
    function tabObj:AddButton(title, desc, btnText, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("0c467844c5479da677"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 58),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or self.icon, self.color, 30, UDim2.new(0, 14, 0.5, -15), 5)

        new(__S("aa7df1f500907d8ccfeee896d3"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 56, 0, 11),
            Size = UDim2.new(1, -190, 0, 16),
            Text = title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        new(__S("48b56ba6d2665d57f435680431"), {
            BackgroundTransparency = 1,
            Font = UIFont,
            Position = UDim2.new(0, 56, 0, 29),
            Size = UDim2.new(1, -190, 0, 16),
            Text = desc or "",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        local actBtn = new(__S("e6ece557a0deec76bb3f13ddb883"), {
            AutoButtonColor = false,
            BackgroundColor3 = tint(self.color, 0.86),
            BorderSizePixel = 0,
            Font = UIFontBold,
            Position = UDim2.new(1, -112, 0.5, -15),
            Size = UDim2.new(0, 98, 0, 30),
            Text = btnText or __S("85245f0878da1f"),
            TextColor3 = self.color,
            TextSize = 11,
            ZIndex = 6,
        }, card)
        corner(actBtn, RADIUS.control)
        local actStroke = hairline(actBtn, self.color, 1, 0.72)

        actBtn.MouseEnter:Connect(function()
            SafeTween(actBtn, TweenInfo.new(0.14), { BackgroundColor3 = tint(self.color, 0.74) }):Play()
            SafeTween(actStroke, TweenInfo.new(0.14), { Transparency = 0.5 }):Play()
        end)
        actBtn.MouseLeave:Connect(function()
            SafeTween(actBtn, TweenInfo.new(0.18), { BackgroundColor3 = tint(self.color, 0.86) }):Play()
            SafeTween(actStroke, TweenInfo.new(0.18), { Transparency = 0.72 }):Play()
        end)
        actBtn.MouseButton1Down:Connect(function()
            SafeTween(actBtn, TweenInfo.new(0.08), { BackgroundColor3 = tint(self.color, 0.62) }):Play()
        end)
        actBtn.MouseButton1Click:Connect(function()
            SafeTween(actBtn, TweenInfo.new(0.16), { BackgroundColor3 = tint(self.color, 0.74) }):Play()
            if callback then task.spawn(callback) end
        end)

        table.insert(allSearchables, { frame = card, label = title .. __S("235bd8b95f") .. (desc or "") })
    end

                                                                               
    function tabObj:AddSlider(title, desc, minVal, maxVal, defaultVal, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("c193526a63ae38b3c1"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 72),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or CustomIcons.Lightning, self.color, 30, UDim2.new(0, 14, 0, 12), 5)

        new(__S("5fcacc1b8b09192bb15e847ccc"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 56, 0, 10),
            Size = UDim2.new(1, -170, 0, 16),
            Text = title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        new(__S("fe0245cce53b794499bd934004"), {
            BackgroundTransparency = 1,
            Font = UIFont,
            Position = UDim2.new(0, 56, 0, 27),
            Size = UDim2.new(1, -170, 0, 14),
            Text = desc or "",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        local valuePill = new(__S("9c39bf7d10aea6bd6d"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -76, 0, 12),
            Size = UDim2.new(0, 62, 0, 22),
            ZIndex = 5,
        }, card)
        corner(valuePill, RADIUS.chip)
        hairline(valuePill, Theme.StrokeSoft, 1, 0.4)

        local valLbl = new(__S("3a71392e50d418e205fa4560e3"), {
            BackgroundTransparency = 1,
            Font = UIFontMono,
            Size = UDim2.new(1, 0, 1, 0),
            Text = tostring(defaultVal),
            TextColor3 = self.color,
            TextSize = 11,
            ZIndex = 6,
        }, valuePill)

        local track = new(__S("d8a8b2df2008b1dbf2"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 56, 0, 52),
            Size = UDim2.new(1, -70, 0, 5),
            ZIndex = 5,
        }, card)
        corner(track, RADIUS.pill)
        hairline(track, Theme.StrokeSoft, 1, 0.45)

        local pct = math.clamp((defaultVal - minVal) / math.max(maxVal - minVal, 1), 0, 1)
        local fill = new(__S("76e02c904fc34a2e7e"), {
            BackgroundColor3 = tint(self.color, 0.35),
            BorderSizePixel = 0,
            Size = UDim2.new(pct, 0, 1, 0),
            ZIndex = 6,
        }, track)
        corner(fill, RADIUS.pill)

        local knob = new(__S("1517a641283af2fba3"), {
            BackgroundColor3 = Color3.fromRGB(240, 242, 245),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(pct, 0, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            ZIndex = 7,
        }, track)
        corner(knob, RADIUS.pill)
        hairline(knob, Theme.Stroke, 1, 0.5)

        local hitArea = new(__S("b34f1ff2be8ef55972c9b638bf9e"), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, -9),
            Size = UDim2.new(1, 0, 0, 24),
            Text = "",
            ZIndex = 8,
        }, track)

        local dragging = false
        local function updateFromX(xPos)
            local rel = math.clamp((xPos - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local v = math.floor(minVal + (maxVal - minVal) * rel + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            valLbl.Text = tostring(v)
            if callback then callback(v) end
        end

        hitArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                SafeTween(knob, TweenInfo.new(0.12), { Size = UDim2.new(0, 15, 0, 15) }):Play()
                updateFromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                SafeTween(knob, TweenInfo.new(0.16), { Size = UDim2.new(0, 12, 0, 12) }):Play()
            end
        end)

        table.insert(allSearchables, { frame = card, label = title .. __S("518699a39a") .. (desc or "") })
    end

                                                                               
    function tabObj:AddDropdown(title, desc, options, defaultOption, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local collapsed = 58
        local listHeight = math.min(#options * 27 + 10, 170)
        local expandedHeight = collapsed + listHeight + 8

        local expanded = false
        local card = new(__S("efbe135438e999a083"), {
            ClipsDescendants = true,
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, collapsed),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised, interactive = false })
        card.BackgroundColor3 = Theme.BgElevated

        iconTile(card, itemIcon or self.icon, self.color, 30, UDim2.new(0, 14, 0, 14), 5)

        new(__S("8df58d059bff0362dbc188ef59"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 56, 0, 12),
            Size = UDim2.new(0.52, 0, 0, 16),
            Text = title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        new(__S("2c2d06b6ff11c848e9844e8ee9"), {
            BackgroundTransparency = 1,
            Font = UIFont,
            Position = UDim2.new(0, 56, 0, 30),
            Size = UDim2.new(0.52, 0, 0, 14),
            Text = desc or "",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        local trigger = new(__S("ca64806767955d6d7d4334bdcd4b"), {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Font = UIFont,
            Position = UDim2.new(1, -210, 0, 14),
            Size = UDim2.new(0, 196, 0, 30),
            Text = __S("689bfa1854c0") .. tostring(defaultOption or options[1] or __S("06d373c94f0b42d11982")) .. __S("a50aed7a08e57baaae14"),
            TextColor3 = Theme.TextSecondary,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
        }, card)
        corner(trigger, RADIUS.control)
        local trigStroke = hairline(trigger, Theme.StrokeSoft, 1, 0.4)

        trigger.MouseEnter:Connect(function()
            SafeTween(trigger, TweenInfo.new(0.14), { BackgroundColor3 = Theme.BgControl, TextColor3 = Theme.TextPrimary }):Play()
            SafeTween(trigStroke, TweenInfo.new(0.14), { Color = Theme.Hairline, Transparency = 0.7 }):Play()
        end)
        trigger.MouseLeave:Connect(function()
            SafeTween(trigger, TweenInfo.new(0.18), { BackgroundColor3 = Theme.BgInset, TextColor3 = Theme.TextSecondary }):Play()
            SafeTween(trigStroke, TweenInfo.new(0.18), { Color = Theme.StrokeSoft, Transparency = 0.4 }):Play()
        end)

        local listFrame = new(__S("4342672bab47997936e0e875d83eeae72c24"), {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            Position = UDim2.new(0, 14, 0, collapsed + 4),
            ScrollBarImageColor3 = self.color,
            ScrollBarImageTransparency = 0.5,
            ScrollBarThickness = 3,
            Size = UDim2.new(1, -28, 0, listHeight),
            ZIndex = 6,
        }, card)
        corner(listFrame, RADIUS.control)
        hairline(listFrame, Theme.StrokeSoft, 1, 0.45)
        new(__S("e179e0dc98293191d1ce5347ef0ccf30"), { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)
        pad(listFrame, 5)

        trigger.MouseButton1Click:Connect(function()
            expanded = not expanded
            SafeTween(card, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, expanded and expandedHeight or collapsed),
            }):Play()
        end)

        for index, opt in ipairs(options) do
            local row = new(__S("7fb15a8d091040756b3c8d322dd5"), {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.BgInset,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Font = UIFont,
                LayoutOrder = index,
                Size = UDim2.new(1, 0, 0, 25),
                Text = __S("1de8d43e8905d5") .. tostring(opt),
                TextColor3 = Theme.TextSecondary,
                TextSize = 11,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7,
            }, listFrame)
            corner(row, RADIUS.chip)

            local mark = new(__S("bc204def4752624b01"), {
                BackgroundColor3 = self.color,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -12, 0.5, -2),
                Size = UDim2.new(0, 4, 0, 4),
                ZIndex = 8,
            }, row)
            corner(mark, RADIUS.pill)

            if tostring(opt) == tostring(defaultOption) then
                mark.BackgroundTransparency = 0
                row.TextColor3 = self.color
            end

            row.MouseEnter:Connect(function()
                SafeTween(row, TweenInfo.new(0.12), { BackgroundTransparency = 0, BackgroundColor3 = Theme.BgRaised }):Play()
            end)
            row.MouseLeave:Connect(function()
                SafeTween(row, TweenInfo.new(0.16), { BackgroundTransparency = 1 }):Play()
            end)
            row.MouseButton1Click:Connect(function()
                trigger.Text = __S("5a57c7a0f194") .. tostring(opt) .. __S("f88f415143f1bcd1d96c")
                for _, sibling in ipairs(listFrame:GetChildren()) do
                    if sibling:IsA(__S("96c6bb02a535421b750c861fb515")) then
                        local siblingMark = sibling:FindFirstChildOfClass(__S("34fe34b321958fb9b2"))
                        if siblingMark then siblingMark.BackgroundTransparency = 1 end
                        sibling.TextColor3 = Theme.TextSecondary
                    end
                end
                mark.BackgroundTransparency = 0
                row.TextColor3 = self.color
                expanded = false
                SafeTween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { Size = UDim2.new(1, 0, 0, collapsed) }):Play()
                if callback then callback(opt) end
            end)
        end

        table.insert(allSearchables, { frame = card, label = title .. __S("d335ae6438") .. (desc or "") })
    end

                                                                               
    function tabObj:AddSegmented(title, desc, options, defaultOption, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("716d2815241faabdbd"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 62),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or self.icon, self.color, 30, UDim2.new(0, 14, 0.5, -15), 5)

        new(__S("0fa4a1c65c31c91bc249fa100d"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 56, 0, 13),
            Size = UDim2.new(1, -380, 0, 16),
            Text = title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        new(__S("addc1b77ba8222a73b7bfce5fb"), {
            BackgroundTransparency = 1,
            Font = UIFont,
            Position = UDim2.new(0, 56, 0, 31),
            Size = UDim2.new(1, -380, 0, 14),
            Text = desc or "",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        local widths, total = {}, 0
        for i, opt in ipairs(options) do
            widths[i] = math.clamp(16 + #tostring(opt) * 7, 58, 104)
            total = total + widths[i]
        end

        local control = new(__S("4c1395285533ac30af"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -(total + 32), 0.5, -14),
            Size = UDim2.new(0, total + 8, 0, 28),
            ZIndex = 6,
        }, card)
        corner(control, RADIUS.control)
        hairline(control, Theme.StrokeSoft, 1, 0.4)

        local thumb = new(__S("ea4b0ed9779e0e643f"), {
            BackgroundColor3 = Theme.BgRaised,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 4, 0, 4),
            Size = UDim2.new(0, widths[1], 1, -8),
            ZIndex = 6,
        }, control)
        corner(thumb, RADIUS.chip)
        hairline(thumb, self.color, 1, 0.55)

        local buttons, selected = {}, tostring(defaultOption)
        local offset = 4
        for i, opt in ipairs(options) do
            local optLabel = tostring(opt)
            local btn = new(__S("8882888a7737fa4c2692e61bf931"), {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Font = UIFont,
                Position = UDim2.new(0, offset, 0, 0),
                Size = UDim2.new(0, widths[i], 1, 0),
                Text = optLabel,
                TextColor3 = optLabel == selected and Theme.TextPrimary or Theme.TextMuted,
                TextSize = 10,
                ZIndex = 7,
            }, control)
            buttons[i] = btn
            offset = offset + widths[i]

            btn.MouseButton1Click:Connect(function()
                selected = optLabel
                for index, other in ipairs(buttons) do
                    SafeTween(other, TweenInfo.new(0.16), {
                        TextColor3 = (options[index] == optLabel) and Theme.TextPrimary or Theme.TextMuted,
                    }):Play()
                end
                SafeTween(thumb, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                    Position = UDim2.new(0, btn.Position.X.Offset, 0, 4),
                }):Play()
                if callback then task.spawn(callback, optLabel) end
            end)
        end

        table.insert(allSearchables, { frame = card, label = title .. __S("26ba023bc5") .. (desc or "") })
    end

                                                                               
    function tabObj:AddLabel(title, desc, height, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("c4f17bec2ce08351c1"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, height or 104),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgElevated, interactive = false })
        card.BackgroundColor3 = Theme.BgElevated

        iconTile(card, itemIcon or CustomIcons.Players, self.color, 24, UDim2.new(0, 14, 0, 12), 5)

        new(__S("6328f59d049bd772015e14e2aa"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 46, 0, 12),
            Size = UDim2.new(1, -150, 0, 15),
            Text = title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        new(__S("01606f4e1e754fb76f149e2a1b"), {
            BackgroundTransparency = 1,
            Font = UIFont,
            Position = UDim2.new(0, 46, 0, 27),
            Size = UDim2.new(1, -150, 0, 13),
            Text = desc or "",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        local live = new(__S("9f97e8ff9da3873f51"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -66, 0, 13),
            Size = UDim2.new(0, 52, 0, 16),
            ZIndex = 6,
        }, card)
        corner(live, RADIUS.pill)
        hairline(live, Theme.StrokeSoft, 1, 0.5)

        local liveDot = new(__S("3dcf62b0ba6d37f7f6"), {
            BackgroundColor3 = Theme.Sage,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 7, 0.5, -2),
            Size = UDim2.new(0, 4, 0, 4),
            ZIndex = 7,
        }, live)
        corner(liveDot, RADIUS.pill)

        new(__S("dc06dc617019117dbec89dc7bc"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 15, 0, 0),
            Size = UDim2.new(1, -18, 1, 0),
            Text = __S("7a3e5612a0216c10"),
            TextColor3 = Theme.TextMuted,
            TextSize = 8,
            ZIndex = 7,
        }, live)

        task.spawn(function()
            while task.wait(1.1) do
                if not card.Parent then break end
                SkillHubStep(__S("1875cfc3c8e789ca0965f05312928ed479"), function()
                    SafeTween(liveDot, TweenInfo.new(0.5), {
                        BackgroundTransparency = liveDot.BackgroundTransparency > 0.2 and 0 or 0.55,
                    }):Play()
                end)
            end
        end)

        local body = new(__S("b6ad497446aaa4ed5b8cca342be499318eb7"), {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            Position = UDim2.new(0, 14, 0, 44),
            ScrollBarImageColor3 = self.color,
            ScrollBarThickness = 2,
            Size = UDim2.new(1, -28, 1, -56),
            ZIndex = 5,
        }, card)
        corner(body, RADIUS.control)
        hairline(body, Theme.StrokeSoft, 1, 0.5)
        pad(body, 8)

        local bodyLbl = new(__S("54e4c325915c7c51df4b2242e7"), {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = UIFontMono,
            Size = UDim2.new(1, 0, 0, 0),
            Text = __S("f31c3cd6621831cd258fddb41886670ea09ea47113e988"),
            TextColor3 = Theme.TextSecondary,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 6,
        }, body)

        table.insert(allSearchables, { frame = card, label = title .. __S("9153b687a6") .. (desc or "") })

        return {
            card = card,
            label = bodyLbl,
            SetText = function(_, txt) bodyLbl.Text = txt end,
            SetColor = function(_, c) bodyLbl.TextColor3 = c end,
            SetVisible = function(_, v) card.Visible = v end,
        }
    end

    function tabObj:AddLivePanel(title, desc, interval, updater, height, itemIcon)
        local panel = self:AddLabel(title, desc, height, itemIcon)
        task.spawn(function()
            while true do
                task.wait(interval or 1)
                if not panel.card or not panel.card.Parent then break end
                local ok, txt = pcall(updater)
                if ok and type(txt) == __S("2f8b30384dbe11d9aceb") then panel.label.Text = txt end
            end
        end)
        return panel
    end

                                                                               
    function tabObj:AddInput(title, desc, placeholder, defaultValue, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("cdc2a9e910d215f219"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 58),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or CustomIcons.Search, self.color, 30, UDim2.new(0, 14, 0.5, -15), 5)

        new(__S("6bfa239acad15fb78b92b6fe52"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 56, 0, 12),
            Size = UDim2.new(0.46, 0, 0, 16),
            Text = title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        new(__S("0a319d4b3336adfa3ac3803a1a"), {
            BackgroundTransparency = 1,
            Font = UIFont,
            Position = UDim2.new(0, 56, 0, 30),
            Size = UDim2.new(0.46, 0, 0, 14),
            Text = desc or "",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        local shell = new(__S("a86916fc01d79aefd0"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -210, 0.5, -15),
            Size = UDim2.new(0, 196, 0, 30),
            ZIndex = 6,
        }, card)
        corner(shell, RADIUS.control)
        local shellStroke = hairline(shell, Theme.StrokeSoft, 1, 0.4)

        local box = new(__S("46a090ad43986af87557b5"), {
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            Font = UIFont,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            PlaceholderColor3 = Theme.TextFaint,
            PlaceholderText = placeholder or __S("e4d80a5e031b73b4dbf666796b9f3203"),
            Text = defaultValue or "",
            TextColor3 = Theme.TextPrimary,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7,
        }, shell)

        local function commit()
            if callback then task.spawn(callback, box.Text) end
        end
        box.Focused:Connect(function()
            SafeTween(shellStroke, TweenInfo.new(0.16), { Color = self.color, Transparency = 0.45 }):Play()
        end)
        box.FocusLost:Connect(function()
            SafeTween(shellStroke, TweenInfo.new(0.18), { Color = Theme.StrokeSoft, Transparency = 0.4 }):Play()
            commit()
        end)
        box.ReturnPressedFromOnScreenKeyboard:Connect(commit)

        table.insert(allSearchables, { frame = card, label = title .. __S("830f840fe8") .. (desc or "") })
        return box
    end

                                                                               
    function tabObj:AddPlayerList(title, desc, height, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("2146fdc0194f790e56"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, height or 280),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgElevated, interactive = false })
        card.BackgroundColor3 = Theme.BgElevated

        iconTile(card, itemIcon or CustomIcons.Players, self.color, 24, UDim2.new(0, 14, 0, 12), 5)

        new(__S("bf7e7771cd7bfc125c42fbf153"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 46, 0, 12),
            Size = UDim2.new(0.6, 0, 0, 15),
            Text = title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        new(__S("5db5f122fe41dcfdb2dc08ec62"), {
            BackgroundTransparency = 1,
            Font = UIFont,
            Position = UDim2.new(0, 46, 0, 27),
            Size = UDim2.new(0.72, 0, 0, 13),
            Text = desc or "",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, card)

        local countChip = new(__S("fbed6ad3cefb67b00b"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -108, 0, 13),
            Size = UDim2.new(0, 94, 0, 18),
            ZIndex = 6,
        }, card)
        corner(countChip, RADIUS.pill)
        hairline(countChip, Theme.StrokeSoft, 1, 0.5)

        local countLbl = new(__S("9a24e4844ac60f8f599342d43b"), {
            BackgroundTransparency = 1,
            Font = UIFontMono,
            Size = UDim2.new(1, 0, 1, 0),
            Text = __S("385c5e358b73fd2982a94823432f1c"),
            TextColor3 = self.color,
            TextSize = 9,
            ZIndex = 7,
        }, countChip)

        local list = new(__S("d693d7e6a24e6265601c5142a51e679cb22f"), {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            Position = UDim2.new(0, 14, 0, 44),
            ScrollBarImageColor3 = self.color,
            ScrollBarImageTransparency = 0.55,
            ScrollBarThickness = 3,
            Size = UDim2.new(1, -28, 1, -56),
            ZIndex = 5,
        }, card)
        corner(list, RADIUS.control)
        hairline(list, Theme.StrokeSoft, 1, 0.5)
        new(__S("74cb5197de9d8aa1546d9a673ddebe42"), { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        pad(list, 6)

        local rows, emptyLbl = {}, nil

        local function actionButton(parent, text, xOffset, baseColor, tooltipColor, callback)
            local btn = new(__S("1302cb48894ea9de1d5bddd60efa"), {
                AutoButtonColor = false,
                BackgroundColor3 = tint(baseColor, 0.84),
                BorderSizePixel = 0,
                Font = UIFontBold,
                Position = UDim2.new(1, xOffset, 0, 16),
                Size = UDim2.new(0, 38, 0, 22),
                Text = text,
                TextColor3 = tooltipColor or baseColor,
                TextSize = 9,
                ZIndex = 7,
            }, parent)
            corner(btn, RADIUS.chip)
            hairline(btn, baseColor, 1, 0.78)
            btn.MouseEnter:Connect(function()
                SafeTween(btn, TweenInfo.new(0.12), { BackgroundColor3 = tint(baseColor, 0.7) }):Play()
            end)
            btn.MouseLeave:Connect(function()
                SafeTween(btn, TweenInfo.new(0.16), { BackgroundColor3 = tint(baseColor, 0.84) }):Play()
            end)
            btn.MouseButton1Click:Connect(function() task.spawn(callback) end)
            return btn
        end

        local function createRow(plr)
            local row = new(__S("b13a44f90dee647cda"), {
                BackgroundColor3 = Theme.BgElevated,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 56),
                ZIndex = 6,
            }, list)
            corner(row, RADIUS.control)
            local rowStroke = hairline(row, Theme.StrokeSoft, 1, 0.45)

            local lamp = new(__S("4f71beaabe6b36de8e"), {
                BackgroundColor3 = Theme.TextFaint,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 10),
                Size = UDim2.new(0, 2, 0, 36),
                ZIndex = 7,
            }, row)
            corner(lamp, RADIUS.pill)

            local avatar = new(__S("eda9385b0c0e1096b1"), {
                BackgroundColor3 = tint(self.color, 0.78),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0.5, -14),
                Size = UDim2.new(0, 28, 0, 28),
                ZIndex = 7,
            }, row)
            corner(avatar, RADIUS.pill)
            hairline(avatar, tint(self.color, 0.5), 1, 0.55)

            local initials = new(__S("8be0b20c084b57bab8fe9e94ca"), {
                BackgroundTransparency = 1,
                Font = UIFontBold,
                Size = UDim2.new(1, 0, 1, 0),
                Text = string.upper(string.sub(plr.DisplayName, 1, 1)),
                TextColor3 = self.color,
                TextSize = 11,
                ZIndex = 8,
            }, avatar)

            task.spawn(function()
                pcall(function()
                    local thumb = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    if thumb and thumb ~= "" and avatar.Parent then
                        local img = new(__S("2a182bbd03bd019cc2e17ad7d26a"), {
                            BackgroundTransparency = 1,
                            Image = thumb,
                            Size = UDim2.new(1, 0, 1, 0),
                            ZIndex = 9,
                        }, avatar)
                        corner(img, RADIUS.pill)
                        initials.Visible = false
                    end
                end)
            end)

            local nameLbl = new(__S("c84fa56eab837655283be9fff3"), {
                BackgroundTransparency = 1,
                Font = UIFontBold,
                Position = UDim2.new(0, 48, 0, 8),
                Size = UDim2.new(1, -260, 0, 15),
                Text = plr.DisplayName,
                TextColor3 = Theme.TextPrimary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 7,
            }, row)

            local infoLbl = new(__S("66871f1f5991b2b55555be8269"), {
                BackgroundTransparency = 1,
                Font = UIFont,
                Position = UDim2.new(0, 48, 0, 23),
                Size = UDim2.new(1, -260, 0, 13),
                Text = __S("04be98d02ee4858bc35101253e64"),
                TextColor3 = Theme.TextMuted,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 7,
            }, row)

            local metaLbl = new(__S("a2f61281c64d0cc7a40be9e96d"), {
                BackgroundTransparency = 1,
                Font = UIFont,
                Position = UDim2.new(0, 48, 0, 36),
                Size = UDim2.new(1, -260, 0, 13),
                Text = "",
                TextColor3 = Theme.TextFaint,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 7,
            }, row)

            actionButton(row, __S("412d8c32d386f0"), -186, self.color, nil, function()
                Config.SelectedPlayer = plr.Name
                notify(__S("df6505e3bb493627fe97fbe279250765ff"), plr.DisplayName .. __S("7d9c7f94e3593385722fa91a5cd68ef747165bc5097b09a203326b"), 2.5, CustomIcons.PvP)
            end)
            actionButton(row, __S("1bd3f9457379561e"), -144, Theme.Danger, nil, function()
                Config.SelectedPlayer = plr.Name
                Config.AutoKillSelected = true
                notify(__S("ba0b72f61daba517de62574bf3"), __S("5842eca7842ef1093650ce46") .. plr.DisplayName .. __S("f67a665820596a44ddd270708681713d45ff77feaad36115b5afd6552c"), 3, CustomIcons.PvP)
            end)
            actionButton(row, __S("94b1e0092577"), -102, Theme.Success, nil, function()
                if tweenToPlayer(plr) then
                    notify(__S("32e959baa1e145c7af67e778"), __S("d120d36b3997eedab1f02ecb588a2397") .. plr.Name, 2.5, CustomIcons.Teleport)
                else
                    notify(__S("6f584d1c152239a1f5a9ab5c"), plr.Name .. __S("0d8fc6cd86ce7f5165781a3b76c7ba58be8e2ca3f131a01210e389322fc371"), 2.5, CustomIcons.Stop)
                end
            end)
            actionButton(row, __S("abc7407e99f8b4"), -60, Theme.Sky, nil, function()
                Config.SelectedPlayer = plr.Name
                Config.SpectatePlayer = true
                setSpectate(plr)
                notify(__S("49feba2f61bdd7397defd41d"), __S("e83633e026c542f0ba04ed4c21d6e4670aabd68cdf") .. plr.Name, 2.5, CustomIcons.ESP)
            end)

            return { row = row, stroke = rowStroke, lamp = lamp, nameLbl = nameLbl, infoLbl = infoLbl, metaLbl = metaLbl }
        end

        local function rebuild()
            local myRoot = getRoot()
            local present, presentCount = {}, 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    present[plr.Name] = plr
                    presentCount = presentCount + 1
                end
            end

            for name, entry in pairs(rows) do
                if not present[name] then
                    entry.row:Destroy()
                    rows[name] = nil
                end
            end

            local names = {}
            for name in pairs(present) do table.insert(names, name) end
            table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)

            for index, name in ipairs(names) do
                local plr = present[name]
                local entry = rows[name]
                if not entry then
                    entry = createRow(plr)
                    rows[name] = entry
                end
                entry.row.LayoutOrder = index

                local _, statusText, statusColor = getPvPStatus(plr)
                local lo = getPlayerLoadout(plr)
                local hrp = plr.Character and plr.Character:FindFirstChild(__S("866dad91f606be0cab491ba89afad1d3153e8231"))
                local dist = (hrp and myRoot) and math.floor((hrp.Position - myRoot.Position).Magnitude) or -1

                local giantTag = ""
                if isGiantForm(plr.Character) then
                    giantTag = __S("24a52742c4acc49125366277c4")
                elseif isBuddhaUser(plr) then
                    giantTag = __S("c2dca0f3f2c2cbf06a85a8f836d9")
                end

                entry.nameLbl.Text = string.format(__S("61141aa421a9f83bbc8f15a819dd0ffbd5"), plr.DisplayName, tostring(lo.level))
                entry.nameLbl.TextColor3 = (Config.SelectedPlayer == plr.Name) and self.color or Theme.TextPrimary
                entry.infoLbl.Text = statusText .. ((Config.SelectedPlayer == plr.Name) and __S("ff4b945535e3e73b07c3de42ffb6581c21") or "")
                entry.infoLbl.TextColor3 = statusColor
                entry.metaLbl.Text = string.format(__S("9d830e0681c3daff9e267b2d352bc085c69fa536b8045f5e5899b336104d3cb2ac13819086ad4dfd08124f42"),
                    lo.fruit, lo.style, lo.hp, lo.maxHp,
                    dist >= 0 and (dist .. __S("3bba87b75c")) or __S("d9f201684a"), giantTag)
                entry.stroke.Color = statusColor
                entry.stroke.Transparency = (Config.SelectedPlayer == plr.Name) and 0.35 or 0.55
                entry.lamp.BackgroundColor3 = statusColor
            end

            if presentCount == 0 then
                if not emptyLbl then
                    emptyLbl = new(__S("78297b19688805202518a61d29"), {
                        BackgroundTransparency = 1,
                        Font = UIFont,
                        Position = UDim2.new(0, 0, 0, 14),
                        Size = UDim2.new(1, 0, 0, 20),
                        Text = __S("1660f4ca3859948749fc1bd57be6218fa9a79db417442d99c0c387c38dfeca749a01e352"),
                        TextColor3 = Theme.TextFaint,
                        TextSize = 10,
                        ZIndex = 7,
                    }, list)
                end
                emptyLbl.Visible = true
            elseif emptyLbl then
                emptyLbl.Visible = false
            end

            countLbl.Text = string.format(__S("b4986e7bf5871f0dbb174f171f58663777dc3e1828bcc2ea18ba"), #Players:GetPlayers(), presentCount)
        end

        SkillHubStep(__S("52cfe82c998dff7a0c0de16b6dbdcfd5e980c845fd3c4ad04b88b6a8e596"), rebuild)
        task.spawn(function()
            while true do
                task.wait(1)
                if not card.Parent then break end
                pcall(rebuild)
            end
        end)

        table.insert(allSearchables, { frame = card, label = title .. __S("f10761dd03") .. (desc or "") })
        return { card = card, refresh = rebuild }
    end

                                                                               
                                                                                  
                                                                               
                                                                               
                                                                           
                                                      
    for _, methodName in ipairs({ __S("8f3edb8ec8d1a33019e626e274a0"), __S("2d76553f7664bdb5b7e6e24454"), __S("cbadcef0a8450944ece9e40fa6"), __S("69e548a1b80a6e1945197ee7a7"),
        __S("081cc252184fc68d6e838a8cbe0588"), __S("a6543c03887f269622af2c5d5db04a38"), __S("448bb5b4abdc89226832e598"), __S("e2c32f65f3d6b97b9e82f97dde4cea09"), __S("80faa916fbd955519c61af29"), __S("1f3222c7731e332925ecde941adceb89da") }) do
        local original = tabObj[methodName]
        if type(original) == __S("bd699c780dc604dcf71b1dfa") then
            tabObj[methodName] = function(self, ...)
                local result = table.pack(pcall(original, self, ...))
                if not result[1] then
                    SkillHubStep(__S("5ba116298e3fa0") .. methodName, function() error(tostring(result[2]), 0) end)
                    return nil
                end
                return table.unpack(result, 2, result.n)
            end
        end
    end

    return tabObj
end
                                                                              
                                              
                                                                              

local TabFarm     = createTab(CustomIcons.AutoFarm, __S("f9d88fdaeabebab35eee98fb37"),       Theme.Iris)
local TabPvP      = createTab(CustomIcons.PvP,      __S("9810098b2b28700c4cc3f5456f621c43eb"),   Theme.Clay)
local TabStats    = createTab(CustomIcons.Stats,    __S("3647833cff94b961e8ff982853d11d9e703d"),  Theme.Mauve)
local TabFruits   = createTab(CustomIcons.Fruits,   __S("d47efceddaa358198091fb5b39510defd202"),  Theme.Sand)
local TabTeleport = createTab(CustomIcons.Teleport, __S("72b6769e78b7bbeb56cca255b1727f2554efe8"), Theme.Sage)
local TabESP      = createTab(CustomIcons.ESP,      __S("10edf04fd8b1846b68b23fbe7a61962094"),   Theme.Rose)
local TabMisc     = createTab(CustomIcons.Settings, __S("af256a003f8829e003955df7431644ec9f6fe7"), Theme.Steel)

                           

    return {
        CloseBtn = CloseBtn,
        FloatBtn = FloatBtn,
        MainWindow = MainWindow,
        MinBtn = MinBtn,
        ScreenGui = ScreenGui,
        StatusBar = StatusBar,
        TabESP = TabESP,
        TabFarm = TabFarm,
        TabFruits = TabFruits,
        TabMisc = TabMisc,
        TabPvP = TabPvP,
        TabStats = TabStats,
        TabTeleport = TabTeleport,
        WatermarkBar = WatermarkBar,
        _ = _,
        notify = notify,
    }
end

local UI = UIFactory({
    CURRENT_SEA = CURRENT_SEA,
    Config = Config,
    CustomIcons = CustomIcons,
    Hooks = Hooks,
    LocalPlayer = LocalPlayer,
    Players = Players,
    PvPState = PvPState,
    RunService = RunService,
    SEA_DETECT_SOURCE = SEA_DETECT_SOURCE,
    SkillHubStep = SkillHubStep,
    TweenService = TweenService,
    UserInputService = UserInputService,
    Workspace = Workspace,
    formatNumber = formatNumber,
    getPlayerBeli = getPlayerBeli,
    getPlayerFragments = getPlayerFragments,
    getPlayerLevel = getPlayerLevel,
    getPlayerLoadout = getPlayerLoadout,
    getPvPStatus = getPvPStatus,
    getRoot = getRoot,
    getServerStatus = getServerStatus,
    isBuddhaUser = isBuddhaUser,
    isGiantForm = isGiantForm,
    setSpectate = setSpectate,
    Guard = Guard,
    trace = trace,
    tweenToPlayer = tweenToPlayer,
})
local CloseBtn, FloatBtn, MainWindow, MinBtn, ScreenGui, StatusBar = UI.CloseBtn, UI.FloatBtn, UI.MainWindow, UI.MinBtn, UI.ScreenGui, UI.StatusBar
local TabESP, TabFarm, TabFruits, TabMisc, TabPvP, TabStats = UI.TabESP, UI.TabFarm, UI.TabFruits, UI.TabMisc, UI.TabPvP, UI.TabStats
local TabTeleport, WatermarkBar, _, notify = UI.TabTeleport, UI.WatermarkBar, UI._, UI.notify

                                                                                    
local TabRegistry = {
    { name = __S("4d5ce3b1e5349093e863f5250d"),       tab = TabFarm },
    { name = __S("eb945d62ee1dea806ed2b2275811376bee"),   tab = TabPvP },
    { name = __S("89cbd71334dd772f4e6309800b6a425009cf"),  tab = TabStats },
    { name = __S("280350c4af07f04f2bcaf15cd12b46710206"),  tab = TabFruits },
    { name = __S("c63aca757bd04c83d52c879eb357529fadb3ce"), tab = TabTeleport },
    { name = __S("64724426b823aca545b8b5b6a03c3bc47d"),   tab = TabESP },
    { name = __S("02a9bdd7d3c386de95ebb286e9a31eb71913de"), tab = TabMisc },
}
local tabCensus, tabSelfTest
                                                                                 
                                                                        
local UnloadSkillHub
TabFarm:AddSection(__S("a0e13788d742e9edd19ecc1ab27a46da8445fe76f2cd025bc4a26fcc954b62f1da7a14da34"))
TabFarm:AddDropdown(__S("3f18b139319280218e2a5b1e85e2bf9e8d3630"), __S("dd502aea3fe97ee6585d1b7eb8dd7b0eebbeeedc0de07f9146f5a087156e0d81a8b5180137b509bcfb03d6a34b187c8fa4533a"), {__S("7b87a49b7c85a8020a"), __S("19bf1e4cc40cfe4829"), __S("b7f697fd1b84e720d0c16189528b"), __S("562e11ae849edb")}, Config.SelectedWeaponType, function(val)
    Config.SelectedWeaponType = val
end, CustomIcons.AutoFarm)
TabFarm:AddToggle(__S("f4658b5f9e37b92aadbd370f74e87b9c5819c9b53707"), __S("929d0510bb4da5d139d6cff3376b61e3bd9fbf87f61068da9feaa1e524452a466bd27b44a3f50a07d1fb55cf59e6c77ba5bf612fe21eddf8f7f5168b375529e42754c7357e65a63bba159dd52c81"), Config.FastAttack, function(v) Config.FastAttack = v end, CustomIcons.Lightning)
TabFarm:AddToggle(__S("30d47ec1e66e0826fea2b7bc1a5ab88b42a194b48522909d5aaa89fb71ea8cf7cb4f"), __S("cf0bf87231de04addd3bbba52090d1b461f58b737dd68a9e190f90c52e933a50760f05bc7f0acc59753cd967c4e43b0f6ead0ff6268914b51ebc445cb1bc6991618c0abe37f49e62"), Config.AutoAttackAlways, function(v) Config.AutoAttackAlways = v end, CustomIcons.Lightning)
TabFarm:AddSegmented(__S("6d437223e649d1e6396e996344f01ec92efacc564e"), __S("0b7aebd404341b42a5a84fe78481ad87b917f7c5fdf4bfb636a2b566aa7377caf1ef72fd9460a8"), {__S("a9b26585d7e31631b6aaa402a598"), __S("47e9df365754670a"), __S("e62158e70a8e676c")}, __S("8458d2987b43a630"), function(mode)
    if mode == __S("22904c49361d5955edeb40d5be7a") then
        Config.FastAttackDelay = 0.01
    elseif mode == __S("c0c7c5fa40a22d53") then
        Config.FastAttackDelay = 0.025
    else
        Config.FastAttackDelay = 0.06
    end
end, CustomIcons.Lightning)
TabFarm:AddSlider(__S("5eff3fabaf71866063811313252f67b57c39e7b303887c0b"), __S("fd36b95c5f3a87c02c60c766b39d2bda03a39c0d19c7a4325a518d8517ee828550c30ca6dd52391eb70fcad7eb1827a021a9"), 25, 80, Config.AttackRange, function(v) Config.AttackRange = v end, CustomIcons.AutoFarm)
TabFarm:AddToggle(__S("9b6e330d8b4e7e2dcc83672c28f1ae4d321cd75802f204bef7412a"), __S("39a5acbe0ef6231785615fcf10fbf9582131689959ba3064de638b0059af29d771092aa61f08ec5041aa1e727fe03e705102f43f85050aad3c12744ca311"), Config.AttackPlayers, function(v) Config.AttackPlayers = v end, CustomIcons.Boss)
TabFarm:AddToggle(__S("d7dd266f46c5f1cbe377d34da22adb8d6423"), __S("7614a02069fa2cf23172b51254ee8366b3750e0038c6dd351f960e4782150c9ba77b9a3acd5d2afa39f59956b157ec156b6db9a49d"), Config.AutoBuso, function(v) Config.AutoBuso = v end, CustomIcons.Shield)
TabFarm:AddToggle(__S("144c19d168f6df1dbb950c6611e831150d5e1ce85d8720fec3d37795cd02c047b943c2"), __S("b2839382cb652fee5ab1c930a542829571fd8f6012f161169fc0f5502c8e090591797ee8601272a4ff5440e939cf285b7b74c5fee163"), Config.BringMobs, function(v) Config.BringMobs = v end, CustomIcons.Layers)
TabFarm:AddToggle(__S("50bb0d3355acf04d500c7badf94e312f08a57553501b0701d93139176f45"), __S("eef286e4d660e47dd947312ec51c0456892bc7e288db54ea781dfa01c83fd36bc7ba942cec40082e42dd1da29a506963ca9b4f9a140e7bbea0d7c8ef8d3f00e82bff55aba94d27793d50883ecb8ab1055921a1a0783025aafc3e80b65460dc9b87781ab9d59cce7620"), Config.HitboxExpander, function(v) Config.HitboxExpander = v; Config.HitboxMobs = v end, CustomIcons.Layers)
TabFarm:AddSlider(__S("8d2a009561449c05e77d6514a773dffcca18"), __S("2b617a464148492ff8d63eb15b4c6431bb785e669193b1510bdebbbfdc4f733e05c26d04a7c49d933732"), 5, 45, Config.FarmDistance, function(v) Config.FarmDistance = v end, CustomIcons.Teleport)

TabFarm:AddSection(__S("c998f3f7c8fdb449d4ee526e69c074b4f6c7a08a755163"))
TabFarm:AddToggle(__S("67d06da89b75996c716750cf3b8a36f264fc04"), __S("0607e7598e3bf88746556a6d94162c3efb1c07591136c8b747647c9c2be88a701ef9019680713c5b7e4d6967875e72f155de55381d2e7c82e5b694b16292e1"), Config.AutoFarmLevel, function(v)
    Config.AutoFarmLevel = v
    if not v then stopTween() end
end, CustomIcons.AutoFarm)
TabFarm:AddToggle(__S("a43f610ae465f477102fa5ad287138b4afa605959dfa6bc2b8"), __S("4276dabb0d9131036b867302737503fd38874b33c0a2d26f4ee3d75bdb9eca35340f2e51d89cb2fe5c7418a50ee49287dbd6"), Config.AutoFarmNearest, function(v)
    Config.AutoFarmNearest = v
    if not v then stopTween() end
end, CustomIcons.AutoFarm)
TabFarm:AddToggle(__S("e0ae546c9cc806d6440da2e64940bf8dadba9292"), __S("7ee5ce1d1a2e3f107e51b0adb17d73cba63c81183ea426e7e2db7dda46a8da0de33046d24172b1ca248b8cc5b4e61ee01c1f"), Config.AutoFarmChests, function(v)
    Config.AutoFarmChests = v
    if not v then stopTween() end
end, CustomIcons.HubCrest)

TabFarm:AddSection(__S("1d1d47cefec74d4371796e85d3b5eab51e5b6a99da8804f35f0f6247e5d3fe741a2a") .. CURRENT_SEA .. __S("bb54c17fa2e01e163aaf538f4b59"))
TabFarm:AddDropdown(__S("598c3b30b6feb7110392bf0df6f0af4a7a35670d4c6f"), __S("f7c3b4e1cbf21a6c3d8474f450b8109ac77bbbd04402fa5fe1795eb8a2ab864361d9438f1ac5de567f66c721f9"), BOSS_LIST_ALL, Config.SelectedBoss, function(val)
    Config.SelectedBoss = val
end, CustomIcons.Boss)
TabFarm:AddToggle(__S("95fb2e920732622025036197734452859adce39d28a6570f62d6e0"), __S("3432a8435fc87421fcef21be8d75db3d92f6f595a87a5a7f2c000b250565411f131b05fc11e41eccd15e36e97bf6abd9bca54f47"), Config.AutoFarmBoss, function(v)
    Config.AutoFarmBoss = v
    if not v then stopTween() end
end, CustomIcons.Boss)
TabFarm:AddToggle(__S("d26a21f45f7e7e2dea7373584e0440557dfb04abbedefe60d85c15b9"), __S("70a19ba5ec976e60db60c10448810149529651a65b6cf3435586853e872173075e5983d614ff4aa20f6f3233eceaca168a8b98"), Config.AutoFarmAllBosses, function(v)
    Config.AutoFarmAllBosses = v
    if not v then stopTween() end
end, CustomIcons.Boss)

                                
TabStats:AddSection(__S("0ed91556ce576b872d37507faea7116a652b4a38e5883fdb4b"))
TabStats:AddSlider(__S("ad108f07cfc2549ce50400899307e2655f9e27"), __S("4b4808b824898ce22ca91d7cd6a220b9adda3da8ccd918cc03914a1cd3479ea38bcd7d"), 1, 100, Config.StatPointsBatch, function(v) Config.StatPointsBatch = v end, CustomIcons.Stats)
TabStats:AddToggle(__S("e97f8269b1b9299ad83083c52b5e"), __S("87b6fc1a41564acf442f75616929bbc92e116c1924e8b392191eddedd7c37fcc16cd7dd9e46bb7548e7b585958cc9a"), Config.AutoStatMelee, function(v) Config.AutoStatMelee = v end, CustomIcons.Stats)
TabStats:AddToggle(__S("25ee75cb216e54b203fb1cc55e635bb7"), __S("c425ef7cf8c7340f98f63ae252f530ddd716f263fb096f7c5b89966b6b2ff906e6533b8a2cfb2e28e69fd23215e8ca5bd8"), Config.AutoStatDefense, function(v) Config.AutoStatDefense = v end, CustomIcons.Shield)
TabStats:AddToggle(__S("625d692df0b958fd1f9145b9833a"), __S("0094e2ded8e43b7d1efb61bfa805ca009e5f16b439b4d55ba513e3ef79980b6737801c6ed0e6cb6380d4d6fe6842da"), Config.AutoStatSword, function(v) Config.AutoStatSword = v end, CustomIcons.AutoFarm)
TabStats:AddToggle(__S("9ecc5c8f40a1ab9bbc1030e9"), __S("3d03d64044dad5681df974a6ef40ddad740ec832eee0d87ab2d43e725c9d4c717cb6cc82eca6fd354eb48743cd"), Config.AutoStatGun, function(v) Config.AutoStatGun = v end, CustomIcons.Lightning)
TabStats:AddToggle(__S("db3b4ff1b258b9712dfb8254b3a5c1b77acccc"), __S("7972c9a2e0247ccee7daa85593896cef7a1ee9d4d2c7b9e053183c68bf77b3bf289e810f6b14dec43361b927097564f38c096801"), Config.AutoStatFruit, function(v) Config.AutoStatFruit = v end, CustomIcons.Fruits)

TabStats:AddSection(__S("17aa4353922b49a10aea9ed5b2c9c9b7c901a796912b66e6667e18202f96df6866f339aa3deb29b7cf1da856a4"))
TabStats:AddToggle(__S("b5e1bd04e54c44b524060814128c6584103a9e4564c347"), __S("541936b5d3e37d1b39b48204e66c7e5e98067fce847eae6be62d04a286c2e9dde967ea4fead3688a5258a26c624b1a17bcee59"), Config.AutoSkillComboZ, function(v) Config.AutoSkillComboZ = v end, CustomIcons.Layers)
TabStats:AddToggle(__S("f250b06609274a3ad415827f51f78df59d28bbcfd9b2aa"), __S("90882a17f3e111fd62d50a4b52253ec3bb45c59111cc6d36cf5fbab1b8714d8bea42c251996da3bdc4ec6147164f59650229d0"), Config.AutoSkillComboX, function(v) Config.AutoSkillComboX = v end, CustomIcons.Layers)
TabStats:AddToggle(__S("2ebfa3c88a0d9ceec49157384941163d008c76a0f6a9a0"), __S("ccf71d7934a992d7b4e730550dafe9d213d89bf3bc6a720421559d48bad5c12b09e1dc59bdd6762f1ca20636bc314166b9a509"), Config.AutoSkillComboC, function(v) Config.AutoSkillComboC = v end, CustomIcons.Layers)
TabStats:AddToggle(__S("6b2e972a6e2579622d98b7cd40233d58a31176ab3e847e"), __S("096610db84834d15da3b5765664dffc157b51bf19bd280cf2fbeb23ffd344c532df546477a5d30fc2708ebf5ce509482c4ef1db8ebb2e274a35c"), Config.AutoSkillComboV, function(v) Config.AutoSkillComboV = v end, CustomIcons.Layers)

TabStats:AddSection(__S("a79d8a8ce26774667eaf9c82451acbac8182b51954e6da7be6a2837e3a8d3f07"))
TabStats:AddToggle(__S("45d5043d558455e0f6b157c6d5a953961a521a76836bb389017a7a62"), __S("e40c7deebd9cc8073813ad8abadaa317425b64eb47d6a0323a8868725d13872dd6096b128d302608edf21d7d6394"), Config.AutoKen, function(v) Config.AutoKen = v end, CustomIcons.ESP)
TabStats:AddToggle(__S("8243f79f667e2edd6f82b5e6c245088fcbbd03bc2de57637"), __S("207b715039e76b13282211f656ec04390f6087ee63930e9a565d9c4abd435217231feaddcf8aa40ede1d15a08d64301e"), Config.AutoRaceV3, function(v) Config.AutoRaceV3 = v end, CustomIcons.Lightning)
TabStats:AddSection(__S("beb2eb01abbb373c4b7bdea819cb5c4a2067751e3cecb950f4e68c"))
TabStats:AddToggle(__S("5cea64b24749b005a8bed622bf39a210a0feb039da86bf24408d9262f6c2446e663d"), __S("fb21de63e107c0f9073a125978389a136d1ad680acbe1d8a465d4eb15bf639d7b0ee8f6ed87bb0b236643149fa2814286c79d641f1d8f39d140b473c"), Config.AutoAttackAlways, function(v) Config.AutoAttackAlways = v end, CustomIcons.Lightning)
TabStats:AddToggle(__S("995958144a22b732257f388245695f4d05654ac67a611b62ad2846"), __S("3790d1c5725c013de8ef7121cc4e77eadcd913d7216196c863f2a8c6bb72f044148c130e7ef465646dd632d6e16bf5e0212fc789cd9a"), Config.SovereignHakiAura, function(v) Config.SovereignHakiAura = v end, CustomIcons.Wand)
TabStats:AddSlider(__S("d5c84b76c4d4252fb764bfdbe404f1b226cb1fd2443de985"), __S("73ffc5278718f3f21b8a356a9239fd7aa988b16c05328a2d4d746973c70f0ef6c40684d9fc744e0413d7ac2159a84102521a36f6fe3543b48347073d"), 25, 90, Config.AttackRange, function(v) Config.AttackRange = v end, CustomIcons.AutoFarm)
TabStats:AddDropdown(__S("12373ed8a8eb471ba20743d5ec3570f87941b6d3437c98aea33008"), __S("b06eb889a0dd5e3a357209362daf6cab2090c46df7a1b75db3bffbe52a09c11948f2f8813365df5d0cf035a73ff523f52833b6be8fbb3193dc14db0780c28e11843c16a3554ac7e1"), FIGHTING_STYLE_ORDER, Config.SelectedFightingStyle or FIGHTING_STYLE_ORDER[1], function(val)
    Config.SelectedFightingStyle = val
end, CustomIcons.AutoFarm)
TabStats:AddButton(__S("4ea6323a59ce90aac9ff55929db01d869d5481dea8e75c252fad2fb25b"), __S("ecddabeb19f57b781b4d81e884b532f4d7215e35e106ff95cf2b91001047e71e1fe52f02d79868a4eae340427767a4e51d3285c125ce34758e9c80bde9ae51be0f18d60a43550efcf115af8d0fdee0f1"), __S("8b15259cea7ced03060c3bcb0c"), function()
    local style = Config.SelectedFightingStyle or FIGHTING_STYLE_ORDER[1]
    local ok = equipFightingStyle(style)
    notify(__S("294c9f4db90d94be3a63ac9b7715f5e8903c"), string.format(__S("c78418fef61ffb6a05"), ok and __S("65bb92af1dbc327f38680b94") or __S("03f30c60ed7d993300e3b1a2c6"), tostring(style):gsub(__S("a22a8611e0736062e4c89ed7ad65"), "")), 3, CustomIcons.AutoFarm)
end, CustomIcons.AutoFarm)
TabStats:AddButton(__S("4061ffc28829e98ca906cbc9d46f1b70e1b88c780f4b0f92d146c42cafbc7c055cb9"), __S("de997973fddc37952e5e8ba0f2c416e7724f4130ad7fabd092b01d604bde9cc601d18692c5d617862dcd6c44836b8c33ba2763309fe935f34e1f1e3d2494e48b33bad53da20b45d7f77d19"), __S("7cd0f324f874542ac1d7cac712e255"), function()
    local ok = equipWeaponByType(__S("1b086cd5515dccf32d"))
    if not ok and getHumanoid() then
        local char = getCharacter()
        local hum = getHumanoid()
        if char and hum then
            local tool = char:FindFirstChildOfClass(__S("b93fe68605fc4d0d"))
            if tool then hum:UnequipTools() task.wait(0.1) hum:EquipTool(tool) ok = true end
        end
    end
    notify(__S("5777603722e98700009fbb3559e0a5"), ok and __S("f5aed9e8c7b56d54f52e12a6cb058a6ad27adcb256d1c86526673a3f73fad258") or __S("93e653997d707a0c990184069ce62245416ba4340010ec1c4fb67880c19611c2"), 3, CustomIcons.AutoFarm)
end, CustomIcons.AutoFarm)
for _, style in ipairs(FIGHTING_STYLES) do
    TabStats:AddButton(__S("321dcd4ad53e5e621232") .. style.name, style.tier .. __S("d05546fb5ecd58bdc47176") .. style.remote .. __S("6e8cc0acc041fe09ff5c032592630e4fa2bae6e28fc72f69c0ae9d168d90568ae0"), __S("0cc43a5d89fa6e718a2e"), function()
        equipFightingStyle(style.name)
        notify(__S("aafbb40e1523b00b27ea547484718fe453be"), __S("49332dbf0e80b9907f83a9b78c70688c") .. style.name, 2.5, CustomIcons.AutoFarm)
    end, CustomIcons.AutoFarm)
end

                               
TabPvP:AddSection(__S("e76aa770b3854a899dfd076c50ca6896379a3dea1b843df1e8d31069088926efcb258f"))
TabPvP:AddPlayerList(
    __S("85a22121f1180352d17103e6e421dd536c72"),
    __S("23d99ad2b2f5f0083eb0f39684837a885757f300e8f651a0c7befdf244c25d2123a7e75156b9116af30dac99a93cdb630914eed5176751a9e1e593da96f6c0dfad0dac7c5b2379db6401bd5f5382d7cc25fcd8fd051f061a87ed81b19a0f0b306ac2a6c757dfa3d5da4a7109168519974f8089ce0f4d365153c49813af62c8a07115d0babc7d488c7e230386c623097e"),
    286,
    CustomIcons.Players
)

TabPvP:AddSection(__S("c2111483eb766f414f7b5c"))
TabPvP:AddLivePanel(__S("60488e34c38876e70921a0b6d2f181"), __S("fe8007e5ca66effb722797845e4ee5db4d04f49e70cde80973b40a499988fb1c160eab5fb7f02af7f1eb0a8e3c8f442d64"), 30, function()
    return "RightShift  →  toggle Skill Aimbot / AimLock\n" ..
           "RightAlt    →  toggle Undetected Bypass Fly\n" ..
           "LeftCtrl    →  park the fly (stop dead in the air, press again to release)\n" ..
           "RightCtrl / F9  →  show / hide the Skill Hub window\n" ..
           __S("9cb781960764103a74ed2cbb1dbc17198fffc5fce7f3cb38d7d16a1ac2a82d2d5b2bc2cf2d5120a1a21f5b6e093d552878591f7062cfb1f4344a5256")
end, 96, CustomIcons.Aim)

TabPvP:AddSection(__S("3aeefb475070cb6b286d3918f34b5bce51"))
TabPvP:AddInput(__S("d92674f8f094b9309311a609d0298cc5ad4e20ba6c52"), __S("775deea9197e5b55c53b2948301a2cd71f38ed1ff13391f0d97800bd5f546e4b09be94417845ab865f9161fbec4b7a34e0de0b78f135"), __S("1595685ae0c59ba8068ee06cef269b"), Config.SelectedPlayer, function(txt)
    Config.SelectedPlayer = txt
    local plr = getPlayerByName(txt)
    if plr then
        notify(__S("b3cce20b39552526ab1fb85acda2510a87"), plr.DisplayName .. __S("52045bbc8594a4c0a5ea2d086842cdb392ff82e18373c3e941b88d"), 2.5, CustomIcons.PvP)
    elseif txt ~= "" then
        notify(__S("f03bd56db2e105792996"), __S("8e734f1e58df2008cb4332ef579b79949c1c7199c753f8") .. tostring(txt), 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Search)
TabPvP:AddButton(__S("2caac8cf9a3cee9132e69c9b4dfc4b148324016e1277e2"), __S("cae24280aa8a2a6bd4b69de51166f561f5d2dd8a180c4b8017bc4c7a70c3a08a2e50bab9601b2a3f2e8a970e442256623f897884030d"), __S("6919bc31f28e670616b4c2a46a4b161e"), function()
    local myRoot = getRoot()
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild(__S("075135e2dc184a7e07b8b9aa5ea0363e377fc073"))
            if hrp and myRoot then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < bestDist then bestDist, best = d, plr end
            end
        end
    end
    if best then
        Config.SelectedPlayer = best.Name
        notify(__S("a588af933a3d46dcbb608cc8919ca80859"), string.format(__S("43c02944159c27a3f06fa4747fafd7b7b4a7"), best.DisplayName, math.floor(bestDist)), 3, CustomIcons.PvP)
    else
        notify(__S("e1f7a2f555441693977b"), __S("802f1ca6551638cf9424b60749c8b8682df17ccdbfed459d6765"), 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Play)
TabPvP:AddButton(__S("1e66965775437046d7e629106ea7b30e188a2e12add5802241b936ac0874"), __S("bc9e1008e60ea0dccf3643c46c0045e065ccecac0ce2122bff8b34988b452a6ef9b405440a681231ad9481a4f3dab8a04a59e39e68af9b"), __S("5ad589b91cb791ccfc4a5a67"), function()
    local plr = getPlayerByName(Config.SelectedPlayer)
    if tweenToPlayer(plr) then
        notify(__S("f90d036acea0a1123c1528cb"), __S("97447d1b3c5b095931ad48a1e765a3f3") .. plr.Name, 2.5, CustomIcons.Teleport)
    else
        notify(__S("357bf6cce967891b06bc5664"), __S("d3b3707d973892a4c84b3bb15b187d74a9819d04271255a94b37bb8dd81c2c6c7f53edafa5"), 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Teleport)
TabPvP:AddButton(__S("71eaea2e0ab8fca6fe89f5e1dfc7391e571aa7"), __S("102263dfdff3dce1cc1b3fcd7986956c32e77313a0a89b8baa36fa277a7eaf3d1b8a5b87760e243c3b3046e82b"), __S("ae59dd9096e5d41f5f6aff78"), function()
    Config.SpectatePlayer = true
    setSpectate(getPlayerByName(Config.SelectedPlayer))
end, CustomIcons.ESP)
TabPvP:AddButton(__S("4c9157418ebcdcd49651d3cee8507e01be9ed4"), __S("eac8d0f2eb823a34ec16466542f3e7717276e1f03ac2bfa5a6aec0c2f5de60e3afe39b28cc2c324590b1de67"), __S("89004aa3faeb4b48"), function()
    Config.SpectatePlayer = false
    setSpectate(nil)
end, CustomIcons.Stop)

TabPvP:AddSection(__S("2737c4549a5ca8551cc4d57a979abcbedd5be308911f33db391ff6ec1901"))
TabPvP:AddToggle(__S("c56f3e05531917be5432723e389f6303673632c34f6c64969570e9b2a4"), __S("63a6b7b690d65a2174ddd0433e452ff813ce944c92cc538223ab40782559e9eedcfa97fe1179e16aa9b90a3b5ca3bed10fa4ce9d472ba9a5ec5b93b8a05b23cb378b6fdb7771413f697af676bcb83b5a7c9c"), Config.AutoKillSelected, function(v)
    Config.AutoKillSelected = v
    notify(__S("01de31670ecf92d6c3e58a4bca96"), v and (__S("a015ab188bfb2d1cb2cc8dfa") .. tostring(Config.SelectedPlayer ~= "" and Config.SelectedPlayer or __S("3e4d24c9ad741154d12749"))) or __S("dc849e7a6ca37ca470b83dc2f484df7c36598e3d2e7bbb36d24e662f0d64b508268d23"), 3, CustomIcons.PvP)
end, CustomIcons.PvP)
TabPvP:AddToggle(__S("7abc182b56cfa854d9d97d37f4347b4514f5da4d59ececdb55106551d06257cf7c"), __S("18f391dcf9b04e886c82574c57413be14e9a77e0c928f3d292ad07acde1fc89ecd9b7ab552db767e418cd48b843d8031aa7861b432a6c8dc84664ce234ef2082c0442a85188688cd80c2b2104c"), Config.AutoKillPvP, function(v)
    Config.AutoKillPvP = v
    notify(__S("b72b0b8df07dbfb7d65bfee494cf"), v and __S("5562853e14ba1d9044d8b803315e7ac9cd4b9ac7acb29efe90db75a0572973a8686693") or __S("f399feef3da85dc0fdc48750274efeaf3c0eb04a"), 3, CustomIcons.PvP)
end, CustomIcons.PvP)
TabPvP:AddToggle(__S("91d178a0cb6d17fff1989936ca1e51eece64"), __S("3008f25123e10273e60a72dccae0fbb37ac6be8c5864bf0377f4c4fdc9d53e1727a0c859ebcfcf21cd57c5"), Config.IgnoreFriendsPvP, function(v) Config.IgnoreFriendsPvP = v end, CustomIcons.Shield)
TabPvP:AddSlider(__S("ce406c02eab3061d6a40601824e3789934db"), __S("6c77e5b3e04020878d810af8097d673d4c07950bcc32e8ae3ec6c3f47be5fa01844b7c66950febe4ad9f18bc3d387a1b67e753d8e38118ba961cadce4b70fd77f917cb0ee11283afad313c60b7be632af5af"), 4, 30, Config.PvPTweenDistance, function(v) Config.PvPTweenDistance = v end, CustomIcons.Teleport)
TabPvP:AddSlider(__S("0aaf5f642ee19e4eb72de5cfc87f23298abd6237"), __S("a8e6d915562469463bbfa6a68585fecb62ad355e2cdfd40347948b51ddf019fe200d87bfee98a941d2d0c7c0ad963f7ee3545e8729"), 30, 400, Config.KillAuraRange, function(v) Config.KillAuraRange = v end, CustomIcons.Lightning)
TabPvP:AddSlider(__S("471e52c68413cd348fef5793c870ad0ae9d48fe1ce1cfe9ed7"), __S("e555cc7709b77190ea3908e45d3af7ccc2fff69cb5cb16d1e2e3340067f7ac05cc934b491e465ad2061947fe3d1274c67ff0f1238ec36106b0a5b105d78ab6c72d3b49d608d06943c7b71dae73dedc20d6e8116b9dd048dcd9"), 5, 50, math.floor((Config.PvPAttackInterval or 0.08) * 100), function(v) Config.PvPAttackInterval = v / 100 end, CustomIcons.Lightning)
TabPvP:AddSlider(__S("838d46285fc67503783e528cf9d606ac67627b2255da9a22"), __S("21c4bfd955e080c2a6102486edf466cbf4b1c74058a17a159d31eb4e23c324899924ad7a32541a310394301fe61f3d14c6ead7f0632f"), 15, 100, math.floor((Config.PvPSkillInterval or 0.4) * 100), function(v) Config.PvPSkillInterval = v / 100 end, CustomIcons.Layers)
TabPvP:AddSlider(__S("bffc398a246f6621f5502ec16271aca5188b8e43f6dff4"), __S("5e33b33b74fc880be31eba4936c2a2ec022680da0427213ee8947e15e75971a893da306c4cf0245400695c1f5357f22768f2e1eea353993c3d8c487d17d8f7ef21982d077a2e344af0c5e6"), 0, 40, Config.PvPHoverHeight, function(v) Config.PvPHoverHeight = v end, CustomIcons.Teleport)
TabPvP:AddDropdown(__S("fc6b2ceca38cccc595a304c0d92bca7c1b4466"), __S("9aa2a69d4d74f91900fcf23e87f824a1f5ee43abf1ec69422546564a778b7e1cb2b8ab515243caa2"), {__S("38da204e89baf321e610e1"), __S("d71199ffa43ea98d2d8e52aa8f"), __S("754913b098fa0f4b9cade7")}, Config.PvPTargetMode, function(v) Config.PvPTargetMode = v end, CustomIcons.Players)
TabPvP:AddToggle(__S("13808d61d657ae58c639a85979d77822cd1b75b9f3d98cb59cdbd81b7e99b112"), __S("b1b807121473ae17c504ba71d268ca204701d798b437012e483a29c5dd9e885e6ab580fbe0ab0c3399cc204c33118b7a1e243389c308f15ebaefdb63cc81ecd6393fa4b5bba62b182085c4c2016a0f443e89f7ee620dc6a1ce"), Config.PvPAutoAim, function(v) Config.PvPAutoAim = v end, CustomIcons.Aim)
TabPvP:AddToggle(__S("4fef80c3792ebef3cda56ab5260a8f973a5324c69e97f22c84164b176ac1259ccdb6870c305989363d7f3dc9"), __S("ee26fa7489f8eed6a430eefaec48413774c59038d46020af360d0698444d566eaae9eba5142af16c1ffb594b972e2713dd0311ada45188912b5e5eed3104d8f2a3bc4178d713e988cd68dc29308fdf660da3662263f5"), Config.PvPFallbackNearest, function(v) Config.PvPFallbackNearest = v end, CustomIcons.Search)
TabPvP:AddToggle(__S("8c5e742509fbc58cc09bd97e73ca0944599746936ddb407dbc84cd1f7086cfa91f399066599aa155"), __S("2a95edd6274f594fe7fd46f1d3e6c38d3c5d8f8bcfaa83bdea80ef1fe2536376f00fe4815db553a6a8f044378e"), Config.PvPSkills, function(v) Config.PvPSkills = v end, CustomIcons.Layers)

TabPvP:AddSection(__S("c8cd6787ea9ca926b8e671d0d6787266f7293a09dc18f26a7b47"))
TabPvP:AddToggle(__S("6704e138c8f00bad73c565379ccae0be532d6ae4c5c1ce8bfc7c24972e7ce285e81c"), __S("053c5ae9aa78f95a91fe829e854d8ba6f63c316524d54d4c11f8606211f5aca2c14089754a8de2eb0e5b1d486d21fd3345930aaebc45b718c6b467dc117925070015dd7f24"), Config.AimLock, function(v)
    Config.AimLock = v
    notify(__S("a373d49a790c6e39d079cc313d7d4d69"), v and __S("41ab4e4b7b726164f77ecead4f7e306df7370e05d67520649d4a5d1960eb398f681a1a650ad03752") or __S("dfe2c7fc7346d7a9c04c1d952dc9e6c53569fbfa"), 3, CustomIcons.Aim)
end, CustomIcons.Aim)
TabPvP:AddSlider(__S("7e1a41adbb04187d2472782db69af836e9041c07bf70"), __S("1c51bb5e9b92bd84b2a2f7bd6bb680732f2a2d9cf63cd6fb2cfa96996fea0ceb4132a86ca1118d51f4c8421a80d96b4a0324"), 8, 100, math.floor((Config.AimLockSmoothness or 0.28) * 100), function(v) Config.AimLockSmoothness = v / 100 end, CustomIcons.Aim)
TabPvP:AddSlider(__S("ba89350f3a28a8ab92c4b493792e53269f9ca8c6b4bd1e"), __S("58c0aec085338103a50cddf709b62dab6075ae11f5357c666babd8c545435afe7d06d6e8ba3763237b"), 0, 2000, Config.AimLockFOV, function(v) Config.AimLockFOV = v end, CustomIcons.ESP)
TabPvP:AddToggle(__S("f6f828719a768ea92c9689a0eccc3dd98d768e4e167b4762017c"), __S("952fa2223e16537d7b2f27f397da22405b9dd0b4751c129550d95c9cfa860ede3a30f065f408090a6bc74d17dc24e1ba4bc9dab2e0a54f5246c65c5af274233162bbdc31e57a"), Config.PlayerHitbox, function(v)
    Config.PlayerHitbox = v
    if not v then
        for name in pairs(PvPState.hitboxOriginals) do
            local plr = getPlayerByName(name)
            if plr then setPlayerHitbox(plr, false) else PvPState.hitboxOriginals[name] = nil end
        end
    end
end, CustomIcons.Layers)
TabPvP:AddSlider(__S("33671bd335ec9c35b655340179c88085df21953f3058fc"), __S("d19e9584365a4904017ca4b7234bc430650302ecd999b43e1d80f08557ac82ce4930c82ad4aabffa4f08c5b84f7daedfec5786ad6f084983ddd5193194afeaeed99e7d26f5fcf8a537d3a404c8992e75786377007a904809be783b7053ea9be26b0fd15f9b601060"), 6, 200, Config.PlayerHitboxSize, function(v) Config.PlayerHitboxSize = v end, CustomIcons.Layers)
TabPvP:AddToggle(__S("6fd60f35c87a3ca9bb17694f419b9a6b8aeead82b0e881d908b1a8abfd7092ae3716"), __S("0e0d88e6e75369cef6e7f032c9f511c83b02e5d9118ba4871f3bc7918767f1e1f388629f06052df5797f7bbbc2ef352eabb47f43e4afd90e199d05edf3e51ea41f1a500f66128f313eec65aadae9073845d47d"), Config.ExpandAllPvPHitbox, function(v) Config.ExpandAllPvPHitbox = v end, CustomIcons.ESP)
TabPvP:AddToggle(__S("ac4502975d6c012f0f14ea07a5757878a5dbba77b1bab404c9545cc13504959f4f"), __S("4a7c7c48b4773da09fd2a2a8c2daa383d6e78ae753e898d779a0300870e24d5630003493d532b472cbcaaa5d1db46c91d29175d2ecba"), Config.AttackPlayers, function(v) Config.AttackPlayers = v end, CustomIcons.AutoFarm)

TabPvP:AddSection(__S("e8b3f5f957882a275959ae420899eb6b810794df5db89835951e2cd65684cbf3ae78e6fac8cdef6b5f94050fda5b"))
TabPvP:AddToggle(__S("86eb6faac792c5e9d2b99a37469fcc492428312bf6ac44dadff33e6cfbb189"), __S("2522e95bfbce4a57b24fe99b1e71b8e472b8c56d2d247491d3ee28b4ab01eb421f0ddd74765adc62a3cb1cd5f33f1743bb7a63fd7b9b1f796e871c0a6140498d7d953695f0bb22913fee25e60bdf8339f245a0096b9b0ff98e6b8c5bd7cbf3126e8a367b551959fd8602e789135fdd9bd1"), Config.BuddhaAwareCombat, function(v)
    Config.BuddhaAwareCombat = v
    notify(__S("c35a630cf32825b064a0ee8c9e43f5443a"), v and __S("6191dcbd39f6c8a5f45334da0f934cb80d2b4f65df9e85fc301a8a1341e93995e533f09a533f") or __S("ffc9566e3f23d65b11fc0da3a5611357f106bd0b6990c27c3ed2cfae0ec39e43"), 3, CustomIcons.PvP)
end, CustomIcons.Shield)
TabPvP:AddToggle(__S("9e00d01f953cbde03ec2ca89f75290432c9175de2bcd3d6c27d56d64c4048bc48a9d94"), __S("3c3849d03077202bfbab7d51834204b99c066bbd57fe57d35afe6edb6c0dc67a7195e2de1392126a5dfebd55de941960bf7d17d9383dc0994ac869f6be8ef86463ec81e638e20d373836685b8e6a7fcc510154"), Config.KillAuraAllPvP, function(v) Config.KillAuraAllPvP = v end, CustomIcons.Lightning)
TabPvP:AddToggle(__S("da6fc3811da2a9447070feee18fd7f0a4a79d2537384bb09521c"), __S("78a73d32bf8f010e254214fcf4446da7c49634dbc3c5a4bc773ee2748488536bd7b6ed51ca9e4ede00a675a93757c0be50aaaed6834ad108646415ebc9172b4133a054c27142cb058bb7941db5e9"), Config.ShowHitboxVisual, function(v) Config.ShowHitboxVisual = v end, CustomIcons.ESP)
TabPvP:AddToggle(__S("16deb6e3ef0d8676b4d0a3e8c2eee9f015d0bada22d788"), __S("b51630949fef0be839073b1a42066b99754ea99b862ea4972e6555c1c509112fb4720c9f928807606cb9c984d2b0bb2846e85c565ffa8cd1cddeacdaafd2205af898f51c7a6aa56fb7ef7585d1dca27c14"), Config.HitboxMobs, function(v)
    Config.HitboxMobs = v
    notify(__S("534daa45ea87a372bb5dcdf22571"), v and __S("f18523f6264396562e614750ba095ab8f83ef1aaa5b05ab034") or __S("8fbc9da78ed3aedeadba4e7f209ad85b7134e28619443ca2fd"), 2.5, CustomIcons.Layers)
end, CustomIcons.Layers)
TabPvP:AddSlider(__S("2df417587a60cbd018bfa5af37c05ced452628"), __S("cc2b9109c44adc7484dc5603af1f7821f2ffc6ce7123bba8ef92e1caee1dfea5048dd3898571a7bb7768ffc25c214230e0286810924ecfec0cddc3fde319e1874d8cd3ca668ac29e109f526233f2ec"), 10, 200, Config.HitboxMobsSize, function(v) Config.HitboxMobsSize = v end, CustomIcons.Layers)
TabPvP:AddSlider(__S("6a630aba6da3b29c07b994e2dd299953bdc441c4"), __S("089a846b2f1f13fb7af332b25debc5c291a1760ee57efdd4bbd7379e15f02a41d099a545f18633a7d634fa2c44648b"), 60, 3000, Config.HitboxMobsRange, function(v) Config.HitboxMobsRange = v end, CustomIcons.Teleport)
TabPvP:AddToggle(__S("a6d1fe1c667f58468765bbcaeea74188424d288970d55e10b2"), __S("450977cdd218a80ad31d2ca16138ff3ab79fd81bd7b29e10b9435fc7951e6ccb0b78e7bf9e9788285a4cbee164a473d2d8f4a0c1c459c94ea4cd594fb2beaa7346aed17f28c9e674ae086ae97e9e8c17ff31b73533a48bf73c3e4e019701620f25f7a202adaadad1a9b97d21adc7c40c4df529584d"), Config.HitboxWholeModel, function(v) Config.HitboxWholeModel = v end, CustomIcons.Layers)
TabPvP:AddLivePanel(__S("e340f17eab31644ddc820c4f8696d926663a931b43c5bdaaf169"), __S("81786b2f6d4a35a79dd571039fc0db9d9664e4414387a50681c050e7237f2299f80a871a640e207f9bd590c44f"), 1.5, function()
    local lines = {}
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local _, size = getCharBoundingBox(plr.Character)
            local giant = isGiantForm(plr.Character)
            local buddha = isBuddhaUser(plr)
            local hrp = plr.Character:FindFirstChild(__S("1fafe4e011a91d448320ef2ae63e937048519f7d"))
            local dist = (hrp and myRoot) and math.floor((hrp.Position - myRoot.Position).Magnitude) or -1
            table.insert(lines, string.format(__S("bde75e91ced91ab218a0311429affe033d24c725fd2a1fa19fd46c50ece1dc576a6bb049a23f6c7e03fe04fa1c59"),
                plr.DisplayName,
                size and string.format(__S("5c1ed842cc2ff7a1e8a6671558"), size.X, size.Y) or __S("fa5651f318"),
                giant and __S("988dcba41ffde371638053567e13") or __S("36c545554c4258b4f303"),
                buddha and __S("d4fcbf06a873a17399a2e0d58f9bfa317879") or "",
                dist,
                PvPState.hitboxOriginals[plr.Name] and __S("733438b72303354b0df024d7") or __S("116bb268f5c60cc26b19")))
        end
    end
    if #lines == 0 then return __S("afa32c1967720f045b39de36e041f467f320574d4909814459e21c12a38ea7b3b9a22f248ff90d51f1bd8a03423e19") end
    return table.concat(lines, "\n")
end, 170, CustomIcons.Shield)

TabPvP:AddSection(__S("4ddaa5ca4b39820117c2478992b466d1455baff814ca0fff954df708e301eb1b30caeefb797157b128087c34c5a4e813966c"))
TabPvP:AddLivePanel(__S("ec121f7b7587c125ba23ae3cceb3a74734a6"), __S("8a49992cb60ca1689ef5c64a0428684bc88fa6365d3aadd14030c78e1b24da0adc10d66fb31f3797743f61c53a8e9a95d063b63bdc72468566ebf0d7047ed1711d93c42d112b2e2133a97efa0a2ec293c22acf8d6323d3"), 1.2, function()
    local lines = {}
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local _, statusText = getPvPStatus(plr)
            local lo = getPlayerLoadout(plr)
            local dist = __S("288112dd9d")
            local hrp = plr.Character and plr.Character:FindFirstChild(__S("c6b88c8e124cf89d2738cef284cf987b94a8bfd8"))
            if hrp and myRoot then dist = math.floor((hrp.Position - myRoot.Position).Magnitude) .. __S("64f0063fc9") end
            table.insert(lines, string.format(__S("03277ff039124232ed30378747f0898d5a3baea0c51bb230ce35aff32cda9677567f2be9ddf781d50de9b787ccf5377891a631f67965edaef5d83ee735e96dbf52f323d303d513ad668452c9d6699a5cf8"),
                plr.DisplayName, tostring(lo.level), statusText, lo.fruit, lo.style, lo.sword, lo.gun, lo.bounty, dist))
        end
    end
    if #lines == 0 then return __S("a15ef9a15a614c0dd9972e4e01e1bdc0949f5d3eeb677058642bbf26df76a4aeced74837") end
    return table.concat(lines, "\n")
end, 200, CustomIcons.Players)
TabPvP:AddButton(__S("3f9673527c06ea646f14a2876ead641ff9627a18bf0b2bcf5bf7f95a64"), __S("ddcded03c2933803870c6950cb18cdb8be5bdaa8b900a4cf82589a294ba708c275b39c452c345c4c5602fd4617a591dd993bc69a2ec4c1ff1fff5f5f1c"), __S("7c0566b42f7ef70c5f34"), function()
    print(__S("1a3ce0653f9d238ad20ec8fa08944dc2a69e4a5cd9bf86e182988ee0b1c752ee07f1064d9fc68c14735f81e6f36074d8afbd780e85ac3c35900e1023f826aef86a"))
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local attackable, statusText = getPvPStatus(plr)
            local lo = getPlayerLoadout(plr)
            print(string.format(__S("b8745a16765908663f3edfc26ea55c346d6d9d8ec1f13ab73e23d8eae8d172c9ecadad026caaa3a19c397e99646257ac3efcf00f3dd70cb67aa19ad620284e8140f5553325c5ecb947dfe3b366b7fec86d0231edfd556c14aaa141a7486175017b1d8b89d6f0509b9b"),
                plr.Name, tostring(lo.level), statusText, tostring(attackable), lo.fruit, lo.style, lo.sword, lo.gun, lo.bounty, lo.hp, lo.maxHp))
        end
    end
    notify(__S("56abd3c73e3f0d3b498ed767b737e4fc21"), __S("f4e34d7858aca14b7a8c0aa1b14c7b3f73551dce699e52807da72385c20984f338c3250744de4031348b21b4335517b498ea81"), 3, CustomIcons.Players)
end, CustomIcons.Search)
TabPvP:AddButton(__S("931ac72955ffecfb8da2ef99fc2f5b8e3f6e274e31482d7dbe27e09fcb2027"), __S("315240daee802b0b18ca02ac02939f37df4f1c9dacc35bdfd9c938e77dde75b2f42a7e2ce7180d179798ef08b2c10cd0356f1f7a245ef3"), __S("cf89ba8b5713a28547c0fd3f521dbd3a"), function()
    local plr = getPlayerByName(Config.SelectedPlayer)
    if not plr then notify(__S("6dc1343c2fbe321adcd2fe4ae57cb63dbf"), __S("0bf8aded6160871a7dfce6cefadd8e6e91bf96d8"), 2.5, CustomIcons.Stop) return end
    local _, statusText = getPvPStatus(plr)
    local lo = getPlayerLoadout(plr)
    print(string.format(__S("aa30279e4460fffc7f4f05210a04f71c0418502d5b9f1c79bb3306b7844204ad00b3f8d2022a5095e2906179539d259c48c7a1c99f28ff47f6e2a3bcd05103c353f614d7307626359ab01b49fab0be4ac407ede1b94bece5ad76f0e06fc9cf34c9637a3f3cd67d"),
        plr.Name, statusText, lo.fruit, getFruitTier(lo.fruit).name, lo.style, lo.sword, lo.gun, tostring(lo.level), lo.bounty, lo.hp, lo.maxHp))
    notify(__S("4867a14f3ce9193ce8bf7dc83038cc56e6f5"), statusText .. __S("e69f1b003fb2823f") .. lo.fruit, 3.5, CustomIcons.PvP)
end, CustomIcons.Players)

                                
TabFruits:AddSection(__S("84d694b1f546361485540e73b435138c5ff647eb7db576fc2854bec337489c14f38ff6fd7fb362ac8f"))
TabFruits:AddDropdown(__S("230e0e623756595fc960ea06e5515f3c2717234ebadb"), __S("c145881363c80d10b1eaff3df6aba174db30d7ac79c4b6c4a343aa067158c5964c4314c21290e54cae4c6fb8"), FRUITS_LIST, Config.SelectedFruit, function(val)
    Config.SelectedFruit = val
end, CustomIcons.Fruits)
TabFruits:AddToggle(__S("5f7d01c4e7249aededece103784317ccf7feb7bdaa41907e"), __S("fdb47b7551e4bef0beda99a79739e2f8c14ea4d5f9d4eab89ba38a32c381ea60970abc297f45ad1d3b8a701ae424ffc0daf0168849728040c27542"), Config.AutoSniperStock, function(v) Config.AutoSniperStock = v end, CustomIcons.Fruits)
TabFruits:AddToggle(__S("9bebf526e0fdf1935c55d4f0491a889263e0d8076010734a99c0556ca4c66b74"), __S("3a236ed71f7ef8d965dd40535d7724af6e9010b7d56a8b76d4f5dbf3e7c211813982fc423d52dba7f6aad0f2f78422f6a0abfd6e50442c"), Config.AutoGrabMapFruits, function(v)
    Config.AutoGrabMapFruits = v
    if not v then stopTween() end
end, CustomIcons.Teleport)
TabFruits:AddToggle(__S("d85ae888cc5f68aaa52c6e0acf6c6a65da68419e39c8471d7b613506b3946c0d5076"), __S("7692623972ca74a8063659bf9b71e2551cc4915e3755b4aa636f1ceb79a0ea7efb4eafd899eaf89553888ea743bf5411531963b9ec59a7"), Config.AutoStoreFruits, function(v) Config.AutoStoreFruits = v end, CustomIcons.Layers)
TabFruits:AddToggle(__S("14c9dbea715415433f9424634c54038fa2f22166bab828ab019c3731"), __S("b301559b500379bd615d09d8b93db2e220903d2da7eb235ec9842927cf5cdb5aad09377cb2895994533b0e842ceb1d684d07cb85960ccedbbe02c022490727c73c968a9f"), Config.AutoRandomFruit, function(v) Config.AutoRandomFruit = v end, CustomIcons.HubCrest)
TabFruits:AddButton(__S("5138cf4cf64f64afb5c3b213706e141d76355784f6f0263a06"), __S("ef7048fdc3828812d2e574a79b24665714fd9863757963e7a57a72e0c755f82d276bc974628e7201dd9d6721c834d453308e8bedc709598e8ce2f77bb966c6fc46e9"), __S("8da7c2aee5e9cdfb702e98dd"), function()
    invokeCommF(__S("2bdf3c5f96b6e9d561a5"), __S("ca16b610781dad"))
    task.wait(0.4)
    local backpack = LocalPlayer:FindFirstChild(__S("684e2fc11800b900a4c68df7"))
    local char = getCharacter()
    local fruitName = nil
    for _, container in ipairs({ char, backpack }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA(__S("0685a97213a25336")) and toolMatchesCategory(tool, __S("a4bd2323ed3168c8dcf4b3647468")) then
                    fruitName = tostring(tool:GetAttribute(__S("42f49cd44cc1ff57535dbb6bd98b38ca")) or tool.Name):gsub(__S("e12c16853b6aef0f5bd5"), "")
                end
            end
        end
    end
    if fruitName then
        notify(__S("7f639036468f1714a5730eca7a50bf518ebdbbbc"), fruitName .. __S("1d9b09e71409ec08bc72df737e61c8e66ce158") .. getFruitTier(fruitName).name, 4, CustomIcons.Fruits)
    else
        notify(__S("bbd283980a7fd695a15ca091f681bae952cd8618"), __S("5a09fd49eb43978f1768ddc22b8c75f06579ccd22a95dd2345197ce01c7520dc00d5dda9a0cc7d3f7283f1b23c71a2abe4b04f62ffc5df"), 3, CustomIcons.Fruits)
    end
end, CustomIcons.Fruits)
TabFruits:AddToggle(__S("f84176fa53bcbdb87d29fec2e9a38165eb6e88317b59f4c28e9f8da99583e242"), __S("9678f0ab7c6bae86d637ffeaa5365fcef4542ef92220f21968ea5f9a4c77c7453c9f7f887250bbb408e777d21a9335701a68e6a9eec3be95961f690a5d7fe8cc7d15cacfcd6f8cd7ecee2ab5ac8323dde6365b0569df0e7c5599d814fe71b87e1c4cec103bdf41fa7dd03bda6d3648219ddd23d99507ed8c1a10e44156a7dbed3792418285e38771fbeec6a2a2e913df036da2542bc459890873428eb58446c2d192680e0ff1"), Config.FruitNotify, function(v) Config.FruitNotify = v end, CustomIcons.Fruits)
TabFruits:AddToggle(__S("34b06a5cc0fea87d32fd24ed4221be03f633416bb8d1e2e4469c6ffde65de5cad9fc2fe8d0d457"), __S("d2e7e40dad73ad2289889e18dfb095a5c3f9eb35907cf6b3728051dd53e3aeb74d5425db8993d7c87ae2c56658e160ee62feb9d8ff3e8e4c13d67157865c30ecd8ef0915a3"), Config.AutoStoreRolled, function(v) Config.AutoStoreRolled = v end, CustomIcons.Layers)

TabFruits:AddSection(__S("711f5dbeecfb7b26b508d9f5c49c52a7004282bf94d38baeb78153afdee92512d0d1f249071252c2ef"))
TabFruits:AddToggle(__S("0f56d76fb4f7a60a874fd9da4174c344"), __S("ad8e512033eae4cae1126ad29dd6a6ce5de7a8e8add462fba186deaf685d3bb2c6702986a4fa7a818c01ee85d9e208629807625e269ab8b9587cbb68a95e80d837fe2aa01b"), Config.FruitMagnet, function(v)
    Config.FruitMagnet = v
    notify(__S("4bc5cad1183fdd1d24273bbfee762c26"), v and __S("e9fd4482f9fafac3423b0017250e06939d6175cfba0d62a9c3") or __S("8834be33cc64a3fe6b5f129af577cc2cff0d2594"), 2.5, CustomIcons.Magnet)
end, CustomIcons.Magnet)
TabFruits:AddSlider(__S("266c37e46129e723b9b1e8c17d2c35c47a36e45c6231c320a5"), __S("c4a3b1953ba4fd7d94b2769dbe364c9e65612b38a35cfb2e6bd9e169562c8b854e7ef380155657cb2201fc38237a013a7737"), 50, 5000, Config.FruitMagnetRadius, function(v) Config.FruitMagnetRadius = v end, CustomIcons.Magnet)
TabFruits:AddButton(__S("62db2b4632ae1497f0aa0ae43e465c0072ffcfdf7bb367da99eaa07859"), __S("0112a4f758feb5c781d65c7438fcbab18a383f7e24a25d73307f4bd84afb511d9048f0816f3e35b71f10b5082551962aa6b669173b8d3b"), __S("9f4a1ea857ea197c"), function()
    for _, entry in ipairs(findFruitHandles(Config.FruitMagnetRadius)) do magnetPart(entry.handle, false) end
    notify(__S("3d819859daa99abce6661b25b3f050a2"), __S("dbb9120a665e585b3eb4ebad0cacc000d91879536243f76b"), 2.5, CustomIcons.Magnet)
end, CustomIcons.Magnet)
TabFruits:AddButton(__S("79f08bbbbf9b920d51be4ee1a00dc3ea1db2c0b5657b08305979d70a834c"), __S("1828056cba0d6e794c768c3781a1c28da0782f4d7b122008de8750511d968b277a10bc52dec76833a47e7b978397fa7f"), __S("b65f7f1de47a7dca"), function()
    local list = findFruitHandles(9000)
    table.sort(list, function(a, b) return a.dist < b.dist end)
    if list[1] then tweenTo(list[1].handle.CFrame) end
end, CustomIcons.Teleport)

TabFruits:AddSection(__S("5496f8ce7bda43788cd5803b653d1bc8f94c0266c8"))
TabFruits:AddDropdown(__S("f2ce727f8d1b8af12c0ca31479ecf2902916"), __S("9105ec30024fb7a9b14b7ab1178f988cd4727311973c81b2f6e02d0b9e236c761928d70684cb29"), RAID_CHIPS, Config.SelectedRaidChip, function(val)
    Config.SelectedRaidChip = val
end, CustomIcons.Lightning)
TabFruits:AddToggle(__S("2f3d65e14084b6db9bb06ce37b9499b99d90881b6fab83ce883600"), __S("cd74df92b0837e7f83c02fd64abb604b5a59e8516248cc5684b3234c3bcba2f5b3890d8427a17c413bbf82050b"), Config.AutoBuyRaidChip, function(v) Config.AutoBuyRaidChip = v end, CustomIcons.Layers)
TabFruits:AddToggle(__S("6bac59437374af8c4835443e45578d1f65ca"), __S("09e3d2f42f68579e4c24379ea3823b8084838874f48d9646d0f197a7217951e174c717044d0d7ec1dfb49264dcc3ea6aec"), Config.AutoRaidAura, function(v) Config.AutoRaidAura = v end, CustomIcons.Boss)
TabFruits:AddToggle(__S("a81b4ca5638aacf6fd709836353500115460581a7b190daab912cc"), __S("4652c6561b262ad4778efbeaec1df30a1f13bc1baa67656281692fd9b29df8e138fb37c0c07e570913d7d723a3c9f75f9dbd398e337c9014a2ee"), Config.AutoAwaken, function(v) Config.AutoAwaken = v end, CustomIcons.Wand)

                                 
TabTeleport:AddSection(__S("e48a4007516d01fdefc3bf7e710a"))
TabTeleport:AddButton(__S("82c1b9b877f6a6005db7053493acc96ea3048f63a3b2ec"), __S("20f9336917e9206b9cf394967d9007e9ae70e545757a612a5b93d88c08ed958c556a865a5e5d3af08baaf0405da8"), __S("bf30ad1a67504ee56bdf"), function() invokeCommF(__S("5d6826cb2708369412dc7c10d393")) end, CustomIcons.Teleport)
TabTeleport:AddButton(__S("fb9fa07c603fe788767cc0eddefdffe19fec9bf5c6f12cb1"), __S("99d71a2db03e60e412c43520c973ba543fe1b2b0aa98a3f0b79dc6e462924e3d5fa1cca1116b47e646f19d"), __S("380e93de309898efad0b"), function() invokeCommF(__S("d6460d8fa04c38b2c6df51e6d4ad5dcfad57f2")) end, CustomIcons.Teleport)
TabTeleport:AddButton(__S("747d87401e286ddf6959ee11ca8b366a9a3a501d08def5"), __S("12b500f170f10e661391494472bf3bb160911364694c84427a5516b1ed1da7e39197027f297115560ae95ff0ac1228211adeee7d"), __S("b0ec7aa2ea59bbb867e4"), function() invokeCommF(__S("4f23f453333f4de750b286dc81")) end, CustomIcons.Teleport)

TabTeleport:AddSection(__S("ed5b6e04209b4d8f3d435e923e09250d64a529e860357402c3af696361faf29fa470082a851fc464e9f701e4121ddaecb9f7b0779cd08a3abf44578157c8f54b"))
TabTeleport:AddSlider(__S("8b92e7b5b38ef9c63519c54aaa16288b2b96d8edb53d"), __S("29ca61666648a52d876bd1e61420b897174e9c734cfa5e8b02d2f99388523094411c7aabd9b484faf40f"), 120, 360, Config.TweenSpeed, function(v) Config.TweenSpeed = v end, CustomIcons.Lightning)
TabTeleport:AddDropdown(__S("c801db1722408dff865f2e90058db0b46d8e36006e8a"), __S("663954c8cb2794cbcc2a4b676313f24e78f3704e1de1d6cf2f265f936e70d47d5694c66492867b7242954d221723203bea2b080496e991dc9f716e49084969bcd7b9b1f07ee6077e39948490"), ISLAND_LIST_ALL, Config.SelectedIsland, function(val)
    Config.SelectedIsland = val
end, CustomIcons.Teleport)
TabTeleport:AddButton(__S("0470ce79325614be7ddd2ec0f60dcaa05dd1159643fcaca3091ff508"), __S("a2a8482a2f35e0d837c8bd63d0f6e3eb31fd5fefbb8fca42dc3601af03fa00b10af3f6b42bb7dd7aa1c5467a26e1c3bd20343473160eb49d"), __S("40dfc1dbddcb178a2dfd88ca"), function()
    local islandName = tostring(Config.SelectedIsland or ""):gsub(__S("df173b8c01305435aabd81d318c580a8dd"), "")
    local targetCF = resolveIslandCFrame(islandName) or ISLAND_TELEPORTS_ALL[Config.SelectedIsland]
    if targetCF then
        tweenTo(targetCF, Config.TweenSpeed)
        notify(__S("7d4eb53dbd923a71bf74f6b2"), __S("1b862eeef75b8a23090f87c9bf9fc806") .. tostring(Config.SelectedIsland), 2.5, CustomIcons.Teleport)
    else
        notify(__S("b9bda89f9c8200d6f863a7aa"), __S("57f522503aedf01a829fc4812c8416a202793d93") .. tostring(Config.SelectedIsland), 3, CustomIcons.Stop)
    end
end, CustomIcons.Play)
TabTeleport:AddButton(__S("f62c9c01645e423589e82d56eda81cac50ca57717a"), __S("946415b2f2415d8ac1bf67adc278fa302148918fedf63e8bfb62f81dba301def011e2e173cd061e4ff68"), __S("329b8f638b76c1df"), stopTween, CustomIcons.Stop)

TabTeleport:AddSection(__S("d0d309143fcaa6779ccf69d6295c36080ffd5f4ebd5114d709c418e55b852937cb"))
TabTeleport:AddSegmented(__S("6f0a82c5bf0de954902855ab5b1a08ee"), __S("0d41fc7670427ceaaad5bc0e985aa3326583d3f891b49fa82948231c1561d4967b70f1b1d5a964bcda08233098e4f88097a9fea4e463b8085fb5debb9f"), { __S("ab79762798f2050c"), __S("49b0efd80e2440b8de"), __S("e7e86989161bf06b43"), __S("861fe33a951a1bcf9c") }, CONFIG_SEA_OVERRIDE == __S("24575ceb8f17f34d") and __S("c28ed69cb373147a") or (__S("60c6504d39b4d6eb") .. CONFIG_SEA_OVERRIDE), function(val)
    CONFIG_SEA_OVERRIDE = (val == __S("fefdc9febeb60d02")) and __S("9d3543afaeff77ec") or string.gsub(val, __S("3b6cbd60537bfcf1"), "")
    CURRENT_SEA = refreshSea()
    notify(__S("d9a43711a118e607a107f84343eab32004"), string.format(__S("77dbb0c2109cb0f003ea806aa4b9e39df6"), CURRENT_SEA, tostring(SEA_DETECT_SOURCE)), 3, CustomIcons.Teleport)
end, CustomIcons.Server)
TabTeleport:AddButton(__S("16132a732f86f7284685b0a283a2dacacf48ea73a0"), __S("b44aa4247166169756fdac80ebf912750452daa9eee4c2caf61937b6ab6ac75d59257679434656d46faf673d9b46f28b52c75a93c9f84bc1ce903c885f6b3924"), __S("52821dd53bddabcb6d5618"), function()
    CONFIG_SEA_OVERRIDE = __S("f0b99786a36eee84")
    CURRENT_SEA = refreshSea()
    notify(__S("8ef111378f65437b46548b7c304a1e36e4"), string.format(__S("2d288ae8c17d4432e90b9c6b7f19bf"), CURRENT_SEA, tostring(SEA_DETECT_SOURCE)), 3, CustomIcons.Teleport)
end, CustomIcons.Search)
TabTeleport:AddLivePanel(__S("cb600499337ed0e5db3811057dbe"), __S("69977e4aa958c48989eadbadab3efcd8a04db8cfbb7a6550a8db8372"), 2, function()
    local scores = computeSeaScores()
    return string.format(
        "PlaceId: %d\nDetected: Sea %d (%s)\nScores  S1=%d  S2=%d  S3=%d\nOverride: %s",
        game.PlaceId, CURRENT_SEA, tostring(SEA_DETECT_SOURCE),
        scores[1] or 0, scores[2] or 0, scores[3] or 0, tostring(CONFIG_SEA_OVERRIDE)
    )
end, 110, CustomIcons.Server)

                               
TabESP:AddSection(__S("07cef7fb541ba846d82c3ec66bfed305e5d39f56b7ac"))
TabESP:AddToggle(__S("a60671ac454dbb3f829cc4d1498f"), __S("443deb5d78ac01cda1beeddf83d909eda3ced1f0efee73656fd1ac56a9e4a1a749946636797f7afd34b633864371bfa8d386ecdbc16484e3b98be2be599ad3b6ae07c0ba06e0fbcd35ef1af6ced937a636de796eeb1e676b25af15ba16f652"), Config.ESPPlayers, function(v) Config.ESPPlayers = v; if not v then clearESP() end end, CustomIcons.ESP)
TabESP:AddToggle(__S("e275650ea04d84aecc453e6d19105d154e60c8"), __S("80acdebf0a11056b0c8df0fe45bd09ea27acc43250a752776b1a928bbd8fbc37e48cf4ed1a6e0af5de1c86d756ed056b2dc713e10ad9fcc1417a56"), Config.ESPFruits, function(v) Config.ESPFruits = v; if not v then clearESP() end end, CustomIcons.Fruits)
TabESP:AddToggle(__S("1ee45870665b4c0ceccfe9a446"), __S("bd1bd22106f5b26e823c858f758191a823bc7079d58832af4efbfb688166531cc138180893fbc4d9a93be2"), Config.ESPChests, function(v) Config.ESPChests = v; if not v then clearESP() end end, CustomIcons.HubCrest)
TabESP:AddToggle(__S("5b534bd24b2af80bb965711c809d1d795ab943dbbd34003351949f0ece3ea401bc"), __S("f98ac5838ad3ccb355a769e332f837edeeb03c1aff8db62cac5cbcca58abb7c1fc844ba399618d41ecdb431e4794159dc3c3b46b8a70e2a678a399bb5190d6f0cc56"), Config.ESPIslands, function(v) Config.ESPIslands = v; if not v then clearESP() end end, CustomIcons.Teleport)
TabESP:AddToggle(__S("97c23f34a4081ce1073e99a0"), __S("35f9b8e533eaa4bacff1f0c7077c27f4696185b7abf8329a5afba7fbe7ee8eda94c65c4a3edf4d4fb2ef0ebdb782f53bfb80ae505b887d"), Config.ESPBosses, function(v) Config.ESPBosses = v; if not v then clearESP() end end, CustomIcons.Boss)
TabESP:AddToggle(__S("d431329617968f71c21559890015b0627180d2b57c40"), __S("7268ac4704fd04d4e8fa91737f410aa8297068ea8670b9cd98f0fb42b863af7fd87badf8434e7a1c2bd43d5d816826399bdd992dd0f68c474a83c9bc4af6ee2078c454571e69325f6d34"), Config.ESPPlayerLoadout, function(v) Config.ESPPlayerLoadout = v end, CustomIcons.Players)
TabESP:AddToggle(__S("10a025f851e96e0ed0052d6042784dadcdc201540f55371e"), __S("aed79fa97bec10c56bc8bdcae49a57524d82846213414ff0be7ea3c38c87085b25daa88f91b7cb000e6dd4fbf111e00089401d3f5cc6a04d5c"), Config.ESPFruitRarity, function(v) Config.ESPFruitRarity = v end, CustomIcons.Fruits)
TabESP:AddToggle(__S("4d0f195a1cdc19b5ceaa1c54af912f54"), __S("eb46930bdc4ea908e42d596e101877a0975fdc7d5f63bfe25e9ea5abdec5ad126d4b1dd4cd7b3b2d2d3746f9d24a06a80e0f12d9a35d3356fec7f11f93c89b5fb2c88c1e"), Config.ESPTracers, function(v)
    Config.ESPTracers = v
    if not v then Hooks.clearESP() end
end, CustomIcons.Aim)

                                 
TabMisc:AddSection(__S("897e0cbc8a168db73bd0cfb1490f9f7739cc76a7d3a6720fdaabaf59ec9199bfeaa167"))
TabMisc:AddToggle(
    __S("27b5866db55dd8669f025d53d8edf398dd61baf6a7e45d251c9df256c9cd1db9a0f6"),
    __S("c5ed001e8be1b0a287779551f2870293c4b49f7997df33f14943f082156916a559875f2a3d187525e5970562ae5f48eedc7ec47a2b28bf2ebf9ebb7e3f0a4e10bab4a4ed0e1b91cc03b4a6eafc484a196ca180c61b83f97b6e36262f"),
    Config.BypassAntiCheat,
    function(v)
        Config.BypassAntiCheat = v
        if v then initBloxFruitsAntiCheatBypass() end
    end,
    CustomIcons.Shield
)
TabMisc:AddToggle(
    __S("642479cf20f9bc64dc9e6d9271caff5494abec756f1b6911682e7c87"),
    __S("025bf38076e0cb18cb62e99515685e19c0196d817e85e4ec1c0f040f198403ec0555df03efc5bcb24008ae9882543c256d233772e4cac2a6ed0242d2610acbac99f333241303c9ca8e5cb09f9e00b5a861151b194f8c27"),
    Config.AntiStun,
    function(v)
        Config.AntiStun = v
    end,
    CustomIcons.Lightning
)

TabMisc:AddSection(__S("a0936d319e618f04da93f3272c9ae45675882fdb74e83573c9645e4148552b5037c41e4a74ae"))
TabMisc:AddToggle(__S("3ecae6e28c89978bef07b270080b"), __S("dd0260932d25b55c4af6efbca12a6fed2ada14e35960013a0dc3cf456ac9aefc31d9d1629c13c40c148261c91faa4c2f4b149d13d73b5e4e3ebb041bf326554f6ae8bbe01dd2fac423c612330627f7ad80616fb7d5326a8e407d52fcb67c01c42470d64b0dc8da9250abcae6d24500"), Config.FlyEnabled, function(v)
    setFlyState(v)
end, CustomIcons.Fly)
TabMisc:AddSlider(__S("7b39da44ba607a6b6e62158433"), __S("197153f5617ce983586e11c92cc6b3066e7ba6b87c8a15340aab60e4f41be51f006ee1bfb85f585e5d02f82a7e35009392ae06fa3b4eb5f82af803f3"), 20, 320, Config.FlySpeed, function(v) Config.FlySpeed = v end, CustomIcons.Fly)
TabMisc:AddToggle(__S("b7a8cda6eacb860a23956f8ed46e16ae1cf660eac9a21868e74cc09586fa281e61684fce574727"), __S("55e04757c023617830f8e5985159d7fb31d9519b6d7217adc55f896289212bc6fbb3a23ddf0c0cc0e4469554252bb05a37d1e1a549124f1969126e2be3fce339f8e17f696c35317be45df3b38686a07b2e70a7507eb27f175a1f1d8e85d60239"), Config.FlyHoverIdle, function(v) Config.FlyHoverIdle = v end, CustomIcons.Stop)
TabMisc:AddSlider(__S("f417c108324622cd47778e0dd71cf7e634ff85660fcecb9b10567d7cd63856560294c153"), __S("924f3ab9c6d7c7955e49ac32609380557268b58fb9fb95662c4a2c01902abe4db2f702b6969d90dd88bc6a47a5d314037e93133ed21cc778c93c0994172958f8c17950fd26119aae1ed4fa1f2edcd55f0caf6415d920ac37395dc03da49dc4e866341ebec18c331a8f2362f646fdbeb88b73830a0c3deb3598988799"), 0, 500, math.floor((Config.FlyHoldSeconds or 1.2) * 100), function(v) Config.FlyHoldSeconds = v / 100 end, CustomIcons.Loop)
TabMisc:AddButton(__S("3086b46adfbbda8def736e956cb0c5b28395678d60bec09a84638da1f980"), __S("cebe2e1b4d1090ccbdfb3fef2e024bce9133f2e837a0d6462043400938890c7db88c8a7a65abba1f8c26dbf1cce0514be155934fda0ae1041219d4a44568507448750399fd71bf961ec9bfe03c948037ecfff3d003ad69b312bca86fab"), __S("6cf5a7ccda01aa39"), function()
    if Config.FlyEnabled then flyPark(not Fly.parked) else notify(__S("0b2d217d3acb75"), __S("a9649b2ea8283543320f602292f12d3cf653d6e6e2606122835571d60216c4314589"), 2.5, CustomIcons.Stop) end
end, CustomIcons.Stop)
TabMisc:AddToggle(__S("479c14df9ee2becf113cc476fd87212b75c8b520307ce0c7b70724"), __S("e5d38e90c328bf1f2ee3aeabecb9188c1de0298b39590dd5023841b02e23ba347b9a72e0dae4d172fbbe4a9f12dd9cb5a4792567e9f4fb514647bd561014b36608533cd4341e9489277f391798d8db26369bf673ddae51599c32ed9efa005c9c4100f0"), Config.FlyBypassMode, function(v) Config.FlyBypassMode = v end, CustomIcons.Shield)
TabMisc:AddToggle(__S("840b0841862af245311903cc283824651fd79a6ec75af49eb2f99ba87242d70b39"), __S("224281f21ffdef95932231fc30e0a4446a0bdb22b4796f74fbadb8efce707b9680b4a60d4ff10ba45ac5e4fb0194e43ac5bf906a7550d4c6e5273092c1d289d495314147266ac1ecaf1674ce3db305786df3065446"), Config.FlyZeroWalkSpeed, function(v) Config.FlyZeroWalkSpeed = v end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("c079fba3c4009b8172ad0de241a63770be4f046a4a338a134263407237"), __S("5eb17554352afccc858b2221ccd21d456627cf917ee0fac8c67b10c9dae01b66eb9a1cc5801048dd28ec89e9ef8258c47a1b78a858cfd2a942cc8f00c4e44b299080925d4d3e07922a71be145ff331400106e7076f93182756d1a9b0654ce04eb1cf"), true, function(v)
    Config.FlyJoinAutopilot = v
    if not v then MovementLink.clearFlyTarget() end
end, CustomIcons.Play)
TabMisc:AddToggle(__S("fce8ef05e0b207d6b568fbd728"), __S("9b2068b6597d73462ded566ca76f5a63f440156ab49439a43dfe7a87d4dfe8b54667953fcc9739ffc42ee96445ec0f8e939f45c567f2e990"), Config.FlyAntiVoid, function(v) Config.FlyAntiVoid = v end, CustomIcons.Lightning)
TabMisc:AddLivePanel(__S("3957e267ec477668da59e170d6fb"), __S("d78f5c18b248a7b8ea8eb398105c25af93b12c60391116320e38db040e"), 1, function()
    local root = getRoot()
    local vel = Fly.bodyVel and Fly.bodyVel.Velocity or Vector3.zero
    return string.format(
        "Fly: %s   Bypass: %s   Speed: %d\nVelocity: %.1f, %.1f, %.1f  (%.0f studs/s)\nAltitude: %.0f   Autopilot: %s   Unlocked by: %s",
        Config.FlyEnabled and __S("75c6d5c9f976") or __S("13fe4f7a5d6953"), Config.FlyBypassMode and __S("b235c92b8c23") or __S("506d42dc55f437"),
        Config.FlySpeed, vel.X, vel.Y, vel.Z, vel.Magnitude,
        root and root.Position.Y or 0,
        (Fly.autopilot and (os.clock() - Fly.autopilotAt) < 1.5) and __S("eea4bc8db6658dd17c03b731c39113fc35aecfec654593") or __S("8cdc363e3e55a65e60d13f262e394f796267"),
        MovementLink.isFlyActive() and __S("2b13afeffe5c83") or __S("c94b29a00b07bad7e7")
    )
end, 100, CustomIcons.Fly)

TabMisc:AddSection(__S("6782a35150f6d2fdd9fc6f884ab4aac72ced65a6"))
TabMisc:AddToggle(__S("05ba1d02b8baba112370bb51927c2beb0c"), __S("a3f196b3735ae18a1ef1a8f76672389e4f7f1a98f3696d5f61d9efede99b84f9ee0884c1c8b94785e0cb1a9c2ce7c2d09a99270ab5c5542c8f778197d5a59866daf5c776283228"), Config.WalkOnWater, function(v)
    Config.WalkOnWater = v
    if not v then removeFloorPad() end
end, CustomIcons.Water)
TabMisc:AddToggle(__S("42291064ffdb6f5a60c6d18523fa767ec3f4e54cbba41c7c00fcefe1"), __S("e0608a1554e226cedbff51b316a99b95eaa1d061cc80f4c78ea35c35bf1c33bd717dcd3eee425f73cd20bd049a9d17d9"), Config.InfiniteGeppo, function(v) Config.InfiniteGeppo = v end, CustomIcons.Fly)
TabMisc:AddToggle(__S("7e9803c63f004e3f15443609fe6c0a9c779caf"), __S("1ccf7d776c4ec84712eb7ef8365235d4a282f1333da7184b29d353989679c3436c2b4e2e9947fa937a67dfeb08aaac2937e597a840c2e4b14c4e"), Config.InfiniteEnergy, function(v) Config.InfiniteEnergy = v end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("bb06f728b7d45282a593ddb7c87f185ccf596c88"), __S("593e70d978fa86f2fd4c1d001d40a8b181ae72012ab28cfd9e374acc49ee87527b38e92771dd010aa77fb9d554432e3b8f2884c56caea6234818"), Config.NoDashCooldown, function(v) Config.NoDashCooldown = v end, CustomIcons.Lightning)
TabMisc:AddSlider(__S("f775ea8adc0abf2436a1e8e1cc74eee7f7"), __S("95ad643b2a698f13bb92e80d9b961afbefeec174cfbffea11728d206b174caa1026fac772345f1f1e6afc310712b"), 5, 120, math.floor((Config.DashInterval or 0.32) * 100), function(v) Config.DashInterval = v / 100 end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("33e4ddec8115441870968fafe9048478e441dd6bab5a"), __S("d21c579de76ba56fbaed190bc728bfb765e04db0d52ea6ec6115103595130742f56221982fb0f75e271a34323e04528ca64848"), Config.AutoCollectDrops, function(v) Config.AutoCollectDrops = v end, CustomIcons.Magnet)
TabMisc:AddToggle(__S("7053d14e408b514ada2da57bc544e2611efe33afd2"), __S("0e8b4afff461328ad4a459c7064a55cec6ac27835123da486fc79c10599a1253f98a0e5e58cfd1d9131b20477f13d732dcc6a256d06e8711d2ccadfd6b5a4d63431b198c73ab20ea6e0d322ed013fb30d74b2a"), Config.SeaEventTracker, function(v)
    Config.SeaEventTracker = v
    if not v then SeaEventState.events = {} end
end, CustomIcons.Server)
TabMisc:AddToggle(__S("acc2c4b097cf20a3f1ca2d9228f5c9d99035dfcc995893c5bb6c4f124176d7"), __S("4afa3e61ee29aa13821bba420937a4c99d700b1618d30036fe91eb4a6a51544340a6f13bdd161f8a62ba275dfb16c943f8957f875151a73aa5e6337f237c04287d9fcbe4beb8f5eb47693d08771758904d"), Config.MirageFinder, function(v) Config.MirageFinder = v end, CustomIcons.Magnet)
TabMisc:AddButton(__S("e931b81238ee827fe51b4d0cd212d53059613793533267"), __S("876931c34d7c29342c7b7eb93cb9aa5488b4688fa379fa60b7d4bc655b0469bc43a6e0f4f72f3c0bc3418e3b"), __S("25a0ab7420835efe"), function()
    SeaEventState.events = scanSeaEvents()
    notify(__S("c3d82525a8312b69f0e1c337d1229dc37bd6"), string.format(__S("620f9ed699f8f26d8eb3d16aff48d7e379741337346d6dcd21d81de1"), #SeaEventState.events), 3, CustomIcons.Server)
end, CustomIcons.Search)
TabMisc:AddToggle(__S("00471887ff70afa44ca415985cb1998908f9ed3d95"), __S("9e7e9238f76cad3deb27985ea0a91a47a56ff130dd31fa57784edc02dc8a404e0a93bb11b2d629ad8e277448f7fb917f667be3d0ad9948657314b081e5742285e03f8616f2e8cc3d9e5d6c"), Config.ServerStatusHUD, function(v)
    Config.ServerStatusHUD = v
    StatusBar.Visible = v
end, CustomIcons.Server)
TabMisc:AddToggle(__S("3cb60be9c27bb9d48f3d6eac694dfbf6bedc97bad229af15726cbccd768ab50854208ed2"), __S("daed859a454656b8a1be29b55f2e360eed20c17832498ed0f27969415de4446276f5140522056c3a72f9c1398249a3decce0fbd55811efe7abeb6ba8"), Config.NoFallDamage, function(v) Config.NoFallDamage = v end, CustomIcons.Shield)
TabMisc:AddLivePanel(__S("7924ff4bde6812fbb7b168b6eb557802be"), __S("175c78fc11f97b43f62603d13bb9ed52e47300de23a80c23"), 1.5, function()
    local st = getServerStatus()
    return string.format(
        "Job: %s   Players: %d/%d   Ping: %dms\nSea: %d (%s)   Locale: %s\nSea events tracked: %d   Fly: %s   AimLock: %s",
        st.jobId, st.players, st.maxPlayers, st.ping, st.sea, tostring(st.source), tostring(st.region), st.events,
        Config.FlyEnabled and __S("b593f2adc168") or __S("53cb6c5ed1f8f1"), Config.AimLock and __S("f202e60fe17e") or __S("903a5fc06ea52f")
    )
end, 104, CustomIcons.Server)

TabMisc:AddSection(__S("2e71d9715f414834c5bcd089fe75b533c254e2392344e0ba5f22bb2886b6f6aa458ba7b3"))
TabMisc:AddToggle(__S("cca95322899d6142070c4c7597cc21035439ddbc5cd2ceb6a5cb6aabd74e803ae89aa1"), __S("6ae0ccd3e75e71f10ac0532df43ffa3feb0c47cede99acea98a29ffd4e728beedb88bc6f9c294648491be4357836dfba071de2c2eec432c470bd287000d9dbc1b1e0d522e399901c21870b06a65c6c6ef6ff40a120ab4ec3d924859164fa7cf65b753e12b4e0c7f8e368180f0590a70a6e9e2d024a39d88e60937d3e49681074dc0e3fc8ce9594406bf38a8ed5ee15bac4dbc72d01a3070602eecdb2987ec2efab997427377cf7f9e1acca39debd568fbb8b4569fa3b1f5914c3ec4409dac71167471167b38267c3b0f4ab305e51116e801ea4a0e31d10f37d"), Config.HookEngine, function(v)
    Config.HookEngine = v
    if v then
        HookRegistry.installNamecall()
        notify(__S("091846842801d8b854573434acff13"), HookRegistry.namecallActive and __S("a74fc035f9751397929b27dd5e1411e42926dff4c6523e21b33d8e287ceed8dc09ce572702cd0c5c8ebd7f8086b28608") or __S("458739e69e998c08864747288740a661ffb8d7e379ac11a2b8609b77ec2b1ae68778c4ca770b58f911e9f2cf"), 4, CustomIcons.Shield)
    else
        Config.SafeHookMode = false
        notify(__S("e3beb39719a977af5fe53e65b37701"), __S("81f62d48cf0f4e29fc65c1365bfbcba3c1b2cb163df51e040a10288918e74f00ecbbbdc3cd9dfb6ef6229091d263932541be3be520c115ed36e5df95288b6524"), 4, CustomIcons.Stop)
    end
end, CustomIcons.Shield)
TabMisc:AddToggle(__S("202da6f9d3dcabb468af807c3937ddc3e45b"), __S("be6520aa8559aafd8156d7d675a9242d40ec769df19c4e7aa40c2e8c3f93981465ef98a94a5bdc9e4f63769792679f816e0c13b32f574c63c0bdd0cb6fecd4626c11a7a58874daa2eb7c4fa3c67129e5aaf663c9cbe44d9c7c7d71be8d7269e53766da5f1716f9c0920bc8b001f8af87a1bdc22bd93f3082e060d209f78c5a4642108ca2fe"), Config.SafeHookMode, function(v)
    Config.SafeHookMode = v
    notify(__S("5c9c9a5bf8d653624b80d9f074b2ef"), v and __S("fad4140cb539c00f5231f80e4f7c5718a52851e28c") or __S("990b8dbdcb2f3893b376a08bb3445550e0585f11181372d9ff15b8cc9b51a7608873d42f2873a77d9433119099ef4f1e"), 3, CustomIcons.Shield)
end, CustomIcons.Shield)
TabMisc:AddButton(__S("3743076ecc5715fe6a832f458d3b5f27af0d91d3"), __S("d57a811f81d5324323da4332e0724ab9e5dcd66cab68b7c0b0c05f84de9619138eafc56b1445a8319f4d65447057fb36f0f64d7eeaa5f5eae523ed62d49b70c54ec2503058326c690ea98c468f2bf25d3f2e28061b90e9fae33f4e98dbb6a0689c2dbf59a139e3a338fa3058"), __S("73b1fad050837f5fda08"), function()
    UnloadSkillHub()
end, CustomIcons.Stop)
TabMisc:AddLivePanel(__S("11e97481d8845992ba10dc7aff1094d9c73e3b5f45941bb77edcbf42f7ac05"), __S("b020ee32967b9c7cbc6011725bd447d583dea1b93b02540e5824ae7ac626fcdfb393ac1c1a60e63807fac6f0112dd58f26e2447a365ffc42"), 2, diagnosticsText, 132, CustomIcons.Server)
TabMisc:AddButton(__S("4e5867e3d2e71403d5e84476413c94b98191d30c1ad2900a5741c81a7b84cb76a2"), __S("ec8fe194c9253fd86dbfd6dc433f5ad53a0015cd425c71018a86074a119b2fddaf16d6ca8b39d78c226e22fdb76490a9b772386d86776dd5ff8650e69c29ee039d5292c755051662c341172c2a97d616d55e33723524139cd282f7259ab3c00e299f6aec"), __S("8ac75b45918b4729"), function()
    local ok = pcall(function() setclipboard(diagnosticsText()) end)
    notify(__S("28fed4f64209207fe75889e0c7554e"), ok and __S("c7364ea75593dd319af050a77961c14915d4a52c1c9976") or __S("656dc85878c7b5a46af0988d38baf9f0eb3f2d4e006152b0bcfa40c00708300b139bd1fbc174432418e6e7437b7285094c63"), 3, ok and CustomIcons.HubCrest or CustomIcons.Stop)
end, CustomIcons.HubCrest)
TabMisc:AddToggle(__S("03a54209dfa61b609aaf869e209f0ae0e2aeba94393f"), __S("a1dcbbba58dc70c46cee845d084fc5e6b37a46e9ae39b90094bad58a5f730cdc1e37848a98353bba99fe8000b99fa1a6d6cd9537e8ece47254dd70cfafe01076ff56ec2cbd452a127e7a60203a2f0947da357b64af84b9526254e88fbb002540db5fdba6d5f35e185ba88721718316398273f1484559106a853c9bced3745467dfa0bd2dc86b4cfd2ea0729ed402f53f8f3987"), Config.DebugTrace, function(v) Config.DebugTrace = v end, CustomIcons.Search)
TabMisc:AddToggle(__S("4014356b9edb5907dc96d8a37ad93f9fc9309e1ac11979fe"), __S("de4baf1c8a32e6e1d4983e0c1f641fdc4a879b5df570db62e9e140a110f3c45f550c5f43821e1da136a6d0da0fe94b84494cd9d10015143ae4cc2e71095aa1a351c12cd7f801883ddef8725069bb9f361a2f1a38425343e841"), Config.IncrementalUIBuild, function(v) Config.IncrementalUIBuild = v end, CustomIcons.Layers)
TabMisc:AddToggle(__S("7c8328cd43ea49ada6966960eb510d7539233e75"), __S("1abaa27ed6d7a9c811b4aa1a7346fce1e2ec3768d3a62ba124b51ea35775de617435a5fbf6dbcdc7d3bda710d4c89e769c9613ad033148f4a244637ede314aa4cd1d381337fb3fedf6577a5c94eee166f6d469cfca1badfc080c8556136931dce6e1988034b300ac5608aa8ed39e143bf67dfbf15daf5e1f74e8319d4c81664b3fbdb82e0c510b228d8e6cc76688a33626d3e1"), Config.CoreGuiWatch, function(v) Config.CoreGuiWatch = v end, CustomIcons.Server)
TabMisc:AddButton(__S("b8f21c2f4047c4500a6562b2993b4d2ffb"), __S("572995e0393924fae4c2acf4dea36ae834e55ef97c97d385a08fe4bcb3924efbc415750826d47b80f71a0567c4a38bfb702ff539c5374e0337d5ce91cca0d8d9ef5f5ca8ec987e6ed4b2a6d8d6149c545c4543b3c85f5dd30b381a24f6d1a31da90c230de8dc35b287fc3b82e078466efe"), __S("f5610f918a3d4cc4586fead0"), function()
    if tabSelfTest then
        tabSelfTest(__S("939889422e3e16d9f7371bd5f6df8d77bdc06de613c7e710757c64f22245cec470b2d17732"))
        notify(__S("31d002f3e0dea7edf3074b701fefa9c53a"), __S("d0077ca488604a8d11c9e4fff394fc90f902d7554eb5a803568eb3fd0e343fce2a10a0c5487334108ca5c3584583e371de99348c913ec934d7bccfd5d18ef6b18adf84"), 4, CustomIcons.Search)
    else
        notify(__S("6e3ef6559b08b9638b2c88a01d096833c1"), __S("0c767006c98a33bf7a0443c09ff5fd73b009badfafcebec77b88037e90178ed806859c1a8ecc6fa7f6241d4e794abe66c14d530dd7b8cabd6e25468d03"), 3, CustomIcons.Stop)
    end
end, CustomIcons.Search)
TabMisc:AddButton(__S("aaade9b7797b61d83df98cb0b8501695d4dfef834f2fbeb0ff3e435ec1ed01"), __S("48e56368fc318b75c1097f0e6044c2318d00e2372759ce897605cc8035cec1f646c20faa7768645c9a719f10c09767183a587a7d49e617d197f6f98b14e9ffc3f1adf0bd683295587471fc7ecbb6ab1c32e1490ff97e3821f6c05e14cb016b91ee8cb5b84672b13b4b2ca96c0a5c7ebaf210bebe0287e1d50f5ab303898a3c5b1b1902fe3b6c97e59606e8931e936e7eae6e47b23d4e567acb83a4d4"), __S("e71cdd19c74827d0c5"), function()
    pcall(function() SkillHubEvidence.report(__S("855456cae192861d3b56f8f79743701155981d9f9240f76b7989800413f62c3bd872bcb5cfd4edb2f66c5eab")) end)
    notify(__S("238bd07bdaa41d2521793040dda76d17ce"), __S("c1c34a2cdd5867f6eb73cebffae75c0eb747f9e418d0ac30afd9bdc356531512fb9ec8156c7619fbeb5f124bbf24c5260b45236f5e0a5cd83f8179ca8aeca171"), 4, CustomIcons.Search)
end, CustomIcons.Search)
TabMisc:AddToggle(__S("5ffac3ddee29f859bf43ededf8a4fabe09c7d613bbe7ecbb7b1c99c12812c7ac970e270ca1660e8fbc2e67"), __S("fe323d8ef977a9d4c1048ef8ab7f2d874e040fedfc1b0841ef1374ed41ebd31dc37f2d7b185232cce9a84f93ac10eb8e879a75ee84831e1f2187de2ece88e14e564984ec9a290437854f67768f026ad712f120085d95c7fa4e40b2cf25bdbb6a81c27c1f39ca4735e104a0e35fff7e5f23f52ad212c48a9aa72e845ab3ed01d40bf98086b8fe617ba6ab220cc78fb9a9803685a9a6a29977ef056831b0d7dbb7e744aa6bb342e26e9a"), Config.UseVirtualInput, function(v)
    Config.UseVirtualInput = v
    notify(__S("9c69b73f2b71f37819f4f7c14711775c413bf6"), v and __S("3aa130f00ad9718d60c3b8") or __S("d8d8aaa1c30ee80c2bc87acfc56c4aa53f8e5653c119a2a9d28d499fd2cf409dc4890b7490735c9787f5342e3621fd31ac926511cb99c8f94f9f070e044d1b1c332a"), 3, CustomIcons.Lightning)
end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("77102452339f3685d1c56387c9e57859dd8ad7bc56d4f5a1dc2b47aac376a17d99452402ef5dc36469ed45"), __S("15479e0310bd909d7284c42506e312497ca2bcfbcd314809295476895c93e52b6905e87b29f29afb858dc11554d79685fe56a37961bbb872187b9993c83703340cdef16a866d895f1b034453885b77bcab14b1d7e1f95089c1678e6739ce3e6b87a0eaf3ceec6c74a2a1230967d075708c6597366209b88f54eb7c99"), Config.LogStepErrors, function(v) Config.LogStepErrors = v end, CustomIcons.Search)
TabMisc:AddToggle(__S("b37f17b4364a46107fd4b3b30f709e5571277d24f501f6af3b"), __S("51b69165fbecdb34dfcc9f4daa83b93bb96bedd0771a176d832402684b07147d03cff306504ae6bd4aa73c73af578cfce105a7a95c8b0de03406621213222525ddb39683539ec1d9640e3d83a8552e16fb46fd18c5348803dc5362f754542a03"), Config.FreezeMobAnimations, function(v) Config.FreezeMobAnimations = v end, CustomIcons.Layers)
TabMisc:AddLivePanel(__S("efee0b161811ddedcffaffc463aed5716a3c33a4f0016b8e5086351e"), __S("8e2584c7d5b225943273ef5f39e21abe596c94a569d344f261307fac71673df02d408d09e8da0b6452564b93"), 1.5, function()
    return string.format(
        "Hook engine    : %s\nNamecall hook  : %s\nIntercepted    : %d calls\nKick guard     : %s\nSecurity block : %s\nSimRadius      : %s\nCoreGui touched: never",
        Config.HookEngine and __S("2c5cfe78f475b74f87163cdca017e25552beb5") or __S("ca9478298e74d55760119a76920e33aedb98625b81d7dc5dbd77ac8a03bd8e7a77964a44d294fd67"),
        HookRegistry.namecallActive and __S("68cbf1daa3dc544a7ac0") or __S("07036b8b9ce8d0f772d6f1f955e35e98a7"),
        HookRegistry.hits or 0,
        HookRegistry.namecallActive and __S("a53ae53cd778947261c279") or __S("43725eed9e4495878dd63244"),
        Config.BypassAntiCheat and (__S("e1a9d89ec18f38e6d1ba8e6771") .. #BLOCKED_REMOTE_PATTERNS .. __S("7fe1524fdb49b33be869dbb736")) or __S("1e18cc00230e61"),
        __S("bc5045b1bbcfc9f6b0cd5395f9885c08e62f4801764754ac2600fe7e936623")
    )
end, 116, CustomIcons.Shield)

TabMisc:AddSection(__S("5a87bf62701e019b19acb3b0a6d913e41c2869ca3e00cf164e353d5e0a6feaebd46ec4dabe2115e8f1"))
TabMisc:AddDropdown(__S("f8bf39133ae427d14a4bc2ca3129"), __S("96f6b2c4846b75481b51810382da9c16d726c3ecb2efa6b9a08bc217c7065e35be314567605cf589e09e9eafbfd04e318dae3a07685398dedef0f4ed0496c50924682d4c4a66c2531af6a729fc3c66a493898c6c1d98f77d69d931ca28c65fd493f77e9cf56c"), {__S("352e2c75eaf4b6"), __S("d365a626412135a0"), __S("719d1fd701e6b7419954f9")}, Config.GuardMode, function(value)
    Config.GuardMode = value
    Guard.mode = value
    notify(__S("0fd49988fdabc78eca21cdfe1274"), value == __S("ae0c1339e94daa3c01bd90") and __S("4c438ceae043726888f03ab5173160366dae567ff04fa45d55a0036767399188723ea0b591b3adf88cf5620a2c72f894eee7d1") or (__S("ea7b069b7c5eb17d2fa3ea") .. tostring(value)), 4, CustomIcons.Shield)
end, CustomIcons.Shield)
TabMisc:AddLivePanel(__S("88b2804c766cfd80f96b785f0583fd09"), __S("26e9f9fdb0eca6d32be63ea73c2433f4c8c046a2faa9ba61ce43c19e250d754bdbf4167bcb915c21e3f3e916c7df685d5028b811d8b109453e4b59d5cb59a3a7df"), 2, function()
    return Guard.report()
end, 104, CustomIcons.Shield)
TabMisc:AddButton(__S("c52173aec72508b1950da208c0fe78252301aabb363bf6128b6569823fdc126e65d741"), __S("6358ed5fb2ea607fb6c671332522c36c7a0b925b839e239ad59cf380fb690d552899b01045e6f47ed0b92753ef0b6b786ed720d89bea74029c012a7a02cdc8f5490b7b1afa78e630f759a9febda6c8e6a437eb72324da06fe1b0318a7704c6587cad0158abcf3e3acce56ca09eed58efff5d0ef6c7a14093c8ac55349177a72997638e1cede498325d"), __S("01906710caf1f452"), function()
    local text = Guard.report()
    print("[Skill Hub] guard report:\n" .. text)
    if type(setclipboard) == __S("9fc7e0c188c5db3450bc0f9e") then pcall(setclipboard, text) end
    notify(__S("3dff5a722d761d9783"), __S("dc36d42368ceb33281b77733b2810c143208683fcda027072f13b16506e257d251a23a297988fecaf57053db820f") .. Guard.fingerprint, 4, CustomIcons.Shield)
end, CustomIcons.Shield)
TabMisc:AddButton(__S("7a6e4dd4ac57cf2d4afe4946d9427bdf985e32798dd93e4c"), __S("18a5c7851d37d30fda41650de862eb20456c7d0a2f7650aa8cc96d26436abc829dae3e1bae1d93736d887950a01bf098be80801d211ba98f5168f5cf75ee9aeaf4b95c40601e6078d20aee45b2560be0a5ca1b20df7f6c1103"), __S("b6dd41366a69b8b762"), function()
    local broken = Guard.audit()
    notify(__S("5514bae7f79f40f4e6089fd14c462bf7"), broken == 0 and __S("f34c3498d4cd4a72e34ee5f9fdd3159005c8b912140d069519de79df170d3e73ddbd9b7c9fd106a7f4") or (tostring(broken) .. __S("9183ae49cc1bbe147471efc3eafee8c1dc42043420b357df16b608166647b2b8b904079a012f1230e4")), 4, broken == 0 and CustomIcons.Shield or CustomIcons.Stop)
end, CustomIcons.Search)

TabMisc:AddSection(__S("2fbb27fa0c2ed81de091d7c0a1ad8e7152423da5"))
TabMisc:AddButton(__S("cdf2a1ab0218b7a55db5d5b5145935b585c1eaa307"), __S("6c2a1b5c2fe4336ab2f1c1f25bdf04ee902b2849d19dc9242f5cc4742c95c07423f9246f2ae461dc6af666"), __S("0a61950d9deaf93f4f44d0"), function() invokeCommF(__S("a8990ebe6a20d505593525"), __S("46d0886ff1e8cab4decdd7")) end, CustomIcons.AutoFarm)
TabMisc:AddButton(__S("e50802200c2ca15b453bfac318fbdfced9f31bf81d"), __S("833f7bd1c06927d5ba27d6f29ce9f5bf6dd2804ea4b8a83afa1cd3d4a037f7c6c3b07b5899029a5fcba61a"), __S("2176f5820c8bc05e5c3d72"), function() invokeCommF(__S("bfae6f33a49afa61a45897"), __S("5de5e8e4d52d0bb6941343")) end, CustomIcons.Shield)
TabMisc:AddToggle(__S("fc1d6295a10cc4dc751def41990021143c9384801ed7f31159ed"), __S("9a54dc46ecd48efc2d70ac073c02550a0602f15b62e5cd88519676558b88954c6929cf4fbe722580d38e9f44497a1adfc293914396dcf28119ffd7c2"), Config.ShowWatermarkHUD, function(v)
    Config.ShowWatermarkHUD = v
    WatermarkBar.Visible = v
end, CustomIcons.HubCrest)
TabMisc:AddToggle(__S("388c55f7790a3ff774637a515155816b4264cd"), __S("d6c3cfa81cb21245cfc6f8c0a0dd2113a46afea3629ff88d2bfd859d559887"), Config.WalkSpeedEnabled, function(v)
    Config.WalkSpeedEnabled = v
    if not v and getHumanoid() then getHumanoid().WalkSpeed = 16 end
end, CustomIcons.Lightning)
TabMisc:AddSlider(__S("74fb4959c6c78d847199ef94752b615a12fa21"), __S("1332c30a8089088a3129212e1e458cfcf3bdcb46ef44d8cb76"), 16, 200, Config.WalkSpeedValue, function(v) Config.WalkSpeedValue = v end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("b16a3cbb2faa4279f658e9a98be020a24106d2"), __S("4fa1b66cd5239c9bc02c9b4e3692ec9aa8c9676697ecdd586a44afd32b7c70"), Config.JumpPowerEnabled, function(v)
    Config.JumpPowerEnabled = v
    if not v and getHumanoid() then getHumanoid().JumpPower = 50 end
end, CustomIcons.Lightning)
TabMisc:AddSlider(__S("edd9301dbad812db91c6464c3604b65e8a337a"), __S("8c10a9ce592830488e31072cea52d1c9a5fbf257a5"), 50, 350, Config.JumpPowerValue, function(v) Config.JumpPowerValue = v end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("2a48237fa2f3c9d97b98"), __S("c87f9d300b5c010b21084d1f565d51893a95fb0796dc3a877a2cbe697669803e403333c3"), Config.NoClip, function(v) Config.NoClip = v end, CustomIcons.Shield)

TabMisc:AddSection(__S("66b716e1173cc6f1dd90ae76e26c437407d4e7124330a029f7b998aa"))
TabMisc:AddButton(__S("04ee90923e3ada56b6b6feef971413a3ec06cafa695ec0f9596733"), __S("a3260a43b52c3a2d28e468352304563e9287e4ecca3cd949d2224f5a5ac0ec1592daaf0ac4327883ffeaf099f964e889322f6e1b014c"), __S("415d83f4979a9718747b568a1151"), function()
    local rem = ReplicatedStorage:FindFirstChild(__S("df94fda547b696ce39130a"))
    local redeem = rem and rem:FindFirstChild(__S("7dcc77563719ce8ecc68"))
    for _, code in ipairs(ACTIVE_CODES) do
        pcall(function() if redeem then redeem:InvokeServer(code) end end)
        task.wait(0.1)
    end
    notify(__S("1c03f10795b787cde8c30baf74a6375a4997"), __S("ba3b6ab89c5122a85215ef42a863cceb9f65d3c3eca9e641d6196f127607de2971367ef0feec9d940a4a"), 3.5, CustomIcons.HubCrest)
end, CustomIcons.HubCrest)
TabMisc:AddButton(__S("5872e4699048fbed68f1838675d71269b8914b37ff98d213ef306e36"), __S("f6aa5e1a2a718478e6a29e191212b3e6cd5ff28f9f2292d9a4ee4a6642ab669a2e80041ffcac45471443cc786f060e98bf0cffceb4659205bd92d2b0445494"), __S("94e1d7cb68b74916f72b2215"), function()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA(__S("3319517c45a0242d3e34b0b7")) then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA(__S("d150cb2d8761e70cd3ac54bf59ac63cc042373")) or v:IsA(__S("6f8844dee36cbd7871")) then v.Enabled = false end
        end
    end)
    notify(__S("0dbfbe8ffeb6979266c009fccc"), __S("abf73840983e4bba1ce672f956ed4508bb1ccb3ad68f91832d311f9060434c0e7638ea"), 2.5, CustomIcons.Lightning)
end, CustomIcons.Lightning)
TabMisc:AddButton(__S("4a2eb1f18b944f706bb92e673224c6c227e7bf9c2e4ba01daa"), __S("e8662ba2192406b1afbf094e2ad8e68fbb9716222ec8ed268d2399df4c22aedcbfe4e0544d5cbb744a05bab9b35186"), __S("869da5531a5f43d49926"), function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end, CustomIcons.Loop)
TabMisc:AddButton(__S("24d51f040d893f2eab28e7421a34"), __S("c30c98b5f0e0a2b1c0e5d6ed7c2c731de7d22b54b435b8c74e7e3217a730085c14b5454455d1b736adbac213ca8427df"), __S("61441266eaf942"), function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end, CustomIcons.Teleport)

                  
local windowVisible = true
local function toggleWindow()
    windowVisible = not windowVisible
    MainWindow.Visible = windowVisible
end

MinBtn.MouseButton1Click:Connect(toggleWindow)
FloatBtn.MouseButton1Click:Connect(toggleWindow)
CloseBtn.MouseButton1Click:Connect(function()
    stopTween()
    Hooks.clearESP()
    flyDisable()
    removeFloorPad()
    ESPFolder:Destroy()
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.F9 then
        toggleWindow()
    end
end)

                                                     
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.AimLock = not Config.AimLock
        Hooks.notify(__S("ff7b8c17584e14768d590ee298c7f33bd4daa6af9782a4568a1a"), Config.AimLock and __S("9db305c8a88fbaea7edbf4") or __S("3bea7f79694ba9eeb064b860"), 2.5, CustomIcons.Aim)
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        Config.FlyEnabled = not Config.FlyEnabled
        setFlyState(Config.FlyEnabled)
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
                                                                                     
        if Config.FlyEnabled then flyPark(not Fly.parked) end
    end
end)

                                                                               
                                                                             
                                                            
markRespawnQuiet = function(seconds)
    RespawnQuietUntil = math.max(RespawnQuietUntil, os.clock() + (seconds or 2.5))
    trace(__S("da21f92ada693726431b54228c4de3aefea3eaef25b0b3172f6c4ba8e281"))
end

local function watchDeath(char)
    local hum = char and char:FindFirstChildOfClass(__S("785972dbd2c489781f6f37f5"))
    if hum then
        hum.Died:Connect(function() markRespawnQuiet(3) end)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    markRespawnQuiet(2.5)
    task.wait(0.2)
    markRespawnQuiet(2.5)
    watchDeath(char)
end)
LocalPlayer.CharacterRemoving:Connect(function() markRespawnQuiet(2.5) end)
watchDeath(LocalPlayer.Character)

                                                                               
function UnloadSkillHub()
    Config.SafeHookMode = false                                               
    Config.BypassAntiCheat = false
    Config.FlyEnabled = false
    Config.AutoKillSelected = false
    Config.AutoKillPvP = false
    Config.AimLock = false
    Config.ESPPlayers = false
    Config.ESPFruits = false
    Config.ESPChests = false
    Config.ESPBosses = false
    Config.ESPIslands = false
    pcall(function() setFlyState(false) end)
    pcall(function() stopTween() end)
    pcall(function() removeFloorPad() end)
    pcall(function() Hooks.clearESP() end)
    pcall(function() ESPFolder:Destroy() end)
    pcall(function() ScreenGui:Destroy() end)
    pcall(function() WatermarkBar:Destroy() end)
    pcall(function() StatusBar:Destroy() end)
    print(__S("1690ec8cd781815eec00e4f71cd1b32cd0eca0aee754cd34"))
end

                                                                               
                                                                              
                                               
tabCensus = function(label)
    local parts = {}
    for _, entry in ipairs(TabRegistry) do
        local page = entry.tab and entry.tab.page
        local count = -1
        if page then pcall(function() count = #page:GetChildren() end) end
        table.insert(parts, string.format(__S("b4c8663d5f405c97eb"), entry.name, count >= 0 and tostring(count) or __S("52ffdfeeb0")))
    end
    print(string.format(__S("f137599f66b4005c44d562c216d266f1e9ef3050b3640bd0"), tostring(label), table.concat(parts, __S("8f6ed350b26463a1"))))
    return parts
end

tabSelfTest = function(reason)
    tabCensus(reason or __S("2da64d013635b84b03cc7bd96227"))
    for _, entry in ipairs(TabRegistry) do
        SkillHubStep(__S("cbddc6b2a395057acb99644774898b7e8801bd") .. entry.name, function()
            if entry.tab and entry.tab.Select then entry.tab.Select() end
            local page = entry.tab and entry.tab.page
            if not (page and page.Visible) then error(__S("6a154063ff5e36cb219fd52485e8868883a041303bab45994f43a59b4f2445"), 0) end
        end)
    end
end

tabCensus(__S("084cba14870deefd52d96ed4fc21"))

Guard.audit()
Guard.startAudit()

                                                                            
                                                                           
                                                                              
                                                                          
SharedEnv.SkillHubInstance = setmetatable({
    version = __S("a68433c5e80e3417"),
    banner = __S("44bbad762fad8e53d8eb91f2723afeaa0fe2222e34aa7cf13f"),
    config = Config,
    hookActive = function() return HookRegistry.namecallActive end,
    unload = UnloadSkillHub,
                                                        
    tabCensus = function() return tabCensus(__S("e2f32727d804154395fb5abfdaf6041067c57559792c45")) end,
    tabSelfTest = function() return tabSelfTest(__S("812aa0d8348177ab1119d755042ca798feb8f1a489181e4b2034")) end,
                                                                             
    guard = {
        fingerprint = Guard.fingerprint,
        licensed = Guard.licensed,
        mode = Guard.mode,
        report = function() return Guard.report() end,
    },
}, {
    __metatable = __S("1f621a89c39a79065d01d748c9ba3312e6e5b1420da3612df22d877ff937b65d"),
    __newindex = function() error(__S("bd99943a46094997169d60ce665bfbe7a1ae705ad70d6e66b4c9e500def58372cb90d87c105b8e7e26b432f4dfe186b0a19275e6"), 2) end,
})

print(string.format(__S("5bd10deb264a3e446e3e9f5eb1bc7e8f274074d7a94a9d4358eaaf66dacd80fb4eb9e54fcb96ca8b61d493dae801ce19d34c85abeafceaf79731a2009cd14371ddc934aa89f1b71530817abe18f0f3ab57a4fe81f565eff6ddf33def9faa59708f69f3fab3c52632f74fdac842abf5323e262edd5ee697b63b6572b96ce8ed4c3220a700792d2bb085"),
    ExecutorName, CURRENT_SEA, tostring(SEA_DETECT_SOURCE),
    tostring(Config.HookEngine),
    HookRegistry.namecallActive and __S("fa08879c8044256fa025") or __S("9840014d3670a8"),
    Config.UseVirtualInput and __S("36777afe45cf") or __S("d4aef4afbd4771"),
    tostring(Config.GuardMode), Guard.fingerprint))

notify(
    __S("72e66e60063d152b00602f57881e844c9215a9fdf7918cd9f3"),
    string.format(__S("111de8119c39987c8a70c79bd5a1bfbdc08a44af81c9defbc7f0919ece803590f7a192bdcd062843f2536a0bdb84e1e254a2df41a3915e76e564945585bd8ed8b8645a7366e70727d3e2658299e51d69a031286eeb964fd624a72c03a18adf88f357ebdf6df52b2f38e723602e26342a9563e514356a129967eae636043ab974c341"), CURRENT_SEA, tostring(SEA_DETECT_SOURCE)),
    5,
    CustomIcons.HubCrest
)
