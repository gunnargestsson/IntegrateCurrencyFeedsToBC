codeunit 73429 "O4N norges-bank.no Period"
{
    TableNo = "O4N Currency Buffer";
    // https://data.norges-bank.no/api/data/EXR/B..NOK.SP?startPeriod=2020-11-10&endPeriod=2020-11-17&format=sdmx-new-json&locale=en

    trigger OnRun()
    var
        GLSetup: Record "General Ledger Setup";
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        CurrencyConvertion: Codeunit "O4N Currency Conversion";
        CurrencyFilter: Codeunit "O4N Currency Filter Mgt.";
        DateMgt: Codeunit "O4N Currency Date Mgt.";
        JObject: JsonObject;
        OutStr: OutStream;
        ToCurrencyCodeList: Text;
        BaseCurrencyCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");

        DateMgt.GetCurrencyPeriod(UrlTok, Rec."Get Structure", 'NOR', StartDate, EndDate);
        ToCurrencyCodeList := CurrHelper.GetToCurrencyCodeText(UrlTok, GLSetup);

        DownloadJson(StrSubstNo(DownloadUrlTok, Format(StartDate, 0, 9), Format(EndDate, 0, 9)), JObject);
        BaseCurrencyCode := ReadJson(JObject, TempCurrencyExchangeRate);
        if GLSetup."LCY Code" <> BaseCurrencyCode then
            CurrencyConvertion.ConvertToLCYRate(BaseCurrencyCode, GLSetup."LCY Code", TempCurrencyExchangeRate);
        CurrencyFilter.ApplyFilter(Rec, TempCurrencyExchangeRate);
        Codeunit.Run(Codeunit::"O4N Currency Overwrite Mgt.", TempCurrencyExchangeRate);
        Rec."Temp Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
        CurrHelper.CreateXml(UrlTok, TempCurrencyExchangeRate, OutStr);
        Rec.Modify();
    end;

    local procedure DownloadJson(Url: Text; var ResponseJson: JsonObject)
    var
        RequestErr: Label 'Error Code: %1\%2', Comment = '%1 = Response Error Code, %2 = Response Error Phrase';
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        InStr: InStream;
        IsHandled: Boolean;
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

    procedure ReadJson(var JObject: JsonObject; var TempCurrencyExchangeRate: Record "Currency Exchange Rate") BaseCurrencyCode: Code[10];
    var
        TempBuffer: Record "Name/Value Buffer" temporary;
        TempDate: Record "Date" temporary;
        TempMultiplier: Record "Integer" temporary;
        TempDecimals: Record "Integer" temporary;
        JToken: JsonToken;
        JCurrencyCode: JsonToken;
        JCurrencyName: JsonToken;
        JCurrencyValue: JsonToken;
        JCurrencySeries: JsonToken;
        JDecimals: JsonValue;
        JCalculated: JsonValue;
        JCollectionIndicator: JsonValue;
        SeriesId: Text;
        AttributeNo: Integer;
    begin
        if not JObject.SelectToken('data.structure.dimensions.series[?(@.id==''QUOTE_CUR'')].values[0].id', JToken) then
            Error(UnableToReadBaseCurrencyFromJsonErr);
        BaseCurrencyCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(BaseCurrencyCode));

        if not JObject.SelectToken('data.structure.dimensions.series[?(@.id==''BASE_CUR'')].values', JToken) then exit;
        foreach JToken in JToken.AsArray() do
            if JToken.AsObject().Get('id', JCurrencyCode) then
                if JToken.AsObject().Get('name', JCurrencyName) then
                    TempBuffer.AddNewEntry(CopyStr(JCurrencyName.AsValue().AsText(), 1, MaxStrLen(TempBuffer.Name)), JCurrencyCode.AsValue().AsText());

        if not JObject.SelectToken('data.structure.attributes.series[?(@.id==''DECIMALS'')].values', JToken) then exit;
        foreach JToken in JToken.AsArray() do
            if JToken.AsObject().Get('id', JToken) then begin
                Evaluate(TempDecimals.Number, JToken.AsValue().AsText(), 9);
                TempDecimals.Insert();
            end;

        if not JObject.SelectToken('data.structure.attributes.series[?(@.id==''UNIT_MULT'')].values', JToken) then exit;
        foreach JToken in JToken.AsArray() do
            if JToken.AsObject().Get('id', JToken) then begin
                Evaluate(TempMultiplier.Number, JToken.AsValue().AsText(), 9);
                TempMultiplier.Insert();
            end;

        if not JObject.SelectToken('data.structure.dimensions.observation[?(@.id==''TIME_PERIOD'')].values', JToken) then exit;
        foreach JToken in JToken.AsArray() do
            if JToken.AsObject().Get('id', JToken) then begin
                TempDate."Period Start" := JToken.AsValue().AsDate();
                TempDate.Insert();
            end;

        if JObject.SelectToken('data.dataSets[0].series', JToken) then
            foreach JCurrencySeries in JToken.AsObject().Values do begin
                CopyStr(JCurrencySeries.Path, 25).Split(':').Get(2, SeriesId);
                Evaluate(TempBuffer.ID, SeriesId, 9);
                TempBuffer.Next();
                AttributeNo := 0;

                if JCurrencySeries.AsObject().Get('attributes', JToken) then
                    foreach JToken in JToken.AsArray() do begin
                        AttributeNo += 1;
                        case AttributeNo of
                            1: // Decimals
                                JDecimals := JToken.AsValue();
                            2: // Calculated
                                JCalculated := JToken.AsValue();
                            3: // Unit Multiplier
                                begin
                                    TempMultiplier.FindSet();
                                    TempMultiplier.Next(JToken.AsValue().AsInteger());
                                end;
                            4: // Collection Indicator
                                JCollectionIndicator := JToken.AsValue();
                        end;
                    end;

                if JCurrencySeries.AsObject().Get('observations', JToken) then begin
                    TempDate.FindSet();
                    foreach JToken in JToken.AsObject().Values do begin
                        JToken.AsArray().Get(0, JCurrencyValue);
                        TempCurrencyExchangeRate.Init();
                        TempCurrencyExchangeRate."Exchange Rate Amount" := 1 * Power(10, TempMultiplier.Number);
                        TempCurrencyExchangeRate."Currency Code" := CopyStr(TempBuffer.GetValue(), 1, MaxStrLen(TempCurrencyExchangeRate."Currency Code"));
                        TempCurrencyExchangeRate."Relational Exch. Rate Amount" := JCurrencyValue.AsValue().AsDecimal();
                        TempCurrencyExchangeRate."Starting Date" := TempDate."Period Start";
                        if TempCurrencyExchangeRate."Currency Code" <> BaseCurrencyCode then begin
                            CurrHelper.OnBeforeAddCurrencyExchangeRate(UrlTok, TempCurrencyExchangeRate);
                            TempCurrencyExchangeRate.Insert();
                        end;
                        TempDate.Next();
                    end;
                end;

                CurrHelper.OnAfterAddingJsonCurrencyExchangeRate(UrlTok, JObject.AsToken(), JCurrencySeries, TempCurrencyExchangeRate);
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
        CurrencyExchangeRateService."Codeunit Id" := Codeunit::"O4N norges-bank.no Period";
        CurrencyExchangeRateService."Setup Page Id" := 0;
        CurrencyExchangeRateService.Insert(true);
    end;

    var
        HttpHelper: Codeunit "O4N Curr. Exch. Rate Http";
        CurrHelper: Codeunit "O4N Curr. Exch. Rates Helper";
        UrlTok: label 'https://D365Connect.com/NOK/norges-bank.no/period', Locked = true, MaxLength = 250;
        DescTok: Label 'Downloads missing exchange rates', MaxLength = 100;
        ServiceProviderTok: Label 'https://www.norges-bank.no/en/topics/Statistics/exchange_rates', MaxLength = 250, Locked = true;
        DownloadUrlTok: Label 'https://data.norges-bank.no/api/data/EXR/B..NOK.SP?startPeriod=%1&endPeriod=%2&format=sdmx-json&locale=en', Locked = true;
        UnableToReadBaseCurrencyFromJsonErr: Label 'Unable to read base currency from Json';
}