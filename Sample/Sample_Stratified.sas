/* ******************************************************************** */
/* ******************************************************************** */
/* 			MACRO - Echantillonnage				*/
/* ******************************************************************** */
/* ******************************************************************** */
/* Auteur 	: Sarah Daymier 					*/
/* Date 	: 2019-05-14						*/
/* -------------------------------------------------------------------- */
/* Objectif : Macros pour réaliser des echantillonnages	stratifié	*/
/* ******************************************************************** */

%macro obsnvars(ds);
   %global dset nvars nb_obs;
   %let dset=&ds;

   /* Open data set passed as the macro parameter */
   %let dsid = %sysfunc(open(&dset));

   /* If the data set exists, get the number of observations */
   /* and variables and then close the data set */
   %if &dsid %then
   %do;
      %let nb_obs =%sysfunc(attrn(&dsid,nobs));
      %let nvars=%sysfunc(attrn(&dsid,nvars));
      %let rc = %sysfunc(close(&dsid));
   %end;

   /* Otherwise, write a message that the data set could not be opened */
   %else %put open for data set &dset failed - %sysfunc(sysmsg());

%mend obsnvars;

/* ******************************************************************** */
/*  Macros - Echantillonnage Stratifie					*/
/* (selon la fréquence des observations par rapport a une modalité) 	*/ 
/* ******************************************************************** */

%macro sample_stratified_with_frequency(  tabin = 
					, var_strat = 
					, SampleRate = 
					, ID = );

/* ******************************************************************** */
/* Paramètres								*/
/* -------------------------------------------------------------------- */
/* - TABIN 		: Table en entrée 				*/
/* - VAR_STRAT 	: Variable pour la strate				*/
/* - SampleRate : Pourcentage obs que doit contenir echantillon en sortie */
/* - ID 		: Liste des identifiants (permet de faire la jointure 	*/
/*				  avec la base en input)		*/
/* - TABOUT		: Base en sortie (échantillon) 			*/
/* ******************************************************************** */

	/* Etape 0 - Calcul de la sampsize */
	/* %let dsid     = %sysfunc(open(&tabin.,in));
	%let nb_obs   = %sysfunc(attrn(&dsid,nobs));
	%put &nb_obs.; */

	proc sql;
		create table tmp as
		select *
		from &tabin.
	; quit;
	%let nb_obs = &sqlobs.;
	%put &nb_obs.;


	%put >>> &nb_obs.;
	%let SampleSize = %sysevalf(&nb_obs. * &SampleRate., floor);
	%put >>>> Taille echantillon : &SampleSize.;


	/* Etape 1 - Calcul des frequences */
	proc freq data =  &tabin.;
		tables &var_strat. / out = NEWFREQ ;
	run;

	/* Etape 2 - Calcul de la sampsize */
	DATA NEWFREQ2 ERROR;
		 SET NEWFREQ;
		 SAMPNUM=(PERCENT * &SampleSize.)/100;
		 _NSIZE_= ROUND(SAMPNUM,1);
		 SAMPNUM=ROUND(SAMPNUM,.01);
		 IF _NSIZE_=0 THEN OUTPUT ERROR;
		 IF _NSIZE_=0 THEN DELETE;
		 OUTPUT NEWFREQ2; 
	run;

	/* Etape 3 - Nettoyage de la base */
	DATA NEWFREQ3;
		SET NEWFREQ2;
		KEEP &var_strat. _NSIZE_;
	run;

	/* Etape 4 - Preparation des bases avant échantillonnage */
	PROC SORT DATA = NEWFREQ3;	BY &var_strat.; run; 
	PROC SORT DATA = &tabin.;	BY &var_strat.; run; 

	/* Etape 5 - Echantillonnage stratifié */
	PROC SURVEYSELECT DATA=&tabin.
		OUT=SAMPLSTRATA 
		SAMPSIZE=NEWFREQ3;
		STRATA &var_strat.;
		ID &ID.  &var_strat.; 
	run;

	/* Etape 6 - Vérification */
	PROC FREQ DATA = SAMPLSTRATA;
		TABLES &var_strat./OUT=SAMPFREQ NOPRINT;
	run;

	/* Etape 7 - Jointure avec la base en entrée - objectif ajouter les variables explicatives */
	proc sort data = SAMPLSTRATA; by &ID.; run;
	proc sort data = &tabin.; by &ID.; run;

	/* Etape 8 - Création de la base d'apprentissage */
	data apprentissage;
		merge SAMPLSTRATA (in= a drop= SelectionProb SamplingWeight)
				&tabin. (in= b);
		by &ID.;
		if a;
	run;

	/* Etape 8 - Création de la base d'apprentissage */
	proc sql;
		create table test as 
		select *
		from &tabin.
		where &ID. not in (select distinct &ID. from apprentissage)
		;quit;

	/* Etape 8 - Nettoyage de la work */
	PROC DELETE DATA =  NEWFREQ 
						NEWFREQ2 
						NEWFREQ3 
						SAMPFL 
						SAMPLSTRATA
						SAMPFREQ 
						ERROR;
	run;

%mend;



