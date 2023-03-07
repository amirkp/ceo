### using estimated parameters to generate data and compare the patterns visually 
# need to load all packages and functions from estimate.jl first. 

using Plots
scatter(randn(10))
# @everywhere begin 
##### SETUP #####

b= res[3, 1:7]
b= res1[3, 1:8]
bup = [
    vcat(0, b[1], b[4])';
    vcat(0, 0. , 0.)';
]

bdown = [
    vcat(b[2], b[3], 0)';
    vcat(0 , 0 , b[5])';
]


x= 20;
# up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165160+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  0., b[7]);
up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165160+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7], b[8]);


p1 = scatter(up[1,:], down[1,:], markersize=1,legend=false, smooth = true)
p2 = scatter(up_data, down_data[1,:], markersize=1, legend = false, smooth = true)
plot(p1,p2, layout=(1,2), legends=false)
cor(up[1,:], down[1,:])
cor(up_data, down_data[1,:])


p1 = scatter(up[1,:], down[2,:], markersize=1,legend=false, smooth=true)
p2 = scatter(up_data, down_data[2,:], markersize=1, legend = false, smooth=true)
plot(p1,p2, layout=(1,2), legends=false)

cor(up[1,:], down[2,:])
cor(up_data, down_data[2,:])

p1 = scatter(up[1,:], pr, markersize=1,legend=false, smooth=true)
p2 = scatter(up_data, price_data, markersize=1, legend = false, smooth=true)
plot(p1,p2, layout=(1,2), legends=false)

cor(up[1,:], pr)
cor(up_data, price_data)


p1 = scatter(down[1,:], pr, markersize=1,legend=false, smooth=true)
p2 = scatter(down_data[1,:], price_data, markersize=1, legend = false, smooth=true)
plot(p1,p2, layout=(1,2), legends=false)

cor(down[1,:], pr)
cor(down_data[1,:], price_data)



p1 = scatter(down[2,:], pr, markersize=1,legend=false, smooth=true)
p2 = scatter(down_data[2,:], price_data, markersize=1, legend = false, smooth=true)
plot(p1,p2, layout=(1,2), legends=false)

cor(down[2,:], pr)
cor(down_data[2,:], price_data)


median(pr)
median(price_data)



b= [-0.0583, 5.6603, 0.7898, -3.8481, 3.97079582423067,-2.165, 0.3517]
