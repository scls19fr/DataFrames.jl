module DataFrames

##############################################################################
##
## Dependencies
##
##############################################################################

using Compat
import Compat.String
using Reexport
@reexport using StatsBase
@reexport using NullableArrays
@reexport using CategoricalArrays
using GZip
using SortingAlgorithms
using Base: Sort, Order
using Docile

@document

##############################################################################
##
## Exported methods and types (in addition to everything reexported above)
##
##############################################################################

export @~,
       @csv_str,
       @csv2_str,
       @tsv_str,
       @wsv_str,

       AbstractDataFrame,
       DataFrame,
       DataFrameRow,
       Formula,
       GroupApplied,
       GroupedDataFrame,
       ModelFrame,
       ModelMatrix,
       SubDataFrame,

       aggregate,
       by,
       coefnames,
       colwise,
       combine,
       complete_cases,
       complete_cases!,
       deleterows!,
       describe,
       eachcol,
       eachrow,
       eltypes,
       groupby,
       melt,
       meltdf,
       names!,
       ncol,
       nonunique,
       nrow,
       nullable!,
       order,
       pool,
       pool!,
       printtable,
       readtable,
       rename!,
       rename,
       showcols,
       stack,
       stackdf,
       unique!,
       unstack,
       writetable,
       # FIXME: unexport, these should go in Base or nowhere
       head,
       tail

    # FIXME
    using Compat
    @compat function Base.:(==){S<:Nullable,T<:Nullable}(A::AbstractArray{S}, B::AbstractArray{T})
        if size(A) != size(B)
            return Nullable(false)
        end
        if isa(A,Range) != isa(B,Range)
            return Nullable(false)
        end
        eq = Nullable(true)
        for (a, b) in zip(A, B)
            el_eq = a == b
            get(el_eq, true) || return Nullable(false)
            eq &= el_eq
        end
        return eq
    end

    for f in (
        :(@compat Base.:(==)),
        :(@compat Base.:!=),
    )
        @eval begin
            function $(f){S1, S2}(x::Nullable{S1}, y::Nullable{S2})
                if isnull(x) || isnull(y)
                    Nullable{Bool}()
                else
                    Nullable{Bool}($(f)(x.value, y.value))
                end
            end
        end
    end

    # FIXME: to remove, == currently throws an error for Nullables
    Base.:(==)(x::Nullable, y::Nullable) = isequal(x, y)

    # For NullableCategoricalArrays (specialized version could be faster)
    NullableArrays.allnull{T<:Nullable}(x::AbstractArray{T}) = all(isnull, x)


    _dropnull(x::Any) = x
    _dropnull{T<:Nullable}(x::AbstractArray{T}) = dropnull(x)

    _isnull(x::Any) = false
    _isnull(x::Nullable) = isnull(x)

    Base.isless(x::Nullable, y::Nullable) = get(x < y)

##############################################################################
##
## Load files
##
##############################################################################

for (dir, filename) in [
        ("other", "utils.jl"),
        ("other", "index.jl"),

        ("abstractdataframe", "abstractdataframe.jl"),
        ("dataframe", "dataframe.jl"),
        ("subdataframe", "subdataframe.jl"),
        ("groupeddataframe", "grouping.jl"),
        ("dataframerow", "dataframerow.jl"),

        ("abstractdataframe", "iteration.jl"),
        ("abstractdataframe", "join.jl"),
        ("abstractdataframe", "reshape.jl"),

        ("abstractdataframe", "io.jl"),
        ("dataframe", "io.jl"),

        ("abstractdataframe", "show.jl"),
        ("groupeddataframe", "show.jl"),
        ("dataframerow", "show.jl"),

        ("abstractdataframe", "sort.jl"),
        ("dataframe", "sort.jl"),

        ("statsmodels", "formula.jl"),
        ("statsmodels", "statsmodel.jl"),

        ("", "deprecated.jl")
    ]

    include(joinpath(dir, filename))
end

end # module DataFrames
