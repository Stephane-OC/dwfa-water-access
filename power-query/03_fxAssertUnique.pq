// ============================================================================
// REQUÊTE   : fxAssertUnique
// OBJECTIF  : Bloquer une jointure multiplicative au lieu de supprimer
//             arbitrairement les doublons
// DÉPENDANCES: Aucune
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

(input as table, keys as list, label as text) as table =>
    let
        Counts = Table.Group(input, keys, {{"RowCount", each Table.RowCount(_), Int64.Type}}),
        Duplicates = Table.SelectRows(Counts, each [RowCount] > 1),
        Checked =
            if Table.RowCount(Duplicates) > 0 then
                error Error.Record("DuplicateKey", "Clé non unique : " & label, Duplicates)
            else
                input
    in
        Checked