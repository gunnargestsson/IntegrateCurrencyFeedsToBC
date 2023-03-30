codeunit 93553 "O4N Currency Date Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;

    [Test]
    procedure "EmptyCompany_GetDates_VerifyReturnedDates"()
    var
        GLEntry: Record "G/L Entry";
        CurrencyExchangeRates: Record "Currency Exchange Rate";
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] Empty Company 
        GLEntry.DeleteAll();
        CurrencyExchangeRates.DeleteAll();

        // [WHEN] Get Dates
        DateMgt.GetCurrencyPeriod('mock-url', false, '', StartDate, EndDate);

        // [THEN] Verify Returned Dates
        Assert.AreEqual(Today(), StartDate, 'Start Date error');
        Assert.AreEqual(Today(), EndDate, 'End Date error');

    end;

    [Test]
    procedure "GLEntryExists_GetDates_VerifyReturnedDates"()
    var
        GLEntry: Record "G/L Entry";
        CurrencyExchangeRates: Record "Currency Exchange Rate";
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] GL Entry Exists 
        GLEntry.DeleteAll();
        CurrencyExchangeRates.DeleteAll();

        // [WHEN] Create GL Entry and Get Dates 
        CreateAnyGLEntry(GLEntry);
        DateMgt.GetCurrencyPeriod('mock-url', false, '', StartDate, EndDate);

        // [THEN] Verify Returned Dates 
        Assert.AreEqual(GLEntry."Posting Date", StartDate, 'Start Date error');
        Assert.AreEqual(Today(), EndDate, 'End Date error');

    end;

    [Test]
    procedure "CurrencyExchangeRateExists_GetDates_VerifyReturnedDates"()
    var
        GLEntry: Record "G/L Entry";
        CurrencyExchangeRates: Record "Currency Exchange Rate";
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] Currency Exchange Rate Exists 
        GLEntry.DeleteAll();
        CurrencyExchangeRates.DeleteAll();

        // [WHEN] Create Currency Exchange Rate and Get Dates 
        CreateAnyCurrencyExchangeRate(CurrencyExchangeRates);
        DateMgt.GetCurrencyPeriod('mock-url', false, '', StartDate, EndDate);

        // [THEN] Verify Returned Dates 
        Assert.AreEqual(CurrencyExchangeRates."Starting Date", StartDate, 'Start Date error');
        Assert.AreEqual(Today(), EndDate, 'End Date error');

    end;

    [Test]
    procedure "BothExists_GetDates_VerifyReturnedDates"()
    var
        GLEntry: Record "G/L Entry";
        CurrencyExchangeRates: Record "Currency Exchange Rate";
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] Both Exists 
        GLEntry.DeleteAll();
        CurrencyExchangeRates.DeleteAll();

        // [WHEN] Create GL Entry and Currency Exchange Rate and Get Dates 
        CreateAnyGLEntry(GLEntry);
        CreateAnyCurrencyExchangeRate(CurrencyExchangeRates);
        DateMgt.GetCurrencyPeriod('mock-url', false, '', StartDate, EndDate);

        // [THEN] Verify Returned Dates 
        Assert.AreEqual(CurrencyExchangeRates."Starting Date", StartDate, 'Start Date error');
        Assert.AreEqual(Today(), EndDate, 'End Date error');

    end;

    [Test]
    procedure "MatchingUrl_ManuallySetDates_VerifyReturnedDates"()
    var
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        MockDate: Codeunit "O4N Currency Date Mock";
        ExpectedStartDate: Date;
        ExpectedEndDate: Date;
        ResultStartDate: Date;
        ResultEndDate: Date;
    begin
        // [GIVEN] Any Date 
        ExpectedStartDate := Any.DateInRange(100);
        ExpectedEndDate := ExpectedStartDate + Any.IntegerInRange(10);

        // [WHEN] Manually Set Dates 
        BindSubscription(MockDate);
        MockDate.SetDates('mock-url', ExpectedStartDate, ExpectedEndDate);
        DateMgt.GetCurrencyPeriod('mock-url', false, '', ResultStartDate, ResultEndDate);

        // [THEN] Verify Returned Dates 
        Assert.AreEqual(ExpectedStartDate, ResultStartDate, 'Start Date error');
        Assert.AreEqual(ExpectedEndDate, ResultEndDate, 'End Date error');
        UnbindSubscription(MockDate);
    end;

    [Test]
    procedure "DifferentUrl_ManuallySetDates_VerifyReturnedDates"()
    var
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        MockDate: Codeunit "O4N Currency Date Mock";
        ExpectedStartDate: Date;
        ExpectedEndDate: Date;
        ResultStartDate: Date;
        ResultEndDate: Date;
    begin
        // [GIVEN] Any Date 
        ExpectedStartDate := Any.DateInRange(100);
        ExpectedEndDate := ExpectedStartDate + Any.IntegerInRange(10);

        // [WHEN] Manually Set Dates 
        BindSubscription(MockDate);
        MockDate.SetDates('mock-url', ExpectedStartDate, ExpectedEndDate);
        DateMgt.GetCurrencyPeriod('different-mock-url', false, '', ResultStartDate, ResultEndDate);

        // [THEN] Verify Returned Dates 
        Assert.AreNotEqual(ExpectedStartDate, ResultStartDate, 'Start Date error');
        Assert.AreNotEqual(ExpectedEndDate, ResultEndDate, 'End Date error');
        UnbindSubscription(MockDate);
    end;


    local procedure CreateAnyGLEntry(var GLEntry: Record "G/L Entry")
    begin
        GLEntry.Init();
        GLEntry."Entry No." := Any.IntegerInRange(10);
        GLEntry."Posting Date" := Any.DateInRange(Today() - 50, 25);
        GLEntry.Insert();
    end;

    local procedure CreateAnyCurrencyExchangeRate(var CurrencyExchangeRates: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRates.Init();
        CurrencyExchangeRates."Starting Date" := Any.DateInRange(Today() - 50, 25);
        CurrencyExchangeRates."Currency Code" := Any.AlphabeticText(MaxStrLen(CurrencyExchangeRates."Currency Code"));
        CurrencyExchangeRates.Insert();
    end;
}