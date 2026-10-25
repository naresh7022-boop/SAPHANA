*&---------------------------------------------------------------------*
*& Report ZCREATE_TCODE_ZRF_RESWM
*& Purpose: Create Dynpros 0100 & 0200 for Module Pool SAPMZRF_RES_WM_TRANSFER
*&          and register Transaction Codes ZRF_RESWM and ZRF01
*&          with CINFO = '00' (Dialog Transaction).
*& Author:  SAP Techno-Functional Architect
*& Package: $TMP
*&---------------------------------------------------------------------*
REPORT zcreate_tcode_zrf_reswm.

DATA: lv_prog     TYPE trdir-name VALUE 'SAPMZRF_RES_WM_TRANSFER',
      lv_alt_prog TYPE trdir-name VALUE 'ZRF_RES_WM_TRANSFER',
      ls_tstc     TYPE tstc,
      ls_tstct    TYPE tstct,
      ls_tstcc    TYPE tstcc.

START-OF-SELECTION.

  " Verify if program exists under either name
  SELECT SINGLE name FROM trdir INTO @DATA(lv_found_prog)
    WHERE name = @lv_prog.
  IF sy-subrc <> 0.
    SELECT SINGLE name FROM trdir INTO @lv_found_prog
      WHERE name = @lv_alt_prog.
    IF sy-subrc = 0.
      lv_prog = lv_alt_prog.
    ENDIF.
  ENDIF.

  WRITE: / '========================================================='.
  WRITE: / 'Target Module Pool Program:', lv_prog.
  WRITE: / '========================================================='.

  " -------------------------------------------------------------
  " 0. Setup CUA Interface (GUI Statuses and Titles)
  " -------------------------------------------------------------
  PERFORM setup_cua_interface USING lv_prog.


  " -------------------------------------------------------------
  " 1. Create and Compile Dynpro 0100 (Selection Screen)
  " -------------------------------------------------------------
  PERFORM create_screen_0100 USING lv_prog.

  " -------------------------------------------------------------
  " 2. Create and Compile Dynpro 0200 (Item Processing Screen)
  " -------------------------------------------------------------
  PERFORM create_screen_0200 USING lv_prog.

  " -------------------------------------------------------------
  " 3. Register Primary Transaction: ZRF_RESWM (Dialog Transaction)
  " -------------------------------------------------------------
  CLEAR: ls_tstc, ls_tstct, ls_tstcc.

  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZRF_RESWM'.
  IF sy-subrc <> 0.
    ls_tstc-tcode = 'ZRF_RESWM'.
  ENDIF.
  ls_tstc-pgmna = lv_prog.
  ls_tstc-dypno = '0100'.
  ls_tstc-cinfo = '00'. " Bit 80 cleared = Dialog transaction (NOT report/selection-screen)
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = sy-langu.
  ls_tstct-tcode = 'ZRF_RESWM'.
  ls_tstct-ttext = 'RF Reservation to WM Transfer'.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = 'E'.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  SELECT SINGLE * FROM tstcc INTO ls_tstcc WHERE tcode = 'ZRF_RESWM'.
  IF sy-subrc <> 0.
    ls_tstcc-tcode = 'ZRF_RESWM'.
  ENDIF.
  ls_tstcc-s_webgui = '1'. " Enabled for WebGUI / ITSmobile
  ls_tstcc-s_win32  = 'X'. " SAP GUI for Windows
  ls_tstcc-s_platin = 'X'. " SAP GUI for Java / macOS
  ls_tstcc-s_dummy  = 'X'.
  ls_tstcc-s_dummy1 = 'X'.
  MODIFY tstcc FROM ls_tstcc.

  " -------------------------------------------------------------
  " 4. Register Quick Short Code: ZRF01 (Dialog Transaction)
  " -------------------------------------------------------------
  CLEAR: ls_tstc, ls_tstct, ls_tstcc.

  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZRF01'.
  IF sy-subrc <> 0.
    ls_tstc-tcode = 'ZRF01'.
  ENDIF.
  ls_tstc-pgmna = lv_prog.
  ls_tstc-dypno = '0100'.
  ls_tstc-cinfo = '00'. " Dialog transaction
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = 'E'.
  ls_tstct-tcode = 'ZRF01'.
  ls_tstct-ttext = 'RF Scanner: Res to WM Transfer'.
  MODIFY tstct FROM ls_tstct.

  SELECT SINGLE * FROM tstcc INTO ls_tstcc WHERE tcode = 'ZRF01'.
  IF sy-subrc <> 0.
    ls_tstcc-tcode = 'ZRF01'.
  ENDIF.
  ls_tstcc-s_webgui = '1'.
  ls_tstcc-s_win32  = 'X'.
  ls_tstcc-s_platin = 'X'.
  ls_tstcc-s_dummy  = 'X'.
  ls_tstcc-s_dummy1 = 'X'.
  MODIFY tstcc FROM ls_tstcc.

  " -------------------------------------------------------------
  " 5. Reset Shared Memory Buffers for TSTC & TSTCC
  " -------------------------------------------------------------
  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING
      tabname = 'TSTC'.

  CALL FUNCTION 'SBUF_RESET_BUFFERED_TABLE'
    EXPORTING
      tabname = 'TSTCC'.

  COMMIT WORK AND WAIT.

  WRITE: / '---------------------------------------------------------'.
  WRITE: / 'SUCCESS: Dynpros compiled and Transactions updated!'.
  WRITE: / '---------------------------------------------------------'.
  WRITE: / 'Primary TCODE : ZRF_RESWM  (CINFO = 00 - Dialog Transaction)'.
  WRITE: / 'Short Code    : ZRF01      (CINFO = 00 - Dialog Transaction)'.
  WRITE: / 'Target Program: ', lv_prog.
  WRITE: / 'Initial Screen: 0100'.
  WRITE: / '---------------------------------------------------------'.

