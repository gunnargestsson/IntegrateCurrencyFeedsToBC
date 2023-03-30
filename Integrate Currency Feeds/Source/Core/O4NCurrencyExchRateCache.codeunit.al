codeunit 73401 "O4N Currency Exch. Rate Cache"
{
    var
        CacheErr: Label 'Unable to use D365 Connect Cache Service.  Please try again in a moment.';

    [NonDebuggable]
    procedure StoreInCache(var TempBuffer: Record "O4N Currency Buffer") CacheUrl: Text[250]
    var
        CacheServiceUrlTok: Label 'CurrencyCacheServiceUrl', Locked = true;
        IsHandled: Boolean;
        JObject: JsonObject;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content, Url : Text;
    begin
        OnBeforeStoreInCache(TempBuffer, CacheUrl, IsHandled);
        if IsHandled then
            exit;

        if not TryGetSecret(CacheServiceUrlTok, Url) then
            Error(CacheErr);

        JObject.Add('Xml', TempBuffer.ReadAsText());
        JObject.WriteTo(Content);
        Request.Content.WriteFrom(Content);
        Request.SetRequestUri(Url);
        Request.Method('POST');
        if not Client.Send(Request, Response) then
            Error(CacheErr);
        if not Response.IsSuccessStatusCode() then
            Error(CacheErr);
        Response.Content.ReadAs(Content);
        CacheUrl := CopyStr(Content, 1, MaxStrLen(CacheUrl));
    end;

    [NonDebuggable]
    procedure IsInCache(CacheUrl: Text[250]) InCache: Boolean
    var
        RequestMgt: Codeunit "Http Web Request Mgt.";
        IsHandled: Boolean;
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        OnBeforeIsInCache(CacheUrl, InCache, IsHandled);
        if IsHandled then
            exit;

        if CacheUrl = '' then exit(false);
        if not RequestMgt.CheckUrl(CacheUrl) then exit(false);
        if not Client.Get(CacheUrl, Response) then exit(false);
        exit(Response.IsSuccessStatusCode());
    end;

    [TryFunction]
    [NonDebuggable]
    procedure TryGetSecret(SecretName: Text; var SecretValue: Text)
    var
        SecretProvider: Codeunit "App Key Vault Secret Provider";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTryGetSecret(SecretName, SecretValue, IsHandled);
        if IsHandled then exit;
        SecretProvider.TryInitializeFromCurrentApp();
        SecretProvider.GetSecret(SecretName, SecretValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryGetSecret(SecretName: Text; var SecretValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStoreInCache(var TempBuffer: Record "O4N Currency Buffer"; var CacheUrl: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsInCache(CacheUrl: Text[250]; var InCache: Boolean; var IsHandled: Boolean)
    begin
    end;


}