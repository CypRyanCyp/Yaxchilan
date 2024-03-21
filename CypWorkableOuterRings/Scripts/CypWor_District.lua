-- ===========================================================================
-- Workable outer ring district.
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
include("SupportFunctions");
include "CypWor_Utility.lua"



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- Buildings
local CYP_WOR_BUILDING_INTERNAL_WORKERS_TYPE = "BUILDING_CYP_WOR_WORKERS_" -- example: BUILDING_CYP_WOR_WORKERS_2
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
-- CypWorDeterminePlotHasAnyYield
-- Determine if this plot has any yield.
-- ---------------------------------------------------------------------------
function CypWorDeterminePlotHasAnyYield(pPlot)
  for pYield in GameInfo.Yields() do
    if pPlot:GetYield(pYield.Index) > 0 then return true end
  end
  return false;
end

-- ---------------------------------------------------------------------------
--	CypWorPlotIsWorkable
--  Determine if plot can be worked.
-- ---------------------------------------------------------------------------
function CypWorPlotIsWorkable(pPlot)
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
  if not CypWorDeterminePlotHasAnyYield(pPlot) then return false end
  -- Check disasters
  if GameClimate.GetActiveDroughtAtPlot(pPlot) ~= nil 
  or GameClimate.GetActiveStormAtPlot(pPlot) ~= nil then return false end
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
        local iBuilding = GameInfo.Buildings[sBuildingType].Index;
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
  -- Determine score
  local iScore = 0;
  for pYield in GameInfo.Yields() do
    iScore = iScore + pPlot:GetYield(pYield.Index) * tYieldMultipliers[pYield.Index];
  end
  return iScore;
end

-- ---------------------------------------------------------------------------
-- CypWorCitizenYieldFavorMultiplier
-- Determine yield multiplier/weight based on citizen favor.
-- This determines how much the amount of yields of a certain type is weighted.
-- ---------------------------------------------------------------------------
function CypWorCitizenYieldFavorMultiplier( pCitizens, pYield )
  local iYield = pYield.Index;
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
-- CypWorCheckRailroadBomb
-- ---------------------------------------------------------------------------
function CypWorCheckRailroadBomb( iPlayer : number, iCity : number, iCypWorPlot : number )
  -- Get player
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  -- Check player has required tech
  if RAILROAD_BOMB_TECH_ID == nil then return end
  if not pPlayer:GetTechs():HasTech(RAILROAD_BOMB_TECH_ID) then return end
  -- Get city
  local pCity = CityManager.GetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Get plot
  local iCypWorPlot = CypWorDistrictPlotId(pCity);
  local pCypWorPlot = Map.GetPlotByIndex(iCypWorPlot);
  if pCypWorPlot == nil then return end
  local iX = pCypWorPlot:GetX();
  local iY = pCypWorPlot:GetY();
  -- Get railroad index
  local kRailroad = GameInfo.Routes['ROUTE_RAILROAD'];
  if kRailroad == nil then return end
  -- Get surrounding tiles
  local tRangePlots = Map.GetNeighborPlots(iX, iY, 1);
  for _, pPlot in ipairs(tRangePlots) do
    if iPlayer == pPlot:GetOwner() then
      RouteBuilder.SetRouteType(pPlot, kRailroad.Index);
    end
  end
