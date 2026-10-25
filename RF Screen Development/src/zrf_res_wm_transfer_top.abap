*&---------------------------------------------------------------------*
*& Include: ZRF_RES_WM_TRANSFER_TOP
*& Description: Global data declarations, screen structures, and constants
*&---------------------------------------------------------------------*
PROGRAM sapmzrf_res_wm_transfer.

" -------------------------------------------------------------
" SCREEN 0100 STRUCTURE
" -------------------------------------------------------------
TYPES:
  BEGIN OF ty_scr0100,
    lgnum     TYPE lgnum,
    rad_res   TYPE char1,
    rad_tr    TYPE char1,
    doc_num   TYPE char10,
    msg       TYPE char40,
  END OF ty_scr0100.

" -------------------------------------------------------------
" SCREEN 0200 STRUCTURE
" -------------------------------------------------------------
TYPES:
  BEGIN OF ty_scr0200,
    doc_type     TYPE char3,
    doc_num      TYPE char10,
    item_curr    TYPE i,
    item_total   TYPE i,
    item_no      TYPE posnr,
    matnr        TYPE matnr,
    maktx        TYPE char20,
    werks        TYPE werks_d,
    lgort        TYPE lgort_d,
    bwart        TYPE bwart,
    target_qty   TYPE menge_d,
    open_qty     TYPE menge_d,
    meins        TYPE meins,
    exidv_scan   TYPE exidv,
    charg_disp   TYPE charg_d,
    ser_count    TYPE i,
    vltyp_disp   TYPE lgtyp,
    vlpla_disp   TYPE lgpla,
    lenum_disp   TYPE lenum,
    post_qty     TYPE menge_d,
    status_msg   TYPE char40,
  END OF ty_scr0200.

" -------------------------------------------------------------
" GLOBAL DATA OBJECTS
" -------------------------------------------------------------
DATA:
  g_scr0100   TYPE ty_scr0100,
  g_scr0200   TYPE ty_scr0200,
  ok_code     TYPE sy-ucomm,
  save_ok     TYPE sy-ucomm,
  gv_cursor   TYPE char30.

" Backend Controller Instance
DATA:
  go_controller  TYPE REF TO zcl_rf_auto_wm_im_transfer,
  gs_header      TYPE zcl_rf_auto_wm_im_transfer=>ty_rf_doc_header,
  gt_items       TYPE zcl_rf_auto_wm_im_transfer=>tt_rf_doc_item,
  gs_curr_item   TYPE zcl_rf_auto_wm_im_transfer=>ty_rf_doc_item,
  gs_hu_info     TYPE zcl_rf_auto_wm_im_transfer=>ty_hu_stock_info,
  gv_item_idx    TYPE i VALUE 1.

CONSTANTS:
  c_fcode_enter  TYPE sy-ucomm VALUE 'ENTR',
  c_fcode_post   TYPE sy-ucomm VALUE 'POST',
  c_fcode_next   TYPE sy-ucomm VALUE 'NEXT',
  c_fcode_prev   TYPE sy-ucomm VALUE 'PREV',
  c_fcode_back   TYPE sy-ucomm VALUE 'BACK',
  c_fcode_canc   TYPE sy-ucomm VALUE 'CANC',
  c_fcode_exit   TYPE sy-ucomm VALUE 'EXIT',
  c_fcode_clear  TYPE sy-ucomm VALUE 'CLEA',
  c_fcode_serials TYPE sy-ucomm VALUE 'SERN',
  c_fcode_bins   TYPE sy-ucomm VALUE 'BINS'.
