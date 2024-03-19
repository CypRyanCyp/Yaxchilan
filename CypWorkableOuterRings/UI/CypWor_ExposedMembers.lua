-- ===========================================================================
-- Exposed Members
-- ===========================================================================



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
  -- Initialized
  print("CypWor_ExposedMembers.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorExposedMembersInitialize();