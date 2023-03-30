codeunit 73406 "O4N Curr. Exch. Rates Helper"
{
    trigger OnRun()
    begin

    end;

    procedure GetToCurrencyCodeText(Url: Text; GLSetup: Record "General Ledger Setup"): Text
    var
        Currency: Record Currency;
        ToCurrencyCodeTextBuilder: TextBuilder;
        SkipCurrencyCode: Boolean;
    begin
        Currency.SetFilter(Code, '<>%1', GLSetup."LCY Code");
#pragma warning disable AA0210
        Currency.SetFilter("ISO Code", '<>%1', '');
#pragma warning restore
        Currency.FindSet();
        repeat
            OnBeforeAddCurrencyCodeToRequestSeries(Url, Currency, SkipCurrencyCode);
            if not SkipCurrencyCode then begin
                if ToCurrencyCodeTextBuilder.Length > 0 then
                    ToCurrencyCodeTextBuilder.Append(',');
                ToCurrencyCodeTextBuilder.Append(Currency."ISO Code")
            end;
        until Currency.Next() = 0;
        exit(ToCurrencyCodeTextBuilder.ToText());
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddCurrencyCodeToRequestSeries(Url: Text; Currency: Record Currency; SkipCurrencyCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeClientSend(Url: Text; var Request: HttpRequestMessage; var Response: HttpResponseMessage; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterReadXml(Url: Text; var Xml: XmlDocument; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterReadJson(Url: Text; var JObject: JsonObject; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddCurrencyExchangeRate(Url: Text; var CurrencyExchangeRate: Record "Currency Exchange Rate" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterAddingXmlCurrencyExchangeRate(Url: Text; var Xml: XmlDocument; var Currency: XmlNode; var CurrencyExchangeRate: Record "Currency Exchange Rate" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterAddingJsonCurrencyExchangeRate(Url: Text; JSON: JsonToken; Currency: JsonToken; var CurrencyExchangeRate: Record "Currency Exchange Rate" temporary)
    begin
    end;

    procedure CreateXml(UrlTok: Text; var TempCurrencyExchangeRate: Record "Currency Exchange Rate"; var OutStr: OutStream)
    var
        CurrencyExchangeRateXml: XmlPort "O4N Currency Exch. Rate Xml";
    begin
        CurrencyExchangeRateXml.SetDestination(OutStr);
        CurrencyExchangeRateXml.Set(TempCurrencyExchangeRate);
        CurrencyExchangeRateXml.Export();

        OnAfterCreateXml(UrlTok, TempCurrencyExchangeRate, OutStr);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateXml(Url: Text; var TempCurrencyExchangeRate: Record "Currency Exchange Rate"; var OutStr: OutStream)
    begin
    end;


}