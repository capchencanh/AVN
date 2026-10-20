*&---------------------------------------------------------------------*
*& Include          YIN_PPIM01_LCL
*&---------------------------------------------------------------------*


CLASS LCL_READ_EXCEL_DC DEFINITION INHERITING FROM YCL_READ_EXCEL.
  PUBLIC SECTION.
    METHODS EXPORT_DATA FINAL REDEFINITION.
ENDCLASS.

CLASS LCL_READ_EXCEL_DC IMPLEMENTATION.
  METHOD EXPORT_DATA.
    DATA LS_DATA TYPE YST_UPLOAD_PSIC.
    DATA LT_DATA TYPE TABLE OF YST_UPLOAD_PSIC.
    LOOP AT GT_KEY_VALUE INTO DATA(LS_KEY_VAL).

      IF TO_UPPER(  LS_KEY_VAL-KEY ) = 'ITEM CODE'.
        CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
          EXPORTING
            INPUT        = LS_KEY_VAL-VALUE
          IMPORTING
            OUTPUT       = LS_DATA-MATNR
          EXCEPTIONS
            LENGTH_ERROR = 1
            OTHERS       = 2.
        IF SY-SUBRC <> 0.
* Implement suitable error handling here
        ENDIF.

      ENDIF.

      TRY.
          CL_ABAP_DATFM=>CONV_DATE_EXT_TO_INT(
            EXPORTING
              IM_DATEXT   = LS_KEY_VAL-KEY    " external representation of date
              IM_DATFMDES = '6'  " date format wanted for conversion
            IMPORTING
              EX_DATINT   = LS_DATA-KEYDATE    " internal representation of date
*             EX_DATFMUSED = EX_DATFMUSED " date format used for conversion
          ).

          "check lay thang hien tai tro di
          CHECK LS_DATA-KEYDATE >= P_DATE.

          "so luong ->check log loi field
          DATA: LV_FLOAT TYPE F.
          TRY.
              LV_FLOAT = LS_KEY_VAL-VALUE.
              LS_DATA-MENGE_UP = LV_FLOAT.
            CATCH CX_SY_CONVERSION_NO_NUMBER.
              LS_DATA-STATUS = C_ICON-WARNING.
              LS_DATA-MESSAGE = 'Số lượng upload sai định dạng'.
          ENDTRY.

          APPEND LS_DATA TO LT_DATA.
          CLEAR: LS_DATA-STATUS, LS_DATA-MESSAGE.

        CATCH CX_ABAP_DATFM_NO_DATE.        " Exception in Class CL_ABAP_DATFM - Input is not a date
        CATCH CX_ABAP_DATFM_INVALID_DATE.   " Exception in Class CL_ABAP_DATFM - Invalid date
        CATCH CX_ABAP_DATFM_FORMAT_UNKNOWN. " Exception in Class CL_ABAP_DATFM - Format unknown
        CATCH CX_ABAP_DATFM_AMBIGUOUS.      " Exception in Class CL_ABAP_DATFM - Ambiguous
      ENDTRY.

    ENDLOOP.

    DELETE LT_DATA WHERE MATNR IS INITIAL .
    T_DATA = LT_DATA.
  ENDMETHOD.
ENDCLASS.


CLASS LCL_PPIM01_DAILY_CTR DEFINITION.
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
               END OF C_ICON ,
               C_PLANT   TYPE BAPISITEMR-PLANT VALUE '4100',
               C_REQTYPE TYPE BAPISITEMR-REQU_TYPE VALUE 'BSF',
               C_VERSION TYPE BAPISITEMR-VERSION VALUE '00'.

    DATA GT_DATA TYPE TABLE OF YST_UPLOAD_PSIC.
    DATA GT_FIELDCAT TYPE LVC_T_FCAT.
    DATA GV_CHECK TYPE XFELD.

    "methods----------------------------------------------------------
    METHODS GET_DATA       .
    METHODS PROCESS_DATA   .
    METHODS BUILD_FCAT     .
    METHODS REFRESH_ALV    .
    METHODS: POST_DAILY,
      CHECK_DATA CHANGING LS_DATA TYPE YST_UPLOAD_PSIC ,
      DELETE_PSIC,
      DELETE_PIR_DAIL ,
      DELETE_MD62 IMPORTING I_MATNR    TYPE MATNR
                            I_REQPLANT TYPE PBDNR ,
      DELETE_PLANNED_ORDER,
      CREATE_PLANNED_ORDER,
      CREATE_MD61,
      SAVE_LOG,
      EXISTS_REQPLAN IMPORTING I_MATNR        TYPE MATNR
                               I_REQMTSPLAN   TYPE PBDNR
                     RETURNING VALUE(E_SUBRC) TYPE SY-SUBRC.

