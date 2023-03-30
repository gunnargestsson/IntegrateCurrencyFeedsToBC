pageextension 73400 "O4NCurrExchRateServ" extends "Curr. Exch. Rate Service Card"
{
    layout
    {
        addbefore(ServiceURL)
        {
            field(O4NCurrencyFilterField; CurrencyFilter)
            {
                ApplicationArea = All;
                Caption = 'Currency Filter';
                Editable = false;
                ToolTip = 'Specifies the value of the Currency Filter field.  Only exchange rates for the currencies within this filter will be imported using this serviece.';

                trigger OnAssistEdit()
                begin
                    if not CurrPage.Editable then exit;
                    TempCurrencyBuffer.SetSelectionFilter(Rec);
                    CurrPage.Update(true);
                end;
            }
        }
        modify(ServiceURL)
        {
            trigger OnLookup(var Text: Text): Boolean
            var
                CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
            begin
                if Page.RunModal(Page::"O4N Curr. Exch. Rate Services", CurrencyExchangeRateService) = Action::LookupOK then begin
                    Text := CurrencyExchangeRateService.Url;
                    exit(true);
                end;
            end;

            trigger OnAfterValidate()
            begin
                O4NOnAfterValidateServiceURL(Rec);
                CurrPage.SimpleDataExchSetup.Page.UpdateData();
                CurrPage.Update();
            end;
        }
    }

    actions
    {

    }

    var
        TempCurrencyBuffer: Record "O4N Currency Buffer" temporary;
        CurrencyFilter: Text;

    trigger OnOpenPage()
    begin
        CurrencyFilter := '';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CurrencyFilter := '';
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrencyFilter := TempCurrencyBuffer.GetFiltersAsTextDisplay(Rec);
    end;

    /// <summary> 
    /// Description for O4NOnAfterValidateServiceURL.
    /// </summary>
    /// <param name="CurrExchRateUpdateSetup">Parameter of type Record "Curr. Exch. Rate Update Setup".</param>
    [IntegrationEvent(false, false)]
    local procedure O4NOnAfterValidateServiceURL(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    begin
    end;
}
