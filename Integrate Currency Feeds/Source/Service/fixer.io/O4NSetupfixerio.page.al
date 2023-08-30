page 73425 "O4N Setup fixer.io"
{
    Caption = 'Setup fixer.io';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "O4N Setup fixer.io";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Authentication)
            {
                Caption = 'Authentication';

                field("Account API Key"; AccountAPIKey)
                {
                    ApplicationArea = All;
                    Caption = 'Account API Key';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the value of the Account API Key for the service.';
                    trigger OnValidate()
                    begin
                        SecretService.StoreSecret(Rec."Account API Key Storage Key", AccountAPIKey);
                    end;
                }
            }
            group(Subscription)
            {
                Caption = 'Subscription';
                field("Subscription Type"; Rec."Subscription Type")
                {
                    ApplicationArea = All;
                    Caption = 'Subscription Type';
                    ToolTip = 'Specifies the subscription type for fixer.io.  Subscription type will affect the request made from Business Central to fixer.io.';
                }
            }
        }
    }

    var
        SecretService: Codeunit "O4N Curr. Exch. Rate Secret";
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
        AccountAPIKey := SecretService.GetSecret(Rec."Account API Key Storage Key");
    end;
}
