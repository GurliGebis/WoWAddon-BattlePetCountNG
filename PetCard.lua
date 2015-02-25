
local addon_name, addon = ...

local module = addon:NewModule("PetCard", "AceEvent-3.0", "AceHook-3.0")

local LPJ = LibStub("LibPetJournal-2.0")
local LibQTip = LibStub("LibQTip-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

--
--
--

function module:OnInitialize()
    if not self:Setup() then
        self:RegisterEvent("ADDON_LOADED")
    end
end

function module:Setup()
    if not IsAddOnLoaded("Blizzard_Collections") then
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

    if PetJournalPetCard.petID and PetJournalPetCard.speciesID  then       
        local ownedElse = addon:ShortOwnedListOnly(PetJournalPetCard.speciesID, PetJournalPetCard.petID)
        if ownedElse then
            local _, _, _, _, rarity = C_PetJournal.GetPetStats(PetJournalPetCard.petID)
            local color = ITEM_QUALITY_COLORS[rarity-1]

            QualityFrame.quality:SetVertexColor(1, 1, 1)
            QualityFrame.quality:SetText(format("%s%s|r (%s%s)", color.hex, _G["BATTLE_PET_BREED_QUALITY"..rarity], "Also Own: ", ownedElse))
        end
    end
end

function module:ADDON_LOADED()
    if self:Setup() then
        self:UnregisterEvent("ADDON_LOADED")
    end
end

