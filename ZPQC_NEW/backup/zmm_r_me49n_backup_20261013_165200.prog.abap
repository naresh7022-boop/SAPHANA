*&---------------------------------------------------------------------*
*& Report ZMM_R_ME49N
*&---------------------------------------------------------------------*
*& Description : Interactive Price Comparison List & PO Creation (ZPQC_NEW)
*& Based on    : ZMM_R_079 / ZME49 layout with item-wise checkboxes and
*&               interactive Purchase Order creation via BAPI_PO_CREATE1.
*& Author      : NARESH
*& Date        : 13.10.2026
*& Version     : 2.3 (13.10.2026 16:40)
*& Change Log  :
*&   v1.0 (12.10.2026) - Initial interactive report & BAPI PO creation
*&   v2.0 (13.10.2026) - Modern HTML dashboard preview (ME47/ME23N links)
*&   v2.1 (13.10.2026) - Card layout styling & dynamic badges
*&   v2.2 (13.10.2026) - Full-width layout & grid borders
*&   v2.3 (13.10.2026) - High-density decision matrix: 0 wasted space,
*&                      compact 3-line quote cells, inline L1 badges,
*&                      crisp grid lines, sticky header, full screen width
*& System      : DS4 / 220
*&---------------------------------------------------------------------*
REPORT zmm_r_me49n.

TABLES: ekko, ekpo.

*----------------------------------------------------------------------*
* Global Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_hdr,
         ebeln TYPE ekko-ebeln,
         matnr TYPE ekpo-matnr,
         lifnr TYPE ekko-lifnr,
         name1 TYPE lfa1-name1,
         submi TYPE ekko-submi,
         ihrez TYPE ekko-ihrez,
         inco1 TYPE ekko-inco1,
         text1 TYPE t052u-text1,
         ztag1 TYPE t052-ztag1,
         waers TYPE ekko-waers,
         wkurs TYPE ekko-wkurs,
         bukrs TYPE ekko-bukrs,
         ekgrp TYPE ekko-ekgrp,
         ekorg TYPE ekko-ekorg,
         zterm TYPE ekko-zterm,
       END OF ty_hdr,

       BEGIN OF ty_rfq_item,
         ebeln TYPE ekko-ebeln,
         ebelp TYPE ekpo-ebelp,
         submi TYPE ekko-submi,
         ekorg TYPE ekko-ekorg,
         ekgrp TYPE ekko-ekgrp,
         bukrs TYPE ekko-bukrs,
         lifnr TYPE ekko-lifnr,
         name1 TYPE lfa1-name1,
         ihrez TYPE ekko-ihrez,
         inco1 TYPE ekko-inco1,
         waers TYPE ekko-waers,
         wkurs TYPE ekko-wkurs,
         zterm TYPE ekko-zterm,
         matnr TYPE ekpo-matnr,
         txz01 TYPE ekpo-txz01,
         ktmng TYPE ekpo-ktmng,
         menge TYPE ekpo-menge,
         meins TYPE ekpo-meins,
         netpr TYPE ekpo-netpr,
         peinh TYPE ekpo-peinh,
         netwr TYPE ekpo-netwr,
         werks TYPE ekpo-werks,
         ztag1 TYPE t052-ztag1,
         text1 TYPE t052u-text1,
       END OF ty_rfq_item,

       BEGIN OF ty_item_ref,
         matnr     TYPE ekpo-matnr,
         ebelp     TYPE ekpo-ebelp,
         txz01     TYPE ekpo-txz01,
         menge     TYPE ekpo-menge,
         meins     TYPE ekpo-meins,
         werks     TYPE ekpo-werks,
         bukrs     TYPE ekko-bukrs,
         ekorg     TYPE ekko-ekorg,
         ekgrp     TYPE ekko-ekgrp,
         submi     TYPE ekko-submi,
         l1_sel_col TYPE slis_fieldname,
         l1_ebeln  TYPE ekko-ebeln,
         l1_ebelp  TYPE ekpo-ebelp,
         l1_lifnr  TYPE ekko-lifnr,
         l1_name1  TYPE lfa1-name1,
         l1_netpr  TYPE ekpo-netpr,
         l1_peinh  TYPE ekpo-peinh,
         l1_waers  TYPE ekko-waers,
         l1_zterm  TYPE ekko-zterm,
         l1_inco1  TYPE ekko-inco1,
         sel_col   TYPE slis_fieldname,
         sel_ebeln TYPE ekko-ebeln,
         sel_ebelp TYPE ekpo-ebelp,
         sel_lifnr TYPE ekko-lifnr,
         sel_name1 TYPE lfa1-name1,
         sel_netpr TYPE ekpo-netpr,
         sel_peinh TYPE ekpo-peinh,
         sel_waers TYPE ekko-waers,
         sel_zterm TYPE ekko-zterm,
         sel_inco1 TYPE ekko-inco1,
         po_number TYPE ekko-ebeln,
       END OF ty_item_ref,

       BEGIN OF ty_final,
         sel(12)       TYPE c,         " '@01@ [X]' / '@R7@ [ ]' or '@01@ [X]All'
         matnr         TYPE mara-matnr,
         maktx         TYPE makt-maktx,
         quat(10)      TYPE c,
         quat1(40)     TYPE c,
         quat2(40)     TYPE c,
         quat3(40)     TYPE c,
         quat4(40)     TYPE c,
         quat5(40)     TYPE c,
         quat6(40)     TYPE c,
         quat7(40)     TYPE c,
         mean(15)      TYPE c,
         minimum(15)   TYPE c,
         po_action(30) TYPE c,         " Action button or Created PO Number
         color(4)      TYPE c,
         cell_colors   TYPE slis_t_specialcol_alv,
         ebelp         TYPE ekpo-ebelp, " Key reference to ty_item_ref
       END OF ty_final,

       BEGIN OF ty_rank,
         lifnr   TYPE lfa1-lifnr,
         amount  TYPE ekpo-netwr,
         amount1 TYPE ekpo-netwr,
       END OF ty_rank,

       BEGIN OF ty_vend_group,
         lifnr TYPE ekko-lifnr,
         name1 TYPE lfa1-name1,
         bukrs TYPE ekko-bukrs,
         ekorg TYPE ekko-ekorg,
         ekgrp TYPE ekko-ekgrp,
         zterm TYPE ekko-zterm,
         inco1 TYPE ekko-inco1,
       END OF ty_vend_group,

       ty_t_rfq_item TYPE STANDARD TABLE OF ty_rfq_item WITH DEFAULT KEY,
       ty_t_item_ref TYPE STANDARD TABLE OF ty_item_ref WITH DEFAULT KEY,
       ty_t_vendors  TYPE STANDARD TABLE OF ty_vend_group WITH DEFAULT KEY.


*----------------------------------------------------------------------*
* Global Controls & HTML Viewer
*----------------------------------------------------------------------*
DATA: go_docking TYPE REF TO cl_gui_docking_container,
      go_html    TYPE REF TO cl_gui_html_viewer.

CLASS lcl_html_handler DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS on_sapevent
      FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action frame getdata postdata query_table.
ENDCLASS.

*----------------------------------------------------------------------*
* Global Data
*----------------------------------------------------------------------*
DATA: gt_final     TYPE TABLE OF ty_final,
      gt_final1    TYPE TABLE OF ty_final,
      gt_hdr       TYPE TABLE OF ty_hdr,
      gt_rfq_items TYPE ty_t_rfq_item,
      gt_item_ref  TYPE TABLE OF ty_item_ref,
      lt_rank      TYPE STANDARD TABLE OF ty_rank,
      ls_rank     TYPE ty_rank,
      lv_amt      TYPE ekpo-netwr,
      lv_rank     TYPE i,
      ls_total    LIKE LINE OF gt_final,
      ls_interest LIKE LINE OF gt_final1,
      gs_val      LIKE LINE OF gt_final,
      gs_rank     LIKE LINE OF gt_final,
      gs_pkg      LIKE LINE OF gt_final,
      gs_app      LIKE LINE OF gt_final,
      lv_mean     TYPE ekpo-netpr,
      int_days    TYPE f VALUE '0.12',
      lv_result   TYPE ekpo-netpr,
      lv_val      TYPE ekpo-netwr.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
  SELECT-OPTIONS: s_ekorg FOR ekko-ekorg DEFAULT 'AE01',
                  s_ebeln FOR ekko-ebeln,
                  s_submi FOR ekko-submi NO INTERVALS NO-EXTENSION,
                  s_lifnr FOR ekko-lifnr,
                  s_matnr FOR ekpo-matnr.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE t_b2.
  PARAMETERS: p_bsart TYPE ekko-bsart DEFAULT 'NB',
              p_test  AS CHECKBOX DEFAULT ' '.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE t_b3.
  PARAMETERS: p_rate  TYPE p DECIMALS 2 DEFAULT '12.00',
              p_v_htm RADIOBUTTON GROUP grpv DEFAULT 'X',
              p_v_alv RADIOBUTTON GROUP grpv.
SELECTION-SCREEN END OF BLOCK b3.

*----------------------------------------------------------------------*
* Initialization
*----------------------------------------------------------------------*
INITIALIZATION.
  t_b1 = 'Selection Criteria'.
  t_b2 = 'PO Creation Settings'.
  t_b3 = 'Commercial & Design Settings'.
  %_s_ekorg_%_app_%-text = 'Purchasing Org.'.
  %_s_ebeln_%_app_%-text = 'Quotation / RFQ No.'.
  %_s_submi_%_app_%-text = 'Collective Number'.
  %_s_lifnr_%_app_%-text = 'Vendor / Supplier'.
  %_s_matnr_%_app_%-text = 'Material Number'.
  %_p_bsart_%_app_%-text = 'Target PO Doc Type'.
  %_p_test_%_app_%-text  = 'Simulation / Test Run'.
  %_p_rate_%_app_%-text  = 'Interest Rate (%)'.
  %_p_v_htm_%_app_%-text = 'Modern Dynamic HTML Dashboard'.
  %_p_v_alv_%_app_%-text = 'Classical ALV Matrix View'.

*----------------------------------------------------------------------*
* Selection Screen Output
*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  IF go_docking IS NOT INITIAL.
    go_docking->free( ).
    CLEAR go_docking.
  ENDIF.
  IF go_html IS NOT INITIAL.
    go_html->free( ).
    CLEAR go_html.
  ENDIF.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM get_data.

  IF cl_gui_alv_grid=>offline( ) <> 0 OR sy-batch IS NOT INITIAL.
    PERFORM display_batch_list.
  ELSEIF p_v_alv = abap_true.
    PERFORM display.
  ELSE.
    WRITE: space. " Initializes standard output screen and triggers TOP-OF-PAGE
    IF go_html IS INITIAL.
      PERFORM display_html.
    ENDIF.
  ENDIF.

*----------------------------------------------------------------------*
* Top of Page (List Output Screen)
*----------------------------------------------------------------------*
TOP-OF-PAGE.
  IF p_v_htm = abap_true AND cl_gui_alv_grid=>offline( ) = 0 AND sy-batch IS INITIAL.
    IF go_html IS INITIAL.
      PERFORM display_html.
    ENDIF.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
FORM get_data.

  SELECT FROM ekko
    INNER JOIN ekpo ON ekko~ebeln = ekpo~ebeln
    LEFT JOIN lfa1 ON ekko~lifnr = lfa1~lifnr
    LEFT JOIN t052u ON ekko~zterm = t052u~zterm AND t052u~spras = @sy-langu
    LEFT JOIN t052 ON ekko~zterm = t052~zterm
    FIELDS ekko~ebeln,
           ekko~submi,
           ekko~ekorg,
           ekko~ekgrp,
           ekko~bukrs,
           ekko~lifnr,
           ekko~ihrez,
           ekko~inco1,
           ekko~waers,
           ekko~wkurs,
           ekko~zterm,
           ekpo~ebelp,
           ekpo~matnr,
           ekpo~txz01,
           ekpo~ktmng,
           ekpo~menge,
           ekpo~meins,
           ekpo~netpr,
           ekpo~peinh,
           ekpo~netwr,
           ekpo~werks,
           lfa1~name1,
           t052~ztag1,
           t052u~text1
    WHERE ekko~bstyp = 'A'
      AND ekko~ebeln IN @s_ebeln
      AND ekko~submi IN @s_submi
      AND ekko~ekorg IN @s_ekorg
      AND ekko~lifnr IN @s_lifnr
      AND ekpo~matnr IN @s_matnr
      AND ekpo~loekz = @space
    INTO TABLE @DATA(it_data).

  IF it_data IS INITIAL.
    MESSAGE 'No data found for selection criteria.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Preserve all RFQ line items globally for interactive supplier switching
  CLEAR gt_rfq_items.
  gt_rfq_items = CORRESPONDING #( it_data ).

  LOOP AT gt_rfq_items ASSIGNING FIELD-SYMBOL(<fs_rfq_item>).
    IF <fs_rfq_item>-menge <= 0 AND <fs_rfq_item>-ktmng > 0.
      <fs_rfq_item>-menge = <fs_rfq_item>-ktmng.
    ENDIF.
    IF <fs_rfq_item>-menge <= 0.
      <fs_rfq_item>-menge = 1.
    ENDIF.
  ENDLOOP.

  " Collect Distinct Quotation Headers (Vendors)
  CLEAR gt_hdr.
  gt_hdr = VALUE #(
    FOR wa_data IN it_data (
      ebeln = wa_data-ebeln
      matnr = wa_data-matnr
      lifnr = wa_data-lifnr
      name1 = wa_data-name1
      submi = wa_data-submi
      ihrez = wa_data-ihrez
      inco1 = wa_data-inco1
      text1 = wa_data-text1
      ztag1 = wa_data-ztag1
      waers = wa_data-waers
      wkurs = wa_data-wkurs
      bukrs = wa_data-bukrs
      ekgrp = wa_data-ekgrp
      ekorg = wa_data-ekorg
      zterm = wa_data-zterm
    ) ).

  SORT gt_hdr BY lifnr ASCENDING.
  DELETE ADJACENT DUPLICATES FROM gt_hdr COMPARING lifnr.

  DATA(lv_count) = lines( gt_hdr ).
  IF lv_count = 0.
    lv_count = 1.
  ENDIF.

  " Check existing Purchase Orders for this collective group / quotation items
  TYPES: BEGIN OF ty_ex_po,
           ebeln TYPE ekpo-ebeln,
           ebelp TYPE ekpo-ebelp,
           matnr TYPE ekpo-matnr,
           anfnr TYPE ekpo-anfnr,
           anfps TYPE ekpo-anfps,
           bednr TYPE ekpo-bednr,
           lifnr TYPE ekko-lifnr,
           submi TYPE ekko-submi,
         END OF ty_ex_po.
  DATA: lt_existing_pos TYPE STANDARD TABLE OF ty_ex_po WITH DEFAULT KEY.
  CLEAR lt_existing_pos.

  DATA: lr_rfqs TYPE RANGE OF ekko-ebeln.
  lr_rfqs = VALUE #( FOR wa_rfq IN gt_hdr ( sign = 'I' option = 'EQ' low = wa_rfq-ebeln ) ).

  IF lr_rfqs IS NOT INITIAL.
    SELECT p~ebeln, p~ebelp, p~matnr, p~anfnr, p~anfps, p~bednr, k~lifnr, k~submi
      FROM ekpo AS p
      INNER JOIN ekko AS k ON p~ebeln = k~ebeln
      WHERE k~bstyp = 'F'
        AND p~loekz = @space
        AND ( ( p~anfnr IN @lr_rfqs AND p~anfnr <> @space )
           OR ( p~bednr IN @lr_rfqs AND p~bednr <> @space ) )
      ORDER BY p~ebeln DESCENDING
      INTO CORRESPONDING FIELDS OF TABLE @lt_existing_pos.
  ENDIF.

  IF s_submi IS NOT INITIAL.
    SELECT p~ebeln, p~ebelp, p~matnr, p~anfnr, p~anfps, p~bednr, k~lifnr, k~submi
      FROM ekpo AS p
      INNER JOIN ekko AS k ON p~ebeln = k~ebeln
      WHERE k~bstyp = 'F'
        AND p~loekz = @space
        AND k~submi IN @s_submi
        AND k~submi <> @space
      ORDER BY p~ebeln DESCENDING
      APPENDING CORRESPONDING FIELDS OF TABLE @lt_existing_pos.
  ENDIF.

  SORT lt_existing_pos BY ebeln DESCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_existing_pos COMPARING ebeln ebelp.

  CLEAR: gt_final, gt_final1, gt_item_ref.

  " Build Top Header Rows (Matching ZME49 Screenshot)
  gt_final = VALUE #(
    " Row 1: Quotation Numbers & Action Button
    ( sel       = '@R7@ [ ]All'
      matnr     = 'Material'
      maktx     = 'Short Text'
      quat      = 'Quot'
      quat1     = VALUE #( gt_hdr[ 1 ]-ebeln OPTIONAL )
      quat2     = VALUE #( gt_hdr[ 2 ]-ebeln OPTIONAL )
      quat3     = VALUE #( gt_hdr[ 3 ]-ebeln OPTIONAL )
      quat4     = VALUE #( gt_hdr[ 4 ]-ebeln OPTIONAL )
      quat5     = VALUE #( gt_hdr[ 5 ]-ebeln OPTIONAL )
      quat6     = VALUE #( gt_hdr[ 6 ]-ebeln OPTIONAL )
      quat7     = VALUE #( gt_hdr[ 7 ]-ebeln OPTIONAL )
      mean      = 'Mean'
      minimum   = 'Minimum'
      po_action = '@0Y@ Create PO'
      color     = 'C210' )

    " Row 2: Supplier Names & Mass Create PO Button
    ( sel       = ''
      matnr     = ''
      maktx     = 'Supplier Name'
      quat      = ''
      quat1     = VALUE #( gt_hdr[ 1 ]-name1 OPTIONAL )
      quat2     = VALUE #( gt_hdr[ 2 ]-name1 OPTIONAL )
      quat3     = VALUE #( gt_hdr[ 3 ]-name1 OPTIONAL )
      quat4     = VALUE #( gt_hdr[ 4 ]-name1 OPTIONAL )
      quat5     = VALUE #( gt_hdr[ 5 ]-name1 OPTIONAL )
      quat6     = VALUE #( gt_hdr[ 6 ]-name1 OPTIONAL )
      quat7     = VALUE #( gt_hdr[ 7 ]-name1 OPTIONAL )
      mean      = ''
      minimum   = ''
      po_action = '@0Y@ Create PO'
      color     = 'C210' )

    " Row 3: Collective Numbers & Refresh Button
    ( sel       = ''
      matnr     = ''
      maktx     = 'Coll. No.'
      quat      = ''
      quat1     = VALUE #( gt_hdr[ 1 ]-submi OPTIONAL )
      quat2     = VALUE #( gt_hdr[ 2 ]-submi OPTIONAL )
      quat3     = VALUE #( gt_hdr[ 3 ]-submi OPTIONAL )
      quat4     = VALUE #( gt_hdr[ 4 ]-submi OPTIONAL )
      quat5     = VALUE #( gt_hdr[ 5 ]-submi OPTIONAL )
      quat6     = VALUE #( gt_hdr[ 6 ]-submi OPTIONAL )
      quat7     = VALUE #( gt_hdr[ 7 ]-submi OPTIONAL )
      mean      = ''
      minimum   = ''
      po_action = '@42@ Refresh Data'
      color     = 'C210' )

    " Row 4: Quotation Reference Numbers
    ( sel       = ''
      matnr     = ''
      maktx     = 'Quotation Ref. No.'
      quat      = ''
      quat1     = VALUE #( gt_hdr[ 1 ]-ihrez OPTIONAL )
      quat2     = VALUE #( gt_hdr[ 2 ]-ihrez OPTIONAL )
      quat3     = VALUE #( gt_hdr[ 3 ]-ihrez OPTIONAL )
      quat4     = VALUE #( gt_hdr[ 4 ]-ihrez OPTIONAL )
      quat5     = VALUE #( gt_hdr[ 5 ]-ihrez OPTIONAL )
      quat6     = VALUE #( gt_hdr[ 6 ]-ihrez OPTIONAL )
      quat7     = VALUE #( gt_hdr[ 7 ]-ihrez OPTIONAL )
      mean      = ''
      minimum   = ''
      po_action = ''
      color     = 'C210' )
  ).

  DATA(it_data1) = it_data.
  SORT it_data1 BY ebelp matnr.
  DELETE ADJACENT DUPLICATES FROM it_data1 COMPARING ebelp matnr.
  SORT it_data BY lifnr ASCENDING.

  DATA: lt_win_cols TYPE STANDARD TABLE OF slis_fieldname WITH DEFAULT KEY.

  " Loop over distinct material items
  LOOP AT it_data1 INTO DATA(ls_data1).

    DATA: lv_win_col TYPE slis_fieldname.
    CLEAR: lv_win_col, lt_rank.
    lv_rank = 1.
    CLEAR: gs_val, gs_rank, gs_pkg, gs_app.

    " Separator Row (Yellow C310 line)
    gs_val-color = 'C310'.
    APPEND gs_val TO gt_final.
    CLEAR gs_val.

    " Setup Row Headers
    DATA(lv_qty) = COND ekpo-menge( WHEN ls_data1-ktmng > 0 THEN ls_data1-ktmng ELSE ls_data1-menge ).
    IF lv_qty <= 0.
      lv_qty = 1.
    ENDIF.

    " Check if PO already exists for this quotation item or material in this collective group
    DATA: lv_found_po    TYPE ekko-ebeln,
          lv_found_lifnr TYPE ekko-lifnr.
    CLEAR: lv_found_po, lv_found_lifnr.
    READ TABLE lt_existing_pos INTO DATA(ls_p1)
      WITH KEY anfnr = ls_data1-ebeln anfps = ls_data1-ebelp.
    IF sy-subrc = 0.
      lv_found_po    = ls_p1-ebeln.
      lv_found_lifnr = ls_p1-lifnr.
    ELSE.
      READ TABLE lt_existing_pos INTO DATA(ls_p2)
        WITH KEY anfnr = ls_data1-ebeln matnr = ls_data1-matnr.
      IF sy-subrc = 0.
        lv_found_po    = ls_p2-ebeln.
        lv_found_lifnr = ls_p2-lifnr.
      ELSE.
        READ TABLE lt_existing_pos INTO DATA(ls_p3)
          WITH KEY bednr = ls_data1-ebeln matnr = ls_data1-matnr.
        IF sy-subrc = 0.
          lv_found_po    = ls_p3-ebeln.
          lv_found_lifnr = ls_p3-lifnr.
        ELSE.
          LOOP AT gt_hdr INTO DATA(ls_gh).
            READ TABLE lt_existing_pos INTO DATA(ls_p4)
              WITH KEY anfnr = ls_gh-ebeln matnr = ls_data1-matnr.
            IF sy-subrc = 0.
              lv_found_po    = ls_p4-ebeln.
              lv_found_lifnr = ls_p4-lifnr.
              EXIT.
            ENDIF.
            READ TABLE lt_existing_pos INTO DATA(ls_p5)
              WITH KEY bednr = ls_gh-ebeln matnr = ls_data1-matnr.
            IF sy-subrc = 0.
              lv_found_po    = ls_p5-ebeln.
              lv_found_lifnr = ls_p5-lifnr.
              EXIT.
            ENDIF.
          ENDLOOP.
          IF lv_found_po IS INITIAL AND ls_data1-submi IS NOT INITIAL.
            READ TABLE lt_existing_pos INTO DATA(ls_p6)
              WITH KEY submi = ls_data1-submi matnr = ls_data1-matnr.
            IF sy-subrc = 0.
              lv_found_po    = ls_p6-ebeln.
              lv_found_lifnr = ls_p6-lifnr.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_found_po IS NOT INITIAL.
      gs_val-sel       = '@02@ Created'.
      gs_val-po_action = |@0V@ PO { lv_found_po }|.
    ELSE.
      gs_val-sel       = '@R7@ [ ]'.      " Unchecked checkbox by default
      gs_val-po_action = '@0Y@ Select Supplier'. " Item-level action button initially Select Supplier
    ENDIF.

    gs_val-matnr     = ls_data1-matnr.
    gs_val-maktx     = ls_data1-txz01.
    gs_val-quat      = 'Val:'.
    gs_val-ebelp     = ls_data1-ebelp.

    gs_rank-quat     = 'Rank:'.
    gs_rank-ebelp    = ls_data1-ebelp.

    gs_pkg-matnr     = 'Total Qty'.
    gs_pkg-maktx     = |{ lv_qty }|.
    gs_pkg-quat      = 'Per Kg'.
    gs_pkg-ebelp     = ls_data1-ebelp.

    gs_app-quat      = 'Approved'.
    gs_app-ebelp     = ls_data1-ebelp.

    " Initialize all columns for vendors in gt_hdr with 'No Price'
    IF lines( gt_hdr ) >= 1.
      gs_val-quat1  = 'No Price'.
      gs_pkg-quat1  = 'No Price'.
      gs_rank-quat1 = 'No Price'.
      gs_app-quat1  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 2.
      gs_val-quat2  = 'No Price'.
      gs_pkg-quat2  = 'No Price'.
      gs_rank-quat2 = 'No Price'.
      gs_app-quat2  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 3.
      gs_val-quat3  = 'No Price'.
      gs_pkg-quat3  = 'No Price'.
      gs_rank-quat3 = 'No Price'.
      gs_app-quat3  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 4.
      gs_val-quat4  = 'No Price'.
      gs_pkg-quat4  = 'No Price'.
      gs_rank-quat4 = 'No Price'.
      gs_app-quat4  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 5.
      gs_val-quat5  = 'No Price'.
      gs_pkg-quat5  = 'No Price'.
      gs_rank-quat5 = 'No Price'.
      gs_app-quat5  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 6.
      gs_val-quat6  = 'No Price'.
      gs_pkg-quat6  = 'No Price'.
      gs_rank-quat6 = 'No Price'.
      gs_app-quat6  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 7.
      gs_val-quat7  = 'No Price'.
      gs_pkg-quat7  = 'No Price'.
      gs_rank-quat7 = 'No Price'.
      gs_app-quat7  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.

    CLEAR lt_rank.
    LOOP AT it_data INTO DATA(ls_data) WHERE ebelp = ls_data1-ebelp AND matnr = ls_data1-matnr.
      IF ls_data-netpr <= 0.
        CONTINUE.
      ENDIF.

      DATA(lv_item_qty) = COND ekpo-menge( WHEN ls_data-ktmng > 0 THEN ls_data-ktmng ELSE ls_data-menge ).
      IF lv_item_qty <= 0.
        lv_item_qty = 1.
      ENDIF.

      DATA(lv_peinh) = COND ekpo-peinh( WHEN ls_data-peinh > 0 THEN ls_data-peinh ELSE 1 ).

      IF ls_data-waers = 'USD' AND ls_data-wkurs > 0.
        lv_val = |{ ( ( lv_item_qty * ls_data-netpr ) / lv_peinh ) * ls_data-wkurs }|.
      ELSE.
        lv_val = |{ ( lv_item_qty * ls_data-netpr ) / lv_peinh }|.
      ENDIF.

      CLEAR ls_rank.
      ls_rank-lifnr  = ls_data-lifnr.
      ls_rank-amount = lv_val.

      IF ls_data-waers = 'USD' AND ls_data-wkurs > 0.
        ls_rank-amount1 = ( ls_data-netpr * ls_data-wkurs ) / lv_peinh.
      ELSE.
        ls_rank-amount1 = ls_data-netpr / lv_peinh.
      ENDIF.
      APPEND ls_rank TO lt_rank.

      IF lines( gt_hdr ) >= 1 AND ls_data-lifnr = gt_hdr[ 1 ]-lifnr.
        gs_val-quat1 = lv_val.
        gs_pkg-quat1 = |{ ls_rank-amount1 }|.
      ELSEIF lines( gt_hdr ) >= 2 AND ls_data-lifnr = gt_hdr[ 2 ]-lifnr.
        gs_val-quat2 = lv_val.
        gs_pkg-quat2 = |{ ls_rank-amount1 }|.
      ELSEIF lines( gt_hdr ) >= 3 AND ls_data-lifnr = gt_hdr[ 3 ]-lifnr.
        gs_val-quat3 = lv_val.
        gs_pkg-quat3 = |{ ls_rank-amount1 }|.
      ELSEIF lines( gt_hdr ) >= 4 AND ls_data-lifnr = gt_hdr[ 4 ]-lifnr.
        gs_val-quat4 = lv_val.
        gs_pkg-quat4 = |{ ls_rank-amount1 }|.
      ELSEIF lines( gt_hdr ) >= 5 AND ls_data-lifnr = gt_hdr[ 5 ]-lifnr.
        gs_val-quat5 = lv_val.
        gs_pkg-quat5 = |{ ls_rank-amount1 }|.
      ELSEIF lines( gt_hdr ) >= 6 AND ls_data-lifnr = gt_hdr[ 6 ]-lifnr.
        gs_val-quat6 = lv_val.
        gs_pkg-quat6 = |{ ls_rank-amount1 }|.
      ELSEIF lines( gt_hdr ) >= 7 AND ls_data-lifnr = gt_hdr[ 7 ]-lifnr.
        gs_val-quat7 = lv_val.
        gs_pkg-quat7 = |{ ls_rank-amount1 }|.
      ENDIF.
    ENDLOOP.

    CONDENSE: gs_val-quat1, gs_val-quat2, gs_val-quat3, gs_val-quat4,
              gs_val-quat5, gs_val-quat6, gs_val-quat7.

    " Calculate Mean only for quotations with price > 0
    DATA: lv_val_sum TYPE decfloat34 VALUE 0,
          lv_pkg_sum TYPE decfloat34 VALUE 0,
          lv_prc_cnt TYPE i VALUE 0.

    LOOP AT lt_rank INTO DATA(ls_rm).
      lv_val_sum = lv_val_sum + ls_rm-amount.
      lv_pkg_sum = lv_pkg_sum + ls_rm-amount1.
      lv_prc_cnt = lv_prc_cnt + 1.
    ENDLOOP.

    IF lv_prc_cnt > 0.
      lv_mean = lv_val_sum / lv_prc_cnt.
      gs_val-mean = |{ lv_mean }|.
      lv_mean = lv_pkg_sum / lv_prc_cnt.
      gs_pkg-mean = |{ lv_mean }|.
    ELSE.
      gs_val-mean = 'No Price'.
      gs_pkg-mean = 'No Price'.
    ENDIF.

    " Determine Ranks & L1 Minimum Winner
    SORT lt_rank BY amount ASCENDING.
    DATA: ls_item_ref TYPE ty_item_ref.
    CLEAR ls_item_ref.
    ls_item_ref-matnr     = ls_data1-matnr.
    ls_item_ref-ebelp     = ls_data1-ebelp.
    ls_item_ref-txz01     = ls_data1-txz01.
    ls_item_ref-menge     = lv_qty.
    ls_item_ref-meins     = ls_data1-meins.
    ls_item_ref-werks     = ls_data1-werks.
    ls_item_ref-submi     = ls_data1-submi.
    ls_item_ref-po_number = lv_found_po.

    IF lt_rank IS NOT INITIAL.
      READ TABLE lt_rank INTO DATA(ls_top_r) INDEX 1.
      READ TABLE it_data INTO DATA(ls_win)
        WITH KEY ebelp = ls_data1-ebelp matnr = ls_data1-matnr lifnr = ls_top_r-lifnr.
      IF sy-subrc = 0.
        ls_item_ref-l1_ebeln = ls_win-ebeln.
        ls_item_ref-l1_ebelp = ls_win-ebelp.
        ls_item_ref-l1_lifnr = ls_win-lifnr.
        ls_item_ref-l1_name1 = ls_win-name1.
        ls_item_ref-l1_netpr = ls_win-netpr.
        ls_item_ref-l1_peinh = ls_win-peinh.
        ls_item_ref-l1_waers = ls_win-waers.
        ls_item_ref-l1_zterm = ls_win-zterm.
        ls_item_ref-l1_inco1 = ls_win-inco1.
        ls_item_ref-bukrs    = ls_win-bukrs.
        ls_item_ref-ekorg    = ls_win-ekorg.
        ls_item_ref-ekgrp    = ls_win-ekgrp.
      ENDIF.
    ENDIF.

    IF ls_item_ref-po_number IS NOT INITIAL.
      gs_val-sel       = '@02@ Created'.
      gs_val-po_action = |@0V@ PO { ls_item_ref-po_number }|.
      IF lv_found_lifnr IS NOT INITIAL.
        READ TABLE gt_hdr INTO DATA(ls_fhdr) WITH KEY lifnr = lv_found_lifnr.
        IF sy-subrc = 0.
          ls_item_ref-sel_lifnr = lv_found_lifnr.
          ls_item_ref-sel_name1 = ls_fhdr-name1.
        ELSE.
          SELECT SINGLE name1 FROM lfa1 INTO @ls_item_ref-sel_name1
            WHERE lifnr = @lv_found_lifnr.
          ls_item_ref-sel_lifnr = lv_found_lifnr.
        ENDIF.
      ENDIF.
    ELSE.
      CLEAR: ls_item_ref-sel_col, ls_item_ref-sel_ebeln, ls_item_ref-sel_ebelp,
             ls_item_ref-sel_lifnr, ls_item_ref-sel_name1, ls_item_ref-sel_netpr,
             ls_item_ref-sel_peinh, ls_item_ref-sel_waers, ls_item_ref-sel_zterm,
             ls_item_ref-sel_inco1.
      gs_val-sel       = '@R7@ [ ]'.
      gs_val-po_action = '@0Y@ Select Supplier'.
    ENDIF.

    IF lt_rank IS NOT INITIAL.
      lv_rank = 1.
      LOOP AT lt_rank INTO ls_rank.
        IF lv_rank = 1.
          gs_val-minimum = |{ ls_rank-amount }|.
          gs_pkg-minimum = |{ ls_rank-amount1 }|.
          CLEAR lv_win_col.
          IF lines( gt_hdr ) >= 1 AND ls_rank-lifnr = gt_hdr[ 1 ]-lifnr.
            lv_win_col = 'QUAT1'.
          ELSEIF lines( gt_hdr ) >= 2 AND ls_rank-lifnr = gt_hdr[ 2 ]-lifnr.
            lv_win_col = 'QUAT2'.
          ELSEIF lines( gt_hdr ) >= 3 AND ls_rank-lifnr = gt_hdr[ 3 ]-lifnr.
            lv_win_col = 'QUAT3'.
          ELSEIF lines( gt_hdr ) >= 4 AND ls_rank-lifnr = gt_hdr[ 4 ]-lifnr.
            lv_win_col = 'QUAT4'.
          ELSEIF lines( gt_hdr ) >= 5 AND ls_rank-lifnr = gt_hdr[ 5 ]-lifnr.
            lv_win_col = 'QUAT5'.
          ELSEIF lines( gt_hdr ) >= 6 AND ls_rank-lifnr = gt_hdr[ 6 ]-lifnr.
            lv_win_col = 'QUAT6'.
          ELSEIF lines( gt_hdr ) >= 7 AND ls_rank-lifnr = gt_hdr[ 7 ]-lifnr.
            lv_win_col = 'QUAT7'.
          ENDIF.
          IF lv_win_col IS NOT INITIAL.
            APPEND lv_win_col TO lt_win_cols.
            ls_item_ref-l1_sel_col = lv_win_col.
          ENDIF.
        ENDIF.

        IF lines( gt_hdr ) >= 1 AND ls_rank-lifnr = gt_hdr[ 1 ]-lifnr.
          gs_rank-quat1 = |{ lv_rank }|.
          IF lv_rank = 1.
            APPEND VALUE #( fieldname = 'QUAT1' color = VALUE #( col = 5 int = 1 ) ) TO gs_rank-cell_colors.
          ELSE.
            APPEND VALUE #( fieldname = 'QUAT1' color = VALUE #( col = 1 int = 0 ) ) TO gs_rank-cell_colors.
          ENDIF.
        ELSEIF lines( gt_hdr ) >= 2 AND ls_rank-lifnr = gt_hdr[ 2 ]-lifnr.
          gs_rank-quat2 = |{ lv_rank }|.
          IF lv_rank = 1.
            APPEND VALUE #( fieldname = 'QUAT2' color = VALUE #( col = 5 int = 1 ) ) TO gs_rank-cell_colors.
          ELSE.
            APPEND VALUE #( fieldname = 'QUAT2' color = VALUE #( col = 1 int = 0 ) ) TO gs_rank-cell_colors.
          ENDIF.
        ELSEIF lines( gt_hdr ) >= 3 AND ls_rank-lifnr = gt_hdr[ 3 ]-lifnr.
          gs_rank-quat3 = |{ lv_rank }|.
          IF lv_rank = 1.
            APPEND VALUE #( fieldname = 'QUAT3' color = VALUE #( col = 5 int = 1 ) ) TO gs_rank-cell_colors.
          ELSE.
            APPEND VALUE #( fieldname = 'QUAT3' color = VALUE #( col = 1 int = 0 ) ) TO gs_rank-cell_colors.
          ENDIF.
        ELSEIF lines( gt_hdr ) >= 4 AND ls_rank-lifnr = gt_hdr[ 4 ]-lifnr.
          gs_rank-quat4 = |{ lv_rank }|.
          IF lv_rank = 1.
            APPEND VALUE #( fieldname = 'QUAT4' color = VALUE #( col = 5 int = 1 ) ) TO gs_rank-cell_colors.
          ELSE.
            APPEND VALUE #( fieldname = 'QUAT4' color = VALUE #( col = 1 int = 0 ) ) TO gs_rank-cell_colors.
          ENDIF.
        ELSEIF lines( gt_hdr ) >= 5 AND ls_rank-lifnr = gt_hdr[ 5 ]-lifnr.
          gs_rank-quat5 = |{ lv_rank }|.
          IF lv_rank = 1.
            APPEND VALUE #( fieldname = 'QUAT5' color = VALUE #( col = 5 int = 1 ) ) TO gs_rank-cell_colors.
          ELSE.
            APPEND VALUE #( fieldname = 'QUAT5' color = VALUE #( col = 1 int = 0 ) ) TO gs_rank-cell_colors.
          ENDIF.
        ELSEIF lines( gt_hdr ) >= 6 AND ls_rank-lifnr = gt_hdr[ 6 ]-lifnr.
          gs_rank-quat6 = |{ lv_rank }|.
          IF lv_rank = 1.
            APPEND VALUE #( fieldname = 'QUAT6' color = VALUE #( col = 5 int = 1 ) ) TO gs_rank-cell_colors.
          ELSE.
            APPEND VALUE #( fieldname = 'QUAT6' color = VALUE #( col = 1 int = 0 ) ) TO gs_rank-cell_colors.
          ENDIF.
        ELSEIF lines( gt_hdr ) >= 7 AND ls_rank-lifnr = gt_hdr[ 7 ]-lifnr.
          gs_rank-quat7 = |{ lv_rank }|.
          IF lv_rank = 1.
            APPEND VALUE #( fieldname = 'QUAT7' color = VALUE #( col = 5 int = 1 ) ) TO gs_rank-cell_colors.
          ELSE.
            APPEND VALUE #( fieldname = 'QUAT7' color = VALUE #( col = 1 int = 0 ) ) TO gs_rank-cell_colors.
          ENDIF.
        ENDIF.

        lv_rank = lv_rank + 1.
      ENDLOOP.
    ELSE.
      gs_val-minimum = 'No Price'.
      gs_pkg-minimum = 'No Price'.
    ENDIF.

    APPEND ls_item_ref TO gt_item_ref.

    APPEND gs_val  TO gt_final.
    APPEND gs_rank TO gt_final.
    APPEND gs_pkg  TO gt_final.
    APPEND gs_app  TO gt_final.

  ENDLOOP.

  PERFORM update_header_sel_state.

  SORT lt_win_cols.
  DELETE ADJACENT DUPLICATES FROM lt_win_cols.

  " Calculate Total Quotation Amount Row
  CLEAR ls_total.
  ls_total-maktx = 'Total Quotation Amount'.
  ls_total-color = 'C110'.

  DATA: lv_has_prc1 TYPE abap_bool VALUE abap_false,
        lv_has_prc2 TYPE abap_bool VALUE abap_false,
        lv_has_prc3 TYPE abap_bool VALUE abap_false,
        lv_has_prc4 TYPE abap_bool VALUE abap_false,
        lv_has_prc5 TYPE abap_bool VALUE abap_false,
        lv_has_prc6 TYPE abap_bool VALUE abap_false,
        lv_has_prc7 TYPE abap_bool VALUE abap_false.

  LOOP AT gt_final INTO DATA(ls_chk) WHERE quat = 'Val:'.
    IF ls_chk-quat1 IS NOT INITIAL AND ls_chk-quat1 NE 'No Price'. lv_has_prc1 = abap_true. ENDIF.
    IF ls_chk-quat2 IS NOT INITIAL AND ls_chk-quat2 NE 'No Price'. lv_has_prc2 = abap_true. ENDIF.
    IF ls_chk-quat3 IS NOT INITIAL AND ls_chk-quat3 NE 'No Price'. lv_has_prc3 = abap_true. ENDIF.
    IF ls_chk-quat4 IS NOT INITIAL AND ls_chk-quat4 NE 'No Price'. lv_has_prc4 = abap_true. ENDIF.
    IF ls_chk-quat5 IS NOT INITIAL AND ls_chk-quat5 NE 'No Price'. lv_has_prc5 = abap_true. ENDIF.
    IF ls_chk-quat6 IS NOT INITIAL AND ls_chk-quat6 NE 'No Price'. lv_has_prc6 = abap_true. ENDIF.
    IF ls_chk-quat7 IS NOT INITIAL AND ls_chk-quat7 NE 'No Price'. lv_has_prc7 = abap_true. ENDIF.
  ENDLOOP.

  IF lines( gt_hdr ) >= 1.
    IF lv_has_prc1 = abap_true.
      ls_total-quat1 = |{ REDUCE decfloat34( INIT s = CONV decfloat34( 0 )
                            FOR ls IN gt_final WHERE ( quat = 'Val:' )
                            NEXT s = s + COND decfloat34(
                              WHEN ls-quat1 IS NOT INITIAL AND ls-quat1 NE 'No Price'
                              THEN CONV decfloat34( ls-quat1 )
                              ELSE 0 ) ) DECIMALS = 2 }|.
    ELSE.
      ls_total-quat1 = 'No Price'.
    ENDIF.
  ENDIF.
  IF lines( gt_hdr ) >= 2.
    IF lv_has_prc2 = abap_true.
      ls_total-quat2 = |{ REDUCE decfloat34( INIT s = CONV decfloat34( 0 )
                            FOR ls IN gt_final WHERE ( quat = 'Val:' )
                            NEXT s = s + COND decfloat34(
                              WHEN ls-quat2 IS NOT INITIAL AND ls-quat2 NE 'No Price'
                              THEN CONV decfloat34( ls-quat2 )
                              ELSE 0 ) ) DECIMALS = 2 }|.
    ELSE.
      ls_total-quat2 = 'No Price'.
    ENDIF.
  ENDIF.
  IF lines( gt_hdr ) >= 3.
    IF lv_has_prc3 = abap_true.
      ls_total-quat3 = |{ REDUCE decfloat34( INIT s = CONV decfloat34( 0 )
                            FOR ls IN gt_final WHERE ( quat = 'Val:' )
                            NEXT s = s + COND decfloat34(
                              WHEN ls-quat3 IS NOT INITIAL AND ls-quat3 NE 'No Price'
                              THEN CONV decfloat34( ls-quat3 )
                              ELSE 0 ) ) DECIMALS = 2 }|.
    ELSE.
      ls_total-quat3 = 'No Price'.
    ENDIF.
  ENDIF.
  IF lines( gt_hdr ) >= 4.
    IF lv_has_prc4 = abap_true.
      ls_total-quat4 = |{ REDUCE decfloat34( INIT s = CONV decfloat34( 0 )
                            FOR ls IN gt_final WHERE ( quat = 'Val:' )
                            NEXT s = s + COND decfloat34(
                              WHEN ls-quat4 IS NOT INITIAL AND ls-quat4 NE 'No Price'
                              THEN CONV decfloat34( ls-quat4 )
                              ELSE 0 ) ) DECIMALS = 2 }|.
    ELSE.
      ls_total-quat4 = 'No Price'.
    ENDIF.
  ENDIF.
  IF lines( gt_hdr ) >= 5.
    IF lv_has_prc5 = abap_true.
      ls_total-quat5 = |{ REDUCE decfloat34( INIT s = CONV decfloat34( 0 )
                            FOR ls IN gt_final WHERE ( quat = 'Val:' )
                            NEXT s = s + COND decfloat34(
                              WHEN ls-quat5 IS NOT INITIAL AND ls-quat5 NE 'No Price'
                              THEN CONV decfloat34( ls-quat5 )
                              ELSE 0 ) ) DECIMALS = 2 }|.
    ELSE.
      ls_total-quat5 = 'No Price'.
    ENDIF.
  ENDIF.
  IF lines( gt_hdr ) >= 6.
    IF lv_has_prc6 = abap_true.
      ls_total-quat6 = |{ REDUCE decfloat34( INIT s = CONV decfloat34( 0 )
                            FOR ls IN gt_final WHERE ( quat = 'Val:' )
                            NEXT s = s + COND decfloat34(
                              WHEN ls-quat6 IS NOT INITIAL AND ls-quat6 NE 'No Price'
                              THEN CONV decfloat34( ls-quat6 )
                              ELSE 0 ) ) DECIMALS = 2 }|.
    ELSE.
      ls_total-quat6 = 'No Price'.
    ENDIF.
  ENDIF.
  IF lines( gt_hdr ) >= 7.
    IF lv_has_prc7 = abap_true.
      ls_total-quat7 = |{ REDUCE decfloat34( INIT s = CONV decfloat34( 0 )
                            FOR ls IN gt_final WHERE ( quat = 'Val:' )
                            NEXT s = s + COND decfloat34(
                              WHEN ls-quat7 IS NOT INITIAL AND ls-quat7 NE 'No Price'
                              THEN CONV decfloat34( ls-quat7 )
                              ELSE 0 ) ) DECIMALS = 2 }|.
    ELSE.
      ls_total-quat7 = 'No Price'.
    ENDIF.
  ENDIF.

  APPEND ls_total TO gt_final.
  APPEND ls_total TO gt_final1.

  " Incoterms Row
  APPEND VALUE #(
    matnr   = ''
    maktx   = 'Incoterms'
    quat1   = VALUE #( gt_hdr[ 1 ]-inco1 OPTIONAL )
    quat2   = VALUE #( gt_hdr[ 2 ]-inco1 OPTIONAL )
    quat3   = VALUE #( gt_hdr[ 3 ]-inco1 OPTIONAL )
    quat4   = VALUE #( gt_hdr[ 4 ]-inco1 OPTIONAL )
    quat5   = VALUE #( gt_hdr[ 5 ]-inco1 OPTIONAL )
    quat6   = VALUE #( gt_hdr[ 6 ]-inco1 OPTIONAL )
    quat7   = VALUE #( gt_hdr[ 7 ]-inco1 OPTIONAL )
    color   = 'C110'
  ) TO gt_final.

  " Payment Terms Row
  APPEND VALUE #(
    matnr   = ''
    maktx   = 'Payment Terms'
    quat1   = VALUE #( gt_hdr[ 1 ]-text1 OPTIONAL )
    quat2   = VALUE #( gt_hdr[ 2 ]-text1 OPTIONAL )
    quat3   = VALUE #( gt_hdr[ 3 ]-text1 OPTIONAL )
    quat4   = VALUE #( gt_hdr[ 4 ]-text1 OPTIONAL )
    quat5   = VALUE #( gt_hdr[ 5 ]-text1 OPTIONAL )
    quat6   = VALUE #( gt_hdr[ 6 ]-text1 OPTIONAL )
    quat7   = VALUE #( gt_hdr[ 7 ]-text1 OPTIONAL )
    color   = 'C110'
  ) TO gt_final.

  " Interest Days Calculation Table
  APPEND VALUE #(
    quat1 = |{ CONV i( VALUE #( gt_hdr[ 1 ]-ztag1 OPTIONAL ) ) }|
    quat2 = |{ CONV i( VALUE #( gt_hdr[ 2 ]-ztag1 OPTIONAL ) ) }|
    quat3 = |{ CONV i( VALUE #( gt_hdr[ 3 ]-ztag1 OPTIONAL ) ) }|
    quat4 = |{ CONV i( VALUE #( gt_hdr[ 4 ]-ztag1 OPTIONAL ) ) }|
    quat5 = |{ CONV i( VALUE #( gt_hdr[ 5 ]-ztag1 OPTIONAL ) ) }|
    quat6 = |{ CONV i( VALUE #( gt_hdr[ 6 ]-ztag1 OPTIONAL ) ) }|
    quat7 = |{ CONV i( VALUE #( gt_hdr[ 7 ]-ztag1 OPTIONAL ) ) }|
  ) TO gt_final1.

  DATA(lt_days) = VALUE int4_table(
    ( CONV i( gt_final1[ 2 ]-quat1 ) )
    ( CONV i( gt_final1[ 2 ]-quat2 ) )
    ( CONV i( gt_final1[ 2 ]-quat3 ) )
    ( CONV i( gt_final1[ 2 ]-quat4 ) )
    ( CONV i( gt_final1[ 2 ]-quat5 ) )
    ( CONV i( gt_final1[ 2 ]-quat6 ) )
    ( CONV i( gt_final1[ 2 ]-quat7 ) ) ).

  DATA(lv_max_days) = REDUCE i( INIT max = 0 FOR day IN lt_days NEXT max = nmax( val1 = max val2 = day ) ).

  " Interest Rate (%) Row
  int_days = p_rate / 100.

  APPEND VALUE #(
    matnr   = ''
    maktx   = 'Interest Rate(%)'
    quat1   = |{ p_rate DECIMALS = 2 }%|
    quat2   = |{ p_rate DECIMALS = 2 }%|
    quat3   = |{ p_rate DECIMALS = 2 }%|
    quat4   = |{ p_rate DECIMALS = 2 }%|
    quat5   = |{ p_rate DECIMALS = 2 }%|
    quat6   = |{ p_rate DECIMALS = 2 }%|
    quat7   = |{ p_rate DECIMALS = 2 }%|
    color   = 'C110'
  ) TO gt_final.

  " Interest Amount Row
  CLEAR ls_interest.
  ls_interest-maktx = 'Interest Amount'.
  ls_interest-color = 'C110'.

  READ TABLE gt_final1 INTO DATA(ls_days) INDEX 2.
  READ TABLE gt_final INTO DATA(ls_amt) WITH KEY maktx = 'Total Quotation Amount' ##READ_WHERE_OK.

  IF sy-subrc = 0.
    IF lines( gt_hdr ) >= 1 AND ls_amt-quat1 IS NOT INITIAL AND ls_amt-quat1 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat1 ) ) * CONV decfloat34( ls_amt-quat1 ) }|.
      ls_interest-quat1 = |{ lv_result DECIMALS = 2 }|.
    ELSEIF lines( gt_hdr ) >= 1.
      ls_interest-quat1 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 2 AND ls_amt-quat2 IS NOT INITIAL AND ls_amt-quat2 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat2 ) ) * CONV decfloat34( ls_amt-quat2 ) }|.
      ls_interest-quat2 = |{ lv_result DECIMALS = 2 }|.
    ELSEIF lines( gt_hdr ) >= 2.
      ls_interest-quat2 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 3 AND ls_amt-quat3 IS NOT INITIAL AND ls_amt-quat3 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat3 ) ) * CONV decfloat34( ls_amt-quat3 ) }|.
      ls_interest-quat3 = |{ lv_result DECIMALS = 2 }|.
    ELSEIF lines( gt_hdr ) >= 3.
      ls_interest-quat3 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 4 AND ls_amt-quat4 IS NOT INITIAL AND ls_amt-quat4 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat4 ) ) * CONV decfloat34( ls_amt-quat4 ) }|.
      ls_interest-quat4 = |{ lv_result DECIMALS = 2 }|.
    ELSEIF lines( gt_hdr ) >= 4.
      ls_interest-quat4 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 5 AND ls_amt-quat5 IS NOT INITIAL AND ls_amt-quat5 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat5 ) ) * CONV decfloat34( ls_amt-quat5 ) }|.
      ls_interest-quat5 = |{ lv_result DECIMALS = 2 }|.
    ELSEIF lines( gt_hdr ) >= 5.
      ls_interest-quat5 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 6 AND ls_amt-quat6 IS NOT INITIAL AND ls_amt-quat6 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat6 ) ) * CONV decfloat34( ls_amt-quat6 ) }|.
      ls_interest-quat6 = |{ lv_result DECIMALS = 2 }|.
    ELSEIF lines( gt_hdr ) >= 6.
      ls_interest-quat6 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 7 AND ls_amt-quat7 IS NOT INITIAL AND ls_amt-quat7 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat7 ) ) * CONV decfloat34( ls_amt-quat7 ) }|.
      ls_interest-quat7 = |{ lv_result DECIMALS = 2 }|.
    ELSEIF lines( gt_hdr ) >= 7.
      ls_interest-quat7 = 'No Price'.
    ENDIF.
  ENDIF.

  APPEND ls_interest TO gt_final.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form display
*&---------------------------------------------------------------------*
FORM display.

  DATA(it_fcat) = VALUE slis_t_fieldcat_alv(
    ( fieldname = 'SEL'       seltext_m = 'Select'   outputlen = '12' hotspot = 'X' )
    ( fieldname = 'MATNR'     seltext_m = ' '        outputlen = '18' hotspot = 'X' )
    ( fieldname = 'MAKTX'     seltext_m = ' '        outputlen = '40' hotspot = 'X' )
    ( fieldname = 'QUAT'      seltext_m = ' '        outputlen = '10' )
    ( fieldname = 'QUAT1'     seltext_m = ' '        outputlen = '20' hotspot = 'X' )
    ( fieldname = 'QUAT2'     seltext_m = ' '        outputlen = '20' hotspot = 'X' )
    ( fieldname = 'QUAT3'     seltext_m = ' '        outputlen = '20' hotspot = 'X' )
    ( fieldname = 'QUAT4'     seltext_m = ' '        outputlen = '20' hotspot = 'X' )
    ( fieldname = 'QUAT5'     seltext_m = ' '        outputlen = '20' hotspot = 'X' )
    ( fieldname = 'QUAT6'     seltext_m = ' '        outputlen = '20' hotspot = 'X' )
    ( fieldname = 'QUAT7'     seltext_m = ' '        outputlen = '20' hotspot = 'X' )
    ( fieldname = 'MEAN'      seltext_m = ' '        outputlen = '15' )
    ( fieldname = 'MINIMUM'   seltext_m = ' '        outputlen = '15' )
    ( fieldname = 'PO_ACTION' seltext_m = 'Action'   outputlen = '25' hotspot = 'X' )
  ).

  DATA(ls_layout) = VALUE slis_layout_alv(
    no_colhead       = 'X'
    info_fieldname   = 'COLOR'
    coltab_fieldname = 'CELL_COLORS'
  ).

  LOOP AT it_fcat INTO DATA(wa_fcat).
    CASE wa_fcat-fieldname.
      WHEN 'QUAT1'.
        IF lines( gt_hdr ) < 1 OR VALUE #( gt_hdr[ 1 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT2'.
        IF lines( gt_hdr ) < 2 OR VALUE #( gt_hdr[ 2 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT3'.
        IF lines( gt_hdr ) < 3 OR VALUE #( gt_hdr[ 3 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT4'.
        IF lines( gt_hdr ) < 4 OR VALUE #( gt_hdr[ 4 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT5'.
        IF lines( gt_hdr ) < 5 OR VALUE #( gt_hdr[ 5 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT6'.
        IF lines( gt_hdr ) < 6 OR VALUE #( gt_hdr[ 6 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT7'.
        IF lines( gt_hdr ) < 7 OR VALUE #( gt_hdr[ 7 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
    ENDCASE.
    MODIFY it_fcat FROM wa_fcat.
  ENDLOOP.

  CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = ls_layout
      it_fieldcat             = it_fcat
    TABLES
      t_outtab                = gt_final
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error displaying ALV List.' TYPE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form user_command
*&---------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

  " Standard Save Button (Ctrl+S / &DATA_SAVE)
  IF r_ucomm = '&DATA_SAVE' OR r_ucomm = 'SAVE'.
    PERFORM create_po_for_selected USING rs_selfield-tabindex.
    rs_selfield-refresh    = abap_true.
    rs_selfield-col_stable = abap_true.
    rs_selfield-row_stable = abap_true.
    RETURN.
  ENDIF.

  " Refresh Function (Toolbar Refresh / Menu / F8 / In-Grid Button Click)
  IF r_ucomm = '&REFRESH' OR r_ucomm = 'REFRESH' OR r_ucomm = 'REFR' OR r_ucomm = 'REF'
     OR rs_selfield-value CS 'Refresh'
     OR ( rs_selfield-fieldname = 'PO_ACTION' AND rs_selfield-tabindex = 3 ).
    PERFORM get_data.
    rs_selfield-refresh    = abap_true.
    rs_selfield-col_stable = abap_true.
    rs_selfield-row_stable = abap_true.
    MESSAGE 'Quotation comparison data refreshed successfully.' TYPE 'S'.
    RETURN.
  ENDIF.

  " Direct trigger for Create PO:
  " - Toolbar button CREATE_PO or PO_CREATE
  " - Hotspot value contains 'Create PO' or 'PO ->'
  " - Column PO_ACTION clicked on any row
  IF r_ucomm = 'CREATE_PO'
     OR r_ucomm = 'PO_CREATE'
     OR rs_selfield-value CS 'Create PO'
     OR rs_selfield-value CS 'PO ->'
     OR rs_selfield-fieldname = 'PO_ACTION'.

    " If clicked on an already created PO (e.g., '@0V@ PO 0400000350') -> Open ME23N
    IF rs_selfield-tabindex > 4 AND rs_selfield-tabindex <= lines( gt_final ).
      READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_act_row>) INDEX rs_selfield-tabindex.
      IF sy-subrc = 0 AND <fs_act_row>-po_action CP '@0V@ PO *'.
        DATA(lv_po_num) = <fs_act_row>-po_action+7(10).
        SET PARAMETER ID 'BES' FIELD lv_po_num.
        CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
        IF sy-subrc <> 0.
          CALL TRANSACTION 'ME23N'.                    "#EC CI_CALLTA
        ENDIF.
        RETURN.
      ENDIF.
      IF sy-subrc = 0 AND ( <fs_act_row>-po_action CS 'Select Supplier' OR rs_selfield-value CS 'Select Supplier' ).
        DATA(lv_act_ebelp) = <fs_act_row>-ebelp.
        IF lv_act_ebelp IS INITIAL AND rs_selfield-tabindex + 1 <= lines( gt_final ).
          READ TABLE gt_final INTO DATA(ls_act_next) INDEX ( rs_selfield-tabindex + 1 ).
          IF sy-subrc = 0.
            lv_act_ebelp = ls_act_next-ebelp.
          ENDIF.
        ENDIF.
        IF lv_act_ebelp IS NOT INITIAL.
          PERFORM popup_choose_supplier USING lv_act_ebelp.
          rs_selfield-refresh    = abap_true.
          rs_selfield-col_stable = abap_true.
          rs_selfield-row_stable = abap_true.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    PERFORM create_po_for_selected USING rs_selfield-tabindex.
    rs_selfield-refresh    = abap_true.
    rs_selfield-col_stable = abap_true.
    rs_selfield-row_stable = abap_true.
    RETURN.
  ENDIF.

  CASE rs_selfield-fieldname.

    WHEN 'SEL' OR 'MATNR' OR 'MAKTX'.
      " Checkbox Hotspot or Material / Text Clicked -> Toggle selection
      IF rs_selfield-tabindex <= 4.
        " Toggle Select All / Deselect All
        PERFORM toggle_select_all.
      ELSEIF rs_selfield-tabindex > 4.
        READ TABLE gt_final INTO DATA(ls_clicked_row) INDEX rs_selfield-tabindex.
        IF sy-subrc = 0.
          DATA(lv_target_sel_ebelp) = ls_clicked_row-ebelp.
          IF lv_target_sel_ebelp IS INITIAL AND rs_selfield-tabindex + 1 <= lines( gt_final ).
            DATA(lv_next_idx) = rs_selfield-tabindex + 1.
            READ TABLE gt_final INTO DATA(ls_next_row) INDEX lv_next_idx.
            IF sy-subrc = 0.
              lv_target_sel_ebelp = ls_next_row-ebelp.
            ENDIF.
          ENDIF.
          IF lv_target_sel_ebelp IS NOT INITIAL.
            READ TABLE gt_item_ref INTO DATA(ls_ir_sel) WITH KEY ebelp = lv_target_sel_ebelp.
            IF sy-subrc = 0 AND ls_ir_sel-po_number IS NOT INITIAL.
              SET PARAMETER ID 'BES' FIELD ls_ir_sel-po_number.
              CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
              IF sy-subrc <> 0.
                CALL TRANSACTION 'ME23N'.                    "#EC CI_CALLTA
              ENDIF.
              RETURN.
            ENDIF.
            PERFORM toggle_item_selection USING lv_target_sel_ebelp.
          ENDIF.
        ENDIF.
      ENDIF.
      rs_selfield-refresh    = abap_true.
      rs_selfield-col_stable = abap_true.
      rs_selfield-row_stable = abap_true.
      RETURN.

    WHEN 'QUAT1' OR 'QUAT2' OR 'QUAT3' OR 'QUAT4' OR 'QUAT5' OR 'QUAT6' OR 'QUAT7'.
      IF rs_selfield-tabindex <= 4.
        " Header Rows 1 to 4: Quotation / Vendor clicked -> Open ME47 for Price Update
        DATA: lv_clicked_ebeln TYPE ekko-ebeln.
        CLEAR lv_clicked_ebeln.

        CASE rs_selfield-fieldname.
          WHEN 'QUAT1'. lv_clicked_ebeln = VALUE #( gt_hdr[ 1 ]-ebeln OPTIONAL ).
          WHEN 'QUAT2'. lv_clicked_ebeln = VALUE #( gt_hdr[ 2 ]-ebeln OPTIONAL ).
          WHEN 'QUAT3'. lv_clicked_ebeln = VALUE #( gt_hdr[ 3 ]-ebeln OPTIONAL ).
          WHEN 'QUAT4'. lv_clicked_ebeln = VALUE #( gt_hdr[ 4 ]-ebeln OPTIONAL ).
          WHEN 'QUAT5'. lv_clicked_ebeln = VALUE #( gt_hdr[ 5 ]-ebeln OPTIONAL ).
          WHEN 'QUAT6'. lv_clicked_ebeln = VALUE #( gt_hdr[ 6 ]-ebeln OPTIONAL ).
          WHEN 'QUAT7'. lv_clicked_ebeln = VALUE #( gt_hdr[ 7 ]-ebeln OPTIONAL ).
        ENDCASE.

        CONDENSE lv_clicked_ebeln.
        IF lv_clicked_ebeln IS NOT INITIAL.
          PERFORM open_me47_for_quotation USING lv_clicked_ebeln.
          PERFORM get_data.
          rs_selfield-refresh    = abap_true.
          rs_selfield-col_stable = abap_true.
          rs_selfield-row_stable = abap_true.
          RETURN.
        ENDIF.

      ELSE.
        " Item Rows (tabindex > 4): Select this Supplier for this specific Item
        READ TABLE gt_final INTO DATA(ls_item_clicked) INDEX rs_selfield-tabindex.
        IF sy-subrc = 0.
          DATA(lv_target_ebelp) = ls_item_clicked-ebelp.
          IF lv_target_ebelp IS INITIAL AND rs_selfield-tabindex + 1 <= lines( gt_final ).
            DATA(lv_next_item_idx) = rs_selfield-tabindex + 1.
            READ TABLE gt_final INTO DATA(ls_next_item) INDEX lv_next_item_idx.
            IF sy-subrc = 0.
              lv_target_ebelp = ls_next_item-ebelp.
            ENDIF.
          ENDIF.
          IF lv_target_ebelp IS NOT INITIAL.
            PERFORM select_supplier_for_item USING lv_target_ebelp rs_selfield-fieldname.
            rs_selfield-refresh    = abap_true.
            rs_selfield-col_stable = abap_true.
            rs_selfield-row_stable = abap_true.
            RETURN.
          ENDIF.
        ENDIF.
      ENDIF.

  ENDCASE.

  " Fallback for direct value click on Header Row 1 (Quotation Numbers)
  IF rs_selfield-tabindex = 1 AND rs_selfield-value IS NOT INITIAL.
    DATA: lv_cell_val TYPE string.
    lv_cell_val = rs_selfield-value.
    CONDENSE lv_cell_val.
    IF lv_cell_val IS NOT INITIAL
       AND lv_cell_val NE 'Mean'
       AND lv_cell_val NE 'Minimum'
       AND lv_cell_val NE 'Material'
       AND lv_cell_val NE 'Short Text'
       AND lv_cell_val NE 'Quot'
       AND NOT ( lv_cell_val CS 'All' )
       AND NOT ( lv_cell_val CS 'Action' ).
      DATA: lv_call_ebeln TYPE ekko-ebeln.
      lv_call_ebeln = lv_cell_val.
      PERFORM open_me47_for_quotation USING lv_call_ebeln.
      PERFORM get_data.
      rs_selfield-refresh    = abap_true.
      rs_selfield-col_stable = abap_true.
      rs_selfield-row_stable = abap_true.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form popup_choose_supplier
*&---------------------------------------------------------------------*
FORM popup_choose_supplier USING pv_ebelp TYPE ekpo-ebelp.

  TYPES: BEGIN OF ty_popup_opt,
           col_name TYPE slis_fieldname,
           lifnr    TYPE ekko-lifnr,
           name1    TYPE lfa1-name1,
           ebeln    TYPE ekko-ebeln,
           netpr    TYPE ekpo-netpr,
           waers    TYPE ekko-waers,
           rank     TYPE i,
         END OF ty_popup_opt.

  DATA: lt_opts   TYPE STANDARD TABLE OF ty_popup_opt,
        ls_opt    TYPE ty_popup_opt,
        lt_spopli TYPE STANDARD TABLE OF spopli,
        ls_spopli TYPE spopli,
        lv_answer TYPE c LENGTH 1.

  CLEAR: lt_opts, lt_spopli, lv_answer.

  READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref>) WITH KEY ebelp = pv_ebelp.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  IF <fs_ref>-po_number IS NOT INITIAL.
    MESSAGE |PO { <fs_ref>-po_number } already created for Item { pv_ebelp }.| TYPE 'W'.
    RETURN.
  ENDIF.

  DATA: lv_idx TYPE i VALUE 0.
  LOOP AT gt_hdr INTO DATA(ls_h).
    lv_idx = lv_idx + 1.
    IF ls_h-lifnr IS INITIAL.
      CONTINUE.
    ENDIF.

    READ TABLE gt_rfq_items INTO DATA(ls_q)
      WITH KEY ebelp = pv_ebelp lifnr = ls_h-lifnr.
    IF sy-subrc = 0 AND ls_q-netpr > 0.
      CLEAR ls_opt.
      ls_opt-col_name = |QUAT{ lv_idx }|.
      ls_opt-lifnr    = ls_q-lifnr.
      ls_opt-name1    = ls_q-name1.
      ls_opt-ebeln    = ls_q-ebeln.
      ls_opt-netpr    = ls_q-netpr.
      ls_opt-waers    = ls_q-waers.
      APPEND ls_opt TO lt_opts.
    ENDIF.
  ENDLOOP.

  IF lt_opts IS INITIAL.
    MESSAGE |No valid quotation with price found for Item { pv_ebelp }.| TYPE 'I'.
    RETURN.
  ENDIF.

  SORT lt_opts BY netpr ASCENDING.

  DATA: lv_r TYPE i VALUE 0.
  LOOP AT lt_opts ASSIGNING FIELD-SYMBOL(<fs_o>).
    lv_r = lv_r + 1.
    <fs_o>-rank = lv_r.
    CLEAR ls_spopli.
    DATA: lv_netpr_str TYPE c LENGTH 16.
    WRITE <fs_o>-netpr TO lv_netpr_str CURRENCY <fs_o>-waers NO-SIGN.
    CONDENSE lv_netpr_str.
    ls_spopli-varoption = |R{ lv_r }: { <fs_o>-name1(20) } - Qtn { <fs_o>-ebeln } - { lv_netpr_str } { <fs_o>-waers }|.
    APPEND ls_spopli TO lt_spopli.
  ENDLOOP.

  DATA: lv_title TYPE c LENGTH 60.
  lv_title = |Select Supplier for Item { pv_ebelp }|.

  CALL FUNCTION 'POPUP_TO_DECIDE_LIST'
    EXPORTING
      textline1 = 'Select supplier quotation to create Purchase Order:'
      titel     = lv_title
    IMPORTING
      answer    = lv_answer
    TABLES
      t_spopli  = lt_spopli
    EXCEPTIONS
      OTHERS    = 1.

  IF sy-subrc = 0 AND lv_answer BETWEEN '1' AND '9'.
    DATA(lv_chosen_idx) = CONV i( lv_answer ).
    READ TABLE lt_opts INTO ls_opt INDEX lv_chosen_idx.
    IF sy-subrc = 0.
      PERFORM select_supplier_for_item USING pv_ebelp ls_opt-col_name.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form select_supplier_for_item
*&---------------------------------------------------------------------*
FORM select_supplier_for_item USING pv_ebelp     TYPE ekpo-ebelp
                                    pv_fieldname TYPE slis_fieldname.

  DATA: lv_col_idx      TYPE i,
        lv_target_lifnr TYPE ekko-lifnr,
        lv_target_name1 TYPE lfa1-name1.

  CASE pv_fieldname.
    WHEN 'QUAT1'. lv_col_idx = 1.
    WHEN 'QUAT2'. lv_col_idx = 2.
    WHEN 'QUAT3'. lv_col_idx = 3.
    WHEN 'QUAT4'. lv_col_idx = 4.
    WHEN 'QUAT5'. lv_col_idx = 5.
    WHEN 'QUAT6'. lv_col_idx = 6.
    WHEN 'QUAT7'. lv_col_idx = 7.
    WHEN OTHERS.  RETURN.
  ENDCASE.

  IF lv_col_idx > lines( gt_hdr ).
    RETURN.
  ENDIF.

  lv_target_lifnr = gt_hdr[ lv_col_idx ]-lifnr.
  lv_target_name1 = gt_hdr[ lv_col_idx ]-name1.

  READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref>) WITH KEY ebelp = pv_ebelp.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  IF <fs_ref>-po_number IS NOT INITIAL.
    MESSAGE |PO { <fs_ref>-po_number } already created for Item { pv_ebelp } / Material { <fs_ref>-matnr }. Supplier change disabled.| TYPE 'W'.
    RETURN.
  ENDIF.

  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_val_cur>)
    WITH KEY ebelp = pv_ebelp quat = 'Val:'.
  IF sy-subrc = 0 AND <fs_ref>-sel_col = pv_fieldname
     AND ( <fs_val_cur>-sel CS '[X]' OR <fs_val_cur>-sel CS '@01@' ).
    PERFORM deselect_item USING pv_ebelp.
    MESSAGE |Deselected supplier '{ lv_target_name1 }' for Item { pv_ebelp }.| TYPE 'S'.
    RETURN.
  ENDIF.

  " Verify quotation exists for this supplier and item
  READ TABLE gt_rfq_items INTO DATA(ls_rfq)
    WITH KEY ebelp = pv_ebelp lifnr = lv_target_lifnr.
  IF sy-subrc <> 0.
    MESSAGE |Supplier '{ lv_target_name1 }' has no quotation for Item { pv_ebelp }.| TYPE 'I'.
    RETURN.
  ENDIF.

  IF ls_rfq-netpr <= 0.
    MESSAGE |Supplier '{ lv_target_name1 }' has no valid price entered for Item { pv_ebelp }.| TYPE 'I'.
    RETURN.
  ENDIF.

  " Update selected supplier details in reference table
  <fs_ref>-sel_col   = pv_fieldname.
  <fs_ref>-sel_ebeln = ls_rfq-ebeln.
  <fs_ref>-sel_ebelp = ls_rfq-ebelp.
  <fs_ref>-sel_lifnr = ls_rfq-lifnr.
  <fs_ref>-sel_name1 = ls_rfq-name1.
  <fs_ref>-sel_netpr = ls_rfq-netpr.
  <fs_ref>-sel_peinh = ls_rfq-peinh.
  <fs_ref>-sel_waers = ls_rfq-waers.
  <fs_ref>-sel_zterm = ls_rfq-zterm.
  <fs_ref>-sel_inco1 = ls_rfq-inco1.
  <fs_ref>-bukrs     = COND #( WHEN ls_rfq-bukrs IS NOT INITIAL THEN ls_rfq-bukrs ELSE '1000' ).
  <fs_ref>-ekorg     = COND #( WHEN ls_rfq-ekorg IS NOT INITIAL THEN ls_rfq-ekorg ELSE 'AE01' ).
  <fs_ref>-ekgrp     = COND #( WHEN ls_rfq-ekgrp IS NOT INITIAL THEN ls_rfq-ekgrp ELSE '101' ).

  " Update Val: Row (Checkbox and Action Button)
  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_val>)
    WITH KEY ebelp = pv_ebelp quat = 'Val:'.
  IF sy-subrc = 0.
    <fs_val>-sel       = '@01@ [X]'.
    <fs_val>-po_action = |@0Y@ PO -> { lv_target_name1(12) }|.
  ENDIF.

  " Update Approved Row (Selection indicator [X] Yes / [ ] and green color)
  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_app>)
    WITH KEY ebelp = pv_ebelp quat = 'Approved'.
  IF sy-subrc = 0.
    IF lines( gt_hdr ) >= 1. <fs_app>-quat1 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 2. <fs_app>-quat2 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 3. <fs_app>-quat3 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 4. <fs_app>-quat4 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 5. <fs_app>-quat5 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 6. <fs_app>-quat6 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 7. <fs_app>-quat7 = '[ ]'. ENDIF.

    CLEAR <fs_app>-cell_colors.

    ASSIGN COMPONENT pv_fieldname OF STRUCTURE <fs_app> TO FIELD-SYMBOL(<fs_cell>).
    IF sy-subrc = 0.
      <fs_cell> = '[X] Yes'.
      APPEND VALUE #( fieldname = pv_fieldname color = VALUE #( col = 5 int = 1 ) ) TO <fs_app>-cell_colors.
    ENDIF.
  ENDIF.

  PERFORM update_header_sel_state.

  MESSAGE |Selected supplier '{ lv_target_name1 }' for Item { pv_ebelp } ({ <fs_ref>-txz01 }).| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form toggle_item_selection
*&---------------------------------------------------------------------*
FORM toggle_item_selection USING pv_ebelp TYPE ekpo-ebelp.

  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_val_row>)
    WITH KEY ebelp = pv_ebelp quat = 'Val:'.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref>)
    WITH KEY ebelp = pv_ebelp.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  IF <fs_ref>-po_number IS NOT INITIAL.
    MESSAGE |PO { <fs_ref>-po_number } already created for Item { pv_ebelp } / Material { <fs_ref>-matnr }. Selection disabled.| TYPE 'W'.
    RETURN.
  ENDIF.

  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_app>)
    WITH KEY ebelp = pv_ebelp quat = 'Approved'.

  IF <fs_val_row>-sel CS '[X]' OR <fs_val_row>-sel CS '@01@'.
    " Currently checked -> Toggle to Unchecked
    PERFORM deselect_item USING pv_ebelp.
    MESSAGE |Item { pv_ebelp } deselected.| TYPE 'S'.
  ELSE.
    " Currently unchecked -> User clicked [ ] checkbox or row
    " If no supplier chosen yet, open popup to let user choose supplier
    IF <fs_ref>-sel_lifnr IS INITIAL.
      PERFORM popup_choose_supplier USING pv_ebelp.
      RETURN.
    ENDIF.

    <fs_val_row>-sel = '@01@ [X]'.
    <fs_val_row>-po_action = |@0Y@ PO -> { <fs_ref>-sel_name1(12) }|.

    IF sy-subrc = 0.
      IF lines( gt_hdr ) >= 1. <fs_app>-quat1 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 2. <fs_app>-quat2 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 3. <fs_app>-quat3 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 4. <fs_app>-quat4 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 5. <fs_app>-quat5 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 6. <fs_app>-quat6 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 7. <fs_app>-quat7 = '[ ]'. ENDIF.
      CLEAR <fs_app>-cell_colors.

      IF <fs_ref>-sel_col IS NOT INITIAL.
        ASSIGN COMPONENT <fs_ref>-sel_col OF STRUCTURE <fs_app> TO FIELD-SYMBOL(<fs_cell>).
        IF sy-subrc = 0.
          <fs_cell> = '[X] Yes'.
          APPEND VALUE #( fieldname = <fs_ref>-sel_col color = VALUE #( col = 5 int = 1 ) )
            TO <fs_app>-cell_colors.
        ENDIF.
      ENDIF.
    ENDIF.

    MESSAGE |Item { pv_ebelp } selected for PO creation (Supplier: { <fs_ref>-sel_name1 }).| TYPE 'S'.
  ENDIF.

  PERFORM update_header_sel_state.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form open_me47_for_quotation
*&---------------------------------------------------------------------*
FORM open_me47_for_quotation USING pv_ebeln TYPE ekko-ebeln.

  DATA: lv_rfq TYPE ekko-ebeln.
  lv_rfq = pv_ebeln.
  CONDENSE lv_rfq.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_rfq
    IMPORTING
      output = lv_rfq.

  IF lv_rfq IS INITIAL.
    RETURN.
  ENDIF.

  " Set Parameter IDs for RFQ / Quotation (ANF) and Purchasing Document (BES)
  SET PARAMETER ID 'ANF' FIELD lv_rfq.
  SET PARAMETER ID 'BES' FIELD lv_rfq.

  " Open ME47 interactively in foreground and skip initial screen so user lands on item overview
  CALL TRANSACTION 'ME47' AND SKIP FIRST SCREEN.     "#EC CI_CALLTA
  IF sy-subrc <> 0.
    CALL TRANSACTION 'ME47'.                         "#EC CI_CALLTA
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form toggle_select_all
*&---------------------------------------------------------------------*
FORM toggle_select_all.
  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_hdr>) INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  DATA: lv_check_all TYPE abap_bool.

  IF <fs_hdr>-sel CS '[X]' OR <fs_hdr>-sel CS '@01@'.
    lv_check_all = abap_false.
    <fs_hdr>-sel = '@R7@ [ ]All'.
  ELSE.
    lv_check_all = abap_true.
    <fs_hdr>-sel = '@01@ [X]All'.
  ENDIF.

  IF lv_check_all = abap_false.
    " Deselect all pending items
    LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_it_des>) WHERE po_number IS INITIAL.
      PERFORM deselect_item USING <fs_it_des>-ebelp.
    ENDLOOP.
    MESSAGE 'All quotation items deselected.' TYPE 'S'.
  ELSE.
    " Select only items where user has already chosen a supplier
    DATA: lv_count_sel TYPE i VALUE 0.
    LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_item>) WHERE po_number IS INITIAL.
      IF <fs_item>-sel_lifnr IS NOT INITIAL.
        lv_count_sel = lv_count_sel + 1.
        READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_val>)
          WITH KEY ebelp = <fs_item>-ebelp quat = 'Val:'.
        IF sy-subrc = 0.
          <fs_val>-sel = '@01@ [X]'.
          <fs_val>-po_action = |@0Y@ PO -> { <fs_item>-sel_name1(12) }|.
        ENDIF.
        READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_app_all>)
          WITH KEY ebelp = <fs_item>-ebelp quat = 'Approved'.
        IF sy-subrc = 0.
          IF lines( gt_hdr ) >= 1. <fs_app_all>-quat1 = '[ ]'. ENDIF.
          IF lines( gt_hdr ) >= 2. <fs_app_all>-quat2 = '[ ]'. ENDIF.
          IF lines( gt_hdr ) >= 3. <fs_app_all>-quat3 = '[ ]'. ENDIF.
          IF lines( gt_hdr ) >= 4. <fs_app_all>-quat4 = '[ ]'. ENDIF.
          IF lines( gt_hdr ) >= 5. <fs_app_all>-quat5 = '[ ]'. ENDIF.
          IF lines( gt_hdr ) >= 6. <fs_app_all>-quat6 = '[ ]'. ENDIF.
          IF lines( gt_hdr ) >= 7. <fs_app_all>-quat7 = '[ ]'. ENDIF.
          CLEAR <fs_app_all>-cell_colors.
          IF <fs_item>-sel_col IS NOT INITIAL.
            ASSIGN COMPONENT <fs_item>-sel_col OF STRUCTURE <fs_app_all> TO FIELD-SYMBOL(<fs_c>).
            IF sy-subrc = 0.
              <fs_c> = '[X] Yes'.
              APPEND VALUE #( fieldname = <fs_item>-sel_col color = VALUE #( col = 5 int = 1 ) )
                TO <fs_app_all>-cell_colors.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF lv_count_sel > 0.
      MESSAGE |{ lv_count_sel } items selected for PO creation.| TYPE 'S'.
    ELSE.
      <fs_hdr>-sel = '@R7@ [ ]All'.
      MESSAGE 'No suppliers chosen yet. Please click on the supplier column for each item first.' TYPE 'I'.
    ENDIF.
  ENDIF.

  PERFORM update_header_sel_state.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form update_header_sel_state
*&---------------------------------------------------------------------*
FORM update_header_sel_state.
  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_hdr>) INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  DATA: lv_all_checked   TYPE abap_bool VALUE abap_true,
        lv_pending_items TYPE abap_bool VALUE abap_false.

  LOOP AT gt_item_ref INTO DATA(ls_ir_chk) WHERE po_number IS INITIAL.
    lv_pending_items = abap_true.
    READ TABLE gt_final INTO DATA(ls_chk) WITH KEY ebelp = ls_ir_chk-ebelp quat = 'Val:'.
    IF sy-subrc = 0.
      IF NOT ( ls_chk-sel CS '[X]' OR ls_chk-sel CS '@01@' ).
        lv_all_checked = abap_false.
        EXIT.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF lv_pending_items = abap_true AND lv_all_checked = abap_true.
    <fs_hdr>-sel = '@01@ [X]All'.
  ELSEIF lv_pending_items = abap_false.
    <fs_hdr>-sel = '@02@ Done'.
  ELSE.
    <fs_hdr>-sel = '@R7@ [ ]All'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form create_po_for_selected
*&---------------------------------------------------------------------*
FORM create_po_for_selected USING pv_tabindex TYPE slis_selfield-tabindex.

  DATA: lt_sel_items TYPE STANDARD TABLE OF ty_item_ref.
  CLEAR lt_sel_items.

  " Check if all items in this collective group already have POs
  READ TABLE gt_item_ref WITH KEY po_number = space TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    MESSAGE 'All items in this collective group already have Purchase Orders created.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Step 1: Collect all items marked with [X] or @01@
  LOOP AT gt_final INTO DATA(ls_row) WHERE quat = 'Val:'.
    IF ls_row-sel CS '[X]' OR ls_row-sel CS '@01@'.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_r>) WITH KEY ebelp = ls_row-ebelp.
      IF sy-subrc = 0 AND <fs_r>-po_number IS INITIAL.
        IF <fs_r>-sel_lifnr IS INITIAL.
          PERFORM popup_choose_supplier USING <fs_r>-ebelp.
          IF <fs_r>-sel_lifnr IS INITIAL.
            MESSAGE 'PO creation cancelled. Supplier not chosen.' TYPE 'S'.
            RETURN.
          ENDIF.
        ENDIF.
        APPEND <fs_r> TO lt_sel_items.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Step 2: Fallback if no item was checked with [X]
  IF lt_sel_items IS INITIAL.
    " Check if user clicked or placed cursor on an item row (tabindex > 4)
    IF pv_tabindex > 4 AND pv_tabindex <= lines( gt_final ).
      DATA: lv_target_ebelp TYPE ekpo-ebelp.
      CLEAR lv_target_ebelp.
      READ TABLE gt_final INTO DATA(ls_cur_row) INDEX pv_tabindex.
      IF sy-subrc = 0.
        lv_target_ebelp = ls_cur_row-ebelp.
      ENDIF.
      " If clicked on separator row, scan next row
      IF lv_target_ebelp IS INITIAL AND pv_tabindex + 1 <= lines( gt_final ).
        DATA(lv_next_cur_idx) = pv_tabindex + 1.
        READ TABLE gt_final INTO DATA(ls_next_cur) INDEX lv_next_cur_idx.
        IF sy-subrc = 0.
          lv_target_ebelp = ls_next_cur-ebelp.
        ENDIF.
      ENDIF.

      IF lv_target_ebelp IS NOT INITIAL.
        READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_r_cur>) WITH KEY ebelp = lv_target_ebelp.
        IF sy-subrc = 0.
          IF <fs_r_cur>-po_number IS NOT INITIAL.
            MESSAGE |Purchase Order { <fs_r_cur>-po_number } already exists for Item { lv_target_ebelp } / Material { <fs_r_cur>-matnr }.|
              TYPE 'W'.
            RETURN.
          ENDIF.
          IF <fs_r_cur>-sel_lifnr IS INITIAL.
            PERFORM popup_choose_supplier USING lv_target_ebelp.
            IF <fs_r_cur>-sel_lifnr IS INITIAL.
              MESSAGE 'PO creation cancelled. Supplier not chosen.' TYPE 'S'.
              RETURN.
            ENDIF.
          ENDIF.
          APPEND <fs_r_cur> TO lt_sel_items.

          " Mark visual checkbox in table
          READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_val_m>)
            WITH KEY ebelp = lv_target_ebelp quat = 'Val:'.
          IF sy-subrc = 0.
            <fs_val_m>-sel = '@01@ [X]'.
            IF <fs_r_cur>-sel_name1 IS NOT INITIAL.
              <fs_val_m>-po_action = |@0Y@ PO -> { <fs_r_cur>-sel_name1(12) }|.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  " Step 3: Prompt if still initial (user clicked Header Create PO with no [X] checked)
  IF lt_sel_items IS INITIAL.
    MESSAGE 'No items selected for PO creation. Please select supplier for items by clicking the quotation column.'
      TYPE 'I'.
    RETURN.
  ENDIF.

  " Build distinct vendors from selected items
  DATA: lt_vendors TYPE ty_t_vendors,
        ls_vend    TYPE ty_vend_group.

  LOOP AT lt_sel_items INTO DATA(ls_si).
    ls_vend-lifnr = ls_si-sel_lifnr.
    ls_vend-name1 = ls_si-sel_name1.
    ls_vend-bukrs = COND #( WHEN ls_si-bukrs IS NOT INITIAL THEN ls_si-bukrs ELSE '1000' ).
    ls_vend-ekorg = COND #( WHEN ls_si-ekorg IS NOT INITIAL THEN ls_si-ekorg ELSE 'AE01' ).
    ls_vend-ekgrp = COND #( WHEN ls_si-ekgrp IS NOT INITIAL THEN ls_si-ekgrp ELSE '101' ).
    ls_vend-zterm = ls_si-sel_zterm.
    ls_vend-inco1 = ls_si-sel_inco1.
    APPEND ls_vend TO lt_vendors.
  ENDLOOP.

  SORT lt_vendors BY lifnr.
  DELETE ADJACENT DUPLICATES FROM lt_vendors COMPARING lifnr.

  " Confirmation Dialog
  DATA: lv_answer   TYPE c LENGTH 1,
        lv_msg      TYPE c LENGTH 128,
        lv_num_vend TYPE i,
        lv_num_item TYPE i.

  lv_num_vend = lines( lt_vendors ).
  lv_num_item = lines( lt_sel_items ).

  IF lv_num_vend = 1.
    READ TABLE lt_vendors INTO ls_vend INDEX 1.
    IF p_test = abap_true.
      lv_msg = |SIMULATION: Validate PO for { lv_num_item } item(s) (Supplier: { ls_vend-name1 })?|.
    ELSE.
      lv_msg = |Create Purchase Order for { lv_num_item } item(s) with Supplier { ls_vend-name1 }?|.
    ENDIF.
  ELSE.
    IF p_test = abap_true.
      lv_msg = |SIMULATION: Validate { lv_num_vend } POs for { lv_num_item } items across { lv_num_vend } suppliers?|.
    ELSE.
      lv_msg = |Create { lv_num_vend } Purchase Orders for { lv_num_item } items across { lv_num_vend } suppliers?|.
    ENDIF.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Confirm PO Creation'
      text_question         = lv_msg
      text_button_1         = 'Yes, Create PO'
      text_button_2         = 'Cancel'
      default_button        = '1'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      OTHERS                = 1.

  IF lv_answer NE '1'.
    MESSAGE 'PO Creation cancelled by user.' TYPE 'S'.
    RETURN.
  ENDIF.

  DATA: lt_created_pos TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
        lv_created_po  TYPE ekko-ebeln,
        lv_last_err    TYPE string.

  LOOP AT lt_vendors INTO ls_vend.
    CLEAR: lv_created_po, lv_last_err.
    PERFORM execute_bapi_po_create USING ls_vend lt_sel_items
                                   CHANGING lv_created_po lv_last_err.
    IF lv_created_po IS NOT INITIAL.
      APPEND |PO { lv_created_po } ({ ls_vend-name1 })| TO lt_created_pos.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_true.
    IF lv_last_err IS NOT INITIAL.
      MESSAGE |Simulation error: { lv_last_err }| TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.
      MESSAGE 'SIMULATION SUCCESSFUL: PO validated with 0 errors.' TYPE 'S'.
    ENDIF.
  ELSEIF lines( lt_created_pos ) > 0.
    DATA: lv_summary TYPE string.
    CLEAR lv_summary.
    LOOP AT lt_created_pos INTO DATA(lv_cpo).
      IF lv_summary IS INITIAL.
        lv_summary = lv_cpo.
      ELSE.
        lv_summary = |{ lv_summary }, { lv_cpo }|.
      ENDIF.
    ENDLOOP.
    MESSAGE |PO Created Successfully: { lv_summary }| TYPE 'S'.
  ELSE.
    IF lv_last_err IS NOT INITIAL.
      MESSAGE |PO creation failed: { lv_last_err }| TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.
      MESSAGE 'Purchase Order could not be created. Please review quotation data.' TYPE 'W'.
    ENDIF.
  ENDIF.

  PERFORM update_header_sel_state.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form create_po_for_single_item
*&---------------------------------------------------------------------*
FORM create_po_for_single_item USING pv_ebelp TYPE ekpo-ebelp.

  READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref>) WITH KEY ebelp = pv_ebelp.
  IF sy-subrc = 0 AND <fs_ref>-po_number IS NOT INITIAL.
    MESSAGE |PO { <fs_ref>-po_number } already created for Item { pv_ebelp }.| TYPE 'W'.
    RETURN.
  ENDIF.

  IF sy-subrc = 0 AND <fs_ref>-sel_lifnr IS INITIAL.
    PERFORM popup_choose_supplier USING pv_ebelp.
    IF <fs_ref>-sel_lifnr IS INITIAL.
      MESSAGE 'PO creation cancelled. Supplier not chosen.' TYPE 'S'.
      RETURN.
    ENDIF.
  ENDIF.

  " Mark item as checked if not already checked, then create PO
  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_v>) WITH KEY ebelp = pv_ebelp quat = 'Val:'.
  IF sy-subrc = 0.
    <fs_v>-sel = '@01@ [X]'.
  ENDIF.
  PERFORM create_po_for_selected USING 0.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form execute_bapi_po_create
*&---------------------------------------------------------------------*
FORM execute_bapi_po_create USING ps_vend     TYPE ty_vend_group
                                  pt_items    TYPE ty_t_item_ref
                            CHANGING pv_new_po TYPE ekko-ebeln
                                     cv_err    TYPE string.

  CLEAR: pv_new_po, cv_err.
  IF ps_vend-lifnr IS INITIAL.
    RETURN.
  ENDIF.

  DATA: ls_poheader    TYPE bapimepoheader,
        ls_poheaderx   TYPE bapimepoheaderx,
        lt_poitem      TYPE STANDARD TABLE OF bapimepoitem,
        ls_poitem      TYPE bapimepoitem,
        lt_poitemx     TYPE STANDARD TABLE OF bapimepoitemx,
        ls_poitemx     TYPE bapimepoitemx,
        lt_poschedule  TYPE STANDARD TABLE OF bapimeposchedule,
        ls_poschedule  TYPE bapimeposchedule,
        lt_poschedulex TYPE STANDARD TABLE OF bapimeposchedulx,
        ls_poschedulex TYPE bapimeposchedulx,
        lt_return      TYPE STANDARD TABLE OF bapiret2,
        lv_po_num      TYPE bapimepoheader-po_number,
        lv_item_no     TYPE numc5 VALUE '00000'.

  DATA: lv_deliv_date  TYPE d.
  lv_deliv_date = sy-datum + 14.

  CLEAR: ls_poheader, ls_poheaderx, lt_poitem, lt_poitemx,
         lt_poschedule, lt_poschedulex, lt_return, lv_po_num.

  " Header
  ls_poheader-comp_code  = COND #( WHEN ps_vend-bukrs IS NOT INITIAL THEN ps_vend-bukrs ELSE '1000' ).
  ls_poheader-doc_type   = COND #( WHEN p_bsart IS NOT INITIAL THEN p_bsart ELSE 'NB' ).
  ls_poheader-vendor     = ps_vend-lifnr.
  ls_poheader-purch_org  = COND #( WHEN ps_vend-ekorg IS NOT INITIAL THEN ps_vend-ekorg ELSE 'AE01' ).
  ls_poheader-pur_group  = COND #( WHEN ps_vend-ekgrp IS NOT INITIAL THEN ps_vend-ekgrp ELSE '101' ).
  ls_poheader-doc_date   = sy-datum.
  " Header Quotation Reference, Payment Terms, and Incoterms
  DATA: lv_q_zterm   TYPE ekko-zterm,
        lv_q_inco1   TYPE ekko-inco1,
        lv_q_inco2   TYPE ekko-inco2,
        lv_q_inco2_l TYPE ekko-inco2_l.
  CLEAR: lv_q_zterm, lv_q_inco1, lv_q_inco2, lv_q_inco2_l.

  IF pt_items IS NOT INITIAL.
    READ TABLE pt_items INTO DATA(ls_first_item) INDEX 1.
    IF sy-subrc = 0 AND ls_first_item-sel_ebeln IS NOT INITIAL.
      SELECT SINGLE zterm, inco1, inco2, inco2_l FROM ekko
        WHERE ebeln = @ls_first_item-sel_ebeln
        INTO (@lv_q_zterm, @lv_q_inco1, @lv_q_inco2, @lv_q_inco2_l).

      ls_poheader-our_ref     = ls_first_item-sel_ebeln.
      ls_poheaderx-our_ref    = abap_true.
      IF ls_first_item-submi IS NOT INITIAL.
        ls_poheader-collect_no  = ls_first_item-submi.
        ls_poheaderx-collect_no = abap_true.
      ENDIF.
    ENDIF.
  ENDIF.

  " Payment Terms
  ls_poheader-pmnttrms = COND #( WHEN ps_vend-zterm IS NOT INITIAL THEN ps_vend-zterm
                                 WHEN lv_q_zterm IS NOT INITIAL THEN lv_q_zterm
                                 ELSE '' ).
  IF ls_poheader-pmnttrms IS INITIAL AND ps_vend-lifnr IS NOT INITIAL.
    SELECT SINGLE zterm FROM ekko
      WHERE bstyp = 'A' AND lifnr = @ps_vend-lifnr
      INTO @ls_poheader-pmnttrms.
  ENDIF.

  " Incoterms
  DATA(lv_final_inco1) = COND ekko-inco1( WHEN ps_vend-inco1 IS NOT INITIAL THEN ps_vend-inco1
                                          WHEN lv_q_inco1 IS NOT INITIAL THEN lv_q_inco1
                                          ELSE '' ).
  IF lv_final_inco1 IS INITIAL AND ps_vend-lifnr IS NOT INITIAL.
    SELECT SINGLE inco1 FROM ekko
      WHERE bstyp = 'A' AND lifnr = @ps_vend-lifnr
      INTO @lv_final_inco1.
  ENDIF.

  ls_poheaderx-comp_code  = abap_true.
  ls_poheaderx-doc_type   = abap_true.
  ls_poheaderx-vendor     = abap_true.
  ls_poheaderx-purch_org  = abap_true.
  ls_poheaderx-pur_group  = abap_true.
  ls_poheaderx-doc_date   = abap_true.

  IF ls_poheader-pmnttrms IS NOT INITIAL.
    ls_poheaderx-pmnttrms = abap_true.
  ENDIF.

  IF lv_final_inco1 IS NOT INITIAL.
    ls_poheader-incoterms1  = lv_final_inco1.
    ls_poheaderx-incoterms1 = abap_true.

    IF lv_q_inco2 IS INITIAL.
      lv_q_inco2 = 'Plant 1120'.
    ENDIF.
    IF lv_q_inco2_l IS INITIAL.
      lv_q_inco2_l = lv_q_inco2.
    ENDIF.

    ls_poheader-incoterms2   = lv_q_inco2.
    ls_poheader-incoterms2l  = lv_q_inco2_l.
    ls_poheaderx-incoterms2  = abap_true.
    ls_poheaderx-incoterms2l = abap_true.
  ENDIF.

  " Items
  LOOP AT pt_items INTO DATA(ls_item).
    IF ls_item-sel_lifnr <> ps_vend-lifnr.
      CONTINUE.
    ENDIF.

    lv_item_no = lv_item_no + 10.

    CLEAR: ls_poitem, ls_poitemx, ls_poschedule, ls_poschedulex.

    IF ls_item-werks IS INITIAL.
      ls_item-werks = '1120'.
    ENDIF.
    IF ls_item-meins IS INITIAL.
      SELECT SINGLE meins FROM ekpo
        WHERE ebeln = @ls_item-sel_ebeln AND ebelp = @ls_item-sel_ebelp
        INTO @ls_item-meins.
      IF ls_item-meins IS INITIAL.
        ls_item-meins = 'NOS'.
      ENDIF.
    ENDIF.

    " Storage Location
    DATA: lv_item_lgort TYPE ekpo-lgort.
    CLEAR lv_item_lgort.
    IF ls_item-sel_ebeln IS NOT INITIAL.
      SELECT SINGLE lgort FROM ekpo
        WHERE ebeln = @ls_item-sel_ebeln AND ebelp = @ls_item-sel_ebelp
        INTO @lv_item_lgort.
    ENDIF.
    IF lv_item_lgort IS INITIAL.
      SELECT SINGLE lgort FROM mard
        WHERE matnr = @ls_item-matnr AND werks = @ls_item-werks
        INTO @lv_item_lgort.
    ENDIF.
    IF lv_item_lgort IS INITIAL.
      lv_item_lgort = 'HS01'.
    ENDIF.

    " Determine tax code from RFQ/Quotation if maintained, else default standard
    DATA: lv_tax_code TYPE ekpo-mwskz.
    CLEAR lv_tax_code.
    SELECT SINGLE mwskz FROM ekpo
      WHERE ebeln = @ls_item-sel_ebeln AND ebelp = @ls_item-sel_ebelp
      INTO @lv_tax_code.
    IF lv_tax_code IS INITIAL.
      IF ps_vend-lifnr = '0000100952'.
        lv_tax_code = '1I'.
      ELSE.
        lv_tax_code = '1C'.
      ENDIF.
    ENDIF.

    DATA(lv_item_qty) = COND ekpo-menge( WHEN ls_item-menge > 0 THEN ls_item-menge ELSE 1 ).

    ls_poitem-po_item     = lv_item_no.
    ls_poitem-material    = ls_item-matnr.
    ls_poitem-plant       = ls_item-werks.
    ls_poitem-stge_loc    = lv_item_lgort.
    ls_poitem-quantity    = lv_item_qty.
    ls_poitem-po_unit     = ls_item-meins.
    ls_poitem-net_price   = ls_item-sel_netpr.
    ls_poitem-price_unit  = COND #( WHEN ls_item-sel_peinh > 0 THEN ls_item-sel_peinh ELSE 1 ).
    ls_poitem-tax_code    = lv_tax_code.
    ls_poitem-trackingno  = ls_item-sel_ebeln.

    ls_poitemx-po_item     = lv_item_no.
    ls_poitemx-po_itemx    = abap_true.
    ls_poitemx-material    = abap_true.
    ls_poitemx-plant       = abap_true.
    ls_poitemx-stge_loc    = abap_true.
    ls_poitemx-quantity    = abap_true.
    ls_poitemx-po_unit     = abap_true.
    IF ls_item-sel_netpr > 0.
      ls_poitemx-net_price  = abap_true.
      ls_poitemx-price_unit = abap_true.
    ENDIF.
    ls_poitemx-tax_code    = abap_true.
    ls_poitemx-trackingno  = abap_true.

    APPEND ls_poitem TO lt_poitem.
    APPEND ls_poitemx TO lt_poitemx.

    " Schedule Line
    ls_poschedule-po_item        = lv_item_no.
    ls_poschedule-sched_line     = '0001'.
    ls_poschedule-delivery_date  = lv_deliv_date.
    ls_poschedule-stat_date      = lv_deliv_date.
    ls_poschedule-quantity       = lv_item_qty.

    ls_poschedulex-po_item        = lv_item_no.
    ls_poschedulex-sched_line     = '0001'.
    ls_poschedulex-po_itemx       = abap_true.
    ls_poschedulex-sched_linex    = abap_true.
    ls_poschedulex-delivery_date  = abap_true.
    ls_poschedulex-stat_date      = abap_true.
    ls_poschedulex-quantity       = abap_true.

    APPEND ls_poschedule TO lt_poschedule.
    APPEND ls_poschedulex TO lt_poschedulex.
  ENDLOOP.

  IF lt_poitem IS INITIAL.
    RETURN.
  ENDIF.

  " Execute BAPI
  CALL FUNCTION 'BAPI_PO_CREATE1'
    EXPORTING
      poheader         = ls_poheader
      poheaderx        = ls_poheaderx
      testrun          = p_test
    IMPORTING
      exppurchaseorder = lv_po_num
    TABLES
      return           = lt_return
      poitem           = lt_poitem
      poitemx          = lt_poitemx
      poschedule       = lt_poschedule
      poschedulex      = lt_poschedulex.

  " Check return
  READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    READ TABLE lt_return WITH KEY type = 'A' TRANSPORTING NO FIELDS.
  ENDIF.

  IF sy-subrc = 0 OR ( p_test <> abap_true AND lv_po_num IS INITIAL ).
    " Error
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    CLEAR cv_err.
    LOOP AT lt_return INTO DATA(ls_r) WHERE type = 'E' OR type = 'A'.
      DATA(lv_msg_text) = ls_r-message.
      IF lv_msg_text IS INITIAL.
        MESSAGE ID ls_r-id TYPE ls_r-type NUMBER ls_r-number
          WITH ls_r-message_v1 ls_r-message_v2 ls_r-message_v3 ls_r-message_v4
          INTO lv_msg_text.
      ENDIF.
      IF cv_err IS INITIAL.
        cv_err = lv_msg_text.
      ELSE.
        cv_err = |{ cv_err } / { lv_msg_text }|.
      ENDIF.
    ENDLOOP.
    IF cv_err IS INITIAL.
      cv_err = 'No purchase order number generated by BAPI.'.
    ENDIF.

  ELSE.
    " Success
    IF p_test = abap_true.
      MESSAGE 'Simulation successful: PO validated.' TYPE 'S'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      pv_new_po = lv_po_num.

      " Update display and reference internal tables
      LOOP AT pt_items INTO DATA(ls_done_item) WHERE sel_lifnr = ps_vend-lifnr.
        " Update gt_item_ref
        READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref>)
          WITH KEY ebelp = ls_done_item-ebelp.
        IF sy-subrc = 0.
          <fs_ref>-po_number = lv_po_num.
        ENDIF.

        " Update gt_final
        READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_f>)
          WITH KEY ebelp = ls_done_item-ebelp quat = 'Val:'.
        IF sy-subrc = 0.
          <fs_f>-po_action = |@0V@ PO { lv_po_num }|.
          <fs_f>-sel       = '@02@ Created'.
        ENDIF.

        READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_app_d>)
          WITH KEY ebelp = ls_done_item-ebelp quat = 'Approved'.
        IF sy-subrc = 0.
          IF lines( gt_hdr ) >= 1. <fs_app_d>-quat1 = '[PO Done]'. ENDIF.
          IF lines( gt_hdr ) >= 2. <fs_app_d>-quat2 = '[PO Done]'. ENDIF.
          IF lines( gt_hdr ) >= 3. <fs_app_d>-quat3 = '[PO Done]'. ENDIF.
          IF lines( gt_hdr ) >= 4. <fs_app_d>-quat4 = '[PO Done]'. ENDIF.
          IF lines( gt_hdr ) >= 5. <fs_app_d>-quat5 = '[PO Done]'. ENDIF.
          IF lines( gt_hdr ) >= 6. <fs_app_d>-quat6 = '[PO Done]'. ENDIF.
          IF lines( gt_hdr ) >= 7. <fs_app_d>-quat7 = '[PO Done]'. ENDIF.
        ENDIF.
      ENDLOOP.
      PERFORM update_header_sel_state.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_batch_list
*&---------------------------------------------------------------------*
FORM display_batch_list.
  WRITE: / 'PRICE COMPARISON REPORT (ZPQC_NEW / ZMM_R_ME49N)' COLOR COL_HEADING.
  ULINE.
  LOOP AT gt_final INTO DATA(ls_out).
    WRITE: / ls_out-sel,
             (18) ls_out-matnr,
             (35) ls_out-maktx,
             (8)  ls_out-quat,
             (15) ls_out-quat1,
             (15) ls_out-quat2,
             (15) ls_out-mean,
             (15) ls_out-minimum,
             (25) ls_out-po_action.
  ENDLOOP.
ENDFORM.

*----------------------------------------------------------------------*
* HTML Event Handler Implementation
*----------------------------------------------------------------------*
CLASS lcl_html_handler IMPLEMENTATION.
  METHOD on_sapevent.
    PERFORM handle_html_action USING action getdata.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*& Form display_html
*&---------------------------------------------------------------------*
FORM display_html.

  IF go_html IS INITIAL.
    IF cl_gui_container=>default_screen IS BOUND.
      CREATE OBJECT go_html
        EXPORTING
          parent = cl_gui_container=>default_screen.
    ELSE.
      CREATE OBJECT go_docking
        EXPORTING
          repid                   = sy-repid
          dynnr                   = sy-dynnr
          side                    = cl_gui_docking_container=>dock_at_top
          extension               = 2000
          no_autodef_progid_dynnr = 'X'.

      CREATE OBJECT go_html
        EXPORTING
          parent = go_docking.
    ENDIF.

    DATA: lt_events TYPE cntl_simple_events.
    lt_events = VALUE #( ( eventid = cl_gui_html_viewer=>m_id_sapevent appl_event = '' ) ).
    go_html->set_registered_events( events = lt_events ).

    SET HANDLER lcl_html_handler=>on_sapevent FOR go_html.
  ENDIF.

  PERFORM render_html.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form render_html
*&---------------------------------------------------------------------*
FORM render_html.

  IF go_html IS INITIAL.
    RETURN.
  ENDIF.

  DATA: lv_html TYPE string,
        lv_css  TYPE string,
        wa_hdr  TYPE ty_hdr,
        ls_q    TYPE ty_rfq_item.

  " Compute selection totals
  DATA: lv_sel_items_count TYPE i VALUE 0,
        lv_done_items_cnt  TYPE i VALUE 0,
        lv_pending_cnt     TYPE i VALUE 0,
        lv_total_items_cnt TYPE i VALUE 0,
        lv_selected_total  TYPE decfloat34 VALUE 0,
        lv_all_sel         TYPE abap_bool VALUE abap_false.

  lv_total_items_cnt = lines( gt_item_ref ).
  LOOP AT gt_item_ref INTO DATA(ls_ir).
    IF ls_ir-po_number IS NOT INITIAL.
      lv_done_items_cnt = lv_done_items_cnt + 1.
      CONTINUE.
    ENDIF.
    lv_pending_cnt = lv_pending_cnt + 1.
    READ TABLE gt_final INTO DATA(ls_row) WITH KEY ebelp = ls_ir-ebelp quat = 'Val:'.
    IF sy-subrc = 0 AND ls_row-sel CS '[X]'.
      lv_sel_items_count = lv_sel_items_count + 1.
      IF ls_ir-sel_lifnr IS NOT INITIAL.
        READ TABLE gt_rfq_items INTO ls_q
          WITH KEY ebelp = ls_ir-ebelp lifnr = ls_ir-sel_lifnr.
        IF sy-subrc = 0.
          DATA(lv_pe) = COND ekpo-peinh( WHEN ls_q-peinh > 0 THEN ls_q-peinh ELSE 1 ).
          DATA(lv_sel_qty) = COND ekpo-menge( WHEN ls_ir-menge > 0 THEN ls_ir-menge
                                              WHEN ls_q-ktmng > 0 THEN ls_q-ktmng
                                              WHEN ls_q-menge > 0 THEN ls_q-menge
                                              ELSE 1 ).
          DATA(lv_amt_sel) = ( lv_sel_qty * ls_q-netpr ) / lv_pe.
          IF ls_q-waers = 'USD' AND ls_q-wkurs > 0.
            lv_amt_sel = lv_amt_sel * ls_q-wkurs.
          ENDIF.
          lv_selected_total = lv_selected_total + lv_amt_sel.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF lv_pending_cnt > 0 AND lv_sel_items_count = lv_pending_cnt.
    lv_all_sel = abap_true.
  ENDIF.

  DATA: lv_fmt_sel_tot TYPE string.
  PERFORM format_inr USING lv_selected_total CHANGING lv_fmt_sel_tot.

  lv_css =
    '<style>' &&
    '* { box-sizing: border-box; margin: 0; padding: 0; }' &&
    'html, body {' &&
    '  margin: 0; padding: 4px; background: #f1f5f9; width: 100%; box-sizing: border-box;' &&
    '  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;' &&
    '  color: #0f172a; font-size: 12px;' &&
    '}' &&
    '.container { width: 100%; max-width: 100%; margin: 0; padding: 0; }' &&
    '.top-header {' &&
    '  display: flex; justify-content: space-between; align-items: center;' &&
    '  padding: 5px 10px; background: #ffffff; border: 1px solid #94a3b8; border-radius: 4px;' &&
    '  margin-bottom: 5px; flex-wrap: wrap; gap: 8px;' &&
    '}' &&
    '.top-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }' &&
    '.top-right { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }' &&
    '.select-all-btn {' &&
    '  display: inline-flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600;' &&
    '  color: #1e293b; text-decoration: none; cursor: pointer;' &&
    '}' &&
    '.badge-count {' &&
    '  background: #f1f5f9; color: #334155; font-size: 11px; font-weight: 600;' &&
    '  padding: 2px 8px; border-radius: 12px; display: inline-block; border: 1px solid #cbd5e1;' &&
    '}' &&
    '.val-summary { font-size: 13px; font-weight: 700; color: #0f172a; }' &&
    '.rate-box {' &&
    '  display: inline-flex; align-items: center; gap: 4px; background: #ffffff;' &&
    '  padding: 2px 6px; border-radius: 4px; border: 1px solid #cbd5e1; font-size: 11px;' &&
    '  font-weight: 600; color: #334155;' &&
    '}' &&
    '.rate-input {' &&
    '  width: 48px; padding: 1px 3px; border: 1px solid #cbd5e1; border-radius: 3px;' &&
    '  font-weight: 700; text-align: center; background: #ffffff; outline: none; font-size: 11px;' &&
    '}' &&
    '.btn-apply {' &&
    '  background: #334155; color: #ffffff; border: none; border-radius: 3px;' &&
    '  padding: 2px 6px; font-size: 10px; font-weight: 600; cursor: pointer;' &&
    '}' &&
    '.btn-apply:hover { background: #1e293b; }' &&
    '.btn-refresh {' &&
    '  background: #ffffff; color: #374151; border: 1px solid #cbd5e1; border-radius: 4px;' &&
    '  padding: 3px 8px; font-size: 11px; font-weight: 600; text-decoration: none;' &&
    '  display: inline-flex; align-items: center; gap: 3px; cursor: pointer;' &&
    '}' &&
    '.btn-refresh:hover { background: #f1f5f9; border-color: #94a3b8; }' &&
    '.btn-po {' &&
    '  background: #059669; color: #ffffff; border-radius: 4px;' &&
    '  padding: 3px 12px; font-size: 11px; font-weight: 700; text-decoration: none;' &&
    '  display: inline-flex; align-items: center; gap: 4px; border: none; cursor: pointer;' &&
    '}' &&
    '.btn-po:hover { background: #047857; }' &&
    '.btn-po-disabled {' &&
    '  background: #e2e8f0; color: #94a3b8; border-radius: 4px; padding: 3px 12px;' &&
    '  font-size: 11px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px; pointer-events: none;' &&
    '}' &&
    '.radio-box {' &&
    '  display: inline-flex; align-items: center; justify-content: center; width: 18px; height: 18px;' &&
    '  border-radius: 50%; box-sizing: border-box; cursor: pointer; text-decoration: none;' &&
    '  vertical-align: middle; background: #ffffff;' &&
    '}' &&
    '.radio-unsel { border: 2px solid #94a3b8; }' &&
    '.radio-sel { border: 2px solid #2563eb; }' &&
    '.radio-dot { width: 8px; height: 8px; border-radius: 50%; background: #2563eb; display: block; }' &&
    '.cmp-table {' &&
    '  width: 100%; border-collapse: collapse; border: 1px solid #64748b; background: #ffffff;' &&
    '}' &&
    '.cmp-table th {' &&
    '  padding: 5px 6px; font-size: 11px; font-weight: 700; color: #0f172a;' &&
    '  text-align: left; vertical-align: middle; border: 1px solid #94a3b8; background: #e2e8f0;' &&
    '}' &&
    '.cmp-table td {' &&
    '  padding: 5px 6px; font-size: 12px; color: #0f172a; vertical-align: middle; border: 1px solid #cbd5e1;' &&
    '}' &&
    '.cmp-table tbody tr:hover { background: #f8fafc; }' &&
    '.cmp-table tbody tr:nth-child(even) { background: #fafbfc; }' &&
    '.v-hdr-title { font-size: 12px; font-weight: 700; color: #0f172a; line-height: 1.25; }' &&
    '.v-hdr-sub { font-size: 10px; font-weight: 500; color: #64748b; margin-top: 1px; }' &&
    '.mat-code { font-size: 12px; font-weight: 700; color: #0f172a; }' &&
    '.mat-desc { font-size: 12px; font-weight: 400; color: #334155; line-height: 1.3; }' &&
    '.mat-qty { font-size: 12px; font-weight: 700; color: #0f172a; }' &&
    '.quote-amt { font-size: 13px; font-weight: 700; color: #0f172a; }' &&
    '.quote-unit { font-size: 10px; color: #64748b; }' &&
    '.rank-lowest {' &&
    '  display: inline-block; background: #dcfce7; color: #15803d; font-size: 10px; font-weight: 700;' &&
    '  padding: 1px 5px; border-radius: 8px; border: 1px solid #86efac;' &&
    '}' &&
    '.rank-other {' &&
    '  display: inline-block; background: #f1f5f9; color: #64748b; font-size: 10px; font-weight: 600;' &&
    '  padding: 1px 5px; border-radius: 8px; border: 1px solid #cbd5e1;' &&
    '}' &&
    '.btn-pill-sel {' &&
    '  background: #2563eb; color: #ffffff; font-size: 10px; font-weight: 700;' &&
    '  padding: 2px 8px; border-radius: 4px; border: 1px solid #1d4ed8; text-decoration: none;' &&
    '  display: inline-block;' &&
    '}' &&
    '.btn-pill-unsel {' &&
    '  background: #ffffff; color: #334155; font-size: 10px; font-weight: 600;' &&
    '  padding: 2px 8px; border-radius: 4px; border: 1px solid #cbd5e1; text-decoration: none;' &&
    '  display: inline-block;' &&
    '}' &&
    '.btn-pill-unsel:hover { background: #f8fafc; border-color: #94a3b8; }' &&
    '.btn-po-link {' &&
    '  background: #059669; color: #ffffff; font-size: 10px; font-weight: 700;' &&
    '  padding: 2px 8px; border-radius: 4px; text-decoration: none; display: inline-block;' &&
    '}' &&
    '.quote-po-done {' &&
    '  background: #f1f5f9; color: #94a3b8; font-size: 10px; font-weight: 600;' &&
    '  padding: 2px 6px; border-radius: 4px; border: 1px solid #e2e8f0; display: inline-block;' &&
    '}' &&
    '.no-price-badge { color: #dc2626; font-size: 12px; font-weight: 700; }' &&
    '.no-price-sub { color: #64748b; font-size: 10px; font-weight: 500; }' &&
    '.no-price-link {' &&
    '  color: #2563eb; font-size: 10px; text-decoration: underline; display: inline-block;' &&
    '  margin-top: 2px; font-weight: 600;' &&
    '}' &&
    '.tot-label {' &&
    '  font-size: 11px; font-weight: 800; color: #0f172a; padding: 6px 8px;' &&
    '  border: 1px solid #64748b; background: #e2e8f0; text-transform: uppercase;' &&
    '}' &&
    '.tot-amt {' &&
    '  font-size: 12px; font-weight: 800; color: #0f172a; padding: 6px 8px;' &&
    '  border: 1px solid #64748b; background: #f8fafc; text-align: right;' &&
    '}' &&
    '.tot-min {' &&
    '  font-size: 12px; font-weight: 700; color: #059669; padding: 6px 8px;' &&
    '  border: 1px solid #64748b; background: #ecfdf5; text-align: right;' &&
    '}' &&
    '.comm-section {' &&
    '  margin-top: 8px; padding: 6px; background: #ffffff; border: 1px solid #94a3b8; border-radius: 4px;' &&
    '}' &&
    '.comm-title { font-size: 12px; font-weight: 700; color: #0f172a; margin-bottom: 5px; }' &&
    '.comm-tbl { width: 100%; border-collapse: collapse; border: 1px solid #64748b; }' &&
    '.comm-tbl th {' &&
    '  background: #e2e8f0; color: #0f172a; font-size: 11px; font-weight: 700;' &&
    '  text-align: left; padding: 5px 8px; border: 1px solid #94a3b8;' &&
    '}' &&
    '.comm-tbl td { padding: 5px 8px; font-size: 11px; border: 1px solid #cbd5e1; color: #0f172a; }' &&
    '.comm-tbl tr.highlight { background: #fefce8; font-weight: 600; }' &&
    '.comm-tbl tr.total-eval {' &&
    '  background: #dcfce7; font-weight: 800; font-size: 12px; color: #166534;' &&
    '  border-top: 2px solid #15803d; border-bottom: 2px solid #15803d;' &&
    '}' &&
    '</style>'.

  lv_html =
    '<!DOCTYPE html>' &&
    '<html lang="en"><head>' &&
    '<meta charset="utf-8">' &&
    '<meta http-equiv="X-UA-Compatible" content="IE=edge">' &&
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">' &&
    '<title>Quotation Price Comparison Dashboard (ZPQC_NEW v2.3)</title>' &&
    lv_css &&
    '</head><body>' &&
    '<div class="container">' &&
    '<div class="top-header">' &&
    '  <div class="top-left">' &&
    COND string(
      WHEN lv_total_items_cnt > 0 AND lv_done_items_cnt = lv_total_items_cnt THEN
        '<span style="display:inline-flex;align-items:center;gap:6px;font-size:12px;font-weight:700;' &&
        'color:#15803d;background:#dcfce7;padding:3px 10px;border-radius:12px;border:1px solid #86efac;">' &&
        '&#10003; All Line Items PO Created</span>'
      ELSE
        '<a href="sapevent:TOGGLE_ALL" class="select-all-btn">' &&
        COND string(
          WHEN lv_all_sel = abap_true THEN
            '<span class="radio-box radio-sel"><span class="radio-dot"></span></span>'
          ELSE
            '<span class="radio-box radio-unsel"></span>'
        ) &&
        '      <span>Select All</span>' &&
        '    </a>' &&
        |    <span class="badge-count">{ lv_sel_items_count } selected</span>|
    ) &&
    COND string(
      WHEN lv_done_items_cnt > 0 AND lv_done_items_cnt < lv_total_items_cnt THEN
        |    <span class="badge-count" style="background:#ecfdf5;color:#065f46;border:1px solid #a7f3d0;">{ lv_done_items_cnt } PO Done</span>|
      ELSE ''
    ) &&
    '    <span class="badge-count" style="font-size:10px;background:#e2e8f0;color:#334155;">v2.3</span>' &&
    '  </div>' &&
    '  <div class="top-right">' &&
    |    <span class="val-summary">Selected: &#8377;{ lv_fmt_sel_tot }</span>| &&
    '    <div class="rate-box">' &&
    '      <span>Rate:</span>' &&
    |      <input type="number" id="inpRate" value="{ p_rate DECIMALS = 2 }" step="0.25" class="rate-input" />| &&
    '      <span>%</span>' &&
    '      <button onclick="applyRate()" class="btn-apply">Apply</button>' &&
    '    </div>' &&
    '    <a href="sapevent:REFRESH" class="btn-refresh">&#128260; Refresh</a>' &&
    COND string(
      WHEN lv_sel_items_count > 0 THEN
        |<a href="sapevent:CREATE_PO" class="btn-po">&#128722; Create PO ({ lv_sel_items_count })</a>|
      ELSE
        '<span class="btn-po-disabled">&#128722; Create PO</span>'
    ) &&
    '  </div>' &&
    '</div>'.

  " Table header
  lv_html = lv_html &&
    '<table class="cmp-table">' &&
    '  <thead><tr>' &&
    '    <th style="width: 36px; text-align: center; vertical-align: middle;">Sel</th>' &&
    '    <th style="width: 110px;">Material</th>' &&
    '    <th style="min-width: 160px;">Material Description</th>' &&
    '    <th style="width: 65px; text-align: right;">Qty</th>'.

  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html &&
      '<th style="min-width: 135px;">' &&
      |  <div class="v-hdr-title">{ wa_hdr-name1 }</div>| &&
      |  <div class="v-hdr-sub">Vendor { wa_hdr-lifnr } · RFQ #{ wa_hdr-ebeln }</div>| &&
      '</th>'.
  ENDLOOP.

  lv_html = lv_html &&
    '    <th style="width: 105px; text-align: right; background: #ecfdf5; color: #065f46;">Minimum</th>' &&
    '    <th style="width: 135px; background: #eff6ff; color: #1e40af;">Selected Supplier</th>' &&
    '  </tr></thead><tbody>'.

  TYPES: BEGIN OF ty_temp_rank,
           lifnr  TYPE ekko-lifnr,
           amount TYPE decfloat34,
           rank   TYPE i,
         END OF ty_temp_rank.
  DATA: lt_tranks TYPE STANDARD TABLE OF ty_temp_rank WITH DEFAULT KEY,
        ls_trank  TYPE ty_temp_rank.

  LOOP AT gt_item_ref INTO DATA(ls_item).

    READ TABLE gt_final INTO DATA(ls_val_row) WITH KEY ebelp = ls_item-ebelp quat = 'Val:'.
    DATA(lv_row_sel) = xsdbool( sy-subrc = 0 AND ls_val_row-sel CS '[X]' ).

    CLEAR lt_tranks.
    DATA(lv_row_qty) = COND ekpo-menge( WHEN ls_item-menge > 0 THEN ls_item-menge ELSE 1 ).
    LOOP AT gt_rfq_items INTO ls_q WHERE ebelp = ls_item-ebelp AND netpr > 0.
      DATA(lv_peinh) = COND ekpo-peinh( WHEN ls_q-peinh > 0 THEN ls_q-peinh ELSE 1 ).
      DATA(lv_q_qty) = COND ekpo-menge( WHEN lv_row_qty > 0 THEN lv_row_qty
                                        WHEN ls_q-ktmng > 0 THEN ls_q-ktmng
                                        WHEN ls_q-menge > 0 THEN ls_q-menge
                                        ELSE 1 ).
      DATA(lv_amt) = ( lv_q_qty * ls_q-netpr ) / lv_peinh.
      IF ls_q-waers = 'USD' AND ls_q-wkurs > 0.
        lv_amt = lv_amt * ls_q-wkurs.
      ENDIF.
      APPEND VALUE #( lifnr = ls_q-lifnr amount = lv_amt ) TO lt_tranks.
    ENDLOOP.
    SORT lt_tranks BY amount ASCENDING.
    DATA(lv_curr_rank) = 1.
    LOOP AT lt_tranks ASSIGNING FIELD-SYMBOL(<fs_tr>).
      <fs_tr>-rank = lv_curr_rank.
      lv_curr_rank = lv_curr_rank + 1.
    ENDLOOP.

    DATA: lv_fmt_min TYPE string.
    CLEAR lv_fmt_min.
    IF lines( lt_tranks ) > 0.
      READ TABLE lt_tranks INTO ls_trank INDEX 1.
      IF ls_trank-amount > 0.
        PERFORM format_inr USING ls_trank-amount CHANGING lv_fmt_min.
      ELSEIF ls_val_row-minimum IS NOT INITIAL AND ls_val_row-minimum NE 'No Price'.
        PERFORM format_inr USING ls_val_row-minimum CHANGING lv_fmt_min.
      ELSE.
        lv_fmt_min = 'No Price'.
      ENDIF.
    ELSEIF ls_val_row-minimum IS NOT INITIAL AND ls_val_row-minimum NE 'No Price'.
      PERFORM format_inr USING ls_val_row-minimum CHANGING lv_fmt_min.
    ELSE.
      lv_fmt_min = 'No Price'.
    ENDIF.

    DATA(lv_qty_str) = COND string(
      WHEN frac( ls_item-menge ) = 0 THEN |{ CONV i( ls_item-menge ) }|
      ELSE |{ ls_item-menge DECIMALS = 2 }| ).

    IF ls_item-po_number IS NOT INITIAL.
      lv_html = lv_html &&
        '<tr>' &&
        '  <td style="text-align: center; vertical-align: middle;">' &&
        |    <a href="sapevent:ME23N?ebeln={ ls_item-po_number }" title="PO { ls_item-po_number } Created" style="text-decoration:none;">| &&
        '      <span style="display:inline-flex;align-items:center;justify-content:center;width:20px;height:20px;' &&
        '            border-radius:50%;background:#dcfce7;color:#166534;font-size:12px;font-weight:800;">&#10003;</span>' &&
        '    </a>' &&
        '  </td>' &&
        |  <td><div class="mat-code">{ ls_item-matnr }</div></td>| &&
        |  <td><div class="mat-desc">{ ls_item-txz01 }</div></td>| &&
        |  <td style="text-align: right;"><div class="mat-qty">{ lv_qty_str }</div></td>|.
    ELSE.
      lv_html = lv_html &&
        '<tr>' &&
        '  <td style="text-align: center; vertical-align: middle;">' &&
        |    <a href="sapevent:TOGGLE_ROW?item={ ls_item-ebelp }">| &&
        COND string(
          WHEN lv_row_sel = abap_true THEN
            '<span class="radio-box radio-sel"><span class="radio-dot"></span></span>'
          ELSE
            '<span class="radio-box radio-unsel"></span>'
        ) &&
        '    </a>' &&
        '  </td>' &&
        |  <td><div class="mat-code">{ ls_item-matnr }</div></td>| &&
        |  <td><div class="mat-desc">{ ls_item-txz01 }</div></td>| &&
        |  <td style="text-align: right;"><div class="mat-qty">{ lv_qty_str }</div></td>|.
    ENDIF.

    DATA(lv_cidx) = 1.
    LOOP AT gt_hdr INTO wa_hdr.
      DATA(lv_is_sel) = xsdbool( ls_item-sel_lifnr = wa_hdr-lifnr ).
      READ TABLE gt_rfq_items INTO DATA(ls_qitem)
        WITH KEY ebelp = ls_item-ebelp lifnr = wa_hdr-lifnr.

      IF sy-subrc = 0 AND ls_qitem-netpr > 0.
        READ TABLE lt_tranks INTO ls_trank WITH KEY lifnr = wa_hdr-lifnr.
        DATA(lv_rk) = ls_trank-rank.
        DATA(lv_item_total) = ls_trank-amount.

        IF lv_item_total <= 0.
          DATA(lv_v_qty) = COND ekpo-menge( WHEN ls_item-menge > 0 THEN ls_item-menge
                                            WHEN ls_qitem-ktmng > 0 THEN ls_qitem-ktmng
                                            WHEN ls_qitem-menge > 0 THEN ls_qitem-menge
                                            ELSE 1 ).
          DATA(lv_v_pe) = COND ekpo-peinh( WHEN ls_qitem-peinh > 0 THEN ls_qitem-peinh ELSE 1 ).
          lv_item_total = ( lv_v_qty * ls_qitem-netpr ) / lv_v_pe.
          IF ls_qitem-waers = 'USD' AND ls_qitem-wkurs > 0.
            lv_item_total = lv_item_total * ls_qitem-wkurs.
          ENDIF.
        ENDIF.

        IF lv_item_total <= 0.
          ASSIGN COMPONENT |QUAT{ lv_cidx }| OF STRUCTURE ls_val_row TO FIELD-SYMBOL(<fs_col_val>).
          IF sy-subrc = 0 AND <fs_col_val> IS NOT INITIAL AND <fs_col_val> NE 'No Price'.
            lv_item_total = CONV decfloat34( <fs_col_val> ).
          ENDIF.
        ENDIF.

        DATA: lv_fmt_tot TYPE string,
              lv_fmt_upr TYPE string.
        PERFORM format_inr USING lv_item_total CHANGING lv_fmt_tot.

        DATA(lv_uprice) = ls_qitem-netpr / COND #( WHEN ls_qitem-peinh > 0 THEN ls_qitem-peinh ELSE 1 ).
        PERFORM format_inr USING lv_uprice CHANGING lv_fmt_upr.

        DATA: lv_rank_pill TYPE string.
        IF lv_rk = 1.
          lv_rank_pill = '<span class="rank-lowest">L1 · Lowest</span>'.
        ELSE.
          lv_rank_pill = |<span class="rank-other">L{ lv_rk }</span>|.
        ENDIF.

        DATA: lv_pill_action TYPE string.
        IF ls_item-po_number IS NOT INITIAL.
          IF ls_item-sel_lifnr = wa_hdr-lifnr.
            lv_pill_action =
              |<a href="sapevent:ME23N?ebeln={ ls_item-po_number }" class="btn-po-link">&#10003; PO { ls_item-po_number }</a>|.
          ELSE.
            lv_pill_action = '<span class="quote-po-done">PO Done</span>'.
          ENDIF.
        ELSE.
          IF lv_is_sel = abap_true.
            lv_pill_action = |<a href="sapevent:DESELECT?item={ ls_item-ebelp }" class="btn-pill-sel">&#10003; Selected</a>|.
          ELSE.
            lv_pill_action = |<a href="sapevent:SELECT?item={ ls_item-ebelp }&col=QUAT{ lv_cidx }" class="btn-pill-unsel">Select</a>|.
          ENDIF.
        ENDIF.

        DATA(lv_td_bg) = COND string(
          WHEN lv_rk = 1
          THEN ' style="background: #f0fdf4; border-left: 2px solid #16a34a; border-right: 2px solid #16a34a;"'
          ELSE '' ).

        lv_html = lv_html &&
          |<td{ lv_td_bg }>| &&
          '  <div style="display: flex; justify-content: space-between; align-items: baseline; gap: 4px;">' &&
          |    <span class="quote-amt">&#8377;{ lv_fmt_tot }</span>| &&
          |    { lv_rank_pill }| &&
          '  </div>' &&
          |  <div class="quote-unit">Per unit: &#8377;{ lv_fmt_upr }</div>| &&
          |  <div style="margin-top: 3px;">{ lv_pill_action }</div>| &&
          '</td>'.

      ELSEIF sy-subrc = 0.
        lv_html = lv_html &&
          '<td style="background: #fff1f2; text-align: center;">' &&
          '  <div class="no-price-badge">No Price</div>' &&
          '  <div class="no-price-sub">Price not maintained</div>' &&
          |  <a href="sapevent:ME47?ebeln={ ls_qitem-ebeln }" class="no-price-link">&#9998; Maintain ME47</a>| &&
          '</td>'.
      ELSE.
        lv_html = lv_html &&
          '<td style="text-align: center; color: #94a3b8; font-style: italic;">' &&
          '  <div>No Quote</div>' &&
          '</td>'.
      ENDIF.

      lv_cidx = lv_cidx + 1.
    ENDLOOP.

    lv_html = lv_html &&
      '<td style="background: #f0fdf4; text-align: right;">' &&
      |  <div style="font-weight: 700; font-size: 13px; color: #15803d;">&#8377;{ lv_fmt_min }</div>| &&
      '</td>'.

    IF ls_item-po_number IS NOT INITIAL.
      lv_html = lv_html &&
        '<td style="background: #f8fafc;">' &&
        |  <div style="font-weight: 700; font-size: 12px; color: #0f172a;">{ ls_item-sel_name1 }</div>| &&
        |<a href="sapevent:ME23N?ebeln={ ls_item-po_number }" | &&
        'style="font-size: 11px; color: #059669; font-weight: 700; text-decoration: underline; margin-top: 2px; display: inline-block;">' &&
        |&#10003; PO { ls_item-po_number }</a>| &&
        '</td>'.
    ELSEIF ls_item-sel_name1 IS NOT INITIAL.
      DATA(lv_sel_state) = COND string(
        WHEN lv_row_sel = abap_true THEN
          '<span style="font-size: 11px; color: #2563eb; font-weight: 700;">Selected</span>'
        ELSE
          '<span style="font-size: 11px; color: #64748b;">Not selected</span>' ).

      lv_html = lv_html &&
        '<td style="background: #f8fafc;">' &&
        |  <div style="font-weight: 700; font-size: 12px; color: #0f172a;">{ ls_item-sel_name1 }</div>| &&
        |  <div style="margin-top: 2px;">{ lv_sel_state }</div>| &&
        '</td>'.
    ELSE.
      lv_html = lv_html &&
        '<td style="background: #f8fafc; text-align: center;"><span style="color: #94a3b8;">—</span></td>'.
    ENDIF.

    lv_html = lv_html && '</tr>'.

  ENDLOOP.

  lv_html = lv_html && '</tbody>'.

  " Total Quotation Amount row
  READ TABLE gt_final INTO DATA(ls_tot) WITH KEY maktx = 'Total Quotation Amount' ##READ_WHERE_OK.

  lv_html = lv_html &&
    '<tfoot><tr>' &&
    '  <td colspan="4" class="tot-label">Total quotation amount</td>'.

  LOOP AT gt_hdr INTO wa_hdr.
    DATA(lv_vidx) = sy-tabix.
    DATA: lv_vtot_raw TYPE string,
          lv_fmt_vtot TYPE string.
    CASE lv_vidx.
      WHEN 1. lv_vtot_raw = ls_tot-quat1.
      WHEN 2. lv_vtot_raw = ls_tot-quat2.
      WHEN 3. lv_vtot_raw = ls_tot-quat3.
      WHEN 4. lv_vtot_raw = ls_tot-quat4.
      WHEN 5. lv_vtot_raw = ls_tot-quat5.
      WHEN 6. lv_vtot_raw = ls_tot-quat6.
      WHEN 7. lv_vtot_raw = ls_tot-quat7.
    ENDCASE.
    PERFORM format_inr USING lv_vtot_raw CHANGING lv_fmt_vtot.
    IF lv_fmt_vtot = 'No Price'.
      lv_html = lv_html && |<td class="tot-amt" style="color: #dc2626;">{ lv_fmt_vtot }</td>|.
    ELSE.
      lv_html = lv_html && |<td class="tot-amt">&#8377;{ lv_fmt_vtot }</td>|.
    ENDIF.
  ENDLOOP.

  lv_html = lv_html &&
    '  <td class="tot-min">—</td>' &&
    |  <td class="tot-amt" style="color: #2563eb;">&#8377;{ lv_fmt_sel_tot }</td>| &&
    '</tr></tfoot></table>'.

  " Commercial Evaluation section
  lv_html = lv_html &&
    '<div class="comm-section">' &&
    |  <div class="comm-title">Commercial Evaluation & Financing Analysis ({ p_rate DECIMALS = 2 }% Interest Rate)</div>| &&
    '  <table class="comm-tbl">' &&
    '    <thead><tr><th>Commercial Parameter</th>'.

  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html &&
      |<th>{ wa_hdr-name1 }<br><small style="font-weight: 500; color: #64748b;">RFQ #{ wa_hdr-ebeln }</small></th>|.
  ENDLOOP.

  lv_html = lv_html && '</tr></thead><tbody>'.

  " Incoterms
  lv_html = lv_html && '<tr><td>Incoterms</td>'.
  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html && |<td>{ wa_hdr-inco1 }</td>|.
  ENDLOOP.
  lv_html = lv_html && '</tr>'.

  " Payment Terms
  lv_html = lv_html && '<tr><td>Payment Terms</td>'.
  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html && |<td>{ wa_hdr-text1 }</td>|.
  ENDLOOP.
  lv_html = lv_html && '</tr>'.

  " Credit Days
  lv_html = lv_html && '<tr><td>Credit Days</td>'.
  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html && |<td>{ wa_hdr-ztag1 } Days</td>|.
  ENDLOOP.
  lv_html = lv_html && '</tr>'.

  " Interest Financing Cost
  READ TABLE gt_final INTO DATA(ls_intr) WITH KEY maktx = 'Interest Amount' ##READ_WHERE_OK.
  lv_html = lv_html &&
    |<tr class="highlight"><td><strong>Financing / Interest Cost ({ p_rate DECIMALS = 2 }%)</strong></td>|.

  LOOP AT gt_hdr INTO wa_hdr.
    DATA(lv_hidx) = sy-tabix.
    DATA: lv_raw_intr TYPE string,
          lv_fmt_intr TYPE string.
    CASE lv_hidx.
      WHEN 1. lv_raw_intr = ls_intr-quat1.
      WHEN 2. lv_raw_intr = ls_intr-quat2.
      WHEN 3. lv_raw_intr = ls_intr-quat3.
      WHEN 4. lv_raw_intr = ls_intr-quat4.
      WHEN 5. lv_raw_intr = ls_intr-quat5.
      WHEN 6. lv_raw_intr = ls_intr-quat6.
      WHEN 7. lv_raw_intr = ls_intr-quat7.
    ENDCASE.
    PERFORM format_inr USING lv_raw_intr CHANGING lv_fmt_intr.
    IF lv_fmt_intr = 'No Price'.
      lv_html = lv_html && |<td style="color: #dc2626;">{ lv_fmt_intr }</td>|.
    ELSE.
      lv_html = lv_html && |<td style="text-align: right;">&#8377;{ lv_fmt_intr }</td>|.
    ENDIF.
  ENDLOOP.
  lv_html = lv_html && '</tr>'.

  " Net Landed Commercial Evaluation
  lv_html = lv_html &&
    '<tr class="total-eval"><td><strong>Net Commercial Landed Evaluation</strong></td>'.

  LOOP AT gt_hdr INTO wa_hdr.
    DATA(lv_eidx) = sy-tabix.
    DATA: lv_t_amt   TYPE decfloat34,
          lv_i_amt   TYPE decfloat34,
          lv_land    TYPE decfloat34,
          lv_flnd    TYPE string,
          lv_raw_tot TYPE string.
    CLEAR: lv_raw_tot, lv_raw_intr.
    CASE lv_eidx.
      WHEN 1. lv_raw_tot = ls_tot-quat1. lv_raw_intr = ls_intr-quat1.
      WHEN 2. lv_raw_tot = ls_tot-quat2. lv_raw_intr = ls_intr-quat2.
      WHEN 3. lv_raw_tot = ls_tot-quat3. lv_raw_intr = ls_intr-quat3.
      WHEN 4. lv_raw_tot = ls_tot-quat4. lv_raw_intr = ls_intr-quat4.
      WHEN 5. lv_raw_tot = ls_tot-quat5. lv_raw_intr = ls_intr-quat5.
      WHEN 6. lv_raw_tot = ls_tot-quat6. lv_raw_intr = ls_intr-quat6.
      WHEN 7. lv_raw_tot = ls_tot-quat7. lv_raw_intr = ls_intr-quat7.
    ENDCASE.
    IF lv_raw_tot IS NOT INITIAL AND lv_raw_tot NE 'No Price'.
      lv_t_amt = CONV decfloat34( lv_raw_tot ).
    ELSE.
      lv_t_amt = 0.
    ENDIF.
    IF lv_raw_intr IS NOT INITIAL AND lv_raw_intr NE 'No Price'.
      lv_i_amt = CONV decfloat34( lv_raw_intr ).
    ELSE.
      lv_i_amt = 0.
    ENDIF.
    IF lv_raw_tot = 'No Price'.
      lv_flnd = 'No Price'.
    ELSE.
      lv_land = lv_t_amt + lv_i_amt.
      PERFORM format_inr USING lv_land CHANGING lv_flnd.
    ENDIF.
    IF lv_flnd = 'No Price'.
      lv_html = lv_html && |<td style="color: #dc2626;"><strong>{ lv_flnd }</strong></td>|.
    ELSE.
      lv_html = lv_html && |<td style="text-align: right;"><strong>&#8377;{ lv_flnd }</strong></td>|.
    ENDIF.
  ENDLOOP.
  lv_html = lv_html && '</tr></tbody></table></div>'.

  lv_html = lv_html &&
    '</div>' &&
    '<script>' &&
    'function applyRate() {' &&
    '  var val = document.getElementById("inpRate").value;' &&
    '  if (val && !isNaN(val)) {' &&
    '    window.location.href = "sapevent:SET_RATE?rate=" + encodeURIComponent(val);' &&
    '  }' &&
    '}' &&
    '</script>' &&
    '</body></html>'.

  " Load HTML into viewer via binary UTF-8 stream
  DATA: lv_xstring TYPE xstring,
        lt_binary  TYPE solix_tab,
        lv_size    TYPE i,
        lv_url     TYPE c LENGTH 255.

  CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text   = lv_html
    IMPORTING
      buffer = lv_xstring.

  lv_size = xstrlen( lv_xstring ).

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer     = lv_xstring
    TABLES
      binary_tab = lt_binary.

  go_html->load_data(
    EXPORTING
      type         = 'text'
      subtype      = 'html'
      size         = lv_size
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_binary
    EXCEPTIONS
      OTHERS       = 1 ).

  IF sy-subrc = 0.
    go_html->show_url(
      EXPORTING
        url      = lv_url
        in_place = 'X'
      EXCEPTIONS
        OTHERS   = 1 ).
  ENDIF.

  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form handle_html_action
*&---------------------------------------------------------------------*
FORM handle_html_action USING pv_action  TYPE c
                              pv_getdata TYPE c.

  DATA: lv_action   TYPE string,
        lv_data     TYPE string,
        lv_item_str TYPE string,
        lv_ebelp    TYPE ekpo-ebelp,
        lv_col      TYPE slis_fieldname.

  lv_action = pv_action.
  lv_data   = pv_getdata.

  CASE lv_action.

    WHEN 'TOGGLE_ALL'.
      DATA: lv_any_unsel TYPE abap_bool VALUE abap_false.
      LOOP AT gt_item_ref INTO DATA(ls_ir_chk) WHERE po_number IS INITIAL.
        READ TABLE gt_final INTO DATA(ls_f) WITH KEY ebelp = ls_ir_chk-ebelp quat = 'Val:'.
        IF sy-subrc = 0 AND ls_f-sel NS '[X]'.
          lv_any_unsel = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF lv_any_unsel = abap_true.
        " Select only items where user has already chosen a supplier
        LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ir>) WHERE po_number IS INITIAL.
          IF <fs_ir>-sel_lifnr IS NOT INITIAL.
            READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_v>)
              WITH KEY ebelp = <fs_ir>-ebelp quat = 'Val:'.
            IF sy-subrc = 0.
              <fs_v>-sel = '@01@ [X]'.
              <fs_v>-po_action = |PO -> { <fs_ir>-sel_name1(12) }|.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ELSE.
        " Deselect all pending items
        LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ir_off>) WHERE po_number IS INITIAL.
          PERFORM deselect_item USING <fs_ir_off>-ebelp.
        ENDLOOP.
      ENDIF.
      PERFORM update_header_sel_state.
      PERFORM render_html.

    WHEN 'TOGGLE_ROW'.
      CLEAR: lv_item_str, lv_ebelp.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      lv_ebelp = lv_item_str.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref_tr>) WITH KEY ebelp = lv_ebelp.
      IF sy-subrc = 0 AND <fs_ref_tr>-po_number IS NOT INITIAL.
        MESSAGE |PO { <fs_ref_tr>-po_number } is already created for Item { lv_ebelp }. Selection disabled.| TYPE 'W'.
        RETURN.
      ENDIF.
      READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_val>)
        WITH KEY ebelp = lv_ebelp quat = 'Val:'.
      IF sy-subrc = 0.
        IF <fs_val>-sel CS '[X]'.
          PERFORM deselect_item USING lv_ebelp.
        ELSE.
          IF <fs_ref_tr>-sel_lifnr IS INITIAL.
            MESSAGE |Please click on the supplier column to select supplier for Item { lv_ebelp }.| TYPE 'I'.
            RETURN.
          ELSE.
            <fs_val>-sel       = '@01@ [X]'.
            <fs_val>-po_action = |PO -> { <fs_ref_tr>-sel_name1(12) }|.
          ENDIF.
        ENDIF.
        PERFORM update_header_sel_state.
        PERFORM render_html.
      ENDIF.

    WHEN 'SELECT'.
      CLEAR: lv_item_str, lv_ebelp, lv_col.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      PERFORM parse_query_param USING lv_data 'col'  CHANGING lv_col.
      lv_ebelp = lv_item_str.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref_sel>) WITH KEY ebelp = lv_ebelp.
      IF sy-subrc = 0 AND <fs_ref_sel>-po_number IS NOT INITIAL.
        MESSAGE |PO { <fs_ref_sel>-po_number } is already created for Item { lv_ebelp }. Supplier change disabled.| TYPE 'W'.
        RETURN.
      ENDIF.
      IF lv_ebelp IS NOT INITIAL AND lv_col IS NOT INITIAL.
        PERFORM select_supplier_for_item USING lv_ebelp lv_col.
        READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_chk>)
          WITH KEY ebelp = lv_ebelp quat = 'Val:'.
        IF sy-subrc = 0.
          <fs_chk>-sel = '@01@ [X]'.
        ENDIF.
        PERFORM update_header_sel_state.
        PERFORM render_html.
      ENDIF.

    WHEN 'DESELECT'.
      CLEAR: lv_item_str, lv_ebelp.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      lv_ebelp = lv_item_str.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref_des>) WITH KEY ebelp = lv_ebelp.
      IF sy-subrc = 0 AND <fs_ref_des>-po_number IS NOT INITIAL.
        MESSAGE |PO { <fs_ref_des>-po_number } is already created for Item { lv_ebelp }. Selection disabled.| TYPE 'W'.
        RETURN.
      ENDIF.
      IF lv_ebelp IS NOT INITIAL.
        PERFORM deselect_item USING lv_ebelp.
        PERFORM render_html.
      ENDIF.

    WHEN 'CREATE_PO'.
      PERFORM create_po_for_selected USING 0.
      PERFORM render_html.

    WHEN 'CREATE_SINGLE_PO'.
      CLEAR: lv_item_str, lv_ebelp.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      lv_ebelp = lv_item_str.
      IF lv_ebelp IS NOT INITIAL.
        PERFORM create_po_for_single_item USING lv_ebelp.
        PERFORM render_html.
      ENDIF.

    WHEN 'ME47'.
      DATA: lv_ebeln TYPE ekko-ebeln.
      PERFORM parse_query_param USING lv_data 'ebeln' CHANGING lv_ebeln.
      IF lv_ebeln IS NOT INITIAL.
        PERFORM open_me47_for_quotation USING lv_ebeln.
        PERFORM get_data.
        PERFORM render_html.
      ENDIF.

    WHEN 'VIEW_PO' OR 'ME23N'.
      CLEAR lv_ebeln.
      PERFORM parse_query_param USING lv_data 'ebeln' CHANGING lv_ebeln.
      IF lv_ebeln IS NOT INITIAL.
        SET PARAMETER ID 'BES' FIELD lv_ebeln.
        CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
        IF sy-subrc <> 0.
          CALL TRANSACTION 'ME23N'.                    "#EC CI_CALLTA
        ENDIF.
      ENDIF.

    WHEN 'REFRESH'.
      PERFORM get_data.
      PERFORM render_html.
      MESSAGE 'Quotation comparison data refreshed successfully.' TYPE 'S'.

    WHEN 'SET_RATE'.
      DATA: lv_rate_str TYPE string.
      PERFORM parse_query_param USING lv_data 'rate' CHANGING lv_rate_str.
      IF lv_rate_str IS NOT INITIAL.
        p_rate = CONV decfloat34( lv_rate_str ).
        PERFORM get_data.
        PERFORM render_html.
        MESSAGE |Interest Rate updated to { p_rate DECIMALS = 2 }%.| TYPE 'S'.
      ENDIF.

  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form parse_query_param
*&---------------------------------------------------------------------*
FORM parse_query_param USING pv_query TYPE string
                             pv_key   TYPE string
                    CHANGING pv_val   TYPE any.
  CLEAR pv_val.
  DATA: lt_parts TYPE STANDARD TABLE OF string,
        lv_pair  TYPE string,
        lv_k     TYPE string,
        lv_v     TYPE string.

  SPLIT pv_query AT '&' INTO TABLE lt_parts.
  LOOP AT lt_parts INTO lv_pair.
    SPLIT lv_pair AT '=' INTO lv_k lv_v.
    IF to_lower( lv_k ) = to_lower( pv_key ).
      pv_val = lv_v.
      EXIT.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form deselect_item
*&---------------------------------------------------------------------*
FORM deselect_item USING pv_ebelp TYPE ekpo-ebelp.
  READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref>) WITH KEY ebelp = pv_ebelp.
  IF sy-subrc = 0.
    IF <fs_ref>-po_number IS NOT INITIAL.
      RETURN.
    ENDIF.
    CLEAR: <fs_ref>-sel_col, <fs_ref>-sel_ebeln, <fs_ref>-sel_ebelp,
           <fs_ref>-sel_lifnr, <fs_ref>-sel_name1, <fs_ref>-sel_netpr,
           <fs_ref>-sel_peinh, <fs_ref>-sel_waers, <fs_ref>-sel_zterm,
           <fs_ref>-sel_inco1.
  ENDIF.

  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_val>)
    WITH KEY ebelp = pv_ebelp quat = 'Val:'.
  IF sy-subrc = 0.
    <fs_val>-sel       = '@R7@ [ ]'.
    <fs_val>-po_action = '@0Y@ Select Supplier'.
  ENDIF.

  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_app>)
    WITH KEY ebelp = pv_ebelp quat = 'Approved'.
  IF sy-subrc = 0.
    IF lines( gt_hdr ) >= 1. <fs_app>-quat1 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 2. <fs_app>-quat2 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 3. <fs_app>-quat3 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 4. <fs_app>-quat4 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 5. <fs_app>-quat5 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 6. <fs_app>-quat6 = '[ ]'. ENDIF.
    IF lines( gt_hdr ) >= 7. <fs_app>-quat7 = '[ ]'. ENDIF.
    CLEAR <fs_app>-cell_colors.
  ENDIF.

  PERFORM update_header_sel_state.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form format_inr
*&---------------------------------------------------------------------*
FORM format_inr USING    pv_val TYPE any
                CHANGING cv_out TYPE string.

  DATA: lv_str_val TYPE string,
        lv_dec_val TYPE decfloat34,
        lv_raw     TYPE string,
        lv_int     TYPE string,
        lv_dec     TYPE string,
        lv_rest    TYPE string,
        lv_last3   TYPE string,
        lv_len     TYPE i,
        lv_offset  TYPE i,
        lv_chunk   TYPE string,
        lv_sign    TYPE string.

  CLEAR cv_out.
  IF pv_val IS INITIAL.
    cv_out = '0.00'.
    RETURN.
  ENDIF.

  lv_str_val = |{ pv_val }|.
  CONDENSE lv_str_val.

  IF lv_str_val = 'No Price' OR lv_str_val CS 'No Price'.
    cv_out = 'No Price'.
    RETURN.
  ENDIF.

  TRY.
      lv_dec_val = CONV decfloat34( lv_str_val ).
    CATCH cx_root.
      cv_out = lv_str_val.
      RETURN.
  ENDTRY.

  IF lv_dec_val < 0.
    lv_sign = '-'.
    lv_dec_val = abs( lv_dec_val ).
  ENDIF.

  lv_raw = |{ lv_dec_val DECIMALS = 2 }|.
  SPLIT lv_raw AT '.' INTO lv_int lv_dec.
  IF lv_dec IS INITIAL.
    lv_dec = '00'.
  ENDIF.

  lv_len = strlen( lv_int ).
  IF lv_len <= 3.
    cv_out = |{ lv_sign }{ lv_int }.{ lv_dec }|.
    RETURN.
  ENDIF.

  " Extract last 3 digits
  lv_offset = lv_len - 3.
  lv_last3  = lv_int+lv_offset(3).
  lv_rest   = lv_int(lv_offset).

  " Process preceding digits in pairs of 2 from right to left
  DATA: lt_pairs TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
  CLEAR lt_pairs.
  WHILE strlen( lv_rest ) > 2.
    lv_offset = strlen( lv_rest ) - 2.
    lv_chunk  = lv_rest+lv_offset(2).
    INSERT lv_chunk INTO lt_pairs INDEX 1.
    lv_rest   = lv_rest(lv_offset).
  ENDWHILE.
  IF lv_rest IS NOT INITIAL.
    INSERT lv_rest INTO lt_pairs INDEX 1.
  ENDIF.

  DATA: lv_grouped TYPE string.
  CLEAR lv_grouped.
  LOOP AT lt_pairs INTO lv_chunk.
    IF lv_grouped IS INITIAL.
      lv_grouped = lv_chunk.
    ELSE.
      lv_grouped = |{ lv_grouped },{ lv_chunk }|.
    ENDIF.
  ENDLOOP.

  cv_out = |{ lv_sign }{ lv_grouped },{ lv_last3 }.{ lv_dec }|.

ENDFORM.
