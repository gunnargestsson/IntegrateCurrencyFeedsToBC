table 73403 "O4N Arion Banki Setup"
{
    Caption = 'Arion Banki Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(2; "Rate Type"; enum "O4N Arion Banki Rate Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Rate Type';
            InitValue = "SalesPurchaseAverage";
        }

    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
