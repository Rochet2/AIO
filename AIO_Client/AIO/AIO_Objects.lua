--[[
    Copyright (C) 2014-  Rochet2 <https://github.com/Rochet2>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
]]

-- http://www.wowwiki.com/Widget_handlers
-- http://www.wowwiki.com/Widget_API

--
-- Below is copy paste from server side AIO_Objects.lua
--

-- All methods are created dynamically from the strings below
local ObjectTypes =
{
    --[[
    
    -- Frame type name used when creating etc
    ["FrameType"] =
    {
        -- Note that if something is edited on client side, you cant use Get methods on server to get the values
        -- Should be rather obvious though.
        -- Only if you set the width for example on server side to something, you can then get the width you set
        -- Almost all GET methods can return nil (GetName, GetChildren etc wont return nil)
        
        -- Inherited frame types (table of type names (strings))
        -- If an object type inherits another type, it wont inherit the inherits
        Inherits = {"FrameType1", "FrameType2"},
        
        -- Get and Set methods (table of function name parts (strings))
        -- Example: Frame:GetName() Frame:SetName("name")
        GetSet_Methods = {"Name", "Width", "Height"},
        
        -- Methods that wont/cant be created to use Get (and set) (table of function names (strings))
        Methods = {"Hide", "Rise"},
    },
    
    ]]
    ["UIObject"] =
    {
        Inherits = {
        },
        GetSet_Methods = {
            "Alpha",
        },
        Methods = {
            "GetName",
            "GetParent",
            -- "GetChildren", -- Commented out for now as it should be only a Frame method
            "GetTemplate",
            "GetObjectType",
            "IsObjectType",
            
            -- This will be same as obj["VarName"] = params
            "SetVar",
        },
    },
    ["AnimationGroup"] =
    {
        Inherits = {
            "UIObject",
        },
        GetSet_Methods = {
            "Looping",
            "Script",
        },
        Methods = {
            "Play",
            "Pause",
            "Stop",
            "Finish",
            -- "GetProgress",
            -- "IsDone",
            -- "IsPlaying",
            -- "IsPaused",
            -- "GetDuration",
            -- "GetLoopState",
            -- "CreateAnimation", -- TODO
            "HasScript",
        },
    },
    ["Animation"] =
    {
        Inherits = {
            "UIObject",
        },
        GetSet_Methods = {
            "StartDelay",
            "Duration",
            "EndDelay",
            "MaxFramerate",
            "Order",
            "Smoothing",
            "Script",
        },
        Methods = {
            "Play",
            "Pause",
            "Stop",
            -- "IsDone",
            -- "IsPlaying",
            -- "IsPaused",
            -- "IsStopped",
            -- "IsDelaying",
            -- "GetElapsed",
            -- "GetProgress",
            -- "GetSmoothProgress",
            -- "GetProgressWithDelay",
            "SetParent",
            "GetRegionParent",
            "HasScript",
        },
    },
    ["FontInstance"] =
    {
        Inherits = {
            "UIObject",
        },
        GetSet_Methods = {
            "Font",
            "FontObject",
            "JustifyH",
            "JustifyV",
            "ShadowColor",
            "ShadowOffset",
            "Spacing",
            "TextColor",
        },
        Methods = {
        },
    },
    ["Region"] =
    {
        Inherits = {
            "UIObject",
        },
        GetSet_Methods = {
            "Height",
            "Point",
            "Size",
            "Width",
        },
        Methods = {
            "ClearAllPoints",
            "CreateAnimationGroup",
            "GetAnimationGroups",
            -- "GetBottom",
            -- "GetCenter",
            -- "GetLeft",
            -- "GetNumPoints",
            -- "GetRect",
            -- "GetRight",
            -- "GetTop",
            "Hide",
            -- "IsDragging",
            -- "IsProtected",
            -- "IsShown",
            -- "IsVisible",
            "SetAllPoints",
            "SetParent",
            "Show",
            "StopAnimating",
        },
    },
    ["Alpha"] =
    {
        Inherits = {
            "UIObject",
            "Animation",
        },
        GetSet_Methods = {
            "Change",
        },
        Methods = {
        },
    },
    ["Path"] =
    {
        Inherits = {
            "UIObject",
            "Animation",
        },
        GetSet_Methods = {
            "Curve",
        },
        Methods = {
            -- "CreateControlPoint", -- TODO? -- Is this supposed to return something?
            -- "GetControlPoints", -- TODO?
            -- "GetMaxOrder",
        },
    },
    ["Rotation"] =
    {
        Inherits = {
            "UIObject",
            "Animation",
        },
        GetSet_Methods = {
            "Degrees",
            "Radians",
            "Origin",
        },
        Methods = {
        },
    },
    ["Scale"] =
    {
        Inherits = {
            "UIObject",
            "Animation",
        },
        GetSet_Methods = {
            "Scale",
            "Origin",
        },
        Methods = {
        },
    },
    ["Translation"] =
    {
        Inherits = {
            "UIObject",
            "Animation",
        },
        GetSet_Methods = {
            "Offset",
        },
        Methods = {
        },
    },
    ["Font"] =
    {
        Inherits = {
            "UIObject",
            "FontInstance",
        },
        GetSet_Methods = {
        },
        Methods = {
            -- "CopyFontObject",
        },
    },
    ["Frame"] =
    {
        Inherits = {
            "UIObject",
            "Region",
        },
        GetSet_Methods = {
            "Backdrop",
            "BackdropBorderColor",
            "BackdropColor",
            "ClampRectInsets",
            "Depth",
            "FrameLevel",
            "FrameStrata",
            "HitRectInsets",
            "ID",
            "MaxResize",
            "MinResize",
            "Movable",
            "Scale",
            "Resizable",
            "Toplevel",
            "IgnoreDepth",
            "ClampedToScreen",
            "EnabledKeyboard",
            "EnabledMouse",
            "EnabledMouseWheel",
            "Script",
            "UserPlaced",
        },
        Methods = {
            "CreateFontString",
            "CreateTexture",
            -- "CreateTitleRegion", -- TODO? How is a title region named?
            "DisableDrawLayer",
            "EnableDrawLayer",
            -- "EnableKeyboard", -- Renamed to SetEnabledKeyboard
            -- "EnableMouse", -- Renamed to SetEnabledMouse
            -- "EnableMouseWheel", -- Renamed to SetEnabledMouseWheel
            -- "GetAttribute",
            "GetChildren",
            -- "GetEffectiveAlpha",
            -- "GetEffectiveDepth",
            -- "GetEffectiveScale",
            "GetFrameType",
            "GetNumChildren",
            "GetNumRegions",
            "GetRegions",
            -- "GetTitleRegion", -- TODO? CreateTitleRegion
            "HasScript",
            "HookScript",
            -- "IgnoreDepth", -- Renamed to SetIgnoreDepth
            -- "IsClampedToScreen", -- Renamed to GetClampedToScreen
            "IsEventRegistered",
            "IsFrameType",
            -- "IsIgnoringDepth", -- Renamed to GetIgnoreDepth
            -- "IsKeyboardEnabled", -- Renamed to GetEnabledKeyboard
            -- "IsMouseEnabled", -- Renamed to GetEnabledMouse
            -- "IsMouseWheelEnabled", -- Renamed to GetEnabledMouseWheel
            -- "IsMovable", -- Renamed to GetMovable
            -- "IsResizable", -- Renamed to GetResizable
            -- "IsToplevel", -- Renamed to GetTopLevel
            -- "IsUserPlaced", -- Renamed to GetUserPlaced
            "Lower",
            "Raise",
            "RegisterAllEvents", -- Events not available for IsEventRegistered etc
            "RegisterEvent",
            "RegisterForDrag",
            "StartMoving",
            "StartSizing",
            "StopMovingOrSizing",
            "UnregisterAllEvents",
            "UnregisterEvent",
        },
    },
    ["LayeredRegion"] =
    {
        Inherits = {
            "UIObject",
            "Region",
        },
        GetSet_Methods = {
            "DrawLayer",
            "VertexColor",
        },
        Methods = {
        },
    },
    ["Button"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "ButtonState",
            "DisabledFontObject",
            "DisabledTexture",
            "FontString",
            "HighlightFontObject",
            "HighlightTexture",
            "NormalTexture",
            "NormalFontObject",
            "PushedTextOffset",
            "PushedTexture",
            "Text",
        },
        Methods = {
            "Click",
            "Disable",
            "Enable",
            -- "GetTextHeight",
            -- "GetTextWidth",
            -- "IsEnabled",
            "LockHighlight",
            "RegisterForClicks",
            -- "SetFont", -- Apparently SetFont is not a button method
            "SetFormattedText",
            "UnlockHighlight",
        },
    },
    ["Cooldown"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "Reverse",
        },
        Methods = {
            "SetCooldown",
        },
    },
    ["ColorSelect"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "ColorHSV",
            "ColorRGB",
            "ColorValueTexture",
            "ColorValueThumbTexture",
            "ColorWheelTexture",
            "ColorWheelThumbTexture",
        },
        Methods = {
        },
    },
    ["EditBox"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
            "FontInstance",
        },
        GetSet_Methods = {
            "AltArrowKeyMode",
            "BlinkSpeed",
            "CursorPosition",
            "HistoryLines",
            "HyperlinksEnabled",
            "AutoFocus",
            "MaxBytes",
            "MaxLetters",
            "MultiLine",
            "Number",
            "Numeric",
            "Password",
            "Text",
            "TextInsets",
        },
        Methods = {
            "AddHistoryLine",
            "ClearFocus",
            -- "GetInputLanguage",
            -- "GetNumLetters",
            "HighlightText",
            "Insert",
            -- "IsAutoFocus", -- Renamed to GetAutoFocus
            -- "IsMultiLine", -- Renamed to GetMultiLine
            -- "IsNumeric", -- Renamed to GetNumeric
            -- "IsPassword", -- Renamed to GetPassword
            "SetFocus",
            -- "SetFont", -- Already inherited from FontInstance
            "ToggleInputLanguage",
        },
    },
    ["GameTooltip"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "MinimumWidth",
            "Spell",
            "Owner",
            "Unit",
        },
        Methods = {
            "AddDoubleLine",
            "AddFontStrings",
            "AddLine",
            "AddTexture",
            "AppendText",
            "ClearLines",
            "FadeOut",
            -- "GetAnchorType",
            -- "GetItem",
            -- "IsUnit",
            -- "NumLines",
            "SetAction",
            "SetAuctionCompareItem",
            "SetAuctionItem",
            "SetAuctionSellItem",
            "SetBackpackToken",
            "SetBagItem",
            "SetBuybackItem",
            "SetCurrencyToken",
            "SetFrameStack",
            "SetGlyph",
            "SetGuildBankItem",
            "SetHyperlink",
            "SetHyperlinkCompareItem",
            "SetInboxItem",
            "SetInventoryItem",
            "SetLootItem",
            "SetLootRollItem",
            "SetMerchantCompareItem",
            "SetMerchantItem",
            "SetPadding",
            "SetPetAction",
            "SetQuestItem",
            "SetQuestLogItem",
            "SetQuestLogRewardSpell",
            "SetQuestRewardSpell",
            "SetSendMailItem",
            "SetShapeshift",
            "SetTalent",
            "SetText",
            "SetTracking",
            "SetTradePlayerItem",
            "SetTradeSkillItem",
            "SetTradeTargetItem",
            "SetTrainerService",
            "SetUnitAura",
            "SetUnitBuff",
            "SetUnitDebuff",
        },
    },
    ["MessageFrame"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
            "FontInstance",
        },
        GetSet_Methods = {
            "FadeDuration",
            "Fading",
            "InsertMode",
            "TimeVisible",
        },
        Methods = {
            "AddMessage",
            "Clear",
        },
    },
    ["Minimap"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "Zoom",
        },
        Methods = {
            -- "GetPingPosition",
            -- "GetZoomLevels",
            "PingLocation",
            "SetArrowModel",
            "SetBlipTexture",
            "SetIconTexture",
            "SetMaskTexture",
            "SetPlayerModel",
        },
    },
    ["Model"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "Facing",
            "FogColor",
            "FogFar",
            "FogNear",
            "Light",
            "Model",
            "ModelScale",
            "Position",
        },
        Methods = {
            "AdvanceTime",
            "ClearFog",
            "ClearModel",
            "ReplaceIconTexture",
            "SetCamera",
            "SetGlow",
            "SetSequence",
            "SetSequenceTime",
        },
    },
    ["ScrollFrame"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "HorizontalScroll",
            "ScrollChild",
            "VerticalScroll",
        },
        Methods = {
            -- "GetHorizontalScrollRange",
            -- "GetVerticalScrollRange",
            "UpdateScrollChildRect",
        },
    },
    ["ScrollingMessageFrame"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
            "FontInstance",
        },
        GetSet_Methods = {
            "FadeDuration",
            "Fading",
            "HyperlinksEnabled",
            "InsertMode",
            "MaxLines",
            "TimeVisible",
        },
        Methods = {
            "AddMessage",
            -- "AtBottom",
            -- "AtTop",
            "Clear",
            -- "GetCurrentLine",
            -- "GetCurrentScroll",
            -- "GetNumLinesDisplayed",
            -- "GetNumMessages",
            "PageDown",
            "PageUp",
            "ScrollDown",
            "ScrollToBottom",
            "ScrollToTop",
            "ScrollUp",
            "SetScrollOffset",
            "UpdateColorByID",
        },
    },
    ["SimpleHTML"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "Font",
            "FontObject",
            "HyperlinkFormat",
            "HyperlinksEnabled",
            "JustifyH",
            "JustifyV",
            "ShadowColor",
            "ShadowOffset",
            "Spacing",
            "TextColor",
        },
        Methods = {
            "SetText",
        },
    },
    ["Slider"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "MinMaxValues",
            "Orientation",
            "StepsPerPage",
            "ThumbTexture",
            "Value",
            "ValueStep",
        },
        Methods = {
            "Disable",
            "Enable",
            -- "IsEnabled",
        },
    },
    ["StatusBar"] =
    {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
        },
        GetSet_Methods = {
            "MinMaxValues",
            "Orientation",
            "StatusBarColor",
            "StatusBarTexture",
            "Value",
        },
        Methods = {
        },
    },
    ["CheckButton"] = {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
            "Button",
        },
        GetSet_Methods = {
            "Checked",
            "CheckedTexture",
            "DisabledCheckedTexture",
        },
        Methods = {
        },
    },
    ["LootButton"] = {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
            "Button",
        },
        GetSet_Methods = {
        },
        Methods = {
            "SetSlot",
        },
    },
    ["PlayerModel"] = {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
            "Model",
        },
        GetSet_Methods = {
        },
        Methods = {
            "RefreshUnit",
            "SetCreature",
            "SetRotation",
            "SetUnit",
        },
    },
    ["DressupModel"] = {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
            "Model",
            "PlayerModel",
        },
        GetSet_Methods = {
        },
        Methods = {
            "Dress",
            "TryOn",
            "Undress",
        },
    },
    ["TabardModel"] = {
        Inherits = {
            "UIObject",
            "Region",
            "Frame",
            "Model",
            "PlayerModel",
        },
        GetSet_Methods = {
        },
        Methods = {
            "CanSaveTabardNow",
            "CycleVariation",
            -- "GetLowerBackgroundFileName",
            -- "GetLowerEmblemFileName",
            -- "GetLowerEmblemTexture",
            -- "GetUpperBackgroundFileName",
            -- "GetUpperEmblemFileName",
            -- "GetUpperEmblemTexture",
            "InitializeTabardColors",
            "Save",
        },
    },
    ["Texture"] = {
        Inherits = {
            "UIObject",
            "Region",
            "LayeredRegion",
        },
        GetSet_Methods = {
            "BlendMode",
            "TexCoord",
            "Texture",
            "Desaturated",
        },
        Methods = {
            -- "GetVertexColor", -- Already inherited from
            -- "IsDesaturated", -- Renamed to GetDesaturated
            "SetGradient",
            "SetGradientAlpha",
            "SetRotation",
        },
    },
    ["FontString"] = {
        Inherits = {
            "UIObject",
            "Region",
            "LayeredRegion",
            "FontInstance",
        },
        GetSet_Methods = {
            "NonSpaceWrap",
            "Text",
        },
        Methods = {
            -- "CanNonSpaceWrap", -- Renamed to GetNonSpaceWrap
            -- "GetStringHeight",
            -- "GetStringWidth",
            "SetAlphaGradient",
            "SetFormattedText",
            "SetTextHeight",
        },
    },
}

