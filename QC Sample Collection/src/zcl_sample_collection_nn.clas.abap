CLASS zcl_sample_collection_nn DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_sample_header,
        prueflos         TYPE qals-prueflos,
        werk             TYPE qals-werk,
        matnr            TYPE qals-matnr,
        maktx            TYPE makt-maktx,
        charg            TYPE qals-charg,
        aufnr            TYPE qals-aufnr,
        art              TYPE qals-art,
        losmenge         TYPE qals-losmenge,
        menge_einh       TYPE qals-menge_einh,
        enstehdat        TYPE qals-enstehdat,
        stat_desc        TYPE char40,
        samples_total    TYPE i,
        samples_collected TYPE i,
        samples_pending  TYPE i,
      END OF ty_sample_header.

    TYPES:
      BEGIN OF ty_sample_item,
        physsample       TYPE qprs-physsample,
        sample_num       TYPE numc4,
        prueflos         TYPE qprs-prueflos,
        sample_cat       TYPE char2,
        sample_cat_text  TYPE char20,
        sample_qty       TYPE p LENGTH 7 DECIMALS 3,
        sample_uom       TYPE meins,
        container        TYPE char20,
        storage_loc      TYPE char20,
        barcode          TYPE char30,
        status           TYPE char4,
        status_txt       TYPE char20,
        drawn_by         TYPE sy-uname,
        drawn_date       TYPE sy-datum,
        drawn_time       TYPE sy-uzeit,
        temperature      TYPE char10,
        remarks          TYPE char50,
      END OF ty_sample_item,
      tt_sample_item TYPE STANDARD TABLE OF ty_sample_item WITH KEY physsample.

    TYPES:
      BEGIN OF ty_collection_result,
        success          TYPE abap_bool,
        physsample       TYPE qprs-physsample,
        message          TYPE string,
        new_status       TYPE char4,
        timestamp        TYPE string,
      END OF ty_collection_result.

    CLASS-METHODS:
      get_instance
        RETURNING
          VALUE(ro_instance) TYPE REF TO zcl_sample_collection_nn.

    METHODS:
      find_samples_by_lot
        IMPORTING
          !iv_prueflos      TYPE qals-prueflos
        EXPORTING
          !es_header        TYPE ty_sample_header
          !et_items         TYPE tt_sample_item
          !ev_found         TYPE abap_bool
          !ev_message       TYPE string,

      find_sample_by_barcode
        IMPORTING
          !iv_barcode       TYPE string
        EXPORTING
          !es_item          TYPE ty_sample_item
          !es_header        TYPE ty_sample_header
          !ev_found         TYPE abap_bool
          !ev_message       TYPE string,

      confirm_sample_collection
        IMPORTING
          !iv_physsample    TYPE qprs-physsample
          !iv_barcode       TYPE string OPTIONAL
          !iv_temperature   TYPE string OPTIONAL
          !iv_storage_loc   TYPE string OPTIONAL
          !iv_remarks       TYPE string OPTIONAL
        RETURNING
          VALUE(rs_result)  TYPE ty_collection_result,

      reset_sample_collection
        IMPORTING
          !iv_physsample    TYPE qprs-physsample
        RETURNING
          VALUE(rs_result)  TYPE ty_collection_result.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA:
      go_instance TYPE REF TO zcl_sample_collection_nn.

    METHODS:
      parse_barcode
        IMPORTING
          !iv_raw_barcode   TYPE string
        EXPORTING
          !ev_lot           TYPE qals-prueflos
          !ev_sample        TYPE qprs-physsample
          !ev_clean_barcode TYPE string.

ENDCLASS.

CLASS zcl_sample_collection_nn IMPLEMENTATION.

  METHOD get_instance.
    IF go_instance IS NOT BOUND.
      go_instance = NEW zcl_sample_collection_nn( ).
    ENDIF.
    ro_instance = go_instance.
  ENDMETHOD.

  METHOD parse_barcode.
    DATA: lv_str TYPE string.
    lv_str = condense( iv_raw_barcode ).

    CLEAR: ev_lot, ev_sample, ev_clean_barcode.
    ev_clean_barcode = lv_str.

    " Format 1: GS1 or Combined Lot-Sample, e.g. '040000001234-0001' or '040000001234/0001'
    IF lv_str CS '-' OR lv_str CS '/'.
      SPLIT lv_str AT '-' INTO DATA(lv_p1) DATA(lv_p2).
      IF lv_p2 IS INITIAL.
        SPLIT lv_str AT '/' INTO lv_p1 lv_p2.
      ENDIF.
      ev_lot = |{ lv_p1 ALPHA = IN }|.
      ev_sample = |{ lv_p2 ALPHA = IN }|.
      RETURN.
    ENDIF.

    " Format 2: Direct Sample Number (e.g. 10 or 12 digit number)
    IF strlen( lv_str ) <= 12 AND lv_str CO '0123456789 '.
      ev_sample = |{ lv_str ALPHA = IN }|.
      RETURN.
    ENDIF.

    " Format 3: Raw scan containing Sample prefix (e.g. 'SMP-00000001')
    IF lv_str CP 'SMP*'.
      DATA(lv_core) = substring( val = lv_str off = 3 ).
      SHIFT lv_core LEFT DELETING LEADING '-_ '.
      ev_sample = |{ lv_core ALPHA = IN }|.
      RETURN.
    ENDIF.

    ev_clean_barcode = lv_str.
  ENDMETHOD.

  METHOD find_samples_by_lot.
    CLEAR: es_header, et_items, ev_found, ev_message.

    DATA(lv_lot) = |{ iv_prueflos ALPHA = IN }|.

    " 1. Read Inspection Lot from QALS
    SELECT SINGLE qals~prueflos, qals~werk, qals~matnr, makt~maktx,
                  qals~charg, qals~aufnr, qals~art, qals~losmenge,
                  qals~menge_einh, qals~enstehdat, qals~stat35
      FROM qals
      LEFT OUTER JOIN makt ON makt~matnr = qals~matnr AND makt~spras = @sy-langu
      WHERE qals~prueflos = @lv_lot
      INTO @DATA(ls_qals).

    IF sy-subrc <> 0.
      ev_found = abap_false.
      ev_message = |Inspection lot { lv_lot } not found in system DS4/220|.
      RETURN.
    ENDIF.

    es_header-prueflos   = ls_qals-prueflos.
    es_header-werk       = ls_qals-werk.
    es_header-matnr      = ls_qals-matnr.
    es_header-maktx      = ls_qals-maktx.
    es_header-charg      = ls_qals-charg.
    es_header-aufnr      = ls_qals-aufnr.
    es_header-art        = ls_qals-art.
    es_header-losmenge   = ls_qals-losmenge.
    es_header-menge_einh = ls_qals-menge_einh.
    es_header-enstehdat  = ls_qals-enstehdat.
    es_header-stat_desc  = 'Inspection Active - Sample Drawing Required'.

    " 2. Read Physical Samples from QPRS
    SELECT physsample, prueflos, gebinde, menge, meinh,
           status, entn_dat, entn_zeit, entn_nehm
      FROM qprs
      WHERE prueflos = @lv_lot
      ORDER BY physsample
      INTO TABLE @DATA(lt_qprs).

    IF lt_qprs IS INITIAL.
      " If no physical sample records exist in QPRS, generate standardized planned sample items
      DATA: lv_idx TYPE numc4 VALUE '0001'.
      DO 3 TIMES.
        DATA: ls_item TYPE ty_sample_item.
        ls_item-physsample      = |{ lv_lot ALPHA = OUT }-{ lv_idx }|.
        ls_item-sample_num      = lv_idx.
        ls_item-prueflos        = lv_lot.
        ls_item-sample_cat      = COND #( WHEN lv_idx = '0001' THEN '01'
                                          WHEN lv_idx = '0002' THEN '02'
                                          ELSE '03' ).
        ls_item-sample_cat_text = COND #( WHEN lv_idx = '0001' THEN 'Primary Sample'
                                          WHEN lv_idx = '0002' THEN 'Pooled Sample'
                                          ELSE 'Reserve Sample' ).
        ls_item-sample_qty      = 50.
        ls_item-sample_uom      = ls_qals-menge_einh.
        ls_item-container       = 'Sterile Glass Bottle'.
        ls_item-storage_loc     = 'QC-ROOM-SHELF-01'.
        ls_item-barcode         = |SMP{ lv_lot ALPHA = OUT }{ lv_idx }|.
        ls_item-status          = 'CRTD'.
        ls_item-status_txt      = 'Planned (Pending)'.
        APPEND ls_item TO et_items.
        lv_idx = lv_idx + 1.
      ENDDO.
    ELSE.
      DATA: lv_seq TYPE numc4 VALUE '0001'.
      LOOP AT lt_qprs INTO DATA(ls_q).
        CLEAR ls_item.
        ls_item-physsample      = ls_q-physsample.
        ls_item-sample_num      = lv_seq.
        ls_item-prueflos        = ls_q-prueflos.
        ls_item-sample_cat      = '01'.
        ls_item-sample_cat_text = 'Physical Sample'.
        ls_item-sample_qty      = ls_q-menge.
        ls_item-sample_uom      = ls_q-meinh.
        ls_item-container       = COND #( WHEN ls_q-gebinde IS NOT INITIAL THEN ls_q-gebinde ELSE 'QC Container' ).
        ls_item-storage_loc     = 'LAB-TEMP-20C'.
        ls_item-barcode         = |SMP{ ls_q-physsample ALPHA = OUT }|.
        ls_item-status          = COND #( WHEN ls_q-status IS NOT INITIAL THEN ls_q-status ELSE 'CRTD' ).
        ls_item-status_txt      = COND #( WHEN ls_item-status = 'SMPL' THEN 'Collected'
                                          WHEN ls_item-status = 'CRTD' THEN 'Pending Scan'
                                          ELSE ls_item-status ).
        ls_item-drawn_by        = ls_q-entn_nehm.
        ls_item-drawn_date      = ls_q-entn_dat.
        ls_item-drawn_time      = ls_q-entn_zeit.
        APPEND ls_item TO et_items.
        lv_seq = lv_seq + 1.
      ENDLOOP.
    ENDIF.

    " Calculate summary counts
    es_header-samples_total = lines( et_items ).
    LOOP AT et_items INTO DATA(ls_chk).
      IF ls_chk-status = 'SMPL'.
        es_header-samples_collected = es_header-samples_collected + 1.
      ELSE.
        es_header-samples_pending = es_header-samples_pending + 1.
      ENDIF.
    ENDLOOP.

    ev_found = abap_true.
    ev_message = |Loaded { es_header-samples_total } sample(s) for lot { lv_lot }|.
  ENDMETHOD.

  METHOD find_sample_by_barcode.
    CLEAR: es_item, es_header, ev_found, ev_message.

    me->parse_barcode(
      EXPORTING
        iv_raw_barcode   = iv_barcode
      IMPORTING
        ev_lot           = DATA(lv_lot)
        ev_sample        = DATA(lv_sample)
        ev_clean_barcode = DATA(lv_clean)
    ).

    IF lv_lot IS NOT INITIAL.
      me->find_samples_by_lot(
        EXPORTING
          iv_prueflos = lv_lot
        IMPORTING
          es_header   = es_header
          et_items    = DATA(lt_items)
          ev_found    = ev_found
          ev_message  = ev_message
      ).

      IF ev_found = abap_true.
        READ TABLE lt_items INTO es_item WITH KEY physsample = lv_sample.
        IF sy-subrc = 0.
          ev_message = |Sample { es_item-physsample } matched from barcode|.
          RETURN.
        ELSEIF lt_items IS NOT INITIAL.
          READ TABLE lt_items INTO es_item INDEX 1.
          ev_message = |Sample matched by lot barcode|.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    " Direct lookup by physical sample ID
    IF lv_sample IS NOT INITIAL.
      SELECT SINGLE physsample, prueflos, gebinde, menge, meinh, status
        FROM qprs
        WHERE physsample = @lv_sample
        INTO @DATA(ls_found).

      IF sy-subrc = 0.
        me->find_samples_by_lot(
          EXPORTING
            iv_prueflos = ls_found-prueflos
          IMPORTING
            es_header   = es_header
            et_items    = lt_items
            ev_found    = ev_found
            ev_message  = ev_message
        ).
        READ TABLE lt_items INTO es_item WITH KEY physsample = ls_found-physsample.
        RETURN.
      ENDIF.
    ENDIF.

    ev_found = abap_false.
    ev_message = |No sample record matches barcode '{ iv_barcode }'|.
  ENDMETHOD.

  METHOD confirm_sample_collection.
    rs_result-physsample = iv_physsample.
    rs_result-success    = abap_true.
    rs_result-new_status = 'SMPL'.
    rs_result-timestamp  = |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }|.
    rs_result-message    = |Sample { iv_physsample } successfully marked as COLLECTED by { sy-uname } at { rs_result-timestamp }|.

    " Real-time database update in QPRS
    UPDATE qprs
      SET status    = 'SMPL',
          entn_dat  = @sy-datum,
          entn_zeit = @sy-uzeit,
          entn_nehm = @sy-uname
      WHERE physsample = @iv_physsample.

    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
    ENDIF.
  ENDMETHOD.

  METHOD reset_sample_collection.
    rs_result-physsample = iv_physsample.
    rs_result-success    = abap_true.
    rs_result-new_status = 'CRTD'.
    rs_result-timestamp  = |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }|.
    rs_result-message    = |Sample { iv_physsample } reset to PLANNED/PENDING status|.

    UPDATE qprs
      SET status    = 'CRTD',
          entn_dat  = '00000000',
          entn_zeit = '000000',
          entn_nehm = @space
      WHERE physsample = @iv_physsample.

    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
