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

local AIO = require("AIO")

local assert = assert
local ipairs = ipairs
local type = type

-- Check if loaded
-- Try to avoid multiple loads with require etc
if (AIO.Mod_Objects) then
    return AIO.Mod_Objects
end
AIO.Mod_Objects = true

-- Table that contains method handler functions for custom frame methods
-- You can create your own custom methods for frames with this
-- Example: MethodHandle["Test"] = function(self, ...) print(self, ...) end
-- Above example will print self (Frame table) along with all passed arguments on the server when a frame uses the method Frame:Test(1,2,3)
local MethodHandle = {}

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

-- Adds a new msg or frame to an initialization message that is sent to the player when he logs in or when he reloads UI (UI init)
function AIO:AddInitMsg(msgorframe)
    assert(not AIO.INITED, "You can only use this function on startup")
    AIO.INIT_MSG = AIO.INIT_MSG or AIO:CreateMsg()
    AIO.INIT_MSG:Append(msgorframe)
end

-- Adds a new function to be called when the player logs in or when he reloads UI (on UI init)
-- Argumets passed: func(player)
-- Called just before sending UI
function AIO:AddPreInitFunc(func)
    assert(type(func) == "function")
    assert(not AIO.INITED, "You can only use this function on startup")
    table.insert(AIO.PRE_INIT_FUNCS, func)
end

-- Adds a new function to be called when the player logs in or when he reloads UI (on UI init)
-- Argumets passed: func(player)
-- Called just after sending UI
function AIO:AddPostInitFunc(func)
    assert(type(func) == "function")
    assert(not AIO.INITED, "You can only use this function on startup")
    table.insert(AIO.POST_INIT_FUNCS, func)
end

-- Creates a new object of given type
-- Used by CreateFrame etc functions to create the base object with needed methods
function AIO:CreateObject(Type, Name, Parent)
    assert(Type)
    if(not Name) then
        -- Nameless, create a name from prefix_NamelessTypeCount
        AIO.NamelessCount = AIO.NamelessCount + 1
        Name = AIO.Prefix.."_"..Type.."_"..AIO.NamelessCount
    end
    if(AIO.Objects[Name]) then
        error("Warning, overwrote object "..Type.." "..Name..", should probably NOT use same name objects!")
    end
    
    local Object = {}
    AIO.Objects[Name] = Object
    AIO:TableMerge(Object, AIO.Object)
    
    Object.Type = Type
    Object.Types = {Type}
    Object.Name = Name
    if (Parent) then
        Object:SetData("Parent", Parent)
        table.insert(Parent:GetChildren(), Object)
    end
    
    -- Add inherited methods
    for k,v in ipairs(ObjectTypes[Type].Inherits or {}) do
        table.insert(Object.Types, v)
        Object:AddMethods(ObjectTypes[v])
    end
    
    -- Add own methods
    Object:AddMethods(ObjectTypes[Type])
    
    if (Object:IsObjectType("Region")) then
        Object.AnimationGroups = {}
    end
    if (Object:IsObjectType("Frame")) then
        Object.Children = {}
    end
    if (Object:IsObjectType("Frame") or Object:IsObjectType("Animation") or Object:IsObjectType("AnimationGroup")) then
        Object.Scripts = {}
    end
    
    return Object
end

-- Base object, the base of all frames etc
AIO.Object = {
    IS_OBJECT = true,
    -- Name
    -- Type
    -- Types
    MSG = AIO:CreateMsg(),
    Data = {},
}

-- Saves a list of data for the Name, which acts as key
-- Will erase the data for the given key if no data given or set data is nil
function AIO.Object:SetData(Name, ...)
    local count = select('#', ...)
    if(count == 0 or (count == 1 and select(1, ...) == nil)) then
        self.Data[Name] = nil
    else
        self.Data[Name] = {...}
    end
end

-- Returns a list of data from the object's data table by a key
function AIO.Object:GetData(Name)
    local valtable = self.Data[Name]
    if(type(valtable) ~= "table") then
        return
    end
    return AIO.unpack(valtable, 1, AIO.maxn(valtable))
