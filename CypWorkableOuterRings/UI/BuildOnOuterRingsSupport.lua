-- ===========================================================================
-- Build On Outer Rings UI Support
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "CypWor_Utility.lua"



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- 



-- ===========================================================================
-- MEMBERS
-- ===========================================================================
-- Dummy plot
local Plot = Map.GetPlot(0,0);



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================



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
        -- TODO CYP
        local tResults = {};
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
        -- TODO CYP
        
        local districtHash = tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE];
        local purchaseYield = tParameters[CityCommandTypes.PARAM_YIELD_TYPE];
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
        -- TODO CYP
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

  print("CityManager.RequestOperation", pCity, xCityOperationType, tParameters);
  for k,v in pairs(tParameters) do
    print("-", k, v);
  end
  
  -- Don't call recursive
  if not tParameters.bAlreadyCalled then
    -- Allow building on outer rings
    if xCityOperationType == CityOperationTypes.BUILD then
      print("CityManager.RequestOperation", "CityOperationTypes.BUILD");
      -- Collect data
      local iX = tParameters[CityOperationTypes.PARAM_X];
      local iY = tParameters[CityOperationTypes.PARAM_Y];
      if iX ~= nil and iY ~= nil then
        local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
        if iDistance >= CYP_WOR_DST_MIN then
        print("CityManager.RequestOperation", "outer-ring");
          -- Collect data
          local pPlot = Map.GetPlot(iX,iY);
          local iPlot = pPlot:GetIndex();
          local iCity = pCity:GetID();
          local iPlayer = pCity:GetOwner();
          -- Prepare cross context
          tParameters.iPlayer = iPlayer;
          tParameters.iCity = iCity;
          tParameters.iPlot = iPlot;
          tParameters.bAlreadyCalled = true;
          tParameters.sOperationType = xCityOperationType;
          -- Determine type
          if tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] ~= nil then
          print("CityManager.RequestOperation", "district");
            local districtHash = tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE];
            local iDistrict = GameInfo.Districts[districtHash].Index;
            tParameters.iDistrict = iDistrict;
            tParameters.OnStart = "CypWor_CC_BuildDistrict";
          elseif tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] ~= nil then
            local buildingHash = tParameters[CityOperationTypes.PARAM_BUILDING_TYPE];
            local iBuilding = GameInfo.Buildings[buildingHash].Index;
            tParameters.iBuilding = iBuilding;
            tParameters.OnStart = "CypWor_CC_BuildBuilding";
          end
          -- Call cross context
          UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
          print("CityManager.RequestOperation", "requested");
        end
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
    -- Districts
    if tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] ~= nil then
      local districtHash = tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE];
      local tOuterRingPlots = CypWorGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), iPlayer, iCity, CYP_WOR_DST_MIN, CYP_WOR_DST_MAX, false);
      for _, pPlot in pairs(tOuterRingPlots) do
        local iPlot = pPlot:GetIndex();
        -- TODO CYP - check district
        table.insert(tResults[CityOperationResults.PLOTS], iPlot);
      end
    
    -- Buildings
    elseif tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] ~= nil then
      local buildingHash = tParameters[CityOperationTypes.PARAM_BUILDING_TYPE];
      local tOuterRingPlots = CypWorGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), iPlayer, iCity, CYP_WOR_DST_MIN, CYP_WOR_DST_MAX, false);
      for _, pPlot in pairs(tOuterRingPlots) do
        local iPlot = pPlot:GetIndex();
        -- TODO CYP - check building
        table.insert(tResults[CityOperationResults.PLOTS], iPlot);
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
  -- Original
  local tResults = CypWorOriginal_CityManager_GetCommandTargets(pCity, xCommandType, tParameters);
  -- Get city and player ID
  local iCity = pCity:GetID();
  local iPlayer = pCity:GetOwner();
  -- Get purchasable plots
  if xCommandType == CityCommandTypes.PURCHASE 
  and tParameters ~= nil
  and tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] ~= nil
  then
    -- Add outer ring purchasable plots
    -- TODO CYP
    -- table.insert(tResults[CityCommandResults.PLOTS], iPlot);
  end
  -- Return
  return tResults;
end


-- ---------------------------------------------------------------------------
CypWorOriginal_AddAdjacentPlotBonuses = AddAdjacentPlotBonuses;
-- ---------------------------------------------------------------------------
-- CityManager.GetCommandTargets
-- ---------------------------------------------------------------------------
function AddAdjacentPlotBonuses( pPlot : table, sDistrictType : string, pCity : table, tCurrentBonuses : table )
  -- TODO CYP
  
  -- Original
  return CypWorOriginal_AddAdjacentPlotBonuses(pPlot, sDistrictType, pCity, tCurrentBonuses);
end


-- ---------------------------------------------------------------------------
-- Plot:GetAdjacencyBonusType
-- ---------------------------------------------------------------------------
CypWorOriginal_Plot_GetAdjacencyBonusType = getmetatable(Plot).__index.GetAdjacencyBonusType;
-- ---------------------------------------------------------------------------
getmetatable(Plot).__index.GetAdjacencyBonusType = function ( self, iPlayer : number, iCity : number, eDistrict, pOtherPlot )
  -- TODO CYP
  -- Original
  CypWorOriginal_Plot_GetAdjacencyBonusType(self, iPlayer, iCity, eDistrict, pOtherPlot);
end


-- ---------------------------------------------------------------------------
-- Plot:CanHaveWonder
-- ---------------------------------------------------------------------------
CypWorOriginal_Plot_CanHaveWonder = getmetatable(Plot).__index.CanHaveWonder;
-- ---------------------------------------------------------------------------
getmetatable(Plot).__index.CanHaveWonder = function ( self, iBuilding : number, iPlayer : number, iCity : number ) 
  print("CanHaveWonder");
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
    CypWorOriginal_Plot_CanHaveWonder(self, iBuilding, iPlayer, iCity);
  end
  -- Determine for outer rings
  return true; -- TODO CYP
end

-- ---------------------------------------------------------------------------
-- Plot:CanHaveDistrict
-- ---------------------------------------------------------------------------
CypWorOriginal_Plot_CanHaveDistrict = getmetatable(Plot).__index.CanHaveDistrict;
-- ---------------------------------------------------------------------------
getmetatable(Plot).__index.CanHaveDistrict = function ( self, iDistrict : number, iPlayer : number, iCity : number ) 
  print("CanHaveDistrict");
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
    CypWorOriginal_Plot_CanHaveDistrict(self, iDistrict, iPlayer, iCity);
  end
  -- Determine for outer rings
  return true; -- TODO CYP
end