
Pkg.add("Distributions");
Pkg.add("JuMP")
Pkg.add("LinearAlgebra")
Pkg.add("Plots")

using Distributions;
using JuMP;
using LinearAlgebra;

function Gaussian(ΣP,ΣQ,x,y)
    #Galichon 2016, P.62, Example 6.1
    S_u = ΣP^-0.5 * (ΣP^0.5 * ΣQ * ΣP^0.5) * ΣP^-0.5;
    S_v = ΣQ^-0.5 * (ΣQ^0.5 * ΣP * ΣQ^0.5) * ΣQ^-0.5;
    u = 1/2 * x' * S_u * x;
    v = 1/2 * y' * S_v * y;
    T_x = S_u * x;
    T_y = S_v * y;
    return u,v,T_x,T_y;
end

# testing part

D=2;
N=100;
ΣP=1I+zeros(D,D);
ΣQ=2I+zeros(D,D);

N_matrix = [n for n=1:N]';
x = [N_matrix; N_matrix];
y=x;

(u,v,T_x,T_y)=Gaussian(ΣP,ΣQ,x,y);

plot_guassx(x,y)=u[x,y]
plot_guassy(x,y)=v[x,y]
plotly()
plot(x[1,:],x[2,:],plot_guassx,st=:surface,camera=(-30,30),title="upstream profit")
plotly()
plot(y[1,:],y[2,:],plot_guassy,st=:surface,camera=(-30,30),title="downstream profit")
