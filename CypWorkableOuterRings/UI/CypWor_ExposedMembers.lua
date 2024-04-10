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

-- ---------------------------------------------------------------------------
-- CypWorCityGetPlotYields
-- ---------------------------------------------------------------------------
function CypWorCityGetPlotYields( iPlot : number, iYieldType : number )
  local pPlot = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return 0 end
  return pPlot:GetYield(iYieldType);
end



-- ===========================================================================
-- CUSTOM EVENTS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorUnitRequestCommand
-- ---------------------------------------------------------------------------
function CypWorUnitRequestCommand( iPlayer : number, iUnit : number, sUnitCommandType )
  print("CypWorUnitRequestCommand", iPlayer, iUnit, sUnitCommandType);
  -- Get unit
  local pUnit = UnitManager.GetUnit(iPlayer, iUnit);
  if pUnit == nil then return end
  -- Get unit command
  local kActivateUnitCommand = GameInfo.UnitCommands[sUnitCommandType];
  if kActivateUnitCommand == nil then return end
  -- Request command
	UnitManager.RequestCommand(pUnit, kActivateUnitCommand.Hash);
  print("CypWorUnitRequestCommand", "executed");
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorExposedMembersInitialize
-- ---------------------------------------------------------------------------
local function CypWorExposedMembersInitialize()
  -- Exposed Members
  if not ExposedMembers.CypWor then ExposedMembers.CypWor = {} end
  ExposedMembers.CypWor.CityGetLockedPlots = CypWorCityGetLockedPlots;
  ExposedMembers.CypWor.GetPlotYields = CypWorCityGetPlotYields;
  ExposedMembers.CypWor.UnitRequestCommand = CypWorUnitRequestCommand;
  -- Initialized
  print("CypWor_ExposedMembers.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorExposedMembersInitialize();