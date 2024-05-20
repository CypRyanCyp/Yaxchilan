-- ===========================================================================
-- Culture Bombs
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
include "CypWor_Utility.lua"



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- Culture bomb modifier argument object types
local CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_DISTRICT = "DistrictType";
local CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_BUILDING = "BuildingType";
local CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_IMPROVEMENT = "ImprovementType";
local CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPES = {};
CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPES[CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_DISTRICT] = true;
CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPES[CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_BUILDING] = true;
CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPES[CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_IMPROVEMENT] = true;
local CYP_WOR_CULTUREBOMB_MODIFIER_WILDCARD = "wildcard";


-- ===========================================================================
-- CACHES
-- ===========================================================================
-- Districts
local CYP_WOR_GAMEINFO_DISTRICTS = {};
for tDistrict in GameInfo.Districts() do
  CYP_WOR_GAMEINFO_DISTRICTS[tDistrict.Index] = tDistrict;
end
-- Buildings
local CYP_WOR_GAMEINFO_BUILDINGS = {};
for tBuilding in GameInfo.Buildings() do
  CYP_WOR_GAMEINFO_BUILDINGS[tBuilding.Index] = tBuilding;
end
-- Improvements
local CYP_WOR_GAMEINFO_IMPROVEMENTS = {};
for tItem in GameInfo.Improvements() do
  CYP_WOR_GAMEINFO_IMPROVEMENTS[tItem.Index] = tItem;
end
-- DynamicModifiers
local CYP_WOR_GAMEINFO_DYNAMICMODIFIERS = {};
for tItem in GameInfo.DynamicModifiers() do
  CYP_WOR_GAMEINFO_DYNAMICMODIFIERS[tItem.Index] = tItem;
end
-- Modifiers
local CYP_WOR_GAMEINFO_MODIFIERS = {};
for tItem in GameInfo.Modifiers() do
  CYP_WOR_GAMEINFO_MODIFIERS[tItem.ModifierId] = tItem;
end
-- Railroad
local CYP_WOR_GAMEINFO_ROUTES_RAILROAD = GameInfo.Routes['ROUTE_RAILROAD'];
-- CultureBomb modifier types
local CYP_WOR_CACHE_CULTUREBOMB_MODIFIERTYPES = {};
local CYP_WOR_CACHE_CULTUREBOMB_WILDCARD_MODIFIERTYPES = {};
local CYP_WOR_CACHE_CULTUREBOMB_CONVERT_MODIFIERTYPES = {};
for kDynamicModifier in GameInfo.DynamicModifiers() do
  if kDynamicModifier.EffectType == "EFFECT_ADD_CULTURE_BOMB_TRIGGER" then
    CYP_WOR_CACHE_CULTUREBOMB_MODIFIERTYPES[kDynamicModifier.ModifierType] = true;
  end
  if kDynamicModifier.EffectType == "EFFECT_ADJUST_ALL_DISTRICTS_CULTURE_BOMB" then
    CYP_WOR_CACHE_CULTUREBOMB_WILDCARD_MODIFIERTYPES[kDynamicModifier.ModifierType] = true;
  end
  if kDynamicModifier.EffectType == "EFFECT_ADJUST_CULTURE_BOMB_CONVERTS_CITY" then
    CYP_WOR_CACHE_CULTUREBOMB_CONVERT_MODIFIERTYPES[kDynamicModifier.ModifierType] = true;
  end
end
-- Event cache (to prevent double execution)
local m_CypWorDistrictEventCache = {};
-- Culture bomb modifier cache
local m_CypWorCultureBombModifierCache = {};
local m_CypWorCultureBombConvertModifierCache = {};



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
  if CYP_WOR_GAMEINFO_ROUTES_RAILROAD == nil then return end
  -- Get surrounding tiles
  local tRangePlots = Map.GetNeighborPlots(iX, iY, 1);
  for _, pPlot in ipairs(tRangePlots) do
    if iPlayer == pPlot:GetOwner() 
    and not pPlot:IsImpassable()
    and not pPlot:IsMountain()
    and not pPlot:IsShallowWater()
    and not pPlot:IsWater()
    and not pPlot:IsNaturalWonder()
    then
      RouteBuilder.SetRouteType(pPlot, CYP_WOR_GAMEINFO_ROUTES_RAILROAD.Index);
    end
  end
end

