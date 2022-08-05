module GeoCoordinates

export
    Datum,
    lla2xyz,xyz2lla,
    lin_interp


"""
    Datum(a=6378137, f=1/298.25722356)

Constructs a `Datum` type for use in coordinate transformations. 
Default values are the WSG84 semimajor axis `a`= 6378137 meters and the flattening factor `f`=1/298.25722356. 
"""
struct Datum
    a::Float64 #semimajor axis
    b::Float64 #semiminor axis
    f::Float64 #flattening factor
    e::Float64 #first eccentricity
    e′::Float64 #second eccentricity

    function Datum(a=6378137, f=1/298.25722356)
        b = a*(1-f)
        e = √((a^2-b^2) / a^2)
        e′= √((a^2-b^2) / b^2)

        return new(a,b,f,e,e′)
    end
end

#Radius of curvature (meters)
function N(ϕ, datum=Datum())
    (;a,e) = datum
    return a / √(1 - e^2 * sind(ϕ)^2)
end

"""
    lla2xyz(ϕ,λ,h; [datum=Datum()])
    lla2xyz(xyz) = lla2xyz(xyz...)

Takes coordinates in LLA format (latitude=ϕ, longitude=λ, altitude=h) to ECEF format (X,Y,Z).
Latitudes and longitudes are taken as positive degree values being North and East respectively. 
Default `Datum` is WSG84. 
"""
function lla2xyz(ϕ, λ, h; datum=Datum())
    (;a,b) = datum

    X = (N(ϕ) + h) * cosd(ϕ) * cosd(λ)
    Y = (N(ϕ) + h) * cosd(ϕ) * sind(λ)
    Z = (b^2/a^2 * N(ϕ) + h) * sind(ϕ)

    return [X,Y,Z]
end

lla2xyz(xyz) = lla2xyz(xyz...)

#Iterative algorithm for returning latitude and altitude from ECEF (X,Y,Z) values. 
function xyz2phih(X, Y, Z; datum=Datum(), atol=1E-6)
    (;e) = datum

    p = √(X^2 + Y^2)
    h = 0.
    ϕ = atand(Z / (p * (1 - e^2)))

    ϕ_old = 0
    h_old = 0

    #While loop checks to see if ϕ and h are no longer changing to within atol tolernace. 
    while !(isapprox(ϕ_old, ϕ, atol=atol) && isapprox(h_old, h, atol=atol))
        ϕ_old = ϕ
        h_old = h
        h = p / cosd(ϕ) - N(ϕ)
        ϕ = atand(Z / (p * (1-e^2 * N(ϕ) / (N(ϕ) + h))))
    end

    return ϕ,h
end

"""
xyz2lla(X,Y,Z; [datum=Datum(), atol=1E-6])
xyz2lla(lla) = xyz2lla(lla...)

Takes coordinates in ECEF format (`X`,`Y`,`Z`) to LLA format (latitude=`ϕ`, longitude=`λ`, altitude=`h`).
`atol` provides an aboslute tolerance for the iterative algorithm to generate `ϕ` and `h`.
Default `Datum` is WSG84. 
"""
function xyz2lla(X, Y, Z; datum=Datum(), atol=1E-6)  

    ϕ,h = xyz2phih(X,Y,Z, datum=datum, atol=atol)
    λ = atand(Y/X)

    return [ϕ,λ,h]
end

xyz2lla(lla) = xyz2lla(lla...)

#=
A triangle "bump" function for use as a basis function in `lin_interp`. 
`a` and `b` are the x intercepts values of the triangle. 
`m` is the point where it reaches its highest value of `1`
=#
function triangle(x, a=-1, m=0, b=1)
    if x > a && x <= m
        1/(m-a)*(x-a)
    elseif x > m && x < b
        1/(b-m)*(b-x)
    else
        0.
    end
end

"""
lin_interp(t, xs, ys)

Returns the value of the linear interpolation of `ys` at value `t` in `xs`. `xs` and `ys` should be equal length arrays.
Uses triangular basis functions over `xs` scaled by the corresponding values in `ys` to generate an interpolating function for
some value `t`

Example
xs = [1,2,3,4]
ys = [6,7,8,9]

#arguments to `a`,`m`,`b` in `triangle` in parentheses
[0 1 2 3 4 0] = padded `xs` array
(0 1 2) * ys[1] +
  (1 2 3) * ys[2] +
    (2 3 4) * ys[3] +
      (3 4 0) * ys[4]
"""
function lin_interp(t, xs, ys)
    #constructs a padded array from `xs`
    pxs = [0; xs; 0]
    #Performs a convolution over `xs` of `ys` and the `triangle` basis functions. 
    ys .* [triangle(t, pxs[i], pxs[i+1], pxs[i+2]) for i in LinearIndices(xs)] |> sum
end

"""
    scitec_data(t)

Returns the velocity at the interpolated unix time `t` in the scitec data set. 
"""
function scitec_data(t)
    df = CSV.File("../data/SciTec_code_problem_data.csv", header=["T","ϕ","λ","h"]) |> DataFrame

    #converts altitude to meters
    transform!(df, :h => ByRow(x->1000*x) => :h)
    #converts latitude, longitude, altitude to XYZ position vectors 
    transform!(df, [:ϕ, :λ, :h] => ByRow(lla2xyz) => :P)
    #breaks XYZ positions into X, Y, Z vectors for easier plotting 
    transform!(df, :P => [:X,:Y,:Z])
    #computes differences in adjacents times for velocity calculation
    transform!(df, :T => (x->x - lag(x, default=x[1] - 1)) => :dT)
    #computes differences in adjacents positions for velocity calculation
    transform!(df, :P => (x->x - lag(x,default=x[1])) => :dP)
    #divides position difference by time differences to obtain velocity
    transform!(df, [:dP,:dT] => ByRow(./) => :V)
    #breaks V velocities into X, Y, Z vectors for easier plotting
    transform!(df, :V => [:Vx, :Vy, :Vz])

    return lin_interp(t1, df.T,df.V)
end

end