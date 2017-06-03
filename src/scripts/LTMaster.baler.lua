--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--28/04/2017
function LTMaster:loadBaler()
    self.dropBale = LTMaster.dropBale;
    self.createBale = LTMaster.createBale;
    self.setIsBalerUnloadingBale = LTMaster.setIsBalerUnloadingBale;
    self.isUnloadingAllowed = LTMaster.isUnloadingAllowed;
    self.setBaleVolume = LTMaster.setBaleVolume;
    self.getNextVolumesIndex = LTMaster.getNextVolumesIndex;
    self.getCreatedBales = LTMaster.getCreatedBales;
    self.allowPickingUp = Utils.overwrittenFunction(self.allowPickingUp, LTMaster.allowPickingUp);
    
    self.LTMaster.baler = {};
    self.LTMaster.baler.fillScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler#value"), 1);
    self.LTMaster.baler.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler#fillUnitIndex"), 1);
    self.LTMaster.baler.baleAnimRoot, self.LTMaster.baler.baleAnimRootComponent = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#node"));
    if self.LTMaster.baler.baleAnimRoot == nil then
        self.LTMaster.baler.baleAnimRoot = self.components[1].node;
        self.LTMaster.baler.baleAnimRootComponent = self.components[1].node;
    end
    local unloadAnimationName = getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#unloadAnimationName");
    local closeAnimationName = getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#closeAnimationName");
    local unloadAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#unloadAnimationSpeed"), 1);
    local closeAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#closeAnimationSpeed"), 1);
    if unloadAnimationName ~= nil and closeAnimationName ~= nil then
        if self.playAnimation ~= nil and self.animations ~= nil then
            if self.animations[unloadAnimationName] ~= nil and self.animations[closeAnimationName] ~= nil then
                self.LTMaster.baler.baleUnloadAnimationName = unloadAnimationName;
                self.LTMaster.baler.baleUnloadAnimationSpeed = unloadAnimationSpeed;
                self.LTMaster.baler.baleCloseAnimationName = closeAnimationName;
                self.LTMaster.baler.baleCloseAnimationSpeed = closeAnimationSpeed;
                self.LTMaster.baler.baleDropAnimTime = getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#baleDropAnimTime");
                if self.LTMaster.baler.baleDropAnimTime == nil then
                    self.LTMaster.baler.baleDropAnimTime = self:getAnimationDuration(self.LTMaster.baler.baleUnloadAnimationName);
                else
                    self.LTMaster.baler.baleDropAnimTime = self.LTMaster.baler.baleDropAnimTime * 1000;
                end
            else
                print("Error: Failed to find unload animations '" .. unloadAnimationName .. "' and '" .. closeAnimationName .. "' in '" .. self.configFileName .. "'.");
            end
        else
            print("Error: There is an unload animation in '" .. self.configFileName .. "' but it is not a AnimatedVehicle. Change to a vehicle type which has the AnimatedVehicle specialization.");
        end
    end
    self.LTMaster.baler.baleTypes = {};
    local i = 0
    while true do
        local key = string.format("vehicle.LTMaster.baler.baleTypes.baleType(%d)", i);
        if not hasXMLProperty(self.xmlFile, key) then
            break;
        end
        local width = Utils.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#width"), 1.2), 2);
        local diameter = Utils.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#diameter"), 1.8), 2);
        table.insert(self.LTMaster.baler.baleTypes, {isRoundBale = true, width = width, height = 0.9, length = 2.4, diameter = diameter});
        i = i + 1;
    end
    self.LTMaster.baler.currentBaleTypeId = 1;
    if table.getn(self.LTMaster.baler.baleTypes) == 0 then
        self.LTMaster.baler.baleTypes = nil;
    end
    if self.isClient then
        self.LTMaster.baler.sampleBaler = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.balerSound", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.baler.sampleBalerIdle = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.balerIdleSound", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.baler.sampleBalerEject = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.balerBaleEject", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.baler.sampleBalerDoor = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.balerDoor", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.baler.sampleKnotting = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.knottingSound", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.baler.sampleOutOfNet = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.outOfNetSound", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.baler.uvScrollParts = Utils.loadScrollers(self.components, self.xmlFile, "vehicle.LTMaster.baler.uvScrollParts.uvScrollPart", {}, false);
        self.LTMaster.baler.workingRotatingParts = Utils.loadRotationNodes(self.xmlFile, {}, "vehicle.LTMaster.baler.rotatingParts.rotatingPart", "LTMaster.baler", self.components);
        self.LTMaster.baler.knottingAnimation = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.LTMaster.baler.knottingAnimation#name"), "");
        self.LTMaster.baler.knottingAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.knottingAnimation#speed"), 1);
        self.LTMaster.baler.knottingScrollParts = Utils.loadScrollers(self.components, self.xmlFile, "vehicle.LTMaster.baler.knottingScrollParts.uvScrollPart", {}, false);
        self.LTMaster.baler.knottingRotatingParts = Utils.loadRotationNodes(self.xmlFile, {}, "vehicle.LTMaster.baler.knottingRotatingParts.rotatingPart", "LTMaster.baler", self.components);
        self.LTMaster.baler.balingAnimationName = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.LTMaster.balingAnimation#name"), "");
    end
    self.LTMaster.baler.unloadingState = Baler.UNLOADING_CLOSED;
    self.LTMaster.baler.bales = {};
    self.LTMaster.baler.dummyBale = {}
    self.LTMaster.baler.dummyBale.scaleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#scaleNode"));
    self.LTMaster.baler.dummyBale.baleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#baleNode"));
    self.LTMaster.baler.dummyBale.currentBaleFillType = FillUtil.FILLTYPE_UNKNOWN;
    self.LTMaster.baler.dummyBale.currentBale = nil;
    self.LTMaster.baler.knottingTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler#knottingTime"), 0) * 1000;
    self.LTMaster.baler.autoUnloadTime = nil;
    self.LTMaster.baler.isWorking = false;
    
    self.LTMaster.baler.baleVolumes = {};
    self.LTMaster.baler.lowerVolume = 1000000;
    self.LTMaster.baler.baleVolumesIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler.baleVolumes#defaultVolumeIndex"), 1);
    local i = 0;
    while true do
        local key = string.format("vehicle.LTMaster.baler.baleVolumes.volume(%d)", i);
        if not hasXMLProperty(self.xmlFile, key) then
            break;
        end
        local liters = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#liters"), 4000);
        if liters < self.LTMaster.baler.lowerVolume then
            self.LTMaster.baler.lowerVolume = liters;
        end
        table.insert(self.LTMaster.baler.baleVolumes, i + 1, liters);
        i = i + 1;
    end
    
    self.LTMaster.baler.balesNet = {};
    self.LTMaster.baler.balesNet.netNodes = {};
    self.LTMaster.baler.balesNet.numNetNodes = 0;
    local i = 0;
    while true do
        local key = string.format("vehicle.LTMaster.baler.balesNet.netNode(%d)", i);
        if not hasXMLProperty(self.xmlFile, key) then
            break;
        end
        local object = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#index"));
        local order = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#order"), 1);
        table.insert(self.LTMaster.baler.balesNet.netNodes, order, object);
        i = i + 1;
    end
    self.LTMaster.baler.balesNet.numNetNodes = #self.LTMaster.baler.balesNet.netNodes;
    self.LTMaster.baler.balesNet.netRollIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.baler.balesNet#netRollIndex"));
    self.LTMaster.baler.balesNet.netUVIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.baler.balesNet#netUVIndex"));
    self.LTMaster.baler.balesNet.netRollUses = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler.balesNet#netRollUses"), 50);
    self.LTMaster.baler.balesNet.netRollMinScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.balesNet#netRollMinScale"), 0.2);
    self.LTMaster.baler.balesNet.netRollRemainingUses = self.LTMaster.baler.balesNet.netRollUses;
    self.LTMaster.baler.balesNet.outOfNetRolls = false;
    if self.isClient then
        self.LTMaster.baler.balesNet.sampleFill = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.balesNet.fillSound", nil, self.baseDirectory, self.components[1].node);
    end
    self.LTMaster.baler.balesNet.fillLitersPerSecond = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.balesNet#fillLitersPerSecond"), 1);
    if self.configurations["dynamicChamber"] == 1 then
        self.LTMaster.baler.dynamicChamber = false;
    else
        self.LTMaster.baler.dynamicChamber = true;
    end
    self.LTMaster.baler.createdBales = 0;
end

function LTMaster:postLoadBaler(savegame)
    self.setUnitFillLevel = Utils.appendedFunction(self.setUnitFillLevel, LTMaster.setUnitFillLevel);
    if savegame ~= nil and not savegame.resetVehicles then
        local numBales = getXMLInt(savegame.xmlFile, savegame.key .. "#numBales");
        self.LTMaster.baler.baleVolumesIndex = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#baleVolumesIndex"), self.LTMaster.baler.baleVolumesIndex);
        self.LTMaster.baler.balesNet.netRollRemainingUses = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#netRollRemainingUses"), self.LTMaster.baler.balesNet.netRollRemainingUses);
        self.LTMaster.baler.createdBales = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#createdBales"), self.LTMaster.baler.createdBales);
        if numBales ~= nil and numBales > 0 then
            self.LTMaster.baler.balesToLoad = {};
            local baleKey = savegame.key .. ".bale(0)";
            local bale = {};
            local fillTypeStr = getXMLString(savegame.xmlFile, baleKey .. "#fillType");
            local fillType = FillUtil.fillTypeNameToInt[fillTypeStr];
            bale.fillType = fillType;
            bale.fillLevel = getXMLFloat(savegame.xmlFile, baleKey .. "#fillLevel");
            table.insert(self.LTMaster.baler.balesToLoad, bale);
        end
    end
end

function LTMaster:getSaveAttributesAndNodesBaler(nodeIdent)
    local attributes = 'numBales="' .. table.getn(self.LTMaster.baler.bales) .. '"';
    attributes = attributes .. ' baleVolumesIndex="' .. self.LTMaster.baler.baleVolumesIndex .. '"';
    attributes = attributes .. ' netRollRemainingUses="' .. self.LTMaster.baler.balesNet.netRollRemainingUses .. '"';
    attributes = attributes .. ' createdBales="' .. self.LTMaster.baler.createdBales .. '"';
    local nodes = "";
    if table.getn(self.LTMaster.baler.bales) > 0 then
        local bale = self.LTMaster.baler.bales[1];
        local fillTypeStr = "unknown";
        if bale.fillType ~= FillUtil.FILLTYPE_UNKNOWN then
            fillTypeStr = FillUtil.fillTypeIntToName[bale.fillType];
        end
        nodes = nodes .. nodeIdent .. '<bale fillType="' .. fillTypeStr .. '" fillLevel="' .. bale.fillLevel .. '"';
        nodes = nodes .. ' />';
    end
    return attributes, nodes;
end

function LTMaster:deleteBaler()
    for k, _ in pairs(self.LTMaster.baler.bales) do
        self:dropBale(k);
    end
    if self.LTMaster.baler.dummyBale.currentBale ~= nil then
        delete(self.LTMaster.baler.dummyBale.currentBale);
        self.LTMaster.baler.dummyBale.currentBale = nil;
    end
    if self.isClient then
        SoundUtil.deleteSample(self.LTMaster.baler.sampleBaler);
        SoundUtil.deleteSample(self.LTMaster.baler.sampleBalerIdle);
        SoundUtil.deleteSample(self.LTMaster.baler.sampleBalerDoor);
        SoundUtil.deleteSample(self.LTMaster.baler.sampleBalerEject);
        SoundUtil.deleteSample(self.LTMaster.baler.sampleKnotting);
        SoundUtil.deleteSample(self.LTMaster.baler.sampleOutOfNet);
        SoundUtil.deleteSample(self.LTMaster.baler.balesNet.sampleFill);
    end
end

function LTMaster:writeStreamBaler(streamId, connection)
    if self.LTMaster.baler.baleUnloadAnimationName ~= nil then
        streamWriteUIntN(streamId, self.LTMaster.baler.unloadingState, 7);
        local animTime = 0;
        if self.LTMaster.baler.unloadingState == Baler.UNLOADING_CLOSED or self.LTMaster.baler.unloadingState == Baler.UNLOADING_CLOSING then
            animTime = self:getRealAnimationTime(self.LTMaster.baler.baleCloseAnimationName);
        elseif self.LTMaster.baler.unloadingState == Baler.UNLOADING_OPEN or self.LTMaster.baler.unloadingState == Baler.UNLOADING_OPENING then
            animTime = self:getRealAnimationTime(self.LTMaster.baler.baleUnloadAnimationName);
        end
        streamWriteFloat32(streamId, animTime);
    end
    streamWriteUInt8(streamId, table.getn(self.LTMaster.baler.bales));
    for i = 1, table.getn(self.LTMaster.baler.bales) do
        local bale = self.LTMaster.baler.bales[i];
        streamWriteInt8(streamId, bale.fillType);
        streamWriteFloat32(streamId, bale.fillLevel);
    end
end

function LTMaster:readStreamBaler(streamId, connection)
    if self.LTMaster.baler.baleUnloadAnimationName ~= nil then
        local state = streamReadUIntN(streamId, 7);
        local animTime = streamReadFloat32(streamId);
        if state == Baler.UNLOADING_CLOSED or state == Baler.UNLOADING_CLOSING then
            self:setIsBalerUnloadingBale(false, true);
            self:setRealAnimationTime(self.LTMaster.baler.baleCloseAnimationName, animTime);
        elseif state == Baler.UNLOADING_OPEN or state == Baler.UNLOADING_OPENING then
            self:setIsBalerUnloadingBale(true, true);
            self:setRealAnimationTime(self.LTMaster.baler.baleUnloadAnimationName, animTime);
        end
    end
    local numBales = streamReadUInt8(streamId);
    for i = 1, numBales do
        local fillType = streamReadInt8(streamId);
        local fillLevel = streamReadFloat32(streamId);
        self:createBale(fillType, fillLevel, true);
    end
end

function LTMaster:updateBaler(dt)
    if self.LTMaster.baler.balesToLoad ~= nil and self.firstTimeRun then
        local v = self.LTMaster.baler.balesToLoad[1];
        self:createBale(v.fillType, v.fillLevel, true);
        self.LTMaster.baler.balesToLoad = nil;
    end
    if self.isClient then
        if self:getIsActiveForInput() then
            if self.LTMaster.baler.dynamicChamber and self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) < self.LTMaster.baler.lowerVolume and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA3) then
                self:setBaleVolume(self:getNextVolumesIndex(self.LTMaster.baler.baleVolumesIndex));
            end
            if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA3) then
                if self:isUnloadingAllowed() then
                    if self.LTMaster.baler.baleUnloadAnimationName ~= nil then
                        if self.LTMaster.baler.unloadingState == Baler.UNLOADING_CLOSED then
                            if table.getn(self.LTMaster.baler.bales) > 0 then
                                self.LTMaster.baler.autoUnloadTime = g_currentMission.time;
                                self.LTMaster.baler.skipKnotting = true;
                            end
                        end
                    end
                end
            end
        end
    end
end

function LTMaster:updateTickBaler(dt, normalizedDt)
    if self.LTMaster.baler.balesNet.numNetNodes > 0 then
        local level = self:getUnitFillLevel(self.LTMaster.fillUnits["balesNet"].index);
        for i = 1, self.LTMaster.baler.balesNet.numNetNodes do
            setVisibility(self.LTMaster.baler.balesNet.netNodes[i], i <= level);
        end
    end
    if self.LTMaster.baler.balesNet.outOfNetRolls then
        setVisibility(self.LTMaster.baler.balesNet.netRollIndex, false);
        setVisibility(self.LTMaster.baler.balesNet.netUVIndex, false);
    else
        setVisibility(self.LTMaster.baler.balesNet.netRollIndex, true);
        setVisibility(self.LTMaster.baler.balesNet.netUVIndex, true);
        local percent = self.LTMaster.baler.balesNet.netRollMinScale + (1 - self.LTMaster.baler.balesNet.netRollMinScale) * (self.LTMaster.baler.balesNet.netRollRemainingUses / self.LTMaster.baler.balesNet.netRollUses);
        setScale(self.LTMaster.baler.balesNet.netRollIndex, 1, percent, percent);
    end
    if self.isServer then
        self.LTMaster.conveyor.isOverloading = false;
    end
    self.LTMaster.baler.isWorking = false;
    if self:getIsActive() then
        if self:getIsTurnedOn() then
            if self:allowPickingUp() and self.isServer and not self.LTMaster.baler.balesNet.outOfNetRolls then
                self.LTMaster.conveyor.isOverloading = true;
                if self:getIsConveyorOverloading() then
                    self.LTMaster.baler.isWorking = true;
                    local usedFillType = self:getUnitLastValidFillType(self.LTMaster.fillUnits["main"].index);
                    local fillLevel = self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index);
                    local totalLiters = math.min(fillLevel, self.LTMaster.conveyor.overloadingCapacity * normalizedDt);
                    if totalLiters > 0 then
                        self:setUnitFillLevel(self.LTMaster.fillUnits["main"].index, fillLevel - totalLiters, usedFillType, false, self.fillVolumeUnloadInfos[self.LTMaster.unloadInfoIndex]);
                        local deltaLevel = totalLiters * self.LTMaster.baler.fillScale;
                        if self.LTMaster.silageAdditive.enabled and self.LTMaster.silageAdditive.acceptedFillTypes[usedFillType] then
                            local additiveLevel = self:getUnitFillLevel(self.LTMaster.fillUnits["silageAdditive"].index);
                            if additiveLevel > 0 then
                                additiveLevel = additiveLevel - deltaLevel * self.LTMaster.silageAdditive.usage;
                                self:setUnitFillLevel(self.LTMaster.fillUnits["silageAdditive"].index, additiveLevel, FillUtil.FILLTYPE_SILAGEADDITIVE, true);
                                deltaLevel = deltaLevel * self.LTMaster.silageAdditive.gain;
                                self.LTMaster.silageAdditive.isUsing = true;
                            else
                                self.LTMaster.silageAdditive.isUsing = false;
                            end
                        else
                            self.LTMaster.silageAdditive.isUsing = false;
                        end
                        local oldFillLevel = self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex);
                        self:setUnitFillLevel(self.LTMaster.baler.fillUnitIndex, oldFillLevel + deltaLevel, usedFillType, true);
                        if self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) >= self:getUnitCapacity(self.LTMaster.baler.fillUnitIndex) then
                            if self.LTMaster.baler.baleTypes ~= nil then
                                self:createBale(usedFillType, self:getUnitCapacity(self.LTMaster.baler.fillUnitIndex));
                                g_server:broadcastEvent(LTMasterBalerCreateBaleEvent:new(self, usedFillType), nil, nil, self);
                                self.LTMaster.baler.autoUnloadTime = g_currentMission.time + self.LTMaster.baler.knottingTime;
                            end
                        end
                    end
                end
            end
            if self.isClient then
                Sound3DUtil:playSample(self.LTMaster.baler.sampleBalerIdle, 0, 0, nil, self:getIsActiveForSound());
            end
        end
        if self.isClient then
            if not self:getIsTurnedOn() then
                Sound3DUtil:stopSample(self.LTMaster.baler.sampleBalerIdle);
            end
            if self.LTMaster.baler.unloadingState == Baler.UNLOADING_OPEN then
                if getNumOfChildren(self.LTMaster.baler.baleAnimRoot) > 0 then
                    delete(getChildAt(self.LTMaster.baler.baleAnimRoot, 0));
                end
            end
        end
        if self.LTMaster.baler.unloadingState == Baler.UNLOADING_OPENING then
            local isPlaying = self:getIsAnimationPlaying(self.LTMaster.baler.baleUnloadAnimationName);
            local animTime = self:getRealAnimationTime(self.LTMaster.baler.baleUnloadAnimationName);
            if not isPlaying or animTime >= self.LTMaster.baler.baleDropAnimTime then;
                if table.getn(self.LTMaster.baler.bales) > 0 then
                    self:dropBale(1);
                    if self.isServer then
                        self:setUnitFillLevel(self.LTMaster.baler.fillUnitIndex, 0, self:getUnitFillType(self.LTMaster.baler.fillUnitIndex), true);
                    end
                end
                if not isPlaying then
                    self.LTMaster.baler.unloadingState = Baler.UNLOADING_OPEN;
                    if self.isClient then
                        Sound3DUtil:stopSample(self.LTMaster.baler.sampleBalerEject);
                        Sound3DUtil:stopSample(self.LTMaster.baler.sampleBalerDoor);
                    end
                end
            end
        elseif self.LTMaster.baler.unloadingState == Baler.UNLOADING_CLOSING then
            if not self:getIsAnimationPlaying(self.LTMaster.baler.baleCloseAnimationName) then
                self.LTMaster.baler.unloadingState = Baler.UNLOADING_CLOSED;
                if self.isClient then
                    Sound3DUtil:stopSample(self.LTMaster.baler.sampleBalerDoor);
                end
            end
        end
        if self.isServer then
            if self.LTMaster.baler.autoUnloadTime ~= nil then
                if g_currentMission.time < self.LTMaster.baler.autoUnloadTime then
                    self.LTMaster.baler.isWorking = true;
                end
                if g_currentMission.time >= self.LTMaster.baler.autoUnloadTime then
                    if self.LTMaster.baler.unloadingState == Baler.UNLOADING_CLOSED and self:allowsGrabbingBale() then
                        self:setIsBalerUnloadingBale(true);
                        if not self.LTMaster.baler.skipKnotting then
                            self.LTMaster.baler.balesNet.netRollRemainingUses = self.LTMaster.baler.balesNet.netRollRemainingUses - 1;
                        end
                    end
                    if self.LTMaster.baler.unloadingState == Baler.UNLOADING_OPEN then
                        self:setIsBalerUnloadingBale(false);
                        self.LTMaster.baler.autoUnloadTime = nil;
                        self.LTMaster.baler.skipKnotting = false;
                    end
                end
            end
            if self.LTMaster.baler.balesNet.netRollRemainingUses <= 0 then
                local fillLevel = self:getUnitFillLevel(self.LTMaster.fillUnits["balesNet"].index);
                if fillLevel > 0 then
                    self.LTMaster.baler.balesNet.outOfNetRolls = false;
                    self.LTMaster.baler.balesNet.netRollRemainingUses = self.LTMaster.baler.balesNet.netRollUses;
                    self:setUnitFillLevel(self.LTMaster.fillUnits["balesNet"].index, fillLevel - 1, FillUtil.FILLTYPE_BALESNET, true);
                else
                    self.LTMaster.baler.balesNet.outOfNetRolls = true;
                end
            end
        end
        if self.isClient then
            Utils.updateRotationNodes(self, self.LTMaster.baler.workingRotatingParts, dt, self.LTMaster.baler.isWorking);
            Utils.updateScrollers(self.LTMaster.baler.uvScrollParts, dt, self.LTMaster.baler.isWorking);
            local isKnotting = self.LTMaster.baler.autoUnloadTime ~= nil and g_currentMission.time < self.LTMaster.baler.autoUnloadTime;
            Utils.updateRotationNodes(self, self.LTMaster.baler.knottingRotatingParts, dt, isKnotting);
            Utils.updateScrollers(self.LTMaster.baler.knottingScrollParts, dt, isKnotting);
            if self:getIsTurnedOn() then
                if self.LTMaster.baler.balesNet.outOfNetRolls then
                    Sound3DUtil:playSample(self.LTMaster.baler.sampleOutOfNet, 0, 0, nil, self:getIsActiveForSound());
                else
                    Sound3DUtil:stopSample(self.LTMaster.baler.sampleOutOfNet);
                end
            end
            if self.LTMaster.baler.isWorking and self.LTMaster.baler.autoUnloadTime == nil then
                Sound3DUtil:playSample(self.LTMaster.baler.sampleBaler, 0, 0, nil, self:getIsActiveForSound());
            else
                Sound3DUtil:stopSample(self.LTMaster.baler.sampleBaler);
            end
        end
    end
    if self.isFilling and self.fillTrigger ~= nil and self.fillTrigger.fillType == FillUtil.FILLTYPE_BALESNET then
        if self.isClient then
            Sound3DUtil:playSample(self.LTMaster.baler.balesNet.sampleFill, 0, 0, nil, self:getIsActiveForSound());
        end
        self.fillLitersPerSecond = self.LTMaster.baler.balesNet.fillLitersPerSecond;
    else
        if self.isClient then
            Sound3DUtil:stopSample(self.LTMaster.baler.balesNet.sampleFill);
        end
    end
