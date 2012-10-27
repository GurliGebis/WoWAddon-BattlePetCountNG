
local addon_name, addon = ...

local module = addon:NewModule("Tooltips", "AceEvent-3.0", "AceHook-3.0")

local LPJ = LibStub("LibPetJournal-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

local is5_1 = not not C_PetJournal.GetNumCollectedInfo

--
--
--

local GameTooltip_OnUpdate_Hook

function module:OnInitialize()
    if ITEM_PET_KNOWN then
        local str = ITEM_PET_KNOWN
        str = gsub(gsub(str, "%(", "%%("), "%)", "%%)")
        str = gsub(str, "%%d", "%%d+")
        self.ITEM_PET_KNOWN_DEFORMAT = "^"..str
    end

    self:Initialize_BattlePetTooltip()
    self:Initialize_PetBattleUnitTooltip()
    self:Initialize_GameTooltip()
end

--
-- BattlePetTooltipTemplate
--

function module:Initialize_BattlePetTooltip()
    self:SecureHook("BattlePetToolTip_Show")

    if not is5_1 then
        -- XXX also do FloatBattlePetTooltip or whatever??
        local frame = BattlePetTooltip
        local Owned = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        Owned:SetWidth(238)
        Owned:SetJustifyH("LEFT")
        Owned:SetPoint("TOPLEFT", frame.SpeedTexture, "BOTTOMLEFT", 0, -2)
        Owned:SetVertexColor(1.0, 0.82, 0.0, 1.0)

        frame.Owned = Owned
    end
end

function module:BattlePetToolTip_Show(speciesID)
    local tip = BattlePetTooltip
    if not speciesID or speciesID < 0 then
        return
    elseif not addon.db.profile.enableCageTip then
        -- TODO
    end

    local Owned = tip.Owned
    Owned:SetText(addon:CollectedText(speciesID))
    Owned:Show()

    -- XXX TRIPLE ECKS
    tip:SetSize(260,136)
end

--
-- PetBattleUnitTooltip
--

function module:Initialize_PetBattleUnitTooltip()
    self:SecureHook("PetBattleUnitTooltip_UpdateForUnit")
    if not is5_1 then
        self:SecureHook("PetBattleUnitFrame_UpdateDisplay")

        local frame = PetBattlePrimaryUnitTooltip
        local CollectedText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        CollectedText:SetJustifyH("LEFT")
        CollectedText:SetPoint("TOPLEFT", frame.Icon, "BOTTOMLEFT", 0, -4)

        frame.CollectedText = CollectedText
    end
end

function module:PetBattleUnitTooltip_UpdateForUnit(tip, petOwner, petIndex)
    if not addon.db.profile.enableBattleTip then
        if not is5_1 then
            tip.CollectedText:Hide()
            tip.HealthBorder:SetPoint("TOPLEFT", tip.Icon, "BOTTOMLEFT", -1, -6)
        end
        return
    end

    local CollectedText = tip.CollectedText
    local height = tip:GetHeight()
    if CollectedText:IsShown() and is5_1 then
        height = height - CollectedText:GetHeight()
    end
    
    local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)
    if not is5_1 then
        CollectedText:SetWidth(tip:GetWidth() - 8) -- fudge
    end
    CollectedText:SetText(addon:CollectedText(speciesID))
    CollectedText:Show()

    tip.HealthBorder:SetPoint("TOPLEFT", CollectedText, "BOTTOMLEFT", -1, -6)
    tip:SetHeight(height + CollectedText:GetHeight())
end

-- 5.0 client support
function module:PetBattleUnitFrame_UpdateDisplay(frame)
    local quality = C_PetBattles.GetBreedQuality(frame.petOwner, frame.petIndex)
    if frame.Name then
        frame.Name:SetVertexColor(ITEM_QUALITY_COLORS[quality-1].r,
                                ITEM_QUALITY_COLORS[quality-1].g,
                                ITEM_QUALITY_COLORS[quality-1].b)
    end
end

--
-- GameTooltip
--

function module:Initialize_GameTooltip()
    -- XX hook SetUnit?
    self:HookScript(GameTooltip, "OnShow", function()
        module:AlterGameTooltip(GameTooltip)
    end)
    self:HookScript(ItemRefTooltip, "OnShow", function()
        module:AlterGameTooltip(ItemRefTooltip)
    end)

    self:HookScript(GameTooltip, "OnUpdate", GameTooltip_OnUpdate_Hook)
end

function module:AlterGameTooltip(tt)
    if not addon.db then
        return
    end
    
    if tt.GetUnit and addon.db.profile.enableCreatureTip then
        local _, unit = tt:GetUnit()
        if unit then
            if UnitIsWildBattlePet(unit) then
                local creatureID = tonumber(strsub(UnitGUID(unit),7,10), 16)
                local speciesID = LPJ:GetSpeciesIDForCreatureID(creatureID)

                local lineno, line = 0, nil
                while true do
                    lineno = lineno + 1
                    line = _G["GameTooltipTextLeft"..lineno] 
                    if not line or not line:IsShown() then
                        line = nil
                        break
                    end

                    local text = line:GetText()
                    if text == UNIT_CAPTURABLE then
                        break
                    elseif self.ITEM_PET_KNOWN_DEFORMAT and strmatch(text, self.ITEM_PET_KNOWN_DEFORMAT) then
                        -- XXX self.ITEM_PET_KNOWN_DEFORMAT nil check for 5.0 client
                        break
                    end
                end

                local newtext = addon:CollectedText(speciesID)
                if line then
                    line:SetText(newtext)
                    line:SetVertexColor(1, 1, 1)
                else
                    tt:AddLine(newtext)
                end
                tt:Show()
            end
            return
        end
    end
    
    if tt.GetItem and addon.db.profile.enableItemTip then
        local _, link = tt:GetItem()
        if link then
            local _, _, itemid = strfind(link, "|Hitem:(%d+):")
            if itemid then
                local speciesID = addon.Item2Species[tonumber(itemid)]
                if speciesID then
                    if not addon.db.profile.itemTipIncludesAll then
                        local _, _, _, _, _, _, _, canBattle = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
                        if not canBattle then
                            return
                        end
                    end
                    tt:AddLine(addon:CollectedText(speciesID))
                    tt:Show()
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
        local s_name = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        if s_name == name then
            return format("%s (%s)", line, addon:ShortOwnedList(speciesID))          
        end
    end

    return line
end

local lastMinimapTooltip
function GameTooltip_OnUpdate_Hook(tt)
    if addon.db and not addon.db.profile.enableMinimapTip then
        return
    elseif tt:GetOwner() ~= Minimap then
        return
    end
    
    local text = GameTooltipTextLeft1:GetText()
    if text ~= lastMinimapTooltip then
        return module:UpdateMiniMapTooltip(tt, text)
    end
end

function module:UpdateMiniMapTooltip(tt, text)
    text = string.gsub(text, "([^\n]+)", sub_PetName)
    GameTooltipTextLeft1:SetText(text)
    lastMinimapTooltip = text
    tt:Show()
end
