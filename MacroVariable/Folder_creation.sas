%let pathtravaux =&racine.\WORK\&date_arr.;
option NOXWAIT XSYNC;
data _null_; 
X mkdir "&pathtravaux";*cr�ation du r�pertoire sous windows;
run;
libname travaux "&pathtravaux.";