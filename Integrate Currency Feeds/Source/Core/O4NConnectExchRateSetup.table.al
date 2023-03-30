table 73402 "O4N Connect Exch. Rate Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Overwrite Policy"; enum "O4N Currency Overwrite Type")
        {
            Caption = 'Overwrite Policy';
            DataClassification = SystemMetadata;
        }
        field(3; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = SystemMetadata;
        }
        field(4; "Starting Date Formula"; DateFormula)
        {
            Caption = 'Starting Date Formula';
            DataClassification = CustomerContent;
        }

    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin

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

    /// <summary>
    /// Event to search for manual start date
    /// </summary>
    /// <param name="StartDate"></param>
    procedure OnAfterFindStartDate(var StartDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if not Get() then exit;

        if "Start Date" = 0D then exit;
        if CurrencyExchangeRate.IsEmpty() then
            StartDate := "Start Date"
        else
            if "Start Date" > StartDate then
                StartDate := "Start Date";
    end;

}