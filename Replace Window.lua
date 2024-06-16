script_name('Replace Window')
script_author('Rice.')
script_version('12.0.2.5')
script_properties('work-in-pause') 

local imgui_check, imgui			= pcall(require, 'mimgui')
local samp_check, samp				= pcall(require, 'samp.events')
local effil_check, effil			= pcall(require, 'effil')
local requests_check, requests		= pcall(require, 'requests')
local monet_check, monet			= pcall(require, 'MoonMonet')
local dlstatus						= require('moonloader').download_status
local weapons						= require('game.weapons')
local ffi							= require('ffi')
local encoding						= require('encoding')
encoding.default					= 'CP1251'
u8 = encoding.UTF8

if not imgui_check or not samp_check or not effil_check or not requests_check or not monet_check then
	function main()
		if not isSampfuncsLoaded() or not isSampLoaded() then return end
		while not isSampAvailable() do wait(100) end
		local libs = {
			['Mimgui'] = imgui_check,
			['SAMP.Lua'] = samp_check,
			['Effil'] = effil_check,
			['Requests'] = requests_check,
			['MoonMonet'] = monet_check
		}
		local libs_no_found = {}
		for k, v in pairs(libs) do
			if not v then sampAddChatMessage('« Replace Window » {FFFFFF}У Вас отсутствует библиотека {7172ee}' .. k .. '{FFFFFF}. Без неё скрипт {7172ee}не будет {FFFFFF}работать!', 0x7172ee); table.insert(libs_no_found, k) end
		end
		sampShowDialog(18364, '{7172ee}Replace Window', string.format('{FFFFFF}В Вашей сборке {7172ee}нету необходимых библиотек{FFFFFF} для работы скрипта.\nБез них он {7172ee}не будет{FFFFFF} работать!\n\nБиблиотеки, которые Вам нужны:\n{FFFFFF}- {7172ee}%s\n\n{FFFFFF}Все библиотеки можно скачать в теме на BlastHack: {7172ee}https://www.blast.hk/threads/190033\n{FFFFFF}В этой же теме Вы {7172ee}найдете инструкцию {FFFFFF}для их установки.', table.concat(libs_no_found, '\n{FFFFFF}- {7172ee}')), 'Принять', '', 0)
		thisScript():unload()
	end
	return
end

-->> JSON
function table.assign(target, def, deep)
    for k, v in pairs(def) do
        if target[k] == nil then
            if type(v) == 'table' then
                target[k] = {}
                table.assign(target[k], v)
            else  
                target[k] = v
            end
        elseif deep and type(v) == 'table' and type(target[k]) == 'table' then 
            table.assign(target[k], v, deep)
        end
    end 
    return target
end

function json(path)
	createDirectory(getWorkingDirectory() .. '/ReplaceWindow')
	local path = getWorkingDirectory() .. '/ReplaceWindow/' .. path
	local class = {}

	function class:save(array)
		if array and type(array) == 'table' and encodeJson(array) then
			local file = io.open(path, 'w')
			file:write(encodeJson(array))
			file:close()
		else
			sms('Ошибка при сохранение файла!')
		end
	end

	function class:load(array)
		local result = {}
		local file = io.open(path)
		if file then
			result = decodeJson(file:read()) or {}
		end

		return table.assign(result, array, true)
	end

	return class
end

-->> Local Settings
local window = imgui.new.bool(false)
local searchLog = imgui.new.char[128]()
local date_select = nil
local infoGithub = {}
local menu = 2
local logMenu = 0
local lastHealth = 0
local sortLog = 0

local jsonLog = json('Log.json'):load({})
local jsonConfig = json('Config.json'):load({
	['script'] = {
		scriptColor = {1.0, 1.0, 1.0},
		lastNewsCheck = 0
	},
	['notifications'] = {
		inputToken = '',
		inputGroup = '',
		resale = false,
		action = false,
		balance = false,
		statistics = false,
		death = false,
		moreItems = false,
		message = false,
		damage = false,
		catchingShop = false,
		status32 = false,
		status33 = false,
		status34 = false,
		status35 = false,
		status37 = false
	},
	['market'] = {
		fontSize = 1.0,
		fontAlpha = 1.00,
		marketAlpha = 1.00,
		marketSize = {x = 700, y = 260},
		marketBool = false,
		marketColor = {text = {1.0, 1.0, 1.0}, window = {0.2, 0.2, 0.2}},
		marketPos = {x = -1, y = -1}
	}
})

-->> Script Settings
local scriptColor = imgui.new.float[3](jsonConfig['script'].scriptColor)
local lastNewsCheck = jsonConfig['script'].lastNewsCheck

-->> Notifications Settings
local inputToken, inputGroup = imgui.new.char[128](jsonConfig['notifications'].inputToken), imgui.new.char[128](jsonConfig['notifications'].inputGroup)
local notifications = {
	{u8('Покупка/Продажа'), 'resale'},
	{u8('Статус лавки'), 'action'},
	{u8('Баланс в сообщение'), 'balance'},
	{u8('Статистика в сообщение'), 'statistics'},
	{u8('Смерть персонажа'), 'death'},
	{u8('Больше 10 пунктов в окне'), 'moreItems'},
	{u8('Логирование урона'), 'damage'},
	{u8('Сообщения от Админов (/ao)'), 'message'},
	{u8('Ловля лавки'), 'catchingShop'},
	{u8('Статус сервера'), {
		{u8('Сервер закрыл соединение!'), 32},
		{u8('Соединение потеряно!'), 33},
		{u8('Вы подключились к серверу!'), 34},
		{u8('Попытка подключения не удалась!'), 35},
		{u8('Неправильный пароль от сервера!'), 37}
	}}
}

-->> Create Notifications Bool
for k, v in ipairs(notifications) do
	if type(v[2]) ~= 'table' then
		notifications[k][3] = imgui.new.bool(jsonConfig['notifications'][v[2]])
	end
end

