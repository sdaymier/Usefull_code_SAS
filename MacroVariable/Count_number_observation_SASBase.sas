/* ******************************************************************** */
/* Diff�rentes m�thodes pour obtenir le nombre d'observation contenu 
/* dans une table SAS */
/* ******************************************************************** */

/* ******************************************************************** */
/* M�thode 1 : */
/* Avoir recours aux m�tadonn�es si elles sont disponibles 		*/
/* ******************************************************************** */

proc sql noprint;
	select nobs into: nb_obs
	from dictionary.tables 
	where upcase(libname)="SASHELP" 
	  and upcase(memname)="CARS"
; quit;
%put &nb_obs.;

/* ******************************************************************** */
/* M�thode 2 : */
/* La macrovariable automatique � sqlobs � 
/* ******************************************************************** */

proc sql;
	create table tmp as
	select *
	from sashelp.cars
; quit;
%let nb_obs = &sqlobs.;
%put &nb_obs.;

/* ******************************************************************** */
/* M�thode 2 : */
/* Recours aux fonctions open / attrn : 
/* ******************************************************************** */

%let dsid     = %sysfunc(open(sashelp.cars,in));
%let nb_obs   = %sysfunc(attrn(&dsid,nobs));
%put &nb_obs.;



