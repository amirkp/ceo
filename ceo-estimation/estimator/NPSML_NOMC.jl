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
addprocs(2)


using BSON
using Plots
@everywhere begin
    using LinearAlgebra
    using Random
    using Distributions
    using BlackBoxOptim
    using Assignment
    using Optim
    include("JV_DGP-LogNormal.jl")
end

# @everywhere begin 
    # n_reps =nworkers() # Number of replications (fake datasets)
true_pars = [-1.5, 2.5, 1.5, -.5, 1.5, 2,1.]

Σ_up = [0 .1;
        0 .2]


Σ_down =  [0 .3;
            0 .4;
            0 .1]

function par_gen(b)
        bup = [
            vcat(b[1], 0, b[4])';
            vcat(0, 0, 0.)';
        ]


        bdown = [
            vcat(b[2], b[3], 0)';
            vcat(0 , 0 , b[5])';
        ]

    return bup, bdown
end



bup, bdown = par_gen(true_pars)
size_fe = 1.

               
# end






n_rep=1; n_firms=300; n_sim=50; h_scale=[1., 1., 1.];  par_ind= 1:7; sel_mode="median"; globT=180; locT=60; data_mode=3;


#[β11u, β12u, β21u, β11u, β11d, β12d, β21u, β13u, β33d]

DGPsize = 1000
up_data, down_data, price_data, up_prof, down_prof =
sim_data_JV_LogNormal(bup, bdown, Σ_up, Σ_down, DGPsize
    , 38+n_rep, false, 0, 0, true_pars[6], sel_mode, size_fe+50.
)

median(down_prof)
median(up_prof)
ind_sample = sample(1:DGPsize, n_firms, replace= false);

up_data =up_data[:, ind_sample];
down_data= down_data[:, ind_sample];
price_data= price_data[ ind_sample];



scatter(up_data[1,:], down_data[1,:])
scatter(up_data[1,:], down_data[2,:])
scatter(down_data[1,:], price_data, xlims=(0,3), ylims=(50,80), markersize=1.5)
scatter(down_data[2,:], down_prof, xlims=(0,3), ylims=(-15,7), markersize=1.5)

################ Illustration #####################





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
    # println("band: ",h," val: ", val)
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
        vcat(b[1], 0, b[4])';
        vcat(0, 0, 0.)';
    ]


    bdown = [
        vcat(b[2], b[3], 0)';
        vcat(0 , 0 , b[5])';
    ]

    solve_draw =  x->sim_data_JV_up_obs(bup, bdown , Σ_up, Σ_down, n_firms, 360+x, true, up_data[1,:],b[6], sel_mode, b[7])

    sim_dat = map(solve_draw, 1:n_sim)
    
    ll=zeros(n_firms)
    n_zeros = 0
    
    for i =1:n_firms
        like =0.
        for j =1:n_sim
            if data_mode == 1 # Only prices 
                like+=(
                    pdf(Normal(),((price_data[i] - sim_dat[j][3][i])/h[3]))
                    )
            elseif data_mode==2 # Only matches
                like+=(
                    pdf(Normal(),((down_data[1,i] - sim_dat[j][2][1,i])/h[1]))
                    *pdf(Normal(),((down_data[2,i] - sim_dat[j][2][2,i])/h[2]))
                    )
            elseif  data_mode==3 # Matches and Prices
                like+=(
                    pdf(Normal(),((down_data[1,i] - sim_dat[j][2][1,i])/h[1]))
                    *pdf(Normal(),((down_data[2,i] - sim_dat[j][2][2,i])/h[2]))
                    *pdf(Normal(),((price_data[i] - sim_dat[j][3][i])/h[3]))
                    )
            end
        end
        # println("like is: ", like, " log of which is: ", log(like/(n_sim*h[1]*h[2]*h[3])))
        if like == 0
        #     # println("Like is zero!!!")
            ll[i] = log(pdf(Normal(),30))
            n_zeros += 1
        else
            if data_mode ==1 # Only prices
                ll[i]=log(like/(n_sim*h[3]))  
            elseif data_mode==2
                ll[i]=log(like/(n_sim*h[1]*h[2]))  
            elseif data_mode==3
                ll[i]=log(like/(n_sim*h[1]*h[2]*h[3]))  
            end
            # ll+=like
        end

    end

    sort!(ll)
    drop_thres = max(2, Int(floor(0.03*n_firms)))
    out = mean(ll[drop_thres:end])

    if mod(time(),10)<1
        # println("I'm worker number $(myid()) on thread $(Threads.threadid()), and I reside on machine $(gethostname()).")

        println(" parameter: ", round.(b, digits=4), " function value: ",out, " Number of zeros: ", n_zeros)
    end

    Random.seed!()
    return -out
end


# # # Estimated parameters: 



bbo_population_size =50
bbo_max_time=globT
bbo_max_step = 30000
bbo_ndim = length(par_ind)
bbo_feval = 100000
bbo_search_range =repeat([(-10.0, 10.0)], bbo_ndim)

function fun(x)
    par_point = copy(true_pars)
    par_point[par_ind] = x
    return loglike(par_point)
end

cbf = x-> println("parameter: ", round.(best_candidate(x), digits=3), " n_rep: ", n_rep, " fitness: ", best_fitness(x) )
nopts=1
opt_mat =zeros(nopts,length(par_ind)+1)


for i = 1:nopts
    bbsolution1 = bboptimize(fun,par ; SearchRange = bbo_search_range, 
        NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
        Method = :adaptive_de_rand_1_bin_radiuslimited, 
        TraceInterval=30.0, TraceMode=:compact, MaxTime = bbo_max_time,
        CallbackInterval=100,  MaxSteps=bbo_max_step,
        CallbackFunction= cbf) 

    @show opt2 = Optim.optimize(fun, best_candidate(bbsolution1), time_limit=locT)
    @show opt_mat[i,:] = vcat(Optim.minimizer(opt2), Optim.minimum(opt2))'
end


# Parameter estimates 


for n_sim =50:25:50
    for n_firms in [200]
        for data_mode=3:3:3
                est_pars = map(x->replicate_byseed(x, n_firms, n_sim,[ 1.,  1., 1.], 1:7, "median", 360, 120, data_mode), 1:n_reps)
                estimation_result = Dict()
                push!(estimation_result, "beta_hat" => est_pars)
                bson("/Users/amir/github/ceo/ceo-estimation/estimator/res1/est_$(n_firms)_sim_$(n_sim)_dmode_$(data_mode).bson", estimation_result)
        end

    end
end



