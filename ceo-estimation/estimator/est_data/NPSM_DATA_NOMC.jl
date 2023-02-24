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
addprocs(6)



using Plots
@everywhere begin
    using BSON, CSV
    using LinearAlgebra
    using Random
    using Distributions
    using BlackBoxOptim
    using Assignment
    using Optim
    using Evolutionary
    using DataFrames
    include("JV_DGP-LogNormal.jl")
end
@everywhere begin 
    n_rep=1; n_sim=50; h_scale=[5., 1., 1.];  par_ind= 1:7; sel_mode="median"; globT=1800; locT=60; data_mode=3;
    data = CSV.read("/Users/amir/Data/est_data.csv", DataFrame)
    data = Matrix(data)
    up_data = data[:,5]
    down_data = data[:,2:3]'


    price_data= data[:,4]

    n_firms = length(price_data)
end
scatter(up_data, down_data[1,:])
#  scatter(up_data, down_data[:,2])

scatter(down_data[:,2], price_data)


scatter(up_data[1,:], down_data[2,:])
scatter(down_data[1,:], price_data, xlims=(0,3), ylims=(50,80), markersize=1.5)
scatter(down_data[2,:], down_prof, xlims=(0,3), ylims=(-15,7), markersize=1.5)

################ Illustration #####################



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
            vcat(0, b[1], b[4])';
            vcat(0, 0, 0.)';
        ]


        bdown = [
            vcat(b[2], b[3], 0)';
            vcat(0 , 0 , b[5])';
        ]

        solve_draw =  x->sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 360+x, true, up_data,down_data[1:2,:],b[6], sel_mode, b[7:8],b[9])

        sim_dat = pmap(solve_draw, 1:n_sim)
        
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

        if mod(time(),10)<10
            # println("I'm worker number $(myid()) on thread $(Threads.threadid()), and I reside on machine $(gethostname()).")

            println(" parameter: ", round.(b, digits=4), " function value: ",out, " Number of zeros: ", n_zeros)
        end

        Random.seed!()
        return -out
    end

    function fun(x)
        par_point = copy(true_pars)
        par_point[par_ind] = x
        return loglike(par_point)
    end
end

# # # Estimated parameters: 

@everywhere begin
    bbo_population_size =50
    bbo_max_time=globT
    bbo_max_step = 30000
    bbo_ndim = length(par_ind)
    bbo_feval = 100000
    bbo_search_range =vcat(repeat([(-5.0, 5.0)], bbo_ndim+1),[(.000001, 5.)])


    cbf = x-> println("parameter: ", round.(best_candidate(x), digits=3), " n_rep: ", n_rep, " fitness: ", best_fitness(x) )
    nopts=1
    opt_mat =zeros(nopts,length(par_ind)+1)
end


bbsolution1 = bboptimize(loglike, randn(9) ; SearchRange = bbo_search_range, 
    NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
    Method = :adaptive_de_rand_1_bin_radiuslimited, 
    TraceInterval=30.0, TraceMode=:compact, MaxTime = bbo_max_time,
    CallbackInterval=100,  MaxSteps=bbo_max_step,
    CallbackFunction= cbf
) 

bc1=best_candidate(bbsolution1)

bbsolution2 = bboptimize(loglike, bc1 ; SearchRange = bbo_search_range, 
    NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
    Method = :adaptive_de_rand_1_bin_radiuslimited, 
    TraceInterval=30.0, TraceMode=:compact, MaxTime = bbo_max_time,
    CallbackInterval=100,  MaxSteps=bbo_max_step,
    CallbackFunction= cbf
) 



opt = bbsetup(loglike;  
    MaxSteps = 10,  SearchRange = bbo_search_range, 
    NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
    Method = :adaptive_de_rand_1_bin_radiuslimited, 
    TraceInterval=30.0, TraceMode=:compact, MaxTime = bbo_max_time,
    CallbackInterval=100,
);



bbo2= bboptimize(opt; MaxSteps= 2)




opt2 = bbsetup(loglike;  
    MaxSteps = 10, MaxTime=60,SearchRange = bbo_search_range, 
    NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
    Method = :adaptive_de_rand_1_bin_radiuslimited, 
    TraceInterval=30.0, TraceMode=:compact,
    CallbackInterval=100,
);
bboptimize(opt2)


opt2 = Optim.optimize(loglike, [-0.315518, -1.28821, 0.188956, -0.801082, 1.03856, 3.85097, 0.994257], time_limit=locT)
tmp = Optim.minimizer(opt2)


opt2 = Optim.optimize(loglike, bc1, time_limit=locT*10)



past_result = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/est_data/tst_optimizer.bson")






opt = past_result["optimizer"];
bboptimize(opt)

acloglike([27.6044, 7.10458, 0.738154, -2.08666, 9.06307, 20.5557, -0.484384])
# for i = 1:nopts
#     bbsolution1 = bboptimize(fun,true_pars ; SearchRange = bbo_search_range, 
#         NumDimensions =bbo_ndim, PopulationSize = bbo_population_size, 
#         Method = :adaptive_de_rand_1_bin_radiuslimited, 
#         TraceInterval=30.0, TraceMode=:compact, MaxTime = bbo_max_time,
#         CallbackInterval=100,  MaxSteps=bbo_max_step,
#         CallbackFunction= cbf) 

#     @show opt2 = Optim.optimize(fun, best_candidate(bbsolution1), time_limit=locT)
#     @show opt_mat[i,:] = vcat(Optim.minimizer(opt2), Optim.minimum(opt2))'
# end



# Alternative Optimization method using the Evolutionary Package
result = Evolutionary.optimize(
             loglike, true_pars,
             TreeGP(), Evolutionary.Options(parallelization=:thread) )
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



scatter(up_data, down_data[1,:])
scatter(up_data, price_data)
scatter(down_data[2,:], price_data)



sim_dat =  x->sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 360+x, true, up_data,down_data[1:2,:],b[6], sel_mode, b[7])

b =[-0.3104, -1.3942, 0.2047, -0.7136, 0.6599, 3.96, 1.0048] 
b = bc1
b= [0.1723, 2.1376, -0.0277, -0.8365, -0.6738, -0.1089, 3.5406, 0.4275]
b= loglike([-0.256761, -1.42568, 0.171714, -1.85544, 0.514433, -0.148743, 0.211312, 0.672027, 0.270116])
loglike([-0.610948, -1.32822, 0.377252, -4.44873, -0.432868, -1.3067, 1.04718, 0.196689, 0.301671])
bup = [
    vcat(0, b[1], b[4])';
    vcat(0, 0, 0.)';
]


bdown = [
    vcat(b[2], b[3], 0)';
    vcat(0 , 0 , b[5])';
]



sim_dat =  x->sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 360+x, true, up_data,down_data[1:2,:],b[6], sel_mode, b[7:8],b[9])
up_sim, down_sim, price_sim = sim_dat(40)
p1 = scatter(up_data, down_data[1,:]);
p2= scatter(up_sim[1,:], down_sim[1,:]);

plot(p1,p2, layout=(1,2), legend= false)

p1 = scatter(up_data, down_data[2,:]);
p2= scatter(up_sim[1,:], down_sim[2,:]);

plot(p1,p2, layout=(1,2))



p1 = scatter(down_data[1,:], price_data);
p2= scatter(down_sim[1,:], price_sim);

plot(p1,p2, layout=(1,2), xlims=(0,1), ylims=(5,15))

p1 = scatter(down_data[2,:], price_data);
p2= scatter(down_sim[2,:], price_sim);

plot(p1,p2, layout=(1,2), xlims=(8,15), ylims=(5,15))



scatter(down_data[2,:], price_data)
scatter(price_data, price_sim)

, xlims=(6,10), ylims=(6,10) )



scatter(price_data, price_sim, markersize =1 , xlims=(0,20), ylims=(0,20))

sim_dat = map(sim_dat, 1:10)




up_sim, down_sim, price_sim = sim_dat(415)


estimation_result = Dict()
push!(estimation_result, "optimizer" => opt)

push!(estimation_result, "beta" => true_pars)
bson("/Users/amir/github/ceo/ceo-estimation/estimator/est_data/tst_optimizer.bson", estimation_result)



opt


# Moments
cor(up_data,down_data[1,:])
cor(up_sim[1,:],down_sim[1,:])

cor(up_data,down_data[2,:])
cor(up_sim[1,:],down_sim[2,:])


cor(up_data, price_data)
cor(up_sim[1,:],price_sim)

cor(down_data[1,:], price_data)
cor(down_sim[1,:],price_sim)

cor(down_data[2,:], price_data)
cor(down_sim[2,:],price_sim)
