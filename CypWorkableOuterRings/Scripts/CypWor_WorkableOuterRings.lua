-- ===========================================================================
-- Workable Outer Rings
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
include "SupportFunctions.lua";
include "CypWor_Utility.lua";



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- Buildings
local CYP_WOR_BUILDING_INTERNAL_WORKERS_TYPE_PREFIX = "BUILDING_CYP_WOR_INTERNAL_WORKERS_" -- example: BUILDING_CYP_WOR_INTERNAL_WORKERS_2
-- Plot yield score
local CYP_WOR_YIELD_SCORE_DEFAULT = 1;
local CYP_WOR_YIELD_SCORE_FAVORED = 4;
local CYP_WOR_YIELD_SCORE_DISFAVORED = 0;
local CYP_WOR_YIELD_BINARY_DIGITS = 11;
local CYP_WOR_WORKERS_BINARY_DIGITS = 7;
-- Specialist compensation yields
local CYP_WOR_SPECIALIST_COMPENSATION_YIELD_AMOUNT = 20;
-- Plot properties
local CYP_WOR_PROPERTY_YIELD_BONUS_PREFIX = "CYP_WOR_BONUS_";
local CYP_WOR_PROPERTY_YIELD_MALUS_PREFIX = "CYP_WOR_MALUS_";
local CYP_WOR_PROPERTY_YIELD_MALUS_AMOUNT = 1024;
-- City properties
local CYP_WOR_PROPERTY_YIELD_HASH = "CYP_WOR_YIELD_HASH";
local CYP_WOR_PROPERTY_WORKABLE_OUTER_RING_TILES = "CYP_WOR_WORKER_WORKABLE_OUTER_RING_TILES";
local CYP_WOR_PROPERTY_SPECIALIST_SLOT_COUNT = "CYP_WOR_SPECIALIST_SLOT_COUNT";



-- ===========================================================================
-- CACHES
-- ===========================================================================
-- Yields
local CYP_WOR_GAMEINFO_YIELD_INDEXES = {};
local CYP_WOR_GAMEINFO_YIELD_TYPES = {};
for pYield in GameInfo.Yields() do
  table.insert(CYP_WOR_GAMEINFO_YIELD_INDEXES, pYield.Index);
  CYP_WOR_GAMEINFO_YIELD_TYPES[pYield.Index] = pYield.YieldType;
end
-- Districts
local CYP_WOR_GAMEINFO_DISTRICTS = {};
local CYP_WOR_GAMEINFO_DISTRICTS_BY_TYPES = {};
for tDistrict in GameInfo.Districts() do
  CYP_WOR_GAMEINFO_DISTRICTS[tDistrict.Index] = tDistrict;
  CYP_WOR_GAMEINFO_DISTRICTS_BY_TYPES[tDistrict.DistrictType] = tDistrict;
end
-- Buildings
local CYP_WOR_GAMEINFO_BUILDINGS = {};
local CYP_WOR_GAMEINFO_BUILDINGS_BY_TYPES = {};
for tBuilding in GameInfo.Buildings() do
  CYP_WOR_GAMEINFO_BUILDINGS[tBuilding.Index] = tBuilding;
  CYP_WOR_GAMEINFO_BUILDINGS_BY_TYPES[tBuilding.BuildingType] = tBuilding;
end
-- Improvements
local CYP_WOR_GAMEINFO_IMPROVEMENTS = {};
for tItem in GameInfo.Improvements() do
  CYP_WOR_GAMEINFO_IMPROVEMENTS[tItem.Index] = tItem;
end
-- City plot cached yields
local m_CypWorCachedPlotYields = {};
local m_CypWorCachedCityLockedPlots = {};
-- Properties
local m_CypWorCachedPlotProperties = {};
local m_CypWorCachedCityProperties = {};



-- ===========================================================================
-- MEMBERS
-- ===========================================================================
-- City plot yields changed
local m_CypWorCityChangedPlotYields = {};
-- Currently updating cities
local m_CypWorCityIsUpdatingSpecialists = {};



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorSetCityProperty
-- ---------------------------------------------------------------------------
function CypWorSetCityProperty( pCity, xKey, xValue )
  -- Set value
  pCity:SetProperty(xKey, xValue);
  -- Update cache
  m_CypWorCachedCityProperties[pCity:GetID()][xKey] = xValue;
end

-- ---------------------------------------------------------------------------
-- CypWorGetCityProperty
-- ---------------------------------------------------------------------------
function CypWorGetCityProperty( pCity, xKey )
  -- Get city
  if pCity == nil then return nil end
  local iCity = pCity:GetID();
  -- Update cache
  if m_CypWorCachedCityProperties[iCity] == nil or m_CypWorCachedCityProperties[iCity][xKey] == nil then
    if m_CypWorCachedCityProperties[iCity] == nil then
      m_CypWorCachedCityProperties[iCity] = {};
    end
    m_CypWorCachedCityProperties[iCity][xKey] = pCity:GetProperty(xKey);
  end
  -- Return
  return m_CypWorCachedCityProperties[iCity][xKey];
end

-- ---------------------------------------------------------------------------
-- CypWorSetPlotProperty
-- ---------------------------------------------------------------------------
function CypWorSetPlotProperty( pPlot, xKey, xValue )
  -- Set value
  pPlot:SetProperty(xKey, xValue);
  -- Update cache
  m_CypWorCachedPlotProperties[pPlot:GetIndex()][xKey] = xValue;
end

