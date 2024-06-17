-- ===========================================================================
-- Build On Outer Rings UI Support
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "CypWor_Utility.lua"



-- ===========================================================================
-- MEMBERS
-- ===========================================================================
-- Dummy plot
local Plot = Map.GetPlot(0,0);
-- Plot purchase gold cost data
local m_CypWorBoors_Players_GoldCostsPerDistance = {};
local m_CypWorBoors_Players_TerrainModifierScalings = {};
local m_CypWorBoors_Plots_GoldCosts = {};
-- Function extension flags
local m_CypWorBoors_CityGoldGetPlotPurchaseCost_HasBeenExtended = false;



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorBoorsPlotInfoGetGoldCostInfo
-- ---------------------------------------------------------------------------
local function CypWorBoorsPlotInfoUpdateGoldCostInfo( iPlayer : number )

  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end

  -- Base cost
  local iPlotBuyBaseCost = GameInfo.GlobalParameters["PLOT_BUY_BASE_COST"].Value;
  local iGoldCostPerDistance = iPlotBuyBaseCost / 2;
  
  -- Tech scaling
  local pPlayerTech = pPlayer:GetTechs();
  local iTotalTechs = 0;
  local iResearchedTechs = 0;
  for kTech in GameInfo.Technologies() do
    iTotalTechs = iTotalTechs + 1;
    if pPlayerTech:HasTech(kTech.Index) then
      iResearchedTechs = iResearchedTechs + 1;
    end
  end
  local iTechScaling = 1 + (iResearchedTechs / iTotalTechs) * 1.5;
  
  -- Civic scaling
  local pPlayerCulture = pPlayer:GetCulture();
  local iTotalCivics = 0;
  local iResearchedCivics = 0;
  for kCivic in GameInfo.Civics() do
    iTotalCivics = iTotalCivics + 1;
    if pPlayerCulture:HasCivic(kCivic.Index) then
      iResearchedCivics = iResearchedCivics + 1;
    end
  end
  local iCivicScaling = 1 + (iResearchedCivics / iTotalCivics) * 1.5;
  
  -- Modifiers
  -- Note: Does only consider default ModifierTypes, no new dynamic modifiers from mods
  local iModifierScaling = 1;
  local tTerrainModifierScalings = {};
  for i, iModifier in ipairs(GameEffects.GetModifiers()) do
    if CypWorIsModifierActive(iModifier, iPlayer) then
      local iOwner = GameEffects.GetModifierOwner(iModifier);
      local iModifierPlayer = GameEffects.GetObjectsPlayerId(iOwner);
      if iPlayer == iModifierPlayer then
        local tModifierDefinition = GameEffects.GetModifierDefinition(iModifier);
        local pModifier = GameInfo.Modifiers[tModifierDefinition.Id];
        if pModifier ~= nil then
          -- Plot purchase
          if pModifier.ModifierType == 'MODIFIER_PLAYER_CITIES_ADJUST_PLOT_PURCHASE_COST' then
            -- Check arguments
            for sKey, xValue in pairs(tModifierDefinition.Arguments) do
              if sKey == 'Amount' then
                local iModScaling = (100 + xValue) / 100;
                iModifierScaling = iModifierScaling * iModScaling;
              end
            end
          -- Plot terrain purchase
          elseif pModifier.ModifierType == 'MODIFIER_PLAYER_CITIES_ADJUST_PLOT_PURCHASE_COST_TERRAIN' then
            tTerrainModifierScalings[pModifier.ModifierId] = {};
            -- Check arguments
            for sKey, xValue in pairs(tModifierDefinition.Arguments) do
              if sKey == 'Amount' then
                tTerrainModifierScalings[pModifier.ModifierId]['Multiplier'] = (100 + xValue) / 100;
              elseif sKey == 'TerrainType' then
                local tTerrain = GameInfo.Terrains[xValue];
                if tTerrain ~= nil then
                  tTerrainModifierScalings[pModifier.ModifierId]['TerrainTypeId'] = tTerrain.Index;
                end
              end
            end
          end
        end
      end
    end
  end
  
  -- Gold cost per distance
  local iGoldCostPerDistance iGoldCostPerDistance * iTechScaling * iCivicScaling * iModifierScaling;

  -- Merge and store
  m_CypWorBoors_Players_GoldCostsPerDistance[iPlayer] = iGoldCostPerDistance;
  m_CypWorBoors_Players_TerrainModifierScalings[iPlayer] = tTerrainModifierScalings;
end

