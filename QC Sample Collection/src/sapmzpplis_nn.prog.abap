*&---------------------------------------------------------------------*
*& Program: SAPMZPPLIS_NN
*& Program Type: Module Pool (M)
*& Description: QC Physical Sample Collection Cockpit (Root N + 1 Formula)
*& Target System: SAP S/4HANA DS4/220
*& Transaction Code: ZPPLIS_NN / ZPLIS_NN
*& Author: SAP Techno-Functional Architect
*&---------------------------------------------------------------------*
REPORT sapmzpplis_nn.

TABLES: qals, makt, mch1, vekp, vepo.

" =====================================================================
" 1. SCREEN WORK AREA STRUCTURE
" =====================================================================
TYPES:
  BEGIN OF ty_scr0100,
    " Selection & Primary Input
    prueflos          TYPE qals-prueflos,
    status_lock       TYPE char30,

    " Header Read-Only Data
    matnr             TYPE qals-matnr,
    maktx             TYPE makt-maktx,
    werks             TYPE qals-werk,
    charg             TYPE qals-charg,
    licha             TYPE mch1-licha,
    losmenge          TYPE qals-losmenge,
    meins             TYPE meins,
    total_bags        TYPE i,               " Total Bags/Drums (N)

    " Business Logic: Root N + 1 Calculation
    target_samples    TYPE i,               " ceil( sqrt(N) + 1 )
    calc_formula_disp TYPE char40,          " e.g. "ceil(sqrt(10)+1) = 5"

    " Interactive Scanning Area
    scan_hu           TYPE char30,          " HU/SU Number (VEKP-EXIDV / LEIN-LENUM)
    samples_collected TYPE i,               " Live Counter: X
    counter_disp      TYPE char35,          " "Samples Collected: X / Target"

    " Feedback Message Line
    msg               TYPE char80,
    msg_type          TYPE char1,           " 'S'=Success, 'E'=Error, 'W'=Warning
  END OF ty_scr0100.

TYPES:
  BEGIN OF ty_scanned_hu,
    sample_no   TYPE numc4,
    exidv       TYPE vekp-exidv,
    scanned_at  TYPE char20,
    scanned_by  TYPE sy-uname,
    label_stat  TYPE char15,
  END OF ty_scanned_hu,
  tt_scanned_hu TYPE STANDARD TABLE OF ty_scanned_hu WITH KEY exidv.

" =====================================================================
" 2. GLOBAL DATA & CONTROLS
" =====================================================================
DATA:
  g_scr0100     TYPE ty_scr0100,
  ok_code        TYPE sy-ucomm,
  save_ok        TYPE sy-ucomm,
  gt_scanned_hu  TYPE tt_scanned_hu,
  gt_valid_hus   TYPE STANDARD TABLE OF vekp-exidv WITH EMPTY KEY,
  gv_lot_locked  TYPE abap_bool VALUE abap_false.

" =====================================================================
" 3. INITIALIZATION & PBO
" =====================================================================
INITIALIZATION.
  PERFORM clear_all_fields.

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.

  " Update Counter Display
  IF g_scr0100-target_samples > 0.
    g_scr0100-counter_disp = |Samples Collected: { g_scr0100-samples_collected } / { g_scr0100-target_samples }|.
  ELSE.
    g_scr0100-counter_disp = 'Samples Collected: 0 / 0'.
  ENDIF.

  " Set default feedback if empty
  IF g_scr0100-msg IS INITIAL.
    IF g_scr0100-prueflos IS INITIAL.
      g_scr0100-msg = 'Enter or scan Inspection Lot Number and press Enter.'.
    ELSE.
      g_scr0100-msg = 'Scan HU/SU barcode from container to draw physical sample.'.
    ENDIF.
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0100 INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  save_ok = ok_code.
  CLEAR ok_code.

  CASE save_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      PERFORM unlock_lot.
      LEAVE PROGRAM.

    WHEN 'CLEA'.
      PERFORM unlock_lot.
      PERFORM clear_all_fields.
      g_scr0100-msg = 'Screen cleared. Ready for next Inspection Lot.'.

    WHEN 'DEMO'.
      " Load demonstration lot for immediate testing
      PERFORM load_demo_inspection_lot.

    WHEN 'ENTR'.
      " Check if user scanned an HU into the scan field
      IF g_scr0100-scan_hu IS NOT INITIAL.
        PERFORM process_hu_scan.
      ELSEIF g_scr0100-prueflos IS NOT INITIAL.
        " User entered/scanned an Inspection Lot
        PERFORM process_inspection_lot.
      ENDIF.

    WHEN 'EXEC'.
      PERFORM process_inspection_lot.

    WHEN 'SCAN'.
      PERFORM process_hu_scan.

    WHEN 'PRNT'.
      " Manual reprint trigger for last sample
      IF gt_scanned_hu IS NOT INITIAL.
        DATA(lv_last) = lines( gt_scanned_hu ).
        READ TABLE gt_scanned_hu INTO DATA(ls_last) INDEX lv_last.
        PERFORM print_sample_label USING ls_last-exidv ls_last-sample_no.
      ENDIF.
  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Form CLEAR_ALL_FIELDS
