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
        g_scr0200-post_qty = lv_u_pqty.
        DATA(lv_upd_open) = gs_curr_item-open_qty - lv_u_pqty.
        g_scr0200-open_qty = lv_upd_open.
        g_scr0200-status_msg = |Qty updated ({ lv_u_pqty DECIMALS = 3 }). Press Post (F1)|.
        RETURN.
      ENDIF.

      " User scanned barcode into the scan field -> validate it
      PERFORM validate_scanned_hu.

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
