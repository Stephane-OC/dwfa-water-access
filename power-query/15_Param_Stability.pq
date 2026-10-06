// ============================================================================
// REQUÊTE   : Param_Stability
// OBJECTIF  : Seuil minimal de stabilité modifiable par segment ; table
//             déconnectée
// DÉPENDANCES: Aucune
// CHARGEMENT: Activé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Source = Table.FromList(List.Transform({-35..25}, each _ / 10), Splitter.SplitByNothing(), {"Minimum"}),
    Typed = Table.TransformColumnTypes(Source, {{"Minimum", type number}})
in
    Typed