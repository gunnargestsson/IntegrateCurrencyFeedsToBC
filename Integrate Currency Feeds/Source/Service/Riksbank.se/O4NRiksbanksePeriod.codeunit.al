codeunit 73419 "O4N Riksbank.se Period"
{
    TableNo = "O4N Currency Buffer";

    trigger OnRun()
    var
        GLSetup: Record "General Ledger Setup";
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        CurrencyConvertion: Codeunit "O4N Currency Conversion";
        CurrencyFilter: Codeunit "O4N Currency Filter Mgt.";
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        Xml: XmlDocument;
        OutStr: OutStream;
        StartDate: Date;
        EndDate: Date;
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");

        DateMgt.GetCurrencyPeriod(UrlTok, Rec."Get Structure", 'SWE', StartDate, EndDate);

        if not DownloadXml(CreateRequestXml(GLSetup, StartDate, EndDate), Xml) then
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

    /// <summary> 
    /// Description for ThrowIfError.
    /// </summary>
    /// <param name="ResponseXml">Parameter of type XmlDocument.</param>
    local procedure ThrowIfError(var ResponseXml: XmlDocument)
    var
        SelectedNode: XmlNode;
        SelectTok: Label '//*[local-name()="%1"]', Locked = true;
    begin
        if not ResponseXml.SelectSingleNode(StrSubstNo(SelectTok, 'Fault'), SelectedNode) then exit;
        if not ResponseXml.SelectSingleNode(StrSubstNo(SelectTok, 'Text'), SelectedNode) then exit;
        Error(SelectedNode.AsXmlElement().InnerText);
    end;

    /// <summary> 
    /// Description for DownloadXml.
    /// </summary>
    /// <param name="ResponseXml">Parameter of type XmlDocument.</param>
    /// <returns>Return variable "Boolean".</returns>
    local procedure DownloadXml(RequestXml: Text; var ResponseXml: XmlDocument): Boolean
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        InStr: InStream;
        IsHandled: Boolean;
    begin
        Request.SetRequestUri('https://swea.riksbank.se/sweaWS/services/SweaWebServiceHttpSoap12Endpoint');
        Request.Method('POST');
        Request.Content.WriteFrom(RequestXml);
        Request.Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/soap+xml;charset=UTF-8;action="urn:getCrossRates"');
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
    /// Description for CreateRequestXml.
    /// </summary>
    local procedure CreateRequestXml(GLSetup: Record "General Ledger Setup"; StartDate: Date; EndDate: Date) Xml: Text;
    var
        RequestXml: XmlDocument;
    begin
        CreateRequestXml(GLSetup, StartDate, EndDate, RequestXml);
        RequestXml.WriteTo(Xml);
    end;

    /// <summary> 
    /// Description for CreateRequestXml.
    /// </summary>
    /// <param name="Xml">Parameter of type XmlDocument.</param>
    procedure CreateRequestXml(GLSetup: Record "General Ledger Setup"; StartDate: Date; EndDate: Date; var Xml: XmlDocument)
    var
        Envelope: XmlNode;
        Header: XmlNode;
        Body: XmlNode;
        getCrossRates: XmlNode;
        crossRequestParameters: XmlNode;
    begin
        Xml := XmlDocument.Create();
        xml.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        Envelope := XmlElement.Create('Envelope', 'http://www.w3.org/2003/05/soap-envelope').AsXmlNode();
        Envelope.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration('soap', 'http://www.w3.org/2003/05/soap-envelope'));
        Envelope.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration('xsd', 'http://swea.riksbank.se/xsd'));
        Header := XmlElement.Create('Header', 'http://www.w3.org/2003/05/soap-envelope').AsXmlNode();
        Envelope.AsXmlElement().Add(Header);
        Body := XmlElement.Create('Body', 'http://www.w3.org/2003/05/soap-envelope').AsXmlNode();
        Envelope.AsXmlElement().Add(Body);
        getCrossRates := XmlElement.Create('getCrossRates', 'http://swea.riksbank.se/xsd').AsXmlNode();
        Body.AsXmlElement().Add(getCrossRates);
        crossRequestParameters := XmlElement.Create('crossRequestParameters', '').AsXmlNode();
        getCrossRates.AsXmlElement().Add(crossRequestParameters);
        crossRequestParameters.AsXmlElement().Add(XmlElement.Create('aggregateMethod', '', 'D').AsXmlNode());
        GetCrossPairs(GLSetup, crossRequestParameters);
        crossRequestParameters.AsXmlElement().Add(XmlElement.Create('datefrom', '', Format(StartDate, 0, 9)).AsXmlNode());
        crossRequestParameters.AsXmlElement().Add(XmlElement.Create('dateto', '', Format(EndDate, 0, 9)).AsXmlNode());
        crossRequestParameters.AsXmlElement().Add(XmlElement.Create('languageid', '', 'en').AsXmlNode());
        xml.Add(Envelope);
    end;

    /// <summary> 
    /// Description for GetSeries.
    /// </summary>
    /// <param name="crossRequestParameters">Parameter of type XmlNode.</param>
    local procedure GetCrossPairs(GLSetup: Record "General Ledger Setup"; var crossRequestParameters: XmlNode)
    var
        Currency: Record Currency;
        SkipCurrencyCode: Boolean;
        SeriesTok: Label '%1%2PMI', Locked = true;
        crossPair: XmlNode;
    begin
        Currency.SetFilter(Code, '<>%1', GLSetup."LCY Code");
