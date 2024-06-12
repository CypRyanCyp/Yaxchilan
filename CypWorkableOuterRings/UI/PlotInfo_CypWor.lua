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
local CITIZEN_BUTTON_HEIGHT		        :number = 64;
local PADDING_SWAP_BUTTON		          :number = 24;
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
-- MEMBERS
-- ===========================================================================
local m_CypWorPlotIM				                  :table = InstanceManager:new("InfoInstance",	"Anchor", Controls.PlotInfoContainer);
local m_CypWorUiCitizens			                :table = {};
local m_CypWorUiWorkableCityPlotsLensMask	    :table = {};
local m_CypWorUiPurchase			                :table = {};
local m_CypWorUiPurchasableCityPlotsLensMask	:table = {};
local m_CypWorUiSwapTiles		                  :table = {};
local m_CypWorUiSwapTilesCityPlotsLensMask	  :table = {};



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoPlotIsInInner2RingsOfOwnedCity
-- ---------------------------------------------------------------------------
function CypWorPlotInfoPlotIsInInner2RingsOfOwnedCity( pPlot )
  if pPlot == nil then return false end
  local iPlot = pPlot:GetIndex();
  local bPlotIsInInner2RingsOfOwnedCity = false;
  local pWorkingCity = Cities.GetPlotPurchaseCity(iPlot);
  if pWorkingCity ~= nil then
    local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pWorkingCity:GetX(), pWorkingCity:GetY());
    bPlotIsInInner2RingsOfOwnedCity = iDistance <= 2;
  end
  return bPlotIsInInner2RingsOfOwnedCity;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoPlotIsNextToOwnedPlot
-- ---------------------------------------------------------------------------
function CypWorPlotInfoPlotIsNextToOwnedPlot( pPlot, iCity : number )
  local tNeighborPlots = Map.GetNeighborPlots(pPlot:GetX(), pPlot:GetY(), 1);
  for _, pNeighborPlot in ipairs(tNeighborPlots) do
    local pWorkingCity = Cities.GetPlotPurchaseCity(pNeighborPlot:GetIndex());
    if pWorkingCity ~= nil and iCity == pWorkingCity:GetID() then 
      return true;
    end
  end
  return false;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoPlotHasOnePerCityImprovement
-- ---------------------------------------------------------------------------
function CypWorPlotInfoPlotHasOnePerCityImprovement( pPlot )
  if pPlot == nil then return false end
  local iImprovement = pPlot:GetImprovementType();
  if iImprovement == -1 then return false end
  local kImprovement = GameInfo.Improvements[iImprovement];
  if kImprovement == nil then return false end
  return kImprovement.OnePerCity;
end

-- ---------------------------------------------------------------------------
-- CypWorCanToggleCitizenPlot
-- Note: Must be defined before CypWorOnClickOuterRingCitizen.
-- ---------------------------------------------------------------------------
function CypWorCanToggleCitizenPlot( iPlayer : number, iCity : number, iPlot : number, bIsInnerRing )
  -- Get and validate city
  local pCity :table = UI.GetHeadSelectedCity();
  if pCity == nil then return false end
  if pCity:GetID() ~= iCity then return false end
  -- Get locked plots
  local tCityLockedPlots = {};
  local iCityLockedCount = -1;
  local bHasInnerRingData = false;
  local tLockedOuterRingPlots = {};
  local bHasOuterRingData = false;
  -- Determine if is locked
  local bPlotIsLocked = false;
  if bIsInnerRing then
    tCityLockedPlots, iCityLockedCount = ExposedMembers.CypWor.CityGetLockedPlots(iPlayer, iCity);
    bHasInnerRingData = true;
    bPlotIsLocked = tCityLockedPlots[iPlot] ~= nil;
  else
    tLockedOuterRingPlots = pCity:GetProperty(CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS);
    if tLockedOuterRingPlots == nil then tLockedOuterRingPlots = {} end
    bHasOuterRingData = true;
    bPlotIsLocked = tLockedOuterRingPlots[iPlot] == true;
  end
  if bPlotIsLocked then return true end
  -- Get missing data
  if not bHasInnerRingData then
    tCityLockedPlots, iCityLockedCount = ExposedMembers.CypWor.CityGetLockedPlots(iPlayer, iCity);
  end
  if not bHasOuterRingData then
    tLockedOuterRingPlots = pCity:GetProperty(CYP_WOR_PROPERTY_LOCKED_OUTER_RING_PLOTS);
    if tLockedOuterRingPlots == nil then tLockedOuterRingPlots = {} end
  end
  -- Count locks
  local iLockedOuterRingPlots = table.count(tLockedOuterRingPlots);
  local iTotalLockedPlots = iLockedOuterRingPlots + iCityLockedCount;
  local iTotalAvailableWorkerCount = pCity:GetPopulation();
  if iTotalLockedPlots + 1 > iTotalAvailableWorkerCount then return false end
  -- Return can lock
  return true;
