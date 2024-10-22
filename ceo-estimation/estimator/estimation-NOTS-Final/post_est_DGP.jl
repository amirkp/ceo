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

up, down, pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
# up, down, pr, upp, downp,xi = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data,vcat(zeros(n_firms)', down_data[2,:]'),b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
# n_rep = 200
# for i = 1:n_rep 
#     tmp_up,tmp_down, tmp_pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x+i, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
#     up .+= tmp_up
#     down .+= tmp_down
#     pr .+= tmp_pr
# end
# tmp_up,tmp_down, tmp_pr = sim_data_JV_up_obs(bup, bdown , 1., 1., n_firms, 3165161+x, true, up_data,down_data[1:2,:],b[6], sel_mode,  b[7],b[8:9], b[10],b[11]);
# up = up/(n_rep+1)
# down= down/(n_rep+1)
# pr= pr/(n_rep+1)




median(pr)
median(price_data)

mean(pr)
mean(price_data)


p1 = scatter(up[1,:], down[1,:], markersize=1,legend=false, smooth = true, title="Simulated Data", xlabel = "CEO Experience", ylabel ="Firm Scope", dpi=300)
p2 = scatter(up_data, down_data[1,:], markersize=1, legend = false, smooth = true, title="Real Data", xlabel = "CEO Experience", ylabel ="Firm Scope", dpi=300)
plot(p1,p2, layout=(1,2), legends=false)
# savefig( "/Users/amir/github/ceo/Notes and Reports/results_Jeremy 2023 03 12/Figures/ability_HHI")
savefig( "/Users/amir/github/paper/figures/ability_HHI")

cor(up[1,:], down[1,:])
cor(up_data, down_data[1,:])


p1 = scatter(up[1,:], down[2,:], markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "CEO Experience", ylabel ="Firm Size", dpi=300)
p2 = scatter(up_data, down_data[2,:], markersize=1, legend = false, smooth=true,  title="Real Data", xlabel = "CEO Experience", ylabel ="Firm Size", dpi=300)
plot(p1,p2, layout=(1,2), legends=false)
savefig( "/Users/amir/github/paper/figures/ability_size")


cor(up[1,:], down[2,:])
cor(up_data, down_data[2,:])

p1 = scatter(up[1,:], pr, markersize=1,legend=false, smooth=true,title="Simulated Data", xlabel = "CEO Experience", ylabel ="Compensation", dpi=300 )
p2 = scatter(up_data, price_data, markersize=1, legend = false, smooth=true, title="Real Data", xlabel = "CEO Experience", ylabel ="Compensation", dpi=300)
plot(p1,p2, layout=(1,2), legends=false, ylims=(0,30))
savefig( "/Users/amir/github/paper/figures/ability_compensation")


cor(up[1,:], pr)
cor(up_data, price_data)
cor(up_data, log.(price_data))


p1 = scatter(down[1,:], pr, markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "Firm Size", ylabel ="Compensation", dpi=300 )
p2 = scatter(down_data[1,:], price_data, markersize=1, legend = false, smooth=true, title="Real Data",  xlabel = "Firm Size", ylabel ="Compensation", dpi=300)
plot(p1,p2, layout=(1,2), legends=false, ylims=(0,30))
savefig( "/Users/amir/github/paper/figures/HHI_compensation")

cor(down[1,:], pr)
cor(down_data[1,:], price_data)






p1 = scatter(down[2,:], pr, markersize=1,legend=false, smooth=true, title="Simulated Data", xlabel = "Firm Size", ylabel ="Compensation", dpi=300 )
p2 = scatter(down_data[2,:], price_data, markersize=1, legend = false, smooth=true, title="Real Data",  xlabel = "Firm Size", ylabel ="Compensation", dpi=300)
plot(p1,p2, layout=(1,2), legends=false , ylims=(0,30))
savefig( "/Users/amir/github/paper/figures/size_compensation")

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