-- ---------------------------------------------------------------------------
-- CypWorBoorsPlotInfoGetPlotGoldCost
-- ---------------------------------------------------------------------------
local function CypWorBoorsPlotInfoGetPlotGoldCost( pPlot, iDistance : number )
  -- Get player
  local iPlayer = pPlot:GetOwner();
  -- Collect player plot purchase gold data
  local iGoldCostPerDistance = m_CypWorBoors_Players_GoldCostsPerDistance[iPlayer];
  if iGoldCostPerDistance == nil then return 0 end
  local tTerrainModifierScalings = m_CypWorBoors_Players_TerrainModifierScalings[iPlayer];
  if tTerrainModifierScalings == nil then return 0 end
  -- Cost due to distance
  local iGoldCost = iDistance * iGoldCostPerDistance;
  -- Terrain modifiers
  for iModifierId, tArgs in pairs(tTerrainModifierScalings) do
    local iTerrainType = tArgs['TerrainTypeId'];
    local iMultiplier = tArgs['Multiplier'];
    if iTerrainType ~= nil and iMultiplier ~= nil then
      if pPlot:GetTerrainType() == iTerrainType then
        iGoldCost = iGoldCost * iMultiplier;
      end
    end
  end
  -- Game speed scaling
  local iSpeedCostMultiplier = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()].CostMultiplier;
  iGoldCost = iGoldCost * iSpeedCostMultiplier / 100;
  -- Rounding
  iGoldCost = math.floor(iGoldCost);
  -- Store
  local iPlot = pPlot:GetIndex();
  m_CypWorBoors_Plots_GoldCosts[iPlot] = iGoldCost;
  -- Return
  return iGoldCost;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoPlotIsInInner2RingsOfOwnedCity
-- ---------------------------------------------------------------------------
local function CypWorPlotInfoPlotIsInInner2RingsOfOwnedCity( pPlot )
  if pPlot == nil then return false end
  local iPlot = pPlot:GetIndex();
  local bPlotIsInInner2RingsOfOwnedCity = false;
  local pWorkingCity = Cities.GetPlotPurchaseCity(iPlot);
  if pWorkingCity ~= nil then
    local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pWorkingCity:GetX(), pWorkingCity:GetY());
    bPlotIsInInner2RingsOfOwnedCity = iDistance <= 2;
  end
  return bPlotIsInInner2RingsOfOwnedCity;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoPlotIsNextToOwnedPlot
-- ---------------------------------------------------------------------------
local function CypWorPlotInfoPlotIsNextToOwnedPlot( pPlot, iCity : number )
  local tNeighborPlots = Map.GetNeighborPlots(pPlot:GetX(), pPlot:GetY(), 1);
  for _, pNeighborPlot in ipairs(tNeighborPlots) do
    local pWorkingCity = Cities.GetPlotPurchaseCity(pNeighborPlot:GetIndex());
    if pWorkingCity ~= nil and iCity == pWorkingCity:GetID() then 
      return true;
    end
  end
  return false;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoPlotHasOnePerCityImprovement
-- ---------------------------------------------------------------------------
local function CypWorPlotInfoPlotHasOnePerCityImprovement( pPlot )
  if pPlot == nil then return false end
  local iImprovement = pPlot:GetImprovementType();
  if iImprovement == -1 then return false end
  local kImprovement = GameInfo.Improvements[iImprovement];
  if kImprovement == nil then return false end
  return kImprovement.OnePerCity;
end

-- ---------------------------------------------------------------------------
-- CypWorBoorsCanToggleCitizenPlot
-- ---------------------------------------------------------------------------
local function CypWorBoorsCanToggleCitizenPlot( iPlayer : number, iCity : number, iPlot : number, bIsInnerRing )
  -- Get and validate city
  local pCity :table = UI.GetHeadSelectedCity();
  if pCity == nil then return false end
  if pCity:GetID() ~= iCity then return false end
  -- Validate if is outer ring plot
  if not bIsInnerRing then
    -- Validate city has WOR district
    if not CypWorDistrictExists(pCity) then return false end
    -- Validate distance
    local iMaxDistance = CYP_WOR_DST_MIN;
    if CypWorBuildingAExists(pCity) then 
      iMaxDistance = CYP_WOR_DST_MAX;
    end
    if iDistance > iMaxDistance then return false end
  end
  -- Get locked plots
  local tCityLockedPlots = {};
  local iCityLockedCount = -1;
  local bHasInnerRingData = false;
  local tLockedOuterRingPlots = {};
  local bHasOuterRingData = false;
  -- Determine if is locked
  local bPlotIsLocked = false;
  if bIsInnerRing then
    tCityLockedPlots, iCityLockedCount = ExposedMembers.CypWor.CityGetLockedPlots(iPlayer, iCity);
    bHasInnerRingData = true;
    bPlotIsLocked = tCityLockedPlots[iPlot] ~= nil;
  else
    tLockedOuterRingPlots = pCity:GetProperty(CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS);
    if tLockedOuterRingPlots == nil then tLockedOuterRingPlots = {} end
    bHasOuterRingData = true;
    bPlotIsLocked = tLockedOuterRingPlots[iPlot] == true;
  end
  if bPlotIsLocked then return true end
  -- Get missing data
  if not bHasInnerRingData then
    tCityLockedPlots, iCityLockedCount = ExposedMembers.CypWor.CityGetLockedPlots(iPlayer, iCity);
  end
  if not bHasOuterRingData then
    tLockedOuterRingPlots = pCity:GetProperty(CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS);
    if tLockedOuterRingPlots == nil then tLockedOuterRingPlots = {} end
  end
  -- Count locks
  local iLockedOuterRingPlots = table.count(tLockedOuterRingPlots);
  local iTotalLockedPlots = iLockedOuterRingPlots + iCityLockedCount;
  local iTotalAvailableWorkerCount = pCity:GetPopulation();
  if iTotalLockedPlots + 1 > iTotalAvailableWorkerCount then return false end
  -- Return can lock
  return true;
