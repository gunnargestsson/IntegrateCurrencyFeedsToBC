codeunit 93552 "O4N Currency Conversion Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
    Any: Codeunit Any;

    [Test]
    procedure "ServiceInLCY_ConversionCalled_VerifySameExchangeRates"()
    var
        GLSetup: Record "General Ledger Setup";
        TempCurrencyExchangeRates: Record "Currency Exchange Rate" temporary;
        CreatedCurrencyExchangeRates: Record "Currency Exchange Rate";
        CurrencyConversion: Codeunit "O4N Currency Conversion";
    begin
        // [GIVEN] Service In LCY
        GLSetup.Get();
        GLSetup."LCY Code" := Any.AlphabeticText(MaxStrLen(TempCurrencyExchangeRates."Currency Code"));
        GLSetup.Modify();

        // [GIVEN] Random Exchange Rate
        CreateAnyCurrencyExchangeRate(Any.AlphabeticText(MaxStrLen(TempCurrencyExchangeRates."Currency Code")), Any.DateInRange(Today() - 50, 25), TempCurrencyExchangeRates);
        CreatedCurrencyExchangeRates := TempCurrencyExchangeRates;

        // [WHEN] Conversion Called        
        CurrencyConversion.ConvertToLCYRate(GLSetup."LCY Code", GLSetup."LCY Code", TempCurrencyExchangeRates);

        // [THEN] Verify Same Exchange Rates
        Assert.AreEqual(CreatedCurrencyExchangeRates."Currency Code", TempCurrencyExchangeRates."Currency Code", 'Currency Code error');
        Assert.AreEqual(CreatedCurrencyExchangeRates."Starting Date", TempCurrencyExchangeRates."Starting Date", 'Starting Date error');
        Assert.AreEqual(CreatedCurrencyExchangeRates."Exchange Rate Amount", TempCurrencyExchangeRates."Exchange Rate Amount", 'Exchange Rate Amount error');
        Assert.AreEqual(CreatedCurrencyExchangeRates."Adjustment Exch. Rate Amount", TempCurrencyExchangeRates."Adjustment Exch. Rate Amount", 'Exchange Rate Amount error');
    end;

    [Test]
    procedure "ServiceNotLCY_ConversionCalled_VerifyMirrorExchangeRates"()
    var
        GLSetup: Record "General Ledger Setup";
        TempCurrencyExchangeRates: Record "Currency Exchange Rate" temporary;
        CreatedCurrencyExchangeRates: Record "Currency Exchange Rate";
        CurrencyConversion: Codeunit "O4N Currency Conversion";
        ServiceCurrencyCode: Code[10];
    begin
        // [GIVEN] Service In LCY
        GLSetup.Get();
        GLSetup."LCY Code" := Any.AlphabeticText(MaxStrLen(TempCurrencyExchangeRates."Currency Code"));
        GLSetup.Modify();

        // [GIVEN] Random Exchange Rate
        CreateAnyCurrencyExchangeRate(GLSetup."LCY Code", Any.DateInRange(Today() - 50, 25), TempCurrencyExchangeRates);
        CreatedCurrencyExchangeRates := TempCurrencyExchangeRates;

        // [GIVEN] Service in Any Currency
        ServiceCurrencyCode := Any.AlphabeticText(MaxStrLen(TempCurrencyExchangeRates."Currency Code"));

        // [WHEN] Conversion Called
        CurrencyConversion.ConvertToLCYRate(ServiceCurrencyCode, GLSetup."LCY Code", TempCurrencyExchangeRates);

        // [THEN] Verify Mirror Exchange Rates
        Assert.AreEqual(ServiceCurrencyCode, TempCurrencyExchangeRates."Currency Code", 'Currency Code error');
        Assert.AreEqual(CreatedCurrencyExchangeRates."Starting Date", TempCurrencyExchangeRates."Starting Date", 'Starting Date error');
        Assert.AreNearlyEqual(100 * CreatedCurrencyExchangeRates."Relational Exch. Rate Amount", TempCurrencyExchangeRates."Exchange Rate Amount", 0.01, 'Exchange Rate Amount error');
        Assert.AreNearlyEqual(100 * CreatedCurrencyExchangeRates."Exchange Rate Amount", TempCurrencyExchangeRates."Relational Exch. Rate Amount", 0.01, 'Exchange Rate Amount error');
    end;

    [Test]
    procedure "ServiceNotLCY_ConversionCalled_VerifyConvertedExchangeRates"()
    var
        GLSetup: Record "General Ledger Setup";
        TempCurrencyExchangeRates: Record "Currency Exchange Rate" temporary;
        CreatedCurrencyExchangeRates: Record "Currency Exchange Rate";
        SecondCreatedCurrencyExchangeRates: Record "Currency Exchange Rate";
        CurrencyConversion: Codeunit "O4N Currency Conversion";
        ExchangeRate: Decimal;
        ServiceCurrencyCode: Code[10];
    begin
        // [GIVEN] Service In LCY
        GLSetup.Get();
        GLSetup."LCY Code" := Any.AlphabeticText(MaxStrLen(TempCurrencyExchangeRates."Currency Code"));
        GLSetup.Modify();

        // [GIVEN] Random Exchange Rate
        CreateAnyCurrencyExchangeRate(GLSetup."LCY Code", Any.DateInRange(Today() - 50, 25), TempCurrencyExchangeRates);
        CreatedCurrencyExchangeRates := TempCurrencyExchangeRates;

        // [GIVEN] Another random exchange rate
        CreateAnyCurrencyExchangeRate(Any.AlphabeticText(MaxStrLen(TempCurrencyExchangeRates."Currency Code")), CreatedCurrencyExchangeRates."Starting Date", TempCurrencyExchangeRates);
        SecondCreatedCurrencyExchangeRates := TempCurrencyExchangeRates;

        // [GIVEN] Service in Any Currency
        ServiceCurrencyCode := Any.AlphabeticText(MaxStrLen(TempCurrencyExchangeRates."Currency Code"));

        // [WHEN] Conversion Called
        CurrencyConversion.ConvertToLCYRate(ServiceCurrencyCode, GLSetup."LCY Code", TempCurrencyExchangeRates);

        // [THEN] Verify Mirror Exchange Rates
        TempCurrencyExchangeRates.SetRange("Currency Code", ServiceCurrencyCode);
        Assert.RecordCount(TempCurrencyExchangeRates, 1);
        TempCurrencyExchangeRates.FindFirst();
        Assert.AreEqual(ServiceCurrencyCode, TempCurrencyExchangeRates."Currency Code", 'Currency Code error');
        Assert.AreEqual(CreatedCurrencyExchangeRates."Starting Date", TempCurrencyExchangeRates."Starting Date", 'Starting Date error');
        Assert.AreNearlyEqual(100 * CreatedCurrencyExchangeRates."Relational Exch. Rate Amount", TempCurrencyExchangeRates."Exchange Rate Amount", 0.01, 'Exchange Rate Amount error');
        Assert.AreNearlyEqual(100 * CreatedCurrencyExchangeRates."Exchange Rate Amount", TempCurrencyExchangeRates."Relational Exch. Rate Amount", 0.01, 'Exchange Rate Amount error');

        // [THEN] Verify Converted Exchange Rates
        TempCurrencyExchangeRates.SetFilter("Currency Code", '<>%1', ServiceCurrencyCode);
        Assert.RecordCount(TempCurrencyExchangeRates, 1);
        TempCurrencyExchangeRates.FindFirst();
        ExchangeRate := Round(CreatedCurrencyExchangeRates."Relational Exch. Rate Amount" / CreatedCurrencyExchangeRates."Exchange Rate Amount", 0.000001);
        Assert.AreEqual(SecondCreatedCurrencyExchangeRates."Currency Code", TempCurrencyExchangeRates."Currency Code", 'Currency Code error');
        Assert.AreEqual(SecondCreatedCurrencyExchangeRates."Starting Date", TempCurrencyExchangeRates."Starting Date", 'Starting Date error');
        Assert.AreNearlyEqual(100, TempCurrencyExchangeRates."Exchange Rate Amount", 0.01, 'Exchange Rate Amount Error');
        Assert.AreNearlyEqual(Round(SecondCreatedCurrencyExchangeRates."Relational Exch. Rate Amount" / SecondCreatedCurrencyExchangeRates."Exchange Rate Amount", 0.000001), Round(ExchangeRate * TempCurrencyExchangeRates."Relational Exch. Rate Amount" / TempCurrencyExchangeRates."Exchange Rate Amount", 0.000001), 0.01, 'Exchange Rate Amount error');

    end;

    local procedure CreateAnyCurrencyExchangeRate(CurrencyCode: Code[10]; CurrencyDate: Date; var CurrencyExchangeRates: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRates.Init();
        CurrencyExchangeRates."Starting Date" := CurrencyDate;
        CurrencyExchangeRates."Currency Code" := CurrencyCode;
        CurrencyExchangeRates."Exchange Rate Amount" := Any.DecimalInRange(1000, 2);
        CurrencyExchangeRates."Relational Exch. Rate Amount" := Any.DecimalInRange(1000, 2);
        CurrencyExchangeRates.Insert();
    end;
}