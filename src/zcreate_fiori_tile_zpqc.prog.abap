*&---------------------------------------------------------------------*
*& Report ZCREATE_FIORI_TILE_ZPQC
*& Purpose: Register Semantic Objects and prepare SAP Fiori Launchpad
*&          Target Mapping and Tile configuration for ZPQC_NEW
*& Author:  NARESH
*& Date:    14.10.2026
*& Package: $TMP
*& Transaction: ZPQC_NEW
*& System:  SAP S/4HANA DS4/220
*&---------------------------------------------------------------------*
REPORT zcreate_fiori_tile_zpqc.

TABLES: /ui2/semobjc, /ui2/semobjct.

DATA: ls_c    TYPE /ui2/semobjc,
      ls_ct   TYPE /ui2/semobjct,
      lv_cnt  TYPE i.

START-OF-SELECTION.

  WRITE: / '========================================================'.
  WRITE: / '  SAP FIORI LAUNCHPAD TILE CONFIGURATION FOR ZPQC_NEW   '.
  WRITE: / '========================================================'.
  SKIP 1.

  " ------------------------------------------------------------------
  " 1. Register Custom Semantic Object: ZPQC_NEW
  " ------------------------------------------------------------------
  ls_c-sem_obj = 'ZPQC_NEW'.
  INSERT /ui2/semobjc FROM ls_c.
  IF sy-subrc = 0.
    WRITE: / '✓ SUCCESS: Registered Semantic Object ZPQC_NEW in /UI2/SEMOBJC'.
  ELSE.
    UPDATE /ui2/semobjc FROM ls_c.
    WRITE: / '✓ OK: Semantic Object ZPQC_NEW exists in /UI2/SEMOBJC'.
  ENDIF.

  ls_ct-language     = 'E'.
  ls_ct-sem_obj      = 'ZPQC_NEW'.
  ls_ct-sem_obj_name = 'ZPQC_NEW'.
  ls_ct-sem_obj_text = 'Quotation Price Comparison Cockpit'.
  INSERT /ui2/semobjct FROM ls_ct.
  IF sy-subrc <> 0.
    UPDATE /ui2/semobjct FROM ls_ct.
  ENDIF.
  WRITE: / '✓ SUCCESS: Maintained English text in /UI2/SEMOBJCT for ZPQC_NEW'.

  " ------------------------------------------------------------------
  " 2. Register Custom Semantic Object: ZPriceComparison
  " ------------------------------------------------------------------
  ls_c-sem_obj = 'ZPriceComparison'.
  INSERT /ui2/semobjc FROM ls_c.
  IF sy-subrc = 0.
    WRITE: / '✓ SUCCESS: Registered Semantic Object ZPriceComparison in /UI2/SEMOBJC'.
  ELSE.
    UPDATE /ui2/semobjc FROM ls_c.
    WRITE: / '✓ OK: Semantic Object ZPriceComparison exists in /UI2/SEMOBJC'.
  ENDIF.

  ls_ct-language     = 'E'.
  ls_ct-sem_obj      = 'ZPriceComparison'.
  ls_ct-sem_obj_name = 'ZPriceComparison'.
  ls_ct-sem_obj_text = 'Quotation Price Comparison & PO Creation'.
  INSERT /ui2/semobjct FROM ls_ct.
  IF sy-subrc <> 0.
    UPDATE /ui2/semobjct FROM ls_ct.
  ENDIF.
  WRITE: / '✓ SUCCESS: Maintained English text in /UI2/SEMOBJCT for ZPriceComparison'.

  COMMIT WORK AND WAIT.

  SKIP 1.
  WRITE: / '--------------------------------------------------------'.
  WRITE: / 'FIORI LAUNCHPAD TILE & TARGET MAPPING PARAMETERS:'.
  WRITE: / '--------------------------------------------------------'.
  WRITE: / '1. SEMANTIC OBJECT   : ZPQC_NEW (or ZPriceComparison)'.
  WRITE: / '2. ACTION            : manage'.
  WRITE: / '3. INTENT            : #ZPQC_NEW-manage'.
  WRITE: / '4. APPLICATION TYPE  : Transaction'.
  WRITE: / '5. TRANSACTION CODE  : ZPQC_NEW'.
  WRITE: / '6. GUI TYPE          : SAP GUI for HTML (WebGUI)'.
  WRITE: / '7. DEVICE SUPPORT    : Desktop, Tablet'.
  WRITE: / '8. TILE TYPE         : Static Tile'.
  WRITE: / '9. TILE TITLE        : Price Quotation Comparison'.
  WRITE: / '10. TILE SUBTITLE    : ZPQC_NEW - Quotation Matrix & PO'.
  WRITE: / '11. TILE ICON        : sap-icon://compare'.
  WRITE: / '12. BUSINESS CATALOG : ZBC_PURCHASING (or ZBC_ZPQC)'.
  SKIP 1.
  WRITE: / '--------------------------------------------------------'.
  WRITE: / 'DIRECT ACCESS URLS FOR TESTING:'.
  WRITE: / '--------------------------------------------------------'.
  WRITE: / '• WebGUI Direct URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPQC_NEW'.
  WRITE: / '• Fiori Launchpad Intent URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#ZPQC_NEW-manage'.
  WRITE: / '--------------------------------------------------------'.
