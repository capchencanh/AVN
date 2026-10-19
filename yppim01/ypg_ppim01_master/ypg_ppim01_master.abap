*&---------------------------------------------------------------------*
*&  Program ID: YPG_PPIM01_MASTER
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
REPORT YPG_PPIM01_MASTER.

INCLUDE RMCS0F0M.
*&---------------------------------------------------------------------*
*&  Table define
*&---------------------------------------------------------------------*
TABLES: RM60X , T006, YTB_MRP_DEMAND, FILE_TABLE.

*&---------------------------------------------------------------------*
*&  Data define
*&---------------------------------------------------------------------*
DATA: BEGIN OF LS_SELECT,
        MONTH TYPE FTI_MONTH_YEAR,
      END OF LS_SELECT.

*&---------------------------------------------------------------------*
*& Selection screen define
*&---------------------------------------------------------------------*
*--- Block cho Standard consumption Report
SELECTION-SCREEN BEGIN OF BLOCK BL01 WITH FRAME TITLE TEXT-T01.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS          RB_UPPS RADIOBUTTON GROUP GR1 DEFAULT 'X' USER-COMMAND CMD.
    SELECTION-SCREEN COMMENT 4(72) TEXT-R01.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS          RB_UPDC RADIOBUTTON GROUP GR1.
    SELECTION-SCREEN COMMENT 4(72) TEXT-R02.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS          RB_RHIS RADIOBUTTON GROUP GR1.
    SELECTION-SCREEN COMMENT 4(72) TEXT-R03.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS          RB_PIRS RADIOBUTTON GROUP GR1.
    SELECTION-SCREEN COMMENT 4(72) TEXT-R04.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK BL01.

TYPES: BEGIN OF TY_SEL,
         FILENAME  TYPE STRING,
         WORKSHEET TYPE TEXT255,
       END OF TY_SEL.
SELECTION-SCREEN BEGIN OF BLOCK BL02 WITH FRAME TITLE TEXT-T02.
  PARAMETERS: P_BERID TYPE RM60X-BERID MODIF ID M1,
              P_MSEHI TYPE T006-MSEHI MODIF ID M1.
  PARAMETERS: P_INFILE TYPE TY_SEL-FILENAME MODIF ID M2 .
  PARAMETERS: P_SHEET TYPE TY_SEL-WORKSHEET MODIF ID M2 .
  PARAMETERS: P_DATE TYPE DATUM DEFAULT SY-DATUM MODIF ID M5 .

SELECTION-SCREEN END OF BLOCK BL02.

SELECTION-SCREEN BEGIN OF BLOCK BL03 WITH FRAME TITLE TEXT-T03.
  PARAMETERS: P_BERID2 TYPE RM60X-BERID MODIF ID M3  DEFAULT '4100-2000'.
  SELECT-OPTIONS:
  S_MATNR FOR YTB_MRP_DEMAND-MATNR MODIF ID M3,
  S_MONTH FOR LS_SELECT-MONTH MODIF ID M3,
  S_DATE FOR YTB_MRP_DEMAND-CRT_DATE MODIF ID M3,
  S_USER FOR YTB_MRP_DEMAND-CRT_USER MODIF ID M3.

  SELECTION-SCREEN SKIP.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: P_PSIC AS CHECKBOX DEFAULT 'X' MODIF ID M3.
    SELECTION-SCREEN COMMENT 10(15) TEXT-T04 FOR FIELD P_PSIC MODIF ID M3.
    PARAMETERS: P_DAIL AS CHECKBOX DEFAULT 'X' MODIF ID M3.
    SELECTION-SCREEN COMMENT 37(10) TEXT-T05 FOR FIELD P_DAIL MODIF ID M3.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK BL03.

SELECTION-SCREEN BEGIN OF BLOCK BL04 WITH FRAME TITLE TEXT-T04.
  PARAMETERS: P_WERKS4 TYPE RM60X-WERKS MODIF ID M4 OBLIGATORY,
              P_BERID4 TYPE RM60X-BERID MODIF ID M4 OBLIGATORY.

  SELECT-OPTIONS:  S_MATNR4 FOR RM60X-MATNR MODIF ID M4 .

SELECTION-SCREEN END OF BLOCK BL04.
*&---------------------------------------------------------------------*
*&  at selection-screen on value
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR S_MONTH-LOW.
  PERFORM MONAT_F4.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR S_MONTH-HIGH.
  PERFORM MONAT_F4.


*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_INFILE.
  DATA: FILETAB   TYPE FILETABLE,
        FILETAB_S LIKE LINE OF FILETAB.
  DATA RC TYPE I.
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG
    EXPORTING
      WINDOW_TITLE            = 'Select a file'
      FILE_FILTER             = 'Excel or csv (*.xlsx;*.xlsm;*.xls;*.csv)|*.xlsx;*.xlsm;*.xls;*.csv'
    CHANGING
      FILE_TABLE              = FILETAB
      RC                      = RC
    EXCEPTIONS
      FILE_OPEN_DIALOG_FAILED = 1
      CNTL_ERROR              = 2
      ERROR_NO_GUI            = 3
      NOT_SUPPORTED_BY_GUI    = 4
      OTHERS                  = 5.
  IF SY-SUBRC = 0.
    READ TABLE FILETAB INTO FILETAB_S INDEX 1.
    P_INFILE = FILETAB_S-FILENAME.
  ENDIF.


