/* ******************************************************************** */
/* Courbe densité score	   				            					*/
/* ******************************************************************** */
/* Auteur : Sarah DAYMIER												*/  
/* Date : Sept 2020													    */                 
/* ******************************************************************** */
/* Objectif : Représenter graphiquement la densité des notes/proba 		*/
/* 	(en fonction du paramètre en entrée) en fonction du critère			*/
/* 	(cad l'évènement à prédire)											*/
/* Lecture : en abscisse : score/proba									*/
/* Interprétation : Si bonne séparation des deux courbes = score bien 	*/
/* 	discriminant car permet de différencier les deux populations		*/
/* ******************************************************************** */

/* -------------------------------------------------------------------- */
/* >>> Déclaration des macro variables 									*/
/* -------------------------------------------------------------------- */
%let base_apprentissage = mabase;
%let base_prediction 	= base_out_predict;
%let variable_cible 	= critere;

/* -------------------------------------------------------------------- */
/* Réapplication du modèle : 											*/
/* -------------------------------------------------------------------- */
/* Note : la base "monmodel" correspond a la sortie "outmodel" de la proc logistic */
/* Exemple :  proc logistic  data=apprentissage 						*/
/*                     		  outmodel=monmodel;						*/
/* -------------------------------------------------------------------- */
proc logistic inmodel=monmodel;
	score data=&base_apprentissage. out=&base_prediction. (rename = (P_1 = predicted));
run;

/*Densité*/
PROC SORT DATA = &base_prediction. ; BY &variable_cible.; RUN ;
PROC KDE DATA = &base_prediction. OUT = courbe ;
	VAR predicted ;
	BY &variable_cible. ;
RUN ;

PROC GPLOT DATA = courbe ;
	title 'Densité';
	PLOT density * predicted = &variable_cible. / LEGEND ;
	SYMBOL  V=NONE i = join;
RUN ; QUIT ;
