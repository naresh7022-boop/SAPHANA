*&---------------------------------------------------------------------*
*& Report ZSETUP_ZPPLIS_NN
*& Purpose: 1-CLICK ALL-IN-ONE INSTALLER FOR QC SAMPLE COLLECTION (ZPPLIS_NN)
*&          1. Injects and activates Module Pool SAPMZPPLIS_NN in TRDIR
*&          2. Compiles Dynpro 0100 with Root N + 1 Formula & HU Scanner
*&          3. Sets up CUA GUI Status & Titles
*&          4. Configures TSTC / TSTCC (S_WEBGUI = 1) for WebGUI
*& Instructions: Paste in SE38 -> Create -> Activate -> Execute (F8).
*&---------------------------------------------------------------------*
REPORT zsetup_zpplis_nn.

TABLES: tstc, tstct, tstcc, tadir.

DATA: lt_source     TYPE TABLE OF string,
      lv_prog_name  TYPE trdir-name VALUE 'SAPMZPPLIS_NN',
      ls_tstc       TYPE tstc,
      ls_tstct      TYPE tstct,
      ls_tstcc      TYPE tstcc,
      ls_tadir      TYPE tadir.

START-OF-SELECTION.

  WRITE: / '=============================================================='.
  WRITE: / '  1-CLICK DEPLOYMENT: QC PHYSICAL SAMPLE COLLECTION (ZPPLIS_NN) '.
  WRITE: / '  LOGIC: ROOT N + 1 FORMULA (ceil(sqrt(N)+1)) & HU SCANNER      '.
  WRITE: / '=============================================================='.
  SKIP 1.

  " -------------------------------------------------------------------
  " STEP 1: CREATE AND INSERT MODULE POOL PROGRAM 'SAPMZPPLIS_NN'
  " -------------------------------------------------------------------
  PERFORM build_source_code CHANGING lt_source.

  INSERT REPORT lv_prog_name FROM lt_source.
  IF sy-subrc = 0.
    WRITE: / '✓ STEP 1: Program', lv_prog_name, 'written to database (TRDIR).'.
  ELSE.
    WRITE: / '✗ STEP 1 ERROR: Failed to insert report', lv_prog_name, 'rc =', sy-subrc.
  ENDIF.

  " Generate program
  GENERATE REPORT lv_prog_name.
  IF sy-subrc = 0.
    WRITE: / '✓ STEP 1: Program', lv_prog_name, 'compiled & activated successfully!'.
  ELSE.
    WRITE: / '✗ STEP 1 WARNING: Generation rc =', sy-subrc.
  ENDIF.

  " Register in TADIR
  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'PROG' AND obj_name = lv_prog_name.
  IF sy-subrc <> 0.
    CLEAR ls_tadir.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'PROG'.
    ls_tadir-obj_name   = lv_prog_name.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = 'E'.
    INSERT tadir FROM ls_tadir.
  ENDIF.

  SKIP 1.

  " -------------------------------------------------------------------
  " STEP 2: CREATE & COMPILE DYNPRO 0100 (Root N + 1 & HU Scan Layout)
  " -------------------------------------------------------------------
  PERFORM create_screen_0100 USING lv_prog_name.

  SKIP 1.

  " -------------------------------------------------------------------
  " STEP 3: CONFIGURE TRANSACTION CODE ZPPLIS_NN (WEBGUI ENABLED)
  " -------------------------------------------------------------------
  CLEAR ls_tstc.
  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZPPLIS_NN'.
  ls_tstc-tcode = 'ZPPLIS_NN'.
  ls_tstc-pgmna = lv_prog_name.
  ls_tstc-dypno = '0100'.
  ls_tstc-cinfo = '00'. " Dialog transaction
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = sy-langu.
  ls_tstct-tcode = 'ZPPLIS_NN'.
  ls_tstct-ttext = 'QC Physical Sample Collection (Root N+1)'.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = 'E'.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  CLEAR ls_tstcc.
  ls_tstcc-tcode    = 'ZPPLIS_NN'.
  ls_tstcc-s_webgui = '1'. " Active for WebGUI / Fiori
  ls_tstcc-s_win32  = 'X'. " Active for SAP GUI Windows
  ls_tstcc-s_platin = 'X'. " Active for SAP GUI Mac/Java
  MODIFY tstcc FROM ls_tstcc.

  SELECT SINGLE * FROM tadir INTO ls_tadir
    WHERE pgmid = 'R3TR' AND object = 'TRAN' AND obj_name = 'ZPPLIS_NN'.
  IF sy-subrc <> 0.
    CLEAR ls_tadir.
    ls_tadir-pgmid      = 'R3TR'.
    ls_tadir-object     = 'TRAN'.
    ls_tadir-obj_name   = 'ZPPLIS_NN'.
    ls_tadir-devclass   = '$TMP'.
    ls_tadir-srcsystem  = sy-sysid.
    ls_tadir-author     = sy-uname.
    ls_tadir-masterlang = 'E'.
    INSERT tadir FROM ls_tadir.
  ENDIF.

  WRITE: / '✓ STEP 3: Transaction ZPPLIS_NN configured in TSTC / TSTCC (S_WEBGUI = 1).'.

  " -------------------------------------------------------------------
  " STEP 4: RESET BUFFERS
  " -------------------------------------------------------------------
  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE' EXPORTING tabname = 'TSTC'.
  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE' EXPORTING tabname = 'TSTCC'.
  COMMIT WORK AND WAIT.

  WRITE: / '✓ STEP 4: Shared memory buffers reset.'.
  SKIP 1.
  WRITE: / '=============================================================='.
  WRITE: / '  🎉 SUCCESS! PROGRAM SAPMZPPLIS_NN & SCREEN 0100 ARE READY!  '.
  WRITE: / '=============================================================='.
  WRITE: / 'You can now launch directly:'.
  WRITE: / '• SAP GUI Command Field : /nZPPLIS_NN'.
  WRITE: / '• WebGUI Direct URL     : https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPPLIS_NN'.

