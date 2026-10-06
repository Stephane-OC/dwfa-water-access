// ============================================================================
// REQUÊTE   : QA_MissingData
// OBJECTIF  : Contrôle des données disponibles par année, sans ajouter de
//             table au modèle
// DÉPENDANCES: Fact_CountryYear
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = Fact_CountryYear,
    ByYear = Table.Group(
        Source,
        {"Year"},
        {
            {"Rows", each Table.RowCount(_), Int64.Type},
            {"PopulationCountries", each List.NonNullCount([PopulationTotal]), Int64.Type},
            {"BasicCountries", each List.NonNullCount([BasicTotal]), Int64.Type},
            {"SafeCountries", each List.NonNullCount([SafeTotal]), Int64.Type},
            {"MortalityCountries", each List.NonNullCount([MortalityRate]), Int64.Type},
            {"StabilityCountries", each List.NonNullCount([PoliticalStability]), Int64.Type}
        }
    )
in
    ByYear