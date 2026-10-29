*&---------------------------------------------------------------------*
*& Report ZCREATE_FIORI_TILE_ZRF_RESWM
*& Purpose: Register Semantic Objects and prepare SAP Fiori Launchpad
*&          Target Mapping and Tile configuration for ZRF_RESWM & ZRF01
*& Author:  NARESH
*& Date:    29.10.2026
*& Package: $TMP
*& Transaction: ZRF_RESWM / ZRF01
*& System:  SAP S/4HANA DS4/220
*&---------------------------------------------------------------------*
REPORT zcreate_fiori_tile_zrf_reswm.

TABLES: /ui2/semobjc, /ui2/semobjct.

DATA: ls_c  TYPE /ui2/semobjc,
      ls_ct TYPE /ui2/semobjct.

START-OF-SELECTION.

  WRITE: / '=============================================================='.
  WRITE: / '  SAP FIORI LAUNCHPAD TILE CONFIGURATION FOR ZRF_RESWM / ZRF01 '.
  WRITE: / '=============================================================='.
  SKIP 1.

  " ------------------------------------------------------------------
  " 1. Register Custom Semantic Object: RFTransfer
  " ------------------------------------------------------------------
  ls_c-sem_obj = 'RFTransfer'.
  INSERT /ui2/semobjc FROM ls_c.
  IF sy-subrc = 0.
    WRITE: / '✓ SUCCESS: Registered Semantic Object RFTransfer in /UI2/SEMOBJC'.
  ELSE.
    UPDATE /ui2/semobjc FROM ls_c.
    WRITE: / '✓ OK: Semantic Object RFTransfer exists in /UI2/SEMOBJC'.
  ENDIF.

  ls_ct-language     = 'E'.
  ls_ct-sem_obj      = 'RFTransfer'.
  ls_ct-sem_obj_name = 'RFTransfer'.
  ls_ct-sem_obj_text = 'RF Reservation to WM Transfer'.
  INSERT /ui2/semobjct FROM ls_ct.
  IF sy-subrc <> 0.
    UPDATE /ui2/semobjct FROM ls_ct.
  ENDIF.
  WRITE: / '✓ SUCCESS: Maintained English text in /UI2/SEMOBJCT for RFTransfer'.

  " ------------------------------------------------------------------
  " 2. Register Custom Semantic Object: RFScanner
  " ------------------------------------------------------------------
  ls_c-sem_obj = 'RFScanner'.
  INSERT /ui2/semobjc FROM ls_c.
  IF sy-subrc = 0.
    WRITE: / '✓ SUCCESS: Registered Semantic Object RFScanner in /UI2/SEMOBJC'.
  ELSE.
    UPDATE /ui2/semobjc FROM ls_c.
    WRITE: / '✓ OK: Semantic Object RFScanner exists in /UI2/SEMOBJC'.
  ENDIF.

  ls_ct-language     = 'E'.
  ls_ct-sem_obj      = 'RFScanner'.
  ls_ct-sem_obj_name = 'RFScanner'.
  ls_ct-sem_obj_text = 'RF Barcode Scanner Terminal'.
  INSERT /ui2/semobjct FROM ls_ct.
  IF sy-subrc <> 0.
    UPDATE /ui2/semobjct FROM ls_ct.
  ENDIF.
  WRITE: / '✓ SUCCESS: Maintained English text in /UI2/SEMOBJCT for RFScanner'.

  COMMIT WORK AND WAIT.

  SKIP 1.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / 'FIORI LAUNCHPAD TILE & TARGET MAPPING PARAMETERS:'.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / '1. SEMANTIC OBJECT   : RFTransfer (or RFScanner)'.
  WRITE: / '2. ACTION            : manage (or scan)'.
  WRITE: / '3. INTENT            : #RFTransfer-manage'.
  WRITE: / '4. APPLICATION TYPE  : Transaction'.
  WRITE: / '5. TRANSACTION CODE  : ZRF_RESWM (or ZRF01)'.
  WRITE: / '6. GUI TYPE          : SAP GUI for HTML (WebGUI)'.
  WRITE: / '7. DEVICE SUPPORT    : Desktop, Tablet, Phone (RF Scanners)'.
  WRITE: / '8. TILE TYPE         : Static Tile'.
  WRITE: / '9. TILE TITLE        : RF Stock Transfer'.
  WRITE: / '10. TILE SUBTITLE    : Reservation / TR to WM Bin'.
  WRITE: / '11. TILE ICON        : sap-icon://bar-code'.
  WRITE: / '12. BUSINESS CATALOG : ZBC_WAREHOUSE (or ZBC_LOGISTICS)'.
  SKIP 1.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / 'DIRECT ACCESS URLS FOR TESTING:'.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / '• WebGUI Direct URL (Primary):'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZRF_RESWM'.
  WRITE: / '• WebGUI Direct URL (Short Code):'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZRF01'.
  WRITE: / '• Fiori Launchpad Intent URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#RFTransfer-manage'.
  WRITE: / '--------------------------------------------------------------'.
