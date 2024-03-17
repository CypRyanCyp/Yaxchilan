-- ===========================================================================
-- Yaxchilan District
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
include("SupportFunctions");
include "Yaxchilan_Utility.lua"



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- Buildings
local YAXCHILAN_BUILDING_INTERNAL_WORKERS_TYPE = "BUILDING_YAXCHILAN_WORKERS_" -- example: BUILDING_YAXCHILAN_WORKERS_2
-- Plot yield score
local YAXCHILAN_YIELD_SCORE_DEFAULT = 1;
local YAXCHILAN_YIELD_SCORE_FAVORED = 4;
local YAXCHILAN_YIELD_SCORE_DISFAVORED = 0;
local YAXCHILAN_YIELD_BINARY_DIGITS = 11;
local YAXCHILAN_WORKERS_BINARY_DIGITS = 7;
-- Specialist compensation yields
local YAXCHILAN_SPECIALIST_COMPENSATION_YIELD_AMOUNT = 20;
-- Plot properties
local YAXCHILAN_PROPERTY_YIELD_BONUS_PREFIX = "YAXCHILAN_BONUS_";
local YAXCHILAN_PROPERTY_YIELD_MALUS_PREFIX = "YAXCHILAN_MALUS_";
local YAXCHILAN_PROPERTY_YIELD_MALUS_AMOUNT = 1024;
-- City properties
local YAXCHILAN_PROPERTY_YIELD_HASH = "YAXCHILAN_YIELD_HASH";
local YAXCHILAN_PROPERTY_WORKABLE_OUTER_RING_TILES = "YAXCHILAN_WORKER_WORKABLE_OUTER_RING_TILES";
local YAXCHILAN_PROPERTY_SPECIALIST_SLOT_COUNT = "YAXCHILAN_SPECIALIST_SLOT_COUNT";



-- ===========================================================================
-- MEMBERS
-- ===========================================================================
-- City plot yields changed
local m_YaxchilanCityChangedPlotYields = {};
-- Currently updating cities
local m_YaxchilanCityIsUpdatingSpecialists = {};



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanGetCityRingPlots
-- Get plots in the nth ring of a city.
-- ---------------------------------------------------------------------------
function YaxchilanGetCityRingPlots(pCity, iMin : number, iMax : number)
  -- Validate city
  if pCity == nil then return {} end
  -- Get plots
  return YaxchilanGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), pCity:GetOwner(), pCity:GetID(), iMin, iMax);
end

-- ---------------------------------------------------------------------------
-- YaxchilanDeterminePlotHasAnyYield
-- Determine if this plot has any yield.
-- ---------------------------------------------------------------------------
function YaxchilanDeterminePlotHasAnyYield(pPlot)
  for pYield in GameInfo.Yields() do
    if pPlot:GetYield(pYield.Index) > 0 then return true end
  end
  return false;
end

-- ---------------------------------------------------------------------------
--	YaxchilanPlotIsWorkable
--  Determine if plot can be worked.
-- ---------------------------------------------------------------------------
function YaxchilanPlotIsWorkable(pPlot)
  -- Check wonder (not workable)
  if pPlot:GetWonderType() ~= -1 then return false end
  -- Check improvement (not workable)
  local sImprovementType = pPlot:GetImprovementType();
  if sImprovementType ~= -1 then
    local pImprovement = GameInfo.Improvements[sImprovementType];
    if not pImprovement.Workable then return false end
  end
  -- Check feature (danger value)
  local pFeature = pPlot:GetFeature();
  if pFeature ~= nil then
    if pFeature.DangerValue ~= nil and pFeature.DangerValue > 0 then return false end
  end
  -- Check has any yields
  if not YaxchilanDeterminePlotHasAnyYield(pPlot) then return false end
  -- Check disasters
  if GameClimate.GetActiveDroughtAtPlot(pPlot) ~= nil 
  or GameClimate.GetActiveStormAtPlot(pPlot) ~= nil then return false end
  -- Workable
  return true;
end

-- ---------------------------------------------------------------------------
--	YaxchilanGetPlotWorkerSlots
--  Determine amount of available worker slots.
-- ---------------------------------------------------------------------------
function YaxchilanGetPlotWorkerSlots(pCity, pPlot)
  -- District tile
  if pPlot:GetDistrictType() ~= -1 then
    local iWorkerSlots = 0;
    -- District specialist slots
    local tDistrict = GameInfo.Districts[pPlot:GetDistrictType()];
    local iDistrictCitizenSlots = GameInfo.Districts[pPlot:GetDistrictType()].CitizenSlots;
    if iDistrictCitizenSlots == nil then iDistrictCitizenSlots = 0 end
    iWorkerSlots = iWorkerSlots + iDistrictCitizenSlots;
    -- Building specialist slots
    for tBuilding in GameInfo.Buildings() do
      if tBuilding.PrereqDistrict == tDistrict.DistrictType and tBuilding.CitizenSlots ~= nil then
        iWorkerSlots = iWorkerSlots + tBuilding.CitizenSlots;
      end
    end
  -- Normal tile
  elseif YaxchilanPlotIsWorkable(pPlot) then
    return 1;
  end
  return 0;
end

-- ---------------------------------------------------------------------------
-- YaxchilanCreateDummyBuildingWithBinaryConvertedValue
-- Create desired dummy buildings determined by value that is to be converted
-- to binary representation.
-- ---------------------------------------------------------------------------
function YaxchilanCreateDummyBuildingWithBinaryConvertedValue(
            iValue : number, 
            iMaxDigits : number, 
            sBuildingTypePrefix, 
            pCity, 
            pBuildingPlotIndex) 
  -- Hash is handled before thi
  -- Convert base10 to base2 (binary)
  local tValueBinary = YaxchilanDecimalToBinaryArray(iValue);
  -- Reverse, so that we can loop from smallest digit (2^0) to largest digit (2^n)
  local tValueBinaryReversed = YaxchilanReverseTable(tValueBinary);
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
        local iBuilding = GameInfo.Buildings[sBuildingType].Index
        local bBuildingExists = pCity:GetBuildings():HasBuilding(iBuilding)
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
-- YaxchilanDeterminePlotScore
-- Determine score of plot considering Multipliers.
-- A plot score is the sum of weighted yield type sums.
-- ---------------------------------------------------------------------------
function YaxchilanDeterminePlotScore( pPlot, tYieldMultipliers :table )
  -- Determine score
  local iScore = 0;
  for pYield in GameInfo.Yields() do
    iScore = iScore + pPlot:GetYield(pYield.Index) * tYieldMultipliers[pYield.Index];
  end
  return iScore;
end

-- ---------------------------------------------------------------------------
-- YaxchilanCitizenYieldFavorMultiplier
-- Determine yield multiplier/weight based on citizen favor.
-- This determines how much the amount of yields of a certain type is weighted.
-- ---------------------------------------------------------------------------
function YaxchilanCitizenYieldFavorMultiplier( pCitizens, pYield )
  local iYield = pYield.Index;
  if pCitizens:IsYieldFavored(iYield) then
    return YAXCHILAN_YIELD_SCORE_FAVORED;
  elseif pCitizens:IsYieldDisfavored(iYield) then
    return YAXCHILAN_YIELD_SCORE_DISFAVORED;
  else
    return YAXCHILAN_YIELD_SCORE_DEFAULT;
  end
end



