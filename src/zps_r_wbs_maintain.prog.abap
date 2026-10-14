*&---------------------------------------------------------------------*
*& Report ZPS_R_WBS_MAINTAIN
*& Purpose: Maintain and Test Allowed Materials for WBS Elements
*& System:  SAP S/4HANA (DS4 / Client 220)
*& Author:  NARESH
*&---------------------------------------------------------------------*
REPORT zps_r_wbs_maintain.

TABLES: prps, mara, marc, zwbs_mat_allow.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b_mode WITH FRAME TITLE TEXT-001.
  PARAMETERS: rb_disp RADIOBUTTON GROUP grp1 DEFAULT 'X' USER-COMMAND u_mode,
              rb_add  RADIOBUTTON GROUP grp1,
              rb_del  RADIOBUTTON GROUP grp1,
              rb_test RADIOBUTTON GROUP grp1.
SELECTION-SCREEN END OF BLOCK b_mode.

SELECTION-SCREEN BEGIN OF BLOCK b_input WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_wbs   TYPE prps-posid OBLIGATORY,
              p_matnr TYPE mara-matnr,
              p_werks TYPE marc-werks.
SELECTION-SCREEN END OF BLOCK b_input.

SELECTION-SCREEN BEGIN OF BLOCK b_detail WITH FRAME TITLE TEXT-003.
  PARAMETERS: p_allow TYPE xfeld DEFAULT 'X',
              p_vfrom TYPE dats DEFAULT sy-datum,
              p_vto   TYPE dats DEFAULT '99991231',
              p_qty   TYPE menge_d,
              p_meins TYPE meins,
              p_rem   TYPE char100.
SELECTION-SCREEN END OF BLOCK b_detail.

*----------------------------------------------------------------------*
* Initialization
*----------------------------------------------------------------------*
INITIALIZATION.
  %_rb_disp_%_app_%-text = 'Display Allowed (ALV)'.
  %_rb_add_%_app_%-text  = 'Add or Update Entry'.
  %_rb_del_%_app_%-text  = 'Delete Material Entry'.
  %_rb_test_%_app_%-text = 'Test WBS Validation'.
  %_p_wbs_%_app_%-text   = 'WBS Element'.
  %_p_matnr_%_app_%-text = 'Material Number'.
  %_p_werks_%_app_%-text = 'Plant'.
  %_p_allow_%_app_%-text = 'Allowed Flag (X=Yes)'.
  %_p_vfrom_%_app_%-text = 'Valid From Date'.
  %_p_vto_%_app_%-text   = 'Valid To Date'.
  %_p_qty_%_app_%-text   = 'Max Quantity Limit'.
  %_p_meins_%_app_%-text = 'Unit of Measure'.
  %_p_rem_%_app_%-text   = 'Remarks Note'.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.

  DATA: lv_ok  TYPE abap_bool,
        lv_msg TYPE string,
        ls_rec TYPE zwbs_mat_allow.

  CASE abap_true.

    " Mode 1: Add or Update Entry
    WHEN rb_add.
      IF p_matnr IS INITIAL.
        MESSAGE 'Please enter Material Number to add.' TYPE 'E'.
        RETURN.
      ENDIF.

      zcl_ps_wbs_mat_validate=>add_allowed_material(
        EXPORTING
          iv_wbs          = p_wbs
          iv_matnr        = p_matnr
          iv_werks        = p_werks
          iv_allow_flag   = p_allow
          iv_valid_from   = p_vfrom
          iv_valid_to     = p_vto
          iv_max_quantity = p_qty
          iv_meins        = p_meins
          iv_remarks      = p_rem
        IMPORTING
          ev_success      = lv_ok
          ev_message      = lv_msg
          es_entry        = ls_rec
      ).

      IF lv_ok = abap_true.
        MESSAGE lv_msg TYPE 'S'.
        WRITE: / 'SUCCESS:' COLOR COL_POSITIVE, lv_msg.
        WRITE: / |WBS Internal: { ls_rec-ps_psp_pnr } - External: { ls_rec-posid }|.
        WRITE: / |Material: { ls_rec-matnr ALPHA = OUT } - Plant: { ls_rec-werks }|.
        WRITE: / |Valid: { ls_rec-valid_from DATE = USER } to { ls_rec-valid_to DATE = USER }|.
        IF ls_rec-max_quantity > 0.
          WRITE: / |Max Qty: { ls_rec-max_quantity } { ls_rec-meins }|.
        ENDIF.
      ELSE.
        MESSAGE lv_msg TYPE 'E'.
      ENDIF.

    " Mode 2: Delete Entry
    WHEN rb_del.
      IF p_matnr IS INITIAL.
        MESSAGE 'Please enter Material Number to delete.' TYPE 'E'.
        RETURN.
      ENDIF.

      zcl_ps_wbs_mat_validate=>delete_allowed_material(
        EXPORTING
          iv_wbs     = p_wbs
          iv_matnr   = p_matnr
          iv_werks   = p_werks
        IMPORTING
          ev_success = lv_ok
          ev_message = lv_msg
      ).

      IF lv_ok = abap_true.
        MESSAGE lv_msg TYPE 'S'.
        WRITE: / 'DELETED:' COLOR COL_NEGATIVE, lv_msg.
      ELSE.
        MESSAGE lv_msg TYPE 'E'.
      ENDIF.

    " Mode 3: Test Validation
    WHEN rb_test.
      IF p_matnr IS INITIAL.
        MESSAGE 'Please enter Material Number to test.' TYPE 'E'.
        RETURN.
      ENDIF.

      zcl_ps_wbs_mat_validate=>check_material_allowed(
        EXPORTING
          iv_wbs      = p_wbs
          iv_matnr    = p_matnr
          iv_werks    = p_werks
          iv_quantity = p_qty
        IMPORTING
          ev_allowed  = lv_ok
          ev_message  = lv_msg
          es_entry    = ls_rec
      ).

      SKIP 1.
      WRITE: / '--------------------------------------------------'.
      WRITE: / '  MATERIAL ALLOWANCE VALIDATION RESULT             ' COLOR COL_HEADING.
      WRITE: / '--------------------------------------------------'.
      IF lv_ok = abap_true.
        WRITE: / 'STATUS: ALLOWED' COLOR COL_POSITIVE INTENSIFIED.
      ELSE.
        WRITE: / 'STATUS: BLOCKED / NOT ALLOWED' COLOR COL_NEGATIVE INTENSIFIED.
      ENDIF.
      WRITE: / 'Message:', lv_msg.
      WRITE: / '--------------------------------------------------'.

    " Mode 4: Display ALV List
    WHEN rb_disp.
      PERFORM display_alv_list.

  ENDCASE.

