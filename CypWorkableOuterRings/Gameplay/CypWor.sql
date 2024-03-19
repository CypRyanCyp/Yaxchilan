-- District and buildings.
-- Description: Add district and buildings.
--------------------------------------------------------------

--------------------------------------------------------------
-- Workable outer ring district
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES
('DISTRICT_CYP_WOR', 'KIND_DISTRICT');
-- Districts
INSERT INTO "Districts"
("DistrictType",     "Name",                      "Description",                      "PrereqCivic",      "Cost", "RequiresPlacement",  "NoAdjacentCity", "Aqueduct", "InternalOnly", "CaptureRemovesBuildings",  "CaptureRemovesCityDefenses", "PlunderType",  "PlunderAmount",  "MilitaryDomain", "OnePerCity", "Housing",  "CostProgressionModel",           "CostProgressionParam1") VALUES 
('DISTRICT_CYP_WOR', 'LOC_DISTRICT_CYP_WOR_NAME', 'LOC_DISTRICT_CYP_WOR_DESCRIPTION', "CIVIC_FEUDALISM",  35,     1,                    1,                0,          0,              0,                          0,                            'PLUNDER_GOLD', 50,               'NO_DOMAIN',      1,            1,          'COST_PROGRESSION_GAME_PROGRESS', 1000);
-- District_TradeRouteYields
INSERT INTO "District_TradeRouteYields" 
("DistrictType",      "YieldType",  "YieldChangeAsOrigin",  "YieldChangeAsDomesticDestination", "YieldChangeAsInternationalDestination") VALUES 
('DISTRICT_CYP_WOR',  'YIELD_FOOD', '0.0',                  '1.0',                              '0.0'),
('DISTRICT_CYP_WOR',  'YIELD_GOLD', '0.0',                  '0.0',                              '1.0');
---- Adjacency_YieldChanges
--INSERT INTO "Adjacency_YieldChanges" 
--("ID",                              "Description",                                  "YieldType",        "YieldChange",  "TilesRequired", "AdjacentDistrict") VALUES 
--('WOR_HOLY_SITE',                   'LOC_WOR_DISTRICT_HOLY_SITE',                   'YIELD_FAITH',      '1',            '1',             'DISTRICT_HOLY_SITE'),
--('WOR_CAMPUS',                      'LOC_WOR_DISTRICT_CAMPUS',                      'YIELD_SCIENCE',    '1',            '1',             'DISTRICT_CAMPUS'),
--('WOR_ENCAMPMENT',                  'LOC_WOR_DISTRICT_ENCAMPMENT',                  'YIELD_PRODUCTION', '1',            '1',             'DISTRICT_ENCAMPMENT'),
--('WOR_HARBOR',                      'LOC_WOR_DISTRICT_HARBOR',                      'YIELD_FOOD',       '1',            '1',             'DISTRICT_HARBOR'),
--('WOR_AERODROME',                   'LOC_WOR_DISTRICT_AERODROME',                   'YIELD_GOLD',       '1',            '1',             'DISTRICT_AERODROME'),
--('WOR_COMMERCIAL_HUB',              'LOC_WOR_DISTRICT_COMMERCIAL_HUB',              'YIELD_GOLD',       '1',            '1',             'DISTRICT_COMMERCIAL_HUB'),
--('WOR_ENTERTAINMENT_COMPLEX',       'LOC_WOR_DISTRICT_ENTERTAINMENT_COMPLEX',       'YIELD_GOLD',       '1',            '1',             'DISTRICT_ENTERTAINMENT_COMPLEX'),
--('WOR_THEATER',                     'LOC_WOR_DISTRICT_THEATER',                     'YIELD_CULTURE',    '1',            '1',             'DISTRICT_THEATER'),
--('WOR_INDUSTRIAL_ZONE',             'LOC_WOR_DISTRICT_INDUSTRIAL_ZONE',             'YIELD_PRODUCTION', '1',            '1',             'DISTRICT_INDUSTRIAL_ZONE'),
--('WOR_WATER_ENTERTAINMENT_COMPLEX', 'LOC_WOR_DISTRICT_WATER_ENTERTAINMENT_COMPLEX', 'YIELD_GOLD',       '1',            '1',             'DISTRICT_WATER_ENTERTAINMENT_COMPLEX'),
--('WOR_PRESERVE',                    'LOC_WOR_DISTRICT_PRESERVE',                    'YIELD_FOOD',       '1',            '1',             'DISTRICT_PRESERVE'),
---- District_Adjacencies
--INSERT INTO "District_Adjacencies" ("DistrictType", "YieldChangeId") VALUES 
--('DISTRICT_CYP_WOR', 'WOR_HOLY_SITE'),
--('DISTRICT_CYP_WOR', 'WOR_CAMPUS'),
--('DISTRICT_CYP_WOR', 'WOR_ENCAMPMENT'),
--('DISTRICT_CYP_WOR', 'WOR_HARBOR'),
--('DISTRICT_CYP_WOR', 'WOR_AERODROME'),
--('DISTRICT_CYP_WOR', 'WOR_COMMERCIAL_HUB'),
--('DISTRICT_CYP_WOR', 'WOR_ENTERTAINMENT_COMPLEX'),
--('DISTRICT_CYP_WOR', 'WOR_THEATER'),
--('DISTRICT_CYP_WOR', 'WOR_INDUSTRIAL_ZONE'),
--('DISTRICT_CYP_WOR', 'WOR_WATER_ENTERTAINMENT_COMPLEX'),
--('DISTRICT_CYP_WOR', 'WOR_PRESERVE');

--------------------------------------------------------------
-- Workable outer ring buildings
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES
('BUILDING_CYP_WOR_CUSTOMS_HOUSE', 'KIND_BUILDING'),
('BUILDING_CYP_WOR_LOGISTICS_CENTER', 'KIND_BUILDING');
-- Buildings
INSERT INTO "Buildings" 
("BuildingType",                      "Name",                                       "Description",                                        "Cost", "PrereqDistrict",   "PrereqCivic")  VALUES
('BUILDING_CYP_WOR_CUSTOMS_HOUSE',    'LOC_BUILDING_CYP_WOR_CUSTOMS_HOUSE_NAME',    'LOC_BUILDING_CYP_WOR_CUSTOMS_HOUSE_DESCRIPTION',     100,    'DISTRICT_CYP_WOR', "CIVIC_URBANIZATION"),
('BUILDING_CYP_WOR_LOGISTICS_CENTER', 'LOC_BUILDING_CYP_WOR_LOGISTICS_CENTER_NAME', 'LOC_BUILDING_CYP_WOR_LOGISTICS_CENTER_DESCRIPTION',  100,    'DISTRICT_CYP_WOR', "CIVIC_CAPITALISM");

--------------------------------------------------------------
-- Temporary list for binary digits
--------------------------------------------------------------
-- CypWorTmpBinaryDigits
CREATE TABLE IF NOT EXISTS "CypWorTmpBinaryDigits" (
  "BinaryDigit"     INTEGER,
  "DecimalValue"    INTEGER
);
INSERT INTO "CypWorTmpBinaryDigits" ("BinaryDigit", "DecimalValue") VALUES
(1, 1), 
(2, 2), 
(3, 4), 
(4, 8), 
(5, 16), 
(6, 32), 
(7, 64), 
(8, 128), 
(9, 256), 
(10, 512), 
(11, 1024);

--------------------------------------------------------------
-- Table for UI invisible buildings.
--------------------------------------------------------------
-- CypWtUiInvisibleBuildings
CREATE TABLE IF NOT EXISTS "CypWtUiInvisibleBuildings" (
	"BuildingType"	    VARCHAR(255) NOT NULL,
  "Name"	            VARCHAR(255) NOT NULL
);

