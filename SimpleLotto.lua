-- 1. INITIAL SETUP & REPAIR LOGIC
local Lotto = { players = {}, tickets = {}, total = 0, active = false }
SimpleLottoHistory = SimpleLottoHistory or {}

-- This function repairs old save files and sets defaults
local function InitializeSettings()
    SimpleLottoSettings = SimpleLottoSettings or {}
    SimpleLottoSettings.maxTickets = SimpleLottoSettings.maxTickets or 5
    SimpleLottoSettings.price = SimpleLottoSettings.price or 5
    SimpleLottoSettings.winnerSplit = SimpleLottoSettings.winnerSplit or 70

    -- Critical Fix: Force channels table to exist for users updating from old versions
    if not SimpleLottoSettings.channels then
        SimpleLottoSettings.channels = { GUILD = false, RAID = true, PARTY = false }
    end
end

-- 2. MAIN WINDOW (CENTER PANEL)
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

MainFrame.CloseButton:HookScript("OnClick", function() 
    if SimpleLottoSettingsFrame then SimpleLottoSettingsFrame:Hide() end
    if SimpleLottoHistoryFrame then SimpleLottoHistoryFrame:Hide() end
end)

-- 3. SETTINGS WINDOW (LEFT PANEL)
local SettingsFrame = CreateFrame("Frame", "SimpleLottoSettingsFrame", MainFrame, "BasicFrameTemplateWithInset")
SettingsFrame:SetSize(220, 360) 
SettingsFrame:SetPoint("TOPRIGHT", MainFrame, "TOPLEFT", -2, 0)
SettingsFrame:Hide()
SettingsFrame.title = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SettingsFrame.title:SetPoint("LEFT", SettingsFrame.TitleBg, "LEFT", 5, 0)
SettingsFrame.title:SetText("Lotto Settings")

local function CreateEditBox(label, y)
    local lbl = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", 15, y)
    lbl:SetText(label)
    local eb = CreateFrame("EditBox", nil, SettingsFrame, "InputBoxTemplate")
    eb:SetSize(50, 20)
    eb:SetPoint("TOPRIGHT", -15, y)
    eb:SetAutoFocus(false)
    return eb
end

local editMax = CreateEditBox("Max Tickets:", -40)
local editPrice = CreateEditBox("Gold/Ticket:", -75)

-- SLIDER & PRECISION ARROWS
local sliderLabel = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sliderLabel:SetPoint("TOP", 0, -110)
sliderLabel:SetText("Payout Split")

local slider = CreateFrame("Slider", "SimpleLottoSplitSlider", SettingsFrame, "OptionsSliderTemplate")
slider:SetPoint("TOP", 0, -135)
slider:SetSize(140, 17)
slider:SetMinMaxValues(0, 100)
slider:SetValueStep(1)
slider:SetObeyStepOnDrag(true)
_G[slider:GetName()..'Low']:SetText('Bank')
_G[slider:GetName()..'High']:SetText('Win')

local splitDisplay = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
splitDisplay:SetPoint("TOP", slider, "BOTTOM", 0, -20)

local function UpdateSliderText(val) 
    splitDisplay:SetText(string.format("Winner: %d%% | Bank: %d%%", val, 100 - val)) 
end
slider:SetScript("OnValueChanged", function(self, value) UpdateSliderText(value) end)

local function CreateArrow(text, point, x, delta)
    local btn = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate")
    btn:SetSize(20, 20)
    btn:SetText(text)
    btn:SetPoint(point, slider, x, 0)
    btn:SetScript("OnClick", function() slider:SetValue(slider:GetValue() + delta) end)
    return btn
end
CreateArrow("<", "RIGHT", "LEFT", -5, -1)
CreateArrow(">", "LEFT", "RIGHT", 5, 1)

-- CHANNEL CHECKBOXES
local chanLabel = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
chanLabel:SetPoint("TOPLEFT", 15, -190)
chanLabel:SetText("Announce Channels:")

local function CreateCheck(label, y)
    local cb = CreateFrame("CheckButton", nil, SettingsFrame, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 15, y)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    cb.text:SetText(label)
    return cb
end

local checkGuild = CreateCheck("Guild", -215)
local checkRaid = CreateCheck("Raid", -245)
local checkParty = CreateCheck("Party", -275)

-- Sync UI to settings when opening
SettingsFrame:SetScript("OnShow", function()
    InitializeSettings() -- Final check
    editMax:SetText(SimpleLottoSettings.maxTickets)
    editPrice:SetText(SimpleLottoSettings.price)
    slider:SetValue(SimpleLottoSettings.winnerSplit)
    UpdateSliderText(SimpleLottoSettings.winnerSplit)
    checkGuild:SetChecked(SimpleLottoSettings.channels.GUILD)
    checkRaid:SetChecked(SimpleLottoSettings.channels.RAID)
    checkParty:SetChecked(SimpleLottoSettings.channels.PARTY)
end)

