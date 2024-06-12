-- ===========================================================================
-- Exposed Members
-- ===========================================================================



-- ===========================================================================
-- CACHES
-- ===========================================================================
-- Yields
local CYP_WOR_GAMEINFO_YIELD_INDEXES = {};
for pYield in GameInfo.Yields() do
  table.insert(CYP_WOR_GAMEINFO_YIELD_INDEXES, pYield.Index);
end



-- ===========================================================================
-- EXPOSED MEMBERS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorCityGetLockedPlots
-- ---------------------------------------------------------------------------
function CypWorCityGetLockedPlots( iPlayer : number, iCity : number )
  -- Validate city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return {} end
  -- Get city citizen info
  local tCommandParameters :table = {};
	tCommandParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);
	local tResults	:table = CityManager.GetCommandTargets(pCity, CityCommandTypes.MANAGE, tCommandParameters);
  -- Determine locked plots
	local tLockedUnits	:table = tResults[CityCommandResults.LOCKED_CITIZENS];
	local tPlots		    :table = tResults[CityCommandResults.PLOTS];
  local tCityLockedPlots : table = {};
  local iCityLockedCount = 0;
  if tPlots ~= nil and (table.count(tPlots) > 0) then
		for i,iPlot in pairs(tPlots) do			
      if tLockedUnits[i] > 0 then
        tCityLockedPlots[iPlot] = tLockedUnits[i];
        iCityLockedCount = iCityLockedCount + tLockedUnits[i];
      end
    end
  end
  -- Return
  return tCityLockedPlots, iCityLockedCount;
end

-- ---------------------------------------------------------------------------
-- CypWorCityGetPlotYields
-- ---------------------------------------------------------------------------
function CypWorCityGetPlotYields( iPlot : number )
  local pPlot = Map.GetPlotByIndex(iPlot);
  local tYields = {};
  for _,iYield in ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
    if pPlot == nil then
      tYields[iYield] = 0;
    else
      tYields[iYield] = pPlot:GetYield(iYield);
    end
  end
  return tYields;
end

-- ---------------------------------------------------------------------------
-- CypWorCityManagerRequestOperation
-- ---------------------------------------------------------------------------
function CypWorCityManagerRequestOperation(tParameters : table )
  print("CypWorCityManagerRequestOperation", "A");
  for k,v in pairs(tParameters) do
    print("-", k, v);
  end
  -- Get params
  local iCity = tParameters.iCity;
  local iPlayer = tParameters.iPlayer;
  local xCityOperationType = tParameters.xCityOperationType;
  -- Validate city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Call
  print("CypWorCityManagerRequestOperation", "B");
  CityManager.RequestOperation(pCity, xCityOperationType, tParameters);
  print("CypWorCityManagerRequestOperation", "C");
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorExposedMembersInitialize
-- ---------------------------------------------------------------------------
local function CypWorExposedMembersInitialize()
  -- ExposedMembers
  if not ExposedMembers.CypWor then ExposedMembers.CypWor = {} end
  ExposedMembers.CypWor.CityGetLockedPlots = CypWorCityGetLockedPlots;
  ExposedMembers.CypWor.GetPlotYields = CypWorCityGetPlotYields;
  -- GameEvents
	LuaEvents.CypWorCityManagerRequestOperation.Add( CypWorCityManagerRequestOperation);
  -- Initialized
  print("CypWor_ExposedMembers.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorExposedMembersInitialize();