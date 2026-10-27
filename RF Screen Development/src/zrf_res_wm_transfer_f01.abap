*&---------------------------------------------------------------------*
*& Include: ZRF_RES_WM_TRANSFER_F01
*& Description: Subroutines and Business Logic Handlers
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form FETCH_DOCUMENT_DATA
*& Validates Document Number on Screen 0100 and reads items
*&---------------------------------------------------------------------*
FORM fetch_document_data.
  DATA: lv_doc_type TYPE char3,
        lt_return   TYPE bapiret2_t,
        lt_scan_his TYPE zcl_rf_auto_wm_im_transfer=>tt_exidv.

  CLEAR: gs_header, gt_items, gs_curr_item, gs_hu_info, gt_scanned_hus.
  gv_item_idx = 1.

  IF g_scr0100-lgnum IS INITIAL.
    g_scr0100-msg = 'Enter Warehouse Number'.
    RETURN.
  ENDIF.

  IF g_scr0100-doc_num IS INITIAL.
    g_scr0100-msg = 'Enter Reservation or TR Number'.
    RETURN.
  ENDIF.

  lv_doc_type = COND #( WHEN g_scr0100-rad_res = 'X' THEN 'RES' ELSE 'TR' ).

  " Call Backend Class
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

  " Set first open item active
  READ TABLE gt_items INTO gs_curr_item INDEX gv_item_idx.
  gt_scanned_hus = lt_scan_his.

  " Navigate to screen 0200
  CLEAR g_scr0100-msg.
  SET SCREEN 0200.
  LEAVE SCREEN.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form VALIDATE_SCANNED_HU
