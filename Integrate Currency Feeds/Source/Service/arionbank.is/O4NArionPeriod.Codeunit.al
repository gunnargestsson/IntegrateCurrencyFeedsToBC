codeunit 73412 "O4N Arion Period"
{
    TableNo = "O4N Currency Buffer";
    // https://www.arionbanki.is/markadir/gjaldmidlar/gengi/xml-export/?beginDate=%1&finalDate=%2&currencytype=AlmenntGengi

    trigger OnRun()
    var
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        GLSetup: Record "General Ledger Setup";
        CurrencyConvertion: Codeunit "O4N Currency Conversion";
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        CurrencyFilter: Codeunit "O4N Currency Filter Mgt.";
        CurrenyDate, StartDate, EndDate : Date;
        OutStr: OutStream;
        Xml: XmlDocument;
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");

        DateMgt.GetCurrencyPeriod(UrlTok, Rec."Get Structure", 'ISL', StartDate, EndDate);


        for CurrenyDate := StartDate to EndDate do begin
            DownloadXml(CurrenyDate, Xml);
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

    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        DescTok: Label 'Downloads missing exchange rates', Comment = '%1 = Web Service Url', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.arionbanki.is/markadir/gjaldmidlar/', MaxLength = 250, Locked = true;
        UrlTok: Label 'https://D365Connect.com/ISK/arionbanki.is/period', Locked = true, MaxLength = 250;

    procedure ReadXml(var Xml: XmlDocument; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        TempExistingCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        Setup: Record "O4N Arion Banki Setup";
        TypeHelper: Codeunit "Type Helper";
        PurchaseRate, SalesRate : Decimal;
        NodeValue: Variant;
        Currency: XmlNode;
        Node: XmlNode;
        Currencies: XmlNodeList;
    begin
        TempExistingCurrencyExchangeRate.Copy(TempCurrencyExchangeRate, true);
        if not Xml.SelectNodes('//*[local-name()="Currency"]', Currencies) then exit;
        if not Setup.Get() then
            Setup.Init();

        foreach Currency in Currencies do begin
            TempCurrencyExchangeRate.Init();
            Currency.SelectSingleNode('./*[local-name()="mynt"]', Node);
            TempCurrencyExchangeRate."Currency Code" := CopyStr(Node.AsXmlElement().InnerText, 1, 3);
            Currency.SelectSingleNode('./*[local-name()="Dagur"]', Node);
            NodeValue := CurrentDateTime();
            if TypeHelper.Evaluate(NodeValue, Node.AsXmlElement().InnerText, '', 'is-IS') then
                TempCurrencyExchangeRate."Starting Date" := DT2Date(NodeValue);
            Currency.SelectSingleNode('./*[local-name()="Kaupgengi"]', Node);
            Evaluate(PurchaseRate, Node.AsXmlElement().InnerText, 9);
            Currency.SelectSingleNode('./*[local-name()="Solugengi"]', Node);
            Evaluate(SalesRate, Node.AsXmlElement().InnerText, 9);
            TempCurrencyExchangeRate."Exchange Rate Amount" := 1;
            case Setup."Rate Type" of
                "O4N Arion Banki Rate Type"::Purchase:
                    TempCurrencyExchangeRate."Relational Exch. Rate Amount" := PurchaseRate;
                "O4N Arion Banki Rate Type"::Sales:
                    TempCurrencyExchangeRate."Relational Exch. Rate Amount" := SalesRate;
                "O4N Arion Banki Rate Type"::SalesPurchaseAverage:
                    TempCurrencyExchangeRate."Relational Exch. Rate Amount" := Round((PurchaseRate + SalesRate) / 2, 0.0001, '=');
            end;
            CurrHelper.OnBeforeAddCurrencyExchangeRate(UrlTok, TempCurrencyExchangeRate);
            if not TempExistingCurrencyExchangeRate.Get(TempCurrencyExchangeRate."Currency Code", TempCurrencyExchangeRate."Starting Date") then
                TempCurrencyExchangeRate.Insert();
            CurrHelper.OnAfterAddingXmlCurrencyExchangeRate(UrlTok, Xml, Currency, TempCurrencyExchangeRate);
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N Arion Period";
        CurrencyExchangeRateService."Setup Page Id" := Page::"O4N Arion Banki Setup";
        CurrencyExchangeRateService.Insert(true);
    end;

    local procedure DownloadXml(StartDate: Date; var ResponseXml: XmlDocument)
    var
        IsHandled: Boolean;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        InStr: InStream;
        RequestErr: Label 'Error Code: %1\%2', Comment = '%1 = Response Error Code, %2 = Response Error Phrase';
        RequestUrlTok: Label 'https://www.arionbanki.is/markadir/gjaldmidlar/gengi/xml-export/?beginDate=%1&currencytype=AlmenntGengi', Locked = true;
    begin
        Request.SetRequestUri(StrSubstNo(RequestUrlTok, Format(StartDate, 0, 9)));
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
