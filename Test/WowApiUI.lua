local frames, FrameClass = {}, {}

FrameClass.methods = {
    "SetScript", "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents", "Show", "Hide", "IsShown",
    "ClearAllPoints", "SetParent", "GetName", "SetOwner", "SetHyperlink", "NumLines", "SetPoint", "SetSize", "SetFrameStrata",
    "SetBackdrop", "CreateFontString", "SetNormalFontObject", "SetHighlightFontObject", "SetNormalTexture", "GetNormalTexture",
    "SetPushedTexture", "GetPushedTexture", "SetHighlightTexture", "GetHighlightTexture", "SetText", "GetScript",
    "EnableMouse", "SetAllPoints", "SetBackdropColor", "SetBackdropBorderColor", "SetWidth", "SetHeight", "GetParent",
    "GetFrameLevel", "SetFrameLevel", "CreateTexture", "SetFontString", "SetDisabledFontObject", "SetID", "SetToplevel",
    "GetFont", "SetWordWrap", "SetJustifyH", "SetMotionScriptsWhileDisabled", "SetDisabledTexture",
    "SetAttribute", "SetScale", "GetObjectType", "IsVisible", "EnableKeyboard", "SetJustifyV", "GetHeight",
    "GetObjectType", "SetMovable", "RegisterForDrag", "HookScript", "SetTextColor", "RegisterForClicks", "GetFontString",
    "SetPushedTextOffset", "GetWidth", "SetFontObject", "SetTextInsets"
}

function FrameClass:New(name)
    local frame = {}
    for _,method in ipairs(self.methods) do
        frame[method] = self[method]
    end
    local frameProps = {
        events = {},
        scripts = {},
        timer = GetTime(),
        name = name,
        isShow = true,
        parent = nil,
        text = nil,
        textures = {}
    }
    return frame, frameProps
end

function FrameClass:SetID(id)

end

function FrameClass:SetToplevel(top)

end

function FrameClass:GetObjectType()
    return "Frame"
end

function FrameClass:SetMovable()

end

function FrameClass:RegisterForDrag()

end

function FrameClass:RegisterForClicks()

end

function FrameClass:SetText(text)
    frames[self].text = text
end

function FrameClass:SetTextColor()

end


function FrameClass:SetScript(script,handler)
    frames[self].scripts[script] = handler
end

function FrameClass:HookScript()

end

function FrameClass:GetScript(script)
    return frames[self].scripts[script]
end

function FrameClass:RegisterEvent(event)
    frames[self].events[event] = true
end

function FrameClass:UnregisterEvent(event)
    frames[self].events[event] = nil
end

function FrameClass:UnregisterAllEvents(frame)
    for event in pairs(frames[self].events) do
        frames[self].events[event] = nil
    end
end

function FrameClass:Show()
    frames[self].isShow = true
end

function FrameClass:Hide()
    frames[self].isShow = false
end

function FrameClass:IsShown()
    return frames[self].isShow
end

function FrameClass:IsVisible()
    return self:IsShown()
end

function FrameClass:ClearAllPoints()

end

function FrameClass:SetParent(parent)
    frames[self].parent = parent
end

function FrameClass:GetParent()
    return frames[self].parent
end

function FrameClass:GetFontString()

end

function FrameClass:SetPushedTextOffset()

end

function FrameClass:SetFrameLevel(l)
end

function FrameClass:EnableKeyboard() end

function FrameClass:SetJustifyV()

end

function FrameClass:GetFrameLevel()
    return 0
end

function FrameClass:GetName()
    return frames[self].name
end

function FrameClass:SetOwner(owner, anchor)

end

function FrameClass:SetHyperlink(link)

end

function FrameClass:NumLines()
    return 0
end

function FrameClass:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy)

end

function FrameClass:SetSize(x, y)

end

function FrameClass:GetHeight()
    return 250
end

function FrameClass:SetFrameStrata(strata)

end

function FrameClass:SetBackdrop(bgFile, edgeFile, tile, tileSize, edgeSize, insets)

end

function FrameClass:CreateFontString(name, layer, inheritsFrom)
    return CreateFrame("FontString", name)
end

function FrameClass:SetWidth(width)

end

function FrameClass:GetWidth()
    return 100
end

function FrameClass:SetHeight(width)

end

function FrameClass:SetNormalFontObject(font)

end

function FrameClass:SetHighlightFontObject(font)

end

function FrameClass:SetFontString(font)

end

function FrameClass:GetFont()
    return nil, nil, nil
