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
using LaTeXStrings

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
    # data = CSV.read("/Users/amir/Data/est_data_250_RANDOM.csv", DataFrame)
    # data = CSV.read("/Users/amir/Data/est_data_RANDOM.csv", DataFrame)
    data = CSV.read("/Users/amir/Data/est_data_1000_RANDOM.csv", DataFrame)

    data = Matrix(data)
    up_data = data[:,5]     # Ability index or x 
    down_data = data[:,2:3]'  # HHI and log(#employees) or (y_1, y_2 )
    # down_data[1,:] = rand(Beta(2,5), 500)

    price_data= data[:,4]    # Compensation variable or p 
    n_firms = length(price_data) # number of firms on ONE side of the market
    price_data=exp.(price_data)  # compensation in thousand dollars calculated from log(compensation)
    price_data=price_data./1000 # converting the compensation to million dollar unit


    ux = kde(up_data)
    n_firms=length(price_data);



    # up = copy(up_data)
    # down[1:2,:] =copy(down_data)
    # pr = copy(price_data)
end


# bxy1 = -1.5;
# bxy2 = 1.5;
# bxeta = 1.;
# bepsy1 = 0.5;
# bepsy2 = 0.5;
# bepseta = 0.5;
# b = [bxy1 ,bxy2 ,bxeta ,bepsy1 ,bepsy2 ,bepseta];
# bup=zeros(2,3)

# bdown = [
#     vcat(b[1], b[2], b[3])';
#     vcat(b[4] , b[5] , b[6])';
# ];
# repn = rep;
# sel_mode="median"
# # repn = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"]);
# up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 1134 * repn, true, up_data,down_data[1:2,:], 0 , sel_mode,0.);
# scatter(up, pr, xlims = (0,4), ylims=(-10,50))
up = copy(up_data)
down =copy(down_data)
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
    # epsbar_vec[i] = est_cdf(pr, up, pr[i],up[i], [0.5,0.07])
    epsbar_vec[i] = est_cdf_step(pr, up, pr[i],up[i], .04)
end

p1 = scatter(up, epsbar_vec, markersize=1, xlims=(0,4),legend=false,dpi=300)


R"library(KernSmooth)"


function quant_bw(profit_v, char_v, alpha_quant)
    @rput profit_v char_v alpha_quant
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
# y1_vec = zeros(n_firms)
# y2_vec = zeros(n_firms)


for i = 1:n_firms
    bw = quant_bw(pr, up, epsbar_vec[i])
    # obj_linear(b) = objective_f(b ,up[i], pr, up, bw[1]*(1.5) , epsbar_vec[i])
    obj_linear(b) = objective_f(b ,up[i], pr, up, (2.95 - 7.8*epsbar_vec[i] + 6.08*epsbar_vec[i]^2) , epsbar_vec[i])
    # obj_linear(b) = objective_f(b ,up[i], pr, up, (2.19 - 8.13*epsbar_vec[i] + 8.46*epsbar_vec[i]^2) , epsbar_vec[i])

    res = Optim.optimize(obj_linear, [1.0,1.0])
    med_vec[i],der_vec[i] = res.minimizer
end











med_vec_fq_50 = zeros(n_firms)
der_vec_fq_50 = zeros(n_firms)

med_vec_fq_25 = zeros(n_firms)
der_vec_fq_25 = zeros(n_firms)

