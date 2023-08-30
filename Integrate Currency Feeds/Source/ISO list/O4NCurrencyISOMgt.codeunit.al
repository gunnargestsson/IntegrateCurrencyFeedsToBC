codeunit 73407 "O4N Currency ISO Mgt"
{
    trigger OnRun()
    begin
    end;

    var
        TempCurrency: Record Currency temporary;
        NoUniversalCurrencyTok: Label 'No universal currency', Locked = true, MaxLength = 30;
        TemporaryErr: Label 'The record must be temporary.';
        XmlErr: Label 'Unable to read currencies from the xml.';

    procedure GetISOList(var Currency: Record Currency)
    begin
        if not Currency.IsTemporary() then
            Error(TemporaryErr);

        LoadISOList();
        Currency.Copy(TempCurrency, true);
    end;

    procedure LookupISOList(Currency: Record Currency; LookupFieldNo: Integer; var Text: Text): Boolean
    var
        CurrencyISOList: Page "O4N Currency ISO List";
    begin
        LoadISOList();
        TempCurrency := Currency;
        case LookupFieldNo of
            Currency.FieldNo("Code"):
                TempCurrency.SetCurrentKey("Code");
            Currency.FieldNo("ISO Code"):
                TempCurrency.SetCurrentKey("ISO Code");
            Currency.FieldNo("ISO Numeric Code"):
                TempCurrency.SetCurrentKey("ISO Numeric Code");
        end;
        CurrencyISOList.LookupMode(true);
        CurrencyISOList.SetRecord(TempCurrency);
        CurrencyISOList.SetTableView(TempCurrency);
        if CurrencyISOList.RunModal() = Action::LookupOK then begin
            CurrencyISOList.GetRecord(TempCurrency);
            case LookupFieldNo of
                Currency.FieldNo("Code"):
                    Text := TempCurrency.Code;
                Currency.FieldNo("ISO Code"):
                    Text := TempCurrency."ISO Code";
                Currency.FieldNo("ISO Numeric Code"):
                    Text := TempCurrency."ISO Numeric Code";
            end;
            exit(true);
        end
    end;

    local procedure DownloadXml() Doc: XmlDocument
    var
        TempBlob: Codeunit "Temp Blob";
        Client: HttpClient;
        Response: HttpResponseMessage;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Client.Get('https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml', Response);
        Response.Content.ReadAs(InStr);
        XmlDocument.ReadFrom(InStr, Doc);
    end;

    local procedure GetNodeInt(SourceNode: XmlNode; NodeName: Text) NodeValue: Integer
    var
        NodeValueAsText: Text;
    begin
        NodeValueAsText := GetNodeText(SourceNode, NodeName);
        if not Evaluate(NodeValue, NodeValueAsText, 9) then
            NodeValue := 0;
    end;

    local procedure GetNodeText(SourceNode: XmlNode; NodeName: Text) NodeValue: Text
    var
        ValueNode: XmlNode;
    begin
        if not SourceNode.SelectSingleNode(NodeName, ValueNode) then
            Error(XmlErr);
        NodeValue := ValueNode.AsXmlElement().InnerText();
    end;

    local procedure LoadISOList()
    var
        Doc: XmlDocument;
        CcyNtry: XmlNode;
        CcyNtries: XmlNodeList;
    begin
        TempCurrency.Reset();
        if not TempCurrency.IsEmpty() then
            exit;

        Doc := DownloadXml();

        if not Doc.SelectNodes('//*[local-name()="CcyNtry"]', CcyNtries) then
            Error(XmlErr);

        foreach CcyNtry in CcyNtries do
            if CopyStr(GetNodeText(CcyNtry, 'CcyNm'), 1, 30) <> NoUniversalCurrencyTok then
                if not TempCurrency.Get(CopyStr(GetNodeText(CcyNtry, 'Ccy'), 1, MaxStrLen(TempCurrency."Code"))) then begin
                    TempCurrency.Init();
                    TempCurrency.Description := CopyStr(GetNodeText(CcyNtry, 'CcyNm'), 1, MaxStrLen(TempCurrency.Description));
                    TempCurrency."Code" := CopyStr(GetNodeText(CcyNtry, 'Ccy'), 1, MaxStrLen(TempCurrency."Code"));
                    TempCurrency."ISO Code" := CopyStr(GetNodeText(CcyNtry, 'Ccy'), 1, MaxStrLen(TempCurrency."ISO Code"));
                    TempCurrency."ISO Numeric Code" := CopyStr(GetNodeText(CcyNtry, 'CcyNbr'), 1, MaxStrLen(TempCurrency."ISO Numeric Code"));
                    if GetNodeInt(CcyNtry, 'CcyMnrUnts') > 0 then begin
                        TempCurrency."Amount Decimal Places" := CopyStr(GetNodeText(CcyNtry, 'CcyMnrUnts') + ':' + GetNodeText(CcyNtry, 'CcyMnrUnts'), 1, MaxStrLen(TempCurrency."Amount Decimal Places"));
                        TempCurrency."Amount Rounding Precision" := Power(10, -GetNodeInt(CcyNtry, 'CcyMnrUnts'));
                    end;
                    TempCurrency.Insert();
                end;
    end;
}