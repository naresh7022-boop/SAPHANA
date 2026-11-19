*&---------------------------------------------------------------------*
*& Report ZCREATE_FIORI_TILE_ZPPLIS_NN
*& Purpose: Register Semantic Objects and prepare SAP Fiori Launchpad
*&          Target Mapping and Tile configuration for ZPPLIS_NN
*& Author:  SAP Techno-Functional Architect
*& Target:  SAP S/4HANA DS4/220
*& Package: $TMP
*& Transaction: ZPPLIS_NN
*&---------------------------------------------------------------------*
REPORT zcreate_fiori_tile_zpplis_nn.

TABLES: /ui2/semobjc, /ui2/semobjct.

DATA: ls_c    TYPE /ui2/semobjc,
      ls_ct   TYPE /ui2/semobjct,
      lv_cnt  TYPE i.

START-OF-SELECTION.

  WRITE: / '=============================================================='.
  WRITE: / '  SAP FIORI LAUNCHPAD TILE CONFIGURATION FOR ZPPLIS_NN          '.
  WRITE: / '=============================================================='.
  SKIP 1.

  " ------------------------------------------------------------------
  " 1. Register Custom Semantic Object: ZPPLIS_NN
  " ------------------------------------------------------------------
  ls_c-sem_obj = 'ZPPLIS_NN'.
  INSERT /ui2/semobjc FROM ls_c.
  IF sy-subrc = 0.
    WRITE: / '✓ SUCCESS: Registered Semantic Object ZPPLIS_NN in /UI2/SEMOBJC'.
  ELSE.
    UPDATE /ui2/semobjc FROM ls_c.
    WRITE: / '✓ OK: Semantic Object ZPPLIS_NN exists in /UI2/SEMOBJC'.
  ENDIF.

  ls_ct-language     = 'E'.
  ls_ct-sem_obj      = 'ZPPLIS_NN'.
  ls_ct-sem_obj_name = 'ZPPLIS_NN'.
  ls_ct-sem_obj_text = 'QC Sample Collection & Barcode Scanner'.
  INSERT /ui2/semobjct FROM ls_ct.
  IF sy-subrc <> 0.
    UPDATE /ui2/semobjct FROM ls_ct.
  ENDIF.
  WRITE: / '✓ SUCCESS: Maintained English text in /UI2/SEMOBJCT for ZPPLIS_NN'.

  " ------------------------------------------------------------------
  " 2. Register Semantic Object: ZSampleCollection
  " ------------------------------------------------------------------
  ls_c-sem_obj = 'ZSampleCollection'.
  INSERT /ui2/semobjc FROM ls_c.
  IF sy-subrc = 0.
    WRITE: / '✓ SUCCESS: Registered Semantic Object ZSampleCollection in /UI2/SEMOBJC'.
  ELSE.
    UPDATE /ui2/semobjc FROM ls_c.
    WRITE: / '✓ OK: Semantic Object ZSampleCollection exists in /UI2/SEMOBJC'.
  ENDIF.

  ls_ct-language     = 'E'.
  ls_ct-sem_obj      = 'ZSampleCollection'.
  ls_ct-sem_obj_name = 'ZSampleCollection'.
  ls_ct-sem_obj_text = 'Sample Collection & Physical Sample Drawing'.
  INSERT /ui2/semobjct FROM ls_ct.
  IF sy-subrc <> 0.
    UPDATE /ui2/semobjct FROM ls_ct.
  ENDIF.
  WRITE: / '✓ SUCCESS: Maintained English text in /UI2/SEMOBJCT for ZSampleCollection'.

  COMMIT WORK AND WAIT.

  SKIP 1.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / 'FIORI LAUNCHPAD TILE & TARGET MAPPING PARAMETERS:'.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / '1. SEMANTIC OBJECT   : ZSampleCollection (or ZPPLIS_NN)'.
  WRITE: / '2. ACTION            : manage'.
  WRITE: / '3. INTENT            : #SampleCollection-manage'.
  WRITE: / '4. APPLICATION TYPE  : Transaction'.
  WRITE: / '5. TRANSACTION CODE  : ZPPLIS_NN'.
  WRITE: / '6. GUI TYPE          : SAP GUI for HTML (WebGUI)'.
  WRITE: / '7. DEVICE SUPPORT    : Desktop, Tablet, Phone'.
  WRITE: / '8. TILE TYPE         : Static Tile'.
  WRITE: / '9. TILE TITLE        : QC Sample Collection'.
  WRITE: / '10. TILE SUBTITLE    : ZPPLIS_NN - Barcode Scanner'.
  WRITE: / '11. TILE ICON        : sap-icon://bar-code'.
  WRITE: / '12. BUSINESS CATALOG : ZBC_QUALITY_MANAGEMENT (or ZBC_QM_SAMPLE)'.
  SKIP 1.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / 'DIRECT ACCESS URLS FOR TESTING (DS4/220):'.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / '• WebGUI Direct URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPPLIS_NN'.
  WRITE: / '• WebGUI User NARESH URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZPPLIS_NN'.
  WRITE: / '• Fiori Launchpad Intent URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#SampleCollection-manage'.
  WRITE: / '--------------------------------------------------------------'.