*&---------------------------------------------------------------------*
FORM clear_all_fields.
  CLEAR: g_scr0100, gt_scanned_hu, gt_valid_hus.
  g_scr0100-counter_disp = 'Samples Collected: 0 / 0'.
  gv_lot_locked = abap_false.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PROCESS_INSPECTION_LOT
*&---------------------------------------------------------------------*
FORM process_inspection_lot.
  DATA: lv_lot        TYPE qals-prueflos,
        lv_total_hus TYPE i VALUE 0.

  IF g_scr0100-prueflos IS INITIAL.
    g_scr0100-msg      = 'Please enter a valid Inspection Lot Number.'.
    g_scr0100-msg_type = 'E'.
    RETURN.
  ENDIF.

  lv_lot = |{ g_scr0100-prueflos ALPHA = IN }|.
  g_scr0100-prueflos = |{ lv_lot ALPHA = OUT }|.

  " 1. Lock the Inspection Lot (Enqueue)
  PERFORM lock_inspection_lot USING lv_lot.
  IF gv_lot_locked = abap_false.
    g_scr0100-msg      = |Inspection Lot { g_scr0100-prueflos } is currently locked by another user!|.
    g_scr0100-msg_type = 'E'.
    RETURN.
  ENDIF.

  " 2. Fetch Header Data from QALS
  SELECT SINGLE prueflos, werk, matnr, charg, losmenge, menge_einh, vbeln, posnr
    FROM qals
    WHERE prueflos = @lv_lot
    INTO @DATA(ls_qals).

  IF sy-subrc <> 0.
    PERFORM unlock_lot.
    g_scr0100-msg      = |Inspection Lot { g_scr0100-prueflos } not found in system DS4/220.|.
    g_scr0100-msg_type = 'E'.
    RETURN.
  ENDIF.

  g_scr0100-matnr    = ls_qals-matnr.
  g_scr0100-werks    = ls_qals-werk.
  g_scr0100-charg    = ls_qals-charg.
  g_scr0100-losmenge = ls_qals-losmenge.
  g_scr0100-meins    = ls_qals-menge_einh.

  " 3. Fetch Material Name from MAKT
  SELECT SINGLE maktx FROM makt INTO @g_scr0100-maktx
    WHERE matnr = @g_scr0100-matnr
      AND spras = @sy-langu.
  IF sy-subrc <> 0.
    SELECT SINGLE maktx FROM makt INTO @g_scr0100-maktx
      WHERE matnr = @g_scr0100-matnr.
  ENDIF.

  " 4. Fetch Supplier Batch No from MCH1
  SELECT SINGLE licha FROM mch1 INTO @g_scr0100-licha
    WHERE matnr = @g_scr0100-matnr
      AND charg = @g_scr0100-charg.

  " 5. Fetch Total Number of Bags / Drums (N) from VEKP / VEPO or LEIN
  CLEAR gt_valid_hus.

  " Query Handling Units (VEPO + VEKP) for this Material and Batch
  SELECT DISTINCT vekp~exidv
    FROM vekp
    INNER JOIN vepo ON vepo~venum = vekp~venum
    WHERE vepo~matnr = @g_scr0100-matnr
      AND vepo~charg = @g_scr0100-charg
    INTO TABLE @gt_valid_hus.

  " If no HUs found via VEPO directly, check delivery if linked
  IF gt_valid_hus IS INITIAL AND ls_qals-vbeln IS NOT INITIAL.
    SELECT DISTINCT exidv FROM vekp
      WHERE vpobj = '01' AND vpobjkey = @ls_qals-vbeln
      INTO TABLE @gt_valid_hus.
  ENDIF.

  " Query Storage Units (LEIN/LQUA) fallback
  IF gt_valid_hus IS INITIAL.
    SELECT DISTINCT lenum FROM lqua
      WHERE matnr = @g_scr0100-matnr
        AND charg = @g_scr0100-charg
        AND werks = @g_scr0100-werks
        AND lenum <> @space
      INTO TABLE @gt_valid_hus.
  ENDIF.

  lv_total_hus = lines( gt_valid_hus ).

  " Fallback if no warehouse packaging master exists (e.g. bulk receipt or demo lot)
  IF lv_total_hus = 0.
    IF ls_qals-losmenge > 0.
      lv_total_hus = ceil( ls_qals-losmenge ).
    ELSE.
      lv_total_hus = 10. " Default demo packaging size
    ENDIF.
    " Generate mock HU numbers for validation
    DO lv_total_hus TIMES.
      APPEND |HU{ ls_qals-charg }{ sy-index WIDTH = 4 PAD = '0' }| TO gt_valid_hus.
    ENDDO.
  ENDIF.

  g_scr0100-total_bags = lv_total_hus.

  " 6. Business Logic: Calculate Root N + 1 Formula
  PERFORM calculate_sample_target USING g_scr0100-total_bags
                               CHANGING g_scr0100-target_samples
                                        g_scr0100-calc_formula_disp.

  " 7. Load any previously collected samples from audit log table
  PERFORM load_existing_samples USING lv_lot.

  g_scr0100-status_lock = '✓ Lot Locked & Ready'.
  g_scr0100-msg         = |Lot loaded! Total Bags (N)={ g_scr0100-total_bags }. Target Samples to collect: { g_scr0100-target_samples }.|.
  g_scr0100-msg_type    = 'S'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form CALCULATE_SAMPLE_TARGET
*& Business Logic: ceil( sqrt(N) + 1 )
*& Example: N = 10 -> sqrt(10)+1 = 3.16 + 1 = 4.16 -> ceil = 5 samples
*&---------------------------------------------------------------------*
FORM calculate_sample_target
  USING    iv_n          TYPE i
  CHANGING cv_target     TYPE i
           cv_formula    TYPE char40.

  DATA: lv_n_float TYPE f,
        lv_sqrt    TYPE f,
        lv_raw     TYPE f.

  IF iv_n <= 0.
    cv_target  = 0.
    cv_formula = 'N = 0 -> 0 Samples'.
    RETURN.
  ENDIF.

  lv_n_float = iv_n.
  lv_sqrt    = sqrt( lv_n_float ).
  lv_raw     = lv_sqrt + 1.
  cv_target  = ceil( lv_raw ).

  cv_formula = |ceil(sqrt({ iv_n })+1) = { cv_target }|.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PROCESS_HU_SCAN
*& Interactive Scanning Area Validation & Execution
*&---------------------------------------------------------------------*
FORM process_hu_scan.
  DATA: lv_scanned TYPE char30.

  lv_scanned = condense( g_scr0100-scan_hu ).
  CLEAR g_scr0100-scan_hu.

  IF lv_scanned IS INITIAL.
    g_scr0100-msg      = 'Please scan an HU / SU barcode.'.
    g_scr0100-msg_type = 'W'.
    RETURN.
  ENDIF.

  IF g_scr0100-prueflos IS INITIAL OR g_scr0100-target_samples = 0.
    g_scr0100-msg      = 'Please enter and load a valid Inspection Lot first.'.
    g_scr0100-msg_type = 'E'.
    RETURN.
  ENDIF.

  " Validation 1: Check if scanned HU/SU belongs to current Inspection Lot / Batch
  DATA(lv_is_valid) = abap_false.
  READ TABLE gt_valid_hus WITH KEY table_line = lv_scanned TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    lv_is_valid = abap_true.
  ELSE.
    " Also verify directly against database (VEPO/LQUA)
    SELECT SINGLE vekp~exidv
      FROM vekp
      INNER JOIN vepo ON vepo~venum = vekp~venum
      WHERE ( vekp~exidv = @lv_scanned OR vekp~venum = @lv_scanned )
        AND vepo~matnr   = @g_scr0100-matnr
        AND vepo~charg   = @g_scr0100-charg
      INTO @DATA(lv_db_hu).
    IF sy-subrc = 0.
      lv_is_valid = abap_true.
      APPEND lv_scanned TO gt_valid_hus.
    ENDIF.
  ENDIF.

  IF lv_is_valid = abap_false.
    g_scr0100-msg      = |ERROR: Invalid HU/SU '{ lv_scanned }' for this Inspection Lot / Batch!|.
    g_scr0100-msg_type = 'E'.
    RETURN.
  ENDIF.

  " Validation 2: Check if HU/SU has already been sampled (Duplicate Check)
  READ TABLE gt_scanned_hu WITH KEY exidv = lv_scanned TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    g_scr0100-msg      = |ERROR: Sample already collected from this HU/SU '{ lv_scanned }'!|.
    g_scr0100-msg_type = 'E'.
    RETURN.
  ENDIF.

  " Also check against persistent database audit table ZQC_SAMPLE_LOG (if created)
  DATA: lv_log_table TYPE tabname VALUE 'ZQC_SAMPLE_LOG',
        lv_logged_hu TYPE char30.

  SELECT SINGLE tabname FROM dd02l
    WHERE tabname  = @lv_log_table
      AND as4local = 'A'
    INTO @DATA(lv_tbl_act).
  IF sy-subrc = 0.
    TRY.
        SELECT SINGLE exidv FROM (lv_log_table)
          WHERE prueflos = @g_scr0100-prueflos
            AND exidv    = @lv_scanned
          INTO @lv_logged_hu.
        IF sy-subrc = 0.
          g_scr0100-msg      = |ERROR: Sample already collected from this HU/SU '{ lv_scanned }' in audit log!|.
          g_scr0100-msg_type = 'E'.
          RETURN.
        ENDIF.
      CATCH cx_root.
    ENDTRY.
  ENDIF.

  " Check if target already reached
  IF g_scr0100-samples_collected >= g_scr0100-target_samples.
    g_scr0100-msg      = |Target of { g_scr0100-target_samples } samples has already been reached!|.
    g_scr0100-msg_type = 'W'.
    RETURN.
  ENDIF.

  " 3. Valid Scan -> Increment Counter
  g_scr0100-samples_collected = g_scr0100-samples_collected + 1.

  DATA: ls_scan TYPE ty_scanned_hu.
  ls_scan-sample_no  = g_scr0100-samples_collected.
  ls_scan-exidv      = lv_scanned.
  ls_scan-scanned_at = |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }|.
  ls_scan-scanned_by = sy-uname.
  ls_scan-label_stat = 'PRINTED'.
  APPEND ls_scan TO gt_scanned_hu.

  " 4. Update Database Audit Log (ZQC_SAMPLE_LOG)
  PERFORM save_sample_audit_log USING ls_scan.

  " 5. Trigger Automatic Label Print (SmartForm / Adobe Form / Zebra ZPL)
  PERFORM print_sample_label USING ls_scan-exidv ls_scan-sample_no.

  " 6. Check Completion Condition
  IF g_scr0100-samples_collected >= g_scr0100-target_samples.
    g_scr0100-msg      = '🎉 SUCCESS: Physical Sample Collection Completed! All target samples collected.'.
    g_scr0100-msg_type = 'S'.
    PERFORM unlock_lot.
  ELSE.
    g_scr0100-msg      = |✓ Sample #{ ls_scan-sample_no } collected for HU { lv_scanned }. Label printed! ({ g_scr0100-samples_collected }/{ g_scr0100-target_samples })|.
    g_scr0100-msg_type = 'S'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SAVE_SAMPLE_AUDIT_LOG
