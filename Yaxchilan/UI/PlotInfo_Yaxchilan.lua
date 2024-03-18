-- ===========================================================================
-- Plotinfo UI
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "Yaxchilan_Utility.lua"
-- Original
local tBaseFileVersions = {
    "PlotInfo_CQUI",  -- CQUI
    "PlotInfo"        -- Base Game and Expansions
};
for _, sVersion in ipairs(tBaseFileVersions) do
  include(sVersion);
  if Initialize then break end
end



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- ICONS
local CITIZEN_BUTTON_HEIGHT		        :number = 64;
local PADDING_SWAP_BUTTON		          :number = 24;
local CITY_CENTER_DISTRICT_INDEX              = GameInfo.Districts["DISTRICT_CITY_CENTER"].Index;
-- PLOT INFO
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
local m_YaxchilanPlotIM				                  :table = InstanceManager:new("InfoInstance",	"Anchor", Controls.PlotInfoContainer);
local m_YaxchilanUiCitizens			                :table = {};
local m_YaxchilanUiWorkableCityPlotsLensMask	  :table = {};
local m_YaxchilanUiPurchase			                :table = {};
local m_YaxchilanUiPurchasableCityPlotsLensMask	:table = {};
local m_YaxchilanUiSwapTiles		                :table = {};
local m_YaxchilanUiSwapTilesCityPlotsLensMask	  :table = {};



-- ===========================================================================
-- FUNCTIONS (UTILITY)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanCanToggleCitizenPlot
-- Note: Must be defined before YaxchilanOnClickOuterRingCitizen.
-- ---------------------------------------------------------------------------
function YaxchilanCanToggleCitizenPlot( iPlayer : number, iCity : number, iPlot : number, bIsInnerRing )
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
    tCityLockedPlots, iCityLockedCount = ExposedMembers.Yaxchilan.CityGetLockedPlots(iPlayer, iCity);
    bHasInnerRingData = true;
    bPlotIsLocked = tCityLockedPlots[iPlot] ~= nil;
  else
    tLockedOuterRingPlots = pCity:GetProperty(YAXCHILAN_PROPERTY_LOCKED_OUTER_RING_PLOTS);
    if tLockedOuterRingPlots == nil then tLockedOuterRingPlots = {} end
    bHasOuterRingData = true;
    bPlotIsLocked = tLockedOuterRingPlots[iPlot] == true;
  end
  if bPlotIsLocked then return true end
  -- Get missing data
  if not bHasInnerRingData then
    tCityLockedPlots, iCityLockedCount = ExposedMembers.Yaxchilan.CityGetLockedPlots(iPlayer, iCity);
  end
  if not bHasOuterRingData then
    tLockedOuterRingPlots = pCity:GetProperty(YAXCHILAN_PROPERTY_LOCKED_OUTER_RING_PLOTS);
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
-- YaxchilanOnClickOuterRingCitizen
-- ---------------------------------------------------------------------------
function YaxchilanOnClickOuterRingCitizen( iPlayer : number, iCity : number, iPlot : number )
  -- Check if can toggle lock
  local bCanToggleCitizenPlot = YaxchilanCanToggleCitizenPlot(iPlayer, iCity, iPlot, false);
  if not bCanToggleCitizenPlot then return false end
  -- Toggle lock
  local tParameters = {};
  tParameters.iPlayer = iPlayer;
  tParameters.iCity = iCity;
  tParameters.iPlot = iPlot;
  tParameters.OnStart = "Yaxchilan_CC_TogglePlotLock";
  UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
  return true;
end


-- ===========================================================================
-- FUNCTIONS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoGetPlotYieldsWithWorkerCompensations
-- Get corrected yields for city center plot with yield bonuses.
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoGetPlotYieldsWithWorkerCompensations( iPlot : number, yields : table, tYieldSums : table )
  -- Get plot
	local pPlot = Map.GetPlotByIndex(iPlot);
  -- Set corrected yields
	for row in GameInfo.Yields() do
    -- Get plot yields
		local yieldAmt:number = pPlot:GetYield(row.Index);
    -- Apply plot bonuses
    local iYieldCompensationAmt:number = tYieldSums[row.YieldType];
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
-- YaxchilanPlotInfoGetOuterRingInstanceAt
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoGetOuterRingInstanceAt( iPlot : number )
	local pInstance = m_YaxchilanUiCitizens[iPlot];
	if pInstance == nil then
		pInstance = m_YaxchilanPlotIM:GetInstance();
		m_YaxchilanUiCitizens[iPlot] = pInstance;
		local worldX, worldY = UI.GridToWorld(iPlot);
		pInstance.Anchor:SetWorldPositionVal(worldX, worldY, 20);
		pInstance.Anchor:SetHide(false);
	end
	return pInstance;
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoReleaseOuterRingInstanceAt
-- Note: This is actually never used, just like the original in PlotInfo.lua.
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoReleaseOuterRingInstanceAt( iPlot : number )
	local pInstance = m_YaxchilanUiCitizens[iPlot];
  if pInstance == nil then return end
  pInstance.Anchor:SetHide(true);
  m_YaxchilanUiCitizens[iPlot] = nil;
end


-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoUpdateNbhCitizens
-- Override visualization of NBH citizens, when autto assigned
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoUpdateNbhCitizens()
  
  -- Get city
  local pCity :table = UI.GetHeadSelectedCity();
	if pCity == nil then return end
  local iCity = pCity:GetID();
  
  -- Validate city has NBH TE
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  local pNbhDistrict = pCity:GetDistricts():GetDistrict(YAXCHILAN_DISTRICT_TYPE);
  local pNbhTePlot = Map.GetPlot(pNbhDistrict:GetX(), pNbhDistrict:GetY());
  local iNbhTePlot = pNbhTePlot:GetIndex();
  
  -- Get instance
  local pInstance : table = GetInstanceAt(iNbhTePlot);
  if pInstance == nil then return end
  table.insert(m_YaxchilanUiCitizens, pInstance);
  
  -- Hide instance
	pInstance.Anchor:SetHide(true);
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoShowOuterRingCitizens
-- Update outer ring workers. This is only called when the city management 
-- UI lens is already selected.
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoShowOuterRingCitizens()
  
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
  local tOuterRingPlotsData : table = pCity:GetProperty(YAXCHILAN_PROPERTY_OUTER_RING_PLOTS_DATA);
  if tOuterRingPlotsData == nil or table.count(tOuterRingPlotsData) == 0 then return end
  
  print("tOuterRingPlotsData");
  for iPlot, _ in pairs(tOuterRingPlotsData) do
    print(">", "iPlot", iPlot);
  end

  -- Show icon on each worked outer ring plot and disable shadow hex
  m_YaxchilanUiWorkableCityPlotsLensMask = {};
  for iPlot, xPlotData in pairs(tOuterRingPlotsData) do
    -- Add to lens hexes
		table.insert(m_YaxchilanUiWorkableCityPlotsLensMask, iPlot);
  -- Update instance
    local pInstance = YaxchilanPlotInfoGetOuterRingInstanceAt(iPlot);
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
      pInstance.CitizenButton:RegisterCallback( Mouse.eLClick, function() YaxchilanOnClickOuterRingCitizen( iPlayer, iCity, iPlot ); end );
    end
  end
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoHideOuterRingCitizens
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoHideOuterRingCitizens()
	for iPlot, pInstance in pairs(m_YaxchilanUiCitizens) do
		--YaxchilanPlotInfoReleaseOuterRingInstanceAt(iPlot);
		pInstance.CitizenButton:SetHide(true);
		pInstance.CitizenMeterBG:SetHide(true);
	end
  m_YaxchilanUiCitizens = {};
  m_YaxchilanUiWorkableCityPlotsLensMask = {};
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoOnClickPurchasePlot
-- Execute outer ring plot purchase.
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoOnClickPurchasePlot( iPlot : number, iGoldCost : number )
  
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
  
  -- Validate unowned
  if pPlot:GetOwner() ~= -1 then return false end
  
  -- Validate player gold
  local pTreasury = pPlayer:GetTreasury();
	local iPlayerGold	:number = pTreasury:GetGoldBalance();
  if iPlayerGold < iGoldCost then return false end
  
  -- Validate distance
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  if iDistance < 4 or iDistance > 5 then return false end
  
  -- Notify script context to purchase plot
  local tParameters = {};
  tParameters.iPlayer = iPlayer;
  tParameters.iCity = iCity;
  tParameters.iPlot = iPlot;
  tParameters.iGoldCost = iGoldCost;
  tParameters.OnStart = "Yaxchilan_CC_PurchasePlot";
  UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
  
  -- Play UI sound
  UI.PlaySound("Purchase_Tile");
  
  -- Always return true, since we can't get any feedback from the cross context call.
  -- However, the validation checks should be sufficient.
  return true;
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoOnClickSwapTile
-- Execute outer ring tile swap.
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoOnClickSwapTile( iPlot : number )
  
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
  if iDistance < 4 or iDistance > 5 then return false end
  
  -- Notify script context to purchase plot
  local tParameters = {};
  tParameters.iPlayer = iPlayer;
  tParameters.iCity = iCity;
  tParameters.iPlot = iPlot;
  tParameters.OnStart = "Yaxchilan_CC_SwapTile";
  UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters);
  
  -- Play UI sound
  UI.PlaySound("Purchase_Tile");
  
  -- Always return true, since we can't get any feedback from the cross context call.
  -- However, the validation checks should be sufficient.
  return true;
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoGetGoldCostInfo
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoGetGoldCostInfo(pPlayer)

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
    local iOwner = GameEffects.GetModifierOwner(iModifier);
    local iModifierPlayer = GameEffects.GetObjectsPlayerId(iOwner);
    if pPlayer:GetID() == iModifierPlayer then
      local pModifier = GameEffects.GetModifierDefinition(iModifier);
      if pModifier ~= nil then
        -- Plot purchase
        if pModifier.ModifierType == 'MODIFIER_PLAYER_CITIES_ADJUST_PLOT_PURCHASE_COST' then
          for kArgs in GameInfo.ModifierArguments() do
            if kArgs.ModifierId == pModifier.ModifierId and kArgs.Name == 'Amount' then
              local iModScaling = (100 + kArgs.Value) / 100;
              iModifierScaling = iModifierScaling * iModScaling;
            end
          end
        -- Plot terrain purchase
        elseif pModifier.ModifierType == 'MODIFIER_PLAYER_CITIES_ADJUST_PLOT_PURCHASE_COST_TERRAIN' then
          tTerrainModifierScalings[pModifier.ModifierId] = {};
          for kArgs in GameInfo.ModifierArguments() do
            if kArgs.ModifierId == pModifier.ModifierId then
              if kArgs.Name == 'Amount' then
                tTerrainModifierScalings[pModifier.ModifierId]['Multiplier'] = (100 + kArgs.Value) / 100;
              elseif kArgs.Name == 'TerrainType' then
                local tTerrain = GameInfo.Terrains[kArgs.Value];
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
-- YaxchilanPlotInfoGetPlotGoldCost
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoGetPlotGoldCost(iGoldCostPerDistance, tTerrainModifierScalings, pCity, pPlot)
  local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY());
  local iGoldCost = iDistance * iGoldCostPerDistance;
  for iModifierId, tArgs in pairs(tTerrainModifierScalings) do
    local iTerrainType = tArgs['TerrainTypeId'];
    local iMultiplier = tArgs['Multiplier'];
    if iTerrainType ~= nil and iMultiplier ~= nil then
      if pPlot:GetTerrainType() == iTerrainType then
        iGoldCost = iGoldCost * iMultiplier;
      end
    end
  end
  return math.floor(iGoldCost);
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoShowOuterRingPurchases
-- Update outer ring purchases. This is only called when the city management 
-- UI lens is already selected.
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoShowOuterRingPurchases()
  
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
  
  -- Validate city has NBH TE
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  
  -- Get player info
	local iPlayerGold	:number = pPlayer:GetTreasury():GetGoldBalance();
  local iGoldCostPerDistance, tTerrainModifierScalings = YaxchilanPlotInfoGetGoldCostInfo(pPlayer);
  
  -- Get unowned plots in outer rings
  local tUnownedOuterRingPlots = YaxchilanGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), -1, nil, 4, 5);
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
    table.insert(m_YaxchilanUiPurchasableCityPlotsLensMask, iPlot);
    -- Add icon
    local pInstance = YaxchilanPlotInfoGetOuterRingInstanceAt(iPlot);
    if pInstance ~= nil then
      -- Gold cost
      local iGoldCost = YaxchilanPlotInfoGetPlotGoldCost(iGoldCostPerDistance, tTerrainModifierScalings, pCity, pPlot);
      pInstance.PurchaseButton:SetText(tostring(iGoldCost));
      -- Button
      AutoSizeGridButton(pInstance.PurchaseButton,51,30,25,"H");
      pInstance.PurchaseButton:SetDisabled( iGoldCost > iPlayerGold );
      if ( iGoldCost > iPlayerGold ) then
        pInstance.PurchaseButton:GetTextControl():SetColorByName("TopBarValueCS");
      else
        pInstance.PurchaseButton:GetTextControl():SetColorByName("ResGoldLabelCS");
      end
      pInstance.PurchaseButton:RegisterCallback( Mouse.eLClick, function() YaxchilanPlotInfoOnClickPurchasePlot( iPlot, iGoldCost ); end );
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
			table.insert(m_YaxchilanUiPurchase, pInstance);
    end    
  end
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoHideOuterRingPurchases
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoHideOuterRingPurchases()
	for _, pInstance in pairs(m_YaxchilanUiPurchase) do
		pInstance.PurchaseButton:SetHide( true );
    -- Note: Instances are removed by worker plot function
	end
  m_YaxchilanUiPurchase = {};
  m_YaxchilanUiPurchasableCityPlotsLensMask = {};
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoShowOuterRingSwapTiles
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoShowOuterRingSwapTiles()
  
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
  
  -- Validate city has NBH TE
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  
  -- Get swappable outer ring tiles
  local tSwappableOuterRingPlots = YaxchilanGetRingPlotsByDistanceAndOwner(pCity:GetX(), pCity:GetY(), iPlayer, iCity, 4, 5, true);
  if tSwappableOuterRingPlots == nil or table.count(tSwappableOuterRingPlots) == 0 then return end
  
  -- Show swap icons
  for _,pPlot in pairs(tSwappableOuterRingPlots) do
    local iPlot = pPlot:GetIndex();
    -- Validate not in inner 2 rings of owned city
    local bPlotIsInInner2RingsOfOwnedCity = true;
    local pWorkingCity = Cities.GetPlotPurchaseCity(iPlot);
    if pWorkingCity ~= nil then
      local iDistance : number = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pWorkingCity:GetX(), pWorkingCity:GetY());
      bPlotIsInInner2RingsOfOwnedCity = iDistance <= 2;
    end
    if not bPlotIsInInner2RingsOfOwnedCity then
      -- Add to lens hexes
      table.insert(m_YaxchilanUiSwapTilesCityPlotsLensMask, iPlot);
      -- Add icon
      local pInstance = YaxchilanPlotInfoGetOuterRingInstanceAt(iPlot);
      if pInstance ~= nil then
          pInstance.SwapTileOwnerButton:SetVoid1(iPlot);
          pInstance.SwapTileOwnerButton:RegisterCallback(Mouse.eLClick, function() YaxchilanPlotInfoOnClickSwapTile( iPlot ); end );
          pInstance.SwapTileOwnerButton:SetHide(false);
          pInstance.SwapTileOwnerButton:SetSizeX(pInstance.SwapLabel:GetSizeX() + PADDING_SWAP_BUTTON);
          table.insert( m_YaxchilanUiSwapTiles, pInstance );
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoHideOuterRingSwapTiles
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoHideOuterRingSwapTiles()
  for _,pInstance in ipairs(m_YaxchilanUiSwapTiles) do
		pInstance.SwapTileOwnerButton:SetHide( true );
    -- Note: Instances are removed by worker plot function
	end
	m_YaxchilanUiSwapTiles = {};
	m_YaxchilanUiSwapTilesCityPlotsLensMask = {};
