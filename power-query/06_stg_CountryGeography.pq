// ============================================================================
// REQUÊTE   : stg_CountryGeography
// OBJECTIF  : Référentiel manuel de continents et codes ISO3 auditable
// DÉPENDANCES: fxReadCsv, fxAssertUnique
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = fxReadCsv("CountryGeography.csv"),
    Typed = Table.TransformColumnTypes(
        Source,
        {{"Country", type text}, {"ISO3", type text}, {"Continent", type text}, {"WHORegion", type text}},
        "en-US"
    ),
    Unique = fxAssertUnique(Typed, {"Country"}, "CountryGeography")
in
    Unique