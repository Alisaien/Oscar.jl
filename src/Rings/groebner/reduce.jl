@doc raw"""
    reduce(I::IdealGens, J::IdealGens; 
          ordering::MonomialOrdering = default_ordering(base_ring(J)), complete_reduction::Bool = false)

Return a `Vector` whose elements are the underlying elements of `I`
reduced by the underlying generators of `J` w.r.t. the monomial
ordering `ordering`. `J` need not be a Gröbner basis. The returned
`Vector` will have the same number of elements as `I`, even if they
are zero.

# Examples
```jldoctest
julia> R, (x, y, z) = polynomial_ring(GF(11), [:x, :y, :z]);

julia> I = ideal(R, [x^2, x*y - y^2]);

julia> J = ideal(R, [y^3])
Ideal generated by
  y^3

julia> reduce(J.gens, I.gens)
1-element Vector{FqMPolyRingElem}:
 y^3

julia> reduce(J.gens, groebner_basis(I))
1-element Vector{FqMPolyRingElem}:
 0

julia> reduce(y^3, [x^2, x*y-y^3])
x*y

julia> reduce(y^3, [x^2, x*y-y^3], ordering=lex(R))
y^3

julia> reduce([y^3], [x^2, x*y-y^3], ordering=lex(R))
1-element Vector{FqMPolyRingElem}:
 y^3
```
"""
function reduce(I::IdealGens, J::IdealGens; ordering::MonomialOrdering = default_ordering(base_ring(J)), complete_reduction::Bool = false)
  @assert base_ring(J) == base_ring(I)
  Is = singular_generators(I, ordering)
  Js = singular_generators(J, ordering)
  res = reduce(Is, Js, complete_reduction=complete_reduction)
  return [J.gens.Ox(x) for x = gens(res)]
end

@doc raw"""
    reduce(g::T, F::Union{Vector{T}, IdealGens{T}};
           ordering::MonomialOrdering = default_ordering(g)), complete_reduction::Bool = false) where T <: MPolyRingElem

If `ordering` is global, return the remainder in a standard representation for `g` on division by the polynomials in `F` with respect to `ordering`.
Otherwise, return the remainder in a *weak* standard representation for `g` on division by the polynomials in `F` with respect to `ordering`.

    reduce(G::Vector{T}, F::Union{Vector{T}, IdealGens{T}};
           ordering::MonomialOrdering = default_ordering(parent(G[1])), complete_reduction::Bool = false) where T <: MPolyRingElem

Return a `Vector` which contains, for each element `g` of `G`, a remainder as above.

!!! note
    The returned remainders are fully reduced if `complete_reduction` is set to `true` and `ordering` is global.

!!! note
    The reduction strategy behind the `reduce` function and the reduction strategy behind the functions 
    `reduce_with_quotients` and `reduce_with_quotients_and_unit` differ. As a consequence, the computed
    remainders may differ.

# Examples
```jldoctest
julia> R, (z, y, x) = polynomial_ring(QQ, [:z, :y, :x]);

julia> f1 = y-x^2; f2 = z-x^3;

julia> g = x^3*y-3*y^2*z^2+x*y*z;

julia> reduce(g, [f1, f2], ordering = lex(R))
-3*x^10 + x^6 + x^5
```

```jldoctest
julia> R, (x, y, z) = polynomial_ring(QQ, [:x, :y, :z]);

julia> f1 = x^2+x^2*y; f2 = y^3+x*y*z; f3 = x^3*y^2+z^4;

julia> g = x^3*y+x^5+x^2*y^2*z^2+z^6;

julia> reduce(g, [f1, f2, f3], ordering = lex(R))
x^5 + x^3*y + x^2*y^2*z^2 + z^6

julia> reduce(g, [f1,f2, f3], ordering = lex(R), complete_reduction = true)
x^5 - x^3 + y^6 + z^6
```

"""
function reduce(f::T, F::Vector{T}; ordering::MonomialOrdering = default_ordering(parent(f)), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  isempty(F) && return f
  J = IdealGens(parent(F[1]), F, ordering)
  return reduce(f, J; ordering=ordering, complete_reduction=complete_reduction)
end

function reduce(F::Vector{T}, G::Vector{T}; ordering::MonomialOrdering = default_ordering(parent(F[1])), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  isempty(G) && return F
  J = IdealGens(parent(G[1]), G, ordering)
  return reduce(F, J; ordering=ordering, complete_reduction=complete_reduction)
end

function reduce(f::T, F::IdealGens{T}; ordering::MonomialOrdering = default_ordering(parent(f)), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  isempty(F) && return f
  @assert parent(f) == base_ring(F)
  R = parent(f)
  I = IdealGens(R, [f], ordering)
  redv = reduce(I, F, ordering=ordering, complete_reduction=complete_reduction)
  return redv[1]
end

function reduce(F::Vector{T}, G::IdealGens{T}; ordering::MonomialOrdering = default_ordering(parent(F[1])), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  (isempty(F) || isempty(G)) && return F
  @assert parent(F[1]) == base_ring(G)
  R = parent(F[1])
  I = IdealGens(R, F, ordering)
  return reduce(I, G, ordering=ordering, complete_reduction=complete_reduction)
end

@doc raw"""
    reduce_with_quotients_and_unit(g::T, F::Union{Vector{T}, IdealGens{T}};
           ordering::MonomialOrdering = default_ordering(parent(g)), complete_reduction::Bool = false) where T <: MPolyRingElem

Return the unit, the quotients and the remainder in a weak standard representation for `g` on division by the polynomials in `F` with respect to `ordering`.

    reduce_with_quotients_and_unit(G::Vector{T}, F::Union{Vector{T}, IdealGens{T}};
           ordering::MonomialOrdering = default_ordering(parent(G[1])), complete_reduction::Bool = false) where T <: MPolyRingElem

Return a `Vector` which contains, for each element `g` of `G`, a unit, quotients, and a remainder as above.

!!! note
    The returned remainders are fully reduced if `complete_reduction` is set to `true` and `ordering` is global.

!!! note
    The reduction strategy behind the `reduce` function and the reduction strategy behind the functions 
    `reduce_with_quotients` and `reduce_with_quotients_and_unit` differ. As a consequence, the computed
    remainders may differ.

# Examples
```jldoctest
julia> R, (x, y, z) = polynomial_ring(QQ, [:x, :y, :z]);

julia> f1 = x^2+x^2*y; f2 = y^3+x*y*z; f3 = x^3*y^2+z^4;

julia> g = x^3*y+x^5+x^2*y^2*z^2+z^6;

julia> u, Q, h =reduce_with_quotients_and_unit(g, [f1,f2, f3], ordering = lex(R));

julia> u
[1]

julia> G = [g, x*y^3-3*x^2*y^2*z^2];

julia> U, Q, H = reduce_with_quotients_and_unit(G, [f1, f2, f3], ordering = negdegrevlex(R));

julia> U
[y + 1       0]
[    0   y + 1]

julia> Q
[  x^3 - x*y^2*z^2 + x*y + y^2*z^2                            0   y*z^2 + z^2]
[x*y*z^2 + y^3*z - 3*y^2*z^2 - y*z   -x^2*y*z - x^2*z + x*y + x             0]

julia> H
2-element Vector{QQMPolyRingElem}:
 0
 0

julia> U*G == Q*[f1, f2, f3]+H
true
```
"""
function reduce_with_quotients_and_unit(f::T, F::Vector{T}; ordering::MonomialOrdering = default_ordering(parent(f)), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  if isempty(F)
    return identity_matrix(parent(f), 1), zero_matrix(parent(f), 1, 0), f
  end
  J = IdealGens(parent(F[1]), F, ordering)
  return reduce_with_quotients_and_unit(f, J; ordering=ordering, complete_reduction=complete_reduction)
end

function reduce_with_quotients_and_unit(F::Vector{T}, G::Vector{T}; ordering::MonomialOrdering = default_ordering(parent(F[1])), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  @assert !isempty(F)
  if isempty(G)
    return identity_matrix(parent(F[1]), length(F)), zero_matrix(parent(F[1]), length(F), 0), F
  end
  J = IdealGens(parent(G[1]), G, ordering)
  return reduce_with_quotients_and_unit(F, J; ordering=ordering, complete_reduction=complete_reduction)
end

function reduce_with_quotients_and_unit(f::T, F::IdealGens{T}; ordering::MonomialOrdering = default_ordering(parent(f)), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  if isempty(F)
    return identity_matrix(parent(f), 1), zero_matrix(parent(f), 1, 0), f
  end
  @assert parent(f) == base_ring(F)
  R = parent(f)
  I = IdealGens(R, [f], ordering)
  u, q, r = _reduce_with_quotients_and_unit(I, F, ordering, complete_reduction)
  return u, q, r[1]
end

function reduce_with_quotients_and_unit(F::Vector{T}, G::IdealGens{T}; ordering::MonomialOrdering = default_ordering(parent(F[1])), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  @assert !isempty(F)
  if isempty(G)
    return identity_matrix(parent(F[1]), length(F)), zero_matrix(parent(F[1]), length(F), 0), F
  end
  @assert parent(F[1]) == base_ring(G)
  R = parent(F[1])
  I = IdealGens(R, F, ordering)
  return _reduce_with_quotients_and_unit(I, G, ordering, complete_reduction)
end

@doc raw"""
    reduce_with_quotients_and_unit(I::IdealGens, J::IdealGens;
      ordering::MonomialOrdering = default_ordering(base_ring(J)), complete_reduction::Bool = false)

Return a `Tuple` consisting of a `Generic.MatSpaceElem` `M`, a
`Vector` `res` whose elements are the underlying elements of `I`
reduced by the underlying generators of `J` w.r.t. the monomial
ordering `ordering` and a diagonal matrix `units` such that `M *
gens(J) + res == units * gens(I)`. If `ordering` is global then
`units` will always be the identity matrix, see also
`reduce_with_quotients`. `J` need not be a Gröbner basis. `res` will
have the same number of elements as `I`, even if they are zero.

# Examples
```jldoctest
julia> R, (x, y) = polynomial_ring(GF(11), [:x, :y]);

julia> I = ideal(R, [x]);

julia> R, (x, y) = polynomial_ring(GF(11), [:x, :y]);

julia> I = ideal(R, [x]);

julia> J = ideal(R, [x+1]);

julia> unit, M, res = reduce_with_quotients_and_unit(I.gens, J.gens, ordering = neglex(R))
([x+1], [x], FqMPolyRingElem[0])

julia> M * gens(J) + res == unit * gens(I)
true

julia> f = x^3*y^2-y^4-10
x^3*y^2 + 10*y^4 + 1

julia> F = [x^2*y-y^3, x^3-y^4]
2-element Vector{FqMPolyRingElem}:
 x^2*y + 10*y^3
 x^3 + 10*y^4

julia> reduce_with_quotients_and_unit(f, F)
([1], [x*y 10*x+1], x^4 + 10*x^3 + 1)

julia> unit, M, res = reduce_with_quotients_and_unit(f, F, ordering=lex(R))
([1], [x*y 0], x*y^4 + 10*y^4 + 1)

julia> M * F + [res] == unit * [f]
true
```
"""
function reduce_with_quotients_and_unit(I::IdealGens, J::IdealGens; ordering::MonomialOrdering = default_ordering(base_ring(J)), complete_reduction::Bool = false)
  return _reduce_with_quotients_and_unit(I, J, ordering, complete_reduction)
end


@doc raw"""
    reduce_with_quotients(I::IdealGens, J::IdealGens; ordering::MonomialOrdering = default_ordering(base_ring(J)), complete_reduction::Bool = false)

Return a `Tuple` consisting of a `Generic.MatSpaceElem` `M` and a
`Vector` `res` whose elements are the underlying elements of `I`
reduced by the underlying generators of `J` w.r.t. the monomial
ordering `ordering` such that `M * gens(J) + res == gens(I)` if `ordering` is global.
If `ordering` is local then this equality holds after `gens(I)` has been multiplied
with an unknown diagonal matrix of units, see `reduce_with_quotients_and_unit` to
obtain this matrix. `J` need not be a Gröbner basis. `res` will have the same number
of elements as `I`, even if they are zero.

# Examples
```jldoctest
julia> R, (x, y, z) = polynomial_ring(GF(11), [:x, :y, :z]);

julia> J = ideal(R, [x^2, x*y - y^2]);

julia> I = ideal(R, [x*y, y^3]);

julia> gb = groebner_basis(J)
Gröbner basis with elements
  1 -> x*y + 10*y^2
  2 -> x^2
  3 -> y^3
with respect to the ordering
  degrevlex([x, y, z])

julia> M, res = reduce_with_quotients(I.gens, gb)
([1 0 0; 0 0 1], FqMPolyRingElem[y^2, 0])

julia> M * gens(gb) + res == gens(I)
true

julia> f = x^3*y^2-y^4-10
x^3*y^2 + 10*y^4 + 1

julia> F = [x^2*y-y^3, x^3-y^4]
2-element Vector{FqMPolyRingElem}:
 x^2*y + 10*y^3
 x^3 + 10*y^4

julia> reduce_with_quotients_and_unit(f, F)
([1], [x*y 10*x+1], x^4 + 10*x^3 + 1)

julia> unit, M, res = reduce_with_quotients_and_unit(f, F, ordering=lex(R))
([1], [x*y 0], x*y^4 + 10*y^4 + 1)

julia> M * F + [res] == unit * [f]
true
```
"""
function reduce_with_quotients(I::IdealGens, J::IdealGens; ordering::MonomialOrdering = default_ordering(base_ring(J)), complete_reduction::Bool = false)
    _, q, r = _reduce_with_quotients_and_unit(I, J, ordering, complete_reduction)
    return q, r
end

@doc raw"""
    reduce_with_quotients(g::T, F::Union{Vector{T}, IdealGens{T}};
           ordering::MonomialOrdering = default_ordering(parent(g)), complete_reduction::Bool = false) where T <: MPolyRingElem

If `ordering` is global, return the quotients and the remainder in a standard representation for `g` on division by the polynomials in `F` with respect to `ordering`.
Otherwise, return the quotients and the remainder in a *weak* standard representation for `g` on division by the polynomials in `F` with respect to `ordering`.

    reduce_with_quotients(G::Vector{T}, F::Union{Vector{T}, IdealGens{T}};
           ordering::MonomialOrdering = default_ordering(parent(G[1])), complete_reduction::Bool = false) where T <: MPolyRingElem

Return a `Vector` which contains, for each element `g` of `G`, quotients and a remainder as above.

!!! note
    The returned remainders are fully reduced if `complete_reduction` is set to `true` and `ordering` is global.

# Examples

```jldoctest
julia> R, (x, y, z) = polynomial_ring(QQ, [:x, :y, :z]);

julia> f1 = x^2+x^2*y; f2 = y^3+x*y*z; f3 = x^3*y^2+z^4;

julia> g = x^3*y+x^5+x^2*y^2*z^2+z^6;

julia> Q, h = reduce_with_quotients(g, [f1,f2, f3], ordering = lex(R));

julia> h
x^5 - x^3 + y^6 + z^6

julia> g == Q[1]*f1+Q[2]*f2+Q[3]*f3+h
true
```
"""
function reduce_with_quotients(f::T, F::Vector{T}; ordering::MonomialOrdering = default_ordering(parent(f)), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  isempty(F) && return zero_matrix(parent(f), 1, 0), f
  J = IdealGens(parent(F[1]), F, ordering)
  return reduce_with_quotients(f, J; ordering=ordering, complete_reduction=complete_reduction)
end

function reduce_with_quotients(F::Vector{T}, G::Vector{T}; ordering::MonomialOrdering = default_ordering(parent(F[1])), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  @assert !isempty(F)
  isempty(G) && return zero_matrix(parent(F[1]), length(F), 0), F
  J = IdealGens(parent(G[1]), G, ordering)
  return reduce_with_quotients(F, J; ordering=ordering, complete_reduction=complete_reduction)
end

function reduce_with_quotients(f::T, F::IdealGens{T}; ordering::MonomialOrdering = default_ordering(parent(f)), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  isempty(F) && return zero_matrix(parent(f), 1, 0), f
  @assert parent(f) == parent(F[1])
  R = parent(f)
  I = IdealGens(R, [f], ordering)
  _, q, r = _reduce_with_quotients_and_unit(I, F, ordering, complete_reduction)
  return q, r[1]
end

function reduce_with_quotients(F::Vector{T}, G::IdealGens{T}; ordering::MonomialOrdering = default_ordering(parent(F[1])), complete_reduction::Bool = false) where {T <: MPolyRingElem}
  @assert !isempty(F)
  isempty(G) && return zero_matrix(parent(F[1]), length(F), 0), F
  @assert parent(F[1]) == parent(G[1])
  R = parent(F[1])
  I = IdealGens(R, F, ordering)
  _, q, r = _reduce_with_quotients_and_unit(I, G, ordering, complete_reduction)
  return q, r
end

function _reduce_with_quotients_and_unit(I::IdealGens, J::IdealGens, ordering::MonomialOrdering = default_ordering(base_ring(J)), complete_reduction::Bool = complete_reduction)
  @assert base_ring(J) == base_ring(I)
  sI = singular_generators(I, ordering)
  sJ = singular_generators(J, ordering)
  res = Singular.divrem2(sI, sJ, complete_reduction=complete_reduction)
  return matrix(base_ring(I), res[3]), matrix(base_ring(I), res[1]), [J.gens.Ox(x) for x = gens(res[2])]
end

@doc raw"""
    normal_form(g::T, I::MPolyIdeal; 
      ordering::MonomialOrdering = default_ordering(base_ring(I))) where T <: MPolyRingElem

Compute the normal form of `g` mod `I` with respect to `ordering`.

    normal_form(G::Vector{T}, I::MPolyIdeal; 
      ordering::MonomialOrdering = default_ordering(base_ring(I))) where T <: MPolyRingElem

Return a `Vector` which contains for each element `g` of `G` a normal form as above.

# Examples
```jldoctest
julia> R,(a,b,c) = polynomial_ring(QQ,[:a,:b,:c])
(Multivariate polynomial ring in 3 variables over QQ, QQMPolyRingElem[a, b, c])

julia> J = ideal(R,[-1+c+b,-1+b+c*a+2*a*b])
Ideal generated by
  b + c - 1
  2*a*b + a*c + b - 1

julia> gens(groebner_basis(J))
2-element Vector{QQMPolyRingElem}:
 b + c - 1
 a*c - 2*a + c

julia> normal_form(-1+c+b+a^3, J)
a^3

julia> R,(a,b,c) = polynomial_ring(QQ,[:a,:b,:c])
(Multivariate polynomial ring in 3 variables over QQ, QQMPolyRingElem[a, b, c])

julia> A = [-1+c+b+a^3,-1+b+c*a+2*a^3,5+c*b+c^2*a]
3-element Vector{QQMPolyRingElem}:
 a^3 + b + c - 1
 2*a^3 + a*c + b - 1
 a*c^2 + b*c + 5

julia> J = ideal(R,[-1+c+b,-1+b+c*a+2*a*b])
Ideal generated by
  b + c - 1
  2*a*b + a*c + b - 1

julia> gens(groebner_basis(J))
2-element Vector{QQMPolyRingElem}:
 b + c - 1
 a*c - 2*a + c

julia> normal_form(A, J)
3-element Vector{QQMPolyRingElem}:
 a^3
 2*a^3 + 2*a - 2*c
 4*a - 2*c^2 - c + 5
```
"""
function normal_form(f::T, J::MPolyIdeal; ordering::MonomialOrdering = default_ordering(base_ring(J))) where { T <: MPolyRingElem }
  res = normal_form([f], J, ordering = ordering)

  return res[1]
end

function normal_form(A::Vector{T}, J::MPolyIdeal; ordering::MonomialOrdering=default_ordering(base_ring(J))) where { T <: MPolyRingElem }
  @req is_exact_type(elem_type(base_ring(J))) "This functionality is only supported over exact fields."
  if is_normal_form_f4_applicable(J, ordering)
    res = _normal_form_f4(A, J)
  else
    res = _normal_form_singular(A, J, ordering)
  end

  return res
end

function is_normal_form_f4_applicable(I::MPolyIdeal, ordering::MonomialOrdering)
    return (ordering == degrevlex(base_ring(I)) && !is_graded(base_ring(I))
            && ((coefficient_ring(I) isa FqField
                 && absolute_degree(coefficient_ring(I)) == 1
                 && characteristic(coefficient_ring(I)) < 2^31)))
end

@doc raw"""
  _normal_form_f4(A::Vector{T}, J::MPolyIdeal) where { T <: MPolyRingElem }

**Note**: Internal function, subject to change, do not use.

Compute the normal form of the elements of `A` w.r.t. a
Gröbner basis of `J` and the monomial ordering `degrevlex` using the F4 Algorithm from AlgebraicSolving.

CAVEAT: This computation needs a Gröbner basis of `J` and the monomial ordering
`ordering. If this Gröbner basis is not available, one is computed automatically.
This may take some time. This function only works in polynomial rings over prime fields
with the degree reverse lexicographical ordering.

# Examples
```jldoctest
julia> R,(a,b,c) = polynomial_ring(GF(65521),[:a,:b,:c])
(Multivariate polynomial ring in 3 variables over GF(65521), FqMPolyRingElem[a, b, c])

julia> J = ideal(R,[-1+c+b,-1+b+c*a+2*a*b])
Ideal generated by
  b + c + 65520
  2*a*b + a*c + b + 65520

julia> A = [-1+c+b+a^3, -1+b+c*a+2*a^3, 5+c*b+c^2*a]
3-element Vector{FqMPolyRingElem}:
 a^3 + b + c + 65520
 2*a^3 + a*c + b + 65520
 a*c^2 + b*c + 5

julia> Oscar._normal_form_f4(A, J)
3-element Vector{FqMPolyRingElem}:
 a^3
 2*a^3 + 2*a + 65519*c
 4*a + 65519*c^2 + 65520*c + 5
```
"""
function _normal_form_f4(A::Vector{T}, J::MPolyIdeal) where { T <: MPolyRingElem }
  if !haskey(J.gb, degrevlex(base_ring(J)))
    groebner_basis_f4(J, complete_reduction = true)
  end

  AJ = AlgebraicSolving.Ideal(J.gens.O)
  AJ.gb[0] = oscar_groebner_generators(J, degrevlex(base_ring(J)), true)
  
  return AlgebraicSolving.normal_form(A, AJ)
end

@doc raw"""
  _normal_form_singular(A::Vector{T}, J::MPolyIdeal, ordering::MonomialOrdering) where { T <: MPolyRingElem }

**Note**: Internal function, subject to change, do not use.

Compute the normal form of the elements of `A` w.r.t. a
Gröbner basis of `J` and the monomial ordering `ordering` using Singular.

CAVEAT: This computation needs a Gröbner basis of `J` and the monomial ordering
`ordering. If this Gröbner basis is not available, one is computed automatically.
This may take some time.

# Examples
```jldoctest
julia> R,(a,b,c) = polynomial_ring(QQ,[:a,:b,:c])
(Multivariate polynomial ring in 3 variables over QQ, QQMPolyRingElem[a, b, c])

julia> J = ideal(R,[-1+c+b,-1+b+c*a+2*a*b])
Ideal generated by
  b + c - 1
  2*a*b + a*c + b - 1

julia> gens(groebner_basis(J))
2-element Vector{QQMPolyRingElem}:
 b + c - 1
 a*c - 2*a + c

julia> A = [-1+c+b+a^3, -1+b+c*a+2*a^3, 5+c*b+c^2*a]
3-element Vector{QQMPolyRingElem}:
 a^3 + b + c - 1
 2*a^3 + a*c + b - 1
 a*c^2 + b*c + 5

julia> Oscar._normal_form_singular(A, J, default_ordering(base_ring(J)))
3-element Vector{QQMPolyRingElem}:
 a^3
 2*a^3 + 2*a - 2*c
 4*a - 2*c^2 - c + 5
```
"""
function _normal_form_singular(A::Vector{T}, J::MPolyIdeal, ordering::MonomialOrdering) where { T <: MPolyRingElem }
  GS = singular_groebner_generators(J, ordering)
  SR = base_ring(GS)
  tmp = map(SR, A)
  IS = Singular.Ideal(SR, tmp)
  K = reduce(IS, GS)
  OR = base_ring(J)
  return map(OR, gens(K))
end

@doc raw"""
    is_standard_basis(F::IdealGens; ordering::MonomialOrdering=default_ordering(base_ring(F)))

Tests if a given IdealGens `F` is a standard basis w.r.t. the given monomial ordering `ordering`.

# Examples
```jldoctest
julia> R, (x, y) = polynomial_ring(QQ, [:x, :y])
(Multivariate polynomial ring in 2 variables over QQ, QQMPolyRingElem[x, y])

julia> I = ideal(R,[x^2+y,x*y-y])
Ideal generated by
  x^2 + y
  x*y - y

julia> is_standard_basis(I.gens, ordering=neglex(R))
false

julia> standard_basis(I, ordering=neglex(R))
Standard basis with elements
  1 -> y
  2 -> x^2
with respect to the ordering
  neglex([x, y])

julia> is_standard_basis(I.gb[neglex(R)], ordering=neglex(R))
true
```
"""
function is_standard_basis(F::IdealGens; ordering::MonomialOrdering=default_ordering(base_ring(F)))
  @req is_exact_type(elem_type(base_ring(F))) "This functionality is only supported over exact fields."
  if F.isGB && F.ord == ordering
    return true
  else
    # Try to reduce all possible s-polynomials, i.e. Buchberger's criterion
    R = base_ring(F)
    for i in 1:length(F)
      lt_i = leading_term(F[i], ordering=ordering)
      for j in i+1:length(F)
        lt_j = leading_term(F[j], ordering=ordering)
        lcm_ij  = lcm(lt_i, lt_j)
        sp_ij = div(lcm_ij, lt_i) * F[i] - div(lcm_ij, lt_j) * F[j]
        if reduce(IdealGens([sp_ij], ordering), F, ordering=ordering) != [R(0)]
          return false
        end
      end
    end
    F.isGB = true
    F.ord = ordering
    return true
  end
end

@doc raw"""
    is_groebner_basis(F::IdealGens; ordering::MonomialOrdering=default_ordering(base_ring(F)))

Tests if a given IdealGens `F` is a Gröbner basis w.r.t. the given monomial ordering `ordering`.

# Examples
```jldoctest
julia> R, (x, y) = polynomial_ring(QQ, [:x, :y])
(Multivariate polynomial ring in 2 variables over QQ, QQMPolyRingElem[x, y])

julia> I = ideal(R,[x^2+y,x*y-y])
Ideal generated by
  x^2 + y
  x*y - y

julia> is_groebner_basis(I.gens, ordering=lex(R))
false

julia> groebner_basis(I, ordering=lex(R))
Gröbner basis with elements
  1 -> y^2 + y
  2 -> x*y - y
  3 -> x^2 + y
with respect to the ordering
  lex([x, y])

julia> is_groebner_basis(I.gb[lex(R)], ordering=lex(R))
true
```
"""
function is_groebner_basis(F::IdealGens; ordering::MonomialOrdering = default_ordering(base_ring(F)))
  is_global(ordering) || error("Ordering must be global")
  return is_standard_basis(F, ordering=ordering)
end
