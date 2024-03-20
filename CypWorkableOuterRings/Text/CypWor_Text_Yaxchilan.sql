-- Text
--------------------------------------------------------------

--------------------------------------------------------------
-- Yaxchilan
--------------------------------------------------------------
-- LocalizedText
INSERT INTO "LocalizedText" ("Language", "Tag", "Text") VALUES
('en_US', 'LOC_CYP_WOR_YAXCHILAN', "Yaxchilan");
-- LocalizedText (update)
UPDATE "LocalizedText"
SET Text = 'Yaxchilan'
WHERE Tag IN ('LOC_CYP_WOR_MOD_NAME_SIMPLE', 'LOC_DISTRICT_CYP_WOR_NAME');
UPDATE "LocalizedText"
SET Text = '[COLOR_FLOAT_FOOD]Yaxchilan[ENDCOLOR]'
WHERE Tag IN ('LOC_CYP_WOR_MOD_NAME_COLOR');