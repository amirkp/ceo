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

using Distributed, ClusterManagers 
pids = addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"]))



## comment the following when running on Rice Cluster
# using Distributed
# addprocs(8)

@everywhere begin
    using BSON, CSV    # BSON for storing optimization results, CSV for reading data file
    using LinearAlgebra
    using Random
    using Distributions
    using BlackBoxOptim
    using Assignment # Install the fork from https://github.com/amirkp/AssignmentDual.jl.git to have access to dual variables
    using Optim   # Local Optimization (Nelder-Mead)
    using DataFrames
    include("JV_DGP-LogNormal.jl") # DGP for likelihood simulation
end

#################
##### SETUP #####
#################

@everywhere begin
    # Given the market size of 500, I find one core per 2 simulation would be more efficient 
    # Simulation is done in batches of size 2 on each core
    
    n_sim=nworkers()*2
    
    ################################################
    ################################################

    # Scaling the bcv2 bandwidths for non-parametric estimation of the joint density of outcome (y_1, y_2, p)
    # h[1], h[2], h[3] would scale the bandwidths for y_1, y_2, and p respectively
    # [1., 1., 1.] is using the bcv2 bandwidths
    
    h_scale=[1., 1., 1.];  
    
    ################################################
    ################################################
    
    # Equilibrium selection rule
    # sel_mode="median", the model parameter for equilibrium selection rule is the median downstream (firm) profit
    # sel_mode="mean", the model parameter for equilibrium selection rule is the mean downstream (firm) profit
    # sel_mode="min", the model parameter for equilibrium selection rule is the minimum downstream (firm) profit

    sel_mode="median"; 

    # Optimization parameters
    

    ################################################
    ################################################

    # Time in seconds for the global optimizer (bboptim, DE solver)
    globT=3*3600; 
    
    # Time in seconds for the local optimizer (optim, Nelder-Mead)
    locT=1800;
    
    # Using only the matching data (1), price data (2), or matching and price data together (3) 
    data_mode=3;

    # Population size for the differential evolution solver
    # Rule-of-thumb: 10 * n_dimensions
    bbo_population_size =100;
    
    bbo_max_time=globT; 
    
    # Dimension of the parameter space
    bbo_ndim = 11;
    # bounds for the parameter space, each dimension

    # bbo_search_range =vcat(repeat([(-20.0, 20.0)],9),[(0.01, 10)], [(.01, 10.)])
    bbo_search_range =[(-1.,0), (0,2 ), (0,2) ,(0,3), (0,2), (4,6), (3,5), (-3,3), (-1,2), (1,3),(4,6)]

    # callback function 
    cbf = x-> println("parameter: ", round.(best_candidate(x), digits=3), " fitness: ", best_fitness(x) )

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
end

# Partitioning the pool of available cores
# Only needed for running multiple optimizations using one slurm file on NOTS
# @everywhere pool_a =  WorkerPool(collect(2:n_sim+1))
# @everywhere pool_b =  WorkerPool(collect(n_sim+2:nworkers()+1))




# Use the array environment variable from NOTS task manager to name output
arrn =  Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"])



# Bandwidth Selection  bcv2
# Sain, Stephan R., Keith A. Baggerly, and David W. Scott. 
# “Cross-Validation of Multivariate Densities.” Journal of the American Statistical Association 89, no. 427 (1994)

# Loss function to be minimized 
@everywhere begin 
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
gen = "FINAL-ESTIMATION-2-smaller-search-S_200"; iter =  Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);

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












