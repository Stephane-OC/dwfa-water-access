// ============================================================================
// REQUÊTE   : src_FAOLand
// OBJECTIF  : Préparer la superficie terrestre depuis le ZIP FAOSTAT et
//             convertir les milliers d’hectares en km²
// DÉPENDANCES: pExternalSourceMode, pExternalFolder, fxReadZipCsv,
//             Dim_Country, fxAssertUnique, fxLatestExternalFile
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

let
    Folder = Text.TrimEnd(pExternalFolder, {"\", "/"}),
    Archive = Binary.Buffer(
        if pExternalSourceMode = "En ligne" then
            Web.Contents(
                "https://bulks-faostat.fao.org",
                [
                    RelativePath = "production/Inputs_LandUse_E_All_Data_(Normalized).zip",
                    Timeout = #duration(0, 0, 3, 0)
                ]
            )
        else
            File.Contents(
                fxLatestExternalFile(
                    {"FAOSTAT_Inputs_LandUse_Source", "Inputs_LandUse_E_All_Data_(Normalized)"}, {".zip"}
                )
            )
    ),
    Codes = fxReadZipCsv(Archive, "Inputs_LandUse_E_AreaCodes.csv"),
    TypedCodes = Table.TransformColumnTypes(Codes, {{"Area Code", type text}, {"Area", type text}}, "en-US"),
    CountryNames = Table.AddColumn(
        Table.SelectColumns(Dim_Country, {"Country"}),
        "FAOName",
        each
            if [Country] = "China" then
                "China; mainland"
            else if [Country] = "Nauru" then
                "Naoero"
            else if [Country] = "Netherlands" then
                "Netherlands (Kingdom of the)"
            else if [Country] = "Republic of North Macedonia" then
                "North Macedonia"
            else if [Country] = "Turkey" then
                "Türkiye"
            else
                [Country],
        type text
    ),
    MapJoin = Table.NestedJoin(CountryNames, {"FAOName"}, TypedCodes, {"Area"}, "FAOCode", JoinKind.LeftOuter),
    MapExpanded = Table.ExpandTableColumn(MapJoin, "FAOCode", {"Area Code"}),
    MissingNames = Table.SelectRows(MapExpanded, each [Area Code] = null),
    Map =
        if Table.RowCount(MissingNames) > 0 then
            error
                Error.Record(
                    "MissingFAOCountryMapping", "Libellés FAO à rapprocher explicitement", MissingNames[Country]
                )
        else
            fxAssertUnique(MapExpanded, {"Area Code"}, "Correspondance pays FAO"),
    Raw = fxReadZipCsv(Archive, "Inputs_LandUse_E_All_Data_(Normalized).csv"),
    Land = Table.SelectRows(
        Raw, each [Item Code] = "6601" and [Element Code] = "5110" and [Year] >= "2000" and [Year] <= "2018"
    ),
    UnitChecked =
        if Table.RowCount(Table.SelectRows(Land, each [Unit] <> "1000 ha")) > 0 then
            error Error.Record("UnexpectedFAOUnit", "Unité attendue : 1000 ha", null)
        else
            Land,
    Fields = Table.SelectColumns(UnitChecked, {"Area Code", "Year", "Value"}),
    Typed = Table.TransformColumnTypes(
        Fields, {{"Area Code", type text}, {"Year", Int64.Type}, {"Value", type number}}, "en-US"
    ),
    Joined = Table.NestedJoin(Typed, {"Area Code"}, Map, {"Area Code"}, "CountryMap", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(Joined, "CountryMap", {"Country"}),
    Converted = Table.AddColumn(
        Expanded,
        "LandAreaKm2",
        each
            if [Value] = null then
                null
            else if [Value] <= 0 then
                error Error.Record("InvalidLandArea", "Superficie non positive", [Country])
            else
                [Value] * 10,
        type number
    ),
    Output = fxAssertUnique(
        Table.SelectColumns(Converted, {"Country", "Year", "LandAreaKm2"}), {"Country", "Year"}, "FAO pays année"
    )
in
    Output