end

function LTMaster:drawBaler()
    if self.isClient then
        if self:getIsActiveForInput(true) then
            if self.LTMaster.baler.dynamicChamber and self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) < self.LTMaster.baler.lowerVolume then
                local cLiters = self.LTMaster.baler.baleVolumes[self.LTMaster.baler.baleVolumesIndex];
                local nLiters = self.LTMaster.baler.baleVolumes[self:getNextVolumesIndex(self.LTMaster.baler.baleVolumesIndex)];
                g_currentMission:addHelpButtonText(string.format(g_i18n:getText("GLTM_CHANGE_BALE_VOLUME"), cLiters, nLiters), InputBinding.IMPLEMENT_EXTRA3, nil, GS_PRIO_HIGH);
            end
            if self:isUnloadingAllowed() then
                if self.LTMaster.baler.baleUnloadAnimationName ~= nil then
                    if self.LTMaster.baler.unloadingState == Baler.UNLOADING_CLOSED then
                        if table.getn(self.LTMaster.baler.bales) > 0 then
                            g_currentMission:addHelpButtonText(g_i18n:getText("action_unloadBaler"), InputBinding.IMPLEMENT_EXTRA3, nil, GS_PRIO_HIGH);
                        end
                    end
                end
            end
        end
    end
end

function LTMaster:onDeactivateBaler()
    if self.LTMaster.baler.balingAnimationName ~= "" then
        self:stopAnimation(self.LTMaster.baler.balingAnimationName, true);
    end
