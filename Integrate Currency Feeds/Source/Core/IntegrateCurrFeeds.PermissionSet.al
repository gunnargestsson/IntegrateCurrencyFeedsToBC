permissionset 73400 IntegrateCurrFeeds
{
    Assignable = true;
    Caption = 'Integrate Currency Feeds', MaxLength = 30;
    Permissions =
        table "O4N Connect Exch. Rate Setup" = X,
        tabledata "O4N Connect Exch. Rate Setup" = RMID,
        table "O4N Currency Buffer" = X,
        tabledata "O4N Currency Buffer" = RMID,
        table "O4N Curr. Exch. Rate Service" = X,
        tabledata "O4N Curr. Exch. Rate Service" = RMID,
        table "O4N Setup fixer.io" = X,
        tabledata "O4N Setup fixer.io" = RMID,
        table "O4N Sedlabanki.is Setup" = X,
        tabledata "O4N Sedlabanki.is Setup" = RMID,
        table "O4N tcmb.gov.tr Setup" = X,
        tabledata "O4N tcmb.gov.tr Setup" = RMID,
        table "O4N Setup xe.com" = X,
        tabledata "O4N Setup xe.com" = RMID,
        codeunit "O4N Currency Conversion" = X,
        codeunit "O4N Currency Date Mgt." = X,
        codeunit "O4N Currency Exch. Rate Event" = X,
        codeunit "O4N Currency.Exch.Rate Service" = X,
        codeunit "O4N Currency Filter Mgt." = X,
        codeunit "O4N Currency Overwrite Mgt." = X,
        codeunit "O4N Curr. Exch. Rate Http" = X,
        codeunit "O4N Curr. Exch. Rate Secret" = X,
        codeunit "O4N Curr. Exch. Rates Helper" = X,
        codeunit "O4N Curr. Exch. Rate Serv Inst" = X,
        codeunit "O4N Curr. Exch. Rate Serv Stp" = X,
        codeunit "O4N Curr. Exch. Rate Serv Upg" = X,
        codeunit "O4N Currency ISO Mgt" = X,
        codeunit "O4N Currency ISO Notification" = X,
        codeunit "O4N ecb.europa.eu 90Days" = X,
        codeunit "O4N ecb.europa.eu Latest" = X,
        codeunit "O4N fixer.io Period" = X,
        codeunit "O4N Nationalbanken.dk 5Days" = X,
        codeunit "O4N Nationalbanken.dk Latest" = X,
        codeunit "O4N norges-bank.no Period" = X,
        codeunit "O4N Riksbank.se Latest" = X,
        codeunit "O4N Riksbank.se Period" = X,
        codeunit "O4N Sedlabanki.is Period" = X,
        codeunit "O4N tcmb.gov.tr Latest" = X,
        codeunit "O4N Xe.com Period" = X,
        codeunit "O4N Currency Exch. Rate Cache" = X,
        page "O4N Connect Exch. Rate Setup" = X,
        page "O4N Curr. Exch. Rate Services" = X,
        page "O4N Currency ISO List" = X,
        page "O4N Setup fixer.io" = X,
        page "O4N Sedlabanki.is Setup" = X,
        page "O4N tcmb.gov.tr Setup" = X,
        page "O4N Setup xe.com" = X,
        xmlport "O4N Currency Exch. Rate Xml" = X;
}
