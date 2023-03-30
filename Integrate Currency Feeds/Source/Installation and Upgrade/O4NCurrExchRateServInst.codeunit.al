codeunit 73410 "O4N Curr. Exch. Rate Serv Inst"
{
    Subtype = Install;

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