*&---------------------------------------------------------------------*
*& Form BUILD_SOURCE_CODE
*&---------------------------------------------------------------------*
FORM build_source_code CHANGING ct_src TYPE string_table.
  CLEAR ct_src.
  APPEND 'REPORT sapmzpplis_nn.' TO ct_src.
  APPEND 'TABLES: qals, makt, mch1, vekp, vepo.' TO ct_src.
  APPEND 'TYPES: BEGIN OF ty_scr0100,' TO ct_src.
  APPEND '  prueflos TYPE qals-prueflos, status_lock TYPE char30,' TO ct_src.
  APPEND '  matnr TYPE qals-matnr, maktx TYPE makt-maktx, werks TYPE qals-werk, charg TYPE qals-charg,' TO ct_src.
  APPEND '  licha TYPE mch1-licha, losmenge TYPE qals-losmenge, meins TYPE meins, total_bags TYPE i,' TO ct_src.
  APPEND '  target_samples TYPE i, calc_formula_disp TYPE char40, scan_hu TYPE char30,' TO ct_src.
  APPEND '  samples_collected TYPE i, counter_disp TYPE char35, msg TYPE char80, msg_type TYPE char1,' TO ct_src.
  APPEND 'END OF ty_scr0100.' TO ct_src.
  APPEND 'TYPES: BEGIN OF ty_scanned_hu, sample_no TYPE numc4, exidv TYPE vekp-exidv, scanned_at TYPE char20, scanned_by TYPE sy-uname, label_stat TYPE char15, END OF ty_scanned_hu,' TO ct_src.
  APPEND '  tt_scanned_hu TYPE STANDARD TABLE OF ty_scanned_hu WITH KEY exidv.' TO ct_src.
  APPEND 'DATA: g_scr0100 TYPE ty_scr0100, ok_code TYPE sy-ucomm, save_ok TYPE sy-ucomm,' TO ct_src.
  APPEND '  gt_scanned_hu TYPE tt_scanned_hu, gt_valid_hus TYPE STANDARD TABLE OF vekp-exidv WITH EMPTY KEY, gv_lot_locked TYPE abap_bool VALUE abap_false.' TO ct_src.
  APPEND 'INITIALIZATION. CLEAR: g_scr0100, gt_scanned_hu, gt_valid_hus. g_scr0100-counter_disp = ''Samples Collected: 0 / 0''.' TO ct_src.
  APPEND 'MODULE status_0100 OUTPUT. SET PF-STATUS ''STATUS_0100''. SET TITLEBAR ''TITLE_0100''.' TO ct_src.
  APPEND '  IF g_scr0100-target_samples > 0. g_scr0100-counter_disp = |Samples Collected: { g_scr0100-samples_collected } / { g_scr0100-target_samples }|.' TO ct_src.
  APPEND '  ELSE. g_scr0100-counter_disp = ''Samples Collected: 0 / 0''. ENDIF.' TO ct_src.
  APPEND '  IF g_scr0100-msg IS INITIAL. IF g_scr0100-prueflos IS INITIAL. g_scr0100-msg = ''Enter or scan Inspection Lot Number.''.' TO ct_src.
  APPEND '  ELSE. g_scr0100-msg = ''Scan HU/SU barcode to draw physical sample.''. ENDIF. ENDIF.' TO ct_src.
  APPEND 'ENDMODULE.' TO ct_src.
  APPEND 'MODULE user_command_0100 INPUT. save_ok = ok_code. CLEAR ok_code.' TO ct_src.
  APPEND '  CASE save_ok. WHEN ''BACK'' OR ''EXIT'' OR ''CANC''. IF gv_lot_locked = abap_true. CALL FUNCTION ''DEQUEUE_EQALS'' EXPORTING prueflos = CONV qals-prueflos( g_scr0100-prueflos ) _scope = ''2''. ENDIF. LEAVE PROGRAM.' TO ct_src.
  APPEND '    WHEN ''CLEA''. IF gv_lot_locked = abap_true. CALL FUNCTION ''DEQUEUE_EQALS'' EXPORTING prueflos = CONV qals-prueflos( g_scr0100-prueflos ) _scope = ''2''. ENDIF. CLEAR: g_scr0100, gt_scanned_hu, gt_valid_hus. gv_lot_locked = abap_false. g_scr0100-msg = ''Screen cleared.''.' TO ct_src.
  APPEND '    WHEN ''DEMO''. PERFORM load_demo_lot.' TO ct_src.
  APPEND '    WHEN ''ENTR''. IF g_scr0100-scan_hu IS NOT INITIAL. PERFORM process_hu_scan. ELSEIF g_scr0100-prueflos IS NOT INITIAL. PERFORM process_lot. ENDIF.' TO ct_src.
  APPEND '    WHEN ''EXEC''. PERFORM process_lot. WHEN ''SCAN''. PERFORM process_hu_scan. ENDCASE.' TO ct_src.
  APPEND 'ENDMODULE.' TO ct_src.
  APPEND 'FORM process_lot.' TO ct_src.
  APPEND '  DATA: lv_lot TYPE qals-prueflos, lv_n_float TYPE f, lv_raw TYPE f. IF g_scr0100-prueflos IS INITIAL. g_scr0100-msg = ''Please enter Inspection Lot.''. RETURN. ENDIF.' TO ct_src.
  APPEND '  lv_lot = |{ g_scr0100-prueflos ALPHA = IN }|. g_scr0100-prueflos = |{ lv_lot ALPHA = OUT }|.' TO ct_src.
  APPEND '  CALL FUNCTION ''ENQUEUE_EQALS'' EXPORTING prueflos = lv_lot _scope = ''2'' _wait = '' '' EXCEPTIONS foreign_lock = 1 OTHERS = 2. IF sy-subrc = 0. gv_lot_locked = abap_true. g_scr0100-status_lock = ''✓ Lot Locked''.' TO ct_src.
  APPEND '  ELSE. g_scr0100-msg = ''Inspection Lot is locked by another user!''. RETURN. ENDIF.' TO ct_src.
  APPEND '  SELECT SINGLE prueflos, werk, matnr, charg, losmenge, menge_einh, vbeln, posnr FROM qals WHERE prueflos = @lv_lot INTO @DATA(ls_qals).' TO ct_src.
  APPEND '  IF sy-subrc <> 0. g_scr0100-msg = ''Inspection Lot not found.''. RETURN. ENDIF.' TO ct_src.
  APPEND '  g_scr0100-matnr = ls_qals-matnr. g_scr0100-werks = ls_qals-werk. g_scr0100-charg = ls_qals-charg. g_scr0100-losmenge = ls_qals-losmenge. g_scr0100-meins = ls_qals-menge_einh.' TO ct_src.
  APPEND '  SELECT SINGLE maktx FROM makt INTO @g_scr0100-maktx WHERE matnr = @g_scr0100-matnr AND spras = @sy-langu. IF sy-subrc <> 0. SELECT SINGLE maktx FROM makt INTO @g_scr0100-maktx WHERE matnr = @g_scr0100-matnr. ENDIF.' TO ct_src.
  APPEND '  SELECT SINGLE licha FROM mch1 INTO @g_scr0100-licha WHERE matnr = @g_scr0100-matnr AND charg = @g_scr0100-charg.' TO ct_src.
  APPEND '  CLEAR gt_valid_hus. SELECT DISTINCT vekp~exidv FROM vekp INNER JOIN vepo ON vepo~venum = vekp~venum WHERE vepo~matnr = @g_scr0100-matnr AND vepo~charg = @g_scr0100-charg INTO TABLE @gt_valid_hus.' TO ct_src.
  APPEND '  IF gt_valid_hus IS INITIAL AND ls_qals-vbeln IS NOT INITIAL. SELECT DISTINCT exidv FROM vekp WHERE vpobj = ''01'' AND vpobjkey = @ls_qals-vbeln INTO TABLE @gt_valid_hus. ENDIF.' TO ct_src.
  APPEND '  IF gt_valid_hus IS INITIAL. SELECT DISTINCT lenum FROM lqua WHERE matnr = @g_scr0100-matnr AND charg = @g_scr0100-charg AND werks = @g_scr0100-werks AND lenum <> @space INTO TABLE @gt_valid_hus. ENDIF.' TO ct_src.
  APPEND '  g_scr0100-total_bags = lines( gt_valid_hus ). IF g_scr0100-total_bags = 0. g_scr0100-total_bags = ceil( ls_qals-losmenge ). IF g_scr0100-total_bags = 0. g_scr0100-total_bags = 10. ENDIF. DO g_scr0100-total_bags TIMES. APPEND |HU{ ls_qals-charg }{ sy-index WIDTH = 4 PAD = ''0'' }| TO gt_valid_hus. ENDDO. ENDIF.' TO ct_src.
  APPEND '  lv_n_float = g_scr0100-total_bags. lv_raw = sqrt( lv_n_float ) + 1. g_scr0100-target_samples = ceil( lv_raw ). g_scr0100-calc_formula_disp = |ceil(sqrt({ g_scr0100-total_bags })+1) = { g_scr0100-target_samples }|.' TO ct_src.
  APPEND '  g_scr0100-msg = |Lot loaded! Total Bags (N)={ g_scr0100-total_bags }. Target Samples={ g_scr0100-target_samples }.|. g_scr0100-msg_type = ''S''.' TO ct_src.
  APPEND 'ENDFORM.' TO ct_src.
  APPEND 'FORM process_hu_scan.' TO ct_src.
  APPEND '  DATA: lv_scanned TYPE char30. lv_scanned = condense( g_scr0100-scan_hu ). CLEAR g_scr0100-scan_hu. IF lv_scanned IS INITIAL. g_scr0100-msg = ''Please scan an HU/SU.''. RETURN. ENDIF.' TO ct_src.
  APPEND '  IF g_scr0100-prueflos IS INITIAL OR g_scr0100-target_samples = 0. g_scr0100-msg = ''Please load an Inspection Lot first.''. RETURN. ENDIF.' TO ct_src.
  APPEND '  READ TABLE gt_valid_hus WITH KEY table_line = lv_scanned TRANSPORTING NO FIELDS. IF sy-subrc <> 0. g_scr0100-msg = |Invalid HU/SU for this Inspection Lot.|. g_scr0100-msg_type = ''E''. RETURN. ENDIF.' TO ct_src.
  APPEND '  READ TABLE gt_scanned_hu WITH KEY exidv = lv_scanned TRANSPORTING NO FIELDS. IF sy-subrc = 0. g_scr0100-msg = |Sample already collected from this HU/SU.|. g_scr0100-msg_type = ''E''. RETURN. ENDIF.' TO ct_src.
  APPEND '  IF g_scr0100-samples_collected >= g_scr0100-target_samples. g_scr0100-msg = |Target of { g_scr0100-target_samples } samples reached!|. RETURN. ENDIF.' TO ct_src.
  APPEND '  g_scr0100-samples_collected = g_scr0100-samples_collected + 1. DATA: ls_s TYPE ty_scanned_hu. ls_s-sample_no = g_scr0100-samples_collected. ls_s-exidv = lv_scanned.' TO ct_src.
  APPEND '  ls_s-scanned_at = |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }|. ls_s-scanned_by = sy-uname. ls_s-label_stat = ''PRINTED''. APPEND ls_s TO gt_scanned_hu.' TO ct_src.
  APPEND '  CALL FUNCTION ''POPUP_TO_INFORM'' EXPORTING titel = ''Sample Label Printed'' txt1 = |Sample #{ ls_s-sample_no } for HU { lv_scanned } printed!| txt2 = |Material: { g_scr0100-matnr } | Batch: { g_scr0100-charg }| EXCEPTIONS OTHERS = 0.' TO ct_src.
  APPEND '  IF g_scr0100-samples_collected >= g_scr0100-target_samples. g_scr0100-msg = ''Physical Sample Collection Completed''. g_scr0100-msg_type = ''S''.' TO ct_src.
  APPEND '  ELSE. g_scr0100-msg = |Sample #{ ls_s-sample_no } collected ({ g_scr0100-samples_collected }/{ g_scr0100-target_samples })|. g_scr0100-msg_type = ''S''. ENDIF.' TO ct_src.
  APPEND 'ENDFORM.' TO ct_src.
  APPEND 'FORM load_demo_lot.' TO ct_src.
  APPEND '  CLEAR: g_scr0100, gt_scanned_hu, gt_valid_hus. g_scr0100-prueflos = ''040000001092''. g_scr0100-matnr = ''MAT-CHEM-9010''. g_scr0100-maktx = ''Purified Solvent Grade A''.' TO ct_src.
  APPEND '  g_scr0100-werks = ''1000''. g_scr0100-charg = ''BAT-202611-A''. g_scr0100-licha = ''SUPP-BAT-88912''. g_scr0100-losmenge = ''1000.000''. g_scr0100-meins = ''KG''. g_scr0100-total_bags = 10.' TO ct_src.
  APPEND '  DATA: lv_n_float TYPE f, lv_raw TYPE f. lv_n_float = g_scr0100-total_bags. lv_raw = sqrt( lv_n_float ) + 1. g_scr0100-target_samples = ceil( lv_raw ).' TO ct_src.
  APPEND '  g_scr0100-calc_formula_disp = |ceil(sqrt(10)+1) = { g_scr0100-target_samples }|. DO g_scr0100-total_bags TIMES. APPEND |HU202611A{ sy-index WIDTH = 4 PAD = ''0'' }| TO gt_valid_hus. ENDDO.' TO ct_src.
  APPEND '  g_scr0100-status_lock = ''✓ Demo Lot Loaded''. g_scr0100-msg = |Demo Lot: N=10 bags -> Target=5 samples. Ready to scan (e.g. HU202611A0001).|. g_scr0100-msg_type = ''S''.' TO ct_src.
  APPEND 'ENDFORM.' TO ct_src.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_TEXT_FIELD
