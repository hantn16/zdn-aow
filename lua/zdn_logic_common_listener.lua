local SubscriberList = {}

function ResolveListener(source, event)
    for i, sub in pairs(SubscriberList) do
        if source == sub.Source and event == sub.Event then
            nx_execute(sub.Subscriber, sub.Callback, sub.Source, unpack(sub.Param))
        end
    end
end

function Subscribe(source, event, subscriber, callback, ...)
    local t = {
        ["Source"] = source,
        ["Event"] = event,
        ["Subscriber"] = subscriber,
        ["Callback"] = callback,
        ["Param"] = arg
    }
    if isListenExists(t) then
        return
    end
    table.insert(SubscriberList, t)
end

function Unsubscribe(source, event, subscriber)
    for i, l in pairs(SubscriberList) do
        if source == l.Source and event == l.Event and subscriber == l.Subscriber then
            table.remove(SubscriberList, i)
        end
    end
end

function isListenExists(t)
    for _, l in pairs(SubscriberList) do
        if t.Source == l.Source and t.Event == l.Event and t.Subscriber == l.Subscriber then
            return true
        end
    end
    return false
end
