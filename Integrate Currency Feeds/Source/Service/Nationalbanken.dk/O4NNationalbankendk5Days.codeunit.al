codeunit 73423 "O4N Nationalbanken.dk 5Days"
{
    TableNo = "O4N Currency Buffer";

    trigger OnRun()
    var
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        GLSetup: Record "General Ledger Setup";
        CurrencyConvertion: Codeunit "O4N Currency Conversion";
        CurrencyFilter: Codeunit "O4N Currency Filter Mgt.";
        OutStr: OutStream;
        Xml: XmlDocument;
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");

        DownloadXml(Xml);

        Rec."Temp Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        ReadXml(Xml, TempCurrencyExchangeRate);
        if GLSetup."LCY Code" <> 'DKK' then
            CurrencyConvertion.ConvertToLCYRate('DKK', GLSetup."LCY Code", TempCurrencyExchangeRate);
        CurrencyFilter.ApplyFilter(Rec, TempCurrencyExchangeRate);
        Codeunit.Run(Codeunit::"O4N Currency Overwrite Mgt.", TempCurrencyExchangeRate);
        CurrHelper.CreateXml(UrlTok, TempCurrencyExchangeRate, OutStr);
        Rec.Modify();
    end;

    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        DescTok: Label 'Downloads the last 5 days exchange rates', Comment = '%1 = Web Service Url', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.nationalbanken.dk/en/statistics/exchange_rates/Pages/default.aspx', MaxLength = 250, Locked = true;
        UrlTok: Label 'https://D365Connect.com/DKK/nationalbanken.dk/5days', Locked = true, MaxLength = 250;

    /// <summary>
    /// Description for D365 ConnectXml.
    /// </summary>
    /// <param name="Xml">Parameter of type XmlDocument.</param>
    /// <param name="OutStr">Parameter of type OutStream.</param>
    procedure ReadXml(var Xml: XmlDocument; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Attribute: XmlAttribute;
        Currency: XmlNode;
        Day: XmlNode;
        Node: XmlNode;
        Currencies: XmlNodeList;
        Days: XmlNodeList;
    begin
        if not Xml.SelectSingleNode('//*[local-name()="Cube"]', Node) then exit;
        Node.SelectNodes('./*[local-name()="Cube"]', Days);
        foreach Day in Days do begin
            Day.AsXmlElement().Attributes().Get(1, Attribute);
            Evaluate(TempCurrencyExchangeRate."Starting Date", Attribute.Value, 9);
            Day.SelectNodes('./*[local-name()="Cube"]', Currencies);
            foreach Currency in Currencies do begin
                TempCurrencyExchangeRate.Init();
                TempCurrencyExchangeRate."Exchange Rate Amount" := 100;
                foreach Attribute in Currency.AsXmlElement().Attributes() do
                    case Attribute.Name of
                        'currency':
                            TempCurrencyExchangeRate."Currency Code" := CopyStr(Attribute.Value, 1, MaxStrLen(TempCurrencyExchangeRate."Currency Code"));
                        'rate':
                            Evaluate(TempCurrencyExchangeRate."Relational Exch. Rate Amount", Attribute.Value, 9);
                    end;
                CurrHelper.OnBeforeAddCurrencyExchangeRate(UrlTok, TempCurrencyExchangeRate);
                TempCurrencyExchangeRate.Insert();
                CurrHelper.OnAfterAddingXmlCurrencyExchangeRate(UrlTok, Xml, Currency, TempCurrencyExchangeRate);
            end;
        end;
        CurrHelper.OnAfterReadXml(UrlTok, Xml, TempCurrencyExchangeRate);
    end;

    /// <summary>
    /// Register this Connected Exchange Rate Service method into the Connected Exchange Rate Service method list.
    /// </summary>
    procedure RegisterService(var CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service")
    begin
        if CurrencyExchangeRateService.Get(UrlTok) then exit;
        CurrencyExchangeRateService.Init();
        CurrencyExchangeRateService.Url := UrlTok;
        CurrencyExchangeRateService.Description := DescTok;
        CurrencyExchangeRateService."Service Provider" := ServiceProviderTok;
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N Nationalbanken.dk 5Days";
        CurrencyExchangeRateService."Setup Page Id" := 0;
        CurrencyExchangeRateService.Insert(true);
    end;

    /// <summary>
    /// Description for DownloadXml.
    /// </summary>
    /// <param name="ResponseXml">Parameter of type XmlDocument.</param>
    /// <returns>Return variable "Boolean".</returns>
    local procedure DownloadXml(var ResponseXml: XmlDocument)
    var
        IsHandled: Boolean;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        InStr: InStream;
        RequestErr: Label 'Error Code: %1\%2', Comment = '%1 = Response Error Code, %2 = Response Error Phrase';
    begin
        Request.SetRequestUri('https://www.nationalbanken.dk/_vti_bin/DN/DataService.svc/CurrencyRatesHistoryXML?lang=en');
        Request.Method('GET');
        CurrHelper.OnBeforeClientSend(UrlTok, Request, Response, IsHandled);
        if not IsHandled then
            Client.Send(Request, Response);
        HttpHelper.ThrowError(Response);
        HttpHelper.CreateInStream(InStr);
        Response.Content.ReadAs(InStr);
        HttpHelper.ReadInStr(InStr, ResponseXml);
        if not Response.IsSuccessStatusCode then
            Error(RequestErr, Response.HttpStatusCode, Response.ReasonPhrase);
    end;

    [EventSubscriber(ObjectType::Table, Database::"O4N Curr. Exch. Rate Service", 'DiscoverCurrencyMappingCodeunits', '', false, false)]
    local procedure DiscoverCurrencyMappingCodeunits()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
    begin
        RegisterService(CurrencyExchangeRateService);
    end;
}
