using Distributions
using Test
using DataFrames
using CSVFiles
using DataStructures

import GlobalSensitivityAnalysis: ishigami, split_output, sample

################################################################################
## JULIA
################################################################################

# define the (uncertain) parameters of the problem and their distributions
data = SobolData(
    params = OrderedDict(:x1 => Uniform(-3.14159265359, 3.14159265359),
        :x2 => Uniform(-3.14159265359, 3.14159265359),
        :x3 => Uniform(-3.14159265359, 3.14159265359)),
    N = 1000
)

N = data.N
D = length(data.params)

# sampling
julia_samples = sample(data) |> DataFrame
julia_ishigami = ishigami(convert(Matrix, julia_samples)) |> DataFrame

# analysis
julia_A, julia_B, julia_AB, julia_BA = split_output(convert(Matrix, julia_ishigami), N, D, data.calc_second_order)
julia_results = analyze(data, convert(Matrix, julia_ishigami); num_resamples = 10_000) 

################################################################################
## Python
################################################################################

# sampling
py_samples = load("data/sobol/py_uniform/py_samples.csv", header_exists=false, colnames = ["x1", "x2", "x3"]) |> DataFrame
py_ishigami = load("data/sobol/py_uniform/py_ishigami.csv", header_exists=false) |> DataFrame

# analysis
py_A = load("data/sobol/py_uniform/py_A.csv", header_exists=false) |> DataFrame
py_B = load("data/sobol/py_uniform/py_B.csv", header_exists=false) |> DataFrame
py_AB = load("data/sobol/py_uniform/py_AB.csv", header_exists=false) |> DataFrame
py_BA = load("data/sobol/py_uniform/py_BA.csv", header_exists=false) |> DataFrame

py_firstorder = load("data/sobol/py_uniform/py_firstorder.csv", header_exists=false) |> DataFrame
py_secondorder = load("data/sobol/py_uniform/py_secondorder.csv", header_exists=false) |> DataFrame
py_totalorder = load("data/sobol/py_uniform/py_totalorder.csv", header_exists=false) |> DataFrame

py_firstorder_conf = load("data/sobol/py_uniform/py_firstorder_conf.csv", header_exists=false) |> DataFrame
py_secondorder_conf = load("data/sobol/py_uniform/py_secondorder_conf.csv", header_exists=false) |> DataFrame
py_totalorder_conf = load("data/sobol/py_uniform/py_totalorder_conf.csv", header_exists=false) |> DataFrame

################################################################################
## Testing
################################################################################

@testset "Uniform Sampling" begin
    @test convert(Matrix, julia_samples) ≈ convert(Matrix, py_samples) atol = ATOL_sobol
end

@testset "Uniform Analysis" begin
    @test convert(Matrix, julia_ishigami) ≈ convert(Matrix, py_ishigami) atol = ATOL_sobol
    @test julia_A ≈ convert(Matrix, py_A) atol = ATOL_sobol
    @test julia_B ≈ convert(Matrix, py_B) atol = ATOL_sobol
    @test julia_AB ≈ convert(Matrix, py_AB) atol = ATOL_sobol
    @test julia_BA ≈ convert(Matrix, py_BA) atol = ATOL_sobol

    @test julia_results[:firstorder] ≈ convert(Matrix, py_firstorder) atol = ATOL_sobol
    @test julia_results[:totalorder] ≈ convert(Matrix, py_totalorder) atol = ATOL_sobol

    for i = 1:D
        for j = i+1:D
            @test julia_results[:secondorder][i,j] ≈ convert(Matrix, py_secondorder)[i,j] atol = ATOL_sobol
        end
    end

    # test confidence intervals
    @test julia_results[:firstorder_conf] ≈ convert(Matrix, py_firstorder_conf) atol = ATOL_CI
    @test julia_results[:totalorder_conf] ≈ convert(Matrix, py_totalorder_conf) atol = ATOL_CI

    for i = 1:D
        for j = i+1:D
            @test julia_results[:secondorder_conf][i,j] ≈ convert(Matrix, py_secondorder_conf)[i,j] atol = ATOL_CI
        end
    end
end