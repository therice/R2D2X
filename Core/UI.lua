--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')

function AddOn:GetResponseColor(name)
    return self:GetResponse(name).color:GetRGBA()
end

function AddOn.GetDiffColor(num)
    if not num or num == "" then num = 0 end
    if num > 0 then return C.Colors.Green:GetRGBA() end
    if num < 0 then return C.Colors.LuminousOrange:GetRGBA() end
    return C.Colors.Aluminum:GetRGBA()
end