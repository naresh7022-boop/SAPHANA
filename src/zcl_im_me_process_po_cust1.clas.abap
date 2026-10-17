class ZCL_IM_ME_PROCESS_PO_CUST1 definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_ME_PROCESS_PO_CUST .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_ME_PROCESS_PO_CUST1 IMPLEMENTATION.


  METHOD if_ex_me_process_po_cust~check.

    IF sy-tcode = 'ME21N'   AND sy-ucomm <> 'ENT2' .

      DATA : lt_head   TYPE mepoheader,
             ls_head   TYPE TABLE OF mepoheader,
*           LV_ZTERM TYPE EKKO-ZTERM.
             wa_zpterm TYPE zpterm,
             gt_zpterm TYPE TABLE OF zpterm,
             lt_field  TYPE STANDARD TABLE OF slis_fieldcat_alv,
             ls_field  TYPE slis_fieldcat_alv.


      CALL METHOD im_header->get_data
        RECEIVING
          re_data = lt_head.
      BREAK mjena .

      IF lt_head IS NOT INITIAL .
        IF lt_head-lifnr IS NOT INITIAL AND lt_head-zterm IS NOT INITIAL.
*        IF LT_HEAD-LIFNR IS NOT INITIAL  ."
*        if LT_HEAD-ZTERM IS NOT INITIAL  AND LT_HEAD-EKORG  IS NOT  INITIAL .
          SELECT * FROM zpterm INTO TABLE gt_zpterm WHERE lifnr = lt_head-lifnr and ekorg = lt_head-ekorg . "ekorg added on 26.04.2024

          SELECT SINGLE * FROM zpterm INTO wa_zpterm WHERE lifnr = lt_head-lifnr AND ekorg = lt_head-ekorg AND ( zterm = lt_head-zterm ) .
          IF  sy-subrc = 4  .
            ls_field-col_pos = 1.
            ls_field-fieldname = 'ZTERM'.
            ls_field-seltext_m = 'Payterms'.
            APPEND ls_field TO lt_field.
            CLEAR ls_field.

            ls_field-col_pos = 2.
            ls_field-fieldname = 'TEXT1'.
            ls_field-seltext_l = 'Description'.
            ls_field-ddic_outputlen   = '50' .
            APPEND ls_field TO lt_field.
            CLEAR ls_field.
            SORT gt_zpterm BY zterm .
*           BREAK mjena .
            CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
              EXPORTING
                i_title               = 'Available Payment Terms'
                i_allow_no_selection  = 'X'
                i_screen_start_column = 10
                i_screen_start_line   = 5
                i_screen_end_column   = 100
                i_screen_end_line     = 10
                i_tabname             = 'GT_ZPTERM'
                it_fieldcat           = lt_field
                i_callback_program    = sy-cprog
              TABLES
                t_outtab              = gt_zpterm
              EXCEPTIONS
                program_error         = 1
                OTHERS                = 2.
            IF sy-subrc <> 0.
* Implement suitable error handling here
            ENDIF.
            DATA(lv_msg) = lt_head-zterm && ':Payment Term Is Invalid'.
            MESSAGE lv_msg TYPE 'E'.

          ENDIF .
        ENDIF.
      ENDIF.
    ENDIF .

    IF sy-tcode = 'ME22N' AND sy-ucomm <> 'ENT2' .

*      BREAK-POINT .
      CALL METHOD im_header->get_data
        RECEIVING
          re_data = lt_head.
      IF lt_head IS NOT INITIAL .

        SELECT *
        FROM zpterm INTO TABLE gt_zpterm WHERE lifnr = lt_head-lifnr and ekorg = lt_head-ekorg.  "ekorg added on 26.04.2024
        SELECT SINGLE * FROM zpterm INTO wa_zpterm WHERE lifnr = lt_head-lifnr AND ekorg = lt_head-ekorg AND ( zterm = lt_head-zterm ) .

        IF sy-subrc = 4 .


          ls_field-col_pos = 1.
          ls_field-fieldname = 'ZTERM'.
          ls_field-seltext_m = 'Payterms'.
          APPEND ls_field TO lt_field.
          CLEAR ls_field.

          ls_field-col_pos = 2.
          ls_field-fieldname = 'TEXT1'.
          ls_field-seltext_l = 'Description'.
          ls_field-ddic_outputlen   = '50' .
          APPEND ls_field TO lt_field.
          CLEAR ls_field.
          SORT gt_zpterm BY zterm .
          CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
            EXPORTING
              i_title               = 'Available Payment Terms'
              i_allow_no_selection  = 'X'
              i_screen_start_column = 10
              i_screen_start_line   = 5
              i_screen_end_column   = 100
              i_screen_end_line     = 10
              i_tabname             = 'GT_ZPTERM'
              it_fieldcat           = lt_field
              i_callback_program    = sy-cprog
            TABLES
              t_outtab              = gt_zpterm
            EXCEPTIONS
              program_error         = 1
              OTHERS                = 2.
          IF sy-subrc <> 0.
