-- Text
--------------------------------------------------------------

--------------------------------------------------------------
-- Yaxchilan
--------------------------------------------------------------
-- LocalizedText
INSERT INTO "LocalizedText" ("Language", "Tag", "Text") VALUES
('en_US',       'LOC_CYP_WOR_YAXCHILAN', "Yaxchilan"),
('ja_JP',       'LOC_CYP_WOR_YAXCHILAN', "ヤシュチラン"),
('zh_Hant_HK',  'LOC_CYP_WOR_YAXCHILAN', "亞斯奇蘭"),
('zh_Hans_CN',  'LOC_CYP_WOR_YAXCHILAN', "亚斯奇兰");
-- LocalizedText (update)
UPDATE "LocalizedText"
SET Text = '{LOC_CYP_WOR_YAXCHILAN}'
WHERE Tag IN ('LOC_CYP_WOR_MOD_NAME_SIMPLE', 'LOC_DISTRICT_CYP_WOR_NAME');
-- colored
UPDATE "LocalizedText"
SET Text = '[COLOR_FLOAT_FOOD]{LOC_CYP_WOR_YAXCHILAN}[ENDCOLOR]'
WHERE Tag IN ('LOC_CYP_WOR_MOD_NAME_COLOR');