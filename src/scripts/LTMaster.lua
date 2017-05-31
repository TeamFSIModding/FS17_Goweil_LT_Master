--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--18/04/2017
LTMaster = {};
LTMaster.debug = true;

LTMaster.g_i18n = {};
LTMaster.g_i18n["shop_messagePurchaseReady"] = g_i18n:getText("shop_messagePurchaseReady");
LTMaster.g_i18n["shop_messageLeasingReady"] = g_i18n:getText("shop_messageLeasingReady");
function LTMaster.onVehicleBoughtCallback()
    g_i18n.globalI18N:setText("shop_messagePurchaseReady", LTMaster.g_i18n["shop_messagePurchaseReady"]);
    g_i18n.globalI18N:setText("shop_messageLeasingReady", LTMaster.g_i18n["shop_messageLeasingReady"]);
end
g_shopScreen.onVehicleBoughtCallback = Utils.appendedFunction(g_shopScreen.onVehicleBoughtCallback, LTMaster.onVehicleBoughtCallback);

LTMaster.STATUS_OC_OPEN = 1;
LTMaster.STATUS_OC_OPENING = 2;
LTMaster.STATUS_OC_CLOSED = 3;
LTMaster.STATUS_OC_CLOSING = 4;

LTMaster.STATUS_RL_LOWERED = 1;
LTMaster.STATUS_RL_LOWERING = 2;
LTMaster.STATUS_RL_RAISED = 3;
LTMaster.STATUS_RL_RAISING = 4;

LTMaster.STATUS_FU_UNFOLDED = 1;
LTMaster.STATUS_FU_UNFOLDING = 2;
LTMaster.STATUS_FU_FOLDED = 3;
LTMaster.STATUS_FU_FOLDING = 4;

source(g_currentModDirectory .. "scripts/LTMaster.animations.lua");
source(g_currentModDirectory .. "scripts/LTMaster.baler.lua");
source(g_currentModDirectory .. "scripts/LTMaster.wrapper.lua");
source(g_currentModDirectory .. "scripts/LTMaster.wrkmove.lua");
source(g_currentModDirectory .. "scripts/LTMaster.hud.lua");
source(g_currentModDirectory .. "scripts/events/hoodStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/supportsStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/foldingStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/ladderStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/baleSlideStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/sideUnloadEvent.lua");
source(g_currentModDirectory .. "scripts/events/conveyorStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/balerCreateBaleEvent.lua");
source(g_currentModDirectory .. "scripts/events/balerChangeVolumeEvent.lua");
source(g_currentModDirectory .. "scripts/events/wrapperChangeStatus.lua");
source(g_currentModDirectory .. "scripts/events/balerSetIsUnloadingBaleEvent.lua");

function LTMaster.print(text, ...)
    if LTMaster.debug then
        local start = string.format("[%s(%s)] -> ", "LTMaster", getDate("%H:%M:%S"));
        local ptext = string.format(text, ...);
        print(string.format("%s%s", start, ptext));
    end
end

function LTMaster.prerequisitesPresent(specializations)
    return true;
end

function LTMaster:preLoad(savegame)
    self.updateHoodStatus = LTMaster.updateHoodStatus;
    self.updateSupportsStatus = LTMaster.updateSupportsStatus;
    self.updateFoldingStatus = LTMaster.updateFoldingStatus;
    self.updateLadderStatus = LTMaster.updateLadderStatus;
    self.updateBaleSlideStatus = LTMaster.updateBaleSlideStatus;
    self.unloadSide = LTMaster.unloadSide;
    self.setConveyorStatus = LTMaster.setConveyorStatus;
    self.getIsConveyorOverloading = LTMaster.getIsConveyorOverloading;
    if self.isServer then
        if savegame == nil then
            self.tempHelpInfoText = g_i18n:getText("GLTM_TEMP_INFO");
        end
    end
end

