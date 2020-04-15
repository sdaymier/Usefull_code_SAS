/****************************************************************************************/
/* PROGRAM:       better_means                                                          */
/* AUTHORS:       Myra A. Oltsik and Peter Crawford                                     */
/* ORIGINAL DATE: 12/20/05                                                              */
/* PURPOSE:       Create a dataset with PROC MEANS statistics, with each record being   */
/*                one variable. Print stats if needed, too. Fixes ODS problems.         */
/*                                                                                      */
/* NOTE:          This macro has special handling for N, SUMWGT, KURT and SKEW.         */
/*                Also:   STDEV, Q1, MEDIAN, Q3 are referred as STD, P25, P50, P75.     */
/****************************************************************************************/
/****************************************************************************************/
/* MACRO PARAMETERS:                                                                    */
/*    required:  none                                                                   */
/*    optional:  print   -- whether or not to print results to output                   */
/*               data    -- dataset name to be analysed                                 */
/*               sort    -- sort order choice of the file of MEANS, by VARNUM or NAME   */
/*               stts    -- indicate which statistics should included in the output     */
/*               varlst  -- list of variables for means if not all numeric vars in file */
/*               clss    -- variable(s) for a class statement                           */
/*               wghts   -- variable for a weight statement                             */
/*    defaults:                                                                         */
/*               data    -- &syslast  (most recently created data set)                  */
/*               print   -- Y                                                           */
/*               sort    -- VARNUM                                                      */
/*               stts    -- _ALL_                                                       */
/*               varlst  -- _ALL_                                                       */
/*                                                                                      */
/* Created Macro Variables:                                                             */
/*               locals  --  see inline comments at %local statement                    */
/* Creates Data Sets                                                                    */
/*               results are written to &data._means                                    */
/*               many data sets are created in the work library  all prefixed _better_  */
/*               but unless the testing option is set, the work data stes are deleted   */
/*                                                                                      */
/* SAMPLES:                                                                             */
/*   %better_means(data=test); print all default statistics in a dataset                */
/*   %better_means(data=sashelp.class,stts=MEAN SUM); print only MEAN and SUM stats     */
/*   %better_means(data=sashelp.gnp,print=N,sort=NAME,stts=MIN MAX,varlst=INVEST        */
/*      EXPORTS); suppress list printing, limit output statistics and variables, and    */
/*      sort on NAME                                                                    */
/*   %better_means(data=sasuser.shoes,clss=PRODUCT); run all stats by PRODUCT field     */
/*   %better_means(data=sasuser.weighted,wghts=WGT); run all stats weighted on WGT      */
/****************************************************************************************/
%macro   better_means(data   = &syslast. 
					,print  = Y
					,sort   = VARNUM
					,stts   = _ALL_
					,varlst = _ALL_
					,clss   =  
					,wghts  =  
					,testing= no        
					/* any other value will preserve the _better_: data sets */
					/****************************************************************************************/
					/* PROVIDE THE COMPLETE PROC MEANS STATISTIC LIST (FROM ONLINE-DOC) IF NONE STATED.     */
					/****************************************************************************************/
					,_stts  = N MEAN STD MIN MAX CSS CV LCLM NMISS                
							 P1 P5 P10 P25 P50 P75 P90 P95 P99 QRANGE RANGE                
							 PROBT STDERR SUM SUMWGT KURT SKEW T UCLM USS VAR      
					);    
%local vLexist  /* EXISTENCE OF LABELS ON INPUT DATASET          */      
		s  		/* POINTER TO STATISTIC IN THE STATISTICS LIST   */     
		stato  /* HOLDER OF AN INDIVIDUAL STATISTIC NAME :
					- USED IN STATISTIC TABLE NAME, AND 
					  USED IN THE IN= VARIABLE DATASET OPTION */      
		full /* INDICATOR IN OUTPUT LABEL WHEN ALL STATS USED.*/   ; 
