--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--19/04/2017
LadderStatusEvent = {};
LadderStatusEvent_mt = Class(LadderStatusEvent, Event);
InitEventClass(LadderStatusEvent, "LadderStatusEvent");

function LadderStatusEvent:emptyNew()
    local self = Event:new(LadderStatusEvent_mt);
    return self;
end

function LadderStatusEvent:new(vehicle, status)
    local self = LadderStatusEvent:emptyNew();
    self.status = status;
    self.vehicle = vehicle;
    return self;
end

function LadderStatusEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.status);
    writeNetworkNodeObject(streamId, self.vehicle);
end

function LadderStatusEvent:readStream(streamId, connection)
    self.status = streamReadUInt8(streamId);
    self.vehicle = readNetworkNodeObject(streamId);
    self:run(connection);
end

function LadderStatusEvent:run(connection)
    if not connection:getIsServer() then
        LTMaster.updateLadderStatus(self.vehicle, self.status);
    else
        LTMaster.eventUpdateLadderStatus(self.vehicle, self.status);
    end
end
