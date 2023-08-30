table 73401 "O4N Currency Buffer"
{
    Caption = 'O4N Currency Buffer';
    DataClassification = SystemMetadata;
    TableType = Temporary;
    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Temp Blob"; Blob)
        {
            Caption = 'Temp Blob';
            DataClassification = SystemMetadata;
        }
        field(3; "Get Structure"; Boolean)
        {
            Caption = 'Get Structure';
            DataClassification = SystemMetadata;
        }
        field(4; "Currency Filter"; Blob)
        {
            Caption = 'Currency Filter';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        Id := CreateGuid();
    end;

    trigger OnModify()
    begin
    end;

    trigger OnDelete()
    begin
    end;

    trigger OnRename()
    begin
    end;

    var
        DefineFiltersTxt: Label 'Specify currency filter for when the exchange rates will be applied.';

    /// <summary>
    /// Get Update ResponseInStream with content from Temp Blob.
    /// </summary>
    /// <param name="ResponseInStream">Parameter of type InStream.</param>
    procedure GetContent(var ResponseInStream: InStream)
    var
        Content: HttpContent;
        InStr: InStream;
    begin
        if not "Temp Blob".HasValue() then exit;
        CalcFields("Temp Blob");
        "Temp Blob".CreateInStream(InStr);
        Content.WriteFrom(InStr);
        Content.ReadAs(ResponseInStream);
    end;

    procedure GetFiltersAsTextDisplay(var CurrExchRateUpdServ: Record "Curr. Exch. Rate Update Setup"): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        FiltersRecordRef: RecordRef;
    begin
        CurrExchRateUpdServ.CalcFields("O4N Currency Filter");

        FiltersRecordRef.Open(Database::Currency);
        TempBlob.FromRecord(CurrExchRateUpdServ, CurrExchRateUpdServ.FieldNo("O4N Currency Filter"));

        if RequestPageParametersHelper.ConvertParametersToFilters(FiltersRecordRef, TempBlob) then
            exit(FiltersRecordRef.GetFilters);

        exit('');
    end;

    procedure ReadAsText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        if not "Temp Blob".HasValue() then exit;
        CalcFields("Temp Blob");
        "Temp Blob".CreateInStream(InStr);
        exit(TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.NewLine()));
    end;

    procedure SetSelectionFilter(var CurrExchRateUpdServ: Record "Curr. Exch. Rate Update Setup")
    var
        FiltersOutStream: OutStream;
        CurrentFilters: Text;
        NewFilters: Text;
    begin
        CurrentFilters := GetExistingFilters(CurrExchRateUpdServ);
        if not ShowRequestPageAndGetFilters(NewFilters, CurrentFilters, '', Database::Currency, DefineFiltersTxt) then exit;
        Clear(CurrExchRateUpdServ."O4N Currency Filter");
        CurrExchRateUpdServ."O4N Currency Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(NewFilters);
    end;

    local procedure GetExistingFilters(var CurrExchRateUpdServ: Record "Curr. Exch. Rate Update Setup") Filters: Text
    var
        FiltersInStream: InStream;
    begin
        CurrExchRateUpdServ.CalcFields("O4N Currency Filter");
        if not CurrExchRateUpdServ."O4N Currency Filter".HasValue then
            exit;

        CurrExchRateUpdServ."O4N Currency Filter".CreateInStream(FiltersInStream);
        FiltersInStream.Read(Filters);
    end;

    local procedure ShowRequestPageAndGetFilters(var NewFilters: Text; ExistingFilters: Text; EntityName: Code[20]; TableNum: Integer; PageCaption: Text) FiltersSet: Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPage: FilterPageBuilder;
    begin
        if not RequestPageParametersHelper.BuildDynamicRequestPage(FilterPage, EntityName, TableNum) then
            exit(false);

        if ExistingFilters <> '' then
            if not RequestPageParametersHelper.SetViewOnDynamicRequestPage(
                 FilterPage, ExistingFilters, EntityName, TableNum)
            then
                exit(false);

        FilterPage.PageCaption := PageCaption;
        if not FilterPage.RunModal() then
            exit(false);

        NewFilters :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPage, EntityName, TableNum);

        FiltersSet := true;
    end;
}