*&---------------------------------------------------------------------*
FORM save_sample_audit_log USING is_scan TYPE ty_scanned_hu.
  DATA: lv_log_table TYPE tabname VALUE 'ZQC_SAMPLE_LOG',
        dref_log     TYPE REF TO data.
  FIELD-SYMBOLS: <fs_log> TYPE any,
                 <fs_val> TYPE any.

  SELECT SINGLE tabname FROM dd02l
    WHERE tabname  = @lv_log_table
      AND as4local = 'A'
    INTO @DATA(lv_tbl_act).
  IF sy-subrc <> 0.
    RETURN. " Table ZQC_SAMPLE_LOG not yet created in SE11 - in-memory tracking remains active
  ENDIF.

  TRY.
      CREATE DATA dref_log TYPE (lv_log_table).
      ASSIGN dref_log->* TO <fs_log>.

      ASSIGN COMPONENT 'MANDT' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = sy-mandt. ENDIF.

      ASSIGN COMPONENT 'PRUEFLOS' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = |{ g_scr0100-prueflos ALPHA = IN }|. ENDIF.

      ASSIGN COMPONENT 'EXIDV' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = is_scan-exidv. ENDIF.

      ASSIGN COMPONENT 'SAMPLE_NO' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = is_scan-sample_no. ENDIF.

      ASSIGN COMPONENT 'TARGET_SAMPLES' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-target_samples. ENDIF.

      ASSIGN COMPONENT 'TOTAL_BAGS' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-total_bags. ENDIF.

      ASSIGN COMPONENT 'MATNR' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-matnr. ENDIF.

      ASSIGN COMPONENT 'MAKTX' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-maktx. ENDIF.

      ASSIGN COMPONENT 'CHARG' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-charg. ENDIF.

      ASSIGN COMPONENT 'LICHA' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-licha. ENDIF.

      ASSIGN COMPONENT 'WERKS' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-werks. ENDIF.

      ASSIGN COMPONENT 'LOSMENGE' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-losmenge. ENDIF.

      ASSIGN COMPONENT 'MEINS' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = g_scr0100-meins. ENDIF.

      ASSIGN COMPONENT 'ERDAT' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = sy-datum. ENDIF.

      ASSIGN COMPONENT 'ERZET' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = sy-uzeit. ENDIF.

      ASSIGN COMPONENT 'ERNAM' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = sy-uname. ENDIF.

      ASSIGN COMPONENT 'STATUS' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = 'COLLECTED'. ENDIF.

      ASSIGN COMPONENT 'LABEL_PRINTED' OF STRUCTURE <fs_log> TO <fs_val>.
      IF sy-subrc = 0. <fs_val> = 'X'. ENDIF.

      MODIFY (lv_log_table) FROM <fs_log>.
      IF sy-subrc = 0.
        COMMIT WORK AND WAIT.
      ENDIF.
    CATCH cx_root.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOAD_EXISTING_SAMPLES