-- ---------------------------------------------------------------------------
-- CypWorCbCultureBombOuterRing
-- ---------------------------------------------------------------------------
function CypWorCbCultureBombOuterRing( iX : number, iY : number, iPlayer : number, iCity : number, iMaxCultureBombRange : number, bCaptureOwnedTerritory, bConvertReligion )
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
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
            local kImprovement = CYP_WOR_GAMEINFO_IMPROVEMENTS[iImprovement];
            if kImprovement ~= nil and (kImprovement.OnePerCity or kImprovement.TraitType) then
              ImprovementBuilder.SetImprovementType(pPlot, -1, NO_PLAYER);   
            end
          end
          -- Check if religion has to be converted
          if bConvertReligion and iOwnerPlayer ~= -1 and pPlotCity ~= nil then
            -- Determine player religion
            local iPlayerReligion = pPlayer:GetReligion():GetReligionTypeCreated();
            -- Only if player has founded a religion
            if iPlayerReligion ~= nil and iPlayerReligion ~= -1 then
              local iPlotCityDominantReligion = pPlotCity:GetReligion():GetMajorityReligion();
              if iPlayerReligion ~= iPlotCityDominantReligion then
                pPlotCity:GetReligion():SetAllCityToReligion(iPlayerReligion);
              end
            end
          end
          -- Change owner
          WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, iCity);
          -- Acquire plot (update modifiers)
          CypWorAcquirePlot(iPlayer, pPlot);
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- CypWorCbHasActiveCultureBombConvertModifier
-- ---------------------------------------------------------------------------
function CypWorCbHasActiveCultureBombConvertModifier( iPlayer : number )
  -- Update cache
  if m_CypWorCultureBombConvertModifierCache == nil then
    m_CypWorCultureBombConvertModifierCache = {};
  end
  if m_CypWorCultureBombConvertModifierCache[iPlayer] == nil then
    for i, iModifier in ipairs(GameEffects.GetModifiers()) do
      if CypWorIsModifierActive(iModifier, iPlayer) then
        local tModifierDefinition = GameEffects.GetModifierDefinition(iModifier);
        local pModifier = CYP_WOR_GAMEINFO_MODIFIERS[tModifierDefinition.Id];
        local sModifierType = pModifier.ModifierType;
        if CYP_WOR_CACHE_CULTUREBOMB_CONVERT_MODIFIERTYPES[sModifierType] then 
          m_CypWorCultureBombConvertModifierCache[iPlayer] = true;
          break;
        end
      end
    end
    m_CypWorCultureBombConvertModifierCache[iPlayer] = false;
  end
  -- Check if active
  return m_CypWorCultureBombConvertModifierCache[iPlayer];
end

-- ---------------------------------------------------------------------------
-- CypWorCbHasActiveCultureBombModifier
-- Returns:
--  0: no culture bomb
--  1: culture bomb unowned territory
--  2: culture bomb owned territory 
-- ---------------------------------------------------------------------------
function CypWorCbHasActiveCultureBombModifier( sArgumentName, sObjectType, bIncludeWildcardModifierTypes, iPlayer : number )
  -- Update cache
  if m_CypWorCultureBombModifierCache == nil then
    m_CypWorCultureBombModifierCache = {};
  end
  if m_CypWorCultureBombModifierCache[iPlayer] == nil then
    m_CypWorCultureBombModifierCache[iPlayer] = {};
    for sObjectTypeArgumentName,_ in pairs(CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPES) do
      m_CypWorCultureBombModifierCache[iPlayer][sObjectTypeArgumentName] = {};
    end
    m_CypWorCultureBombModifierCache[iPlayer][CYP_WOR_CULTUREBOMB_MODIFIER_WILDCARD] = false;
    -- Determine active modifiers
    for _, iModifier in ipairs(GameEffects.GetModifiers()) do
      -- Note:  We assume no culture bomb modifier has a reuirement set.
      --        That's why it is okay to only check it when upda.ting 
      --        the cache.
      if CypWorIsModifierActive(iModifier, iPlayer) then
        -- Collect info
        local tModifierDefinition = GameEffects.GetModifierDefinition(iModifier);
        local pModifier = CYP_WOR_GAMEINFO_MODIFIERS[tModifierDefinition.Id];
        local sModifierType = pModifier.ModifierType;
        -- Wildcard type
        if CYP_WOR_CACHE_CULTUREBOMB_WILDCARD_MODIFIERTYPES[sModifierType] == true then
          m_CypWorCultureBombModifierCache[iPlayer][CYP_WOR_CULTUREBOMB_MODIFIER_WILDCARD] = true;
        -- Specific type
        elseif CYP_WOR_CACHE_CULTUREBOMB_MODIFIERTYPES[sModifierType] == true then
          -- Check arguments
          local sObjectTypeKey = nil;
          local sObjectTypeValue = nil;
          local bCaptureOwnedTerritory = true;
          for sKey, sValue in pairs(tModifierDefinition.Arguments) do
            if sKey == "CaptureOwnedTerritory" then
              bCaptureOwnedTerritory = sValue == 1 or sValue == "1" or sValue == true;
            end
            if CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPES[sKey] == true then
              sObjectTypeKey = sKey;
              sObjectTypeValue = sValue;
            end
          end
          if sObjectTypeKey ~= nil then
            m_CypWorCultureBombModifierCache[iPlayer][sObjectTypeKey][sObjectTypeValue] = bCaptureOwnedTerritory;
            -- example                          1      DistrictType   DISTRICT_HOLY_SITE      true
          end
        end
      end
    end
  end
  
  -- Check district wildcard
  if sArgumentName == CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_DISTRICT 
  and m_CypWorCultureBombModifierCache[iPlayer][CYP_WOR_CULTUREBOMB_MODIFIER_WILDCARD] == true
  then return 1 end -- District wildcard never takes owned territory
  
  -- Check specific object culture bomb
  if m_CypWorCultureBombModifierCache[iPlayer][sArgumentName][sObjectType] == nil then
    return 0;
  elseif m_CypWorCultureBombModifierCache[iPlayer][sArgumentName][sObjectType] == false then
    return 1;
  else
    return 2;
  end
