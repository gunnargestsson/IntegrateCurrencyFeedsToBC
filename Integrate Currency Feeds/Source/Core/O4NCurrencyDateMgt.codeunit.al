codeunit 73403 "O4N Currency Date Mgt."
{

    procedure GetCurrencyPeriod(Url: Text; GetStructure: Boolean; CountryCode: Code[3]; var StartDate: Date; var EndDate: Date)
    begin
        if GetStructure then begin
            StartDate := GetStructureDate(CountryCode);
            EndDate := StartDate;
        end else begin
            StartDate := FindStartDate(Url);
            EndDate := FindEndDate(Url, StartDate);
        end;
    end;

    local procedure GetStructureDate(CountryCode: Code[3]) CurrencyDate: Date
    var
        IsHoliday: Boolean;
    begin
        CurrencyDate := CalcDate('<-1W-CW>', Today());
        if TryGetIsPublicHoliday(CountryCode, CurrencyDate, IsHoliday) then;
        while (Date2DWY(CurrencyDate, 1) >= 6) or (IsHoliday) do begin
            CurrencyDate := CurrencyDate - 3;
            if TryGetIsPublicHoliday(CountryCode, CurrencyDate, IsHoliday) then;
        end;
    end;

    local procedure FindStartDate(Url: Text) StartDate: Date
    var
        Setup: Record "O4N Connect Exch. Rate Setup";
    begin
        if not FindLastCurrencyExchangeRate(StartDate) then
            if not FindFirstGLEntry(StartDate) then
                StartDate := Today();
        Setup.OnAfterFindStartDate(StartDate);
        if StartDate > Today() then
            StartDate := Today();
        OnAfterFindStartDate(Url, StartDate);
    end;

    local procedure FindEndDate(Url: Text; StartDate: Date) EndDate: Date
    begin
        EndDate := Today();
        if EndDate < StartDate then
            EndDate := StartDate;
        OnAfterFindEndDate(Url, StartDate, EndDate);
    end;

    local procedure FindLastCurrencyExchangeRate(var StartDate: Date): Boolean
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if CurrencyExchangeRate.IsEmpty() then exit;
        CurrencyExchangeRate.SetCurrentKey("Starting Date");
        CurrencyExchangeRate.FindLast();
        StartDate := CurrencyExchangeRate."Starting Date";
        exit(true);
    end;

    local procedure FindFirstGLEntry(var StartDate: Date): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.IsEmpty() then exit;
        GLEntry.SetCurrentKey("Posting Date");
        GLEntry.FindFirst();
        StartDate := GLEntry."Posting Date";
        exit(true);
    end;

    [TryFunction]
    local procedure TryGetIsPublicHoliday(CountryCode: Code[3]; CurrencyDate: Date; var IsHoliday: Boolean)
    var
        Client: HttpClient;
        Respose: HttpResponseMessage;
        ResponseText: Text;
        Day: JsonToken;
        IsPublicHoliday: JsonToken;
        UrlTok: Label 'https://kayaposoft.com/enrico/json/v2.0/?action=isPublicHoliday&date=%2&country=%1', Comment = '%1 = Country Code; %2 = Date';
    begin
        Client.Get(StrSubstNo(UrlTok, CountryCode, Format(CurrencyDate, 0, '<Day,2>-<Month,2>-<Year4>')), Respose);
        Respose.Content.ReadAs(ResponseText);
        if not Respose.IsSuccessStatusCode then Error(ResponseText);
        Day.ReadFrom(ResponseText);
        if Day.AsObject().Get('isPublicHoliday', IsPublicHoliday) then
            IsHoliday := IsPublicHoliday.AsValue().AsBoolean();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O4N Curr. Exch. Rates Helper", 'OnBeforeAddCurrencyExchangeRate', '', false, false)]
    local procedure OnBeforeAddCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Setup: Record "O4N Connect Exch. Rate Setup";
    begin
        if not Setup.Get() then exit;
        CurrencyExchangeRate."Starting Date" := CalcDate(Setup."Starting Date Formula", CurrencyExchangeRate."Starting Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindStartDate(Url: Text; var StartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindEndDate(Url: Text; StartDate: Date; var EndDate: Date)
    begin
    end;
}
