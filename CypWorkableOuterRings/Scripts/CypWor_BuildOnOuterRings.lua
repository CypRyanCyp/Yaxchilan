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
  -- Get plot
  local pPlot = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return end
  print("CypWorBuildDistrict", "E");
  -- Add queue info to plot
  tParameters.iTurn = Game.GetCurrentGameTurn();
  pPlot:SetProperty(CYP_WOR_PROPERTY_OUTER_RING_BUILD_ADD_TO_QUEUE, tParameters);
  -- Place district
  pCity:GetBuildQueue():CreateIncompleteDistrict(iDistrict, iPlot, 0);
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