-- Initial Setup
local Lotto = { players = {}, tickets = {}, total = 0, active = false }
SimpleLottoHistory = SimpleLottoHistory or {}
SimpleLottoSettings = SimpleLottoSettings or {
    maxTickets = 5,
    price = 5,
    winnerSplit = 70,
    bankSplit = 30
}

-- 1. MAIN WINDOW (CENTER PANEL)
local MainFrame = CreateFrame("Frame", "SimpleLottoFrame", UIParent, "BasicFrameTemplateWithInset")
MainFrame:SetSize(300, 510)
MainFrame:SetPoint("CENTER")
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
MainFrame:Hide()

MainFrame.title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MainFrame.title:SetPoint("LEFT", MainFrame.TitleBg, "LEFT", 5, 0)
MainFrame.title:SetText("Simple Lotto Master")

-- Close all windows if Main is closed
MainFrame.CloseButton:HookScript("OnClick", function() 
    if SimpleLottoSettingsFrame then SimpleLottoSettingsFrame:Hide() end
    if SimpleLottoHistoryFrame then SimpleLottoHistoryFrame:Hide() end
end)

-- 2. SETTINGS WINDOW (LEFT PANEL - ATTACHED)
local SettingsFrame = CreateFrame("Frame", "SimpleLottoSettingsFrame", MainFrame, "BasicFrameTemplateWithInset")
SettingsFrame:SetSize(220, 220)
SettingsFrame:SetPoint("TOPRIGHT", MainFrame, "TOPLEFT", -2, 0)
SettingsFrame:Hide()
SettingsFrame.title = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SettingsFrame.title:SetPoint("LEFT", SettingsFrame.TitleBg, "LEFT", 5, 0)
SettingsFrame.title:SetText("Lotto Settings")

local function CreateEditBox(label, y, default)
    local lbl = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", 15, y)
    lbl:SetText(label)
    local eb = CreateFrame("EditBox", nil, SettingsFrame, "InputBoxTemplate")
    eb:SetSize(50, 20)
    eb:SetPoint("TOPRIGHT", -15, y)
    eb:SetAutoFocus(false)
    eb:SetText(default)
    return eb
end

local editMax = CreateEditBox("Max Tickets:", -40, SimpleLottoSettings.maxTickets)
local editPrice = CreateEditBox("Gold/Ticket:", -75, SimpleLottoSettings.price)
local editWinner = CreateEditBox("Winner %:", -110, SimpleLottoSettings.winnerSplit)
local editBank = CreateEditBox("Bank %:", -145, SimpleLottoSettings.bankSplit)

local saveSetBtn = CreateFrame("Button", nil, SettingsFrame, "GameMenuButtonTemplate")
saveSetBtn:SetSize(120, 25)
saveSetBtn:SetPoint("BOTTOM", 0, 15)
saveSetBtn:SetText("Save Settings")
saveSetBtn:SetScript("OnClick", function()
    SimpleLottoSettings.maxTickets = tonumber(editMax:GetText()) or 5
    SimpleLottoSettings.price = tonumber(editPrice:GetText()) or 5
    SimpleLottoSettings.winnerSplit = tonumber(editWinner:GetText()) or 70
    SimpleLottoSettings.bankSplit = tonumber(editBank:GetText()) or 30
    print("|cFF00FF00Lotto:|r Settings Saved.")
    SettingsFrame:Hide()
end)

-- 3. HISTORY WINDOW (RIGHT PANEL - ATTACHED)
local HistoryFrame = CreateFrame("Frame", "SimpleLottoHistoryFrame", MainFrame, "BasicFrameTemplateWithInset")
HistoryFrame:SetSize(350, 400)
HistoryFrame:SetPoint("TOPLEFT", MainFrame, "TOPRIGHT", 2, 0)
HistoryFrame:Hide()
HistoryFrame.title = HistoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
HistoryFrame.title:SetPoint("LEFT", HistoryFrame.TitleBg, "LEFT", 5, 0)
HistoryFrame.title:SetText("Lotto History Log")

local HistoryScroll = CreateFrame("ScrollFrame", nil, HistoryFrame, "UIPanelScrollFrameTemplate")
HistoryScroll:SetPoint("TOPLEFT", 10, -30)
HistoryScroll:SetPoint("BOTTOMRIGHT", -30, 40)
local HistoryContent = CreateFrame("Frame", nil, HistoryScroll)
HistoryContent:SetSize(300, 1)
HistoryScroll:SetScrollChild(HistoryContent)
local HistoryText = HistoryContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HistoryText:SetPoint("TOPLEFT", 5, -5)
HistoryText:SetJustifyH("LEFT")
HistoryText:SetWidth(290)

-- 4. UI REFRESH
local function RefreshUI()
    local text, count = "", 0
    local names = {}
    for n in pairs(Lotto.players) do table.insert(names, n) end
    table.sort(names)
    for _, n in ipairs(names) do
        local d = Lotto.players[n]
        text = text .. "|cFFFFFFFF" .. n .. ":|r " .. (type(d) == "number" and d .. " tkt" or "Assigned") .. "\n"
        if type(d) == "number" then count = count + d end
    end
    ListText:SetText(text)
    StatusText:SetText(Lotto.active and "|cFFFF0000Waiting for Roll|r" or ("|cFFFFFF00Pot:|r "..(count * SimpleLottoSettings.price).."g  |cFF00FF00Tkts:|r "..count))
end

local function UpdateHistoryUI()
    local log = ""
    for i = #SimpleLottoHistory, 1, -1 do log = log .. SimpleLottoHistory[i] .. "\n\n" end
    HistoryText:SetText(log)
