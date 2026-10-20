*&---------------------------------------------------------------------*
*& Include          YIN_PPIM01_LCL
*&---------------------------------------------------------------------*

CLASS LCL_PPIM01_HIS DEFINITION.
  PUBLIC SECTION.

    "data define----------------------------------------------------------
    CONSTANTS: BEGIN OF C_USRCMD,
                 SEL   TYPE SY-UCOMM VALUE '&SEL',
                 DESEL TYPE SY-UCOMM VALUE '&DESEL',
                 POST  TYPE SY-UCOMM VALUE '&POST',
               END OF C_USRCMD,
               BEGIN OF C_ICON,
                 SUCCESS TYPE ICON_D VALUE ICON_GREEN_LIGHT,
                 FAIL    TYPE ICON_D VALUE ICON_RED_LIGHT,
                 WARNING TYPE ICON_D VALUE ICON_YELLOW_LIGHT,
                 NONE    TYPE ICON_D VALUE ICON_LIGHT_OUT,
               END OF C_ICON .


    DATA GT_DATA TYPE TABLE OF YST_MRP_DEMAND.
    DATA GT_FIELDCAT TYPE LVC_T_FCAT.
    DATA GV_CHECK TYPE XFELD.

    "methods----------------------------------------------------------
    METHODS GET_DATA       .
    METHODS PROCESS_DATA   .
    METHODS BUILD_FCAT     .
    METHODS REFRESH_ALV    .


*    methods sel_all.
*    methods unsel_al.
*    methods post.

ENDCLASS.


CLASS LCL_PPIM01_HIS IMPLEMENTATION.

  METHOD GET_DATA .
    SELECT FROM YTB_MRP_DEMAND AS A
      FIELDS
      A~*
      WHERE BERID = @P_BERID
        AND MATNR IN @S_MATNR
        AND CONCAT( GJAHR , YMONTH ) IN @S_MONTH
        AND CRT_DATE IN @S_DATE
        AND CRT_USER IN @S_USER
        AND ( ( PSIC_DATA = @P_PSIC AND @P_PSIC IS NOT INITIAL )
        OR  ( DAILY_CD = @P_DAIL AND @P_DAIL IS NOT INITIAL ) )
    INTO CORRESPONDING FIELDS OF TABLE @GT_DATA.
    IF SY-SUBRC <> 0.
      MESSAGE 'No data' TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.

  METHOD PROCESS_DATA   .

    LOOP AT GT_DATA REFERENCE INTO DATA(LS_DATA).
      DATA: LV_DATE TYPE DATS,
            LV_TIME TYPE TIMS.
      CONVERT TIME STAMP LS_DATA->TIMESTAMPL TIME ZONE SY-ZONLO INTO DATE LV_DATE TIME LV_TIME.
      LS_DATA->TIME = LV_TIME.
    ENDLOOP.

  ENDMETHOD.


  METHOD BUILD_FCAT .

    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        I_STRUCTURE_NAME       = 'YST_MRP_DEMAND'
      CHANGING
        CT_FIELDCAT            = GT_FIELDCAT
      EXCEPTIONS
        INCONSISTENT_INTERFACE = 1
        PROGRAM_ERROR          = 2
        OTHERS                 = 3.
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
                   WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

    DATA LV_COLTEXT TYPE STRING.
    LOOP AT GT_FIELDCAT ASSIGNING FIELD-SYMBOL(<FS_FCAT>).
      CASE <FS_FCAT>-FIELDNAME.
        WHEN 'MANDT' OR 'PUID'. <FS_FCAT>-TECH = ABAP_TRUE.
      ENDCASE.
      IF LV_COLTEXT IS NOT INITIAL.
        <FS_FCAT>-COLTEXT = <FS_FCAT>-SELTEXT  = <FS_FCAT>-REPTEXT = LV_COLTEXT.
        <FS_FCAT>-SCRTEXT_S = <FS_FCAT>-SCRTEXT_M = <FS_FCAT>-SCRTEXT_L = LV_COLTEXT .
      ENDIF.
      CLEAR LV_COLTEXT.
    ENDLOOP.

  ENDMETHOD.


  METHOD REFRESH_ALV.
    IF GO_GRID IS BOUND.
      GO_GRID->REFRESH_TABLE_DISPLAY(
        EXPORTING
          IS_STABLE = VALUE #( ROW = 'X' COL = 'X' )    " With Stable Rows/Columns
*         i_soft_refresh = i_soft_refresh    " Without Sort, Filter, etc.
        EXCEPTIONS
          FINISHED  = 1
      ).
      IF SY-SUBRC <> 0.
        MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
                   WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF..
      IF SY-SUBRC <> 0.
      ENDIF.
    ENDIF.
  ENDMETHOD.

*  method sel_all.
*    go_alv->get_filtered_entries(
*      importing
*        et_filtered_entries = data(lt_filter)    " Hash Table of Filtered Entries
*    ).
*    loop at gt_data reference into data(ls_data).
*      if not line_exists( lt_filter[ table_line = sy-tabix ] )
*         and ls_data->style is initial.
*        ls_data->sel = abap_true.
*      endif.
*    endloop.
*  endmethod.
*
*  method unsel_all.
*    loop at gt_data reference into data(ls_data).
*      ls_data->sel = abap_false.
*    endloop.
*  endmethod.


ENDCLASS.

CLASS LCL_HANDLE DEFINITION.
  PUBLIC SECTION.
    METHODS:
      USER_COMMAND FOR EVENT USER_COMMAND OF CL_GUI_ALV_GRID
        IMPORTING
          E_UCOMM
          SENDER,
      TOOLBAR FOR EVENT TOOLBAR OF CL_GUI_ALV_GRID
        IMPORTING
          E_INTERACTIVE
          E_OBJECT
          SENDER.

ENDCLASS.

CLASS LCL_HANDLE IMPLEMENTATION.


  METHOD TOOLBAR.
*    DATA: LS_TOOLBAR TYPE STB_BUTTON.
*    DEFINE ADD_BUTTON.
*      ls_toolbar-function  = &1.
*      ls_toolbar-icon      = &2.
*      ls_toolbar-quickinfo = &3.
*      ls_toolbar-text      = &3.
*      ls_toolbar-butn_type = 0.
*      append ls_toolbar to e_object->mt_toolbar.
*      clear ls_toolbar.
*    END-OF-DEFINITION.
**    ADD_BUTTON C_USRCMD-SEL ICON_SELECT_ALL  ''.
**    ADD_BUTTON C_USRCMD-UNSEL ICON_DESELECT_ALL  ''.
*    ADD_BUTTON C_USRCMD-POST ICON_RELEASE  'Post'.
  ENDMETHOD.

  METHOD USER_COMMAND.
  ENDMETHOD.

ENDCLASS.

*
* 
