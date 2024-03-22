-- Text
--------------------------------------------------------------

--------------------------------------------------------------
-- Yaxchilan
--------------------------------------------------------------
-- LocalizedText
INSERT INTO "LocalizedText" ("Language", "Tag", "Text") VALUES
('en_US', 'LOC_CYP_WOR_YAXCHILAN', "Yaxchilan");
-- LocalizedText (update)
--- en, de, ...
UPDATE "LocalizedText"
SET Text = 'Yaxchilan'
WHERE Tag IN ('LOC_CYP_WOR_MOD_NAME_SIMPLE', 'LOC_DISTRICT_CYP_WOR_NAME')
AND Language NOT IN ('zh_Hant_HK', 'zh_Hans_CN');
--- zh
UPDATE "LocalizedText"
SET Text = '亚斯奇兰'
WHERE Tag IN ('LOC_CYP_WOR_MOD_NAME_SIMPLE', 'LOC_DISTRICT_CYP_WOR_NAME')
AND Language IN ('zh_Hant_HK', 'zh_Hans_CN');
-- colored
UPDATE "LocalizedText"
SET Text = '[COLOR_FLOAT_FOOD]{LOC_CYP_WOR_MOD_NAME_SIMPLE}[ENDCOLOR]'
WHERE Tag IN ('LOC_CYP_WOR_MOD_NAME_COLOR');