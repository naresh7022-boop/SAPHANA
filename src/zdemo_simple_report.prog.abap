*&---------------------------------------------------------------------*
*& Report ZDEMO_SIMPLE_REPORT
*&---------------------------------------------------------------------*
*& Purpose: Simple Demonstration Report in SAP S/4HANA (DS4)
*& Author:  NARESH
*& Date:    12.10.2026
*& Package: $TMP (Local Object)
*&---------------------------------------------------------------------*
REPORT zdemo_simple_report.

TABLES: t000.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_name TYPE string DEFAULT 'NARESH' LOWER CASE,
              p_max  TYPE i DEFAULT 5.
  SELECTION-SCREEN SKIP 1.
  PARAMETERS: p_sys AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.

TYPES: BEGIN OF ty_client,
         mandt TYPE t000-mandt,
         mtext TYPE t000-mtext,
         ort01 TYPE t000-ort01,
         mwaer TYPE t000-mwaer,
       END OF ty_client.

DATA: lt_clients TYPE STANDARD TABLE OF ty_client,
      ls_client  TYPE ty_client.

START-OF-SELECTION.

  WRITE: / '===============================================================' COLOR COL_HEADING.
  WRITE: / '  WELCOME TO ABAP DEVELOPMENT ON SAP S/4HANA (DS4)            ' COLOR COL_POSITIVE INTENSIFIED.
  WRITE: / '===============================================================' COLOR COL_HEADING.
  SKIP 1.

  WRITE: / 'Hello, ', p_name COLOR COL_KEY, '! Welcome to ABAP programming.'.
  SKIP 1.

  IF p_sys = abap_true.
    WRITE: / '--- System Information ---' COLOR COL_HEADING.
    WRITE: / 'System ID      :', sy-sysid COLOR COL_TOTAL.
    WRITE: / 'Client         :', sy-mandt COLOR COL_TOTAL.
    WRITE: / 'Current User   :', sy-uname COLOR COL_TOTAL.
    WRITE: / 'Execution Date :', sy-datum COLOR COL_TOTAL.
    WRITE: / 'Execution Time :', sy-uzeit COLOR COL_TOTAL.
    SKIP 1.
  ENDIF.

  WRITE: / '--- Client Overview (Table T000) ---' COLOR COL_HEADING.
  SELECT mandt, mtext, ort01, mwaer
    FROM t000
    UP TO @p_max ROWS
    INTO CORRESPONDING FIELDS OF TABLE @lt_clients.

  IF sy-subrc = 0.
    ULINE.
    WRITE: / sy-vline,
             (5)  'Client' COLOR COL_HEADING, sy-vline,
             (25) 'Description' COLOR COL_HEADING, sy-vline,
             (15) 'City' COLOR COL_HEADING, sy-vline,
             (5)  'Curr' COLOR COL_HEADING, sy-vline.
    ULINE.

    LOOP AT lt_clients INTO ls_client.
      WRITE: / sy-vline,
               (5)  ls_client-mandt COLOR COL_NORMAL, sy-vline,
               (25) ls_client-mtext COLOR COL_NORMAL, sy-vline,
               (15) ls_client-ort01 COLOR COL_NORMAL, sy-vline,
               (5)  ls_client-mwaer COLOR COL_NORMAL, sy-vline.
    ENDLOOP.
    ULINE.
    SKIP 1.
    WRITE: / 'Records fetched:', lines( lt_clients ) COLOR COL_POSITIVE.
  ELSE.
    WRITE: / 'No client data found or read error.' COLOR COL_NEGATIVE.
  ENDIF.