function LTMaster:load(savegame)
    self.applyInitialAnimation = Utils.overwrittenFunction(self.applyInitialAnimation, LTMaster.applyInitialAnimation);
    self.getIsTurnedOnAllowed = Utils.overwrittenFunction(self.getIsTurnedOnAllowed, LTMaster.getIsTurnedOnAllowed);
    self.getTurnedOnNotAllowedWarning = Utils.overwrittenFunction(self.getTurnedOnNotAllowedWarning, LTMaster.getTurnedOnNotAllowedWarning);
    self.getConsumedPtoTorque = Utils.overwrittenFunction(self.getConsumedPtoTorque, LTMaster.getConsumedPtoTorque);
    self.getPtoRpm = Utils.overwrittenFunction(self.getPtoRpm, LTMaster.getPtoRpm);
    self.getIsFoldAllowed = Utils.overwrittenFunction(self.getIsFoldAllowed, LTMaster.getIsFoldAllowed);
    self.getDirtMultiplier = Utils.overwrittenFunction(self.getDirtMultiplier, LTMaster.getDirtMultiplier);
    self.getIsPowerTakeoffActive = Utils.overwrittenFunction(self.getIsPowerTakeoffActive, LTMaster.getIsPowerTakeoffActive);
    
    self.LTMaster = {};
    self.LTMaster.ptoRotSpeed = 0;
    self.LTMaster.manureLock = false;
    
    self.LTMaster.unloadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster#unloadInfoIndex"), 1);
    self.LTMaster.loadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster#loadInfoIndex"), 1);
    --self.LTMaster.baler.dischargeInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler#dischargeInfoIndex"), 1);
    self.LTMaster.fillUnits = {};
    self.LTMaster.fillUnits["main"] = {};
    self.LTMaster.fillUnits["main"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.triggers.tipTrigger#fillUnitIndex"), 1);
    self.LTMaster.fillUnits["right"] = {};
    self.LTMaster.fillUnits["right"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.triggers.tipTrigger#rightFillUnitIndex"), 2);
    self.LTMaster.fillUnits["right"].unloadSpeed = 0;
    self.LTMaster.fillUnits["left"] = {};
    self.LTMaster.fillUnits["left"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.triggers.tipTrigger#leftFillUnitIndex"), 3);
    self.LTMaster.fillUnits["left"].unloadSpeed = 0;
    self.LTMaster.fillUnits["baler"] = {};
    self.LTMaster.fillUnits["baler"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler#fillUnitIndex"), 4);
    self.LTMaster.fillUnits["silageAdditive"] = {};
    self.LTMaster.fillUnits["silageAdditive"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.silageAdditive#fillUnitIndex"), 5);
    self.LTMaster.fillUnits["balesNet"] = {};
    self.LTMaster.fillUnits["balesNet"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler.balesNet#fillUnitIndex"), 6);
    self.LTMaster.fillUnits["balesFoil"] = {};
    self.LTMaster.fillUnits["balesFoil"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.wrapper.balesFoil#fillUnitIndex"), 7);
    
    self.LTMaster.conveyor = {};
    if self.isClient then
        self.LTMaster.turnedOnRotationNodes = Utils.loadRotationNodes(self.xmlFile, {}, "vehicle.LTMaster.turnedOnRotationNodes.rotatingPart", "LTMaster.turnedOn", self.components);
        self.LTMaster.conveyor.effects = EffectManager:loadEffect(self.xmlFile, "vehicle.LTMaster.conveyor.effects", self.components, self);
        self.LTMaster.conveyor.unloadEffects = EffectManager:loadEffect(self.xmlFile, "vehicle.LTMaster.conveyor.unloadEffects", self.components, self);
        self.LTMaster.conveyor.uvScrollParts = Utils.loadScrollers(self.components, self.xmlFile, "vehicle.LTMaster.conveyor.uvScrollParts.uvScrollPart", {}, false);
        self.LTMaster.conveyor.rotatingParts = Utils.loadRotationNodes(self.xmlFile, {}, "vehicle.LTMaster.conveyor.rotatingParts.rotatingPart", "LTMaster.conveyor", self.components);
        self.LTMaster.conveyor.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.conveyor.sound", nil, self.baseDirectory, self.components[1].node);
        self.LTMaster.conveyor.unloadParticleSystems = {};
        local i = 0;
        while true do
            local key = string.format("vehicle.LTMaster.conveyor.unloadParticleSystems.emitterShape(%d)", i);
            if not hasXMLProperty(self.xmlFile, key) then
                break;
            end
            local emitterShape = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"));
            local particleType = getXMLString(self.xmlFile, key .. "#particleType");
            if emitterShape ~= nil then
                for fillType, _ in pairs(self:getUnitFillTypes(self.LTMaster.fillUnits["main"].index)) do
                    local particleSystem = MaterialUtil.getParticleSystem(fillType, particleType);
                    if particleSystem ~= nil then
                        if self.LTMaster.conveyor.unloadParticleSystems[fillType] == nil then
                            self.LTMaster.conveyor.unloadParticleSystems[fillType] = {};
                        end
                        local currentPS = ParticleUtil.copyParticleSystem(self.xmlFile, key, particleSystem, emitterShape);
                        table.insert(self.LTMaster.conveyor.unloadParticleSystems[fillType], currentPS);
                    end
                end
            end
            i = i + 1;
        end
        self.LTMaster.conveyor.augerParticleSystems = {};
        local i = 0;
        while true do
            local key = string.format("vehicle.LTMaster.conveyor.augerParticleSystems.emitterShape(%d)", i);
            if not hasXMLProperty(self.xmlFile, key) then
                break;
            end
            local emitterShape = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"));
            local particleType = getXMLString(self.xmlFile, key .. "#particleType");
            if emitterShape ~= nil then
                for fillType, _ in pairs(self:getUnitFillTypes(self.LTMaster.fillUnits["main"].index)) do
                    local particleSystem = MaterialUtil.getParticleSystem(fillType, particleType);
                    if particleSystem ~= nil then
                        if self.LTMaster.conveyor.augerParticleSystems[fillType] == nil then
                            self.LTMaster.conveyor.augerParticleSystems[fillType] = {};
                        end
                        table.insert(self.LTMaster.conveyor.augerParticleSystems[fillType], ParticleUtil.copyParticleSystem(self.xmlFile, key, particleSystem, emitterShape));
                    end
                end
            end
            i = i + 1;
        end
    end
    self.LTMaster.conveyor.overloadingCapacity = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.conveyor#overloadingCapacity"), 100);
    --self.LTMaster.conveyor.overloadingDelay = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.conveyor#overloadingDelay"), 3);
    self.LTMaster.conveyor.isOverloading = false;
    
    self.LTMaster.sideUnload = {};
    self.LTMaster.sideUnload.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.sideUnload#animationName");
    self.LTMaster.sideUnload.maxAmount = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.sideUnload#maxAmount"), 0);
    self.LTMaster.sideUnload.isUnloading = false;
    
    local trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#index"));
    self.LTMaster.triggerLeft = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#index"));
    self.LTMaster.triggerRight = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLadder#index"));
    self.LTMaster.triggerLadder = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerLadder#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerBaleSlide#index"));
    self.LTMaster.triggerBaleSlide = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerBaleSlide#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.tipTrigger#index"));
    self.LTMaster.tipTrigger = LTMasterTipTrigger:new(self.isServer, self.isClient);
    self.LTMaster.tipTrigger:load(trigger, self, self.LTMaster.fillUnits["main"].index, self.LTMaster.fillUnits["right"].index, self.LTMaster.fillUnits["left"].index, self.LTMaster.loadInfoIndex);
    self.LTMaster.tipTrigger:register(true);
    
    self.LTMaster.hoods = {};
    self.LTMaster.hoods.openingSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.hoods.openingSound", nil, self.baseDirectory, self.components[1].node);
    self.LTMaster.hoods.closingSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.hoods.closingSound", nil, self.baseDirectory, self.components[1].node);
    self.LTMaster.hoods.delayedUpdateHoodStatus = DelayedCallBack:new(LTMaster.updateHoodStatus, self);
    self.LTMaster.hoods["left"] = {};
    self.LTMaster.hoods["left"].name = "left";
    self.LTMaster.hoods["left"].animation = getXMLString(self.xmlFile, "vehicle.LTMaster.hoods.leftDoor#animationName");
    self.LTMaster.hoods["left"].status = LTMaster.STATUS_OC_CLOSED;
    
    self.LTMaster.hoods["right"] = {};
    self.LTMaster.hoods["right"].name = "right";
    self.LTMaster.hoods["right"].animation = getXMLString(self.xmlFile, "vehicle.LTMaster.hoods.rightDoor#animationName");
    self.LTMaster.hoods["right"].status = LTMaster.STATUS_OC_CLOSED;
    
    self.LTMaster.supports = {};
    self.LTMaster.supports.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.supports#animationName");
    self.LTMaster.supports.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.supports.delayedUpdateSupportsStatus = DelayedCallBack:new(LTMaster.updateSupportsStatus, self);
    self.LTMaster.supports.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.supports.sound", nil, self.baseDirectory, self.components[1].node);
    
    self.LTMaster.folding = {};
    self.LTMaster.folding.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.folding#animationName");
    self.LTMaster.folding.status = LTMaster.STATUS_FU_FOLDED;
    self.LTMaster.folding.delayedUpdateFoldingStatus = DelayedCallBack:new(LTMaster.updateFoldingStatus, self);
    self.LTMaster.folding.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.folding.sound", nil, self.baseDirectory, self.components[1].node);
    
    self.LTMaster.ladder = {};
    self.LTMaster.ladder.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.ladder#animationName");
    self.LTMaster.ladder.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.ladder.delayedUpdateLadderStatus = DelayedCallBack:new(LTMaster.updateLadderStatus, self);
    self.LTMaster.ladder.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.ladder.sound", nil, self.baseDirectory, self.components[1].node);
    
    self.LTMaster.baleSlide = {};
    self.LTMaster.baleSlide.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.baleSlide#animationName");
    self.LTMaster.baleSlide.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.baleSlide.delayedUpdateBaleSlideStatus = DelayedCallBack:new(LTMaster.updateBaleSlideStatus, self);
    self.LTMaster.baleSlide.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baleSlide.sound", nil, self.baseDirectory, self.components[1].node);
    
    self.LTMaster.silageAdditive = {};
    self.LTMaster.silageAdditive.isUsing = false;
    self.LTMaster.silageAdditive.gain = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.silageAdditive#gain"), 1.1);
    self.LTMaster.silageAdditive.usage = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.silageAdditive#usage"), 0.001);
    local fillTypeNames = getXMLString(self.xmlFile, "vehicle.LTMaster.silageAdditive#fillTypes");
    self.LTMaster.silageAdditive.fillTypes = FillUtil.getFillTypesByNames(fillTypeNames);
    self.LTMaster.silageAdditive.acceptedFillTypes = {};
    if self.LTMaster.silageAdditive.fillTypes ~= nil then
        for _, fillType in pairs(self.LTMaster.silageAdditive.fillTypes) do
            self.LTMaster.silageAdditive.acceptedFillTypes[fillType] = true;
        end
    end
    self.LTMaster.silageAdditive.fillType = FillUtil.FILLTYPE_SILAGEADDITIVE;
    if self.isClient then
        self.LTMaster.silageAdditive.effects = EffectManager:loadEffect(self.xmlFile, "vehicle.LTMaster.silageAdditive.effects", self.components, self);
        self.LTMaster.silageAdditive.sampleFill = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.silageAdditive.fillSound", nil, self.baseDirectory, self.components[1].node);
    end
    self.LTMaster.silageAdditive.fillLitersPerSecond = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.silageAdditive#fillLitersPerSecond"), 20);
    if self.configurations["silageAdditiveSystem"] == 1 then
        self.LTMaster.silageAdditive.enabled = false;
        self:setUnitCapacity(self.LTMaster.fillUnits["silageAdditive"].index, 0);
    else
        self.LTMaster.silageAdditive.enabled = true;
    end
    
    self.LTMaster.greasePump = {};
    self.LTMaster.greasePump.delay = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.greasePump#delay"), 120) * 1000;
    self.LTMaster.greasePump.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.greasePump.sound", nil, self.baseDirectory, self.components[1].node);
    self.LTMaster.greasePump.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.greasePump#animationName");
    self.LTMaster.greasePump.next = g_currentMission.time + self.LTMaster.greasePump.delay;
    
    ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.silageAdditiveSystemConfigurations.silageAdditiveSystemConfiguration", self.configurations["silageAdditiveSystem"], self.components, self);
    ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.monitorSystemConfigurations.monitorSystemConfiguration", self.configurations["monitorSystem"], self.components, self);
    ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.remoteMonitorSystemConfigurations.remoteMonitorSystemConfiguration", self.configurations["remoteMonitorSystem"], self.components, self);
    
    self.LTMaster.conveyor.overloadingCapacity = 100 + (self.configurations["conveyorFlow"] * 100);
    
    self.LTMaster.vehicleRpmHud = VehicleHudUtils.loadHud(self, self.xmlFile, "vehicleRpm");
    self.LTMaster.productionHud = VehicleHudUtils.loadHud(self, self.xmlFile, "production");
    self.LTMaster.weightHud = VehicleHudUtils.loadHud(self, self.xmlFile, "weight");
    self.LTMaster.balePressureHud = VehicleHudUtils.loadHud(self, self.xmlFile, "balePressure");
    
    LTMaster.loadBaler(self, savegame);
    LTMaster.loadWrapper(self, savegame);
    LTMaster.loadWrkMove(self, savegame);
    LTMaster.loadHud(self, savegame);
end

function LTMaster:postLoad(savegame)
    LTMaster.postLoadBaler(self, savegame);
    LTMaster.postLoadWrapper(self, savegame);
    if self.isServer then
        if savegame ~= nil and not savegame.resetVehicles then
            self.LTMaster.hoods["left"].status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#leftHoodStatus"), self.LTMaster.hoods["left"].status);
            self.LTMaster.hoods["right"].status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#rightHoodStatus"), self.LTMaster.hoods["right"].status);
            self.LTMaster.supports.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#supportsStatus"), self.LTMaster.supports.status);
            self.LTMaster.folding.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#foldingStatus"), self.LTMaster.folding.status);
            self.LTMaster.ladder.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#ladderStatus"), self.LTMaster.ladder.status);
            self.LTMaster.baleSlide.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#baleSlideStatus"), self.LTMaster.baleSlide.status);
            self.LTMaster.manureLock = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#manureLock"), self.LTMaster.manureLock);
        elseif savegame == nil then
            if self.configurations["starterKit"] == 2 then
                if self.LTMaster.silageAdditive.enabled then
                    self:setUnitFillLevel(self.LTMaster.fillUnits["silageAdditive"].index, math.huge, FillUtil.FILLTYPE_SILAGEADDITIVE, true);
                end
                self:setUnitFillLevel(self.LTMaster.fillUnits["balesNet"].index, math.huge, FillUtil.FILLTYPE_BALESNET, true);
                self:setUnitFillLevel(self.LTMaster.fillUnits["balesFoil"].index, math.huge, FillUtil.FILLTYPE_BALESFOIL, true);
            end
            g_i18n.globalI18N:setText("shop_messagePurchaseReady", g_i18n:getText("shop_overwrite_messagePurchaseReady"));
            g_i18n.globalI18N:setText("shop_messageLeasingReady", g_i18n:getText("shop_overwrite_messageLeasingReady"));
        end
        LTMaster.finalizeLoad(self);
    end
end

function LTMaster:getSaveAttributesAndNodes(nodeIdent)
    local attributes = string.format("leftHoodStatus=\"%s\" rightHoodStatus=\"%s\" ", self.LTMaster.hoods["left"].status, self.LTMaster.hoods["right"].status);
    attributes = attributes .. string.format("supportsStatus=\"%s\" ", self.LTMaster.supports.status);
    attributes = attributes .. string.format("foldingStatus=\"%s\" ", self.LTMaster.folding.status);
    attributes = attributes .. string.format("ladderStatus=\"%s\" ", self.LTMaster.ladder.status);
    attributes = attributes .. string.format("baleSlideStatus=\"%s\" ", self.LTMaster.baleSlide.status);
    attributes = attributes .. string.format("manureLock=\"%s\" ", self.LTMaster.manureLock);
    local bAttributes, bNodes = LTMaster.getSaveAttributesAndNodesBaler(self, nodeIdent);
    local wAttributes = LTMaster.getSaveAttributesAndNodesWrapper(self, nodeIdent);
    return attributes .. " " .. bAttributes .. " " .. wAttributes, bNodes;
end

function LTMaster:finalizeLoad()
    self:updateHoodStatus(self.LTMaster.hoods["left"], nil, true);
    self:updateHoodStatus(self.LTMaster.hoods["right"], nil, true);
    self:updateSupportsStatus(self.LTMaster.supports.status, true);
    self:updateFoldingStatus(self.LTMaster.folding.status, true);
    self:updateLadderStatus(self.LTMaster.ladder.status, true);
    self:updateBaleSlideStatus(self.LTMaster.baleSlide.status, true);
    self:setBaleVolume(self.LTMaster.baler.baleVolumesIndex, true);
end

function LTMaster:delete()
    self.LTMaster.triggerLeft:delete();
    self.LTMaster.triggerRight:delete();
    self.LTMaster.triggerLadder:delete();
    self.LTMaster.triggerBaleSlide:delete();
    self.LTMaster.tipTrigger:delete();
    SoundUtil.deleteSample(self.LTMaster.hoods.openingSound);
    SoundUtil.deleteSample(self.LTMaster.hoods.closingSound);
    SoundUtil.deleteSample(self.LTMaster.supports.sound);
    SoundUtil.deleteSample(self.LTMaster.folding.sound);
    SoundUtil.deleteSample(self.LTMaster.ladder.sound);
    SoundUtil.deleteSample(self.LTMaster.baleSlide.sound);
    SoundUtil.deleteSample(self.LTMaster.greasePump.sound);
    if self.isClient then
        SoundUtil.deleteSample(self.LTMaster.conveyor.sound);
        EffectManager:deleteEffects(self.LTMaster.conveyor.effects);
        EffectManager:deleteEffects(self.LTMaster.conveyor.unloadEffects);
        EffectManager:deleteEffects(self.LTMaster.silageAdditive.effects);
        for _, particleSystems in pairs(self.LTMaster.conveyor.unloadParticleSystems) do
            ParticleUtil.deleteParticleSystems(particleSystems);
        end
        for _, particleSystems in pairs(self.LTMaster.conveyor.augerParticleSystems) do
            ParticleUtil.deleteParticleSystems(particleSystems);
        end
        SoundUtil.deleteSample(self.LTMaster.silageAdditive.sampleFill);
    end
    LTMaster.deleteBaler(self);
    LTMaster.deleteWrapper(self);
    LTMaster.deleteHud(self);
end

function LTMaster:mouseEvent(posX, posY, isDown, isUp, button)
end

function LTMaster:keyEvent(unicode, sym, modifier, isDown)
end

function LTMaster:writeStream(streamId, connection)
    LTMaster.writeStreamBaler(self, streamId, connection);
    LTMaster.writeStreamWrapper(self, streamId, connection);
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.LTMaster.hoods["left"].status);
        streamWriteUInt8(streamId, self.LTMaster.hoods["right"].status);
        streamWriteUInt8(streamId, self.LTMaster.supports.status);
        streamWriteUInt8(streamId, self.LTMaster.folding.status);
        streamWriteUInt8(streamId, self.LTMaster.ladder.status);
        streamWriteUInt8(streamId, self.LTMaster.baleSlide.status);
        streamWriteInt32(streamId, self.LTMaster.tipTrigger.id);
        streamWriteInt32(streamId, self.LTMaster.baler.balesNet.netRollRemainingUses);
        streamWriteInt32(streamId, self.LTMaster.wrapper.balesFoil.foilRollRemainingUses);
        streamWriteBool(streamId, self.LTMaster.sideUnload.isUnloading);
        streamWriteBool(streamId, self.LTMaster.conveyor.isOverloading);
        streamWriteBool(streamId, self.LTMaster.silageAdditive.isUsing);
        streamWriteBool(streamId, self.LTMaster.wrapper.enabled);
        streamWriteBool(streamId, self.LTMaster.baler.isWorking);
        streamWriteBool(streamId, self.LTMaster.manureLock);
        streamWriteUInt8(streamId, self.LTMaster.baler.baleVolumesIndex);
        self.LTMaster.tipTrigger:writeStream(streamId, connection);
        g_server:registerObjectInStream(connection, self.LTMaster.tipTrigger);
    end
end

function LTMaster:readStream(streamId, connection)
    LTMaster.readStreamBaler(self, streamId, connection);
    LTMaster.readStreamWrapper(self, streamId, connection);
    if connection:getIsServer() then
        self.LTMaster.hoods["left"].status = streamReadUInt8(streamId);
        self.LTMaster.hoods["right"].status = streamReadUInt8(streamId);
        self.LTMaster.supports.status = streamReadUInt8(streamId);
        self.LTMaster.folding.status = streamReadUInt8(streamId);
        self.LTMaster.ladder.status = streamReadUInt8(streamId);
        self.LTMaster.baleSlide.status = streamReadUInt8(streamId);
        local tipTriggerId = streamReadInt32(streamId);
        self.LTMaster.baler.balesNet.netRollRemainingUses = streamReadInt32(streamId);
        self.LTMaster.wrapper.balesFoil.foilRollRemainingUses = streamReadInt32(streamId);
        self.LTMaster.sideUnload.isUnloading = streamReadBool(streamId);
        self.LTMaster.conveyor.isOverloading = streamReadBool(streamId);
        self.LTMaster.silageAdditive.isUsing = streamReadBool(streamId);
        self.LTMaster.wrapper.enabled = streamReadBool(streamId);
        self.LTMaster.baler.isWorking = streamReadBool(streamId);
        self.LTMaster.manureLock = streamReadBool(streamId);
        self.LTMaster.baler.baleVolumesIndex = streamReadUInt8(streamId);
        self.LTMaster.tipTrigger:readStream(streamId, connection);
        g_client:finishRegisterObject(self.LTMaster.tipTrigger, tipTriggerId);
        LTMaster.finalizeLoad(self);
    end
end

function LTMaster:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.LTMaster.baler.baleVolumesIndex);
        streamWriteInt32(streamId, self.LTMaster.baler.balesNet.netRollRemainingUses);
        streamWriteInt32(streamId, self.LTMaster.wrapper.balesFoil.foilRollRemainingUses);
        streamWriteBool(streamId, self.LTMaster.sideUnload.isUnloading);
        streamWriteBool(streamId, self.LTMaster.conveyor.isOverloading);
        streamWriteBool(streamId, self.LTMaster.silageAdditive.isUsing);
        streamWriteBool(streamId, self.LTMaster.wrapper.enabled);
        streamWriteBool(streamId, self.LTMaster.baler.isWorking);
        streamWriteBool(streamId, self.LTMaster.manureLock);
        streamWriteFloat32(streamId, self.LTMaster.ptoRotSpeed);
    end
end

function LTMaster:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        self.LTMaster.baler.baleVolumesIndex = streamReadUInt8(streamId);
        self.LTMaster.baler.balesNet.netRollRemainingUses = streamReadInt32(streamId);
        self.LTMaster.wrapper.balesFoil.foilRollRemainingUses = streamReadInt32(streamId);
        self.LTMaster.sideUnload.isUnloading = streamReadBool(streamId);
        self.LTMaster.conveyor.isOverloading = streamReadBool(streamId);
        self.LTMaster.silageAdditive.isUsing = streamReadBool(streamId);
        self.LTMaster.wrapper.enabled = streamReadBool(streamId);
        self.LTMaster.baler.isWorking = streamReadBool(streamId);
        self.LTMaster.manureLock = streamReadBool(streamId);
        self.LTMaster.ptoRotSpeed = streamReadFloat32(streamId);
    end
end

function LTMaster:update(dt)
    LTMaster.updateBaler(self, dt);
    LTMaster.updateWrapper(self, dt);
    LTMaster.updateWrkMove(self, dt);
    LTMaster.updateHud(self, dt);
    self.LTMaster.hoods.delayedUpdateHoodStatus:update(dt);
    self.LTMaster.supports.delayedUpdateSupportsStatus:update(dt);
    self.LTMaster.folding.delayedUpdateFoldingStatus:update(dt);
    self.LTMaster.ladder.delayedUpdateLadderStatus:update(dt);
    self.LTMaster.baleSlide.delayedUpdateBaleSlideStatus:update(dt);
    if self.isClient then
        LTMaster.animationsInput(self, dt);
    --if self.LTMaster.triggerLeft.active and not self.LTMaster.sideUnload.isUnloading and self.LTMaster.folding.status == LTMaster.STATUS_FU_UNFOLDED and self:getRootAttacherVehicle().isMotorStarted then
    --    if self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) <= self.LTMaster.sideUnload.maxAmount then
    --        g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_UNLOAD_SIDE"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH);
    --        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
    --            g_client:getServerConnection():sendEvent(SideUnloadEvent:new(self));
    --            self.LTMaster.sideUnload.isUnloading = true;
    --        end
    --    end
    --end
    end
    self.LTMaster.conveyor.lastEffectStateOn = self.LTMaster.conveyor.effects[1].state;
    local rootVehicle = self:getRootAttacherVehicle();
    if self.isServer and rootVehicle ~= nil and not rootVehicle.isControlled then
        if rootVehicle.motor ~= nil then
            rootVehicle.motor:updateMotorRpm(dt);
        end
    end
    if self.fillUnits ~= nil and self.LTMaster.conveyor.isOverloading then
        local fillUnit = self.fillUnits[self.LTMaster.fillUnits["main"].index];
        if fillUnit ~= nil then
            local fillVolume = self.fillVolumes[fillUnit.fillVolumeIndex];
            if fillVolume ~= nil then
                if fillVolume.scrollSpeedDischarge[1] ~= 0 or fillVolume.scrollSpeedDischarge[2] ~= 0 or fillVolume.scrollSpeedDischarge[3] ~= 0 then
                    fillVolume.uvPosition[1] = fillVolume.uvPosition[1] + fillVolume.scrollSpeedDischarge[1] * dt;
                    fillVolume.uvPosition[2] = fillVolume.uvPosition[2] + fillVolume.scrollSpeedDischarge[2] * dt;
                    fillVolume.uvPosition[3] = fillVolume.uvPosition[3] + fillVolume.scrollSpeedDischarge[3] * dt;
                    setShaderParameter(fillVolume.volume, "uvOffset", fillVolume.uvPosition[1], fillVolume.uvPosition[2], fillVolume.uvPosition[3], 0, false);
                end
            end
        end
    end
end

function LTMaster:updateTick(dt)
    local normalizedDt = dt / 1000;
    LTMaster.updateTickBaler(self, dt, normalizedDt);
    LTMaster.updateTickWrapper(self, dt, normalizedDt);
    LTMaster.updateTickWrkMove(self, dt, normalizedDt);
    PlayerTriggers:update();
    if self.LTMaster.vehicleRpmHud ~= nil and self:getRootAttacherVehicle() ~= nil then
        local rv = self:getRootAttacherVehicle();
        if rv.motor ~= nil then
            VehicleHudUtils.setHudValue(self, self.LTMaster.vehicleRpmHud, rv.motor:getLastMotorRpm(), rv.motor:getMaxRpm());
        end
    end
    if self.LTMaster.productionHud ~= nil then
        VehicleHudUtils.setHudValue(self, self.LTMaster.productionHud, self:getCreatedBales(), 99999);
    end
    if self.LTMaster.weightHud ~= nil and self:getRootAttacherVehicle() ~= nil then
        local desc = FillUtil.fillTypeIndexToDesc[self:getUnitLastValidFillType(self.LTMaster.baler.fillUnitIndex)];
        if desc ~= nil then
            local value = desc.massPerLiter * self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) * 1000;
            VehicleHudUtils.setHudValue(self, self.LTMaster.weightHud, value, 9999);
        end
    end
    if self.LTMaster.balePressureHud ~= nil then
        local value = 0;
        if self.LTMaster.baler.unloadingState == Baler.UNLOADING_CLOSED then
            value = self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex);
        end
        VehicleHudUtils.setHudValue(self, self.LTMaster.balePressureHud, value, self.LTMaster.balePressureHud.maxValueAnim);
    end
    self.inputAttacherJoints[1].ptoInput.rotSpeed = self.LTMaster.ptoRotSpeed;
    if self.isServer then
        if self:getDirtAmount() > 0.01 then
            if self:getUnitLastValidFillType(self.LTMaster.fillUnits["main"].index) == FillUtil.FILLTYPE_MANURE and self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) > 1 then
                self.LTMaster.manureLock = true;
            end
        else
            self.LTMaster.manureLock = false;
        end
    end
    if g_currentMission.time >= self.LTMaster.greasePump.next then
        if self:getIsTurnedOn() then
            self:playAnimation(self.LTMaster.greasePump.animation, 1);
            Sound3DUtil:playSample(self.LTMaster.greasePump.sound, 1, 0, nil, self:getIsActiveForSound());
        end
        self.LTMaster.greasePump.next = g_currentMission.time + self.LTMaster.greasePump.delay;
    end
    if self.isServer then
        if self.LTMaster.sideUnload.isUnloading then
            for _, fillUnit in pairs({self.LTMaster.fillUnits["left"], self.LTMaster.fillUnits["right"]}) do
                local fillType = self:getUnitLastValidFillType(fillUnit.index);
                local fillLevel = self:getUnitFillLevel(fillUnit.index);
                local delta = math.min(fillLevel, fillUnit.unloadSpeed * dt);
                if delta > 0 then
                    local mainCapacity = self:getUnitCapacity(self.LTMaster.fillUnits["main"].index);
                    local mainFillLevel = self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index);
                    local mainDelta = math.min(delta, mainCapacity - mainFillLevel);
                    if mainDelta > 0 then
                        self:setUnitFillLevel(fillUnit.index, fillLevel - mainDelta, fillType);
                        self:setUnitFillLevel(self.LTMaster.fillUnits["main"].index, mainFillLevel + mainDelta, fillType);
                    end
                end
            end
            if self:getAnimationTime(self.LTMaster.sideUnload.animation) >= 1 then
                self.LTMaster.sideUnload.isUnloading = false;
            end
        end
    end
    if self.isClient then
        if self.LTMaster.silageAdditive.effects ~= nil then
            if self.LTMaster.silageAdditive.isUsing and self:getIsConveyorOverloading() then
                EffectManager:setFillType(self.LTMaster.silageAdditive.effects, self.LTMaster.silageAdditive.fillType);
                EffectManager:startEffects(self.LTMaster.silageAdditive.effects);
            else
                EffectManager:stopEffects(self.LTMaster.silageAdditive.effects);
            end
        end
        if self.LTMaster.conveyor.effects ~= nil then
            if self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) > 0 then
                if self.LTMaster.conveyor.isOverloading then
                    EffectManager:setFillType(self.LTMaster.conveyor.effects, self:getUnitLastValidFillType(self.LTMaster.fillUnits["main"].index));
                    EffectManager:startEffects(self.LTMaster.conveyor.effects);
                    for _, effect in pairs(self.LTMaster.conveyor.effects) do
                        if effect.setScrollUpdate ~= nil then
                            effect:setScrollUpdate(true);
                        end
                    end
                    Utils.updateScrollers(self.LTMaster.conveyor.uvScrollParts, dt, true);
                    Utils.updateRotationNodes(self, self.LTMaster.conveyor.rotatingParts, dt, true);
                    Sound3DUtil:playSample(self.LTMaster.conveyor.sound, 0, 0, nil, self:getIsActiveForSound());
                else
                    for _, effect in pairs(self.LTMaster.conveyor.effects) do
                        if effect.setScrollUpdate ~= nil then
                            effect:setScrollUpdate(false);
                        end
                    end
                    Utils.updateScrollers(self.LTMaster.conveyor.uvScrollParts, dt, false, false);
                    Utils.updateRotationNodes(self, self.LTMaster.conveyor.rotatingParts, dt, false);
                    Sound3DUtil:stopSample(self.LTMaster.conveyor.sound);
                end
            else
                EffectManager:stopEffects(self.LTMaster.conveyor.effects);
                Utils.updateScrollers(self.LTMaster.conveyor.uvScrollParts, dt, false);
                Utils.updateRotationNodes(self, self.LTMaster.conveyor.rotatingParts, dt, false);
                Sound3DUtil:stopSample(self.LTMaster.conveyor.sound);
            end
        end
        if self:getIsConveyorOverloading() then
            local currentUnloadParticleSystems = self.LTMaster.conveyor.unloadParticleSystems[self:getUnitLastValidFillType(self.LTMaster.fillUnits["main"].index)];
            if currentUnloadParticleSystems ~= self.LTMaster.conveyor.currentUnloadParticleSystems then
                if self.LTMaster.conveyor.currentUnloadParticleSystems ~= nil then
                    for _, ps in pairs(self.LTMaster.conveyor.currentUnloadParticleSystems) do
                        ParticleUtil.setEmittingState(ps, false);
                    end
                end
                self.LTMaster.conveyor.currentUnloadParticleSystems = currentUnloadParticleSystems;
                if self.LTMaster.conveyor.currentUnloadParticleSystems ~= nil then
                    for _, ps in pairs(self.LTMaster.conveyor.currentUnloadParticleSystems) do
                        ParticleUtil.setEmittingState(ps, true);
                    end
                end
            end
            EffectManager:setFillType(self.LTMaster.conveyor.unloadEffects, self:getUnitLastValidFillType(self.LTMaster.fillUnits["main"].index));
            EffectManager:startEffects(self.LTMaster.conveyor.unloadEffects);
        else
            if self.LTMaster.conveyor.currentUnloadParticleSystems ~= nil then
                for _, ps in pairs(self.LTMaster.conveyor.currentUnloadParticleSystems) do
                    ParticleUtil.setEmittingState(ps, false)
                end
                self.LTMaster.conveyor.currentUnloadParticleSystems = nil;
            end
            EffectManager:stopEffects(self.LTMaster.conveyor.unloadEffects);
        end
        if self.LTMaster.conveyor.isOverloading and self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) > 0 then
            local currentAugerParticleSystems = self.LTMaster.conveyor.augerParticleSystems[self:getUnitLastValidFillType(self.LTMaster.fillUnits["main"].index)];
            if currentAugerParticleSystems ~= self.LTMaster.conveyor.currentAugerParticleSystems then
                if self.LTMaster.conveyor.currentAugerParticleSystems ~= nil then
                    for _, ps in pairs(self.LTMaster.conveyor.currentAugerParticleSystems) do
                        ParticleUtil.setEmittingState(ps, false);
                    end
                end
                self.LTMaster.conveyor.currentAugerParticleSystems = currentAugerParticleSystems;
                if self.LTMaster.conveyor.currentAugerParticleSystems ~= nil then
                    for _, ps in pairs(self.LTMaster.conveyor.currentAugerParticleSystems) do
                        ParticleUtil.setEmittingState(ps, true);
                    end
                end
            end
        else
            if self.LTMaster.conveyor.currentAugerParticleSystems ~= nil then
                for _, ps in pairs(self.LTMaster.conveyor.currentAugerParticleSystems) do
                    ParticleUtil.setEmittingState(ps, false)
                end
                self.LTMaster.conveyor.currentAugerParticleSystems = nil;
            end
        end
    end
    if self.isFilling and self.fillTrigger ~= nil and self.fillTrigger.fillType == FillUtil.FILLTYPE_SILAGEADDITIVE then
        if self.isClient then
            Sound3DUtil:playSample(self.LTMaster.silageAdditive.sampleFill, 0, 0, nil, self:getIsActiveForSound());
        end
        self.fillLitersPerSecond = self.LTMaster.silageAdditive.fillLitersPerSecond;
    else
        if self.isClient then
            Sound3DUtil:stopSample(self.LTMaster.silageAdditive.sampleFill);
        end
    end
    if not self.isFilling then
        self.fillLitersPerSecond = 1;
    end
    Utils.updateRotationNodes(self, self.LTMaster.turnedOnRotationNodes, dt, self:getIsTurnedOn());
