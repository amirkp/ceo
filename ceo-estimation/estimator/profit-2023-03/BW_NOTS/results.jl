
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

bwmat = [0.1 1.5;
         0.25 0.6;
         0.5   0.4;
         0.75   0.7;
         0.9  1.8
]


function fitpol(b)
    err = zeros(size(bwmat)[1]) 
    for i = 1:size(bwmat)[1]
        err[i]=( bwmat[i,2] - b[1] - b[2]*bwmat[i,1] - b[3]*bwmat[i,1]^2)^2
    end
    

    return mean(err)
end


pol = Optim.optimize(fitpol, rand(3))
coeffs=Optim.minimizer(pol)
scatter(bwmat[:,1], bwmat[:,2], markersize = 2, color=:yellow)

coeffs+=[0.1, -1.5, +0.3]
plot!(bwmat[:,1],[ coeffs[1]+coeffs[2]*bwmat[i,1]+coeffs[3]*bwmat[i,1]^2  for i =1:99])



q=0:0.01:1
q[1]
coeffs[1] .+ coeffs[2].*q .+coeffs[3].*q.^2

scatter(q,coeffs[1] .+ coeffs[2].*q .+coeffs[3].*q.^2)

using Loess
model = loess(bwmat[:,1],bwmat[:,2], span=0.8)
vs = predict(model, bwmat[:,1])
plot!(bwmat[:,1],vs)
scatter(2)


2.95 -7.8 +6.08