end


-- ===========================================================================
-- USER INPUT CALLBACKS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorOnClickOuterRingCitizen
-- ---------------------------------------------------------------------------
function CypWorOnClickOuterRingCitizen( iPlayer : number, iCity : number, iPlot : number )
  -- Check if can toggle lock
  local bCanToggleCitizenPlot = CypWorCanToggleCitizenPlot(iPlayer, iCity, iPlot, false);
  if not bCanToggleCitizenPlot then return false end
  -- Toggle lock
  local tParameters = {};
  tParameters.iPlayer = iPlayer;
  tParameters.iCity = iCity;
  tParameters.iPlot = iPlot;
  tParameters.OnStart = "CypWor_CC_TogglePlotLock";
  UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
  -- Return
  return true;
end


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

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoGetOuterRingInstanceAt
-- ---------------------------------------------------------------------------
function CypWorPlotInfoGetOuterRingInstanceAt( iPlot : number )
	local pInstance = m_CypWorUiCitizens[iPlot];
	if pInstance == nil then
		pInstance = m_CypWorPlotIM:GetInstance();
		m_CypWorUiCitizens[iPlot] = pInstance;
		local worldX, worldY = UI.GridToWorld(iPlot);
		pInstance.Anchor:SetWorldPositionVal(worldX, worldY, 20);
		pInstance.Anchor:SetHide(false);
	end
	return pInstance;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoReleaseOuterRingInstanceAt
-- Note: This is actually never used, just like the original in PlotInfo.lua.
-- ---------------------------------------------------------------------------
function CypWorPlotInfoReleaseOuterRingInstanceAt( iPlot : number )
	local pInstance = m_CypWorUiCitizens[iPlot];
  if pInstance == nil then return end
  pInstance.Anchor:SetHide(true);
  m_CypWorUiCitizens[iPlot] = nil;
end


