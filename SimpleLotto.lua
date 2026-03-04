-- 1. INITIAL SETUP & REPAIR LOGIC
local Lotto = { players = {}, tickets = {}, total = 0, active = false }
local WhisperQueue = {} 
SimpleLottoHistory = SimpleLottoHistory or {}

local function InitializeSettings()
    SimpleLottoSettings = SimpleLottoSettings or {}
    SimpleLottoSettings.maxTickets = SimpleLottoSettings.maxTickets or 5
    SimpleLottoSettings.price = SimpleLottoSettings.price or 5
    SimpleLottoSettings.winnerSplit = SimpleLottoSettings.winnerSplit or 70
    if not SimpleLottoSettings.channels then
        SimpleLottoSettings.channels = { GUILD = false, RAID = true, PARTY = false }
    end
end

-- 2. WHISPER THROTTLER
local isWhispering = false
local function ProcessWhisperQueue()
    if #WhisperQueue > 0 then
        isWhispering = true
        local nextMsg = table.remove(WhisperQueue, 1)
        SendChatMessage(nextMsg.text, "WHISPER", nil, nextMsg.target)
        C_Timer.After(0.3, ProcessWhisperQueue)
    else
        isWhispering = false
    end
end

local function ThrottledWhisper(target, text)
    table.insert(WhisperQueue, {target = target, text = text})
    if not isWhispering then ProcessWhisperQueue() end
end

-- 3. MAIN WINDOW
local MainFrame = CreateFrame("Frame", "SimpleLottoFrame", UIParent)
MainFrame:SetSize(300, 510)
MainFrame:SetPoint("CENTER")
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
MainFrame:SetFrameStrata("HIGH")
MainFrame:Hide()

local bgMain = MainFrame:CreateTexture(nil, "BACKGROUND")
bgMain:SetAllPoints(MainFrame)
bgMain:SetColorTexture(0, 0, 0, 0.7)

MainFrame.title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
MainFrame.title:SetPoint("TOP", MainFrame, "TOP", 0, -10)
MainFrame.title:SetText("|cFFFFD100Simple|r |cFFFF0000Lotto|r |cFF00FF00Master|r")

-- RESTORED CLOSE BUTTON
local CloseBtn = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", 0, 0)
CloseBtn:SetScript("OnClick", function() 
    MainFrame:Hide() 
    if SimpleLottoSettingsFrame then SimpleLottoSettingsFrame:Hide() end
    if SimpleLottoHistoryFrame then SimpleLottoHistoryFrame:Hide() end
end)

-- 4. SETTINGS WINDOW
local SettingsFrame = CreateFrame("Frame", "SimpleLottoSettingsFrame", MainFrame)
SettingsFrame:SetSize(220, 360) 
SettingsFrame:SetPoint("TOPRIGHT", MainFrame, "TOPLEFT", -2, 0)
SettingsFrame:Hide()

local bgSet = SettingsFrame:CreateTexture(nil, "BACKGROUND")
bgSet:SetAllPoints(SettingsFrame)
bgSet:SetColorTexture(0, 0, 0, 0.8)

SettingsFrame.title = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SettingsFrame.title:SetPoint("TOP", SettingsFrame, "TOP", 0, -10)
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

local slider = CreateFrame("Slider", "SimpleLottoSplitSlider", SettingsFrame, "OptionsSliderTemplate")
slider:SetPoint("TOP", 0, -135)
slider:SetSize(140, 17)
slider:SetMinMaxValues(0, 100)
slider:SetValueStep(1)
_G[slider:GetName()..'Low']:SetText('Bank')
_G[slider:GetName()..'High']:SetText('Win')

local splitDisplay = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
splitDisplay:SetPoint("TOP", slider, "BOTTOM", 0, -20)

local function UpdateSliderText(val) 
    local rounded = math.floor(val + 0.5)
    splitDisplay:SetText(string.format("Winner: %d%% | Bank: %d%%", rounded, 100 - rounded)) 
end

slider:SetScript("OnValueChanged", function(self, value) UpdateSliderText(value) end)

