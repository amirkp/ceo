#LOG NORMAL DGP
# One observed characteristic for the upstream side
# Two observed characteristic for the downstream side
# Sel_mode is the equilibrium selection rule, min, median, mean of downstream profits

function sim_data_JV_up_obs(β_up, β_down, Σ_up, Σ_down, n_firms,i, flag, obs_up,obs_down, d_min_prof_input, sel_mode="median", x_coeff=1.,y_coeffs=[0.,0.], scale_unobs=0.1, scale_up_unobs = 0.1)
    
    if flag == false
        # up_data = Array{Float64, 2}(undef, 2, n_firms)
    
        # up_data[1,:] = rand(Random.seed!(1234+i), LogNormal(Σ_up[1,1], Σ_up[1,2]), n_firms)
        # up_data[2,:] = rand(Random.seed!(1234+200i), LogNormal(0,0.1), n_firms)
        

        # down_data = Array{Float64, 2}(undef, 3, n_firms)
        # down_data[1,:] = rand(Random.seed!(1234+400i), LogNormal(Σ_down[1,1], Σ_down[1,2]), n_firms)
        # down_data[2,:] = rand(Random.seed!(1234+500i), LogNormal(Σ_down[2,1], Σ_down[2,2]), n_firms)
        # down_data[3,:] = rand(Random.seed!(1234+600i), LogNormal(Σ_down[3,1], Σ_down[3,2]), n_firms)
    elseif flag==true # take observed data as given (do not generate observed chars)
        
        up_data = Array{Float64, 2}(undef, 2, n_firms)
        up_data[1,:] = obs_up
        up_data[2,:] = rand(Random.seed!(1234+3000i),Uniform(0., 1.), n_firms)

        
        down_data = Array{Float64, 2}(undef, 3, n_firms)
        down_data[1:2,:] = obs_down
        down_data[3,:] = rand(Random.seed!(1234+6i), Normal(0,abs(scale_unobs)), n_firms)
    end
    
    #unobservable error term for upstream valuation
    up_unobs = rand(Random.seed!(94923403+6i), Normal(0,abs(scale_up_unobs)), n_firms)
    
    A_mat = β_up + β_down
    C = -1*Transpose(up_data)*A_mat*down_data #pairwise surplus
    for i = 1:n_firms
        C[i,:] .-=  x_coeff * up_data[1,i] + up_unobs[i]
    end

    for j = 1:n_firms
        C[:,j] .-=  y_coeffs[1] * down_data[1,j] + y_coeffs[2] * down_data[2,j]
    end

    



    # C=rand(500,500)
    match, up_profit_data, down_profit_data = find_best_assignment(C)

    down_match_data=  Array{Float64, 2}(undef, 3, n_firms)
    for i=1:n_firms
        down_match_data[:,i] = down_data[:, match[i][2]]
    end

    down_match_profit_data =  Array{Float64, 1}(undef, n_firms)
    for i=1:n_firms
        down_match_profit_data[i] = down_profit_data[match[i][2]]
    end

    d_min_prof = 0.
    if sel_mode=="min"
        d_min_prof = findmin(down_match_profit_data)[1]
    elseif sel_mode == "median"
        d_min_prof = median(down_match_profit_data)
    elseif sel_mode == "mean"
        d_min_prof = mean(down_match_profit_data)
    end

    profit_diff = d_min_prof_input - d_min_prof
    down_match_profit_data .= down_match_profit_data .+ profit_diff
    up_profit_data .= up_profit_data .- profit_diff

    down_valuation = diag(up_data'*β_down*down_match_data) + up_data[1,:].* x_coeff

    down_prices = down_valuation - down_match_profit_data 
  
    return up_data, down_match_data, down_prices
end



