-- District and buildings.
-- Description: Add district and buildings.
--------------------------------------------------------------

--------------------------------------------------------------
-- Dummy trait
--------------------------------------------------------------
-- Traits
INSERT INTO "Types" ("Type", "Kind") VALUES 
('TRAIT_CYP_WOR_DUMMY', 'KIND_TRAIT');
-- Traits
INSERT INTO "Traits" ("TraitType", "InternalOnly") VALUES 
('TRAIT_CYP_WOR_DUMMY', '1');

--------------------------------------------------------------
-- Workable outer ring district
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES
('DISTRICT_CYP_WOR', 'KIND_DISTRICT');
-- Districts
INSERT INTO "Districts"
("DistrictType",     "Name",                      "Description",                      "PrereqCivic",      "Cost", "RequiresPopulation", "RequiresPlacement",  "NoAdjacentCity", "Appeal", "Aqueduct", "InternalOnly", "CaptureRemovesBuildings",  "CaptureRemovesCityDefenses", "PlunderType",  "PlunderAmount",  "MilitaryDomain", "OnePerCity", "Housing",  "CostProgressionModel",           "CostProgressionParam1") VALUES 
('DISTRICT_CYP_WOR', 'LOC_DISTRICT_CYP_WOR_NAME', 'LOC_DISTRICT_CYP_WOR_DESCRIPTION', "CIVIC_FEUDALISM",  35,     0,                    1,                    1,                -1,       0,          0,              0,                          0,                            'PLUNDER_GOLD', 50,               'NO_DOMAIN',      1,            1,          'COST_PROGRESSION_GAME_PROGRESS', 1000);
-- District_TradeRouteYields
INSERT INTO "District_TradeRouteYields" 
("DistrictType",      "YieldType",  "YieldChangeAsOrigin",  "YieldChangeAsDomesticDestination", "YieldChangeAsInternationalDestination") VALUES 
('DISTRICT_CYP_WOR',  'YIELD_FOOD', '0.0',                  '1.0',                              '0.0'),
('DISTRICT_CYP_WOR',  'YIELD_GOLD', '0.0',                  '0.0',                              '1.0');
-- Types (culture bomb)
INSERT OR IGNORE INTO "Types" ("Type", "Kind") VALUES 
('MODIFIER_CYP_WOR_ALL_PLAYERS_ADD_CULTURE_BOMB_TRIGGER', 'KIND_MODIFIER');
-- DynamicModifiers (culture bomb)
INSERT OR IGNORE INTO "DynamicModifiers" ("ModifierType", "CollectionType", "EffectType") VALUES 
('MODIFIER_CYP_WOR_ALL_PLAYERS_ADD_CULTURE_BOMB_TRIGGER', 'COLLECTION_MAJOR_PLAYERS', 'EFFECT_ADD_CULTURE_BOMB_TRIGGER');
-- Modifiers (culture bomb)
INSERT INTO "Modifiers" ("ModifierId", "ModifierType") VALUES 
('MOD_DISTRICT_CYP_WOR_CULTURE_BOMB', 'MODIFIER_CYP_WOR_ALL_PLAYERS_ADD_CULTURE_BOMB_TRIGGER');
-- ModifierArguments
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") VALUES 
('MOD_DISTRICT_CYP_WOR_CULTURE_BOMB', 'DistrictType', 'DISTRICT_CYP_WOR'),
('MOD_DISTRICT_CYP_WOR_CULTURE_BOMB', 'CaptureOwnedTerritory', '0');
-- GameModifiers
INSERT INTO "GameModifiers" ("ModifierId") VALUES 
('MOD_DISTRICT_CYP_WOR_CULTURE_BOMB');
-- Adjacency_YieldChanges
INSERT INTO "Adjacency_YieldChanges" 
("ID",            "Description",                "YieldType",  "YieldChange",  "TilesRequired",  "AdjacentDistrict") VALUES 
('CypWor_Gold',   'LOC_DISTRICT_CYP_WOR_GOLD',  'YIELD_GOLD', '1',            '1',              'DISTRICT_CYP_WOR');
-- 
INSERT INTO "District_Adjacencies" ("DistrictType", "YieldChangeId") 
SELECT  d.DistrictType  "DistrictType", 
        'CypWor_Gold'   "YieldChangeId"
FROM "Districts" d
WHERE d.DistrictType IN
('DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR');
-- District_GreatPersonPoints
INSERT INTO "District_GreatPersonPoints" ("DistrictType", "GreatPersonClassType", "PointsPerTurn")
SELECT    'DISTRICT_CYP_WOR'        "DistrictType", 
          gpc.GreatPersonClassType  "GreatPersonClassType", 
          1                         "PointsPerTurn"
FROM "GreatPersonClasses" gpc
WHERE gpc.GreatPersonClassType = 'GREAT_PERSON_CLASS_JNR_EXPLORER';