end

-- ---------------------------------------------------------------------------
-- CypWorCbClearCultureBombModifierCache
-- ---------------------------------------------------------------------------
function CypWorCbClearCultureBombModifierCache( iPlayer : number )
  -- Culture bomb modifier cache
  if m_CypWorCultureBombModifierCache == nil then
    m_CypWorCultureBombModifierCache = {};
  end
  m_CypWorCultureBombModifierCache[iPlayer] = nil;
  -- Culture bomb convert modifier cache
  if m_CypWorCultureBombConvertModifierCache == nil then
    m_CypWorCultureBombConvertModifierCache = {};
  end
  m_CypWorCultureBombConvertModifierCache[iPlayer] = nil;
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
  local kImprovement = CYP_WOR_GAMEINFO_IMPROVEMENTS[iImprovement];
  local sObjectType = kImprovement.ImprovementType;
  -- Check if has active culture bomb modifier
  local iCultureBombType = CypWorCbHasActiveCultureBombModifier(CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_IMPROVEMENT, sObjectType, false, iPlayer);
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
  local kDistrict = CYP_WOR_GAMEINFO_DISTRICTS[iDistrictType];
  if kDistrict == nil then return end
  local sObjectType = kDistrict.DistrictType;
  -- Check if has active culture bomb modifier
  local iCultureBombType = CypWorCbHasActiveCultureBombModifier(CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_DISTRICT, sObjectType, true, iPlayer);
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
  local kBuilding = CYP_WOR_GAMEINFO_BUILDINGS[iBuilding];
  if kBuilding == nil then return end
  local sObjectType = kBuilding.BuildingType;
  -- Ignore hidden buildings
  if CypStringStartsWith(sObjectType, CYP_WOR_BUILDING_INTERNAL_TYPE_PREFIX) then return end
  -- Check if has active culture bomb modifier
  local iCultureBombType = CypWorCbHasActiveCultureBombModifier(CYP_WOR_CULTUREBOMB_MODIFIER_OBJECT_TYPE_BUILDING, sObjectType, false, iPlayer);
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

-- ---------------------------------------------------------------------------
-- CypWorCbOnBeliefAdded
-- ---------------------------------------------------------------------------
local function CypWorCbOnBeliefAdded( iPlayer : number )
  CypWorCbClearCultureBombModifierCache(iPlayer);
end

-- ---------------------------------------------------------------------------
-- CypWorCbOnUnitGreatPersonActivated
-- ---------------------------------------------------------------------------
local function CypWorCbOnUnitGreatPersonActivated( iPlayer : number )
  CypWorCbClearCultureBombModifierCache(iPlayer);
end

-- ---------------------------------------------------------------------------
-- CypWorCbOnWorldCongressFinished
-- ---------------------------------------------------------------------------
local function CypWorCbOnWorldCongressFinished()
	for _, iPlayer in pairs(PlayerManager.GetWasEverAliveIDs()) do
    CypWorCbClearCultureBombModifierCache(iPlayer);
  end
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
  -- Clear cache events
  Events.BeliefAdded.Add(                   CypWorCbOnBeliefAdded );
  Events.UnitGreatPersonActivated.Add(      CypWorCbOnUnitGreatPersonActivated );
  Events.WorldCongressFinished.Add(         CypWorCbOnWorldCongressFinished );
  -- Log the initialization
  print("CypWor_CultureBombs.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- CypWorCbMain
-- ---------------------------------------------------------------------------
local function CypWorCbMain()
  -- LateInititalize subscription
  Events.LoadScreenClose.Add(CypWorCbLateInitialize);
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorCbMain();