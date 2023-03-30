table 73424 "O4N Setup xe.com"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(2; "Account ID Storage Key"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Account ID Key';
        }
        field(3; "Account API Key Storage Key"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Account API Key Storage Key';
        }
        field(4; "Subscription Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Subscription Id';
        }
        field(5; "Organization"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Organization';
        }
        field(6; "Package"; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Package';
        }
        field(7; "Subscription Start Time"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Subscription Start Time';
        }
        field(8; "Subscription End Time"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Subscription End Time';
        }
        field(9; "Package Limit"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Package Limit';
        }
        field(10; "Package Limit Remaining"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Package Limit Remaining';
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

    procedure VerifyAuthorization()
    begin
        if SecretService.HasSecret("Account ID Storage Key") and SecretService.HasSecret("Account API Key Storage Key") then exit;
        Error(AuthorizationMissingErr, TableCaption());
    end;

    procedure GetBasicAuthorization(): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        UserAuthenticationTok: Label '%1:%2', Locked = true;
        BasicTok: Label 'Basic ', Locked = true;
    begin
        exit(
            BasicTok +
            StrSubstNo(
                Base64Convert.ToBase64(
                    StrSubstNo(UserAuthenticationTok,
                    SecretService.GetSecret("Account ID Storage Key"),
                    SecretService.GetSecret("Account API Key Storage Key")))));
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

    var
        SecretService: Codeunit "O4N Curr. Exch. Rate Secret";
        AuthorizationMissingErr: Label 'Account ID and Account API Key is missing in %1', Comment = '%1 = tablecaption';

}