-- ---------------------------------------------------------------------------
-- CypWorPlotInfoUpdateWorCitizens
-- Override visualization of WOR citizens, when autto assigned
-- ---------------------------------------------------------------------------
function CypWorPlotInfoUpdateWorCitizens()
  
  -- Get city
  local pCity :table = UI.GetHeadSelectedCity();
	if pCity == nil then return end
  
  -- Validate city has WOR district
  if not CypWorDistrictExists(pCity) then return end
  local iCypWorPlot = CypWorDistrictPlotId(pCity);
  
  -- Get instance
  local pInstance : table = GetInstanceAt(iCypWorPlot);
  if pInstance == nil then return end
  table.insert(m_CypWorUiCitizens, pInstance);
  
  -- Hide instance
	pInstance.Anchor:SetHide(true);
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoShowOuterRingCitizens
-- Update outer ring workers. This is only called when the city management 
-- UI lens is already selected.
-- ---------------------------------------------------------------------------
function CypWorPlotInfoShowOuterRingCitizens()
  
  -- Get city
  local pCity :table = UI.GetHeadSelectedCity();
	if pCity == nil then return end
  local iCity = pCity:GetID();
  
  -- Validate is local player
  local iPlayer = pCity:GetOwner();
	if iPlayer ~= Game.GetLocalPlayer() then return end
  
  -- Validate is city management
	if UI.GetInterfaceMode() ~= InterfaceModeTypes.CITY_MANAGEMENT then return end
  
  -- Get outer ring plot data
  local tOuterRingPlotsData : table = pCity:GetProperty(CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA);
  if tOuterRingPlotsData == nil or table.count(tOuterRingPlotsData) == 0 then return end
  
  -- Show icon on each worked outer ring plot and disable shadow hex
  m_CypWorUiWorkableCityPlotsLensMask = {};
  for iPlot, xPlotData in pairs(tOuterRingPlotsData) do
    -- Add to lens hexes
		table.insert(m_CypWorUiWorkableCityPlotsLensMask, iPlot);
  -- Update instance
    local pInstance = CypWorPlotInfoGetOuterRingInstanceAt(iPlot);
    if pInstance ~= nil then
      if xPlotData.bIsWorked then
        pInstance.CitizenButton:SetTextureOffsetVal(0, CITIZEN_BUTTON_HEIGHT*4);
      else
        pInstance.CitizenButton:SetTextureOffsetVal(0, 0);
      end
      pInstance.CitizenButton:SetHide(false);
      pInstance.CitizenMeterBG:SetHide(true);
      pInstance.LockedIcon:SetHide(not xPlotData.bIsLocked);
      pInstance.CitizenButton:SetVoid1(iPlot);
      pInstance.CitizenButton:SetDisabled(false);
      pInstance.CitizenButton:RegisterCallback( Mouse.eLClick, function() CypWorOnClickOuterRingCitizen( iPlayer, iCity, iPlot ); end );
    end
  end
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoHideOuterRingCitizens
-- ---------------------------------------------------------------------------
function CypWorPlotInfoHideOuterRingCitizens()
	for iPlot, pInstance in pairs(m_CypWorUiCitizens) do
		--CypWorPlotInfoReleaseOuterRingInstanceAt(iPlot);
		pInstance.CitizenButton:SetHide(true);
		pInstance.CitizenMeterBG:SetHide(true);
	end
  m_CypWorUiCitizens = {};
  m_CypWorUiWorkableCityPlotsLensMask = {};
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoOnClickPurchasePlot
-- Execute outer ring plot purchase.
-- ---------------------------------------------------------------------------
function CypWorPlotInfoOnClickPurchasePlot( iPlot : number, iGoldCost : number )
  
  -- Validate placing mode
	if UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then return false end 
  if UI.GetInterfaceMode() == InterfaceModeTypes.BUILDING_PLACEMENT then return false end
  
  -- Get city
  local pCity :table = UI.GetHeadSelectedCity();
	if pCity == nil then return false end
  local iCity = pCity:GetID();
  
  -- Validate city has required building
  if not CypWorDistrictExists(pCity) then return false end
  
  -- Determine purchase distance
  local iPurchaseDst = CYP_WOR_DST_MIN;
  if CypWorBuildingAExists(pCity) then 
    iPurchaseDst = CYP_WOR_DST_MAX;
  end
  
  -- Get player
  local iPlayer = pCity:GetOwner();
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return false end
    
  -- Get plot
	local pPlot :table = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return false end
  
  -- Validate unowned
  if pPlot:GetOwner() ~= -1 then return false end
  
  -- Validate player gold
  local pTreasury = pPlayer:GetTreasury();
	local iPlayerGold	:number = pTreasury:GetGoldBalance();
  if iPlayerGold < iGoldCost then return false end
  
  -- Validate distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  if iDistance < CYP_WOR_DST_MIN or iDistance > iPurchaseDst then return false end
  
  -- Notify script context to purchase plot
  local tParameters = {};
  tParameters.iPlayer = iPlayer;
  tParameters.iCity = iCity;
  tParameters.iPlot = iPlot;
  tParameters.iGoldCost = iGoldCost;
  tParameters.OnStart = "CypWor_CC_PurchasePlot";
  UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
  
  -- Play UI sound
  UI.PlaySound("Purchase_Tile");
  
  -- Always return true, since we can't get any feedback from the cross context call.
  -- However, the validation checks should be sufficient.
  return true;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoOnClickSwapTile
-- Execute outer ring tile swap.
-- ---------------------------------------------------------------------------
function CypWorPlotInfoOnClickSwapTile( iPlot : number )
  
  -- Validate placing mode
	if UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then return false end 
  if UI.GetInterfaceMode() == InterfaceModeTypes.BUILDING_PLACEMENT then return false end
  
  -- Get city
  local pCity :table = UI.GetHeadSelectedCity();
	if pCity == nil then return false end
  local iCity = pCity:GetID();
  
  -- Get player
  local iPlayer = pCity:GetOwner();
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return false end
    
  -- Get plot
	local pPlot :table = Map.GetPlotByIndex(iPlot);
  if pPlot == nil then return false end
  
  -- Validate is owned by player
  if pPlot:GetOwner() ~= iPlayer then return false end
  
  -- Validate not already owned by city
  local pWorkingCity = Cities.GetPlotPurchaseCity(pPlot:GetIndex());
  local iWorkingCity = nil;
  if pWorkingCity ~= nil then 
    iWorkingCity = pWorkingCity:GetID();
  end
  if iWorkingCity == nil or iWorkingCity == iCity then return false end
  
  -- Validate distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  if iDistance < CYP_WOR_DST_MIN or iDistance > CYP_WOR_DST_MAX then return false end
  
  -- Validate not in inner 2 rings of owned city
  if CypWorPlotInfoPlotIsInInner2RingsOfOwnedCity(pPlot) then return false end
  
  -- Validate is next to owned plot
  if not CypWorPlotInfoPlotIsNextToOwnedPlot(pPlot, iCity) then return false end
  
  -- Validate is no one per city improvement
  if CypWorPlotInfoPlotHasOnePerCityImprovement(pPlot) then return false end
  
  -- Notify script context to purchase plot
  local tParameters = {};
  tParameters.iPlayer = iPlayer;
  tParameters.iCity = iCity;
  tParameters.iPlot = iPlot;
  tParameters.OnStart = "CypWor_CC_SwapTile";
  UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
  
  -- Play UI sound
  UI.PlaySound("Purchase_Tile");
  
  -- Always return true, since we can't get any feedback from the cross context call.
  -- However, the validation checks should be sufficient.
  return true;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoGetGoldCostInfo
-- ---------------------------------------------------------------------------
function CypWorPlotInfoGetGoldCostInfo(pPlayer)

  -- Get player
  local iPlayer = pPlayer:GetID();

  -- Base cost
  local iPlotBuyBaseCost = GameInfo.GlobalParameters["PLOT_BUY_BASE_COST"].Value;
  local iGoldCostPerDistance = iPlotBuyBaseCost / 2;
  
  -- Tech scaling
  local pPlayerTech = pPlayer:GetTechs();
  local iTotalTechs = 0;
  local iResearchedTechs = 0;
  for kTech in GameInfo.Technologies() do
    iTotalTechs = iTotalTechs + 1;
    if pPlayerTech:HasTech(kTech.Index) then
      iResearchedTechs = iResearchedTechs + 1;
    end
  end
  local iTechScaling = 1 + (iResearchedTechs / iTotalTechs) * 1.5;
  
  -- Civic scaling
  local pPlayerCulture = pPlayer:GetCulture();
  local iTotalCivics = 0;
  local iResearchedCivics = 0;
  for kCivic in GameInfo.Civics() do
    iTotalCivics = iTotalCivics + 1;
    if pPlayerCulture:HasCivic(kCivic.Index) then
      iResearchedCivics = iResearchedCivics + 1;
    end
  end
  local iCivicScaling = 1 + (iResearchedCivics / iTotalCivics) * 1.5;
  
  -- Modifiers
  -- Note: Does only consider default ModifierTypes, no new dynamic modifiers from mods
  local iModifierScaling = 1;
  local tTerrainModifierScalings = {};
  for i, iModifier in ipairs(GameEffects.GetModifiers()) do
    if CypWorIsModifierActive(iModifier, iPlayer) then
      local iOwner = GameEffects.GetModifierOwner(iModifier);
      local iModifierPlayer = GameEffects.GetObjectsPlayerId(iOwner);
      if iPlayer == iModifierPlayer then
        local tModifierDefinition = GameEffects.GetModifierDefinition(iModifier);
        local pModifier = GameInfo.Modifiers[tModifierDefinition.Id];
        if pModifier ~= nil then
          -- Plot purchase
          if pModifier.ModifierType == 'MODIFIER_PLAYER_CITIES_ADJUST_PLOT_PURCHASE_COST' then
            -- Check arguments
            for sKey, xValue in pairs(tModifierDefinition.Arguments) do
              if sKey == 'Amount' then
                local iModScaling = (100 + xValue) / 100;
                iModifierScaling = iModifierScaling * iModScaling;
              end
            end
          -- Plot terrain purchase
          elseif pModifier.ModifierType == 'MODIFIER_PLAYER_CITIES_ADJUST_PLOT_PURCHASE_COST_TERRAIN' then
            tTerrainModifierScalings[pModifier.ModifierId] = {};
            -- Check arguments
            for sKey, xValue in pairs(tModifierDefinition.Arguments) do
              if sKey == 'Amount' then
                tTerrainModifierScalings[pModifier.ModifierId]['Multiplier'] = (100 + xValue) / 100;
              elseif sKey == 'TerrainType' then
                local tTerrain = GameInfo.Terrains[xValue];
                if tTerrain ~= nil then
                  tTerrainModifierScalings[pModifier.ModifierId]['TerrainTypeId'] = tTerrain.Index;
                end
              end
            end
          end
        end
      end
    end
  end

  -- Merge and return
  return iGoldCostPerDistance * iTechScaling * iCivicScaling * iModifierScaling, tTerrainModifierScalings;
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoGetPlotGoldCost
-- ---------------------------------------------------------------------------
function CypWorPlotInfoGetPlotGoldCost(iGoldCostPerDistance, tTerrainModifierScalings, iSpeedCostMultiplier, pCity, pPlot)
  -- Cost due to distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  local iGoldCost = iDistance * iGoldCostPerDistance;
  -- Terrain modifiers
  for iModifierId, tArgs in pairs(tTerrainModifierScalings) do
    local iTerrainType = tArgs['TerrainTypeId'];
    local iMultiplier = tArgs['Multiplier'];
    if iTerrainType ~= nil and iMultiplier ~= nil then
      if pPlot:GetTerrainType() == iTerrainType then
        iGoldCost = iGoldCost * iMultiplier;
      end
    end
  end
  -- Game speed scaling
  iGoldCost = iGoldCost * iSpeedCostMultiplier / 100;
  -- Rounding
  return math.floor(iGoldCost);
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoShowOuterRingPurchases
-- Update outer ring purchases. This is only called when the city management 
-- UI lens is already selected.
-- ---------------------------------------------------------------------------
function CypWorPlotInfoShowOuterRingPurchases()
  
  -- Do not show when any placement filter is set, since districts and buildings
  -- can't be placed in the outer rings anyway.
	if UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then return end 
  if UI.GetInterfaceMode() == InterfaceModeTypes.BUILDING_PLACEMENT then return end
  
  -- Get city
  local pCity :table = UI.GetHeadSelectedCity();
	if pCity == nil then return end
  local iCity = pCity:GetID();
  
  -- Validate is local player
  local iPlayer = pCity:GetOwner();
	if iPlayer ~= Game.GetLocalPlayer() then return end
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  
  -- Validate city has required building
  if not CypWorDistrictExists(pCity) then return end
  
  -- Determine purchase distance
  local iPurchaseDst = CYP_WOR_DST_MIN;
  if CypWorBuildingAExists(pCity) then 
    iPurchaseDst = CYP_WOR_DST_MAX;
  end
  
  -- Get player info
	local iPlayerGold	:number = pPlayer:GetTreasury():GetGoldBalance();
  local iGoldCostPerDistance, tTerrainModifierScalings = CypWorPlotInfoGetGoldCostInfo(pPlayer);
  local iSpeedCostMultiplier = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()].CostMultiplier;
  
  -- Get unowned plots in outer rings
  local tUnownedOuterRingPlots = CypWorGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), -1, nil, CYP_WOR_DST_MIN, iPurchaseDst);
  if tUnownedOuterRingPlots == nil or table.count(tUnownedOuterRingPlots) == 0 then return end
  
  -- Filter unreachable unowned tiles (= tiles that are not adjacent to a tiled already owned by this city)
  local tReachableUnownedOuterRingPlots = {};
  for _,pPlot in pairs(tUnownedOuterRingPlots) do
    local tNeighborPlots = Map.GetNeighborPlots(pPlot:GetX(), pPlot:GetY(), 1);
    for _, pNeighborPlot in ipairs(tNeighborPlots) do
      local pWorkingCity = Cities.GetPlotPurchaseCity(pNeighborPlot:GetIndex());
      if pWorkingCity ~= nil then 
        if iCity == pWorkingCity:GetID() and iPlayer == pNeighborPlot:GetOwner() then
          table.insert(tReachableUnownedOuterRingPlots, pPlot);
          break;
        end
      end
    end
  end
  
  -- Show purchase icons
  for _,pPlot in pairs(tReachableUnownedOuterRingPlots) do
    local iPlot = pPlot:GetIndex();
    -- Add to lens hexes
    table.insert(m_CypWorUiPurchasableCityPlotsLensMask, iPlot);
    -- Add icon
    local pInstance = CypWorPlotInfoGetOuterRingInstanceAt(iPlot);
    if pInstance ~= nil then
      -- Gold cost
      local iGoldCost = CypWorPlotInfoGetPlotGoldCost(iGoldCostPerDistance, tTerrainModifierScalings, iSpeedCostMultiplier, pCity, pPlot);
      pInstance.PurchaseButton:SetText(tostring(iGoldCost));
      -- Button
      AutoSizeGridButton(pInstance.PurchaseButton,51,30,25,"H");
      pInstance.PurchaseButton:SetDisabled( iGoldCost > iPlayerGold );
      if ( iGoldCost > iPlayerGold ) then
        pInstance.PurchaseButton:GetTextControl():SetColorByName("TopBarValueCS");
      else
        pInstance.PurchaseButton:GetTextControl():SetColorByName("ResGoldLabelCS");
      end
      pInstance.PurchaseButton:RegisterCallback( Mouse.eLClick, function() CypWorPlotInfoOnClickPurchasePlot( iPlot, iGoldCost ); end );
      pInstance.PurchaseAnim:SetColor( (iGoldCost > iPlayerGold ) and UI.GetColorValueFromHexLiteral(0xbb808080) or UI.GetColorValueFromHexLiteral(0xffffffff) ) ;
			pInstance.PurchaseAnim:RegisterEndCallback( OnSpinningCoinAnimDone );
			if ( iGoldCost > iPlayerGold ) then
				pInstance.PurchaseButton:ClearMouseEnterCallback();
				pInstance.PurchaseButton:SetToolTipString( Locale.Lookup("LOC_PLOTINFO_YOU_NEED_MORE_GOLD_TO_PURCHASE", iGoldCost - math.floor(iPlayerGold) ));
			else
				pInstance.PurchaseButton:RegisterMouseEnterCallback( function() OnSpinningCoinAnimMouseEnter(pInstance.PurchaseAnim); end );
				pInstance.PurchaseButton:SetToolTipString("");
			end
			pInstance.PurchaseButton:SetHide( false );
			table.insert(m_CypWorUiPurchase, pInstance);
    end    
  end
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoHideOuterRingPurchases
-- ---------------------------------------------------------------------------
function CypWorPlotInfoHideOuterRingPurchases()
	for _, pInstance in pairs(m_CypWorUiPurchase) do
		pInstance.PurchaseButton:SetHide( true );
    -- Note: Instances are removed by worker plot function
	end
  m_CypWorUiPurchase = {};
  m_CypWorUiPurchasableCityPlotsLensMask = {};
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoShowOuterRingSwapTiles
-- ---------------------------------------------------------------------------
function CypWorPlotInfoShowOuterRingSwapTiles()
  
  -- Do not show when any placement filter is set, since districts and buildings
  -- can't be placed in the outer rings anyway.
	if UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then return end 
  if UI.GetInterfaceMode() == InterfaceModeTypes.BUILDING_PLACEMENT then return end
  
  -- Get city
  local pCity :table = UI.GetHeadSelectedCity();
	if pCity == nil then return end
  local iCity = pCity:GetID();
  
  -- Validate is local player
  local iPlayer = pCity:GetOwner();
	if iPlayer ~= Game.GetLocalPlayer() then return end
  local pPlayer = Players[iPlayer];
  if pPlayer == nil then return end
  
  -- Validate city has WOR district
  --if not CypWorDistrictExists(pCity) then return end
  
  -- Get swappable outer ring tiles
  local tSwappableOuterRingPlots = CypWorGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), iPlayer, iCity, CYP_WOR_DST_MIN, CYP_WOR_DST_MAX, true);
  if tSwappableOuterRingPlots == nil or table.count(tSwappableOuterRingPlots) == 0 then return end
  
  -- Show swap icons
  for _,pPlot in pairs(tSwappableOuterRingPlots) do
    local iPlot = pPlot:GetIndex();
    -- Validate
    if not CypWorPlotInfoPlotIsInInner2RingsOfOwnedCity(pPlot) 
    and CypWorPlotInfoPlotIsNextToOwnedPlot(pPlot, iCity) 
    and not CypWorPlotInfoPlotHasOnePerCityImprovement(pPlot) 
    then
      -- Add to lens hexes
      table.insert(m_CypWorUiSwapTilesCityPlotsLensMask, iPlot);
      -- Add icon
      local pInstance = CypWorPlotInfoGetOuterRingInstanceAt(iPlot);
      if pInstance ~= nil then
          pInstance.SwapTileOwnerButton:SetVoid1(iPlot);
          pInstance.SwapTileOwnerButton:RegisterCallback(Mouse.eLClick, function() CypWorPlotInfoOnClickSwapTile( iPlot ); end );
          pInstance.SwapTileOwnerButton:SetHide(false);
          pInstance.SwapTileOwnerButton:SetSizeX(pInstance.SwapLabel:GetSizeX() + PADDING_SWAP_BUTTON);
          table.insert( m_CypWorUiSwapTiles, pInstance );
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoHideOuterRingSwapTiles
-- ---------------------------------------------------------------------------
function CypWorPlotInfoHideOuterRingSwapTiles()
  for _,pInstance in ipairs(m_CypWorUiSwapTiles) do
		pInstance.SwapTileOwnerButton:SetHide( true );
    -- Note: Instances are removed by worker plot function
	end
	m_CypWorUiSwapTiles = {};
	m_CypWorUiSwapTilesCityPlotsLensMask = {};