end

function LTMaster:onDeactivateSoundsBaler()
    if self.isClient then
        Sound3DUtil:stopSample(self.LTMaster.baler.sampleBaler, true);
        Sound3DUtil:stopSample(self.LTMaster.baler.sampleBalerIdle, true);
        Sound3DUtil:stopSample(self.LTMaster.baler.sampleBalerDoor, true);
        Sound3DUtil:stopSample(self.LTMaster.baler.sampleBalerEject, true);
        Sound3DUtil:stopSample(self.LTMaster.baler.sampleKnotting, true);
        Sound3DUtil:stopSample(self.LTMaster.baler.sampleOutOfNet, true);
    end
end

function LTMaster:setUnitFillLevel(fillUnitIndex, fillLevel, fillType, force, fillInfo)
    if fillUnitIndex == self.LTMaster.baler.fillUnitIndex then
        if self.LTMaster.baler.dummyBale.baleNode ~= nil and fillLevel > 0 and fillLevel < self:getUnitCapacity(fillUnitIndex) and (self.LTMaster.baler.dummyBale.currentBale == nil or self.LTMaster.baler.dummyBale.currentBaleFillType ~= fillType) then
            if self.LTMaster.baler.dummyBale.currentBale ~= nil then
                delete(self.LTMaster.baler.dummyBale.currentBale);
                self.LTMaster.baler.dummyBale.currentBale = nil;
            end
            local t = self.LTMaster.baler.baleTypes[self.LTMaster.baler.currentBaleTypeId];
            local baleType = BaleUtil.getBale(fillType, t.width, t.height, t.length, t.diameter, t.isRoundBale);
            local baleRoot = Utils.loadSharedI3DFile(baleType.filename, "", false, false);
            local baleId = getChildAt(baleRoot, 0);
            setRigidBodyType(baleId, "NoRigidBody");
            link(self.LTMaster.baler.dummyBale.baleNode, baleId);
            delete(baleRoot);
            self.LTMaster.baler.dummyBale.currentBale = baleId;
            self.LTMaster.baler.dummyBale.currentBaleFillType = fillType;
        end
        if self.LTMaster.baler.dummyBale.currentBale ~= nil then
            local percent = fillLevel / self:getUnitCapacity(fillUnitIndex);
            setScale(self.LTMaster.baler.dummyBale.scaleNode, 1, percent, percent);
        end
    end
end

function LTMaster:onTurnedOn(noEventSend)
    if self.LTMaster.baler.balingAnimationName ~= "" then
        self:playAnimation(self.LTMaster.baler.balingAnimationName, 1, self:getAnimationTime(self.LTMaster.baler.balingAnimationName), true);
    end
end

function LTMaster:onTurnedOff(noEventSend)
    if self.LTMaster.baler.balingAnimationName ~= "" then
        self:stopAnimation(self.LTMaster.baler.balingAnimationName, true);
    end
end

function LTMaster:isUnloadingAllowed()
    if not self:getIsTurnedOn() then
        return false;
    end
    if self.hasBaleWrapper == nil or not self.hasBaleWrapper then
        return true;
    end
    return self:allowsGrabbingBale();
end

function LTMaster:setIsBalerUnloadingBale(isUnloadingBale, noEventSend)
    if self.LTMaster.baler.baleUnloadAnimationName ~= nil and self.LTMaster.baler.baleCloseAnimationName ~= nil then
        if isUnloadingBale then
            if self.LTMaster.baler.unloadingState ~= Baler.UNLOADING_OPENING then
                LTMBalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend);
                self.LTMaster.baler.unloadingState = Baler.UNLOADING_OPENING;
                if self.isClient then
                    Sound3DUtil:playSample(self.LTMaster.baler.sampleBalerEject, 1, 0, nil, self:getIsActiveForSound());
                    Sound3DUtil:playSample(self.LTMaster.baler.sampleBalerDoor, 1, 0, nil, self:getIsActiveForSound());
                end
                self:playAnimation(self.LTMaster.baler.baleUnloadAnimationName, self.LTMaster.baler.baleUnloadAnimationSpeed, nil, true);
            end
        else
            if self.LTMaster.baler.unloadingState ~= Baler.UNLOADING_CLOSING then
                LTMBalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend);
                self.LTMaster.baler.unloadingState = Baler.UNLOADING_CLOSING;
                if self.isClient then
                    Sound3DUtil:playSample(self.LTMaster.baler.sampleBalerDoor, 1, 0, nil, self:getIsActiveForSound());
                end
                self:playAnimation(self.LTMaster.baler.baleCloseAnimationName, self.LTMaster.baler.baleCloseAnimationSpeed, nil, true);
            end
        end
    end
