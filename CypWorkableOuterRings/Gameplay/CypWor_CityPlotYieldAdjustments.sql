-- City Plot Yield Adjustments
-- Description: Adds quite complex mechanic to solve the
-- bug that when changign tile ownership via LUA the city
-- plot yield adjustments are not updated until reload.
--------------------------------------------------------------

--------------------------------------------------------------
-- TODOS
--------------------------------------------------------------
-- Support reusing modifiers (modifier || object)
-- Governor effects

--------------------------------------------------------------
-- Plot swapped property
--------------------------------------------------------------
-- Requirements
INSERT INTO "Requirements" ("RequirementId", "RequirementType", "Inverse") VALUES
('REQUIRES_CYP_WOR_PLOT_IS_SPECIAL_SWAPPED', 'REQUIREMENT_PLOT_PROPERTY_MATCHES', 0),
('REQUIRES_CYP_WOR_PLOT_IS_NOT_SPECIAL_SWAPPED', 'REQUIREMENT_PLOT_PROPERTY_MATCHES', 1);
-- RequirementArguments
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value") VALUES
('REQUIRES_CYP_WOR_PLOT_IS_SPECIAL_SWAPPED', 'PropertyName', 'CYP_WOR_PLOT_SPECIAL_SWAP'),
('REQUIRES_CYP_WOR_PLOT_IS_SPECIAL_SWAPPED', 'PropertyMinimum', '1'),
('REQUIRES_CYP_WOR_PLOT_IS_NOT_SPECIAL_SWAPPED', 'PropertyName', 'CYP_WOR_PLOT_SPECIAL_SWAP'),
('REQUIRES_CYP_WOR_PLOT_IS_NOT_SPECIAL_SWAPPED', 'PropertyMinimum', '1');

--------------------------------------------------------------
-- Player plot yields modifier
--------------------------------------------------------------
-- Types
INSERT INTO "Types" ("Type", "Kind") VALUES 
('MODIFIER_CYP_WOR_PLAYER_ADJUST_PLOT_YIELD', 'KIND_MODIFIER');
-- DynamicModifiers
INSERT INTO "DynamicModifiers" ("ModifierType", "CollectionType", "EffectType") VALUES 
('MODIFIER_CYP_WOR_PLAYER_ADJUST_PLOT_YIELD', 'COLLECTION_PLAYER_PLOT_YIELDS', 'EFFECT_ADJUST_PLOT_YIELD');

--------------------------------------------------------------
-- Temporary table
--------------------------------------------------------------
-- Create table
CREATE TABLE IF NOT EXISTS "CypWorPlotYieldAdjustmentObjects" (
	"ObjectType"	                VARCHAR(255) NOT NULL,
	"ObjectTypeName"	            VARCHAR(255) NOT NULL,
  "ObjectTypeRequirementType"	  VARCHAR(255) NOT NULL,
	"ModifierId"	                VARCHAR(255) NOT NULL
);

--------------------------------------------------------------
-- Building city plot yield adjustments
--------------------------------------------------------------
-- Insert city wide plot yield modifiers from buildings (A)
INSERT INTO "CypWorPlotYieldAdjustmentObjects" ("ObjectType", "ObjectTypeName", "ObjectTypeRequirementType", "ModifierId")
SELECT  bm.BuildingType                   "ObjectType",
        'BuildingType'                    "ObjectTypeName", 
        'REQUIREMENT_CITY_HAS_BUILDING'   "ObjectTypeRequirementType", 
        bm.ModifierId                     "ModifierId"
FROM Modifiers m
JOIN BuildingModifiers bm
ON bm.ModifierId = m.ModifierId
JOIN DynamicModifiers dm
ON m.ModifierType = dm.ModifierType
WHERE dm.EffectType = 'EFFECT_ADJUST_PLOT_YIELD'
AND dm.CollectionType = 'COLLECTION_CITY_PLOT_YIELDS'
AND m.SubjectRequirementSetId NOT IN (
	SELECT DISTINCT(rsr.RequirementSetId)
	FROM RequirementSetRequirements rsr
	JOIN Requirements r
	ON rsr.RequirementId = r.RequirementId
	WHERE r.RequirementType NOT LIKE '%PLOT%'
)
AND bm.BuildingType NOT LIKE 'MOD_BUILDING_CYP_WOR_%';
-- Insert city wide plot yield modifiers from buildings (B)
INSERT INTO "CypWorPlotYieldAdjustmentObjects" ("ObjectType", "ObjectTypeName", "ObjectTypeRequirementType", "ModifierId")
SELECT  bm.BuildingType                   "ObjectType",
        'BuildingType'                    "ObjectTypeName", 
        'REQUIREMENT_CITY_HAS_BUILDING'   "ObjectTypeRequirementType", 
        bm.ModifierId                     "ModifierId"
