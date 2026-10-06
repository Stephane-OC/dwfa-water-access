// ============================================================================
// REQUÊTE   : fxNormalizeCountry
// OBJECTIF  : Harmoniser les noms de pays sans rapprochement approximatif
// DÉPENDANCES: Aucune
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

(country as nullable text) as nullable text =>
    let
        Clean = if country = null then null else Text.Trim(Text.Clean(country)),
        // Variante FAO alignée sur le référentiel OMS. Chine traitée par source
        Canonical = if Clean = "North Macedonia" then "Republic of North Macedonia" else Clean
    in
        Canonical