-- ---------------------------------------------------------------------------
-- CypWorGetPlotProperty
-- ---------------------------------------------------------------------------
function CypWorGetPlotProperty( iPlot : number, xKey )
  -- Update cache
  if m_CypWorCachedPlotProperties[iPlot] == nil or m_CypWorCachedPlotProperties[iPlot][xKey] == nil then
    if m_CypWorCachedPlotProperties[iPlot] == nil then
      m_CypWorCachedPlotProperties[iPlot] = {};
    end
    local pPlot = Map.GetPlotByIndex(iPlot);
    local xValue = nil;
    if pPlot ~= nil then 
      xValue = pPlot:GetProperty(xKey);
    end
    m_CypWorCachedPlotProperties[iPlot][xKey] = xValue;
  end
  -- Return
  return m_CypWorCachedPlotProperties[iPlot][xKey];
end

-- ---------------------------------------------------------------------------
-- CypWorGetCityRingPlots
-- Get plots in the nth ring of a city.
-- ---------------------------------------------------------------------------
function CypWorGetCityLockedPlots( iPlayer : number, iCity : number )
  -- Update cache
  if m_CypWorCachedCityLockedPlots[iCity] == nil then
    -- Get player
    local pPlayer = Players[iPlayer];
    if pPlayer == nil then 
      return {},0;
    end
    -- Get city
    local pCity = pPlayer:GetCities():FindID(iCity);
    if pCity == nil then 
      return {},0; 
    end
    -- Get locked plots
    m_CypWorCachedCityLockedPlots[iCity] = ExposedMembers.CypWor.CityGetLockedPlots(iPlayer, iCity);
  end
  -- Count
  local iCityLockedCount = 0;
  for iPlot, iLockedCount in pairs(m_CypWorCachedCityLockedPlots[iCity]) do
    iCityLockedCount = iCityLockedCount + iLockedCount;
  end
  -- Return
  return m_CypWorCachedCityLockedPlots[iCity], iCityLockedCount;
end

-- ---------------------------------------------------------------------------
-- CypWorGetCityRingPlots
-- Get plots in the nth ring of a city.
-- ---------------------------------------------------------------------------
function CypWorGetCityRingPlots(pCity, iMin : number, iMax : number)
  -- Validate city
  if pCity == nil then return {} end
  -- Get plots
  return CypWorGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), pCity:GetOwner(), pCity:GetID(), iMin, iMax);
end

-- ---------------------------------------------------------------------------
-- CypWorUpdatePlotYieldCache
-- ---------------------------------------------------------------------------
function CypWorUpdatePlotYieldCache( iPlot : number, bForce )
  -- Clear cache
  if bForce == true then
    m_CypWorCachedPlotYields[iPlot] = nil;
  end
  -- Check cache
  if m_CypWorCachedPlotYields[iPlot] ~= nil then return end
  -- Update cache
  local pPlot = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return end
  for _,iYield ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
    m_CypWorCachedPlotYields[iPlot][iYield] = pPlot:GetYield(iYield);
  end
end

-- ---------------------------------------------------------------------------
-- CypWorDeterminePlotHasAnyYield
-- Determine if this plot has any yield.
-- ---------------------------------------------------------------------------
function CypWorDeterminePlotHasAnyYield(pPlot)
  -- Get plot
  if pPlot == nil then return false end
  local iPlot = pPlot:GetIndex();
  -- Update cache
  CypWorUpdatePlotYieldCache(iPlot);
  -- Check if has any yields
  for _,iYield ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
    if m_CypWorCachedPlotYields[iPlot][iYield] > 0 then return true end
  end
  return false
end

-- ---------------------------------------------------------------------------
--	CypWorPlotIsWorkable
--  Determine if plot can be worked.
-- ---------------------------------------------------------------------------
function CypWorPlotIsWorkable(pPlot)
  -- Check wonder (not workable)
  if pPlot:GetWonderType() ~= -1 then return false end
  -- Check improvement (not workable)
  local iImprovement = pPlot:GetImprovementType();
  if iImprovement ~= -1 then
    local pImprovement = CYP_WOR_GAMEINFO_IMPROVEMENTS[iImprovement];
    if not pImprovement.Workable then return false end
  end
  -- Check feature (danger value)
  local pFeature = pPlot:GetFeature();
  if pFeature ~= nil then
    if pFeature.DangerValue ~= nil and pFeature.DangerValue > 0 then return false end
  end
  -- Check has any yields
  if not CypWorDeterminePlotHasAnyYield(pPlot) then return false end
  -- Check disasters
  if CypWorHasXp2() and (GameClimate.GetActiveDroughtAtPlot(pPlot) ~= nil 
  or GameClimate.GetActiveStormAtPlot(pPlot) ~= nil) then return false end
  -- Workable
  return true;
end

-- ---------------------------------------------------------------------------
--	CypWorGetPlotWorkerSlots
--  Determine amount of available worker slots.
-- ---------------------------------------------------------------------------
function CypWorGetPlotWorkerSlots(pCity, pPlot)
  -- District tile
  if pPlot:GetDistrictType() ~= -1 then
    local iWorkerSlots = 0;
    -- District specialist slots
    local tDistrict = CYP_WOR_GAMEINFO_DISTRICTS[pPlot:GetDistrictType()];
    local iDistrictCitizenSlots = CYP_WOR_GAMEINFO_DISTRICTS[pPlot:GetDistrictType()].CitizenSlots;
    if iDistrictCitizenSlots == nil then iDistrictCitizenSlots = 0 end
    iWorkerSlots = iWorkerSlots + iDistrictCitizenSlots;
    -- Building specialist slots
    for _,tBuilding in pairs(CYP_WOR_GAMEINFO_BUILDINGS_BY_TYPES) do
      if tBuilding.PrereqDistrict == tDistrict.DistrictType and tBuilding.CitizenSlots ~= nil then
        iWorkerSlots = iWorkerSlots + tBuilding.CitizenSlots;
      end
    end
  -- Normal tile
  elseif CypWorPlotIsWorkable(pPlot) then
    return 1;
  end
  return 0;
