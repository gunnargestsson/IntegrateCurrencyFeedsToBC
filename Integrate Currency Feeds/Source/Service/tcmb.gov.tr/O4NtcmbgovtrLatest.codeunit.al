codeunit 73428 "O4N tcmb.gov.tr Latest"
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
        if GLSetup."LCY Code" <> 'TRY' then
            CurrencyConvertion.ConvertToLCYRate('TRY', GLSetup."LCY Code", TempCurrencyExchangeRate);
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
        Request.SetRequestUri('https://www.tcmb.gov.tr/kurlar/today.xml');
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
        Setup: Record "O4N tcmb.gov.tr Setup";
        TypeHelper: Codeunit "Type Helper";
        Currencies: XmlNodeList;
        Currency: XmlNode;
        Node: XmlNode;
        Attribute: XmlAttribute;
        DateVariant: Variant;
    begin
        if not Setup.Get() then
            Setup.Init();
        if not Xml.SelectSingleNode('//*[local-name()="Tarih_Date"]', Node) then exit;
        foreach Attribute in Node.AsXmlElement().Attributes() do
            if Attribute.Name = 'Date' then begin
                DateVariant := TempCurrencyExchangeRate."Starting Date";
                if TypeHelper.Evaluate(DateVariant, Attribute.Value, 'MM/dd/yyyy', 'en-us') then
                    TempCurrencyExchangeRate."Starting Date" := DateVariant;
            end;
        if not Xml.SelectNodes('//*[local-name()="Currency"]', Currencies) then exit;
        foreach Currency in Currencies do begin
            TempCurrencyExchangeRate.Init();
            foreach Attribute in Currency.AsXmlElement().Attributes() do
                if Attribute.Name = 'CurrencyCode' then
                    TempCurrencyExchangeRate."Currency Code" := CopyStr(Attribute.Value, 1, MaxStrLen(TempCurrencyExchangeRate."Currency Code"));
            Currency.SelectSingleNode('Unit', Node);
            Evaluate(TempCurrencyExchangeRate."Exchange Rate Amount", Node.AsXmlElement().InnerText, 9);
            case Setup."Rate Type" of
                Setup."Rate Type"::ForexBuying:
                    Currency.SelectSingleNode('ForexBuying', Node);
                Setup."Rate Type"::ForexSelling:
                    Currency.SelectSingleNode('ForexSelling', Node);
                Setup."Rate Type"::BanknoteBuying:
                    Currency.SelectSingleNode('BanknoteBuying', Node);
                Setup."Rate Type"::BanknoteSelling:
                    Currency.SelectSingleNode('BanknoteSelling', Node);
            end;
            Evaluate(TempCurrencyExchangeRate."Relational Exch. Rate Amount", Node.AsXmlElement().InnerText, 9);
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N tcmb.gov.tr Latest";
        CurrencyExchangeRateService."Setup Page Id" := Page::"O4N tcmb.gov.tr Setup";
        CurrencyExchangeRateService.Insert(true);
    end;

    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        UrlTok: label 'https://D365Connect.com/TRY/tcmb.gov.tr/latest', Locked = true, MaxLength = 250;
        DescTok: Label 'Downloads the latest exchange rates', Comment = '%1 = Web Service Url', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.tcmb.gov.tr/wps/wcm/connect/EN/TCMB+EN/Main+Menu/Statistics/Exchange+Rates', MaxLength = 250, Locked = true;
}
