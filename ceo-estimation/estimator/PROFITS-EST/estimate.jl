### Estimation of the two sided matching model in Fox, Kazempour, and Tang (2023)
### using CEO-Firm Data 
### 
### Data Sources:
### CEO compensation: EXCECUCOMP
### Segment data: COMPUSTAT HISTORICAL SEGMENTS
### Firm's fundamentals: CRSP

###  March 10, 2023
### Amir Kazempour, amirkp@gmail.com
############################################


## uncomment for running on Rice cluster



using BSON, CSV    # BSON for storing optimization results, CSV for reading data file
using LinearAlgebra
using Random
using Distributions
using BlackBoxOptim
using Assignment # Install the fork from https://github.com/amirkp/AssignmentDual.jl.git to have access to dual variables
using Optim   # Local Optimization (Nelder-Mead)
using DataFrames
include("JV_DGP-LogNormal.jl") # DGP for likelihood simulation

#################
##### SETUP #####
#################


# loading data
# data = CSV.read("/home/ak68/est_data_RANDOM.csv", DataFrame)
data = CSV.read("/Users/amir/Data/est_data_RANDOM.csv", DataFrame)

data = Matrix(data)
up_data = data[:,5]     # Ability index or x 
down_data = data[:,2:3]'  # HHI and log(#employees) or (y_1, y_2 )
price_data= data[:,4]    # Compensation variable or p 
n_firms = length(price_data) # number of firms on ONE side of the market
price_data=exp.(price_data)  # compensation in thousand dollars calculated from log(compensation)
price_data=price_data./1000 # converting the compensation to million dollar unit

data

sort!(data, [:pGAI])

# Partitioning the pool of available cores
# Only needed for running multiple optimizations using one slurm file on NOTS
# @everywhere pool_a =  WorkerPool(collect(2:n_sim+1))
# @everywhere pool_b =  WorkerPool(collect(n_sim+2:nworkers()+1))

using KernelEstimator

x = rand(Beta(4,2), 500) * 10
y=2 .* x.^2 + x .* rand(Normal(0, 5), 500)

xreg = npr(up_data, price_data)
scatter(up_data, xreg, markersize=1)


y1reg = npr(down_data[1,:], price_data)
scatter(down_data[1,:], y1reg, markersize=1)



y2reg = npr(down_data[2,:], price_data)
scatter(down_data[2,:], y2reg, markersize=1)





using RCall

using RDatasets
@rput up_data
@rput down_data
@rput price_data

z=1
R"library(locpol)"
R"library(locpol)"
R"library(locpol)"
R"library(locpol)"


@rget ders
R"dersx = compDerEst(up_data, price_data, p =0)"
R"dersy1 = compDerEst(down_data[1,], price_data, p =0)"
R"dersy2 = compDerEst(down_data[2,], price_data, p =0)"


@rget dersx 
@rget dersy1
@rget dersy2

ders
ders

scatter(up_data, dersx[:,4], markersize = 2)

scatter(down_data[1,:], dersy1[:,4], markersize = 2)
scatter(down_data[2,:], dersy2[:,4], markersize = 2)




R"library(pspline)"
R"profs.spl <- sm.spline(up_data, price_data)
    "


R"lines(profs.spl, col = "blue")"

R"ups <- smooth.Pspline(up_data, price_data)"

R"ups <- sm.spline(down_data[2,], price_data, df =2)"


R"up_prof_s <- sm.spline(up_data, price_data, cv=TRUE,spar= 1.5)"
R"up_der<-predict(ups, up_data, nderiv=1)"

R"down_match_1_s<- sm.spline(up_data, down_data[1,], cv=FALSE,spar= .5)"
R"down_match_1<-predict(down_match_1_s, up_data, nderiv=0)"

R"down_match_2_s<- sm.spline(up_data, down_data[2,], cv=FALSE, df=10)"
R"down_match_2<-predict(down_match_2_s, up_data, nderiv=0)"




# @rget down_match 
@rget up_der
@rget down_match_1
@rget down_match_2



scatter(up_data, down_data[1,:], markersize=2)
scatter!(up_data, down_match_1, markersize=2)

scatter(up_data, down_data[2,:], markersize=2)
scatter!(up_data, down_match_2, markersize=2)




scatter(up_data, up_der, markersize=2)

i=20;
j = 120;

sum = 0.
count=0
for i = 1:500 
    for j = 1:500 
        if i!=j 
            if (2*(up_data[i]-up_data[j])*down_data[2,i]*down_data[2,j])!= 0     
                sum+=(up_der[j] * down_match[i] - up_der[i]*down_match[j])/(2*(up_data[i]-up_data[j])*down_data[2,i]*down_data[2,j])
                count+=1
            end

        end
    end
