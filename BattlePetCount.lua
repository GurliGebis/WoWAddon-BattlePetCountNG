
local LPJ = LibStub("LibPetJournal-2.0")

--
--
--

local function Create_SubTip(t)
    local subtip = CreateFrame("FRAME", nil, t)
    subtip:SetPoint("TOPLEFT", t, "BOTTOMLEFT")
    subtip:SetPoint("TOPRIGHT", t, "BOTTOMRIGHT")
    
    subtip:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
        tile = true, tileSize = 16, edgeSize = 16, 
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    subtip:SetBackdropColor(0,0,0,1)
    
    subtip.Text = subtip:CreateFontString("ARTWORK")
    subtip.Text:SetFontObject(GameTooltipTextSmall)
    subtip.Text:SetWordWrap(true)
    subtip.Text:SetPoint("TOPLEFT", subtip, 8, -8)
    subtip.Text:SetWidth(220)
    
    return subtip
end

local BuildOwnedListS
do
    local tmp = {}
    function BuildOwnedListS(speciesid)
        wipe(tmp)

        for iv,petid in LPJ:IteratePetIDs() do
            local p_sp, customName, _, _, _, _, petName = C_PetJournal.GetPetInfoByPetID(petid)
            if speciesid == p_sp then
                local _, _, _, _, quality = C_PetJournal.GetPetStats(petid)
                
                tinsert(tmp, format("|cff%02x%02x%02x%s|r",
                            ITEM_QUALITY_COLORS[quality-1].r*255,
                            ITEM_QUALITY_COLORS[quality-1].g*255,
                            ITEM_QUALITY_COLORS[quality-1].b*255,
                            customName or petName))
            end
        end
        
        if #tmp > 0 then
            return table.concat(tmp, ", ")
        end
    end
end

--
-- 
--

local function BattlePetTooltipTemplate_SetText(t, s)
    if not t.X_BPC then
        t.X_BPC = Create_SubTip(t)
    end

    t.X_BPC.Text:SetText(s)
    t.X_BPC:SetHeight(t.X_BPC.Text:GetHeight()+16)
end

hooksecurefunc("BattlePetTooltipTemplate_SetBattlePet", function(self, data)
    local speciesID = self.speciesID
    
    local list = BuildOwnedListS(speciesID)
    if list then
        BattlePetTooltipTemplate_SetText(self, format("You own this pet: %s", list))
    else
        BattlePetTooltipTemplate_SetText(self, "You don't own this pet.")
    end
end)

--
-- PetBattleUnitTooltip
--

local function PetBattleUnitTooltip_SetText(t, s)
    if not t.X_BPC then
        t.X_BPC = Create_SubTip(t)
    end

    t.X_BPC.Text:SetText(s)
    t.X_BPC:SetHeight(t.X_BPC.Text:GetHeight()+16)
end

hooksecurefunc("PetBattleUnitTooltip_UpdateForUnit", function(self, petOwner, petIndex)
    local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)

    local list = BuildOwnedListS(speciesID)
    if list then
        PetBattleUnitTooltip_SetText(self, format("You own this pet: %s", list))
    else
        PetBattleUnitTooltip_SetText(self, "You don't own this pet.")
    end
end)