end

-- ---------------------------------------------------------------------------
-- CypWorBoorsGetInfrastructureTypeInfo
-- ---------------------------------------------------------------------------
local function CypWorBoorsGetInfrastructureTypeInfo( tParameters : table )
  local bIsDistrict = false;
  local iInfrastructure = -1;
  local sInfrastructureHash = nil;
  if tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] ~= nil then
    bIsDistrict = true;
    local districtHash = tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE];
    sInfrastructureHash = districtHash;
    local iDistrict = GameInfo.Districts[districtHash].Index;
    iInfrastructure = iDistrict;
  elseif tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] ~= nil then
    bIsDistrict = false;
    local buildingHash = tParameters[CityOperationTypes.PARAM_BUILDING_TYPE];
    sInfrastructureHash = buildingHash;
    local iBuilding = GameInfo.Buildings[buildingHash].Index;
    iInfrastructure = iBuilding;
  else
    return nil, -1, -1;
  end
  return bIsDistrict, iInfrastructure, sInfrastructureHash;
end

-- ---------------------------------------------------------------------------
-- CypWorBoorsCanBuildInfrastructureOnPlot
-- ---------------------------------------------------------------------------
local function CypWorBoorsCanBuildInfrastructureOnPlot( pPlot, bIsDistrict, iInfrastructure : number )
  return true; -- TODO CYP
  -- Determine IF can be placed
  -- Check terrains and features
  -- Check if terrain or feature can be removed?
  -- If yes, is there a feature or whatever that will removed
end



-- ===========================================================================
-- OVERWRITES
-- ===========================================================================

-- ---------------------------------------------------------------------------
CypWorOriginal_CityManager_CanStartCommand = CityManager.CanStartCommand;
-- ---------------------------------------------------------------------------
-- CityManager.CanStartCommand
-- ---------------------------------------------------------------------------
CityManager.CanStartCommand = function( pCity, xCityCommandType, tParameters : table, bParam )
  
  -- Collect x/y data
  local iX = tParameters[CityCommandTypes.PARAM_X];
  local iY = tParameters[CityCommandTypes.PARAM_Y];
  local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
  
  -- Purchase infrastructure on outer ring plot
  if xCityCommandType == CityCommandTypes.PURCHASE
  and iX ~= nil and iY ~= nil 
  and iDistance >= CYP_WOR_DST_MIN 
  then
    -- Validate city has WOR district
    if not CypWorDistrictExists(pCity) then 
      return false, {};
    end
    -- Validate distance
    local iMaxDistance = CYP_WOR_DST_MIN;
    if CypWorBuildingAExists(pCity) then 
      iMaxDistance = CYP_WOR_DST_MAX;
    end
    if iDistance > iMaxDistance then 
      return false, {};
    end
    -- Collect data
    local pPlot = Map.GetPlot(iX,iY);
    local iPlayer = pCity:GetOwner();
    local xPurchaseYieldType = tParameters[CityCommandTypes.PARAM_YIELD_TYPE];
    -- Determine infrastructure type
    local bIsDistrict, iInfrastructure, sInfrastructureHash = CypWorBoorsGetInfrastructureTypeInfo(tParameters);
    if bIsDistrict == nil then 
      return false, {};
    end
    -- Determine cost
    local iYieldCost = pCity:GetGold():GetPurchaseCost(xPurchaseYieldType, sInfrastructureHash);
    -- Validate player can pay yields
    if not CypWorPlayerCanPayCost(iPlayer, xPurchaseYieldType, iYieldCost) then 
      return false, {};
    end
    -- Validate can place infrastructure on this plot
    if not CypWorBoorsCanBuildInfrastructureOnPlot(pPlot, bIsDistrict, iInfrastructure) then
      return false, {}; -- TODO CYP - more info?
    end
    -- Return
    local tResults = {}; -- TODO CYP - more info?
    return true, tResults;
  
  -- Purchase outer ring plot
  elseif xCityCommandType == CityCommandTypes.PURCHASE 
  and tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] ~= nil
  and iX ~= nil and iY ~= nil 
  and iDistance >= CYP_WOR_DST_MIN 
  then
    -- Validate city has WOR district
    if not CypWorDistrictExists(pCity) then return false end
    -- Validate distance
    local iMaxDistance = CYP_WOR_DST_MIN;
    if CypWorBuildingAExists(pCity) then 
      iMaxDistance = CYP_WOR_DST_MAX;
    end
    if iDistance > iMaxDistance then return false end
    -- Collect data
    local pPlot = Map.GetPlot(iX,iY);
    local iPlayer = pCity:GetOwner();
    local pPlayer = Players[iPlayer];
    -- Validate unowned
    if pPlot:GetOwner() ~= -1 then return false end
    -- Validate player gold
    local iGoldCost = m_CypWorBoors_Plots_GoldCosts[iPlot];
    if iGoldCost == nil then iGoldCost = 0 end
    local iPlayerGold	:number = pPlayer:GetTreasury():GetGoldBalance();
    if iPlayerGold < iGoldCost then return false end
    -- Return
    return true;
  end
  
  -- Original
  return CypWorOriginal_CityManager_CanStartCommand(pCity, xCityCommandType, tParameters, bParam);
