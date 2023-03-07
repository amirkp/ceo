### Estimation of the two sided matching model in Fox, Kazempour, and Tang (2023)
### using CEO-Firm Data 
### 
### Data Sources:
### CEO compensation: EXCECUCOMP
### Segment data: COMPUSTAT HISTORICAL SEGMENTS
### Firm's fundamentals: CRSP

### Version 1, Feb 15, 2023 
### Amir Kazempour, amirkp@gmail.com

## uncomment for running on Rice cluster
# using Distributed, ClusterManagers 
# pids = addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"]))

## comment the following when running on Rice Cluster
using Distributed

addprocs(8)

@everywhere begin
    using BSON, CSV
    using LinearAlgebra
    using Random
    using Distributions
    using BlackBoxOptim
    using Assignment
    using Optim
    using DataFrames
    include("JV_DGP-LogNormal.jl")
end


# @everywhere begin 
##### SETUP #####

# number of simulations for each likelihood evaluation
# use the same as the number of processors available
@everywhere begin
    n_sim=nworkers()

    # scaling the bcv2 bandwidths 
    h_scale=[1., 1., 1.];  par_ind= 1:9;

    #equilibrium selection rule for downstream firms
    sel_mode="median"; 

    # Optimization parameters
    globT=3*3600; locT=1800; data_mode=3;

    bbo_population_size =100
    bbo_max_time=globT; bbo_ndim = 9;
    bbo_search_range =vcat(repeat([(-5.0, 5.0)],5),[(.000001, 5.)],[(-5.0, 5.0)],[(-5.0, 5.0)], [(.01, 5.)])
    cbf = x-> println("parameter: ", round.(best_candidate(x), digits=3), " fitness: ", best_fitness(x) )

    # loading data
    # data = CSV.read("/home/ak68/est_data.csv", DataFrame)
    data = CSV.read("/Users/amir/github/ceo/ceo-estimation/estimator/est_data_NOTS/est_data.csv", DataFrame)
    data = Matrix(data)
    up_data = data[:,5]
    down_data = data[:,2:3]'
    price_data= data[:,4]
    n_firms = length(price_data)

end
# Partitioning the pool of available cores 
# @everywhere pool_a =  WorkerPool(collect(2:n_sim+1))
# @everywhere pool_b =  WorkerPool(collect(n_sim+2:nworkers()+1))



@everywhere begin 
    function bcv2_fun(h, down_data, price_data)
        h=abs.(h)
        ll = 0.0
        n_firms = length(price_data)
        for i = 1:n_firms
            for j=1:n_firms
                if (j!=i)
                    expr_1 = ((down_data[1,i]-down_data[1,j])/h[1])^2 + ((down_data[2,i]-down_data[2,j])/h[2])^2 + ((price_data[i]-price_data[j])/h[3])^2
                    expr_2 = pdf(Normal(),(down_data[1,i]-down_data[1,j])/h[1]) * pdf(Normal(),((down_data[2,i]-down_data[2,j])/h[2])) * pdf(Normal(),((price_data[i]-price_data[j])/h[3]))
                    ll += (expr_1 - (2*3 +4)*expr_1 + (3^2 +2*3))*expr_2
                end
            end
        end
        val = ((sqrt(2*pi))^3 * n_firms *h[1]*h[2]*h[3])^(-1) +
                                ((4*n_firms*(n_firms-1))*h[1]*h[2]*h[3])^(-1) * ll
        return val
    end

    # # only use a sample of size of the nsims not the total observed sample 
    # inds = rand(1:n_firms, n_sim)
    inds = 1:n_firms;

    # # Optimize over choice of h
    res_bcv = Optim.optimize(x->bcv2_fun(x,down_data[1:2,inds],price_data[inds]), [0.1,.1,1.11]);


    @show h = abs.(Optim.minimizer(res_bcv))

    if sum(h .> 10) >0 
        h=[0.04, 0.06, 0.2]
        println("BAD BANDWIDTH")

    end
    h[1] = h[1] * h_scale[1]
    h[2] = h[2] * h_scale[2]
    h[3] = h[3] * h_scale[3]


    function loglike(b)
        bup = [
            vcat(0, b[1], b[4])';
            vcat(0, 0, 0.)';
        ]

        bdown = [
            vcat(b[2], b[3], 0)';
            vcat(0 , 0 , b[5])';
        ]

        solve_draw =  x->sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165160+x, true, up_data,down_data[1:2,:],b[6], sel_mode, b[7:8],b[9])
        sim_dat = pmap(solve_draw, 1:n_sim)
        ll=zeros(n_firms)
        n_zeros = 0
        
        for i =1:n_firms
            like =0.
            for j =1:n_sim
                like+=(
                    pdf(Normal(),((down_data[1,i] - sim_dat[j][2][1,i])/h[1]))
                    *pdf(Normal(),((down_data[2,i] - sim_dat[j][2][2,i])/h[2]))
                    *pdf(Normal(),((price_data[i] - sim_dat[j][3][i])/h[3]))
                )            
            end
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
        if mod(time(),10)<2
            println("worker number $(myid()) parameter: ", round.(b, digits=4), " function value: ",out, " Number of zeros: ", n_zeros)
        end
        Random.seed!()
        return -out
    end
