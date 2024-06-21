-- ===========================================================================
-- DistrictPlotIconManager UI
-- ===========================================================================



-- ===========================================================================
-- INCLUDES
-- ===========================================================================
-- Original
local tBaseFileVersions = {
    "districtploticonmanager_CQUI",  -- CQUI
    "DistrictPlotIconManager"        -- Base Game and Expansions
};
for _, sVersion in ipairs(tBaseFileVersions) do
  include(sVersion);
  if Initialize then break end
end
-- Build support for outer rings
include( "BuildOnOuterRingSupport" );



-- ===========================================================================
-- OVERWRITES
-- ===========================================================================

-- ---------------------------------------------------------------------------
CypWorOriginal_ClearEveything = ClearEveything;
-- ---------------------------------------------------------------------------
-- ClearEveything
-- ---------------------------------------------------------------------------
function ClearEveything()
  -- Clear plot adjacency cache
  if not ExposedMembers.CypWor then ExposedMembers.CypWor = {} end
  ExposedMembers.CypWor.DistrictYieldChangeIds = {};
  ExposedMembers.CypWor.PlotDistrictDirectionAdjacencyTypeCache = {};
  ExposedMembers.CypWor.PlotDistrictAdjacencyYieldBonusCache = {};
  -- Original
  CypWorOriginal_ClearEveything();
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================
print("DistrictPlotIconManager_CypWor.lua initialized!");