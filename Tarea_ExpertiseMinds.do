
clear all


cd "C:\Users\alcan\Desktop\Tarea_ExpertiseMinds"

global mio "C:\Users\alcan\Desktop\Tarea_ExpertiseMinds"



*###############################################################################
************** CONSTRUCCION DE LAS BASES DE DATOS ******************************
*###############################################################################



forvalues i=2017/2019 { 

	


	**************************************************
	**************** Modulo 300 **********************
	**************************************************

	use "enaho01a-`i'-300.dta",clear 
	
   * Generamos la variable residente habitual
	gen resi=1 if ((p204==1 & p205==2) | (p204==2 & p206==1))
	keep if resi==1 


	* Renombramos la variable sexo
	gen sexo=1 if p207==2
	replace sexo=0 if sexo==.

	label define sexo 0 "Hombre" 1 "Mujer"
	label value sexo sexo

	keep if sexo==1

	* Generamos la variable area, la cual tendra
	*las categorias urbano/rural

	gen area=0 if estrato<=5 

	replace area=1 if estrato>=6 & estrato<=8
	label define area 0 "Urbano" 1 "Rural"
	label value area area

	keep if area==1

	* Generamos la variable jefe/a del hogar

	gen Jefa=1 if p203==1
	replace Jefa=0 if Jefa==.

	label define Jefa 0 "No es Jefa" 1 "Es Jefa"
	label value Jefa Jefa

	* Generamos el estado Civil 
	gen EC=1 if p209==6
	replace EC=0 if EC==. 
	label define EC 0 "No Soltera" 1 "Soltera"
	label value EC EC 

	* Generamos la variable tenencia de teléfono móvil propio
	gen UCPR=1 if p316a1==1
	replace UCPR=0 if UCPR==.


	* Generamos la variable tenencia de teléfono móvil de un familiar
	gen UCFM=1 if p316a2==2
	replace UCFM=0 if UCFM==.

	* Generamos la variable tenencia de teléfono móvil de centro laboral
	gen UCLB=1 if p316a3==3
	replace UCLB=0 if UCLB==.



	**************************************
	* Estimación de los años de educación
	**************************************

	//Años de educación estimados
		

	egen tmp_years = rowmax(p301b p301c)
	gen S = .

	* Primaria
	replace S = 1+tmp_years if p301a==3 & tmp_years<6
	replace S = 1+6 if (p301a==3 & tmp_years>=6) | p301a==4

	* Secundaria
	replace S = 1+6+tmp_years if p301a==5 & tmp_years<=5
	replace S = 1+11 if (p301a==5 & tmp_years>=5) | p301a==6

	* Superior universitaria
	replace S = 1+11+tmp_years if p301a==7 & tmp_years!=.

	* Postgrado (Maximo 3 años adicionales, eso hace hasta 19 años en total)
	replace S = 16+tmp_years if p301a==8 & inrange(tmp_years,1,3)

	drop if S==.
		
	* Nos quedamos solo con las variables que necesitamos 
	keep conglome vivienda hogar codperso Jefa EC UCPR UCFM UCLB S 

	* Guardamos la base trabajada 
	save "$mio\base300.dta",replace



	**************************************************
	**************** Modulo 500 **********************
	**************************************************

	use "enaho01a-`i'-500.dta",clear 

	/*

	Generamos la variable participacion en el 
	mercado laboral, para lo cual asumiremos
	que hace referencia a la PEA Ocupada

	*/

	gen Part=1 if (ocu500==1 | ocu500==2)
	replace Part=0 if Part==.


	
	
	* Segun las estadisticas descriptivas presentadas
	* en el documento, se intuye que la experiencia laboral
	* hace referencia al tiempo en su ocupacion principal

	* Experiencia en años = años + meses/12
	gen Exp = .
	replace Exp = p513a1 + p513a2/12 if p513a1!=. & p513a2!=.
	replace Exp = p513a1             if p513a1!=. & p513a2==.
	replace Exp = p513a2/12          if p513a1==. & p513a2!=.

	* cuadrado de experiencia
	gen Exp2 = Exp^2 if Exp!=.
	
	
	* Generamos el ingreso
	gen W = .
	replace W = p524a1*30 if p523==1 & p524a1!=.
	replace W = p524a1*4  if p523==2 & p524a1!=.
	replace W = p524a1*2  if p523==3 & p524a1!=.
	replace W = p524a1    if p523==4 & p524a1!=.

	* según el paper, quienes no tienen ingresos se cuentan como 0
	replace W = 0 if W==.
	
	
	* Nos quedamos solo con las variables que necesitamos 
	keep conglome vivienda hogar codperso Part W Exp Exp2

	* Guardamos la base trabajada 
	save "$mio\base500.dta",replace


	***********************************************
	* Unimos las bases a utilizar
	***********************************************

	use "$mio\base300.dta",clear

	merge 1:1 conglome vivienda hogar codperso using "$mio\base500.dta"
	keep if _merge==3

	drop _merge conglome vivienda hogar codperso 

    gen year=`i'
	
	********************
	* Sacamos la muestra
	*********************
	
		if `i'==2017 {
			sample 1436,count
		}
		
		else if `i'==2018 {
			sample 1568,count
		}
		
		else if `i'==2019 {
			sample 1523,count
		}
	
	
	save "$mio\base`i'.dta",replace
	
}


