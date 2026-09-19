local hashesComputed = false
local PED_TATTOOS = {}
local pedModelsByHash = {}

local function tofloat(num)
    return num + 0.0
end

local function forConfiguredAddonHeads(modelName, cb)
    if not modelName or not Config.HeadBlend then return false end

    local function checkModelHeads(modelHeads)
        if type(modelHeads) ~= "table" then return false end

        for configuredHeadId, headConfig in pairs(modelHeads) do
            if cb(tonumber(configuredHeadId), headConfig) then
                return true
            end
        end

        return false
    end

    if checkModelHeads(Config.HeadBlend[modelName]) then
        return true
    end

    for modelKey, modelHeads in pairs(Config.HeadBlend) do
        local configuredModelName = tostring(modelKey):match("^([^^]+)")

        if configuredModelName == modelName and checkModelHeads(modelHeads) then
            return true
        end
    end

    return false
end

local function isConfiguredAddonHeadBlend(modelName, headId)
    headId = tonumber(headId)
    if not headId then return false end

    return forConfiguredAddonHeads(modelName, function(configuredHeadId, headConfig)
        if configuredHeadId == headId then
            return true
        end

        if type(headConfig) ~= "table" or type(headConfig.headBlend) ~= "table" then
            return false
        end

        local headBlend = headConfig.headBlend

        return configuredHeadId == headId and headConfig.mode == "blend"
            or tonumber(headBlend.shapeFirst) == headId
            or tonumber(headBlend.shapeSecond) == headId
            or tonumber(headBlend.shapeThird) == headId
    end)
end

local function isConfiguredAddonHeadComponent(modelName, drawable)
    drawable = tonumber(drawable)
    if not drawable then return false end

    return forConfiguredAddonHeads(modelName, function(configuredHeadId, headConfig)
        if type(headConfig) ~= "table" then
            return false
        end

        if headConfig.mode ~= "component" and not headConfig.component and not headConfig.componentDrawable then
            return false
        end

        local component = headConfig.component
        local componentDrawable = type(component) == "table" and component.drawable or headConfig.componentDrawable

        return tonumber(componentDrawable or configuredHeadId) == drawable
    end)
end

local function getFreemodeModelName(ped)
    local model = GetEntityModel(ped)

    if model == `mp_m_freemode_01` then
        return "mp_m_freemode_01"
    elseif model == `mp_f_freemode_01` then
        return "mp_f_freemode_01"
    end
end

local function clampHeadBlendShape(ped, shape)
    shape = math.floor(tonumber(shape) or 0)

    if shape < 0 then return 0 end
    if shape <= 45 then return shape end

    if isConfiguredAddonHeadBlend(getFreemodeModelName(ped), shape) then
        return shape
    end

    return 45
end

local function clampHeadBlendSkin(ped, skin)
    skin = math.floor(tonumber(skin) or 0)

    if skin < 0 then return 0 end
    if skin <= 45 then return skin end

    return 45
end

