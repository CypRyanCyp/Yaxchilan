-- ===========================================================================
-- WorldInput UI
-- ===========================================================================



-- ===========================================================================
-- IMPORTS
-- ===========================================================================
-- Original
local tBaseFileVersions = {
  -- CQUI
  "worldinput_CQUI_basegame.lua",
  "worldinput_CQUI_expansion1.lua",
  "worldinput_CQUI_expansion2.lua",
  -- Base Game and Expansions
  "WorldInput_Expansion2.lua",
  "WorldInput_Expansion1.lua",
  "WorldInput.lua"
};
for _, sVersion in ipairs(tBaseFileVersions) do
  include(sVersion);
  if Initialize then break end
end
-- Build support for outer rings
include "BuildOnOuterRingsSupport.lua"