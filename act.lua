script_properties('work-in-pause')

local imgui = require('mimgui')
local ffi = require('ffi')
local samp = require('samp.events')
local inicfg = require('inicfg')
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8

local cfg = inicfg.load({
	config = {color = 0, title = ''},
	colors = {}
}, 'AutoColorAndTitle')
local window = imgui.new.bool(false)
local title = imgui.new.char[128](u8(cfg.config.title))

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	sampRegisterChatCommand('act', function() window[0] = not window[0] end)
	sms('Активация: {7172ee}/act'); save()
	wait(-1)
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil; theme()
end)

local newFrame = imgui.OnFrame(
	function() return window[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
	function(player)
	  imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  imgui.SetNextWindowSize(imgui.ImVec2(300, 245), imgui.Cond.FirstUseEver)
		imgui.Begin('AutoColorAndTitle', window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
			imgui.BeginChild('title', imgui.ImVec2(-1, 35), true)
				imgui.PushItemWidth(-1)
				if imgui.InputTextWithHint('##title', u8('Введите название'), title, ffi.sizeof(title)) then cfg.config.title = u8:decode(ffi.string(title)); save() end
				imgui.PopItemWidth()
			imgui.EndChild()

			imgui.BeginChild('color', imgui.ImVec2(-1, -1), true)
				imgui.CenterText(u8('Выбранный цвет: ' .. cfg.config.color))
				if imgui.Button(u8('Сбросить цвет'), imgui.ImVec2(-1)) then cfg.config.color = 0; save() end
				for k, v in ipairs(cfg.colors) do
					local t = {explode_argb(tonumber('0x' .. v))}
					imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(t[2] / 255, t[3] / 255, t[4] / 255, 1))
					imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(t[2] / 255, t[3] / 255, t[4] / 255, 1))
					imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(t[2] / 255, t[3] / 255, t[4] / 255, 1))
						if imgui.Button(tostring(k), imgui.ImVec2( (imgui.GetWindowWidth() - 25) / 4 )) then cfg.config.color = k; save() end
					imgui.PopStyleColor(3)
					if k % 4 ~= 0 and k ~= #cfg.colors then imgui.SameLine() end
				end
			imgui.EndChild()
		imgui.End()
	end
)

function samp.onShowDialog(dialogId, style, title, button1, button2, text)
	if text:find('{FFFFFF}Введите название вашей лавки') and #cfg.config.title > 0 then
		sampSendDialogResponse(dialogId, 1, nil, cfg.config.title); return false
	end

	if title == '{BFBBBA}Выберете цвет' and text:find('{E94E4E}|||||||||||||||||||') then
		cfg.colors = {}
		for line in text:gmatch('[^\n]+') do
			table.insert(cfg.colors, (line:match('{(.-)}') == 'FFFFFF' and 'ABABAB' or line:match('{(.-)}')))
		end
		save()
		if cfg.colors[cfg.config.color] then
			sampSendDialogResponse(dialogId, 1, cfg.config.color - 1); return false
		end
	end
end

function save()
	inicfg.save(cfg, 'AutoColorAndTitle.ini')
end

function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function sms(text)
	sampAddChatMessage('[AutoColorAndTitle] {FFFFFF}' .. tostring(text), 0x7172ee)
end