end


sum
count


sum/count


sum1 = 0.
count1= 0
for i = 1:500 
    for j = 1:500 
        if i!=j 
            if ((up_data[i]-up_data[j])*down_data[2,i]*down_data[2,j]) != 0 
                sum1 += (up_der[j] * up_data[i]*down_match[i] + up_der[i]*up_data[i]*down_match[j])/((up_data[i]-up_data[j])*down_data[2,i]*down_data[2,j])
                count1 += 1    
            end

        end
    end
end

sum1

count1

sum1/count1

7.56



-1.26* median(up_data[1,:])^2 

# 2*(up_data[i]-up_data[j])*down_data[1,i]*down_data[2,j]




scatter(up_data, up_der, markersize=2)
scatter!(up_data, down_match, markersize=2)

@rget down_match 
@rget up_der
# R"ups <- sm.spline(down_data[2,], price_data, cv=TRUE,spar= 3.5)"

# R"fun<-predict(ups, up_data, nderiv=1)"
R"fun<-predict(ups, down_data[2,], nderiv=1)"
@rget fun

# scatter(up_data, fun, markersize =2 )
scatter(down_data[2,:], fun, markersize =2 )

scatter!(up_data, price_data, markersize =2 )


df = DataFrame( PIU=up_der[:,1], Y1BAR= down_match_1[:,1], Y2BAR = down_match_2[:,1])

df
up_der[:,1]

using Plots 
using GLM, StatsBase
ols = lm(@formula(PIU ~ Y1BAR+Y2BAR), df)

stop 
# Bandwidth Selection  bcv2
# Sain, Stephan R., Keith A. Baggerly, and David W. Scott. 
# “Cross-Validation of Multivariate Densities.” Journal of the American Statistical Association 89, no. 427 (1994)

