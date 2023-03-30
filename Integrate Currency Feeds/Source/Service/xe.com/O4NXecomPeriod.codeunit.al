codeunit 73424 "O4N Xe.com Period"
{
    TableNo = "O4N Currency Buffer";
    // https://xecdapi.xe.com/v1/historic_rate.json/?from=USD&date=2020-11-01&to=CAD,JPY

    trigger OnRun()
    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Country: Record "Country/Region";
        Setup: Record "O4N Setup xe.com";
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        CurrencyFilter: Codeunit "O4N Currency Filter Mgt.";
        JObject: JsonObject;
        OutStr: OutStream;
        ToCurrencyCodeList: Text;
        Authorization: Text;
        StartDate: Date;
        EndDate: Date;
        CurrencyDate: Date;
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
        Authorization := Setup.GetBasicAuthorization();

        DateMgt.GetCurrencyPeriod(UrlTok, Rec."Get Structure", Country."ISO Code", StartDate, EndDate);

        ToCurrencyCodeList := CurrHelper.GetToCurrencyCodeText(UrlTok, GLSetup);

        for CurrencyDate := StartDate to EndDate do begin
            DownloadJson(GLSetup."LCY Code", ToCurrencyCodeList, CurrencyDate, Authorization, JObject);
            ReadJson(JObject, CurrencyDate, TempCurrencyExchangeRate);
        end;
        CurrencyFilter.ApplyFilter(Rec, TempCurrencyExchangeRate);
        Codeunit.Run(Codeunit::"O4N Currency Overwrite Mgt.", TempCurrencyExchangeRate);
        Rec."Temp Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        CurrHelper.CreateXml(UrlTok, TempCurrencyExchangeRate, OutStr);
        Rec.Modify();
    end;

    local procedure DownloadJson(FromCurrencyCode: Code[10]; ToCurrencyCodeList: Text; CurrencyDate: Date; Authorization: Text; var ResponseJson: JsonObject)
    var
        RequestUrlTok: Label 'https://xecdapi.xe.com/v1/historic_rate.json/?from=%1&date=%2&to=%3', Locked = true;
        RequestErr: Label 'Error Code: %1\%2', Comment = '%1 = Response Error Code, %2 = Response Error Phrase';
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        InStr: InStream;
        IsHandled: Boolean;
    begin
        Client.DefaultRequestHeaders.Add('Authorization', Authorization);
        Request.SetRequestUri(StrSubstNo(RequestUrlTok, FromCurrencyCode, Format(CurrencyDate, 0, 9), ToCurrencyCodeList));
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

    procedure ReadJson(var JObject: JsonObject; CurrencyDate: Date; var TempCurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        JToken: JsonToken;
        JValue: JsonToken;
    begin
        if not JObject.Get('to', JToken) then exit;
        foreach JToken in JToken.AsArray() do begin
            TempCurrencyExchangeRate.Init();
            TempCurrencyExchangeRate."Exchange Rate Amount" := 1;
            JToken.AsObject().Get('quotecurrency', JValue);
            TempCurrencyExchangeRate."Currency Code" := CopyStr(JValue.AsValue().AsText(), 1, MaxStrLen(TempCurrencyExchangeRate."Currency Code"));
            TempCurrencyExchangeRate."Starting Date" := CurrencyDate;
            JToken.AsObject().Get('mid', JValue);
            TempCurrencyExchangeRate."Relational Exch. Rate Amount" := JValue.AsValue().AsDecimal();
            CurrHelper.OnBeforeAddCurrencyExchangeRate(UrlTok, TempCurrencyExchangeRate);
            TempCurrencyExchangeRate.Insert();
            CurrHelper.OnAfterAddingJsonCurrencyExchangeRate(UrlTok, JObject.AsToken(), JToken, TempCurrencyExchangeRate);
        end;
        CurrHelper.OnAfterReadJson(UrlTok, JObject, TempCurrencyExchangeRate);
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N Xe.com Period";
        CurrencyExchangeRateService."Setup Page Id" := Page::"O4N Setup xe.com";
        CurrencyExchangeRateService.Insert(true);
    end;

    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        UrlTok: label 'https://D365Connect.com/ANY/xe.com/period', Locked = true, MaxLength = 250;
        DescTok: Label 'Downloads missing exchange rates', Comment = '%1 = Web Service Url', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.xe.com/xecurrencydata/#integration', MaxLength = 250, Locked = true;
        SetupMissingErr: Label 'Xe.com Setup is missing';
}