--[[
    Sonoran Plugins

    Plugin Configuration

    Put all needed configuration in this file.
]]
local config = {
    enabled = false,
    pluginName = "wraithv2", -- name your plugin here
    pluginAuthor = "SonoranCAD", -- author
    requiresPlugins = {"lookups"}, -- required plugins for this plugin to work, separated by commas

    -- put your configuration options below
    isPluginEnabled = false -- disable this plugin by default
    ,useExpires = true -- use vehicle registration expirations, or not
    ,useMiddleInitial = true -- use middle initials?
}

if config.enabled then
    Config.RegisterPluginConfig(config.pluginName, config)
end