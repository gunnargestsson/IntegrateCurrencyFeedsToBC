codeunit 93550 "O4N Curr. Exch. Rate Library"
{

    EventSubscriberInstance = Manual;

    var
        GlobalRequest: HttpRequestMessage;
        GlobalResponse: HttpResponseMessage;
        HasResponse: Boolean;

    procedure SetResponse(var Response: HttpResponseMessage)
    begin
        GlobalResponse := Response;
        HasResponse := true;
    end;

    procedure GetRequest(var Request: HttpRequestMessage)
    begin
        Request := GlobalRequest;
    end;

    procedure GetRiksbankseLatestXmlRequest() Xml: Text
    begin
        Exit('<?xml version="1.0" encoding="utf-8" standalone="yes"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsd="http://swea.riksbank.se/xsd"><soap:Header /><soap:Body><xsd:getLatestInterestAndExchangeRates><languageid>en</languageid><seriesid>SEKAUDPMI</seriesid><seriesid>SEKCADPMI</seriesid><seriesid>SEKDKKPMI</seriesid><seriesid>SEKEURPMI</seriesid></xsd:getLatestInterestAndExchangeRates></soap:Body></soap:Envelope>');
    end;

    procedure GetRiksbankseLatestXmlResponse() Xml: Text
    begin
        Exit('<?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope"><SOAP-ENV:Body><ns0:getLatestInterestAndExchangeRatesResponse xmlns:ns0="http://swea.riksbank.se/xsd"><return xmlns=""><groups xmlns=""><groupid xmlns="">130</groupid><groupname xmlns="">Currencies against Swedish kronor</groupname><series xmlns=""><seriesid xmlns="">SEKAUDPMI</seriesid><seriesname xmlns="">1 AUD</seriesname><unit xmlns="">1.0E0</unit><resultrows xmlns=""><date xmlns="">2020-09-29</date><value xmlns="">6.4046E0</value></resultrows></series><series xmlns=""><seriesid xmlns="">SEKCADPMI</seriesid><seriesname xmlns="">1 CAD</seriesname><unit xmlns="">1.0E0</unit><resultrows xmlns=""><date xmlns="">2020-09-29</date><value xmlns="">6.7564E0</value></resultrows></series><series xmlns=""><seriesid xmlns="">SEKDKKPMI</seriesid><seriesname xmlns="">100 DKK</seriesname><unit xmlns="">1.0E2</unit><resultrows xmlns=""><date xmlns="">2020-09-29</date><value xmlns="">1.417817E2</value></resultrows></series><series xmlns=""><seriesid xmlns="">SEKEURPMI</seriesid><seriesname xmlns="">1 EUR</seriesname><unit xmlns="">1.0E0</unit><resultrows xmlns=""><date xmlns="">2020-09-29</date><value xmlns="">1.05553E1            </value></resultrows></series></groups></return></ns0:getLatestInterestAndExchangeRatesResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O4N Curr. Exch. Rates Helper", 'OnBeforeClientSend', '', false, false)]
    local procedure RiksbankSELatestOnBeforeClientSend(var Request: HttpRequestMessage; var Response: HttpResponseMessage; var IsHandled: Boolean)
    begin
        GlobalRequest := Request;
        Response := GlobalResponse;
        IsHandled := true or HasResponse;
    end;

}
