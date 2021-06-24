function [lik,latents] = actor_critic_lik(x,data)
%{
fixed model free parameters (4):
    agent.beta:         fitted value of beta
    agent.lrate_theta:  actor learning rate
    agent.lrate_V:      critic learning rate
    agent.lrate_p:      learning rate for marginal action probability

adaptive model free parameters (6):
    agent.C:            capacity
    agent.lrate_theta:  actor learning rate
    agent.lrate_V:      critic learning rate
    agent.lrate_p:      learning rate for marginal action probability
    agent.lrate_beta:   learning rate for beta
    agent.beta0:        initial beta value

reduced adaptive model free parameters (5);
    agent.C:            capacity
    agent.lrate_theta:  actor learning rate
    agent.lrate_V:      critic learning rate
    agent.lrate_beta:   learning rate for beta
    agent.beta0:        initial beta value
%}


if length(x)==2             % no cost model            
    agent.m = 1;
    agent.C = [];
    agent.lrate_theta = x(1);
    agent.lrate_V = x(2);
    agent.lrate_p = 0;
    agent.beta0 = 1;
    agent.lrate_beta = 0;
    agent.lrate_e = 0.1;


elseif length(x)==3         % "best" model
    agent.m = 2;
    agent.lrate_theta = x(1);
    agent.lrate_V = x(2);
    agent.C = x(3);
    agent.beta0 = 1;
    agent.lrate_beta = 1;
    agent.lrate_p = 0;
    agent.lrate_e = 0.1;

   
elseif length(x)==4        % fixed model   THIS ONE PERFORMS BEST FOR NOW
    agent.m = 3;
    agent.lrate_theta = x(1);
    agent.lrate_V = x(2);
    agent.beta0 = x(3);
    %agent.C = x(4);
    %agent.lrate_p = 0;
    agent.lrate_p = x(4);
    agent.lrate_beta = 0;
    agent.lrate_e = 0.1;
  
    
elseif length(x)==5          % reduced adaptive model
    agent.m = 5;
    agent.lrate_theta = x(1);
    agent.lrate_V = x(2);
    agent.lrate_beta = x(3);
    agent.beta0 = x(4);
    agent.C = x(5);
    agent.lrate_p = 0;
    agent.lrate_e = 0.1;
    
elseif length(x)==6         % adaptive model
    agent.m = 6;
    agent.lrate_theta = x(1);
    agent.lrate_V = x(2);
    agent.lrate_beta = x(3);
    agent.beta0 = x(4);
    agent.C = x(5);
    agent.lrate_p = x(6);
    agent.lrate_e = 0.1;
end


C = unique(data(1).cond);
lik = 0;

for c = 1:length(C)
    ix = find(strcmp(data.cond, C{c}));
    reward = data.r(ix);
    action = data.a(ix);
    state = data.s(ix);
    acc = data.acc(ix); 
    setsize = length(unique(state));    % number of distinct states
    nA = length(unique(action));        % number of distinct actions
    theta = zeros(setsize,nA);          % policy parameters
    V = zeros(setsize,1);               % state values
    Q = zeros(setsize,nA);              % state-action values
    p = ones(1,nA)/nA;                  % marginal action probabilities
    beta = agent.beta0;
    ecost = 0;
    
    if nargout > 1                      % if you want to collect the latents
        ii = find(ix);
    end
    
    for t = 1:length(state)
        s = state(t); a = action(t); r = reward(t);
        if isnan(a)
            continue;
        end
        d = beta * theta(s,:) + log(p);
        logpolicy = d - logsumexp(d);
        policy = exp(logpolicy);               % softmax policy
        lik = lik + logpolicy(a);
        cost = logpolicy(a) - log(p(a));       % policy complexity cost
        
        if agent.m > 2                         % if it's a cost model
            rpe = beta*r - cost - V(s);        % reward prediction error
        else
            rpe = r - V(s);                    % reward prediction error w/o cost
        end
        
        g = rpe*beta*(1 - policy(a));                  % policy gradient
        V(s) = V(s) + agent.lrate_V*rpe;               % state value update
        Q(s,a) = Q(s,a) + agent.lrate_V*(beta*r-cost-Q(s,a));    % state-action value update
        ecost = ecost + agent.lrate_e*(cost-ecost);    % policy cost update
        
        if agent.lrate_beta > 0
            beta = beta + agent.lrate_beta*2*(agent.C-ecost); % squared deviation is independent of beta (beta not in policy)
            beta = max(min(beta,50),0);
        end
        
        if agent.lrate_p > 0
            p = p + agent.lrate_p*(policy - p); p = p./sum(p);  % marginal update
        end
        
        theta(s,a) = theta(s,a) + agent.lrate_theta*g;                  % policy parameter update
        
        if nargout > 1                                          % if you want to collect the latents
            latents.rpe(ii(t)) = rpe;
        end
        
    end % trials in block end
end % block end
        