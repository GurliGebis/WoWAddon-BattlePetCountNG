
local addon_name, addon = ...

local LPJ = LibStub("LibPetJournal-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

local is5_1 = not not C_PetJournal.GetNumCollectedInfo

--
--
--

local InBattleIndicator = CreateFrame("FRAME", nil, PetBattleFrame.ActiveEnemy, "InsetFrameTemplate3")
InBattleIndicator:SetPoint("RIGHT", PetBattleFrame.ActiveEnemy, "LEFT", -6, 0)
InBattleIndicator:SetPoint("LEFT", PetBattleFrame.TopVersusText, "RIGHT", 22, 0)
InBattleIndicator:SetHeight(30)

local Text = InBattleIndicator:CreateFontString(nil, "OVERLAY")
Text:SetFontObject(GameFontHighlightLeft)
Text:SetJustifyH("CENTER")
Text:SetAllPoints()

--
--
--

for _,frame in pairs{PetBattleFrame.Enemy2, PetBattleFrame.Enemy3} do
    local overlay = CreateFrame("FRAME", nil, frame)
    overlay:SetWidth(16)
    overlay:SetHeight(16)
    overlay:SetPoint("TOPRIGHT", 7, 0)
    local texture = overlay:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\AddOns\\"..addon_name.."\\Media\\investigate")
    overlay.Texture = texture
    overlay:Hide()
    frame.X_BPC_UP = overlay
end

local border_touched = {}           -- try not to mess up other addons?
local function updateBorder(owner, slot, frame)
    if not frame:IsShown() then
        return
    end
    
    local border = frame.Border or frame.BorderAlive
    local quality = C_PetBattles.GetBreedQuality(owner, slot)
    
    if not is5_1 then
        if addon.db.profile.enableBattleBorder then
            border:SetVertexColor(ITEM_QUALITY_COLORS[quality-1].r,
                                ITEM_QUALITY_COLORS[quality-1].g,
                                ITEM_QUALITY_COLORS[quality-1].b)
            border_touched[border] = true
        elseif border_touched[border] then
            border:SetVertexColor(1, 1, 1)
            border_touched[border] = nil
        end
    end
        
    local upgradeIcon = frame.X_BPC_UP
    if upgradeIcon then
        if addon.db.profile.enableBattleBorderIcon and C_PetBattles.IsWildBattle() then
            local hp = C_PetBattles.GetHealth(owner, slot)
            local speciesID = C_PetBattles.GetPetSpeciesID(owner, slot)
            local bestquality = PlayersBest(speciesID)
            if hp > 0 and (not bestquality or quality > bestquality) then
                upgradeIcon.Texture:SetVertexColor(
                    ITEM_QUALITY_COLORS[quality-1].r,
                    ITEM_QUALITY_COLORS[quality-1].g,
                    ITEM_QUALITY_COLORS[quality-1].b)
                upgradeIcon:Show()
            else
                upgradeIcon:Hide()
            end
        else
            upgradeIcon:Hide()
        end
    end
end

local function updateBorders()
    local activeEnemy = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
    local activeAlly = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY)
    local inactiveEnemy, inactiveAlly = 2, 2
    for i=1, NUM_BATTLE_PETS_IN_BATTLE do
        if i ~= activeEnemy then
            updateBorder(LE_BATTLE_PET_ENEMY, i, PetBattleFrame["Enemy"..inactiveEnemy])
            inactiveEnemy = inactiveEnemy + 1
        else
            updateBorder(LE_BATTLE_PET_ENEMY, i, PetBattleFrame.ActiveEnemy)
        end
        
        if i ~= activeAlly then
            updateBorder(LE_BATTLE_PET_ALLY, i, PetBattleFrame["Ally"..inactiveAlly])
            inactiveAlly = inactiveAlly + 1
        else
            updateBorder(LE_BATTLE_PET_ALLY, i, PetBattleFrame.ActiveAlly)
        end
    end
end

--
--
--

InBattleIndicator:RegisterEvent("PET_BATTLE_PET_CHANGED")
InBattleIndicator:RegisterEvent("PET_BATTLE_OPENING_START")
InBattleIndicator:SetScript("OnEvent", function(self, event, ...)
    updateBorders()

    if not addon.db.profile.enableBattleIndicator then
        return self:Hide()
    elseif not C_PetBattles.IsWildBattle() then
        return self:Hide()
    end
    
    local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
    local speciesID = C_PetBattles.GetPetSpeciesID(LE_BATTLE_PET_ENEMY, activePet)
    Text:SetText(ShortOwnedList(speciesID))
    self:Show()
end)

InBattleIndicator:SetScript("OnEnter", function(self)
    local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
    local speciesID = C_PetBattles.GetPetSpeciesID(LE_BATTLE_PET_ENEMY, activePet)

    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    
    GameTooltip:AddLine(OwnedListOrNot(BuildOwnedListS(speciesID)))
    GameTooltip:Show()
end)

InBattleIndicator:SetScript("OnLeave", function(self)
    if self == GameTooltip:GetOwner() then
        GameTooltip:Hide()
    end
end)
