-- Text
-- GameMode: Secret Societies
--------------------------------------------------------------

--------------------------------------------------------------
-- LocalizedText
--------------------------------------------------------------
-- Add note to vampire castle
--- en_US
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || 'Does not work when adjacent to {LOC_DISTRICT_CYP_WOR_NAME}.'
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'en_US';
--- de_DE
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || 'Funktioniert nicht, wenn angrenzend an {LOC_DISTRICT_CYP_WOR_NAME}.'
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'de_DE';
--- fr_FR
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || "Ne fonctionne pas lorsqu'il est adjacent à {LOC_DISTRICT_CYP_WOR_NAME}."
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'fr_FR';
--- pt_BR
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || 'Não funciona quando adjacente a {LOC_DISTRICT_CYP_WOR_NAME}.'
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'pt_BR';
--- es_ES
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || 'No funciona cuando es adyacente a {LOC_DISTRICT_CYP_WOR_NAME}.'
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'es_ES';
--- it_IT
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || 'Non funziona se adiacente a {LOC_DISTRICT_CYP_WOR_NAME}.'
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'it_IT';
--- ja_JP
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || '{LOC_DISTRICT_CYP_WOR_NAME}に隣接する場合は動作しません。'
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'ja_JP';
--- zh_Hant_HK
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || '与{LOC_DISTRICT_CYP_WOR_NAME}相邻时不起作用。'
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'zh_Hant_HK';
--- zh_Hans_CN
UPDATE "LocalizedText" 
SET Text = Text || '[NEWLINE]' || '与{LOC_DISTRICT_CYP_WOR_NAME}相邻时不起作用。'
WHERE Tag = 'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
AND Language = 'zh_Hans_CN';