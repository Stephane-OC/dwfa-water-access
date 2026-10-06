// ============================================================================
// REQUÊTE   : stg_Water
// OBJECTIF  : Accès à au moins un service basique et service géré en toute
//             sécurité
// DÉPENDANCES: fxReadCsv, fxNormalizeCountry, fxPercent, fxAssertUnique
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = fxReadCsv("BasicAndSafelyManagedDrinkingWaterServices.csv"),
    Named = Table.RenameColumns(
        Source,
        {
            {"Population using at least basic drinking-water services (%)", "Basic"},
            {"Population using safely managed drinking-water services (%)", "Safe"}
        }
    ),
    Typed = Table.TransformColumnTypes(
        Named,
        {
            {"Country", type text},
            {"Granularity", type text},
            {"Year", Int64.Type},
            {"Basic", type number},
            {"Safe", type number}
        },
        "en-US"
    ),
    Clean = Table.TransformColumns(
        Typed,
        {
            {"Country", fxNormalizeCountry, type text},
            {"Basic", fxPercent, type number},
            {"Safe", fxPercent, type number}
        }
    ),
    Unique = fxAssertUnique(Clean, {"Country", "Year", "Granularity"}, "Water")
in
    Unique