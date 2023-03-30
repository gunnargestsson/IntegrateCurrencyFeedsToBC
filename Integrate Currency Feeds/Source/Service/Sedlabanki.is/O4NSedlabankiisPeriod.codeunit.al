codeunit 73421 "O4N Sedlabanki.is Period"
{
    TableNo = "O4N Currency Buffer";
    // https://www.sedlabanki.is/xmltimeseries/Default.aspx?DagsFra=2020-09-09&DagsTil=2020-09-15&GroupID=7&Type=xml

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

        DateMgt.GetCurrencyPeriod(UrlTok, Rec."Get Structure", 'ISL', StartDate, EndDate);

        DownloadXml(StartDate, EndDate, 9, Xml);
        ReadXml(Xml, TempCurrencyExchangeRate);

        if not Rec."Get Structure" then begin
            DownloadXml(StartDate, EndDate, 7, Xml);
            ReadXml(Xml, TempCurrencyExchangeRate);
        end;

        if GLSetup."LCY Code" <> 'ISK' then
            CurrencyConvertion.ConvertToLCYRate('ISK', GLSetup."LCY Code", TempCurrencyExchangeRate);
        CurrencyFilter.ApplyFilter(Rec, TempCurrencyExchangeRate);
        Codeunit.Run(Codeunit::"O4N Currency Overwrite Mgt.", TempCurrencyExchangeRate);
        Rec."Temp Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        CurrHelper.CreateXml(UrlTok, TempCurrencyExchangeRate, OutStr);
        Rec.Modify();
    end;

    local procedure DownloadXml(StartDate: Date; EndDate: Date; GroupId: Integer; var ResponseXml: XmlDocument)
    var
        RequestUrlTok: Label 'https://www.sedlabanki.is/xmltimeseries/Default.aspx?DagsFra=%1&DagsTil=%2&GroupID=%3&Type=xml', Locked = true;
        RequestErr: Label 'Error Code: %1\%2', Comment = '%1 = Response Error Code, %2 = Response Error Phrase';
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        InStr: InStream;

        IsHandled: Boolean;
    begin
        Request.SetRequestUri(StrSubstNo(RequestUrlTok, Format(StartDate, 0, 9), Format(CreateDateTime(EndDate, 235959T), 0, 9), GroupId));
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

    procedure ReadXml(var Xml: XmlDocument; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Setup: Record "O4N Sedlabanki.is Setup";
        TypeHelper: Codeunit "Type Helper";
        Currencies: XmlNodeList;
        Currency: XmlNode;
        Series: XmlNode;
        Node: XmlNode;
        Rows: XmlNodeList;
        Row: XmlNode;
        NodeValue: Variant;
    begin
        if not Xml.SelectNodes('//*[local-name()="TimeSeries"]', Currencies) then exit;
        if not Setup.Get() then
            Setup.Init();

        foreach Currency in Currencies do begin
            Currency.SelectSingleNode('./*[local-name()="Description"]', Node);
            if (Node.AsXmlElement().InnerText.Contains(PurchaseTypeTok) and (Setup."Rate Type" = Setup."Rate Type"::Purchase)) or
               (Node.AsXmlElement().InnerText.Contains(SalesTypeTok) and (Setup."Rate Type" = Setup."Rate Type"::Sales)) or
               (Node.AsXmlElement().InnerText.Contains(AverageTypeTok) and (Setup."Rate Type" = Setup."Rate Type"::Average)) then begin
                TempCurrencyExchangeRate.Init();
                TempCurrencyExchangeRate."Exchange Rate Amount" := 1;
                Currency.SelectSingleNode('./*[local-name()="FameName"]', Node);
                TempCurrencyExchangeRate."Currency Code" := CopyStr(Node.AsXmlElement().InnerText, 1, 3);
                Currency.SelectSingleNode('./*[local-name()="TimeSeriesData"]', Series);
                Series.SelectNodes('./*[local-name()="Entry"]', Rows);
                foreach Row in Rows do begin
                    Row.SelectSingleNode('./*[local-name()="Date"]', Node);
                    NodeValue := CurrentDateTime();
                    if TypeHelper.Evaluate(NodeValue, Node.AsXmlElement().InnerText, '', 'en-US') then
                        TempCurrencyExchangeRate."Starting Date" := DT2Date(NodeValue);
                    Row.SelectSingleNode('./*[local-name()="Value"]', Node);
                    Evaluate(TempCurrencyExchangeRate."Relational Exch. Rate Amount", Node.AsXmlElement().InnerText, 9);
                    CurrHelper.OnBeforeAddCurrencyExchangeRate(UrlTok, TempCurrencyExchangeRate);
                    TempCurrencyExchangeRate.Insert();
                    CurrHelper.OnAfterAddingXmlCurrencyExchangeRate(UrlTok, Xml, Currency, TempCurrencyExchangeRate);
                end;
            end;
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N Sedlabanki.is Period";
        CurrencyExchangeRateService."Setup Page Id" := Page::"O4N Sedlabanki.is Setup";
        CurrencyExchangeRateService.Insert(true);
    end;



    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        UrlTok: label 'https://D365Connect.com/ISK/sedlabanki.is/period', Locked = true, MaxLength = 250;
        DescTok: Label 'Downloads missing exchange rates', Comment = '%1 = Web Service Url', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.sedlabanki.is/hagtolur/xml-gogn/', MaxLength = 250, Locked = true;
        SalesTypeTok: Label 'skráð sölugengi.', Locked = true;
        PurchaseTypeTok: Label 'skráð kaupgengi.', Locked = true;
        AverageTypeTok: Label 'skráð miðgengi.', Locked = true;
}