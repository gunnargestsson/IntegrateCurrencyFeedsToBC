page 73401 "O4N Currency ISO List"
{
    Caption = 'Connect Currency ISO List';
    PageType = List;
    SourceTable = Currency;
    SourceTableTemporary = true;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("ISO Code"; Rec."ISO Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the ISO Code field';
                }
                field("ISO Numeric Code"; Rec."ISO Numeric Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the ISO Numeric Code field';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field';
                }
                field("Amount Decimal Places"; Rec."Amount Decimal Places")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Amount Decimal Places field';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        CurrencyISOMgt: Codeunit "O4N Currency ISO Mgt";
    begin
        CurrencyISOMgt.GetISOList(Rec);
    end;

}
