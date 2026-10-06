// ============================================================================
// REQUÊTE   : stg_ExternalContext
// OBJECTIF  : Choisir la préparation des compléments : CSV fourni, fichiers
//             bruts ou sources en ligne
// DÉPENDANCES: pExternalSourceMode, fxReadCsv, fxPercent, fxAssertUnique,
//             stg_ExternalContextFromSources
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Mode = pExternalSourceMode,
    Output =
        if Mode = "CSV fourni" then
            let
                Source = fxReadCsv("ExternalContextCountryYear.csv"),
                Typed = Table.TransformColumnTypes(
                    Source,
                    {
                        {"Country", type text},
                        {"ISO3", type text},
                        {"Year", Int64.Type},
                        {"SanitationBasicPercent", type number},
                        {"HygieneBasicPercent", type number},
                        {"LandArea1000Ha", type number},
                        {"FAOLandFlag", type text}
                    },
                    "en-US"
                ),
                // La superficie source est en 1000 hectares : 1000 ha = 10 km²
                Converted = Table.TransformColumns(
                    Typed,
                    {
                        {"SanitationBasicPercent", each fxPercent(_), type number},
                        {"HygieneBasicPercent", each fxPercent(_), type number},
                        {"LandArea1000Ha", each if _ = null then null else _ * 10, type number}
                    }
                ),
                Named = Table.RenameColumns(
                    Converted,
                    {
                        {"SanitationBasicPercent", "SanitationBasicTotal"},
                        {"HygieneBasicPercent", "HygieneBasicTotal"},
                        {"LandArea1000Ha", "LandAreaKm2"}
                    }
                ),
                Selected = Table.SelectColumns(
                    Named, {"Country", "Year", "SanitationBasicTotal", "HygieneBasicTotal", "LandAreaKm2"}
                ),
                Unique = fxAssertUnique(Selected, {"Country", "Year"}, "stg_ExternalContext")
            in
                Unique
        else if Mode = "Fichiers bruts" or Mode = "En ligne" then
            stg_ExternalContextFromSources
        else
            error Error.Record("InvalidExternalMode", "Valeurs admises : CSV fourni, Fichiers bruts, En ligne", Mode)
in
    Output