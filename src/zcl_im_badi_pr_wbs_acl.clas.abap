CLASS zcl_im_badi_pr_wbs_acl DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_ex_me_process_req_cust .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_im_badi_pr_wbs_acl IMPLEMENTATION.

  METHOD if_ex_me_process_req_cust~process_account.
    DATA: ls_exkn    TYPE exkn,
          lv_objnr   TYPE prps-objnr,
          lv_posid   TYPE ps_posid,
          lo_item    TYPE REF TO if_purchase_requisition_item,
          ls_item    TYPE mereq_item,
          lv_allowed TYPE abap_bool,
          lv_msg     TYPE string,
          lv_msg1    TYPE symsgv,
          lv_msg2    TYPE symsgv.

    " 1. Retrieve account assignment data
    ls_exkn = im_account->get_exkn( ).

    IF ls_exkn-ps_psp_pnr IS INITIAL.
      RETURN.
    ENDIF.

    " 2. ACL Authorization Check for Edit access
    SELECT SINGLE objnr, posid
      FROM prps
      INTO (@lv_objnr, @lv_posid)
      WHERE pspnr = @ls_exkn-ps_psp_pnr.

    IF sy-subrc = 0.
      CALL FUNCTION 'CN_ACL_CHECK_AUTHORIZATION'
        EXPORTING
          i_objnr      = lv_objnr
          i_uname      = sy-uname
          i_activity   = '02' " 02 = Change/Edit
        EXCEPTIONS
          no_authority = 1
          OTHERS       = 2.

      IF sy-subrc <> 0.
        cl_message_mm=>create(
          EXPORTING
            im_msgid = 'ZMM_MESSAGES'
            im_msgno = '001'
            im_msgty = 'E'
            im_msgv1 = CONV #( lv_posid )
        ).
        RETURN.
      ENDIF.
    ENDIF.

    " 3. WBS Material Validation against ZWBS_MAT_ALLOW for Project Stock (KNTTP = 'Q' or 'P')
    IF im_account_ref IS BOUND.
      lo_item = im_account_ref->get_item( ).
      IF lo_item IS BOUND.
        ls_item = lo_item->get_data( ).
        IF ls_item-matnr IS NOT INITIAL.
          IF ls_item-knttp = 'Q' OR ls_item-knttp = 'P' OR ls_item-sobkz = 'Q'.
            zcl_ps_wbs_mat_validate=>check_material_allowed(
              EXPORTING
                iv_wbs      = ls_exkn-ps_psp_pnr
                iv_matnr    = ls_item-matnr
                iv_werks    = ls_item-werks
                iv_quantity = ls_exkn-menge
              IMPORTING
                ev_allowed  = lv_allowed
                ev_message  = lv_msg
            ).

            IF lv_allowed = abap_false.
              lv_msg1 = lv_msg(50).
              IF strlen( lv_msg ) > 50.
                lv_msg2 = lv_msg+50.
              ELSE.
                CLEAR lv_msg2.
              ENDIF.
              cl_message_mm=>create(
                EXPORTING
                  im_msgid = '00'
                  im_msgno = '001'
                  im_msgty = 'E'
                  im_msgv1 = lv_msg1
                  im_msgv2 = lv_msg2
              ).
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD if_ex_me_process_req_cust~check.
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
  METHOD if_ex_me_process_req_cust~process_header.
  ENDMETHOD.
  METHOD if_ex_me_process_req_cust~process_item.
  ENDMETHOD.

ENDCLASS.
