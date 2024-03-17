-- Yaxchilan
-- Description: Add Yaxchilan district and buildings.
--------------------------------------------------------------

--------------------------------------------------------------
-- Yaxchilan district
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES
('DISTRICT_YAXCHILAN', 'KIND_DISTRICT');
-- Districts
INSERT INTO "Districts"
("DistrictType",        "Name",                       "Description",                        "PrereqTech", "PrereqCivic",  "Cost", "RequiresPlacement",  "NoAdjacentCity", "Aqueduct", "InternalOnly", "CaptureRemovesBuildings",  "CaptureRemovesCityDefenses", "PlunderType",  "MilitaryDomain") VALUES 
('DISTRICT_YAXCHILAN', 'LOC_DISTRICT_YAXCHILAN_NAME', 'LOC_DISTRICT_YAXCHILAN_DESCRIPTION', NULL,         NULL,           27,     1,                    0,                0,          0,              0,                          0,                            'PLUNDER_GOLD', 'NO_DOMAIN');

--------------------------------------------------------------
-- Temporary list for binary digits
--------------------------------------------------------------
-- YaxchilanTmpBinaryDigits
CREATE TABLE IF NOT EXISTS "YaxchilanTmpBinaryDigits" (
  "BinaryDigit"     INTEGER,
  "DecimalValue"    INTEGER
);
INSERT INTO "YaxchilanTmpBinaryDigits" ("BinaryDigit", "DecimalValue") VALUES
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
-- YaxchilanUiInvisibleBuildings
CREATE TABLE IF NOT EXISTS "YaxchilanUiInvisibleBuildings" (
	"BuildingType"	    VARCHAR(255) NOT NULL,
  "Name"	            VARCHAR(255) NOT NULL
);

--------------------------------------------------------------
-- Yaxchilan specialists internal yield building
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES
('BUILDING_YAXCHILAN', 'KIND_BUILDING');
-- Buildings
INSERT INTO "Buildings" ("BuildingType", "Name", "Cost", "PrereqDistrict", "Description", "CitizenSlots", "InternalOnly")  VALUES
('BUILDING_YAXCHILAN', 'LOC_BUILDING_YAXCHILAN_NAME', 999, 'DISTRICT_YAXCHILAN', 'LOC_BUILDING_YAXCHILAN_DESCRIPTION', 0, 1);
-- Building_CitizenYieldChanges
INSERT INTO "Building_CitizenYieldChanges" ("BuildingType", "YieldType", "YieldChange")
SELECT  'BUILDING_YAXCHILAN'                "BuildingType",
        y.YieldType                         "YieldType", 
        20                                  "YieldChange"
FROM Yields y;
-- YaxchilanUiInvisibleBuildings
INSERT INTO "YaxchilanUiInvisibleBuildings" ("BuildingType", "Name") 
SELECT  b.BuildingType                      "BuildingType",
        b.Name                              "Name"
FROM "Buildings" b
WHERE b.BuildingType IN ('BUILDING_YAXCHILAN');

--------------------------------------------------------------
-- Yield Modifiers
--------------------------------------------------------------
-- RequirementSets
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType")
SELECT  'REQ_SET_YAXCHILAN_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit      "RequirementSetId",
        'REQUIREMENTSET_TEST_ALL'                                                           "RequirementSetType"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- Requirements
INSERT INTO "Requirements" ("RequirementId", "RequirementType")
SELECT  'REQUIRES_YAXCHILAN_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit     "RequirementId",
        'REQUIREMENT_PLOT_PROPERTY_MATCHES'                                                 "RequirementType"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- RequirementArguments (PropertyName)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_YAXCHILAN_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit     "RequirementId",
        'PropertyName'                                                                      "Name",
        'YAXCHILAN_BONUS_' || y.YieldType || '_' || bd.BinaryDigit                          "Value"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- RequirementArguments (PropertyMinimum)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_YAXCHILAN_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit     "RequirementId",
        'PropertyMinimum'                                                                   "Name",
        '1'                                                                                 "Value"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- RequirementSetRequirements
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId") 
SELECT  'REQ_SET_YAXCHILAN_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit      "RequirementSetId",
        'REQUIRES_YAXCHILAN_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit     "RequirementId"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- Modifiers
INSERT INTO "Modifiers" ("ModifierId", "ModifierType", "SubjectRequirementSetId") 
SELECT  'MOD_BUILDING_YAXCHILAN_BONUS_' || y.YieldType || '_' || bd.BinaryDigit             "ModifierId",
        'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD'                                       "ModifierType",
        'REQ_SET_YAXCHILAN_PLOT_HAS_PROPERTY_' || y.YieldType || '_' || bd.BinaryDigit      "RequirementSetId"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- ModifierArguments (Amount)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") 
SELECT  'MOD_BUILDING_YAXCHILAN_BONUS_' || y.YieldType || '_' || bd.BinaryDigit             "ModifierId",
        'Amount'                                                                            "Name",
        bd.DecimalValue                                                                     "Value"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- ModifierArguments (YieldType)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") 
