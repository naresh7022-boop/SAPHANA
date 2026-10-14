*&---------------------------------------------------------------------*
*& Include          ZMM_R_079_S01
*&---------------------------------------------------------------------*

SELECTION-SCREEN : BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001 ##TEXT_POOL.
  SELECT-OPTIONS : s_ekorg FOR ekko-ekorg DEFAULT 'AE01',
                    s_ebeln FOR ekko-ebeln,
                    s_submi FOR ekko-submi NO INTERVALS NO-EXTENSION,
                    s_lifnr FOR ekko-lifnr,
                    s_matnr FOR ekpo-matnr.
SELECTION-SCREEN : END OF BLOCK b1.