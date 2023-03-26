### Estimation of the two sided matching model in Fox, Kazempour, and Tang (2023)
### using CEO-Firm Data 
### 
### Data Sources:
### CEO compensation: EXCECUCOMP
### Segment data: COMPUSTAT HISTORICAL SEGMENTS
### Firm's fundamentals: CRSP
#### Profit estimation
###  March 19, 2023
### Amir Kazempour, amirkp@gmail.com
############################################


## uncomment for running on Rice cluster

using Distributed
addprocs()

@everywhere begin 
        
    using BSON, CSV    # BSON for storing optimization results, CSV for reading data file
    using LinearAlgebra
    using Random
    using Distributions
    using BlackBoxOptim
    using Assignment # Install the fork from https://github.com/amirkp/AssignmentDual.jl.git to have access to dual variables
    using Optim   # Local Optimization (Nelder-Mead)
    using DataFrames
    using RCall
    using KernelDensity

    using Plots
    include("JV_DGP-LogNormal.jl") # DGP for likelihood simulation
end
@everywhere begin
    #################
    ##### SETUP #####
    #################


    # loading data
    # data = CSV.read("/home/ak68/est_data_RANDOM.csv", DataFrame)
    data = CSV.read("/Users/amir/Data/est_data_RANDOM.csv", DataFrame)
    # data = CSV.read("/Users/amir/Data/est_data_1000_RANDOM.csv", DataFrame)

    data = Matrix(data)
    up_data = data[:,5]     # Ability index or x 
    down_data = data[:,2:3]'  # HHI and log(#employees) or (y_1, y_2 )
    # down_data[1,:] = rand(Beta(2,5), 500)

    price_data= data[:,4]    # Compensation variable or p 
    n_firms = length(price_data) # number of firms on ONE side of the market
    price_data=exp.(price_data)  # compensation in thousand dollars calculated from log(compensation)
    price_data=price_data./1000 # converting the compensation to million dollar unit


    ux = kde(up_data)


end


@everywhere begin 
    # up[1,:] = copy(up_data)
    # down[1:2,:] =copy(down_data)
    # pr = copy(price_data)


    function replicate(rep)

        bxy1 = -1.5;
        bxy2 = 1.5;
        bxeta = 0.;
        bepsy1 = 1.;
        bepsy2 = 0.5;
        bepseta = 0.5;
        b = [bxy1 ,bxy2 ,bxeta ,bepsy1 ,bepsy2 ,bepseta];
        bup=zeros(2,3)

        bdown = [
            vcat(b[1], b[2], b[3])';
            vcat(b[4] , b[5] , b[6])';
        ];
        repn = rep;
        n_firms=length(price_data);
        sel_mode="median"
        # repn = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);
        # up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1134 * repn, true, up_data,down_data[1:2,:], 0 , sel_mode,1.);
        up =zeros(2,n_firms)
        up[1,:] = up_data
        down = zeros(3,n_firms)
        down[1:2,:] = down_data
        pr = copy(price_data)


        function est_cdf_step(y_data, x_data,  y, x, h)
            num= 0.0
            den= 0.0
            for i =1:size(y_data)[1]
                num+= (y_data[i] < y) * pdf(Normal(0,1), (x-x_data[i])/h)
                den+= (pdf(Normal(0,1), (x-x_data[i])/h))
                # println("x is: ", x_data[i], " y is: ", y_data[i], " value is: ", (1/(h[1]*h[2])) * cdf(Normal(0,1), (y-y_data[i])/h[1])* pdf(Normal(0,1), (x-x_data[i])/h[2]))
            end
            return (num/den)
        end


        # estimate epsilon bar for each data point

        epsbar_vec = zeros(n_firms)
        for i = 1:n_firms
            # epsbar_vec[i] = est_cdf(pr, up[1,:], pr[i],up[1,i], [0.5,0.3])
            epsbar_vec[i] = est_cdf_step(pr, up[1,:], pr[i],up[1,i], .3)
        end

        


        R"library(KernSmooth)"
        function quant_bw(profit_v, char_v, alpha_quant)
            @rput profit_v char_v
            R"bandwidth_mean = dpill(char_v, profit_v)"
            @rget bandwidth_mean
            bandwidth = bandwidth_mean*((alpha_quant * (1-alpha_quant))/(pdf(Normal(0,1),quantile(Normal(0,1), alpha_quant)))^2)^(0.2)
            return bandwidth
        end


        # Check-function for check-function approach estimation of conditisnal quantiles
        function check_f(z, alpha)
            return alpha*z*(z>=0) - (1-alpha)*z*(z<0)
        end

        # defining normal kernel for ease of use
        d = Normal(0,1);
        function normal_Kernel_f(x)
            return pdf(d,x)
        end

        function objective_f(b, x, u_profit_v, u_char_v,  h, alpha)
            # b: Vector of coefficients b[1] is the constant, b[2] slope
            # x: the point at which the objective function is evaluated
            # u_profit_v: vector of upstream profits
            # u_char_v: vector of downstream profits
            # h: smoothing parameter or bandwidth
            # alpha: quantile of interest
            n = length(u_profit_v)
            obj_value = 0.0
            for i = 1:n
                obj_value += check_f(u_profit_v[i] - b[1] - b[2]*(u_char_v[i] - x), alpha) *
                normal_Kernel_f((x - u_char_v[i])/h)
            end
            return obj_value
        end



        med_vec = zeros(n_firms)
        der_vec = zeros(n_firms)

        for i = 1:n_firms
            bw = quant_bw(pr, up[1,:], epsbar_vec[i])
            obj_linear(b) = objective_f(b ,up[1,i], pr, up[1,:], bw[1], epsbar_vec[i])
            res = Optim.optimize(obj_linear, [1.0,1.0])
            med_vec[i],der_vec[i] = res.minimizer
        end


        function obj_est(b)
            tot_err=0
            for i = 1:n_firms
                if (up[1,i]>0. && up[1,i]<3.5)
                    tot_err +=(der_vec[i] -b[1] -b[2] *down[1,i] - b[3]* down[2,i])^2
                end
            end
            return tot_err
        end


        res = Optim.optimize(obj_est,[0.,0,0.])
        ests = Optim.minimizer(res)
        return ests
    end
end



































replicate(1)


est_vec = pmap(replicate, 1:100)
est_vec2 = pmap(replicate, 1:100)
mean(est_vec)
mean(est_vec2)
replicate(122)


mse1 = zeros(100,3)
for i = 1:100
    mse1[i,:]= est_vec[i] - [1., -1.5, 1.5]
end





mse2 = zeros(100,3)
for i = 1:100
    mse2[i,:]= est_vec2[i] - [1., -1.5, 1.5]
end


mean(mse1.^2, dims=1)
mean(mse1, dims=1)

mean(mse2.^2, dims=1)
mean(mse2, dims=1)


#################


x_den = kde(up_data)

function est_cdf_step(y_data, x_data,  y, x, h)
    num= 0.0
    den= 0.0
    for i =1:size(y_data)[1]
        num+= (y_data[i] < y) * pdf(Normal(0,1), (x-x_data[i])/h)
        den+= (pdf(Normal(0,1), (x-x_data[i])/h))
        # println("x is: ", x_data[i], " y is: ", y_data[i], " value is: ", (1/(h[1]*h[2])) * cdf(Normal(0,1), (y-y_data[i])/h[1])* pdf(Normal(0,1), (x-x_data[i])/h[2]))
    end
    return (num/den)
end

function cv(y_data, x_data,  y, h)
    cv=0.0
    for i = 1:n_firms
        cv += ((y_data[i] < y) - est_cdf_step(y_data[1:end .!= i], x_data[1:end .!= i],  y, x_data[i], h[1]) )^2 * pdf(x_den, x_data[i])
    end
    # println("h: ", h, " value: ", n_firms^(-1)*cv  )
    return n_firms^(-1)*cv
end

Optim.optimize(x->cv(pr, up[1,:], 2. ,x), 0.0001, 1.)




function cv_int(h)
    
    y_vec  = pr[collect(1:10:n_firms)]
    cv_vals = map(x->cv(pr, up[1,:], x ,h), y_vec)
    println("h: ", h, " value: ", sum(cv_vals)  )
    return sum(cv_vals)
end

cv_int([.3])

Optim.optimize(cv_int, 0.0001, 1.0)




# estimate the conditional cdf of y
function est_cdf(y_data, x_data,  y, x, h)
    num= 0.0
    den= 0.0
    for i =1:size(y_data)[1]
        num+= cdf(Normal(0,1), (y-y_data[i])/h[1])* pdf(Normal(0,1), (x-x_data[i])/h[2])
        den+= (pdf(Normal(0,1), (x-x_data[i])/h[2]))
        # println("x is: ", x_data[i], " y is: ", y_data[i], " value is: ", (1/(h[1]*h[2])) * cdf(Normal(0,1), (y-y_data[i])/h[1])* pdf(Normal(0,1), (x-x_data[i])/h[2]))
    end
    return (num/den)
end






#########