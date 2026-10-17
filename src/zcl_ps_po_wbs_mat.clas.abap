CLASS zcl_ps_po_wbs_mat DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_ex_me_process_po_cust .
    CLASS-DATA: gv_check_called TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS emit_error
      IMPORTING
        !io_obj TYPE REF TO if_message_obj_mm
        !iv_msg TYPE string.
ENDCLASS.

CLASS zcl_ps_po_wbs_mat IMPLEMENTATION.

  METHOD emit_error.
    DATA: lv_msg_v1 TYPE symsgv,
          lv_msg_v2 TYPE symsgv,
          lv_msg_v3 TYPE symsgv,
          lv_msg_v4 TYPE symsgv.

    IF strlen( iv_msg ) <= 50.
      lv_msg_v1 = iv_msg.
    ELSEIF strlen( iv_msg ) <= 100.
      lv_msg_v1 = iv_msg(50).
      lv_msg_v2 = iv_msg+50.
    ELSEIF strlen( iv_msg ) <= 150.
      lv_msg_v1 = iv_msg(50).
      lv_msg_v2 = iv_msg+50(50).
      lv_msg_v3 = iv_msg+100.
    ELSE.
      lv_msg_v1 = iv_msg(50).
      lv_msg_v2 = iv_msg+50(50).
      lv_msg_v3 = iv_msg+100(50).
      lv_msg_v4 = iv_msg+150.
    ENDIF.

    TRY.
        cl_message_mm=>create(
          EXPORTING
            im_business_obj  = io_obj
            im_msgid         = '00'
            im_msgno         = '001'
            im_msgty         = 'E'
            im_msgv1         = lv_msg_v1
            im_msgv2         = lv_msg_v2
            im_msgv3         = lv_msg_v3
            im_msgv4         = lv_msg_v4
            im_force_collect = 'X'
        ).
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD if_ex_me_process_po_cust~process_account.
    DATA: ls_acct_data    TYPE mepoaccounting,
          lo_item         TYPE REF TO if_purchase_order_item_mm,
          ls_item_data    TYPE mepoitem,
          lv_wbs          TYPE string,
          lv_acl_allowed  TYPE abap_bool,
          lv_acl_msg      TYPE string,
          lv_plant_allowed TYPE abap_bool,
          lv_plant_msg    TYPE string,
          lv_po_allowed   TYPE abap_bool,
          lv_po_msg       TYPE string.

    gv_check_called = abap_true.
    CHECK im_account IS BOUND.

    lo_item = im_account->get_item( ).
    CHECK lo_item IS BOUND.
    ls_item_data = lo_item->get_data( ).
    CHECK ls_item_data-loekz IS INITIAL.

    ls_acct_data = im_account->get_data( ).
    CLEAR lv_wbs.
    IF ls_acct_data-ps_psp_pnr IS NOT INITIAL.
      lv_wbs = ls_acct_data-ps_psp_pnr.
    ELSEIF ls_acct_data-extwbselement IS NOT INITIAL.
      lv_wbs = ls_acct_data-extwbselement.
    ELSEIF ls_acct_data-psp_pnr IS NOT INITIAL.
      lv_wbs = ls_acct_data-psp_pnr.
    ENDIF.
    CHECK lv_wbs IS NOT INITIAL.

    " 1. ACL Check: User must have access for WBS in CJ20N ACL Tab
    zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
      EXPORTING
        iv_wbs     = lv_wbs
      IMPORTING
        ev_allowed = lv_acl_allowed
        ev_message = lv_acl_msg
    ).

    IF lv_acl_allowed = abap_false.
      emit_error( io_obj = lo_item iv_msg = lv_acl_msg ).
      im_account->invalidate( ).
      lo_item->invalidate( ).
      RETURN.
    ENDIF.

    " 2. Plant Check: Transaction Plant must match WBS Plant mapped in CJ20N
    IF ls_item_data-werks IS NOT INITIAL.
      zcl_ps_wbs_mat_validate=>check_wbs_plant(
        EXPORTING
          iv_wbs     = lv_wbs
          iv_werks   = ls_item_data-werks
        IMPORTING
          ev_allowed = lv_plant_allowed
          ev_message = lv_plant_msg
      ).

      IF lv_plant_allowed = abap_false.
        emit_error( io_obj = lo_item iv_msg = lv_plant_msg ).
        im_account->invalidate( ).
        lo_item->invalidate( ).
        RETURN.
      ENDIF.
    ENDIF.

    " 3. Material Allowed Check (Validation applies to Account Assignment Q/P or SOBKZ=Q for R&D Project Profile)
    CHECK ls_item_data-matnr IS NOT INITIAL.
    CHECK ls_item_data-knttp = 'Q' OR ls_item_data-knttp = 'P' OR ls_item_data-sobkz = 'Q'.

    zcl_ps_wbs_mat_validate=>check_material_allowed(
      EXPORTING
        iv_wbs      = lv_wbs
        iv_matnr    = ls_item_data-matnr
        iv_werks    = ls_item_data-werks
        iv_quantity = ls_acct_data-menge
      IMPORTING
        ev_allowed  = lv_po_allowed
        ev_message  = lv_po_msg
    ).

    IF lv_po_allowed = abap_false.
      emit_error( io_obj = lo_item iv_msg = lv_po_msg ).
      im_account->invalidate( ).
      lo_item->invalidate( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_ex_me_process_po_cust~process_item.
    DATA: ls_item_data     TYPE mepoitem,
          lt_accts         TYPE purchase_order_accountings,
          ls_acct          TYPE purchase_order_accounting,
          lo_acct          TYPE REF TO if_purchase_order_account_mm,
          ls_acct_data     TYPE mepoaccounting,
          lv_wbs           TYPE string,
          lv_acl_allowed   TYPE abap_bool,
          lv_acl_msg       TYPE string,
          lv_plant_allowed TYPE abap_bool,
          lv_plant_msg     TYPE string,
          lv_po_allowed    TYPE abap_bool,
          lv_po_msg        TYPE string.

    gv_check_called = abap_true.
    CHECK im_item IS BOUND.
    ls_item_data = im_item->get_data( ).
    CHECK ls_item_data-loekz IS INITIAL.

    lt_accts = im_item->get_accountings( ).
    IF lt_accts IS INITIAL.
      CLEAR lv_wbs.
      IF ls_item_data-ps_psp_pnr IS NOT INITIAL.
        lv_wbs = ls_item_data-ps_psp_pnr.
      ELSEIF ls_item_data-wbs_element IS NOT INITIAL.
        lv_wbs = ls_item_data-wbs_element.
      ENDIF.

      IF lv_wbs IS NOT INITIAL.
        " 1. ACL Check
        zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
          EXPORTING
            iv_wbs     = lv_wbs
          IMPORTING
            ev_allowed = lv_acl_allowed
            ev_message = lv_acl_msg
        ).

        IF lv_acl_allowed = abap_false.
          emit_error( io_obj = im_item iv_msg = lv_acl_msg ).
          im_item->invalidate( ).
          RETURN.
        ENDIF.

        " 2. Plant Check
        IF ls_item_data-werks IS NOT INITIAL.
          zcl_ps_wbs_mat_validate=>check_wbs_plant(
            EXPORTING
              iv_wbs     = lv_wbs
              iv_werks   = ls_item_data-werks
            IMPORTING
              ev_allowed = lv_plant_allowed
              ev_message = lv_plant_msg
          ).

          IF lv_plant_allowed = abap_false.
            emit_error( io_obj = im_item iv_msg = lv_plant_msg ).
            im_item->invalidate( ).
            RETURN.
          ENDIF.
        ENDIF.

        " 3. Material Allowed Check
        IF ls_item_data-matnr IS NOT INITIAL AND
           ( ls_item_data-knttp = 'Q' OR ls_item_data-knttp = 'P' OR ls_item_data-sobkz = 'Q' ).
          zcl_ps_wbs_mat_validate=>check_material_allowed(
            EXPORTING
              iv_wbs      = lv_wbs
              iv_matnr    = ls_item_data-matnr
              iv_werks    = ls_item_data-werks
              iv_quantity = ls_item_data-menge
            IMPORTING
              ev_allowed  = lv_po_allowed
              ev_message  = lv_po_msg
          ).

          IF lv_po_allowed = abap_false.
            emit_error( io_obj = im_item iv_msg = lv_po_msg ).
            im_item->invalidate( ).
          ENDIF.
        ENDIF.
      ENDIF.
    ELSE.
      LOOP AT lt_accts INTO ls_acct.
        lo_acct = ls_acct-accounting.
        IF lo_acct IS NOT BOUND.
          CONTINUE.
        ENDIF.

        ls_acct_data = lo_acct->get_data( ).
        CLEAR lv_wbs.
        IF ls_acct_data-ps_psp_pnr IS NOT INITIAL.
          lv_wbs = ls_acct_data-ps_psp_pnr.
        ELSEIF ls_acct_data-extwbselement IS NOT INITIAL.
          lv_wbs = ls_acct_data-extwbselement.
        ELSEIF ls_acct_data-psp_pnr IS NOT INITIAL.
          lv_wbs = ls_acct_data-psp_pnr.
        ENDIF.
        IF lv_wbs IS INITIAL.
          CONTINUE.
        ENDIF.

        " 1. ACL Check
        zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
          EXPORTING
            iv_wbs     = lv_wbs
          IMPORTING
            ev_allowed = lv_acl_allowed
            ev_message = lv_acl_msg
        ).

        IF lv_acl_allowed = abap_false.
          emit_error( io_obj = im_item iv_msg = lv_acl_msg ).
          lo_acct->invalidate( ).
          im_item->invalidate( ).
          CONTINUE.
        ENDIF.

        " 2. Plant Check
        IF ls_item_data-werks IS NOT INITIAL.
          zcl_ps_wbs_mat_validate=>check_wbs_plant(
            EXPORTING
              iv_wbs     = lv_wbs
              iv_werks   = ls_item_data-werks
            IMPORTING
              ev_allowed = lv_plant_allowed
              ev_message = lv_plant_msg
          ).

          IF lv_plant_allowed = abap_false.
            emit_error( io_obj = im_item iv_msg = lv_plant_msg ).
            lo_acct->invalidate( ).
            im_item->invalidate( ).
            CONTINUE.
          ENDIF.
        ENDIF.

        " 3. Material Allowed Check
        IF ls_item_data-matnr IS NOT INITIAL AND
           ( ls_item_data-knttp = 'Q' OR ls_item_data-knttp = 'P' OR ls_item_data-sobkz = 'Q' ).
          zcl_ps_wbs_mat_validate=>check_material_allowed(
            EXPORTING
              iv_wbs      = lv_wbs
              iv_matnr    = ls_item_data-matnr
              iv_werks    = ls_item_data-werks
              iv_quantity = ls_acct_data-menge
            IMPORTING
              ev_allowed  = lv_po_allowed
              ev_message  = lv_po_msg
          ).

          IF lv_po_allowed = abap_false.
            emit_error( io_obj = im_item iv_msg = lv_po_msg ).
            lo_acct->invalidate( ).
            im_item->invalidate( ).
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD if_ex_me_process_po_cust~check.
    DATA: lt_po_items      TYPE purchase_order_items,
          ls_po_item       TYPE purchase_order_item,
          lo_po_item       TYPE REF TO if_purchase_order_item_mm,
          ls_item_data     TYPE mepoitem,
          lt_accts         TYPE purchase_order_accountings,
          ls_acct          TYPE purchase_order_accounting,
          lo_acct          TYPE REF TO if_purchase_order_account_mm,
          ls_acct_data     TYPE mepoaccounting,
          lv_wbs           TYPE string,
          lv_acl_allowed   TYPE abap_bool,
          lv_acl_msg       TYPE string,
          lv_plant_allowed TYPE abap_bool,
          lv_plant_msg     TYPE string,
          lv_po_allowed    TYPE abap_bool,
          lv_po_msg        TYPE string,
          lo_msg_obj       TYPE REF TO if_message_obj_mm,
          lo_handler       TYPE REF TO cl_message_handler_mm,
          lv_sev           TYPE i.

    gv_check_called = abap_true.
    IF im_header IS NOT BOUND.
      RETURN.
    ENDIF.

    lt_po_items = im_header->get_items( ).
    LOOP AT lt_po_items INTO ls_po_item.
      lo_po_item = ls_po_item-item.
      IF lo_po_item IS NOT BOUND.
        CONTINUE.
      ENDIF.

      ls_item_data = lo_po_item->get_data( ).
      IF ls_item_data-loekz IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      lt_accts = lo_po_item->get_accountings( ).
      IF lt_accts IS INITIAL.
        CLEAR lv_wbs.
        IF ls_item_data-ps_psp_pnr IS NOT INITIAL.
          lv_wbs = ls_item_data-ps_psp_pnr.
        ELSEIF ls_item_data-wbs_element IS NOT INITIAL.
          lv_wbs = ls_item_data-wbs_element.
        ENDIF.

        IF lv_wbs IS NOT INITIAL.
          " 1. ACL Check
          zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
            EXPORTING
              iv_wbs     = lv_wbs
            IMPORTING
              ev_allowed = lv_acl_allowed
              ev_message = lv_acl_msg
          ).

          IF lv_acl_allowed = abap_false.
            ch_failed = abap_true.
            emit_error( io_obj = lo_po_item iv_msg = lv_acl_msg ).
            lo_po_item->invalidate( ).
            CONTINUE.
          ENDIF.

          " 2. Plant Check
          IF ls_item_data-werks IS NOT INITIAL.
            zcl_ps_wbs_mat_validate=>check_wbs_plant(
              EXPORTING
                iv_wbs     = lv_wbs
                iv_werks   = ls_item_data-werks
              IMPORTING
                ev_allowed = lv_plant_allowed
                ev_message = lv_plant_msg
            ).

            IF lv_plant_allowed = abap_false.
              ch_failed = abap_true.
              emit_error( io_obj = lo_po_item iv_msg = lv_plant_msg ).
              lo_po_item->invalidate( ).
              CONTINUE.
            ENDIF.
          ENDIF.

          " 3. Material Check
          IF ls_item_data-matnr IS NOT INITIAL AND
             ( ls_item_data-knttp = 'Q' OR ls_item_data-knttp = 'P' OR ls_item_data-sobkz = 'Q' ).
            zcl_ps_wbs_mat_validate=>check_material_allowed(
              EXPORTING
                iv_wbs      = lv_wbs
                iv_matnr    = ls_item_data-matnr
                iv_werks    = ls_item_data-werks
                iv_quantity = ls_item_data-menge
              IMPORTING
                ev_allowed  = lv_po_allowed
                ev_message  = lv_po_msg
            ).

            IF lv_po_allowed = abap_false.
              ch_failed = abap_true.
              emit_error( io_obj = lo_po_item iv_msg = lv_po_msg ).
              lo_po_item->invalidate( ).
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
        LOOP AT lt_accts INTO ls_acct.
          lo_acct = ls_acct-accounting.
          IF lo_acct IS NOT BOUND.
            CONTINUE.
          ENDIF.

          ls_acct_data = lo_acct->get_data( ).
          CLEAR lv_wbs.
          IF ls_acct_data-ps_psp_pnr IS NOT INITIAL.
            lv_wbs = ls_acct_data-ps_psp_pnr.
          ELSEIF ls_acct_data-extwbselement IS NOT INITIAL.
            lv_wbs = ls_acct_data-extwbselement.
          ELSEIF ls_acct_data-psp_pnr IS NOT INITIAL.
            lv_wbs = ls_acct_data-psp_pnr.
          ENDIF.
          IF lv_wbs IS INITIAL.
            CONTINUE.
          ENDIF.

          " 1. ACL Check
          zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
            EXPORTING
              iv_wbs     = lv_wbs
            IMPORTING
              ev_allowed = lv_acl_allowed
              ev_message = lv_acl_msg
          ).

          IF lv_acl_allowed = abap_false.
            ch_failed = abap_true.
            emit_error( io_obj = lo_po_item iv_msg = lv_acl_msg ).
            lo_acct->invalidate( ).
            lo_po_item->invalidate( ).
            CONTINUE.
          ENDIF.

          " 2. Plant Check
          IF ls_item_data-werks IS NOT INITIAL.
            zcl_ps_wbs_mat_validate=>check_wbs_plant(
              EXPORTING
                iv_wbs     = lv_wbs
                iv_werks   = ls_item_data-werks
              IMPORTING
                ev_allowed = lv_plant_allowed
                ev_message = lv_plant_msg
            ).

            IF lv_plant_allowed = abap_false.
              ch_failed = abap_true.
              emit_error( io_obj = lo_po_item iv_msg = lv_plant_msg ).
              lo_acct->invalidate( ).
              lo_po_item->invalidate( ).
              CONTINUE.
            ENDIF.
          ENDIF.

          " 3. Material Check
          IF ls_item_data-matnr IS NOT INITIAL AND
             ( ls_item_data-knttp = 'Q' OR ls_item_data-knttp = 'P' OR ls_item_data-sobkz = 'Q' ).
            zcl_ps_wbs_mat_validate=>check_material_allowed(
              EXPORTING
                iv_wbs      = lv_wbs
                iv_matnr    = ls_item_data-matnr
                iv_werks    = ls_item_data-werks
                iv_quantity = ls_acct_data-menge
              IMPORTING
                ev_allowed  = lv_po_allowed
                ev_message  = lv_po_msg
            ).

            IF lv_po_allowed = abap_false.
              ch_failed = abap_true.
              emit_error( io_obj = lo_po_item iv_msg = lv_po_msg ).
              lo_acct->invalidate( ).
              lo_po_item->invalidate( ).
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    " In addition: If ANY error was registered in the message handler for this PO, block save!
    lo_msg_obj ?= im_header.
    cl_message_handler_mm=>get_handler( IMPORTING ex_handler = lo_handler ).
    IF lo_handler IS BOUND AND lo_msg_obj IS BOUND.
      lv_sev = lo_handler->get_severity_bo( im_business_obj = lo_msg_obj
                                            im_include_child_objects = 'X' ).
      IF lv_sev >= 13.
        ch_failed = abap_true.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD if_ex_me_process_po_cust~close.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~fieldselection_header.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~fieldselection_header_refkeys.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~fieldselection_item.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~fieldselection_item_refkeys.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~initialize.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~open.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~post.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~process_header.
  ENDMETHOD.
  METHOD if_ex_me_process_po_cust~process_schedule.
  ENDMETHOD.

ENDCLASS.