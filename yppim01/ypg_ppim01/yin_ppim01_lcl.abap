*&---------------------------------------------------------------------*
*& Include          YIN_PPIM01_LCL
*&---------------------------------------------------------------------*


CLASS LCL_READ_EXCEL_PIC DEFINITION INHERITING FROM YCL_READ_EXCEL.
  PUBLIC SECTION.
    METHODS EXPORT_DATA FINAL REDEFINITION.
ENDCLASS.

CLASS LCL_READ_EXCEL_PIC IMPLEMENTATION.
  METHOD EXPORT_DATA.
    DATA LS_DATA TYPE YST_UPLOAD_PSIC.
    DATA LT_DATA TYPE TABLE OF YST_UPLOAD_PSIC.
    DATA LV_CALC_DATE TYPE P0001-BEGDA.


    CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
      EXPORTING
        "phucnl add begin 07.09.2026
        DATE      = CONV D( SY-DATUM(6) && '01' )
        "phucnl add end 07.09.2026
        DAYS      = 0
        MONTHS    = 1
        YEARS     = 0
      IMPORTING
        CALC_DATE = LV_CALC_DATE.

    LOOP AT GT_KEY_VALUE INTO DATA(LS_KEY_VAL).

      IF TO_UPPER(  LS_KEY_VAL-KEY ) = 'MATERAIL NO'.
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
      CHECK STRLEN( LS_KEY_VAL-KEY ) > 10.
      IF TO_UPPER( LS_KEY_VAL-KEY+10 ) = 'PACK'.
        TRY.
            CL_ABAP_DATFM=>CONV_DATE_EXT_TO_INT(
              EXPORTING
                IM_DATEXT   = CONV #( LS_KEY_VAL-KEY(10) )    " external representation of date
                IM_DATFMDES = '6'  " date format wanted for conversion
              IMPORTING
                EX_DATINT   = LS_DATA-KEYDATE    " internal representation of date
*               EX_DATFMUSED = EX_DATFMUSED " date format used for conversion
            ).

            LS_DATA-MONTH = LS_DATA-KEYDATE+4(2).
            LS_DATA-GJAHR = LS_DATA-KEYDATE(4).
            "check lay thang hien tai + 1 tro di
            CHECK LS_DATA-GJAHR && LS_DATA-MONTH >= LV_CALC_DATE(6).

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


      ENDIF.
    ENDLOOP.
    DELETE LT_DATA WHERE MATNR IS INITIAL OR MONTH IS INITIAL OR GJAHR IS INITIAL.
    T_DATA = LT_DATA.
  ENDMETHOD.
ENDCLASS.


CLASS LCL_PPIM01_PSIC DEFINITION.
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
               END OF C_ICON,
               C_PLANT      TYPE BAPISITEMR-PLANT VALUE '4100',
               C_REQTYPE    TYPE BAPISITEMR-REQU_TYPE VALUE 'BSF',
               C_VERSION    TYPE BAPISITEMR-VERSION VALUE '00',
               C_REQMTSPLAN TYPE BAPISITEMR-REQ_NUMBER VALUE 'LTFPSIC'.

    DATA GT_DATA TYPE TABLE OF YST_UPLOAD_PSIC.
    DATA GT_FIELDCAT TYPE LVC_T_FCAT.
    DATA GV_CHECK TYPE XFELD.

    "methods----------------------------------------------------------
    METHODS GET_DATA       .
    METHODS PROCESS_DATA   .
    METHODS BUILD_FCAT     .
    METHODS REFRESH_ALV    .
    METHODS: POST_PIC,
      CHECK_DATA CHANGING LS_DATA TYPE YST_UPLOAD_PSIC ,
      DELETE_MD74,
      CREATE_MD61,
      SAVE_LOG,
      EXISTS_REQPLAN IMPORTING I_MATNR        TYPE MATNR
                     RETURNING VALUE(E_SUBRC) TYPE SY-SUBRC.

*    methods sel_all.
*    methods unsel_al.
*    methods post.

ENDCLASS.


