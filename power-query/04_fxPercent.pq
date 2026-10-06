// ============================================================================
// REQUÊTE   : fxPercent
// OBJECTIF  : Convertir un taux source 0–100 en fraction 0–1 avec contrôle
// DÉPENDANCES: Aucune
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

(value as nullable number) as nullable number =>
    if value = null then
        null
    else if value < 0 or value > 100.001 then
        error Error.Record("InvalidPercent", "Pourcentage hors bornes", value)
        // La source contient 100.00001 : corrige uniquement cette précision numérique
    else
        List.Min({value, 100}) / 100