table 73424 "O4N Setup xe.com"
{
    Caption = 'Setup xe.com';
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Account ID Storage Key"; Guid)
        {
            Caption = 'Account ID Key';
            DataClassification = SystemMetadata;
        }
        field(3; "Account API Key Storage Key"; Guid)
        {
            Caption = 'Account API Key Storage Key';
            DataClassification = SystemMetadata;
        }
        field(4; "Subscription Id"; Guid)
        {
            Caption = 'Subscription Id';
            DataClassification = SystemMetadata;
        }
        field(5; Organization; Text[250])
        {
            Caption = 'Organization';
            DataClassification = SystemMetadata;
        }
        field(6; Package; Code[50])
        {
            Caption = 'Package';
            DataClassification = SystemMetadata;
        }
        field(7; "Subscription Start Time"; DateTime)
        {
            Caption = 'Subscription Start Time';
            DataClassification = SystemMetadata;
        }
        field(8; "Subscription End Time"; DateTime)
        {
            Caption = 'Subscription End Time';
            DataClassification = SystemMetadata;
        }
        field(9; "Package Limit"; Integer)
        {
            Caption = 'Package Limit';
            DataClassification = SystemMetadata;
        }
        field(10; "Package Limit Remaining"; Integer)
        {
            Caption = 'Package Limit Remaining';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
    end;

    trigger OnModify()
    begin
    end;

    trigger OnDelete()
    begin
    end;

    trigger OnRename()
    begin
    end;

    var
        SecretService: Codeunit "O4N Curr. Exch. Rate Secret";
        AuthorizationMissingErr: Label 'Account ID and Account API Key is missing in %1', Comment = '%1 = tablecaption';

    procedure GetAccountInfo()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ErrorTok: Label '%1: %2', Locked = true;
        JSON: Text;
    begin
        Clear("Subscription Id");
        Clear("Subscription Start Time");
        Clear("Subscription End Time");
        Clear(Organization);
        Clear(Package);
        Clear("Package Limit");
        Clear("Package Limit Remaining");
        if not SecretService.HasSecret("Account ID Storage Key") then exit;
        if not SecretService.HasSecret("Account API Key Storage Key") then exit;
        Client.DefaultRequestHeaders.Add('Authorization', GetBasicAuthorization());
        Client.Get('https://xecdapi.xe.com/v1/account_info', Response);
        Response.Content.ReadAs(JSON);
        if Response.IsSuccessStatusCode() then
            ReadAccountInfo(JSON)
        else begin
            ReadMessage(JSON);
            Error(ErrorTok, Response.HttpStatusCode, Response.ReasonPhrase);
        end;
    end;

    procedure GetBasicAuthorization(): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        BasicTok: Label 'Basic ', Locked = true;
        UserAuthenticationTok: Label '%1:%2', Locked = true;
    begin
        exit(
            BasicTok +
            StrSubstNo(
                Base64Convert.ToBase64(
                    StrSubstNo(UserAuthenticationTok,
                    SecretService.GetSecret("Account ID Storage Key"),
                    SecretService.GetSecret("Account API Key Storage Key")))));
    end;

    procedure VerifyAuthorization()
    begin
        if SecretService.HasSecret("Account ID Storage Key") and SecretService.HasSecret("Account API Key Storage Key") then exit;
        Error(AuthorizationMissingErr, TableCaption());
    end;

    local procedure ReadAccountInfo(JSON: Text)
    var
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        JObject.ReadFrom(JSON);
        if JObject.Get('id', JToken) then
            "Subscription Id" := JToken.AsValue().AsText();
        if JObject.Get('organization', JToken) then
            Organization := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Organization));
        if JObject.Get('package', JToken) then
            Package := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Package));
        if JObject.Get('service_start_timestamp', JToken) then
            "Subscription Start Time" := JToken.AsValue().AsDateTime();
        if JObject.Get('service_end_timestamp', JToken) then
            "Subscription End Time" := JToken.AsValue().AsDateTime();
        if JObject.Get('package_limit', JToken) then
            "Package Limit" := JToken.AsValue().AsInteger();
        if JObject.Get('package_limit_remaining', JToken) then
            "Package Limit Remaining" := JToken.AsValue().AsInteger();
    end;

    local procedure ReadMessage(JSON: Text)
    var
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        JObject.ReadFrom(JSON);
        if JObject.Get('message', JToken) then
            Error(JToken.AsValue().AsText());
    end;
}