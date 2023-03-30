codeunit 93556 O4NECBLibrary
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

    procedure GetECBLatestXmlResponse() Xml: Text
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        Exit(Base64Convert.FromBase64('PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxnZXNtZXM6RW52ZWxvcGUgeG1sbnM6Z2VzbWVzPSJodHRwOi8vd3d3Lmdlc21lcy5vcmcveG1sLzIwMDItMDgtMDEiIHhtbG5zPSJodHRwOi8vd3d3LmVjYi5pbnQvdm9jYWJ1bGFyeS8yMDAyLTA4LTAxL2V1cm9meHJlZiI+DQoJPGdlc21lczpzdWJqZWN0PlJlZmVyZW5jZSByYXRlczwvZ2VzbWVzOnN1YmplY3Q+DQoJPGdlc21lczpTZW5kZXI+DQoJCTxnZXNtZXM6bmFtZT5FdXJvcGVhbiBDZW50cmFsIEJhbms8L2dlc21lczpuYW1lPg0KCTwvZ2VzbWVzOlNlbmRlcj4NCgk8Q3ViZT4NCgkJPEN1YmUgdGltZT0nMjAyMS0xMC0yNic+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nVVNEJyByYXRlPScxLjE2MTgnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdKUFknIHJhdGU9JzEzMi40NycvPg0KCQkJPEN1YmUgY3VycmVuY3k9J0JHTicgcmF0ZT0nMS45NTU4Jy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nQ1pLJyByYXRlPScyNS43MDAnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdES0snIHJhdGU9JzcuNDM5MicvPg0KCQkJPEN1YmUgY3VycmVuY3k9J0dCUCcgcmF0ZT0nMC44NDE3OCcvPg0KCQkJPEN1YmUgY3VycmVuY3k9J0hVRicgcmF0ZT0nMzY1LjI5Jy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nUExOJyByYXRlPSc0LjYwMDknLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdST04nIHJhdGU9JzQuOTQ2OCcvPg0KCQkJPEN1YmUgY3VycmVuY3k9J1NFSycgcmF0ZT0nOS45ODQ4Jy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nQ0hGJyByYXRlPScxLjA2ODQnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdJU0snIHJhdGU9JzE1MC4wMCcvPg0KCQkJPEN1YmUgY3VycmVuY3k9J05PSycgcmF0ZT0nOS42ODI4Jy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nSFJLJyByYXRlPSc3LjUyMjUnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdSVUInIHJhdGU9JzgwLjY0MTcnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdUUlknIHJhdGU9JzEwLjk3NDQnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdBVUQnIHJhdGU9JzEuNTQ2NScvPg0KCQkJPEN1YmUgY3VycmVuY3k9J0JSTCcgcmF0ZT0nNi40NjIwJy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nQ0FEJyByYXRlPScxLjQzNjEnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdDTlknIHJhdGU9JzcuNDEyNCcvPg0KCQkJPEN1YmUgY3VycmVuY3k9J0hLRCcgcmF0ZT0nOS4wMzM1Jy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nSURSJyByYXRlPScxNjQwOC4yNCcvPg0KCQkJPEN1YmUgY3VycmVuY3k9J0lMUycgcmF0ZT0nMy43MTc4Jy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nSU5SJyByYXRlPSc4Ny4wODIwJy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nS1JXJyByYXRlPScxMzU0LjExJy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nTVhOJyByYXRlPScyMy40MDE2Jy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nTVlSJyByYXRlPSc0LjgxNzQnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdOWkQnIHJhdGU9JzEuNjE3MicvPg0KCQkJPEN1YmUgY3VycmVuY3k9J1BIUCcgcmF0ZT0nNTguOTQ3Jy8+DQoJCQk8Q3ViZSBjdXJyZW5jeT0nU0dEJyByYXRlPScxLjU2MzcnLz4NCgkJCTxDdWJlIGN1cnJlbmN5PSdUSEInIHJhdGU9JzM4LjQ1NicvPg0KCQkJPEN1YmUgY3VycmVuY3k9J1pBUicgcmF0ZT0nMTcuMTMwOScvPg0KCQk8L0N1YmU+DQoJPC9DdWJlPg0KPC9nZXNtZXM6RW52ZWxvcGU+'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O4N Curr. Exch. Rates Helper", 'OnBeforeClientSend', '', false, false)]
    local procedure ECBOnBeforeClientSend(var Request: HttpRequestMessage; var Response: HttpResponseMessage; var IsHandled: Boolean)
    begin
        GlobalRequest := Request;
        Response := GlobalResponse;
        IsHandled := true or HasResponse;
    end;
}
