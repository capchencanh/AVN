*&---------------------------------------------------------------------*
*& Include          YIN_PPIM01_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INIT .
ENDFORM.                    " INIT
*&---------------------------------------------------------------------*
*&      Form  MAIN_PROC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM MAIN_PROC  .

  GR_DAILY_CTR = NEW #( ).
  GR_DAILY_CTR->GET_DATA( ).
  GR_DAILY_CTR->PROCESS_DATA( ).
  GR_DAILY_CTR->BUILD_FCAT( ).

  CALL SCREEN 100.

ENDFORM.                    " MAIN_PROC

*&---------------------------------------------------------------------*
*&      Form  CREATE_OBJECTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CREATE_OBJECTS .

  "Custom----------------------------------------------------------
  GO_CONTAINER = NEW #( CONTAINER_NAME = 'CONTAINER' ).
  GO_GRID = NEW #( I_PARENT = GO_CONTAINER ).
*    go_split_c = new cl_gui_splitter_container(
*      parent                  = go_container
*      rows                    = 2
*      columns                 = 1
*    ).

*    go_top_container = go_split_c->get_container(
*                         row    = 1
*                         column = 1
*                       ).
*    go_bottom_container = go_split_c->get_container(
*                         row    = 2
*                         column = 1
*                       ).

*    "Docking----------------------------------------------------------
*  CREATE OBJECT GO_DOCKING
*    EXPORTING
*      RATIO = '95'.
*  IF SY-SUBRC EQ 0.
** Splitting the Docking container
*    CREATE OBJECT GO_SPLIT
*      EXPORTING
*        PARENT        = GO_DOCKING
*        SASH_POSITION = 5 "Position of Splitter Bar (in Percent)
*        WITH_BORDER   = 0. "With Border = 1 Without Border = 0
**   Placing the containers in the splitter
*    GO_TOP_CONTAINER = GO_SPLIT->TOP_LEFT_CONTAINER .
*    GO_BOTTOM_CONTAINER = GO_SPLIT->BOTTOM_RIGHT_CONTAINER .
*
**   creating grid
*    CREATE OBJECT GO_GRID
*      EXPORTING
*        I_PARENT = GO_BOTTOM_CONTAINER.
**   Creating the document
*    CREATE OBJECT GO_DOCUMENT
*      EXPORTING
*        STYLE = 'ALV_GRID'.
*  ENDIF.



ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FILL_TOP_OF_PAGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_TOP_OF_PAGE .
  CHECK GO_DOCUMENT IS BOUND.
* Calling the methods for dynamic text
  CALL METHOD GO_DOCUMENT->ADD_TEXT
    EXPORTING
      TEXT = 'ZPPIM01 Upload PIC'.
** Adding GAP
*  CALL METHOD GO_DOCUMENT->ADD_GAP
*    EXPORTING
*      WIDTH = 10.
*  CALL METHOD GO_DOCUMENT->ADD_TEXT
*    EXPORTING
*      TEXT = '100'.
** Adding Line
*  CALL METHOD GO_DOCUMENT->NEW_LINE.

* Display the data
  CALL METHOD GO_DOCUMENT->DISPLAY_DOCUMENT
    EXPORTING
      PARENT = GO_TOP_CONTAINER.
* Calling the method of ALV to process top of page
  CALL METHOD GO_GRID->LIST_PROCESSING_EVENTS
    EXPORTING
      I_EVENT_NAME = 'TOP_OF_PAGE'
      I_DYNDOC_ID  = GO_DOCUMENT.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  display_output
*&---------------------------------------------------------------------*
*       Displaying the Output
*----------------------------------------------------------------------*
FORM DISPLAY_OUTPUT .

  GS_LAYO-CWIDTH_OPT = 'X'.
  GS_LAYO-ZEBRA = 'X'.

  GS_VARIANT-REPORT = SY-REPID.
  GS_VARIANT-USERNAME = SY-UNAME.

  "event
  DATA(LO_HANDLE) = NEW LCL_HANDLE( ).
  SET HANDLER: LO_HANDLE->TOOLBAR FOR GO_GRID,
  LO_HANDLE->USER_COMMAND FOR GO_GRID.

  YCL_BASE_ABAP=>GET_EX_TOOLBAR( IMPORTING T_EX_TOOLBAR = DATA(LT_EX_TOOLBAR) ).

  FIELD-SYMBOLS <LFT_DATA> TYPE STANDARD TABLE.
  ASSIGN GR_DAILY_CTR->GT_DATA TO <LFT_DATA>.
  IF  <LFT_DATA> IS ASSIGNED.

    GO_GRID->SET_TABLE_FOR_FIRST_DISPLAY( EXPORTING  IS_VARIANT                    = GS_VARIANT                 " Layout
                                                     I_SAVE                        = 'A'                 " Save Layout
                                                     I_DEFAULT                     = 'X'              " Default Display Variant
                                                     IS_LAYOUT                     = GS_LAYO                 " Layout
*                                                    is_print                      = " Print Control
*                                                    it_special_groups             = " Field Groups
                                                     IT_TOOLBAR_EXCLUDING          = LT_EX_TOOLBAR                  " Excluded Toolbar Standard Functions
*                                                    it_hyperlink                  = " Hyperlinks
*                                                    it_alv_graphics               = " Table of Structure DTC_S_TC
*                                                    it_except_qinfo               = " Table for Exception Quickinfo
*                                                    ir_salv_adapter               = " Interface ALV Adapter
                                          CHANGING   IT_OUTTAB                     = <LFT_DATA>                 " Output Table
                                                     IT_FIELDCATALOG               = GR_DAILY_CTR->GT_FIELDCAT                 " Field Catalog
*                                                    it_sort                       = gt_sort
*                                                    it_filter                     = " Filter Criteria
                                          EXCEPTIONS INVALID_PARAMETER_COMBINATION = 1                " Wrong Parameter
                                                     PROGRAM_ERROR                 = 2                " Program Errors
                                                     TOO_MANY_LINES                = 3                " Too many Rows in Ready for Input Grid
                                                     OTHERS                        = 4 ).
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
                  WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.
ENDFORM.                    " display_output

*
* 
