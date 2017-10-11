--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--07/05/2017
function LTMaster:loadWrapper(savegame)
    self.getIsFoldAllowed = Utils.overwrittenFunction(self.getIsFoldAllowed, LTMaster.getIsFoldAllowed);
    self.allowsGrabbingBale = LTMaster.allowsGrabbingBale;
    self.pickupWrapperBale = LTMaster.pickupWrapperBale;
    self.getWrapperBaleType = LTMaster.getWrapperBaleType;
    self.updateWrappingState = LTMaster.updateWrappingState;
    self.dropBaleFromWrapper = LTMaster.dropBaleFromWrapper;
    self.moveBaleToWrapper = LTMaster.moveBaleToWrapper;
    self.doStateChange = LTMaster.doStateChange;
    self.updateWrapNodes = LTMaster.updateWrapNodes;
    self.playMoveToWrapper = LTMaster.playMoveToWrapper;
    self.getWrappedBales = LTMaster.getWrappedBales;
    self.hasBaleWrapper = true;
    for _, baleCategory in pairs({"roundBaleWrapper", "squareBaleWrapper"}) do
        self[baleCategory] = {};
        self[baleCategory].animations = {};
        for _, animType in pairs({"moveToWrapper", "wrapBale", "dropFromWrapper", "resetAfterDrop"}) do
            local key = string.format("vehicle.LTMaster.wrapper.%s.animations.%s", baleCategory, animType);
            self[baleCategory].animations[animType] = {};
            self[baleCategory].animations[animType].animName = getXMLString(self.xmlFile, key .. "#animName");
            self[baleCategory].animations[animType].animSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#animSpeed"), 1);
            self[baleCategory].animations[animType].reverseAfterMove = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#reverseAfterMove"), true);
        end
        self[baleCategory].allowedBaleTypes = {};
        local i = 0;
        while true do
            local key = string.format("vehicle.LTMaster.wrapper.%s.baleTypes.baleType(%d)", baleCategory, i);
            if not hasXMLProperty(self.xmlFile, key) then
                break;
            end
            local wrapperBaleFilename = Utils.getFilename(getXMLString(self.xmlFile, key .. "#wrapperBaleFilename"), self.baseDirectory);
            local fillTypeStr = getXMLString(self.xmlFile, key .. "#fillType");
            if wrapperBaleFilename ~= nil and fillTypeStr ~= nil then
                local fillType = FillUtil.fillTypeNameToInt[fillTypeStr];
                if fillType == nil then
                    print("Warning: invalid fillType '" .. tostring(fillTypeStr) .. "' for '" .. tostring(key) .. "' given!");
                    break;
                end
                self[baleCategory].allowedBaleTypes[fillType] = {};
                local minBaleDiameter = getXMLFloat(self.xmlFile, key .. "#minBaleDiameter");
                local maxBaleDiameter = getXMLFloat(self.xmlFile, key .. "#maxBaleDiameter");
                local minBaleWidth = getXMLFloat(self.xmlFile, key .. "#minBaleWidth");
                local maxBaleWidth = getXMLFloat(self.xmlFile, key .. "#maxBaleWidth");
                if minBaleDiameter ~= nil and maxBaleDiameter ~= nil and minBaleWidth ~= nil and maxBaleWidth ~= nil then
                    table.insert(self[baleCategory].allowedBaleTypes[fillType], {fillType = fillType, wrapperBaleFilename = wrapperBaleFilename, minBaleDiameter = minBaleDiameter, maxBaleDiameter = maxBaleDiameter, minBaleWidth = minBaleWidth, maxBaleWidth = maxBaleWidth});
                else
                    local minBaleHeight = getXMLFloat(self.xmlFile, key .. "#minBaleHeight");
                    local maxBaleHeight = getXMLFloat(self.xmlFile, key .. "#maxBaleHeight");
                    local minBaleLength = getXMLFloat(self.xmlFile, key .. "#minBaleLength");
                    local maxBaleLength = getXMLFloat(self.xmlFile, key .. "#maxBaleLength");
                    if minBaleWidth ~= nil and maxBaleWidth ~= nil and minBaleHeight ~= nil and maxBaleHeight ~= nil and minBaleLength ~= nil and maxBaleLength ~= nil then
                        table.insert(self[baleCategory].allowedBaleTypes[fillType], {fillType = fillType, wrapperBaleFilename = wrapperBaleFilename, minBaleWidth = minBaleWidth, maxBaleWidth = maxBaleWidth, minBaleHeight = minBaleHeight, maxBaleHeight = maxBaleHeight, minBaleLength = minBaleLength, maxBaleLength = maxBaleLength});
                    end
                end
            end
            i = i + 1;
        end
        local key = string.format("vehicle.LTMaster.wrapper.%s", baleCategory);
        self[baleCategory].baleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#baleIndex"));
        self[baleCategory].wrapperNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#wrapperIndex"));
        self[baleCategory].wrapperRotAxis = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#wrapperRotAxis"), 2);
        local wrappingAnimCurve = AnimCurve:new(linearInterpolatorN);
        local i = 0;
        while true do
            local keyI = string.format("%s.wrapperAnimation.key(%d)", key, i);
            local t = getXMLFloat(self.xmlFile, keyI .. "#time");
            local baleX, baleY, baleZ = Utils.getVectorFromString(getXMLString(self.xmlFile, keyI .. "#baleRot"));
            if baleX == nil or baleY == nil or baleZ == nil then
                break;
            end
            baleX = math.rad(Utils.getNoNil(baleX, 0));
            baleY = math.rad(Utils.getNoNil(baleY, 0));
            baleZ = math.rad(Utils.getNoNil(baleZ, 0));
            local wrapperX, wrapperY, wrapperZ = Utils.getVectorFromString(getXMLString(self.xmlFile, keyI .. "#wrapperRot"));
            wrapperX = math.rad(Utils.getNoNil(wrapperX, 0));
            wrapperY = math.rad(Utils.getNoNil(wrapperY, 0));
            wrapperZ = math.rad(Utils.getNoNil(wrapperZ, 0));
            wrappingAnimCurve:addKeyframe({v = {baleX, baleY, baleZ, wrapperX, wrapperY, wrapperZ}, time = t});
            i = i + 1;
        end
        self[baleCategory].animCurve = wrappingAnimCurve;
        self[baleCategory].animTime = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#wrappingTime"), 5) * 1000;
        self[baleCategory].currentTime = 0;
        self[baleCategory].currentBale = nil;
        self[baleCategory].wrapAnimNodes = {};
        local i = 0;
        while true do
            local wrapAnimNodeKey = string.format("vehicle.LTMaster.wrapper.%s.wrapAnimNodes.wrapAnimNode(%d)", baleCategory, i);
            if not hasXMLProperty(self.xmlFile, wrapAnimNodeKey) then
                break;
            end
            local nodeId = Utils.indexToObject(self.components, getXMLString(self.xmlFile, wrapAnimNodeKey .. "#index"));
            if nodeId ~= nil then
                local animCurve = AnimCurve:new(linearInterpolatorN);
                local keyI = 0;
                local useWrapperRot = false;
                while true do
                    local key = string.format(wrapAnimNodeKey .. ".key(%d)", keyI);
                    local wrapperRot = getXMLFloat(self.xmlFile, key .. "#wrapperRot");
                    local wrapperTime = getXMLFloat(self.xmlFile, key .. "#wrapperTime");
                    if wrapperRot == nil and wrapperTime == nil then
                        break;
                    end
                    useWrapperRot = wrapperRot ~= nil;
                    local x, y, z = Utils.getVectorFromString(getXMLString(self.xmlFile, key .. "#trans"));
                    local rx, ry, rz = Utils.getVectorFromString(getXMLString(self.xmlFile, key .. "#rot"));
                    local sx, sy, sz = Utils.getVectorFromString(getXMLString(self.xmlFile, key .. "#scale"));
                    x = Utils.getNoNil(x, 0);
                    y = Utils.getNoNil(y, 0);
                    z = Utils.getNoNil(z, 0);
                    rx = math.rad(Utils.getNoNil(rx, 0));
                    ry = math.rad(Utils.getNoNil(ry, 0));
                    rz = math.rad(Utils.getNoNil(rz, 0));
                    sx = Utils.getNoNil(sx, 1);
                    sy = Utils.getNoNil(sy, 1);
                    sz = Utils.getNoNil(sz, 1);
                    if wrapperRot ~= nil then
                        animCurve:addKeyframe({v = {x, y, z, rx, ry, rz, sx, sy, sz}, time = math.rad(wrapperRot)});
                    else
                        animCurve:addKeyframe({v = {x, y, z, rx, ry, rz, sx, sy, sz}, time = wrapperTime});
                    end
                    keyI = keyI + 1;
                end
                if keyI > 0 then
                    local repeatWrapperRot = Utils.getNoNil(getXMLBool(self.xmlFile, wrapAnimNodeKey .. "#repeatWrapperRot"), false);
                    local normalizeRotationOnBaleDrop = Utils.getNoNil(getXMLInt(self.xmlFile, wrapAnimNodeKey .. "#normalizeRotationOnBaleDrop"), 0);
                    table.insert(self[baleCategory].wrapAnimNodes, {nodeId = nodeId, animCurve = animCurve, repeatWrapperRot = repeatWrapperRot, normalizeRotationOnBaleDrop = normalizeRotationOnBaleDrop, useWrapperRot = useWrapperRot});
                end
            end
            i = i + 1;
        end
        self[baleCategory].wrapNodes = {};
        local i = 0;
        while true do
            local wrapNodeKey = string.format("vehicle.LTMaster.wrapper.%s.wrapNodes.wrapNode(%d)", baleCategory, i);
            if not hasXMLProperty(self.xmlFile, wrapNodeKey) then
                break;
            end
            local nodeId = Utils.indexToObject(self.components, getXMLString(self.xmlFile, wrapNodeKey .. "#index"));
            local wrapVisibility = Utils.getNoNil(getXMLBool(self.xmlFile, wrapNodeKey .. "#wrapVisibility"), false);
            local emptyVisibility = Utils.getNoNil(getXMLBool(self.xmlFile, wrapNodeKey .. "#emptyVisibility"), false);
            if nodeId ~= nil and (wrapVisibility or emptyVisibility) then
                local maxWrapperRot = getXMLFloat(self.xmlFile, wrapNodeKey .. "#maxWrapperRot");
                if maxWrapperRot == nil then
                    maxWrapperRot = math.huge;
                else
                    maxWrapperRot = math.rad(maxWrapperRot);
                end
                table.insert(self[baleCategory].wrapNodes, {nodeId = nodeId, wrapVisibility = wrapVisibility, emptyVisibility = emptyVisibility, maxWrapperRot = maxWrapperRot});
            end
            i = i + 1;
        end
        local defaultText = baleCategory == "roundBaleWrapper" and "action_unloadRoundBale" or "action_unloadBaler";
        self[baleCategory].unloadBaleText = Utils.getNoNil(getXMLString(self.xmlFile, key .. "#unloadBaleText"), defaultText);
    end
    self.LTMaster.wrapper = {};
    self.LTMaster.wrapper.balesFoil = {};
    self.LTMaster.wrapper.currentWrapper = {};
    self.LTMaster.wrapper.currentWrapper = self.roundBaleWrapper;
    self:updateWrapNodes(false, true, 0);
    self.LTMaster.wrapper.baleGrabber = {};
    self.LTMaster.wrapper.baleGrabber.grabNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.wrapper.baleGrabber#index"));
    self.LTMaster.wrapper.baleGrabber.origTrans = {getTranslation(self.LTMaster.wrapper.baleGrabber.grabNode)};
    if self.isClient then
        self.LTMaster.wrapper.currentWrapperSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.wrapper.wrapperSound", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.wrapper.currentWrapperStartSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.wrapper.wrapperStartSound", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.wrapper.currentWrapperStopSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.wrapper.wrapperStopSound", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.wrapper.sampleOutOfFoil = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.wrapper.outOfFoilSound", nil, self.baseDirectory, self.components[1].node);
    end
    self.LTMaster.wrapper.baleToLoad = nil;
    self.LTMaster.wrapper.baleToMount = nil;
    self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_NONE;
    self.LTMaster.wrapper.grabberIsMoving = false;
    self.LTMaster.wrapper.mustWrappedBales = {};
    local fillTypeNames = getXMLString(self.xmlFile, "vehicle.LTMaster.wrapper.mustWrappedBales#fillTypes");
    for _, f in pairs(FillUtil.getFillTypesByNames(fillTypeNames)) do
        self.LTMaster.wrapper.mustWrappedBales[f] = true;
    end
    self.LTMaster.wrapper.enabled = true;
    self.LTMaster.wrapper.balesFoil.foilNodes = {};
    self.LTMaster.wrapper.balesFoil.numfoilNodes = 0;
    local i = 0;
    while true do
        local key = string.format("vehicle.LTMaster.wrapper.balesFoil.foilNode(%d)", i);
        if not hasXMLProperty(self.xmlFile, key) then
            break;
        end
        local object = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#index"));
        local order = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#order"), 1);
        table.insert(self.LTMaster.wrapper.balesFoil.foilNodes, order, object);
        i = i + 1;
    end
    self.LTMaster.wrapper.balesFoil.numFoilNodes = #self.LTMaster.wrapper.balesFoil.foilNodes;
    self.LTMaster.wrapper.balesFoil.leftFoilRollIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.wrapper.balesFoil#leftFoilRollIndex"));
    self.LTMaster.wrapper.balesFoil.rightFoilRollIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.wrapper.balesFoil#rightFoilRollIndex"));
    self.LTMaster.wrapper.balesFoil.leftFoilIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.wrapper.balesFoil#leftFoilIndex"));
    self.LTMaster.wrapper.balesFoil.rightFoilIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.wrapper.balesFoil#rightFoilIndex"));
    self.LTMaster.wrapper.balesFoil.foilRollUses = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.wrapper.balesFoil#foilRollUses"), 50);
    self.LTMaster.wrapper.balesFoil.foilRollMinScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.wrapper.balesFoil#foilRollMinScale"), 0.3);
    self.LTMaster.wrapper.balesFoil.foilRollRemainingUses = self.LTMaster.wrapper.balesFoil.foilRollUses;
    self.LTMaster.wrapper.balesFoil.outOfFoilRolls = false;
    if self.isClient then
        self.LTMaster.wrapper.balesFoil.sampleFill = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.wrapper.balesFoil.fillSound", nil, self.baseDirectory, self.components[1].node);
    end
    self.LTMaster.wrapper.balesFoil.fillLitersPerSecond = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.wrapper.balesFoil#fillLitersPerSecond"), 1);
    self.LTMaster.wrapper.wrappedBales = 0;
    
    -- Seasons support
    if g_seasons ~= nil then
        if savegame ~= nil and not savegame.resetVehicles then
            local baleFillTypeSourceName = getXMLString(savegame.xmlFile, savegame.key .. "#baleFillTypeSource");
            if baleFillTypeSourceName ~= nil then
                self.baleFillTypeSource = FillUtil.getFillTypesByNames(baleFillTypeSourceName)[1];
            end
        end
    end
