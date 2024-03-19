-- Suk_PlotTooltips.lua
-- Author: Sukritact
-- DateCreated: 4/10/2022 11:39:50 PM
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
local tBaseFiles = {
	"plottooltip_CQUI_expansion2.lua",
	"PlotTooltip_Expansion2.lua",
}

for _,sVersion in ipairs(tBaseFiles) do
	include(sVersion)
	if Initialize then
		print("--------- Suk_PlotToolTips ---------")
		print('Loading ' .. sVersion .. " as base file")
		print("-------------------------------------------")
		break
	end
end
-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local Old_FetchData = FetchData
-- ===========================================================================
-- OVERRIDE BASE FUNCTIONS
-- ===========================================================================
function FetchData(pPlot)
	local data = Old_FetchData(pPlot)

	local kRivers = RiverManager.GetRiverTypes(pPlot);
	if kRivers and table.count(kRivers) > 0 then

		local eFloodpainRiver = RiverManager.GetRiverForFloodplain(pPlot:GetX(), pPlot:GetY())

		data.RiverNames = {}

		for _,eRiver in pairs(kRivers) do
			local szRiverName = RiverManager.GetRiverNameByType(eRiver)
			if szRiverName and eFloodpainRiver == eRiver then
				szRiverName = szRiverName .. "[ICON_You]"
			end
			table.insert(data.RiverNames, szRiverName);
		end

		data.RiverNames = "[NEWLINE][ICON_Bullet]"..table.concat(data.RiverNames, "[NEWLINE][ICON_Bullet]")
	end

	return data
end
-- ===========================================================================
-- ===========================================================================