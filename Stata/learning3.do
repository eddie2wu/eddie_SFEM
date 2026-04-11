* This file produces Figure 2 in the text and Figures A2.4 and A2.5 and Table A2.8 in the web appendix
clear


* cd /Users/eddiewu/Documents/Mon_travail/MY_PHD/kareen_geoffroy/eddie_SFEM/scripts
local project "/Users/eddiewu/Documents/Mon_travail/MY_PHD/kareen_geoffroy/eddie_SFEM"
local interm  "`project'/intermediate_output/learningmodel"
local data    "`project'/data"

cd "`interm'"

local infile "simulationresults_${autoplay_tag}_${sample}.txt"

di "Loading file: `infile'"

* Process simulation data
insheet treatment round G coope0 coope1 coope2 coope3 coope4 coope5 ///
coope6 coope7 coope8 coope9 coope10 coope11 coope12 coope13 coope14 foo ///
using "`infile'", tab



* insheet treatment round G coope0 coope1 coope2 coope3 coope4 coope5 coope6 coope7 coope8 coope9 coope10 coope11 coope12 coope13 coope14 foo using simulationresults_ap.txt, tab


gen lowlimit90 = 0 if coope0>49
replace lowlimit90 = 1/14 if coope0<50 & coope0+coope1>49
replace lowlimit90 = 2/14 if coope0+coope1<50 & coope0+coope1+coope2>49
replace lowlimit90 = 3/14 if coope0+coope1+coope2<50 & coope0+coope1+coope2+coope3>49
replace lowlimit90 = 4/14 if coope0+coope1+coope2+coope3<50 & coope0+coope1+coope2+coope3+coope4>49
replace lowlimit90 = 5/14 if coope0+coope1+coope2+coope3+coope4<50 & coope0+coope1+coope2+coope3+coope4+coope5>49
replace lowlimit90 = 6/14 if coope0+coope1+coope2+coope3+coope4+coope5<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6>49
replace lowlimit90 = 7/14 if coope0+coope1+coope2+coope3+coope4+coope5+coope6<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7>49
replace lowlimit90 = 8/14 if coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8>49
replace lowlimit90 = 9/14 if coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9>49
replace lowlimit90 = 10/14 if coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10>49
replace lowlimit90 = 11/14 if coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11>49
replace lowlimit90 = 12/14 if coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12>49
replace lowlimit90 = 13/14 if coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13>49
replace lowlimit90 = 14/14 if coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49

gen upplimit90 = 1 if coope14>49
replace upplimit90 = 13/14 if coope14<50 & coope13+coope14>49
replace upplimit90 = 12/14 if coope13+coope14<50 & coope12+coope13+coope14>49
replace upplimit90 = 11/14 if coope12+coope13+coope14<50 & coope11+coope12+coope13+coope14>49
replace upplimit90 = 10/14 if coope11+coope12+coope13+coope14<50 & coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 9/14 if coope10+coope11+coope12+coope13+coope14<50 & coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 8/14 if coope9+coope10+coope11+coope12+coope13+coope14<50 & coope8+coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 7/14 if coope8+coope9+coope10+coope11+coope12+coope13+coope14<50 & coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 6/14 if coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14<50 & coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 5/14 if coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14<50 & coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 4/14 if coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14<50 & coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 3/14 if coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14<50 & coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 2/14 if coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14<50 & coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 1/14 if coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14<50 & coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49
replace upplimit90 = 0 if coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14<50 & coope0+coope1+coope2+coope3+coope4+coope5+coope6+coope7+coope8+coope9+coope10+coope11+coope12+coope13+coope14>49

sort treatment round
save simulationresults, replace


*Simulation results
use "`data'/modified_data.dta", clear
keep if stage==1
collapse coop, by (treatment round)
sort treatment round
merge treatment round using simulationresults


