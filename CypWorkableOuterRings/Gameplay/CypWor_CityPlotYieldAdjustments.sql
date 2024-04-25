-- City Plot Yield Adjustments
--------------------------------------------------------------

--------------------------------------------------------------
-- Dummy GP to acquire tiles
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES
('UNIT_CYP_WOR_GREAT_DUMMY', 'KIND_UNIT'),
('GREAT_PERSON_CLASS_CYP_WOR', 'KIND_GREAT_PERSON_CLASS'),
('MODIFIER_CYP_WOR_UNIT_GRANT_PLOT', 'KIND_MODIFIER'),
('MODIFIER_CYP_WOR_ACQUIRE_PLOT_TERRAIN_VALID', 'KIND_MODIFIER'),
('GREAT_PERSON_INDIVIDUAL_CYP_WOR_ACQUIRE_PLOT', 'KIND_GREAT_PERSON_INDIVIDUAL'),
('MODIFIER_CYP_WOR_PLAYER_ADJUST_EMBARK_UNIT_PASS', 'KIND_MODIFIER');
-- Units
INSERT INTO "Units" 
("UnitType",                        "Name", "BaseSightRange", "BaseMoves",  "Domain",       "FormationClass",           "Cost", "Description",  "Flavor", "CanCapture", "CanRetreatWhenCaptured", "TraitType",            "PromotionClass", "CanTrain", "Stackable", "IgnoreMoves") VALUES 
('UNIT_CYP_WOR_GREAT_DUMMY',        '-',    1,                99,           'DOMAIN_LAND',  'FORMATION_CLASS_CIVILIAN', 1,      "-",            NULL,     1,            0,                        "TRAIT_CYP_WOR_DUMMY",  NULL,             0,          1,           0);
-- Units_XP2
INSERT OR IGNORE INTO "Units_XP2" 
("UnitType",                        "CanEarnExperience",  "CanFormMilitaryFormation") VALUES 
('UNIT_CYP_WOR_GREAT_DUMMY',        0,                    0);
-- GreatPersonClasses
INSERT INTO "GreatPersonClasses" 
("GreatPersonClassType",              "Name", "UnitType",                       "DistrictType",         "MaxPlayerInstances", "PseudoYieldType",          "IconString",           "ActionIcon",                         "AvailableInTimeline",  "GenerateDuplicateIndividuals") VALUES 
('GREAT_PERSON_CLASS_CYP_WOR',        '-',    'UNIT_CYP_WOR_GREAT_DUMMY',       'DISTRICT_CITY_CENTER', NULL,                 'PSEUDOYIELD_GPP_GENERAL',  '[ICON_GreatGeneral]', 'ICON_UNITOPERATION_GENERAL_ACTION',  '0',                    '1');
-- ExcludedGreatPersonClasses
INSERT INTO "ExcludedGreatPersonClasses" 
("GreatPersonClassType",        "TraitType") VALUES 
('GREAT_PERSON_CLASS_CYP_WOR',  'TRAIT_LEADER_MAJOR_CIV');
-- GreatPersonIndividuals
INSERT INTO "GreatPersonIndividuals" 
("GreatPersonIndividualType",                           "Name", "GreatPersonClassType",             "EraType",    "ActionCharges",  "ActionRequiresOwnedTile",  "ActionRequiresAdjacentOwnedTile",  "Gender") VALUES 
('GREAT_PERSON_INDIVIDUAL_CYP_WOR_ACQUIRE_PLOT',        '-',    'GREAT_PERSON_CLASS_CYP_WOR',       'ERA_ANCIENT', 0,               0,                          1,                                  'M');
-- DynamicModifiers
INSERT INTO "DynamicModifiers" ("ModifierType", "CollectionType", "EffectType") VALUES 
('MODIFIER_CYP_WOR_UNIT_GRANT_PLOT', 'COLLECTION_OWNER', 'EFFECT_GRANT_PLOT');
-- Modifiers
INSERT INTO "Modifiers" ("ModifierId", "ModifierType", "RunOnce", "Permanent") VALUES 
('MOD_CYP_WOR_GREATPERSON_GRANT_PLOT', 'MODIFIER_CYP_WOR_UNIT_GRANT_PLOT', '1', '1');
-- GreatPersonIndividualBirthModifiers
INSERT INTO "GreatPersonIndividualBirthModifiers" 
("GreatPersonIndividualType",                           "ModifierId") VALUES 
('GREAT_PERSON_INDIVIDUAL_CYP_WOR_ACQUIRE_PLOT',        'MOD_CYP_WOR_GREATPERSON_GRANT_PLOT');
-- RequirementSets
INSERT INTO "Requirements" ("RequirementId", "RequirementType") VALUES 
('REQUIRES_CYP_WOR_UNIT_IS_CYP_WOR_ACQUIRE_PLOT', 'REQUIREMENT_UNIT_TYPE_MATCHES');
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value") VALUES 
('REQUIRES_CYP_WOR_UNIT_IS_CYP_WOR_ACQUIRE_PLOT', 'UnitType', 'UNIT_CYP_WOR_GREAT_DUMMY');
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType") VALUES 
('REQ_SET_CYP_WOR_UNIT_IS_CYP_WOR_ACQUIRE_PLOT', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId") VALUES 
('REQ_SET_CYP_WOR_UNIT_IS_CYP_WOR_ACQUIRE_PLOT', 'REQUIRES_CYP_WOR_UNIT_IS_CYP_WOR_ACQUIRE_PLOT');
-- DynamicModifiers
INSERT INTO "DynamicModifiers" ("ModifierType", "CollectionType", "EffectType") VALUES 
('MODIFIER_CYP_WOR_ACQUIRE_PLOT_TERRAIN_VALID', 'COLLECTION_ALL_UNITS', 'EFFECT_ADJUST_UNIT_VALID_TERRAIN');
-- Modifiers (terrain)
INSERT INTO "Modifiers" ("ModifierId", "ModifierType", "SubjectRequirementSetId")
SELECT  'MOD_CYP_WOR_ACQUIRE_PLOT_VALID_' || t.TerrainType  "ModifierId", 
        'MODIFIER_CYP_WOR_ACQUIRE_PLOT_TERRAIN_VALID'      "ModifierType", 
        'REQ_SET_CYP_WOR_UNIT_IS_CYP_WOR_ACQUIRE_PLOT'      "SubjectRequirementSetId"
FROM "Terrains" t
WHERE t.Mountain = 0;
-- ModifierArguments (terrain - TerrainType)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value")
SELECT  'MOD_CYP_WOR_ACQUIRE_PLOT_VALID_' || t.TerrainType  "ModifierId", 
        'TerrainType'                                       "Name", 
        t.TerrainType                                       "Value"
FROM "Terrains" t
WHERE t.Mountain = 0;
-- ModifierArguments (terrain - Valid)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value")
SELECT  'MOD_CYP_WOR_ACQUIRE_PLOT_VALID_' || t.TerrainType  "ModifierId", 
        'Valid'                                             "Name", 
        '1'                                                 "Value"
FROM "Terrains" t
WHERE t.Mountain = 0;
-- TraitModifiers (terrain)
INSERT INTO "TraitModifiers" ("TraitType", "ModifierId")
SELECT  'TRAIT_LEADER_MAJOR_CIV'                            "TraitType", 
        'MOD_CYP_WOR_ACQUIRE_PLOT_VALID_' || t.TerrainType  "ModifierId"
FROM "Terrains" t
WHERE t.Mountain = 0;
-- DynamicModifiers
INSERT INTO "DynamicModifiers" ("ModifierType", "CollectionType", "EffectType") VALUES 
('MODIFIER_CYP_WOR_PLAYER_ADJUST_EMBARK_UNIT_PASS', 'COLLECTION_OWNER', 'EFFECT_ADJUST_PLAYER_EMBARK_UNIT_PASS');
-- Modifiers (embark)
INSERT INTO "Modifiers" ("ModifierId", "ModifierType") VALUES 
('MOD_CYP_WOR_ACQUIRE_PLOT_EMBARK', 'MODIFIER_CYP_WOR_PLAYER_ADJUST_EMBARK_UNIT_PASS');
-- ModifierArguments (embark)
INSERT INTO "ModifierArguments" ("ModifierId", "Name", "Value") VALUES 
('MOD_CYP_WOR_ACQUIRE_PLOT_EMBARK', 'UnitType', 'UNIT_CYP_WOR_GREAT_DUMMY');
-- TraitModifiers (embark)
INSERT INTO "TraitModifiers" ("TraitType", "ModifierId") VALUES
('TRAIT_LEADER_MAJOR_CIV', 'MOD_CYP_WOR_ACQUIRE_PLOT_EMBARK');