### using estimated parameters to generate data and compare the patterns visually 
# need to load all packages and functions from estimate.jl first. 

using Plots
#test if Plots is loaded correctly, in case of broke package refer to notes
scatter(randn(10))
# @everywhere begin 
##### SETUP #####

b= res[2, 1:11]
# b= res1[3, 1:8]
# b= res[2, 1:11]
# # b= [-0.72, 1.0865, 0.9817, 1.5154, -0.7186, 1.7308, 3.7191, 4.8389, 1.5418, 2.2477, 1.5972]
# b = [-0.72, 1.086, 0.982, 1.515, -0.719, 1.731, 3.719, 4.839, 1.542, 3.548, 100.8597]

# b[2]=2.
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
up, down, pr, upp, downp,xi = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
up, down, pr, upp, downp,xi = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data,vcat(zeros(n_firms)', down_data[2,:]'),b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
quantile(price_data, [0.2,0.8])
quantile(pr, [0.2,0.8])


median(pr)
median(price_data)
count = 0
for i =1:500
    if xi[i]<100000000
        count+=1 
    end
end
count

for i = 1:50
    display([pr[(i-1)*10+1 : i*10] xi[(i-1)*10+1 : i*10]])
end

p1 = scatter(up[1,:], down[1,:], markersize=1,legend=false, smooth = true, title="Simulated Data", xlabel = "x", ylabel ="y1")
p2 = scatter(up_data, down_data[1,:], markersize=1, legend = false, smooth = true, title="Real Data", xlabel = "x", ylabel ="y1")
plot(p1,p2, layout=(1,2), legends=false)
cor(up[1,:], down[1,:])
cor(up_data, down_data[1,:])


p1 = scatter(up[1,:], down[2,:], markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "x", ylabel ="y2")
p2 = scatter(up_data, down_data[2,:], markersize=1, legend = false, smooth=true,  title="Real Data", xlabel = "x", ylabel ="y2")
plot(p1,p2, layout=(1,2), legends=false)

cor(up[1,:], down[2,:])
cor(up_data, down_data[2,:])

p1 = scatter(up[1,:], pr, markersize=1,legend=false, smooth=true,title="Simulated Data", xlabel = "x", ylabel ="Price" )
p2 = scatter(up_data, price_data, markersize=1, legend = false, smooth=true, title="Real Data", xlabel = "x", ylabel ="Price")
plot(p1,p2, layout=(1,2), legends=false, ylims=(0,30))

cor(up[1,:], pr)
cor(up_data, price_data)
cor(up_data, log.(price_data))


p1 = scatter(down[1,:], pr, markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "y1", ylabel ="Price" )
p2 = scatter(down_data[1,:], price_data, markersize=1, legend = false, smooth=true, title="Real Data",  xlabel = "y1", ylabel ="Price")
plot(p1,p2, layout=(1,2), legends=false, ylims=(0,30))

cor(down[1,:], pr)
cor(down_data[1,:], price_data)

cor(xi, pr)
p1 = scatter(xi,  pr, markersize=1,legend=false, smooth=true,xlims=(0,10), ylims=(-30,30))
p1 = scatter(xi,  downp, markersize=1,legend=false, smooth=true,xlims=(0,10), ylims=(-30,30))




p1 = scatter(down[2,:], pr, markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "y2", ylabel ="Price" )
p2 = scatter(down_data[2,:], price_data, markersize=1, legend = false, smooth=true, title="Real Data",  xlabel = "y2", ylabel ="Price")
plot(p1,p2, layout=(1,2), legends=false , ylims=(0,30))

cor(down[2,:], pr)
cor(down_data[2,:], price_data)




p1 = scatter(up[1,:], upp, markersize=1,legend=false, smooth=true)

p1 = scatter(up[1,:], downp, markersize=1,legend=false, smooth=true)


p1 = scatter(down[1,:], downp, markersize=1,legend=false, smooth=true)
p1 = scatter(down[2,:], downp, markersize=1,legend=false, smooth=true)

plot(p1,p2, layout=(1,2), legends=false , ylims=(0,40), title = "y2 p")

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



x=1.5; y1 = 0.25; y2 =2;
b[1]*x*y2  +b[8] *y1 +b[9]*y2 -4.7

b[7]*x +b[2]*x*y1 +b[3]*x*y2 




x=1.5; y1 = 0.25; y2 =2;

b[1]*0.9*y2 

b[7]*0.9 +b[2]*0.9*y1 +b[3]*0.9*y2 





