*&---------------------------------------------------------------------*
*& Include          ZPP_IN_DECLARE_PBO
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Include          ZPP_IN_DECLARE_PBO
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*       CLASS lcl_eventhandler DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS LCL_EVENTHANDLER DEFINITION.
  PUBLIC SECTION.

    CLASS-METHODS:
      HANDLE_ITEM_DOUBLE_CLICK
        FOR EVENT ITEM_DOUBLE_CLICK OF CL_GUI_ALV_TREE
        IMPORTING NODE_KEY
                  FIELDNAME.

ENDCLASS.                    "lcl_eventhandler DEFINITION
*----------------------------------------------------------------------*
*       CLASS lcl_eventhandler IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS LCL_EVENTHANDLER IMPLEMENTATION.

  METHOD HANDLE_ITEM_DOUBLE_CLICK.

    READ TABLE GT_TREE INTO DATA(LS_ITEM) INDEX NODE_KEY.
    IF SY-SUBRC = 0 AND LS_ITEM-LEVEL = 2.
      IF NOT LS_ITEM-TCODE IS INITIAL.
        TRY.
            CALL TRANSACTION LS_ITEM-TCODE WITH AUTHORITY-CHECK.
          CATCH CX_SY_AUTHORIZATION_ERROR.
            MESSAGE I853(MG) WITH LS_ITEM-TCODE.
        ENDTRY.
      ELSE.
        PERFORM CALL_MV USING LS_ITEM-VIEWNAME.
      ENDIF.
    ENDIF.
  ENDMETHOD.                    "handle_item_double_click

ENDCLASS.                    "lcl_eventhandler IMPLEMENTATION
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.
  SET PF-STATUS 'GUI'.
  SET TITLEBAR 'TITLE'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT .

  DATA: LS_VARIANT   TYPE DISVARIANT,
        LS_HIERARCHY TYPE TREEV_HHDR,
        LS_NODE_LV1  TYPE LVC_NKEY,
        LS_NODE_LV2  TYPE LVC_NKEY,
        LT_NODE_EXP  TYPE LVC_T_NKEY.


  IF GO_CONTAINER IS INITIAL.
*   Create main container
    CREATE OBJECT GO_CONTAINER
      EXPORTING
        CONTAINER_NAME              = 'CONTAINER'
      EXCEPTIONS
        CNTL_ERROR                  = 1
        CNTL_SYSTEM_ERROR           = 2
        CREATE_ERROR                = 3
        LIFETIME_ERROR              = 4
        LIFETIME_DYNPRO_DYNPRO_LINK = 5
        OTHERS                      = 6.
    IF SY-SUBRC <> 0.
      MESSAGE 'Create Container object failed'
        TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.

*   Create tree control
    CREATE OBJECT GO_TREE
      EXPORTING
        PARENT                      = GO_CONTAINER
        NODE_SELECTION_MODE         = CL_GUI_COLUMN_TREE=>NODE_SEL_MODE_SINGLE
        NO_HTML_HEADER              = 'X'
        NO_TOOLBAR                  = 'X'
      EXCEPTIONS
        CNTL_ERROR                  = 1
        CNTL_SYSTEM_ERROR           = 2
        CREATE_ERROR                = 3
        LIFETIME_ERROR              = 4
        ILLEGAL_NODE_SELECTION_MODE = 5
        FAILED                      = 6
        ILLEGAL_COLUMN_NAME         = 7
        OTHERS                      = 8.
    IF SY-SUBRC <> 0.
      MESSAGE 'Create ALV Tree object failed'
        TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    PERFORM BUILD_FLDCAT.
*   register events
    PERFORM REGISTER_EVENTS.

*   Create empty tree
    LS_VARIANT-REPORT       = SY-REPID.
    LS_HIERARCHY-HEADING    = 'Structure'.

    LS_HIERARCHY-WIDTH      = 65.
    CALL METHOD GO_TREE->SET_TABLE_FOR_FIRST_DISPLAY
      EXPORTING
        IS_HIERARCHY_HEADER = LS_HIERARCHY
        IS_VARIANT          = LS_VARIANT
        I_SAVE              = 'A'
      CHANGING
        IT_OUTTAB           = GT_TREE
        IT_FIELDCATALOG     = GT_FLDCAT.

*   Build hierarchy
    LOOP AT GT_DATA ASSIGNING FIELD-SYMBOL(<LF_DATA>).
      CASE <LF_DATA>-LEVEL.
        WHEN 1.
          PERFORM ADD_LINE_EXP USING <LF_DATA>
                                     ''
                                     LS_NODE_LV1.
          APPEND LS_NODE_LV1 TO LT_NODE_EXP.

        WHEN 2.
          PERFORM ADD_LINE USING <LF_DATA>
                                LS_NODE_LV1
                                LS_NODE_LV2.
          APPEND LS_NODE_LV2 TO LT_NODE_EXP.
      ENDCASE.
    ENDLOOP.

  ENDIF.

  CALL METHOD GO_TREE->EXPAND_NODES
    EXPORTING
      IT_NODE_KEY             = LT_NODE_EXP
    EXCEPTIONS
      FAILED                  = 1
      CNTL_SYSTEM_ERROR       = 2
      ERROR_IN_NODE_KEY_TABLE = 3
      DP_ERROR                = 4
      NODE_NOT_FOUND          = 5
      OTHERS                  = 6.
  IF SY-SUBRC <> 0.
    MESSAGE 'Execute method EXPAND_NODES failed' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  CALL METHOD GO_TREE->COLUMN_OPTIMIZE
    EXPORTING
      I_INCLUDE_HEADING      = 'X'
    EXCEPTIONS
      START_COLUMN_NOT_FOUND = 1
      END_COLUMN_NOT_FOUND   = 2
      OTHERS                 = 3.
  IF SY-SUBRC <> 0.
    MESSAGE 'Execute method COLUMN_OPTIMIZE failed' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