end

function LTMaster:postLoadWrapper(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local filename = getXMLString(savegame.xmlFile, savegame.key .. "#baleFileName");
        if filename ~= nil then
            filename = Utils.convertFromNetworkFilename(filename);
            local wrapperTime = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#wrapperTime"), 0);
            local baleValueScale = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#baleValueScale"), 1);
            local fillLevel = getXMLFloat(savegame.xmlFile, savegame.key .. "#fillLevel");
            local translation = {0, 0, 0};
            local rotation = {0, 0, 0};
            self.LTMaster.wrapper.baleToLoad = {filename = filename, translation = translation, rotation = rotation, fillLevel = fillLevel, wrapperTime = wrapperTime, baleValueScale = baleValueScale};
        end
        self.LTMaster.wrapper.enabled = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#wrapperEnabled"), self.LTMaster.wrapper.enabled);
        self.LTMaster.wrapper.balesFoil.foilRollRemainingUses = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#foilRollRemainingUses"), self.LTMaster.wrapper.balesFoil.foilRollRemainingUses);
        self.LTMaster.wrapper.wrappedBales = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#wrappedBales"), self.LTMaster.wrapper.wrappedBales);
    end
end

function LTMaster:getSaveAttributesAndNodesWrapper(nodeIdent)
    local attributes = "";
    attributes = ' wrapperEnabled="' .. tostring(self.LTMaster.wrapper.enabled) .. '"';
    attributes = attributes .. ' foilRollRemainingUses="' .. self.LTMaster.wrapper.balesFoil.foilRollRemainingUses .. '"';
    attributes = attributes .. ' wrappedBales="' .. self.LTMaster.wrapper.wrappedBales .. '"';
    local baleServerId = self.LTMaster.wrapper.baleGrabber.currentBale;
    if baleServerId == nil then
        baleServerId = self.LTMaster.wrapper.currentWrapper.currentBale;
    end
    if baleServerId ~= nil then
        local bale = networkGetObject(baleServerId);
        if bale ~= nil then
            local fillLevel = bale:getFillLevel();
            local baleValueScale = bale.baleValueScale;
            attributes = attributes .. ' baleFileName="' .. Utils.encodeToHTML(Utils.convertToNetworkFilename(bale.i3dFilename)) .. '" fillLevel="' .. fillLevel .. '" wrapperTime="' .. tostring(self.LTMaster.wrapper.currentWrapper.currentTime) .. '" baleValueScale="' .. baleValueScale .. '"';
        end
    end
    -- Seasons support
    if g_seasons ~= nil then
        if attributes ~= nil and self.baleFillTypeSource ~= nil then
            attributes = attributes .. ' baleFillTypeSource="' .. Utils.getNoNil(FillUtil.fillTypeIntToName[self.baleFillTypeSource], "grass_windrow") .. '"';
        end
    end
    return attributes;
end

function LTMaster:deleteWrapper()
    if self.isServer then
        local baleId;
        if self.LTMaster.wrapper.currentWrapper.currentBale ~= nil then
            baleId = self.LTMaster.wrapper.currentWrapper.currentBale;
        end
        if self.LTMaster.wrapper.baleGrabber.currentBale ~= nil then
            baleId = self.LTMaster.wrapper.baleGrabber.currentBale;
        end
        if baleId ~= nil then
            local bale = networkGetObject(baleId);
            if bale ~= nil then
                bale:unmount();
            end
        end
    end
    if self.isClient then
        SoundUtil.deleteSample(self.LTMaster.wrapper.currentWrapperSound);
        SoundUtil.deleteSample(self.LTMaster.wrapper.currentWrapperStartSound);
        SoundUtil.deleteSample(self.LTMaster.wrapper.currentWrapperStopSound);
        SoundUtil.deleteSample(self.LTMaster.wrapper.sampleOutOfFoil);
        SoundUtil.deleteSample(self.LTMaster.wrapper.balesFoil.sampleFill);
    end
end

function LTMaster:readStreamWrapper(streamId, connection)
    if connection:getIsServer() then
        local wrapperState = streamReadUIntN(streamId, BaleWrapper.STATE_NUM_BITS);
        if wrapperState >= BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
            local baleServerId;
            if wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
                baleServerId = readNetworkNodeObjectId(streamId);
            end
            if wrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, baleServerId);
                AnimatedVehicle.updateAnimations(self, 99999999);
            elseif wrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
                self.LTMaster.wrapper.baleGrabber.currentBale = baleServerId;
                self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER);
                AnimatedVehicle.updateAnimations(self, 99999999);
            elseif wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
                local attachNode = self.LTMaster.wrapper.currentWrapper.baleNode;
                self.LTMaster.wrapper.baleToMount = {serverId = baleServerId, linkNode = attachNode, trans = {0, 0, 0}, rot = {0, 0, 0}};
                self:updateWrapNodes(true, true, 0);
                self.LTMaster.wrapper.currentWrapper.currentBale = baleServerId;
                if wrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
                    local wrapperTime = streamReadFloat32(streamId);
                    self.LTMaster.wrapper.currentWrapper.currentTime = wrapperTime;
                    self:updateWrappingState(self.LTMaster.wrapper.currentWrapper.currentTime / self.LTMaster.wrapper.currentWrapper.animTime, true);
                else
                    self.LTMaster.wrapper.currentWrapper.currentTime = self.LTMaster.wrapper.currentWrapper.animTime;
                    self:updateWrappingState(1, true);
                    self:doStateChange(BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED);
                    AnimatedVehicle.updateAnimations(self, 99999999);
                    if wrapperState >= BaleWrapper.STATE_WRAPPER_DROPPING_BALE then
                        self:doStateChange(BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE);
                        AnimatedVehicle.updateAnimations(self, 99999999);
                    end
                end
            else
                self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM;
            end
        end
    end
end

function LTMaster:writeStreamWrapper(streamId, connection)
    if not connection:getIsServer() then
        local wrapperState = self.LTMaster.wrapper.baleWrapperState;
        streamWriteUIntN(streamId, wrapperState, BaleWrapper.STATE_NUM_BITS);
        if wrapperState >= BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER and wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
            if wrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                writeNetworkNodeObjectId(streamId, self.LTMaster.wrapper.baleGrabber.currentBale);
            else
                writeNetworkNodeObjectId(streamId, self.LTMaster.wrapper.currentWrapper.currentBale);
            end
        end
        if wrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
            streamWriteFloat32(streamId, self.LTMaster.wrapper.currentWrapper.currentTime);
        end
    end
end

function LTMaster:updateWrapper(dt)
    if self.firstTimeRun then
        if self.LTMaster.wrapper.baleToLoad ~= nil then
            local v = self.LTMaster.wrapper.baleToLoad;
            self.LTMaster.wrapper.baleToLoad = nil;
            local baleObject = Bale:new(self.isServer, self.isClient);
            local x, y, z = unpack(v.translation);
            local rx, ry, rz = unpack(v.rotation);
            baleObject:load(v.filename, x, y, z, rx, ry, rz, v.fillLevel);
            if baleObject.nodeId ~= nil and baleObject.nodeId ~= 0 then
                self:playMoveToWrapper(baleObject);
                baleObject.baleValueScale = v.baleValueScale;
                local wrapperState = math.min(v.wrapperTime / self.LTMaster.wrapper.currentWrapper.animTime, 1);
                baleObject:setWrappingState(wrapperState);
                baleObject:mount(self, self.LTMaster.wrapper.currentWrapper.baleNode, x, y, z, rx, ry, rz)
                baleObject:register();
                self:doStateChange(BaleWrapper.CHANGE_WRAPPING_START);
                self.LTMaster.wrapper.currentWrapper.currentBale = networkGetObjectId(baleObject);
                self.LTMaster.wrapper.currentWrapper.currentTime = v.wrapperTime;
                self:updateWrappingState(self.LTMaster.wrapper.currentWrapper.currentTime / self.LTMaster.wrapper.currentWrapper.animTime);
            end
        end
        if self.LTMaster.wrapper.baleToMount ~= nil then
            local bale = networkGetObject(self.LTMaster.wrapper.baleToMount.serverId);
            if bale ~= nil then
                local x, y, z = unpack(self.LTMaster.wrapper.baleToMount.trans);
                local rx, ry, rz = unpack(self.LTMaster.wrapper.baleToMount.rot);
                bale:mount(self, self.LTMaster.wrapper.baleToMount.linkNode, x, y, z, rx, ry, rz);
                self.LTMaster.wrapper.baleToMount = nil;
                if self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                    self:playMoveToWrapper(bale)
                end
            end
        end
    end
    if self:getIsActiveForInput() then
        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
            g_client:getServerConnection():sendEvent(WrapperChangeStatus:new(not self.LTMaster.wrapper.enabled, self));
        end
    end
    if self:getIsActive() then
        if self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
            if self.isClient then
                if not self.LTMaster.wrapper.currentWrapperSound.isPlaying then
                    if self.LTMaster.wrapper.currentWrapperStartSound.sample == nil or not SoundUtil.isSamplePlaying(self.LTMaster.wrapper.currentWrapperStartSound, 1.8 * dt) then
                        Sound3DUtil:playSample(self.LTMaster.wrapper.currentWrapperSound, 0, 0, nil, self:getIsActiveForSound());
                    end
                end
            end
            self.LTMaster.wrapper.currentWrapper.currentTime = self.LTMaster.wrapper.currentWrapper.currentTime + dt;
            self:updateWrappingState(self.LTMaster.wrapper.currentWrapper.currentTime / self.LTMaster.wrapper.currentWrapper.animTime);
        end
    end
    if self.isServer then
        if self.LTMaster.wrapper.baleWrapperState ~= nil and self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
            self:doStateChange(BaleWrapper.CHANGE_BUTTON_EMPTY);
        end
    end
end

function LTMaster:updateTickWrapper(dt)
    if self.LTMaster.wrapper.balesFoil.numFoilNodes > 0 then
        local level = self:getUnitFillLevel(self.LTMaster.fillUnits["balesFoil"].index);
        for i = 1, self.LTMaster.wrapper.balesFoil.numFoilNodes do
            setVisibility(self.LTMaster.wrapper.balesFoil.foilNodes[i], i <= level);
        end
    end
    if self.LTMaster.wrapper.balesFoil.outOfFoilRolls then
        setVisibility(self.LTMaster.wrapper.balesFoil.leftFoilRollIndex, false);
        setVisibility(self.LTMaster.wrapper.balesFoil.leftFoilIndex, false);
        setVisibility(self.LTMaster.wrapper.balesFoil.rightFoilRollIndex, false);
        setVisibility(self.LTMaster.wrapper.balesFoil.rightFoilIndex, false);
    else
        setVisibility(self.LTMaster.wrapper.balesFoil.leftFoilRollIndex, true);
        setVisibility(self.LTMaster.wrapper.balesFoil.leftFoilIndex, true);
        setVisibility(self.LTMaster.wrapper.balesFoil.rightFoilRollIndex, true);
        setVisibility(self.LTMaster.wrapper.balesFoil.rightFoilIndex, true);
        local percent = self.LTMaster.wrapper.balesFoil.foilRollMinScale + (1 - self.LTMaster.wrapper.balesFoil.foilRollMinScale) * (self.LTMaster.wrapper.balesFoil.foilRollRemainingUses / self.LTMaster.wrapper.balesFoil.foilRollUses);
        setScale(self.LTMaster.wrapper.balesFoil.leftFoilRollIndex, percent, 1, percent);
        setScale(self.LTMaster.wrapper.balesFoil.rightFoilRollIndex, percent, 1, percent);
    end
    if self:getIsActive() then
        if self.isServer then
            if self.LTMaster.wrapper.baleWrapperState ~= BaleWrapper.STATE_NONE then
                if self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                    if not self:getIsAnimationPlaying(self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].animName) then
                        g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER), true, nil, self);
                    end
                elseif self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
                    if not self:getIsAnimationPlaying(self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].animName) then
                        local bale = networkGetObject(self.LTMaster.wrapper.currentWrapper.currentBale);
                        if not self.LTMaster.wrapper.enabled and not self.LTMaster.wrapper.mustWrappedBales[bale:getFillType()] then
                            g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self);
                        elseif not self.LTMaster.wrapper.balesFoil.outOfFoilRolls then
                            g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPING_START), true, nil, self);
                        end
                    end
                elseif self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_DROPPING_BALE then
                    if not self:getIsAnimationPlaying(self.LTMaster.wrapper.currentWrapper.animations["dropFromWrapper"].animName) then
                        g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED), true, nil, self);
                    end
                elseif self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
                    if not self:getIsAnimationPlaying(self.LTMaster.wrapper.currentWrapper.animations["resetAfterDrop"].animName) then
                        g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET), true, nil, self);
                    end
                end
            end
        end
    end
    if self.isServer then
        if self.LTMaster.wrapper.balesFoil.foilRollRemainingUses <= 0 then
            local fillLevel = self:getUnitFillLevel(self.LTMaster.fillUnits["balesFoil"].index);
            if fillLevel > 1 then
                self.LTMaster.wrapper.balesFoil.outOfFoilRolls = false;
                self.LTMaster.wrapper.balesFoil.foilRollRemainingUses = self.LTMaster.wrapper.balesFoil.foilRollUses;
                self:setUnitFillLevel(self.LTMaster.fillUnits["balesFoil"].index, fillLevel - 2, FillUtil.FILLTYPE_BALESFOIL, true);
            else
                self.LTMaster.wrapper.balesFoil.outOfFoilRolls = true;
            end
        end
    end
    if self.isClient and self:getIsActive() and self:getIsTurnedOn() then
        if self.LTMaster.wrapper.balesFoil.outOfFoilRolls then
            if self.LTMaster.wrapper.enabled then
                Sound3DUtil:playSample(self.LTMaster.wrapper.sampleOutOfFoil, 0, 0, nil, self:getIsActiveForSound());
            else
                local bale = networkGetObject(self.LTMaster.wrapper.currentWrapper.currentBale);
                if bale ~= nil and self.LTMaster.wrapper.mustWrappedBales[bale:getFillType()] then
                    Sound3DUtil:playSample(self.LTMaster.wrapper.sampleOutOfFoil, 0, 0, nil, self:getIsActiveForSound());
                else
                    Sound3DUtil:stopSample(self.LTMaster.wrapper.sampleOutOfFoil);
                end
            end
        else
            Sound3DUtil:stopSample(self.LTMaster.wrapper.sampleOutOfFoil);
        end
    end
    if self.isFilling and self.fillTrigger ~= nil and self.fillTrigger.fillType == FillUtil.FILLTYPE_BALESFOIL then
        if self.isClient then
            Sound3DUtil:playSample(self.LTMaster.wrapper.balesFoil.sampleFill, 0, 0, nil, self:getIsActiveForSound());
        end
        self.fillLitersPerSecond = self.LTMaster.wrapper.balesFoil.fillLitersPerSecond;
    else
        if self.isClient then
            Sound3DUtil:stopSample(self.LTMaster.wrapper.balesFoil.sampleFill);
        end
    end
