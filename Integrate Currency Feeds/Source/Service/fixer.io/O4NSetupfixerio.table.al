table 73425 "O4N Setup fixer.io"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(3; "Account API Key Storage Key"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Account API Key Storage Key';
        }
        field(4; "Subscription Type"; Enum "O4N fixer.io Subscription Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Subscription Type';
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

    procedure VerifyAuthorization()
    begin
        if SecretService.HasSecret("Account API Key Storage Key") then exit;
        Error(AuthorizationMissingErr, TableCaption());
    end;

    procedure GetAccessKey(): Text;
    begin
        exit(SecretService.GetSecret("Account API Key Storage Key"));
    end;


    var
        SecretService: Codeunit "O4N Curr. Exch. Rate Secret";
        AuthorizationMissingErr: Label 'Account API Key is missing in %1', Comment = '%1 = tablecaption';

}