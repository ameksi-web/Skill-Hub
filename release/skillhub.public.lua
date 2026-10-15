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

                                                                              
    Author             = __S("a0ff0a1dc212ec0710bb24e3eb96"),                                                      
    ShowAuthor         = true,                                                          
}

                                                        
                                     
                                               
                                                                                
                                           
if SharedEnv.SkillHubNoHooks == true then
    Config.SafeHookMode = false
    Config.BypassAntiCheat = false
    print(__S("3f3683ce12fa6099d04cad4a1f31e3ce2220bb2aefb038e2ac49565c3dd9196b6e872d3a97b3bd3eef4dac5a62c6fe36d014a0b53800df0097499e92aeb16740b58b8815c8415c676e9a851257776e"))
end

                                                                       
                                        
if SharedEnv.SkillHubNoEvidence == true then
    Config.NoDiagnostics = true
    Config.CoreGuiWatch = false
    print(__S("dd6dfd7f853333c8175a61be7f0051a59848cab1e1e64872b9ec745356dafd3f69533d530782f7a11bdaac28cc5019fa0949a6c63be645c85993b32be1eeb0803fc21112ea5e528ec17b07aa8bf5822bee5256a125db"))
end

                                                        
                                            
if SharedEnv.SkillHubNoVirtualInput == true then
    Config.UseVirtualInput = false
    print(__S("7ba57730eac998264aed941ade3afdc430a4211de262a2bb798cd664a7b9082bd2197a70e1b9b86c420b238424cbbda7e9972b8ff36dd761d2b5652c8d60648e9ceaa3642abe7dcd3b66"))
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
    print(__S("19dcf0e17ae96daa1ea1c41bac9d34e9fe1245138e7c7908ddf64506840e627b61a878be5124871999a268ad11db36466b0c175a82a2c6c67147a8cb34f1a328d0c8a7cee9975dcea4c43b4bf3c5"))
end

                                                                             
                                             
                                         
if SharedEnv.SkillHubMinimalMode == true then
    SharedEnv.SkillHubNoVirtualInput = true
    SharedEnv.SkillHubNoHooks = true
    SharedEnv.SkillHubSafeMode = true
    SharedEnv.SkillHubNoEsp = true
    Config.UseVirtualInput = false
    Config.SafeHookMode = false
    Config.BypassAntiCheat = false
    print(__S("b8146a924ae364fd4a750da85db6769fcaf55fb35a890ec743472abbdfb7c289c9312d0c575b5c14f413b7688655aff4c83357ac69acbb4c16520b0ed3fb8d31c7595c7781766096df0e498305724f75232ca0f7edd2565ec184"))
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
    table.insert(ActionTrace.items, string.format(__S("564be443479f91656ab152a01c68b0"), tostring(action), os.clock()))
    while #ActionTrace.items > TRACE_MAX do table.remove(ActionTrace.items, 1) end
end

                                                                               
                                                                               
                                                                            
                                                                             
                                                                        
                                                                            
                                                                            
                                                                             
                                                                            
                                                                     
                                                                           
local SkillHubEvidence = {
    boot = os.clock(), log = {}, max = 12, names = {}, numeric = {},
    readable = true, report = nil, watch = nil, identity = nil,
}