end

-- ---------------------------------------------------------------------------
-- CypWorCreateDummyBuildingWithBinaryConvertedValue
-- Create desired dummy buildings determined by value that is to be converted
-- to binary representation.
-- ---------------------------------------------------------------------------
function CypWorCreateDummyBuildingWithBinaryConvertedValue(
            iValue : number, 
            iMaxDigits : number, 
            sBuildingTypePrefix, 
            pCity, 
            pBuildingPlotIndex) 
  -- Hash is handled before thi
  -- Convert base10 to base2 (binary)
  local tValueBinary = CypWorDecimalToBinaryArray(iValue);
  -- Reverse, so that we can loop from smallest digit (2^0) to largest digit (2^n)
  local tValueBinaryReversed = CypWorReverseTable(tValueBinary);
  -- Loop twice: first add then remove buildings so that assigned
  -- specialists won't be removed due to temporary missing slots
  for iAdd = 1, 0, -1 do
    for i = 1, iMaxDigits do
      local iValueBinaryDigit = tValueBinaryReversed[i];
      if iValueBinaryDigit == nil then
        iValueBinaryDigit = 0;
      end
      -- Only execute add or remove when we are in the correct loop (add or remove)
      if iValueBinaryDigit == iAdd then
        -- Determine if desired and actual existence states match and...
        local bBuildingShouldExist = iValueBinaryDigit == 1;
        local sBuildingType = sBuildingTypePrefix .. i;
        local iBuilding = CYP_WOR_GAMEINFO_BUILDINGS_BY_TYPES[sBuildingType].Index;
        local bBuildingExists = pCity:GetBuildings():HasBuilding(iBuilding);
        -- ... if not setup desired state
        if bBuildingShouldExist ~= bBuildingExists then
          if bBuildingExists then -- Remove building if exists
            pCity:GetBuildings():RemoveBuilding(iBuilding);
          else -- Add building if not exists
            pCity:GetBuildQueue():CreateIncompleteBuilding(iBuilding, pBuildingPlotIndex, 100);
          end
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- CypWorDeterminePlotScore
-- Determine score of plot considering Multipliers.
-- A plot score is the sum of weighted yield type sums.
-- ---------------------------------------------------------------------------
function CypWorDeterminePlotScore( pPlot, tYieldMultipliers :table )
  -- Get plot
  if pPlot == nil then return 0 end
  local iPlot = pPlot:GetIndex();
  -- Update cache
  CypWorUpdatePlotYieldCache(iPlot);
  -- Determine score
  local iScore = 0;
  for _,iYield ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
    iScore = iScore + m_CypWorCachedPlotYields[iPlot][iYield] * tYieldMultipliers[iYield];
  end
  return iScore;
end

-- ---------------------------------------------------------------------------
-- CypWorCitizenYieldFavorMultiplier
-- Determine yield multiplier/weight based on citizen favor.
-- This determines how much the amount of yields of a certain type is weighted.
-- ---------------------------------------------------------------------------
function CypWorCitizenYieldFavorMultiplier( pCitizens, iYield : number )
  if pCitizens:IsYieldFavored(iYield) then
    return CYP_WOR_YIELD_SCORE_FAVORED;
  elseif pCitizens:IsYieldDisfavored(iYield) then
    return CYP_WOR_YIELD_SCORE_DISFAVORED;
  else
    return CYP_WOR_YIELD_SCORE_DEFAULT;
  end
end