end

function LTMaster:draw()
    if self.tempHelpInfoText then
        g_currentMission:addExtraPrintText(self.tempHelpInfoText);
    end
    LTMaster.drawBaler(self);
    LTMaster.drawWrapper(self);
    LTMaster.drawWrkMove(self);
    LTMaster.drawHud(self);
end

function LTMaster:onDeactivate()
    LTMaster.onDeactivateBaler(self);
    LTMaster.onDeactivateWrapper(self);
end

function LTMaster:onDeactivateSounds()
    LTMaster.onDeactivateSoundsBaler(self);
    LTMaster.onDeactivateSoundsWrapper(self);
end

function LTMaster:unloadSide()
    self:playAnimation(self.LTMaster.sideUnload.animation, 1);
    local animationDuration = self:getAnimationDuration(self.LTMaster.sideUnload.animation) / 2;
    self.LTMaster.fillUnits["left"].unloadSpeed = self:getUnitFillLevel(self.LTMaster.fillUnits["left"].index) / animationDuration;
    self.LTMaster.fillUnits["right"].unloadSpeed = self:getUnitFillLevel(self.LTMaster.fillUnits["right"].index) / animationDuration;
    self.LTMaster.sideUnload.isUnloading = true;
end

function LTMaster:getIsFoldAllowed(superFunc, onAiTurnOn)
    if self:getIsTurnedOn() or self.LTMaster.baleSlide.status ~= LTMaster.STATUS_RL_RAISED or self.LTMaster.supports.status ~= LTMaster.STATUS_RL_RAISED or not self:getRootAttacherVehicle().isMotorStarted then
        return false;
    end
    if superFunc ~= nil then
        return superFunc(self, onAiTurnOn);
    end
    return true;
