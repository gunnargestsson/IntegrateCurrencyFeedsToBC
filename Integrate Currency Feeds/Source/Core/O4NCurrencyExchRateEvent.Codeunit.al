codeunit 73414 "O4N Currency Exch. Rate Event"
{
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";

    [EventSubscriber(ObjectType::Page, Page::"Curr. Exch. Rate Service Card", 'OnOpenPageEvent', '', true, false)]
    local procedure OnOpenCardPage()
    begin
        CurrencyExchangeRateService.DiscoverCurrencyMappingCodeunits();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Curr. Exch. Rate Service List", 'OnOpenPageEvent', '', true, false)]
    local procedure OnOpenListPage()
    begin
        CurrencyExchangeRateService.DiscoverCurrencyMappingCodeunits();
    end;
}
