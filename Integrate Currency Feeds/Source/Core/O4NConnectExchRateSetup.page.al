page 73402 "O4N Connect Exch. Rate Setup"
{
    Caption = 'Connect Exch. Rate Setup';
    PageType = Card;
    SourceTable = "O4N Connect Exch. Rate Setup";
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Overwrite Policy"; Rec."Overwrite Policy")
                {
                    Caption = 'Overwrite Policy';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the overwrite policy for imported currency exchange rates.';
                }
                field("Cache Service Url"; Rec."Cache Service Url")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cache Service Url field.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    Caption = 'Start Date';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start date that will be used as the first possible date to download the exchange rates.';
                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        GetNextPeriod();
                    end;
                }
                field("Starting Date Formula"; Rec."Starting Date Formula")
                {
                    Caption = 'Starting Date Formula';
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the imported currency exchange rate date will we adjusted using this date formula.';
                }
            }
            group(Period)
            {
                Caption = 'Period';
                field(NextPeriodStartField; NextPeriodStart)
                {
                    Editable = false;
                    Caption = 'Next Period Start';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the next currency period start date based on G/L Entries, Currency Exchange Rates and the Start Date specifies in the General tab.';
                }
                field(NextPeriodEndField; NextPeriodEnd)
                {
                    Editable = false;
                    Caption = 'Next Period End';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the next currency period end date based on G/L Entries, Currency Exchange Rates and the Start Date specifies in the General tab.';
                }
            }
        }
    }

    var
        NextPeriodStart: Date;
        NextPeriodEnd: Date;


    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        GetNextPeriod();
    end;

    local procedure GetNextPeriod()
    var
        DateMgt: Codeunit "O4N Currency Date Mgt.";
    begin
        DateMgt.GetCurrencyPeriod('', false, '', NextPeriodStart, NextPeriodEnd);
    end;
}