*&---------------------------------------------------------------------*
*& Form ADD_TEXT_FIELD
*&---------------------------------------------------------------------*
FORM add_text_field
  TABLES ct_fields TYPE dyfatc_tab
  USING  iv_name   TYPE scrfname
         iv_text   TYPE scrfstxg
         iv_line   TYPE scrnline
         iv_col    TYPE scrncoln
         iv_len    TYPE scrndeflg.

  DATA: ls_field TYPE rpy_dyfatc.

  CLEAR ls_field.
  ls_field-cont_type = 'SCREEN'.
  ls_field-cont_name = 'SCREEN'.
  ls_field-type      = 'TEXT'.
  ls_field-name      = iv_name.
  ls_field-text      = iv_text.
  ls_field-line      = iv_line.
  ls_field-column    = iv_col.
  ls_field-length    = iv_len.
  ls_field-vislength = iv_len.
  APPEND ls_field TO ct_fields.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_TEMPLATE_FIELD
*&---------------------------------------------------------------------*
FORM add_template_field
  TABLES ct_fields TYPE dyfatc_tab
  USING  iv_name    TYPE scrfname
         iv_line    TYPE scrnline
         iv_col     TYPE scrncoln
         iv_len     TYPE scrndeflg
         iv_inp     TYPE scrffein
         iv_out     TYPE scrffout
         iv_outonly TYPE scrfoout.

  DATA: ls_field TYPE rpy_dyfatc.

  CLEAR ls_field.
  ls_field-cont_type  = 'SCREEN'.
  ls_field-cont_name  = 'SCREEN'.
  ls_field-type       = 'TEMPLATE'.
  ls_field-name       = iv_name.
  ls_field-line       = iv_line.
  ls_field-column     = iv_col.
  ls_field-length     = iv_len.
  ls_field-vislength  = iv_len.
  ls_field-format     = 'CHAR'.
  ls_field-text       = space.
  ls_field-input_fld  = iv_inp.
  ls_field-output_fld = iv_out.
  ls_field-outputonly = iv_outonly.
  APPEND ls_field TO ct_fields.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_PUSH_BUTTON
