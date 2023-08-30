codeunit 93560 "O4N Arion Banki Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        CurrExchRateLibrary: Codeunit "O4N Arion Banki Library";

    [Test]
    procedure "CurrencyExchangeRateServiceEmpty_DiscoveryExecuted_VerifyCodeunitExists"()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        TempCurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service" temporary;
        ArionBanki: Codeunit "O4N Arion Period";
    begin
        // [GIVEN] CurrencyExchangeRateService Empty
        CurrencyExchangeRateService.DeleteAll();

        // [WHEN] When Register Discovery Executed
        CurrencyExchangeRateService.DiscoverCurrencyMappingCodeunits();

        // [THEN] Verify CurrencyExchangeRateService exists
        ArionBanki.RegisterService(TempCurrencyExchangeRateService);
        Assert.IsTrue(CurrencyExchangeRateService.Get(TempCurrencyExchangeRateService.Url), 'CurrencyExchangeRateService not found');
        Assert.AreEqual(TempCurrencyExchangeRateService."Codeunit Id", CurrencyExchangeRateService."Codeunit Id", 'Codeunit Id not matching');
        Assert.AreEqual(TempCurrencyExchangeRateService.Description, CurrencyExchangeRateService.Description, 'Description not matching');
        Assert.AreEqual(TempCurrencyExchangeRateService."Service Provider", CurrencyExchangeRateService."Service Provider", 'Service Provider not matching');

    end;

    [Test]
    [HandlerFunctions('ConfirmPageClose')]
    procedure "ISKCompany_SetupAndPreview_VerifyPurchasesPreview"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        Arionbanki: Codeunit "O4N Arion Period";
        CurrExchRateServSetup: Codeunit "O4N Curr. Exch. Rate Serv Stp";
        CacheHandler: Codeunit "O4N Cache Handler";
        CurrExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrExchRates: TestPage "Currency Exchange Rates";
        Response: HttpResponseMessage;
    begin
        // [GIVEN] Standard Response Xml
        CurrExchRateServSetup.SetApiCallsAllowed();
        InitSetup("O4N Arion Banki Rate Type"::Purchase);

        GLSetup.ModifyAll("LCY Code", 'ISK');
        CurrExchrateUpdateSetup.DeleteAll();
        CurrencyExchangeRateService.DeleteAll();
        Arionbanki.RegisterService(CurrencyExchangeRateService);
        Currency.DeleteAll();
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('SEK', Currency);
        Commit();

        // [GIVEN] Fixed response
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetArionBankiXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);

        // [WHEN] Setup
        BindSubscription(CacheHandler);
        CacheHandler.SetCacheUrl('https://d365services4bc.blob.core.windows.net/testxml/f2ef4825b0e74ea98af690cf55666693.xml');
        CurrExchRateUpdateSetupCard.OpenNew();
        CurrExchRateUpdateSetupCard.Code.SetValue(Any.AlphabeticText(MaxStrLen(CurrExchRateUpdateSetup.Code)));
        CurrExchRateUpdateSetupCard.Description.SetValue(Any.AlphabeticText(MaxStrLen(CurrExchRateUpdateSetup.Description)));
        CurrExchRateUpdateSetupCard.ServiceURL.SetValue(CurrencyExchangeRateService.Url);
        UnbindSubscription(CurrExchRateLibrary);
        UnbindSubscription(CacheHandler);

        // [WHEN] Preview 
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetArionBankiXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);
        CurrExchRates.Trap();
        CurrExchRateUpdateSetupCard.Preview.Invoke();
        UnbindSubscription(CurrExchRateLibrary);

        // [THEN] Verify Preview 
        Assert.IsTrue(CurrExchRates.First(), 'First preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('CAD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(96.0550);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(96.0550);
        Assert.IsTrue(CurrExchRates.Next(), 'Second preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('DKK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(18.9990);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(18.9990);
        Assert.IsTrue(CurrExchRates.Next(), 'Third preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('SEK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(11.9500);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(11.9500);
    end;

    [Test]
    [HandlerFunctions('ConfirmPageClose')]
    procedure "ISKCompany_SetupAndPreview_VerifySalesPreview"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        Arionbanki: Codeunit "O4N Arion Period";
        CurrExchRateServSetup: Codeunit "O4N Curr. Exch. Rate Serv Stp";
        CacheHandler: Codeunit "O4N Cache Handler";
        CurrExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrExchRates: TestPage "Currency Exchange Rates";
        Response: HttpResponseMessage;
    begin
        // [GIVEN] Standard Response Xml
        CurrExchRateServSetup.SetApiCallsAllowed();
        InitSetup("O4N Arion Banki Rate Type"::Sales);

        GLSetup.ModifyAll("LCY Code", 'ISK');
        CurrExchrateUpdateSetup.DeleteAll();
        CurrencyExchangeRateService.DeleteAll();
        Arionbanki.RegisterService(CurrencyExchangeRateService);
        Currency.DeleteAll();
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('SEK', Currency);
        Commit();

        // [GIVEN] Fixed response
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetArionBankiXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);

        // [WHEN] Setup
        BindSubscription(CacheHandler);
        CacheHandler.SetCacheUrl('https://d365services4bc.blob.core.windows.net/testxml/f2ef4825b0e74ea98af690cf55666693.xml');
        CurrExchRateUpdateSetupCard.OpenNew();
        CurrExchRateUpdateSetupCard.Code.SetValue(Any.AlphabeticText(MaxStrLen(CurrExchRateUpdateSetup.Code)));
        CurrExchRateUpdateSetupCard.Description.SetValue(Any.AlphabeticText(MaxStrLen(CurrExchRateUpdateSetup.Description)));
        CurrExchRateUpdateSetupCard.ServiceURL.SetValue(CurrencyExchangeRateService.Url);
        UnbindSubscription(CurrExchRateLibrary);
        UnbindSubscription(CacheHandler);

        // [WHEN] Preview 
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetArionBankiXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);
        CurrExchRates.Trap();
        CurrExchRateUpdateSetupCard.Preview.Invoke();
        UnbindSubscription(CurrExchRateLibrary);

        // [THEN] Verify Preview 
        Assert.IsTrue(CurrExchRates.First(), 'First preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('CAD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(96.7300);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(96.7300);
        Assert.IsTrue(CurrExchRates.Next(), 'Second preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('DKK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(19.1330);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(19.1330);
        Assert.IsTrue(CurrExchRates.Next(), 'Third preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('SEK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(12.0340);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(12.0340);
    end;

    [Test]
    [HandlerFunctions('ConfirmPageClose')]
    procedure "ISKCompany_SetupAndPreview_VerifyAveragesPreview"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        Arionbanki: Codeunit "O4N Arion Period";
        CurrExchRateServSetup: Codeunit "O4N Curr. Exch. Rate Serv Stp";
        CacheHandler: Codeunit "O4N Cache Handler";
        CurrExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrExchRates: TestPage "Currency Exchange Rates";
        Response: HttpResponseMessage;
    begin
        // [GIVEN] Standard Response Xml
        CurrExchRateServSetup.SetApiCallsAllowed();
        InitSetup("O4N Arion Banki Rate Type"::SalesPurchaseAverage);

        GLSetup.ModifyAll("LCY Code", 'ISK');
        CurrExchrateUpdateSetup.DeleteAll();
        CurrencyExchangeRateService.DeleteAll();
        Arionbanki.RegisterService(CurrencyExchangeRateService);
        Currency.DeleteAll();
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('SEK', Currency);
        Commit();

        // [GIVEN] Fixed response
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetArionBankiXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);

        // [WHEN] Setup
        BindSubscription(CacheHandler);
        CacheHandler.SetCacheUrl('https://d365services4bc.blob.core.windows.net/testxml/f2ef4825b0e74ea98af690cf55666693.xml');
        CurrExchRateUpdateSetupCard.OpenNew();
        CurrExchRateUpdateSetupCard.Code.SetValue(Any.AlphabeticText(MaxStrLen(CurrExchRateUpdateSetup.Code)));
        CurrExchRateUpdateSetupCard.Description.SetValue(Any.AlphabeticText(MaxStrLen(CurrExchRateUpdateSetup.Description)));
        CurrExchRateUpdateSetupCard.ServiceURL.SetValue(CurrencyExchangeRateService.Url);
        UnbindSubscription(CurrExchRateLibrary);
        UnbindSubscription(CacheHandler);

        // [WHEN] Preview 
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetArionBankiXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);
        CurrExchRates.Trap();
        CurrExchRateUpdateSetupCard.Preview.Invoke();
        UnbindSubscription(CurrExchRateLibrary);

        // [THEN] Verify Preview 
        Assert.IsTrue(CurrExchRates.First(), 'First preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('CAD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(96.3925);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(96.3925);
        Assert.IsTrue(CurrExchRates.Next(), 'Second preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('DKK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(19.0660);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(19.0660);
        Assert.IsTrue(CurrExchRates.Next(), 'Third preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('SEK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(30, 08, 2023));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(11.9920);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(11.9920);
    end;


    local procedure AddCurrencyCode(CurrencyCode: Code[10]; var Currency: Record Currency)
    begin
        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency."ISO Code" := CopyStr(CurrencyCode, 1, 3);
        Currency.Insert();
    end;

    local procedure InitSetup(ArionBankiRateType: Enum "O4N Arion Banki Rate Type")
    var
        Setup: Record "O4N Arion Banki Setup";
    begin
        Setup.DeleteAll();
        Setup.Init();
        Setup."Rate Type" := ArionBankiRateType;
        Setup.Insert();
    end;

    [ConfirmHandler]
    procedure ConfirmPageClose(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
