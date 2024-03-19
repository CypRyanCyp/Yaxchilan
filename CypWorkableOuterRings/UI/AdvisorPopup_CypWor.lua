-- ===========================================================================
-- Yaxchilan
-- Description: Show Yaxchilan advisor just once.
-- ===========================================================================



-- ===========================================================================
-- IMPORTS
-- ===========================================================================
include "SupportFunctions.lua";
include "GameCapabilities.lua";
include "Civ6Common.lua";
include "AdvisorPopup";



-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
-- Options
local CYPWOR_USEROPTIONS_YAXCHILAN_CATEGORY = 'Tutorial';
local CYPWOR_USEROPTIONS_YAXCHILAN_KEY = 'YAXCHILAN_5';
-- Audio
local CYPWOR_AUDIO_YAXCHILAN_PREFIX = 'CYP_WOR_YAXCHILAN_';
local CYPWOR_AUDIO_YAXCHILAN_START = CYPWOR_AUDIO_YAXCHILAN_PREFIX .. 'START';
local CYPWOR_AUDIO_YAXCHILAN_STOP = CYPWOR_AUDIO_YAXCHILAN_PREFIX .. 'STOP';
-- AdvisorItem
hstructure AdvisorItem
	Message			: string;		-- TXT key to look up for advisor message (if raised via an advisor)
	MessageAudio	: string;		-- Name of the accompanying audio to play with the message.
	Image			: string;		-- (optional) Name of texture used in image.
	OptionsNum		: number;		-- Number of options.
	Button1Text		: string;		-- TXT key to look up for button 1
	Button2Text		: string;		-- " " " 2
	Button1Func		: ifunction;	-- Callback on button 1
	Button2Func		: ifunction;	-- " " " 2
	CalloutHeader	: string;		-- TXT key to look up for callout header
	CalloutBody		: string;		-- TXT key to look up for callout body
	PlotCallback	: ifunction;	-- Function to return the ID of a world plot to which dialog will be anchored
	ShowPortrait	: boolean;		-- Whether or not the advisor portrait should appear in the dialog (expected when VO is played)
	UITriggers		: table;		-- IDs and/or Trigger names for the UI when advisor item is up.
end


-- ===========================================================================
-- FUNCTIONS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWtAdvisorPopupShow
-- ---------------------------------------------------------------------------
local function CypWtAdvisorPopupShow()
  local sYax = Locale.Lookup('LOC_CYP_WOR_YAXCHILAN');
  print(sYax);
  -- Add notification
  NotificationManager.SendNotification(iPlayer, NotificationTypes.USER_DEFINED_1, sYax, sYax);
  -- Create advisor data
  local sAudioStart = CYPWOR_AUDIO_YAXCHILAN_PREFIX .. 'START';
  local fButton = function( advisorInfo )
                    UI.PlaySound(CYPWOR_AUDIO_YAXCHILAN_STOP);
                    LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
                  end
  local oAdvisorData = hmake AdvisorItem {
    Message			  = sYax,           -- TXT key to look up for advisor message (if raised via an advisor)
    MessageAudio	= CYPWOR_AUDIO_YAXCHILAN_START,   -- Name of the accompanying audio to play with the message.
    Image         = nil,            -- (optional) Name of texture used in image.
    OptionsNum		= 2,              -- Number of options.
    Button1Text		= sYax,           -- TXT key to look up for button 1
    Button2Text		= sYax,           -- " " " 2
    Button1Func		= fButton,        -- Callback on button 1
    Button2Func		= fButton,        -- " " " 2
    CalloutHeader = nil,            -- TXT key to look up for callout header
    CalloutBody		= nil,            -- TXT key to look up for callout body
    PlotCallback	= nil,            -- Function to return the ID of a world plot to which dialog will be anchored
    ShowPortrait	= true,           -- Whether or not the advisor portrait should appear in the dialog (expected when VO is played)
    UITriggers		= {}              -- IDs and/or Trigger names for the UI when advisor item is up.
  };
  -- Show or queue 
  ShowOrQueuePopup(oAdvisorData);
  
end

-- ---------------------------------------------------------------------------
-- CypWtAdvisorPopupCheck
-- ---------------------------------------------------------------------------
local function CypWtAdvisorPopupCheck()
  local iVal = Options.GetUserOption(CYPWOR_USEROPTIONS_YAXCHILAN_CATEGORY, CYPWOR_USEROPTIONS_YAXCHILAN_KEY);
  print("iVal", iVal);
  if iVal == 1 then return end
  -- TODO CYP
  Options.SetUserOption(CYPWOR_USEROPTIONS_YAXCHILAN_CATEGORY, CYPWOR_USEROPTIONS_YAXCHILAN_KEY, 1);
  Options.SaveOptions();
  local iVal = Options.GetUserOption(CYPWOR_USEROPTIONS_YAXCHILAN_CATEGORY, CYPWOR_USEROPTIONS_YAXCHILAN_KEY);
  print("iVal", iVal);
  CypWtAdvisorPopupShow();
end



-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- CypWorPopupMain
-- ---------------------------------------------------------------------------
local function CypWtAdvisorPopupInitialize()
  Events.LoadScreenClose.Add(CypWtAdvisorPopupCheck);
  print("AdvisorPopup_CypWor.lua initialized!");
end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
CypWtAdvisorPopupInitialize();