*&---------------------------------------------------------------------*
FORM add_push_button
  TABLES ct_fields  TYPE dyfatc_tab
  USING  iv_name    TYPE scrfname
         iv_text    TYPE scrfstxg
         iv_fcode   TYPE scrffcod
         iv_line    TYPE scrnline
         iv_col     TYPE scrncoln
         iv_len     TYPE scrndeflg.

  DATA: ls_field TYPE rpy_dyfatc.

  CLEAR ls_field.
  ls_field-cont_type  = 'SCREEN'.
  ls_field-cont_name  = 'SCREEN'.
  ls_field-type       = 'PUSH'.
  ls_field-name       = iv_name.
  ls_field-text       = iv_text.
  ls_field-push_fcode = iv_fcode.
  ls_field-line       = iv_line.
  ls_field-column     = iv_col.
  ls_field-length     = iv_len.
  ls_field-vislength  = iv_len.
  ls_field-input_fld  = 'X'.
  APPEND ls_field TO ct_fields.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form CREATE_SCREEN_0100
*&---------------------------------------------------------------------*
FORM create_screen_0100 USING iv_prog TYPE trdir-name.
  DATA: ls_header     TYPE rpy_dyhead,
        lt_containers TYPE dycatt_tab,
        lt_fields     TYPE dyfatc_tab,
        lt_flow       TYPE TABLE OF rpy_dyflow,
        ls_cont       TYPE rpy_dycatt,
        ls_field      TYPE rpy_dyfatc.

  " Delete existing dynpro if present
  CALL FUNCTION 'RS_DYNPRO_DELETE'
    EXPORTING
      dynnr           = '0100'
      progname        = iv_prog
      popup           = space
      suppress_checks = 'X'
      suppress_corr   = 'X'
    EXCEPTIONS
      OTHERS          = 0.

  " Header
  CLEAR ls_header.
  ls_header-program    = iv_prog.
  ls_header-screen     = '0100'.
  ls_header-language   = 'E'.
  ls_header-descript   = 'RF Reservation/TR Transfer Selection'.
  ls_header-type       = 'N'.
  ls_header-lines      = 21.
  ls_header-columns    = 40.

  " Root Container
  CLEAR lt_containers.
  CLEAR ls_cont.
  ls_cont-type   = 'SCREEN'.
  ls_cont-name   = 'SCREEN'.
  ls_cont-line   = 1.
  ls_cont-column = 1.
  ls_cont-length = 40.
  ls_cont-height = 21.
  APPEND ls_cont TO lt_containers.

  " Fields
  CLEAR lt_fields.

  " OK_CODE (mandatory)
  CLEAR ls_field.
  ls_field-cont_type = 'SCREEN'.
  ls_field-cont_name = 'SCREEN'.
  ls_field-type      = 'OKCODE'.
  ls_field-name      = 'OK_CODE'.
  ls_field-line      = 0.
  ls_field-column    = 0.
  ls_field-length    = 20.
  ls_field-vislength = 20.
  ls_field-format    = 'CHAR'.
  ls_field-input_fld = 'X'.
  ls_field-text      = '____________________'.
  APPEND ls_field TO lt_fields.

  " Title Text
  PERFORM add_text_field TABLES lt_fields USING 'TXT_TIT01' 'RF RES / TR TRANSFER' 1 2 20.

  " Whse Num Label & Input
  PERFORM add_text_field TABLES lt_fields USING 'TXT_WH' 'Whse Num :' 3 2 10.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-LGNUM' 3 13 3 'X' 'X' ' '.

  " Doc Type Label
  PERFORM add_text_field TABLES lt_fields USING 'TXT_DTYP' 'Doc Type :' 5 2 10.

  " Res Label & Input
  PERFORM add_text_field TABLES lt_fields USING 'TXT_RES' 'RES:' 5 13 4.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-RAD_RES' 5 18 1 'X' 'X' ' '.

  " TR Label & Input
  PERFORM add_text_field TABLES lt_fields USING 'TXT_TR' 'TR:' 5 21 3.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-RAD_TR' 5 25 1 'X' 'X' ' '.

  " Doc Num Label & Input
  PERFORM add_text_field TABLES lt_fields USING 'TXT_DOC' 'Doc Num  :' 7 2 10.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-DOC_NUM' 7 13 10 'X' 'X' ' '.

  " Message Field
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-MSG' 9 2 38 ' ' 'X' 'X'.

  " Action Buttons
  PERFORM add_push_button TABLES lt_fields USING 'BTN_EXEC' 'Process [Enter]' 'ENTR' 11 2 16.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_EXIT' 'Exit [F3]' 'EXIT' 11 20 12.

  " Flow Logic
  CLEAR lt_flow.
  APPEND VALUE #( line = 'PROCESS BEFORE OUTPUT.' ) TO lt_flow.
  APPEND VALUE #( line = '  MODULE status_0100.' ) TO lt_flow.
  APPEND VALUE #( line = 'PROCESS AFTER INPUT.' ) TO lt_flow.
  APPEND VALUE #( line = '  MODULE user_command_0100.' ) TO lt_flow.

  " Insert & Compile Screen
  CALL FUNCTION 'RPY_DYNPRO_INSERT'
    EXPORTING
      header                   = ls_header
      suppress_exist_checks    = 'X'
      suppress_corr_checks     = 'X'
      suppress_extended_checks = 'X'
      suppress_generate        = ' '
    TABLES
      containers               = lt_containers
      fields_to_containers     = lt_fields
      flow_logic               = lt_flow
    EXCEPTIONS
      cancelled                = 1
      already_exists           = 2
      program_not_exists       = 3
      not_executed             = 4
      missing_required_field   = 5
      illegal_field_value      = 6
      field_not_allowed        = 7
      not_generated            = 8
      illegal_field_position   = 9
      OTHERS                   = 10.

  WRITE: / 'Dynpro 0100 creation rc =', sy-subrc, 'sys msg:', sy-msgid, sy-msgno.
  WRITE: / '  v1=', sy-msgv1, 'v2=', sy-msgv2, 'v3=', sy-msgv3, 'v4=', sy-msgv4.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form CREATE_SCREEN_0200
