#estimating the bandwidths



using Distributed, ClusterManagers 
pids = addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"]))

@everywhere begin 
    using BSON, CSV    # BSON for storing optimization results, CSV for reading data file
    using LinearAlgebra
    using Random
    using Distributions
    using Optim   # Local Optimization (Nelder-Mead)
    using DataFrames
end

@everywhere begin
    #################
    ##### SETUP #####
    #################


    #loading data
    # data = CSV.read("/home/ak68/est_data_250_RANDOM.csv", DataFrame)
    # data = CSV.read("/home/ak68/est_data_RANDOM.csv", DataFrame)
    data = CSV.read("/home/ak68/est_data_1000_RANDOM.csv", DataFrame)

    data = Matrix(data)
    up_data = data[:,5]     # Ability index or x 
    down_data = data[:,2:3]'  # HHI and log(#employees) or (y_1, y_2 )
    # down_data[1,:] = rand(Beta(2,5), 500)

    price_data= data[:,4]    # Compensation variable or p 
    n_firms = length(price_data) # number of firms on ONE side of the market
    price_data=exp.(price_data)  # compensation in thousand dollars calculated from log(compensation)
    price_data=price_data./1000 # converting the compensation to million dollar unit
end

@everywhere begin

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




    function objective_cube_f(b, x, u_profit_v, u_char_v,  h, alpha)
        # b: Vector of coefficients b[1] is the constant, b[2] slope
        # x: the point at which the objective function is evaluated
        # u_profit_v: vector of upstream profits
        # u_char_v: vector of downstream profits
        # h: smoothing parameter or bandwidth
        # alpha: quantile of interest
        n = length(u_profit_v)
        obj_value = 0.0
        for i = 1:n
            obj_value += check_f(u_profit_v[i] - b[1] - b[2]*(u_char_v[i] - x)-  b[3]*(u_char_v[i] - x)^2- b[4]*(u_char_v[i] - x)^3, alpha) *
            normal_Kernel_f((x - u_char_v[i])/h)
        end
        return obj_value
    end





    function quant_bw(profit_v, char_v, alpha_quant, minx, maxx)
        function CV(h)
            obj = 0. 

            for i =1:n_firms 
                if char_v[i]>minx && char_v[i]<maxx
                    obj_linear(b) = objective_f(b ,char_v[i], profit_v, char_v, h, alpha_quant)
                    obj_cube(b) = objective_cube_f(b ,char_v[i], profit_v, char_v, h, alpha_quant)
                    res_ll = Optim.optimize(obj_linear, [1.,1.,1.])
                    res_cu = Optim.optimize(obj_cube, [1.,1.,1.,1.])
                    obj += (Optim.minimizer(res_ll)[2]- Optim.minimizer(res_cu)[2])^2 
                end 
            
            end
            println("h: ", h, " obj: ", obj)
            return obj 
        end

        res_h = Optim.optimize(CV, 0.001, 4.)
        return vcat(alpha_quant, Optim.minimizer(res_h), Optim.minimum(res_h))
    end
end

q_fun = x-> quant_bw(price_data, up_data, x, quantile(up_data, 0.05), quantile(up_data, 0.95))

bws_res = pmap(q_fun, collect(0.01:0.01:0.99))
res = Dict()
push!(res, "bw" => bws_res)
bson("/home/ak68/output_bw/bw_res_$(n_firms)_2.bson", res)
