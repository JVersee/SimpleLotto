local Lotto = { players = {}, tickets = {}, total = 0, active = false }

-- 1. THE MAIN WINDOW
local MainFrame = CreateFrame("Frame", "SimpleLottoFrame", UIParent, "BasicFrameTemplateWithInset")
MainFrame:SetSize(300, 420)
MainFrame:SetPoint("CENTER")
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
MainFrame:Hide()

MainFrame.title = MainFrame:CreateFontString(nil, "OVERLAY")
MainFrame.title:SetFontObject("GameFontHighlight")
MainFrame.title:SetPoint("LEFT", MainFrame.TitleBg, "LEFT", 5, 0)
MainFrame.title:SetText("Simple Lotto Master")

-- 2. SCROLLABLE PLAYER LIST
local ScrollFrame = CreateFrame("ScrollFrame", nil, MainFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 10, -30)
ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 130)

local Content = CreateFrame("Frame", nil, ScrollFrame)
Content:SetSize(260, 1)
ScrollFrame:SetScrollChild(Content)

local ListText = Content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ListText:SetPoint("TOPLEFT", 5, -5)
ListText:SetJustifyH("LEFT")
ListText:SetSpacing(3)

-- 3. STATUS BAR
local StatusText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
StatusText:SetPoint("BOTTOM", 0, 105)
StatusText:SetText("Pot: 0g (0 Tickets)")

-- 4. REFRESH UI FUNCTION
local function RefreshUI()
    local text = ""
    local count = 0
    local sortedNames = {}
    for n in pairs(Lotto.players) do table.insert(sortedNames, n) end
    table.sort(sortedNames)

    for _, name in ipairs(sortedNames) do
        local data = Lotto.players[name]
        local display = type(data) == "number" and data .. " tkt" or "Numbers Assigned"
        text = text .. "|cFFFFFFFF" .. name .. ":|r " .. display .. "\n"
        if type(data) == "number" then count = count + data end
    end
    ListText:SetText(text)
    if Lotto.active then
        StatusText:SetText("|cFFFF0000Lotto Closed - Waiting for Roll|r")
    else
        StatusText:SetText("|cFFFFFF00Pot:|r " .. (count * 5) .. "g  |cFF00FF00Tickets:|r " .. count)
    end
end

-- 5. BUTTON CREATION HELPER
local function CreateBtn(text, width, x, y, parent)
    local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    btn:SetSize(width, 25)
    btn:SetPoint("BOTTOM", x, y)
    btn:SetText(text)
    return btn
end

-- 6. BUTTON ACTIONS
local addBtn = CreateBtn("Add Target", 130, -70, 70, MainFrame)
addBtn:SetScript("OnClick", function()
    local name = UnitName("target")
    if name then SlashCmdList["SIMPLELOTTO"]("add " .. name .. " 1") end
end)

local remBtn = CreateBtn("Remove Target", 130, 70, 70, MainFrame)
remBtn:SetScript("OnClick", function()
    local name = UnitName("target")
    if name then SlashCmdList["SIMPLELOTTO"]("remove " .. name) end
end)

local closeBtn = CreateBtn("Close & Assign", 270, 0, 40, MainFrame)
closeBtn:SetScript("OnClick", function() SlashCmdList["SIMPLELOTTO"]("close") end)

local resetBtn = CreateBtn("Full Reset All", 270, 0, 10, MainFrame)
resetBtn:SetScript("OnClick", function() StaticPopup_Show("CONFIRM_LOTTO_RESET") end)

StaticPopupDialogs["CONFIRM_LOTTO_RESET"] = {
    text = "Are you sure you want to clear ALL lottery data?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function() SlashCmdList["SIMPLELOTTO"]("reset") end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- 7. CORE LOGIC
local function HandleSlash(msg)
    local cmd, arg1, arg2 = strsplit(" ", msg)
    if not cmd or cmd == "" then
        if MainFrame:IsShown() then MainFrame:Hide() else MainFrame:Show() end
        RefreshUI()
        return
    end
    
    cmd = cmd:lower()
    if cmd == "add" and arg1 then
        if Lotto.active then print("Lotto: Cannot add players while a lottery is active. Reset first."); return end
        local playerName = arg1:gsub("^%l", string.upper)
        local count = tonumber(arg2) or 1
        local current = Lotto.players[playerName] or 0
        if (current + count) <= 5 then Lotto.players[playerName] = current + count end
        
    elseif cmd == "remove" and arg1 then
        local playerName = arg1:gsub("^%l", string.upper)
        Lotto.players[playerName] = nil
        
    elseif cmd == "close" then
        if Lotto.active then print("Lotto: Already closed. Waiting for winner or reset."); return end
        if next(Lotto.players) == nil then print("Lotto: No players added."); return end
        
        local pool = {}
        Lotto.tickets = {}
        Lotto.total = 0
        
        -- Create number pool
        for name, count in pairs(Lotto.players) do
            for i = 1, count do 
                Lotto.total = Lotto.total + 1
                table.insert(pool, Lotto.total) 
            end
        end
        
        -- Randomize and Assign
        for name, count in pairs(Lotto.players) do
            local myNumbers = {}
            for i = 1, count do
                local ticketNum = table.remove(pool, math.random(#pool))
                Lotto.tickets[ticketNum] = name
                table.insert(myNumbers, ticketNum)
            end
            Lotto.players[name] = table.concat(myNumbers, ", ")
            SendChatMessage("Lotto: Your numbers: [" .. Lotto.players[name] .. "]", "WHISPER", nil, name)
        end
        
        Lotto.active = true
        SendChatMessage("Lotto CLOSED! Total: " .. Lotto.total .. ". Check whispers for numbers. /roll " .. Lotto.total, "RAID")
        
    elseif cmd == "reset" then
        Lotto = { players = {}, tickets = {}, total = 0, active = false }
    end
    RefreshUI()
end

-- 8. EVENT HANDLER
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", function(_, event, msg, sender)
    if event == "CHAT_MSG_SYSTEM" and Lotto.active then
        local name, roll, low, high = msg:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
        if name and tonumber(high) == Lotto.total then
            local winnerName = Lotto.tickets[tonumber(roll)]
            if winnerName then
                local totalGold = Lotto.total * 5
                SendChatMessage("Winner: " .. winnerName .. " (Ticket " .. roll .. ")! Payout: " .. (totalGold * 0.7) .. "g (Gbank: " .. (totalGold * 0.3) .. "g)", "RAID")
                Lotto.active = false
                RefreshUI()
            end
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local trigger = msg:lower()
        if trigger == "tickets" or trigger == "numbers" then
            local playerName = sender:gsub("%-.+", "")
            local data = Lotto.players[playerName]
            if not data then
                SendChatMessage("Lotto: No tickets yet!", "WHISPER", nil, sender)
            elseif Lotto.active then
                SendChatMessage("Lotto: Your numbers are [" .. data .. "]", "WHISPER", nil, sender)
            else
                SendChatMessage("Lotto: You have " .. data .. " ticket(s).", "WHISPER", nil, sender)
            end
        end
    end
end)

SLASH_SIMPLELOTTO1 = "/sl"
SlashCmdList["SIMPLELOTTO"] = HandleSlash
print("|cFF00FF00SimpleLotto Loaded! Type /sl to toggle UI.|r")