*    methods sel_all.
*    methods unsel_al.
*    methods post.

ENDCLASS.


CLASS LCL_PPIM01_DAILY_CTR IMPLEMENTATION.

  METHOD GET_DATA .
    DATA(LO_EXCEL) = NEW LCL_READ_EXCEL_DC( I_FILE = CONV #( P_INFILE ) I_FROM = 2 I_SHEET = CONV #( P_SHEET ) ).
    LO_EXCEL->EXPORT_DATA( IMPORTING T_DATA = ME->GT_DATA ).
    IF GT_DATA IS INITIAL.
      MESSAGE 'No data' TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.

  METHOD PROCESS_DATA   .
    DATA(LT_MATNR) = GT_DATA.
    SORT LT_MATNR BY MATNR.
    DELETE ADJACENT DUPLICATES FROM LT_MATNR.

    SELECT FROM @LT_MATNR AS DATA
          INNER JOIN MARA ON MARA~MATNR = DATA~MATNR
          LEFT JOIN YTB_MRP_MATTYPE AS A ON A~MTART = MARA~MTART
    FIELDS
      MARA~MATNR,
      MARA~MTART,
      MARA~MEINS,
      A~TPHAM,
      A~BTPHAM
    ORDER BY MARA~MATNR
    INTO TABLE @DATA(LT_MAT).

    SELECT FROM @GT_DATA AS A
      FIELDS
      A~MATNR,
      A~KEYDATE,
      SUM( A~MENGE_UP ) AS MENGE_UP
    GROUP BY A~MATNR, A~KEYDATE
    ORDER BY A~MATNR, A~KEYDATE
    INTO TABLE @DATA(LT_DATA).

    DATA(LO_CONV_INST) = CL_UOM_CONVERSION=>CREATE( ).

    DATA(LT_CHECK) = GT_DATA.
    SORT LT_CHECK BY MATNR KEYDATE STATUS DESCENDING.
    DELETE ADJACENT DUPLICATES FROM LT_CHECK COMPARING MATNR KEYDATE.
    DELETE LT_CHECK WHERE STATUS IS INITIAL.

    CLEAR GT_DATA.
    LOOP AT LT_DATA INTO DATA(LS_DATA).
      APPEND INITIAL LINE TO GT_DATA REFERENCE INTO DATA(LR_DATA).
      LR_DATA->* = CORRESPONDING #( LS_DATA ).
      LR_DATA->DATEHL = P_DATE.
      LR_DATA->STATUS = C_ICON-NONE.
      LR_DATA->MEINS_UP = P_MSEHI.
      LR_DATA->PBDNR = 'LTKHSX' && LS_DATA-KEYDATE+4(2) && LS_DATA-KEYDATE+2(2).

      READ TABLE LT_MAT INTO DATA(LS_MAT) WITH KEY MATNR = LR_DATA->MATNR BINARY SEARCH.
      IF SY-SUBRC = 0.
        LR_DATA->BANTPHAM = LS_MAT-BTPHAM.
        LR_DATA->THANHPHAM = LS_MAT-TPHAM.
        LR_DATA->MEINS_QD = LS_MAT-MEINS.

        LO_CONV_INST->UNIT_CONVERSION_SIMPLE( EXPORTING  INPUT                = LR_DATA->MENGE_UP
                                                         ROUND_SIGN           = ''
                                                         UNIT_IN              = LR_DATA->MEINS_UP
                                                         UNIT_OUT             = LR_DATA->MEINS_QD
                                              IMPORTING  OUTPUT               = LR_DATA->MENGE_QD
                                              EXCEPTIONS CONVERSION_NOT_FOUND = 01
                                                         DIVISION_BY_ZERO     = 02
                                                         INPUT_INVALID        = 03
                                                         OUTPUT_INVALID       = 04
                                                         OVERFLOW             = 05
                                                         UNITS_MISSING        = 06
                                                         UNIT_IN_NOT_FOUND    = 07
                                                         UNIT_OUT_NOT_FOUND   = 08 ).
        IF SY-SUBRC <> 0.
          LR_DATA->STATUS = C_ICON-FAIL.
          MESSAGE ID SY-MSGID  TYPE SY-MSGTY NUMBER SY-MSGNO
          WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 INTO LR_DATA->MESSAGE.
        ENDIF.
      ENDIF.

      READ TABLE LT_CHECK INTO DATA(LS_CHECK) WITH KEY MATNR = LR_DATA->MATNR
                                                     KEYDATE = LR_DATA->KEYDATE
                                   BINARY SEARCH.
      IF SY-SUBRC = 0.
        LR_DATA->STATUS = LS_CHECK-STATUS.
        LR_DATA->MESSAGE = LS_CHECK-MESSAGE.
      ENDIF.

      CHECK_DATA(
        CHANGING
          LS_DATA = LR_DATA->*
      ).

    ENDLOOP.

    SORT GT_DATA BY MATNR PBDNR.

  ENDMETHOD.


  METHOD BUILD_FCAT .

    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        I_STRUCTURE_NAME       = 'YST_UPLOAD_PSIC'
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
        WHEN 'MATNR'.
        WHEN 'KEYDATE'.
          <FS_FCAT>-COL_POS = 2.
          LV_COLTEXT = 'Date'.
        WHEN 'MENGE_UP'.
          LV_COLTEXT = 'Số lượng upload'.
        WHEN 'MEINS_UP'.
          LV_COLTEXT = 'Đơn vị upload'.
        WHEN 'MENGE_QD'.
          LV_COLTEXT = 'Số lượng quy đổi'.
        WHEN 'MEINS_QD'.
          LV_COLTEXT = 'Base Unit'.
        WHEN 'THANHPHAM'.
          LV_COLTEXT = 'Thành phẩm'.
        WHEN 'BANTPHAM'.
          LV_COLTEXT = 'Bán thành phẩm'.
        WHEN 'STATUS'.
          LV_COLTEXT = 'Status'.
        WHEN 'MESSAGE'.
          LV_COLTEXT = 'Message'.
        WHEN 'PBDNR'.
        WHEN 'DATEHL'.
          LV_COLTEXT = 'Ngày hiệu lực'.
        WHEN OTHERS.
          <FS_FCAT>-TECH = ABAP_TRUE.
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

  METHOD POST_DAILY.
    IF GV_CHECK IS INITIAL AND LINE_EXISTS( GT_DATA[ STATUS = C_ICON-WARNING ] ) .
      MESSAGE 'Số lượng upload sai định dạng. Kiểm tra lại trước khi post' TYPE 'S' DISPLAY LIKE 'W'.
      GV_CHECK = ABAP_TRUE.
      RETURN.
    ENDIF.
    LOOP AT GT_DATA REFERENCE INTO DATA(LR_DATA) WHERE STATUS = C_ICON-WARNING.
      LR_DATA->STATUS = C_ICON-NONE.
      CLEAR LR_DATA->MESSAGE.
    ENDLOOP.

    IF NOT LINE_EXISTS( GT_DATA[ STATUS = C_ICON-NONE ] ).
      MESSAGE 'No dataa to post' TYPE 'S'.
      RETURN.
    ENDIF.

    "Delete PSIC - PIRs Daily
    DELETE_PSIC( ).
    DELETE_PIR_DAIL( ).

    "Delete Planned order
    DELETE_PLANNED_ORDER( ).

    "Tạo lại dữ liệu PIRs theo ngày
    CREATE_MD61( ).

    "Tạo dữ liệu Planned Order firm theo ngày
    CREATE_PLANNED_ORDER( ).

    SAVE_LOG( ).
  ENDMETHOD.

  METHOD CHECK_DATA .
    IF LS_DATA-THANHPHAM IS INITIAL AND LS_DATA-BANTPHAM IS INITIAL.
      LS_DATA-STATUS = C_ICON-FAIL.
      LS_DATA-MESSAGE = 'Mã chưa được khai báo là thành phẩm hoặc bán thành phẩm!'.
    ENDIF.

    IF LS_DATA-MENGE_UP < 0.
      LS_DATA-STATUS = C_ICON-FAIL.
      LS_DATA-MESSAGE = 'Không có số lượng!'.
    ENDIF.

  ENDMETHOD.

  METHOD DELETE_PSIC.
    DATA: LS_REQ_ITEM   TYPE BAPISITEMR,
          LV_REQMTSPLAN TYPE BAPISITEMR-REQ_NUMBER,
          LT_RETURN     TYPE STANDARD TABLE OF BAPIRETURN1.

    DATA(LT_DELETE) = GT_DATA.
    DELETE LT_DELETE WHERE STATUS <> C_ICON-NONE.
    DELETE ADJACENT DUPLICATES FROM LT_DELETE COMPARING MATNR .

    LOOP AT LT_DELETE INTO DATA(LS_DATA).
      DELETE_MD62( I_MATNR = LS_DATA-MATNR I_REQPLANT = 'LTFPSIC' ).
    ENDLOOP.

  ENDMETHOD.

  METHOD DELETE_PIR_DAIL.
    DATA: LS_REQ_ITEM   TYPE BAPISITEMR,
          LV_REQMTSPLAN TYPE BAPISITEMR-REQ_NUMBER,
          LT_RETURN     TYPE STANDARD TABLE OF BAPIRETURN1.

    DATA(LT_DELETE) = GT_DATA.
    DELETE LT_DELETE WHERE STATUS <> C_ICON-NONE.
    DELETE ADJACENT DUPLICATES FROM LT_DELETE COMPARING MATNR PBDNR.

    LOOP AT LT_DELETE INTO DATA(LS_DATA).
      DELETE_MD62( I_MATNR = LS_DATA-MATNR I_REQPLANT = LS_DATA-PBDNR ).
    ENDLOOP.
  ENDMETHOD.

  METHOD DELETE_MD62.
    DATA: LS_REQ_ITEM TYPE BAPISITEMR,
          LT_RETURN   TYPE STANDARD TABLE OF BAPIRETURN1.

    LS_REQ_ITEM-PLANT = C_PLANT.
    LS_REQ_ITEM-MATERIAL = I_MATNR.
    LS_REQ_ITEM-REQU_TYPE = C_REQTYPE.
    LS_REQ_ITEM-REQ_NUMBER = I_REQPLANT.
    LS_REQ_ITEM-VERSION = C_VERSION.
    LS_REQ_ITEM-VERS_ACTIV = ABAP_TRUE.
    LS_REQ_ITEM-MRP_AREA   = P_BERID.
    IF EXISTS_REQPLAN( I_MATNR = I_MATNR  I_REQMTSPLAN = I_REQPLANT  ) =  0.

      IF I_REQPLANT = 'LTFPSIC'.
        DATA(LT_SCHEL) = GT_DATA.
        DELETE LT_SCHEL WHERE MATNR <> LS_REQ_ITEM-MATERIAL.
        LOOP AT LT_SCHEL REFERENCE INTO DATA(LS_SHCEL).
          LS_SHCEL->KEYDATE+6(2) = '01'.
        ENDLOOP.
        SORT LT_SCHEL BY KEYDATE.
        DELETE ADJACENT DUPLICATES FROM LT_SCHEL COMPARING KEYDATE.
        DATA LT_REQSHEL TYPE TABLE OF BAPISSHDIN.
        LOOP AT LT_SCHEL REFERENCE INTO LS_SHCEL.
          APPEND INITIAL LINE TO LT_REQSHEL REFERENCE INTO DATA(LS_REQ_SCHEDULE).
          LS_REQ_SCHEDULE->DATE_TYPE = '3'.
          LS_REQ_SCHEDULE->REQ_DATE = LS_SHCEL->KEYDATE.
          LS_REQ_SCHEDULE->REQ_QTY = 0.
        ENDLOOP.

        DATA(LV_DELETE_OLD) = VALUE BAPISPARAM-DELETE_OLD( ).
      ELSE.
        LV_DELETE_OLD = ABAP_TRUE.
      ENDIF.

      CALL FUNCTION 'BAPI_REQUIREMENTS_CHANGE'
        EXPORTING
          MATERIAL                 = LS_REQ_ITEM-MATERIAL
          PLANT                    = LS_REQ_ITEM-PLANT
          REQUIREMENTSTYPE         = LS_REQ_ITEM-REQU_TYPE
          VERSION                  = LS_REQ_ITEM-VERSION
          REQMTSPLANNUMBER         = LS_REQ_ITEM-REQ_NUMBER
          VERS_ACTIV               = LS_REQ_ITEM-VERS_ACTIV
          MRP_AREA                 = LS_REQ_ITEM-MRP_AREA
          DELETE_OLD               = LV_DELETE_OLD
          DO_COMMIT                = ABAP_FALSE
        TABLES
          REQUIREMENTS_SCHEDULE_IN = LT_REQSHEL
          RETURN                   = LT_RETURN.

      IF LINE_EXISTS( LT_RETURN[ TYPE = 'E' ] ) OR LINE_EXISTS( LT_RETURN[ TYPE = 'A' ] ).
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING WAIT = 'X'.
        WAIT UP TO '0.5' SECONDS.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD DELETE_PLANNED_ORDER.

    CONSTANTS:
* Planauftragsarten:
      PAA_STOCK_ORDER TYPE PLAF-PAART VALUE 'LA', "Lagerauftrag
      PAA_RS_QUANT    TYPE PLAF-PAART VALUE 'PE', "Produktionseinteilung
      PAA_CUST_ORDER  TYPE PLAF-PAART VALUE 'KD', "Kundeneinzelauftrag
      PAA_PROJ_ORDER  TYPE PLAF-PAART VALUE 'PR'. "Projektauftrag

    DATA:
      LR_MATNR TYPE RANGE OF MATNR,
      LR_PAART TYPE RANGE OF PAART,
      LR_REMFL TYPE RANGE OF REMFL,
      LR_PSTTR TYPE RANGE OF PSTTR.

* fill range for order types to select
    LR_PAART = VALUE #( SIGN = 'I' OPTION = 'EQ' ( LOW = PAA_STOCK_ORDER )
                                                 ( LOW = PAA_RS_QUANT )
                                                 ( LOW = PAA_CUST_ORDER )
                                                 ( LOW = PAA_PROJ_ORDER ) ).
    LR_REMFL = VALUE #( SIGN = 'I' OPTION = 'EQ' ( LOW = 'X' ) ).

    LR_MATNR = VALUE #( FOR I IN GT_DATA
                        ( SIGN = 'I' OPTION = 'EQ' LOW = I-MATNR ) ).
    SORT LR_MATNR BY LOW.
    DELETE ADJACENT DUPLICATES FROM LR_MATNR COMPARING LOW.

    APPEND INITIAL LINE TO LR_PSTTR REFERENCE INTO DATA(LV_PSTTR).
    LV_PSTTR->SIGN = 'I'. LV_PSTTR->OPTION = 'BT'.
    SELECT
      MAX( KEYDATE ) AS MAXDATE,
      MIN( KEYDATE ) AS MINDATE
    FROM @GT_DATA AS A
    INTO ( @LV_PSTTR->HIGH, @LV_PSTTR->LOW ) .

    SELECT PLNUM FROM PLAF
              WHERE MATNR IN @LR_MATNR[]
              AND   VERID EQ  '0801'
              AND   PWWRK EQ  '4100'
              AND   PSTTR IN @LR_PSTTR[] " 8
              AND   PAART IN @LR_PAART[]
              AND    ( REMFL IN @LR_REMFL[] OR
                       REMFL IS NULL )
              AND   BESKZ EQ 'E'
              AND   AUFFX EQ 'X'
    INTO TABLE @DATA(LT_PLAF).

    DATA LS_RETURN          TYPE BAPIRETURN1.
    LOOP AT LT_PLAF INTO DATA(LS_PLAF).
      CALL FUNCTION 'BAPI_PLANNEDORDER_DELETE'
        EXPORTING
          PLANNEDORDER = LS_PLAF-PLNUM
