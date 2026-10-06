// ============================================================================
// REQUÊTE   : stg_ExternalContextFromSources
// OBJECTIF  : Assembler les sources OMS et FAO sur la grille des pays et
//             des années du modèle
// DÉPENDANCES: Dim_Country, Dim_Year, src_OMSContext, src_FAOLand,
//             fxAssertUnique
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Countries = Table.SelectColumns(Dim_Country, {"Country"}),
    WithYears = Table.AddColumn(Countries, "Years", each Dim_Year),
    Grid = Table.ExpandTableColumn(WithYears, "Years", {"Year"}),
    WHOJoin = Table.NestedJoin(
        Grid, {"Country", "Year"}, src_OMSContext, {"Country", "Year"}, "WHO", JoinKind.LeftOuter
    ),
    WHO = Table.ExpandTableColumn(WHOJoin, "WHO", {"SanitationBasicTotal", "HygieneBasicTotal"}),
    FAOJoin = Table.NestedJoin(WHO, {"Country", "Year"}, src_FAOLand, {"Country", "Year"}, "FAO", JoinKind.LeftOuter),
    FAO = Table.ExpandTableColumn(FAOJoin, "FAO", {"LandAreaKm2"}),
    Typed = Table.TransformColumnTypes(
        FAO,
        {
            {"Country", type text},
            {"Year", Int64.Type},
            {"SanitationBasicTotal", type number},
            {"HygieneBasicTotal", type number},
            {"LandAreaKm2", type number}
        },
        "en-US"
    ),
    Unique = fxAssertUnique(Typed, {"Country", "Year"}, "Compléments OMS FAO"),
    Output =
        if Table.RowCount(Unique) <> Table.RowCount(Countries) * Table.RowCount(Dim_Year) then
            error
                Error.Record(
                    "ExternalGridSize", "La jointure a modifié la taille de la grille", Table.RowCount(Unique)
                )
        else
            Unique
in
    Output