end

-- ---------------------------------------------------------------------------
CypWorOriginal_CityManager_RequestCommand = CityManager.RequestCommand;
-- ---------------------------------------------------------------------------
-- CityManager.RequestCommand
-- ---------------------------------------------------------------------------
CityManager.RequestCommand = function( pCity, xCityCommandType, tParameters : table )
  
  -- Collect x/y data
  local iX = tParameters[CityCommandTypes.PARAM_X];
  local iY = tParameters[CityCommandTypes.PARAM_Y];
  local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
  
  -- Purchase infrastructure
  if xCityCommandType == CityCommandTypes.PURCHASE 
  and tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] == nil
  and iX ~= nil and iY ~= nil
  and iDistance > = CYP_WOR_DST_MIN
  then
    -- Validate
    if not CityManager.CanStartCommand(pCity, xCityCommandType, tParameters) then return false end
    -- Collect data
    local pPlot = Map.GetPlot(iX,iY);
    local iPlot = pPlot:GetIndex();
    local iCity = pCity:GetID();
    local iPlayer = pCity:GetOwner();
    local xPurchaseYieldType = tParameters[CityCommandTypes.PARAM_YIELD_TYPE];
    -- Prepare cross context
    local tBuildParameters = {};
    tBuildParameters.iPlayer = iPlayer;
    tBuildParameters.iCity = iCity;
    tBuildParameters.iPlot = iPlot;
    tBuildParameters.xPurchaseYieldType = xPurchaseYieldType;
    tBuildParameters.OnStart = "CypWor_CC_PurchaseInfrastructure";
    tBuildParameters.xInsertMode = tParameters[CityOperationTypes.PARAM_INSERT_MODE];
    tBuildParameters.xQueueDestinationLocation = tParameters[CityOperationTypes.PARAM_QUEUE_DESTINATION_LOCATION];
    -- Determine infrastructure type
    local bIsDistrict, iInfrastructure, sInfrastructureHash = CypWorBoorsGetInfrastructureTypeInfo(tParameters);
    if bIsDistrict == nil then return end
    tBuildParameters.bIsDistrict = bIsDistrict;
    if bIsDistrict then
      tBuildParameters.iDistrict = iInfrastructure;
    else
      tBuildParameters.iBuilding = iInfrastructure;
    end
    -- Determine cost
    local iYieldCost = pCity:GetGold():GetPurchaseCost(xPurchaseYieldType, sInfrastructureHash);
    tBuildParameters.iYieldCost = iYieldCost;
    -- Validate player can pay yields
    if not CypWorPlayerCanPayCost(iPlayer, xPurchaseYieldType, iYieldCost) then return end
    -- Call cross context
    UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tBuildParameters);
    -- Return
    return;
  
  -- Toggle citizen lock
  elseif xCityCommandType == CityCommandTypes.MANAGE 
  and tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] ~= nil
  and iX ~= nil and iY ~= nil
  then
    -- Determine inner or outer ring
    local bIsInnerRing = iDistance < CYP_WOR_DST_MIN;
    -- Validate
    if not CypWorBoorsCanToggleCitizenPlot(iPlayer, iCity, iPlot, bIsInnerRing) then return false end
    -- Toggle inner ring plot
    if bIsInnerRing then
      -- Original
      tResults = CypWorOriginal_CityManager_RequestCommand(pCity, xCityCommandType, tParameters);
      -- Call to clear plot lock cache
      local tParameters = {};
      tParameters.iCity = iCity;
      tParameters.OnStart = "CypWor_CC_ClearPlotLockCache";
      UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
      -- Return
      return tResults;
    -- Toggle outer ring plot
    else
      -- Cross context call if is outer ring
      local tParameters = {};
      tParameters.iPlayer = iPlayer;
      tParameters.iCity = iCity;
      tParameters.iPlot = iPlot;
      tParameters.OnStart = "CypWor_CC_TogglePlotLock";
      UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
      -- Return
      return true;
    end
  
  -- Swap tile
  elseif xCityCommandType == CityCommandTypes.SWAP_TILE_OWNER 
  and tParameters[CityCommandTypes.PARAM_SWAP_TILE_OWNER] ~= nil
  and iX ~= nil and iY ~= nil
  and iDistance > = CYP_WOR_DST_MIN
  then
    -- Collect data
    local pPlot = Map.GetPlot(iX,iY);
    local iPlot = pPlot:GetIndex();
    local iCity = pCity:GetID();
    local iPlayer = pCity:GetOwner();
    -- Validate not already owned by city
    local pWorkingCity = Cities.GetPlotPurchaseCity(iPlot);
    local iWorkingCity = nil;
    if pWorkingCity ~= nil then 
      iWorkingCity = pWorkingCity:GetID();
    end
    if iWorkingCity == nil or iWorkingCity == iCity then return false end
    -- Validate max distance
    if iDistance > CYP_WOR_DST_MAX then return false end
    -- Validate not in inner 2 rings of owned city
    if CypWorPlotInfoPlotIsInInner2RingsOfOwnedCity(pPlot) then return false end
    -- Validate is next to owned plot
    if not CypWorPlotInfoPlotIsNextToOwnedPlot(pPlot, iCity) then return false end
    -- Validate is no one per city improvement
    if CypWorPlotInfoPlotHasOnePerCityImprovement(pPlot) then return false end
    -- Notify script context to purchase plot
    local tParameters = {};
    tParameters.iPlayer = iPlayer;
    tParameters.iCity = iCity;
    tParameters.iPlot = iPlot;
    tParameters.OnStart = "CypWor_CC_SwapTile";
    UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
    -- Return
    return true;
  
  -- Purchase tile
  elseif xCityCommandType == CityCommandTypes.PURCHASE 
  and tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] ~= nil
  and iX ~= nil and iY ~= nil
  and iDistance > = CYP_WOR_DST_MIN
  then
    -- Validate
    if not CityManager.CanStartCommand(pCity, xCityCommandType, tParameters) then return false end
    -- Collect data
    local pPlot = Map.GetPlot(iX,iY);
    local iPlot = pPlot:GetIndex();
    local iCity = pCity:GetID();
    local iPlayer = pCity:GetOwner();
    local iGoldCost = m_CypWorBoors_Plots_GoldCosts[iPlot];
    if iGoldCost == nil then iGoldCost = 0 end
    -- Notify script context to purchase plot
    local tParameters = {};
    tParameters.iPlayer = iPlayer;
    tParameters.iCity = iCity;
    tParameters.iPlot = iPlot;
    tParameters.iGoldCost = iGoldCost;
    tParameters.OnStart = "CypWor_CC_PurchasePlot";
    UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
    -- Return
    return true;
  end
  
  -- Original
  CypWorOriginal_CityManager_RequestCommand(pCity, xCityCommandType, tParameters);