*&---------------------------------------------------------------------*
FORM create_screen_0200 USING iv_prog TYPE trdir-name.
  DATA: ls_header     TYPE rpy_dyhead,
        lt_containers TYPE dycatt_tab,
        lt_fields     TYPE dyfatc_tab,
        lt_flow       TYPE TABLE OF rpy_dyflow,
        ls_cont       TYPE rpy_dycatt,
        ls_field      TYPE rpy_dyfatc.

  CALL FUNCTION 'RS_DYNPRO_DELETE'
    EXPORTING
      dynnr           = '0200'
      progname        = iv_prog
      popup           = space
      suppress_checks = 'X'
      suppress_corr   = 'X'
    EXCEPTIONS
      OTHERS          = 0.

  CLEAR ls_header.
  ls_header-program    = iv_prog.
  ls_header-screen     = '0200'.
  ls_header-language   = 'E'.
  ls_header-descript   = 'RF Reservation/TR Transfer Item Execution'.
  ls_header-type       = 'N'.
  ls_header-lines      = 21.
  ls_header-columns    = 40.

  CLEAR lt_containers.
  CLEAR ls_cont.
  ls_cont-type   = 'SCREEN'.
  ls_cont-name   = 'SCREEN'.
  ls_cont-line   = 1.
  ls_cont-column = 1.
  ls_cont-length = 40.
  ls_cont-height = 21.
  APPEND ls_cont TO lt_containers.

  CLEAR lt_fields.

  " OK_CODE
  CLEAR ls_field.
  ls_field-cont_type = 'SCREEN'.
  ls_field-cont_name = 'SCREEN'.
  ls_field-type      = 'OKCODE'.
  ls_field-name      = 'OK_CODE'.
  ls_field-line      = 0.
  ls_field-column    = 0.
  ls_field-length    = 20.
  ls_field-vislength = 20.
  ls_field-format    = 'CHAR'.
  ls_field-input_fld = 'X'.
  ls_field-text      = '____________________'.
  APPEND ls_field TO lt_fields.

  " Row 1: DOC: [TYP] [NUM] Itm:[C]/[T]
  PERFORM add_text_field TABLES lt_fields USING 'TXT_DOC2' 'DOC:' 1 2 4.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-DOC_TYPE' 1 7 3 ' ' 'X' 'X'.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-DOC_NUM' 1 11 10 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_ITM' 'Itm:' 1 22 4.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-ITEM_CURR' 1 27 3 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SLASH' '/' 1 31 1.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-ITEM_TOTAL' 1 33 3 ' ' 'X' 'X'.

  " Row 3: Mat: [MATNR]
  PERFORM add_text_field TABLES lt_fields USING 'TXT_MAT' 'Mat: ' 3 2 5.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-MATNR' 3 8 18 ' ' 'X' 'X'.

  " Row 4: Desc: [MAKTX]
  PERFORM add_text_field TABLES lt_fields USING 'TXT_MAKTX' 'Desc:' 4 2 5.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-MAKTX' 4 8 20 ' ' 'X' 'X'.

  " Row 5: Req: [TARGET_QTY]  Open: [OPEN_QTY] [MEINS]
  PERFORM add_text_field TABLES lt_fields USING 'TXT_REQ' 'Req:' 5 2 4.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-TARGET_QTY' 5 7 9 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_OPN' 'Open:' 5 17 5.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-OPEN_QTY' 5 23 9 ' ' 'X' 'X'.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-MEINS' 5 33 3 ' ' 'X' 'X'.

  " Row 7: Src Bin: [VLTYP] [VLPLA]
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SBIN' 'Src Bin:' 7 2 8.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-VLTYP_DISP' 7 11 3 ' ' 'X' 'X'.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-VLPLA_DISP' 7 15 10 ' ' 'X' 'X'.

  " Row 9: Scan HU: [EXIDV_SCAN]
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SHU' 'Scan HU :' 9 2 9.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-EXIDV_SCAN' 9 12 20 'X' 'X' ' '.

  " Row 11: Batch: [CHARG] Ser: [CNT]
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SBAT' 'Batch   :' 11 2 9.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-CHARG_DISP' 11 12 10 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SSER' 'Ser:' 11 24 4.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-SER_COUNT' 11 29 4 ' ' 'X' 'X'.

  " Row 13: Qty: [POST_QTY]
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SQTY' 'Qty     :' 13 2 9.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-POST_QTY' 13 12 13 'X' 'X' ' '.

  " Row 15: Status Msg
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-STATUS_MSG' 15 2 38 ' ' 'X' 'X'.

  " Action Buttons Row 17 & 19
  PERFORM add_push_button TABLES lt_fields USING 'BTN_POST' 'Post' 'POST' 17 2 7.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_PREV' 'Prev' 'PREV' 17 10 7.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_NEXT' 'Next' 'NEXT' 17 18 7.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_BACK' 'Back' 'BACK' 17 26 7.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_SER' 'Serials' 'SERN' 19 2 12.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_BINS' 'Stock Bins' 'BINS' 19 16 14.

  " Flow logic
  CLEAR lt_flow.
  APPEND VALUE #( line = 'PROCESS BEFORE OUTPUT.' ) TO lt_flow.
  APPEND VALUE #( line = '  MODULE status_0200.' ) TO lt_flow.
  APPEND VALUE #( line = 'PROCESS AFTER INPUT.' ) TO lt_flow.
  APPEND VALUE #( line = '  MODULE user_command_0200.' ) TO lt_flow.

  CALL FUNCTION 'RPY_DYNPRO_INSERT'
    EXPORTING
      header                   = ls_header
      suppress_exist_checks    = 'X'
      suppress_corr_checks     = 'X'
      suppress_extended_checks = 'X'
      suppress_generate        = ' '
    TABLES
      containers               = lt_containers
      fields_to_containers     = lt_fields
      flow_logic               = lt_flow
    EXCEPTIONS
      cancelled                = 1
      already_exists           = 2
      program_not_exists       = 3
      not_executed             = 4
      missing_required_field   = 5
      illegal_field_value      = 6
      field_not_allowed        = 7
      not_generated            = 8
      illegal_field_position   = 9
      OTHERS                   = 10.

  WRITE: / 'Dynpro 0200 creation rc =', sy-subrc, 'sys msg:', sy-msgid, sy-msgno.
  WRITE: / '  v1=', sy-msgv1, 'v2=', sy-msgv2, 'v3=', sy-msgv3, 'v4=', sy-msgv4.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SETUP_CUA_INTERFACE
