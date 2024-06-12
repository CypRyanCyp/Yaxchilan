-- ===========================================================================
-- Build On Outer Rings
-- ===========================================================================



-- ===========================================================================
-- TODOS
-- ===========================================================================
-- Remove yield on purchase
-- Use ProductionPanel.lua : GetBuildInsertMode idea to request command from UI context again to put the new item on correct place in production queue


-- ===========================================================================
-- EVENT CALLBACKS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorBuildDistrict
-- ---------------------------------------------------------------------------
local function CypWorBuildDistrict( iPlayer : number, tParameters : table )
  print("CypWorBuildDistrict", "A");
  for k,v in pairs(tParameters) do
    print("-", k, v);
  end
  -- Get params
  local iCity = tParameters.iCity;
  local iDistrict = tParameters.iDistrict;
  local iPlot = tParameters.iPlot;
  print("CypWorBuildDistrict", "B", iCity, iDistrict, iPlot);
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  print("CypWorBuildDistrict", "C");
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return end
  print("CypWorBuildDistrict", "D");
  -- Place district
  pCity:GetBuildQueue():CreateIncompleteDistrict(iDistrict, iPlot, 0);
  print("CypWorBuildDistrict", "E");
  -- Call initial function again to add to queue
  --LuaEvents.CypWorCityManagerRequestOperation(iPlayer, iCity, tParameters.sOperationType, tParameters);
  --ExposedMembers.CypWor.CityManagerRequestOperation(iPlayer, iCity, tParameters.sOperationType, tParameters);
  ReportingEvents.SendLuaEvent("CypWorCityManagerRequestOperation", tParameters);
  -- TODO cyp - differ between purchase and build
  print("CypWorBuildDistrict", "F");
end

-- ---------------------------------------------------------------------------
-- CypWorBuildBuilding
-- ---------------------------------------------------------------------------
local function CypWorBuildBuilding( iPlayer : number, tParameters : table )
  -- Get params
  local iCity = tParameters.iCity;
  local iBuilding = tParameters.iBuilding;
  local iPlot = tParameters.iPlot;
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return end
  -- Place building
  pCity:GetBuildQueue():CreateIncompleteBuilding(iBuilding, iPlot, 0);
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorLateInitialize
-- ---------------------------------------------------------------------------
local function CypWorBoorLateInitialize()
  -- Custom game event subscriptions
  GameEvents.CypWor_CC_BuildDistrict.Add(   CypWorBuildDistrict);
  GameEvents.CypWor_CC_BuildBuilding.Add(   CypWorBuildBuilding);
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