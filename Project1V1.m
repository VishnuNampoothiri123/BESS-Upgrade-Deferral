% ECE488/588: Smart Grid Technologies
% By: Vishnu Nampoothiri
% Date: 02/23/2024

clear;
clc;
close all;

% Create a txt file to store all results from terminal
dfile ='Energy.txt';
if exist(dfile, 'file') ; delete(dfile); end
diary(dfile)
diary on
% Load data from the Excel file
data = readtable('Load Profile.xlsx', 'PreserveVariableNames', true);
load_profile = data.('Load');

% Constants
loading_limit = 7.5 * 1000; % Convert loading limit to kW
load_growth_factor = 1.02;
years = 2023:2026;
battery_roundtrip_efficiency = 0.95;
SOC = 0.3;
deferral = 5;

% Calculate load profiles for all years
load_profiles = load_profile * (load_growth_factor .^ (years - years(1)));
exceeding_limits = load_profiles > loading_limit;
cumulative_energies = cumsum(max(0, load_profiles - loading_limit), 1);

% Plotting
for i = 1:length(years)    
    [maxCumulativeEnergy,cumEnergyTotal]=maxCumEnergy(load_profiles(:, i));
    max_cumulative_energies=maxCumulativeEnergy;
    figure;
    % Subplot for Load Profile and Violating Hours
    subplot(2, 1, 1);
    data.Time.Format='hh:mm:ss a';
    plot(data.Time, load_profiles(:, i), 'LineWidth', 2);
    hold on;
    plot(data.Time, loading_limit * ones(size(data.Time)), '--r', 'LineWidth', 2);
    label_position = [0.5, loading_limit];
    text(data.Time(1), label_position(2), '  7.5 MW', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'FontSize', 10, 'Color', 'r');
    plot(data.Time(exceeding_limits(:, i)), load_profiles(exceeding_limits(:, i), i), 'mx');
    xlabel('Time');
    ylabel('Load (kW)');
    legend('Load Profile', 'Loading Limit', 'Violating Hours','Location','best');
    title(['Load Profile and Violating Hours - Year ', num2str(years(i))]);
    grid on;
    % Subplot for Cumulative Violating Energy
    subplot(2, 1, 2);
    plot(data.Time, cumEnergyTotal(:), '-g', 'LineWidth', 2);
    xlabel('Time');
    ylabel('Cumulative Violating Energy (kWh)');
    legend('Cumulative Violating Energy','Location','best');
    title(['Cumulative Violating Energy - Year ', num2str(years(i))]);
    grid on;
    saveas(gcf, ['Plot_Year_', num2str(years(i)), '.png']);
    % Display required information for each year
    disp(['Year: ', num2str(years(i))]);
    disp(['Total Violating Hours: ', num2str(sum(exceeding_limits(:, i)))]);
    disp(['Total Violating Energy (kWh): ', num2str(cumulative_energies(end, i))]);
    disp(['Maximum Load Above Limit (kW): ', num2str(max(load_profiles(:, i) - loading_limit))]);
    disp(['Maximum Cumulative Violating Energy (kWh): ', num2str(max_cumulative_energies)]);
    
    required_battery_size_MWh = max_cumulative_energies / (battery_roundtrip_efficiency * (1 - SOC));
    disp(['Required Battery Size (MW): ', num2str(max(load_profiles(:, i) - loading_limit))]);
    disp(['Required Battery Size (MWh): ', num2str(required_battery_size_MWh)]);
    disp(' ');
end
diary off

% A function to calculate the cumulative violation energy
function [maxCumulativeEnergy,cumEnergyTotal]=maxCumEnergy(Load)
    vioEnergy = zeros(size(Load));
    cumEnergy = zeros(size(Load));
    for i = 2:length(Load)
        exceedingEnergy = max(Load(i) - 7500, 0);
        vioEnergy(i) = exceedingEnergy;
        
        if vioEnergy(i) > 0
            if cumEnergy(i - 1) > 0
                cumEnergy(i) = cumEnergy(i - 1) + vioEnergy(i);
            else
                cumEnergy(i) = vioEnergy(i);
            end
        else
            cumEnergy(i) = 0;
        end
    end
    
    % Initialize an empty array to store values one index before zero
    cumEnergyTotal = zeros(size(Load));
    % Iterate through zero indices and capture values one index before them
    for i = 2:length(cumEnergy)
        if(cumEnergy(i)==0)
            if(cumEnergy(i-1)~=0)
                cumEnergyTotal(i-1) = cumEnergy(i-1);
            end
        end
    end
   maxCumulativeEnergy=max(cumEnergyTotal);
    %load_profile = [Load, vioEnergy, cumEnergy,cumEnergyTotal];
end


