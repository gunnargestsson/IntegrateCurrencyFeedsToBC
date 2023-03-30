codeunit 73413 "O4N Currency Filter Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        TemporaryErr: Label 'The record must be temporary.';

    procedure ApplyFilter(CurrencyBuffer: Record "O4N Currency Buffer"; var TempCurrencyExchangeRates: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        if not TempCurrencyExchangeRates.IsTemporary() then
            Error(TemporaryErr);

        TempCurrencyExchangeRates.SetCurrentKey("Currency Code");
        if TempCurrencyExchangeRates.FindSet() then begin
            FilterCurrency(CurrencyBuffer, Currency);
            Currency.FilterGroup(2);
            repeat
                TempCurrencyExchangeRates.SetRange("Currency Code", TempCurrencyExchangeRates."Currency Code");
                TempCurrencyExchangeRates.FindLast();
                Currency.SetRange("ISO Code", TempCurrencyExchangeRates."Currency Code");
                if Currency.IsEmpty() then
                    TempCurrencyExchangeRates.DeleteAll();
                TempCurrencyExchangeRates.SetRange("Currency Code");
            until TempCurrencyExchangeRates.Next() = 0;
        end;

    end;

    local procedure FilterCurrency(CurrencyBuffer: Record "O4N Currency Buffer"; var Currency: Record Currency)
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        if not CurrencyBuffer."Currency Filter".HasValue then exit;
        RecRef.GetTable(Currency);
        TempBlob.FromRecord(CurrencyBuffer, CurrencyBuffer.FieldNo("Currency Filter"));
        RequestPageParametersHelper.ConvertParametersToFilters(RecRef, TempBlob);
        RecRef.SetTable(Currency);
    end;
}
