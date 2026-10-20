*&---------------------------------------------------------------------*
*& Include          YIN_PPIM01_TOP
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&  Table define
*&---------------------------------------------------------------------*
TABLES: RM60X , YTB_MRP_DEMAND.

*&---------------------------------------------------------------------*
*&  Data define
*&---------------------------------------------------------------------*
DATA GS_VARIANT TYPE DISVARIANT.
DATA GS_LAYO  TYPE LVC_S_LAYO.

*&---------------------------------------------------------------------*
*&  Constants
*&---------------------------------------------------------------------*
CONSTANTS: BEGIN OF C_ICON,
             SUCCESS TYPE ICON_D VALUE ICON_GREEN_LIGHT,
             FAIL    TYPE ICON_D VALUE ICON_RED_LIGHT,
             WARNING TYPE ICON_D VALUE ICON_YELLOW_LIGHT,
             NONE    TYPE ICON_D VALUE ICON_LIGHT_OUT,
           END OF C_ICON,
           BEGIN OF C_USRCMD,
             SEL   TYPE SY-UCOMM VALUE '&SEL',
             UNSEL TYPE SY-UCOMM VALUE '&UNSEL',
             POST  TYPE SY-UCOMM VALUE '&POST',
           END OF C_USRCMD.

*&---------------------------------------------------------------------*
*&  Object define
*&---------------------------------------------------------------------*
DATA: GO_DOCKING          TYPE REF TO CL_GUI_DOCKING_CONTAINER, "Docking Container
      GO_GRID             TYPE REF TO CL_GUI_ALV_GRID, "Grid
      GO_SPLIT            TYPE REF TO CL_GUI_EASY_SPLITTER_CONTAINER, "Splitter
      GO_SPLIT_C          TYPE REF TO CL_GUI_SPLITTER_CONTAINER, "Splitter
      GO_CONTAINER        TYPE REF TO CL_GUI_CUSTOM_CONTAINER,   "Container
      GO_TOP_CONTAINER    TYPE REF TO CL_GUI_CONTAINER,   "Top Container
      GO_BOTTOM_CONTAINER TYPE REF TO CL_GUI_CONTAINER, "Bottom Container
      GO_DOCUMENT         TYPE REF TO CL_DD_DOCUMENT.          "Document

CLASS LCL_PPIM01_HIS DEFINITION DEFERRED.
DATA GO_UPPSIC TYPE REF TO LCL_PPIM01_HIS.

*&---------------------------------------------------------------------*
*& Selection screen define
*&---------------------------------------------------------------------*
DATA: BEGIN OF LS_SELECT,
        MONTH TYPE FTI_MONTH_YEAR,
      END OF LS_SELECT.
SELECTION-SCREEN BEGIN OF BLOCK BL03 WITH FRAME TITLE TEXT-T03.
  PARAMETERS: P_BERID TYPE RM60X-BERID MODIF ID M3.
  SELECT-OPTIONS:
  S_MATNR FOR YTB_MRP_DEMAND-MATNR MODIF ID M3,
  S_MONTH FOR LS_SELECT-MONTH MODIF ID M3,
  S_DATE FOR YTB_MRP_DEMAND-CRT_DATE MODIF ID M3,
  S_USER FOR YTB_MRP_DEMAND-CRT_USER MODIF ID M3.

  PARAMETERS:
    P_PSIC AS CHECKBOX DEFAULT 'X',
    P_DAIL AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK BL03.

*
* 
