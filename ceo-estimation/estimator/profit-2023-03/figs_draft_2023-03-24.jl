
xlab=L"x"
ylab = L"\hat{\alpha}_\varepsilon"
p1 = scatter(up[1,:], epsbar_vec, markersize=1, xlims=(0,4),legend=false,dpi=300,
    xlabel="x", ylabel =ylab  
)

xlab=L"\varepsilon"
ylab = L"\hat{\alpha}_\varepsilon"
    
p2 = scatter(up[2,:], epsbar_vec, markersize=1, xlims=(0,1),legend=false, smooth=true, dpi=300, linecolor=:yellow,
    xlabel = xlab, ylabel =ylab
)


plot(p1,p2, layout=(1,2))
savefig("/Users/amir/github/paper/figures/alphaepshat_epsilon.png")

################################
#################################
##################################
##################################



ylab = L"\bar{\Phi}_x(x_i, \bar{\varepsilon}_i, y_{1,i}, y_{2,i})"
# scatter(up[1,:], der_vec, markersize=2, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, ylims=(-10,10), dpi=300,
    # color=:black)
scatter(up[1,:], ders_truth, markersize=3, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, dpi=300,
     color=:black, ylims=(0,10)
)

scatter!(up[1,:], der_vec, markersize=2, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, dpi=300,
    color=:orange
)
    
savefig("/Users/amir/github/paper/figures/ders_vs_ests.png")





#### DATA FIGS

xlab="CEO Experience"
ylab = L"\hat{\alpha}_\varepsilon"
p1 = scatter(up, epsbar_vec, markersize=1, xlims=(0,4),legend=false,dpi=300,
    xlabel=xlab, ylabel =ylab  
)
savefig("/Users/amir/github/paper/figures/DATA_alphaepshat.png")





ylab = L"\bar{\Phi}_x(Exper_i, \bar{\varepsilon}_i, Scope_{i}, Size_{2,i})"
scatter(up, der_vec, markersize=2, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, ylims=(-10,10), dpi=300,
    color=:black)
# scatter(up[1,:], ders_truth, markersize=3, xlims=(0,4), xlabel="x", ylabel=ylab, legend=false, dpi=300,
#      color=:black, ylims=(0,10)
)