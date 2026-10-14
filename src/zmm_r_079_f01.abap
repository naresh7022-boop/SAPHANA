*&---------------------------------------------------------------------*
*& Include          ZMM_R_079_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data .


  SELECT FROM ekko
    INNER JOIN ekpo ON ekko~ebeln = ekpo~ebeln
    LEFT JOIN lfa1 ON ekko~lifnr = lfa1~lifnr
    LEFT JOIN t052u ON ekko~zterm = t052u~zterm AND t052u~spras = @sy-langu
    LEFT JOIN t052 ON ekko~zterm = t052~zterm          "#EC CI_BUFFJOIN
    FIELDS ekko~ebeln,
           ekko~submi,
           ekko~ekorg,
           ekko~lifnr,
           ekko~ihrez,
           ekko~inco1,
           ekko~waers,
           ekko~wkurs,
           ekpo~ebelp,
           ekpo~matnr,
           ekpo~txz01,
           ekpo~ktmng,
           ekpo~meins,
           ekpo~netpr,
           lfa1~name1,
           t052~ztag1,
           t052u~text1 WHERE ekko~ebeln IN @s_ebeln
                        AND ekko~submi IN @s_submi
                        AND ekko~ekorg IN @s_ekorg
                        AND ekko~lifnr IN @s_lifnr
                        AND ekpo~matnr IN @s_matnr
                  INTO TABLE @DATA(it_data).


  IF it_data IS NOT INITIAL.

*    BREAK ssingh.

    gt_hdr = VALUE #(
      FOR wa_data IN it_data (
        ebeln = wa_data-ebeln
        matnr = wa_data-matnr
        lifnr = wa_data-lifnr
        name1 = wa_data-name1
        submi = wa_data-submi
        ihrez = wa_data-ihrez
        inco1  = wa_data-inco1
        text1  = wa_data-text1
        ztag1  = wa_data-ztag1
        waers  = wa_data-waers
        wkurs  = wa_data-wkurs
      ) ).


    SORT gt_hdr BY lifnr ASCENDING.
    DELETE ADJACENT DUPLICATES FROM gt_hdr COMPARING lifnr .
