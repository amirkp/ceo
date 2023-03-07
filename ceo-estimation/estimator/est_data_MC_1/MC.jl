### Estimation of the two sided matching model in Fox, Kazempour, and Tang (2023)
### using CEO-Firm Data 
### 
### Data Sources:
### CEO compensation: EXCECUCOMP
### Segment data: COMPUSTAT HISTORICAL SEGMENTS
### Firm's fundamentals: CRSP

### Version 2, March 3, 2023
### Amir Kazempour, amirkp@gmail.com

############################################
###########################################
#### MC using the real data
########################################


## uncomment for running on Rice cluster

using Distributed, ClusterManagers 
pids = addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"]))

## comment the following when running on Rice Cluster
# using Distributed

# addprocs(8)

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
    # n_sim=nworkers()
    n_sim =50
    # scaling the bcv2 bandwidths 
    h_scale=[1., 1., 1.];  par_ind= 1:7;

    #equilibrium selection rule for downstream firms
    sel_mode="median"; 

    # Optimization parameters
    globT=1.5*3600; locT=1800/2; data_mode=3;
    # globT=30; locT=10; data_mode=3;

    bbo_population_size =100
    bbo_max_time=globT; bbo_ndim = 9;
    bbo_search_range =vcat(repeat([(-10.0, 10.0)],8), [(.01, 5.)])
    cbf = x-> println("parameter: ", round.(best_candidate(x), digits=3), " fitness: ", best_fitness(x) )

    # loading data
    # data = CSV.read("/home/ak68/est_data.csv", DataFrame)
    data = CSV.read("/Users/amir/Data/est_data.csv", DataFrame)
    data = Matrix(data)
    up_data = data[:,5]
    down_data = data[:,2:3]'
    price_data= data[:,4]
    n_firms = length(price_data)

end



############################# FAKE DATA ####################
@everywhere begin 

    b = [-4.5 ,0.5 ,2.5 ,-.2 ,-5 ,1.7 ,0 ,4.3, .4]
    bup = [
        vcat(b[1], b[2], b[5])';
        vcat(0, 0., 0.)';
    ]

    bdown = [
        vcat(b[3], b[4], 0)';
        vcat(0 , 0 , b[6])';
    ]
    repn = 1

    # repn = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);
    up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1134 * repn, true, up_data,down_data[1:2,:], b[7], sel_mode ,b[8],b[9])



    up_data = up[1,:]
    down_data = down[1:2,:]
    price_data = pr[:]
end
# repn = 21







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
            vcat(b[1], b[2], b[5])';
            vcat(0, 0., 0.)';
        ]
        
        bdown = [
            vcat(b[3], b[4], 0)';
            vcat(0 , 0 , b[6])';
        ]

        solve_draw =  x->sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165160+x, true, up_data,down_data[1:2,:],b[7], sel_mode,  b[8], b[9])
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
        if mod(time(),10)<10
            println("worker number $(myid()) parameter: ", round.(b, digits=4), " function value: ",out, " Number of zeros: ", n_zeros)
        end
        Random.seed!()
        return -out
    end
end





function score_k(b,  tol)
    bup = [
        vcat(b[1], b[2], b[5])';
        vcat(0, 0., 0.)';
    ]
    
    bdown = [
        vcat(b[3], b[4], 0)';
        vcat(0 , 0 , b[6])';
    ]

    solve_draw =  x->sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165160+x, true, up_data,down_data[1:2,:],b[7], sel_mode,  b[8], b[9])
    sim_dat = pmap(solve_draw, 1:n_sim)

 

    ll=zeros(n_firms)
    ll_k=zeros(n_firms)
    n_zeros = 0
    Sfirms = zeros(n_firms, 9 )

    for k =1:9
        c= copy(b)
        c[k] =c[k]+tol
        
        bup = [
            vcat(c[1], c[2], c[5])';
            vcat(0, 0., 0.)';
        ]
        
        bdown = [
            vcat(c[3], c[4], 0)';
            vcat(0 , 0 , c[6])';
        ]

        solve_draw =  x->sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165160+x, true, up_data,down_data[1:2,:],c[7], sel_mode,  c[8], c[9])
        sim_dat_k = pmap(solve_draw, 1:500)


        for i =1:n_firms
            like =0.
            like_k =0.
            for j =1:n_sim
                like+=(
                    pdf(Normal(),((down_data[1,i] - sim_dat[j][2][1,i])/h[1]))
                    *pdf(Normal(),((down_data[2,i] - sim_dat[j][2][2,i])/h[2]))
                    *pdf(Normal(),((price_data[i] - sim_dat[j][3][i])/h[3]))
                )      
                like_k+=(
                    pdf(Normal(),((down_data[1,i] - sim_dat_k[j][2][1,i])/h[1]))
                    *pdf(Normal(),((down_data[2,i] - sim_dat_k[j][2][2,i])/h[2]))
                    *pdf(Normal(),((price_data[i] - sim_dat_k[j][3][i])/h[3]))
                )            
            end
            if like == 0
                ll[i] = log(pdf(Normal(),30))
                n_zeros += 1
            else
                Sfirms[i,k ] =  (log(like_k/(n_sim*h[1]*h[2]*h[3])) - log(like/(n_sim*h[1]*h[2]*h[3])))/tol
            end
        end
        println("k: ",k)
    end    
    Souter= zeros(9,9)
    for i =1:n_firms
        Souter += Sfirms[i,:]*Sfirms[i,:]'
    end

    # if mod(time(),10)<10
    #     println("worker number $(myid()) parameter: ", round.(b, digits=4), " function value: ",mean(der), " Number of zeros: ", n_zeros)
    # end
    # Random.seed!()
    return Souter/n_firms
