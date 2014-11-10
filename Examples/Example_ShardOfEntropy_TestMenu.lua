-- Example by NotHawthorne and Kaev for ShardOfEntropy project
-- Slightly modified for example purposes and overlapping with other examples

-- Notice that the objects are not named

local AIO = require("AIO")

-- Frame
local Frame = AIO:CreateFrame("Frame", nil, "UIParent", nil)
Frame:SetSize(42, 179)
Frame:SetMovable(false)
Frame:SetEnabledMouse(true)
Frame:RegisterForDrag("LeftButton")
Frame:SetPoint("RIGHT")
Frame:SetClampedToScreen(true)
Frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    edgeSize = 10,
    nsets = { left = 1, right = 1, top = 1, bottom = 1 }
})
-- Frame End

-- Frame Children
local TrainingFrame = AIO:CreateFrame("Frame", nil, nil, "UIPanelDialogTemplate")
TrainingFrame:SetSize(500, 300)
TrainingFrame:SetMovable(true)
TrainingFrame:SetEnabledMouse(true)
TrainingFrame:RegisterForDrag("LeftButton")
TrainingFrame:SetPoint("CENTER")
TrainingFrame:SetClampedToScreen(true)
TrainingFrame:SetBackdrop({
    bgFile = "Interface/AchievementFrame/UI-Achievement-Parchment-Horizontal",
    insets = { left = 9, right = 6, top = 5, bottom = 5 }
})
TrainingFrame:Hide()
-- Frame Children End

-- Buttons
local TrainingButton = AIO:CreateFrame("Button", nil, Frame)
TrainingButton:SetSize(32, 32)
TrainingButton:SetPoint("CENTER", 0, 67)
TrainingButton:SetEnabledMouse(true)
TrainingButton:SetNormalTexture("Interface/ICONS/INV_Misc_Book_11")
TrainingButton:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
TrainingButton:SetPushedTexture("Interface/Buttons/CheckButtonHilight")
TrainingButton:SetScript("OnMouseUp", AIO:ToFunction(TrainingFrame:GetName()..":Show()"))
local TrainingsButton_Tooltip_OnEnter = [[
    GameTooltip:SetOwner(select(1, ...), "ANCHOR_RIGHT")
    GameTooltip:SetText("Test\nNew Line")
    GameTooltip:Show()
]]
TrainingButton:SetScript("OnEnter", AIO:ToFunction(TrainingsButton_Tooltip_OnEnter))
local TrainingsButton_Tooltip_OnLeave = [[
    GameTooltip:Hide()
]]
TrainingButton:SetScript("OnLeave", AIO:ToFunction(TrainingsButton_Tooltip_OnLeave))

local TestButton1 = AIO:CreateFrame("Button", nil, Frame)
TestButton1:SetSize(32, 32)
TestButton1:SetPoint("CENTER", 0, 33)
TestButton1:SetEnabledMouse(true)
TestButton1:SetNormalTexture("Interface/ICONS/Ability_Warrior_StrengthOfArms")
TestButton1:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
TestButton1:SetPushedTexture("Interface/Buttons/CheckButtonHilight")

local TestButton2 = AIO:CreateFrame("Button", nil, Frame)
TestButton2:SetSize(32, 32)
TestButton2:SetPoint("CENTER", 0, -1)
TestButton2:SetEnabledMouse(true)
TestButton2:SetNormalTexture("Interface/ICONS/Spell_Arcane_Rune")
TestButton2:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
TestButton2:SetPushedTexture("Interface/Buttons/CheckButtonHilight")

local TestButton3 = AIO:CreateFrame("Button", nil, Frame)
TestButton3:SetSize(32, 32)
TestButton3:SetPoint("CENTER", 0, -35)
TestButton3:SetEnabledMouse(true)
TestButton3:SetNormalTexture("Interface/ICONS/Achievement_Dungeon_Outland_Dungeon_Hero")
TestButton3:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
TestButton3:SetPushedTexture("Interface/Buttons/CheckButtonHilight")

local TestButton4 = AIO:CreateFrame("Button", nil, Frame)
TestButton4:SetSize(32, 32)
TestButton4:SetPoint("CENTER", 0, -69)
TestButton4:SetEnabledMouse(true)
TestButton4:SetNormalTexture("Interface/ICONS/Achievement_Dungeon_PlagueWing")
TestButton4:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
TestButton4:SetPushedTexture("Interface/Buttons/CheckButtonHilight")
-- Buttons end

-- Add Frames to initialization message. This way they are sent to the client when the player reloads UI or logs in
-- See definition and comments of AddInitMsg for more
AIO:AddInitMsg(Frame)
AIO:AddInitMsg(TrainingFrame)
-- This is an example of a function to be called on UI initialization.
-- See definition and comments of AddInitFunc for more
AIO:AddPreInitFunc(print) -- before init UI, can return false to stop init
-- Sending UI
AIO:AddPostInitFunc(print) -- after init UI