do
    local LF = string.char(10)

    local function coreGuiService()
        local ok, gui = pcall(function() return game:GetService(__S("f4835df46910c2b96181e8")) end)
        if ok and gui then return gui end
        return nil
    end

    local function identitySample()
        local ok, tb = pcall(function()
            return select(2, xpcall(
                function() error(__S("92bad7a59153e835f533cc8b7b7f18b9118dcae5b65a48a7b3e45aff"), 0) end,
                function(err) return debug.traceback(err, 2) end))
        end)
        if not ok or type(tb) ~= __S("30f25156093f0e54c382") then return __S("cf29cb07361874a633029b20a277a2644de5518766a9d2b5c813b7e93db76879") end
        local first, second = string.match(tb, __S("6d6144b80b87d9") .. LF .. __S("0b98be697eb8bf") .. LF .. __S("a9d0381a3b2285") .. LF .. __S("4807b1cb090c16"))
        if not first then return __S("e63f2b7c21fd7d91c5bb6c7f961a9bd803e12c54fc318348930da3838d4bcd62") end
        return first .. (second and (__S("8476a52de48376c114") .. second) or "")
    end

    local function creatorNote()
        local ok, tb = pcall(function() return debug.traceback("", 2) end)
        if not ok or type(tb) ~= __S("22ae1ede971e38ecc10b") then return __S("c0e5988fa124c917e65f268055c19970f4745e3a7d") end
        local frames = {}
        for line in string.gmatch(tb, __S("5f1d1240f192") .. LF .. __S("fd548bf13925")) do
            local clean = string.gsub(line, __S("9b8c05a2a01cc42e"), "")
            local skip = clean == "" or clean == __S("39c37f53f4de6af7a037523b9480a3") or clean == __S("d7faf9041a97ac5165bdf83811")
                or string.sub(clean, 1, 3) == __S("763272b53c5cc0")
                or string.find(clean, __S("1469ec6667e05432ea9173b1ce91a6cb400709"), 1, true)
                or string.find(clean, __S("b2a1661785e728c83dbc276762ea5f"), 1, true)
                or string.find(clean, __S("50d8dfc83bedee0f4a067c5e81bfd752"), 1, true)
                or string.find(clean, __S("ef105979e236ff07d34496f182a5147cc0ffce"), 1, true)
            if not skip then
                table.insert(frames, clean)
                if #frames >= 2 then break end
            end
        end
        if #frames == 0 then return __S("8d47d32ab552b6c1f80eb2f3ab8a8fc6e97dbf6672a80f02688bd77b55d47460b634e6b1ed59e59f542833d4246ab3fe0befce5eee42f50ac9") end
        return table.concat(frames, __S("2b7f4cdba9f774493dd508"))
    end

                                                                                
                                                                             
                                                                                
                                      
    local lastNote = -1e9
    local function coreGuiAdded(inst)
        local okName, name = pcall(function() return inst.Name end)
        if not okName or type(name) ~= __S("c9b6c68cac512eb82cb2") then return end
        local okCls, cls = pcall(function() return inst.ClassName end)
        cls = okCls and tostring(cls) or __S("67ee403dd6")
        local isScript = (cls == __S("0625b9ee715d07027595") or cls == __S("a45d339fc465255403c67fef49bb92") or cls == __S("4294ad506201a5699a84e73649f84b24"))
        local isNumeric = string.match(name, __S("e0cc2701a9d86e55b2")) ~= nil
        if not (isScript or isNumeric) then return end
        local now = os.clock()
        if now - lastNote < 0.1 then return end
        lastNote = now
        local numeric = isNumeric and __S("7f03a0b218edbbe3d22b95d6024fabc1556966c9cbc82d01ea98f0b849e88f494bb46d1e96b9a744606bc6") or ""
        table.insert(SkillHubEvidence.log, string.format(
            __S("1d3b1a6303c6e2b19ee5d85acfddbb9dcc5f30cb0067be0861715567a784ac5fca16ef8235a2e3f6"),
            now, isScript and __S("bb7294143f879ff7864a22") or "", cls, name, numeric, creatorNote()))
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
                    if string.match(n, __S("59aa0dc512aec76570")) then table.insert(SkillHubEvidence.numeric, n) end
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
            print(__S("f7e187768a7ab384a826cfc8bf7308ff61436ec0b29121867815ffd3f705472b87911560969f6eb29fa959d9678ad2b2c89a7af95e4b880a8cc7763439e4d7d5254d4d552ba6887749d38106b8ecd219ef8c18786d74a83ef31d2fb600"))
            return
        end
        print(__S("9619012742fe14c62df5aa47ef80b250") .. tostring(reason))
        print(string.format(__S("34507ad8dd01e8ab526de885e5d777e15636f18df9774b514022f09147d8a7c2a7b89511af2016db9f206d8d52a801268cdcbd45ba881ba5c07298a65a83e693e461b639ed1421b7705bdc19a1b8d0b0f283a4a05d2690832291cdc3e159d18070d71c67b9680a762cfc636da43f9e2fa0ff40fe5c47a6"),
            os.clock() - SkillHubEvidence.boot, Config.UseVirtualInput and __S("d287f4898de7") or __S("70bf6e3a291e19"),
            tostring(Config.HookEngine), identitySample()))
        print(__S("0ef6e7eb0e67e7cced808c1cbb6c19640b7e2d652d25cb0574eb6f14146e00e25a"))
        if #ActionTrace.items == 0 then
            print(__S("ad2e619c7294772ccf024ef80a120c0049ca177911f6289ce117533a04d02cdf3b60648aca3a33a47d6bb505e8f7be63305d0858e77fd7a2d1474ed7900767391652a74531b6ee63d3623b4070adc9"))
        end
        for _, item in ipairs(ActionTrace.items) do print(__S("4b65db4d0b8fe2e6642b2c4373c236") .. item) end
        if not SkillHubEvidence.readable then
            print(__S("e99d54febf3c544b05cce10c6b3a6bcd12f4fd3b30660f4aa48bc8f92c1b72bf929cae989dd7e3140101d79f0dc7d8ec86fbf074c1b3a8"))
        elseif #SkillHubEvidence.numeric > 0 then
            print(__S("87d4ceaf6f19104277c774f18b66adeca16bdfb58d73c0dadfd0c08d1f51f79e03cff61e3bda03194452b10adcd601e00cfff1a57591210337680a12715fe1719b271a569d50fa6db1d786f3a674edb1180e011cf3ab")
                .. table.concat(SkillHubEvidence.numeric, __S("260c4860cc9f")))
        else
            print(string.format(__S("c443c21111c9b9733da3f73809d074e03b109ed2296999f221a4403eefdcdabe8dd03f4db7a20b0ee785975b36551b6186efc3d017991cbc3709d5ed8e5c37f4301730b0035617b17a4d7775965d0561b2f3"),
                #SkillHubEvidence.names))
        end
        if #SkillHubEvidence.log == 0 then
            print(__S("627b3bc20347e748de0cb2482391a03929222375217fb8ba66ceb9c258ce2360cf7c579fd691fffb4f0e655c0c62f51debabb4c142856e90468f0f46489f2a2afce19a9c75e11d3bd9"))
        else
            print(__S("00b2b573fd01f1b1ee8746e1b920641017c53bc90f7750bcaa8f3317242514ecfe9e37c4a2c1a8"))
            for _, item in ipairs(SkillHubEvidence.log) do print(__S("9eea2f24e3644b46f0bf150d65e488") .. item) end
        end
    end
end

do
    local ok, LogService = pcall(function() return game:GetService(__S("3d21a8d584763543baf6aa38f12c")) end)
    if ok and LogService then
        local lastDump = -1e9
        pcall(function()
            LogService.MessageOut:Connect(function(message, msgType)
                if type(message) ~= __S("db592286319f5b93587e") then return end
                if string.sub(message, 1, 11) == __S("79909c37e76b0c45b23020817f5b88") then return end                                 
                                                                            
                                                                                
                                                                                
                                                                                 
                local mentionsNil = string.find(message, __S("17c815e87cc11c3a86660734f9"), 1, true) ~= nil
                if not (mentionsNil
                    or string.find(message, __S("b5ff8f993cf9baa5adbe1a"), 1, true)
                    or string.find(message, __S("5437094a29723f5105f9cd"), 1, true)) then return end
                if msgType ~= Enum.MessageType.MessageError then return end
                local now = os.clock()
                if now - lastDump < 5 then return end
                lastDump = now
                print(__S("f26e82fbd8affda62e31f9abd4b2e59b6fb17eb50edab3b76b4ef19ec8ea979805237e21c784a4f037afd09284") .. message)
                pcall(function() SkillHubEvidence.report(__S("90a5fcacc3b973b9a3aabe10b9ecb09ab433e18cc002751c3f7da719fce65884f464c6b8b5b108a6bb2c7b7e69523a6650")) end)
            end)
        end)
    end
end

                                                                              
                                                                            
                                                                             
                                                                            
                                                     
do
    local LF = string.char(10)
    local ok, SC = pcall(function() return game:GetService(__S("2edd765dc5fe14e54ecd30bd8870bf911c")) end)
    if ok and SC then
        local lastSCError = -1e9
        pcall(function()
            SC.Error:Connect(function(message, stack, script)
                if type(message) ~= __S("cd14f00e77db31709f55") then return end
                if not string.find(message, __S("6b4c69bfac0593aaa28f0df7b9"), 1, true) then return end
                local now = os.clock()
                if now - lastSCError < 5 then return end
                lastSCError = now
                print(__S("0983e3701d8a02b685f418f01fbb7a3e2f385a874c77ddb3fea12d7c86a098a6b8f1975e") .. message)
                if type(stack) == __S("a7bb5d219d4a527db4b8") then
                    local shown = 0
                    for line in string.gmatch(stack, __S("45f2d6d2ddbd") .. LF .. __S("e42a5083038b")) do
                        if shown < 3 then print(__S("8261ca3467917f637ea35be3739e03") .. line) end
                        shown = shown + 1
                    end
                end
                if script ~= nil then
                    local okFull, full = pcall(function() return script:GetFullName() end)
                    local okCls, cls  = pcall(function() return script.ClassName end)
                    local owned = okFull and tostring(full) or __S("209943e548")
                    print(string.format(__S("bed0bd96e7a8b2607c3c7b2946172a4b9c223e69c0ac2efead6a92b64c9d68f26a"), owned, okCls and tostring(cls) or __S("5d08374768")))
                    if string.find(owned, __S("fb3fb0f82b8a400a5cd863"), 1, true) then
                        print(__S("99772aa998b1b81e8e5b11ff29153ef016a1f56baf6e4dcd96f317df0b695eca7dd14a5dfb79988dcdab5e964dbf1f0a31dfc07ff63129bfa81352d4d72da52ece53"))
                    elseif string.find(owned, __S("37aea45aa54e826f0e9ab2e7"), 1, true) then
                        print(__S("d5e61e0b389d09ca3ded60e0c06d49ef5da7e20dafa36e3dd30a7adc61eab81e3e6474bae77b4f528da40ea6646be48995bc8c7ce9ce627667c077779d762e60a8a2"))
                    end
                else
                    print(__S("741d97bcc96575ddc719b5f2eea04906577e75cd4a316dcc25e251739dbe53ddd42dc2ed0446f729d7bb007a75308c123b42c6645c2876"))
                end
                pcall(function() SkillHubEvidence.report(__S("1255116d1701c4d57791044fcbff4ac03a4406d06e05fc9703972a20f20288be721c")) end)
            end)
        end)
    end
end

                                                                               
                                                        
pcall(function() SkillHubEvidence.watch() end)
pcall(function()
    print(string.format(__S("b08c8b1e921452729675749946e5339b5e3cce83f998a4d457c5e766a30dc5cece09f2e271e875135615971c0c679b6a8dcd40cd9257f32f59a421b6894e3df1ec5bdd505c5da1875a41bb4e24de68719402fd43ff"),
        #SkillHubEvidence.names,
        #SkillHubEvidence.numeric > 0 and table.concat(SkillHubEvidence.numeric, __S("4ec404cfed8b")) or __S("ecfb7e80db277b2a")))
    print(__S("8b32f83110fd93ca80484a513dc916a9bc20581430e99d73159d6a789f1d61c9789dca57558357ff020b1d47953a4c502412e0949e26dd990bb57888fb3e10982fa8f4b3bb3b88dbf72aa910e484b440cf21") .. SkillHubEvidence.identity())
    print("[Skill Hub] console watchlist armed · LogService.MessageOut + ScriptContext.Error · every \"attempt to call a nil value\" now prints our action trace, the CoreGui snapshot and the failing instance name")
end)

                                                                              
                                                                              
                                                                      
                                                           
                                                                                
                                                                         
local NoTween = {
    Play   = function() end,
    Cancel = function() end,
    Pause  = function() end,
}

local function isInstanceValue(v)
    if typeof == nil then return type(v) == __S("296a71e21ce701aa98973f65") or type(v) == __S("c7a1eb93cef667c7b1") end
    return typeof(v) == __S("65d9654435b157901afe3fc1")
end

function SafeTween(inst, info, props)
    if not isInstanceValue(inst) or type(props) ~= __S("0410def526e66e4c0a") then return NoTween end
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
            SkillHubStep(__S("a24858a67e93c020927bd7b194f1c9e469fe058b055e6726348671b426a8"), function() VirtualUser:Button1Up(Vector2.zero) end)
        end)
    end)
    if not ok then
        SyntheticInput.userFails = SyntheticInput.userFails + 1
        if SyntheticInput.userFails >= 3 and not SyntheticInput.warnedUser then
            SyntheticInput.warnedUser = true
            SyntheticInput.userReady = false
            print(__S("407fd257b67ce1e00d38523c9d49cdd56e63c999c98ece76b4626b8b6fe079f53c9d9d6f3ca3e7d733e1f6b4846d613efa24e676d606ffb54f5a8f14960267c764f95a2a043e9494149676200fc286dd3b0e1002e79d69ea39f2428a15a3a0ba62c445aae9995408a169c05d8e2abbe8d897ee9bdbc98a46007ae1777d1077a5c4accbcb3158e72db9a245d9ee01f5092189cfedf9d6e552936c780408f418a5fc3242dd956e86d2e52b"))
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
        SkillHubStep(__S("deb74c088177a07e95625c70ac9788e82f15dd6f97a15b96cec9e29f00642212f6ea"), function()
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end)
    if not ok then
        SyntheticInput.vimFails = SyntheticInput.vimFails + 1
        if SyntheticInput.vimFails >= 3 and not SyntheticInput.warnedVim then
            SyntheticInput.warnedVim = true
            SyntheticInput.vimReady = false
            print(__S("7ceec5b96ea2698f0b1df05d8383215855f19e96972a55304eb12c50328df4527affbfa38913e0e082a9b8b187eeef2e6afd195d66092e94a6c9bd956a91395b1194a86cbfca33481e2683e4e55dce388bb4676b39a2333453573c2170fd9cc64333ef83775dc65ad639b3f2c0f2a1f8f4803881c54c2a10051da84f7db2c13a7de9b3568ff5f2d58a71c024a39cc54a6275c40a3866b35c92ef9e79b2b419c1"))
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
    __S("1b263f6a8efb0c3df90a8c1611"), __S("b95db91bc5322fc00a608dc2ab4f"), __S("579532cc0b18463cd99ba0e904a7"), __S("f5ccac7dafb666f2b6148a66a51299ddc8"), __S("9404262efdedbf18a1e42749"),
    __S("323b9fdfab322347f7aaf5d6e3cd668832cf"), __S("d0731990536f16a7a47392401a9e9e"), __S("6eaa934148b8fc3df66b5820f58e"), __S("0ce20cf2a9f0283ca7442539839b89e636"), __S("ab1986a3807f9445a0feeda5c1"),
    __S("49510054b25b5e289f196772e5c2"), __S("e7887a053199e04bcaf5d4d9f2eb"), __S("85bff3b673a9325f55e6c2b016f9b8fe510ec1e6"),
}

                                                                                   
local SeaEventState = {
    events = {},
    mirage = {},
    lastNotify = {},
}

                                                                         
RespawnQuietUntil = 0
markRespawnQuiet = nil


                                                                              
                                                            
  
                                                                                 
                                                                             
                                                  
  
                                                                             
                                                                         
                                                                              
                                                                              
                                                                                
                                                                                
                                                                                
                                                                            
                                                                                
                                                                               
                                                                                 
                                                                 
                                                                            
                                                                                
                                                                              
                                                                         
                                                                           
                                                                            
                                                                              
local Guard = {
    mode        = (Config.GuardMode or __S("23f76d677de88834")),
    licensed    = true,
    compromised = false,
    hwid        = __S("c22ee718cbb3bc478a9db5"),
    keyHash     = __S("606660c958744d11"),
    fingerprint = __S("fe9dda7a8630230fc751e1"),
    watched     = {},
    lastAudit   = 0,
    auditNote   = __S("9cd5542b0d300ab26746ae776fd4c1"),
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
                                                                             
                                                                       
    if type(bit32) == __S("3b0ccddc138a9e73d8") and type(bit32.bxor) == __S("d944478dd15f602e4036e11a") then return bit32.bxor(a, b) end
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
    return string.format(__S("777bc13eb567133c"), hash)
end

                                                                               
                                                            
local function guardUnseal(blob, tag)
    if type(blob) ~= __S("15b33aefeb7c4026b1c6") or blob == "" then return nil end
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
        if ok and type(value) == __S("b3eab4a099e60228bf8d9c91") then return value end
        return nil
    end
    Pristine.HttpGet = grab(game, __S("52222e514d3503fa2ea4df"))
    Pristine.HttpPost = grab(game, __S("f059a80226580abdbe75f024"))
    Pristine.loadstring = loadstring
    Pristine.info = (type(debug) == __S("8e9121b394ad34985e") and debug.info) or nil
end

function Guard.http(url)
    if type(url) ~= __S("2cc89b6405d7c92b435f") or not Pristine.HttpGet then return nil end
    local ok, body = pcall(Pristine.HttpGet, game, url)
    if ok and type(body) == __S("cb00151537d89dd46e97") then return body end
    return nil
end

                                                                               
local function globalsTable()
    if type(_G) == __S("69378ec6e5de8ca00e") then return _G end
    if type(SharedEnv) == __S("076f0877d355140289") then return SharedEnv end
    return {}
end

local function rawHwid()
    local env = globalsTable()
    local candidates = {
        function() local fn = env.gethwid; if type(fn) == __S("a5a682289ff905c0664627f4") then return fn() end end,
        function() local fn = env.get_hwid; if type(fn) == __S("43ddfbd9ac2af56c2784cf78") then return fn() end end,
        function() if syn and syn.get_hwid then return syn.get_hwid() end end,
        function() return game:GetService(__S("e215758a8ae4de073e1c0c2ffaf52f6dfe25b5c09e2793")):GetClientId() end,
        function() local players = game:GetService(__S("804cef3b7ecd144e11ea48")); return players.LocalPlayer and players.LocalPlayer.UserId end,
        function() return tostring(game.PlaceId) end,
    }
    for _, attempt in ipairs(candidates) do
        local ok, value = pcall(attempt)
        if ok and value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    return __S("1e8468ec55cacb1e27fb3c")
end

Guard.hwid = rawHwid()
Guard.keyHash = guardHash32(tostring(Config.LicenseKey or ""))
Guard.fingerprint = guardHash32(Guard.hwid .. __S("bcbbe29db5d0fffc4832a2a30cfc"))

do
    local keys = Config.LicenseKeys
    if type(keys) == __S("5af35c4ee7aec8bf39") and #keys > 0 then
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
    if Guard.mode ~= __S("f92ad5fff04ec269d5ad49") then return false end
    return (not Guard.licensed) or Guard.compromised
end

                                                                               
function Guard.watchTable(prefix, sourceTable)
    if type(sourceTable) ~= __S("97624fb0ce08d93c5a") then return 0 end
    local count = 0
    for key, value in pairs(sourceTable) do
        if type(value) == __S("3599c9613defaef8c2dbb68f") then
            local identity = nil
            if Pristine.info then
                local ok, info = pcall(Pristine.info, value, __S("d3d14312d8"))
                if ok and type(info) == __S("7208bcc3184f4d4b56e0") then identity = info end
            end
            table.insert(Guard.watched, {
                name = tostring(prefix) .. __S("104036747d") .. tostring(key),
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
        Guard.auditNote = __S("ae77b025e9e1601ffde1610459ace668d2d4bc4999c6aa2f0e2ebd18184ba042143bad36d6e3dab9bd6806566c4ecb0613059e67cb")
        return 0
    end
    local broken, checked = 0, 0
    for _, entry in ipairs(Guard.watched) do
        if entry.identity then
            checked = checked + 1
            local ok, info = pcall(Pristine.info, entry.fn, __S("4caf29d6ef"))
            if not ok or info ~= entry.identity then
                broken = broken + 1
                if not entry.reported then
                    entry.reported = true
                    print(string.format(__S("eae6a38717a59ee355bb861803fb6649d7228fa9884cb232a5059c3e4b0e0c88a7f0cb1523532077054d9612a186e325f5757fab84a1c5a59b1ae44bfa852012fec5844bc9a363"), entry.name))
                end
            end
        end
    end
    Guard.auditNote = string.format(__S("891e1d38c1a1b5ab6b592ca76488de5cde9f3052551906a720fac21259b378dec0a8836e0652"), checked, broken)
    if broken > 0 and not Guard.compromised then
        Guard.compromised = true
        print(__S("275596e9d6cdd4f7b9b4c21c5b1c4106103b333ddd0cadca4d206d3286a710e38f9d8ed80008a8e5cd2148f27d12aa89b81dc04ca83408cce4cb0b055038053c0b6feae5e8af87680e77e85f94985a27a68b8579933ea43a23058bfb4b"))
    end
    return broken
end

function Guard.startAudit()
    if Config.GuardMode == __S("c58d109a9a45ed") then return end
    task.spawn(function()
        while true do
            task.wait(math.max(tonumber(Config.TamperAuditSeconds) or 30, 5))
            pcall(Guard.audit)
        end
    end)
end

                                                                               
function Guard.hookRadar()
    if type(getrawmetatable) ~= __S("63c48a4bcb6df58fbb4e25b7") then return __S("01fc03fcfa6c1f8227db9f9baf8668d6c6b9d20aeb6bdadb42ef44c3de4504") end
    local ok, metatable = pcall(getrawmetatable, game)
    if not ok or type(metatable) ~= __S("a0337dadda9dc03c2a") then return __S("3e6af75eb9c25982e59af03076829097f7f317a41b14d523674f8c4e3d6133") end
    local namecall = metatable.__namecall
    if namecall == nil then return __S("dca2710fe0c513eed2a99c50946568e22db9d5ac26b2891cbe701485d5b4be20227dc3ecbe14df") end
    local kind = __S("7ad9eac075a2dca203f444e64c436771")
    if type(iscclosure) == __S("1911647118c66f93b5f94c17") then
        local okC, isC = pcall(iscclosure, namecall)
        if okC and isC == true then kind = __S("b748de22a700f519a7481f35e0e014332fb0774e667dda4585c7600e4b3c8d993971") end
    end
    if type(islclosure) == __S("558057d3c89d37ffd5fafbd1") then
        local okL, isL = pcall(islclosure, namecall)
        if okL and isL == true then kind = __S("f3b7d184ebfe6922650943d63bf2b591c102d52b332eee4ea32ca4ae945fe25b6519fb2abd0d0097") end
    end
    return __S("91ef4b350ee2b5922126f6776d80eb4a8cd63b2deefc99942b") .. kind
end

                                                                               
function Guard.endpoint()
    if type(Config.SealedEndpoint) ~= __S("3026c4e6a8a827373560") or Config.SealedEndpoint == "" then return nil end
    local url = guardUnseal(Config.SealedEndpoint, Guard.fingerprint)
    if type(url) ~= __S("ce5e3e9702a9b3220406") or not string.match(url, __S("6c95b84818592836a03561d0be71")) then
        print(__S("0acd31f9db56f3b9884bb978e46d3e2ed3da38a5f2ee0edd1a03d16444fd021325640140bb05510bdcca7c1e34fc8bea0e51b5f4d635f72130df388a8c20e44755c937360ddf6dda72558c18738c6a95bf90aa2aaf51f04ef32e16059e1b947a4f"))
        return nil
    end
    return url
end

function Guard.requestHeaders()
    if Config.RequestWatermark == false then return {} end
    return { [__S("a904abaa8aa56ba70b7ba809e2f7777dc376")] = Guard.fingerprint }
end

function Guard.report()
    local lines = {
        __S("473c255bd73518e0321815c88dcddace15b9e76801") .. tostring(Guard.mode) .. (Guard.mode == __S("e5739f0c80c9dcad3ce491") and __S("83ab18bda351af368732734cfeedaf") or __S("21e2926eb9797f0eca051899b2fd749f606d")),
        __S("c01a0c1ff5270dd85589fe188550182ffe1b0f6902") .. Guard.fingerprint .. __S("5e5185d025eb7dc5838a3d25a5ef22e2f43e911730444db2d01deb424fcaade64a21e0605c53af8f521a9d5b4c1d1d953d9854c99e45"),
        __S("fc88ff81d11b445b0645e9d78ef4d1646de38f56fd") .. (Guard.licensed and __S("9ac0793280dedc615fab61578f88") or __S("38f7f2e338c46fc950b102aebc0aea22d8017bfba18feda834c0c76826bff7ba0ff2ac9dabc922967fcfcb133c")) ..
            (type(Config.LicenseKeys) == __S("d72f6c94fe820e74e2") and #Config.LicenseKeys > 0 and "" or __S("7566e645f2e14040ef591bf37eeb1dd827faeb89580c86be79f93c517a")),
        __S("139e5ff65fc63de8f813e2f802b84ddc328c2af2be") .. Guard.keyHash .. __S("b1d5d9a717f7aa8b5288efc1a35ceaadb34a000043968534ebe955cd6fc5c3288a6bc7d7a76ea40b05e0ceeb6fbcf2b0b0ae321fe57de91edd63fb"),
        __S("500d53585f4b5a0d084aeb877e979146763c889c62") .. Guard.auditNote .. __S("ee44cd09bb2d6c40d7ce") .. tostring(#Guard.watched) .. __S("8c7c46ba2f5970866af625faa08cd1e357dc1bb547"),
        __S("2ab3c06bfc9701fb509ed2de043de42220bba79505") .. Guard.hookRadar(),
        __S("c8eb3a1c9b7bbaee499deea96ceb9e25831be85fac") .. (type(Config.SealedEndpoint) == __S("6722b3cd131f80d4234b") and Config.SealedEndpoint ~= "" and __S("055a2d7ee54832ef170e593317ac9998eac90ee93aeff452c1ae77e191f3") or __S("a391a72f5bc34414")),
        __S("41c920e01800edc397fc83eae3f3b069086c94986e") .. (Config.RequestWatermark == false and __S("e0009a914f5f63592aaa7bf8fe0ff4f843") or __S("7e3814422dd0011ad2480f40498d1e83")) .. __S("1c6f8df35b6f6f4d47a35c728a531480a46d8a16da369defdb28688e112b5a317aa2ebfefec2186cda7953497cd6571cd8f39a392b496a90"),
    }
    return table.concat(lines, "\n")
end

print(string.format(__S("baa707a4765fe54af704878aefea59518a5cb7bd46f6b4cd2c187efb9920aa54ffa3686bbe18d3013bb67b2866bc251eca2fc421e140e71d050bcf691d740bb0e0644964a7fbec731e09b914"),
    tostring(Guard.mode), Guard.fingerprint, Guard.licensed and __S("58de8155a074") or __S("f715fb06fe90dd77d400cc"), Guard.hookRadar()))

                                                                              
                                                                 
                                                                              


                                                                              
                   
                                                                        
                                                                  
                                                        
                                                                              
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
    [__S("954d74b779c1b3fc0057")]             = true,
    [__S("3384ee68aff04c38aa")]              = true,
    [__S("d1bc6819f442086fd975786a2975e5458ce4027ccd")]  = true,
    [__S("6ff3e1cabdb9dd183da5e0d9c3261275aa09")]     = true,
    [__S("0e2b5b7b8bdda78932bd0d47b3cfe6c28e3aa5921c21")] = true,
    [__S("ac62d52cd9255419e6c2036f42")]          = true,
    [__S("4a9a4eddafcbcedbd70f")]             = true,
}

local function isSuspiciousRemote(remoteObj)
    if not remoteObj or typeof(remoteObj) ~= __S("e8d1c88ee7bc993fc54f551f") then return false end
    local okIs, isRemote = pcall(function()
        return remoteObj:IsA(__S("8709423fcafc6ab226c841ca76c346")) or remoteObj:IsA(__S("2540bbf05d2f46666f77a3c265bd68190e54"))
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
        local pScripts = LocalPlayer:FindFirstChild(__S("c37835a1f7909fa1d8581fbde2be0be500"))
        if not pScripts then return end
        for _, desc in ipairs(pScripts:GetDescendants()) do
            if desc:IsA(__S("61afaf523c30a767bd1754eb38684d")) then
                local n = string.lower(desc.Name)
                if string.find(n, __S("ffe7290301bf302b41ca5bee08"), 1, true) or string.find(n, __S("9e1ea2b4f1a3e7ee6f47a8943f4a"), 1, true)
                    or string.find(n, __S("3c561c65fca421ace93190d1c602629eeb2d"), 1, true) or string.find(n, __S("da8d961674d95bd4719566bdcf0c7de802"), 1, true) then
                    pcall(function() desc.Disabled = true end)
                end
            end
        end
    end)
end

initBloxFruitsAntiCheatBypass()

                                                                                 
                                                                       
local function applyCharacterTweaks(char)
    local hum = char and char:FindFirstChildOfClass(__S("78c50fc731cd5101c32f0375"))
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
    if char:FindFirstChild(__S("16fc8978e27baea1")) then pcall(function() char.Stun.Value = 0 end) end
    if char:FindFirstChild(__S("b5340329e3f5bace")) then pcall(function() char.Busy.Value = false end) end
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
            SkillHubStep(__S("536b7cda8f574ac48d0ffe35ac20848b"), function()
                sethiddenproperty(LocalPlayer, __S("f1a2f68b21e9fc629315fedbc5047d46961bcb52"), 9e9)
                sethiddenproperty(LocalPlayer, __S("8fda703cdfed9e4c9b8b5f87b597abb163613988f08224"), 9e9)
            end)
        end

        local char = LocalPlayer.Character
        if not char then return end

                                               
        if Config.AntiStun then
            local stun = char:FindFirstChild(__S("2e11e9ed48ccc03c"))
            if stun and (stun:IsA(__S("cc49639eaaa300de51510cb1")) or stun:IsA(__S("6a80dd4ff5a1e545e277e14c57585e"))) and stun.Value ~= 0 then
                stun.Value = 0
            end
            local busy = char:FindFirstChild(__S("08b85700eeaad388"))
            if busy and busy:IsA(__S("a6efd0b12fd527315c7ad3193f")) and busy.Value == true then
                busy.Value = false
            end
        end

                                                                            
                                                                     

        if Config.AutoFarmLevel or Config.AutoFarmNearest or Config.AutoFarmBoss or Config.AutoFarmAllBosses then
            local hrp = char:FindFirstChild(__S("45274a62ffa93545235aa229ed86aab06d562051"))
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end)

                                                                              
                                                              
                                                                              

local function getCommF()
    local remotes = ReplicatedStorage:FindFirstChild(__S("e35ec4130fd8e8d9e0459d"))
    return remotes and remotes:FindFirstChild(__S("81963dc4f0a931d4e647"))
end

local function invokeCommF(...)
    local comm = getCommF()
    if comm and comm:IsA(__S("1fcdb77536b2f8e4336ff22770d1213154e8")) then
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
    return char and char:FindFirstChild(__S("be053126bef3fc8a46e0d817d8d7d89a6aebb6c7"))
end
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass(__S("5c3caad7ac0eecad486854e6"))
end

local function getPlayerLevel()
    local data = LocalPlayer:FindFirstChild(__S("fa742488fef346b4"))
    local lv = data and data:FindFirstChild(__S("98ab9e3923b670b1e1"))
    return (lv and lv.Value) or 1
end

local function getPlayerBeli()
    local data = LocalPlayer:FindFirstChild(__S("36e317ea01f83951"))
    local beli = data and data:FindFirstChild(__S("d51a919bad7b67c4"))
    return (beli and beli.Value) or 0
end

local function getPlayerFragments()
    local data = LocalPlayer:FindFirstChild(__S("73520b4c3573c99f"))
    local frags = data and data:FindFirstChild(__S("118984fdf027759b854cde6253"))
    return (frags and frags.Value) or 0
end

local function formatNumber(n)
    local s = tostring(math.floor(n or 0))
    return s:reverse():gsub(__S("afc0feae0c3f26ab3fd58510"), __S("4df8785fc30bd8")):reverse():gsub(__S("ec2ff210b8fd"), "")
end

                  
local activeTween = nil

local function stopTween()
    pcall(function() MovementLink.clearFlyTarget() end)
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
    local root = getRoot()
    if root and root:FindFirstChild(__S("8a676bc1dd45ca83f37075a31d6bbb399caf8176")) then
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

    if not root:FindFirstChild(__S("289ee57279d67f5829ade1a44323270944d3260f")) then
        local bv = Instance.new(__S("c6d65f23b8207e0bc4aa30804b8b245f"))
        bv.Name = __S("650dd8d46c6fd55016c5791306b53a59ef16a8cc")
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
    local backpack = LocalPlayer:FindFirstChild(__S("03455285ad00279d29548266"))
    for _, container in ipairs({ char, backpack }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA(__S("a17ccc367faa6ec6")) then table.insert(list, tool) end
            end
        end
    end
    return list
end

local function equipTool(tool)
    if not tool or not tool:IsA(__S("3fb445e75747ce99")) then return false end
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
    local equipped = char and char:FindFirstChildOfClass(__S("ddebbf984098f542"))
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
    local key = tostring(styleQuery):lower():gsub(__S("7c233949694f86ff47c92abc1bb8"), ""):gsub(__S("1a5ab2faa63daf1e"), ""):gsub(__S("b8922cab0d99f9fb"), "")
    local canonical = FIGHTING_STYLE_TOOLS[key] or FIGHTING_STYLE_TOOLS[key:gsub(__S("56c9a65cd821"), "")]
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
    if not target then target = findToolByCategory(__S("f501200d6074078876")) end
    if target and char and not char:FindFirstChild(target.Name) then
        equipTool(target)
        task.wait(0.15)
        if not char:FindFirstChild(target.Name) then equipTool(target) end
    end
    return char ~= nil and char:FindFirstChildOfClass(__S("933899becd29a2d1")) ~= nil
end

                                                                               

local PVP_FLAG_NAMES = {
    __S("3170136f910bff"), __S("cfa78d20510f5f"), __S("6ddf06d143b2ff"), __S("0c168082f114b390cbb2b493f594"), __S("aa4dfa3326db2efab27afa5aed8e"), __S("488573e4c8b3cfa5a70fd9887d45"), __S("e6bced951b992e3a3c"), __S("84f467460146a64802"),
    __S("232be0f79d7fbede6cb3ba"), __S("c1635aa883c3f345fede61"), __S("5f9ad459b8fa7b6284"), __S("fdd24e0a334f1b9a59"), __S("9c09c7bb1456f991ff"), __S("3a41416c5f9fdb64444764e752"), __S("d878bb1dc05529307b506cace5"),
}

local function findPvpFlag(container)
    if not container then return nil, nil end
    for _, name in ipairs(PVP_FLAG_NAMES) do
        local v = container:FindFirstChild(name)
        if v and (v:IsA(__S("76b034ced864f7c89932ed795d")) or v:IsA(__S("14e7ae7fc24a246d87f519d8")) or v:IsA(__S("b31f2830f27eea29e608422bd16a32")) or v:IsA(__S("5156a1e18724f29a234ee22191ce0f"))) then
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
            if obj:IsA(__S("ef8e1b922eb195624fa5b5b8")) and obj.Name:lower():find(__S("8dc595432619a3bc"), 1, true) then
                table.insert(parts, obj)
            end
        end
    end)
    cachedSafeParts, safeCacheStamp = parts, os.clock()
    return parts
end

local function isInsideSafeZone(char)
    if not char then return false end
    local root = char:FindFirstChild(__S("2bfd0ef40de924a79c05e403e837c015b0d4b5f7")) or char:FindFirstChild(__S("ca3488a5c0ccbf32f8277f24d6ba")) or char:FindFirstChild(__S("686c0256b17cec6e01"))
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
    if not plr then return false, __S("06a37c0703161bfab3bf00"), grey end
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass(__S("a4daf5b806c10cd8fb2ab211"))
    if not char or not hum then return false, __S("43126f699abff08e6a267e52d5e2e56a4b66"), grey end
    if hum.Health <= 0 then return false, __S("e149e91a8b7f01f5"), grey end

    if char:FindFirstChild(__S("7f8162cb819ad483c02144b04a2d")) then
        return false, __S("1db8dc7cd4b0e94d4b74807977837e85368b457f7d1c"), blue
    end

                                      
    local flag, flagName = findPvpFlag(char)
    if not flag then flag, flagName = findPvpFlag(plr:FindFirstChild(__S("bbf0562d13334b35"))) end
    if not flag then flag, flagName = findPvpFlag(plr) end
    if not flag then
                                                                              
                                                                               
                                                                              
        local playerGui = plr:FindFirstChild(__S("5a27cfde60f4804ebb51794fbb"))
        local main = playerGui and playerGui:FindFirstChild(__S("f85f498f75a7a6a7"))
        if main then flag, flagName = findPvpFlag(main) end
    end
    if flag then
        if flag.Value == true then return true, __S("9696c3408f4540576100d1b5953e") .. tostring(flagName), red end
        if flag.Value == false then return false, __S("34ce3cf1296614a0997b28d8685a37") .. tostring(flagName), green end
    end

                                                                               
    for _, attr in ipairs({ __S("d305b6a25ab843"), __S("713d305398faf5"), __S("0f74aa048e590ef12b9ac3699092"), __S("adac23b5119780d253") }) do
        local v = (pcall(function() return plr:GetAttribute(attr) end)) and plr:GetAttribute(attr) or nil
        if v ~= nil then
            return v and true or false, (v and __S("4be39d6631f219713210549ce3f39ab95e28") or __S("ea1b17175bdacb059d2782301ce942de1cb84a")), (v and red or green)
        end
    end

    if isInsideSafeZone(char) then return false, __S("885290c81ef2ce2e95a7be4295"), blue end

                                                                                    
                                                          
    return true, __S("268a0a79ab51cdecadd6e61ea79b15e9e09f990772c4464553419bf2cfa2c5"), red
end

local function canAttackPlayer(plr)
    local ok = getPvPStatus(plr)
    return ok
end

local function getPlayerBounty(plr)
    local data = plr and plr:FindFirstChild(__S("c4c1842a4cd0b073"))
    if data then
        for _, n in ipairs({ __S("62f8fddb784d44901c3f"), __S("0130778cae02b8749219e3d5495edf"), __S("9f67f13d7fd75afef0fd2bf6a0600eb3") }) do
            local v = data:FindFirstChild(n)
            if v and v:IsA(__S("3d9f6aee39f5999f52ee90086c")) then return tostring(v.Value) end
        end
    end
    return __S("dbd6e49fb0")
end

                                                                      
local function getPlayerLoadout(plr)
    local out = {
        fruit = __S("7a0e5e50bcd0fe64"), style = __S("1845d801806857064446"), sword = __S("b67d51b25a"), gun = __S("54b4cb6342"),
        level = __S("f2ec45146c"), bounty = __S("9123bec595"), total = __S("2f5b3876f1"), hp = 0, maxHp = 0,
    }
    if not plr then return out end
    local data = plr:FindFirstChild(__S("cd92b2270883b2dc"))
    local function readData(...)
        if not data then return nil end
        for _, n in ipairs({ ... }) do
            local v = data:FindFirstChild(n)
            if v and v:IsA(__S("6bca2bd8d602e1e2a3db1d094b")) then return tostring(v.Value) end
        end
        return nil
    end
    out.level  = readData(__S("0a01a589bd2a89946e")) or __S("a8391f3a4a")
    out.bounty = getPlayerBounty(plr)
    out.total  = readData(__S("467098ebbf4c602d")) or __S("e4a8129cec")
    out.fruit  = readData(__S("82df8c4d62db79b251f7072afc3d"), __S("211705fe2c00cfa64c"), __S("bf4e7faff66b11656cc128c16695af202ecf24")) or __S("5d85f960fa9c60b8")

    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass(__S("fbbd73117690b2e630e73207"))
    if hum then
        out.hp = math.floor(hum.Health)
        out.maxHp = math.floor(hum.MaxHealth)
    end

    for _, container in ipairs({ char, plr:FindFirstChild(__S("99f4ecc2360eab6aed5bd495")) }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA(__S("382c667316fdcdc2")) then
                    local isFruit = toolMatchesCategory(tool, __S("d663e024b5a4658c1fdb7e1944ee"))
                    if isFruit and (out.fruit == __S("749b59d5eb6ff271") or out.fruit == "") then
                        out.fruit = tool.Name
                    elseif isMeleeTool(tool) and out.style == __S("12d2d3867439ab4f2bde") then
                        out.style = tool.Name
                    elseif toolMatchesCategory(tool, __S("b10a4d3712b97e505b")) and out.sword == __S("4f41c6e8cb") then
                        out.sword = tool.Name
                    elseif toolMatchesCategory(tool, __S("ed794099ebd6c5")) and out.gun == __S("8bb0ba4adb") then
                        out.gun = tool.Name
                    end
                end
            end
        end
    end
    out.fruit = tostring(out.fruit):gsub(__S("29e833fb106aed636ec4"), "")
    out.style = tostring(out.style):gsub(__S("c81fadac79ec961ab86b"), "")
    return out
end

local function getPlayerByName(query)
    if not query or query == "" then return nil end
    local q = tostring(query):lower():gsub(__S("6657275d3d529397"), ""):gsub(__S("048ea10e5caa3f9b"), "")
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

    local enemiesFolder = Workspace:FindFirstChild(__S("a2c61abfd224b253e957a3"))
    if enemiesFolder then
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            local hum = mob:FindFirstChildOfClass(__S("40fd9470215d430514252fb4"))
            local hrp = mob:FindFirstChild(__S("df350e213122a6e2e6f149d486e99fea42bb2235"))
            local head = mob:FindFirstChild(__S("7d6c87d2719fbed5")) or hrp
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
        local charsFolder = Workspace:FindFirstChild(__S("1ba401832a3fb30d64f46e7f827b"))
        local list = charsFolder and charsFolder:GetChildren() or Players:GetPlayers()
        for _, entry in ipairs(list) do
            local char = entry:IsA(__S("b9db7b347af398e61eec")) and entry.Character or entry
            if char and char ~= LocalPlayer.Character then
                local hum = char:FindFirstChildOfClass(__S("5812f4e5aacbb85738e5610f"))
                local hrp = char:FindFirstChild(__S("f64a6e9652ad87b5876828e8f4e8af63eef70b84"))
                local head = char:FindFirstChild(__S("9481e847ab99d15f")) or hrp
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
            local pScripts = LocalPlayer:FindFirstChild(__S("32b961f88b6f22be7abdfb270d960a7bba"))
            local cfScript = pScripts and pScripts:FindFirstChild(__S("d0f0dba948cfccbb6352886a0d5c9133dc8457"))
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
        SkillHubStep(__S("6f28555a96c6226dcefcd43f9b9a2b039e"), function()
            local modules = ReplicatedStorage:FindFirstChild(__S("0d5fcf0b9994f78e854687"))
            local net = modules and modules:FindFirstChild(__S("ab9748bc329067"))
            if net then
                local regAtk = net:FindFirstChild(__S("49cec26d7ec847980d50da9f9d631d72a13982db04"))
                local regHit = net:FindFirstChild(__S("e8063c1e0e20a2a93c8adc65880146d96f78"))
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
                local rem = ReplicatedStorage:FindFirstChild(__S("863db5cf7fa007c97e932484d530e03044f7786818fa"))
                local validator = ReplicatedStorage:FindFirstChild(__S("24752f805043b4887bf1c2"))
                    and ReplicatedStorage.Remotes:FindFirstChild(__S("c2aca931223d89f454c8023a10"))
                if validator and ac.blades and ac.blades[1] then
                    SkillHubStep(__S("60e422e213354fb4948b7af1997dce1d38"), function()
                        ac:attack()
                    end)
                end
                if rem then
                    local tool = char:FindFirstChildOfClass(__S("ff1b9c9363e446f7"))
                    if tool then
                        rem:FireServer(__S("9d531644fe35c4b554727e5532d0e8cf"), tostring(tool.Name))
                    end
                    rem:FireServer(__S("3b8a8ff547cf0d"), rawParts, 3, "")
                end
            end
        end
    end)

                                                            
    pcall(function()
        local equippedTool = char:FindFirstChildOfClass(__S("d9c209a629c6d39f"))
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
        SkillHubStep(__S("77f9835733379d4b922f75d03408599b18"), function()
            if os.clock() < RespawnQuietUntil then return end
            local isFarming = Config.AutoFarmLevel or Config.AutoFarmNearest or Config.AutoFarmBoss or Config.AutoFarmAllBosses
            if (isFarming and Config.FastAttack) or Config.AutoAttackAlways then
                if (os.clock() - (lastAttackTrace or 0)) > 2 then
                    lastAttackTrace = os.clock()
                    trace(__S("1630fd08a60a0e515009b012f27c0915dd6225b4f1"))
                end
                triggerFastAttack()
            end
        end)
    end
end)

local function ensureBuso()
    if not Config.AutoBuso then return end
    local char = getCharacter()
    if char and not char:FindFirstChild(__S("b46876b96efaa661e536e2")) then
        invokeCommF(__S("529ff06a0175a32b"))
    end
end

local function bringNearbyMobs(targetName, targetPos)
    if not Config.BringMobs then return end
    local enemies = Workspace:FindFirstChild(__S("f0d76a1bb47adf52b675c0"))
    if not enemies then return end
    for _, mob in ipairs(enemies:GetChildren()) do
        if not targetName or mob.Name == targetName then
            local hrp = mob:FindFirstChild(__S("8f0ee3ccdf4430efaaa3162f8d163613b6364c75"))
            local hum = mob:FindFirstChildOfClass(__S("2d465d7d61a21ed4b78444ad"))
            if hrp and hum and hum.Health > 0 and (hrp.Position - targetPos).Magnitude <= 350 then
                SkillHubStep(__S("cb7dd72ecf776486829c07fd5ba184fc7d"), function()
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
                        local anim = hum:FindFirstChildOfClass(__S("69b550df491c787cce462a05"))
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

                                                                              
                                                                                 
                                                                                  
                                                                               
                                                                                  
                                                            

local GIANT_MARKER_NAMES = { __S("07ecca906d6f53e4bb09"), __S("a6244441b52c5c396e1b24636dfb"), __S("445bbdf2470592c8e83b6cd2c9"), __S("e29337a3c4b9428c75e043f72001357ac3b9"), __S("80cab154e332eab5f7"), __S("1f022b05f64d09711e9b68") }

local function getCharBoundingBox(char)
    if not char then return nil, nil end
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if ok and cf and size then return cf, size end
    local hrp = char:FindFirstChild(__S("bd39a4b609d5f05f5910cbca10c3da9f5dbef777"))
    if hrp then return hrp.CFrame, hrp.Size end
    return nil, nil
end

local giantCache = {}
local function computeGiantForm(char)
    local hum = char:FindFirstChildOfClass(__S("5b711e6751ffc02a4eb46ba3"))
    if hum and (tonumber(hum.HipHeight) or 0) > 6 then return true end
    local ok, size = pcall(function() return char:GetExtentsSize() end)
    if ok and size and size.Y > 11 then return true end
    for _, marker in ipairs(GIANT_MARKER_NAMES) do
        if char:FindFirstChild(marker) then return true end
    end
    for _, attr in ipairs({ __S("f9a89818af3dd07034f9"), __S("97e011c9c2af740e6d"), __S("36178b7a5242e7aba53a90409824d1"), __S("d44f052bd7d6a6f982a4fd") }) do
        local v = char:GetAttribute(attr)
        if type(v) == __S("72867edc506a12b642a816") and v then return true end
    end
    local scale = char:GetAttribute(__S("10bdf88d68cd5f699e")) or char:GetAttribute(__S("aef5723ed4d4a35c"))
    if type(scale) == __S("4d2cebef49be7a6e5159") and scale > 1.6 then return true end
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
    local data = plr:FindFirstChild(__S("eb6465a00c1004ae"))
    local fruit = data and data:FindFirstChild(__S("899bdf510d183aee28e1e5bc64cb"))
    if fruit and tostring(fruit.Value):lower():find(__S("27d35902792503046107"), 1, true) then return true end
    for _, container in ipairs({ plr.Character, plr:FindFirstChild(__S("c60ad2b37fae4dd05cde36a1")) }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA(__S("64424c64b7c839bd")) then
                    local original = tostring(tool:GetAttribute(__S("0279c615073423c577a371bcebb3693f")) or ""):lower()
                    if original:find(__S("a0b13fc6408a9b53171e"), 1, true) or tool.Name:lower():find(__S("3ee8b9777657623778d5"), 1, true) then return true end
                end
            end
        end
    end
    return false
end

local function getCharacterCombatParts(char)
    if not char or char == LocalPlayer.Character then return nil end
    local hum = char:FindFirstChildOfClass(__S("dd2033288294f6383d6fd1e0"))
    local hrp = char:FindFirstChild(__S("7b57acd91745b3c2a01d59c1b5a6751ddcde9325"))
    local head = char:FindFirstChild(__S("198f268acd06de2d")) or hrp
    if not hum or not hrp or not head or hum.Health <= 0 then return nil end
    return { char = char, hum = hum, hrp = hrp, head = head }
end

local function castCombatSkills(inRange)
    if inRange == false then return end
    local now = os.clock()
    if now - (PvPState.lastSkill or 0) < math.clamp(Config.PvPSkillInterval or 0.4, 0.15, 1) then return end
    PvPState.lastSkill = now
    for _, key in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V }) do
        SkillHubStep(__S("b7c6a03bd66e1fd421c4594099795a2b33"), function()
            pressKey(key, 0.05)
            task.wait(0.05)
        end)
    end
end

                                                                             
local function buildAttackPayload(char)
    local hum = char and char:FindFirstChildOfClass(__S("55fe19ec6556639fa4ac2857"))
    local hrp = char and char:FindFirstChild(__S("f435939d365e5de6268663e415e34d508287b37f"))
    if not hum or not hrp or hum.Health <= 0 then return nil end

    local head = char:FindFirstChild(__S("926d0d4e64d41e2d")) or hrp
    local giant = Config.BuddhaAwareCombat ~= false and isGiantForm(char)
    local bbox, size = getCharBoundingBox(char)

    local bladeHits, rawParts, seen = {}, {}, {}
    local function addPart(part)
        if part and part:IsA(__S("30a486ffc005ddf5f0203a6b")) and not seen[part] then
            seen[part] = true
            table.insert(bladeHits, { char, part })
            table.insert(rawParts, part)
        end
    end

    if giant then
                                                                                  
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA(__S("cedc00b037a45f2e2dd858b4")) then addPart(d) end
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
        if d:IsA(__S("6d137a61cc9d8b2b30aa270a")) then
            store.parts[d] = { size = d.Size, transparency = d.Transparency, collide = d.CanCollide, massless = d.Massless }
            table.insert(store.order, d)
        end
    end
    PvPState.hitboxOriginals[key] = store
    return store
end

local function setPlayerHitbox(plr, expand)
    local char = plr and plr.Character
    local hrp = char and char:FindFirstChild(__S("0b4af4127e2df2adf4fa6013d6945b264dfc5ba1"))
    if not hrp then return end
    local key = plr.Name

    if expand then
        local store = storeHitboxState(key, char)
        local target = math.clamp(Config.PlayerHitboxSize or 14, 4, 200)
        local factor = math.min(target / math.max(hrp.Size.X, 0.5), Config.HitboxWholeModel ~= false and 4 or 1)
        SkillHubStep(__S("a9826dc37324a162dfebc6b05c3fa0c23e"), function()
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
            SkillHubStep(__S("47b9e77452d31775ea44782010171890ce"), function()
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
    mode = mode or Config.PvPTargetMode or __S("e5f161256198782511b6f3")
    local best, bestDist, bestScore = nil, math.huge, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local info = getCharacterCombatParts(plr.Character)
            if info and canAttackPlayer(plr) and not isFriend(plr) then
                local dist = (info.hrp.Position - myRoot.Position).Magnitude
                local score = dist
                if mode == __S("8428dad6c394850b263208d6ac") then
                    local hum = plr.Character and plr.Character:FindFirstChildOfClass(__S("22605487576983660cf1c1e9"))
                    score = (hum and hum.Health) or math.huge
                elseif mode == __S("c097ce38c7d9b08f4ddaaf") then
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
    local hum = char and char:FindFirstChildOfClass(__S("5ecf47e9b83045f00f3c49b1"))
    if hum then
        if not SpectateState.active then
            SpectateState.originalType = cam.CameraType
            SpectateState.originalSubject = cam.CameraSubject
            SpectateState.active = true
        end
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    elseif SpectateState.active then
        SkillHubStep(__S("fd06c19a6df2ecd4f25ec457b4bc19a8b0"), function()
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
        SkillHubStep(__S("9b3e3b4b0d8b3df2cc0773279b5e2a5616"), function()
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
                            if myChar and not myChar:FindFirstChildOfClass(__S("3975b4fc7d162544")) then
                                PvPState.lastEquip = now
                                SkillHubStep(__S("d7ad2eadc18b4f504b84a3e06eed5559d5eed2b6"), function() equipWeaponByType(Config.SelectedWeaponType) end)
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
                        SkillHubStep(__S("75e4a85e79c992c156ba05d80c6253ec"), function() aimCameraAt(target) end)
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
        SkillHubStep(__S("141c220f6c9699cb85e8c9603dfd8414b0"), function()
            local enemies = Workspace:FindFirstChild(__S("b2539bc0b0ae3c2bb2efb5"))
            if not enemies then return end
            local root = getRoot()
            local size = math.clamp(Config.HitboxMobsSize or 55, 6, 200)
            local range = Config.HitboxMobsRange or 420

            for _, mob in ipairs(enemies:GetChildren()) do
                local hum = mob:FindFirstChildOfClass(__S("508b15714b56538d20218309"))
                local hrp = mob:FindFirstChild(__S("eec28f22d937c434d5592b35c4c7479ad97e15a1"))
                if hum and hrp and hum.Health > 0 and hrp.Parent then
                    local inRange = (not root) or (hrp.Position - root.Position).Magnitude <= range
                    if Config.HitboxMobs and inRange then
                        local store = MobHitboxStore[mob]
                        if not store then
                            store = { parts = {}, order = {}, baseSize = math.max(hrp.Size.X, 0.5) }
                            for _, d in ipairs(mob:GetDescendants()) do
                                if d:IsA(__S("8cfa08d3019607fde045cc18")) then
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
    if type(method) ~= __S("2b318284c71b75306625") or not HANDLED_METHODS[method] then return nil end
    HookRegistry.hits = (HookRegistry.hits or 0) + 1

                                    
    if method == __S("c968fc3549cfb229") or method == __S("67a075e60381b9d5") then
        if self == LocalPlayer then return BLOCK_RESULT end
        return nil
    end

                                                               
    if Config.BypassAntiCheat and (method == __S("05d7ef97637bd89fb034ef1c6439") or method == __S("a40f6948f2a95c235a663f5b2780b8fe")) then
        if isSuspiciousRemote(self) then return BLOCK_RESULT end
    end

                                                                              
    if Config.AimLock and PvPState.target
        and (method == __S("4246e2f9131db7e7a3cd40d98bc99f2282ace8b4916d1f7f99660c645c2553") or method == __S("e07e5caaf998b2876da6da429aa1a1548a") or method == __S("7eb5d65bb6d96d514cd1e8")) then
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
            if method == __S("1ced500c7c4eeab44b9adddfc3be4f085bb9c47f78f4d5304e5f0500bbe17d") and args[1] then
                local dir = aimPos - args[1].Origin
                if dir.Magnitude > 0.1 then
                    return true, { Ray.new(args[1].Origin, dir.Unit * math.clamp(dir.Magnitude + 8, 1, 600)), args[2], select(3, ...) }
                end
            elseif method == __S("bb24c9bd72a0afc8e26d2529b3d987442e") and args[1] then
                local dir = aimPos - args[1].Origin
                if dir.Magnitude > 0.1 then
                    return true, { Ray.new(args[1].Origin, dir.Unit * math.clamp(dir.Magnitude + 8, 1, 600)), select(2, ...) }
                end
            elseif method == __S("595c436e64e231bb1d63a9") and args[1] and args[2] then
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
        if flag == true and type(payload) == __S("f793bd1f934185afee") then
            local okCall, res = pcall(function() return originalNamecall(self, table.unpack(payload)) end)
            if okCall then return res end
        end
    end

    if type(originalNamecall) == __S("95cb36d03ed4c2ef0016de0e") then
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
        if okWrap and type(wrapped) == __S("3402b081eeb6647c587c63ca") then replacement = wrapped end
    end

    local ok, old = pcall(function()
        return hookmetamethod(game, __S("d23a2a32532fefec804a73062dcd"), replacement)
    end)
    if ok and type(old) == __S("7071a3e3231c4d1ee627dc77") then
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
        local pad = Instance.new(__S("0ea91d94690ed752"))
        pad.Name = __S("ace09745322e8e7dc4f40ab5625cbf95acff4c21566ac9873ea2")
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
        local bg = Instance.new(__S("4b1810f6977beed2fa7fa4f3"))
        bg.Name = __S("e94f8aa7b9e40329e195d658081a99ce1e831e")
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
        local bv = Instance.new(__S("878704585cb50124657cc4a2bffc01f8"))
        bv.Name = __S("25be7e09a50fc6725c8af7dfbfa1cd1a7a59069ce63794")
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
        SkillHubStep(__S("c3f5f7ba369674fd04e292a7837511d414"), function()
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
        SkillHubStep(__S("622d716b664d5b3b74f83fc1af5384522b"), function()
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
        Hooks.notify(__S("0064eb1c39a5ef67c32c3f3ae4a4"), __S("9e9c64cd673cd9f535fe1fef745f716c9413211bee135b5b7519031e30b7fd3f5bebacc95a6634688acbdf33e7bdcaa890776abc1390e5ce3330e04e263554e3ffe2d869"), 3.5, CustomIcons.Stop)
    else
        Hooks.notify(__S("3cd3de7eb6ae4b"), __S("db0b582f78929c19f29f52ab7575c59b9c1765cd117469c4fadde18e48d6db9e8356b38d402dfddd811c0bae38169ac209f83851ac385d76a9ce9b88f58c"), 2.5, CustomIcons.Fly)
    end
end

local function flyEnable()
    if Fly.active then return end
    Fly.active = true
    Fly.parked = false
    Fly.manualHold = 0
                                                                                  
                                                                 
    SkillHubStep(__S("7942d1e0d9dbcb589eef0cdbd9dd"), function() stopTween() end)
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
        Hooks.notify(__S("177a4b916078f3fd33290e23f22268b695a3"), __S("b5b1c542481267ee665bb3cabe18c408ab417ca6fd13726377e9fafb65fa4d22cd62a1d76b9f2f76d89f40a704d54b02cf8228d95c715b66ed90a13255ff5a0c12350d3f4a5ad3aee732c2f33722ca7d16c5d3d1fb7442abcd1132490404"), 4, CustomIcons.Fly)
    else
        flyDisable()
        Hooks.notify(__S("53e93ef3bd15c0671bddedeeab30e0104b07"), __S("f220b8a4b873fdbb56d0d5"), 2, CustomIcons.Stop)
    end
end

                                     
task.spawn(function()
    while task.wait(0.12) do
        SkillHubStep(__S("90583255b11406aff0c268204d219e9808"), function()
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
        SkillHubStep(__S("2e8fac06cc2d5fe76cabc060ce4f0804f1"), function()
            pressKey(Enum.KeyCode.Space, 0.05)
            task.wait(0.05)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 68, root.AssemblyLinearVelocity.Z)
        end)
    end)
end)

                                                                                          
task.spawn(function()
    while task.wait(0.4) do
        if Config.InfiniteEnergy then
            SkillHubStep(__S("ccc725b702ad88df3b69f1ef80a17e5d03"), function()
                local data = LocalPlayer:FindFirstChild(__S("6afe9f6885e9e398"))
                if data then
                    for _, n in ipairs({ __S("0936191936c595c590df"), __S("a76d92ca1d8339958112069c6d"), __S("45a50c7bef555dbe86903dd5f771") }) do
                        local v = data:FindFirstChild(n)
                        if v and v:IsA(__S("e3dc862ceed03dac76c99b14c1fd24")) then v.Value = 1000000 end
                    end
                end
                local char = getCharacter()
                local energy = char and char:FindFirstChild(__S("8213ffdd4cb1651c514d"))
                if energy and energy:IsA(__S("204b798e1df791743095f0de6991a6")) then energy.Value = 1000000 end
                if Config.InfiniteEnergy then
                    invokeCommF(__S("be82f33faff29a2b"))
                    if Config.AutoKen then invokeCommF(__S("5cba6cf06991e8"), true) end
                end
            end)
        end
    end
end)

                        
task.spawn(function()
    local lastDash = 0
    while task.wait(0.05) do
        SkillHubStep(__S("faf1e6a1be07da3821af41c1e3ac64310d"), function()
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
            SkillHubStep(__S("99296052ceae96d0d553c0b7f4a356ca52"), function()
                local rem = ReplicatedStorage:FindFirstChild(__S("3760da03212b9e6055cfcf"))
                local commE = rem and rem:FindFirstChild(__S("d59853b460b2c6fa54"))
                if commE then commE:FireServer(__S("73cfcd6590db46ba")) end
            end)
        end)
    end
end)

                                                                              
                                                                                    
                                                                              

local function magnetPart(handle, tweenFallback)
    local root = getRoot()
    if not handle or not root then return end
    if firetouchinterest then
        SkillHubStep(__S("1207471689262dea18c84c6b84bfc70f36"), function()
            firetouchinterest(root, handle, 0)
            firetouchinterest(root, handle, 1)
        end)
        SkillHubStep(__S("b03ec0c739c210f80d622cfd9d9a9c8319"), function()
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
        if obj:IsA(__S("4e763a7830068c76")) or obj:IsA(__S("ecadb429d0e4258f16")) or obj.Name:lower():find(__S("8ae52ddab3a2237b7f"), 1, true) then
            local handle = obj:FindFirstChild(__S("291ca78b951e43491a6e")) or obj:FindFirstChildWhichIsA(__S("c754213c6707114607434191"))
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
            SkillHubStep(__S("658b9aed2b7b842c671eb3708e31067df1"), function()
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
            SkillHubStep(__S("03c3149e9bfeda697991172db6b55d5dfd"), function()
                local root = getRoot()
                if not root then return end
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA(__S("a1fa8e4fc2f86771")) then
                        local handle = obj:FindFirstChild(__S("40320800f1babbb720da"))
                        if handle and (handle.Position - root.Position).Magnitude <= 900 then magnetPart(handle, false) end
                    elseif obj:IsA(__S("de6981b113961d0961")) then
                        local name = obj.Name:lower()
                        if name:find(__S("7ca0fb6260b84769"), 1, true) or name:find(__S("1ad875139c39ca8956a1"), 1, true) or name:find(__S("b90feec42c2ced461f"), 1, true) then
                            local handle = obj:FindFirstChildWhichIsA(__S("57476875333a325434b424d1"))
                            if handle and (handle.Position - root.Position).Magnitude <= 250 then magnetPart(handle, false) end
                        end
                    end
                end
            end)
        end
    end
end)

                                                                              
                                                                       
                                                                              

                                                                               
                                                                               
                                                                                
                                                                           
                                                                              
                                                        
                                                  
                                                                          
                                                                               
                                          
local watchedContainers = {}
local FRUIT_SEEN = setmetatable({}, { __mode = __S("f57ee226b0") })
local FRUIT_LAST_NAME = {}
local FRUIT_LAST_REMOVED = {}
local FRUIT_REPEAT_WINDOW = 60
local FRUIT_MOVE_WINDOW = 8

local function fruitToolName(tool)
    local original = tool:GetAttribute(__S("93b65bd7deb54487588730f3acf34dc8"))
    local name = tostring(original or tool.Name or __S("31edd588d9"))
    name = name:gsub(__S("d0254f39f8f75105175c"), "")
    name = name:gsub(__S("6e5cc8ea5490b8ca"), ""):gsub(__S("0c94429bdd21b2a7"), "")
    return name
end

local function isFruitTool(tool)
    if not tool or not tool:IsA(__S("aacbbc4c19f2125b")) then return false end
    if tool:GetAttribute(__S("490335fd0c63034004bf1c3aa735e5df")) ~= nil then return true end
    if tool:GetAttribute(__S("e73aafaea0906b76a0eecc")) == true then return true end
    if tool:FindFirstChild(__S("8572295f5b355494f6da")) == nil then return false end
    if toolMatchesCategory(tool, __S("23a9a31017e342eb92defb4d573c")) then return true end
    if FRUIT_RARITY_OF[tool.Name] ~= nil then return true end
    return tool.Name:lower():find(__S("c1e11cc13ba28535ba"), 1, true) ~= nil
end

                                                    
local function announceFruit(tool, containerLabel)
    local name = fruitToolName(tool)
    local now = os.clock()
    local known = FRUIT_SEEN[tool] == true
    FRUIT_SEEN[tool] = true
    if known then return false end
    if containerLabel ~= __S("601896727b7e0beb0cfcefe8") then return false end
    if FRUIT_LAST_REMOVED[name] and (now - FRUIT_LAST_REMOVED[name]) < FRUIT_MOVE_WINDOW then return false end
    local previous = FRUIT_LAST_NAME[name]
    if previous and (now - previous) < FRUIT_REPEAT_WINDOW then return false end
    FRUIT_LAST_NAME[name] = now
    Config.RolledFruitName = name
    if Config.FruitNotify == false then return true end
    Hooks.notify(__S("fe5010236fe39dadfb5bcaf75e0c6b067697"), name .. __S("9c8789d46ae3398db2878c45050df851b00974") .. getFruitTier(name).name, 4, CustomIcons.Fruits)
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
            if Config.AutoStoreRolled and Config.AutoStoreFruits ~= false and label == __S("3abf0385e012c18093002b98") then
                local fruitName = fruitToolName(tool)
                local code = FRUIT_STORE_CODES[fruitName] or (fruitName .. __S("d8f67d3673") .. fruitName)
                task.wait(0.35)
                invokeCommF(__S("772df6e7ac9b73ff6946ffe9bcd1"), code, tool)
            end
        end)
    end)
    container.ChildRemoved:Connect(function(tool)
        if tool and tool:IsA(__S("1565709817a17bf7")) then
            FRUIT_LAST_REMOVED[fruitToolName(tool)] = os.clock()
        end
    end)
end

local function bindAllFruitWatchers()
    bindFruitWatcher(LocalPlayer:FindFirstChild(__S("b39cea4901816ef6c7ee4314")), __S("51d463fa8d033bc88a0f2b2d"))
    bindFruitWatcher(LocalPlayer.Character, __S("f00bddabb7a308a6d42db23c5a"))
end
bindAllFruitWatchers()
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    bindFruitWatcher(LocalPlayer:FindFirstChild(__S("8e43575c4a37d9d0a6799964")), __S("2c7ad10d625a77d38acbfb5a"))
    bindFruitWatcher(char, __S("cab24abe8fe67479c677d12832"))
end)

                                                                              
                                                      
                                                                              

local function scanSeaEvents()
    local myRoot = getRoot()
    local found = {}
    local scanRoots = {}
    for _, child in ipairs(Workspace:GetChildren()) do table.insert(scanRoots, child) end
    for _, folderName in ipairs({ __S("68e9c46fb89e221cabb8aa"), __S("07213e20517b992e434c7f9d684b"), __S("a558b7d14eed7d9b"), __S("439031825ff789"), __S("e1c7ab334a0c35dc907eaf"), __S("7fff24e4aab27303ab42f4f9e8010c57") }) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then table.insert(scanRoots, folder) end
    end

    local visited = {}
    local function inspect(obj)
        if visited[obj] then return end
        visited[obj] = true
        local name = obj.Name
        if type(name) ~= __S("1e369e95f40c8d0462e4") or #name < 4 then return end
        local lower = name:lower()
        for _, sig in ipairs(SEA_EVENT_SIGNATURES) do
            for _, key in ipairs(sig.Keys) do
                if lower:find(key, 1, true) then
                    local part = obj:IsA(__S("bc6e184617dcc0e2f390067e")) and obj or obj:FindFirstChildWhichIsA(__S("5aa591f7b849b0712b51f8dd"))
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
        SkillHubStep(__S("f8dd0ba891e48e7fbfa9a16ad1be83a9f9"), function()
            if not Config.SeaEventTracker and not Config.MirageFinder then return end
            local events = scanSeaEvents()
            SeaEventState.events = events
            local mirage = {}
            for _, ev in ipairs(events) do
                if ev.name == __S("971485590b8e95dd77b45e913bb62c2d61") or ev.name == __S("354bff0af431ac440fa8122a2bd427d28d94") or ev.name == __S("d38378bb937e8b6c74d4c7fcbae30af3d8c315cc7a22") or ev.name == __S("71baf26c275fb6e6ea2f54e69db726ae8c6478fa1505") then
                    table.insert(mirage, ev)
                end
            end
            SeaEventState.mirage = mirage

            if Config.SeaEventTracker then
                for _, ev in ipairs(events) do
                    local key = ev.name .. math.floor(ev.pos.X / 500) .. math.floor(ev.pos.Z / 500)
                    if not SeaEventState.lastNotify[key] then
                        SeaEventState.lastNotify[key] = true
                        local isSpecial = ev.name ~= __S("0ff26c1dc62ed8a8625600a35e6184d585279fa4")
                        if isSpecial or Config.MirageFinder then
                            Hooks.notify(ev.name .. __S("ae29e5ce662817410b45612f17"), string.format(__S("4c615f7f9dc8d04a528a6e160c17c6b20eb083403021109e44eb1b760786bd40"), ev.dist, ev.pos.X, ev.pos.Z), 4, CustomIcons.Teleport)
                        end
                    end
                end
            end
        end)
    end
end)

                                                                              
                                                              
                                                                              

local function getServerStatus()
    local ping = 0
    pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem[__S("ea98d9304bdbf3edfed4e6ea99")]:GetValue()) end)
    local region = __S("88d052e178")
    pcall(function() region = tostring(game:GetService(__S("2707cc92940e85dec174782b74298bdb6a0542c3c1315d")).RobloxLocaleId) end)
    return {
        jobId = (game.JobId ~= "" and game.JobId:sub(1, 8)) or __S("c53f4643e8790493187da4"),
        players = #Players:GetPlayers(),
        maxPlayers = Players.MaxPlayers,
        ping = ping,
        region = region,
        sea = CURRENT_SEA,
        source = SEA_DETECT_SOURCE,
        events = #(SeaEventState.events or {}),
        up = math.floor(time() - (game:GetService(__S("6376bff4e21c409bc391b35d6ef4")):IsStudio() and time() or 0)),
    }
end

                                                                                      
task.spawn(function()
    for _ = 1, 40 do
        task.wait(1.5)
        SkillHubStep(__S("01ae39a585951156483ce1e946119a1c11"), function()
            local before = CURRENT_SEA
            refreshSea()
            if CURRENT_SEA ~= before then
                LocalPlayer:SetAttribute(__S("9fe5b356e2d01b9bd8f04e98a7aef2"), CURRENT_SEA)
            else
                LocalPlayer:SetAttribute(__S("3e1d2d07aa2bfdf1208bf7253f5cd5"), CURRENT_SEA)
            end
        end)
    end
end)

                                                                              
                            
                                                                              

task.spawn(function()
    while task.wait(0.12) do
        SkillHubStep(__S("dc54a6b8b4bce340e9683a17663c6e84a7"), function()
            local char = getCharacter()
            local root = getRoot()
            local hum  = getHumanoid()
            if not char or not root or not hum or hum.Health <= 0 then return end

            if Config.AutoFarmLevel then
                ensureBuso()
                equipWeaponByType(Config.SelectedWeaponType)
                local qData = getQuestForLevel(getPlayerLevel())
                local pGui = LocalPlayer:FindFirstChild(__S("7a8c2069595227af24a97eee35"))
                local mainGui = pGui and pGui:FindFirstChild(__S("18c39a1ad7dc28ce"))
                local questFrame = mainGui and mainGui:FindFirstChild(__S("b6fb13cb9b93048bbf"))

                if questFrame and not questFrame.Visible then
                    tweenTo(qData.QPos)
                    if (root.Position - qData.QPos.Position).Magnitude < 20 then
                        invokeCommF(__S("55328d7c216f484a2003122f66fc"), qData.Quest, qData.QNum)
                    end
                else
                    local enemies = Workspace:FindFirstChild(__S("f36a072defc6c53bb67fe0"))
                    local targetMob = nil
                    if enemies then
                        for _, mob in ipairs(enemies:GetChildren()) do
                            local mHum = mob:FindFirstChildOfClass(__S("91a180de2b4c9ee175f456da"))
                            local mHrp = mob:FindFirstChild(__S("2fd8fa8fe31003274d96676c7b9876723b7bc668"))
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
                local enemies = Workspace:FindFirstChild(__S("ce107440c9575f5e78b1f6"))
                local nearest, minDist = nil, math.huge
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mHum = mob:FindFirstChildOfClass(__S("6c47edf1e59692d691a4aa1f"))
                        local mHrp = mob:FindFirstChild(__S("0a7f67a24fe201a019ac175ade8f077b49e7e01b"))
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
                local enemies = Workspace:FindFirstChild(__S("a8b6e153f8bd1623c51131"))
                local targetBoss = nil
                local seaBosses = BOSSES_BY_SEA[CURRENT_SEA] or {}

                local selectedBossName = tostring(Config.SelectedBoss):gsub(__S("46ee5b04fd64c554b974d19310a68b"), "")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mHum = mob:FindFirstChildOfClass(__S("e525d4b5a4dbd5c777a27b73"))
                        local mHrp = mob:FindFirstChild(__S("835d4e66a60446bc6350070487db86ddd612888c"))
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
        SkillHubStep(__S("2194c817b1ccedae3445cf11e323c88f11"), function()
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
                    local spark = Instance.new(__S("bfcc41c8223ba0b1"))
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
        SkillHubStep(__S("5e03bb7942323f43ad3814bd693343a77c"), function()
            local batch = Config.StatPointsBatch
            if Config.AutoStatMelee   then invokeCommF(__S("fc3b352a84e107a49b751012"), __S("9a72aedba2aafc9484"), batch) end
            if Config.AutoStatDefense then invokeCommF(__S("38aa288c30f64ccd01ca8b50"), __S("d6e1a23dea15975faaa897"), batch) end
            if Config.AutoStatSword   then invokeCommF(__S("75191bee1d70a900323cc695"), __S("1350959ffdd55e9410"), batch) end
            if Config.AutoStatGun     then invokeCommF(__S("b1880f5000a50563d827088c"), __S("4fbf8901c9736d"), batch) end
            if Config.AutoStatFruit   then invokeCommF(__S("edf702b263805433fc68de7f"), __S("8c2e7c63b63ad2dc9bfe9f6d434b4c"), batch) end
        end)
    end
end)

                           
task.spawn(function()
    while task.wait(1.2) do
        SkillHubStep(__S("2a65f614ca0ccd8859b75ecd8fba65f3ed"), function()
            if Config.AutoSniperStock then
                invokeCommF(__S("c89d6fc5d046eed0df57e1a48d"))
                invokeCommF(__S("66d4e976bb38a300ddb21eb4e2cd3d7d46177c9e"), Config.SelectedFruit, false)
            end
            if Config.AutoRandomFruit then
                invokeCommF(__S("050c6327b07bc7ccb5c2"), __S("a343dcd876c5d4"))
            end
            if Config.AutoGrabMapFruits then
                local root = getRoot()
                if root then
                    for _, obj in ipairs(Workspace:GetChildren()) do
                        if obj:IsA(__S("417b5689880dd985")) or obj.Name:lower():find(__S("dfb2d03a86dbe1c895")) then
                            local handle = obj:FindFirstChild(__S("7dea49ebc8c1f42ff739"))
                            if handle and handle:IsA(__S("1c21c39c570939cb06be3d7f")) then
                                tweenTo(handle.CFrame)
                                break
                            end
                        end
                    end
                end
            end
            if Config.AutoStoreFruits then
                local containers = {LocalPlayer:FindFirstChild(__S("ba593d4d57f0bc482c8cc6df")), getCharacter()}
                for _, container in ipairs(containers) do
                    if container then
                        for _, tool in ipairs(container:GetChildren()) do
                            if tool:IsA(__S("5890b6fead6bc392")) and tool.Name:find(__S("f6c830afa74969445d")) then
                                local cleanName = tool.Name:gsub(__S("94ffaa60b9e6dd906231"), "")
                                local code = FRUIT_STORE_CODES[cleanName] or (cleanName .. __S("3337241186") .. cleanName)
                                invokeCommF(__S("d16e9dc2da83185fc7f610da0da5"), code, tool)
                            end
                        end
                    end
                end
            end
            if Config.AutoBuyRaidChip then
                invokeCommF(__S("6fa6177365833b6bc36b413f"), __S("0ddd91248b285bb70100"), Config.SelectedRaidChip)
            end
            if Config.AutoAwaken then
                invokeCommF(__S("ac150ad573bb4ef970f5174e"), __S("4a4c8486ab22cd5b97"))
                invokeCommF(__S("e883fe3774e66d1380d70567"), __S("86bb77e8ea758aadd602"))
            end
            if Config.AutoRaidAura then
                local enemies = Workspace:FindFirstChild(__S("24f2f1999cb461ae15b17e"))
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local hum = mob:FindFirstChildOfClass(__S("c32a6b4a43f922e577a8c6b9"))
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
        SkillHubStep(__S("6161e4fbe978be54da9b2593e20685d41e"), function()
            if Config.AutoFarmChests then
                local root = getRoot()
                if root then
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA(__S("ff995eac887a2e1e90b95d2c")) and (v.Name == __S("9dd0d85d73f50f09d61d") or v.Name == __S("3c08520e2978a747691e") or v.Name == __S("da3fcbbf38c3f04534dd")) then
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
            if Config.AutoKen then invokeCommF(__S("78774570d7cc6e"), true) end
            if Config.AutoRaceV3 then
                local rem = ReplicatedStorage:FindFirstChild(__S("16aebf21565b107490a53e"))
                local commE = rem and rem:FindFirstChild(__S("b4e638d2ef33ce9160"))
                if commE then commE:FireServer(__S("531db283c4f24bee74277d5df92920f65ca153")) end
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    if Config.NoClip or Config.AutoFarmLevel or Config.AutoFarmBoss or Config.AutoFarmAllBosses then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA(__S("f1552c34bf72c4fda837156e")) and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if not Config.AntiAFK then return end
    if VirtualUser and Config.UseVirtualInput ~= false then
        SkillHubStep(__S("8f8ca5e5bc56227a3cfc7c9ee73c6389f2004d0249b6e2f51168855a"), function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    else
                                                                           
                                                                            
                                             
        SkillHubStep(__S("2dc41f964c22ea296410ff102d91c39d"), function()
            local char = getCharacter()
            local hrp = char and char:FindFirstChild(__S("cbfb9947a6ae08f86b38f20bc294adc95793354a"))
            local hum = char and char:FindFirstChildOfClass(__S("6a3312f8465cf796280b28e9"))
            if hum and hrp then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 0.05, 0)
            end
        end)
    end
end)

                                                                              
              
                                                                              

local ESPFolder = Instance.new(__S("086a8ca9d057e9300a82"))
ESPFolder.Name = __S("a6a2065afd882af51177f977d2dee49ebce5ac")
                                                                             
pcall(function() ESPFolder.Parent = LocalPlayer:WaitForChild(__S("44d9800bd7a289a3a5c69a8aad")) end)

                                                                               
                                                                               
                                                                                
                                                                              
                                                                    
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

    local bb = Instance.new(__S("e310f9bc0d61860b63c91d8dc566d3fd"))
    bb.Name = __S("8148736d5a96a95e98e3c8")
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 200, 0, height or (bodyText and 72 or 42))
    bb.StudsOffset = Vector3.new(0, 3.6, 0)
    bb.AlwaysOnTop = true
    bb.Parent = ESPFolder

    local mainLbl = Instance.new(__S("1f7fed1e2419d094b68a627c6f"), bb)
    mainLbl.Size = UDim2.new(1, 0, 0, bodyText and 20 or 22)
    mainLbl.BackgroundTransparency = 1
    mainLbl.Font = Enum.Font.GothamBold
    mainLbl.TextSize = 13
    mainLbl.TextColor3 = color
    mainLbl.TextStrokeTransparency = 0.25
    mainLbl.Text = titleText

    local subLbl = Instance.new(__S("bdb766cf2c17d1cdfe498061d2"), bb)
    subLbl.Size = UDim2.new(1, 0, 0, bodyText and 16 or 18)
    subLbl.Position = UDim2.new(0, 0, 0, bodyText and 20 or 23)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.TextSize = 11
    subLbl.TextColor3 = Color3.fromRGB(226, 232, 240)
    subLbl.TextStrokeTransparency = 0.35
    subLbl.Text = subText or ""

    local bodyLbl = Instance.new(__S("5beee080cb4696e2a66ac7332f"), bb)
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
        local ok, created = pcall(function() return Drawing.new(__S("fa265a31edf4c3d7")) end)
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
        SkillHubStep(__S("985dd3e2df30c50efcb1fa48f07fb8fea1"), function()
            local myRoot = getRoot()
            local cam = Workspace.CurrentCamera
            if not myRoot or os.clock() < RespawnQuietUntil then return end

                                                                               
            espStamp = os.clock()
            trace(__S("36954d936516b4bb67244a22"))

            if not Config.ESPTracers then
                for _, line in pairs(tracerCache) do pcall(function() line.Visible = false end) end
            end

                                                                               
            if Config.ESPPlayers then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hrp = plr.Character:FindFirstChild(__S("d4ccc744de6e54f7f210f24450f95a8a86dc8959"))
                        local hum = plr.Character:FindFirstChildOfClass(__S("730440f5306ed2fb4c621b63"))
                        if hrp and hum and hum.Health > 0 then
                            local dist = math.floor((hrp.Position - myRoot.Position).Magnitude)
                            local attackable, statusText, statusColor = getPvPStatus(plr)
                            local loadout = getPlayerLoadout(plr)
                            local title = string.format(__S("113bbaa6949a99b75c7e4335"), plr.DisplayName, tostring(loadout.level))
                            local sub = string.format(__S("af733457ee832871bca96394a6e01413"), statusText, dist)

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
                                updateTracer(__S("4daaae08ed474e64") .. plr.Name, cam.ViewportSize / 2, (hrp.Position - myRoot.Position), statusColor, true)
                            end
                        end
                    end
                end
            end

                                                                              
            if Config.ESPFruits then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA(__S("ebe227b907a6e661")) or obj.Name:lower():find(__S("8a19a16a1694cc0d3e"), 1, true) then
                        local handle = obj:FindFirstChild(__S("28511b1b8af19d5564af")) or obj:FindFirstChildWhichIsA(__S("c68894cc06be5c5a680c6467"))
                        if handle then
                            local dist = math.floor((handle.Position - myRoot.Position).Magnitude)
                            local fruitName = tostring(obj:GetAttribute(__S("64c00e7df56dc478f0dad4e0ae0f2c8d")) or obj.Name):gsub(__S("02f7882e17d8c21b41b3"), "")
                            local tier = getFruitTier(fruitName)
                            local color = Config.ESPFruitRarity and tier.color or Color3.fromRGB(250, 204, 21)
                            createESPBillboard(handle, fruitName .. __S("a12f01dfd54ab4f27121"), string.format(__S("3f667b90ff4e59ae4f283f5ffe3c308ca14fa10020ac5f280b703a86"), tier.name, dist), color)
                        end
                    end
                end
            end

                                                                              
            if Config.ESPChests then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA(__S("dd9df541f9656859bbaa9a4c")) and (obj.Name == __S("7bd56ef2549f1fe63a99") or obj.Name == __S("1a0ce8a38c2bc8d1ca00") or obj.Name == __S("b8446254709084a5d308")) then
                        local dist = math.floor((obj.Position - myRoot.Position).Magnitude)
                        if dist < 2500 then
                            local label = obj.Name == __S("567bdc05bb044adfe691") and __S("f4b355b670c17be548f04d9f96ec05c16a") or (obj.Name == __S("92eacf67272d1ef32834") and __S("312249185fc1b74c5483d054053c") or __S("cf59c2c93a4fcd9d970b486fe6606089"))
                            createESPBillboard(obj, label, string.format(__S("6d913c7af0662dc08056fb51"), dist), Color3.fromRGB(74, 222, 128))
                        end
                    end
                end
            end

                                                                              
            if Config.ESPIslands then
                local map = Workspace:FindFirstChild(__S("0bc8b62b5211a3cc5f2ec57885f55da0")) and Workspace._WorldOrigin:FindFirstChild(__S("aa002fdc4d8c779b4d0996f349"))
                if map then
                    for _, loc in ipairs(map:GetChildren()) do
                        if loc:IsA(__S("4837a98d8ca5f27068ef7f6f")) then
                            local dist = math.floor((loc.Position - myRoot.Position).Magnitude)
                            local lower = loc.Name:lower()
                            local color, tag = Color3.fromRGB(167, 139, 250), __S("e66f233e33342a5ab352")
                            if lower:find(__S("84a69cef5fc0c1ec721f")) then color, tag = Color3.fromRGB(244, 114, 182), __S("22de16a0480f438846be")
                            elseif lower:find(__S("c115905175215f4dae441b")) then color, tag = Color3.fromRGB(250, 204, 21), __S("5f4d0a02cf60c196c774c3")
                            elseif lower:find(__S("fd8483b37aac677a799ac097a4a931")) then color, tag = Color3.fromRGB(74, 222, 128), __S("9bbbfd64df0e9a684ca54ab73cc9a1")
                            elseif lower:find(__S("39f377154910cea5")) then color, tag = Color3.fromRGB(56, 189, 248), __S("d82af0c66b8b60314c6acb907b9cfff7") end
                            createESPBillboard(loc, loc.Name, string.format(__S("76626a77e41147d5c873d05d4d02cd3f1989edb5b7"), tag, dist), color)
                        end
                    end
                end
            end

                                                                             
            if (Config.SeaEventTracker or Config.MirageFinder) and #(SeaEventState.events or {}) > 0 then
                for idx, ev in ipairs(SeaEventState.events) do
                    if ev.obj and ev.obj.Parent then
                        local dist = math.floor((ev.obj.Position - myRoot.Position).Magnitude)
                        if dist < 4000 then
                            createESPBillboard(ev.obj, ev.name, string.format(__S("1499e428a31f172d9435788aba67c4af0b19385f309f1746"), dist), ev.color)
                        end
                    end
                end
            end

                                                                              
            if Config.ESPBosses then
                local enemies = Workspace:FindFirstChild(__S("b2d15dd9a9daea486a067d"))
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local hrp = mob:FindFirstChild(__S("5108d78afe2f6bff72021a39e1314acb8d36540f"))
                        local hum = mob:FindFirstChildOfClass(__S("ef40513bc0f2bbd9a1a1239d"))
                        if hrp and hum and hum.Health > 0 then
                            local dist = math.floor((hrp.Position - myRoot.Position).Magnitude)
                            createESPBillboard(hrp, mob.Name, string.format(__S("8d77caec91068173d44ead8d475e2901320ff367"), math.floor(hum.Health), dist), Color3.fromRGB(248, 113, 113))
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

                                                                                 
print(string.format(__S("2baf449d38503dc5e9b48b50aeec97d51762149f600e34e89f4e6fe9dfadb8005da8cab99b5ad48a431ddab192e78232cf"), Guard.watchTable(__S("c9e6be4e1c90a132f92631"), Engines)))

                                                                              
                     
                                                                      
                                                            
                                                                              
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
    local c = Instance.new(__S("681e37ff3a78da96c64fd902"))
    c.CornerRadius = UDim.new(0, radius or RADIUS.card)
    if parent ~= nil then pcall(function() c.Parent = parent end) end
    return c
end

local function hairline(parent, color, thickness, transparency)
    local s = Instance.new(__S("0655b1b0f4fdd5ef8b800ab5"))
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if parent ~= nil then pcall(function() s.Parent = parent end) end
    return s
end

local function pad(parent, all, extra)
    local p = Instance.new(__S("a48d2b61e4c3fd8599bc009e6a"))
    if all then
        p.PaddingTop = UDim.new(0, all)
        p.PaddingBottom = UDim.new(0, all)
        p.PaddingLeft = UDim.new(0, all)
        p.PaddingRight = UDim.new(0, all)
    end
    if extra then
        for side, value in pairs(extra) do p[__S("42c4a51251dbffa4e66b6b") .. side] = UDim.new(0, value) end
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
    local shadow = new(__S("e0fc1ec3389d62e57294c183a146"), {
        Name = __S("7f339874795f43d493a6"),
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
    target:GetPropertyChangedSignal(__S("1d6b1225a20df22d893d9053")):Connect(sync)
    target:GetPropertyChangedSignal(__S("bba28bd6a9a3e4a2")):Connect(sync)
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
        accentLine = new(__S("59da0587342cc87f10"), {
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
    [CustomIcons.HubCrest]  = __S("f8117f38c0e1646f3d"),
    [CustomIcons.AutoFarm]  = __S("9648f8e950a505cfc640"),
    [CustomIcons.Stats]     = __S("3480729af099b33def"),
    [CustomIcons.Fruits]    = __S("d2b7ec4b32a5e9e9d5"),
    [CustomIcons.Teleport]  = __S("70ef65fc376c99f250e324"),
    [CustomIcons.ESP]       = __S("0f26dfad21b10c"),
    [CustomIcons.Animator]  = __S("ad5e595e94c6bc02"),
    [CustomIcons.Settings]  = __S("4b95d30f321be9f0"),
    [CustomIcons.Boss]      = __S("e9cd4cc0d92742954a"),
    [CustomIcons.Lightning] = __S("8804c671f6396073"),
    [CustomIcons.Shield]    = __S("263c40228d00a73feef0"),
    [CustomIcons.Play]      = __S("c473b9d3e76ef7a5"),
    [CustomIcons.Stop]      = __S("62ab3384bac7b6d0"),
    [CustomIcons.Loop]      = __S("00e2ad351baff0a6"),
    [CustomIcons.Wand]      = __S("9f1a26e6c77b5e77"),
    [CustomIcons.Layers]    = __S("3d51a0979aad21298c96"),
    [CustomIcons.Search]    = __S("db891a485b99ff1139d2"),
    [CustomIcons.PvP]       = __S("79c093f995643cc06c"),
    [CustomIcons.Players]   = __S("17f80daa6f26ababf5"),
    [CustomIcons.Aim]       = __S("b62f875b7aa9aed4fbb686"),
    [CustomIcons.Fly]       = __S("5467010cada26e94"),
    [CustomIcons.Water]     = __S("f29e7abd1c4f6c"),
    [CustomIcons.Magnet]    = __S("90d5f46e6ffdcf6d0b6a"),
    [CustomIcons.Server]    = __S("2f0d6e1f1b06899c2b"),
}

local function drawVectorGlyph(holder, kind, color, size, zBase, out)
    out = out or {}
    local function put(px, py, w, h, rotation, radius, fill)
        local part = new(__S("cd44e7d0a900f19033"), {
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

    if kind == __S("6b7c6181b4793375d8c5") then
        put(0.5, 0.5, 0.13, 1.0, 45, 2)
        put(0.5, 0.5, 0.13, 1.0, -45, 2)
    elseif kind == __S("09b3db322b36865e3d") then
        put(0.5, 0.43, 0.86, 0.72, 0, math.floor(size * 0.3))
        put(0.34, 0.41, 0.19, 0.19, 0, math.floor(size / 2), Theme.BgApp)
        put(0.66, 0.41, 0.19, 0.19, 0, math.floor(size / 2), Theme.BgApp)
        put(0.5, 0.79, 0.34, 0.17, 0, 2)
    elseif kind == __S("a7eb54e33b0b88abee") then
        put(0.24, 0.7, 0.15, 0.44, 0, 2)
        put(0.5, 0.6, 0.15, 0.66, 0, 2)
        put(0.76, 0.68, 0.15, 0.52, 0, 2)
    elseif kind == __S("4622ce948a6c911c83") then
        put(0.5, 0.66, 0.8, 0.8, 0, math.floor(size / 2))
        put(0.75, 0.2, 0.34, 0.16, -18, math.floor(size / 2))
        put(0.5, 0.22, 0.08, 0.3, 0, 2)
    elseif kind == __S("e45a484509a11f") then
        put(0.5, 0.5, 1.0, 0.62, 0, math.floor(size * 0.31))
        put(0.5, 0.5, 0.34, 0.34, 0, math.floor(size / 2), Theme.BgApp)
    elseif kind == __S("8291c1f6e2a4ad68f8f450") then
        put(0.5, 0.5, 1.0, 1.0, 0, math.floor(size / 2))
        put(0.5, 0.5, 0.6, 0.6, 0, math.floor(size / 2), Theme.BgApp)
        put(0.5, 0.5, 0.09, 0.42, 40, 2)
    elseif kind == __S("20c93ba73eaa1acc") then
        put(0.5, 0.16, 0.3, 0.3, 0, 2)
        put(0.5, 0.84, 0.3, 0.3, 0, 2)
        put(0.16, 0.5, 0.3, 0.3, 90, 2)
        put(0.84, 0.5, 0.3, 0.3, 90, 2)
        put(0.5, 0.5, 0.54, 0.54, 0, math.floor(size / 2))
        put(0.5, 0.5, 0.2, 0.2, 0, math.floor(size / 2), Theme.BgApp)
    elseif kind == __S("bf00b5584fabf924") then
        put(0.44, 0.32, 0.15, 0.48, 18, 2)
        put(0.56, 0.68, 0.15, 0.48, 18, 2)
    elseif kind == __S("5d382f09b64ff74a5b28") then
        put(0.5, 0.46, 0.86, 0.9, 0, math.floor(size * 0.3))
        put(0.5, 0.42, 0.34, 0.13, 0, 2, Theme.BgApp)
        put(0.5, 0.5, 0.13, 0.5, 0, 2, Theme.BgApp)
    elseif kind == __S("fb6fa8ba366c195d") then
        put(0.42, 0.34, 0.13, 0.55, -32, 2)
        put(0.42, 0.66, 0.13, 0.55, 32, 2)
    elseif kind == __S("99a7226b2dad5d18") then
        put(0.5, 0.5, 0.6, 0.6, 0, 3)
    elseif kind == __S("37de9c1c1ec2ba98") then
        put(0.5, 0.5, 0.86, 0.86, 0, math.floor(size / 2))
        put(0.5, 0.5, 0.5, 0.5, 0, math.floor(size / 2), Theme.BgApp)
        put(0.5, 0.12, 0.22, 0.22, 0, 2)
    elseif kind == __S("d61615cdb6ba6aead874") then
        put(0.5, 0.27, 0.8, 0.22, 0, 3)
        put(0.5, 0.51, 0.8, 0.22, 0, 3)
        put(0.5, 0.75, 0.8, 0.22, 0, 3)
    elseif kind == __S("744d8f7e3c5dce560705") then
        put(0.44, 0.42, 0.62, 0.62, 0, math.floor(size / 2))
        put(0.44, 0.42, 0.3, 0.3, 0, math.floor(size / 2), Theme.BgApp)
        put(0.76, 0.76, 0.15, 0.42, -45, 2)
    elseif kind == __S("1285092f72f4c584e397") then
        put(0.3, 0.44, 0.16, 0.6, 0, 2)
        put(0.7, 0.44, 0.16, 0.6, 0, 2)
        put(0.5, 0.74, 0.56, 0.16, 0, 2)
    elseif kind == __S("b0bc82e0f392343d39") then
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
    local holder = new(__S("4ef3fc91477f679a8d"), {
        Name = __S("ed2b76429a6b504762186ad5"),
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
                if key == __S("8b62eff35441b38cf3d24f36cbd1f4") then return accentColor end
                return nil
            end,
            __newindex = function(_, key, value)
                if key == __S("299a69a4da1d5b60244d9e700e82ee") then
                    for _, part in ipairs(parts) do part.BackgroundColor3 = value end
                elseif key == __S("c7d1e355c1b3da0e68") then
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

    local img = new(__S("66095d06db29cecc1b50d6fbe93b"), {
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
                print(string.format(__S("0440d6b727003d957a612610f6860ee17893cfb47fee052533af13f8d350e77ef30e7db3bb76c90bd01819f83567cf312a8569d49b12ee97c111c0a892fc0218a14821c6544456b9569f61"), tostring(iconAssetId)))
            elseif BadIconCount == 4 then
                print(__S("a278506849eaee8dfed6de298db72fe9c6a86ad3ed4c54d7192f03555501265e678f059e3974e9f2d0cab90f0a806fb8fe186dc32f4c76b92e769d541308e34f225462c712c13945f7c21f6352e10c8712362ca1f81aca"))
            end
        end
        img.Visible = false
        drawVectorGlyph(holder, glyphKind or GLYPH_OF_ASSET[iconAssetId] or __S("40afca196badd9"), accentColor, inner, (zIdx or 4) + 1)
    end)

    return holder, img
end

                                                 
local createVectorIconBadge = iconTile

                                                                               
local guiParent = LocalPlayer:WaitForChild(__S("dee743ca7545ae94f793e8086e"))
if guiParent:FindFirstChild(__S("7d1ebd7b104c61a8eed0b09ec9aa1b07ab15f23391f5")) then
    guiParent.SkillHubBloxFruits:Destroy()
end

local ScreenGui = new(__S("1b56372c06270461ea0acf103d"), {
    Name = __S("b98db0dd856abf1c957e1139b681452ba27e75b425ca"),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    IgnoreGuiInset = true,
}, guiParent)

local UIScale = new(__S("57c52a8e11da2b7d9c200c"), {}, ScreenGui)
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
    Workspace.CurrentCamera:GetPropertyChangedSignal(__S("f5fca43f946dcaa4b578248a85b42d86")):Connect(updateScale)
end

                                                                               
                                                                      
local Canvas = new(__S("94341df0d38a0b5eb9"), {
    Name = __S("326b97a16d1b2a9810a4"),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
}, ScreenGui)

local MainWindow = new(__S("d0a31152903db8fdd8"), {
    Name = __S("6eda8b03535cecf39456c3043df7"),
    Size = UDim2.new(0, 772, 0, 512),
    Position = UDim2.new(0.5, -386, 0.5, -256),
    BackgroundColor3 = Theme.BgSurface,
    BorderSizePixel = 0,
    ClipsDescendants = false,
}, Canvas)
corner(MainWindow, RADIUS.window)

attachShadow(MainWindow, 42, 0.5)

local winStroke = hairline(MainWindow, Theme.Stroke, 1, 0.2)

                                                                
local sheen = new(__S("0d1204b4f027f745d0"), {
    Name = __S("ab497e659438be5216"),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.965,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 132),
    ZIndex = 2,
}, MainWindow)
corner(sheen, RADIUS.window)
new(__S("4980f816e285915c3466144d3b1e"), {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, sheen)

local WinClip = new(__S("e7b871c7a1e5971ba5"), {
    Name = __S("85efeb786fdffffd2487a8c20b5d"),
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

                                                                               
local Topbar = new(__S("242765292e1f4fbb37"), {
    Name = __S("c25ededa4cbb0ab121f2a518"),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 58),
    ZIndex = 6,
}, WinClip)

local brandTile = iconTile(Topbar, CustomIcons.HubCrest, Theme.Accent, 30, UDim2.new(0, 18, 0.5, -15), 7)

local BrandTitle = new(__S("6096588b1cfc21fd6092ee83ae"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("fecdd23c0ae57fdd898586ac11"),
    TextColor3 = Theme.TextPrimary,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 58, 0, 12),
    Size = UDim2.new(0, 200, 0, 18),
    ZIndex = 7,
}, Topbar)

local VersionChip = new(__S("9d054bedb72fc8ba3a"), {
    BackgroundColor3 = Theme.BgInset,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 132, 0, 15),
    Size = UDim2.new(0, 46, 0, 15),
    ZIndex = 7,
}, Topbar)
corner(VersionChip, RADIUS.chip)
hairline(VersionChip, Theme.StrokeSoft, 1, 0.4)
new(__S("3b3cc59e2d592e3ff05246de09"), {
    BackgroundTransparency = 1,
    Font = UIFontMono,
    Text = __S("d9743f4f57c14a7eab"),
    TextColor3 = Theme.TextMuted,
    TextSize = 9,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 8,
}, VersionChip)

local BrandSub = new(__S("77abb900b1c030e972965890bd"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Text = __S("15e332b149effe475b6c1812bbaabba42601cb775d02f7d7"),
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 58, 0, 30),
    Size = UDim2.new(0, 260, 0, 14),
    ZIndex = 7,
}, Topbar)

                                             
local SearchShell = new(__S("b41aac62cfa104591d"), {
    BackgroundColor3 = Theme.BgInset,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -404, 0.5, -15),
    Size = UDim2.new(0, 236, 0, 30),
    ZIndex = 7,
}, Topbar)
corner(SearchShell, RADIUS.control)
local searchStroke = hairline(SearchShell, Theme.StrokeSoft, 1, 0.35)

iconTile(SearchShell, CustomIcons.Search, Theme.TextMuted, 16, UDim2.new(0, 8, 0.5, -8), 8)

local SearchBox = new(__S("525226136ff105a20acf4b"), {
    BackgroundTransparency = 1,
    ClearTextOnFocus = false,
    Font = UIFont,
    PlaceholderColor3 = Theme.TextFaint,
    PlaceholderText = __S("f0899fc4afa951cdd27d4e0ec5614025996a1ae31d13e6fc71fef7"),
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
    local btn = new(__S("8ec1197596b2f07b412e238c2cf7"), {
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

local MinBtn = ghostButton(Topbar, __S("2cf893268af482"), -66, false)
local CloseBtn = ghostButton(Topbar, __S("cb300cd7205f53"), -36, true)

                                                                               
do
    local DragHandle = new(__S("696786887515f80bcf"), {
        Name = __S("079f0039119b703be5b524813d70"),
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

                              
new(__S("a5d679ea399f04d10a"), {
    BackgroundColor3 = Theme.StrokeSoft,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 57),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 6,
}, WinClip)

                                                                               
local Rail = new(__S("440df39b62c5039861"), {
    Name = __S("e2456d4ca89e31ff"),
    BackgroundColor3 = Theme.BgSidebar,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 58),
    Size = UDim2.new(0, 206, 1, -58),
    ZIndex = 4,
}, WinClip)

new(__S("807ce6fd6a8929131d"), {
    BackgroundColor3 = Theme.StrokeSoft,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    ZIndex = 5,
}, Rail)

local RailSection = new(__S("1eb460ae6a1672500587981bcb"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("bcebda5f21fd182b6f790e3ce530"),
    TextColor3 = Theme.TextFaint,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 18, 0, 12),
    Size = UDim2.new(1, -24, 0, 12),
    ZIndex = 5,
}, Rail)

local TabButtonContainer = new(__S("5b235410932bbbe4fc49975788f133d27e8d"), {
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    Position = UDim2.new(0, 10, 0, 30),
    ScrollBarThickness = 0,
    Size = UDim2.new(1, -20, 1, -124),
    ZIndex = 5,
}, Rail)
new(__S("f95acdc1e538fb7decb912ec2a56f9b8"), {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, TabButtonContainer)

                                          
local IdCard = new(__S("979247720a5220eb6f"), {
    BackgroundColor3 = Theme.BgElevated,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 1, -110),
    Size = UDim2.new(1, -20, 0, 100),
    ZIndex = 5,
}, Rail)
corner(IdCard, RADIUS.panel)
hairline(IdCard, Theme.StrokeSoft, 1, 0.3)

local AvatarShell = new(__S("35c9c123333cfb2aaa"), {
    BackgroundColor3 = tint(Theme.Accent, 0.7),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 12),
    Size = UDim2.new(0, 34, 0, 34),
    ZIndex = 6,
}, IdCard)
corner(AvatarShell, RADIUS.pill)
hairline(AvatarShell, tint(Theme.Accent, 0.4), 1, 0.5)

local AvatarInitials = new(__S("d4013ad40d483c28ea6cb34113"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("7238b485ce"),
    TextColor3 = Theme.Accent,
    TextSize = 13,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 7,
}, AvatarShell)

local AvatarImg = new(__S("10702e36048198adb2d122979307"), {
    BackgroundTransparency = 1,
    Image = "",
    Size = UDim2.new(1, 0, 1, 0),
    Visible = false,
    ZIndex = 8,
}, AvatarShell)
corner(AvatarImg, RADIUS.pill)

local IdName = new(__S("aea7a7e7de6c134d72f2e72ded"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("4cdf21987ed10370aa36"),
    TextColor3 = Theme.TextPrimary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 54, 0, 14),
    Size = UDim2.new(1, -64, 0, 15),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 6,
}, IdCard)

local IdHandle = new(__S("eb169b49e28dead7f1c4ea0c5c"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Text = __S("894e14fa12e8306127ae87"),
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 54, 0, 29),
    Size = UDim2.new(1, -64, 0, 14),
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 6,
}, IdCard)

local function miniStat(parent, xOffset, width, caption, value, valueColor)
    local holder = new(__S("27858eaba50dd4a061"), {
        BackgroundColor3 = Theme.BgInset,
        BorderSizePixel = 0,
        Position = UDim2.new(0, xOffset, 0, 58),
        Size = UDim2.new(0, width, 0, 30),
        ZIndex = 6,
    }, parent)
    corner(holder, RADIUS.chip)
    hairline(holder, Theme.StrokeSoft, 1, 0.45)

    new(__S("c5bd085cb33cfd69d9d27516b2"), {
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

    local lbl = new(__S("63f4820d63ae4dc0b64b790e01"), {
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

local FooterLvLbl = miniStat(IdCard, 12, 84, __S("022bfbbe5caaf0aca67f35edb1152b6a0b747a910aba"), __S("a063756f39908aa9da36"), Theme.TextSecondary)
local FooterBeliLbl = miniStat(IdCard, 102, 76, __S("3e9aef203dff736d"), __S("dcd268d1b1b873"), Theme.Success)

                        
task.spawn(function()
    while task.wait(1) do
        if not ScreenGui.Parent then break end
        SkillHubStep(__S("7b09e2828375445653f139e54b9ca7afe4"), function()
            FooterLvLbl.Text = string.format(__S("19415c3375474b57b6773b42"), tostring(getPlayerLevel()), formatNumber(getPlayerFragments()))
            FooterBeliLbl.Text = __S("b778d5e4e278") .. formatNumber(getPlayerBeli())
            BrandSub.Text = string.format(__S("55b04f957666882bc488ae1c58fde549bc98ab15ade6347c86da21f3fffc70"), CURRENT_SEA, tostring(SEA_DETECT_SOURCE))
            IdName.Text = LocalPlayer.DisplayName
            IdHandle.Text = __S("f3e7c94641") .. LocalPlayer.Name
            if AvatarInitials.Text == __S("921f42f708") then
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

                                                                               
local Content = new(__S("3056bca82fe063ddc7"), {
    Name = __S("ce8e365958f6281fda8f83"),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 206, 0, 58),
    Size = UDim2.new(1, -206, 1, -58),
    ZIndex = 4,
}, WinClip)

local HeaderBar = new(__S("6cc5b00a2e9767f3cc"), {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 56),
    ZIndex = 5,
}, Content)

local _, ActiveTabIconImg = iconTile(HeaderBar, CustomIcons.AutoFarm, Theme.Accent, 32, UDim2.new(0, 18, 0, 13), 6)

local ActiveTabTitle = new(__S("0afd29bbca865a67d97c4ad0b8"), {
    BackgroundTransparency = 1,
    Font = UIFontBold,
    Text = __S("a934a36c81b65269bbfd1c7708"),
    TextColor3 = Theme.TextPrimary,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 60, 0, 10),
    Size = UDim2.new(0, 300, 0, 18),
    ZIndex = 6,
}, HeaderBar)

local ActiveTabSub = new(__S("476c1d1d6ea66f8feef9ded9b4"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Text = __S("e5a396ce51925c6ff693fead40509b316eae19a60e9fca1037001e95"),
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 60, 0, 28),
    Size = UDim2.new(0, 320, 0, 14),
    ZIndex = 6,
}, HeaderBar)

                                                
local headerChips = new(__S("83db107f734616f960"), {
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -400, 0, 17),
    Size = UDim2.new(0, 382, 0, 22),
    ZIndex = 6,
}, HeaderBar)
local chipLayout = new(__S("22128a308fbf434f800bf2ebee6f2ec6"), {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, headerChips)

local function statusChip(text, color)
    local chip = new(__S("c04a03e1fcfe5034bc"), {
        BackgroundColor3 = Theme.BgInset,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 20),
        ZIndex = 7,
        AutomaticSize = Enum.AutomaticSize.X,
    }, headerChips)
    corner(chip, RADIUS.pill)
    hairline(chip, Theme.StrokeSoft, 1, 0.4)
    pad(chip, nil, { Left = 8, Right = 8 })

    local dot = new(__S("5e817d922d76f71839"), {
        BackgroundColor3 = color or Theme.TextMuted,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0.5, -2),
        Size = UDim2.new(0, 4, 0, 4),
        ZIndex = 8,
    }, chip)
    corner(dot, RADIUS.pill)

    local lbl = new(__S("fcb8f7435f58458ce98cae8590"), {
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

local ChipSea   = statusChip(__S("9af070f4b0b4d4600d"), Theme.Accent)
local ChipKill  = statusChip(__S("3927eaa5572ff9ca442f4793390b8038"), Theme.TextMuted)
local ChipFly   = statusChip(__S("d75f64567ae28ff6a85d050ce325"), Theme.TextMuted)
local ChipNet   = statusChip(__S("7596de079c6b1981"), Theme.Sage)

new(__S("13ce57b8e2035e5d7c"), {
    BackgroundColor3 = Theme.StrokeSoft,
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 55),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 5,
}, HeaderBar)

local PagesFolder = new(__S("b205d1699bf9cd1679"), {
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Position = UDim2.new(0, 18, 0, 60),
    Size = UDim2.new(1, -36, 1, -92),
    ZIndex = 4,
}, Content)

                                     
local StatusStrip = new(__S("503d4b1a53beecd379"), {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 18, 1, -30),
    Size = UDim2.new(1, -36, 0, 22),
    ZIndex = 5,
}, Content)

local HotkeyHint = new(__S("ee74c4cb4936efc683fd9f188e"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Text = __S("8cac3e7c3f88a51f549ff33af3fc5c257f3086a8fc36b8dda8e503cd0c5c9628541df09af7485c8f77ec13cbe656df4342ad96e164a24e1d14931d324c25c7403951185802254899cd49b2c5af22fe0b00f0d59c110c9a5fbe5370"),
    TextColor3 = Theme.TextFaint,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Size = UDim2.new(1, -140, 1, 0),
    ZIndex = 6,
}, StatusStrip)

local LiveClock = new(__S("2ae3b82d4ada38f011dd2b9051"), {
    BackgroundTransparency = 1,
    Font = UIFontMono,
    Text = __S("c91b31dea341fec422c1e6fc"),
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
        SkillHubStep(__S("6752ab8f33ee811832712b7a37872bb1fc"), function()
            local t = os.date(__S("058a2540db2b"))
            LiveClock.Text = string.format(__S("a3c19ef11bcd18cd4bcd10457ccfdf9d24cc"), t.hour, t.min, t.sec)
        end)
    end
end)

                                                                               
local ToastHolder = new(__S("41f918a2129367362f"), {
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -336, 0, 14),
    Size = UDim2.new(0, 322, 1, -28),
    ZIndex = 100,
}, ScreenGui)
new(__S("e0309253fb384193e67816fcbead6acd"), {
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
}, ToastHolder)

local toastOrder = 0
local function notify(title, message, duration, iconAsset)
    duration = duration or 3.5
    toastOrder = toastOrder + 1

    local card = new(__S("7e680c04b6225a55f8"), {
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

    local titleLbl = new(__S("1c9f85b5d51dee51ae1ee91bf2"), {
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

    local messageLbl = new(__S("bad6ff66cf0abd3021f4b434e3"), {
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

    local progressTrack = new(__S("590e791767aa92c16b"), {
        BackgroundColor3 = Theme.BgInset,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 102,
    }, card)
    corner(progressTrack, RADIUS.pill)

    local progress = new(__S("f745f2c8c0ff17e202"), {
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
            if child:IsA(__S("957d6c7947a990f90192950c88")) then child.Visible = false end
        end
        SafeTween(card, TweenInfo.new(0.26, Enum.EasingStyle.Quart), { Size = UDim2.new(1, 0, 0, 62) }):Play()
        task.wait(0.09)
        for _, child in ipairs(card:GetDescendants()) do
            if child:IsA(__S("33b4e62a953de24eac8602cc47")) then child.Visible = true end
        end
    end)

    task.delay(duration, function()
        if card and card.Parent then
            SafeTween(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
            for _, child in ipairs(card:GetDescendants()) do
                if child:IsA(__S("d1ec5fdb84a2550f43b5a57a5c")) or child:IsA(__S("7023d98cecceebc317d7d1c007cf")) then
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

                                                                              
local WatermarkBar = new(__S("0e5b533d0517afd72d"), {
    Name = __S("ac92ccee1e4c85d74049579144cef357"),
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

local WatermarkText = new(__S("4aca469fa71f881687e7fdf0ca"), {
    BackgroundTransparency = 1,
    Font = UIFontMono,
    Position = UDim2.new(0, 32, 0, 0),
    Size = UDim2.new(1, -40, 1, 0),
    Text = __S("e901c050268670cde8d173ac1d0f2cd1dacac3c89c2d4087589ca3"),
    TextColor3 = Theme.TextSecondary,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 87,
}, WatermarkBar)

local StatusBar = new(__S("87393a01db1eb5f93f"), {
    Name = __S("2570b3b242f8f32b7f0a1e227a0dc25e06d101"),
    BackgroundColor3 = Theme.BgInset,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, -252, 0, 42),
    Size = UDim2.new(0, 504, 0, 22),
    ZIndex = 84,
}, ScreenGui)
corner(StatusBar, RADIUS.pill)
hairline(StatusBar, Theme.StrokeSoft, 1, 0.45)

local StatusText = new(__S("c3a82d6315e03c6decf0a52ef8"), {
    BackgroundTransparency = 1,
    Font = UIFontMono,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -24, 1, 0),
    Text = __S("61dfa71499cb9800811076d834910f38ad"),
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
        SkillHubStep(__S("001720c5eff3ded9c77d7de2834ef0fac8"), function()
            local now = tick()
            local fps = math.floor(frames / math.max(now - lastTick, 0.01))
            frames = 0
            lastTick = now
            local status = getServerStatus()

            WatermarkBar.Visible = Config.ShowWatermarkHUD
            WatermarkText.Text = string.format(__S("9e4e9a766599003c70625d1acffefe253da94eca16cb522361e6d39bfe243eaa89b862f6d1c25a5946b64b3047f8fa9c2fd2e612a3d29fb790af0f625e"),
                CURRENT_SEA, string.upper(tostring(SEA_DETECT_SOURCE)), getPlayerLevel(), fps, status.ping)

            StatusBar.Visible = Config.ServerStatusHUD and Config.ShowWatermarkHUD
            local hunting = Config.AutoKillSelected or Config.AutoKillPvP
            StatusText.Text = string.format(
                __S("3c861427ac5e152d1d67b86006e7efdbe025a43a7bdf89e2206d1910fe4fc5439000ba5bf90e0962c259401e6c788fff8e48b23cd080a24201a1d4eeb3e2"),
                status.jobId, status.players, status.maxPlayers,
                Config.AimLock and __S("dabd8dd87aa9245ef277ae") or (PvPState.target and (__S("78f50789bf22e9055115e7") .. string.upper(tostring(PvPState.targetName))) or __S("172c813a0f81111b85fea92b")),
                hunting and __S("b563faeb3fba3ad96ccafbf73d454af5") or __S("539b749c53aa21ae4e826c64b4"),
                Config.FlyEnabled and __S("f1d2ee4d0fb6") or __S("900a67fe4bb49c"),
                status.events
            )
            StatusText.TextColor3 = hunting and Theme.Clay or Theme.TextMuted

                           
            ChipSea.label.Text = string.format(__S("2e41e1af6629aeae641cde2fcc580da5"), CURRENT_SEA, string.upper(tostring(SEA_DETECT_SOURCE)))
            ChipSea.dot.BackgroundColor3 = Theme.Accent
            ChipKill.label.Text = hunting and (__S("cc795b60e16143abebe1f53a") .. (PvPState.targetName ~= "" and string.upper(PvPState.targetName) or __S("6ab0d51159098f90"))) or __S("08e84ec251fa35e7292c524aae22f6bd")
            ChipKill.dot.BackgroundColor3 = hunting and Theme.Clay or Theme.TextFaint
            ChipFly.label.Text = Config.FlyEnabled and __S("a71fc8735d867b0c3dc628db81") or __S("455742244b410f549a848a10c867")
            ChipFly.dot.BackgroundColor3 = Config.FlyEnabled and Theme.Sage or Theme.TextFaint
            ChipNet.label.Text = string.format(__S("e38ebbd56a7592dd2dea3a54ea9bab9c27e426"), status.ping, fps)
            ChipNet.dot.BackgroundColor3 = (status.ping < 90) and Theme.Sage or ((status.ping < 180) and Theme.Sand or Theme.Clay)
        end)
    end
end)

                                                                              
local FloatBtn = new(__S("81c63586c9777e119b899a950f40"), {
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

local NoResults = new(__S("1ffdaf372e54573c7a5167b237"), {
    BackgroundTransparency = 1,
    Font = UIFont,
    Position = UDim2.new(0, 0, 0.5, -14),
    Size = UDim2.new(1, 0, 0, 28),
    Text = __S("be3528e8b28ae127b1a860fa7d1a068808ca3b34ca9d974c9ac96ea80f3970de"),
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

SearchBox:GetPropertyChangedSignal(__S("5c6ca29912c68e12")):Connect(applySearch)

                                                                               
local function createTab(iconAsset, name, accentOverride)
    local tabColor = accentOverride or Theme.Accent

    local btn = new(__S("faa41c4a08ecd04e252a82077afa"), {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Text = "",
        ZIndex = 5,
    }, TabButtonContainer)
    corner(btn, RADIUS.control)

    local pill = new(__S("98db95fbafdfb8faa3"), {
        BackgroundColor3 = Theme.BgElevated,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 5,
    }, btn)
    corner(pill, RADIUS.control)
    local pillStroke = hairline(pill, Theme.Hairline, 1, 1)

    local bar = new(__S("37130fac7907f2b2db"), {
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

    local lbl = new(__S("d54a895d99028d0c18b4fa96e8"), {
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

    local page = new(__S("7382030e4ca1d555b861870e204575d4dc27"), {
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
    new(__S("11b97cbffdd4239dacc6b4e183262dad"), {
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

        trace(__S("aff0f6707b6bc3c438234b6dbedeab6c8678") .. tostring(name))
        ActiveTabTitle.Text = name
        ActiveTabSub.Text = string.format(__S("4e287021956771caf7da35097719a33685e335d85fa21129ca2aebb646a02d55992be2a90e31"), CURRENT_SEA)
        ActiveTabIconImg.Image = iconAsset
        ActiveTabIconImg.ImageColor3 = tabColor

                               
        page.Position = UDim2.new(0, 8, 0, 0)
        SafeTween(page, TweenInfo.new(0.22, Enum.EasingStyle.Quart), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        applySearch()
    end

                                                                            
    tabObj.Select = selectTab
    btn.MouseButton1Click:Connect(function()
        SkillHubStep(__S("ec5fe9d214ff3359fe8d1c9ff39f773313") .. tostring(name), selectTab)
    end)
    if #tabs == 1 then SkillHubStep(__S("8a976383849e8b8b059b338df0b299291a") .. tostring(name) .. __S("28cedd34a0161a32de3179"), selectTab) end

                                                                               
    function tabObj:AddSection(title)
        self.order = self.order + 1
        local sec = new(__S("c70656e54e6876f6eb"), {
            BackgroundTransparency = 1,
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 26),
        }, self.page)

        local dot = new(__S("653dd09667a177051e"), {
            BackgroundColor3 = self.color,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 2, 0.5, -2),
            Size = UDim2.new(0, 4, 0, 4),
        }, sec)
        corner(dot, RADIUS.pill)

        new(__S("03754a472d7a36d3a8cfda1b79"), {
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

        local divider = new(__S("a1acc3f877840e5f68"), {
            BackgroundColor3 = Theme.StrokeSoft,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 3,
        }, sec)
        new(__S("3fe43da9f42ee1e9936cd16b8d60"), {
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
        local card = new(__S("de1bb75a24d4a0a7e8"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 58),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or self.icon, self.color, 30, UDim2.new(0, 14, 0.5, -15), 5)

        new(__S("7c53310b268cdef271e7fabdbb"), {
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

        new(__S("1a8aaabc4698aa1ebd71e60434"), {
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

        local stateLbl = new(__S("b8c2246d5ec744e9ad2841711c"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(1, -112, 0.5, -7),
            Size = UDim2.new(0, 30, 0, 14),
            Text = __S("56f99e1eac9010"),
            TextColor3 = Theme.TextFaint,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 5,
        }, card)

        local track = new(__S("f53117cf0d80f06ebd"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -68, 0.5, -12),
            Size = UDim2.new(0, 44, 0, 24),
            ZIndex = 5,
        }, card)
        corner(track, RADIUS.pill)
        local trackStroke = hairline(track, Theme.StrokeSoft, 1, 0.35)

        local knob = new(__S("93689180ea55ffd5a4"), {
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
            stateLbl.Text = state and __S("31a00b315dad") or __S("cfd784e2e863f0")
            stateLbl.TextColor3 = state and self.color or Theme.TextFaint
        end
        render(false)

        local click = new(__S("6e0efe938947bdfd639029f6ad9b"), {
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

        table.insert(allSearchables, { frame = card, label = title .. __S("0c467844a3") .. (desc or "") })
    end

                                                                               
    function tabObj:AddButton(title, desc, btnText, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("aa7df1f512876495e6"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 58),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or self.icon, self.color, 30, UDim2.new(0, 14, 0.5, -15), 5)

        new(__S("48b56ba6d2665d57f435680431"), {
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

        new(__S("e6ece557a0deec76b52b05ccbb"), {
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

        local actBtn = new(__S("85245f087eca0951003636098bfd"), {
            AutoButtonColor = false,
            BackgroundColor3 = tint(self.color, 0.86),
            BorderSizePixel = 0,
            Font = UIFontBold,
            Position = UDim2.new(1, -112, 0.5, -15),
            Size = UDim2.new(0, 98, 0, 30),
            Text = btnText or __S("235bd8b92df6b7"),
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

        table.insert(allSearchables, { frame = card, label = title .. __S("c193526a05") .. (desc or "") })
    end

                                                                               
    function tabObj:AddSlider(title, desc, minVal, maxVal, defaultVal, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("5fcacc1b991e003298"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 72),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or CustomIcons.Lightning, self.color, 30, UDim2.new(0, 14, 0, 12), 5)

        new(__S("fe0245cce53b794499bd934004"), {
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

        new(__S("9c39bf7d02b9bfa4441459a40d"), {
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

        local valuePill = new(__S("3a71392e42c301fb2c"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -76, 0, 12),
            Size = UDim2.new(0, 62, 0, 22),
            ZIndex = 5,
        }, card)
        corner(valuePill, RADIUS.chip)
        hairline(valuePill, Theme.StrokeSoft, 1, 0.4)

        local valLbl = new(__S("d8a8b2df321fa8c2db02021364"), {
            BackgroundTransparency = 1,
            Font = UIFontMono,
            Size = UDim2.new(1, 0, 1, 0),
            Text = tostring(defaultVal),
            TextColor3 = self.color,
            TextSize = 11,
            ZIndex = 6,
        }, valuePill)

        local track = new(__S("76e02c904fc34a2e7e"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 56, 0, 52),
            Size = UDim2.new(1, -70, 0, 5),
            ZIndex = 5,
        }, card)
        corner(track, RADIUS.pill)
        hairline(track, Theme.StrokeSoft, 1, 0.45)

        local pct = math.clamp((defaultVal - minVal) / math.max(maxVal - minVal, 1), 0, 1)
        local fill = new(__S("1517a641283af2fba3"), {
            BackgroundColor3 = tint(self.color, 0.35),
            BorderSizePixel = 0,
            Size = UDim2.new(pct, 0, 1, 0),
            ZIndex = 6,
        }, track)
        corner(fill, RADIUS.pill)

        local knob = new(__S("b34f1ff2ac99ec4055"), {
            BackgroundColor3 = Color3.fromRGB(240, 242, 245),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(pct, 0, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            ZIndex = 7,
        }, track)
        corner(knob, RADIUS.pill)
        hairline(knob, Theme.Stroke, 1, 0.5)

        local hitArea = new(__S("518699a3eeb6d2fa17353f125565"), {
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

        table.insert(allSearchables, { frame = card, label = title .. __S("efbe13545e") .. (desc or "") })
    end

                                                                               
    function tabObj:AddDropdown(title, desc, options, defaultOption, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local collapsed = 58
        local listHeight = math.min(#options * 27 + 10, 170)
        local expandedHeight = collapsed + listHeight + 8

        local expanded = false
        local card = new(__S("8df58d0589e81a7bf2"), {
            ClipsDescendants = true,
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, collapsed),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised, interactive = false })
        card.BackgroundColor3 = Theme.BgElevated

        iconTile(card, itemIcon or self.icon, self.color, 30, UDim2.new(0, 14, 0, 14), 5)

        new(__S("2c2d06b6ff11c848e9844e8ee9"), {
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

        new(__S("ca64806767955d6d735722acce"), {
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

        local trigger = new(__S("689bfa182085f7b47d8da7626649"), {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Font = UIFont,
            Position = UDim2.new(1, -210, 0, 14),
            Size = UDim2.new(0, 196, 0, 30),
            Text = __S("06d373c93c4e") .. tostring(defaultOption or options[1] or __S("a50aed7a7ba0372d5bde")) .. __S("4342672bd804cbf4cc32"),
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

        local listFrame = new(__S("e179e0dc9e030f97ced67648f125c825483e"), {
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
        new(__S("7fb15a8d083c74685a3db5273bd41993"), { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)
        pad(listFrame, 5)

        trigger.MouseButton1Click:Connect(function()
            expanded = not expanded
            SafeTween(card, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, expanded and expandedHeight or collapsed),
            }):Play()
        end)

        for index, opt in ipairs(options) do
            local row = new(__S("1de8d43efd408da05027fb441b18"), {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.BgInset,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Font = UIFont,
                LayoutOrder = index,
                Size = UDim2.new(1, 0, 0, 25),
                Text = __S("bc204def210023") .. tostring(opt),
                TextColor3 = Theme.TextSecondary,
                TextSize = 11,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7,
            }, listFrame)
            corner(row, RADIUS.chip)

            local mark = new(__S("5a57c7a097c6db1615"), {
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
                trigger.Text = __S("f88f415143f1") .. tostring(opt) .. __S("96c6bb02d1701a8da1c7")
                for _, sibling in ipairs(listFrame:GetChildren()) do
                    if sibling:IsA(__S("34fe34b3338296a09522b26dd524")) then
                        local siblingMark = sibling:FindFirstChildOfClass(__S("d335ae645ee67c7f96"))
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

        table.insert(allSearchables, { frame = card, label = title .. __S("716d281542") .. (desc or "") })
    end

                                                                               
    function tabObj:AddSegmented(title, desc, options, defaultOption, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("0fa4a1c64e26d002eb"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 62),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or self.icon, self.color, 30, UDim2.new(0, 14, 0.5, -15), 5)

        new(__S("addc1b77ba8222a73b7bfce5fb"), {
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

        new(__S("4c1395284724b529865e921b81"), {
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

        local control = new(__S("ea4b0ed9779e0e643f"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -(total + 32), 0.5, -14),
            Size = UDim2.new(0, total + 8, 0, 28),
            ZIndex = 6,
        }, card)
        corner(control, RADIUS.control)
        hairline(control, Theme.StrokeSoft, 1, 0.4)

        local thumb = new(__S("8882888a6520e35501"), {
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
            local btn = new(__S("26ba023bb1b54feca1871a496f72"), {
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

        table.insert(allSearchables, { frame = card, label = title .. __S("c4f17bec4a") .. (desc or "") })
    end

                                                                               
    function tabObj:AddLabel(title, desc, height, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("6328f59d168cce6b28"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, height or 104),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgElevated, interactive = false })
        card.BackgroundColor3 = Theme.BgElevated

        iconTile(card, itemIcon or CustomIcons.Players, self.color, 24, UDim2.new(0, 14, 0, 12), 5)

        new(__S("01606f4e1e754fb76f149e2a1b"), {
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

        new(__S("9f97e8ff8fb49e267862491dbc"), {
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

        local live = new(__S("3dcf62b0ba6d37f7f6"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -66, 0, 13),
            Size = UDim2.new(0, 52, 0, 16),
            ZIndex = 6,
        }, card)
        corner(live, RADIUS.pill)
        hairline(live, Theme.StrokeSoft, 1, 0.5)

        local liveDot = new(__S("dc06dc61620e086497"), {
            BackgroundColor3 = Theme.Sage,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 7, 0.5, -2),
            Size = UDim2.new(0, 4, 0, 4),
            ZIndex = 7,
        }, live)
        corner(liveDot, RADIUS.pill)

        new(__S("7a3e5612b80d422105b45d7ae7"), {
            BackgroundTransparency = 1,
            Font = UIFontBold,
            Position = UDim2.new(0, 15, 0, 0),
            Size = UDim2.new(1, -18, 1, 0),
            Text = __S("1875cfc3e9cfb6e1"),
            TextColor3 = Theme.TextMuted,
            TextSize = 8,
            ZIndex = 7,
        }, live)

        task.spawn(function()
            while task.wait(1.1) do
                if not card.Parent then break end
                SkillHubStep(__S("b6ad497478a8bfec198cd63b7697da66d2"), function()
                    SafeTween(liveDot, TweenInfo.new(0.5), {
                        BackgroundTransparency = liveDot.BackgroundTransparency > 0.2 and 0 or 0.55,
                    }):Play()
                end)
            end
        end)

        local body = new(__S("54e4c325965a764aff462949ec3a01ed3862"), {
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

        local bodyLbl = new(__S("f31c3cd6611c20cd0080d8f112"), {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = UIFontMono,
            Size = UDim2.new(1, 0, 0, 0),
            Text = __S("9153b687d16c2cb8cbba7497f25f38d59aeed6aff44d3a"),
            TextColor3 = Theme.TextSecondary,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 6,
        }, body)

        table.insert(allSearchables, { frame = card, label = title .. __S("2f8b30381e") .. (desc or "") })

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
                if ok and type(txt) == __S("cdc2a9e925d406f612e8") then panel.label.Text = txt end
            end
        end)
        return panel
    end

                                                                               
    function tabObj:AddInput(title, desc, placeholder, defaultValue, callback, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("6bfa239ad8c646aea2"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, 58),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgRaised })

        iconTile(card, itemIcon or CustomIcons.Search, self.color, 30, UDim2.new(0, 14, 0.5, -15), 5)

        new(__S("0a319d4b3336adfa3ac3803a1a"), {
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

        new(__S("a86916fc13c083f6f9aa697da9"), {
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

        local shell = new(__S("46a090ad518f73e152"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -210, 0.5, -15),
            Size = UDim2.new(0, 196, 0, 30),
            ZIndex = 6,
        }, card)
        corner(shell, RADIUS.control)
        local shellStroke = hairline(shell, Theme.StrokeSoft, 1, 0.4)

        local box = new(__S("e4d80a5e23077ba5b9f17b"), {
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            Font = UIFont,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            PlaceholderColor3 = Theme.TextFaint,
            PlaceholderText = placeholder or __S("830f840fbc1fe54a0cc7766fa62ea355"),
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

        table.insert(allSearchables, { frame = card, label = title .. __S("2146fdc07f") .. (desc or "") })
        return box
    end

                                                                               
    function tabObj:AddPlayerList(title, desc, height, itemIcon)
        self.order = self.order + 1
        uiPace(self.order)
        local card = new(__S("bf7e7771df6ce50b75"), {
            LayoutOrder = self.order,
            Size = UDim2.new(1, 0, 0, height or 280),
        }, self.page)
        addFinish(card, self.color, { base = Theme.BgElevated, hoverColor = Theme.BgElevated, interactive = false })
        card.BackgroundColor3 = Theme.BgElevated

        iconTile(card, itemIcon or CustomIcons.Players, self.color, 24, UDim2.new(0, 14, 0, 12), 5)

        new(__S("5db5f122fe41dcfdb2dc08ec62"), {
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

        new(__S("fbed6ad3dcec7ea922459aa39e"), {
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

        local countChip = new(__S("9a24e48458d1169670"), {
            BackgroundColor3 = Theme.BgInset,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -108, 0, 13),
            Size = UDim2.new(0, 94, 0, 18),
            ZIndex = 6,
        }, card)
        corner(countChip, RADIUS.pill)
        hairline(countChip, Theme.StrokeSoft, 1, 0.5)

        local countLbl = new(__S("385c5e35ac75e433a0a14421cd"), {
            BackgroundTransparency = 1,
            Font = UIFontMono,
            Size = UDim2.new(1, 0, 1, 0),
            Text = __S("d693d7e6824e71646219564b20d8b3"),
            TextColor3 = self.color,
            TextSize = 9,
            ZIndex = 7,
        }, countChip)

        local list = new(__S("74cb5197d8b7b4a74b75bf6823f7b9573aa8"), {
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
        new(__S("1302cb4888629dc32c5ae5c318fb37b8"), { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        pad(list, 6)

        local rows, emptyLbl = {}, nil

        local function actionButton(parent, text, xOffset, baseColor, tooltipColor, callback)
            local btn = new(__S("b13a44f91ff97d65fd75e9a46ecb"), {
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
            local row = new(__S("4f71beaabe6b36de8e"), {
                BackgroundColor3 = Theme.BgElevated,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 56),
                ZIndex = 6,
            }, list)
            corner(row, RADIUS.control)
            local rowStroke = hairline(row, Theme.StrokeSoft, 1, 0.45)

            local lamp = new(__S("eda9385b0c0e1096b1"), {
                BackgroundColor3 = Theme.TextFaint,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 10),
                Size = UDim2.new(0, 2, 0, 36),
                ZIndex = 7,
            }, row)
            corner(lamp, RADIUS.pill)

            local avatar = new(__S("8be0b20c1a5c4ea391"), {
                BackgroundColor3 = tint(self.color, 0.78),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0.5, -14),
                Size = UDim2.new(0, 28, 0, 28),
                ZIndex = 7,
            }, row)
            corner(avatar, RADIUS.pill)
            hairline(avatar, tint(self.color, 0.5), 1, 0.55)

            local initials = new(__S("2a182bbd1eb5188febcc79d0db"), {
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
                        local img = new(__S("c84fa56eb68b6f460116eaf8fa77"), {
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

            local nameLbl = new(__S("66871f1f5991b2b55555be8269"), {
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

            local infoLbl = new(__S("04be98d016ee9c9be65e04a2d2"), {
                BackgroundTransparency = 1,
                Font = UIFont,
                Position = UDim2.new(0, 48, 0, 23),
                Size = UDim2.new(1, -260, 0, 13),
                Text = __S("a2f61281fe4715d78104ec6e81fb"),
                TextColor3 = Theme.TextMuted,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 7,
            }, row)

            local metaLbl = new(__S("412d8c32d3a4dc7357655b93ab"), {
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

            actionButton(row, __S("df6505e3bb6f10"), -186, self.color, nil, function()
                Config.SelectedPlayer = plr.Name
                notify(__S("7d9c7f94975132c27934fe764ada90e003"), plr.DisplayName .. __S("1bd3f94518596972a2038f665687aecc46e93003429d70d55c32f5"), 2.5, CustomIcons.PvP)
            end)
            actionButton(row, __S("ba0b72f617979d34"), -144, Theme.Danger, nil, function()
                Config.SelectedPlayer = plr.Name
                Config.AutoKillSelected = true
                notify(__S("5842eca78d2eeb127f75c00a6d"), __S("f67a665848eeb310f5c9633f") .. plr.DisplayName .. __S("94b1e00951e5803968f1fa19dacc81e1aeab8cfb5579c129e924166f12"), 3, CustomIcons.PvP)
            end)
            actionButton(row, __S("32e959baa1d4"), -102, Theme.Success, nil, function()
                if tweenToPlayer(plr) then
                    notify(__S("d120d36b3985e7daaff632d8"), __S("6f584d1c153030a1ebafb74fe5e0361b") .. plr.Name, 2.5, CustomIcons.Teleport)
                else
                    notify(__S("0d8fc6cdf2c372473579076f"), plr.Name .. __S("abc7407efad198f05c6a9edfd8573d452fa0921379608ea401aad95f6c2c5f"), 2.5, CustomIcons.Stop)
                end
            end)
            actionButton(row, __S("49feba2f718cff"), -60, Theme.Sky, nil, function()
                Config.SelectedPlayer = plr.Name
                Config.SpectatePlayer = true
                setSpectate(plr)
                notify(__S("e83633e036d44af6bc04b945"), __S("866dad91fd12be08b74752a0a7f6d5c2217f9f2b91") .. plr.Name, 2.5, CustomIcons.ESP)
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
                local hrp = plr.Character and plr.Character:FindFirstChild(__S("24a52742ac1b1ed00c104a5dc2f3194822aeb40f"))
                local dist = (hrp and myRoot) and math.floor((hrp.Position - myRoot.Position).Magnitude) or -1

                local giantTag = ""
                if isGiantForm(plr.Character) then
                    giantTag = __S("c2dca0f3f2c2cbf06f99adf22a")
                elseif isBuddhaUser(plr) then
                    giantTag = __S("61141aa424186f3b3c6d71cc1dea")
                end

                entry.nameLbl.Text = string.format(__S("ff4b945530b0e7f952f4de2efc833d7c16"), plr.DisplayName, tostring(lo.level))
                entry.nameLbl.TextColor3 = (Config.SelectedPlayer == plr.Name) and self.color or Theme.TextPrimary
                entry.infoLbl.Text = statusText .. ((Config.SelectedPlayer == plr.Name) and __S("9d830e06e7918f747d867e125aaa3ce0d1") or "")
                entry.infoLbl.TextColor3 = statusColor
                entry.metaLbl.Text = string.format(__S("3bba87b77703a6869ee84d1b86c48227a99549f82ce209c11a19aded835391192da145436656ca2041aa4a7e"),
                    lo.fruit, lo.style, lo.hp, lo.maxHp,
                    dist >= 0 and (dist .. __S("d9f201680a")) or __S("78297b1911"), giantTag)
                entry.stroke.Color = statusColor
                entry.stroke.Transparency = (Config.SelectedPlayer == plr.Name) and 0.35 or 0.55
                entry.lamp.BackgroundColor3 = statusColor
            end

            if presentCount == 0 then
                if not emptyLbl then
                    emptyLbl = new(__S("1660f4ca2253cc9c71f51cc237"), {
                        BackgroundTransparency = 1,
                        Font = UIFont,
                        Position = UDim2.new(0, 0, 0, 14),
                        Size = UDim2.new(1, 0, 0, 20),
                        Text = __S("b4986e7b9e8c1f0da113430b5a08c8e12e9c284b64bcdfbe09b6dc85d6c4dd67a464bd34"),
                        TextColor3 = Theme.TextFaint,
                        TextSize = 10,
                        ZIndex = 7,
                    }, list)
                end
                emptyLbl.Visible = true
            elseif emptyLbl then
                emptyLbl.Visible = false
            end

            countLbl.Text = string.format(__S("52cfe82ccc85be6c0713c46c7be9370ba7ccd80cf03919d64b8e"), #Players:GetPlayers(), presentCount)
        end

        SkillHubStep(__S("f10761dd530f90a1f5822323d473bc7241e5c791bcc0c38f58a0db055be3"), rebuild)
        task.spawn(function()
            while true do
                task.wait(1)
                if not card.Parent then break end
                pcall(rebuild)
            end
        end)

        table.insert(allSearchables, { frame = card, label = title .. __S("8f3edb8ea9") .. (desc or "") })
        return { card = card, refresh = rebuild }
    end

                                                                               
                                                                                  
                                                                               
                                                                               
                                                                           
                                                      
    for _, methodName in ipairs({ __S("2d76553f7664bdb2bde2f1415ea8"), __S("cbadcef0a8450952f6faf70cad"), __S("69e548a1b80a6e085c046eedbb"), __S("081cc252184fc69a70859e8da3"),
        __S("a6543c03887f268135a7315c5cb341"), __S("448bb5b4abdc893d6c37ed9179744d91"), __S("e2c32f65f3d6b97b9696f941"), __S("80faa916fbd955549b67bf0dc1207a1d"), __S("1f3222c7731e333027fdd285"), __S("bd699c782ad70eefef130bf1b1a080bd46") }) do
        local original = tabObj[methodName]
        if type(original) == __S("5ba116299d23f49a4d93122a") then
            tabObj[methodName] = function(self, ...)
                local result = table.pack(pcall(original, self, ...))
                if not result[1] then
                    SkillHubStep(__S("f9d88fdadea2f4") .. methodName, function() error(tostring(result[2]), 0) end)
                    return nil
                end
                return table.unpack(result, 2, result.n)
            end
        end
    end

    return tabObj
end
                                                                              
                                              
                                                                              

local TabFarm     = createTab(CustomIcons.AutoFarm, __S("9810098b3a2b54434aa5c45b63"),       Theme.Iris)
local TabPvP      = createTab(CustomIcons.PvP,      __S("3647833cfc968835bdffee6471c7158e62"),   Theme.Clay)
local TabStats    = createTab(CustomIcons.Stats,    __S("d47efcedcfa54c0487c2fd5d5a6c01e4d705"),  Theme.Mauve)
local TabFruits   = createTab(CustomIcons.Fruits,   __S("72b6769e6aa0a2e752d0f007b1063e1f55fd"),  Theme.Sand)
local TabTeleport = createTab(CustomIcons.Teleport, __S("10edf04fc987b82e3efd1ba32932d71f82682c"), Theme.Sage)
local TabESP      = createTab(CustomIcons.ESP,      __S("af256a0037b20aa305932bcd551751e982"),   Theme.Rose)
local TabMisc     = createTab(CustomIcons.Settings, __S("4d5ce3b1e928979fe803b4040599b684eceafc"), Theme.Steel)

                           

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
    { name = __S("eb945d62ff1ececf68b4833954"),       tab = TabFarm },
    { name = __S("89cbd71337df467b1b637fcc297c4a401b"),   tab = TabPvP },
    { name = __S("280350c4ba01e4522c99f75ab2164a7a0701"),  tab = TabStats },
    { name = __S("c63aca7569c7558fd130d5ccb32313a5aca1"),  tab = TabFruits },
    { name = __S("64724426a91590e013f791abf36f7afb6b36bb"), tab = TabTeleport },
    { name = __S("02a9bdd7dbf9a59d93edc4bcffa20bb204"),   tab = TabESP },
    { name = __S("a0e13788cd4efbfe9ed6cc6ff75a40da9a4ee8"), tab = TabMisc },
}
local tabCensus, tabSelfTest
                                                                                 
                                                                        
local UnloadSkillHub
TabFarm:AddSection(__S("3f18b139319280218e2a5b7bc4c2a89092282c2008344778f88348fac3202c9697f8be4ffb"))
TabFarm:AddDropdown(__S("dd502aea3be973f354471b4abcc86e06eaece3"), __S("7b87a49b6285a8020c4c6ad59108b642a5c62b52efacacee19fa5161825b04f95dca17a835de2c8c0c07024a3215dac2f7c219"), {__S("19bf1e4cda1efd5f28"), __S("b7f697fd0a9fe72a94"), __S("562e11ae8187da70562a5d5abb6b"), __S("f4658b5f9f23a4")}, Config.SelectedWeaponType, function(val)
    Config.SelectedWeaponType = val
end, CustomIcons.AutoFarm)
TabFarm:AddToggle(__S("929d0510a95ebfd575f296eb37716fb1b5b4ab99ef50"), __S("30d47ec1f3691539b286eea41a40b6d923a096b988389dc170b182f2258babc0853449a984686006fc36bf87802deb3911df8463b80b56af69aae2b24ad2a31286c29b44d96343aa6f0bf12b04de"), Config.FastAttack, function(v) Config.FastAttack = v end, CustomIcons.Lightning)
TabFarm:AddToggle(__S("cf0bf87231de04ad901bbbb82292d6f859b99d6670c4c9dd720790c52eb721477a4f"), __S("6d437223e15dd6fd744e997e46f2198504aac8475ea84019a1c9ea45316745e77877bc4ad5c41721d16a77512fe032e09c4633b95bab005c23d60b0dba7bae56c307d5bdccd2be98"), Config.AutoAttackAlways, function(v) Config.AutoAttackAlways = v end, CustomIcons.Lightning)
TabFarm:AddSegmented(__S("0b7aebd412340b5de09d1bfa8b96a3d59c06fe807b"), __S("a9b26585d4f7053fa1fec20ab898aa337a8c59d7778c766b735b09a948f48975c657aa50bcc5de"), {__S("47e9df364240641b76cf7668c8f8"), __S("e62158e71f8e727d"), __S("8458d2986e43b321")}, __S("22904c4923095a44"), function(mode)
    if mode == __S("c0c7c5fa55b62e4249f466f55d77") then
        Config.FastAttackDelay = 0.01
    elseif mode == __S("5eff3faba8648175") then
        Config.FastAttackDelay = 0.025
    else
        Config.FastAttackDelay = 0.06
    end
end, CustomIcons.Lightning)
TabFarm:AddSlider(__S("fd36b95c533b9fd526269355a49b2dc603e9a31808c6f773"), __S("9b6e330d874f6638c6c5331d36f7b25c600d9b5008b776b7f0526f6735341f48a1d9e6e24f9596c6c661e3ab786c5a6c2208"), 25, 80, Config.AttackRange, function(v) Config.AttackRange = v end, CustomIcons.AutoFarm)
TabFarm:AddToggle(__S("39a5acbe06ec341a936e1abf19f4e5502a62389c56e30777c32487"), __S("d7dd266f4edee6c8b651c31ea864f681766ab77ed9095a460d9ea9942c7be5c45b3634d3b1ddc17384b6f6f303c75f01615d79c19a0aee453c571ac62c92"), Config.AttackPlayers, function(v) Config.AttackPlayers = v end, CustomIcons.Boss)
TabFarm:AddToggle(__S("7614a02069fa2cf27c51b40858afa76ba13c"), __S("144c19d16bf1c21cb1d4356010fa7d51391f1ae54c9a76b497e53eb9ea11c50ee4729edd27aa2b20d612430a6189b778929fb07e1a"), Config.AutoBuso, function(v) Config.AutoBuso = v end, CustomIcons.Shield)
TabFarm:AddToggle(__S("b2839382d9622aec1de0f13ab44582d852f9856712f66149d0f4f949168a1f4c856433"), __S("50bb0d334db0e8431f052e8df24a702402a56a1a1d5d1255e5222907740977235e9559ee9289a0e696a7e675509d6d3565c0d16505be"), Config.BringMobs, function(v) Config.BringMobs = v end, CustomIcons.Layers)
TabFarm:AddToggle(__S("eef286e4db71e07ed85b310ed3090841cd06c0afc1800ea34f3be00acf46"), __S("8d2a00956c539a01fb390118ba62d3eb89352b5aac15780aac33c5f19962436277802d5cb4078baa88950a9a46b13c12bdb6650c591a39068340944c9221e673bcf771c8e1aea3691cc015462ac5532b628cc88cf6f20c497e8e83017c3331326cc85b6b30bcac57fb"), Config.HitboxExpander, function(v) Config.HitboxExpander = v; Config.HitboxMobs = v end, CustomIcons.Layers)
TabFarm:AddSlider(__S("2b617a465a534a2ef9d61bba474e607fac7c"), __S("c998f3f7d7ecb748cbee152c4bd973b4c4c7a080794b247a06de3119eedacac8ec9be95ffcddcc409965"), 5, 45, Config.FarmDistance, function(v) Config.FarmDistance = v end, CustomIcons.Teleport)

TabFarm:AddSection(__S("67d06da896659b663d01179d1bc518b754f81a1e437a26"))
TabFarm:AddToggle(__S("0607e7598e3bf8870b727f769a570c37f4591b"), __S("a43f610ae465f4775d08b0b626301abdb7f4108f8ab106d8aa70ec8f7e5c49ec6d74a985084708a76ca77d86332f88a2141727ee1fc6349154b211740c07ec"), Config.AutoFarmLevel, function(v)
    Config.AutoFarmLevel = v
    if not v then stopTween() end
end, CustomIcons.AutoFarm)
TabFarm:AddToggle(__S("4276dabb0a8537016ba37e1f6d303eec79994736ddecf82049"), __S("e0ae546c9bdc00d44428affb57058f91e8a58f97842c31878efd9dad7a24ec8336a1acebd9db8b276fdb13e75a3a8bacb6a5"), Config.AutoFarmNearest, function(v)
    Config.AutoFarmNearest = v
    if not v then stopTween() end
end, CustomIcons.AutoFarm)
TabFarm:AddToggle(__S("7ee5ce1d0f2c2e1a3037a5b0fc2e40c2b421900f"), __S("1d1d47cee8df5b553f116f8487a3e8f441546391daa808fe5a4af2eb51b4c27d1f2acf9acbcdba14851a46e140be24c2c292"), Config.AutoFarmChests, function(v)
    Config.AutoFarmChests = v
    if not v then stopTween() end
end, CustomIcons.HubCrest)

TabFarm:AddSection(__S("bb54c17fc0eb08117f8452845b1516d5c4c75256b21615c8929f292004624915b59b") .. CURRENT_SEA .. __S("598c3b30c5ffbe000585eb3cf3ab"))
TabFarm:AddDropdown(__S("f7c3b4e1dde1137b27d036cf42b95790d57b9cc95203"), __S("95fb2e920331733d7c65628a6d17218f9099e59f28b00e6d7ec0f23f19e66daf9d5c281b28267e0f4f5799c930"), BOSS_LIST_ALL, Config.SelectedBoss, function(val)
    Config.SelectedBoss = val
end, CustomIcons.Boss)
TabFarm:AddToggle(__S("3432a8435fc87421b1c834a58334e43487b3e296a87b141d371c58"), __S("d26a21f45f7e7e2da754664340456d5568fb23b9ba9bd22fdf4050abe4d58299904f663e161774e42dbf8e8776fcfea1ca9947b7"), Config.AutoFarmBoss, function(v)
    Config.AutoFarmBoss = v
    if not v then stopTween() end
end, CustomIcons.Boss)
TabFarm:AddToggle(__S("70a19ba5ee9b79639e06d41e57ce3542569663af566cc25c47828e28"), __S("0ed91556cc5b7c8468445076a8bb444c61674437e8dc25c44409a8f6ab07a38e5da15d4664c4427e39f204f1c80f8d814457a0"), Config.AutoFarmAllBosses, function(v)
    Config.AutoFarmAllBosses = v
    if not v then stopTween() end
end, CustomIcons.Boss)

                                
TabStats:AddSection(__S("ad108f07ded8499db12454b88206e2705a9123c3bff312c106"))
TabStats:AddSlider(__S("4b4808b8279284f878aa5245dda473cda5d53a"), __S("e97f8269a3b83c81d80d89c0204f4bef91d440c76129dc4332bd1764961bded3e30cc5"), 1, 100, Config.StatPointsBatch, function(v) Config.StatPointsBatch = v end, CustomIcons.Stats)
TabStats:AddToggle(__S("87b6fc1a41564acf090364646f2d"), __S("25ee75cb216e54b24ede0dca586c44beefa24b02d7cc88c575dcdc753aed4b157f13b48b632c58683c8fe236874ff7"), Config.AutoStatMelee, function(v) Config.AutoStatMelee = v end, CustomIcons.Stats)
TabStats:AddToggle(__S("c425ef7cf8c7340fd5d32bed54fa2fd4"), __S("625d692df0b958fd52a346bf923f9d041f49fd39b6a612434a1870c3f3316028495814afaa46485cc56325943609139371"), Config.AutoStatDefense, function(v) Config.AutoStatDefense = v end, CustomIcons.Shield)
TabStats:AddToggle(__S("0094e2ded8e43b7d53c962b9b900"), __S("9ecc5c8f40a1ab9bf13631eef6fb41571e9767be3c266615de9120d442322bb97d223c040bb18ae03a43a1069133f7"), Config.AutoStatSword, function(v) Config.AutoStatSword = v end, CustomIcons.AutoFarm)
TabStats:AddToggle(__S("3d03d64044dad56850df75a1"), __S("db3b4ff1b258b97160d89a52a8e4eba97685d1f81a589f3e660bc4ff79a7edeb59179a5c332aa62c3ad103ecd9"), Config.AutoStatGun, function(v) Config.AutoStatGun = v end, CustomIcons.Lightning)
TabStats:AddToggle(__S("7972c9a2e0247cceaaf9b05388c846f17657f4"), __S("17aa4353922b49a147c68bcfa5cdd7a29072a5918b2235d1277e18242996875d2fb26d813dad67808012ca6ce2336be5fba1abd5"), Config.AutoStatFruit, function(v) Config.AutoStatFruit = v end, CustomIcons.Fruits)

TabStats:AddSection(__S("b5e1bd04e54c44b52408081412c944965905990c53f53a5ba9a67f1fb2e246c6cc31d9b750094b63e0bac29a97"))
TabStats:AddToggle(__S("541936b5d3e37d1b7496971ef12d4159884a679cb64394"), __S("f250b06609274a3a9937976546b6b2f28d64a39deb8d900b05db9aa136e52adf990ce320c8532791fee1b14e8d9c31100f8be7"), Config.AutoSkillComboZ, function(v) Config.AutoSkillComboZ = v end, CustomIcons.Layers)
TabStats:AddToggle(__S("90882a17f3e111fd2ff71f51456401c4ab09ddc323f357"), __S("2ebfa3c88a0d9cee89b342225e00293a10c06ef2c48d9abf109137e724a5d22f3efe27ff6bab0cc09e82d59aac82dd986808d2"), Config.AutoSkillComboX, function(v) Config.AutoSkillComboX = v end, CustomIcons.Layers)
TabStats:AddToggle(__S("ccf71d7934a992d7f9c5254f1aeed6d5039483a18e4e48"), __S("6b2e972a6e25796260baa2d75762025fb35d6ef90cb5440ca3a44d9f8031c7ec860fabaed5145950b0d285308ffaeadddbb5c5"), Config.AutoSkillComboC, function(v) Config.AutoSkillComboC = v end, CustomIcons.Layers)
TabStats:AddToggle(__S("096610db84834d159719427f710cc0c647f903a3a9e3ba"), __S("a79d8a8ceb736b603feeba8a451e87e6d8e4a80c55f5d470f3a2862a22963b1f2efd07dae916a5184001e7e8ca117bcf34eb58013bea66cf2c75"), Config.AutoSkillComboV, function(v) Config.AutoSkillComboV = v end, CustomIcons.Layers)

TabStats:AddSection(__S("45d5043d5c904ae6fad86bd4c2a51dd34e345b5a8e71faaf0731403fee91490e"))
TabStats:AddToggle(__S("e40c7deeb78cd9183815a18aabc1bb15421223ce02f0e11132c36038"), __S("8243f79f6c6e3fc26f9fb6f6c21728dd9f950ebb61c463257b65d4248c27175e2a706d92da87069bc9177742db2d"), Config.AutoKen, function(v) Config.AutoKen = v end, CustomIcons.ESP)
TabStats:AddToggle(__S("207b715039e76b13651104fc50ad3e66560183ee7d9f5ab1"), __S("beb2eb01a9a12e31476e8a800fd851067f6750183de4fc76fce69ac0087458abb58ce1d4a94edfc548fba7907cd3eea0"), Config.AutoRaceV3, function(v) Config.AutoRaceV3 = v end, CustomIcons.Lightning)
TabStats:AddSection(__S("5cea64b24f4fb10be98b8311ab6beb71f3aa9c76e89fae314a85c1"))
TabStats:AddToggle(__S("fb21de63fe1cc5e54b1e4a477861d7203828d8d399ea289f51570d9b17f32dc0b0e7"), __S("995958144d3fa8273b7f7c894a30725e4e4a0bf47b333b368f0f7dbe1f1926677e5faeea37eae60fed4c98b59bc856e4fe55a3fdd69f440064383e71"), Config.AutoAttackAlways, function(v) Config.AutoAttackAlways = v end, CustomIcons.Lightning)
TabStats:AddToggle(__S("3790d1c5625f1e3df4fe3535cb0a5aabd9d55cf87472829a549483"), __S("d5c84b76c6cc382bba7bb2fae801f7fa688623c81138efdeb1123c492b5f83d26d6b1fb66dd93e10c973bf37e12a521c84cc9db8f337"), Config.SovereignHakiAura, function(v) Config.SovereignHakiAura = v end, CustomIcons.Wand)
TabStats:AddSlider(__S("73ffc5278b19ebe711cc6159853ffb66a9c28e791433d96c"), __S("12373ed8a3f74c07bf4359d3be0161f53546faf6466dd9a4ab374d9bd884dafa1cf013667d3cae2f2439c7e6d0cf89ec11ace0646011943a200992ac"), 25, 90, Config.AttackRange, function(v) Config.AttackRange = v end, CustomIcons.AutoFarm)
TabStats:AddDropdown(__S("b06eb889b0851990f63b31632d3eaff21ac6c45ae2acba5aa1ec7c"), __S("4ea6323a5c88d91c1db723869d33dfd2a44ae4dca9f740600ff9b45eaa7890b3151353c38ea3aa4cc4b961cd3bf8fdae958b70542549398aca63ecccdeac08e5ac02b98d1f3f3179"), FIGHTING_STYLE_ORDER, Config.SelectedFightingStyle or FIGHTING_STYLE_ORDER[1], function(val)
    Config.SelectedFightingStyle = val
end, CustomIcons.AutoFarm)
TabStats:AddButton(__S("ecddabeb08f76b7f5756d6a7d0972fe5cb2c6f2cf14ffcc1e5338d4055"), __S("8b15259ced78e119595f02cd0f4b3b1955f7c998fdeedef20af09a94d047d8534fd3c1dad4db8631b549d49f08bb0b49570dc6cbc94cf12c796b8bc8670fcb4c002b377e5f157a48043549373a838ea6"), __S("294c9f4dba1586bf3e2a8c9320"), function()
    local style = Config.SelectedFightingStyle or FIGHTING_STYLE_ORDER[1]
    local ok = equipFightingStyle(style)
    notify(__S("c78418fe9505bc27023aa00c01c6176094ec"), string.format(__S("65bb92af7dbe67333b"), ok and __S("03f30c60fa699d2f15e0a0a3") or __S("a22a861197653b32da95c09794"), tostring(style):gsub(__S("4061ffc2eb35b1ca9708a49dfc22"), "")), 3, CustomIcons.AutoFarm)
end, CustomIcons.AutoFarm)
TabStats:AddButton(__S("de997973eec020856b2aa1beebf90fb71f010d3ea630f39ee1b71075429be8c70fd0"), __S("7cd0f324eb68433a84a3e8cd12d3594577d60a0134e3c6737d8e4ee47f7c4f0b36e9152e5ea481f8e007e6fbd01282280ce4f16c4560044077dd41d3dd0258ef1377cca1f468316d69d6db"), __S("1b086cd55a57d2f52dd4ebcc1bfbca"), function()
    local ok = equipWeaponByType(__S("b93fe6861cf64e040f"))
    if not ok and getHumanoid() then
        local char = getCharacter()
        local hum = getHumanoid()
        if char and hum then
            local tool = char:FindFirstChildOfClass(__S("577760373be38409"))
            if tool then hum:UnequipTools() task.wait(0.1) hum:EquipTool(tool) ok = true end
        end
    end
    notify(__S("f5aed9e8ccb96659e46739b09e3f8e"), ok and __S("93e6539975763d22840f8215d5db311c7e7afd2c0a5ff45345ab2d8fde931ac2") or __S("321dcd4ade200b4d0b754e2991c7ae8e6ecd6b2e4d82058d9d29daf058d35c39"), 3, CustomIcons.AutoFarm)
end, CustomIcons.AutoFarm)
for _, style in ipairs(FIGHTING_STYLES) do
    TabStats:AddButton(__S("d05546fb3b9ccf541671") .. style.name, style.tier .. __S("6e8cc0acc04137a97d154d") .. style.remote .. __S("0cc43a5dfaad2c25c92f0f85aad5e924e4103c7db0ed0d670b201caa7bb9fccaac"), __S("aafbb40e003dbe1730eb"), function()
        equipFightingStyle(style.name)
        notify(__S("49332dbf1b9eb78c6882a2b48c5773d5bb80"), __S("e76aa770a1875792dec50e6909db7596") .. style.name, 2.5, CustomIcons.AutoFarm)
    end, CustomIcons.AutoFarm)
end

                               
TabPvP:AddSection(__S("85a22121e308054b94534fd7f125d61652681c007e064c9badd3b8372811a4ddc26c31"))
TabPvP:AddPlayerList(
    __S("23d99ad2a0e5f61176b0b6a09a8770854057"),
    __S("c2111483e26c6f4507704a95e05badcc46ebc0f87d4e3be36892ab1b5d2c3ce56b689180be65fc19ec7fc4d335d2c977a74f6714b2f5eeae5c550fd41a88e13c58a334a35aeab3d65a158902a1916ab5676f690721a55024ee206557286f2434c3ed80434c00e471bf3e469a20e54c4df4459200206403bd5f4d0ae0d18e7faf722e6f71504bed7528321dcdcf0a4e7a"),
    286,
    CustomIcons.Players
)

TabPvP:AddSection(__S("60488e34db9152ac2437a7"))
TabPvP:AddLivePanel(__S("fe8007e5eb65d6b8516880805543e4"), __S("9cb781962561183a7aed67b91aac48178afeccbdb17024c696934f1184a02d3d582687fa2d0139a0a2014666597a1c3275"), 30, function()
    return "RightShift  →  toggle Skill Aimbot / AimLock\n" ..
           "RightAlt    →  toggle Undetected Bypass Fly\n" ..
           "LeftCtrl    →  park the fly (stop dead in the air, press again to release)\n" ..
           "RightCtrl / F9  →  show / hide the Skill Hub window\n" ..
           __S("3aeefb475761d86f28393125f64e0fca4ab79f0172389205007e63ae4937ac340308c9dee2af761fcc803e5fb2bc8957db1995369c9350b858954bce")
end, 96, CustomIcons.Aim)

TabPvP:AddSection(__S("d92674f8f094b9309311a609d0298cc5ad"))
TabPvP:AddInput(__S("775deea919665957802e296d2f1e27dc0c75c65eb433"), __S("1595685ae1cf8ebf488ead7cb26dc7918da90efa4d94bcb55b7199863a4a54a18be0ee063108cd4f10a5895b9adc18dbe1a461316ea1"), __S("b3cce20b38473233a00af5738cef14"), Config.SelectedPlayer, function(txt)
    Config.SelectedPlayer = txt
    local plr = getPlayerByName(txt)
    if plr then
        notify(__S("52045bbcf19ca587aef17a647e4ed3a4d6"), plr.DisplayName .. __S("f03bd56dc6e9043e228d083da35830a979a4bbb271bf4e867d9bd0"), 2.5, CustomIcons.PvP)
    elseif txt ~= "" then
        notify(__S("8e734f1e42d1721fc256"), __S("2caac8cf983cad8a7ec9809f4db95501d717056a0f28b0") .. tostring(txt), 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Search)
TabPvP:AddButton(__S("cae24280b5802565978c8ba4176be335b6eede98041a4d"), __S("6919bc31ed846808558ed4e56c46004ab1abd28cba2780a6e5b836e963a62f7111936ead77258ed45552fb9619139651ea25989facb9"), __S("075135e2d80244744999b5af7eaa2a3e"), function()
    local myRoot = getRoot()
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild(__S("a588af93262959dab07bc5e0ac90ac196d2964da"))
            if hrp and myRoot then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < bestDist then bestDist, best = d, plr end
            end
        end
    end
    if best then
        Config.SelectedPlayer = best.Name
        notify(__S("43c02944648e7506223ba15c30bfc8a7b4"), string.format(__S("e1f7a2f524564436452faa40447a7f183d14"), best.DisplayName, math.floor(bestDist)), 3, CustomIcons.PvP)
    else
        notify(__S("802f1ca64f186ac78538"), __S("1e6696576f5b354ccdae63421ab2b30a11802e15adc780777bbc"), 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Play)
TabPvP:AddButton(__S("bc9e1008f317b1d08c750481591109f674c5fbf858e1186ec5ca20938756"), __S("5ad589b909ae80c0bf09666d53463d3deb04b8f26e5a669ebee95f666697f1d7d3ea0533d6ac097264a7f4d971b3925281a84b98a24e12"), __S("f90d036aceb2a812225a0ed0"), function()
    local plr = getPlayerByName(Config.SelectedPlayer)
    if tweenToPlayer(plr) then
        notify(__S("97447d1b3c4900592fab54b2"), __S("357bf6cce975801b18ba4a7765197b5a") .. plr.Name, 2.5, CustomIcons.Teleport)
    else
        notify(__S("d3b3707d973c8ca6dd5069ad"), __S("71eaea2e0da9eba2ef9ca1ec9ee078025f5fb056eb00202287483a84190e9989d49c73f17d"), 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Teleport)
TabPvP:AddButton(__S("102263dfc0ecdae9cb5a3fc03cf2977f38e775"), __S("ae59dd9089fad217582bff7531819f1f153d1817c5b5ee658eec52d38b4e2819166bd3c6f01925d1a3c8cdf236"), __S("4c9157418eb8d6c7c263d7ce"), function()
    Config.SpectatePlayer = true
    setSpectate(getPlayerByName(Config.SelectedPlayer))
end, CustomIcons.ESP)
TabPvP:AddButton(__S("eac8d0f2ea932131be2b452055efe3257879eb"), __S("89004aa3fbfa504d3c24a3c688f1027d21bb4aae81cf1f12fd04757c0a8f158c65debd1d25a465c57018cdd3"), __S("2737c454995e9705"), function()
    Config.SpectatePlayer = false
    setSpectate(nil)
end, CustomIcons.Stop)

TabPvP:AddSection(__S("c56f3e05421a33f13c0c752631cd10a4bc731ade466464969570e9b2a4e4"))
TabPvP:AddToggle(__S("63a6b7b69fcc406327e2d65f72110ef40fc792159bc90ab73dea7f7c24"), __S("01de316710d6acdbf8e48b4f8f906e9dec89054dc649b1b8a6d1701cad387b00981ad3fd2d7683fe3ce4a1bf14e575988055dc9a34f26d78916024f5f679352a80e9f0e035ade9956a445dc8c59bbab0a3c3"), Config.AutoKillSelected, function(v)
    Config.AutoKillSelected = v
    notify(__S("a015ab1893f8134893d784ae94bf"), v and (__S("3e4d24c98b641e52dd3a5a22") .. tostring(Config.SelectedPlayer ~= "" and Config.SelectedPlayer or __S("dc849e7a51a371b376bf2c"))) or __S("7abc182b44dfb05e9ae6713fb56447523dbded0350fbeeca585e521dc26f5dcd7fb447"), 3, CustomIcons.PvP)
end, CustomIcons.PvP)
TabPvP:AddToggle(__S("18f391dcf9b04e8821a84a49580007fb67975afbc63eec9793fb32b2c646c98dd3"), __S("b72b0b8de17e9bf8f34fe4f992dcd7876019caa39df093e5a482acb9282799450ff3593f0cbe1c54b9ba42eb8263198dbb86a4e6b7f6ac2053547c0de65e99fec71b619e34804b7409a3cba82c"), Config.AutoKillPvP, function(v)
    Config.AutoKillPvP = v
    notify(__S("5562853e0cb923c465c3b1573540"), v and __S("f399feef25ab6394fcdf8e046651e6e01c08850381e93b4b24a551eed365984fc730ac") or __S("91d178a0d27c29b0eb88d704980440efda67732e"), 3, CustomIcons.PvP)
end, CustomIcons.PvP)
TabPvP:AddToggle(__S("3008f25139ed056ce74f00f5dae5f1a53ed3"), __S("ce406c02f1b719086b40761e35fb768f77d89b5233215622be4dbcd953cc24f735ba02ab20a334567d293f"), Config.IgnoreFriendsPvP, function(v) Config.IgnoreFriendsPvP = v end, CustomIcons.Shield)
TabPvP:AddSlider(__S("6c77e5b3fb5b23868c812ff3157f63735b0a"), __S("0aaf5f6436fc8746e44cf1dfc62914689abc726494e00642909658d8548d5244951110c94ab7f9fdaefa2208be2437a51cc9be915ef00aeeb523362f84d943942ad1862d9766521ba8d2f20b33d239dc54c3"), 4, 30, Config.PvPTweenDistance, function(v) Config.PvPTweenDistance = v end, CustomIcons.Teleport)
TabPvP:AddSlider(__S("a8e6d9155c39714b7895f3b192c0ded32694367d"), __S("471e52c68413cd348fef57b4cb67ac07e9cd97c58b1ee49ec29bb8a2425f31cb25be26fef0c73e7e062e720144b90439589c94a32f"), 30, 400, Config.KillAuraRange, function(v) Config.KillAuraRange = v end, CustomIcons.Lightning)
TabPvP:AddSlider(__S("e555cc771ba6669ee7365b864a2df0cf87d3f6c8b1cd14d1ed"), __S("838d46285fc87f007a7a62c3f6d11dfb4b69616746d88f2f32ee08cd2fca3d5a4b6cbfa80c7aface04c1f4b1685cd4e168e7700633aafbad8d5ae2c562eab15132b130f4d93b9511fa1edabc3927e72bde134e5e9970d81408"), 5, 50, math.floor((Config.PvPAttackInterval or 0.08) * 100), function(v) Config.PvPAttackInterval = v / 100 end, CustomIcons.Lightning)
TabPvP:AddSlider(__S("21c4bfd955ee8ac1a45414c9e2f37d9cd8badd0570f84356"), __S("bffc398a3f7f6b3afe467da96f62bda05da6850acb98d8b5cfea8b5ee1d5d4f542e521522d0deb56ea4d4b8cefa9c353b98935d7dd1c"), 15, 100, math.floor((Config.PvPSkillInterval or 0.4) * 100), function(v) Config.PvPSkillInterval = v / 100 end, CustomIcons.Layers)
TabPvP:AddSlider(__S("5e33b33b79f1920de74ce9752cd0b4be430c8ac5066f21"), __S("fc6b2cecb295cad091f757e4de26d62e1352702f0d85affbb9362be0ef4ff84f1aa27f8f9c51710d251123c1c0e5ee049ef0dadeb5902cfd6966eacf29c50acb6678fcc365036bb166fea9"), 0, 40, Config.PvPHoverHeight, function(v) Config.PvPHoverHeight = v end, CustomIcons.Teleport)
TabPvP:AddDropdown(__S("9aa2a69d517afc5e11e0b74e9de425a7f9e81a"), __S("38da204e8fb0e573f70bf0b3f6be08af2d6c9670a4d039586ada5cef7e067e513c88553f7f3ba64f"), {__S("d71199ffa634bf9a3b8906"), __S("754913b083f019458aaab3f771"), __S("13808d61c047bb5c830bb5")}, Config.PvPTargetMode, function(v) Config.PvPTargetMode = v end, CustomIcons.Players)
TabPvP:AddToggle(__S("b1b807121e63bf089665a774fb27ca2a0a13cd90f83e4e0c562b22c5f999c446"), __S("4fef80c3733eafec9ece77b12f0abf933b5335d3db9fbd298e1f434425cd648bcef3d31771458b323b3a2ac8e775b5d4442d61511668c4c998ef09b3a07857194a8c4d152eadd43e80165fdaa802a0f6415170e734425851ec"), Config.PvPAutoAim, function(v) Config.PvPAutoAim = v end, CustomIcons.Aim)
TabPvP:AddToggle(__S("ee26fa7481ebbacdec1ea7faef0b79377c808320d07d65bb770d0f8a124a442db5a1faea4721e67b08ec061f"), __S("8c5e742501e8919788bd98616889314a54db5a8c2ccd4b2fc889da1963979ca1317ead6969d0850a92d5b80dfad99bd68d6cf1739b56eeb78939d3fabceb573f725955a200fa74fa4c904124b9382f4b0b160cb78f6c"), Config.PvPFallbackNearest, function(v) Config.PvPFallbackNearest = v end, CustomIcons.Search)
TabPvP:AddToggle(__S("2a95edd620535f45b49e4ae3d4b2f5942c11909386a981ee9e85e80aee49247ede48d98e4eec55af"), __S("c8cd6787ff9eb22fa7e65dd8c86e7860ae266923dc19d276384800d97201de97df0a2ba56b22169d91af27e0cd"), Config.PvPSkills, function(v) Config.PvPSkills = v end, CustomIcons.Layers)

TabPvP:AddSection(__S("6704e138daf20f8d70864f7ed9ebeea716702b85878cc391eb78"))
TabPvP:AddToggle(__S("053c5ae9b87cfb798af5c9ddcc638fb9f26e3c2a6c9e2c560be32f0311e9a8e1de08"), __S("a373d49a790a683ac831ad3b3172476fa6c9175459ecd0a38908db219ec0fc7664e60300bd7b355fae1e46b58c733135a46ae30ec03087e49bd76d48c4c9d23644cb772614"), Config.AimLock, function(v)
    Config.AimLock = v
    notify(__S("41ab4e4b69706544f43de4e467521858"), v and __S("dfe2c7fc7346d7a9c04c1d951ae2cde1135fdabef92ffba90016dcf9a1beb91a70cd6cf7afe34007") or __S("7e1a41adbb04187d2472782d9792fb3cfc1f1706"), 3, CustomIcons.Aim)
end, CustomIcons.Aim)
TabPvP:AddSlider(__S("1c51bb5ee2dbede8b4afefe959b59b3c282c2289a58d"), __S("ba89350f4361f8c794c9acc75e0f7126c4a1bdc3f00c809f39c8026cd6cb86b863e15a6971b1bcd951643e287dff35470198"), 8, 100, math.floor((Config.AimLockSmoothness or 0.28) * 100), function(v) Config.AimLockSmoothness = v / 100 end, CustomIcons.Aim)
TabPvP:AddSlider(__S("58c0aec08d3d8220b80a96a32e8b1cee3c55fa02e43421"), __S("f6f82871837d81bf3b81899ce4ca38d38125eb5013685d6e017c7def03d1b69927846dd45991770a05"), 0, 2000, Config.AimLockFOV, function(v) Config.AimLockFOV = v end, CustomIcons.ESP)
TabPvP:AddToggle(__S("952fa222271454687f2962c8deda284a03c9f4be621808d6468b"), __S("33671bd334eb8e3bb859712130c68dc0d7068038334ea116ca6ff400afac2531865ba73026f67c7051181001748acef443712df83270beca01ea89923ae6e54417fa3375aef2"), Config.PlayerHitbox, function(v)
    Config.PlayerHitbox = v
    if not v then
        for name in pairs(PvPState.hitboxOriginals) do
            local plr = getPlayerByName(name)
            if plr then setPlayerHitbox(plr, false) else PvPState.hitboxOriginals[name] = nil end
        end
    end
end, CustomIcons.Layers)
TabPvP:AddSlider(__S("d19e95843b4b4d070060e1806a79d47d2c3e19f0d9b8f2"), __S("6fd60f35c87a3ca9bb172c4e17b69d7fcbd0b4bbf4ca82d70584bbf9e13995a5220b2d182ed80dfcb0688bc410e2fc2468cb0a55129d81a6cf06814fa9a456d4c9c6fe2c139104ffe89f9972ad38e9993b96f83f45238e1b2ddfb36df716b53529652acd02d45aa8"), 6, 200, Config.PlayerHitboxSize, function(v) Config.PlayerHitboxSize = v end, CustomIcons.Layers)
TabPvP:AddToggle(__S("0e0d88e6eb457fc3f9f7b5249ff515d4692bb3e8458fa9850d3fd7dd8a2ef5effd89"), __S("ac450297557613220d0baf26e47e6978f7cbf475a9bbb102d1154ec1315d80815db1c1219da1fef4d85d694aab1e163a564e34a107d844611488417d6051d75eb07920202acb168952c9f4a810ebe6f4aa03fc"), Config.ExpandAllPvPHitbox, function(v) Config.ExpandAllPvPHitbox = v end, CustomIcons.ESP)
TabPvP:AddToggle(__S("4a7c7c48b3623ab5dcf8f68ec2d7afc6d9aeafed53f1dcf37ff2214470f75b4b63"), __S("e8b3f5f959802d311660fa73118ae125ca42ad9647e69852c02e38925380d9bca130c8e7da83eb277d820d1fc80f3d5038ab10c05f92"), Config.AttackPlayers, function(v) Config.AttackPlayers = v end, CustomIcons.AutoFarm)

TabPvP:AddSection(__S("86eb6faacd8ed5efd5a09a5d1ea8c4462e39634af7ff1699dff22465fdb89ceb0a3b100af6487742202ac61c5337"))
TabPvP:AddToggle(__S("2522e95bfdde5a56b95aba944d55b0e979a8c504183062909bcc6ef9a40ffb"), __S("c35a630cf53835b16fb5bdef824df6492bdd5613680addb545937c528fd26216e815eac3b59f841be07148758113f4a07512ff912422b49b58ea0f49c994919916308787100fe4bbff0b7bd4da6cd8d464922dcc2ddc2f4ec21c25a4525267d50e4967ddfb42787d60a261db37d2f88a82"), Config.BuddhaAwareCombat, function(v)
    Config.BuddhaAwareCombat = v
    notify(__S("6191dcbd3ceacdafe81d56ec049a46b859"), v and __S("ffc9566e2b3ed65b01b23db2e16d1e57b546bd016085912839d5c4a7038a984d775796b43d5e") or __S("9e00d01f8d21b0e27ae2cd9fb61a9d4b3ccf3ad531d16f6166f77c51901d89c2"), 3, CustomIcons.PvP)
end, CustomIcons.Shield)
TabPvP:AddToggle(__S("3c3849d03a6b3828fba1614f8e423ca6b8552ab452f405d916cf6be3290e8a7e7e95e2"), __S("da6fc3810fbfb25c7073fef616b2575c4c30c04a6187f2095b0f3966065ed90b2310c56ef5b77f91ee7f0351997fae1784dc32f11caacec5d0868640dd3cb66c02d0426f9711326b09e5308d8baa7ef24653b6"), Config.KillAuraAllPvP, function(v) Config.KillAuraAllPvP = v end, CustomIcons.Lightning)
TabPvP:AddToggle(__S("78a73d32a186051c762a09e0f30b70ffe29e29cac7cdedbf7e2d"), __S("16deb6e3ef038f338f99a3e2c8b6accd1dc1b5d023d6da510fea7076aac27982928a82a9798bb4b78fdd19a4f9296f82ede5e1ce5e31325e33aee0efe3b2f29bda0a40cbd4ed5f71e51948d85b16"), Config.ShowHitboxVisual, function(v) Config.ShowHitboxVisual = v end, CustomIcons.ESP)
TabPvP:AddToggle(__S("b51630949bee0fa4101a2a0b0d1b3db97f47e8998b3dbf"), __S("534daa45ee86a73e9240dce36a6cf189ce61ede171ca8d84248452f667df43940d06f56965d948d3eda5ae6798c1c86701374439467cb0e0be839d55f4a8adc519e40b9a49cfd19b55f4a81e4e5ba2e7b2"), Config.HitboxMobs, function(v)
    Config.HitboxMobs = v
    notify(__S("f18523f6264396560e614750ba09"), v and __S("8fbc9da78ed3aedeadba4e7f209ad85b712fe993014a3aa2fd") or __S("2df417587a60cbd038bfa5af37c019cd0c2e28784d173b689e"), 2.5, CustomIcons.Layers)
end, CustomIcons.Layers)
TabPvP:AddSlider(__S("cc2b9109c150d335a2da4b0592083706cbe4d1"), __S("6a630aba68b9bddd21bf89e4e03ed6758ccb54d54ce4c465d0afcc225dba147af5d4b5c729702d8116048eecb9c457fd35ddd6c6b1a5194b0348aaf075f718a3d7f0b5f036c7f1c169cd125932d19b"), 10, 200, Config.HitboxMobsSize, function(v) Config.HitboxMobsSize = v end, CustomIcons.Layers)
TabPvP:AddSlider(__S("089a846b2d1e1da212f729b241b392f984a77805"), __S("a6d1fe1c7a725553c228a0c0f8a74189594924c73dce521cad8d44fd1b575ca3e7215def7a5467c686e77b4dafc089"), 60, 3000, Config.HitboxMobsRange, function(v) Config.HitboxMobsRange = v end, CustomIcons.Teleport)
TabPvP:AddToggle(__S("450977cdc609a611c51d3dbf616af172b49ad0599aaa9301bd"), __S("e340f17eae366f5ec7c34916c3a3c9676427de2a00d3bab0fc3b9e3993cbdf9f84107ab9f3a6a475d073ce3b4b4fc9dc1f1dd1dc69aaa1991a7f0e4cc35fa122b578ceaef2cc3ab7beee05ab1912668f7f374ff20ad20457603d169ea9c4baade86ace90add18e414527144b6ce4400d23b56f00da"), Config.HitboxWholeModel, function(v) Config.HitboxWholeModel = v end, CustomIcons.Layers)
TabPvP:AddLivePanel(__S("81786b2f435627a6d5d93e48daeb928f916aa1320bc6a30190d0"), __S("1fafe4e035b50640cd22e92ad13ddc77714a88297b6a8f51d0bcd85487e4993fbd885fd7e05723f7e71d3b68fa"), 1.5, function()
    local lines = {}
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local _, size = getCharBoundingBox(plr.Character)
            local giant = isGiantForm(plr.Character)
            local buddha = isBuddhaUser(plr)
            local hrp = plr.Character:FindFirstChild(__S("bde75e91a3df5711c1ef351f1fa5fd5748369593"))
            local dist = (hrp and myRoot) and math.floor((hrp.Position - myRoot.Position).Magnitude) or -1
            table.insert(lines, string.format(__S("5c1ed842cc72e70527a3244a5a395650792dd2081b7209b18068e6db79a10da4293cff51e686bd62f3b1a7c95593"),
                plr.DisplayName,
                size and string.format(__S("fa5651f302cd42977437b9ff62"), size.X, size.Y) or __S("988dcba467"),
                giant and __S("36c5455565646b97c64fc6ca28d9") or __S("d4fcbf06e634916b9caa"),
                buddha and __S("733438b74673277f27d009f2d7762039356c") or "",
                dist,
                PvPState.hitboxOriginals[plr.Name] and __S("116bb268def12eee44312037") or __S("afa32c1947725d195634")))
        end
    end
    if #lines == 0 then return __S("4ddaa5ca553ac3081ed11ea58eb436c34f5ba8aa5528d4b69440b84be213b92a25eeaba2797756b3290e7c36c5b2a2") end
    return table.concat(lines, "\n")
end, 170, CustomIcons.Shield)

TabPvP:AddSection(__S("ec121f7b7587c125ba23ae26c3a1b94c32a02a35daeb4780b3636ace7b6be66c4162da7aed1e1b55110c69e4a2fd6f161b71"))
TabPvP:AddLivePanel(__S("8a49992c8a09b674dbd79049473a7244d988"), __S("288112dddca4088d84af5998f28ae3642ccab1e08ca1d2ff31ecfff0555bbe2f70c72c0a422dc8755a116fbb43751e5e5d1a6ea2fa7403bc6552b2efb2ff5aa437ca5fe194d8ba8068688f637b319ff69562d0c18d81d0"), 1.2, function()
    local lines = {}
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local _, statusText = getPvPStatus(plr)
            local lo = getPlayerLoadout(plr)
            local dist = __S("c6b88c8e77")
            local hrp = plr.Character and plr.Character:FindFirstChild(__S("64f0063fecbd6a2af6b17409a2a685c160fc88e7"))
            if hrp and myRoot then dist = math.floor((hrp.Position - myRoot.Position).Magnitude) .. __S("03277ff071") end
            table.insert(lines, string.format(__S("a15ef9a1317d4c39e189651952ccf1849eda536d8d7c6b116479f6708c25bdfcebc64375f2bca104a98176e7c23202b749b9e83715e5c7c53c5fd9b0ed20619ab693248bbd8e8bef8ff5ab665560477a7e"),
                plr.DisplayName, tostring(lo.level), statusText, lo.fruit, lo.style, lo.sword, lo.gun, lo.bounty, dist))
        end
    end
    if #lines == 0 then return __S("3f967352621ba3656f5c818022b12832ef666c04ea1665bd4aefff5b3038832d493b464a") end
    return table.concat(lines, "\n")
end, 200, CustomIcons.Players)
TabPvP:AddButton(__S("ddcded03c5933819965f0f40d1119f8df14ad2a6b511f6ba9408a52d6f"), __S("7c0566b42a69ee1748334f650b1a0b695439b92d5728ba721fd7cf0f263a2578e6b577f49fb2818a9201e7d1709e81751c2a14fa0823b13a60e29cb486"), __S("1a3ce0658f6dc30735ea"), function()
    print(__S("b8745a16cfe9ebd98ae24b79db34e9d8afdd7e4c7c006e901409ffc7aaf542b6e98ec86349cfb7f3bb155aec1613046ed74c41eed459fc1cb8117914c998ff63bf"))
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local attackable, statusText = getPvPStatus(plr)
            local lo = getPlayerLoadout(plr)
            print(string.format(__S("56abd3c735761f1f0cb0811bf734abf275a1dd63da83cd34db81b2babb7bbd815eb9eab00c047cfa815bbc937e8cdaabdbc75b1746d1c2f19efbfbc9e800240f309a3779ebd9d429a14679b67cc116966d234ef62cef46d5897abac080cc367f3203b0bd3923e2417d"),
                plr.Name, tostring(lo.level), statusText, tostring(attackable), lo.fruit, lo.style, lo.sword, lo.gun, lo.bounty, lo.hp, lo.maxHp))
        end
    end
    notify(__S("f4e34d784eb5ac5e3f924592b053613927"), __S("931ac72950e5f0ee8d9ae18aff255ada5373235a314f2d7d9d20e49cde373afd8e127dfd507377d63d199285a55d7a313a62b2"), 3, CustomIcons.Players)
end, CustomIcons.Search)
TabPvP:AddButton(__S("315240dafd9d321c4ced43aa0d93cb7bfc43169ca7965b9ef8db30fe3bdf2c"), __S("cf89ba8b5713a2854793892a481ff822d877c713803cd36eaaeb746ab2693c6f74b2b7149bec293a353ddd98264cba22edaa9b6bf81d69"), __S("6dc1343c2fa03a0dcd808a79f26bbc3b"), function()
    local plr = getPlayerByName(Config.SelectedPlayer)
    if not plr then notify(__S("0bf8aded7f63c61779fca1f9eb8d8d7386"), __S("aa30279e515b9eda597836195e01e8531b53103a"), 2.5, CustomIcons.Stop) return end
    local _, statusText = getPvPStatus(plr)
    local lo = getPlayerLoadout(plr)
    print(string.format(__S("4867a14f33dc2a09ca8e09d97f7cdb19efa1e2c2c1a472c93d2bae83e39c3e951423e44527dfe6c321cf78bd6badadea1ca7822671ca0907b01626d979bbcc63f03d6e98164fc0e850d042fd0e2826c61c6dee0ca5a296803556fff1566f47278919cbff7b9ad5"),
        plr.Name, statusText, lo.fruit, getFruitTier(lo.fruit).name, lo.style, lo.sword, lo.gun, tostring(lo.level), lo.bounty, lo.hp, lo.maxHp))
    notify(__S("e69f1b004b114778919cb4d4adef1b0f3856"), statusText .. __S("84d694b191e1f75d") .. lo.fruit, 3.5, CustomIcons.PvP)
end, CustomIcons.Players)

                                
TabFruits:AddSection(__S("230e0e6227525d51c0348c30f54e4270543f384bb6dd4d64d0da51aa197fbd0eed865d4136e47f14e0"))
TabFruits:AddDropdown(__S("c145881364cc1312b7eaff0ce3f0bc77d612c4ad7590"), __S("5f7d01c4f53482e7aedab40f283d17ccb9f1f68fbd149f7840961c9f959ba89da9934579281abd4b8edf8b48"), FRUITS_LIST, Config.SelectedFruit, function(val)
    Config.SelectedFruit = val
end, CustomIcons.Fruits)
TabFruits:AddToggle(__S("fdb47b7559ffb9ebfff698b2ce4ae6e2d046ecf2f8c4a3b8"), __S("9bebf526e8e6f6881d7cd2fd521aab9770f4de0377551e5f8892747ba58f797567e270d6b2c332719681d9a5fd588946b8516938d7e790e921593f"), Config.AutoSniperStock, function(v) Config.AutoSniperStock = v end, CustomIcons.Fruits)
TabFruits:AddToggle(__S("3a236ed70a7ce9d32bba465d1f3916ab7a951fbe9125b437c0a7f2f1e2ce01d2"), __S("d85ae888d95d79a0eb5f6e0a9d672b57dd6f49866a875c533f5a3400a69f7c42666a8eb2f6f04d5ed52a7946dbab5dc6c67ffd0eb16957"), Config.AutoGrabMapFruits, function(v)
    Config.AutoGrabMapFruits = v
    if not v then stopTween() end
end, CustomIcons.Teleport)
TabFruits:AddToggle(__S("7692623972ca74a84b0459b98a75ae7f17918b5e2b07b8e422480bbd7abceb78fd17"), __S("14c9dbea7154154372a73f6643152882b8ba3332fd9024e40c973d3841b8532b2dfbdf20daa9b2b66726a809993384654e498f8d27986b"), Config.AutoStoreFruits, function(v) Config.AutoStoreFruits = v end, CustomIcons.Layers)
TabFruits:AddToggle(__S("b301559b431961be322f0794a77c9be72c957c6bfdc423458580346a"), __S("5138cf4cf64f64afe6b1b25d666017595f2a028bf0a5012151ebbe5dd5922b5437a998c18f295cc8c07dcba46539622eae4b550ea601092c17022707fd10d1ddb8e5bf5b"), Config.AutoRandomFruit, function(v) Config.AutoRandomFruit = v end, CustomIcons.HubCrest)
TabFruits:AddButton(__S("ef7048fdd883970a93d961e9a522641b37fccd786e3541a830"), __S("8da7c2aefee8d2e3310e838aec173809300009020da89f6aba6c597bda74104921e75f10c2dd9c6e764ff702688c5fd2ff580244ec078af30fe2f65379d44141a502"), __S("2bdf3c5f87b6f0ca28850fad"), function()
    invokeCommF(__S("ca16b6107907a1f2c768"), __S("684e2fc11814a3"))
    task.wait(0.4)
    local backpack = LocalPlayer:FindFirstChild(__S("0685a97205ac5f319435892e"))
    local char = getCharacter()
    local fruitName = nil
    for _, container in ipairs({ char, backpack }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA(__S("a4bd2323fb3268dc")) and toolMatchesCategory(tool, __S("42f49cd441dff9481a75a872fe9e")) then
                    fruitName = tostring(tool:GetAttribute(__S("e12c1685545ef41d5bcf5e9c7c8bccaa")) or tool.Name):gsub(__S("7f63903624a50a19ec41"), "")
                end
            end
        end
    end
    if fruitName then
        notify(__S("1d9b09e7764561f03e148d74766781d574b81018"), fruitName .. __S("bbd2839868335b6d233af296fe87f3da4a94ce") .. getFruitTier(fruitName).name, 4, CustomIcons.Fruits)
    else
        notify(__S("5a09fd49fb40949b175ccac6379d26c3617e8451"), __S("f84176fa47a1a4bd297bd4d1e8a79b7feb6e889d94b9bdd6828f99b188cced4179563d59cd0380952f3d447f30fa5d3cfd1c62e476e925"), 3, CustomIcons.Fruits)
    end
end, CustomIcons.Fruits)
TabFruits:AddToggle(__S("9678f0ab7b77b580d779d3eda2775780f7427bde3974f4116df01e994d7dc716"), __S("34b06a5cc0e5b27d67c033e74364ff71ff2d5867a8d1a2aa65873bebe756ee8e90ce7df4ca80436971d157e150c86e00894f2096e5e46795f2469b2df3fa88e8c656fcbf34f58a7a9794d3d5eb3dc24cd75f9e0b63650b01a38509b2f348777db9855fcf6683c1f7a9f94949bb3be957dd5389e43754f67b74fe2d644137b031046f5bf50fb7cd0269825c3988931f464fcb1d022e79db16f4e76fa3e8581ea8a680627f4439"), Config.FruitNotify, function(v) Config.FruitNotify = v end, CustomIcons.Fruits)
TabFruits:AddToggle(__S("d2e7e40dbf72b63fcca8ca12dbb0c78e8cfbe227d43aabe65496059453e3a8bf18763ec087c7c3"), __S("711f5dbef9fd613da45bb4f1d59745aa0004b2b8d0d48dbefec643a7dee9350ac4dbef07104759cfa592b04ee12dd7dd6efd08c043617dd35aa040c30fafd53b6294ac7426"), Config.AutoStoreRolled, function(v) Config.AutoStoreRolled = v end, CustomIcons.Layers)

TabFruits:AddSection(__S("0f56d76fb4f7a60a874fd9da4174c344ba37b06d39779b1a087380e4a7f9415e34883b0f1ae581a49e"))
TabFruits:AddToggle(__S("ad8e512013f1e3c6e15d52d092d1adce"), __S("4bc5cad13824da11246803bde17127265a0187df706596c40a972e5394cf482d63edfcb4b9b135f596397317718745b3baea7dbb2c0f2030dcc63dc2f2c7b301f184d3fabe"), Config.FruitMagnet, function(v)
    Config.FruitMagnet = v
    notify(__S("e9fd4482f2e9e8c4536f24052b0e04c7"), v and __S("8834be33c777b1f97a0b3688fb77ce78b910369bf3e269925d") or __S("266c37e46a3af524a8e585f27b2639c52979aa69"), 2.5, CustomIcons.Magnet)
end, CustomIcons.Magnet)
TabFruits:AddSlider(__S("c4a3b19530b7ef7a85b576b8b6264d8278617703be5abf2f23"), __S("62db2b4639bd0690e1ad0add384514416fb6d5d07ea567d88de2ba6803c514950f63a24b408ea0e86f568d60c2ab181f5ffc"), 50, 5000, Config.FruitMagnetRadius, function(v) Config.FruitMagnetRadius = v end, CustomIcons.Magnet)
TabFruits:AddButton(__S("0112a4f75cf1a1dd85cc08562eabeaec953d717c3ea20f7a65754ac80a"), __S("9f4a1ea84ef10664b9de3d4f12f88dd2460c33f46a55a61ccccc9083e6c5fc5995cfaf15b6f9d6b3115bfd5f21e71f4199412dad3e2b68"), __S("3d819859ccae83b9"), function()
    for _, entry in ipairs(findFruitHandles(Config.FruitMagnetRadius)) do magnetPart(entry.handle, false) end
    notify(__S("dbb9120a7059415e2ff086a20ea3d716"), __S("79f08bbba89c9f03149902e0b609c2fc44d4d4b279665c6b"), 2.5, CustomIcons.Magnet)
end, CustomIcons.Magnet)
TabFruits:AddButton(__S("1828056ca9086a7e021886349ba3d98da04a3218660e6500e495544616cc"), __S("b65f7f1df77f79cdd71f124300de87a3095debb99c6d63d9f9fd4e8f657a4a42e217dc07f2460488e39e0bedaea2d2a2"), __S("5496f8ce6ec94b7e"), function()
    local list = findFruitHandles(9000)
    table.sort(list, function(a, b) return a.dist < b.dist end)
    if list[1] then tweenTo(list[1].handle.CFrame) end
end, CustomIcons.Teleport)

TabFruits:AddSection(__S("f2ce727f8d1b8af17f61ec574af4f09325080b1422"))
TabFruits:AddDropdown(__S("9105ec30034bb2a8f27233bc0a929685d122"), __S("2f3d65e15294aed1d88639f434b495b19590aa002cb888db8131132acd54a1b066539c2a260ac1"), RAID_CHIPS, Config.SelectedRaidChip, function(val)
    Config.SelectedRaidChip = val
end, CustomIcons.Lightning)
TabFruits:AddToggle(__S("cd74df92b0837e7fcee32ec609886d4e4759d54d7359cb549fbf73"), __S("6bac59436060b287051f593b4a16a0066e8b23bbc8501388ea7f5b5c2d5170874e2dfd4eb6f45b3b8660b4f5d3"), Config.AutoBuyRaidChip, function(v) Config.AutoBuyRaidChip = v end, CustomIcons.Layers)
TabFruits:AddToggle(__S("09e3d2f43865579705013f86aa8208949f86"), __S("a81b4ca56793b1f4b45f8e233b701c507b760d16615c2dacaa049f064ac2d0376c2d0ba9a64d588128f21fdba79bf783fa"), Config.AutoRaidAura, function(v) Config.AutoRaidAura = v end, CustomIcons.Boss)
TabFruits:AddToggle(__S("4652c6561b262ad43aaef8e2e419f1462041a805bf2c4d63d7692d"), __S("e48a4007437d14b2d6d0aa61770778ad3238938ea713a2023940315dd2f0b7c5c4bdd5362b9547800b014d23455696536734ff77e513ceacbf12"), Config.AutoAwaken, function(v) Config.AutoAwaken = v end, CustomIcons.Wand)

                                 
TabTeleport:AddSection(__S("82c1b9b870e1a6566ca9443699e0"))
TabTeleport:AddButton(__S("20f9336917fe2d7889f0c69632c42ea0936ff545717072"), __S("bf30ad1a674743f67edc5a840c3249cf7e79bdff599c26be4432f867d2eb80bad65a5a202b7425114b72fe8acf8a"), __S("5d6826cb2708369412dc"), function() invokeCommF(__S("fb9fa07c603fe788767cadf8d8b3")) end, CustomIcons.Teleport)
TabTeleport:AddButton(__S("99d71a2db0296df707c767208627861118fcb9a7f9b9a9e2"), __S("380e93de308f95fcb8085ed436835a6f5377e8fc28149ec9a056addff400386e45fb3eb048b3cdc9015010"), __S("d6460d8fa04c38b2c6df"), function() invokeCommF(__S("747d87401e286ddf69598a17c0d811709c3b55")) end, CustomIcons.Teleport)
TabTeleport:AddButton(__S("12b500f170e6037506921b443deb00f9538c02641509b5"), __S("b0ec7aa2ea4eb6ab72e72a0a28c1a2b5b5049318e414f05af3f7f308f711bf99e88fd8254d4a4971e3d873ec7d1ea965bc3641b6"), __S("4f23f453333f4de750b2"), function() invokeCommF(__S("ed5b6e043d9a4098364b24a93c")) end, CustomIcons.Teleport)

TabTeleport:AddSection(__S("8b92e7b5ae8af0c2355da372b41425912b91cde4b529a803a1d3c56c60ac1aaf7fdf19a9dc581a0780ee216139638f0fadd76d72ab1ccfd1ceb6b5b659327da5"))
TabTeleport:AddSlider(__S("29ca6166614bb52c9a6be7ef0f67a3865472827209b6"), __S("c801db1735518bef9c113f811ec2adf14792340520c61e2b01317bf4b34512ac4f26236d644733c8ecf3"), 120, 360, Config.TweenSpeed, function(v) Config.TweenSpeed = v end, CustomIcons.Lightning)
TabTeleport:AddDropdown(__S("663954c8dc73c8ec976b79202a0cee0b57e9644a17a5"), __S("0470ce7935105e8821d2099cf62edda95edb199643fc8ca3091ff508b52d6ad7dc014eaa9660c29810a0e724915f48598af8bcc0ab857975a2ec114cd4ee624829a70ac75109780a0de9abe0"), ISLAND_LIST_ALL, Config.SelectedIsland, function(val)
    Config.SelectedIsland = val
end, CustomIcons.Teleport)
TabTeleport:AddButton(__S("a2a8482a282fead22d80e96d9ed1efaa37f64eebab8ff050d6324fad"), __S("40dfc1dbdad11d8037b5efc4845f662b63c773a6a31d25268770dbefce2d04ff79150420446cddee53ef02405e4e9dfba55f2277f22b5e58"), __S("df173b8c0b141434e1eeec5e"), function()
    local islandName = tostring(Config.SelectedIsland or ""):gsub(__S("7d4eb53db7a47370ea68ae24ee9b944ba7"), "")
    local targetCF = resolveIslandCFrame(islandName) or ISLAND_TELEPORTS_ALL[Config.SelectedIsland]
    if targetCF then
        tweenTo(targetCF, Config.TweenSpeed)
        notify(__S("1b862eeef749832317099bda"), __S("b9bda89f9c9009d6e665bbb991c9ca65") .. tostring(Config.SelectedIsland), 2.5, CustomIcons.Teleport)
    else
        notify(__S("57f522503be6f7119d87d8d5"), __S("f62c9c016244462bc6de2002edad15ed6ad90834") .. tostring(Config.SelectedIsland), 3, CustomIcons.Stop)
    end
end, CustomIcons.Play)
TabTeleport:AddButton(__S("946415b2e8585f9f859765adce62e630165e9a89e6"), __S("329b8f63916fc3ca50800bfa5e39bd835f4fffca06f88745595479f8567e0d2f7831383cb4220b30a930"), __S("d0d309143fdba827"), stopTween, CustomIcons.Stop)

TabTeleport:AddSection(__S("6f0a82c5bf0de9549b3b44bc4a0705e4284e2061e08edd4d9505e68a6f7f607ed5"))
TabTeleport:AddSegmented(__S("0d41fc76625269a5c59ef92c8652a432"), __S("ab79762798f2050c591358caa2850f164c114da1e41a1980f2548e33a110844c65bebcbe0699b575e29010f33b6884b1c10ab01587e52a5d456c631692"), { __S("49b0efd81c3455f7"), __S("e7e86989161bf06b40"), __S("861fe33a951a1bcf9d"), __S("24575ceb9d07e602c0") }, CONFIG_SEA_OVERRIDE == __S("c28ed69cb373147a") and __S("60c6504d2ba4c3a4") or (__S("fefdc9feaca6184d") .. CONFIG_SEA_OVERRIDE), function(val)
    CONFIG_SEA_OVERRIDE = (val == __S("9d3543afaeff77ec")) and __S("3b6cbd60416be9be") or string.gsub(val, __S("d9a43711a118e607"), "")
    CURRENT_SEA = refreshSea()
    notify(__S("77dbb0c2109cb0f062ebd479aeacaad7eb"), string.format(__S("16132a732e86bb6c0695f5b79ee3a98add"), CURRENT_SEA, tostring(SEA_DETECT_SOURCE)), 3, CustomIcons.Teleport)
end, CustomIcons.Server)
TabTeleport:AddButton(__S("b44aa4247166168050e8a790bf892d710617dda2b5"), __S("52821dd53bddabcb6d5618c9b748b9b515efbe7fbd5f34365742f7757505a66871fa25e5f5aa9a42a12ec8ccd73a4ad1f002378203718b076423247c99010926"), __S("f0b99786b07eb798d31ea8"), function()
    CONFIG_SEA_OVERRIDE = __S("8ef111379d755634")
    CURRENT_SEA = refreshSea()
    notify(__S("2d288ae8c17d4432880ac826391eff737f"), string.format(__S("cb600499337ed0e5ac3941422ab968"), CURRENT_SEA, tostring(SEA_DETECT_SOURCE)), 3, CustomIcons.Teleport)
end, CustomIcons.Search)
TabTeleport:AddLivePanel(__S("69977e4a9654d3ccfbebceb6bc29"), __S("07cef7fb6f1dac4f9c687d924bf3d305fec49f719699bfe0e40454ad"), 2, function()
    local scores = computeSeaScores()
    return string.format(
        "PlaceId: %d\nDetected: Sea %d (%s)\nScores  S1=%d  S2=%d  S3=%d\nOverride: %s",
        game.PlaceId, CURRENT_SEA, tostring(SEA_DETECT_SOURCE),
        scores[1] or 0, scores[2] or 0, scores[3] or 0, tostring(CONFIG_SEA_OVERRIDE)
    )
end, 110, CustomIcons.Server)

                               
TabESP:AddSection(__S("a60671ac424ea82a83cec2b45fb1cd5dcfab38317007"))
TabESP:AddToggle(__S("443deb5d66a10dd1e8ec81ffa6ec"), __S("e275650eaa499fa28c45347a1a1c45192b63ee977305cea9a3e84f23f342a74dfe57255f80ef51b0daea956fa69aeb7cb33178be761e509dcbad0ae523b19d0c6573515cc709b538565313bf167889167b9f0e42653b311553b331dbf791b6"), Config.ESPPlayers, function(v) Config.ESPPlayers = v; if not v then clearESP() end end, CustomIcons.ESP)
TabESP:AddToggle(__S("80acdebf061d146a0cc4d1e444f40eba0388fa"), __S("1ee458706d5a4e17f486cb9f62a5d26e5d0a8687044bf0997d98d7b2ef4d9c89147cb5089de35c1f79e5d17dff56eed4b77c2d2412fbf1cc2d4eb4"), Config.ESPFruits, function(v) Config.ESPFruits = v; if not v then clearESP() end end, CustomIcons.Fruits)
TabESP:AddToggle(__S("bd1bd2210df4b0759a75a7b451"), __S("5b534bd24e2aed02b269365bd4f6276445ba48ccb13b67154e9cde468a5a883381d9f809a93af7259dc708"), Config.ESPChests, function(v) Config.ESPChests = v; if not v then clearESP() end end, CustomIcons.HubCrest)
TabESP:AddToggle(__S("f98ac58393c8dfb159e204a560d239fcbd8c2113beccf249ff7bb4d04ffe9cf78c"), __S("97c23f34b2150ef14c5b8799fcf29068d091c699818a8a5824d181bd964ebb1133b2994476f7468dd7c995b3fe6f8f5dea33d10aa1fc274ee67810e0d8aba61ad3f5"), Config.ESPIslands, function(v) Config.ESPIslands = v; if not v then clearESP() end end, CustomIcons.Teleport)
TabESP:AddToggle(__S("35f9b8e535eca4b983d5dab7"), __S("d431329603939d78cb0600e50e17a0647291d29240635e98182cb58f6f47b7f8cf9ec53c87246c713fe11b20a5dd74b7b595e73b8318cc"), Config.ESPBosses, function(v) Config.ESPBosses = v; if not v then clearESP() end end, CustomIcons.Boss)
TabESP:AddToggle(__S("7268ac4707f90adaadedd05c78001eab3d7d2dddf253"), __S("10a025f844f3741084401e62583149b88cf80b4a4753652bd59bcdd2c9ad2a74cd4cb2a40059b903c42a307c2236972e274fd1d8701f5c30466cdd4cc9e54e0f906eb06e1eeb7c1f9d3a"), Config.ESPPlayerLoadout, function(v) Config.ESPPlayerLoadout = v end, CustomIcons.Players)
TabESP:AddToggle(__S("aed79fa97ef109c36a9acfcde4864a5f4d84b85e5c5644a3"), __S("4d0f195a0bc114b9deaa1c7eb48a2353ac9453ae2ddfcd7b4c967d1afec1211d6ac4e5d4c665a8fe0bbac04597971412e0faf32771ff156099"), Config.ESPFruitRarity, function(v) Config.ESPFruitRarity = v end, CustomIcons.Fruits)
TabESP:AddToggle(__S("eb46930bcc4ea91ca133104c1c0532b5"), __S("897e0cbc8c0883b83bfad4aa4508cc310acd6fee8a8d7f4ad8ade06ef68a99b4f4e46115139c7323673f4060b13c8a7fd9836ab7225f9739276c793cc98cf062295e5ed1"), Config.ESPTracers, function(v)
    Config.ESPTracers = v
    if not v then Hooks.clearESP() end
end, CustomIcons.Aim)

                                 
TabMisc:AddSection(__S("27b5866db358c47fdd284a06f3f5efc0bc49bceae3d346603c87a67b8dfd14beade760"))
TabMisc:AddToggle(
    __S("c5ed001e8de4aca08e3bca3ad98806c3cddecd5f9bc835a36159fdc46c4f12a5489c"),
    __S("642479cf23fba76e9aed23ac7689b25cf3e8ec647f0b65434d3566c36af794258c239c1601ba0288b0b349fdb7944d5f0c45fb183dd887b962574c796639880908136d7ca31bdb0f9408fe612384f090c0eec5e9337417002701724a"),
    Config.BypassAntiCheat,
    function(v)
        Config.BypassAntiCheat = v
        if v then initBloxFruitsAntiCheatBypass() end
    end,
    CustomIcons.Shield
)
TabMisc:AddToggle(
    __S("025bf38074e1d1058f5fe88f0e3b1440ae0c28b164d6dea431120607"),
    __S("a0936d3188608515c798e53c3c8da86d2c822bda68e83077d13649101c18371144d6074533a1e9ac9c69aed945f77fd900a1d4612fe0b4ea98ba2f456ab0baddc098510b41273d7a5a2125aae20aceed92513556d745e4"),
    Config.AntiStun,
    function(v)
        Config.AntiStun = v
    end,
    CustomIcons.Lightning
)

TabMisc:AddSection(__S("3ecae6e29c89928cf707f14201163ef1fc1428b0f368182efca583ff9efb63321ed123f9904c"))
TabMisc:AddToggle(__S("dd0260933e2eb85145fabb83e037"), __S("7b39da44aa696f245e7b04987a7382ab34c155fa0cd085af25c3885bef22628070bce06578a482f3d04e657b1350612061c323f51e0f31328aa06bb26353defbf1990914d706574936db06aae60a92bac87fec32bc26370073dd7c10c48e47c018e19542ac6222100f9bae787a82e1"), Config.FlyEnabled, function(v)
    setFlyState(v)
end, CustomIcons.Fly)
TabMisc:AddSlider(__S("197153f57464e5c7783e04c93a"), __S("b7a8cda6fbcd920535956b84862f45b80bf67eae9ebd156fab478fd381e638506f3b47c75e582c83ace8917eb6866c99e3fc423fa0d695ac06fba998"), 20, 320, Config.FlySpeed, function(v) Config.FlySpeed = v end, CustomIcons.Fly)
TabMisc:AddToggle(__S("55e04757d0346c7634abf8991618a0c916f20ee86a7b11a6c542922d92377292faa5a236d2011a"), __S("f417c10821563ac7566d8b0cc41cd0c612c8cf151ec9dc9b4205707cd36b1a471ed1865f9ece3b09c40735440f7ca2a092997e30929ac48ecfdbf4c7bd433a2392675c5e2b520b04dc06c22b5d71fd76b84bccaad568251938705d233cb1fe41"), Config.FlyHoverIdle, function(v) Config.FlyHoverIdle = v end, CustomIcons.Stop)
TabMisc:AddSlider(__S("924f3ab9d4c7d0954044b37d60db9514466ea4c0f8db8071334a7a4eb57c8208a7a211b6"), __S("3086b46adcbfcb89a15171cc38f0d3e6ad90338b2ed8d5808c63c3e8dbdf6b34b6c64ce9bc0baadaebba1e063281d51df88837c5805a5e0446778388a10939f7f6f1ab7292051346097ad319bc6c68b66a2722b699d152c59dad3b8ad8d339a2fe5804daa0639a4f2ff7e82e2282435cc8793481e081de15cc792e3c"), 0, 500, math.floor((Config.FlyHoldSeconds or 1.2) * 100), function(v) Config.FlyHoldSeconds = v / 100 end, CustomIcons.Loop)
TabMisc:AddButton(__S("cebe2e1b551e8ec3ee9d2af97b5818df8622b1f579f0cd5d2c17480f2480"), __S("6cf5a7ccc20fb436ecde3c74b8c65e479a4ecbc36dcea0c4e9e497e0830028b5faefa953cb0667d9ead0a1a177c54d4dbd239a46f2df9b3cc55d2cd44fc7ae4cb0778aea08980197390c10c9400d1197acd1779832825893209dc41681"), __S("0b2d217d2cc67e12"), function()
    if Config.FlyEnabled then flyPark(not Fly.parked) else notify(__S("a9649b2ea82835"), __S("479c14df9af7b78e0b3cc454f48564e9dd3dfb313730e4c7b3406444f288f38e5599"), 2.5, CustomIcons.Stop) end
end, CustomIcons.Stop)
TabMisc:AddToggle(__S("e5d38e90d23ca01129f8ae87e0be18c050f3268b391b059543290d"), __S("840b08419335f84f3f1403fa2a372a5a0ac09e7e8e42f2dbfeeadea27158d711275609362f9887a3721e552456b72b5a3ec3342fc502ab9bb6ae4c2efe79423ec3f75dfd9878e970dae0bfc3199b76d89a76674aa534b49fb2dbd9ca10ef2d209c2601"), Config.FlyBypassMode, function(v) Config.FlyBypassMode = v end, CustomIcons.Shield)
TabMisc:AddToggle(__S("224281f20afbe5809a6765c334acac7f7b1cdf25e06b753df4a7f6fdd0667e9482"), __S("c079fba3d601809e21cb18f849a67b388f4b35297f238c5c51654269316c4265ef28d792ff45c654eb9aee00950bd53eb7960733d143d06f72e71121fb0a6abd0d5c6220243247191b77d9a918a40370223b0e24a1"), Config.FlyZeroWalkSpeed, function(v) Config.FlyZeroWalkSpeed = v end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("5eb17554383afcd0858c3627ced27404443cb3914bfdeb87f47d0fd58e"), __S("fce8ef05edb907ccb87fe1ca2311d20e99dddc3d0d0dbad882ec1b59fc96aab6608c41ec89f0d1222c6e6badefba9d01b8a584752221521ddb76dc15bde6acc70bb98e8d46bc1ee5e63d0794a24dc1728c760217e40348d549a8306e3a2002232339"), true, function(v)
    Config.FlyJoinAutopilot = v
    if not v then MovementLink.clearFlyTarget() end
end, CustomIcons.Play)
TabMisc:AddToggle(__S("9b2068b64c766b4a70d44b71b0"), __S("3957e267fe4e632df942f270d0a804c20bf504612a4bd5e89753f565c696d92ed89466d96a5b98e7c0d0ad1e1f083bfc0b3244a6a5b93af8"), Config.FlyAntiVoid, function(v) Config.FlyAntiVoid = v end, CustomIcons.Lightning)
TabMisc:AddLivePanel(__S("d78f5c18984da8fd999cbe954500"), __S("75c6d5c9da51800204ae3367fd4ff9e976acc7a143b516c289ec4d8d80"), 1, function()
    local root = getRoot()
    local vel = Fly.bodyVel and Fly.bodyVel.Velocity or Vector3.zero
    return string.format(
        "Fly: %s   Bypass: %s   Speed: %d\nVelocity: %.1f, %.1f, %.1f  (%.0f studs/s)\nAltitude: %.0f   Autopilot: %s   Unlocked by: %s",
        Config.FlyEnabled and __S("13fe4f7a7d41") or __S("b235c92bac0b70"), Config.FlyBypassMode and __S("506d42dc68db") or __S("eea4bc8d85718e"),
        Config.FlySpeed, vel.X, vel.Y, vel.Z, vel.Magnitude,
        root and root.Position.Y or 0,
        (Fly.autopilot and (os.clock() - Fly.autopilotAt) < 1.5) and __S("8cdc363e1241bc4447dc6d642101565f276147163d838d") or __S("2b13afeff5519411761add9a3607fc38e279"),
        MovementLink.isFlyActive() and __S("c94b29a0191ca6") or __S("6782a35171efdee9c2")
    )
end, 100, CustomIcons.Fly)

TabMisc:AddSection(__S("05ba1d02bab5bf0b767af524b17433e70ac2e6ca"))
TabMisc:AddToggle(__S("a3f196b3774bec9650ede6b65f3325954b"), __S("42291064e5c5684460dc85816d9d7a60c5f2b60af99b122509e5ebf417dfd72f4729b78401dff014cf525dc32d3c62942e7bbeee7f2693c5e872be320f6626630f6131b0aff6e2"), Config.WalkOnWater, function(v)
    Config.WalkOnWater = v
    if not v then removeFloorPad() end
end, CustomIcons.Water)
TabMisc:AddToggle(__S("e0608a154dfe25d4c6b676a6578d9bc5f3a0d02385b7b2df8da41123"), __S("7e9803c6261c4d25080d111cbf4a01d96c95f6c192c682939312f1a3a75cc9d7c916218371540a42406829ad6b893769"), Config.InfiniteGeppo, function(v) Config.InfiniteGeppo = v end, CustomIcons.Fly)
TabMisc:AddToggle(__S("1ccf7d776e45cb5e0fa24ff373653cc8f0caa8"), __S("bb06f728b2de17b6b7c0f0f9ee6210498b193ba7f5c08e9008272ae025fd45af00309610584ec0edee511c05e596d0a02348c1a07c8114d37ee4"), Config.InfiniteEnergy, function(v) Config.InfiniteEnergy = v end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("593e70d965e5c7dbef1f01483b0fa3bc96a92518"), __S("f775ea8acb1bad2165c8f2fdcc26fce7e8ef5104722b650d30799cc1bc91677e3f50ee350de7a7682c6191ab7bd64d80b6d2b81de3cd7198581b"), Config.NoDashCooldown, function(v) Config.NoDashCooldown = v end, CustomIcons.Lightning)
TabMisc:AddSlider(__S("95ad643b2a6d901ae2fbe41c8a9309ffed"), __S("33e4ddec84055c1629f582a6f1168269aa25cb65a8413504ac8ea04e66c643e32705cb20f16dc1f4b0980648e30d"), 5, 120, math.floor((Config.DashInterval or 0.32) * 100), function(v) Config.DashInterval = v / 100 end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("d21c579deb7fb66effda1f14ce3efca737cb4fafc039"), __S("7053d14e5e8f5704fa2fa966d41796770df228bac589c3b31b1f9afb61882e0c259fbc1a9bca0a60475a50057ab927a5ea3d3b"), Config.AutoCollectDrops, function(v) Config.AutoCollectDrops = v end, CustomIcons.Magnet)
TabMisc:AddToggle(__S("0e8b4affe66836d8e5a11c82522f52ec87a9239403"), __S("acc2c4b09bca37b0e2dc2d9628fde3fac43ad39efe6997c5e945545c767bc4e5669e2186933d26fe0d34ad546153474aab05262ab2c1e256a9beb60d1b411dc71afa1cb609f4d9a2f332d2335983062ab8ca33"), Config.SeaEventTracker, function(v)
    Config.SeaEventTracker = v
    if not v then SeaEventState.events = {} end
end, CustomIcons.Server)
TabMisc:AddToggle(__S("4afa3e61f732b9118e0dba204008bcdd8c39214533d70f20f2f7c94d7a4753"), __S("e931b8123fff8272ae3b08209b25c23252350dc0713c7e1146f5809d822b774b306e7ade16959f2f7ef53ed5d58badabe84226efb20b16f8befe29d284d7e453112ab13fea367c3b3815654d0461125ea1"), Config.MirageFinder, function(v) Config.MirageFinder = v end, CustomIcons.Magnet)
TabMisc:AddButton(__S("876931c358703a3969087ab63c95b15c83a472ce9973ad"), __S("25a0ab74358f4df356845efe9f48f1dbae172e6a556465073eeee5aaaa23a33fa86a2460abc1dd4dc3138e3e"), __S("c3d82525a8372b27"), function()
    SeaEventState.events = scanSeaEvents()
    notify(__S("620f9ed6eff9b328bda0da70ab05e5f2737f"), string.format(__S("004718878971fdb75fb35bbf08bd8c8e10bcd740a27bf3258a1c4e24"), #SeaEventState.events), 3, CustomIcons.Server)
end, CustomIcons.Search)
TabMisc:AddToggle(__S("9e7e9238f76cbc24e0319879bbb84e42bf23d55fb9"), __S("3cb60be9df71fafd803522f8425cb6e7b0d5dbafd222ae035228c6826f82f435543389963f07a2afb454fc0d8ff5ed9cc7c8cfe714fc0ec10cc4969ffbec85d7add6d044cae5333ae723b0"), Config.ServerStatusHUD, function(v)
    Config.ServerStatusHUD = v
    StatusBar.Visible = v
end, CustomIcons.Server)
TabMisc:AddToggle(__S("daed859a5b5b1388a5bc31e63b293a03e66585367f6987c1bb38514a14f2054177fb0c01"), __S("7924ff4bdd7f05fbb7ad3c97ae43761ca600abc4d4ec14efc338d1a8513525f797465aab6469814d6c7193ec9a0fc01cd1140577578aa06083a2208c"), Config.NoFallDamage, function(v) Config.NoFallDamage = v end, CustomIcons.Shield)
TabMisc:AddLivePanel(__S("175c78fc2ef57f50b32746f128acf000e3"), __S("b593f2ade24f4eb8a15068ab6dd2f032fcd8edb989ded607"), 1.5, function()
    local st = getServerStatus()
    return string.format(
        "Job: %s   Players: %d/%d   Ping: %dms\nSea: %d (%s)   Locale: %s\nSea events tracked: %d   Fly: %s   AimLock: %s",
        st.jobId, st.players, st.maxPlayers, st.ping, st.sea, tostring(st.source), tostring(st.region), st.events,
        Config.FlyEnabled and __S("53cb6c5ef1d0") or __S("f202e60fc156e2"), Config.AimLock and __S("903a5fc04e8d") or __S("2e71d97171495a")
    )
end, 104, CustomIcons.Server)

TabMisc:AddSection(__S("cca953228596614a472a507899dc210e5531dff27c9c6b68ebc625ecd31e9c72e098fc23"))
TabMisc:AddToggle(__S("6ae0ccd3e35576e406c94b36bb149432a40d4999f894a7ec85b2cdb00666df9ced88f4"), __S("091846842900c4a7157e3620e5de38d9e5c43b496652da3bc0315f5804c1b6f65e74c1af8a2b08a8f417ba4254e851939cbe601a85007adb90433ea35da2a93f87ad7afba28eb0b3fb4e71cd85c443263a9d8a3bdbb0fe274adb78ed6193ed77316900ae64b765403228584979038e16e4a95f0c7b684477cd7a5bde38dfdb394afc20a5c1954ddf2842aad71983693f324cb85c672fbc40b92de3907a0fd2f9dff8767372e5bf5ce895a29d8fcbcc5ad8d4d362d121d566e1c91e18b9a764f1de3b4da365fdf442e084862fd6d0ef012d7721da92f5b07e0e"), Config.HookEngine, function(v)
    Config.HookEngine = v
    if v then
        HookRegistry.installNamecall()
        notify(__S("a74fc035f975139792b727c9431b18"), HookRegistry.namecallActive and __S("458739e6938e8600d35a4629d345a568e9fc996e8d1842a5ad7a9b6cf62b06e6c875dcc36f1315ee00ecf2dd0dde9db3") or __S("e3beb39714be7da70ad43f70fa7d0b843d2aa3a3c87c429e41a5541bb4aed9222128db440fb4f3ed769382c2"), 4, CustomIcons.Shield)
    else
        Config.SafeHookMode = false
        notify(__S("81f62d48cf0f4e29fc49dc715cfad9"), __S("202da6f9c8d2a2ba688e9c333c78e78ce11eb6a37a974d6c32faabde23dd72ab5400bc0957f11452e6234a39d1fef205c838c50ebb817fe4b604486edf8f5a8e"), 4, CustomIcons.Stop)
    end
end, CustomIcons.Shield)
TabMisc:AddToggle(__S("be6520aa8150a9f6816ad0dc3ee1062d4fa9"), __S("5c9c9a5be7d159674bb1dff23db4e50209b4a5de6396a02bfb174f5f87dd98bac04474045c7d77fafc32bbfe5ff08aeca6b51058d8d5a6df54d810d3270a08b56fc1289909553190b1c1ed876ce06e45251f7a73b683cbc43dd291bbfd555827d536330151435176a595100956885d5400c07ecd361b697d06d198fbd7f2e90d5b94bc7f9f"), Config.SafeHookMode, function(v)
    Config.SafeHookMode = v
    notify(__S("fad4140cae37c901521cf9064d325f"), v and __S("990b8dbdd021319db377bcc4b60b4f1fe51d0f3f25") or __S("3743076ed15616fa2b8e7c36883d446bee6594d0fe254df9669ea8882171877a5007ea9fa69c3f967a6cf415bd3e3a26"), 3, CustomIcons.Shield)
end, CustomIcons.Shield)
TabMisc:AddButton(__S("d57a811f86de334334db1041ff7343f590dd8325"), __S("73b1fad057887e5fcd09969bfba806cf7a6035a430a2b9d56a874ecc7153e5d2d7aca2a3aa3909c7ee0b6592b9ac6722751a3bde16cd4096353d36eeacbf5d2dd6510460a48461ddd3077244e5ab550b0956aa2960c1bd648c453706829a9a54a947b5b800d8940f18d92f1c"), __S("11e97481c892509eae00"), function()
    UnloadSkillHub()
end, CustomIcons.Stop)
TabMisc:AddLivePanel(__S("b020ee32a46b986be96d117509d202e589d2bfed1019151a433bad61dd31fc"), __S("4e5867e3e6e0050ed5d5426254729eb2909bc50b55d4df59615dd1056b9fd92404a1ff0b030db84f4313c1b04e681b431bada964335ec89d"), 2, diagnosticsText, 132, CustomIcons.Server)
TabMisc:AddButton(__S("ec8fe194c9253fc828889fc94c3415d42b1919cc16087f43a69c0b1a5b9136caa8"), __S("8ac75b45918b47393b855677805268cfa4e9d3e0da78ecec76fcd9e8547c3ea72a1aaafd0793dd987b56fccfefc0cdd3c430266eb9fa702f28fab48a5191cd60e02fe24e7f5455dfe3ee4bb391bca17e78dd9a688f682a46595478cfaf7d116761ba84c5"), __S("28fed4f6450f3161"), function()
    local ok = pcall(function() setclipboard(diagnosticsText()) end)
    notify(__S("c7364ea75295cc3f91fb03a77f22d1"), ok and __S("656dc85848cdb1ae63fdc89b38fbe8f8a2263c010f7c42") or __S("03a54209e8a60d7691e6b79f3b9717eae293bbd534355e06471a5f3b2131254a574849a4abf8cb5300dff139a44ee7aa0fca"), 3, ok and CustomIcons.HubCrest or CustomIcons.Stop)
end, CustomIcons.HubCrest)
TabMisc:AddToggle(__S("a1dcbbba4bd177df2bbaad5b5c43c4effa4051a8bf39"), __S("4014356b80dd5f1b998fd5a82edd3dd8f517db78c61565f5029fcb4f4db1df225d77ef173944d53bfe878d7519d21f67223e7a62aa96e35fd2a049f9ea137292252ad5e04d0044e6ba5d314ad35ad948eec261a7eebe864ce0b30d34d0d4cadbc2201691a62f88f89f08342d2005215a307e1ae841924b3969f6bb5b7b1c68a56d8260262026a782677e5efd16f1d18103afbf"), Config.DebugTrace, function(v) Config.DebugTrace = v end, CustomIcons.Search)
TabMisc:AddToggle(__S("de4baf1c8129ecffd5d52f0a0e251a926babc979e17ad226"), __S("7c8328cd42f052a485c37428d910107825222374b48ba89abfd912128c3816b21e6d9675fb280664c82b6953b5349238834e099bbcd4df960565f9262af2466c0c860aff91698c0e3eb8f7e7d8870698d2cf784f7071c4fec8"), Config.IncrementalUIBuild, function(v) Config.IncrementalUIBuild = v end, CustomIcons.Layers)
TabMisc:AddToggle(__S("1abaa27ec7ddbac97baead565d1da8f1e4e9287c"), __S("b8f21c2f4643c714746f60b8cd55082fe1e367a5083ac5915fdf2b19dd0096df89dd847271f53a6d898b01cdbf0a7d580429eae72fc686e9c070f7c7089f3cf7ebe9fbeb159c308942eabcc985f3f1ce3be64fcae25d9d4a6137e73b68d579a5b5af68417cca3348b5646dfd3d7c082c4f82e30fbbda82d918f93ae3a5073910b2d7e96f95339cd59c028451f56d5c8fd74bd6"), Config.CoreGuiWatch, function(v) Config.CoreGuiWatch = v end, CustomIcons.Server)
TabMisc:AddButton(__S("572995e03e3d2abfd4d3b3b296816ae939"), __S("f5610f918b2d4e816f7eea84a6df36134627d3171db4773079e68bed5f6d37b5e89b5f784fadeb10b7e81aba4697a6ed3c8f32a6a588b87e9f511f0b52f04c63bd75cc33ee98bf3693553c22618babe06f69ce501bd4151a2bf6f3739b8780ea441d2b9e65a736b8116d27a29156c0eee3"), __S("93988942082a1ad9d03704c7"), function()
    if tabSelfTest then
        tabSelfTest(__S("31d002f3c0dea7edd3074b701fcfa9c53af317571214b27e3a020b3a5198076c29e8f2f08e"))
        notify(__S("d0077ca499774ddf3b8cfcf8bce0ee82fe"), __S("6e3ef6558a1fbe31a16990a7527d7a21c6e55a40ca3102a951acda296e3cc3c29edaf158ee0fe2acaabdf404d6be9da345c539d690ca3c4e51e2efdba164fc35a28048"), 4, CustomIcons.Search)
    else
        notify(__S("0c767006c98334bf400f5bc3c0c7f963a1"), __S("aaade9b76e7c6a8b3bfb9df58b43139fc5dfae800e2fbebcbe20065dd0fd443ba769bd7cfd0cbebad0db24833085c9f72d82f52e0b89eaf8cc71f07b5c"), 3, CustomIcons.Stop)
    end
end, CustomIcons.Search)
TabMisc:AddButton(__S("48e56368ef2c8c68da163a5a4954862f914fa622664fcc853f12c78234978a"), __S("e71cdd19d64f2ad7c5ea8112bb8a902137beb5927fb915f81e8881e24770167ebefcfa7030a70d09b6f86a41a45bb14710648f749b42ea25afa543e7abbb278ad63118042c79f8b0d37d5173509f15fbe5ce60b3f710df1611d1373dff9927c02b7703c75b774126509e014c2da6f3eae4d4ed847502474c5572e9c073c646af1e2caa14d59e9026fc21e54f84da3d5bd3c18f7565f2bd593f0f253e"), __S("855456cacd868c012e"), function()
    pcall(function() SkillHubEvidence.report(__S("238bd07bf4aa1d232f797503f3bc7a11d65e47d9fa56cd5493ea0c0fcfc3d6f668f10b422e3c5d0e26584a70")) end)
    notify(__S("c1c34a2ccc5279eaf66b8befc9fb5613a6"), __S("5ffac3ddef35e642a552b9f4e9eddda41cd6825afdacfdaa6d1cd18e3008dab4874fa9ac562a0483a7246ef5154fd5e9325bc08d5a59267bfea4474c801c049e"), 4, CustomIcons.Search)
end, CustomIcons.Search)
TabMisc:AddToggle(__S("fe323d8efc67b5d4dc0096d8a62f119d731015acb3151f18f75626ed52f4c407c26d61705b6832ddf6ae07"), __S("9c69b73f2e61ef7804f0efe14a414b467c2fec4268bd09ec2cf0c702bd82d9f2d9a0ec4af63fb74be7d30c0f1d72fb921eaccfcf202ba23242df708e806179201ffcc465cc493824cded5696c1590f12d3a0359bd22e455e49cc636bf16aa08b1561852b954f9eaf41b815edd0f128bc5199f5898cb22909ddecd3be0522d44c4f2b4a90d539a4f504ddd615463a497b7af1a5dd24f509d57690b6044c6c62e474d57513a27ae47304"), Config.UseVirtualInput, function(v)
    Config.UseVirtualInput = v
    notify(__S("3aa130f01cce7e9b64c3a8f41027f945ef1703"), v and __S("d8d8aaa1c209fa0f25c17b") or __S("771024523b9922c4fcde68ceaaa26f5794a3c9bd19d5f2e898300eb8c224a83483487603ef57c9216ff609dd46dc9fb53b931e7e5967e9f04f8903550eccb1f67d2a"), 3, CustomIcons.Lightning)
end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("15479e030ca09ed349808a5316e71f4030c786fcc01e1b5a75466fdd51c1fb2d7540883531fe91f0d9929d"), __S("b37f17b4204a4a1b71c2b3a53379d778736e5830e335b9b23c2c4156e4dbe4fad1f706e2f8b55020a5a9e0a0bb64da00bb54d9c9151dfdcb0343abba70825c84894b537576fa7a11a73378fdead1e63333812cb609cb2a18e754f249bfd549f26c0c07a1b84f7ea10d8cae0d4aad61097517051eb48ed6799a1b0209"), Config.LogStepErrors, function(v) Config.LogStepErrors = v end, CustomIcons.Search)
TabMisc:AddToggle(__S("51b69165eeead121d689d26fa7c1f814be6fe1c56a1c162384"), __S("efee0b16030addf69cfcb2ea6ffadd32403937b1ed4e56da4580210e289b901803e663f6872372aed70b9385f55316e1ebec3d12c6038f047344af5ab088e472b88041c5e51464ed22cbf1730f9453de39bcd54d311b491f67c42c22daef8295"), Config.FreezeMobAnimations, function(v) Config.FreezeMobAnimations = v end, CustomIcons.Layers)
TabMisc:AddLivePanel(__S("8e2584c7f1b43c9a3231a67f30f81ce06e6d92b73d9578f4203062ba"), __S("2c5cfe78fd72a048cb17319da500ad5355b2a453e632f62bc3a70fe6de9e1627afc8c107853847a552d3bacf"), 1.5, function()
    return string.format(
        "Hook engine    : %s\nNamecall hook  : %s\nIntercepted    : %d calls\nKick guard     : %s\nSecurity block : %s\nSimRadius      : %s\nCoreGui touched: never",
        Config.HookEngine and __S("ca947829a45cf21524069b359f1a7ebec69975") or __S("68cbf1daadd9462304f74d6ba48a86d9cb5762e82cdef2b20d947fbddc64e8a82cf4897d8aced3c8"),
        HookRegistry.namecallActive and __S("07036b8bb3c4f09e4dfd") or __S("a53ae53cdc79813064c96e637cdeee5c9b"),
        HookRegistry.hits or 0,
        HookRegistry.namecallActive and __S("43725eed9f43878483df33") or __S("e1a9d89ec78a24e4d8bf8564"),
        Config.BypassAntiCheat and (__S("7fe1524f9955bd2cf765c7be65") .. #BLOCKED_REMOTE_PATTERNS .. __S("1e18cc006c1866989b7f59ef00")) or __S("bc5045b1edcc96"),
        __S("5a87bf620e0e59c955ea1869efcc18b09785898235099b5f067360751a54a6")
    )
end, 116, CustomIcons.Shield)

TabMisc:AddSection(__S("f8bf39133ae427d14a4b4d12752d5fdbf072127a8136ebe05d21d40411712395277bb5f6d6061407c4"))
TabMisc:AddDropdown(__S("96f6b2c4b47f66545f4cec1e83cf"), __S("352e2c75f2f3a2476ee288e83e47b3def7c71a7d7e80f0aa8a74eb761a917624e680802d35e47b42e32fe194ba238330eed0a36bdae2d2c72b6c7cffc2b36cc707b3f1f0ed44a1c61ce3286df17eb5527f0dc528a5e37df689931bb8d4711872a9680ed742a4"), {__S("d365a626592621"), __S("719d1fd713e9a340"), __S("0fd49988dfb0c093dc62e5")}, Config.GuardMode, function(value)
    Config.GuardMode = value
    Guard.mode = value
    notify(__S("ae0c1339cb56ad2117feb877472c"), value == __S("4c438ceac043726888f036") and __S("ea7b069b6a55a33229afa3be66077c93edaa9abe1eaffd77f8545d987a86cf85ccb1f7f273e97448b119ed0e0d0bae5eb755e8") or (__S("88b2804c627ce8d2e9240b") .. tostring(value)), 4, CustomIcons.Shield)
end, CustomIcons.Shield)
TabMisc:AddLivePanel(__S("26e9f9fd91f0a9c62ab41da1343e32a7"), __S("c52173aee22316afd039bb14cef57e7593dfe4a37f73b33b9d613b24a8ae037f67d550e796fcabb8551e913771a8a79aa902ac30862b122e216330b698c9f148aa"), 2, function()
    return Guard.report()
end, 104, CustomIcons.Shield)
TabMisc:AddButton(__S("6358ed5fa5ed7526f0e9763a2735c16e610c880fcad166b3d494e78dbe4848512f82b7"), __S("01906710ddf6e10b61bc4b30b74daccbb22e49c564a4e0e0b81edc480a4951b47c9bcf405696efad40c20007b094d09e1445f3730f038fa0af562318a5cbe2d4b79fa738fdec94bc8a66f3a6d411516580ce4c717f2f82fa71ae3afeea03438aa7e1be7abee6ed099d9b264f8aed5b035d412408fd80a8bebe0f9c746e0196d0dd3f11ca573cd9c975"), __S("9fc7e0c1addfc52e"), function()
    local text = Guard.report()
    print("[Skill Hub] guard report:\n" .. text)
    if type(setclipboard) == __S("3dff5a720c76128693a6607d") then pcall(setclipboard, text) end
    notify(__S("dc36d4237ddea22f97"), __S("7a6e4dd4ac47d1626ceb0446ce5935ea885e7b6cc3f37158ce5b33030b707b2d31780d0ea53251bd4d284a10a1e7") .. Guard.fingerprint, 4, CustomIcons.Shield)
end, CustomIcons.Shield)
TabMisc:AddButton(__S("18a5c7851d27904ce6456b16fe30bf09517c341b795d4da4"), __S("b6dd41367979f1bd7ee45870ae0f01926ea36ad145fb6cfaf577900fb589253b11c70d617023e1d3fff96f728eb820d6f70c6a7413a54d05c2072c6c42b8f8f8668a9172a4c2f2d906bf96ec35f04e2dc3e0791013dca426b7"), __S("5514bae7e28b49edf7"), function()
    local broken = Guard.audit()
    notify(__S("f34c3498c3c04263e81c27381c971992"), broken == 0 and __S("9183ae49af14b71a69247f2656ada497da581c7a24ba5c8c01bd4d57615be6a3a81f4b8542320e32e3") or (tostring(broken) .. __S("2fbb27fa7828d51fb3c285e6e1bfd530525e39b99c5a71ed4f01e35364a60b1d19a51ba83d24a479ec")), 4, broken == 0 and CustomIcons.Shield or CustomIcons.Stop)
end, CustomIcons.Search)

TabMisc:AddSection(__S("cdf2a1ab1c12bfa65dc39c841d4c22a7c6e1eab0"))
TabMisc:AddButton(__S("6c2a1b5c36fc3370f1c988e156c704fad91e234bd9"), __S("0a61950d9ef4e22a58498304ff2b6b2db1e5891bd6e7179e300875a4e9692e1f4bce704b8ba63a02493f70"), __S("a8990ebe692cd33048313b"), function() invokeCommF(__S("46d0886ff2e4cc81cfc9c9"), __S("e5080220162aba541113e8")) end, CustomIcons.AutoFarm)
TabMisc:AddButton(__S("833f7bd1d97127cff90297e199ebf5ab24e78b4cac"), __S("2176f582129ddb4351302194d0da6c9be9c14dbe3d9bb1e88df88f8ac270438966c17f88c964f7b7a26e8a"), __S("bfae6f33ba9efc5caf5c89"), function() invokeCommF(__S("5de5e8e4cb290d8b9f175d"), __S("fc1d6295bf05d9c23b2cf3")) end, CustomIcons.Shield)
TabMisc:AddToggle(__S("9a54dc46fbd592fb6145ba57703c421b4336cc693caebda96ab5"), __S("388c55f76a0220ec4b726614591cb5610d51e9bfdac7039d751ed3abf2ca02cf553bc5b745d9fde73539c78235f933402bb56a477e223e2ad137689a"), Config.ShowWatermarkHUD, function(v)
    Config.ShowWatermarkHUD = v
    WatermarkBar.Visible = v
end, CustomIcons.HubCrest)
TabMisc:AddToggle(__S("d6c3cfa804a51b5ceedff9c0e4951611aa77e5"), __S("74fb4959ded0849d5080ee94316342561fe12b7a203d6acd01e024eb45aafc"), Config.WalkSpeedEnabled, function(v)
    Config.WalkSpeedEnabled = v
    if not v and getHumanoid() then getHumanoid().WalkSpeed = 16 end
end, CustomIcons.Lightning)
TabMisc:AddSlider(__S("1332c30a949d17950d3464261513bff0faa6da"), __S("b16a3cbb26aa5c7dc95abea196b607a04b1bd269a67d564aeb"), 16, 200, Config.WalkSpeedValue, function(v) Config.WalkSpeedValue = v end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("4fa1b66cd0209499e22a884e64dadb98a6d47c"), __S("edd9301dbfdb1ad9b3c0554c644c9552872870b21bf5d16de2d194136777c8"), Config.JumpPowerEnabled, function(v)
    Config.JumpPowerEnabled = v
    if not v and getHumanoid() then getHumanoid().JumpPower = 50 end
end, CustomIcons.Lightning)
TabMisc:AddSlider(__S("8c10a9ce50282e4cb1335023ed1ff788b9e1e0"), __S("2a48237fafe9f9c17d856b40c59b3a9279bffb254f"), 50, 350, Config.JumpPowerValue, function(v) Config.JumpPowerValue = v end, CustomIcons.Lightning)
TabMisc:AddToggle(__S("c87f9d3012522e0c680c"), __S("66b716e10332ceff8ec4e024de7c566a42d1a62b5b2aec21edb4ddb6d844036eb1ff8a93"), Config.NoClip, function(v) Config.NoClip = v end, CustomIcons.Shield)

TabMisc:AddSection(__S("04ee90922f30da56a0fbf88ea81d4194ea0083d97817efff496b2537"))
TabMisc:AddButton(__S("a3260a43a63c2a2720e83c1d2c091a1388d3ffffcb79ff4b962650"), __S("415d83f4848a87127c7702a21e5c6d990f622d7df1bad5927f957f077f2b50b7fd28fbf8d46f4ea1b67e01e88e0e6479133161aed3f1"), __S("df94fda547b69fc4281b59b7db82"), function()
    local rem = ReplicatedStorage:FindFirstChild(__S("7dcc77563719c784dd60fd"))
    local redeem = rem and rem:FindFirstChild(__S("1c03f10784bd87cdfe8e"))
    for _, code in ipairs(ACTIVE_CODES) do
        pcall(function() if redeem then redeem:InvokeServer(code) end end)
        task.wait(0.1)
    end
    notify(__S("ba3b6ab88d5b22a84458d843ec67c5eada60"), __S("5872e469847dcca84ff3899121965125d49f5f63d19cd643c535623d51d345bfc16af71161132315bfb5"), 3.5, CustomIcons.HubCrest)
end, CustomIcons.HubCrest)
TabMisc:AddButton(__S("f6aa5e1a2848a439c6a1944a155afda2ee47f683f82092dbb8ee4a79"), __S("94e1d7cb63ae4e1ef82e3d50e40037eaca9301049ed8ced22c8e9540f1c6e577a7753caf3954943052179d7a167c4739aa14f586c3aa9bfbe10fcf5dfbcc48"), __S("3319517c48b12321033cb8a6"), function()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA(__S("d150cb2d9561e61deaae4aae")) then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA(__S("6f8844dee77fae6574f7cde21e6afa79c1083b")) or v:IsA(__S("0dbfbe8fec94a5db48")) then v.Enabled = false end
        end
    end)
    notify(__S("abf73840991c79ea36e07ef902"), __S("4a2eb1f19e83446f6abe6d576739c4d320fef6b52e5df61eb75dc1dba752d93f2d8206"), 2.5, CustomIcons.Lightning)
end, CustomIcons.Lightning)
TabMisc:AddButton(__S("e8662ba219240fb1a8bf4c6e2b8ae085f5975e146bd9ee318d"), __S("869da5531a5f4ad49e26a57639689ef5d2c507775e20a74c5ba5c52cbcae9872cd0c02028e6e936524ae6def781d18"), __S("24d51f040c892737a734"), function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end, CustomIcons.Loop)
TabMisc:AddButton(__S("c30c98b5ebeaa0e7d1f8d6c43338"), __S("61441266eaf94275bf124576723f5e6bdc78f8f7d520f16d47598a22548cc1e4319b228967c952d65340ecc749a69753"), __S("ff7b8c17434a0d"), function()
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
        Hooks.notify(__S("9db305c8beaa94c755bef125bdf64adab7881f6dee33627061ff"), Config.AimLock and __S("3bea7f795e6082ca965299") or __S("da21f92ada692833431f5f66"), 2.5, CustomIcons.Aim)
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        Config.FlyEnabled = not Config.FlyEnabled
        setFlyState(Config.FlyEnabled)
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
                                                                                     
        if Config.FlyEnabled then flyPark(not Fly.parked) end
    end
end)

                                                                               
                                                                             
                                                            
markRespawnQuiet = function(seconds)
    RespawnQuietUntil = math.max(RespawnQuietUntil, os.clock() + (seconds or 2.5))
    trace(__S("785972dbe8d49769107730b1289fb81ed782e3bb38b8e9dfa7c3a3c00f2b"))
end

local function watchDeath(char)
    local hum = char and char:FindFirstChildOfClass(__S("1690ec8cc4a78756ee03addb"))
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
    print(__S("b4c8663d21600adbf494470beae53ce74280e3ca579c9a74"))
end

                                                                               
                                                                              
                                               
tabCensus = function(label)
    local parts = {}
    for _, entry in ipairs(TabRegistry) do
        local page = entry.tab and entry.tab.page
        local count = -1
        if page then pcall(function() count = #page:GetChildren() end) end
        table.insert(parts, string.format(__S("52ffdfeeaa7159c8d1"), entry.name, count >= 0 and tostring(count) or __S("f137599f02")))
    end
    print(string.format(__S("8f6ed350c9f5bfe878c3a16b0bd8804eba0371ca41e64b11"), tostring(label), table.concat(parts, __S("2da64d0162966d4b"))))
    return parts
end

tabSelfTest = function(reason)
    tabCensus(reason or __S("cbddc6b2a395057adb9966522c8e"))
    for _, entry in ipairs(TabRegistry) do
        SkillHubStep(__S("6a154063fb5e338e729ed02688f28c8fd7f804") .. entry.name, function()
            if entry.tab and entry.tab.Select then entry.tab.Select() end
            local page = entry.tab and entry.tab.page
            if not (page and page.Visible) then error(__S("084cba14830debb811d869c3a93c5b7b94254998954747b4551b438dbf0aaa"), 0) end
        end)
    end
end

tabCensus(__S("a68433c5af416707ae9482307e49"))

Guard.audit()
Guard.startAudit()

                                                                            
                                                                           
                                                                              
                                                                          
SharedEnv.SkillHubInstance = setmetatable({
    version = __S("44bbad764fe8d60d"),
    banner = __S("e2f32727ff0e1e0f9abe7cb9cda5520b2495290c4d2c187e68"),
    config = Config,
    hookActive = function() return HookRegistry.namecallActive end,
    unload = UnloadSkillHub,
                                                        
    tabCensus = function() return tabCensus(__S("812aa0d8348177ab0119d5405c2be2c3e7f9b7bc891a42")) end,
    tabSelfTest = function() return tabSelfTest(__S("1f621a89e490724a4244f35b86ee94d6b2b6fc4e00a8706cf76a")) end,
                                                                             
    guard = {
        fingerprint = Guard.fingerprint,
        licensed = Guard.licensed,
        mode = Guard.mode,
        report = function() return Guard.report() end,
    },
}, {
    __metatable = __S("bd99943a46094997169d60ce665b503ef2a97455d80d2a2fae87e511def78573"),
    __newindex = function() error(__S("5bd10deb2e723c416e72f763a6fe3797671a2489970fd1454aaeb9679b6352bf0be9e142ca8b8891359b81994196891fd75fdca7"), 2) end,
})

print(string.format(__S("fa08879c9a541a4f9a0c4e8e6973c76da276b0977701f8b2af238bc911f0d3c02d05e3d60ef3059a3ae88af2be3cd5ac110721746eb798f237cef6f41f47e8241cccafae7080aebe06173ed8adb6726af424f4b04fdaeafb260fd925f19b8a073fda27a1c3336a8145463ac7fa0e67a97acd34d20ccfea6ca45bdd09ccc5c1a04b0cb25876b25ba845"),
    ExecutorName, CURRENT_SEA, tostring(SEA_DETECT_SOURCE),
    tostring(Config.HookEngine),
    HookRegistry.namecallActive and __S("9840014d18559a27bd84") or __S("36777afe45c756"),
    Config.UseVirtualInput and __S("d4aef4af9d6f") or __S("72e66e601a103a"),
    tostring(Config.GuardMode), Guard.fingerprint))

notify(
    __S("111de8118d3e9e68c616fd9bdef5baaebbcb12eea0c08aba96") .. (Config.ShowAuthor == false and "" or (__S("af5561c2d45d32e00a3286") .. tostring(Config.Author))),
    string.format(__S("4d8cdb730036116b3cabf1f28c6354640bdbe0c6d1fbd0e893123cc0ac89a827bbde1683f1b4154699b75721f7801c7c12bfca8ee8e8961bb019a59cfa9c1d85bbdb9c4f4dba077e2680a02172e48304aea20e00d9a97bdeeaff0fee4c976c05b766b9205f40f0c79a853393446435f2d2e3debad2250aefb1edbc1cb1bf72185a32"), CURRENT_SEA, tostring(SEA_DETECT_SOURCE)),
    5,
    CustomIcons.HubCrest
)
