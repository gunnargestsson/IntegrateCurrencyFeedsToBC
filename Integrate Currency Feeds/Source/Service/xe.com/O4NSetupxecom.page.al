page 73424 "O4N Setup xe.com"
{
    Caption = 'Setup xe.com';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "O4N Setup xe.com";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Authentication)
            {
                Caption = 'Authentication';
                field("Account ID"; AccountID)
                {
                    ApplicationArea = All;
                    Caption = 'Account ID';
                    ToolTip = 'Specifies the Account ID for the service.';
                    trigger OnValidate()
                    begin
                        SecretService.StoreSecret(Rec."Account ID Storage Key", AccountID);
                        Rec.GetAccountInfo();
                    end;
                }
                field("Account API Key"; AccountAPIKey)
                {
                    ApplicationArea = All;
                    Caption = 'Account API Key';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the value of the Account API Key for the service.';
                    trigger OnValidate()
                    begin
                        SecretService.StoreSecret(Rec."Account API Key Storage Key", AccountAPIKey);
                        Rec.GetAccountInfo();
                    end;
                }
            }
            group(AccountInfo)
            {
                Caption = 'Account Information';

                field(Organization; Rec.Organization)
                {
                    ApplicationArea = All;
                    Caption = 'Organization';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Organization field';
                }
                field("Subscription Id"; Rec."Subscription Id")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Id';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Subscription Id field';
                }
                field("Subscription Start Time"; Rec."Subscription Start Time")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Start Time';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Subscription Start Time field';
                }
                field("Subscription End Time"; Rec."Subscription End Time")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription End Time';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Subscription End Time field';
                }
                field(Package; Rec.Package)
                {
                    ApplicationArea = All;
                    Caption = 'Package';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Package field';
                }
                field("Package Limit"; Rec."Package Limit")
                {
                    ApplicationArea = All;
                    Caption = 'Package Limit';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Package Limit field';
                }
                field("Package Limit Remaining"; Rec."Package Limit Remaining")
                {
                    ApplicationArea = All;
                    Caption = 'Package Limit Remaining';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Package Limit Remaining field';
                }
            }
        }
    }

    var
        SecretService: Codeunit "O4N Curr. Exch. Rate Secret";
        AccountAPIKey: Text;
        AccountID: Text;

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then begin
            Rec.Init();
            Rec.Insert();
        end
    end;

    trigger OnAfterGetCurrRecord()
    begin
        AccountID := SecretService.GetSecret(Rec."Account ID Storage Key");
        AccountAPIKey := SecretService.GetSecret(Rec."Account API Key Storage Key");
    end;
}