--------------------------------------------------------------
-- Workable outer ring buildings
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES
('BUILDING_CYP_WOR_LOGISTICS_CENTER', 'KIND_BUILDING');
-- Buildings
INSERT INTO "Buildings" 
("BuildingType",                      "Name",                                       "Description",                                        "Cost", "PrereqDistrict",   "PrereqCivic")  VALUES
('BUILDING_CYP_WOR_LOGISTICS_CENTER', 'LOC_BUILDING_CYP_WOR_LOGISTICS_CENTER_NAME', 'LOC_BUILDING_CYP_WOR_LOGISTICS_CENTER_DESCRIPTION',  100,    'DISTRICT_CYP_WOR', "CIVIC_URBANIZATION");
-- Building_GreatPersonPoints
INSERT INTO "Building_GreatPersonPoints" ("BuildingType", "GreatPersonClassType", "PointsPerTurn")
SELECT  'BUILDING_CYP_WOR_LOGISTICS_CENTER'   "BuildingType", 
        gpc.GreatPersonClassType              "GreatPersonClassType", 
        1                                     "PointsPerTurn"
FROM "GreatPersonClasses" gpc
WHERE gpc.GreatPersonClassType = 'GREAT_PERSON_CLASS_JNR_EXPLORER';

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
('BUILDING_CYP_WOR_INTERNAL_SPECIALISTS', 'KIND_BUILDING');
-- Buildings
INSERT INTO "Buildings" ("BuildingType", "Name", "Cost", "PrereqDistrict", "Description", "CitizenSlots", "InternalOnly", "TraitType")  VALUES
('BUILDING_CYP_WOR_INTERNAL_SPECIALISTS', 'LOC_BUILDING_CYP_WOR_NAME', 0, 'DISTRICT_CYP_WOR', 'LOC_BUILDING_CYP_WOR_DESCRIPTION', 0, 1, 'TRAIT_CYP_WOR_DUMMY');
-- Building_CitizenYieldChanges
INSERT INTO "Building_CitizenYieldChanges" ("BuildingType", "YieldType", "YieldChange")
SELECT  'BUILDING_CYP_WOR_INTERNAL_SPECIALISTS' "BuildingType",
        y.YieldType                             "YieldType", 
        20                                      "YieldChange"
FROM Yields y;
-- CypWtUiInvisibleBuildings
INSERT INTO "CypWtUiInvisibleBuildings" ("BuildingType", "Name") VALUES
('BUILDING_CYP_WOR_INTERNAL_SPECIALISTS', 'LOC_BUILDING_CYP_WOR_NAME');
-- CivilopediaPageExcludes
INSERT INTO "CivilopediaPageExcludes" ("SectionId", "PageId") VALUES
('BUILDINGS', 'BUILDING_CYP_WOR_INTERNAL_SPECIALISTS');

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
SELECT  'BUILDING_CYP_WOR_INTERNAL_SPECIALISTS'                                             "BuildingType",
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
SELECT  'BUILDING_CYP_WOR_INTERNAL_SPECIALISTS'                                             "BuildingType",
        'MOD_BUILDING_CYP_WOR_MALUS_' || y.YieldType                                        "ModifierId"
FROM "Yields" y;

--------------------------------------------------------------
-- Specialists internal worker buildings
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind")
SELECT  'BUILDING_CYP_WOR_INTERNAL_WORKERS_' || bd.BinaryDigit   "Type",
        'KIND_BUILDING'                                          "Kind"
FROM "CypWorTmpBinaryDigits" bd
WHERE bd.BinaryDigit <= 7;
-- Buildings
INSERT INTO "Buildings" ("BuildingType", "Name", "Cost", "PrereqDistrict", "Description", "CitizenSlots", "InternalOnly", "TraitType") 
SELECT  'BUILDING_CYP_WOR_INTERNAL_WORKERS_' || bd.BinaryDigit  "BuildingType", 
        'LOC_BUILDING_CYP_WOR_INTERNAL_WORKERS_NAME'            "Name", 
        0                                                       "Cost", 
        'DISTRICT_CYP_WOR'                                      "PrereqDistrict", 
        'LOC_BUILDING_CYP_WOR_INTERNAL_WORKERS_DESCRIPTION'     "Description", 
        bd.DecimalValue                                         "CitizenSlots",
        1                                                       "InternalOnly",
        'TRAIT_CYP_WOR_DUMMY'                                   "TraitType"
FROM "CypWorTmpBinaryDigits" bd
WHERE bd.BinaryDigit <= 7;
-- CypWtUiInvisibleBuildings
INSERT INTO "CypWtUiInvisibleBuildings" ("BuildingType", "Name") 
SELECT  b.BuildingType    "BuildingType",
        b.Name            "Name"
FROM "Buildings" b
WHERE b.BuildingType LIKE 'BUILDING_CYP_WOR_INTERNAL_WORKERS_%';
-- CivilopediaPageExcludes
INSERT INTO "CivilopediaPageExcludes" ("SectionId", "PageId")
SELECT  'BUILDINGS'       "SectionId",
        b.BuildingType    "PageId"
FROM "Buildings" b
WHERE b.BuildingType LIKE 'BUILDING_CYP_WOR_INTERNAL_WORKERS_%';

--------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------
DROP TABLE IF EXISTS "CypWorTmpBinaryDigits";