end


-- ---------------------------------------------------------------------------
CypWorOriginal_CityManager_GetCommandTargets = CityManager.GetCommandTargets;
-- ---------------------------------------------------------------------------
-- CityManager.GetCommandTargets
-- ---------------------------------------------------------------------------
CityManager.GetCommandTargets = function( pCity, xCommandType, tParameters : table )
  
  -- Original
  local tResults = CypWorOriginal_CityManager_GetCommandTargets(pCity, xCommandType, tParameters);
  -- Get city and player ID
  local iCity = pCity:GetID();
  local iPlayer = pCity:GetOwner();
  
  -- Get purchasable plots
  if xCommandType == CityCommandTypes.PURCHASE
  and tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] ~= nil
  then
    -- Validate city has WOR district
    if CypWorDistrictExists(pCity) then
      -- Add outer ring purchasable plots
      local tReachableUnownedOuterRingPlots = CypWorGetPurchasableOuterRingPlots(pCity);
      if table.count(tReachableUnownedOuterRingPlots) > 0 then
        for _,pPlot in pairs(tReachableUnownedOuterRingPlots) do
          local iPlot = pPlot:GetIndex();
          table.insert(tResults[CityCommandResults.PLOTS], iPlot);
        end
        -- Collect data for gold purchase cost
        CypWorBoorsPlotInfoUpdateGoldCostInfo(iPlayer);
        
        -- Extend CityGold:GetPlotPurchaseCost
        if not m_CypWorBoors_CityGoldGetPlotPurchaseCost_HasBeenExtended then
          -- Get instance to access metadable
          local pCityGold = pCity:GetGold();
          -- Extend
          fCypWorOriginal_CityGold_GetPlotPurchaseCost = getmetatable(pCityGold).__index.GetPlotPurchaseCost;
          getmetatable(pCityGold).__index.GetPlotPurchaseCost = function (self, iPlot : number)
            -- Get plot
            local pPlot = Map.GetPlotByIndex(iPlot);
            if pPlot == nil then return 0 end
            -- Get city
            local pCity = Cities.GetPlotPurchaseCity(iPlot);
            if pCity == nil then return 0 end
            -- Determine inner or outer ring
            local iDistance : number = Map.GetPlotDistance(pCity:GetX(), pCity:GetY() pPlot:GetX(), pPlot:GetY());
            -- Original for inner ring
            if iDistance < CYP_WOR_DST_MIN then
              return fCypWorOriginal_CityGold_GetPlotPurchaseCost(self, iPlot);
            -- Custom calculate for outer ring
            else
              return CypWorBoorsPlotInfoGetPlotGoldCost(pPlot, iDistance);
            end
          end
          -- Flag that function has been extended
          m_CypWorBoors_CityGoldGetPlotPurchaseCost_HasBeenExtended = true;
        end
      end
    end
  
  -- Get city citizen info
  elseif xCommandType == CityCommandTypes.MANAGE 
  and tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] ~= nil
  then
    -- Validate city has WOR district
    if CypWorDistrictExists(pCity) then
      -- Remove WOR district citizen info
      local iCypWorPlot = CypWorDistrictPlotId(pCity);
      for i,iPlotX in pairs(tResults[CityCommandResults.PLOTS]) do
        if iPlotX == iCypWorPlot then
          tResults[CityCommandResults.CITIZENS][i] = 0;
          tResults[CityCommandResults.MAX_CITIZENS][i] = 0;
          tResults[CityCommandResults.LOCKED_CITIZENS][i] = 0;
          break;
        end
      end
      -- Add outer ring plots
      local tOuterRingPlotsData : table = pCity:GetProperty(CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA);
      if tOuterRingPlotsData ~= nil and table.count(tOuterRingPlotsData) > 0 then
        for iPlot, xPlotData in pairs(tOuterRingPlotsData) do
          local iNumUnits = 0;
          if xPlotData.bIsWorked then
            iNumUnits = 1;
          end
          local iMaxUnits = 1; -- TODO CYP - districts?
          local iLockedUnits = 0;
          if bIsLocked then
            iLockedUnits = 1; -- TODO CYP - districts
          end
          table.insert(tResults[CityCommandResults.PLOTS], iPlot);
          table.insert(tResults[CityCommandResults.CITIZENS], iNumUnits);
          table.insert(tResults[CityCommandResults.MAX_CITIZENS], iMaxUnits);
          table.insert(tResults[CityCommandResults.LOCKED_CITIZENS], iLockedUnits);
        end
      end
    end
  
  -- Get swapable tiles
  elseif xCommandType == CityCommandTypes.SWAP_TILE_OWNER 
  and tParameters[CityCommandTypes.PARAM_SWAP_TILE_OWNER] ~= nil
  then
    -- Add outer rings plots when can be swapped
    local tOuterRingPlots = CypWorGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), iPlayer, iCity, CYP_WOR_DST_MIN, CYP_WOR_DST_MAX, true);
    for _,pPlot in pairs(tSwappableOuterRingPlots) do
      if not CypWorPlotInfoPlotIsInInner2RingsOfOwnedCity(pPlot) 
      and CypWorPlotInfoPlotIsNextToOwnedPlot(pPlot, iCity) 
      and not CypWorPlotInfoPlotHasOnePerCityImprovement(pPlot) 
      then
        local iPlot = pPlot:GetIndex();
        table.insert(tResults[CityCommandResults.PLOTS], iPlot);
      end
    end
  end
  
  -- Return
  return tResults;