*&---------------------------------------------------------------------*
*& Form display_alv_list
*&---------------------------------------------------------------------*
FORM display_alv_list.
  DATA: lv_posnr TYPE ps_posnr.

  lv_posnr = zcl_ps_wbs_mat_validate=>convert_wbs_to_internal( p_wbs ).

  SELECT z~ps_psp_pnr,
         z~posid,
         p~post1 AS wbs_name,
         z~matnr,
         m~maktx AS mat_desc,
         z~werks,
         w~name1 AS werks_name,
         z~allow_flag,
         z~valid_from,
         z~valid_to,
         z~max_quantity,
         z~meins,
         z~remarks,
         z~ernam,
         z~erdat,
         z~aenam,
         z~aedat
    FROM zwbs_mat_allow AS z
    LEFT JOIN prps AS p ON p~pspnr = z~ps_psp_pnr
    LEFT JOIN makt AS m ON m~matnr = z~matnr AND m~spras = @sy-langu
    LEFT JOIN t001w AS w ON w~werks = z~werks
    WHERE ( z~ps_psp_pnr = @lv_posnr OR @p_wbs IS INITIAL )
      AND ( z~matnr = @p_matnr OR @p_matnr IS INITIAL )
      AND ( z~werks = @p_werks OR @p_werks IS INITIAL )
    INTO TABLE @DATA(lt_output).

  IF lt_output IS INITIAL.
    MESSAGE 'No records found for the given criteria.' TYPE 'S' DISPLAY LIKE 'W'.
    WRITE: / 'No records found in ZWBS_MAT_ALLOW for given criteria.' COLOR COL_TOTAL.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = DATA(lo_salv)
        CHANGING
          t_table      = lt_output
      ).

      lo_salv->get_functions( )->set_all( abap_true ).
      lo_salv->get_columns( )->set_optimize( abap_true ).

      DATA(lo_cols) = lo_salv->get_columns( ).
      TRY.
          lo_cols->get_column( 'WBS_NAME' )->set_short_text( 'WBS Desc' ).
          lo_cols->get_column( 'MAT_DESC' )->set_short_text( 'Mat Desc' ).
          lo_cols->get_column( 'WERKS_NAME' )->set_short_text( 'Plant Desc' ).
        CATCH cx_salv_not_found.
      ENDTRY.

      lo_salv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.
