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
    
    con = game:FindFirstChild('Trade Update', true).OnClientEvent:Connect(function(id)
        lastTradeId = id
    end)
    
    repeat task.wait(.25) until T:InvokeServer("InvSend", game.Players[alt]) == true
    repeat task.wait() until lastTradeId
    
    local TotalIn = 0
    local TotalE = #getequippedpets()
    
    for _, p in pairs(getequippedpets()) do
        task.spawn(function()
            T:InvokeServer("Add", lastTradeId, p.id)
            TotalIn = TotalIn + 1
        end)
    end
    
    repeat task.wait(.1) until TotalIn == TotalE
    
    local curr = #getpets()
    T:InvokeServer("Ready", lastTradeId)
    
    repeat task.wait(.1) until curr ~= #getpets()
    task.spawn(function() T:InvokeServer("Cancel", lastTradeId) end)
    
    local TEquipped = 0
    local TFoundNonEquipped = 0
    local absT = 0
    
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
    
    repeat task.wait() until TEquipped == TFoundNonEquipped
    ge = (absT == TFoundNonEquipped)
    repeat task.wait(.1) until curr <= #getpets()
    
until #getequippedpets() == 0 or ge