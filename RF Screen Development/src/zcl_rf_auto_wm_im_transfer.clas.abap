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
        is_batch_managed TYPE abap_bool,   " 'X' if material is batch managed
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

    TYPES: tt_exidv TYPE STANDARD TABLE OF exidv WITH DEFAULT KEY.
    DATA: mt_scanned_hus TYPE tt_exidv.

    " Core Methods
    METHODS get_document_details
      IMPORTING
        iv_lgnum       TYPE lgnum
        iv_doc_type    TYPE char3            " 'RES' or 'TR'
        iv_doc_num     TYPE char10
      EXPORTING
        es_header      TYPE ty_rf_doc_header
        et_items       TYPE tt_rf_doc_item
        et_scanned_hus TYPE tt_exidv
        et_return      TYPE bapiret2_t.

    METHODS is_hu_already_scanned
      IMPORTING
        iv_doc_num        TYPE char10
        iv_exidv          TYPE exidv
      RETURNING
        VALUE(rv_scanned) TYPE abap_bool.

    METHODS validate_hu_and_stock
      IMPORTING
        iv_lgnum       TYPE lgnum
        iv_exidv       TYPE exidv
        iv_matnr       TYPE matnr
        iv_werks       TYPE werks_d
        iv_lgort       TYPE lgort_d
        iv_charg       TYPE charg_d OPTIONAL
        iv_req_qty     TYPE menge_d OPTIONAL
        iv_doc_num     TYPE char10 OPTIONAL
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
    CLEAR: es_header, et_items, et_return, mt_scanned_hus.

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

          " Check Serial Number Profile and Batch Management
          DATA: lv_resb_xchpf TYPE xchpf.
          SELECT SINGLE sernp, xchpf
            FROM marc
            INTO (@ls_item-sernp, @lv_resb_xchpf)
            WHERE matnr = @<ls_resb>-matnr
              AND werks = @<ls_resb>-werks.
          IF ls_item-sernp IS NOT INITIAL.
            ls_item-is_serialized = abap_true.
          ENDIF.
          IF lv_resb_xchpf = 'X'.
            ls_item-is_batch_managed = abap_true.
          ELSE.
            SELECT SINGLE xchpf FROM mara INTO @DATA(lv_resb_mara_xchpf) WHERE matnr = @<ls_resb>-matnr.
            IF lv_resb_mara_xchpf = 'X'.
              ls_item-is_batch_managed = abap_true.
            ENDIF.
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
        IF es_header-bwart IS INITIAL AND ls_ltbk-bwlvs IS NOT INITIAL.
          es_header-bwart     = ls_ltbk-bwlvs.
        ENDIF.
        IF ls_ltbk-rsnum IS NOT INITIAL.
          SELECT SINGLE bwart FROM resb INTO @DATA(lv_tr_hdr_bwart)
            WHERE rsnum = @ls_ltbk-rsnum.
          IF sy-subrc = 0 AND lv_tr_hdr_bwart IS NOT INITIAL.
            es_header-bwart = lv_tr_hdr_bwart.
          ENDIF.
        ENDIF.
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

          " Serial Profile and Batch Management Check
          DATA: lv_tr_xchpf TYPE xchpf.
          SELECT SINGLE sernp, xchpf
            FROM marc
            INTO (@ls_item-sernp, @lv_tr_xchpf)
            WHERE matnr = @<ls_ltbp>-matnr
              AND werks = @<ls_ltbp>-werks.
          IF ls_item-sernp IS NOT INITIAL.
            ls_item-is_serialized = abap_true.
          ENDIF.
          IF lv_tr_xchpf = 'X'.
            ls_item-is_batch_managed = abap_true.
          ELSE.
            SELECT SINGLE xchpf FROM mara INTO @DATA(lv_tr_mara_xchpf) WHERE matnr = @<ls_ltbp>-matnr.
            IF lv_tr_mara_xchpf = 'X'.
              ls_item-is_batch_managed = abap_true.
            ENDIF.
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

    " -----------------------------------------------------------------
    " Load all previously scanned/posted HUs and SUs for this document
    " to restrict duplicate scanning in a single reservation/TR
    " -----------------------------------------------------------------
    CLEAR mt_scanned_hus.
    IF iv_doc_num IS NOT INITIAL.
      DATA: lv_scan_doc_alpha TYPE char10,
            lv_scan_indx_id   TYPE indx-srtfd.
      lv_scan_doc_alpha = |{ iv_doc_num ALPHA = IN }|.
      lv_scan_indx_id   = |ZRF_RES_{ lv_scan_doc_alpha }|.

      " 1. Cluster database INDX(rf)
      DATA: lt_clust_hus TYPE tt_exidv.
      TRY.
          IMPORT scanned_hus = lt_clust_hus FROM DATABASE indx(rf) ID lv_scan_indx_id.
          LOOP AT lt_clust_hus INTO DATA(lv_c_hu).
            APPEND lv_c_hu TO mt_scanned_hus.
          ENDLOOP.
        CATCH cx_root.
      ENDTRY.

      " 2. Query SAP Standard LTBK (TR) -> LTAK -> LTAP (TO) for this reservation
      SELECT DISTINCT p~vlenr
        FROM ltbk AS k
        INNER JOIN ltak AS a ON a~lgnum = k~lgnum AND a~tbnum = k~tbnum
        INNER JOIN ltap AS p ON p~lgnum = a~lgnum AND p~tanum = a~tanum
        WHERE ( k~rsnum = @lv_scan_doc_alpha OR k~rsnum = @iv_doc_num
             OR ( k~betyp = 'P' AND ( k~benum = @lv_scan_doc_alpha OR k~benum = @iv_doc_num ) ) )
          AND p~vlenr IS NOT INITIAL
        APPENDING TABLE @mt_scanned_hus.

      SELECT DISTINCT p~nlenr
        FROM ltbk AS k
        INNER JOIN ltak AS a ON a~lgnum = k~lgnum AND a~tbnum = k~tbnum
        INNER JOIN ltap AS p ON p~lgnum = a~lgnum AND p~tanum = a~tanum
        WHERE ( k~rsnum = @lv_scan_doc_alpha OR k~rsnum = @iv_doc_num
             OR ( k~betyp = 'P' AND ( k~benum = @lv_scan_doc_alpha OR k~benum = @iv_doc_num ) ) )
          AND p~nlenr IS NOT INITIAL
        APPENDING TABLE @mt_scanned_hus.

      " 3. Query Serial numbers / HUs via SER03 + OBJK + MSEG
      SELECT DISTINCT o~sernr
        FROM mseg AS m
        INNER JOIN ser03 AS s ON s~mblnr = m~mblnr AND s~mjahr = m~mjahr
        INNER JOIN objk AS o ON o~obknr = s~obknr
        WHERE ( m~rsnum = @lv_scan_doc_alpha OR m~rsnum = @iv_doc_num )
          AND o~sernr IS NOT INITIAL
        APPENDING TABLE @mt_scanned_hus.

      " 5. Normalize and expand all variations (raw, stripped, alpha-padded)
      DATA: lt_norm_hus TYPE tt_exidv.
      LOOP AT mt_scanned_hus INTO DATA(lv_raw_hu).
        CHECK lv_raw_hu IS NOT INITIAL.
        DATA: lv_h_raw   TYPE exidv,
              lv_h_strip TYPE exidv,
              lv_h_pad20 TYPE exidv,
              lv_h_pad10 TYPE exidv.
        lv_h_raw = lv_raw_hu.
        CONDENSE lv_h_raw NO-GAPS.
        lv_h_strip = lv_h_raw.
        SHIFT lv_h_strip LEFT DELETING LEADING ' 0'.
        lv_h_pad20 = |{ lv_h_strip ALPHA = IN }|.
        lv_h_pad10 = |{ lv_h_strip ALPHA = IN }|.

        APPEND lv_h_raw   TO lt_norm_hus.
        APPEND lv_h_strip TO lt_norm_hus.
        APPEND lv_h_pad20 TO lt_norm_hus.
        IF lv_h_pad10 IS NOT INITIAL.
          APPEND lv_h_pad10 TO lt_norm_hus.
        ENDIF.
      ENDLOOP.

      mt_scanned_hus = lt_norm_hus.
      SORT mt_scanned_hus.
      DELETE ADJACENT DUPLICATES FROM mt_scanned_hus.

      IF et_scanned_hus IS REQUESTED.
        et_scanned_hus = mt_scanned_hus.
      ENDIF.
    ENDIF.
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
    " Comprehensive validation for ZRF01 / ZRF_RESWM supporting:
    " 1. Priority 1: Handling Unit (HU) scan (VEKP/VEPO)
    " 2. Priority 2: Storage Unit (SU) scan (LQUA/LEIN)
    " 3. Priority 3 (Fallback): Batch number scan (MCHA/MCH1/MCHB/LQUA)
    CLEAR: es_hu_info, et_return.

    " -------------------------------------------------------------
    " Format and Clean scanned input barcode
    " -------------------------------------------------------------
    DATA: lv_scan_raw    TYPE exidv,
          lv_scan_clean  TYPE string,
          lv_scan_strip  TYPE exidv,
          lv_pad20       TYPE exidv,
          lv_pad10       TYPE exidv,
          lv_pad18       TYPE char18.

    lv_scan_raw = iv_exidv.
    CONDENSE lv_scan_raw NO-GAPS.
    lv_scan_clean = lv_scan_raw.

    " Strip barcode symbology identifiers if scanned with AIM prefix
    IF strlen( lv_scan_clean ) >= 3 AND ( lv_scan_clean(3) = ']C1' OR lv_scan_clean(3) = ']e0' OR lv_scan_clean(3) = ']d2' ).
      lv_scan_clean = lv_scan_clean+3.
    ENDIF.
    " Strip GS1 Application Identifier (00) for SSCC / HU
    IF strlen( lv_scan_clean ) >= 4 AND ( lv_scan_clean(4) = '(00)' OR lv_scan_clean(4) = '(01)' ).
      lv_scan_clean = lv_scan_clean+4.
    ENDIF.
    CONDENSE lv_scan_clean NO-GAPS.

    lv_scan_strip = lv_scan_clean.
    SHIFT lv_scan_strip LEFT DELETING LEADING ' 0'.
    IF lv_scan_strip IS INITIAL.
      lv_scan_strip = lv_scan_clean.
    ENDIF.

    lv_pad20 = |{ lv_scan_strip ALPHA = IN WIDTH = 20 }|.
    lv_pad10 = |{ lv_scan_strip ALPHA = IN WIDTH = 10 }|.
    lv_pad18 = |{ lv_scan_strip ALPHA = IN WIDTH = 18 }|.

    " -------------------------------------------------------------
    " Check if HU or SU was already scanned/posted for this request
    " -------------------------------------------------------------
    IF iv_doc_num IS NOT INITIAL AND iv_exidv IS NOT INITIAL.
      IF me->is_hu_already_scanned( iv_doc_num = iv_doc_num iv_exidv = iv_exidv ) = abap_true
         OR me->is_hu_already_scanned( iv_doc_num = iv_doc_num iv_exidv = lv_scan_strip ) = abap_true
         OR me->is_hu_already_scanned( iv_doc_num = iv_doc_num iv_exidv = lv_pad20 ) = abap_true
         OR me->is_hu_already_scanned( iv_doc_num = iv_doc_num iv_exidv = lv_pad10 ) = abap_true.
        APPEND VALUE #(
          type    = 'E'
          id      = 'ZRF'
          number  = '033'
          message = 'HU or SU is already scan'
        ) TO et_return.
        RETURN.
      ENDIF.
    ENDIF.

    " -------------------------------------------------------------
    " PRIORITY 1: HANDLING UNIT (HU) SCAN (VEKP / VEPO)
    " -------------------------------------------------------------
    DATA: ls_vekp TYPE vekp.
    SELECT SINGLE *
      FROM vekp
      INTO @ls_vekp
      WHERE exidv = @lv_scan_raw
         OR exidv = @lv_pad20
         OR exidv = @lv_pad18
         OR exidv = @lv_pad10
         OR exidv = @lv_scan_strip
         OR venum = @lv_pad10
         OR venum = @lv_pad20
         OR venum = @lv_scan_strip.

    IF sy-subrc = 0.
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

      " Read Handling Unit Item Contents (VEPO)
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

      " Material Match Validation
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

      SELECT SINGLE maktx
        FROM makt
        INTO @es_hu_info-maktx
        WHERE matnr = @es_hu_info-matnr
          AND spras = @sy-langu.

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

      IF iv_charg IS NOT INITIAL AND es_hu_info-charg <> iv_charg.
        APPEND VALUE #(
          type       = 'E'
          id         = 'ZRF'
          number     = '016'
          message    = |Scanned Batch { es_hu_info-charg } <> Required Batch { iv_charg }|
        ) TO et_return.
        RETURN.
      ENDIF.

      " Extract Serial Numbers for Serialized Materials
      es_hu_info-serials = me->get_serial_numbers_for_hu(
        iv_venum = ls_vekp-venum
        iv_matnr = es_hu_info-matnr
      ).

      " LE-WM Quant and Bin Verification (LQUA)
      SELECT SINGLE *
        FROM lqua
        INTO @DATA(ls_lqua)
        WHERE lgnum = @iv_lgnum
          AND matnr = @es_hu_info-matnr
          AND ( charg = @es_hu_info-charg OR charg = @space )
          AND ( lenum = @ls_vekp-exidv OR lenum = @lv_pad20 OR lenum = @lv_pad10
             OR lenum = @lv_scan_raw OR lenum = @lv_scan_strip OR lqnum = @ls_vekp-venum )
          AND skzua = @space
          AND skzue = @space
          AND einme = @space.
      IF sy-subrc <> 0.
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

      IF es_hu_info-lenum IS INITIAL.
        SELECT SINGLE lenum FROM lein INTO @es_hu_info-lenum
          WHERE lenum = @ls_vekp-exidv OR lenum = @lv_pad20 OR lenum = @lv_pad10.
      ENDIF.

      IF ls_lqua-lgtyp(1) = '9'.
        APPEND VALUE #(
          type       = 'E'
          id         = 'ZRF'
          number     = '018'
          message    = |HU is currently in interim storage { ls_lqua-lgtyp }/{ ls_lqua-lgpla }|
        ) TO et_return.
        RETURN.
      ENDIF.

      IF ls_lqua-verme <= 0.
        APPEND VALUE #(
          type       = 'E'
          id         = 'ZRF'
          number     = '019'
          message    = |WM Quant has zero stock available|
        ) TO et_return.
        RETURN.
      ENDIF.

      " IM Stock Verification (MARD / MCHB)
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

      IF iv_doc_num IS NOT INITIAL.
        IF ( es_hu_info-exidv IS NOT INITIAL AND me->is_hu_already_scanned( iv_doc_num = iv_doc_num iv_exidv = es_hu_info-exidv ) = abap_true )
           OR ( es_hu_info-lenum IS NOT INITIAL AND me->is_hu_already_scanned( iv_doc_num = iv_doc_num iv_exidv = es_hu_info-lenum ) = abap_true ).
          CLEAR es_hu_info.
          APPEND VALUE #(
            type    = 'E'
            id      = 'ZRF'
            number  = '033'
            message = 'HU or SU is already scan'
          ) TO et_return.
          RETURN.
        ENDIF.
      ENDIF.

      es_hu_info-is_valid = abap_true.
      RETURN.
    ENDIF.

    " -------------------------------------------------------------
    " PRIORITY 2: STORAGE UNIT (SU) SCAN (LQUA / LEIN)
    " Allows scanning pure Storage Units or SU-managed pallets
    " -------------------------------------------------------------
    SELECT *
      FROM lqua
      INTO TABLE @DATA(lt_lqua_su)
      WHERE lgnum = @iv_lgnum
        AND ( lenum = @lv_pad20
           OR lenum = @lv_pad10
           OR lenum = @lv_scan_raw
           OR lenum = @lv_scan_strip )
        AND skzua = @space
        AND skzue = @space
        AND einme = @space.

    IF sy-subrc = 0 AND lt_lqua_su IS NOT INITIAL.
      " Storage Unit found in Warehouse! Verify Material
      READ TABLE lt_lqua_su INTO DATA(ls_lqua_su) WITH KEY matnr = iv_matnr.
      IF sy-subrc <> 0.
        DATA(ls_wrong_su) = lt_lqua_su[ 1 ].
        APPEND VALUE #(
          type    = 'E'
          id      = 'ZRF'
          number  = '013'
          message = |SU { iv_exidv } material { ls_wrong_su-matnr } <> Req { iv_matnr }|
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
        " If this SU has multiple quants, see if another quant matches iv_charg
        READ TABLE lt_lqua_su INTO ls_lqua_su
          WITH KEY matnr = iv_matnr charg = iv_charg.
        IF sy-subrc <> 0.
          APPEND VALUE #(
            type    = 'E'
            id      = 'ZRF'
            number  = '016'
            message = |SU Batch { ls_lqua_su-charg } <> Req Batch { iv_charg }|
          ) TO et_return.
          RETURN.
        ENDIF.
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

      " Calculate total quantity on this SU for this material/batch
      DATA: lv_su_mat_qty TYPE menge_d VALUE 0.
      LOOP AT lt_lqua_su INTO DATA(ls_su_q) WHERE matnr = iv_matnr.
        IF iv_charg IS INITIAL OR ls_su_q-charg = iv_charg.
          lv_su_mat_qty = lv_su_mat_qty + ls_su_q-verme.
        ENDIF.
      ENDLOOP.
      IF lv_su_mat_qty <= 0.
        lv_su_mat_qty = ls_lqua_su-verme.
      ENDIF.

      " Check if this Storage Unit is linked to a Handling Unit in VEKP
      DATA: lv_su_venum TYPE venum,
            lv_su_exidv TYPE exidv.
      SELECT SINGLE venum, exidv FROM vekp
        INTO (@lv_su_venum, @lv_su_exidv)
        WHERE exidv = @ls_lqua_su-lenum OR venum = @ls_lqua_su-lenum
           OR exidv = @lv_pad20 OR exidv = @lv_pad10.
      IF sy-subrc = 0.
        es_hu_info-venum   = lv_su_venum.
        es_hu_info-exidv   = COND #( WHEN lv_su_exidv IS NOT INITIAL THEN lv_su_exidv ELSE ls_lqua_su-lenum ).
        es_hu_info-serials = me->get_serial_numbers_for_hu( iv_venum = lv_su_venum iv_matnr = iv_matnr ).
      ELSE.
        es_hu_info-exidv   = ls_lqua_su-lenum.
        es_hu_info-venum   = space.
      ENDIF.

      es_hu_info-lenum        = ls_lqua_su-lenum.
      es_hu_info-matnr        = ls_lqua_su-matnr.
      es_hu_info-werks        = ls_lqua_su-werks.
      es_hu_info-lgort        = ls_lqua_su-lgort.
      es_hu_info-charg        = ls_lqua_su-charg.
      es_hu_info-menge        = lv_su_mat_qty.
      es_hu_info-meins        = ls_lqua_su-meins.
      es_hu_info-lgnum        = ls_lqua_su-lgnum.
      es_hu_info-lgtyp        = ls_lqua_su-lgtyp.
      es_hu_info-lgpla        = ls_lqua_su-lgpla.
      es_hu_info-lqnum        = ls_lqua_su-lqnum.
      es_hu_info-wm_avail_qty = lv_su_mat_qty.

      IF ls_lqua_su-charg IS NOT INITIAL.
        SELECT SINGLE clabs FROM mchb INTO @es_hu_info-im_avail_qty
          WHERE matnr = @ls_lqua_su-matnr AND werks = @ls_lqua_su-werks
            AND lgort = @ls_lqua_su-lgort AND charg = @ls_lqua_su-charg.
      ELSE.
        SELECT SINGLE labst FROM mard INTO @es_hu_info-im_avail_qty
          WHERE matnr = @ls_lqua_su-matnr AND werks = @ls_lqua_su-werks
            AND lgort = @ls_lqua_su-lgort.
      ENDIF.

      SELECT SINGLE maktx
        FROM makt
        INTO @es_hu_info-maktx
        WHERE matnr = @es_hu_info-matnr
          AND spras = @sy-langu.

      IF iv_doc_num IS NOT INITIAL.
        IF ( es_hu_info-exidv IS NOT INITIAL AND me->is_hu_already_scanned( iv_doc_num = iv_doc_num iv_exidv = es_hu_info-exidv ) = abap_true )
           OR ( es_hu_info-lenum IS NOT INITIAL AND me->is_hu_already_scanned( iv_doc_num = iv_doc_num iv_exidv = es_hu_info-lenum ) = abap_true ).
          CLEAR es_hu_info.
          APPEND VALUE #(
            type    = 'E'
            id      = 'ZRF'
            number  = '033'
            message = 'HU or SU is already scan'
          ) TO et_return.
          RETURN.
        ENDIF.
      ENDIF.

      es_hu_info-is_valid = abap_true.
      RETURN.
    ELSE.
      " Check if SU header exists in LEIN but no quants
      SELECT SINGLE * FROM lein INTO @DATA(ls_lein_only)
        WHERE lenum = @lv_pad20 OR lenum = @lv_pad10
           OR lenum = @lv_scan_raw OR lenum = @lv_scan_strip.
      IF sy-subrc = 0.
        APPEND VALUE #(
          type    = 'E'
          id      = 'ZRF'
          number  = '012'
          message = |Storage Unit { iv_exidv } has no available stock|
        ) TO et_return.
        RETURN.
      ENDIF.
    ENDIF.

    " -------------------------------------------------------------
    " PRIORITY 3 (FALLBACK): BATCH NUMBER SCAN (MCHA / MCH1 / MCHB)
    " Store team scans Batch Number (CHARG) directly
    " -------------------------------------------------------------
    DATA: lv_batch_scan TYPE charg_d.
    lv_batch_scan = iv_exidv.

    SELECT SINGLE * FROM mcha INTO @DATA(ls_mcha)
      WHERE matnr = @iv_matnr
        AND werks = @iv_werks
        AND ( charg = @lv_batch_scan OR charg = @lv_scan_strip ).
    IF sy-subrc <> 0.
      SELECT SINGLE * FROM mch1 INTO @DATA(ls_mch1)
        WHERE matnr = @iv_matnr
          AND ( charg = @lv_batch_scan OR charg = @lv_scan_strip ).
    ENDIF.

    IF sy-subrc = 0.
      DATA(lv_matched_batch) = COND charg_d( WHEN ls_mcha-charg IS NOT INITIAL THEN ls_mcha-charg ELSE ls_mch1-charg ).
      IF iv_charg IS NOT INITIAL AND iv_charg <> lv_matched_batch.
        APPEND VALUE #(
          type    = 'E'
          id      = 'ZRF'
          number  = '031'
          message = |Scanned Batch { lv_matched_batch } <> Required Batch { iv_charg }|
        ) TO et_return.
        RETURN.
      ENDIF.

      DATA: lv_batch_clabs TYPE menge_d.
      SELECT SINGLE clabs FROM mchb INTO @lv_batch_clabs
        WHERE matnr = @iv_matnr
          AND werks = @iv_werks
          AND lgort = @iv_lgort
          AND charg = @lv_matched_batch.

      IF lv_batch_clabs <= 0.
        APPEND VALUE #(
          type    = 'E'
          id      = 'ZRF'
          number  = '032'
          message = |Batch { lv_matched_batch } has no stock in SLoc { iv_lgort }|
        ) TO et_return.
        RETURN.
      ENDIF.

      SELECT * FROM lqua
        INTO TABLE @DATA(lt_batch_quants)
        WHERE lgnum = @iv_lgnum
          AND matnr = @iv_matnr
          AND werks = @iv_werks
          AND lgort = @iv_lgort
          AND charg = @lv_matched_batch
          AND skzua = @space
          AND skzue = @space
          AND verme > 0
        ORDER BY lgtyp, lgpla.

      DATA: lv_sum_wm_qty  TYPE menge_d VALUE 0,
            ls_best_bquant TYPE lqua.

      LOOP AT lt_batch_quants INTO DATA(ls_bq).
        lv_sum_wm_qty = lv_sum_wm_qty + ls_bq-verme.
        IF ls_best_bquant IS INITIAL.
          ls_best_bquant = ls_bq.
        ENDIF.
      ENDLOOP.

      es_hu_info-exidv        = lv_matched_batch.
      es_hu_info-charg        = lv_matched_batch.
      es_hu_info-matnr        = iv_matnr.
      es_hu_info-werks        = iv_werks.
      es_hu_info-lgort        = iv_lgort.
      es_hu_info-lgnum        = iv_lgnum.
      es_hu_info-im_avail_qty = lv_batch_clabs.

      IF ls_best_bquant IS NOT INITIAL.
        es_hu_info-lgtyp        = ls_best_bquant-lgtyp.
        es_hu_info-lgpla        = ls_best_bquant-lgpla.
        es_hu_info-lenum        = ls_best_bquant-lenum.
        es_hu_info-lqnum        = ls_best_bquant-lqnum.
        es_hu_info-meins        = ls_best_bquant-meins.
        es_hu_info-wm_avail_qty = lv_sum_wm_qty.
        es_hu_info-menge        = lv_sum_wm_qty.

        IF ls_best_bquant-lenum IS NOT INITIAL.
          SELECT SINGLE venum, exidv FROM vekp
            INTO (@es_hu_info-venum, @DATA(lv_linked_exidv2))
            WHERE exidv = @ls_best_bquant-lenum OR venum = @ls_best_bquant-lenum.
        ENDIF.
      ELSE.
        SELECT SINGLE meins FROM mara INTO @es_hu_info-meins WHERE matnr = @iv_matnr.
        es_hu_info-wm_avail_qty = lv_batch_clabs.
        es_hu_info-menge        = lv_batch_clabs.
      ENDIF.

      SELECT SINGLE maktx FROM makt INTO @es_hu_info-maktx
        WHERE matnr = @iv_matnr AND spras = @sy-langu.

      es_hu_info-is_valid = abap_true.
      RETURN.
    ENDIF.

    " -------------------------------------------------------------
    " NEITHER HU, SU, NOR BATCH FOUND
    " -------------------------------------------------------------
    APPEND VALUE #(
      type       = 'E'
      id         = 'ZRF'
      number     = '010'
      message    = |HU or SU '{ iv_exidv }' does not exist in WH { iv_lgnum }|
    ) TO et_return.
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
    " Determine Receiving / Destination Storage Location
    DATA: lv_dest_lgort TYPE lgort_d,
          lv_dest_werks TYPE werks_d,
          lv_dest_parlg TYPE lgort_d,
          lv_src_xhupf  TYPE xhupf,
          lv_dest_xhupf TYPE xhupf.

    lv_dest_werks = is_header-werks.
    IF is_header-doc_type = 'RES'.
      DATA(lv_res_rspos) = CONV rspos( is_item-item_no ).
      SELECT SINGLE umlgo, umwrk FROM resb INTO (@lv_dest_lgort, @lv_dest_werks)
        WHERE rsnum = @is_header-doc_num AND rspos = @lv_res_rspos.
    ELSEIF is_header-doc_type = 'TR'.
      SELECT SINGLE rsnum, benum FROM ltbk INTO (@DATA(lv_tr_hdr_rsnum), @DATA(lv_tr_hdr_benum))
        WHERE lgnum = @is_header-lgnum AND tbnum = @is_header-doc_num.
      IF lv_tr_hdr_rsnum IS NOT INITIAL.
        SELECT SINGLE umlgo, umwrk FROM resb INTO (@lv_dest_lgort, @lv_dest_werks)
          WHERE rsnum = @lv_tr_hdr_rsnum.
      ELSEIF lv_tr_hdr_benum IS NOT INITIAL.
        SELECT SINGLE umlgo, umwrk FROM resb INTO (@lv_dest_lgort, @lv_dest_werks)
          WHERE rsnum = @lv_tr_hdr_benum.
      ENDIF.
    ENDIF.
    IF lv_dest_lgort IS INITIAL.
      lv_dest_lgort = is_header-lgort.
    ENDIF.
    IF lv_dest_werks IS INITIAL.
      lv_dest_werks = is_header-werks.
    ENDIF.

    " Check HU management indicator for source and destination storage locations
    SELECT SINGLE xhupf FROM t001l INTO @lv_src_xhupf
      WHERE werks = @is_hu_info-werks AND lgort = @is_hu_info-lgort.

    SELECT SINGLE xhupf, parlg FROM t001l INTO (@lv_dest_xhupf, @lv_dest_parlg)
      WHERE werks = @lv_dest_werks AND lgort = @lv_dest_lgort.

    " Determine target TR number for Transfer Order and cross-referencing
    DATA(lv_tr_target) = is_item-tbnum.
    IF lv_tr_target IS INITIAL.
      IF is_header-doc_type = 'TR'.
        lv_tr_target = is_header-doc_num.
      ELSE.
        SELECT SINGLE tbnum FROM ltbk INTO @lv_tr_target
          WHERE lgnum = @is_header-lgnum
            AND ( rsnum = @is_header-doc_num OR ( betyp = 'P' AND benum = @is_header-doc_num ) )
            AND statu <> 'E'.
      ENDIF.
    ENDIF.

    DATA: lv_im_posted  TYPE abap_bool VALUE abap_false,
          lv_mblnr      TYPE mblnr,
          lv_mjahr      TYPE mjahr,
          lv_last_error TYPE string.

    " -------------------------------------------------------------
    " PATH 1: Both SLocs are HU-Managed -> Standard HU_CREATE_GOODS_MOVEMENT
    " Note: Per SAP Note 1594558 / standard HUM, 1-step HU transfer posting (0006)
    " is valid ONLY if BOTH source and destination storage locations are HU-managed!
    " -------------------------------------------------------------
    IF lv_src_xhupf = 'X' AND lv_dest_xhupf = 'X'
       AND is_hu_info-exidv IS NOT INITIAL AND is_hu_info-venum IS NOT INITIAL.

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
      ls_imkpf-bktxt = |RF-HU:{ is_hu_info-exidv }|.

      ls_move_to-huwbevent = COND #( WHEN is_header-bwart = '311' THEN '0006' ELSE '0001' ).
      ls_move_to-werks     = lv_dest_werks.
      ls_move_to-lgort     = lv_dest_lgort.
      ls_move_to-bwart     = is_header-bwart.
      ls_move_to-matnr     = is_hu_info-matnr.
      ls_move_to-charg     = is_hu_info-charg.

      " Populate HU item line reference from VEPO
      SELECT venum, vepos, matnr, charg, vemng, vemeh
        FROM vepo
        INTO TABLE @DATA(lt_vepo_lines)
        WHERE venum = @is_hu_info-venum
          AND matnr = @is_hu_info-matnr.
      LOOP AT lt_vepo_lines INTO DATA(ls_vl).
        APPEND VALUE hum_humseg( venum = ls_vl-venum vepos = ls_vl-vepos ) TO ls_move_to-hu_items.
      ENDLOOP.
      APPEND ls_move_to TO lt_move_to.

      " Use full external HU ID with leading zeros intact
      APPEND is_hu_info-exidv TO lt_external_id.

      IF is_header-doc_type = 'RES'.
        ls_imseg-matnr = is_hu_info-matnr.
        ls_imseg-werks = is_hu_info-werks.
        ls_imseg-lgort = is_hu_info-lgort.
        ls_imseg-umlgo = lv_dest_lgort.
        ls_imseg-bwart = is_header-bwart.
        ls_imseg-erfmg = lv_post_qty.
        ls_imseg-erfme = is_hu_info-meins.
        ls_imseg-rsnum = is_header-doc_num.
        ls_imseg-rspos = is_item-item_no.
        APPEND ls_imseg TO ct_imseg.
      ENDIF.

      DATA: lv_hu_event TYPE char4.
      lv_hu_event = COND #( WHEN is_header-bwart = '311' THEN '0006' ELSE '0001' ).

      CALL FUNCTION 'HU_PACKING_REFRESH'.

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

      IF es_emkpf-mblnr IS NOT INITIAL AND ( ef_posted = 1 OR ef_posted = 0 ).
        lv_im_posted = abap_true.
        lv_mblnr     = es_emkpf-mblnr.
        lv_mjahr     = es_emkpf-mjahr.
      ELSE.
        " HU_CREATE_GOODS_MOVEMENT failed or returned error like L9 610.
        " Log warning and fall through to PATH 2 (BAPI_GOODSMVT_CREATE)
        IF ls_es_message-msgid IS NOT INITIAL AND ls_es_message-msgty CA 'EAX'.
          MESSAGE ID ls_es_message-msgid TYPE ls_es_message-msgty NUMBER ls_es_message-msgno
            WITH ls_es_message-msgv1 ls_es_message-msgv2 ls_es_message-msgv3 ls_es_message-msgv4
            INTO lv_last_error.
        ENDIF.
        IF lv_last_error IS INITIAL.
          LOOP AT et_messages INTO DATA(ls_err_msg) WHERE msgty CA 'EAX'.
            MESSAGE ID ls_err_msg-msgid TYPE ls_err_msg-msgty NUMBER ls_err_msg-msgno
              WITH ls_err_msg-msgv1 ls_err_msg-msgv2 ls_err_msg-msgv3 ls_err_msg-msgv4
              INTO lv_last_error.
            EXIT.
          ENDLOOP.
        ENDIF.
        me->log_application_message(
          iv_doc_num = is_header-doc_num
          iv_exidv   = is_hu_info-exidv
          iv_msgty   = 'W'
          iv_text    = |HU move failed: { lv_last_error }. Falling back to BAPI_GOODSMVT_CREATE.|
        ).
      ENDIF.
    ENDIF.

    " -------------------------------------------------------------
    " PATH 2: BAPI_GOODSMVT_CREATE
    " Handles:
    "  - Standard Reservation / TR movements
    "  - Fallback from Path 1 if HU movement returned L9 610
    " -------------------------------------------------------------
    IF lv_im_posted = abap_false.
      DATA: ls_gm_header TYPE bapi2017_gm_head_01,
            ls_gm_code   TYPE bapi2017_gm_code,
            lt_gm_items  TYPE TABLE OF bapi2017_gm_item_create,
            ls_gm_item   TYPE bapi2017_gm_item_create,
            lt_gm_serial TYPE TABLE OF bapi2017_gm_serialnumber,
            ls_gm_serial TYPE bapi2017_gm_serialnumber,
            lt_gm_return TYPE TABLE OF bapiret2.

      DATA: lv_bwart_post TYPE bwart.
      lv_bwart_post = COND #( WHEN is_header-bwart IS NOT INITIAL THEN is_header-bwart ELSE '311' ).

      ls_gm_header-pstng_date = sy-datum.
      ls_gm_header-doc_date   = sy-datum.
      ls_gm_header-pr_uname   = sy-uname.
      ls_gm_header-header_txt = COND #(
        WHEN lv_tr_target IS NOT INITIAL THEN |TR:{ lv_tr_target }|
        ELSE |RF-HU:{ is_hu_info-exidv }|
      ).
      ls_gm_header-ref_doc_no = COND #(
        WHEN is_header-doc_type = 'RES' THEN is_header-doc_num
        ELSE lv_tr_target
      ).

      ls_gm_code-gm_code = COND #(
        WHEN lv_bwart_post = '311' THEN '04'
        ELSE '03'
      ).

      ls_gm_item-material   = is_hu_info-matnr.
      ls_gm_item-plant      = is_hu_info-werks.
      ls_gm_item-stge_loc   = is_hu_info-lgort.
      ls_gm_item-batch      = is_hu_info-charg.
      ls_gm_item-move_type  = lv_bwart_post.
      ls_gm_item-entry_qnt  = lv_post_qty.
      ls_gm_item-entry_uom  = is_hu_info-meins.
      ls_gm_item-item_text  = |TR:{ lv_tr_target } Pos:{ is_item-tbpos }|.

      IF lv_bwart_post = '311'.
        ls_gm_item-move_plant = lv_dest_werks.
        ls_gm_item-move_batch = is_hu_info-charg.
        IF lv_src_xhupf <> lv_dest_xhupf AND lv_dest_xhupf = 'X' AND lv_dest_parlg IS NOT INITIAL.
          ls_gm_item-move_stloc = lv_dest_parlg.
        ELSE.
          ls_gm_item-move_stloc = lv_dest_lgort.
        ENDIF.
      ENDIF.

      " If not mixed HU, reference reservation directly
      IF is_header-doc_type = 'RES' AND ( lv_src_xhupf = lv_dest_xhupf OR lv_dest_xhupf <> 'X' ).
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
      IF is_item-is_serialized = abap_true.
        IF is_hu_info-serials IS NOT INITIAL.
          LOOP AT is_hu_info-serials INTO DATA(lv_sernr).
            CLEAR ls_gm_serial.
            ls_gm_serial-matdoc_itm = 1.
            ls_gm_serial-serialno   = lv_sernr.
            APPEND ls_gm_serial TO lt_gm_serial.
          ENDLOOP.
        ELSE.
          SELECT e~sernr
            FROM equi AS e
            INNER JOIN eqbs AS b ON b~equnr = e~equnr
            WHERE e~matnr = @is_hu_info-matnr
              AND b~b_werk = @is_hu_info-werks
              AND b~b_lager = @is_hu_info-lgort
            ORDER BY e~sernr
            INTO TABLE @DATA(lt_auto_ser)
            UP TO @lv_post_qty ROWS.
          LOOP AT lt_auto_ser INTO DATA(ls_ser_line).
            CLEAR ls_gm_serial.
            ls_gm_serial-matdoc_itm = 1.
            ls_gm_serial-serialno   = ls_ser_line-sernr.
            APPEND ls_gm_serial TO lt_gm_serial.
          ENDLOOP.
        ENDIF.
      ENDIF.

      CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
        EXPORTING
          goodsmvt_header       = ls_gm_header
          goodsmvt_code         = ls_gm_code
        IMPORTING
          materialdocument      = lv_mblnr
          matdocumentyear       = lv_mjahr
        TABLES
          goodsmvt_item         = lt_gm_items
          goodsmvt_serialnumber = lt_gm_serial
          return                = lt_gm_return.

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

      IF lv_mblnr IS NOT INITIAL.
        lv_im_posted = abap_true.
      ENDIF.
    ENDIF.

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
    DATA: lv_final_dest_lgtyp TYPE lgtyp,
          lv_final_dest_lgpla TYPE lgpla.

    me->determine_destination_bin(
      EXPORTING
        iv_lgnum        = is_header-lgnum
        iv_werks        = is_header-werks
        iv_dest_lgort   = lv_dest_lgort
        iv_matnr        = is_hu_info-matnr
        iv_source_lgtyp = is_hu_info-lgtyp
        iv_source_lgpla = is_hu_info-lgpla
      IMPORTING
        ev_dest_lgtyp   = lv_final_dest_lgtyp
        ev_dest_lgpla   = lv_final_dest_lgpla
    ).

    " 1. Priority 1: Check if a Posting Change Notice (PCN) was generated in LUBU
    DATA: lv_pcn_ubnum TYPE ubnum.
    SELECT SINGLE ubnum FROM lubu INTO @lv_pcn_ubnum
      WHERE mblnr = @lv_mblnr AND mjahr = @lv_mjahr.
    IF sy-subrc = 0 AND lv_pcn_ubnum IS NOT INITIAL.
      CALL FUNCTION 'L_TO_CREATE_POSTING_CHANGE'
        EXPORTING
          i_lgnum       = is_header-lgnum
          i_ubnum       = lv_pcn_ubnum
          i_squit       = 'X'
          i_commit_work = ' '
        TABLES
          t_ltak        = lt_ltak
          t_ltap_vb     = lt_ltap
        EXCEPTIONS
          OTHERS        = 1.
      IF sy-subrc = 0 AND lt_ltak IS NOT INITIAL.
        lv_tanum = lt_ltak[ 1 ]-tanum.
      ENDIF.
    ENDIF.

    " 2. Priority 2: Check if TR exists or was generated for the reservation
    IF lv_tanum IS INITIAL.
      IF lv_tr_target IS INITIAL.
        SELECT SINGLE tbnum FROM ltbk INTO @lv_tr_target
          WHERE lgnum = @is_header-lgnum AND mblnr = @lv_mblnr AND mjahr = @lv_mjahr.
      ENDIF.

      IF lv_tr_target IS NOT INITIAL.
        CLEAR ls_trite.
        ls_trite-tbpos = COND #( WHEN is_item-tbpos IS NOT INITIAL THEN is_item-tbpos ELSE 1 ).
        ls_trite-anfme = lv_post_qty.
        ls_trite-altme = is_hu_info-meins.
        ls_trite-charg = is_hu_info-charg.
        ls_trite-vltyp = is_hu_info-lgtyp.
        ls_trite-vlpla = is_hu_info-lgpla.
        ls_trite-vlenr = is_hu_info-lenum.
        ls_trite-nltyp = '921'.
        ls_trite-nlpla = 'TRANSFER'.
        APPEND ls_trite TO lt_trite.

        CALL FUNCTION 'L_TO_CREATE_TR'
          EXPORTING
            i_lgnum        = is_header-lgnum
            i_tbnum        = lv_tr_target
            it_trite       = lt_trite
            i_squit        = ' '                  " Immediate confirmation not allowed for 311 in W01
            i_commit_work  = 'X'
            i_bname        = sy-uname
          IMPORTING
            e_tanum        = lv_tanum
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
        IF lv_wm_subrc = 0 AND ( lv_tanum IS NOT INITIAL OR lt_ltak IS NOT INITIAL ).
          IF lv_tanum IS INITIAL AND lt_ltak IS NOT INITIAL.
            lv_tanum = lt_ltak[ 1 ]-tanum.
          ENDIF.

          " Confirm the TO immediately to adjust LX02
          DATA: lt_ltap_conf TYPE TABLE OF ltap_conf,
                ls_ltap_conf TYPE ltap_conf.
          LOOP AT lt_ltap INTO DATA(ls_vb).
            CLEAR ls_ltap_conf.
            ls_ltap_conf-tanum = ls_vb-tanum.
            ls_ltap_conf-tapos = ls_vb-tapos.
            ls_ltap_conf-squit = 'X'.
            APPEND ls_ltap_conf TO lt_ltap_conf.
          ENDLOOP.

          CALL FUNCTION 'L_TO_CONFIRM'
            EXPORTING
              i_lgnum             = is_header-lgnum
              i_tanum             = lv_tanum
              i_squit             = ' '
              i_commit_work       = 'X'
            TABLES
              t_ltap_conf         = lt_ltap_conf
            EXCEPTIONS
              to_confirmed        = 1
              to_doesnt_exist     = 2
              item_confirmed      = 3
              squit_or_quantities = 4
              OTHERS              = 5.
        ENDIF.
      ENDIF.
    ENDIF.

    " 3. Priority 3: Storage Unit Move (L_TO_CREATE_MOVE_SU) if SU is intact
    IF lv_tanum IS INITIAL AND is_hu_info-lenum IS NOT INITIAL.
      CALL FUNCTION 'L_TO_CREATE_MOVE_SU'
        EXPORTING
          i_lenum       = is_hu_info-lenum
          i_bwlvs       = '999'
          i_nltyp       = lv_final_dest_lgtyp
          i_nlpla       = lv_final_dest_lgpla
          i_squit       = 'X'
          i_commit_work = ' '
        IMPORTING
          e_tanum       = lv_tanum
        TABLES
          t_ltak        = lt_ltak
          t_ltap_vb     = lt_ltap
        EXCEPTIONS
          OTHERS        = 1.
    ENDIF.

    " 4. Priority 4: Direct single TO creation (L_TO_CREATE_SINGLE)
    IF lv_tanum IS INITIAL.
      DATA: lv_bwlvs_use TYPE bwlvs VALUE '999'.
      IF is_header-bwart IS NOT INITIAL.
        SELECT SINGLE bwlvs FROM t333 INTO @DATA(lv_t333_chk)
          WHERE lgnum = @is_header-lgnum AND bwlvs = @is_header-bwart.
        IF sy-subrc = 0.
          lv_bwlvs_use = is_header-bwart.
        ENDIF.
      ENDIF.

      CALL FUNCTION 'L_TO_CREATE_SINGLE'
        EXPORTING
          i_lgnum       = is_header-lgnum
          i_bwlvs       = lv_bwlvs_use
          i_matnr       = is_hu_info-matnr
          i_werks       = is_hu_info-werks
          i_lgort       = COND #( WHEN is_hu_info-lgort IS NOT INITIAL THEN is_hu_info-lgort ELSE lv_dest_lgort )
          i_charg       = is_hu_info-charg
          i_anfme       = lv_post_qty
          i_altme       = is_hu_info-meins
          i_vltyp       = is_hu_info-lgtyp
          i_vlpla       = is_hu_info-lgpla
          i_vlenr       = is_hu_info-lenum
          i_nltyp       = lv_final_dest_lgtyp
          i_nlpla       = lv_final_dest_lgpla
          i_squit       = 'X'                  " Confirm immediately
          i_commit_work = ' '
          i_bname       = sy-uname
        IMPORTING
          e_tanum       = lv_tanum
        TABLES
          t_ltak        = lt_ltak
          t_ltap_vb     = lt_ltap
        EXCEPTIONS
          no_to_created = 1
          foreign_lock  = 2
          OTHERS        = 3.
      lv_wm_subrc = sy-subrc.
    ENDIF.

    " -------------------------------------------------------------
    " STEP C: LUW MANAGEMENT & COMPENSATORY ROLLBACK
    " Zero Orphan Stock in 9xx Interim Storage Types
    " -------------------------------------------------------------
    IF lv_tanum IS INITIAL.
      IF lv_mblnr IS NOT INITIAL.
        " If TO creation failed after IM was posted, rollback IM to guarantee zero orphan stock in 922/921
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

        rs_result-rf_message = |WM TO Failed (rc={ lv_wm_subrc }). IM { lv_mblnr } Reversed.|.
        me->log_application_message(
          iv_doc_num = is_header-doc_num
          iv_exidv   = is_hu_info-exidv
          iv_msgty   = 'E'
          iv_text    = |WM TO Failed (rc={ lv_wm_subrc }). MIGO { lv_mblnr } reversed automatically.|
          it_return  = lt_cancel_return
        ).
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        rs_result-rf_message = |WM TO Failed (rc={ lv_wm_subrc }).|.
        me->log_application_message(
          iv_doc_num = is_header-doc_num
          iv_exidv   = is_hu_info-exidv
          iv_msgty   = 'E'
          iv_text    = |WM TO Failed (rc={ lv_wm_subrc }).|
        ).
      ENDIF.

      rs_result-success    = abap_false.
      rs_result-mblnr      = space.
      rs_result-mjahr      = space.
      RETURN.
    ENDIF.

    " Update reservation and all linked TR items and headers
    me->update_reservation_and_tr(
      is_header   = is_header
      is_item     = is_item
      iv_post_qty = lv_post_qty
      iv_mblnr    = lv_mblnr
      iv_mjahr    = lv_mjahr
    ).

    " Both IM and WM Successful: Commit the LUW
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.

    rs_result-success    = abap_true.
    rs_result-mblnr      = lv_mblnr.
    rs_result-mjahr      = lv_mjahr.
    rs_result-tanum      = lv_tanum.
    rs_result-dest_lgtyp = lv_final_dest_lgtyp.
    rs_result-dest_lgpla = lv_final_dest_lgpla.
    rs_result-rf_message = |MIGO:{ lv_mblnr } TO:{ lv_tanum } TR:{ lv_tr_target }|.
    APPEND is_hu_info-exidv TO mt_scanned_hus.
    IF is_hu_info-lenum IS NOT INITIAL AND is_hu_info-lenum <> is_hu_info-exidv.
      APPEND is_hu_info-lenum TO mt_scanned_hus.
    ENDIF.

    " Persist to INDX cluster database for this single reservation/TR
    IF is_header-doc_num IS NOT INITIAL.
      DATA: lv_std_p_alpha TYPE char10,
            lv_std_p_indx  TYPE indx-srtfd,
            lt_std_p_hus   TYPE tt_exidv.
      lv_std_p_alpha = |{ is_header-doc_num ALPHA = IN }|.
      lv_std_p_indx  = |ZRF_RES_{ lv_std_p_alpha }|.
      TRY.
          IMPORT scanned_hus = lt_std_p_hus FROM DATABASE indx(rf) ID lv_std_p_indx.
        CATCH cx_root.
      ENDTRY.
      APPEND is_hu_info-exidv TO lt_std_p_hus.
      IF is_hu_info-lenum IS NOT INITIAL.
        APPEND is_hu_info-lenum TO lt_std_p_hus.
      ENDIF.
      SORT lt_std_p_hus.
      DELETE ADJACENT DUPLICATES FROM lt_std_p_hus.
      TRY.
          EXPORT scanned_hus = lt_std_p_hus TO DATABASE indx(rf) ID lv_std_p_indx.
        CATCH cx_root.
      ENDTRY.
    ENDIF.

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
          lv_tbnum_lead TYPE tbnum,
          lv_rspos_lead TYPE rspos.

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

    IF is_item-tbnum IS NOT INITIAL.
      SELECT SINGLE rspos FROM ltbp INTO @DATA(lv_tr_rspos)
        WHERE lgnum = @is_header-lgnum AND tbnum = @is_item-tbnum AND tbpos = @is_item-tbpos.
      IF sy-subrc = 0 AND lv_tr_rspos IS NOT INITIAL.
        lv_rspos_lead = lv_tr_rspos.
      ENDIF.
    ENDIF.

    IF lv_rspos_lead IS INITIAL AND is_item-item_no IS NOT INITIAL.
      lv_rspos_lead = CONV rspos( is_item-item_no ).
    ENDIF.

    DATA: lv_is_res_closed TYPE abap_bool VALUE abap_false.

    IF lv_rsnum_lead IS NOT INITIAL AND lv_rspos_lead IS NOT INITIAL.
      SELECT SINGLE bdmng, enmng FROM resb INTO (@DATA(lv_bdmng), @DATA(lv_enmng))
        WHERE rsnum = @lv_rsnum_lead AND rspos = @lv_rspos_lead.
      IF sy-subrc = 0.
        DATA(lv_new_enmng) = lv_enmng + iv_post_qty.
        DATA(lv_kzear) = COND char1( WHEN lv_new_enmng >= lv_bdmng THEN 'X' ELSE space ).
        IF lv_kzear = 'X'.
          lv_is_res_closed = abap_true.
        ENDIF.
        UPDATE resb SET enmng = @lv_new_enmng, kzear = @lv_kzear
          WHERE rsnum = @lv_rsnum_lead AND rspos = @lv_rspos_lead.
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
          AND ( p~rspos = @lv_rspos_lead OR p~matnr = @is_item-matnr ).
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
    out->write( |--- ZCL_RF_AUTO_WM_IM_TRANSFER Status Check ---| ).

    DATA: ls_header TYPE ty_rf_doc_header,
          lt_items  TYPE tt_rf_doc_item,
          lt_ret    TYPE bapiret2_t.

    " 1. Check TR 0001000918
    me->get_document_details(
      EXPORTING
        iv_lgnum    = 'W01'
        iv_doc_type = 'TR'
        iv_doc_num  = '0001000918'
      IMPORTING
        es_header   = ls_header
        et_items    = lt_items
        et_return   = lt_ret
    ).
    out->write( |TR 0001000918: Header doc_num={ ls_header-doc_num } bwart={ ls_header-bwart } items={ lines( lt_items ) }| ).
    LOOP AT lt_items INTO DATA(ls_it).
      out->write( |Item { ls_it-item_no }: matnr={ ls_it-matnr } target={ ls_it-target_qty } picked={ ls_it-picked_qty } open={ ls_it-open_qty }| ).
    ENDLOOP.

    " 2. Check Reservation 0000534044
    me->get_document_details(
      EXPORTING
        iv_lgnum    = 'W01'
        iv_doc_type = 'RES'
        iv_doc_num  = '0000534044'
      IMPORTING
        es_header   = ls_header
        et_items    = lt_items
        et_return   = lt_ret
    ).
    out->write( |RES 0000534044: Header doc_num={ ls_header-doc_num } bwart={ ls_header-bwart } items={ lines( lt_items ) }| ).
    LOOP AT lt_items INTO DATA(ls_rit).
      out->write( |Item { ls_rit-item_no }: matnr={ ls_rit-matnr } target={ ls_rit-target_qty } picked={ ls_rit-picked_qty } open={ ls_rit-open_qty }| ).
    ENDLOOP.

    " 3. Check Duplicate Scan Protection for SU 59692 & 59693
    DATA(lv_already_92) = me->is_hu_already_scanned(
      iv_exidv   = '00000000001000059692'
      iv_doc_num = '0000534044'
    ).
    out->write( |SU 59692 Duplicate Scanned Check: { lv_already_92 }| ).

    DATA(lv_already_93) = me->is_hu_already_scanned(
      iv_exidv   = '00000000001000059693'
      iv_doc_num = '0000534044'
    ).
    out->write( |SU 59693 Duplicate Scanned Check: { lv_already_93 }| ).
  ENDMETHOD.

  METHOD is_hu_already_scanned.
    rv_scanned = abap_false.
    CHECK iv_exidv IS NOT INITIAL.

    DATA: lv_raw       TYPE exidv,
          lv_stripped  TYPE exidv,
          lv_pad20     TYPE exidv,
          lv_pad10     TYPE exidv,
          lv_alpha_doc TYPE char10.

    lv_raw = iv_exidv.
    CONDENSE lv_raw NO-GAPS.
    lv_stripped = lv_raw.
    SHIFT lv_stripped LEFT DELETING LEADING ' 0'.
    lv_pad20 = |{ lv_stripped ALPHA = IN }|.
    lv_pad10 = |{ lv_stripped ALPHA = IN }|.
    lv_alpha_doc = |{ iv_doc_num ALPHA = IN }|.

    " 1. Check in-memory session table of scanned/posted HUs
    LOOP AT mt_scanned_hus INTO DATA(lv_prev_hu).
      DATA: lv_prev_raw   TYPE exidv,
            lv_prev_strip TYPE exidv,
            lv_prev_pad20 TYPE exidv,
            lv_prev_pad10 TYPE exidv.

      lv_prev_raw = lv_prev_hu.
      CONDENSE lv_prev_raw NO-GAPS.
      lv_prev_strip = lv_prev_raw.
      SHIFT lv_prev_strip LEFT DELETING LEADING ' 0'.
      lv_prev_pad20 = |{ lv_prev_strip ALPHA = IN }|.
      lv_prev_pad10 = |{ lv_prev_strip ALPHA = IN }|.

      IF lv_raw = lv_prev_raw OR lv_stripped = lv_prev_strip
         OR lv_pad20 = lv_prev_pad20 OR lv_pad10 = lv_prev_pad10.
        rv_scanned = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

    IF iv_doc_num IS NOT INITIAL.
      " 2. Check Database cluster INDX(rf) for this reservation
      DATA: lt_clust_hus TYPE tt_exidv,
            lv_indx_id   TYPE indx-srtfd.
      lv_indx_id = |ZRF_RES_{ lv_alpha_doc }|.
      TRY.
          IMPORT scanned_hus = lt_clust_hus FROM DATABASE indx(rf) ID lv_indx_id.
          LOOP AT lt_clust_hus INTO DATA(lv_c_hu).
            DATA: lv_c_raw   TYPE exidv,
                  lv_c_strip TYPE exidv,
                  lv_c_pad20 TYPE exidv,
                  lv_c_pad10 TYPE exidv.
            lv_c_raw = lv_c_hu.
            CONDENSE lv_c_raw NO-GAPS.
            lv_c_strip = lv_c_raw.
            SHIFT lv_c_strip LEFT DELETING LEADING ' 0'.
            lv_c_pad20 = |{ lv_c_strip ALPHA = IN }|.
            lv_c_pad10 = |{ lv_c_strip ALPHA = IN }|.

            IF lv_raw = lv_c_raw OR lv_stripped = lv_c_strip
               OR lv_pad20 = lv_c_pad20 OR lv_pad10 = lv_c_pad10.
              rv_scanned = abap_true.
              APPEND iv_exidv TO mt_scanned_hus.
              RETURN.
            ENDIF.
          ENDLOOP.
        CATCH cx_root.
      ENDTRY.

      " 3. Check LE-WM Transfer Orders created for this reservation/TR
      SELECT SINGLE @abap_true
        FROM ltbk AS k
        INNER JOIN ltak AS a ON a~lgnum = k~lgnum AND a~tbnum = k~tbnum
        INNER JOIN ltap AS p ON p~lgnum = a~lgnum AND p~tanum = a~tanum
        INTO @DATA(lv_found_ltap)
        WHERE ( k~rsnum = @lv_alpha_doc OR k~rsnum = @iv_doc_num
             OR ( k~betyp = 'P' AND ( k~benum = @lv_alpha_doc OR k~benum = @iv_doc_num ) ) )
          AND ( p~vlenr = @lv_raw OR p~vlenr = @lv_pad20 OR p~vlenr = @lv_pad10 OR p~vlenr = @lv_stripped
             OR p~nlenr = @lv_raw OR p~nlenr = @lv_pad20 OR p~nlenr = @lv_pad10 OR p~nlenr = @lv_stripped ).
      IF lv_found_ltap = abap_true.
        rv_scanned = abap_true.
        APPEND iv_exidv TO mt_scanned_hus.
        RETURN.
      ENDIF.

      " 5. Check Serial numbers / OBJK posted in goods movement for this reservation
      SELECT SINGLE @abap_true
        FROM mseg AS m
        INNER JOIN ser03 AS s ON s~mblnr = m~mblnr AND s~mjahr = m~mjahr
        INNER JOIN objk AS o ON o~obknr = s~obknr
        INTO @DATA(lv_found_ser)
        WHERE ( m~rsnum = @lv_alpha_doc OR m~rsnum = @iv_doc_num )
          AND ( o~sernr = @lv_raw OR o~sernr = @lv_pad20 OR o~sernr = @lv_stripped ).
      IF lv_found_ser = abap_true.
        rv_scanned = abap_true.
        APPEND iv_exidv TO mt_scanned_hus.
        RETURN.
      ENDIF.

      " 6. Check Material Documents posted with this HU in header text (MKPF)
      DATA: lv_like_clean TYPE bktxt,
            lv_like_raw   TYPE bktxt,
            lv_like_strip TYPE bktxt.
      lv_like_clean = |%{ lv_pad20 }%|.
      lv_like_raw   = |%{ lv_raw }%|.
      lv_like_strip = |%{ lv_stripped }%|.

      SELECT SINGLE @abap_true
        FROM mseg AS m
        INNER JOIN mkpf AS k ON k~mblnr = m~mblnr AND k~mjahr = m~mjahr
        INTO @DATA(lv_found_mseg)
        WHERE ( m~rsnum = @lv_alpha_doc OR m~rsnum = @iv_doc_num )
          AND ( k~bktxt LIKE @lv_like_clean OR k~bktxt LIKE @lv_like_raw OR k~bktxt LIKE @lv_like_strip ).
      IF lv_found_mseg = abap_true.
        rv_scanned = abap_true.
        APPEND iv_exidv TO mt_scanned_hus.
        RETURN.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
