CLASS zcl_ps_wbs_mat_validate DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    TYPES:
      BEGIN OF ty_result,
        is_allowed   TYPE abap_bool,
        message      TYPE string,
        ps_psp_pnr   TYPE ps_psp_pnr,
        posid        TYPE ps_posid,
        matnr        TYPE matnr,
        werks        TYPE werks_d,
        max_quantity TYPE menge_d,
        meins        TYPE meins,
      END OF ty_result .

    CLASS-METHODS is_rnd_project
      IMPORTING
        !iv_ps_psp_pnr   TYPE ps_psp_pnr
      EXPORTING
        !ev_profl        TYPE proj-profl
        !ev_proftext     TYPE tcj4t-profi_txt
      RETURNING
        VALUE(rv_is_rnd) TYPE abap_bool .

    CLASS-METHODS check_user_wbs_acl
      IMPORTING
        !iv_wbs           TYPE any
        !iv_uname         TYPE sy-uname DEFAULT sy-uname
      EXPORTING
        !ev_allowed       TYPE abap_bool
        !ev_message       TYPE string
        !ev_act_type      TYPE psacl_tab-act_type
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool .

        CLASS-METHODS check_wbs_plant
      IMPORTING
        !iv_wbs           TYPE any
        !iv_werks         TYPE any
      EXPORTING
        !ev_allowed       TYPE abap_bool
        !ev_message       TYPE string
        !ev_wbs_werks     TYPE werks_d
        !ev_posid         TYPE ps_posid
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool .

CLASS-METHODS check_material_allowed
      IMPORTING
        !iv_wbs        TYPE any
        !iv_matnr      TYPE any
        !iv_werks      TYPE werks_d OPTIONAL
        !iv_quantity   TYPE menge_d OPTIONAL
        !iv_date       TYPE dats DEFAULT sy-datum
      EXPORTING
        !ev_allowed    TYPE abap_bool
        !ev_message    TYPE string
        !es_entry      TYPE zwbs_mat_allow
      RETURNING
        VALUE(rs_info) TYPE ty_result .

    CLASS-METHODS add_allowed_material
      IMPORTING
        !iv_wbs          TYPE any
        !iv_matnr        TYPE any
        !iv_werks        TYPE werks_d OPTIONAL
        !iv_allow_flag   TYPE xfeld DEFAULT 'X'
        !iv_valid_from   TYPE dats DEFAULT sy-datum
        !iv_valid_to     TYPE dats DEFAULT '99991231'
        !iv_max_quantity TYPE menge_d OPTIONAL
        !iv_meins        TYPE meins OPTIONAL
        !iv_remarks      TYPE char100 OPTIONAL
      EXPORTING
        !ev_success      TYPE abap_bool
        !ev_message      TYPE string
        !es_entry        TYPE zwbs_mat_allow .

    CLASS-METHODS delete_allowed_material
      IMPORTING
        !iv_wbs     TYPE any
        !iv_matnr   TYPE any
        !iv_werks   TYPE werks_d OPTIONAL
      EXPORTING
        !ev_success TYPE abap_bool
        !ev_message TYPE string .

    CLASS-METHODS convert_wbs_to_internal
      IMPORTING
        !iv_wbs              TYPE any
      RETURNING
        VALUE(rv_ps_psp_pnr) TYPE ps_psp_pnr .

    CLASS-METHODS convert_wbs_to_external
      IMPORTING
        !iv_ps_psp_pnr  TYPE ps_psp_pnr
      RETURNING
        VALUE(rv_posid) TYPE ps_posid .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_ps_wbs_mat_validate IMPLEMENTATION.

  METHOD is_rnd_project.
    DATA: lv_spras TYPE spras.
    CLEAR: rv_is_rnd, ev_profl, ev_proftext.

    IF iv_ps_psp_pnr IS INITIAL.
      rv_is_rnd = abap_false.
      RETURN.
    ENDIF.

    lv_spras = sy-langu.
    IF lv_spras IS INITIAL.
      lv_spras = 'E'.
    ENDIF.

    SELECT SINGLE proj~profl, tcj4t~profi_txt
      FROM prps
      INNER JOIN proj ON prps~psphi = proj~pspnr
      LEFT OUTER JOIN tcj4t ON proj~profl = tcj4t~profidproj AND tcj4t~spras = @lv_spras
      INTO ( @ev_profl, @ev_proftext )
      WHERE prps~pspnr = @iv_ps_psp_pnr.

    IF sy-subrc = 0.
      IF ev_proftext IS INITIAL.
        SELECT SINGLE profi_txt FROM tcj4t INTO @ev_proftext
          WHERE profidproj = @ev_profl AND spras = 'E'.
      ENDIF.

      IF ev_profl = 'RND' OR ev_proftext CS 'R&D' OR ev_proftext CS 'R & D'.
        rv_is_rnd = abap_true.
      ELSE.
        rv_is_rnd = abap_false.
      ENDIF.
    ELSE.
      rv_is_rnd = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD check_user_wbs_acl.
    DATA: lv_ps_psp_pnr TYPE ps_psp_pnr,
          lv_posid      TYPE ps_posid,
          lv_objnr      TYPE prps-objnr,
          lv_psphi      TYPE prps-psphi,
          lv_proj_objnr TYPE proj-objnr,
          lv_uname      TYPE sy-uname,
          lv_act_type   TYPE psacl_tab-act_type,
          lv_acl_count  TYPE i.

    CLEAR: ev_allowed, ev_message, ev_act_type.
    ev_allowed = abap_true.

    " 1. Resolve WBS internal key and external identifier
    lv_ps_psp_pnr = convert_wbs_to_internal( iv_wbs ).
    IF lv_ps_psp_pnr IS INITIAL.
      ev_message = |WBS Element '{ iv_wbs }' is invalid or does not exist.|.
      ev_allowed = abap_false.
      rv_allowed = abap_false.
      RETURN.
    ENDIF.
    lv_posid = convert_wbs_to_external( lv_ps_psp_pnr ).

    " 2. Determine User
    lv_uname = COND #( WHEN iv_uname IS NOT INITIAL THEN iv_uname ELSE sy-uname ).

    " 3. Get WBS OBJNR and Project Definition OBJNR
    SELECT SINGLE objnr, psphi
      FROM prps
      INTO ( @lv_objnr, @lv_psphi )
      WHERE pspnr = @lv_ps_psp_pnr.
    IF sy-subrc <> 0 OR lv_objnr IS INITIAL.
      ev_message = |WBS Element '{ lv_posid }' has no OBJNR in PRPS.|.
      ev_allowed = abap_false.
      rv_allowed = abap_false.
      RETURN.
    ENDIF.

    SELECT SINGLE objnr
      FROM proj
      INTO @lv_proj_objnr
      WHERE pspnr = @lv_psphi.

    " 4. Check if ACL is maintained in CJ20N for this WBS or its Project Definition
    SELECT COUNT(*) FROM psacl_tab
      INTO @lv_acl_count
      WHERE objnr = @lv_objnr OR objnr = @lv_proj_objnr.

    IF lv_acl_count = 0.
      " No ACL entries maintained for this WBS or Project -> Allow
      ev_allowed = abap_true.
      rv_allowed = abap_true.
      ev_message = |No ACL maintained in CJ20N for WBS { lv_posid }.|.
      RETURN.
    ENDIF.

    " 5. Check user authorization in PSACL_TAB
    " First check direct entry on WBS element
    SELECT SINGLE act_type
      FROM psacl_tab
      INTO @lv_act_type
      WHERE objnr = @lv_objnr
        AND auth_user = @lv_uname.

    IF sy-subrc <> 0 AND lv_proj_objnr IS NOT INITIAL.
      " If not on WBS directly, check Project Definition
      SELECT SINGLE act_type
        FROM psacl_tab
        INTO @lv_act_type
        WHERE objnr = @lv_proj_objnr
          AND auth_user = @lv_uname.
    ENDIF.

    " Check by User Group if not directly found by user
    IF lv_act_type IS INITIAL.
      SELECT SINGLE psacl_tab~act_type
        FROM psacl_tab
        INNER JOIN usr02 ON psacl_tab~auth_user_grp = usr02~class
        INTO @lv_act_type
        WHERE ( psacl_tab~objnr = @lv_objnr OR psacl_tab~objnr = @lv_proj_objnr )
          AND psacl_tab~auth_user_grp IS NOT NULL
          AND psacl_tab~auth_user_grp <> @space
          AND usr02~class <> @space
          AND usr02~bname = @lv_uname
          AND psacl_tab~act_type > '1'.
    ENDIF.

    ev_act_type = lv_act_type.

    " 6. Evaluate access
    IF lv_act_type IS INITIAL OR lv_act_type = '1'.
      ev_allowed = abap_false.
      rv_allowed = abap_false.
      ev_message = |User '{ lv_uname }' has no access for WBS Element '{ lv_posid }' in CJ20N ACL.|.
      RETURN.
    ENDIF.

    ev_allowed = abap_true.
    rv_allowed = abap_true.
    ev_message = |User '{ lv_uname }' is authorized (Access Level { lv_act_type }) for WBS Element '{ lv_posid }'.|.
  ENDMETHOD.

  METHOD check_wbs_plant.
    DATA: lv_ps_psp_pnr TYPE ps_psp_pnr,
          lv_posid      TYPE ps_posid,
          lv_wbs_werks  TYPE prps-werks,
          lv_psphi      TYPE prps-psphi,
          lv_proj_werks TYPE proj-werks,
          lv_in_werks   TYPE werks_d.

    CLEAR: ev_allowed, ev_message, ev_wbs_werks, ev_posid, rv_allowed.
    ev_allowed = abap_true.
    rv_allowed = abap_true.

    IF iv_wbs IS INITIAL.
      RETURN.
    ENDIF.

    lv_in_werks = iv_werks.

    " 1. Resolve WBS internal key and external identifier
    lv_ps_psp_pnr = convert_wbs_to_internal( iv_wbs ).
    IF lv_ps_psp_pnr IS INITIAL.
      ev_message = |WBS Element '{ iv_wbs }' is invalid or does not exist.|.
      ev_allowed = abap_false.
      rv_allowed = abap_false.
      RETURN.
    ENDIF.
    lv_posid = convert_wbs_to_external( lv_ps_psp_pnr ).
    ev_posid = lv_posid.

    " 2. Get WBS Plant from PRPS
    SELECT SINGLE werks, psphi
      FROM prps
      WHERE pspnr = @lv_ps_psp_pnr
      INTO ( @lv_wbs_werks, @lv_psphi ).

    " If WBS plant is initial, check Project Definition plant (PROJ-WERKS)
    IF lv_wbs_werks IS INITIAL AND lv_psphi IS NOT INITIAL.
      SELECT SINGLE werks
        FROM proj
        WHERE pspnr = @lv_psphi
        INTO @lv_proj_werks.
      IF sy-subrc = 0 AND lv_proj_werks IS NOT INITIAL.
        lv_wbs_werks = lv_proj_werks.
      ENDIF.
    ENDIF.

    ev_wbs_werks = lv_wbs_werks.

    " 3. If no plant mapped in CJ20N for this WBS/Project, do not restrict
    IF lv_wbs_werks IS INITIAL.
      ev_allowed = abap_true.
      rv_allowed = abap_true.
      ev_message = |No plant mapped in CJ20N for WBS '{ lv_posid }'.|.
      RETURN.
    ENDIF.

    " 4. If transaction plant is not passed, cannot validate against it
    IF lv_in_werks IS INITIAL.
      ev_allowed = abap_true.
      rv_allowed = abap_true.
      RETURN.
    ENDIF.

    " 5. Check match
    IF lv_in_werks <> lv_wbs_werks.
      ev_allowed = abap_false.
      rv_allowed = abap_false.
      ev_message = |Plant '{ lv_in_werks }' not allowed. WBS '{ lv_posid }' is mapped to Plant '{ lv_wbs_werks }' in CJ20N.|.
    ELSE.
      ev_allowed = abap_true.
      rv_allowed = abap_true.
      ev_message = |Plant '{ lv_in_werks }' matches CJ20N mapped plant for WBS '{ lv_posid }'.|.
    ENDIF.
  ENDMETHOD.

  METHOD convert_wbs_to_internal.
    DATA: lv_input TYPE string,
          lv_posnr TYPE ps_posnr,
          lv_num   TYPE ps_psp_pnr.

    CLEAR rv_ps_psp_pnr.
    IF iv_wbs IS INITIAL.
      RETURN.
    ENDIF.

    lv_input = iv_wbs.
    CONDENSE lv_input.

    " 1. If numeric (internal PSPNR: e.g. 00000795 or 795)
    IF lv_input CO '0123456789' AND strlen( lv_input ) <= 8.
      lv_num = |{ lv_input ALPHA = IN }|.
      SELECT SINGLE pspnr FROM prps INTO rv_ps_psp_pnr
        WHERE pspnr = lv_num.
      IF sy-subrc = 0 AND rv_ps_psp_pnr IS NOT INITIAL.
        RETURN.
      ENDIF.
    ENDIF.

    " 2. Try standard conversion exit for external WBS (e.g. RD-TEST1)
    CALL FUNCTION 'CONVERSION_EXIT_ABPSP_INPUT'
      EXPORTING
        input  = lv_input
      IMPORTING
        output = lv_posnr
      EXCEPTIONS
        OTHERS = 1.

    IF sy-subrc = 0 AND lv_posnr IS NOT INITIAL.
      rv_ps_psp_pnr = lv_posnr.
      RETURN.
    ENDIF.

    " 3. Direct lookup in PRPS by POSID
    SELECT SINGLE pspnr FROM prps INTO rv_ps_psp_pnr
      WHERE posid = lv_input.
    IF sy-subrc = 0 AND rv_ps_psp_pnr IS NOT INITIAL.
      RETURN.
    ENDIF.

    " 4. Uppercase lookup in PRPS by POSID
    DATA(lv_upper) = to_upper( lv_input ).
    SELECT SINGLE pspnr FROM prps INTO rv_ps_psp_pnr
      WHERE posid = lv_upper.
  ENDMETHOD.

  METHOD convert_wbs_to_external.
    DATA: lv_posid TYPE ps_posid.
    CLEAR rv_posid.
    IF iv_ps_psp_pnr IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE posid FROM prps INTO lv_posid
      WHERE pspnr = iv_ps_psp_pnr.
    IF sy-subrc = 0 AND lv_posid IS NOT INITIAL.
      rv_posid = lv_posid.
      RETURN.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
      EXPORTING
        input  = iv_ps_psp_pnr
      IMPORTING
        output = rv_posid
      EXCEPTIONS
        OTHERS = 1.
  ENDMETHOD.

  METHOD add_allowed_material.
    DATA: lv_ps_psp_pnr TYPE ps_psp_pnr,
          lv_posid      TYPE ps_posid,
          lv_matnr      TYPE matnr,
          lv_mat_input  TYPE string,
          ls_entry_db   TYPE zwbs_mat_allow,
          lv_meins      TYPE meins,
          lv_mat_disp   TYPE string,
          lv_profl      TYPE proj-profl,
          lv_proftext   TYPE tcj4t-profi_txt.

    CLEAR: ev_success, ev_message, es_entry.
    ev_success = abap_false.

    " 1. Resolve and Validate WBS Element
    lv_ps_psp_pnr = convert_wbs_to_internal( iv_wbs ).
    IF lv_ps_psp_pnr IS INITIAL.
      ev_message = |WBS Element '{ iv_wbs }' not found in PRPS.|.
      RETURN.
    ENDIF.
    lv_posid = convert_wbs_to_external( lv_ps_psp_pnr ).

    " 2. Validate Project Profile (CJ20N): Must belong to R&D Project Profile
    IF is_rnd_project(
         EXPORTING
           iv_ps_psp_pnr = lv_ps_psp_pnr
         IMPORTING
           ev_profl      = lv_profl
           ev_proftext   = lv_proftext
       ) = abap_false.
      ev_message = |WBS Element '{ lv_posid }' has Project Profile '{ lv_profl }' ({ lv_proftext }). Material mapping is only applicable for R&D projects.|.
      RETURN.
    ENDIF.

    " 3. Format and Validate Material Number
    lv_mat_input = iv_matnr.
    CONDENSE lv_mat_input.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = lv_mat_input
      IMPORTING
        output       = lv_matnr
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.
    IF sy-subrc <> 0 OR lv_matnr IS INITIAL.
      lv_matnr = iv_matnr.
    ENDIF.

    SELECT SINGLE meins FROM mara INTO lv_meins
      WHERE matnr = lv_matnr.
    IF sy-subrc <> 0.
      lv_mat_disp = |{ lv_matnr ALPHA = OUT }|.
      CONDENSE lv_mat_disp.
      ev_message = |Material '{ lv_mat_disp }' not found in MARA master.|.
      RETURN.
    ENDIF.

    IF iv_meins IS NOT INITIAL.
      lv_meins = iv_meins.
    ENDIF.

    " 4. Build Record
    es_entry-mandt        = sy-mandt.
    es_entry-ps_psp_pnr   = lv_ps_psp_pnr.
    es_entry-matnr        = lv_matnr.
    es_entry-werks        = iv_werks.
    es_entry-posid        = lv_posid.
    es_entry-allow_flag   = COND #( WHEN iv_allow_flag IS NOT INITIAL THEN iv_allow_flag ELSE 'X' ).
    es_entry-valid_from   = COND #( WHEN iv_valid_from IS NOT INITIAL THEN iv_valid_from ELSE sy-datum ).
    es_entry-valid_to     = COND #( WHEN iv_valid_to IS NOT INITIAL THEN iv_valid_to ELSE '99991231' ).
    es_entry-max_quantity = iv_max_quantity.
    es_entry-meins        = lv_meins.
    es_entry-remarks      = iv_remarks.

    " Check if entry already exists (Audit info preservation)
    SELECT SINGLE * FROM zwbs_mat_allow INTO ls_entry_db
      WHERE ps_psp_pnr = lv_ps_psp_pnr
        AND matnr      = lv_matnr
        AND werks      = iv_werks.
    IF sy-subrc = 0.
      es_entry-ernam = ls_entry_db-ernam.
      es_entry-erdat = ls_entry_db-erdat.
      es_entry-erzet = ls_entry_db-erzet.
      es_entry-aenam = sy-uname.
      es_entry-aedat = sy-datum.
      es_entry-aezet = sy-uzeit.
    ELSE.
      es_entry-ernam = sy-uname.
      es_entry-erdat = sy-datum.
      es_entry-erzet = sy-uzeit.
    ENDIF.

    MODIFY zwbs_mat_allow FROM es_entry.
    lv_mat_disp = |{ lv_matnr ALPHA = OUT }|.
    CONDENSE lv_mat_disp.
    IF sy-subrc = 0.
      COMMIT WORK.
      ev_success = abap_true.
      ev_message = |Material { lv_mat_disp } successfully added/updated for WBS { lv_posid }.|.
    ELSE.
      ROLLBACK WORK.
      ev_message = |Database insert failed for WBS { lv_posid } and Material { lv_mat_disp }.|.
    ENDIF.
  ENDMETHOD.

  METHOD delete_allowed_material.
    DATA: lv_ps_psp_pnr TYPE ps_psp_pnr,
          lv_matnr      TYPE matnr,
          lv_mat_input  TYPE string,
          lv_mat_disp   TYPE string.

    CLEAR: ev_success, ev_message.
    ev_success = abap_false.

    lv_ps_psp_pnr = convert_wbs_to_internal( iv_wbs ).
    IF lv_ps_psp_pnr IS INITIAL.
      ev_message = |WBS Element '{ iv_wbs }' not found in PRPS.|.
      RETURN.
    ENDIF.

    lv_mat_input = iv_matnr.
    CONDENSE lv_mat_input.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = lv_mat_input
      IMPORTING
        output       = lv_matnr
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.
    IF sy-subrc <> 0 OR lv_matnr IS INITIAL.
      lv_matnr = iv_matnr.
    ENDIF.

    DELETE FROM zwbs_mat_allow
      WHERE ps_psp_pnr = lv_ps_psp_pnr
        AND matnr      = lv_matnr
        AND werks      = iv_werks.

    lv_mat_disp = |{ lv_matnr ALPHA = OUT }|.
    CONDENSE lv_mat_disp.
    IF sy-subrc = 0.
      COMMIT WORK.
      ev_success = abap_true.
      ev_message = |Record deleted successfully for WBS { iv_wbs } and Material { lv_mat_disp }.|.
    ELSE.
      ev_message = |Record not found to delete.|.
    ENDIF.
  ENDMETHOD.

  METHOD check_material_allowed.
    DATA: lv_ps_psp_pnr TYPE ps_psp_pnr,
          lv_matnr      TYPE matnr,
          lv_posid      TYPE ps_posid,
          ls_allow      TYPE zwbs_mat_allow,
          lv_mat_input  TYPE string,
          lv_mat_disp   TYPE string,
          lv_profl      TYPE proj-profl,
          lv_proftext   TYPE tcj4t-profi_txt.

    CLEAR: ev_allowed, ev_message, es_entry, rs_info.
    ev_allowed = abap_false.

    " 1. Resolve WBS internal key and external identifier
    lv_ps_psp_pnr = convert_wbs_to_internal( iv_wbs ).
    IF lv_ps_psp_pnr IS INITIAL.
      ev_message = |WBS Element '{ iv_wbs }' is invalid or does not exist in PRPS.|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      RETURN.
    ENDIF.
    lv_posid = convert_wbs_to_external( lv_ps_psp_pnr ).

    " 2. Format Material Number
    lv_mat_input = iv_matnr.
    CONDENSE lv_mat_input.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = lv_mat_input
      IMPORTING
        output       = lv_matnr
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.
    IF sy-subrc <> 0 OR lv_matnr IS INITIAL.
      lv_matnr = iv_matnr.
    ENDIF.

    lv_mat_disp = |{ lv_matnr ALPHA = OUT }|.
    CONDENSE lv_mat_disp.

    " 3. Project Profile Check (Maintained in CJ20N Project Builder)
    " Validation applies ONLY for R&D Project Profile, NOT for other profiles.
    IF is_rnd_project(
         EXPORTING
           iv_ps_psp_pnr = lv_ps_psp_pnr
         IMPORTING
           ev_profl      = lv_profl
           ev_proftext   = lv_proftext
       ) = abap_false.
      ev_allowed = abap_true.
      ev_message = |Project Profile '{ lv_profl }' is not an R&D Profile; validation bypassed for WBS { lv_posid }.|.
      rs_info-is_allowed = abap_true.
      rs_info-message    = ev_message.
      rs_info-ps_psp_pnr = lv_ps_psp_pnr.
      rs_info-posid      = lv_posid.
      rs_info-matnr      = lv_matnr.
      rs_info-werks      = iv_werks.
      RETURN.
    ENDIF.

    " 4. R&D Project Profile: Validate against ZWBS_MAT_ALLOW
    IF iv_werks IS NOT INITIAL.
      SELECT SINGLE * FROM zwbs_mat_allow INTO ls_allow
        WHERE ps_psp_pnr = lv_ps_psp_pnr
          AND matnr      = lv_matnr
          AND werks      = iv_werks.
    ENDIF.

    IF ls_allow IS INITIAL.
      SELECT SINGLE * FROM zwbs_mat_allow INTO ls_allow
        WHERE ps_psp_pnr = lv_ps_psp_pnr
          AND matnr      = lv_matnr
          AND werks      = space.
    ENDIF.

    IF ls_allow IS INITIAL.
      ev_allowed = abap_false.
      ev_message = |Material { lv_mat_disp } is NOT allowed for WBS { lv_posid }.|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      rs_info-ps_psp_pnr = lv_ps_psp_pnr.
      rs_info-posid      = lv_posid.
      rs_info-matnr      = lv_matnr.
      rs_info-werks      = iv_werks.
      RETURN.
    ENDIF.

    IF ls_allow-allow_flag <> 'X'.
      ev_allowed = abap_false.
      ev_message = |Material { lv_mat_disp } is blocked/inactive for WBS { lv_posid }.|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      RETURN.
    ENDIF.

    IF ls_allow-valid_from IS NOT INITIAL AND iv_date < ls_allow-valid_from.
      ev_allowed = abap_false.
      ev_message = |Material { lv_mat_disp } not yet valid for WBS { lv_posid } (Valid from: { ls_allow-valid_from DATE = USER }).|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      RETURN.
    ENDIF.

    IF ls_allow-valid_to IS NOT INITIAL AND iv_date > ls_allow-valid_to.
      ev_allowed = abap_false.
      ev_message = |Material { lv_mat_disp } validity expired for WBS { lv_posid } (Valid to: { ls_allow-valid_to DATE = USER }).|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      RETURN.
    ENDIF.

    IF ls_allow-max_quantity > 0 AND iv_quantity > 0.
      IF iv_quantity > ls_allow-max_quantity.
        ev_allowed = abap_false.
        ev_message = |Quantity { iv_quantity } exceeds max allowed limit ({ ls_allow-max_quantity } { ls_allow-meins }) for WBS { lv_posid }.|.
        rs_info-is_allowed = abap_false.
        rs_info-message    = ev_message.
        RETURN.
      ENDIF.
    ENDIF.

    ev_allowed = abap_true.
    ev_message = |Material { lv_mat_disp } is allowed for WBS { lv_posid }.|.
    es_entry   = ls_allow.

    rs_info-is_allowed   = abap_true.
    rs_info-message      = ev_message.
    rs_info-ps_psp_pnr   = lv_ps_psp_pnr.
    rs_info-posid        = lv_posid.
    rs_info-matnr        = lv_matnr.
    rs_info-werks        = ls_allow-werks.
    rs_info-max_quantity = ls_allow-max_quantity.
    rs_info-meins        = ls_allow-meins.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
  ENDMETHOD.

ENDCLASS.