*&---------------------------------------------------------------------*
*&  AT SELECTION-SCREEN OUTPUT.
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    CASE ABAP_TRUE.
      WHEN RB_UPPS.
        IF SCREEN-GROUP1 = 'M3' OR SCREEN-GROUP1 = 'M4' OR SCREEN-GROUP1 = 'M5'.
          SCREEN-ACTIVE  = 0 .
        ELSE.
          SCREEN-REQUIRED = 2.
        ENDIF.
      WHEN RB_UPDC.
        IF SCREEN-GROUP1 = 'M3' OR SCREEN-GROUP1 = 'M4'.
          SCREEN-ACTIVE  = 0 .
        ELSE.
          SCREEN-REQUIRED = 2.
        ENDIF.
      WHEN RB_RHIS.
        IF SCREEN-GROUP1 = 'M1' OR SCREEN-GROUP1 = 'M2' OR SCREEN-GROUP1 = 'M4' OR SCREEN-GROUP1 = 'M5'.
          SCREEN-ACTIVE  = 0 .
        ELSEIF SCREEN-NAME = 'P_BERID2'.
          SCREEN-REQUIRED = 2.
        ENDIF.
      WHEN RB_PIRS.
        IF SCREEN-GROUP1 = 'M1' OR SCREEN-GROUP1 = 'M2' OR SCREEN-GROUP1 = 'M3' OR SCREEN-GROUP1 = 'M5'.
          SCREEN-ACTIVE  = 0 .
        ELSEIF SCREEN-NAME = 'P_BERID4' OR SCREEN-NAME = 'P_WERKS4'.
          SCREEN-REQUIRED = 2.
        ENDIF.
    ENDCASE.

    MODIFY SCREEN.
  ENDLOOP.

*&---------------------------------------------------------------------*
*&  START-OF-SELECTION.
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  CASE ABAP_TRUE.
    WHEN RB_UPPS.
      PERFORM CHECK_UPD.
      SUBMIT YPG_PPIM01
        WITH P_BERID EQ P_BERID
        WITH P_MSEHI EQ P_MSEHI
        WITH P_INFILE EQ P_INFILE
        WITH P_SHEET EQ P_SHEET
      AND RETURN.
    WHEN RB_UPDC.
      PERFORM CHECK_UPD.
      SUBMIT YPG_PPIM01_DAILY_CONTROL
       WITH P_BERID EQ P_BERID
       WITH P_MSEHI EQ P_MSEHI
       WITH P_INFILE EQ P_INFILE
       WITH P_SHEET EQ P_SHEET
       WITH P_DATE EQ P_DATE
     AND RETURN.
    WHEN RB_RHIS.
      PERFORM CHECK_HIS.
      SUBMIT YPG_PPIM01_HIS
        WITH P_BERID EQ  P_BERID2
        WITH S_MATNR IN  S_MATNR
        WITH S_MONTH IN  S_MONTH
        WITH S_DATE  IN  S_DATE
        WITH S_USER  IN  S_USER
        WITH P_PSIC EQ P_PSIC
        WITH P_DAIL EQ P_DAIL
       AND RETURN.
    WHEN RB_PIRS.
      PERFORM CHECK_PIRS.
      SUBMIT YPG_PPIM01_UPDATE_PIRS_NVL
        WITH P_WERKS EQ P_WERKS4
        WITH P_BERID EQ P_BERID4
        WITH S_MATNR IN S_MATNR4
       AND RETURN.

    WHEN OTHERS.
      MESSAGE 'Not thing' TYPE 'S' DISPLAY LIKE 'E'.
  ENDCASE.


FORM CHECK_UPD.
  IF P_BERID IS INITIAL.
    MESSAGE 'MRP Area is require' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  IF  P_MSEHI IS INITIAL.
    MESSAGE 'Internal UoM is require' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF P_INFILE IS INITIAL.
    MESSAGE 'File name is require' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF P_SHEET IS INITIAL.
    MESSAGE 'Tên sheet is require' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  IF RB_UPDC IS NOT INITIAL.
    IF P_DATE IS INITIAL.
      MESSAGE 'Ngày hiệu lực is require' TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.
ENDFORM.

FORM CHECK_HIS.
  IF P_BERID2 IS INITIAL.
    MESSAGE 'MRP Area is require' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.

FORM CHECK_PIRS.
  IF P_WERKS4 IS INITIAL.
    MESSAGE 'Plant is require' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF P_BERID4 IS INITIAL.
    MESSAGE 'MRP Area is require' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.

*Text elements
*----------------------------------------------------------
* R01 Upload PSIC
* R02 Upload kế hoạch sản xuất
* R03 Xem lại dữ liệu đã Upload PSIC/Kế hoạch sản xuất
* R04 Cập nhật mã điều chuyển Bulk/FG từ BH sang LT
* T01 Option
* T02 Parameter
* T04 PSIC
* T05 Daily Control


*Selection texts
*----------------------------------------------------------
* P_BERID D       .
* P_BERID2 D       .
* P_BERID4         MRP Area
* P_DAIL 
* P_DATE         Ngày hiệu lực
* P_INFILE         File name
* P_MSEHI D       .
* P_SHEET         Tên sheet
* P_WERKS4         Plant
* RB_PIRS 
* RB_RHIS         Xem lại dữ liệu
* RB_UPDC         Upload Daily Control
* RB_UPPS         Upload PSIC
* S_DATE D       .
* S_MATNR D       .
* S_MATNR4         Material
* S_MONTH D       .
* S_USER D       .


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   Not thing

*
* 