end

-- ---------------------------------------------------------------------------
CypWorOriginal_CityManager_CanStartOperation = CityManager.CanStartOperation;
-- ---------------------------------------------------------------------------
-- CityManager.CanStartOperation
-- ---------------------------------------------------------------------------
CityManager.CanStartOperation = function( pCity, xCityOperationType, tParameters : table, bParam )

  -- Collect x/y data
  local iX = tParameters[CityCommandTypes.PARAM_X];
  local iY = tParameters[CityCommandTypes.PARAM_Y];
  local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
  
  -- Allow building on outer rings
  if xCityOperationType == CityOperationTypes.BUILD
  and iX ~= nil and iY ~= nil 
  and iDistance >= CYP_WOR_DST_MIN 
  then
    -- Validate city has WOR district
    if not CypWorDistrictExists(pCity) then return 
      return false, {};
    end
    -- Validate distance
    local iMaxDistance = CYP_WOR_DST_MIN;
    if CypWorBuildingAExists(pCity) then 
      iMaxDistance = CYP_WOR_DST_MAX;
    end
    if iDistance > iMaxDistance then
      return false, {};
    end
    -- Collect data
    local pPlot = Map.GetPlot(iX,iY);
    local iPlot = pPlot:GetIndex();
    local iCity = pCity:GetID();
    local iPlayer = pCity:GetOwner();
    -- Determine infrastructure type
    local bIsDistrict, iInfrastructure, sInfrastructureHash = CypWorBoorsGetInfrastructureTypeInfo(tParameters);
    if bIsDistrict == nil then 
      return false, {};
    end
    -- Validate can place infrastructure on this plot
    if not CypWorBoorsCanBuildInfrastructureOnPlot(pPlot, bIsDistrict, iInfrastructure) then
      return false, {}; -- TODO CYP - more info?
    end
    local tResults = {};
    tResults[CityOperationResults.SUCCESS_CONDITIONS] = {};
    return true, tResults;
  end
  
  -- Original
  return CypWorOriginal_CityManager_CanStartOperation(pCity, xCityOperationType, tParameters, bParam);
