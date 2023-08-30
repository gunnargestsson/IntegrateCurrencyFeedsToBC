codeunit 73420 "O4N Riksbank.se Latest"
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

        if not DownloadXml(GLSetup, Xml) then
            ThrowIfError(Xml);
        Rec."Temp Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        ReadXml(Xml, TempCurrencyExchangeRate);
        if GLSetup."LCY Code" <> 'SEK' then
            CurrencyConvertion.ConvertToLCYRate('SEK', GLSetup."LCY Code", TempCurrencyExchangeRate);
        CurrencyFilter.ApplyFilter(Rec, TempCurrencyExchangeRate);
        Codeunit.Run(Codeunit::"O4N Currency Overwrite Mgt.", TempCurrencyExchangeRate);
        CurrHelper.CreateXml(UrlTok, TempCurrencyExchangeRate, OutStr);
        Rec.Modify();
    end;

    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        DescTok: Label 'Downloads the latest exchange rates', Comment = '%1 = Web Service Url', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.riksbank.se/en-gb/statistics/search-interest--exchange-rates/web-services/series-for-web-services/', MaxLength = 250, Locked = true;
        UrlTok: Label 'https://D365Connect.com/SEK/riksbank.se/latest', Locked = true, MaxLength = 250;

    /// <summary>
    /// Description for CreateRequestXml.
    /// </summary>
    /// <param name="Xml">Parameter of type XmlDocument.</param>
    procedure CreateRequestXml(GLSetup: Record "General Ledger Setup"; var Xml: XmlDocument)
    var
        Body: XmlNode;
        Envelope: XmlNode;
        getLatestInterestAndExchangeRates: XmlNode;
        Header: XmlNode;
    begin
        Xml := XmlDocument.Create();
        Xml.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        Envelope := XmlElement.Create('Envelope', 'http://www.w3.org/2003/05/soap-envelope').AsXmlNode();
        Envelope.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration('soap', 'http://www.w3.org/2003/05/soap-envelope'));
        Envelope.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration('xsd', 'http://swea.riksbank.se/xsd'));
        Header := XmlElement.Create('Header', 'http://www.w3.org/2003/05/soap-envelope').AsXmlNode();
        Envelope.AsXmlElement().Add(Header);
        Body := XmlElement.Create('Body', 'http://www.w3.org/2003/05/soap-envelope').AsXmlNode();
        Envelope.AsXmlElement().Add(Body);
        getLatestInterestAndExchangeRates := XmlElement.Create('getLatestInterestAndExchangeRates', 'http://swea.riksbank.se/xsd').AsXmlNode();
        Body.AsXmlElement().Add(getLatestInterestAndExchangeRates);
        getLatestInterestAndExchangeRates.AsXmlElement().Add(XmlElement.Create('languageid', '', 'en').AsXmlNode());
        GetSeries(GLSetup, getLatestInterestAndExchangeRates);
        Xml.Add(Envelope);
    end;

    /// <summary>
    /// Description for D365 ConnectXml.
    /// </summary>
    /// <param name="Xml">Parameter of type XmlDocument.</param>
    /// <param name="OutStr">Parameter of type OutStream.</param>
    procedure ReadXml(var Xml: XmlDocument; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    var

        Currency: XmlNode;
        Node: XmlNode;
        Row: XmlNode;
        Currencies: XmlNodeList;
        Rows: XmlNodeList;
    begin
        if not Xml.SelectNodes('//*[local-name()="series"]', Currencies) then exit;
        foreach Currency in Currencies do begin
            TempCurrencyExchangeRate.Init();
            Currency.SelectSingleNode('./*[local-name()="seriesid"]', Node);
            TempCurrencyExchangeRate."Currency Code" := CopyStr(Node.AsXmlElement().InnerText, 4, 3);
            Currency.SelectSingleNode('./*[local-name()="unit"]', Node);
            TempCurrencyExchangeRate."Exchange Rate Amount" := EvaluateEValue(Node.AsXmlElement().InnerText);
            Currency.SelectNodes('./*[local-name()="resultrows"]', Rows);
            foreach Row in Rows do begin
                Row.SelectSingleNode('./*[local-name()="date"]', Node);
                Evaluate(TempCurrencyExchangeRate."Starting Date", Node.AsXmlElement().InnerText, 9);
                Row.SelectSingleNode('./*[local-name()="value"]', Node);
                TempCurrencyExchangeRate."Relational Exch. Rate Amount" := EvaluateEValue(Node.AsXmlElement().InnerText);
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N Riksbank.se Latest";
        CurrencyExchangeRateService."Setup Page Id" := 0;
        CurrencyExchangeRateService.Insert(true);
    end;

    /// <summary>
    /// Description for CreateRequestXml.
    /// </summary>
    local procedure CreateRequestXml(GLSetup: Record "General Ledger Setup") Xml: Text;
    var
        RequestXml: XmlDocument;
    begin
        CreateRequestXml(GLSetup, RequestXml);
        RequestXml.WriteTo(Xml);
    end;

    /// <summary>
    /// Description for DownloadXml.
    /// </summary>
    /// <param name="ResponseXml">Parameter of type XmlDocument.</param>
    /// <returns>Return variable "Boolean".</returns>
    local procedure DownloadXml(GLSetup: Record "General Ledger Setup"; var ResponseXml: XmlDocument): Boolean
    var
        IsHandled: Boolean;
        Client: HttpClient;
        Headers: HttpHeaders;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        InStr: InStream;
    begin
        Request.SetRequestUri('https://swea.riksbank.se/sweaWS/services/SweaWebServiceHttpSoap12Endpoint');
        Request.Method('POST');
        Request.Content.WriteFrom(CreateRequestXml(GLSetup));
        Request.Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/soap+xml;charset=UTF-8;action="urn:getLatestInterestAndExchangeRates"');
        CurrHelper.OnBeforeClientSend(UrlTok, Request, Response, IsHandled);
        if not IsHandled then
            Client.Send(Request, Response);
        HttpHelper.ThrowError(Response);
        HttpHelper.CreateInStream(InStr);
        Response.Content.ReadAs(InStr);
        HttpHelper.ReadInStr(InStr, ResponseXml);
        exit(Response.IsSuccessStatusCode);
    end;

    /// <summary>
    /// Description for EvaluateEValue.
    /// </summary>
    /// <param name="InnerText">Parameter of type Text.</param>
    local procedure EvaluateEValue(InnerText: Text) Amount: Decimal
    var
        Values: List of [Text];
    begin
        Values := InnerText.Split('E');
        Amount := GetDecimalValue(Values, 1) * Power(10, GetDecimalValue(Values, 2));
    end;

    /// <summary>
    /// Description for GetDecimalValue.
    /// </summary>
    /// <param name="Values">Parameter of type List of [Text].</param>
    /// <param name="ColumnNo">Parameter of type Integer.</param>
    local procedure GetDecimalValue(Values: List of [Text]; ColumnNo: Integer) Amount: Decimal
    var
        ColumnValue: Text;
    begin
        Values.Get(ColumnNo, ColumnValue);
        Evaluate(Amount, ColumnValue, 9);
    end;

    /// <summary>
    /// Description for GetSeries.
    /// </summary>
    /// <param name="SeriesNode">Parameter of type XmlNode.</param>
    local procedure GetSeries(GLSetup: Record "General Ledger Setup"; var SeriesNode: XmlNode)
    var
        Currency: Record Currency;
        SkipCurrencyCode: Boolean;
        SeriesTok: Label '%1%2PMI', Locked = true;
    begin
        Currency.SetFilter(Code, '<>%1', GLSetup."LCY Code");
#pragma warning disable AA0210
        Currency.SetFilter("ISO Code", '<>%1', '');
#pragma warning restore
        Currency.FindSet();
        repeat
            SkipCurrencyCode := false;
            CurrHelper.OnBeforeAddCurrencyCodeToRequestSeries(UrlTok, Currency, SkipCurrencyCode);
            if not SkipCurrencyCode then
                SeriesNode.AsXmlElement().Add(XmlElement.Create('seriesid', '', StrSubstNo(SeriesTok, 'SEK', Currency."ISO Code")).AsXmlNode());
        until Currency.Next() = 0;
        if GLSetup."LCY Code" <> 'SEK' then
            SeriesNode.AsXmlElement().Add(XmlElement.Create('seriesid', '', StrSubstNo(SeriesTok, 'SEK', GLSetup."LCY Code")).AsXmlNode());
    end;

    /// <summary>
    /// Description for ThrowIfError.
    /// </summary>
    /// <param name="ResponseXml">Parameter of type XmlDocument.</param>
    local procedure ThrowIfError(var ResponseXml: XmlDocument)
    var
        SelectTok: Label '//*[local-name()="%1"]', Locked = true;
        SelectedNode: XmlNode;
    begin
        if not ResponseXml.SelectSingleNode(StrSubstNo(SelectTok, 'Fault'), SelectedNode) then exit;
        if not ResponseXml.SelectSingleNode(StrSubstNo(SelectTok, 'Text'), SelectedNode) then exit;
        Error(SelectedNode.AsXmlElement().InnerText);
    end;

    [EventSubscriber(ObjectType::Table, Database::"O4N Curr. Exch. Rate Service", 'DiscoverCurrencyMappingCodeunits', '', false, false)]
    local procedure DiscoverCurrencyMappingCodeunits()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
    begin
        RegisterService(CurrencyExchangeRateService);
    end;
}
