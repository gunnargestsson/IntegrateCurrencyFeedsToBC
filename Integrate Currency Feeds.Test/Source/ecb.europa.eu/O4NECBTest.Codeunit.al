codeunit 93555 "O4N ECB Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        CurrExchRateLibrary: Codeunit O4NECBLibrary;

    [Test]
    procedure "CurrencyExchangeRateServiceEmpty_DiscoveryExecuted_VerifyCodeunitExists"()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        TempCurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service" temporary;
        ECBLatest: Codeunit "O4N ecb.europa.eu Latest";
    begin
        // [GIVEN] CurrencyExchangeRateService Empty
        CurrencyExchangeRateService.DeleteAll();

        // [WHEN] When Register Discovery Executed
        CurrencyExchangeRateService.DiscoverCurrencyMappingCodeunits();

        // [THEN] Verify CurrencyExchangeRateService exists
        ECBLatest.RegisterService(TempCurrencyExchangeRateService);
        Assert.IsTrue(CurrencyExchangeRateService.Get(TempCurrencyExchangeRateService.Url), 'CurrencyExchangeRateService not found');
        Assert.AreEqual(TempCurrencyExchangeRateService."Codeunit Id", CurrencyExchangeRateService."Codeunit Id", 'Codeunit Id not matching');
        Assert.AreEqual(TempCurrencyExchangeRateService.Description, CurrencyExchangeRateService.Description, 'Description not matching');
        Assert.AreEqual(TempCurrencyExchangeRateService."Service Provider", CurrencyExchangeRateService."Service Provider", 'Service Provider not matching');

    end;

    [Test]
    [HandlerFunctions('ConfirmPageClose')]
    procedure "EURCompany_SetupAndPreview_VerifyPreview"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        ECBLatest: Codeunit "O4N ecb.europa.eu Latest";
        CurrExchRateServSetup: Codeunit "O4N Curr. Exch. Rate Serv Stp";
        CurrExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrExchRates: TestPage "Currency Exchange Rates";
        Response: HttpResponseMessage;
    begin
        // [GIVEN] Standard Response Xml
        CurrExchRateServSetup.SetApiCallsAllowed();

        GLSetup.ModifyAll("LCY Code", 'EUR');
        CurrExchrateUpdateSetup.DeleteAll();
        CurrencyExchangeRateService.DeleteAll();
        ECBLatest.RegisterService(CurrencyExchangeRateService);
        Currency.DeleteAll();
        AddCurrencyCode('AUD', Currency);
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('SEK', Currency);
        Commit();

        // [GIVEN] Fixed response
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetECBLatestXmlResponse());
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
        Response.Content.WriteFrom(CurrExchRateLibrary.GetECBLatestXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);
        CurrExchRates.Trap();
        CurrExchRateUpdateSetupCard.Preview.Invoke();
        UnbindSubscription(CurrExchRateLibrary);

        // [THEN] Verify Preview 
        Assert.IsTrue(CurrExchRates.First(), 'First preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('AUD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1.5465);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1.5465);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(1);
        Assert.IsTrue(CurrExchRates.Next(), 'Second preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('CAD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(1.4361);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(1.4361);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(1);
        Assert.IsTrue(CurrExchRates.Next(), 'Third preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('DKK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(7.4392);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(7.4392);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(1);
        Assert.IsTrue(CurrExchRates.Next(), 'Fourth preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('SEK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(9.9848);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(9.9848);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(1);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(1);

    end;

    [Test]
    [HandlerFunctions('ConfirmPageClose')]
    procedure "CZKCompany_SetupAndPreview_VerifyPreview"()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        ECBLatest: Codeunit "O4N ecb.europa.eu Latest";
        CurrExchRateServSetup: Codeunit "O4N Curr. Exch. Rate Serv Stp";
        CurrExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrExchRates: TestPage "Currency Exchange Rates";
        Response: HttpResponseMessage;
    begin
        // [GIVEN] Standard Response Xml
        CurrExchRateServSetup.SetApiCallsAllowed();

        GLSetup.ModifyAll("LCY Code", 'CZK');
        CurrExchrateUpdateSetup.DeleteAll();
        CurrencyExchangeRateService.DeleteAll();
        ECBLatest.RegisterService(CurrencyExchangeRateService);
        Currency.DeleteAll();
        AddCurrencyCode('AUD', Currency);
        AddCurrencyCode('CAD', Currency);
        AddCurrencyCode('DKK', Currency);
        AddCurrencyCode('SEK', Currency);
        AddCurrencyCode('EUR', Currency);
        Commit();

        // [GIVEN] Fixed response
        Clear(CurrExchRateLibrary);
        BindSubscription(CurrExchRateLibrary);
        Response.Content.WriteFrom(CurrExchRateLibrary.GetECBLatestXmlResponse());
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
        Response.Content.WriteFrom(CurrExchRateLibrary.GetECBLatestXmlResponse());
        CurrExchRateLibrary.SetResponse(Response);
        CurrExchRates.Trap();
        CurrExchRateUpdateSetupCard.Preview.Invoke();
        UnbindSubscription(CurrExchRateLibrary);

        // [THEN] Verify Preview 
        Assert.IsTrue(CurrExchRates.First(), 'First preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('AUD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(100);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(100);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(100 * 25.700 / 1.5465);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(100 * 25.700 / 1.5465);
        Assert.IsTrue(CurrExchRates.Next(), 'Second preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('CAD');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(100);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(100);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(100 * 25.700 / 1.4361);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(100 * 25.700 / 1.4361);
        Assert.IsTrue(CurrExchRates.Next(), 'Third preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('DKK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(100);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(100);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(100 * 25.700 / 7.4392);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(100 * 25.700 / 7.4392);
        Assert.IsTrue(CurrExchRates.Next(), 'Fourth preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('EUR');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(100);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(100);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(100 * 25.700);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(100 * 25.700);
        Assert.IsTrue(CurrExchRates.Next(), 'Fifth preview entry not found');
        CurrExchRates."Currency Code".AssertEquals('SEK');
        CurrExchRates."Relational Currency Code".AssertEquals('');
        CurrExchRates."Starting Date".AssertEquals(DMY2Date(26, 10, 2021));
        CurrExchRates."Exchange Rate Amount".AssertEquals(100);
        CurrExchRates."Adjustment Exch. Rate Amount".AssertEquals(100);
        CurrExchRates."Relational Exch. Rate Amount".AssertEquals(100 * 25.700 / 9.9848);
        CurrExchRates."Relational Adjmt Exch Rate Amt".AssertEquals(100 * 25.700 / 9.9848);

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