local function isPedFreemodeModel(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

local function computePedModelsByHash()
    for i = 1, #Config.Peds.pedConfig do
        local peds = Config.Peds.pedConfig[i].peds
        for j = 1, #peds do
            pedModelsByHash[joaat(peds[j])] = peds[j]
        end
    end
end

---@param ped number entity id
---@return string
--- Get the model name from an entity's model hash
local function getPedModel(ped)
    if not hashesComputed then
        computePedModelsByHash()
        hashesComputed = true
    end
    return pedModelsByHash[GetEntityModel(ped)]
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getPedComponents(ped)
    local size = #constants.PED_COMPONENTS_IDS
    local components = table.create(size, 0)

    for i = 1, size do
        local componentId = constants.PED_COMPONENTS_IDS[i]
        components[i] = {
            component_id = componentId,
            drawable = GetPedDrawableVariation(ped, componentId),
            texture = GetPedTextureVariation(ped, componentId),
        }
    end

    return components
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getPedProps(ped)
    local size = #constants.PED_PROPS_IDS
    local props = table.create(size, 0)

    for i = 1, size do
        local propId = constants.PED_PROPS_IDS[i]
        props[i] = {
            prop_id = propId,
            drawable = GetPedPropIndex(ped, propId),
            texture = GetPedPropTextureIndex(ped, propId),
        }
    end
    return props
end

local function round(number, decimalPlaces)
    return tonumber(string.format("%." .. (decimalPlaces or 0) .. "f", number))
end

---@param ped number entity id
---@return table <number, number>
---```
---{ shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix }
---```
local function getPedHeadBlend(ped)
    -- GET_PED_HEAD_BLEND_DATA
    local shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix = Citizen.InvokeNative(0x2746BD9D88C5C5D0, ped, Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0))

    shapeMix = tonumber(string.sub(shapeMix, 0, 4))
    if shapeMix > 1 then shapeMix = 1 end

    skinMix = tonumber(string.sub(skinMix, 0, 4))
    if skinMix > 1 then skinMix = 1 end

    if not thirdMix then
        thirdMix = 0
    end
    thirdMix = tonumber(string.sub(thirdMix, 0, 4))
    if thirdMix > 1 then thirdMix = 1 end


    local modelName = getFreemodeModelName(ped)
    local addonHead = isConfiguredAddonHeadBlend(modelName, shapeFirst)
        or isConfiguredAddonHeadBlend(modelName, shapeSecond)
        or isConfiguredAddonHeadBlend(modelName, shapeThird)

    return {
        addonHead = addonHead or nil,
        shapeFirst = shapeFirst,
        shapeSecond = shapeSecond,
        shapeThird = shapeThird,
        skinFirst = skinFirst,
        skinSecond = skinSecond,
        skinThird = skinThird,
        shapeMix = shapeMix,
        skinMix = skinMix,
        thirdMix = thirdMix
    }
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getPedFaceFeatures(ped)
    local size = #constants.FACE_FEATURES
    local faceFeatures = table.create(0, size)

    for i = 1, size do
        local feature = constants.FACE_FEATURES[i]
        faceFeatures[feature] = round(GetPedFaceFeature(ped, i-1), 1)
    end

    return faceFeatures
end

---@param ped number entity id
---@return table<number, table<string, number>>
local function getPedHeadOverlays(ped)
    local size = #constants.HEAD_OVERLAYS
    local headOverlays = table.create(0, size)

    for i = 1, size do
        local overlay = constants.HEAD_OVERLAYS[i]
        local _, value, _, firstColor, secondColor, opacity = GetPedHeadOverlayData(ped, i-1)

        if value ~= 255 then
            opacity = round(opacity, 1)
        else
            value = 0
            opacity = 0
        end

        headOverlays[overlay] = {style = value, opacity = opacity, color = firstColor, secondColor = secondColor}
    end

    return headOverlays
end

---@param ped number entity id
---@return table<string, number>
local function getPedHair(ped)
    return {
        style = GetPedDrawableVariation(ped, 2),
        color = GetPedHairColor(ped),
        highlight = GetPedHairHighlightColor(ped),
        texture = GetPedTextureVariation(ped, 2)
    }
end

local function getPedDecorationType()
    local pedModel = GetEntityModel(cache.ped)
    local decorationType

    if pedModel == `mp_m_freemode_01` then
        decorationType = "male"
    elseif pedModel == `mp_f_freemode_01` then
        decorationType = "female"
    else
        decorationType = IsPedMale(cache.ped) and "male" or "female"
    end

    return decorationType
end

local function getPedAppearance(ped)
    local eyeColor = GetPedEyeColor(ped)

    return {
        model = getPedModel(ped) or "mp_m_freemode_01",
        headBlend = getPedHeadBlend(ped),
        faceFeatures = getPedFaceFeatures(ped),
        headOverlays = getPedHeadOverlays(ped),
        components = getPedComponents(ped),
        props = getPedProps(ped),
        hair = getPedHair(ped),
        tattoos = client.getPedTattoos(),
        eyeColor = eyeColor < #constants.EYE_COLORS and eyeColor or 0
    }
end