/****************************************************************************************/
/* PUT STATS AND VAR PARAMETER LIST INTO UPPER CASE.                                    */
/****************************************************************************************/
%let varlst = %upcase(&varlst);    
%let stts   = %upcase(&stts);    
%put >>>>>>>>>>>> &data.;
%let data   = &data ;
%put >>>>>>>>>>>> &data.;

/****************************************************************************************/
/* GET THE NAMES/NUMBERS OF ALL VARIABLES INTO A LOOKUP FORMAT IF SORT ORDER = VARNUM.  */
/****************************************************************************************/
%if &sort. eq VARNUM %then %do;       

    proc contents data = &data. out = _better_cols noprint;       
	run;
	data _better_cntl;     
		retain FMTNAME '_bm_VN' 
				TYPE 'I' 
				HLO 'U' 
			;          
		set _better_cols ( keep= NAME VARNUM  rename=( VARNUM=LABEL ));    
		START = upcase( NAME) ;      
	run; 

	proc format cntlin= _better_cntl;       
	run;    

%end;



/****************************************************************************************/
/* PROCESS STATISTICS CONDITIONS / COMBINATIONS                                         */
/****************************************************************************************/
%if &stts = _ALL_ or %length(&stts) = 0 %then %do; 
	%let stts = &_stts. ;
	%let full = FULL STATS;   
%end;    
%if  %length(&wghts.) %then %do;     
	%* remove KURT and Skew  when weights are present;
	%let stts = %sysfunc( tranwrd( &stts., KURT, %str( ) ));
	%let stts = %sysfunc( tranwrd( &stts., SKEW, %str( ) )); 
	%let full = STATS ;    
%end;   
%else %do;     
	%* remove SUMWGT  when no weights present ;
	%let stts = %sysfunc( tranwrd( &stts, SUMWGT, %str( ) )); 
	%let full = STATS ;   
%end; 
/****************************************************************************************/
/* RUN PROC MEANS ON VARIABLES WITH OUTPUT FILE FOR EACH STATISTIC REQUESTED. MERGE     */
/* DATASET OF LIST OF NUMERIC VARIABLES AND THEIR VARNUM.                               */
/****************************************************************************************/
proc means data= &data noprint missing; 
	%if &varlst ne _ALL_ & %length(&varlst) %then %do;
		var   &varlst; 
	%end; 
	%if %length(&clss) %then %do;          
		class &clss; 
	%end; 
	%if %length(&wghts) %then %do;          
		weight &wghts; 
	%end; 
	%let s     =               1  ;
	%let stato = %scan( &stts, 1 ); 
	%do %while( %length(&stato) > 0 );       
		/* USING %LENGTH() FOR &STATO WORDS SIGNIFICANT TO %IF/%WHILE */         
		output out= _better_&stato &stato= ;
		%let s     = %eval(        &s +1 ); 
		%let stato = %scan( &stts, &s    );
	%end;
run;  

data _better_means1;  
	length _BETTER_ $32./* STATS IDENTITY */      ;     
	set  /* ALL THOSE OUTPUT DATASETS FROM PROC MEANS */
	%let stato = %scan( &stts, 1 ); 
		%let s =  1 ;
			%do %while(    %length(&stato) gt  0 );      
				_better_&stato( in= _in_&stato )        
				/* NEED IN= VARIABLE TO IDENTIFY INPUT DATA */
				%let s     = %eval(        &s +1 );
				%let stato = %scan( &stts, &s    ); 
			%end; ;   
	by _TYPE_ &clss;
	%let    stato = %scan( &stts, 1 );  
	/* GENERATE _BETTER_ TO IDENTIFY EACH ROW OF RESULTS */
	%let s = 1  ;
	%do %while( %length(&stato) > 0 );    
		if _in_&stato then _BETTER_ = "%upcase( &stato )" ; 
		else 
		%let s     = %eval(        &s +1 ); 
		%let stato = %scan( &stts, &s    );
	%end;;    
run;   

proc transpose data=_better_means1  
				out=_better_means2;      
	by _TYPE_ &clss ;      
	id _BETTER_ ;   
run; 

