### using estimated parameters to generate data and compare the patterns visually 
# need to load all packages and functions from estimate.jl first. 

using Plots
#test if Plots is loaded correctly, in case of broke package refer to notes
scatter(randn(10))
# @everywhere begin 
##### SETUP #####

b= res[5, 1:12];

println(round.(b, digits=1))
bup = [
    vcat(0, b[1], b[4])';
    vcat(0, 0. , 0.)';
]

bdown = [
    vcat(b[2], b[3], 0)';
    vcat(0 , 0 , b[5])';
]


x= 220;


medx = median(up_data)
medy2 = median(down_data[2,:])


# First counterfactual
up_data_c1 = copy(up_data)
up_data_c1 .= medx
down_data_c1 = copy(down_data)

# Second counterfactual 
# All scope = 0 
up_data_c2 = copy(up_data)
down_data_c2 = copy(down_data)
down_data_c2[1,:] .= 0

# Thirds counterfactual 
# All size = median 
up_data_c3 = copy(up_data)
down_data_c3 = copy(down_data)
down_data_c3[2,:] .= medy2

# down_data_c[1,:] .= 0.
up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
upc1, downc1, prc1 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data_c1,down_data_c1[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
upc2, downc2, prc2 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data_c2,down_data_c2[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
upc3, downc3, prc3 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data_c3,down_data_c3[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);




using DataFrames
df = DataFrame(exper = up_data, scope= down_data[1,:], size = down_data[2,:], comp = price_data, scenario=repeat(["Data"], 500))
dfc1 = DataFrame(exper = upc1[1,:], scope= downc1[1,:], size = downc1[2,:], comp = prc1, scenario=repeat(["CF: Median Exper."], 500))
dfc2 = DataFrame(exper = upc2[1,:], scope= downc2[1,:], size = downc2[2,:], comp = prc2, scenario=repeat(["CF: Scope=0"], 500))
dfc3 = DataFrame(exper = upc3[1,:], scope= downc3[1,:], size = downc3[2,:], comp = prc3, scenario=repeat(["CF: Median Size "], 500))


alldf = vcat(df, dfc1,dfc2, dfc3)
@df alldf boxplot(string.(:scenario), :comp, fillalpha=0.5, linewidth=02, outliers=false, legend=false, title="CEO Compensation: Data and Counterfactuals")
savefig("/Users/amir/github/paper/figures/boxplot-cf.png")






median(price_data)
median(prc1)
median(prc2)
median(prc3)


quantile(price_data, 0.25)
quantile(prc1, 0.25)
quantile(prc2, 0.25)
quantile(prc3, 0.25)

quantile(price_data, 0.75)
quantile(prc1, 0.75)
quantile(prc2, 0.75)
quantile(prc3, 0.75)

quantile(price_data, 0.25)
quantile(price_data, 0.25)
quantile(prc, 0.25)
quantile(prc, 0.75)
quantile(price_data, 0.75)
mean(pr)
mean(prc)
mean(price_data)





p1 = scatter(up[2,:], down[3,:], markersize=1,legend=false,  title="Simulated Data", xlabel = L"\varepsilon", ylabel =L"\eta", dpi=300)
p2 = scatter(upc1[2,:], downc1[3,:], markersize=1, legend = false, title="Counterfactual", xlabel = L"\varepsilon", ylabel =L"\eta", dpi=300)
plot(p1,p2, layout=(1,2), legends=false)
# savefig("/Users/amir/github/paper/figures/eps-eta-matching-cf-1.png")



p1 = scatter(up_data, down_data[1,:], markersize=1,legend=false,  title="Simulated Data", xlabel = L"\varepsilon", ylabel =L"\eta", dpi=300)
p2 = scatter(upc3[1,:], downc3[1,:], markersize=1, legend = false, title="Counterfactual", xlabel = L"\varepsilon", ylabel =L"\eta", dpi=300)
plot(p1,p2, layout=(1,2), legends=false)
# savefig("/Users/amir/github/paper/figures/eps-eta-matching-cf-1.png")


# cor(up[1,:], down[3,:])
# cor(upc2[1,:], downc2[3,:])




p1 = scatter(up_data, price_data, markersize=1,legend=false,  title="Simulated Data", xlabel = L"\varepsilon", ylabel =L"\eta", dpi=300, ylims=(-5,30))
p2 = scatter(upc3[1,:], prc3, markersize=1, legend = false, title="Counterfactual", xlabel = L"\varepsilon", ylabel =L"\eta", dpi=300,ylims=(-5,30))
plot(p1,p2, layout=(1,2), legends=false)
# savefig("/Users/amir/github/paper/figures/eps-eta-matching-cf-1.png")


cor(up[1,:], down[1,:])
cor(upc3[1,:], downc3[1,:])





p3=  scatter(up[1,:],pr, markersize=1, legend = false, smooth=false, xlims =(0,3.5), ylims=(-30,40), title="Counterfactual 2",  xlabel = "CEO Experience", ylabel ="Compensation", dpi=300)
p1 = scatter(upc2[1,:], prc2, markersize=1, legend = false, smooth=false, xlims =(0,3.5), ylims=(-30,40), title="Counterfactual 2",  xlabel = "CEO Experience", ylabel ="Compensation", dpi=300)
p2 = scatter(upc3[1,:], prc3, markersize=1, legend = false, smooth=false, xlims =(0,3.5), ylims=(-30,40), title="Counterfactual 2",  xlabel = "CEO Experience", ylabel ="Compensation", dpi=300)




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




h = 0.2; alpha = 0.25;
obj_linear(b) = objective_f(b ,quantile(up_data, 0.75), price_data, up_data, h , alpha);
res = Optim.optimize(obj_linear,[1.,1.]);
comp75 = Optim.minimizer(res)[1]


obj_linear(b) = objective_f(b ,quantile(up_data, 0.50), price_data, up_data, h , alpha);
res = Optim.optimize(obj_linear,[1.,1.]);
comp50 = Optim.minimizer(res)[1]
comp75 - comp50 


obj_linear(b) = objective_f(b ,quantile(up_data, 0.25), prc2 , upc2[1,:], h , alpha);
res = Optim.optimize(obj_linear,[1.,1.]);
comp25 = Optim.minimizer(res)[1]
comp50 -comp25






h = 0.2; alpha = 0.75;
obj_linear(b) = objective_f(b ,quantile(up_data, 0.75), prc2, upc2[1,:], h , alpha);
res = Optim.optimize(obj_linear,[1.,1.]);
comp75 = Optim.minimizer(res)[1]


obj_linear(b) = objective_f(b ,quantile(up_data, 0.50), prc2, upc2, h , alpha);
res = Optim.optimize(obj_linear,[1.,1.]);
comp50 = Optim.minimizer(res)[1]
comp75 - comp50 


obj_linear(b) = objective_f(b ,quantile(up_data, 0.25), prc2 , upc2[1,:], h , alpha);
res = Optim.optimize(obj_linear,[1.,1.]);
comp25 = Optim.minimizer(res)[1]
comp50 -comp25



scatter(upc2[1,:], prc2, markersize=2, xlims=(0,quantile(upc2[1,:], 0.95)), ylims=(-30,30))


h = 0.2; alpha = 0.75;
sum_diff= zeros(100);
sum_diff2 = zeros(100);
for i =1:100
    upc2, downc2, prc2 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165 +7*i, true, up_data_c2,down_data_c2[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);

    obj_linear(b) = objective_f(b ,quantile(up_data, 0.75), prc2, upc2[1,:], h , alpha);
    res = Optim.optimize(obj_linear,[1.,1.]);
    comp75 = Optim.minimizer(res)[1]


    obj_linear(b) = objective_f(b ,quantile(up_data, 0.50), prc2, upc2[1,:], h , alpha);
    res = Optim.optimize(obj_linear,[1.,1.]);
    comp50 = Optim.minimizer(res)[1]
    sum_diff[i] = (comp75 - comp50)

    obj_linear(b) = objective_f(b ,quantile(up_data, 0.25), prc2 , upc2[1,:], h , alpha);
    res = Optim.optimize(obj_linear,[1.,1.]);
    comp25 = Optim.minimizer(res)[1]
    sum_diff2[i] = comp50 -comp25

end
# sum_diff
mean(sum_diff)
mean(sum_diff2)








h = 0.2; alpha = 0.75;
sum_diff= zeros(100);
sum_diff2 = zeros(100);
for i =1:100
    upc3, downc3, prc3 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165 +7*i, true, up_data_c3,down_data_c3[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);

    obj_linear(b) = objective_f(b ,quantile(up_data, 0.75), prc3, upc3[1,:], h , alpha);
    res = Optim.optimize(obj_linear,[1.,1.]);
    comp75 = Optim.minimizer(res)[1]


    obj_linear(b) = objective_f(b ,quantile(up_data, 0.50), prc3, upc3[1,:], h , alpha);
    res = Optim.optimize(obj_linear,[1.,1.]);
    comp50 = Optim.minimizer(res)[1]
    sum_diff[i] = (comp75 - comp50)

    obj_linear(b) = objective_f(b ,quantile(up_data, 0.25), prc3 , upc3[1,:], h , alpha);
    res = Optim.optimize(obj_linear,[1.,1.]);
    comp25 = Optim.minimizer(res)[1]
    sum_diff2[i] = comp50 -comp25

end
# sum_diff
mean(sum_diff)
mean(sum_diff2)



comp50 -comp25







ct = 0; 
for i = 1:500 
    if prc2[i]<-100
        ct+=1
    end

end







comp75-comp50

function diff_75_50(i) 

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

    upc2, downc2, prc2 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3161*i, true, up_data_c2,down_data_c2[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11])
    
    obj_linear(b) = objective_f(b ,quantile(up_data, 0.75), prc2, upc2[1,:], 0.5 , 0.5);
    res = Optim.optimize(obj_linear,[1.,1.])
    c75 = Optim.minimizer(res)[1]

    obj_linear(b) = objective_f(b ,quantile(up_data, 0.25), prc2, upc2[1,:], 0.5 , 0.5);
    res = Optim.optimize(obj_linear,[1.,1.]);
    c50 = Optim.minimizer(res)[1]
    
    return out
end 

diff_75_50(31231)


obj_linear(b) = objective_f(b ,2.31, price_data, up_data, 0.5 , 0.5);
res = Optim.optimize(obj_linear,[1.,1.]);
comp75 = Optim.minimizer(res)[1]

obj_linear(b) = objective_f(b ,0.98, price_data, up_data, 0.5 , 0.5);
res = Optim.optimize(obj_linear,[1.,1.]);
comp25 = Optim.minimizer(res)[1]



obj_linear(b) = objective_f(b ,2.31, prc2, upc2[1,:], 0.5 , 0.5);
res = Optim.optimize(obj_linear,[1.,1.]);
comp75_c2 = Optim.minimizer(res)[1]

obj_linear(b) = objective_f(b ,0.98, prc2, upc2[1,:], 0.5 , 0.5);
res = Optim.optimize(obj_linear,[1.,1.]);
comp25_c2 = Optim.minimizer(res)[1]

comp75 - comp25

comp75_c2 - comp25_c2




obj_linear(b) = objective_f(b ,2.31, prc3, upc3[1,:], 0.5 , 0.5);
res = Optim.optimize(obj_linear,[1.,1.]);
comp75_c3 = Optim.minimizer(res)[1]

obj_linear(b) = objective_f(b ,0.98, prc3, upc3[1,:], 0.5 , 0.5);
res = Optim.optimize(obj_linear,[1.,1.]);
comp25_c3 = Optim.minimizer(res)[1]

comp75 - comp25
comp75_c2 - comp25_c2
comp75_c3 - comp25_c3





# Report counterfactual correlations

function cf2_corr(i)
    upc2, downc2, prc2 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3161*i, true, up_data_c2,down_data_c2[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
    return cor(upc2[1,:], downc2[2,:])
end



function cf3_corr(i)
    upc3, downc3, prc3 = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3161*i, true, up_data_c3,down_data_c3[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
    return cor(upc3[1,:], downc3[1,:])
end


corrs_cf2 = map(cf2_corr, 1:100)
corrs_cf3 = map(cf3_corr, 1:100)

mean(corrs_cf2)
cor(up_data, down_data[2,:])
cor(up_data, down_data[1,:])
mean(corrs_cf3)


function cf_corr(i)
    up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3161*i, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
    return cor(up[1,:], down[2,:])
end

corrs_sim_1 = map(cf_corr, 1:100)
mean(corrs_sim_1)

corrs_sim_2 = map(cf_corr, 1:100)
mean(corrs_sim_2)




function cond_q_pr(x, pr, up)
    obj_linear(b) = objective_f(b ,x, pr, up, 0.8 , 0.5);
    res = Optim.optimize(obj_linear,[1.,1.]);
    return Optim.minimizer(res)[1]
end


plot(x->cond_q_pr(x, price_data, up_data),0.1, 3.5, legend= false)
plot(x->cond_q_pr(x, prc2, upc2[1,:]),0.1, 3.5, legend= true, label="CF2")
plot!(x->cond_q_pr(x, prc3, upc3[1,:]),0.1, 3.5, legend= true, label="CF3")

dat_kde = kde(price_data) 
c1_kde = kde(prc1)

plot(dat_kde)
plot!(c1_kde)

std(price_data)
std(prc1)
median(price_data)
median(prc1)


p1 = scatter(up[2,:], pr, markersize=1,legend=false,  title="Simulated Data", xlabel = L"\varepsilon", ylabel =L"\eta", dpi=300)
p2 = scatter(upc1[2,:], prc1, markersize=1, legend = false, title="Counterfactual", xlabel = L"\varepsilon", ylabel ="Compensation", dpi=300)
plot(p1,p2, layout=(1,2), legends=false)
# savefig("/Users/amir/github/paper/figures/eps-eta-matching-cf-1.png")





p1 = scatter(up[1,:], down[1,:], markersize=1,legend=false, smooth = true, title="Simulated Data", xlabel = "CEO Experience", ylabel ="Firm HHI", dpi=300)

p2 = scatter(up_data, down_data[1,:], markersize=1, legend = false, smooth = true, title="Real Data", xlabel = "CEO Ability", ylabel ="Firm HHI", dpi=300)
p1 = scatter(up[2,:], down[3,:], markersize=1,legend=false, smooth = true, title="Simulated Data", xlabel = "CEO Experience", ylabel ="Firm HHI", dpi=300)
p3 = scatter(upc1[2,:], downc1[3,:], markersize=1, legend = false, smooth = true, title="Real Data", xlabel = "CEO Ability", ylabel ="Firm HHI", dpi=300)
plot(p1,p2, layout=(1,2), legends=false)
# savefig( "/Users/amir/github/ceo/Notes and Reports/results_Jeremy 2023 03 12/Figures/ability_HHI")

cor(up[1,:], down[1,:])
cor(up_data, down_data[1,:])


p1 = scatter(up[1,:], down[2,:], markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "CEO Ability", ylabel ="Firm Size", dpi=300)
p2 = scatter(up_data, down_data[2,:], markersize=1, legend = false, smooth=true,  title="Real Data", xlabel = "CEO Ability", ylabel ="Firm Size", dpi=300)
plot(p1,p2, layout=(1,2), legends=false)
# savefig( "/Users/amir/github/ceo/Notes and Reports/results_Jeremy 2023 03 12/Figures/ability_size")


cor(up[1,:], down[2,:])
cor(upc[1,:], downc[2,:])
cor(up_data, down_data[2,:])

p1 = scatter(up[1,:], pr, markersize=1,legend=false, smooth=true,title="Simulated Data", xlabel = "CEO Ability", ylabel ="Compensation", dpi=300 )
p2 = scatter(up_data, price_data, markersize=1, legend = false, smooth=true, title="Real Data", xlabel = "CEO Ability", ylabel ="Compensation", dpi=300)
plot(p1,p2, layout=(1,2), legends=false, ylims=(0,30))
# savefig( "/Users/amir/github/ceo/Notes and Reports/results_Jeremy 2023 03 12/Figures/ability_compensation")


cor(up[1,:], pr)
cor(up_data, price_data)
cor(up_data, log.(price_data))


p1 = scatter(down[1,:], pr, markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "Firm HHI", ylabel ="Compensation", dpi=300 )
p2 = scatter(down_data[1,:], price_data, markersize=1, legend = false, smooth=true, title="Real Data",  xlabel = "Firm HHI", ylabel ="Compensation", dpi=300)
# plot(p1,p2, layout=(1,2), legends=false, ylims=(0,30))
# savefig( "/Users/amir/github/ceo/Notes and Reports/results_Jeremy 2023 03 12/Figures/HHI_compensation")

cor(down[1,:], pr)
cor(downc[1,:], pr)
cor(down_data[1,:], price_data)


k_price = kde(price_data)
k_prc = kde(prc);
k_pr= kde(pr)


scatter(collect(-10:0.1:50),[ pdf(k_price, collect(-10:0.1:50)[i] ) i = 1:length(collect(-10:0.1:50))])







p1 = scatter(down[2,:], pr, markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "Firm Size", ylabel ="Compensation", dpi=300 )
# p2 = scatter(down_data[2,:], price_data, markersize=1, legend = false, smooth=true, title="Real Data",  xlabel = "Firm Size", ylabel ="Compensation", dpi=300)
p2 = scatter(downc[2,:], prc, markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "Firm Size", ylabel ="Compensation", dpi=300 )
plot(p1,p2, layout=(1,2), legends=false , ylims=(0,30))
# savefig( "/Users/amir/github/ceo/Notes and Reports/results_Jeremy 2023 03 12/Figures/size_compensation")

cor(down[2,:], pr)
cor(down_data[2,:], price_data)





sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);


function up_valuation(b, x, y, eps, xi, n_opt)
    b = res[n_opt,1:11]
    b[8] * y[1] + b[9] *y[2] +b[1]*x - b[11]* 1
end

function down_valuation(b, x, y, eps, xi, n_opt)
    b = res[n_opt,1:11]
    b[7] * x + b[2] *x*y[1]+b[3]*x*y[2]
end

x= 1.5; y=[0.25,2]; eps= 0.5; xi = -4.7;

up_valuation(b,x,y, eps,xi,1 )

upvals = [up_valuation(b,x,y, eps,xi,i ) for i=1:10]
downvals = [down_valuation(b,x,y, eps,xi,i ) for i=1:10]

udelx =  [up_valuation(b,x+ 0.9,y, eps,xi,i ) for i=1:10];
ddelx = [down_valuation(b,x+0.9,y, eps,xi,i ) for i=1:10];
udelx - upvals
ddelx - downvals



udely1 =  [up_valuation(b,x,y+[0.2,0], eps,xi,i ) for i=1:10];
ddely1 = [down_valuation(b,x,y+[0.2,0], eps,xi,i ) for i=1:10];

udely1- upvals
ddely1 - downvals





udely2 =  [up_valuation(b,x,y+[0,1.3], eps,xi,i ) for i=1:10]
ddely2 = [down_valuation(b,x,y+[0,1.3], eps,xi,i ) for i=1:10]

udely2- upvals
ddely2 - downvals











# p1 = scatter(up[1,:], upp, markersize=1,legend=false, smooth=true)

# p1 = scatter(up[1,:], downp, markersize=1,legend=false, smooth=true)


# p1 = scatter(down[1,:], downp, markersize=1,legend=false, smooth=true)
# p1 = scatter(down[2,:], downp, markersize=1,legend=false, smooth=true)

# plot(p1,p2, layout=(1,2), legends=false , ylims=(0,40), title = "y2 p")

cor(down[2,:], pr)
cor(down_data[2,:], price_data)


median(pr)
median(price_data)

b= [-0.0583, 5.6603, 0.7898, -3.8481, 3.97079582423067,-2.165, 0.3517]

println(round.(b, digits=1))

up_data[253]
down_data[:,253]
price_data[253]


median(price_data)
median(up_data)
median(down_data[1,:])
median(down_data[2,:])



# Valuations

7.1 * 0.25 + 1.9*2 - 0.4*1.5*2 -12.4*1.5*1 

7.1 * 0.2
1.9*1.3 - 0.4*1.5*1.3
- 0.4*.9*2 -12.4*.9*1 


8.3*1.5 + 0.9*1.5*0.25 + 1.5*2 + 5*0.5 *1 

0.9*1.5*0.2 
1.5*1.3
8.3*.9 + 0.9*.9*0.25 + 1.5*.9 



plot(x->2*pdf(LogNormal(0,1),.5*x), 0,100)



b=res[3,:]

x=1.5; y1 = 0.25; y2 =2;
b[1]*x*y2  +b[8] *y1 +b[9]*y2 - b[11]
b[7]*x +b[2]*x*y1 +b[3]*x*y2 


dy1 = 0.2
b[8] *dy1 
b[2]*x*dy1

dy2 = 1.3
b[1]*x*dy2 +b[9]*dy2
b[3]*x*dy2 

dx=0.9
b[1]*dx*y2 
b[7]*dx +b[2]*dx*y1 +b[3]*dx*y2 



dx = 0.9

x=1.5; y1 = 0.25; y2 =2;

b[1]*0.9*y2 

b[7]*0.9 +b[2]*0.9*y1 +b[3]*0.9*y2 




HHI=\frac{1}{2}\left[\sum_{i=1}^{n_{Segments}}\left(\frac{\text{Revenue from segment \$i\$ }}{\text{Total Revenue}}\right)^{2}\right]+\frac{1}{2}\left[\left(\frac{\text{Domestic Revenue}}{\text{Total Revenue}}\right)^{2}+\left(\frac{\text{Foreign Revenue}}{\text{Total Revenue}}\right)^{2}\right]




data_kde = kde(price_data)
model_kde = kde(pr)

plot(data_kde)
plot!(model_kde)