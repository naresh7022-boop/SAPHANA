*&---------------------------------------------------------------------*
*& Report ZCREATE_TCODE_ZGATEENTRY
*& Purpose: Create and configure transaction codes ZGATEENTRY and ZGE01
*&          for program ZGATEENTRY with SAP GUI for HTML (WebGUI) support
*& Author:  NARESH
*& Date:    26.10.2026
*& Package: $TMP
*& System:  SAP S/4HANA DS4/220
*&---------------------------------------------------------------------*
REPORT zcreate_tcode_zgateentry.

DATA: lv_prog  TYPE trdir-name VALUE 'ZGATEENTRY',
      ls_tstc  TYPE tstc,
      ls_tstct TYPE tstct,
      ls_tstcc TYPE tstcc,
      ls_tadir TYPE tadir.

START-OF-SELECTION.

  WRITE: / '=============================================================='.
  WRITE: / '  REGISTERING TRANSACTION CODES WITH FULL SAP WEBGUI SUPPORT   '.
  WRITE: / '=============================================================='.
  SKIP 1.

  " ------------------------------------------------------------------
  " 1. Configure Primary Transaction: ZGATEENTRY
  " ------------------------------------------------------------------
  CLEAR ls_tstc.
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZGATEENTRY'.
  ls_tstc-tcode = 'ZGATEENTRY'.
  ls_tstc-pgmna = lv_prog.
  ls_tstc-dypno = '1000'.
  ls_tstc-cinfo = '80'. " Standard Report Transaction
  CLEAR ls_tstc-arbgb.
  CLEAR ls_tstc-menue.
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = 'E'.
  ls_tstct-tcode = 'ZGATEENTRY'.
  ls_tstct-ttext = 'Gate Entry & Vehicle Inward Cockpit'.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = sy-langu.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  CLEAR ls_tstcc.
  ls_tstcc-tcode    = 'ZGATEENTRY'.
  ls_tstcc-s_webgui = '1'. " Active for SAP GUI for HTML (WebGUI)
  ls_tstcc-s_win32  = 'X'. " Active for SAP GUI for Windows
  ls_tstcc-s_platin = 'X'. " Active for SAP GUI for Java
  CLEAR: ls_tstcc-s_dummy, ls_tstcc-s_dummy1, ls_tstcc-s_dummy2, ls_tstcc-s_service, ls_tstcc-s_pervas.
  MODIFY tstcc FROM ls_tstcc.

  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'TRAN' AND obj_name = 'ZGATEENTRY'.
  IF sy-subrc <> 0.
    CLEAR ls_tadir.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'TRAN'.
    ls_tadir-obj_name   = 'ZGATEENTRY'.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = 'E'.
    INSERT tadir FROM ls_tadir.
  ELSE.
    ls_tadir-devclass   = '$TMP'.
    MODIFY tadir FROM ls_tadir.
  ENDIF.

  DELETE FROM tstca WHERE tcode = 'ZGATEENTRY'.
  DELETE FROM tstcp WHERE tcode = 'ZGATEENTRY'.

  WRITE: / '✓ SUCCESS: Primary TCODE ZGATEENTRY configured (WebGUI Enabled: S_WEBGUI = 1)'.

  " ------------------------------------------------------------------
  " 2. Configure Short Quick Code: ZGE01 (For mobile & handheld scans)
  " ------------------------------------------------------------------
  CLEAR ls_tstc.
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZGE01'.
  ls_tstc-tcode = 'ZGE01'.
  ls_tstc-pgmna = lv_prog.
  ls_tstc-dypno = '1000'.
  ls_tstc-cinfo = '80'.
  CLEAR ls_tstc-arbgb.
  CLEAR ls_tstc-menue.
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = 'E'.
  ls_tstct-tcode = 'ZGE01'.
  ls_tstct-ttext = 'Gate Entry Quick Access'.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = sy-langu.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  CLEAR ls_tstcc.
  ls_tstcc-tcode    = 'ZGE01'.
  ls_tstcc-s_webgui = '1'.
  ls_tstcc-s_win32  = 'X'.
  ls_tstcc-s_platin = 'X'.
  CLEAR: ls_tstcc-s_dummy, ls_tstcc-s_dummy1, ls_tstcc-s_dummy2, ls_tstcc-s_service, ls_tstcc-s_pervas.
  MODIFY tstcc FROM ls_tstcc.

  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'TRAN' AND obj_name = 'ZGE01'.
  IF sy-subrc <> 0.
    CLEAR ls_tadir.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'TRAN'.
    ls_tadir-obj_name   = 'ZGE01'.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = 'E'.
    INSERT tadir FROM ls_tadir.
  ELSE.
    ls_tadir-devclass   = '$TMP'.
    MODIFY tadir FROM ls_tadir.
  ENDIF.

  DELETE FROM tstca WHERE tcode = 'ZGE01'.
  DELETE FROM tstcp WHERE tcode = 'ZGE01'.

  WRITE: / '✓ SUCCESS: Short TCODE ZGE01 configured (WebGUI Enabled: S_WEBGUI = 1)'.

  " ------------------------------------------------------------------
  " 3. Flush SAP Buffers
  " ------------------------------------------------------------------
  CALL FUNCTION 'RESET_TRANSACTION_BUFFER'
    EXPORTING
      tcode = 'ZGATEENTRY'
    EXCEPTIONS
      OTHERS = 0.

  CALL FUNCTION 'RESET_TRANSACTION_BUFFER'
    EXPORTING
      tcode = 'ZGE01'
    EXCEPTIONS
      OTHERS = 0.

  COMMIT WORK AND WAIT.

  SKIP 1.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / 'WEBGUI DIRECT ACCESS URLS:'.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / '• Primary WebGUI URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZGATEENTRY'.
  WRITE: / '• Direct with User NARESH:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZGATEENTRY'.
  WRITE: / '--------------------------------------------------------------'.