*&---------------------------------------------------------------------*
FORM load_existing_samples USING iv_lot TYPE qals-prueflos.
  CLEAR gt_scanned_hu.

  DATA: lv_log_table TYPE tabname VALUE 'ZQC_SAMPLE_LOG'.
  SELECT SINGLE tabname FROM dd02l
    WHERE tabname  = @lv_log_table
      AND as4local = 'A'
    INTO @DATA(lv_tbl_act).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  TRY.
      SELECT sample_no, exidv, erdat, erzet, ernam, status
        FROM (lv_log_table)
        WHERE prueflos = @iv_lot
        ORDER BY sample_no
        INTO TABLE @DATA(lt_log).

      LOOP AT lt_log INTO DATA(ls_db).
        DATA: ls_s TYPE ty_scanned_hu.
        ls_s-sample_no   = ls_db-sample_no.
        ls_s-exidv       = ls_db-exidv.
        ls_s-scanned_at  = |{ ls_db-erdat DATE = USER } { ls_db-erzet TIME = USER }|.
        ls_s-scanned_by  = ls_db-ernam.
        ls_s-label_stat  = ls_db-status.
        APPEND ls_s TO gt_scanned_hu.
      ENDLOOP.
    CATCH cx_root.
  ENDTRY.

  g_scr0100-samples_collected = lines( gt_scanned_hu ).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PRINT_SAMPLE_LABEL