for k, v in ipairs(notifications[#notifications][2]) do
	notifications[#notifications][2][k][3] = imgui.new.bool(jsonConfig['notifications']['status' .. v[2]])
end

-->> Market Settings
local TextDraw_Remove = {{4, 203, 347}, {4, 204, 349}, {2, 208, 351}}
local fontSize = imgui.new.float(jsonConfig['market'].fontSize)
local fontAlpha = imgui.new.float(jsonConfig['market'].fontAlpha)
local marketAlpha = imgui.new.float(jsonConfig['market'].marketAlpha)
local marketSize = {x = imgui.new.int(jsonConfig['market'].marketSize.x), y = imgui.new.int(jsonConfig['market'].marketSize.y)}
local marketBool = {now = imgui.new.bool(false), always = imgui.new.bool(jsonConfig['market'].marketBool)}
local marketColor = {text = imgui.new.float[3](jsonConfig['market'].marketColor.text), window = imgui.new.float[3](jsonConfig['market'].marketColor.window)}
local marketPos = imgui.ImVec2(jsonConfig['market'].marketPos.x, jsonConfig['market'].marketPos.y)
local marketShop = {}

-->> Main
function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	while not sampIsLocalPlayerSpawned() do wait(0) end
	
	sms('Активация: /repw')
	getInfo()
	sampRegisterChatCommand('repw', function() window[0] = not window[0] end)

	for k, v in pairs(jsonLog) do
		local arr = {}
		if type(v[1]) == 'string' then
			for line in v[1]:gmatch('[^\n]+') do
				table.insert(arr, line)
			end
			jsonLog[k][1] = arr
			json('Log.json'):save(jsonLog)
		end
	end

	while true do wait(0)
		for i = 1, 4096 do
			if sampTextdrawIsExists(i) then
				local style = sampTextdrawGetStyle(i)
				local x, y = sampTextdrawGetPos(i)
				local text = sampTextdrawGetString(i)
				for i_table = 1, #TextDraw_Remove do
					if (style == TextDraw_Remove[i_table][1] and math.floor(x) == TextDraw_Remove[i_table][2] and math.floor(y) == TextDraw_Remove[i_table][3]) then
						if not marketBool['always'][0] then marketBool['now'][0] = true end
						sampTextdrawDelete(i)
					end
				end
			end
		end
	end
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	getTheme()

	fonts = {}
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()

	-->> Default Font
	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(u8(getWorkingDirectory() .. '/ReplaceWindow/EagleSans-Regular.ttf'), 20, nil, glyph_ranges)

	-->> Other Fonts
	for k, v in ipairs({15, 18, 25, 30}) do
		fonts[v] = imgui.GetIO().Fonts:AddFontFromFileTTF(u8(getWorkingDirectory() .. '/ReplaceWindow/EagleSans-Regular.ttf'), v, nil, glyph_ranges)
	end

	-->> Logo
	logo = imgui.CreateTextureFromFile(u8(getWorkingDirectory() .. '/ReplaceWindow/ReplaceWindow.png'))
end)

local windowFrame = imgui.OnFrame(
	function() return window[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
	function(player)
		imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  	imgui.SetNextWindowSize(imgui.ImVec2(1000, 475), imgui.Cond.FirstUseEver)
		imgui.Begin(thisScript().name, window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysUseWindowPadding)
			imgui.BeginGroup()
				imgui.SetCursorPosY(30 / 2)
				imgui.Image(logo, imgui.ImVec2(200, 130))

				imgui.SetCursorPosY(160)
				local buttons = {u8('Palatka.lua'), u8('Лог'), u8('Уведомления'), u8('Обновления'), u8('Новости'), u8('Настройки'), u8('Автор')}
				for k, v in ipairs(buttons) do
					if imgui.ActiveButton(v, imgui.ImVec2(200, 40)) then menu = k end
				end
			imgui.EndGroup()

			imgui.SameLine()

			imgui.PushStyleColor(imgui.Col.ChildBg, convertDecimalToRGBA(palette.accent2.color_900))
			imgui.BeginChild('right', imgui.ImVec2(-1, -1), true, imgui.WindowFlags.NoScrollbar)
				if menu == 1 then
					imgui.SetCursorPosY(45)
					imgui.FText(u8('{TextDisabled}[Вопрос]: {Text}Что это такое?'))
					imgui.FText(u8('{TextDisabled}[Ответ]: {Text}Palatka.lua - это качественный платный скрипт, который позволяет абсолютно любому'))
					imgui.FText(u8('игроку, без какого-либо опыта, без больших бюджетов - быстро начать поднимать деньги на'))
					imgui.FText(u8('Центральном Рынке.'))
					imgui.NewLine()
						imgui.FText(u8('{TextDisabled}[Вопрос]: {Text}Почему мне нужно выбрать именно этот скрипт?'))
						imgui.FText(u8('{TextDisabled}[Ответ]: {Text}Скрипт на рынке уже более двух лет. Более трех тысяч пользователей и продолжает'))
						imgui.FText(u8('увеличиваться. Сотни положительных отзывов.'))
					imgui.NewLine()
						imgui.FText(u8('{TextDisabled}[Вопрос]: {Text}Где мне можно подробно узнать про него?'))
						imgui.FText(u8('{TextDisabled}[Ответ]: {Text}Видео обзоры, подробная информация и отзывы тут:'))
						imgui.SameLine()
						imgui.Link('YouTube', 'https://youtu.be/cvW87APbsMo')
						imgui.SameLine()
						imgui.FText(u8('и'))
						imgui.SameLine()
						imgui.Link('Blast Hack', 'https://www.blast.hk/threads/77559')
					imgui.NewLine()
						imgui.FText(u8('{TextDisabled}[Вопрос]: {Text}А я могу получить какой-нибудь бонус?'))
						imgui.FText(u8('{TextDisabled}[Ответ]: {Text}При покупке подписки назови промокод "{ButtonActive}Гречка{Text}", чтобы получить {ButtonActive}+1 бесплатный месяц{Text} к'))
						imgui.FText(u8('подписке. Действует только для новых пользователей.'))
				elseif menu == 2 then
					imgui.BeginGroup()
						imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8(('Статистика [%s]:'):format(date_select or 'Дата не выбрана'))).x) / 2)
						imgui.FText(u8(('{Text}Статистика [{TextDisabled}%s{Text}]:'):format(date_select or 'Дата не выбрана')))

						imgui.CenterText(u8('Получили с продажи: $') .. (date_select ~= nil and money_separator(jsonLog[date_select][2]) or '0'), imgui.GetWindowWidth() * 0.5)
						imgui.SameLine()
						imgui.CenterText(u8('Получили с продажи: VC$') .. (date_select ~= nil and money_separator(jsonLog[date_select][4]) or '0'), imgui.GetWindowWidth() * 1.5)

						imgui.CenterText(u8('Потратили на покупку: $') .. (date_select ~= nil and money_separator(jsonLog[date_select][3]) or '0'), imgui.GetWindowWidth() * 0.5)
						imgui.SameLine()
						imgui.CenterText(u8('Потратили на покупку: VC$') .. (date_select ~= nil and money_separator(jsonLog[date_select][5]) or '0'), imgui.GetWindowWidth() * 1.5)
					imgui.EndGroup()

					imgui.BeginGroup()
						imgui.PushItemWidth(-1)
						imgui.InputTextWithHint('##search', u8('Поиск'), searchLog, ffi.sizeof(searchLog))
						imgui.PopItemWidth()

						if imgui.ActiveButton(u8('Лог'), imgui.ImVec2((imgui.GetWindowWidth() - 20) / 3)) then logMenu = 0 end
						imgui.SameLine()
						if imgui.ActiveButton(u8('Выбрать дату'), imgui.ImVec2((imgui.GetWindowWidth() - 20) / 3)) then imgui.OpenPopup(u8('Выбор даты')) end; changeDate()
						imgui.SameLine()
						if imgui.ActiveButton(u8('Предметы'), imgui.ImVec2((imgui.GetWindowWidth() - 20) / 3)) then logMenu = 1 end

						if imgui.ActiveButton(u8('Статистика за всё время'), imgui.ImVec2(-1)) then imgui.OpenPopup(u8('Статистика за всё время')) end; statsAllTime()
					imgui.EndGroup()

					if date_select and jsonLog[date_select][1] then
						if logMenu == 0 then
							imgui.BeginChild('log', imgui.ImVec2(-1, -1), true)
								for i = #jsonLog[date_select][1], 1, -1 do
									if u8:decode(ffi.string(searchLog)) ~= 0 and string.find(string.nlower(jsonLog[date_select][1][i]), string.nlower(u8:decode(ffi.string(searchLog))), nil, true) then
										imgui.FText(u8(jsonLog[date_select][1][i]), 18)
									end
								end
							imgui.EndChild()
						else
							local array = {}
							local sArray = {}
							for k, v in pairs(jsonLog[date_select][1]) do
								local fullString = v:find('продал') and v:match('продал "(.+)" за') or v:match('"(.+)" за')
								local count = fullString:find('%(%d+ шт%.%)$') and fullString:match('%((%d+) шт%.%)$') or 1
								local item = (fullString:find('%(%d+ шт%.%)$') and fullString:gsub('%(%d+ шт%.%)$', '') or fullString):gsub(' $', '')
								if not array[item] then array[item] = {['buy'] = 0, ['sell'] = 0} end
								array[item][v:find('продал') and 'buy' or 'sell'] = array[item][v:find('продал') and 'buy' or 'sell'] + count
							end

							for k, v in pairs(array) do
								table.insert(sArray, {name = k, buy = v.buy, sell = v.sell})
							end

							table.sort(sArray, function(a, b)
								if sortLog == 1 then
									return a.buy > b.buy
								elseif sortLog == 2 then
									return a.buy < b.buy
								elseif sortLog == 3 then
									return a.sell > b.sell
								elseif sortLog == 4 then
									return a.sell < b.sell
								end
							end)
							
							local dl = imgui.GetWindowDrawList()
							local p = imgui.GetCursorScreenPos()
							local sizeRight = 470

							imgui.PushFont(fonts[18])
								imgui.BeginChild('statsItem', imgui.ImVec2(-1, -1), true)
									dl:AddLine(imgui.ImVec2(p.x + sizeRight - 2, p.y + 2), imgui.ImVec2(p.x + sizeRight - 2, p.y + 271), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['Separator']]))
									dl:AddLine(imgui.ImVec2(p.x + sizeRight + 150 - 2, p.y + 2), imgui.ImVec2(p.x + sizeRight + 150 - 2, p.y + 271), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['Separator']]))
									
									imgui.SetCursorPosX((sizeRight - imgui.CalcTextSize(u8('Название:')).x) / 2)
									imgui.Text(u8('Название:'))
					
									imgui.SameLine()
					
									imgui.SetCursorPosX(sizeRight + (150 - imgui.CalcTextSize(u8('Я купил:')).x) / 2)
									imgui.Text(u8('Я купил:'))
									if imgui.IsItemClicked() then sortLog = (sortLog == 1) and 2 or 1 end
					
									imgui.SameLine()
					
									imgui.SetCursorPosX(sizeRight + (450 - imgui.CalcTextSize(u8('Я продал:')).x) / 2)
									imgui.Text(u8('Я продал:'))
									if imgui.IsItemClicked() then sortLog = (sortLog == 3) and 4 or 3 end
					
									imgui.Separator()
					
									for k, v in ipairs(sArray) do
										if u8:decode(ffi.string(searchLog)) ~= 0 and string.find(string.nlower(v.name), string.nlower(u8:decode(ffi.string(searchLog))), nil, true) then
											imgui.SetCursorPosX((sizeRight - imgui.CalcTextSize(u8(v.name)).x) / 2)
											imgui.Text(u8(v.name))
					
											imgui.SameLine()
					
											local count1 = u8(money_separator(v.buy) .. ' шт.')
											imgui.SetCursorPosX(sizeRight + (150 - imgui.CalcTextSize(count1).x) / 2)
											imgui.Text(count1)
					
											imgui.SameLine()
					
											local count1 = u8(money_separator(v.sell) .. ' шт.')
											imgui.SetCursorPosX(sizeRight + (450 - imgui.CalcTextSize(count1).x) / 2)
											imgui.Text(count1)
										end
									end 
								imgui.EndChild()
							imgui.PopFont()
						end
					else
						imgui.SetCursorPos(imgui.ImVec2((imgui.GetWindowWidth() - imgui.CalcTextSize(u8('Здесь пока ничего нету :(')).x) / 2, (imgui.GetWindowHeight() + 175 - 20) / 2))
						imgui.Text(u8('Здесь пока ничего нету :('))
					end
				elseif menu == 3 then
					imgui.PushFont(fonts[15])
					imgui.Text(u8('1 Шаг: Открываем Telegram и заходим в бота «@BotFather»')); imgui.SameLine(); imgui.Link('(https://t.me/BotFather)', 'https://t.me/BotFather')
					imgui.Text(u8('2 Шаг: Вводим команду «/newbot» и следуем инструкциям'))
					imgui.Text(u8('3 Шаг: После успешного создания бота Вы получите токен')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Пример сообщения с токеном:')); imgui.SameLine(); imgui.TextDisabled('Use this token to access the HTTP API: 6123464634:AAHgee28hWg5yCFICHfeew231pmKhh19c')
					imgui.Text(u8('4 Шаг: Теперь Вам нужно создать группу и добавить туда бота. Найти ссылку на бота можете в сообщение с токеном'))
					imgui.Text(u8('5 Шаг: Вам нужно узнать ID группы, которую Вы создали. Для этого я использовал бота «@getmyid_bot»')); imgui.SameLine(); imgui.Link('(https://t.me/getmyid_bot)', 'https://t.me/getmyid_bot')
					imgui.Text(u8('6 Шаг: После добавления бота «@getmyid_bot» в чат Вам отправится ID Вашей группы в поле «Current chat ID»')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Пример сообщения с ID группы:')); imgui.SameLine(); imgui.TextDisabled('Current chat ID: -71950130')
					imgui.Text(u8('7 Шаг: Теперь нам нужно ввести токен и ID группы в поля ниже. После нажмите на кнопку «Тестовое сообщение» в скрипте')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Если в чат группы отправится сообщение, то Вы всё сделали правильно'))
					imgui.PopFont()

					imgui.NewLine()

					imgui.SetCursorPosY(265)
					imgui.CenterText(u8(' Данные для бота:'))

					imgui.SetCursorPosX((imgui.GetWindowWidth() - 300) / 2)
					imgui.BeginGroup()
						imgui.PushItemWidth(300)
							if imgui.InputTextWithHint('##inputToken', u8('Введите токен'), inputToken, ffi.sizeof(inputToken), imgui.InputTextFlags.Password) then
								jsonConfig['notifications'].inputToken = ffi.string(inputToken)
								json('Config.json'):save(jsonConfig)
							end
							if imgui.InputTextWithHint('##inputGroup', u8('Введите ID группы'), inputGroup, ffi.sizeof(inputGroup), imgui.InputTextFlags.Password) then
								jsonConfig['notifications'].inputGroup = ffi.string(inputGroup)
								json('Config.json'):save(jsonConfig)
							end
						imgui.PopItemWidth()
						if imgui.Button(u8('Тестовое сообщение'), imgui.ImVec2(300)) then
							sendTelegram('Тестовое сообщение из скрипта!')
						end
					imgui.EndGroup()
				elseif menu == 4 then
					imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Список Обновлений:'), 30).x) / 2 )
					imgui.FText(u8('Список Обновлений:'), 30)

					if infoGithub.update then
						imgui.BeginChild('update', imgui.ImVec2(-1, -1), false)
							for i = #infoGithub.update, 1, -1 do
								local v = infoGithub.update[i]
								imgui.BeginChild('update' .. i, imgui.ImVec2(-1, 30 + 18 * #v.text + 5 * (#v.text + 2)), true)
									imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(v.title, 30).x) / 2 )
									imgui.FText(v.title, 30)

									for k, v in ipairs(v.text) do
										imgui.FText('- ' .. v, 18)
									end
				
									local date_text = u8('От ') .. v.date
									imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
									imgui.FText('{TextDisabled}' .. date_text, 18)
								imgui.EndChild()
							end
						imgui.EndChild()
					end
				elseif menu == 5 then
					imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Новости:'), 30).x) / 2 )
					imgui.FText(u8('Новости:'), 30)

					if infoGithub.news then
						imgui.BeginChild('news', imgui.ImVec2(-1, -1), false)
							for i = #infoGithub.news, 1, -1 do
								local v = infoGithub.news[i]
								imgui.BeginChild('update' .. i, imgui.ImVec2(-1, 18 * #v.text + 5 * (#v.text + 1)), true)
									for k, v in ipairs(v.text) do
										imgui.FText(v, 18)
									end
				
									local date_text = u8('От ') .. v.date
									imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
									imgui.FText('{TextDisabled}' .. date_text, 18)
								imgui.EndChild()
							end
						imgui.EndChild()
					end
				elseif menu == 6 then
					imgui.PushFont(fonts[18])
					imgui.SetCursorPos(imgui.ImVec2((imgui.GetWindowWidth() * 0.5 - 365) / 2 + 5, (imgui.GetWindowHeight() - 385 + 30) / 2))
					imgui.BeginColorChild('settingsWindow', imgui.ImVec2(365, 385), false)
						imgui.StripChild()
						imgui.BeginColorChild('settingsWindowUnder', imgui.ImVec2(-1, -1), false)
							imgui.CenterText(u8('Настройки окна:'))

							-- imgui.SetCursorPosY(52.5)
							imgui.PushItemWidth(170)
								if imgui.DragFloat(u8('Размер шрифта'), fontSize, 0.01, 0.1, 2.0, "%.1f") then
									jsonConfig['market'].fontSize = fontSize[0]
									json('Config.json'):save(jsonConfig)
								end
								if imgui.DragFloat(u8('Прозрачность шрифта'), fontAlpha, 0.01, 0.0, 1.0, "%.2f") then
									jsonConfig['market'].fontAlpha = fontAlpha[0]
									json('Config.json'):save(jsonConfig)
								end
								if imgui.DragFloat(u8('Прозрачность окна'), marketAlpha, 0.01, 0.0, 1.0, "%.2f") then
									jsonConfig['market'].marketAlpha = marketAlpha[0]
									json('Config.json'):save(jsonConfig)
								end

								if imgui.ColorEdit3(u8('Цвет текста'), marketColor.text) then
									jsonConfig['market'].marketColor.text = {marketColor.text[0], marketColor.text[1], marketColor.text[2]}
									json('Config.json'):save(jsonConfig)
								end
								if imgui.ColorEdit3(u8('Цвет окна'), marketColor.window) then
									jsonConfig['market'].marketColor.window = {marketColor.window[0], marketColor.window[1], marketColor.window[2]}
									json('Config.json'):save(jsonConfig)
								end
							imgui.PopItemWidth()

							imgui.BeginGroup()
								if imgui.ActiveButton(u8('Центр'), imgui.ImVec2(85 - 2.5)) then
									marketPos = imgui.ImVec2(-1, -1)
									jsonConfig['market'].marketPos = {x = marketPos.x, y = marketPos.y}
									json('Config.json'):save(jsonConfig)
								end
								imgui.SameLine()
								if imgui.ActiveButton(u8('Позиция'), imgui.ImVec2(85 - 2.5)) then
									sms('Нажмите {mc}ЛКМ{-1}, чтобы сохранить позицию.')
									window[0], marketBool.now[0] = false, true
									sampSetCursorMode(4)
									lua_thread.create(function()
										while true do
											marketPos = imgui.ImVec2(select(1, getCursorPos()), select(2, getCursorPos()))
											jsonConfig['market'].marketPos = {x = marketPos.x, y = marketPos.y}
											json('Config.json'):save(jsonConfig)
											if imgui.IsMouseClicked(0) then
												sms('Местоположение сохранено.')
												
												window[0], marketBool.now[0] = true, false
												sampSetCursorMode(0)
												break
											end
											wait(0)
										end
									end)
								end
								imgui.SameLine()
								imgui.Text(u8('Местоположение окна'))
							imgui.EndGroup()

							imgui.PushItemWidth(85 - 2.5)
								if imgui.DragInt('##marketSizeX', marketSize.x, 1, 0, select(1, getScreenResolution()), "%.0f") then
									jsonConfig['market'].marketSize.x = marketSize.x[0]
									json('Config.json'):save(jsonConfig)
								end
								imgui.SameLine()
								if imgui.DragInt('##marketSizeY', marketSize.y, 1, 0, select(2, getScreenResolution()), "%.0f") then
									jsonConfig['market'].marketSize.y = marketSize.y[0]
									json('Config.json'):save(jsonConfig)
								end
								imgui.SameLine()
								imgui.Text(u8('Размер окна'))
							imgui.PopItemWidth()

							imgui.BeginGroup()
								if imgui.Button(u8('Тестовые строчки'), imgui.ImVec2(170)) then
									marketShop = {}
									for i = 1, 10 do marketShop[i] = 'Вы купили Семейный талон (1 шт.) у игрока Test за $10000' end
								end
								imgui.SameLine()
								imgui.Text(u8('Для настройки окна'))

								if imgui.ActiveButton(u8(marketBool.now[0] and 'Включено' or 'Выключено'), imgui.ImVec2(170)) then marketBool.now[0] = not marketBool.now[0] end
								imgui.SameLine()
								imgui.Text(u8('Статус окна'))

								if imgui.ActiveButton(u8(marketBool.always[0] and 'Да' or 'Нет') .. '##marketBool.always[0]', imgui.ImVec2(170)) then
									marketBool.always[0] = not marketBool.always[0]
									jsonConfig['market'].marketBool = marketBool.always[0]
									json('Config.json'):save(jsonConfig)
								end
								imgui.SameLine()
								imgui.Text(u8('Окно всегда выключено'))

								if imgui.ActiveButton(u8(notifications[6][3][0] and 'Да' or 'Нет') .. '##notifications[6][3][0]', imgui.ImVec2(170)) then
									notifications[6][3][0] = not notifications[6][3][0]
									jsonConfig['notifications']['moreItems'] = notifications[6][3][0]
									json('Config.json'):save(jsonConfig)
								end
								imgui.SameLine()
								imgui.Text(u8('Больше 10 пунктов'))
							imgui.EndGroup()

						imgui.EndColorChild()
					imgui.EndColorChild()
					
					imgui.SameLine()

					imgui.BeginGroup()
						imgui.SetCursorPosX((imgui.GetWindowWidth() * 1.5 - 365) / 2 - 5)
						imgui.BeginGroup()
							imgui.BeginColorChild('settingsNotf', imgui.ImVec2(365, 325), false)
								imgui.StripChild()
								imgui.BeginColorChild('settingsNotfUnder', imgui.ImVec2(-1, -1), false)
									imgui.CenterText(u8('Настройки уведомлений:'))

									for k, v in ipairs(notifications) do
										if k == #notifications then
											if imgui.ActiveButton('S', imgui.ImVec2(18 + 10)) then imgui.OpenPopup(v[1]) end
											imgui.SameLine(); imgui.Text(v[1])
											settingsStatus(v[2])
										else
											if k ~= 6 then
												if imgui.Checkbox(v[1], v[3]) then
													jsonConfig['notifications'][v[2]] = v[3][0]
													json('Config.json'):save(jsonConfig)
												end
											end
										end
									end
								imgui.EndColorChild()
							imgui.EndColorChild()

							imgui.BeginColorChild('settingsMain', imgui.ImVec2(365, 55), false)
								imgui.StripChild()
								imgui.BeginColorChild('settingsMainUnder', imgui.ImVec2(-1, -1), false)
									imgui.CenterText(u8('Настройки скрипта:'))

									imgui.PushItemWidth(170)
										if imgui.ColorEdit3(u8('Цвет скрипта'), scriptColor) then getTheme() end
									imgui.PopItemWidth()
								imgui.EndColorChild()
							imgui.EndColorChild()
						imgui.EndGroup()
					imgui.EndGroup()
					imgui.PopFont()
				elseif menu == 7 then
					imgui.PushFont(fonts[30])
						imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8('Автор скрипта: Rice.')).x) / 2)
						imgui.Text(u8('Автор скрипта:'))
						imgui.SameLine()
						imgui.TextColored(convertDecimalToRGBA(palette.accent1.color_500), 'Rice.')
					imgui.PopFont()

					imgui.SetCursorPos(imgui.ImVec2((imgui.GetWindowWidth() * 0.5 - 300) / 2, (imgui.GetWindowHeight() - 195) / 2))
					imgui.BeginChild('Contacts', imgui.ImVec2(300, 195), true)
						imgui.CenterText(u8('Контакты:'))
						if imgui.ColorsButton(u8('ВКонтакте'), imgui.ImVec2(-1, 50), {'0077ff', '006EEB', '0063D3'}) then os.execute('explorer https://vk.com/id324119075') end
						if imgui.ColorsButton('Telegram', imgui.ImVec2(-1, 50), {'28a8eb', '1A9ADD', '118ECF'}) then os.execute('explorer https://t.me/Xkelling') end
						if imgui.ColorsButton('BlastHack', imgui.ImVec2(-1, 50), {'646464', '5B5B5B', '505050'}) then os.execute('explorer https://www.blast.hk/members/371780/') end
					imgui.EndChild()

					imgui.SameLine()

					imgui.SetCursorPos(imgui.ImVec2((imgui.GetWindowWidth() * 1.5 - 300) / 2, (imgui.GetWindowHeight() - 195) / 2))
					imgui.BeginChild('Other', imgui.ImVec2(300, 195), true)
						imgui.CenterText(u8('Остальное:'))
						if imgui.ColorsButton(u8('Telegram Канал'), imgui.ImVec2(-1, 77.5), {'28a8eb', '1A9ADD', '118ECF'}) then os.execute('explorer https://t.me/ReplaceWindow') end
						if imgui.ColorsButton(u8('Тема на BlastHack'), imgui.ImVec2(-1, 77.5), {'646464', '5B5B5B', '505050'}) then os.execute('explorer https://www.blast.hk/threads/128857/') end
					imgui.EndChild()

					imgui.SetCursorPosY(imgui.GetWindowHeight() * 0.875)
					imgui.CenterText(u8('Нашли баг/недоработку, либо хотите предложить идею для скрипта?'))
					imgui.CenterText(u8('Свяжитесь с Автором с помощью ВКонтакте или Telegram.'))
				end

				imgui.PushFont(fonts[15])
					imgui.SetCursorPosX(imgui.GetWindowWidth() - 55)
					imgui.SetCursorPosY(5)
					if imgui.Button('X', imgui.ImVec2(50)) then window[0] = false end
				imgui.PopFont()
			imgui.EndChild()
			imgui.PopStyleColor()
		imgui.End()
	end
)

local updateFrame = imgui.OnFrame(
	function() return (infoGithub.version and infoGithub.version.v ~= thisScript().version) and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
	function(player)
	  imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  imgui.SetNextWindowSize(imgui.ImVec2(700, 400), imgui.Cond.FirstUseEver)
		imgui.Begin('update', update, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)

			imgui.FText(u8('{ButtonActive}Доступно обновление!'), 30)

			imgui.PushFont(fonts[18])
			imgui.TextDisabled(u8('Replace Window | Версия: #' .. infoGithub.version.v))
			imgui.PopFont()

			imgui.NewLine()

			imgui.FText(u8('{ButtonActive}Список изменений:'), 25)

			imgui.BeginChild('update', imgui.ImVec2(-1, -40), false)
				for k, v in ipairs(infoGithub.update[#infoGithub.update].text) do
					imgui.SetCursorPosX(20)
					imgui.FText(('{ButtonActive}%s) {Text}%s'):format(k, v), 20)
				end
			imgui.EndChild()

			if imgui.Button(u8('Отмена'), imgui.ImVec2(150, -1)) then infoGithub.version.v = thisScript().version end
			imgui.SameLine(imgui.GetWindowWidth() - 155)
			if imgui.ActiveButton(u8('Установить'), imgui.ImVec2(150, -1)) then
				downloadUrlToFile(infoGithub.version.url,thisScript().path, function(id, status, p1, p2)
					if status == dlstatus.STATUS_ENDDOWNLOADDATA then
						sms('Загрузка обновления завершена.')
						lua_thread.create(function() wait(500) thisScript():reload() end)
					end
				end)
			end

		imgui.End()
	end
)

local messageFrame = imgui.OnFrame(
	function() return (infoGithub.news and #infoGithub.news ~= lastNewsCheck) and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
	function(player)
	  imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  imgui.SetNextWindowSize(imgui.ImVec2(800, 500), imgui.Cond.FirstUseEver)
		imgui.Begin('message', message, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)

		imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Новые новости!'), 30).x) / 2 )
		imgui.FText(u8('{ButtonActive}Новые новости!'), 30)

		imgui.BeginChild('message', imgui.ImVec2(-1, -40), false)
			for i = #infoGithub.news, lastNewsCheck + 1, -1 do
				local v = infoGithub.news[i]
				imgui.BeginChild('message' .. i, imgui.ImVec2(-1, (#v.text + 1) * 5 + #v.text * 18), true)
					for k, v in ipairs(v.text) do
						imgui.FText(v, 18)
					end

					local date_text = u8('От ') .. v.date
					imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
					imgui.FText('{TextDisabled}' .. date_text, 18)
				imgui.EndChild()
			end
		imgui.EndChild()

		if imgui.Button(u8('Закрыть'), imgui.ImVec2(150, -1)) then lastNewsCheck = #infoGithub.news end
		imgui.SameLine(imgui.GetWindowWidth() - 155)
		if imgui.ActiveButton(u8('Прочитал'), imgui.ImVec2(150, -1)) then
			lastNewsCheck = #infoGithub.news
			jsonConfig['script'].lastNewsCheck = lastNewsCheck
			json('Config.json'):save(jsonConfig)
		end

		imgui.End()
	end
)

local marketFrame = imgui.OnFrame(
	function() return not marketBool.always[0] and marketBool.now[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
	function(player)
		player.HideCursor = true
		local sx, sy = getScreenResolution()
		local position = marketPos.x ~= -1 and marketPos or imgui.ImVec2((sx - marketSize.x[0]) / 2, sy - marketSize.y[0] - sy * 0.01)
		imgui.SetNextWindowPos(position, imgui.Cond.Always)
		imgui.SetNextWindowSize(imgui.ImVec2(marketSize.x[0], marketSize.y[0]), imgui.Cond.Always)
		imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(marketColor.text[0], marketColor.text[1], marketColor.text[2], fontAlpha[0]))
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(marketColor.window[0], marketColor.window[1], marketColor.window[2], marketAlpha[0]))
			imgui.Begin('market', market, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
				imgui.SetWindowFontScale(fontSize[0])
				for i = #marketShop, 1, -1 do
					imgui.Text(u8(marketShop[i]))
				end
			imgui.End()
		imgui.PopStyleColor(2)
	end
)

function statsAllTime()
	if imgui.BeginPopupModal(u8('Статистика за всё время'), _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then

			imgui.CenterText(u8('Деньги:'))
			local array = {0, 0, 0, 0}
			for k, v in pairs(jsonLog) do
				array[1] = array[1] + v[2]
				array[2] = array[2] + v[3]
				array[3] = array[3] + v[4]
				array[4] = array[4] + v[5]
			end
			imgui.CenterText(u8('Получили с продажи: $' .. money_separator(array[1])))
			imgui.CenterText(u8('Потратили на покупку: $' .. money_separator(array[2])))
			imgui.CenterText(u8('Получили с продажи: VC$' .. money_separator(array[3])))
			imgui.CenterText(u8('Потратили на покупку: VC$' .. money_separator(array[4])))
			imgui.NewLine()

			local array = {0, {}}
			local sArray = {}
			for k, v in pairs(jsonLog) do
				for k, v in ipairs(v[1]) do
					local fullString = v:find('продал') and v:match('продал "(.+)" за') or v:match('"(.+)" за')
					local count = fullString:find('%(%d+ шт%.%)$') and fullString:match('%((%d+) шт%.%)$') or 1
					local item = (fullString:find('%(%d+ шт%.%)$') and fullString:gsub('%(%d+ шт%.%)$', '') or fullString):gsub(' $', '')
					if not array[2][item] then array[2][item] = {['buy'] = 0, ['sell'] = 0} end
					array[2][item][v:find('продал') and 'buy' or 'sell'] = array[2][item][v:find('продал') and 'buy' or 'sell'] + count
					if array[1] < imgui.CalcTextSize(u8(item)).x then array[1] = imgui.CalcTextSize(u8(item)).x end
				end
			end
			array[1] = (array[1] == 0 and 150 or array[1]) + 10

			for k, v in pairs(array[2]) do
				table.insert(sArray, {name = k, buy = v.buy, sell = v.sell})
			end

			table.sort(sArray, function(a, b)
				if sortLog == 1 then
					return a.buy > b.buy
				elseif sortLog == 2 then
					return a.buy < b.buy
				elseif sortLog == 3 then
					return a.sell > b.sell
				elseif sortLog == 4 then
					return a.sell < b.sell
				end
			end)
			
			imgui.CenterText(u8('Предметы:'))

			imgui.PushItemWidth(-1)
			imgui.InputTextWithHint('##search', u8('Поиск'), searchLog, ffi.sizeof(searchLog))
			imgui.PopItemWidth()

			local dl = imgui.GetWindowDrawList()
			local p = imgui.GetCursorScreenPos()
			imgui.BeginChild('statsItem', imgui.ImVec2(array[1] + 300, 300), true)
				dl:AddLine(imgui.ImVec2(p.x + array[1] - 2, p.y + 2), imgui.ImVec2(p.x + array[1] - 2, p.y + 298), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['Separator']]))
				dl:AddLine(imgui.ImVec2(p.x + array[1] + 150 - 2, p.y + 2), imgui.ImVec2(p.x + array[1] + 150 - 2, p.y + 298), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['Separator']]))
				
				imgui.SetCursorPosX((array[1] - imgui.CalcTextSize(u8('Название:')).x) / 2)
				imgui.Text(u8('Название:'))

				imgui.SameLine()

				imgui.SetCursorPosX(array[1] + (150 - imgui.CalcTextSize(u8('Я купил:')).x) / 2)
				imgui.Text(u8('Я купил:'))
				if imgui.IsItemClicked() then sortLog = (sortLog == 1) and 2 or 1 end

				imgui.SameLine()

				imgui.SetCursorPosX(array[1] + (450 - imgui.CalcTextSize(u8('Я продал:')).x) / 2)
				imgui.Text(u8('Я продал:'))
				if imgui.IsItemClicked() then sortLog = (sortLog == 3) and 4 or 3 end

				imgui.Separator()

				for k, v in pairs(sArray) do
					if u8:decode(ffi.string(searchLog)) ~= 0 and string.find(string.nlower(v.name), string.nlower(u8:decode(ffi.string(searchLog))), nil, true) then
						imgui.SetCursorPosX((array[1] - imgui.CalcTextSize(u8(v.name)).x) / 2)
						imgui.Text(u8(v.name))

						imgui.SameLine()

						local count1 = u8(money_separator(v.buy) .. ' шт.')
						imgui.SetCursorPosX(array[1] + (150 - imgui.CalcTextSize(count1).x) / 2)
						imgui.Text(count1)

						imgui.SameLine()

						local count1 = u8(money_separator(v.sell) .. ' шт.')
						imgui.SetCursorPosX(array[1] + (450 - imgui.CalcTextSize(count1).x) / 2)
						imgui.Text(count1)
					end
				end
			imgui.EndChild()

			if imgui.Button(u8('Закрыть'), imgui.ImVec2(-1, 30)) then
				imgui.CloseCurrentPopup()
			end

		imgui.EndPopup()
	end
end

function changeDate()
	if imgui.BeginPopupModal(u8('Выбор даты'), _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
		imgui.SetWindowSizeVec2(imgui.ImVec2(300, 305))

		imgui.BeginChild('up', imgui.ImVec2(-1, imgui.GetWindowWidth() - 70), true)

			local temp_table = {}
			for k, v in pairs(jsonLog) do
				local d, m, y = k:match('(%d+)%.(%d+)%.(%d+)')
				table.insert(temp_table, {key = k, date = tonumber(y .. m .. d)})
			end
			table.sort(temp_table, function(a, b) return a.date > b.date end)

			for k, v in ipairs(temp_table) do
				if imgui.ActiveButton(v.key, imgui.ImVec2(-1)) then date_select = v.key; imgui.CloseCurrentPopup() end
			end
		imgui.EndChild()

		if imgui.Button(u8('Закрыть'), imgui.ImVec2(-1, 30)) then
			imgui.CloseCurrentPopup()
		end

		imgui.EndPopup()
	end
end

function settingsStatus(array)
	if imgui.BeginPopupModal(u8('Статус сервера'), _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
		imgui.SetWindowSizeVec2(imgui.ImVec2(300, 235))
		for k, v in ipairs(array) do
			if imgui.Checkbox(v[1], v[3]) then
				jsonConfig['notifications']['status' .. v[2]] = v[3][0]
				json('Config.json'):save(jsonConfig)
			end
		end
		if imgui.Button(u8('Закрыть'), imgui.ImVec2(-1, 30)) then
			imgui.CloseCurrentPopup()
		end
		imgui.EndPopup()
	end
end

-->> SAMP EVENTS
function samp.onServerMessage(color, text)
	local hookMarket = {
		{text = '^%s*(.+) купил у вас (.+), вы получили(.+)$(.+) от продажи %(комиссия %d+ процент%(а%)%)$', color = -1347440641, key = 2},
		{text = '^%s*Вы успешно продали (.+) торговцу (.+), с продажи получили(.+)$(.+) %(комиссия %d+ процент%(а%)%)$', color = -65281, key = 2},
		{text = '^%s*Вы купили (.+) у игрока (.+) за(.+)$(.+)', color = -1347440641, key = 3},
		{text = '^%s*Вы успешно купили (.+) у (.+) за(.+)$(.+)', color = -65281, key = 3}
	}

	local hookActionsShop = {
		'^%s*%[Информация%] {FFFFFF}Вы отказались от аренды лавки!',
		'^%s*%[Информация%] {FFFFFF}Вы сняли лавку!',
		'^%s*%[Информация%] {FFFFFF}Ваша лавка была закрыта, из%-за того что вы её покинули!'
	}

	for k, v in ipairs(hookMarket) do
		if string.find(text, v['text']) and v['color'] == color then
			local args = splitArguments({text:match(v['text'])}, text:find('купил у вас'))
			local textLog = getTypeMessageMarket(text, args)
			
			if jsonLog[os.date('%d.%m.%Y')] == nil then jsonLog[os.date('%d.%m.%Y')] = {{}, 0, 0, 0, 0} end

			table.insert(jsonLog[os.date('%d.%m.%Y')][1], textLog)
			jsonLog[os.date('%d.%m.%Y')][(#args['ViceCity'] == 3 and v.key + 2 or v.key)] = jsonLog[os.date('%d.%m.%Y')][(#args['ViceCity'] == 3 and v.key + 2 or v.key)] + args['money']
			json('Log.json'):save(jsonLog)

			if #marketShop >= 10 and not notifications[6][3][0] then marketShop = {} end
			table.insert(marketShop, textLog)

			if notifications[1][3][0] then
				if notifications[4][3][0] then
					textLog = textLog .. '\n\n' .. 'Продали за день: $' .. money_separator(jsonLog[os.date('%d.%m.%Y')][2]) .. '\n' .. 'Скупили за день: $' .. money_separator(jsonLog[os.date('%d.%m.%Y')][3]) .. '\n\n' .. 'Продали за день: VC$' .. money_separator(jsonLog[os.date('%d.%m.%Y')][4]) .. '\n' .. 'Скупили за день: VC$' .. money_separator(jsonLog[os.date('%d.%m.%Y')][5])
				end
				if notifications[3][3][0] then
					textLog = textLog .. '\n\n' .. 'Наличные: $' .. money_separator(getPlayerMoney(PLAYER_HANDLE))
				end
				sendTelegram(textLog)
			end
		end
	end

	if text:find('^%s*%(%( Через 30 секунд вы сможете сразу отправиться в больницу или подождать врачей %)%)%s*$') then
		marketBool['now'][0], marketShop = false, {}
		if notifications[5][3][0] then
			sendTelegram('[Информация] Ваш персонаж умер!')
		end
	end

	for k, v in ipairs(hookActionsShop) do
		if text:find(v) then
			marketBool['now'][0], marketShop = false, {}
			if notifications[2][3][0] then
				sendTelegram(text)
			end
		end
	end

	if color == -2686721 and text:find('.- .-: .+') and notifications[8][3][0] and not text:find('Сообщение до редакции:') and not text:find('%[FOREVER%]') and not text:find('%[Cобиратели%]') and not text:find('%[Риелторское агенство%]') and not text:find('%[PREMIUM%]') then
		sendTelegram('[Сообщения от Администрации] ' .. text)
	end

	if text:find('^%s*%[Подсказка%] {FFFFFF}Вы успешно арендовали лавку для продажи/покупки товара!%s*$') and notifications[9][3][0] then
		sendTelegram('[Информация] Вы успешно арендовали лавку!')
	end
end

function splitArguments(array, key)
	return {
		['name'] = (key and array[1] or array[2]),
		['item'] = (key and array[2] or array[1]),
		['ViceCity'] = array[3],
		['money'] = stringToCount(array[4])
	}
end

function getTypeMessageMarket(text, args)
	local array = {
		['купил у вас'] = '%s %s купил "%s" за%s$%s',
		['Вы купили'] = '%s %s продал "%s" за%s$%s',
		['Вы успешно продали'] = '%s [Чужая Лавка] %s купил "%s" за%s$%s',
		['Вы успешно купили'] = '%s [Чужая Лавка] %s продал "%s" за%s$%s'
	}
	for k, v in pairs(array) do
		if text:find(k) then return string.format(v, os.date('[%H:%M:%S]'), args['name'], args['item'], args['ViceCity'], money_separator(args['money'])) end
	end
end

function stringToCount(text)
	local count = ''
	for line in text:gmatch('%d') do
		count = count .. line
	end
	return tonumber(count)
end

-->> Mimgui Snippets
function imgui.ColorsButton(text, size, colors)
	imgui.PushStyleColor(imgui.Col.Button, imgui.ColorConvertHexToFloat4(colors[1]))
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ColorConvertHexToFloat4(colors[2]))
	imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ColorConvertHexToFloat4(colors[3]))
		local result = imgui.Button(text, size)
	imgui.PopStyleColor(3)
	return result
end

function getTheme()
	jsonConfig['script'].scriptColor = {scriptColor[0], scriptColor[1], scriptColor[2]}
	json('Config.json'):save(jsonConfig)

	local dec = imgui.GetColorU32Vec4(imgui.ImVec4(scriptColor[0], scriptColor[1], scriptColor[2], 1.0))
	local color = bit.tohex(bit.bswap(dec))
	local hex = ('%s'):format(color:sub(1, #color - 2))
	theme(tonumber('0x' .. hex), 1.5, true)
end

function imgui.StripChild()
	local dl = imgui.GetWindowDrawList()
	local p = imgui.GetCursorScreenPos()
	dl:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + 10, p.y + imgui.GetWindowHeight()), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['ButtonActive']]), 3, 5)
	imgui.Dummy(imgui.ImVec2(10, imgui.GetWindowHeight()))
	imgui.SameLine()
end

function imgui.BeginColorChild(...)
	imgui.PushStyleColor(imgui.Col.ChildBg, convertDecimalToRGBA(palette.accent2.color_800))
	imgui.BeginChild(...)
end

function imgui.EndColorChild()
	imgui.EndChild()
	imgui.PopStyleColor(1)
end

function imgui.ActiveButton(name, ...)
	imgui.PushStyleColor(imgui.Col.Button, convertDecimalToRGBA(palette.accent1.color_500))
	imgui.PushStyleColor(imgui.Col.ButtonHovered, convertDecimalToRGBA(palette.accent1.color_400))
	imgui.PushStyleColor(imgui.Col.ButtonActive, convertDecimalToRGBA(palette.accent1.color_300))
	local result = imgui.Button(name, ...)
	imgui.PopStyleColor(3)
	return result
end

function imgui.FText(text, font)
	assert(text)
	local render_text = function(stext)
		local text, colors, m = {}, {}, 1
		while stext:find('{%u%l-%u-%l-}') do
			local n, k = stext:find('{.-}')
			local color = imgui.GetStyle().Colors[imgui.Col[stext:sub(n + 1, k - 1)]]
			if color then
				text[#text], text[#text + 1] = stext:sub(m, n - 1), stext:sub(k + 1, #stext)
				colors[#colors + 1] = color
				m = n
			end
			stext = stext:sub(1, n - 1) .. stext:sub(k + 1, #stext)
		end
		if text[0] then
			for i = 0, #text do
				imgui.TextColored(colors[i] or colors[1], text[i])
				imgui.SameLine(nil, 0)
			end
			imgui.NewLine()
		else imgui.Text(stext) end
	end
	imgui.PushFont(fonts[font])
	render_text(text)
	imgui.PopFont()
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function getSize(text, font)
	assert(text)
	imgui.PushFont(fonts[font])
	local size = imgui.CalcTextSize(text)
	imgui.PopFont()
	return size
end

function money_separator(n)
    local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
    return left..(num:reverse():gsub('(%d%d%d)','%1.'):reverse())..right
end

function string.nlower(s)
	local line_lower = string.lower(s)
	for line in s:gmatch('.') do
		if (string.byte(line) >= 192 and string.byte(line) <= 223) or string.byte(line) == 168 then
			line_lower = string.gsub(line_lower, line, string.char(string.byte(line) == 168 and string.byte(line) + 16 or string.byte(line) + 32), 1)
		end
	end
	return line_lower
end

function imgui.Link(name, link, size)
	local size = size or imgui.CalcTextSize(name)
	local p = imgui.GetCursorScreenPos()
	local p2 = imgui.GetCursorPos()
	local resultBtn = imgui.InvisibleButton('##'..link..name, size)
	if resultBtn then os.execute('explorer '..link) end
	imgui.SetCursorPos(p2)
	if imgui.IsItemHovered() then
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col['ButtonHovered']], name)
		imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['ButtonHovered']]))
	else
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col['ButtonActive']], name)
	end
	return resultBtn
