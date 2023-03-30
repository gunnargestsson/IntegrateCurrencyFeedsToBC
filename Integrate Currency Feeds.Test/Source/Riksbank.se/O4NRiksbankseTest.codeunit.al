codeunit 93551 "O4N Riksbank.se Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        CurrExchRateLibrary: Codeunit "O4N Curr. Exch. Rate Library";


    [Test]
    procedure "SetOfCurrencies_LatestRequested_VerifyRequestXml"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        RiksbankseLatest: Codeunit "O4N Riksbank.se Latest";
        Xml: XmlDocument;
    begin
        // [GIVEN] SEK as LCY Currency and a Set Of Currencies 
        GLSetup.ModifyAll("LCY Code", 'SEK');
        Currency.DeleteAll();
        AddCurrencyCode('AUD', Currency);
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('EUR', Currency);

        // [WHEN] Latest Requested
        RiksbankseLatest.CreateRequestXml(GLSetup, Xml);

        // [THEN] Verify Request Xml
        TestRequestXml(Xml);

    end;

    [Test]
    procedure "SetOfCurrencies_LatestRequested_VerifySentRequestXml"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        TempBuffer: Record "O4N Currency Buffer" temporary;
        RiksbankseLatest: Codeunit "O4N Riksbank.se Latest";
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Header: HttpHeaders;
        Xml: Text;
        HeaderValues: Array[1] of Text;
    begin
        // [GIVEN] SEK as LCY Currency and a Set Of Currencies 
        GLSetup.ModifyAll("LCY Code", 'SEK');
        Currency.DeleteAll();
        AddCurrencyCode('AUD', Currency);
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('EUR', Currency);

        // [GIVEN] Fixed response
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetRiksbankseLatestXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);

        // [WHEN] Latest Requested
        TempBuffer.Insert(true);
        RiksbankseLatest.Run(TempBuffer);
        CurrExchRateLibrary.GetRequest(Request);
        UnbindSubscription(CurrExchRateLibrary);

        // [THEN] Verify the Request header
        Assert.IsTrue(Request.Content.GetHeaders(Header), 'Unable to get request headers');
        Assert.IsTrue(Header.Contains('Content-Type'), 'Content type header missing');
        Assert.IsTrue(Header.GetValues('Content-Type', HeaderValues), 'Unable to get the content type value');
        Assert.AreEqual('application/soap+xml; charset=UTF-8; action="urn:getLatestInterestAndExchangeRates"', HeaderValues[1], 'Incorrect header value');

        // [THEN] Verify the request Url
        Assert.AreEqual('https://swea.riksbank.se/sweaWS/services/SweaWebServiceHttpSoap12Endpoint', Request.GetRequestUri(), 'Incorrect Url');

        // [THEN] Verify Request Xml
        Request.Content.ReadAs(Xml);
        TestRequestXml(Xml);

    end;

    [Test]
    procedure "StandardResponseXml_D365 ConnectedToCurrencyXml_VerifyResultXml"()
    var
        TempBuffer: Record "O4N Currency Buffer" temporary;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        RiksbankseLatest: Codeunit "O4N Riksbank.se Latest";
        CurrencyHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        Xml: XmlDocument;
        OutStr: OutStream;
        InStr: InStream;
        XmlAsText: TextBuilder;
        XmlLine: Text;
    begin
        // [GIVEN] Standard response Xml
        XmlDocument.ReadFrom(CurrExchRateLibrary.GetRiksbankseLatestXmlResponse(), Xml);

        // [WHEN] D365 Connected To Currency Xml 
        TempBuffer."Temp Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        RiksbankseLatest.ReadXml(Xml, TempCurrencyExchangeRate);
        CurrencyHelper.CreateXml('mock-url', TempCurrencyExchangeRate, OutStr);

        // [THEN] Verify Result Xml
        TempBuffer."Temp Blob".CreateInStream(InStr, TextEncoding::UTF8);
        while InStr.ReadText(XmlLine) > 0 do
            XmlAsText.Append(XmlLine);

        XmlDocument.ReadFrom(XmlAsText.ToText(), Xml);
        TestResponseXml(Xml);
    end;

    [Test]
    procedure "StandardResponseXml_LatestRequest_VerifyResultXml"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        TempBuffer: Record "O4N Currency Buffer" temporary;
        RiksbankseLatest: Codeunit "O4N Riksbank.se Latest";
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Xml: XmlDocument;
        InStr: InStream;
        XmlAsText: TextBuilder;
        XmlLine: Text;
    begin
        // [GIVEN] SEK as LCY Currency and a Set Of Currencies 
        GLSetup.ModifyAll("LCY Code", 'SEK');
        Currency.DeleteAll();
        AddCurrencyCode('AUD', Currency);
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('EUR', Currency);

        // [GIVEN] Fixed response
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetRiksbankseLatestXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);

        // [WHEN] Latest Requested
        TempBuffer.Insert(true);
        RiksbankseLatest.Run(TempBuffer);
        CurrExchRateLibrary.GetRequest(Request);
        UnbindSubscription(CurrExchRateLibrary);

        // [THEN] Verify Result Xml
        TempBuffer."Temp Blob".CreateInStream(InStr, TextEncoding::UTF8);
        while InStr.ReadText(XmlLine) > 0 do
            XmlAsText.Append(XmlLine);

        XmlDocument.ReadFrom(XmlAsText.ToText(), Xml);
        TestResponseXml(Xml);
    end;

    [Test]
    procedure "CurrencyExchangeRateServicey_Registration_VerifyValues"()
    var
        TempCurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service" temporary;
        RiksbankseLatest: Codeunit "O4N Riksbank.se Latest";
    begin
        // [GIVEN] 

        // [WHEN] When Registration is executed
        RiksbankseLatest.RegisterService(TempCurrencyExchangeRateService);

        // [THEN] Verify registration values
        Assert.AreEqual('https://D365Connect.com/SEK/riksbank.se/latest', TempCurrencyExchangeRateService.Url, 'Url not matching');
        Assert.AreEqual(Codeunit::"O4N Riksbank.se Latest", TempCurrencyExchangeRateService."Codeunit Id", 'Codeunit Id not matching');
        Assert.AreEqual('Downloads the latest exchange rates', TempCurrencyExchangeRateService.Description, 'Description not matching');
        Assert.AreEqual('https://www.riksbank.se/en-gb/statistics/search-interest--exchange-rates/web-services/series-for-web-services/', TempCurrencyExchangeRateService."Service Provider", 'Service Provider not matching');
        Assert.AreEqual(0, TempCurrencyExchangeRateService."Setup Page Id", 'Setup page not matching');
    end;

    [Test]
    procedure "CurrencyExchangeRateServiceEmpty_DiscoveryExecuted_VerifyCodeunitExists"()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        TempCurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service" temporary;
        RiksbankseLatest: Codeunit "O4N Riksbank.se Latest";
    begin
        // [GIVEN] CurrencyExchangeRateService Empty
        CurrencyExchangeRateService.DeleteAll();

        // [WHEN] When Register Discovery Executed
        CurrencyExchangeRateService.DiscoverCurrencyMappingCodeunits();

        // [THEN] Verify CurrencyExchangeRateService exists
        RiksbankseLatest.RegisterService(TempCurrencyExchangeRateService);
        Assert.IsTrue(CurrencyExchangeRateService.Get(TempCurrencyExchangeRateService.Url), 'CurrencyExchangeRateService not found');
        Assert.AreEqual(TempCurrencyExchangeRateService."Codeunit Id", CurrencyExchangeRateService."Codeunit Id", 'Codeunit Id not matching');
        Assert.AreEqual(TempCurrencyExchangeRateService.Description, CurrencyExchangeRateService.Description, 'Description not matching');
        Assert.AreEqual(TempCurrencyExchangeRateService."Service Provider", CurrencyExchangeRateService."Service Provider", 'Service Provider not matching');

    end;

    [Test]
    [HandlerFunctions('ConfirmPageClose')]
    procedure "StandardResponseXml_SetupAndPreview_VerifyPreview"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        RiksbankseLatest: Codeunit "O4N Riksbank.se Latest";
        CurrExchRateServSetup: Codeunit "O4N Curr. Exch. Rate Serv Stp";
        CurrExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrExchRates: TestPage "Currency Exchange Rates";
        Response: HttpResponseMessage;
    begin
        // [GIVEN] Standard Response Xml
        CurrExchRateServSetup.SetApiCallsAllowed();

        GLSetup.ModifyAll("LCY Code", 'SEK');
        CurrExchrateUpdateSetup.DeleteAll();
        CurrencyExchangeRateService.DeleteAll();
        RiksbankseLatest.RegisterService(CurrencyExchangeRateService);
        Currency.DeleteAll();
        AddCurrencyCode('AUD', Currency);
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('EUR', Currency);
        Commit();

        // [GIVEN] Fixed response
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetRiksbankseLatestXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);

        // [WHEN] Setup
        CurrExchRateUpdateSetupCard.OpenNew();
        CurrExchRateUpdateSetupCard.Code.SetValue(Any.AlphabeticText(MaxStrLen(CurrExchRateUpdateSetup.Code)));
        CurrExchRateUpdateSetupCard.Description.SetValue(Any.AlphabeticText(MaxStrLen(CurrExchRateUpdateSetup.Description)));
        CurrExchRateUpdateSetupCard.ServiceURL.SetValue(CurrencyExchangeRateService.Url);
        UnbindSubscription(CurrExchRateLibrary);

        // [WHEN] Preview 
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetRiksbankseLatestXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);
        CurrExchRates.Trap();
        CurrExchRateUpdateSetupCard.Preview.Invoke();
        UnbindSubscription(CurrExchRateLibrary);

        // [THEN] Verify Preview 
        Assert.IsTrue(CurrExchRates.First(), 'First preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('AUD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(29, 09, 2020));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(6.4046);
        Assert.IsTrue(CurrExchRates.Next(), 'Second preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('CAD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(29, 09, 2020));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(6.7564);
        Assert.IsTrue(CurrExchRates.Next(), 'Third preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('DKK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(29, 09, 2020));
        CurrExchRates."Exchange Rate Amount".AssertEquals(100);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(141.7817);
        Assert.IsTrue(CurrExchRates.Next(), 'Fourth preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('EUR');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(29, 09, 2020));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(10.5553);

    end;

    local procedure TestRequestXml(XmlAsText: Text)
    var
        Xml: Xmldocument;
    begin
        XmlDocument.ReadFrom(XmlAsText, Xml);
        TestRequestXml(Xml);
    end;

    local procedure TestRequestXml(Xml: Xmldocument)
    var
        SearchNode: XmlNode;
        SearchAttribute: XmlAttribute;
    begin
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="Envelope"]', SearchNode), 'Envelope not found in Xml');
        Assert.IsTrue(SearchNode.AsXmlElement().HasAttributes, 'Namespace attributes missing in Envelope');
        Assert.AreEqual(2, SearchNode.AsXmlElement().Attributes().Count(), 'Namespace attributes missing in Envelope');
        Assert.AreEqual('http://www.w3.org/2003/05/soap-envelope', SearchNode.AsXmlElement().NamespaceUri, 'Incorrect namespace for Envelope');
        Assert.AreEqual('soap:Envelope', SearchNode.AsXmlElement().Name, 'Incorrect prefix in Envelope');
        Assert.IsTrue(SearchNode.AsXmlElement().Attributes().Get(1, SearchAttribute), 'First attribute not found');
        Assert.AreEqual('xmlns:soap', SearchAttribute.Name, 'Attribute name incorrect');
        Assert.AreEqual('http://www.w3.org/2003/05/soap-envelope', SearchAttribute.Value, 'Attribute value incorrect');
        Assert.IsTrue(SearchNode.AsXmlElement().Attributes().Get(2, SearchAttribute), 'First attribute not found');
        Assert.AreEqual('xmlns:xsd', SearchAttribute.Name, 'Attribute name incorrect');
        Assert.AreEqual('http://swea.riksbank.se/xsd', SearchAttribute.Value, 'Attribute value incorrect');
        Assert.IsTrue(SearchNode.AsXmlElement().HasElements, 'Child elements missing for Envelope');
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="Header"]', SearchNode), 'Header not found in Xml');
        Assert.AreEqual('soap:Header', SearchNode.AsXmlElement().Name, 'Incorrect prefix in header');
        Assert.IsFalse(SearchNode.AsXmlElement().HasAttributes, 'Unexpected attributes in header');
        Assert.IsFalse(SearchNode.AsXmlElement().HasElements, 'Unexpected child elements in header');
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="Body"]', SearchNode), 'Body not found in Xml');
        Assert.AreEqual('soap:Body', SearchNode.AsXmlElement().Name, 'Incorrect prefix in body');
        Assert.IsFalse(SearchNode.AsXmlElement().HasAttributes, 'Unexpected attributes in body');
        Assert.IsTrue(SearchNode.AsXmlElement().HasElements, 'Child elements missing for body');
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="getLatestInterestAndExchangeRates"]', SearchNode), 'method not found in Xml');
        Assert.AreEqual('xsd:getLatestInterestAndExchangeRates', SearchNode.AsXmlElement().Name, 'Incorrect prefix in body');
        Assert.IsFalse(SearchNode.AsXmlElement().HasAttributes, 'Unexpected attributes in method');
        Assert.IsTrue(SearchNode.AsXmlElement().HasElements, 'Child elements missing for method');
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="languageid"]', SearchNode), 'languageId not found in Xml');
        Assert.AreEqual('languageid', SearchNode.AsXmlElement().Name, 'Incorrect prefix in languageid');
        Assert.IsFalse(SearchNode.AsXmlElement().HasAttributes, 'Unexpected attributes in languageId');
        Assert.IsFalse(SearchNode.AsXmlElement().HasElements, 'Unexpected child elements in languageId');
        Assert.AreEqual('en', SearchNode.AsXmlElement().InnerText, 'Unexpected value in element');
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="seriesid" and text()="SEKAUDPMI"]', SearchNode), 'SEKAUDPMI not found in Xml');
        Assert.IsFalse(SearchNode.AsXmlElement().HasAttributes, 'Unexpected attributes in SEKAUDPMI');
        Assert.IsFalse(SearchNode.AsXmlElement().HasElements, 'Unexpected child elements in SEKAUDPMI');
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="seriesid" and text()="SEKCADPMI"]', SearchNode), 'SEKCADPMI not found in Xml');
        Assert.IsFalse(SearchNode.AsXmlElement().HasAttributes, 'Unexpected attributes in SEKCADPMI');
        Assert.IsFalse(SearchNode.AsXmlElement().HasElements, 'Unexpected child elements in SEKCADPMI');
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="seriesid" and text()="SEKDKKPMI"]', SearchNode), 'SEKDKKPMI not found in Xml');
        Assert.IsFalse(SearchNode.AsXmlElement().HasAttributes, 'Unexpected attributes in SEKDKKPMI');
        Assert.IsFalse(SearchNode.AsXmlElement().HasElements, 'Unexpected child elements in SEKDKKPMI');
        Assert.IsTrue(Xml.SelectSingleNode('//*[local-name()="seriesid" and text()="SEKEURPMI"]', SearchNode), 'SEKEURPMI not found in Xml');
        Assert.IsFalse(SearchNode.AsXmlElement().HasAttributes, 'Unexpected attributes in SEKEURPMI');
        Assert.IsFalse(SearchNode.AsXmlElement().HasElements, 'Unexpected child elements in SEKEURPMI');

        /* <?xml version="1.0" encoding="utf-8" standalone="yes"?>
        <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsd="http://swea.riksbank.se/xsd">
          <soap:Header />
          <soap:Body>
            <xsd:getLatestInterestAndExchangeRates>
              <languageid>en</languageid>
              <seriesid>SEKAUDPMI</seriesid>
              <seriesid>SEKCADPMI</seriesid>
              <seriesid>SEKDKKPMI</seriesid>
              <seriesid>SEKEURPMI</seriesid>
            </xsd:getLatestInterestAndExchangeRates>
          </soap:Body>
        </soap:Envelope> */

    end;

    local procedure TestResponseXml(Xml: Xmldocument)
    var
        SearchNodeList: XmlNodeList;
        SearchNode: XmlNode;
        CurrencyNode: XmlNode;
    begin
        Assert.IsTrue(Xml.SelectSingleNode('Currencies', SearchNode), 'Root element not found');
        SearchNodeList := SearchNode.AsXmlElement().GetChildElements();
        Assert.AreEqual(4, SearchNodeList.Count(), 'Unexpected child nodes');
        Assert.IsTrue(SearchNodeList.Get(1, SearchNode), 'Unable to get first childnode');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('CurrencyCode', CurrencyNode), 'currency code not found');
        Assert.AreEqual('AUD', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected currency code');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('StartingDate', CurrencyNode), 'currency code not found');
        Assert.AreEqual('2020-09-29', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected starting date');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('ExchangeRateAmount', CurrencyNode), 'currency code not found');
        Assert.AreEqual('1.0', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected exchange rate amount');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('RelationalExchRateAmount', CurrencyNode), 'currency code not found');
        Assert.AreEqual('6.4046', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected relational exchange rate amount');
        Assert.IsTrue(SearchNodeList.Get(2, SearchNode), 'Unable to get first childnode');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('CurrencyCode', CurrencyNode), 'currency code not found');
        Assert.AreEqual('CAD', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected currency code');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('StartingDate', CurrencyNode), 'currency code not found');
        Assert.AreEqual('2020-09-29', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected starting date');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('ExchangeRateAmount', CurrencyNode), 'currency code not found');
        Assert.AreEqual('1.0', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected exchange rate amount');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('RelationalExchRateAmount', CurrencyNode), 'currency code not found');
        Assert.AreEqual('6.7564', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected relational exchange rate amount');
        Assert.IsTrue(SearchNodeList.Get(3, SearchNode), 'Unable to get first childnode');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('CurrencyCode', CurrencyNode), 'currency code not found');
        Assert.AreEqual('DKK', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected currency code');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('StartingDate', CurrencyNode), 'currency code not found');
        Assert.AreEqual('2020-09-29', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected starting date');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('ExchangeRateAmount', CurrencyNode), 'currency code not found');
        Assert.AreEqual('100.0', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected exchange rate amount');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('RelationalExchRateAmount', CurrencyNode), 'currency code not found');
        Assert.AreEqual('141.7817', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected relational exchange rate amount');
        Assert.IsTrue(SearchNodeList.Get(4, SearchNode), 'Unable to get first childnode');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('CurrencyCode', CurrencyNode), 'currency code not found');
        Assert.AreEqual('EUR', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected currency code');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('StartingDate', CurrencyNode), 'currency code not found');
        Assert.AreEqual('2020-09-29', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected starting date');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('ExchangeRateAmount', CurrencyNode), 'currency code not found');
        Assert.AreEqual('1.0', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected exchange rate amount');
        Assert.IsTrue(SearchNode.AsXmlElement().SelectSingleNode('RelationalExchRateAmount', CurrencyNode), 'currency code not found');
        Assert.AreEqual('10.5553', CurrencyNode.AsXmlElement().InnerText(), 'Unexpected relational exchange rate amount');

    end;

    local procedure AddCurrencyCode(CurrencyCode: Code[10]; var Currency: Record Currency)
    begin
        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency."ISO Code" := CopyStr(CurrencyCode, 1, 3);
        Currency.Insert();
    end;

    [ConfirmHandler]
    procedure ConfirmPageClose(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

}