#pragma warning disable AA0210
        Currency.SetFilter("ISO Code", '<>%1', '');
#pragma warning restore
        Currency.FindSet();
        repeat
            SkipCurrencyCode := false;
            CurrHelper.OnBeforeAddCurrencyCodeToRequestSeries(UrlTok, Currency, SkipCurrencyCode);
            if not SkipCurrencyCode then begin
                crossPair := XmlElement.Create('crossPair', '').AsXmlNode();
                crossPair.AsXmlElement().Add(XmlElement.Create('seriesid1', '', StrSubstNo(SeriesTok, 'SEK', Currency."ISO Code")).AsXmlNode());
                crossPair.AsXmlElement().Add(XmlElement.Create('seriesid2', '', 'SEK').AsXmlNode());
                crossRequestParameters.AsXmlElement().Add(crossPair);
            end;
        until Currency.Next() = 0;
        if GLSetup."LCY Code" <> 'SEK' then begin
            crossPair := XmlElement.Create('crossPair', '').AsXmlNode();
            crossPair.AsXmlElement().Add(XmlElement.Create('seriesid1', '', StrSubstNo(SeriesTok, 'SEK', GLSetup."LCY Code")).AsXmlNode());
            crossPair.AsXmlElement().Add(XmlElement.Create('seriesid2', '', 'SEK').AsXmlNode());
            crossRequestParameters.AsXmlElement().Add(crossPair);
        end;
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
        Rows: XmlNodeList;
        Row: XmlNode;
    begin
        if not Xml.SelectNodes('//*[local-name()="series"]', Currencies) then exit;
        foreach Currency in Currencies do begin
            TempCurrencyExchangeRate.Init();
            Currency.SelectSingleNode('./*[local-name()="seriesid1"]', Node);
            TempCurrencyExchangeRate."Currency Code" := CopyStr(Node.AsXmlElement().InnerText, 4, 3);
            TempCurrencyExchangeRate."Exchange Rate Amount" := 1;
            if TempCurrencyExchangeRate."Currency Code" <> '' then begin
                Currency.SelectNodes('./*[local-name()="resultrows"]', Rows);
                foreach Row in Rows do begin
                    Row.SelectSingleNode('./*[local-name()="date"]', Node);
                    if Node.AsXmlElement().IsEmpty() then break;
                    Evaluate(TempCurrencyExchangeRate."Starting Date", Node.AsXmlElement().InnerText, 9);
                    Row.SelectSingleNode('./*[local-name()="value"]', Node);
                    if Node.AsXmlElement().IsEmpty() then break;
                    TempCurrencyExchangeRate."Relational Exch. Rate Amount" := EvaluateEValue(Node.AsXmlElement().InnerText);
                    CurrHelper.OnBeforeAddCurrencyExchangeRate(UrlTok, TempCurrencyExchangeRate);
                    TempCurrencyExchangeRate.Insert();
                    CurrHelper.OnAfterAddingXmlCurrencyExchangeRate(UrlTok, Xml, Currency, TempCurrencyExchangeRate);
                end;
            end;
        end;
        CurrHelper.OnAfterReadXml(UrlTok, Xml, TempCurrencyExchangeRate);
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N Riksbank.se Period";
        CurrencyExchangeRateService."Setup Page Id" := 0;
        CurrencyExchangeRateService.Insert(true);
    end;

    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        UrlTok: label 'https://D365Connect.com/SEK/riksbank.se/period', Locked = true, MaxLength = 250;
        DescTok: Label 'Downloads missing exchange rates', Comment = '%1 = Web Service Url', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.riksbank.se/en-gb/statistics/search-interest--exchange-rates/web-services/series-for-web-services/', MaxLength = 250, Locked = true;
}
