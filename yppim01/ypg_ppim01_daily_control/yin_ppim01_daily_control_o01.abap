*&---------------------------------------------------------------------*
*& Include          YIN_PPIM01_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module status_0100 output.
  set pf-status 'GUI_0100'.
  set titlebar 'TITLE_0100'.

  if go_grid is not bound.
* Creating Objects
    perform create_objects.
* Filling top of page
    perform fill_top_of_page.
* Displaying the output
    perform display_output.
  else.
    go_grid->refresh_table_display(
      exporting
        is_stable      = conv #( 'XX' )      " With Stable Rows/Columns
*      i_soft_refresh = i_soft_refresh " Without Sort, Filter, etc.
      exceptions
        finished       = 1              " Display was Ended (by Export)
    ).
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
        with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
  endif.

endmodule.                 " STATUS_0100  OUTPUT

*
* 