end

-- Add a new block to object msg.
-- Action and arguments
function AIO.Object:AddBlock(Name, ...)
    self.MSG:AddBlock(Name, ...)
end

-- Send the object functions etc
function AIO.Object:Send(...)
    local fullmsg = AIO:CreateMsg()
    fullmsg:Append(self) -- Make one big msg block from self and childs
    fullmsg:Send(...) -- send it
    -- Clear messages from self and childs
    self.MSG:Clear()
end

-- Append a msg to the object msg
-- This is just a wrapper
function AIO.Object:Append(...)
    self.MSG:Append(...)
end

-- Clear the msg from frame and childs, if SelfOnly is true, doesnt clear childs
function AIO.Object:Clear(SelfOnly)
    self.MSG:Clear()
    if (SelfOnly) then
        return
    end
    if (self.Children) then
        for k, child in ipairs(self.Children) do
            child:Clear()
        end
    end
end
    
-- Method adder helper functions
-- Adds methods as functions that append the function name, frame name and the arguments to the message
function AIO.Object:AddMethod(MethodName, Func)
    if(self[MethodName]) then
        print("Warning, overwriting "..MethodName.." method for type "..self.Type)
    end
    if(MethodHandle[MethodName]) then
        self[MethodName] = MethodHandle[MethodName]
    else
        -- Client method
        self[MethodName] = Func or function (self, ...)
            self:AddBlock("Method", self:GetName(), MethodName, ...)
        end
    end
end
-- Adds methods, GetSet_Methods methods and inherited methods from ObjectTypes[Type]
function AIO.Object:AddMethods(tbl)
    for k,v in ipairs(tbl.Methods or {}) do
        self:AddMethod(v)
    end
    for k,v in ipairs(tbl.GetSet_Methods or {}) do
        self:AddMethod("Get"..v,
            function(self, ...)
                return self:GetData(v)
            end
        )
        self:AddMethod("Set"..v,
            function(self, ...)
                self:SetData(v, ...)
                self:AddBlock("Method", self:GetName(), "Set"..v, ...)
            end
        )
    end
end

-- Creates a new Frame object and sets all methods and variables for it
function AIO:CreateFrame(Type, Name, Parent, Template)
    assert(Type)
    assert(ObjectTypes[Type], "Invalid frame type"..Type)
    
    -- Frame can probably only have a frame parent
    if(not AIO:IsFrame(Parent)) then
        Parent = nil
    end
    
    -- Frames are objects, which are tables with a message and methods that append stuff to it
    local Frame = AIO:CreateObject(Type, Name, Parent)
    -- Check that the created object inherited Frame type!
    assert(Frame:IsObjectType("Frame"))
    
    Frame.IS_FRAME = true
    Frame.Template = Template
    Frame.RegisteredEvents = {}
    
    -- Append create frame block to the message so the frame is created on client side when the frame is sent
    Frame:AddBlock("Frame", Frame:GetFrameType(), Frame:GetName(), Frame:GetParent(), Template)
    
    return Frame
end

-- Some methods are special or act a bit differently from others etc
-- They need special coding. Here you can see the functions that have server side code.
-- See AIO_BlockHandle.lua on client side for client side special method implementations
function MethodHandle.CreateFontString(self, name, layer, template, ...)
    local fontstr = AIO:CreateObject("FontString", name, self)
    fontstr:SetData("DrawLayer", layer)
    fontstr.Template = template
    self:AddBlock("Method", self:GetName(), "CreateFontString", name, layer, template, ...)
    return fontstr
end
function MethodHandle.CreateTexture(self, name, layer, template, ...)
    local texture = AIO:CreateObject("Texture", name, self)
    texture:SetData("DrawLayer", layer)
    texture.Template = template
    self:AddBlock("Method", self:GetName(), "CreateTexture", name, layer, template, ...)
    return texture
end
function MethodHandle.GetRegionParent(self, ...)
    local parent = self:GetParent()
    local RegionParent = nil
    if(parent) then
        RegionParent = parent:GetParent()
    end
    return RegionParent