*         USE_COLL_UPDATE       = ' '
*         LAST_ORDER   = ' '
        IMPORTING
          RETURN       = LS_RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD CREATE_MD61.

    DATA: LS_REQ_ITEM     TYPE BAPISITEMR,
          LV_REQMTSPLAN   TYPE BAPISITEMR-REQ_NUMBER,
          LT_REQ_SCHEDULE TYPE STANDARD TABLE OF BAPISSHDIN,
          LT_RETURN       TYPE STANDARD TABLE OF BAPIRETURN1.

    DATA(LT_POST) = GT_DATA.
    DELETE LT_POST WHERE THANHPHAM IS INITIAL OR STATUS <> C_ICON-NONE.
    DATA(LT_ITEM) =  LT_POST.
    DELETE ADJACENT DUPLICATES FROM LT_POST COMPARING MATNR PBDNR.

    DATA: LV_TABIX TYPE I.
    LV_TABIX = 1.
    LOOP AT LT_POST INTO DATA(LS_POST).

      LS_REQ_ITEM-MRP_AREA  = P_BERID.
      LS_REQ_ITEM-REQ_NUMBER  = LS_POST-PBDNR.
      LS_REQ_ITEM-PLANT = C_PLANT.
      LS_REQ_ITEM-MATERIAL = LS_POST-MATNR.
      LS_REQ_ITEM-REQU_TYPE = C_REQTYPE.
      LS_REQ_ITEM-VERSION = C_VERSION.
      LS_REQ_ITEM-VERS_ACTIV = ABAP_TRUE.

      LOOP AT LT_ITEM INTO DATA(LS_DATA) FROM LV_TABIX.
        IF LS_DATA-MATNR = LS_POST-MATNR AND LS_DATA-PBDNR = LS_POST-PBDNR.
          APPEND INITIAL LINE TO LT_REQ_SCHEDULE REFERENCE INTO DATA(LS_REQ_SCHEDULE).
          LS_REQ_SCHEDULE->DATE_TYPE = '1'.
          LS_REQ_SCHEDULE->REQ_DATE = LS_DATA-KEYDATE.
          LS_REQ_SCHEDULE->REQ_QTY = LS_DATA-MENGE_QD.

        ELSE.
          LV_TABIX = SY-TABIX.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF EXISTS_REQPLAN( I_MATNR = LS_POST-MATNR  I_REQMTSPLAN = LS_POST-PBDNR ) <> 0.
        "create
        CALL FUNCTION 'BAPI_REQUIREMENTS_CREATE'
          EXPORTING
            REQUIREMENTS_ITEM        = LS_REQ_ITEM
          TABLES
            REQUIREMENTS_SCHEDULE_IN = LT_REQ_SCHEDULE
            RETURN                   = LT_RETURN.

      ELSE.

        "Update
        CALL FUNCTION 'BAPI_REQUIREMENTS_CHANGE'
          EXPORTING
            MATERIAL                 = LS_REQ_ITEM-MATERIAL
            PLANT                    = LS_REQ_ITEM-PLANT
            REQUIREMENTSTYPE         = LS_REQ_ITEM-REQU_TYPE
            VERSION                  = LS_REQ_ITEM-VERSION
            REQMTSPLANNUMBER         = LS_REQ_ITEM-REQ_NUMBER
            VERS_ACTIV               = LS_REQ_ITEM-VERS_ACTIV
            MRP_AREA                 = LS_REQ_ITEM-MRP_AREA
            DELETE_OLD               = ABAP_FALSE
            DO_COMMIT                = ABAP_TRUE
          TABLES
            REQUIREMENTS_SCHEDULE_IN = LT_REQ_SCHEDULE
            RETURN                   = LT_RETURN.

      ENDIF.

      IF LINE_EXISTS( LT_RETURN[ TYPE = 'E' ] ) OR LINE_EXISTS( LT_RETURN[ TYPE = 'A' ] ).
        DATA(LV_FAIL) = ABAP_TRUE.
      ELSE.
        COMMIT WORK AND WAIT.
      ENDIF.

      LOOP AT GT_DATA REFERENCE INTO DATA(LR_DATA) WHERE MATNR = LS_POST-MATNR AND PBDNR = LS_POST-PBDNR.
        LR_DATA->STATUS = COND #( WHEN LV_FAIL IS NOT INITIAL THEN C_ICON-FAIL
                                                              ELSE C_ICON-SUCCESS ).
        DATA(LS_MESS) = VALUE #( LT_RETURN[ 1 ] OPTIONAL ).
        IF LS_MESS IS NOT INITIAL.
          MESSAGE ID LS_MESS-ID  TYPE LS_MESS-TYPE NUMBER LS_MESS-NUMBER
          WITH LS_MESS-MESSAGE_V1 LS_MESS-MESSAGE_V2 LS_MESS-MESSAGE_V3 LS_MESS-MESSAGE_V4 INTO LR_DATA->MESSAGE.
        ENDIF.
      ENDLOOP.

      CLEAR : LT_RETURN, LT_REQ_SCHEDULE, LS_REQ_ITEM, LV_FAIL.

    ENDLOOP.

  ENDMETHOD.

  METHOD CREATE_PLANNED_ORDER.

    DATA LS_HEADERDATA            TYPE BAPIPLAF_I1.
    DATA LS_RETURN                TYPE BAPIRETURN1.
    DATA LV_PLANNEDORDER          TYPE BAPI_PLDORD-PLDORD_NUM.

    LOOP AT GT_DATA REFERENCE INTO DATA(LS_DATA) WHERE BANTPHAM = ABAP_TRUE AND STATUS = C_ICON-NONE.
      LS_HEADERDATA-PLDORD_PROFILE = 'LA'.
      LS_HEADERDATA-PLAN_PLANT = C_PLANT.
      LS_HEADERDATA-MATERIAL = LS_DATA->MATNR.
      LS_HEADERDATA-MRP_AREA = P_BERID.
      LS_HEADERDATA-ORDER_START_DATE = LS_DATA->KEYDATE.
      LS_HEADERDATA-TOTAL_PLORD_QTY = LS_DATA->MENGE_QD.
      LS_HEADERDATA-VERSION = '0801'.
      LS_HEADERDATA-PLDORD_TEXT = LS_DATA->PBDNR.
      LS_HEADERDATA-FIRMING_IND = 'X'.

      CALL FUNCTION 'BAPI_PLANNEDORDER_CREATE'
        EXPORTING
          HEADERDATA   = LS_HEADERDATA
        IMPORTING
          RETURN       = LS_RETURN
          PLANNEDORDER = LV_PLANNEDORDER.
      IF ( LS_RETURN-TYPE = 'E' OR LS_RETURN-TYPE = 'A' ) AND LS_HEADERDATA-TOTAL_PLORD_QTY <> 0.
        LS_DATA->STATUS = C_ICON-FAIL.
        MESSAGE ID LS_RETURN-ID  TYPE LS_RETURN-TYPE NUMBER LS_RETURN-NUMBER
          WITH LS_RETURN-MESSAGE_V1 LS_RETURN-MESSAGE_V2 LS_RETURN-MESSAGE_V3 LS_RETURN-MESSAGE_V4 INTO LS_DATA->MESSAGE.
      ELSE.
        LS_DATA->STATUS = C_ICON-SUCCESS.
        LS_DATA->PLNUM = LV_PLANNEDORDER.
        COMMIT WORK AND WAIT.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD SAVE_LOG.
    DATA LV_LONG_TIME_STAMP  TYPE TIMESTAMPL.
    GET TIME STAMP FIELD LV_LONG_TIME_STAMP.

    DATA LT_DEMAND TYPE TABLE OF YTB_MRP_DEMAND.
    LT_DEMAND = VALUE #( FOR I IN GT_DATA WHERE ( STATUS = C_ICON-SUCCESS )
    ( PUID      = CL_SYSTEM_UUID=>IF_SYSTEM_UUID_RFC4122_STATIC~CREATE_UUID_C36_BY_VERSION( VERSION = 4 )
      CRT_USER  = SY-UNAME
      CRT_DATE  = SY-DATUM
      BERID     = P_BERID
      MATNR     = I-MATNR
      DATE_DC   = I-KEYDATE
      YMONTH    = I-MONTH
      GJAHR     = I-GJAHR
      MENGE_UP  = I-MENGE_UP
      MEINS_UP  = I-MEINS_UP
      MENGE_QD  = I-MENGE_QD
      MEINS_QD  = I-MEINS_QD
      THANHPHAM = I-THANHPHAM
      BANTPHAM  = I-BANTPHAM
      DAILY_CD = 'X'
      UPD_PIRS  = COND #( WHEN I-THANHPHAM = 'X' THEN 'X' ELSE '' )
      UPD_PLORDER  = COND #( WHEN I-BANTPHAM = 'X' THEN 'X' ELSE '' )
      PLNUM  = I-PLNUM
      DATEHL = I-DATEHL
      TIMESTAMPL = LV_LONG_TIME_STAMP ) ).
    INSERT YTB_MRP_DEMAND FROM TABLE LT_DEMAND.
    IF SY-SUBRC = 0.
      MESSAGE 'Save data success' TYPE 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD EXISTS_REQPLAN.

    SELECT COUNT(*)
        FROM PBID
        WHERE PBDNR = I_REQMTSPLAN
          AND MATNR = I_MATNR
          AND BERID = P_BERID
          AND VERSB = C_VERSION
          AND WERKS = C_PLANT
          AND BEDAE = C_REQTYPE.
    E_SUBRC = SY-SUBRC.

  ENDMETHOD.

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
    DATA: LS_TOOLBAR TYPE STB_BUTTON.
    DEFINE ADD_BUTTON.
      ls_toolbar-function  = &1.
      ls_toolbar-icon      = &2.
      ls_toolbar-quickinfo = &3.
      ls_toolbar-text      = &3.
      ls_toolbar-butn_type = 0.
      append ls_toolbar to e_object->mt_toolbar.
      clear ls_toolbar.
    END-OF-DEFINITION.
*    ADD_BUTTON C_USRCMD-SEL ICON_SELECT_ALL  ''.
*    ADD_BUTTON C_USRCMD-UNSEL ICON_DESELECT_ALL  ''.
    ADD_BUTTON C_USRCMD-POST ICON_RELEASE  'Post'.
  ENDMETHOD.

  METHOD USER_COMMAND.
    CHECK GR_DAILY_CTR IS BOUND.
    CASE E_UCOMM.
*      WHEN C_USRCMD-SEL.
*        GO_UPPSIC->REFRESH_ALV( ).
*      WHEN C_USRCMD-UNSEL.
*        GO_UPPSIC->REFRESH_ALV( ).
      WHEN C_USRCMD-POST.
        GR_DAILY_CTR->POST_DAILY( ).
        GR_DAILY_CTR->REFRESH_ALV( ).
    ENDCASE.
  ENDMETHOD.


ENDCLASS.

*
* 
