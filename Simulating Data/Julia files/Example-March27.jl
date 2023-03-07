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
    # x(y) is upstream(downstream) characteristics
    S_u = ΣP^-0.5 * (ΣP^0.5 * ΣQ * ΣP^0.5)^0.5 * ΣP^-0.5;
    S_v = ΣQ^-0.5 * (ΣQ^0.5 * ΣP * ΣQ^0.5)^0.5 * ΣQ^-0.5;
    # S_u and S_v are intermediate variables, here S_v = S_u ^(-1)
    u = 1/2 * x' * S_u * x;
    v = 1/2 * y' * S_v * y;
    # u (v) is the profit of upstream(downstream)
    T_x = S_u * x;
    # T_x is the Optimal assignment
    return u,v,T_x;
end

function testGaussian(u,v,x,y)
    N=ndims(u);
    equal_matrix = zeros(N,N)#use this matrix to record the stability
    production = x'y;# production matrix
    capacity = ones(N,N);#a matrix filled with 1s
    for i = 1:N;#if Profit_Upi + profit_Downj >= S[i,j] for all (i, j)∈ N × N, regardless i and j are matched or not
        for j = 1:N;
            if round(u[i,j] + v[i,j] - production[i,j]; digits=10) == 0;
                equal_matrix[i,j] = 1;
            end
        end
    end
    if equal_matrix == capacity;#if all elements in stability_matrix are 1s, it's stable
        equality = "equal";
    else equality = "unequal";
    end
    return equality;
end

# testing part
D = 2; # dimension
N = 1000; # sample size
n_grid = 100; # number of points on every integer coordinate in y(downstream firm characteristics)

N_matrix = [n for n=1:N]'; # a matrix, size of N, filled with sorted integer
up_diff(x)=x; # the function between characteristics
x = [N_matrix; N_matrix]/up_diff(n_grid);
y = up_diff(x);


# zero off diagonal elements distribution
ΣP1 = I+zeros(D,D);
ΣQ1 = up_diff(ΣP1);
# above two matrices are the covariance matrix of x and y

(u1,v1,y1)=Gaussian(ΣP1,ΣQ1,x,y);
(u1,v1,y1)=Gaussian(ΣP1,ΣQ1,x,y1);
equal1 = testGaussian(u1,v1,x,y1);# equal means if u + v = x'y;

# another zero off diagonal elements distribution
ΣP2 = 5I+zeros(D,D);
ΣQ2 = up_diff(ΣP2);
# above two matrices are the covariance matrix of x and y

(u2,v2,y2)=Gaussian(ΣP2,ΣQ2,x,y);
(u2,v2,y2)=Gaussian(ΣP2,ΣQ2,x,y2);
equal2 = testGaussian(u2,v2,x,y2);

# non-zero off diagonal elements distribution
ΣP3 = 0.5I+0.5ones(D,D);
ΣQ3 = up_diff(ΣP3);

(u3,v3,y3)=Gaussian(ΣP3,ΣQ3,x,y);
(u3,v3,y3)=Gaussian(ΣP3,ΣQ3,x,y3);
equal3 = testGaussian(u3,v3,x,y3);

#ΣP is not equal to ΣQ
ΣP4 = ΣP1;
ΣQ4 = 2*ΣP4;

(u4,v4,y4)=Gaussian(ΣP4,ΣQ4,x,y);
(u4,v4,y4)=Gaussian(ΣP4,ΣQ4,x,y4);
equal4 = testGaussian(u4,v4,x,y4);




#plot part
plot_guassx1(x,y)=u1[round(Int,x*up_diff(n_grid)),round(Int,y*up_diff(n_grid))]
plot_guassy1(x,y)=v1[round(Int,x*n_grid),round(Int,y*n_grid)]
# above two functions are used to return z-axis values when plot
plotly()
plot(x[1,:],x[2,:],plot_guassx1,st=:surface,camera=(-30,30),title="upstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")
plotly()
plot(y1[1,:],y1[2,:],plot_guassy1,st=:surface,camera=(-30,30),title="downstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")

plot_guassx2(x,y)=u2[round(Int,x*up_diff(n_grid)),round(Int,y*up_diff(n_grid))]
plot_guassy2(x,y)=v2[round(Int,x*n_grid),round(Int,y*n_grid)]
# above two functions are used to return z-axis values when plot
plotly()
plot(x[1,:],x[2,:],plot_guassx2,st=:surface,camera=(-30,30),title="upstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")
plotly()
plot(y2[1,:],y2[2,:],plot_guassy2,st=:surface,camera=(-30,30),title="downstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")

plot_guassx3(x,y)=u3[round(Int,x*up_diff(n_grid)),round(Int,y*up_diff(n_grid))]
plot_guassy3(x,y)=v3[round(Int,x*n_grid),round(Int,y*n_grid)]
plotly()
plot(x[1,:],x[2,:],plot_guassx3,st=:surface,camera=(-30,30),title="upstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")
plotly()
plot(y3[1,:],y3[2,:],plot_guassy3,st=:surface,camera=(-30,30),title="downstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")

plot_guassx4(x,y)=u4[round(Int,x*up_diff(n_grid)),round(Int,y*up_diff(n_grid))]
plot_guassy4(x,y)=v4[round(Int,x*n_grid),round(Int,y*n_grid)]
plotly()
plot(x[1,:],x[2,:],plot_guassx3,st=:surface,camera=(-30,30),title="upstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")
plotly()
plot(y4[1,:],y4[2,:],plot_guassy3,st=:surface,camera=(-30,30),title="downstream profit",xlabel="x:observable",ylabel="y:unobservable",zlabel="z:profit")
