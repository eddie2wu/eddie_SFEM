# RA Task on SFEM

### Replicating tables for estimation of strategies used

This is table 17 - 19 in reports.pdf. There are 2x2x4 = 16 configurations:

{full_sample, perfect_quiz} X {6-strategies, 3-strategies} X {full, drop1quarter, first5, last5}

The instructions for reproducing the 16 configurations of the table are as follows:

1.  In `replicate_strat_used.R`, specify perfect_quiz to be TRUE or FALSE to indicate whether using people with perfect quiz or the full sample.

2.  Run `replicate_strat_used.R`.

3.  The tables are in the form of .tex files, saved in tex/. To understand file name, let's consider an example: `results_table7_S3_first5_perfect.tex` means we are using 3-strategies, for the first 5 supergames, with subjects with perfect quiz.



### Replicating tables of learning model parameter mean and median, CDF plots, and evolution graph

This is Figure 7 in reports.pdf, and Table A2.9 in Dal Bo Frechette (2011) appendix. There are 2x2 = 4 configurations:

{full_sample, perfect_quiz} x {autoplayer, no autoplayer}

The instructions for reproducing the 4 configurations of the tables and graphs are as follows:

Running order for replication Tables 17 - 19, Figure 7, Table A2.9, and CDF plots of Learning Model parameters:

1. In `replicate_longrun_graph.R`, specify perfect_quiz to be either TRUE or FALSE, and specify autoplayer to be either TRUE or FALSE. This determines whether using only people with perfect score on quiz, and whether using autoplayer as opponents in long run simulations.

2. Run `replicate_longrun_graph.R`.

3. The tables are in the form of .tex files, saved in tex/. To understand file name, let's consider an example: `summary_mean_belief_ap1_perfect.tex` means this table summarizes the mean belief variables, for autoplayer opponent, and subjects with perfect quiz.

4. The CDF plots are in the form of .pdf files, saved in figure/. To understand file name, let's consider an example: `cdf_ap1_full_treatment_4_beliefs.pdf` means this plots belief variables, for autoplayer opponent, using the full sample of subjects, for treatment 4.

5. The evolution plots are in the form of .png files, saved in figure/. To understand file name, let's consider an example: `learning_ap0_perfect.png` means NOT using autoplayer opponent, and for subjects with perfect quiz.