*    SORT gt_hdr BY ebeln lifnr DESCENDING.
*    DELETE ADJACENT DUPLICATES FROM gt_hdr COMPARING ebeln lifnr .

    DATA(lv_count) = lines( gt_hdr ).

  ELSE.
    MESSAGE : 'No data found' TYPE 'E' ##NO_TEXT.
  ENDIF.

  CLEAR gt_final.

  gt_final = VALUE #(

  ( matnr   = 'Material'
    maktx   = 'Short Text' ##NO_TEXT
    quat    = 'Quot'
    quat1   = VALUE #( gt_hdr[ 1 ]-ebeln OPTIONAL )
    quat2   = VALUE #( gt_hdr[ 2 ]-ebeln OPTIONAL )
    quat3   = VALUE #( gt_hdr[ 3 ]-ebeln OPTIONAL )
    quat4   = VALUE #( gt_hdr[ 4 ]-ebeln OPTIONAL )
    quat5   = VALUE #( gt_hdr[ 5 ]-ebeln OPTIONAL )
    quat6   = VALUE #( gt_hdr[ 6 ]-ebeln OPTIONAL )
    quat7   = VALUE #( gt_hdr[ 7 ]-ebeln OPTIONAL )
    mean    = 'Mean'
    minimum = 'Minimum'
   color = 'C210' )

  ( maktx = 'Supplier Name'
    quat1 = VALUE #( gt_hdr[ 1 ]-name1 OPTIONAL )
    quat2 = VALUE #( gt_hdr[ 2 ]-name1 OPTIONAL )
    quat3 = VALUE #( gt_hdr[ 3 ]-name1 OPTIONAL )
    quat4 = VALUE #( gt_hdr[ 4 ]-name1 OPTIONAL )
    quat5 = VALUE #( gt_hdr[ 5 ]-name1 OPTIONAL )
    quat6 = VALUE #( gt_hdr[ 6 ]-name1 OPTIONAL )
    quat7 = VALUE #( gt_hdr[ 7 ]-name1 OPTIONAL ) )

  ( maktx = 'Coll. No.'
    quat1 = VALUE #( gt_hdr[ 1 ]-submi OPTIONAL )
    quat2 = VALUE #( gt_hdr[ 2 ]-submi OPTIONAL )
    quat3 = VALUE #( gt_hdr[ 3 ]-submi OPTIONAL )
    quat4 = VALUE #( gt_hdr[ 4 ]-submi OPTIONAL )
    quat5 = VALUE #( gt_hdr[ 5 ]-submi OPTIONAL )
    quat6 = VALUE #( gt_hdr[ 6 ]-submi OPTIONAL )
    quat7 = VALUE #( gt_hdr[ 7 ]-submi OPTIONAL ) )

  ( maktx = 'Quotation Ref. No.'
    quat1 = VALUE #( gt_hdr[ 1 ]-ihrez OPTIONAL )
    quat2 = VALUE #( gt_hdr[ 2 ]-ihrez OPTIONAL )
    quat3 = VALUE #( gt_hdr[ 3 ]-ihrez OPTIONAL )
    quat4 = VALUE #( gt_hdr[ 4 ]-ihrez OPTIONAL )
    quat5 = VALUE #( gt_hdr[ 5 ]-ihrez OPTIONAL )
    quat6 = VALUE #( gt_hdr[ 6 ]-ihrez OPTIONAL )
    quat7 = VALUE #( gt_hdr[ 7 ]-ihrez OPTIONAL ) )
 ).


  DATA(it_data1) = it_data.
*  SORT it_data BY ebelp matnr.
  SORT it_data1 BY ebelp matnr.
  DELETE ADJACENT DUPLICATES FROM it_data1 COMPARING ebelp matnr.

  SORT it_data BY lifnr ASCENDING.

  LOOP AT it_data1 INTO DATA(ls_data1).

    REFRESH :lt_rank.
    lv_rank = 1.
    CLEAR: gs_val, gs_rank, gs_pkg, gs_app.

    gs_val-color   = 'C310'.
    APPEND gs_val  TO gt_final.
    CLEAR : gs_val.

    gs_val-matnr  = ls_data1-matnr.
    gs_val-maktx  = ls_data1-txz01.
    gs_val-quat   = 'Val:' ##NO_TEXT.

    gs_rank-quat  = 'Rank:' ##NO_TEXT.

    gs_pkg-matnr  = 'Total Qty' ##NO_TEXT.
    gs_pkg-maktx  = ls_data1-ktmng.
    gs_pkg-quat   = 'Per Kg' ##NO_TEXT.

    gs_app-quat   = 'Approved' ##NO_TEXT.


    LOOP AT it_data INTO DATA(ls_data) WHERE ebelp = ls_data1-ebelp AND matnr = ls_data1-matnr.
      IF ls_data-waers = 'USD'.
        lv_val = |{ ( ls_data-ktmng * ls_data-netpr ) * ls_data-wkurs }|.
      ELSE.
        lv_val = |{ ls_data-ktmng * ls_data-netpr }|.
      ENDIF.

      CLEAR ls_rank.
      ls_rank-lifnr  = ls_data-lifnr.
      ls_rank-amount = lv_val.

      IF ls_data-waers = 'USD'.
        ls_rank-amount1 = ls_data-netpr * ls_data-wkurs.
      ELSE.
        ls_rank-amount1 = ls_data-netpr.
      ENDIF.
      APPEND ls_rank TO lt_rank.

      IF ls_data-lifnr = gt_hdr[ 1 ]-lifnr.
        gs_val-quat1 = lv_val.
        gs_pkg-quat1 = |{ ls_rank-amount1 }|.

      ELSEIF ls_data-lifnr = gt_hdr[ 2 ]-lifnr.
        gs_val-quat2 = lv_val.
        gs_pkg-quat2 = |{ ls_rank-amount1 }|.

      ELSEIF ls_data-lifnr = gt_hdr[ 3 ]-lifnr.
        gs_val-quat3 = lv_val.
        gs_pkg-quat3 = |{ ls_rank-amount1 }|.

      ELSEIF ls_data-lifnr = gt_hdr[ 4 ]-lifnr.
        gs_val-quat4 = lv_val.
        gs_pkg-quat4 = |{ ls_rank-amount1 }|.

      ELSEIF ls_data-lifnr = gt_hdr[ 5 ]-lifnr.
        gs_val-quat5 = lv_val.
        gs_pkg-quat5 = |{ ls_rank-amount1 }|.

      ELSEIF ls_data-lifnr = gt_hdr[ 6 ]-lifnr.
        gs_val-quat6 = lv_val.
        gs_pkg-quat6 = |{ ls_rank-amount1 }|.

      ELSEIF ls_data-lifnr = gt_hdr[ 7 ]-lifnr.
        gs_val-quat7 = lv_val.
        gs_pkg-quat7 = |{ ls_rank-amount1 }|.
      ENDIF.

      CONDENSE : gs_val-quat1,gs_val-quat2,gs_val-quat3,gs_val-quat4,gs_val-quat5,gs_val-quat6,gs_val-quat7.

    ENDLOOP.

*    BREAK ssingh.
    lv_mean = ( gs_val-quat1 + gs_val-quat2 + gs_val-quat3 + gs_val-quat4 + gs_val-quat5 + gs_val-quat6 + gs_val-quat7 ) / lv_count.
    gs_val-mean = |{ lv_mean }|.
    CLEAR : lv_mean .
    lv_mean  = ( gs_pkg-quat1 + gs_pkg-quat2 + gs_pkg-quat3 + gs_pkg-quat4 + gs_pkg-quat5 + gs_pkg-quat6 + gs_pkg-quat7 ) / lv_count.
    gs_pkg-mean = |{ lv_mean }|.





    SORT lt_rank BY amount ASCENDING.
    LOOP AT lt_rank INTO ls_rank.

      IF ls_rank-lifnr = gt_hdr[ 1 ]-lifnr.
        gs_rank-quat1 = |{ lv_rank }|.
        IF lv_rank = 1.
          gs_app-quat1 = 'Yes'.
          gs_val-minimum = |{ ls_rank-amount }|.
          gs_pkg-minimum = |{ ls_rank-amount1 }|.
        ENDIF.
      ELSEIF ls_rank-lifnr = gt_hdr[ 2 ]-lifnr.
        gs_rank-quat2 = |{ lv_rank }|.
        IF lv_rank = 1.
          gs_app-quat2 = 'Yes'.
          gs_val-minimum = |{ ls_rank-amount }|.
          gs_pkg-minimum = |{ ls_rank-amount1 }|.
        ENDIF.
      ELSEIF ls_rank-lifnr = gt_hdr[ 3 ]-lifnr.
        gs_rank-quat3 = |{ lv_rank }|.
        IF lv_rank = 1.
          gs_app-quat3 = 'Yes'.
          gs_val-minimum = |{ ls_rank-amount }|.
          gs_pkg-minimum = |{ ls_rank-amount1 }|.
        ENDIF.
      ELSEIF ls_rank-lifnr = gt_hdr[ 4 ]-lifnr.
        gs_rank-quat4 = |{ lv_rank }|.
        IF lv_rank = 1.
          gs_app-quat4 = 'Yes'.
          gs_val-minimum = |{ ls_rank-amount }|.
          gs_pkg-minimum = |{ ls_rank-amount1 }|.
        ENDIF.
      ELSEIF ls_rank-lifnr = gt_hdr[ 5 ]-lifnr.
        gs_rank-quat5 = |{ lv_rank }|.
        IF lv_rank = 1.
          gs_app-quat5 = 'Yes'.
          gs_val-minimum = |{ ls_rank-amount }|.
          gs_pkg-minimum = |{ ls_rank-amount1 }|.
        ENDIF.
      ELSEIF ls_rank-lifnr = gt_hdr[ 6 ]-lifnr.
        gs_rank-quat6 = |{ lv_rank }|.
        IF lv_rank = 1.
          gs_app-quat6 = 'Yes'.
          gs_val-minimum = |{ ls_rank-amount }|.
          gs_pkg-minimum = |{ ls_rank-amount1 }|.
        ENDIF.
      ELSEIF ls_rank-lifnr = gt_hdr[ 7 ]-lifnr.
        gs_rank-quat7 = |{ lv_rank }|.
        IF lv_rank = 1.
          gs_app-quat7 = 'Yes'.
          gs_val-minimum = |{ ls_rank-amount }|.
          gs_pkg-minimum = |{ ls_rank-amount1 }|.
        ENDIF.
      ENDIF.

      lv_rank = lv_rank + 1.

    ENDLOOP.


    APPEND gs_val  TO gt_final.
    APPEND gs_rank TO gt_final.
    APPEND gs_pkg  TO gt_final.
    APPEND gs_app  TO gt_final.

  ENDLOOP.


  CLEAR ls_total.
  ls_total-maktx = 'Total Quotation Amount' ##NO_TEXT.


  ls_total-quat1 = |{ REDUCE decfloat34(
                       INIT s = CONV decfloat34( 0 )
                       FOR ls IN gt_final
                       WHERE ( quat = 'Val:' ) ##NO_TEXT
                       NEXT s = s + CONV decfloat34( ls-quat1 )
                     ) DECIMALS = 2 }|.

  ls_total-quat2 = |{ REDUCE decfloat34(
                       INIT s = CONV decfloat34( 0 )
                       FOR ls IN gt_final WHERE ( quat = 'Val:' ) ##NO_TEXT
                       NEXT s = s + CONV decfloat34( ls-quat3 )
                     ) DECIMALS = 2 }|.

  ls_total-quat3 = |{ REDUCE decfloat34(
                        INIT s = CONV decfloat34( 0 )
                        FOR ls IN gt_final WHERE ( quat = 'Val:' ) ##NO_TEXT
                        NEXT s = s + CONV decfloat34( ls-quat3 )
                         ) DECIMALS = 2 }|.

  ls_total-quat4 = |{ REDUCE decfloat34(
                        INIT s = CONV decfloat34( 0 )
                        FOR ls IN gt_final WHERE ( quat = 'Val:' ) ##NO_TEXT
                        NEXT s = s + CONV decfloat34( ls-quat4 ) ) DECIMALS = 2 }|.

  ls_total-quat5 = |{ REDUCE decfloat34(
                        INIT s = CONV decfloat34( 0 )
                        FOR ls IN gt_final WHERE ( quat = 'Val:' ) ##NO_TEXT
                        NEXT s = s + CONV decfloat34( ls-quat5 ) ) DECIMALS = 2  }|.

  ls_total-quat6 = |{ REDUCE decfloat34(
                        INIT s = CONV decfloat34( 0 )
                        FOR ls IN gt_final WHERE ( quat = 'Val:' ) ##NO_TEXT
                        NEXT s = s + CONV decfloat34( ls-quat6 ) ) DECIMALS = 2 }|.

  ls_total-quat7 = |{ REDUCE decfloat34(
                        INIT s = CONV decfloat34( 0 )
                        FOR ls IN gt_final WHERE ( quat = 'Val:' ) ##NO_TEXT
                        NEXT s = s + CONV decfloat34( ls-quat7 ) ) DECIMALS = 2 }|.

*  ls_total-mean = |{ REDUCE decfloat34(
*                      INIT s = CONV decfloat34( 0 )
*                      FOR ls IN gt_final WHERE ( quat = 'Val:' )
*                      NEXT s = s + CONV decfloat34( ls-mean ) ) }|.
*
*  ls_total-minimum = |{ REDUCE decfloat34(
*                        INIT s = CONV decfloat34( 0 )
*                        FOR ls IN gt_final WHERE ( quat = 'Val:' )
*                        NEXT s = s + CONV decfloat34( ls-minimum ) ) }|.

  ls_total-color = 'C110'.

  APPEND ls_total TO gt_final.
  APPEND ls_total TO gt_final1.


  APPEND VALUE #(
    matnr   = ''
    maktx   = 'Incoterms'  ##NO_TEXT
    quat1   = VALUE #( gt_hdr[ 1 ]-inco1 OPTIONAL )
    quat2   = VALUE #( gt_hdr[ 2 ]-inco1 OPTIONAL )
    quat3   = VALUE #( gt_hdr[ 3 ]-inco1 OPTIONAL )
    quat4   = VALUE #( gt_hdr[ 4 ]-inco1 OPTIONAL )
    quat5   = VALUE #( gt_hdr[ 5 ]-inco1 OPTIONAL )
    quat6   = VALUE #( gt_hdr[ 6 ]-inco1 OPTIONAL )
    quat7   = VALUE #( gt_hdr[ 7 ]-inco1 OPTIONAL )
    color   = 'C110'
  ) TO gt_final.

  APPEND VALUE #(
    matnr   = ''
    maktx   = 'Payment Terms' ##NO_TEXT
    quat1   = VALUE #( gt_hdr[ 1 ]-text1 OPTIONAL )
    quat2   = VALUE #( gt_hdr[ 2 ]-text1 OPTIONAL )
    quat3   = VALUE #( gt_hdr[ 3 ]-text1 OPTIONAL )
    quat4   = VALUE #( gt_hdr[ 4 ]-text1 OPTIONAL )
    quat5   = VALUE #( gt_hdr[ 5 ]-text1 OPTIONAL )
    quat6   = VALUE #( gt_hdr[ 6 ]-text1 OPTIONAL )
    quat7   = VALUE #( gt_hdr[ 7 ]-text1 OPTIONAL )
    color   = 'C110'
  ) TO gt_final.


  APPEND VALUE #(
    quat1 = |{ CONV i( VALUE #( gt_hdr[ 1 ]-ztag1 OPTIONAL ) ) }|
    quat2 = |{ CONV i( VALUE #( gt_hdr[ 2 ]-ztag1 OPTIONAL ) ) }|
    quat3 = |{ CONV i( VALUE #( gt_hdr[ 3 ]-ztag1 OPTIONAL ) ) }|
    quat4 = |{ CONV i( VALUE #( gt_hdr[ 4 ]-ztag1 OPTIONAL ) ) }|
    quat5 = |{ CONV i( VALUE #( gt_hdr[ 5 ]-ztag1 OPTIONAL ) ) }|
    quat6 = |{ CONV i( VALUE #( gt_hdr[ 6 ]-ztag1 OPTIONAL ) ) }|
    quat7 = |{ CONV i( VALUE #( gt_hdr[ 7 ]-ztag1 OPTIONAL ) ) }|
  ) TO gt_final1.


  DATA(lt_days) = VALUE int4_table(
                  ( CONV i( gt_final1[ 2 ]-quat1 ) )
                  ( CONV i( gt_final1[ 2 ]-quat2 ) )
                  ( CONV i( gt_final1[ 2 ]-quat3 ) )
                  ( CONV i( gt_final1[ 2 ]-quat4 ) )
                  ( CONV i( gt_final1[ 2 ]-quat5 ) )
                  ( CONV i( gt_final1[ 2 ]-quat6 ) )
                  ( CONV i( gt_final1[ 2 ]-quat7 ) ) ).



  DATA(lv_max_days) = REDUCE i( INIT max = 0 FOR day IN lt_days NEXT max = nmax( val1 = max val2 = day ) ).

  APPEND VALUE #(
  matnr   = ''
  maktx   = 'Interest Rate(%)'  ##NO_TEXT
  quat1   = '12%'
  quat2   = '12%'
  quat3   = '12%'
  quat4   = '12%'
  quat5   = '12%'
  quat6   = '12%'
  quat7   = '12%'
  color   = 'C110'
) TO gt_final.


  CLEAR ls_interest.
  ls_interest-maktx = 'Interest Amount' ##NO_TEXT.

  READ TABLE gt_final1 INTO DATA(ls_days) INDEX 2.
  READ TABLE gt_final INTO DATA(ls_amt) WHERE maktx = 'Total Quot.' ##READ_WHERE_OK ##NO_TEXT.

  lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat1 ) ) * ls_amt-quat1 }|.
  ls_interest-quat1 = |{ lv_result }|.
  lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat2 ) ) * ls_amt-quat2 }|.
  ls_interest-quat2 = |{ lv_result }|.
  lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat3 ) ) * ls_amt-quat3 }|.
  ls_interest-quat3 = |{ lv_result }|.
  lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat4 ) ) * ls_amt-quat4 }|.
  ls_interest-quat4 = |{ lv_result }|.
  lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat5 ) ) * ls_amt-quat5 }|.
  ls_interest-quat5 = |{ lv_result }|.
  lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat6 ) ) * ls_amt-quat6 }|.
  ls_interest-quat6 = |{ lv_result }|.
  lv_result = |{ ( int_days / 365 ) * ( lv_max_days - CONV i( ls_days-quat7 ) ) * ls_amt-quat7 }|.
  ls_interest-color = 'C110'.

  APPEND ls_interest TO gt_final.
  CLEAR : ls_interest.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form Processing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM processing .


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display .

  DATA(it_fcat) = VALUE slis_t_fieldcat_alv( ( fieldname = 'MATNR'   seltext_m = ' '                   )
                                             ( fieldname = 'MAKTX'   seltext_m = ' '  outputlen = '40' )
                                             ( fieldname = 'QUAT'    seltext_m = ' '                   )
                                             ( fieldname = 'QUAT1'   seltext_m = ' '  outputlen = '20' hotspot = 'X' )
                                             ( fieldname = 'QUAT2'   seltext_m = ' '  outputlen = '20' hotspot = 'X' )
                                             ( fieldname = 'QUAT3'   seltext_m = ' '  outputlen = '20' hotspot = 'X' )
                                             ( fieldname = 'QUAT4'   seltext_m = ' '  outputlen = '20' hotspot = 'X' )
                                             ( fieldname = 'QUAT5'   seltext_m = ' '  outputlen = '20' hotspot = 'X' )
                                             ( fieldname = 'QUAT6'   seltext_m = ' '  outputlen = '20' hotspot = 'X' )
                                             ( fieldname = 'QUAT7'   seltext_m = ' '  outputlen = '20' hotspot = 'X' )
                                             ( fieldname = 'MEAN'    seltext_m = ' '  outputlen = '15' )
                                             ( fieldname = 'MINIMUM' seltext_m = ' '  outputlen = '15' ) ).


  DATA(ls_layout) = VALUE slis_layout_alv( no_colhead = 'X' info_fieldname = 'COLOR' ).

  LOOP AT it_fcat INTO DATA(wa_fcat).

    CASE wa_fcat-fieldname.

      WHEN 'QUAT1'.
        IF VALUE #( gt_hdr[ 1 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT2'.
        IF VALUE #( gt_hdr[ 2 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT3'.
        IF VALUE #( gt_hdr[ 3 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT4'.
        IF VALUE #( gt_hdr[ 4 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT5'.
        IF VALUE #( gt_hdr[ 5 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT6'.
        IF VALUE #( gt_hdr[ 6 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
      WHEN 'QUAT7'.
        IF VALUE #( gt_hdr[ 7 ]-ebeln OPTIONAL ) IS INITIAL.
          wa_fcat-no_out = 'X'.
        ENDIF.
    ENDCASE.
    MODIFY it_fcat FROM wa_fcat.

  ENDLOOP.


  CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = ls_layout
      it_fieldcat             = it_fcat
    TABLES
      t_outtab                = gt_final
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.



ENDFORM.
FORM user_command USING r_ucomm LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

*  BREAK ssingh.
  IF rs_selfield-tabindex = '1'.
    IF rs_selfield-value NE 'Mean' AND rs_selfield-value NE 'Minimum' AND rs_selfield-value NE 'Material'
      AND rs_selfield-value NE 'Short Text' AND rs_selfield-value NE 'Quot'.

      SET PARAMETER ID 'ANF' FIELD rs_selfield-value.
      CALL TRANSACTION 'ME47' AND SKIP FIRST SCREEN.     "#EC CI_CALLTA

    ENDIF.
  ENDIF.


ENDFORM.