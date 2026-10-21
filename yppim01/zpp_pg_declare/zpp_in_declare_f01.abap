*&---------------------------------------------------------------------*
*& Include          ZPP_IN_DECLARE_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Include          ZPP_IN_DECLARE_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form INIT_PROC
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM INIT_PROC .
  REFRESH GT_DATA.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form MAIN_PROC
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM MAIN_PROC .

  PERFORM GET_DATA.
  PERFORM PROCESS_DATA.
  PERFORM CREATE_OBJECT.
  CALL SCREEN 0100.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM GET_DATA .

  PERFORM INIT.
  PERFORM GET_MV.
  PERFORM GET_TCODE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form INIT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM INIT .
  DATA: LS_DATA   LIKE LINE OF GT_DATA,
        LS_HEADER LIKE LS_DATA.

  DEFINE STRUCT_HEADER.
    ls_data-stt_module  = &1.
    ls_data-module      = &2.
    ls_data-level       = 1.
    APPEND ls_data TO gt_data.
    CLEAR ls_data.
  END-OF-DEFINITION.

  DEFINE STRUCT_ITEM.
    READ TABLE gt_data INTO ls_header
      WITH KEY module = &1
               level  = 1 BINARY SEARCH.
    IF sy-subrc = 0.
      ls_data-stt_module = ls_header-stt_module.
    ENDIF.
    ls_data-module    = &1.
    ls_data-level     = 2.
    ls_data-stt       = &2.
    ls_data-viewname  = &3.
    ls_data-tcode     = &4.
    APPEND ls_data TO gt_data.
    CLEAR ls_data.
  END-OF-DEFINITION.

  STRUCT_HEADER 1 'KB'.
  STRUCT_HEADER 2 'CN'.
  SORT GT_DATA BY MODULE LEVEL.

  STRUCT_ITEM 'KB' 1  'ZPP_MV_NCC'         ''.
  STRUCT_ITEM 'KB' 1  'YMV_MRP_MATTYPE'         ''.
  STRUCT_ITEM 'KB' 1  'YPP_MV_DLDT'             ''.
  STRUCT_ITEM 'KB' 1  'YMV_MRP_NVLLT'           ''.
  "HienHN add begin 12.04.2026 21:03:37
  STRUCT_ITEM 'KB' 1  'YMV_MRP_POTYPE'           ''.
  "HienHN add end 12.04.2026 21:03:37