med_vec_fq_75 = zeros(n_firms)
der_vec_fq_75 = zeros(n_firms)
#fixed quantile
for i = 1:n_firms
    bw = quant_bw(pr, up, epsbar_vec[i])
    m=1.
    if up[i]>2.
        m=1
    end



    # obj_linear(b) = objective_f(b ,up[i], pr, up, bw[1]*(1.5) , epsbar_vec[i])
    q = 0.5
    obj_linear(b) = objective_f(b ,up[i], pr, up, m*0.3 , q)
    res = Optim.optimize(obj_linear, [1.0,1.0])
    med_vec_fq_50[i],der_vec_fq_50[i] = res.minimizer

    q = 0.25
    obj_linear(b) = objective_f(b ,up[i], pr, up, m*0. , q)
    res = Optim.optimize(obj_linear, [1.0,1.0])
    med_vec_fq_25[i],der_vec_fq_25[i] = res.minimizer

    q = 0.75
    obj_linear(b) = objective_f(b ,up[i], pr, up, m*.9 , q)
    res = Optim.optimize(obj_linear, [1.0,1.0])
    med_vec_fq_75[i],der_vec_fq_75[i] = res.minimizer
end





ylab = L"\bar{\Phi}_x(Exper_i, \alpha_\varepsilon, Scope^*, Size^*)"

lab25 = L"\alpha_\varepsilon=0.25"
lab50 = L"\alpha_\varepsilon=0.50"
lab75 = L"\alpha_\varepsilon=0.75"
lab = L"\alpha_\varepsilon=\hat{\alpha}_{\varepsilon i}"

scatter(up, der_vec, markersize=1, xlims=(0,3.5), xlabel="CEO Experience", ylabel=ylab,color=:black, legend=true, label = lab, ylims=(-0.3,5), dpi=300)
# scatter(epsbar_vec, der_vec, markersize=1, xlims=(0,1), xlabel="x", ylabel=ylab, legend=false, ylims=(-2,10), dpi=300)
scatter!(up, der_vec_fq_25, markersize=2, xlims=(0,3.5),color=:red, ylabel=ylab, legend=true, ylims=(-0.3,5), dpi=300, label=lab25)
scatter!(up, der_vec_fq_50, markersize=2, xlims=(0,3.5),color=:blue, ylabel=ylab, legend=true, ylims=(-0.3,5), dpi=300, label=lab50)
scatter!(up, der_vec_fq_75, markersize=2, xlims=(0,3.5),color=:yellow, ylabel=ylab, legend=true, ylims=(-0.3,5), dpi=300,  label=lab75)

# savefig("/Users/amir/github/paper/figures/DATA-ders.png")




scatter(up, med_vec, markersize=1, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, ylims=(-2,10), dpi=300)
scatter(epsbar_vec, der_vec, markersize=1, xlims=(0,1), xlabel="x", ylabel=ylab, legend=false, ylims=(-2,10), dpi=300)


###################
function fun_fit(b)
    err = 0.
    for i =1:1000
        if up[i] <quantile(up, 0.95) && up[i]>quantile(up,0.05)
            err+= 
                (der_vec[i]- 
                 ( b[1]*up[i] + b[2]*epsbar_vec[i] +b[3]*down[1,i] +b[4]*down[2,i]
                 + b[5]*up[i]*down[1,i] + b[6]*up[i]*down[2,i] 
                 + b[7]*epsbar_vec[i]*down[1,i] + b[8]*epsbar_vec[i]*down[2,i] 
                 +b[9]*down[1,i]^2 +b[10]*down[2,i]^2
                 + b[11]*down[1,i]^3 +b[12]*down[2,i]^3))^2
        end

    end
    return err/1000
end



fun_fit(rand(12))
fun_fit(b)
res = Optim.optimize(fun_fit, rand(12))
b  = Optim.minimizer(res)
res = Optim.optimize(fun_fit, b)
b  = Optim.minimizer(res)

res = Optim.optimize(fun_fit, b)
b  = Optim.minimizer(res)


res = Optim.optimize(fun_fit, b)
b  = Optim.minimizer(res)

fit_der = zeros(n_firms)



for i = 1:1000 
    fit_der[i]=  (b[1]*up[i] + b[2]*epsbar_vec[i] +b[3]*down[1,i] +b[4]*down[2,i]
                 + b[5]*up[i]*down[1,i] + b[6]*up[i]*down[2,i]  
                 + b[7]*epsbar_vec[i]*down[1,i] + b[8]*epsbar_vec[i]*down[2,i] 
                 +b[9]*down[1,i]^2 +b[10]*down[2,i]^2+b[11]*down[1,i]^3 +b[12]*down[2,i]^3)
