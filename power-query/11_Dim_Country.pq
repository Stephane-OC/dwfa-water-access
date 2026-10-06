// ============================================================================
// REQUÊTE   : Dim_Country
// OBJECTIF  : 194 pays ; dimension du schéma en étoile
// DÉPENDANCES: stg_RegionCountry, stg_CountryGeography, fxAssertUnique
// CHARGEMENT: Activé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = stg_RegionCountry,
    Join = Table.NestedJoin(Source, {"Country"}, stg_CountryGeography, {"Country"}, "Geo", JoinKind.LeftOuter),
    Expanded = Table.ExpandTableColumn(Join, "Geo", {"ISO3", "Continent"}),
    Missing = Table.SelectRows(Expanded, each [ISO3] = null or [Continent] = null),
    Checked =
        if Table.RowCount(Missing) > 0 then
            error Error.Record("MissingGeography", "Compléter le référentiel géographique", Missing)
        else
            Expanded,
    Unique = fxAssertUnique(Checked, {"Country"}, "Dim_Country")
in
    Unique