*
  STRUCT_ITEM 'CN' 1  'YPP_PG_CNCCT_MRP'         'YPPIM02'.
  STRUCT_ITEM 'CN' 1  ''                         'ZDD02'.
  STRUCT_ITEM 'CN' 1  ''                         'ZDD03'.
  STRUCT_ITEM 'CN' 1  ''                         'ZDD09'.
  STRUCT_ITEM 'CN' 1  ''                         'ZDD04'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_MV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM GET_MV .
  CHECK GT_DATA IS NOT INITIAL.

  DATA(LT_DATA) = GT_DATA.
  DELETE LT_DATA WHERE VIEWNAME IS INITIAL.
  SORT LT_DATA BY VIEWNAME.
  DELETE ADJACENT DUPLICATES FROM LT_DATA COMPARING VIEWNAME.

  CHECK LT_DATA IS NOT INITIAL.

  SELECT
    DD25L~VIEWNAME AS VIEWNAME,
    DD02T~DDTEXT
  FROM DD02T
    INNER JOIN DD25L ON DD25L~ROOTTAB   = DD02T~TABNAME
                    AND DD25L~AS4LOCAL = DD02T~AS4LOCAL
                    AND DD25L~AS4VERS  = DD02T~AS4VERS
    INNER JOIN DD02L ON DD02L~TABNAME  = DD25L~VIEWNAME
                    AND DD02L~AS4LOCAL = DD25L~AS4LOCAL
                    AND DD02L~AS4VERS  = DD25L~AS4VERS
    INNER JOIN @LT_DATA AS DATA ON DATA~VIEWNAME = DD25L~VIEWNAME   ##ITAB_KEY_IN_SELECT
  WHERE DD02L~VIEWCLASS  EQ 'C'
  ORDER BY DD25L~VIEWNAME
  INTO TABLE @GT_MV.

  SELECT
    DD02L~TABNAME,
    DD02T~DDTEXT
  FROM DD02T
    INNER JOIN DD02L ON DD02L~TABNAME  = DD02T~TABNAME
                    AND DD02L~AS4LOCAL = DD02T~AS4LOCAL
                    AND DD02L~AS4VERS  = DD02T~AS4VERS
    INNER JOIN @LT_DATA AS DATA ON DATA~VIEWNAME = DD02L~TABNAME    ##ITAB_KEY_IN_SELECT
  WHERE DD02L~TABCLASS  EQ 'TRANSP'
  ORDER BY DD02L~TABNAME
  INTO TABLE @GT_TB.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_TCODE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM GET_TCODE .
  CHECK GT_DATA IS NOT INITIAL.

  DATA(LT_DATA) = GT_DATA.
  DELETE LT_DATA WHERE TCODE IS INITIAL.
  SORT LT_DATA BY TCODE.
  DELETE ADJACENT DUPLICATES FROM LT_DATA COMPARING TCODE.

  CHECK LT_DATA IS NOT INITIAL.

  SELECT
    TSTC~TCODE
    TSTC~PGMNA
    TRDIRT~TEXT
    FROM TSTC
    INNER JOIN TRDIRT ON TRDIRT~NAME = TSTC~PGMNA
    INTO TABLE GT_PG
    FOR ALL ENTRIES IN LT_DATA
    WHERE TCODE EQ LT_DATA-TCODE
      AND SPRSL EQ SY-LANGU.
  IF SY-SUBRC = 0.
    SORT GT_PG BY TCODE.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form PROCESS_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM PROCESS_DATA .

  DATA LS_DATA LIKE LINE OF GT_DATA.

  DATA(LT_DATA) = GT_DATA.
  REFRESH GT_DATA.
  SORT LT_DATA BY MODULE LEVEL.

  LOOP AT LT_DATA INTO LS_DATA.
    CASE LS_DATA-LEVEL.
      WHEN 1.
        CASE LS_DATA-MODULE .
          WHEN 'KB'. LS_DATA-NAME = 'Khai báo'.
          WHEN 'CN'. LS_DATA-NAME = 'Chức năng'.
        ENDCASE.
      WHEN 2.
        READ TABLE LT_DATA TRANSPORTING NO FIELDS
          WITH KEY MODULE = LS_DATA-MODULE
                   LEVEL  = 2 BINARY SEARCH.
        IF SY-SUBRC NE 0.
          CONTINUE.
        ENDIF.
    ENDCASE.

    IF LS_DATA-NAME IS INITIAL.
      READ TABLE GT_MV INTO DATA(LS_MV)
        WITH KEY VIEWNAME = LS_DATA-VIEWNAME BINARY SEARCH.
      IF SY-SUBRC EQ 0.
        LS_DATA-NAME = LS_MV-DDTEXT.
      ELSE.
        READ TABLE GT_TB INTO DATA(LS_TB)
          WITH KEY TABNAME = LS_DATA-VIEWNAME BINARY SEARCH.
        IF SY-SUBRC EQ 0.
          LS_DATA-NAME = LS_TB-DDTEXT.
        ENDIF.
      ENDIF.
    ENDIF.
    IF NOT LS_DATA-TCODE IS INITIAL.
      AUTHORITY-CHECK OBJECT 'S_TCODE'
       ID 'TCD' FIELD LS_DATA-TCODE.
      IF SY-SUBRC <> 0.
        CONTINUE.
      ENDIF.
      READ TABLE GT_PG INTO DATA(LS_PG)
        WITH KEY TCODE = LS_DATA-TCODE.
      IF SY-SUBRC <> 0.
        CONTINUE.
      ELSE.
        IF LS_DATA-NAME IS INITIAL.
          LS_DATA-NAME = LS_DATA-TCODE && ` - `  && LS_PG-TEXT.
        ENDIF.
      ENDIF.
    ENDIF.
    APPEND LS_DATA TO GT_DATA.
    CLEAR LS_DATA.
  ENDLOOP.

  SORT GT_DATA BY STT_MODULE  ASCENDING
                  MODULE      ASCENDING
                  LEVEL       ASCENDING
                  STT         ASCENDING.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form BUILD_FLDCAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM BUILD_FLDCAT .
  DATA: LS_FLDCAT LIKE LINE OF GT_FLDCAT.
  CLEAR LS_FLDCAT.

  LS_FLDCAT-FIELDNAME   = 'NAME'.
  LS_FLDCAT-REPTEXT     = 'Name'.
  LS_FLDCAT-OUTPUTLEN   = '000070'.
  LS_FLDCAT-NO_OUT      = 'X'.
  APPEND LS_FLDCAT TO GT_FLDCAT.
  CLEAR LS_FLDCAT.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CALL_MV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM CALL_MV  USING VALUE(LPW_TABNAME).
  DATA: LW_VIEW_NAME  TYPE DD02V-TABNAME.

  LW_VIEW_NAME = LPW_TABNAME.

  SELECT SINGLE
    COUNT(*)
    FROM DD02V
    WHERE TABNAME = LW_VIEW_NAME.
  IF SY-SUBRC = 0.

    CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
      EXPORTING
        ACTION                       = 'U'
        VIEW_NAME                    = LW_VIEW_NAME
      EXCEPTIONS
        CLIENT_REFERENCE             = 1
        FOREIGN_LOCK                 = 2
        INVALID_ACTION               = 3
        NO_CLIENTINDEPENDENT_AUTH    = 4
        NO_DATABASE_FUNCTION         = 5
        NO_EDITOR_FUNCTION           = 6
        NO_SHOW_AUTH                 = 7
        NO_TVDIR_ENTRY               = 8
        NO_UPD_AUTH                  = 9
        ONLY_SHOW_ALLOWED            = 10
        SYSTEM_FAILURE               = 11
        UNKNOWN_FIELD_IN_DBA_SELLIST = 12
        VIEW_NOT_FOUND               = 13
        MAINTENANCE_PROHIBITED       = 14
        OTHERS                       = 15.
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
        WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ELSE.
    SELECT SINGLE
      COUNT(*)
      FROM VCLDIR
      WHERE VCLNAME = LW_VIEW_NAME.
    IF SY-SUBRC = 0.
      CALL FUNCTION 'VIEWCLUSTER_MAINTENANCE_CALL'
        EXPORTING
          VIEWCLUSTER_NAME             = LW_VIEW_NAME
          MAINTENANCE_ACTION           = 'U'
        EXCEPTIONS
          CLIENT_REFERENCE             = 1
          FOREIGN_LOCK                 = 2
          VIEWCLUSTER_NOT_FOUND        = 3
          VIEWCLUSTER_IS_INCONSISTENT  = 4
          MISSING_GENERATED_FUNCTION   = 5
          NO_UPD_AUTH                  = 6
          NO_SHOW_AUTH                 = 7
          OBJECT_NOT_FOUND             = 8
          NO_TVDIR_ENTRY               = 9
          NO_CLIENTINDEP_AUTH          = 10
          INVALID_ACTION               = 11
          SAVING_CORRECTION_FAILED     = 12
          SYSTEM_FAILURE               = 13
          UNKNOWN_FIELD_IN_DBA_SELLIST = 14
          MISSING_CORR_NUMBER          = 15
          OTHERS                       = 16.
      IF SY-SUBRC <> 0.
        MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
          WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 DISPLAY LIKE 'E'.
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_TABNAME
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM GET_TABNAME  USING    LPW_PARAM
                  CHANGING LPW_TABNAME.

  IF LPW_PARAM CS 'SM30'.
    SPLIT LPW_PARAM AT '/*SM30 VIEWNAME=' INTO TABLE DATA(LT_STR).
  ELSE.
    SPLIT LPW_PARAM AT '/*SM34 VCLDIR-VCLNAME=' INTO TABLE LT_STR.
  ENDIF.
  LOOP AT LT_STR INTO DATA(LS_STR).
    SPLIT LS_STR AT ';' INTO DATA(LW_TABNAME) DATA(LW_OTHER).
    SELECT SINGLE
      COUNT(*)
      FROM DD02L
      WHERE TABNAME = LW_TABNAME.
    IF SY-SUBRC = 0.
      LPW_TABNAME = LW_TABNAME.
      EXIT.
    ELSE.
      SELECT SINGLE
        COUNT(*)
        FROM VCLDIR
        WHERE VCLNAME = LW_TABNAME.
      IF SY-SUBRC = 0.
        LPW_TABNAME = LW_TABNAME.
        EXIT.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.

*
* 
