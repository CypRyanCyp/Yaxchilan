-- ===========================================================================
-- Plotinfo UI
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "CypWor_Utility.lua"
-- Original
local tBaseFileVersions = {
    "PlotInfo_CQUI",  -- CQUI
    "PlotInfo"        -- Base Game and Expansions
};
for _, sVersion in ipairs(tBaseFileVersions) do
  include(sVersion);
  if Initialize then break end
end
-- Build support for outer rings
include "BuildOnOuterRingsSupport.lua"



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- ICONS
local CITY_CENTER_DISTRICT_INDEX              = GameInfo.Districts["DISTRICT_CITY_CENTER"].Index;
-- PLOT INFO
local YIELD_NUMBER_VARIATION	                = "Yield_Variation_";
local YIELD_VARIATION_MANY		                = "Yield_Variation_Many";
local YIELD_VARIATION_MAP		:table = {
	YIELD_FOOD			  = "Yield_Food_",
	YIELD_PRODUCTION	= "Yield_Production_",
	YIELD_GOLD			  = "Yield_Gold_",
	YIELD_SCIENCE		  = "Yield_Science_",
	YIELD_CULTURE		  = "Yield_Culture_",
	YIELD_FAITH			  = "Yield_Faith_",
};



-- ===========================================================================
-- FUNCTIONS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoGetPlotYieldsWithWorkerCompensations
-- Get corrected yields for city center plot with yield bonuses.
-- ---------------------------------------------------------------------------
function CypWorPlotInfoGetPlotYieldsWithWorkerCompensations( iPlot : number, yields : table, tYieldSums : table )
  -- Get plot
	local pPlot = Map.GetPlotByIndex(iPlot);
  -- Set corrected yields
	for row in GameInfo.Yields() do
    -- Get plot yields
		local yieldAmt:number = pPlot:GetYield(row.Index);
    -- Apply plot bonuses
    local iYieldCompensationAmt:number = tYieldSums[row.Index];
    if iYieldCompensationAmt == nil then iYieldCompensationAmt = 0 end
    yieldAmt = yieldAmt - iYieldCompensationAmt;
    -- Determine info
		if yieldAmt > 0 then
			local clampedYieldAmount:number = yieldAmt > 5 and 5 or yieldAmt;
			local yieldType:string = YIELD_VARIATION_MAP[row.YieldType] .. clampedYieldAmount;
			local plots:table = yields[yieldType];
			if plots == nil then
				plots = { data = {}, variations = {}, yieldType=row.YieldType };
				yields[yieldType] = plots;
			end
			table.insert(plots.data, iPlot);
			-- Variations are used to overlay a number from 6 - 12 on top of largest yield icon (5)
			if yieldAmt > 5 then
				if yieldAmt > 11 then
					table.insert(plots.variations, { YIELD_VARIATION_MANY, iPlot });
				else
					table.insert(plots.variations, { YIELD_NUMBER_VARIATION .. yieldAmt, iPlot });
				end
			end
		end
	end
end



-- ===========================================================================
-- OVERRIDES
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CACHE ORIGINAL
-- ---------------------------------------------------------------------------
-- Plot yields
CypWorOriginal_GetPlotYields = GetPlotYields;

-- ---------------------------------------------------------------------------
-- GetPlotYields
-- Overwrites original PlotInfo.GetPlotYields function.
-- Account for worker compensation at city center.
-- ---------------------------------------------------------------------------
function GetPlotYields( iPlot : number, tYields : table)
  -- Get plot
	local pPlot = Map.GetPlotByIndex(iPlot);
  -- Check if is city center with worker compensations
  local tYieldSums = nil;
	local districtType = pPlot:GetDistrictType();
  if districtType == CITY_CENTER_DISTRICT_INDEX then
    tYieldSums = pPlot:GetProperty(CYP_WOR_PROPERTY_YIELDS_WITH_COMPENSATIONS);
  end
  -- Get yields
  if tYieldSums ~= nil then
    return CypWorPlotInfoGetPlotYieldsWithWorkerCompensations(iPlot, tYields, tYieldSums);
  else
    return CypWorOriginal_GetPlotYields(iPlot, tYields);
  end
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoRefreshFocus
-- Force refresh of city focus, that will also trigger city UI data refresh.
-- Currently unused.
-- ---------------------------------------------------------------------------
function CypWorPlotInfoRefreshFocus(pCity)
  local pCitizens = pCity:GetCitizens();
  local yieldType :number = YieldTypes.GOLD;
  local tParameters	:table = {};
	tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = yieldType;
  if pCitizens:IsFavoredYield(yieldType) then
	tParameters[CityCommandTypes.PARAM_FLAGS] = 0;
		tParameters[CityCommandTypes.PARAM_DATA0]= 1;
	elseif pCitizens:IsDisfavoredYield(yieldType) then
	tParameters[CityCommandTypes.PARAM_FLAGS] = 0;
		tParameters[CityCommandTypes.PARAM_DATA0] = 0;
	else
    tParameters[CityCommandTypes.PARAM_FLAGS]	= 1;
		tParameters[CityCommandTypes.PARAM_DATA0] = 0;
	end
	local result = CityManager.RequestCommand(pCity, CityCommandTypes.SET_FOCUS, tParameters);
end



-- ===========================================================================
-- EVENT CALLBACKS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoOuterRingSpecialistsChanged
-- ---------------------------------------------------------------------------
local function CypWorPlotInfoOuterRingSpecialistsChanged( tParameters : table )
  -- Get and validate city
  local pCity :table = UI.GetHeadSelectedCity();
  if pCity == nil then return end
  local iCity = pCity:GetID();
  if iCity ~= tParameters.iCity then return end
  -- Get and validate player
  local iPlayer = pCity:GetOwner();
  if iPlayer ~= tParameters.iPlayer or iPlayer ~= Game.GetLocalPlayer() then return end
  -- Refresh
  RefreshPurchasePlots();
  RefreshCitizenManagement();
  RefreshCityYieldsPlotList();
  -- Force refresh
  if tParameters.bForceFocusRefresh == true then
    CypWorPlotInfoRefreshFocus(pCity);
  end
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoInitialize
-- ---------------------------------------------------------------------------
local function CypWorPlotInfoInitialize()
  -- Register custom events
  LuaEvents.CypWorOuterRingSpecialistsChanged.Add( CypWorPlotInfoOuterRingSpecialistsChanged );
  -- Log init
  print("PlotInfo_CypWor.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorPlotInfoInitialize();