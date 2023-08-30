page 73400 "O4N Curr. Exch. Rate Services"
{
    ApplicationArea = All;
    Caption = 'Connected Exch. Rate Services';
    Editable = false;
    PageType = List;
    SourceTable = "O4N Curr. Exch. Rate Service";
    UsageCategory = Administration;

    layout
    {
        area(Content)
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
                    QuickEntry = false;
                    ToolTip = 'Specifies a description for the Connected Exchange Rate Service functionality.';
                }
                field("Service Provider"; Rec."Service Provider")
                {
                    ApplicationArea = All;
                    Caption = 'Service Provider';
                    ExtendedDatatype = URL;
                    QuickEntry = false;
                    ToolTip = 'Specifies a service provider Url for the connected exchange rate service.';
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
                ApplicationArea = All;
                Caption = 'Connect Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                RunObject = page "O4N Connect Exch. Rate Setup";
                ToolTip = 'Open SConnect etup for the currency exchange rate services.';
            }
            action(Setup)
            {
                ApplicationArea = All;
                Caption = 'Service Setup';
                Enabled = SetupPageEnabled;
                Image = Setup;
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