end














######################## GENERATE DATA FOR ALL CASES ##############


b=rand(9)*4

bup = [
    vcat(0, b[1], b[4])';
    vcat(0, 0, 0.)';
]

bdown = [
    vcat(b[2], b[3], 0)';
    vcat(0 , 0 , b[5])';
]

b[7] =0
b[8]= 0
up, down, pr, uprof, dprof = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1234, true, up_data,down_data[1:2,:],b[6], sel_mode, b[7:8],b[9],2.)


using Plots

scatter(up[1,:], down[1,:])

scatter(up[1,:], pr)


##### Showing that 
#####  two linear terms in y
#####  one or more linear term in y and eq selection rule are not identified. 
function pdist(pars)
    up1, down1, pr1, uprof1, dprof1 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1234, true, up_data,down_data[1:2,:],pars[2], sel_mode, vcat(b[7],pars[1]),b[9]);
    return sum((pr-pr1).^2)
end


spoints = rand(10,2)*4
opt = Optim.optimize(pdist, spoints[2,:], show_trace=true);
[b[6] b[8]] - Optim.minimizer(opt)'

spoints = rand(10,3)*4

opt = Optim.optimize(pdist, spoints[3,:], show_trace=false);


[b[6] b[7] b[8]] - Optim.minimizer(opt)'

Optim.minimum(opt)










################################
function pdist(pars)
        bup = [
        vcat(pars[6], pars[1], pars[4])';
        vcat(0, 0, 0.)';
    ]

    bdown = [
        vcat(pars[2], pars[3], 0)';
        vcat(0 , 0 , pars[5])';
    ]
    up1, down1, pr1, uprof1, dprof1 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1234, true, up_data,down_data[1:2,:],b[6], sel_mode, b[7:8],b[9],2.);
    return sum((pr-pr1).^2)
end


spoints = rand(10,2)*4
opt = Optim.optimize(pdist, spoints[3,:], show_trace=true);
[2. b[6]] - Optim.minimizer(opt)'

spoints = rand(10,4)*4

opt = Optim.optimize(pdist, vcat(b[1:5],0.) +rand(6), show_trace=true);
opt = Optim.optimize(pdist, Optim.minimizer(opt), show_trace=true);

b[1] b[2] b[3] b[4] b[5]] - Optim.minimizer(opt)'



Optim.minimum(opt)

















############## Most ambitious identification
############ DO the DGP again 



b=rand(1:100, 9)*0.01
rand(9)
bup= [
    vcat(b[1], b[2], b[5])';
    vcat(0, 0, 0.)';
]

bdown = [
vcat(b[3], b[4], 0)';
vcat(0 , 0 , b[6])';
]

up, down, pr, uprof, dprof = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1234, true, up_data,down_data[1:2,:],b[7], sel_mode, [0., 0.],b[8],b[9])




scatter(up[1,:], down[1,:])

scatter(down[1,:], pr)



################################
function pdist(pars)
    bup = [
        vcat(pars[1], pars[2], pars[5])';
        vcat(0, 0, 0.)';
    ]

    bdown = [
        vcat(pars[3], pars[4], 0)';
        vcat(0 , 0 , pars[6])';
    ]

    up1, down1, pr1, uprof1, dprof1 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1234, true, up_data,down_data[1:2,:],pars[7], sel_mode, [0.,0.],pars[8],pars[9]);
    
    return sum((pr-pr1).^2 )+ sum(down_data[1:2,:] - down1[1:2,:]).^2
end
sum((rand(3,3) - rand(3,3)).^2)


st_point = b+rand(Random.seed!(),9)*0.1
pdist(st_point)



opt = Optim.optimize(pdist, st_point, show_trace=true);



b - Optim.minimizer(opt)
opt = Optim.optimize(pdist, Optim.minimizer(opt), show_trace=true);

spoints = rand(10,4)*4

opt = Optim.optimize(pdist, vcat(b[1:5],0.) +rand(6), show_trace=true);
opt = Optim.optimize(pdist, Optim.minimizer(opt), show_trace=true);

b[1] b[2] b[3] b[4] b[5]] - Optim.minimizer(opt)'



Optim.minimum(opt)













loglike(b)
# opt_mat =zeros(nopts,length(par_ind)+1)

opt1 = bbsetup(loglike;  
    MaxTime=globT ,SearchRange = bbo_search_range, 
    NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
    Method = :adaptive_de_rand_1_bin_radiuslimited, 
    TraceInterval=30.0, TraceMode=:compact,
    CallbackInterval=100
);

res_global = bboptimize(opt1)

globe_best_cand = best_candidate(res_global)
globe_best_value = best_fitness(res_global)


loc_res = Optim.optimize(loglike, globe_best_cand,time_limit=locT)

loc_best_cand = Optim.minimizer(loc_res)
loc_best_value = Optim.minimum(loc_res)


gen = 1; iter = 1;

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