* Implement suitable error handling here
          ENDIF.
*          MESSAGE 'This Payment Term Is Invalid' TYPE 'E'.
          DATA(lv_msg1) = lt_head-zterm && ':Payment Term Is Invalid'.
          MESSAGE lv_msg1 TYPE 'E'.
*        MESSAGE 'This Payment Term Is Invalid' TYPE 'E' DISPLAY LIKE 'I'.
*      ENDIF.
*    ENDIF.
*          CALL METHOD IM_HEADER->SET_DATA
*            EXPORTING
*              IM_DATA = LT_HEAD.
        ENDIF .
      ENDIF.
    ENDIF.

    " ------------------------------------------------------------------
    " Custom Validation: WBS Material Allowance (ZWBS_MAT_ALLOW)
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

        " Specifically validate Account Assignment Category Q (Project Stock) or P
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
  ENDMETHOD.


  method IF_EX_ME_PROCESS_PO_CUST~CLOSE.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_HEADER.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_HEADER_REFKEYS.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_ITEM.
     DATA: l_changeable          TYPE mmpur_bool.
  FIELD-SYMBOLS:<fs_f> LIKE LINE OF ch_fieldselection.

  l_changeable = im_header->is_changeable( ).

  READ TABLE ch_fieldselection ASSIGNING <fs_f> WITH TABLE KEY metafield = mmmfd_cust_08.

  IF sy-subrc = 0.
    IF l_changeable = 'X'.
      <fs_f>-fieldstatus = '.'.
    ELSE.
      <fs_f>-fieldstatus = '*'.
    ENDIF.
  ENDIF.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_ITEM_REFKEYS.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~INITIALIZE.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~OPEN.
  endmethod.


  METHOD if_ex_me_process_po_cust~post.


  ENDMETHOD.


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

    " Specifically validate Account Assignment Category Q (Project Stock) or P
    CHECK ls_item_data-knttp = 'Q' OR ls_item_data-knttp = 'P' OR ls_item_data-sobkz = 'Q'.

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


  METHOD if_ex_me_process_po_cust~process_header.

    DATA : lt_head   TYPE mepoheader,
           ls_head   TYPE TABLE OF mepoheader,
*           LV_ZTERM TYPE EKKO-ZTERM.
           wa_zpterm TYPE zpterm,
           gt_zpterm TYPE TABLE OF zpterm,
           lt_field  TYPE STANDARD TABLE OF slis_fieldcat_alv,
           ls_field  TYPE slis_fieldcat_alv.

    CALL METHOD im_header->get_data
      RECEIVING
        re_data = lt_head.

    CHECK 1 = 2.
    IF sy-tcode = 'ME21N'   AND sy-ucomm <> 'ENT2' .


      CALL METHOD im_header->get_data
        RECEIVING
          re_data = lt_head.
*    break mjena .

      IF lt_head IS NOT INITIAL .
        IF lt_head-lifnr IS NOT INITIAL AND lt_head-zterm IS NOT INITIAL.
*        IF LT_HEAD-LIFNR IS NOT INITIAL  ."
*        if LT_HEAD-ZTERM IS NOT INITIAL  AND LT_HEAD-EKORG  IS NOT  INITIAL .
          SELECT * FROM zpterm INTO TABLE gt_zpterm WHERE lifnr = lt_head-lifnr .

          SELECT SINGLE * FROM zpterm INTO wa_zpterm WHERE lifnr = lt_head-lifnr AND ekorg = lt_head-ekorg AND ( zterm = lt_head-zterm ) .
          IF  sy-subrc = 4  .
            ls_field-col_pos = 1.
            ls_field-fieldname = 'ZTERM'.
            ls_field-seltext_m = 'Payterms'.
            APPEND ls_field TO lt_field.
            CLEAR ls_field.

            ls_field-col_pos = 2.
            ls_field-fieldname = 'TEXT1'.
            ls_field-seltext_l = 'Description'.
            ls_field-ddic_outputlen   = '50' .
            APPEND ls_field TO lt_field.
            CLEAR ls_field.
            SORT gt_zpterm BY zterm .
*           BREAK mjena .
            CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
              EXPORTING
                i_title               = 'Available Payment Terms'
                i_allow_no_selection  = 'X'
                i_screen_start_column = 10
                i_screen_start_line   = 5
                i_screen_end_column   = 100
                i_screen_end_line     = 10
                i_tabname             = 'GT_ZPTERM'
                it_fieldcat           = lt_field
                i_callback_program    = sy-cprog
              TABLES
                t_outtab              = gt_zpterm
              EXCEPTIONS
                program_error         = 1
                OTHERS                = 2.
            IF sy-subrc <> 0.
* Implement suitable error handling here
            ENDIF.
            DATA(lv_msg) = lt_head-zterm && ':Payment Term Is Invalid'.
            MESSAGE lv_msg TYPE 'E'.
          ENDIF .
        ENDIF.
      ENDIF.
    ENDIF .

    IF sy-tcode = 'ME22N' AND sy-ucomm <> 'ENT2' .

*      BREAK-POINT .
      CALL METHOD im_header->get_data
        RECEIVING
          re_data = lt_head.
      IF lt_head IS NOT INITIAL .

        SELECT *
        FROM zpterm INTO TABLE gt_zpterm WHERE lifnr = lt_head-lifnr .
        SELECT SINGLE * FROM zpterm INTO wa_zpterm WHERE lifnr = lt_head-lifnr AND ekorg = lt_head-ekorg AND ( zterm = lt_head-zterm ) .

        IF sy-subrc = 4 .


          ls_field-col_pos = 1.
          ls_field-fieldname = 'ZTERM'.
          ls_field-seltext_m = 'Payterms'.
          APPEND ls_field TO lt_field.
          CLEAR ls_field.

          ls_field-col_pos = 2.
          ls_field-fieldname = 'TEXT1'.
          ls_field-seltext_l = 'Description'.
          ls_field-ddic_outputlen   = '50' .
          APPEND ls_field TO lt_field.
          CLEAR ls_field.
          SORT gt_zpterm BY zterm .
*         BREAK mjena .
          CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
            EXPORTING
              i_title               = 'Available Payment Terms'
              i_allow_no_selection  = 'X'
              i_screen_start_column = 10
              i_screen_start_line   = 5
              i_screen_end_column   = 100
              i_screen_end_line     = 10
              i_tabname             = 'GT_ZPTERM'
              it_fieldcat           = lt_field
              i_callback_program    = sy-cprog
            TABLES
              t_outtab              = gt_zpterm
            EXCEPTIONS
              program_error         = 1
              OTHERS                = 2.
          IF sy-subrc <> 0.
* Implement suitable error handling here
          ENDIF.
*          MESSAGE 'This Payment Term Is Invalid' TYPE 'E'.
          DATA(lv_msg1) = lt_head-zterm && ':Payment Term Is Invalid'.
          MESSAGE lv_msg1 TYPE 'E'.
*        MESSAGE 'This Payment Term Is Invalid' TYPE 'E' DISPLAY LIKE 'I'.
*      ENDIF.
*    ENDIF.
*          CALL METHOD IM_HEADER->SET_DATA
*            EXPORTING
*              IM_DATA = LT_HEAD.
        ENDIF .
      ENDIF.
    ENDIF.
*   ENDIF .
  ENDMETHOD.


  METHOD if_ex_me_process_po_cust~process_item.

    DATA: lwa_mepoitem TYPE mepoitem.
    DATA ls_ekpo TYPE uekpo.
    DATA ls_eban TYPE eban.
    DATA lt_eban TYPE TABLE OF eban.
    DATA: gt_conn    TYPE TABLE OF toav0,
          gt_conn_av TYPE TABLE OF toav0,
          gs_conn    TYPE toav0,
          gs_toa01   TYPE toa01,
          lw_banfn   TYPE banfn.
    CALL METHOD im_item->get_data
      RECEIVING
        re_data = lwa_mepoitem.
    SELECT SINGLE zzpacking FROM zmm_t_006
      INTO @lwa_mepoitem-zzpacking
      WHERE ebeln = @lwa_mepoitem-ebeln
      AND ebelp = @lwa_mepoitem-ebelp.
    IF sy-subrc EQ 0 AND lwa_mepoitem-zzpacking IS NOT INITIAL.
      CALL METHOD im_item->set_data
        EXPORTING
          im_data = lwa_mepoitem.

    ENDIF.
  ENDMETHOD.


  method IF_EX_ME_PROCESS_PO_CUST~PROCESS_SCHEDULE.
  endmethod.
ENDCLASS.