end

function LTMaster:drawWrapper()
    if self.isClient then
        if self:getIsActiveForInput(true) then
            if self.LTMaster.wrapper.enabled then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_WRAPPER_SET_OFF"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH);
            else
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_WRAPPER_SET_ON"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH);
            end
        end
    end
end

function LTMaster:onDeactivateWrapper()
end

function LTMaster:onDeactivateSoundsWrapper()
    if self.isClient then
        Sound3DUtil:stopSample(self.LTMaster.wrapper.currentWrapperStartSound, true);
        Sound3DUtil:stopSample(self.LTMaster.wrapper.currentWrapperStopSound, true);
        Sound3DUtil:stopSample(self.LTMaster.wrapper.currentWrapperSound, true);
        Sound3DUtil:stopSample(self.LTMaster.wrapper.sampleOutOfFoil, true);
    end
end

function LTMaster:allowsGrabbingBale()
    return self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_NONE;
end

function LTMaster:updateWrapNodes(isWrapping, isEmpty, t, wrapperRot)
    if wrapperRot == nil then
        wrapperRot = 0;
    end
    for _, wrapNode in pairs(self.LTMaster.wrapper.currentWrapper.wrapNodes) do
        local doShow = true;
        if wrapNode.maxWrapperRot ~= nil then
            doShow = wrapperRot < wrapNode.maxWrapperRot;
        end
        setVisibility(wrapNode.nodeId, doShow and ((isWrapping and wrapNode.wrapVisibility) or (isEmpty and wrapNode.emptyVisibility)));
    end
    if isWrapping then
        local wrapperRotRepeat = Utils.sign(wrapperRot) * (wrapperRot % math.pi);
        if wrapperRotRepeat < 0 then
            wrapperRotRepeat = wrapperRotRepeat + math.pi;
        end
        for _, wrapAnimNode in pairs(self.LTMaster.wrapper.currentWrapper.wrapAnimNodes) do
            local v;
            if wrapAnimNode.useWrapperRot then
                local rot = wrapperRot;
                if wrapAnimNode.repeatWrapperRot then
                    rot = wrapperRotRepeat;
                end
                v = wrapAnimNode.animCurve:get(rot);
            else
                v = wrapAnimNode.animCurve:get(t);
            end
            if v ~= nil then
                setTranslation(wrapAnimNode.nodeId, v[1], v[2], v[3]);
                setRotation(wrapAnimNode.nodeId, v[4], v[5], v[6]);
                setScale(wrapAnimNode.nodeId, v[7], v[8], v[9]);
            end
        end
    else
        if not isEmpty then
            for _, wrapAnimNode in pairs(self.LTMaster.wrapper.currentWrapper.wrapAnimNodes) do
                if wrapAnimNode.normalizeRotationOnBaleDrop ~= 0 then
                    local rot = {getRotation(wrapAnimNode.nodeId)};
                    for i = 1, 3 do
                        rot[i] = wrapAnimNode.normalizeRotationOnBaleDrop * Utils.sign(rot[i]) * (rot[i] % (2 * math.pi));
                    end
                    setRotation(wrapAnimNode.nodeId, rot[1], rot[2], rot[3]);
                end
            end
        end
    end
