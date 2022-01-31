function simdata = actor_critic_sim(agent, data, incentives, cond)

    %{
    Simulation of the action sequences for both the set size manipulation experiment
    and the incentive & load manipulation experiment.
    
    Called by: sim_from_empirical() & analyze_simdata_exp2()
    %}

    if ~isfield(agent, 'beta')
        agent.beta = agent.beta0;
    end

    if nargin==3 && ~exist('cond', 'var')
        cond = {{'Ns4,baseline'}, {'Ns4,train', 'Ns4,perform', 'Ns4,test'},...
                {'Ns6,baseline'}, {'Ns6,train', 'Ns6,perform', 'Ns6,test'}};
    end

    for setId = 1:length(cond)
        idx = [];
        expCond = cond(setId);
        for c = 1:length(expCond)
            idx = [idx find(strcmp(data.cond, expCond{c}))'];
        end
        condition = data.cond(idx);
        state = data.s(idx);
        corrchoice = state;
        setsize = length(unique(state));
        nA = setsize + 1;                 
        theta = zeros(setsize, nA);               
        V = zeros(setsize,1)+0.01;             
        Q = zeros(setsize,nA)+0.01;                    
        beta = agent.beta;
        p = ones(1,nA)/nA;

        if setsize==4
            %p=[0.25 0.125 0.25 0.25 0.125]; 
            chunk = [2 1];
            if ~exist('incentives', 'var')
                reward = [eye(4), transpose([0 1 0 0])];
            else
                reward = incentives.Ns4;
            end
        end
        if setsize==6
            %p=[1/6 1/6 1/6 1/6 1/12 1/6 1/12]; 
            chunk = [5 4];
            if ~exist('incentives', 'var')
                reward = [eye(6), transpose([0 0 0 0 1 0])];
            else
                reward = incentives.Ns6;
            end
        end

        ecost = 0;
        inChunk = 0;
        chunkStep = 0;
        a_actual = 0;
        policy_prev = 0;

        for t = 1:length(state)
            s = state(t);
            d = beta * theta(s,:) + log(p);
            logpolicy = d-logsumexp(d);
            policy = exp(logpolicy);    % softmax policy
            if inChunk == 0
                a = fastrandsample(policy); % action
                if a==nA; inChunk=1; chunkStep=1; end
            else
                chunkStep = chunkStep+1;
                a = nA;
            end

            if inChunk == 0; a_actual = a; end
            if inChunk == 1; a_actual = chunk(chunkStep); end

            r = reward(s, a_actual);
            cost = logpolicy(a) - log(p(a));
            if inChunk==1 && chunkStep>1; cost=0; end

            if agent.m > 1                       
                rpe = beta*r - cost - V(s);       
            else
                rpe = r - V(s);                   
            end
            ecost = ecost + agent.lrate_e*(cost-ecost);    % policy cost update

            if agent.lrate_beta > 0
                beta = beta + agent.lrate_beta*2*(agent.C-ecost); 
                beta = max(min(beta,50),0);
            end

            % we use the Boolean variable inChunk to track whether the agent is executing a chunk
            if ~inChunk % if not in chunk, update theta(s,a) and Q(s,a) as we normally would
                g = rpe*beta*(1 - policy(a));   
                theta(s,a) = theta(s,a) + agent.lrate_theta*g;             
                Q(s,a) = Q(s,a) + agent.lrate_V*(beta*r-cost-Q(s,a));
                V(s) = V(s) + agent.lrate_V*rpe;  
                p = p + agent.lrate_p*(policy - p); p = p./sum(p);
                if a==chunk(1) % if the primitive action corresponds to the CI action is selected, also update the chunk
                               % rationale: if we only look at the current step, selecting the primitive CI action
                               % and selecting the chunk both earn us the same reward, therefore they should be
                               % assigned the same credit
                    theta(s,nA) = theta(s,nA) + agent.lrate_theta*g;
                    Q(s,nA) = Q(s,nA) + agent.lrate_V*(beta*r-cost-Q(s,a));
                end

            else        % if currently in chunk
                if chunkStep==2 % update theta and Q only after the chunk is done
                    s_prev = simdata.s(idx(t-1)); % s_prev becuase we made the decision to execute the chunk in s(t-1)
                    r_chunk = (simdata.r(idx(t-1))==1 && r==1);  % r_chunk is the total reward for the entire chunk!!

                    % If the chunk perfectly corresponds to two consecutive states, there would be a positive reward of 1;
                    % otherwise, there is a negative reward to punish the execution of chunk becuase S(t-1) and S(t) do not
                    % usually appear together.
                    % Regard the r_chunk as measuring the ASSOCIATION between S(t-1) and S(t) !!
                    if r_chunk==0; r_chunk=-1; end             
                                      
                    rpe_chunk = beta*r_chunk - simdata.cost(idx(t-1)) - V(s_prev); % rpe of executing the chunk in the previous step
                    g_chunk = rpe_chunk*beta*(1-policy_prev(nA));
                    theta(s_prev,nA) = theta(s_prev,nA) +agent.lrate_theta*(g_chunk);  % "backprop" the credit of chunk to the previous state
                    Q(s_prev,nA) = Q(s_prev,nA) + agent.lrate_V*(beta*r_chunk-simdata.cost(idx(t-1))-Q(s_prev,a));
                    V(s_prev) = V(s_prev) + agent.lrate_V*rpe_chunk;  
                    p = p + agent.lrate_p*(policy - p); p = p./sum(p);

                    % note that here we do not update policy parameters for the current step, becuase at the current step we have
                    % no autonomy in terms of selecting an action according to the poliy; we're just following the chunk execution
                end
            end

            simdata.s(idx(t)) = s;
            simdata.a(idx(t)) = a_actual;
            simdata.r(idx(t)) = r;
            simdata.acc(idx(t)) = s==a_actual;
            simdata.beta(idx(t)) = beta;
            simdata.ecost(idx(t)) = ecost;
            simdata.cost(idx(t)) = cost;
            simdata.cond(idx(t)) = condition(t);
            simdata.theta{idx(t)} = theta;
            simdata.inChunk(idx(t)) = inChunk;
            simdata.chunkStep(idx(t)) = chunkStep;
            simdata.policy{idx(t)} = policy;
            if chunkStep==length(chunk); inChunk=0; chunkStep=0; end
            policy_prev = policy;

        end
        simdata.p(setId) = {p};
    end
end