end



-- ===========================================================================
-- OVERRIDES
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CACHE ORIGINAL
-- ---------------------------------------------------------------------------
-- Plot yields
CypWorOriginal_GetPlotYields = GetPlotYields;
-- Citizens
CypWorOriginal_ShowCitizens = ShowCitizens;
CypWorOriginal_HideCitizens = HideCitizens;
CypWorOriginal_OnClickCitizen = OnClickCitizen;
-- Purchase tiles
CypWorOriginal_ShowPurchases = ShowPurchases;
CypWorOriginal_HidePurchases = HidePurchases;
-- Swap tiles
CypWorOriginal_ShowSwapTiles = ShowSwapTiles;
CypWorOriginal_HideSwapTiles = HideSwapTiles;
-- Lens hexes
CypWorOriginal_AggregateLensHexes = AggregateLensHexes;
-- Cleanup
CypWorOriginal_ClearEverything = ClearEverything;

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
-- ShowCitizens
-- Overwrites original PlotInfo.ShowCitizens function.
-- Show outer ring workers in city management UI lens.
-- ---------------------------------------------------------------------------
function ShowCitizens()
  -- Call original
  CypWorOriginal_ShowCitizens();
  -- Update WOR specialists
  CypWorPlotInfoUpdateWorCitizens();
  -- Show outer ring workers
  CypWorPlotInfoShowOuterRingCitizens();
