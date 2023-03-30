codeunit 73411 "O4N Curr. Exch. Rate Serv Upg"
{
    Subtype = Upgrade;

    trigger OnRun()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
    begin
        CurrencyExchangeRateService.DiscoverCurrencyMappingCodeunits();
    end;
}