end

function FrameClass:SetDisabledFontObject(font)

end

function FrameClass:SetWordWrap(wrap)

end

function FrameClass:SetJustifyH(just)

end

function FrameClass:SetMotionScriptsWhileDisabled(enabled)

end

function FrameClass:SetDisabledTexture(texture)

end

function FrameClass:SetAttribute(k, v)

end

function FrameClass:SetScale(scale)

end

function FrameClass:GetObjectType()
    return frames[self].type
end

function FrameClass:CreateTexture(name, texture, texturePath)
    return CreateTexture(name, texture, texturePath)
end

function FrameClass:SetNormalTexture(texture, texturePath)
    local texture = CreateTexture("normal", texture, texturePath)
    frames[self].textures['normal'] = texture
end

function FrameClass:GetNormalTexture()
    return frames[self].textures['normal']
end

function FrameClass:SetPushedTexture(texture, texturePath)
    local texture = CreateTexture("pushed", texture, texturePath)
    frames[self].textures['pushed'] = texture
end

function FrameClass:GetPushedTexture()
    return frames[self].textures['pushed']
end

function FrameClass:SetHighlightTexture(texture, texturePath)
    local texture = CreateTexture("highlight", texture, texturePath)
    frames[self].textures['highlight'] = texture
end

function FrameClass:GetHighlightTexture()
    return frames[self].textures['highlight']
end

function FrameClass:EnableMouse(on)

end

function FrameClass:SetAllPoints()

end

function FrameClass:SetBackdropColor(r, g, b)

end

function FrameClass:SetBackdropBorderColor(r, g, b)

end

function FrameClass:SetFontObject(font) end

function FrameClass:SetTextInsets(a, b, c, d) end

function CreateFrame(kind, name, parent)
    local frame, internal = FrameClass:New(name)
    internal.parent = parent
    internal.type = kind
    frame[0] = '(userdata)'
    frames[frame] = internal
    if name then
        _G[name] = frame
    end
    return frame
end

UIParent = CreateFrame('Frame', 'UIParent', {})
GameTooltip = CreateFrame('Frame', 'GameTooltip', UIParent)

_G.UIParent = UIParent
_G.GameTooltip = GameTooltip

local textures, TextureClass = {}, {}

TextureClass.methods = {
    "SetTexCoord", "SetAllPoints", "Hide", "SetTexture", "SetBlendMode", "SetWidth", "SetHeight", "SetPoint",
    "SetVertexColor", "SetColorTexture", "SetDrawLayer", "SetDesaturated"
}

function TextureClass:New(t)
    local texture = {}
    for _,method in ipairs(self.methods) do
        texture[method] = self[method]
    end

    local textureProps = {
        texture = t,
        texturePath = nil,
        coord = {}
    }

    return texture, textureProps
end

function TextureClass:SetTexCoord(left, right, top, bottom)

end

function TextureClass:SetColorTexture()

end

function TextureClass:SetAllPoints()

end

function TextureClass:Hide()

end

function TextureClass:SetTexture(texture)

end

function TextureClass:SetBlendMode(mode)

end

function TextureClass:SetWidth(width)

end

function TextureClass:SetHeight(width)

end

function TextureClass:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy)

end

function TextureClass:SetVertexColor(r, g, b)

end

function TextureClass:SetDrawLayer(layer) end

function TextureClass:SetDesaturated(saturated) end

function CreateTexture(name, texture, texturePath)
    local tex, internal = TextureClass:New(name)
    internal.texture = texture
    internal.texturePath = texturePath
    internal.coord = {}
    textures[tex] = internal
    if name then
        _G[name] = tex
    end
    return tex
end

function WoWAPI_FireEvent(event,...)
    for frame, props in pairs(frames) do
        if props.events[event] then
            if props.scripts["OnEvent"] then
                for i=1,select('#',...) do
                    _G["arg"..i] = select(i,...)
                end
                _G.event=event
                props.scripts["OnEvent"](frame,event,...)
            end
        end
    end
end

function WoWAPI_FireUpdate(forceNow)
    if forceNow then
        _time = forceNow
    end
    local now = GetTime()
    for frame,props in pairs(frames) do
        if props.isShow and props.scripts.OnUpdate then
            if now == 0 then
                props.timer = 0	-- reset back in case we reset the clock for more testing
            end
            _G.arg1=now-props.timer
            props.scripts.OnUpdate(frame,now-props.timer)
            props.timer = now
        end
    end
end

