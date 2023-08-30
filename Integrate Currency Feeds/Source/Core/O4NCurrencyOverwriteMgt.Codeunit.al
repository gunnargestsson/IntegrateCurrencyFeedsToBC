codeunit 73409 "O4N Currency Overwrite Mgt."
{
    TableNo = "Currency Exchange Rate";

    trigger OnRun()
    begin
        if Rec.IsTemporary() then
            ApplyOverwritePolicy(Rec);
    end;

    local procedure ApplyOverwritePolicy(var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Setup: Record "O4N Connect Exch. Rate Setup";
    begin
        if not Setup.Get() then Setup.Init();

        if Setup."Overwrite Policy" = Setup."Overwrite Policy"::All then
            exit;

        if TempCurrencyExchangeRate.FindSet() then
            repeat
                if CurrencyExchangeRate.Get(TempCurrencyExchangeRate."Currency Code", TempCurrencyExchangeRate."Starting Date") then
                    if Setup."Overwrite Policy" = Setup."Overwrite Policy"::None then
                        TempCurrencyExchangeRate.Delete()
                    else
                        if (Setup."Overwrite Policy" = Setup."Overwrite Policy"::Latest) and (TempCurrencyExchangeRate."Starting Date" < Today()) then
                            TempCurrencyExchangeRate.Delete();
            until TempCurrencyExchangeRate.Next() = 0;
    end;
}
