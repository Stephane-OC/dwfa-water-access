// ============================================================================
// REQUÊTE   : stg_Stability
// OBJECTIF  : Stabilité politique ; 2001 absent ; pas de remplacement par
//             zéro
// DÉPENDANCES: fxReadCsv, fxNormalizeCountry, fxAssertUnique
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = fxReadCsv("PoliticalStability.csv"),
    Named = Table.RenameColumns(Source, {{"Political_Stability", "PoliticalStability"}}),
    Typed = Table.TransformColumnTypes(
        Named,
        {
            {"Country", type text},
            {"Granularity", type text},
            {"Year", Int64.Type},
            {"PoliticalStability", type number}
        },
        "en-US"
    ),
    Clean = Table.TransformColumns(Typed, {{"Country", fxNormalizeCountry, type text}}),
    Mainland = Table.TransformColumns(Clean, {{"Country", each if _ = "China, mainland" then "China" else _, type text}}),
    Total = Table.SelectRows(Mainland, each [Granularity] = "Total"),
    Unique = fxAssertUnique(Total, {"Country", "Year"}, "PoliticalStability")
in
    Unique