*&---------------------------------------------------------------------*
*&  Program ID: YPG_PPIM01
*&  Program Summary: T-Code YPG_PPIM01  - Program
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

REPORT YPG_PPIM01.

INCLUDE YIN_PPIM01_TOP.
INCLUDE YIN_PPIM01_LCL.
INCLUDE YIN_PPIM01_O01.
INCLUDE YIN_PPIM01_I01.
INCLUDE YIN_PPIM01_F01.


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
* TITLE_0100 --> ZPPIM01 Upload PSIC


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   Số lượng upload sai định dạng. Kiểm tra lại trước khi post

*
* 
