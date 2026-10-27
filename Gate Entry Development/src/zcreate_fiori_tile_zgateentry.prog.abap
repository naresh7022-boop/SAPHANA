*&---------------------------------------------------------------------*
*& Report ZCREATE_FIORI_TILE_ZGATEENTRY
*& Purpose: Register Semantic Objects and prepare SAP Fiori Launchpad
*&          Target Mapping and Tile configuration for ZGATEENTRY
*& Author:  NARESH
*& Date:    26.10.2026
*& Package: $TMP
*& Transaction: ZGATEENTRY
*& System:  SAP S/4HANA DS4/220
*&---------------------------------------------------------------------*
REPORT zcreate_fiori_tile_zgateentry.

TABLES: /ui2/semobjc, /ui2/semobjct.

DATA: ls_c  TYPE /ui2/semobjc,
      ls_ct TYPE /ui2/semobjct.

START-OF-SELECTION.

  WRITE: / '=============================================================='.
  WRITE: / '  SAP FIORI LAUNCHPAD TILE CONFIGURATION FOR ZGATEENTRY       '.
  WRITE: / '=============================================================='.
  SKIP 1.

  " ------------------------------------------------------------------
  " 1. Register Custom Semantic Object: GateEntry
  " ------------------------------------------------------------------
  ls_c-sem_obj = 'GateEntry'.
  INSERT /ui2/semobjc FROM ls_c.
  IF sy-subrc = 0.
    WRITE: / '✓ SUCCESS: Registered Semantic Object GateEntry in /UI2/SEMOBJC'.
  ELSE.
    UPDATE /ui2/semobjc FROM ls_c.
    WRITE: / '✓ OK: Semantic Object GateEntry exists in /UI2/SEMOBJC'.
  ENDIF.

  ls_ct-language     = 'E'.
  ls_ct-sem_obj      = 'GateEntry'.
  ls_ct-sem_obj_name = 'GateEntry'.
  ls_ct-sem_obj_text = 'Gate Entry & Material Inward Cockpit'.
  INSERT /ui2/semobjct FROM ls_ct.
  IF sy-subrc <> 0.
    UPDATE /ui2/semobjct FROM ls_ct.
  ENDIF.
  WRITE: / '✓ SUCCESS: Maintained English text in /UI2/SEMOBJCT for GateEntry'.

  " ------------------------------------------------------------------
  " 2. Register Custom Semantic Object: ZGateEntry
  " ------------------------------------------------------------------
  ls_c-sem_obj = 'ZGateEntry'.
  INSERT /ui2/semobjc FROM ls_c.
  IF sy-subrc = 0.
    WRITE: / '✓ SUCCESS: Registered Semantic Object ZGateEntry in /UI2/SEMOBJC'.
  ELSE.
    UPDATE /ui2/semobjc FROM ls_c.
    WRITE: / '✓ OK: Semantic Object ZGateEntry exists in /UI2/SEMOBJC'.
  ENDIF.

  ls_ct-language     = 'E'.
  ls_ct-sem_obj      = 'ZGateEntry'.
  ls_ct-sem_obj_name = 'ZGateEntry'.
  ls_ct-sem_obj_text = 'Custom Gate Entry Management'.
  INSERT /ui2/semobjct FROM ls_ct.
  IF sy-subrc <> 0.
    UPDATE /ui2/semobjct FROM ls_ct.
  ENDIF.
  WRITE: / '✓ SUCCESS: Maintained English text in /UI2/SEMOBJCT for ZGateEntry'.

  COMMIT WORK AND WAIT.

  SKIP 1.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / 'FIORI LAUNCHPAD TILE & TARGET MAPPING PARAMETERS:'.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / '1. SEMANTIC OBJECT   : GateEntry (or ZGateEntry)'.
  WRITE: / '2. ACTION            : manage'.
  WRITE: / '3. INTENT            : #GateEntry-manage'.
  WRITE: / '4. APPLICATION TYPE  : Transaction'.
  WRITE: / '5. TRANSACTION CODE  : ZGATEENTRY'.
  WRITE: / '6. GUI TYPE          : SAP GUI for HTML (WebGUI)'.
  WRITE: / '7. DEVICE SUPPORT    : Desktop, Tablet, Phone'.
  WRITE: / '8. TILE TYPE         : Static Tile'.
  WRITE: / '9. TILE TITLE        : Gate Entry Cockpit'.
  WRITE: / '10. TILE SUBTITLE    : Material Inward / Outward Entry'.
  WRITE: / '11. TILE ICON        : sap-icon://shipping-status'.
  WRITE: / '12. BUSINESS CATALOG : ZBC_INVENTORY (or ZBC_LOGISTICS)'.
  SKIP 1.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / 'DIRECT ACCESS URLS FOR TESTING:'.
  WRITE: / '--------------------------------------------------------------'.
  WRITE: / '• WebGUI Direct URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZGATEENTRY'.
  WRITE: / '• Fiori Launchpad Intent URL:'.
  WRITE: / '  https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#GateEntry-manage'.
  WRITE: / '--------------------------------------------------------------'.
