// ============================================================================
// REQUÊTE   : fxLatestExternalFile
// OBJECTIF  : Repérer le fichier brut le plus récent par date de
//             modification, puis par nom
// DÉPENDANCES: pExternalFolder
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

(nameTokens as list, extensions as list) as text =>
    let
        Folder = Text.TrimEnd(pExternalFolder, {"\", "/"}),
        Files = Folder.Contents(Folder),
        Candidates = Table.SelectRows(
            Files,
            (row as record) =>
                List.Contains(extensions, Text.Lower(row[Extension]))
                and List.AnyTrue(
                    List.Transform(
                        nameTokens, (token as text) => Text.Contains(row[Name], token, Comparer.OrdinalIgnoreCase)
                    )
                )
        ),
        Sorted = Table.Sort(Candidates, {{"Date modified", Order.Descending}, {"Name", Order.Ascending}}),
        Output =
            if Table.RowCount(Sorted) = 0 then
                error
                    Error.Record(
                        "MissingExternalSource",
                        "Aucun fichier brut correspondant dans le dossier",
                        [
                            Folder = Folder,
                            NameTokens = nameTokens,
                            Extensions = extensions
                        ]
                    )
            else
                Folder & "/" & Sorted{0}[Name]
    in
        Output