module GeoCoordinates

export
    Datum,
    lla2xyz,xyz2lla,
    lin_interp

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

function N(ϕ, datum=Datum())
    (;a,e) = datum
    return a / √(1 - e^2 * sind(ϕ)^2)
end

function lla2xyz(ϕ,λ,h; datum=Datum())
    (;a,b) = datum

    X = (N(ϕ) + h) * cosd(ϕ) * cosd(λ)
    Y = (N(ϕ) + h) * cosd(ϕ) * sind(λ)
    Z = (b^2/a^2 * N(ϕ) + h) * sind(ϕ)

    return [X,Y,Z]
end

lla2xyz(xyz) = lla2xyz(xyz...)

function xyz2phih(X,Y,Z; datum=Datum(), atol=1E-6)
    (;e) = datum

    p = √(X^2 + Y^2)
    h = 0.
    ϕ = atand(Z / (p * (1 - e^2)))

    ϕ_old = 0
    h_old = 0

    while !(isapprox(ϕ_old, ϕ, atol=atol) && isapprox(h_old, h, atol=atol))
        ϕ_old = ϕ
        h_old = h
        h = p / cosd(ϕ) - N(ϕ)
        ϕ = atand(Z / (p * (1-e^2 * N(ϕ) / (N(ϕ) + h))))
    end

    return ϕ,h
end

function xyz2lla(X,Y,Z; datum=Datum(), atol=1E-6)  

    ϕ,h = xyz2phih(X,Y,Z, datum=datum, atol=atol)
    λ = atand(Y/X)

    return [ϕ,λ,h]
end

xyz2lla(lla) = xyz2lla(lla...)

function triangle(x, a=-1, m=0, b=1)
    if x > a && x <= m
        1/(m-a)*(x-a)
    elseif x > m && x < b
        1/(b-m)*(b-x)
    else
        0.
    end
end

function lin_interp(t,xs,ys)
    pxs = [0; xs; 0]
    ys .* [triangle(t, pxs[i], pxs[i+1], pxs[i+2]) for i in LinearIndices(xs)] |> sum
end
end