end

-- ---------------------------------------------------------------------------
CypWorOriginal_CityManager_RequestOperation = CityManager.RequestOperation;
-- ---------------------------------------------------------------------------
-- CityManager.RequestOperation
-- ---------------------------------------------------------------------------
CityManager.RequestOperation = function( pCity, xCityOperationType, tParameters : table )

  -- Collect x/y data
  local iX = tParameters[CityCommandTypes.PARAM_X];
  local iY = tParameters[CityCommandTypes.PARAM_Y];
  local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
  
  -- Allow building on outer rings
  if xCityOperationType == CityOperationTypes.BUILD
  and iX ~= nil and iY ~= nil 
  and iDistance >= CYP_WOR_DST_MIN 
  then
    -- Validate
    if not CityManager.RequestOperation(pCity, xCityOperationType, tParameters) then return false end
    -- Collect data
    local pPlot = Map.GetPlot(iX,iY);
    local iPlot = pPlot:GetIndex();
    local iCity = pCity:GetID();
    local iPlayer = pCity:GetOwner();
    -- Prepare cross context
    local tBuildParameters = {};
    tBuildParameters.iPlayer = iPlayer;
    tBuildParameters.iCity = iCity;
    tBuildParameters.iPlot = iPlot;
    tBuildParameters.OnStart = "CypWor_CC_BuildPlaceInfrastructure";
    tBuildParameters.xInsertMode = tParameters[CityOperationTypes.PARAM_INSERT_MODE];
    tBuildParameters.xQueueDestinationLocation = tParameters[CityOperationTypes.PARAM_QUEUE_DESTINATION_LOCATION];
    -- Determine infrastructure type
    local bIsDistrict, iInfrastructure, sInfrastructureHash = CypWorBoorsGetInfrastructureTypeInfo(tParameters);
    if bIsDistrict == nil then return end
    tBuildParameters.bIsDistrict = bIsDistrict;
    if bIsDistrict then
      tBuildParameters.iDistrict = iInfrastructure;
      tBuildParameters.sDistrictHash = sInfrastructureHash;
    else
      tBuildParameters.iBuilding = iInfrastructure;
      tBuildParameters.sBuildingHash = sInfrastructureHash;
    end
    -- Call cross context
    UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tBuildParameters);
    return;
  end
  -- Original
  CypWorOriginal_CityManager_RequestOperation(pCity, xCityOperationType, tParameters);
end

