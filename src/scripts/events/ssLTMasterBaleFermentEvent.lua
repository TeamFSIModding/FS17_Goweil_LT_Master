----------------------------------------------------------------------------------------------------
-- BALE FERMENT EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event when a new silage bale is created and fermentation starts
-- Authors:  reallogger (based on script by baron)
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------
ssLTMasterBaleFermentEvent = {};
ssLTMasterBaleFermentEvent_mt = Class(ssLTMasterBaleFermentEvent, Event);
InitEventClass(ssLTMasterBaleFermentEvent, "ssLTMasterBaleFermentEvent");

function ssLTMasterBaleFermentEvent:emptyNew()
    local self = Event:new(ssLTMasterBaleFermentEvent_mt);
    self.className = "ssLTMasterBaleFermentEvent";
    return self;
end

function ssLTMasterBaleFermentEvent:new(bale)
    local self = ssLTMasterBaleFermentEvent:emptyNew();
    self.bale = bale;
    self.fillType = self.bale:getFillType();
    return self;
end

function ssLTMasterBaleFermentEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.bale));
    streamWriteUIntN(streamId, self.fillType, FillUtil.sendNumBits);
end

function ssLTMasterBaleFermentEvent:readStream(streamId, connection)
    local objectId = streamReadInt32(streamId);
    self.bale = networkGetObject(objectId);
    self.fillType = streamReadUIntN(streamId, FillUtil.sendNumBits);
    self:run(connection);
end

function ssLTMasterBaleFermentEvent:run(connection)
    if self.bale then
        self.bale:setFillType(self.fillType);
    end
end

function ssLTMasterBaleFermentEvent:sendEvent(bale)
    if g_server ~= nil then
        g_server:broadcastEvent(ssLTMasterBaleFermentEvent:new(bale), nil, nil, bale);
    end
end
