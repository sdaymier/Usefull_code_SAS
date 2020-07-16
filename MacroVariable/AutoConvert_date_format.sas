/* ******************************************************************** */
/* Convertisseur "automatique" de format date SAS						            */
/* ******************************************************************** */
/* Auteur : Sarah DAYMIER												                        */
/* Date : Juillet 2020													                        */
/* ******************************************************************** */
/* PARAMETRE EN ENTREE :												                        */
/*	-> nom : Nom de la macro variable créée en sortie 					        */
/*	-> val : Date a transformer 										                    */
/*	-> myfmt : le format a appliquer sur la date 						            */
/* ******************************************************************** */
/* Quelques exemples de format DATE 									                  */
/* 	-> DDMMYY10. : 25/01/2001											                      */
/* 	-> DDMMYYB10. : 25 01 2001											                    */
/* 	-> MMYYS7. : 01/2001												                        */
/* 	-> YEAR4. : 2001													                          */
/* 	-> DATE9. : 25JAN2001												                        */
/* 	-> datetime. : 02JAN21:17:40:01										                  */
/* ******************************************************************** */


%macro convert_format_date(nom= , val= , myfmt = );
	
	options DATESTYLE=MDY; /* Uniformisation des formats : US */

	/* Déclaration des variables locales */
	%local saveOptions;

	/* Déclaration des variables globales */
	%global &nom.;

	/* Vérification des arguments */
	%if %length(&nom) = 0 or
		%length(&val) = 0 %then %do;
		%put >>>> ERROR: Un des paramètres (nom ou val) est manquant;
		%abort cancel;
	%end;

	/* Si "fmt" n'est pas spécifié, on le fixe à 8. */
	%if %length(&fmt)=0 %then %let fmt = yymmn6.;

	/* Sauvegarder et modifier l'option notes */
	%let saveOptions = %sysfunc(getoption(notes));
	options nonotes;


	/* Modification des formats e tutti quanti */
	proc sql;
		create table dates
		(cdate char(40));
		insert into dates
		values("&val.")
	;quit;
	Data Convert;
		Set dates;
		Date = Input (cdate, ANYDTDTE21.);
		Format date &myfmt..;
		call symputx("&nom.", put(date, &myfmt..), 'g');
	Run;

	/* Restaurer l'option notes/nonotes */
	options &saveOptions;

	proc delete data=dates; run;
%mend;

%convert_format_date(nom= mydatebis, val= 20200301, myfmt = date9);
%put >>>>>>>>>>>>> &mydatebis.;

%convert_format_date(nom= mydateter, val= 01MAR2020, myfmt = yymmn6);
%put >>>>>>>>>>>>> &mydatebis.;