local function setPlayerModel(model)
    if type(model) == "string" then model = joaat(model) end

    if IsModelInCdimage(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end

        SetPlayerModel(cache.playerId, model)
        Wait(150)
        SetModelAsNoLongerNeeded(model)

        if isPedFreemodeModel(cache.ped) then
            SetPedDefaultComponentVariation(cache.ped)
             -- Check if the model is male or female, then change the face mix based on this.
             if model == `mp_m_freemode_01` then
                SetPedHeadBlendData(cache.ped, 0, 0, 0, 0, 0, 0, 0, 0, 0, false)
            elseif model == `mp_f_freemode_01` then
                SetPedHeadBlendData(cache.ped, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0, false)
            end
        end

        PED_TATTOOS = {}
        return cache.ped
    end

    return cache.playerId
end

local function setPedHeadBlend(ped, headBlend)
    if headBlend and isPedFreemodeModel(ped) then
        SetPedHeadBlendData(
            ped,
            clampHeadBlendShape(ped, headBlend.shapeFirst),
            clampHeadBlendShape(ped, headBlend.shapeSecond),
            clampHeadBlendShape(ped, headBlend.shapeThird),
            clampHeadBlendSkin(ped, headBlend.skinFirst),
            clampHeadBlendSkin(ped, headBlend.skinSecond),
            clampHeadBlendSkin(ped, headBlend.skinThird),
            tofloat(headBlend.shapeMix or 0),
            tofloat(headBlend.skinMix or 0),
            tofloat(headBlend.thirdMix or 0),
            false
        )
    end
end

local function setPedFaceFeatures(ped, faceFeatures)
    if faceFeatures then
        for k, v in pairs(constants.FACE_FEATURES) do
            SetPedFaceFeature(ped, k-1, tofloat(faceFeatures[v]))
        end
    end
end

local function setPedHeadOverlays(ped, headOverlays)
    if headOverlays then
        for k, v in pairs(constants.HEAD_OVERLAYS) do
            local headOverlay = headOverlays[v]
            SetPedHeadOverlay(ped, k-1, headOverlay.style, tofloat(headOverlay.opacity))

            if headOverlay.color then
                local colorType = 1
                if v == "blush" or v == "lipstick" or v == "makeUp" then
                    colorType = 2
                end

                SetPedHeadOverlayColor(ped, k-1, colorType, headOverlay.color, headOverlay.secondColor)
            end
        end
    end
end

local function applyAutomaticFade(ped, style)
    local gender = getPedDecorationType()
    local hairDecoration = constants.HAIR_DECORATIONS[gender][style]

    if(hairDecoration) then
        AddPedDecorationFromHashes(ped, hairDecoration[1], hairDecoration[2])
    end
end

local function setTattoos(ped, tattoos, style)
    local isMale = client.getPedDecorationType() == "male"
    ClearPedDecorations(ped)
    if Config.AutomaticFade then
        tattoos["ZONE_HAIR"] = {}
        PED_TATTOOS["ZONE_HAIR"] = {}
        applyAutomaticFade(ped, style or GetPedDrawableVariation(ped, 2))
    end
    for k in pairs(tattoos) do
        for i = 1, #tattoos[k] do
            local tattoo = tattoos[k][i]
            local tattooGender = isMale and tattoo.hashMale or tattoo.hashFemale
            for _ = 1, (tattoo.opacity or 0.1) * 10 do
                AddPedDecorationFromHashes(ped, joaat(tattoo.collection), joaat(tattooGender))
            end
        end
    end
    if Config.RCoreTattoosCompatibility then
        TriggerEvent("rcore_tattoos:applyOwnedTattoos")
    end
end

-- Validates that a drawable/texture combo actually exists on this ped right now.
-- Prevents SetPedComponentVariation/SetPedPropIndex from being called with a
-- drawable id that isn't loaded yet (addon component still streaming in) or
-- that no longer exists (stale saved appearance) -- both of which can crash
-- the client with a null-pointer access violation inside the native.
local function isValidComponentVariation(ped, componentId, drawable, texture)
    local maxDrawable = GetNumberOfPedDrawableVariations(ped, componentId) - 1
    if drawable == nil or drawable < 0 or drawable > maxDrawable then
        return false
    end

    if texture ~= nil then
        local maxTexture = GetNumberOfPedTextureVariations(ped, componentId, drawable) - 1
        if texture < 0 or texture > maxTexture then
            return false
        end
    end

    return true
end

local function isValidPropVariation(ped, propId, drawable, texture)
    if drawable == -1 then return true end -- -1 always means "clear prop"

    local maxDrawable = GetNumberOfPedPropDrawableVariations(ped, propId) - 1
    if drawable == nil or drawable < 0 or drawable > maxDrawable then
        return false
    end

    if texture ~= nil then
        local maxTexture = GetNumberOfPedPropTextureVariations(ped, propId, drawable) - 1
        if texture < 0 or texture > maxTexture then
            return false
        end
    end

    return true
end

local function setPedHair(ped, hair, tattoos)
    if hair then
        if isValidComponentVariation(ped, 2, hair.style, hair.texture) then
            SetPedComponentVariation(ped, 2, hair.style, hair.texture, 0)
        else
            print(("[illenium-appearance] Skipped invalid hair style/texture (style=%s texture=%s) - drawable not loaded or out of range"):format(tostring(hair.style), tostring(hair.texture)))
        end

        SetPedHairColor(ped, hair.color, hair.highlight)
        if isPedFreemodeModel(ped) then
            setTattoos(ped, tattoos or PED_TATTOOS, hair.style)
        end
    end
end

local function setPedEyeColor(ped, eyeColor)
    if eyeColor then
        SetPedEyeColor(ped, eyeColor)
    end
end

local function setPedComponent(ped, component)
    if component then
        if isPedFreemodeModel(ped) then
            if component.component_id == 2 then
                return
            end

            if component.component_id == 0
                and not isConfiguredAddonHeadComponent(getFreemodeModelName(ped), component.drawable) then
                return
            end
        end

        if isValidComponentVariation(ped, component.component_id, component.drawable, component.texture) then
            SetPedComponentVariation(ped, component.component_id, component.drawable, component.texture, 0)
        else
            print(("[illenium-appearance] Skipped invalid component (component_id=%s drawable=%s texture=%s) - drawable not loaded or out of range"):format(tostring(component.component_id), tostring(component.drawable), tostring(component.texture)))
        end
    end
end

local function setPedComponents(ped, components, skipHead)
    if components then
        for _, v in pairs(components) do
            if not skipHead or v.component_id ~= 0 then
                setPedComponent(ped, v)
            end
        end
    end
end

local function setPedHeadComponent(ped, components)
    if components then
        for _, v in pairs(components) do
            if v.component_id == 0 then
                setPedComponent(ped, v)
                return
            end
        end
    end
end

local function setPedProp(ped, prop)
    if prop then
        if prop.drawable == -1 then
            ClearPedProp(ped, prop.prop_id)
        elseif isValidPropVariation(ped, prop.prop_id, prop.drawable, prop.texture) then
            SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture, false)
        else
            print(("[illenium-appearance] Skipped invalid prop (prop_id=%s drawable=%s texture=%s) - drawable not loaded or out of range"):format(tostring(prop.prop_id), tostring(prop.drawable), tostring(prop.texture)))
        end
    end
