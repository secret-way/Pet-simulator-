local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Pet Equip System",
    LoadingTitle = "Pet Equip System",
    LoadingSubtitle = "by Scripting",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PetEquip",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Main Section
local MainSection = MainTab:CreateSection("Main Controls")

local AltInput = MainTab:CreateInput({
    Name = "Alt Username",
    PlaceholderText = "Enter alt username",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        alt = Text
    end,
})

local StatusLabel = MainTab:CreateLabel("Status: Ready")

local StartButton = MainTab:CreateButton({
    Name = "Start Transfer",
    Callback = function()
        if alt == nil or alt == "" then
            Rayfield:Notify({
                Title = "Error",
                Content = "Please enter alt username first!",
                Duration = 3,
                Image = 4483362458,
            })
            return
        end
        
        StatusLabel:Set("Status: Starting...")
        
        -- Запускаем скрипт в отдельной корутине
        task.spawn(function()
            local success, errorMsg = pcall(function()
                function getsave()
                    return workspace.__REMOTES.Core["Get Stats"]:InvokeServer().Save
                end

                function getpets()
                    return getsave().Pets
                end

                function getequippedpets()
                    local t = {}
                    for _, p in pairs(getpets()) do
                        if p.e then
                            t[#t+1] = p
                        end
                    end
                    return t
                end

                local mp = getsave().MaxPets
                local T = workspace.__REMOTES.Game.Trading
                local IR = workspace.__REMOTES.Game.Inventory
                local ge = false
                local con

                repeat
                    task.wait()
                    if con then con:Disconnect() con = nil end
                    local lastTradeId = nil
                    
                    StatusLabel:Set("Status: Waiting for trade...")
                    
                    con = game:FindFirstChild('Trade Update', true).OnClientEvent:Connect(function(id)
                        lastTradeId = id
                    end)
                    
                    repeat task.wait(.25) 
                        StatusLabel:Set("Status: Sending trade request...")
                    until T:InvokeServer("InvSend", game.Players[alt]) == true
                    
                    repeat task.wait() 
                        StatusLabel:Set("Status: Waiting for trade ID...")
                    until lastTradeId

                    local TotalIn = 0
                    local TotalE = #getequippedpets()
                    
                    StatusLabel:Set("Status: Adding pets to trade... (" .. TotalE .. " pets)")
                    
                    for _, p in pairs(getequippedpets()) do
                        task.spawn(function()
                            T:InvokeServer("Add", lastTradeId, p.id)
                            TotalIn = TotalIn + 1
                        end)
                    end
                    
                    repeat task.wait(.1) 
                        StatusLabel:Set("Status: Adding pets... " .. TotalIn .. "/" .. TotalE)
                    until TotalIn == TotalE

                    local curr = #getpets()
                    T:InvokeServer("Ready", lastTradeId)
                    
                    StatusLabel:Set("Status: Waiting for trade completion...")
                    
                    repeat task.wait(.1) until curr ~= #getpets()
                    task.spawn(function() T:InvokeServer("Cancel", lastTradeId) end)
                    
                    local TEquipped = 0
                    local TFoundNonEquipped = 0
                    local absT = 0
                    
                    StatusLabel:Set("Status: Equipping new pets...")
                    
                    for _, p in pairs(getpets()) do
                        if not p.e then
                            absT = absT + 1
                            if TFoundNonEquipped ~= mp then
                                TFoundNonEquipped = TFoundNonEquipped + 1
                                task.spawn(function()
                                    IR:InvokeServer('Equip', p.id)
                                    TEquipped = TEquipped + 1
                                end)
                            end
                        end
                    end
                    
                    repeat task.wait() 
                        StatusLabel:Set("Status: Equipping... " .. TEquipped .. "/" .. TFoundNonEquipped)
                    until TEquipped == TFoundNonEquipped
                    
                    ge = (absT == TFoundNonEquipped)
                    repeat task.wait(.1) until curr <= #getpets()

                until #getequippedpets() == 0 or ge
                
                StatusLabel:Set("Status: Completed!")
                
                Rayfield:Notify({
                    Title = "Success",
                    Content = "Pet transfer completed!",
                    Duration = 5,
                    Image = 4483362458,
                })
            end)
            
            if not success then
                StatusLabel:Set("Status: Error occurred!")
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Script error: " .. tostring(errorMsg),
                    Duration = 5,
                    Image = 4483362458,
                })
            end
        end)
    end,
})

local StopButton = MainTab:CreateButton({
    Name = "Stop Transfer",
    Callback = function()
        if con then 
            con:Disconnect() 
            con = nil
        end
        StatusLabel:Set("Status: Stopped by user")
        
        Rayfield:Notify({
            Title = "Stopped",
            Content = "Transfer process has been stopped",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- Info Section
local InfoSection = MainTab:CreateSection("Information")

local EquippedLabel = MainTab:CreateLabel("Equipped Pets: 0")
local TotalPetsLabel = MainTab:CreateLabel("Total Pets: 0")
local MaxPetsLabel = MainTab:CreateLabel("Max Pets: 0")

-- Функция для обновления информации о питомцах
local function updatePetInfo()
    local success, result = pcall(function()
        local save = getsave()
        local equipped = #getequippedpets()
        local total = #getpets()
        local maxPets = save.MaxPets
        
        EquippedLabel:Set("Equipped Pets: " .. equipped)
        TotalPetsLabel:Set("Total Pets: " .. total)
        MaxPetsLabel:Set("Max Pets: " .. maxPets)
    end)
end

-- Кнопка обновления информации
local RefreshButton = MainTab:CreateButton({
    Name = "Refresh Pet Info",
    Callback = updatePetInfo
})

-- Автоматическое обновление информации каждые 5 секунд
task.spawn(function()
    while true do
        updatePetInfo()
        task.wait(5)
    end
end)

-- Settings Section
local SettingsSection = SettingsTab:CreateSection("UI Settings")

local ToggleUI = SettingsTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Callback = function(Keybind)
        Rayfield:Notify({
            Title = "UI Toggle",
            Content = "UI toggle keybind set to: " .. Keybind,
            Duration = 2,
            Image = 4483362458,
        })
    end,
})

local DestroyGUI = SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- Загрузка сохраненных настроек
Rayfield:LoadConfiguration()

-- Первоначальное обновление информации
updatePetInfo()

Rayfield:Notify({
    Title = "Pet Equip System Loaded",
    Content = "Enter alt username and click Start Transfer",
    Duration = 5,
    Image = 4483362458,
})