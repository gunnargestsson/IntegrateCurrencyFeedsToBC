codeunit 73405 "O4N Curr. Exch. Rate Http"
{
    trigger OnRun()
    begin

    end;


    procedure ReadInStr(var InStr: InStream; var ResponseXml: XmlDocument)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        ReadInStr(InStr, TempBlob);
        TempBlob.CreateInStream(InStr);
        XmlDocument.ReadFrom(InStr, ResponseXml);
    end;

    procedure ReadInStr(var InStr: InStream; var ResponseJson: JsonObject)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        ReadInStr(InStr, TempBlob);
        TempBlob.CreateInStream(InStr);
        ResponseJson.ReadFrom(InStr);
    end;

    procedure ReadInStr(var InStr: InStream; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    procedure CreateInStream(var InStr: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
    end;

    procedure ThrowError(var Response: HttpResponseMessage)
    var
        ErrorTok: Label 'Web Request Error.\Status Code: %1\Status Message: %2\Content: %3', Comment = '%1 = status Code, %2 = Status Message, %3 = Response content';
        ResponseContent: Text;
    begin
        Response.Content.ReadAs(ResponseContent);
        if not Response.IsSuccessStatusCode then
            Error(ErrorTok, Response.HttpStatusCode, Response.ReasonPhrase, ResponseContent);
    end;
}