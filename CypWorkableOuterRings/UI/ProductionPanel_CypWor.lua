-- ===========================================================================
-- ProductionPanel UI
-- ===========================================================================



-- ===========================================================================
-- IMPORTS
-- ===========================================================================
-- Original
local tBaseFileVersions = {
  "ProductionPanel_CypWt.lua",
  "productionpanel_CQUI.lua", -- CQUI
  "ProductionPanel_Babylon_Heroes.lua",
  "ProductionPanel.lua" -- Base Game and Expansions
};
for _, sVersion in ipairs(tBaseFileVersions) do
  include(sVersion);
  if Initialize then break end
end
-- Build support for outer rings
include "BuildOnOuterRingsSupport.lua"