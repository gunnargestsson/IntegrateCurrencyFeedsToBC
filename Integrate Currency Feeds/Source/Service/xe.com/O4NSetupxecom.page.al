page 73424 "O4N Setup xe.com"
{
    Caption = 'Setup xe.com';
    PageType = Card;
    SourceTable = "O4N Setup xe.com";
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            group(Authentication)
            {
                Caption = 'Authentication';
                field("Account ID"; AccountID)
                {
                    Caption = 'Account ID';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Account ID for the service.';
                    trigger OnValidate()
                    begin
                        SecretService.StoreSecret(Rec."Account ID Storage Key", AccountID);
                        Rec.GetAccountInfo();
                    end;
                }
                field("Account API Key"; AccountAPIKey)
                {
                    Caption = 'Account API Key';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Account API Key for the service.';
                    ExtendedDatatype = Masked;
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
                    Caption = 'Organization';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Organization field';
                }
                field("Subscription Id"; Rec."Subscription Id")
                {
                    Caption = 'Subscription Id';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Subscription Id field';
                }
                field("Subscription Start Time"; Rec."Subscription Start Time")
                {
                    Caption = 'Subscription Start Time';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Subscription Start Time field';
                }
                field("Subscription End Time"; Rec."Subscription End Time")
                {
                    Caption = 'Subscription End Time';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Subscription End Time field';
                }
                field(Package; Rec.Package)
                {
                    Caption = 'Package';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Package field';
                }
                field("Package Limit"; Rec."Package Limit")
                {
                    Caption = 'Package Limit';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Package Limit field';
                }
                field("Package Limit Remaining"; Rec."Package Limit Remaining")
                {
                    Caption = 'Package Limit Remaining';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Package Limit Remaining field';
                }
            }
        }
    }

    var
        SecretService: Codeunit "O4N Curr. Exch. Rate Secret";
        AccountID: Text;
        AccountAPIKey: Text;

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