-- ===========================================================================
-- FUNCTIONS (LOGIC)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorRefreshWorkerYields
-- ---------------------------------------------------------------------------
function CypWorRefreshWorkerYields( iPlayer : number, iCity : number, iCypWorPlot : number, iCypWorWorkerCount : number, bForceFocusRefresh )
  
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  
  -- Get city plot
  local pCityPlot = pCity:GetPlot();
  if pCityPlot == nil then return end
  
  -- Get assigned specialists
  local pCypWorPlot = Map.GetPlotByIndex(iCypWorPlot);
  if iCypWorWorkerCount == nil or iCypWorWorkerCount < 0 then
    iCypWorWorkerCount = pCypWorPlot:GetWorkerCount();
  end
  
  -- Prepare yield sum
  local tYieldSums = {};
  for _,iYield ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
    tYieldSums[iYield] = 0;
  end
  
  -- Determine to be worked outer ring plots
  -- Get n best workable outer ring tiles, while n is the amount of specialists
  local tWorkableOuterPlotData : table = CypWorGetCityProperty(pCity, CYP_WOR_PROPERTY_WORKABLE_OUTER_RING_TILES);
  local iAssignedDistrictWorkerCount = 0;
  local tOuterRingPlotsData = {};
  for _, xOuterRingPlotInfo in ipairs(tWorkableOuterPlotData) do
    -- Set data
    local xPlotData = {};
    xPlotData.bIsWorked = iAssignedDistrictWorkerCount < iCypWorWorkerCount;
    xPlotData.iPlot = xOuterRingPlotInfo.iPlot;
    xPlotData.bIsLocked = xOuterRingPlotInfo.bIsLocked;
    tOuterRingPlotsData[xPlotData.iPlot] = xPlotData;
    -- Count yield sum and assigned
    if xPlotData.bIsWorked then 
      iAssignedDistrictWorkerCount = iAssignedDistrictWorkerCount + 1;
      for _,iYield ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
        tYieldSums[iYield] = tYieldSums[iYield] + m_CypWorCachedPlotYields[xOuterRingPlotInfo.iPlot][iYield];
      end
    end
  end
  
  -- Store properties
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_YIELD_VALUES, tYieldSums);
  -- Compensate ingame specialist yields and set property
  for _,iYield ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
    tYieldSums[iYield] = tYieldSums[iYield] - (iCypWorWorkerCount * CYP_WOR_SPECIALIST_COMPENSATION_YIELD_AMOUNT);
  end
  CypWorSetPlotProperty(pCityPlot, CYP_WOR_PROPERTY_YIELDS_WITH_COMPENSATIONS, tYieldSums);
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA, tOuterRingPlotsData);

  -- Check hash (determines if desired yields already applied)
  local sCityOuterRingYieldHash = '|';
  for _,iYield ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
    sCityOuterRingYieldHash = sCityOuterRingYieldHash .. tYieldSums[iYield] .. '|';
  end
  local sStoredHash = CypWorGetCityProperty(pCity, CYP_WOR_PROPERTY_YIELD_HASH);
  if sStoredHash ~= sCityOuterRingYieldHash then
    -- Force focus refresh
    if not bForceFocusRefresh then bForceFocusRefresh = true end
    -- Store hash
    CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_YIELD_HASH, sCityOuterRingYieldHash);
    -- Apply yield properties to add worked plot yields
    for iYield, iYieldAmount in pairs(tYieldSums) do
      -- Get yield type
      local sYieldType = CYP_WOR_GAMEINFO_YIELD_TYPES[iYield];
      -- Handle negative yield part
      local sNegativeYieldPropertyName = CYP_WOR_PROPERTY_YIELD_MALUS_PREFIX .. sYieldType;
      local iNegativeYield = 0;
      if iYieldAmount < 0 then
        iNegativeYield = 1;
        iYieldAmount = CYP_WOR_PROPERTY_YIELD_MALUS_AMOUNT + iYieldAmount;
      end
      pCityPlot:SetProperty(sNegativeYieldPropertyName, iNegativeYield);
      -- Handle positive yield part
      CypWorApplyPropertiesToPlotWithBinaryConvertedValue(
          iYieldAmount, 
          CYP_WOR_YIELD_BINARY_DIGITS, 
          CYP_WOR_PROPERTY_YIELD_BONUS_PREFIX .. sYieldType .. "_",
          pCityPlot);
    end
  end
  
  -- Soft refresh by resetting city name
  pCity:SetName(pCity:GetName());
  
  -- Notify event outer ring workers changed
  local tParameters = {};
  tParameters.iPlayer = iPlayer;
  tParameters.iCity = iCity;
  tParameters.iWantedOuterRingWorkers = iWantedOuterRingWorkers;
  tParameters.bForceFocusRefresh = bForceFocusRefresh;
  ReportingEvents.SendLuaEvent("CypWorOuterRingSpecialistsChanged", tParameters);
end

