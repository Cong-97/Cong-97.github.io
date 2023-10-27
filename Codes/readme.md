% This is the readme note for using the provided code to reproduce our results. by running the "main_analysis_program" and 
% "DTCapacityFitting", all the results shown in the paper can be obtained.
 

% To allow researchers generate more electric vehicle (EV) charging scenarios for their own research, we also proveide 
% an EV charging scenario generation program "main_EV_scenario_generation_program(NumEV,RandomSeed)".This program will 
% ask users to input two values 1. NumEV: the number of EVs to generate charging scenarios 2.RandomSeed: the random seed
% to fix the generation results for generating reproducible results. Notably, users can also change the "EV_Powers" 
% (at line 12) based on their own need. The default values for "EV_Powers" come from our data.


%% programs and functions
1. "main_analysis_program"
This program operates all the analysis and produces all the results used in our paper.

2. "main_EV_scenario_generation_program(NumEV,RandomSeed)"
This function is used to generate new EV charging scenarios. Users need to specify the number of EVs they want to simulate,
and the random seed can be changed to obtain different scenarios. Besides, users can specify their own EV power rates in 
line 12 based on their own needs.

3. "Nodes_And_Powers_Sampling_GM(Power_rates,totalNodes)"
This function samples power rates for different EVs at different nodes, users need to input the power rates and number of 
nodes (default as the number of EVs) they want to simulate

4. "Sampling_EV_charging_Event_Temperature_categorized_GM(ChargingPower,chargingCounts_pdf, num_Durations_pdf,Charging_frequency)"
This function samples EV charging scenarios under different temperature conditions based on the EV charging demand analysis results.

5. "Sample_EV_load"
This function samples EV charging scenarios under different EV penetrations.

6. "DTCapacityFitting"
This program gives the fitted curve presenting the relationship between the DT capacity and the ambient temperature with 
the polynomial function.


%% recorded data
7. "A_indexMatrix"
This is the data storing the connectivity relationship between DT and local loads.

8. "DT_rating"
This is the data storing the rated DT capacity.

9. "DT_rating_Dyn"
This is the data storing the dynamic DT capacity under different ambient temperatures over 2022.

10. "EV_analysis_data"
This is the data recording EV charging demand analysis results under different temperature categories. The analysis results 
include a. charging frequency b. charging start time probability distribution c. charging duration probability distribution

11. "Residential_load"
This is the residential load data we used for the paper

12. "TAmes2022"
This is the data storing the daily average temperature of Ames over 2022.