end

-- ---------------------------------------------------------------------------
-- HideCitizens
-- Overwrites original PlotInfo.HideCitizens function.
-- Hide outer ring workers in city management UI lens.
-- ---------------------------------------------------------------------------
function HideCitizens()
  -- Call original
  CypWorOriginal_HideCitizens();
  -- Hide outer ring workers
  CypWorPlotInfoHideOuterRingCitizens();
end


-- ---------------------------------------------------------------------------
-- OnClickCitizen
-- ---------------------------------------------------------------------------
function OnClickCitizen( iPlot : number )
  -- Get and validate city
  local pCity :table = UI.GetHeadSelectedCity();
  if pCity == nil then return end
  local iCity = pCity:GetID();
  -- Get and validate player
  local iPlayer = pCity:GetOwner();
  -- Check if can toggle lock
  local bCanToggleCitizenPlot = CypWorCanToggleCitizenPlot(iPlayer, iCity, iPlot, true);
  if not bCanToggleCitizenPlot then return false end
  -- Call original
	local bResult = CypWorOriginal_OnClickCitizen(iPlot);
  -- Call to clear plot lock cache
  local tParameters = {};
  tParameters.iCity = iCity;
  tParameters.OnStart = "CypWor_CC_ClearPlotLockCache";
  UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
  -- Return
  return bResult;