end

function LTMaster:updateWrappingState(t, noEventSend)
    t = math.min(t, 1);
    local wrapperRot = 0;
    if self.LTMaster.wrapper.currentWrapper.animCurve ~= nil then
        local v = self.LTMaster.wrapper.currentWrapper.animCurve:get(t);
        if v ~= nil then
            setRotation(self.LTMaster.wrapper.currentWrapper.baleNode, v[1] % (math.pi * 2), v[2] % (math.pi * 2), v[3] % (math.pi * 2));
            setRotation(self.LTMaster.wrapper.currentWrapper.wrapperNode, v[4] % (math.pi * 2), v[5] % (math.pi * 2), v[6] % (math.pi * 2));
            wrapperRot = v[3 + self.LTMaster.wrapper.currentWrapper.wrapperRotAxis];
        elseif self.LTMaster.wrapper.currentWrapper.animations["wrapBale"].animName ~= nil then
            t = self:getAnimationTime(self.LTMaster.wrapper.currentWrapper.animations["wrapBale"].animName);
        end
        if self.LTMaster.wrapper.currentWrapper.currentBale ~= nil and self.isServer then
            local bale = networkGetObject(self.LTMaster.wrapper.currentWrapper.currentBale);
            if bale ~= nil then
                bale:setWrappingState(t);
            end
        end
    end
    self:updateWrapNodes(t > 0, false, t, wrapperRot);
    if t == 1 then
        if self.isServer and self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE and not noEventSend then
            g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED), true, nil, self);
        end
    end
