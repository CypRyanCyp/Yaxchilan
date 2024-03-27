-- ===========================================================================
-- Culture Bombs
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
include "CypWor_Utility.lua"



-- ===========================================================================
-- MEMBERS
-- ===========================================================================
-- CultureBomb modifier types
local m_CypWorCultureBombModifierTypes = {};
local m_CypWorWildcardCultureBombModifierTypes = {};
local m_CypWorCultureBombConvertsModifierTypes = {}
-- Event cache (to prevent double execution)
local m_CypWorDistrictEventCache = {};



-- ===========================================================================
-- FUNCTIONS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorCheckRailroadBomb
-- ---------------------------------------------------------------------------
function CypWorCheckRailroadBomb( iPlayer : number, iCity : number, iCypWorPlot : number )
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Check player has required tech
  if RAILROAD_BOMB_TECH_ID == nil then return end
  if not pPlayer:GetTechs():HasTech(RAILROAD_BOMB_TECH_ID) then return end
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Get plot
  local iCypWorPlot = CypWorDistrictPlotId(pCity);
  local pCypWorPlot = Map.GetPlotByIndex(iCypWorPlot);
  if pCypWorPlot == nil then return end
  local iX = pCypWorPlot:GetX();
  local iY = pCypWorPlot:GetY();
  -- Get railroad index
  local kRailroad = GameInfo.Routes['ROUTE_RAILROAD'];
  if kRailroad == nil then return end
  -- Get surrounding tiles
  local tRangePlots = Map.GetNeighborPlots(iX, iY, 1);
  for _, pPlot in ipairs(tRangePlots) do
    if iPlayer == pPlot:GetOwner() then
      RouteBuilder.SetRouteType(pPlot, kRailroad.Index);
    end
  end
end

-- ---------------------------------------------------------------------------
-- CypWorCbCultureBombOuterRing
-- ---------------------------------------------------------------------------
function CypWorCbCultureBombOuterRing( iX : number, iY : number, iPlayer : number, iCity : number, iMaxCultureBombRange : number, bCaptureOwnedTerritory, bConvertReligion )
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Get surrounding tiles
  local tRangePlots = Map.GetNeighborPlots(iX, iY, 1);
  for _, pPlot in ipairs(tRangePlots) do
    local iPlot = pPlot:GetIndex();
    -- Only if not in inner ring (core game takes care of this)
    local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
    if iDistance > 3  and iDistance <= iMaxCultureBombRange then
      local iOwnerPlayer = pPlot:GetOwner();
      -- Only if unowned or owned territory is to be captured
      if iOwnerPlayer ~= iPlayer and (iOwnerPlayer == -1 or bCaptureOwnedTerritory) then
        local iDistrict = pPlot:GetDistrictType();
        local iWonder = pPlot:GetWonderType();
        local bHasDistrict = iDistrict ~= -1;
        local bHasWonder = iWonder ~= -1;
        local pPlotCity = Cities.GetPlotPurchaseCity(iPlot);
        -- If plot has no completed wonder or district
        local bHasCompletedWonderOrDistrict = false;
        if pPlotCity ~= nil then
          if bHasWonder and pPlot:IsWonderComplete() then
            bHasCompletedWonderOrDistrict = true;
          elseif not bHasWonder and bHasDistrict and pPlotCity:GetDistricts():GetDistrict(iDistrict):IsComplete() then
            bHasCompletedWonderOrDistrict = true;
          end
        end
        if not bHasCompletedWonderOrDistrict then
          -- Remove unfinished wonder
          if bHasWonder then
            pPlotCity:GetBuildings():RemoveBuilding(iWonder);
          end
          -- Remove unfinished district
          if bHasDistrict then
            pPlotCity:GetDistricts():RemoveDistrict(iDistrict);
          end
          -- Remove unique and one-per-city improvements
          local iImprovement = pPlot:GetImprovementType();
          if iImprovement ~= -1 then
            local kImprovement = GameInfo.Improvements[iImprovement];
            if kImprovement ~= nil and (kImprovement.OnePerCity or kImprovement.TraitType) then
              ImprovementBuilder.SetImprovementType(pPlot, -1, NO_PLAYER);   
            end
          end
          -- Check if religion has to be converted
          if bConvertReligion and iOwnerPlayer ~= -1 and pPlotCity ~= nil then
            -- Determine player religion
            local iPlayerReligion = nil;
            for _, pReligionInfo in ipairs(Game.GetReligion():GetReligions()) do
              if pReligionInfo.Founder == iPlayer then
                iPlayerReligion = pReligionInfo.Religion;
                break;
              end
            end
            -- Only if player has founded a religion
            if iPlayerReligion ~= nil then
              local iPlotCityDominantReligion = pPlotCity:GetReligion():GetMajorityReligion();
              if iPlayerReligion ~= iPlotCityDominantReligion then
                pPlotCity:GetReligion():SetAllCityToReligion(iPlayerReligion);
              end
            end
          end
          -- Change owner
          WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, iCity);
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- CypWorCbDetermineCultureBombModifierTypes
-- ---------------------------------------------------------------------------
function CypWorCbDetermineCultureBombModifierTypes()
  for kDynamicModifier in GameInfo.DynamicModifiers() do
    if kDynamicModifier.EffectType == "EFFECT_ADD_CULTURE_BOMB_TRIGGER" then
      m_CypWorCultureBombModifierTypes[kDynamicModifier.ModifierType] = true;
    end
    if kDynamicModifier.EffectType == "EFFECT_ADJUST_ALL_DISTRICTS_CULTURE_BOMB" then
      m_CypWorWildcardCultureBombModifierTypes[kDynamicModifier.ModifierType] = true;
    end
    if kDynamicModifier.EffectType == "EFFECT_ADJUST_CULTURE_BOMB_CONVERTS_CITY" then
      m_CypWorCultureBombConvertsModifierTypes[kDynamicModifier.ModifierType] = true;
    end
    
  end