--------------------------------------------------------------
-- Specialists internal yield building
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES
('BUILDING_CYP_WOR', 'KIND_BUILDING');
-- Buildings
INSERT INTO "Buildings" ("BuildingType", "Name", "Cost", "PrereqDistrict", "Description", "CitizenSlots", "InternalOnly")  VALUES
('BUILDING_CYP_WOR', 'LOC_BUILDING_CYP_WOR_NAME', 999, 'DISTRICT_CYP_WOR', 'LOC_BUILDING_CYP_WOR_DESCRIPTION', 0, 1);
-- Building_CitizenYieldChanges
INSERT INTO "Building_CitizenYieldChanges" ("BuildingType", "YieldType", "YieldChange")
SELECT  'BUILDING_CYP_WOR'                  "BuildingType",
        y.YieldType                         "YieldType", 
        20                                  "YieldChange"
FROM Yields y;
-- CypWtUiInvisibleBuildings
INSERT INTO "CypWtUiInvisibleBuildings" ("BuildingType", "Name") VALUES
('BUILDING_CYP_WOR', 'LOC_BUILDING_CYP_WOR_NAME');
-- CivilopediaPageExcludes
INSERT INTO "CivilopediaPageExcludes" ("SectionId", "PageId") VALUES
('BUILDINGS', 'BUILDING_CYP_WOR');

--------------------------------------------------------------
-- Yield Modifiers
--------------------------------------------------------------
-- RequirementSets
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType")
SELECT  'REQ_SET_CYP_WOR_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit        "RequirementSetId",
        'REQUIREMENTSET_TEST_ALL'                                                           "RequirementSetType"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- Requirements
INSERT INTO "Requirements" ("RequirementId", "RequirementType")
SELECT  'REQUIRES_CYP_WOR_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit       "RequirementId",
        'REQUIREMENT_PLOT_PROPERTY_MATCHES'                                                 "RequirementType"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- RequirementArguments (PropertyName)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_CYP_WOR_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit       "RequirementId",
        'PropertyName'                                                                      "Name",
        'CYP_WOR_BONUS_' || y.YieldType || '_' || bd.BinaryDigit                            "Value"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- RequirementArguments (PropertyMinimum)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_CYP_WOR_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit       "RequirementId",
        'PropertyMinimum'                                                                   "Name",
        '1'                                                                                 "Value"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- RequirementSetRequirements
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId") 
SELECT  'REQ_SET_CYP_WOR_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit        "RequirementSetId",
        'REQUIRES_CYP_WOR_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit       "RequirementId"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- Modifiers
INSERT INTO "Modifiers" ("ModifierId", "ModifierType", "SubjectRequirementSetId") 
SELECT  'MOD_BUILDING_CYP_WOR_BONUS_' || y.YieldType || '_' || bd.BinaryDigit               "ModifierId",
        'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD'                                       "ModifierType",
        'REQ_SET_CYP_WOR_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit        "RequirementSetId"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- ModifierArguments (Amount)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") 
SELECT  'MOD_BUILDING_CYP_WOR_BONUS_' || y.YieldType || '_' || bd.BinaryDigit               "ModifierId",
        'Amount'                                                                            "Name",
        bd.DecimalValue                                                                     "Value"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- ModifierArguments (YieldType)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") 
SELECT  'MOD_BUILDING_CYP_WOR_BONUS_' || y.YieldType || '_' || bd.BinaryDigit               "ModifierId",
        'YieldType'                                                                         "Name",
        y.YieldType                                                                         "Value"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- BuildingModifiers
INSERT INTO "BuildingModifiers" ("BuildingType", "ModifierId")
SELECT  'BUILDING_CYP_WOR'                                                                  "BuildingType",
        'MOD_BUILDING_CYP_WOR_BONUS_' || y.YieldType || '_' || bd.BinaryDigit               "ModifierId"
FROM "Yields" y
JOIN "CypWorTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;

--------------------------------------------------------------
-- Yield Modifiers (negative)
--------------------------------------------------------------
-- RequirementSets
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType")
SELECT  'REQ_SET_CYP_WOR_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                           "RequirementSetId",
        'REQUIREMENTSET_TEST_ALL'                                                           "RequirementSetType"
FROM "Yields" y;
-- Requirements
INSERT INTO "Requirements" ("RequirementId", "RequirementType")
SELECT  'REQUIRES_CYP_WOR_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                          "RequirementId",
        'REQUIREMENT_PLOT_PROPERTY_MATCHES'                                                 "RequirementType"