end

function LTMaster:getIsTurnedOnAllowed(superFunc, isTurnedOn)
    if isTurnedOn then
        if self.LTMaster.folding.status ~= LTMaster.STATUS_FU_UNFOLDED or self.LTMaster.baleSlide.status ~= LTMaster.STATUS_RL_LOWERED then
            return false;
        end
    end
    if superFunc ~= nil then
        return superFunc(self, isTurnedOn);
    end
    return true;
end

function LTMaster:getTurnedOnNotAllowedWarning(superFunc)
    if self:getRootAttacherVehicle().isMotorStarted then
        if self.LTMaster.folding.status ~= LTMaster.STATUS_FU_UNFOLDED then
            return g_i18n:getText("GLTM_TURNON_NOT_ALLOWED_UNFOLD");
        end
        if self.LTMaster.baleSlide.status ~= LTMaster.STATUS_RL_LOWERED then
            return g_i18n:getText("GLTM_TURNON_NOT_ALLOWED_BALESLIDE");
        end
    end
    if superFunc ~= nil then
        return superFunc(self);
    end
    return nil;
end

function LTMaster:getConsumedPtoTorque(superFunc)
    local torque = 0;
    if superFunc ~= nil then
        torque = superFunc(self);
    end
    torque = 0;
    local cvTT = 540 * math.pi / 30;
    if self.LTMaster.supports.status == LTMaster.STATUS_RL_LOWERING then
        torque = torque + 30 / cvTT;
    end
    if self.LTMaster.supports.status == LTMaster.STATUS_RL_RAISING then
        torque = torque + 10 / cvTT;
    end
    if self.LTMaster.baleSlide.status == LTMaster.STATUS_RL_LOWERING then
        torque = torque + 10 / cvTT;
    end
    if self.LTMaster.baleSlide.status == LTMaster.STATUS_RL_RAISING then
        torque = torque + 20 / cvTT;
    end
    if self.LTMaster.folding.status == LTMaster.STATUS_FU_UNFOLDING then
        torque = torque + 20 / cvTT;
    end
    if self.LTMaster.folding.status == LTMaster.STATUS_FU_FOLDING then
        torque = torque + 40 / cvTT;
    end
    if self:getIsAnimationPlaying(self.foldingParts[1].animationName) then
        torque = torque + 25 / cvTT;
    end
    if self:getIsTurnedOn() then
        torque = torque + 40 / cvTT;
    end
    if not self:allowsGrabbingBale() then
        torque = torque + 20 / cvTT;
    end
    if self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) > 0 and self.LTMaster.conveyor.isOverloading then
        torque = torque + 40 / cvTT;
    end
    if self.LTMaster.baler.isWorking then
        torque = torque + (70 * (self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) / self:getUnitCapacity(self.LTMaster.baler.fillUnitIndex))) / cvTT;
    end
    return torque;
