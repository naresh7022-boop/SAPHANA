class ZCL_RF_AUTO_WM_IM_TRANSFER definition
  public
  final
  create public .

public section.
    TYPES tt_sernr TYPE STANDARD TABLE OF gernr WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_rf_doc_header,
        doc_type     TYPE char3,           " 'RES' (Reservation) or 'TR' (Transfer Requirement)
        doc_num      TYPE char10,          " RSNUM or TBNUM
        lgnum        TYPE lgnum,           " Warehouse Number
        werks        TYPE werks_d,         " Plant
        lgort        TYPE lgort_d,         " Storage Location
        bwart        TYPE bwart,           " Movement Type (e.g. 201, 261, 311)
        kostl        TYPE kostl,           " Cost Center (if applicable)
        aufnr        TYPE aufnr,           " Order (if applicable)
        total_items  TYPE i,
        open_items   TYPE i,
      END OF ty_rf_doc_header,

      BEGIN OF ty_rf_doc_item,
        item_no      TYPE posnr,           " Reservation item (RSPOS) or TR item (POSNR)
        matnr        TYPE matnr,           " Material Number
        maktx        TYPE maktx,           " Material Short Text
        target_qty   TYPE menge_d,         " Required Quantity
        picked_qty   TYPE menge_d,         " Picked / Processed Quantity
        open_qty     TYPE menge_d,         " Remaining Open Quantity
        meins        TYPE meins,           " Base Unit of Measure
        charg        TYPE charg_d,         " Pre-assigned Batch (if any)
        sernp        TYPE serail,          " Serial Number Profile
        is_serialized TYPE abap_bool,      " 'X' if material is serialized
        vltyp        TYPE lgtyp,           " Source Storage Type
        vlpla        TYPE lgpla,           " Source Storage Bin
        tbnum        TYPE tbnum,           " Linked Transfer Requirement
        tbpos        TYPE tbpos,           " Linked TR Item
        status       TYPE char1,           " 'O' = Open, 'P' = In Progress, 'C' = Complete
      END OF ty_rf_doc_item,
      tt_rf_doc_item TYPE STANDARD TABLE OF ty_rf_doc_item WITH KEY item_no,

      BEGIN OF ty_hu_stock_info,
        exidv        TYPE exidv,           " External Handling Unit ID
        venum        TYPE venum,           " Internal HU ID
        matnr        TYPE matnr,           " Material Number
        maktx        TYPE maktx,           " Material Description
        charg        TYPE charg_d,         " Batch Number
        werks        TYPE werks_d,         " Plant
        lgort        TYPE lgort_d,         " Storage Location
        lgnum        TYPE lgnum,           " Warehouse Number
        lgtyp        TYPE lgtyp,           " Storage Type in WM
        lgpla        TYPE lgpla,           " Storage Bin in WM
        lenum        TYPE lenum,           " Storage Unit Number
        menge        TYPE menge_d,         " Quantity packed in HU
        meins        TYPE meins,           " Unit of measure
        lqnum        TYPE lvs_lqnum,       " Quant Number in WM
        wm_avail_qty TYPE menge_d,         " Unrestricted quantity in WM quant
        im_avail_qty TYPE menge_d,         " Unrestricted stock in IM (MARD/MCHB)
        serials      TYPE tt_sernr,                        " Associated Serial Numbers
        is_valid     TYPE abap_bool,       " 'X' if all checks pass
      END OF ty_hu_stock_info,

      BEGIN OF ty_posting_result,
        success      TYPE abap_bool,       " 'X' if both IM and WM committed
        mblnr        TYPE mblnr,           " Material Document Number
        mjahr        TYPE mjahr,           " Material Document Year
        tanum        TYPE tanum,           " Transfer Order Number
        lgnum        TYPE lgnum,           " Warehouse Number
        dest_lgtyp   TYPE lgtyp,           " Destination Storage Type
        dest_lgpla   TYPE lgpla,           " Destination Storage Bin
        rf_message   TYPE char40,          " Formatted message for 16x20 / 8x40 RF screen
        return_tab   TYPE bapiret2_t,      " Comprehensive BAPI messages
      END OF ty_posting_result.

    CONSTANTS:
      c_log_object    TYPE balobj_d  VALUE 'ZRF_WM',
      c_log_subobject TYPE balsubobj VALUE 'RES_TRANSFER'.

    " Core Methods
    METHODS get_document_details
      IMPORTING
        iv_lgnum       TYPE lgnum
        iv_doc_type    TYPE char3            " 'RES' or 'TR'
        iv_doc_num     TYPE char10
      EXPORTING
        es_header      TYPE ty_rf_doc_header
        et_items       TYPE tt_rf_doc_item
        et_return      TYPE bapiret2_t.

    METHODS validate_hu_and_stock
      IMPORTING
        iv_lgnum       TYPE lgnum
        iv_exidv       TYPE exidv
        iv_matnr       TYPE matnr
        iv_werks       TYPE werks_d
        iv_lgort       TYPE lgort_d
        iv_charg       TYPE charg_d OPTIONAL
        iv_req_qty     TYPE menge_d OPTIONAL
      EXPORTING
        es_hu_info     TYPE ty_hu_stock_info
        et_return      TYPE bapiret2_t.

    METHODS execute_single_step_posting
      IMPORTING
        is_header      TYPE ty_rf_doc_header
        is_item        TYPE ty_rf_doc_item
        is_hu_info     TYPE ty_hu_stock_info
        iv_post_qty    TYPE menge_d
      RETURNING
        VALUE(rs_result) TYPE ty_posting_result.

    " Utility & Logging
    METHODS format_rf_message
      IMPORTING
        it_return         TYPE bapiret2_t
        iv_default_text   TYPE string OPTIONAL
      RETURNING
        VALUE(rv_message) TYPE char40.

    METHODS log_application_message
      IMPORTING
        iv_doc_num  TYPE clike
        iv_exidv    TYPE exidv OPTIONAL
        iv_msgty    TYPE symsgty
        iv_text     TYPE string
        it_return   TYPE bapiret2_t OPTIONAL.

    INTERFACES if_oo_adt_classrun.

    METHODS update_reservation_and_tr
      IMPORTING
        is_header   TYPE ty_rf_doc_header
        is_item     TYPE ty_rf_doc_item
        iv_post_qty TYPE menge_d
        iv_mblnr    TYPE mblnr
        iv_mjahr    TYPE mjahr.

    METHODS determine_destination_bin
      IMPORTING
        iv_lgnum         TYPE lgnum
        iv_werks         TYPE werks_d
        iv_dest_lgort    TYPE lgort_d
        iv_matnr         TYPE matnr
        iv_source_lgtyp  TYPE lgtyp
        iv_source_lgpla  TYPE lgpla
      EXPORTING
        ev_dest_lgtyp    TYPE lgtyp
        ev_dest_lgpla    TYPE lgpla.

protected section.
private section.
    METHODS ensure_tr_exists
      IMPORTING
        iv_lgnum  TYPE lgnum
        is_rkpf   TYPE rkpf
        is_resb   TYPE resb
      EXPORTING
        ev_tbnum  TYPE tbnum
        ev_tbpos  TYPE tbpos
        et_return TYPE bapiret2_t.

    METHODS get_serial_numbers_for_hu
      IMPORTING
        iv_venum   TYPE venum
        iv_matnr   TYPE matnr
      RETURNING
        VALUE(rt_serials) TYPE tt_sernr.
ENDCLASS.



CLASS ZCL_RF_AUTO_WM_IM_TRANSFER IMPLEMENTATION.

  METHOD get_document_details.
    " Fetches Reservation or TR items, verifies WM mapping, and automatically
    " generates a TR via L_TR_CREATE if one does not exist for the reservation.
    CLEAR: es_header, et_items, et_return.

    IF iv_doc_num IS INITIAL.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '001'
        message    = 'Please scan or input Document Number'
      ) TO et_return.
      RETURN.
    ENDIF.

    DATA: lv_alpha_num TYPE char10.
    lv_alpha_num = |{ iv_doc_num ALPHA = IN }|.

    CASE iv_doc_type.
      WHEN 'RES'.
        " 1. Read Reservation Header
        SELECT SINGLE *
          FROM rkpf
          INTO @DATA(ls_rkpf)
          WHERE rsnum = @lv_alpha_num.
        IF sy-subrc <> 0.
          APPEND VALUE #(
            type       = 'E'
            id         = 'ZRF'
            number     = '002'
            message    = |Reservation { iv_doc_num } not found|
          ) TO et_return.
          RETURN.
        ENDIF.

        " 2. Read Reservation Items
        SELECT *
          FROM resb
          INTO TABLE @DATA(lt_resb)
          WHERE rsnum = @lv_alpha_num
            AND xloek = @space       " Not deleted
            AND kzear = @space.      " Final issue not set
        IF sy-subrc <> 0 OR lt_resb IS INITIAL.
          APPEND VALUE #(
            type       = 'E'
            id         = 'ZRF'
            number     = '003'
            message    = |No open items found for Reservation { iv_doc_num }|
          ) TO et_return.
          RETURN.
        ENDIF.

        " 3. Build Header
        es_header-doc_type    = 'RES'.
        es_header-doc_num     = ls_rkpf-rsnum.
        es_header-lgnum       = iv_lgnum.
        es_header-bwart       = ls_rkpf-bwart.
        es_header-kostl       = ls_rkpf-kostl.
        es_header-aufnr       = ls_rkpf-aufnr.
        es_header-werks       = VALUE #( lt_resb[ 1 ]-werks OPTIONAL ).
        es_header-lgort       = VALUE #( lt_resb[ 1 ]-lgort OPTIONAL ).
        es_header-total_items = lines( lt_resb ).

        " 4. Process Each Item
        LOOP AT lt_resb ASSIGNING FIELD-SYMBOL(<ls_resb>).
          DATA(lv_open) = <ls_resb>-bdmng - <ls_resb>-enmng.
          CHECK lv_open > 0.

          DATA: ls_item TYPE ty_rf_doc_item.
          CLEAR ls_item.
          ls_item-item_no    = <ls_resb>-rspos.
          ls_item-matnr      = <ls_resb>-matnr.
          ls_item-target_qty = <ls_resb>-bdmng.
          ls_item-picked_qty = <ls_resb>-enmng.
          ls_item-open_qty   = lv_open.
          ls_item-meins      = <ls_resb>-meins.
          ls_item-charg      = <ls_resb>-charg.
          ls_item-status     = 'O'.

          " Material Description
          SELECT SINGLE maktx
            FROM makt
            INTO @ls_item-maktx
            WHERE matnr = @<ls_resb>-matnr
              AND spras = @sy-langu.

          " Check Serial Number Profile
          SELECT SINGLE sernp
            FROM marc
            INTO @ls_item-sernp
            WHERE matnr = @<ls_resb>-matnr
              AND werks = @<ls_resb>-werks.
          IF ls_item-sernp IS NOT INITIAL.
            ls_item-is_serialized = abap_true.
          ENDIF.

          " Cross-reference Transfer Requirement (LTBP via LTBK)
          DATA(lv_resb_rsnum_lead) = CONV rsnum( |{ <ls_resb>-rsnum ALPHA = IN }| ).
          SELECT SINGLE k~tbnum, p~tbpos, k~vltyp, k~vlpla
            FROM ltbk AS k
            INNER JOIN ltbp AS p ON p~lgnum = k~lgnum AND p~tbnum = k~tbnum
            INTO (@ls_item-tbnum, @ls_item-tbpos, @ls_item-vltyp, @ls_item-vlpla)
            WHERE k~lgnum = @iv_lgnum
              AND ( k~rsnum = @lv_resb_rsnum_lead OR ( k~betyp = 'P' AND k~benum = @lv_resb_rsnum_lead ) )
              AND ( p~rspos = @<ls_resb>-rspos OR p~matnr = @<ls_resb>-matnr )
              AND p~elikz = @space.
          IF sy-subrc <> 0 OR ls_item-tbnum IS INITIAL.
            " AUTO-TR TRIGGER: Generate Transfer Requirement on the fly if missing
            me->ensure_tr_exists(
              EXPORTING
                iv_lgnum  = iv_lgnum
                is_rkpf   = ls_rkpf
                is_resb   = <ls_resb>
              IMPORTING
                ev_tbnum  = ls_item-tbnum
                ev_tbpos  = ls_item-tbpos
                et_return = DATA(lt_tr_ret)
            ).
          ENDIF.

          APPEND ls_item TO et_items.
        ENDLOOP.

        es_header-open_items = lines( et_items ).

        IF et_items IS INITIAL.
          APPEND VALUE #(
            type       = 'E'
            id         = 'ZRF'
            number     = '003'
            message    = |Reservation { iv_doc_num } is already closed/completed|
          ) TO et_return.
          RETURN.
        ENDIF.

      WHEN 'TR'.
        " 1. Read Transfer Requirement Header
        SELECT SINGLE *
          FROM ltbk
          INTO @DATA(ls_ltbk)
          WHERE tbnum = @lv_alpha_num
            AND lgnum = @iv_lgnum.
        IF sy-subrc <> 0.
          APPEND VALUE #(
            type       = 'E'
            id         = 'ZRF'
            number     = '004'
            message    = |TR { iv_doc_num } not found in Warehouse { iv_lgnum }|
          ) TO et_return.
          RETURN.
        ENDIF.

        " 2. Read TR Items
        SELECT *
          FROM ltbp
          INTO TABLE @DATA(lt_ltbp)
          WHERE tbnum = @lv_alpha_num
            AND lgnum = @iv_lgnum
            AND elikz = @space.      " Open items only
        IF sy-subrc <> 0 OR lt_ltbp IS INITIAL.
          APPEND VALUE #(
            type       = 'E'
            id         = 'ZRF'
            number     = '005'
            message    = |No open items found for TR { iv_doc_num }|
          ) TO et_return.
          RETURN.
        ENDIF.

        " 3. Build Header
        es_header-doc_type    = 'TR'.
        es_header-doc_num     = ls_ltbk-tbnum.
        es_header-lgnum       = ls_ltbk-lgnum.
        es_header-bwart       = ls_ltbk-bwart.
        es_header-total_items = lines( lt_ltbp ).
        es_header-werks       = VALUE #( lt_ltbp[ 1 ]-werks OPTIONAL ).
        es_header-lgort       = VALUE #( lt_ltbp[ 1 ]-lgort OPTIONAL ).

        " 4. Items
        LOOP AT lt_ltbp ASSIGNING FIELD-SYMBOL(<ls_ltbp>).
          DATA(lv_tr_open) = <ls_ltbp>-menge - <ls_ltbp>-tamen.
          CHECK lv_tr_open > 0.

          CLEAR ls_item.
          ls_item-item_no    = <ls_ltbp>-tbpos.
          ls_item-matnr      = <ls_ltbp>-matnr.
          ls_item-target_qty = <ls_ltbp>-menge.
          ls_item-picked_qty = <ls_ltbp>-tamen.
          ls_item-open_qty   = lv_tr_open.
          ls_item-meins      = <ls_ltbp>-meins.
          ls_item-charg      = <ls_ltbp>-charg.
          ls_item-vltyp      = ls_ltbk-vltyp.
          ls_item-vlpla      = ls_ltbk-vlpla.
          ls_item-tbnum      = <ls_ltbp>-tbnum.
          ls_item-tbpos      = <ls_ltbp>-tbpos.
          ls_item-status     = 'O'.

          " Material Description
          SELECT SINGLE maktx
            FROM makt
            INTO @ls_item-maktx
            WHERE matnr = @<ls_ltbp>-matnr
              AND spras = @sy-langu.

          " Serial Profile Check
          SELECT SINGLE sernp
            FROM marc
            INTO @ls_item-sernp
            WHERE matnr = @<ls_ltbp>-matnr
              AND werks = @<ls_ltbp>-werks.
          IF ls_item-sernp IS NOT INITIAL.
            ls_item-is_serialized = abap_true.
          ENDIF.

          APPEND ls_item TO et_items.
        ENDLOOP.

        es_header-open_items = lines( et_items ).

        IF et_items IS INITIAL.
          APPEND VALUE #(
            type       = 'E'
            id         = 'ZRF'
            number     = '005'
            message    = |TR { iv_doc_num } is already closed/completed|
          ) TO et_return.
          RETURN.
        ENDIF.

      WHEN OTHERS.
        APPEND VALUE #(
          type       = 'E'
          id         = 'ZRF'
          number     = '006'
          message    = |Invalid Doc Type { iv_doc_type }. Use 'RES' or 'TR'.|
        ) TO et_return.
    ENDCASE.
  ENDMETHOD.

  METHOD ensure_tr_exists.
    " Automatically creates a Transfer Requirement via L_TR_CREATE if one
    " was not created during standard reservation save.
    CLEAR: ev_tbnum, ev_tbpos, et_return.

    DATA: lt_ltba TYPE TABLE OF ltba,
          ls_ltba TYPE ltba.

    ls_ltba-lgnum = iv_lgnum.
    ls_ltba-matnr = is_resb-matnr.
    ls_ltba-werks = is_resb-werks.
    ls_ltba-lgort = is_resb-lgort.
    ls_ltba-charg = is_resb-charg.
    ls_ltba-menga = is_resb-bdmng - is_resb-enmng.
    ls_ltba-altme = is_resb-meins.
    ls_ltba-bname = sy-uname.
    ls_ltba-betyp = 'P'.                 " Material Reservation
    ls_ltba-benum = is_rkpf-rsnum.
    ls_ltba-rsnum = is_resb-rsnum.
    ls_ltba-rspos = is_resb-rspos.
    ls_ltba-rsart = is_resb-rsart.
    ls_ltba-bwlvs = COND #(
      WHEN is_rkpf-bwart = '261' THEN '261'
      WHEN is_rkpf-bwart = '311' THEN '311'
      WHEN is_rkpf-bwart = '201' THEN '201'
      ELSE '999'
    ).
    APPEND ls_ltba TO lt_ltba.

    CALL FUNCTION 'L_TR_CREATE'
      EXPORTING
        i_commit_work = 'X'
      TABLES
        t_ltba        = lt_ltba
      EXCEPTIONS
        OTHERS        = 1.

    IF sy-subrc = 0 AND lt_ltba IS NOT INITIAL.
      READ TABLE lt_ltba INTO ls_ltba INDEX 1.
      ev_tbnum = ls_ltba-tbnum.
      ev_tbpos = ls_ltba-tbpos.

      me->log_application_message(
        iv_doc_num = is_rkpf-rsnum
        iv_msgty   = 'S'
        iv_text    = |Auto-TR { ev_tbnum } successfully created for Reservation { is_rkpf-rsnum }|
      ).
    ELSE.
      APPEND VALUE #(
        type    = 'W'
        id      = 'ZRF'
        number  = '007'
        message = |Warning: Auto-TR creation failed for Reservation { is_rkpf-rsnum }|
      ) TO et_return.
    ENDIF.
  ENDMETHOD.

  METHOD validate_hu_and_stock.
    " Comprehensive validation of Handling Unit (VEKP/VEPO), Batch (MCHB),
    " Serials (OBJK), and LE-WM Bin/Quant verification (LQUA).
    CLEAR: es_hu_info, et_return.

    DATA: lv_clean_exidv TYPE exidv.
    lv_clean_exidv = |{ iv_exidv ALPHA = IN }|.

    " 1. Read Handling Unit Header (VEKP)
    SELECT SINGLE *
      FROM vekp
      INTO @DATA(ls_vekp)
      WHERE exidv = @iv_exidv.
    IF sy-subrc <> 0.
      " Try with ALPHA conversion if alphanumeric
      SELECT SINGLE *
        FROM vekp
        INTO @ls_vekp
        WHERE exidv = @lv_clean_exidv.
      IF sy-subrc <> 0.
        " If not found in VEKP (Handling Units), check LQUA for Storage Unit (SU)
        SELECT SINGLE *
          FROM lqua
          INTO @DATA(ls_lqua_su)
          WHERE lgnum = @iv_lgnum
            AND ( lenum = @iv_exidv OR lenum = @lv_clean_exidv )
            AND skzua = @space
            AND skzue = @space
            AND einme = @space.
        IF sy-subrc = 0.
          " Valid Storage Unit (SU) located in Warehouse
          IF ls_lqua_su-matnr <> iv_matnr.
            APPEND VALUE #(
              type    = 'E'
              id      = 'ZRF'
              number  = '013'
              message = |SU { iv_exidv } material { ls_lqua_su-matnr } <> Req { iv_matnr }|
            ) TO et_return.
            RETURN.
          ENDIF.

          IF iv_werks IS NOT INITIAL AND ls_lqua_su-werks <> iv_werks.
            APPEND VALUE #(
              type    = 'E'
              id      = 'ZRF'
              number  = '014'
              message = |SU Plant { ls_lqua_su-werks } <> Req Plant { iv_werks }|
            ) TO et_return.
            RETURN.
          ENDIF.

          IF iv_lgort IS NOT INITIAL AND ls_lqua_su-lgort <> iv_lgort.
            APPEND VALUE #(
              type    = 'E'
              id      = 'ZRF'
              number  = '015'
              message = |SU SLoc { ls_lqua_su-lgort } <> Req SLoc { iv_lgort }|
            ) TO et_return.
            RETURN.
          ENDIF.

          IF iv_charg IS NOT INITIAL AND ls_lqua_su-charg <> iv_charg.
            APPEND VALUE #(
              type    = 'E'
              id      = 'ZRF'
              number  = '016'
              message = |SU Batch { ls_lqua_su-charg } <> Req Batch { iv_charg }|
            ) TO et_return.
            RETURN.
          ENDIF.

          IF ls_lqua_su-lgtyp(1) = '9'.
            APPEND VALUE #(
              type    = 'E'
              id      = 'ZRF'
              number  = '018'
              message = |SU is in interim storage { ls_lqua_su-lgtyp }/{ ls_lqua_su-lgpla }|
            ) TO et_return.
            RETURN.
          ENDIF.

          es_hu_info-exidv        = ls_lqua_su-lenum.
          es_hu_info-venum        = space.
          es_hu_info-matnr        = ls_lqua_su-matnr.
          es_hu_info-werks        = ls_lqua_su-werks.
          es_hu_info-lgort        = ls_lqua_su-lgort.
          es_hu_info-charg        = ls_lqua_su-charg.
          es_hu_info-menge        = ls_lqua_su-verme.
          es_hu_info-meins        = ls_lqua_su-meins.
          es_hu_info-lgnum        = ls_lqua_su-lgnum.
          es_hu_info-lgtyp        = ls_lqua_su-lgtyp.
          es_hu_info-lgpla        = ls_lqua_su-lgpla.
          es_hu_info-lenum        = ls_lqua_su-lenum.
          es_hu_info-lqnum        = ls_lqua_su-lqnum.
          es_hu_info-wm_avail_qty = ls_lqua_su-verme.

          SELECT SINGLE maktx
            FROM makt
            INTO @es_hu_info-maktx
            WHERE matnr = @es_hu_info-matnr
              AND spras = @sy-langu.

          es_hu_info-is_valid = abap_true.
          RETURN.
        ENDIF.

        APPEND VALUE #(
          type       = 'E'
          id         = 'ZRF'
          number     = '010'
          message    = |HU or SU { iv_exidv } does not exist|
        ) TO et_return.
        RETURN.
      ENDIF.
    ENDIF.

    " Check HU status: not deleted/archived
    IF ls_vekp-status = '0060'. " Inactive / archived
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '011'
        message    = |HU { iv_exidv } is archived/inactive|
      ) TO et_return.
      RETURN.
    ENDIF.

    es_hu_info-exidv = ls_vekp-exidv.
    es_hu_info-venum = ls_vekp-venum.

    " 2. Read Handling Unit Item Contents (VEPO)
    SELECT *
      FROM vepo
      INTO TABLE @DATA(lt_vepo)
      WHERE venum = @ls_vekp-venum.
    IF sy-subrc <> 0 OR lt_vepo IS INITIAL.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '012'
        message    = |Handling Unit { iv_exidv } is empty|
      ) TO et_return.
      RETURN.
    ENDIF.

    " 3. Material Match Validation
    READ TABLE lt_vepo INTO DATA(ls_vepo) WITH KEY matnr = iv_matnr.
    IF sy-subrc <> 0.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '013'
        message    = |HU { iv_exidv } does not contain Material { iv_matnr }|
      ) TO et_return.
      RETURN.
    ENDIF.

    es_hu_info-matnr = ls_vepo-matnr.
    es_hu_info-werks = ls_vepo-werks.
    es_hu_info-lgort = ls_vepo-lgort.
    es_hu_info-charg = ls_vepo-charg.
    es_hu_info-menge = ls_vepo-vemng.
    es_hu_info-meins = ls_vepo-vemeh.

    " Material Short Text
    SELECT SINGLE maktx
      FROM makt
      INTO @es_hu_info-maktx
      WHERE matnr = @es_hu_info-matnr
        AND spras = @sy-langu.

    " Validate Plant & SLoc Match
    IF iv_werks IS NOT INITIAL AND es_hu_info-werks <> iv_werks.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '014'
        message    = |HU Plant { es_hu_info-werks } <> Reservation Plant { iv_werks }|
      ) TO et_return.
      RETURN.
    ENDIF.

    IF iv_lgort IS NOT INITIAL AND es_hu_info-lgort <> iv_lgort.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '015'
        message    = |HU SLoc { es_hu_info-lgort } <> Reservation SLoc { iv_lgort }|
      ) TO et_return.
      RETURN.
    ENDIF.

    " Validate Batch Match if pre-assigned
    IF iv_charg IS NOT INITIAL AND es_hu_info-charg <> iv_charg.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '016'
        message    = |Scanned Batch { es_hu_info-charg } <> Required Batch { iv_charg }|
      ) TO et_return.
      RETURN.
    ENDIF.

    " 4. Extract Serial Numbers for Serialized Materials
    es_hu_info-serials = me->get_serial_numbers_for_hu(
      iv_venum = ls_vekp-venum
      iv_matnr = es_hu_info-matnr
    ).

    " 5. LE-WM Quant and Bin Verification (LQUA)
    SELECT SINGLE *
      FROM lqua
      INTO @DATA(ls_lqua)
      WHERE lgnum = @iv_lgnum
        AND matnr = @es_hu_info-matnr
        AND ( charg = @es_hu_info-charg OR charg = @space )
        AND ( lenum = @ls_vekp-exidv OR lenum = @lv_clean_exidv OR lqnum = @ls_vekp-venum )
        AND skzua = @space     " Not blocked for stock removal
        AND skzue = @space     " Not blocked for stock placement
        AND einme = @space.    " Not in inventory
    IF sy-subrc <> 0.
      " If not found by Storage Unit, check quant by plant and sloc in WM
      SELECT SINGLE *
        FROM lqua
        INTO @ls_lqua
        WHERE lgnum = @iv_lgnum
          AND matnr = @es_hu_info-matnr
          AND werks = @es_hu_info-werks
          AND lgort = @es_hu_info-lgort
          AND ( charg = @es_hu_info-charg OR charg = @space )
          AND skzua = @space
          AND skzue = @space.
      IF sy-subrc <> 0.
        APPEND VALUE #(
          type       = 'E'
          id         = 'ZRF'
          number     = '017'
          message    = |No active LE-WM Quant found for HU { iv_exidv } in WH { iv_lgnum }|
        ) TO et_return.
        RETURN.
      ENDIF.
    ENDIF.

    es_hu_info-lgnum        = ls_lqua-lgnum.
    es_hu_info-lgtyp        = ls_lqua-lgtyp.
    es_hu_info-lgpla        = ls_lqua-lgpla.
    es_hu_info-lenum        = ls_lqua-lenum.
    es_hu_info-lqnum        = ls_lqua-lqnum.
    es_hu_info-wm_avail_qty = ls_lqua-verme.

    " Ensure WM Storage Type is not an Interim Storage Type (e.g. 9xx)
    IF ls_lqua-lgtyp(1) = '9'.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '018'
        message    = |HU is currently in interim storage { ls_lqua-lgtyp }/{ ls_lqua-lgpla }|
      ) TO et_return.
      RETURN.
    ENDIF.

    " Available WM Quant Stock Verification (Allows partial quantity for multi-HU scanning)
    IF ls_lqua-verme <= 0.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '019'
        message    = |WM Quant has zero stock available|
      ) TO et_return.
      RETURN.
    ENDIF.

    " 6. IM Stock Verification (MARD / MCHB)
    IF es_hu_info-charg IS NOT INITIAL.
      SELECT SINGLE clabs
        FROM mchb
        INTO @DATA(lv_clabs)
        WHERE matnr = @es_hu_info-matnr
          AND werks = @es_hu_info-werks
          AND lgort = @es_hu_info-lgort
          AND charg = @es_hu_info-charg.
      es_hu_info-im_avail_qty = lv_clabs.
    ELSE.
      SELECT SINGLE labst
        FROM mard
        INTO @DATA(lv_labst)
        WHERE matnr = @es_hu_info-matnr
          AND werks = @es_hu_info-werks
          AND lgort = @es_hu_info-lgort.
      es_hu_info-im_avail_qty = lv_labst.
    ENDIF.

    IF es_hu_info-im_avail_qty <= 0.
      APPEND VALUE #(
        type       = 'E'
        id         = 'ZRF'
        number     = '020'
        message    = |IM unrestricted stock ({ es_hu_info-im_avail_qty }) is zero|
      ) TO et_return.
      RETURN.
    ENDIF.

    es_hu_info-is_valid = abap_true.
  ENDMETHOD.

  METHOD get_serial_numbers_for_hu.
    " Reads serial numbers linked to the Handling Unit via OBJK / SER06
    CLEAR rt_serials.

    " Query serial numbers tied to the Handling Unit internal object list
    SELECT objk~sernr
      FROM ser06
      INNER JOIN objk ON objk~obknr = ser06~obknr
      INTO TABLE @rt_serials
      WHERE ser06~venum = @iv_venum
        AND objk~matnr  = @iv_matnr.
  ENDMETHOD.

  METHOD execute_single_step_posting.
    " Unified atomic posting:
    " 1. Pre-validations & WM quant lock
    " 2. IM Goods Movement (BAPI_GOODSMVT_CREATE)
    " 3. LE-WM Transfer Order Creation & Auto-Confirmation (L_TO_CREATE_TR)
    " 4. Compensatory Rollback (BAPI_GOODSMVT_CANCEL) on failure (Zero orphan stock)
    CLEAR rs_result.
    rs_result-lgnum = is_header-lgnum.

    " -------------------------------------------------------------
    " GUARD PHASE: Validate Inputs & Quant Availability Prior to IM Commit
    " -------------------------------------------------------------
    IF is_hu_info-is_valid = abap_false.
      rs_result-success    = abap_false.
      rs_result-rf_message = 'Invalid HU or Stock Verification Failed'.
      RETURN.
    ENDIF.

    DATA(lv_post_qty) = COND #(
      WHEN iv_post_qty > 0 THEN iv_post_qty
      ELSE is_hu_info-menge
    ).

    IF lv_post_qty > is_item-open_qty.
      rs_result-success    = abap_false.
      rs_result-rf_message = |Post Qty { lv_post_qty } > Open Qty { is_item-open_qty }|.
      RETURN.
    ENDIF.

    " -------------------------------------------------------------
    " STEP A: IM Goods Movement Posting
    " -------------------------------------------------------------
    " Check if source storage location is HU-managed (XHUPF = 'X')
    DATA: lv_src_xhupf TYPE xhupf.
    SELECT SINGLE xhupf FROM t001l INTO @lv_src_xhupf
      WHERE werks = @is_hu_info-werks AND lgort = @is_hu_info-lgort.

    IF lv_src_xhupf = 'X' AND is_hu_info-exidv IS NOT INITIAL.
      " Storage Location is HU-Managed: use standard HU_CREATE_GOODS_MOVEMENT
      DATA: ls_imkpf       TYPE imkpf,
            lt_move_to     TYPE hum_data_move_to_t,
            ls_move_to     TYPE hum_data_move_to,
            lt_external_id TYPE hum_exidv_t,
            ct_imseg       TYPE vsep_t_imseg,
            ls_imseg       TYPE imseg,
            es_emkpf       TYPE emkpf,
            ef_posted      TYPE sysubrc,
            ls_es_message  TYPE huitem_messages,
            et_messages    TYPE huitem_messages_t.

      ls_imkpf-bldat = sy-datum.
      ls_imkpf-budat = sy-datum.
      ls_imkpf-usnam = sy-uname.

      ls_move_to-werks = is_header-werks.
      IF is_header-bwart = '311' AND is_header-doc_type = 'RES'.
        SELECT SINGLE umlgo FROM resb INTO @ls_move_to-lgort
          WHERE rsnum = @is_header-doc_num AND rspos = @is_item-item_no.
      ENDIF.
      IF ls_move_to-lgort IS INITIAL.
        ls_move_to-lgort = is_header-lgort.
      ENDIF.
      ls_move_to-bwart = is_header-bwart.
      APPEND ls_move_to TO lt_move_to.

      " Use full external HU ID with leading zeros intact
      APPEND is_hu_info-exidv TO lt_external_id.

      IF is_header-doc_type = 'RES'.
        ls_imseg-matnr = is_hu_info-matnr.
        ls_imseg-werks = is_hu_info-werks.
        ls_imseg-lgort = is_hu_info-lgort.
        ls_imseg-umlgo = ls_move_to-lgort.
        ls_imseg-bwart = is_header-bwart.
        ls_imseg-erfmg = lv_post_qty.
        ls_imseg-erfme = is_hu_info-meins.
        ls_imseg-rsnum = is_header-doc_num.
        ls_imseg-rspos = is_item-item_no.
        APPEND ls_imseg TO ct_imseg.
      ENDIF.

      " For 311 SLoc transfer, event 0006 is required (0004 is 322 QI transfer)
      DATA: lv_hu_event TYPE char4.
      lv_hu_event = COND #( WHEN is_header-bwart = '311' THEN '0006' ELSE '0001' ).

      CALL FUNCTION 'HU_CREATE_GOODS_MOVEMENT'
        EXPORTING
          if_event       = lv_hu_event
          is_imkpf       = ls_imkpf
          it_move_to     = lt_move_to
          it_external_id = lt_external_id
          if_simulate    = ' '
          if_commit      = 'X'
          if_tcode       = 'VLMOVE'
        IMPORTING
          es_emkpf       = es_emkpf
          ef_posted      = ef_posted
          es_message     = ls_es_message
          et_messages    = et_messages
        CHANGING
          ct_imseg       = ct_imseg.

      " In HU_CREATE_GOODS_MOVEMENT: ef_posted = 1 means posted, 0 = simulated, 2 = error
      IF es_emkpf-mblnr IS NOT INITIAL AND ( ef_posted = 1 OR ef_posted = 0 ).
        " Update reservation and all linked TR items and headers
        me->update_reservation_and_tr(
          is_header   = is_header
          is_item     = is_item
          iv_post_qty = lv_post_qty
          iv_mblnr    = es_emkpf-mblnr
          iv_mjahr    = es_emkpf-mjahr
        ).

        " Determine Destination Storage Type & Bin based on Receiving SLoc Putaway Strategy
        DATA: lv_dest_lgtyp TYPE lgtyp,
              lv_dest_lgpla TYPE lgpla.

        me->determine_destination_bin(
          EXPORTING
            iv_lgnum        = is_header-lgnum
            iv_werks        = is_header-werks
            iv_dest_lgort   = ls_move_to-lgort
            iv_matnr        = is_hu_info-matnr
            iv_source_lgtyp = is_hu_info-lgtyp
            iv_source_lgpla = is_hu_info-lgpla
          IMPORTING
            ev_dest_lgtyp   = lv_dest_lgtyp
            ev_dest_lgpla   = lv_dest_lgpla
        ).

        " Create & Auto-Confirm Transfer Order to move SU/HU to Destination Bin
        DATA: lv_hu_tanum TYPE tanum,
              lt_hu_ltak  TYPE TABLE OF ltak_vb,
              lt_hu_ltap  TYPE TABLE OF ltap_vb.

        IF is_hu_info-lenum IS NOT INITIAL.
          CALL FUNCTION 'L_TO_CREATE_MOVE_SU'
            EXPORTING
              i_lenum       = is_hu_info-lenum
              i_bwlvs       = '999'
              i_nltyp       = lv_dest_lgtyp
              i_nlpla       = lv_dest_lgpla
              i_squit       = 'X'
              i_commit_work = 'X'
            IMPORTING
              e_tanum       = lv_hu_tanum
            TABLES
              t_ltak        = lt_hu_ltak
              t_ltap_vb     = lt_hu_ltap
            EXCEPTIONS
              OTHERS        = 1.
        ENDIF.

        IF lv_hu_tanum IS INITIAL.
          " Fallback to single TO creation if SU move was not applicable or failed
          CALL FUNCTION 'L_TO_CREATE_SINGLE'
            EXPORTING
              i_lgnum       = is_header-lgnum
              i_bwlvs       = '999'
              i_matnr       = is_hu_info-matnr
              i_werks       = is_hu_info-werks
              i_lgort       = ls_move_to-lgort
              i_charg       = is_hu_info-charg
              i_anfme       = lv_post_qty
              i_altme       = is_hu_info-meins
              i_vltyp       = is_hu_info-lgtyp
              i_vlpla       = is_hu_info-lgpla
              i_vlenr       = is_hu_info-lenum
              i_nltyp       = lv_dest_lgtyp
              i_nlpla       = lv_dest_lgpla
              i_squit       = 'X'
              i_commit_work = 'X'
            IMPORTING
              e_tanum       = lv_hu_tanum
            TABLES
              t_ltak        = lt_hu_ltak
              t_ltap_vb     = lt_hu_ltap
            EXCEPTIONS
              OTHERS        = 1.
        ENDIF.

        COMMIT WORK AND WAIT.
        rs_result-success    = abap_true.
        rs_result-mblnr      = es_emkpf-mblnr.
        rs_result-mjahr      = es_emkpf-mjahr.
        rs_result-tanum      = lv_hu_tanum.
        rs_result-dest_lgtyp = lv_dest_lgtyp.
        rs_result-dest_lgpla = lv_dest_lgpla.
        rs_result-rf_message = |Success! MIGO:{ es_emkpf-mblnr } TO:{ lv_hu_tanum } Bin:{ lv_dest_lgtyp }/{ lv_dest_lgpla }|.
        me->log_application_message(
          iv_doc_num = is_header-doc_num
          iv_exidv   = is_hu_info-exidv
          iv_msgty   = 'S'
          iv_text    = |SUCCESS: Doc { is_header-doc_num } MIGO { es_emkpf-mblnr } TO { lv_hu_tanum } Bin { lv_dest_lgtyp }/{ lv_dest_lgpla }|
        ).
        RETURN.
      ELSE.
        DATA: lv_real_msg TYPE string.

        " 1. Priority 1: Check es_message for header/early validation error
        IF ls_es_message-msgid IS NOT INITIAL AND ls_es_message-msgty CA 'EAX'.
          MESSAGE ID ls_es_message-msgid TYPE ls_es_message-msgty NUMBER ls_es_message-msgno
            WITH ls_es_message-msgv1 ls_es_message-msgv2 ls_es_message-msgv3 ls_es_message-msgv4
            INTO lv_real_msg.
        ENDIF.

        " 2. Priority 2: Check et_messages for item/goods movement error
        IF lv_real_msg IS INITIAL.
          LOOP AT et_messages INTO DATA(ls_err_msg) WHERE msgty CA 'EAX'.
            IF ls_err_msg-msgid = 'L9' AND ls_err_msg-msgno = '042'.
              lv_real_msg = |Cannot unpack in { is_hu_info-lgtyp } (SU active, L9 042)|.
            ELSEIF ls_err_msg-msgid = 'L9' AND ls_err_msg-msgno = '610'.
              lv_real_msg = |Cannot 311 HU { is_hu_info-lgort }->non-HU { ls_move_to-lgort } (L9 610)|.
            ELSE.
              MESSAGE ID ls_err_msg-msgid TYPE ls_err_msg-msgty NUMBER ls_err_msg-msgno
                WITH ls_err_msg-msgv1 ls_err_msg-msgv2 ls_err_msg-msgv3 ls_err_msg-msgv4
                INTO lv_real_msg.
            ENDIF.
            EXIT.
          ENDLOOP.
        ENDIF.

        " 3. Priority 3: Fallback with return code
        IF lv_real_msg IS INITIAL.
          lv_real_msg = |HU Goods Movement Failed (Code { ef_posted })|.
        ENDIF.

        rs_result-success    = abap_false.
        rs_result-rf_message = lv_real_msg.
        me->log_application_message(
          iv_doc_num = is_header-doc_num
          iv_exidv   = is_hu_info-exidv
          iv_msgty   = 'E'
          iv_text    = |HU Goods Movement Failed: { lv_real_msg }|
        ).
        RETURN.
      ENDIF.
    ENDIF.

    " Standard Non-HU / IM Goods Movement Posting via BAPI_GOODSMVT_CREATE
    DATA: ls_gm_header TYPE bapi2017_gm_head_01,
          ls_gm_code   TYPE bapi2017_gm_code,
          lt_gm_items  TYPE TABLE OF bapi2017_gm_item_create,
          ls_gm_item   TYPE bapi2017_gm_item_create,
          lt_gm_serial TYPE TABLE OF bapi2017_gm_serialnumber,
          ls_gm_serial TYPE bapi2017_gm_serialnumber,
          lt_gm_return TYPE TABLE OF bapiret2,
          lv_mblnr     TYPE mblnr,
          lv_mjahr     TYPE mjahr.

    ls_gm_header-pstng_date = sy-datum.
    ls_gm_header-doc_date   = sy-datum.
    ls_gm_header-pr_uname   = sy-uname.
    ls_gm_header-header_txt = |RF-HU:{ is_hu_info-exidv }|.

    " GM_CODE '03' = Goods Issue, '04' = Transfer Posting
    ls_gm_code-gm_code = COND #(
      WHEN is_header-bwart = '311' THEN '04'
      ELSE '03'
    ).

    ls_gm_item-material   = is_hu_info-matnr.
    ls_gm_item-plant      = is_hu_info-werks.
    ls_gm_item-stge_loc   = is_hu_info-lgort.
    ls_gm_item-batch      = is_hu_info-charg.
    ls_gm_item-move_type  = is_header-bwart.
    ls_gm_item-entry_qnt  = lv_post_qty.
    ls_gm_item-entry_uom  = is_hu_info-meins.

    IF is_header-doc_type = 'RES'.
      ls_gm_item-reserv_no = is_header-doc_num.
      ls_gm_item-res_item  = is_item-item_no.
    ENDIF.

    IF is_header-kostl IS NOT INITIAL.
      ls_gm_item-costcenter = is_header-kostl.
    ENDIF.
    IF is_header-aufnr IS NOT INITIAL.
      ls_gm_item-orderid = is_header-aufnr.
    ENDIF.

    APPEND ls_gm_item TO lt_gm_items.

    " Populate Serial Numbers into BAPI table
    IF is_item-is_serialized = abap_true AND is_hu_info-serials IS NOT INITIAL.
      LOOP AT is_hu_info-serials INTO DATA(lv_sernr).
        CLEAR ls_gm_serial.
        ls_gm_serial-matdoc_itm = 1.
        ls_gm_serial-serialno   = lv_sernr.
        APPEND ls_gm_serial TO lt_gm_serial.
      ENDLOOP.
    ENDIF.

    CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
      EXPORTING
        goodsmvt_header  = ls_gm_header
        goodsmvt_code    = ls_gm_code
      IMPORTING
        materialdocument = lv_mblnr
        matdocumentyear  = lv_mjahr
      TABLES
        goodsmvt_item    = lt_gm_items
        goodsmvt_serialnumber = lt_gm_serial
        return           = lt_gm_return.

    " Check for IM Posting Errors
    READ TABLE lt_gm_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
    IF sy-subrc = 0 OR lv_mblnr IS INITIAL.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      rs_result-success    = abap_false.
      rs_result-return_tab = lt_gm_return.
      rs_result-rf_message = me->format_rf_message(
        it_return       = lt_gm_return
        iv_default_text = 'IM MIGO Posting Failed'
      ).
      me->log_application_message(
        iv_doc_num = is_header-doc_num
        iv_exidv   = is_hu_info-exidv
        iv_msgty   = 'E'
        iv_text    = |IM MIGO Posting Failed: { rs_result-rf_message }|
        it_return  = lt_gm_return
      ).
      RETURN.
    ENDIF.

    rs_result-mblnr = lv_mblnr.
    rs_result-mjahr = lv_mjahr.

    " -------------------------------------------------------------
    " STEP B: LE-WM Transfer Order Creation & Auto-Confirmation
    " -------------------------------------------------------------
    DATA: lv_tanum    TYPE tanum,
          lt_trite    TYPE l03b_trite_t,
          ls_trite    TYPE l03b_trite,
          lt_ltak     TYPE TABLE OF ltak_vb,
          lt_ltap     TYPE TABLE OF ltap_vb,
          lv_wm_subrc TYPE sysubrc.

    " Determine Destination Storage Type & Bin based on Receiving SLoc Putaway Strategy
    DATA: lv_dest_lgort       TYPE lgort_d,
          lv_nonhu_dest_lgtyp TYPE lgtyp,
          lv_nonhu_dest_lgpla TYPE lgpla.

    IF is_header-bwart = '311' AND is_header-doc_type = 'RES'.
      SELECT SINGLE umlgo FROM resb INTO @lv_dest_lgort
        WHERE rsnum = @is_header-doc_num AND rspos = @is_item-item_no.
    ENDIF.
    IF lv_dest_lgort IS INITIAL.
      lv_dest_lgort = is_header-lgort.
    ENDIF.

    me->determine_destination_bin(
      EXPORTING
        iv_lgnum        = is_header-lgnum
        iv_werks        = is_header-werks
        iv_dest_lgort   = lv_dest_lgort
        iv_matnr        = is_hu_info-matnr
        iv_source_lgtyp = is_hu_info-lgtyp
        iv_source_lgpla = is_hu_info-lgpla
      IMPORTING
        ev_dest_lgtyp   = lv_nonhu_dest_lgtyp
        ev_dest_lgpla   = lv_nonhu_dest_lgpla
    ).

    " If a Transfer Requirement exists, create TO via TR; else create single TO
    IF is_item-tbnum IS NOT INITIAL.
      CLEAR ls_trite.
      ls_trite-tbpos = is_item-tbpos.
      ls_trite-anfme = lv_post_qty.
      ls_trite-altme = is_hu_info-meins.
      ls_trite-charg = is_hu_info-charg.
      ls_trite-vltyp = is_hu_info-lgtyp.
      ls_trite-vlpla = is_hu_info-lgpla.
      ls_trite-vlenr = is_hu_info-lenum.
      ls_trite-nltyp = lv_nonhu_dest_lgtyp.
      ls_trite-nlpla = lv_nonhu_dest_lgpla.
      APPEND ls_trite TO lt_trite.

      CALL FUNCTION 'L_TO_CREATE_TR'
        EXPORTING
          i_lgnum        = is_header-lgnum
          i_tbnum        = is_item-tbnum
          it_trite       = lt_trite
          i_squit        = 'X'                  " Automatic confirmation
          i_commit_work  = ' '                  " Handled in current LUW
          i_bname        = sy-uname
        TABLES
          t_ltak         = lt_ltak
          t_ltap_vb      = lt_ltap
        EXCEPTIONS
          foreign_lock   = 1
          qm_check       = 2
          tr_not_found   = 3
          tr_closed      = 4
          conversion_error = 5
          error_message  = 6
          OTHERS         = 7.
      lv_wm_subrc = sy-subrc.
      IF lv_wm_subrc = 0 AND lt_ltak IS NOT INITIAL.
        lv_tanum = lt_ltak[ 1 ]-tanum.
      ENDIF.
    ELSE.
      " Direct TO creation clearing interim storage to destination bin
      CALL FUNCTION 'L_TO_CREATE_SINGLE'
        EXPORTING
          i_lgnum        = is_header-lgnum
          i_bwlvs        = is_header-bwart
          i_matnr        = is_hu_info-matnr
          i_werks        = is_hu_info-werks
          i_lgort        = is_hu_info-lgort
          i_charg        = is_hu_info-charg
          i_anfme        = lv_post_qty
          i_altme        = is_hu_info-meins
          i_vltyp        = is_hu_info-lgtyp
          i_vlpla        = is_hu_info-lgpla
          i_vlenr        = is_hu_info-lenum
          i_nltyp        = lv_nonhu_dest_lgtyp
          i_nlpla        = lv_nonhu_dest_lgpla
          i_squit        = 'X'                  " Confirm immediately
          i_commit_work  = ' '
          i_bname        = sy-uname
        IMPORTING
          e_tanum        = lv_tanum
        TABLES
          t_ltak         = lt_ltak
          t_ltap_vb      = lt_ltap
        EXCEPTIONS
          no_to_created  = 1
          foreign_lock   = 2
          OTHERS         = 3.
      lv_wm_subrc = sy-subrc.
    ENDIF.

    " -------------------------------------------------------------
    " STEP C: LUW MANAGEMENT & COMPENSATORY ROLLBACK
    " Zero Orphan Stock in 9xx Interim Storage Types
    " -------------------------------------------------------------
    IF lv_wm_subrc <> 0 OR lv_tanum IS INITIAL.

      " COMPENSATORY ACTION: Rollback IM Posting via BAPI_GOODSMVT_CANCEL
      DATA: ls_cancel_head   TYPE bapi2017_gm_head_ret,
            lt_cancel_return TYPE TABLE OF bapiret2.

      CALL FUNCTION 'BAPI_GOODSMVT_CANCEL'
        EXPORTING
          materialdocument    = lv_mblnr
          matdocumentyear     = lv_mjahr
          goodsmvt_pstng_date = sy-datum
          goodsmvt_pr_uname   = sy-uname
        IMPORTING
          goodsmvt_headret    = ls_cancel_head
        TABLES
          return              = lt_cancel_return.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.

      rs_result-success    = abap_false.
      rs_result-mblnr      = space.
      rs_result-mjahr      = space.
      rs_result-rf_message = |WM TO Failed (rc={ lv_wm_subrc }). IM { lv_mblnr } Reversed.|.

      me->log_application_message(
        iv_doc_num = is_header-doc_num
        iv_exidv   = is_hu_info-exidv
        iv_msgty   = 'E'
        iv_text    = |WM TO Failed (rc={ lv_wm_subrc }). MIGO { lv_mblnr } reversed automatically.|
        it_return  = lt_cancel_return
      ).
      RETURN.
    ENDIF.

    " Update reservation and all linked TR items and headers
    me->update_reservation_and_tr(
      is_header   = is_header
      is_item     = is_item
      iv_post_qty = lv_post_qty
      iv_mblnr    = lv_mblnr
      iv_mjahr    = sy-datum(4)
    ).

    " Both IM and WM Successful: Commit the LUW
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.

    rs_result-success    = abap_true.
    rs_result-tanum      = lv_tanum.
    rs_result-dest_lgtyp = lv_nonhu_dest_lgtyp.
    rs_result-dest_lgpla = lv_nonhu_dest_lgpla.
    rs_result-rf_message = |Success! MIGO:{ lv_mblnr } TO:{ lv_tanum } Bin:{ lv_nonhu_dest_lgtyp }/{ lv_nonhu_dest_lgpla }|.

    me->log_application_message(
      iv_doc_num = is_header-doc_num
      iv_exidv   = is_hu_info-exidv
      iv_msgty   = 'S'
      iv_text    = |SUCCESS: Doc { is_header-doc_num } MIGO { lv_mblnr } TO { lv_tanum } Confirmed for HU { is_hu_info-exidv }|
    ).
  ENDMETHOD.

  METHOD format_rf_message.
    " Formats return messages into max 40-character strings for RF screens
    CLEAR rv_message.

    READ TABLE it_return INTO DATA(ls_err) WITH KEY type = 'E'.
    IF sy-subrc <> 0.
      READ TABLE it_return INTO ls_err WITH KEY type = 'A'.
    ENDIF.

    IF sy-subrc = 0 AND ls_err-message IS NOT INITIAL.
      rv_message = ls_err-message(40).
    ELSEIF iv_default_text IS NOT INITIAL.
      rv_message = iv_default_text(40).
    ELSE.
      rv_message = 'Action completed successfully'.
    ENDIF.
  ENDMETHOD.

  METHOD log_application_message.
    " Writes application log entry into SLG1 (Object: ZRF_WM)
    DATA: ls_log        TYPE bal_s_log,
          lv_log_handle TYPE balloghndl,
          ls_msg        TYPE bal_s_msg.

    ls_log-extnumber = |RF-{ iv_doc_num }-{ sy-datum }-{ sy-uzeit }|.
    ls_log-object    = c_log_object.
    ls_log-subobject = c_log_subobject.
    ls_log-aluser    = sy-uname.
    ls_log-alprog    = sy-repid.

    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log      = ls_log
      IMPORTING
        e_log_handle = lv_log_handle
      EXCEPTIONS
        OTHERS       = 1.
    CHECK sy-subrc = 0.

    " Add Main Message
    CLEAR ls_msg.
    ls_msg-msgty = iv_msgty.
    ls_msg-msgid = 'ZRF'.
    ls_msg-msgno = '099'.
    ls_msg-msgv1 = iv_text(50).
    ls_msg-msgv2 = COND #( WHEN strlen( iv_text ) > 50 THEN iv_text+50(50) ELSE space ).

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_log_handle = lv_log_handle
        i_s_msg      = ls_msg
      EXCEPTIONS
        OTHERS       = 1.

    " Add BAPI Return Messages if provided
    LOOP AT it_return INTO DATA(ls_ret).
      CLEAR ls_msg.
      ls_msg-msgty = ls_ret-type.
      ls_msg-msgid = ls_ret-id.
      ls_msg-msgno = ls_ret-number.
      ls_msg-msgv1 = ls_ret-message_v1.
      ls_msg-msgv2 = ls_ret-message_v2.
      ls_msg-msgv3 = ls_ret-message_v3.
      ls_msg-msgv4 = ls_ret-message_v4.

      CALL FUNCTION 'BAL_LOG_MSG_ADD'
        EXPORTING
          i_log_handle = lv_log_handle
          i_s_msg      = ls_msg
        EXCEPTIONS
          OTHERS       = 1.
    ENDLOOP.

    " Save Log to Database
    DATA: lt_handles TYPE bal_t_logh.
    APPEND lv_log_handle TO lt_handles.

    CALL FUNCTION 'BAL_DB_SAVE'
      EXPORTING
        i_t_log_handle = lt_handles
      EXCEPTIONS
        OTHERS         = 1.
  ENDMETHOD.

  METHOD update_reservation_and_tr.
    DATA: lv_rsnum_lead TYPE rsnum,
          lv_tbnum_lead TYPE tbnum.

    " ------------------------------------------------------------------
    " 1. UPDATE RESERVATION (RESB)
    " ------------------------------------------------------------------
    IF is_header-doc_type = 'RES'.
      lv_rsnum_lead = |{ is_header-doc_num ALPHA = IN }|.
    ELSEIF is_item-tbnum IS NOT INITIAL.
      SELECT SINGLE rsnum FROM ltbk INTO @lv_rsnum_lead
        WHERE lgnum = @is_header-lgnum AND tbnum = @is_item-tbnum.
      IF sy-subrc <> 0 OR lv_rsnum_lead IS INITIAL.
        SELECT SINGLE benum FROM ltbk INTO @DATA(lv_benum)
          WHERE lgnum = @is_header-lgnum AND tbnum = @is_item-tbnum AND betyp = 'P'.
        IF sy-subrc = 0.
          lv_rsnum_lead = |{ lv_benum ALPHA = IN }|.
        ENDIF.
      ENDIF.
    ENDIF.

    DATA: lv_is_res_closed TYPE abap_bool VALUE abap_false.

    IF lv_rsnum_lead IS NOT INITIAL.
      SELECT SINGLE bdmng, enmng FROM resb INTO (@DATA(lv_bdmng), @DATA(lv_enmng))
        WHERE rsnum = @lv_rsnum_lead AND rspos = @is_item-item_no.
      IF sy-subrc = 0.
        DATA(lv_new_enmng) = lv_enmng + iv_post_qty.
        DATA(lv_kzear) = COND char1( WHEN lv_new_enmng >= lv_bdmng THEN 'X' ELSE space ).
        IF lv_kzear = 'X'.
          lv_is_res_closed = abap_true.
        ENDIF.
        UPDATE resb SET enmng = @lv_new_enmng, kzear = @lv_kzear
          WHERE rsnum = @lv_rsnum_lead AND rspos = @is_item-item_no.
      ENDIF.
    ENDIF.

    " ------------------------------------------------------------------
    " 2. IDENTIFY ALL LINKED TRANSFER REQUIREMENTS (LTBK / LTBP)
    " ------------------------------------------------------------------
    TYPES: BEGIN OF ty_tr_target,
             lgnum TYPE lgnum,
             tbnum TYPE tbnum,
             tbpos TYPE tbpos,
             menge TYPE ltbp_menge,
             tamen TYPE ltbp_tamen,
           END OF ty_tr_target.
    DATA: lt_targets TYPE STANDARD TABLE OF ty_tr_target WITH EMPTY KEY.

    " If an explicit TR number was already bound to the item
    IF is_item-tbnum IS NOT INITIAL.
      lv_tbnum_lead = |{ is_item-tbnum ALPHA = IN }|.
      SELECT SINGLE lgnum, tbnum, tbpos, menge, tamen
        FROM ltbp
        INTO @DATA(ls_direct_tr)
        WHERE lgnum = @is_header-lgnum
          AND tbnum = @lv_tbnum_lead
          AND tbpos = @is_item-tbpos.
      IF sy-subrc = 0.
        APPEND ls_direct_tr TO lt_targets.
      ENDIF.
    ENDIF.

    " If document is Reservation, locate all TRs created for this reservation
    IF lv_rsnum_lead IS NOT INITIAL.
      SELECT p~lgnum, p~tbnum, p~tbpos, p~menge, p~tamen
        FROM ltbk AS k
        INNER JOIN ltbp AS p ON p~lgnum = k~lgnum AND p~tbnum = k~tbnum
        APPENDING TABLE @lt_targets
        WHERE k~lgnum = @is_header-lgnum
          AND ( k~rsnum = @lv_rsnum_lead OR ( k~betyp = 'P' AND k~benum = @lv_rsnum_lead ) )
          AND ( p~rspos = @is_item-item_no OR p~matnr = @is_item-matnr ).
    ENDIF.

    SORT lt_targets BY lgnum tbnum tbpos.
    DELETE ADJACENT DUPLICATES FROM lt_targets COMPARING lgnum tbnum tbpos.

    " ------------------------------------------------------------------
    " 3. UPDATE EACH TR ITEM (LTBP)
    " ------------------------------------------------------------------
    DATA: lt_distinct_tbnum TYPE STANDARD TABLE OF tbnum WITH EMPTY KEY.

    LOOP AT lt_targets INTO DATA(ls_tr).
      DATA(lv_new_tamen) = ls_tr-tamen + iv_post_qty.
      DATA(lv_elikz) = COND char1(
        WHEN lv_new_tamen >= ls_tr-menge OR lv_is_res_closed = abap_true THEN 'X'
        ELSE space
      ).

      UPDATE ltbp
        SET tamen = @lv_new_tamen,
            elikz = @lv_elikz,
            tdatu = @sy-datum,
            tzeit = @sy-uzeit
        WHERE lgnum = @ls_tr-lgnum
          AND tbnum = @ls_tr-tbnum
          AND tbpos = @ls_tr-tbpos.

      APPEND ls_tr-tbnum TO lt_distinct_tbnum.
    ENDLOOP.

    SORT lt_distinct_tbnum.
    DELETE ADJACENT DUPLICATES FROM lt_distinct_tbnum.

    " ------------------------------------------------------------------
    " 4. UPDATE LTBK HEADER STATUS FOR ALL AFFECTED TRS
    " ------------------------------------------------------------------
    LOOP AT lt_distinct_tbnum INTO DATA(lv_affected_tbnum).
      DATA: lv_remaining_open TYPE i VALUE 0.
      SELECT COUNT(*) INTO @lv_remaining_open
        FROM ltbp
        WHERE lgnum = @is_header-lgnum
          AND tbnum = @lv_affected_tbnum
          AND elikz = @space.

      DATA(lv_tr_statu) = COND ltbk_statu(
        WHEN lv_remaining_open = 0 THEN 'E'  " All items closed -> Processing Complete!
        ELSE 'T'                            " Partially Delivered
      ).

      UPDATE ltbk
        SET statu = @lv_tr_statu,
            mblnr = @iv_mblnr,
            mjahr = @iv_mjahr,
            pdatu = @sy-datum,
            pzeit = @sy-uzeit
        WHERE lgnum = @is_header-lgnum
          AND tbnum = @lv_affected_tbnum.
    ENDLOOP.
  ENDMETHOD.

  METHOD determine_destination_bin.
    " Automatically determines destination storage type & storage bin based on:
    " 1. MLGT Fixed Bin for the Material
    " 2. Receiving Storage Location mapping to Storage Type (T320/LAGP)
    " 3. Standard Putaway available bin search in LAGP
    CLEAR: ev_dest_lgtyp, ev_dest_lgpla.

    " -------------------------------------------------------------
    " 1. CHECK MLGT FIXED BIN FOR MATERIAL IN WAREHOUSE
    " -------------------------------------------------------------
    SELECT SINGLE lgtyp, lgpla
      FROM mlgt
      INTO (@ev_dest_lgtyp, @ev_dest_lgpla)
      WHERE lgnum = @iv_lgnum
        AND matnr = @iv_matnr
        AND lgpla <> @space.
    IF sy-subrc = 0 AND ev_dest_lgtyp IS NOT INITIAL AND ev_dest_lgpla IS NOT INITIAL.
      " Validate bin exists in LAGP and is not blocked
      SELECT SINGLE @abap_true
        FROM lagp
        INTO @DATA(lv_fixed_bin_ok)
        WHERE lgnum = @iv_lgnum
          AND lgtyp = @ev_dest_lgtyp
          AND lgpla = @ev_dest_lgpla
          AND skzue = @space.
      IF lv_fixed_bin_ok = abap_true.
        RETURN.
      ENDIF.
      CLEAR: ev_dest_lgtyp, ev_dest_lgpla.
    ENDIF.

    " -------------------------------------------------------------
    " 2. MAP RECEIVING STORAGE LOCATION TO STORAGE TYPE
    " -------------------------------------------------------------
    CASE iv_dest_lgort.
      WHEN 'OH01' OR 'OH02'.
        ev_dest_lgtyp = 'OH1'.
      WHEN 'CS01'.
        ev_dest_lgtyp = 'RM1'.
      WHEN 'CS02' OR 'HS01' OR 'MT01' OR 'MT02' OR 'CIS1'.
        ev_dest_lgtyp = 'EN1'.
      WHEN 'GS01'.
        ev_dest_lgtyp = 'GS1'.
      WHEN 'FG01'.
        DATA: lv_fg_typ TYPE lgtyp.
        SELECT lgtyp FROM lagp INTO @lv_fg_typ
          UP TO 1 ROWS
          WHERE lgnum = @iv_lgnum AND lgtyp IN ('100', 'EN1', 'OH1')
          ORDER BY lgtyp DESCENDING.
        ENDSELECT.
        ev_dest_lgtyp = COND #( WHEN lv_fg_typ IS NOT INITIAL THEN lv_fg_typ ELSE 'EN1' ).
      WHEN OTHERS.
        " Check active non-interim quants in LQUA for this destination SLoc
        SELECT SINGLE lgtyp FROM lqua INTO @DATA(lv_lqua_typ)
          WHERE lgnum = @iv_lgnum AND werks = @iv_werks AND lgort = @iv_dest_lgort
            AND lgtyp NOT LIKE '9%'.
        IF sy-subrc = 0 AND lv_lqua_typ IS NOT INITIAL.
          ev_dest_lgtyp = lv_lqua_typ.
        ELSE.
          ev_dest_lgtyp = 'EN1'.
        ENDIF.
    ENDCASE.

    " -------------------------------------------------------------
    " 3. FIND AVAILABLE DESTINATION BIN IN LAGP
    " -------------------------------------------------------------
    " Priority 1: Pick an open, unblocked bin different from the source bin
    SELECT lgpla
      FROM lagp
      INTO @ev_dest_lgpla
      UP TO 1 ROWS
      WHERE lgnum = @iv_lgnum
        AND lgtyp = @ev_dest_lgtyp
        AND ( lgtyp <> @iv_source_lgtyp OR lgpla <> @iv_source_lgpla )
        AND skzue = @space
      ORDER BY lgpla ASCENDING.
    ENDSELECT.

    " Priority 2: If no different bin found (e.g. OH1 has only 'ONHOLD'), take any unblocked bin in storage type
    IF ev_dest_lgpla IS INITIAL.
      SELECT SINGLE lgpla
        FROM lagp
        INTO @ev_dest_lgpla
        WHERE lgnum = @iv_lgnum
          AND lgtyp = @ev_dest_lgtyp
          AND skzue = @space.
    ENDIF.

    " Priority 3: Fallback if storage type has no bin in LAGP: use interim 921 TRANSFER
    IF ev_dest_lgpla IS INITIAL.
      ev_dest_lgtyp = '921'.
      ev_dest_lgpla = 'TRANSFER'.
    ENDIF.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    " Test destination bin determination for various receiving SLocs
    DATA: lv_t_typ TYPE lgtyp,
          lv_t_pla TYPE lgpla.

    me->determine_destination_bin(
      EXPORTING
        iv_lgnum        = 'W01'
        iv_werks        = '1120'
        iv_dest_lgort   = 'CS02'
        iv_matnr        = '000000008000009754'
        iv_source_lgtyp = 'EN1'
        iv_source_lgpla = '1-L0001-04'
      IMPORTING
        ev_dest_lgtyp   = lv_t_typ
        ev_dest_lgpla   = lv_t_pla
    ).
    out->write( |Determined Destination for CS02: { lv_t_typ } / { lv_t_pla }| ).

    me->determine_destination_bin(
      EXPORTING
        iv_lgnum        = 'W01'
        iv_werks        = '1120'
        iv_dest_lgort   = 'OH01'
        iv_matnr        = '000000008000009754'
        iv_source_lgtyp = 'EN1'
        iv_source_lgpla = '1-L0001-04'
      IMPORTING
        ev_dest_lgtyp   = lv_t_typ
        ev_dest_lgpla   = lv_t_pla
    ).
    out->write( |Determined Destination for OH01: { lv_t_typ } / { lv_t_pla }| ).

    me->determine_destination_bin(
      EXPORTING
        iv_lgnum        = 'W01'
        iv_werks        = '1120'
        iv_dest_lgort   = 'CS01'
        iv_matnr        = '000000008000009754'
        iv_source_lgtyp = 'EN1'
        iv_source_lgpla = '1-L0001-04'
      IMPORTING
        ev_dest_lgtyp   = lv_t_typ
        ev_dest_lgpla   = lv_t_pla
    ).
    out->write( |Determined Destination for CS01: { lv_t_typ } / { lv_t_pla }| ).

    " Test move SU 00000000002000020327 using the determined destination for CS02
    me->determine_destination_bin(
      EXPORTING
        iv_lgnum        = 'W01'
        iv_werks        = '1120'
        iv_dest_lgort   = 'CS02'
        iv_matnr        = '000000008000009754'
        iv_source_lgtyp = 'EN1'
        iv_source_lgpla = '1-L0001-04'
      IMPORTING
        ev_dest_lgtyp   = lv_t_typ
        ev_dest_lgpla   = lv_t_pla
    ).

    DATA: lv_test_tanum TYPE tanum,
          lv_test_nltyp TYPE ltap_nltyp,
          lv_test_nlber TYPE ltap_nlber,
          lv_test_nlpla TYPE ltap_nlpla,
          lt_test_ltak  TYPE TABLE OF ltak_vb,
          lt_test_ltap  TYPE TABLE OF ltap_vb.

    CALL FUNCTION 'L_TO_CREATE_MOVE_SU'
      EXPORTING
        i_lenum         = '00000000002000020327'
        i_bwlvs         = '999'
        i_nltyp         = lv_t_typ
        i_nlpla         = lv_t_pla
        i_squit         = 'X'
        i_commit_work   = 'X'
      IMPORTING
        e_tanum         = lv_test_tanum
        e_nltyp         = lv_test_nltyp
        e_nlber         = lv_test_nlber
        e_nlpla         = lv_test_nlpla
      TABLES
        t_ltak          = lt_test_ltak
        t_ltap_vb       = lt_test_ltap
      EXCEPTIONS
        OTHERS          = 1.

    COMMIT WORK AND WAIT.
    out->write( |L_TO_CREATE_MOVE_SU: rc={ sy-subrc } tanum={ lv_test_tanum } dest={ lv_test_nltyp }/{ lv_test_nlpla }| ).
    IF sy-subrc <> 0.
      out->write( |Error msg: ID={ sy-msgid } NO={ sy-msgno } V1={ sy-msgv1 } V2={ sy-msgv2 }| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
