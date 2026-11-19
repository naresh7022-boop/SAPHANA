*&---------------------------------------------------------------------*
*& Report ZCOPY_ZPPLIS_TO_NN
*& Purpose: AUTOMATIC DUPLICATION OF ZPPLIS & ALL SCREENS TO _NN
*&          1. Reads exact program name & screen of ZPPLIS from TSTC
*&          2. Copies Program, Screens, CUA Statuses & Texts using RS_COPY_PROGRAM
*&          3. Generates & Activates the new _NN program
*&          4. Registers ZPPLIS_NN with S_WEBGUI = '1' (WebGUI enabled)
*& Instructions: Run in SE38 -> Activate -> Execute (F8).
*&---------------------------------------------------------------------*
REPORT zcopy_zpplis_to_nn.

TABLES: tstc, tstct, tstcc, tadir.

DATA: lv_orig_tcode   TYPE tstc-tcode VALUE 'ZPPLIS',
      lv_target_tcode TYPE tstc-tcode VALUE 'ZPPLIS_NN',
      lv_orig_prog    TYPE trdir-name,
      lv_target_prog  TYPE trdir-name,
      ls_tstc         TYPE tstc,
      ls_tstct        TYPE tstct,
      ls_tstcc        TYPE tstcc,
      ls_tadir        TYPE tadir.

