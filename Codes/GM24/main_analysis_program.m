clear
clc
rng(7)
load("A_indexMatrix"); % Load the index matrix about the connectivity between DT and local loads.
load("DT_rating"); % Load the rated DT capacity.
load("DT_rating_Dyn"); % Load the dynamic DT capacity under different ambient temperatures over 2022.
load("A_indexMatrix"); % Load the index matrix about the connectivity between DT and local loads.
load("EV_analysis_data"); % load the analysis results
load("Residential_load");

Monthly_metered_days = [186,168,226,263,279,300,341,360,383,410,420,453]; % the number of days with EV metering data from all meters in each month
categorical_metered_days = [sum(Monthly_metered_days([1,2,12])),sum(Monthly_metered_days([3,11])),sum(Monthly_metered_days([4,10])),sum(Monthly_metered_days(5)),sum(Monthly_metered_days([6,7,8,9]))];

% calculate the total charging sessions
Sessions = sum(VL_num_Durations) + sum(L_num_Durations) + sum(M_num_Durations) + sum(H_num_Durations) + sum(VH_num_Durations);

% calculating the daytime CST probability for each category
Day_hour_start_prob = [sum(ChargingStartCounts_pdf(1,5:18)),sum(ChargingStartCounts_pdf(2,5:18)),sum(ChargingStartCounts_pdf(3,5:18)),...
    sum(ChargingStartCounts_pdf(4,5:18)),sum(ChargingStartCounts_pdf(5,5:18))];

% calculating the short CD probability for each category
short_duration = 2; % define the limit of short duration
Short_CD_prob = [sum(VL_num_Durations_pdf(1:short_duration)),sum(L_num_Durations_pdf(1:short_duration)),sum(M_num_Durations_pdf(1:short_duration))...
    sum(H_num_Durations_pdf(1:short_duration)),sum(VH_num_Durations_pdf(1:short_duration))];

% calculating the mean CD for each category
% Ignore very low-probable CDs larger than 450 mins, whose probability is
% Prob_CD_largerThan_450mins = [1-sum(VL_num_Durations_pdf(1:30)),1-sum(L_num_Durations_pdf(1:30)),...
%     1-sum(M_num_Durations_pdf(1:30)),1-sum(H_num_Durations_pdf(1:30)),1-sum(VH_num_Durations_pdf(1:30))];
Durations = [15:15:450]; % the charging duration scenarios
Ave_CD_VL = Durations*VL_num_Durations_pdf(1:30)'; % mean CD for VL category
Ave_CD_L = Durations*L_num_Durations_pdf(1:30)'; % mean CD for L category
Ave_CD_M = Durations*M_num_Durations_pdf(1:30)'; % mean CD for M category
Ave_CD_H = Durations*H_num_Durations_pdf(1:30)'; % mean CD for H category
Ave_CD_VH = Durations*VH_num_Durations_pdf(1:30)'; % mean CD for VH category
Ave_CDs = [Ave_CD_VL,Ave_CD_L,Ave_CD_M,Ave_CD_H,Ave_CD_VH]; % summarizing the CDs

% calculate the overall mean CD
weights_for_categories = [sum(VL_num_Durations),sum(L_num_Durations),sum(M_num_Durations)...
    sum(H_num_Durations),sum(VH_num_Durations)]/3560; % the weights for different categories based on the number of sessions
Ave_CD_overall = Ave_CD_VL*weights_for_categories(1) + Ave_CD_L*weights_for_categories(2) + ...
    Ave_CD_M*weights_for_categories(3) + Ave_CD_M*weights_for_categories(4) + Ave_CD_VH*weights_for_categories(5);

% the charging frequency and charging duration can be used to estimate
% charging demand by demand = frequency * duration
Estimated_charging_demand = Charging_frequencies(1:5) .* Ave_CDs;


%% sampling EV loads and apply to the distribution system
% Sample aggregated EV charging data for different temperature categories
% sample which node will have what EV charging demand at different EV
% penetration levels
Num_of_Sys_Nodes = 52; % There are 50 customers and 52 nodes, 2 extra nodes are wind nodes without EV load
[sampledNodes,EV_Powers] = Nodes_And_Powers_Sampling_GM(Power_rates,Num_of_Sys_Nodes);