end

function LTMaster:getPtoRpm(superFunc)
    local ptoRpm = 0;
    if superFunc ~= nil then
        ptoRpm = superFunc(self);
    end
    if self.LTMaster.supports.status == LTMaster.STATUS_RL_LOWERING then
        ptoRpm = math.max(ptoRpm, 760);
    end
    if self.LTMaster.supports.status == LTMaster.STATUS_RL_RAISING then
        ptoRpm = math.max(ptoRpm, 540);
    end
    if self.LTMaster.folding.status == LTMaster.STATUS_FU_UNFOLDING then
        ptoRpm = math.max(ptoRpm, 760);
    end
    if self.LTMaster.folding.status == LTMaster.STATUS_FU_FOLDING then
        ptoRpm = math.max(ptoRpm, 870);
    end
    if self.LTMaster.baleSlide.status == LTMaster.STATUS_RL_LOWERING or self.LTMaster.baleSlide.status == LTMaster.STATUS_RL_RAISING then
        ptoRpm = math.max(ptoRpm, 540);
    end
    if self:getIsAnimationPlaying(self.foldingParts[1].animationName) then
        ptoRpm = math.max(ptoRpm, 540);
    end
    if self:getIsTurnedOn() then
        ptoRpm = math.max(ptoRpm, 540);
    end
    if not self:allowsGrabbingBale() then
        ptoRpm = math.max(ptoRpm, 650);
    end
    if self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) > 0 and self.LTMaster.conveyor.isOverloading then
        ptoRpm = math.max(ptoRpm, 650);
    end
    if self.LTMaster.baler.isWorking and self.LTMaster.baler.autoUnloadTime == nil then
        ptoRpm = math.max(ptoRpm, 650 + (330 * (self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) / self:getUnitCapacity(self.LTMaster.baler.fillUnitIndex))));
    end
    self.LTMaster.ptoRotSpeed = math.rad(ptoRpm ^ 3 * 0.00000000125);
    return ptoRpm;
