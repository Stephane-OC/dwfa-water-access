// ============================================================================
// REQUÊTE   : stg_RegionCountry
// OBJECTIF  : Une ligne par pays avec sa région OMS
// DÉPENDANCES: fxReadCsv, fxNormalizeCountry, fxAssertUnique
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = fxReadCsv("RegionCountry.csv"),
    Names = Table.RenameColumns(Source, {{"COUNTRY (DISPLAY)", "Country"}, {"REGION (DISPLAY)", "WHORegion"}}),
    Clean = Table.TransformColumns(
        Names, {{"Country", fxNormalizeCountry, type text}, {"WHORegion", Text.Trim, type text}}
    ),
    Unique = fxAssertUnique(Clean, {"Country"}, "RegionCountry")
in
    Unique