function [Sampled_EV_load] = Sample_EV_load(Sampled_VL_EV_loads,Sampled_L_EV_loads,...
    Sampled_M_EV_loads,Sampled_H_EV_loads,Sampled_VH_EV_loads,penetration_level,sampledNodes)
    % the input of this function include EV load sampled from each category, residential load, EV penetration, and node sampling 
    % output of this function include the EV load under current EV
    % peneration level, and total residential plus EV load

    Very_Low = [1,2,12];
    Low = [3,11];
    Medium = [4,10];
    High = [5];
    Very_High = [6,7,8,9]; % month categories

   
    Month_day_index = zeros(12,365); % used to indicate which days are in which month

    % start input which days are in which month
    Month_days = [0,31,28,31,30,31,30,31,31,30,31,30,31]; % how many days in each month

    for month = 1:12
        Month_day_index(month,sum(Month_days(1:month))+1:sum(Month_days(1:month+1))) = 1; % put the days as 1 for that month
    end

    Month_hour_index = zeros(12,8760); % used to indicate which hours are in which month

    for month = 1:12
        for day = 1:365
            if Month_day_index(month,day) == 1
                Month_hour_index(month,(day-1)*24+1:day*24) = 1; % if that hour is in that month, set index to 1
            end
        end
    end

    Sampled_EV_load = zeros(length(sampledNodes),8760); % initialize EV load
    
    % then, start puting values to EV_load
    for month = 1:12
         if find(Very_Low==month) >= 1 % if it's a very cold month
            for hr = find(Month_hour_index(month,:)==1)
                Sampled_EV_load(:,hr) = Sampled_VL_EV_loads(:,hr);
            end
         end

         if find(Low==month) >= 1 % if it's a cold month
            for hr = find(Month_hour_index(month,:)==1)
               
                Sampled_EV_load(:,hr) = Sampled_L_EV_loads(:,hr);
            end
         end

         if find(Medium==month) >= 1 % if it's a mild month
            for hr = find(Month_hour_index(month,:)==1)
                Sampled_EV_load(:,hr) = Sampled_M_EV_loads(:,hr);
            end
         end

         if find(High==month) >= 1 % if it's a hot month
            for hr = find(Month_hour_index(month,:)==1)
                Sampled_EV_load(:,hr) = Sampled_H_EV_loads(:,hr);
            end
         end

         if find(Very_High==month) >= 1 % if it's a very hot month
            for hr = find(Month_hour_index(month,:)==1)
                Sampled_EV_load(:,hr) = Sampled_VH_EV_loads(:,hr);
            end
         end
    end
    
    % Then, we remove the load that are not under this EV penetration level
    
    Existing_EV_index = zeros(1,length(sampledNodes)); % initialize the index for if an EV exisit at each node
    Existing_EV = sampledNodes(1:penetration_level); % nodes with EVs at this penetration level
    Existing_EV_index(Existing_EV) = 1; % set index to 1 if there is an EV

    for customer = 1:length(sampledNodes)
        if Existing_EV_index(customer) == 0 % if there is no EV at this customer for this penetration level
            Sampled_EV_load(customer,:) = 0; % remvoe all the EV loads at this customer
        end
    end
end

    