end




mat = score_k(b,0.2)
invmat =inv(mat)
sqrt.(diag(invmat))
sqrt.(diag(mat))


0.005/0.01

loglike(res[1,:])

# opt_mat =zeros(nopts,length(par_ind)+1)

opt1 = bbsetup(loglike;  
    MaxTime=globT ,SearchRange = bbo_search_range, 
    NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
    Method = :adaptive_de_rand_1_bin_radiuslimited, 
    TraceInterval=30.0, TraceMode=:compact,
    CallbackInterval=100
);




res_global = bboptimize(opt1, b )

globe_best_cand = best_candidate(res_global)
globe_best_value = best_fitness(res_global)


loc_res = Optim.optimize(loglike, globe_best_cand,time_limit=locT)

loc_best_cand = Optim.minimizer(loc_res)
loc_best_value = Optim.minimum(loc_res)



gen = "MC-9par"; iter =  Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);

estimation_result = Dict()
push!(estimation_result, "optimizer" => opt1)
push!(estimation_result, "G" => globe_best_cand)
push!(estimation_result, "GV" => globe_best_value)
push!(estimation_result, "L" => loc_best_cand)
push!(estimation_result, "LV" => loc_best_value)
bson("/home/ak68/outMC/output_est_$(gen)_$(iter).bson", estimation_result)

light_res = Dict()
push!(light_res, "G" => globe_best_cand)
push!(light_res, "GV" => globe_best_value)
push!(light_res, "L" => loc_best_cand)
push!(light_res, "LV" => loc_best_value)
bson("/home/ak68/outMC/light_res_$(gen)_$(iter).bson", light_res)
















b = [-4.5 ,0.5 ,2.5 ,-.1 ,-5 ,1.7 ,0 ,4.3, .4]
bup = [
    vcat(b[1], b[2], b[5])';
    vcat(0, 0., 0.)';
]

bdown = [
    vcat(b[3], b[4], 0)';
    vcat(0 , 0 , b[6])';
]
repn = 1

# repn = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);
up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1134 * repn, true, up_data,down_data[1:2,:], b[7], sel_mode ,b[8],b[9])



up_data2 = up[1,:]
down_data2 = down[1:2,:]
price_data2 = pr[:]



up_data = up[1,:]
down_data = down[1:2,:]
price_data = pr[:]


sum(up_data- up_data2)
sum(down_data-down_data2)
sum(price_data-price_data2)



function tstder(par)

    b = [-4.5 ,0.5 ,2.5 ,-.1 ,-5 ,1.7 ,0 ,4.3, .4]
    bup = [
        vcat(b[1], b[2], b[5])';
        vcat(0, 0., 0.)';
    ]

    bdown = [
        vcat(b[3], b[4], 0)';
        vcat(0 , 0 , b[6])';
    ]
    repn = 1

    # repn = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);
    up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1134 * repn, true, up_data,down_data[1:2,:], b[7], sel_mode ,b[8],b[9])

    up_data1 = up[1,:]
    down_data1 = down[1:2,:]
    price_data1 = pr[:]


    b = [-4.5+par ,0.5 ,2.5 ,-.1 ,-5 ,1.7 ,0 ,4.3, .4]
    bup = [
        vcat(b[1], b[2], b[5])';
        vcat(0, 0., 0.)';
    ]

    bdown = [
        vcat(b[3], b[4], 0)';
        vcat(0 , 0 , b[6])';
    ]
    repn = 1

    # repn = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);
    up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1134 * repn, true, up_data,down_data[1:2,:], b[7], sel_mode ,b[8],b[9])

    up_data2 = up[1,:]
    down_data2 = down[1:2,:]
    price_data2 = pr[:]
    errm = mean((down_data2-down_data1).^2)
    errp  = mean((price_data2 - price_data1).^2)
    println("dev is ", par,  " mean match error is: ", errm , " mean price err is: ", errp ) 

    return errm+errp

end


tstder(0.02)

grid = collect(-.5:0.01: .5)
lvals = [tstder(grid[i]) for i =1:length(grid)]

central_fdm(5, 1; factor=1e10)(tstder, .15)


extrapolate_fdm(central_fdm(5, 1; factor =1e10), tstder, .15)

central_fdm(5, 1; factor=1e16)(tstder, 1)


central_fdm(5, 1; factor =1e12)
tol =0.02
(tstder(tol)-tstder(0))/tol 

scatter(grid, lvals, markersize = 1)

+ mean((price_data2 - price_data1).^2)