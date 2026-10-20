*&---------------------------------------------------------------------*
*& Include          YIN_PPIM01_TOP
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&  Table define
*&---------------------------------------------------------------------*
TABLES: RM60X, T006 .

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

CLASS LCL_PPIM01_PSIC DEFINITION DEFERRED.
DATA GO_UPPSIC TYPE REF TO LCL_PPIM01_PSIC.

*&---------------------------------------------------------------------*
*& Selection screen define
*&---------------------------------------------------------------------*
TYPES: BEGIN OF TY_SEL,
         FILENAME  TYPE STRING,
         WORKSHEET TYPE TEXT255,
       END OF TY_SEL.
SELECTION-SCREEN BEGIN OF BLOCK BL02 WITH FRAME TITLE TEXT-T02.
  PARAMETERS: P_BERID TYPE RM60X-BERID MODIF ID M1 OBLIGATORY,
              P_MSEHI TYPE T006-MSEHI MODIF ID M1 OBLIGATORY.
  PARAMETERS: P_INFILE TYPE TY_SEL-FILENAME MODIF ID M2 OBLIGATORY,
              P_SHEET  TYPE TY_SEL-WORKSHEET MODIF ID M2 OBLIGATORY.
SELECTION-SCREEN END OF BLOCK BL02.

*
* 
