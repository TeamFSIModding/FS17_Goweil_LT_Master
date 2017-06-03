--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--18/04/2017
HoodStatusEvent = {};
HoodStatusEvent_mt = Class(HoodStatusEvent, Event);
InitEventClass(HoodStatusEvent, "HoodStatusEvent");

function HoodStatusEvent:emptyNew()
    local self = Event:new(HoodStatusEvent_mt);
    return self;
end

function HoodStatusEvent:new(vehicle, hood, status)
    local self = HoodStatusEvent:emptyNew();
    self.status = status;
    self.hood = hood;
    self.vehicle = vehicle;
    return self;
end

function HoodStatusEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.status);
    streamWriteString(streamId, self.hood);
    writeNetworkNodeObject(streamId, self.vehicle);
end

function HoodStatusEvent:readStream(streamId, connection)
    self.status = streamReadUInt8(streamId);
    self.hood = streamReadString(streamId);
    self.vehicle = readNetworkNodeObject(streamId);
    self:run(connection);
end

function HoodStatusEvent:run(connection)
    if not connection:getIsServer() then
        LTMaster.updateHoodStatus(self.vehicle, self.vehicle.LTMaster.hoods[self.hood], self.status);
    else
        LTMaster.eventUpdateHoodStatus(self.vehicle, self.hood, self.status);
    end
end
