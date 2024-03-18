-- ===========================================================================
-- Utility
-- ===========================================================================



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
YAXCHILAN_DISTRICT_TYPE = 'DISTRICT_YAXCHILAN';
YAXCHILAN_DISTRICT_ID = nil;
local YAXCHILAN_DISTRICT = GameInfo.Districts[YAXCHILAN_DISTRICT_TYPE];
if YAXCHILAN_DISTRICT ~= nil then
  YAXCHILAN_DISTRICT_ID = YAXCHILAN_DISTRICT.Index;
end
YAXCHILAN_BUILDING_TYPE = 'BUILDING_YAXCHILAN';
YAXCHILAN_BUILDING_ID = nil;
local YAXCHILAN_BUILDING = GameInfo.Buildings[YAXCHILAN_BUILDING_TYPE];
if YAXCHILAN_BUILDING ~= nil then
  YAXCHILAN_BUILDING_ID = YAXCHILAN_BUILDING.Index;
end
YAXCHILAN_PROPERTY_YIELDS_WITH_COMPENSATIONS = "YAXCHILAN_YIELDS_WITH_COMPENSATION";
YAXCHILAN_PROPERTY_YIELD_VALUES = "YAXCHILAN_YIELDS";
YAXCHILAN_PROPERTY_OUTER_RING_PLOTS_DATA = "YAXCHILAN_OUTER_RING_PLOTS_DATA";
YAXCHILAN_PROPERTY_TOTAL_WORKABLE_OUTER_RING_PLOT_COUNT = "YAXCHILAN_TOTAL_WORKABLE_OUTER_RING_TILE_COUNT";
YAXCHILAN_PROPERTY_LOCKED_OUTER_RING_PLOTS = "YAXCHILAN_WORKER_LOCKED_OUTER_RING_PLOTS";



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanGetRingPlotsByDistanceAndOwner
-- Get plots in the nth ring of a city.
-- ---------------------------------------------------------------------------
function YaxchilanGetRingPlotsByDistanceAndOwner( iX : number, iY : number, iPlayer : number, iCity : number, iMinDistance : number, iMaxDistance : number, bExcludeCity )
  local tPlots :table = {};
  -- Validate input
  if bWantOwnedByPlayerButNotCity == nil then bWantOwnedByPlayerButNotCity = false end
  if iMinDistance < 0 or iMaxDistance < 0 or iMinDistance > iMaxDistance then 
    return tPlots;
  end
  -- Determine range plots
  local tRangePlots = Map.GetNeighborPlots(iX, iY, iMaxDistance);
  -- Add plots with correct distance, only
  for _, pPlot in ipairs(tRangePlots) do
    -- Check if distance is correct
    local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), iX, iY);
    if iDistance >= iMinDistance and iDistance <= iMaxDistance then
      -- Check if working city is correct
      local pWorkingCity = Cities.GetPlotPurchaseCity(pPlot:GetIndex());
      local iWorkingCity = nil;
      if pWorkingCity ~= nil then 
        iWorkingCity = pWorkingCity:GetID();
      end
      -- Only consider plot if it is owned by specified player (or no player if iPlayer == -1)
      if iPlayer == pPlot:GetOwner() then
        -- If bExcludeCity is true that means that we want all plots that are owned by specified player
        -- but NOT owned by specified city. We do NOT want unowned plots, or plots owned by other players. Just plots
        -- that currently belong to another city of this player.
        if bExcludeCity then
          if iWorkingCity ~= nil and iWorkingCity ~= iCity then
            table.insert(tPlots, pPlot);
          end
        -- We want only plots that are owned by specified city (or no city if iCity == nil)
        else
          if iWorkingCity == iCity then
            table.insert(tPlots, pPlot);
          end
        end
      end
    end
  end
  -- Return
  return tPlots;
end

-- ---------------------------------------------------------------------------
-- YaxchilanReverseTable
-- ---------------------------------------------------------------------------
function YaxchilanReverseTable(t:table)
  local n = table.count(t);
  local reversedT :table = {};
  for i = 1, n do
    reversedT[i] = t[n]
    n = n - 1;
  end
  return reversedT;
end

-- ---------------------------------------------------------------------------
-- YaxchilanTableContains
-- ---------------------------------------------------------------------------
function YaxchilanTableContains( tTable, x )
  for _, v in pairs(tTable) do
    if v == x then return true end
  end
  return false;
end

-- ---------------------------------------------------------------------------
-- YaxchilanDecimalToBinaryArray
-- Convert decimal number to binary number represented in a array of 0 and 1.
-- ---------------------------------------------------------------------------
function YaxchilanDecimalToBinaryArray( decimal : number )
  if decimal < 0 then
    decimal = 0;
  end
  local tBinaryArray = {};
  repeat
    local remainder = decimal % 2;
    table.insert(tBinaryArray, 1, remainder);
    decimal = math.floor(decimal / 2);
  until decimal == 0
  return tBinaryArray;
end

-- ---------------------------------------------------------------------------
-- YaxchilanApplyPropertiesToPlotWithBinaryConvertedValue
-- Create desired properties determined by value that is to be 
-- converted to binary representation.
-- ---------------------------------------------------------------------------
function YaxchilanApplyPropertiesToPlotWithBinaryConvertedValue(
            iValue : number, 
            iMaxDigits : number, 
            sPropertyPrefix, 
            pPlot) 
  -- Check hash
  local sHashPropertyName = sPropertyPrefix .. 'HASH';
  local xHashProperty = pPlot:GetProperty(sHashPropertyName);
  if xHashProperty ~= nil and xHashProperty == iValue then return end
  -- Convert base10 to base2 (binary)
  local tValuesBinary = YaxchilanDecimalToBinaryArray(iValue);
  -- Reverse, so that we can loop from smallest digit (2^0) to largest digit (2^n)
  local tValuesBinaryReversed = YaxchilanReverseTable(tValuesBinary);
  -- Loop 
  for i = 1, iMaxDigits do
    local iValueBinaryDigit = tValuesBinaryReversed[i];
    if iValueBinaryDigit == nil then
      iValueBinaryDigit = 0;
    end
    -- Determine if desired and actual existence states match and...
    local iExpectedValue = iValueBinaryDigit;
    local sPropertyName = sPropertyPrefix .. i;
    pPlot:SetProperty(sPropertyName, iExpectedValue);
  end
  -- Set hash
  pPlot:SetProperty(sHashPropertyName, iValue);
end