end


fit_der_y1 = zeros(n_firms)


for i = 1:1000 
    fit_der_y1[i]=  (b[3] + b[5]*up[i]+ b[7]*epsbar_vec[i] + 2*b[9]*down[1,i] +  3*b[11]*down[1,i]^2 )
end




fit_der_y2 = zeros(n_firms)


for i = 1:1000 
    fit_der_y2[i]=  (b[4]*down[2,i]
                 +  b[6]*up[i]  
                 + b[8]*epsbar_vec[i]
                 + 2*b[10]*down[2,i]^2+ 3*b[12]*down[2,i]^2)
end


ylab1 = L"\bar{\Phi}_{x,y_1}(Exper_i, \bar{\alpha}_{\varepsilon i}, Scope_{i}^*, Size_{i}^*)"
ylab2 = L"\bar{\Phi}_{x,y_2}(Exper_i, \bar{\alpha}_{\varepsilon i}, Scope_{i}^*, Size_{i}^*)"

xlab= "CEO Experience"
p1 = scatter(up, fit_der_y1, markersize=1, dpi=300, xlims=(0,3.5), xlabel=xlab, ylabel = ylab1, legend=false, ylims=(-3,3) )
p2 = scatter(up, fit_der_y2, markersize=1, dpi=300, xlims=(0,3.5), xlabel=xlab, ylabel = ylab2, legend=false)
plot(p1, p2, layout=(1,2))
savefig("/Users/amir/github/paper/figures/complimentarities-CEO-sample.png")




fit_der_y2_xf = zeros(n_firms)


for i = 1:1000 
    fit_der_y2_xf[i]=  (b[4]*down[2,i]
                 +  b[6]*quantile(up,0.75)
                 + b[8]*0.5
                 + 2*b[10]*down[2,i]^2+ 3*b[12]*down[2,i]^2)
end


fit_der_y1_xf = zeros(n_firms)


for i = 1:1000 
    fit_der_y1_xf[i]=  (b[3] + b[5]*quantile(up,0.75)+ b[7]*0.5 + 2*b[9]*down[1,i] +  3*b[11]*down[1,i]^2 )
end



scatter(down[1,:], fit_der_y1, markersize=1, dpi=300, xlims=(0,4.5) )
scatter!(down[1,:], fit_der_y1_xf, markersize=1, dpi=300, xlims=(0,1) )


scatter(down[2,:], fit_der_y2, markersize=1, dpi=300, xlims=(0,4.5) )
scatter!(down[2,:], fit_der_y2_xf, markersize=1, dpi=300, xlims=(0,4.5) )

fit_der_y


fun_fit(b)

scatter(up, der_vec, markersize=1, xlims=(0,4.5), dpi=300)
scatter!(up, fit_der, markersize=2, xlims=(0,4.5), color=:yellow, dpi=300)












bwx =0.3
bwe = 0.1
function np_y2_est(x,e)
    tot_weight = 0. 
    weighted_sum = 0 
    for i = 1:n_firms
        weighted_sum += pdf(Normal(), (up[i]-x)/bwx)*pdf(Normal(), (epsbar_vec[i]-e)/bwe) * down[2,i]
        tot_weight += pdf(Normal(), (up[i]-x)/bwx)*pdf(Normal(), (epsbar_vec[i]-e)/bwe) 
    end
    return weighted_sum/tot_weight

end



function np_y2_est(x,e)
    tot_weight = 0. 
    weighted_sum = 0 
    for i = 1:n_firms
        weighted_sum += pdf(Normal(), (up[i]-x)/bwx)*pdf(Normal(), (epsbar_vec[i]-e)/bwe) * down[2,i]
        tot_weight += pdf(Normal(), (up[i]-x)/bwx)*pdf(Normal(), (epsbar_vec[i]-e)/bwe) 
    end
    return weighted_sum/tot_weight

