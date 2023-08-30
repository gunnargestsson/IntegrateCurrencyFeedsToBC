codeunit 73402 "O4N Currency Conversion"
{
    var
        UnableToConvertRatesToLCYErr: Label 'Unable to convert exchange rates from %1 to %2', Comment = '%1 = Service Currency Code, %2 = LCY Currency Code';

    procedure ConvertToLCYRate(ServiceCurrencyCode: Code[10]; LCYCurrencyCode: Code[10]; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        CurrencyFactor: Decimal;
    begin
        if LCYCurrencyCode = ServiceCurrencyCode then exit;
        CurrencyExchangeRate.SetCurrentKey("Starting Date");
        CurrencyExchangeRate.SetRange("Currency Code", LCYCurrencyCode);
        if not CurrencyExchangeRate.FindSet() then
            Message(UnableToConvertRatesToLCYErr, ServiceCurrencyCode, LCYCurrencyCode)
        else
            repeat
                CurrencyFactor := CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount";
                InsertMirrorEntry(CurrencyExchangeRate, ServiceCurrencyCode, TempCurrencyExchangeRate);

                CurrencyExchangeRate.SetRange("Starting Date", CurrencyExchangeRate."Starting Date");

                CurrencyExchangeRate.SetFilter("Currency Code", '<>%1', LCYCurrencyCode);
                if CurrencyExchangeRate.FindSet() then
                    repeat
                        InsertConvertedEntry(CurrencyExchangeRate, CurrencyFactor, TempCurrencyExchangeRate);
                    until CurrencyExchangeRate.Next() = 0;

                CurrencyExchangeRate.SetRange("Currency Code", LCYCurrencyCode);
                CurrencyExchangeRate.FindLast();
                CurrencyExchangeRate.SetRange("Starting Date");
            until CurrencyExchangeRate.Next() = 0;

        CurrencyExchangeRate.Copy(TempCurrencyExchangeRate, true);
    end;

    local procedure InsertConvertedEntry(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyFactor: Decimal; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        ExchangeRateAmt: Decimal;
    begin
        ExchangeRateAmt := CurrencyExchangeRate."Exchange Rate Amount" * CurrencyFactor;
        TempCurrencyExchangeRate := CurrencyExchangeRate;
        TempCurrencyExchangeRate."Relational Exch. Rate Amount" := Round(100 * CurrencyExchangeRate."Relational Exch. Rate Amount" / ExchangeRateAmt, 0.000001);
        TempCurrencyExchangeRate."Exchange Rate Amount" := 100;
        TempCurrencyExchangeRate.Insert();
    end;

    local procedure InsertMirrorEntry(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        TempCurrencyExchangeRate := CurrencyExchangeRate;
        TempCurrencyExchangeRate."Currency Code" := CurrencyCode;
        TempCurrencyExchangeRate."Exchange Rate Amount" := CurrencyExchangeRate."Relational Exch. Rate Amount" * 100;
        TempCurrencyExchangeRate."Relational Exch. Rate Amount" := CurrencyExchangeRate."Exchange Rate Amount" * 100;
        TempCurrencyExchangeRate.Insert();
    end;
}