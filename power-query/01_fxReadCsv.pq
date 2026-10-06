// ============================================================================
// REQUÊTE   : fxReadCsv
// OBJECTIF  : Lecture UTF-8 commune de tous les fichiers
// DÉPENDANCES: pDataFolder
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

(fileName as text) as table =>
    let
        // Un seul chemin à modifier ; fonctionne avec ou sans séparateur final
        Folder = Text.TrimEnd(pDataFolder, {"\", "/"}),
        Source = Csv.Document(
            File.Contents(Folder & "/" & fileName), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
        ),
        Headers = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
        // Une cellule vide reste manquante avant les conversions numériques.
        MissingAsNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers))
    in
        MissingAsNull