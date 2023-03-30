xmlport 73400 "O4N Currency Exch. Rate Xml"
{
    Caption = 'Currency Exch. Rate Xml';
    Direction = Export;
    Encoding = UTF8;
    Format = Xml;
    PreserveWhiteSpace = true;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Currencies)
        {
            tableelement(Currency; "Currency Exchange Rate")
            {
                UseTemporary = true;
                fieldelement(CurrencyCode; Currency."Currency Code")
                {
                }
                fieldelement(StartingDate; Currency."Starting Date")
                {
                }
                fieldelement(ExchangeRateAmount; Currency."Exchange Rate Amount")
                {
                }
                fieldelement(RelationalExchRateAmount; Currency."Relational Exch. Rate Amount")
                {
                }
            }
        }
    }

    /// <summary> 
    /// Set the currency exchange rate temporary data for the XmlPort
    /// </summary>
    /// <param name="CurrencyExchangeRate">Temporary instance of type Record "Currency Exchange Rate".</param>
    procedure Set(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        Currency.Copy(CurrencyExchangeRate, true);
    end;
}
