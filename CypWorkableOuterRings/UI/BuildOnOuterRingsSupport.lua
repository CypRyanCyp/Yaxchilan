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



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorBoorsCanToggleCitizenPlot
-- Note: Must be defined before CypWorOnClickOuterRingCitizen.
-- ---------------------------------------------------------------------------
function CypWorBoorsCanToggleCitizenPlot( iPlayer : number, iCity : number, iPlot : number, bIsInnerRing )
  -- Get and validate city
  local pCity :table = UI.GetHeadSelectedCity();
  if pCity == nil then return false end
  if pCity:GetID() ~= iCity then return false end
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
  -- Allow building on outer rings
  if xCityCommandType == CityCommandTypes.PURCHASE then
    -- Collect data
    local iX = tParameters[CityCommandTypes.PARAM_X];
    local iY = tParameters[CityCommandTypes.PARAM_Y];
    if iX ~= nil and iY ~= nil then
      local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
      if iDistance >= CYP_WOR_DST_MIN then
        -- Collect data
        local pPlot = Map.GetPlot(iX,iY);
        local iPlot = pPlot:GetIndex();
        local iCity = pCity:GetID();
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
      end
    end
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
  -- Allow building on outer rings
  if xCityCommandType == CityCommandTypes.PURCHASE then
    -- Collect data
    local iX = tParameters[CityCommandTypes.PARAM_X];
    local iY = tParameters[CityCommandTypes.PARAM_Y];
    if iX ~= nil and iY ~= nil then
      local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
      if iDistance >= CYP_WOR_DST_MIN then
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
        return;
      end
    end
  end
  -- Original
  CypWorOriginal_CityManager_RequestCommand(pCity, xCityCommandType, tParameters);
end

-- ---------------------------------------------------------------------------
CypWorOriginal_CityManager_CanStartOperation = CityManager.CanStartOperation;
-- ---------------------------------------------------------------------------
-- CityManager.CanStartOperation
-- ---------------------------------------------------------------------------
CityManager.CanStartOperation = function( pCity, xCityOperationType, tParameters : table, bParam )
  -- Allow building on outer rings
  if xCityOperationType == CityOperationTypes.BUILD then
    -- Collect data
    local iX = tParameters[CityOperationTypes.PARAM_X];
    local iY = tParameters[CityOperationTypes.PARAM_Y];
    if iX ~= nil and iY ~= nil then
      local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
      if iDistance >= CYP_WOR_DST_MIN then
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
    end
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
  -- Allow building on outer rings
  if xCityOperationType == CityOperationTypes.BUILD then
    -- Collect data
    local iX = tParameters[CityOperationTypes.PARAM_X];
    local iY = tParameters[CityOperationTypes.PARAM_Y];
    if iX ~= nil and iY ~= nil then
      local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
      if iDistance >= CYP_WOR_DST_MIN then
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
    end
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
  -- Get city and player ID
  local iCity = pCity:GetID();
  local iPlayer = pCity:GetOwner();
  
  -- Get buildable plots for district or building
  if xOperationType == CityOperationTypes.BUILD 
  and tParameters ~= nil
  then
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
CypWorOriginal_CityManager_GetCommandTargets = CityManager.GetCommandTargets;
-- ---------------------------------------------------------------------------
-- CityManager.GetCommandTargets
-- ---------------------------------------------------------------------------
CityManager.GetCommandTargets = function( pCity, xCommandType, tParameters : table )
  
  -- Prepare result 
  local tResults = nil;
  
  -- Get purchasable plots
  if xCommandType == CityCommandTypes.PURCHASE 
  and tParameters ~= nil
  and tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] ~= nil
  then
    -- Original
    tResults = CypWorOriginal_CityManager_GetCommandTargets(pCity, xCommandType, tParameters);
    -- Add outer ring purchasable plots
    local tReachableUnownedOuterRingPlots = CypWorGetPurchasableOuterRingPlots(pCity);
    for _,pPlot in pairs(tReachableUnownedOuterRingPlots) do
      local iPlot = pPlot:GetIndex();
      table.insert(tResults[CityCommandResults.PLOTS], iPlot);
    end
    
  -- Get city citizen info
  elseif xCommandType == CityCommandTypes.MANAGE 
  and tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] ~= nil
  and (tParameters[CityCommandTypes.PARAM_X] == nil or tParameters[CityCommandTypes.PARAM_Y] == nil)
  then
    -- Original
    tResults = CypWorOriginal_CityManager_GetCommandTargets(pCity, xCommandType, tParameters);
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
      -- Append outer ring plots data
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
        
  -- Get city citizen info or toggle citizen lock
  elseif xCommandType == CityCommandTypes.MANAGE 
  and tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] ~= nil
  and tParameters[CityCommandTypes.PARAM_X] ~= nil 
  and tParameters[CityCommandTypes.PARAM_Y] ~= nil)
  then
    -- Collect params
    local iX = tParameters[CityCommandTypes.PARAM_X];
    local iY = tParameters[CityCommandTypes.PARAM_Y];
    -- Determine if is inner ring
    local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
    local bIsInnerRing = iDistance < CYP_WOR_DST_MIN;
    -- Check if can toggle this plot
    if not CypWorBoorsCanToggleCitizenPlot(iPlayer, iCity, iPlot, bIsInnerRing) then 
      tResults = false;
    else
      -- Toggle inner ring plot
      if bIsInnerRing then
        -- Original
        tResults = CypWorOriginal_CityManager_GetCommandTargets(pCity, xCommandType, tParameters);
        -- Call to clear plot lock cache
        local tParameters = {};
        tParameters.iCity = iCity;
        tParameters.OnStart = "CypWor_CC_ClearPlotLockCache";
        UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
      -- Toggle outer ring plot
      else
        -- Cross context call if is outer ring
        local tParameters = {};
        tParameters.iPlayer = iPlayer;
        tParameters.iCity = iCity;
        tParameters.iPlot = iPlot;
        tParameters.OnStart = "CypWor_CC_TogglePlotLock";
        UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
        -- Result
        tResults = true;
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

--

--


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