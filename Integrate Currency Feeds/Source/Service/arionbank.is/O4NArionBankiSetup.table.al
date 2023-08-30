table 73403 "O4N Arion Banki Setup"
{
    Caption = 'Arion Banki Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Rate Type"; Enum "O4N Arion Banki Rate Type")
        {
            Caption = 'Rate Type';
            DataClassification = SystemMetadata;
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
