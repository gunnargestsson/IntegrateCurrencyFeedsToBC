codeunit 93557 "O4N Cache Handler"
{
    EventSubscriberInstance = Manual;

    var
        StoredCacheUrl: Text[250];

    internal procedure SetCacheUrl(Url: Text[250])
    begin
        StoredCacheUrl := Url;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O4N Currency Exch. Rate Cache", 'OnBeforeStoreInCache', '', false, false)]
    local procedure OnBeforeStoreInCache(var TempBuffer: Record "O4N Currency Buffer"; var CacheUrl: Text[250]; var IsHandled: Boolean)
    begin
        if StoredCacheUrl = '' then exit;
        CacheUrl := StoredCacheUrl;
        IsHandled := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O4N Currency Exch. Rate Cache", 'OnBeforeIsInCache', '', false, false)]
    local procedure OnBeforeIsInCache(CacheUrl: Text[250]; var InCache: Boolean; var IsHandled: Boolean)
    begin
        InCache := CacheUrl = StoredCacheUrl;
        IsHandled := true;
    end;

}
