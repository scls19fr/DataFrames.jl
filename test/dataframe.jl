module TestDataFrame
    using Base.Test
    using DataFrames, Compat
    import Compat.String

    #
    # Equality
    #

    @test isequal(DataFrame(a=[1, 2, 3], b=[4, 5, 6]), DataFrame(a=[1, 2, 3], b=[4, 5, 6]))
    @test !isequal(DataFrame(a=[1, 2], b=[4, 5]), DataFrame(a=[1, 2, 3], b=[4, 5, 6]))
    @test !isequal(DataFrame(a=[1, 2, 3], b=[4, 5, 6]), DataFrame(a=[1, 2, 3]))
    @test !isequal(DataFrame(a=[1, 2, 3], b=[4, 5, 6]), DataFrame(a=[1, 2, 3], c=[4, 5, 6]))
    @test !isequal(DataFrame(a=[1, 2, 3], b=[4, 5, 6]), DataFrame(b=[4, 5, 6], a=[1, 2, 3]))
    @test !isequal(DataFrame(a=[1, 2, 2], b=[4, 5, 6]), DataFrame(a=[1, 2, 3], b=[4, 5, 6]))
    @test isequal(DataFrame(a=Nullable{Int}[1, 2, Nullable()], b=[4, 5, 6]),
                  DataFrame(a=Nullable{Int}[1, 2, Nullable()], b=[4, 5, 6]))

    @test get(DataFrame(a=[1, 2, 3], b=[4, 5, 6]) == DataFrame(a=[1, 2, 3], b=[4, 5, 6]))
    @test get(DataFrame(a=[1, 2], b=[4, 5]) != DataFrame(a=[1, 2, 3], b=[4, 5, 6]))
    @test get(DataFrame(a=[1, 2, 3], b=[4, 5, 6]) != DataFrame(a=[1, 2, 3]))
    @test get(DataFrame(a=[1, 2, 3], b=[4, 5, 6]) != DataFrame(a=[1, 2, 3], c=[4, 5, 6]))
    @test get(DataFrame(a=[1, 2, 3], b=[4, 5, 6]) != DataFrame(b=[4, 5, 6], a=[1, 2, 3]))
    @test get(DataFrame(a=[1, 2, 2], b=[4, 5, 6]) != DataFrame(a=[1, 2, 3], b=[4, 5, 6]))
    @test get(DataFrame(a=Nullable{Int}[1, 3, Nullable()], b=[4, 5, 6]) !=
              DataFrame(a=Nullable{Int}[1, 2, Nullable()], b=[4, 5, 6]))
    @test isnull(DataFrame(a=Nullable{Int}[1, 2, Nullable()], b=[4, 5, 6]) ==
                 DataFrame(a=Nullable{Int}[1, 2, Nullable()], b=[4, 5, 6]))
    @test isnull(DataFrame(a=Nullable{Int}[1, 2, Nullable()], b=[4, 5, 6]) ==
                 DataFrame(a=Nullable{Int}[1, 2, 3], b=[4, 5, 6]))

    #
    # Copying
    #

    df = DataFrame(a = [2, 3], b = Any[DataFrame(c = 1), DataFrame(d = 2)])
    dfc = copy(df)
    dfdc = deepcopy(df)

    df[1, :a] = 4
    get(df[1, :b])[:e] = 5
    names!(df, [:f, :g])

    @test names(dfc) == [:a, :b]
    @test names(dfdc) == [:a, :b]

    @test get(dfc[1, :a]) === 4
    @test get(dfdc[1, :a]) === 2

    @test names(get(dfc[1, :b])) == [:c, :e]
    @test names(get(dfdc[1, :b])) == [:c]

    #

    x = DataFrame(a = [1, 2, 3], b = [4, 5, 6])
    v = DataFrame(a = [5, 6, 7], b = [8, 9, 10])

    z = vcat(v, x)

    z2 = z[:, [1, 1, 2]]
    @test names(z2) == [:a, :a_1, :b]

    #test_group("DataFrame assignment")
    # Insert single column
    x0 = x[Int[], :]
    @test_throws ErrorException x0[:d] = [1]
    @test_throws ErrorException x0[:d] = 1:3

    # Insert single value
    x[:d] = 3
    @test get(x[:d] == NullableArray([3, 3, 3]))

    x0[:d] = 3
    @test x0[:d] == Int[]

    # similar / nulls
    df = DataFrame(a = 1, b = "b", c = NominalArray([3.3]))
    nulldf = DataFrame(a = NullableArray(Int, 2),
                       b = NullableArray(String, 2),
                       c = NullableNominalArray(Float64, 2))
    @test isequal(nulldf, similar(df, 2))
    @test isequal(nulldf, DataFrames.similar_nullable(df, 2))

    # Associative methods

    df = DataFrame(a=[1, 2], b=[3., 4.])
    @test haskey(df, :a)
    @test !haskey(df, :c)
    @test get(df, :a, -1) === df.columns[1]
    @test get(df, :c, -1) == -1
    @test !isempty(df)

    @test empty!(df) === df
    @test isempty(df.columns)
    @test isempty(df)

    df = DataFrame(a=[1, 2], b=[3., 4.])
    @test_throws BoundsError insert!(df, 5, ["a", "b"], :newcol)
    @test_throws ErrorException insert!(df, 1, ["a"], :newcol)
    # FIXME: should we convert to NullableArray automatically?
    @test get(insert!(df, 1, NullableArray(["a", "b"]), :newcol) == df)
    @test isequal(df, DataFrame(newcol=["a", "b"], a=[1, 2], b=[3., 4.]))
    df = DataFrame(a=[1, 2], b=[3., 4.])
    # FIXME: should we convert to NullableArray automatically?
    @test get(insert!(df, 3, NullableArray(["a", "b"]), :newcol) == df)
    @test isequal(df, DataFrame(a=[1, 2], b=[3., 4.], newcol=["a", "b"]))

    df = DataFrame(a=[1, 2], b=[3., 4.])
    df2 = DataFrame(b=["a", "b"], c=[:c, :d])
    @test get(merge!(df, df2) == df)
    @test isequal(df, DataFrame(a=[1, 2], b=["a", "b"], c=[:c, :d]))

    #test_group("Empty DataFrame constructors")
    df = DataFrame(Int, 10, 3)
    @test size(df, 1) == 10
    @test size(df, 2) == 3
    @test typeof(df[:, 1]) == NullableVector{Int}
    @test typeof(df[:, 2]) == NullableVector{Int}
    @test typeof(df[:, 3]) == NullableVector{Int}
    @test allnull(df[:, 1])
    @test allnull(df[:, 2])
    @test allnull(df[:, 3])

    df = DataFrame(Any[Int, Float64, String], 100)
    @test size(df, 1) == 100
    @test size(df, 2) == 3
    @test typeof(df[:, 1]) == NullableVector{Int}
    @test typeof(df[:, 2]) == NullableVector{Float64}
    @test typeof(df[:, 3]) == NullableVector{String}
    @test allnull(df[:, 1])
    @test allnull(df[:, 2])
    @test allnull(df[:, 3])

    df = DataFrame(Any[Int, Float64, String], [:A, :B, :C], 100)
    @test size(df, 1) == 100
    @test size(df, 2) == 3
    @test typeof(df[:, 1]) == NullableVector{Int}
    @test typeof(df[:, 2]) == NullableVector{Float64}
    @test typeof(df[:, 3]) == NullableVector{String}
    @test allnull(df[:, 1])
    @test allnull(df[:, 2])
    @test allnull(df[:, 3])


    df = DataFrame(DataType[Int, Float64, Compat.UTF8String],[:A, :B, :C], [false,false,true],100)
    @test size(df, 1) == 100
    @test size(df, 2) == 3
    @test typeof(df[:, 1]) == NullableVector{Int}
    @test typeof(df[:, 2]) == NullableVector{Float64}
    @test typeof(df[:, 3]) == NullableNominalVector{Compat.UTF8String,UInt32}
    @test allnull(df[:, 1])
    @test allnull(df[:, 2])
    @test allnull(df[:, 3])


    df = convert(DataFrame, zeros(10, 5))
    @test size(df, 1) == 10
    @test size(df, 2) == 5
    @test typeof(df[:, 1]) == Vector{Float64}

    df = convert(DataFrame, ones(10, 5))
    @test size(df, 1) == 10
    @test size(df, 2) == 5
    @test typeof(df[:, 1]) == Vector{Float64}

    df = convert(DataFrame, eye(10, 5))
    @test size(df, 1) == 10
    @test size(df, 2) == 5
    @test typeof(df[:, 1]) == Vector{Float64}

    #test_group("Other DataFrame constructors")
    df = DataFrame([@compat(Dict{Any,Any}(:a=>1, :b=>'c')),
                    @compat(Dict{Any,Any}(:a=>3, :b=>'d')),
                    @compat(Dict{Any,Any}(:a=>5))])
    @test size(df, 1) == 3
    @test size(df, 2) == 2
    @test typeof(df[:,:a]) == NullableVector{Int}
    @test typeof(df[:,:b]) == NullableVector{Char}

    df = DataFrame([@compat(Dict{Any,Any}(:a=>1, :b=>'c')),
                    @compat(Dict{Any,Any}(:a=>3, :b=>'d')),
                    @compat(Dict{Any,Any}(:a=>5))],
                   [:a, :b])
    @test size(df, 1) == 3
    @test size(df, 2) == 2
    @test typeof(df[:,:a]) == NullableVector{Int}
    @test typeof(df[:,:b]) == NullableVector{Char}


    # This assignment was missing before
    df = DataFrame(Column = [:A])
    df[1, :Column] = "Testing"

    # zero-row dataframe and subdataframe test
    df = DataFrame(x=[], y=[])
    @test nrow(df) == 0
    df = DataFrame(x=[1:3;], y=[3:5;])
    sdf = sub(df, df[:x] .== 4)
    @test size(sdf, 1) == 0

    @test hash(convert(DataFrame, [1 2; 3 4])) == hash(convert(DataFrame, [1 2; 3 4]))
    @test hash(convert(DataFrame, [1 2; 3 4])) != hash(convert(DataFrame, [1 3; 2 4]))


    # push!(df, row)
    df=DataFrame( first=[1,2,3], second=["apple","orange","pear"] )

    dfb= DataFrame( first=[1,2], second=["apple","orange"] )
    push!(dfb, Any[3,"pear"])
    @test get(df==dfb)

    dfb= DataFrame( first=[1,2], second=["apple","orange"] )
    push!(dfb, (3,"pear"))
    @test get(df==dfb)

    dfb= DataFrame( first=[1,2], second=["apple","orange"] )
    @test_throws ArgumentError push!(dfb, (33.33,"pear"))

    dfb= DataFrame( first=[1,2], second=["apple","orange"] )
    @test_throws ArgumentError push!(dfb, ("coconut",22))

    dfb= DataFrame( first=[1,2], second=["apple","orange"] )
    push!(dfb, @compat(Dict(:first=>3, :second=>"pear")))
    @test get(df==dfb)

    df=DataFrame( first=[1,2,3], second=["apple","orange","banana"] )
    dfb= DataFrame( first=[1,2], second=["apple","orange"] )
    push!(dfb, @compat(Dict("first"=>3, "second"=>"banana")))
    @test get(df==dfb)

    df0= DataFrame( first=[1,2], second=["apple","orange"] )
    dfb= DataFrame( first=[1,2], second=["apple","orange"] )
    @test_throws ArgumentError push!(dfb, @compat(Dict(:first=>true, :second=>false)))
    @test get(df0==dfb)

    df0= DataFrame( first=[1,2], second=["apple","orange"] )
    dfb= DataFrame( first=[1,2], second=["apple","orange"] )
    @test_throws ArgumentError push!(dfb, @compat(Dict("first"=>"chicken", "second"=>"stuff")))
    @test get(df0==dfb)

    # delete!
    df = DataFrame(a=1, b=2, c=3, d=4, e=5)
    @test_throws ArgumentError delete!(df, 0)
    @test_throws ArgumentError delete!(df, 6)
    @test_throws KeyError delete!(df, :f)

    d = copy(df)
    delete!(d, [:a, :e, :c])
    @test names(d) == [:b, :d]
    delete!(d, :b)
    @test isequal(d, df[[:d]])

    d = copy(df)
    delete!(d, [2, 5, 3])
    @test names(d) == [:a, :d]
    delete!(d, 2)
    @test isequal(d, df[[:a]])

    # deleterows!
    df = DataFrame(a=[1, 2], b=[3., 4.])
    @test deleterows!(df, 1) === df
    @test isequal(df, DataFrame(a=[2], b=[4.]))

    df = DataFrame(a=[1, 2], b=[3., 4.])
    @test deleterows!(df, 2) === df
    @test isequal(df, DataFrame(a=[1], b=[3.]))

    df = DataFrame(a=[1, 2, 3], b=[3., 4., 5.])
    @test deleterows!(df, 2:3) === df
    @test isequal(df, DataFrame(a=[1], b=[3.]))

    df = DataFrame(a=[1, 2, 3], b=[3., 4., 5.])
    @test deleterows!(df, [2, 3]) === df
    @test isequal(df, DataFrame(a=[1], b=[3.]))

    df = DataFrame(a=NullableArray([1, 2]), b=NullableArray([3., 4.]))
    @test deleterows!(df, 1) === df
    @test isequal(df, DataFrame(a=NullableArray([2]), b=NullableArray([4.])))

    df = DataFrame(a=NullableArray([1, 2]), b=NullableArray([3., 4.]))
    @test deleterows!(df, 2) === df
    @test isequal(df, DataFrame(a=NullableArray([1]), b=NullableArray([3.])))

    df = DataFrame(a=NullableArray([1, 2, 3]), b=NullableArray([3., 4., 5.]))
    @test deleterows!(df, 2:3) === df
    @test isequal(df, DataFrame(a=NullableArray([1]), b=NullableArray([3.])))

    df = DataFrame(a=NullableArray([1, 2, 3]), b=NullableArray([3., 4., 5.]))
    @test deleterows!(df, [2, 3]) === df
    @test isequal(df, DataFrame(a=NullableArray([1]), b=NullableArray([3.])))

    # describe
    #suppress output and test that describe() does not throw
    devnull = @unix? "/dev/null" : "nul"
    open(devnull, "w") do f
        @test nothing == describe(f, DataFrame(a=[1, 2], b=Any["3", Nullable()]))
        @test nothing ==
              describe(f, DataFrame(a=NullableArray([1, 2]),
                                    b=NullableArray(Nullable{String}["3", Nullable()])))
        @test nothing ==
              describe(f, DataFrame(a=NominalArray([1, 2]),
                                    b=NullableNominalArray(Nullable{String}["3", Nullable()])))
        @test nothing == describe(f, [1, 2, 3])
        @test nothing == describe(f, NullableArray([1, 2, 3]))
        @test nothing == describe(f, NominalArray([1, 2, 3]))
        @test nothing == describe(f, Any["1", "2", Nullable()])
        @test nothing == describe(f, NullableArray(Nullable{String}["1", "2", Nullable()]))
        @test nothing == describe(f, NullableNominalArray(Nullable{String}["1", "2", Nullable()]))
    end
        
    #Check the output of unstack
    df = DataFrame(Fish = ["Bob", "Bob", "Batman", "Batman"], 
        Key = ["Mass", "Color", "Mass", "Color"], 
        Value = ["12 g", "Red", "18 g", "Grey"])
    #Unstack specifying a row column
    df2 = unstack(df,:Fish, :Key, :Value)
    #Unstack without specifying a row column
    df3 = unstack(df,:Key, :Value)
    #The expected output
    # FIXME: NominalArray keep levels in their order of appearance, while PDAs sort them
    #        Decide what's best.
    df4 = DataFrame(Fish = ["Bob", "Batman"], Mass = ["12 g", "18 g"], Color = ["Red", "Grey"])
    @test get(df2 == df4)
    @test get(df3 == df4)
end
