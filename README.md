# GeoCoordinates

## Installation

* Install Julia v1.7.0 or greater from JuliaLang.org's [downloads page](https://julialang.org/downloads/). 

* Run Julia in terminal

  * The default Github API has changed to use Personal Access Tokens, so you will need to type ``` ENV["JULIA_PKG_USE_CLI_GIT"]=true ``` into the REPL to import from a private repository without generating a PAT first. 
  

  * The Julia package manager REPL can be accessed by typing ```]``` into the default REPL and then ```add https://github.com/kathesch/GeoCoordinates.jl``` 
  
  * Alternatively, you can use ```import Pkg; Pkg.add(url="https://github.com/kathesch/GeoCoordinates.jl")```

* API references can be accessed via the help REPL by typing ```?``` followed by the function you are interested in seeing the docstring for. 

```
~ % julia

   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.9.0-DEV.1074 (2022-08-02)
 _/ |\__'_|_|_|\__'_|  |  Commit eedf3f150c (2 days old master)
|__/                   |
```
```julia
julia> ENV["JULIA_PKG_USE_CLI_GIT"]=true
(@v1.9) pkg> add https://github.com/kathesch/GeoCoordinates.jl
julia> using GeoCoordinates
```

## API



## Example Plots

![image](./examples/earth_spin.gif)

![image2](./examples/earth_viz.png)