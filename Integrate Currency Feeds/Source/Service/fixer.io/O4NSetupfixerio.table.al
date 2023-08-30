table 73425 "O4N Setup fixer.io"
{
    Caption = 'O4N Setup fixer.io';
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(3; "Account API Key Storage Key"; Guid)
        {
            Caption = 'Account API Key Storage Key';
            DataClassification = SystemMetadata;
        }
        field(4; "Subscription Type"; Enum "O4N fixer.io Subscription Type")
        {
            Caption = 'Subscription Type';
            DataClassification = SystemMetadata;
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

    var
        SecretService: Codeunit "O4N Curr. Exch. Rate Secret";
        AuthorizationMissingErr: Label 'Account API Key is missing in %1', Comment = '%1 = tablecaption';

    procedure GetAccessKey(): Text;
    begin
        exit(SecretService.GetSecret("Account API Key Storage Key"));
    end;

    procedure VerifyAuthorization()
    begin
        if SecretService.HasSecret("Account API Key Storage Key") then exit;
        Error(AuthorizationMissingErr, TableCaption());
    end;
}