class ZCL_IM_ZMB_MIGO_BADI definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_MB_MIGO_BADI .

  data IS_MKPF type MKPF .
protected section.
private section.

  data GT_EXTDATA type TY_T_EXTDATA .
  data GT_EXTDATA_MAA type TY_T_EXTDATA .
  constants GF_CLASS_ID type MIGO_CLASS_ID value 'MIGO_BADI_IMPLEMENTATION1' ##NO_TEXT.
  data G_NO_INPUT type XFELD .
  data GS_EXDATA_HEADER type ZMM_T_009 .
  data G_CANCEL type XFELD .
  data G_LINE_ID type GOITEM-GLOBAL_COUNTER .

  TYPES:
    BEGIN OF ty_goitem_cache,
      line_id TYPE mb_line_id,
      item    TYPE goitem,
    END OF ty_goitem_cache,
    ty_t_goitem_cache TYPE HASHED TABLE OF ty_goitem_cache WITH UNIQUE KEY line_id.

  DATA gt_goitem_cache TYPE ty_t_goitem_cache.
ENDCLASS.



CLASS ZCL_IM_ZMB_MIGO_BADI IMPLEMENTATION.


  method IF_EX_MB_MIGO_BADI~CHECK_HEADER.

  endmethod.


  METHOD if_ex_mb_migo_badi~check_item.
    DATA: ls_cache    TYPE ty_goitem_cache,
          lv_wbs      TYPE ps_psp_pnr,
          lv_allowed  TYPE abap_bool,
          lv_message  TYPE string,
          ls_bapiret2 TYPE bapiret2.

    READ TABLE gt_goitem_cache INTO ls_cache WITH TABLE KEY line_id = i_line_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Only validate items with a material number
    IF ls_cache-item-matnr IS INITIAL.
      RETURN.
    ENDIF.

    " Determine WBS element:
    " 1) mat_pspnr  (Special stock WBS for project purchase stock 'Q')
    " 2) ps_psp_pnr (Account assignment WBS, e.g. movement 221 / 281)
    CLEAR lv_wbs.
    IF ls_cache-item-sobkz = 'Q' AND ls_cache-item-mat_pspnr IS NOT INITIAL.
      lv_wbs = ls_cache-item-mat_pspnr.
    ELSEIF ls_cache-item-ps_psp_pnr IS NOT INITIAL.
      lv_wbs = ls_cache-item-ps_psp_pnr.
    ELSEIF ls_cache-item-mat_pspnr IS NOT INITIAL.
      lv_wbs = ls_cache-item-mat_pspnr.
    ENDIF.

    " Validate when:
    " - Special stock indicator is 'Q' (Project Stock), OR
    " - Movement type is project consumption (221, 222, 281, 282), OR
    " - WBS element is populated
    IF ls_cache-item-sobkz = 'Q' OR lv_wbs IS NOT INITIAL.
      IF lv_wbs IS NOT INITIAL.
        zcl_ps_wbs_mat_validate=>check_material_allowed(
          EXPORTING
            iv_wbs      = lv_wbs
            iv_matnr    = ls_cache-item-matnr
            iv_werks    = ls_cache-item-werks
            iv_quantity = ls_cache-item-erfmg
          IMPORTING
            ev_allowed  = lv_allowed
            ev_message  = lv_message
        ).

        IF lv_allowed = abap_false.
          CLEAR ls_bapiret2.
          ls_bapiret2-type       = 'E'.
          ls_bapiret2-id         = '00'.
          ls_bapiret2-number     = '001'.
          ls_bapiret2-message    = lv_message.
          ls_bapiret2-message_v1 = lv_message(50).
          IF strlen( lv_message ) > 50.
            ls_bapiret2-message_v2 = lv_message+50.
          ENDIF.
          ls_bapiret2-parameter  = 'MATNR'.
          ls_bapiret2-row        = i_line_id.
          APPEND ls_bapiret2 TO et_bapiret2.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  method IF_EX_MB_MIGO_BADI~HOLD_DATA_DELETE.
  endmethod.


  method IF_EX_MB_MIGO_BADI~HOLD_DATA_LOAD.
  endmethod.


  method IF_EX_MB_MIGO_BADI~HOLD_DATA_SAVE.
  endmethod.


  method IF_EX_MB_MIGO_BADI~INIT.

