
local addon_name, addon = ...

local module = addon:NewModule("Tooltips", "AceEvent-3.0", "AceHook-3.0")

local LPJ = LibStub("LibPetJournal-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

local is5_1 = not not C_PetJournal.GetNumCollectedInfo

--
--
--

function module:OnInitialize()
    self:SecureHook("BattlePetTooltipTemplate_SetBattlePet")

    self:SecureHook("PetBattleUnitTooltip_UpdateForUnit")
    if not is5_1 then
        self:SecureHook("PetBattleUnitFrame_UpdateDisplay")
    end

    -- XX hook SetUnit?
    self:HookScript(GameTooltip, "OnShow", function()
        module:AlterGameTooltip(GameTooltip)
    end)
    self:HookScript(ItemRefTooltip, "OnShow", function()
        module:AlterGameTooltip(ItemRefTooltip)
    end)
end

--
-- BattlePetTooltipTemplate
--

function module:BattlePetTooltipTemplate_SetBattlePet(tip, data)
    if not addon.db.profile.enableCageTip then
        return HideSubTip(self)
    end

    local subtip = SubTip(self)
    subtip.Text:SetText(addon:OwnedListOrNot("speciesID", self.speciesID))
    subtip:SetHeight(subtip.Text:GetHeight()+16)
end

--
-- PetBattleUnitTooltip
--

function module:PetBattleUnitTooltip_UpdateForUnit(tip, petOwner, petIndex)
    if not addon.db.profile.enableBattleTip then
        return HideSubTip(self)
    end

    local subtip = SubTip(self)
    local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)
    subtip.Text:SetText(addon:OwnedListOrNot("speciesID", speciesID))
    subtip:SetHeight(subtip.Text:GetHeight()+16)
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

function module:AlterGameTooltip(self)
    if not addon.db then
        return
    end
    
    if self.GetUnit and addon.db.profile.enableCreatureTip then
        local _, unit = self:GetUnit()
        if unit then
            if UnitIsWildBattlePet(unit) then
                local creatureID = tonumber(strsub(UnitGUID(unit),7,10), 16)
                self:AddLine(addon:OwnedListOrNot("creatureID", creatureID))
                self:Show()
            end
            return
        end
    end
    
    if self.GetItem and addon.db.profile.enableItemTip then
        local _, link = self:GetItem()
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
                    self:AddLine(addon:OwnedListOrNot("speciesID", speciesID))
                    self:Show()
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
            return format("%s (%s)", line, addon:ShortOwnedList("speciesID", speciesID))          
        end
    end

    return line
end

local lastMinimapTooltip
function module:GameTooltip_OnUpdate(tt)
    if addon.db and not addon.db.profile.enableMinimapTip then
        return
    elseif tt:GetOwner() ~= Minimap then
        return
    end
    
    local text = GameTooltipTextLeft1:GetText()
    if text ~= lastMinimapTooltip then
        text = string.gsub(text, "([^\n]+)", sub_PetName)
        GameTooltipTextLeft1:SetText(text)
        lastMinimapTooltip = text
        tt:Show()
    end
end
