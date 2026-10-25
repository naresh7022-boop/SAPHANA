*&---------------------------------------------------------------------*
*& Report ZCREATE_TCODE_ME49N
*& Purpose: Create and configure transaction codes ZPQC_NEW and ZPQC
*&          for ZMM_R_ME49N with full SAP GUI for HTML (WebGUI) support
*& Author:  NARESH
*& Date:    12.10.2026 (Updated: 24.10.2026)
*& Package: $TMP
*&---------------------------------------------------------------------*
REPORT zcreate_tcode_me49n.

DATA: lv_prog  TYPE trdir-name VALUE 'ZMM_R_ME49N',
      ls_tstc  TYPE tstc,
      ls_tstct TYPE tstct,
      ls_tstcc TYPE tstcc,
      ls_tadir TYPE tadir.

START-OF-SELECTION.

  " 1. Configure ZPQC_NEW in TSTC / TSTCT / TSTCC / TADIR
  CLEAR ls_tstc.
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZPQC_NEW'.
  ls_tstc-tcode = 'ZPQC_NEW'.
  ls_tstc-pgmna = lv_prog.
  ls_tstc-dypno = '1000'.
  ls_tstc-cinfo = '80'. " hex_rep: Standard Report Transaction (NO TSTCA auth object check)
  CLEAR ls_tstc-arbgb.
  CLEAR ls_tstc-menue.
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = 'E'.
  ls_tstct-tcode = 'ZPQC_NEW'.
  ls_tstct-ttext = 'Quotation Price Comparison & PO Creation'.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = sy-langu.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  CLEAR ls_tstcc.
  ls_tstcc-tcode    = 'ZPQC_NEW'.
  ls_tstcc-s_webgui = '1'. " Active for SAP GUI for HTML (WebGUI)
  ls_tstcc-s_win32  = 'X'. " Active for SAP GUI for Windows
  ls_tstcc-s_platin = 'X'. " Active for SAP GUI for Java
  CLEAR: ls_tstcc-s_dummy, ls_tstcc-s_dummy1, ls_tstcc-s_dummy2, ls_tstcc-s_service, ls_tstcc-s_pervas.
  MODIFY tstcc FROM ls_tstcc.

  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'TRAN' AND obj_name = 'ZPQC_NEW'.
  IF sy-subrc <> 0.
    CLEAR ls_tadir.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'TRAN'.
    ls_tadir-obj_name   = 'ZPQC_NEW'.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = 'E'.
    INSERT tadir FROM ls_tadir.
  ELSE.
    ls_tadir-devclass   = '$TMP'.
    MODIFY tadir FROM ls_tadir.
  ENDIF.

  DELETE FROM tstca WHERE tcode = 'ZPQC_NEW'.
  DELETE FROM tstcp WHERE tcode = 'ZPQC_NEW'.

  " 2. Also configure ZPQC short code
  CLEAR ls_tstc.
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZPQC'.
  ls_tstc-tcode = 'ZPQC'.
  ls_tstc-pgmna = lv_prog.
  ls_tstc-dypno = '1000'.
  ls_tstc-cinfo = '80'. " hex_rep: Standard Report Transaction
  CLEAR ls_tstc-arbgb.
  CLEAR ls_tstc-menue.
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = 'E'.
  ls_tstct-tcode = 'ZPQC'.
  ls_tstct-ttext = 'Quotation Price Comparison Cockpit'.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = sy-langu.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  CLEAR ls_tstcc.
  ls_tstcc-tcode    = 'ZPQC'.
  ls_tstcc-s_webgui = '1'.
  ls_tstcc-s_win32  = 'X'.
  ls_tstcc-s_platin = 'X'.
  CLEAR: ls_tstcc-s_dummy, ls_tstcc-s_dummy1, ls_tstcc-s_dummy2, ls_tstcc-s_service, ls_tstcc-s_pervas.
  MODIFY tstcc FROM ls_tstcc.

  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'TRAN' AND obj_name = 'ZPQC'.
  IF sy-subrc <> 0.
    CLEAR ls_tadir.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'TRAN'.
    ls_tadir-obj_name   = 'ZPQC'.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = 'E'.
    INSERT tadir FROM ls_tadir.
  ELSE.
    ls_tadir-devclass   = '$TMP'.
    MODIFY tadir FROM ls_tadir.
  ENDIF.

  DELETE FROM tstca WHERE tcode = 'ZPQC'.
  DELETE FROM tstcp WHERE tcode = 'ZPQC'.

  " 3. Reset shared memory table buffer for TSTC, TSTCC & TADIR
  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING
      tabname = 'TSTC'.

  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING
      tabname = 'TSTCC'.

  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING
      tabname = 'TADIR'.

  COMMIT WORK AND WAIT.

  DATA: lt_errors TYPE STANDARD TABLE OF rsmp_check,
        lv_cnt    TYPE i.

  CALL FUNCTION 'RS_TRANSACTION_INCONSISTENCIES'
    EXPORTING
      transaction_code = 'ZPQC_NEW'
      tadir_check      = 'X'
    TABLES
      error_list       = lt_errors
    EXCEPTIONS
      object_not_found = 1
      OTHERS           = 2.

  DESCRIBE TABLE lt_errors LINES lv_cnt.
  DATA: lv_ds_bnd TYPE abap_bool,
        lv_s0_bnd TYPE abap_bool.
  lv_ds_bnd = boolc( cl_gui_container=>default_screen IS BOUND ).
  lv_s0_bnd = boolc( cl_gui_container=>screen0 IS BOUND ).
  WRITE: / 'default_screen bound:', lv_ds_bnd.
  WRITE: / 'screen0 bound:', lv_s0_bnd.

  WRITE: / 'SUCCESS: ZPQC_NEW and ZPQC registered with WebGUI enabled (CINFO = 80, TADIR created, buffers reset).'.