-- ---------------------------------------------------------------------------
-- CypWorDetermineAutoAssignedOuterRingWorkers
-- ---------------------------------------------------------------------------
function CypWorDetermineAutoAssignedOuterRingWorkers( pCity, iCypWorPlot : number, tCityLockedPlots : table, tCityLockedOuterRingPlots : table )

  -- Determine yield multipliers (depends on city yield favor)
  local pCitizens = pCity:GetCitizens();
  local tYieldMultipliers = {};
  for _,iYield ipairs(CYP_WOR_GAMEINFO_YIELD_INDEXES) do
    tYieldMultipliers[iYield] = CypWorCitizenYieldFavorMultiplier(pCitizens, iYield);
  end
  
  -- Determine maximum ring
  local iWorMaxRange = CYP_WOR_DST_MIN;
  if CypWorBuildingAExists(pCity) then
    iWorMaxRange = CYP_WOR_DST_MAX;
  end
  
  -- Determine all city tiles with scores (include inner and outer rings)
  local tCityPlots : table = {};
  local iCityPlot = pCity:GetPlot():GetIndex();
  for _, pPlot in pairs(CypWorGetCityRingPlots(pCity, 1, iWorMaxRange)) do
    -- Ignore WOR district
    local iPlot = pPlot:GetIndex();
    if iPlot ~= iCypWorPlot and iPlot ~= iCityPlot then
      -- Store info
      local xPlotInfo = {};
      xPlotInfo.iPlot = iPlot;
      xPlotInfo.pPlot = pPlot;
      -- Determine score
      xPlotInfo.iScore = 0;
      local iPlotWorkerSlots = CypWorGetPlotWorkerSlots(pCity, pPlot); -- Also checks if plot is workable
      if iPlotWorkerSlots > 0 then
        xPlotInfo.iScore = CypWorDeterminePlotScore(pPlot, tYieldMultipliers);
      end
      -- Determine if is inner ring
      xPlotInfo.bIsInnerRing = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY()) <= 3;
      -- Determine if is locked
      xPlotInfo.bIsLocked = false;
      if xPlotInfo.bIsInnerRing then
        xPlotInfo.bIsLocked = tCityLockedPlots[iPlot] ~= nil;
        -- If inner ring plot is locked we count exactly the amount of current workers (specialists)
        if xPlotInfo.bIsLocked then
          iPlotWorkerSlots = pPlot:GetWorkerCount();
        end
      else
        xPlotInfo.bIsLocked = tCityLockedOuterRingPlots[iPlot] == true;
      end
      -- Insert n times, while n = amount of available worker slots
      if iPlotWorkerSlots > 0 then
        for i = 1, iPlotWorkerSlots, 1 do
          table.insert(tCityPlots, xPlotInfo);
        end
      end
    end
  end
  
  -- Order all city tiles by bIsLocked.DESC, iScore.DESC, bIsInnerRing.DESC
  table.sort(tCityPlots, function(xPlotInfoA, xPlotInfoB)
    -- Handle nil
    if xPlotInfoA == nil then return false end
    if xPlotInfoB == nil then return false end
    -- Sort by bIsLocked.DESC first
    if xPlotInfoA.bIsLocked ~= xPlotInfoB.bIsLocked then
      return xPlotInfoA.bIsLocked;
    end
    -- Sort by iScore.DESC second
    if xPlotInfoA.iScore ~= xPlotInfoB.iScore then
      return xPlotInfoA.iScore > xPlotInfoB.iScore;
    end
    -- Prefer inner ring
    if xPlotInfoA.bIsInnerRing ~= xPlotInfoB.bIsInnerRing then
      return xPlotInfoA.bIsInnerRing;
    end
    -- Fallback order by plot id
    return xPlotInfoA.iPlot < xPlotInfoB.iPlot;
  end);
  
  -- Determine available worker count
  local iTotalAvailableWorkerCount = pCity:GetPopulation();
  
  -- Determine amount of wanted outer ring workers.
  -- Therefore take the n best plots, while n = available worker count
  -- and count the amount of outer ring plots.
  local iTotalPlannedWorkers = 0;
  local iTotalPlannedOuterRingWorkers = 0;
  local tWorkableOuterPlotData = {};
  for _, xPlotInfo in pairs(tCityPlots) do
    local bWorked = false;
    -- Add best tiles, one for each worker
    if iTotalPlannedWorkers < iTotalAvailableWorkerCount then 
      if not xPlotInfo.bIsInnerRing then
        --table.insert(tOuterRingTiles, xPlotInfo.pPlot:GetIndex()); -- automatically inserted in iScore.DESC order
        --tOuterRingTiles[iTotalPlannedOuterRingWorkers] = xPlotInfo.iPlot;
        iTotalPlannedOuterRingWorkers = iTotalPlannedOuterRingWorkers + 1;
      end
      iTotalPlannedWorkers = iTotalPlannedWorkers + 1;
      bWorked = true;
    end
    -- Add to list of all outer ring tiles
    
    if not xPlotInfo.bIsInnerRing then
      -- Store info
      local xOuterRingPlotInfo = {};
      xOuterRingPlotInfo.iPlot = xPlotInfo.iPlot;
      xOuterRingPlotInfo.bIsLocked = xPlotInfo.bIsLocked;
      table.insert(tWorkableOuterPlotData, xOuterRingPlotInfo);
    end
  end
  
  -- Return
  return tWorkableOuterPlotData, iTotalPlannedOuterRingWorkers;
end

-- ---------------------------------------------------------------------------
-- CypWorRefreshCityWorWorkerSlots
-- ---------------------------------------------------------------------------
function CypWorRefreshCityWorWorkerSlots( iPlayer : number, iCity : number, bForceFocusRefresh )

  -- Remove from list
  m_CypWorCityChangedPlotYields[iCity] = nil;

  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  
  -- Validate city has WOR district
  if not CypWorDistrictExists(pCity) then return end
  local iCypWorPlot = CypWorDistrictPlotId(pCity);
  
  -- Prepare
  local iOuterRingTileSpecialistSlots = 0;
  local tWorkableOuterPlotData = {};
  local iWorkableOuterRingTilesCountPropertyValue = nil;
  
  -- Check WOR pillaged state
  local bCypWorIsPillaged = pCity:GetDistricts():GetDistrict(CYP_WOR_DISTRICT_ID):IsPillaged();
  
  -- Remove all specialist slots when pillaged
  if not bCypWorIsPillaged then
    
    -- Determine locked plots
    local tCityLockedPlots, iCityLockedCount = CypWorGetCityLockedPlots(iPlayer, iCity);
    local tCityLockedOuterRingPlots = CypWorGetCityProperty(pCity, CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS);
    if tCityLockedOuterRingPlots == nil then tCityLockedOuterRingPlots = {} end
    
    -- Correct too high amount of locked outer ring plots
    -- This can happen when population shrinks
    local iLockedOuterRingPlots = table.count(tCityLockedOuterRingPlots);
    if iLockedOuterRingPlots > 0 then
      local iTotalLockedPlots = iCityLockedCount + iLockedOuterRingPlots;
      local iTotalAvailableWorkerCount = pCity:GetPopulation();
      if iTotalLockedPlots > iTotalAvailableWorkerCount then
        local iDeltaLockedOuterRingPlots = math.min(iLockedOuterRingPlots, iTotalLockedPlots - iTotalAvailableWorkerCount);
        local tCorrectedCityLockedOuterRingPlots = {};
        for iPlot, bIsLocked in pairs(tCityLockedOuterRingPlots) do
          if bIsLocked then
            if iDeltaLockedOuterRingPlots > 0 then
              iDeltaLockedOuterRingPlots = iDeltaLockedOuterRingPlots - 1;
            else
              tCorrectedCityLockedOuterRingPlots[iPlot] = true;
            end
          end          
        end
        tCityLockedOuterRingPlots = tCorrectedCityLockedOuterRingPlots;
        CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS, tCityLockedOuterRingPlots);
      end
    end
    
    -- Add one specialist slot for each workable outer ring tile that should be worked (city AI)
    -- Auto assigned tiles are workable only (for the game)
    tWorkableOuterPlotData, iOuterRingTileSpecialistSlots = CypWorDetermineAutoAssignedOuterRingWorkers(pCity, iCypWorPlot, tCityLockedPlots, tCityLockedOuterRingPlots);
  end
  
  -- Store amount of actual workable outer ring tiles (used in UI)
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_WORKABLE_OUTER_RING_TILES, tWorkableOuterPlotData);
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_TOTAL_WORKABLE_OUTER_RING_PLOT_COUNT, table.count(tWorkableOuterPlotData));
  -- Check if to be worked outer ring tiles count has changed
  local iPropertyStoredCount = CypWorGetCityProperty(pCity, CYP_WOR_PROPERTY_SPECIALIST_SLOT_COUNT);
  -- Always update, caching worker count leads to bugs
  if iPropertyStoredCount ~= iOuterRingTileSpecialistSlots then
    -- Force focus refresh
    if not bForceFocusRefresh then bForceFocusRefresh = true end
    -- Store cache
    CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_SPECIALIST_SLOT_COUNT, iOuterRingTileSpecialistSlots);
    --- Apply amount of specialist slots (if worked count changed)
    m_CypWorCityIsUpdatingSpecialists[iCity] = true;
    CypWorCreateDummyBuildingWithBinaryConvertedValue(
        iOuterRingTileSpecialistSlots, 
        CYP_WOR_WORKERS_BINARY_DIGITS, 
        CYP_WOR_BUILDING_INTERNAL_WORKERS_TYPE_PREFIX,
        pCity,
        iCypWorPlot);
    m_CypWorCityIsUpdatingSpecialists[iCity] = false;
  end
  
  -- Update yields
  CypWorRefreshWorkerYields(iPlayer, iCity, iCypWorPlot, iOuterRingTileSpecialistSlots, bForceFocusRefresh);
