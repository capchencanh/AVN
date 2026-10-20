*&---------------------------------------------------------------------*
*&  Program ID: YPG_PPIM01_DAILY_CONTROL
*&  Program Summary: T-Code YPG_PPIM01
*&  Create by: Citek_DEV1
*&  Created on: 21.11.2025
*&  Version   Change Date       Modifier           Description
*&---------------------------------------------------------------------*
*&  1.0       15.10.2025        Citek_DEV1         Initialize report
*&
*&---------------------------------------------------------------------*
*&  Modification Log:
*&---------------------------------------------------------------------*
*&  M001: (Thông tin chỉnh sửa)
*&  Scope: (Những INCLUDE, FM,... bị thay đổi)
*&  Requester:
*&  Modifier:
*&  Modification date:
*&---------------------------------------------------------------------*

REPORT YPG_PPIM01_DAILY_CONTROL.

INCLUDE YIN_PPIM01_DAILY_CONTROL_TOP.
INCLUDE YIN_PPIM01_DAILY_CONTROL_LCL.
INCLUDE YIN_PPIM01_DAILY_CONTROL_O01.
INCLUDE YIN_PPIM01_DAILY_CONTROL_I01.
INCLUDE YIN_PPIM01_DAILY_CONTROL_F01.


*&---------------------------------------------------------------------*
*&  initialization
*&---------------------------------------------------------------------*
INITIALIZATION.
  PERFORM INIT.

*&---------------------------------------------------------------------*
*&  start-of-selection
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM MAIN_PROC.

*&---------------------------------------------------------------------*
*&  end-of-selection
*&---------------------------------------------------------------------*
END-OF-SELECTION.

*GUI Texts
*----------------------------------------------------------
* TITLE_0100 --> ZPPIM01 Upload kế hoạch sản xuất


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   No data

*
* 
