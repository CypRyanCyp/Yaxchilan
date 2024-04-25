-- ===========================================================================
-- PlotTooltip UI
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "CypWor_Utility.lua"
-- Original
local includeFileVersions = {
	"Suk_PlotTooltips.lua",
  "plottooltip_CQUI_expansion2.lua",
	"plottooltip_CQUI_basegame.lua",
  "PlotToolTip_Expansion2_BarbarianClansMode.lua",
  "PlotToolTip_BarbarianClansMode.lua",
  "PlotToolTip_BlackDeathScenario.lua",
  "PlotToolTip_PiratesScenario.lua",
	"PlotTooltip_Expansion2.lua",
	"PlotTooltip.lua",
}
for _,sVersion in ipairs(includeFileVersions) do
	include(sVersion)
	if Initialize or Initialize_PlotTooltip_CQUI or FetchData then break end
end



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- Invisible UI building types
local CYP_WOR_INVISIBLE_BUILDING_IDS : table = {};
local CYP_WOR_INVISIBLE_BUILDING_NAMES : table = {};
for row in GameInfo.CypWtUiInvisibleBuildings() do
  CYP_WOR_INVISIBLE_BUILDING_IDS[GameInfo.Buildings[row.BuildingType].Index] = true;
  CYP_WOR_INVISIBLE_BUILDING_NAMES[row.Name] = true;
end


-- ===========================================================================
-- PLOT TOOLTIP
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CACHE ORIGINAL
-- ---------------------------------------------------------------------------
CypWorOriginal_GetDetails = GetDetails;

-- ---------------------------------------------------------------------------
-- CypWorModifyDataHideInternalBuildings
-- Hide internal buildings.
-- ---------------------------------------------------------------------------
function CypWorModifyDataHideInternalBuildings( data : table )
  -- Remove invisible buildings from names
  local tRemoveBuildingNames = {};
  if data.BuildingNames ~= nil and table.count(data.BuildingNames) > 0 then
    for i, sBuildingName in pairs(data.BuildingNames) do
      if CYP_WOR_INVISIBLE_BUILDING_NAMES[sBuildingName] then
        tRemoveBuildingNames[i] = sBuildingName;
      end
    end
  end
  for i, v in pairs(tRemoveBuildingNames) do
    data.BuildingNames[i] = nil;
  end
  -- Remove invisible buildings from types
  local tRemoveBuildingTypes = {};
  if data.BuildingTypes ~= nil and table.count(data.BuildingTypes) > 0 then
    for i, sBuildingType in pairs(data.BuildingTypes) do
      if CYP_WOR_INVISIBLE_BUILDING_IDS[sBuildingType] then
        tRemoveBuildingTypes[i] = sBuildingType;
      end
    end
  end
  for i, v in pairs(tRemoveBuildingTypes) do
    data.BuildingTypes[i] = nil;
  end
end

-- ---------------------------------------------------------------------------
-- CypWorModifyDataWorSpecialists
-- Show outer ring worker yields as specialist yields.
-- ---------------------------------------------------------------------------
function CypWorModifyDataWorSpecialists(data)
  -- Check if is district
  if data.DistrictID == -1 or data.DistrictType == nil then return end
  -- Yields are not shown to other players -> nothing to modify
  if data.Owner == nil or data.Owner ~= Game.GetLocalPlayer() then return end
  -- Only if has workers
  if data.Workers == nil or data.Workers == 0 then return end
  -- Only if this is wor district
  if data.DistrictType ~= CYP_WOR_DISTRICT_TYPE then return end
  -- Clear yields
  data.Yields = {};
  data.DistrictYields = {};
  data.Workers = 0;
end

-- ---------------------------------------------------------------------------
-- CypWorModifyDataCityCenterYields
-- Remove negative outer ring worker compensation yields from city center plot.
-- ---------------------------------------------------------------------------
local function CypWorModifyDataCityCenterYields(data)
  -- Check if is city
  if not data.IsCity then return end
  -- Get plot
  local pPlot = Map.GetPlotByIndex(data.Index);
  if pPlot == nil then return end
  -- Try to get yields from property and validate that it is not empty
  local tYieldSums = pPlot:GetProperty(CYP_WOR_PROPERTY_YIELDS_WITH_COMPENSATIONS);
  if tYieldSums == nil then return end
  -- Add amount to negative compensation yield
  for dYield in GameInfo.Yields() do
    -- Get applied amount
    local iYield = dYield.Index;
    local sYieldType = dYield.YieldType;
    local iYieldAmount = pPlot:GetYield(iYield);
    if iYieldAmount == nil then iYieldAmount = 0 end
    -- Get compensation amount
    local iYieldCompensationAmt:number = tYieldSums[iYield];
    if iYieldCompensationAmt == nil then iYieldCompensationAmt = 0 end
    -- Combine
    iYieldAmount = iYieldAmount - iYieldCompensationAmt;
    if iYieldAmount == 0 then iYieldAmount = nil end
    -- Apply
    data.Yields[sYieldType] = iYieldAmount;
  end
end

-- ---------------------------------------------------------------------------
-- CypWorModifyDataWorkedOuterRingPlots
-- Set worker count for outer ring plots.
-- ---------------------------------------------------------------------------
local function CypWorModifyDataWorkedOuterRingPlots(data)
  -- Ignore city centers
  if data.IsCity then return end
  -- Ignore districts
  if data.DistrictID ~= -1 or data.DistrictType ~= nil then return end
  -- Ignore if not belongs to local player
  if data.Owner == nil or data.Owner ~= Game.GetLocalPlayer() then return end
  -- Ignore if already has worker assigned
  if data.Workers ~= nil and data.Workers > 1 then return end
  -- Get outer ring plot data
  local tOuterRingPlotsData : table = data.OwnerCity:GetProperty(CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA);
  if tOuterRingPlotsData == nil or table.count(tOuterRingPlotsData) == 0 then return end
  -- Check if plot is worked
  local xPlotData = tOuterRingPlotsData[data.Index];
  if xPlotData ~= nil and xPlotData.bIsWorked then
    -- Assign worker
    data.Workers = 1;
  end
end

-- ---------------------------------------------------------------------------
-- GetDetails
-- Overwrites original PlotToolTip.GetDetails function.
-- ---------------------------------------------------------------------------
function GetDetails( data )
  CypWorModifyDataWorkedOuterRingPlots(data);
  CypWorModifyDataCityCenterYields(data);
  CypWorModifyDataWorSpecialists(data);
  CypWorModifyDataHideInternalBuildings(data);
  return CypWorOriginal_GetDetails(data);
end

-- Log init
print("PlotToolTip_CypWor.lua initialized!");