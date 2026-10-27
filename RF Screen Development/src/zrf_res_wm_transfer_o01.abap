*&---------------------------------------------------------------------*
*& Include: ZRF_RES_WM_TRANSFER_O01
*& Description: Process Before Output (PBO) Modules
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.

  " Ensure backend controller is initialized
  IF go_controller IS INITIAL.
    go_controller = NEW zcl_rf_auto_wm_im_transfer( ).
  ENDIF.

  " Set default warehouse from memory / user profile if blank
  IF g_scr0100-lgnum IS INITIAL.
    GET PARAMETER ID 'LGN' FIELD g_scr0100-lgnum.
    IF g_scr0100-lgnum IS INITIAL.
      g_scr0100-lgnum = '100'. " Standard default or template
    ENDIF.
  ENDIF.

  " Default Radio Button
  IF g_scr0100-rad_res IS INITIAL AND g_scr0100-rad_tr IS INITIAL.
    g_scr0100-rad_res = 'X'.
  ENDIF.

  " Set default cursor to Document Number field for instant barcode scanner entry
  SET CURSOR FIELD 'G_SCR0100-DOC_NUM'.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'STATUS_0200'.
  SET TITLEBAR 'TITLE_0200'.

  " Ensure an item is active
  IF gs_curr_item IS INITIAL AND gt_items IS NOT INITIAL.
    READ TABLE gt_items INTO gs_curr_item INDEX gv_item_idx.
  ENDIF.

  " Refresh Screen 0200 Display Fields from Data Objects
  g_scr0200-doc_type   = gs_header-doc_type.
  g_scr0200-doc_num    = gs_header-doc_num.
  g_scr0200-item_curr  = gv_item_idx.
  g_scr0200-item_total = lines( gt_items ).

  IF gs_curr_item IS NOT INITIAL.
    g_scr0200-item_no    = gs_curr_item-item_no.
    g_scr0200-matnr      = gs_curr_item-matnr.
    g_scr0200-maktx      = gs_curr_item-maktx(20).
    g_scr0200-werks      = gs_header-werks.
    g_scr0200-lgort      = gs_header-lgort.
    g_scr0200-bwart      = gs_header-bwart.
    g_scr0200-target_qty = gs_curr_item-target_qty.
    g_scr0200-meins      = gs_curr_item-meins.

    " Dynamic Scan Label and Guidance based on Material Management
    IF gs_curr_item-is_serialized = abap_true.
      g_scr0200-scan_lbl = 'Scan HU/SU:'.
      IF g_scr0200-status_msg IS INITIAL.
        g_scr0200-status_msg = 'Serial material: Scan HU or SU barcode'.
      ENDIF.
    ELSEIF gs_curr_item-is_batch_managed = abap_true.
      g_scr0200-scan_lbl = 'Scan Batch:'.
      IF g_scr0200-status_msg IS INITIAL.
        g_scr0200-status_msg = 'Batch material: Scan Batch number'.
      ENDIF.
    ELSE.
      g_scr0200-scan_lbl = 'Scan HU/SU:'.
      IF g_scr0200-status_msg IS INITIAL.
        g_scr0200-status_msg = 'Scan HU or SU barcode'.
      ENDIF.
    ENDIF.
  ENDIF.

  " If an HU has been validated, display its details and calculate pending open quantity
  IF gs_hu_info-is_valid = abap_true.
    g_scr0200-exidv_scan = gs_hu_info-exidv.
    g_scr0200-charg_disp = gs_hu_info-charg.
    g_scr0200-ser_count  = lines( gs_hu_info-serials ).
    g_scr0200-vltyp_disp = gs_hu_info-lgtyp.
    g_scr0200-vlpla_disp = gs_hu_info-lgpla.
    g_scr0200-lenum_disp = gs_hu_info-lenum.
    IF g_scr0200-post_qty IS INITIAL.
      DATA: lv_init_qty_o TYPE menge_d.
      lv_init_qty_o = gs_hu_info-menge.
      IF lv_init_qty_o > gs_curr_item-open_qty.
        lv_init_qty_o = gs_curr_item-open_qty.
      ENDIF.
      g_scr0200-post_qty = lv_init_qty_o.
    ENDIF.

    DATA: lv_rem_open TYPE menge_d.
    lv_rem_open = gs_curr_item-open_qty - g_scr0200-post_qty.
    IF lv_rem_open < 0.
      lv_rem_open = 0.
    ENDIF.
    g_scr0200-open_qty = lv_rem_open.
  ELSE.
    g_scr0200-open_qty = gs_curr_item-open_qty.
  ENDIF.

  " Screen Element Controls: disable Post & Scan if item complete, disable Next if no other open
  DATA: lv_has_other_open TYPE abap_bool VALUE abap_false,
        lv_curr_is_open   TYPE abap_bool.

  lv_curr_is_open = COND #( WHEN gs_curr_item-open_qty > 0 THEN abap_true ELSE abap_false ).

  LOOP AT gt_items INTO DATA(ls_cnt) WHERE open_qty > 0.
    IF ls_cnt-item_no <> gs_curr_item-item_no.
      lv_has_other_open = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.

  LOOP AT SCREEN.
    IF screen-name = 'BTN_NEXT'.
      screen-input = COND #( WHEN lv_has_other_open = abap_true THEN '1' ELSE '0' ).
      MODIFY SCREEN.
    ELSEIF screen-name = 'BTN_POST' OR screen-name = 'G_SCR0200-EXIDV_SCAN' OR screen-name = 'G_SCR0200-POST_QTY'.
      IF lv_curr_is_open = abap_false.
        screen-input = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Position cursor on HU Scan input field if open
  IF lv_curr_is_open = abap_true.
    SET CURSOR FIELD 'G_SCR0200-EXIDV_SCAN'.
  ENDIF.
ENDMODULE.
