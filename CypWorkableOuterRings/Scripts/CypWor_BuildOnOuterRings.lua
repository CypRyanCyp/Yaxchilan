-- ===========================================================================
-- Build On Outer Rings
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- BuildOnOuterRings
include "CypWor_BuildOnOuterRings.lua"



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
  local bIsDistrict = tParameters.bIsDistrict;
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return end
  -- Get plot
  local pPlot = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return end
  -- Validate
  local iInfrastructure = -1;
  if bIsDistrict then
    iInfrastructure = tParameters.iDistrict;
  else
    iInfrastructure = tParameters.iBuilding;
  end
  local bCanStart, tSuccessConditions = CypWorBoorsCanBuildInfrastructureOnPlot(pPlot, bIsDistrict, iInfrastructure);
  if not bCanStart then return end
  -- Place infrastructure
  local tQueueParameters = {};
  if bIsDistrict then
    pCity:GetBuildQueue():CreateIncompleteDistrict(tParameters.iDistrict, iPlot, 0);
    tQueueParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = tParameters.sDistrictHash;
  else
    pCity:GetBuildQueue():CreateIncompleteBuilding(tParameters.iBuilding, iPlot, 0);
    tQueueParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = tParameters.sBuildingHash;
  end
  -- Remove feature
  if tSuccessConditions.sFeatureType then
    TerrainBuilder.SetFeatureType(pPlot, -1);
  end
  -- Remove improvement
  if tSuccessConditions.sImprovementsType then
    ImprovementBuilder:SetImprovementType(pPlot, -1);
  end
  -- Remove resource
  if tSuccessConditions.sResourcesType then
    ResourceBuilder.SetResourceType(pPlot, -1);
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
local function CypWorPurchaseInfrastructure( iPlayer : number, tParameters : table )
  -- Get params
  local iCity = tParameters.iCity;
  local iPlot = tParameters.iPlot;
  local iYieldCost = tParameters.iYieldCost;
  local xPurchaseYieldType = tParameters.xPurchaseYieldType
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return end
  -- Validate player can pay yields
  if not CypWorPlayerCanPayCost(iPlayer, xPurchaseYieldType, iYieldCost) then end
  -- Place infrastructure
  if tParameters.bIsDistrict then
    pCity:GetBuildQueue():CreateIncompleteDistrict(tParameters.iDistrict, iPlot, 100);
  else
    pCity:GetBuildQueue():CreateIncompleteBuilding(tParameters.iBuilding, iPlot, 100);
  end
  -- Remove payment yields from player
  if xPurchaseYieldType == YieldTypes.GOLD then
    pPlayer:GetTreasury():ChangeGoldBalance(-iYieldCost);
  elseif xPurchaseYieldType == YieldTypes.FAITH then
    pPlayer:GetReligion():ChangeFaithBalance(-iYieldCost);
  end
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
  GameEvents.CypWor_CC_PurchaseInfrastructure.Add( CypWorPurchaseInfrastructure );
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