-- ---------------------------------------------------------------------------
CypWorOriginal_CityManager_GetOperationTargets = CityManager.GetOperationTargets;
-- ---------------------------------------------------------------------------
-- CityManager.GetOperationTargets
-- ---------------------------------------------------------------------------
CityManager.GetOperationTargets = function( pCity, xOperationType, tParameters : table )
  
  -- Original
  local tResults = CypWorOriginal_CityManager_GetOperationTargets(pCity, xOperationType, tParameters);
  
  -- Get buildable plots for district or building
  if xOperationType == CityOperationTypes.BUILD 
  and tParameters ~= nil
  then
    -- Get city and player ID
    local iCity = pCity:GetID();
    local iPlayer = pCity:GetOwner();
    -- Determine infrastructure type
    local bIsDistrict, iInfrastructure, sInfrastructureHash = CypWorBoorsGetInfrastructureTypeInfo(tParameters);
    if bIsDistrict ~= nil then 
      -- Add outer rings plots where infrastructure can be placed
      local tOuterRingPlots = CypWorGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), iPlayer, iCity, CYP_WOR_DST_MIN, CYP_WOR_DST_MAX, false);
      for _, pPlot in pairs(tOuterRingPlots) do
        if CypWorBoorsCanBuildInfrastructureOnPlot(pPlot, bIsDistrict, iInfrastructure) then
          local iPlot = pPlot:GetIndex();
          table.insert(tResults[CityOperationResults.PLOTS], iPlot);
        end
      end
    end
  end
  
  -- Return
  return tResults;
end

-- ---------------------------------------------------------------------------
-- Plot:GetAdjacencyBonusType
-- ---------------------------------------------------------------------------
CypWorOriginal_Plot_GetAdjacencyBonusType = getmetatable(Plot).__index.GetAdjacencyBonusType;
-- ---------------------------------------------------------------------------
getmetatable(Plot).__index.GetAdjacencyBonusType = function ( self, iPlayer : number, iCity : number, eDistrict, pOtherPlot )
  -- TODO CYP
  
  -- Original
  return CypWorOriginal_Plot_GetAdjacencyBonusType(self, iPlayer, iCity, eDistrict, pOtherPlot);
end

-- ---------------------------------------------------------------------------
-- Plot:GetAdjacencyYield
-- ---------------------------------------------------------------------------
CypWorOriginal_Plot_GetAdjacencyYield = getmetatable(Plot).__index.GetAdjacencyYield;
-- ---------------------------------------------------------------------------
getmetatable(Plot).__index.GetAdjacencyYield = function ( self, iPlayer : number, iCity : number, eDistrict, iYieldType : number )
  -- TODO CYP
  
  -- Original
  return CypWorOriginal_Plot_GetAdjacencyYield(self, iPlayer, iCity, eDistrict, iYieldType);
end

-- ---------------------------------------------------------------------------
-- Plot:GetAdjacencyBonusTooltip
-- ---------------------------------------------------------------------------
CypWorOriginal_Plot_GetAdjacencyBonusTooltip = getmetatable(Plot).__index.GetAdjacencyBonusTooltip;
-- ---------------------------------------------------------------------------
getmetatable(Plot).__index.GetAdjacencyBonusTooltip = function ( self, iPlayer : number, iCity : number, eDistrict, iYieldType : number )
  -- TODO CYP
  
  -- Original
  return CypWorOriginal_Plot_GetAdjacencyBonusTooltip(self, iPlayer, iCity, eDistrict, iYieldType);
end

-- ---------------------------------------------------------------------------
-- Plot:CanHaveWonder
-- ---------------------------------------------------------------------------
CypWorOriginal_Plot_CanHaveWonder = getmetatable(Plot).__index.CanHaveWonder;
-- ---------------------------------------------------------------------------
getmetatable(Plot).__index.CanHaveWonder = function ( self, iBuilding : number, iPlayer : number, iCity : number ) 
  -- Get plot
  local pPlot = self;
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return false end
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return false end
  -- Determine distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  -- Call original function for inner rings
  if iDistance <= 3 then
    return CypWorOriginal_Plot_CanHaveWonder(self, iBuilding, iPlayer, iCity);
  end
  -- Determine for outer rings
  return CypWorBoorsCanBuildInfrastructureOnPlot(pPlot, false, iBuilding);
end

-- ---------------------------------------------------------------------------
-- Plot:CanHaveDistrict
-- ---------------------------------------------------------------------------
CypWorOriginal_Plot_CanHaveDistrict = getmetatable(Plot).__index.CanHaveDistrict;
-- ---------------------------------------------------------------------------
getmetatable(Plot).__index.CanHaveDistrict = function ( self, iDistrict : number, iPlayer : number, iCity : number ) 
  -- Get plot
  local pPlot = self;
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return false end
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return false end
  -- Determine distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  -- Call original function for inner rings
  if iDistance <= 3 then
    return CypWorOriginal_Plot_CanHaveDistrict(self, iDistrict, iPlayer, iCity);
  end
  -- Determine for outer rings
  return CypWorBoorsCanBuildInfrastructureOnPlot(pPlot, true, iDistrict);
end