end



-- ===========================================================================
-- OVERRIDES
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CACHE ORIGINAL
-- ---------------------------------------------------------------------------
-- Plot yields
YaxchilanOriginal_GetPlotYields = GetPlotYields;
-- Citizens
YaxchilanOriginal_ShowCitizens = ShowCitizens;
YaxchilanOriginal_HideCitizens = HideCitizens;
YaxchilanOriginal_OnClickCitizen = OnClickCitizen;
-- Purchase tiles
YaxchilanOriginal_ShowPurchases = ShowPurchases;
YaxchilanOriginal_HidePurchases = HidePurchases;
-- Swap tiles
YaxchilanOriginal_ShowSwapTiles = ShowSwapTiles;
YaxchilanOriginal_HideSwapTiles = HideSwapTiles;
-- Lens hexes
YaxchilanOriginal_AggregateLensHexes = AggregateLensHexes;
-- Cleanup
YaxchilanOriginal_ClearEverything = ClearEverything;

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
    tYieldSums = pPlot:GetProperty(YAXCHILAN_PROPERTY_YIELDS_WITH_COMPENSATIONS);
  end
  -- Get yields
  if tYieldSums ~= nil then
    return YaxchilanPlotInfoGetPlotYieldsWithWorkerCompensations(iPlot, tYields, tYieldSums);
  else
    return YaxchilanOriginal_GetPlotYields(iPlot, tYields);
  end
