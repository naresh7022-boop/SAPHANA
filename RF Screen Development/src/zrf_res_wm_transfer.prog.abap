*&---------------------------------------------------------------------*
*& Program: SAPMZRF_RES_WM_TRANSFER
*& Program Type: Module Pool (M)
*& Description: Single-Screen RF Scanner for Reservation to WM Transfer
*& Author: SAP Techno-Functional Architect
*& Target System: SAP S/4HANA / SAP ECC
*& Transaction Code: ZRF_RESWM / ZRF01
*&---------------------------------------------------------------------*
PROGRAM sapmzrf_res_wm_transfer.

" ====================================================================
" 1. SCREEN DATA STRUCTURES & DEFINITIONS
" ====================================================================
TYPES:
  BEGIN OF ty_scr0100,
    lgnum     TYPE lgnum,
    rad_res   TYPE char1,
    rad_tr    TYPE char1,
    doc_num   TYPE char10,
    msg       TYPE char40,
  END OF ty_scr0100.

TYPES:
  BEGIN OF ty_scr0200,
    doc_type     TYPE char3,
    doc_num      TYPE char10,
    item_curr    TYPE char4,
    item_total   TYPE char4,
    item_no      TYPE posnr,
    matnr        TYPE matnr,
    maktx        TYPE char20,
    werks        TYPE werks_d,
    lgort        TYPE lgort_d,
    bwart        TYPE bwart,
    target_qty   TYPE char13,
    open_qty     TYPE char13,
    meins        TYPE meins,
    scan_lbl     TYPE char10,
    exidv_scan   TYPE exidv,
    charg_disp   TYPE charg_d,
    ser_count    TYPE char4,
    vltyp_disp   TYPE lgtyp,
    vlpla_disp   TYPE lgpla,
    lenum_disp   TYPE lenum,
    post_qty     TYPE char13,
    status_msg   TYPE char40,
  END OF ty_scr0200.

TYPES:
  BEGIN OF ty_rf_doc_header,
    doc_type     TYPE char3,
    doc_num      TYPE char10,
    lgnum        TYPE lgnum,
    werks        TYPE werks_d,
    lgort        TYPE lgort_d,
    bwart        TYPE bwart,
    kostl        TYPE kostl,
    aufnr        TYPE aufnr,
    total_items  TYPE i,
    open_items   TYPE i,
  END OF ty_rf_doc_header,

  BEGIN OF ty_rf_doc_item,
    item_no       TYPE posnr,
    matnr         TYPE matnr,
    maktx         TYPE maktx,
    target_qty    TYPE menge_d,
    picked_qty    TYPE menge_d,
    open_qty      TYPE menge_d,
    meins         TYPE meins,
    charg         TYPE charg_d,
    sernp         TYPE serail,
    is_serialized TYPE abap_bool,
    is_batch_managed TYPE abap_bool,
    vltyp         TYPE lgtyp,
    vlpla         TYPE lgpla,
    tbnum         TYPE tbnum,
    tbpos         TYPE tbpos,
    status        TYPE char1,
  END OF ty_rf_doc_item,
  tt_rf_doc_item TYPE STANDARD TABLE OF ty_rf_doc_item WITH KEY item_no,

  BEGIN OF ty_hu_stock_info,
    exidv        TYPE exidv,
    venum        TYPE venum,
    matnr        TYPE matnr,
    maktx        TYPE maktx,
    charg        TYPE charg_d,
    werks        TYPE werks_d,
    lgort        TYPE lgort_d,
    lgnum        TYPE lgnum,
    lgtyp        TYPE lgtyp,
    lgpla        TYPE lgpla,
    lenum        TYPE lenum,
    menge        TYPE menge_d,
    meins        TYPE meins,
    lqnum        TYPE lvs_lqnum,
    wm_avail_qty TYPE menge_d,
    im_avail_qty TYPE menge_d,
    serials      TYPE zcl_rf_auto_wm_im_transfer=>tt_sernr,
    is_valid     TYPE abap_bool,
  END OF ty_hu_stock_info,

  BEGIN OF ty_posting_result,
    success      TYPE abap_bool,
    mblnr        TYPE mblnr,
    mjahr        TYPE mjahr,
    tanum        TYPE tanum,
    lgnum        TYPE lgnum,
    rf_message   TYPE char40,
    return_tab   TYPE bapiret2_t,
  END OF ty_posting_result.

DATA:
  g_scr0100   TYPE ty_scr0100,
  g_scr0200   TYPE ty_scr0200,
  ok_code     TYPE sy-ucomm,
  save_ok     TYPE sy-ucomm,
  gv_cursor   TYPE char30.

DATA:
  go_controller  TYPE REF TO zcl_rf_auto_wm_im_transfer,
  gs_header      TYPE ty_rf_doc_header,
  gt_items       TYPE tt_rf_doc_item,
  gs_curr_item   TYPE ty_rf_doc_item,
  gs_hu_info     TYPE ty_hu_stock_info,
  gv_item_idx    TYPE i VALUE 1,
  gt_scanned_hus TYPE STANDARD TABLE OF exidv WITH DEFAULT KEY.

CONSTANTS:
  c_fcode_enter   TYPE sy-ucomm VALUE 'ENTR',
  c_fcode_post    TYPE sy-ucomm VALUE 'POST',
  c_fcode_next    TYPE sy-ucomm VALUE 'NEXT',
  c_fcode_prev    TYPE sy-ucomm VALUE 'PREV',
  c_fcode_back    TYPE sy-ucomm VALUE 'BACK',
  c_fcode_canc    TYPE sy-ucomm VALUE 'CANC',
  c_fcode_exit    TYPE sy-ucomm VALUE 'EXIT',
  c_fcode_clear   TYPE sy-ucomm VALUE 'CLEA',
  c_fcode_serials TYPE sy-ucomm VALUE 'SERN',
  c_fcode_bins    TYPE sy-ucomm VALUE 'BINS'.

" ====================================================================
" 2. PROCESS BEFORE OUTPUT (PBO) MODULES
" ====================================================================
MODULE status_0100 OUTPUT.
  " Guard against missing GUI status to prevent Message 00264 dump
  SELECT SINGLE progname FROM d344l INTO @DATA(lv_d344l_0100)
    WHERE progname = @sy-repid.
  IF sy-subrc = 0.
    SELECT SINGLE text FROM rsmptexts INTO @DATA(lv_stat_0100)
      WHERE progname = @sy-repid AND obj_type = 'S' AND obj_code = 'STATUS_0100'.
    IF sy-subrc = 0.
      SET PF-STATUS 'STATUS_0100'.
    ENDIF.

    SELECT SINGLE text FROM rsmptexts INTO @DATA(lv_tit_0100)
      WHERE progname = @sy-repid AND obj_type = 'T' AND obj_code = 'TITLE_0100'.
    IF sy-subrc = 0.
      SET TITLEBAR 'TITLE_0100'.
    ENDIF.
  ENDIF.

  IF go_controller IS INITIAL.
    go_controller = NEW zcl_rf_auto_wm_im_transfer( ).
  ENDIF.

  IF g_scr0100-lgnum IS INITIAL.
    GET PARAMETER ID 'LGN' FIELD g_scr0100-lgnum.
    IF g_scr0100-lgnum IS INITIAL.
      SELECT SINGLE lgnum FROM t320 INTO @g_scr0100-lgnum WHERE lgnum = 'W01'.
      IF sy-subrc <> 0.
        g_scr0100-lgnum = '100'.
      ENDIF.
    ENDIF.
  ENDIF.

  IF g_scr0100-rad_res IS INITIAL AND g_scr0100-rad_tr IS INITIAL.
    g_scr0100-rad_res = 'X'.
  ENDIF.

  SET CURSOR FIELD 'G_SCR0100-DOC_NUM'.
ENDMODULE.

MODULE status_0200 OUTPUT.
  " Guard against missing GUI status to prevent Message 00264 dump
  SELECT SINGLE progname FROM d344l INTO @DATA(lv_d344l_0200)
    WHERE progname = @sy-repid.
  IF sy-subrc = 0.
    SELECT SINGLE text FROM rsmptexts INTO @DATA(lv_stat_0200)
      WHERE progname = @sy-repid AND obj_type = 'S' AND obj_code = 'STATUS_0200'.
    IF sy-subrc = 0.
      SET PF-STATUS 'STATUS_0200'.
    ENDIF.

    SELECT SINGLE text FROM rsmptexts INTO @DATA(lv_tit_0200)
      WHERE progname = @sy-repid AND obj_type = 'T' AND obj_code = 'TITLE_0200'.
    IF sy-subrc = 0.
      SET TITLEBAR 'TITLE_0200'.
    ENDIF.
  ENDIF.

  IF gs_curr_item IS INITIAL AND gt_items IS NOT INITIAL.
    READ TABLE gt_items INTO gs_curr_item INDEX gv_item_idx.
  ENDIF.

  g_scr0200-doc_type   = gs_header-doc_type.
  g_scr0200-doc_num    = gs_header-doc_num.
  g_scr0200-item_curr  = |{ gv_item_idx }|.
  g_scr0200-item_total = |{ lines( gt_items ) }|.

  IF gs_curr_item IS NOT INITIAL.
    g_scr0200-item_no    = gs_curr_item-item_no.
    g_scr0200-matnr      = gs_curr_item-matnr.
    g_scr0200-maktx      = gs_curr_item-maktx(20).
    g_scr0200-werks      = gs_header-werks.
    g_scr0200-lgort      = gs_header-lgort.
    g_scr0200-bwart      = gs_header-bwart.
    g_scr0200-target_qty = |{ gs_curr_item-target_qty DECIMALS = 3 }|.
    g_scr0200-meins      = gs_curr_item-meins.

    " Allow scanning both HU and SU across all material types
    g_scr0200-scan_lbl = 'Scan HU/SU:'.
    IF g_scr0200-status_msg IS INITIAL.
      g_scr0200-status_msg = 'Scan HU or SU barcode'.
    ENDIF.
  ENDIF.

  " Next button control: only active if requirement remains open in other items
  DATA: lv_open_req_count TYPE i VALUE 0,
        lv_has_other_open TYPE abap_bool VALUE abap_false.

  LOOP AT gt_items INTO DATA(ls_count_item) WHERE open_qty > 0.
    lv_open_req_count = lv_open_req_count + 1.
    IF ls_count_item-item_no <> gs_curr_item-item_no.
      lv_has_other_open = abap_true.
    ENDIF.
  ENDLOOP.

  DATA: lv_curr_open TYPE abap_bool.
  lv_curr_open = COND #( WHEN gs_curr_item-open_qty > 0 THEN abap_true ELSE abap_false ).

  LOOP AT SCREEN.
    IF screen-name = 'BTN_NEXT'.
      IF lv_has_other_open = abap_true.
        screen-input = '1'.
      ELSE.
        screen-input = '0'.
      ENDIF.
      MODIFY SCREEN.
    ELSEIF screen-name = 'BTN_POST' OR screen-name = 'G_SCR0200-EXIDV_SCAN' OR screen-name = 'G_SCR0200-POST_QTY'.
      IF lv_curr_open = abap_false.
        screen-input = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF gs_hu_info-is_valid = abap_true.
    g_scr0200-exidv_scan = gs_hu_info-exidv.
    g_scr0200-charg_disp = gs_hu_info-charg.
    g_scr0200-ser_count  = |{ lines( gs_hu_info-serials ) }|.
    g_scr0200-vltyp_disp = gs_hu_info-lgtyp.
    g_scr0200-vlpla_disp = gs_hu_info-lgpla.
    g_scr0200-lenum_disp = gs_hu_info-lenum.
    IF g_scr0200-post_qty IS INITIAL.
      DATA: lv_init_qty TYPE menge_d.
      lv_init_qty = gs_hu_info-menge.
      IF lv_init_qty > gs_curr_item-open_qty.
        lv_init_qty = gs_curr_item-open_qty.
      ENDIF.
      g_scr0200-post_qty = |{ lv_init_qty DECIMALS = 3 }|.
    ENDIF.

    " Calculate pending / remaining open quantity based on scanned/posting quantity
    DATA: lv_calc_open     TYPE menge_d,
          lv_calc_post_qty TYPE menge_d,
          lv_pqty_str      TYPE string.
    lv_pqty_str = g_scr0200-post_qty.
    REPLACE ALL OCCURRENCES OF ',' IN lv_pqty_str WITH '.'.
    CONDENSE lv_pqty_str NO-GAPS.
    TRY.
        lv_calc_post_qty = lv_pqty_str.
      CATCH cx_root.
        lv_calc_post_qty = gs_hu_info-menge.
    ENDTRY.
    IF lv_calc_post_qty > gs_curr_item-open_qty.
      lv_calc_post_qty = gs_curr_item-open_qty.
    ENDIF.
    lv_calc_open = gs_curr_item-open_qty - lv_calc_post_qty.
    IF lv_calc_open < 0.
      lv_calc_open = 0.
    ENDIF.
    g_scr0200-open_qty = |{ lv_calc_open DECIMALS = 3 }|.
    SET CURSOR FIELD 'G_SCR0200-EXIDV_SCAN'.
  ELSE.
    g_scr0200-open_qty = |{ gs_curr_item-open_qty DECIMALS = 3 }|.
    SET CURSOR FIELD 'G_SCR0200-EXIDV_SCAN'.
  ENDIF.
ENDMODULE.

" ====================================================================
" 3. PROCESS AFTER INPUT (PAI) MODULES
" ====================================================================
MODULE user_command_0100 INPUT.
  save_ok = sy-ucomm.
  IF save_ok IS INITIAL.
    save_ok = ok_code.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.

  CASE save_ok.
    WHEN c_fcode_back OR c_fcode_exit OR c_fcode_canc.
      LEAVE PROGRAM.

    WHEN c_fcode_clear.
      CLEAR: g_scr0100-doc_num, g_scr0100-msg.

    WHEN c_fcode_enter OR space OR '/00'.
      PERFORM fetch_document_data.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.

MODULE user_command_0200 INPUT.
  save_ok = sy-ucomm.
  IF save_ok IS INITIAL.
    save_ok = ok_code.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.

  CASE save_ok.
    WHEN c_fcode_back OR 'BACK'.
      CLEAR: gs_hu_info, g_scr0200.
      SET SCREEN 0100.
      LEAVE SCREEN.

    WHEN c_fcode_exit OR 'EXIT' OR c_fcode_canc OR 'CANC'.
      LEAVE PROGRAM.

    WHEN c_fcode_clear OR 'CLEA'.
      CLEAR: gs_hu_info, g_scr0200-exidv_scan, g_scr0200-charg_disp,
             g_scr0200-ser_count, g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
             g_scr0200-lenum_disp, g_scr0200-post_qty, g_scr0200-status_msg.

    WHEN c_fcode_enter OR space OR '/00'.
      IF g_scr0200-exidv_scan IS INITIAL.
        g_scr0200-status_msg = 'Please scan Handling Unit (HU) or SU'.
        RETURN.
      ENDIF.

      " Check if active HU or SU on screen is scanned again
      DATA: lv_ent_raw   TYPE exidv,
            lv_ent_strip TYPE exidv.
      lv_ent_raw = g_scr0200-exidv_scan.
      CONDENSE lv_ent_raw NO-GAPS.
      lv_ent_strip = lv_ent_raw.
      SHIFT lv_ent_strip LEFT DELETING LEADING ' 0'.

      IF gs_hu_info-is_valid = abap_true.
        DATA: lv_act_raw   TYPE exidv,
              lv_act_strip TYPE exidv,
              lv_act_su    TYPE exidv.
        lv_act_raw = gs_hu_info-exidv.
        CONDENSE lv_act_raw NO-GAPS.
        lv_act_strip = lv_act_raw.
        SHIFT lv_act_strip LEFT DELETING LEADING ' 0'.
        lv_act_su = gs_hu_info-lenum.
        SHIFT lv_act_su LEFT DELETING LEADING ' 0'.

        IF lv_ent_raw = lv_act_raw OR lv_ent_strip = lv_act_strip
           OR ( lv_act_su IS NOT INITIAL AND ( lv_ent_raw = gs_hu_info-lenum OR lv_ent_strip = lv_act_su ) ).
          g_scr0200-status_msg = 'HU or SU is already scan'.
          MESSAGE s000(00) WITH 'HU or SU is already scan' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      ENDIF.

      " If cursor was on POST_QTY and user entered a new quantity, recalculate remaining
      GET CURSOR FIELD gv_cursor.
      IF gv_cursor = 'G_SCR0200-POST_QTY' AND gs_hu_info-is_valid = abap_true.
        DATA: lv_u_pqty TYPE menge_d,
              lv_u_str  TYPE string.
        lv_u_str = g_scr0200-post_qty.
        REPLACE ALL OCCURRENCES OF ',' IN lv_u_str WITH '.'.
        CONDENSE lv_u_str NO-GAPS.
        TRY.
            lv_u_pqty = lv_u_str.
          CATCH cx_root.
            lv_u_pqty = gs_hu_info-menge.
        ENDTRY.
        IF lv_u_pqty > gs_curr_item-open_qty.
          lv_u_pqty = gs_curr_item-open_qty.
        ENDIF.
        IF lv_u_pqty > gs_hu_info-menge.
          lv_u_pqty = gs_hu_info-menge.
        ENDIF.
        g_scr0200-post_qty = |{ lv_u_pqty DECIMALS = 3 }|.
        DATA(lv_upd_open) = gs_curr_item-open_qty - lv_u_pqty.
        g_scr0200-open_qty = |{ lv_upd_open DECIMALS = 3 }|.
        g_scr0200-status_msg = |Qty updated ({ lv_u_pqty DECIMALS = 3 }). Press Post (F1)|.
        RETURN.
      ENDIF.

      " User scanned barcode into the scan field -> validate it
      PERFORM validate_scanned_hu.

    WHEN c_fcode_post OR 'POST' OR 'SAVE' OR '/11'.
      PERFORM execute_posting.

    WHEN c_fcode_next OR 'NEXT'.
      " User Rule: If Requirement Qty is fulfilled then Next button should not work.
      " Only if requirement is remaining/open across other items should it work.
      DATA: lv_open_other_cnt TYPE i VALUE 0.
      LOOP AT gt_items INTO DATA(ls_chk_cnt).
        IF ls_chk_cnt-item_no <> gs_curr_item-item_no AND ls_chk_cnt-open_qty > 0.
          lv_open_other_cnt = lv_open_other_cnt + 1.
        ENDIF.
      ENDLOOP.

      IF gs_curr_item-open_qty <= 0 AND lv_open_other_cnt = 0.
        g_scr0200-status_msg = 'Requirement fulfilled. No open items.'.
      ELSEIF lv_open_other_cnt = 0.
        g_scr0200-status_msg = |Current item { gs_curr_item-item_no } is open. No other items.|.
      ELSE.
        PERFORM navigate_next_item.
        g_scr0200-status_msg = |Item { gs_curr_item-item_no } loaded.|.
      ENDIF.

    WHEN c_fcode_prev OR 'PREV'.
      PERFORM navigate_prev_item.

    WHEN c_fcode_serials OR 'SERN'.
      PERFORM display_serial_numbers.

    WHEN c_fcode_bins OR 'BINS'.
      PERFORM display_stock_bins.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.

" ====================================================================
" 4. SUBROUTINES & BUSINESS LOGIC HANDLERS
" ====================================================================
FORM fetch_document_data.
  DATA: lv_doc_type TYPE char3,
        lt_return   TYPE bapiret2_t,
        lt_scan_his TYPE zcl_rf_auto_wm_im_transfer=>tt_exidv.

  CLEAR: gs_header, gt_items, gs_curr_item, gs_hu_info, gt_scanned_hus.
  gv_item_idx = 1.

  IF g_scr0100-lgnum IS INITIAL.
    IF g_scr0100-rad_res = 'X' AND g_scr0100-doc_num IS NOT INITIAL.
      DATA: lv_res_alpha TYPE char10.
      lv_res_alpha = |{ g_scr0100-doc_num ALPHA = IN }|.
      SELECT SINGLE werks FROM resb INTO @DATA(lv_resb_werks) WHERE rsnum = @lv_res_alpha.
      IF sy-subrc = 0 AND lv_resb_werks IS NOT INITIAL.
        SELECT SINGLE lgnum FROM t320 INTO @g_scr0100-lgnum WHERE werks = @lv_resb_werks.
      ENDIF.
    ENDIF.
  ENDIF.

  IF g_scr0100-lgnum IS INITIAL.
    g_scr0100-msg = 'Enter Warehouse Number'.
    RETURN.
  ENDIF.

  IF g_scr0100-doc_num IS INITIAL.
    g_scr0100-msg = 'Enter Reservation or TR Number'.
    RETURN.
  ENDIF.

  lv_doc_type = COND #( WHEN g_scr0100-rad_res = 'X' THEN 'RES' ELSE 'TR' ).

  go_controller->get_document_details(
    EXPORTING
      iv_lgnum       = g_scr0100-lgnum
      iv_doc_type    = lv_doc_type
      iv_doc_num     = g_scr0100-doc_num
    IMPORTING
      es_header      = gs_header
      et_items       = gt_items
      et_scanned_hus = lt_scan_his
      et_return      = lt_return
  ).

  READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
  IF sy-subrc = 0.
    g_scr0100-msg = ls_err-message(40).
    MESSAGE s000(00) WITH ls_err-message DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gt_items IS INITIAL.
    g_scr0100-msg = |Only open { lv_doc_type } allowed. Doc is closed.|.
    MESSAGE s000(00) WITH |Only open { lv_doc_type } allowed. Doc is closed.| DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  DATA: lv_has_any_open TYPE abap_bool VALUE abap_false.
  LOOP AT gt_items INTO DATA(ls_chk_open) WHERE open_qty > 0.
    lv_has_any_open = abap_true.
    EXIT.
  ENDLOOP.
  IF lv_has_any_open = abap_false.
    g_scr0100-msg = |Only open { lv_doc_type } allowed. Doc is closed.|.
    MESSAGE s000(00) WITH |Only open { lv_doc_type } allowed. Doc is closed.| DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE gt_items INTO gs_curr_item INDEX gv_item_idx.
  gt_scanned_hus = lt_scan_his.

  CLEAR g_scr0100-msg.
  SET SCREEN 0200.
  LEAVE SCREEN.
ENDFORM.

FORM validate_scanned_hu.
  DATA: lt_return TYPE bapiret2_t.

  " Prevent scanning the same HU/SU multiple times in the same request
  DATA: lv_scan_in    TYPE exidv,
        lv_scan_strip TYPE exidv,
        lv_scan_pad20 TYPE exidv,
        lv_scan_pad10 TYPE char10.

  lv_scan_in = g_scr0200-exidv_scan.
  CONDENSE lv_scan_in NO-GAPS.
  lv_scan_strip = lv_scan_in.
  SHIFT lv_scan_strip LEFT DELETING LEADING ' 0'.
  lv_scan_pad20 = |{ lv_scan_strip ALPHA = IN }|.
  lv_scan_pad10 = |{ lv_scan_strip ALPHA = IN }|.

  " 1. Check if already posted for this reservation in the current session
  LOOP AT gt_scanned_hus INTO DATA(lv_done_hu).
    DATA: lv_done_raw   TYPE exidv,
          lv_done_strip TYPE exidv,
          lv_done_pad20 TYPE exidv,
          lv_done_pad10 TYPE char10.

    lv_done_raw = lv_done_hu.
    CONDENSE lv_done_raw NO-GAPS.
    lv_done_strip = lv_done_raw.
    SHIFT lv_done_strip LEFT DELETING LEADING ' 0'.
    lv_done_pad20 = |{ lv_done_strip ALPHA = IN }|.
    lv_done_pad10 = |{ lv_done_strip ALPHA = IN }|.

    IF lv_scan_in    = lv_done_raw   OR
       lv_scan_strip = lv_done_strip OR
       lv_scan_pad20 = lv_done_pad20 OR
       lv_scan_pad10 = lv_done_pad10.
      g_scr0200-status_msg = 'HU or SU is already scan'.
      MESSAGE s000(00) WITH 'HU or SU is already scan' DISPLAY LIKE 'E'.
      CLEAR: gs_hu_info, g_scr0200-charg_disp, g_scr0200-ser_count,
             g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
             g_scr0200-lenum_disp, g_scr0200-post_qty.
      g_scr0200-open_qty = |{ gs_curr_item-open_qty DECIMALS = 3 }|.
      RETURN.
    ENDIF.
  ENDLOOP.

  " 2. Check if the exact same HU is already active/validated on screen
  IF gs_hu_info-is_valid = abap_true.
    DATA: lv_act_raw   TYPE exidv,
          lv_act_strip TYPE exidv.
    lv_act_raw = gs_hu_info-exidv.
    CONDENSE lv_act_raw NO-GAPS.
    lv_act_strip = lv_act_raw.
    SHIFT lv_act_strip LEFT DELETING LEADING ' 0'.

    IF lv_scan_in = lv_act_raw OR lv_scan_strip = lv_act_strip.
      g_scr0200-status_msg = 'HU or SU is already scan'.
      MESSAGE s000(00) WITH 'HU or SU is already scan' DISPLAY LIKE 'E'.
      CLEAR: gs_hu_info, g_scr0200-charg_disp, g_scr0200-ser_count,
             g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
             g_scr0200-lenum_disp, g_scr0200-post_qty.
      g_scr0200-open_qty = |{ gs_curr_item-open_qty DECIMALS = 3 }|.
      RETURN.
    ENDIF.
  ENDIF.

  CLEAR gs_hu_info.

  go_controller->validate_hu_and_stock(
    EXPORTING
      iv_lgnum   = gs_header-lgnum
      iv_exidv   = g_scr0200-exidv_scan
      iv_matnr   = gs_curr_item-matnr
      iv_werks   = gs_header-werks
      iv_lgort   = gs_header-lgort
      iv_charg   = gs_curr_item-charg
      iv_req_qty = gs_curr_item-open_qty
      iv_doc_num = gs_header-doc_num
    IMPORTING
      es_hu_info = gs_hu_info
      et_return  = lt_return
  ).

  READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
  IF sy-subrc = 0.
    g_scr0200-status_msg = ls_err-message(40).
    MESSAGE s000(00) WITH ls_err-message DISPLAY LIKE 'E'.
    CLEAR: gs_hu_info, g_scr0200-charg_disp, g_scr0200-ser_count,
           g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
           g_scr0200-lenum_disp, g_scr0200-post_qty.
    g_scr0200-open_qty = |{ gs_curr_item-open_qty DECIMALS = 3 }|.
    RETURN.
  ENDIF.

  " 3. Extra verification: Check if resolved HU or SU was already scanned for this reservation
  LOOP AT gt_scanned_hus INTO DATA(lv_prev_res).
    DATA: lv_prev_res_strip TYPE exidv,
          lv_hu_res_strip   TYPE exidv,
          lv_su_res_strip   TYPE exidv.

    lv_prev_res_strip = lv_prev_res.
    CONDENSE lv_prev_res_strip NO-GAPS.
    SHIFT lv_prev_res_strip LEFT DELETING LEADING ' 0'.

    lv_hu_res_strip = gs_hu_info-exidv.
    CONDENSE lv_hu_res_strip NO-GAPS.
    SHIFT lv_hu_res_strip LEFT DELETING LEADING ' 0'.

    lv_su_res_strip = gs_hu_info-lenum.
    CONDENSE lv_su_res_strip NO-GAPS.
    SHIFT lv_su_res_strip LEFT DELETING LEADING ' 0'.

    IF ( lv_hu_res_strip IS NOT INITIAL AND lv_hu_res_strip = lv_prev_res_strip ) OR
       ( lv_su_res_strip IS NOT INITIAL AND lv_su_res_strip = lv_prev_res_strip ).
      g_scr0200-status_msg = 'HU or SU is already scan'.
      MESSAGE s000(00) WITH 'HU or SU is already scan' DISPLAY LIKE 'E'.
      CLEAR: gs_hu_info, g_scr0200-charg_disp, g_scr0200-ser_count,
             g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
             g_scr0200-lenum_disp, g_scr0200-post_qty.
      g_scr0200-open_qty = |{ gs_curr_item-open_qty DECIMALS = 3 }|.
      RETURN.
    ENDIF.
  ENDLOOP.

  g_scr0200-charg_disp = gs_hu_info-charg.
  g_scr0200-ser_count  = |{ lines( gs_hu_info-serials ) }|.
  g_scr0200-vltyp_disp = gs_hu_info-lgtyp.
  g_scr0200-vlpla_disp = gs_hu_info-lgpla.
  g_scr0200-lenum_disp = gs_hu_info-lenum.

  " Fetch Qty from selected HU, SU, or Batch, capped at reservation/TR material open quantity
  DATA: lv_fetch_qty TYPE menge_d.
  lv_fetch_qty = gs_hu_info-menge.
  IF lv_fetch_qty > gs_curr_item-open_qty.
    lv_fetch_qty = gs_curr_item-open_qty.
  ENDIF.

  " Calculate pending / remaining quantity after scan
  DATA: lv_rem_qty TYPE menge_d.
  lv_rem_qty = gs_curr_item-open_qty - lv_fetch_qty.
  IF lv_rem_qty < 0.
    lv_rem_qty = 0.
  ENDIF.

  g_scr0200-open_qty = |{ lv_rem_qty DECIMALS = 3 }|.
  g_scr0200-post_qty = |{ lv_fetch_qty DECIMALS = 3 }|.

  DATA(lv_disp_id) = COND exidv( WHEN gs_hu_info-exidv IS NOT INITIAL THEN gs_hu_info-exidv ELSE gs_hu_info-lenum ).
  IF lv_disp_id IS INITIAL.
    lv_disp_id = gs_hu_info-charg.
  ENDIF.
  IF lv_rem_qty > 0.
    g_scr0200-status_msg = |HU/SU { lv_disp_id } valid. Rem: { lv_rem_qty DECIMALS = 3 } { gs_curr_item-meins }. Press Post (F1)|.
  ELSE.
    g_scr0200-status_msg = |HU/SU { lv_disp_id } valid ({ lv_fetch_qty DECIMALS = 3 } { gs_curr_item-meins }). Press Post (F1)|.
  ENDIF.
ENDFORM.

FORM execute_posting.
  IF g_scr0200-exidv_scan IS INITIAL.
    g_scr0200-status_msg = 'Please scan Handling Unit (HU) or SU'.
    RETURN.
  ENDIF.

  IF gs_hu_info IS INITIAL OR gs_hu_info-is_valid = abap_false
     OR ( gs_hu_info-exidv <> g_scr0200-exidv_scan AND gs_hu_info-lenum <> g_scr0200-exidv_scan ).
    PERFORM validate_scanned_hu.
    IF gs_hu_info-is_valid = abap_false.
      RETURN.
    ENDIF.
  ENDIF.

  IF g_scr0200-post_qty IS INITIAL.
    DATA: lv_fetch_init TYPE menge_d.
    lv_fetch_init = gs_hu_info-menge.
    IF lv_fetch_init > gs_curr_item-open_qty.
      lv_fetch_init = gs_curr_item-open_qty.
    ENDIF.
    g_scr0200-post_qty = |{ lv_fetch_init DECIMALS = 3 }|.
  ENDIF.

  DATA: lv_qty     TYPE menge_d,
        lv_qty_str TYPE string.

  lv_qty_str = g_scr0200-post_qty.
  REPLACE ALL OCCURRENCES OF ',' IN lv_qty_str WITH '.'.
  CONDENSE lv_qty_str NO-GAPS.
  TRY.
      lv_qty = lv_qty_str.
    CATCH cx_root.
      g_scr0200-status_msg = 'Invalid Quantity Entered'.
      RETURN.
  ENDTRY.

  IF lv_qty <= 0.
    g_scr0200-status_msg = 'Posting Quantity must be > 0'.
    RETURN.
  ENDIF.

  " Rule: It should not allow more than reservation or TR material quantity
  IF lv_qty > gs_curr_item-open_qty.
    g_scr0200-status_msg = |Qty exceeds remaining open ({ gs_curr_item-open_qty DECIMALS = 3 })|.
    RETURN.
  ENDIF.

  " Rule: Cannot post more than available in the scanned HU/SU or Batch
  IF lv_qty > gs_hu_info-menge.
    g_scr0200-status_msg = |Qty exceeds HU/SU qty ({ gs_hu_info-menge DECIMALS = 3 })|.
    RETURN.
  ENDIF.

  DATA(ls_result) = go_controller->execute_single_step_posting(
    is_header   = gs_header
    is_item     = gs_curr_item
    is_hu_info  = gs_hu_info
    iv_post_qty = lv_qty
  ).

  IF ls_result-success = abap_true.
    gs_curr_item-picked_qty = gs_curr_item-picked_qty + lv_qty.
    gs_curr_item-open_qty   = gs_curr_item-target_qty - gs_curr_item-picked_qty.
    MODIFY gt_items FROM gs_curr_item INDEX gv_item_idx.

    " Record scanned HU/SU in all representations to strictly prevent duplicate scanning in this single reservation
    APPEND gs_hu_info-exidv TO gt_scanned_hus.
    DATA: lv_prog_h_strip TYPE exidv.
    lv_prog_h_strip = gs_hu_info-exidv.
    SHIFT lv_prog_h_strip LEFT DELETING LEADING ' 0'.
    APPEND lv_prog_h_strip TO gt_scanned_hus.
    APPEND |{ lv_prog_h_strip ALPHA = IN }| TO gt_scanned_hus.

    IF gs_hu_info-lenum IS NOT INITIAL AND gs_hu_info-lenum <> gs_hu_info-exidv.
      APPEND gs_hu_info-lenum TO gt_scanned_hus.
      DATA: lv_prog_s_strip TYPE exidv.
      lv_prog_s_strip = gs_hu_info-lenum.
      SHIFT lv_prog_s_strip LEFT DELETING LEADING ' 0'.
      APPEND lv_prog_s_strip TO gt_scanned_hus.
      APPEND |{ lv_prog_s_strip ALPHA = IN }| TO gt_scanned_hus.
    ENDIF.
    SORT gt_scanned_hus.
    DELETE ADJACENT DUPLICATES FROM gt_scanned_hus.

    CLEAR: gs_hu_info, g_scr0200-exidv_scan, g_scr0200-charg_disp,
           g_scr0200-ser_count, g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
           g_scr0200-lenum_disp, g_scr0200-post_qty.

    DATA: lv_mblnr_str TYPE string.
    lv_mblnr_str = COND #(
      WHEN ls_result-mblnr IS NOT INITIAL THEN ls_result-mblnr
      WHEN ls_result-tanum IS NOT INITIAL THEN ls_result-tanum
      ELSE 'Posted'
    ).

    IF gs_curr_item-open_qty <= 0.
      gs_curr_item-status = 'C'.
      MODIFY gt_items FROM gs_curr_item INDEX gv_item_idx.

      " Check if any other item remains open
      DATA: lv_has_other_open_items TYPE abap_bool VALUE abap_false.
      LOOP AT gt_items INTO DATA(ls_open_test) WHERE open_qty > 0.
        lv_has_other_open_items = abap_true.
        EXIT.
      ENDLOOP.

      IF lv_has_other_open_items = abap_true.
        PERFORM navigate_next_item.
        IF ls_result-dest_lgpla IS NOT INITIAL.
          g_scr0200-status_msg = |Success! Bin:{ ls_result-dest_lgtyp }/{ ls_result-dest_lgpla } Next:{ gs_curr_item-item_no }|.
        ELSE.
          g_scr0200-status_msg = |Successfully completed! Next: { gs_curr_item-item_no }|.
        ENDIF.
        MESSAGE s000(00) WITH |Successfully completed transaction! MIGO: { lv_mblnr_str } TO: { ls_result-tanum } posted.|.
      ELSE.
        IF ls_result-dest_lgpla IS NOT INITIAL.
          g_scr0200-status_msg = |Success! Bin:{ ls_result-dest_lgtyp }/{ ls_result-dest_lgpla } All closed.|.
        ELSE.
          g_scr0200-status_msg = 'Successfully completed transaction!'.
        ENDIF.
        MESSAGE s000(00) WITH |Successfully completed transaction! MIGO: { lv_mblnr_str } TO: { ls_result-tanum } posted. All closed.|.
      ENDIF.
    ELSE.
      IF ls_result-dest_lgpla IS NOT INITIAL.
        g_scr0200-status_msg = |Success! Bin:{ ls_result-dest_lgtyp }/{ ls_result-dest_lgpla } Rem:{ gs_curr_item-open_qty DECIMALS = 0 }|.
      ELSE.
        g_scr0200-status_msg = |Successfully completed! Rem: { gs_curr_item-open_qty DECIMALS = 0 }|.
      ENDIF.
      MESSAGE s000(00) WITH |Successfully completed transaction! MIGO: { lv_mblnr_str } TO: { ls_result-tanum } posted.|.
    ENDIF.
  ELSE.
    g_scr0200-status_msg = ls_result-rf_message.
    MESSAGE s000(00) WITH ls_result-rf_message DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM navigate_next_item.
  DATA(lv_total) = lines( gt_items ).

  DO lv_total TIMES.
    gv_item_idx = gv_item_idx + 1.
    IF gv_item_idx > lv_total.
      gv_item_idx = 1.
    ENDIF.

    READ TABLE gt_items INTO gs_curr_item INDEX gv_item_idx.
    IF gs_curr_item-open_qty > 0.
      CLEAR: gs_hu_info, g_scr0200-exidv_scan, g_scr0200-charg_disp,
             g_scr0200-ser_count, g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
             g_scr0200-lenum_disp, g_scr0200-post_qty.
      RETURN.
    ENDIF.
  ENDDO.

  g_scr0200-status_msg = 'All items fully transferred!'.
ENDFORM.

FORM navigate_prev_item.
  DATA(lv_total) = lines( gt_items ).
  gv_item_idx = gv_item_idx - 1.
  IF gv_item_idx < 1.
    gv_item_idx = lv_total.
  ENDIF.

  READ TABLE gt_items INTO gs_curr_item INDEX gv_item_idx.
  CLEAR: gs_hu_info, g_scr0200-exidv_scan, g_scr0200-charg_disp,
         g_scr0200-ser_count, g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
         g_scr0200-lenum_disp, g_scr0200-post_qty.
  g_scr0200-status_msg = |Item { gs_curr_item-item_no } loaded.|.
ENDFORM.

FORM display_serial_numbers.
  IF gs_hu_info IS INITIAL OR gs_hu_info-serials IS INITIAL.
    g_scr0200-status_msg = 'No serial numbers in HU'.
    RETURN.
  ENDIF.

  DATA: lv_preview TYPE string.
  LOOP AT gs_hu_info-serials INTO DATA(lv_sn) TO 3.
    lv_preview = |{ lv_preview } { lv_sn }|.
  ENDLOOP.

  g_scr0200-status_msg = |SN({ lines( gs_hu_info-serials ) }):{ lv_preview }|.
ENDFORM.

FORM display_stock_bins.
  SELECT lgtyp, lgpla, verme, meins
    FROM lqua
    INTO TABLE @DATA(lt_bins)
    UP TO 5 ROWS
    WHERE lgnum = @gs_header-lgnum
      AND matnr = @gs_curr_item-matnr
      AND verme > 0
      AND skzua = @space
      AND skzue = @space
    ORDER BY verme DESCENDING.

  IF sy-subrc = 0 AND lt_bins IS NOT INITIAL.
    DATA(ls_first) = lt_bins[ 1 ].
    g_scr0200-status_msg = |Avail: { ls_first-lgtyp }/{ ls_first-lgpla } ({ ls_first-verme } { ls_first-meins })|.
  ELSE.
    g_scr0200-status_msg = 'No available stock found in WM bins'.
  ENDIF.
ENDFORM.