end

-->> Other Function
function getInfo()
	asyncHttpRequest('GET', 'https://raw.githubusercontent.com/Xkelling/Replace-Window/main/info', nil, function(response) infoGithub = decodeJson(response.text) end)
	asyncHttpRequest('GET', ('https://ricetech.ru/replace-window/metrics?nick=%s&server=%s&version=%s'):format(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))), select(1, sampGetCurrentServerAddress()), thisScript().version))
end

function sms(text)
	local color_chat = '7172ee'
	local text = tostring(text):gsub('{mc}', '{' .. color_chat .. '}'):gsub('{%-1}', '{FFFFFF}')
	sampAddChatMessage(string.format('« %s » {FFFFFF}%s', thisScript().name, text), tonumber('0x' .. color_chat))
end

function onReceivePacket(id)
	local list_packets = {
		[32] = {'Сервер закрыл соединение!', 'ID_DISCONNECTION_NOTIFICATION', notifications[#notifications][2][1][3][0]},
		[33] = {'Соединение потеряно!', 'ID_CONNECTION_LOST', notifications[#notifications][2][2][3][0]},
		[34] = {'Вы подключились к серверу!', 'ID_CONNECTION_REQUEST_ACCEPTED', notifications[#notifications][2][3][3][0]},
		[35] = {'Попытка подключения не удалась!', 'ID_CONNECTION_ATTEMPT_FAILED', notifications[#notifications][2][4][3][0]},
		[37] = {'Неправильный пароль от сервера!', 'ID_INVALID_PASSWORD', notifications[#notifications][2][5][3][0]}
	}
	if list_packets[id] and list_packets[id][3] then
		sendTelegram('[Статус сервера] ' .. list_packets[id][1])
	end
end

function samp.onSetPlayerHealth(health)
	if health < lastHealth and notifications[7][3][0] and sampGetGamestate() == 3 then
		sendTelegram('[Уменьшение здоровья] Текущее ХП: ' .. health)
	end
	lastHealth = health
end

function convertDecimalToRGBA(u32, alpha)
	local a = bit.band(bit.rshift(u32, 24), 0xFF) / 0xFF
	local r = bit.band(bit.rshift(u32, 16), 0xFF) / 0xFF
	local g = bit.band(bit.rshift(u32, 8), 0xFF) / 0xFF
	local b = bit.band(u32, 0xFF) / 0xFF
	return imgui.ImVec4(r, g, b, a * (alpha or 1.0))
end

function imgui.ColorConvertHexToFloat4(hex)
	local s = hex:sub(5, 6) .. hex:sub(3, 4) .. hex:sub(1, 2)
	return imgui.ColorConvertU32ToFloat4(tonumber('0xFF' .. s))
end

function url_encode(text)
	local text = string.gsub(text, "([^%w-_ %.~=])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	local text = string.gsub(text, " ", "+")
	return text
end

function sendTelegram(text)
	local url = ('https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s'):format(ffi.string(inputToken), ffi.string(inputGroup), url_encode(u8(text):gsub('{......}', '')))
	asyncHttpRequest('POST', url, nil, function(resolve)
	end, function(err)
		sms('Ошибка при отправке сообщения в Telegram!')
	end)
end

function asyncHttpRequest(method, url, args, resolve, reject)
	local request_thread = effil.thread(function (method, url, args)
	   local requests = require 'requests'
	   local result, response = pcall(requests.request, method, url, args)
	   if result then
		  response.json, response.xml = nil, nil
		  return true, response
	   else
		  return false, response
	   end
	end)(method, url, args)
	-- Если запрос без функций обработки ответа и ошибок.
	if not resolve then resolve = function() end end
	if not reject then reject = function() end end
	-- Проверка выполнения потока
	lua_thread.create(function()
	   local runner = request_thread
	   while true do
		  local status, err = runner:status()
		  if not err then
			 if status == 'completed' then
				local result, response = runner:get()
				if result then
				   resolve(response)
				else
				   reject(response)
				end
				return
			 elseif status == 'canceled' then
				return reject(status)
			 end
		  else
			 return reject(err)
		  end
		  wait(0)
	   end
	end)
end

function theme(color, chroma_multiplier, accurate_shades)
	imgui.SwitchContext()
	palette = monet.buildColors(color, chroma_multiplier, accurate_shades)
	local style = imgui.GetStyle()
	local colors = style.Colors
	local flags = imgui.Col

	imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
	imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)

	imgui.GetStyle().IndentSpacing = 20
	imgui.GetStyle().ScrollbarSize = 12.5
	imgui.GetStyle().GrabMinSize = 10

	imgui.GetStyle().WindowBorderSize = 0
	imgui.GetStyle().ChildBorderSize = 1
	imgui.GetStyle().PopupBorderSize = 1
	imgui.GetStyle().FrameBorderSize = 0
	imgui.GetStyle().TabBorderSize = 0

	imgui.GetStyle().WindowRounding = 3
	imgui.GetStyle().ChildRounding = 3
	imgui.GetStyle().PopupRounding = 3
	imgui.GetStyle().FrameRounding = 3
	imgui.GetStyle().ScrollbarRounding = 1.5
	imgui.GetStyle().GrabRounding = 3
	imgui.GetStyle().TabRounding = 3

	imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.50, 0.50)

	colors[flags.Text] = convertDecimalToRGBA(palette.neutral1.color_50)
	colors[flags.TextDisabled] = convertDecimalToRGBA(palette.neutral1.color_400)
	colors[flags.WindowBg] = convertDecimalToRGBA(palette.accent2.color_900)
	colors[flags.ChildBg] = convertDecimalToRGBA(palette.accent2.color_900)
	colors[flags.PopupBg] = convertDecimalToRGBA(palette.accent2.color_900)
	colors[flags.Border] = convertDecimalToRGBA(palette.accent2.color_300)
	colors[flags.BorderShadow] = imgui.ImVec4(0, 0, 0, 0)
	colors[flags.FrameBg] = convertDecimalToRGBA(palette.accent1.color_600)
	colors[flags.FrameBgHovered] = convertDecimalToRGBA(palette.accent1.color_500)
	colors[flags.FrameBgActive] = convertDecimalToRGBA(palette.accent1.color_400)
	colors[flags.TitleBgActive] = convertDecimalToRGBA(palette.accent1.color_600)
	colors[flags.ScrollbarBg] = convertDecimalToRGBA(palette.accent2.color_800)
	colors[flags.ScrollbarGrab] = convertDecimalToRGBA(palette.accent1.color_600)
	colors[flags.ScrollbarGrabHovered] = convertDecimalToRGBA(palette.accent1.color_500)
	colors[flags.ScrollbarGrabActive] = convertDecimalToRGBA(palette.accent1.color_400)
	colors[flags.CheckMark] = convertDecimalToRGBA(palette.neutral1.color_50)
	colors[flags.SliderGrab] = convertDecimalToRGBA(palette.accent2.color_400)
	colors[flags.SliderGrabActive] = convertDecimalToRGBA(palette.accent2.color_300)
	colors[flags.Button] = convertDecimalToRGBA(palette.accent2.color_700)
	colors[flags.ButtonHovered] = convertDecimalToRGBA(palette.accent1.color_600)
	colors[flags.ButtonActive] = convertDecimalToRGBA(palette.accent1.color_500)
	colors[flags.Header] = convertDecimalToRGBA(palette.accent1.color_800)
	colors[flags.HeaderHovered] = convertDecimalToRGBA(palette.accent1.color_700)
	colors[flags.HeaderActive] = convertDecimalToRGBA(palette.accent1.color_600)
	colors[flags.Separator] = convertDecimalToRGBA(palette.accent2.color_200)
	colors[flags.SeparatorHovered] = convertDecimalToRGBA(palette.accent2.color_100)
	colors[flags.SeparatorActive] = convertDecimalToRGBA(palette.accent2.color_50)
	colors[flags.ResizeGrip] = convertDecimalToRGBA(palette.accent2.color_900)
	colors[flags.ResizeGripHovered] = convertDecimalToRGBA(palette.accent2.color_800)
	colors[flags.ResizeGripActive] = convertDecimalToRGBA(palette.accent2.color_700)
	colors[flags.Tab] = convertDecimalToRGBA(palette.accent1.color_700)
	colors[flags.TabHovered] = convertDecimalToRGBA(palette.accent1.color_600)
	colors[flags.TabActive] = convertDecimalToRGBA(palette.accent1.color_500)
	colors[flags.PlotLines] = convertDecimalToRGBA(palette.accent3.color_300)
	colors[flags.PlotLinesHovered] = convertDecimalToRGBA(palette.accent3.color_50)
	colors[flags.PlotHistogram] = convertDecimalToRGBA(palette.accent3.color_300)
	colors[flags.PlotHistogramHovered] = convertDecimalToRGBA(palette.accent3.color_50)
	colors[flags.DragDropTarget] = convertDecimalToRGBA(palette.accent1.color_100)
	colors[flags.ModalWindowDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.95)
end

EXPORTS = {}

function EXPORTS.isReplaceOpen()
	return window[0]
end

function EXPORTS.openReplace()
	window[0] = true
end

function EXPORTS.closeReplace()
	window[0] = false
end

function EXPORTS.getReplaceVersion()
	return thisScript().version
end