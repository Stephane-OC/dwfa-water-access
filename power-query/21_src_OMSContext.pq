// ============================================================================
// REQUÊTE   : src_OMSContext
// OBJECTIF  : Préparer les totaux nationaux d’assainissement et d’hygiène
//             depuis les JSON OMS ou leur API
// DÉPENDANCES: pExternalSourceMode, pExternalFolder, Dim_Country,
//             fxPercent, fxAssertUnique, fxLatestExternalFile
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Folder = Text.TrimEnd(pExternalFolder, {"\", "/"}),
    Geo = fxAssertUnique(Table.SelectColumns(Dim_Country, {"Country", "ISO3"}), {"ISO3"}, "OMS ISO3"),
    ReadPage = (path as text, query as record) as record =>
        Json.Document(
            Web.Contents(
                "https://ghoapi.azureedge.net", [RelativePath = path, Query = query, Timeout = #duration(0, 0, 3, 0)]
            )
        ),
    ReadAll = (indicator as text) as list =>
        let
            Filter = "SpatialDimType eq 'COUNTRY' and Dim1 eq 'RESIDENCEAREATYPE_TOTL' and TimeDim ge 2000 and TimeDim le 2018",
            First = ReadPage("api/" & indicator, [#"$filter" = Filter]),
            Pages = List.Generate(
                () => [Doc = First, More = true],
                each [More],
                each
                    let
                        Next = Record.FieldOrDefault([Doc], "@odata.nextLink", null)
                    in
                        if Next = null then
                            [Doc = null, More = false]
                        else
                            let
                                Parts = Uri.Parts(Next)
                            in
                                if Text.Lower(Parts[Host]) <> "ghoapi.azureedge.net" then
                                    error
                                        Error.Record(
                                            "UnexpectedWHOHost", "Hôte de pagination inattendu", Parts[Host]
                                        )
                                else
                                    [Doc = ReadPage(Text.TrimStart(Parts[Path], "/"), Parts[Query]), More = true],
                each[Doc][value]
            ),
            Combined = List.Combine(Pages)
        in
            Combined,
    GetIndicator = (indicator as text, localFile as text, metric as text) as table =>
        let
            Records =
                if pExternalSourceMode = "En ligne" then
                    ReadAll(indicator)
                else
                    let
                        Doc = Json.Document(File.Contents(fxLatestExternalFile({indicator}, {".json"})))
                    in
                        if Record.FieldOrDefault(Doc, "@odata.nextLink", null) <> null then
                            error
                                Error.Record(
                                    "IncompleteWHOExtract",
                                    "Extraction JSON incomplète ; utiliser le mode En ligne",
                                    localFile
                                )
                        else
                            Doc[value],
            Raw = Table.FromRecords(Records),
            Selected = Table.SelectRows(
                Raw,
                each
                    [IndicatorCode] = indicator
                    and [SpatialDimType] = "COUNTRY"
                    and [TimeDimType] = "YEAR"
                    and [Dim1] = "RESIDENCEAREATYPE_TOTL"
                    and [Dim2] = null
                    and [Dim3] = null
                    and [TimeDim] >= 2000
                    and [TimeDim] <= 2018
            ),
            Fields = Table.SelectColumns(Selected, {"SpatialDim", "TimeDim", "NumericValue"}),
            Named = Table.RenameColumns(
                Fields, {{"SpatialDim", "ISO3"}, {"TimeDim", "Year"}, {"NumericValue", "Rate"}}
            ),
            Typed = Table.TransformColumnTypes(
                Named, {{"ISO3", type text}, {"Year", Int64.Type}, {"Rate", type number}}, "en-US"
            ),
            Unique = fxAssertUnique(Typed, {"ISO3", "Year"}, indicator),
            Joined = Table.NestedJoin(Unique, {"ISO3"}, Geo, {"ISO3"}, "CountryMap", JoinKind.Inner),
            Expanded = Table.ExpandTableColumn(Joined, "CountryMap", {"Country"}),
            Fraction = Table.TransformColumns(Expanded, {{"Rate", each fxPercent(_), type number}}),
            Metric = Table.AddColumn(Fraction, "Metric", each metric, type text),
            Output = Table.SelectColumns(Metric, {"Country", "Year", "Metric", "Rate"})
        in
            Output,
    Sanitation = GetIndicator(
        "WSH_SANITATION_BASIC", "WHO_WSH_SANITATION_BASIC_2000_2018.json", "SanitationBasicTotal"
    ),
    Hygiene = GetIndicator("WSH_HYGIENE_BASIC", "WHO_WSH_HYGIENE_BASIC_2000_2018.json", "HygieneBasicTotal"),
    Combined = fxAssertUnique(
        Table.Combine({Sanitation, Hygiene}), {"Country", "Year", "Metric"}, "OMS indicateur pays année"
    ),
    Pivoted = Table.Pivot(Combined, {"SanitationBasicTotal", "HygieneBasicTotal"}, "Metric", "Rate"),
    Output = Table.TransformColumnTypes(
        Pivoted,
        {
            {"Country", type text},
            {"Year", Int64.Type},
            {"SanitationBasicTotal", type number},
            {"HygieneBasicTotal", type number}
        },
        "en-US"
    )
in
    Output