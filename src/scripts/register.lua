--
--Goweil LT Master
--
--TyKonKet - fcelsa (Team FSI Modding)
--
--01/05/2017
register = {};
register.dir = g_currentModDirectory;

ConfigurationUtil.registerConfigurationType("conveyorFlow", g_i18n:getText("configuration_conveyorFlow"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("silageAdditiveSystem", g_i18n:getText("configuration_silageAdditiveSystem"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("dynamicChamber", g_i18n:getText("configuration_dynamicChamber"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("monitorSystem", g_i18n:getText("configuration_monitorSystem"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("remoteMonitorSystem", g_i18n:getText("configuration_remoteMonitorSystem"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("starterKit", g_i18n:getText("configuration_starterKit"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);

FillUtil.registerFillType("silageAdditive", g_i18n:getText("fillType_silageAdditive"), FillUtil.FILLTYPE_CATEGORY_LIQUID, 5.000, false, g_currentModDirectory .. "hud/fillTypes/hud_fill_silageAdditive.png", g_currentModDirectory .. "hud/fillTypes/hud_fill_silageAdditive_sml.png", 550 * 0.000001, math.rad(0));
FillUtil.registerFillType("balesNet", g_i18n:getText("fillType_balesNet"), FillUtil.FILLTYPE_CATEGORY_PIECE, 75, false, g_currentModDirectory .. "hud/fillTypes/hud_fill_balesNet.png", g_currentModDirectory .. "hud/fillTypes/hud_fill_balesNet_sml.png", 1500 * 0.000001, math.rad(0));
FillUtil.registerFillType("balesFoil", g_i18n:getText("fillType_balesFoil"), FillUtil.FILLTYPE_CATEGORY_PIECE, 50, false, g_currentModDirectory .. "hud/fillTypes/hud_fill_balesFoil.png", g_currentModDirectory .. "hud/fillTypes/hud_fill_balesFoil_sml.png", 1800 * 0.000001, math.rad(0));

BaleUtil.registerBaleType(register.dir .. "bales/roundbaleGrass_w112_d130.i3d", "grass_windrow", 1.13, nil, nil, 1.3, true);
BaleUtil.registerBaleType(register.dir .. "bales/roundbaleGrassSilage_w112_d130.i3d", "silage", 1.13, nil, nil, 1.3, true);
BaleUtil.registerBaleType(register.dir .. "bales/roundbaleHay_w112_d130.i3d", "dryGrass_windrow", 1.13, nil, nil, 1.3, true);
BaleUtil.registerBaleType(register.dir .. "bales/roundbaleStraw_w112_d130.i3d", "straw", 1.13, nil, nil, 1.3, true);
BaleUtil.registerBaleType(register.dir .. "bales/roundbaleChaff_w112_d130.i3d", "chaff", 1.13, nil, nil, 1.3, true);
BaleUtil.registerBaleType(register.dir .. "bales/roundbaleChaffSilage_w112_d130.i3d", "silage", 1.14, nil, nil, 1.3, true);
BaleUtil.registerBaleType(register.dir .. "bales/roundbaleWoodChips_w112_d130.i3d", "woodChips", 1.13, nil, nil, 1.3, true);
BaleUtil.registerBaleType(register.dir .. "bales/roundbaleManure_w112_d130.i3d", "manure", 1.13, nil, nil, 1.3, true);

function register:loadMap(name)
    for k, v in pairs(g_i18n.texts) do
        local nv = v;
        for m in nv:gmatch("$input_.-;") do
            local input = m:gsub("$input_", ""):gsub(";", "");
            nv = nv:gsub(m, InputBinding.getKeysNamesOfDigitalAction(InputBinding[input]));
        end
        g_i18n.globalI18N:setText(k, nv);
    end
    Utils.loadHelpLine(self.dir .. "helpline/helpLine.xml", g_inGameMenu.helpLineCategories, g_inGameMenu.helpLineCategorySelectorElement, self.dir);
    Utils.loadI3D(self.dir .. "holders/materialHolder.i3d");
    Utils.loadI3D(self.dir .. "holders/tireTruckMaterialHolder.i3d");
end

function register:deleteMap()
end

function register:keyEvent(unicode, sym, modifier, isDown)
end

function register:mouseEvent(posX, posY, isDown, isUp, button)
end

function register:update(dt)
end

function register:draw()
end

addModEventListener(register);
