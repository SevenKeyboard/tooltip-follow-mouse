#Requires AutoHotkey v1.1.35+
#Include %A_ScriptDir%
#Include .\lib\MonitorExGetUtils.ahk
#Include .\lib\mouseGetWhichMonitor.ahk
;==============================================================
; tooltipFollowMouse — Flicker-free tooltip follower
;
; GitHub: https://github.com/SevenKeyboard/tooltip-follow-mouse
; Author: SevenKeyboard Ltd. (2025)
; License: MIT License
;
; Documentation / References:
;   ToolTip which follows the mouse is flickering
;     https://www.autohotkey.com/board/topic/63640-tooltip-which-follows-the-mouse-is-flickering/
;     https://www.autohotkey.com/boards/viewtopic.php?&t=12307
;   ToolTip following mouse without flicker
;     https://www.autohotkey.com/boards/viewtopic.php?t=103459
;==============================================================
class VersionManager_tooltipFollowMouse
{
    static _ := VersionManager_tooltipFollowMouse._init()
    _init()    {
        global
        TOOLTIPFOLLOWMOUSE_VERSION := "1.0.0"
        if (!this._verCheck(MONITOREXGETUTILS_VERSION, "1.0.0"))
            throw exception("MonitorExGetUtils version 1.x is required (minimum 1.0.0).")
        if (!this._verCheck(MOUSEGETWHICHMONITOR_VERSION, "1.0.0"))
            throw exception("mouseGetWhichMonitor version 1.x is required (minimum 1.0.0).")
        return true
    }
    _verCheck(byRef actual, required)    {
        if !isSet(actual)
            return false
        actualMajor     := strSplit(actual, ".",, 2)[1]
        requiredMajor   := strSplit(required, ".",, 2)[1]
        if (actualMajor !== requiredMajor)
            return false
        return verCompare(actual, ">=" required)
    }
}
tooltipFollowMouse(text:="", x:=16, y:=16, whichToolTip:=1)    {
    return new TooltipMouseFollower_A2DB753C(text, x, y, whichToolTip)
}
;------------------------------------------------------------------------------------------
class TooltipMouseFollower_A2DB753C
{
    __new(text, x, y, whichToolTip)    {
        this._obmST:=objBindMethod(this,"_setTimer")
        this._obmUpdateCT:=objBindMethod(this,"_updateCT")
        this.obmStop:=objBindMethod(this,"stop")
        this.Text:=text, this.X:=x, this.Y:=y, this.WhichToolTip:=whichToolTip
        this._inprogress:=false
        this.Timeout:=0.0
        this._visible:=true
        this.UseMoveWindow:=true
        this.Period:=10
        this.Callout:=false, this.CalloutPeriod:=0
        this.hWnds:=[]
        loop 20
            this.hWnds[A_Index]:=0
        TooltipFollowerBackend_C069DB6B.init()
    }
    __delete()    {
        if (this._inprogress)
            this.stop()
    }
    ;------------------------------
    start()    {
        TooltipFollowerBackend_C069DB6B.createGui(true)
        this._inprogress:=true
        this.cT:= this.cX:= this.cY:= ""
        this.sT:=(this.Callout?format("{2}",Callout:=this.Callout,%Callout%()):this.Text)
        this._getCursorPos(sX,sY)
        if (hWnd:=this.hWnds[this.WhichToolTip])
        && (monIndex:=this._mouseGetWhichMonitor(sX,sY))    {
            this._adjustTooltipCoordinates(sX, sY,,, hWnd, monIndex)
        }  else  {
            sX+=this.X, sY+=this.Y
        }
        this.sX:=sX,this.sY:=sY
        switch (this._visible)
        {
            case true:
                if (this.sT!=="")
                    this._showTooltipScreen(this.sT, this.sX, this.sY, this.WhichToolTip)
                else
                    this._hideTooltip(this.WhichToolTip)
            default:
                this._hideTooltip(this.WhichToolTip)
        }
        if (this.CalloutPeriod && this.CalloutPeriod!==this.Period)   {
            _obmUpdateCT:=this._obmUpdateCT, %_obmUpdateCT%()
            setTimer % _obmUpdateCT, % this.CalloutPeriod
        }
        _obmST:=this._obmST
        setTimer % _obmST, % this.Period
        if this.Timeout
            this._setTimeout()
    }
    stop()    {
        this._setTimeout(false)
        _obmST:=this._obmST, _obmUpdateCT:=this._obmUpdateCT, obmStop:=this.obmStop
        setTimer % _obmST, % "Delete"
        setTimer % _obmUpdateCT, % "Delete"
        setTimer % obmStop, % "Delete"
        this._hideTooltip(this.WhichToolTip)
        this._inprogress:=false
    }
    ;------------------------------
    Text    {
        get  {
            return this._text
        }
        set  {
            this._text:=value
            if (this._inprogress)    {
                if (hWnd:=this.hWnds[this.WhichToolTip]) && this.UseMoveWindow
                    this._syncTooltipCoordinates(hWnd)
            }
        }
    }
    InProgress    {
        get  {
            return (!!this._inprogress)
        }
    }
    Timeout    {
        get  {
            return format("{:f}",this._timeout)
        }
        set  {
            this._timeout:=format("{:f}",value)
            if (this._inprogress)
                this._setTimeout()
        }
    }
    Visible    {
        get  {
            return (!!this._visible)
        }
        set  {
            switch (this._visible:=!!value)
            {
                case true:
                    if (this.sT!=="")    {
                        TooltipFollowerBackend_C069DB6B.createGui(true)
                        this._showTooltipScreen(this.sT, this.sX, this.sY, this.WhichToolTip)
                    }  else  {
                        this._hideTooltip(this.WhichToolTip)
                    }
                case false:     this._hideTooltip(this.WhichToolTip)
            }
        }
    }
    UseMoveWindow    {
        get  {
            return (!!this._usemovewindow)
        }
        set  {
            this._usemovewindow:=(!!value)
        }
    }
    Period    {
        get  {
            return format("{:d}",this._period)
        }
        set  {
            this._period:=format("{:d}",value)
            if (this._inprogress)    {
                _obmST:=this._obmST
                setTimer % _obmST, % this._period
            }
        }
    }
    Callout    {
        get  {
            return this._callout
        }
        set  {
            this._callout:=isFunc(value)?value:""
        }
    }
    CalloutPeriod    {
        get  {
            return format("{:d}",this._calloutperiod)
        }
        set  {
            this._calloutperiod:=format("{:d}",value)
            if (this._inprogress)    {
                _obmUpdateCT:=this._obmUpdateCT
                switch (!!this._calloutperiod)
                {
                    case true:      setTimer % _obmUpdateCT, % (this._calloutperiod!==this.Period?this._calloutperiod:"Off")
                    case false:     setTimer % _obmUpdateCT, % "Off"
                }
            }
        }
    }
    WhichToolTip    {
        get  {
            return this._whichtooltip
        }
        set  {
            value:=format("{:d}",value)
            if (value<1||20<value)
                return
            if (this._whichtooltip!==value)    {
                prevIC:=A_IsCritical
                critical On
                prevWhichtooltip:=this._whichtooltip, this._whichtooltip:=value
                if (this.sT!=="")
                    this._showTooltipScreen(this.sT, this.sX, this.sY, this.WhichToolTip)
                else
                    this._hideTooltip(this.WhichToolTip)
                this._hideTooltip(prevWhichtooltip)
                critical % prevIC
            }            
        }
    }
    _ScriptPID    {
        get  {
            static pid:=""
            if (pid=="")
                pid:=dllCall("Kernel32.dll\GetCurrentProcessId", "UInt")
            return pid
        }
    }
    ;------------------------------
    _setTimer()    {
        switch (!!this.Callout)
        {
            case true:
                if !(this.CalloutPeriod && this.CalloutPeriod!==this.Period)
                    _obmUpdateCT:=this._obmUpdateCT, %_obmUpdateCT%()
            default:
                this.cT:=this.Text
        }
        this._getCursorPos(cX,cY)
        if !(hWnd:=this.hWnds[this.WhichToolTip])    {
            switch (this._visible)
            {
                case true:
                    this.sT:=this.cT
                    this.sX:= this.cX:= cX+this.X
                    this.sY:= this.cY:= cY+this.Y
                    this._showTooltipScreen(this.cT, this.cX, this.cY, this.WhichToolTip)
                default:
                    this._hideTooltip(this.WhichToolTip)
            }
            return
        }
        switch (monIndex:=this._mouseGetWhichMonitor(cX,cY))
        {
            case 0:     cX+=this.X, cY+=this.Y
            default:    this._adjustTooltipCoordinates(cX, cY, tW, tH, hWnd, monIndex)
        }
        this.cX:=cX, this.cY:=cY
        if !(changeOccurred:=(this.sT!==this.cT)?"Text":(this.sX!==this.cX||this.sY!==this.cY)?"Coord":false)
            return
        this.sT:=this.cT, this.sX:=this.cX, this.sY:=this.cY
        switch (this._visible)
        {
            case true:
                if (this.sT=="")    {
                    this._hideTooltip(this.WhichToolTip)
                    return
                }
                switch (changeOccurred)
                {
                    case "Text":        this._showTooltipScreen(this.cT, this.cX, this.cY, this.WhichToolTip)
                    case "Coord":
                        if (hWnd && monIndex && this.UseMoveWindow)    {
                            this._MoveTooltipScreen(hWnd, this.cX, this.cY, tW, tH)
                        }  else  {
                            this._showTooltipScreen(this.cT, this.cX, this.cY, this.WhichToolTip)
                        }
                }
            default:
                this._hideTooltip(this.WhichToolTip)
        }
    }
    _setTimeout(onoff:=true)    {
        switch (onoff)
        {
            case true:
                obmStop:=this.obmStop
                setTimer % obmStop, % -1*Abs(this.Timeout*1000)
            case false:
                if this.obmStop    {
                    obmStop:=this.obmStop
                    setTimer % obmStop, % "Delete"
                }
        }
    }
    _updateCT()    {
        if this.Callout    {
            Callout:=this.Callout
            this.cT:=%Callout%()
            if (this._inprogress && this.sT!==this.cT)   {
                if (hWnd:=this.hWnds[this.WhichToolTip]) && this.UseMoveWindow
                    this._syncTooltipCoordinates(hWnd)
            } 
        }
    }
    _showTooltipScreen(text, x, y, whichToolTip)    {
        prevIC:=A_IsCritical
        critical On
        prevCMT:=A_CoordModeToolTip
        coordMode Tooltip, Screen
        if (format("{2}",this._getCursorPos(mX,mY),(X-mX==16&&Y-mY==16)))
            tooltip % text,,, % whichToolTip
        else
            tooltip % text, % x, % y, % whichToolTip
        coordMode Tooltip, % prevCMT
        /*
         since the width and height of the tooltip cannot be determined before it is created, 
        it is not possible to adjust the coordinates based on the boundaries of the bottom right in advance. 
        however, if the difference between the cursor coordinates and the tooltip coordinates corresponds to the default value of 16,
        the issue does not arise as the X and Y parameters of the tooltip can be omitted.
        */
        if (!this.hWnds[WhichToolTip])    {
            this.hWnds[WhichToolTip]:=winExist("ahk_class tooltips_class32 ahk_pid " this._ScriptPID)
            TooltipFollowerBackend_C069DB6B.tooltipIds[this.hWnds[WhichToolTip]]:=""
        }
        critical % prevIC
    }
    _hideTooltip(WhichToolTip)    {
        tooltip,,,, % WhichToolTip
        hWnd:=this.hWnds[WhichToolTip]
        if (TooltipFollowerBackend_C069DB6B.tooltipIds.hasKey(hWnd))
            TooltipFollowerBackend_C069DB6B.tooltipIds.delete(hWnd)
        this.hWnds[WhichToolTip]:=0
    }
    _MoveTooltipScreen(hWnd, x, y, w, h, repaint:=false)    {
        TooltipFollowerBackend_C069DB6B.createGui()
        dllCall("User32.dll\MoveWindow", "Ptr",hWnd, "Int",x, "Int",y, "Int",w, "Int",h, "Int",repaint)
    }
    _adjustTooltipCoordinates(byRef x:="", byRef y:="", byRef w:="", byRef h:="", hWnd:=0, monIndex:=0)    {
        if (!hWnd || !monIndex)
            return
        info:=monitorExGetInfo(monIndex)
        if (errorLevel)
            return
        this._getClientRectOnScreen(tX, tY, tW, tH, hWnd)
        if (info.rcWork.right-tW-3<x && info.rcWork.bottom-tH-3<y && this._mouseGetWhichMonitorWorkArea(x,y))    {
            x:=min(x-3,info.rcWork.right-3)-tW
            y:=min(y-3,info.rcWork.bottom-3)-tH
        }  else  {
            x+=this.x                           ,y+=this.y
            x:=min(x,info.rcWork.right-tW-1)    ,y:=min(y,info.rcWork.bottom-tH-1)
        }
        x:=max(x,info.rcWork.left)      ,y:=max(y,info.rcWork.top)
        w:=tW                           ,h:=tH
    }
    _syncTooltipCoordinates(hWnd:=0)    {
        static TTM_TRACKPOSITION:=0x412
        if (hWnd)
            this._getClientRectOnScreen(tX, tY,,, hWnd), dllCall("SendMessage", "Ptr",hWnd, "UINT",TTM_TRACKPOSITION, "UPtr",0, "Ptr",(tX&0xFFFF)|(tY&0xFFFF)<<16)
    }
    _getClientRectOnScreen(byRef x:="", byRef y:="", byRef w:="", byRef h:="", hWnd:="")    {
        varSetCapacity(RECT, 16, 0)
        dllCall("user32\GetClientRect", "Ptr",hWnd, "Ptr",&RECT)
        dllCall("user32\ClientToScreen", "Ptr",hWnd, "Ptr",&RECT)
        x:=numGet(&RECT, 0,"Int"), y:=numGet(&RECT, 4,"Int"), w:=numGet(&RECT, 8,"Int"), h:=numGet(&RECT, 12,"Int")
    }
    _getCursorPos(byRef x:="", byRef y:="")    {
        varSetCapacity(lpPoint,8,0), dllCall("User32.dll\GetCursorPos", "Ptr",&lpPoint), x:=numGet(lpPoint,0,"Int"), y:=numGet(lpPoint,4,"Int")
    }
    ;------------------------------
    _mouseGetWhichMonitor(x, y)    {
        for N,info in monitorExGetInfoList()    {
            if (info.rcMonitor.left<=x && x<=info.rcMonitor.right && info.rcMonitor.top<=y && y<=info.rcMonitor.bottom)
                return N
        }
        return 0
    }
    _mouseGetWhichMonitorWorkArea(x, y)    {
        for N,info in monitorExGetInfoList()    {
            if (info.rcWork.left<=x && x<=info.rcWork.right && info.rcWork.top<=y && y<=info.rcWork.bottom)
                return N
        }
        return 0
    }
}
;------------------------------------------------------------------------------------------
class TooltipFollowerBackend_C069DB6B
{
    static _lastMonIndex:=0, _currName:="", _currHwnd:=0, tooltipIds:=object()
    init()    {
        static hasCallback:=false
            ,WM_ACTIVATE:=0x0006
            ;  ,WM_DPICHANGED:=0x02E0
        if (!hasCallback)    {
            hasCallback:=true
            this.setObjCreateEventHook()
            onMessage(WM_ACTIVATE,objBindMethod(this,"_onActivate"))
            ;  onMessage(WM_DPICHANGED,objBindMethod(this,"_onDpiChanged"))
        }
    }
    createGui(force:=false)    {
        if (force)
            this._lastMonIndex:=0
        monIndex:=mouseGetWhichMonitor()
        if (this._lastMonIndex==monIndex)
            return
        this._lastMonIndex:=monIndex
        info:=monitorExGetInfo(monIndex)
        if (errorLevel)
            return
        if (this._currHwnd && dllCall("User32.dll\IsWindow", "Ptr",this._currHwnd))    {
            gui % this._currName ":Destroy"
            this._currName:="", this._currHwnd:=0
        }
        this._currName:="TooltipFollowerBackend_Anchor_MonIndex" monIndex "_B2CECE55"
        gui % this._currName ":Destroy"
        gui % this._currName ":+AlwaysOnTop +HwndcurrHwnd +LastFound +ToolWindow"
        winSet Transparent, 0
        gui % this._currName ":Show", % "x" info.rcWork.left+1 " y" info.rcWork.top+1 " w48 h48 NA"
        winWait % "ahk_id " (this._currHwnd:=currHwnd),, 0.1
    }
    setObjCreateEventHook()    {
        static EVENT_OBJECT_DESTROY:=0x8001
            ,WINEVENT_OUTOFCONTEXT:=0x0000
        this._hHook:=dllCall("User32.dll\SetWinEventHook"
            ,"UInt",eventMin:=EVENT_OBJECT_DESTROY
            ,"UInt",eventMax:=EVENT_OBJECT_DESTROY
            ,"Ptr",hmodWinEventProc:=0
            ,"Ptr",pfnWinEventProc:=registerCallback("tooltipFollowerBackend_WinEventProc_A9AA4116","F")
            ,"UInt",idProcess:=dllCall("Kernel32.dll\GetCurrentProcessId","UInt")
            ,"UInt",idThread:=0
            ,"UInt",dwflags:=WINEVENT_OUTOFCONTEXT
            ,"Ptr")
        onExit(objBindMethod(this,"_onApplicationExit"))
    }
    _onApplicationExit(exitReason, exitCode)    {
        if (this._hHook)
            dllCall("UnhookWinEvent", "Ptr",this._hHook)
    }
    handleObjCreateDestroyEventHook(hHook, event, hWnd, idObject, idChild, dwEventThread, dwmsEventTime)    {
        static EVENT_OBJECT_CREATE:=0x8000
            ,EVENT_OBJECT_DESTROY:=0x8001
            ,MAX_CLASS_NAME:=1024
        if (A_PtrSize!==8)
            hWnd:=hWnd<<32>>32
        switch (event)
        {
            /*
            case EVENT_OBJECT_CREATE:
                varSetCapacity(lpClassName, (A_IsUnicode?2:1)*MAX_CLASS_NAME, 0)
                if (dllCall("User32.dll\GetClassName", "Ptr",hWnd, "Ptr",&lpClassName, "Int",MAX_CLASS_NAME, "Int"))    {
                    switch (className:=strGet(&lpClassName))
                    {
                        case "tooltips_class32":        this.tooltipIds[hWnd]:=""
                    }
                }
            */
            case EVENT_OBJECT_DESTROY:
                if (!this.tooltipIds.hasKey(hWnd))
                    return
                this.tooltipIds.delete(hWnd)
                if (!this.tooltipIds.count())    {
                    this._lastMonIndex:=0
                    if (this._currHwnd && dllCall("User32.dll\IsWindow", "Ptr",this._currHwnd))    {
                        gui % this._currName ":Destroy"
                        this._currName:="", this._currHwnd:=0
                    }
                }
        }
    }
    _onActivate(wParam, lParam, msg, hWnd)    {
        if (wParam)
            this.createGui(true)
    }
    /*
    _onDpiChanged(wParam, lParam, msg, hWnd)    {
        
    }
    */
}
tooltipFollowerBackend_WinEventProc_A9AA4116(hHook, event, hWnd, idObject, idChild, dwEventThread, dwmsEventTime)    {
    TooltipFollowerBackend_C069DB6B.handleObjCreateDestroyEventHook(hHook, event, hWnd, idObject, idChild, dwEventThread, dwmsEventTime)
}