end

function LTMaster:allowPickingUp(superFunc)
    if self.LTMaster.baler.baleUnloadAnimationName ~= nil then
        if table.getn(self.LTMaster.baler.bales) > 0 or self.LTMaster.baler.unloadingState ~= Baler.UNLOADING_CLOSED then
            return false;
        end
    end
    if superFunc ~= nil then
        return superFunc(self)
    end
    return true;
end

function LTMaster:createBale(baleFillType, fillLevel, firstTimeRun)
    if self.LTMaster.baler.knottingAnimation ~= "" then
        self:playAnimation(self.LTMaster.baler.knottingAnimation, self.LTMaster.baler.knottingAnimationSpeed, nil, true);
    end
    if not firstTimeRun then
        Sound3DUtil:playSample(self.LTMaster.baler.sampleKnotting, 1, 0, nil, self:getIsActiveForSound());
    end
    if self.LTMaster.baler.dummyBale.currentBale ~= nil then
        delete(self.LTMaster.baler.dummyBale.currentBale);
        self.LTMaster.baler.dummyBale.currentBale = nil;
    end
    local t = self.LTMaster.baler.baleTypes[self.LTMaster.baler.currentBaleTypeId];
    local baleType = BaleUtil.getBale(baleFillType, t.width, t.height, t.length, t.diameter, t.isRoundBale);
    local bale = {};
    bale.filename = Utils.getFilename(baleType.filename, "");
    bale.time = 0;
    bale.fillType = baleFillType;
    if self.isServer then
        local randomFillLevel = math.random(0, fillLevel * 0.06) - fillLevel * 0.03;
        bale.fillLevel = fillLevel + randomFillLevel;
    end
    local baleRoot = Utils.loadSharedI3DFile(baleType.filename, "", false, false);
    local baleId = getChildAt(baleRoot, 0);
    link(self.LTMaster.baler.baleAnimRoot, baleId);
    delete(baleRoot);
    bale.id = baleId;
    table.insert(self.LTMaster.baler.bales, bale);
end

function LTMaster:dropBale(baleIndex)
    local bale = self.LTMaster.baler.bales[baleIndex];
    local x, y, z = getWorldTranslation(bale.id);
    local rx, ry, rz = getWorldRotation(bale.id);
    delete(bale.id);
    if self.isServer then
        local baleObject = Bale:new(self.isServer, self.isClient);
        baleObject:load(bale.filename, x, y, z, rx, ry, rz, bale.fillLevel);
        baleObject:register();
        self:moveBaleToWrapper(baleObject);
    end
    Utils.releaseSharedI3DFile(bale.filename, nil, true);
    table.remove(self.LTMaster.baler.bales, baleIndex);
    self.LTMaster.baler.createdBales = self.LTMaster.baler.createdBales + 0.000001;
    g_currentMission.missionStats:updateStats("baleCount", 1);
end

function LTMaster:setBaleVolume(baleVolumesIndex, noEventSend)
    if self.isServer then
        self.LTMaster.baler.baleVolumesIndex = baleVolumesIndex;
        local liters = self.LTMaster.baler.baleVolumes[self.LTMaster.baler.baleVolumesIndex];
        self:setUnitCapacity(self.LTMaster.baler.fillUnitIndex, liters);
    else
        if noEventSend == nil or not noEventSend then
            g_client:getServerConnection():sendEvent(BalerChangeVolumeEvent:new(baleVolumesIndex, self));
        end
    end
end

function LTMaster:getNextVolumesIndex(baleVolumesIndex)
    local nextVolumesIndex = baleVolumesIndex + 1;
    if nextVolumesIndex > #self.LTMaster.baler.baleVolumes then
        nextVolumesIndex = 1;
    end
    return nextVolumesIndex;
end

function LTMaster:getCreatedBales()
    return self.LTMaster.baler.createdBales * 1000000;
end
