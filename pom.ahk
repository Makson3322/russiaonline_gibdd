#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SendMode Input

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

global CurrentVersion := "3.2"
global RepoURL := "https://github.com/Makson3322/russiaonline_gibdd"
global UpdateAvailable := false
global LatestVersion := ""

LatestVersion := CheckVersionNow()
if (LatestVersion != "" && LatestVersion != CurrentVersion) {
    UpdateAvailable := true
}

IniFile := A_ScriptDir . "\config_gibdd.ini"
IniRead, CurrentHotkey, %IniFile%, Settings, OpenKey, NONE

InitDatabase()

OnMessage(0x0201, "WM_LBUTTONDOWN")

BuildOverlay()
BuildSelectorGui()

ShowSettingsGui(CurrentHotkey)
return

WM_LBUTTONDOWN() {
    PostMessage, 0xA1, 2,,, A
}

CheckVersionNow() {
    tmpFile := A_Temp . "\gibdd_ver_" . A_TickCount . ".txt"
    psCmd := "powershell -NoProfile -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Makson3322/russiaonline_gibdd/main/version.txt' -UseBasicParsing -TimeoutSec 3).Content | Out-File -FilePath '" . tmpFile . "' -Encoding ascii"""
    RunWait, %psCmd%,, Hide
    ver := ""
    if FileExist(tmpFile) {
        FileRead, ver, %tmpFile%
        FileDelete, %tmpFile%
    }
    if (ver == "") {
        psCmdMaster := "powershell -NoProfile -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Makson3322/russiaonline_gibdd/master/version.txt' -UseBasicParsing -TimeoutSec 3).Content | Out-File -FilePath '" . tmpFile . "' -Encoding ascii"""
        RunWait, %psCmdMaster%,, Hide
        if FileExist(tmpFile) {
            FileRead, ver, %tmpFile%
            FileDelete, %tmpFile%
        }
    }
    ver := Trim(ver)
    ver := RegExReplace(ver, "[\r\n\t ]+", "")
    return ver
}