use "base2017.dta",clear

append using "base2018.dta" "base2019.dta"

save "base_total.dta",replace 

*###############################################################################


*###############################################################################
******************* ESTADISTICOS DESCRIPTIVOS **********************************
*###############################################################################

forvalues i=2017/2019{

preserve 

keep if year==`i'

gen W_pos = W if W>0
sum W_pos
gen lnW = ln(W_pos)
sum lnW
scalar W_`i'_MEAN= exp(r(mean))



gen lnS = ln(S) if S>0
sum lnS
scalar S_`i'_MEAN=exp(r(mean))



gen Exp_pos = Exp if Exp>0
gen lnExp = ln(Exp_pos)
sum lnExp 
scalar Exp_`i'_MEAN=exp(r(mean)) 


sum W
scalar W_N_`i'=_N
scalar W_SD_`i'=r(sd)
scalar W_MIN_`i'=r(min)
scalar W_MAX_`i'=r(max)

sum S 
scalar S_N_`i'=_N
scalar S_SD_`i'=r(sd)
scalar S_MIN_`i'=r(min)
scalar S_MAX_`i'=r(max)

sum Exp 
scalar Exp_N_`i'=_N
scalar Exp_SD_`i'=r(sd)
scalar Exp_MIN_`i'=r(min)
scalar Exp_MAX_`i'=r(max)


restore 
}


******************************
* Estadisticos Descriptivos 
******************************

***********
* AN0 2017 
***********
display  W_N_2017 "   " W_2017_MEAN "   " W_SD_2017  "   " W_MIN_2017 "   " W_MAX_2017  
display  S_N_2017 "   " S_2017_MEAN "   " S_SD_2017  "   " S_MIN_2017 "   " S_MAX_2017  
display  Exp_N_2017 "   " Exp_2017_MEAN "   " Exp_SD_2017  "   " Exp_MIN_2017 "   " Exp_MAX_2017  


tab Part if year==2017
tab EC if year==2017
tab UCPR if year==2017
tab UCFM if year==2017
tab UCLB if year==2017
tab Jefa if year==2017


***********
* AN0 2018 
***********
display  W_N_2018 "   " W_2018_MEAN "   " W_SD_2018  "   " W_MIN_2018 "   " W_MAX_2018  
display  S_N_2018 "   " S_2018_MEAN "   " S_SD_2018  "   " S_MIN_2018 "   " S_MAX_2018  
display  Exp_N_2018 "   " Exp_2018_MEAN "   " Exp_SD_2018  "   " Exp_MIN_2018 "   " Exp_MAX_2018  


tab Part if year==2018
tab EC if year==2018
tab UCPR if year==2018
tab UCFM if year==2018
tab UCLB if year==2018
tab Jefa if year==2018



***********
* AN0 2019
***********
display  W_N_2019 "   " W_2019_MEAN "   " W_SD_2019  "   " W_MIN_2019 "   " W_MAX_2019  
display  S_N_2019 "   " S_2019_MEAN "   " S_SD_2019  "   " S_MIN_2019 "   " S_MAX_2019  
display  Exp_N_2019 "   " Exp_2019_MEAN "   " Exp_SD_2019  "   " Exp_MIN_2019 "   " Exp_MAX_2019 


tab Part if year==2019
tab EC if year==2019
tab UCPR if year==2019
tab UCFM if year==2019
tab UCLB if year==2019
tab Jefa if year==2019




*###############################################################################
************************* REGRESIONES ******************************************
*###############################################################################


forvalues i=2017/2019 {

	preserve 

	keep if year==`i'

	* Generemao el logaritmo de W
	gen W_pos = W if W>0
	gen lnW = ln(W_pos)

  
   *****************************************************************************
   
	* Modelo Probit 
	probit Part S Exp Exp2 Jefa, robust

	*Modelo de Mincer 
	heckman lnW S Exp Exp2 EC UCPR UCFM UCLB, select(Part = S Exp Exp2 Jefa) twostep
	
    *****************************************************************************
	
restore 

}


    
	