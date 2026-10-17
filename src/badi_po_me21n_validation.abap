*&---------------------------------------------------------------------*
*& Implementation: Purchase Order Validation (ME21N / ME22N)
*& BAdI:           ME_PROCESS_PO_CUST
*& Class:          ZCL_IM_ME_PROCESS_PO_CUST1
*& Purpose:        Validate Account Assignment Category Q (Project Stock)
*&                 against ZWBS_MAT_ALLOW
*&---------------------------------------------------------------------*

* ======================================================================
* BLOCK 1: Method IF_EX_ME_PROCESS_PO_CUST~PROCESS_ACCOUNT
* (Triggered instantly when WBS is assigned with KNTTP = 'Q')
* ======================================================================
METHOD if_ex_me_process_po_cust~process_account.
  DATA: ls_acct_data  TYPE mepoaccounting,
        lo_item       TYPE REF TO if_purchase_order_item_mm,
        ls_item_data  TYPE mepoitem,
        lv_po_allowed TYPE abap_bool,
        lv_po_msg     TYPE string,
        lv_msg_v1     TYPE symsgv,
        lv_msg_v2     TYPE symsgv.

  CHECK im_account IS BOUND.
  ls_acct_data = im_account->get_data( ).
  CHECK ls_acct_data-ps_psp_pnr IS NOT INITIAL.

  lo_item = im_account->get_item( ).
  CHECK lo_item IS BOUND.
  ls_item_data = lo_item->get_data( ).
  CHECK ls_item_data-matnr IS NOT INITIAL.
  CHECK ls_item_data-loekz IS INITIAL.

  " Specifically check for Account Assignment Category Q (Project Purchase Stock) or P
  CHECK ls_item_data-knttp = 'Q' OR ls_item_data-knttp = 'P' OR ls_item_data-sobkz = 'Q'.

  " Validate against custom table ZWBS_MAT_ALLOW
  zcl_ps_wbs_mat_validate=>check_material_allowed(
    EXPORTING
      iv_wbs      = ls_acct_data-ps_psp_pnr
      iv_matnr    = ls_item_data-matnr
      iv_werks    = ls_item_data-werks
      iv_quantity = ls_acct_data-menge
    IMPORTING
      ev_allowed  = lv_po_allowed
      ev_message  = lv_po_msg
  ).

  IF lv_po_allowed = abap_false.
    lv_msg_v1 = lv_po_msg(50).
    IF strlen( lv_po_msg ) > 50.
      lv_msg_v2 = lv_po_msg+50.
    ELSE.
      CLEAR lv_msg_v2.
    ENDIF.
    cl_message_mm=>create(
      EXPORTING
        im_msgid = '00'
        im_msgno = '001'
        im_msgty = 'E'
        im_msgv1 = lv_msg_v1
        im_msgv2 = lv_msg_v2
    ).
  ENDIF.
ENDMETHOD.


* ======================================================================
* BLOCK 2: Method IF_EX_ME_PROCESS_PO_CUST~CHECK
* (Triggered on Check button or Save - strictly stops PO saving)
* Add this block before the ENDMETHOD of check:
* ======================================================================
    " ------------------------------------------------------------------
    " Custom Validation: WBS Material Allowance (ZWBS_MAT_ALLOW)
    " Enforce for Account Assignment Category Q (Project Purchase Stock)
    " ------------------------------------------------------------------
    DATA: lt_po_items   TYPE purchase_order_items,
          ls_po_item    TYPE purchase_order_item,
          lo_po_item    TYPE REF TO if_purchase_order_item_mm,
          ls_item_data  TYPE mepoitem,
          lt_accts      TYPE purchase_order_accountings,
          ls_acct       TYPE purchase_order_accounting,
          lo_acct       TYPE REF TO if_purchase_order_account_mm,
          ls_acct_data  TYPE mepoaccounting,
          lv_po_allowed TYPE abap_bool,
          lv_po_msg     TYPE string,
          lv_msg_v1     TYPE symsgv,
          lv_msg_v2     TYPE symsgv.

    IF im_header IS BOUND.
      lt_po_items = im_header->get_items( ).
      LOOP AT lt_po_items INTO ls_po_item.
        lo_po_item = ls_po_item-item.
        IF lo_po_item IS NOT BOUND.
          CONTINUE.
        ENDIF.

        ls_item_data = lo_po_item->get_data( ).
        IF ls_item_data-loekz IS NOT INITIAL OR ls_item_data-matnr IS INITIAL.
          CONTINUE.
        ENDIF.

        " Check Account Assignment Category Q (Project Stock) or P
        IF ls_item_data-knttp <> 'Q' AND ls_item_data-knttp <> 'P' AND ls_item_data-sobkz <> 'Q'.
          CONTINUE.
        ENDIF.

        lt_accts = lo_po_item->get_accountings( ).
        LOOP AT lt_accts INTO ls_acct.
          lo_acct = ls_acct-accounting.
          IF lo_acct IS NOT BOUND.
            CONTINUE.
          ENDIF.

          ls_acct_data = lo_acct->get_data( ).

          IF ls_acct_data-ps_psp_pnr IS NOT INITIAL.
            zcl_ps_wbs_mat_validate=>check_material_allowed(
              EXPORTING
                iv_wbs      = ls_acct_data-ps_psp_pnr
                iv_matnr    = ls_item_data-matnr
                iv_werks    = ls_item_data-werks
                iv_quantity = ls_acct_data-menge
              IMPORTING
                ev_allowed  = lv_po_allowed
                ev_message  = lv_po_msg
            ).

            IF lv_po_allowed = abap_false.
              ch_failed = abap_true.
              lv_msg_v1 = lv_po_msg(50).
              IF strlen( lv_po_msg ) > 50.
                lv_msg_v2 = lv_po_msg+50.
              ELSE.
                CLEAR lv_msg_v2.
              ENDIF.
              cl_message_mm=>create(
                EXPORTING
                  im_msgid = '00'
                  im_msgno = '001'
                  im_msgty = 'E'
                  im_msgv1 = lv_msg_v1
                  im_msgv2 = lv_msg_v2
              ).
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
