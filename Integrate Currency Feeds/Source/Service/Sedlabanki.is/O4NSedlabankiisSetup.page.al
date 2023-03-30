page 73421 "O4N Sedlabanki.is Setup"
{
    Caption = 'Sedlabanki.is Setup';
    PageType = Card;
    SourceTable = "O4N Sedlabanki.is Setup";
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
                    ToolTip = 'Specifies the rate type to download.';
                }
            }
        }
    }


    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
