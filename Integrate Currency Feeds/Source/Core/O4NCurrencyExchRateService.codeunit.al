codeunit 73400 "O4N Currency.Exch.Rate Service"
{
    Permissions = tabledata "O4N Curr. Exch. Rate Service" = m;

    local procedure CleanUrl(ServiceUrl: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(DelChr(ServiceUrl, '>', TypeHelper.NewLine()));
    end;

    /// <summary>
    /// Description for ExecuteService.
    /// </summary>
    /// <param name="CurrencyExchangeRateService">Parameter of type Record "O4N Curr. Exch. Rate Service".</param>
    /// <param name="ServiceURL">Parameter of type Text.</param>
    local procedure ExecuteService(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service"; var ServiceURL: Text)
    var
        TempBuffer: Record "O4N Currency Buffer" temporary;
        CacheMgt: Codeunit "O4N Currency Exch. Rate Cache";
    begin
        OnBeforeExecuteService(CurrencyExchangeRateService, ServiceURL);

        CurrencyExchangeRateService.TestField("Codeunit Id");
        CurrExchRateUpdateSetup.CalcFields("O4N Currency Filter");
        TempBuffer."Currency Filter" := CurrExchRateUpdateSetup."O4N Currency Filter";
        TempBuffer."Get Structure" := true;
        TempBuffer.Insert(true);
        Codeunit.Run(CurrencyExchangeRateService."Codeunit Id", TempBuffer);
        CurrencyExchangeRateService."Cache Url" := CacheMgt.StoreInCache(TempBuffer);
        CurrencyExchangeRateService.Modify();
        ServiceURL := CurrencyExchangeRateService."Cache Url";

        OnAfterExecuteService(CurrencyExchangeRateService, ServiceURL);
    end;

    /// <summary>
    /// Description for GetWebServiceUrl.
    /// </summary>
    /// <param name="CurrExchRateUpdateSetup">Parameter of type Record "Curr. Exch. Rate Update Setup".</param>
    local procedure GetWebServiceUrl(CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup") ServiceURL: Text
    var
        InStr: InStream;
    begin
        CurrExchRateUpdateSetup.CalcFields("Web Service URL");
        if CurrExchRateUpdateSetup."Web Service URL".HasValue then begin
            CurrExchRateUpdateSetup."Web Service URL".CreateInStream(InStr);
            InStr.Read(ServiceURL);
        end;
    end;

    /// <summary>
    /// Description for ReUserService.
    /// </summary>
    /// <param name="CurrencyExchangeRateService">Parameter of type Record "O4N Curr. Exch. Rate Service".</param>
    /// <param name="ServiceURL">Parameter of type Text.</param>
    /// <returns>Return variable "Boolean".</returns>
    local procedure ReUserService(CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service"; var ServiceURL: Text) ReUserService: Boolean
    var
        CacheMgt: Codeunit "O4N Currency Exch. Rate Cache";
        IsHandled: Boolean;
    begin
        OnBeforeReUserService(CurrencyExchangeRateService, ServiceURL, ReUserService, IsHandled);
        if IsHandled then exit;
        if CurrencyExchangeRateService."Cache Url" = '' then exit(false);
        if not CacheMgt.IsInCache(CurrencyExchangeRateService."Cache Url") then exit(false);
        ServiceURL := CurrencyExchangeRateService."Cache Url";
        exit(true);
    end;

    /// <summary>
    /// Description for UpdateFieldMapping.
    /// </summary>
    /// <param name="CurrExchRateUpdateSetup">Parameter of type Record "Curr. Exch. Rate Update Setup".</param>
    local procedure UpdateFieldMapping(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    var
        DataExchColDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        OnBeforeUpdateFieldMapping(CurrExchRateUpdateSetup);

        DataExchLineDef.SetRange("Data Exch. Def Code", CurrExchRateUpdateSetup."Data Exch. Def Code");
        DataExchLineDef.FindFirst();
        if DataExchLineDef."Data Line Tag" <> '' then exit;
        DataExchLineDef.ModifyAll("Data Line Tag", '/Currencies/Currency');
        DataExchColDef.SetRange("Data Exch. Def Code", CurrExchRateUpdateSetup."Data Exch. Def Code");
        DataExchColDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColDef.SetRange("Column No.", 20000);
        DataExchColDef.ModifyAll(Path, '/Currencies/Currency/CurrencyCode');
        DataExchColDef.SetRange("Column No.", 30000);
        DataExchColDef.ModifyAll(Path, '/Currencies/Currency/StartingDate');
        DataExchColDef.SetRange("Column No.", 40000);
        DataExchColDef.ModifyAll(Path, '/Currencies/Currency/ExchangeRateAmount');
        DataExchColDef.SetRange("Column No.", 50000);
        DataExchColDef.ModifyAll(Path, '/Currencies/Currency/RelationalExchRateAmount');

        OnAfterUpdateFieldMapping(CurrExchRateUpdateSetup);
    end;

    local procedure VerifyUrl(var ServiceUrl: Text) Verified: Boolean
    var
        FileMgt: Codeunit "File Management";
        RequestMgt: Codeunit "Http Web Request Mgt.";
        Client: HttpClient;
        Response: HttpResponseMessage;
        UnableToVerifyUrlTok: Label 'Unable to verify access to the Url: %1', Comment = '%1 = Service Url';
    begin
        if ServiceUrl = '' then exit(true);
        if not RequestMgt.CheckUrl(ServiceUrl) then
            Verified := FileMgt.ServerFileExists(ServiceUrl)
        else
            Verified := Client.Get(ServiceUrl, Response);

        if Verified then exit;
        Message(UnableToVerifyUrlTok, ServiceUrl);
        ServiceUrl := '';
    end;

    /// <summary>
    /// Description for OnAfterGetWebServiceURL.
    /// </summary>
    /// <param name="sender">Parameter of type Record "Curr. Exch. Rate Update Setup".</param>
    /// <param name="ServiceURL">Parameter of type Text.</param>
    [EventSubscriber(ObjectType::Table, Database::"Curr. Exch. Rate Update Setup", 'OnAfterGetWebServiceURL', '', false, false)]
    local procedure OnAfterGetWebServiceURL(var sender: Record "Curr. Exch. Rate Update Setup"; var ServiceURL: Text)
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
    begin
        ServiceURL := CleanUrl(ServiceURL);
        if not CurrencyExchangeRateService.Get(CopyStr(ServiceURL, 1, MaxStrLen(CurrencyExchangeRateService.Url))) then begin
            VerifyUrl(ServiceURL);
            exit;
        end;
        if not ReUserService(CurrencyExchangeRateService, ServiceURL) then
            ExecuteService(sender, CurrencyExchangeRateService, ServiceURL);
        UpdateFieldMapping(sender);
    end;

    /// <summary>
    /// Description for OnBeforeGetCurrencyExchangeData.
    /// </summary>
    /// <param name="CurrExchRateUpdateSetup">Parameter of type Record "Curr. Exch. Rate Update Setup".</param>
    /// <param name="ResponseInStream">Parameter of type InStream.</param>
    /// <param name="SourceName">Parameter of type Text.</param>
    /// <param name="Handled">Parameter of type Boolean.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Update Currency Exchange Rates", 'OnBeforeGetCurrencyExchangeData', '', false, false)]
    local procedure OnBeforeGetCurrencyExchangeData(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; var ResponseInStream: InStream; var SourceName: Text; var Handled: Boolean)
    var
        CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service";
        TempBuffer: Record "O4N Currency Buffer" temporary;
        ServiceURL: Text;
    begin
        ServiceURL := GetWebServiceUrl(CurrExchRateUpdateSetup);

        if not CurrencyExchangeRateService.Get(CopyStr(ServiceURL, 1, MaxStrLen(CurrencyExchangeRateService.Url))) then exit;
        CurrExchRateUpdateSetup.CalcFields("O4N Currency Filter");
        TempBuffer."Currency Filter" := CurrExchRateUpdateSetup."O4N Currency Filter";
        TempBuffer.Insert(true);
        Codeunit.Run(CurrencyExchangeRateService."Codeunit Id", TempBuffer);
        TempBuffer.GetContent(ResponseInStream);
        SourceName := CurrencyExchangeRateService.Description;
        Handled := true;
    end;

    /// <summary>
    /// Description for OnAfterExecuteService.
    /// </summary>
    /// <param name="CurrencyExchangeRateService">Parameter of type Record "O4N Curr. Exch. Rate Service".</param>
    /// <param name="ServiceURL">Parameter of type Text.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterExecuteService(var CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service"; var ServiceURL: Text)
    begin
    end;

    /// <summary>
    /// Description for OnAfterUpdateFieldMapping.
    /// </summary>
    /// <param name="CurrExchRateUpdateSetup">Parameter of type Record "Curr. Exch. Rate Update Setup".</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateFieldMapping(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    begin
    end;

    /// <summary>
    /// Description for OnBeforeExecuteService.
    /// </summary>
    /// <param name="CurrencyExchangeRateService">Parameter of type Record "O4N Curr. Exch. Rate Service".</param>
    /// <param name="ServiceURL">Parameter of type Text.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeExecuteService(var CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service"; var ServiceURL: Text)
    begin
    end;

    /// <summary>
    /// Description for OnBeforeReUserService.
    /// </summary>
    /// <param name="CurrencyExchangeRateService">Parameter of type Record "O4N Curr. Exch. Rate Service".</param>
    /// <param name="ServiceURL">Parameter of type Text.</param>
    /// <param name="ReUserService">Parameter of type Boolean.</param>
    /// <param name="Handler">Parameter of type Boolean.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReUserService(CurrencyExchangeRateService: Record "O4N Curr. Exch. Rate Service"; var ServiceURL: Text; var ReUserService: Boolean; var Handler: Boolean)
    begin
    end;

    /// <summary>
    /// Description for OnBeforeUpdateFieldMapping.
    /// </summary>
    /// <param name="CurrExchRateUpdateSetup">Parameter of type Record "Curr. Exch. Rate Update Setup".</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFieldMapping(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    begin
    end;
}