end

-- ---------------------------------------------------------------------------
-- CypWorCbHasActiveCultureBombConvertModifier
-- ---------------------------------------------------------------------------
function CypWorCbHasActiveCultureBombConvertModifier( iPlayer : number )
  for i, iModifier in ipairs(GameEffects.GetModifiers()) do
    if CypWorIsModifierActive(iModifier, iPlayer) then
      local tModifierDefinition = GameEffects.GetModifierDefinition(iModifier);
      local pModifier = GameInfo.Modifiers[tModifierDefinition.Id];
      local sModifierType = pModifier.ModifierType;
      if m_CypWorCultureBombConvertsModifierTypes[sModifierType] then return true end
    end
  end
  return false;
end

-- ---------------------------------------------------------------------------
-- CypWorCbHasActiveCultureBombModifier
-- ---------------------------------------------------------------------------
function CypWorCbHasActiveCultureBombModifier( sArgumentName, sObjectType, bIncludeWildcardModifierTypes, iPlayer : number )
  for i, iModifier in ipairs(GameEffects.GetModifiers()) do
    if CypWorIsModifierActive(iModifier, iPlayer) then
      local tModifierDefinition = GameEffects.GetModifierDefinition(iModifier);
      local pModifier = GameInfo.Modifiers[tModifierDefinition.Id];
      local sModifierType = pModifier.ModifierType;
      -- Check modifier type
      local bIsWildcard = bIncludeWildcardModifierTypes and m_CypWorWildcardCultureBombModifierTypes[sModifierType] == true;
      local bIsSpecific = m_CypWorCultureBombModifierTypes[sModifierType] == true;
      if bIsWildcard or bIsSpecific then
        -- Check arguments
        local sValueObjectType = nil;
        local bCaptureOwnedTerritory = true;
        for sKey, sValue in pairs(tModifierDefinition.Arguments) do
          if sKey == "CaptureOwnedTerritory" then
            bCaptureOwnedTerritory = sValue == 1 or sValue == "1" or sValue == true;
          end
          if sKey == sArgumentName then
            sValueObjectType = sValue;
          end
        end
        if bIsWildcard or sValueObjectType == sObjectType then
          if bCaptureOwnedTerritory == true then
            return 2;
          else
            return 1;
          end
        end
      end
    end
  end
  return 0;
end



-- ===========================================================================
-- EVENT CALLBACKS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorCbOnImprovementAddedToMap
-- ---------------------------------------------------------------------------
local function CypWorCbOnImprovementAddedToMap( iX : number, iY : number, iImprovement : number, iPlayer : number )
  -- Get city
  local pPlot = Map.GetPlot(iX, iY);
  local iPlot = pPlot:GetIndex();
  local pCity = Cities.GetPlotPurchaseCity(iPlot);
  if pCity == nil then return end
  local iCity = pCity:GetID();
  -- Check if city has district
  if not CypWorDistrictExists(pCity) then return end
  -- Determine improvement
  local kImprovement = GameInfo.Improvements[iImprovement];
  local sObjectType = kImprovement.ImprovementType;
  -- Check if has active culture bomb modifier
  local iCultureBombType = CypWorCbHasActiveCultureBombModifier("ImprovementType", sObjectType, false, iPlayer);
  if iCultureBombType == 0 then return end
  -- Culture bomb
  local bCaptureOwnedTerritory = iCultureBombType == 2;
  local bConvertReligion = bCaptureOwnedTerritory and CypWorCbHasActiveCultureBombConvertModifier(iPlayer);
  local iMaxCultureBombRange = 4;
  if CypWorBuildingAExists(pCity) then
    iMaxCultureBombRange = 5;
  end
  CypWorCbCultureBombOuterRing(iX, iY, iPlayer, iCity, iMaxCultureBombRange, bCaptureOwnedTerritory, bConvertReligion);