FROM "Yields" y;
-- RequirementArguments (PropertyName)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_CYP_WOR_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                          "RequirementId",
        'PropertyName'                                                                      "Name",
        'CYP_WOR_MALUS_' || y.YieldType                                                     "Value"
FROM "Yields" y;
-- RequirementArguments (PropertyMinimum)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_CYP_WOR_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                          "RequirementId",
        'PropertyMinimum'                                                                   "Name",
        '1'                                                                                 "Value"
FROM "Yields" y;
-- RequirementSetRequirements
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId") 
SELECT  'REQ_SET_CYP_WOR_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                           "RequirementSetId",
        'REQUIRES_CYP_WOR_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                          "RequirementId"
FROM "Yields" y;
-- Modifiers
INSERT INTO "Modifiers" ("ModifierId", "ModifierType", "SubjectRequirementSetId") 
SELECT  'MOD_BUILDING_CYP_WOR_MALUS_' || y.YieldType                                        "ModifierId",
        'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD'                                       "ModifierType",
        'REQ_SET_CYP_WOR_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                           "RequirementSetId"
FROM "Yields" y;
-- ModifierArguments (Amount)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") 
SELECT  'MOD_BUILDING_CYP_WOR_MALUS_' || y.YieldType                                        "ModifierId",
        'Amount'                                                                            "Name",
        -1024                                                                               "Value"
FROM "Yields" y;
-- ModifierArguments (YieldType)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") 
SELECT  'MOD_BUILDING_CYP_WOR_MALUS_' || y.YieldType                                        "ModifierId",
        'YieldType'                                                                         "Name",
        y.YieldType                                                                         "Value"
FROM "Yields" y;
-- BuildingModifiers
INSERT INTO "BuildingModifiers" ("BuildingType", "ModifierId")
SELECT  'BUILDING_CYP_WOR'                                                                  "BuildingType",
        'MOD_BUILDING_CYP_WOR_MALUS_' || y.YieldType                                        "ModifierId"
FROM "Yields" y;

--------------------------------------------------------------
-- Specialists internal worker buildings
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind")
SELECT  'BUILDING_CYP_WOR_WORKERS_' || bd.BinaryDigit   "Type",
        'KIND_BUILDING'                                 "Kind"
FROM "CypWorTmpBinaryDigits" bd
WHERE bd.BinaryDigit <= 7;
-- Buildings
INSERT INTO "Buildings" ("BuildingType", "Name", "Cost", "PrereqDistrict", "Description", "CitizenSlots", "InternalOnly") 
SELECT  'BUILDING_CYP_WOR_WORKERS_' || bd.BinaryDigit     "BuildingType", 
        'LOC_BUILDING_CYP_WOR_WORKERS_NAME'               "Name", 
        999                                               "Cost", 
        'DISTRICT_CYP_WOR'                                "PrereqDistrict", 
        'LOC_BUILDING_CYP_WOR_WORKERS_DESCRIPTION'        "Description", 
        bd.DecimalValue                                   "CitizenSlots",
        1                                                 "InternalOnly"
FROM "CypWorTmpBinaryDigits" bd
WHERE bd.BinaryDigit <= 7;
-- CypWtUiInvisibleBuildings
INSERT INTO "CypWtUiInvisibleBuildings" ("BuildingType", "Name") 
SELECT  b.BuildingType    "BuildingType",
        b.Name            "Name"
FROM "Buildings" b
WHERE b.BuildingType LIKE '%BUILDING_CYP_WOR_WORKERS_%';
-- CivilopediaPageExcludes
INSERT INTO "CivilopediaPageExcludes" ("SectionId", "PageId") VALUES
SELECT  'BUILDINGS'       "SectionId",
        b.BuildingType    "PageId",
FROM "Buildings" b
WHERE b.BuildingType LIKE '%BUILDING_CYP_WOR_WORKERS_%';

--------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------
DROP TABLE IF EXISTS "CypWorTmpBinaryDigits";