end

np_y2_est(1.5,0.5)
scatter(up, down[2,:],markersize=1, xlims=(0,3.5))
scatter(epsbar_vec, down[2,:],markersize=1, xlims=(0,3.5))
plot!(collect(0:0.05:3.5), (x->np_y2_est(x,0.8)).(collect(0:0.05:3.5)))

plot!(collect(0:0.01:1), (x->np_y2_est(2.5,x)).(collect(0:0.01:1)))
plot!(collect(0:0.05:5), (x->np_y2_est(x,0.1)).(collect(0:0.05:5)))































2.95 -7.8 +6.08
# xs = rand(Random.seed!(3232), Uniform(quantile(up, 0.05), quantile(up,.90)), n_firms)
# epss = rand(Random.seed!(32), Uniform(0.05, 0.90), n_firms)


# for i = 1:n_firms
#     bw = quant_bw(pr, up, epss[i])
#     obj_linear(b) = objective_f(b ,xs[i], pr, up, bw[1]*(1.5) , epss[i])
#     res = Optim.optimize(obj_linear, [1.0,1.0])
#     med_vec[i],der_vec[i] = res.minimizer

#     bw = quant_bw(down[1,:], up, epss[i])
#     obj_linear(b) = objective_f(b ,xs[i], down[1,:], up, bw[1] , epss[i])
#     y1_vec[i],tmp = res.minimizer

#     bw = quant_bw(down[2,:], up, epss[i])
#     obj_linear(b) = objective_f(b ,xs[i], down[2,:], up, bw[1] , epss[i])
#     y2_vec[i],tmp = res.minimizer
# end



# function obj_est(b)
#     tot_err=0
#     for i = 1:n_firms
#         if (up[i]>0. && up[i]<3.5)
#             tot_err +=(der_vec[i] - 1. -b[2] *down[1,i] - b[3]* down[2,i]-down[3,i])^2
#         end
#     end
#     return tot_err
# end


# res = Optim.optimize(obj_est,[0.,0,0.])
# ests = Optim.minimizer(res)


imse = [] 
counter = 0
minx = quantile(up,0.05)
maxx = quantile(up,0.95)
for i = 1:n_firms
    # if up[i]<maxx && up[i]>minx
        # imse +=((der_vec[i] -1. - down[3,i] -b[1] *down[1,i] - b[2]* down[2,i])^2)
        push!(imse, ((der_vec[i] -1. - down[3,i] -b[1] *down[1,i] - b[2]* down[2,i])^2))
        counter+=1
    # end

end
@show counter
# imse = imse/counter
return imse
end


@everywhere begin

    # data = CSV.read("/Users/amir/Data/est_data_250_RANDOM.csv", DataFrame)
    # data = CSV.read("/Users/amir/Data/est_data_RANDOM.csv", DataFrame)
    data = CSV.read("/Users/amir/Data/est_data_1000_RANDOM.csv", DataFrame)

    data = Matrix(data)
    up_data = data[:,5]     # Ability index or x 
    down_data = data[:,2:3]'  # HHI and log(#employees) or (y_1, y_2 )

    price_data= data[:,4]    # Compensation variable or p 
    n_firms = length(price_data) # number of firms on ONE side of the market
    price_data=exp.(price_data)  # compensation in thousand dollars calculated from log(compensation)
    price_data=price_data./1000 # converting the compensation to million dollar unit
    ux = kde(up_data)

end




# MC_250 =  pmap(replicate, 1:200)

# MC_500 =  pmap(replicate, 1:200)

# MC_1000 =  pmap(replicate, 1:200)