function theme()
	local function colorConvertHexToFloat4(hex)
		local s = hex:sub(5, 6) .. hex:sub(3, 4) .. hex:sub(1, 2)
		return imgui.ColorConvertU32ToFloat4(tonumber('0xFF' .. s))
	end

	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4

	-->> Sizez
	imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
	imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)

	imgui.GetStyle().IndentSpacing = 21
	imgui.GetStyle().ScrollbarSize = 14
	imgui.GetStyle().GrabMinSize = 10

	imgui.GetStyle().WindowBorderSize = 0
	imgui.GetStyle().ChildBorderSize = 1
	imgui.GetStyle().PopupBorderSize = 1
	imgui.GetStyle().FrameBorderSize = 0
	imgui.GetStyle().TabBorderSize = 1

	imgui.GetStyle().WindowRounding = 2.5
	imgui.GetStyle().ChildRounding = 2.5
	imgui.GetStyle().PopupRounding = 2.5
	imgui.GetStyle().FrameRounding = 2.5
	imgui.GetStyle().ScrollbarRounding = 2.5
	imgui.GetStyle().GrabRounding = 2.5
	imgui.GetStyle().TabRounding = 2.5

	imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.50, 0.50)

	-->> Colors
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)

	colors[clr.WindowBg] 							 = ImVec4(0.15, 0.16, 0.37, 1.00)
	colors[clr.ChildBg]                = ImVec4(0.17, 0.18, 0.43, 1.00)
	colors[clr.PopupBg]                = colors[clr.WindowBg]

	colors[clr.Border]                 = colorConvertHexToFloat4('7B7BE1')
	colors[clr.BorderShadow]           = ImVec4(0.65, 0.60, 0.60, 0.00)

	colors[clr.TitleBg]                = ImVec4(0.18, 0.20, 0.46, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.18, 0.20, 0.46, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.18, 0.20, 0.46, 1.00)
	colors[clr.MenuBarBg]              = ImVec4(1.00, 0.51, 0.51, 1.00)

	colors[clr.ScrollbarBg]            = ImVec4(0.14, 0.14, 0.36, 1.00)
	colors[clr.ScrollbarGrab]          = ImVec4(0.22, 0.22, 0.53, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.20, 0.21, 0.53, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.25, 0.25, 0.58, 1.00)

	colors[clr.Button]                 = ImVec4(0.25, 0.25, 0.58, 1.00)
	colors[clr.ButtonHovered]          = colorConvertHexToFloat4('4949A4')
	colors[clr.ButtonActive]           = colorConvertHexToFloat4('5656BA')

	colors[clr.CheckMark]              = colorConvertHexToFloat4('8383DF')
	colors[clr.SliderGrab]             = ImVec4(0.39, 0.39, 0.83, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.48, 0.48, 0.96, 1.00)

	colors[clr.FrameBg]                = colors[clr.Button]
	colors[clr.FrameBgHovered]         = colors[clr.ButtonHovered]
	colors[clr.FrameBgActive]          = colors[clr.ButtonActive]

	colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)

	colors[clr.Separator]              = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.SeparatorHovered]       = ImVec4(0.10, 0.40, 0.75, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.10, 0.40, 0.75, 1.00)

	colors[clr.ResizeGrip]             = colors[clr.Button]
	colors[clr.ResizeGripHovered]      = colors[clr.ButtonHovered]
	colors[clr.ResizeGripActive]       = colors[clr.ButtonActive]

	colors[clr.Tab]                    = ImVec4(0.45, 0.49, 0.54, 0.86)
	colors[clr.TabHovered]             = ImVec4(0.45, 0.50, 0.54, 0.80)
	colors[clr.TabActive]              = ImVec4(0.60, 0.60, 0.60, 1.00)
	colors[clr.TabUnfocused]           = ImVec4(0.07, 0.10, 0.15, 0.97)
	colors[clr.TabUnfocusedActive]     = ImVec4(0.54, 0.59, 0.65, 1.00)

	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)

	colors[clr.TextSelectedBg]         = ImVec4(0.64, 0.67, 0.71, 0.35)
	colors[clr.DragDropTarget]         = ImVec4(1.00, 1.00, 0.00, 0.90)

	colors[clr.NavHighlight]           = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.NavWindowingHighlight]  = ImVec4(1.00, 1.00, 1.00, 0.70)
	colors[clr.NavWindowingDimBg]      = ImVec4(0.80, 0.80, 0.80, 0.20)

	colors[clr.ModalWindowDimBg]       = ImVec4(0.00, 0.00, 0.00, 0.90)
end