# Loss function to be minimized 
]@everywhere begin 
    function bcv2_fun(h, down_data, price_data)
        h=abs.(h)
        ll = 0.0
        n_firms = length(price_data)
        for i = 1:n_firms
            for j=1:n_firms
                if (j!=i)
                    expr_1 = ((down_data[1,i]-down_data[1,j])/h[1])^2 +
                     ((down_data[2,i]-down_data[2,j])/h[2])^2 + 
                     ((price_data[i]-price_data[j])/h[3])^2
                    
                     expr_2 = pdf(Normal(),(down_data[1,i]-down_data[1,j])/h[1]) *
                         pdf(Normal(),((down_data[2,i]-down_data[2,j])/h[2])) *
                             pdf(Normal(),((price_data[i]-price_data[j])/h[3]))

                    ll += (expr_1 - (2*3 +4)*expr_1 + (3^2 +2*3))*expr_2
                end
            end
        end
        val = ((sqrt(2*pi))^3 * n_firms *h[1]*h[2]*h[3])^(-1) +
                                ((4*n_firms*(n_firms-1))*h[1]*h[2]*h[3])^(-1) * ll
        return val
    end

    # We have the option to use a selected number of observation of the entire sample for bcv2 bandwidth calculation
    # inds is a vector of integers corresponding to the indices of the observations to be included in the sample passed to bcv2 
    # used exclusively in Monte Carlo studies
    # 1:n_firms would pass the entire sample as argument to bcv2_fun
    # inds = rand(1:n_firms, n_sim)
    inds = 1:n_firms;

    # # Optimize over choice of [h[1], h[2], h[3]]
    # The Nelder-Mead algorithm converges successfully most of the time

    res_bcv = Optim.optimize(x->bcv2_fun(x,down_data[1:2,inds],price_data[inds]), [0.1,.1,1.11]);


    @show h = abs.(Optim.minimizer(res_bcv))
    

    # Check if the bandwidth has not converged or converged to a unreasonable point
    if sum(h .> 10) >0 
        println("BAD BANDWIDTH")
    end

    # Scaling the parameters
    h[1] = h[1] * h_scale[1]
    h[2] = h[2] * h_scale[2]
    h[3] = h[3] * h_scale[3]


    # Simulated log-likelihood function 
    # the only input argument is vector of parameters b
    # the real data, bandwidth, and other parameters defined in the outer scope are already available inside the function 

    function loglike(b)
        # Parameterize the matrices of upstream and downstream valuation
        
        bup = [
            vcat(0, b[1], b[4])';
            vcat(0., 0. , 0.)';
        ]

        bdown = [
            vcat(b[2], b[3], 0)';
            vcat(0 , 0 , b[5])';
        ]

        # The function takes as the argument an integer, 
        # solves the model finite market assignment problem using the Jonker-Volgenant algorithm, for the specific draw of unobserved random variables
        # Return matching data and prices
        # the output is of the form: 
        # up_data = (2 * n_firms) matrix of upstream types
        # down_data = (3 * n_firms) matrix of downstream types
        # price = vector of size n_firm of match prices
        # match i and its price can be accessed as up_data[1:2, i],  down_data[1:3, i], price[i]

        # sim_data_JV_up_obs(β_up, β_down , Σ_up, Σ_down, n_firms, RANDOM SEED, Real data Flag, up_data,down_data[1:2,:], κ (eq. selection), sel_mode,  β_x, β_y[8:9], σ_η, σ_ξ)

        solve_draw =  x->sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165160+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7], b[8:9], b[10],b[11])

        # Simulate n_sim fake markets using the real data for observed variables and different simulation draws of unobervables for each market
        # using parallel map, 2 markets are simulated on each worker in parallel and then the result is transferred to worker 1
        sim_dat = pmap(solve_draw, 1:n_sim, batch_size=2)

        # vector of log-likelihood of n_firms observation of matches and prices
        ll=zeros(n_firms)

        # A counter for number of simulated data points under parameter vector b that are so far-off from the real sample counterpart that the joint density's value on computer is zero 
        # When joint density is evaluated to be zero --> log-likelihood value will be -∞
        # we use this to guide the solver to a the region of parameter space such that the log-likelhood has a finite value
        n_zeros = 0;
        

        for i =1:n_firms   # for each observation

            like =0.
            for j =1:n_sim
                # Non-parametrically estimate the joint density evaluated at observation i using simulated sample of size n_sim
                # in each simulation we evaluate the joint kernel by comparing the observed data from the corresponding data point in the simulation
                like+=(
                    pdf(Normal(),((down_data[1,i] - sim_dat[j][2][1,i])/h[1]))
                    *pdf(Normal(),((down_data[2,i] - sim_dat[j][2][2,i])/h[2]))
                    *pdf(Normal(),((price_data[i] - sim_dat[j][3][i])/h[3]))
                )        
            end
            
            # if the simulated sample prediction for the observation is so far off from the observed point 
            # we use penalize the likelhood function by assuming the kernel is evaluated at point 30
            if like == 0
                ll[i] = log(pdf(Normal(),30))
                n_zeros += 1
            else
                ll[i]=log(like/(n_sim*h[1]*h[2]*h[3]))      
            end
        end

        sort!(ll)
        #drop 0.04 * n_firms of least likely observations
        drop_thres = max(2, Int(floor(0.04*n_firms)))
        
        out = mean(ll[drop_thres:end])

        # print out the output 10 percent of the time
        if mod(time(),10)<0.5
            println("OPTIMIZATION $(arrn) , parameter: ", round.(b, digits=2), " function value: ",out, " Number of zeros: ", n_zeros)
        end

        # This is required to reset the seed after the simulation, otherwise bboptim relies on the random seed and will fail to Search
        Random.seed!()
        return -out
    end
end






# Solver's setup 
opt1 = bbsetup(loglike;  
    MaxTime=globT, 
    SearchRange = bbo_search_range, 
    NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
    Method = :adaptive_de_rand_1_bin_radiuslimited, 
    TraceInterval=30.0, TraceMode=:compact,
    CallbackInterval=100
);




# Global optimization step
res_global = bboptimize(opt1)
globe_best_cand = best_candidate(res_global)
globe_best_value = best_fitness(res_global)

# Local optimization step using the best candidate from the global optimization

loc_res = Optim.optimize(loglike, globe_best_cand,time_limit=locT)
loc_best_cand = Optim.minimizer(loc_res)
loc_best_value = Optim.minimum(loc_res)




# Storing the results and the optimization struct 
# So that we can restart optimizaiton if needed
gen = "FINAL-ESTIMATION-2-smaller-search-S_200_larger_bw"; iter =  Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);

estimation_result = Dict()
push!(estimation_result, "optimizer" => opt1)
push!(estimation_result, "G" => globe_best_cand)
push!(estimation_result, "GV" => globe_best_value)
push!(estimation_result, "L" => loc_best_cand)
push!(estimation_result, "LV" => loc_best_value)
bson("/home/ak68/output/output_est_$(gen)_$(iter).bson", estimation_result)

light_res = Dict()
push!(light_res, "G" => globe_best_cand)
push!(light_res, "GV" => globe_best_value)
push!(light_res, "L" => loc_best_cand)
push!(light_res, "LV" => loc_best_value)
bson("/home/ak68/output/light_res_$(gen)_$(iter).bson", light_res)











