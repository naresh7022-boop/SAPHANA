*&---------------------------------------------------------------------*
*& Include          ZMM_R_079_T01
*&---------------------------------------------------------------------*

TABLES : ekko,ekpo.

TYPES : BEGIN OF ty_hdr,
          ebeln TYPE ekko-ebeln,
          matnr TYPE ekpo-matnr,
          lifnr TYPE ekko-lifnr,
          name1 TYPE lfa1-name1,
          submi TYPE ekko-submi,
          ihrez TYPE ekko-ihrez,
          inco1 TYPE ekko-inco1,
          text1 TYPE t052u-text1,
          ztag1 TYPE t052-ztag1,
          waers TYPE ekko-waers,
          wkurs TYPE ekko-wkurs,
        END OF ty_hdr,

        BEGIN OF ty_final,
          matnr       TYPE mara-matnr,
          maktx       TYPE makt-maktx,
          quat(10)    TYPE c,
          quat1(40)   TYPE c, "ekko-ebeln,
          quat2(40)   TYPE c, "ekko-ebeln,
          quat3(40)   TYPE c, "ekko-ebeln,
          quat4(40)   TYPE c, "ekko-ebeln,
          quat5(40)   TYPE c, "ekko-ebeln,
          quat6(40)   TYPE c, "ekko-ebeln,
          quat7(40)   TYPE c, "ekko-ebeln,
          mean(15)    TYPE c,
          minimum(15) TYPE c,
          color       TYPE slis_specialcol_alv,
        END OF ty_final,

        BEGIN OF ty_rank,
          lifnr   TYPE lfa1-lifnr,
          amount  TYPE ekpo-netwr,
          amount1 TYPE ekpo-netwr,
        END OF ty_rank.

DATA : gt_final    TYPE TABLE OF ty_final,
       gt_final1   TYPE TABLE OF ty_final,
       gs_final    TYPE ty_final,
       gt_hdr      TYPE TABLE OF ty_hdr,
       gs_hdr      TYPE ty_hdr,
       ls_interest LIKE LINE OF gt_final1,

       lt_rank     TYPE STANDARD TABLE OF ty_rank,
       ls_rank     TYPE ty_rank,
       lv_amt      TYPE ekpo-netwr,
       lv_rank     TYPE i,

       ls_total    LIKE LINE OF gt_final,

       gs_val      LIKE gs_final,
       gs_rank     LIKE gs_final,
       gs_pkg      LIKE gs_final,
       gs_app      LIKE gs_final,

       lv_matnr    TYPE mara-matnr,

       lv_mean     TYPE ekpo-netpr,
       lv_minimum  TYPE ekpo-netpr.

DATA : int_days  TYPE f VALUE '0.12'.
DATA : lv_result TYPE ekpo-netpr,
       lv_val    TYPE ekpo-netwr.