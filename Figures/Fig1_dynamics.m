clc
clear
addpath Functions
addpath Data
addpath Figures
load epi_params

%Time parameters
T_vec = pars.T_vec;
N_steps = pars.N_steps;
n = pars.n; % network size
pars.n_A = 100;

load rand_bip_n200.mat; % load a bipartite network of 200 nodes called 'adj'
load hcw_pat_id.mat % load logical column vectors for hcw and pat
%Epi is the network with the number of S, E, I and R in every time step
zero_vector = pars.zero_vector;

%Rewire frequency
daily = 24*6;
weekly = daily*7;
rewire_freq = weekly;
n_runs = 50;
inf_0 = 10; %initial number of infected hcws
rec_0 = 0; %initial number of recovered individuals

epi_S = zeros(n_runs, N_steps);
epi_E = zeros(n_runs, N_steps);
epi_I = zeros(n_runs, N_steps);
epi_R = zeros(n_runs, N_steps);
%% BASELINE CASE 

for i=1:n_runs
    %Initial conditions with inf_0 randomly infected hcws and rec_0
    %randomly immunized individuals
    node_status = initial_cond(inf_0, rec_0, pars);
    epi = zeros(4, N_steps);

    for i_t = 1:N_steps
        node_status = SEIR_stochastic_fct(adj, node_status, pars); %SEIR dynamics
        epi(:,i_t) = type_to_count(node_status); % Count each type
    end

    % Save each run 
    epi_S(i,:) = epi(1,:);
    epi_E(i,:) = epi(2,:);
    epi_I(i,:) = epi(3,:);
    epi_R(i,:) = epi(4,:);
end

S_bas_mean = mean(epi_S);
S_bas_std = std(epi_S);
E_bas_mean = mean(epi_E);
E_bas_std = std(epi_E);
I_bas_mean = mean(epi_I);
I_bas_std = std(epi_I);
R_bas_mean = mean(epi_R);
R_bas_std = std(epi_R);
%% REWIRING CASE

for i=1:n_runs
    %Initial conditions
    node_status = initial_cond(inf_0, rec_0, pars);
    epi = zeros(4, N_steps);
    %We are changing adj so we will be making a copy of it
    adj_new = adj;
    
    for i_t = 1:N_steps
        node_status = SEIR_stochastic_fct(adj_new, node_status, pars); %SEIR dynamics
        
        if rem(i_t, weekly) == 0 
             adj_new = rewire_all(adj_new, node_status, is_pat, is_hcw);
        end       
        epi(:, i_t) = type_to_count(node_status); 

    end
    % Save each run 
    epi_S(i,:) = epi(1,:);
    epi_E(i,:) = epi(2,:);
    epi_I(i,:) = epi(3,:);
    epi_R(i,:) = epi(4,:);
end

S_rew_mean = mean(epi_S);
S_rew_std = std(epi_S);
E_rew_mean = mean(epi_E);
E_rew_std = std(epi_E);
I_rew_mean = mean(epi_I);
I_rew_std = std(epi_I);
R_rew_mean = mean(epi_R);
R_rew_std = std(epi_R);

%% Figure 1 - No interventions and mitigation intervention dynamics
figure(1);
set(gcf, 'Position',  [400, 100, 700,600])% set position, width and height of plot
steps = 1 : (10*24*6) : N_steps;
steps_freq = 1 : (24*6) : N_steps;
color = [0.0,0.4,1.0; 1.0,0.6,0.2; 1.0,0.0,0.2; 0.0,0.8,0.2];

subplot(2,1,1); %Corresponding to panel A, no interventions
hold on

% % plot S

hold all
patch([T_vec(steps) fliplr(T_vec(steps))],...
    [S_bas_mean(steps)+S_bas_std(steps) fliplr(S_bas_mean(steps)-S_bas_std(steps))],...
    color(1,:),'FaceAlpha',0.1,'EdgeColor','none','HandleVisibility','off');