* Plot graph
twoway (line coop round if treatment==1 & round<=60, title(delta=low r=normal) subtitle(GT) legend(off) graphregion(color(white)) xtitle("Repeated Game (log scale)") ytitle("Cooperation") yscale(range(0 1)) ylabel(#11) xscale(log) xlabel(1 5 10 20 40 100 300 1000)) (line g round if treatment==1, lpattern(dash)) (line lowlimit90 round if treatment==1,  lpattern(dot) lcolor(cranberry)) (line upplimit90 round if treatment==1, lpattern(dot) lcolor(cranberry)), saving("`project'/figure/graphd5r32gt",replace)
twoway (line coop round if treatment==2 & round<=30, title(delta=high r=normal) subtitle(GT) legend(off) graphregion(color(white)) xtitle("Repeated Game (log scale)") ytitle("Cooperation") yscale(range(0 1)) ylabel(#11) xscale(log) xlabel(1 5 10 20 40 100 300 1000)) (line g round if treatment==2, lpattern(dash)) (line lowlimit90 round if treatment==2,  lpattern(dot) lcolor(cranberry)) (line upplimit90 round if treatment==2, lpattern(dot) lcolor(cranberry)), saving("`project'/figure/graphd75r32gt",replace)
twoway (line coop round if treatment==3 & round<=60, title(delta=low r=normal) subtitle(MIX) legend(off) graphregion(color(white)) xtitle("Repeated Game (log scale)") ytitle("Cooperation") yscale(range(0 1)) ylabel(#11) xscale(log) xlabel(1 5 10 20 40 100 300 1000)) (line g round if treatment==3, lpattern(dash)) (line lowlimit90 round if treatment==3,  lpattern(dot) lcolor(cranberry)) (line upplimit90 round if treatment==3, lpattern(dot) lcolor(cranberry)), saving("`project'/figure/graphd5r32xy",replace)
twoway (line coop round if treatment==4 & round<=30, title(delta=high r=normal) subtitle("MIX, no knowledge") legend(off) graphregion(color(white)) xtitle("Repeated Game (log scale)") ytitle("Cooperation") yscale(range(0 1)) ylabel(#11) xscale(log) xlabel(1 5 10 20 40 100 300 1000)) (line g round if treatment==4, lpattern(dash)) (line lowlimit90 round if treatment==4,  lpattern(dot) lcolor(cranberry)) (line upplimit90 round if treatment==4, lpattern(dot) lcolor(cranberry)), saving("`project'/figure/graphd75r32xy",replace)
twoway (line coop round if treatment==5 & round<=30, title(delta=high r=normal) subtitle("MIX, no knowledge nor observer") legend(off) graphregion(color(white)) xtitle("Repeated Game (log scale)") ytitle("Cooperation") yscale(range(0 1)) ylabel(#11) xscale(log) xlabel(1 5 10 20 40 100 300 1000)) (line g round if treatment==5, lpattern(dash)) (line lowlimit90 round if treatment==5,  lpattern(dot) lcolor(cranberry)) (line upplimit90 round if treatment==5, lpattern(dot) lcolor(cranberry)), saving("`project'/figure/graphd75r32xx",replace)
twoway (line coop round if treatment==6 & round<=30, title(delta=high r=normal) subtitle(MIX) legend(off) graphregion(color(white)) xtitle("Repeated Game (log scale)") ytitle("Cooperation") yscale(range(0 1)) ylabel(#11) xscale(log) xlabel(1 5 10 20 40 100 300 1000)) (line g round if treatment==6, lpattern(dash)) (line lowlimit90 round if treatment==6,  lpattern(dot) lcolor(cranberry)) (line upplimit90 round if treatment==6, lpattern(dot) lcolor(cranberry)), saving("`project'/figure/graphd75r32yy",replace)
twoway (line coop round if treatment==7 & round<=30, title(delta=high r=high) subtitle(MIX) legend(off) graphregion(color(white)) xtitle("Repeated Game (log scale)") ytitle("Cooperation") yscale(range(0 1)) ylabel(#11) xscale(log) xlabel(1 5 10 20 40 100 300 1000)) (line g round if treatment==7, lpattern(dash)) (line lowlimit90 round if treatment==7,  lpattern(dot) lcolor(cranberry)) (line upplimit90 round if treatment==7, lpattern(dot) lcolor(cranberry)), saving("`project'/figure/graphd75r48yy",replace)
twoway (line coop round if treatment==8 & round<=30, title(delta=high r=high) subtitle("MIX, no knowledge") legend(off) graphregion(color(white)) xtitle("Repeated Game (log scale)") ytitle("Cooperation") yscale(range(0 1)) ylabel(#11) xscale(log) xlabel(1 5 10 20 40 100 300 1000)) (line g round if treatment==8, lpattern(dash)) (line lowlimit90 round if treatment==8,  lpattern(dot) lcolor(cranberry)) (line upplimit90 round if treatment==8, lpattern(dot) lcolor(cranberry)), saving("`project'/figure/graphd75r48xy",replace)

graph combine ///
"`project'/figure/graphd5r32gt.gph" ///
"`project'/figure/graphd75r32gt.gph" ///
"`project'/figure/graphd5r32xy.gph" ///
"`project'/figure/graphd75r32xy.gph" ///
"`project'/figure/graphd75r32xx.gph" ///
"`project'/figure/graphd75r32yy.gph" ///
"`project'/figure/graphd75r48yy.gph" ///
"`project'/figure/graphd75r48xy.gph", ///
cols(4) xsize(16) ysize(8) graphregion(color(white)) ///
saving("`project'/figure/learning_${autoplay_tag}_${sample}", replace)

graph export "`project'/figure/learning_${autoplay_tag}_${sample}.png", replace


