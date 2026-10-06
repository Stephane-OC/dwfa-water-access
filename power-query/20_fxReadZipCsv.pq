// ============================================================================
// REQUÊTE   : fxReadZipCsv
// OBJECTIF  : Lire un CSV dans une archive ZIP Store ou Deflate, sans
//             extraction manuelle
// DÉPENDANCES: Aucune
// CHARGEMENT: Désactivé
// CRÉATION  : Nouvelle source > Requête vide > Éditeur avancé
// ============================================================================

(archive as binary, fileName as text) as table =>
    let
        Zip = Binary.Buffer(archive),
        Size = Binary.Length(Zip),
        UInt = (offset as number, length as number) as number =>
            let
                Bytes = Binary.ToList(Binary.Range(Zip, offset, length))
            in
                List.Sum(List.Transform({0..length - 1}, each Bytes{_} * Number.Power(256, _))),
        Find = (offset as number) as binary =>
            if offset + 4 > Size then
                error Error.Record("ZipFileNotFound", "CSV absent de l'archive", fileName)
            else if UInt(offset, 4) <> 67324752 then
                error Error.Record("ZipFileNotFound", "CSV absent ou format ZIP non pris en charge", fileName)
            else
                let
                    Flags = UInt(offset + 6, 2),
                    Method = UInt(offset + 8, 2),
                    CompressedSize = UInt(offset + 18, 4),
                    UncompressedSize = UInt(offset + 22, 4),
                    NameLength = UInt(offset + 26, 2),
                    ExtraLength = UInt(offset + 28, 2),
                    EntryName = Text.FromBinary(Binary.Range(Zip, offset + 30, NameLength), TextEncoding.Utf8),
                    PayloadOffset = offset + 30 + NameLength + ExtraLength,
                    NextOffset = PayloadOffset + CompressedSize,
                    Unsupported =
                        Number.Mod(Flags, 2) = 1
                        or Number.Mod(Number.IntegerDivide(Flags, 8), 2) = 1
                        or CompressedSize = 4294967295
                        or UncompressedSize = 4294967295,
                    Result =
                        if Unsupported then
                            error
                                Error.Record(
                                    "UnsupportedZip",
                                    "ZIP chiffré, ZIP64 ou descripteur de données non pris en charge",
                                    EntryName
                                )
                        else if NextOffset > Size then
                            error Error.Record("TruncatedZip", "Archive ZIP incomplète", EntryName)
                        else if EntryName <> fileName then
                            @Find(NextOffset)
                        else
                            let
                                Payload = Binary.Range(Zip, PayloadOffset, CompressedSize),
                                Unpacked =
                                    if Method = 0 then
                                        Payload
                                    else if Method = 8 then
                                        Binary.Decompress(Payload, Compression.Deflate)
                                    else
                                        error
                                            Error.Record(
                                                "UnsupportedZipCompression",
                                                "Méthode de compression non prise en charge",
                                                Method
                                            )
                            in
                                if Binary.Length(Unpacked) <> UncompressedSize then
                                    error
                                        Error.Record("InvalidZipLength", "Taille décompressée incorrecte", EntryName)
                                else
                                    Unpacked
                in
                    Result,
        CsvBinary = Find(0),
        Csv = Csv.Document(CsvBinary, [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
        Headers = Table.PromoteHeaders(Csv, [PromoteAllScalars = true]),
        MissingAsNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers))
    in
        MissingAsNull