-- GameMode: Secret Societies
--------------------------------------------------------------

--------------------------------------------------------------
-- SANGUINE PACT
--------------------------------------------------------------
-- Disable Vampire Castle next to NBH TE
--- Requirements (is vampire castle)
INSERT INTO "Requirements" ("RequirementId", "RequirementType")
SELECT  'REQUIRES_CYP_WOR_PLOT_HAS_VAMPIRE_CASTLE_REQ_SET_IS_MET'   "RequirementId", 
        'REQUIREMENT_REQUIREMENTSET_IS_MET'                         "RequirementType"
FROM "Modifiers" m
WHERE m.ModifierId = 'SANGUINE_PACT_GRANT_CASTLES_ADJACENT_YIELDS';
--- RequirementArguments (is vampire castle)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_CYP_WOR_PLOT_HAS_VAMPIRE_CASTLE_REQ_SET_IS_MET'   "RequirementId", 
        'RequirementSetId'                                          "Name", 
        'THIS_PLOT_IS_A_VAMPIRE_CASTLE'                             "Value"
FROM "Modifiers" m
WHERE m.ModifierId = 'SANGUINE_PACT_GRANT_CASTLES_ADJACENT_YIELDS';
--- Requirements (not next to FTQ)
INSERT INTO "Requirements" ("RequirementId", "RequirementType", "Inverse") 
SELECT  'REQUIRES_CYP_WOR_PLOT_IS_NOT_ADJACENT_TO_DISTRICT_CYP_WOR' "RequirementId", 
        'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES'           "RequirementType", 
        '1'                                                         "Inverse"
FROM "Modifiers" m
WHERE m.ModifierId = 'SANGUINE_PACT_GRANT_CASTLES_ADJACENT_YIELDS';
--- RequirementArguments (not next to FTQ)
INSERT INTO "RequirementArguments" ("RequirementId", "Name", "Value")
SELECT  'REQUIRES_CYP_WOR_PLOT_IS_NOT_ADJACENT_TO_DISTRICT_CYP_WOR'  "RequirementId", 
        'DistrictType'                                              "Name", 
        'DISTRICT_CYP_WOR'                                          "Value"
FROM "Modifiers" m
WHERE m.ModifierId = 'SANGUINE_PACT_GRANT_CASTLES_ADJACENT_YIELDS';
--- RequirementSets
INSERT INTO "RequirementSets" ("RequirementSetId", "RequirementSetType")
SELECT  'REQ_SET_CYP_WOR_PLOT_HAS_VAMPIRE_CASTLE_AND_IS_NOT_ADJACENT_TO_DISTRICT_CYP_WOR'   "RequirementSetId", 
        'REQUIREMENTSET_TEST_ALL'                                                           "RequirementSetType"
FROM "Modifiers" m
WHERE m.ModifierId = 'SANGUINE_PACT_GRANT_CASTLES_ADJACENT_YIELDS';
--- RequirementSetRequirements (is vampire castle)
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId")
SELECT  'REQ_SET_CYP_WOR_PLOT_HAS_VAMPIRE_CASTLE_AND_IS_NOT_ADJACENT_TO_DISTRICT_CYP_WOR'   "RequirementSetId", 
        'REQUIRES_CYP_WOR_PLOT_HAS_VAMPIRE_CASTLE_REQ_SET_IS_MET'                           "RequirementId"
FROM "Modifiers" m
WHERE m.ModifierId = 'SANGUINE_PACT_GRANT_CASTLES_ADJACENT_YIELDS';
--- RequirementSetRequirements (is vampire castle)
INSERT INTO "RequirementSetRequirements" ("RequirementSetId", "RequirementId")
SELECT  'REQ_SET_CYP_WOR_PLOT_HAS_VAMPIRE_CASTLE_AND_IS_NOT_ADJACENT_TO_DISTRICT_CYP_WOR'   "RequirementSetId", 
        'REQUIRES_CYP_WOR_PLOT_IS_NOT_ADJACENT_TO_DISTRICT_CYP_WOR'                         "RequirementId"
FROM "Modifiers" m
WHERE m.ModifierId = 'SANGUINE_PACT_GRANT_CASTLES_ADJACENT_YIELDS';
--- Modifiers (replace req set)
UPDATE "Modifiers"
SET SubjectRequirementSetId = 'REQ_SET_CYP_WOR_PLOT_HAS_VAMPIRE_CASTLE_AND_IS_NOT_ADJACENT_TO_DISTRICT_CYP_WOR'
WHERE ModifierId = 'SANGUINE_PACT_GRANT_CASTLES_ADJACENT_YIELDS';