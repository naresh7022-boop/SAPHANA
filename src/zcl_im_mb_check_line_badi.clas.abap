CLASS zcl_im_mb_check_line_badi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_ex_mb_check_line_badi .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_im_mb_check_line_badi IMPLEMENTATION.

  METHOD if_ex_mb_check_line_badi~check_line.
    DATA: lv_wbs           TYPE ps_psp_pnr,
          lv_acl_ok        TYPE abap_bool,
          lv_acl_msg       TYPE string,
          lv_plant_allowed TYPE abap_bool,
          lv_plant_msg     TYPE string,
          lv_mat_ok        TYPE abap_bool,
          lv_mat_msg       TYPE string,
          lv_msg_v1        TYPE symsgv,
          lv_msg_v2        TYPE symsgv.

    IF is_mseg-ps_psp_pnr IS NOT INITIAL.
      lv_wbs = is_mseg-ps_psp_pnr.
    ELSEIF is_mseg-mat_pspnr IS NOT INITIAL.
      lv_wbs = is_mseg-mat_pspnr.
    ENDIF.

    IF lv_wbs IS INITIAL.
      RETURN.
    ENDIF.

    " 1. ACL Check: User must have access for WBS in CJ20N ACL Tab
    zcl_ps_wbs_mat_validate=>check_user_wbs_acl(
      EXPORTING
        iv_wbs     = lv_wbs
      IMPORTING
        ev_allowed = lv_acl_ok
        ev_message = lv_acl_msg
    ).

    IF lv_acl_ok = abap_false.
      lv_msg_v1 = lv_acl_msg(50).
      IF strlen( lv_acl_msg ) > 50.
        lv_msg_v2 = lv_acl_msg+50.
      ENDIF.
      MESSAGE e001(00) WITH lv_msg_v1 lv_msg_v2.
      RETURN.
    ENDIF.

    " 2. Plant Check: MIGO item plant must match WBS plant in CJ20N
    IF is_mseg-werks IS NOT INITIAL.
      zcl_ps_wbs_mat_validate=>check_wbs_plant(
        EXPORTING
          iv_wbs     = lv_wbs
          iv_werks   = is_mseg-werks
        IMPORTING
          ev_allowed = lv_plant_allowed
          ev_message = lv_plant_msg
      ).

      IF lv_plant_allowed = abap_false.
        lv_msg_v1 = lv_plant_msg(50).
        IF strlen( lv_plant_msg ) > 50.
          lv_msg_v2 = lv_plant_msg+50.
        ENDIF.
        MESSAGE e001(00) WITH lv_msg_v1 lv_msg_v2.
        RETURN.
      ENDIF.
    ENDIF.

    " 3. Material Allowed Check (Validation applies only to R&D Project Profile)
    IF is_mseg-matnr IS NOT INITIAL.
      zcl_ps_wbs_mat_validate=>check_material_allowed(
        EXPORTING
          iv_wbs      = lv_wbs
          iv_matnr    = is_mseg-matnr
          iv_werks    = is_mseg-werks
          iv_quantity = is_mseg-menge
        IMPORTING
          ev_allowed  = lv_mat_ok
          ev_message  = lv_mat_msg
      ).

      IF lv_mat_ok = abap_false.
        lv_msg_v1 = lv_mat_msg(50).
        IF strlen( lv_mat_msg ) > 50.
          lv_msg_v2 = lv_mat_msg+50.
        ENDIF.
        MESSAGE e001(00) WITH lv_msg_v1 lv_msg_v2.
        RETURN.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.