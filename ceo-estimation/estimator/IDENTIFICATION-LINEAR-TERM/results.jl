#using BSON, Plot
res = zeros(20,9)
resG = zeros(20,9)

for i = 1:20
    if i != 9
        res[i,1:8] = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/out4-20iter/light_res_2_$(i-1).bson")["L"]
        res[i,9]  = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/out4-20iter/light_res_2_$(i-1).bson")["LV"]
        
        resG[i,1:8] = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/out4-20iter/light_res_2_$(i-1).bson")["G"]
        resG[i,9]  = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/out4-20iter/light_res_2_$(i-1).bson")["GV"]
    end    
end

res


res-resG
res = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/out3-20iter/light_res_1_$.bson")

minimum(res[:,10])


display("text/plain", res)