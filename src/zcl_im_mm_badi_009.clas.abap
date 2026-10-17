CLASS zcl_im_mm_badi_009 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_ex_me_process_req_cust .

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS emit_error
      IMPORTING
        !io_obj TYPE REF TO if_message_obj_mm
        !iv_msg TYPE string.
ENDCLASS.

CLASS zcl_im_mm_badi_009 IMPLEMENTATION.

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

  METHOD if_ex_me_process_req_cust~check.
    DATA: lt_items         TYPE mmpur_requisition_items,
          ls_item          TYPE mmpur_requisition_item,
          lo_item          TYPE REF TO if_purchase_requisition_item,
          ls_item_data     TYPE mereq_item,
          lt_accts         TYPE mmpur_accounting_list,
          ls_acct          TYPE mmpur_accounting_type,
          ls_exkn          TYPE exkn,
          lv_wbs           TYPE ps_psp_pnr,
          lv_acl_ok        TYPE abap_bool,
          lv_acl_msg       TYPE string,
          lv_plant_allowed TYPE abap_bool,
          lv_plant_msg     TYPE string,
          lv_mat_ok        TYPE abap_bool,
          lv_mat_msg       TYPE string,
          lo_msg_obj       TYPE REF TO if_message_obj_mm,
          lo_handler       TYPE REF TO cl_message_handler_mm,
          lv_sev           TYPE i.

    IF im_header IS NOT BOUND.
      RETURN.
    ENDIF.

    lt_items = im_header->get_items( ).
    LOOP AT lt_items INTO ls_item.
      lo_item = ls_item-item.
      IF lo_item IS NOT BOUND.
        CONTINUE.
      ENDIF.

      ls_item_data = lo_item->get_data( ).
      IF ls_item_data-loekz IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      lt_accts = lo_item->if_acct_container_mm~get_items( ).
      IF lt_accts IS INITIAL.
        CLEAR lv_wbs.
        lo_item->if_acct_container_mm~get_data( IMPORTING ex_ps_psp_pnr = lv_wbs ).
        IF lv_wbs IS NOT INITIAL.
          " 1. ACL Check
          zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
            EXPORTING
              iv_wbs     = lv_wbs
            IMPORTING
              ev_allowed = lv_acl_ok
              ev_message = lv_acl_msg
          ).
          IF lv_acl_ok = abap_false.
            ch_failed = abap_true.
            emit_error( io_obj = lo_item iv_msg = lv_acl_msg ).
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
              emit_error( io_obj = lo_item iv_msg = lv_plant_msg ).
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
                ev_allowed  = lv_mat_ok
                ev_message  = lv_mat_msg
            ).
            IF lv_mat_ok = abap_false.
              ch_failed = abap_true.
              emit_error( io_obj = lo_item iv_msg = lv_mat_msg ).
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
        LOOP AT lt_accts INTO ls_acct.
          IF ls_acct-model IS NOT BOUND.
            CONTINUE.
          ENDIF.
          ls_exkn = ls_acct-model->get_exkn( ).
          IF ls_exkn-ps_psp_pnr IS INITIAL.
            CONTINUE.
          ENDIF.
          lv_wbs = ls_exkn-ps_psp_pnr.

          " 1. ACL Check
          zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
            EXPORTING
              iv_wbs     = lv_wbs
            IMPORTING
              ev_allowed = lv_acl_ok
              ev_message = lv_acl_msg
          ).
          IF lv_acl_ok = abap_false.
            ch_failed = abap_true.
            emit_error( io_obj = lo_item iv_msg = lv_acl_msg ).
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
              emit_error( io_obj = lo_item iv_msg = lv_plant_msg ).
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
                iv_quantity = ls_exkn-menge
              IMPORTING
                ev_allowed  = lv_mat_ok
                ev_message  = lv_mat_msg
            ).
            IF lv_mat_ok = abap_false.
              ch_failed = abap_true.
              emit_error( io_obj = lo_item iv_msg = lv_mat_msg ).
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    " In addition: If ANY error was registered in the message handler for this PR, block save!
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

  METHOD if_ex_me_process_req_cust~close.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~fieldselection_header.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~fieldselection_header_refkeys.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~fieldselection_item.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~fieldselection_item_refkeys.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~initialize.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~open.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~post.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~process_account.
    DATA: ls_exkn          TYPE exkn,
          lv_wbs           TYPE ps_psp_pnr,
          lo_item          TYPE REF TO if_purchase_requisition_item,
          ls_item          TYPE mereq_item,
          lv_acl_ok        TYPE abap_bool,
          lv_acl_msg       TYPE string,
          lv_plant_allowed TYPE abap_bool,
          lv_plant_msg     TYPE string,
          lv_mat_ok        TYPE abap_bool,
          lv_mat_msg       TYPE string.

    " 1. Retrieve account assignment data
    CHECK im_account IS BOUND.
    ls_exkn = im_account->get_exkn( ).

    IF ls_exkn-ps_psp_pnr IS INITIAL.
      RETURN.
    ENDIF.
    lv_wbs = ls_exkn-ps_psp_pnr.

    IF im_account_ref IS BOUND.
      lo_item = im_account_ref->get_item( ).
    ENDIF.
    IF lo_item IS NOT BOUND AND im_account IS BOUND.
      TRY.
          lo_item ?= im_account.
        CATCH cx_root.
      ENDTRY.
    ENDIF.

    " 2. ACL Authorization Check for current user against CJ20N ACL Tab
    zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
      EXPORTING
        iv_wbs     = lv_wbs
      IMPORTING
        ev_allowed = lv_acl_ok
        ev_message = lv_acl_msg
    ).

    IF lv_acl_ok = abap_false.
      emit_error( io_obj = lo_item iv_msg = lv_acl_msg ).
      RETURN.
    ENDIF.

    " 3. Plant Validation: PR item plant must match WBS plant in CJ20N
    IF lo_item IS BOUND.
      ls_item = lo_item->get_data( ).

      IF ls_item-werks IS NOT INITIAL.
        zcl_ps_wbs_mat_validate=>check_wbs_plant(
          EXPORTING
            iv_wbs     = lv_wbs
            iv_werks   = ls_item-werks
          IMPORTING
            ev_allowed = lv_plant_allowed
            ev_message = lv_plant_msg
        ).

        IF lv_plant_allowed = abap_false.
          emit_error( io_obj = lo_item iv_msg = lv_plant_msg ).
          RETURN.
        ENDIF.
      ENDIF.

      " 4. WBS Material Validation against ZWBS_MAT_ALLOW (for R&D project profile)
      IF ls_item-matnr IS NOT INITIAL.
        IF ls_item-knttp = 'Q' OR ls_item-knttp = 'P' OR ls_item-sobkz = 'Q'.
          zcl_ps_wbs_mat_validate=>check_material_allowed(
            EXPORTING
              iv_wbs      = lv_wbs
              iv_matnr    = ls_item-matnr
              iv_werks    = ls_item-werks
              iv_quantity = ls_exkn-menge
            IMPORTING
              ev_allowed  = lv_mat_ok
              ev_message  = lv_mat_msg
          ).

          IF lv_mat_ok = abap_false.
            emit_error( io_obj = lo_item iv_msg = lv_mat_msg ).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~process_header.
  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~process_item.
*&Implemented : on 11-11-2025
*&Author      : Vinay Reddy
*&Functinal   : Andappa & Saddam
*&Reason      : Auto populate Purchase Organisation based on zmm_t_027 table.

    IF sy-tcode = 'ME51N'.
      DATA: ls_data  TYPE mereq_item.

      SELECT SINGLE ekorg
        FROM zmm_t_027
        WHERE zuser = @sy-uname INTO @DATA(lv_ekorg).
      IF sy-subrc = 0  AND lv_ekorg IS NOT INITIAL.

        ls_data = im_item->get_data( ).

        IF ls_data-ekorg IS INITIAL.
          ls_data-ekorg = lv_ekorg.
          im_item->set_data( ls_data ).
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.