--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--19/04/2017
BaleSlideStatusEvent = {};
BaleSlideStatusEvent_mt = Class(BaleSlideStatusEvent, Event);
InitEventClass(BaleSlideStatusEvent, "BaleSlideStatusEvent");

function BaleSlideStatusEvent:emptyNew()
    local self = Event:new(BaleSlideStatusEvent_mt);
    return self;
end

function BaleSlideStatusEvent:new(vehicle, status)
    local self = BaleSlideStatusEvent:emptyNew();
    self.status = status;
    self.vehicle = vehicle;
    return self;
end

function BaleSlideStatusEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.status);
    writeNetworkNodeObject(streamId, self.vehicle);
end

function BaleSlideStatusEvent:readStream(streamId, connection)
    self.status = streamReadUInt8(streamId);
    self.vehicle = readNetworkNodeObject(streamId);
    self:run(connection);
end

function BaleSlideStatusEvent:run(connection)
    if not connection:getIsServer() then
        LTMaster.updateBaleSlideStatus(self.vehicle, self.status);
    else
        LTMaster.eventUpdateBaleSlideStatus(self.vehicle, self.status);
    end
end
