-- ===========================================================================
-- Version
-- Description: Check version and pop up notification if changed.
-- ===========================================================================



-- ===========================================================================
-- IMPORTS
-- ===========================================================================
include "SupportFunctions.lua";
include "CypWor_Utility.lua";



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- Compatible Mod Version
local CYPWOR_MOD_VERSION = '1.0';
local CYPWOR_PROPERTY_MOD_VERSION = 'CYPWOR_MOD_VERSION';



-- ===========================================================================
-- FUNCTIONS (LOGIC)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorCheckVersion
-- ---------------------------------------------------------------------------
local function CypWorCheckVersion()
  local sVersion = Game:GetProperty(CYPWOR_PROPERTY_MOD_VERSION);
  if sVersion == nil then
    Game:SetProperty(CYPWOR_PROPERTY_MOD_VERSION, CYPWOR_MOD_VERSION);
    print("Set version");
  elseif sVersion ~= CYPWOR_MOD_VERSION then
    print("Cyp's Workable Outer Rings mod versions do not match! Game started version:", sVersion, "Game loaded version:", CYPWOR_MOD_VERSION);
    local iPlayer = Game.GetLocalPlayer();
    local sMessage = 'LOC_CYP_WOR_NOTIFICATION_VERSION_COMPATIBILITY_MESSAGE';
    local sSummary = 'LOC_CYP_WOR_NOTIFICATION_VERSION_COMPATIBILITY_SUMMARY';
    NotificationManager.SendNotification(iPlayer, NotificationTypes.USER_DEFINED_1, sMessage, sSummary);
  end
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorVersionCompatibilityLateInitialize
-- Register all the events after loading is complete.
-- ---------------------------------------------------------------------------
local function CypWorVersionCompatibilityLateInitialize()
  -- Check version
  CypWorCheckVersion();
  -- Log the initialization
  print("CypWor_Version.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- CypWorVersionCompatibilityMain
-- Subscribes to the LoadScreenClose Event, which will call LateInitialize later.
-- ---------------------------------------------------------------------------
local function CypWorVersionCompatibilityMain()
  Events.LoadScreenClose.Add(CypWorVersionCompatibilityLateInitialize);
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWorVersionCompatibilityMain();