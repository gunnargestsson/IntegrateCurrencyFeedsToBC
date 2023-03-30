codeunit 73412 "O4N Curr. Exch. Rate Serv Stp"
{

    procedure SetApiCallsAllowed()
    var
        AppSettings: Record "NAV App Setting";
        CurrentApp: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentApp);
        AppSettings.SetRange("App ID", CurrentApp.Id);
        if AppSettings.IsEmpty() then begin
            AppSettings.Init();
            AppSettings."App ID" := CurrentApp.Id;
            AppSettings."Allow HttpClient Requests" := true;
            AppSettings.Insert(true);
        end else
            AppSettings.ModifyAll("Allow HttpClient Requests", true);
        Commit();
    end;

}