-- BROADCAST HELPER
local function MultiBroadcast(msg)
    if not msg or not SimpleLottoSettings.channels then return end
    local s = SimpleLottoSettings.channels
    if s.GUILD and IsInGuild() then SendChatMessage(msg, "GUILD") end
    if s.RAID and UnitInRaid("player") then SendChatMessage(msg, "RAID") end
    if s.PARTY and UnitInParty("player") then SendChatMessage(msg, "PARTY") end
end

local saveSetBtn = CreateFrame("Button", nil, SettingsFrame, "GameMenuButtonTemplate")
saveSetBtn:SetSize(120, 25)
saveSetBtn:SetPoint("BOTTOM", 0, 15)
saveSetBtn:SetText("Save Settings")
saveSetBtn:SetScript("OnClick", function()
    SimpleLottoSettings.maxTickets = tonumber(editMax:GetText()) or 5
    SimpleLottoSettings.price = tonumber(editPrice:GetText()) or 5
    SimpleLottoSettings.winnerSplit = math.floor(slider:GetValue())
    SimpleLottoSettings.channels.GUILD = checkGuild:GetChecked()
    SimpleLottoSettings.channels.RAID = checkRaid:GetChecked()
    SimpleLottoSettings.channels.PARTY = checkParty:GetChecked()
    print("|cFF00FF00Lotto:|r Settings Saved.")
    SettingsFrame:Hide()
end)

-- 4. HISTORY WINDOW
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

-- 5. BUTTONS & UI REFRESH
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
    local msg = string.format("Lotto Live! %dg/tkt (max %d). Trade {star} %s {star}. Payout: %d%% winner / %d%% bank.", s.price, s.maxTickets, UnitName("player"), s.winnerSplit, 100 - s.winnerSplit)
    MultiBroadcast(msg)
end)

CreateBtn("Add Target", 130, -70, 130, MainFrame):SetScript("OnClick", function()
    local name = UnitName("target")
    if name and not Lotto.active then
        local n = name:gsub("^%l", string.upper)
        local cur = type(Lotto.players[n]) == "number" and Lotto.players[n] or 0
        if (cur + 1) <= SimpleLottoSettings.maxTickets then Lotto.players[n] = cur + 1 RefreshUI() end
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
    MultiBroadcast("Lotto CLOSED! Total tickets: "..Lotto.total..". Please /roll "..Lotto.total)
    RefreshUI()
end)

CreateBtn("History Log", 130, -70, 70, MainFrame):SetScript("OnClick", function() if HistoryFrame:IsShown() then HistoryFrame:Hide() else UpdateHistoryUI() HistoryFrame:Show() end end)
CreateBtn("Settings", 130, 70, 70, MainFrame):SetScript("OnClick", function() if SettingsFrame:IsShown() then SettingsFrame:Hide() else SettingsFrame:Show() end end)
CreateBtn("Full Reset All", 270, 0, 40, MainFrame):SetScript("OnClick", function() StaticPopup_Show("CONFIRM_LOTTO_RESET") end)
CreateBtn("Clear Log", 100, 0, 10, HistoryFrame):SetScript("OnClick", function() SimpleLottoHistory = {} UpdateHistoryUI() end)

-- 6. LOGIC & EVENTS
StaticPopupDialogs["CONFIRM_LOTTO_RESET"] = {
    text = "Clear ALL current lottery data?", button1 = "Yes", button2 = "No",
    OnAccept = function() Lotto = { players = {}, tickets = {}, total = 0, active = false } RefreshUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", function(self, event, msg, sender)
    if event == "ADDON_LOADED" and msg == "SimpleLotto" then
        InitializeSettings()
    elseif event == "CHAT_MSG_SYSTEM" and Lotto.active then
        local name, roll, low, high = msg:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
        if name and tonumber(high) == Lotto.total then
            local winner = Lotto.tickets[tonumber(roll)]
            if winner then
                local s = SimpleLottoSettings
                local pot = Lotto.total * s.price
                local winP = math.floor(pot * (s.winnerSplit/100))
                local res = string.format("Winner: %s (Ticket %d)! Payout: %dg (G-Bank: %dg)", winner, tonumber(roll), winP, pot - winP)
                table.insert(SimpleLottoHistory, "|cFF00FF00" .. date("%d-%m-%Y") .. ":|r " .. res)
                MultiBroadcast(res)
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
