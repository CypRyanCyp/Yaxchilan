-- ===========================================================================
-- BUILD ON OUTER RINGS
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "CypWor_Utility.lua"



-- ===========================================================================
-- EVENTS
-- ===========================================================================


-- ---------------------------------------------------------------------------
-- CypWorBorOnDistrictAddedToMap
-- ---------------------------------------------------------------------------
function CypWorBorOnDistrictAddedToMap( 
          iPlayer : number, 
          iDistrict : number, 
          iCity : number, 
          iX : number,
          iY : number,
          iDistrictType : number,
          iPercentCompleted : number)
  print("CypWorBorOnDistrictAddedToMap", "A");
  -- Validate same turn
  if tParameters.iTurn ~= Game.GetCurrentGameTurn() then return end
  print("CypWorBorOnDistrictAddedToMap", "B");
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  print("CypWorBorOnDistrictAddedToMap", "C");
  -- Validate outer ring
  local iDistance : number = Map.GetPlotDistance(iX, iY, pCity:GetX(), pCity:GetY());
  if iDistance < CYP_WOR_DST_MIN then return end
  print("CypWorBorOnDistrictAddedToMap", "D");
  -- Get plot
  local pPlot = Map.GetPlot(iX,iY);
  if pPlot == nil then return end
  print("CypWorBorOnDistrictAddedToMap", "E");
  -- Get property
  local tParameters = pPlot:GetProperty(CYP_WOR_PROPERTY_OUTER_RING_BUILD_ADD_TO_QUEUE);
  if tParameters == nil then return end
  print("CypWorBorOnDistrictAddedToMap", "F");
  -- Call add to queue
  tParameters[CYP_WOR_PARAM_OUTER_RING_BUILD_ADD_TO_QUEUE] = true;
  CityManager.RequestOperation(pCity, Parameters.sOperationType, tParameters);
  print("CypWorBorOnDistrictAddedToMap", "G");
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorBuildOnOuterRingsInitialize
-- ---------------------------------------------------------------------------
local function CypWorBuildOnOuterRingsLateInitialize()
  -- Events
	Events.DistrictAddedToMap.Add( CypWorBorOnDistrictAddedToMap );
  -- Initialized
  print("CypWor_BuildOnOuterRings.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- CypWorBuildOnOuterRingsInitialize
-- ---------------------------------------------------------------------------
function CypWorBuildOnOuterRingsInitialize()
    -- LateInititalize subscription
    Events.LoadScreenClose.Add(CypWorBuildOnOuterRingsLateInitialize);
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorBuildOnOuterRingsInitialize();