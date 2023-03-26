
gen = ""
folder= "ou_bw_1"
niter = 10;
ndim = 11;




bws= BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/ou_bw_3/bw_res_1000_2.bson")["bw"]



bwmat = zeros(99,3)

for i = 1:99
    bwmat[i,:] = bws[i]
end

bwmat


scatter(bwmat[:,1], bwmat[:,2], markersize = 2, color=:yellow)


using PolyFit
fit(bwmat[:,1], bwmat[:,2])

fit()



function fitpol(b)
    err = zeros(99) 
    for i = 1:99
        err[i]=( bwmat[i,2] - b[1] - b[2]*bwmat[i,1] - b[3]*bwmat[i,1]^2)^2
    end
    sort!(err)

    return mean(err[50:99])
end


pol = Optim.optimize(fitpol, rand(3))
coeffs=Optim.minimizer(pol)
scatter(bwmat[:,1], bwmat[:,2], markersize = 2, color=:yellow)

coeffs+=[0.1, -0.5, +0.3]
plot!(bwmat[:,1],[ coeffs[1]+coeffs[2]*bwmat[i,1]+coeffs[3]*bwmat[i,1]^2  for i =1:99])






using Loess
model = loess(bwmat[:,1],bwmat[:,2], span=0.8)
vs = predict(model, bwmat[:,1])
plot!(bwmat[:,1],vs)
scatter(2)