end

local function setPedProps(ped, props)
    if props then
        for _, v in pairs(props) do
            setPedProp(ped, v)
        end
    end
end

local function setPedTattoos(ped, tattoos)
    PED_TATTOOS = tattoos
    setTattoos(ped, tattoos)
end

local function getPedTattoos()
    return PED_TATTOOS
end

local function addPedTattoo(ped, tattoos)
    setTattoos(ped, tattoos)
end

local function removePedTattoo(ped, tattoos)
    setTattoos(ped, tattoos)
end

local function setPreviewTattoo(ped, tattoos, tattoo)
    local isMale = client.getPedDecorationType() == "male"
    local tattooGender = isMale and tattoo.hashMale or tattoo.hashFemale

    ClearPedDecorations(ped)
    for _ = 1, (tattoo.opacity or 0.1) * 10 do
        AddPedDecorationFromHashes(ped, joaat(tattoo.collection), tattooGender)
    end
    for k in pairs(tattoos) do
        for i = 1, #tattoos[k] do
            local aTattoo = tattoos[k][i]
            if aTattoo.name ~= tattoo.name then
                local aTattooGender = isMale and aTattoo.hashMale or aTattoo.hashFemale
                for _ = 1, (aTattoo.opacity or 0.1) * 10 do
                    AddPedDecorationFromHashes(ped, joaat(aTattoo.collection), joaat(aTattooGender))
                end
            end
        end
    end
    if Config.AutomaticFade then
        applyAutomaticFade(ped, GetPedDrawableVariation(ped, 2))
    end
