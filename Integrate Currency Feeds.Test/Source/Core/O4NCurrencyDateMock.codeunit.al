codeunit 93554 "O4N Currency Date Mock"
{
    EventSubscriberInstance = Manual;

    procedure SetDates(Url: Text; StartDate: Date; EndDate: Date)
    begin
        GlobalUrl := Url;
        GlobalStartDate := StartDate;
        GlobalEndDate := EndDate;
    end;

    procedure GetDates(var StartDate: Date; var EndDate: Date)
    begin
        StartDate := GlobalStartDate;
        EndDate := GlobalEndDate;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O4N Currency Date Mgt.", 'OnAfterFindStartDate', '', false, false)]
    local procedure OnAfterFindStartDate(Url: Text; var StartDate: Date)
    begin
        if Url = GlobalUrl then
            StartDate := GlobalStartDate;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O4N Currency Date Mgt.", 'OnAfterFindEndDate', '', false, false)]
    local procedure OnAfterFindEndDate(Url: Text; StartDate: Date; var EndDate: Date)
    begin
        if Url = GlobalUrl then
            EndDate := GlobalEndDate;
    end;

    var
        GlobalUrl: Text;
        GlobalStartDate: Date;
        GlobalEndDate: Date;
}