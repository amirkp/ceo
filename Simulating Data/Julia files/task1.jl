Pkdd("Distributions")udd("JuMP"udd("Gurobi"udd("LinearAlgebra")));g.add("Distributions");
Pukg.add("JuMP")
Pkg.add("Gurobi")
Pkg.add("LinearAlgebra")

ing LinearAlgebra;sing Distributions;
using Gurobi;
using JuMP;
using LinearAlgebra;

function task1(N,μZ,ΣZ,μE,ΣE)
n=N-1
paraZ = MvNormal(μZ, ΣZ);#parameters of joint distribution of (ZU,ZD)
paraE = MvNormal(μE, ΣE);#parameters of joint distribution of (EU,ED)
rand_Z = rand(paraZ,1);#draw random numbers
rand_E = rand(paraE,1);
ZU=reshape(rand_Z[1:N^2,1],N,N);
ZD=reshape(rand_Z[N^2+1:2N^2,1],N,N);
EU=reshape(rand_E[1:N^2,1],N,N);
ED=reshape(rand_E[N^2+1:2N^2,1],N,N);
S=ZU+ZD+EU+ED; #sum matrix
capacity = ones(N,N);#a matrix filled with 1s
Pairmodel = Model(solver=GurobiSolver(Presolve=0));#find the optimal assignment
@variable(Pairmodel, flow[i=1:N,j=1:N]>=0);
@constraint(Pairmodel,flow .<= capacity);#the elements in flow should be either 0 or 1
for j=1:N#each upstream (downstream) firm is matched to at most one downstream (upstream) firm.
    @constraint(Pairmodel, sum(flow[j,i] for i=1:N)<=1);
    @constraint(Pairmodel, sum(flow[i,j] for i=1:N)<=1);
end
@constraint(Pairmodel, sum(flow)==N);#N pairs are expected
@objective(Pairmodel,Max, sum(flow.*S) );#maximize profit
solve(Pairmodel);
assignment = getvalue(flow);#record the optimal assignment
production = getvalue(flow).*S#production of each pair in the optimal assignment
profit0 = sum(production);#profit of optimal assignment
profit_Up = zeros(N,1);#define the profit matrix
profit_Down = zeros(N,1);
for t=1:N
Pairmodel2 = Model(solver=GurobiSolver(Presolve=0))#find the optimal assignment with upstreaming t unmatched
    @variable(Pairmodel2, flow2[i=1:N,j=1:N]>=0);
    @constraint(Pairmodel2,flow2.<= capacity);#the elements in flow should be either 0 or 1
    for j=1:n#each upstream (downstream) firm is matched to at most one downstream (upstream) firm.
        @constraint(Pairmodel2, sum(flow2[j,i] for i=1:N)<=1);
        @constraint(Pairmodel2, sum(flow2[i,j] for i=1:N)<=1);
    end
    @constraint(Pairmodel2,sum(flow2[t,:])== 0);#upstreaming t is unmatched, so the t row of flow should be filled with 0
    @constraint(Pairmodel2, sum(flow2)==n);#n pairs are expected
    @objective(Pairmodel2,Max, sum(flow2.*S));#maximize profit
    solve(Pairmodel2);
profit_Up[t,1] = profit0 - sum(getvalue(flow2).*S);#record the difference of profit one by one
profit_Down[t,1] = sum(production[t,:])-profit_Up[t,1];#there's only one non-zero element in each row of matrix production,so row sum is the S_t,j
end
if sum(profit_Up)+sum(profit_Down)>=sum(production)
    feasibility= 1;
else feasibility=0;
end
stability_matrix = zeros(N,N)#use this matrix to record the stability
if feasibility == 1;
    for i = 1:N;#by definition 12 in the paper,(i) u_i>=O, v_j>=O,(ii) u_i + v_j >= α_ij for all (i, j)∈ P x Q.
        for j = 1:N;
            if profit_Up[i,1] >=0;#u_i>=O
                if profit_Down[j,1] >=0;#v_j>=O
                    if profit_Up[i,1] + profit_Down[j,1] >= S[i,j];#u_i + v_j >= α_ij for all (i, j)∈ P x Q
                        stability_matrix[i,j] = 1;#if all elements in stability_matrix are 1s, it's stable
                    end
                end
            end
        end
    end
end
if stability_matrix == capacity;#if all elements in stability_matrix are 1s, it's stable
    stability = "stable";
    else stability = "unstable"
end
return ZU,ZD,EU,ED,assignment,profit_Up,profit_Down,stability
end #funtion task1 end

#test part, just for testing
N = 10; #the number of firms
μZ=[100*ones(N^2);50*ones(N^2)];#mean of joint distribution of (ZU,ZD)
ΣZ=I+zeros(2N^2,2N^2);#variance-covariance marix of joint distribution of (ZU,ZD)
μE=[20*ones(N^2);10*ones(N^2)];#mean of joint distribution of (EU,ED)
ΣE=I+zeros(2N^2,2N^2);#variance-covariance marix of joint distribution of (ZU,ZD)
(ZU,ZD,EU,ED,assignment,profit_Up,profit_Down,stability)= task1(N,μZ,ΣZ,μE,ΣE);
