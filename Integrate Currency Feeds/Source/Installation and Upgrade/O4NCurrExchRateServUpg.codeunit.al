codeunit 73411 "O4N Curr. Exch. Rate Serv Upg"
{
    Subtype = Upgrade;

    var
        Setup: Codeunit "O4N Curr. Exch. Rate Serv Stp";

    trigger OnRun()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
    begin
        CurrencyExchangeRateService.DiscoverCurrencyMappingCodeunits();
        Setup.SetApiCallsAllowed();
    end;
}