end

-- ---------------------------------------------------------------------------
-- CypWorCleanupProperties
-- ---------------------------------------------------------------------------
function CypWorCleanupProperties( iPlayer : number, iCity : number )
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Clear properties
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_WORKABLE_OUTER_RING_TILES, nil);
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_SPECIALIST_SLOT_COUNT, nil);
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_TOTAL_WORKABLE_OUTER_RING_PLOT_COUNT, nil);
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA, nil);
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_YIELD_HASH, nil);
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_YIELD_VALUES, nil);
  pCity:GetPlot():SetProperty(CYP_WOR_PROPERTY_YIELDS_WITH_COMPENSATIONS, nil);
  -- Clear caches
  m_CypWorCachedCityLockedPlots[iCity] = nil;
end



-- ===========================================================================
-- EVENT CALLBACKS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorOnMapYieldsChanged
-- ---------------------------------------------------------------------------
local function CypWorOnMapYieldsChanged( iPlayer : number)
  if iPlayer == nil then iPlayer = -1 end
  for iCity, iCityOwnerPlayer in pairs(m_CypWorCityChangedPlotYields) do
    if iCityOwnerPlayer ~= nil then
      if iPlayer == -1 or iPlayer == iCityOwnerPlayer then
        CypWorRefreshCityWorWorkerSlots(iCityOwnerPlayer, iCity, false);
      end
    end
  end
  -- Make sure list is cleared after
  if iPlayer == -1 then
    m_CypWorCityChangedPlotYields = {};
  end
end

-- ---------------------------------------------------------------------------
-- CypWorOnPlotYieldChanged
-- Add to list of changed cities that will be processed in CypWorOnMapYieldsChanged.
-- ---------------------------------------------------------------------------
local function CypWorOnPlotYieldChanged(iX : number, iY : number)
  -- Get city
  local pCity = Cities.GetPlotWorkingCity(iX, iY);
  if pCity == nil then return end
  -- Ignore city center
  if iX == pCity:GetX() and iY == pCity:GetY() then return end
  -- Validate city has WOR district
  if not CypWorDistrictExists(pCity) then return end
  -- Get plot
  local pPlot = Map.GetPlot(iX, iY);
  if pPlot == nil then return end
  local iPlot = pPlot:GetIndex();
  -- Get city and player ID
  local iCity = pCity:GetID();
  local iPlayer = pCity:GetOwner();
  -- Update cached yields
  CypWorUpdatePlotYieldCache(iPlot, true);
  -- Register plot city for updated cache
  m_CypWorCityChangedPlotYields[iCity] = iPlayer;
end

-- ---------------------------------------------------------------------------
-- CypWorOnPlayerTurnActivated
-- ---------------------------------------------------------------------------
local function CypWorOnPlayerTurnActivated( iPlayer : number )
  -- Update all changed yields on any turn activation
  CypWorOnMapYieldsChanged(iPlayer);
end

