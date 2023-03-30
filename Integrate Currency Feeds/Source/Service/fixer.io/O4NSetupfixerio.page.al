page 73425 "O4N Setup fixer.io"
{
    Caption = 'Setup fixer.io';
    PageType = Card;
    SourceTable = "O4N Setup fixer.io";
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

                field("Account API Key"; AccountAPIKey)
                {
                    Caption = 'Account API Key';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Account API Key for the service.';
                    ExtendedDatatype = Masked;
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
                    Caption = 'Subscription Type';
                    ApplicationArea = All;
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