end

-- ---------------------------------------------------------------------------
-- ShowPurchases
-- Overwrites original PlotInfo.ShowPurchases function.
-- Show unowned outer ring plots in city management UI lens.
-- ---------------------------------------------------------------------------
function ShowPurchases()
  -- Call original
  CypWorOriginal_ShowPurchases();
  -- Show outer ring workers
  CypWorPlotInfoShowOuterRingPurchases();
end

-- ---------------------------------------------------------------------------
-- HidePurchases
-- Overwrites original PlotInfo.HidePurchases function.
-- Hide unowned outer ring plots in city management UI lens.
-- ---------------------------------------------------------------------------
function HidePurchases()
  -- Call original
  CypWorOriginal_HidePurchases();
  -- Hide outer ring workers
  CypWorPlotInfoHideOuterRingPurchases();
end

-- ---------------------------------------------------------------------------
-- ShowSwapTiles
-- Overwrites original PlotInfo.ShowSwapTiles function.
-- Show outer ring swap tiles.
-- ---------------------------------------------------------------------------
function ShowSwapTiles()
  -- Call original
  CypWorOriginal_ShowSwapTiles();
  -- Show outer ring swap tiles
  CypWorPlotInfoShowOuterRingSwapTiles();
end

-- ---------------------------------------------------------------------------
-- HideSwapTiles
-- Overwrites original PlotInfo.HideSwapTiles function.
-- Hide outer ring swap tiles.
-- ---------------------------------------------------------------------------
function HideSwapTiles()
  -- Call original
  CypWorOriginal_HideSwapTiles();
  -- Hide outer ring swap tiles
  CypWorPlotInfoHideOuterRingSwapTiles();
end

-- ---------------------------------------------------------------------------
-- AggregateLensHexes
-- Overwrites original PlotInfo.AggregateLensHexes function.
-- Add outer ring worker plot ids to lens hexes list.
-- This means that they won't be shadowed.
-- ---------------------------------------------------------------------------
function AggregateLensHexes( tKeys : table )
  -- Call original
  local tResults : table = CypWorOriginal_AggregateLensHexes(tKeys);
  -- Add outer ring plots to lens hexes
  for i, iPlot in pairs(m_CypWorUiWorkableCityPlotsLensMask) do
    table.insert(tResults, iPlot);
  end
  -- Add unowned outer ring plots to lens hexes
  for i, iPlot in pairs(m_CypWorUiPurchasableCityPlotsLensMask) do
    table.insert(tResults, iPlot);
  end
  -- Add swappable outer ring plots to lens hexes
  for i, iPlot in pairs(m_CypWorUiSwapTilesCityPlotsLensMask) do
    table.insert(tResults, iPlot);
  end
  -- Return new result
  return tResults;
end

-- ---------------------------------------------------------------------------
-- ClearEverything
-- Overwrites original PlotInfo.ClearEverything function.
-- Clear outer ring worker instances.
-- ---------------------------------------------------------------------------
function ClearEverything()
  -- Call original
  CypWorOriginal_ClearEverything();
  -- Clear outer ring worker instances
  for key,pInstance in pairs(m_CypWorUiCitizens) do
		pInstance.Anchor:SetHide(true);
		m_CypWorPlotIM:ReleaseInstance(pInstance);
		m_CypWorUiCitizens[key] = nil;
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