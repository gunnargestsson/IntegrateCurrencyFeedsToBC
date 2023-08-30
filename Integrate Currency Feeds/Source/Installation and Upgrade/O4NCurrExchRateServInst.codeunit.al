codeunit 73410 "O4N Curr. Exch. Rate Serv Inst"
{
    Subtype = Install;

    trigger OnRun()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
    begin
        CurrencyExchangeRateService.DiscoverCurrencyMappingCodeunits();
    end;
}