*      APPEND gf_class_id TO ct_init.
  endmethod.


  METHOD if_ex_mb_migo_badi~line_delete.
    DELETE TABLE gt_goitem_cache WITH TABLE KEY line_id = i_line_id.
  ENDMETHOD.


  METHOD if_ex_mb_migo_badi~line_modify.
    DATA: ls_cache TYPE ty_goitem_cache.

    ls_cache-line_id = i_line_id.
    ls_cache-item    = cs_goitem.
    MODIFY TABLE gt_goitem_cache FROM ls_cache.
    IF sy-subrc <> 0.
      INSERT ls_cache INTO TABLE gt_goitem_cache.
    ENDIF.
  ENDMETHOD.


  method IF_EX_MB_MIGO_BADI~MAA_LINE_ID_ADJUST.
  endmethod.


  method IF_EX_MB_MIGO_BADI~MODE_SET.
* In case of 'DISPLAY' the global field G_NO_INPUT will be set to 'X'.
* The result is that a different external subscreen will be choosen in
* method PBO_DETAIL.

  IF i_action = 'A04' OR i_action = 'A03'.
    g_no_input = 'X'.
  ENDIF.
* In case of 'CANCEL' the global field G_CANCEL will be set to 'X'.
* The result is that in method POST_DOCUMENT a different handling is
* used
  IF i_action = 'A03'.
    g_cancel = 'X'.
  ENDIF.
  endmethod.


  method IF_EX_MB_MIGO_BADI~PAI_DETAIL.

  endmethod.


  METHOD if_ex_mb_migo_badi~pai_header.
*     Get Header data from external screen:
    gs_exdata_header-mblnr = is_gohead-mblnr.
    gs_exdata_header-mjahr = is_gohead-mjahr.

    CALL FUNCTION 'ZGET_ZMIGO_BADI'
      EXPORTING
        is_gohead  = is_gohead                 " MMIM Enjoy:  Header Data
      IMPORTING
        e_mkpf_ext = gs_exdata_header.


  ENDMETHOD.


  method IF_EX_MB_MIGO_BADI~PBO_DETAIL.

  endmethod.


  METHOD if_ex_mb_migo_badi~pbo_header.
    " This check is obligatory, otherwise the program flow is incorrect
* (If there would be more than one implementation of BAdI MB_MIGO_BADI,
* only one subscreen would be displayed).

    CHECK i_class_id = gf_class_id.
    IF g_no_input IS INITIAL.
      e_heading = 'Gate Entry Details'.
      e_cprog = 'SAPLZMIGO_BADI'(004).
      e_dynnr = '5555'.
    ELSE.
      e_cprog   = 'SAPLZMIGO_BADI'(004).
      e_dynnr   = '0002'.                     "External fields: Input
      e_heading = 'Gate Entry Details'.
    ENDIF.

* Export data to function group (for display on subscreen)

    CALL FUNCTION 'ZSET_ZMIGO_BADI'
      EXPORTING
        i_mkpf_ext = gs_exdata_header
      IMPORTING
        i_mkpf_exp = gs_exdata_header.



  ENDMETHOD.


  METHOD if_ex_mb_migo_badi~post_document.

    gs_exdata_header-mblnr          = is_mkpf-mblnr.
    gs_exdata_header-bldat          = is_mkpf-bldat.
    gs_exdata_header-budat          = is_mkpf-budat.
    gs_exdata_header-cputm          = is_mkpf-cputm.
    gs_exdata_header-usnam          = is_mkpf-usnam.
*    is_mkpf-zzgateentyno = gs_exdata_header-zzgateentyno.

    MODIFY zmm_t_009 FROM gs_exdata_header.
    CLEAR gs_exdata_header.




  ENDMETHOD.


  method IF_EX_MB_MIGO_BADI~PROPOSE_SERIALNUMBERS.
  endmethod.


  method IF_EX_MB_MIGO_BADI~PUBLISH_MATERIAL_ITEM.
  endmethod.


  METHOD if_ex_mb_migo_badi~reset.
    CLEAR: gt_extdata,
           g_no_input,
           gs_exdata_header,
           g_cancel,
           g_line_id,
           gt_goitem_cache.
  ENDMETHOD.


  METHOD if_ex_mb_migo_badi~status_and_header.

*& set gs_exdata_header with custom details
    IF NOT g_no_input IS INITIAL.
      SELECT SINGLE * FROM zmm_t_009 INTO gs_exdata_header
         WHERE mblnr = is_gohead-mblnr
         AND   mjahr = is_gohead-mjahr.
    ENDIF.
  ENDMETHOD.
ENDCLASS.