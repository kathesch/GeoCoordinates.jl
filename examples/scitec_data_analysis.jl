using GLMakie, DataFrames, CSV, ShiftedArrays, FileIO, GeoCoordinates
using Downloads: download

#Data Import

df = CSV.File("../data/SciTec_code_problem_data.csv", header=["T","ϕ","λ","h"]) |> DataFrame

transform!(df, :h => ByRow(x->1000*x) => :h)
transform!(df, [:ϕ, :λ, :h] => ByRow(lla2xyz) => :P)
transform!(df, :P => [:X,:Y,:Z])
transform!(df, :T => (x->x - lag(x, default=x[1] - 1)) => :dT)
transform!(df, :P => (x->x - lag(x,default=x[1])) => :dP)
transform!(df, [:dP,:dT] => ByRow(./) => :V)
transform!(df, :V => [:Vx, :Vy, :Vz])

t1 = 1532334000
t2 = 1532335268

v1 = lin_interp(t1, df.T,df.V)
v2 = lin_interp(t2, df.T,df.V)

p1 = lin_interp(t1, df.T,df.P)
p2 = lin_interp(t2, df.T,df.P)

earth_img = load(download("https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Blue_Marble_Next_Generation_+_topography_+_bathymetry.jpg/1024px-Blue_Marble_Next_Generation_+_topography_+_bathymetry.jpg"))

n = 512
lats = LinRange(90,-90, n) 
longs = LinRange(-180,180, 2 * n)
pos = [lla2xyz(ϕ,λ,0.) for ϕ in lats, λ in longs]
x,y,z = [[i[j] for i in pos] for j in 1:3]


begin
    f = Figure(resolution=(4000,4000),backgroundcolor=:grey2)
    ax = Axis3(f[1,1],viewmode=:fit,aspect=:data,
        elevation=deg2rad(20),azimuth=deg2rad(-50),backgroundcolor="#748AA6")
    hidedecorations!(ax)
    hidespines!(ax)
    
    surface!(ax, x,y,z,color=earth_img)
    lines!(ax,df.P .|> Point3, color=:red,linewidth=2)
    
    
    
    ts = Observable(1)
    dp = @lift([df.P[$ts] |> Point3])
    dv = @lift([df.V[$ts]*500 |> Point3])
    scatter!(ax, dp, color=:darkorange, markersize=10)
    quiver!(ax, dp, dv, color=:darkorange,linewidth=20000*2, arrowsize=100000)
    #=
    n = 20
    quiver!(ax,df.P[1:n:end] .|> x->Point3(x), df.V[1:n:end] .|> x->Point3(x) .* 1000,
        color=:violet,linewidth=10000*2,
        arrowsize=100000)
    scatter!(ax,[p1,p2] .|> Point3, color=:orange, markersize=10)
    quiver!(ax,[p1,p2] .|> Point3, [v1,v2] .|> x->Point3(x) .* 1000,
        color=:orange,linewidth=20000*2,
        arrowsize=100000)
    =#

    f
end

record(f,"earth_spin.gif",1:100,framerate=60) do i
    ax.azimuth[] = mod2pi(-0.001*i + deg2rad(-50))
    ts[] = mod1(i*5,length(df.P))
end

save("earth_viz.png",f)
=#