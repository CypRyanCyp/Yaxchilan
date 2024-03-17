-- ===========================================================================
-- Plotinfo Citizens UI from Sukritacts Simple UI Adjustments
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "Yaxchilan_Utility.lua"
-- Original
include "PlotInfo_Citizens"



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- ICONS
local CITIZEN_BUTTON_HEIGHT		        :number = 64;



-- ===========================================================================
-- Members
-- ===========================================================================
-- Selected city
local m_hoveredCityPlayerId                   = nil;
local m_hoveredCityId                         = nil;



-- ===========================================================================
-- FUNCTIONS (utility)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoCitizensGetCity
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoCitizensGetCity( iPlayer : number, iCity : number )
  
  -- Validate is local player
	if iPlayer ~= Game.GetLocalPlayer() then return nil end
  
  -- Validate is not city management
	if UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT then return nil end

  -- Get player
	local pPlayer = Players[iPlayer];
  if pPlayer == nil then return nil end
  
  -- Get city
	local pCity = pPlayer:GetCities():FindID(iCity);
  if pCity == nil then return nil end
  
  -- Return
  return pCity;
end



-- ===========================================================================
-- FUNCTIONS (city yields)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Override
-- ---------------------------------------------------------------------------
YaxchilanOriginal_ShowCityYields = ShowCityYields;

-- ---------------------------------------------------------------------------
-- ShowCityYields
-- ---------------------------------------------------------------------------
function ShowCityYields( tPlots : table )

  -- Get city
  local iPlayer = m_hoveredCityPlayerId;
  local iCity = m_hoveredCityId;
  local pCity = YaxchilanPlotInfoCitizensGetCity(iPlayer, iCity);
  if pCity == nil then return end
  
  -- Merge inner and outer ring plots
  local tOuterRingPlotsData : table = pCity:GetProperty(YAXCHILAN_PROPERTY_OUTER_RING_PLOTS_DATA);
  if tOuterRingPlotsData ~= nil and table.count(tOuterRingPlotsData) > 0 then return end
  for iPlot, _ in pairs(tOuterRingPlotsData) do
    table.insert(tPlots, iPlot);
  end

  -- Call original
  YaxchilanOriginal_ShowCityYields(tPlots);
end



-- ===========================================================================
-- FUNCTIONS (show citizens)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoCitizensHideDistrict
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoCitizensHideDistrict( pCity )
  -- Validate city has NBH TE
  if not pCity:GetBuildings():HasBuilding(YAXCHILAN_BUILDING_ID) then return end
  local pYaxchilanDistrict = pCity:GetDistricts():GetDistrict(YAXCHILAN_DISTRICT_TYPE);
  local pYaxchilanPlot = Map.GetPlot(pYaxchilanDistrict:GetX(), pYaxchilanDistrict:GetY());
  local iYaxchilanPlot = pYaxchilanPlot:GetIndex();
  -- Hide instance
  local pInstance = GetInstanceAt(iYaxchilanPlot);
  if pInstance == nil then return end
	pInstance.Anchor:SetHide(true);
end

-- ---------------------------------------------------------------------------
-- YaxchilanPlotInfoCitizensShowOuterRingCitizens
-- ---------------------------------------------------------------------------
function YaxchilanPlotInfoCitizensShowOuterRingCitizens( pCity )
  
  -- Get outer ring plot data
  local tOuterRingPlotsData : table = pCity:GetProperty(YAXCHILAN_PROPERTY_OUTER_RING_PLOTS_DATA);
  if tOuterRingPlotsData == nil or table.count(tOuterRingPlotsData) == 0 then return end
  
  -- Show icon on each worked outer ring plot
  for iPlot, xPlotData in pairs(tOuterRingPlotsData) do
    if xPlotData.bIsWorked then
      local pInstance = GetInstanceAt(iPlot);
      if pInstance ~= nil then
        pInstance.CitizenButton:SetTextureOffsetVal(0, CITIZEN_BUTTON_HEIGHT*4);
				pInstance.CitizenButtonAnim:SetToBeginning();
				pInstance.CitizenButtonAnim:Play();
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Override
-- ---------------------------------------------------------------------------
YaxchilanOriginal_ShowCitizens = ShowCitizens;

-- ---------------------------------------------------------------------------
-- ShowCitizens
-- ---------------------------------------------------------------------------
function ShowCitizens( iPlayer : number, iCity : number )
  -- Call original
  m_hoveredCityPlayerId = iPlayer;
  m_hoveredCityId = iCity;
  YaxchilanOriginal_ShowCitizens(iPlayer, iCity);
  -- Get city
  local pCity = YaxchilanPlotInfoCitizensGetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Hide NBH citizens
  YaxchilanPlotInfoCitizensHideDistrict(pCity);
  -- Show outer ring workers
  YaxchilanPlotInfoCitizensShowOuterRingCitizens(pCity);
end

-- Log init
print("PlotInfo_Citizens_Yaxchilan.lua initialized!");