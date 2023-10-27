function [chargingLoad, chargingScenarios] = Sampling_EV_charging_Event_Temperature_categorized_GM(ChargingPower,chargingCounts_pdf, num_Durations_pdf,Charging_frequency)
    
    

    % Number of days in a year
    numDays= 365;
    
    % Number of hours in a day
    numHoursPerDay = 24;
    
    % Initialize the matrix to store charging behavior
    chargingScenarios = zeros(numDays, numHoursPerDay);
    
    for day = 1:numDays
        
        % Sample whether the EV will be charged on this day
        if rand() <= Charging_frequency
            % Sample charging start time based on probability distribution
            chargingStartHour = find(rand() <= cumsum(chargingCounts_pdf), 1);
            
            % Sample charging duration based on probability distribution
            chargingDuration = ceil(find(rand() <= cumsum(num_Durations_pdf), 1)/4); 
            % divided by 4 to transform 15-min into hours and round it
            % using the ceiling value
            
            % Check if the charging behavior crosses to the next day
            if chargingStartHour + chargingDuration - 1 > numHoursPerDay
                % Adjust the charging duration
                chargingDuration = numHoursPerDay - chargingStartHour + 1;
                if day<365
                    chargingScenarios(day+1, 1:chargingStartHour+chargingDuration-numHoursPerDay) = ChargingPower;
                end
            end
            
            % Set the charging behavior in the matrix
            chargingScenarios(day, chargingStartHour:chargingStartHour+chargingDuration-1) = ChargingPower;
            
        end
    end
    chargingLoad = reshape(chargingScenarios', 1, []);
end
