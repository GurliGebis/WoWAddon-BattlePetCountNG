
local addon_name, addon = ...

local module = addon:NewModule("Tooltips", "AceEvent-3.0", "AceHook-3.0")

local LPJ = LibStub("LibPetJournal-2.0")
local LibQTip = LibStub("LibQTip-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

--
--
--

local GameTooltip_OnUpdate_Hook

function module:OnInitialize()
    local str = ITEM_PET_KNOWN
    str = gsub(gsub(str, "%(", "%%("), "%)", "%%)")
    str = gsub(str, "%%d", "%%d+")
    self.ITEM_PET_KNOWN_DEFORMAT = "^"..str

    self:Initialize_BattlePetTooltip()
    self:Initialize_PetBattleUnitTooltip()
    self:Initialize_GameTooltip()

    self:RegisterEvent("ADDON_LOADED")
    self:ADDON_LOADED()
end

function module:ADDON_LOADED()
    if not self.LibExtraTip then
        self.LibExtraTip = LibStub("LibExtraTip-1", true)
        if self.LibExtraTip then
            self.LibExtraTip:AddCallback{
                type = "extrashow",
                callback = function(tip, extratip)
                    if tip.X_BPC2 then
                        tip.X_BPC2:SetPoint("TOPLEFT", extratip, "BOTTOMLEFT")
                        tip.X_BPC2:SetPoint("TOPRIGHT", extratip, "BOTTOMRIGHT") 
                    end
                end
            }
            self.LibExtraTip:AddCallback{
                type = "extrahide",
                callback = function(tip, extratip)
                    if tip.X_BPC2 then
                        tip.X_BPC2:SetPoint("TOPLEFT", tip, "BOTTOMLEFT")
                        tip.X_BPC2:SetPoint("TOPRIGHT", tip, "BOTTOMRIGHT") 
                    end
                end
            }
        end
    end
end

function module:SubTip(tooltip, text)
    if not text then
        return self:HideSubTip(tooltip)
    end

    local subtip = tooltip.X_BPC2
    if not subtip then
        subtip = LibQTip:Acquire(tooltip:GetName().."_BPC_SubTip", 1, "LEFT")

        subtip:SetPoint("BOTTOMLEFT", tooltip, "TOPLEFT")
        subtip:SetPoint("BOTTOMRIGHT", tooltip, "TOPRIGHT")
        subtip:Show()

        tooltip.X_BPC2 = subtip
    else
        subtip:Clear()
    end

    if text then
        local row, col = subtip:AddLine()
        subtip:SetCell(row, col, text, nil, "LEFT", nil, nil, nil, nil, tooltip:GetWidth()-10)
    end
end

function module:HideSubTip(tooltip)
    if tooltip.X_BPC2 then
        LibQTip:Release(tooltip.X_BPC2)
        tooltip.X_BPC2 = nil
    end
end

function module:HookScriptSilent(frame, script, func)
    if frame:HasScript(script) then
        return self:SecureHookScript(frame, script, func)
    end
end

--
-- BattlePetTooltipTemplate
--

function module:Initialize_BattlePetTooltip()
    self:SecureHook("BattlePetToolTip_Show")
    self:SecureHookScript(BattlePetTooltip, "OnHide", "BattlePetToolTip_Hide")
end

function module:BattlePetToolTip_Show(speciesID, level, breedQuality, maxHealth, power, speed, customName)
    local tip = BattlePetTooltip

    if not speciesID or speciesID < 0 then
        return
    end

    local Owned = tip.Owned
    if not addon.db.profile.enableCageTip then
        -- pass
    elseif addon.db.profile.useSubTip then
        if Owned and Owned:IsShown() then
            tip.Owned:Hide()
            -- TODO fix size
        end

        self:SubTip(tip, addon:CollectedText(speciesID))
    else
        self:HideSubTip(tip)

        Owned:SetWordWrap(true)
        Owned:SetText(addon:CollectedText(speciesID))
        Owned:Show()

        local ownedCount = C_PetJournal.GetNumCollectedInfo(speciesID)
        local heightModifier
        if ownedCount > 0 then
            heightModifier = 12
        else
            heightModifier = -2
        end

        local height = tip:GetHeight() + Owned:GetHeight() - heightModifier
        tip:SetHeight(height)
    end
end

function module:BattlePetToolTip_Hide()
    self:HideSubTip(BattlePetTooltip)
end

--
-- PetBattleUnitTooltip
--

function module:Initialize_PetBattleUnitTooltip()
    self.PetBattleUnit_Hooked = {}
    self:SecureHook("PetBattleUnitTooltip_UpdateForUnit")
end

function module:PetBattleUnitTooltip_UpdateForUnit(tip, petOwner, petIndex)
    if not self.PetBattleUnit_Hooked[tip] then
        self:HookScript(tip, "OnHide", "PetBattleUnitTooltip_Hide")
        self.PetBattleUnit_Hooked[tip] = true
    end

    local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)
    local CollectedText = tip.CollectedText
    if not addon.db.profile.enableBattleTip then
        -- pass
    elseif addon.db.profile.useSubTip then
        if CollectedText and CollectedText:IsShown() then
            local height = tip:GetHeight()
            tip:SetHeight(height - CollectedText:GetHeight())
            tip.HealthBorder:SetPoint("TOPLEFT", tip.Icon, "BOTTOMLEFT", -1, -6)
            CollectedText:Hide()
        end

        self:SubTip(tip, addon:CollectedText(speciesID))
    else
        self:HideSubTip(tip)

        local height = tip:GetHeight()
        if CollectedText:IsShown() then
            height = height - CollectedText:GetHeight()
        end
        
        CollectedText:SetWidth(tip:GetWidth()-20)
        CollectedText:SetWordWrap(true)
        CollectedText:SetText(addon:CollectedText(speciesID))
        CollectedText:Show()

        tip.HealthBorder:SetPoint("TOPLEFT", CollectedText, "BOTTOMLEFT", -1, -6)
        tip:SetHeight(height + CollectedText:GetHeight())
    end
