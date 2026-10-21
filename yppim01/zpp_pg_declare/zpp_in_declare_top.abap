*&---------------------------------------------------------------------*
*& Include          ZPP_IN_DECLARE_TOP
*&---------------------------------------------------------------------*
TYPES: BEGIN OF GTY_DATA,
         STT_MODULE TYPE INT4,
         MODULE     TYPE CHAR2,
         LEVEL      TYPE INT4,
         STT        TYPE INT4,
         NAME       TYPE CHAR70,
         VIEWNAME   TYPE TABNAME,
         TCODE      TYPE TCODE,
       END OF GTY_DATA,
       BEGIN OF GTY_MV,
         VIEWNAME TYPE VIEWNAME,
         DDTEXT   TYPE DD02T-DDTEXT,
       END OF GTY_MV,
       BEGIN OF GTY_TB,
         TABNAME TYPE TABNAME,
         DDTEXT  TYPE DD02T-DDTEXT,
       END OF GTY_TB,
       BEGIN OF GTY_PG,
         TCODE TYPE TCODE,
         PGMNA TYPE PROGRAM_ID,
         TEXT  TYPE REPTI,
       END OF GTY_PG.
*-----------------------------------------------------------------------
* Tables Definition
*-----------------------------------------------------------------------
DATA:
  GT_DATA   TYPE TABLE OF GTY_DATA,
  GT_TREE   LIKE GT_DATA,
  GT_MV     TYPE TABLE OF GTY_MV,
  GT_TB     TYPE TABLE OF GTY_TB,
  GT_PG     TYPE TABLE OF GTY_PG,

  GT_FLDCAT TYPE LVC_T_FCAT.
*-----------------------------------------------------------------------
* Object Definition
*-----------------------------------------------------------------------
DATA:
  OK_CODE      TYPE SY-UCOMM,
  GO_TREE      TYPE REF TO CL_GUI_ALV_TREE,          "ALV tree
  GO_CONTAINER TYPE REF TO CL_GUI_CUSTOM_CONTAINER.  "Container

*
* 
