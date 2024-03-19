-- ===========================================================================
-- Plotinfo Citizens UI from Sukritacts Simple UI Adjustments
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Utility
include "CypWor_Utility.lua"
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
-- CypWorPlotInfoCitizensGetCity
-- ---------------------------------------------------------------------------
function CypWorPlotInfoCitizensGetCity( iPlayer : number, iCity : number )
  
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
CypWorOriginal_ShowCityYields = ShowCityYields;

-- ---------------------------------------------------------------------------
-- ShowCityYields
-- ---------------------------------------------------------------------------
function ShowCityYields( tPlots : table )

  -- Get city
  local iPlayer = m_hoveredCityPlayerId;
  local iCity = m_hoveredCityId;
  local pCity = CypWorPlotInfoCitizensGetCity(iPlayer, iCity);
  if pCity == nil then return end
  
  -- Merge inner and outer ring plots
  local tOuterRingPlotsData : table = pCity:GetProperty(CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA);
  if tOuterRingPlotsData ~= nil and table.count(tOuterRingPlotsData) > 0 then return end
  for iPlot, _ in pairs(tOuterRingPlotsData) do
    table.insert(tPlots, iPlot);
  end

  -- Call original
  CypWorOriginal_ShowCityYields(tPlots);
end



-- ===========================================================================
-- FUNCTIONS (show citizens)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoCitizensHideDistrict
-- ---------------------------------------------------------------------------
function CypWorPlotInfoCitizensHideDistrict( pCity )
  -- Validate city has WOR district
  if not CypWorDistrictExists(pCity) then return end
  local iCypWorPlot = CypWorDistrictPlotId(pCity);
  -- Hide instance
  local pInstance = GetInstanceAt(iCypWorPlot);
  if pInstance == nil then return end
	pInstance.Anchor:SetHide(true);
end

-- ---------------------------------------------------------------------------
-- CypWorPlotInfoCitizensShowOuterRingCitizens
-- ---------------------------------------------------------------------------
function CypWorPlotInfoCitizensShowOuterRingCitizens( pCity )
  
  -- Get outer ring plot data
  local tOuterRingPlotsData : table = pCity:GetProperty(CYP_WOR_PROPERTY_OUTER_RING_PLOTS_DATA);
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
CypWorOriginal_ShowCitizens = ShowCitizens;

-- ---------------------------------------------------------------------------
-- ShowCitizens
-- ---------------------------------------------------------------------------
function ShowCitizens( iPlayer : number, iCity : number )
  -- Call original
  m_hoveredCityPlayerId = iPlayer;
  m_hoveredCityId = iCity;
  CypWorOriginal_ShowCitizens(iPlayer, iCity);
  -- Get city
  local pCity = CypWorPlotInfoCitizensGetCity(iPlayer, iCity);
  if pCity == nil then return end
  -- Hide WOR citizens
  CypWorPlotInfoCitizensHideDistrict(pCity);
  -- Show outer ring workers
  CypWorPlotInfoCitizensShowOuterRingCitizens(pCity);
end

-- Log init
print("PlotInfo_Citizens_CypWor.lua initialized!");