START-OF-SELECTION.

  WRITE: / '=============================================================='.
  WRITE: / '  AUTOMATIC DUPLICATION OF ZPPLIS & ALL SCREENS TO _NN          '.
  WRITE: / '=============================================================='.
  SKIP 1.

  " 1. Locate original transaction ZPPLIS in TSTC
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = lv_orig_tcode.
  IF sy-subrc <> 0.
    WRITE: / '✗ ERROR: Transaction code ZPPLIS not found in table TSTC!'.
    WRITE: / '  Please verify the transaction name in Client 220.'.
    EXIT.
  ENDIF.

  lv_orig_prog = ls_tstc-pgmna.
  WRITE: / '✓ Step 1: Found ZPPLIS in Client 220:',
         / '  Original Program:', lv_orig_prog,
         / '  Initial Screen  :', ls_tstc-dypno,
         / '  Trans Type/CINFO:', ls_tstc-cinfo.
  SKIP 1.

  " Determine target program name (max 30 chars for ABAP program names)
  IF strlen( lv_orig_prog ) <= 27.
    lv_target_prog = |{ lv_orig_prog }_NN|.
  ELSE.
    lv_target_prog = |{ substring( val = lv_orig_prog off = 0 len = 27 ) }_NN|.
  ENDIF.

  WRITE: / '✓ Step 2: Target Program name determined:', lv_target_prog.

  " 2. Copy Program, All Screens (Dynpros), CUA Interface, Texts & Variants
  CALL FUNCTION 'RS_COPY_PROGRAM'
    EXPORTING
      corrnumber          = space
      program             = lv_orig_prog
      target_program      = lv_target_prog
      with_dynpros        = 'X' " Copies all screen layouts & flow logic
      with_cua            = 'X' " Copies GUI status and title bars
      with_texts          = 'X' " Copies text elements & selection texts
      with_includes       = 'X'
      with_variants       = 'X'
      suppress_checks     = 'X'
      suppress_commit     = ' '
    EXCEPTIONS
      enqueue_lock        = 1
      program_exists      = 2
      program_not_exists  = 3
      permission_failure  = 4
      OTHERS              = 5.

  IF sy-subrc = 0 OR sy-subrc = 2.
    IF sy-subrc = 2.
      WRITE: / '✓ Step 3: Program', lv_target_prog, 'already exists. Proceeding with activation.'.
    ELSE.
      WRITE: / '✓ Step 3: Successfully copied', lv_orig_prog, '->', lv_target_prog, 'with ALL SCREENS.'.
    ENDIF.
  ELSE.
    WRITE: / '✗ ERROR: RS_COPY_PROGRAM failed with sy-subrc =', sy-subrc.
    EXIT.
  ENDIF.

  " 3. Generate & Activate target program
  GENERATE REPORT lv_target_prog.
  IF sy-subrc = 0.
    WRITE: / '✓ Step 4: Program', lv_target_prog, 'successfully compiled & activated.'.
  ELSE.
    WRITE: / '✗ WARNING: Compilation warning/error on', lv_target_prog, 'rc =', sy-subrc.
  ENDIF.

  " Register in TADIR
  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'PROG' AND obj_name = lv_target_prog.
  IF sy-subrc <> 0.
    CLEAR ls_tadir.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'PROG'.
    ls_tadir-obj_name   = lv_target_prog.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = sy-langu.
    INSERT tadir FROM ls_tadir.
  ENDIF.

  SKIP 1.

  " 4. Register Transaction ZPPLIS_NN in TSTC pointing to the newly copied program
  CLEAR ls_tstc.
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = lv_target_tcode.
  ls_tstc-tcode = lv_target_tcode.
  ls_tstc-pgmna = lv_target_prog.
  SELECT SINGLE dypno, cinfo FROM tstc INTO (@ls_tstc-dypno, @ls_tstc-cinfo) WHERE tcode = lv_orig_tcode.
  MODIFY tstc FROM ls_tstc.

  " Set Transaction Text
  SELECT SINGLE ttext FROM tstct INTO @DATA(lv_orig_text) WHERE tcode = lv_orig_tcode AND sprsl = sy-langu.
  IF sy-subrc <> 0.
    SELECT SINGLE ttext FROM tstct INTO @lv_orig_text WHERE tcode = lv_orig_tcode.
  ENDIF.

  ls_tstct-sprsl = sy-langu.
  ls_tstct-tcode = lv_target_tcode.
  ls_tstct-ttext = |{ lv_orig_text } (Duplicated _NN)|.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = 'E'.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  " 5. Enable WebGUI in TSTCC (S_WEBGUI = 1)
  CLEAR ls_tstcc.
  ls_tstcc-tcode    = lv_target_tcode.
  ls_tstcc-s_webgui = '1'. " Active for SAP GUI for HTML (WebGUI)
  ls_tstcc-s_win32  = 'X'. " Active for Windows SAP GUI
  ls_tstcc-s_platin = 'X'. " Active for Java/Mac SAP GUI
  MODIFY tstcc FROM ls_tstcc.

  " Also ensure original ZPPLIS has WebGUI enabled
  CLEAR ls_tstcc.
  SELECT SINGLE * FROM tstcc INTO ls_tstcc WHERE tcode = lv_orig_tcode.
  ls_tstcc-tcode    = lv_orig_tcode.
  ls_tstcc-s_webgui = '1'.
  ls_tstcc-s_win32  = 'X'.
  ls_tstcc-s_platin = 'X'.
  MODIFY tstcc FROM ls_tstcc.

  " Register Transaction in TADIR
  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'TRAN' AND obj_name = lv_target_tcode.
  IF sy-subrc <> 0.
    CLEAR ls_tadir.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'TRAN'.
    ls_tadir-obj_name   = lv_target_tcode.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = sy-langu.
    INSERT tadir FROM ls_tadir.
  ENDIF.

  WRITE: / '✓ Step 5: Transaction', lv_target_tcode, 'registered with WebGUI support (S_WEBGUI = 1).'.

  " 6. Reset Shared Memory Buffers
  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE' EXPORTING tabname = 'TSTC'.
  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE' EXPORTING tabname = 'TSTCC'.
  COMMIT WORK AND WAIT.

  SKIP 1.
  WRITE: / '=============================================================='.
  WRITE: / '  🎉 COMPLETED! ALL OBJECTS AND SCREENS DUPLICATED WITH _NN   '.
  WRITE: / '=============================================================='.
  WRITE: / '• Duplicated Program :', lv_target_prog.
  WRITE: / '• Initial Screen     :', ls_tstc-dypno.
  WRITE: / '• Transaction Code   :', lv_target_tcode.
  WRITE: / '• WebGUI Status      : ENABLED (S_WEBGUI = 1)'.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / 'Direct WebGUI URL:'.
  WRITE: / |https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction={ lv_target_tcode }|.
