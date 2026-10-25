*&---------------------------------------------------------------------*
*& BAdI Implementation: ZCL_IM_MB_RES_AUTO_TR
*& BAdI Definition    : MB_RESERVATION_BADI
*& Description         : Auto-generate LE-WM Transfer Requirement (TR) on Reservation Save
*& Target System       : SAP S/4HANA / SAP ECC 6.0 EHP7+
*&---------------------------------------------------------------------*
CLASS zcl_im_mb_res_auto_tr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_mb_reservation_badi.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_wm_loc,
        werks TYPE werks_d,
        lgort TYPE lgort_d,
        lgnum TYPE lgnum,
      END OF ty_wm_loc.

    METHODS is_wm_managed
      IMPORTING
        iv_werks        TYPE werks_d
        iv_lgort        TYPE lgort_d
      RETURNING
        VALUE(rv_lgnum) TYPE lgnum.

    METHODS create_tr_for_resb
      IMPORTING
        is_rkpf TYPE rkpf
        it_resb TYPE resb_t.
ENDCLASS.

CLASS zcl_im_mb_res_auto_tr IMPLEMENTATION.

  METHOD if_ex_mb_reservation_badi~data_changed.
    " Called when reservation data is created/changed (e.g. via MB21, MB22, BAPIs)
    CHECK it_resb IS NOT INITIAL.

    " Filter items where deletion indicator is NOT set and final issue NOT set
    DATA(lt_active_resb) = VALUE resb_t(
      FOR ls_item IN it_resb
      WHERE ( xloek IS INITIAL AND kzear IS INITIAL )
      ( CORRESPONDING #( ls_item ) )
    ).

    CHECK lt_active_resb IS NOT INITIAL.

    " Trigger auto-TR creation for WM-managed storage locations
    me->create_tr_for_resb(
      is_rkpf = is_rkpf
      it_resb = lt_active_resb
    ).
  ENDMETHOD.

  METHOD if_ex_mb_reservation_badi~data_check.
    " Optional pre-save validation rules can be added here
  ENDMETHOD.

  METHOD is_wm_managed.
    CLEAR rv_lgnum.
    CHECK iv_werks IS NOT INITIAL AND iv_lgort IS NOT INITIAL.

    " Check mapping in table T320 (Assignment Plant/Storage Location to Warehouse Number)
    SELECT SINGLE lgnum
      FROM t320
      INTO @rv_lgnum
      WHERE werks = @iv_werks
        AND lgort = @iv_lgort.
    IF sy-subrc <> 0.
      " Fallback check in T001L
      SELECT SINGLE lgnum
        FROM t001l
        INTO @rv_lgnum
        WHERE werks = @iv_werks
          AND lgort = @iv_lgort.
    ENDIF.
  ENDMETHOD.

  METHOD create_tr_for_resb.
    DATA: lv_lgnum      TYPE lgnum,
          ls_tr_header  TYPE ltbk,
          lt_tr_items   TYPE TABLE OF ltbp,
          ls_tr_item    TYPE ltbp,
          lv_tbnum      TYPE tbnum,
          lv_item_num   TYPE posnr VALUE 0.

    " Loop over active reservation items and group by Warehouse Number
    LOOP AT it_resb ASSIGNING FIELD-SYMBOL(<ls_resb>).
      " Determine source or destination warehouse
      lv_lgnum = me->is_wm_managed(
        iv_werks = <ls_resb>-werks
        iv_lgort = <ls_resb>-lgort
      ).
      CHECK lv_lgnum IS NOT INITIAL.

      " Check if a Transfer Requirement already exists for this reservation item
      SELECT SINGLE tbnum
        FROM ltbp
        INTO @DATA(lv_existing_tbnum)
        WHERE rsnum = @<ls_resb>-rsnum
          AND rspos = @<ls_resb>-rspos
          AND elikz = @space.
      IF sy-subrc = 0 AND lv_existing_tbnum IS NOT INITIAL.
        " TR already exists and is open; do not duplicate
        CONTINUE.
      ENDIF.

      " Calculate open quantity to transfer
      DATA(lv_open_qty) = <ls_resb>-bdmng - <ls_resb>-enmng.
      CHECK lv_open_qty > 0.

      " Populate TR item
      lv_item_num = lv_item_num + 1.
      CLEAR ls_tr_item.
      ls_tr_item-posnr = lv_item_num.
      ls_tr_item-matnr = <ls_resb>-matnr.
      ls_tr_item-werks = <ls_resb>-werks.
      ls_tr_item-lgort = <ls_resb>-lgort.
      ls_tr_item-charg = <ls_resb>-charg.
      ls_tr_item-menge = lv_open_qty.
      ls_tr_item-meins = <ls_resb>-meins.
      ls_tr_item-rsnum = <ls_resb>-rsnum.
      ls_tr_item-rspos = <ls_resb>-rspos.
      ls_tr_item-rsart = <ls_resb>-rsart.
      ls_tr_item-sobkz = <ls_resb>-sobkz.
      ls_tr_item-sonum = <ls_resb>-sonum.
      ls_tr_item-bwart = is_rkpf-bwart.

      " Determine requirement type (e.g. 'A' = Production Order, 'P' = Reservation, 'W' = Generic)
      ls_tr_item-bwlvs = COND #(
        WHEN is_rkpf-bwart = '261' THEN '261'
        WHEN is_rkpf-bwart = '311' THEN '311'
        WHEN is_rkpf-bwart = '201' THEN '201'
        ELSE '999'
      ).

      APPEND ls_tr_item TO lt_tr_items.
    ENDLOOP.

    CHECK lt_tr_items IS NOT INITIAL.

    " Populate TR Header
    CLEAR ls_tr_header.
    ls_tr_header-lgnum = lv_lgnum.
    ls_tr_header-tbdat = sy-datum.
    ls_tr_header-bname = sy-uname.
    ls_tr_header-betyp = 'P'.              " Requirement type: 'P' = Material Reservation
    ls_tr_header-benum = is_rkpf-rsnum.     " Requirement number: Reservation Number
    ls_tr_header-bwart = is_rkpf-bwart.

    " Call standard function module to create Transfer Requirement
    CALL FUNCTION 'L_TR_CREATE'
      EXPORTING
        i_ltbk_create = ls_tr_header
      IMPORTING
        e_tbnum       = lv_tbnum
      TABLES
        t_ltbp_create = lt_tr_items
      EXCEPTIONS
        error_message = 1
        OTHERS        = 2.

    IF sy-subrc = 0 AND lv_tbnum IS NOT INITIAL.
      " Transfer Requirement created successfully
      " In S/4HANA update task, standard database update handles commit
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& ALTERNATIVE CLASSIC CUSTOMER EXIT IMPLEMENTATION (MBCF0007 / EXIT_SAPMM07R_001)
*& Include ZXMBCU07
*&---------------------------------------------------------------------*
* IF xresb-xloek IS INITIAL AND xresb-kzear IS INITIAL.
*   " Call function or trigger background TR creation
*   DATA: lv_auto_tr_lgnum TYPE lgnum.
*   SELECT SINGLE lgnum FROM t320 INTO lv_auto_tr_lgnum
*     WHERE werks = xresb-werks AND lgort = xresb-lgort.
*   IF sy-subrc = 0 AND lv_auto_tr_lgnum IS NOT INITIAL.
*     " Trigger TR creation via background task or custom FM
*   ENDIF.
* ENDIF.