-- ===========================================================================
-- FUNCTIONS (LOGIC)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanRefreshWorkerYields
-- ---------------------------------------------------------------------------
function YaxchilanRefreshWorkerYields( iPlayer : number, iCity : number, iYaxchilanPlot : number, iYaxchilanWorkerCount : number, bForceFocusRefresh )
  
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  
  -- Get city plot
  local pCityPlot = pCity:GetPlot();
  if pCityPlot == nil then return end
  
  -- Get assigned specialists of NBH TE
  local pYaxchilanPlot = Map.GetPlotByIndex(iYaxchilanPlot);
  if iYaxchilanWorkerCount == nil or iYaxchilanWorkerCount < 0 then
    iYaxchilanWorkerCount = pYaxchilanPlot:GetWorkerCount();
  end
  
  -- Prepare yield sum
  local tYieldSums = {};
  for pYield in GameInfo.Yields() do
    tYieldSums[pYield.YieldType] = 0;
  end
  
  -- Determine to be worked outer ring plots
  -- Get n best workable outer ring tiles, while n is the amount of NBH specialists
  local tWorkableOuterPlotData : table = pCity:GetProperty(YAXCHILAN_PROPERTY_WORKABLE_OUTER_RING_TILES);
  local iAssignedNbhWorkerCount = 0;
  local tOuterRingPlotsData = {};
  for _, xOuterRingPlotInfo in pairs(tWorkableOuterPlotData) do
    -- Set data
    local xPlotData = {};
    xPlotData.bIsWorked = iAssignedNbhWorkerCount < iYaxchilanWorkerCount;
    xPlotData.iPlot = xOuterRingPlotInfo.iPlot;
    xPlotData.bIsLocked = xOuterRingPlotInfo.bIsLocked;
    tOuterRingPlotsData[xPlotData.iPlot] = xPlotData;
    -- Count yield sum and assigned
    if xPlotData.bIsWorked then 
      iAssignedNbhWorkerCount = iAssignedNbhWorkerCount + 1;
      local pPlot = Map.GetPlotByIndex(xOuterRingPlotInfo.iPlot); 
      for pYield in GameInfo.Yields() do
        tYieldSums[pYield.YieldType] = tYieldSums[pYield.YieldType] + pPlot:GetYield(pYield.Index);
      end
    end
  end
  
  -- Store properties
  pCity:SetProperty(YAXCHILAN_PROPERTY_YIELD_VALUES, tYieldSums);
  -- Compensate ingame specialist yields and set property
  for pYield in GameInfo.Yields() do
    tYieldSums[pYield.YieldType] = tYieldSums[pYield.YieldType] - (iYaxchilanWorkerCount * YAXCHILAN_SPECIALIST_COMPENSATION_YIELD_AMOUNT);
  end
  pCityPlot:SetProperty(YAXCHILAN_PROPERTY_YIELDS_WITH_COMPENSATIONS, tYieldSums);
  pCity:SetProperty(YAXCHILAN_PROPERTY_OUTER_RING_PLOTS_DATA, tOuterRingPlotsData);

  -- Check hash (determines if desired yields already applied)
  local sCityOuterRingYieldHash = '|';
  for pYield in GameInfo.Yields() do
    sCityOuterRingYieldHash = sCityOuterRingYieldHash .. tYieldSums[pYield.YieldType] .. '|';
  end
  local sStoredHash = pCity:GetProperty(YAXCHILAN_PROPERTY_YIELD_HASH);
  if sStoredHash ~= sCityOuterRingYieldHash then
    -- Force focus refresh
    if not bForceFocusRefresh then bForceFocusRefresh = true end
    -- Store hash
    pCity:SetProperty(YAXCHILAN_PROPERTY_YIELD_HASH, sCityOuterRingYieldHash);
    -- Apply yield properties to add worked plot yields
    for sYieldType, iYieldAmount in pairs(tYieldSums) do
      -- Handle negative yield part
      local sNegativeYieldPropertyName = YAXCHILAN_PROPERTY_YIELD_MALUS_PREFIX .. sYieldType;
      local iNegativeYield = 0;
      if iYieldAmount < 0 then
        iNegativeYield = 1;
        iYieldAmount = YAXCHILAN_PROPERTY_YIELD_MALUS_AMOUNT + iYieldAmount;
      end
      pCityPlot:SetProperty(sNegativeYieldPropertyName, iNegativeYield);
      -- Handle positie yield part
      YaxchilanApplyPropertiesToPlotWithBinaryConvertedValue(
          iYieldAmount, 
          YAXCHILAN_YIELD_BINARY_DIGITS, 
          YAXCHILAN_PROPERTY_YIELD_BONUS_PREFIX .. sYieldType .. "_",
          pCityPlot);
    end
  end
  
  -- Notify event outer ring workers changed
  local tParameters = {};
  tParameters.iPlayer = iPlayer;
  tParameters.iCity = iCity;
  tParameters.iWantedOuterRingWorkers = iWantedOuterRingWorkers;
  tParameters.bForceFocusRefresh = bForceFocusRefresh;
  ReportingEvents.SendLuaEvent("YaxchilanOuterRingSpecialistsChanged", tParameters);
end

