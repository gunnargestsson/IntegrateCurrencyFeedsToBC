page 73400 "O4N Curr. Exch. Rate Services"
{

    ApplicationArea = All;
    Caption = 'Connected Exch. Rate Services';
    PageType = List;
    Editable = false;
    SourceTable = "O4N Curr. Exch. Rate Service";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Url; Rec.Url)
                {
                    ApplicationArea = All;
                    Caption = 'Url';
                    ToolTip = 'Specifies the Currency Exchange Rate Service Url to match.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description for the Connected Exchange Rate Service functionality.';
                    QuickEntry = false;
                }
                field("Service Provider"; Rec."Service Provider")
                {
                    ApplicationArea = All;
                    Caption = 'Service Provider';
                    ToolTip = 'Specifies a service provider Url for the connected exchange rate service.';
                    ExtendedDatatype = URL;
                    QuickEntry = false;
                }
                field("Codeunit Id"; Rec."Codeunit Id")
                {
                    ApplicationArea = All;
                    Caption = 'Codeunit Id';
                    ToolTip = 'Specifies the Codeunit Id to be executed for data handling.';
                    Visible = false;
                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ConnectSetup)
            {
                Caption = 'Connect Setup';
                ApplicationArea = All;
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Open SConnect etup for the currency exchange rate services.';
                RunObject = Page "O4N Connect Exch. Rate Setup";
            }
            action(Setup)
            {
                Caption = 'Service Setup';
                ApplicationArea = All;
                Image = Setup;
                Enabled = SetupPageEnabled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Open Setup for the current currency exchange rate service.';
                trigger OnAction()
                begin
                    Page.Run(Rec."Setup Page Id");
                end;
            }
        }
    }


    trigger OnOpenPage()
    begin
        Rec.DiscoverCurrencyMappingCodeunits();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetupPageEnabled := Rec."Setup Page Id" > 0;
    end;

    var
        SetupPageEnabled: Boolean;

}