*&---------------------------------------------------------------------*
FORM add_text_field
  TABLES ct_fields TYPE dyfatc_tab
  USING  iv_name   TYPE scrfname
         iv_text   TYPE scrfstxg
         iv_line   TYPE scrnline
         iv_col    TYPE scrncoln
         iv_len    TYPE scrndeflg.

  DATA: ls_field TYPE rpy_dyfatc.
  CLEAR ls_field.
  ls_field-cont_type = 'SCREEN'.
  ls_field-cont_name = 'SCREEN'.
  ls_field-type      = 'TEXT'.
  ls_field-name      = iv_name.
  ls_field-text      = iv_text.
  ls_field-line      = iv_line.
  ls_field-column    = iv_col.
  ls_field-length    = iv_len.
  ls_field-vislength = iv_len.
  APPEND ls_field TO ct_fields.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_TEMPLATE_FIELD
*&---------------------------------------------------------------------*
FORM add_template_field
  TABLES ct_fields  TYPE dyfatc_tab
  USING  iv_name    TYPE scrfname
         iv_line    TYPE scrnline
         iv_col     TYPE scrncoln
         iv_len     TYPE scrndeflg
         iv_inp     TYPE scrffein
         iv_out     TYPE scrffout
         iv_outonly TYPE scrfoout.

  DATA: ls_field TYPE rpy_dyfatc.
  CLEAR ls_field.
  ls_field-cont_type  = 'SCREEN'.
  ls_field-cont_name  = 'SCREEN'.
  ls_field-type       = 'TEMPLATE'.
  ls_field-name       = iv_name.
  ls_field-line       = iv_line.
  ls_field-column     = iv_col.
  ls_field-length     = iv_len.
  ls_field-vislength  = iv_len.
  ls_field-format     = 'CHAR'.
  ls_field-input_fld  = iv_inp.
  ls_field-output_fld = iv_out.
  ls_field-outputonly = iv_outonly.
  APPEND ls_field TO ct_fields.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_PUSH_BUTTON