-- ---------------------------------------------------------------------------
-- YaxchilanDetermineAutoAssignedOuterRingWorkers
-- ---------------------------------------------------------------------------
function YaxchilanDetermineAutoAssignedOuterRingWorkers( pCity, iYaxchilanPlot : number, tCityLockedPlots : table, tCityLockedOuterRingPlots : table )

  -- Determine yield multipliers (depends on city yield favor)
  local pCitizens = pCity:GetCitizens();
  local tYieldMultipliers = {};
  for pYield in GameInfo.Yields() do
    tYieldMultipliers[pYield.Index] = YaxchilanCitizenYieldFavorMultiplier(pCitizens, pYield);
  end
  
  -- Determine all city tiles with scores (include inner and outer rings)
  local tCityPlots : table = {};
  local iCityPlot = pCity:GetPlot():GetIndex();
  for _, pPlot in pairs(YaxchilanGetCityRingPlots(pCity, 1, 5)) do
    -- Ignore NBH TE
    local iPlot = pPlot:GetIndex();
    if iPlot ~= iYaxchilanPlot and iPlot ~= iCityPlot then
      -- Store info
      local xPlotInfo = {};
      xPlotInfo.iPlot = iPlot;
      xPlotInfo.pPlot = pPlot;
      -- Determine score
      xPlotInfo.iScore = 0;
      local iPlotWorkerSlots = YaxchilanGetPlotWorkerSlots(pCity, pPlot); -- Also checks if plot is workable
      if iPlotWorkerSlots > 0 then
        xPlotInfo.iScore = YaxchilanDeterminePlotScore(pPlot, tYieldMultipliers);
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
-- YaxchilanRefreshCityNbhWorkerSlots
-- ---------------------------------------------------------------------------
function YaxchilanRefreshCityNbhWorkerSlots( iPlayer : number, iCity : number, bForceFocusRefresh )

  -- Remove from list
  m_YaxchilanCityChangedPlotYields[iCity] = nil;

  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  
  -- Validate city has NBH TE
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  local iYaxchilanPlot = pCity:GetBuildings():GetBuildingLocation(YAXCHILAN_BUILDING_ID);
  
  -- Prepare
  local iOuterRingTileSpecialistSlots = 0;
  local tWorkableOuterPlotData = {};
  local iWorkableOuterRingTilesCountPropertyValue = nil;
  
  -- Check NBH TE pillaged state
  local bYaxchilanIsPillaged = pCity:GetBuildings():IsPillaged(YAXCHILAN_BUILDING_ID);
  
  -- Remove all specialist slots when building is pillaged
  if not bYaxchilanIsPillaged then
    
    -- Determine locked plots
    local tCityLockedPlots, iCityLockedCount = ExposedMembers.Yaxchilan.CityGetLockedPlots(iPlayer, iCity);
    local tCityLockedOuterRingPlots = pCity:GetProperty(YAXCHILAN_PROPERTY_LOCKED_OUTER_RING_PLOTS);
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
        pCity:SetProperty(YAXCHILAN_PROPERTY_LOCKED_OUTER_RING_PLOTS, tCityLockedOuterRingPlots);
      end
    end
    
    -- Add one specialist slot for each workable outer ring tile that should be worked (city AI)
    -- Auto assigned tiles are workable only (for the game)
    tWorkableOuterPlotData, iOuterRingTileSpecialistSlots = YaxchilanDetermineAutoAssignedOuterRingWorkers(pCity, iYaxchilanPlot, tCityLockedPlots, tCityLockedOuterRingPlots);
    pCity:SetProperty(YAXCHILAN_PROPERTY_WORKABLE_OUTER_RING_TILES, tWorkableOuterPlotData);
  end
  
  -- Store amount of actual workable outer ring tiles (used in UI)
  pCity:SetProperty(YAXCHILAN_PROPERTY_TOTAL_WORKABLE_OUTER_RING_PLOT_COUNT, table.count(tWorkableOuterPlotData));
  
  -- Check if to be worked outer ring tiles count has changed
  local iPropertyStoredCount = pCity:GetProperty(YAXCHILAN_PROPERTY_SPECIALIST_SLOT_COUNT);
  -- Always update, caching worker count leads to bugs
  if iPropertyStoredCount ~= iOuterRingTileSpecialistSlots then
    -- Force focus refresh
    if not bForceFocusRefresh then bForceFocusRefresh = true end
    -- Store cache
    pCity:SetProperty(YAXCHILAN_PROPERTY_SPECIALIST_SLOT_COUNT, iOuterRingTileSpecialistSlots);
    --- Apply amount of NBH TE specialist slots (if worked count changed)
    m_YaxchilanCityIsUpdatingSpecialists[iCity] = true;
    YaxchilanCreateDummyBuildingWithBinaryConvertedValue(
        iOuterRingTileSpecialistSlots, 
        YAXCHILAN_WORKERS_BINARY_DIGITS, 
        YAXCHILAN_BUILDING_INTERNAL_WORKERS_TYPE,
        pCity,
        iYaxchilanPlot);
    m_YaxchilanCityIsUpdatingSpecialists[iCity] = false;
  end
  
  -- Update yields
  YaxchilanRefreshWorkerYields(iPlayer, iCity, iYaxchilanPlot, iOuterRingTileSpecialistSlots, bForceFocusRefresh);