end

-- ---------------------------------------------------------------------------
-- ShowCitizens
-- Overwrites original PlotInfo.ShowCitizens function.
-- Show outer ring workers in city management UI lens.
-- ---------------------------------------------------------------------------
function ShowCitizens()
  -- Call original
  YaxchilanOriginal_ShowCitizens();
  -- Update NBH specialists
  YaxchilanPlotInfoUpdateNbhCitizens();
  -- Show outer ring workers
  YaxchilanPlotInfoShowOuterRingCitizens();
end

-- ---------------------------------------------------------------------------
-- HideCitizens
-- Overwrites original PlotInfo.HideCitizens function.
-- Hide outer ring workers in city management UI lens.
-- ---------------------------------------------------------------------------
function HideCitizens()
  -- Call original
  YaxchilanOriginal_HideCitizens();
  -- Hide outer ring workers
  YaxchilanPlotInfoHideOuterRingCitizens();
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
  local bCanToggleCitizenPlot = YaxchilanCanToggleCitizenPlot(iPlayer, iCity, iPlot, true);
  if not bCanToggleCitizenPlot then return false end
  -- Call original
	return YaxchilanOriginal_OnClickCitizen(iPlot);
end

-- ---------------------------------------------------------------------------
-- ShowPurchases
-- Overwrites original PlotInfo.ShowPurchases function.
-- Show unowned outer ring plots in city management UI lens.
-- ---------------------------------------------------------------------------
function ShowPurchases()
  -- Call original
  YaxchilanOriginal_ShowPurchases();
  -- Show outer ring workers
  YaxchilanPlotInfoShowOuterRingPurchases();