end

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
  for pYield in GameInfo.Yields() do
    tYieldSums[pYield.YieldType] = 0;
  end
  
  -- Determine to be worked outer ring plots
  -- Get n best workable outer ring tiles, while n is the amount of specialists
  local tWorkableOuterPlotData : table = pCity:GetProperty(CYP_WOR_PROPERTY_WORKABLE_OUTER_RING_TILES);
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
      local pPlot = Map.GetPlotByIndex(xOuterRingPlotInfo.iPlot); 
      for pYield in GameInfo.Yields() do
        tYieldSums[pYield.YieldType] = tYieldSums[pYield.YieldType] + pPlot:GetYield(pYield.Index);
      end
    end
  end
  
  -- Store properties
  pCity:SetProperty(CYP_WOR_PROPERTY_YIELD_VALUES, tYieldSums);
  -- Compensate ingame specialist yields and set property
  for pYield in GameInfo.Yields() do
    tYieldSums[pYield.YieldType] = tYieldSums[pYield.YieldType] - (iCypWorWorkerCount * CYP_WOR_SPECIALIST_COMPENSATION_YIELD_AMOUNT);
  end
  pCityPlot:SetProperty(CYP_WOR_PROPERTY_YIELDS_WITH_COMPENSATIONS, tYieldSums);
  pCity:SetProperty(CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA, tOuterRingPlotsData);

  -- Check hash (determines if desired yields already applied)
  local sCityOuterRingYieldHash = '|';
  for pYield in GameInfo.Yields() do
    sCityOuterRingYieldHash = sCityOuterRingYieldHash .. tYieldSums[pYield.YieldType] .. '|';
  end
  local sStoredHash = pCity:GetProperty(CYP_WOR_PROPERTY_YIELD_HASH);
  if sStoredHash ~= sCityOuterRingYieldHash then
    -- Force focus refresh
    if not bForceFocusRefresh then bForceFocusRefresh = true end
    -- Store hash
    pCity:SetProperty(CYP_WOR_PROPERTY_YIELD_HASH, sCityOuterRingYieldHash);
    -- Apply yield properties to add worked plot yields
    for sYieldType, iYieldAmount in pairs(tYieldSums) do
      -- Handle negative yield part
      local sNegativeYieldPropertyName = CYP_WOR_PROPERTY_YIELD_MALUS_PREFIX .. sYieldType;
      local iNegativeYield = 0;
      if iYieldAmount < 0 then
        iNegativeYield = 1;
        iYieldAmount = CYP_WOR_PROPERTY_YIELD_MALUS_AMOUNT + iYieldAmount;
      end
      pCityPlot:SetProperty(sNegativeYieldPropertyName, iNegativeYield);
      -- Handle positie yield part
      CypWorApplyPropertiesToPlotWithBinaryConvertedValue(
          iYieldAmount, 
          CYP_WOR_YIELD_BINARY_DIGITS, 
          CYP_WOR_PROPERTY_YIELD_BONUS_PREFIX .. sYieldType .. "_",
          pCityPlot);
    end
  end
  
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
  for pYield in GameInfo.Yields() do
    tYieldMultipliers[pYield.Index] = CypWorCitizenYieldFavorMultiplier(pCitizens, pYield);
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
    local tCityLockedPlots, iCityLockedCount = ExposedMembers.CypWor.CityGetLockedPlots(iPlayer, iCity);
    local tCityLockedOuterRingPlots = pCity:GetProperty(CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS);
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
        pCity:SetProperty(CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS, tCityLockedOuterRingPlots);
      end
    end
    
    -- Add one specialist slot for each workable outer ring tile that should be worked (city AI)
    -- Auto assigned tiles are workable only (for the game)
    tWorkableOuterPlotData, iOuterRingTileSpecialistSlots = CypWorDetermineAutoAssignedOuterRingWorkers(pCity, iCypWorPlot, tCityLockedPlots, tCityLockedOuterRingPlots);
  end
  
  -- Store amount of actual workable outer ring tiles (used in UI)
  pCity:SetProperty(CYP_WOR_PROPERTY_WORKABLE_OUTER_RING_TILES, tWorkableOuterPlotData);
  pCity:SetProperty(CYP_WOR_PROPERTY_TOTAL_WORKABLE_OUTER_RING_PLOT_COUNT, table.count(tWorkableOuterPlotData));
  
  -- Check if to be worked outer ring tiles count has changed
  local iPropertyStoredCount = pCity:GetProperty(CYP_WOR_PROPERTY_SPECIALIST_SLOT_COUNT);
  -- Always update, caching worker count leads to bugs
  if iPropertyStoredCount ~= iOuterRingTileSpecialistSlots then
    -- Force focus refresh
    if not bForceFocusRefresh then bForceFocusRefresh = true end
    -- Store cache
    pCity:SetProperty(CYP_WOR_PROPERTY_SPECIALIST_SLOT_COUNT, iOuterRingTileSpecialistSlots);
    --- Apply amount of specialist slots (if worked count changed)
    m_CypWorCityIsUpdatingSpecialists[iCity] = true;
    CypWorCreateDummyBuildingWithBinaryConvertedValue(
        iOuterRingTileSpecialistSlots, 
        CYP_WOR_WORKERS_BINARY_DIGITS, 
        CYP_WOR_BUILDING_INTERNAL_WORKERS_TYPE,
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
  pCity:SetProperty(CYP_WOR_PROPERTY_WORKABLE_OUTER_RING_TILES, nil);
  pCity:SetProperty(CYP_WOR_PROPERTY_SPECIALIST_SLOT_COUNT, nil);
  pCity:SetProperty(CYP_WOR_PROPERTY_TOTAL_WORKABLE_OUTER_RING_PLOT_COUNT, nil);
  pCity:SetProperty(CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA, nil);
  pCity:SetProperty(CYP_WOR_PROPERTY_YIELD_HASH, nil);
  pCity:SetProperty(CYP_WOR_PROPERTY_YIELD_VALUES, nil);
  pCity:GetPlot():SetProperty(CYP_WOR_PROPERTY_YIELDS_WITH_COMPENSATIONS, nil);
end



-- ===========================================================================
-- EVENT CALLBACKS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorOnOnMapYieldsChanged
-- ---------------------------------------------------------------------------
local function CypWorOnOnMapYieldsChanged()
  for iCity, iPlayer in ipairs(m_CypWorCityChangedPlotYields) do
    CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, false);
  end
  -- Make sure list is cleared after
  m_CypWorCityChangedPlotYields = {};