end

-- ---------------------------------------------------------------------------
-- YaxchilanCleanupProperties
-- ---------------------------------------------------------------------------
function YaxchilanCleanupProperties( iPlayer : number, iCity : number )

  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  
  -- Clear properties
  pCity:SetProperty(YAXCHILAN_PROPERTY_WORKABLE_OUTER_RING_TILES, nil);
  pCity:SetProperty(YAXCHILAN_PROPERTY_SPECIALIST_SLOT_COUNT, nil);
  pCity:SetProperty(YAXCHILAN_PROPERTY_TOTAL_WORKABLE_OUTER_RING_PLOT_COUNT, nil);
  pCity:SetProperty(YAXCHILAN_PROPERTY_OUTER_RING_PLOTS_DATA, nil);
  pCity:SetProperty(YAXCHILAN_PROPERTY_YIELD_HASH, nil);
  pCity:SetProperty(YAXCHILAN_PROPERTY_YIELD_VALUES, nil);
  pCity:GetPlot():SetProperty(YAXCHILAN_PROPERTY_YIELDS_WITH_COMPENSATIONS, nil);
  
  -- Check if city has NBH TE
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  local iYaxchilanPlot = pCity:GetBuildings():GetBuildingLocation(YAXCHILAN_BUILDING_ID);
  
  -- Clear buildings
  if pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then
    pCity:GetBuildings():RemoveBuilding(YAXCHILAN_BUILDING_ID);
  end
  -- Clear workers
  YaxchilanCreateDummyBuildingWithBinaryConvertedValue(
      0, 
      YAXCHILAN_WORKERS_BINARY_DIGITS, 
      YAXCHILAN_BUILDING_INTERNAL_WORKERS_TYPE,
      pCity,
      iYaxchilanPlot);
  -- Clear city center yields
  local pCityPlot = pCity:GetPlot();
  for row in GameInfo.Yields() do
    local sYieldType = row.YieldType;
    -- Handle negative yield part
    local sNegativeYieldPropertyName = YAXCHILAN_PROPERTY_YIELD_MALUS_PREFIX .. sYieldType;
    pCityPlot:SetProperty(sNegativeYieldPropertyName, nil);
    YaxchilanApplyPropertiesToPlotWithBinaryConvertedValue(
        0, 
        YAXCHILAN_YIELD_BINARY_DIGITS, 
        YAXCHILAN_PROPERTY_YIELD_BONUS_PREFIX .. sYieldType .. "_",
        pCityPlot);
  end
end