local function CreateArrow(text, point, x, delta)
    local btn = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate")
    btn:SetSize(20, 20)
    btn:SetText(text)
    btn:SetPoint(point, slider, x, 0)
    btn:SetScript("OnClick", function() 
        local current = math.floor(slider:GetValue() + 0.1)
        slider:SetValue(math.max(0, math.min(100, current + delta)))
        UpdateSliderText(slider:GetValue())
    end)
    return btn
end
CreateArrow("<", "RIGHT", "LEFT", -5, 0)
CreateArrow(">", "LEFT", "RIGHT", 5, 0)

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

SettingsFrame:SetScript("OnShow", function()
    InitializeSettings()
    editMax:SetText(SimpleLottoSettings.maxTickets)
    editPrice:SetText(SimpleLottoSettings.price)
    slider:SetValue(SimpleLottoSettings.winnerSplit)
    UpdateSliderText(SimpleLottoSettings.winnerSplit)
    checkGuild:SetChecked(SimpleLottoSettings.channels.GUILD)
    checkRaid:SetChecked(SimpleLottoSettings.channels.RAID)
    checkParty:SetChecked(SimpleLottoSettings.channels.PARTY)
end)

local saveSetBtn = CreateFrame("Button", nil, SettingsFrame, "GameMenuButtonTemplate")
saveSetBtn:SetSize(120, 25)
saveSetBtn:SetPoint("BOTTOM", 0, 15)
saveSetBtn:SetText("Save Settings")
saveSetBtn:SetScript("OnClick", function()
    SimpleLottoSettings.maxTickets = tonumber(editMax:GetText()) or 5
    SimpleLottoSettings.price = tonumber(editPrice:GetText()) or 5
    SimpleLottoSettings.winnerSplit = math.floor(slider:GetValue() + 0.5)
    SimpleLottoSettings.channels.GUILD = checkGuild:GetChecked()
    SimpleLottoSettings.channels.RAID = checkRaid:GetChecked()
    SimpleLottoSettings.channels.PARTY = checkParty:GetChecked()
    SettingsFrame:Hide()
end)

-- 5. HISTORY WINDOW
local HistoryFrame = CreateFrame("Frame", "SimpleLottoHistoryFrame", MainFrame)
HistoryFrame:SetSize(350, 400)
HistoryFrame:SetPoint("TOPLEFT", MainFrame, "TOPRIGHT", 2, 0)
HistoryFrame:Hide()

local bgHist = HistoryFrame:CreateTexture(nil, "BACKGROUND")
bgHist:SetAllPoints(HistoryFrame)
bgHist:SetColorTexture(0, 0, 0, 0.8)

HistoryFrame.title = HistoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
HistoryFrame.title:SetPoint("TOP", HistoryFrame, "TOP", 0, -10)
HistoryFrame.title:SetText("Lotto History Log")

local HistoryScroll = CreateFrame("ScrollFrame", nil, HistoryFrame, "UIPanelScrollFrameTemplate")
HistoryScroll:SetPoint("TOPLEFT", 10, -35)
HistoryScroll:SetPoint("BOTTOMRIGHT", -30, 45)
local HistoryContent = CreateFrame("Frame", nil, HistoryScroll)
HistoryContent:SetSize(300, 1)
HistoryScroll:SetScrollChild(HistoryContent)
local HistoryText = HistoryContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HistoryText:SetPoint("TOPLEFT", 5, -5)
HistoryText:SetJustifyH("LEFT")
HistoryText:SetWidth(290)

local function UpdateHistoryUI()
    local log = ""
    for i = #SimpleLottoHistory, 1, -1 do log = log .. SimpleLottoHistory[i] .. "\n\n" end
    HistoryText:SetText(log)
    HistoryContent:SetHeight(HistoryText:GetHeight() + 20)
end

local clearLogBtn = CreateFrame("Button", nil, HistoryFrame, "GameMenuButtonTemplate")
clearLogBtn:SetSize(120, 25)
clearLogBtn:SetPoint("BOTTOM", 0, 12)
clearLogBtn:SetText("Clear History")
clearLogBtn:SetScript("OnClick", function() 
    SimpleLottoHistory = {} 
    UpdateHistoryUI() 
end)

