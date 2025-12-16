#Requires AutoHotkey v1.1
#SingleInstance Force
#Include %A_ScriptDir%
#Include .\lib\tooltipFollowMouse.ahk
setBatchLines -1
;==========================================================================================
*F1::
    TFM1:=tooltipFollowMouse("Simple Example1"
                    . "`nthe tooltip1 is displayed when F1 is pressed. ")
    TFM1.start()
    ;  TFM1.UseMoveWindow:=false
    keyWait F1
    sleep 100
    TFM1.stop()
    TFM1:=""
    return
;------------------------------------------------------------------------------------------
*F2::
    if (!TFM2)    {
        TFM2:=tooltipFollowMouse("Simple Example2"
                        . "`nthe tooltip2 will automatically disappear after 3 seconds. ",40,80,2)
        TFM2.Timeout:=3
    }
    if (TFM2.InProgress)
        return
    TFM2.start()
    return
;------------------------------------------------------------------------------------------
*F3::
    keyWait F3
    if (!TFM3)    {
        TFM3:=tooltipFollowMouse()
        TFM3.Text:="Simple Example3"
                . "`nyou can determine the visibility of the tooltip3 by adjusting the value of the ""Visible"" field. "
        TFM3.WhichToolTip:=3
        TFM3.X:=16
        TFM3.Y:=16
    }
    if (TFM3.InProgress)
        return
    TFM3.start()
    sleep 800
    loop 3    {
        TFM3.Visible:=false
        sleep 200
        TFM3.Visible:=true
        sleep 200
    }
    sleep 800
    TFM3.stop()
    return
;------------------------------------------------------------------------------------------
*F4::
    if (!TFM4.InProgress)    {
        TFM4:=tooltipFollowMouse(,-420,-50,4)
        TFM4.start()
        loop Parse, % "Simple Example4"
                    . "`nyou can change the "" .Text"" during the InProgress state. "
                    . "`nthe tooltip4 will automatically disappear after 2 seconds. "
        {
            TFM4.Text.=A_LoopField
            sleep 20
        }
        TFM4.Timeout:=2
    }
    return
;==========================================================================================
*F5::run % A_ScriptFullPath
;------------------------------------------------------------------------------------------
*F6::
    while (getKeyState("F6","P"))    {
        tooltip % "
        (
 Universal Declaration of Human Rights

The Universal Declaration of Human Rights (UDHR) is an international document 
adopted by the United Nations General Assembly that enshrines the rights and freedoms of all human beings. 
Drafted by a UN committee chaired by Eleanor Roosevelt, 
it was accepted by the General Assembly as Resolution 217 during its third session 
on 10 December 1948 at the Palais de Chaillot in Paris, France. 
Of the 58 members of the United Nations at the time, 
48 voted in favour, none against, eight abstained, and two did not vote.`t`t`t[ " A_Now " ]
        )",,,6
        sleep 10
    }
    tooltip,,,, 6
    return
;------------------------------------------------------------------------------------------
*F7::
    TFM7:=tooltipFollowMouse(,,,7)
    TFM7.Callout:=func("tfm7_Callout")
    TFM7.start()
    keyWait F7
    TFM7.stop()
    return
tfm7_Callout()    {
    ret:="
    (
 Universal Declaration of Human Rights

The Universal Declaration of Human Rights (UDHR) is an international document 
adopted by the United Nations General Assembly that enshrines the rights and freedoms of all human beings. 
Drafted by a UN committee chaired by Eleanor Roosevelt, 
it was accepted by the General Assembly as Resolution 217 during its third session 
on 10 December 1948 at the Palais de Chaillot in Paris, France. 
Of the 58 members of the United Nations at the time, 
48 voted in favour, none against, eight abstained, and two did not vote.`t`t`t[ " A_Now " ]
    )"
    return ret
}
;==========================================================================================
*F9::
    if (!TFM9)    {
        TFM9:=tooltipFollowMouse(,2,8,9)
        TFM9.Callout:=func("TFM9_Callout")
        TFM9.CalloutPeriod:=400
    }
    TFM9[TFM9.InProgress?"stop":"start"]()
    keyWait F9
    return

TFM9_Callout()    {
    return "Advanced Example9`nthe current value of TickCount is as follows. `n`nTickCount : " A_TickCount
}
;------------------------------------------------------------------------------------------
*F10::
    if (!TFM10)    {
        TFM10:=tooltipFollowMouse(,,,10)
        TFM10.Period:=1000
        TFM10.Callout:=func("tfm10_Callout")
        TFM10.CalloutPeriod:=0 ;  default value 0 means that Callout is called in accordance with the SetTimer interval of the mouse cursor move. 
    }
    TFM10[TFM10.InProgress?"stop":"start"]()
    keyWait F10
    return
tfm10_Callout()    {
    return "Advanced Example10`nthe current value of TimeIdle is as follows. `n`nTimeIdle`t`t: " A_TimeIdle "`nTimeIdlePhysical`t: " A_TimeIdlePhysical "`nTimeIdleKeyboard`t: " A_TimeIdleKeyboard "`nTimeIdleMouse`t`t: " A_TimeIdleMouse
}
;------------------------------------------------------------------------------------------
*F11::
    keyWait F11
    TFM11:=tooltipFollowMouse()
    TFM11.Callout:=func("tfm11_Callout"), TFM11.WhichToolTip:=11
    TFM11.start()
    sleep 3000
    TFM11.WhichToolTip:=6
    sleep 3000
    TFM11.WhichToolTip:=5
    TFM11.WhichToolTip:=20
    sleep 3000
    TFM11.WhichToolTip:=11
    TFM11.Text:="Advanced Example11"
            . "`nthe tooltip" TFM11.WhichToolTip " will automatically disappear after 3 seconds. "
    TFM11.Callout:=false
    TFM11.Timeout:=3
    return
tfm11_Callout()    {
    global TFM11
    return "Advanced Example11"
        . "`nyou can change "" .WhichToolTip"" even when the tooltip is in the InProgress state. `n`nTFM11.WhichToolTip`t: " TFM11.WhichToolTip
}
;------------------------------------------------------------------------------------------
*F12::
    keyWait F12
    TFM12:=tooltipFollowMouse(,,,12)
    TFM12.CalloutPeriod:=100
    TFM12.Callout:=func("tfm12_Callout1")
    TFM12.start()
    sleep 4000
    TFM12.Callout:=func("tfm12_Callout2")
    sleep 4000
    TFM12.stop()
    return
tfm12_Callout1()    {
    coordMode Mouse, % format("{2}",prevCMM:=A_CoordModeMouse,"Screen")
    mouseGetPos X, Y
    coordMode Mouse, % prevCMM
    return "
        (LTrim
            Advanced Example12
            the current mouse coordinates in the ""Screen"" coordMode are as follows.
            
            ScreenX  `t: " X "
            ScreenY  `t: " Y "
        )"
}
tfm12_Callout2()    {
    coordMode Mouse, % format("{2}",prevCMM:=A_CoordModeMouse,"Window")
    mouseGetPos X, Y
    coordMode Mouse, % prevCMM
    return "
        (LTrim
            Advanced Example12
            the current mouse coordinates in the ""Window"" coordMode are as follows.
            
            WindowX  `t: " X "
            WindowY  `t: " Y "
        )"
}