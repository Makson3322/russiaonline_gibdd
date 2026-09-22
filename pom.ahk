#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SendMode Input

DllCall("SetProcessDPIAware")
GetDPI() {
    hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
    dpi := DllCall("GetDeviceCaps", "Ptr", hdc, "Int", 88)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
    return dpi
}

global SYSTEM_DPI := GetDPI()
global DPI_SCALE  := SYSTEM_DPI / 96.0

S(val) {
    global DPI_SCALE
    return Round(val * DPI_SCALE)
}

if not A_IsAdmin
{
    try {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%" /restart
    }
    ExitApp
}

global CurrentVersion := "4.2"
global RepoURL := "https://github.com/Makson3322/russiaonline_gibdd"
global UpdateAvailable := false
global LatestVersion := ""
global LastUpdateError := ""

global CurrentTheme := "Фиолетовый градиент"
global CLR_BG_TOP     := "0A1A4F"
global CLR_BG_BOT     := "8B3FD1"
global CLR_PANEL      := "0F1533"
global CLR_PANEL2     := "141B44"
global CLR_TEXT       := "F1F5F9"
global CLR_MUTED      := "A9B4D0"
global CLR_ACCENT     := "8B5CF6"
global CLR_ACCENT2    := "A78BFA"
global CLR_SUCCESS    := "34D399"
global CLR_WARN       := "FBBF24"
global CLR_DANGER     := "F87171"
global CLR_TITLE      := "FFFFFF"

global TimerRemaining := 0
global TimerActive := false
global TimerModeName := "Не задан"
global DisplayMap := []

global LastSelectedItem := ""
global LastSelectedPartIndex := ""
global hMyLV := ""

global IniFile := A_ScriptDir . "\config_gibdd.ini"
IniRead, CurrentHotkey, %IniFile%, Settings, OpenKey, F3
IniRead, SavedTheme, %IniFile%, Settings, Theme, Фиолетовый градиент

ApplyTheme(SavedTheme)
InitDatabase()

OnMessage(0x0201, "WM_LBUTTONDOWN")

BuildOverlay()
BuildSelectorGui()
BuildTimerGui()
ShowSettingsGui(CurrentHotkey)

if (CurrentHotkey != "NONE" && CurrentHotkey != "") {
    try Hotkey, %CurrentHotkey%, ToggleSelectionMenu, On
}

SetTimer, CheckUpdateFast, -1500
return

ApplyTheme(name) {
    global
    CurrentTheme := name
    if (name = "Темный графит") {
        CLR_BG_TOP := "111215", CLR_BG_BOT := "20232A"
        CLR_PANEL := "171920", CLR_PANEL2 := "1F222B"
        CLR_TEXT := "F1F5F9", CLR_MUTED := "94A3B8"
        CLR_ACCENT := "6366F1", CLR_ACCENT2 := "818CF8"
        CLR_SUCCESS := "34D399", CLR_WARN := "FBBF24"
        CLR_DANGER := "F87171", CLR_TITLE := "FFFFFF"
    } else if (name = "Синий ДПС") {
        CLR_BG_TOP := "0B2240", CLR_BG_BOT := "123B6B"
        CLR_PANEL := "081A31", CLR_PANEL2 := "0F2E54"
        CLR_TEXT := "F1F5F9", CLR_MUTED := "8DA9C4"
        CLR_ACCENT := "2563EB", CLR_ACCENT2 := "60A5FA"
        CLR_SUCCESS := "34D399", CLR_WARN := "FBBF24"
        CLR_DANGER := "F87171", CLR_TITLE := "FFFFFF"
    } else if (name = "Изумруд") {
        CLR_BG_TOP := "05241C", CLR_BG_BOT := "0D4733"
        CLR_PANEL := "041C16", CLR_PANEL2 := "093828"
        CLR_TEXT := "F1F5F9", CLR_MUTED := "A7F3D0"
        CLR_ACCENT := "059669", CLR_ACCENT2 := "34D399"
        CLR_SUCCESS := "34D399", CLR_WARN := "FBBF24"
        CLR_DANGER := "F87171", CLR_TITLE := "FFFFFF"
    } else if (name = "Кровавый рубин") {
        CLR_BG_TOP := "260606", CLR_BG_BOT := "521212"
        CLR_PANEL := "1C0505", CLR_PANEL2 := "360C0C"
        CLR_TEXT := "F1F5F9", CLR_MUTED := "FECACA"
        CLR_ACCENT := "DC2626", CLR_ACCENT2 := "F87171"
        CLR_SUCCESS := "34D399", CLR_WARN := "FBBF24"
        CLR_DANGER := "F87171", CLR_TITLE := "FFFFFF"
    } else if (name = "Янтарь") {
        CLR_BG_TOP := "1F1820", CLR_BG_BOT := "3A281A"
        CLR_PANEL := "171219", CLR_PANEL2 := "271D1A"
        CLR_TEXT := "F1F5F9", CLR_MUTED := "FDE68A"
        CLR_ACCENT := "D97706", CLR_ACCENT2 := "FBBF24"
        CLR_SUCCESS := "34D399", CLR_WARN := "FBBF24"
        CLR_DANGER := "F87171", CLR_TITLE := "FFFFFF"
    } else {
        CurrentTheme   := "Фиолетовый градиент"
        CLR_BG_TOP := "0A1A4F", CLR_BG_BOT := "8B3FD1"
        CLR_PANEL := "0F1533", CLR_PANEL2 := "141B44"
        CLR_TEXT := "F1F5F9", CLR_MUTED := "A9B4D0"
        CLR_ACCENT := "8B5CF6", CLR_ACCENT2 := "A78BFA"
        CLR_SUCCESS := "34D399", CLR_WARN := "FBBF24"
        CLR_DANGER := "F87171", CLR_TITLE := "FFFFFF"
    }
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    WinGetClass, cls, ahk_id %hwnd%
    if (cls = "Edit" || cls = "SysListView32" || cls = "Button" || cls = "ComboBox")
        return
    PostMessage, 0xA1, 2,,, A
}

ApplyRoundedCorners(hwnd, w := 0, h := 0, r := 18) {
    VarSetCapacity(rc, 16, 0)
    DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", &rc)
    rw := NumGet(rc, 8, "Int") - NumGet(rc, 0, "Int")
    rh := NumGet(rc, 12, "Int") - NumGet(rc, 4, "Int")
    if (rw > 0 && rh > 0)
        w := rw, h := rh
    sr := Round(r * (A_ScreenDPI / 96.0))
    hRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", w + 1, "Int", h + 1, "Int", sr, "Int", sr, "Ptr")
    DllCall("SetWindowRgn", "Ptr", hwnd, "Ptr", hRgn, "UInt", 1)
}

CopyToClip(strText, notifyMsg) {
    Clipboard := strText
    SoundPlay, *-1
    TrayTip, ДПС ГИБДД [V4.2], %notifyMsg%, 2, 1
}

CheckUpdateFast:
    CheckUpdate()
return

CheckUpdate() {
    global CurrentVersion, LatestVersion, UpdateAvailable, LastUpdateError
    UpdateAvailable := false
    LatestVersion := ""
    LastUpdateError := ""
    GuiControl, Settings:, CheckStatusLabel, Проверка обновлений на GitHub...
    remoteVersion := GetRemoteVersion()
    if (remoteVersion = "") {
        HideUpdateUI()
        if (LastUpdateError != "")
            GuiControl, Settings:, CheckStatusLabel, Ошибка сети: %LastUpdateError%
        else
            GuiControl, Settings:, CheckStatusLabel, Не удалось получить данные о версии
        return false
    }
    LatestVersion := remoteVersion
    if (IsNewer(remoteVersion, CurrentVersion)) {
        UpdateAvailable := true
        ApplyUpdateUI()
        GuiControl, Settings:, CheckStatusLabel, Доступна V%remoteVersion% (текущая V%CurrentVersion%)
        ShowUpdateModal()
        return true
    }
    HideUpdateUI()
    GuiControl, Settings:, CheckStatusLabel, V%CurrentVersion% - установлена актуальная версия
    return true
}

ManualCheckUpdate:
    GuiControl, Settings:, CheckStatusLabel, Подключение к GitHub...
    CheckUpdate()
return

GetRemoteVersion() {
    global LastUpdateError
    version := CurlGetRaw()
    if (version != "")
        return version
    version := CurlGetAPI()
    if (version != "")
        return version
    return ""
}

