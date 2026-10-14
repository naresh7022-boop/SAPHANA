*&---------------------------------------------------------------------*
*& Report ZCREATE_TCODE_ME49N
*& Purpose: Create and configure transaction codes ZPQC_NEW and ZPQC
*&          for ZMM_R_ME49N with full SAP GUI for HTML (WebGUI) support
*& Author:  NARESH
*& Date:    12.10.2026 (Updated: 14.10.2026)
*& Package: $TMP
*&---------------------------------------------------------------------*
REPORT zcreate_tcode_me49n.

DATA: lv_tcode TYPE tstc-tcode VALUE 'ZPQC_NEW',
      lv_prog  TYPE trdir-name VALUE 'ZMM_R_ME49N',
      lv_text  TYPE tstct-ttext VALUE 'Quotation Price Comparison & PO Creation',
      lv_devcl TYPE rglif-devclass VALUE '$TMP',
      ls_tstc  TYPE tstc,
      ls_tstct TYPE tstct,
      ls_tstcc TYPE tstcc.

START-OF-SELECTION.

  " 1. Create or ensure ZPQC_NEW in TSTC / TSTCT / TSTCC
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZPQC_NEW'.
  IF sy-subrc <> 0.
    ls_tstc-tcode = 'ZPQC_NEW'.
    ls_tstc-pgmna = lv_prog.
    ls_tstc-dypno = '1000'.
  ENDIF.
  ls_tstc-cinfo = '84'. " GUI for Windows + GUI for HTML (WebGUI)
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = sy-langu.
  ls_tstct-tcode = 'ZPQC_NEW'.
  ls_tstct-ttext = lv_text.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = 'E'.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  SELECT SINGLE * FROM tstcc INTO ls_tstcc WHERE tcode = 'ZPQC_NEW'.
  IF sy-subrc <> 0.
    ls_tstcc-tcode = 'ZPQC_NEW'.
  ENDIF.
  ls_tstcc-s_webgui = '1'.
  ls_tstcc-s_win32  = 'X'.
  ls_tstcc-s_platin = 'X'.
  ls_tstcc-s_dummy  = 'X'.
  ls_tstcc-s_dummy1 = 'X'.
  MODIFY tstcc FROM ls_tstcc.

  " 2. Also create ZPQC short code
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZPQC'.
  IF sy-subrc <> 0.
    ls_tstc-tcode = 'ZPQC'.
    ls_tstc-pgmna = lv_prog.
    ls_tstc-dypno = '1000'.
  ENDIF.
  ls_tstc-cinfo = '84'.
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = 'E'.
  ls_tstct-tcode = 'ZPQC'.
  ls_tstct-ttext = 'Quotation Price Comparison Cockpit'.
  MODIFY tstct FROM ls_tstct.

  SELECT SINGLE * FROM tstcc INTO ls_tstcc WHERE tcode = 'ZPQC'.
  IF sy-subrc <> 0.
    ls_tstcc-tcode = 'ZPQC'.
  ENDIF.
  ls_tstcc-s_webgui = '1'.
  ls_tstcc-s_win32  = 'X'.
  ls_tstcc-s_platin = 'X'.
  ls_tstcc-s_dummy  = 'X'.
  ls_tstcc-s_dummy1 = 'X'.
  MODIFY tstcc FROM ls_tstcc.

  " 3. Reset shared memory table buffer for TSTC & TSTCC
  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING
      tabname = 'TSTC'.

  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING
      tabname = 'TSTCC'.

  COMMIT WORK AND WAIT.

  WRITE: / 'SUCCESS: ZPQC_NEW and ZPQC registered with WebGUI enabled (CINFO = 84).'.
