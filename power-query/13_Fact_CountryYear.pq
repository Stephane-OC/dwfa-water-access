// ============================================================================
// REQUÊTE   : Fact_CountryYear
// OBJECTIF  : Une ligne par pays année ; 3 686 lignes ; table de faits
//             unique
// DÉPENDANCES: Dim_Country, Dim_Year, stg_Population, stg_Water,
//             stg_Mortality, stg_Stability, stg_ExternalContext,
//             fxAssertUnique
// CHARGEMENT: Activé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    // Base complète : conserve les pays même lorsqu'un indicateur est absent
    Countries = Table.SelectColumns(Dim_Country, {"Country"}),
    WithYears = Table.AddColumn(Countries, "Years", each Dim_Year),
    Grid = Table.ExpandTableColumn(WithYears, "Years", {"Year"}),
    // Jointures 1:1 par pays et année ; les fonctions de préparation contrôlent les clés.
    JoinMetric = (base as table, source as table, cols as list, names as list) as table =>
        Table.ExpandTableColumn(
            Table.NestedJoin(base, {"Country", "Year"}, source, {"Country", "Year"}, "Metric", JoinKind.LeftOuter),
            "Metric",
            cols,
            names
        ),
    PopTotal = JoinMetric(
        Grid, Table.SelectRows(stg_Population, each [Granularity] = "Total"), {"Population"}, {"PopulationTotal"}
    ),
    PopUrban = JoinMetric(
        PopTotal, Table.SelectRows(stg_Population, each [Granularity] = "Urban"), {"Population"}, {"PopulationUrban"}
    ),
    PopRural = JoinMetric(
        PopUrban, Table.SelectRows(stg_Population, each [Granularity] = "Rural"), {"Population"}, {"PopulationRural"}
    ),
    WaterTotal = JoinMetric(
        PopRural,
        Table.SelectRows(stg_Water, each [Granularity] = "Total"),
        {"Basic", "Safe"},
        {"BasicTotal", "SafeTotal"}
    ),
    WaterUrban = JoinMetric(
        WaterTotal,
        Table.SelectRows(stg_Water, each [Granularity] = "Urban"),
        {"Basic", "Safe"},
        {"BasicUrban", "SafeUrban"}
    ),
    WaterRural = JoinMetric(
        WaterUrban,
        Table.SelectRows(stg_Water, each [Granularity] = "Rural"),
        {"Basic", "Safe"},
        {"BasicRural", "SafeRural"}
    ),
    Mortality = JoinMetric(
        WaterRural, stg_Mortality, {"MortalityRate", "WASHDeaths"}, {"MortalityRate", "WASHDeaths"}
    ),
    Stability = JoinMetric(Mortality, stg_Stability, {"PoliticalStability"}, {"PoliticalStability"}),
    External = JoinMetric(
        Stability,
        stg_ExternalContext,
        {"SanitationBasicTotal", "HygieneBasicTotal", "LandAreaKm2"},
        {"SanitationBasicTotal", "HygieneBasicTotal", "LandAreaKm2"}
    ),
    Key = Table.AddColumn(External, "CountryYearKey", each [Country] & "|" & Text.From([Year], "en-US"), type text),
    // Types définitifs après les jointures ; les valeurs absentes restent null
    TypedFinal = Table.TransformColumnTypes(
        Key,
        {
            {"Country", type text},
            {"Year", Int64.Type},
            {"CountryYearKey", type text},
            {"PopulationTotal", type number},
            {"PopulationUrban", type number},
            {"PopulationRural", type number},
            {"BasicTotal", type number},
            {"SafeTotal", type number},
            {"BasicUrban", type number},
            {"SafeUrban", type number},
            {"BasicRural", type number},
            {"SafeRural", type number},
            {"MortalityRate", type number},
            {"WASHDeaths", type number},
            {"PoliticalStability", type number},
            {"SanitationBasicTotal", type number},
            {"HygieneBasicTotal", type number},
            {"LandAreaKm2", type number}
        },
        "en-US"
    ),
    Unique = fxAssertUnique(TypedFinal, {"CountryYearKey"}, "Fact_CountryYear")
in
    Unique