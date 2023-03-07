

gen = "NORMAL_S200-linear-normal-dist-up-error-03-06"
folder= "out-F-4-4"
niter = 10;
ndim = 11;
res = zeros(niter,ndim+1);
resG = zeros(niter,ndim+1);
for i = 1:niter
    if i != 90
        res[i,1:ndim] = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/$(folder)/light_res_$(gen)_$(i-1).bson")["L"]
        res[i,ndim+1]  = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/$(folder)/light_res_$(gen)_$(i-1).bson")["LV"]
        # 
        resG[i,1:ndim] = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/$(folder)/light_res_$(gen)_$(i-1).bson")["G"]
        resG[i,ndim+1]  = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/$(folder)/light_res_$(gen)_$(i-1).bson")["GV"]
    end    
end

display("text/plain", (res))




gen = "NORMAL_S200-pos-dprofmed"
folder= "out-F-4-3"
niter = 3;
ndim = 8;
res1 = zeros(niter,ndim+1);
resG1 = zeros(niter,ndim+1);
for i = 1:niter
    if i != 90
        res1[i,1:ndim] = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/$(folder)/light_res_$(gen)_$(i-1).bson")["L"]
        res1[i,ndim+1]  = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/$(folder)/light_res_$(gen)_$(i-1).bson")["LV"]
        # 
        resG1[i,1:ndim] = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/$(folder)/light_res_$(gen)_$(i-1).bson")["G"]
        resG1[i,ndim+1]  = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/$(folder)/light_res_$(gen)_$(i-1).bson")["GV"]
    end    
end

display("text/plain", (res1))

# loglike(res[3,1:8])



display("text/plain", mean(res, dims =1))





res-resG
res = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/out3-20iter/light_res_1_$.bson")

minimum(res[:,10])

loglike(b+ vcat(0.1, repeat([0.], 8)) )

jac = zeros(9)

# b= res[2,1:9]
b=res[1,1:11]
thres=1e-3
for i = 1:9
    c = zeros(9)
    c[i] +=thres
    jac[i] = -(loglike(b+2c) - 2*loglike(b+c) + loglike(b))/thres^2
end


jac


sqrt.(-(1 ./ jac))

loglike(res[1,1:9])



ll(θ) = log(lik(θ))
# Numerical first derivative
ll_prime(θ; h = 1e-5) = (ll(θ + h) - ll(θ)) / h
# Numerical second-order derivative (2nd order forward)
ll_prime2(θ; h = 1e-5) = (ll(θ + 2h) - 2ll(θ + h) + ll(θ)) / h^2
# Asymptotic standard error
ase(θ) = sqrt(- 1 / ll_prime2(θ))


loglike(b)


c = copy(b)
c[4] +=0.1
b[4]
loglike(b)
loglike(c)

repeat([.1], 9)



using FiniteDiff

hess = FiniteDiff.finite_difference_hessian(loglike, res[1,1:9], rel)


diag(inv(hess))

using FiniteDifferences
central_fdm(5, 1; factor=1e10)(sin_noisy, 1) - cos(1)



grid = collect(-4.7:0.01: -4.3)
lvals = [loglike(vcat(grid[i],b[2:9])) for i =1:length(grid)]

scatter(grid, lvals)


grid = collect(-6:0.1: -3)
lvals = [loglike(vcat(grid[i],b[2:9])) for i =1:length(grid)]

scatter(grid, lvals)



using FastChebInterp
g(x) = sin(x[1] + cos(x[2]) + 2x[3])
lb, ub = [-4.5,0], [-4,1 ] # lower and upper bounds of the domain, respectively
x = chebpoints((5,5), lb, ub)
c = chebinterp(log2d.(x), lb, ub)
c2 = chebinterp(log2d.(x), lb, ub)

log2d = x-> loglike(vcat(x[1], x[2], b[3:9]))
log2d([b[1] b[2]])
log2d(b)


log2d([-4.3,.5])-c([-4.3,.5])
log2d([-4.3,.5])-c2([-4.3,.5])

grid = collect(-5:0.01: -4.)
lvals2= [c2(vcat(grid[i],.5)) for i =1:length(grid)]
scatter!(grid, lvals2)


grid = collect(-5:0.01: -4.)
lvals = [log2d(vcat(grid[i],.5)) for i =1:length(grid)]



scatter(grid, lvals, xlims = (-6,-3), markersize = 1)

@everywhere h[2]=h[2]*4
f = Polynomials.fit(grid, lvals,2) 
lfit = [f(grid[i]) for i =1:length(grid)]

scatter!(grid, lfit, xlims = (-6,-3), markersize = 1)





using Polynomials



f(-4.5)


|> p -> round.(coeffs(p), digits=) |> Polynomial