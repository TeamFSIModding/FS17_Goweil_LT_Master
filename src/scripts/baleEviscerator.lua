--
--Goweil LT Master
--
--fcelsa (Team FSI Modding)
--
--10/05/2017
BaleEviscerator = {};
BaleEviscerator.baleObject = nil;
BaleEviscerator.dir = g_currentModDirectory;

function BaleEviscerator:loadMap(name)
    self.eviscerateSample = createSample("eviscerateSample");
    loadSample(self.eviscerateSample, Utils.getFilename("eviscerateSound.wav", self.dir .. "sounds/"), false);
    self.eviHud = HudImage:new("cutterHud", self.dir .. "hud/cutter.dds", 0.456, 0.489, 38, 38);
    self.eviHud:setUVs(GuiUtils.getUVs("0px 0px 128px 128px", {128, 128}));
    self.eviHud:setColor(1, 1, 1, 0.3);
    self.eviHud:setIsVisible(false, true);
end

function BaleEviscerator:deleteMap()
    if self.eviscerateSample then
        delete(self.eviscerateSample);
    end
end

function BaleEviscerator:keyEvent(unicode, sym, modifier, isDown)
end

function BaleEviscerator:mouseEvent(posX, posY, isDown, isUp, button)
end

function BaleEviscerator:update(dt)
    if not g_currentMission.missionDynamicInfo.isMultiplayer then
        self.baleObject = nil;
        self.eviHud:setIsVisible(false, true);
        if g_currentMission.player ~= nil and g_currentMission.controlledVehicle == nil and g_currentMission.player.lastFoundBale ~= nil and g_currentMission.player.currentToolId == 0 then
            self.baleObject = g_currentMission.player.lastFoundBale;
            self.eviHud:setIsVisible(true, true);
        end
        if self.baleObject ~= nil then
            g_currentMission:addHelpButtonText(g_i18n:getText("input_EVIBALE"), InputBinding.ACTIVATE_OBJECT, nil, GS_PRIO_VERY_HIGH);
            if InputBinding.hasEvent(InputBinding.ACTIVATE_OBJECT) then
                BaleEvisceratorEvent:sendEvent(self.baleObject);
                self:evisceratesBale(self.baleObject, true);
            end
        end
    end
end

function BaleEviscerator:updateTick(dt)
end

function BaleEviscerator:draw()
end

function BaleEviscerator:evisceratesBale(baleObject, isLocal)
    
    local delta = self.baleObject.fillLevel;
    local fillType = self.baleObject.fillType;
    local x, y, z = getWorldTranslation(self.baleObject.nodeId);
    local xzRndm = ((math.random(1, 20)) - 10) / 10;
    local xOffset = math.max(math.min(xzRndm, 0.3), -0.3);
    local zOffset = math.max(math.min(xzRndm, 0.8), -0.1);
    local ex = x + xOffset;
    local ey = y - 0.1;
    local ez = z + zOffset;
    local innerRadius = 0;
    local outerRadius = TipUtil.getDefaultMaxRadius(fillType);
    local levelerNode = 1;
    local valueOk, droppedToLine = TipUtil.tipToGroundAroundLine(nil,
        delta,
        fillType,
        x,
        y,
        z,
        ex,
        ey,
        ez,
        innerRadius,
        outerRadius,
        levelerNode,
        false, nil, false);
    
    baleObject:setFillLevel(baleObject:getFillLevel() - valueOk);
    
    if isLocal and valueOk > 0 then
        playSample(self.eviscerateSample, 1, 1, 0);
    end
    
    if g_currentMission:getIsServer() then
        if baleObject:getFillLevel() <= TipUtil.getMinValidLiterValue(fillType) then
            baleObject:delete();
        end
    end
end

addModEventListener(BaleEviscerator);

BaleEvisceratorEvent = {};
BaleEvisceratorEvent_mt = Class(BaleEvisceratorEvent, Event);
InitEventClass(BaleEvisceratorEvent, "BaleEvisceratorEvent");

function BaleEvisceratorEvent:emptyNew()
    local self = Event:new(BaleEvisceratorEvent_mt);
    return self;
end

function BaleEvisceratorEvent:new(bale)
    local self = BaleEvisceratorEvent:emptyNew()
    self.baleServerId = networkGetObjectId(bale);
    return self;
end

function BaleEvisceratorEvent:writeStream(streamId, connection)
    writeNetworkNodeObjectId(streamId, self.baleServerId);
end

function BaleEvisceratorEvent:readStream(streamId, connection)
    self.baleServerId = readNetworkNodeObjectId(streamId);
    self:run(connection);
end

function BaleEvisceratorEvent:run(connection)
    local bale = networkGetObject(self.baleServerId);
    if not connection:getIsServer() then
        g_server:broadcastEvent(BaleEvisceratorEvent:new(bale), false, connection);
    end
    BaleEviscerator:evisceratesBale(bale, false);
end

function BaleEvisceratorEvent:sendEvent(bale)
    local event = BaleEvisceratorEvent:new(bale);
    if g_currentMission:getIsServer() then
        g_server:broadcastEvent(event, false);
    else
        g_client:getServerConnection():sendEvent(event);
    end
end
