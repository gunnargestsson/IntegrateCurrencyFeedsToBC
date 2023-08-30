table 73400 "O4N Curr. Exch. Rate Service"
{
    Caption = 'Currency Exch. Rate Service';
    DataClassification = SystemMetadata;
    LookupPageId = "O4N Curr. Exch. Rate Services";
    DrillDownPageId = "O4N Curr. Exch. Rate Services";

    fields
    {
        field(1; Url; Text[250])
        {
            Caption = 'Url';
            DataClassification = SystemMetadata;
        }
        field(2; "Codeunit Id"; Integer)
        {
            Caption = 'Codeunit Id';
            DataClassification = SystemMetadata;
            TableRelation = AllObj."Object ID" where("Object Type" = const(Codeunit));
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(5; "Setup Page Id"; Integer)
        {
            Caption = 'Setup Page Id';
            DataClassification = SystemMetadata;
        }
        field(10; "Service Provider"; Text[250])
        {
            Caption = 'Service Provider';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Cache Url"; Text[250])
        {
            Caption = 'Cache Url';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; Url)
        {
            Clustered = true;
        }
    }

    /// <summary> 
    /// Description for DiscoverCurrencyMappingCodeunits.
    /// </summary>
    [BusinessEvent(false)]
    procedure DiscoverCurrencyMappingCodeunits()
    begin
    end;

}