-- ===========================================================================
-- EVENT CALLBACKS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanOnOnMapYieldsChanged
-- ---------------------------------------------------------------------------
local function YaxchilanOnOnMapYieldsChanged()
  for iCity, iPlayer in ipairs(m_YaxchilanCityChangedPlotYields) do
    YaxchilanRefreshCityNbhWorkerSlots(iPlayer, iCity, false);
  end
  -- Make sure list is cleared after
  m_YaxchilanCityChangedPlotYields = {};
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnPlotYieldChanged
-- Add to list of changed cities that will be processed in 
-- YaxchilanOnOnMapYieldsChanged.
-- ---------------------------------------------------------------------------
local function YaxchilanOnPlotYieldChanged(iX : number, iY : number)
  -- Get city
  local pCity = Cities.GetPlotWorkingCity(iX, iY);
  if pCity == nil then return end
  -- Store in tmp table
  local iCity = pCity:GetID();
  local iPlayer = pCity:GetOwner();
  local pPlayer = Players[iPlayer];
  -- Ignore city center
  if iX == pCity:GetX() and iY == pCity:GetY() then return end
  -- Ignore NBH TE
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  local iYaxchilanPlot = pCity:GetBuildings():GetBuildingLocation(YAXCHILAN_BUILDING_ID);
  local pYaxchilanPlot = Map.GetPlotByIndex(iYaxchilanPlot);
  if iX == pYaxchilanPlot:GetX() and iY == pYaxchilanPlot:GetY() then return end
  -- Check if is player turn
  if pPlayer:IsTurnActive() then
    YaxchilanRefreshCityNbhWorkerSlots(iPlayer, iCity, false);
  else
    m_YaxchilanCityChangedPlotYields[iCity] = iPlayer;
  end
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnPlayerTurnActivated
-- ---------------------------------------------------------------------------
local function YaxchilanOnPlayerTurnActivated( iPlayer : number )
  -- Update all changed yields on any turn activation
  YaxchilanOnOnMapYieldsChanged(); 
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnCityTileOwnershipChanged
-- New tiles can shift inner/outer ring worker distribution.
-- ---------------------------------------------------------------------------
local function YaxchilanOnCityTileOwnershipChanged(iPlayer : number, iCity : number, iX : number, iY : number)
  YaxchilanRefreshCityNbhWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnCityFocusChanged
-- Recalculate all slots, since plot score depends on city focus.
-- Changing focus can shift inner/outer ring worker distribution.
-- ---------------------------------------------------------------------------
local function YaxchilanOnCityFocusChanged(iPlayer : number, iCity : number)
  YaxchilanRefreshCityNbhWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnBuildingConstructed
-- ---------------------------------------------------------------------------
local function YaxchilanOnDistrictBuildProgressChanged( 
                iPlayer : number, 
                iDistrict : number, 
                iCity : number, 
                iX : number, 
                iY : number, 
                iDistrictType : number, 
                iEra : number,
                iCiv : number,
                iPercent : number)
  -- Only when NBH TE has been built
  if iDistrictType ~= YAXCHILAN_DISTRICT_ID then return end
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Get plot
  local pYaxchilanPlot = Map.GetPlot(iX, iY);
  if pYaxchilanPlot == nil then return end
  local iYaxchilanPlot = pYaxchilanPlot:GetIndex();
  -- Place internal specialist yield building
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then
    pCity:GetBuildQueue():CreateIncompleteBuilding(YAXCHILAN_BUILDING_ID, iYaxchilanPlot, 100);
  end
  -- Update worker slots
  YaxchilanRefreshCityNbhWorkerSlots(iPlayer, iCity, true);
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnCityWorkerChanged
-- ---------------------------------------------------------------------------
local function YaxchilanOnCityWorkerChanged( iPlayer : number, iCity : number, iX : number, iY : number )
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Validate NBH TE exists
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  local iYaxchilanPlot = pCity:GetBuildings():GetBuildingLocation(YAXCHILAN_BUILDING_ID);
  -- Validate not currently updating specialists
  if m_YaxchilanCityIsUpdatingSpecialists[iCity] then return end
  -- Refresh yields
  YaxchilanRefreshWorkerYields(iPlayer, iCity, iYaxchilanPlot, nil, false);
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnCityTransfered
-- ---------------------------------------------------------------------------
local function YaxchilanOnCityTransfered(iPlayer : number, iCity : number, iOldPlayer : number, xTransferType)
  YaxchilanCleanupProperties(iPlayer, iCity);
  YaxchilanRefreshCityNbhWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnCityInitialized
-- ---------------------------------------------------------------------------
local function YaxchilanOnCityInitialized(iPlayer : number, iCity : number, iX : number, iY : number)
  YaxchilanCleanupProperties(iPlayer, iCity);
end

-- ---------------------------------------------------------------------------
-- YaxchilanOnBuildingPillageStateChanged
-- ---------------------------------------------------------------------------
local function YaxchilanOnBuildingPillageStateChanged( iPlayer : number, iCity : number, iBuilding : number, bPillageState )
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Validate NBH TE
  if iBuilding ~= YAXCHILAN_BUILDING_ID then return end
  -- Update worker slots
  YaxchilanRefreshCityNbhWorkerSlots(iPlayer, iCity, false);