end
function MethodHandle.CreateAnimationGroup(self, name, template, ...)
    local group = AIO:CreateObject("AnimationGroup", name, self)
    group.Template = template
    self:AddBlock("Method", self:GetName(), "CreateAnimationGroup", name, template, ...)
    return group
end
function MethodHandle.GetAnimationGroups(self, ...)
    local groups = {}
    for k,v in ipairs(self:GetChildren()) do
        if(v:IsObjectType("AnimationGroup")) then
            table.insert(groups, v)
        end
    end
    -- Should return a table or not?
    return groups
end
function MethodHandle.GetRegions(self, ...)
    local regions = {}
    for k,v in ipairs(self:GetChildren()) do
        if(v:IsObjectType("Region")) then
            table.insert(groups, v)
        end
    end
    -- Should return a table or not?
    return regions
end
function MethodHandle.GetNumRegions(self, ...)
    return #self:GetRegions()
end
function MethodHandle.GetName(self, ...)
    return self.Name
end
function MethodHandle.GetChildren(self, ...)
    return self.Children
end
function MethodHandle.GetNumChildren(self, ...)
    return #self:GetChildren()
end
function MethodHandle.GetTemplate(self, ...)
    return self.Template
end
function MethodHandle.GetFrameType(self, ...)
    return self.Type
end
function MethodHandle.GetObjectType(self, ...)
    return self.Type
end
function MethodHandle.IsFrameType(self, Type)
    for k,v in ipairs(self.Types) do
        if (v == Type) then
            return true
        end
    end
    return false
end
function MethodHandle.IsObjectType(self, Type)
    for k,v in ipairs(self.Types) do
        if (v == Type) then
            return true
        end
    end
    return false
end
function MethodHandle.RegisterEvent(self, event, ...)
    self.RegisteredEvents[event] = true
    self:AddBlock("Method", self:GetName(), "RegisterEvent", event, ...)
end
function MethodHandle.UnregisterEvent(self, event, ...)
    self.RegisteredEvents[event] = nil
    self:AddBlock("Method", self:GetName(), "UnregisterEvent", event, ...)
end
function MethodHandle.IsEventRegistered(self, event, ...)
    return self.RegisteredEvents[event] ~= nil
end
function MethodHandle.GetParent(self, ...)
    return self:GetData("Parent")
end
function MethodHandle.SetParent(self, newparent, ...)
    local oldparent = self:GetParent()
    if (oldparent) then
        local childs = oldparent:GetChildren()
        for i = #childs,1,-1 do
            if (childs[i] == self) then
                table.remove(childs, i)
            end
        end
    end
    table.insert(newparent:GetChildren(), self)
    self:SetData("Parent", newparent, ...)
    self:AddBlock("Method", self:GetName(), "SetParent", newparent, ...)
end
function MethodHandle.SetEnabledKeyboard(self, ...)
    self:SetData("EnabledKeyboard", ...)
    self:AddBlock("Method", self:GetName(), "EnableKeyboard", ...)
end
function MethodHandle.SetEnabledMouse(self, ...)
    self:SetData("EnabledMouse", ...)
    self:AddBlock("Method", self:GetName(), "EnableMouse", ...)
end
function MethodHandle.SetEnabledMouseWheel(self, ...)
    self:SetData("EnabledMouseWheel", ...)
    self:AddBlock("Method", self:GetName(), "EnableMouseWheel", ...)
end

-- When Func is a funcstr, the function is used client side when the Event happens
-- The event parameters will be passed to the function and you can access them with ...

