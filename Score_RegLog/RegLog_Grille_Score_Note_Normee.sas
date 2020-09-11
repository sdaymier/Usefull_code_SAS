/* ******************************************************************** */
/* Normalisation note de score			            					*/
/* ******************************************************************** */
/* Auteur : Sarah DAYMIER												*/  
/* Date : Sept 2020													    */                 
/* ******************************************************************** */
/* Objectif : Transformer les proba en note de score compris entre 0 et */
/* un max a définir 													*/
/* ******************************************************************** */
/* WARNING : ce programme est a revoir en cas de croisement des 		*/
/* variables dans la procédure d'estimation du modèle reg log (problème */
/* sur le nom des variables / modalité) 								*/			
/* ******************************************************************** */

data mabase; set apprentissage; run;

/* -------------------------------------------------------------------- */
/* >>> Déclaration des macro variables 									*/
/* -------------------------------------------------------------------- */
%let base_apprentissage = mabase;
%let base_estimator     = Estimators_grille_model;
%let base_prediction 	= base_out_predict;
%let variable_cible 	= critere;

/* -------------------------------------------------------------------- */
/* Estimation du modèle final : 										*/
/* -------------------------------------------------------------------- */
/* Note : Pour pouvoir normaliser les coefficients de la grille de score*/
/* on a besoin de la table "ParameterEstimates" obtenu dans ods ouput   */
/* de la proc logistic. Cette table correspond à la table de sortie des */
/* estimations des coefficients et p-value 								*/
/* -------------------------------------------------------------------- */
/* Un exemple de procédure est donné ci dessous : 						*/
/*    ods output ParameterEstimates = &base_estimator. (drop = DF 
									rename = (ClassVal0 = modalite))		*/
/*    proc logistic   data=&base_apprentissage. 						*/
/*                    outmodel=monmodel;								*/
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/* >>> Retraitement de la table 										*/
/* -------------------------------------------------------------------- */
/* WARNING : la variable ClassVal0 générée automatiquement dans la 		*/
/* sortie correspond aux modalités de la variable 						*/
/* -------------------------------------------------------------------- */

	data &base_estimator.2 (drop = ClassVal0);
		format modalite $50.;
		retain variable modalite;
		set &base_estimator.;
		modalite = compress(upcase(ClassVal0));
	run;

/* -------------------------------------------------------------------- */
/* >>> Récupération de l'ensemble des modalités 						*/
/* -------------------------------------------------------------------- */
/* Les modalités de référence n'apparaissent pas dans la sortie, il 	*/
/* convient donc de les ajouter 										*/
/* -------------------------------------------------------------------- */
	proc sql;
		select distinct variable into: lst_var separated by " "
		from &base_estimator.
		where upcase(variable) NE "INTERCEPT"
	;quit;


	%macro listing_modalites_variables(tabin =, tabout= , list_var = );
		proc delete data =&tabout.; run;

		%let i = 1;%let cpt = 1;
		%do %while (%scan(&list_var., &i.) ne );
			%let vari = %scan(&list_var., &i.);
				%put >>> Traitement pour la variable i &i. : &vari.;

				proc sql;
					create table sortie as 
					select distinct &vari. as &vari.
					from &tabin.
				;quit;
				/* Formatage en caractere */
				data sortie (drop = &vari.);
					format variable $50.;
					format modalite $50.;
					set sortie;
					variable = "&vari.";
					modalite = &vari.;
				run;

				%if %sysfunc(exist(&tabout.)) ne 1 %then %do;
					%put table &tabout. n existe pas;
					data &tabout.; 
						set sortie; 
					run;
				%end;
				%else %do;
					%put table existe;
					data &tabout.; 
						set &tabout. 
							sortie; 
					run;
				%end;

				proc delete data = sortie; run;

			%let i = %eval(&i. + 1);
		%end;
	%mend;
	%listing_modalites_variables(tabin   = apprentissage
								, tabout = liste_moda_var
								, list_var = &lst_var.);

	/* >>> Reconstitution de la grille au complet */
	proc sql;
		create table Estimators_grille_complete as 
		select a.variable
			, a.modalite
			, case when missing(estimate) then 0 else estimate end as estimate
			, case when missing(stderr) then 0 else stderr end as stderr
			, waldchisq
			, probchisq
		from liste_moda_var as a
		left join Estimators_grille_model  as b
			on upcase(a.variable)    = upcase(b.variable) 
			and compress(upcase(a.modalite))   = compress(upcase(b.ClassVal0))
	;quit;

/* -------------------------------------------------------------------- */
/* >>> Calcul de la note normée 										*/
/* -------------------------------------------------------------------- */

	proc sql noprint;

		create table Grille_minmax  as
		    select variable,min(estimate) as min, max(estimate) as max 
		from Estimators_grille_complete
		group by variable;

		create table delta_estimate as
		    select variable,min,(max-min) as deltamax 
		from Grille_minmax;

		select sum(deltamax) into: somme_deltamax 
		from delta_estimate;

		create table Grille_note_normee as
		    select a.variable,
		    a.modalite,
		    a.ProbChiSq, 
		    a.estimate,
		    round(1000*(a.estimate-b.min)/(&somme_deltamax.),0.01) as note_normee 
		from Estimators_grille_complete as a 
		left join delta_estimate 		as b 
		on a.variable=b.variable
		order by variable,modalite;

	quit;

	proc delete data= Grille_minmax 
					  delta_estimate
	; run;