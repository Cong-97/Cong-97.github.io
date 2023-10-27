function [sampledNodes,EVPowers] = Nodes_And_Powers_Sampling_GM(Power_rates,totalNodes)
    
    % Sampling Nodes with EV charging demand 
    maxSampleSize = totalNodes;
    % Initialize the sampled nodes
    sampledNodes = [];
    
    % Loop until we have sampled 50 nodes
    while length(sampledNodes) < maxSampleSize
        % Generate a random sample of nodes that haven't been sampled before
        remainingNodes = setdiff(1:totalNodes, sampledNodes);
        
        % Calculate the number of nodes to sample in this iteration
        remainingSampleSize = min(maxSampleSize - length(sampledNodes), length(remainingNodes));
        
        % Randomly sample nodes from the remaining nodes
        sampledNodes = [sampledNodes, randsample(remainingNodes, remainingSampleSize)];
    end
    
    
    stepSize = 5;
    
    % Initialize the sampled nodes and steps
    sampledNodes = [];
    steps = [];
    
    % Loop until we have sampled 50 nodes
    while length(sampledNodes) < maxSampleSize
        % Generate a random sample of nodes that haven't been sampled before
        remainingNodes = setdiff(1:totalNodes, sampledNodes);
        
        % Calculate the number of nodes to sample in this iteration
        remainingSampleSize = min(maxSampleSize - length(sampledNodes), stepSize);
        
        % Randomly sample nodes from the remaining nodes
        sampled = randsample(remainingNodes, remainingSampleSize);
        sampledNodes = [sampledNodes, sampled];
        steps = [steps, length(sampledNodes)];
    end
    
    % Sampling EV charging power for each node
    
    numSamples = totalNodes;
    
    % Initialize an array to record the sampled values
    EVPowers = zeros(1, numSamples);
    
    % Randomly sample values
    for i = 1:numSamples
        EVPowers(i) = randsample(Power_rates, 1);
    end
end