-- 6. REFRESH & BROADCAST
local function MultiBroadcast(msg)
    if not msg or not SimpleLottoSettings.channels then return end
    local s = SimpleLottoSettings.channels
    if s.GUILD and IsInGuild() then SendChatMessage(msg, "GUILD") end
    if s.RAID and UnitInRaid("player") then SendChatMessage(msg, "RAID") end
    if s.PARTY and UnitInParty("player") then SendChatMessage(msg, "PARTY") end
end

local function RefreshUI()
    local text, count = "", 0
    local names = {}
    for n in pairs(Lotto.players) do table.insert(names, n) end
    table.sort(names)
    for _, n in ipairs(names) do
        local d = Lotto.players[n]
        local info = type(d) == "string" and ("|cFFFFD100["..d.."]|r") or (d .. " tkt")
        text = text .. "|cFFFFFFFF" .. n .. ":|r " .. info .. "\n"
        if type(d) == "number" then count = count + d end
    end
    ListText:SetText(text)
    StatusText:SetText(Lotto.active and "|cFFFF0000Waiting for Roll|r" or ("|cFFFFFF00Pot:|r "..(count * SimpleLottoSettings.price).."g  |cFF00FF00Tkts:|r "..count))
end

-- 7. MAIN UI BUTTONS
local function CreateBtn(text, width, x, y, parent)
    local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    btn:SetSize(width, 25)
    btn:SetPoint("BOTTOM", x, y)
    btn:SetText(text)
    return btn
end

local ScrollFrame = CreateFrame("ScrollFrame", nil, MainFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 10, -70)
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
    MultiBroadcast(string.format("Lotto Live! %dg/tkt (max %d). Trade %s. Payout: %d%% win / %d%% bank.", s.price, s.maxTickets, UnitName("player"), s.winnerSplit, 100-s.winnerSplit))
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
    end
    Lotto.active = true
    MultiBroadcast("Lotto CLOSED! Total tickets: "..Lotto.total..". Whisper 'tickets' for numbers. Please /roll "..Lotto.total)
    RefreshUI()
end)

CreateBtn("History Log", 130, -70, 70, MainFrame):SetScript("OnClick", function() 
    if HistoryFrame:IsShown() then HistoryFrame:Hide() else UpdateHistoryUI() HistoryFrame:Show() end 
end)

CreateBtn("Settings", 130, 70, 70, MainFrame):SetScript("OnClick", function() 
    if SettingsFrame:IsShown() then SettingsFrame:Hide() else SettingsFrame:Show() end 
end)

CreateBtn("Full Reset All", 270, 0, 40, MainFrame):SetScript("OnClick", function() 
    Lotto = { players = {}, tickets = {}, total = 0, active = false } 
    RefreshUI() 
end)

-- 8. LOGIC & EVENTS
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", function(self, event, msg, sender)
    if event == "ADDON_LOADED" and msg == "SimpleLotto" then
        InitializeSettings()
    elseif event == "CHAT_MSG_SYSTEM" and Lotto.active then
        local name, roll, low, high = msg:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
        if name == UnitName("player") and tonumber(high) == Lotto.total then
            local winner = Lotto.tickets[tonumber(roll)]
            if winner then
                local s = SimpleLottoSettings
                local pot = Lotto.total * s.price
                local winP = math.floor(pot * (s.winnerSplit/100))
                local res = string.format("Winner: %s (Ticket %d)! Payout: %dg (G-Bank: %dg)", winner, tonumber(roll), winP, pot - winP)
                table.insert(SimpleLottoHistory, "|cFF00FF00" .. date("%H:%M") .. ":|r " .. res)
                MultiBroadcast(res)
                Lotto.active = false
                RefreshUI()
                if HistoryFrame:IsShown() then UpdateHistoryUI() end
            end
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local p = sender:gsub("%-.+", "")
        if (msg:lower() == "tickets" or msg:lower() == "numbers") and Lotto.players[p] then
            ThrottledWhisper(sender, "Lotto: " .. (Lotto.active and "Numbers ["..Lotto.players[p].."]" or "Tickets: "..Lotto.players[p]))
        end
    end
end)

SLASH_SIMPLELOTTO1 = "/sl"
SlashCmdList["SIMPLELOTTO"] = function() if MainFrame:IsShown() then MainFrame:Hide() else MainFrame:Show() RefreshUI() end end