* Send data to frontend.
  CALL METHOD GO_TREE->FRONTEND_UPDATE.
  CALL METHOD CL_GUI_CFW=>FLUSH
    EXCEPTIONS
      CNTL_SYSTEM_ERROR = 1
      CNTL_ERROR        = 2.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  register_events
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM REGISTER_EVENTS.
* define the events which will be passed to the backend
  DATA: LT_EVENTS TYPE CNTL_SIMPLE_EVENTS,
        L_EVENT   TYPE CNTL_SIMPLE_EVENT.

* define the events which will be passed to the backend
  L_EVENT-EVENTID = CL_GUI_COLUMN_TREE=>EVENTID_EXPAND_NO_CHILDREN.
  APPEND L_EVENT TO LT_EVENTS.

  L_EVENT-EVENTID = CL_GUI_COLUMN_TREE=>EVENTID_ITEM_DOUBLE_CLICK.
  APPEND L_EVENT TO LT_EVENTS.


  CALL METHOD GO_TREE->SET_REGISTERED_EVENTS
    EXPORTING
      EVENTS                    = LT_EVENTS
    EXCEPTIONS
      CNTL_ERROR                = 1
      CNTL_SYSTEM_ERROR         = 2
      ILLEGAL_EVENT_COMBINATION = 3.
  IF SY-SUBRC <> 0.
    MESSAGE X208(00) WITH 'ERROR'.                          "#EC NOTEXT
  ENDIF.

* set Handler
  SET HANDLER:
    LCL_EVENTHANDLER=>HANDLE_ITEM_DOUBLE_CLICK FOR GO_TREE.

ENDFORM.                               " register_events

*&---------------------------------------------------------------------*
*& Form ADD_LINE
*&---------------------------------------------------------------------*
*& Add line
*&---------------------------------------------------------------------*
FORM ADD_LINE USING    LPS_DATA
                       LPW_PARENT_KEY   TYPE LVC_NKEY
              CHANGING LPW_CREATED_KEY  TYPE LVC_NKEY.

  DATA: LS_NODE_LAYOUT TYPE LVC_S_LAYN,
        LW_TEXT        TYPE LVC_VALUE.
  FIELD-SYMBOLS: <LF_FIELD1> TYPE ANY.

* Node-Layout

* Text to be displayed
  CLEAR: LW_TEXT.
  ASSIGN COMPONENT 'NAME' OF STRUCTURE LPS_DATA TO <LF_FIELD1>.
  IF <LF_FIELD1> IS ASSIGNED.
    LW_TEXT = <LF_FIELD1>.
    UNASSIGN: <LF_FIELD1>.
  ENDIF.

* Create Node
  CALL METHOD GO_TREE->ADD_NODE
    EXPORTING
      I_RELAT_NODE_KEY = LPW_PARENT_KEY
      I_RELATIONSHIP   = CL_GUI_COLUMN_TREE=>RELAT_LAST_CHILD
      I_NODE_TEXT      = LW_TEXT
      IS_OUTTAB_LINE   = LPS_DATA
      IS_NODE_LAYOUT   = LS_NODE_LAYOUT
    IMPORTING
      E_NEW_NODE_KEY   = LPW_CREATED_KEY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_LINE_EXP
*&---------------------------------------------------------------------*
*& Add Material line
*&---------------------------------------------------------------------*
FORM ADD_LINE_EXP USING    LPS_DATA
                             LPW_PARENT_KEY   TYPE LVC_NKEY
                    CHANGING LPW_CREATED_KEY  TYPE LVC_NKEY.

  DATA: LS_NODE_LAYOUT TYPE LVC_S_LAYN,
        LW_TEXT        TYPE LVC_VALUE.
  FIELD-SYMBOLS: <LF_FIELD1> TYPE ANY.

* Node-Layout
  LS_NODE_LAYOUT-N_IMAGE   = ICON_DISPLAY_TEXT.
  LS_NODE_LAYOUT-EXP_IMAGE = ICON_DISPLAY_TEXT.
  LS_NODE_LAYOUT-EXPANDER  = 'X'.

* Text to be displayed
  CLEAR: LW_TEXT.
  ASSIGN COMPONENT 'NAME' OF STRUCTURE LPS_DATA TO <LF_FIELD1>.
  IF <LF_FIELD1> IS ASSIGNED.
    LW_TEXT = <LF_FIELD1>.
    UNASSIGN: <LF_FIELD1>.
  ENDIF.

* Create Node
  CALL METHOD GO_TREE->ADD_NODE
    EXPORTING
      I_RELAT_NODE_KEY     = LPW_PARENT_KEY
      I_RELATIONSHIP       = CL_GUI_COLUMN_TREE=>RELAT_LAST_CHILD
      I_NODE_TEXT          = LW_TEXT
      IS_OUTTAB_LINE       = LPS_DATA
      IS_NODE_LAYOUT       = LS_NODE_LAYOUT
    IMPORTING
      E_NEW_NODE_KEY       = LPW_CREATED_KEY
    EXCEPTIONS
      RELAT_NODE_NOT_FOUND = 1                " Relat Node Key not Found
      NODE_NOT_FOUND       = 2                " Node not Found
      OTHERS               = 3.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
      WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.

*
* 
