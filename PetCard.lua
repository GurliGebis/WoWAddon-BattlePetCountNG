
local addon_name, addon = ...

local module = addon:NewModule("PetCard", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

--
--
--

function module:OnInitialize()
    if not self:Setup() then
        self:RegisterEvent("ADDON_LOADED", function()
            if self:Setup() then
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end

function module:Setup()
    if not C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
        return false
    end

    hooksecurefunc("PetJournal_UpdatePetCard", function()
        self:UpdatePetCard() 
    end)
    self:UpdatePetCard() 

    return true
end

function module:UpdatePetCard()
    local QualityFrame = PetJournalPetCard.QualityFrame

    if addon.db.profile.enablePetCard and PetJournalPetCard.petID and PetJournalPetCard.speciesID then
        local ownedElse = addon:ShortOwnedListOnly(PetJournalPetCard.speciesID, PetJournalPetCard.petID)
        if ownedElse then
            local _, _, _, _, rarity = C_PetJournal.GetPetStats(PetJournalPetCard.petID)
            if rarity then
                local color = ITEM_QUALITY_COLORS[rarity-1]

                QualityFrame.quality:SetVertexColor(1, 1, 1)
                QualityFrame.quality:SetText(format("%s%s|r (%s%s)",
                        color.hex,
                        _G["BATTLE_PET_BREED_QUALITY"..rarity],
                        L["ALSO_OWN_COLON"], ownedElse))
            end
        end
    end
end
