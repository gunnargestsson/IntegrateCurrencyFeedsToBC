pageextension 73401 "O4N Currencies ISO Extension" extends Currencies
{
    layout
    {
        modify("Code")
        {
            trigger OnAfterValidate()
            var
                TempCurrency: Record Currency temporary;
            begin
                if Rec."Code" = '' then exit;
                CurrencyISOMgt.GetISOList(TempCurrency);
                TempCurrency.SetRange("Code", Rec."Code");
                if TempCurrency.FindFirst() then begin
                    Rec."ISO Code" := TempCurrency."ISO Code";
                    Rec."ISO Numeric Code" := TempCurrency."ISO Numeric Code";
                    if Rec.Description = '' then
                        Rec.Description := TempCurrency.Description;
                end else
                    Message(ISOCodeNotFoundMsg, Rec."ISO Code")
            end;

            trigger OnLookup(var Text: Text): Boolean
            begin
                exit(CurrencyISOMgt.LookupISOList(Rec, Rec.FieldNo("Code"), Text));
            end;

        }
        modify("ISO Code")
        {
            trigger OnAfterValidate()
            var
                TempCurrency: Record Currency temporary;
            begin
                if Rec."ISO Code" = '' then exit;
                CurrencyISOMgt.GetISOList(TempCurrency);
                TempCurrency.SetRange("ISO Code", Rec."ISO Code");
                if TempCurrency.FindFirst() then begin
                    Rec."ISO Numeric Code" := TempCurrency."ISO Numeric Code";
                    if Rec.Description = '' then
                        Rec.Description := TempCurrency.Description;
                end else
                    Message(ISOCodeNotFoundMsg, Rec."ISO Code")
            end;

            trigger OnLookup(var Text: Text): Boolean
            begin
                exit(CurrencyISOMgt.LookupISOList(Rec, Rec.FieldNo("ISO Code"), Text));
            end;
        }
        modify("ISO Numeric Code")
        {
            trigger OnAfterValidate()
            var
                TempCurrency: Record Currency temporary;
            begin
                if Rec."ISO NUmeric Code" = '' then exit;
                CurrencyISOMgt.GetISOList(TempCurrency);
                TempCurrency.SetRange("ISO Numeric Code", DelChr(Rec."ISO Numeric Code", '<', '0'));
                if TempCurrency.FindFirst() then begin
                    Rec."ISO Code" := TempCurrency."ISO Code";
                    if Rec.Description = '' then
                        Rec.Description := TempCurrency.Description;
                end else
                    Message(ISOCodeNotFoundMsg, Rec."ISO Code")
            end;

            trigger OnLookup(var Text: Text): Boolean
            begin
                exit(CurrencyISOMgt.LookupISOList(Rec, Rec.FieldNo("ISO Numeric Code"), Text));
            end;

        }

    }

    actions
    {

    }

    var
        CurrencyISOMgt: Codeunit "O4N Currency ISO Mgt";
        ISOCodeNotFoundMsg: Label 'Currency ISO Code %1 was not found in https://currency-iso.org', Comment = '%1 = Currency ISO Code';

}
