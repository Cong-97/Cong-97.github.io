% This function is used to sample EV charging scenarios based on the
% analysis data. The generated EV data has a resolution of one hour, lasts
% for a year (8760 data points for each EV). The user will specify the
% number of EVs (NumEV) they want. By changing the random seed, different scenarios can be generated 

function EV_charging_scenarios = main_EV_scenario_generation_program(NumEV,RandomSeed)

    load("EV_analysis_data"); % load the analysis results
    rng(RandomSeed); % fix the random seed for reproducibility

    Num_of_Sys_Nodes = NumEV; % it is assumed that the number of nodes equals to number of EVs to be generated
    [sampledNodes,EV_Powers] = Nodes_And_Powers_Sampling_GM(Power_rates,Num_of_Sys_Nodes);
    % EV rates are based on our data, if users wish to use other rates,
    % please specify it for  "EV_Powers"

    Sampled_VL_EV_loads = zeros(NumEV,8760);
    Sampled_L_EV_loads = zeros(NumEV,8760);
    Sampled_M_EV_loads = zeros(NumEV,8760);
    Sampled_H_EV_loads = zeros(NumEV,8760);
    Sampled_VH_EV_loads = zeros(NumEV,8760); % initialize the load scenarios
    

    %% Then, we sample EV charging load for different categories
    for customer = 1:NumEV
        [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
            ChargingStartCounts_pdf(1,:), VL_num_Durations_pdf,Charging_frequencies(1)); 
        % charging load is a 1*8760 vector, following the time series of a year
        % charging scenarios is a 365*24 matrix, which indicates the daily load
        Sampled_VL_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    
        [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
            ChargingStartCounts_pdf(2,:), L_num_Durations_pdf,Charging_frequencies(2)); 
        % charging load is a 1*8760 vector, following the time series of a year
        % charging scenarios is a 365*24 matrix, which indicates the daily load
        Sampled_L_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    
        [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
            ChargingStartCounts_pdf(3,:), M_num_Durations_pdf,Charging_frequencies(3)); 
        % charging load is a 1*8760 vector, following the time series of a year
        % charging scenarios is a 365*24 matrix, which indicates the daily load
        Sampled_M_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    
        [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
            ChargingStartCounts_pdf(4,:), H_num_Durations_pdf,Charging_frequencies(4)); 
        % charging load is a 1*8760 vector, following the time series of a year
        % charging scenarios is a 365*24 matrix, which indicates the daily load
        Sampled_H_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data
    
        [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(EV_Powers(customer),...
            ChargingStartCounts_pdf(5,:), VH_num_Durations_pdf,Charging_frequencies(5)); 
        % charging load is a 1*8760 vector, following the time series of a year
        % charging scenarios is a 365*24 matrix, which indicates the daily load
        Sampled_VH_EV_loads(sampledNodes(customer),:) = chargingLoad; %record the sampled data


        %% obatining the yearly EV load scenario with different catagories
        penetration_level = NumEV; % set the EV penetration level
        EV_charging_scenarios = Sample_EV_load(Sampled_VL_EV_loads,Sampled_L_EV_loads,...
            Sampled_M_EV_loads,Sampled_H_EV_loads,Sampled_VH_EV_loads,penetration_level,sampledNodes); 
        % obtaining EV load and the total residential plus EV load under given EV
        % penetration levels
end