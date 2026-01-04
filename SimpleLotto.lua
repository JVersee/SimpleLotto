local Lotto = { players = {}, tickets = {}, total = 0, active = false }
SimpleLottoHistory = SimpleLottoHistory or {}

-- 1. THE MAIN WINDOW
local MainFrame = CreateFrame("Frame", "SimpleLottoFrame", UIParent, "BasicFrameTemplateWithInset")
MainFrame:SetSize(300, 480) -- Increased for History button
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

-- 2. HISTORY WINDOW
local HistoryFrame = CreateFrame("Frame", "SimpleLottoHistoryFrame", UIParent, "BasicFrameTemplateWithInset")
HistoryFrame:SetSize(400, 300)
HistoryFrame:SetPoint("CENTER", 50, -50)
HistoryFrame:SetMovable(true)
HistoryFrame:EnableMouse(true)
HistoryFrame:RegisterForDrag("LeftButton")
HistoryFrame:SetScript("OnDragStart", HistoryFrame.StartMoving)
HistoryFrame:SetScript("OnDragStop", HistoryFrame.StopMovingOrSizing)
HistoryFrame:Hide()
HistoryFrame.title = HistoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
HistoryFrame.title:SetPoint("LEFT", HistoryFrame.TitleBg, "LEFT", 5, 0)
HistoryFrame.title:SetText("Lotto History Log")

local HistoryScroll = CreateFrame("ScrollFrame", nil, HistoryFrame, "UIPanelScrollFrameTemplate")
HistoryScroll:SetPoint("TOPLEFT", 10, -30)
HistoryScroll:SetPoint("BOTTOMRIGHT", -30, 40)
local HistoryContent = CreateFrame("Frame", nil, HistoryScroll)
HistoryContent:SetSize(360, 1)
HistoryScroll:SetScrollChild(HistoryContent)
local HistoryText = HistoryContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HistoryText:SetPoint("TOPLEFT", 5, -5)
HistoryText:SetJustifyH("LEFT")

-- 3. UI HELPERS
local function RefreshUI()
    local text, count = "", 0
    local sortedNames = {}
    for n in pairs(Lotto.players) do table.insert(sortedNames, n) end
    table.sort(sortedNames)
    for _, name in ipairs(sortedNames) do
        local data = Lotto.players[name]
        text = text .. "|cFFFFFFFF" .. name .. ":|r " .. (type(data) == "number" and data .. " tkt" or "Assigned") .. "\n"
        if type(data) == "number" then count = count + data end
    end
    ListText:SetText(text)
    StatusText:SetText(Lotto.active and "|cFFFF0000Waiting for Roll|r" or ("|cFFFFFF00Pot:|r "..(count*5).."g  |cFF00FF00Tkts:|r "..count))
end

local function UpdateHistoryUI()
    local logText = ""
    for i = #SimpleLottoHistory, 1, -1 do -- Show newest first
        logText = logText .. SimpleLottoHistory[i] .. "\n\n"
    end
    HistoryText:SetText(logText)
end

local function CreateBtn(text, width, x, y, parent)
    local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    btn:SetSize(width, 25)
    btn:SetPoint("BOTTOM", x, y)
    btn:SetText(text)
    return btn
end

-- 4. MAIN WINDOW ELEMENTS
local ScrollFrame = CreateFrame("ScrollFrame", nil, MainFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 10, -65)
ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 160)
local Content = CreateFrame("Frame", nil, ScrollFrame)
Content:SetSize(260, 1)
ScrollFrame:SetScrollChild(Content)
ListText = Content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ListText:SetPoint("TOPLEFT", 5, -5)
ListText:SetJustifyH("LEFT")
StatusText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
StatusText:SetPoint("BOTTOM", 0, 135)

-- 5. BUTTONS
CreateBtn("Announce Start", 270, 0, 420, MainFrame):SetScript("OnClick", function()
    local msg = "The lottery is live! Ticket price is 5g (max 5 per). Come trade {star} " .. UnitName("player") .. " {star} today. 1st gets 70%, 30% to gbank."
    SendChatMessage(msg, (UnitInRaid("player") and "RAID") or (UnitInParty("player") and "PARTY") or "SAY")
end)

CreateBtn("Add Target", 130, -70, 100, MainFrame):SetScript("OnClick", function()
    local name = UnitName("target")
    if name then SlashCmdList["SIMPLELOTTO"]("add "..name.." 1") RefreshUI() end
end)

