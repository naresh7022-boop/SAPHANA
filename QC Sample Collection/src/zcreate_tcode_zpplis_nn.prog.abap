*&---------------------------------------------------------------------*
*& Report ZCREATE_TCODE_ZPPLIS_NN
*& Purpose: Create Dynpros 0100 & 0200 for Module Pool SAPMZPPLIS_NN
*&          and register Transaction Codes ZPPLIS_NN and ZPLIS_NN
*&          with CINFO = '00' (Dialog Transaction) and S_WEBGUI = '1'.
*& Author:  SAP Techno-Functional Architect
*& Target:  SAP S/4HANA DS4/220
*& Package: $TMP
*&---------------------------------------------------------------------*
REPORT zcreate_tcode_zpplis_nn.

DATA: lv_prog     TYPE trdir-name VALUE 'SAPMZPPLIS_NN',
      lv_alt_prog TYPE trdir-name VALUE 'ZPPLIS_NN',
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
  " 1. Create and Compile Dynpro 0100 (Selection & Lot Scan Screen)
  " -------------------------------------------------------------
  PERFORM create_screen_0100 USING lv_prog.

  " -------------------------------------------------------------
  " 2. Create and Compile Dynpro 0200 (Sample Collection & Tube Scan)
  " -------------------------------------------------------------
  PERFORM create_screen_0200 USING lv_prog.

  " -------------------------------------------------------------
  " 3. Register Primary Transaction: ZPPLIS_NN (Dialog Transaction)
  " -------------------------------------------------------------
  CLEAR: ls_tstc, ls_tstct, ls_tstcc.

  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZPPLIS_NN'.
  IF sy-subrc <> 0.
    ls_tstc-tcode = 'ZPPLIS_NN'.
  ENDIF.
  ls_tstc-pgmna = lv_prog.
  ls_tstc-dypno = '0100'.
  ls_tstc-cinfo = '00'. " Dialog Transaction
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = sy-langu.
  ls_tstct-tcode = 'ZPPLIS_NN'.
  ls_tstct-ttext = 'QC Sample Collection & Barcode Scanner'.
  MODIFY tstct FROM ls_tstct.

  IF sy-langu <> 'E'.
    ls_tstct-sprsl = 'E'.
    MODIFY tstct FROM ls_tstct.
  ENDIF.

  SELECT SINGLE * FROM tstcc INTO ls_tstcc WHERE tcode = 'ZPPLIS_NN'.
  IF sy-subrc <> 0.
    ls_tstcc-tcode = 'ZPPLIS_NN'.
  ENDIF.
  ls_tstcc-s_webgui = '1'. " Enabled for WebGUI / ITSmobile / Fiori
  ls_tstcc-s_win32  = 'X'. " SAP GUI for Windows
  ls_tstcc-s_platin = 'X'. " SAP GUI for Java / macOS
  ls_tstcc-s_dummy  = 'X'.
  ls_tstcc-s_dummy1 = 'X'.
  MODIFY tstcc FROM ls_tstcc.

  " -------------------------------------------------------------
  " 4. Register Quick Mobile Short Code: ZPLIS_NN (Dialog Transaction)
  " -------------------------------------------------------------
  CLEAR: ls_tstc, ls_tstct, ls_tstcc.

  SELECT SINGLE * FROM tstc INTO ls_tstc WHERE tcode = 'ZPLIS_NN'.
  IF sy-subrc <> 0.
    ls_tstc-tcode = 'ZPLIS_NN'.
  ENDIF.
  ls_tstc-pgmna = lv_prog.
  ls_tstc-dypno = '0100'.
  ls_tstc-cinfo = '00'. " Dialog transaction
  MODIFY tstc FROM ls_tstc.

  ls_tstct-sprsl = 'E'.
  ls_tstct-tcode = 'ZPLIS_NN'.
  ls_tstct-ttext = 'QC Sample Scanner Short T-Code'.
  MODIFY tstct FROM ls_tstct.

  SELECT SINGLE * FROM tstcc INTO ls_tstcc WHERE tcode = 'ZPLIS_NN'.
  IF sy-subrc <> 0.
    ls_tstcc-tcode = 'ZPLIS_NN'.
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
  WRITE: / 'Primary TCODE : ZPPLIS_NN (CINFO = 00 - Dialog Transaction)'.
  WRITE: / 'Short Code    : ZPLIS_NN  (CINFO = 00 - Dialog Transaction)'.
  WRITE: / 'Target Program: ', lv_prog.
  WRITE: / 'Initial Screen: 0100'.
  WRITE: / 'WebGUI Enabled: S_WEBGUI = 1'.
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
  TABLES ct_fields  TYPE dyfatc_tab
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
  ls_header-descript   = 'QC Sample Collection - Barcode Scanner'.
  ls_header-type       = 'N'.
  ls_header-lines      = 21.
  ls_header-columns    = 60.

  " Root Container
  CLEAR lt_containers.
  CLEAR ls_cont.
  ls_cont-type   = 'SCREEN'.
  ls_cont-name   = 'SCREEN'.
  ls_cont-line   = 1.
  ls_cont-column = 1.
  ls_cont-lines  = 21.
  ls_cont-cols   = 60.
  APPEND ls_cont TO lt_containers.

  " Fields Layout
  CLEAR lt_fields.

  " Title Banner
  PERFORM add_text_field TABLES lt_fields USING 'TXT_TITLE' '*** QC SAMPLE SCANNER (ZPPLIS_NN) ***' 1 2 45.

  " Plant
  PERFORM add_text_field TABLES lt_fields USING 'TXT_WERK' 'Plant / Werk   :' 3 2 16.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-WERKS' 3 20 4 'X' 'X' ' '.

  " Barcode Scan Input (Primary handheld entry)
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SCAN' 'Scan Barcode   :' 5 2 16.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-SCAN_BARCODE' 5 20 35 'X' 'X' ' '.

  " Inspection Lot Input
  PERFORM add_text_field TABLES lt_fields USING 'TXT_LOT' 'Inspection Lot :' 7 2 16.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-PRUEFLOS' 7 20 12 'X' 'X' ' '.

  " Process Order / Aufnr
  PERFORM add_text_field TABLES lt_fields USING 'TXT_ORD' 'Process Order  :' 9 2 16.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-AUFNR' 9 20 12 'X' 'X' ' '.

  " Message Field
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0100-MSG' 12 2 56 ' ' 'X' 'X'.

  " Action Buttons
  PERFORM add_push_button TABLES lt_fields USING 'BTN_EXEC' 'Process [Enter]' 'ENTR' 15 2 16.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_DEMO' 'Demo Lot' 'DEMO' 15 20 12.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_CLEA' 'Clear [F4]' 'CLEA' 15 34 12.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_EXIT' 'Exit [F3]' 'EXIT' 15 48 10.

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

  WRITE: / 'Dynpro 0100 creation rc =', sy-subrc.
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
  ls_header-descript   = 'QC Physical Sample Collection Details'.
  ls_header-type       = 'N'.
  ls_header-lines      = 22.
  ls_header-columns    = 60.

  CLEAR lt_containers.
  CLEAR ls_cont.
  ls_cont-type   = 'SCREEN'.
  ls_cont-name   = 'SCREEN'.
  ls_cont-line   = 1.
  ls_cont-column = 1.
  ls_cont-lines  = 22.
  ls_cont-cols   = 60.
  APPEND ls_cont TO lt_containers.

  CLEAR lt_fields.

  " Header Information
  PERFORM add_text_field TABLES lt_fields USING 'TXT_HDR_LOT' 'Insp Lot:' 1 2 9.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-PRUEFLOS' 1 12 12 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_HDR_BAT' 'Batch:' 1 26 6.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-CHARG' 1 33 10 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_HDR_PLT' 'Plt:' 1 45 4.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-WERKS' 1 50 4 ' ' 'X' 'X'.

  PERFORM add_text_field TABLES lt_fields USING 'TXT_HDR_MAT' 'Material:' 2 2 9.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-MATNR' 2 12 18 ' ' 'X' 'X'.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-MAKTX' 2 31 27 ' ' 'X' 'X'.

  " Separator
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SEP' '----------------------------------------------------------' 3 2 56.

  " Current Sample Progress
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SMP_NUM' 'Sample Item :' 4 2 14.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-ITEM_CURR' 4 17 2 ' ' 'X' 'X'.
  PERFORM add_text_field TABLES lt_fields USING 'TXT_OF' 'of' 4 20 2.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-ITEM_TOTAL' 4 23 2 ' ' 'X' 'X'.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-SAMPLE_CAT_TXT' 4 28 20 ' ' 'X' 'X'.

  " Physical Sample ID
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SMP_ID' 'Sample ID   :' 6 2 14.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-PHYSSAMPLE' 6 17 12 ' ' 'X' 'X'.

  " Target Quantity & UoM
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SMP_QTY' 'Quantity    :' 7 2 14.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-SAMPLE_QTY' 7 17 10 ' ' 'X' 'X'.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-SAMPLE_UOM' 7 28 4 ' ' 'X' 'X'.

  " Container & Storage Location
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SMP_CON' 'Container   :' 8 2 14.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-CONTAINER' 8 17 25 ' ' 'X' 'X'.

  PERFORM add_text_field TABLES lt_fields USING 'TXT_SMP_LOC' 'Storage Loc :' 9 2 14.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-STORAGE_LOC' 9 17 25 'X' 'X' ' '.

  " Tube Barcode Verification
  PERFORM add_text_field TABLES lt_fields USING 'TXT_TUBE_BC' 'Tube Barcode:' 11 2 14.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-SCAN_TUBE_BARCODE' 11 17 35 'X' 'X' ' '.

  " Temperature
  PERFORM add_text_field TABLES lt_fields USING 'TXT_SMP_TMP' 'Temperature :' 13 2 14.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-TEMPERATURE' 13 17 10 'X' 'X' ' '.

  " Status
  PERFORM add_text_field TABLES lt_fields USING 'TXT_STATUS' 'Status      :' 14 2 14.
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-STATUS_TXT' 14 17 25 ' ' 'X' 'X'.

  " Message Field
  PERFORM add_template_field TABLES lt_fields USING 'G_SCR0200-MSG' 16 2 56 ' ' 'X' 'X'.

  " Action Buttons
  PERFORM add_push_button TABLES lt_fields USING 'BTN_CONF' 'Confirm Sample [Enter]' 'CONF' 18 2 22.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_NEXT' 'Next >>' 'NEXT' 18 26 10.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_PREV' '<< Prev' 'PREV' 18 38 10.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_BACK' 'Back [F3]' 'BACK' 18 50 8.

  PERFORM add_push_button TABLES lt_fields USING 'BTN_PRNT' 'Print Label' 'PRNT' 20 2 14.
  PERFORM add_push_button TABLES lt_fields USING 'BTN_REST' 'Reset Sample' 'REST' 20 18 14.

  " Flow Logic
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

  WRITE: / 'Dynpro 0200 creation rc =', sy-subrc.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SETUP_CUA_INTERFACE
*&---------------------------------------------------------------------*
FORM setup_cua_interface USING iv_prog TYPE trdir-name.
  " Setup GUI Titlebar
  CALL FUNCTION 'RS_CUA_TITLES_WRITE'
    EXPORTING
      trdir_name = iv_prog
    TABLES
      title_tab  = VALUE rpy_dytitt_tab(
        ( title_code = 'TITLE_0100' title_text = 'QC Sample Collection - Barcode Scanner' )
        ( title_code = 'TITLE_0200' title_text = 'Physical Sample Collection & Verification' )
      )
    EXCEPTIONS
      OTHERS     = 0.
ENDFORM.
