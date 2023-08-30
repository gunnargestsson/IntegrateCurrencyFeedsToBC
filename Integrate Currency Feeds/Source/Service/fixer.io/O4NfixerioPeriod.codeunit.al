codeunit 73425 "O4N fixer.io Period"
{
    TableNo = "O4N Currency Buffer";
    // http://data.fixer.io/api/2013-12-24? access_key = API_KEY& base = GBP& symbols = USD,CAD,EUR

    trigger OnRun()
    var
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        GLSetup: Record "General Ledger Setup";
        Setup: Record "O4N Setup fixer.io";
        CurrencyConvertion: Codeunit "O4N Currency Conversion";
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        CurrencyFilter: Codeunit "O4N Currency Filter Mgt.";
        BaseCurrencyCode: Code[10];
        CurrencyDate: Date;
        EndDate: Date;
        StartDate: Date;
        JObject: JsonObject;
        OutStr: OutStream;
        ToCurrencyCodeList: Text;
        Url: Text;
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        CompanyInfo.Get();
        CompanyInfo.TestField("Country/Region Code");
        Country.Get(CompanyInfo."Country/Region Code");
        Country.TestField("ISO Code");

        if not Setup.Get() then
            Error(SetupMissingErr);
        Setup.VerifyAuthorization();

        DateMgt.GetCurrencyPeriod(UrlTok, Rec."Get Structure", Country."ISO Code", StartDate, EndDate);
        ToCurrencyCodeList := CurrHelper.GetToCurrencyCodeText(UrlTok, GLSetup);

        for CurrencyDate := StartDate to EndDate do begin
            Url := GetUrl(Rec."Get Structure", Setup."Subscription Type", Setup.GetAccessKey(), GLSetup."LCY Code", ToCurrencyCodeList, CurrencyDate);
            DownloadJson(Url, JObject);
            BaseCurrencyCode := ReadJson(JObject, TempCurrencyExchangeRate);
        end;
        if GLSetup."LCY Code" <> BaseCurrencyCode then
            CurrencyConvertion.ConvertToLCYRate(BaseCurrencyCode, GLSetup."LCY Code", TempCurrencyExchangeRate);
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
        ServiceProviderTok: Label 'https://fixer.io/dashboard', MaxLength = 250, Locked = true;
        SetupMissingErr: Label 'fixer.io Setup is missing';
        UrlTok: Label 'https://D365Connect.com/ANY/fixer.io/period', Locked = true, MaxLength = 250;

    procedure ReadJson(var JObject: JsonObject; var TempCurrencyExchangeRate: Record "Currency Exchange Rate") BaseCurrencyCode: Code[10];
    var
        JErrorCode: JsonToken;
        JErrorType: JsonToken;
        JToken: JsonToken;
        RequestErr: Label 'Error Code: %1\%2', Comment = '%1 = Response Error Code, %2 = Response Error Phrase';
    begin
        if not JObject.Get('success', JToken) then exit;
        if not JToken.AsValue().AsBoolean() then begin
            JObject.Get('error', JToken);
            JToken.AsObject().Get('code', JErrorCode);
            JToken.AsObject().Get('type', JErrorType);
            Error(RequestErr, JErrorCode.AsValue().AsText(), JErrorType.AsValue().AsText());
        end;
        JObject.Get('base', JToken);
        BaseCurrencyCode := CopyStr(JToken.AsValue().AsCode(), 1, MaxStrLen(BaseCurrencyCode));
        JObject.Get('date', JToken);
        TempCurrencyExchangeRate."Starting Date" := JToken.AsValue().AsDate();
        JObject.Get('rates', JToken);
        foreach JToken in JToken.AsObject().Values() do begin
            TempCurrencyExchangeRate.Init();
            TempCurrencyExchangeRate."Exchange Rate Amount" := 1;
            TempCurrencyExchangeRate."Currency Code" := CopyStr(JToken.AsValue().Path, 7, MaxStrLen(TempCurrencyExchangeRate."Currency Code"));
            TempCurrencyExchangeRate."Relational Exch. Rate Amount" := JToken.AsValue().AsDecimal();
            if TempCurrencyExchangeRate."Currency Code" <> BaseCurrencyCode then begin
                CurrHelper.OnBeforeAddCurrencyExchangeRate(UrlTok, TempCurrencyExchangeRate);
                TempCurrencyExchangeRate.Insert();
            end;
            CurrHelper.OnAfterAddingJsonCurrencyExchangeRate(UrlTok, JObject.AsToken(), JToken, TempCurrencyExchangeRate);
        end;
        CurrHelper.OnAfterReadJson(UrlTok, JObject, TempCurrencyExchangeRate);
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N fixer.io Period";
        CurrencyExchangeRateService."Setup Page Id" := Page::"O4N Setup fixer.io";
        CurrencyExchangeRateService.Insert(true);
    end;

    local procedure DownloadJson(Url: Text; var ResponseJson: JsonObject)
    var
        IsHandled: Boolean;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        InStr: InStream;
        RequestErr: Label 'Error Code: %1\%2', Comment = '%1 = Response Error Code, %2 = Response Error Phrase';
    begin
        Request.SetRequestUri(Url);
        Request.Method('GET');
        CurrHelper.OnBeforeClientSend(UrlTok, Request, Response, IsHandled);
        if not IsHandled then
            Client.Send(Request, Response);
        HttpHelper.ThrowError(Response);
        HttpHelper.CreateInStream(InStr);
        Response.Content.ReadAs(InStr);
        HttpHelper.ReadInStr(InStr, ResponseJson);
        if not Response.IsSuccessStatusCode then
            Error(RequestErr, Response.HttpStatusCode, Response.ReasonPhrase);
    end;

    local procedure GetUrl(GetStructure: Boolean; SubscriptionType: Enum "O4N fixer.io Subscription Type"; AccessKey: Text; Base: Code[10]; Symbols: Text; CurrencyDate: Date) Url: Text;
    begin
        case true of
            GetStructure and (SubscriptionType = SubscriptionType::Free):
                Url := 'http://data.fixer.io/api/latest?access_key=' + AccessKey;
            GetStructure:
                Url := 'https://data.fixer.io/api/latest?access_key=' + AccessKey;
            SubscriptionType = SubscriptionType::Free:
                Url := 'http://data.fixer.io/api/' + Format(CurrencyDate, 0, 9) + '?access_key=' + AccessKey;
            else
                Url := 'https://data.fixer.io/api/' + Format(CurrencyDate, 0, 9) + '?access_key=' + AccessKey + '&base=' + Base + '&symbols=' + Symbols;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"O4N Curr. Exch. Rate Service", 'DiscoverCurrencyMappingCodeunits', '', false, false)]
    local procedure DiscoverCurrencyMappingCodeunits()
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
    begin
        RegisterService(CurrencyExchangeRateService);
    end;
}