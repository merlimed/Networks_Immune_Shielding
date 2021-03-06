clc
clear
load epi_params

%Time parameters
T_vec = pars.T_vec;
N_steps = pars.N_steps;
n = pars.n; % network size

% Network names/iterations 
network=["rand_bip_n200.mat", "rand_bip_n200_ratio_1_3.mat", "rand_bip_n200_ratio_1_5.mat",...
    "rand_bip_n200_ratio_1_10.mat"];

% Load logical column vectors for hcw and pat (this will change for the different ratios)
id=["hcw_pat_id.mat","hcw_pat_id_ratio_1_3.mat","hcw_pat_id_ratio_1_5.mat","hcw_pat_id_ratio_1_10.mat"];

%Epi is the network with the number of S, E, I and R in every time step
zero_vector = pars.zero_vector;

%Rewire frequency
daily = 24*6;
weekly = daily*7;

%Initial conditions
n_runs = 500;
inf_0 = 10;
rec_0 = 0; 

% Vectors
epi = zeros(5, N_steps); % 1 - S (0), 2 - E (1),3 - I(2), 4 - R(3), 5 - ISOLATED(4)

%% BASELINE CASE
Rinf_bas = zeros(n_runs, length(network));
for i = 1:length(network)
    for j = 1:n_runs
        load(network(i));
        load(id(i));
        adj_new = full(adj);
        pars.n_A = sum(is_hcw);
        node_status = initial_cond(inf_0, rec_0, pars);
        epi = zeros(4, N_steps);
        
        for i_t = 1:N_steps
            node_status = SEIR_stochastic_fct(adj_new, node_status, pars); %SEIR dynamics
            epi(:,i_t) = type_to_count(node_status); % Count each type
        end

        Rinf_bas(j, i) = epi(4,end);
    end
end

%% REWIRING CASE DAILY

Rinf_rew_daily = zeros(n_runs, length(network));

for i = 1:length(network)
    for j = 1:n_runs
        load(network(i));
        load(id(i));
        adj_new = full(adj);
        pars.n_A = sum(is_hcw);

        
        node_status = initial_cond(inf_0, rec_0, pars);
        epi = zeros(4, N_steps);
        
        for i_t = 1:N_steps    
            node_status = SEIR_stochastic_fct(adj_new, node_status, pars); %SEIR dynamics
            
            if rem(i_t, daily) == 0 % daily rewiring
                adj_new = rewire_all(adj_new, node_status, is_pat, is_hcw);
            end
            epi(:, i_t) = type_to_count(node_status);
        end
        Rinf_rew_daily(j, i)=epi(4, end); 

    end
end


%% REWIRING CASE WEEKLY
Rinf_rew_weekly = zeros(n_runs, length(network));

for i = 1:length(network)
    for j = 1:n_runs
        load(network(i));
        adj_new = full(adj);
        load(id(i));
        
        pars.n_A = sum(is_hcw);
        node_status = initial_cond(inf_0, rec_0, pars);
        epi = zeros(4, N_steps);
        
        for i_t = 1:N_steps    
            node_status = SEIR_stochastic_fct(adj_new, node_status, pars); %SEIR dynamics
            
            if rem(i_t, weekly) == 0 % weekly rewiring
                adj_new = rewire_all(adj_new, node_status, is_pat, is_hcw);
            end
            epi(:, i_t) = type_to_count(node_status);
        end
        Rinf_rew_weekly(j, i)=epi(4, end);

    end
end

%% Supplementary Figure 4b - oubreak size of different staff:resident ratios

hold all;

data=[Rinf_bas(:,1), Rinf_rew_weekly(:,1), Rinf_rew_daily(:,1), Rinf_bas(:,2),...
    Rinf_rew_weekly(:,2),Rinf_rew_daily(:,2), Rinf_bas(:,3),Rinf_rew_weekly(:,3),...
    Rinf_rew_daily(:,3), Rinf_bas(:,4),Rinf_rew_weekly(:,4),Rinf_rew_daily(:,4)];

data=data-inf_0.*ones(size(data)); % remove initial infected

color_boxplot = brewermap(3, 'Set1');
boxplot(data,'color', color_boxplot)
ylabel('Outbreak size')

xlh = xlabel('staff ratios', 'Position', [6 -10]);
set(findobj(gca,'type','line'),'linew', 2)
set(gca,'XTickLabel',{' '})
text(1.2, -5, '1:1', 'fontsize', 12, 'fontweight', 'bold')
text(4.5, -5, '1:3', 'fontsize', 12, 'fontweight', 'bold')
text(8.0, -5,'1:5', 'fontsize', 12, 'fontweight', 'bold')
text(10.9, -5,'1:10', 'fontsize', 12, 'fontweight', 'bold')
set(gca, 'fontsize', 13, 'fontweight', 'bold')
ylim([0,200]);
hold off;
