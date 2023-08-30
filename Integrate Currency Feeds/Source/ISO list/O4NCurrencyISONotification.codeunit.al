codeunit 73408 "O4N Currency ISO Notification"
{
    var
        ActionTxt: Label 'Fix now';
        CurrenciesUpdatedMsg: Label 'All currencies have been updated with the required ISO Code';
        IgnoreTxt: Label 'Ignore';
        NotificationIDLbl: Label 'c536b578-c36f-4cce-a5e6-c6a187171231', Locked = true;
        NotificationMsg: Label 'ISO Code is missing on one or more currencies';

    procedure CurrencyISONotificationCode(): Code[50]
    begin
        exit(UpperCase('CurrencyISONotification'));
    end;

    procedure DisableMessageForCurrentUser(InstructionType: Code[50])
    var
        UserPreference: Record "User Preference";
    begin
        UserPreference.DisableInstruction(InstructionType);
    end;

    procedure DontShowAgain(myNotification: Notification)
    begin
        DisableMessageForCurrentUser(CurrencyISONotificationCode());
    end;

    procedure IsEnabled(InstructionType: Code[50]): Boolean
    var
        UserPreference: Record "User Preference";
    begin
        exit(not UserPreference.Get(UserId, InstructionType));
    end;

    procedure PopulateISOCodes(myNotification: Notification)
    var
        Currency: Record Currency;
        TempCurrency: Record Currency temporary;
        CurrencyISOMgt: Codeunit "O4N Currency ISO Mgt";
    begin
        CurrencyISOMgt.GetISOList(TempCurrency);
        Currency.SetRange("ISO Code", '');
        if Currency.FindSet(true) then
            repeat
                if TempCurrency.Get(Currency.Code) then begin
                    Currency."ISO Code" := TempCurrency."ISO Code";
                    Currency."ISO Numeric Code" := TempCurrency."ISO Numeric Code";
                    if Currency.Description = '' then
                        Currency.Description := TempCurrency.Description;
                    Currency.Modify();
                end;
            until Currency.Next() = 0;
        Commit();
        if Currency.IsEmpty() then
            Message(CurrenciesUpdatedMsg)
        else
            Page.RunModal(Page::Currencies, Currency);
    end;

    local procedure RecallNotification()
    var
        CompanyInfoNotification: Notification;
    begin
        CompanyInfoNotification.Id := NotificationIDLbl;
        CompanyInfoNotification.Recall();
    end;

    local procedure SendNotification()
    var
        myNotification: Notification;
    begin
        myNotification.Id := NotificationIDLbl;
        myNotification.Message := NotificationMsg;
        myNotification.Scope := NotificationScope::LocalScope;
        myNotification.AddAction(ActionTxt, Codeunit::"O4N Currency ISO Notification", 'PopulateISOCodes');
        myNotification.AddAction(IgnoreTxt, Codeunit::"O4N Currency ISO Notification", 'DontShowAgain');
        myNotification.Send();
    end;

    local procedure SendOrRecallNotification()
    var
        Rec: Record Currency;
    begin
        if not IsEnabled(CurrencyISONotificationCode()) then exit;
        Rec.SetRange("ISO Code", '');
        if not Rec.IsEmpty() then
            SendNotification()
        else
            RecallNotification();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Curr. Exch. Rate Service Card", 'OnOpenPageEvent', '', false, false)]
    local procedure SendNotificationOnEvent()
    begin
        SendOrRecallNotification();
    end;
}