end

-- ---------------------------------------------------------------------------
-- YaxchilanPurchasePlot
-- ---------------------------------------------------------------------------
local function YaxchilanPurchasePlot( iPlayer : number, tParameters : table )
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
  -- Get plot
	local pPlot = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return end
  -- Validate unowned
  if pPlot:GetOwner() ~= -1 then return end
  -- Get city
	local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Validate distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  if iDistance < 4 or iDistance > 5 then return end
  -- Set plot owner
  WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, iCity);
  -- Update player gold
  if iGoldCost > 0 then
    pTreasury:ChangeGoldBalance(-iGoldCost);
  end
  -- Update info
  YaxchilanOnCityTileOwnershipChanged(iPlayer, iCity, pPlot:GetX(), pPlot:GetY());
end

-- ---------------------------------------------------------------------------
-- YaxchilanSwapTile
-- ---------------------------------------------------------------------------
local function YaxchilanSwapTile( iPlayer : number, tParameters : table )
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
  if iDistance < 4 or iDistance > 5 then return end
  -- Set plot owner
  WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, iCity);
  -- Update info
  YaxchilanOnCityTileOwnershipChanged(iPlayer, iCity, pPlot:GetX(), pPlot:GetY());
end

-- ---------------------------------------------------------------------------
-- YaxchilanTogglePlotLock
-- ---------------------------------------------------------------------------
local function YaxchilanTogglePlotLock( iPlayer : number, tParameters : table )
  -- Get params
  local iCity = tParameters.iCity;
  local iPlot = tParameters.iPlot;
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Get city
  local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return end
  -- Validate NBH TE exists
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  -- Get locked outer ring plots
  local tLockedOuterRingPlots = pCity:GetProperty(YAXCHILAN_PROPERTY_LOCKED_OUTER_RING_PLOTS);
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
  pCity:SetProperty(YAXCHILAN_PROPERTY_LOCKED_OUTER_RING_PLOTS, tLockedOuterRingPlots);
  -- Refresh yields
  local bForceRefresh = true;
  YaxchilanRefreshCityNbhWorkerSlots(iPlayer, iCity, bForceRefresh);
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanLateInitialize
-- ---------------------------------------------------------------------------
local function YaxchilanLateInitialize()
  -- Event and GameEvent subscriptions
  Events.PlotYieldChanged.Add(                          YaxchilanOnPlotYieldChanged);
  Events.PlayerTurnActivated.Add(                       YaxchilanOnPlayerTurnActivated);
	Events.MapYieldsChanged.Add(                          YaxchilanOnOnMapYieldsChanged);             -- plots + score + slots + yields
  Events.CityTileOwnershipChanged.Add(                  YaxchilanOnCityTileOwnershipChanged);       -- plots + score + slots + yields
  Events.DistrictBuildProgressChanged.Add(              YaxchilanOnDistrictBuildProgressChanged);   -- plots + score + slots + yields
  Events.CityFocusChanged.Add(                          YaxchilanOnCityFocusChanged);               -- plots + score + slots + yields
  Events.CityWorkerChanged.Add(                         YaxchilanOnCityWorkerChanged);              --                         yields
  Events.CityTransfered.Add(                            YaxchilanOnCityTransfered);                 -- cleanup
  Events.CityInitialized.Add(                           YaxchilanOnCityInitialized);                -- cleanup
  GameEvents.BuildingPillageStateChanged.Add(           YaxchilanOnBuildingPillageStateChanged);    -- pillaged
  -- Custom game event subscriptions
  GameEvents.Yaxchilan_CC_YaxchilanPurchasePlot.Add(    YaxchilanPurchasePlot);
  GameEvents.Yaxchilan_CC_YaxchilanSwapTile.Add(        YaxchilanSwapTile)
  GameEvents.Yaxchilan_CC_YaxchilanTogglePlotLock.Add(  YaxchilanTogglePlotLock);                   -- plots + score + slots + yields
  -- Log the initialization
  print("Yaxchilan_Script_NeighborhoodTe.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- YaxchilanMain
-- ---------------------------------------------------------------------------
local function YaxchilanMain()
  -- LateInititalize subscription
  Events.LoadScreenClose.Add(YaxchilanLateInitialize);
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
YaxchilanMain();