*&---------------------------------------------------------------------*
FORM setup_cua_interface USING iv_prog TYPE trdir-name.
  DATA: lv_src_prog TYPE trdir-name.
  DATA: lt_sta TYPE TABLE OF rsmpe_sta,
        lt_ctx TYPE TABLE OF rsmpe_ctx,
        lt_fun TYPE TABLE OF rsmpe_fun,
        lt_mtx TYPE TABLE OF rsmpe_mnl,
        lt_doc TYPE TABLE OF rsmpe_atr,
        lt_tit TYPE TABLE OF rsmpe_tit,
        lt_men TYPE TABLE OF rsmpe_men,
        lt_act TYPE TABLE OF rsmpe_act,
        lt_but TYPE TABLE OF rsmpe_but,
        lt_pfk TYPE TABLE OF rsmpe_pfk,
        lt_set TYPE TABLE OF rsmpe_staf,
        lt_biv TYPE TABLE OF rsmpe_buts,
        ls_adm TYPE rsmpe_adm.
  DATA: eudb_src_key LIKE rseu1_key,
        eudb_dst_key LIKE rseu1_key.

  DATA: lt_candidates TYPE TABLE OF trdir-name.
  APPEND 'ZGATEENTRY' TO lt_candidates.
  APPEND 'SAPMSSYS' TO lt_candidates.
  APPEND 'SAPLMEGUI' TO lt_candidates.
  APPEND 'SAPLSCVI' TO lt_candidates.

  SELECT name FROM eudb APPENDING TABLE @lt_candidates
    WHERE relid = 'CU' AND srtf2 = 0 AND name LIKE 'Z%'
    ORDER BY name.

  LOOP AT lt_candidates INTO lv_src_prog.
    CLEAR: lt_sta, lt_ctx, lt_fun, lt_mtx, lt_doc, lt_tit,
           lt_men, lt_act, ls_adm, lt_but, lt_pfk, lt_set, lt_biv.
    eudb_src_key-name  = lv_src_prog.
    eudb_src_key-sprsl = 'D'.

    CATCH SYSTEM-EXCEPTIONS import_mismatch_errors = 1.
      IMPORT sta TO lt_sta
             ctx TO lt_ctx
             fun TO lt_fun
             mtx TO lt_mtx
             doc TO lt_doc
             tit TO lt_tit
             men TO lt_men
             act TO lt_act
             adm TO ls_adm
             but TO lt_but
             pfk TO lt_pfk
             set TO lt_set
             biv TO lt_biv
        FROM DATABASE eudb(cu) ID eudb_src_key
        IGNORING CONVERSION ERRORS
        ACCEPTING TRUNCATION.
    ENDCATCH.

    IF sy-subrc = 0 AND lt_sta IS NOT INITIAL.
      EXIT.
    ENDIF.
  ENDLOOP.

  WRITE: / '---------------------------------------------------------'.
  WRITE: / 'Setting up CUA GUI Status & Titles for:', iv_prog.
  WRITE: / 'Source template program in EUDB(CU)   :', lv_src_prog.
  WRITE: / 'IMPORT from EUDB(CU) sy-subrc =', sy-subrc, 'statuses =', lines( lt_sta ).

    IF sy-subrc = 0 AND lt_sta IS NOT INITIAL.
      DATA(ls_template_sta) = lt_sta[ 1 ].

      " Ensure STATUS_0100
      READ TABLE lt_sta TRANSPORTING NO FIELDS WITH KEY code = 'STATUS_0100'.
      IF sy-subrc <> 0.
        DATA(ls_sta1) = ls_template_sta.
        ls_sta1-code = 'STATUS_0100'.
        APPEND ls_sta1 TO lt_sta.
      ENDIF.

      " Ensure STATUS_0200
      READ TABLE lt_sta TRANSPORTING NO FIELDS WITH KEY code = 'STATUS_0200'.
      IF sy-subrc <> 0.
        DATA(ls_sta2) = ls_template_sta.
        ls_sta2-code = 'STATUS_0200'.
        APPEND ls_sta2 TO lt_sta.
      ENDIF.

      " Ensure TITLE_0100
      READ TABLE lt_tit TRANSPORTING NO FIELDS WITH KEY code = 'TITLE_0100'.
      IF sy-subrc <> 0.
        APPEND VALUE #( code = 'TITLE_0100' ) TO lt_tit.
      ENDIF.

      " Ensure TITLE_0200
      READ TABLE lt_tit TRANSPORTING NO FIELDS WITH KEY code = 'TITLE_0200'.
      IF sy-subrc <> 0.
        APPEND VALUE #( code = 'TITLE_0200' ) TO lt_tit.
      ENDIF.

      eudb_dst_key-name  = iv_prog.
      eudb_dst_key-sprsl = 'D'.

      EXPORT sta FROM lt_sta
             ctx FROM lt_ctx
             fun FROM lt_fun
             mtx FROM lt_mtx
             doc FROM lt_doc
             tit FROM lt_tit
             men FROM lt_men
             act FROM lt_act
             adm FROM ls_adm
             but FROM lt_but
             pfk FROM lt_pfk
             set FROM lt_set
             biv FROM lt_biv
        TO DATABASE eudb(cu) ID eudb_dst_key.

      WRITE: / 'EXPORT to EUDB(CU) rc =', sy-subrc.

      " Update administrative fields in EUDB
      UPDATE eudb SET langu = @sy-langu, autor = @sy-uname, datum = @sy-datum, zeit = @sy-uzeit
        WHERE relid = 'CU' AND name = @iv_prog AND srtf2 = 0.

      " Generate compiled CUA load
      CALL FUNCTION 'RS_CUA_INTERNAL_GENERATE'
        EXPORTING
          program           = iv_prog
          generate_path     = 'X'
        EXCEPTIONS
          not_found         = 1
          syntax_error      = 2
          generation_failed = 3
          OTHERS            = 4.

      WRITE: / 'RS_CUA_INTERNAL_GENERATE rc =', sy-subrc.

      " Update RSMPTEXTS
      DATA: ls_mptext TYPE rsmptexts.

      CLEAR ls_mptext.
      ls_mptext-progname = iv_prog.
      ls_mptext-sprsl    = sy-langu.
      ls_mptext-obj_type = 'S'.
      ls_mptext-obj_code = 'STATUS_0100'.
      ls_mptext-text     = 'RF Reservation/TR Transfer Selection'.
      MODIFY rsmptexts FROM @ls_mptext.

      CLEAR ls_mptext.
      ls_mptext-progname = iv_prog.
      ls_mptext-sprsl    = sy-langu.
      ls_mptext-obj_type = 'S'.
      ls_mptext-obj_code = 'STATUS_0200'.
      ls_mptext-text     = 'RF Transfer Item Execution'.
      MODIFY rsmptexts FROM @ls_mptext.

      CLEAR ls_mptext.
      ls_mptext-progname = iv_prog.
      ls_mptext-sprsl    = sy-langu.
      ls_mptext-obj_type = 'T'.
      ls_mptext-obj_code = 'TITLE_0100'.
      ls_mptext-text     = 'RF Reservation/TR Transfer'.
      MODIFY rsmptexts FROM @ls_mptext.

      CLEAR ls_mptext.
      ls_mptext-progname = iv_prog.
      ls_mptext-sprsl    = sy-langu.
      ls_mptext-obj_type = 'T'.
      ls_mptext-obj_code = 'TITLE_0200'.
      ls_mptext-text     = 'RF Transfer Item Execution'.
      MODIFY rsmptexts FROM @ls_mptext.

      COMMIT WORK AND WAIT.
      WRITE: / 'CUA Statuses and Titles registered successfully!'.
    ENDIF.
ENDFORM.