CurlGetRaw() {
    global LastUpdateError
    tmpOut := A_Temp . "\gibdd_raw_" . A_TickCount . ".txt"
    FileDelete, %tmpOut%
    url := "https://raw.githubusercontent.com/Makson3322/russiaonline_gibdd/main/version.txt"
    cmd := "curl.exe -s -L --max-time 15 -o """ . tmpOut . """ """ . url . """"
    RunWait, %ComSpec% /c %cmd%, , Hide UseErrorLevel
    if (!FileExist(tmpOut)) {
        LastUpdateError := "raw: нет ответа"
        return ""
    }
    FileRead, raw, %tmpOut%
    FileDelete, %tmpOut%
    raw := RegExReplace(raw, "^\xEF\xBB\xBF", "")
    raw := RegExReplace(raw, "[\r\n\t ]+", "")
    raw := Trim(raw)
    if (SubStr(raw, 1, 1) = "v" || SubStr(raw, 1, 1) = "V")
        raw := SubStr(raw, 2)
    if (raw = "" || !RegExMatch(raw, "^\d+(\.\d+)*$")) {
        LastUpdateError := "raw: некорректно"
        return ""
    }
    LastUpdateError := ""
    return raw
}

CurlGetAPI() {
    global LastUpdateError
    tmpOut := A_Temp . "\gibdd_api_" . A_TickCount . ".txt"
    FileDelete, %tmpOut%
    url := "https://api.github.com/repos/Makson3322/russiaonline_gibdd/contents/version.txt"
    cmd := "curl.exe -s -L --max-time 15 -H ""Accept: application/vnd.github.v3+json"" -o """ . tmpOut . """ """ . url . """"
    RunWait, %ComSpec% /c %cmd%, , Hide UseErrorLevel
    if (!FileExist(tmpOut)) {
        LastUpdateError := "api: нет ответа"
        return ""
    }
    FileRead, json, %tmpOut%
    FileDelete, %tmpOut%
    if (!RegExMatch(json, """content""\s*:\s*""([^""]+)""", m)) {
        LastUpdateError := "api: нет content"
        return ""
    }
    b64 := m1
    b64 := StrReplace(b64, "\n", "")
    b64 := StrReplace(b64, "`n", "")
    b64 := StrReplace(b64, "`r", "")
    b64 := StrReplace(b64, " ", "")
    xml := ComObjCreate("Microsoft.XMLDOM")
    node := xml.createElement("b")
    node.dataType := "bin.base64"
    node.text := b64
    bin := node.nodeTypedValue
    raw := ""
    Loop, % StrLen(bin)
        raw .= Chr(NumGet(bin, A_Index - 1, "UChar"))
    raw := RegExReplace(raw, "^\xEF\xBB\xBF", "")
    raw := RegExReplace(raw, "[\r\n\t ]+", "")
    raw := Trim(raw)
    if (SubStr(raw, 1, 1) = "v" || SubStr(raw, 1, 1) = "V")
        raw := SubStr(raw, 2)
    if (raw = "" || !RegExMatch(raw, "^\d+(\.\d+)*$")) {
        LastUpdateError := "api: некорректно"
        return ""
    }
    LastUpdateError := ""
    return raw
}

IsNewer(vRemote, vLocal) {
    aR := StrSplit(vRemote, ".")
    aL := StrSplit(vLocal, ".")
    m := aR.Length() > aL.Length() ? aR.Length() : aL.Length()
    Loop, %m%
    {
        r := (A_Index <= aR.Length()) ? aR[A_Index] + 0 : 0
        l := (A_Index <= aL.Length()) ? aL[A_Index] + 0 : 0
        if (r > l)
            return true
        if (r < l)
            return false
    }
    return false
}

HideUpdateUI() {
    GuiControl, Overlay:Hide, UpdateNoticeBtn
    GuiControl, Selector:Hide, UpdateSelectorBtn
    GuiControl, Settings:Hide, UpdateSettingsBtn
}

ApplyUpdateUI() {
    global LatestVersion
    GuiControl, Overlay:Show, UpdateNoticeBtn
    GuiControl, Overlay:, UpdateNoticeBtn, ОБНОВИТЬ ДО V%LatestVersion%
    GuiControl, Selector:Show, UpdateSelectorBtn
    GuiControl, Selector:, UpdateSelectorBtn, ДОСТУПНО ОБНОВЛЕНИЕ: V%LatestVersion%
    GuiControl, Settings:Show, UpdateSettingsBtn
    GuiControl, Settings:, UpdateSettingsBtn, ВЫШЛО ОБНОВЛЕНИЕ V%LatestVersion% - СКАЧАТЬ
}

ShowUpdateModal() {
    global
    UpdateModalVisible := true
    Gui, UpdateModal:Destroy
    Gui, UpdateModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhUpdateGui
    Gui, UpdateModal:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    wW := 520, hW := 262
    fs := 15
	Gui, UpdateModal:Font, s%fs% c%CLR_TITLE% Bold, Segoe UI
    Gui, UpdateModal:Add, Text, x0 y24 w%wW% Center, ДОСТУПНА НОВАЯ ВЕРСИЯ
    Gui, UpdateModal:Font, s9 c%CLR_MUTED% Normal, Segoe UI
    Gui, UpdateModal:Add, Text, x0 y58 w%wW% Center, Обновление скрипта памятки ДПС ГИБДД
    Gui, UpdateModal:Font, s10 c%CLR_TEXT% Normal, Segoe UI
    uMsg := "В официальном репозитории вышла версия: V" . LatestVersion . "`r`n"
          . "У вас установлена версия: V" . CurrentVersion . "`r`n`r`n"
          . "Рекомендуется обновиться для получения актуального`r`n"
          . "законодательства и улучшений."
    Gui, UpdateModal:Add, Text, x30 y98 w460 h80 Center, %uMsg%
    Gui, UpdateModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, UpdateModal:Add, Button, x40 y196 w240 h42 gOpenRepoUrl, Открыть GitHub
    Gui, UpdateModal:Add, Button, x290 y196 w190 h42 gCloseUpdateModal, Позже
    Gui, UpdateModal:Show, w%wW% h%hW% Center, GIBDD_Update
    WinActivate, ahk_id %hUpdateGui%
    DllCall("SetForegroundWindow", "Ptr", hUpdateGui)
    DllCall("SetWindowPos", "Ptr", hUpdateGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hUpdateGui, wW, hW, 18)
}

OpenRepoUrl:
    Run %RepoURL%
    Gui, UpdateModal:Hide
    UpdateModalVisible := false
return

CloseUpdateModal:
    Gui, UpdateModal:Hide
    UpdateModalVisible := false
return

ShowSettingsGui(savedKey) {
    global
    Gui, Settings:Destroy
    Gui, Settings:+AlwaysOnTop -MaximizeBox -MinimizeBox -Caption +Border
    Gui, Settings:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    wW := 460, hW := 334
    Gui, Settings:Font, s16 c%CLR_TITLE% Bold, Segoe UI
    Gui, Settings:Add, Text, x0 y18 w%wW% Center, ПАМЯТКА • ДИМА ЗЛАЯ КАКА
    Gui, Settings:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, Settings:Add, Text, x0 y48 w%wW% Center, КУТУЗОВСКИЙ  •  РОССИЯ ОНЛАЙН  •  V4.2
    Gui, Settings:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, Settings:Add, Button, x30 y74 w400 h36 vUpdateSettingsBtn gOpenRepoUrl +Hidden, ВЫШЛО ОБНОВЛЕНИЕ - СКАЧАТЬ
    Gui, Settings:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    if (savedKey == "NONE" || savedKey == "") {
        Gui, Settings:Add, Text, x0 y118 w%wW% Center, Назначьте клавишу для открытия меню инспектора:
        btnText := "Сохранить и запустить"
    } else {
        Gui, Settings:Add, Text, x0 y116 w%wW% Center, Текущая клавиша: [%savedKey%] | Выберите новую или подтвердите:
        btnText := "Запустить помощник"
    }
    Gui, Settings:Font, s11 cFFFFFF Bold, Segoe UI
    Gui, Settings:Add, Hotkey, x90 y140 w280 h32 vNewHotkey, % (savedKey == "NONE" ? "F3" : savedKey)
    Gui, Settings:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    Gui, Settings:Add, Text, x0 y182 w%wW% Center, Выберите тему оформления скрипта:
    themeChoices := ""
    allThemes := ["Фиолетовый градиент", "Синий ДПС", "Темный графит", "Изумруд", "Кровавый рубин", "Янтарь"]
    for idx, tName in allThemes
    {
        if (tName = CurrentTheme)
            themeChoices .= tName . "||"
        else
            themeChoices .= tName . "|"
    }
    Gui, Settings:Font, s10 c000000 Normal, Segoe UI
    Gui, Settings:Add, DropDownList, x90 y204 w280 vSelectedTheme gOnThemeDropdownChange, %themeChoices%
    Gui, Settings:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, Settings:Add, Button, x90 y252 w200 h40 gSaveAndStart, %btnText%
    Gui, Settings:Add, Button, x297 y252 w73 h40 gManualCheckUpdate, ОБН.
    Gui, Settings:Font, s8 c%CLR_MUTED% Normal, Segoe UI
    Gui, Settings:Add, Text, x0 y304 w%wW% Center vCheckStatusLabel, Проверка обновлений...
    if (UpdateAvailable) {
        GuiControl, Settings:Show, UpdateSettingsBtn
        GuiControl, Settings:, UpdateSettingsBtn, ВЫШЛО ОБНОВЛЕНИЕ V%LatestVersion% - СКАЧАТЬ
    }
    Gui, Settings:Show, w%wW% h%hW%, Настройка биндера ГИБДД
    WinGet, hSet, ID, Настройка биндера ГИБДД
    ApplyRoundedCorners(hSet, wW, hW, 18)
}

OnThemeDropdownChange:
    Gui, Settings:Submit, NoHide
    ApplyTheme(SelectedTheme)
    IniWrite, %SelectedTheme%, %IniFile%, Settings, Theme
    BuildOverlay()
    BuildSelectorGui()
    BuildTimerGui()
    ShowSettingsGui(NewHotkey)
return

SaveAndStart:
    Gui, Settings:Submit
    if (NewHotkey == "") {
        MsgBox, 48, Ошибка, Вы не выбрали клавишу!
        ShowSettingsGui(CurrentHotkey)
        return
    }
    if (CurrentHotkey != "NONE" && CurrentHotkey != "") {
        try Hotkey, %CurrentHotkey%, Toggle, Off
    }
    CurrentHotkey := NewHotkey
    CurrentTheme := SelectedTheme
    ApplyTheme(CurrentTheme)
    IniWrite, %CurrentHotkey%, %IniFile%, Settings, OpenKey
    IniWrite, %CurrentTheme%, %IniFile%, Settings, Theme
    Hotkey, %CurrentHotkey%, ToggleSelectionMenu, On
    TrayTip, ДПС ГИБДД V4.2, Настройки сохранены!`nКлавиша: [%CurrentHotkey%] | Тема: %CurrentTheme%, 3, 1
    BuildOverlay()
    BuildSelectorGui()
    BuildTimerGui()
    if (UpdateAvailable) {
        ApplyUpdateUI()
    }
return

SettingsGuiClose:
    ExitApp

BuildSelectorGui() {
    global
    Gui, Selector:Destroy
    Gui, Selector:+AlwaysOnTop +ToolWindow -Caption +LastFound +Border +HwndhSelectorGui
    Gui, Selector:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    WinSet, Transparent, 250
    wW := 430, hW := 478
    Gui, Selector:Font, s16 c%CLR_TITLE% Bold, Segoe UI
    Gui, Selector:Add, Text, x0 y18 w%wW% Center, СИСТЕМА ДПС ГИБДД
    Gui, Selector:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, Selector:Add, Text, x0 y48 w%wW% Center, БАЗА ДАННЫХ ЗАКОНОДАТЕЛЬСТВА  •  V4.2
    Gui, Selector:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, Selector:Add, Button, x25 y76 w380 h34 vUpdateSelectorBtn gOpenRepoUrl +Hidden, ДОСТУПНО ОБНОВЛЕНИЕ
    Gui, Selector:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, Selector:Add, Button, x25 y116 w380 h38 gChoosePopular, ПОПУЛЯРНЫЕ СТАТЬИ (БАЗА ДПС)
    Gui, Selector:Add, Button, x25 y158 w380 h38 gChooseAll, ВСЕ СТАТЬИ И ЗАКОНЫ (ПОЛНАЯ БАЗА)
    Gui, Selector:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Selector:Add, Button, x25 y202 w185 h36 gChooseKoAP, КоАП РО
    Gui, Selector:Add, Button, x220 y202 w185 h36 gChooseUK, УК РО
    Gui, Selector:Add, Button, x25 y242 w185 h36 gChooseProc, Процессуальный кодекс
    Gui, Selector:Add, Button, x220 y242 w185 h36 gChoosePDD, ПДД РО
    Gui, Selector:Add, Button, x25 y282 w185 h36 gChoosePolice, ФЗ О Полиции
    Gui, Selector:Add, Button, x220 y282 w185 h36 gChooseUstav, Устав ГИБДД
    Gui, Selector:Add, Button, x25 y324 w90 h36 gShowMiranda, Права
    Gui, Selector:Add, Button, x122 y324 w90 h36 gShowMegaphone, Рупор
    Gui, Selector:Add, Button, x219 y324 w90 h36 gShowBailCalc, Залог
    Gui, Selector:Add, Button, x315 y324 w90 h36 gShowRPBinder, РП
    Gui, Selector:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Selector:Add, Button, x25 y366 w185 h36 gToggleTimerFromSelector, Таймер задержания
    Gui, Selector:Add, Button, x220 y366 w185 h36 gShowForceStages, Стадии силы
    Gui, Selector:Add, Button, x25 y408 w380 h34 gShowRulesFromSelector, Регламент ст. 10 КоАП / Подследственность
    Gui, Selector:Font, s8 c%CLR_MUTED% Normal, Segoe UI
    Gui, Selector:Add, Text, x0 y450 w%wW% Center, Закрыть: [%CurrentHotkey%] / [ESC]  •  Перемещение за фон
    if (UpdateAvailable) {
        GuiControl, Selector:Show, UpdateSelectorBtn
        GuiControl, Selector:, UpdateSelectorBtn, ДОСТУПНО ОБНОВЛЕНИЕ: V%LatestVersion%
    }
}

ToggleSelectionMenu:
    if (OverlayVisible || SelectorVisible || RulesVisible || MirandaVisible || MegaphoneVisible || BailVisible || RPBinderVisible || ForceVisible || UpdateModalVisible) {
        CloseAllWindows()
        return
    }
    PrevGameHwnd := WinActive("A")
    SelectorVisible := true
    Gui, Selector:Show, w430 h478 Center, GIBDD_Selector
    WinActivate, ahk_id %hSelectorGui%
    DllCall("SetForegroundWindow", "Ptr", hSelectorGui)
    DllCall("SetWindowPos", "Ptr", hSelectorGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hSelectorGui, 430, 478, 20)
return

ChoosePopular:
    Gui, Selector:Hide
    SelectorVisible := false
    OpenOverlayWithCategory(1)
return
ChooseAll:
    Gui, Selector:Hide
    SelectorVisible := false
    OpenOverlayWithCategory(2)
return
ChooseKoAP:
    Gui, Selector:Hide
    SelectorVisible := false
    OpenOverlayWithCategory(3)
return
ChooseUK:
    Gui, Selector:Hide
    SelectorVisible := false
    OpenOverlayWithCategory(4)
return
ChooseProc:
    Gui, Selector:Hide
    SelectorVisible := false
    OpenOverlayWithCategory(5)
return
ChoosePDD:
    Gui, Selector:Hide
    SelectorVisible := false
    OpenOverlayWithCategory(6)
return
ChoosePolice:
    Gui, Selector:Hide
    SelectorVisible := false
    OpenOverlayWithCategory(7)
return
ChooseUstav:
    Gui, Selector:Hide
    SelectorVisible := false
    OpenOverlayWithCategory(8)
return
ShowRulesFromSelector:
    Gui, Selector:Hide
    SelectorVisible := false
    Gosub, ShowRules
return

ToggleTimerFromSelector:
    Gui, Selector:Hide
    SelectorVisible := false
    Gosub, ToggleTimerGui
return

OpenOverlayWithCategory(catNumber) {
    global
    OverlayVisible := true
    Gui, Overlay:Default
    ActiveCategoryIndex := catNumber
    GuiControl, Overlay:, SearchTerm,
    Gosub, FilterArticles
    Gui, Overlay:Show, w1120 h680 Center, GIBDD_Overlay
    WinActivate, ahk_id %hOverlayGui%
    DllCall("SetForegroundWindow", "Ptr", hOverlayGui)
    DllCall("SetWindowPos", "Ptr", hOverlayGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hOverlayGui, 1120, 680, 20)
    GuiControl, Overlay:Focus, SearchTerm
    DllCall("SetFocus", "Ptr", hSearchBox)
}

CloseAllWindows() {
    global
    OverlayVisible := false
    SelectorVisible := false
    RulesVisible := false
    MirandaVisible := false
    MegaphoneVisible := false
    BailVisible := false
    RPBinderVisible := false
    ForceVisible := false
    UpdateModalVisible := false
    Gui, Overlay:Hide
    Gui, Selector:Hide
    Gui, RulesModal:Hide
    Gui, MirandaModal:Hide
    Gui, MegaphoneModal:Hide
    Gui, BailModal:Hide
    Gui, RPBinderModal:Hide
    Gui, ForceModal:Hide
    Gui, UpdateModal:Hide
    if (PrevGameHwnd) {
        WinActivate, ahk_id %PrevGameHwnd%
    }
}

#IfWinExist, GIBDD_Selector
Escape::
    CloseAllWindows()
return
#IfWinExist

#IfWinExist, GIBDD_Overlay
Escape::
    CloseAllWindows()
return
Enter::
    Gosub, HandleEnterKey
return
NumpadEnter::
    Gosub, HandleEnterKey
return
$Space::
    GuiControlGet, focusedCtrl, Overlay:FocusV
    if (focusedCtrl = "SearchTerm")
        Send, {Space}
    else
        Gosub, ToggleExpandSelected
return
$Right::
    GuiControlGet, focusedCtrl, Overlay:FocusV
    if (focusedCtrl = "SearchTerm")
        Send, {Right}
    else
        Gosub, ExpandSelected
return
$Left::
    GuiControlGet, focusedCtrl, Overlay:FocusV
    if (focusedCtrl = "SearchTerm")
        Send, {Left}
    else
        Gosub, CollapseSelected
return
Down::
    GuiControlGet, focusedCtrl, Overlay:FocusV
    if (focusedCtrl = "SearchTerm") {
        GuiControl, Overlay:Focus, MyLV
        LV_Modify(1, "Select Focus")
    } else {
        Send, {Down}
    }
return
#IfWinExist

#IfWinExist, GIBDD_Rules
Escape::
    CloseAllWindows()
return
#IfWinExist
#IfWinExist, GIBDD_Miranda
Escape::
    CloseAllWindows()
return
#IfWinExist
#IfWinExist, GIBDD_Megaphone
Escape::
    CloseAllWindows()
return
#IfWinExist
#IfWinExist, GIBDD_Bail
Escape::
    CloseAllWindows()
return
#IfWinExist
#IfWinExist, GIBDD_RP
Escape::
    CloseAllWindows()
return
#IfWinExist
#IfWinExist, GIBDD_Force
Escape::
    CloseAllWindows()
return
#IfWinExist
#IfWinExist, GIBDD_Update
Escape::
    CloseAllWindows()
return
#IfWinExist

BuildOverlay() {
    global
    Gui, Overlay:Destroy
    Gui, Overlay:+AlwaysOnTop +ToolWindow -Caption +LastFound +Border +HwndhOverlayGui
    Gui, Overlay:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    Gui, Overlay:Default
    ActiveCategoryIndex := 1
    WinSet, Transparent, 250
    Gui, Overlay:Font, s15 c%CLR_TITLE% Bold, Segoe UI
    Gui, Overlay:Add, Text, x25 y18 w360, ДПС ГИБДД КУТУЗОВСКИЙ
    Gui, Overlay:Font, s8 c%CLR_SUCCESS% Bold, Segoe UI
    Gui, Overlay:Add, Text, x390 y24 w70, [ V4.2 ]
    Gui, Overlay:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Overlay:Add, Button, x470 y16 w220 h30 vUpdateNoticeBtn gOpenRepoUrl +Hidden, ОБНОВИТЬ СКРИПТ
    Gui, Overlay:Font, s9 c%CLR_MUTED% Normal, Segoe UI
    Gui, Overlay:Add, Text, x700 y22 w400 Right, Закрыть: [%CurrentHotkey%] / [ESC]  •  Пробел/2xЛКМ: Развернуть
    Gui, Overlay:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Overlay:Add, Button, x25 y56 w70 h30 gTabPop, Топ
    Gui, Overlay:Add, Button, x100 y56 w65 h30 gTabAll, Все
    Gui, Overlay:Add, Button, x170 y56 w75 h30 gTabKoap, КоАП
    Gui, Overlay:Add, Button, x250 y56 w75 h30 gTabUK, УК РО
    Gui, Overlay:Add, Button, x330 y56 w75 h30 gTabPK, ПК РО
    Gui, Overlay:Add, Button, x410 y56 w75 h30 gTabPDD, ПДД
    Gui, Overlay:Add, Button, x490 y56 w105 h30 gTabPol, ФЗ Полиция
    Gui, Overlay:Add, Button, x600 y56 w75 h30 gTabUstav, Устав
    Gui, Overlay:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, Overlay:Add, Button, x680 y56 w70 h30 gShowMiranda, Права
    Gui, Overlay:Add, Button, x755 y56 w70 h30 gShowMegaphone, Рупор
    Gui, Overlay:Add, Button, x830 y56 w70 h30 gShowBailCalc, Залог
    Gui, Overlay:Add, Button, x905 y56 w60 h30 gShowRPBinder, РП
    Gui, Overlay:Add, Button, x970 y56 w85 h30 gToggleTimerGui, Таймер
    Gui, Overlay:Add, Button, x1060 y56 w35 h30 gOpenSettingsFromMenu, О
    Gui, Overlay:Font, s9 c%CLR_TEXT% Bold, Segoe UI
    Gui, Overlay:Add, Text, x25 y100 w60 h28 +0x200, Поиск:
    Gui, Overlay:Font, s10 cFFFFFF Normal, Segoe UI
    Gui, Overlay:Add, Edit, x90 y98 w320 h30 vSearchTerm gFilterArticles -E0x200 +Border +HwndhSearchBox,
    Gui, Overlay:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Overlay:Add, Button, x418 y98 w34 h30 gClearSearch, X
    Gui, Overlay:Add, Button, x458 y98 w135 h30 gCopySelected, Скопировать
    Gui, Overlay:Add, Button, x599 y98 w180 h30 gToggleExpandSelected, ▶/▼ Раскрыть части
    Gui, Overlay:Add, Button, x785 y98 w115 h30 gShowForceStages, Стадии силы
    Gui, Overlay:Add, Button, x906 y98 w105 h30 gShowRules, Регламент
    Gui, Overlay:Font, s8 c%CLR_SUCCESS% Bold, Segoe UI
    Gui, Overlay:Add, Text, x1015 y104 w90 h20 Right vCountLabel, База...
    Gui, Overlay:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    Gui, Overlay:Add, ListView, x25 y140 w1070 h370 vMyLV gLVClick +AltSubmit -Multi +Grid Background%CLR_PANEL2% cFFFFFF +HwndhMyLV, Раздел|Статья / Часть / Пункт|Наказание / Санкция / Содержание
        c1 := S(130), c2 := S(580), c3 := S(340)
    LV_ModifyCol(1, c1 . " Left")
    LV_ModifyCol(2, c2 . " Left")
    LV_ModifyCol(3, c3 . " Left")
    Gui, Overlay:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, Overlay:Add, GroupBox, x25 y520 w1070 h150, КАРТОЧКА СТАТЬИ И САНКЦИИ
    Gui, Overlay:Font, s10 c%CLR_TEXT% Normal, Segoe UI
    Gui, Overlay:Add, Edit, x38 y545 w1044 h110 vDetailBox ReadOnly -E0x200 +Multi Background%CLR_BG_TOP% +Border, Выберите статью в списке выше. Статьи со стрелкой [▶] можно раскрыть по частям (Пробел, 2xЛКМ или кнопка «Раскрыть части»)...
    Gosub, FilterArticles
}

TabPop:
    ActiveCategoryIndex := 1
    Gosub, FilterArticles
return
TabAll:
    ActiveCategoryIndex := 2
    Gosub, FilterArticles
return
TabKoap:
    ActiveCategoryIndex := 3
    Gosub, FilterArticles
return
TabUK:
    ActiveCategoryIndex := 4
    Gosub, FilterArticles
return
TabPK:
    ActiveCategoryIndex := 5
    Gosub, FilterArticles
return
TabPDD:
    ActiveCategoryIndex := 6
    Gosub, FilterArticles
return
TabPol:
    ActiveCategoryIndex := 7
    Gosub, FilterArticles
return
TabUstav:
    ActiveCategoryIndex := 8
    Gosub, FilterArticles
return

ClearSearch:
    GuiControl, Overlay:, SearchTerm,
    Gosub, FilterArticles
    GuiControl, Overlay:Focus, SearchTerm
return

FilterArticles:
    Gui, Overlay:Default
    Gui, Overlay:Submit, NoHide
    GuiControl, Overlay:-Redraw, MyLV
    LV_Delete()
    query := Trim(SearchTerm)
    catIndex := ActiveCategoryIndex
    matchCount := 0
    totalCount := ArticleDB.Length()
    DisplayMap := []
    for idx, item in ArticleDB
    {
        passCategory := false
        if (catIndex == 1) {
            if (item.IsPop)
                passCategory := true
        } else if (catIndex == 2) {
            passCategory := true
        } else if (catIndex == 3) {
            if (InStr(item.Category, "КоАП"))
                passCategory := true
        } else if (catIndex == 4) {
            if (InStr(item.Category, "УК"))
                passCategory := true
        } else if (catIndex == 5) {
            if (InStr(item.Category, "ПК"))
                passCategory := true
        } else if (catIndex == 6) {
            if (InStr(item.Category, "ПДД"))
                passCategory := true
        } else if (catIndex == 7) {
            if (InStr(item.Category, "ФЗ"))
                passCategory := true
        } else if (catIndex == 8) {
            if (InStr(item.Category, "Устав"))
                passCategory := true
        }
        if (passCategory) {
            hasParts := (item.Parts.Length() > 0)
            matchesQuery := false
            if (query == "") {
                matchesQuery := true
            } else {
                if (InStr(item.Category, query) || InStr(item.Title, query) || InStr(item.Punish, query))
                    matchesQuery := true
                if (!matchesQuery && hasParts) {
                    for pIdx, pItem in item.Parts {
                        if (InStr(pItem.Title, query) || InStr(pItem.Punish, query)) {
                            matchesQuery := true
                            break
                        }
                    }
                }
            }
            if (matchesQuery) {
                matchCount++
                prefix := hasParts ? (item.Expanded ? "▼ " : "▶ ") : "  "
                LV_Add("", item.Category, prefix . item.Title, item.Punish)
                DisplayMap.Push({"Item": item, "PartIndex": 0})
                if (hasParts && (item.Expanded || (query != "" && matchesQuery))) {
                    for pIdx, pItem in item.Parts {
                        LV_Add("", "", "    ↳ " . pItem.Title, pItem.Punish)
                        DisplayMap.Push({"Item": item, "PartIndex": pIdx})
                    }
                }
            }
        }
    }
    GuiControl, Overlay:+Redraw, MyLV
    GuiControl, Overlay:, CountLabel, Найдено: %matchCount%
    if (LastSelectedItem && LastSelectedPartIndex != "") {
        newRow := FindRowByItem(LastSelectedItem, LastSelectedPartIndex)
        if (newRow > 0) {
            LV_Modify(newRow, "Select Focus")
            SendMessage, 0x1013, newRow - 1, 0, , ahk_id %hMyLV%
        }
        LastSelectedItem := ""
        LastSelectedPartIndex := ""
    }
return

LVClick:
    Gui, Overlay:Default
    Row := LV_GetNext(0, "Focused")
    if (Row <= 0)
        return
    info := DisplayMap[Row]
    if (!info)
        return
    item := info.Item
    pIdx := info.PartIndex
    if (A_GuiEvent == "Normal" || A_GuiEvent == "K") {
        if (pIdx == 0) {
            infoText := "РАЗДЕЛ:`t" . item.Category . "`r`nСТАТЬЯ:`t" . item.Title . "`r`nСУТЬ / НАКАЗАНИЕ:`t" . item.Punish
            if (item.Parts.Length() > 0) {
                infoText .= "`r`n`r`n[СОДЕРЖИТ ЧАСТИ / ПУНКТЫ — Нажмите Пробел, 2xЛКМ или «Раскрыть части»]:`r`n"
                for i, p in item.Parts
                    infoText .= "  • " . p.Title . " — " . p.Punish . "`r`n"
            }
            GuiControl, Overlay:, DetailBox, %infoText%
        } else {
            part := item.Parts[pIdx]
            infoText := "РАЗДЕЛ:`t" . item.Category . "`r`nСТАТЬЯ:`t" . item.Title . "`r`nЧАСТЬ / ПУНКТ:`t" . part.Title . "`r`nНАКАЗАНИЕ / СОДЕРЖАНИЕ:`t" . part.Punish
            GuiControl, Overlay:, DetailBox, %infoText%
        }
    }
    if (A_GuiEvent == "DoubleClick") {
        if (pIdx == 0 && item.Parts.Length() > 0) {
            LastSelectedItem := item
            LastSelectedPartIndex := 0
            item.Expanded := !item.Expanded
            Gosub, FilterArticles
        } else {
            Gosub, CopySelected
        }
    }
return

HandleEnterKey:
    Gui, Overlay:Default
    Row := LV_GetNext(0, "Focused")
    if (Row <= 0)
        return
    info := DisplayMap[Row]
    if (!info)
        return
    item := info.Item
    pIdx := info.PartIndex
    if (pIdx == 0 && item.Parts.Length() > 0) {
        LastSelectedItem := item
        LastSelectedPartIndex := 0
        item.Expanded := !item.Expanded
        Gosub, FilterArticles
    } else {
        Gosub, CopySelected
    }
return

ToggleExpandSelected:
    Gui, Overlay:Default
    Row := LV_GetNext(0, "Focused")
    if (Row <= 0)
        return
    info := DisplayMap[Row]
    if (!info)
        return
    item := info.Item
    if (item.Parts.Length() > 0) {
        LastSelectedItem := item
        LastSelectedPartIndex := 0
        item.Expanded := !item.Expanded
        Gosub, FilterArticles
    }
return

ExpandSelected:
    Gui, Overlay:Default
    Row := LV_GetNext(0, "Focused")
    if (Row <= 0)
        return
    info := DisplayMap[Row]
    if (!info)
        return
    item := info.Item
    if (item.Parts.Length() > 0 && !item.Expanded) {
        LastSelectedItem := item
        LastSelectedPartIndex := 0
        item.Expanded := true
        Gosub, FilterArticles
    }
return

CollapseSelected:
    Gui, Overlay:Default
    Row := LV_GetNext(0, "Focused")
    if (Row <= 0)
        return
    info := DisplayMap[Row]
    if (!info)
        return
    item := info.Item
    if (item.Parts.Length() > 0 && item.Expanded) {
        LastSelectedItem := item
        LastSelectedPartIndex := 0
        item.Expanded := false
        Gosub, FilterArticles
    }
return

FindRowByItem(targetItem, targetPIdx) {
    global DisplayMap
    for r, info in DisplayMap {
        if (info.Item == targetItem && info.PartIndex == targetPIdx)
            return r
    }
    return 0
}

CopySelected:
    Gui, Overlay:Default
    Row := LV_GetNext(0, "Focused")
    if (Row <= 0)
        return
    info := DisplayMap[Row]
    if (!info)
        return
    item := info.Item
    pIdx := info.PartIndex
    if (pIdx == 0) {
        if (item.Parts.Length() > 0) {
            CopyToClip("[" . item.Category . "] " . item.Title . " - " . item.Punish, "Статья скопирована!")
        } else {
            CopyToClip("[" . item.Category . "] " . item.Title . " - Наказание: " . item.Punish, "Статья скопирована!")
        }
    } else {
        part := item.Parts[pIdx]
        CopyToClip("[" . item.Category . "] " . item.Title . " (" . part.Title . ") - " . part.Punish, "Пункт статьи скопирован!")
    }
return

ShowMiranda:
    MirandaVisible := true
    Gui, MirandaModal:Destroy
    Gui, MirandaModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhMirandaGui
    Gui, MirandaModal:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    Gui, MirandaModal:Font, s15 c%CLR_TITLE% Bold, Segoe UI
    Gui, MirandaModal:Add, Text, x0 y20 w580 Center, ПРАВИЛО МИРАНДЫ
    Gui, MirandaModal:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, MirandaModal:Add, Text, x0 y52 w580 Center, Статья 6 Главы II Процессуального кодекса РО
    Gui, MirandaModal:Font, s11 c%CLR_TEXT% Normal, Segoe UI
    mText := "«Вы имеете право хранить молчание.`r`n"
          . "Всё, что вы скажете, может и будет использовано против Вас в суде.`r`n"
          . "Вы имеете право на один телефонный звонок.`r`n"
          . "Также Вы имеете право на адвоката.`r`n"
          . "Если вам необходим адвокат, он будет для Вас запрошен.`r`n`r`n"
          . "Вы понимаете свои права?»"
    Gui, MirandaModal:Add, Text, x30 y88 w520 h140 Center, %mText%
    Gui, MirandaModal:Font, s9 c%CLR_MUTED% Normal, Segoe UI
    Gui, MirandaModal:Add, Text, x0 y240 w580 Center, Звонок: до 3 минут в присутствии  •  Адвокат: встреча 10 минут наедине
    Gui, MirandaModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, MirandaModal:Add, Button, x90 y278 w190 h42 gCopyMiranda, Скопировать текст
    Gui, MirandaModal:Add, Button, x300 y278 w190 h42 gCloseMiranda, Закрыть
    Gui, MirandaModal:Show, w580 h340 Center, GIBDD_Miranda
    WinActivate, ahk_id %hMirandaGui%
    DllCall("SetForegroundWindow", "Ptr", hMirandaGui)
    DllCall("SetWindowPos", "Ptr", hMirandaGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hMirandaGui, 580, 340, 20)
return

CopyMiranda:
    CopyToClip("Вы имеете право хранить молчание. Всё, что вы скажете, может и будет использовано против Вас в суде. Вы имеете право на один телефонный звонок. Также Вы имеете право на адвоката. Если вам необходим адвокат, он будет для Вас запрошен. Вы понимаете свои права?", "Правило Миранды скопировано!")
return

CloseMiranda:
    Gui, MirandaModal:Hide
    MirandaVisible := false
return

ShowMegaphone:
    MegaphoneVisible := true
    Gui, MegaphoneModal:Destroy
    Gui, MegaphoneModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhMegaphoneGui
    Gui, MegaphoneModal:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    Gui, MegaphoneModal:Font, s15 c%CLR_TITLE% Bold, Segoe UI
    Gui, MegaphoneModal:Add, Text, x0 y18 w660 Center, ТРЕБОВАНИЯ В МЕГАФОН
    Gui, MegaphoneModal:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, MegaphoneModal:Add, Text, x0 y48 w660 Center, Статья 6 Главы XI Процессуального кодекса РО
    Gui, MegaphoneModal:Add, GroupBox, x20 y75 w620 h74, 1-е ТРЕБОВАНИЕ ОБ ОСТАНОВКЕ
    Gui, MegaphoneModal:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    Gui, MegaphoneModal:Add, Text, x32 y95 w460 h46, Водитель ТС, прижмитесь к обочине и остановитесь! В противном случае будут применены меры принудительной остановки!
    Gui, MegaphoneModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x500 y93 w128 h38 gCopyMega1, Скопировать [1]
    Gui, MegaphoneModal:Add, GroupBox, x20 y155 w620 h74, 2-е ТРЕБОВАНИЕ ОБ ОСТАНОВКЕ
    Gui, MegaphoneModal:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    Gui, MegaphoneModal:Add, Text, x32 y175 w460 h46, Повторяю требование об остановке! Немедленно прижмитесь к обочине, заглушите двигатель и оставайтесь в авто!
    Gui, MegaphoneModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x500 y173 w128 h38 gCopyMega2, Скопировать [2]
    Gui, MegaphoneModal:Add, GroupBox, x20 y235 w620 h74, 3-е ТРЕБОВАНИЕ (ФИНАЛЬНОЕ / ОГОНЬ)
    Gui, MegaphoneModal:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    Gui, MegaphoneModal:Add, Text, x32 y255 w460 h46, Это последнее предупреждение! В случае неподчинения будет открыт огонь по колесам и применен силовой таран!
    Gui, MegaphoneModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x500 y253 w128 h38 gCopyMega3, Скопировать [3]
    Gui, MegaphoneModal:Add, GroupBox, x20 y315 w620 h74, ТРЕБОВАНИЕ ЗАГЛУШИТЬ ДВИГАТЕЛЬ
    Gui, MegaphoneModal:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    Gui, MegaphoneModal:Add, Text, x32 y335 w460 h46, Заглушите двигатель, положите руки на руль и приготовьте документы для проверки инспектором!
    Gui, MegaphoneModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x500 y333 w128 h38 gCopyMega4, Скопировать [4]
    Gui, MegaphoneModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x240 y400 w180 h38 gCloseMegaphone, Закрыть
    Gui, MegaphoneModal:Show, w660 h450 Center, GIBDD_Megaphone
    WinActivate, ahk_id %hMegaphoneGui%
    DllCall("SetForegroundWindow", "Ptr", hMegaphoneGui)
    DllCall("SetWindowPos", "Ptr", hMegaphoneGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hMegaphoneGui, 660, 450, 20)
return

CopyMega1:
    CopyToClip("/m [ГИБДД]: Водитель ТС, прижмитесь к обочине и остановитесь! В противном случае к вам будут применены меры принудительной остановки!", "1-е требование скопировано!")
return
CopyMega2:
    CopyToClip("/m [ГИБДД]: Повторяю требование об остановке! Немедленно прижмитесь к обочине, заглушите двигатель и оставайтесь в авто!", "2-е требование скопировано!")
return
CopyMega3:
    CopyToClip("/m [ГИБДД]: Это последнее предупреждение! В случае неподчинения будет открыт огонь по колесам и применен таран!", "3-е требование скопировано!")
return
CopyMega4:
    CopyToClip("/m [ГИБДД]: Заглушите двигатель, положите руки на руль и приготовьте документы для проверки!", "Требование заглушить авто скопировано!")
return

CloseMegaphone:
    Gui, MegaphoneModal:Hide
    MegaphoneVisible := false
return

ShowBailCalc:
    BailVisible := true
    Gui, BailModal:Destroy
    Gui, BailModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhBailGui
    Gui, BailModal:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    Gui, BailModal:Font, s15 c%CLR_TITLE% Bold, Segoe UI
    Gui, BailModal:Add, Text, x0 y18 w460 Center, КАЛЬКУЛЯТОР ЗАЛОГА
    Gui, BailModal:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, BailModal:Add, Text, x0 y48 w460 Center, Статья 5.10 УК РО  •  1 год = 25 000 рублей
    Gui, BailModal:Font, s10 c%CLR_TEXT% Bold, Segoe UI
    Gui, BailModal:Add, Text, x35 y86 w180 h28 +0x200, Срок ареста (лет):
    Gui, BailModal:Font, s11 cFFFFFF Bold, Segoe UI
    Gui, BailModal:Add, Edit, x220 y84 w200 h30 vBailYears gCalcBail -E0x200 +Border +Number, 1
    Gui, BailModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, BailModal:Add, Button, x35 y122 w70 h28 gSetBail1, 1 год
    Gui, BailModal:Add, Button, x115 y122 w70 h28 gSetBail2, 2 года
    Gui, BailModal:Add, Button, x195 y122 w70 h28 gSetBail3, 3 года
    Gui, BailModal:Add, Button, x275 y122 w70 h28 gSetBail4, 4 года
    Gui, BailModal:Add, Button, x350 y122 w70 h28 gSetBail5, 5 лет
    Gui, BailModal:Font, s12 c%CLR_SUCCESS% Bold, Segoe UI
    Gui, BailModal:Add, Text, x0 y160 w460 Center vBailResult, Итоговая сумма: 25 000 руб
    Gui, BailModal:Font, s8 c%CLR_MUTED% Normal, Segoe UI
    Gui, BailModal:Add, Text, x0 y190 w460 Center, Залог не применяется по статьям с судимостью (от 4 звезд)
    Gui, BailModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, BailModal:Add, Button, x70 y218 w150 h38 gCopyBailSum, Скопировать
    Gui, BailModal:Add, Button, x240 y218 w150 h38 gCloseBail, Закрыть
    Gui, BailModal:Show, w460 h274 Center, GIBDD_Bail
    WinActivate, ahk_id %hBailGui%
    DllCall("SetForegroundWindow", "Ptr", hBailGui)
    DllCall("SetWindowPos", "Ptr", hBailGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hBailGui, 460, 274, 20)
return

SetBail1:
    GuiControl, BailModal:, BailYears, 1
    Gosub, CalcBail
return
SetBail2:
    GuiControl, BailModal:, BailYears, 2
    Gosub, CalcBail
return
SetBail3:
    GuiControl, BailModal:, BailYears, 3
    Gosub, CalcBail
return
SetBail4:
    GuiControl, BailModal:, BailYears, 4
    Gosub, CalcBail
return
SetBail5:
    GuiControl, BailModal:, BailYears, 5
    Gosub, CalcBail
return

CalcBail:
    Gui, BailModal:Submit, NoHide
    val := BailYears + 0
    if (val <= 0) {
        GuiControl, BailModal:, BailResult, Введите корректный срок
        return
    }
    total := val * 25000
    GuiControl, BailModal:, BailResult, Итоговая сумма залога: %total% руб
return

CopyBailSum:
    Gui, BailModal:Submit, NoHide
    val := BailYears + 0
    total := val * 25000
    CopyToClip("Сумма освобождения под залог по ст. 5.10 УК РО составляет " . total . " рублей.", "Сумма залога скопирована!")
return

CloseBail:
    Gui, BailModal:Hide
    BailVisible := false
return

ShowRPBinder:
    RPBinderVisible := true
    Gui, RPBinderModal:Destroy
    Gui, RPBinderModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhRPGui
    Gui, RPBinderModal:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    Gui, RPBinderModal:Font, s15 c%CLR_TITLE% Bold, Segoe UI
    Gui, RPBinderModal:Add, Text, x0 y18 w620 Center, БЫСТРЫЕ RP-ОТЫГРОВКИ ДПС ГИБДД
    Gui, RPBinderModal:Font, s9 c%CLR_MUTED% Normal, Segoe UI
    Gui, RPBinderModal:Add, Text, x0 y48 w620 Center, Нажмите для копирования отыгровки в буфер обмена
    Gui, RPBinderModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, RPBinderModal:Add, Button, x25 y78 w275 h38 gRPDoc, 1. Предъявить удостоверение
    Gui, RPBinderModal:Add, Button, x320 y78 w275 h38 gRPStopSign, 2. Остановка жезлом ДПС
    Gui, RPBinderModal:Add, Button, x25 y122 w275 h38 gRPReqDocs, 3. Запрос В/У и документов
    Gui, RPBinderModal:Add, Button, x320 y122 w275 h38 gRPKpk, 4. Проверка гражданина по КПК
    Gui, RPBinderModal:Add, Button, x25 y166 w275 h38 gRPAlco, 5. Освидетельствование (Алко)
    Gui, RPBinderModal:Add, Button, x320 y166 w275 h38 gRPFrisk, 6. Первичный досмотр
    Gui, RPBinderModal:Add, Button, x25 y210 w275 h38 gRPCuff, 7. Надеть наручники
    Gui, RPBinderModal:Add, Button, x320 y210 w275 h38 gRPInCar, 8. Посадить в патруль (/incar)
    Gui, RPBinderModal:Add, Button, x25 y254 w275 h38 gRPEject, 9. Высадить из авто (/eject)
    Gui, RPBinderModal:Add, Button, x320 y254 w275 h38 gRPProtocol, 10. Протокол КоАП (штраф)
    Gui, RPBinderModal:Add, Button, x25 y298 w275 h38 gRPTow, 11. Эвакуация на штрафстоянку
    Gui, RPBinderModal:Add, Button, x320 y298 w275 h38 gRPArrest, 12. Помещение в ИВС (/arrest)
    Gui, RPBinderModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, RPBinderModal:Add, Button, x220 y350 w180 h38 gCloseRPBinder, Закрыть
    Gui, RPBinderModal:Show, w620 h404 Center, GIBDD_RP
    WinActivate, ahk_id %hRPGui%
    DllCall("SetForegroundWindow", "Ptr", hRPGui)
    DllCall("SetWindowPos", "Ptr", hRPGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hRPGui, 620, 404, 20)
return

RPDoc:
    CopyToClip("/do Служебное удостоверение инспектора ГИБДД находится в нагрудном кармане.`n/me резким движением достал удостоверение и показал гражданину в развернутом виде`n/do В удостоверении указаны звание, должность и подразделение ГИБДД.", "Отыгровка удостоверения скопирована!")
return
RPStopSign:
    CopyToClip("/me вытянул руку с регулировочным диском-жезлом вперед, указав водителю на обочину дороги`n/do Инспектор жестом руки приказал остановиться и прижаться вправо.", "Остановка жезлом скопирована!")
return
RPReqDocs:
    CopyToClip("Здравия желаю. Инспектор ДПС ГИБДД.`nПожалуйста, заглушите автомобиль и предъявите Ваше водительское удостоверение и СТС.", "Запрос документов скопирован!")
return
RPKpk:
    CopyToClip("/me снял служебный КПК с поясного держателя, включил экран и перешел в единую базу МВД`n/me ввел серию и номер документа, после чего начал проверку по ориентировкам и неоплаченным штрафам", "Проверка КПК скопирована!")
return
RPAlco:
    CopyToClip("/me расстегнул боковой подсумок, извлек сертифицированный алкотестер и вскрыл одноразовый мундштук`n/me установил мундштук в прибор, включил тест и протянул устройство водителю`nСделайте один глубокий плавный выдох в мундштук до звукового сигнала прибора.", "Отыгровка алкотестера скопирована!")
return
RPFrisk:
    CopyToClip("/me надел одноразовые резиновые перчатки, затем провел руками по верхней одежде и карманам гражданина`n/do В ходе поверхностного досмотра были проверены личные вещи на предмет запрещенных средств.", "Первичный досмотр скопирован!")
return
RPCuff:
    CopyToClip("/me снял металлические наручники с поясного крепления`n/me завел руки нарушителя за спину и аккуратно защелкнул браслеты на обоих запястьях", "Наручники скопированы!")
return
RPInCar:
    CopyToClip("/me открыл заднюю пассажирскую дверь служебного автомобиля`n/me придерживая задержанного за плечо и голову, посадил его на заднее сиденье и закрыл дверь", "Посадка в авто скопирована!")
return
RPEject:
    CopyToClip("/me открыл дверь патрульного автомобиля, удерживая гражданина за плечо, помог ему выйти наружу", "Высадка из авто скопирована!")
return
RPProtocol:
    CopyToClip("/me открыл служебную папку, достал бланк протокола об административном правонарушении и ручку`n/me внес персональные данные, дату, место и квалификацию правонарушения, после чего поставил подпись", "Протокол КоАП скопирован!")
return
RPTow:
    CopyToClip("/me достал пульт управления лебедкой эвакуатора, закрепил буксировочные тросы за шасси автомобиля`n/me активировал подъемник и аккуратно погрузил задержанное транспортное средство на платформу", "Эвакуация скопирована!")
return
RPArrest:
    CopyToClip("/me открыл металлическую решетку камеры временного содержания`n/me завел задержанного в камеру ИВС, закрыл дверь на замок и передал протокол дежурному офицеру", "Передача в ИВС скопирована!")
return

CloseRPBinder:
    Gui, RPBinderModal:Hide
    RPBinderVisible := false
return

ShowForceStages:
    ForceVisible := true
    Gui, ForceModal:Destroy
    Gui, ForceModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhForceGui
    Gui, ForceModal:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    Gui, ForceModal:Font, s15 c%CLR_TITLE% Bold, Segoe UI
    Gui, ForceModal:Add, Text, x0 y18 w620 Center, СТАДИИ ПРИМЕНЕНИЯ СИЛЫ И ОРУЖИЯ
    Gui, ForceModal:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, ForceModal:Add, Text, x0 y48 w620 Center, Глава XI Процессуального кодекса РО  •  ФЗ О Полиции
    Gui, ForceModal:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    Gui, ForceModal:Add, Text, x30 y82 w560 h38, 1. ПРИСУТСТВИЕ СОТРУДНИКА — нахождение сотрудника в форме и служебном авто. Предостерегает от нарушений одним лишь присутствием.
    Gui, ForceModal:Add, Text, x30 y124 w560 h38, 2. УСТНЫЕ ТРЕБОВАНИЯ — законные, понятные распоряжения сотрудника полиции. Предупреждение о последствиях неподчинения.
    Gui, ForceModal:Add, Text, x30 y166 w560 h38, 3. ФИЗИЧЕСКАЯ СИЛА — применение боевых приемов, захватов и заломов для преодоления физического сопротивления нарушителя.
    Gui, ForceModal:Add, Text, x30 y208 w560 h38, 4. СПЕЦСРЕДСТВА (Тазер, дубинка, наручники) — применяются при активном сопротивлении, побеге или групповых беспорядках.
    Gui, ForceModal:Add, Text, x30 y250 w560 h48, 5. СМЕРТЕЛЬНАЯ СИЛА (Огнестрельное оружие) — применяется ИСКЛЮЧИТЕЛЬНО при реальной и непосредственной угрозе жизни граждан или сотрудников. Предупредительные выстрелы запрещены!
    Gui, ForceModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, ForceModal:Add, Button, x220 y308 w180 h38 gCloseForceStages, Закрыть
    Gui, ForceModal:Show, w620 h362 Center, GIBDD_Force
    WinActivate, ahk_id %hForceGui%
    DllCall("SetForegroundWindow", "Ptr", hForceGui)
    DllCall("SetWindowPos", "Ptr", hForceGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hForceGui, 620, 362, 20)
return

CloseForceStages:
    Gui, ForceModal:Hide
    ForceVisible := false
return

BuildTimerGui() {
    global
    Gui, ProcTimer:Destroy
    Gui, ProcTimer:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhTimerGui
    Gui, ProcTimer:Color, %CLR_PANEL%, %CLR_PANEL2%
    Gui, ProcTimer:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, ProcTimer:Add, Text, x10 y8 w220 Center, ТАЙМЕР ЗАДЕРЖАНИЯ
    Gui, ProcTimer:Font, s16 c%CLR_TITLE% Bold, Consolas
    Gui, ProcTimer:Add, Text, x10 y30 w220 Center vTimerDisplay, 00:00
    Gui, ProcTimer:Font, s8 c%CLR_MUTED% Normal, Segoe UI
    Gui, ProcTimer:Add, Text, x10 y60 w220 Center vTimerStatusLabel, Режим: Не задан
    Gui, ProcTimer:Font, s8 cFFFFFF Bold, Segoe UI
    Gui, ProcTimer:Add, Button, x10 y86 w68 h26 gSetTimerAdv, 10м Адв
    Gui, ProcTimer:Add, Button, x86 y86 w68 h26 gSetTimerJudge, 15м Суд
    Gui, ProcTimer:Add, Button, x162 y86 w68 h26 gSetTimerHour, 60м Час
    Gui, ProcTimer:Add, Button, x10 y118 w104 h26 gToggleTimerRunning, Старт / Пауза
    Gui, ProcTimer:Add, Button, x126 y118 w104 h26 gResetTimer, Сбросить
    Gui, ProcTimer:Font, s8 c%CLR_DANGER% Bold, Segoe UI
    Gui, ProcTimer:Add, Button, x10 y150 w220 h24 gHideTimerGui, Закрыть таймер
}

ToggleTimerGui:
    if (TimerGuiVisible) {
        Gui, ProcTimer:Hide
        TimerGuiVisible := false
    } else {
        BuildTimerGui()
        Gui, ProcTimer:Show, x30 y180 w240 h184 NoActivate, GIBDD_Timer
        TimerGuiVisible := true
        ApplyRoundedCorners(hTimerGui, 240, 184, 14)
        Gosub, UpdateTimerLabel
    }
return

HideTimerGui:
    Gui, ProcTimer:Hide
    TimerGuiVisible := false
return

SetTimerAdv:
    TimerRemaining := 600
    TimerModeName := "Адвокат (10 мин)"
    TimerActive := true
    SetTimer, TimerTick, 1000
    Gosub, UpdateTimerLabel
return

SetTimerJudge:
    TimerRemaining := 900
    TimerModeName := "Судья/Прок (15 мин)"
    TimerActive := true
    SetTimer, TimerTick, 1000
    Gosub, UpdateTimerLabel
return

SetTimerHour:
    TimerRemaining := 3600
    TimerModeName := "Проц. час (60 мин)"
    TimerActive := true
    SetTimer, TimerTick, 1000
    Gosub, UpdateTimerLabel
return

ToggleTimerRunning:
    if (TimerRemaining <= 0)
        return
    TimerActive := !TimerActive
    if (TimerActive)
        SetTimer, TimerTick, 1000
    else
        SetTimer, TimerTick, Off
    Gosub, UpdateTimerLabel
return

ResetTimer:
    TimerActive := false
    SetTimer, TimerTick, Off
    TimerRemaining := 0
    TimerModeName := "Не задан"
    Gosub, UpdateTimerLabel
return

TimerTick:
    if (!TimerActive)
        return
    if (TimerRemaining > 0) {
        TimerRemaining--
        Gosub, UpdateTimerLabel
    } else {
        TimerActive := false
        SetTimer, TimerTick, Off
        Gosub, UpdateTimerLabel
        SoundPlay, *16
        MsgBox, 48, Внимание ДПС ГИБДД, Время по таймеру истекло! (%TimerModeName%)
    }
return

UpdateTimerLabel:
    m := Floor(TimerRemaining / 60)
    s := Mod(TimerRemaining, 60)
    strM := (m < 10) ? "0" . m : m
    strS := (s < 10) ? "0" . s : s
    timeStr := strM . ":" . strS
    GuiControl, ProcTimer:, TimerDisplay, %timeStr%
    statusText := TimerActive ? TimerModeName . " [ИДЕТ]" : TimerModeName . " [ПАУЗА]"
    GuiControl, ProcTimer:, TimerStatusLabel, %statusText%
return

ShowRules:
    RulesVisible := true
    Gui, RulesModal:Destroy
    Gui, RulesModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhRulesGui
    Gui, RulesModal:Color, %CLR_BG_TOP%, %CLR_BG_BOT%
    Gui, RulesModal:Font, s15 c%CLR_TITLE% Bold, Segoe UI
    Gui, RulesModal:Add, Text, x25 y20 w570, ПРИМЕЧАНИЯ И РЕГЛАМЕНТ ДПС
    Gui, RulesModal:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, RulesModal:Add, GroupBox, x25 y52 w570 h130, 1. РЕГЛАМЕНТ СТАТЬИ 10 КоАП (ОТКАЗ ОТ ШТРАФА)
    Gui, RulesModal:Font, s9 c%CLR_TEXT% Normal, Segoe UI
    rText1 := "За нарушение ст. 10 КоАП задержанного необходимо отвозить в здание Правительства.`r`nДалее туда же вызываем сотрудника МВД для передачи процессуальных действий и судью через канал в Discord фракции.`r`nЕсли судья не приедет в течение 15 минут — задержанного необходимо отпустить, а материалы дела направить в суд."
    Gui, RulesModal:Add, Text, x38 y78 w544 h95, %rText1%
    Gui, RulesModal:Font, s9 c%CLR_ACCENT2% Bold, Segoe UI
    Gui, RulesModal:Add, GroupBox, x25 y190 w570 h125, 2. ПОДСЛЕДСТВЕННОСТЬ СТРУКТУР (КУДА ВЕЗТИ)
    Gui, RulesModal:Font, s10 c%CLR_SUCCESS% Bold, Consolas
    rText2 := "Ф  ->  ФСБ`r`nС  ->  Следственный комитет`r`nР  ->  МВД (основное место доставки ДПС)`r`nВ  ->  Военная полиция / Армия"
    Gui, RulesModal:Add, Text, x40 y216 w540 h90, %rText2%
    Gui, RulesModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, RulesModal:Add, Button, x210 y330 w200 h42 gCloseRules, Закрыть
    Gui, RulesModal:Show, w620 h390 Center, GIBDD_Rules
    WinActivate, ahk_id %hRulesGui%
    DllCall("SetForegroundWindow", "Ptr", hRulesGui)
    DllCall("SetWindowPos", "Ptr", hRulesGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
    ApplyRoundedCorners(hRulesGui, 620, 390, 20)
return

CloseRules:
    Gui, RulesModal:Hide
    RulesVisible := false
    if (OverlayVisible) {
        WinActivate, ahk_id %hOverlayGui%
    } else if (PrevGameHwnd) {
        WinActivate, ahk_id %PrevGameHwnd%
    }
return

OpenSettingsFromMenu:
    CloseAllWindows()
    ShowSettingsGui(CurrentHotkey)
return

InitDatabase() {
    global ArticleDB := []
    k6 =
    (
КоАП РО|Статья 14.8. Встречка|2-7к (Штраф 2.000 – 7.000 руб.)|1
КоАП РО|Статья 14.9. Правила стоянки и остановки|1-5к (Штраф 1.000 – 5.000 руб.)|1
КоАП РО|Статья 14.18.1. По обочине, разделительной полосе, автобусной|0.5-2к (Штраф 500 – 2.000 руб.)|1
КоАП РО|Статья 14.18.2. По тротуару, пешеходной, велосипедной|1-4к (Штраф 1.000 – 4.100 руб.)|1
КоАП РО|Статья 14.25.1. Несоблюдение дорожного занка, разметки|0.5-3к (Штраф 500 – 3.000 руб.)|1
КоАП РО|Статья 14.16.1. Нарушение правил разворота,поворота|0.5-2к (Штраф 500 – 2.000 руб.)|1
КоАП РО|Статья 14.25.2. 14.25.1 только повлекшее ДТП|3-7к (Штраф 3.000 – 7.000 руб.)|1
КоАП РО|Статья 14.1. Управление без прав|20-40к (Штраф 20.000 – 40.000 руб.)|1
КоАП РО|Статья 14.2. Непредоставление документов|5-10к (Штраф 5.000 – 10.000 руб.)|1
КоАП РО|Статья 14.3. Оставление места ДТП|10-30к (Штраф 10.000 – 30.000 руб.)|1
КоАП РО|Статья 14.4. Опасное вождение, аварийные ситуации|20-50к (Штраф 20.000 – 50.000 руб.)|1
КоАП РО|Статья 14.6.2. Отсутсвие регистрации или знака|10-25к (Штраф 10.000 – 25.000 руб.)|1
КоАП РО|Статья 14.6.2. Незарегистрированный номер|25-50к (Штраф 25.000 – 50.000 руб.)|1
КоАП РО|Статья 14.11. Эксплуатация неисправного тс|3-7к (Штраф 3.000 – 7.000 руб.)|1
КоАП РО|Статья 14.12. Нарушение правил повлекшее ущерб|15-40к (Штраф 15.000 – 40.000 руб.)|1
КоАП РО|Статья 14.26. Непредоставление преимущества пешеходу|2-6к (Штраф 2.000 – 6.000 руб.)|1
КоАП РО|Статья 14.5. Непредоставление преимущества экстренной службе|15-30к (Штраф 15.000 – 30.000 руб.)|1
КоАП РО|Статья 14.7. Превышение скорости|0.5-5к (Штраф 500 – 5.000 руб.)|1
КоАП РО|Статья 14.10. Повторное нарушение 49, 50, 52.1, 52.2, опасность для участников|20-40к (Штраф 20.000 – 40.000 руб.)|1
КоАП РО|Статья 14.13.1. Невыполнение обязанностей в связи с ДТП|5-15к (Штраф 5.000 – 15.000 руб.)|1
КоАП РО|Статья 14.13.2. Неоказание первой помощи или вызове медиков при ДТП|15-30к (Штраф 15.000 – 30.000 руб.)|1
КоАП РО|Статья 14.16.1. Неуступил дорогу при повороте,развороте,выезде|0.5-2к (Штраф 500 – 2.000 руб.)|1
КоАП РО|Статья 14.16.2. Разворот,движение задним ходом где запрещено|0.5-3к (Штраф 500 – 3.000 руб.)|1
КоАП РО|Статья 14.16.3. Нарушение 14.16.1 или 2 создавшая аварию|3-10к (Штраф 3.000 – 10.000 руб.)|1
КоАП РО|Статья 14.17.1. Непредоставление преимущества на перекрестке|5-15к (Штраф 5.000 – 15.000 руб.)|1
КоАП РО|Статья 14.19.1. Обгон или опережение без обеспечения безопасности маневра|2-6к (Штраф 2.000 – 6.000 руб.)|1
КоАП РО|Статья 14.19.2. Обгон в запрещённых местах|3-7к (Штраф 3.000 – 7.000 руб.)|1
КоАП РО|Статья 14.21.1. На автомагистрале - остановка,движение задним ходом,разворот|1-4к (Штраф 1.000 – 4.100 руб.)|1
КоАП РО|Статья 14.22.2. Использование маячков и спец сигнала без необходимости|30-70к (Штраф 30.000 – 70.000 руб.)|1
КоАП РО|Статья 14.23. Нарушение свет и звук|1-3к (Штраф 1.000 – 3.000 руб.)|1
КоАП РО|Статья 14.28.1. Воспрепятствование движению колонны|10-25к (Штраф 10.000 – 25.000 руб.)|1
КоАП РО|Статья 7.1.1. Мелкое хулиганство|5-15к / 10 суток|1
КоАП РО|Статья 7.1.2. То же самое совершенное повторно|15-30к / 10 суток|1
КоАП РО|Статья 7.10. Наркота до 3 грамм|20-40к / 10 суток|1
КоАП РО|Статья 7.11.1. Причинение незначительного вреда здоровью|15-30к / 10 суток|1
КоАП РО|Статья 7.11.2. Тоже самое по неосторожности|10-20к|1
КоАП РО|Статья 8.1. Оскорбление|10-20к|1
КоАП РО|Статья 8.5. Повреждение имущества|10-30к|1
КоАП РО|Статья 32.1. Нарушение правил использования оружия|30-60к|1
КоАП РО|Статья 38. Воспрепятствование гос служащему|15-35 / 10 суток|1
    )
    LoadData(k6)

    u1 =
    (
УК РО|Статья 1. Уголовное законодательство РО|Состоит из настоящего Кодекса на основе Конституции РО|0
УК РО|Статья 1.1. Задачи Уголовного кодекса РО|Охрана прав, свобод, правопорядка, безопасности и предупреждение преступлений|0
УК РО|Статья 1.2. Принцип законности|Наказуемость деяния определяется только УК РО; запрет аналогии закона|0
УК РО|Статья 1.3. Принцип равенства граждан перед законом|Равенство всех лиц независимо от пола, расы, должности и статуса|0
УК РО|Статья 1.4. Принцип вины|Ответственность только при наличии установленной вины; запрет объективного вменения|0
УК РО|Статья 1.5. Принцип справедливости|Соответствие тяжести содеянному; никто не может нести наказание дважды|0
УК РО|Статья 1.6. Принцип гуманизма|Безопасность человека; запрет физических страданий и унижения достоинства|0
УК РО|Статья 1.7. Основание уголовной ответственности|Совершение деяния со всеми признаками предусмотренного состава преступления|0
УК РО|Статья 1.8. Состав преступления (объект, субъект, стороны, виды)|Материальные, формальные и усеченные составы преступлений|0|ч. 1 Элементы состава: объект, субъект, объективная и субъективная стороны^Отсутствие одного признака исключает состав преступления~ч. 2 Виды составов: материальные, формальные, усеченные^Разграничение по моменту окончания преступления
УК РО|Статья 1.9. Судимость|Штраф не влечет судимости; судимость запрещает государственную службу|0|ч. 1 Понятие судимости^Правовой статус осужденного лица~ч. 3 Уголовный штраф без судимости^Судимость при уголовном штрафе не возникает~ч. 4 Запрет государственной службы^Судимость запрещает нахождение на государственной службе
УК РО|Статья 1.10. Действие уголовного закона во времени|Определяется законом на момент совершения общественно опасного деяния|0
УК РО|Статья 1.11. Обратная сила уголовного закона|Закон, смягчающий наказание или устраняющий преступность, имеет обратную силу|0
УК РО|Статья 2. Понятие преступления|Виновное общественно опасное деяние под угрозой наказания; исключение малозначительности|0
УК РО|Статья 2.1. Рецидив преступлений|Совершение умышленного преступления лицом с судимостью за умышленное|0
УК РО|Статья 2.2. Формы вины|Преступление признается совершенным умышленно либо по неосторожности|0
УК РО|Статья 2.3. Преступление, совершенное умышленно|Прямой умысел (желал последствий) и косвенный (сознательно допускал)|0
УК РО|Статья 2.4. Преступление, совершенное по неосторожности|Легкомыслие (самонадеянный расчет) либо небрежность (не предвидел)|0
УК РО|Статья 2.5. Невиновное причинение вреда|Лицо не могло и не должно было осознавать опасность либо предотвратить вред|0
УК РО|Статья 2.6. Ответственность за преступление с двумя формами вины|Тяжкие последствия причинены по неосторожности; в целом деяние умышленное|0
УК РО|Статья 3. Оконченное и неоконченное преступления|Оконченное деяние содержит все признаки состава преступления|0
УК РО|Статья 3.1. Приготовление к преступлению и покушение на преступление|Приготовление — создание условий; Покушение — непосредственные действия|0
УК РО|Статья 3.2. Добровольный отказ от преступления|Окончательное прекращение действий освобождает от ответственности|0
УК РО|Статья 3.3. Понятие соучастия в преступлении|Умышленное совместное участие двух или более лиц в преступлении|0
УК РО|Статья 3.4. Виды соучастников преступления|Исполнитель, организатор, подстрекатель, пособник|0
УК РО|Статья 3.5. Ответственность соучастников преступления|Определяется характером и степенью фактического участия каждого лица|0
    )
    LoadData(u1)

    u2 =
    (
УК РО|Статья 3.6. Совершение преступления группой лиц, по сговору, ОПГ, ОПС|Влечет более строгое наказание в пределах, предусмотренных УК|0
УК РО|Статья 3.7. Эксцесс исполнителя преступления|Совершение исполнителем деяния, не охваченного умыслом остальных соучастников|0
УК РО|Статья 4. Необходимая оборона|Защита от опасного для жизни насилия; самооборона в жилище правомерна|0
УК РО|Статья 4.1. Причинение вреда при задержании лица, совершившего преступление|Правомерный вред для доставления в органы власти при соразмерности|0
УК РО|Статья 4.2. Крайняя необходимость|Устранение опасности причинением меньшего вреда, если иной путь невозможен|0
УК РО|Статья 4.3. Обоснованный риск|Правомерен для достижения общественно полезной цели при принятии мер защиты|0
УК РО|Статья 4.4. Исполнение приказа или распоряжения|Ответственность несет лицо, отдавшее незаконный приказ; исполнение незаконного наказуемо|0
УК РО|Статья 4.5. Физическое или психическое принуждение|Исключает ответственность, если лицо не могло руководить действиями|0
УК РО|Статья 4.6. Нормы о наркотических веществах (каннабиноиды)|До 3 г изымаются без УК; 1 куст Green = 5 г, 1 семечко Green = 2 г|0
УК РО|Статья 5. Виды наказаний|Судебный/уголовный штраф, лишение права, увольнение, тюрьма, работы|0|ч. 1 Перечень видов наказаний^Штрафы, лишение права, увольнение, лишение свободы, работы~ч. 3 Уголовный штраф вне суда^Назначается МВД, ФСБ, ФСО, Прокуратурой и судом
УК РО|Статья 5.1. Исправительные работы|Назначаются по основному месту работы либо в местах, определяемых судом|0
УК РО|Статья 5.1.2. Принудительные работы|Применяются как альтернатива лишению свободы с привлечением к труду|0
УК РО|Статья 5.2. Общие начала назначения наказания|Внесудебно лишение свободы не более 5 лет (за исключением ст. 17.3 УК)|0|ч. 4 Внесудебный предел лишения свободы^Не более 5 лет (за исключением ст. 17.3 УК во время процесса)~ч. 5 Упрощенное разрешение уголовного материала^Только лишение свободы до 5 лет в пределах статьи
УК РО|Статья 5.2.1. Назначение наказания за неоконченное преступление|Приготовление не более половины, покушение не более 3/4 максимума|0
УК РО|Статья 5.3. Обстоятельства, смягчающие наказание|Принуждение, явка с повинной, помощь потерпевшему, возмещение ущерба|0
УК РО|Статья 5.4. Обстоятельства, отягчающие наказание|Группа лиц, вражда, месть служащему, особая жестокость, форма, опьянение|0
УК РО|Статья 5.5. Назначение более мягкого наказания|Ниже низшего предела при исключительных обстоятельствах|0
УК РО|Статья 5.6. Освобождение в связи с назначением штрафа/работ или примирением|Впервые совершившее лицо может быть освобождено судом со штрафом от 10.000|0
УК РО|Статья 5.7. Сроки давности привлечения к уголовной ответственности|15 лет (15 дней); розыск боло-приоритета от 1 до 5 звезд|0|ч. 1 Срок давности 15 дней^Освобождение по истечении 15 календарных дней~ч. 3 Приоритет розыска от 1 до 5 звезд^Устанавливается сотрудниками МВД и ФСБ
УК РО|Статья 5.8. Судимость|Отметка о судимости ставится при аресте по статьям от 4 звезд и выше|0
УК РО|Статья 5.9. Освобождение при добровольной сдаче предметов (оружие, наркотики)|Добровольная сдача по ст. 12.8, 12.8.1, 13.1, 13.2 освобождает от УК|0
УК РО|Статья 5.10. Освобождение под залог|Применяется по статьям без судимости в соотношении 1 год к 25.000|0
УК РО|Статья 5.11. Упрощенное разрешение уголовного материала сотрудником правопорядка|Лишение свободы до 5 лет на месте задержания без отдельного дела|0
УК РО|Статья 5.12. Подследственность: [Р] МВД, [Ф] ФСБ, [В] Военная полиция, [С] СК|Задержание производит дознаватель ведомства либо с передачей по компетенции|0
УК РО|Статья 6.1 (Р) Умышленное нанесение телесных повреждений легкой или средней степени|до 20 месяцев лишения свободы (2 звезды)|1
    )
    LoadData(u2)

    u3 =
    (
УК РО|Статья 6.2 (Ф/Р) Убийство или причинение тяжких телесных повреждений|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 6.3 (Ф/Р) Тяжкое убийство (двух или более лиц / близких служащего)|до 50 месяцев с созданием записи о судимости (5 звезд)|1
УК РО|Статья 6.4 (Р) Причинение тяжкого вреда здоровью по неосторожности|до 20 месяцев лишения свободы (2 звезды)|1
УК РО|Статья 6.5 (Р) Причинение смерти по неосторожности|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 6.6 (Ф/Р) Угроза расправой должностному лицу или его близким|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 6.7 (Р) Угрозы с целью запугать человека|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 6.8 (Р) Умышленное нанесение телесных повреждений животному|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 6.9 (Р) Нарушение ПДД, повлекшее тяжкий вред здоровью или смерть|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 7.1 (Ф) Похищение человека|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 7.2 (Р) Клевета в публичном выступлении, СМИ или с использованием должности|до 20 месяцев лишения свободы (2 звезды)|1
УК РО|Статья 7.3 (Р) Клевета, соединенная с обвинением лица в преступлении|до 20 месяцев лишения свободы (2 звезды)|1
УК РО|Статья 7.4 (Р) Нарушения против личности и чести, допущенные сотрудниками СМИ|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 7.5 (Р) Возбуждение ненависти либо вражды|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 7.6 (Р) Возбуждение ненависти либо вражды представителем власти|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 8.1 (Ф/Р/В) Неисполнение подчиненным приказа начальника на военной службе|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 8.2 (В/С) Самовольное оставление воинской части или места службы|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 8.3 (В/С) Дезертирство (самовольное оставление с целью уклонения)|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 8.4 (В/С) Нарушение правил несения боевого дежурства|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 8.5 (В/С) Уничтожение, повреждение или халатность к имуществу Нац. Гвардии|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 8.6 (В/С) Нарушение правил вождения боевой машины с тяжким вредом|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 9.1 (Ф) Незаконный сбор или распространение сведений о частной жизни|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 9.2 (Ф/Р) Незаконное проникновение в жилище и на частную территорию|до 20 месяцев лишения свободы (2 звезды)|1
УК РО|Статья 9.3 (Ф/Р) Воспрепятствование свободному осуществлению избирательных прав|до 10 месяцев лишения свободы (1 звезда)|0
УК РО|Статья 9.4 (Ф/Р) Принуждение журналистов к распространению или отказу от инфо|до 10 месяцев лишения свободы (1 звезда)|0
УК РО|Статья 9.5 (Ф/Р) Незаконное ограничение профессиональной деятельности журналистов|до 10 месяцев лишения свободы (1 звезда)|0
    )
    LoadData(u3)

    u4 =
    (
УК РО|Статья 9.6 (Ф/Р/С) Необоснованный отказ от предоставления медпомощи или услуг полиции|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 9.7 (Ф/Р/С) Воспрепятствование деятельности адвоката / вмешательство в защиту|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 10.1 (Р) Кража чужого имущества стоимостью свыше 3.000|до 10 месяцев лишения свободы (1 звезда)|0
УК РО|Статья 10.2 (Р) Кража чужого имущества стоимостью свыше 5.000|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 10.3 (Ф/Р) Кража чужого имущества стоимостью свыше 15.000|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 10.4 (Ф) Мошенничество (хищение чужого имущества путем обмана)|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 10.5 (Ф/Р) Грабеж (открытое хищение чужого имущества)|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 10.6 (Ф/Р) Разбойное ограбление с применением опасного насилия|до 50 месяцев лишения свободы|1|ст. 10.6 Обычный разбой с насилием^до 40 месяцев с созданием записи о судимости (4 звезды)~ст. 10.6.1 Разбой крупных финансовых объектов (банки)^до 50 месяцев с созданием записи о судимости (5 звезд)
УК РО|Статья 10.7 (Р) Неправомерное завладение ТС (угон)|до 40 месяцев лишения свободы|1|ст. 10.7 Угон гражданского ТС^до 30 месяцев лишения свободы (3 звезды)~ст. 10.7.1 Завладение государственным или оперативным служебным ТС^до 40 месяцев с созданием записи о судимости (4 звезды)
УК РО|Статья 10.8 (Р) Умышленные уничтожение или повреждение имущества|до 30 месяцев лишения свободы|1|ст. 10.8 Повреждение чужого частного имущества^до 20 месяцев лишения свободы (2 звезды)~ст. 10.8.1 Повреждение государственного имущества^до 30 месяцев лишения свободы (3 звезды)
УК РО|Статья 10.9 (Ф/Р) Уничтожение чужого имущества путем поджога, взрыва|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 10.10 (Ф) Вымогательство под угрозой насилия или уничтожения имущества|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 10.11 (Ф/С) Незаконное изъятие имущества или лицензий сотрудником органов|от штрафа до 30 месяцев с возмещением ущерба (3 звезды)|0
УК РО|Статья 10.12 (Ф/Р) Кража с проникновением в частное жилище или помещение|до 40 месяцев лишения свободы|1|ст. 10.12 Кража с проникновением в жилище^до 30 месяцев лишения свободы (3 звезды)~ст. 10.12.1 Кража группой лиц с проникновением в жилище^до 40 месяцев с созданием записи о судимости (4 звезды)
УК РО|Статья 11.1 (Ф/С) Предпринимательская деятельность без регистрации|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 11.2 (Ф/С) Принуждение к совершению сделки или к отказу от нее|до 30 месяцев лишения свободы (3 звезды)|0|ст. 11.2 Принуждение к сделке без применения оружия^до 30 месяцев лишения свободы (3 звезды)~ст. 11.2.1 Принуждение к сделке с применением огнестрельного оружия^до 30 месяцев лишения свободы (3 звезды)
УК РО|Статья 11.3 (Ф/С) Уклонение от уплаты налогов (взыскание в 2-кратном размере)|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 11.4 (Ф/С) Сокрытие денежных средств или имущества от взыскания налогов|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 11.5 (Ф/С) Ограничение конкуренции с крупным ущербом|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 11.6 (Ф/С) Преднамеренное банкротство юридического лица|до 40 месяцев с созданием записи о судимости (4 звезды)|0
    )
    LoadData(u4)

    u5 =
    (
УК РО|Статья 11.7 (Ф/Р/С) Незаконные получение и разглашение коммерческой или банковской тайны|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 11.8 (Ф/С) Уклонение организации от уплаты штрафа|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 11.9 (Ф/С) Нецелевое использование средств государственного бюджета|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 11.10 (Ф/С) Присвоение финансовых средств государственной структуры|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 11.11 (Р) Отказ или уклонение от оплаты медицинских услуг|до 20 месяцев с возмещением ущерба (2 звезды)|0
УК РО|Статья 11.12 (Р) Незаконный вылов водных биологических ресурсов|до 30 месяцев с изъятием лицензии на ловлю (3 звезды)|0
УК РО|Статья 12.1 (Ф/С) Терроризм (взрыв, поджог, угроза их совершения)|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.2 (Ф/С) Склонение, вербовка или финансирование терроризма|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.3 (Ф/С) Захват или удержание лица в качестве заложника|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.4 (Ф/Р/С) Заведомо ложное сообщение о готовящемся теракте или взрыве|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 12.5 (Ф/Р/С) Организация массовых беспорядков или участие в них|до 50 месяцев лишения свободы (5 звезд)|0|ст. 12.5 Участие и организация массовых беспорядков^до 50 месяцев с созданием записи о судимости (5 звезд)~ст. 12.5.1 Массовые беспорядки с ущербом, вредом или смертью^до 50 месяцев с созданием записи о судимости (5 звезд)
УК РО|Статья 12.6 (Р) Хулиганство, грубое систематическое нарушение порядка|до 20 месяцев лишения свободы (2 звезды)|1
УК РО|Статья 12.7 (Ф/Р/С) Незаконное проникновение на закрытый объект РО|до 50 месяцев лишения свободы|1|ст. 12.7 Проникновение на закрытый объект РО^до 30 месяцев лишения свободы (3 звезды)~ст. 12.7.1 Проникновение на режимный объект со спецстатусом^до 50 месяцев с созданием записи о судимости (5 звезд)~ст. 12.7.2 Проникновение за оцепление военного или ЧП положения^до 50 месяцев с созданием записи о судимости (5 звезд)
УК РО|Статья 12.8 (Ф/Р/С) Незаконный оборот оружия, боеприпасов и спецсредств|до 50 месяцев лишения свободы|1|ст. 12.8 Оборот легких бронежилетов, оружия и патронов^до 40 месяцев с созданием записи о судимости (4 звезды)~ст. 12.8.1 Оборот гос. спецсредств (дефибрилляторы, тяжелая броня)^до 50 месяцев с созданием записи о судимости (5 звезд)
УК РО|Статья 12.9 (Ф/Р) Хищение огнестрельного оружия или взрывчатки|до 50 месяцев лишения свободы|0|ст. 12.9 Хищение оружия или боеприпасов^до 40 месяцев с созданием записи о судимости (4 звезды)~ст. 12.9.1 Хищение оружия со склада улик сотрудниками органов^до 50 месяцев с созданием записи о судимости (5 звезд)
УК РО|Статья 12.10 (Ф/С) Организация несанкционированных митингов или призывы к бунту|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.11 (Ф/С) Организация геноцида либо попытка его организации|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.12 (Ф/С) Создание преступной организации либо руководство ею|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.13 (Ф/С) Подрыв нацбезопасности, вывод средств в офшоры, спонсирование террористов|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.14 (Ф/С) Публичные призывы к нарушению территориальной целостности РО|до 40 месяцев с созданием записи о судимости (4 звезды)|0
    )
    LoadData(u5)

    u6 =
    (
УК РО|Статья 12.15 (Ф/Р/С) Участие в несанкционированных митингах и шествиях|до 50 месяцев лишения свободы|0|ст. 12.15 Участие в незаконных шествиях и демонстрациях^до 20 месяцев лишения свободы (2 звезды)~ст. 12.15.1 Участие с игнорированием законных требований^до 50 месяцев лишения свободы (5 звезд)
УК РО|Статья 13.1 (Ф/С) Незаконное кустарное производство и сбор наркотиков|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 13.2 (Ф/Р/С) Незаконное хранение, приобретение, перевозка наркотиков (свыше 3 г)|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 13.3 (Ф/С) Незаконный оборот наркотиков в особо крупном размере (свыше 20 г)|до 50 месяцев с созданием записи о судимости (5 звезд)|1
УК РО|Статья 13.4 (Р/С) Пропаганда наркотических средств или растений|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 13.5 (Ф/С) Оборот наркотических средств сотрудниками госструктур|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 13.6 (Ф/С) Оборот синтетических наркотических веществ|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 13.7 (Ф/Р/С) Незаконный сбыт и распространение наркотических средств|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 14.1 (Ф/Р/С) Посягательство на жизнь государственного или общественного деятеля|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.2 (Ф/Р/С) Насильственный захват власти или вооруженный мятеж|до 50 месяцев лишения свободы|0|ст. 14.2 Захват власти или мятеж^до 50 месяцев с созданием записи о судимости (5 звезд)~ст. 14.2.1 Агитация или руководство движением по захвату власти^до 40 месяцев с созданием записи о судимости (4 звезды)
УК РО|Статья 14.3 (Ф/С) Разглашение сведений, составляющих государственную тайну|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.4 (Ф/С) Приобретение, сбыт или использование формы госструктур, жетонов|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 14.5 (Ф/С) Государственная измена / шпионаж|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.6 (Ф/С) Утрата документов, содержащих государственную тайну|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 14.7 (Ф/С) Нарушение законодательства о выборах, подлог документов|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.8 (Ф/С) Незаконный оборот государственных секретов и закрытых данных|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 14.9 (Ф/С) Продажа, хранение глушащих устройств и радар-детекторов|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 15.1 (Ф/С) Превышение и злоупотребление должностными полномочиями|до 50 месяцев лишения свободы|1|ст. 15.1 Превышение должностных полномочий^до 40 месяцев с созданием записи о судимости (4 звезды)~ст. 15.1.1 Злоупотребление служебными полномочиями^до 50 месяцев с созданием записи о судимости (5 звезд)
УК РО|Статья 15.2 (Ф/Р/С) Умышленное неисполнение законного приказа начальника полицейским|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 15.3 (Ф/С) Самовольное присвоение гражданином полномочий должностного лица|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 15.4 (Ф/С) Получение взятки должностным лицом|до 50 месяцев с созданием записи о судимости (5 звезд)|1
УК РО|Статья 15.5 (Ф/С) Дача взятки должностному лицу|до 40 месяцев с созданием записи о судимости (4 звезды)|1
    )
    LoadData(u6)

    u7 =
    (
УК РО|Статья 15.6 (Ф/С) Халатность должностного лица с причинением крупного ущерба|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 15.7 (Ф/Р/С) Подкуп голосов избирателей во время выборов|до 10 месяцев лишения свободы (1 звезда)|0
УК РО|Статья 15.8 (Ф/С) Неисполнение сотрудников указов и нормативных актов Правительства/IB|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 15.9 (Ф/С) Неисполнение руководством госструктур актов Премьер-министра|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 16.1 (Ф/С) Вмешательство в деятельность суда или следствия|до 50 месяцев лишения свободы|0|ст. 16.1 Вмешательство в суд или следствие^до 50 месяцев с созданием записи о судимости (5 звезд)~ст. 16.1.2 Воспрепятствование деятельности прокурора или следователя^до 40 месяцев с созданием записи о судимости (4 звезды)
УК РО|Статья 16.2 (Ф/С) Посягательство на жизнь судьи, прокурора, следователя|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 16.3 (Ф/Р/С) Неуважение к суду и участникам судебного заседания|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 16.4 (Ф/С) Привлечение заведомо невиновного к ответственности|до 40 месяцев лишения свободы|0|ст. 16.4 Привлечение к уголовной ответственности^до 40 месяцев с созданием записи о судимости (4 звезды)~ст. 16.4.1 Привлечение к административной ответственности^до 30 месяцев лишения свободы (3 звезды)
УК РО|Статья 16.5 (Ф/С) Заведомо незаконное задержание или арест|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 16.6 (Ф/С) Фальсификация доказательств по гражданскому или адм. делу|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 16.7 (Ф/С) Фальсификация доказательств по уголовному делу следователем/прокурором|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 16.8 (Ф/С) Вынесение судьей заведомо неправосудного судебного акта|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 16.9 (Ф/Р/С) Заведомо ложный донос о совершении преступления|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 16.10 (Ф/С) Заведомо ложные показания свидетеля или эксперта в суде|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 16.11 (Ф/С) Подкуп свидетеля или эксперта в суде|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 16.12 (Ф/Р/С) Неисполнение судебного акта или указа Кабинета министров|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 16.13 (Ф/С) Сокрытие или уничтожение улик|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 16.14 (Ф/С) Уклонение от следствия, задержания и суда (увольнение, смена внешности)|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 16.15 (Ф/Р/С) Дача ложных сведений следователю или суду|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 16.16 (Ф/Р/С) Побег из места лишения свободы или из-под стражи|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 16.17 (Ф/С) Злостное неисполнение судебного акта представителем власти|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 16.18 (Ф/С) Незаконное ограничение свободы граждан|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 17.1 (Ф/Р) Посягательство на жизнь сотрудника силовых структур|до 50 месяцев с созданием записи о судимости (5 звезд)|1
    )
    LoadData(u7)

    u8 =
    (
УК РО|Статья 17.2 (Ф/Р) Нанесение телесных повреждений или угроза представителю власти|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 17.3 (Ф/Р) Оскорбление представителя власти при исполнении обязанностей|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 17.4 (Р) Перевозка товаров без документов и подделка документов|до 40 месяцев лишения свободы|0|ст. 17.4 Перевозка товаров без коммерческих документов^до 20 месяцев лишения свободы (2 звезды)~ст. 17.4.1 Подделка документов, лицензий, печатей и бланков^до 40 месяцев с созданием записи о судимости (4 звезды)
УК РО|Статья 17.5 (Ф/С) Самоуправство (самовольные действия вопреки закону)|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 17.6 (Ф/Р/С) Неподчинение законным требованиям сотрудника силовых структур|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 17.7 (Ф/С) Укрывательство преступника или следов преступления|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 17.8 (Р) Грубое оскорбление человека в присутствии представителя власти|до 10 месяцев лишения свободы (1 звезда)|1
УК РО|Статья 17.9 (Ф/Р/С) Незаконная помеха задержанию или процессуальным действиям|до 50 месяцев лишения свободы|1|ст. 17.9 Помеха задержанию гражданином^до 40 месяцев с созданием записи о судимости (4 звезды)~ст. 17.10 Помеха задержанию сотрудником госструктур^до 50 месяцев с созданием записи о судимости (5 звезд)
УК РО|Статья 17.11 (Ф/Р/С/В) Провокация сотрудников Армии / помеха на КПП|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 17.12 (Ф/Р/В) Помеха государственной колонне и перевозке материалов|до 50 месяцев лишения свободы|1|ст. 17.12 Помеха колонне государственных структур^до 30 месяцев лишения свободы (3 звезды)~ст. 17.12.1 Помеха госструктурам при перевозке материалов^50 месяцев с созданием записи о судимости (5 звезд)
УК РО|Статья 17.13 (Ф/Р) Побег или сопротивление при аресте / задержании|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 17.14 (Р) Браконьерство / отлов редких видов животных и растений|до 30 месяцев лишения свободы (3 звезды)|0
    )
    LoadData(u8)

    p1 =
    (
ПК РО|Глава I. Статья 1. Следственные действия и поводы к проверке|Обязанность инициировать процессуальную проверку при наличии законных поводов|0|п. а) Непосредственный очевидец^Сотрудник стал непосредственным очевидцем правонарушения~п. б) Сообщение потерпевшего или очевидца^Потерпевший или очевидец сообщил о правонарушении~п. в) Обнаружение следов^Обнаружены явные следы правонарушения~п. г) Заявление гражданина^По факту принятого и зарегистрированного заявления
ПК РО|Глава I. Статья 2. Принципы расследования|Обязанность соблюдать законные принципы при расследовании|0|Адекватность^Действовать профессионально, без превышения полномочий, разобраться до умозаключений~Безотлагательность^Отреагировать на правонарушение и начать действовать без промедлений
ПК РО|Глава I. Статья 3. Передача дела уполномоченному сотруднику|Передача подозреваемого и изложение всех известных обстоятельств|0
ПК РО|Глава I. Статья 4. Письменная отчетность и упрощенный порядок|Форма фиксации материалов дела и видеозаписи|0|ч. 1 Письменная отчетность^Дело ведется с отчетностью при передаче в суд, СК или прокуратуру~ч. 2 Упрощенный порядок на месте^Без отдельного дела; обязательная видеофиксация не менее 48 часов
ПК РО|Глава I. Статья 5. Перечень следственных действий (п. а - о)|Исчерпывающий перечень следственных действий государственного сотрудника|0|п. а) Возбуждение дела / принятие проверки^Постановление следователя при наличии признаков преступления~п. б) Допрос^Свидетелей, потерпевших, подозреваемого, экспертов~п. в) Осмотр^Оценка и фиксация состояния и свойств материальных объектов~п. г) Освидетельствование^Экспертиза технического или биологического объекта~п. д) Следственный эксперимент^Воспроизведение опытным путем действий и обстановки~п. е) Обыск^Обследование помещений либо лиц в целях обнаружения предметов~п. ж) Выемка^Принудительное изъятие имеющих значение предметов и документов~п. з) ОРМ^Оперативно-розыскные мероприятия уполномоченных органов~п. и) Задержание^Кратковременное ограничение свободы на момент расследования~п. о) Рейд^Оцепление объекта на основании судебного акта или прокурора
ПК РО|Глава I. Статья 6.1. Оперативно-розыскные мероприятия (ОРМ)|Перечень оперативно-розыскных мероприятий|0|п. а - в) Опрос, наведение справок, сборы образцов^Первоначальный сбор ориентирующей информации~п. г) Контрольная закупка^Проводится оперативными подразделениями по закону~п. е - ж) Наблюдение и обследование помещений/ТС^Сбор данных в пределах установленной компетенции~п. и - к) Оперативное внедрение и эксперимент^Проводятся уполномоченными оперативниками~п. м) Объявление ориентировки^Применяется по решению суда или уголовному делу
ПК РО|Глава I. Статья 6.3. Применение средств ограничения подвижности (наручников)|Применение наручников для задержания, привода; процессуальный час|0
ПК РО|Глава I. Статья 7.1. Виды процессуальных действий|Действия, непосредственно затрагивающие права граждан|0|п. а) Досмотр личный и ТС^Проводится исключительно с устного или письменного согласия лица~п. б) Обыск личный и ТС^Обследование без согласия при наличии законных оснований~п. в - г) Задержание и арест^Меры ограничения свободы по закону~п. д - е) Штрафы и изъятие лицензий^Применение административных и специальных санкций~п. ё) Сила, спецсредства и наручники^Меры физического принуждения~п. ж) Устные требования в рупор/связь^Предъявление обязательных распоряжений
ПК РО|Глава I. Статья 8. Рейд (основание, оцепление объекта)|Проводится на основании судебного акта или постановления прокурора|0
ПК РО|Глава I. Статья 10. Подследственность СК, ФСБ, Прокуратуры|Материалы передаются по подследственности без необоснованной задержки|0|ч. 1 Исключительная подследственность СК и ФСБ^Предварительное расследование по федеральным законам~ч. 2 Полномочия прокуратуры^Вправе самостоятельно рассматривать любые уголовные материалы~ч. 3 Передача материалов^Передаются по подследственности без задержек~ч. 4 Неотложные действия^Пресечение преступления, защита жизни, первичный обыск и задержание
ПК РО|Глава I. Статья 13. Срок предварительного расследования|Обычный срок до 96 часов; продление до 7 дней; далее через суд|0|ч. 1 Обычный срок расследования^До 96 часов с момента возбуждения уголовного дела~ч. 2 Продление руководством следствия^Мотивированное продление до семи календарных дней~ч. 3 Продление через суд^В исключительных случаях по судебному ходатайству
ПК РО|Глава II. Статья 1. Задержание подозреваемого (основания п. а - ж)|Ограничение свободы до 1 часа для сбора доказательств во внесудебном порядке|1|п. а) Застигнут на месте^В момент совершения или непосредственно после совершения деяния~п. б) Явные следы^Следы на одежде, теле, при себе или в жилище лица~п. в) Показания свидетелей^Три и более свидетелей прямо указывают на лицо~п. г) Фото-видеофиксация^Наличие объективных фото- или видеоматериалов правонарушения~п. д) Акт уполномоченного лица^Судебный акт или прокурорская санкция на задержание~п. е) Розыск или ориентировка^Ориентировка на ТС или лицо, нахождение в базе розыска~п. ж) Угроза жизни или неадекватность^Непосредственная угроза окружающим или сильное опьянение с нарушением
ПК РО|Глава II. Статья 1.1. Процедура установки личности (отказ от документов / маска)|Порядок действий при сокрытии личности или отсутствии документов|1|п. а) Наручники^Надеть наручники на лицо (если применяются)~п. б) Разъяснение основания^Разъяснить лицу законное основание установления личности~п. в) Проверка баз и документов^Использование баз данных и досмотр документов задержанного~п. г) Фоторобот^Сверить лицо задержанного с ориентировкой и фотороботом~п. д) Личный обыск^При обнаружении нелегала — переход к процессу задержания
ПК РО|Глава II. Статья 2. Порядок задержания лица (обязательные пункты)|Строгая последовательность процессуальных действий сотрудника|1|1. Наручники^Надеть наручники на подозреваемого (если применяются)~2. Опознавательный знак^Предъявить нашивку, бейдж, жетон или служебное удостоверение~3. Первичный обыск и личность^Поиск документов, проверка розыска и принадлежности к госорганам~4. Временная выемка опасного^Изъятие оружия, боеприпасов, ножей, наркотиков, взрывчатки на время процесса~5. Учет розыска^Внесение данных о розыске по законным основаниям~6. Разъяснение статей^Огласить основания задержания и статьи с кратким разъяснением~7. Разъяснение прав (Миранда)^Зачитать процессуальные права в порядке ст. 6 гл. II ПК РО~8. Доставление в ИВС/Суд^Доставка задержанного для процессуальных действий или ареста~9. Экспертиза (при необходимости)^Экспертиза технического или биологического объекта~10. Допрос (при необходимости)^Допрос подозреваемого с обязательным участием адвоката при запросе~11. Вызов прокурора для гос. служащих^Вызов прокурора и СК при задержании государственного служащего
ПК РО|Глава II. Статья 2.7.1. Передача задержанного по подследственности СК или ФСБ|Порядок передачи при совершении преступлений юрисдикции СК/ФСБ|0|ч. 1 Запрет разрешать дело сотрудником полиции^Обязанность организовать передачу уполномоченному следствию~ч. 2 Место ожидания^Доставление в ИВС или служебное помещение для передачи~ч. 3 Вызов сотрудника^Направление межведомственного вызова уполномоченному лицу~ч. 4 Неотложные действия^Установление личности, первичный обыск, видеофиксация и выемка опасного~ч. 5 Передача материалов^Передача видеозаписи, улик, изъятых предметов и задержанного~ч. 6 Срок задержания^Срок исчисляется с момента первого ограничения свободы и не прерывается~ч. 7 Освобождение при неприбытии^Освобождение лица, если сотрудник СК/ФСБ не прибыл до истечения срока
ПК РО|Глава II. Статья 2.9. Упрощенное разрешение уголовного материала на месте|Лишение свободы до 5 лет по общей подследственности без уголовного дела|1|ч. 1 Условия применения^Общая подследственность, не гос. служащий, без обязательного суда~ч. 2 Делопроизводство не ведется^Основа — достаточные доказательства и видеофиксация 48 часов~ч. 3 Проверка доказательств и адвокат^Проверка оправдывающих данных и обеспечение права на защиту~ч. 4 Мера наказания^Лишение свободы до 5 лет (за искл. оскорбления по ст. 17.3 УК при процессе)~ч. 5 Запрет штрафов полицией^Уголовный штраф и лишение должностей полицией в упрощенном порядке не назначаются~ч. 6 Оглашение решения^Объявление статей, назначенного срока и права на обжалование под видео~ч. 9 Ограничение ФСБ^Сотрудник ФСБ не вправе назначать или оформлять уголовный штраф
ПК РО|Глава II. Статья 3. Вызов адвоката на задержание|Сроки и порядок реализации права на квалифицированную юридическую помощь|1|ст. 3.1 Запрос гос. адвоката^Ожидание ответа по рации 3 минуты; при молчании — продолжение процесса~ст. 3.2 Ожидание приезда адвоката^При подтверждении вызова процессуальный час приостанавливается до 10 минут~ст. 3.3 Частный адвокат^Приостановка процессуального часа на приезд не более 10 минут~ст. 3.4 Осознанный отказ^Право на защиту считается реализованным при осознанном отказе лица
ПК РО|Глава II. Статья 4. Задержание государственного служащего|Обязательное участие прокуратуры и Следственного комитета|1|ст. 4.1 Проверка улик прокурором^Прокурор лично изучает видеозаписи, состав и принимает решение~ст. 4.2 Ожидание прибытия прокурора^Приостановка проц. часа до прибытия прокурора не более 15 минут (далее — свободен)~ст. 4.3 Неподтверждение вызова за 15 минут^Задержанный служащий освобождается от удержания; материалы передаются в прокуратуру~ст. 4.4 Решения прокурора^Освобождение, штраф, арест, изменение статей либо передача в СК/ФСБ~ст. 4.8 Увольнение после задержания^Не отменяет обязательную специальную процедуру прокурора~ст. 4.9 Решающее слово прокурора^Окончательное решение выносит сотрудник прокуратуры
ПК РО|Глава II. Статья 7. Основания освобождения подозреваемого|Перечень оснований для немедленного прекращения ограничения свободы|1|п. а) Не подтвердилось^Не подтвердилось подозрение в совершении правонарушения~п. б) Санкция исполнена^Штраф оплачен, оснований для дальнейшего удержания нет~п. в) Нарушение ст. 1 гл. II^Задержание проведено без законных оснований~п. г) Истек 1 час^Истек процессуальный час без вынесения процессуального решения~п. д) Неприкосновенность^Лицо обладает неприкосновенностью (кроме прямой угрозы жизни)~п. е) Недопустимые улики^Отсутствие допустимых доказательств либо признание их незаконными
ПК РО|Глава II. Статья 7.1. Основания приостановления процессуального часа|Исчерпывающий перечень законных оснований паузы процессуального срока|1|п. а) Допрос^Проведение официального допроса подозреваемого~п. б) Адвокат^Ожидание ответа/приезда и конфиденциальная беседа до 10 минут~п. в) Прокурор^Ожидание приезда и разбирательство по гос. служащему до 15 минут~п. г) Дополнительная проверка^Проведение проверки обстоятельств, но не более чем на 20 минут~п. д) Ожидание СК / ФСБ^Доставление и ожидание следователя СК/ФСБ совокупно не более 20 минут~п. е) Судебная проверка^Незамедлительная проверка судьей — на все фактическое время
ПК РО|Глава II. Статья 8. Субъекты задержания (круг лиц с правом присутствия)|Лица, законно допущенные к процессуальным действиям задержания|0|п. а) Сотрудник правопорядка^Сотрудник(-и) при исполнении, производящий задержание или арест~п. б) Задержанный^Лицо, в отношении которого проводятся процессуальные действия~п. в) Адвокат^Защитник (и до 3 младших адвокатов при основном адвокате)~п. г) Прокурор^Сотрудник прокуратуры для надзора или решения по гос. служащему~п. д - е) Наблюдатели ФСБ и СК^По одному сотруднику управления ФСБ и Следственного комитета~п. ё) Руководство Правительства^Премьер-министр, Вице-премьер-министр и их охрана
ПК РО|Глава II. Статья 9. Права задерживаемого лица|Гарантированные законом права подозреваемого гражданина|1|п. а) Телефонный звонок^Один разговор до 3 минут в присутствии сотрудника~п. б) Адвокат и беседа наедине^Конфиденциальная встреча с защитником до 10 минут наедине~п. в) Молчание^Право не свидетельствовать против себя и близких родственников~п. г) Знание оснований^Право знать основания задержания и инкриминируемые статьи~п. д) Обжалование^Право заявлять ходатайства и обжаловать действия сотрудников
ПК РО|Глава II. Статья 10. Обязанности сотрудника при задержании|Обязательные требования к сотруднику, ограничивающему свободу|1|п. а) Видеофиксация 48 часов^Вести и хранить непрерывную видеозапись оснований и процесса не менее 48 часов~п. б) Предоставление адвокату^Предоставить адвокату видеозапись каждого отдельного эпизода~п. в) Предоставить прокурору^Обязанность показать видеозапись прокурору по его требованию~п. д) Вызов прокурора и СК^Обязательный вызов при задержании государственного служащего
    )
    LoadData(p1)

    p2 =
    (
ПК РО|Глава V. Статья 3. Обыск транспортного средства без судебного ордера|Законные основания для досмотра и обыска автомобиля|1|1) Погоня и таран^Попытка водителя скрыться от требования об остановке с принудительной остановкой~2) Ориентировка^Действующая ориентировка на ТС либо нахождение в нем разыскиваемого лица~3) Запрещенные предметы^Обнаружение у водителя или пассажиров оружия, боеприпасов или наркотиков~4) Режимный объект^Нахождение ТС на охраняемой или режимной территории без разрешения~5) Следы преступления^Наличие видимых следов преступления или прямых оснований для обыска
ПК РО|Глава VII. Статья 1. Обязательная видеофиксация процессуальных действий|Перечень процессуальных действий с непрерывной видеозаписью|1|1) Задержание^Основания задержания и весь ход процесса задержания~2) Арест^Помещение лица под административный или уголовный арест в ИВС~3) Обыски^Личный обыск и обыск ТС без согласия лица~4) Сила и оружие^Применение физической силы, специальных средств или огнестрельного оружия~5) Изъятия^Принудительное изъятие лицензий, разрешений или имущества
ПК РО|Глава VII. Статья 3. Срок хранения видеофиксации (не менее 48 часов)|Сроки и условия сохранения видеозаписей сотрудником|1|ч. 1 Минимальный срок 48 часов^Запись хранится не менее 48 часов с момента окончания действия~ч. 2 Продление при жалобе или суде^Запись сохраняется до окончания суда, следствия или проверки жалобы
ПК РО|Глава XI. Статья 2. Общие положения об устном законном требовании|Обязательные критерии законного распоряжения сотрудника|1|ч. 1 Обязательность исполнения^Требование обязательно для исполнения гражданами и должностными лицами~ч. 2 Форма требования^Однозначное, конкретное, законное, этичное, в повелительном наклонении~ч. 3 Законные цели^Процессуальные действия, проверка документов, пресечение правонарушений, порядок
ПК РО|Глава XI. Статья 4. Основания применения силы и спецсредств|Правила применения приемов борьбы, дубинок, тазеров и наручников|1|ч. 1 Оправданность и соразмерность^Применение только при необходимости с минимизацией вреда~ч. 4 Несмертельная сила^Приемы, дубинки, тазеры при умеренной угрозе или физическом сопротивлении~Прим. 1 Запрет силы при обычном штрафе^Запрет силы при выписывании штрафа КоАП без сопротивления лица~Прим. 2 Наручники при УК и адм. аресте^Право надеть наручники при признаках преступления или административного ареста
ПК РО|Глава XI. Статья 5. Особенности применения смертельной силы|Крайние основания для открытия огня на поражение|1|ч. 1 Защита жизни^Исключительно при непосредственной угрозе смерти или тяжкого вреда здоровью~ч. 3 Случаи применения^Отражение нападения, освобождение заложников, побег опасного преступника~ч. 4 Запрет предупредительных выстрелов^Предупредительные выстрелы категорически запрещены!~ч. 5 Побег^Бегство само по себе не оправдывает стрельбу без смертельной угрозы
ПК РО|Глава XI. Статья 6. Остановка ТС и применение силы в мегафон|Основания остановки и принудительного блокирования автомобиля|1|ч. 4 Требования в рупор^Требование об остановке оглашается через мегафон~ч. 5 Таран после 1-го требования^При неповиновении первому требованию при сирене и маячках патруля~ч. 6 Остановка после 3-х требований^При неповиновении 3 требованиям мегафона с объявлением ведомства~ч. 7 Немедленный таран/огонь^Тяжкое преступление, скрылся от погони, смертельная езда, проезд за оцепление~ч. 9 Способы остановки^Огнестрельное оружие по колесам, тазер, таран и блокирование ТС~ч. 10 Силовое извлечение^Извлечение силой при отказе добровольно покинуть автомобиль
    )
    LoadData(p2)

    pd1 =
    (
ПДД РО|Пункт 1. Общие положения и основные термины ПДД|Базовые правила дорожного движения на территории РО|0|п. 1.3 Правостороннее движение^Движение на всей территории РО является правосторонним~п. 1.4 Термины^Обочина, полоса, перекресток, обгон, опережение, остановка, стоянка~п. 1.5 Взаимная безопасность^Запрет создания опасности и необоснованных помех
ПДД РО|Пункт 2. Общие обязанности водителя ТС|Перечень обязанностей лица, управляющего транспортом|0|п. 2.1 Права и СТС^Обязанность иметь и предъявлять В/У и документы на ТС по требованию ГИБДД~п. 2.2 Регистрационные знаки^Управление ТС только с установленными гос. номерами~п. 2.3 - 2.4 Остановка и выход^Остановка по требованию ГИБДД и выход из авто при законном требовании~п. 2.5 Запреты на руль^Запрет управления в опьянении, утомлении, без прав или при неисправности~п. 2.7 Освидетельствование^Обязанность пройти проверку на состояние опьянения~п. 2.8 Телефон без гарнитуры^Запрет удержания средств связи рукой во время движения
ПДД РО|Пункт 3. Обязанности водителя при совершении ДТП|Порядок действий при дорожно-транспортном происшествии|0|п. 3.1 Остановка и аварийка^Немедленно остановиться, включить аварийную сигнализацию и выставить знак~п. 3.2 Сохранение следов^Запрет перемещения предметов и авто до фиксации обстоятельств~п. 3.3 Пострадавшие лица^Оказание первой помощи, вызов скорой помощи и экипажа ГИБДД~п. 3.6 Оставление места ДТП^Категорический запрет оставления места происшествия (ст. 48 КоАП)~п. 3.7 Алкоголь после ДТП^Запрет употребления спиртного и веществ до освидетельствования
ПДД РО|Пункт 4. Применение специальных сигналов (мигалки и сирена)|Правила использования маячков и порядок предоставления приоритета|0|п. 4.1 Маячки синий/красный^Право отступать от правил только при одновременной сирене и маячках~п. 4.3 Обязанность уступить дорогу^Водители обязаны уступить дорогу спецтранспорту с включенной сиреной~п. 4.5 Желтые и оранжевые маячки^Преимущества не дают; используются для эвакуаторов и дорожных служб
ПДД РО|Пункт 8. Скорость движения и безопасная дистанция|Скоростные ограничения на дорогах РО|0|п. 8.2 Лимиты скорости^Город 60 км/ч | Трасса 90 км/ч | Магистраль 110 км/ч | Буксир 50 км/ч~п. 8.4 Существенное превышение^Превышение более чем на 20 км/ч наказуемо по ст. 52.1 КоАП~п. 8.5 Запреты при езде^Запрет резкого торможения и беспричинной чрезмерно медленной езды
ПДД РО|Пункт 9. Обгон и опережение|Правила безопасного опережения и выезда на встречную полосу|0|п. 9.2 Препятствие обгону^Запрет водителю обгоняемого автомобиля ускоряться и мешать обгону~п. 9.3 Места запрета обгона^Пешеходный переход, ж/д переезд, тоннель, мост, опасный поворот, знак
ПДД РО|Пункт 17. Правила остановки и стоянки ТС|Места и порядок разрешенной парковки транспорта|0|п. 17.1 Правая сторона дороги^Остановка справа у края проезжей части либо на обочине параллельно бордюру~п. 17.4 Места запрета остановки^Пешеходный переход, переезд, тоннель, мост, перекресток, остановка маршруток~п. 17.6 Эвакуация ТС^Перемещение ТС на штрафстоянку при создании существенной помехи
    )
    LoadData(pd1)

    pl1 =
    (
ФЗ О Полиции|Статья 1. Полиция РО в системе МВД РО|Защита жизни, здоровья, прав, свобод, борьба с преступностью и охрана порядка|0
ФЗ О Полиции|Статья 3. Основные задачи полиции|12 основных направлений служебной деятельности полиции|0
ФЗ О Полиции|Статья 7. Государственная инспекция безопасности дорожного движения (ГИБДД)|Специализированная служба в области безопасности движения МВД|0
ФЗ О Полиции|Статья 30. Представление сотрудника полиции|Обязанность назвать звание, фамилию и предъявить служебное удостоверение|0
ФЗ О Полиции|Статья 32. Законное требование сотрудника полиции|Обязательно для граждан; конкретное, этичное, в приказном наклонении|0
ФЗ О Полиции|Статья 33. Проверка документов и установление личности|Законные основания для требования документов, удостоверяющих личность|0|п. 1 Подозрение в правонарушении^Наличие достаточных оснований подозревать лицо в деянии~п. 2 Розыск и ориентировка^Нахождение в розыске либо совпадение с имеющейся ориентировкой~п. 3 Процессуальные действия^Необходимость установить личность задержанного, потерпевшего, свидетеля~п. 4 Пропускной режим^Попытка прохода на охраняемую территорию с установленным режимом
ФЗ О Полиции|Статья 38. Обыск транспортного средства|Основания обыска ТС сотрудниками полиции без судебного ордера|0
ФЗ О Полиции|Статья 48. Применение физической силы|Случаи применения боевых приемов и физического воздействия|0|п. 1 Пресечение нападения^Отражение нападения на граждан или сотрудников полиции~п. 2 Сопротивление^Преодоление физического сопротивления нарушителя~п. 3 Задержание и побег^Задержание скрывающегося лица и предотвращение побега
ФЗ О Полиции|Статья 50. Применение наручников и средств ограничения подвижности|Задержание, арест, конвой, риск нападения, побега или уничтожения улик|0
ФЗ О Полиции|Статья 51. Применение огнестрельного оружия|Крайняя мера при угрозе жизни; категорический запрет предупредительных выстрелов|0
ФЗ О Полиции|Статья 63. Служебное удостоверение и нагрудный знак|Обязательное ношение нагрудного знака на форме для визуального контроля|0
Устав ГИБДД|Статья 1. Государственная инспекция безопасности дорожного движения|Государственный орган исполнительной власти в сфере безопасности движения|0
Устав ГИБДД|Статья 8. Структурные подразделения ГИБДД|4 специализированных подразделения: ДПС, ЦПП, УСБ, Спецбатальон (СБ)|0|ДПС^Дорожно-патрульная служба: патрули, посты, оформление ДТП, погони~ЦПП^Центр подготовки персонала: Академия, обучение, прием экзаменов~УСБ^Управление собственной безопасности: надзор, дисциплина, проверки~СБ^Специальный батальон: силовая поддержка, сопровождение, спецрейды
Устав ГИБДД|Статья 11. Общие обязанности сотрудника ГИБДД|Соблюдать законы, субординацию, беречь служебное ТС, оружие и спецсредства|0
Устав ГИБДД|Статья 11.6. Обязанность прибытия на построение личного состава|Неявка в строй или самовольный уход без разрешения влечет взыскание|0
Устав ГИБДД|Статья 15. Порядок служебного обращения|Официальная форма: «Товарищ [звание]»; общение с гражданами строго на «Вы»|0
Устав ГИБДД|Статья 17. Основные запреты сотрудникам|Запрет взяток, покровительства, алкоголя, прогулов и обмана руководства|0
Устав ГИБДД|Статья 19. Рабочее время сотрудников|Дневная смена: 10:00 - 23:00 | Ночная смена: 23:00 - 07:00|0
Устав ГИБДД|Статья 26. Виды дисциплинарных взысканий|Строгий выговор (система 0/3), переаттестация, увольнение из органов|0
    )
    LoadData(pl1)

    additions1 =
    (
КоАП РО|Статья 1.1. Законодательство об административных правонарушениях|Состоит из настоящего Кодекса и федеральных законов|0|1. Состав законодательства^Кодекс и федеральные законы, прямо предусматривающие административную ответственность~2. Запрет подзаконных актов^Подзаконные и внутренние нормативные акты не могут устанавливать состав административного правонарушения или наказание
КоАП РО|Статья 1.2. Задачи законодательства об административных правонарушениях|Защита личности, прав и свобод человека и гражданина, собственности, общественного порядка и безопасности, здоровья населения, окружающей среды, законных экономических и трудовых интересов, предупреждение правонарушений|0
КоАП РО|Статья 1.3. Равенство перед законом|Лица, совершившие административные правонарушения, равны перед законом|0|1. Равенство^Все равны перед законом~2. Запрет необоснованных различий^Должностное положение и иные обстоятельства вне состава не могут быть основанием для необоснованного различия в ответственности
КоАП РО|Статья 1.4. Презумпция невиновности|Ответственность только при установленной вине; неустранимые сомнения толкуются в пользу лица|0|1. Вина как условие^Ответственность только за правонарушение, по которому установлена вина~2. Невиновность до доказательства^Вина устанавливается достаточными и допустимыми доказательствами в предусмотренном законом порядке~3. Нет обязанности доказывать^Лицо не обязано доказывать невиновность; неустранимые сомнения толкуются в его пользу
КоАП РО|Статья 1.5. Законность административного принуждения|Наказание и меры обеспечения — только на основаниях и в порядке, установленных законом|0|1. Законность^Наказание и меры обеспечения применяются только по закону~2. Пределы компетенции^Должностное лицо действует в пределах компетенции и выбирает соразмерную меру
КоАП РО|Статья 1.6. Действие закона во времени|Ответственность определяется законом, действовавшим во время совершения правонарушения|0|1. Закон времени^Ответственность определяется законом, действовавшим во время правонарушения~2. Обратная сила^Закон, отменяющий ответственность, смягчающий наказание или иным образом улучшающий положение лица, имеет обратную силу
КоАП РО|Статья 1.7. Возраст административной ответственности|Административной ответственности подлежит физическое лицо, достигшее шестнадцатилетнего возраста ко времени совершения правонарушения|0
КоАП РО|Статья 1.8. Ответственность юридических лиц|Юридическое лицо виновно, если имелась реальная возможность соблюдать установленное требование, однако не были приняты разумные и необходимые меры|0
КоАП РО|Статья 2.1. Понятие административного правонарушения|Противоправное и виновное действие или бездействие физического либо юридического лица, за которое предусмотрена административная ответственность и которое не образует состава преступления|0
КоАП РО|Статья 2.2. Формы вины|Умысел или неосторожность|0|1. Умысел^Лицо осознавало противоправный характер поведения и желало его совершить либо сознательно допускало последствия~2. Неосторожность^Лицо предвидело возможность вредных последствий, но без достаточных оснований рассчитывало их предотвратить, либо не предвидело, хотя должно было и могло предвидеть
КоАП РО|Статья 2.3. Разграничение с преступлением|Одно деяние не может одновременно повлечь уголовное и административное наказание по совпадающим фактическим обстоятельствам|0|1. Запрет двойной ответственности^Одно деяние — либо уголовное, либо административное наказание~2. Передача по подследственности^При выявлении признаков преступления административное производство прекращается, материал передается по подследственности
КоАП РО|Статья 2.4. Крайняя необходимость|Не является правонарушением причинение меньшего вреда охраняемым законом интересам для устранения непосредственно угрожающей опасности, если она не могла быть устранена иными средствами|0
КоАП РО|Статья 2.5. Правомерное осуществление полномочий|Не является правонарушением действие, совершенное в пределах прямо предоставленных законом полномочий и с соблюдением установленной процедуры|0
КоАП РО|Статья 2.6. Малозначительность|При малозначительности правонарушения судья, прокурор, орган или должностное лицо вправе освободить лицо от административной ответственности и ограничиться устным замечанием|0
КоАП РО|Статья 3.1. Цели административного наказания|Восстановление нарушенного порядка и предупреждение новых правонарушений|0
КоАП РО|Статья 3.2. Виды административных наказаний|Предупреждение; административный штраф; административный арест; конфискация орудия или предмета правонарушения; лишение специального права; административное приостановление деятельности|0
КоАП РО|Статья 3.3. Предупреждение|Официальное порицание, преимущественно при впервые совершенном малозначительном правонарушении|0
КоАП РО|Статья 3.4. Административный штраф|Денежное взыскание в рублях в размере, установленном Особенной частью|0|1. Понятие^Штраф — денежное взыскание в рублях~2. Размер в диапазоне^Определяется с учетом тяжести деяния, имущественного положения, смягчающих и отягчающих обстоятельств
КоАП РО|Статья 3.5. Административный арест|Кратковременная изоляция лица, применяется только когда прямо предусмотрена санкцией статьи|0|1. Понятие^Кратковременная изоляция; только по санкции статьи~2. Внесудебный порядок до 10 суток^Сотрудник правоохранительного органа вправе назначить арест до 10 суток, если статья допускает такой порядок~3. Свыше 10 суток — судья^Арест свыше 10 суток назначает судья; прокурор — в случаях, отнесенных законом к его компетенции~4. Максимум 15 суток^По одному материалу или совокупности одновременно рассматриваемых правонарушений
КоАП РО|Статья 3.6. Лишение специального права|Лишение права управления ТС, права на владение оружием либо иного специального права назначается судьей, если федеральным законом прямо не установлено иное|0
    )
    LoadData(additions1)

    additions2 =
    (
КоАП РО|Статья 3.7. Конфискация|Принудительное обращение в собственность РО орудия или предмета административного правонарушения в случаях, предусмотренных законом|0
КоАП РО|Статья 3.8. Административное приостановление деятельности|Временное прекращение деятельности организации, эксплуатации объекта или осуществления лицензируемого вида деятельности; назначается судьей на срок до семи календарных дней, если иной срок прямо не установлен законом|0
КоАП РО|Статья 4.1. Общие правила назначения наказания|Наказание в пределах санкции с учетом характера правонарушения, последствий, формы вины, личности виновного и его имущественного положения|0|1. Общие правила^В пределах санкции с учетом характера, последствий, формы вины, личности и имущественного положения~2. Ниже низшего предела^Прокурор или суд при исключительных смягчающих обстоятельствах вправе назначить наказание ниже низшего предела либо не применять дополнительное наказание
КоАП РО|Статья 4.2. Смягчающие обстоятельства|Раскаяние, добровольное прекращение нарушения, содействие установлению обстоятельств, предотвращение последствий, добровольное возмещение вреда, иные обстоятельства, существенно уменьшающие вредность деяния|0
КоАП РО|Статья 4.3. Отягчающие обстоятельства|Продолжение нарушения после законного требования прекратить его, повторность, совершение группой лиц, использование должностного положения, состояние опьянения, попытка скрыть доказательства, иные обстоятельства, существенно усугубляющие вредность деяния|0
КоАП РО|Статья 4.4. Несколько правонарушений|Наказание определяется за каждое, однако итоговое наказание должно оставаться соразмерным и не может обходить максимальные пределы Кодекса|0
КоАП РО|Статья 4.5. Давность привлечения|Лицо не подлежит административной ответственности, если со дня совершения правонарушения прошло более пяти календарных дней, если Особенной частью не установлен специальный срок|0|1. Срок давности^Более 5 календарных дней — не подлежит ответственности, если нет специального срока~2. Приостановление^На период официально ведущейся проверки, розыска лица или судебного производства
КоАП РО|Статья 5.1. Органы, рассматривающие административные материалы|Прокуратура, МВД, ГИБДД — по подсудности; исключительно прокурорские и исключительно судебные дела|0|1. Прокуратура РО^Возбуждает, рассматривает и разрешает любые дела, кроме исключительной подсудности суда~2. МВД РО^Рассматривает все дела, кроме исключительного прокурорского либо судебного порядка и главы IX Особенной части~3. ГИБДД^Рассматривает дела главы IX и главы 14; при исключительной подсудности направляет материал в суд~4. Исключительно прокурорские^Дела, для которых Особенной частью прямо установлен прокурорский порядок~5. Исключительно судебные^Дела и вопросы с прямым судебным порядком; лишение специального права и приостановление деятельности, если иное прямо не предусмотрено~6. Передача материала^Орган, выявивший неподведомственное правонарушение, пресекает его, сохраняет доказательства и передает материал уполномоченному органу, прокурору или суду
КоАП РО|Статья 5.2. Упрощенное рассмотрение на месте|Разрешение материала на месте без отдельного письменного дела, если обстоятельства очевидны, доказательств достаточно и статья не требует обязательного судебного рассмотрения|0|1. Условия^Обстоятельства очевидны, доказательств достаточно, статья не требует обязательного судебного рассмотрения~2. Что можно назначить^Предупреждение, административный штраф и административный арест в пределах части 2 статьи 6.5~3. Объявление лицу^Существо нарушения, статья, основные доказательства, наказание; разъяснение права на юрпомощь и обжалование
КоАП РО|Статья 5.3. Ответственность государственного служащего|Если правонарушение совершено госслужащим в связи с исполнением должностных обязанностей — наказание назначается прокурором либо судом в случаях, предусмотренных законом|0|1. Связь со службой^Наказание назначается прокурором либо судом в случаях, предусмотренных законом~2. Задержание госслужащего^При задержании и рассмотрении вопроса об административном аресте участие прокурора обязательно~3. Вне службы^Обычное правонарушение вне связи со службой и без административного ареста — на общих основаниях
КоАП РО|Статья 5.4. Судебная подсудность|Первая инстанция — мировой судья; апелляция — Кутузовский районный суд; кассация — Верховный Суд РО|0|1. Первая инстанция^Обязательное судебное рассмотрение — мировым судьей; допускается рассмотрение судом любой инстанции~2. Апелляция и кассация^Апелляция — Кутузовский районный суд; кассация — Верховный Суд РО
КоАП РО|Статья 5.5. Ведомственный пересмотр административного решения|Жалоба в орган, сотрудник которого назначил наказание; пересмотр вышестоящим должностным лицом|0|1. Право на жалобу^Лицо вправе обратиться с жалобой в орган, сотрудник которого назначил наказание~2. Содержание жалобы^Проверка законности, обоснованности, квалификации, доказательств и наказания~3. Истребование материалов^Вышестоящее лицо обязано истребовать все материалы, включая видеозаписи, документы, объяснения, сведения о свидетелях~4. Срок 24 часа^Материалы предоставляются не позднее 24 часов; при непредставлении или недостаточности решение отменяется, производство прекращается~5. Самостоятельное рассмотрение^Вышестоящее лицо не связано выводами сотрудника; пересмотр может быть заочным или с участием лиц~6. Срок 72 часа^Жалоба рассматривается не позднее 72 часов~7. Право на прокуратуру и суд^Ведомственный пересмотр не лишает права обратиться в прокуратуру РО либо в суд~8. Возврат штрафа^Если наказание отменено с прекращением и штраф уплачен — орган возвращает всю сумму~9. Компенсация за арест^При полном или частичном отбытии ареста — денежная компенсация~10. Оспаривание компенсации^Отказ или размер можно оспорить в суде~11. Перечень должностных лиц^Определяется руководством органа власти или профильным министерством
    )
    LoadData(additions2)

    additions3 =
    (
КоАП РО|Статья 5.6. Исполнение административного штрафа|Уклонение от штрафа — бездействие, отсутствие средств, прямой отказ; влечет ответственность по статье 10|0|1. Уклонение^Игнорирование штрафного тикета в течение 15 секунд; отсутствие средств; прямой отказ~2. Ответственность^Уклонение влечет ответственность по статье 10 настоящего Кодекса
КоАП РО|Статья 6.1. Уклонение от исполнения административного наказания|административный арест на 10 суток|0
КоАП РО|Статья 7.1. Мелкое хулиганство|5 000 – 15 000 руб. либо административный арест до 10 суток|1|1. Основной состав^5 000 – 15 000 руб. либо административный арест до 10 суток~2. Повторно / группой / со злостным отказом^15 000 – 30 000 руб. либо административный арест до 10 суток
КоАП РО|Статья 7.2. Нарушение порядка организации или проведения публичного мероприятия|10 000 – 25 000 руб.; при угрозе безопасности — 25 000 – 50 000 руб. либо арест до 10 суток|0|1. Основной состав^10 000 – 25 000 руб.~2. После требования прекратить^25 000 – 50 000 руб. либо административный арест до 10 суток
КоАП РО|Статья 7.3. Самовольное использование государственного имущества|20 000 – 50 000 руб. с возмещением ущерба|0
КоАП РО|Статья 7.4. Нахождение в состоянии опьянения, нарушающем общественный порядок|5 000 – 15 000 руб. либо административный арест до 5 суток|0
КоАП РО|Статья 7.5. Нарушение режима использования средств бронезащиты на охраняемом объекте|10 000 – 20 000 руб.; при сокрытии личности — 20 000 – 35 000 руб. либо арест до 7 суток|0|1. Основной состав^10 000 – 20 000 руб.~2. С сокрытием личности, попыткой пройти в служебную зону или отказом покинуть объект^20 000 – 35 000 руб. либо административный арест до 7 суток
КоАП РО|Статья 7.6. Азартные игры в неустановленном месте|10 000 – 30 000 руб.; организатору — 20 000 – 50 000 руб.|0
КоАП РО|Статья 7.7. Опасное открытое ношение или использование разрешенных предметов|15 000 – 30 000 руб.; повторно — 30 000 – 50 000 руб.|0
КоАП РО|Статья 7.8. Нецелевое расходование бюджетных средств|75 000 – 150 000 руб. с возмещением суммы|0
КоАП РО|Статья 7.9. Незаконное нахождение на частной территории|5 000 – 15 000 руб.; при повторе или преодолении ограждения — 15 000 – 30 000 руб. либо арест до 5 суток|0|1. Основной состав^5 000 – 15 000 руб.~2. Повторный отказ или проникновение с преодолением ограждения^15 000 – 30 000 руб. либо административный арест до 5 суток
КоАП РО|Статья 7.10. Незаконный оборот наркотических средств в незначительном размере (до 3 г)|20 000 – 40 000 руб. либо административный арест до 10 суток с обязательным изъятием вещества|1
КоАП РО|Статья 7.11. Причинение незначительного вреда здоровью, побои|15 000 – 30 000 руб. либо административный арест до 10 суток; по неосторожности — 10 000 – 20 000 руб.|1|1. Умышленное причинение боли или незначительного вреда^15 000 – 30 000 руб. либо административный арест до 10 суток~2. По неосторожности при грубом нарушении правил безопасности^10 000 – 20 000 руб.
КоАП РО|Статья 7.12. Нарушение режима чрезвычайного или военного положения|20 000 – 50 000 руб. либо административный арест до 10 суток с возможной конфискацией предмета|0
КоАП РО|Статья 7.13. Угроза причинением вреда, не образующая преступления|15 000 – 30 000 руб.|0
КоАП РО|Статья 7.14. Создание антисанитарной обстановки в общественном месте|5 000 – 15 000 руб.|0
КоАП РО|Статья 8.1. Оскорбление|10 000 – 20 000 руб.|1
КоАП РО|Статья 8.2. Дискриминация|гражданину 10 000 – 30 000 руб.; должностному лицу — 30 000 – 70 000 руб.|0
КоАП РО|Статья 8.3. Дискриминация в сфере труда|30 000 – 80 000 руб.|0
КоАП РО|Статья 8.4. Публичное унижение группы лиц|20 000 – 50 000 руб.|0
КоАП РО|Статья 8.5. Повреждение чужого имущества в незначительном размере|10 000 – 30 000 руб. с обязанностью возместить ущерб|1
КоАП РО|Статья 8.6. Воспрепятствование законной деятельности журналиста|15 000 – 35 000 руб.|0
КоАП РО|Статья 8.7. Неправомерное использование специальных средств должностным лицом|30 000 – 70 000 руб.|0
КоАП РО|Статья 8.8. Неисполнение законного письменного предписания или акта|20 000 – 50 000 руб.; должностному лицу — 50 000 – 100 000 руб.; организации — 100 000 – 250 000 руб.|0
КоАП РО|Статья 8.9. Неисполнение законного адвокатского запроса|должностному лицу 20 000 – 50 000 руб.; организации — 50 000 – 120 000 руб.|0
КоАП РО|Статья 8.10. Нарушение порядка доступа к общественно значимой информации|20 000 – 50 000 руб.|0
КоАП РО|Статья 8.11. Нарушение правил использования законно принадлежащего оружия|30 000 – 60 000 руб.; при угрозе или повторе — 40 000 – 80 000 руб. с лишением права на оружие до 30 дней|0|1. Основной состав^30 000 – 60 000 руб.~2. Создавшее реальную угрозу или повторно^40 000 – 80 000 руб. с лишением права на оружие до 30 дней
КоАП РО|Статья 9.1. Браконьерство|20 000 – 50 000 руб. с изъятием незаконно добытого ресурса; возможно лишение специального права до 30 дней|0
КоАП РО|Статья 9.2. Превышение установленной нормы добычи|10 000 – 30 000 руб. с изъятием добычи сверх нормы. Норма вылова рыбы — 25 кг|0
КоАП РО|Статья 10.1. Неуважение к суду|10 000 – 50 000 руб. либо административный арест до 10 суток|0
КоАП РО|Статья 10.2. Заведомо ложный вызов экстренной или государственной службы|10 000 – 25 000 руб.|0
КоАП РО|Статья 10.3. Заведомо ложное сообщение об административном правонарушении|15 000 – 30 000 руб.|0
КоАП РО|Статья 10.4. Воспрепятствование законной деятельности государственного служащего|15 000 – 35 000 руб. либо административный арест до 10 суток|0
КоАП РО|Статья 10.5. Нарушение установленного порядка поведения в государственном учреждении|10 000 – 25 000 руб.|0
КоАП РО|Статья 10.6. Нарушение порядка хранения государственного оружия и специальных средств сотрудником|30 000 – 70 000 руб. с обязательной передачей предметов по месту учета|0
    )
    LoadData(additions3)

    additions4 =
    (
КоАП РО|Статья 10.7. Нарушение правил предвыборной агитации и агитации по вопросам референдума|гражданину 15 000 – 30 000 руб.; должностному лицу — 30 000 – 70 000 руб.; организации — 100 000 – 200 000 руб.|0
КоАП РО|Статья 10.8. Ненадлежащее исполнение должностных обязанностей|20 000 – 60 000 руб.|0
КоАП РО|Статья 11.1. Исполнение государственной службы в состоянии наркотического опьянения|40 000 – 80 000 руб. + материал для дисциплинарной ответственности|0
КоАП РО|Статья 11.2. Воспрепятствование оказанию медицинской помощи|20 000 – 40 000 руб.; при продолжении — до 50 000 руб. либо административный арест до 10 суток|0
КоАП РО|Статья 11.3. Отказ государственного служащего в предоставлении медицинских справок|до 40 000 руб.|0
КоАП РО|Статья 11.4. Просроченные медицинские справки у государственного служащего|до 20 000 руб.|0
КоАП РО|Статья 11.5. Препятствие или отказ от проверки|50 000 – 100 000 руб.|0
КоАП РО|Статья 11.6. Нарушение санитарно-эпидемиологических правил|до 10 000 руб.|0
КоАП РО|Статья 12.1. Нарушение трудового законодательства|15 000 – 40 000 руб.; повторно — 30 000 – 70 000 руб.; незаконное увольнение — 30 000 – 80 000 руб.; дисциплинарное взыскание — 20 000 – 50 000 руб.; повторно — 50 000 – 100 000 руб.; нарушение права на отдых — 20 000 – 60 000 руб.; повторно — 40 000 – 90 000 руб.|0|1. Основной состав^15 000 – 40 000 руб.~2. Повторно^30 000 – 70 000 руб.~3. Незаконное увольнение или прекращение трудовых отношений^30 000 – 80 000 руб.~4. Наложение дисциплинарного взыскания без основания или с нарушением процедуры^20 000 – 50 000 руб.~5. Повторное совершение деяний по ч. 3 или 4^50 000 – 100 000 руб.~6. Нарушение права на отдых, оплату труда или компенсацию^20 000 – 60 000 руб.~7. Повторное совершение деяния по ч. 6^40 000 – 90 000 руб.
КоАП РО|Статья 12.2. Незаконные правила внутреннего трудового распорядка|100 000 – 250 000 руб. с обязанностью привести акт в соответствие с законом|0
КоАП РО|Статья 13.1. Незаконное предпринимательство, не образующее преступления|гражданину 30 000 – 80 000 руб.; должностному лицу — 50 000 – 120 000 руб.; организации — 100 000 – 250 000 руб. с возможным административным приостановлением деятельности|0
КоАП РО|Статья 13.2. Ненадлежащая реклама незаконной деятельности|50 000 – 150 000 руб.|0
КоАП РО|Статья 13.3. Нарушение обязательных условий лицензии|30 000 – 100 000 руб.; при повторном нарушении возможно приостановление лицензируемой деятельности до 7 календарных дней|0
КоАП РО|Статья 14.1. Управление транспортным средством без необходимого права или документов|20 000 – 40 000 руб. с отстранением от управления либо административный арест до 10 суток; непредъявление документов — 5 000 – 10 000 руб.|1|1. Управление без права^20 000 – 40 000 руб. с отстранением от управления либо административный арест до 10 суток~2. Непредъявление документов^5 000 – 10 000 руб.
КоАП РО|Статья 14.2. Управление транспортным средством в состоянии опьянения|50 000 – 100 000 руб. с лишением права управления транспортными средствами до 30 календарных дней|1
КоАП РО|Статья 14.3. Оставление места дорожно-транспортного происшествия|10 000 – 30 000 руб. либо лишение права управления транспортными средствами|1
КоАП РО|Статья 14.4. Опасное вождение и создание аварийной ситуации|20 000 – 50 000 руб.|1
КоАП РО|Статья 14.5. Непредоставление преимущества транспортному средству экстренной службы|15 000 – 30 000 руб.|1
КоАП РО|Статья 14.6. Нарушение правил государственной регистрации транспортного средства|10 000 – 25 000 руб.; подложный или чужой знак — 25 000 – 50 000 руб.|1|1. Без регистрации или знака^10 000 – 25 000 руб.~2. Подложный или чужой регистрационный знак^25 000 – 50 000 руб.
КоАП РО|Статья 14.7. Существенное превышение установленной скорости|500 – 5 000 руб.|1
КоАП РО|Статья 14.8. Проезд на запрещающий сигнал или движение по встречной полосе|2 000 – 7 000 руб.|1
КоАП РО|Статья 14.9. Нарушение правил остановки или стоянки|1 000 – 5 000 руб. с возможным перемещением транспортного средства|1
КоАП РО|Статья 14.10. Повторное грубое нарушение правил дорожного движения|20 000 – 40 000 руб. либо лишение права управления транспортными средствами|1
КоАП РО|Статья 14.11. Эксплуатация технически опасного транспортного средства|3 000 – 7 000 руб. с отстранением транспортного средства от эксплуатации до устранения нарушения|1
КоАП РО|Статья 14.12. Нарушение правил дорожного движения, повлекшее имущественный ущерб|15 000 – 40 000 руб. с обязанностью возместить причиненный ущерб|1
КоАП РО|Статья 14.13. Невыполнение обязанностей в связи с дорожно-транспортным происшествием|5 000 – 15 000 руб.; при пострадавших — 15 000 – 30 000 руб.; алкоголь после ДТП — 50 000 – 100 000 руб. с лишением права управления до 30 дней|1|1. Невыполнение обязанностей^5 000 – 15 000 руб.~2. Неоказание помощи или невызов медиков при пострадавших^15 000 – 30 000 руб.~3. Употребление алкоголя/наркотиков после ДТП до освидетельствования^50 000 – 100 000 руб. с лишением права управления до 30 дней
КоАП РО|Статья 14.14. Передача управления транспортным средством лицу, не имеющему права управления или находящемуся в состоянии опьянения|10 000 – 25 000 руб.; лицу в состоянии опьянения — 30 000 – 60 000 руб.|1|1. Лицу без права управления^10 000 – 25 000 руб.~2. Лицу в состоянии опьянения^30 000 – 60 000 руб.
КоАП РО|Статья 14.15. Нарушение правил пользования средствами связи при управлении транспортным средством|1 000 – 30 000 руб.|1
КоАП РО|Статья 14.16. Нарушение правил маневрирования|500 – 2 000 руб.; маневр в запрещенном месте — 500 – 3 000 руб.; создание аварийной ситуации — 3 000 – 10 000 руб.|1|1. Нарушение обязанности подать сигнал или уступить дорогу^500 – 2 000 руб.~2. Разворот, движение задним ходом или маневр в запрещенном месте^500 – 3 000 руб.~3. Создание реальной аварийной ситуации^3 000 – 10 000 руб.
    )
    LoadData(additions4)

    additions5 =
    (
КоАП РО|Статья 14.17. Нарушение правил проезда перекрестков и предоставления преимущества|5 000 – 15 000 руб.; выезд на перекресток при заторе — 5 000 – 15 000 руб.|1|1. Непредоставление преимущества на перекрестке^5 000 – 15 000 руб.~2. Выезд на перекресток при заторе с созданием препятствия^5 000 – 15 000 руб.
КоАП РО|Статья 14.18. Нарушение правил расположения транспортного средства на проезжей части|500 – 2 000 руб.; движение по тротуару или велодорожке — 1 000 – 4 000 руб.; угроза пешеходу — 20 000 – 40 000 руб.|1|1. Движение по обочине, разделительной полосе или занятие полосы с нарушением правил^500 – 2 000 руб.~2. Движение по тротуару, пешеходной или велосипедной дорожке^1 000 – 4 000 руб.~3. Создание реальной угрозы пешеходу или велосипедисту^20 000 – 40 000 руб.
КоАП РО|Статья 14.19. Нарушение правил обгона и опережения|2 000 – 6 000 руб.; обгон в запрещенном месте — 3 000 – 7 000 руб.|1|1. Обгон или опережение без обеспечения безопасности маневра^2 000 – 6 000 руб.~2. Обгон на пешеходном переходе, ж/д переезде, мосту, в тоннеле или на участке с ограниченной видимостью^3 000 – 7 000 руб.
КоАП РО|Статья 14.20. Нарушение правил движения через железнодорожные пути|5 000 – 10 000 руб.; выезд на переезд при запрещающем сигнале — 5 000 – 10 000 руб.|1|1. Пересечение вне переезда, движение по путям, разворот, задний ход или остановка на переезде^5 000 – 10 000 руб.~2. Выезд на переезд при запрещающем сигнале или очевидной угрозе столкновения^5 000 – 10 000 руб.
КоАП РО|Статья 14.21. Нарушение правил движения по автомагистрали|1 000 – 4 000 руб.; создание аварийной ситуации — 5 000 – 15 000 руб.|1|1. Необоснованная остановка, задний ход, разворот, выезд на разделительную полосу или иное запрещенное действие^1 000 – 4 000 руб.~2. Создание реальной аварийной ситуации^5 000 – 15 000 руб.
КоАП РО|Статья 14.22. Нарушение порядка использования специальных световых и звуковых сигналов|20 000 – 50 000 руб. с конфискацией устройства; уполномоченным водителем без необходимости — 30 000 – 70 000 руб.|1|1. Установка или использование без права^20 000 – 50 000 руб. с конфискацией незаконно используемого специального устройства~2. Использование уполномоченным водителем без необходимости или с грубым нарушением^30 000 – 70 000 руб.
КоАП РО|Статья 14.23. Нарушение правил пользования внешними световыми приборами и звуковыми сигналами|1 000 – 3 000 руб.|1
КоАП РО|Статья 14.24. Нарушение правил дорожного движения пешеходом|500 – 3 000 руб.; создание аварийной ситуации — 3 000 – 7 000 руб.|1|1. Нарушение обязательных требований^500 – 3 000 руб.~2. Создание аварийной ситуации^3 000 – 7 000 руб.
КоАП РО|Статья 14.25. Несоблюдение требований дорожных знаков и разметки|500 – 3 000 руб.; создание аварийной ситуации — 3 000 – 7 000 руб.|1|1. Несоблюдение требования знака, разметки, стоп-линии или иного средства организации движения^500 – 3 000 руб.~2. Создание реальной аварийной ситуации^3 000 – 7 000 руб.
КоАП РО|Статья 14.26. Непредоставление преимущества пешеходу, велосипедисту или маршрутному транспортному средству|2 000 – 6 000 руб.|1
КоАП РО|Статья 14.27. Нарушение правил буксировки, перевозки груза или пассажиров|5 000 – 15 000 руб.|0
КоАП РО|Статья 14.28. Воспрепятствование движению организованной транспортной колонны|10 000 – 25 000 руб.; продолжение нарушения или создание аварийной ситуации — 20 000 – 40 000 руб.|0|1. Вклинивание в колонну или создание препятствия^10 000 – 25 000 руб.~2. Продолжение нарушения или создание аварийной ситуации^20 000 – 40 000 руб.
УК РО|Статья 1. Уголовное законодательство РО|Состоит из настоящего Кодекса; новые законы подлежат включению в Кодекс; основывается на Конституции РО и международных нормах|0|ч. 1 Состав законодательства^Уголовное законодательство состоит из настоящего Кодекса; новые законы включаются в Кодекс~ч. 2 Основа^Кодекс основывается на Конституции РО и международных нормах
УК РО|Статья 1.1. Задачи Уголовного кодекса РО|Охрана прав и свобод, собственности, общественного порядка, окружающей среды, конституционного строя; предупреждение преступлений|0|ч. 1 Задачи^Охрана прав и свобод, собственности, порядка, безопасности, окружающей среды, конституционного строя~ч. 2 Основание и принципы^Кодекс устанавливает основание и принципы ответственности, определяет преступления и наказания
УК РО|Статья 1.2. Принцип законности|Преступность деяния определяется только УК РО; аналогия не допускается|0|ч. 1 Только Кодекс^Преступность, наказуемость и последствия определяются только настоящим Кодексом~ч. 2 Запрет аналогии^Применение уголовного закона по аналогии не допускается
УК РО|Статья 1.3. Принцип равенства граждан перед законом|Равенство независимо от пола, расы, национальности, языка, происхождения, имущественного и должностного положения|0
УК РО|Статья 1.4. Принцип вины|Ответственность только за деяния и последствия, в отношении которых установлена вина; объективное вменение не допускается|0|ч. 1 Личная вина^Ответственность только за те деяния и последствия, по которым установлена вина~ч. 2 Запрет объективного вменения^Ответственность за невиновное причинение вреда не допускается
УК РО|Статья 1.5. Принцип справедливости|Наказание должно соответствовать характеру и степени общественной опасности; никто не несет ответственность дважды|0|ч. 1 Соразмерность^Наказание соответствует характеру и степени опасности, обстоятельствам и личности виновного~ч. 2 Запрет двойной ответственности^Никто не может нести уголовную ответственность дважды за одно преступление
УК РО|Статья 1.6. Принцип гуманизма|Обеспечение безопасности человека; наказание не может причинять физические страдания или унижать достоинство|0|ч. 1 Безопасность человека^Уголовное законодательство обеспечивает безопасность человека~ч. 2 Запрет страданий и унижения^Наказание не может иметь целью причинение физических страданий или унижение достоинства
УК РО|Статья 1.7. Основание уголовной ответственности|Совершение деяния, содержащего все признаки состава преступления|0
    )
    LoadData(additions5)

    additions6 =
    (
УК РО|Статья 1.8. Состав преступления|Объект, субъект, объективная и субъективная стороны; материальные, формальные и усеченные составы|0|ч. 1 Элементы состава^Объект, субъект, объективная и субъективная стороны~ч. 2 Виды составов^Материальные, формальные, усеченные
УК РО|Статья 1.9. Судимость|Судимость — правовой статус после осуждения; уголовный штраф не влечет судимости; судимость запрещает госслужбу|0|ч. 1 Понятие судимости^Правовой статус лица после осуждения~ч. 2 Период судимости^Со дня назначения наказания до погашения или снятия~ч. 3 Уголовный штраф без судимости^Судимость при уголовном штрафе не возникает~ч. 4 Запрет государственной службы^Судимость запрещает нахождение на государственной службе
УК РО|Статья 1.10. Действие уголовного закона во времени|Преступность и наказуемость определяются законом, действовавшим во время совершения деяния|0|ч. 1 Закон времени^Преступность и наказуемость — по закону, действовавшему во время деяния~ч. 2 Время совершения^Время совершения деяния независимо от времени наступления последствий
УК РО|Статья 1.11. Обратная сила уголовного закона|Закон, устраняющий преступность, смягчающий наказание или улучшающий положение, имеет обратную силу|0|ч. 1 Обратная сила^Закон, устраняющий преступность, смягчающий или улучшающий положение, имеет обратную силу~ч. 2 Смягчение наказания^Если новый закон смягчает наказание, оно подлежит сокращению в пределах нового закона
УК РО|Статья 2. Понятие преступления|Виновно совершенное общественно опасное деяние, запрещенное УК под угрозой наказания; малозначительность исключается|0|ч. 1 Понятие^Виновно совершенное общественно опасное деяние, запрещенное Кодексом под угрозой наказания~ч. 2 Малозначительность^Не является преступлением действие (бездействие) в силу малозначительности
УК РО|Статья 2.1. Рецидив преступлений|Совершение умышленного преступления лицом, имеющим судимость за ранее совершенное умышленное преступление|0|ч. 1 Понятие^Совершение умышленного преступления лицом с судимостью за умышленное~ч. 2 Последствия^Более строгое наказание и иные последствия по закону
УК РО|Статья 2.2. Формы вины|Виновным признается лицо, совершившее деяние умышленно или по неосторожности|0|ч. 1 Формы вины^Умысел или неосторожность~ч. 2 Только неосторожность^Деяние по неосторожности — преступление, только если специально предусмотрено статьей
УК РО|Статья 2.3. Преступление, совершенное умышленно|Прямой умысел (желало последствий) и косвенный (сознательно допускало или относилось безразлично)|0|ч. 1 Умысел^Прямой или косвенный~ч. 2 Прямой умысел^Осознавало опасность, предвидело последствия и желало их~ч. 3 Косвенный умысел^Осознавало опасность, предвидело последствия, не желало, но сознательно допускало или относилось безразлично
УК РО|Статья 2.4. Преступление, совершенное по неосторожности|Легкомыслие (самонадеянный расчет) или небрежность (не предвидело, хотя должно было и могло)|0|ч. 1 Неосторожность^Легкомыслие или небрежность~ч. 2 Легкомыслие^Предвидело последствия, но самонадеянно рассчитывало их предотвратить~ч. 3 Небрежность^Не предвидело последствий, хотя должно было и могло их предвидеть
УК РО|Статья 2.5. Невиновное причинение вреда|Лицо не осознавало и не могло осознавать опасность либо не предвидело и не могло предотвратить последствия|0|ч. 1 Отсутствие осознания или предвидения^Лицо не осознавало и не могло осознавать опасность либо не предвидело и не могло предотвратить последствия~ч. 2 Невозможность предотвратить^Лицо предвидело последствия, но не могло их предотвратить из-за несоответствия психофизиологических качеств
УК РО|Статья 2.6. Ответственность за преступление с двумя формами вины|Тяжкие последствия причинены по неосторожности; в целом преступление признается умышленным|0
УК РО|Статья 3. Оконченное и неоконченное преступления|Оконченное — все признаки состава; неоконченное — приготовление и покушение|0|ч. 1 Оконченное^Все признаки состава преступления~ч. 2 Неоконченное^Приготовление и покушение~ч. 3 Ответственность^По статье за оконченное преступление со ссылкой на статью 3.1
УК РО|Статья 3.1. Приготовление к преступлению и покушение на преступление|Приготовление — создание условий; покушение — непосредственные действия, не доведенные до конца|0|ч. 1 Приготовление^Приискание, изготовление, приспособление средств, приискание соучастников, сговор или иное создание условий~ч. 2 Покушение^Умышленные действия (бездействие), непосредственно направленные на совершение преступления
УК РО|Статья 3.2. Добровольный отказ от преступления|Прекращение приготовления или действий освобождает от ответственности; иной состав — наказуем|0|ч. 1 Понятие^Прекращение приготовления или действий при осознании возможности довести преступление до конца~ч. 2 Освобождение^Лицо не подлежит ответственности, если добровольно и окончательно отказалось~ч. 3 Иной состав^Ответственность, если фактически совершенное деяние содержит иной состав~ч. 4 Организатор и подстрекатель^Не подлежат ответственности, если своевременно сообщили органам власти или иными мерами предотвратили доведение преступления~ч. 5 Смягчающее обстоятельство^Если меры не привели к предотвращению — могут быть признаны смягчающими
УК РО|Статья 3.3. Понятие соучастия в преступлении|Умышленное совместное участие двух или более лиц в совершении умышленного преступления|0
УК РО|Статья 3.4. Виды соучастников преступления|Исполнитель, организатор, подстрекатель, пособник|0|ч. 1 Виды^Исполнитель, организатор, подстрекатель, пособник~ч. 2 Исполнитель^Непосредственно совершившее преступление либо участвовавшее совместно с другими~ч. 3 Организатор^Организовавшее или руководившее исполнением, создавшее организованную группу или преступное сообщество~ч. 4 Подстрекатель^Склонившее другое лицо к совершению преступления~ч. 5 Пособник^Содействовавшее советами, указаниями, предоставлением информации, средств или устранением препятствий
    )
    LoadData(additions6)

    additions7 =
    (
УК РО|Статья 3.5. Ответственность соучастников преступления|Определяется характером и степенью фактического участия каждого|0|ч. 1 Индивидуализация^Ответственность определяется характером и степенью фактического участия~ч. 2 Соисполнители^Отвечают по статье Особенной части без ссылки на статью 3.4~ч. 3 Организатор, подстрекатель, пособник^Отвечают по статье со ссылкой на статью 3.4, кроме случаев соисполнительства~ч. 4 Лицо, не являющееся субъектом^Отвечает как организатор, подстрекатель или пособник~ч. 5 Недоведение до конца^Остальные соучастники отвечают за приготовление или покушение
УК РО|Статья 3.6. Совершение преступления группой лиц, по сговору, ОПГ, ОПС|Группа лиц, группа по предварительному сговору, организованная группа, преступное сообщество|0|ч. 1 Группа лиц^Два или более исполнителя без предварительного сговора~ч. 2 Группа по предварительному сговору^Лица, заранее договорившиеся о совместном совершении~ч. 3 Организованная группа^Устойчивая группа, заранее объединившаяся для совершения одного или нескольких преступлений~ч. 4 Преступное сообщество^Структурированная организованная группа или объединение групп под единым руководством~ч. 5 Организатор и руководитель^Отвечают за организацию и руководство по статьям 12.12, 12.5 и за все преступления, охваченные умыслом~ч. 6 Создание организованной группы^Ответственность за приготовление к преступлениям, для которых она создана~ч. 7 Более строгое наказание^Совершение группой влечет более строгое наказание
УК РО|Статья 3.7. Эксцесс исполнителя преступления|Совершение исполнителем преступления, не охваченного умыслом других соучастников|0
УК РО|Статья 4. Необходимая оборона|Защита от опасного для жизни насилия; самооборона в жилище правомерна; превышение пределов — умышленные действия, явно не соответствующие опасности|0|ч. 1 Оборона от опасного насилия^Защита при посягательстве, сопряженном с насилием, опасным для жизни, либо с непосредственной угрозой~ч. 2 Оборона от неопасного насилия^Правомерна, если не допущено превышения пределов~ч. 2.1 Неожиданность посягательства^Не является превышением, если лицо не могло объективно оценить степень и характер опасности~ч. 2.2 Защита жилища^Не является превышением при защите себя и семьи от насилия либо имущества от незаконно проникшего~ч. 3 Равные права^Распространяется на всех независимо от подготовки и служебного положения
УК РО|Статья 4.1. Причинение вреда при задержании лица, совершившего преступление|Правомерный вред для доставления органам власти при невозможности иных средств и без превышения мер|0|ч. 1 Правомерность^Не является преступлением, если иными средствами задержать не представлялось возможным и не допущено превышения~ч. 2 Превышение мер^Явное несоответствие характеру и степени опасности преступления и обстоятельствам задержания
УК РО|Статья 4.2. Крайняя необходимость|Устранение опасности причинением меньшего вреда, если иной путь невозможен; превышение — вред равный или более значительный|0|ч. 1 Правомерность^Устранение опасности, непосредственно угрожающей личности, правам, интересам общества или государства, если иными средствами невозможно~ч. 2 Превышение пределов^Причинение вреда, явно не соответствующего характеру и степени угрожавшей опасности
УК РО|Статья 4.3. Обоснованный риск|Правомерен для общественно полезной цели при достаточных мерах; не признается при угрозе жизни многих людей, экологической катастрофе|0|ч. 1 Правомерность^Не является преступлением при обоснованном риске для общественно полезной цели~ч. 2 Обоснованность^Цель не могла быть достигнута без риска; приняты достаточные меры для предотвращения вреда~ч. 3 Не признается обоснованным^Заведомо сопряжен с угрозой для жизни многих людей, экологической катастрофой или общественным бедствием
УК РО|Статья 4.4. Исполнение приказа или распоряжения|Ответственность несет лицо, отдавшее незаконный приказ; исполнение заведомо незаконного приказа наказуемо|0|ч. 1 Правомерность^Не является преступлением причинение вреда лицом, действующим во исполнение обязательного приказа~ч. 2 Заведомо незаконный приказ^Исполнение заведомо незаконного приказа наказуемо на общих основаниях; неисполнение исключает ответственность
УК РО|Статья 4.5. Физическое или психическое принуждение|Исключает ответственность, если лицо не могло руководить действиями; при сохранении возможности — учитывается ст. 4.2|0|ч. 1 Физическое принуждение^Не является преступлением, если лицо не могло руководить своими действиями~ч. 2 Психическое принуждение^Решается с учетом статьи 4.2
УК РО|Статья 4.6. Нормы о наркотических веществах (каннабиноиды)|До 3 г изымаются без УК; 1 куст Green = 5 г; 1 семечко Green = 2 г|0|ч. 1 До 3 г^Найденные каннабиноиды до 3 г изымаются без уголовной ответственности~ч. 2 Куст Green^Один куст Green приравнивается к 5 г~ч. 3 Семечко Green^Одно семечко Green приравнивается к 2 г
УК РО|Статья 5. Виды наказаний|Судебный штраф, уголовный штраф, лишение права, увольнение, лишение свободы, исправительные и принудительные работы|0|ч. 1 Виды^Судебный штраф, уголовный штраф, лишение права, увольнение, лишение свободы, исправительные работы, принудительные работы~ч. 2 Судебный процесс^Могут быть назначены все виды наказаний~ч. 3 Уголовный штраф^Применяется МВД, ФСБ, ФСО, Прокуратурой и судом~ч. 4 Расследование^По уголовным статьям может быть назначено только лишение свободы
УК РО|Статья 5.1. Исправительные работы|Назначаются по основному месту работы либо в местах, определяемых судом; срок устанавливается приговором|0|ч. 1 Место отбывания^По основному месту работы либо в местах, определяемых судом~ч. 2 Срок^Устанавливается приговором суда~ч. 3 Злостное уклонение^Замена принудительными работами или лишением свободы
    )
    LoadData(additions7)

    additions8 =
    (
УК РО|Статья 5.1.2. Принудительные работы|Альтернатива лишению свободы; привлечение к труду в местах, определяемых судом; уклонение влечет замену лишением свободы|0|ч. 1 Альтернатива^Применяются как альтернатива лишению свободы~ч. 2 Замена лишения свободы^Если суд придет к выводу о возможности исправления без реального отбывания~ч. 3 Содержание^Привлечение к труду в местах, определяемых судом~ч. 4 Срок^Устанавливается приговором~ч. 5 Уклонение^Неотбытая часть заменяется лишением свободы~ч. 6 Места и порядок^Определяются судом
УК РО|Статья 5.2. Общие начала назначения наказания|Справедливое наказание в пределах санкции с учетом характера, степени опасности, личности, смягчающих и отягчающих|0|ч. 1 Справедливость^В пределах санкции и с учетом Общей части~ч. 1.2 Особый порядок^По решению суда или постановлению прокуратуры — от минимальной санкции до 10 лет лишения свободы~ч. 2 Учет^Характер и степень опасности, личность виновного, смягчающие и отягчающие~ч. 3 Совокупность преступлений^В пределах наиболее строгой статьи; возможно полное или частичное сложение~ч. 4 Внесудебный предел^Не более 5 лет (за исключением ст. 17.3 во время процесса)~ч. 5 Упрощенный порядок^Только лишение свободы до 5 лет; иные виды наказаний не назначаются
УК РО|Статья 5.2.1. Назначение наказания за неоконченное преступление|Приготовление — не более половины, покушение — не более трех четвертей максимума|0|ч. 1 Учет обстоятельств^Учитываются обстоятельства, в силу которых преступление не доведено до конца~ч. 2 Приготовление^Не более половины максимального срока~ч. 3 Покушение^Не более трех четвертей максимального срока
УК РО|Статья 5.3. Обстоятельства, смягчающие наказание|Принуждение, зависимость, нарушение условий правомерности, явка с повинной, помощь потерпевшему, возмещение ущерба|0|а) Принуждение или зависимость^Совершение в результате физического или психического принуждения либо в силу зависимости~б) Нарушение условий правомерности^При нарушении условий необходимой обороны, задержания, крайней необходимости, обоснованного риска, исполнения приказа~в) Поведение потерпевшего^Противоправность или аморальность поведения, явившегося поводом~г) Явка с повинной^Активное способствование раскрытию, изобличению соучастников~д) Помощь потерпевшему^Оказание помощи, возмещение ущерба и морального вреда, иные действия~е) Иные обстоятельства
УК РО|Статья 5.4. Обстоятельства, отягчающие наказание|Группа лиц, вражда, месть, особая жестокость, использование формы, опьянение, рецидив|0|а) Группа лиц^Совершение в составе группы~б) Ненависть или вражда^По мотивам политической, идеологической, расовой, национальной, религиозной ненависти или вражды~в) Месть или сокрытие^Из мести за правомерные действия, с целью скрыть другое преступление или облегчить его~г) В связи со службой^В отношении лица или его близких в связи со служебной деятельностью~д) Особая жестокость^Садизм, издевательство, мучения для потерпевшего~е) Использование доверия^В силу служебного положения или договора~ё) Форменная одежда или документы^Использование формы или документов представителя власти~ж) Опьянение^Алкогольное или наркотическое~з) Психическое давление^На потерпевшего~и) Рецидивизм~й) Беспомощное положение^Потерпевший в заведомо беспомощном положении
УК РО|Статья 5.5. Назначение более мягкого наказания|Ниже низшего предела при исключительных обстоятельствах или активном содействии раскрытию|0
УК РО|Статья 5.6. Освобождение в связи с назначением штрафа/работ или примирением|Впервые совершившее лицо может быть освобождено судом со штрафом от 10 000 и/или исправительными работами|0|ч. 1 Примирение^Впервые совершившее преступление может быть освобождено при примирении и заглаживании вреда~ч. 2 Судебный штраф и работы^Освобождение с назначением судебного штрафа от 10 000 и (или) исправительных работ
УК РО|Статья 5.7. Сроки давности привлечения к уголовной ответственности|15 лет (15 дней); к лицам в федеральном розыске сроки не применяются; боло-розыск от 1 до 5 звезд|0|ч. 1 Срок давности^15 лет (15 дней) со дня совершения преступления~ч. 2 Федеральный розыск^К лицам в федеральном розыске сроки давности не применяются~ч. 3 Боло-розыск МВД/ФСБ^Уровень от 1 до 5 звезд~ч. 4 Боло-розыск по решению суда или прокуратуры^Уровень от 1 до 5 звезд~ч. 5 Исчисление^Со дня совершения до вступления приговора в силу; по каждому преступлению самостоятельно
УК РО|Статья 5.8. Судимость|Арест по статьям от 4 звезд и выше влечет отметку о судимости; погашение аннулирует последствия|0|ч. 1 Отметка о судимости^При аресте по статьям от 4 звезд и более~ч. 2 Погашение^Аннулирует все правовые последствия~ч. 3 Уголовный штраф^Запрета на государственную службу не возникает
УК РО|Статья 5.9. Освобождение при добровольной сдаче предметов|Добровольная сдача по ст. 12.8, 12.8.1, 13.1, 13.2 освобождает от УК; изъятие при задержании не считается добровольной сдачей|0
УК РО|Статья 5.10. Освобождение под залог|По статьям без судимости; 1 год = 25 000|0
УК РО|Статья 5.11. Упрощенное разрешение уголовного материала сотрудником правопорядка|Лишение свободы до 5 лет на месте задержания без отдельного дела; уголовный штраф только прокурором|0|ч. 1 Условия^Общая подследственность, отсутствие обязательного суда, достаточные доказательства, отсутствие обязательного участия прокурора~ч. 2 Без отдельного дела^Не требуется постановление о возбуждении и обвинительное заключение~ч. 3 Мера^Лишение свободы в пределах санкции, но не более 5 лет, либо уголовный штраф по ст. 5.2~ч. 4 Госслужащий^Уголовный штраф — только прокурор; иные виды наказаний в упрощенном порядке не назначаются~ч. 5 Объявление^Обстоятельства, статья, срок лишения свободы, право на обжалование~ч. 6 Спор о фактах^При существенном споре или необходимости расследования упрощенный порядок не применяется~ч. 7 Обжалование^Прокурору или в суд; подача жалобы не приостанавливает исполнение
    )
    LoadData(additions8)

    additions9 =
    (
УК РО|Статья 5.12. Подследственность|Р — МВД, Ф — ФСБ, В — Военная полиция, С — Следственный комитет|0|ч. 1 Буквенные обозначения^[Р] МВД, [Ф] ФСБ, [В] Военная полиция, [С] Следственный комитет~ч. 2 Несколько обозначений^Статья относится к подследственности любого из указанных ведомств~ч. 3 Задержание^Дознавателем ведомства; лицо в розыске — любым дознавателем с последующей передачей
УК РО|Статья 6.1 (Р) Умышленное и/или неоднократное нанесение телесных повреждений легкой или средней степени|до 20 месяцев лишения свободы (2 звезды)|1
УК РО|Статья 8.3 (В/С) Дезертирство|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 9.3 (Ф/Р) Воспрепятствование осуществлению избирательных прав|до 10 месяцев лишения свободы (1 звезда)|0
УК РО|Статья 9.4 (Ф/Р) Принуждение журналистов к распространению или отказу от информации|до 10 месяцев лишения свободы (1 звезда)|0
УК РО|Статья 10.4 (Ф) Мошенничество|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 10.5 (Ф/Р) Грабеж|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 16.14 (Ф/С) Уклонение от следствия, задержания и суда|до 50 месяцев с созданием записи о судимости (5 звезд)|0
    )
    LoadData(additions9)
}

LoadData(str) {
    global ArticleDB
    Loop, Parse, str, `n, `r
    {
        line := Trim(A_LoopField)
        if (line == "")
            continue
        p := StrSplit(line, "|")
        if (p.Length() >= 3) {
            pop := (p.Length() >= 4 && p[4] != "") ? p[4] + 0 : 0
            parts := []
            if (p.Length() >= 5 && Trim(p[5]) != "") {
                Loop, Parse, % p[5], "~"
                {
                    partStr := Trim(A_LoopField)
                    if (partStr == "")
                        continue
                    pp := StrSplit(partStr, "^")
                    if (pp.Length() >= 2)
                        parts.Push({"Title": pp[1], "Punish": pp[2]})
                    else if (pp.Length() == 1)
                        parts.Push({"Title": pp[1], "Punish": ""})
                }
            }
            ArticleDB.Push({"Category": p[1], "Title": p[2], "Punish": p[3], "IsPop": pop, "Expanded": false, "Parts": parts})
        }
    }
}



