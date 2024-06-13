-- ===========================================================================
-- Build On Outer Rings
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "CypWor_Utility.lua"



-- ===========================================================================
-- TODOS
-- ===========================================================================
-- Remove yield on purchase
-- Use ProductionPanel.lua : GetBuildInsertMode idea to request command from UI context again to put the new item on correct place in production queue


-- ===========================================================================
-- EVENT CALLBACKS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorBuildPlaceInfrastructure
-- ---------------------------------------------------------------------------
local function CypWorBuildPlaceInfrastructure( iPlayer : number, tParameters : table )
  -- Get params
  local iCity = tParameters.iCity;
  local iPlot = tParameters.iPlot;
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return end
  -- Place infrastructure
  local tQueueParameters = {};
  if tParameters.bIsDistrict then
    pCity:GetBuildQueue():CreateIncompleteDistrict(tParameters.iDistrict, iPlot, 0);
    tQueueParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = tParameters.sDistrictHash;
  else
    pCity:GetBuildQueue():CreateIncompleteBuilding(tParameters.iBuilding, iPlot, 0);
    tQueueParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = tParameters.sBuildingHash;
  end
  -- Add to queue
  tQueueParameters[CityOperationTypes.PARAM_INSERT_MODE] = tParameters.xInsertMode;
  if tParameters.xQueueDestinationLocation then
    tQueueParameters[CityOperationTypes.PARAM_QUEUE_DESTINATION_LOCATION] = tParameters.xQueueDestinationLocation
  end
  ExposedMembers.CypWor.CityManagerRequestOperation(iPlayer, iCity, CityOperationTypes.BUILD, tQueueParameters);
end

-- ---------------------------------------------------------------------------
-- CypWorBuildDistrict
-- ---------------------------------------------------------------------------
local function CypWorPurchaseDistrict( iPlayer : number, tParameters : table )
  print("CypWorPurchaseDistrict", "A");
  for k,v in pairs(tParameters) do
    print("-", k, v);
  end
  -- Get params
  local iCity = tParameters.iCity;
  local iDistrict = tParameters.iDistrict;
  local iPlot = tParameters.iPlot;
  print("CypWorPurchaseDistrict", "B", iCity, iDistrict, iPlot);
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  print("CypWorPurchaseDistrict", "C");
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return end
  print("CypWorPurchaseDistrict", "D");
  print("CypWorPurchaseDistrict", "E");
  -- Place district
  pCity:GetBuildQueue():CreateIncompleteDistrict(iDistrict, iPlot, 100);
  -- Remove cost
  -- TODO CYP
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorLateInitialize
-- ---------------------------------------------------------------------------
local function CypWorBoorLateInitialize()
  -- Custom game event subscriptions
  GameEvents.CypWor_CC_BuildPlaceInfrastructure.Add( CypWorBuildPlaceInfrastructure );
  GameEvents.CypWor_CC_PurchasInfrastructure.Add( CypWorPurchaseInfrastructure );
  -- Log the initialization
  print("CypWor_BuildOnOuterRings.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- CypWorMain
-- ---------------------------------------------------------------------------
local function CypWorBoorMain()
  -- LateInititalize subscription
  Events.LoadScreenClose.Add(CypWorBoorLateInitialize);
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorBoorMain();