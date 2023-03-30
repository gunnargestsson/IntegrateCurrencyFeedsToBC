codeunit 73422 "O4N Nationalbanken.dk Latest"
{
    TableNo = "O4N Currency Buffer";

    trigger OnRun()
    var
        GLSetup: Record "General Ledger Setup";
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        CurrencyConvertion: Codeunit "O4N Currency Conversion";
        CurrencyFilter: Codeunit "O4N Currency Filter Mgt.";
        Xml: XmlDocument;
        OutStr: OutStream;
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

    /// <summary> 
    /// Description for DownloadXml.
    /// </summary>
    /// <param name="ResponseXml">Parameter of type XmlDocument.</param>
    /// <returns>Return variable "Boolean".</returns>
    local procedure DownloadXml(var ResponseXml: XmlDocument)
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        RequestErr: Label 'Error Code: %1\%2', Comment = '%1 = Response Error Code, %2 = Response Error Phrase';
        InStr: InStream;
        IsHandled: Boolean;
    begin
        Request.SetRequestUri('https://www.nationalbanken.dk/_vti_bin/DN/DataService.svc/CurrencyRatesXML?lang=en');
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

    /// <summary> 
    /// Description for D365 ConnectXml.
    /// </summary>
    /// <param name="Xml">Parameter of type XmlDocument.</param>
    /// <param name="OutStr">Parameter of type OutStream.</param>
    procedure ReadXml(var Xml: XmlDocument; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    var

        Currencies: XmlNodeList;
        Currency: XmlNode;
        Node: XmlNode;
        Attribute: XmlAttribute;
    begin
        if not Xml.SelectSingleNode('//*[local-name()="dailyrates"]', Node) then exit;
        if not Xml.SelectNodes('//*[local-name()="currency"]', Currencies) then exit;
        if not Node.AsXmlElement().Attributes().Get(1, Attribute) then exit;
        if not Evaluate(TempCurrencyExchangeRate."Starting Date", Attribute.Value, 9) then exit;
        foreach Currency in Currencies do begin
            TempCurrencyExchangeRate.Init();
            TempCurrencyExchangeRate."Exchange Rate Amount" := 100;
            foreach Attribute in Currency.AsXmlElement().Attributes() do
                case Attribute.Name of
                    'code':
                        TempCurrencyExchangeRate."Currency Code" := CopyStr(Attribute.Value, 1, MaxStrLen(TempCurrencyExchangeRate."Currency Code"));
                    'rate':
                        Evaluate(TempCurrencyExchangeRate."Relational Exch. Rate Amount", Attribute.Value, 9);
                end;
            CurrHelper.OnBeforeAddCurrencyExchangeRate(UrlTok, TempCurrencyExchangeRate);
            TempCurrencyExchangeRate.Insert();
            CurrHelper.OnAfterAddingXmlCurrencyExchangeRate(UrlTok, Xml, Currency, TempCurrencyExchangeRate);
        end;
        CurrHelper.OnAfterReadXml(UrlTok, Xml, TempCurrencyExchangeRate);
    end;

    [EventSubscriber(ObjectType::Table, Database::"O4N Curr. Exch. Rate Service", 'DiscoverCurrencyMappingCodeunits', '', false, false)]
    local procedure DiscoverCurrencyMappingCodeunits()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
    begin
        RegisterService(CurrencyExchangeRateService);
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N Nationalbanken.dk Latest";
        CurrencyExchangeRateService."Setup Page Id" := 0;
        CurrencyExchangeRateService.Insert(true);
    end;

    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        UrlTok: label 'https://D365Connect.com/DKK/nationalbanken.dk/latest', Locked = true, MaxLength = 250;
        DescTok: Label 'Downloads the latest exchange rates', Comment = '%1 = Web Service Url', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.nationalbanken.dk/en/statistics/exchange_rates/Pages/default.aspx', MaxLength = 250, Locked = true;
}