Sampled_VL_EV_loads = zeros(Num_of_Sys_Nodes,8760);
Sampled_L_EV_loads = zeros(Num_of_Sys_Nodes,8760);
Sampled_M_EV_loads = zeros(Num_of_Sys_Nodes,8760);
Sampled_H_EV_loads = zeros(Num_of_Sys_Nodes,8760);
Sampled_VH_EV_loads = zeros(Num_of_Sys_Nodes,8760); % initialize the load scenarios

Sampled_VL_EV_scenarios = zeros(1,24);
Sampled_L_EV_scenarios = zeros(1,24);
Sampled_M_EV_scenarios = zeros(1,24);
Sampled_H_EV_scenarios = zeros(1,24);
Sampled_VH_EV_scenarios = zeros(1,24); % initialize the load scenarios

% Then, we sample EV charging load for 
for customer = 1:52
    [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
        ChargingStartCounts_pdf(1,:), VL_num_Durations_pdf,Charging_frequencies(1)); 
    % charging load is a 1*8760 vector, following the time series of a year
    % charging scenarios is a 365*24 matrix, which indicates the daily load
    Sampled_VL_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    Sampled_VL_EV_scenarios = [Sampled_VL_EV_scenarios;chargingScenarios]; % record the 364*24 scenarios

    [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
        ChargingStartCounts_pdf(2,:), L_num_Durations_pdf,Charging_frequencies(2)); 
    % charging load is a 1*8760 vector, following the time series of a year
    % charging scenarios is a 365*24 matrix, which indicates the daily load
    Sampled_L_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    Sampled_L_EV_scenarios = [Sampled_L_EV_scenarios;chargingScenarios]; % record the 364*24 scenarios

    [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
        ChargingStartCounts_pdf(3,:), M_num_Durations_pdf,Charging_frequencies(3)); 
    % charging load is a 1*8760 vector, following the time series of a year
    % charging scenarios is a 365*24 matrix, which indicates the daily load
    Sampled_M_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    Sampled_M_EV_scenarios = [Sampled_M_EV_scenarios;chargingScenarios]; % record the 364*24 scenarios

    [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
        ChargingStartCounts_pdf(4,:), H_num_Durations_pdf,Charging_frequencies(4)); 
    % charging load is a 1*8760 vector, following the time series of a year
    % charging scenarios is a 365*24 matrix, which indicates the daily load
    Sampled_H_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    Sampled_H_EV_scenarios = [Sampled_H_EV_scenarios;chargingScenarios]; % record the 364*24 scenarios

    [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
        ChargingStartCounts_pdf(5,:), VH_num_Durations_pdf,Charging_frequencies(5)); 
    % charging load is a 1*8760 vector, following the time series of a year
    % charging scenarios is a 365*24 matrix, which indicates the daily load
    Sampled_VH_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    Sampled_VH_EV_scenarios = [Sampled_VH_EV_scenarios;chargingScenarios]; % record the 364*24 scenarios
end

[sum(sum(Sampled_VL_EV_loads)),sum(sum(Sampled_L_EV_loads)),sum(sum(Sampled_M_EV_loads)),sum(sum(Sampled_H_EV_loads)),...
    sum(sum(Sampled_VH_EV_loads))];

% obtaining EV load and the total residential plus EV load under given EV
% penetration levels
penetration_level = 0:1:50; % set the EV penetration level
np = length(penetration_level);
DT_overloading = zeros(np,1); % Vector storing the number of overloading DT with rated capacity under different EV penetrations.
DT_overloading_Dyn = zeros(np,1); % Vector storing the number of overloading DT with dynamic capacity under different EV penetrations.
for i = 1:np
    Sampled_EV_load = Sample_EV_load(Sampled_VL_EV_loads,Sampled_L_EV_loads,...
    Sampled_M_EV_loads,Sampled_H_EV_loads,Sampled_VH_EV_loads,penetration_level(i),sampledNodes);
    Total_load = Sampled_EV_load + P;
    DT_loading = A_indexMatrix*Total_load;
    DT_overloading(i) = sum(sum(DT_loading > DT_rating));
    DT_overloading_Dyn(i) = sum(sum(DT_loading > DT_rating_Dyn));
end