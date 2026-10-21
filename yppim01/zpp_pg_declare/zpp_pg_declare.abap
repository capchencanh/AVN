*&---------------------------------------------------------------------*
*& Report ZPP_PG_DECLARE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZPP_PG_DECLARE.

INCLUDE ZPP_IN_DECLARE_TOP.
INCLUDE ZPP_IN_DECLARE_F01.
INCLUDE ZPP_IN_DECLARE_PBO.
INCLUDE ZPP_IN_DECLARE_PAI.
************************************************************************
INITIALIZATION.
************************************************************************
  PERFORM INIT_PROC.
************************************************************************
START-OF-SELECTION.
************************************************************************
  PERFORM MAIN_PROC.

*GUI Texts
*----------------------------------------------------------
* TITLE --> Khai báo các giá trị cho sản xuất


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*
* Message class: Hard coded
*   Create Container object failed
*
* Message class: MG
*853   You are not authorized to use transaction &

*
* 