end

-- ---------------------------------------------------------------------------
-- HidePurchases
-- Overwrites original PlotInfo.HidePurchases function.
-- Hide unowned outer ring plots in city management UI lens.
-- ---------------------------------------------------------------------------
function HidePurchases()
  -- Call original
  YaxchilanOriginal_HidePurchases();
  -- Hide outer ring workers
  YaxchilanPlotInfoHideOuterRingPurchases();
end

-- ---------------------------------------------------------------------------
-- ShowSwapTiles
-- Overwrites original PlotInfo.ShowSwapTiles function.
-- Show outer ring swap tiles.
-- ---------------------------------------------------------------------------
function ShowSwapTiles()
  -- Call original
  YaxchilanOriginal_ShowSwapTiles();
  -- Show outer ring swap tiles
  YaxchilanPlotInfoShowOuterRingSwapTiles();
end

-- ---------------------------------------------------------------------------
-- HideSwapTiles
-- Overwrites original PlotInfo.HideSwapTiles function.
-- Hide outer ring swap tiles.
-- ---------------------------------------------------------------------------
function HideSwapTiles()
  -- Call original
  YaxchilanOriginal_HideSwapTiles();
  -- Hide outer ring swap tiles
  YaxchilanPlotInfoHideOuterRingSwapTiles();
end

-- ---------------------------------------------------------------------------
-- AggregateLensHexes
-- Overwrites original PlotInfo.AggregateLensHexes function.
-- Add outer ring worker plot ids to lens hexes list.
-- This means that they won't be shadowed.
-- ---------------------------------------------------------------------------
function AggregateLensHexes( tKeys : table )
  -- Call original
  local tResults : table = YaxchilanOriginal_AggregateLensHexes(tKeys);
  -- Add outer ring plots to lens hexes
  for i, iPlot in pairs(m_YaxchilanUiWorkableCityPlotsLensMask) do
    table.insert(tResults, iPlot);
  end
  -- Add unowned outer ring plots to lens hexes
  for i, iPlot in pairs(m_YaxchilanUiPurchasableCityPlotsLensMask) do
    table.insert(tResults, iPlot);
  end
  -- Add swappable outer ring plots to lens hexes
  for i, iPlot in pairs(m_YaxchilanUiSwapTilesCityPlotsLensMask) do
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
  YaxchilanOriginal_ClearEverything();
  -- Clear outer ring worker instances
  for key,pInstance in pairs(m_YaxchilanUiCitizens) do
		pInstance.Anchor:SetHide(true);
		m_YaxchilanPlotIM:ReleaseInstance(pInstance);
		m_YaxchilanUiCitizens[key] = nil;
	end
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoRefreshFocus
-- Force refresh of city focus, that will also trigger city UI data refresh.
-- Currently unused.
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoRefreshFocus(pCity)
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
-- YaxchilanPlotInfoOuterRingSpecialistsChanged
-- ---------------------------------------------------------------------------
local function YaxchilanPlotInfoOuterRingSpecialistsChanged( tParameters : table )
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
    YaxchilanPlotInfoRefreshFocus(pCity);
  end
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoInitialize
-- ---------------------------------------------------------------------------
local function YaxchilanPlotInfoInitialize()
  -- Register custom events
  LuaEvents.YaxchilanOuterRingSpecialistsChanged.Add( YaxchilanPlotInfoOuterRingSpecialistsChanged );
  -- Log init
  print("PlotInfo_Yaxchilan.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
YaxchilanPlotInfoInitialize();