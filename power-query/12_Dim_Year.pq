// ============================================================================
// REQUÊTE   : Dim_Year
// OBJECTIF  : Une ligne par année ; données annuelles, sans calendrier
//             quotidien artificiel
// DÉPENDANCES: Aucune
// CHARGEMENT: Activé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = Table.FromList({2000..2018}, Splitter.SplitByNothing(), {"Year"}),
    Typed = Table.TransformColumnTypes(Source, {{"Year", Int64.Type}})
in
    Typed