FROM Modifiers m
JOIN DynamicModifiers dm
ON m.ModifierType = dm.ModifierType
JOIN BuildingModifiers bm
ON m.ModifierId = bm.ModifierId
JOIN ModifierArguments ma
ON m.ModifierId = ma.ModifierId
JOIN Modifiers m2
ON ma.Value = m2.ModifierId
JOIN DynamicModifiers dm2
ON m2.ModifierType = dm2.ModifierType
WHERE dm.EffectType = 'EFFECT_ATTACH_MODIFIER' 
AND dm.CollectionType = 'COLLECTION_ALL_CITIES'
AND ma.Name = 'ModifierId'
AND dm2.EffectType = 'EFFECT_ADJUST_PLOT_YIELD' 
AND dm2.CollectionType = 'COLLECTION_CITY_PLOT_YIELDS';
-- Create table
CREATE TABLE IF NOT EXISTS "CypWorPlotYieldAdjustmentBuildings" (
	"BuildingType"	    VARCHAR(255) NOT NULL,
  PRIMARY KEY("BuildingType")
);
-- Insert buildings (unique)
INSERT INTO "CypWorPlotYieldAdjustmentBuildings" ("BuildingType")
SELECT  t.ObjectType    "BuildingType"
FROM "CypWorPlotYieldAdjustmentObjects" t
WHERE t.ObjectTypeName = 'BuildingType'
GROUP BY t.ObjectType;

--------------------------------------------------------------
-- District city plot yield adjustments
--------------------------------------------------------------
-- Insert city wide plot yield modifiers from Districts
INSERT INTO "CypWorPlotYieldAdjustmentObjects" ("ObjectType", "ObjectTypeName", "ObjectTypeRequirementType", "ModifierId")
SELECT  bm.DistrictType                   "ObjectType",
        'DistrictType'                    "ObjectTypeName", 
        'REQUIREMENT_CITY_HAS_District'   "ObjectTypeRequirementType", 
        bm.ModifierId                     "ModifierId"
FROM Modifiers m
JOIN DistrictModifiers bm
ON bm.ModifierId = m.ModifierId
JOIN DynamicModifiers dm
ON m.ModifierType = dm.ModifierType
WHERE dm.EffectType = 'EFFECT_ADJUST_PLOT_YIELD'
-- Only consider plot or city wide modifiers
AND dm.CollectionType = 'COLLECTION_CITY_PLOT_YIELDS'
-- Filter single plot yield adjustments where requirements are only based on plot conditions
AND m.SubjectRequirementSetId NOT IN (
	SELECT DISTINCT(rsr.RequirementSetId)
	FROM RequirementSetRequirements rsr
	JOIN Requirements r
	ON rsr.RequirementId = r.RequirementId
	WHERE r.RequirementType NOT LIKE '%PLOT%'
);
-- Create table
CREATE TABLE IF NOT EXISTS "CypWorPlotYieldAdjustmentDistricts" (
	"DistrictType"	    VARCHAR(255) NOT NULL,
  PRIMARY KEY("DistrictType")
);
-- Insert Districts (unique)
INSERT INTO "CypWorPlotYieldAdjustmentDistricts" ("DistrictType")
SELECT  t.ObjectType    "DistrictType"
FROM "CypWorPlotYieldAdjustmentObjects" t
WHERE t.ObjectTypeName = 'DistrictType'
GROUP BY t.ObjectType;