plot(T_vec(steps_freq),S_bas_mean(steps_freq),'LineWidth',2,'Color', color(1,:));
% % plot E
patch([T_vec(steps) fliplr(T_vec(steps))],...
    [E_bas_mean(steps)+E_bas_std(steps) fliplr(E_bas_mean(steps)-E_bas_std(steps))],...
    color(2,:),'FaceAlpha',0.1,'EdgeColor','none','HandleVisibility','off');
plot(T_vec(steps_freq),E_bas_mean(steps_freq),'LineWidth',2,'Color', color(2,:));

% % plot I
patch([T_vec(steps) fliplr(T_vec(steps))],...
    [I_bas_mean(steps)+I_bas_std(steps) fliplr(I_bas_mean(steps)-I_bas_std(steps))],...
    color(3,:),'FaceAlpha',0.1,'EdgeColor','none','HandleVisibility','off');

plot(T_vec(steps_freq),I_bas_mean(steps_freq),'LineWidth',2,'Color', color(3,:));

% % plot R
patch([T_vec(steps) fliplr(T_vec(steps))],...
    [R_bas_mean(steps)+R_bas_std(steps) fliplr(R_bas_mean(steps)-R_bas_std(steps))],...
    color(4,:),'FaceAlpha',0.1,'EdgeColor','none','HandleVisibility','off');

plot(T_vec(steps_freq), R_bas_mean(steps_freq),'LineWidth',2,'Color', color(4,:));

hold off
legend('S','E','I','R','Location','west','box','off');
title('No interventions');
xlabel('Time [days]');
ylabel('Number of nodes');
ylim([0,200]);
set(gca, 'FontSize',16);
xlabel('Time [days]');
xlim([0,50]);
box on

subplot(2,1,2); %Corresponding to panel B, Mitigation

figure(1)
hold on
%plot S
patch([T_vec(steps) fliplr(T_vec(steps))],...
    [S_rew_mean(steps)+S_rew_std(steps) fliplr(S_rew_mean(steps)-S_rew_std(steps))],...
    color(1,:),'FaceAlpha',0.1,'EdgeColor','none','HandleVisibility','off');
plot(T_vec(steps_freq), S_rew_mean(steps_freq),'LineWidth',2,'Color', color(1,:));
%plot E
patch([T_vec(steps) fliplr(T_vec(steps))],...
    [E_rew_mean(steps)+E_rew_std(steps) fliplr(E_rew_mean(steps)-E_rew_std(steps))],...
    color(2,:),'FaceAlpha',0.1,'EdgeColor','none','HandleVisibility','off');
plot(T_vec, E_rew_mean,'LineWidth',2,'Color', color(2,:));

% plot I
patch([T_vec(steps) fliplr(T_vec(steps))],...
    [I_rew_mean(steps)+I_rew_std(steps) fliplr(I_rew_mean(steps)-I_rew_std(steps))],...
    color(3,:),'FaceAlpha',0.1,'EdgeColor','none','HandleVisibility','off');

plot(T_vec(steps_freq),I_rew_mean(steps_freq),'LineWidth',2,'Color', color(3,:));

% plot R
patch([T_vec(steps) fliplr(T_vec(steps))],...
    [R_rew_mean(steps)+R_rew_std(steps) fliplr(R_rew_mean(steps)-R_rew_std(steps))],...
    color(4,:),'FaceAlpha',0.1,'EdgeColor','none','HandleVisibility','off');

plot(T_vec(steps_freq), R_rew_mean(steps_freq),'LineWidth',2,'Color', color(4,:));

hold off
legend('S','E','I','R','Location','west','box','off');
title('Mitigation');
xlabel('Time [days]');
ylabel('Number of nodes');
ylim([0,200]);
set(gca, 'FontSize',16);
xlabel('Time [days]');
xlim([0,50]);
box on