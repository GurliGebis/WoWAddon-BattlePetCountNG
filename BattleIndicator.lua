
local addon_name, addon = ...

local module = addon:NewModule("Indicators", "AceEvent-3.0", "AceHook-3.0")

local LPJ = LibStub("LibPetJournal-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

--
--
--

function module:OnInitialize()
    self:CreateIndicator()
    self:CreateAlert()
end

function module:OnEnable()
    self:RegisterEvent("PET_BATTLE_PET_CHANGED", "Update")
    self:RegisterEvent("PET_BATTLE_OPENING_START", "Update")
end

function module:CreateIndicator()
    self.InBattleIndicator = CreateFrame("FRAME", nil, PetBattleFrame.ActiveEnemy, "InsetFrameTemplate3")
    self.InBattleIndicator:SetHeight(30)
    self.InBattleIndicator:SetWidth(143)
    self:UpdateIndicatorPosition()

    self.InBattleIndicator:EnableMouse(true)
    self.InBattleIndicator:SetMovable(true)
    self.InBattleIndicator:SetScript("OnMouseDown", function(frame)
        if IsAltKeyDown() then
            frame:StartMoving()
        end
    end)
    self.InBattleIndicator:SetScript("OnMouseUp", function(frame)
        frame:StopMovingOrSizing()
        frame:SetUserPlaced(false)  -- don't let location cache position us
        addon.db.profile.battleIndicatorX = frame:GetLeft() - PetBattleFrame.TopVersusText:GetRight()
        addon.db.profile.battleIndicatorY = frame:GetTop() - PetBattleFrame.TopVersusText:GetTop()
    end)

    local Text = self.InBattleIndicator:CreateFontString(nil, "OVERLAY")
    Text:SetFontObject(GameFontHighlightLeft)
    Text:SetJustifyH("CENTER")
    Text:SetAllPoints()
    self.InBattleIndicator.Text = Text

    self.InBattleIndicator:SetScript("OnEnter", function(self)
        module:InBattleIndicator_OnEnter(self)
    end)

    self.InBattleIndicator:SetScript("OnLeave", function(self)
        module:InBattleIndicator_OnLeave(self)
    end)
end

function module:UpdateIndicatorPosition()
    self.InBattleIndicator:ClearAllPoints()
    if addon.db.profile.battleIndicatorX then
        self.InBattleIndicator:SetPoint("TOPLEFT", PetBattleFrame.TopVersusText, "TOPRIGHT",
            addon.db.profile.battleIndicatorX, addon.db.profile.battleIndicatorY)
    else
        self.InBattleIndicator:SetPoint("TOPLEFT", PetBattleFrame.TopVersusText, "TOPRIGHT", 22, 0)
    end
end

function module:ResetIndicatorPosition()
    addon.db.profile.battleIndicatorX = nil
    addon.db.profile.battleIndicatorY = nil
    self:UpdateIndicatorPosition()
end

function module:CreateAlert()
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
end

--
--
--

local function updateBorder(owner, slot, frame)
    if not frame:IsShown() then
        return
    end

    local border = frame.Border or frame.BorderAlive
    local quality = C_PetBattles.GetBreedQuality(owner, slot)

    -- Workaround for 11.0.0 breaking C_PetBattles.GetBreedQuality
    quality = quality + 1

    local upgradeIcon = frame.X_BPC_UP
    if upgradeIcon then
        if addon.db.profile.enableBattleBorderIcon and C_PetBattles.IsWildBattle() then
            local hp = C_PetBattles.GetHealth(owner, slot)
            local speciesID = C_PetBattles.GetPetSpeciesID(owner, slot)
            local bestquality = addon:PlayersBest(speciesID)
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
    local activeEnemy = C_PetBattles.GetActivePet(Enum.BattlePetOwner.Enemy)
    local activeAlly = C_PetBattles.GetActivePet(Enum.BattlePetOwner.Ally)
    local inactiveEnemy, inactiveAlly = 2, 2
    for i=1, NUM_BATTLE_PETS_IN_BATTLE do
        if i ~= activeEnemy then
            updateBorder(Enum.BattlePetOwner.Enemy, i, PetBattleFrame["Enemy"..inactiveEnemy])
            inactiveEnemy = inactiveEnemy + 1
        else
            updateBorder(Enum.BattlePetOwner.Enemy, i, PetBattleFrame.ActiveEnemy)
        end

        if i ~= activeAlly then
            updateBorder(Enum.BattlePetOwner.Ally, i, PetBattleFrame["Ally"..inactiveAlly])
            inactiveAlly = inactiveAlly + 1
        else
            updateBorder(Enum.BattlePetOwner.Ally, i, PetBattleFrame.ActiveAlly)
        end
    end
end

--
--
--

function module:Update()
    updateBorders()

    if not addon.db.profile.enableBattleIndicator then
        return self.InBattleIndicator:Hide()
    elseif not C_PetBattles.IsWildBattle() then
        return self.InBattleIndicator:Hide()
    end
    
    local activePet = C_PetBattles.GetActivePet(Enum.BattlePetOwner.Enemy)
    local speciesID = C_PetBattles.GetPetSpeciesID(Enum.BattlePetOwner.Enemy, activePet)
    if not addon:CanObtainSpecies(speciesID) then
        return self.InBattleIndicator:Hide()
    end 

    self.InBattleIndicator.Text:SetText(addon:ShortOwnedList(speciesID))
    self.InBattleIndicator:Show()
end

function module:InBattleIndicator_OnEnter(indicator)
    local activePet = C_PetBattles.GetActivePet(Enum.BattlePetOwner.Enemy)
    local speciesID = C_PetBattles.GetPetSpeciesID(Enum.BattlePetOwner.Enemy, activePet)

    if speciesID then
        GameTooltip:SetOwner(indicator, "ANCHOR_BOTTOM")
        
        GameTooltip:AddLine(addon:CollectedText(speciesID))
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["EXPLAIN_BATTLE_HINT_DRAG"])

        GameTooltip:Show()
    end
end

function module:InBattleIndicator_OnLeave(indicator)
    if indicator == GameTooltip:GetOwner() then
        GameTooltip:Hide()
    end
end
