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
        lt_return   TYPE bapiret2_t.

  CLEAR: gs_header, gt_items, gs_curr_item, gs_hu_info.
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
      iv_lgnum    = g_scr0100-lgnum
      iv_doc_type = lv_doc_type
      iv_doc_num  = g_scr0100-doc_num
    IMPORTING
      es_header   = gs_header
      et_items    = gt_items
      et_return   = lt_return
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
    IMPORTING
      es_hu_info = gs_hu_info
      et_return  = lt_return
  ).

  READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
  IF sy-subrc = 0.
    g_scr0200-status_msg = ls_err-message(40).
    CLEAR: g_scr0200-charg_disp, g_scr0200-ser_count,
           g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
           g_scr0200-lenum_disp, g_scr0200-post_qty.
    RETURN.
  ENDIF.

  " Populate screen fields
  g_scr0200-charg_disp = gs_hu_info-charg.
  g_scr0200-ser_count  = lines( gs_hu_info-serials ).
  g_scr0200-vltyp_disp = gs_hu_info-lgtyp.
  g_scr0200-vlpla_disp = gs_hu_info-lgpla.
  g_scr0200-lenum_disp = gs_hu_info-lenum.
  g_scr0200-post_qty   = gs_hu_info-menge.
  g_scr0200-status_msg = |HU Validated. Ready to Post (F1).|.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form EXECUTE_POSTING
*& Triggers single-click IM & LE-WM atomic transaction with rollback
*&---------------------------------------------------------------------*
FORM execute_posting.
  IF gs_hu_info IS INITIAL OR gs_hu_info-is_valid = abap_false.
    g_scr0200-status_msg = 'Please scan & validate HU first'.
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