--------------------------------------------------------------
-- Building and district city plot yield adjustments
-- Change effect to all player plots and modify requirements
-- like so:
-- (plot-original-requirements)
-- AND
-- (  (city-has-infrastructure AND plot-is-not-special-swapped)
--    OR
--    (plot-has-custom-property-cityhasbuilding)
--  )
--------------------------------------------------------------
-- Requirements (original req set is met)
INSERT INTO "Requirements" ("RequirementId", "RequirementType") 
SELECT  'REQUIRES_CYP_WOR_SWAP_REQ_SET_MET_' || m.SubjectRequirementSetId         "RequirementId", 
        'REQUIREMENT_REQUIREMENTSET_IS_MET'                                       "RequirementType"
FROM "CypWorPlotYieldAdjustmentObjects" t
JOIN "Modifiers" m
ON t.ModifierId = m.ModifierId
WHERE m.SubjectRequirementSetId IS NOT NULL
GROUP BY m.SubjectRequirementSetId;
-- RequirementArguments (has infrastructure AND not special swapped)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value") 
SELECT  'REQUIRES_CYP_WOR_SWAP_REQ_SET_MET_' || m.SubjectRequirementSetId         "RequirementId", 
        'RequirementSetId'                                                        "Name", 
        m.SubjectRequirementSetId                                                 "Value"
FROM "CypWorPlotYieldAdjustmentObjects" t
JOIN "Modifiers" m
ON t.ModifierId = m.ModifierId
WHERE m.SubjectRequirementSetId IS NOT NULL
GROUP BY m.SubjectRequirementSetId;
-- Requirements (has infrastructure)
INSERT INTO "Requirements" ("RequirementId", "RequirementType") 
SELECT  'REQUIRES_CYP_WOR_SWAP_CITY_HAS_' || t.ObjectType   "RequirementId", 
        t.ObjectTypeRequirementType                         "RequirementType"
FROM "CypWorPlotYieldAdjustmentObjects" t
GROUP BY t.ObjectType;
-- RequirementArguments (has infrastructure)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value") 
SELECT  'REQUIRES_CYP_WOR_SWAP_CITY_HAS_' || t.ObjectType   "RequirementId", 
        t.ObjectTypeName                                    "Name", 
        t.ObjectType                                        "Value"
FROM "CypWorPlotYieldAdjustmentObjects" t
GROUP BY t.ObjectType;
-- RequirementSets (has infrastructure AND not special swapped)
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_UNSWAPPED_' || t.ModifierId                     "RequirementSetId", 
        'REQUIREMENTSET_TEST_ALL'                                                 "RequirementSetType"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementSetRequirements (has infrastructure)
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_UNSWAPPED_' || t.ModifierId                     "RequirementSetId", 
        'REQUIRES_CYP_WOR_SWAP_CITY_HAS_' || t.ObjectType                         "RequirementId"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementSetRequirements (not special swapped)
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_UNSWAPPED_' || t.ModifierId                     "RequirementSetId", 
        'REQUIRES_CYP_WOR_PLOT_IS_NOT_SPECIAL_SWAPPED'                            "RequirementId"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- Requirements (has infrastructure AND not special swapped)
INSERT INTO "Requirements" ("RequirementId", "RequirementType") 
SELECT  'REQUIRES_CYP_WOR_SWAP_FOR_UNSWAPPED_' || t.ModifierId                    "RequirementId", 
        'REQUIREMENT_REQUIREMENTSET_IS_MET'                                       "RequirementType"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementArguments (has infrastructure AND not special swapped)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value") 
SELECT  'REQUIRES_CYP_WOR_SWAP_FOR_UNSWAPPED_' || t.ModifierId                    "RequirementId", 
        'RequirementSetId'                                                        "Name", 
        'REQ_SET_CYP_WOR_SWAP_FOR_UNSWAPPED_' || t.ModifierId                     "Value"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- Requirements (plot has infrastructure special property)
INSERT INTO "Requirements" ("RequirementId", "RequirementType") 
SELECT  'REQUIRES_CYP_WOR_SWAP_PLOT_BELONGS_TO_CITY_THAT_HAS_' || t.ObjectType    "RequirementId", 
        'REQUIREMENT_PLOT_PROPERTY_MATCHES'                                       "RequirementType"
FROM "CypWorPlotYieldAdjustmentObjects" t
GROUP BY t.ObjectType;
-- RequirementArguments (plot has infrastructure special property - PropertyName)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value") 
SELECT  'REQUIRES_CYP_WOR_SWAP_PLOT_BELONGS_TO_CITY_THAT_HAS_' || t.ObjectType    "RequirementId", 
        'PropertyName'                                                            "Name", 
        'CYP_WOR_PLOT_BELONGS_TO_CITY_THAT_HAS_' || t.ObjectType                  "Value"