end

function LTMaster:moveBaleToWrapper(bale)
    local baleType = self:getWrapperBaleType(bale);
    self:pickupWrapperBale(bale, baleType);
end

function LTMaster:playMoveToWrapper(bale)
    self.LTMaster.wrapper.currentWrapper = self.roundBaleWrapper;
    if bale.baleDiameter == nil then
        self.LTMaster.wrapper.currentWrapper = self.squareBaleWrapper;
    end
    if self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].animName ~= nil then
        self:playAnimation(self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].animName, self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].animSpeed, nil, true);
    end
end

function LTMaster:doStateChange(id, nearestBaleServerId)
    if id == BaleWrapper.CHANGE_GRAB_BALE then
        local bale = networkGetObject(nearestBaleServerId);
        self.LTMaster.wrapper.baleGrabber.currentBale = nearestBaleServerId;
        if bale ~= nil then
            local x, y, z = localToLocal(bale.nodeId, getParent(self.LTMaster.wrapper.baleGrabber.grabNode), 0, 0, 0);
            setTranslation(self.LTMaster.wrapper.baleGrabber.grabNode, x, y, z);
            self.LTMaster.wrapper.baleToMount = nil;
            self:playMoveToWrapper(bale);
        else
            self.LTMaster.wrapper.baleToMount = {serverId = nearestBaleServerId, linkNode = self.LTMaster.wrapper.baleGrabber.grabNode, trans = {0, 0, 0}, rot = {0, 0, 0}};
        end
        self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER;
    elseif id == BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER then
        local attachNode = self.LTMaster.wrapper.currentWrapper.baleNode;
        local bale = networkGetObject(self.LTMaster.wrapper.baleGrabber.currentBale);
        if bale ~= nil then
            bale:mount(self, attachNode, 0, 0, 0, 0, 0, 0);
            self.LTMaster.wrapper.baleToMount = nil;
        else
            self.LTMaster.wrapper.baleToMount = {serverId = self.LTMaster.wrapper.baleGrabber.currentBale, linkNode = attachNode, trans = {0, 0, 0}, rot = {0, 0, 0}};
        end
        self:updateWrapNodes(true, false, 0);
        self.LTMaster.wrapper.currentWrapper.currentBale = self.LTMaster.wrapper.baleGrabber.currentBale;
        self.LTMaster.wrapper.baleGrabber.currentBale = nil;
        if self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].animName ~= nil then
            if self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].reverseAfterMove then
                self:playAnimation(self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].animName, -self.LTMaster.wrapper.currentWrapper.animations["moveToWrapper"].animSpeed, nil, true);
            end
        end
        self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_MOVING_GRABBER_TO_WORK;
    elseif id == BaleWrapper.CHANGE_WRAPPING_START then
        self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_WRAPPER_WRAPPING_BALE;
        if self.isClient then
            Sound3DUtil:playSample(self.LTMaster.wrapper.currentWrapperStartSound, 1, 0, nil, self:getIsActiveForSound());
        end
        if self.LTMaster.wrapper.currentWrapper.animations["wrapBale"].animName ~= nil then
            self:playAnimation(self.LTMaster.wrapper.currentWrapper.animations["wrapBale"].animName, self.LTMaster.wrapper.currentWrapper.animations["wrapBale"].animSpeed, nil, true);
        end
    elseif id == BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED then
        if self.isClient then
            Sound3DUtil:stopSample(self.LTMaster.wrapper.currentWrapperSound);
            if self.isClient then
                Sound3DUtil:playSample(self.LTMaster.wrapper.currentWrapperStopSound, 1, 0, nil, self:getIsActiveForSound());
            end
        end
        self:updateWrappingState(1, true);
        if self.isServer then
            self.LTMaster.wrapper.balesFoil.foilRollRemainingUses = self.LTMaster.wrapper.balesFoil.foilRollRemainingUses - 1;
            self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_WRAPPER_FINSIHED;
        end
    elseif id == BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE then
        self:updateWrapNodes(false, true, 0);
        if self.LTMaster.wrapper.currentWrapper.animations["dropFromWrapper"].animName ~= nil then
            self:playAnimation(self.LTMaster.wrapper.currentWrapper.animations["dropFromWrapper"].animName, self.LTMaster.wrapper.currentWrapper.animations["dropFromWrapper"].animSpeed, nil, true);
        end
        self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_WRAPPER_DROPPING_BALE;
    elseif id == BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED then
        local bale = networkGetObject(self.LTMaster.wrapper.currentWrapper.currentBale);
        if bale ~= nil then
            bale:unmount();
        end
        self.lastDroppedBale = bale;
        self.LTMaster.wrapper.currentWrapper.currentBale = nil;
        self.LTMaster.wrapper.currentWrapper.currentTime = 0;
        if self.LTMaster.wrapper.currentWrapper.animations["resetAfterDrop"].animName ~= nil then
            self:playAnimation(self.LTMaster.wrapper.currentWrapper.animations["resetAfterDrop"].animName, self.LTMaster.wrapper.currentWrapper.animations["resetAfterDrop"].animSpeed, nil, true);
        end
        self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM;
        self.LTMaster.baler.createdBales = self.LTMaster.baler.createdBales + 0.000001;
    elseif id == BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET then
        self:updateWrappingState(0);
        self:updateWrapNodes(false, true, 0);
        self.LTMaster.wrapper.baleWrapperState = BaleWrapper.STATE_NONE;
    elseif id == BaleWrapper.CHANGE_BUTTON_EMPTY then
        assert(self.isServer);
        if self.LTMaster.wrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
            g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self);
        end
    end
    -- Seasons support
    if g_seasons ~= nil then
        if self.isServer then
            if id == BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED and self.lastDroppedBale ~= nil then
                local bale = self.lastDroppedBale;
                if bale:getFillType() == FillUtil.FILLTYPE_SILAGE and bale.wrappingState >= 1 then
                    --initiate fermenting process
                    bale:setFillType(Utils.getNoNil(self.baleFillTypeSource, FillUtil.FILLTYPE_GRASS_WINDROW));
                    bale.fermentingProcess = 0;
                    ssLTMasterBaleFermentEvent:sendEvent(bale);
                end
                self.baleFillTypeSource = nil;
            end
        end
    end