CLASS LCL_PPIM01_PSIC IMPLEMENTATION.

  METHOD GET_DATA .
    DATA(LO_EXCEL) = NEW LCL_READ_EXCEL_PIC( I_FILE  = CONV #( P_INFILE )
                                             I_FROM  = 12
                                             I_TO    = 13
                                             I_SHEET = CONV #( P_SHEET ) ).
    LO_EXCEL->EXPORT_DATA( IMPORTING T_DATA = ME->GT_DATA ).
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
      A~MONTH,
      A~GJAHR,
      SUM( A~MENGE_UP ) AS MENGE_UP
    GROUP BY A~MATNR, A~MONTH, A~GJAHR
    ORDER BY A~MATNR, A~MONTH, A~GJAHR
    INTO TABLE @DATA(LT_DATA).

    DATA(LO_CONV_INST) = CL_UOM_CONVERSION=>CREATE( ).

    DATA(LT_CHECK) = GT_DATA.
    SORT LT_CHECK BY MATNR MONTH GJAHR STATUS DESCENDING.
    DELETE ADJACENT DUPLICATES FROM LT_CHECK COMPARING MATNR MONTH GJAHR.
    DELETE LT_CHECK WHERE STATUS IS INITIAL.

    CLEAR GT_DATA.
    LOOP AT LT_DATA INTO DATA(LS_DATA).
      APPEND INITIAL LINE TO GT_DATA REFERENCE INTO DATA(LR_DATA).
      LR_DATA->* = CORRESPONDING #( LS_DATA ).
      LR_DATA->STATUS = C_ICON-NONE.
      LR_DATA->MEINS_UP = P_MSEHI.
      LR_DATA->KEYDATE = LR_DATA->GJAHR && LR_DATA->MONTH && '01'.

      READ TABLE LT_MAT INTO DATA(LS_MAT) WITH KEY MATNR = LR_DATA->MATNR BINARY SEARCH.
      IF SY-SUBRC = 0.
        LR_DATA->BANTPHAM = LS_MAT-BTPHAM.
        LR_DATA->THANHPHAM = LS_MAT-TPHAM.
        LR_DATA->MEINS_QD = LS_MAT-MEINS.

        READ TABLE LT_CHECK INTO DATA(LS_CHECK) WITH KEY MATNR = LR_DATA->MATNR
                                               MONTH = LR_DATA->MONTH
                                               GJAHR = LR_DATA->GJAHR
                             BINARY SEARCH.
        IF SY-SUBRC = 0.
          LR_DATA->STATUS = LS_CHECK-STATUS.
          LR_DATA->MESSAGE = LS_CHECK-MESSAGE.
        ENDIF.

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
          WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 INTO DATA(LV_MESS).
          IF LR_DATA->MESSAGE IS INITIAL.
            LR_DATA->MESSAGE = LV_MESS.
          ELSE.
            LR_DATA->MESSAGE = |{ LR_DATA->MESSAGE }, { LV_MESS }|.
          ENDIF.
        ENDIF.
      ENDIF.

      CHECK_DATA(
        CHANGING
          LS_DATA = LR_DATA->*
      ).

    ENDLOOP.

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
        WHEN 'MONTH'.
          LV_COLTEXT = 'Month'.
        WHEN 'GJAHR'.
          LV_COLTEXT = 'Year'.
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

  METHOD POST_PIC.
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
      MESSAGE 'No data to post' TYPE 'S'.
      RETURN.
    ENDIF.

*    DELETE_MD74( ).
    CREATE_MD61( ).
    SAVE_LOG( ).
  ENDMETHOD.

  METHOD CHECK_DATA .
    DATA LV_MESS TYPE STRING.
    IF LS_DATA-THANHPHAM IS INITIAL.
      LS_DATA-STATUS = C_ICON-FAIL.
      LV_MESS = 'Mã chưa được khai báo là thành phẩm!'.
      IF LS_DATA-MESSAGE IS INITIAL.
        LS_DATA-MESSAGE = LV_MESS.
      ELSE.
        LS_DATA-MESSAGE = |{ LS_DATA-MESSAGE }, { LV_MESS }|.
      ENDIF.
    ENDIF.

    IF LS_DATA-MENGE_UP < 0.
      LS_DATA-STATUS = C_ICON-FAIL.
      LV_MESS = 'Không có số lượng!'.
      IF LS_DATA-MESSAGE IS INITIAL.
        LS_DATA-MESSAGE = LV_MESS.
      ELSE.
        LS_DATA-MESSAGE = |{ LS_DATA-MESSAGE }, { LV_MESS }|.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD DELETE_MD74.

    DATA(LV_DATEMAX) = REDUCE #( INIT DATE TYPE DATUM FOR I IN GT_DATA
                                 NEXT DATE = NMAX( VAL1 = DATE VAL2 = I-KEYDATE ) ).
    DATA LR_BERID TYPE RANGE OF BERID.
    DATA LR_PBDNR TYPE RANGE OF PBDNR.
    LR_BERID = VALUE #( SIGN = 'I' OPTION = 'EQ' ( LOW = P_BERID ) ).
    LR_PBDNR = VALUE #( SIGN = 'I' OPTION = 'EQ' ( LOW = 'LTFPSIC' ) ).
    SUBMIT RM60RR20 USING SELECTION-SCREEN 1000
       WITH PBDNR IN LR_PBDNR
       WITH BERID IN LR_BERID
       WITH DATE1 EQ LV_DATEMAX
       WITH HISTFLAG EQ ABAP_TRUE
       WITH INACFLAG EQ ABAP_FALSE
       WITH DEACFLAG EQ ABAP_FALSE
       WITH LISTFLAG EQ ABAP_FALSE
       WITH TESTFLAG EQ ABAP_FALSE AND RETURN.

  ENDMETHOD.

  METHOD CREATE_MD61.

    DATA: LS_REQ_ITEM     TYPE BAPISITEMR,
          LV_PLANT        TYPE BAPISITEMR-PLANT,
          LV_REQTYPE      TYPE BAPISITEMR-REQU_TYPE,
          LV_VERSION      TYPE BAPISITEMR-VERSION,
          LV_REQMTSPLAN   TYPE BAPISITEMR-REQ_NUMBER,
          LT_REQ_SCHEDULE TYPE STANDARD TABLE OF BAPISSHDIN,
          LT_RETURN       TYPE STANDARD TABLE OF BAPIRETURN1.

    LOOP AT GT_DATA INTO DATA(LS_DATA) WHERE STATUS = C_ICON-NONE.

      APPEND INITIAL LINE TO LT_REQ_SCHEDULE REFERENCE INTO DATA(LS_REQ_SCHEDULE).
      LS_REQ_SCHEDULE->DATE_TYPE = '3'.
      LS_REQ_SCHEDULE->REQ_DATE = LS_DATA-KEYDATE.
      LS_REQ_SCHEDULE->REQ_QTY = LS_DATA-MENGE_QD.

      AT END OF MATNR.

        LS_REQ_ITEM-PLANT = C_PLANT.
        LS_REQ_ITEM-MATERIAL = LS_DATA-MATNR.
        LS_REQ_ITEM-REQU_TYPE = C_REQTYPE.
        LS_REQ_ITEM-REQ_NUMBER = C_REQMTSPLAN.
        LS_REQ_ITEM-VERSION = C_VERSION.
        LS_REQ_ITEM-VERS_ACTIV = ABAP_TRUE.
        LS_REQ_ITEM-MRP_AREA   = P_BERID.
        IF EXISTS_REQPLAN( LS_DATA-MATNR ) <> 0.
          "create
          CALL FUNCTION 'BAPI_REQUIREMENTS_CREATE'
            EXPORTING
              REQUIREMENTS_ITEM        = LS_REQ_ITEM
            TABLES
              REQUIREMENTS_SCHEDULE_IN = LT_REQ_SCHEDULE
              RETURN                   = LT_RETURN.
        ELSE.
          "update
          CALL FUNCTION 'BAPI_REQUIREMENTS_CHANGE'
            EXPORTING
              MATERIAL         = LS_REQ_ITEM-MATERIAL
              PLANT            = LS_REQ_ITEM-PLANT
              REQUIREMENTSTYPE = LS_REQ_ITEM-REQU_TYPE
              VERSION          = LS_REQ_ITEM-VERSION
              REQMTSPLANNUMBER = LS_REQ_ITEM-REQ_NUMBER
              VERS_ACTIV       = LS_REQ_ITEM-VERS_ACTIV
              MRP_AREA         = LS_REQ_ITEM-MRP_AREA
              DELETE_OLD       = ABAP_TRUE
              DO_COMMIT        = ABAP_FALSE
            TABLES
              RETURN           = LT_RETURN.

          IF LINE_EXISTS( LT_RETURN[ TYPE = 'E' ] ) OR LINE_EXISTS( LT_RETURN[ TYPE = 'A' ] ).
            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          ELSE.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING WAIT = 'X'.
            WAIT UP TO '0.5' SECONDS.

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

        ENDIF.
        IF LINE_EXISTS( LT_RETURN[ TYPE = 'E' ] ) OR LINE_EXISTS( LT_RETURN[ TYPE = 'A' ] ).
          DATA(LV_FAIL) = ABAP_TRUE.
        ELSE.
          COMMIT WORK AND WAIT.
        ENDIF.

        LOOP AT GT_DATA REFERENCE INTO DATA(LR_DATA) WHERE MATNR = LS_DATA-MATNR AND STATUS = C_ICON-NONE.
          LR_DATA->STATUS = COND #( WHEN LV_FAIL IS NOT INITIAL THEN C_ICON-FAIL
                                                                ELSE C_ICON-SUCCESS ).
          DATA(LS_MESS) = VALUE #( LT_RETURN[ 1 ] OPTIONAL ).
          IF LS_MESS IS NOT INITIAL.
            MESSAGE ID LS_MESS-ID  TYPE LS_MESS-TYPE NUMBER LS_MESS-NUMBER
            WITH LS_MESS-MESSAGE_V1 LS_MESS-MESSAGE_V2 LS_MESS-MESSAGE_V3 LS_MESS-MESSAGE_V4 INTO LR_DATA->MESSAGE.
          ENDIF.
        ENDLOOP.

        CLEAR : LT_RETURN, LT_REQ_SCHEDULE, LS_REQ_ITEM, LV_FAIL.
      ENDAT.

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
      YMONTH    = I-MONTH
      GJAHR     = I-GJAHR
      MENGE_UP  = I-MENGE_UP
      MEINS_UP  = I-MEINS_UP
      MENGE_QD  = I-MENGE_QD
      MEINS_QD  = I-MEINS_QD
      THANHPHAM = I-THANHPHAM
      BANTPHAM  = I-BANTPHAM
      PSIC_DATA = 'X'
      UPD_PIRS  = 'X'
      TIMESTAMPL = LV_LONG_TIME_STAMP ) ).
    CHECK LT_DEMAND IS NOT INITIAL.
    INSERT YTB_MRP_DEMAND FROM TABLE LT_DEMAND.
    IF SY-SUBRC = 0.
      MESSAGE 'Save data success' TYPE 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD EXISTS_REQPLAN.

    SELECT COUNT(*)
        FROM PBID
        WHERE PBDNR = C_REQMTSPLAN
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
    CHECK GO_UPPSIC IS BOUND.
    CASE E_UCOMM.
*      WHEN C_USRCMD-SEL.
*        GO_UPPSIC->REFRESH_ALV( ).
*      WHEN C_USRCMD-UNSEL.
*        GO_UPPSIC->REFRESH_ALV( ).
      WHEN C_USRCMD-POST.
        GO_UPPSIC->POST_PIC( ).
        GO_UPPSIC->REFRESH_ALV( ).
    ENDCASE.
  ENDMETHOD.

ENDCLASS.

*
* 