end

local function setPedAppearance(ped, appearance)
    if appearance then
        setPedComponents(ped, appearance.components, true)
        setPedProps(ped, appearance.props)

        if appearance.headBlend and isPedFreemodeModel(ped) then setPedHeadBlend(ped, appearance.headBlend) end
        setPedHeadComponent(ped, appearance.components)
        if appearance.faceFeatures then setPedFaceFeatures(ped, appearance.faceFeatures) end
        if appearance.headOverlays then setPedHeadOverlays(ped, appearance.headOverlays) end
        if appearance.hair then setPedHair(ped, appearance.hair, appearance.tattoos) end
        if appearance.eyeColor then setPedEyeColor(ped, appearance.eyeColor) end
        if appearance.tattoos then setPedTattoos(ped, appearance.tattoos) end
    end
end

local function setPlayerAppearance(appearance)
    if appearance then
        setPlayerModel(appearance.model)
        setPedAppearance(cache.ped, appearance)
    end
end

exports("getPedModel", getPedModel)
exports("getPedComponents", getPedComponents)
exports("getPedProps", getPedProps)
exports("getPedHeadBlend", getPedHeadBlend)
exports("getPedFaceFeatures", getPedFaceFeatures)
exports("getPedHeadOverlays", getPedHeadOverlays)
exports("getPedHair", getPedHair)
exports("getPedAppearance", getPedAppearance)

exports("setPlayerModel", setPlayerModel)
exports("setPedHeadBlend", setPedHeadBlend)
exports("setPedFaceFeatures", setPedFaceFeatures)
exports("setPedHeadOverlays", setPedHeadOverlays)
exports("setPedHair", setPedHair)
exports("setPedEyeColor", setPedEyeColor)
exports("setPedComponent", setPedComponent)
exports("setPedComponents", setPedComponents)
exports("setPedProp", setPedProp)
exports("setPedProps", setPedProps)
exports("setPlayerAppearance", setPlayerAppearance)
exports("setPedAppearance", setPedAppearance)
exports("setPedTattoos", setPedTattoos)

client = {
    getPedAppearance = getPedAppearance,
    getPedHeadBlend = getPedHeadBlend,
    setPlayerModel = setPlayerModel,
    setPedHeadBlend = setPedHeadBlend,
    setPedFaceFeatures = setPedFaceFeatures,
    setPedHair = setPedHair,
    setPedHeadOverlays = setPedHeadOverlays,
    setPedEyeColor = setPedEyeColor,
    setPedComponent = setPedComponent,
    setPedProp = setPedProp,
    setPlayerAppearance = setPlayerAppearance,
    setPedAppearance = setPedAppearance,
    getPedDecorationType = getPedDecorationType,
    isPedFreemodeModel = isPedFreemodeModel,
    setPreviewTattoo = setPreviewTattoo,
    setPedTattoos = setPedTattoos,
    getPedTattoos = getPedTattoos,
    addPedTattoo = addPedTattoo,
    removePedTattoo = removePedTattoo,
    getPedModel = getPedModel,
    setPedComponents = setPedComponents,
    setPedProps = setPedProps,
    getPedComponents = getPedComponents,
    getPedProps = getPedProps
}