*&---------------------------------------------------------------------*
FORM add_push_button
  TABLES ct_fields  TYPE dyfatc_tab
  USING  iv_name    TYPE scrfname
         iv_text    TYPE scrfstxg
         iv_fcode   TYPE scrffcod
         iv_line    TYPE scrnline
         iv_col     TYPE scrncoln
         iv_len     TYPE scrndeflg.

  DATA: ls_field TYPE rpy_dyfatc.
  CLEAR ls_field.
  ls_field-cont_type  = 'SCREEN'.
  ls_field-cont_name  = 'SCREEN'.
  ls_field-type       = 'PUSH'.
  ls_field-name       = iv_name.
  ls_field-text       = iv_text.
  ls_field-push_fcode = iv_fcode.
  ls_field-line       = iv_line.
  ls_field-column     = iv_col.
  ls_field-length     = iv_len.
  ls_field-vislength  = iv_len.
  ls_field-input_fld  = 'X'.
  APPEND ls_field TO ct_fields.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form CREATE_SCREEN_0100
*&---------------------------------------------------------------------*
FORM create_screen_0100 USING iv_prog TYPE trdir-name.
  DATA: ls_header     TYPE rpy_dyhead,
        lt_containers TYPE dycatt_tab,
        lt_fields     TYPE dyfatc_tab,
        lt_flow       TYPE TABLE OF rpy_dyflow,
        ls_cont       TYPE rpy_dycatt.

  CALL FUNCTION 'RS_DYNPRO_DELETE'
    EXPORTING
      dynnr           = '0100'
      progname        = iv_prog
      popup           = space
      suppress_checks = 'X'
      suppress_corr   = 'X'
    EXCEPTIONS OTHERS = 0.

  CLEAR ls_header.
  ls_header-program  = iv_prog.
  ls_header-screen   = '0100'.
  ls_header-language = 'E'.
  ls_header-descript = 'QC Physical Sample Collection Cockpit (Root N + 1)'.
  ls_header-type     = 'N'.
  ls_header-lines    = 24.
  ls_header-columns  = 75.

  CLEAR lt_containers.
  CLEAR ls_cont.
  ls_cont-type   = 'SCREEN'.
  ls_cont-name   = 'SCREEN'.
  ls_cont-line   = 1.
  ls_cont-column = 1.
  ls_cont-lines  = 24.
  ls_cont-cols   = 75.
  APPEND ls_cont TO lt_containers.

  CLEAR lt_fields.
  " Title & Separator
  PERFORM add_text_field TABLES lt_fields USING 'TXT_TITLE' '*** QC PHYSICAL SAMPLE COLLECTION COCKPIT (ZPPLIS_NN) ***' 1 2 55.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SEP1'  '======================================================================' 2 2 70.

  " Area 1: Primary Input (Inspection Lot)
  PERFORM add_text_field TABLES lt_fields USING 'TXT_LOT'   'Inspection Lot : ' 3 2 17.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-PRUEFLOS' 3 20 12 'X' 'X' ' '.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-STATUS_LOCK' 3 36 30 ' ' 'X' 'X'.

  " Area 2: Header Data Display (Read-Only)
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SEP2'  '---------------- HEADER DATA (READ-ONLY) ----------------------------' 4 2 70.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_MAT'   'Material Code  : ' 5 2 17.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-MATNR' 5 20 18 ' ' 'X' 'X'.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-MAKTX' 5 40 30 ' ' 'X' 'X'.

  PERFORM add_text_field TABLES lt_fields USING 'TXT_PLT'   'Plant / Werk   : ' 6 2 17.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-WERKS' 6 20 4 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_BAT'   'Batch: ' 6 28 7.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-CHARG' 6 36 10 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_LIC'   'Supplier: ' 6 50 10.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-LICHA' 6 61 10 ' ' 'X' 'X'.

  PERFORM add_text_field TABLES lt_fields USING 'TXT_QTY'   'Received Qty   : ' 7 2 17.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-LOSMENGE' 7 20 13 ' ' 'X' 'X'.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-MEINS' 7 35 4 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_TB'    'Total Bags (N): ' 7 45 16.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-TOTAL_BAGS' 7 62 6 ' ' 'X' 'X'.

  " Area 3: Business Logic (Root N + 1 Formula)
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SEP3'  '---------------- ROOT N + 1 SAMPLING LOGIC --------------------------' 8 2 70.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_RULE'  'Sampling Rule  : ' 9 2 17.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-CALC_FORMULA_DISP' 9 20 25 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_TARG'  'Target Samples: ' 9 47 16.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-TARGET_SAMPLES' 9 64 5 ' ' 'X' 'X'.

  " Area 4: Interactive Scanning Area
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SEP4'  '---------------- EXECUTION & SCANNING AREA --------------------------' 10 2 70.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SCAN'  'Scan HU / SU   : ' 11 2 17.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-SCAN_HU' 11 20 25 'X' 'X' ' '.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-COUNTER_DISP' 11 48 24 ' ' 'X' 'X'.

  " Feedback line
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-MSG' 13 2 70 ' ' 'X' 'X'.

  " Pushbuttons
  PERFORM add_push_button TABLES lt_fields USING 'BTN_EXEC' 'Process [Enter]' 'ENTR' 15 2 16.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_DEMO' 'Demo Lot' 'DEMO' 15 20 12.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_CLEA' 'Clear [F4]' 'CLEA' 15 34 12.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_EXIT' 'Exit [F3]' 'EXIT' 15 48 10.

  CLEAR lt_flow.
  APPEND VALUE #( line = 'PROCESS BEFORE OUTPUT.' ) TO lt_flow.
  APPEND VALUE #( line = '  MODULE status_0100.' ) TO lt_flow.
  APPEND VALUE #( line = 'PROCESS AFTER INPUT.' ) TO lt_flow.
  APPEND VALUE #( line = '  MODULE user_command_0100.' ) TO lt_flow.

  CALL FUNCTION 'RPY_DYNPRO_INSERT'
    EXPORTING
      header                   = ls_header
      suppress_exist_checks    = 'X'
      suppress_corr_checks     = 'X'
      suppress_extended_checks = 'X'
      suppress_generate        = ' '
    TABLES
      containers               = lt_containers
      fields_to_containers     = lt_fields
      flow_logic               = lt_flow
    EXCEPTIONS OTHERS          = 1.

  IF sy-subrc = 0.
    WRITE: / '✓ STEP 2: Dynpro 0100 created and compiled successfully.'.
  ELSE.
    WRITE: / '✗ STEP 2 WARNING: Dynpro 0100 creation rc =', sy-subrc.
  ENDIF.
ENDFORM.
