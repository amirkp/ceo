Pkg.add("Distributions");
Pkg.add("JuMP")
Pkg.add("Gurobi")
Pkg.add("LinearAlgebra")

using Distributions;
using Gurobi;
using JuMP;
using LinearAlgebra;



function optimal(S,t,r,s)
    #this function is used to optimize profit with given factors
    #S is the production matrix with all pairs, which is ZU+ZD+EU+ED
    #if n<N, the 't'th ROW firm is remain unmatched
    #U means that one upstream firm is allowed to match at most U downstream firms
    #D means that one downstream firm is allowed to match at most D upstream firms
    capacity = ones(length(r),length(s));#a matrix filled with 1s
    Pairmodel = Model(solver=GurobiSolver(Presolve=0));#find the optimal assignment
    @variable(Pairmodel, flow[i=1:length(r),j=1:length(s)]>=0);
    # matrix flow is matrix filled with 1 or 0,flow[i,j]=1 means that Ui is matched with Dj
    @constraint(Pairmodel,flow.<= capacity);
    #the elements in flow should be either 0 or 1
    for i=1:length(r)
        #=
        each upstream firm is matched to at most r[i] downstream firm,
        so there are r[i] 1s in each row
        that is to say, the sum of each row should be r[i]
        =#
        @constraint(Pairmodel, sum(flow[i,j] for j=1:length(s))<=r[i]);
    end
    for j=1:length(s)
        #=
        each downstream firm is matched to at most s[j] upstream firm,
        so there are s[j] 1s in each column
        that is to say, the sum of each row should be s[j]
        =#
        @constraint(Pairmodel, sum(flow[i,j] for i=1:length(r))<=s[j]);
    end
    n=sum(r);    #n is the number of pairs
    if t>0
        @constraint(Pairmodel,sum(flow[t,i] for i=1:length(s))== 0);
        n-=1;   #in this condition, one firm is keeping unmatched, so the expected pairs are n-1
        #keep the t row firm unmatched
    end
    @constraint(Pairmodel, sum(flow)== n);#n pairs are expected
    #there are N 1s in the matrix flow, so the sum should be N
    @objective(Pairmodel,Max, sum(flow.*S) );#maximize profit of matched pairs
    solve(Pairmodel);
    assignment = getvalue(flow);#record the optimal assignment
end



function two_matching(μZ,ΣZ,μE,ΣE,weight,r,s)
    # this function is used to calculate profit and price
    # N is the number of firms.
    # weight is a number between 0 and 1, which is the weight of upstream profit
    # μZ,ΣZ,μE,ΣE is the mean and covariance matrix of Z and E
    #r is the upstream quota
    #s is the downstream quota
    paraZ = MvNormal(μZ, ΣZ);#parameters of joint distribution of (ZU,ZD)
    paraE = MvNormal(μE, ΣE);#parameters of joint distribution of (EU,ED)
    rand_Z = rand(paraZ,1);#draw random numbers
    rand_E = rand(paraE,1);
    N_Up = length(r); #N is the number of firms in the one to one related games
    N_Down = length(s);
#r_related = ones(N); #r_related is the quota of upstream firms in the one to one related games, actually full of 1s
    # reshape vectors into N*N matrices
    # ZU,ZD,EU,ED are N×N matrices of characteristics
    ZU=reshape(rand_Z[1 : N_Up*N_Down, 1], N_Up, N_Down);
    ZD=reshape(rand_Z[N_Up*N_Down+1 : 2N_Up * N_Down , 1], N_Up, N_Down);
    EU=reshape(rand_E[1 : N_Up*N_Down, 1], N_Up, N_Down);
    ED=reshape(rand_E[N_Up*N_Down+1 : 2N_Up * N_Down , 1], N_Up, N_Down);
#n=N-1
    S=ZU+ZD+EU+ED; #sum matrix,S[i,j] is the production of Ui and Dj if they are matched
    assignment = optimal(S,0,r,s);#record the optimal assignment
    production = assignment.*S;#production matrix of each pair in the optimal assignment
    # find the optimal assignment and S matrix of one to one related games
    N=sum(r)
    assignment_related_row = zeros(N,N);  #define zero matrices first
    S_related_row = zeros(N,N)
    ZU_related_row = zeros(N,N)
    ZD_related_row = zeros(N,N)
    EU_related_row = zeros(N,N)
    ED_related_row = zeros(N,N)
    #firstly, we seperate the upstream firms
    for i = 1 : N_Up    #row i of assignment
        for k = 1 : r[i];   # the k_th 1 in the row i, which is the k_th pair of upstream i. The max of k should be the quota of firm i
            c=0;    # c is used record the number of pairs we meet in row i, defaulted to be 0 as we haven't start
            for j = 1 : N_Down  # the j column of assignment
                if assignment[i,j] ==1  # if [i,j] is matched in the optimal assignment
                    c+=1 # we meet a pair, so c+1
                    if c==k # if this is the k_th pair we meet, that is to say, we haven't record this pair
                        assignment_related_row[sum(r[1:i-1])+k,j] = assignment[i,j];    #record this pair
                        S_related_row[sum(r[1:i-1])+k,j] = S[i,j];     #record the S, if [i,j] is the k_th pair
                        ZU_related_row[sum(r[1:i-1])+k,j] = ZU[i,j];
                        ZD_related_row[sum(r[1:i-1])+k,j] = ZD[i,j];
                        EU_related_row[sum(r[1:i-1])+k,j] = EU[i,j];
                        ED_related_row[sum(r[1:i-1])+k,j] = ED[i,j];
                    end
                else
                    S_related_row[sum(r[1:i-1])+k,j] = S[i,j];     #record the S, if [i,j] is not a pair
                    ZU_related_row[sum(r[1:i-1])+k,j] = ZU[i,j];
                    ZD_related_row[sum(r[1:i-1])+k,j] = ZD[i,j];
                    EU_related_row[sum(r[1:i-1])+k,j] = EU[i,j];
                    ED_related_row[sum(r[1:i-1])+k,j] = ED[i,j];
                end
            end
        end
    end
    #seperate downstream firms
    assignment_related = zeros(N,N);  #define zero matrices first
    S_related = zeros(N,N)
    ZU_related = zeros(N,N)
    ZD_related = zeros(N,N)
    EU_related = zeros(N,N)
    ED_related = zeros(N,N)
    for j = 1 : N_Down    #column i of assignment
        for k = 1 : s[j];   # the k_th 1 in the column i, which is the k_th pair of upstream i. The max of k should be the quota of firm i
            c=0;    # c is used record the number of pairs we meet in row i, defaulted to be 0 as we haven't start
            for i = 1 : N  # the j column of assignment
                if assignment_related_row[i,j] ==1  # if [i,j] is matched in the optimal assignment
                    c+=1 # we meet a pair, so c+1
                    if c==k # if this is the k_th pair we meet, that is to say, we haven't record this pair
                        assignment_related[i,sum(s[1:j-1])+k] = assignment_related_row[i,j];    #record this pair
                        S_related[i,sum(s[1:j-1])+k] = S_related_row[i,j];     #record the S, if [i,j] is the k_th pair
                        ZU_related[i,sum(s[1:j-1])+k] = ZU_related_row[i,j];
                        ZD_related[i,sum(s[1:j-1])+k] = ZD_related_row[i,j];
                        EU_related[i,sum(s[1:j-1])+k] = EU_related_row[i,j];
                        ED_related[i,sum(s[1:j-1])+k] = ED_related_row[i,j];
                    end
                else
                    S_related[i,sum(s[1:j-1])+k] = S_related_row[i,j];     #record the S, if [i,j] is not a pair
                    ZU_related[i,sum(s[1:j-1])+k] = ZU_related_row[i,j];
                    ZD_related[i,sum(s[1:j-1])+k] = ZD_related_row[i,j];
                    EU_related[i,sum(s[1:j-1])+k] = EU_related_row[i,j];
                    ED_related[i,sum(s[1:j-1])+k] = ED_related_row[i,j];
                end
            end
        end
    end
    production_related = S_related .* assignment_related;
    profit0 = sum(production);#profit of optimal assignment
    profit_Up = zeros(N,1);#define the profit matrix
    profit_Down = zeros(N,1);
    r_related = ones(N);    #the quota of one to one games is always 1
    r_related=convert(Array{Int64,1},r_related)
    for t=1:N# calculate the optimal upstream/downstream profit
        assignment_Up = optimal(S_related,t,r_related,r_related);
        profit_Up[t,1] = profit0 - sum(assignment_Up.*S_related);#profit_Up is ordered by i
        assignment_Down = optimal(S_related',t,r_related,r_related);#we consider downstream firms as upstream firms, so just transpose S_related here
        profit_Down[t,1] = profit0 - sum(assignment_Down.*S_related');#profit_Down is ordered by j
    end
    profit_respond_Up = production_related*ones(N,1) - assignment_related * profit_Down;
    #=
    Assume that Ui is matcher with Dj,
    then profit_respond_Up is S[i,j] - profit_Downi.
    As production[i,j] = S[i,j] if Ui and Dj are matched, = 0 if unmatched,
    the sum of row i and the sum of column j in production matrix are both equal to S[i,j].
    So production*ones(N,1) is the row sum of production matrix which is S[i,j] ordered by i.
    assignment * profit_Down will reorder the profit_Down matrix by the row order i rather than the column order j according to optimal assignment
    =#
    profit_respond_Down_tran = ones(1,N)*production_related - profit_Up' * assignment_related;
    #=
    Assume that Ui is matcher with Dj,
    then profit_respond_Downj is S[i,j] - profit_Upi.
    As production[i,j] = S[i,j] if Ui and Dj are matched, and 0 if unmatched,
    the sum of row i and the sum of column j in production matrix are both equal to S[i,j].
    So ones(1,N)*production is the column sum of production matrix which is S[i,j] ordered by j.
    profit_Up' * assignment will reorder the profit_Up matrix by the column order j rather than the row order i according to optimal assignment
    =#
    profit_respond_Down = profit_respond_Down_tran';#transpose row vector to column vector
    profit_mix_Up = weight * profit_Up + (1-weight) * profit_respond_Up;
    profit_mix_Down =  weight * profit_respond_Down + (1-weight) * profit_Down;
    Z_mix = weight * ZU_related + (1 - weight) * ZD_related;
    E_mix = weight * EU_related + (1 - weight) * ED_related;
    price = profit_mix_Up - (Z_mix + E_mix) .* assignment_related * ones(N,1);
    return ZU_related,ZD_related,EU_related,ED_related,assignment,profit_mix_Up,profit_mix_Down,price;
end #funtion two_matching end



function stability(ZU,ZD,EU,ED,profit_Up,profit_Down)
    N=length(profit_Down);
    stability_matrix = zeros(N,N)#use this matrix to record the stability
    S=ZU+ZD+EU+ED;
    capacity = ones(N,N);#a matrix filled with 1s
    for i = 1:N;#if Profit_Upi + profit_Downj >= S[i,j] for all (i, j)∈ N × N, regardless i and j are matched or not
        for j = 1:N;
            if profit_Up[i,1] + profit_Down[j,1] >= S[i,j]-0.000001;
                #=
                As there are approximately calculations bias, there's a threshold of 0.000001,
                which means numbers greater than -0.000001 is considered nonnegative.
                if the condition of [i,j] is satisfied, record it as 1, else it's still 0
                =#
                stability_matrix[i,j] = 1;
            end
        end
    end
    if stability_matrix == capacity;#if all elements in stability_matrix are 1s, it's stable
        stability = "stable";
        else stability = "unstable"
    end
    return stability
end#




#test part, just for testing
r=[1,4,2,3,4]; #the upstream quota
s=[2,5,1,2,1,2,1]; #the downstream quota
dim_quota = length(r)*length(s);
μZ=[100*ones(dim_quota);80*ones(dim_quota)];#mean of joint distribution of (ZU,ZD)
ΣZ=10I+zeros(2dim_quota,2dim_quota);#variance-covariance marix of joint distribution of (ZU,ZD)
μE=[100*ones(dim_quota);80*ones(dim_quota)];#mean of joint distribution of (EU,ED)
ΣE=10I+zeros(2dim_quota,2dim_quota);#variance-covariance marix of joint distribution of (ZU,ZD)


(ZU,ZD,EU,ED,assignment,profit_Up,profit_Down,price_Up) = two_matching(μZ,ΣZ,μE,ΣE,1,r,s);
stability_Up = stability(ZU,ZD,EU,ED,profit_Up,profit_Down)

(ZU,ZD,EU,ED,assignment,profit_Up,profit_Down,price_Down) = two_matching(μZ,ΣZ,μE,ΣE,0,r,s);
stability_Down = stability(ZU,ZD,EU,ED,profit_Up,profit_Down)

weight=0.6
(ZU,ZD,EU,ED,assignment,profit_mix_Up,profit_mix_Down,price_mix) = two_matching(μZ,ΣZ,μE,ΣE,weight,r,s);
stability_mix = stability(ZU,ZD,EU,ED,profit_mix_Up,profit_mix_Down)
