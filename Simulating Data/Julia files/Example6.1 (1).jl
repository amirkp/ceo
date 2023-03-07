Pkg.add("Distributions");
Pkg.add("JuMP")
Pkg.add("LinearAlgebra")
Pkg.add("Plots")

using Distributions;
using JuMP;
using LinearAlgebra;
using Plots;

function Gaussian(ΣP,ΣQ,x,y)
    # Galichon 2016, P.62, Example 6.1
    # this function is used to find the profits and optimal assignment
    # P ~ N(0,ΣP), the distribution of x
    # Q ~ N(0,ΣQ), the distribution of y
    # x(y) is upstream(downstream) characteristics with [observable;unobservable]
    S_u = ΣP^-0.5 * (ΣP^0.5 * ΣQ * ΣP^0.5) * ΣP^-0.5;
    S_v = ΣQ^-0.5 * (ΣQ^0.5 * ΣP * ΣQ^0.5) * ΣQ^-0.5;
    # S_u and S_v are intermediate variables, here S_v = S_u ^(-1)
    u = 1/2 * x' * S_u * x;
    v = 1/2 * y' * S_v * y;
    # u and v are
    T_x = S_u * x;
    # T_x is the Optimal assignment
    return u,v,T_x;
end

# testing part
D = 2; # dimension
N = 1000; # sample size
n_grid = 100; # number of points on every integer coordinate in y(downstream firm characteristics)

N_matrix = [n for n=1:N]'; # a matrix, size of N, filled with sorted integer
up_diff(x)=0.5x; # the function between characteristics
x = [N_matrix; N_matrix]/up_diff(n_grid);
y = up_diff(x);

# zero off diagonal elements distribution
ΣP = I+zeros(D,D);
ΣQ = up_diff(ΣP);
# above two matrices are the covariance matrix of x and y

(u,v,T_x)=Gaussian(ΣP,ΣQ,x,y);

plot_guassx(x,y)=u[round(Int,x*up_diff(n_grid)),round(Int,y*up_diff(n_grid))]
plot_guassy(x,y)=v[round(Int,x*n_grid),round(Int,y*n_grid)]
# above two functions are used to return z-axis values when plot
plotly()
plot(x[1,:],x[2,:],plot_guassx,st=:surface,camera=(-30,30),title="upstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")
plotly()
plot(y[1,:],y[2,:],plot_guassy,st=:surface,camera=(-30,30),title="downstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")

# non-zero off diagonal elements distribution
ΣP = 0.5I+0.5ones(D,D);
ΣQ = up_diff(ΣP);

(u,v,T_x)=Gaussian(ΣP,ΣQ,x,y);

plot_guassx(x,y)=u[round(Int,x*up_diff(n_grid)),round(Int,y*up_diff(n_grid))]
plot_guassy(x,y)=v[round(Int,x*n_grid),round(Int,y*n_grid)]
plotly()
plot(x[1,:],x[2,:],plot_guassx,st=:surface,camera=(-30,30),title="upstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")
plotly()
plot(y[1,:],y[2,:],plot_guassy,st=:surface,camera=(-30,30),title="downstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")
