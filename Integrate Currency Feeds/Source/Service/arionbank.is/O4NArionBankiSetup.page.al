page 73403 "O4N Arion Banki Setup"
{
    Caption = 'Arion Banki Setup';
    PageType = Card;
    SourceTable = "O4N Arion Banki Setup";
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
                field("Rate Type"; Rec."Rate Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rate type to be downloaded from Arion Banki';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then begin
            Rec.Init();
            Rec.Insert();
        end
    end;
}