end

function LTMaster:setIsUnloadingBale(isUnloadingBale, noEventSend)
    if self.baler ~= nil and self.baler.baleUnloadAnimationName ~= nil then
        if isUnloadingBale then
            if self.baleWrapperUnloadingState ~= BaleWrapper.UNLOADING_OPENING then
                BaleWrapperSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend);
                self.baleWrapperUnloadingState = BaleWrapper.UNLOADING_OPENING;
                self:playAnimation(self.baler.baleUnloadAnimationName, self.baler.baleUnloadAnimationSpeed, nil, true);
            end
        else
            if self.baleWrapperUnloadingState ~= BaleWrapper.UNLOADING_CLOSING then
                BaleWrapperSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend);
                self.baleWrapperUnloadingState = BaleWrapper.UNLOADING_CLOSING;
                self:playAnimation(self.baler.baleCloseAnimationName, self.baler.baleCloseAnimationSpeed, nil, true);
            end
        end
    end
end

function LTMaster:getWrapperBaleType(bale)
    local baleTypes;
    if bale.baleDiameter ~= nil then
        baleTypes = self.roundBaleWrapper.allowedBaleTypes[bale:getFillType()];
    else
        baleTypes = self.squareBaleWrapper.allowedBaleTypes[bale:getFillType()];
    end
    if baleTypes ~= nil then
        for _, baleType in pairs(baleTypes) do
            if bale.baleDiameter ~= nil and bale.baleWidth ~= nil then
                if bale.baleDiameter >= baleType.minBaleDiameter and bale.baleDiameter <= baleType.maxBaleDiameter and
                    bale.baleWidth >= baleType.minBaleWidth and bale.baleWidth <= baleType.maxBaleWidth
                then
                    return baleType;
                end
            elseif bale.baleHeight ~= nil and bale.baleWidth ~= nil and bale.baleLength ~= nil then
                if bale.baleHeight >= baleType.minBaleHeight and bale.baleHeight <= baleType.maxBaleHeight and
                    bale.baleWidth >= baleType.minBaleWidth and bale.baleWidth <= baleType.maxBaleWidth and
                    bale.baleLength >= baleType.minBaleLength and bale.baleLength <= baleType.maxBaleLength
                then
                    return baleType;
                end
            end
        end
    end
    return nil;
end

function LTMaster:pickupWrapperBale(bale, baleType)
    -- Seasons support
    if g_seasons ~= nil then
        self.baleFillTypeSource = bale:getFillType();
    end
    if baleType ~= nil and bale.i3dFilename ~= baleType.wrapperBaleFilename and bale.supportsWrapping then
        local x, y, z = getWorldTranslation(bale.nodeId);
        local rx, ry, rz = getWorldRotation(bale.nodeId);
        local fillLevel = bale.fillLevel;
        local baleValueScale = bale.baleValueScale;
        bale:delete();
        bale = Bale:new(self.isServer, self.isClient);
        bale:load(baleType.wrapperBaleFilename, x, y, z, rx, ry, rz, fillLevel);
        bale.baleValueScale = baleValueScale;
        bale:register();
    end
    g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_GRAB_BALE, networkGetObjectId(bale)), true, nil, self);
end

function LTMaster:getIsFoldAllowed(superFunc, onAiTurnOn)
    if self.LTMaster.wrapper.baleWrapperState ~= BaleWrapper.STATE_NONE then
        return false;
    end
    if superFunc ~= nil then
        return superFunc(self, onAiTurnOn);
    end
    return true;
end

function LTMaster:getWrappedBales()
    return self.LTMaster.wrapper.wrappedBales * 1000000;
end
