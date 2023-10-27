clear;
clc;
% The type of cooling for the transformer is selected as ONAN.
% The unit of temperature is degrees celsius.
%% Transformer Thermal Parameters
thetaH = 110; % The hottest-spot temperature.
thetaA_min = -30; % The minimum ambient temperature.
thetaA_max = 40; % The maximum ambient temperature.
R = 8; % The ratio of load loss at rated load to no-load loss on the tap position.
deltathetaTO_R = 55; % The top-oil rise over ambient temperature at rated load on the tap position.
deltathetaHS_R = 25; % The winding hottest-spot rise over top-oil temperature at rated load on the tap position.
n = 0.8; % An empirically derived exponent used to calculate the variation of deltathetaTO_R.
m = 0.8; % An empirically derived exponent used to calculate the variation of deltathetaHS_R.
%% Loading Transformer Current Data
k = transpose(0.5:0.01:1.5); % The ratio of actual distribution transformer(DT) load to the rated load.
K = k.^2; % The square of the ratio of actual DT load to the rated load
%% Calculating Ambient Temperature
cTO = deltathetaTO_R/((R+1)^n); % Intermediate coefficient for the next equation.
thetaA = thetaH - (cTO*(R*K + 1).^n + deltathetaHS_R*(K.^m)); % The relationship betweem DT capacity and its ambient temperature thetaA.
%% K-thetaA Curve Fitting
idx = (thetaA_min <= thetaA)&(thetaA <= thetaA_max); % Indices of the effective thetaA.
idx1 = thetaA_min > thetaA; % Indices of the temperatures below the minimum thetaA.
idx2 = thetaA_max < thetaA; % Indices of the temperatures above the maximum thetaA.
DT = [thetaA(idx),k(idx)]; % Effective K-thetaA.
DT_min = [thetaA(idx1),k(idx1)]; % Removed K-thetaA.
DT_max = [thetaA(idx2),k(idx2)]; % Removed K-thetaA.
p = polyfit(DT(:,1),DT(:,2),2); % Fitting the K-thetaA curve with the polynomial function. 
k_pre = p(1)*(DT(:,1).^2) + p(2)*DT(:,1) + p(3); % Predict the values of k according to the above fitted curve. 
%% Predict the value of k of the DT in Ames, USA
load('TAmes2022'); % Loading the temperature data of Ames over 2022.
k_pre_year = p(1)*(T.^2) + p(2)*T + p(3);