FROM "CypWorPlotYieldAdjustmentObjects" t
GROUP BY t.ObjectType;
-- RequirementArguments (plot has infrastructure special property - PropertyMinimum)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value") 
SELECT  'REQUIRES_CYP_WOR_SWAP_PLOT_BELONGS_TO_CITY_THAT_HAS_' || t.ObjectType    "RequirementId", 
        'PropertyMinimum'                                                         "Name", 
        '1'                                                                       "Value"
FROM "CypWorPlotYieldAdjustmentObjects" t
GROUP BY t.ObjectType;
-- RequirementSets (unswapped or swapped)
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_SWAPPED_OR_UNSWAPPED_' || t.ModifierId          "RequirementSetId", 
        'REQUIREMENTSET_TEST_ANY'                                                 "RequirementSetType"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementSetRequirements (unswapped)
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_SWAPPED_OR_UNSWAPPED_' || t.ModifierId          "RequirementSetId", 
        'REQUIRES_CYP_WOR_SWAP_FOR_UNSWAPPED_' || t.ModifierId                    "RequirementId"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementSetRequirements (swapped)
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_SWAPPED_OR_UNSWAPPED_' || t.ModifierId          "RequirementSetId", 
        'REQUIRES_CYP_WOR_SWAP_PLOT_BELONGS_TO_CITY_THAT_HAS_' || t.ObjectType    "RequirementId"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- Requirements (unswapped or swapped)
INSERT INTO "Requirements" ("RequirementId", "RequirementType") 
SELECT  'REQUIRES_CYP_WOR_SWAP_FOR_SWAPPED_OR_UNSWAPPED_' || t.ModifierId         "RequirementId", 
        'REQUIREMENT_REQUIREMENTSET_IS_MET'                                       "RequirementType"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementArguments (has building AND not special swapped)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value") 
SELECT  'REQUIRES_CYP_WOR_SWAP_FOR_SWAPPED_OR_UNSWAPPED_' || t.ModifierId         "RequirementId", 
        'RequirementSetId'                                                        "Name", 
        'REQ_SET_CYP_WOR_SWAP_FOR_SWAPPED_OR_UNSWAPPED_' || t.ModifierId          "Value"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementSets (original-req and swapped or unswapped)
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_' || t.ModifierId                               "RequirementSetId", 
        'REQUIREMENTSET_TEST_ALL'                                                 "RequirementSetType"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementSetRequirements (swapped or unswapped)
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_' || t.ModifierId                               "RequirementSetId", 
        'REQUIRES_CYP_WOR_SWAP_FOR_SWAPPED_OR_UNSWAPPED_' || t.ModifierId         "RequirementId"
FROM "CypWorPlotYieldAdjustmentObjects" t;
-- RequirementSetRequirements (not special swapped)
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId")
SELECT  'REQ_SET_CYP_WOR_SWAP_FOR_' || t.ModifierId                               "RequirementSetId", 
        'REQUIRES_CYP_WOR_SWAP_REQ_SET_MET_' || m.SubjectRequirementSetId         "RequirementId"
FROM "CypWorPlotYieldAdjustmentObjects" t
JOIN "Modifiers" m
ON t.ModifierId = m.ModifierId
WHERE m.SubjectRequirementSetId IS NOT NULL
GROUP BY m.SubjectRequirementSetId;
-- Modifiers (UPDATE)
UPDATE Modifiers
SET ModifierType = 'MODIFIER_CYP_WOR_PLAYER_ADJUST_PLOT_YIELD',
    SubjectRequirementSetId = (SELECT 'REQ_SET_CYP_WOR_SWAP_FOR_' || t.ModifierId FROM "CypWorPlotYieldAdjustmentObjects" t WHERE t.ModifierId = Modifiers.ModifierId)
WHERE ModifierId IN (SELECT t.ModifierId FROM "CypWorPlotYieldAdjustmentObjects" t);

--------------------------------------------------------------
-- Temporary table
--------------------------------------------------------------
-- Cleanup
DROP TABLE "CypWorPlotYieldAdjustmentObjects";