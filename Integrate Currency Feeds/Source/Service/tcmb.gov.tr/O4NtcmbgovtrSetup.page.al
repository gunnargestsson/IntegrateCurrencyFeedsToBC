page 73428 "O4N tcmb.gov.tr Setup"
{
    Caption = 'tcmb.gov.tr Setup';
    PageType = Card;
    SourceTable = "O4N tcmb.gov.tr Setup";
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