ShowSettingsGui(savedKey) {
    global
    Gui, Settings:Destroy
    Gui, Settings:+AlwaysOnTop -MaximizeBox -MinimizeBox -Caption +Border
    Gui, Settings:Color, 121316, 1E1F23
    
    Gui, Settings:Font, s13 c5865F2 Bold, Segoe UI
    Gui, Settings:Add, Text, x20 y18 w400 Center, ПАМЯТКА ДПС ГИБДД КУТУЗОВСКИЙ
    
    Gui, Settings:Font, s9 c949BA4 Normal, Segoe UI
    Gui, Settings:Add, Text, x20 y44 w400 Center, [ СИСТЕМА ЗАКОНОДАТЕЛЬСТВА РОССИЯ ОНЛАЙН ]
    
    startY := 72
    guiH := 240
    
    if (UpdateAvailable) {
        Gui, Settings:Font, s10 cFFFFFF Bold, Segoe UI
        Gui, Settings:Add, Button, x30 y68 w380 h36 gOpenRepoUrl, 🚀 ВЫШЛО ОБНОВЛЕНИЕ V%LatestVersion%! (СКАЧАТЬ)
        startY := 112
        guiH := 280
    }
    
    Gui, Settings:Font, s10 cDCDDDE Normal, Segoe UI
    if (savedKey == "NONE" || savedKey == "") {
        Gui, Settings:Add, Text, x20 y%startY% w400 Center, Назначьте клавишу для открытия оверлея:
        btnText := "Сохранить и запустить"
    } else {
        Gui, Settings:Add, Text, x20 y%startY% w400 Center, Текущая клавиша вызова: [%savedKey%]`nВы можете изменить ее или продолжить:
        btnText := "Запустить биндер"
    }
    
    hkY := startY + 46
    btnY := hkY + 44
    footY := btnY + 46
    
    Gui, Settings:Font, s11 c2B2D31 Bold, Segoe UI
    Gui, Settings:Add, Hotkey, x80 y%hkY% w280 h32 vNewHotkey, % (savedKey == "NONE" ? "F3" : savedKey)
    
    Gui, Settings:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, Settings:Add, Button, x80 y%btnY% w280 h36 gSaveAndStart, %btnText%
    
    Gui, Settings:Font, s8 c949BA4 Normal, Segoe UI
    Gui, Settings:Add, Text, x20 y%footY% w400 Center, Закрытие меню в игре: [%CurrentHotkey%] или [ESC]
    
    Gui, Settings:Show, w440 h%guiH%, Настройка биндера ГИБДД
}

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
    IniWrite, %CurrentHotkey%, %IniFile%, Settings, OpenKey
    
    Hotkey, %CurrentHotkey%, ToggleSelectionMenu, On
    
    TrayTip, ДПС ГИБДД Памятка, Биндер успешно запущен!`nКлавиша вызова: [%CurrentHotkey%], 3, 1
    BuildOverlay()
    BuildSelectorGui()
return

SettingsGuiClose:
    ExitApp

BuildSelectorGui() {
    global
    Gui, Selector:Destroy
    Gui, Selector:+AlwaysOnTop +ToolWindow -Caption +LastFound +Border +HwndhSelectorGui
    Gui, Selector:Color, 121316, 1E1F23
    
    WinSet, Transparent, 248
    
    Gui, Selector:Font, s12 c5865F2 Bold, Segoe UI
    Gui, Selector:Add, Text, x20 y16 w380 Center, БАЗА ЗАКОНОДАТЕЛЬСТВА
    
    Gui, Selector:Font, s9 c949BA4 Normal, Segoe UI
    Gui, Selector:Add, Text, x20 y42 w380 Center, Выберите нужный раздел для открытия:
    
    sY := 72
    sH := 385
    if (UpdateAvailable) {
        Gui, Selector:Font, s10 cFFFFFF Bold, Segoe UI
        Gui, Selector:Add, Button, x30 y70 w360 h34 gOpenRepoUrl, 🚀 СКАЧАТЬ ОБНОВЛЕНИЕ V%LatestVersion%
        sY := 110
        sH := 425
    }
    
    b2 := sY + 42
    b3 := b2 + 44
    b4 := b3 + 40
    b5 := b4 + 40
    b6 := b5 + 40
    b7 := b6 + 40
    b8 := b7 + 38
    
    Gui, Selector:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, Selector:Add, Button, x30 y%sY% w360 h38 gChoosePopular, ★ ПОПУЛЯРНЫЕ СТАТЬИ (БАЗА ДПС)
    Gui, Selector:Add, Button, x30 y%b2% w360 h38 gChooseAll, 📋 ВСЕ СТАТЬИ И ЗАКОНЫ (ПОЛНАЯ БАЗА)
    
    Gui, Selector:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Selector:Add, Button, x30 y%b3% w175 h34 gChooseKoAP, КоАП РО (по порядку)
    Gui, Selector:Add, Button, x215 y%b3% w175 h34 gChooseUK, УК РО (по порядку)
    
    Gui, Selector:Add, Button, x30 y%b4% w175 h34 gChooseProc, Процессуальный кодекс
    Gui, Selector:Add, Button, x215 y%b4% w175 h34 gChoosePDD, ПДД РО
    
    Gui, Selector:Add, Button, x30 y%b5% w175 h34 gChoosePolice, ФЗ О Полиции
    Gui, Selector:Add, Button, x215 y%b5% w175 h34 gChooseUstav, Устав ГИБДД
    
    Gui, Selector:Add, Button, x30 y%b6% w115 h34 gShowMiranda, ⚖ Миранда
    Gui, Selector:Add, Button, x152 y%b6% w115 h34 gShowMegaphone, 📢 Мегафон
    Gui, Selector:Add, Button, x275 y%b6% w115 h34 gShowBailCalc, 💰 Залог
    
    Gui, Selector:Add, Button, x30 y%b7% w360 h32 gShowRulesFromSelector, [ ? ] Регламент ст. 10 КоАП / Подследственность
    
    Gui, Selector:Font, s8 c949BA4 Normal, Segoe UI
    Gui, Selector:Add, Text, x20 y%b8% w380 Center, Закрыть: [%CurrentHotkey%] / [ESC] | Перемещение за фон
}

ToggleSelectionMenu:
    if (OverlayVisible || SelectorVisible || RulesVisible || MirandaVisible || MegaphoneVisible || BailVisible) {
        CloseAllWindows()
        return
    }
    
    PrevGameHwnd := WinActive("A")
    SelectorVisible := true
    Gui, Selector:Show, Center, GIBDD_Selector
    WinActivate, ahk_id %hSelectorGui%
    DllCall("SetForegroundWindow", "Ptr", hSelectorGui)
    DllCall("SetWindowPos", "Ptr", hSelectorGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
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

OpenOverlayWithCategory(catNumber) {
    global
    OverlayVisible := true
    Gui, Overlay:Default
    ActiveCategoryIndex := catNumber
    GuiControl, Overlay:, SearchTerm, 
    Gosub, FilterArticles
    
    Gui, Overlay:Show, w1040 h610 Center, GIBDD_Overlay
    WinActivate, ahk_id %hOverlayGui%
    DllCall("SetForegroundWindow", "Ptr", hOverlayGui)
    DllCall("SetWindowPos", "Ptr", hOverlayGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
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
    Gui, Overlay:Hide
    Gui, Selector:Hide
    Gui, RulesModal:Hide
    Gui, MirandaModal:Hide
    Gui, MegaphoneModal:Hide
    Gui, BailModal:Hide
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
    Gosub, CopySelected
return

NumpadEnter::
    Gosub, CopySelected
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

OpenRepoUrl:
    Run https://github.com/Makson3322/russiaonline_gibdd
return

BuildOverlay() {
    global
    Gui, Overlay:Destroy
    Gui, Overlay:+AlwaysOnTop +ToolWindow -Caption +LastFound +Border +HwndhOverlayGui
    Gui, Overlay:Color, 121316, 1E1F23
    Gui, Overlay:Default
    
    ActiveCategoryIndex := 1
    WinSet, Transparent, 248
    
    Gui, Overlay:Font, s12 c5865F2 Bold, Segoe UI
    Gui, Overlay:Add, Text, x25 y14 w260, ДПС ГИБДД КУТУЗОВСКИЙ
    
    if (UpdateAvailable) {
        Gui, Overlay:Font, s9 cFFFFFF Bold, Segoe UI
        Gui, Overlay:Add, Button, x290 y12 w320 h28 gOpenRepoUrl, 🚀 ОБНОВИТЬ СКРИПТ ДО V%LatestVersion%
    }
    
    Gui, Overlay:Font, s9 c949BA4 Normal, Segoe UI
    Gui, Overlay:Add, Text, x620 y16 w395 Right, Закрыть: [%CurrentHotkey%] / [ESC] | Двойной клик / Enter: копия
    
    Gui, Overlay:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Overlay:Add, Button, x25 y46 w80 h28 gTabPop, ★ Топ
    Gui, Overlay:Add, Button, x110 y46 w70 h28 gTabAll, Все
    Gui, Overlay:Add, Button, x185 y46 w85 h28 gTabKoap, КоАП
    Gui, Overlay:Add, Button, x275 y46 w75 h28 gTabUK, УК РО
    Gui, Overlay:Add, Button, x355 y46 w75 h28 gTabPK, ПК РО
    Gui, Overlay:Add, Button, x435 y46 w80 h28 gTabPDD, ПДД
    Gui, Overlay:Add, Button, x520 y46 w75 h28 gTabPol, ФЗ Полица
    Gui, Overlay:Add, Button, x600 y46 w75 h28 gTabUstav, Устав
    
    Gui, Overlay:Font, s9 c5865F2 Bold, Segoe UI
    Gui, Overlay:Add, Button, x690 y46 w80 h28 gShowMiranda, ⚖ Права
    Gui, Overlay:Add, Button, x775 y46 w85 h28 gShowMegaphone, 📢 Мегафон
    Gui, Overlay:Add, Button, x865 y46 w75 h28 gShowBailCalc, 💰 Залог
    Gui, Overlay:Add, Button, x945 y46 w70 h28 gOpenSettingsFromMenu, ⚙ Бинд
    
    Gui, Overlay:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Overlay:Add, Text, x25 y88 w50 h26 +0x200, Поиск:
    
    Gui, Overlay:Font, s10 cFFFFFF Normal, Segoe UI
    Gui, Overlay:Add, Edit, x80 y86 w340 h28 vSearchTerm gFilterArticles -E0x200 +Border +HwndhSearchBox, 
    
    Gui, Overlay:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, Overlay:Add, Button, x425 y86 w32 h28 gClearSearch, ✖
    Gui, Overlay:Add, Button, x465 y86 w130 h28 gCopySelected, 📋 Копировать
    Gui, Overlay:Add, Button, x602 y86 w150 h28 gShowRules, [ ? ] Регламент/Суд
    
    Gui, Overlay:Font, s8 c57F287 Bold, Segoe UI
    Gui, Overlay:Add, Text, x765 y92 w250 h18 Right vCountLabel, Загрузка базы...
    
    Gui, Overlay:Font, s9 cFFFFFF Normal, Segoe UI
    Gui, Overlay:Add, ListView, x25 y122 w990 h320 vMyLV gLVClick +AltSubmit -Multi +Grid Background1E1F23 cFFFFFF, Раздел|Статья / Пункт|Наказание / Санкция / Содержание
    LV_ModifyCol(1, "130 Left")
    LV_ModifyCol(2, "520 Left")
    LV_ModifyCol(3, "335 Left")
    
    Gui, Overlay:Font, s9 c5865F2 Bold, Segoe UI
    Gui, Overlay:Add, GroupBox, x25 y452 w990 h140, КАРТОЧКА СТАТЬИ / РЕГЛАМЕНТ:
    
    Gui, Overlay:Font, s10 cE0E2E6 Normal, Consolas
    Gui, Overlay:Add, Edit, x38 y474 w964 h108 vDetailBox ReadOnly -E0x200 +Multi Background18191C +Border, Выберите статью в списке выше (нажатие Enter или двойной клик копирует информацию в буфер обмена)...
    
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
    
    for index, item in ArticleDB
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
            if (query == "" || InStr(item.Category, query) || InStr(item.Title, query) || InStr(item.Punish, query)) {
                LV_Add("", item.Category, item.Title, item.Punish)
                matchCount++
            }
        }
    }
    GuiControl, Overlay:+Redraw, MyLV
    GuiControl, Overlay:, CountLabel, Найдено: %matchCount% из %totalCount%
return

LVClick:
    Gui, Overlay:Default
    if (A_GuiEvent == "Normal" || A_GuiEvent == "K") {
        Row := LV_GetNext(0, "Focused")
        if (Row > 0) {
            LV_GetText(tCat, Row, 1)
            LV_GetText(tTitle, Row, 2)
            LV_GetText(tPunish, Row, 3)
            infoText := "РАЗДЕЛ:    " . tCat . "`r`nСТАТЬЯ:    " . tTitle . "`r`nНАКАЗАНИЕ: " . tPunish
            GuiControl, Overlay:, DetailBox, %infoText%
        }
    }
    if (A_GuiEvent == "DoubleClick") {
        Gosub, CopySelected
    }
return

CopySelected:
    Gui, Overlay:Default
    Row := LV_GetNext(0, "Focused")
    if (Row > 0) {
        LV_GetText(tCat, Row, 1)
        LV_GetText(tTitle, Row, 2)
        LV_GetText(tPunish, Row, 3)
        Clipboard := "[" . tCat . "] " . tTitle . " — Наказание: " . tPunish
        TrayTip, ДПС ГИБДД, Статья скопирована в буфер обмена!, 2, 1
    }
return

ShowMiranda:
    global MirandaVisible := true
    Gui, MirandaModal:Destroy
    Gui, MirandaModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhMirandaGui
    Gui, MirandaModal:Color, 121316, 1E1F23
    
    Gui, MirandaModal:Font, s12 c5865F2 Bold, Segoe UI
    Gui, MirandaModal:Add, Text, x20 y16 w540 Center, ПРАВИЛО МИРАНДЫ (СТ. 6 ГЛ. II ПК РО)
    
    Gui, MirandaModal:Font, s10 cDCDDDE Normal, Segoe UI
    mText := "«Вы имеете право хранить молчание.`r`n"
          . "Всё, что вы скажете, может и будет использовано против Вас в суде.`r`n"
          . "Вы имеете право на один телефонный звонок.`r`n"
          . "Также Вы имеете право на адвоката.`r`n"
          . "Если вам необходим адвокат, он будет для Вас запрошен.`r`n`r`n"
          . "Вы понимаете свои права?»"
    Gui, MirandaModal:Add, Text, x30 y52 w520 h130 Center, %mText%
    
    Gui, MirandaModal:Font, s9 c949BA4 Normal, Segoe UI
    Gui, MirandaModal:Add, Text, x20 y190 w540 Center, Звонок: до 3 минут в присутствии | Адвокат: встреча 10 минут наедине
    
    Gui, MirandaModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, MirandaModal:Add, Button, x90 y225 w180 h36 gCopyMiranda, 📋 Скопировать текст
    Gui, MirandaModal:Add, Button, x290 y225 w180 h36 gCloseMiranda, Закрыть
    
    Gui, MirandaModal:Show, w580 h280 Center, GIBDD_Miranda
    WinActivate, ahk_id %hMirandaGui%
    DllCall("SetForegroundWindow", "Ptr", hMirandaGui)
    DllCall("SetWindowPos", "Ptr", hMirandaGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
return

CopyMiranda:
    Clipboard := "Вы имеете право хранить молчание. Всё, что вы скажете, может и будет использовано против Вас в суде. Вы имеете право на один телефонный звонок. Также Вы имеете право на адвоката. Если вам необходим адвокат, он будет для Вас запрошен. Вы понимаете свои права?"
    TrayTip, ДПС ГИБДД, Текст Миранды скопирован в буфер обмена!, 2, 1
return

CloseMiranda:
    Gui, MirandaModal:Hide
    MirandaVisible := false
return

ShowMegaphone:
    global MegaphoneVisible := true
    Gui, MegaphoneModal:Destroy
    Gui, MegaphoneModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhMegaphoneGui
    Gui, MegaphoneModal:Color, 121316, 1E1F23
    
    Gui, MegaphoneModal:Font, s12 c5865F2 Bold, Segoe UI
    Gui, MegaphoneModal:Add, Text, x20 y16 w600 Center, ТРЕБОВАНИЯ В МЕГАФОН (СТ. 6 ГЛ. XI ПК РО)
    
    Gui, MegaphoneModal:Font, s9 c5865F2 Bold, Segoe UI
    Gui, MegaphoneModal:Add, GroupBox, x20 y45 w600 h75, 1-е ТРЕБОВАНИЕ ОБ ОСТАНОВКЕ:
    Gui, MegaphoneModal:Font, s9 cDCDDDE Normal, Segoe UI
    Gui, MegaphoneModal:Add, Text, x30 y65 w450 h45, Водитель ТС, прижмитесь к обочине и остановитесь! В противном случае к вам будут применены меры принудительной остановки!
    Gui, MegaphoneModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x490 y65 w120 h35 gCopyMega1, 📋 Скопировать
    
    Gui, MegaphoneModal:Font, s9 c5865F2 Bold, Segoe UI
    Gui, MegaphoneModal:Add, GroupBox, x20 y128 w600 h75, 2-е ТРЕБОВАНИЕ ОБ ОСТАНОВКЕ:
    Gui, MegaphoneModal:Font, s9 cDCDDDE Normal, Segoe UI
    Gui, MegaphoneModal:Add, Text, x30 y148 w450 h45, Повторяю требование об остановке! Немедленно прижмитесь к обочине, заглушите двигатель и оставайтесь в автомобиле!
    Gui, MegaphoneModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x490 y148 w120 h35 gCopyMega2, 📋 Скопировать
    
    Gui, MegaphoneModal:Font, s9 c5865F2 Bold, Segoe UI
    Gui, MegaphoneModal:Add, GroupBox, x20 y211 w600 h75, 3-е ТРЕБОВАНИЕ (ФИНАЛЬНОЕ):
    Gui, MegaphoneModal:Font, s9 cDCDDDE Normal, Segoe UI
    Gui, MegaphoneModal:Add, Text, x30 y231 w450 h45, Это последнее предупреждение! В случае дальнейшего неподчинения будет открыт огонь по колесам и применен силовой таран!
    Gui, MegaphoneModal:Font, s9 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x490 y231 w120 h35 gCopyMega3, 📋 Скопировать
    
    Gui, MegaphoneModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, MegaphoneModal:Add, Button, x230 y298 w180 h36 gCloseMegaphone, Закрыть окно
    
    Gui, MegaphoneModal:Show, w640 h350 Center, GIBDD_Megaphone
    WinActivate, ahk_id %hMegaphoneGui%
    DllCall("SetForegroundWindow", "Ptr", hMegaphoneGui)
    DllCall("SetWindowPos", "Ptr", hMegaphoneGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
return

CopyMega1:
    Clipboard := "/m [ГИБДД]: Водитель ТС, прижмитесь к обочине и остановитесь! В противном случае к вам будут применены меры принудительной остановки!"
    TrayTip, ДПС ГИБДД, 1-е требование скопировано!, 2, 1
return

CopyMega2:
    Clipboard := "/m [ГИБДД]: Повторяю требование об остановке! Немедленно прижмитесь к обочине, заглушите двигатель и оставайтесь в авто!"
    TrayTip, ДПС ГИБДД, 2-е требование скопировано!, 2, 1
return

CopyMega3:
    Clipboard := "/m [ГИБДД]: Это последнее предупреждение! В случае неподчинения будет открыт огонь по колесам и применен таран!"
    TrayTip, ДПС ГИБДД, 3-е требование скопировано!, 2, 1
return

CloseMegaphone:
    Gui, MegaphoneModal:Hide
    MegaphoneVisible := false
return

ShowBailCalc:
    global BailVisible := true
    Gui, BailModal:Destroy
    Gui, BailModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhBailGui
    Gui, BailModal:Color, 121316, 1E1F23
    
    Gui, BailModal:Font, s12 c5865F2 Bold, Segoe UI
    Gui, BailModal:Add, Text, x20 y16 w400 Center, КАЛЬКУЛЯТОР ЗАЛОГА (СТ. 5.10 УК РО)
    
    Gui, BailModal:Font, s9 c949BA4 Normal, Segoe UI
    Gui, BailModal:Add, Text, x20 y42 w400 Center, Сумма залога: 1 год (звезда) = 25 000 рублей
    
    Gui, BailModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, BailModal:Add, Text, x40 y80 w180 h26 +0x200, Срок ареста (лет/звезд):
    
    Gui, BailModal:Font, s11 cFFFFFF Normal, Segoe UI
    Gui, BailModal:Add, Edit, x230 y78 w160 h28 vBailYears gCalcBail -E0x200 +Border +Number, 1
    
    Gui, BailModal:Font, s11 c57F287 Bold, Segoe UI
    Gui, BailModal:Add, Text, x20 y120 w400 Center vBailResult, Итоговая сумма: 25 000 руб
    
    Gui, BailModal:Font, s8 c949BA4 Normal, Segoe UI
    Gui, BailModal:Add, Text, x20 y148 w400 Center, Залог не применяется по статьям с отметкой о судимости (от 4 звезд)
    
    Gui, BailModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, BailModal:Add, Button, x60 y180 w150 h36 gCopyBailSum, 📋 Скопировать
    Gui, BailModal:Add, Button, x230 y180 w150 h36 gCloseBail, Закрыть
    
    Gui, BailModal:Show, w440 h235 Center, GIBDD_Bail
    WinActivate, ahk_id %hBailGui%
    DllCall("SetForegroundWindow", "Ptr", hBailGui)
    DllCall("SetWindowPos", "Ptr", hBailGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
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
    Clipboard := "Сумма освобождения под залог по ст. 5.10 УК РО составляет " . total . " рублей."
    TrayTip, ДПС ГИБДД, Сумма залога скопирована в буфер обмена!, 2, 1
return

CloseBail:
    Gui, BailModal:Hide
    BailVisible := false
return

ShowRules:
    global RulesVisible := true
    Gui, RulesModal:Destroy
    Gui, RulesModal:+AlwaysOnTop +ToolWindow -Caption +Border +HwndhRulesGui
    Gui, RulesModal:Color, 121316, 1E1F23
    
    Gui, RulesModal:Font, s12 c5865F2 Bold, Segoe UI
    Gui, RulesModal:Add, Text, x25 y16 w560, ПРИМЕЧАНИЯ И РЕГЛАМЕНТ ДПС
    
    Gui, RulesModal:Font, s9 c5865F2 Bold, Segoe UI
    Gui, RulesModal:Add, GroupBox, x25 y46 w560 h125, 1. РЕГЛАМЕНТ СТАТЬИ 10 КоАП (ОТКАЗ ОТ ШТРАФА):
    
    Gui, RulesModal:Font, s9 cDCDDDE Normal, Segoe UI
    rText1 := "За нарушение ст. 10 КоАП задержанного необходимо отвозить в здание Правительства.`r`nДалее туда же вызываем сотрудника МВД для передачи процессуальных действий и судью через канал в Discord фракции.`r`nЕсли судья не приедет в течение 15 минут — задержанного необходимо отпустить, а материалы дела направить в суд."
    Gui, RulesModal:Add, Text, x38 y70 w534 h90, %rText1%
    
    Gui, RulesModal:Font, s9 c5865F2 Bold, Segoe UI
    Gui, RulesModal:Add, GroupBox, x25 y180 w560 h120, 2. ПОДСЛЕДСТВЕННОСТЬ СТРУКТУР (КУДА ВЕЗТИ):
    
    Gui, RulesModal:Font, s10 cE0E2E6 Bold, Consolas
    rText2 := "Ф  ->  ФСБ`r`nС  ->  Следственный комитет`r`nР  ->  МВД (основное место доставки ДПС)`r`nВ  ->  Военная полиция / Армия"
    Gui, RulesModal:Add, Text, x40 y205 w530 h85, %rText2%
    
    Gui, RulesModal:Font, s10 cFFFFFF Bold, Segoe UI
    Gui, RulesModal:Add, Button, x205 y315 w200 h36 gCloseRules, Закрыть окно
    
    Gui, RulesModal:Show, w610 h365 Center, GIBDD_Rules
    WinActivate, ahk_id %hRulesGui%
    DllCall("SetForegroundWindow", "Ptr", hRulesGui)
    DllCall("SetWindowPos", "Ptr", hRulesGui, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001 | 0x0002 | 0x0040)
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

    k1 = 
    (
КоАП РО|Статья 1.1. Законодательство об административных правонарушениях|Состоит из Кодекса и федеральных законов; подзаконные акты не вводят наказаний|0
КоАП РО|Статья 1.2. Задачи законодательства об административных правонарушениях|Защита прав, свобод, собственности, правопорядка и общественной безопасности|0
КоАП РО|Статья 2.1. Равенство перед законом|Все лица равны независимо от должности, положения и государственного статуса|0
КоАП РО|Статья 2.2. Презумпция невиновности|Бремя доказывания на обвинении; неустранимые сомнения толкуются в пользу лица|0
КоАП РО|Статья 2.3. Законность административного принуждения|Меры избираются строго соразмерно и только в пределах служебной компетенции|0
КоАП РО|Статья 2.4. Действие закона во времени|Закон, улучшающий положение лица либо отменяющий ответственность, имеет обратную силу|0
КоАП РО|Статья 2.5. Возраст административной ответственности|Административной ответственности подлежит лицо, достигшее 16-летнего возраста|0
КоАП РО|Статья 2.6. Ответственность юридических лиц|При наличии реальной возможности соблюдения правил и непринятии мер|0
КоАП РО|Статья 3.1. Понятие административного правонарушения|Противоправное виновное деяние лица, не образующее состава преступления|0
КоАП РО|Статья 3.2. Формы вины (умысел и неосторожность)|Осознание противоправности либо самонадеянный расчет на предотвращение вреда|0
КоАП РО|Статья 3.3. Разграничение с преступлением|При признаках преступления адм. производство прекращается и передается в СК/МВД|0
КоАП РО|Статья 4.1. Крайняя необходимость|Причинение меньшего вреда для устранения непосредственно угрожающей опасности|0
КоАП РО|Статья 4.2. Правомерное осуществление полномочий|Действия в пределах прямо предоставленных законом прав не являются правонарушением|0
КоАП РО|Статья 5.1. Малозначительность правонарушения|Возможность освобождения от ответственности с объявлением устного замечания|0
КоАП РО|Статья 6.1. Цели административного наказания|Восстановление нарушенного правопорядка и предупреждение совершения новых деяний|0
КоАП РО|Статья 6.2. Виды административных наказаний|Предупреждение, штраф, арест, конфискация, лишение права, приостановление|0
КоАП РО|Статья 6.3. Предупреждение|Официальное порицание за впервые совершенное малозначительное деяние|0
КоАП РО|Статья 6.4. Административный штраф|Денежное взыскание в рублях в пределах установленной санкции статьи|0
КоАП РО|Статья 6.5. Административный арест|Внесудебно до 10 суток; свыше 10 суток — только судьей (максимально 15 суток)|0
КоАП РО|Статья 6.6. Лишение специального права|Лишение права управления ТС или владения оружием назначается судьей|0
КоАП РО|Статья 6.7. Конфискация орудия или предмета|Принудительное безвозмездное обращение орудия правонарушения в собственность РО|0
КоАП РО|Статья 6.8. Административное приостановление деятельности|Временное прекращение работы организации судьей на срок до 7 календарных дней|0
КоАП РО|Статья 7.1. Общие правила назначения наказания|Строго в пределах санкции с учетом тяжести содеянного, вины и личности|0
КоАП РО|Статья 7.2. Смягчающие обстоятельства|Раскаяние, добровольное прекращение, содействие органам, возмещение ущерба|0
КоАП РО|Статья 7.3. Отягчающие обстоятельства|Отказ прекратить нарушение, повторность, группа лиц, должность, опьянение|0
    )
    LoadData(k1)

    k2 = 
    (
КоАП РО|Статья 7.4. Несколько правонарушений|Наказание назначается за каждое деяние без превышения пределов Кодекса|0
КоАП РО|Статья 8.1. Давность привлечения к ответственности|Срок давности составляет 5 календарных дней со дня совершения правонарушения|0
КоАП РО|Статья 9.1. Органы, рассматривающие материалы|ГИБДД рассматривает все дела по главе IX и статье 10 настоящего Кодекса|0
КоАП РО|Статья 9.2. Упрощенное рассмотрение на месте|Предупреждение, штраф или арест до 10 суток при очевидности обстоятельств|0
КоАП РО|Статья 9.3. Ответственность государственного служащего|При административном аресте гос. служащего участие прокурора строго обязательно|0
КоАП РО|Статья 9.4. Судебная подсудность|Первая инстанция — Мировой судья; апелляционные жалобы — Районный суд|0
КоАП РО|Статья 9.5. Ведомственный пересмотр решения|Жалоба руководству; предоставление видеозаписей за 24 ч, рассмотрение за 72 ч|0
КоАП РО|Статья 9.6. Исполнение административного штрафа|Игнор штрафного тикета 15 секунд / отказ оплаты = состав статьи 10 КоАП|0
КоАП РО|Статья 10. Уклонение от исполнения административного наказания|Административный арест на 10 суток (1 звезда / Суд в Правительстве)|1
КоАП РО|Статья 11. ч.1. Мелкое хулиганство (непристойное поведение, нецензурная брань)|Штраф от 5.000 до 15.000 рублей либо арест до 10 суток|0
КоАП РО|Статья 11. ч.2. Мелкое хулиганство повторно, группой лиц или отказ прекратить|Штраф от 15.000 до 30.000 рублей либо арест до 10 суток|0
КоАП РО|Статья 11.1. ч.1. Нарушение порядка проведения публичного мероприятия|Штраф от 10.000 до 25.000 рублей|0
КоАП РО|Статья 11.1. ч.2. Организация/продолжение митинга после требования прекратить|Штраф от 25.000 до 50.000 рублей либо арест до 10 суток|0
КоАП РО|Статья 12. Самовольное использование государственного имущества|Штраф от 20.000 до 50.000 рублей с возмещением причиненного ущерба|0
КоАП РО|Статья 13. Нахождение в состоянии опьянения, нарушающем общественный порядок|Штраф от 5.000 до 15.000 рублей либо арест до 5 суток|0
КоАП РО|Статья 13.1. ч.1. Нарушение режима ношения бронезащиты на охраняемом объекте|Штраф от 10.000 до 20.000 рублей|0
КоАП РО|Статья 13.1. ч.2. Ношение бронезащиты с сокрытием личности или отказом покинуть|Штраф от 20.000 до 35.000 рублей либо арест до 7 суток|0
КоАП РО|Статья 14. Азартные игры в неустановленном месте|Штраф от 10.000 до 30.000 рублей; организатору от 20.000 до 50.000 рублей|0
КоАП РО|Статья 15. Опасное открытое ношение или использование разрешенных предметов|Штраф от 15.000 до 30.000 рублей; повторно от 30.000 до 50.000 рублей|0
КоАП РО|Статья 16. Нецелевое расходование бюджетных средств|Штраф должностному лицу от 75.000 до 150.000 рублей (Судебный порядок)|0
КоАП РО|Статья 17. ч.1. Незаконное нахождение на частной территории|Штраф от 5.000 до 15.000 рублей|0
КоАП РО|Статья 17. ч.2. Повторный отказ покинуть территорию либо преодоление ограждения|Штраф от 15.000 до 30.000 рублей либо арест до 5 суток|0
КоАП РО|Статья 18. Незаконный оборот наркотических средств в незначительном размере (до 3 г)|Штраф от 20.000 до 40.000 рублей либо арест до 10 суток с изъятием|0
КоАП РО|Статья 19. ч.1. Причинение незначительного вреда здоровью, побои|Штраф от 15.000 до 30.000 рублей либо арест до 10 суток|0
КоАП РО|Статья 19. ч.2. Причинение вреда по неосторожности при грубом нарушении безопасности|Штраф от 10.000 до 20.000 рублей|0
    )
    LoadData(k2)

    k3 = 
    (
КоАП РО|Статья 20. Нарушение режима чрезвычайного или военного положения|Штраф от 20.000 до 50.000 рублей либо арест до 10 суток с конфискацией|0
КоАП РО|Статья 21. Угроза причинением вреда, не образующая преступления|Штраф от 15.000 до 30.000 рублей|0
КоАП РО|Статья 22. Создание антисанитарной обстановки в общественном месте|Штраф от 5.000 до 15.000 рублей|0
КоАП РО|Статья 23. Оскорбление (унижение чести и достоинства в неприличной форме)|Штраф от 10.000 до 20.000 рублей|0
КоАП РО|Статья 24. Дискриминация прав граждан|Штраф гражданину от 10.000 до 30.000; должностному от 30.000 до 70.000 руб (Суд)|0
КоАП РО|Статья 24.1. Дискриминация в сфере труда|Штраф работодателю или должностному лицу от 30.000 до 80.000 рублей (Суд)|0
КоАП РО|Статья 25. Публичное унижение группы лиц|Штраф от 20.000 до 50.000 рублей (Судебный порядок)|0
КоАП РО|Статья 26. Воспрепятствование оказанию медицинской помощи|Штраф от 20.000 до 40.000 руб; при продолжении до 50.000 руб или арест 10 сут|0
КоАП РО|Статья 27. Повреждение чужого имущества в незначительном размере|Штраф от 10.000 до 30.000 рублей с обязанностью возместить ущерб|0
КоАП РО|Статья 28. Воспрепятствование законной деятельности журналиста|Штраф от 15.000 до 35.000 рублей|0
КоАП РО|Статья 29. Неправомерное использование специальных средств должностным лицом|Штраф должностному лицу от 30.000 до 70.000 рублей (Прокуратура)|0
КоАП РО|Статья 30. Неисполнение законного письменного предписания или акта|Штраф гражданину 20.000-50.000; должностному 50.000-100.000 (Прокуратура)|0
КоАП РО|Статья 30.1. Неисполнение законного адвокатского запроса|Штраф должностному лицу от 20.000 до 50.000 рублей (Прокуратура)|0
КоАП РО|Статья 31. Нарушение порядка доступа к общественно значимой информации|Штраф должностному лицу от 20.000 до 50.000 рублей (Суд)|0
КоАП РО|Статья 32. ч.1. Нарушение правил использования законно принадлежащего оружия|Штраф от 30.000 до 60.000 рублей|0
КоАП РО|Статья 32. ч.2. Нарушение правил оружия с реальной угрозой либо повторно|Штраф от 40.000 до 80.000 рублей с лишением лицензии до 30 дней (Суд)|0
КоАП РО|Статья 33. Браконьерство (охота или рыболовство без разрешения/в запретном месте)|Штраф от 20.000 до 50.000 рублей с изъятием добычи и лишением права (Суд)|0
КоАП РО|Статья 34. Превышение установленной нормы добычи природных ресурсов|Штраф от 10.000 до 30.000 рублей с изъятием добычи сверх нормы|0
КоАП РО|Статья 35. Неуважение к суду|Штраф от 10.000 до 50.000 рублей либо административный арест до 10 суток (Суд)|0
КоАП РО|Статья 36. Заведомо ложный вызов экстренной или государственной службы|Штраф от 10.000 до 25.000 рублей|0
КоАП РО|Статья 37. Заведомо ложное сообщение об административном правонарушении|Штраф от 15.000 до 30.000 рублей|0
КоАП РО|Статья 38. Воспрепятствование законной деятельности государственного служащего|Штраф от 15.000 до 35.000 рублей либо административный арест до 10 суток|1
КоАП РО|Статья 39. Нарушение установленного порядка поведения в государственном учреждении|Штраф от 10.000 до 25.000 рублей|0
КоАП РО|Статья 40. Нарушение порядка хранения служебного оружия и спецсредств сотрудником|Штраф должностному лицу от 30.000 до 70.000 рублей с изъятием (Прокуратура)|0
КоАП РО|Статья 41.1. Нарушение правил предвыборной агитации|Штраф гражданину от 15.000 до 30.000; должностному от 30.000 до 70.000 руб (Суд)|0
    )
    LoadData(k3)

    k4 = 
    (
КоАП РО|Статья 41.2. Ненадлежащее исполнение должностных обязанностей|Штраф должностному лицу от 20.000 до 60.000 рублей (Прокуратура)|0
КоАП РО|Статья 42.1. Исполнение государственной службы в состоянии наркотического опьянения|Штраф от 40.000 до 80.000 рублей (Прокуратура)|0
КоАП РО|Статья 42.2. Отказ государственного служащего в предоставлении медицинских справок|Штраф до 40.000 рублей|0
КоАП РО|Статья 42.3. Просроченные медицинские справки у государственного служащего|Штраф до 20.000 рублей|0
КоАП РО|Статья 42.4. Препятствие или отказ от санитарно-эпидемиологической проверки|Штраф от 50.000 до 100.000 рублей|0
КоАП РО|Статья 42.5. Нарушение санитарно-эпидемиологических правил (угроза заболевания)|Штраф до 10.000 рублей|0
КоАП РО|Статья 43. Нарушение требований трудового законодательства работодателем|Штраф от 15.000 до 100.000 рублей в зависимости от части (Прокуратура)|0
КоАП РО|Статья 44. Незаконные правила внутреннего трудового распорядка|Штраф от 100.000 до 250.000 рублей с устранением нарушений (Суд)|0
КоАП РО|Статья 45. Незаконное предпринимательство, не образующее преступления|Штраф гражданину от 30.000 до 80.000 рублей с возможным приостановлением (Суд)|0
КоАП РО|Статья 45.1. Ненадлежащая реклама незаконной деятельности|Штраф от 50.000 до 150.000 рублей (Судебный порядок)|0
КоАП РО|Статья 45.2. Нарушение обязательных условий лицензии|Штраф от 30.000 до 100.000 рублей с приостановлением до 7 дней (Суд)|0
КоАП РО|Статья 46. ч.1. Управление транспортным средством без права управления|Штраф от 20.000 до 40.000 рублей с отстранением либо арест до 10 суток|1
КоАП РО|Статья 46. ч.2. Непредъявление водителем водительского удостоверения и документов сотруднику|Штраф от 5.000 до 10.000 рублей|1
КоАП РО|Статья 47. Управление транспортным средством в состоянии опьянения|Штраф от 50.000 до 100.000 рублей с лишением прав до 30 дней (Суд)|0
КоАП РО|Статья 48. Оставление места дорожно-транспортного происшествия (ДТП)|Штраф от 10.000 до 30.000 рублей либо лишение права управления|1
КоАП РО|Статья 49. Опасное вождение и создание аварийной ситуации|Штраф от 20.000 до 50.000 рублей|1
КоАП РО|Статья 50. Непредоставление преимущества транспортному средству экстренной службы со спецсигналами|Штраф от 15.000 до 30.000 рублей|1
КоАП РО|Статья 51. ч.1. Управление ТС без обязательной регистрации или гос. номеров|Штраф от 10.000 до 25.000 рублей|0
КоАП РО|Статья 51. ч.2. Использование заведомо подложного номерного знака|Штраф от 25.000 до 50.000 рублей|0
КоАП РО|Статья 52.1. Существенное превышение установленной скорости (более чем на 20 км/ч)|Штраф от 500 до 5.000 рублей|1
КоАП РО|Статья 52.2. Проезд на запрещающий сигнал или движение по встречной полосе|Штраф от 2.000 до 7.000 рублей|1
КоАП РО|Статья 52.3. Нарушение правил остановки или стоянки с созданием существенной помехи|Штраф от 1.000 до 5.000 рублей с перемещением ТС на штрафстоянку|1
КоАП РО|Статья 52.4. Повторное грубое нарушение правил дорожного движения (по ст. 49, 50, 52.1, 52.2)|Штраф от 20.000 до 40.000 рублей либо лишение права управления|1
КоАП РО|Статья 53. Эксплуатация технически опасного транспортного средства (тормоза, руль)|Штраф от 3.000 до 7.000 рублей с отстранением ТС до устранения|0
КоАП РО|Статья 54. Нарушение ПДД, повлекшее ДТП с имущественным ущербом без вреда здоровью|Штраф от 15.000 до 40.000 рублей с обязанностью возместить ущерб|0
    )
    LoadData(k4)

    k5 = 
    (
КоАП РО|Статья 55. ч.1. Невыполнение обязанностей в связи с ДТП (не остановился, не выставил знак)|Штраф от 5.000 до 15.000 рублей|0
КоАП РО|Статья 55. ч.2. Неоказание первой помощи либо невызов скорой при ДТП с пострадавшими|Штраф от 15.000 до 30.000 рублей|0
КоАП РО|Статья 55. ч.3. Употребление веществ/алкоголя после ДТП или остановки до освидетельствования|Штраф от 50.000 до 100.000 рублей с лишением прав до 30 дней (Суд)|0
КоАП РО|Статья 56. ч.1. Передача управления ТС лицу без права управления|Штраф от 10.000 до 25.000 рублей|0
КоАП РО|Статья 56. ч.2. Передача управления ТС лицу в состоянии опьянения|Штраф от 30.000 до 60.000 рублей|0
КоАП РО|Статья 57. Использование телефона или рации водителем при удержании рукой во время движения|Штраф от 1.000 до 30.000 рублей|0
КоАП РО|Статья 58. ч.1. Нарушение правил маневрирования (не подал поворотник, не уступил при перестроении)|Штраф от 500 до 2.000 рублей|0
КоАП РО|Статья 58. ч.2. Разворот, движение задним ходом в запрещенном ПДД месте|Штраф от 500 до 3.000 рублей|0
КоАП РО|Статья 58. ч.3. Нарушение правил маневрирования, создавшее реальную аварийную ситуацию|Штраф от 3.000 до 10.000 рублей|0
КоАП РО|Статья 59. ч.1. Непредоставление преимущества участнику движения на перекрестке|Штраф от 5.000 до 15.000 рублей|0
КоАП РО|Статья 59. ч.2. Выезд на перекресток при образовавшемся заторе с созданием поперечной помехи|Штраф от 5.000 до 15.000 рублей|0
КоАП РО|Статья 60. ч.1. Нарушение расположения ТС на проезжей части (обочина, разделительная полоса)|Штраф от 500 до 2.000 рублей|1
КоАП РО|Статья 60. ч.2. Движение ТС по тротуару, пешеходной или велосипедной дорожке|Штраф от 1.000 до 4.000 рублей|1
КоАП РО|Статья 60. ч.3. Движение ТС по тротуару, создавшее реальную угрозу жизни пешехода|Штраф от 20.000 до 40.000 рублей|1
КоАП РО|Статья 61. ч.1. Нарушение правил обгона и опережения без выезда на встречную полосу|Штраф от 2.000 до 6.000 рублей|0
КоАП РО|Статья 61. ч.2. Обгон на пешеходном переходе, переезде, мосту, в тоннеле|Штраф от 3.000 до 7.000 рублей|0
КоАП РО|Статья 62. Нарушение правил движения через железнодорожные пути (вне переезда, на запрещающий)|Штраф от 5.000 до 10.000 рублей|0
КоАП РО|Статья 63. Нарушение правил движения по автомагистрали (остановка, разворот, задний ход)|Штраф от 1.000 до 4.000 рублей (с аварией от 5.000 до 15.000 руб)|0
КоАП РО|Статья 64. ч.1. Незаконная установка или использование спецсигналов (мигалки, сирены)|Штраф от 20.000 до 50.000 рублей с конфискацией спецсигнала|0
КоАП РО|Статья 64. ч.2. Использование спецсигнала сотрудником без служебной необходимости|Штраф должностному лицу от 30.000 до 70.000 рублей (Прокуратура)|0
КоАП РО|Статья 65. Нарушение правил пользования внешними световыми приборами и звуковым сигналом|Штраф от 1.000 до 3.000 рублей|0
КоАП РО|Статья 66. ч.1. Нарушение правил дорожного движения пешеходом|Штраф от 500 до 3.000 рублей|1
КоАП РО|Статья 66. ч.2. Нарушение правил дорожного движения пешеходом, создавшее аварию|Штраф от 3.000 до 7.000 рублей|1
КоАП РО|Статья 67. ч.1. Несоблюдение требований дорожных знаков, разметки, стоп-линии|Штраф от 500 до 3.000 рублей|0
КоАП РО|Статья 67. ч.2. Несоблюдение требований дорожных знаков/разметки с созданием аварии|Штраф от 3.000 до 7.000 рублей|0
КоАП РО|Статья 68. Непредоставление преимущества пешеходу, велосипедисту или маршрутному ТС|Штраф от 2.000 до 6.000 рублей|0
КоАП РО|Статья 69. Нарушение правил буксировки, перевозки груза или пассажиров|Штраф от 5.000 до 15.000 рублей|0
КоАП РО|Статья 70. ч.1. Самовольное вклинивание в организованную транспортную колонну|Штраф от 10.000 до 25.000 рублей|1
КоАП РО|Статья 70. ч.2. Игнорирование требования покинуть колонну либо создание аварии|Штраф от 20.000 до 40.000 рублей|1
    )
    LoadData(k5)

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
УК РО|Статья 1.8. Состав преступления (объект, субъект, стороны, виды)|Материальные, формальные и усеченные составы преступлений|0
УК РО|Статья 1.9. Судимость|Штраф не влечет судимости; судимость запрещает государственную службу|0
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
УК РО|Статья 5. Виды наказаний|Судебный/уголовный штраф, лишение права, увольнение, тюрьма, работы|0
УК РО|Статья 5.1. Исправительные работы|Назначаются по основному месту работы либо в местах, определяемых судом|0
УК РО|Статья 5.1.2. Принудительные работы|Применяются как альтернатива лишению свободы с привлечением к труду|0
УК РО|Статья 5.2. Общие начала назначения наказания|Внесудебно лишение свободы не более 5 лет (за исключением ст. 17.3 УК)|0
УК РО|Статья 5.2.1. Назначение наказания за неоконченное преступление|Приготовление не более половины, покушение не более 3/4 максимума|0
УК РО|Статья 5.3. Обстоятельства, смягчающие наказание|Принуждение, явка с повинной, помощь потерпевшему, возмещение ущерба|0
УК РО|Статья 5.4. Обстоятельства, отягчающие наказание|Группа лиц, вражда, месть служащему, особая жестокость, форма, опьянение|0
УК РО|Статья 5.5. Назначение более мягкого наказания|Ниже низшего предела при исключительных обстоятельствах|0
УК РО|Статья 5.6. Освобождение в связи с назначением штрафа/работ или примирением|Впервые совершившее лицо может быть освобождено судом со штрафом от 10.000|0
УК РО|Статья 5.7. Сроки давности привлечения к уголовной ответственности|15 лет (15 дней); розыск боло-приоритета от 1 до 5 звезд|0
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
УК РО|Статья 10.6 (Ф/Р) Разбойное ограбление с применением опасного насилия|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 10.6.1 (Ф/Р) Разбойное ограбление крупных финансовых объектов (банки)|до 50 месяцев с созданием записи о судимости (5 звезд)|1
УК РО|Статья 10.7 (Р) Неправомерное завладение ТС (угон/поездка без цели хищения)|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 10.7.1 (Р) Завладение государственным или оперативным служебным ТС|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 10.8 (Р) Умышленные уничтожение или повреждение чужого имущества|до 20 месяцев лишения свободы (2 звезды)|1
УК РО|Статья 10.8.1 (Ф/Р/С) Умышленные уничтожение или повреждение государственного имущества|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 10.9 (Ф/Р) Уничтожение чужого имущества путем поджога, взрыва|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 10.10 (Ф) Вымогательство под угрозой насилия или уничтожения имущества|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 10.11 (Ф/С) Незаконное изъятие имущества или лицензий сотрудником органов|от штрафа до 30 месяцев с возмещением ущерба (3 звезды)|0
УК РО|Статья 10.12 (Ф/Р) Кража с проникновением в частное жилище или помещение|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 10.12.1 (Ф/Р) Кража группой лиц с проникновением в жилище|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 11.1 (Ф/С) Предпринимательская деятельность без регистрации|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 11.2 (Ф/С) Принуждение к совершению сделки без оружия|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 11.2.1 (Ф/С) Принуждение к сделке с применением огнестрельного оружия|до 30 месяцев лишения свободы (3 звезды)|0
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
УК РО|Статья 12.5 (Ф/Р/С) Организация массовых беспорядков или участие в них|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.5.1 (Ф/Р/С) Массовые беспорядки с причинением ущерба или смерти|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.6 (Р) Хулиганство, грубое систематическое нарушение порядка|до 20 месяцев лишения свободы (2 звезды)|1
УК РО|Статья 12.7 (Ф/Р/С) Незаконное проникновение на закрытый объект РО|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 12.7.1 (Ф/Р/С) Незаконное проникновение на режимный объект со спецстатусом|до 50 месяцев с созданием записи о судимости (5 звезд)|1
УК РО|Статья 12.7.2 (Ф) Проникновение на территорию оцепления военного или ЧП положения|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.8 (Ф/Р/С) Незаконный оборот оружия, боеприпасов и легких бронежилетов|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 12.8.1 (Ф/Р/С) Незаконный оборот спецсредств государства (дефибрилляторы, тяжелая броня)|до 50 месяцев с созданием записи о судимости (5 звезд)|1
УК РО|Статья 12.9 (Ф/Р) Хищение огнестрельного оружия, комплектующих или взрывчатки|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 12.9.1 (Ф) Хищение оружия со склада улик сотрудниками органов|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.10 (Ф/С) Организация несанкционированных митингов или призывы к бунту|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.11 (Ф/С) Организация геноцида либо попытка его организации|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.12 (Ф/С) Создание преступной организации либо руководство ею|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.13 (Ф/С) Подрыв нацбезопасности, вывод средств в офшоры, спонсирование террористов|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 12.14 (Ф/С) Публичные призывы к нарушению территориальной целостности РО|до 40 месяцев с созданием записи о судимости (4 звезды)|0
    )
    LoadData(u5)

    u6 = 
    (
УК РО|Статья 12.15 (Ф/Р/С) Участие в несанкционированных митингах и шествиях|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 12.15.1 (Ф/Р/С) Участие в несанкционированном митинге с игнорированием требований|до 50 месяцев лишения свободы (5 звезд)|0
УК РО|Статья 13.1 (Ф/С) Незаконное кустарное производство и сбор наркотиков|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 13.2 (Ф/Р/С) Незаконное хранение, приобретение, перевозка наркотиков (свыше 3 г)|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 13.3 (Ф/С) Незаконный оборот наркотиков в особо крупном размере (свыше 20 г)|до 50 месяцев с созданием записи о судимости (5 звезд)|1
УК РО|Статья 13.4 (Р/С) Пропаганда наркотических средств или растений|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 13.5 (Ф/С) Оборот наркотических средств сотрудниками госструктур|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 13.6 (Ф/С) Оборот синтетических наркотических веществ|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 13.7 (Ф/Р/С) Незаконный сбыт и распространение наркотических средств|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 14.1 (Ф/Р/С) Посягательство на жизнь государственного или общественного деятеля|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.2 (Ф/Р/С) Насильственный захват власти или вооруженный мятеж|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.2.1 (Ф/С) Агитация или руководство движением по захвату власти|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 14.3 (Ф/С) Разглашение сведений, составляющих государственную тайну|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.4 (Ф/С) Приобретение, сбыт или использование формы госструктур, жетонов|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 14.5 (Ф/С) Государственная измена / шпионаж|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.6 (Ф/С) Утрата документов, содержащих государственную тайну|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 14.7 (Ф/С) Нарушение законодательства о выборах, подлог документов|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 14.8 (Ф/С) Незаконный оборот государственных секретов и закрытых данных|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 14.9 (Ф/С) Продажа, хранение глушащих устройств и радар-детекторов|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 15.1 (Ф/С) Превышение должностных полномочий|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 15.1.1 (Ф/С) Злоупотребление служебными полномочиями|до 50 месяцев с созданием записи о судимости (5 звезд)|1
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
УК РО|Статья 16.1 (Ф/С) Вмешательство в деятельность суда или следствия|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 16.1.2 (Ф/С) Воспрепятствование деятельности прокурора или следователя|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 16.2 (Ф/С) Посягательство на жизнь судьи, прокурора, следователя|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 16.3 (Ф/Р/С) Неуважение к суду и участникам судебного заседания|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 16.4 (Ф/С) Привлечение заведомо невиновного к уголовной ответственности|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 16.4.1 (Ф/С) Привлечение заведомо невиновного к административной ответственности|до 30 месяцев лишения свободы (3 звезды)|0
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
УК РО|Статья 17.4 (Р) Перевозка товаров без коммерческих документов или с поддельными|до 20 месяцев лишения свободы (2 звезды)|0
УК РО|Статья 17.4.1 (Р) Подделка документов, лицензий, печатей и бланков|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 17.5 (Ф/С) Самоуправство (самовольные действия вопреки закону)|до 50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 17.6 (Ф/Р/С) Неподчинение законным требованиям сотрудника силовых структур|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 17.7 (Ф/С) Укрывательство преступника или следов преступления|до 40 месяцев с созданием записи о судимости (4 звезды)|0
УК РО|Статья 17.8 (Р) Грубое оскорбление человека в присутствии представителя власти|до 10 месяцев лишения свободы (1 звезда)|1
УК РО|Статья 17.9 (Ф/Р/С) Незаконная помеха задержанию или процессуальным действиям|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 17.10 (Ф/Р/С) Помеха задержанию со стороны сотрудника госструктур|до 50 месяцев с созданием записи о судимости (5 звезд)|1
УК РО|Статья 17.11 (Ф/Р/С/В) Провокация сотрудников Армии / помеха на КПП|до 30 месяцев лишения свободы (3 звезды)|0
УК РО|Статья 17.12 (Ф/Р/В) Помеха движению организованной государственной колонны|до 30 месяцев лишения свободы (3 звезды)|1
УК РО|Статья 17.12.1 (Ф/Р/В) Помеха госструктурам во время перевозки материалов|50 месяцев с созданием записи о судимости (5 звезд)|0
УК РО|Статья 17.13 (Ф/Р) Побег или сопротивление при аресте / задержании|до 40 месяцев с созданием записи о судимости (4 звезды)|1
УК РО|Статья 17.14 (Р) Браконьерство / отлов редких видов животных и растений|до 30 месяцев лишения свободы (3 звезды)|0
    )
    LoadData(u8)

    p1 = 
    (
ПК РО|Глава I. Статья 1. Следственные действия и поводы к проверке|Очевидец, сообщение потерпевшего/граждан, следы, принятое заявление|0
ПК РО|Глава I. Статья 2. Принципы расследования (Адекватность и Безотлагательность)|Профессионализм, отсутствие промедлений, точные умозаключения|0
ПК РО|Глава I. Статья 3. Передача дела уполномоченному сотруднику|Передача подозреваемого и изложение всех известных обстоятельств|0
ПК РО|Глава I. Статья 4. Письменная отчетность и упрощенный порядок|При упрощенном разрешении дело не оформляется (видеофиксация 48 ч)|0
ПК РО|Глава I. Статья 5. Перечень следственных действий (п. а - о)|Возбуждение дела, допрос, осмотр, экспертиза, эксперимент, обыск, выемка, рейд|0
ПК РО|Глава I. Статья 6.1. Оперативно-розыскные мероприятия (ОРМ)|Опрос, наведение справок, закупка, наблюдение, внедрение, ориентировка|0
ПК РО|Глава I. Статья 6.2. Порядок применения перечня ОРМ|Применяется с учетом федерального законодательства РО|0
ПК РО|Глава I. Статья 6.3. Применение средств ограничения подвижности (наручников)|Для задержания, привода; распространяется процессуальный час|0
ПК РО|Глава I. Статья 7. Понятие процессуального действия|Отдельная операция уполномоченного лица по проверке или задержанию|0
ПК РО|Глава I. Статья 7.1. Виды процессуальных действий|Досмотр, обыск, задержание, арест, штрафы, лицензии, сила, спецсредства|0
ПК РО|Глава I. Статья 7.1.1. Разграничение досмотра и обыска|Досмотр — с согласия; Обыск — без согласия при законных основаниях|0
ПК РО|Глава I. Статья 8. Рейд (основание, оцепление объекта)|Проводится на основании судебного акта или постановления прокурора|0
ПК РО|Глава I. Статья 9. Пределы следственных действий государственного сотрудника|Строго в рамках и пределах предоставленных должностных полномочий|0
ПК РО|Глава I. Статья 10. Подследственность СК, ФСБ, Прокуратуры|Материалы передаются по подследственности без необоснованной задержки|0
ПК РО|Глава I. Статья 11. Самостоятельность Следственного комитета и надзор прокуратуры|Прокурор проверяет законность, но не руководит следствием СК|0
ПК РО|Глава I. Статья 12. Возбуждение уголовного дела и принятие к производству|Возбуждается следователем при достаточных данных о преступлении|0
ПК РО|Глава I. Статья 13. Срок предварительного расследования|Обычный срок до 96 часов; продление до 7 дней; далее через суд|0
ПК РО|Глава I. Статья 14. Окончание предварительного расследования|Обвинительное заключение, передача в суд, прокуратуру либо прекращение|0
ПК РО|Глава II. Статья 1. Задержание подозреваемого (основания п. а - ж)|Ограничение свободы до 1 часа для сбора доказательств во внесудебном порядке|0
ПК РО|Глава II. Статья 1.1. Процедура установки личности (отказ от документов / маска)|Наручники -> основание -> базы данных -> фоторобот -> первичный обыск|0
ПК РО|Глава II. Статья 2. Порядок задержания лица (12 обязательных пунктов)|Наручники -> опознавательный знак -> обыск -> выемка -> статьи -> Миранда -> ИВС|0
ПК РО|Глава II. Статья 2.1. Отступление от точного порядка задержания|Допускается при ЧП, но все ключевые пункты обязаны быть выполнены|0
ПК РО|Глава II. Статья 2.2. Удаление инородных предметов с лица задержанного|Разрешается снять маску или предмет, скрывающий внешность|0
ПК РО|Глава II. Статья 2.3. Запрос содействия по связи для вызова адвоката/прокурора|Обязанность запросить помощь коллег при отсутствии прямого доступа к каналу|0
ПК РО|Глава II. Статья 2.4. Первичный обыск при задержании|Поиск и временное изъятие оружия, наркотиков, взрывчатки и ножей|0
    )
    LoadData(p1)

    p2 = 
    (
ПК РО|Глава II. Статья 2.5. Освобождение при неподтверждении оснований|Ограничение свободы немедленно прекращается|0
ПК РО|Глава II. Статья 2.5.1. Возврат временно изъятых для безопасности предметов|Возвращаются законному владельцу после отпадения оснований удержания|0
ПК РО|Глава II. Статья 2.6. Выемка предметов и документов|Принудительное изъятие вещей, имеющих значение для дела или безопасности|0
ПК РО|Глава II. Статья 2.7. Порядок передачи задержанного между сотрудниками|Передаются основания, предварительная квалификация, улики и видеозапись|0
ПК РО|Глава II. Статья 2.7.1. Передача задержанного по подследственности СК или ФСБ|Сотрудник МВД не разрешает дело, а вызывает уполномоченного сотрудника|0
ПК РО|Глава II. Статья 2.8. Проверка неприкосновенности и специального статуса|Удостоверение осматривается до совершения следственных действий|0
ПК РО|Глава II. Статья 2.9. Упрощенное разрешение уголовного материала непосредственно при задержании|До 5 лет лишения свободы по общей подследственности (без дела и штрафа)|0
ПК РО|Глава II. Статья 3.1. Вызов государственного адвоката на задержание|Ожидание ответа по рации 3 минуты; при отсутствии — продолжение|0
ПК РО|Глава II. Статья 3.2. Ожидание прибытия государственного адвоката|При подтверждении процессуальный час приостанавливается до 10 минут|0
ПК РО|Глава II. Статья 3.3. Вызов частного адвоката|Приостановка процессуального часа на срок ожидания не более 10 минут|0
ПК РО|Глава II. Статья 3.4. Отказ задержанного от услуг адвоката|Право на защиту считается реализованным при осознанном отказе лица|0
ПК РО|Глава II. Статья 4.1. Участие прокурора и СК при задержании государственного служащего|Изучение улик, видеозаписей; прокурор принимает обязательное решение|0
ПК РО|Глава II. Статья 4.2. Срок ожидания прокурора при задержании гос. служащего|Ожидание не более 15 минут; при неприбытии лицо освобождается|0
ПК РО|Глава II. Статья 4.3. Неподтверждение вызова прокуратурой за 15 минут|Задержанный гос. служащий подлежит немедленному освобождению|0
ПК РО|Глава II. Статья 4.4. Полномочия прокурора по итогам задержания служащего|Освобождение, изменение статей, назначение штрафа, ареста, передача в СК|0
ПК РО|Глава II. Статья 4.5. Освобождение служащего при отсутствии оснований|Прокуратура вправе проверить законность действий задерживавших сотрудников|0
ПК РО|Глава II. Статья 4.6. Обжалование решения прокурора на задержании|Подается вышестоящему прокурору или в суд; исполнение не приостанавливается|0
ПК РО|Глава II. Статья 4.7. Исполнение ранее вынесенного прокурорского акта|Повторный вызов прокурора на место не требуется при действующем решении|0
ПК РО|Глава II. Статья 4.8. Увольнение служащего после начала задержания|Не отменяет обязательную специальную прокурорскую процедуру|0
ПК РО|Глава II. Статья 4.9. Совместное участие прокурора и следователя СК|Окончательное решение по делу выносит сотрудник прокуратуры|0
ПК РО|Глава II. Статья 5. Уведомление госоргана о задержании его служащего|Информационный характер, не приостанавливает сроки задержания|0
ПК РО|Глава II. Статья 6. Разъяснение процессуальных прав (Правило Миранды)|Право на молчание, звонок (3 мин), адвоката (10 мин конфиденциально)|0
ПК РО|Глава II. Статья 7. Основания освобождения подозреваемого|Не подтвердилось, штраф уплачен, истек 1 час, неприкосновенность|0
ПК РО|Глава II. Статья 7.1. Основания приостановления процессуального часа|Допрос, адвокат, прокурор, доп. проверка (до 20 мин), суд. проверка|0
ПК РО|Глава II. Статья 8. Субъекты задержания (круг лиц с правом присутствия)|Сотрудники, задержанный, адвокат, прокурор, СК, ФСБ, Губернатор|0
    )
    LoadData(p2)

    p3 = 
    (
ПК РО|Глава II. Статья 8.1. Запрет вмешательства посторонних лиц в процессуальные действия|Требование отойти на безопасное расстояние обязательно к исполнению|0
ПК РО|Глава II. Статья 9. Права задерживаемого лица (звонок 3 мин, адвокат 10 мин)|Право хранить молчание, право знать статьи и обжаловать действия|0
ПК РО|Глава II. Статья 10. Обязанности сотрудника (хранение видеозаписи 48 часов)|Обязанность вести видеофиксацию и предоставить ее адвокату/прокурору|0
ПК РО|Глава II. Статья 11. Задержание во исполнение судебного или прокурорского акта|Повторное рассмотрение не требуется; права задержанного сохраняются|0
ПК РО|Глава III. Статья 1. Порядок исполнения административного ареста|Личный обыск, выемка запрещенных вещей, водворение в ИВС|0
ПК РО|Глава III. Статья 2. Административный арест государственного служащего|Разрешается исключительно прокурором в порядке главы II ПК|0
ПК РО|Глава III. Статья 2.1. Обжалование административного ареста|Вышестоящему прокурору либо в судебном порядке|0
ПК РО|Глава III. Статья 2.2. Исполнение ранее вынесенного акта об адм. аресте|Повторное рассмотрение прокурором на месте не требуется|0
ПК РО|Глава III. Статья 3. Передача задержанного для административного ареста|Передается уполномоченному лицу вместе со всеми материалами|0
ПК РО|Глава IV. Статья 1. Основания уголовного ареста|Решение прокурора, санкция на арест, решение суда, упрощенный порядок|0
ПК РО|Глава IV. Статья 2. Порядок исполнения уголовного ареста|Полный обыск, выемка, помещение в камеру ИВС / места содержания|0
ПК РО|Глава IV. Статья 3. Арест государственного служащего|Обязательное прокурорское рассмотрение до помещения под арест|0
ПК РО|Глава IV. Статья 3.1. Исполнение судебного акта или прокурорской санкции|Прямое исполнение без повторного рассмотрения оснований|0
ПК РО|Глава IV. Статья 3.2. Прокурорская санкция на арест (Генпрокурор, старший прокурор)|Основание для объявления в розыск, задержания и помещения под арест|0
ПК РО|Глава IV. Статья 3.3. Обжалование прокурорской санкции на арест|Обжалуется вышестоящему прокурору либо в суд|0
ПК РО|Глава IV. Статья 3.4. Лица со специальным процессуальным статусом (неприкосновенность)|Арест и следственные действия только по специальной процедуре|0
ПК РО|Глава IV. Статья 4. Передача лица для исполнения уголовного ареста|Передается с материалами и основаниями задержания|0
ПК РО|Глава V. Статья 1. Основания и законные цели личного обыска|Установление личности, поиск оружия, опасных и запрещенных предметов|0
ПК РО|Глава V. Статья 1.1. Первичный обыск при задержании|Обеспечение безопасности; временное изъятие не является конфискацией|0
ПК РО|Глава V. Статья 1.2. Обыск перед помещением под арест|Полный личный обыск с изъятием всех запрещенных в изоляторе вещей|0
ПК РО|Глава V. Статья 2. Обыск жилища и частной территории|По судебному решению; в неотложных случаях — с уведомлением за 1 час|0
ПК РО|Глава V. Статья 3. Обыск транспортного средства без ордера суда|Погоня, ориентировка, запрещенные предметы у водителя, охраняемый объект|0
ПК РО|Глава V. Статья 4. Досмотр при проходе на охраняемый государственный объект|Пропускной режим; добровольность (отказ = покинуть территорию)|0
ПК РО|Глава V. Статья 5. Режим военных и охраняемых территорий|Специальный режим; право требовать досмотр или выдворение посторонних|0
ПК РО|Глава V. Статья 6. Вызов и доставление лица на допрос|Повестка, постановление; задержанный доставляется без повестки|0
    )
    LoadData(p3)

    p4 = 
    (
ПК РО|Глава V. Статья 7. Порядок проведения допроса|Разъяснение прав, участие адвоката, категорический запрет насилия и угроз|0
ПК РО|Глава V. Статья 8. Фиксация и хранение записи допроса (48 часов)|Непрерывная аудио-видеозапись; хранение не менее 48 часов|0
ПК РО|Глава V. Статья 9. Допустимость показаний допрашиваемого|Только добровольные показания с разъяснением прав имеют силу|0
ПК РО|Глава V. Статья 10. Заявление о незаконном давлении при допросе|Проверка записи прокурором/судом; признание улик недопустимыми|0
ПК РО|Глава V. Статья 11. Обязанность явки по законному вызову|Неявка без уважительной причины влечет принудительный привод|0
ПК РО|Глава V. Статья 12. Порядок осуществления привода|Принудительное доставление к следователю, прокурору или в суд|0
ПК РО|Глава VI. Статья 1. Презумпция невиновности|Бремя доказывания на следствии; неустранимые сомнения в пользу обвиняемого|0
ПК РО|Глава VI. Статья 2. Законность и допустимость доказательств|Улики, добытые с насилием или без ордера, признаются недопустимыми|0
ПК РО|Глава VI. Статья 3. Оценка доказательств по совокупности|Никакое доказательство не имеет заранее установленной силы|0
ПК РО|Глава VI. Статья 4. Приоритет специальной нормы над общей|Специальная процедура имеет верховенство над общим порядком|0
ПК РО|Глава VII. Статья 1. Обязательная видеофиксация процессуальных действий|Задержание, арест, обыски, допросы, применение силы, изъятие лицензий|0
ПК РО|Глава VII. Статья 2. Требования к видеозаписи|Непрерывность, различимость лиц и обстоятельств; запрет монтажа|0
ПК РО|Глава VII. Статья 3. Срок хранения видеофиксации (не менее 48 часов)|При наличии жалобы или суда — хранится до окончания дела|0
ПК РО|Глава VII. Статья 4. Истребование и предоставление записи|Обязанность передать запись по запросу суда, прокурора или адвоката|0
ПК РО|Глава VII. Статья 5. Последствия отсутствия обязательной записи|Бремя объяснения на сотруднике; возможная отмена всех решений|0
ПК РО|Глава VIII. Статья 1. Обязанность разъяснения прав участникам производства|Суд, прокурор, следователь обязаны разъяснить все процессуальные права|0
ПК РО|Глава VIII. Статья 2. Защита участников производства (свидетелей, потерпевших)|Меры гос. защиты при угрозе жизни или здоровью|0
ПК РО|Глава VIII. Статья 3. Немедленное прекращение незаконного ограничения свободы|Немедленное освобождение при отпадении законных оснований|0
ПК РО|Глава VIII. Статья 4. Безопасность задержанного и оказание медпомощи|Обеспечение безопасных условий; неотложная помощь врачей при травмах|0
ПК РО|Глава VIII. Статья 5. Тайна переписки и телефонных переговоров|Ограничение допускается исключительно по решению суда|0
ПК РО|Глава VIII. Статья 6. Запрет необоснованного затягивания процессуальных действий|Запрет избыточных маршрутов доставки и искусственных задержек|0
ПК РО|Глава IX. Статья 1. Срок и формы обжалования (48 часов)|Жалоба подается в течение 48 часов в прокуратуру или суд|0
ПК РО|Глава IX. Статья 2. Порядок обжалования действий в прокуратуру|Прокурорская проверка, отмена мер, направление дела по подследственности|0
ПК РО|Глава IX. Статья 3. Судебный порядок обжалования|Суд вправе признать действие незаконным и отменить индивидуальный акт|0
ПК РО|Глава IX. Статья 4. Обжалование решений прокурора|Вышестоящему прокурору либо в суд (решения Генпрокурора — только в суд)|0
    )
    LoadData(p4)

    p5 = 
    (
ПК РО|Глава IX. Статья 5. Обжалование следственных решений СК|Руководителю следственного органа либо в суд|0
ПК РО|Глава IX. Статья 6. Последствия признания действия незаконным|Немедленное освобождение гражданина и возврат изъятого имущества|0
ПК РО|Глава X. Статья 1. Понятие сделки со следствием (досудебное соглашение)|Добровольное содействие раскрытию преступлений в обмен на смягчение|0
ПК РО|Глава X. Статья 2. Инициатива и порядок предложения соглашения|Предлагается следователем, прокурором или задерживающим сотрудником|0
ПК РО|Глава X. Статья 3. Содержание соглашения о сотрудничестве|Конкретные действия, правдивые показания, пределы смягчения наказания|0
ПК РО|Глава X. Статья 4. Заключение и утверждение соглашения прокурором|Обязательное утверждение прокурором после проверки добровольности|0
ПК РО|Глава X. Статья 5. Порядок исполнения соглашения сотрудничающим лицом|Дача показаний, очные ставки, участие в оперативных действиях|0
ПК РО|Глава X. Статья 6. Правовые последствия исполнения соглашения|Учет судом смягчающих обстоятельств строго в рамках УК РО|0
ПК РО|Глава X. Статья 7. Ответственность за неисполнение соглашения или ложь|Аннулирование всех преимуществ сделки и рассмотрение дела на общих основаниях|0
ПК РО|Глава X. Статья 8. Конфиденциальность и безопасность сотрудничающего лица|Государственная тайна и меры безопасности для участника сделки|0
ПК РО|Глава XI. Статья 1. Законодательство об устных требованиях и силе|Обязательно для соблюдения всеми государственными служащими РО|0
ПК РО|Глава XI. Статья 2. Требования к устному законному распоряжению|Повелительное наклонение, однозначность, конкретность, исполнимость|0
ПК РО|Глава XI. Статья 3. Иерархия требований (взаимоисключающие распоряжения)|Исполнению подлежит требование, озвученное последним по времени|0
ПК РО|Глава XI. Статья 4. Основания применения физической силы и спецсредств (тазер)|Соразмерность; преодоление сопротивления; запрет силы при обычном штрафе|0
ПК РО|Глава XI. Статья 5. Основания применения смертельной силы (огнестрельного оружия)|Непосредственная угроза жизни; категорический запрет предупредительных выстрелов|0
ПК РО|Глава XI. Статья 6. Остановка ТС через мегафон (3 требования) и принудительная остановка|Таран, тазер, стрельба по колесам при неподчинении требованиям мегафона|0
ПК РО|Глава XII. Статья 1. Непрерывность процессуальных действий сотрудника|Запрет срыва процессуальных действий другими сотрудниками / запрет фиктивных мер|0
ПК РО|Глава XIII. Статья 1. Соотношение Процессуального кодекса с иными законами|Верховенство процессуальных гарантий Конституции и федеральных кодексов|0
ПК РО|Глава XIII. Статья 2. Исчисление и фиксация процессуальных сроков|Приостановление строго по закону; обязательная поминутная фиксация|0
    )
    LoadData(p5)

    pd1 = 
    (
ПДД РО|Пункт 1.1 - 1.2. Обязанности участников движения соблюдать ПДД|Правила поведения на дорогах; ответственность по КоАП РО|0
ПДД РО|Пункт 1.3. Правостороннее движение|Дорожное движение на всей территории РО является правосторонним|0
ПДД РО|Пункт 1.4. Термины: Дорога, проезжая часть, полоса, обочина|Определения элементов обустроенной дороги|0
ПДД РО|Пункт 1.4. Термины: Разделительная полоса, перекресток, прилегающая территория|Определения зон пересечения и границ дорожной сети|0
ПДД РО|Пункт 1.4. Термины: Пешеходный переход, обгон, опережение|Разграничение выезда на встречную полосу (обгон) и опережения попутных ТС|0
ПДД РО|Пункт 1.4. Термины: Остановка (до 5 мин), стоянка (более 5 мин)|Разграничение преднамеренного прекращения движения ТС|0
ПДД РО|Пункт 1.4. Термины: Уступить дорогу, ДТП, автомагистраль, колонна ТС|Определения приоритета и особых категорий движения|0
ПДД РО|Пункт 1.5. Принцип взаимной безопасности на дороге|Запрет создания опасности и необоснованных помех другим лицам|0
ПДД РО|Пункт 2.1. Обязанность водителя иметь и предъявлять права и документы на ТС|Предъявление по первому законному требованию сотрудника ГИБДД|0
ПДД РО|Пункт 2.2. Управление ТС с государственными регистрационными знаками|Номера обязаны соответствовать учету и быть установленными|0
ПДД РО|Пункт 2.3 - 2.4. Остановка по требованию ГИБДД и выход из автомобиля|Остановка в безопасном месте и выполнение законных требований|0
ПДД РО|Пункт 2.5. Запреты на управление ТС (опьянение, без прав, неисправность)|Запрещено садиться за руль в опьянении, утомлении или без прав|0
ПДД РО|Пункт 2.6. Запрет передачи управления лицу без прав или в опьянении|Владелец ТС несет прямую ответственность по КоАП|0
ПДД РО|Пункт 2.7. Обязанность водителя пройти освидетельствование на опьянение|Проверка на состояние опьянения при наличии законных оснований|0
ПДД РО|Пункт 2.8. Запрет использования телефона без гарнитуры во время движения|Запрещено удерживать телефон или радиостанцию рукой за рулем|0
ПДД РО|Пункт 2.9 - 2.10. Безопасная дистанция, запрет опасного вождения|Ответственность по статье 49 КоАП РО|0
ПДД РО|Пункт 2.11. Запрет самовольного вклинивания в организованную колонну ТС|Ответственность по статье 70 КоАП РО|0
ПДД РО|Пункт 3.1 - 3.2. Первоочередные действия водителя при совершении ДТП|Остановиться, включить аварийку, выставить знак, не сдвигать предметы|0
ПДД РО|Пункт 3.3. Действия при ДТП с пострадавшими|Первая помощь, вызов скорой помощи и инспекторов ГИБДД|0
ПДД РО|Пункт 3.4 - 3.5. Оформление ДТП только с материальным ущербом|Фото-видеофиксация; при споре обязателен вызов ГИБДД|0
ПДД РО|Пункт 3.6. Категорический запрет оставления места ДТП|Лишение права управления по ст. 48 КоАП РО|0
ПДД РО|Пункт 3.7. Запрет употребления веществ/алкоголя после совершения ДТП|Запрещено употреблять алкоголь до проведения освидетельствования|0
ПДД РО|Пункт 4.1 - 4.2. Право отступать от правил при синих/красных маячках и сирене|Преимущество предоставляется только при одновременной сирене и маячках|0
ПДД РО|Пункт 4.3 - 4.4. Обязанность уступить дорогу спецтранспорту с сиреной|Снизить скорость при приближении к стоящему спецтранспорту с маячками|0
ПДД РО|Пункт 4.5 - 4.6. Желтые и оранжевые проблесковые маячки|Преимущества не дают; используются для эвакуаторов, дорожных служб|0
    )
    LoadData(pd1)

    pd2 = 
    (
ПДД РО|Пункт 5.1 - 5.4. Значения сигналов светофора (зеленый, желтый, красный)|Остановка перед стоп-линией на запрещающий сигнал светофора|0
ПДД РО|Пункт 5.5 - 5.6. Сигналы регулировщика и их приоритет над светофором и знаками|Регулировщик имеет высший приоритет на участке движения|0
ПДД РО|Пункт 6.1 - 6.6. Начало движения, маневрирование, поворотники|Заблаговременная подача сигналов; занять крайнее положение на проезжей части|0
ПДД РО|Пункт 6.7. Места запрета разворота ТС|Пешеходные переходы, тоннели, мосты, эстакады, ж/д переезды, видимость менее 100 м|0
ПДД РО|Пункт 6.8. Движение задним ходом и места запрета|Запрещено на перекрестках, переходах, ж/д путях, мостах, автомагистралях|0
ПДД РО|Пункт 7.1 - 7.3. Расположение ТС на дороге и запрет встречной полосы|Движение по правой стороне; соблюдение полос движения|0
ПДД РО|Пункт 7.4. Запрет движения по обочине, разделительной полосе, тротуарам|Штрафы по статье 60 КоАП РО|0
ПДД РО|Пункт 7.5 - 7.6. Движение тихоходного транспорта|Обязан двигаться по крайней правой полосе|0
ПДД РО|Пункт 8.1. Выбор безопасной скорости движения|С учетом дорожного покрытия, видимости, погоды и груза|0
ПДД РО|Пункт 8.2. Лимиты скорости: Город 60 | Трасса 90 | Магистраль 110 | Буксир 50|Базовые скоростные режимы в РО|0
ПДД РО|Пункт 8.4. Существенное превышение скорости (более чем на 20 км/ч)|Ответственность по статье 52.1 КоАП РО|0
ПДД РО|Пункт 8.5. Запреты при выборе скорости|Запрет резких торможений и беспричинного создания помех медленной ездой|0
ПДД РО|Пункт 9.1 - 9.2. Правила обгона и запрет препятствования обгону|Запрещено ускоряться водителю обгоняемого автомобиля|0
ПДД РО|Пункт 9.3. Места запрета обгона с выездом на встречную полосу|Пешеходный переход, ж/д переезд, тоннель, мост, подъем, знак «Обгон запрещен»|0
ПДД РО|Пункт 9.4. Опережение попутного транспорта без выезда на встречную полосу|Разрешено при обеспечении полной безопасности маневра|0
ПДД РО|Пункт 10.1 - 10.4. Общие правила приоритета и преимущество маршрутных ТС|Уступи дорогу пешеходам при повороте и автобусу от остановки|0
ПДД РО|Пункт 11.1 - 11.3. Проезд регулируемых перекрестков и запрет выезда в затор|Запрещено выезжать на перекресток при образовавшейся пробке|0
ПДД РО|Пункт 11.4 - 11.6. Проезд нерегулируемых перекрестков (главная дорога, помеха справа)|Уступить транспорту на главной дороге; на равнозначных — помеха справа|0
ПДД РО|Пункт 12.1 - 12.5. Обязанности пешеходов при движении и спецсигналах|Переход по пешеходному переходу; освободить проезжую часть при сирене|0
ПДД РО|Пункт 13.1 - 13.4. Обязанности водителей перед пешеходами|Пропуск пешеходов на переходах; запрет обгона на пешеходном переходе|0
ПДД РО|Пункт 14.1 - 14.5. Правила для велосипедистов и пассажиров ТС|Спешивание велосипедистов на переходах; посадка со стороны тротуара|0
ПДД РО|Пункт 15.1 - 15.4. Движение через железнодорожные переезды|Запрет выезда на закрытый шлагбаум; запрет разворота, стоянки, обгона|0
ПДД РО|Пункт 16.1 - 16.2. Движение по автомагистралям|Запрет движения пешеходов, мопедов, заднего хода, разворота в разделительную|0
ПДД РО|Пункт 17.1 - 17.3. Правила остановки и стоянки ТС|Остановка справа у края дороги параллельно бордюру в один ряд|0
ПДД РО|Пункт 17.4 - 17.5. Места, где остановка и стоянка категорически запрещены|Пешеходные переходы, мосты, тоннели, перекрестки, остановки, тротуары|0
ПДД РО|Пункт 17.6. Задержание и эвакуация транспортного средства|При создании существенной помехи движению по КоАП РО|0
ПДД РО|Пункт 18.1 - 18.3. Включение внешних световых приборов и фар|Ближний свет в темное время суток; переключение на ближний при разъезде|0
ПДД РО|Пункт 19.1 - 19.3. Порядок использования звукового сигнала|Разрешен только для предотвращения ДТП либо обгона вне города|0
ПДД РО|Пункт 20.1 - 20.4. Правила буксировки механических ТС|Скорость буксировки не более 50 км/ч; включенная аварийная сигнализация|0
ПДД РО|Пункт 21.1 - 21.4. Правила перевозки пассажиров и грузов|Груз не должен закрывать обзор, номера, фары и угрожать падением|0
ПДД РО|Пункт 22.1 - 22.5. Техническое состояние ТС и допуск к движению|Запрет езды при неисправности тормозов, руля или фар; гос. номера обязательны|0
ПДД РО|Пункт 23.1 - 23.4. Дорожные знаки (STOP, Уступи дорогу, Ограничение скорости)|Обязательны к соблюдению всеми водителями|0
ПДД РО|Пункт 24.1 - 24.9. Дорожная разметка (сплошная, двойная сплошная, стоп-линия)|Запрет пересечения сплошной линии разметки|0
ПДД РО|Пункт 25.1 - 25.5. Заключительные положения и вступление ПДД в силу|Полномочия сотрудников ГИБДД; ответственность по КоАП и УК РО|0
    )
    LoadData(pd2)

    pl1 = 
    (
ФЗ О Полиции|Статья 1. Полиция РО в системе МВД РО|Защита жизни, здоровья, прав, свобод, борьба с преступностью и охрана порядка|0
ФЗ О Полиции|Статья 2. Правовая основа деятельности полиции|Конституция РО, федеральные законы и кодексы; запрет произвольных ограничений|0
ФЗ О Полиции|Статья 3. Основные задачи полиции (12 направлений)|Пресечение правонарушений, задержание, розыск, помощь гражданам, упрощенный порядок|0
ФЗ О Полиции|Статья 4. Основные направления деятельности полиции|Патрульно-постовая, оперативная, розыскная, конвойная и административная деятельность|0
ФЗ О Полиции|Статья 5. Территориальность деятельности полиции|Полномочия на всей территории РО; пресечение правонарушений вне своей зоны|0
ФЗ О Полиции|Статья 6. Пределы полицейской компетенции|Только для законной цели и соразмерно; запрет вмешательства в частную жизнь|0
ФЗ О Полиции|Статья 7. Государственная инспекция безопасности дорожного движения (ГИБДД)|Специализированная служба в области безопасности движения МВД|0
ФЗ О Полиции|Статья 8. Внутренние акты полиции|Приказы и регламенты МВД не могут уменьшать объем прав граждан|0
ФЗ О Полиции|Статья 9. Принцип законности|Отказ от исполнения заведомо незаконного приказа; ссылка на приказ не освобождает|0
ФЗ О Полиции|Статья 10. Соблюдение и уважение прав человека|Запрет пыток, унижения достоинства и применения силы в качестве наказания|0
ФЗ О Полиции|Статья 11. Необходимость и соразмерность мер принуждения|Выбор мер с меньшим причинением вреда; запрет избыточных мер ради удобства|0
ФЗ О Полиции|Статья 12. Принцип беспристрастности|Защита прав независимо от расы, национальности, пола, должности; конфликт интересов|0
ФЗ О Полиции|Статья 13. Открытость и информирование|Деятельность открыта; соблюдение тайны следствия и государственной тайны|0
ФЗ О Полиции|Статья 14. Взаимодействие и взаимопомощь ведомств|Сотрудничество с Прокуратурой, СК, ФСБ, Судами и Армией|0
ФЗ О Полиции|Статья 15. Персональная ответственность сотрудника полиции|Сотрудник лично отвечает за законность своих требований и мер силы|0
ФЗ О Полиции|Статья 16. Прием и регистрация заявлений о правонарушениях|Обязательная регистрация вызовов; срок рассмотрения не более 48 часов|0
ФЗ О Полиции|Статья 17. Оказание помощи гражданам|Первая помощь пострадавшим, вызов врачей, защита беспомощных лиц|0
ФЗ О Полиции|Статья 18. Предупреждение и пресечение правонарушений|Законное требование прекратить нарушение; официальное предупреждение|0
ФЗ О Полиции|Статья 19. Охрана общественного порядка|Патрулирование улиц, охрана публичных мест и массовых мероприятий|0
ФЗ О Полиции|Статья 20. Охрана места происшествия и сохранение доказательств|Оцепление, ограничение прохода посторонних, запрет перемещения предметов|0
ФЗ О Полиции|Статья 21. Розыск лиц и ориентировки|Поиск разыскиваемых, проверка ориентировок и законное задержание|0
ФЗ О Полиции|Статья 22. Исполнение обязательных судебных и прокурорских актов|Исполнение решений суда, постановлений о санкции ареста, приводов|0
ФЗ О Полиции|Статья 23. Производство по делам об административных правонарушениях|Возбуждение, составление протоколов и рассмотрение дел по КоАП|0
ФЗ О Полиции|Статья 24. Упрощенное разрешение уголовного материала|Разрешение дел общей подследственности на месте без письменного производства|0
ФЗ О Полиции|Статья 25. Передача уголовных материалов по подследственности в СК и ФСБ|Неотложные действия на месте и обязательная передача дела в СК/ФСБ|0
    )
    LoadData(pl1)

    pl2 = 
    (
ФЗ О Полиции|Статья 26. Обеспечение прав задержанного|Разъяснение прав, вызов адвоката, обязательное участие прокурора для служащих|0
ФЗ О Полиции|Статья 27. Безопасность задержанного и контроль состояния|Оказание медпомощи; постоянный контроль при применении наручников|0
ФЗ О Полиции|Статья 28. Сохранность изъятых доказательств и имущества|Запрет присвоения, подмены или использования изъятого в личных целях|0
ФЗ О Полиции|Статья 29. Обязательная фото-, аудио- и видеофиксация|Ведение и хранение записей процессуальных действий по закону|0
ФЗ О Полиции|Статья 30. Порядок представления сотрудника полиции гражданам|Назвать звание, фамилию, должность и предъявить служебное удостоверение|0
ФЗ О Полиции|Статья 31. Действия сотрудника вне времени несения службы|Вызов дежурных нарядов и предотвращение тяжких последствий при ЧП|0
ФЗ О Полиции|Статья 32. Законное требование сотрудника полиции|Обязательно для граждан; конкретное, этичное, в приказном наклонении|0
ФЗ О Полиции|Статья 33. Проверка документов и установление личности граждан|Основания: подозрение, розыск, ориентировка, охраняемая территория|0
ФЗ О Полиции|Статья 34. Использование государственных информационных систем|Строго по службе; запрет слива баз данных и пробива в личных целях|0
ФЗ О Полиции|Статья 35. Вызов граждан и получение объяснений|Приглашение для опроса; принудительный привод только по постановлению|0
ФЗ О Полиции|Статья 36. Доставление и задержание лиц|Ограничение свободы строго по закону; задержание не является наказанием|0
ФЗ О Полиции|Статья 37. Личный обыск, досмотр и изъятие вещей|Первичный обыск при задержании на оружие, запрещенные вещества и документы|0
ФЗ О Полиции|Статья 38. Обыск транспортного средства без судебного ордера|При погоне, ориентировке, преступлении или запрещенных вещах у водителя|0
ФЗ О Полиции|Статья 39. Проникновение в жилище и частные помещения без ордера|Спасение жизни, преследование по горячим следам, ликвидация ЧС|0
ФЗ О Полиции|Статья 40. Доступ на государственные и режимные объекты|По служебному удостоверению для следственных действий и задержаний|0
ФЗ О Полиции|Статья 41. Оцепление участков местности и ограничение доступа|Места преступлений, спецоперации, массовые беспорядки, угрозы взрыва|0
ФЗ О Полиции|Статья 42. Осмотр и обследование территорий|Осмотр общественных мест, открытой местности и мест происшествий|0
ФЗ О Полиции|Статья 43. Оперативно-розыскная деятельность (ОРД)|Наблюдение, внедрение; ограничение прав граждан только через суд|0
ФЗ О Полиции|Статья 44. Использование транспорта граждан в неотложных случаях|С согласия владельца; без согласия — только при прямой угрозе жизни|0
ФЗ О Полиции|Статья 45. Исполнение привода, конвоирование и охрана|Доставление в суд/следствие, конвой в ИВС, охрана мест содержания|0
ФЗ О Полиции|Статья 46. Защита потерпевших, свидетелей и иных лиц|Применение мер государственной безопасности при угрозах жизни|0
ФЗ О Полиции|Статья 47. Общие условия применения физической силы|Только для законной цели; прекращение после устранения угрозы|0
ФЗ О Полиции|Статья 48. Основания применения физической силы и приемов|Пресечение нападения, сопротивления, задержание, пресечение побега|0
ФЗ О Полиции|Статья 49. Специальные средства (дубинки, тазеры, барьеры)|Отражение нападения, задержание опасных лиц, пресечение беспорядков|0
ФЗ О Полиции|Статья 50. Основания применения наручников|Задержание, арест, конвой, риск нападения, побега или уничтожения улик|0
    )
    LoadData(pl2)

    pl3 = 
    (
ФЗ О Полиции|Статья 51. Основания применения огнестрельного оружия|Крайняя мера при угрозе жизни; запрет предупредительных выстрелов|0
ФЗ О Полиции|Статья 52. Предупреждение о намерении применить силу/оружие|Предупреждение обязательно (исключение: внезапное нападение/угроза жизни)|0
ФЗ О Полиции|Статья 53. Ограничения при применении силы|Запрет применения избыточной силы к лицу, прекратившему сопротивление|0
ФЗ О Полиции|Статья 54. Действия сотрудника полиции после применения силы|Оказание первой помощи, доклад руководству, передача видео в прокуратуру|0
ФЗ О Полиции|Статья 55. Преследование транспортных средств (погоня)|Преследование скрывающихся нарушителей с учетом безопасности граждан|0
ФЗ О Полиции|Статья 56. Система органов полиции МВД РО|ГУ МВД, территориальные отделы, уголовный розыск, ППС, ГИБДД|0
ФЗ О Полиции|Статья 57. Министр внутренних дел РО|Общее государственное и организационное руководство ведомством|0
ФЗ О Полиции|Статья 58. Руководитель Главного управления МВД РО (Глава МВД)|Оперативное управление полицией, патрулированием, кадрами и спецоперациями|0
ФЗ О Полиции|Статья 59. Внутренняя структура подразделений полиции|Управления, отделы, батальоны; объем прав определяется законами|0
ФЗ О Полиции|Статья 60. Служебные поручения и распределение материалов|Распределение вызовов и ориентировок между дежурными сменами|0
ФЗ О Полиции|Статья 61. Совместные группы и специальные межведомственные операции|Взаимодействие при рейдах и массовых мероприятиях|0
ФЗ О Полиции|Статья 62. Правовой статус сотрудника полиции|Сотрудник при исполнении — официальный представитель государственной власти|0
ФЗ О Полиции|Статья 63. Служебное удостоверение и нагрудный жетон|Обязательное ношение нагрудного знака на форме для визуального контроля|0
ФЗ О Полиции|Статья 64. Специальные звания полиции|Звание определяет субординацию, но не отменяет должностную цепь подчинения|0
ФЗ О Полиции|Статья 65. Основные обязанности сотрудника полиции|Соблюдать Конституцию, приказы, права граждан, видеофиксацию, тайну|0
ФЗ О Полиции|Статья 66. Запреты и ограничения для сотрудника полиции|Запрет взяток, покровительства, использования оружия и баз в личных целях|0
ФЗ О Полиции|Статья 67. Приказ руководителя и отказ от незаконного приказа|Отказ от заведомо незаконного приказа не является дисциплинарным проступком|0
ФЗ О Полиции|Статья 68. Государственная защита сотрудника полиции и его близких|Уголовная защита от угроз и насилия в связи со службой|0
ФЗ О Полиции|Статья 69. Дисциплинарная ответственность сотрудников|Замечание, выговор, строгий выговор, понижение в должности, увольнение|0
ФЗ О Полиции|Статья 70. Ответственность за незаконные действия и превышение полномочий|Дисциплинарная, гражданская и уголовная ответственность сотрудника|0
ФЗ О Полиции|Статья 71. Взаимодействие с Прокуратурой РО (надзор)|Предоставление видеозаписей по запросу; исполнение санкций прокурора|0
ФЗ О Полиции|Статья 72. Взаимодействие со Следственным комитетом (СК РО)|Исполнение поручений следователя по розыску, приводам, оцеплениям|0
ФЗ О Полиции|Статья 73. Взаимодействие с Федеральной службой безопасности (ФСБ)|Передача материалов по исключительной подследственности ФСБ|0
ФЗ О Полиции|Статья 74. Взаимодействие с судами|Исполнение приводов, охрана заседаний, обязательность судебных решений|0
ФЗ О Полиции|Статья 75. Взаимодействие с Правительством РО|Организационное обеспечение; запрет незаконного вмешательства в следствие|0
ФЗ О Полиции|Статья 76. Ведомственный контроль руководства полиции|Служебные проверки, контроль дисциплины и отмена незаконных актов|0
ФЗ О Полиции|Статья 77. Порядок обжалования действий и решений полиции|Жалоба руководству, в прокуратуру или суд; предоставление видеофиксации|0
    )
    LoadData(pl3)

    us1 = 
    (
Устав ГИБДД|Статья 1. Государственная инспекция безопасности дорожного движения|Орган исполнительной власти в сфере безопасности движения и контроля порядка|0
Устав ГИБДД|Статья 2. Роль и обязательность Устава ГИБДД|Обязателен для всех сотрудников независимо от звания; незнание не освобождает|0
Устав ГИБДД|Статья 3. Основные принципы службы в ГИБДД|Законность, единоначалие, дисциплина, субординация и авторитет службы|0
Устав ГИБДД|Статья 4. Порядок изменения настоящего Устава|Вносятся руководством ГИБДД с обязательным ознакомлением личного состава|0
Устав ГИБДД|Статья 5. Поступление на службу и зачисление в Академию|Отбор кандидатов; зачисление в Академию ГИБДД для первоначальной подготовки|0
Устав ГИБДД|Статья 6. Академия ГИБДД (руководство ЦПП)|Обучение законам, уставу, регламентам; куратор — Центр подготовки персонала|0
Устав ГИБДД|Статья 7. Срок прохождения Академии (3 дня, 2 попытки сдачи)|Несдача = отчисление и внесение в Чёрный список на 14 календарных дней|0
Устав ГИБДД|Статья 8. Структурные подразделения (ДПС, ЦПП, УСБ, СБ)|4 специализированных подразделения в подчинении руководства ГИБДД|0
Устав ГИБДД|Статья 9. Руководство ГИБДД (Генерал, Генерал-полковник, Генерал-лейтенант)|Командиры несут персональную ответственность за дисциплину личного состава|0
Устав ГИБДД|Статья 10. 16 специальных званий ГИБДД (Рядовой — Генерал)|Иерархическая лестница званий дорожной инспекции|0
Устав ГИБДД|Статья 11. Общие обязанности сотрудника ГИБДД|Соблюдать законы, субординацию, беречь служебное ТС, оружие и спецсредства|0
Устав ГИБДД|Статья 11.6. Обязанность прибытия на построение личного состава|Неявка в строй или самовольный уход без разрешения влечет взыскание|0
Устав ГИБДД|Статья 12. Права сотрудника ГИБДД|Получение экипировки, подача рапортов, защита прав, обжалование наказаний|0
Устав ГИБДД|Статья 13. Исполнение законных распоряжений руководства|Обязательно; заведомо незаконное распоряжение исполнению не подлежит|0
Устав ГИБДД|Статья 14. Понятие и обязательность служебной субординации|Основана на званиях, должностях и единоначалии; нарушение наказуемо|0
Устав ГИБДД|Статья 15. Порядок служебного обращения («Товарищ [звание]»)|Официальная форма; общение с гражданами на «Вы» в вежливой форме|0
Устав ГИБДД|Статья 16. Правила служебного общения и профессиональная этика|Запрет панибратства, пренебрежительного тона, мата и оскорблений|0
Устав ГИБДД|Статья 17. Основные запреты сотрудникам (взятки, прогулы, алкоголь)|Категорический запрет коррупции, обмана руководства и прогула службы|0
    )
    LoadData(us1)

    us2 = 
    (
Устав ГИБДД|Статья 18. Правила использования служебной радиосвязи|Краткость, запрет личных бесед; приоритет срочных сообщений и погонь|0
Устав ГИБДД|Статья 19. Рабочий график сотрудников (с 10:00 до 23:00)|Перерывы суммарно не более 1 часа в течение служебного дня|0
Устав ГИБДД|Статья 20. Порядок предоставления отпуска (до 7 дней в месяц)|Подается рапорт после Академии; продление только по согласованию|0
Устав ГИБДД|Статья 21. Дорожно-патрульная служба (ДПС ГИБДД)|Патрулирование, посты, проверка документов, оформление ДТП, погони|0
Устав ГИБДД|Статья 22. Центр подготовки персонала (ЦПП ГИБДД)|Набор личного состава, собеседования, обучение курсантов Академии|0
Устав ГИБДД|Статья 23. Управление собственной безопасности (УСБ ГИБДД)|Внутренний надзор, досмотр сотрудников, проверки на опьянение, взыскания|0
Устав ГИБДД|Статья 24. Специальный батальон (СБ ГИБДД)|Силовая поддержка, сопровождение колонн, опасные рейды и задержания|0
Устав ГИБДД|Статья 25. Понятие дисциплинарного проступка|Виновное нарушение устава, законов или законного приказа руководства|0
Устав ГИБДД|Статья 26. Виды дисциплинарных взысканий|Устный выговор, строгий выговор, переаттестация, увольнение|0
Устав ГИБДД|Статья 27. Устный выговор (система учета 0/2)|Применяется за легкие проступки; 2 устных выговора = 1 строгий выговор|0
Устав ГИБДД|Статья 28. Строгий выговор (система учета 0/2)|За грубые нарушения; 2 строгих = переаттестация либо увольнение из органов|0
Устав ГИБДД|Статья 29. Проведение переаттестации сотрудника|Проверка профпригодности при 2 выговорах; несдача = увольнение|0
Устав ГИБДД|Статья 30. Порядок снятия дисциплинарных взысканий (служебная отработка)|Посты, патрули, нормативы; строгий запрет откупа деньгами или вещами|0
Устав ГИБДД|Статья 31. Обжалование дисциплинарного взыскания|Письменная жалоба в УСБ или руководству с изложением доводов|0
Устав ГИБДД|Статья 32. Повышение в звании и согласование руководящих постов с УСБ|Подача отчетов; проверка благонадежности кандидатов в командиры через УСБ|0
Устав ГИБДД|Статья 33. Прекращение службы и увольнение из ГИБДД|Сдача имущества, формы, оружия и незавершенных материалов|0
Устав ГИБДД|Статья 34. Чёрный список ГИБДД|Внесение на 14 дней за провал Академии; бессрочно — за взятки и слив инфо|0
Устав ГИБДД|Статья 35. Вступление Устава в законную силу|Утверждено Генералом ГИБДД Базановым Д.А., г. Москва|0
    )
    LoadData(us2)
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
            pop := (p.Length() >= 4) ? p[4] : 0
            ArticleDB.Push({"Category": p[1], "Title": p[2], "Punish": p[3], "IsPop": pop})
        }
    }
}