*& Validates Scanned HU against Material, Batch, and WM Quants
*&---------------------------------------------------------------------*
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
      g_scr0200-open_qty = gs_curr_item-open_qty.
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
      g_scr0200-open_qty = gs_curr_item-open_qty.
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
    CLEAR: g_scr0200-charg_disp, g_scr0200-ser_count,
           g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
           g_scr0200-lenum_disp, g_scr0200-post_qty.
    g_scr0200-open_qty = gs_curr_item-open_qty.
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
      g_scr0200-open_qty = gs_curr_item-open_qty.
      RETURN.
    ENDIF.
  ENDLOOP.

  " Populate screen fields
  g_scr0200-charg_disp = gs_hu_info-charg.
  g_scr0200-ser_count  = lines( gs_hu_info-serials ).
  g_scr0200-vltyp_disp = gs_hu_info-lgtyp.
  g_scr0200-vlpla_disp = gs_hu_info-lgpla.
  g_scr0200-lenum_disp = gs_hu_info-lenum.

  " Fetch Qty from selected HU, SU, or Batch, capped at reservation/TR material open quantity
  DATA: lv_fetch_qty TYPE menge_d.
  lv_fetch_qty = gs_hu_info-menge.
  IF lv_fetch_qty > gs_curr_item-open_qty.
    lv_fetch_qty = gs_curr_item-open_qty.
  ENDIF.

  DATA: lv_rem_qty TYPE menge_d.
  lv_rem_qty = gs_curr_item-open_qty - lv_fetch_qty.
  IF lv_rem_qty < 0.
    lv_rem_qty = 0.
  ENDIF.

  g_scr0200-open_qty = lv_rem_qty.
  g_scr0200-post_qty = lv_fetch_qty.

  IF gs_curr_item-is_batch_managed = abap_true AND gs_curr_item-is_serialized = abap_false.
    IF lv_rem_qty > 0.
      g_scr0200-status_msg = |Batch { gs_hu_info-charg } valid. Rem: { lv_rem_qty DECIMALS = 3 } { gs_curr_item-meins }. Press Post (F1)|.
    ELSE.
      g_scr0200-status_msg = |Batch { gs_hu_info-charg } valid ({ lv_fetch_qty DECIMALS = 3 } { gs_curr_item-meins }). Press Post (F1)|.
    ENDIF.
  ELSE.
    IF lv_rem_qty > 0.
      g_scr0200-status_msg = |HU/SU { gs_hu_info-exidv } valid. Rem: { lv_rem_qty DECIMALS = 3 } { gs_curr_item-meins }. Press Post (F1)|.
    ELSE.
      g_scr0200-status_msg = |HU/SU { gs_hu_info-exidv } valid ({ lv_fetch_qty DECIMALS = 3 } { gs_curr_item-meins }). Press Post (F1)|.
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form EXECUTE_POSTING
*& Triggers single-click IM & LE-WM atomic transaction with rollback
*&---------------------------------------------------------------------*
FORM execute_posting.
  IF gs_hu_info IS INITIAL OR gs_hu_info-is_valid = abap_false.
    IF gs_curr_item-is_batch_managed = abap_true AND gs_curr_item-is_serialized = abap_false.
      g_scr0200-status_msg = 'Please scan & validate Batch first'.
    ELSE.
      g_scr0200-status_msg = 'Please scan & validate HU first'.
    ENDIF.
    RETURN.
  ENDIF.

  IF g_scr0200-post_qty <= 0.
    g_scr0200-status_msg = 'Posting Quantity must be > 0'.
    RETURN.
  ENDIF.

  " Call Backend Class for Atomic Posting
  DATA(ls_result) = go_controller->execute_single_step_posting(
    is_header   = gs_header
    is_item     = gs_curr_item
    is_hu_info  = gs_hu_info
    iv_post_qty = g_scr0200-post_qty
  ).

  IF ls_result-success = abap_true.
    " Update item open quantity
    gs_curr_item-picked_qty = gs_curr_item-picked_qty + g_scr0200-post_qty.
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

    " Clear scanned HU for next scan
    CLEAR: gs_hu_info, g_scr0200-exidv_scan, g_scr0200-charg_disp,
           g_scr0200-ser_count, g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
           g_scr0200-lenum_disp, g_scr0200-post_qty.

    DATA: lv_mblnr_str TYPE string.
    lv_mblnr_str = COND #(
      WHEN ls_result-mblnr IS NOT INITIAL THEN ls_result-mblnr
      WHEN ls_result-tanum IS NOT INITIAL THEN ls_result-tanum
      ELSE 'Posted'
    ).

    " If current item is fully processed, move to next open item or complete
    IF gs_curr_item-open_qty <= 0.
      gs_curr_item-status = 'C'.
      MODIFY gt_items FROM gs_curr_item INDEX gv_item_idx.

      DATA: lv_has_other_open_items TYPE abap_bool VALUE abap_false.
      LOOP AT gt_items INTO DATA(ls_open_test) WHERE open_qty > 0.
        lv_has_other_open_items = abap_true.
        EXIT.
      ENDLOOP.

      IF lv_has_other_open_items = abap_true.
        PERFORM navigate_next_item.
        g_scr0200-status_msg = |Successfully completed! Next: { gs_curr_item-item_no }|.
        MESSAGE s000(00) WITH |Successfully completed transaction! MIGO: { lv_mblnr_str } posted.|.
      ELSE.
        g_scr0200-status_msg = 'Successfully completed transaction!'.
        MESSAGE s000(00) WITH |Successfully completed transaction! MIGO: { lv_mblnr_str } posted. All closed.|.
      ENDIF.
    ELSE.
      g_scr0200-status_msg = |Successfully completed! Rem: { gs_curr_item-open_qty DECIMALS = 0 }|.
      MESSAGE s000(00) WITH |Successfully completed transaction! MIGO: { lv_mblnr_str } posted.|.
    ENDIF.
  ELSE.
    g_scr0200-status_msg = ls_result-rf_message.
    MESSAGE s000(00) WITH ls_result-rf_message DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form NAVIGATE_NEXT_ITEM
*&---------------------------------------------------------------------*
FORM navigate_next_item.
  DATA(lv_total) = lines( gt_items ).
  DATA(lv_start) = gv_item_idx.

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

  " If all items completed
  g_scr0200-status_msg = 'All items fully transferred!'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form NAVIGATE_PREV_ITEM
*&---------------------------------------------------------------------*
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

*&---------------------------------------------------------------------*
*& Form DISPLAY_SERIAL_NUMBERS
*&---------------------------------------------------------------------*
FORM display_serial_numbers.
  IF gs_hu_info IS INITIAL OR gs_hu_info-serials IS INITIAL.
    g_scr0200-status_msg = 'No serial numbers in HU'.
    RETURN.
  ENDIF.

  " Concatenate first 3 serials for RF screen message
  DATA: lv_preview TYPE string.
  LOOP AT gs_hu_info-serials INTO DATA(lv_sn) TO 3.
    lv_preview = |{ lv_preview } { lv_sn }|.
  ENDLOOP.

  g_scr0200-status_msg = |SN({ lines( gs_hu_info-serials ) }):{ lv_preview }|.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY_STOCK_BINS
*& Displays available stock bins for the required material
*&---------------------------------------------------------------------*
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