end

-- ---------------------------------------------------------------------------
-- CypWorOnPlotYieldChanged
-- Add to list of changed cities that will be processed in CypWorOnOnMapYieldsChanged.
-- ---------------------------------------------------------------------------
local function CypWorOnPlotYieldChanged(iX : number, iY : number)
  -- Get city
  local pCity = Cities.GetPlotWorkingCity(iX, iY);
  if pCity == nil then return end
  -- Store in tmp table
  local iCity = pCity:GetID();
  local iPlayer = pCity:GetOwner();
  local pPlayer = Players[iPlayer];
  -- Ignore city center
  if iX == pCity:GetX() and iY == pCity:GetY() then return end
  -- Validate city has WOR district
  if not CypWorDistrictExists(pCity) then return end
  local iCypWorPlot, iWorX, iWorY = CypWorDistrictPlotId(pCity);
  if iX == iWorX and iY == iWorY then return end
  -- Check if is player turn
  if pPlayer:IsTurnActive() then
    CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, false);
  else
    m_CypWorCityChangedPlotYields[iCity] = iPlayer;
  end
end

-- ---------------------------------------------------------------------------
-- CypWorOnPlayerTurnActivated
-- ---------------------------------------------------------------------------
local function CypWorOnPlayerTurnActivated( iPlayer : number )
  -- Update all changed yields on any turn activation
  CypWorOnOnMapYieldsChanged(); 
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
-- CypWorOnBuildingConstructed
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
  -- Railroad bomb
  CypWorCheckRailroadBomb(iPlayer, iCity);
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
  -- Set plot owner
  WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, iCity);
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
  -- Set plot owner
  WorldBuilder.CityManager():SetPlotOwner(pPlot:GetX(), pPlot:GetY(), iPlayer, iCity);
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
  local tLockedOuterRingPlots = pCity:GetProperty(CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS);
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
  pCity:SetProperty(CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS, tLockedOuterRingPlots);
  -- Refresh yields
  local bForceRefresh = true;
  CypWorRefreshCityWorWorkerSlots(iPlayer, iCity, bForceRefresh);
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
	Events.MapYieldsChanged.Add(                          CypWorOnOnMapYieldsChanged);            -- plots + score + slots + yields
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
  -- Log the initialization
  print("CypWor_District.lua initialized!");
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