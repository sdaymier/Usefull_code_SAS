
/* ******************************************************************** */
/* >>> Discretisation des variables par rapport a une catégorielle 		*/
/* ******************************************************************** */
/* Parametre en entrée : 												*/
/*     -> table : base en input 										*/
/*     -> varTarget : variable cible (généralement binaire)				*/
/*     -> varX : variable continue à discretiser						*/
/*     -> nbGroupes : nombre de groupe à construire à priori			*/
/*     -> seuil: seuil d'acceptabilité du regroupement 					*/
/* ******************************************************************** */
/* ******************************************************************** */

%MACRO aov16 (table, varTarget, varX, nbGroupes=16, seuil=0.0001) ;
	%LOCAL maxP n objODS p g1 g2 diff ;

    PROC SQL ;
    %IF %SYSFUNC(EXIST(work.groupes)) %THEN %DO ;
       DROP TABLE work.groupes ;
    %END ;
    %IF %SYSFUNC(EXIST(work.__data)) %THEN %DO ;
       DROP TABLE work.__data ;
    %END ;
    QUIT ;

    PROC RANK DATA = &table (KEEP=&varTarget &varX) 
               OUT = work.__data
            GROUPS = &nbGroupes 
              TIES = LOW ;
        VAR &varX ;
        RANKS __grp ;
    RUN ;

    %IF &sysVlong >= 9.02.02M3 %THEN %DO ;
              %LET objODS=diffs ;
              %LET p=probZ ;
    %END ;
    %ELSE %DO ;
              %LET objODS=LSMeanDiffs ;
              %LET p=probChisq ;
    %END ;




	%LET maxP = 1 ;

	PROC SQL NOPRINT ;
	  SELECT COUNT(DISTINCT __grp) INTO : n 
	  FROM work.__data ;
	QUIT ;

    ODS EXCLUDE ALL ;

	%DO %WHILE (&n > 1) ;

	    PROC GENMOD DATA = work.__data ;
	        CLASS __grp ;
	        MODEL &varTarget = __grp / DIST=BIN ;
	        LSMEANS __grp /  
	                   %IF &sysvlong >= 9.02.02M3 %THEN 
	                      DIFF=ALL ;
						%ELSE  DIFF ;
	        ;
	        ODS OUTPUT &objODS = work.__d
	             (KEEP=&p __grp ___grp) ;
	    RUN ;


		PROC TRANSPOSE DATA=work.__d OUT=work.__d2 (DROP=_name_ _label_) PREFIX=p ;
		  ID ___grp ;
		  BY __grp ;
		  VAR &p ;
		RUN ;


		DATA work.__d2 (KEEP=__grp prob avec) ;
		  SET work.__d2 ;
		  ARRAY p p: ;
		  prob = p[_N_] ;
		  avec = SUBSTR(VNAME(p[_N_]),2)+0 ;
		RUN ;


		PROC SQL NOPRINT OUTOBS=1 ;
		  SELECT __grp, avec, prob FORMAT=BEST12.
		  INTO : g1, : g2, : maxP
		  FROM work.__d2
		  ORDER BY prob DESC ;
		QUIT ;


		%LET diff = %SYSEVALF(&maxP - &seuil) ;
		%LET diff = %SYSFUNC(SIGN(&diff)) ;
	    %IF &diff > 0 %THEN %DO ;
			DATA work.__data ;
			  SET work.__data ;
			  IF __grp IN (&g1, &g2) THEN __grp = &g1 ;
			RUN ;
			%LET n = %EVAL(&n-1) ;
			%PUT NOTE: fusion des groupes &g1 et &g2 (p=%SYSFUNC(ROUND(&maxP,0.00001),PVALUE5.)) ;
		%END ;
		%ELSE %GOTO fini ;
	%END ;

	%fini:
	ODS SELECT ALL ;
	TITLE10 "Partition en &n groupes" ;

	PROC REPORT DATA = work.__data NOWD 
				 OUT = base_format (drop  = _BREAK_ __grp
							rename = (_C3_ = min _C4_ = max)
							where  = (not missing(num))
							) ;
	  COLUMNS __grp num &varX, (MIN MAX) ;
	  DEFINE __grp / GROUP NOPRINT ;
	  DEFINE num / COMPUTED "Groupe" ;
	  DEFINE &varX / ANALYSIS;
      
	 
	  COMPUTE BEFORE ;
	    n = 0 ;
	  ENDCOMP ;
	  COMPUTE num ;
	    n = n + 1 ;
		num = n ;
	  ENDCOMP ;
      

	RUN ;
	TITLE10 ;


%MEND aov16 ;

