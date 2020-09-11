%let pathtravaux =&racine.\WORK\&date_arr.;
option NOXWAIT XSYNC;
data _null_; 
X mkdir "&pathtravaux";*création du répertoire sous windows;
run;
libname travaux "&pathtravaux.";