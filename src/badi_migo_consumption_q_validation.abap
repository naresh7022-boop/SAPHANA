*&---------------------------------------------------------------------*
*& Implementation: MIGO Goods Movements & Project Stock Consumption (Q)
*& BAdI:           MB_MIGO_BADI
*& Class:          ZCL_IM_ZMB_MIGO_BADI
*& Purpose:        Validate Consumption for Project Stock (Q) / 221 / 281
*&---------------------------------------------------------------------*

* ======================================================================
* BLOCK 1: Class Definition -> PRIVATE SECTION
* Add item cache table to store line items for check
* ======================================================================
  TYPES:
    BEGIN OF ty_goitem_cache,
      line_id TYPE mb_line_id,
      item    TYPE goitem,
    END OF ty_goitem_cache,
    ty_t_goitem_cache TYPE HASHED TABLE OF ty_goitem_cache WITH UNIQUE KEY line_id.

  DATA gt_goitem_cache TYPE ty_t_goitem_cache.


* ======================================================================
* BLOCK 2: Method IF_EX_MB_MIGO_BADI~LINE_MODIFY
* (Captures item state on entry/change)
* ======================================================================
METHOD if_ex_mb_migo_badi~line_modify.
  DATA: ls_cache TYPE ty_goitem_cache.

  ls_cache-line_id = i_line_id.
  ls_cache-item    = cs_goitem.
  MODIFY TABLE gt_goitem_cache FROM ls_cache.
  IF sy-subrc <> 0.
    INSERT ls_cache INTO TABLE gt_goitem_cache.
  ENDIF.
ENDMETHOD.


* ======================================================================
* BLOCK 3: Method IF_EX_MB_MIGO_BADI~LINE_DELETE
* (Cleans up deleted line items)
* ======================================================================
METHOD if_ex_mb_migo_badi~line_delete.
  DELETE TABLE gt_goitem_cache WITH TABLE KEY line_id = i_line_id.
ENDMETHOD.


* ======================================================================
* BLOCK 4: Method IF_EX_MB_MIGO_BADI~RESET
* (Clears cache on screen refresh / new document)
* ======================================================================
METHOD if_ex_mb_migo_badi~reset.
  CLEAR: gt_extdata,
         g_no_input,
         gs_exdata_header,
         g_cancel,
         g_line_id,
         gt_goitem_cache.
ENDMETHOD.


* ======================================================================
* BLOCK 5: Method IF_EX_MB_MIGO_BADI~CHECK_ITEM
* (Validates Project Stock Consumption: SOBKZ = 'Q' or movement 221/281 or WBS)
* ======================================================================
METHOD if_ex_mb_migo_badi~check_item.
  DATA: ls_cache    TYPE ty_goitem_cache,
        lv_wbs      TYPE ps_psp_pnr,
        lv_allowed  TYPE abap_bool,
        lv_message  TYPE string,
        ls_bapiret2 TYPE bapiret2.

  READ TABLE gt_goitem_cache INTO ls_cache WITH TABLE KEY line_id = i_line_id.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " Only validate items with a material number
  IF ls_cache-item-matnr IS INITIAL.
    RETURN.
  ENDIF.

  " Determine WBS element:
  " 1) mat_pspnr  (Special stock WBS for project purchase stock 'Q')
  " 2) ps_psp_pnr (Account assignment WBS, e.g. movement 221 / 281)
  CLEAR lv_wbs.
  IF ls_cache-item-sobkz = 'Q' AND ls_cache-item-mat_pspnr IS NOT INITIAL.
    lv_wbs = ls_cache-item-mat_pspnr.
  ELSEIF ls_cache-item-ps_psp_pnr IS NOT INITIAL.
    lv_wbs = ls_cache-item-ps_psp_pnr.
  ELSEIF ls_cache-item-mat_pspnr IS NOT INITIAL.
    lv_wbs = ls_cache-item-mat_pspnr.
  ENDIF.

  " Validate when:
  " - Special stock indicator is 'Q' (Project Stock), OR
  " - Movement type is project consumption (221, 222, 281, 282), OR
  " - WBS element is populated
  IF ls_cache-item-sobkz = 'Q' OR lv_wbs IS NOT INITIAL.
    IF lv_wbs IS NOT INITIAL.
      zcl_ps_wbs_mat_validate=>check_material_allowed(
        EXPORTING
          iv_wbs      = lv_wbs
          iv_matnr    = ls_cache-item-matnr
          iv_werks    = ls_cache-item-werks
          iv_quantity = ls_cache-item-erfmg
        IMPORTING
          ev_allowed  = lv_allowed
          ev_message  = lv_message
      ).

      IF lv_allowed = abap_false.
        CLEAR ls_bapiret2.
        ls_bapiret2-type       = 'E'.
        ls_bapiret2-id         = '00'.
        ls_bapiret2-number     = '001'.
        ls_bapiret2-message    = lv_message.
        ls_bapiret2-message_v1 = lv_message(50).
        IF strlen( lv_message ) > 50.
          ls_bapiret2-message_v2 = lv_message+50.
        ENDIF.
        ls_bapiret2-parameter  = 'MATNR'.
        ls_bapiret2-row        = i_line_id.
        APPEND ls_bapiret2 TO et_bapiret2.
      ENDIF.
    ENDIF.
  ENDIF.
ENDMETHOD.
