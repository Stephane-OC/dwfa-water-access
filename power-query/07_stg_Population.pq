// ============================================================================
// REQUÊTE   : stg_Population
// OBJECTIF  : Population en personnes, une ligne par pays année et milieu
// DÉPENDANCES: fxReadCsv, fxNormalizeCountry, fxAssertUnique
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = fxReadCsv("Population.csv"),
    Typed = Table.TransformColumnTypes(
        Source,
        {{"Country", type text}, {"Granularity", type text}, {"Year", Int64.Type}, {"Population", type number}},
        "en-US"
    ),
    Clean = Table.TransformColumns(Typed, {{"Country", fxNormalizeCountry, type text}}),
    // Le libellé China est un agrégat FAO. Prend mainland pour la ligne OMS China
    RemovedAggregate = Table.SelectRows(Clean, each [Country] <> "China"),
    Mainland = Table.TransformColumns(
        RemovedAggregate, {{"Country", each if _ = "China, mainland" then "China" else _, type text}}
    ),
    Persons = Table.TransformColumns(Mainland, {{"Population", each _ * 1000, type number}}),
    Selected = Table.SelectRows(Persons, each List.Contains({"Total", "Urban", "Rural"}, [Granularity])),
    Unique = fxAssertUnique(Selected, {"Country", "Year", "Granularity"}, "Population")
in
    Unique