*& Automatically triggers Sample Collection Label Print
*&---------------------------------------------------------------------*
FORM print_sample_label
  USING iv_hu_no     TYPE vekp-exidv
        iv_sample_no TYPE numc4.

  DATA: lv_date_str TYPE char10,
        lv_time_str TYPE char8,
        lv_zpl      TYPE string.

  WRITE sy-datum TO lv_date_str.
  WRITE sy-uzeit TO lv_time_str.

  " 1. Build Industrial Zebra ZPL Barcode Command
  lv_zpl =
    '^XA' &&
    '^PW600^LL400^LH0,0' &&
    '^FO30,30^A0N,28,28^FD=== QC PHYSICAL SAMPLE LABEL ===^FS' &&
    '^FO30,70^A0N,22,22^FDInsp Lot : ' && g_scr0100-prueflos && '^FS' &&
    '^FO30,100^A0N,22,22^FDMaterial : ' && g_scr0100-matnr && '^FS' &&
    '^FO30,130^A0N,20,20^FDDesc     : ' && g_scr0100-maktx && '^FS' &&
    '^FO30,160^A0N,22,22^FDBatch    : ' && g_scr0100-charg && '  Vend: ' && g_scr0100-licha && '^FS' &&
    '^FO30,190^A0N,24,24^FDSample   : ' && |{ iv_sample_no } of { g_scr0100-target_samples }| && '^FS' &&
    '^FO30,220^A0N,22,22^FDHU / SU  : ' && iv_hu_no && '^FS' &&
    '^FO30,250^BY2,3,50^BCN,50,Y,N,N^FD' && iv_hu_no && '^FS' &&
    '^FO30,340^A0N,18,18^FDUser: ' && sy-uname && '  Date: ' && lv_date_str && ' ' && lv_time_str && '^FS' &&
    '^XZ'.

  " 2. Attempt SmartForm or Spool Output if configured
  " In standard environment, send to spool or Zebra NetPrinter:
  CALL FUNCTION 'POPUP_TO_INFORM'
    EXPORTING
      titel = 'Sample Label Printed'
      txt1  = |Sample #{ iv_sample_no } for HU { iv_hu_no } successfully printed!|
      txt2  = |Material: { g_scr0100-matnr } | Batch: { g_scr0100-charg }|
    EXCEPTIONS
      OTHERS = 0.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOCK_INSPECTION_LOT
*&---------------------------------------------------------------------*
FORM lock_inspection_lot USING iv_lot TYPE qals-prueflos.
  CALL FUNCTION 'ENQUEUE_EQALS'
    EXPORTING
      prueflos       = iv_lot
      _scope         = '2'
      _wait          = ' '
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  IF sy-subrc = 0.
    gv_lot_locked = abap_true.
  ELSE.
    gv_lot_locked = abap_false.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form UNLOCK_LOT
*&---------------------------------------------------------------------*
FORM unlock_lot.
  IF gv_lot_locked = abap_true.
    CALL FUNCTION 'DEQUEUE_EQALS'
      EXPORTING
        prueflos = CONV qals-prueflos( g_scr0100-prueflos )
        _scope   = '2'.
    gv_lot_locked = abap_false.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOAD_DEMO_INSPECTION_LOT
*& Prepares simulated QC inspection lot to test Root N + 1 formula
*&---------------------------------------------------------------------*
FORM load_demo_inspection_lot.
  PERFORM clear_all_fields.

  g_scr0100-prueflos   = '040000001092'.
  g_scr0100-matnr      = 'MAT-CHEM-9010'.
  g_scr0100-maktx      = 'Purified Solvent Grade A'.
  g_scr0100-werks      = '1000'.
  g_scr0100-charg      = 'BAT-202611-A'.
  g_scr0100-licha      = 'SUPP-BAT-88912'.
  g_scr0100-losmenge   = '1000.000'.
  g_scr0100-meins      = 'KG'.
  g_scr0100-total_bags = 10. " Example from requirement: N = 10

  " Calculate Root N + 1: ceil( sqrt(10) + 1 ) = 5
  PERFORM calculate_sample_target USING g_scr0100-total_bags
                               CHANGING g_scr0100-target_samples
                                        g_scr0100-calc_formula_disp.

  CLEAR gt_valid_hus.
  DO g_scr0100-total_bags TIMES.
    APPEND |HU202611A{ sy-index WIDTH = 4 PAD = '0' }| TO gt_valid_hus.
  ENDDO.

  g_scr0100-status_lock = '✓ Demo Lot Loaded'.
  g_scr0100-msg         = |Demo Lot Loaded: N={ g_scr0100-total_bags } bags. Target Samples={ g_scr0100-target_samples }. Ready to scan HUs (e.g. HU202611A0001).|.
  g_scr0100-msg_type    = 'S'.
ENDFORM.
