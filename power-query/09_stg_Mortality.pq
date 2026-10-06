// ============================================================================
// REQUÊTE   : stg_Mortality
// OBJECTIF  : 183 pays en 2016 ; taux pour 100 000 et décès WASH estimés
// DÉPENDANCES: fxReadCsv, fxNormalizeCountry, fxAssertUnique
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = fxReadCsv("MortalityRateAttributedToWater.csv"),
    Named = Table.RenameColumns(
        Source,
        {
            {"Mortality rate attributed to exposure to unsafe WASH services", "MortalityRate"},
            {"WASH deaths", "WASHDeaths"}
        }
    ),
    Typed = Table.TransformColumnTypes(
        Named,
        {
            {"Country", type text},
            {"Granularity", type text},
            {"Year", Int64.Type},
            {"MortalityRate", type number},
            {"WASHDeaths", type number}
        },
        "en-US"
    ),
    Clean = Table.TransformColumns(Typed, {{"Country", fxNormalizeCountry, type text}}),
    // Total seul : Male et Female sont des sous-ensembles, pas des populations à ajouter.
    Total = Table.SelectRows(Clean, each [Granularity] = "Total"),
    Unique = fxAssertUnique(Total, {"Country", "Year"}, "Mortality")
in
    Unique