/****************************************************************************************//* FROM SAS FAQ # 1806: MACRO TO CHECK IF THE VARIABLE EXISTS IN A DATASET.             *//****************************************************************************************/
/*%macro varcheck(varname,dsname); 
	%local dsid vindex rc; 
	%let dsid = %sysfunc(open(&dsname,is)); 
	%if &dsid EQ 0 %then %do; 
		%put ERROR: (varcheck) The data set "&dsname" could not be found; 
	%end; 
	%else %do;
		%let vindex = %sysfunc(varnum(&dsid,&varname));
	%end; 
	%let rc = %sysfunc(close(&dsid));     
	&vindex.   
%mend varcheck;  

%let vLexist = %varcheck(_LABEL_,_better_means2); 
*/
/****************************************************************************************/
/* CREATE BASIS FOR OUTPUT DATASET BASED ON DIFFERENT CONDITIONS AND PARAMETER CHOICES. */
/****************************************************************************************/

%macro inL( list, seek ) / des= "Return TRUE, if &seek in &list, blank delimited"; 
	%sysfunc( indexw( &list, &seek ))     
%mend inL ; 


%macro now( fmt= datetime21.2 ) / des= "Timestamp";
	%sysfunc( datetime(), &fmt ) 
%mend  now; 

%let vLexist = 0;
data _better_means_out;
	length _TYPE_ 3. ; 
	retain/* TO FIX ORDER OF THE FIRST FEW */ &clss 
		%if &sort eq VARNUM %then %do;            
			VARNUM 
		%end;        
		NAME 
		/* ADD IF TRANSPOSED DATASET CONTAINS THE LABEL VARIABLE */    
		/*%if &vLexist ne 0 %then %do;       
  			LABEL 
		%end; */
		/* ADD % NOT MISSING IF STATISTIC "N" REQUESTED */    
		%if %inL(&stts.,N) %then %do;           
    		N             
			PCT_POP             
			PCT_DEN 
		%end;  
	; 

	set _better_means2 (rename=(_NAME_  = NAME 
								%if &vLexist ne 0 %then %do; 
									_LABEL_ = LABEL 
								%end;       
						));
	%if %inL(&stts,N) %then %do;
		format PCT_POP percent.4 ;
		if NAME = "_FREQ_" then do;    
			PCT_DEN = N ; 
			delete;
		end; 
		else do; 
			if PCT_DEN then PCT_POP = N / pct_den ; 
		end; 
		drop  PCT_DEN ; 
	%end; 
	%else %do; 
		if NAME = "_FREQ_" then delete; 
	%end; 
	%if &sort eq VARNUM %then %do;  
		VARNUM = input(NAME,_bm_VN.); 
	%end; 
	NAMEU = upcase(NAME) ;
run; 

/****************************************************************************************/
/* CREATE FINAL DATASET WITH ALL STATISTICS, SORTED AS REQUESTED ON INVOCATION.         */
/****************************************************************************************/
proc sort data = _better_means_out 
			out= &data._means (label= "&FULL FOR &data %NOW" 
							    drop= NAMEU %if %length(&clss) = 0 %then %do;
											_TYPE_ 
											%end; ); 
by _TYPE_ &clss &sort; 
run; 

/****************************************************************************************/
/* IF PRINTED OUTPUT IS REQUESTED, DO SO HERE.                                          */
/****************************************************************************************/
%if &print. = Y %then %do;  
	proc print data=&data._means; 
	title3 "MEANS FOR &data"; 
	%if %length(&clss) > 0 %then %do;
		by _TYPE_;
	%end;
	run;   
%end;  

/****************************************************************************************/
/* CLEAN UP REMAINING TEMPORARY DATASETS.                                               */
/****************************************************************************************/
%if &testing = no  %then %do; 
	proc datasets lib= work nolist; 
		delete _better_:; 
	run; quit;
%end; 

%mend better_means;

/****************************************************************************************/
/* Exemple de lancement :                                                               */
/****************************************************************************************/
data Cars; set Sashelp.Cars; run;

%better_means(data=Cars
			,stts=n min max mean
			,varlst=Weight Length
			,clss=make type); 

