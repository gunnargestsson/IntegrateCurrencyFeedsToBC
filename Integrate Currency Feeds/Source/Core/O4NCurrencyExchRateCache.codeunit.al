codeunit 73401 "O4N Currency Exch. Rate Cache"
{
    var
        CacheErr: Label 'Unable to use D365 Connect Cache Service.  Please try again in a moment.';

    [NonDebuggable]
    procedure StoreInCache(var TempBuffer: Record "O4N Currency Buffer") CacheUrl: Text[250]
    var
        JObject: JsonObject;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: Text;
    begin
        JObject.Add('Xml', TempBuffer.ReadAsText());
        JObject.WriteTo(Content);
        Request.Content.WriteFrom(Content);
        Request.SetRequestUri('https://d365services4bc.azurewebsites.net/api/StoreInCache?code=<AuthorizationCode>');
        Request.Method('POST');
        if not Client.Send(Request, Response) then
            Error(CacheErr);
        if not Response.IsSuccessStatusCode() then
            Error(CacheErr);
        Response.Content.ReadAs(Content);
        CacheUrl := CopyStr(Content, 1, MaxStrLen(CacheUrl));
    end;

    [NonDebuggable]
    procedure IsInCache(CacheUrl: Text[250]): Boolean
    var
        RequestMgt: Codeunit "Http Web Request Mgt.";
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if CacheUrl = '' then exit(false);
        if not RequestMgt.CheckUrl(CacheUrl) then exit(false);
        if not Client.Get(CacheUrl, Response) then exit(false);
        exit(Response.IsSuccessStatusCode());
    end;


}