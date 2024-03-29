-- Suk_CityPanelOverview
-- Author: Sukritact
-- DateCreated: 12/1/2020 2:17:17 AM
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
local tCityBannerVersions = {
	"CityPanelOverview_Expansion2.lua",
	"CityPanelOverview_Expansion1.lua",
	"CityPanelOverview.lua",
}

for _,sVersion in ipairs(tCityBannerVersions) do
	include(sVersion)
	if Initialize then
		print("--------- Suk_CityPanelOverview ---------")
		print('Loading ' .. sVersion .. " as base file")
		print("-------------------------------------------")
		break
	end
end
-- ===========================================================================
-- ===========================================================================
m_kTradingPostsIM		= InstanceManager:new("TradingPostInstance", "Top", Controls.TradingPostsStack);

function ViewPanelBreakdown( data:table )
	local playerID = Game.GetLocalPlayer();

	Controls.DistrictsNum:SetText( data.DistrictsNum );
	Controls.DistrictsConstructed:SetText( Locale.Lookup("LOC_HUD_CITY_DISTRICTS_CONSTRUCTED", data.DistrictsNum) );
	Controls.DistrictsPossibleNum:SetText( data.DistrictsPossibleNum );
	---------------------------------------
	-- Add buildings and districts
	---------------------------------------
	LuaEvents.Suk_CityPanelOverview_Districts(playerID, data)
	---------------------------------------
	-- Add wonders
	---------------------------------------
	local hideWondersInfo :boolean = not GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_WONDERS");
	local isHasWonders :boolean = (table.count(data.Wonders) > 0)
	Controls.NoWondersArea:SetHide(hideWondersInfo or isHasWonders);
	Controls.WondersArea:SetHide(hideWondersInfo or not isHasWonders);
	Controls.WondersHeader:SetHide(hideWondersInfo);

	LuaEvents.Suk_CityPanelOverview_Wonders(
		playerID,
		data,
		((not hideWondersInfo) and isHasWonders)
	)
	---------------------------------------
	-- Add trading posts
	---------------------------------------
	m_kTradingPostsIM:ResetInstances();

	local hideTradingPostsInfo :boolean = not GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_TRADING_POSTS");
	local isHasTradingPosts :boolean = (table.count(data.TradingPosts) > 0);
	Controls.NoTradingPostsArea:SetHide(hideTradingPostsInfo or isHasTradingPosts);
	Controls.TradingPostsArea:SetHide(hideTradingPostsInfo or not isHasTradingPosts);
	Controls.TradingPostsHeader:SetHide(hideTradingPostsInfo);

	if isHasTradingPosts then
		for _, tradePostPlayerId in ipairs(data.TradingPosts) do
			local pTradePostPlayer:table = Players[tradePostPlayerId]
			local pTradePostPlayerConfig:table = PlayerConfigurations[tradePostPlayerId];
			local kInstanceTradingPost	:table = m_kTradingPostsIM:GetInstance();
			local playerName			:string = Locale.Lookup( pTradePostPlayerConfig:GetPlayerName() );

			local iconName:string = "";
			local iconSize:number = SIZE_LEADER_ICON;
			local iconColor = UI.GetColorValue("COLOR_WHITE");
			if pTradePostPlayer:IsMinor() then
				-- If we're a city-state display our city-state icon instead of leader since we don't have one
				local civType:string = pTradePostPlayerConfig:GetCivilizationTypeName();
				local primaryColor, secondaryColor = UI.GetPlayerColors(tradePostPlayerId);
				iconName = "ICON_"..civType;
				iconColor = secondaryColor;
				iconSize = SIZE_CITYSTATE_ICON;
			else
				iconName = "ICON_"..pTradePostPlayerConfig:GetLeaderTypeName();
			end

			local textureOffsetX :number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(iconName, iconSize);
			kInstanceTradingPost.LeaderPortrait:SetIcon(iconName);
			kInstanceTradingPost.LeaderPortrait:SetColor(iconColor);
			kInstanceTradingPost.LeaderPortrait:SetHide(false);

			if tradePostPlayerId == playerID then
				playerName = playerName .. " (" .. Locale.Lookup("LOC_HUD_CITY_YOU") .. ")";
			end
			kInstanceTradingPost.TradingPostName:SetText( playerName );
		end
	end
end
-- ===========================================================================
-- ===========================================================================