-- ---------------------------------------------------------------------------
-- CypWorOnCityTileOwnershipChanged
-- New tiles can shift inner/outer ring worker distribution.
-- ---------------------------------------------------------------------------
local function CypWorOnCityTileOwnershipChanged(iPlayer : number, iCity : number, iX : number, iY : number)
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- CypWorOnCityFocusChanged
-- Recalculate all slots, since plot score depends on city focus.
-- Changing focus can shift inner/outer ring worker distribution.
-- ---------------------------------------------------------------------------
local function CypWorOnCityFocusChanged(iPlayer : number, iCity : number)
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- CypWorOnDistrictBuildProgressChanged
-- ---------------------------------------------------------------------------
local function CypWorOnDistrictBuildProgressChanged(
                iPlayer : number, 
                iDistrict : number, 
                iCity : number, 
                iX : number, 
                iY : number, 
                iDistrictType : number, 
                iEra : number,
                iCiv : number,
                iPercent : number)
  -- Only when WOR has been built
  if iDistrictType ~= CYP_WOR_DISTRICT_ID then return end
  -- Only when finished
  if iPercent < 100 then return end
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Get plot
  local pCypWorPlot = Map.GetPlot(iX, iY);
  if pCypWorPlot == nil then return end
  local iCypWorPlot = pCypWorPlot:GetIndex();
  -- Place internal specialist yield building
  if not pCity:GetBuildings():HasBuilding(CYP_WOR_BUILDING_ID) then
    pCity:GetBuildQueue():CreateIncompleteBuilding(CYP_WOR_BUILDING_ID, iCypWorPlot, 100);
  end
  -- Update worker slots
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, true);
end

-- ---------------------------------------------------------------------------
-- CypWorOnBuildingAddedToMap
-- ---------------------------------------------------------------------------
local function CypWorOnBuildingAddedToMap( iX : number, iY : number, iBuilding : number, iPlayer : number )
  -- Validate is building A
  if iBuilding ~= CYP_WOR_BUILDING_A_ID then return end
  -- Get city
  local pCity = Cities.GetPlotWorkingCity(iX, iY);
  if pCity == nil then return end
  local iCity = pCity:GetID();
  -- Update worker slots
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, true);
end

-- ---------------------------------------------------------------------------
-- CypWorOnBuildingConstructed
-- ---------------------------------------------------------------------------
local function CypWorOnBuildingConstructed( iPlayer : number, iCity : number, iBuilding : number )
  -- Validate is building A
  if iBuilding ~= CYP_WOR_BUILDING_A_ID then return end
  -- Update worker slots
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, true);
end

-- ---------------------------------------------------------------------------
-- CypWorOnCityWorkerChanged
-- ---------------------------------------------------------------------------
local function CypWorOnCityWorkerChanged( iPlayer : number, iCity : number, iX : number, iY : number )
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Validate city has WOR district
  if not CypWorDistrictExists(pCity) then return end
  local iCypWorPlot = CypWorDistrictPlotId(pCity);
  -- Validate not currently updating specialists
  if m_CypWorCityIsUpdatingSpecialists[iCity] then return end
  -- Refresh yields
  CypWorRefreshWorkerYields(iPlayer, iCity, iCypWorPlot, nil, false);
end

-- ---------------------------------------------------------------------------
-- CypWorOnCityTransfered
-- ---------------------------------------------------------------------------
local function CypWorOnCityTransfered( iPlayer : number, iCity : number, iOldPlayer : number, xTransferType )
  CypWorCleanupProperties(iPlayer, iCity);
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- CypWorOnCityInitialized
-- ---------------------------------------------------------------------------
local function CypWorOnCityInitialized( iPlayer : number, iCity : number, iX : number, iY : number )
  CypWorCleanupProperties(iPlayer, iCity);
end

-- ---------------------------------------------------------------------------
-- CypWorOnDistrictRemovedFromMap
-- ---------------------------------------------------------------------------
local function CypWorOnDistrictRemovedFromMap( iPlayer : number, iDistrict : number, iCity : number, iX : number, iY : number, iDistrictType : number )
  -- Validate WOR
  if iDistrictType ~= CYP_WOR_DISTRICT_ID then return end
  -- Cleanup
  CypWorCleanupProperties(iPlayer, iCity);
end

-- ---------------------------------------------------------------------------
-- CypWorOnDistrictPillaged
-- ---------------------------------------------------------------------------
local function CypWorOnDistrictPillaged( iPlayer : number, iDistrict : number, iCity : number, iX : number, iY : number, iDistrictType : number, iPercent : number, bPillaged)
  -- Validate WOR
  if iDistrictType ~= CYP_WOR_DISTRICT_ID then return end
  -- Update worker slots
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- CypWorOnBuildingPillageStateChanged
-- ---------------------------------------------------------------------------
local function CypWorOnBuildingPillageStateChanged( iPlayer : number, iCity : number, iBuilding : number, bPillageState )
  -- Validate WOR A
  if iBuilding ~= CYP_WOR_BUILDING_A_ID then return end
  -- Update worker slots
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- CypWorPurchasePlot
-- ---------------------------------------------------------------------------
local function CypWorPurchasePlot( iPlayer : number, tParameters : table )
  -- Get params
  local iCity = tParameters.iCity;
  local iPlot = tParameters.iPlot;
  local iGoldCost = tParameters.iGoldCost;
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Validate player gold
  local pTreasury = pPlayer:GetTreasury();
	local iPlayerGold	:number = pTreasury:GetGoldBalance();
  if iPlayerGold < iGoldCost then return end
  -- Get city
	local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Validate city has district
  if not CypWorDistrictExists(pCity) then return end
  -- Determine purchase distance
  local iPurchaseDst = CYP_WOR_DST_MIN;
  if CypWorBuildingAExists(pCity) then 
    iPurchaseDst = CYP_WOR_DST_MAX;
  end
  -- Get plot
	local pPlot = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return end
  -- Validate unowned
  if pPlot:GetOwner() ~= -1 then return end
  -- Validate distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  if iDistance < CYP_WOR_DST_MIN or iDistance > iPurchaseDst then return end
  -- Set plot city owner
  WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, iCity);
  -- Acquire plot (update modifiers)
  CypWorAcquirePlot(iPlayer, pPlot);
  -- Update player gold
  if iGoldCost > 0 then
    pTreasury:ChangeGoldBalance(-iGoldCost);
  end
  -- Update info
  CypWorOnCityTileOwnershipChanged(iPlayer, iCity, pPlot:GetX(), pPlot:GetY());
end

-- ---------------------------------------------------------------------------
-- CypWorSwapTile
-- ---------------------------------------------------------------------------
local function CypWorSwapTile( iPlayer : number, tParameters : table )
  -- Get params
  local iCity = tParameters.iCity;
  local iPlot = tParameters.iPlot;
  -- Get plot
	local pPlot = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return end
  -- Validate is owned by player
  if pPlot:GetOwner() ~= iPlayer then return end
  -- Get city
	local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Validate distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  if iDistance < CYP_WOR_DST_MIN or iDistance > CYP_WOR_DST_MAX then return end
  -- Set plot city owner
  WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, iCity);
  -- Acquire plot (update modifiers)
  CypWorAcquirePlot(iPlayer, pPlot);
  -- Update info
  CypWorOnCityTileOwnershipChanged(iPlayer, iCity, pPlot:GetX(), pPlot:GetY());
end

-- ---------------------------------------------------------------------------
-- CypWorTogglePlotLock
-- ---------------------------------------------------------------------------
local function CypWorTogglePlotLock( iPlayer : number, tParameters : table )
  -- Get params
  local iCity = tParameters.iCity;
  local iPlot = tParameters.iPlot;
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return end
  -- Validate city has WOR district
  if not CypWorDistrictExists(pCity) then return end
  -- Get locked outer ring plots
  local tLockedOuterRingPlots = CypWorGetCityProperty(pCity, CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS);
  if tLockedOuterRingPlots == nil then tLockedOuterRingPlots = {} end
  -- Get old locked state
  local bWasLocked = tLockedOuterRingPlots[iPlot] == true;
  local bWantLocked = not bWasLocked;
  -- Toggle lock
  if bWantLocked then
    tLockedOuterRingPlots[iPlot] = true;
  else
    tLockedOuterRingPlots[iPlot] = nil;
  end
  CypWorSetCityProperty(pCity, CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS, tLockedOuterRingPlots);
  -- Refresh yields
  local bForceRefresh = true;
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, bForceRefresh);
end

-- ---------------------------------------------------------------------------
-- CypWorClearPlotLockCache
-- ---------------------------------------------------------------------------
local function CypWorClearPlotLockCache( iPlayer : number, tParameters : table )
  -- Get params
  local iCity = tParameters.iCity;
  -- Clear cache
  m_CypWorCachedCityLockedPlots[iCity] = nil;
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorLateInitialize
-- ---------------------------------------------------------------------------
local function CypWorLateInitialize()
  -- Event and GameEvent subscriptions
  Events.PlotYieldChanged.Add(                          CypWorOnPlotYieldChanged);
  Events.PlayerTurnActivated.Add(                       CypWorOnPlayerTurnActivated);
	Events.MapYieldsChanged.Add(                          CypWorOnMapYieldsChanged);            -- plots + score + slots + yields
  Events.CityTileOwnershipChanged.Add(                  CypWorOnCityTileOwnershipChanged);      -- plots + score + slots + yields
  Events.DistrictBuildProgressChanged.Add(              CypWorOnDistrictBuildProgressChanged);  -- plots + score + slots + yields
  Events.BuildingAddedToMap.Add(                        CypWorOnBuildingAddedToMap);            -- plots + score + slots + yields
  GameEvents.BuildingConstructed.Add(                   CypWorOnBuildingConstructed);           -- plots + score + slots + yields
  Events.CityFocusChanged.Add(                          CypWorOnCityFocusChanged);              -- plots + score + slots + yields
  Events.CityWorkerChanged.Add(                         CypWorOnCityWorkerChanged);             --                         yields
  Events.CityTransfered.Add(                            CypWorOnCityTransfered);                -- cleanup
  Events.CityInitialized.Add(                           CypWorOnCityInitialized);               -- cleanup
  Events.DistrictRemovedFromMap.Add(                    CypWorOnDistrictRemovedFromMap);        -- cleanup
  GameEvents.BuildingPillageStateChanged.Add(           CypWorOnBuildingPillageStateChanged);   -- pillaged
  Events.DistrictPillaged.Add(                          CypWorOnDistrictPillaged);              -- pillaged
  -- Custom game event subscriptions
  GameEvents.CypWor_CC_PurchasePlot.Add(                CypWorPurchasePlot);
  GameEvents.CypWor_CC_SwapTile.Add(                    CypWorSwapTile)
  GameEvents.CypWor_CC_TogglePlotLock.Add(              CypWorTogglePlotLock);                   -- plots + score + slots + yields
  GameEvents.CypWor_CC_ClearPlotLockCache.Add(          CypWorClearPlotLockCache);
  -- Log the initialization
  print("CypWor_WorkableOuterRings.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- CypWorMain
-- ---------------------------------------------------------------------------
local function CypWorMain()
  -- LateInititalize subscription
  Events.LoadScreenClose.Add(CypWorLateInitialize);
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorMain();