module SweepOperator
export sweep!

#--------------------------------------------------------------------# sweep! methods
"""
`sweep!(A, k, inv = false)`

Symmetric sweep operator of the matrix `A` on element `k`.  `A` is overwritten.
`inv = true` will perform the inverse sweep.  Only the upper triangle is read and swept.

```julia
x = randn(100, 10)
xtx = x'x
sweep!(xtx, 1)
sweep!(xtx, 1, true)
```
"""
function sweep!{T<:Number}(A::AbstractMatrix{T}, k::Integer, inv::Bool = false)
    n, p = size(A)
    # ensure @inbounds is safe
    @assert n == p "A must be square"
    @assert k <= p "pivot element not within range"
    @inbounds d = 1.0 / A[k, k]  # pivot
    # get column A[:, k] (hack because only upper triangle is available)
    akk = zeros(p)
    for j in 1:k
        @inbounds akk[j] = A[j, k]
    end
    for j in k+1:p
        @inbounds akk[j] = A[k, j]
    end
    # for j in 1:p
    #     if j <= k
    #         @inbounds akk[j] = A[j, k]
    #     else
    #         @inbounds akk[j] = A[k, j]
    #     end
    # end
    BLAS.syrk!('U', 'N', -d, akk, 1.0, A)  # everything not in col/row k
    scale!(akk, d * (-1.0) ^ inv)
    for i in 1:k-1  # col k
        @inbounds A[i, k] = akk[i]
    end
    for j in k+1:p  # row k
        @inbounds A[k, j] = akk[j]
    end
    A[k, k] = -d  # pivot element
    A
end

function sweep!{T<:Number, I<:Integer}(A::AbstractMatrix{T}, ks::AbstractVector{I}, inv::Bool = false)
    for k in ks
        sweep!(A, k, inv)
    end
    A
end

end # module