CreateBtn("Remove Target", 130, 70, 100, MainFrame):SetScript("OnClick", function()
    local name = UnitName("target")
    if name then SlashCmdList["SIMPLELOTTO"]("remove "..name) RefreshUI() end
end)

CreateBtn("Close & Assign", 270, 0, 70, MainFrame):SetScript("OnClick", function() SlashCmdList["SIMPLELOTTO"]("close") RefreshUI() end)
CreateBtn("View History", 270, 0, 40, MainFrame):SetScript("OnClick", function() 
    if HistoryFrame:IsShown() then HistoryFrame:Hide() else UpdateHistoryUI() HistoryFrame:Show() end 
end)
CreateBtn("Full Reset All", 270, 0, 10, MainFrame):SetScript("OnClick", function() StaticPopup_Show("CONFIRM_LOTTO_RESET") end)

CreateBtn("Clear Log", 100, 0, 10, HistoryFrame):SetScript("OnClick", function() SimpleLottoHistory = {} UpdateHistoryUI() end)

-- 6. LOGIC & EVENTS
StaticPopupDialogs["CONFIRM_LOTTO_RESET"] = {
    text = "Clear ALL current lottery data?", button1 = "Yes", button2 = "No",
    OnAccept = function() Lotto = { players = {}, tickets = {}, total = 0, active = false } RefreshUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

local function HandleSlash(msg)
    local cmd, arg1, arg2 = strsplit(" ", msg)
    if not cmd or cmd == "" then if MainFrame:IsShown() then MainFrame:Hide() else MainFrame:Show() RefreshUI() end return end
    cmd = cmd:lower()
    if cmd == "add" and arg1 and not Lotto.active then
        local name = arg1:gsub("^%l", string.upper)
        local cur = type(Lotto.players[name]) == "number" and Lotto.players[name] or 0
        if (cur + (tonumber(arg2) or 1)) <= 5 then Lotto.players[name] = cur + (tonumber(arg2) or 1) end
    elseif cmd == "remove" and arg1 then
        Lotto.players[arg1:gsub("^%l", string.upper)] = nil
    elseif cmd == "close" and not Lotto.active and next(Lotto.players) then
        local pool = {}
        Lotto.tickets, Lotto.total = {}, 0
        for n, c in pairs(Lotto.players) do for i=1,c do Lotto.total=Lotto.total+1 table.insert(pool, Lotto.total) end end
        for n, c in pairs(Lotto.players) do
            local myN = {}
            for i=1,c do local t=table.remove(pool, math.random(#pool)) Lotto.tickets[t]=n table.insert(myNums or myN, t) end
            Lotto.players[n] = table.concat(myN, ", ")
            SendChatMessage("Lotto: Your numbers: ["..Lotto.players[n].."]", "WHISPER", nil, n)
        end
        Lotto.active = true
        SendChatMessage("Lotto CLOSED! Total: "..Lotto.total..". Please /roll "..Lotto.total, "RAID")
    end
    RefreshUI()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", function(_, event, msg, sender)
    if event == "CHAT_MSG_SYSTEM" and Lotto.active then
        local name, roll, low, high = msg:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
        if name and tonumber(high) == Lotto.total then
            local winN = tonumber(roll)
            local winner = Lotto.tickets[winN]
            if winner then
                local pot = Lotto.total * 5
                local resultStr = string.format("Winner: %s (Ticket %d)! Payout: %dg (G-Bank: %dg)", winner, winN, pot*0.7, pot*0.3)
                local dateStr = date("%d-%m-%Y")
                table.insert(SimpleLottoHistory, "|cFF00FF00" .. dateStr .. ":|r " .. resultStr)
                SendChatMessage(resultStr, "RAID")
                Lotto.active = false
                RefreshUI()
            end
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local trigger = msg:lower()
        if (trigger == "tickets" or trigger == "numbers") and Lotto.players[sender:gsub("%-.+", "")] then
            local p = sender:gsub("%-.+", "")
            SendChatMessage("Lotto: " .. (Lotto.active and "Your numbers ["..Lotto.players[p].."]" or "You have "..Lotto.players[p].." tickets."), "WHISPER", nil, sender)
        end
    end
end)

SLASH_SIMPLELOTTO1 = "/sl"
SlashCmdList["SIMPLELOTTO"] = HandleSlash