do
    -- "Dummy" type as ALL methods, inherits ALL ( is all types )
    local Inherits = {}
    local Methods = {}
    local GetSet_Methods = {}
    for Type,t in pairs(ObjectTypes) do
        Inherits[Type] = true
        for k,v in ipairs(t.Methods or {}) do
            Methods[v] = true
        end
        for k,v in ipairs(t.GetSet_Methods or {}) do
            GetSet_Methods[v] = true
        end
    end
    local Dummy = {
        Inherits = {
        },
        GetSet_Methods = {
        },
        Methods = {
        },
    }
    for k,v in pairs(Inherits) do
        table.insert(Dummy.Inherits, k)
    end
    -- for k,v in pairs(GetSet_Methods) do
    --     table.insert(Dummy.GetSet_Methods, k)
    -- end
    -- for k,v in pairs(Methods) do
    --     table.insert(Dummy.Methods, k)
    -- end
    ObjectTypes["Dummy"] = Dummy
end

do
    local function GetSorted(T)
        local t = {}
        for k, v in pairs(T) do
            table.insert(t, k)
        end
        table.sort(t)
        return t
    end

    local methods = {}
    for k, v in ipairs(GetSorted(ObjectTypes) or {}) do
        for k, v in ipairs(ObjectTypes[v].GetSet_Methods or {}) do
            table.insert(methods, "Get"..v)
            table.insert(methods, "Set"..v)
        end
        for k, v in ipairs(ObjectTypes[v].Methods or {}) do
            table.insert(methods, v)
        end
    end
    table.sort(methods)

    local i = 1
    while true do
        if (not methods[i]) then
            break
        end
        if (methods[i] == methods[i+1]) then
           table.remove(methods, i+1)
        else
            i = i+1
        end
    end
    
    local indexes = {}
    for k,v in ipairs(methods) do
        indexes[v] = k
    end

    AIO.METHOD_NAME_TABLE = indexes
    AIO.METHOD_INDEX_TABLE = methods
end
