using BlackBoxOptim, Optim, BSON
res1 = BSON.load("/Users/amir/github/ceo/ceo-estimation/estimator/out1/light_res_1_1.bson",@__MODULE__)

julia> res1 = BSON.load("/home/ak68/output/light_res_1_1.bson")
Dict{Any,Any} with 5 entries:
  "optimizer" => OptController{DiffEvoOpt{FitPopulation{Float64},RadiusLimitedSelector,AdaptiveDiffEvoRandBin{3},RandomBound{Continuou…
  "GV"        => 2.73146
  "G"         => [-0.277475, -0.00119175, 0.277144, -4.22497, -1.27498, 3.88669, 0.804581, 0.797653, 0.341299]
  "L"         => [-0.277808, -0.00113735, 0.277473, -4.23293, -1.27982, 3.88396, 0.770275, 0.797205, 0.345881]
  "LV"        => 2.7012

julia> BSON.load("/home/ak68/output/light_res_1_2.bson")
Dict{Any,Any} with 5 entries:
  "optimizer" => OptController{DiffEvoOpt{FitPopulation{Float64},RadiusLimitedSelector,AdaptiveDiffEvoRandBin{3},RandomBound{Continuou…
  "GV"        => 2.83
  "G"         => [-0.182693, -0.00125939, 0.182782, -3.66991, 1.20456, 0.460816, 1.52899, 0.447629, 0.259629]
  "L"         => [-0.182961, -0.00110267, 0.182885, -3.73956, 1.33105, 0.510334, 1.473, 0.447999, 0.259908]
  "LV"        => 2.76328

julia> BSON.load("/home/ak68/output/light_res_1_3.bson")
Dict{Any,Any} with 5 entries:
  "optimizer" => OptController{DiffEvoOpt{FitPopulation{Float64},RadiusLimitedSelector,AdaptiveDiffEvoRandBin{3},RandomBound{Continuou…
  "GV"        => 2.72358
  "G"         => [-0.171795, -0.00215549, 0.171642, -2.45665, -1.15024, 1.65624, 1.89104, 0.668312, 0.402317]
  "L"         => [-0.171942, -0.00224749, 0.171785, -2.45852, -1.15108, 1.67624, 1.95504, 0.667332, 0.399948]
  "LV"        => 2.70952

julia> BSON.load("/home/ak68/output/light_res_1_4.bson")
Dict{Any,Any} with 5 entries:
  "optimizer" => OptController{DiffEvoOpt{FitPopulation{Float64},RadiusLimitedSelector,AdaptiveDiffEvoRandBin{3},RandomBound{Continuou…
  "GV"        => 2.57847
  "G"         => [-0.15932, -0.000895975, 0.159289, -4.43158, -1.3001, 4.68876, -0.0540073, 1.16725, 0.193648]
  "L"         => [-0.159268, -0.000924552, 0.159232, -4.42735, -1.29218, 4.6879, -0.0544571, 1.16789, 0.193573]
  "LV"        => 2.51982