SELECT  'MOD_BUILDING_YAXCHILAN_BONUS_' || y.YieldType || '_' || bd.BinaryDigit             "ModifierId",
        'YieldType'                                                                         "Name",
        y.YieldType                                                                         "Value"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;
-- BuildingModifiers
INSERT INTO "BuildingModifiers" ("BuildingType", "ModifierId")
SELECT  'BUILDING_YAXCHILAN_POPULATION'                                                     "BuildingType",
        'MOD_BUILDING_YAXCHILAN_BONUS_' || y.YieldType || '_' || bd.BinaryDigit             "ModifierId"
FROM "Yields" y
JOIN "YaxchilanTmpBinaryDigits" bd
ORDER BY y.YieldType, bd.BinaryDigit;

--------------------------------------------------------------
-- Yield Modifiers (negative)
--------------------------------------------------------------
-- RequirementSets
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType")
SELECT  'REQ_SET_YAXCHILAN_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                         "RequirementSetId",
        'REQUIREMENTSET_TEST_ALL'                                                           "RequirementSetType"
FROM "Yields" y;
-- Requirements
INSERT INTO "Requirements" ("RequirementId", "RequirementType")
SELECT  'REQUIRES_YAXCHILAN_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                        "RequirementId",
        'REQUIREMENT_PLOT_PROPERTY_MATCHES'                                                 "RequirementType"
FROM "Yields" y;
-- RequirementArguments (PropertyName)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_YAXCHILAN_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                        "RequirementId",
        'PropertyName'                                                                      "Name",
        'YAXCHILAN_MALUS_' || y.YieldType                                                   "Value"
FROM "Yields" y;
-- RequirementArguments (PropertyMinimum)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_YAXCHILAN_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                        "RequirementId",
        'Proper tyMinimum'                                                                  "Name",
        '1'                                                                                 "Value"
FROM "Yields" y;
-- RequirementSetRequirements
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId") 
SELECT  'REQ_SET_YAXCHILAN_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                         "RequirementSetId",
        'REQUIRES_YAXCHILAN_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                        "RequirementId"
FROM "Yields" y;
-- Modifiers
INSERT INTO "Modifiers" ("ModifierId", "ModifierType", "SubjectRequirementSetId") 
SELECT  'MOD_BUILDING_YAXCHILAN_MALUS_' || y.YieldType                                      "ModifierId",
        'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD'                                       "ModifierType",
        'REQ_SET_YAXCHILAN_PLOT_HAS_PROPERTY_MINUS_' || y.YieldType                         "RequirementSetId"
FROM "Yields" y;
-- ModifierArguments (Amount)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") 
SELECT  'MOD_BUILDING_YAXCHILAN_MALUS_' || y.YieldType                                      "ModifierId",
        'Amount'                                                                            "Name",
        -1024                                                                               "Value"
FROM "Yields" y;
-- ModifierArguments (YieldType)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") 
SELECT  'MOD_BUILDING_YAXCHILAN_MALUS_' || y.YieldType                                      "ModifierId",
        'YieldType'                                                                         "Name",
        y.YieldType                                                                         "Value"
FROM "Yields" y;
-- BuildingModifiers
INSERT INTO "BuildingModifiers" ("BuildingType", "ModifierId")
SELECT  'BUILDING_YAXCHILAN_POPULATION'                                                     "BuildingType",
        'MOD_BUILDING_YAXCHILAN_MALUS_' || y.YieldType                                      "ModifierId"
FROM "Yields" y;

--------------------------------------------------------------
-- Yaxchilan specialists internal worker buildings
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind")
SELECT  'BUILDING_YAXCHILAN_WORKERS_' || bd.BinaryDigit   "Type",
        'KIND_BUILDING'                                   "Kind"
FROM "YaxchilanTmpBinaryDigits" bd
WHERE bd.BinaryDigit <= 7;
-- Buildings
INSERT INTO "Buildings" ("BuildingType", "Name", "Cost", "PrereqDistrict", "Description", "CitizenSlots", "InternalOnly") 
SELECT  'BUILDING_YAXCHILAN_WORKERS_' || bd.BinaryDigit   "BuildingType", 
        'LOC_BUILDING_YAXCHILAN_WORKERS_NAME'             "Name", 
        999                                               "Cost", 
        'DISTRICT_YAXCHILAN'                              "PrereqDistrict", 
        'LOC_BUILDING_YAXCHILAN_WORKERS_DESCRIPTION'      "Description", 
        bd.DecimalValue                                   "CitizenSlots",
        1                                                 "InternalOnly"
FROM "YaxchilanTmpBinaryDigits" bd
WHERE bd.BinaryDigit <= 7;
-- YaxchilanUiInvisibleBuildings
INSERT INTO "YaxchilanUiInvisibleBuildings" ("BuildingType", "Name") 
SELECT  b.BuildingType    "BuildingType",
        b.Name            "Name"
FROM "Buildings" b
WHERE b.BuildingType LIKE '%BUILDING_YAXCHILAN_WORKERS_%';

--------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------
DROP TABLE IF EXISTS "YaxchilanTmpBinaryDigits";