end

-- ---------------------------------------------------------------------------
-- CypWorCbOnDistrictBuildProgressChanged
-- ---------------------------------------------------------------------------
local function CypWorCbOnDistrictBuildProgressChanged(
                iPlayer : number, 
                iDistrict : number, 
                iCity : number, 
                iX : number, 
                iY : number, 
                iDistrictType : number, 
                iEra : number,
                iCiv : number,
                iPercent : number)
  -- Only when finished
  if iPercent < 100 then return end
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Check if city has district
  if not CypWorDistrictExists(pCity) then return end
  -- Check cache
  local iTurn = Game.GetCurrentGameTurn();
  if m_CypWorDistrictEventCache[iDistrict] == iTurn then return end
  m_CypWorDistrictEventCache[iDistrict] = iTurn;
  -- Get district
  local kDistrict = GameInfo.Districts[iDistrictType];
  if kDistrict == nil then return end
  local sObjectType = kDistrict.DistrictType;
  -- Check if has active culture bomb modifier
  local iCultureBombType = CypWorCbHasActiveCultureBombModifier("DistrictType", sObjectType, true, iPlayer);
  if iCultureBombType == 0 then return end
  -- Culture bomb
  local bCaptureOwnedTerritory = iCultureBombType == 2;
  local bConvertReligion = bCaptureOwnedTerritory and CypWorCbHasActiveCultureBombConvertModifier(iPlayer);
  local iMaxCultureBombRange = 4;
  if CypWorBuildingAExists(pCity) then
    iMaxCultureBombRange = 5;
  end
  CypWorCbCultureBombOuterRing(iX, iY, iPlayer, iCity, iMaxCultureBombRange, bCaptureOwnedTerritory, bConvertReligion);
end

-- ---------------------------------------------------------------------------
-- CypWorCbOnBuildingConstructed
-- ---------------------------------------------------------------------------
local function CypWorCbOnBuildingConstructed( iPlayer : number, iCity : number, iBuilding : number )
  -- Railroad bomb
  if iBuilding == CYP_WOR_BUILDING_A_ID then
    CypWorCheckRailroadBomb(iPlayer, iCity);
  end
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Check if city has district
  if not CypWorDistrictExists(pCity) then return end
  -- Get Building
  local kBuilding = GameInfo.Buildings[iBuilding];
  if kBuilding == nil then return end
  local sObjectType = kBuilding.BuildingType;
  -- Ignore hidden buildings
  if CypStringStartsWith(sObjectType, CYP_WOR_BUILDING_INTERNAL_TYPE_PREFIX) then return end
  -- Check if has active culture bomb modifier
  local iCultureBombType = CypWorCbHasActiveCultureBombModifier("BuildingType", sObjectType, false, iPlayer);
  if iCultureBombType == 0 then return end
  -- Get plot
  local iPlot = pCity:GetBuildings():GetBuildingLocation(iBuilding);
  local pPlot = Map.GetPlotByIndex(iPlot);
  local iX = pPlot:GetX();
  local iY = pPlot:GetY();
  -- Culture bomb
  local bCaptureOwnedTerritory = iCultureBombType == 2;
  local bConvertReligion = bCaptureOwnedTerritory and CypWorCbHasActiveCultureBombConvertModifier(iPlayer);
  local iMaxCultureBombRange = 4;
  if CypWorBuildingAExists(pCity) then
    iMaxCultureBombRange = 5;
  end
  CypWorCbCultureBombOuterRing(iX, iY, iPlayer, iCity, iMaxCultureBombRange, bCaptureOwnedTerritory, bConvertReligion);
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorCbLateInitialize
-- ---------------------------------------------------------------------------
local function CypWorCbLateInitialize()
  -- Event and GameEvent subscriptions
  Events.ImprovementAddedToMap.Add(         CypWorCbOnImprovementAddedToMap );
  Events.DistrictBuildProgressChanged.Add(  CypWorCbOnDistrictBuildProgressChanged);
  GameEvents.BuildingConstructed.Add(       CypWorCbOnBuildingConstructed);
  -- Log the initialization
  print("CypWor_CultureBombs.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- CypWorCbMain
-- ---------------------------------------------------------------------------
local function CypWorCbMain()
  -- Determine culture bomb modifiers
  CypWorCbDetermineCultureBombModifierTypes();
  -- LateInititalize subscription
  Events.LoadScreenClose.Add(CypWorCbLateInitialize);
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorCbMain();