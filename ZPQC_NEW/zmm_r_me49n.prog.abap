*&---------------------------------------------------------------------*
*& Report ZMM_R_ME49N
*&---------------------------------------------------------------------*
*& Description : Interactive Price Comparison List & PO Creation (ZPQC_NEW)
*& Based on    : ZMM_R_079 / ZME49 layout with item-wise checkboxes and
*&               interactive Purchase Order creation via BAPI_PO_CREATE1.
*& Author      : NARESH
*& Date        : 13.10.2026
*& Version     : 3.1 (13.10.2026 19:35)
*& Change Log  :
*&   v1.0 (12.10.2026) - Initial interactive report & BAPI PO creation
*&   v2.0 (13.10.2026) - Modern HTML dashboard preview (ME47/ME23N links)
*&   v2.1 (13.10.2026) - Card layout styling & dynamic badges
*&   v2.2 (13.10.2026) - Full-width layout & grid borders
*&   v2.3 (13.10.2026) - High-density decision matrix
*&   v2.4 (13.10.2026) - Classical ERP grid table with highlighted L1 cells
*&   v2.5 (13.10.2026) - Actual unrounded Price & Rate precision (full decimals)
*&   v2.6 (13.10.2026) - Unified table format: commercial analysis merged into single
*&                      continuous grid with pixel-perfect column alignment & sizing
*&   v2.7 (13.10.2026) - Price Comparison Approval Workflow: System Suggested (L1) vs
*&                      User Suggested columns, HOD routing via ZMM_T_023 & ZMM_T_021
*&   v2.8 (13.10.2026) - HOD Approved Status with Green Background (#16a34a)
*&                      and Strict PO Creation Enforcement (Only Approved Items)
*&   v2.9 (13.10.2026) - Fixed Net Price resolution in BAPI PO creation from ZMM_T_021
*&   v3.0 (13.10.2026) - Role-Based Workflow Security (Approver vs Creator):
*&                      Approve/Reject buttons hidden from User, visible only to HOD;
*&                      Continuous 'Send for Approval' availability for partial PO collectives;
*&                      Compulsory justification remarks for non-L1 selected suppliers;
*&                      Automated Email & SAP GUI Express Notification to HOD via
*&                      SO_NEW_DOCUMENT_SEND_API1 & TH_POPUP
*&   v3.1 (13.10.2026) - Full Lock Down for 'In Approval' & 'Approved' States:
*&                      Items in approval cannot change supplier, selection, or remarks;
*&                      Approved items can only trigger 'Create PO';
*&                      Identical workflow, visual status, and lock enforcement applied to ALV list
*&   v3.2 (14.10.2026) - Approver Resolution for DIPAK RATHOD, Mandatory Rejection Remark,
*&                      Open Collective F4 Search Help for Approver, and Rejection Reason display.
*&   v3.3 (14.10.2026) - Last Purchase Price (LPP) of material benchmark from EKPO/EKKO;
*&                      Default selection to System Suggested L1 (fixed 1st supplier bug);
*&                      Delivery Cost & Additional Freight Condition evaluation from PRCD_ELEMENTS;
*&                      Direct RFQ quotation reference in BAPI_PO_CREATE1 (RFQ_NO/RFQ_ITEM).
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
         knumv TYPE ekko-knumv,
       END OF ty_hdr,

       BEGIN OF ty_rfq_item,
         ebeln   TYPE ekko-ebeln,
         ebelp   TYPE ekpo-ebelp,
         submi   TYPE ekko-submi,
         ekorg   TYPE ekko-ekorg,
         ekgrp   TYPE ekko-ekgrp,
         bukrs   TYPE ekko-bukrs,
         lifnr   TYPE ekko-lifnr,
         name1   TYPE lfa1-name1,
         ihrez   TYPE ekko-ihrez,
         inco1   TYPE ekko-inco1,
         waers   TYPE ekko-waers,
         wkurs   TYPE ekko-wkurs,
         zterm   TYPE ekko-zterm,
         knumv   TYPE ekko-knumv,
         matnr   TYPE ekpo-matnr,
         txz01   TYPE ekpo-txz01,
         ktmng   TYPE ekpo-ktmng,
         menge   TYPE ekpo-menge,
         meins   TYPE ekpo-meins,
         netpr   TYPE ekpo-netpr,
         peinh   TYPE ekpo-peinh,
         netwr   TYPE ekpo-netwr,
         freight     TYPE decfloat34,
         tot_amt     TYPE decfloat34,
         frt_details TYPE string,
         werks       TYPE ekpo-werks,
         ztag1   TYPE t052-ztag1,
         text1   TYPE t052u-text1,
       END OF ty_rfq_item,

       BEGIN OF ty_item_ref,
         matnr       TYPE ekpo-matnr,
         ebelp       TYPE ekpo-ebelp,
         txz01       TYPE ekpo-txz01,
         menge       TYPE ekpo-menge,
         meins       TYPE ekpo-meins,
         werks       TYPE ekpo-werks,
         bukrs       TYPE ekko-bukrs,
         ekorg       TYPE ekko-ekorg,
         ekgrp       TYPE ekko-ekgrp,
         submi       TYPE ekko-submi,
         lpp_ebeln   TYPE ekko-ebeln,
         lpp_ebelp   TYPE ekpo-ebelp,
         lpp_bedat   TYPE ekko-bedat,
         lpp_netpr   TYPE ekpo-netpr,
         lpp_peinh   TYPE ekpo-peinh,
         lpp_waers   TYPE ekko-waers,
         lpp_meins   TYPE ekpo-meins,
         lpp_lifnr   TYPE ekko-lifnr,
         lpp_name1   TYPE lfa1-name1,
         lpp_upr_amt TYPE decfloat34,
         l1_sel_col  TYPE slis_fieldname,
         l1_ebeln    TYPE ekko-ebeln,
         l1_ebelp    TYPE ekpo-ebelp,
         l1_lifnr    TYPE ekko-lifnr,
         l1_name1    TYPE lfa1-name1,
         l1_netpr    TYPE ekpo-netpr,
         l1_peinh    TYPE ekpo-peinh,
         l1_waers    TYPE ekko-waers,
         l1_zterm    TYPE ekko-zterm,
         l1_inco1    TYPE ekko-inco1,
         l1_freight      TYPE decfloat34,
         l1_tot_amt      TYPE decfloat34,
         l1_upr_amt      TYPE decfloat34,
         l1_frt_details  TYPE string,
         sel_col         TYPE slis_fieldname,
         sel_ebeln       TYPE ekko-ebeln,
         sel_ebelp       TYPE ekpo-ebelp,
         sel_lifnr       TYPE ekko-lifnr,
         sel_name1       TYPE lfa1-name1,
         sel_netpr       TYPE ekpo-netpr,
         sel_peinh       TYPE ekpo-peinh,
         sel_waers       TYPE ekko-waers,
         sel_zterm       TYPE ekko-zterm,
         sel_inco1       TYPE ekko-inco1,
         sel_freight     TYPE decfloat34,
         sel_tot_amt     TYPE decfloat34,
         sel_upr_amt     TYPE decfloat34,
         sel_frt_details TYPE string,
         appr_status TYPE c LENGTH 1,
         user_pref   TYPE c LENGTH 1,
         user_remark TYPE zmm_de_remark,
         appr_remark TYPE zmm_de_aremark,
         po_number   TYPE ekko-ebeln,
       END OF ty_item_ref,

       BEGIN OF ty_final,
         sel(12)       TYPE c,         " '@01@ [X]' / '@R7@ [ ]' or '@01@ [X]All'
         matnr         TYPE mara-matnr,
         maktx         TYPE makt-maktx,
         lpp(30)       TYPE c,         " Last Purchase Price benchmark
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
         amount  TYPE decfloat34,
         amount1 TYPE decfloat34,
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

TYPES: BEGIN OF ty_q_frt_item,
         ebeln   TYPE ekko-ebeln,
         ebelp   TYPE ekpo-ebelp,
         lifnr   TYPE ekko-lifnr,
         name1   TYPE lfa1-name1,
         kschl   TYPE prcd_elements-kschl,
         vtext   TYPE string,
         kbetr   TYPE prcd_elements-kbetr,
         waers   TYPE prcd_elements-waers,
         kwert   TYPE prcd_elements-kwert,
         waerk   TYPE prcd_elements-waerk,
         inr_amt TYPE decfloat34,
       END OF ty_q_frt_item.

*----------------------------------------------------------------------*
* Global Data
*----------------------------------------------------------------------*
DATA: gt_final       TYPE TABLE OF ty_final,
      gt_final1      TYPE TABLE OF ty_final,
      gt_hdr         TYPE TABLE OF ty_hdr,
      gt_rfq_items   TYPE ty_t_rfq_item,
      gt_q_frt_items TYPE STANDARD TABLE OF ty_q_frt_item WITH DEFAULT KEY,
      gt_item_ref    TYPE TABLE OF ty_item_ref,
      lt_rank        TYPE STANDARD TABLE OF ty_rank,
      ls_rank     TYPE ty_rank,
      lv_amt      TYPE ekpo-netwr,
      lv_rank     TYPE i,
      ls_total    LIKE LINE OF gt_final,
      ls_interest LIKE LINE OF gt_final1,
      gs_val      LIKE LINE OF gt_final,
      gs_frt      LIKE LINE OF gt_final,
      gs_rank     LIKE LINE OF gt_final,
      gs_pkg      LIKE LINE OF gt_final,
      gs_app      LIKE LINE OF gt_final,
      lv_mean     TYPE ekpo-netpr,
      int_days    TYPE f VALUE '0.12',
      lv_result   TYPE ekpo-netpr,
      lv_val      TYPE ekpo-netwr,
      gv_hod_user        TYPE zuser,
      gv_hod_name        TYPE string,
      gv_is_approver     TYPE abap_bool VALUE abap_false,
      gv_submi           TYPE ekko-submi,
      gv_approval_status TYPE c LENGTH 10 VALUE 'DRAFT',
      gv_appr_items_cnt  TYPE i VALUE 0,
      gv_pend_items_cnt  TYPE i VALUE 0,
      gv_rej_items_cnt   TYPE i VALUE 0.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
  SELECT-OPTIONS: s_ekorg FOR ekko-ekorg,
                  s_ebeln FOR ekko-ebeln,
                  s_submi FOR ekko-submi NO INTERVALS NO-EXTENSION,
                  s_lifnr FOR ekko-lifnr,
                  s_matnr FOR ekpo-matnr.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE t_b2.
  PARAMETERS: p_bsart TYPE ekko-bsart DEFAULT 'NB',
              p_test  AS CHECKBOX DEFAULT ' ',
              p_apprv AS CHECKBOX DEFAULT ' '.
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
  %_p_apprv_%_app_%-text = 'Simulate Approver Role (HOD)'.
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

  " Auto-detect Approver role from master table ZMM_T_023
  DATA: lv_is_appr_sel TYPE abap_bool VALUE abap_false.
  SELECT COUNT(*) FROM zmm_t_023 WHERE zuser = @sy-uname.
  IF sy-subrc = 0 AND sy-dbcnt > 0.
    lv_is_appr_sel = abap_true.
    p_apprv        = abap_true.
  ENDIF.

  " Auto-default collective number if empty (for BOTH User and Approver)
  IF s_submi[] IS INITIAL AND s_submi-low IS INITIAL.
    DATA: lv_def_submi TYPE ekko-submi.
    PERFORM get_default_open_collective USING sy-uname CHANGING lv_def_submi.
    IF lv_def_submi IS NOT INITIAL.
      s_submi-sign   = 'I'.
      s_submi-option = 'EQ'.
      s_submi-low    = lv_def_submi.
      APPEND s_submi.
    ENDIF.
  ENDIF.

*----------------------------------------------------------------------*
* Selection Screen F4 Value-Request for Collective Number
*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_submi-low.
  PERFORM f4_collective_number.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.

  " 1. Synchronize single value from screen header if internal table empty
  IF s_submi-low IS NOT INITIAL AND s_submi[] IS INITIAL.
    s_submi-sign   = 'I'.
    s_submi-option = 'EQ'.
    APPEND s_submi.
  ENDIF.

  " 2. Auto-pad collective number with leading zeroes if purely numeric
  LOOP AT s_submi ASSIGNING FIELD-SYMBOL(<fs_submi>).
    IF <fs_submi>-low IS NOT INITIAL AND <fs_submi>-low CO '0123456789 '.
      CONDENSE <fs_submi>-low NO-GAPS.
      <fs_submi>-low = |{ <fs_submi>-low ALPHA = IN }|.
    ENDIF.
    IF <fs_submi>-high IS NOT INITIAL AND <fs_submi>-high CO '0123456789 '.
      CONDENSE <fs_submi>-high NO-GAPS.
      <fs_submi>-high = |{ <fs_submi>-high ALPHA = IN }|.
    ENDIF.
  ENDLOOP.

  " 3. If still empty, default to latest open collective
  IF s_submi[] IS INITIAL.
    DATA: lv_sos_submi TYPE ekko-submi.
    PERFORM get_default_open_collective USING sy-uname CHANGING lv_sos_submi.
    IF lv_sos_submi IS NOT INITIAL.
      s_submi-sign   = 'I'.
      s_submi-option = 'EQ'.
      s_submi-low    = lv_sos_submi.
      APPEND s_submi.
    ENDIF.
  ENDIF.

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

  " Determine Purchasing Org filter:
  " If user specified a collective number and left s_ekorg blank, do NOT restrict by purchasing org.
  DATA: lt_ekorg_range TYPE RANGE OF ekko-ekorg.
  IF s_submi[] IS NOT INITIAL AND s_ekorg[] IS INITIAL.
    CLEAR lt_ekorg_range.
  ELSE.
    lt_ekorg_range = s_ekorg[].
  ENDIF.

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
           ekko~knumv,
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
      AND ekko~ekorg IN @lt_ekorg_range
      AND ekko~lifnr IN @s_lifnr
      AND ekpo~matnr IN @s_matnr
      AND ekpo~loekz = @space
    INTO TABLE @DATA(it_data).

  IF it_data IS INITIAL.
    " Safe fallback: if filtered by purchasing org, retry across all orgs for this collective
    IF lt_ekorg_range IS NOT INITIAL.
      CLEAR lt_ekorg_range.
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
               ekko~knumv,
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
          AND ekko~lifnr IN @s_lifnr
          AND ekpo~matnr IN @s_matnr
          AND ekpo~loekz = @space
        INTO TABLE @it_data.
    ENDIF.
  ENDIF.

  IF it_data IS INITIAL.
    MESSAGE 'No data found for selection criteria.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  gv_submi = it_data[ 1 ]-submi.

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
      knumv = wa_data-knumv
    ) ).

  SORT gt_hdr BY ebeln ASCENDING.
  DELETE ADJACENT DUPLICATES FROM gt_hdr COMPARING ebeln.

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

  CLEAR: gt_final, gt_final1, gt_item_ref, gt_q_frt_items.

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
  " Fetch Last Purchase Price (LPP) from EKPO / EKKO for distinct materials
  TYPES: BEGIN OF ty_lpp,
           matnr TYPE ekpo-matnr,
           ebeln TYPE ekko-ebeln,
           ebelp TYPE ekpo-ebelp,
           netpr TYPE ekpo-netpr,
           peinh TYPE ekpo-peinh,
           meins TYPE ekpo-meins,
           waers TYPE ekko-waers,
           bedat TYPE ekko-bedat,
           lifnr TYPE ekko-lifnr,
           name1 TYPE lfa1-name1,
         END OF ty_lpp.
  DATA: lt_lpp TYPE STANDARD TABLE OF ty_lpp WITH DEFAULT KEY.
  CLEAR lt_lpp.

  DATA: lr_mat_all TYPE RANGE OF ekpo-matnr.
  lr_mat_all = VALUE #( FOR wa_m IN it_data WHERE ( matnr IS NOT INITIAL )
                        ( sign = 'I' option = 'EQ' low = wa_m-matnr ) ).
  SORT lr_mat_all BY low.
  DELETE ADJACENT DUPLICATES FROM lr_mat_all COMPARING low.

  IF lr_mat_all IS NOT INITIAL.
    SELECT p~matnr, p~ebeln, p~ebelp, p~netpr, p~peinh, p~meins,
           k~waers, k~bedat, k~lifnr, l~name1
      FROM ekpo AS p
      INNER JOIN ekko AS k ON p~ebeln = k~ebeln
      LEFT JOIN lfa1 AS l ON k~lifnr = l~lifnr
      WHERE k~bstyp = 'F'
        AND p~loekz = @space
        AND p~matnr IN @lr_mat_all
        AND p~netpr > 0
      ORDER BY p~matnr ASCENDING, k~bedat DESCENDING, p~ebeln DESCENDING
      INTO TABLE @lt_lpp.

    DELETE ADJACENT DUPLICATES FROM lt_lpp COMPARING matnr.
  ENDIF.

  " Ensure knumv is populated for all quotation headers and items
  LOOP AT gt_hdr ASSIGNING FIELD-SYMBOL(<fs_gh_k>) WHERE knumv IS INITIAL.
    SELECT SINGLE knumv FROM ekko INTO @<fs_gh_k>-knumv WHERE ebeln = @<fs_gh_k>-ebeln.
  ENDLOOP.
  LOOP AT it_data ASSIGNING FIELD-SYMBOL(<fs_it_k>) WHERE knumv IS INITIAL.
    SELECT SINGLE knumv FROM ekko INTO @<fs_it_k>-knumv WHERE ebeln = @<fs_it_k>-ebeln.
  ENDLOOP.

  " Fetch quotation pricing conditions (delivery costs / freight) from PRCD_ELEMENTS
  TYPES: BEGIN OF ty_q_cond,
           knumv TYPE prcd_elements-knumv,
           kposn TYPE prcd_elements-kposn,
           stunr TYPE prcd_elements-stunr,
           zaehk TYPE prcd_elements-zaehk,
           kschl TYPE prcd_elements-kschl,
           kinak TYPE prcd_elements-kinak,
           krech TYPE prcd_elements-krech,
           kbetr TYPE prcd_elements-kbetr,
           kwert TYPE prcd_elements-kwert,
           kkurs TYPE prcd_elements-kkurs,
           waers TYPE prcd_elements-waers,
           waerk TYPE prcd_elements-waerk,
           kpein TYPE prcd_elements-kpein,
           kmein TYPE prcd_elements-kmein,
         END OF ty_q_cond.
  DATA: lt_q_conds TYPE STANDARD TABLE OF ty_q_cond WITH DEFAULT KEY.
  CLEAR lt_q_conds.

  DATA: lt_knumv_range TYPE RANGE OF ekko-knumv.
  lt_knumv_range = VALUE #( FOR wa_h IN gt_hdr WHERE ( knumv IS NOT INITIAL )
                            ( sign = 'I' option = 'EQ' low = wa_h-knumv ) ).
  LOOP AT it_data INTO DATA(wa_it_d) WHERE knumv IS NOT INITIAL.
    IF NOT line_exists( lt_knumv_range[ low = wa_it_d-knumv ] ).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = wa_it_d-knumv ) TO lt_knumv_range.
    ENDIF.
  ENDLOOP.
  SORT lt_knumv_range BY low.
  DELETE ADJACENT DUPLICATES FROM lt_knumv_range COMPARING low.

  IF lt_knumv_range IS NOT INITIAL.
    SELECT knumv, kposn, stunr, zaehk, kschl, kinak, krech, kbetr, kwert, kkurs, waers, waerk, kpein, kmein
      FROM prcd_elements
      WHERE knumv IN @lt_knumv_range
        AND kinak = @space
        AND ( kwert <> 0 OR kbetr <> 0 )
      INTO CORRESPONDING FIELDS OF TABLE @lt_q_conds.
  ENDIF.

  " Retrieve delivery cost / freight condition types from customizing (T685A)
  " Note: Strictly exclude base prices (koaid = 'B' or kntyp = 'H') and gross price conditions
  DATA: lr_freight_conds TYPE RANGE OF prcd_elements-kschl.
  CLEAR lr_freight_conds.
  SELECT kschl FROM t685a
    WHERE kappl = 'M'
      AND ( kntyp = 'B' OR kntyp = 'b'
            OR kschl LIKE 'FR%' OR kschl LIKE 'Z%FR%'
            OR kschl IN ( 'ZAFR', 'WT01', 'U4V', 'FREI', 'ZTRK', 'ZI01', 'ZI04', 'ZI08', 'ZI16', 'ZI23', 'ZDP1', 'ZDT1', 'ZI42' ) )
      AND koaid <> 'B'
      AND ( kntyp IS INITIAL OR kntyp <> 'H' )
      AND kschl NOT IN ( 'PB00', 'PBXX', 'P001', 'P002', 'RA00', 'SKTO' )
    INTO TABLE @DATA(lt_f_conds).
  lr_freight_conds = VALUE #( FOR wa_fc IN lt_f_conds ( sign = 'I' option = 'EQ' low = wa_fc-kschl ) ).
  IF lr_freight_conds IS INITIAL.
    lr_freight_conds = VALUE #(
      ( sign = 'I' option = 'EQ' low = 'FRA1' )
      ( sign = 'I' option = 'EQ' low = 'FRA2' )
      ( sign = 'I' option = 'EQ' low = 'FRB1' )
      ( sign = 'I' option = 'EQ' low = 'FRB2' )
      ( sign = 'I' option = 'EQ' low = 'FRC1' )
      ( sign = 'I' option = 'EQ' low = 'FRC2' )
      ( sign = 'I' option = 'EQ' low = 'ZAFR' )
      ( sign = 'I' option = 'EQ' low = 'ZDT1' )
      ( sign = 'I' option = 'EQ' low = 'ZDP1' )
      ( sign = 'I' option = 'EQ' low = 'ZI01' )
      ( sign = 'I' option = 'EQ' low = 'ZI04' )
      ( sign = 'I' option = 'EQ' low = 'ZI08' )
      ( sign = 'I' option = 'EQ' low = 'ZI16' )
      ( sign = 'I' option = 'EQ' low = 'ZI23' )
      ( sign = 'I' option = 'EQ' low = 'ZI42' )
    ).
  ENDIF.

  " Fetch condition metadata (calculation rule) from T685A
  TYPES: BEGIN OF ty_t685a_info,
           kschl TYPE t685a-kschl,
           krech TYPE t685a-krech,
           kntyp TYPE t685a-kntyp,
           koaid TYPE t685a-koaid,
         END OF ty_t685a_info.
  DATA: lt_t685a_info TYPE HASHED TABLE OF ty_t685a_info WITH UNIQUE KEY kschl.
  SELECT kschl, krech, kntyp, koaid FROM t685a
    WHERE kappl = 'M'
    INTO TABLE @lt_t685a_info.

  " Fetch condition descriptions from T685T
  TYPES: BEGIN OF ty_cond_text,
           kschl TYPE t685t-kschl,
           vtext TYPE t685t-vtext,
         END OF ty_cond_text.
  DATA: lt_cond_texts TYPE HASHED TABLE OF ty_cond_text WITH UNIQUE KEY kschl.
  SELECT kschl, vtext FROM t685t
    WHERE spras = @sy-langu AND kappl = 'M'
    INTO TABLE @DATA(lt_all_ctexts).
  IF lt_all_ctexts IS INITIAL AND sy-langu <> 'E'.
    SELECT kschl, vtext FROM t685t
      WHERE spras = 'E' AND kappl = 'M'
      INTO TABLE @lt_all_ctexts.
  ENDIF.
  lt_cond_texts = CORRESPONDING #( lt_all_ctexts ).

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
    CLEAR: gs_val, gs_frt, gs_rank, gs_pkg, gs_app.

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

    gs_frt-matnr     = ls_data1-matnr.
    gs_frt-maktx     = 'Delivery / Freight'.
    gs_frt-quat      = 'Delivery:'.
    gs_frt-ebelp     = ls_data1-ebelp.
    gs_frt-color     = 'C300'.
    gs_frt-po_action = '@0S@ View Breakdown'.

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
      gs_frt-quat1  = 'No Price'.
      gs_rank-quat1 = 'No Price'.
      gs_app-quat1  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 2.
      gs_val-quat2  = 'No Price'.
      gs_pkg-quat2  = 'No Price'.
      gs_frt-quat2  = 'No Price'.
      gs_rank-quat2 = 'No Price'.
      gs_app-quat2  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 3.
      gs_val-quat3  = 'No Price'.
      gs_pkg-quat3  = 'No Price'.
      gs_frt-quat3  = 'No Price'.
      gs_rank-quat3 = 'No Price'.
      gs_app-quat3  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 4.
      gs_val-quat4  = 'No Price'.
      gs_pkg-quat4  = 'No Price'.
      gs_frt-quat4  = 'No Price'.
      gs_rank-quat4 = 'No Price'.
      gs_app-quat4  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 5.
      gs_val-quat5  = 'No Price'.
      gs_pkg-quat5  = 'No Price'.
      gs_frt-quat5  = 'No Price'.
      gs_rank-quat5 = 'No Price'.
      gs_app-quat5  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 6.
      gs_val-quat6  = 'No Price'.
      gs_pkg-quat6  = 'No Price'.
      gs_frt-quat6  = 'No Price'.
      gs_rank-quat6 = 'No Price'.
      gs_app-quat6  = COND #( WHEN lv_found_po IS NOT INITIAL THEN '[PO Done]' ELSE '[ ]' ).
    ENDIF.
    IF lines( gt_hdr ) >= 7.
      gs_val-quat7  = 'No Price'.
      gs_pkg-quat7  = 'No Price'.
      gs_frt-quat7  = 'No Price'.
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

      DATA: lv_calc_tot TYPE decfloat34,
            lv_calc_upr TYPE decfloat34,
            lv_b_upr    TYPE decfloat34,
            lv_b_tot    TYPE decfloat34,
            lv_frt_inr  TYPE decfloat34 VALUE 0.

      lv_b_upr = CONV decfloat34( ls_data-netpr ) /
                 COND decfloat34( WHEN lv_peinh > 0 THEN lv_peinh ELSE 1 ).
      IF ls_data-waers = 'USD' AND ls_data-wkurs > 0.
        lv_b_upr = lv_b_upr * CONV decfloat34( ls_data-wkurs ).
      ENDIF.
      lv_b_tot = CONV decfloat34( lv_item_qty ) * lv_b_upr.

      " Calculate freight / delivery cost from PRCD_ELEMENTS for this quotation item
      DATA: lv_item_frt_str TYPE string.
      CLEAR lv_item_frt_str.

      IF lt_q_conds IS NOT INITIAL AND ls_data-knumv IS NOT INITIAL.
        DATA: lv_kposn_item TYPE prcd_elements-kposn,
              lv_kposn_raw  TYPE prcd_elements-kposn.
        UNPACK ls_data-ebelp TO lv_kposn_item.
        lv_kposn_raw = ls_data-ebelp.

        LOOP AT lt_q_conds INTO DATA(ls_q_c)
          WHERE knumv = ls_data-knumv
            AND ( kposn = lv_kposn_item OR kposn = lv_kposn_raw )
            AND kschl IN lr_freight_conds.

          DATA: lv_cond_inr TYPE decfloat34 VALUE 0,
                lv_crule    TYPE t685a-krech.
          CLEAR lv_crule.
          IF ls_q_c-krech IS NOT INITIAL.
            lv_crule = ls_q_c-krech.
          ELSEIF line_exists( lt_t685a_info[ kschl = ls_q_c-kschl ] ).
            lv_crule = lt_t685a_info[ kschl = ls_q_c-kschl ]-krech.
          ENDIF.

          IF ls_q_c-waers = 'INR'.
            IF lv_crule = 'B' AND ls_q_c-kbetr <> 0.
              lv_cond_inr = CONV decfloat34( ls_q_c-kbetr ).
            ELSEIF lv_crule = 'C' AND ls_q_c-kbetr <> 0.
              DATA(lv_kpein_val) = COND decfloat34( WHEN ls_q_c-kpein > 0 THEN ls_q_c-kpein ELSE 1 ).
              lv_cond_inr = ( CONV decfloat34( ls_q_c-kbetr ) * CONV decfloat34( lv_item_qty ) ) / lv_kpein_val.
            ELSEIF ls_q_c-kwert <> 0.
              lv_cond_inr = CONV decfloat34( ls_q_c-kwert ).
              IF ls_q_c-waerk = 'USD' AND ls_data-wkurs > 0.
                lv_cond_inr = lv_cond_inr * CONV decfloat34( ls_data-wkurs ).
              ENDIF.
            ELSE.
              lv_cond_inr = CONV decfloat34( ls_q_c-kbetr ).
            ENDIF.
          ELSE.
            IF ls_q_c-kwert <> 0.
              lv_cond_inr = CONV decfloat34( ls_q_c-kwert ).
              IF ( ls_q_c-waerk = 'USD' OR ls_data-waers = 'USD' ) AND ls_data-wkurs > 0.
                lv_cond_inr = lv_cond_inr * CONV decfloat34( ls_data-wkurs ).
              ENDIF.
            ELSEIF ls_q_c-kbetr <> 0.
              lv_cond_inr = CONV decfloat34( ls_q_c-kbetr ).
              IF ( ls_q_c-waers = 'USD' OR ls_data-waers = 'USD' ) AND ls_data-wkurs > 0.
                lv_cond_inr = lv_cond_inr * CONV decfloat34( ls_data-wkurs ).
              ENDIF.
            ENDIF.
          ENDIF.

          lv_frt_inr = lv_frt_inr + lv_cond_inr.

          " Find condition description
          DATA: lv_c_desc TYPE string.
          CLEAR lv_c_desc.
          READ TABLE lt_cond_texts INTO DATA(ls_ctext) WITH KEY kschl = ls_q_c-kschl.
          IF sy-subrc = 0 AND ls_ctext-vtext IS NOT INITIAL.
            lv_c_desc = ls_ctext-vtext.
          ELSE.
            lv_c_desc = ls_q_c-kschl.
          ENDIF.

          " Store individual condition in global table
          APPEND VALUE #(
            ebeln   = ls_data-ebeln
            ebelp   = ls_data-ebelp
            lifnr   = ls_data-lifnr
            name1   = ls_data-name1
            kschl   = ls_q_c-kschl
            vtext   = lv_c_desc
            kbetr   = ls_q_c-kbetr
            waers   = ls_q_c-waers
            kwert   = ls_q_c-kwert
            waerk   = ls_q_c-waerk
            inr_amt = lv_cond_inr
          ) TO gt_q_frt_items.

          DATA: lv_famt_str TYPE string.
          PERFORM format_inr USING lv_cond_inr CHANGING lv_famt_str.
          IF lv_item_frt_str IS INITIAL.
            lv_item_frt_str = |{ ls_q_c-kschl }: ₹{ lv_famt_str }|.
          ELSE.
            lv_item_frt_str = |{ lv_item_frt_str } · { ls_q_c-kschl }: ₹{ lv_famt_str }|.
          ENDIF.
        ENDLOOP.

        " Header freight distributed to item
        DATA: lv_hdr_frt TYPE decfloat34 VALUE 0.
        LOOP AT lt_q_conds INTO ls_q_c
          WHERE knumv = ls_data-knumv AND ( kposn = '000000' OR kposn = '00000' ) AND kschl IN lr_freight_conds.
          DATA: lv_hcond_inr TYPE decfloat34 VALUE 0.
          IF ls_q_c-waers = 'INR'.
            IF ls_q_c-kbetr <> 0.
              lv_hcond_inr = CONV decfloat34( ls_q_c-kbetr ).
            ELSEIF ls_q_c-kwert <> 0.
              lv_hcond_inr = CONV decfloat34( ls_q_c-kwert ).
              IF ls_q_c-waerk = 'USD' AND ls_data-wkurs > 0.
                lv_hcond_inr = lv_hcond_inr * CONV decfloat34( ls_data-wkurs ).
              ENDIF.
            ENDIF.
          ELSE.
            IF ls_q_c-kwert <> 0.
              lv_hcond_inr = CONV decfloat34( ls_q_c-kwert ).
              IF ( ls_q_c-waerk = 'USD' OR ls_data-waers = 'USD' ) AND ls_data-wkurs > 0.
                lv_hcond_inr = lv_hcond_inr * CONV decfloat34( ls_data-wkurs ).
              ENDIF.
            ELSEIF ls_q_c-kbetr <> 0.
              lv_hcond_inr = CONV decfloat34( ls_q_c-kbetr ).
              IF ( ls_q_c-waers = 'USD' OR ls_data-waers = 'USD' ) AND ls_data-wkurs > 0.
                lv_hcond_inr = lv_hcond_inr * CONV decfloat34( ls_data-wkurs ).
              ENDIF.
            ENDIF.
          ENDIF.
          lv_hdr_frt = lv_hdr_frt + lv_hcond_inr.
        ENDLOOP.
        IF lv_hdr_frt > 0.
          DATA: lv_q_icnt TYPE i VALUE 0.
          LOOP AT it_data TRANSPORTING NO FIELDS WHERE ebeln = ls_data-ebeln AND netpr > 0.
            lv_q_icnt = lv_q_icnt + 1.
          ENDLOOP.
          IF lv_q_icnt > 0.
            DATA(lv_dist_hdr) = lv_hdr_frt / lv_q_icnt.
            lv_frt_inr = lv_frt_inr + lv_dist_hdr.
            IF lv_item_frt_str IS INITIAL.
              DATA: lv_fhdr_str TYPE string.
              PERFORM format_inr USING lv_dist_hdr CHANGING lv_fhdr_str.
              lv_item_frt_str = |Hdr: ₹{ lv_fhdr_str }|.
            ELSE.
              DATA: lv_fhdr_str2 TYPE string.
              PERFORM format_inr USING lv_dist_hdr CHANGING lv_fhdr_str2.
              lv_item_frt_str = |{ lv_item_frt_str } · Hdr: ₹{ lv_fhdr_str2 }|.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      " Store freight and basic total in gt_rfq_items
      READ TABLE gt_rfq_items ASSIGNING FIELD-SYMBOL(<fs_up_rqi>)
        WITH KEY ebeln = ls_data-ebeln ebelp = ls_data-ebelp.
      IF sy-subrc = 0.
        <fs_up_rqi>-freight     = lv_frt_inr.
        <fs_up_rqi>-tot_amt     = lv_b_tot.
        <fs_up_rqi>-frt_details = lv_item_frt_str.
      ENDIF.

      " Line-level item amount is strictly Basic Amount (Price * Quantity)
      lv_val = |{ lv_b_tot STYLE = SIMPLE }|.
      DATA(lv_frt_s) = |{ lv_frt_inr STYLE = SIMPLE }|.

      CLEAR ls_rank.
      ls_rank-lifnr   = ls_data-lifnr.
      ls_rank-amount  = lv_b_tot.
      ls_rank-amount1 = lv_b_upr.
      APPEND ls_rank TO lt_rank.

      IF lines( gt_hdr ) >= 1 AND ls_data-ebeln = gt_hdr[ 1 ]-ebeln.
        gs_val-quat1 = lv_val.
        gs_pkg-quat1 = |{ lv_b_upr STYLE = SIMPLE }|.
        gs_frt-quat1 = lv_frt_s.
      ELSEIF lines( gt_hdr ) >= 2 AND ls_data-ebeln = gt_hdr[ 2 ]-ebeln.
        gs_val-quat2 = lv_val.
        gs_pkg-quat2 = |{ lv_b_upr STYLE = SIMPLE }|.
        gs_frt-quat2 = lv_frt_s.
      ELSEIF lines( gt_hdr ) >= 3 AND ls_data-ebeln = gt_hdr[ 3 ]-ebeln.
        gs_val-quat3 = lv_val.
        gs_pkg-quat3 = |{ lv_b_upr STYLE = SIMPLE }|.
        gs_frt-quat3 = lv_frt_s.
      ELSEIF lines( gt_hdr ) >= 4 AND ls_data-ebeln = gt_hdr[ 4 ]-ebeln.
        gs_val-quat4 = lv_val.
        gs_pkg-quat4 = |{ lv_b_upr STYLE = SIMPLE }|.
        gs_frt-quat4 = lv_frt_s.
      ELSEIF lines( gt_hdr ) >= 5 AND ls_data-ebeln = gt_hdr[ 5 ]-ebeln.
        gs_val-quat5 = lv_val.
        gs_pkg-quat5 = |{ lv_b_upr STYLE = SIMPLE }|.
        gs_frt-quat5 = lv_frt_s.
      ELSEIF lines( gt_hdr ) >= 6 AND ls_data-ebeln = gt_hdr[ 6 ]-ebeln.
        gs_val-quat6 = lv_val.
        gs_pkg-quat6 = |{ lv_b_upr STYLE = SIMPLE }|.
        gs_frt-quat6 = lv_frt_s.
      ELSEIF lines( gt_hdr ) >= 7 AND ls_data-ebeln = gt_hdr[ 7 ]-ebeln.
        gs_val-quat7 = lv_val.
        gs_pkg-quat7 = |{ lv_b_upr STYLE = SIMPLE }|.
        gs_frt-quat7 = lv_frt_s.
      ENDIF.
    ENDLOOP.

    CONDENSE: gs_val-quat1, gs_val-quat2, gs_val-quat3, gs_val-quat4,
              gs_val-quat5, gs_val-quat6, gs_val-quat7,
              gs_frt-quat1, gs_frt-quat2, gs_frt-quat3, gs_frt-quat4,
              gs_frt-quat5, gs_frt-quat6, gs_frt-quat7.

    " Calculate Mean only for quotations with price > 0
    DATA: lv_val_sum TYPE decfloat34,
          lv_pkg_sum TYPE decfloat34,
          lv_frt_sum TYPE decfloat34,
          lv_prc_cnt TYPE i.
    CLEAR: lv_val_sum, lv_pkg_sum, lv_frt_sum, lv_prc_cnt.

    LOOP AT lt_rank INTO DATA(ls_rm).
      lv_val_sum = lv_val_sum + ls_rm-amount.
      lv_pkg_sum = lv_pkg_sum + ls_rm-amount1.
      lv_prc_cnt = lv_prc_cnt + 1.
    ENDLOOP.

    LOOP AT it_data INTO DATA(ls_d_frt) WHERE ebelp = ls_data1-ebelp AND matnr = ls_data1-matnr AND netpr > 0.
      READ TABLE gt_rfq_items INTO DATA(ls_rq_f) WITH KEY ebeln = ls_d_frt-ebeln ebelp = ls_d_frt-ebelp.
      IF sy-subrc = 0.
        lv_frt_sum = lv_frt_sum + ls_rq_f-freight.
      ENDIF.
    ENDLOOP.

    IF lv_prc_cnt > 0.
      lv_mean = lv_val_sum / lv_prc_cnt.
      gs_val-mean = |{ lv_mean STYLE = SIMPLE }|.
      lv_mean = lv_pkg_sum / lv_prc_cnt.
      gs_pkg-mean = |{ lv_mean STYLE = SIMPLE }|.
      lv_mean = lv_frt_sum / lv_prc_cnt.
      gs_frt-mean = |{ lv_mean STYLE = SIMPLE }|.
    ELSE.
      gs_val-mean = 'No Price'.
      gs_pkg-mean = 'No Price'.
      gs_frt-mean = 'No Price'.
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
        ls_item_ref-bukrs      = ls_win-bukrs.
        ls_item_ref-ekorg      = ls_win-ekorg.
        ls_item_ref-ekgrp      = ls_win-ekgrp.
        ls_item_ref-l1_tot_amt = ls_top_r-amount.
        ls_item_ref-l1_upr_amt = ls_top_r-amount1.
        READ TABLE gt_rfq_items INTO DATA(ls_l1_rfq_chk)
          WITH KEY ebeln = ls_win-ebeln ebelp = ls_win-ebelp.
        IF sy-subrc = 0.
          ls_item_ref-l1_freight     = ls_l1_rfq_chk-freight.
          ls_item_ref-l1_frt_details = ls_l1_rfq_chk-frt_details.
          gs_frt-minimum             = |{ ls_l1_rfq_chk-freight STYLE = SIMPLE }|.
        ENDIF.
      ENDIF.
    ENDIF.

    " Populate Last Purchase Price (LPP) benchmark for this material
    READ TABLE lt_lpp INTO DATA(ls_mat_lpp) WITH KEY matnr = ls_data1-matnr.
    IF sy-subrc = 0.
      ls_item_ref-lpp_ebeln   = ls_mat_lpp-ebeln.
      ls_item_ref-lpp_ebelp   = ls_mat_lpp-ebelp.
      ls_item_ref-lpp_bedat   = ls_mat_lpp-bedat.
      ls_item_ref-lpp_netpr   = ls_mat_lpp-netpr.
      ls_item_ref-lpp_peinh   = COND #( WHEN ls_mat_lpp-peinh > 0 THEN ls_mat_lpp-peinh ELSE 1 ).
      ls_item_ref-lpp_waers   = ls_mat_lpp-waers.
      ls_item_ref-lpp_meins   = ls_mat_lpp-meins.
      ls_item_ref-lpp_lifnr   = ls_mat_lpp-lifnr.
      ls_item_ref-lpp_name1   = ls_mat_lpp-name1.
      ls_item_ref-lpp_upr_amt = CONV decfloat34( ls_mat_lpp-netpr ) /
                                CONV decfloat34( ls_item_ref-lpp_peinh ).
      IF ls_mat_lpp-waers = 'USD' AND ls_data1-wkurs > 0.
        ls_item_ref-lpp_upr_amt = ls_item_ref-lpp_upr_amt * CONV decfloat34( ls_data1-wkurs ).
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
      " Default selection to System Suggested L1 winner by default
      ls_item_ref-sel_col         = ls_item_ref-l1_sel_col.
      ls_item_ref-sel_ebeln       = ls_item_ref-l1_ebeln.
      ls_item_ref-sel_ebelp       = ls_item_ref-l1_ebelp.
      ls_item_ref-sel_lifnr       = ls_item_ref-l1_lifnr.
      ls_item_ref-sel_name1       = ls_item_ref-l1_name1.
      ls_item_ref-sel_netpr       = ls_item_ref-l1_netpr.
      ls_item_ref-sel_peinh       = ls_item_ref-l1_peinh.
      ls_item_ref-sel_waers       = ls_item_ref-l1_waers.
      ls_item_ref-sel_zterm       = ls_item_ref-l1_zterm.
      ls_item_ref-sel_inco1       = ls_item_ref-l1_inco1.
      ls_item_ref-sel_tot_amt     = ls_item_ref-l1_tot_amt.
      ls_item_ref-sel_upr_amt     = ls_item_ref-l1_upr_amt.
      ls_item_ref-sel_freight     = ls_item_ref-l1_freight.
      ls_item_ref-sel_frt_details = ls_item_ref-l1_frt_details.
      ls_item_ref-user_pref       = space.
      gs_val-sel                  = '@01@ [X]'.
      gs_val-po_action            = |@0Y@ PO -> { ls_item_ref-l1_name1(12) }|.
    ENDIF.

    IF lt_rank IS NOT INITIAL.
      lv_rank = 1.
      LOOP AT lt_rank INTO ls_rank.
        IF lv_rank = 1.
          gs_val-minimum = |{ ls_rank-amount STYLE = SIMPLE }|.
          gs_pkg-minimum = |{ ls_rank-amount1 STYLE = SIMPLE }|.
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
      gs_frt-minimum = 'No Price'.
    ENDIF.

    IF ls_item_ref-po_number IS INITIAL AND ls_item_ref-sel_col IS INITIAL.
      ls_item_ref-sel_col = ls_item_ref-l1_sel_col.
    ENDIF.

    IF ls_item_ref-lpp_upr_amt > 0.
      DATA: lv_fmt_lpp_alv TYPE string.
      PERFORM format_inr USING ls_item_ref-lpp_upr_amt CHANGING lv_fmt_lpp_alv.
      gs_rank-matnr = 'Last PO:'.
      gs_rank-maktx = |₹{ lv_fmt_lpp_alv }/ { ls_item_ref-lpp_meins } (PO { ls_item_ref-lpp_ebeln })|.
    ELSE.
      gs_rank-matnr = 'Last PO:'.
      gs_rank-maktx = 'No PO History'.
    ENDIF.

    APPEND ls_item_ref TO gt_item_ref.

    APPEND gs_val  TO gt_final.
    APPEND gs_frt  TO gt_final.
    APPEND gs_rank TO gt_final.
    APPEND gs_pkg  TO gt_final.
    APPEND gs_app  TO gt_final.

  ENDLOOP.
  PERFORM init_approval_status.
  PERFORM update_header_sel_state.

  SORT lt_win_cols.
  DELETE ADJACENT DUPLICATES FROM lt_win_cols.

  " 1. Total Item Amount Row (Basic material cost)
  DATA: ls_item_tot TYPE ty_final.
  CLEAR ls_item_tot.
  ls_item_tot-maktx = 'Total Item Amount'.
  ls_item_tot-color = 'C110'.

  " 2. Total Delivery Cost Row (Individual row down side!)
  DATA: ls_frt_tot TYPE ty_final.
  CLEAR ls_frt_tot.
  ls_frt_tot-maktx = 'Total Delivery Cost'.
  ls_frt_tot-color = 'C300'.

  " 3. Total Quotation Amount Row (Landed: Item Amount + Delivery Cost)
  CLEAR ls_total.
  ls_total-maktx = 'Total Quotation Amount'.
  ls_total-color = 'C110'.

  DO lines( gt_hdr ) TIMES.
    DATA(lv_h_idx) = sy-index.
    DATA(ls_h_curr) = gt_hdr[ lv_h_idx ].

    DATA: lv_has_q_prc TYPE abap_bool,
          lv_v_mat     TYPE decfloat34,
          lv_v_frt     TYPE decfloat34,
          lv_v_tot     TYPE decfloat34.

    CLEAR: lv_has_q_prc, lv_v_mat, lv_v_frt, lv_v_tot.

    LOOP AT gt_rfq_items INTO DATA(ls_rqi_v) WHERE ebeln = ls_h_curr-ebeln AND netpr > 0.
      lv_has_q_prc = abap_true.
      DATA(lv_v_peinh) = COND ekpo-peinh( WHEN ls_rqi_v-peinh > 0 THEN ls_rqi_v-peinh ELSE 1 ).
      DATA(lv_v_menge) = COND ekpo-menge( WHEN ls_rqi_v-menge > 0 THEN ls_rqi_v-menge
                                          WHEN ls_rqi_v-ktmng > 0 THEN ls_rqi_v-ktmng ELSE 1 ).
      DATA: lv_item_mat TYPE decfloat34.
      lv_item_mat = ( CONV decfloat34( lv_v_menge ) * CONV decfloat34( ls_rqi_v-netpr ) ) / CONV decfloat34( lv_v_peinh ).
      IF ls_rqi_v-waers = 'USD' AND ls_rqi_v-wkurs > 0.
        lv_item_mat = lv_item_mat * CONV decfloat34( ls_rqi_v-wkurs ).
      ENDIF.
      lv_v_mat = lv_v_mat + lv_item_mat.
      lv_v_frt = lv_v_frt + ls_rqi_v-freight.
    ENDLOOP.
    lv_v_tot = lv_v_mat + lv_v_frt.

    DATA: lv_str_mat TYPE string,
          lv_str_frt TYPE string,
          lv_str_tot TYPE string.

    IF lv_has_q_prc = abap_true.
      lv_str_mat = |{ lv_v_mat STYLE = SIMPLE }|.
      lv_str_frt = |{ lv_v_frt STYLE = SIMPLE }|.
      lv_str_tot = |{ lv_v_tot STYLE = SIMPLE }|.
    ELSE.
      lv_str_mat = 'No Price'.
      lv_str_frt = 'No Price'.
      lv_str_tot = 'No Price'.
    ENDIF.

    CASE lv_h_idx.
      WHEN 1.
        ls_item_tot-quat1 = lv_str_mat.
        ls_frt_tot-quat1  = lv_str_frt.
        ls_total-quat1    = lv_str_tot.
      WHEN 2.
        ls_item_tot-quat2 = lv_str_mat.
        ls_frt_tot-quat2  = lv_str_frt.
        ls_total-quat2    = lv_str_tot.
      WHEN 3.
        ls_item_tot-quat3 = lv_str_mat.
        ls_frt_tot-quat3  = lv_str_frt.
        ls_total-quat3    = lv_str_tot.
      WHEN 4.
        ls_item_tot-quat4 = lv_str_mat.
        ls_frt_tot-quat4  = lv_str_frt.
        ls_total-quat4    = lv_str_tot.
      WHEN 5.
        ls_item_tot-quat5 = lv_str_mat.
        ls_frt_tot-quat5  = lv_str_frt.
        ls_total-quat5    = lv_str_tot.
      WHEN 6.
        ls_item_tot-quat6 = lv_str_mat.
        ls_frt_tot-quat6  = lv_str_frt.
        ls_total-quat6    = lv_str_tot.
      WHEN 7.
        ls_item_tot-quat7 = lv_str_mat.
        ls_frt_tot-quat7  = lv_str_frt.
        ls_total-quat7    = lv_str_tot.
    ENDCASE.
  ENDDO.

  " Calculate Mean for summary rows across valid quotations
  DATA: lv_m_mat_sum TYPE decfloat34,
        lv_m_frt_sum TYPE decfloat34,
        lv_m_tot_sum TYPE decfloat34,
        lv_m_cnt     TYPE i.
  CLEAR: lv_m_mat_sum, lv_m_frt_sum, lv_m_tot_sum, lv_m_cnt.

  DO lines( gt_hdr ) TIMES.
    DATA: lv_col_mat TYPE string,
          lv_col_frt TYPE string,
          lv_col_tot TYPE string.
    CASE sy-index.
      WHEN 1. lv_col_mat = ls_item_tot-quat1. lv_col_frt = ls_frt_tot-quat1. lv_col_tot = ls_total-quat1.
      WHEN 2. lv_col_mat = ls_item_tot-quat2. lv_col_frt = ls_frt_tot-quat2. lv_col_tot = ls_total-quat2.
      WHEN 3. lv_col_mat = ls_item_tot-quat3. lv_col_frt = ls_frt_tot-quat3. lv_col_tot = ls_total-quat3.
      WHEN 4. lv_col_mat = ls_item_tot-quat4. lv_col_frt = ls_frt_tot-quat4. lv_col_tot = ls_total-quat4.
      WHEN 5. lv_col_mat = ls_item_tot-quat5. lv_col_frt = ls_frt_tot-quat5. lv_col_tot = ls_total-quat5.
      WHEN 6. lv_col_mat = ls_item_tot-quat6. lv_col_frt = ls_frt_tot-quat6. lv_col_tot = ls_total-quat6.
      WHEN 7. lv_col_mat = ls_item_tot-quat7. lv_col_frt = ls_frt_tot-quat7. lv_col_tot = ls_total-quat7.
    ENDCASE.
    IF lv_col_mat IS NOT INITIAL AND lv_col_mat NE 'No Price'.
      lv_m_mat_sum = lv_m_mat_sum + CONV decfloat34( lv_col_mat ).
      lv_m_frt_sum = lv_m_frt_sum + CONV decfloat34( lv_col_frt ).
      lv_m_tot_sum = lv_m_tot_sum + CONV decfloat34( lv_col_tot ).
      lv_m_cnt     = lv_m_cnt + 1.
    ENDIF.
  ENDDO.

  IF lv_m_cnt > 0.
    ls_item_tot-mean = |{ ( lv_m_mat_sum / lv_m_cnt ) STYLE = SIMPLE }|.
    ls_frt_tot-mean  = |{ ( lv_m_frt_sum / lv_m_cnt ) STYLE = SIMPLE }|.
    ls_total-mean    = |{ ( lv_m_tot_sum / lv_m_cnt ) STYLE = SIMPLE }|.
  ELSE.
    ls_item_tot-mean = 'No Price'.
    ls_frt_tot-mean  = 'No Price'.
    ls_total-mean    = 'No Price'.
  ENDIF.

  " Calculate L1 minimum values for summary rows
  DATA: lv_l1_m_mat TYPE decfloat34,
        lv_l1_m_frt TYPE decfloat34,
        lv_l1_m_tot TYPE decfloat34.
  CLEAR: lv_l1_m_mat, lv_l1_m_frt, lv_l1_m_tot.
  LOOP AT gt_item_ref INTO DATA(ls_ir_alv) WHERE l1_tot_amt > 0.
    lv_l1_m_mat = lv_l1_m_mat + ls_ir_alv-l1_tot_amt.
    lv_l1_m_frt = lv_l1_m_frt + ls_ir_alv-l1_freight.
    lv_l1_m_tot = lv_l1_m_tot + ( ls_ir_alv-l1_tot_amt + ls_ir_alv-l1_freight ).
  ENDLOOP.
  IF lv_l1_m_tot > 0.
    ls_item_tot-minimum = |{ lv_l1_m_mat STYLE = SIMPLE }|.
    ls_frt_tot-minimum  = |{ lv_l1_m_frt STYLE = SIMPLE }|.
    ls_total-minimum    = |{ lv_l1_m_tot STYLE = SIMPLE }|.
  ELSE.
    ls_item_tot-minimum = 'No Price'.
    ls_frt_tot-minimum  = 'No Price'.
    ls_total-minimum    = 'No Price'.
  ENDIF.

  APPEND ls_item_tot TO gt_final.
  APPEND ls_frt_tot  TO gt_final.
  APPEND ls_total    TO gt_final.
  APPEND ls_total    TO gt_final1.

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
      ls_interest-quat1 = lv_result.
    ELSEIF lines( gt_hdr ) >= 1.
      ls_interest-quat1 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 2 AND ls_amt-quat2 IS NOT INITIAL AND ls_amt-quat2 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat2 ) ) * CONV decfloat34( ls_amt-quat2 ) }|.
      ls_interest-quat2 = lv_result.
    ELSEIF lines( gt_hdr ) >= 2.
      ls_interest-quat2 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 3 AND ls_amt-quat3 IS NOT INITIAL AND ls_amt-quat3 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat3 ) ) * CONV decfloat34( ls_amt-quat3 ) }|.
      ls_interest-quat3 = lv_result.
    ELSEIF lines( gt_hdr ) >= 3.
      ls_interest-quat3 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 4 AND ls_amt-quat4 IS NOT INITIAL AND ls_amt-quat4 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat4 ) ) * CONV decfloat34( ls_amt-quat4 ) }|.
      ls_interest-quat4 = lv_result.
    ELSEIF lines( gt_hdr ) >= 4.
      ls_interest-quat4 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 5 AND ls_amt-quat5 IS NOT INITIAL AND ls_amt-quat5 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat5 ) ) * CONV decfloat34( ls_amt-quat5 ) }|.
      ls_interest-quat5 = lv_result.
    ELSEIF lines( gt_hdr ) >= 5.
      ls_interest-quat5 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 6 AND ls_amt-quat6 IS NOT INITIAL AND ls_amt-quat6 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat6 ) ) * CONV decfloat34( ls_amt-quat6 ) }|.
      ls_interest-quat6 = lv_result.
    ELSEIF lines( gt_hdr ) >= 6.
      ls_interest-quat6 = 'No Price'.
    ENDIF.
    IF lines( gt_hdr ) >= 7 AND ls_amt-quat7 IS NOT INITIAL AND ls_amt-quat7 NE 'No Price'.
      lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat7 ) ) * CONV decfloat34( ls_amt-quat7 ) }|.
      ls_interest-quat7 = lv_result.
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
    ( fieldname = 'QUAT'      seltext_m = ' '        outputlen = '10' hotspot = 'X' )
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

  " Freight & Delivery Condition Details Breakdown
  IF r_ucomm = '&FRT' OR r_ucomm = 'FREIGHT'
     OR rs_selfield-value CS 'Breakdown'.
    IF rs_selfield-tabindex > 0 AND rs_selfield-tabindex <= lines( gt_final ).
      READ TABLE gt_final INTO DATA(ls_uc_f) INDEX rs_selfield-tabindex.
      IF sy-subrc = 0.
        PERFORM show_item_freight_details USING ls_uc_f-ebelp rs_selfield-fieldname.
        RETURN.
      ENDIF.
    ENDIF.
    PERFORM show_item_freight_details USING space space.
    RETURN.
  ENDIF.

  " Check if a Delivery / Freight row was clicked
  IF rs_selfield-tabindex > 0 AND rs_selfield-tabindex <= lines( gt_final ).
    READ TABLE gt_final INTO DATA(ls_uc_check) INDEX rs_selfield-tabindex.
    IF sy-subrc = 0.
      IF ls_uc_check-quat = 'Delivery:' OR ls_uc_check-maktx = 'Total Delivery Cost'
         OR ls_uc_check-maktx = 'Delivery / Freight'.
        PERFORM show_item_freight_details USING ls_uc_check-ebelp rs_selfield-fieldname.
        RETURN.
      ENDIF.
    ENDIF.
  ENDIF.

  " Direct trigger for Actions:
  " - Toolbar button CREATE_PO or PO_CREATE
  " - Hotspot value contains 'Create PO' or 'PO ->'
  " - Column PO_ACTION clicked on any row
  IF r_ucomm = 'CREATE_PO'
     OR r_ucomm = 'PO_CREATE'
     OR rs_selfield-value CS 'Create PO'
     OR rs_selfield-value CS 'PO ->'
     OR rs_selfield-fieldname = 'PO_ACTION'.

    " Row 1: Create PO for all approved items
    IF rs_selfield-tabindex = 1 OR r_ucomm = 'CREATE_PO' OR r_ucomm = 'PO_CREATE'.
      IF gv_is_approver = abap_true.
        MESSAGE 'Approval completed. Only creator/requester can create Purchase Orders.' TYPE 'I'.
        RETURN.
      ENDIF.
      IF gv_appr_items_cnt > 0.
        PERFORM create_po_for_selected USING rs_selfield-tabindex.
      ELSE.
        MESSAGE 'No approved items available to create Purchase Order.' TYPE 'W'.
      ENDIF.
      rs_selfield-refresh    = abap_true.
      rs_selfield-col_stable = abap_true.
      rs_selfield-row_stable = abap_true.
      RETURN.
    ENDIF.

    " Row 2: Send to HOD (User) or Approve All (HOD)
    IF rs_selfield-tabindex = 2.
      IF gv_is_approver = abap_true.
        IF gv_pend_items_cnt > 0.
          PERFORM handle_html_action USING 'APPROVE' space.
        ELSE.
          MESSAGE 'No pending items to approve.' TYPE 'I'.
        ENDIF.
      ELSE.
        DATA: lv_unsub_cnt_uc TYPE i VALUE 0.
        LOOP AT gt_item_ref INTO DATA(ls_unsub_uc) WHERE po_number IS INITIAL.
          IF ls_unsub_uc-sel_lifnr IS NOT INITIAL AND ls_unsub_uc-user_pref IS INITIAL.
            lv_unsub_cnt_uc = lv_unsub_cnt_uc + 1.
          ENDIF.
        ENDLOOP.
        IF lv_unsub_cnt_uc > 0.
          PERFORM handle_html_action USING 'SUBMIT_APPROVAL' space.
        ELSEIF gv_pend_items_cnt > 0.
          MESSAGE 'Items are already submitted and pending HOD approval.' TYPE 'I'.
        ELSE.
          MESSAGE 'Please select supplier for items before sending to HOD.' TYPE 'I'.
        ENDIF.
      ENDIF.
      rs_selfield-refresh    = abap_true.
      rs_selfield-col_stable = abap_true.
      rs_selfield-row_stable = abap_true.
      RETURN.
    ENDIF.

    " Row 4: Reject All (Approver only)
    IF rs_selfield-tabindex = 4 AND gv_is_approver = abap_true.
      PERFORM handle_html_action USING 'REJECT' space.
      rs_selfield-refresh    = abap_true.
      rs_selfield-col_stable = abap_true.
      rs_selfield-row_stable = abap_true.
      RETURN.
    ENDIF.

    " Item Rows (tabindex > 4): Action button clicked
    IF rs_selfield-tabindex > 4 AND rs_selfield-tabindex <= lines( gt_final ).
      READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_act_row>) INDEX rs_selfield-tabindex.
      IF sy-subrc = 0.
        DATA(lv_act_ebelp) = <fs_act_row>-ebelp.
        IF lv_act_ebelp IS INITIAL AND rs_selfield-tabindex + 1 <= lines( gt_final ).
          READ TABLE gt_final INTO DATA(ls_act_next) INDEX ( rs_selfield-tabindex + 1 ).
          IF sy-subrc = 0.
            lv_act_ebelp = ls_act_next-ebelp.
          ENDIF.
        ENDIF.

        IF <fs_act_row>-po_action CP '@0V@ PO *'.
          DATA(lv_po_num) = <fs_act_row>-po_action+7(10).
          SET PARAMETER ID 'BES' FIELD lv_po_num.
          CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
          IF sy-subrc <> 0.
            CALL TRANSACTION 'ME23N'.                    "#EC CI_CALLTA
          ENDIF.
          RETURN.
        ELSEIF <fs_act_row>-po_action CS 'Create PO' OR <fs_act_row>-po_action CS '@15@'.
          IF gv_is_approver = abap_true.
            MESSAGE 'Approval completed. Only creator/requester can create Purchase Orders.' TYPE 'I'.
            RETURN.
          ENDIF.
          IF lv_act_ebelp IS NOT INITIAL.
            PERFORM create_po_for_single_item USING lv_act_ebelp.
          ELSE.
            PERFORM create_po_for_selected USING rs_selfield-tabindex.
          ENDIF.
          rs_selfield-refresh    = abap_true.
          rs_selfield-col_stable = abap_true.
          rs_selfield-row_stable = abap_true.
          RETURN.
        ELSEIF <fs_act_row>-po_action CS 'Approve Item'
               OR ( gv_is_approver = abap_true AND <fs_act_row>-po_action CS '@0V@' ).
          IF lv_act_ebelp IS NOT INITIAL.
            DATA: lv_act_param TYPE string.
            lv_act_param = |item={ lv_act_ebelp }|.
            PERFORM handle_html_action USING 'APPROVE_ITEM' lv_act_param.
          ENDIF.
          rs_selfield-refresh    = abap_true.
          rs_selfield-col_stable = abap_true.
          rs_selfield-row_stable = abap_true.
          RETURN.
        ELSEIF <fs_act_row>-po_action CS 'Reject' OR <fs_act_row>-po_action CS '@0W@'
               OR <fs_act_row>-po_action CS '@02@ [R]'.
          IF gv_is_approver = abap_true AND lv_act_ebelp IS NOT INITIAL.
            DATA: lv_act_p_rej TYPE string.
            lv_act_p_rej = |item={ lv_act_ebelp }|.
            PERFORM handle_html_action USING 'REJECT_ITEM' lv_act_p_rej.
            rs_selfield-refresh    = abap_true.
            rs_selfield-col_stable = abap_true.
            rs_selfield-row_stable = abap_true.
            RETURN.
          ELSEIF lv_act_ebelp IS NOT INITIAL.
            READ TABLE gt_item_ref INTO DATA(ls_r_info) WITH KEY ebelp = lv_act_ebelp.
            IF sy-subrc = 0.
              DATA: lv_ans_resub TYPE c,
                    lv_q_text    TYPE string.
              IF ls_r_info-appr_remark IS NOT INITIAL.
                lv_q_text = |Rejection Reason: "{ ls_r_info-appr_remark }". Resend Item { lv_act_ebelp } for HOD approval?|.
              ELSE.
                lv_q_text = |Resend Item { lv_act_ebelp } for HOD approval?|.
              ENDIF.
              CALL FUNCTION 'POPUP_TO_CONFIRM'
                EXPORTING
                  titlebar       = 'Resubmit Rejected Item'
                  text_question  = lv_q_text
                  text_button_1  = 'Resend'
                  text_button_2  = 'Cancel'
                  default_button = '1'
                IMPORTING
                  answer         = lv_ans_resub
                EXCEPTIONS
                  OTHERS         = 1.
              IF lv_ans_resub = '1'.
                DATA: lv_act_p_res TYPE string.
                lv_act_p_res = |item={ lv_act_ebelp }|.
                PERFORM handle_html_action USING 'SUBMIT_SINGLE' lv_act_p_res.
                rs_selfield-refresh    = abap_true.
                rs_selfield-col_stable = abap_true.
                rs_selfield-row_stable = abap_true.
                RETURN.
              ENDIF.
            ENDIF.
          ENDIF.
        ELSEIF <fs_act_row>-po_action CS 'In Approval' OR <fs_act_row>-po_action CS '@09@'.
          MESSAGE |Item { lv_act_ebelp } is in approval process. Details are locked.| TYPE 'I'.
          RETURN.
        ELSEIF <fs_act_row>-po_action CS 'Send to HOD' OR <fs_act_row>-po_action CS '@2L@'.
          IF lv_act_ebelp IS NOT INITIAL.
            DATA: lv_act_p2 TYPE string.
            lv_act_p2 = |item={ lv_act_ebelp }|.
            PERFORM handle_html_action USING 'SUBMIT_SINGLE' lv_act_p2.
          ENDIF.
          rs_selfield-refresh    = abap_true.
          rs_selfield-col_stable = abap_true.
          rs_selfield-row_stable = abap_true.
          RETURN.
        ELSEIF <fs_act_row>-po_action CS 'Select Supplier' OR rs_selfield-value CS 'Select Supplier'.
          IF lv_act_ebelp IS NOT INITIAL.
            PERFORM popup_choose_supplier USING lv_act_ebelp.
            rs_selfield-refresh    = abap_true.
            rs_selfield-col_stable = abap_true.
            rs_selfield-row_stable = abap_true.
            RETURN.
          ENDIF.
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
            IF sy-subrc = 0 AND gv_is_approver = abap_false.
              IF ls_ir_sel-appr_status = 'X'.
                MESSAGE |Item { lv_target_sel_ebelp } is approved. Selection locked; only Create PO is allowed.| TYPE 'W'.
                RETURN.
              ENDIF.
              IF ls_ir_sel-user_pref = 'X' AND ls_ir_sel-appr_status <> 'R'.
                MESSAGE |Item { lv_target_sel_ebelp } is in approval process. Selection locked.| TYPE 'W'.
                RETURN.
              ENDIF.
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
            READ TABLE gt_item_ref INTO DATA(ls_ir_col) WITH KEY ebelp = lv_target_ebelp.
            IF sy-subrc = 0 AND ls_ir_col-po_number IS NOT INITIAL.
              MESSAGE |PO { ls_ir_col-po_number } already created for Item { lv_target_ebelp }. Supplier change disabled.| TYPE 'W'.
              RETURN.
            ENDIF.
            IF sy-subrc = 0 AND gv_is_approver = abap_false.
              IF ls_ir_col-appr_status = 'X'.
                MESSAGE |Item { lv_target_ebelp } is approved. Supplier change locked; only Create PO is allowed.| TYPE 'W'.
                RETURN.
              ENDIF.
              IF ls_ir_col-user_pref = 'X' AND ls_ir_col-appr_status <> 'R'.
                MESSAGE |Item { lv_target_ebelp } is in approval process. Supplier change locked.| TYPE 'W'.
                RETURN.
              ENDIF.
            ENDIF.
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
*& Form show_item_freight_details
*&---------------------------------------------------------------------*
FORM show_item_freight_details USING pv_ebelp TYPE any
                                     pv_col   TYPE any.

  DATA: lv_flt_ebelp TYPE ekpo-ebelp.
  CLEAR lv_flt_ebelp.
  IF pv_ebelp IS NOT INITIAL AND pv_ebelp <> space.
    lv_flt_ebelp = pv_ebelp.
  ENDIF.

  TYPES: BEGIN OF ty_frt_disp,
           ebeln   TYPE ekko-ebeln,
           ebelp   TYPE ekpo-ebelp,
           lifnr   TYPE ekko-lifnr,
           name1   TYPE lfa1-name1,
           kschl   TYPE prcd_elements-kschl,
           vtext   TYPE c LENGTH 30,
           kbetr   TYPE prcd_elements-kbetr,
           waers   TYPE prcd_elements-waers,
           kwert   TYPE prcd_elements-kwert,
           waerk   TYPE prcd_elements-waerk,
           inr_amt TYPE bprei,
         END OF ty_frt_disp.

  DATA: lt_frt_disp TYPE STANDARD TABLE OF ty_frt_disp WITH DEFAULT KEY,
        ls_frt_disp TYPE ty_frt_disp.

  DATA: lt_fcat   TYPE slis_t_fieldcat_alv,
        ls_fcat   TYPE slis_fieldcat_alv,
        ls_layout TYPE slis_layout_alv.

  CLEAR lt_frt_disp.

  " Filter conditions based on lv_flt_ebelp
  LOOP AT gt_q_frt_items INTO DATA(ls_qf).
    IF lv_flt_ebelp IS NOT INITIAL AND ls_qf-ebelp <> lv_flt_ebelp.
      CONTINUE.
    ENDIF.
    CLEAR ls_frt_disp.
    ls_frt_disp-ebeln   = ls_qf-ebeln.
    ls_frt_disp-ebelp   = ls_qf-ebelp.
    ls_frt_disp-lifnr   = ls_qf-lifnr.
    ls_frt_disp-name1   = ls_qf-name1.
    ls_frt_disp-kschl   = ls_qf-kschl.
    ls_frt_disp-vtext   = ls_qf-vtext.
    ls_frt_disp-kbetr   = ls_qf-kbetr.
    ls_frt_disp-waers   = ls_qf-waers.
    ls_frt_disp-kwert   = ls_qf-kwert.
    ls_frt_disp-waerk   = ls_qf-waerk.
    ls_frt_disp-inr_amt = CONV bprei( ls_qf-inr_amt ).
    APPEND ls_frt_disp TO lt_frt_disp.
  ENDLOOP.

  IF lt_frt_disp IS INITIAL.
    MESSAGE 'No individual freight or delivery conditions found for this selection.' TYPE 'I'.
    RETURN.
  ENDIF.

  " Sort by Quotation, Item, Condition Type
  SORT lt_frt_disp BY ebeln ebelp kschl.

  CLEAR lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'EBELN'.
  ls_fcat-seltext_l = 'Quotation No'.
  ls_fcat-seltext_m = 'Quotation'.
  ls_fcat-outputlen = 12.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'EBELP'.
  ls_fcat-seltext_l = 'Item No'.
  ls_fcat-seltext_m = 'Item'.
  ls_fcat-outputlen = 6.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'LIFNR'.
  ls_fcat-seltext_l = 'Vendor'.
  ls_fcat-seltext_m = 'Vendor'.
  ls_fcat-outputlen = 10.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'NAME1'.
  ls_fcat-seltext_l = 'Vendor Name'.
  ls_fcat-seltext_m = 'Vendor Name'.
  ls_fcat-outputlen = 25.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'KSCHL'.
  ls_fcat-seltext_l = 'Condition Type'.
  ls_fcat-seltext_m = 'Cond Type'.
  ls_fcat-outputlen = 10.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'VTEXT'.
  ls_fcat-seltext_l = 'Condition Description'.
  ls_fcat-seltext_m = 'Description'.
  ls_fcat-outputlen = 25.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname  = 'KBETR'.
  ls_fcat-seltext_l  = 'Condition Rate'.
  ls_fcat-seltext_m  = 'Rate'.
  ls_fcat-cfieldname = 'WAERS'.
  ls_fcat-outputlen  = 14.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'WAERS'.
  ls_fcat-seltext_l = 'Rate Currency'.
  ls_fcat-seltext_m = 'Curr'.
  ls_fcat-outputlen = 6.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname  = 'KWERT'.
  ls_fcat-seltext_l  = 'Condition Value'.
  ls_fcat-seltext_m  = 'Doc Value'.
  ls_fcat-cfieldname = 'WAERK'.
  ls_fcat-outputlen  = 14.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'WAERK'.
  ls_fcat-seltext_l = 'Doc Currency'.
  ls_fcat-seltext_m = 'Doc Curr'.
  ls_fcat-outputlen = 6.
  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'INR_AMT'.
  ls_fcat-seltext_l = 'Amount (INR)'.
  ls_fcat-seltext_m = 'Amount (INR)'.
  ls_fcat-do_sum    = 'X'.
  ls_fcat-outputlen = 16.
  APPEND ls_fcat TO lt_fcat.

  ls_layout-colwidth_optimize = 'X'.
  ls_layout-zebra             = 'X'.

  DATA: lv_title TYPE lvc_title.
  IF lv_flt_ebelp IS NOT INITIAL.
    lv_title = |Freight Conditions Breakdown - Item { lv_flt_ebelp }|.
  ELSE.
    lv_title = 'Quotation Freight & Delivery Conditions Breakdown (All Items)'.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title          = lv_title
      is_layout             = ls_layout
      it_fieldcat           = lt_fcat
      i_screen_start_column = 10
      i_screen_start_line   = 4
      i_screen_end_column   = 135
      i_screen_end_line     = 22
    TABLES
      t_outtab              = lt_frt_disp
    EXCEPTIONS
      program_error         = 1
      OTHERS                = 2.

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

  IF gv_is_approver = abap_false.
    IF <fs_ref>-appr_status = 'X'.
      MESSAGE |Item { pv_ebelp } is approved. Supplier change locked; only Create PO is allowed.| TYPE 'W'.
      RETURN.
    ENDIF.

    IF <fs_ref>-user_pref = 'X' AND <fs_ref>-appr_status <> 'R'.
      MESSAGE |Item { pv_ebelp } is in approval process. Supplier change locked.| TYPE 'W'.
      RETURN.
    ENDIF.
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

  IF gv_is_approver = abap_false.
    IF <fs_ref>-appr_status = 'X'.
      MESSAGE |Item { pv_ebelp } is approved. Supplier change locked; only Create PO is allowed.| TYPE 'W'.
      RETURN.
    ENDIF.

    IF <fs_ref>-user_pref = 'X' AND <fs_ref>-appr_status <> 'R'.
      MESSAGE |Item { pv_ebelp } is in approval process. Supplier change locked.| TYPE 'W'.
      RETURN.
    ENDIF.
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
  <fs_ref>-sel_inco1   = ls_rfq-inco1.
  <fs_ref>-sel_freight     = ls_rfq-freight.
  <fs_ref>-sel_frt_details = ls_rfq-frt_details.
  <fs_ref>-bukrs       = COND #( WHEN ls_rfq-bukrs IS NOT INITIAL THEN ls_rfq-bukrs ELSE '1000' ).
  <fs_ref>-ekorg       = COND #( WHEN ls_rfq-ekorg IS NOT INITIAL THEN ls_rfq-ekorg ELSE 'AE01' ).
  <fs_ref>-ekgrp       = COND #( WHEN ls_rfq-ekgrp IS NOT INITIAL THEN ls_rfq-ekgrp ELSE '101' ).

  DATA(lv_s_qty) = COND ekpo-menge( WHEN <fs_ref>-menge > 0 THEN <fs_ref>-menge
                                    WHEN ls_rfq-ktmng > 0 THEN ls_rfq-ktmng
                                    WHEN ls_rfq-menge > 0 THEN ls_rfq-menge
                                    ELSE 1 ).
  DATA(lv_s_pe) = COND ekpo-peinh( WHEN ls_rfq-peinh > 0 THEN ls_rfq-peinh ELSE 1 ).
  DATA(lv_b_upr_s) = CONV decfloat34( ls_rfq-netpr ) / CONV decfloat34( lv_s_pe ).
  IF ls_rfq-waers = 'USD' AND ls_rfq-wkurs > 0.
    lv_b_upr_s = lv_b_upr_s * CONV decfloat34( ls_rfq-wkurs ).
  ENDIF.
  <fs_ref>-sel_tot_amt     = CONV decfloat34( lv_s_qty ) * lv_b_upr_s.
  <fs_ref>-sel_upr_amt     = lv_b_upr_s.
  <fs_ref>-sel_freight     = ls_rfq-freight.
  <fs_ref>-sel_frt_details = ls_rfq-frt_details.

  IF <fs_ref>-sel_lifnr <> <fs_ref>-l1_lifnr AND <fs_ref>-user_remark IS INITIAL.
    DATA: lv_sel_cancel TYPE abap_bool.
    PERFORM prompt_user_remark USING pv_ebelp
                             CHANGING <fs_ref>-user_remark
                                      lv_sel_cancel.
  ENDIF.

  IF <fs_ref>-appr_status = 'X' OR <fs_ref>-appr_status = 'R'.
    <fs_ref>-appr_status = space.
    <fs_ref>-user_pref   = space.
    <fs_ref>-appr_remark = space.
    UPDATE zmm_t_021
      SET zapprover1 = ' ',
          userpref   = ' ',
          zaremark   = ' '
      WHERE zcollectno = @<fs_ref>-submi
        AND zqitem     = @pv_ebelp.
    COMMIT WORK.
  ENDIF.
  PERFORM init_approval_status.

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

  IF gv_is_approver = abap_false.
    IF <fs_ref>-appr_status = 'X'.
      MESSAGE |Item { pv_ebelp } is approved. Selection locked; only Create PO is allowed.| TYPE 'W'.
      RETURN.
    ENDIF.

    IF <fs_ref>-user_pref = 'X' AND <fs_ref>-appr_status <> 'R'.
      MESSAGE |Item { pv_ebelp } is in approval process. Selection locked.| TYPE 'W'.
      RETURN.
    ENDIF.
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
    " Deselect only pending draft items (leave approved and in-approval items intact)
    LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_it_des>)
      WHERE po_number IS INITIAL AND appr_status <> 'X' AND user_pref <> 'X'.
      PERFORM deselect_item USING <fs_it_des>-ebelp.
    ENDLOOP.
    MESSAGE 'Draft quotation items deselected.' TYPE 'S'.
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

  IF gv_is_approver = abap_true.
    MESSAGE 'Approval completed. Only creator/requester can create Purchase Orders.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Check if all items in this collective group already have POs
  READ TABLE gt_item_ref WITH KEY po_number = space TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    MESSAGE 'All items in this collective group already have Purchase Orders created.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Step 1: Collect all items marked with [X] or @01@ that are HOD APPROVED
  DATA: lv_unappr_cnt TYPE i VALUE 0.
  LOOP AT gt_final INTO DATA(ls_row) WHERE quat = 'Val:'.
    IF ls_row-sel CS '[X]' OR ls_row-sel CS '@01@'.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_r>) WITH KEY ebelp = ls_row-ebelp.
      IF sy-subrc = 0 AND <fs_r>-po_number IS INITIAL.
        IF <fs_r>-appr_status <> 'X'.
          lv_unappr_cnt = lv_unappr_cnt + 1.
          CONTINUE.
        ENDIF.
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

  " Step 2: Fallback if no item was checked with [X], collect all HOD APPROVED items
  IF lt_sel_items IS INITIAL AND lv_unappr_cnt = 0.
    LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_appr_auto>)
      WHERE po_number IS INITIAL AND appr_status = 'X'.
      IF <fs_appr_auto>-sel_lifnr IS INITIAL.
        PERFORM popup_choose_supplier USING <fs_appr_auto>-ebelp.
        IF <fs_appr_auto>-sel_lifnr IS INITIAL.
          MESSAGE 'PO creation cancelled. Supplier not chosen.' TYPE 'S'.
          RETURN.
        ENDIF.
      ENDIF.
      APPEND <fs_appr_auto> TO lt_sel_items.
    ENDLOOP.
  ENDIF.

  " Step 3: Fallback for ALV cursor selection
  IF lt_sel_items IS INITIAL AND lv_unappr_cnt = 0.
    IF pv_tabindex > 4 AND pv_tabindex <= lines( gt_final ).
      DATA: lv_target_ebelp TYPE ekpo-ebelp.
      CLEAR lv_target_ebelp.
      READ TABLE gt_final INTO DATA(ls_cur_row) INDEX pv_tabindex.
      IF sy-subrc = 0.
        lv_target_ebelp = ls_cur_row-ebelp.
      ENDIF.
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
          IF <fs_r_cur>-appr_status <> 'X'.
            MESSAGE |PO creation locked: Item { lv_target_ebelp } is not approved by HOD.|
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

  " Step 3: Validate collected items
  IF lt_sel_items IS INITIAL.
    IF lv_unappr_cnt > 0.
      MESSAGE 'PO creation blocked: Selected line items are not approved by HOD. Only Approved items can be converted to PO.'
        TYPE 'E'.
    ELSE.
      MESSAGE 'PO creation blocked: No approved line items found for PO creation. Draft or Rejected items cannot be converted.'
        TYPE 'E'.
    ENDIF.
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

  IF gv_is_approver = abap_true.
    MESSAGE 'Approval completed. Only creator/requester can create Purchase Orders.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ref>) WITH KEY ebelp = pv_ebelp.
  IF sy-subrc = 0.
    IF <fs_ref>-po_number IS NOT INITIAL.
      MESSAGE |PO { <fs_ref>-po_number } already created for Item { pv_ebelp }.| TYPE 'W'.
      RETURN.
    ENDIF.

    IF <fs_ref>-appr_status <> 'X'.
      MESSAGE |PO creation blocked: Item { pv_ebelp } is not approved by HOD. Only Approved items can be converted to PO.|
        TYPE 'E'.
      RETURN.
    ENDIF.

    IF <fs_ref>-sel_lifnr IS INITIAL.
      PERFORM popup_choose_supplier USING pv_ebelp.
      IF <fs_ref>-sel_lifnr IS INITIAL.
        MESSAGE 'PO creation cancelled. Supplier not chosen.' TYPE 'S'.
        RETURN.
      ENDIF.
    ENDIF.
  ENDIF.

  " Mark ONLY this item as checked in gt_final, uncheck all others
  LOOP AT gt_final ASSIGNING FIELD-SYMBOL(<fs_v_all>) WHERE quat = 'Val:'.
    IF <fs_v_all>-ebelp = pv_ebelp.
      <fs_v_all>-sel = '@01@ [X]'.
    ELSE.
      <fs_v_all>-sel = '@R7@ [ ]'.
    ENDIF.
  ENDLOOP.
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
  " Header Quotation Reference, Payment Terms, Incoterms, and Currency
  DATA: lv_q_zterm   TYPE ekko-zterm,
        lv_q_inco1   TYPE ekko-inco1,
        lv_q_inco2   TYPE ekko-inco2,
        lv_q_inco2_l TYPE ekko-inco2_l,
        lv_q_waers   TYPE ekko-waers.
  CLEAR: lv_q_zterm, lv_q_inco1, lv_q_inco2, lv_q_inco2_l, lv_q_waers.

  IF pt_items IS NOT INITIAL.
    READ TABLE pt_items INTO DATA(ls_first_item) INDEX 1.
    IF sy-subrc = 0 AND ls_first_item-sel_ebeln IS NOT INITIAL.
      SELECT SINGLE zterm, inco1, inco2, inco2_l, waers FROM ekko
        WHERE ebeln = @ls_first_item-sel_ebeln
        INTO (@lv_q_zterm, @lv_q_inco1, @lv_q_inco2, @lv_q_inco2_l, @lv_q_waers).

      ls_poheader-our_ref     = ls_first_item-sel_ebeln.
      ls_poheaderx-our_ref    = abap_true.
      IF ls_first_item-submi IS NOT INITIAL.
        ls_poheader-collect_no  = ls_first_item-submi.
        ls_poheaderx-collect_no = abap_true.
      ENDIF.
    ENDIF.
  ENDIF.

  IF lv_q_waers IS INITIAL.
    IF ls_first_item-sel_waers IS NOT INITIAL.
      lv_q_waers = ls_first_item-sel_waers.
    ELSE.
      lv_q_waers = 'INR'.
    ENDIF.
  ENDIF.
  ls_poheader-currency   = lv_q_waers.
  ls_poheaderx-currency  = abap_true.

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

    " Resolve Net Price with robust 4-level fallback
    DATA: lv_item_netpr TYPE ekpo-netpr,
          lv_item_peinh TYPE ekpo-peinh.

    lv_item_netpr = ls_item-sel_netpr.
    lv_item_peinh = COND #( WHEN ls_item-sel_peinh > 0 THEN ls_item-sel_peinh ELSE 1 ).

    " Level 1: gt_rfq_items matching item and vendor
    IF lv_item_netpr <= 0.
      READ TABLE gt_rfq_items INTO DATA(ls_rfq_fb)
        WITH KEY ebelp = ls_item-ebelp lifnr = ps_vend-lifnr.
      IF sy-subrc = 0 AND ls_rfq_fb-netpr > 0.
        lv_item_netpr = ls_rfq_fb-netpr.
        IF ls_rfq_fb-peinh > 0.
          lv_item_peinh = ls_rfq_fb-peinh.
        ENDIF.
      ENDIF.
    ENDIF.

    " Level 2: direct EKPO query on quotation
    IF lv_item_netpr <= 0 AND ls_item-sel_ebeln IS NOT INITIAL.
      SELECT SINGLE netpr, peinh FROM ekpo
        WHERE ebeln = @ls_item-sel_ebeln AND ebelp = @ls_item-sel_ebelp
        INTO (@lv_item_netpr, @DATA(lv_db_p2)).
      IF sy-subrc = 0 AND lv_db_p2 > 0.
        lv_item_peinh = lv_db_p2.
      ENDIF.
    ENDIF.

    " Level 3: search quotation in EKPO by supplier and item
    IF lv_item_netpr <= 0.
      SELECT SINGLE k~netpr, k~peinh
        FROM ekpo AS k
        INNER JOIN ekko AS h ON h~ebeln = k~ebeln
        WHERE h~bstyp = 'A'
          AND h~lifnr = @ps_vend-lifnr
          AND k~ebelp = @ls_item-ebelp
          AND k~netpr > 0
        INTO (@lv_item_netpr, @DATA(lv_db_p3)).
      IF sy-subrc = 0 AND lv_db_p3 > 0.
        lv_item_peinh = lv_db_p3.
      ENDIF.
    ENDIF.

    " Level 4: If price cannot be resolved, halt PO creation cleanly
    IF lv_item_netpr <= 0.
      cv_err = |Item { ls_item-ebelp } ({ ls_item-matnr }) has net price 0.00 for Supplier { ps_vend-name1 }. | &&
               |Please maintain quotation price via ME47 first.|.
      RETURN.
    ENDIF.

    DATA(lv_item_qty) = COND ekpo-menge( WHEN ls_item-menge > 0 THEN ls_item-menge ELSE 1 ).

    ls_poitem-po_item     = lv_item_no.
    ls_poitem-material    = ls_item-matnr.
    ls_poitem-plant       = ls_item-werks.
    ls_poitem-stge_loc    = lv_item_lgort.
    ls_poitem-quantity    = lv_item_qty.
    ls_poitem-po_unit     = ls_item-meins.
    ls_poitem-net_price   = lv_item_netpr.
    ls_poitem-price_unit  = lv_item_peinh.
    ls_poitem-tax_code    = lv_tax_code.
    ls_poitem-trackingno  = ls_item-sel_ebeln.
    ls_poitem-rfq_no      = ls_item-sel_ebeln.
    ls_poitem-rfq_item    = ls_item-sel_ebelp.

    ls_poitemx-po_item     = lv_item_no.
    ls_poitemx-po_itemx    = abap_true.
    ls_poitemx-material    = abap_true.
    ls_poitemx-plant       = abap_true.
    ls_poitemx-stge_loc    = abap_true.
    ls_poitemx-quantity    = abap_true.
    ls_poitemx-po_unit     = abap_true.
    ls_poitemx-net_price   = abap_true.
    ls_poitemx-price_unit  = abap_true.
    ls_poitemx-tax_code    = abap_true.
    ls_poitemx-trackingno  = abap_true.
    ls_poitemx-rfq_no      = abap_true.
    ls_poitemx-rfq_item    = abap_true.

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
        " Update ZPO in ZMM_T_021
        UPDATE zmm_t_021
          SET zpo = @lv_po_num
          WHERE zquotation = @ls_done_item-sel_ebeln
            AND zqitem     = @ls_done_item-sel_ebelp.

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
  DATA: lv_sel_items_count  TYPE i VALUE 0,
        lv_done_items_cnt   TYPE i VALUE 0,
        lv_pending_cnt      TYPE i VALUE 0,
        lv_total_items_cnt  TYPE i VALUE 0,
        lv_selected_total   TYPE decfloat34 VALUE 0,
        lv_selected_mat_tot TYPE decfloat34 VALUE 0,
        lv_selected_frt_tot TYPE decfloat34 VALUE 0,
        lv_all_sel          TYPE abap_bool VALUE abap_false.

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
          DATA: lv_amt_sel TYPE decfloat34,
                lv_mat_sel TYPE decfloat34.
          lv_mat_sel = ( CONV decfloat34( lv_sel_qty ) * CONV decfloat34( ls_q-netpr ) ) / CONV decfloat34( lv_pe ).
          IF ls_q-waers = 'USD' AND ls_q-wkurs > 0.
            lv_mat_sel = lv_mat_sel * CONV decfloat34( ls_q-wkurs ).
          ENDIF.
          lv_selected_mat_tot = lv_selected_mat_tot + lv_mat_sel.
          lv_selected_frt_tot = lv_selected_frt_tot + ls_q-freight.
          lv_amt_sel = lv_mat_sel + ls_q-freight.
          lv_selected_total = lv_selected_total + lv_amt_sel.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF lv_pending_cnt > 0 AND lv_sel_items_count = lv_pending_cnt.
    lv_all_sel = abap_true.
  ENDIF.

  DATA: lv_fmt_sel_tot TYPE string,
        lv_fmt_sel_mat TYPE string,
        lv_fmt_sel_frt TYPE string.
  PERFORM format_inr USING lv_selected_total CHANGING lv_fmt_sel_tot.
  PERFORM format_inr USING lv_selected_mat_tot CHANGING lv_fmt_sel_mat.
  PERFORM format_inr USING lv_selected_frt_tot CHANGING lv_fmt_sel_frt.

  lv_css =
    '<style>' &&
    '* { box-sizing: border-box; margin: 0; padding: 0; }' &&
    'html, body {' &&
    '  margin: 0; padding: 6px; background: #f8fafc; width: 100%; box-sizing: border-box;' &&
    '  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Inter", "Helvetica Neue", Arial, sans-serif;' &&
    '  color: #0f172a; font-size: 12px; -webkit-font-smoothing: antialiased;' &&
    '}' &&
    '.container { width: 100%; max-width: 100%; margin: 0; padding: 0; }' &&
    '.top-header {' &&
    '  display: flex; justify-content: space-between; align-items: center;' &&
    '  padding: 8px 12px; background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);' &&
    '  border: 1px solid #cbd5e1; border-radius: 8px;' &&
    '  margin-bottom: 8px; flex-wrap: wrap; gap: 8px;' &&
    '  box-shadow: 0 2px 6px -1px rgba(0,0,0,0.05);' &&
    '}' &&
    '.top-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }' &&
    '.top-right { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }' &&
    '.select-all-btn {' &&
    '  display: inline-flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 700;' &&
    '  color: #1e293b; text-decoration: none; cursor: pointer;' &&
    '  padding: 3px 6px; border-radius: 4px; transition: background 0.15s;' &&
    '}' &&
    '.select-all-btn:hover { background: #f1f5f9; }' &&
    '.badge-count {' &&
    '  background: #f1f5f9; color: #334155; font-size: 11px; font-weight: 600;' &&
    '  padding: 3px 8px; border-radius: 6px; display: inline-block; border: 1px solid #cbd5e1;' &&
    '}' &&
    '.val-summary {' &&
    '  font-size: 13px; font-weight: 800; color: #0f172a;' &&
    '  background: #ffffff; border: 1.5px solid #e2e8f0; border-radius: 6px;' &&
    '  padding: 3px 10px; box-shadow: 0 1px 3px rgba(0,0,0,0.03);' &&
    '  display: inline-flex; align-items: center; gap: 4px;' &&
    '}' &&
    '.rate-box {' &&
    '  display: inline-flex; align-items: center; gap: 4px; background: #ffffff;' &&
    '  padding: 2px 6px; border-radius: 6px; border: 1px solid #cbd5e1; font-size: 11px;' &&
    '  font-weight: 600; color: #334155;' &&
    '}' &&
    '.rate-input {' &&
    '  width: 50px; padding: 2px 4px; border: 1px solid #cbd5e1; border-radius: 4px;' &&
    '  font-weight: 700; text-align: center; background: #ffffff; outline: none; font-size: 11px;' &&
    '}' &&
    '.rate-input:focus { border-color: #2563eb; }' &&
    '.btn-apply {' &&
    '  background: #334155; color: #ffffff; border: none; border-radius: 4px;' &&
    '  padding: 3px 8px; font-size: 10px; font-weight: 700; cursor: pointer; transition: all 0.15s;' &&
    '}' &&
    '.btn-apply:hover { background: #0f172a; transform: translateY(-0.5px); }' &&
    '.btn-refresh {' &&
    '  background: #ffffff; color: #374151; border: 1px solid #cbd5e1; border-radius: 6px;' &&
    '  padding: 4px 10px; font-size: 11px; font-weight: 600; text-decoration: none;' &&
    '  display: inline-flex; align-items: center; gap: 4px; cursor: pointer; transition: all 0.15s;' &&
    '}' &&
    '.btn-refresh:hover { background: #f8fafc; border-color: #94a3b8; transform: translateY(-0.5px); }' &&
    '.btn-po {' &&
    '  background: linear-gradient(135deg, #059669 0%, #047857 100%); color: #ffffff; border-radius: 6px;' &&
    '  padding: 4px 12px; font-size: 11px; font-weight: 700; text-decoration: none;' &&
    '  display: inline-flex; align-items: center; gap: 4px; border: none; cursor: pointer;' &&
    '  box-shadow: 0 1px 3px rgba(5,150,105,0.3); transition: all 0.15s;' &&
    '}' &&
    '.btn-po:hover { background: #047857; transform: translateY(-0.5px); box-shadow: 0 3px 8px rgba(5,150,105,0.4); }' &&
    '.btn-po-disabled {' &&
    '  background: #e2e8f0; color: #94a3b8; border-radius: 6px; padding: 4px 12px;' &&
    '  font-size: 11px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px; pointer-events: none;' &&
    '}' &&
    '.btn-appr-submit {' &&
    '  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); color: #ffffff; border-radius: 6px; padding: 4px 12px;' &&
    '  font-size: 11px; font-weight: 700; text-decoration: none; display: inline-flex;' &&
    '  align-items: center; gap: 4px; border: none; cursor: pointer;' &&
    '  box-shadow: 0 1px 3px rgba(37,99,235,0.3); transition: all 0.15s;' &&
    '}' &&
    '.btn-appr-submit:hover { background: #1d4ed8; transform: translateY(-0.5px); box-shadow: 0 3px 8px rgba(37,99,235,0.4); }' &&
    '.btn-reject {' &&
    '  background: #ffffff; color: #dc2626; border: 1.5px solid #f87171; border-radius: 6px;' &&
    '  padding: 3px 8px; font-size: 11px; font-weight: 700; text-decoration: none;' &&
    '  display: inline-flex; align-items: center; gap: 3px; cursor: pointer; transition: all 0.15s;' &&
    '}' &&
    '.btn-reject:hover { background: #fee2e2; border-color: #dc2626; }' &&
    '.radio-box {' &&
    '  display: inline-flex; align-items: center; justify-content: center; width: 17px; height: 17px;' &&
    '  border-radius: 4px; box-sizing: border-box; cursor: pointer; text-decoration: none;' &&
    '  vertical-align: middle; background: #ffffff; transition: all 0.15s ease;' &&
    '  font-size: 11px; font-weight: 800; line-height: 1;' &&
    '}' &&
    '.radio-unsel { border: 1.5px solid #94a3b8; background: #ffffff; }' &&
    '.radio-unsel:hover { border-color: #2563eb; background: #eff6ff; }' &&
    '.radio-sel { border: 1.5px solid #2563eb; background: #2563eb; color: #ffffff; }' &&
    '.radio-dot { display: none; }' &&
    '.quote-chk-btn {' &&
    '  display: inline-flex; align-items: center; gap: 5px;' &&
    '  padding: 2px 8px; border-radius: 5px; font-size: 10.5px; font-weight: 600;' &&
    '  text-decoration: none; cursor: pointer; transition: all 0.18s cubic-bezier(0.16, 1, 0.3, 1);' &&
    '  box-sizing: border-box; vertical-align: middle; user-select: none;' &&
    '}' &&
    '.quote-chk-btn .chk-sq {' &&
    '  width: 13px; height: 13px; border-radius: 3px; border: 1.5px solid #94a3b8;' &&
    '  background: #ffffff; display: inline-flex; align-items: center; justify-content: center;' &&
    '  font-size: 10px; font-weight: 800; line-height: 1; transition: all 0.15s ease; flex-shrink: 0;' &&
    '}' &&
    '.quote-chk-btn.is-unsel {' &&
    '  background: #ffffff; color: #334155; border: 1px solid #cbd5e1;' &&
    '  box-shadow: 0 1px 2px rgba(0,0,0,0.03);' &&
    '}' &&
    '.quote-chk-btn.is-unsel:hover {' &&
    '  border-color: #2563eb; background: #eff6ff; color: #1d4ed8;' &&
    '  box-shadow: 0 2px 6px rgba(37,99,235,0.15); transform: translateY(-1px);' &&
    '}' &&
    '.quote-chk-btn.is-unsel:hover .chk-sq { border-color: #2563eb; }' &&
    '.quote-chk-btn.is-sel {' &&
    '  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);' &&
    '  color: #ffffff; border: 1px solid #1d4ed8; font-weight: 700;' &&
    '  box-shadow: 0 2px 6px rgba(37,99,235,0.3);' &&
    '}' &&
    '.quote-chk-btn.is-sel:hover {' &&
    '  background: linear-gradient(135deg, #1d4ed8 0%, #1e40af 100%);' &&
    '  box-shadow: 0 3px 8px rgba(37,99,235,0.4); transform: translateY(-1px);' &&
    '}' &&
    '.quote-chk-btn.is-sel .chk-sq {' &&
    '  background: #ffffff; border-color: #ffffff; color: #1d4ed8;' &&
    '}' &&
    '.quote-chk-btn.is-appr {' &&
    '  background: linear-gradient(135deg, #16a34a 0%, #15803d 100%);' &&
    '  color: #ffffff; border: 1px solid #15803d; font-weight: 700; cursor: default;' &&
    '}' &&
    '.quote-chk-btn.is-appr .chk-sq { background: #ffffff; border-color: #ffffff; color: #16a34a; }' &&
    '.quote-chk-btn.is-rej {' &&
    '  background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);' &&
    '  color: #ffffff; border: 1px solid #b91c1c; font-weight: 700; cursor: default;' &&
    '}' &&
    '.quote-chk-btn.is-rej .chk-sq { background: #ffffff; border-color: #ffffff; color: #dc2626; }' &&
    '.quote-chk-btn.is-pend {' &&
    '  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);' &&
    '  color: #ffffff; border: 1px solid #d97706; font-weight: 700; cursor: default;' &&
    '}' &&
    '.quote-chk-btn.is-pend .chk-sq { background: #ffffff; border-color: #ffffff; color: #d97706; }' &&
    '.table-wrapper {' &&
    '  width: 100%; overflow-x: auto; border: 1px solid #cbd5e1; border-radius: 8px;' &&
    '  background: #ffffff; box-shadow: 0 4px 16px -4px rgba(15,23,42,0.06);' &&
    '}' &&
    '.cmp-table { width: 100%; border-collapse: collapse; background: #ffffff; font-variant-numeric: tabular-nums; }' &&
    '.cmp-table th {' &&
    '  padding: 6px 8px; font-size: 11px; font-weight: 700; color: #0f172a;' &&
    '  text-align: left; vertical-align: middle; border: 1px solid #94a3b8; background: #e2e8f0;' &&
    '}' &&
    '.cmp-table td {' &&
    '  padding: 6px 8px; font-size: 12px; color: #0f172a; vertical-align: middle; border: 1px solid #cbd5e1;' &&
    '}' &&
    '.cmp-table tbody tr:hover { background: #f8fafc; }' &&
    '.cmp-table tbody tr:nth-child(even) { background: #fafbfc; }' &&
    '.quote-cell {' &&
    '  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1); position: relative; vertical-align: top;' &&
    '}' &&
    '.quote-cell:hover {' &&
    '  background: #f8fafc;' &&
    '  box-shadow: inset 0 0 0 1px #94a3b8;' &&
    '}' &&
    '.quote-cell-sel {' &&
    '  background: #eff6ff !important;' &&
    '  border-left: 2px solid #2563eb !important; border-right: 2px solid #2563eb !important;' &&
    '  box-shadow: inset 0 0 0 1px #93c5fd;' &&
    '}' &&
    '.quote-cell-l1 {' &&
    '  background: #f0fdf4 !important;' &&
    '  border-left: 2px solid #16a34a !important; border-right: 2px solid #16a34a !important;' &&
    '}' &&
    '.quote-cell-sel.quote-cell-l1 {' &&
    '  background: #f0fdf4 !important;' &&
    '  border-left: 2px solid #16a34a !important; border-right: 2px solid #16a34a !important;' &&
    '  box-shadow: inset 0 0 0 1px #86efac;' &&
    '}' &&
    '.v-hdr-title { font-size: 12px; font-weight: 700; color: #0f172a; line-height: 1.25; }' &&
    '.v-hdr-sub { font-size: 10px; font-weight: 500; color: #64748b; margin-top: 1px; }' &&
    '.mat-code { font-size: 12px; font-weight: 700; color: #0f172a; font-family: monospace; }' &&
    '.mat-desc { font-size: 12px; font-weight: 500; color: #334155; line-height: 1.3; }' &&
    '.mat-qty { font-size: 12px; font-weight: 700; color: #0f172a; }' &&
    '.quote-amt { font-size: 13.5px; font-weight: 800; color: #0f172a; letter-spacing: -0.2px; }' &&
    '.quote-cell-sel .quote-amt { color: #1e40af; }' &&
    '.quote-cell-l1 .quote-amt { color: #14532d; }' &&
    '.quote-unit { font-size: 10px; color: #64748b; margin-top: 1px; }' &&
    '.rank-lowest {' &&
    '  display: inline-flex; align-items: center; gap: 3px;' &&
    '  background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%);' &&
    '  color: #14532d; font-size: 9.5px; font-weight: 700;' &&
    '  padding: 1.5px 6px; border-radius: 10px; border: 1px solid #86efac;' &&
    '  box-shadow: 0 1px 2px rgba(22,163,74,0.12);' &&
    '}' &&
    '.rank-lowest::before {' &&
    '  content: ""; width: 5px; height: 5px; border-radius: 50%; background: #16a34a; display: inline-block;' &&
    '}' &&
    '.rank-other {' &&
    '  display: inline-block; background: #f1f5f9; color: #64748b; font-size: 9.5px; font-weight: 600;' &&
    '  padding: 1.5px 6px; border-radius: 10px; border: 1px solid #cbd5e1;' &&
    '}' &&
    '.frt-link-pill {' &&
    '  display: inline-flex; align-items: center; gap: 3px;' &&
    '  background: #fffbeb; color: #b45309; padding: 1.5px 5px;' &&
    '  border-radius: 4px; border: 1px solid #fde68a;' &&
    '  font-size: 10px; font-weight: 600; text-decoration: none;' &&
    '  transition: all 0.15s ease;' &&
    '}' &&
    '.frt-link-pill:hover {' &&
    '  background: #fef3c7; color: #78350f; border-color: #f59e0b;' &&
    '  transform: translateY(-0.5px);' &&
    '}' &&
    '.btn-pill-sel { background: #2563eb; color: #ffffff; font-size: 10px; font-weight: 700; padding: 2px 8px; border-radius: 4px; border: 1px solid #1d4ed8; text-decoration: none; display: inline-block; }' &&
    '.btn-pill-unsel { background: #ffffff; color: #334155; font-size: 10px; font-weight: 600; padding: 2px 8px; border-radius: 4px; border: 1px solid #cbd5e1; text-decoration: none; display: inline-block; }' &&
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
    '  font-size: 11px; font-weight: 800; color: #0f172a; padding: 7px 10px;' &&
    '  border: 1px solid #64748b; background: #e2e8f0; text-transform: uppercase; letter-spacing: 0.3px;' &&
    '}' &&
    '.tot-amt {' &&
    '  font-size: 12.5px; font-weight: 800; color: #0f172a; padding: 7px 10px;' &&
    '  border: 1px solid #64748b; background: #f8fafc; text-align: right;' &&
    '}' &&
    '.tot-min {' &&
    '  font-size: 12.5px; font-weight: 700; color: #059669; padding: 7px 10px;' &&
    '  border: 1px solid #64748b; background: #ecfdf5; text-align: right;' &&
    '}' &&
    '.comm-sec-hdr td {' &&
    '  background: #cbd5e1; font-size: 11px; font-weight: 800; color: #0f172a;' &&
    '  padding: 7px 10px; text-transform: uppercase; letter-spacing: 0.3px; border: 1px solid #94a3b8;' &&
    '}' &&
    '.comm-param-label {' &&
    '  font-size: 11px; font-weight: 600; color: #1e293b; padding: 5px 8px;' &&
    '  background: #f8fafc; border: 1px solid #cbd5e1;' &&
    '}' &&
    '.comm-param-val {' &&
    '  font-size: 11px; color: #0f172a; padding: 5px 8px; border: 1px solid #cbd5e1;' &&
    '}' &&
    '.comm-row-hl td { background: #fefce8; font-weight: 600; border: 1px solid #cbd5e1; }' &&
    '.comm-row-eval td {' &&
    '  background: linear-gradient(90deg, #dcfce7 0%, #bbf7d0 100%); font-weight: 800; font-size: 12px; color: #166534;' &&
    '  border-top: 2px solid #16a34a; border-bottom: 2px solid #16a34a; border-left: 1px solid #86efac; border-right: 1px solid #86efac;' &&
    '}' &&
    '</style>'.

  DATA: lv_appr_badge   TYPE string,
        lv_appr_actions TYPE string,
        lv_unsub_cnt    TYPE i VALUE 0,
        lv_pend_cnt     TYPE i VALUE 0,
        lv_appr_cnt     TYPE i VALUE 0,
        lv_rej_cnt      TYPE i VALUE 0,
        lv_po_done_cnt  TYPE i VALUE 0.

  LOOP AT gt_item_ref INTO DATA(ls_cnt_ir).
    IF ls_cnt_ir-po_number IS NOT INITIAL.
      lv_po_done_cnt = lv_po_done_cnt + 1.
    ELSEIF ls_cnt_ir-sel_lifnr IS NOT INITIAL.
      IF ls_cnt_ir-appr_status = 'X'.
        lv_appr_cnt = lv_appr_cnt + 1.
      ELSEIF ls_cnt_ir-appr_status = 'R'.
        lv_rej_cnt = lv_rej_cnt + 1.
      ELSE.
        IF gv_is_approver = abap_true.
          lv_pend_cnt = lv_pend_cnt + 1.
        ELSE.
          IF ls_cnt_ir-user_pref = 'X'.
            lv_pend_cnt = lv_pend_cnt + 1.
          ELSE.
            lv_unsub_cnt = lv_unsub_cnt + 1.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF gv_is_approver = abap_true.
    " Approver View
    lv_appr_badge =
      '<span class="badge-count" style="background:#4f46e5;color:#ffffff;' &&
      'border:1px solid #4338ca;font-weight:700;padding:3px 10px;font-size:11px;">' &&
      |&#128737;&#65039; Approver: { gv_hod_name } ({ gv_hod_user })</span>|.
    IF lv_pend_cnt > 0.
      lv_appr_badge = lv_appr_badge &&
        ' <span class="badge-count" style="background:#f59e0b;color:#ffffff;' &&
        'border:1px solid #d97706;font-weight:700;padding:3px 10px;font-size:11px;">' &&
        |&#9203; { lv_pend_cnt } Awaiting Your Approval</span>|.
    ENDIF.
    IF lv_appr_cnt > 0.
      lv_appr_badge = lv_appr_badge &&
        ' <span class="badge-count" style="background:#16a34a;color:#ffffff;' &&
        'border:1px solid #15803d;font-weight:700;padding:3px 10px;font-size:11px;">' &&
        |&#10003; { lv_appr_cnt } Approved</span>|.
    ENDIF.
    IF lv_rej_cnt > 0.
      lv_appr_badge = lv_appr_badge &&
        ' <span class="badge-count" style="background:#fee2e2;color:#991b1b;' &&
        'border:1px solid #f87171;font-weight:700;padding:3px 10px;font-size:11px;">' &&
        |&#10007; { lv_rej_cnt } Rejected</span>|.
    ENDIF.

    DATA(lv_act_tot_html) = lv_pend_cnt + lv_rej_cnt.
    IF lv_act_tot_html > 0.
      lv_appr_actions =
        |<a href="sapevent:APPROVE" class="btn-po" style="background:#059669;"| &&
        | title="Approve pending items">&#10003; Approve All ({ lv_act_tot_html })</a>| &&
        ' <a href="sapevent:REJECT" class="btn-reject" title="Reject comparison with compulsory remark">&#10007; Reject All</a>'.
    ELSEIF lv_appr_cnt > 0.
      lv_appr_actions =
        ' <a href="sapevent:REJECT" class="btn-reject" title="Reject comparison with compulsory remark">&#10007; Reject All</a>'.
    ENDIF.
    IF lv_appr_cnt > 0.
      lv_appr_badge = lv_appr_badge &&
        ' <span class="badge-count" style="background:#dcfce7;color:#15803d;' &&
        'border:1px solid #86efac;font-weight:700;padding:3px 10px;font-size:11px;">' &&
        |Sent to Creator for PO</span>|.
    ENDIF.

  ELSE.
    " User / Requester View - STRICT ROLE ISOLATION: NEVER DISPLAY APPROVE OR REJECT!
    IF lv_unsub_cnt > 0.
      lv_appr_badge =
        '<span class="badge-count" style="background:#dbeafe;color:#1e40af;' &&
        'border:1px solid #93c5fd;font-weight:700;padding:3px 10px;font-size:11px;">' &&
        |{ lv_unsub_cnt } Ready to Submit</span>|.
    ENDIF.
    IF lv_pend_cnt > 0.
      lv_appr_badge = lv_appr_badge &&
        ' <span class="badge-count" style="background:#f59e0b;color:#ffffff;' &&
        'border:1px solid #d97706;font-weight:700;padding:3px 10px;font-size:11px;">' &&
        |&#9203; { lv_pend_cnt } Pending HOD ({ gv_hod_user })</span>|.
    ENDIF.
    IF lv_appr_cnt > 0.
      lv_appr_badge = lv_appr_badge &&
        ' <span class="badge-count" style="background:#16a34a;color:#ffffff;' &&
        'border:1px solid #15803d;font-weight:700;padding:3px 10px;font-size:11px;">' &&
        |&#10003; { lv_appr_cnt } Approved</span>|.
    ENDIF.
    IF lv_rej_cnt > 0.
      lv_appr_badge = lv_appr_badge &&
        ' <span class="badge-count" style="background:#fee2e2;color:#991b1b;' &&
        'border:1px solid #f87171;font-weight:700;padding:3px 10px;font-size:11px;">' &&
        |&#10007; { lv_rej_cnt } Rejected</span>|.
    ENDIF.
    IF lv_appr_badge IS INITIAL.
      lv_appr_badge =
        '<span class="badge-count" style="background:#f1f5f9;color:#475569;' &&
        'border:1px solid #94a3b8;font-weight:700;padding:3px 10px;font-size:11px;">Draft</span>'.
    ENDIF.

    " Available Actions for Creator
    DATA(lv_ready_submit) = lv_unsub_cnt + lv_rej_cnt.
    IF lv_ready_submit > 0.
      lv_appr_actions =
        |<a href="sapevent:SUBMIT_APPROVAL" class="btn-appr-submit"| &&
        | title="Submit items to HOD for approval">&#128228; Send for Approval ({ lv_ready_submit })</a>|.
    ENDIF.
    IF lv_appr_cnt > 0.
      lv_appr_actions = lv_appr_actions &&
        | <a href="sapevent:CREATE_PO" class="btn-po">&#128722; Create PO ({ lv_appr_cnt } Approved)</a>|.
    ENDIF.
  ENDIF.

  DATA: lv_rej_banner TYPE string.
  CLEAR lv_rej_banner.
  IF lv_rej_cnt > 0.
    DATA: lt_rej_banner_items TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    CLEAR lt_rej_banner_items.
    LOOP AT gt_item_ref INTO DATA(ls_r_item) WHERE appr_status = 'R'.
      APPEND |Item { ls_r_item-ebelp }: "{ ls_r_item-appr_remark }"| TO lt_rej_banner_items.
    ENDLOOP.
    DATA(lv_rej_details) = concat_lines_of( table = lt_rej_banner_items sep = ' &middot; ' ).
    lv_rej_banner =
      '<div style="margin: 6px 0; padding: 8px 12px; background: #fef2f2; border: 1px solid #f87171;' &&
      'border-radius: 6px; color: #991b1b; display: flex; align-items: center; justify-content: space-between; font-size: 11px;">' &&
      '  <div style="display: flex; align-items: center; gap: 8px;">' &&
      '    <span style="display:inline-flex;align-items:center;justify-content:center;width:20px;height:20px;' &&
      '          border-radius:50%;background:#fee2e2;color:#dc2626;font-size:12px;font-weight:800;">&#10007;</span>' &&
      '    <span><strong>Rejected by Approver:</strong> ' && lv_rej_details && '</span>' &&
      '  </div>' &&
      '  <span style="font-weight: 600; font-size: 10px; color: #b91c1c;">Sent back to creator. Please review remarks and resubmit.</span>' &&
      '</div>'.
  ENDIF.

  lv_html =
    '<!DOCTYPE html>' &&
    '<html lang="en"><head>' &&
    '<meta charset="utf-8">' &&
    '<meta http-equiv="X-UA-Compatible" content="IE=edge">' &&
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">' &&
    '<title>Quotation Price Comparison Dashboard (ZPQC_NEW v3.3)</title>' &&
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
        '<a href="sapevent:TOGGLE_ALL" class="select-all-btn" title="Toggle Select All items">' &&
        COND string(
          WHEN lv_all_sel = abap_true THEN
            '<span class="radio-box radio-sel">&#10003;</span>'
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
    '    <span class="badge-count" style="font-size:10px;background:#e2e8f0;color:#334155;">v3.3</span>' &&
    |    { lv_appr_badge }| &&
    COND string(
      WHEN gv_is_approver = abap_true THEN
        '    <span class="badge-count" style="font-size:10px;' &&
        'background:#ede9fe;color:#5b21b6;border:1px solid #c4b5fd;">' &&
        |Approver: { gv_hod_name } ({ gv_hod_user })</span>|
      ELSE
        '    <span class="badge-count" style="font-size:10px;' &&
        'background:#f8fafc;color:#334155;border:1px solid #cbd5e1;">' &&
        |HOD Approver: { gv_hod_name } ({ gv_hod_user })</span>|
    ) &&
    '  </div>' &&
    '  <div class="top-right">' &&
    COND string(
      WHEN lv_selected_frt_tot > 0 THEN
        |    <span class="val-summary" title="Basic Total: ₹{ lv_fmt_sel_mat } + Delivery: ₹{ lv_fmt_sel_frt } = Landed ₹{ lv_fmt_sel_tot }">Selected: &#8377;{ lv_fmt_sel_mat }| &&
        | <span style="font-size:11px;font-weight:600;color:#b45309;">(+&#8377;{ lv_fmt_sel_frt } Delivery = &#8377;{ lv_fmt_sel_tot })</span></span>|
      ELSE
        |    <span class="val-summary">Selected: &#8377;{ lv_fmt_sel_mat }</span>|
    ) &&
    '    <div class="rate-box">' &&
    '      <span>Rate:</span>' &&
    |      <input type="number" id="inpRate" value="{ p_rate DECIMALS = 2 }" step="0.25" class="rate-input" />| &&
    '      <span>%</span>' &&
    '      <button onclick="applyRate()" class="btn-apply">Apply</button>' &&
    '    </div>' &&
    '    <a href="sapevent:REFRESH" class="btn-refresh">&#128260; Refresh</a>' &&
    lv_appr_actions &&
    '  </div>' &&
    '</div>'.

  " Table header
  lv_html = lv_html &&
    lv_rej_banner &&
    '<div class="table-wrapper">' &&
    '<table class="cmp-table">' &&
    '  <thead><tr>' &&
    '    <th style="width: 38px; text-align: center; vertical-align: middle;">Sel</th>' &&
    '    <th style="width: 48px; text-align: center;">Item</th>' &&
    '    <th style="width: 110px; white-space: nowrap;">Material</th>' &&
    '    <th style="min-width: 160px;">Material Description</th>' &&
    '    <th style="width: 75px; text-align: right; white-space: nowrap;">Qty</th>' &&
    '    <th style="min-width: 140px; background: #f8fafc; color: #334155; border-left: 1px solid #cbd5e1;">' &&
    '      <div class="v-hdr-title" style="color: #334155;">Last Purchase Price</div>' &&
    '      <div class="v-hdr-sub" style="color: #64748b;">Previous PO Benchmark</div>' &&
    '    </th>'.

  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html &&
      '<th style="min-width: 155px;">' &&
      |  <div class="v-hdr-title">{ wa_hdr-name1 }</div>| &&
      |  <div class="v-hdr-sub">Vendor { wa_hdr-lifnr } · | &&
      |    <a href="sapevent:ME47?ebeln={ wa_hdr-ebeln }" style="color:#2563eb;text-decoration:underline;"| &&
      |       title="Maintain quotation dates and pricing in ME47">RFQ #{ wa_hdr-ebeln } &#9998;</a></div>| &&
      '</th>'.
  ENDLOOP.

  lv_html = lv_html &&
    '<th style="min-width: 155px; background: #ecfdf5; color: #065f46; border-left: 2px solid #10b981;">' &&
    '  <div class="v-hdr-title" style="color: #065f46;">System Suggested (L1)</div>' &&
    '  <div class="v-hdr-sub" style="color: #047857;">Lowest Evaluated Quote</div>' &&
    '</th>' &&
    '<th style="min-width: 165px; background: #eff6ff; color: #1e40af; border-left: 2px solid #3b82f6;">' &&
    '  <div class="v-hdr-title" style="color: #1e40af;">User Suggested</div>' &&
    '  <div class="v-hdr-sub" style="color: #2563eb;">Selected Supplier</div>' &&
    '</th>' &&
    '  </tr></thead><tbody>'.

  TYPES: BEGIN OF ty_temp_rank,
           lifnr    TYPE ekko-lifnr,
           b_amount TYPE decfloat34,
           landed   TYPE decfloat34,
           rank     TYPE i,
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
      DATA: lv_amt TYPE decfloat34.
      lv_amt = ( CONV decfloat34( lv_q_qty ) * CONV decfloat34( ls_q-netpr ) ) / CONV decfloat34( lv_peinh ).
      IF ls_q-waers = 'USD' AND ls_q-wkurs > 0.
        lv_amt = lv_amt * CONV decfloat34( ls_q-wkurs ).
      ENDIF.
      DATA(lv_lnd) = lv_amt + ls_q-freight.
      APPEND VALUE #( lifnr = ls_q-lifnr b_amount = lv_amt landed = lv_lnd ) TO lt_tranks.
    ENDLOOP.
    SORT lt_tranks BY landed ASCENDING.
    DATA(lv_curr_rank) = 1.
    LOOP AT lt_tranks ASSIGNING FIELD-SYMBOL(<fs_tr>).
      <fs_tr>-rank = lv_curr_rank.
      lv_curr_rank = lv_curr_rank + 1.
    ENDLOOP.

    DATA: lv_fmt_min TYPE string.
    CLEAR lv_fmt_min.
    IF lines( lt_tranks ) > 0.
      READ TABLE lt_tranks INTO ls_trank INDEX 1.
      IF ls_trank-b_amount > 0.
        PERFORM format_inr USING ls_trank-b_amount CHANGING lv_fmt_min.
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
      ELSE |{ CONV decfloat34( ls_item-menge ) STYLE = SIMPLE }| ).

    IF ls_item-po_number IS NOT INITIAL.
      lv_html = lv_html &&
        '<tr>' &&
        '  <td style="text-align: center; vertical-align: middle;">' &&
        |    <a href="sapevent:ME23N?ebeln={ ls_item-po_number }" title="PO { ls_item-po_number } Created" style="text-decoration:none;">| &&
        '      <span style="display:inline-flex;align-items:center;justify-content:center;width:18px;height:18px;' &&
        '            border-radius:50%;background:#dcfce7;color:#166534;font-size:11px;font-weight:800;">&#10003;</span>' &&
        '    </a>' &&
        '  </td>' &&
        |  <td style="text-align: center; font-weight: 600; color: #64748b;">{ ls_item-ebelp }</td>| &&
        |  <td><div class="mat-code">{ ls_item-matnr }</div></td>| &&
        |  <td><div class="mat-desc">{ ls_item-txz01 }</div></td>| &&
        |  <td style="text-align: right;"><div class="mat-qty">{ lv_qty_str } { ls_item-meins }</div></td>|.
    ELSEIF ls_item-appr_status = 'X'.
      lv_html = lv_html &&
        '<tr>' &&
        '  <td style="text-align: center; vertical-align: middle;">' &&
        '    <span class="radio-box radio-sel" style="background:#16a34a;border-color:#16a34a;cursor:not-allowed;"' &&
        '          title="Item is Approved">&#10003;</span>' &&
        '  </td>' &&
        |  <td style="text-align: center; font-weight: 600; color: #64748b;">{ ls_item-ebelp }</td>| &&
        |  <td><div class="mat-code">{ ls_item-matnr }</div></td>| &&
        |  <td><div class="mat-desc">{ ls_item-txz01 }</div></td>| &&
        |  <td style="text-align: right;"><div class="mat-qty">{ lv_qty_str } { ls_item-meins }</div></td>|.
    ELSEIF ls_item-appr_status = 'R'.
      lv_html = lv_html &&
        '<tr>' &&
        '  <td style="text-align: center; vertical-align: middle;">' &&
        '    <span class="radio-box radio-sel" style="background:#dc2626;border-color:#dc2626;cursor:not-allowed;"' &&
        '          title="Item is Rejected &#183; Resend for Approval">&#10007;</span>' &&
        '  </td>' &&
        |  <td style="text-align: center; font-weight: 600; color: #64748b;">{ ls_item-ebelp }</td>| &&
        |  <td><div class="mat-code">{ ls_item-matnr }</div></td>| &&
        |  <td><div class="mat-desc">{ ls_item-txz01 }</div></td>| &&
        |  <td style="text-align: right;"><div class="mat-qty">{ lv_qty_str } { ls_item-meins }</div></td>|.
    ELSEIF ls_item-user_pref = 'X'.
      lv_html = lv_html &&
        '<tr>' &&
        '  <td style="text-align: center; vertical-align: middle;">' &&
        '    <span class="radio-box radio-sel" style="background:#f59e0b;border-color:#f59e0b;color:#ffffff;cursor:not-allowed;"' &&
        '          title="Item is in Approval Process">&#9203;</span>' &&
        '  </td>' &&
        |  <td style="text-align: center; font-weight: 600; color: #64748b;">{ ls_item-ebelp }</td>| &&
        |  <td><div class="mat-code">{ ls_item-matnr }</div></td>| &&
        |  <td><div class="mat-desc">{ ls_item-txz01 }</div></td>| &&
        |  <td style="text-align: right;"><div class="mat-qty">{ lv_qty_str } { ls_item-meins }</div></td>|.
    ELSE.
      lv_html = lv_html &&
        '<tr>' &&
        '  <td style="text-align: center; vertical-align: middle;">' &&
        |    <a href="sapevent:TOGGLE_ROW?item={ ls_item-ebelp }" title="Toggle item selection">| &&
        COND string(
          WHEN lv_row_sel = abap_true THEN
            '<span class="radio-box radio-sel">&#10003;</span>'
          ELSE
            '<span class="radio-box radio-unsel"></span>'
        ) &&
        '    </a>' &&
        '  </td>' &&
        |  <td style="text-align: center; font-weight: 600; color: #64748b;">{ ls_item-ebelp }</td>| &&
        |  <td><div class="mat-code">{ ls_item-matnr }</div></td>| &&
        |  <td><div class="mat-desc">{ ls_item-txz01 }</div></td>| &&
        |  <td style="text-align: right;"><div class="mat-qty">{ lv_qty_str } { ls_item-meins }</div></td>|.
    ENDIF.

    " Last Purchase Price (LPP) Benchmark Cell
    DATA: lv_fmt_lpp    TYPE string,
          lv_lpp_badge  TYPE string,
          lv_disp_bedat TYPE string.
    CLEAR: lv_fmt_lpp, lv_lpp_badge, lv_disp_bedat.

    IF ls_item-lpp_upr_amt > 0.
      PERFORM format_inr USING ls_item-lpp_upr_amt CHANGING lv_fmt_lpp.
      IF ls_item-lpp_bedat IS NOT INITIAL.
        lv_disp_bedat = |{ ls_item-lpp_bedat+6(2) }.{ ls_item-lpp_bedat+4(2) }.{ ls_item-lpp_bedat(4) }|.
      ENDIF.

      IF ls_item-l1_upr_amt > 0.
        DATA(lv_lpp_diff_pct) = ( ( ls_item-l1_upr_amt - ls_item-lpp_upr_amt ) / ls_item-lpp_upr_amt ) * 100.
        IF lv_lpp_diff_pct > 0.
          lv_lpp_badge =
            '<span style="display:inline-block;background:#fee2e2;color:#991b1b;font-size:9px;font-weight:700;' &&
            'padding:1px 5px;border-radius:4px;border:1px solid #f87171;margin-top:2px;"' &&
            | title="L1 rate is higher than last PO by { lv_lpp_diff_pct DECIMALS = 1 }%">| &&
            |&#9650; +{ lv_lpp_diff_pct DECIMALS = 1 }% vs LPP</span>|.
        ELSEIF lv_lpp_diff_pct < 0.
          DATA(lv_lpp_abs_pct) = abs( lv_lpp_diff_pct ).
          lv_lpp_badge =
            '<span style="display:inline-block;background:#dcfce7;color:#15803d;font-size:9px;font-weight:700;' &&
            'padding:1px 5px;border-radius:4px;border:1px solid #86efac;margin-top:2px;"' &&
            | title="L1 rate is lower by { lv_lpp_abs_pct DECIMALS = 1 }% vs last PO (Cost Savings)">| &&
            |&#9660; -{ lv_lpp_abs_pct DECIMALS = 1 }% Savings</span>|.
        ELSE.
          lv_lpp_badge =
            '<span style="display:inline-block;background:#f1f5f9;color:#475569;font-size:9px;font-weight:600;' &&
            'padding:1px 5px;border-radius:4px;border:1px solid #cbd5e1;margin-top:2px;">= Same Rate</span>'.
        ENDIF.
      ENDIF.

      lv_html = lv_html &&
        '<td style="background: #f8fafc; border-left: 1px solid #cbd5e1; border-right: 1px solid #cbd5e1; font-size: 11px;">' &&
        |  <div style="font-weight: 700; color: #1e293b; font-size: 12px;">&#8377;{ lv_fmt_lpp } | &&
        |    <span style="font-weight: 400; font-size: 10px; color: #64748b;">/ { ls_item-lpp_meins }</span></div>| &&
        |  <div style="margin-top: 1px;"><a href="sapevent:ME23N?ebeln={ ls_item-lpp_ebeln }"| &&
        |       style="color: #2563eb; text-decoration: underline; font-size: 10px; font-weight: 600;"| &&
        |       title="View Last PO { ls_item-lpp_ebeln } in ME23N">PO #{ ls_item-lpp_ebeln } &#8599;</a></div>| &&
        |  <div style="font-size: 10px; color: #64748b; line-height: 1.2;">{ lv_disp_bedat } &middot; { ls_item-lpp_name1(12) }</div>| &&
        |  { lv_lpp_badge }| &&
        '</td>'.
    ELSE.
      lv_html = lv_html &&
        '<td style="background: #f8fafc; border-left: 1px solid #cbd5e1; border-right: 1px solid #cbd5e1; text-align: center; font-size: 11px;">' &&
        '  <div style="color: #94a3b8; font-style: italic;">No PO History</div>' &&
        '  <div style="font-size: 9px; color: #94a3b8;">New Material</div>' &&
        '</td>'.
    ENDIF.

    DATA(lv_cidx) = 1.
    LOOP AT gt_hdr INTO wa_hdr.
      DATA(lv_is_sel) = xsdbool( ls_item-sel_lifnr = wa_hdr-lifnr ).
      READ TABLE gt_rfq_items INTO DATA(ls_qitem)
        WITH KEY ebelp = ls_item-ebelp lifnr = wa_hdr-lifnr.

      IF sy-subrc = 0 AND ls_qitem-netpr > 0.
        READ TABLE lt_tranks INTO ls_trank WITH KEY lifnr = wa_hdr-lifnr.
        DATA(lv_rk) = ls_trank-rank.
        DATA(lv_item_total) = ls_trank-b_amount.

        IF lv_item_total <= 0.
          DATA(lv_v_qty) = COND ekpo-menge( WHEN ls_item-menge > 0 THEN ls_item-menge
                                            WHEN ls_qitem-ktmng > 0 THEN ls_qitem-ktmng
                                            WHEN ls_qitem-menge > 0 THEN ls_qitem-menge
                                            ELSE 1 ).
          DATA(lv_v_pe) = COND ekpo-peinh( WHEN ls_qitem-peinh > 0 THEN ls_qitem-peinh ELSE 1 ).
          lv_item_total = ( CONV decfloat34( lv_v_qty ) * CONV decfloat34( ls_qitem-netpr ) ) /
                          CONV decfloat34( lv_v_pe ).
          IF ls_qitem-waers = 'USD' AND ls_qitem-wkurs > 0.
            lv_item_total = lv_item_total * CONV decfloat34( ls_qitem-wkurs ).
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

        DATA: lv_uprice TYPE decfloat34.
        lv_uprice = CONV decfloat34( ls_qitem-netpr ) /
                    COND decfloat34( WHEN ls_qitem-peinh > 0 THEN ls_qitem-peinh ELSE 1 ).
        IF ls_qitem-waers = 'USD' AND ls_qitem-wkurs > 0.
          lv_uprice = lv_uprice * CONV decfloat34( ls_qitem-wkurs ).
        ENDIF.
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
        ELSEIF ls_item-appr_status = 'X'.
          IF lv_is_sel = abap_true.
            lv_pill_action =
              '<span class="quote-chk-btn is-appr" title="Quotation Approved"><span class="chk-sq">&#10003;</span><span>Approved</span></span>'.
          ELSE.
            IF gv_is_approver = abap_true.
              lv_pill_action =
                |<a href="sapevent:SELECT?item={ ls_item-ebelp }&col=QUAT{ lv_cidx }" class="quote-chk-btn is-unsel" title="Select this quotation"><span class="chk-sq"></span><span>Select</span></a>|.
            ELSE.
              lv_pill_action = space.
            ENDIF.
          ENDIF.
        ELSEIF ls_item-appr_status = 'R'.
          IF lv_is_sel = abap_true.
            lv_pill_action =
              '<span class="quote-chk-btn is-rej" title="Quotation Rejected"><span class="chk-sq">&#10007;</span><span>Rejected</span></span>'.
          ELSE.
            lv_pill_action =
              |<a href="sapevent:SELECT?item={ ls_item-ebelp }&col=QUAT{ lv_cidx }" class="quote-chk-btn is-unsel" title="Select this quotation"><span class="chk-sq"></span><span>Select</span></a>|.
          ENDIF.
        ELSEIF ls_item-user_pref = 'X'.
          IF lv_is_sel = abap_true.
            lv_pill_action =
              '<span class="quote-chk-btn is-pend" title="Quotation in Approval Process"><span class="chk-sq">&#9203;</span><span>In Approval</span></span>'.
          ELSE.
            IF gv_is_approver = abap_true.
              lv_pill_action =
                |<a href="sapevent:SELECT?item={ ls_item-ebelp }&col=QUAT{ lv_cidx }" class="quote-chk-btn is-unsel" title="Select this quotation"><span class="chk-sq"></span><span>Select</span></a>|.
            ELSE.
              lv_pill_action = space.
            ENDIF.
          ENDIF.
        ELSE.
          IF lv_is_sel = abap_true.
            lv_pill_action =
              |<a href="sapevent:DESELECT?item={ ls_item-ebelp }" class="quote-chk-btn is-sel" title="Selected · Click to deselect"><span class="chk-sq">&#10003;</span><span>Selected</span></a>|.
          ELSE.
            lv_pill_action =
              |<a href="sapevent:SELECT?item={ ls_item-ebelp }&col=QUAT{ lv_cidx }" class="quote-chk-btn is-unsel" title="Click to select this quotation"><span class="chk-sq"></span><span>Select</span></a>|.
          ENDIF.
        ENDIF.

        DATA lv_td_cls TYPE string.
        IF lv_is_sel = abap_true AND lv_rk = 1.
          lv_td_cls = ' class="quote-cell quote-cell-sel quote-cell-l1"'.
        ELSEIF lv_is_sel = abap_true.
          lv_td_cls = ' class="quote-cell quote-cell-sel"'.
        ELSEIF lv_rk = 1.
          lv_td_cls = ' class="quote-cell quote-cell-l1"'.
        ELSE.
          lv_td_cls = ' class="quote-cell"'.
        ENDIF.

        DATA: lv_q_frt_html TYPE string,
              lv_fmt_q_frt  TYPE string.
        CLEAR: lv_q_frt_html, lv_fmt_q_frt.
        IF ls_qitem-freight > 0.
          PERFORM format_inr USING ls_qitem-freight CHANGING lv_fmt_q_frt.
          DATA(lv_det_txt) = COND string( WHEN ls_qitem-frt_details IS NOT INITIAL THEN | ({ ls_qitem-frt_details })| ELSE '' ).
          lv_q_frt_html =
            |<div style="margin-top: 2px;">| &&
            |  <a href="sapevent:SHOW_ITEM_FREIGHT?item={ ls_item-ebelp }" class="frt-link-pill"| &&
            |     title="Click to view freight conditions breakdown for this item">+&#8377;{ lv_fmt_q_frt } Delivery{ lv_det_txt } &#128269;</a>| &&
            |</div>|.
        ELSE.
          lv_q_frt_html =
            '<div style="font-size: 10px; color: #94a3b8; font-style: italic; margin-top: 2px;"' &&
            ' title="Delivery cost not maintained">Delivery: &#8212;</div>'.
        ENDIF.

        lv_html = lv_html &&
          |<td{ lv_td_cls }>| &&
          '  <div style="display: flex; justify-content: space-between; align-items: baseline; gap: 4px;">' &&
          |    <span class="quote-amt">&#8377;{ lv_fmt_tot }</span>| &&
          |    { lv_rank_pill }| &&
          '  </div>' &&
          |  <div class="quote-unit">Rate: &#8377;{ lv_fmt_upr } / { ls_item-meins }</div>| &&
          lv_q_frt_html &&
          |  <div style="margin-top: 4px;">{ lv_pill_action }</div>| &&
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

    " Dedicated Column 1: System Suggested (L1)
    DATA: lv_fmt_l1_upr  TYPE string,
          lv_fmt_l1_frt  TYPE string,
          lv_l1_frt_html TYPE string.
    CLEAR: lv_l1_frt_html, lv_fmt_l1_frt.
    IF ls_item-l1_upr_amt > 0.
      PERFORM format_inr USING ls_item-l1_upr_amt CHANGING lv_fmt_l1_upr.
    ELSE.
      lv_fmt_l1_upr = '—'.
    ENDIF.
    IF ls_item-l1_freight > 0.
      PERFORM format_inr USING ls_item-l1_freight CHANGING lv_fmt_l1_frt.
      DATA(lv_l1_det) = COND string( WHEN ls_item-l1_frt_details IS NOT INITIAL THEN | ({ ls_item-l1_frt_details })| ELSE '' ).
      lv_l1_frt_html =
        |<div style="font-size: 10px; color: #047857; font-weight: 600;">| &&
        |  <a href="sapevent:SHOW_ITEM_FREIGHT?item={ ls_item-ebelp }" style="color: #047857; text-decoration: none;"| &&
        |     title="Click to view freight conditions breakdown">+&#8377;{ lv_fmt_l1_frt } Delivery{ lv_l1_det } &#128269;</a>| &&
        |</div>|.
    ELSE.
      lv_l1_frt_html = '<div style="font-size: 10px; color: #94a3b8; font-style: italic;">Delivery: &#8212;</div>'.
    ENDIF.

    lv_html = lv_html &&
      '<td style="background: #f0fdf4; border-left: 2px solid #10b981;">' &&
      |  <div style="font-weight: 700; font-size: 12px; color: #065f46;">{ ls_item-l1_name1 }</div>| &&
      |  <div style="font-size: 10px; color: #047857;">RFQ #{ ls_item-l1_ebeln }</div>| &&
      '  <div style="display: flex; justify-content: space-between; align-items: baseline; margin-top: 2px;">' &&
      |    <span style="font-weight: 700; font-size: 12px; color: #15803d;">&#8377;{ lv_fmt_min }</span>| &&
      '    <span class="rank-lowest">L1 · Lowest</span>' &&
      '  </div>' &&
      |  <div class="quote-unit">Rate: &#8377;{ lv_fmt_l1_upr } / { ls_item-meins }</div>| &&
      lv_l1_frt_html &&
      '</td>'.

    " Dedicated Column 2: User Suggested (Selected)
    IF ls_item-sel_lifnr IS NOT INITIAL.
      DATA: lv_fmt_s_tot  TYPE string,
            lv_fmt_s_upr  TYPE string,
            lv_fmt_s_frt  TYPE string,
            lv_var_badge  TYPE string,
            lv_s_frt_html TYPE string.
      CLEAR: lv_s_frt_html, lv_fmt_s_frt.
      PERFORM format_inr USING ls_item-sel_tot_amt CHANGING lv_fmt_s_tot.
      PERFORM format_inr USING ls_item-sel_upr_amt CHANGING lv_fmt_s_upr.
      IF ls_item-sel_freight > 0.
        PERFORM format_inr USING ls_item-sel_freight CHANGING lv_fmt_s_frt.
        DATA(lv_s_det) = COND string( WHEN ls_item-sel_frt_details IS NOT INITIAL THEN | ({ ls_item-sel_frt_details })| ELSE '' ).
        lv_s_frt_html =
          |<div style="font-size: 10px; color: #1e40af; font-weight: 600;">| &&
          |  <a href="sapevent:SHOW_ITEM_FREIGHT?item={ ls_item-ebelp }" style="color: #1e40af; text-decoration: none;"| &&
          |     title="Click to view freight conditions breakdown">+&#8377;{ lv_fmt_s_frt } Delivery{ lv_s_det } &#128269;</a>| &&
          |</div>|.
      ELSE.
        lv_s_frt_html = '<div style="font-size: 10px; color: #94a3b8; font-style: italic;">Delivery: &#8212;</div>'.
      ENDIF.

      IF ls_item-sel_lifnr = ls_item-l1_lifnr.
        lv_var_badge =
          '<span class="rank-lowest" style="background:#dcfce7;color:#15803d;border:1px solid #86efac;">&#10003; Matches L1</span>'.
      ELSE.
        DATA(lv_d_amt) = ls_item-sel_tot_amt - ls_item-l1_tot_amt.
        DATA: lv_fmt_d_amt TYPE string.
        PERFORM format_inr USING lv_d_amt CHANGING lv_fmt_d_amt.
        lv_var_badge =
          '<span class="rank-other" style="background:#fef3c7;color:#92400e;border:1px solid #fcd34d;">' &&
          |&#9650; Higher +&#8377;{ lv_fmt_d_amt }</span>|.
      ENDIF.

      DATA: lv_item_appr_html TYPE string,
            lv_cell_bg        TYPE string,
            lv_remark_html    TYPE string.

      CLEAR lv_remark_html.
      IF ls_item-sel_lifnr <> ls_item-l1_lifnr.
        IF ls_item-user_remark IS NOT INITIAL.
          lv_remark_html =
            '<div style="margin-top:3px;padding:3px 6px;background:#fef3c7;' &&
            'border:1px solid #f59e0b;border-radius:3px;font-size:10px;line-height:1.2;">' &&
            '  <div style="font-weight:700;color:#92400e;">User Justification:</div>' &&
            |  <div style="color:#78350f;word-break:break-word;">{ ls_item-user_remark }</div>| &&
            COND string(
              WHEN gv_is_approver = abap_false AND ls_item-po_number IS INITIAL
                   AND ls_item-appr_status IS INITIAL AND ls_item-user_pref IS INITIAL THEN
                |  <a href="sapevent:EDIT_REMARK?item={ ls_item-ebelp }"| &&
                ' style="font-size:9px;color:#2563eb;text-decoration:underline;">[Edit Reason]</a>'
              ELSE ''
            ) &&
            '</div>'.
        ELSE.
          lv_remark_html =
            '<div style="margin-top:3px;padding:3px 6px;background:#fee2e2;' &&
            'border:1px solid #ef4444;border-radius:3px;font-size:10px;line-height:1.2;">' &&
            '  <span style="color:#b91c1c;font-weight:700;">&#9888; Reason Required</span>' &&
            COND string(
              WHEN gv_is_approver = abap_false
                   AND ls_item-appr_status IS INITIAL AND ls_item-user_pref IS INITIAL THEN
                |  <a href="sapevent:EDIT_REMARK?item={ ls_item-ebelp }" class="btn-refresh"| &&
                ' style="font-size:9px;padding:1px 4px;margin-left:4px;">&#9998; Enter Reason</a>'
              ELSE
                '  <span style="color:#b91c1c;font-size:9px;">(No reason entered)</span>'
            ) &&
            '</div>'.
        ENDIF.
      ENDIF.

      " Rejection Remark Box (Prominently displayed in Red)
      DATA: lv_appr_rem_html TYPE string.
      CLEAR lv_appr_rem_html.
      IF ls_item-appr_remark IS NOT INITIAL OR ls_item-appr_status = 'R'.
        DATA(lv_disp_aremark) = ls_item-appr_remark.
        IF lv_disp_aremark IS INITIAL.
          lv_disp_aremark = 'Comparison rejected by Approver.'.
        ENDIF.
        lv_appr_rem_html =
          '<div style="margin-top:3px;padding:4px 6px;background:#fef2f2;' &&
          'border:1px solid #f87171;border-radius:3px;font-size:10px;line-height:1.2;">' &&
          '  <div style="font-weight:700;color:#991b1b;display:flex;align-items:center;gap:3px;">' &&
          |    <span>&#10007; Rejection Reason ({ gv_hod_name }):</span>| &&
          '  </div>' &&
          |  <div style="color:#7f1d1d;font-style:italic;margin-top:2px;word-break:break-word;">"{ lv_disp_aremark }"</div>| &&
          '</div>'.
      ENDIF.

      IF ls_item-appr_status = 'X'.
        " Approved with Green Background!
        lv_cell_bg = 'background: #f0fdf4; border-left: 3px solid #16a34a;'.
        IF ls_item-po_number IS NOT INITIAL.
          lv_item_appr_html =
            '<div style="display:flex;align-items:center;gap:6px;margin-top:4px;">' &&
            '  <span style="background:#16a34a;color:#ffffff;padding:2px 8px;border-radius:3px;font-weight:700;font-size:10px;">' &&
            '    &#10003; Approved' &&
            '  </span>' &&
            |  <a href="sapevent:ME23N?ebeln={ ls_item-po_number }" class="btn-po-link">&#10003; PO { ls_item-po_number }</a>| &&
            '</div>'.
        ELSE.
          IF gv_is_approver = abap_true.
            lv_item_appr_html =
              '<div style="display:flex;align-items:center;gap:6px;margin-top:4px;flex-wrap:wrap;">' &&
              '  <span style="background:#16a34a;color:#ffffff;padding:2px 8px;border-radius:3px;font-weight:700;font-size:10px;">' &&
              '    &#10003; Approved' &&
              '  </span>' &&
              '  <span style="font-size:10px;color:#15803d;font-weight:600;">(Sent to Creator for PO)</span>' &&
              |  <a href="sapevent:REJECT_ITEM?item={ ls_item-ebelp }" class="btn-reject"| &&
              ' style="font-size:10px;padding:2px 6px;" title="Reject this item with compulsory remark">&#10007; Reject</a>' &&
              '</div>'.
          ELSE.
            lv_item_appr_html =
              '<div style="display:flex;align-items:center;gap:6px;margin-top:4px;flex-wrap:wrap;">' &&
              '  <span style="background:#16a34a;color:#ffffff;padding:2px 8px;border-radius:3px;font-weight:700;font-size:10px;">' &&
              '    &#10003; Approved' &&
              '  </span>' &&
              |  <a href="sapevent:CREATE_PO_SINGLE?item={ ls_item-ebelp }"| &&
              ' class="btn-po" style="font-size:10px;padding:2px 8px;" title="Create PO">&#128722; Create PO</a>' &&
              '</div>'.
          ENDIF.
        ENDIF.

      ELSEIF ls_item-appr_status = 'R'.
        lv_cell_bg = 'background: #fef2f2; border-left: 3px solid #dc2626;'.
        lv_item_appr_html =
          '<div style="display:flex;align-items:center;gap:6px;margin-top:4px;flex-wrap:wrap;">' &&
          '  <span style="background:#dc2626;color:#ffffff;padding:2px 8px;border-radius:3px;font-weight:700;font-size:10px;">' &&
          '    &#10007; Rejected' &&
          '  </span>' &&
          COND string(
            WHEN gv_is_approver = abap_true THEN
              |  <a href="sapevent:APPROVE_ITEM?item={ ls_item-ebelp }" class="btn-pill-sel"| &&
              ' style="font-size:10px;padding:2px 6px;background:#059669;color:#fff;"' &&
              ' title="Approve this item">&#10003; Approve</a>'
            ELSE
              |  <a href="sapevent:ME47?ebeln={ ls_item-sel_ebeln }" class="btn-refresh"| &&
              ' style="font-size:10px;padding:2px 6px;" title="Maintain dates/prices in ME47">&#9998; Edit ME47</a>' &&
              |  <a href="sapevent:SUBMIT_SINGLE?item={ ls_item-ebelp }" class="btn-pill-sel"| &&
              ' style="font-size:10px;padding:2px 6px;background:#f59e0b;color:#fff;"' &&
              ' title="Resend this item to HOD for approval">&#128228; Resend for Approval</a>'
          ) &&
          '</div>'.
        IF ls_item-appr_remark IS NOT INITIAL.
          lv_item_appr_html = lv_item_appr_html &&
            |<div style="font-size:10px;color:#991b1b;margin-top:3px;line-height:1.2;">| &&
            |  <strong>Rejection Remark:</strong> { ls_item-appr_remark }| &&
            |</div>|.
        ENDIF.

      ELSEIF ls_item-sel_lifnr IS NOT INITIAL.
        lv_cell_bg = 'background: #fffbeb; border-left: 3px solid #f59e0b;'.
        IF gv_is_approver = abap_true.
          lv_item_appr_html =
            '<div style="display:flex;align-items:center;gap:4px;margin-top:4px;flex-wrap:wrap;">' &&
            '  <span style="background:#f59e0b;color:#ffffff;padding:2px 8px;border-radius:3px;font-weight:700;font-size:10px;">' &&
            '    &#9203; Pending Approval' &&
            '  </span>' &&
            |  <a href="sapevent:APPROVE_ITEM?item={ ls_item-ebelp }"| &&
            ' class="btn-pill-sel" style="font-size:10px;padding:2px 6px;background:#059669;color:#fff;"' &&
            ' title="Approve this item">&#10003; Approve</a>' &&
            |  <a href="sapevent:REJECT_ITEM?item={ ls_item-ebelp }"| &&
            ' class="btn-reject" style="font-size:10px;padding:2px 6px;"' &&
            ' title="Reject this item with compulsory remark">&#10007; Reject</a>' &&
            '</div>'.
        ELSE.
          IF ls_item-user_pref = 'X'.
            lv_item_appr_html =
              '<div style="display:flex;align-items:center;gap:4px;margin-top:4px;">' &&
              '  <span style="background:#f59e0b;color:#ffffff;padding:2px 8px;border-radius:3px;font-weight:700;font-size:10px;">' &&
              |    &#9203; Pending HOD ({ gv_hod_user })| &&
              '  </span>' &&
              '</div>'.
          ELSE.
            lv_item_appr_html =
              '<div style="display:flex;align-items:center;gap:6px;margin-top:4px;">' &&
              '  <span style="background:#64748b;color:#ffffff;padding:2px 8px;border-radius:3px;font-weight:600;font-size:10px;">' &&
              '    Draft' &&
              '  </span>' &&
              |  <a href="sapevent:SUBMIT_SINGLE?item={ ls_item-ebelp }" class="btn-pill-sel"| &&
              ' style="font-size:10px;padding:2px 6px;background:#f59e0b;color:#fff;"' &&
              ' title="Send this item for approval">&#128228; Submit</a>' &&
              '</div>'.
          ENDIF.
        ENDIF.

      ELSE.
        lv_cell_bg = 'background: #eff6ff; border-left: 2px solid #3b82f6;'.
        lv_item_appr_html =
          '<div style="display:flex;align-items:center;gap:6px;margin-top:4px;">' &&
          '  <span style="background:#64748b;color:#ffffff;padding:2px 8px;border-radius:3px;font-weight:600;font-size:10px;">' &&
          '    Draft' &&
          '  </span>' &&
          '</div>'.
      ENDIF.

      lv_html = lv_html &&
        |<td style="{ lv_cell_bg }">| &&
        |  <div style="font-weight: 700; font-size: 12px; color: #1e40af;">{ ls_item-sel_name1 }</div>| &&
        |  <div style="font-size: 10px; color: #2563eb;">RFQ #{ ls_item-sel_ebeln }</div>| &&
        '  <div style="display: flex; justify-content: space-between; align-items: baseline; margin-top: 2px;">' &&
        |    <span style="font-weight: 700; font-size: 12px; color: #0f172a;">&#8377;{ lv_fmt_s_tot }</span>| &&
        |    { lv_var_badge }| &&
        '  </div>' &&
        |  <div class="quote-unit">Rate: &#8377;{ lv_fmt_s_upr } / { ls_item-meins }</div>| &&
        lv_s_frt_html &&
        lv_remark_html &&
        lv_appr_rem_html &&
        lv_item_appr_html &&
        '</td>'.
    ELSE.
      lv_html = lv_html &&
        '<td style="background: #f8fafc; border-left: 2px solid #cbd5e1; text-align: center;">' &&
        '  <div style="color: #94a3b8; font-style: italic; padding: 6px;">Not Selected</div>' &&
        '</td>'.
    ENDIF.

    lv_html = lv_html && '</tr>'.

  ENDLOOP.

  lv_html = lv_html && '</tbody>'.

  " Total Rows
  READ TABLE gt_final INTO DATA(ls_mat_tot) WITH KEY maktx = 'Total Item Amount' ##READ_WHERE_OK.
  READ TABLE gt_final INTO DATA(ls_frt_tot) WITH KEY maktx = 'Total Delivery Cost' ##READ_WHERE_OK.
  READ TABLE gt_final INTO DATA(ls_tot) WITH KEY maktx = 'Total Quotation Amount' ##READ_WHERE_OK.

  DATA: lv_l1_grand       TYPE decfloat34 VALUE 0,
        lv_l1_mat_tot     TYPE decfloat34 VALUE 0,
        lv_l1_frt_tot     TYPE decfloat34 VALUE 0,
        lv_fmt_l1_grand   TYPE string,
        lv_fmt_l1_mat     TYPE string,
        lv_fmt_l1_frt_tot TYPE string.
  LOOP AT gt_item_ref INTO DATA(ls_ir_g).
    lv_l1_mat_tot = lv_l1_mat_tot + ls_ir_g-l1_tot_amt.
    lv_l1_frt_tot = lv_l1_frt_tot + ls_ir_g-l1_freight.
    lv_l1_grand   = lv_l1_grand + ( ls_ir_g-l1_tot_amt + ls_ir_g-l1_freight ).
  ENDLOOP.
  IF lv_l1_grand > 0.
    PERFORM format_inr USING lv_l1_grand CHANGING lv_fmt_l1_grand.
    PERFORM format_inr USING lv_l1_mat_tot CHANGING lv_fmt_l1_mat.
    PERFORM format_inr USING lv_l1_frt_tot CHANGING lv_fmt_l1_frt_tot.
  ELSE.
    lv_fmt_l1_grand   = '—'.
    lv_fmt_l1_mat     = '—'.
    lv_fmt_l1_frt_tot = '—'.
  ENDIF.

  lv_html = lv_html && '<tfoot>'.

  " 1. Total Item Amount Row (Excl. Delivery)
  lv_html = lv_html &&
    '<tr style="background: #f8fafc;">' &&
    '  <td colspan="6" class="tot-label" style="font-weight: 600; color: #475569;">Total Item Amount (Excl. Delivery)</td>'.

  LOOP AT gt_hdr INTO wa_hdr.
    DATA(lv_midx) = sy-tabix.
    DATA: lv_vmat_raw TYPE string,
          lv_fmt_vmat TYPE string.
    CASE lv_midx.
      WHEN 1. lv_vmat_raw = ls_mat_tot-quat1.
      WHEN 2. lv_vmat_raw = ls_mat_tot-quat2.
      WHEN 3. lv_vmat_raw = ls_mat_tot-quat3.
      WHEN 4. lv_vmat_raw = ls_mat_tot-quat4.
      WHEN 5. lv_vmat_raw = ls_mat_tot-quat5.
      WHEN 6. lv_vmat_raw = ls_mat_tot-quat6.
      WHEN 7. lv_vmat_raw = ls_mat_tot-quat7.
    ENDCASE.
    PERFORM format_inr USING lv_vmat_raw CHANGING lv_fmt_vmat.
    IF lv_fmt_vmat = 'No Price'.
      lv_html = lv_html && |<td class="tot-amt" style="color: #dc2626; font-weight: 600;">{ lv_fmt_vmat }</td>|.
    ELSE.
      lv_html = lv_html && |<td class="tot-amt" style="color: #334155; font-weight: 600;">&#8377;{ lv_fmt_vmat }</td>|.
    ENDIF.
  ENDLOOP.

  lv_html = lv_html &&
    |  <td class="tot-min" style="border-left: 2px solid #10b981; font-weight: 600; color: #047857;">&#8377;{ lv_fmt_l1_mat }</td>| &&
    |  <td class="tot-amt" style="border-left: 2px solid #3b82f6; color: #1e40af; font-weight: 600;">&#8377;{ lv_fmt_sel_mat }</td>| &&
    '</tr>'.

  " 2. Total Delivery Cost Row (Individual row down side!)
  lv_html = lv_html &&
    '<tr style="background: #fffbeb;">' &&
    '  <td colspan="6" class="tot-label" style="font-weight: 700; color: #b45309;">' &&
    '    Total Delivery Cost / Freight' &&
    '    <a href="sapevent:SHOW_FREIGHT" style="margin-left: 8px; font-size: 10px; font-weight: 600; color: #b45309; text-decoration: underline;"' &&
    '       title="Click to view quotation & item-wise breakdown of all freight conditions">&#128269; View All Breakdown</a>' &&
    '  </td>'.

  LOOP AT gt_hdr INTO wa_hdr.
    DATA(lv_fidx) = sy-tabix.
    DATA: lv_vfrt_raw TYPE string,
          lv_fmt_vfrt TYPE string.
    CASE lv_fidx.
      WHEN 1. lv_vfrt_raw = ls_frt_tot-quat1.
      WHEN 2. lv_vfrt_raw = ls_frt_tot-quat2.
      WHEN 3. lv_vfrt_raw = ls_frt_tot-quat3.
      WHEN 4. lv_vfrt_raw = ls_frt_tot-quat4.
      WHEN 5. lv_vfrt_raw = ls_frt_tot-quat5.
      WHEN 6. lv_vfrt_raw = ls_frt_tot-quat6.
      WHEN 7. lv_vfrt_raw = ls_frt_tot-quat7.
    ENDCASE.
    PERFORM format_inr USING lv_vfrt_raw CHANGING lv_fmt_vfrt.
    IF lv_fmt_vfrt = 'No Price'.
      lv_html = lv_html && |<td class="tot-amt" style="color: #dc2626;">{ lv_fmt_vfrt }</td>|.
    ELSEIF lv_vfrt_raw IS NOT INITIAL AND CONV decfloat34( lv_vfrt_raw ) > 0.
      lv_html = lv_html && |<td class="tot-amt" style="color: #b45309; font-weight: 700;">+&#8377;{ lv_fmt_vfrt }</td>|.
    ELSE.
      lv_html = lv_html && |<td class="tot-amt" style="color: #94a3b8; font-weight: 500;">&#8377;0.00</td>|.
    ENDIF.
  ENDLOOP.

  DATA: lv_l1_frt_disp  TYPE string,
        lv_sel_frt_disp TYPE string.
  IF lv_l1_frt_tot > 0.
    lv_l1_frt_disp = |+&#8377;{ lv_fmt_l1_frt_tot }|.
  ELSE.
    lv_l1_frt_disp = '&#8377;0.00'.
  ENDIF.
  IF lv_selected_frt_tot > 0.
    lv_sel_frt_disp = |+&#8377;{ lv_fmt_sel_frt }|.
  ELSE.
    lv_sel_frt_disp = '&#8377;0.00'.
  ENDIF.

  lv_html = lv_html &&
    |  <td class="tot-min" style="border-left: 2px solid #10b981; font-weight: 700; color: #047857;">{ lv_l1_frt_disp }</td>| &&
    |  <td class="tot-amt" style="border-left: 2px solid #3b82f6; color: #1e40af; font-weight: 700;">{ lv_sel_frt_disp }</td>| &&
    '</tr>'.

  " 3. Total Quotation Amount Row (Landed Grand Total)
  lv_html = lv_html &&
    '<tr style="background: #f1f5f9; border-top: 2px solid #64748b; border-bottom: 2px solid #64748b;">' &&
    '  <td colspan="6" class="tot-label" style="font-size: 12px; font-weight: 800; color: #0f172a;">Total Quotation Amount</td>'.

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
      lv_html = lv_html && |<td class="tot-amt" style="color: #dc2626; font-weight: 800; font-size: 13px;">{ lv_fmt_vtot }</td>|.
    ELSE.
      lv_html = lv_html && |<td class="tot-amt" style="font-weight: 800; font-size: 13px; color: #0f172a;">&#8377;{ lv_fmt_vtot }</td>|.
    ENDIF.
  ENDLOOP.

  lv_html = lv_html &&
    |  <td class="tot-min" style="border-left: 2px solid #10b981; font-weight: 800; font-size: 13px; color: #15803d;">&#8377;{ lv_fmt_l1_grand }</td>| &&
    |  <td class="tot-amt" style="border-left: 2px solid #3b82f6; font-weight: 800; font-size: 13px; color: #2563eb;">&#8377;{ lv_fmt_sel_tot }</td>| &&
    '</tr>'.

  " Commercial Evaluation & Financing Section (Unified in single table)
  lv_html = lv_html &&
    '<tr class="comm-sec-hdr">' &&
    |  <td colspan="6">Commercial Evaluation & Financing Analysis ({ p_rate DECIMALS = 2 }% Interest Rate)</td>|.

  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html &&
      |<td><strong>{ wa_hdr-name1 }</strong><br><small style="font-weight: 500; color: #475569;">RFQ #{ wa_hdr-ebeln }</small></td>|.
  ENDLOOP.

  lv_html = lv_html &&
    '  <td style="text-align: right; background: #ecfdf5; color: #065f46;">Lowest Landed</td>' &&
    '  <td style="text-align: center; color: #94a3b8;">—</td>' &&
    '</tr>'.

  " Incoterms
  lv_html = lv_html && '<tr><td colspan="6" class="comm-param-label">Incoterms</td>'.
  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html && |<td class="comm-param-val">{ wa_hdr-inco1 }</td>|.
  ENDLOOP.
  lv_html = lv_html &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '</tr>'.

  " Payment Terms
  lv_html = lv_html && '<tr><td colspan="6" class="comm-param-label">Payment Terms</td>'.
  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html && |<td class="comm-param-val">{ wa_hdr-text1 }</td>|.
  ENDLOOP.
  lv_html = lv_html &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '</tr>'.

  " Credit Days
  lv_html = lv_html && '<tr><td colspan="6" class="comm-param-label">Credit Days</td>'.
  LOOP AT gt_hdr INTO wa_hdr.
    lv_html = lv_html && |<td class="comm-param-val">{ wa_hdr-ztag1 } Days</td>|.
  ENDLOOP.
  lv_html = lv_html &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '</tr>'.

  " Financing / Interest Cost
  READ TABLE gt_final INTO DATA(ls_intr) WITH KEY maktx = 'Interest Amount' ##READ_WHERE_OK.
  lv_html = lv_html &&
    '<tr class="comm-row-hl">' &&
    |  <td colspan="6" class="comm-param-label" style="font-weight: 700; color: #854d0e;">| &&
    |Financing / Interest Cost ({ p_rate DECIMALS = 2 }%)</td>|.

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
      lv_html = lv_html && |<td class="comm-param-val" style="color: #dc2626;">{ lv_fmt_intr }</td>|.
    ELSE.
      lv_html = lv_html && |<td class="comm-param-val" style="text-align: right; font-weight: 600;">&#8377;{ lv_fmt_intr }</td>|.
    ENDIF.
  ENDLOOP.
  lv_html = lv_html &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '</tr>'.

  " Net Landed Commercial Evaluation
  DATA: lv_min_land     TYPE decfloat34 VALUE 0,
        lv_fmt_min_land TYPE string,
        lt_flnd         TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
  CLEAR lt_flnd.

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
      IF lv_land > 0 AND ( lv_min_land = 0 OR lv_land < lv_min_land ).
        lv_min_land = lv_land.
      ENDIF.
      PERFORM format_inr USING lv_land CHANGING lv_flnd.
    ENDIF.
    APPEND lv_flnd TO lt_flnd.
  ENDLOOP.

  IF lv_min_land > 0.
    PERFORM format_inr USING lv_min_land CHANGING lv_fmt_min_land.
  ELSE.
    lv_fmt_min_land = '—'.
  ENDIF.

  lv_html = lv_html &&
    '<tr class="comm-row-eval">' &&
    '  <td colspan="6" class="comm-param-label" style="font-weight: 800; font-size: 12px; color: #166534;">' &&
    '    Net Commercial Landed Evaluation' &&
    '  </td>'.

  LOOP AT lt_flnd INTO lv_flnd.
    IF lv_flnd = 'No Price'.
      lv_html = lv_html && |<td class="comm-param-val" style="color: #dc2626;"><strong>{ lv_flnd }</strong></td>|.
    ELSE.
      lv_html = lv_html && |<td class="comm-param-val" style="text-align: right;"><strong>&#8377;{ lv_flnd }</strong></td>|.
    ENDIF.
  ENDLOOP.

  lv_html = lv_html &&
    |  <td class="comm-param-val" style="text-align: right; font-weight: 800; color: #166534;">&#8377;{ lv_fmt_min_land }</td>| &&
    '  <td class="comm-param-val" style="text-align: center; color: #94a3b8;">—</td>' &&
    '</tr>' &&
    '</tfoot></table></div>'.

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
FORM handle_html_action USING pv_action  TYPE any
                              pv_getdata TYPE any.

  DATA: lv_action   TYPE string,
        lv_data     TYPE string,
        lv_item_str TYPE string,
        lv_ebelp    TYPE ekpo-ebelp,
        lv_col      TYPE slis_fieldname.

  lv_action = pv_action.
  lv_data   = pv_getdata.

  CASE lv_action.

    WHEN 'SHOW_FREIGHT'.
      PERFORM show_item_freight_details USING space space.
      RETURN.

    WHEN 'SHOW_ITEM_FREIGHT'.
      CLEAR: lv_item_str, lv_ebelp.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      lv_ebelp = lv_item_str.
      PERFORM show_item_freight_details USING lv_ebelp space.
      RETURN.

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
        LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_ir_off>)
          WHERE po_number IS INITIAL AND appr_status <> 'X' AND user_pref <> 'X'.
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
      IF sy-subrc = 0 AND gv_is_approver = abap_false.
        IF <fs_ref_tr>-appr_status = 'X'.
          MESSAGE |Item { lv_ebelp } is approved. Selection locked; only Create PO is allowed.| TYPE 'W'.
          RETURN.
        ENDIF.
        IF <fs_ref_tr>-user_pref = 'X' AND <fs_ref_tr>-appr_status <> 'R'.
          MESSAGE |Item { lv_ebelp } is in approval process. Selection locked.| TYPE 'W'.
          RETURN.
        ENDIF.
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
      IF sy-subrc = 0 AND gv_is_approver = abap_false.
        IF <fs_ref_sel>-appr_status = 'X'.
          MESSAGE |Item { lv_ebelp } is approved. Supplier change locked; only Create PO is allowed.| TYPE 'W'.
          RETURN.
        ENDIF.
        IF <fs_ref_sel>-user_pref = 'X' AND <fs_ref_sel>-appr_status <> 'R'.
          MESSAGE |Item { lv_ebelp } is in approval process. Supplier change locked.| TYPE 'W'.
          RETURN.
        ENDIF.
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
      IF sy-subrc = 0 AND gv_is_approver = abap_false.
        IF <fs_ref_des>-appr_status = 'X'.
          MESSAGE |Item { lv_ebelp } is approved. Modifications locked; only Create PO is allowed.| TYPE 'W'.
          RETURN.
        ENDIF.
        IF <fs_ref_des>-user_pref = 'X' AND <fs_ref_des>-appr_status <> 'R'.
          MESSAGE |Item { lv_ebelp } is in approval process. Modifications locked.| TYPE 'W'.
          RETURN.
        ENDIF.
      ENDIF.
      IF lv_ebelp IS NOT INITIAL.
        PERFORM deselect_item USING lv_ebelp.
        PERFORM render_html.
      ENDIF.

    WHEN 'SUBMIT_APPROVAL'.
      DATA: lv_any_sel_appr TYPE abap_bool VALUE abap_false.
      LOOP AT gt_item_ref INTO DATA(ls_sir) WHERE po_number IS INITIAL.
        IF ls_sir-sel_lifnr IS NOT INITIAL.
          lv_any_sel_appr = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_any_sel_appr = abap_false.
        MESSAGE 'Please select supplier for at least one item before submitting for HOD approval.' TYPE 'I'.
        RETURN.
      ENDIF.

      " Validate mandatory remarks for Non-L1 selections!
      DATA: lv_sub_cancel TYPE abap_bool VALUE abap_false.
      LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_chk_ir>) WHERE po_number IS INITIAL.
        IF <fs_chk_ir>-sel_lifnr IS NOT INITIAL AND <fs_chk_ir>-sel_lifnr <> <fs_chk_ir>-l1_lifnr.
          IF <fs_chk_ir>-user_remark IS INITIAL.
            PERFORM prompt_user_remark USING <fs_chk_ir>-ebelp
                                     CHANGING <fs_chk_ir>-user_remark
                                              lv_sub_cancel.
            IF lv_sub_cancel = abap_true OR <fs_chk_ir>-user_remark IS INITIAL.
              MESSAGE |Justification remark is compulsory for Non-L1 selection on Item { <fs_chk_ir>-ebelp }.| TYPE 'E'.
              RETURN.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDLOOP.

      DATA: lv_submitted_cnt TYPE i VALUE 0.
      LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_sub_ir>) WHERE po_number IS INITIAL.
        IF <fs_sub_ir>-sel_lifnr IS NOT INITIAL.
          DATA: lv_cur_np TYPE ekpo-netpr,
                lv_cur_pe TYPE ekpo-peinh.
          SELECT SINGLE netpr, peinh FROM ekpo
            WHERE ebeln = @<fs_sub_ir>-sel_ebeln AND ebelp = @<fs_sub_ir>-sel_ebelp
            INTO ( @lv_cur_np, @lv_cur_pe ).
          IF sy-subrc = 0 AND lv_cur_np > 0.
            <fs_sub_ir>-sel_netpr = lv_cur_np.
            <fs_sub_ir>-sel_peinh = COND #( WHEN lv_cur_pe > 0 THEN lv_cur_pe ELSE 1 ).
            DATA(lv_sub_q) = COND ekpo-menge( WHEN <fs_sub_ir>-menge > 0 THEN <fs_sub_ir>-menge ELSE 1 ).
            <fs_sub_ir>-sel_upr_amt = CONV decfloat34( <fs_sub_ir>-sel_netpr ) / CONV decfloat34( <fs_sub_ir>-sel_peinh ).
            <fs_sub_ir>-sel_tot_amt = CONV decfloat34( lv_sub_q ) * <fs_sub_ir>-sel_upr_amt.
          ENDIF.

          UPDATE zmm_t_021
            SET userpref = ' ', zapprover1 = ' '
            WHERE zcollectno = @<fs_sub_ir>-submi
              AND zqitem     = @<fs_sub_ir>-ebelp
              AND zquotation <> @<fs_sub_ir>-sel_ebeln.

          DATA: ls_db21 TYPE zmm_t_021.
          CLEAR ls_db21.
          SELECT SINGLE * FROM zmm_t_021
            INTO @ls_db21
            WHERE zquotation = @<fs_sub_ir>-sel_ebeln
              AND zqitem     = @<fs_sub_ir>-sel_ebelp.
          IF sy-subrc = 0.
            ls_db21-userpref   = 'X'.
            ls_db21-zapprover1 = space.
            ls_db21-zaremark   = space.
            ls_db21-zuser      = sy-uname.
            ls_db21-znetpr     = <fs_sub_ir>-sel_netpr.
            ls_db21-zremark    = <fs_sub_ir>-user_remark.
            MODIFY zmm_t_021 FROM ls_db21.
          ELSE.
            ls_db21-mandt      = sy-mandt.
            ls_db21-zquotation = <fs_sub_ir>-sel_ebeln.
            ls_db21-zqitem     = <fs_sub_ir>-sel_ebelp.
            ls_db21-zdshcount  = '0001'.
            ls_db21-zcollectno = <fs_sub_ir>-submi.
            ls_db21-zsupplier  = <fs_sub_ir>-sel_lifnr.
            ls_db21-zsupname   = <fs_sub_ir>-sel_name1.
            ls_db21-zmat       = <fs_sub_ir>-matnr.
            ls_db21-zdesc      = <fs_sub_ir>-txz01.
            ls_db21-zqty       = <fs_sub_ir>-menge.
            ls_db21-zuom       = <fs_sub_ir>-meins.
            ls_db21-znetpr     = <fs_sub_ir>-sel_netpr.
            ls_db21-userpref   = 'X'.
            ls_db21-zapprover1 = space.
            ls_db21-zaremark   = space.
            ls_db21-zuser      = sy-uname.
            ls_db21-zremark    = <fs_sub_ir>-user_remark.
            MODIFY zmm_t_021 FROM ls_db21.
          ENDIF.
          <fs_sub_ir>-user_pref   = 'X'.
          <fs_sub_ir>-appr_status = space.
          <fs_sub_ir>-appr_remark = space.
          lv_submitted_cnt = lv_submitted_cnt + 1.
        ENDIF.
      ENDLOOP.
      COMMIT WORK.

      " Dispatch Notification and Email to Approver
      PERFORM send_approval_notification USING gv_submi.

      PERFORM init_approval_status.
      MESSAGE |Quotation comparison ({ lv_submitted_cnt } items) submitted to HOD ({ gv_hod_name }). Notification sent.| TYPE 'S'.
      PERFORM render_html.

    WHEN 'SUBMIT_SINGLE'.
      CLEAR: lv_item_str, lv_ebelp.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      lv_ebelp = lv_item_str.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_sgl_ir>) WITH KEY ebelp = lv_ebelp.
      IF sy-subrc = 0 AND <fs_sgl_ir>-sel_lifnr IS NOT INITIAL.
        IF <fs_sgl_ir>-po_number IS NOT INITIAL.
          MESSAGE |PO { <fs_sgl_ir>-po_number } already created for Item { lv_ebelp }.| TYPE 'W'.
          RETURN.
        ENDIF.

        IF <fs_sgl_ir>-sel_lifnr <> <fs_sgl_ir>-l1_lifnr AND <fs_sgl_ir>-user_remark IS INITIAL.
          DATA: lv_sgl_cancel TYPE abap_bool.
          PERFORM prompt_user_remark USING <fs_sgl_ir>-ebelp
                                   CHANGING <fs_sgl_ir>-user_remark
                                            lv_sgl_cancel.
          IF lv_sgl_cancel = abap_true OR <fs_sgl_ir>-user_remark IS INITIAL.
            MESSAGE |Justification remark is compulsory for Non-L1 selection on Item { lv_ebelp }.| TYPE 'E'.
            RETURN.
          ENDIF.
        ENDIF.

        DATA: lv_cur_np_s TYPE ekpo-netpr,
              lv_cur_pe_s TYPE ekpo-peinh.
        SELECT SINGLE netpr, peinh FROM ekpo
          WHERE ebeln = @<fs_sgl_ir>-sel_ebeln AND ebelp = @<fs_sgl_ir>-sel_ebelp
          INTO ( @lv_cur_np_s, @lv_cur_pe_s ).
        IF sy-subrc = 0 AND lv_cur_np_s > 0.
          <fs_sgl_ir>-sel_netpr = lv_cur_np_s.
          <fs_sgl_ir>-sel_peinh = COND #( WHEN lv_cur_pe_s > 0 THEN lv_cur_pe_s ELSE 1 ).
          DATA(lv_sgl_q) = COND ekpo-menge( WHEN <fs_sgl_ir>-menge > 0 THEN <fs_sgl_ir>-menge ELSE 1 ).
          <fs_sgl_ir>-sel_upr_amt = CONV decfloat34( <fs_sgl_ir>-sel_netpr ) / CONV decfloat34( <fs_sgl_ir>-sel_peinh ).
          <fs_sgl_ir>-sel_tot_amt = CONV decfloat34( lv_sgl_q ) * <fs_sgl_ir>-sel_upr_amt.
        ENDIF.

        UPDATE zmm_t_021
          SET userpref = ' ', zapprover1 = ' '
          WHERE zcollectno = @<fs_sgl_ir>-submi
            AND zqitem     = @<fs_sgl_ir>-ebelp
            AND zquotation <> @<fs_sgl_ir>-sel_ebeln.

        DATA: ls_db21_s TYPE zmm_t_021.
        CLEAR ls_db21_s.
        SELECT SINGLE * FROM zmm_t_021 INTO @ls_db21_s
          WHERE zquotation = @<fs_sgl_ir>-sel_ebeln AND zqitem = @<fs_sgl_ir>-sel_ebelp.
        IF sy-subrc = 0.
          ls_db21_s-userpref   = 'X'.
          ls_db21_s-zapprover1 = space.
          ls_db21_s-zaremark   = space.
          ls_db21_s-zuser      = sy-uname.
          ls_db21_s-znetpr     = <fs_sgl_ir>-sel_netpr.
          ls_db21_s-zremark    = <fs_sgl_ir>-user_remark.
          MODIFY zmm_t_021 FROM ls_db21_s.
        ELSE.
          ls_db21_s-mandt      = sy-mandt.
          ls_db21_s-zquotation = <fs_sgl_ir>-sel_ebeln.
          ls_db21_s-zqitem     = <fs_sgl_ir>-sel_ebelp.
          ls_db21_s-zdshcount  = '0001'.
          ls_db21_s-zcollectno = <fs_sgl_ir>-submi.
          ls_db21_s-zsupplier  = <fs_sgl_ir>-sel_lifnr.
          ls_db21_s-zsupname   = <fs_sgl_ir>-sel_name1.
          ls_db21_s-zmat       = <fs_sgl_ir>-matnr.
          ls_db21_s-zdesc      = <fs_sgl_ir>-txz01.
          ls_db21_s-zqty       = <fs_sgl_ir>-menge.
          ls_db21_s-zuom       = <fs_sgl_ir>-meins.
          ls_db21_s-znetpr     = <fs_sgl_ir>-sel_netpr.
          ls_db21_s-userpref   = 'X'.
          ls_db21_s-zapprover1 = space.
          ls_db21_s-zaremark   = space.
          ls_db21_s-zuser      = sy-uname.
          ls_db21_s-zremark    = <fs_sgl_ir>-user_remark.
          MODIFY zmm_t_021 FROM ls_db21_s.
        ENDIF.
        COMMIT WORK.
        <fs_sgl_ir>-user_pref   = 'X'.
        <fs_sgl_ir>-appr_status = space.
        <fs_sgl_ir>-appr_remark = space.

        PERFORM send_approval_notification USING gv_submi.
        PERFORM init_approval_status.
        MESSAGE |Item { lv_ebelp } submitted to HOD ({ gv_hod_name }) for approval. Notification sent.| TYPE 'S'.
        PERFORM render_html.
      ENDIF.

    WHEN 'EDIT_REMARK'.
      CLEAR: lv_item_str, lv_ebelp.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      lv_ebelp = lv_item_str.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_rem_ir>) WITH KEY ebelp = lv_ebelp.
      IF sy-subrc = 0.
        IF <fs_rem_ir>-po_number IS NOT INITIAL.
          MESSAGE |PO { <fs_rem_ir>-po_number } is already created for Item { lv_ebelp }.| TYPE 'W'.
          RETURN.
        ENDIF.
        IF <fs_rem_ir>-appr_status = 'X'.
          MESSAGE |Item { lv_ebelp } is approved. Remark modifications locked.| TYPE 'W'.
          RETURN.
        ENDIF.
        IF <fs_rem_ir>-user_pref = 'X' AND <fs_rem_ir>-appr_status <> 'R'
           AND gv_is_approver = abap_false.
          MESSAGE |Item { lv_ebelp } is in approval process. Remark modifications locked.| TYPE 'W'.
          RETURN.
        ENDIF.
        DATA: lv_rem_cancel TYPE abap_bool.
        PERFORM prompt_user_remark USING lv_ebelp
                                 CHANGING <fs_rem_ir>-user_remark
                                          lv_rem_cancel.
        IF lv_rem_cancel = abap_false.
          IF <fs_rem_ir>-sel_ebeln IS NOT INITIAL AND <fs_rem_ir>-sel_ebelp IS NOT INITIAL.
            UPDATE zmm_t_021
              SET zremark = @<fs_rem_ir>-user_remark
              WHERE zquotation = @<fs_rem_ir>-sel_ebeln
                AND zqitem     = @<fs_rem_ir>-sel_ebelp.
            COMMIT WORK.
          ENDIF.
          MESSAGE |Justification remark updated for Item { lv_ebelp }.| TYPE 'S'.
        ENDIF.
        PERFORM render_html.
      ENDIF.

    WHEN 'APPROVE'.
      IF gv_is_approver = abap_false.
        MESSAGE 'Authorization error: Only HOD approver can approve quotation comparison.' TYPE 'E'.
        RETURN.
      ENDIF.
      LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_app_ir>) WHERE po_number IS INITIAL.
        IF <fs_app_ir>-sel_lifnr IS NOT INITIAL.
          UPDATE zmm_t_021
            SET userpref = ' ', zapprover1 = ' '
            WHERE zcollectno = @<fs_app_ir>-submi
              AND zqitem     = @<fs_app_ir>-ebelp
              AND zquotation <> @<fs_app_ir>-sel_ebeln.

          DATA: ls_db21_app TYPE zmm_t_021.
          CLEAR ls_db21_app.
          SELECT SINGLE * FROM zmm_t_021
            INTO @ls_db21_app
            WHERE zquotation = @<fs_app_ir>-sel_ebeln
              AND zqitem     = @<fs_app_ir>-sel_ebelp.
          IF sy-subrc = 0.
            ls_db21_app-userpref   = 'X'.
            ls_db21_app-zapprover1 = 'X'.
            ls_db21_app-zaremark   = 'Approved by HOD'.
            UPDATE zmm_t_021 FROM @ls_db21_app.
          ELSE.
            ls_db21_app-mandt      = sy-mandt.
            ls_db21_app-zquotation = <fs_app_ir>-sel_ebeln.
            ls_db21_app-zqitem     = <fs_app_ir>-sel_ebelp.
            ls_db21_app-zdshcount  = '0001'.
            ls_db21_app-zcollectno = <fs_app_ir>-submi.
            ls_db21_app-zsupplier  = <fs_app_ir>-sel_lifnr.
            ls_db21_app-zsupname   = <fs_app_ir>-sel_name1.
            ls_db21_app-zmat       = <fs_app_ir>-matnr.
            ls_db21_app-zdesc      = <fs_app_ir>-txz01.
            ls_db21_app-zqty       = <fs_app_ir>-menge.
            ls_db21_app-zuom       = <fs_app_ir>-meins.
            ls_db21_app-znetpr     = <fs_app_ir>-sel_netpr.
            ls_db21_app-userpref   = 'X'.
            ls_db21_app-zapprover1 = 'X'.
            ls_db21_app-zaremark   = 'Approved by HOD'.
            INSERT zmm_t_021 FROM @ls_db21_app.
          ENDIF.
          <fs_app_ir>-user_pref   = 'X'.
          <fs_app_ir>-appr_status = 'X'.
          <fs_app_ir>-appr_remark = 'Approved by HOD'.
        ENDIF.
      ENDLOOP.
      COMMIT WORK.
      PERFORM send_decision_notification USING gv_submi 'X' 'Approved by HOD'.
      PERFORM init_approval_status.
      MESSAGE |Quotation comparison approved by HOD ({ gv_hod_name }). Sent back to creator for PO creation.| TYPE 'S'.
      PERFORM render_html.

    WHEN 'APPROVE_ITEM'.
      IF gv_is_approver = abap_false.
        MESSAGE 'Authorization error: Only HOD approver can approve items.' TYPE 'E'.
        RETURN.
      ENDIF.
      CLEAR: lv_item_str, lv_ebelp.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      lv_ebelp = lv_item_str.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_it_app>) WITH KEY ebelp = lv_ebelp.
      IF sy-subrc = 0 AND <fs_it_app>-sel_lifnr IS NOT INITIAL.
        UPDATE zmm_t_021
          SET userpref = ' ', zapprover1 = ' '
          WHERE zcollectno = @<fs_it_app>-submi
            AND zqitem     = @<fs_it_app>-ebelp
            AND zquotation <> @<fs_it_app>-sel_ebeln.

        DATA: ls_db21_it_app TYPE zmm_t_021.
        CLEAR ls_db21_it_app.
        SELECT SINGLE * FROM zmm_t_021
          INTO @ls_db21_it_app
          WHERE zquotation = @<fs_it_app>-sel_ebeln
            AND zqitem     = @<fs_it_app>-sel_ebelp.
        IF sy-subrc = 0.
          ls_db21_it_app-userpref   = 'X'.
          ls_db21_it_app-zapprover1 = 'X'.
          ls_db21_it_app-zaremark   = 'Approved by HOD'.
          UPDATE zmm_t_021 FROM @ls_db21_it_app.
        ELSE.
          ls_db21_it_app-mandt      = sy-mandt.
          ls_db21_it_app-zquotation = <fs_it_app>-sel_ebeln.
          ls_db21_it_app-zqitem     = <fs_it_app>-sel_ebelp.
          ls_db21_it_app-zdshcount  = '0001'.
          ls_db21_it_app-zcollectno = <fs_it_app>-submi.
          ls_db21_it_app-zsupplier  = <fs_it_app>-sel_lifnr.
          ls_db21_it_app-zsupname   = <fs_it_app>-sel_name1.
          ls_db21_it_app-zmat       = <fs_it_app>-matnr.
          ls_db21_it_app-zdesc      = <fs_it_app>-txz01.
          ls_db21_it_app-zqty       = <fs_it_app>-menge.
          ls_db21_it_app-zuom       = <fs_it_app>-meins.
          ls_db21_it_app-znetpr     = <fs_it_app>-sel_netpr.
          ls_db21_it_app-userpref   = 'X'.
          ls_db21_it_app-zapprover1 = 'X'.
          ls_db21_it_app-zaremark   = 'Approved by HOD'.
          INSERT zmm_t_021 FROM @ls_db21_it_app.
        ENDIF.
        <fs_it_app>-user_pref   = 'X'.
        <fs_it_app>-appr_status = 'X'.
        <fs_it_app>-appr_remark = 'Approved by HOD'.
        COMMIT WORK.
        PERFORM send_decision_notification USING gv_submi 'X' 'Approved by HOD'.
        PERFORM init_approval_status.
        MESSAGE |Item { lv_ebelp } approved by HOD ({ gv_hod_name }). Sent back to creator for PO creation.| TYPE 'S'.
        PERFORM render_html.
      ENDIF.

    WHEN 'REJECT'.
      IF gv_is_approver = abap_false.
        MESSAGE 'Authorization error: Only HOD approver can reject quotation comparison.' TYPE 'E'.
        RETURN.
      ENDIF.
      DATA: lv_rej_all_remark TYPE zmm_de_aremark,
            lv_rej_all_cancel TYPE abap_bool,
            lv_rej_all_ebelp  TYPE ekpo-ebelp.
      PERFORM prompt_rejection_remark USING lv_rej_all_ebelp
                                   CHANGING lv_rej_all_remark
                                            lv_rej_all_cancel.
      IF lv_rej_all_cancel = abap_true OR lv_rej_all_remark IS INITIAL.
        MESSAGE 'Rejection cancelled. Rejection remark is compulsory.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      DATA: lt_rej_items TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
      CLEAR lt_rej_items.

      LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_rej_ir>) WHERE po_number IS INITIAL.
        IF <fs_rej_ir>-sel_lifnr IS NOT INITIAL.
          APPEND |{ <fs_rej_ir>-ebelp }| TO lt_rej_items.
          UPDATE zmm_t_021
            SET userpref = ' ', zapprover1 = ' '
            WHERE zcollectno = @<fs_rej_ir>-submi
              AND zqitem     = @<fs_rej_ir>-ebelp
              AND zquotation <> @<fs_rej_ir>-sel_ebeln.

          DATA: ls_db21_rej TYPE zmm_t_021.
          CLEAR ls_db21_rej.
          SELECT SINGLE * FROM zmm_t_021
            INTO @ls_db21_rej
            WHERE zquotation = @<fs_rej_ir>-sel_ebeln
              AND zqitem     = @<fs_rej_ir>-sel_ebelp.
          IF sy-subrc = 0.
            ls_db21_rej-userpref   = 'X'.
            ls_db21_rej-zapprover1 = 'R'.
            ls_db21_rej-zaremark   = lv_rej_all_remark.
            UPDATE zmm_t_021 FROM @ls_db21_rej.
          ELSE.
            ls_db21_rej-mandt      = sy-mandt.
            ls_db21_rej-zquotation = <fs_rej_ir>-sel_ebeln.
            ls_db21_rej-zqitem     = <fs_rej_ir>-sel_ebelp.
            ls_db21_rej-zdshcount  = '0001'.
            ls_db21_rej-zcollectno = <fs_rej_ir>-submi.
            ls_db21_rej-zsupplier  = <fs_rej_ir>-sel_lifnr.
            ls_db21_rej-zsupname   = <fs_rej_ir>-sel_name1.
            ls_db21_rej-zmat       = <fs_rej_ir>-matnr.
            ls_db21_rej-zdesc      = <fs_rej_ir>-txz01.
            ls_db21_rej-zqty       = <fs_rej_ir>-menge.
            ls_db21_rej-zuom       = <fs_rej_ir>-meins.
            ls_db21_rej-znetpr     = <fs_rej_ir>-sel_netpr.
            ls_db21_rej-userpref   = 'X'.
            ls_db21_rej-zapprover1 = 'R'.
            ls_db21_rej-zaremark   = lv_rej_all_remark.
            INSERT zmm_t_021 FROM @ls_db21_rej.
          ENDIF.
          <fs_rej_ir>-user_pref   = 'X'.
          <fs_rej_ir>-appr_status = 'R'.
          <fs_rej_ir>-appr_remark = lv_rej_all_remark.
        ENDIF.
      ENDLOOP.
      COMMIT WORK.
      PERFORM send_decision_notification USING gv_submi 'R' lv_rej_all_remark.
      PERFORM init_approval_status.
      DATA(lv_items_str) = concat_lines_of( table = lt_rej_items sep = ', ' ).
      IF lines( lt_rej_items ) = 1.
        MESSAGE |Item { lv_items_str } rejected with remark: { lv_rej_all_remark }. Sent back to creator.| TYPE 'S' DISPLAY LIKE 'E'.
      ELSEIF lines( lt_rej_items ) > 1.
        MESSAGE |Items { lv_items_str } rejected with remark: { lv_rej_all_remark }. Sent back to creator.| TYPE 'S' DISPLAY LIKE 'E'.
      ELSE.
        MESSAGE |Quotation comparison rejected with remark: { lv_rej_all_remark }. Sent back to creator.| TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.
      PERFORM render_html.

    WHEN 'REJECT_ITEM'.
      IF gv_is_approver = abap_false.
        MESSAGE 'Authorization error: Only HOD approver can reject items.' TYPE 'E'.
        RETURN.
      ENDIF.
      CLEAR: lv_item_str, lv_ebelp.
      PERFORM parse_query_param USING lv_data 'item' CHANGING lv_item_str.
      lv_ebelp = lv_item_str.
      READ TABLE gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_it_rej>) WITH KEY ebelp = lv_ebelp.
      IF sy-subrc = 0 AND <fs_it_rej>-sel_lifnr IS NOT INITIAL.
        DATA: lv_rej_sgl_remark TYPE zmm_de_aremark,
              lv_rej_sgl_cancel TYPE abap_bool.
        PERFORM prompt_rejection_remark USING lv_ebelp
                                     CHANGING lv_rej_sgl_remark
                                              lv_rej_sgl_cancel.
        IF lv_rej_sgl_cancel = abap_true OR lv_rej_sgl_remark IS INITIAL.
          MESSAGE |Rejection of Item { lv_ebelp } cancelled. Rejection remark is compulsory.| TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        UPDATE zmm_t_021
          SET userpref = ' ', zapprover1 = ' '
          WHERE zcollectno = @<fs_it_rej>-submi
            AND zqitem     = @<fs_it_rej>-ebelp
            AND zquotation <> @<fs_it_rej>-sel_ebeln.

        DATA: ls_db21_it_rej TYPE zmm_t_021.
        CLEAR ls_db21_it_rej.
        SELECT SINGLE * FROM zmm_t_021
          INTO @ls_db21_it_rej
          WHERE zquotation = @<fs_it_rej>-sel_ebeln
            AND zqitem     = @<fs_it_rej>-sel_ebelp.
        IF sy-subrc = 0.
          ls_db21_it_rej-userpref   = 'X'.
          ls_db21_it_rej-zapprover1 = 'R'.
          ls_db21_it_rej-zaremark   = lv_rej_sgl_remark.
          UPDATE zmm_t_021 FROM @ls_db21_it_rej.
        ELSE.
          ls_db21_it_rej-mandt      = sy-mandt.
          ls_db21_it_rej-zquotation = <fs_it_rej>-sel_ebeln.
          ls_db21_it_rej-zqitem     = <fs_it_rej>-sel_ebelp.
          ls_db21_it_rej-zdshcount  = '0001'.
          ls_db21_it_rej-zcollectno = <fs_it_rej>-submi.
          ls_db21_it_rej-zsupplier  = <fs_it_rej>-sel_lifnr.
          ls_db21_it_rej-zsupname   = <fs_it_rej>-sel_name1.
          ls_db21_it_rej-zmat       = <fs_it_rej>-matnr.
          ls_db21_it_rej-zdesc      = <fs_it_rej>-txz01.
          ls_db21_it_rej-zqty       = <fs_it_rej>-menge.
          ls_db21_it_rej-zuom       = <fs_it_rej>-meins.
          ls_db21_it_rej-znetpr     = <fs_it_rej>-sel_netpr.
          ls_db21_it_rej-userpref   = 'X'.
          ls_db21_it_rej-zapprover1 = 'R'.
          ls_db21_it_rej-zaremark   = lv_rej_sgl_remark.
          INSERT zmm_t_021 FROM @ls_db21_it_rej.
        ENDIF.
        <fs_it_rej>-user_pref   = 'X'.
        <fs_it_rej>-appr_status = 'R'.
        <fs_it_rej>-appr_remark = lv_rej_sgl_remark.
        COMMIT WORK.
        PERFORM send_decision_notification USING gv_submi 'R' lv_rej_sgl_remark.
        PERFORM init_approval_status.
        MESSAGE |Item { lv_ebelp } rejected with remark: { lv_rej_sgl_remark }. Sent back to creator.| TYPE 'S' DISPLAY LIKE 'E'.
        PERFORM render_html.
      ENDIF.

    WHEN 'RECALL_APPROVAL' OR 'RESUBMIT'.
      LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_rec_ir>) WHERE po_number IS INITIAL.
        IF <fs_rec_ir>-sel_lifnr IS NOT INITIAL.
          UPDATE zmm_t_021
            SET zapprover1 = ' '
            WHERE zquotation = @<fs_rec_ir>-sel_ebeln
              AND zqitem     = @<fs_rec_ir>-sel_ebelp.
          <fs_rec_ir>-appr_status = space.
        ENDIF.
      ENDLOOP.
      COMMIT WORK.
      PERFORM init_approval_status.
      MESSAGE 'Quotation comparison returned to Draft mode.' TYPE 'S'.
      PERFORM render_html.

    WHEN 'CREATE_PO'.
      IF gv_is_approver = abap_true.
        MESSAGE 'Approval completed. Only creator/requester can create Purchase Orders.' TYPE 'I'.
        RETURN.
      ENDIF.
      PERFORM create_po_for_selected USING 0.
      PERFORM render_html.

    WHEN 'CREATE_SINGLE_PO' OR 'CREATE_PO_SINGLE'.
      IF gv_is_approver = abap_true.
        MESSAGE 'Approval completed. Only creator/requester can create Purchase Orders.' TYPE 'I'.
        RETURN.
      ENDIF.
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
    IF gv_is_approver = abap_false.
      IF <fs_ref>-appr_status = 'X'.
        MESSAGE |Item { pv_ebelp } is approved. Modifications locked.| TYPE 'W'.
        RETURN.
      ENDIF.
      IF <fs_ref>-user_pref = 'X' AND <fs_ref>-appr_status <> 'R'.
        MESSAGE |Item { pv_ebelp } is in approval process. Modifications locked.| TYPE 'W'.
        RETURN.
      ENDIF.
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

  IF lv_str_val CS '-'.
    lv_sign = '-'.
    REPLACE ALL OCCURRENCES OF '-' IN lv_str_val WITH ''.
    CONDENSE lv_str_val.
  ENDIF.

  " If exponential scientific notation like 1.23E+04, expand via decfloat34 STYLE = SIMPLE
  IF lv_str_val CS 'E'.
    TRY.
        DATA(lv_df) = CONV decfloat34( lv_str_val ).
        lv_str_val = |{ lv_df STYLE = SIMPLE }|.
      CATCH cx_root.
    ENDTRY.
  ENDIF.

  SPLIT lv_str_val AT '.' INTO lv_int lv_dec.

  " Clean leading zeros on integer part while preserving single 0
  SHIFT lv_int LEFT DELETING LEADING '0'.
  IF lv_int IS INITIAL.
    lv_int = '0'.
  ENDIF.

  " Preserve actual decimal digits with minimum 2 decimals (.00), never round
  IF lv_dec IS INITIAL.
    lv_dec = '00'.
  ELSEIF strlen( lv_dec ) = 1.
    lv_dec = lv_dec && '0'.
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

*&---------------------------------------------------------------------*
*& Form init_approval_status
*&---------------------------------------------------------------------*
FORM init_approval_status.

  " 1. Determine if current logged-in user is an Approver in ZMM_T_023
  CLEAR: gv_hod_user, gv_hod_name.
  DATA: lv_is_appr_mstr TYPE abap_bool VALUE abap_false.

  SELECT COUNT(*) FROM zmm_t_023 WHERE zuser = @sy-uname.
  IF sy-subrc = 0 AND sy-dbcnt > 0.
    lv_is_appr_mstr = abap_true.
  ENDIF.

  IF lv_is_appr_mstr = abap_true OR p_apprv = abap_true.
    " Current user IS an Approver!
    gv_is_approver = abap_true.
    gv_hod_user    = sy-uname.
  ELSE.
    " Current user is a Creator / Requester
    gv_is_approver = abap_false.
    " Look up assigned HOD for this creator
    SELECT SINGLE zuser FROM zmm_t_023
      INTO @gv_hod_user
      WHERE zcreator  = @sy-uname
        AND zapprover = '1'.
    IF sy-subrc <> 0 OR gv_hod_user IS INITIAL.
      " If not mapped directly to sy-uname, check creator of the current RFQs
      IF gt_hdr IS NOT INITIAL.
        READ TABLE gt_hdr ASSIGNING FIELD-SYMBOL(<ls_first_hdr>) INDEX 1.
        IF sy-subrc = 0.
          DATA: lv_hdr_ernam TYPE ekko-ernam.
          SELECT SINGLE ernam FROM ekko
            WHERE ebeln = @<ls_first_hdr>-ebeln
            INTO @lv_hdr_ernam.
          IF sy-subrc = 0 AND lv_hdr_ernam IS NOT INITIAL.
            SELECT SINGLE zuser FROM zmm_t_023
              INTO @gv_hod_user
              WHERE zcreator  = @lv_hdr_ernam
                AND zapprover = '1'.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  IF gv_hod_user IS NOT INITIAL.
    DATA: lv_persno TYPE usr21-persnumber,
          lv_fname  TYPE adrp-name_first,
          lv_lname  TYPE adrp-name_last.
    SELECT SINGLE persnumber FROM usr21 INTO @lv_persno WHERE bname = @gv_hod_user.
    IF sy-subrc = 0 AND lv_persno IS NOT INITIAL.
      SELECT SINGLE name_first, name_last FROM adrp INTO ( @lv_fname, @lv_lname )
        WHERE persnumber = @lv_persno.
      IF lv_fname IS NOT INITIAL OR lv_lname IS NOT INITIAL.
        gv_hod_name = |{ lv_fname } { lv_lname }|.
        CONDENSE gv_hod_name.
      ENDIF.
    ENDIF.
    IF gv_hod_name IS INITIAL.
      gv_hod_name = gv_hod_user.
    ENDIF.
  ELSE.
    gv_hod_user = 'HOD'.
    gv_hod_name = 'Head of Department'.
  ENDIF.

  " 2. Read existing approval entries from ZMM_T_021
  DATA: lt_t021 TYPE STANDARD TABLE OF zmm_t_021 WITH DEFAULT KEY.
  CLEAR lt_t021.
  IF gt_hdr IS NOT INITIAL.
    SELECT * FROM zmm_t_021
      INTO TABLE @lt_t021
      FOR ALL ENTRIES IN @gt_hdr
      WHERE zquotation = @gt_hdr-ebeln.
  ENDIF.

  CLEAR: gv_appr_items_cnt, gv_pend_items_cnt, gv_rej_items_cnt.
  DATA: lv_any_pref TYPE abap_bool VALUE abap_false,
        lv_sel_cnt  TYPE i VALUE 0.

  LOOP AT gt_item_ref ASSIGNING FIELD-SYMBOL(<fs_iref>).
    " 1. Strict hierarchy: Approved ('X') -> Rejected ('R') -> User Preferred ('X')
    READ TABLE lt_t021 INTO DATA(ls_p21)
      WITH KEY zqitem = <fs_iref>-ebelp zapprover1 = 'X'.
    IF sy-subrc <> 0.
      READ TABLE lt_t021 INTO ls_p21
        WITH KEY zqitem = <fs_iref>-ebelp zapprover1 = 'R'.
    ENDIF.
    IF sy-subrc <> 0.
      READ TABLE lt_t021 INTO ls_p21
        WITH KEY zqitem = <fs_iref>-ebelp userpref = 'X'.
    ENDIF.
    IF sy-subrc = 0.
      IF ls_p21-zapprover1 = 'X'.
        <fs_iref>-appr_status = 'X'.
        <fs_iref>-user_pref   = 'X'.
        lv_any_pref           = abap_true.
      ELSEIF ls_p21-zapprover1 = 'R'.
        <fs_iref>-appr_status = 'R'.
        <fs_iref>-user_pref   = 'X'.
        lv_any_pref           = abap_true.
      ELSEIF ls_p21-userpref = 'X'.
        <fs_iref>-appr_status = space.
        <fs_iref>-user_pref   = 'X'.
        lv_any_pref           = abap_true.
      ELSE.
        <fs_iref>-appr_status = ls_p21-zapprover1.
        <fs_iref>-user_pref   = ls_p21-userpref.
      ENDIF.
      <fs_iref>-user_remark = ls_p21-zremark.
      <fs_iref>-appr_remark = ls_p21-zaremark.
      IF <fs_iref>-po_number IS INITIAL.
        <fs_iref>-sel_lifnr = ls_p21-zsupplier.
        <fs_iref>-sel_ebeln = ls_p21-zquotation.
        <fs_iref>-sel_ebelp = ls_p21-zqitem.
        READ TABLE gt_hdr INTO DATA(ls_h_m) WITH KEY ebeln = ls_p21-zquotation.
        IF sy-subrc = 0.
          <fs_iref>-sel_name1 = ls_h_m-name1.
        ELSE.
          READ TABLE gt_hdr INTO ls_h_m WITH KEY lifnr = ls_p21-zsupplier.
          IF sy-subrc = 0.
            <fs_iref>-sel_name1 = ls_h_m-name1.
          ENDIF.
        ENDIF.

        " Ensure complete price and quotation details are populated
        CLEAR: <fs_iref>-sel_netpr, <fs_iref>-sel_peinh.
        READ TABLE gt_rfq_items INTO DATA(ls_rfq_rst)
          WITH KEY ebeln = <fs_iref>-sel_ebeln ebelp = <fs_iref>-sel_ebelp.
        IF sy-subrc <> 0 AND <fs_iref>-sel_lifnr IS NOT INITIAL.
          READ TABLE gt_rfq_items INTO ls_rfq_rst
            WITH KEY ebelp = <fs_iref>-ebelp lifnr = <fs_iref>-sel_lifnr.
        ENDIF.

        IF sy-subrc = 0 AND ls_rfq_rst-netpr > 0.
          <fs_iref>-sel_netpr   = ls_rfq_rst-netpr.
          <fs_iref>-sel_peinh   = COND #( WHEN ls_rfq_rst-peinh > 0 THEN ls_rfq_rst-peinh ELSE 1 ).
          <fs_iref>-sel_waers   = ls_rfq_rst-waers.
          <fs_iref>-sel_zterm   = ls_rfq_rst-zterm.
          <fs_iref>-sel_inco1       = ls_rfq_rst-inco1.
          <fs_iref>-sel_freight     = ls_rfq_rst-freight.
          <fs_iref>-sel_frt_details = ls_rfq_rst-frt_details.
          IF ls_rfq_rst-bukrs IS NOT INITIAL. <fs_iref>-bukrs = ls_rfq_rst-bukrs. ENDIF.
          IF ls_rfq_rst-ekorg IS NOT INITIAL. <fs_iref>-ekorg = ls_rfq_rst-ekorg. ENDIF.
          IF ls_rfq_rst-ekgrp IS NOT INITIAL. <fs_iref>-ekgrp = ls_rfq_rst-ekgrp. ENDIF.
        ELSE.
          DATA: lv_db_pe_r TYPE ekpo-peinh,
                lv_db_me_r TYPE ekpo-meins.
          SELECT SINGLE netpr, peinh, meins FROM ekpo
            WHERE ebeln = @<fs_iref>-sel_ebeln AND ebelp = @<fs_iref>-sel_ebelp
            INTO (@<fs_iref>-sel_netpr, @lv_db_pe_r, @lv_db_me_r).
          IF sy-subrc = 0.
            <fs_iref>-sel_peinh = COND #( WHEN lv_db_pe_r > 0 THEN lv_db_pe_r ELSE 1 ).
          ELSEIF ls_p21-znetpr > 0.
            <fs_iref>-sel_netpr = ls_p21-znetpr.
            <fs_iref>-sel_peinh = 1.
          ENDIF.
        ENDIF.

        DATA(lv_rst_q) = COND ekpo-menge( WHEN <fs_iref>-menge > 0 THEN <fs_iref>-menge ELSE 1 ).
        DATA(lv_rst_p) = COND ekpo-peinh( WHEN <fs_iref>-sel_peinh > 0 THEN <fs_iref>-sel_peinh ELSE 1 ).
        DATA(lv_b_upr_rst) = CONV decfloat34( <fs_iref>-sel_netpr ) / CONV decfloat34( lv_rst_p ).
        IF <fs_iref>-sel_waers = 'USD' AND ls_rfq_rst-wkurs > 0.
          lv_b_upr_rst = lv_b_upr_rst * CONV decfloat34( ls_rfq_rst-wkurs ).
        ENDIF.
        <fs_iref>-sel_tot_amt = CONV decfloat34( lv_rst_q ) * lv_b_upr_rst.
        <fs_iref>-sel_upr_amt = lv_b_upr_rst.
      ENDIF.
    ELSE.
      " No saved preference in ZMM_T_021: Default to System Suggested L1 winner if unselected!
      IF <fs_iref>-po_number IS INITIAL AND <fs_iref>-sel_lifnr IS INITIAL.
        <fs_iref>-sel_col         = <fs_iref>-l1_sel_col.
        <fs_iref>-sel_ebeln       = <fs_iref>-l1_ebeln.
        <fs_iref>-sel_ebelp       = <fs_iref>-l1_ebelp.
        <fs_iref>-sel_lifnr       = <fs_iref>-l1_lifnr.
        <fs_iref>-sel_name1       = <fs_iref>-l1_name1.
        <fs_iref>-sel_netpr       = <fs_iref>-l1_netpr.
        <fs_iref>-sel_peinh       = <fs_iref>-l1_peinh.
        <fs_iref>-sel_waers       = <fs_iref>-l1_waers.
        <fs_iref>-sel_zterm       = <fs_iref>-l1_zterm.
        <fs_iref>-sel_inco1       = <fs_iref>-l1_inco1.
        <fs_iref>-sel_freight     = <fs_iref>-l1_freight.
        <fs_iref>-sel_frt_details = <fs_iref>-l1_frt_details.
        <fs_iref>-sel_tot_amt     = <fs_iref>-l1_tot_amt.
        <fs_iref>-sel_upr_amt     = <fs_iref>-l1_upr_amt.
        <fs_iref>-appr_status = space.
        <fs_iref>-user_pref   = space.
        CLEAR: <fs_iref>-user_remark, <fs_iref>-appr_remark.
      ENDIF.
    ENDIF.

    " Determine column name QUAT1..QUAT7 for visual highlight in ALV
    IF <fs_iref>-sel_lifnr IS NOT INITIAL.
      CLEAR <fs_iref>-sel_col.
      DATA: lv_h_idx TYPE i VALUE 0.
      LOOP AT gt_hdr INTO DATA(ls_h_c).
        lv_h_idx = lv_h_idx + 1.
        IF ls_h_c-lifnr = <fs_iref>-sel_lifnr.
          <fs_iref>-sel_col = |QUAT{ lv_h_idx }|.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    " Sync gt_final row: quat = 'Val:'
    READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_val_sync>)
      WITH KEY ebelp = <fs_iref>-ebelp quat = 'Val:'.
    IF sy-subrc = 0.
      IF <fs_iref>-po_number IS NOT INITIAL.
        <fs_val_sync>-sel       = '@02@ Created'.
        <fs_val_sync>-po_action = |@0V@ PO { <fs_iref>-po_number }|.
      ELSEIF <fs_iref>-appr_status = 'X'.
        <fs_val_sync>-sel       = '@01@ [X]'.
        IF gv_is_approver = abap_true.
          <fs_val_sync>-po_action = '@0V@ Approved'.
        ELSE.
          <fs_val_sync>-po_action = '@15@ Create PO'.
        ENDIF.
      ELSEIF <fs_iref>-appr_status = 'R'.
        <fs_val_sync>-sel       = '@02@ [R]'.
        IF <fs_iref>-appr_remark IS NOT INITIAL.
          <fs_val_sync>-po_action = |@0W@ Rej: { <fs_iref>-appr_remark(15) }|.
        ELSE.
          <fs_val_sync>-po_action = '@0W@ Rejected'.
        ENDIF.
      ELSEIF <fs_iref>-sel_lifnr IS NOT INITIAL.
        IF gv_is_approver = abap_true.
          <fs_val_sync>-sel       = '@09@ [X]'.
          <fs_val_sync>-po_action = '@0V@ Approve Item'.
        ELSE.
          IF <fs_iref>-user_pref = 'X'.
            <fs_val_sync>-sel       = '@09@ [X]'.
            <fs_val_sync>-po_action = '@09@ In Approval'.
          ELSE.
            <fs_val_sync>-sel       = '@01@ [X]'.
            <fs_val_sync>-po_action = '@2L@ Send to HOD'.
          ENDIF.
        ENDIF.
      ELSE.
        <fs_val_sync>-sel       = '@R7@ [ ]'.
        <fs_val_sync>-po_action = '@0Y@ Select Supplier'.
      ENDIF.
    ENDIF.

    " Sync gt_final row: quat = 'Approved'
    READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_app_sync>)
      WITH KEY ebelp = <fs_iref>-ebelp quat = 'Approved'.
    IF sy-subrc = 0.
      IF lines( gt_hdr ) >= 1. <fs_app_sync>-quat1 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 2. <fs_app_sync>-quat2 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 3. <fs_app_sync>-quat3 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 4. <fs_app_sync>-quat4 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 5. <fs_app_sync>-quat5 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 6. <fs_app_sync>-quat6 = '[ ]'. ENDIF.
      IF lines( gt_hdr ) >= 7. <fs_app_sync>-quat7 = '[ ]'. ENDIF.
      CLEAR <fs_app_sync>-cell_colors.

      IF <fs_iref>-sel_col IS NOT INITIAL.
        ASSIGN COMPONENT <fs_iref>-sel_col OF STRUCTURE <fs_app_sync> TO FIELD-SYMBOL(<fs_app_c>).
        IF sy-subrc = 0.
          IF <fs_iref>-po_number IS NOT INITIAL.
            <fs_app_c> = '[PO Done]'.
            APPEND VALUE #( fieldname = <fs_iref>-sel_col color = VALUE #( col = 5 int = 0 ) )
              TO <fs_app_sync>-cell_colors.
          ELSEIF <fs_iref>-appr_status = 'X'.
            <fs_app_c> = '[Approved]'.
            APPEND VALUE #( fieldname = <fs_iref>-sel_col color = VALUE #( col = 5 int = 1 ) )
              TO <fs_app_sync>-cell_colors.
          ELSEIF <fs_iref>-appr_status = 'R'.
            <fs_app_c> = '[Rejected]'.
            APPEND VALUE #( fieldname = <fs_iref>-sel_col color = VALUE #( col = 6 int = 1 ) )
              TO <fs_app_sync>-cell_colors.
          ELSEIF <fs_iref>-user_pref = 'X'.
            <fs_app_c> = '[In Appr]'.
            APPEND VALUE #( fieldname = <fs_iref>-sel_col color = VALUE #( col = 3 int = 1 ) )
              TO <fs_app_sync>-cell_colors.
          ELSE.
            <fs_app_c> = '[Selected]'.
            APPEND VALUE #( fieldname = <fs_iref>-sel_col color = VALUE #( col = 1 int = 1 ) )
              TO <fs_app_sync>-cell_colors.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF <fs_iref>-sel_lifnr IS NOT INITIAL.
      lv_sel_cnt = lv_sel_cnt + 1.
      IF <fs_iref>-appr_status = 'X'.
        gv_appr_items_cnt = gv_appr_items_cnt + 1.
      ELSEIF <fs_iref>-appr_status = 'R'.
        gv_rej_items_cnt  = gv_rej_items_cnt + 1.
      ELSEIF <fs_iref>-user_pref = 'X' OR gv_is_approver = abap_true.
        gv_pend_items_cnt = gv_pend_items_cnt + 1.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Sync Top Header Action Buttons in ALV (Rows 1, 2, 4)
  DATA: lv_unsub_top TYPE i VALUE 0.
  LOOP AT gt_item_ref INTO DATA(ls_unsub_top) WHERE po_number IS INITIAL.
    IF ls_unsub_top-sel_lifnr IS NOT INITIAL AND ls_unsub_top-user_pref IS INITIAL.
      lv_unsub_top = lv_unsub_top + 1.
    ENDIF.
  ENDLOOP.

  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_top1>) INDEX 1.
  IF sy-subrc = 0.
    IF gv_is_approver = abap_true.
      <fs_top1>-po_action = COND #( WHEN gv_appr_items_cnt > 0
                                    THEN |@0V@ Sent to Creator ({ gv_appr_items_cnt })|
                                    ELSE '@0Y@ Approver View' ).
    ELSE.
      IF gv_appr_items_cnt > 0.
        <fs_top1>-po_action = |@15@ Create PO ({ gv_appr_items_cnt })|.
      ELSE.
        <fs_top1>-po_action = '@0Y@ Create PO'.
      ENDIF.
    ENDIF.
  ENDIF.

  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_top2>) INDEX 2.
  IF sy-subrc = 0.
    IF gv_is_approver = abap_true.
      DATA(lv_act_top_tot) = gv_pend_items_cnt + gv_rej_items_cnt.
      IF lv_act_top_tot > 0.
        <fs_top2>-po_action = |@0V@ Approve All ({ lv_act_top_tot })|.
      ELSE.
        <fs_top2>-po_action = '@0V@ Approved'.
      ENDIF.
    ELSE.
      IF lv_unsub_top > 0.
        <fs_top2>-po_action = |@2L@ Send to HOD ({ lv_unsub_top })|.
      ELSEIF gv_rej_items_cnt > 0.
        <fs_top2>-po_action = |@2L@ Resend to HOD ({ gv_rej_items_cnt })|.
      ELSEIF gv_pend_items_cnt > 0.
        <fs_top2>-po_action = |@09@ In Appr ({ gv_pend_items_cnt })|.
      ELSE.
        <fs_top2>-po_action = '@09@ In Approval'.
      ENDIF.
    ENDIF.
  ENDIF.

  READ TABLE gt_final ASSIGNING FIELD-SYMBOL(<fs_top4>) INDEX 4.
  IF sy-subrc = 0.
    IF gv_is_approver = abap_true AND ( gv_pend_items_cnt > 0 OR gv_appr_items_cnt > 0 ).
      <fs_top4>-po_action = '@0W@ Reject All'.
    ELSE.
      <fs_top4>-po_action = space.
    ENDIF.
  ENDIF.

  IF lv_sel_cnt > 0 AND gv_appr_items_cnt = lv_sel_cnt.
    gv_approval_status = 'APPROVED'.
  ELSEIF gv_appr_items_cnt > 0.
    gv_approval_status = 'PARTIAL'.
  ELSEIF gv_pend_items_cnt > 0.
    gv_approval_status = 'PENDING'.
  ELSEIF gv_rej_items_cnt > 0 AND gv_rej_items_cnt = lv_sel_cnt.
    gv_approval_status = 'REJECTED'.
  ELSE.
    gv_approval_status = 'DRAFT'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form prompt_user_remark
*&---------------------------------------------------------------------*
FORM prompt_user_remark USING    pv_ebelp     TYPE ekpo-ebelp
                        CHANGING cv_remark    TYPE zmm_de_remark
                                 cv_cancelled TYPE abap_bool.

  DATA: lt_fields TYPE STANDARD TABLE OF sval,
        ls_field  TYPE sval,
        lv_return TYPE c.

  cv_cancelled = abap_false.
  CLEAR: lt_fields, ls_field.

  ls_field-tabname   = 'ZMM_T_021'.
  ls_field-fieldname = 'ZREMARK'.
  ls_field-fieldtext = |Reason for Item { pv_ebelp }|.
  ls_field-value     = cv_remark.
  ls_field-field_obl = 'X'.
  APPEND ls_field TO lt_fields.

  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      popup_title     = |Mandatory Non-L1 Reason (Item { pv_ebelp })|
    IMPORTING
      returncode      = lv_return
    TABLES
      fields          = lt_fields
    EXCEPTIONS
      error_in_fields = 1
      OTHERS          = 2.

  IF sy-subrc <> 0 OR lv_return = 'A'.
    cv_cancelled = abap_true.
    RETURN.
  ENDIF.

  READ TABLE lt_fields INTO ls_field INDEX 1.
  IF sy-subrc = 0.
    cv_remark = ls_field-value.
    CONDENSE cv_remark.
    IF cv_remark IS INITIAL.
      cv_cancelled = abap_true.
    ENDIF.
  ELSE.
    cv_cancelled = abap_true.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form prompt_rejection_remark
*&---------------------------------------------------------------------*
FORM prompt_rejection_remark USING    pv_ebelp     TYPE any
                             CHANGING cv_remark    TYPE zmm_de_aremark
                                      cv_cancelled TYPE abap_bool.

  DATA: lt_fields TYPE STANDARD TABLE OF sval,
        ls_field  TYPE sval,
        lv_return TYPE c,
        lv_title  TYPE c LENGTH 80.

  cv_cancelled = abap_false.
  CLEAR: lt_fields, ls_field.

  ls_field-tabname   = 'ZMM_T_021'.
  ls_field-fieldname = 'ZAREMARK'.
  IF pv_ebelp IS NOT INITIAL.
    ls_field-fieldtext = |Reject Item { pv_ebelp }|.
    lv_title           = |Mandatory Rejection Remark - Item { pv_ebelp }|.
  ELSE.
    ls_field-fieldtext = 'Rejection Reason'.
    lv_title           = 'Mandatory Rejection Remark (All Pending Items)'.
  ENDIF.
  ls_field-value     = cv_remark.
  ls_field-field_obl = 'X'.
  APPEND ls_field TO lt_fields.

  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      popup_title     = lv_title
    IMPORTING
      returncode      = lv_return
    TABLES
      fields          = lt_fields
    EXCEPTIONS
      error_in_fields = 1
      OTHERS          = 2.

  IF sy-subrc <> 0 OR lv_return = 'A'.
    cv_cancelled = abap_true.
    RETURN.
  ENDIF.

  READ TABLE lt_fields INTO ls_field INDEX 1.
  IF sy-subrc = 0.
    cv_remark = ls_field-value.
    CONDENSE cv_remark.
    IF cv_remark IS INITIAL.
      cv_cancelled = abap_true.
    ENDIF.
  ELSE.
    cv_cancelled = abap_true.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_default_open_collective
*&---------------------------------------------------------------------*
FORM get_default_open_collective USING    pv_user  TYPE sy-uname
                                CHANGING cv_submi TYPE ekko-submi.

  CLEAR cv_submi.

  DATA: lt_creators TYPE STANDARD TABLE OF zmm_t_023-zcreator.
  SELECT zcreator FROM zmm_t_023 INTO TABLE @lt_creators WHERE zuser = @pv_user.
  IF lt_creators IS INITIAL.
    APPEND pv_user TO lt_creators.
  ENDIF.

  TYPES: BEGIN OF ty_sub_date,
           submi TYPE ekko-submi,
           aedat TYPE ekko-aedat,
         END OF ty_sub_date.
  DATA: lt_submis TYPE STANDARD TABLE OF ty_sub_date.

  SELECT DISTINCT submi, aedat
    FROM ekko
    FOR ALL ENTRIES IN @lt_creators
    WHERE bstyp = 'A'
      AND submi <> @space
      AND ernam = @lt_creators-table_line
    INTO TABLE @lt_submis.

  IF lt_submis IS INITIAL.
    SELECT DISTINCT submi, aedat
      FROM ekko
      WHERE bstyp = 'A'
        AND submi <> @space
      INTO TABLE @lt_submis.
  ENDIF.

  IF lt_submis IS INITIAL.
    RETURN.
  ENDIF.

  SORT lt_submis BY aedat DESCENDING submi DESCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_submis COMPARING submi.

  SELECT zcollectno, zpo
    FROM zmm_t_021
    FOR ALL ENTRIES IN @lt_submis
    WHERE zcollectno = @lt_submis-submi
    INTO TABLE @DATA(lt_chk_t021).

  LOOP AT lt_submis INTO DATA(ls_sd).
    DATA: lv_tot TYPE i VALUE 0,
          lv_pos TYPE i VALUE 0.
    CLEAR: lv_tot, lv_pos.
    LOOP AT lt_chk_t021 INTO DATA(ls_c) WHERE zcollectno = ls_sd-submi.
      lv_tot = lv_tot + 1.
      IF ls_c-zpo IS NOT INITIAL.
        lv_pos = lv_pos + 1.
      ENDIF.
    ENDLOOP.
    IF lv_tot = 0 OR lv_pos < lv_tot.
      cv_submi = ls_sd-submi.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF cv_submi IS INITIAL AND lt_submis IS NOT INITIAL.
    cv_submi = lt_submis[ 1 ]-submi.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f4_collective_number
*&---------------------------------------------------------------------*
FORM f4_collective_number.

  DATA: lv_is_appr_f4 TYPE abap_bool VALUE abap_false.
  SELECT COUNT(*) FROM zmm_t_023 WHERE zuser = @sy-uname.
  IF ( sy-subrc = 0 AND sy-dbcnt > 0 ) OR p_apprv = abap_true.
    lv_is_appr_f4 = abap_true.
  ENDIF.

  TYPES: BEGIN OF ty_f4_submi,
           submi      TYPE ekko-submi,
           ernam      TYPE ekko-ernam,
           aedat      TYPE ekko-aedat,
           status     TYPE c LENGTH 25,
           open_items TYPE c LENGTH 15,
         END OF ty_f4_submi.

  DATA: lt_f4_submi TYPE STANDARD TABLE OF ty_f4_submi,
        ls_f4_submi TYPE ty_f4_submi.

  DATA: lt_my_creators TYPE STANDARD TABLE OF zmm_t_023-zcreator.
  IF lv_is_appr_f4 = abap_true.
    SELECT zcreator FROM zmm_t_023
      INTO TABLE @lt_my_creators
      WHERE zuser = @sy-uname.
    IF lt_my_creators IS INITIAL AND p_apprv = abap_true.
      SELECT DISTINCT zcreator FROM zmm_t_023 INTO TABLE @lt_my_creators.
    ENDIF.
  ELSE.
    APPEND sy-uname TO lt_my_creators.
  ENDIF.

  IF lt_my_creators IS INITIAL.
    MESSAGE 'No assigned creators found for approval routing.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  TYPES: BEGIN OF ty_ekko_sub,
           submi TYPE ekko-submi,
           ernam TYPE ekko-ernam,
           aedat TYPE ekko-aedat,
         END OF ty_ekko_sub.
  DATA: lt_rfqs TYPE STANDARD TABLE OF ty_ekko_sub.

  SELECT DISTINCT submi, ernam, aedat
    FROM ekko
    FOR ALL ENTRIES IN @lt_my_creators
    WHERE bstyp = 'A'
      AND submi <> @space
      AND ernam = @lt_my_creators-table_line
    INTO TABLE @lt_rfqs.

  IF lt_rfqs IS INITIAL.
    SELECT DISTINCT submi, ernam, aedat
      FROM ekko
      WHERE bstyp = 'A'
        AND submi <> @space
      INTO TABLE @lt_rfqs.
  ENDIF.

  IF lt_rfqs IS INITIAL.
    MESSAGE 'No collective RFQs found.' TYPE 'S' DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

  SORT lt_rfqs BY aedat DESCENDING submi DESCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_rfqs COMPARING submi.

  SELECT zcollectno, zquotation, zqitem, zapprover1, zpo
    FROM zmm_t_021
    FOR ALL ENTRIES IN @lt_rfqs
    WHERE zcollectno = @lt_rfqs-submi
    INTO TABLE @DATA(lt_t021_all).

  LOOP AT lt_rfqs INTO DATA(ls_rfq).
    DATA: lv_tot_lines  TYPE i VALUE 0,
          lv_po_lines   TYPE i VALUE 0,
          lv_pend_lines TYPE i VALUE 0,
          lv_appr_lines TYPE i VALUE 0,
          lv_rej_lines  TYPE i VALUE 0.

    CLEAR: lv_tot_lines, lv_po_lines, lv_pend_lines, lv_appr_lines, lv_rej_lines.

    LOOP AT lt_t021_all INTO DATA(ls_t21) WHERE zcollectno = ls_rfq-submi.
      lv_tot_lines = lv_tot_lines + 1.
      IF ls_t21-zpo IS NOT INITIAL.
        lv_po_lines = lv_po_lines + 1.
      ELSE.
        IF ls_t21-zapprover1 = 'X'.
          lv_appr_lines = lv_appr_lines + 1.
        ELSEIF ls_t21-zapprover1 = 'R'.
          lv_rej_lines = lv_rej_lines + 1.
        ELSE.
          lv_pend_lines = lv_pend_lines + 1.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " Open only requirement: If all items have PO created, skip!
    IF lv_tot_lines > 0 AND lv_po_lines >= lv_tot_lines.
      CONTINUE.
    ENDIF.

    CLEAR ls_f4_submi.
    ls_f4_submi-submi = ls_rfq-submi.
    ls_f4_submi-ernam = ls_rfq-ernam.
    ls_f4_submi-aedat = ls_rfq-aedat.

    DATA(lv_open_cnt) = lv_tot_lines - lv_po_lines.
    IF lv_tot_lines = 0.
      ls_f4_submi-status     = 'New / Uncompared'.
      ls_f4_submi-open_items = 'RFQ Open'.
    ELSEIF lv_pend_lines > 0.
      ls_f4_submi-status     = 'Pending Approval'.
      ls_f4_submi-open_items = |{ lv_pend_lines } Pending|.
    ELSEIF lv_appr_lines > 0.
      ls_f4_submi-status     = 'Approved (PO Pend)'.
      ls_f4_submi-open_items = |{ lv_appr_lines } Approved|.
    ELSEIF lv_rej_lines > 0.
      ls_f4_submi-status     = 'Rejected by HOD'.
      ls_f4_submi-open_items = |{ lv_rej_lines } Rejected|.
    ELSE.
      ls_f4_submi-status     = 'Draft / In Progress'.
      ls_f4_submi-open_items = |{ lv_open_cnt } Open|.
    ENDIF.

    APPEND ls_f4_submi TO lt_f4_submi.
  ENDLOOP.

  IF lt_f4_submi IS INITIAL.
    MESSAGE 'No OPEN collective numbers pending for your approval.' TYPE 'S' DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

  DATA: lt_return TYPE STANDARD TABLE OF ddshretval.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SUBMI'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'S_SUBMI-LOW'
      value_org       = 'S'
    TABLES
      value_tab       = lt_f4_submi
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc = 0.
    READ TABLE lt_return INTO DATA(ls_ret) INDEX 1.
    IF sy-subrc = 0.
      s_submi-low    = ls_ret-fieldval.
      s_submi-sign   = 'I'.
      s_submi-option = 'EQ'.
      CLEAR s_submi[].
      APPEND s_submi.

      DATA: lt_dynpread TYPE STANDARD TABLE OF dynpread,
            ls_dynpread TYPE dynpread.
      ls_dynpread-fieldname  = 'S_SUBMI-LOW'.
      ls_dynpread-fieldvalue = ls_ret-fieldval.
      APPEND ls_dynpread TO lt_dynpread.
      CALL FUNCTION 'DYNP_VALUES_UPDATE'
        EXPORTING
          dyname     = sy-repid
          dynumb     = sy-dynnr
        TABLES
          dynpfields = lt_dynpread
        EXCEPTIONS
          OTHERS     = 0.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form send_approval_notification
*&---------------------------------------------------------------------*
FORM send_approval_notification USING pv_submi TYPE any.

  DATA: lv_msg       TYPE char128,
        lv_hod_user  TYPE sy-uname,
        lv_hod_email TYPE adr6-smtp_addr.

  lv_hod_user = gv_hod_user.
  IF lv_hod_user IS INITIAL OR lv_hod_user = 'HOD'.
    RETURN.
  ENDIF.

  " 1. Send screen popup to HOD if logged in
  lv_msg = |Price comparison for Collective RFQ { pv_submi } submitted by { sy-uname } for approval.|.
  CALL FUNCTION 'TH_POPUP'
    EXPORTING
      client  = sy-mandt
      user    = lv_hod_user
      message = lv_msg
    EXCEPTIONS
      OTHERS  = 1.

  " 2. Get Approver Email from ADR6 / USR21
  DATA: lv_persno TYPE usr21-persnumber,
        lv_addrno TYPE usr21-addrnumber.
  SELECT SINGLE persnumber, addrnumber FROM usr21
    INTO ( @lv_persno, @lv_addrno )
    WHERE bname = @lv_hod_user.
  IF sy-subrc = 0.
    SELECT SINGLE smtp_addr FROM adr6
      INTO @lv_hod_email
      WHERE persnumber = @lv_persno
        AND addrnumber = @lv_addrno.
    IF sy-subrc <> 0 OR lv_hod_email IS INITIAL.
      SELECT SINGLE smtp_addr FROM adr6
        INTO @lv_hod_email
        WHERE persnumber = @lv_persno.
    ENDIF.
  ENDIF.

  " 3. Prepare Notification Document
  DATA: ls_doc_data  TYPE sodocchgi1,
        lt_objtxt    TYPE STANDARD TABLE OF solisti1,
        ls_objtxt    TYPE solisti1,
        lt_receivers TYPE STANDARD TABLE OF somlreci1,
        ls_receiver  TYPE somlreci1.

  ls_doc_data-obj_name  = 'PRICE_COMP'.
  ls_doc_data-obj_descr = |Quotation Approval Request: Collective RFQ { pv_submi }|.
  ls_doc_data-obj_langu = sy-langu.

  " Header body lines
  ls_objtxt-line = |Dear { gv_hod_name },|.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = space.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = |A quotation price comparison has been submitted for your approval.|.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = |Submitted By : { sy-uname }|.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = |Collective RFQ: { pv_submi }|.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = |Transaction Code: ZPQC_NEW|.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = space.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = 'SUBMITTED ITEMS BREAKDOWN:'.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = '--------------------------------------------------------------------------------'.
  APPEND ls_objtxt TO lt_objtxt.

  LOOP AT gt_item_ref INTO DATA(ls_ir) WHERE po_number IS INITIAL AND sel_lifnr IS NOT INITIAL.
    DATA: lv_amt_str TYPE string.
    PERFORM format_inr USING ls_ir-sel_tot_amt CHANGING lv_amt_str.
    ls_objtxt-line = |Item { ls_ir-ebelp }: { ls_ir-txz01(20) } | &&
                     |Qty: { ls_ir-menge } { ls_ir-meins } | &&
                     |Supplier: { ls_ir-sel_name1(16) } | &&
                     |Total: INR { lv_amt_str }|.
    APPEND ls_objtxt TO lt_objtxt.
    IF ls_ir-sel_lifnr <> ls_ir-l1_lifnr.
      ls_objtxt-line = |  * NON-L1 SELECTION (System L1: { ls_ir-l1_name1(16) })|.
      APPEND ls_objtxt TO lt_objtxt.
      IF ls_ir-user_remark IS NOT INITIAL.
        ls_objtxt-line = |  * JUSTIFICATION REASON: { ls_ir-user_remark }|.
        APPEND ls_objtxt TO lt_objtxt.
      ENDIF.
    ENDIF.
  ENDLOOP.

  ls_objtxt-line = '--------------------------------------------------------------------------------'.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = space.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = 'Please log in to SAP and execute transaction ZPQC_NEW to review and approve/reject.'.
  APPEND ls_objtxt TO lt_objtxt.

  " Receivers
  " 1. SAP Business Workplace Inbox
  CLEAR ls_receiver.
  ls_receiver-receiver = lv_hod_user.
  ls_receiver-rec_type = 'B'.  " SAP user inbox
  ls_receiver-express  = 'X'.
  APPEND ls_receiver TO lt_receivers.

  " 2. External Email (if maintained)
  IF lv_hod_email IS NOT INITIAL.
    CLEAR ls_receiver.
    ls_receiver-receiver = lv_hod_email.
    ls_receiver-rec_type = 'U'.  " Internet email
    APPEND ls_receiver TO lt_receivers.
  ENDIF.

  CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
    EXPORTING
      document_data              = ls_doc_data
      document_type              = 'RAW'
      put_in_outbox              = 'X'
      commit_work                = 'X'
    TABLES
      object_content             = lt_objtxt
      receivers                  = lt_receivers
    EXCEPTIONS
      OTHERS                     = 1.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form send_decision_notification
*&---------------------------------------------------------------------*
FORM send_decision_notification USING pv_submi  TYPE any
                                     pv_status TYPE c
                                     pv_remark TYPE any.

  DATA: lv_creator_user  TYPE sy-uname,
        lv_creator_email TYPE adr6-smtp_addr,
        lv_msg           TYPE char128.

  " 1. Determine creator user: check ZMM_T_021 (zuser) or EKKO (ernam)
  SELECT SINGLE zuser FROM zmm_t_021
    WHERE zcollectno = @pv_submi
      AND zuser      IS NOT INITIAL
    INTO @lv_creator_user.
  IF sy-subrc <> 0 OR lv_creator_user IS INITIAL.
    IF gt_hdr IS NOT INITIAL.
      READ TABLE gt_hdr ASSIGNING FIELD-SYMBOL(<ls_h_c>) INDEX 1.
      IF sy-subrc = 0.
        SELECT SINGLE ernam FROM ekko
          WHERE ebeln = @<ls_h_c>-ebeln
          INTO @lv_creator_user.
      ENDIF.
    ENDIF.
  ENDIF.

  IF lv_creator_user IS INITIAL.
    RETURN.
  ENDIF.

  " 2. Send screen popup to Creator if logged in
  IF pv_status = 'X'.
    lv_msg = |Collective RFQ { pv_submi } has been APPROVED by { gv_hod_name }. Please create Purchase Orders.|.
  ELSE.
    lv_msg = |Collective RFQ { pv_submi } has been REJECTED by { gv_hod_name }. Reason: { pv_remark }.|.
  ENDIF.

  CALL FUNCTION 'TH_POPUP'
    EXPORTING
      client  = sy-mandt
      user    = lv_creator_user
      message = lv_msg
    EXCEPTIONS
      OTHERS  = 1.

  " 3. Get Creator Email from ADR6 / USR21
  DATA: lv_persno TYPE usr21-persnumber,
        lv_addrno TYPE usr21-addrnumber.
  SELECT SINGLE persnumber, addrnumber FROM usr21
    WHERE bname = @lv_creator_user
    INTO ( @lv_persno, @lv_addrno ).
  IF sy-subrc = 0.
    SELECT SINGLE smtp_addr FROM adr6
      WHERE persnumber = @lv_persno
        AND addrnumber = @lv_addrno
      INTO @lv_creator_email.
    IF sy-subrc <> 0 OR lv_creator_email IS INITIAL.
      SELECT SINGLE smtp_addr FROM adr6
        WHERE persnumber = @lv_persno
        INTO @lv_creator_email.
    ENDIF.
  ENDIF.

  " 4. Send SAP Office Mail to Creator
  DATA: ls_doc_data  TYPE sodocchgi1,
        lt_objtxt    TYPE STANDARD TABLE OF solisti1,
        ls_objtxt    TYPE solisti1,
        lt_receivers TYPE STANDARD TABLE OF somlreci1,
        ls_receiver  TYPE somlreci1.

  ls_doc_data-obj_name  = 'PRICE_DEC'.
  IF pv_status = 'X'.
    ls_doc_data-obj_descr = |Quotation Approval: Collective RFQ { pv_submi } APPROVED|.
  ELSE.
    ls_doc_data-obj_descr = |Quotation Approval: Collective RFQ { pv_submi } REJECTED|.
  ENDIF.
  ls_doc_data-obj_langu = sy-langu.

  ls_objtxt-line = |Dear { lv_creator_user },|.
  APPEND ls_objtxt TO lt_objtxt.
  ls_objtxt-line = space.
  APPEND ls_objtxt TO lt_objtxt.

  IF pv_status = 'X'.
    ls_objtxt-line = |Price comparison for Collective RFQ { pv_submi } has been APPROVED by { gv_hod_name }.|.
    APPEND ls_objtxt TO lt_objtxt.
    ls_objtxt-line = 'You can now proceed with Purchase Order (PO) creation for approved items.'.
    APPEND ls_objtxt TO lt_objtxt.
  ELSE.
    ls_objtxt-line = |Price comparison for Collective RFQ { pv_submi } has been REJECTED by { gv_hod_name }.|.
    APPEND ls_objtxt TO lt_objtxt.
    ls_objtxt-line = |Rejection Reason: { pv_remark }|.
    APPEND ls_objtxt TO lt_objtxt.
    ls_objtxt-line = 'Please update quotation data or dates in ME47 and resend for approval.'.
    APPEND ls_objtxt TO lt_objtxt.
  ENDIF.

  " Send to SAP user inbox
  ls_receiver-receiver = lv_creator_user.
  ls_receiver-rec_type = 'B'. " SAP user
  ls_receiver-express  = 'X'.
  APPEND ls_receiver TO lt_receivers.

  IF lv_creator_email IS NOT INITIAL.
    CLEAR ls_receiver.
    ls_receiver-receiver = lv_creator_email.
    ls_receiver-rec_type = 'U'. " Internet address
    APPEND ls_receiver TO lt_receivers.
  ENDIF.

  CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
    EXPORTING
      document_data              = ls_doc_data
      document_type              = 'RAW'
      put_in_outbox              = 'X'
      commit_work                = 'X'
    TABLES
      object_content             = lt_objtxt
      receivers                  = lt_receivers
    EXCEPTIONS
      OTHERS                     = 1.

ENDFORM.
