--
--Goweil LT Master
--
--TyKonKet - fcelsa (Team FSI Modding)
--
--10/05/2017
BaleInfos = {};

function BaleInfos.renderTxtBale(x, y, z, text, textSize, textOffset)
    local sx, sy, sz = project(x, y, z);
    if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
        setTextAlignment(RenderText.ALIGN_CENTER);
        setTextBold(true);
        setTextColor(0.0, 0.0, 1.0, 0.70);
        renderText(sx, sy - 0.0018 + textOffset, textSize, text);
        setTextColor(0.5, 1.0, 0.7, 1.0);
        renderText(sx, sy + textOffset, textSize, text);
        setTextAlignment(RenderText.ALIGN_LEFT);
    end
end

function BaleInfos:loadMap(name)
    self.guiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"), 1);
    self.fontSize = 0.016 * self.guiScale;
end

function BaleInfos:deleteMap()
end

function BaleInfos:keyEvent(unicode, sym, modifier, isDown)
end

function BaleInfos:mouseEvent(posX, posY, isDown, isUp, button)
end

function BaleInfos:update(dt)
    self.textBaleInfos = nil;
    if g_currentMission.player ~= nil and g_currentMission.controlledVehicle == nil then
        if g_currentMission.player.lastFoundBale ~= nil then
            local desc = FillUtil.fillTypeIndexToDesc[g_currentMission.player.lastFoundBale.fillType];
            local iName = desc.nameI18N;
            local fLevel = g_currentMission.player.lastFoundBale.fillLevel;
            local baseValue = g_currentMission.player.lastFoundBale:getValue();
            local realWeight = (fLevel * desc.massPerLiter) * 1000;
            self.textBaleInfos = iName .. " (" .. string.format("%0.f l)", fLevel) .. "\n" .. string.format("%0.f kg", realWeight) .. "\n" .. g_i18n.globalI18N:formatMoney(baseValue, 0, true);
        end
    end
end

function BaleInfos:draw()
    if g_seasons == nil then
        if self.textBaleInfos ~= nil and g_currentMission.player.lastFoundBale ~= nil and g_currentMission.player.lastFoundBale.nodeId ~= 0 and g_currentMission.player.currentToolId == 0 then
            local x, y, z = getWorldTranslation(g_currentMission.player.lastFoundBale.nodeId);
            BaleInfos.renderTxtBale(x, y, z, self.textBaleInfos, getCorrectTextSize(self.fontSize), 0);
        end
    end
end

addModEventListener(BaleInfos);
