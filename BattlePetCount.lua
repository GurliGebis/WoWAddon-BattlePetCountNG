
local addon_name, addon = ...

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

local BuildOwnedListS, BuildOwnedListC
do
    local tmp = {}
    local function BuildOwnedList(p_sp, p_c)
        wipe(tmp)

        for iv,petid in LPJ:IteratePetIDs() do
            local speciesID, customName, _, _, _, _, name, _, _, creatureID = C_PetJournal.GetPetInfoByPetID(petid)
            if (p_sp and speciesID == p_sp) or (p_c and creatureID == p_c) then
                local _, _, _, _, quality = C_PetJournal.GetPetStats(petid)
                
                tinsert(tmp, format("|cff%02x%02x%02x%s|r",
                            ITEM_QUALITY_COLORS[quality-1].r*255,
                            ITEM_QUALITY_COLORS[quality-1].g*255,
                            ITEM_QUALITY_COLORS[quality-1].b*255,
                            customName or name))
            end
        end
        
        if #tmp > 0 then
            return table.concat(tmp, ", ")
        end
    end
    
    function BuildOwnedListS(speciesid)
        return BuildOwnedList(speciesid, nil)
    end
    
    function BuildOwnedListC(creatureid)
        return BuildOwnedList(nil, creatureid)
    end
end

local function OwnedListOrNot(ownedlist)
    if ownedlist then
        return format("You own this pet: %s", ownedlist)
    else
        return "You don't own this pet."
    end
end

local function PlayersBestQuality(speciesID)
    local maxquality = -1
    for iv,petid in LPJ:IteratePetIDs() do
        local sid = C_PetJournal.GetPetInfoByPetID(petid)
        if sid == speciesID then
            local _, _, _, _, quality = C_PetJournal.GetPetStats(petid)
            if maxquality < quality then
                maxquality = quality
            end
        end
    end
    
    if maxquality == -1 then
        return nil
    end
    return maxquality
end

--
-- BattlePetTooltipTemplate
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
    BattlePetTooltipTemplate_SetText(self, OwnedListOrNot(BuildOwnedListS(speciesID)))
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
    PetBattleUnitTooltip_SetText(self, OwnedListOrNot(BuildOwnedListS(speciesID)))
end)

--
-- GameTooltip
--

GameTooltip:HookScript("OnShow", function(self)
    local _, unit = self:GetUnit()
    if unit then
        if UnitIsWildBattlePet(unit) then
            local creatureID = tonumber(strsub(UnitGUID(unit),7,10), 16)
            self:AddLine(OwnedListOrNot(BuildOwnedListC(creatureID)))
            self:Show()
        end
        return
    end
    
    local _, link = self:GetItem()
    if link then
        local _, _, itemid = strfind(link, "|Hitem:(%d+):")
        if itemid then
            local speciesID = addon.Item2Species[tonumber(itemid)]
            if speciesID then
                self:AddLine(OwnedListOrNot(BuildOwnedListS(speciesID)))
                self:Show()
            end
        end
        return
    end
end)

--
-- Pet Battle Text
--

do
    local InBattleIndicator = CreateFrame("FRAME", nil, PetBattleFrame.ActiveEnemy, "InsetFrameTemplate3")

    local Text = InBattleIndicator:CreateFontString("OVERLAY")
    Text:SetFontObject(GameFontHighlightSmallLeft)
    Text:SetPoint("RIGHT", PetBattleFrame.ActiveEnemy, "LEFT", -8, 0)
    Text:SetPoint("LEFT", PetBattleFrame.TopVersusText, "RIGHT", 24, 0)
    
    InBattleIndicator:SetPoint("TOPLEFT", Text, -4, 4)
    InBattleIndicator:SetPoint("BOTTOMRIGHT", Text, 5, -4)
    InBattleIndicator:SetScale(0.95) -- bleh
    
    InBattleIndicator:RegisterEvent("PET_BATTLE_PET_CHANGED")
    InBattleIndicator:RegisterEvent("PET_BATTLE_OPENING_START")
    InBattleIndicator:SetScript("OnEvent", function(self, event, ...)
        if not C_PetBattles.IsPlayerNPC(LE_BATTLE_PET_ENEMY) then
            self:Hide()
        end
        
        local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
        local speciesID = C_PetBattles.GetPetSpeciesID(LE_BATTLE_PET_ENEMY, activePet)
        local best = PlayersBestQuality(speciesID)
        if not best then
            Text:SetText("You don't own this pet.")
        else
            if best < C_PetBattles.GetBreedQuality(LE_BATTLE_PET_ENEMY, activePet) then
                Text:SetText("This pet is an upgrade.")
            else
                Text:SetText("You own this pet.")
            end
        end
        
        self:Show()
    end)
    
    InBattleIndicator:SetScript("OnEnter", function(self)
        local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
        local speciesID = C_PetBattles.GetPetSpeciesID(LE_BATTLE_PET_ENEMY, activePet)

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(OwnedListOrNot(BuildOwnedListS(speciesID)))
        GameTooltip:Show()
    end)
    
    InBattleIndicator:SetScript("OnLeave", function(self)
        if self == GameTooltip:GetOwner() then
            GameTooltip:Hide()
        end
    end)
end
