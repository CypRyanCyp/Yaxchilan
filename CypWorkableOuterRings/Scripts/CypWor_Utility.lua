-- ===========================================================================
-- Utility
-- ===========================================================================



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- District
CYP_WOR_DISTRICT_TYPE = 'DISTRICT_CYP_WOR';
CYP_WOR_DISTRICT_ID = nil;
local CYP_WOR_DISTRICT = GameInfo.Districts[CYP_WOR_DISTRICT_TYPE];
if CYP_WOR_DISTRICT ~= nil then
  CYP_WOR_DISTRICT_ID = CYP_WOR_DISTRICT.Index;
end
-- Building
CYP_WOR_BUILDING_A_TYPE = 'BUILDING_CYP_WOR_LOGISTICS_CENTER';
CYP_WOR_BUILDING_A_ID = nil;
local CYP_WOR_BUILDING_A = GameInfo.Buildings[CYP_WOR_BUILDING_A_TYPE];
if CYP_WOR_BUILDING_A ~= nil then
  CYP_WOR_BUILDING_A_ID = CYP_WOR_BUILDING_A.Index;
end
-- Internal building
CYP_WOR_BUILDING_TYPE = 'BUILDING_CYP_WOR';
CYP_WOR_BUILDING_ID = nil;
local CYP_WOR_BUILDING = GameInfo.Buildings[CYP_WOR_BUILDING_TYPE];
if CYP_WOR_BUILDING ~= nil then
  CYP_WOR_BUILDING_ID = CYP_WOR_BUILDING.Index;
end
-- Properties
CYP_WOR_PROPERTY_YIELDS_WITH_COMPENSATIONS = "CYP_WOR_YIELDS_WITH_COMPENSATION";
CYP_WOR_PROPERTY_YIELD_VALUES = "CYP_WOR_YIELDS";
CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA = "CYP_WOR_OUTER_RING_PLOTS_DATA";
CYP_WOR_PROPERTY_TOTAL_WORKABLE_OUTER_RING_PLOT_COUNT = "CYP_WOR_TOTAL_WORKABLE_OUTER_RING_TILE_COUNT";
CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS = "CYP_WOR_WORKER_LOCKED_OUTER_RING_PLOTS";
-- Configurations
CYP_WOR_DST_MIN = 4;
CYP_WOR_DST_MAX = 5;



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorDistrictExists
-- ---------------------------------------------------------------------------
function CypWorDistrictExists( pCity )
  if not pCity:GetDistricts():HasDistrict(CYP_WOR_DISTRICT_ID) then return false end
  local pDistrict = pCity:GetDistricts():GetDistrict(CYP_WOR_DISTRICT_ID);
  return pDistrict:IsComplete();
  
end

-- ---------------------------------------------------------------------------
-- CypWorDistrictPlotId
-- ---------------------------------------------------------------------------
function CypWorDistrictPlotId( pCity )
  local pDistrict = pCity:GetDistricts():GetDistrict(CYP_WOR_DISTRICT_ID);
  local iX = pDistrict:GetX();
  local iY = pDistrict:GetY();
  local pPlot = Map.GetPlot(iX, iY);
  local iPlot = pPlot:GetIndex();
  return iPlot, iX, iY;
end

-- ---------------------------------------------------------------------------
-- CypWorBuildingAExists
-- ---------------------------------------------------------------------------
function CypWorBuildingAExists( pCity )
  if not pCity:GetBuildings():HasBuilding(CYP_WOR_BUILDING_A_ID) then return false end
  return not pCity:GetBuildings():IsPillaged(CYP_WOR_BUILDING_A_ID);
end

-- ---------------------------------------------------------------------------
-- CypWorGetRingPlotsByDistanceAndOwner
-- Get plots in the nth ring of a city.
-- ---------------------------------------------------------------------------
function CypWorGetRingPlotsByDistanceAndOwner( iX : number, iY : number, iPlayer : number, iCity : number, iMinDistance : number, iMaxDistance : number, bExcludeCity )
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
-- CypWorReverseTable
-- ---------------------------------------------------------------------------
function CypWorReverseTable(t:table)
  local n = table.count(t);
  local reversedT :table = {};
  for i = 1, n do
    reversedT[i] = t[n]
    n = n - 1;
  end
  return reversedT;
end

-- ---------------------------------------------------------------------------
-- CypWorTableContains
-- ---------------------------------------------------------------------------
function CypWorTableContains( tTable, x )
  for _, v in pairs(tTable) do
    if v == x then return true end
  end
  return false;
end

-- ---------------------------------------------------------------------------
-- CypWorDecimalToBinaryArray
-- Convert decimal number to binary number represented in a array of 0 and 1.
-- ---------------------------------------------------------------------------
function CypWorDecimalToBinaryArray( decimal : number )
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
-- CypWorApplyPropertiesToPlotWithBinaryConvertedValue
-- Create desired properties determined by value that is to be 
-- converted to binary representation.
-- ---------------------------------------------------------------------------
function CypWorApplyPropertiesToPlotWithBinaryConvertedValue(
            iValue : number, 
            iMaxDigits : number, 
            sPropertyPrefix, 
            pPlot) 
  -- Check hash
  local sHashPropertyName = sPropertyPrefix .. 'HASH';
  local xHashProperty = pPlot:GetProperty(sHashPropertyName);
  if xHashProperty ~= nil and xHashProperty == iValue then return end
  -- Convert base10 to base2 (binary)
  local tValuesBinary = CypWorDecimalToBinaryArray(iValue);
  -- Reverse, so that we can loop from smallest digit (2^0) to largest digit (2^n)
  local tValuesBinaryReversed = CypWorReverseTable(tValuesBinary);
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