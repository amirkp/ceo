### using estimated parameters to generate data and compare the patterns visually 
# need to load all packages and functions from estimate.jl first. 

using Plots
#test if Plots is loaded correctly, in case of broke package refer to notes
scatter(randn(10))
# @everywhere begin 
##### SETUP #####

# b= res[3, 1:7]
# b= res1[3, 1:8]
b= res[1, 1:11]
b= [-0.72, 1.0865, 0.9817, 1.5154, -0.7186, 1.7308, 3.7191, 4.8389, 1.5418, 2.2477, 1.5972]
println(round.(b, digits=1))
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
up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165160+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);


p1 = scatter(up[1,:], down[1,:], markersize=1,legend=false, smooth = true, title="Fake Data")
p2 = scatter(up_data, down_data[1,:], markersize=1, legend = false, smooth = true)
plot(p1,p2, layout=(1,2), legends=false, title="x y1")
cor(up[1,:], down[1,:])
cor(up_data, down_data[1,:])


p1 = scatter(up[1,:], down[2,:], markersize=1,legend=false, smooth=true)
p2 = scatter(up_data, down_data[2,:], markersize=1, legend = false, smooth=true)
plot(p1,p2, layout=(1,2), legends=false, title="x y2")

cor(up[1,:], down[2,:])
cor(up_data, down_data[2,:])

p1 = scatter(up[1,:], pr, markersize=1,legend=false, smooth=true)
p2 = scatter(up_data, price_data, markersize=1, legend = false, smooth=true)
plot(p1,p2, layout=(1,2), legends=false, ylims=(0,15), title = "x p")

cor(up[1,:], pr)
cor(up_data, price_data)


p1 = scatter(down[1,:], pr, markersize=1,legend=false, smooth=true)
p2 = scatter(down_data[1,:], price_data, markersize=1, legend = false, smooth=true)
plot(p1,p2, layout=(1,2), legends=false, ylims=(0,15), title = "y1 p")

cor(down[1,:], pr)
cor(down_data[1,:], price_data)



p1 = scatter(down[2,:], pr, markersize=1,legend=false, smooth=true)
p2 = scatter(down_data[2,:], price_data, markersize=1, legend = false, smooth=true)
plot(p1,p2, layout=(1,2), legends=false , ylims=(0,15), title = "y2 p")

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