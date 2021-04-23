clc
clear
load epi_params

%Time parameters
T_vec = pars.T_vec;
N_steps = pars.N_steps;
n = pars.n; % network size

load rand_bip_n200.mat; % load a bipartite network of 200 nodes called 'adj'
load hcw_pat_id.mat % load logical column vectors for hcw and pat
%Epi is the network with the number of S, E, I and R in every time step
zero_vector = pars.zero_vector;

%Rewire frequency
daily = 24*6;
weekly = daily*7;
rewire_freq = weekly;
isolation_freq = weekly;
isolation_rewiring_freq = weekly;
n_runs = 500;
inf_0 = 1;
% Vectors
epi = zeros(5, N_steps); % 1 - S (0), 2 - E (1),3 - I(2), 4 - R(3), 5 - ISOLATED(4)

% Number of iterations
R_init = [0, 5, 10, 20, 40, 80, 120, 160]; % initial number of immunized indiv.

%% BASELINE CASE
Rinf_bas = zeros(n_runs, length(R_init));
for i = 1:length(R_init)
    for j = 1:n_runs
    rec_0 = R_init(i);
    node_status = initial_cond(inf_0, rec_0, pars);
    epi = zeros(4, N_steps);

    for i_t = 1:N_steps
        node_status = SEIR_stochastic_fct(adj, node_status, pars); %SEIR dynamics
        epi(:,i_t) = type_to_count(node_status); % Count each type
    end
    
    Rinf_bas(j, i) = epi(4,end);
    end
end

%% PREWIRING CASE
Rinf_prew = zeros(n_runs, length(R_init));
for i = 1:length(R_init)   
    for j = 1:n_runs
    rec_0 = R_init(i);
    node_status = initial_cond(inf_0, rec_0, pars);
    epi = zeros(4, N_steps);

    %prewire the network
    adj_new = pre_rewire(adj, node_status, is_pat, is_hcw);
    
    for i_t = 1:N_steps
        node_status = SEIR_stochastic_fct(adj_new, node_status, pars); %SEIR dynamics
        epi(:,i_t) = type_to_count(node_status); % Count each type
    end
    
    Rinf_prew(j, i) = epi(4, end); 
    end   
end
%% ISOLATION CASE
Rinf_iso = zeros(n_runs, length(R_init));
epi_R = zeros(n_runs, N_steps);

for i = 1:length(R_init)  
    for j = 1:n_runs
    rec_0 = R_init(i);
    node_status = initial_cond(inf_0, rec_0, pars);
    epi = zeros(4, N_steps);    
    
    for i_t = 1:N_steps 
        node_status = SEIR_stochastic_fct(adj, node_status, pars);

        if mod(i_t, isolation_freq) == 0
             node_status = isolate_hcw(node_status, is_hcw, pars); % isolation intervention
        end
        epi(:,i_t) = type_to_count(node_status); % Count each type
    end
    
    % Run de SEIR model over 100 days and isolate infected HCW every week  
    Rinf_iso(j, i) = epi(4,end);

    end  
end
%% REWIRING CASE
Rinf_rew = zeros(n_runs, length(R_init));

for i = 1:length(R_init)
    for j = 1:n_runs
        adj_new = adj;
        rec_0 = R_init(i);
        node_status = initial_cond(inf_0, rec_0, pars);
        epi = zeros(4, N_steps);
        
        for i_t = 1:N_steps    
            node_status = SEIR_stochastic_fct(adj_new, node_status, pars); %SEIR dynamics
            
            if rem(i_t, rewire_freq) == 0
                adj_new = rewire_all(adj_new, node_status, is_pat, is_hcw);
            end
            epi(:, i_t) = type_to_count(node_status);
        end
        Rinf_rew(j, i)=epi(4, end);   
    end
end
%% REWIRING + ISOLATION CASE
Rinf_rewiso = zeros(n_runs, length(R_init));

for i = 1:length(R_init)
    for j = 1:n_runs
        adj_new = adj;
        rec_0 = R_init(i);
        node_status = initial_cond(inf_0, rec_0, pars);
        epi = zeros(4, N_steps);
        
        for i_t = 1:N_steps
            node_status = SEIR_stochastic_fct(adj_new, node_status, pars);
            
            if mod(i_t, isolation_rewiring_freq) == 0
                node_status = isolate_hcw(node_status, is_hcw, pars); % first do isolation of infected hcws
                adj_new = rewire_all(adj_new, node_status, is_pat, is_hcw); % then do rewiring
            end
            epi(:, i_t) = type_to_count(node_status);
        end
        Rinf_rewiso(j, i) = epi(4, end);
    end
end
%%
% Calculate the Probability of an outbreak greater than 10% of the
% population.
P_outbreak = zeros(length(R_init), 5);
P_outbreak(:,1) = sum((Rinf_bas-R_init) > n * 0.1)./n_runs;
P_outbreak(:,2) = sum((Rinf_prew-R_init) > n * 0.1)./n_runs;
P_outbreak(:,3) = sum((Rinf_iso-R_init) > n * 0.1)./n_runs;
P_outbreak(:,4) = sum((Rinf_rew-R_init) > n * 0.1)./n_runs;
P_outbreak(:,5) = sum((Rinf_rewiso-R_init) > n * 0.1)./n_runs;

%% Figure 4
figure(4);
hold all
colorpalette=[0.7,0.7,0.7;1,1,0.1;0.3,0.8,0.2;0.1,0.2,0.8;0.6,0.1,0.7];
for x=1:5    
    area((R_init.*100) / n,P_outbreak(:,x),'LineWidth',1.5,...
        'EdgeColor','w','FaceColor',colorpalette(x,:),'FaceAlpha',0.7);

    xlabel('% Immunization')
    ylabel('Prob. outbreak>10%');  
end

legend('no interventions','prewiring','isolation (w)','rewiring (w)','isolation+rewiring (w)','box','off')
box on
set(gca, 'FontSize', 16) 
hold off;