end

-- 5. BUTTONS (MAIN PANEL)
local function CreateBtn(text, width, x, y, parent)
    local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    btn:SetSize(width, 25)
    btn:SetPoint("BOTTOM", x, y)
    btn:SetText(text)
    return btn
end

local ScrollFrame = CreateFrame("ScrollFrame", nil, MainFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 10, -65)
ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 190)
local Content = CreateFrame("Frame", nil, ScrollFrame)
Content:SetSize(260, 1)
ScrollFrame:SetScrollChild(Content)
ListText = Content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ListText:SetPoint("TOPLEFT", 5, -5)
ListText:SetJustifyH("LEFT")
StatusText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
StatusText:SetPoint("BOTTOM", 0, 165)

CreateBtn("Announce Start", 270, 0, 450, MainFrame):SetScript("OnClick", function()
    local s = SimpleLottoSettings
    local msg = string.format("Lotto Live! %dg/ticket (max %d). Trade {star} %s {star}. Payout: %d%% winner / %d%% gbank.", s.price, s.maxTickets, UnitName("player"), s.winnerSplit, s.bankSplit)
    SendChatMessage(msg, (UnitInRaid("player") and "RAID") or "SAY")
end)

CreateBtn("Add Target", 130, -70, 130, MainFrame):SetScript("OnClick", function()
    local name = UnitName("target")
    if name and not Lotto.active then
        local n = name:gsub("^%l", string.upper)
        local cur = type(Lotto.players[n]) == "number" and Lotto.players[n] or 0
        if (cur + 1) <= SimpleLottoSettings.maxTickets then
            Lotto.players[n] = cur + 1
            RefreshUI()
        end
    end
end)

CreateBtn("Remove Target", 130, 70, 130, MainFrame):SetScript("OnClick", function()
    local name = UnitName("target")
    if name then Lotto.players[name:gsub("^%l", string.upper)] = nil RefreshUI() end
end)

CreateBtn("Close & Assign", 270, 0, 100, MainFrame):SetScript("OnClick", function()
    if Lotto.active or next(Lotto.players) == nil then return end
    local pool = {}
    Lotto.tickets, Lotto.total = {}, 0
    for n, c in pairs(Lotto.players) do for i=1,c do Lotto.total=Lotto.total+1 table.insert(pool, Lotto.total) end end
    for n, c in pairs(Lotto.players) do
        local myN = {}
        for i=1,c do 
            local t = table.remove(pool, math.random(#pool))
            Lotto.tickets[t] = n
            table.insert(myN, t)
        end
        Lotto.players[n] = table.concat(myN, ", ")
        SendChatMessage("Lotto: Your numbers: ["..Lotto.players[n].."]", "WHISPER", nil, n)
    end
    Lotto.active = true
    SendChatMessage("Lotto CLOSED! Total: "..Lotto.total..". Please /roll "..Lotto.total, "RAID")
    RefreshUI()
end)

CreateBtn("History Log", 130, -70, 70, MainFrame):SetScript("OnClick", function() 
    if HistoryFrame:IsShown() then HistoryFrame:Hide() else UpdateHistoryUI() HistoryFrame:Show() end 
end)
CreateBtn("Settings", 130, 70, 70, MainFrame):SetScript("OnClick", function()
    if SettingsFrame:IsShown() then SettingsFrame:Hide() else SettingsFrame:Show() end
end)
CreateBtn("Full Reset All", 270, 0, 40, MainFrame):SetScript("OnClick", function() StaticPopup_Show("CONFIRM_LOTTO_RESET") end)

-- BUTTON FOR HISTORY FRAME
CreateBtn("Clear Log", 100, 0, 10, HistoryFrame):SetScript("OnClick", function() SimpleLottoHistory = {} UpdateHistoryUI() end)

-- 6. LOGIC & EVENTS
StaticPopupDialogs["CONFIRM_LOTTO_RESET"] = {
    text = "Clear ALL current lottery data?", button1 = "Yes", button2 = "No",
    OnAccept = function() Lotto = { players = {}, tickets = {}, total = 0, active = false } RefreshUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", function(_, event, msg, sender)
    if event == "CHAT_MSG_SYSTEM" and Lotto.active then
        local name, roll, low, high = msg:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
        if name and tonumber(high) == Lotto.total then
            local winner = Lotto.tickets[tonumber(roll)]
            if winner then
                local s = SimpleLottoSettings
                local pot = Lotto.total * s.price
                local winP = math.floor(pot * (s.winnerSplit/100))
                local bP = math.floor(pot * (s.bankSplit/100))
                local res = string.format("Winner: %s (Ticket %d)! Payout: %dg (G-Bank: %dg)", winner, tonumber(roll), winP, bP)
                table.insert(SimpleLottoHistory, "|cFF00FF00" .. date("%d-%m-%Y") .. ":|r " .. res)
                SendChatMessage(res, "RAID")
                Lotto.active = false
                RefreshUI()
                if HistoryFrame:IsShown() then UpdateHistoryUI() end
            end
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local p = sender:gsub("%-.+", "")
        if (msg:lower() == "tickets" or msg:lower() == "numbers") and Lotto.players[p] then
            SendChatMessage("Lotto: " .. (Lotto.active and "Numbers ["..Lotto.players[p].."]" or "Tickets: "..Lotto.players[p]), "WHISPER", nil, sender)
        end
    end
end)

SLASH_SIMPLELOTTO1 = "/sl"
SlashCmdList["SIMPLELOTTO"] = function() if MainFrame:IsShown() then MainFrame:Hide() else MainFrame:Show() RefreshUI() end end