-- When Func is a function, the function is used server side when the Event happens
-- if Func is a function, ClientFunc can be function contents as a string that is executed client side when the event happens
-- ClientFunc is not an AIO:ToFunction() value!
-- The return value(s) of the ClientFunc is added to ClientFuncRet table parameter for the Func executed server side
-- Func arguments will then be (Player, Event, EventParamsTable, ClientFuncRet)
function MethodHandle.SetScript(self, Event, Func, ClientFunc, ...)
    assert(AIO:IsFrame(self), "self not frame")
    assert(type(Event) == "string", "Event not string")
    local ftype = type(Func)
    if(ftype == "function") then
        -- Was server side executable function
        local callback = AIO:ToFunction("local function CliFunc(...) "..(ClientFunc or "").." end local MSG = AIO:CreateMsg() MSG:AddBlock('ServerEvent', '"..Event.."', {...}, {CliFunc(...)}) MSG:Send()")
        self:AddBlock("Method", self:GetName(), "SetScript", Event, callback)
    elseif(ftype == "string") then
        -- Was client side executable function ( func as string with AIO:ToFunction(funcstr) )
        -- Imitate using a method
        self:AddBlock("Method", self:GetName(), "SetScript", Event, Func)
    elseif(ftype == "nil") then
        -- Was nil, erase executed function
        self:AddBlock("Method", self:GetName(), "SetScript", Event, nil)
    else
        error("Func was not a string nor a function")
    end
    self.Scripts[Event] = {Func, ClientFunc, ...}
end
-- Same as SetScrpt
function MethodHandle.HookScript(self, Event, Func, ClientFunc, ...)
    assert(AIO:IsFrame(self), "self not frame")
    assert(type(Event) == "string", "Event not string")
    local ftype = type(Func)
    if(ftype == "function") then
        -- Was server side executable function
        local callback = AIO:ToFunction("local function CliFunc(...) "..(ClientFunc or "").." end local MSG = AIO:CreateMsg() MSG:AddBlock('ServerEvent', '"..Event.."', {...}, {CliFunc(...)}) MSG:Send()")
        self:AddBlock("Method", self:GetName(), "HookScript", Event, callback)
    elseif(ftype == "string") then
        -- Was client side executable function ( func as string with AIO:ToFunction(funcstr) )
        -- Imitate using a method
        self:AddBlock("Method", self:GetName(), "HookScript", Event, Func)
    elseif(ftype == "nil") then
        -- Was nil, erase executed function
        self:AddBlock("Method", self:GetName(), "HookScript", Event, nil)
    else
        error("Func was not a string nor a function")
    end
    self.Scripts[Event] = {Func, ClientFunc, ...}
end
function MethodHandle.GetScript(self, Event, ...)
    return AIO.unpack(self.Scripts[Event], 1, AIO.maxn(self.Scripts[Event]))
end
function MethodHandle.HasScript(self, Event, ...)
    return AIO.unpack(self.Scripts[Event], 1, AIO.maxn(self.Scripts[Event])) ~= nil
end

-- Creates function content as string that returns values IN ORDER from given function executed on objects or object names passed
-- ObjDo accepts an object (or name) and a string. Every other passed argument is an object and every other is a string.
-- The string is a function or variable etc that you want to do with for the object. Can be blank string AIO:ObjDo(Frame, "")
-- Example: AIO:ObjDo(Object, ":GetText()") Results into: " return _G['ObjectName']:GetText() "
-- The string can have a function and arguments etc, example AIO:ObjDo(Frame, ":GetAttribute(prefix, name, suffix)")
-- You can also access variables with using dot . example: AIO:ObjDo(Object, ".Var")
-- Usage:
--[[
local function ToExec(Player, Event, EventParamsTable, ClientFuncRet)
    for k, v in ipairs(ClientFuncRet) do
        print(v) -- Prints the GetText value from all 4 inputs
    end
end
Frame:SetScript("OnClick", ToExec, AIO:ObjDo(Input1, ":GetText()", Input2, ":GetText()", Input3, ":GetText()", "Input4Name", ":GetText()"))
]]
function AIO:ObjDo(...)
    local params = ""
    for i = 1, select('#',...), 2 do
        local Obj = select(i, ...)
        local Do = select(i+1, ...)
        if(AIO:IsObject(Obj)) then
            Obj = Obj:GetName()
        end
        if(Obj and Do) then
            Obj = Obj:gsub('"', '\\"')
            params = params .. ',_G["'..Obj..'"]'..Do
        end
    end
    -- remove the first comma with sub
    return " return "..params:sub(2).." "
end
