*&---------------------------------------------------------------------*
*& Include: ZRF_RES_WM_TRANSFER_I01
*& Description: Process After Input (PAI) Modules
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0100 INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  save_ok = ok_code.
  CLEAR ok_code.

  CASE save_ok.
    WHEN c_fcode_back OR c_fcode_exit OR c_fcode_canc.
      LEAVE PROGRAM.

    WHEN c_fcode_clear.
      CLEAR: g_scr0100-doc_num, g_scr0100-msg.

    WHEN c_fcode_enter.
      " Validate Document and retrieve items
      PERFORM fetch_document_data.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0200 INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  save_ok = ok_code.
  CLEAR ok_code.

  CASE save_ok.
    WHEN c_fcode_back.
      " Return to selection screen 0100
      CLEAR: gs_hu_info, g_scr0200.
      SET SCREEN 0100.
      LEAVE SCREEN.

    WHEN c_fcode_clear.
      " Clear scanned HU data
      CLEAR: gs_hu_info, g_scr0200-exidv_scan, g_scr0200-charg_disp,
             g_scr0200-ser_count, g_scr0200-vltyp_disp, g_scr0200-vlpla_disp,
             g_scr0200-lenum_disp, g_scr0200-post_qty, g_scr0200-status_msg.

    WHEN c_fcode_enter.
      " Triggered on Barcode Scan of Handling Unit
      IF g_scr0200-exidv_scan IS NOT INITIAL.
        PERFORM validate_scanned_hu.
      ELSE.
        g_scr0200-status_msg = 'Please scan Handling Unit (HU)'.
      ENDIF.

    WHEN c_fcode_post.
      " Single-Click Atomic Posting
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

    WHEN c_fcode_prev.
      " Switch to previous open item
      PERFORM navigate_prev_item.

    WHEN c_fcode_serials.
      " Display Serial Numbers in popup
      PERFORM display_serial_numbers.

    WHEN c_fcode_bins.
      " Display available stock bins
      PERFORM display_stock_bins.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