end

function module:PetBattleUnitTooltip_Hide(tip)
    self:HideSubTip(tip)
end

--
-- GameTooltip
--

local function updateTooltip(tooltip)
    module:AlterGameTooltip(tooltip)
end

function module:Initialize_GameTooltip()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, updateTooltip)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, updateTooltip)
    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, GameTooltip_OnUpdate_Hook)
end

function module:FindCollectedTooltipText(tt)
    local prefix = tt:GetName().."TextLeft"
    local lineno, line = 0, nil
    while true do
        lineno = lineno + 1
        line = _G[prefix..lineno] 
        if not line or not line:IsShown() then
            line = nil
            break
        end

        local text = line:GetText()
        if text == UNIT_CAPTURABLE then
            break
        elseif strmatch(text, self.ITEM_PET_KNOWN_DEFORMAT) then
            break
        end
    end

    return line
end

function module:AlterCollectedTooltipText(tt, speciesID)
    local line = self:FindCollectedTooltipText(tt)
    local newtext = addon:CollectedText(speciesID)
    if line then
        line:SetText(newtext)
        line:SetVertexColor(1, 1, 1)
    elseif addon:CanObtainSpecies(speciesID) then
        tt:AddLine(newtext)
    end
    tt:Show()
end

function module:AlterGameTooltip(tt)
    if not addon.db then
        return
    end
    
    if tt.GetUnit and addon.db.profile.enableCreatureTip then
        local _, unit = tt:GetUnit()
        if unit then
            if UnitIsWildBattlePet(unit) then
                local speciesID = UnitBattlePetSpeciesID(unit)
                self:AlterCollectedTooltipText(tt, speciesID)
            end
            return
        end
    end
    
    if tt.GetItem and addon.db.profile.enableItemTip then
        local _, link = tt:GetItem()
        if link then
            local _, _, itemid = strfind(link, "|Hitem:(%d+):")
            if itemid then
                local speciesID = select(13, C_PetJournal.GetPetInfoByItemID(itemid))
                if speciesID then
                    if not addon.db.profile.itemTipIncludesAll then
                        local _, _, _, _, _, _, _, canBattle = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
                        if not canBattle then
                            return
                        end
                    end

                    self:AlterCollectedTooltipText(tt, speciesID)
                end
            end
            return
        end
    end
end

local function sub_PetName(line)
    local name = line
    local start, stop = strfind(line, "|t")
    if start then
        name = strsub(line, stop+1)
    end
    local _, _, subname = strfind(name, "|c%x%x%x%x%x%x%x%x([^|]+)|r")
    if subname then
        name = subname
    end
    
    for _,speciesID in LPJ:IterateSpeciesIDs() do
        local s_name, _, _, _, _, _, _, _, _, _, s_obtain = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        if s_name == name and s_obtain then
            return format("%s (%s)", line, addon:ShortOwnedList(speciesID))          
        end
    end

    return line
end

local lastMinimapTooltip
function GameTooltip_OnUpdate_Hook(tt)
    if addon.db and not addon.db.profile.enableMinimapTip then
        return
    elseif not tt then
        return
    end

    local tooltipInfo = tt:GetPrimaryTooltipInfo()

    if not tooltipInfo or not tooltipInfo.getterName or tooltipInfo.getterName ~= "GetMinimapMouseover" then
        return
    end

    local text = GameTooltipTextLeft1:GetText()
    if text ~= lastMinimapTooltip then
        return module:UpdateMiniMapTooltip(tt, text)
    end
end

function module:UpdateMiniMapTooltip(tt, text)
    if text == nil then
        return
    end

    text = string.gsub(text, "([^\n]+)", sub_PetName)
    GameTooltipTextLeft1:SetText(text)
    lastMinimapTooltip = text
    tt:Show()
end
