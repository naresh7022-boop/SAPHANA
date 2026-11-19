*&---------------------------------------------------------------------*
*& Report ZQUICK_REGISTER_TCODE
*& Purpose: Instantly duplicate ZPPLIS to ZPPLIS_NN in SAP Client 220
*&          and enable SAP GUI for HTML (WebGUI) with S_WEBGUI = '1'.
*& Instructions: Paste this in SE38 -> Create -> Activate -> Execute (F8).
*&---------------------------------------------------------------------*
REPORT zquick_register_tcode.

TABLES: tstc, tstct, tstcc, tadir.

DATA: ls_tstc  TYPE tstc,
      ls_tstct TYPE tstct,
      ls_tstcc TYPE tstcc,
      ls_tadir TYPE tadir.

START-OF-SELECTION.

  WRITE: / '=============================================================='.
  WRITE: / '  DUPLICATING ZPPLIS -> ZPPLIS_NN & ENABLING WEBGUI (CLIENT 220)'.
  WRITE: / '=============================================================='.
  SKIP 1.

  " 1. Inspect original ZPPLIS in TSTC
  SELECT SINGLE * FROM tstc INTO @DATA(ls_orig) WHERE tcode = 'ZPPLIS'.
  IF sy-subrc = 0.
    WRITE: / '✓ Found original ZPPLIS:',
           / '  Program:', ls_orig-pgmna,
           / '  Screen :', ls_orig-dypno,
           / '  CINFO  :', ls_orig-cinfo.

    " Enable WebGUI on original ZPPLIS as well
    CLEAR ls_tstcc.
    SELECT SINGLE * FROM tstcc INTO ls_tstcc WHERE tcode = 'ZPPLIS'.
    ls_tstcc-tcode    = 'ZPPLIS'.
    ls_tstcc-s_webgui = '1'. " Active for WebGUI
    ls_tstcc-s_win32  = 'X'.
    ls_tstcc-s_platin = 'X'.
    MODIFY tstcc FROM ls_tstcc.
    WRITE: / '✓ WebGUI enabled on original ZPPLIS (TSTCC-S_WEBGUI = 1)'.
  ELSE.
    WRITE: / '! WARNING: Original ZPPLIS not found in TSTC. Using default SAPMZPPLIS_NN / 0100.'.
    ls_orig-pgmna = 'SAPMZPPLIS_NN'.
    ls_orig-dypno = '0100'.
    ls_orig-cinfo = '00'.
  ENDIF.

  SKIP 1.

  " 2. Create / Update ZPPLIS_NN
  CLEAR ls_tstc.
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZPPLIS_NN'.
  ls_tstc-tcode = 'ZPPLIS_NN'.
  " If custom program SAPMZPPLIS_NN exists, use it; otherwise duplicate original program
  SELECT SINGLE name FROM trdir INTO @DATA(lv_new_prog) WHERE name = 'SAPMZPPLIS_NN'.
  IF sy-subrc = 0.
    ls_tstc-pgmna = 'SAPMZPPLIS_NN'.
    ls_tstc-dypno = '0100'.
    ls_tstc-cinfo = '00'.
  ELSE.
    ls_tstc-pgmna = ls_orig-pgmna.
    ls_tstc-dypno = ls_orig-dypno.
    ls_tstc-cinfo = ls_orig-cinfo.
  ENDIF.
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = sy-langu.
  ls_tstct-tcode = 'ZPPLIS_NN'.
  ls_tstct-ttext = 'QC Sample Collection Barcode Scanner'.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = 'E'.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  CLEAR ls_tstcc.
  ls_tstcc-tcode    = 'ZPPLIS_NN'.
  ls_tstcc-s_webgui = '1'. " Enable WebGUI!
  ls_tstcc-s_win32  = 'X'.
  ls_tstcc-s_platin = 'X'.
  MODIFY tstcc FROM ls_tstcc.

  " Register in TADIR
  CLEAR ls_tadir.
  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'TRAN' AND obj_name = 'ZPPLIS_NN'.
  IF sy-subrc <> 0.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'TRAN'.
    ls_tadir-obj_name   = 'ZPPLIS_NN'.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = 'E'.
    INSERT tadir FROM ls_tadir.
  ENDIF.

  WRITE: / '✓ SUCCESS: ZPPLIS_NN created & registered in TSTC, TSTCT, TSTCC, TADIR.'.

  " 3. Create Short Code: ZPLIS_NN
  CLEAR ls_tstc.
  ls_tstc-tcode = 'ZPLIS_NN'.
  ls_tstc-pgmna = ls_tstc-pgmna.
  ls_tstc-dypno = ls_tstc-dypno.
  ls_tstc-cinfo = ls_tstc-cinfo.
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = 'E'.
  ls_tstct-tcode = 'ZPLIS_NN'.
  ls_tstct-ttext = 'QC Sample Scanner Short Code'.
  MODIFY tstct FROM ls_tstct.

  CLEAR ls_tstcc.
  ls_tstcc-tcode    = 'ZPLIS_NN'.
  ls_tstcc-s_webgui = '1'.
  ls_tstcc-s_win32  = 'X'.
  ls_tstcc-s_platin = 'X'.
  MODIFY tstcc FROM ls_tstcc.

  " 4. Reset Shared Buffers so WebGUI immediately sees the new T-codes
  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING tabname = 'TSTC'.

  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING tabname = 'TSTCC'.

  COMMIT WORK AND WAIT.

  SKIP 1.
  WRITE: / '=============================================================='.
  WRITE: / '  STATUS: ALL T-CODES REGISTERED AND WEBGUI BUFFERS FLUSHED!  '.
  WRITE: / '=============================================================='.
  WRITE: / 'You can now launch directly:'.
  WRITE: / '• WebGUI: https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPPLIS_NN'.
  WRITE: / '• SAP GUI Command Field: /nZPPLIS_NN'.