function MC_clean(MC)
    err = zeros(length(MC))
    count = zeros(length(MC)) 
    totw = 0.
    maxx  = quantile(up,0.99)
    for i = 1:length(MC[1])
        if up[i]<maxx
            totw += (1/pdf(ux,up[i]))
        end
    end
    @show totw

    for i = 1: length(MC)
        for j = 1:length(MC[i])
            if (MC[i][j] < quantile(MC[i], 0.95)) & (up[1,j] < maxx)
                err[i] += MC[i][j]* (1/pdf(ux,up[1,j]))
                count[i] +=1
            end
        end
    end
    return err ./ (totw)
end

MC_250_tr = MC_clean(MC_250)
mean(MC_250_tr)
median(MC_250_tr)


ctzero=0
for i = 1:n_firms
    if pdf(ux,up[i]) == 0 
        ctzero +=1
        @show i
    end

end

MC_500_tr = MC_clean(MC_500)
mean(MC_500_tr)
# median(MC_500_tr)



MC_1000_tr = MC_clean(MC_1000)
mean(MC_1000_tr)
median(MC_1000_tr)



for i = 1: length(MC_250)
    su
    MC_250[i]
end




median(MC_250[3])
mean(MC_250[3])
sum((MC_250[1].<10))
mean((MC_250[1].<1).* MC_250[1])
median(MC_250[1])

mean(MC_250)
median(MC_250)

MC_500 =pmap(replicate, 1:50)
mean(MC_500)

MC_1000 =pmap(replicate, 1:50)
mean(MC_1000)



MC_250[12][2]


[MC_250[i][2] for i =1:250]


MC_500 =  pmap(replicate, 1:50)


est_vec = pmap(replicate, 1:100)
est_vec2 = pmap(replicate, 1:100)
est_vec3 = pmap(replicate, 1:100)
mean(est_vec)
mean(est_vec2)
mean(est_vec3)
replicate(122)


mse1 = zeros(100,3)
for i = 1:100
    mse1[i,:]= est_vec[i] - [1., -1.5, 1.5]
end





mse2 = zeros(100,3)
for i = 1:100
    mse2[i,:]= est_vec2[i] - [1., -1.5, 1.5]
end


mse3 = zeros(100,3)
for i = 1:100
    mse3[i,:]= est_vec3[i] - [1., -1.5, 1.5]
end



mean(mse3.^2, dims=1)
mean(mse3, dims=1)

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

Optim.optimize(x->cv(pr, up, 2. ,x), 0.0001, 1.)




function cv_int(h)
    
    y_vec  = pr[collect(1:10:n_firms)]
    cv_vals = map(x->cv(pr, up, x ,h), y_vec)
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






# #########
# ders_truth = zeros(n_firms)
# for i = 1:n_firms
#     ders_truth[i] = 1. + b[3]*down[3,i] +b[1] *down[1,i] + b[2]* down[2,i]
# end
# ###########






function krs(x,eps,hx, he)
    tw = 0. 
    val = 0.0 
    for i = 1:n_firms
        tw += pdf(Normal(), (x-up[i])/hx) * pdf(Normal(), (eps-epsbar_vec[i])/he)
        val += der_vec[i]*pdf(Normal(), (x-up[i])/hx) * pdf(Normal(), (eps-epsbar_vec[i])/he)
    end
    return val/tw
end



krs(2.5, 0.8, 0.5, 0.05)

plot(x->krs(2.5,x, 0.5, 0.05), 0, 1)
plot(x->krs(x,0.5, 0.5, 0.05), 0, 3.5)















scatter(up,down_data[1,:], der_vec, markersize=1, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, dpi=300)


contour(up,epsbar_vec, der_vec, fill=true)

using Plots; pythonplot()

using PythonPlot

contour(up,epsbar_vec, der_vec, levels=1)





scatter(xs, der_vec, markersize=2, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, ylims=(-10,10), dpi=300)
scatter(xs, y2_vec, markersize=2, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, dpi=300)
scatter(up, down[1,:], markersize=2, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, dpi=300)



R"library(locpol)"
R"library(pspline)"

@rput up_data;
@rput down_data;
@rput price_data;
R"up_ders = looLocPolSmootherC(up_data, price_data, 1., 1, EpaK)";
R"y1_ = looLocPolSmootherC(up_data, down_data[1,], 1., 1, EpaK)";
R"y2_ = looLocPolSmootherC(up_data, down_data[2,], 1., 1, EpaK)";



function npreg(x, eps, y)

end















# savefig("/Users/amir/github/ceo/Notes and Reports/figs20230322/derivatives_data.png")

ylab = L"\bar{\varepsilon}_i"
scatter(up, epsbar_vec,  xlims=(0,4), ylims=(0,1), markersize= 1,legend=false, xlabel="x", ylabel=ylab)


scatter(up, down[1,:],  xlims=(0,4), markersize= 1,legend=false, xlabel="x", ylabel=ylab)
scatter(up, down[2,:],  xlims=(0,4), markersize= 1,legend=false, xlabel="x", ylabel=ylab)



bwx =0.3
bwe = 0.1
function np_y2_est(x,e)
    tot_weight = 0. 
    weighted_sum = 0 
    for i = 1:n_firms
        weighted_sum += pdf(Normal(), (up[i]-x)/bwx)*pdf(Normal(), (epsbar_vec[i]-e)/bwe) * down[2,i]
        tot_weight += pdf(Normal(), (up[i]-x)/bwx)*pdf(Normal(), (epsbar_vec[i]-e)/bwe) 
    end
    return weighted_sum/tot_weight

end

np_y2_est(3,0.9)

plot!(collect(0:0.05:6), (x->np_y2_est(x,0.8)).(collect(0:0.05:6)))

plot(collect(0:0.01:1), (x->np_y2_est(2.5,x)).(collect(0:0.01:1)))
scatter(up, down[2,:],markersize=1)
plot!(collect(0:0.05:5), (x->np_y2_est(x,0.1)).(collect(0:0.05:5)))





med_vec1 = zeros(n_firms)
der_vec1 = zeros(n_firms)
bw = quant_bw(pr, up, 0.8)
for i = 1:n_firms
    # bw = quant_bw(pr, up, 0.8)
    obj_linear(b) = objective_f(b ,up[i], pr, up, bw[1], 0.8)
    res = Optim.optimize(obj_linear, [1.0,1.0])
    med_vec1[i],der_vec1[i] = res.minimizer
end

scatter!(up, der_vec1, markersize=2, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, dpi=300, color=:orange, ylims=(-5,10))



med_vec2 = zeros(n_firms)
der_vec2 = zeros(n_firms)
bw = quant_bw(pr, up, 0.4)
for i = 1:n_firms
    # bw = quant_bw(pr, up, 0.8)
    obj_linear(b) = objective_f(b ,up[i], pr, up, bw[1], 0.4)
    res = Optim.optimize(obj_linear, [1.0,1.0])
    med_vec2[i],der_vec2[i] = res.minimizer
end

scatter!(up, der_vec2, markersize=2, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, dpi=300, color=:red, ylims=(-5,10))
# savefig("/Users/amir/github/ceo/Notes and Reports/figs20230322/derivatives_data_fixedeps.png")





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



i = 10
obj_linear(b) = objective_cube_f(b ,up[i], pr, up, bw[1], epsbar_vec[i])
res = Optim.optimize(obj_linear, [1.0,1.0,1.,1.])
obj_linear(b) = objective_f(b ,up[i], pr, up, bw[1], epsbar_vec[i])
res = Optim.optimize(obj_linear, [1.0,1.0,1.,1.])
Optim.minimizer(res)

function quant_bw(profit_v, char_v, alpha_quant, minx, maxx)
    function CV(h)
        obj = 0. 

        for i =1:5:n_firms 
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

    res_h = Optim.optimize(CV, 0.001, 3., iterations=25)
    return Optim.minimizer(res_h)
end


quant_bw(pr, up,0.2,0.05,3.)