local Lotto = { players = {}, tickets = {}, total = 0, active = false }

local function HandleSlash(msg)
    local cmd, arg1, arg2 = strsplit(" ", msg)
    cmd = cmd and cmd:lower()

    -- 1. ADD / UPDATE
    if cmd == "add" and arg1 then
        local count = tonumber(arg2) or 1
        local playerName = arg1:gsub("^%l", string.upper)
        
        local current = type(Lotto.players[playerName]) == "number" and Lotto.players[playerName] or 0
        
        if (current + count) > 5 then
            print("|cFFFF0000Error:|r " .. playerName .. " cannot have more than 5 tickets.")
        else
            Lotto.players[playerName] = current + count
            print("|cFF00FF00Lotto:|r " .. playerName .. " now has " .. Lotto.players[playerName] .. " tickets.")
        end
    
    -- 2. REMOVE
    elseif cmd == "remove" and arg1 then
        local playerName = arg1:gsub("^%l", string.upper)
        Lotto.players[playerName] = nil
        print("|cFFFF0000Lotto:|r Removed " .. playerName)

    -- 3. STATUS
    elseif cmd == "status" then
        print("|cFFFFFF00--- Current Lotto Entries ---|r")
        local currentTotal = 0
        for name, data in pairs(Lotto.players) do
            local count = type(data) == "number" and data or "Closed"
            print(name .. ": " .. count)
            if type(data) == "number" then currentTotal = currentTotal + data end
        end
        if not Lotto.active then print("|cFF00FF00Total Tickets:|r " .. currentTotal .. " (" .. (currentTotal * 5) .. "g pot)") end

    -- 4. CLOSE & ASSIGN
    elseif cmd == "close" then
        if next(Lotto.players) == nil then print("Lotto: No players!"); return end
        
        local pool = {}
        Lotto.tickets = {}
        Lotto.total = 0

        for name, count in pairs(Lotto.players) do
            for i = 1, count do
                Lotto.total = Lotto.total + 1
                table.insert(pool, Lotto.total)
            end
        end

        for name, count in pairs(Lotto.players) do
            local myNumbers = {}
            for i = 1, count do
                local num = table.remove(pool, math.random(#pool))
                Lotto.tickets[num] = name
                table.insert(myNumbers, num)
            end
            Lotto.players[name] = table.concat(myNumbers, ", ")
            SendChatMessage("Lotto: Your ticket numbers are: [" .. Lotto.players[name] .. "]", "WHISPER", nil, name)
        end

        Lotto.active = true
        SendChatMessage("Lotto CLOSED! Total Tickets: " .. Lotto.total .. ". Check whispers for numbers. Whisper 'tickets' to recall. Please /roll " .. Lotto.total, "RAID")

    -- 5. RESET
    elseif cmd == "reset" then
        Lotto = { players = {}, tickets = {}, total = 0, active = false }
        print("|cFFFF0000Lotto: Data Wiped.|r")
    else
        print("|cFFFFFF00Lotto Commands:|r /sl add [name] [amt], /sl remove [name], /sl status, /sl close, /sl reset")
    end
end

-- Event Handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", function(_, event, msg, sender)
    if event == "CHAT_MSG_SYSTEM" and Lotto.active then
        local name, roll, low, high = msg:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
        if name and tonumber(high) == Lotto.total then
            local winNum = tonumber(roll)
            local winnerName = Lotto.tickets[winNum]
            if winnerName then
                local totalGold = Lotto.total * 5
                SendChatMessage("Ticket [" .. winNum .. "] wins! Winner: " .. winnerName .. "! Payout: " .. (totalGold * 0.7) .. "g (G-Bank: " .. (totalGold * 0.3) .. "g)", "RAID")
                Lotto.active = false
            end
        end
    
    elseif event == "CHAT_MSG_WHISPER" then
        local trigger = msg:lower()
        if trigger == "tickets" or trigger == "numbers" then
            local playerName = sender:gsub("%-.+", "")
            local data = Lotto.players[playerName]
            
            if not data then
                SendChatMessage("Lotto: You don't have any tickets registered yet!", "WHISPER", nil, sender)
            elseif Lotto.active then
                SendChatMessage("Lotto: Your numbers are [" .. data .. "]", "WHISPER", nil, sender)
            else
                SendChatMessage("Lotto: You currently have " .. data .. " ticket(s) registered. Numbers will be assigned when the lottery closes!", "WHISPER", nil, sender)
            end
        end
    end
end)

SLASH_SIMPLELOTTO1 = "/sl"
SlashCmdList["SIMPLELOTTO"] = HandleSlash
print("|cFF00FF00SimpleLotto Loaded!|r")