end

function LTMaster:getIsConveyorOverloading()
    local stateOn = self.LTMaster.conveyor.lastEffectStateOn == ShaderPlaneEffect.STATE_ON or self.LTMaster.conveyor.effects[1].state == ShaderPlaneEffect.STATE_ON;
    return self.LTMaster.conveyor.isOverloading and stateOn;
end

function LTMaster:getDirtMultiplier(superFunc)
    local multiplier = 0;
    if superFunc ~= nil then
        multiplier = superFunc(self);
    end
    if self:getIsTurnedOn() then
        multiplier = math.max(1, multiplier);
    end
    if self.LTMaster.baler.isWorking and self.LTMaster.baler.autoUnloadTime == nil then
        if self:getUnitLastValidFillType(self.LTMaster.fillUnits["main"].index) == FillUtil.FILLTYPE_MANURE then
            multiplier = math.max(multiplier, self.workMultiplier * 2);
        else
            multiplier = math.max(multiplier, self.workMultiplier);
        end
    end
    return multiplier;
end

function LTMaster:getIsPowerTakeoffActive(superFunc)
    local result = false;
    if superFunc ~= nil then
        result = superFunc(self);
    end
    if self.LTMaster.ptoRotSpeed > 0 then
        return true;
    end
    return result;
end

function LTMaster:onAttach(attacherVehicle, implement)
    local isAllowed, motorOff = PowerConsumer.getIsTurnedOnAllowed(self, nil, true);
    if not isAllowed and self.firstTimeRun and not motorOff then
        g_currentMission:showBlinkingWarning(self.powerConsumer.turnOnNotAllowedWarning, 2000);
    end
end
