Pkg.add("Distributions");
Pkg.add("JuMP")
Pkg.add("Gurobi")
Pkg.add("LinearAlgebra")
Pkg.add("Plots")

using Distributions;
using Gurobi;
using JuMP;
using LinearAlgebra;
using Plots;

function Gaussian(ΣP,ΣQ,x,y)
    S_u = ΣP^-0.5 * (ΣP^0.5 * ΣQ * ΣP^0.5) * ΣP^-0.5;
    S_v = ΣQ^-0.5 * (ΣQ^0.5 * ΣP * ΣQ^0.5) * ΣQ^-0.5;
    u = 1/2 * x' * S_u * x;
    v = 1/2 * y' * S_v * y;
    T_x = S_u * x;
    return u,v,T_x;
end

# testing part

N=2
μ=zeros(N)
ΣP=10I+zeros(N,N);
ΣQ=10I+zeros(N,N);

dis_x=MvNormal(μ,ΣP);
dis_y=MvNormal(μ,ΣQ);

x=rand(dis_x,1);
y=rand(dis_y,1);

(u,v,T_x)=Gaussian(ΣP,ΣQ,x,y)
profit=[u[1];v[1]];
plotly()
plot(x,T_x,title="Optimal Assignment", xlab="x", ylab="T(x)",legend=false)
plot(x,profit,title="Profit", xlab="x", ylab="profit",legend=false)
