export IdealSheaf
export covered_patches
export covering
export extend!
export ideal_dict
export ideal_sheaf
export ideal_sheaf_type
export order_on_divisor
export scheme
export subscheme

export show_details

### Forwarding the presheaf functionality
underlying_presheaf(I::IdealSheaf) = I.I

# an alias for the user's convenience
scheme(I::IdealSheaf) = space(I)

@doc raw"""
    IdealSheaf(X::AbsProjectiveScheme, g::Vector{<:RingElem})

Create the ideal sheaf on the covered scheme of ``X`` which is 
generated by the dehomogenization of the homogeneous elements in `g` 
in every chart.

**Note:** When taking the pullback of an `IdealSheaf` ``ℐ`` along a morphism 
``f : X → Y``, what is actually computed, is ``f⁻¹ ℐ ⋅ 𝒪_{X}``. 
To obtain the pullback of ``ℐ`` as a sheaf of modules (i.e. ``f* ℐ``), 
convert ``ℐ`` into a `CoherentSheaf` on ``Y``, first.
"""
function IdealSheaf(X::AbsProjectiveScheme, I::MPolyIdeal) 
  S = base_ring(I)
  S === homogeneous_coordinate_ring(X) || error("ideal does not live in the graded coordinate ring of the scheme")
  g = gens(I)
  X_covered = covered_scheme(X)
  C = default_covering(X_covered)
  r = relative_ambient_dimension(X)
  I = IdDict{AbsSpec, Ideal}()
  for i in 0:r
    I[C[i+1]] = ideal(OO(C[i+1]), dehomogenization_map(X, i).(g))
  end
  return IdealSheaf(X_covered, I, check=true)
end

function IdealSheaf(X::AbsProjectiveScheme, I::MPolyQuoIdeal) 
  S = base_ring(I)
  S === homogeneous_coordinate_ring(X) || error("ideal does not live in the graded coordinate ring of the scheme")
  g = gens(I)
  X_covered = covered_scheme(X)
  C = default_covering(X_covered)
  r = relative_ambient_dimension(X)
  I = IdDict{AbsSpec, Ideal}()
  for i in 0:r
    I[C[i+1]] = ideal(OO(C[i+1]), dehomogenization_map(X, i).(g))
  end
  return IdealSheaf(X_covered, I, check=true)
end

ideal_sheaf(X::AbsProjectiveScheme, I::MPolyIdeal) = IdealSheaf(X, I)
ideal_sheaf(X::AbsProjectiveScheme, I::MPolyQuoIdeal) = IdealSheaf(X, I)

function IdealSheaf(
    X::AbsProjectiveScheme, 
    g::MPolyDecRingElem
  )
  return IdealSheaf(X, [g])
end

function IdealSheaf(
    X::AbsProjectiveScheme, 
    g::MPolyQuoRingElem
  )
  return IdealSheaf(X, [g])
end

ideal_sheaf(X::AbsProjectiveScheme, g::MPolyDecRingElem) = IdealSheaf(X, g)
ideal_sheaf(X::AbsProjectiveScheme, g::MPolyQuoRingElem) = IdealSheaf(X, g)

function IdealSheaf(
    X::AbsProjectiveScheme, 
    g::Vector{RingElemType}
  ) where {RingElemType<:MPolyDecRingElem}
  X_covered = covered_scheme(X)
  r = relative_ambient_dimension(X)
  I = IdDict{AbsSpec, Ideal}()
  U = basic_patches(default_covering(X_covered))
  for i in 1:length(U)
    I[U[i]] = ideal(OO(U[i]), dehomogenization_map(X, i-1).(g))
  end
  return IdealSheaf(X_covered, I, check=false)
end

function IdealSheaf(
    X::AbsProjectiveScheme, 
    g::Vector{RingElemType}
  ) where {RingElemType<:MPolyQuoRingElem}
  X_covered = covered_scheme(X)
  r = relative_ambient_dimension(X)
  I = IdDict{AbsSpec, Ideal}()
  U = basic_patches(default_covering(X_covered))
  for i in 1:length(U)
    I[U[i]] = ideal(OO(U[i]), dehomogenization_map(X, i-1).(g))
  end
  return IdealSheaf(X_covered, I, check=false)
end

ideal_sheaf(X::AbsProjectiveScheme, g::Vector{RingElemType}) where {RingElemType<:MPolyDecRingElem} = IdealSheaf(X, g)
ideal_sheaf(X::AbsProjectiveScheme, g::Vector{RingElemType}) where {RingElemType<:MPolyQuoRingElem} = IdealSheaf(X, g)



# this constructs the zero ideal sheaf
function IdealSheaf(X::CoveredScheme) 
  C = default_covering(X)
  I = IdDict{AbsSpec, Ideal}()
  for U in basic_patches(C)
    I[U] = ideal(OO(U), elem_type(OO(U))[])
  end
  return IdealSheaf(X, I, check=false)
end

@doc raw"""
    ideal_sheaf(X::AbsCoveredScheme)

See the documentation for `IdealSheaf`.
"""
ideal_sheaf(X::AbsCoveredScheme) = IdealSheaf(X)

# set up an ideal sheaf by automatic extension 
# from one prescribed set of generators on one affine patch
@doc raw"""
    IdealSheaf(X::CoveredScheme, U::AbsSpec, g::Vector)

Set up an ideal sheaf on ``X`` by specifying a set of generators ``g`` 
on one affine open subset ``U`` among the `basic_patches` of the 
`default_covering` of ``X``. 

**Note:** The set ``U`` has to be dense in its connected component 
of ``X`` since otherwise, the extension of the ideal sheaf to other 
charts can not be inferred. 
"""
function IdealSheaf(X::CoveredScheme, U::AbsSpec, g::Vector{RET}) where {RET<:RingElem}
  C = default_covering(X)
  U in patches(C) || error("the affine open patch does not belong to the covering")
  for f in g
    parent(f) === OO(U) || error("the generators do not belong to the correct ring")
  end
  D = IdDict{AbsSpec, Ideal}()
  D[U] = ideal(OO(U), g)
  D = extend!(C, D)
  I = IdealSheaf(X, D, check=false)
  return I
end

ideal_sheaf(X::CoveredScheme, U::AbsSpec, g::Vector{RET}) where {RET<:RingElem} = IdealSheaf(X, U, g)

@doc raw"""
    IdealSheaf(Y::AbsCoveredScheme, 
        phi::CoveringMorphism{<:Any, <:Any, <:ClosedEmbedding}
    )

Internal method to create an ideal sheaf from a `CoveringMorphism` 
of `ClosedEmbedding`s; return the ideal sheaf describing the images 
of the local morphisms.
"""
function IdealSheaf(Y::AbsCoveredScheme, 
    phi::CoveringMorphism{<:Any, <:Any, <:ClosedEmbedding}
  )
  maps = morphisms(phi)
  V = [codomain(ff) for ff in values(maps)]
  dict = IdDict{AbsSpec, Ideal}()
  for U in affine_charts(Y)
    if U in V
      i = findall(x->(codomain(x) == U), maps)
      dict[U] = image_ideal(maps[first(i)])
    else
      dict[U] = ideal(OO(U), one(OO(U)))
    end
  end
  return IdealSheaf(Y, dict) # TODO: set check=false?
end

    
# pullback of an ideal sheaf for internal use between coverings of the same scheme
#function (F::CoveringMorphism)(I::IdealSheaf)
#  X = scheme(I)
#  D = codomain(F)
#  D == covering(I) || error("ideal sheaf is not defined on the correct covering")
#  C = domain(F)
#  new_dict = Dict{AbsSpec, Ideal}()
#
#  # go through the patches of C and pull back the generators 
#  # whenever they are defined on the target patch
#  for U in patches(C)
#    f = F[U]
#    V = codomain(f)
#    # for the basic patches here
#    if haskey(ideal_dict(I), V)
#      new_dict[U] = ideal(OO(U), pullback(f).(I[V]))
#    end
#    # check for affine refinements
#    if haskey(affine_refinements(D), V)
#      Vrefs = affine_refinements(D)[V]
#      # pull back the refinement
#      for W in Vrefs
#        h = pullback(f).(gens(W))
#        # take care to discard possibly empty preimages of patches
#        j = [i for i in 1:length(h) if !iszero(h)]
#        Wpre = SpecOpen(U, h[j])
#        add_affine_refinement!(C, Wpre)
#        for i in 1:length(j)
#          if haskey(ideal_dict(I), Wpre[i])
#            new_dict[Wpre[i]] = lifted_numerator.(pullback(f).(I[V[j[i]]]))
#          end
#        end
#      end
#    end
#  end
#  return IdealSheaf(X, C, new_dict)
#end

function +(I::IdealSheaf, J::IdealSheaf) 
  X = space(I)
  X == space(J) || error("ideal sheaves are not defined over the same scheme")
  new_dict = IdDict{AbsSpec, Ideal}()
  CI = default_covering(X)
  for U in patches(CI)
    new_dict[U] = I(U) + J(U)
  end
  return IdealSheaf(X, new_dict, check=false)
end

function *(I::IdealSheaf, J::IdealSheaf) 
  X = space(I)
  X == space(J) || error("ideal sheaves are not defined over the same scheme")
  new_dict = IdDict{AbsSpec, Ideal}()
  CI = default_covering(X)
  for U in patches(CI)
    new_dict[U] = I(U) * J(U)
  end
  return IdealSheaf(X, new_dict, check=false)
end

@doc raw"""
    simplify!(I::IdealSheaf)

Replaces the set of generators of the ideal sheaf by a minimal 
set of random linear combinations in every affine patch. 
"""
function simplify!(I::IdealSheaf)
  for U in basic_patches(default_covering(space(I)))
    n = ngens(I(U)) 
    n == 0 && continue
    R = ambient_coordinate_ring(U)
    kk = coefficient_ring(R)
    new_gens = elem_type(OO(U))[]
    K = ideal(OO(U), new_gens) 
    while !issubset(I(U), K)
      new_gen = dot([rand(kk, 1:100) for i in 1:n], gens(I(U)))
      while new_gen in K
        new_gen = dot([rand(kk, 1:100) for i in 1:n], gens(I(U)))
      end
      push!(new_gens, new_gen)
      K = ideal(OO(U), new_gens)
    end
    Oscar.object_cache(underlying_presheaf(I))[U] = K 
  end
  return I
end

@doc """
    subscheme(I::IdealSheaf) 

For an ideal sheaf ``ℐ`` on an `AbsCoveredScheme` ``X`` this returns 
the subscheme ``Y ⊂ X`` given by the zero locus of ``ℐ``.
"""
function subscheme(I::IdealSheaf) 
  X = space(I)
  C = default_covering(X)
  new_patches = [subscheme(U, I(U)) for U in basic_patches(C)]
  new_glueings = IdDict{Tuple{AbsSpec, AbsSpec}, AbsGlueing}()
  for (U, V) in keys(glueings(C))
    i = C[U]
    j = C[V]
    Unew = new_patches[i]
    Vnew = new_patches[j]
    G = C[U, V]
    #new_glueings[(Unew, Vnew)] = restrict(C[U, V], Unew, Vnew, check=false)
    new_glueings[(Unew, Vnew)] = LazyGlueing(Unew, Vnew, _compute_restriction, 
                                             RestrictionDataClosedEmbedding(C[U, V], Unew, Vnew)
                                            )
    #new_glueings[(Vnew, Unew)] = inverse(new_glueings[(Unew, Vnew)])
    new_glueings[(Vnew, Unew)] = LazyGlueing(Vnew, Unew, inverse, new_glueings[(Unew, Vnew)])
  end
  Cnew = Covering(new_patches, new_glueings, check=false)
  return CoveredScheme(Cnew)
end


@doc raw"""
    extend!(C::Covering, D::Dict{SpecType, IdealType}) where {SpecType<:Spec, IdealType<:Ideal}

For ``C`` a covering and ``D`` a dictionary holding vectors of 
polynomials on affine patches of ``C`` this function extends the 
collection of polynomials over all patches in a compatible way; 
meaning that on the overlaps the restrictions of either two sets 
of polynomials coincides.

This proceeds by crawling through the glueing graph and taking 
closures in the patches ``Uⱼ`` of the subschemes 
``Zᵢⱼ = V(I) ∩ Uᵢ ∩ Uⱼ`` in the intersection with a patch ``Uᵢ`` 
on which ``I`` had already been described.

Note that the covering `C` is not modified.  
"""
function extend!(
    C::Covering, D::IdDict{AbsSpec, Ideal}
  )
  gg = glueing_graph(C)
  # push all nodes on which I is known in a heap
  dirty_patches = collect(keys(D))
  while length(dirty_patches) > 0
    U = pop!(dirty_patches)
    N = neighbor_patches(C, U)
    Z = subscheme(U, D[U])
    for V in N
      # check whether this node already knows about D
      haskey(D, V)  && continue

      # if not, extend D to this patch
      f, _ = glueing_morphisms(C[V, U])
      pZ = preimage(f, Z)
      ZV = closure(pZ, V)
      D[V] = ideal(OO(V), gens(saturated_ideal(modulus(OO(ZV)))))
      V in dirty_patches || push!(dirty_patches, V)
    end
  end
  for U in basic_patches(C) 
    if !haskey(D, U)
      D[U] = ideal(OO(U), zero(OO(U)))
    end
  end
  return D
end

#function Base.show(io::IO, I::IdealSheaf)
#  print(io, "sheaf of ideals on $(space(I))")
#end

function ==(I::IdealSheaf, J::IdealSheaf)
  I === J && return true
  X = space(I)
  X == space(J) || return false
  for U in basic_patches(default_covering(X))
    is_subset(I(U), J(U)) && is_subset(J(U), I(U)) || return false
  end
  return true
end

function is_subset(I::IdealSheaf, J::IdealSheaf)
  X = space(I)
  X === space(J) || return false
  for U in basic_patches(default_covering(X))
    is_subset(I(U), J(U)) || return false
  end
  return true
end

# prepares a refinement C' of the covering for the ideal sheaf I 
# such that I can be generated by a regular sequence defining a smooth 
# local complete intersection subscheme in every patch U of C' and 
# returns the ideal sheaf with those generators on C'.
#function as_smooth_lci(
#    I::IdealSheaf;
#    verbose::Bool=false,
#    check::Bool=true,
#    codimension::Int=dim(scheme(I))-dim(subscheme(I)) #assumes both scheme(I) and its subscheme to be equidimensional
#  )
#  X = scheme(I)
#  C = covering(I)
#  SpecType = affine_patch_type(C)
#  PolyType = poly_type(SpecType)
#  new_gens_dict = Dict{SpecType, Vector{PolyType}}()
#  for U in patches(C)
#    V, spec_dict = as_smooth_lci(U, I[U], 
#                                 verbose=verbose, 
#                                 check=check, 
#                                 codimension=codimension) 
#    add_affine_refinement!(C, V)
#    merge!(new_gens_dict, spec_dict)
#  end
#  Iprep = IdealSheaf(X, C, new_gens_dict)
#  set_attribute!(Iprep, :is_regular_sequence, true)
#  return Iprep
#end
#
#function as_smooth_lci(
#    U::Spec, g::Vector{T}; 
#    verbose::Bool=false,
#    check::Bool=true,
#    codimension::Int=dim(U)-dim(subscheme(U, g)) # this assumes both U and its subscheme to be equidimensional
#  ) where {T<:MPolyRingElem}
#  verbose && println("preparing $g as a local complete intersection on $U")
#  f = numerator.(gens(localized_modulus(OO(U))))
#  f = [a for a in f if !iszero(a)]
#  verbose && println("found $(length(f)) generators for the ideal defining U")
#  h = vcat(f, g)
#  r = length(f)
#  s = length(g)
#  Dh = jacobi_matrix(h)
#  (ll, ql, rl, cl) = _non_degeneration_cover(subscheme(U, g), Dh, codimension + codim(U), 
#                          verbose=verbose, check=check, 
#                          restricted_columns=[collect(1:r), [r + k for k in 1:s]])
#
#  n = length(ll)
#  # first process the necessary refinements of U
#  # The restricted columns in the call to _non_degenerate_cover 
#  # assure that the first codim(U) entries of every cl[i] are 
#  # indices of some element of f. However, we can discard these, 
#  # as they are trivial generators of the ideal sheaf on U.
#  minor_list = [det(Dh[rl[i], cl[i]]) for i in 1:n]
#  V = Vector{open_subset_type(U)}()
#  SpecType = typeof(U)
#  PolyType = poly_type(U)
#  spec_dict = Dict{SpecType, Vector{PolyType}}()
#  g = Vector{PolyType}()
#  W = SpecOpen(U, minor_list)
#  for i in 1:n
#    spec_dict[W[i]] = h[cl[i][codim(U)+1:end]]
#  end
#  return W, spec_dict
#end
#

function is_prime(I::IdealSheaf) 
  return all(U->is_prime(I(U)), basic_patches(default_covering(space(I))))
end

function _minimal_power_such_that(I::Ideal, P::PropertyType) where {PropertyType}
  whole_ring = ideal(base_ring(I), [one(base_ring(I))])
  P(whole_ring) && return (0, whole_ring)
  P(I) && return (1, I)
  I_powers = [(1,I)]

  while !P(last(I_powers)[2])
    push!(I_powers, (last(I_powers)[1]*2, last(I_powers)[2]^2))
  end
  upper = pop!(I_powers)
  lower = pop!(I_powers)
  while upper[1]!=lower[1]+1
    middle = pop!(I_powers)
    middle = (lower[1]+middle[1], lower[2]*middle[2])
    if P(middle[2])
      upper = middle
    else
      lower = middle
    end
  end
  return upper
end

@doc raw"""
    order_on_divisor(f::VarietyFunctionFieldElem, I::IdealSheaf; check::Bool=true) -> Int

Return the order of the rational function `f` on the prime divisor given by the ideal sheaf `I`.
"""
function order_on_divisor(
    f::VarietyFunctionFieldElem, 
    I::IdealSheaf;
    check::Bool=true
  )
  if check
    is_prime(I) || error("ideal sheaf must be a sheaf of prime ideals")
  end
  X = space(I)::AbsCoveredScheme
  X == variety(parent(f)) || error("schemes not compatible")
  
  #order_dict = Dict{AbsSpec, Int}()

  # Since X is integral and I is a sheaf of prime ideals, 
  # it suffices to find one chart in which I is non-trivial.

  # We look for the chart with the least complexity
  V = first(affine_charts(X))
  #complexity = Vector{Tuple{AbsSpec, Int}}()
  complexity = inf
  for U in keys(Oscar.object_cache(underlying_presheaf(I))) # Those charts on which I is known.
    U in default_covering(X) || continue
    one(base_ring(I(U))) in I(U) && continue
    tmp = sum([total_degree(lifted_numerator(g)) for g in gens(I(U)) if !iszero(g)]) # /ngens(Oscar.pre_image_ideal(I(U)))
    if tmp < complexity 
      complexity = tmp
      V = U
    end
  end
  if complexity == inf
    error("divisor is empty")
  end
  R = ambient_coordinate_ring(V)
  J = saturated_ideal(I(V))
  floc = f[V]
  aR = ideal(R, numerator(floc))
  bR = ideal(R, denominator(floc))


  # The following uses ArXiv:2103.15101, Lemma 2.18 (4):
  num_mult = _minimal_power_such_that(J, x->(issubset(quotient(x, aR), J)))[1]-1
  den_mult = _minimal_power_such_that(J, x->(issubset(quotient(x, bR), J)))[1]-1
  return num_mult - den_mult
#    # Deprecated code computing symbolic powers explicitly:
#    L, map = Localization(OO(U), 
#                          MPolyComplementOfPrimeIdeal(saturated_ideal(I(U)))
#                         )
#    typeof(L)<:Union{MPolyLocRing{<:Any, <:Any, <:Any, <:Any, 
#                                        <:MPolyComplementOfPrimeIdeal},
#                     MPolyQuoLocRing{<:Any, <:Any, <:Any, <:Any, 
#                                           <:MPolyComplementOfPrimeIdeal}
#                    } || error("localization was not successful")
# 
#    floc = f[U]
#    a = numerator(floc)
#    b = denominator(floc)
#    # TODO: cache groebner bases in a reasonable way.
#    P = L(prime_ideal(inverted_set(L)))
#    if one(L) in P 
#      continue # the multiplicity is -∞ in this case and does not count
#    end
#    upper = _minimal_power_such_that(P, x->!(L(a) in x))[1]-1
#    lower = _minimal_power_such_that(P, x->!(L(b) in x))[1]-1
#    order_dict[U] = upper-lower
end

@doc raw"""
    smooth_lci_covering(I::IdealSheaf)

For an ideal sheaf ``ℐ`` on a *smooth* scheme ``X`` with a *smooth* 
associated subscheme ``Y = V(ℐ)`` this produces a covering ``𝔘 = {Uₐ}, a ∈ A``
such that ``ℐ(Uₐ) = ⟨f₁,…,fₖ⟩`` is generated by a regular sequence on every 
patch ``Uₐ`` of that covering.
"""
function smooth_lci_covering(I::IdealSheaf)
  error("not implemented")
end

function pushforward(inc::CoveredClosedEmbedding, I::IdealSheaf)
  Y = domain(inc)
  scheme(I) === Y || error("ideal sheaf is not defined on the domain of the embedding")
  X = codomain(inc)
  phi = covering_morphism(inc)
  ID = IdDict{AbsSpec, Ideal}()
  for U in patches(domain(phi))
    V = codomain(phi[U])
    ID[V] = pushforward(phi[U], I(U))
  end
  return IdealSheaf(X, ID, check=false)
end

function pushforward(inc::ClosedEmbedding, I::Ideal)
  Y = domain(inc)
  base_ring(I) === OO(Y) || error("ideal is not defined in the coordinate ring of the domain")
  X = codomain(inc)
  return ideal(OO(X), vcat(gens(image_ideal(inc)), 
                           OO(X).(lifted_numerator.(gens(I))))
              )
end

########################################################################
# primary decomposition
########################################################################

## this should go to src/Ring/mpolyquo-localization.jl
function primary_decomposition(I::Union{<:MPolyQuoIdeal, <:MPolyQuoLocalizedIdeal, <:MPolyLocalizedIdeal})
  Q = base_ring(I)
  R = base_ring(Q)
  decomp = primary_decomposition(saturated_ideal(I))
  result = [(ideal(Q, Q.(gens(a))), ideal(Q, Q.(gens(b)))) for (a, b) in decomp]
  return result
end

## this should go to src/Rings/mpolyquo-localization.jl
function minimal_primes(I::Union{<:MPolyQuoIdeal, <:MPolyQuoLocalizedIdeal, <:MPolyLocalizedIdeal})
  Q = base_ring(I)
  R = base_ring(Q)
  decomp = minimal_primes(saturated_ideal(I))
  result = [ideal(Q, Q.(gens(b))) for b in decomp]
  return result
end


function minimal_associated_points(I::IdealSheaf)
  X = scheme(I)
  OOX = OO(X)

  charts_todo = copy(affine_charts(X))            ## todo-list of charts

  associated_primes_temp = Vector{IdDict{AbsSpec, Ideal}}()  ## already identified components
                                                  ## may not yet contain all relevant charts. but
                                                  ## at least one for each identified component

# run through all charts and try to match the components
  while length(charts_todo) > 0
    U = pop!(charts_todo)
    !is_one(I(U)) || continue                        ## supp(I) might not meet all components
    components_here = minimal_primes(I(U))

## run through all primes in MinAss(I(U)) and try to match them with previously found ones
    for comp in components_here
      matches = match_on_intersections(X,U,comp,associated_primes_temp,false)
      nmatches = length(matches)

      if nmatches == 0                             ## not found
        add_dict = IdDict{AbsSpec,Ideal}()         ## create new dict
        add_dict[U] = comp                         ## and fill it
        push!(associated_primes_temp, add_dict)
      elseif nmatches == 1                         ## unique match, update it
        component_index = matches[1]
        associated_primes_temp[component_index][U] = comp
      else                                                ## more than one match, form union
        target_comp = pop!(matches)
        merge!(associated_primes_temp[target_comp], associated_primes_temp[x] for x in matches)
        deleteat!(associated_primes_temp,matches)
        associated_primes_temp[target_comp][U] = comp
      end
    end
  end

# fill the gaps arising from a support not meeting a patch
  for U in affine_charts(X)
    I_one = ideal(OOX(U),one(OOX(U)))
    for i in 1:length(associated_primes_temp)
      !haskey(associated_primes_temp[i],U) || continue
      associated_primes_temp[i][U] = I_one
    end
  end

# make sure to return ideal sheaves, not dicts
  associated_primes_result = [IdealSheaf(X,associated_primes_temp[i],check=false) for i in 1:length(associated_primes_temp)]
  return associated_primes_result
end

function associated_points(I::IdealSheaf)
  X = scheme(I)
  OOX = OO(X)
  charts_todo = copy(affine_charts(X))            ## todo-list of charts

  associated_primes_temp = Vector{IdDict{AbsSpec, Ideal}}()  ## already identified components
                                                  ## may not yet contain all relevant charts. but
                                                  ## at least one for each identified component

# run through all charts and try to match the components
  while !iszero(length(charts_todo))
    U = pop!(charts_todo)
    !is_one(I(U)) || continue                        ## supp(I) might not meet all components
    components_here = [ a for (_,a) in primary_decomposition(I(U))]

## run through all primes in Ass(I(U)) and try to match them with previously found ones
    for comp in components_here
      matches = match_on_intersections(X,U,comp,associated_primes_temp,false)
      nmatches = length(matches)

      if nmatches == 0                             ## not found
        add_dict = IdDict{AbsSpec,Ideal}()         ## create new dict
        add_dict[U] = comp                         ## and fill it
        push!(associated_primes_temp, add_dict)
      elseif nmatches == 1                         ## unique match, update it
        component_index = matches[1]
        associated_primes_temp[component_index][U] = comp
      else                                                ## more than one match, form union
        target_comp = pop!(matches)
        merge!(associated_primes_temp[target_comp], associated_primes_temp[x] for x in matches)
        deleteat!(associated_primes_temp,matches)
        associated_primes_temp[target_comp][U] = comp
      end
    end
  end

# fill the gaps arising from a support not meeting a patch
  for U in affine_charts(X)
    I_one = ideal(OOX(U),one(OOX(U)))
    for i in 1:length(associated_primes_temp)
      !haskey(associated_primes_temp[i],U) || continue
      associated_primes_temp[i][U] = I_one
    end
  end

# make sure to return ideal sheaves, not dicts
  associated_primes_result = [IdealSheaf(X,associated_primes_temp[i],check=false) for i in 1:length(associated_primes_temp)]
  return associated_primes_result
end

function match_on_intersections(
      X::AbsCoveredScheme,
      U::AbsSpec,
      I::Union{<:MPolyQuoIdeal, <:MPolyQuoLocalizedIdeal, <:MPolyLocalizedIdeal},
      associated_list::Vector{IdDict{AbsSpec,Ideal}},
      check::Bool=true)

  matches = Int[]
  OOX = OO(X)

# run through all components in associated_list and try to match up I
  for i in 1:length(associated_list)
    match_found = false
    match_contradicted = false

## run through all known patches of the component
    for (V,IV) in associated_list[i]
      G = default_covering(X)[V,U]
      VU, UV = glueing_domains(G)
      I_res = OOX(U,UV)(I)
      IV_res = OOX(V,UV)(IV)
      if (I_res == IV_res)
        match_found = !is_one(I_res)                               ## count only non-trivial matches
        check || break
      else
        match_contradicted = true
        check || break
      end
    end

## make sure we are working on consistent data
    if check
      if match_found && match_contradicted
        error("contradictory matching result!!")                     ## this should not be reached for ass. points
      end
    end

## update list of matches
    if match_found
      push!(matches, i)
    end
  end

  return matches
end

## TODO: this should go away, once associated_points is finished
function primary_decomposition(I::IdealSheaf)
  X = scheme(I)
  OOX = OO(X)

  # Compute the primary decompositions in the charts.
  decomp_dict = IdDict{AbsSpec, Vector{Tuple{Ideal, Ideal}}}()
  for U in affine_charts(X)
    decomp_dict[U] = primary_decomposition(I(U))
  end

  clean_charts = Vector{AbsSpec}()
  dirty_charts = copy(affine_charts(X))

  prime_parts = Vector{IdDict{AbsSpec, Ideal}}()
  primary_parts = Vector{IdDict{AbsSpec, Ideal}}()

  while !iszero(length(dirty_charts))
    #@show "new chart: ##############################################################"
    U = pop!(dirty_charts)
    new_prime_parts = Vector{IdDict{AbsSpec, Ideal}}()
    new_primary_parts = Vector{IdDict{AbsSpec, Ideal}}()
    #@show U
    #@show "starting new patch"
    new_components = decomp_dict[U]
    for (Q, P) in new_components
      is_one(P) && continue
      #@show "looking at component"
      #@show gens(Q)
      #@show gens(P)
      possible_matches = Int[]
      for i in 1:length(prime_parts)
        #@show i
        is_possible_match = true
        all_intersections_trivial = true
        for V in clean_charts
          #@show V
          if !haskey(glueings(default_covering(X)), (V, U))
            #@show "patches are not glued"
            continue
          end
          G = default_covering(X)[V, U]
          VU, UV = glueing_domains(G)
          QU_res = OOX(U, UV)(Q)
          QV_res = OOX(V, UV)(primary_parts[i][V])
          #@show gens(QU_res)
          #@show gens(QV_res)
          if QU_res == QV_res
            #@show "possible match"
            if !is_one(QV_res)
              all_intersections_trivial = false
            end
          else 
            #@show "ideals do not coincide on overlap"
            is_possible_match = false
            break
          end
        end
        if is_possible_match
          #@show "found a possible match in $i"
          if !all_intersections_trivial
            push!(possible_matches, i)
          end
        end
      end
      if iszero(length(possible_matches))
      #@show "adding new component"
        new_prime_part = IdDict{AbsSpec, Ideal}()
        new_primary_part = IdDict{AbsSpec, Ideal}()
        for V in clean_charts
          J = ideal(OOX(V), one(OOX(V)))
          new_prime_part[V] = J
          new_primary_part[V] = J
        end
        new_prime_part[U] = P
        new_primary_part[U] = Q
        push!(new_prime_parts, new_prime_part)
        push!(new_primary_parts, new_primary_part)
      elseif isone(length(possible_matches))
        #@show "unique match found; extending component"
        k = first(possible_matches)
        prime_parts[k][U] = P
        primary_parts[k][U] = Q
      else
        error("no unique match found; case not implemented")
      end
    end
    push!(clean_charts, U)
    prime_parts = vcat(prime_parts, new_prime_parts)
    primary_parts = vcat(primary_parts, new_primary_parts)
    for P in prime_parts
      if !haskey(P, U) 
        P[U] = ideal(OOX(U), one(OOX(U)))
      end
    end
    for Q in primary_parts
      if !haskey(Q, U) 
        Q[U] = ideal(OOX(U), one(OOX(U)))
      end
    end
    #@show length(prime_parts)
  end

  prime_components = [IdealSheaf(X, P, check= false) for P in prime_parts] # TODO: Set to false!
  primary_components = [IdealSheaf(X, Q, check= false) for Q in primary_parts]

  return collect(zip(primary_components, prime_components))
end

# further required functionality
#function isone(I::Ideal)
#  return one(base_ring(I)) in I
#end

function (phi::Hecke.Map{D, C})(I::Ideal) where {D<:Ring, C<:Ring}
  base_ring(I) === domain(phi) || error("ideal not defined over the domain of the map")
  R = domain(phi)
  S = codomain(phi)
  return ideal(S, phi.(gens(I)))
end

# Necessary for removing ambiguities
function (phi::AbstractAlgebra.Generic.CompositeMap{D, C})(I::Ideal) where {D<:Ring, C<:Ring}
  base_ring(I) === domain(phi) || error("ideal not defined over the domain of the map")
  R = domain(phi)
  S = codomain(phi)
  return ideal(S, phi.(gens(I)))
end

function (phi::MPolyAnyMap{D, C})(I::MPolyIdeal) where {D<:MPolyRing, C<:Ring}
  base_ring(I) === domain(phi) || error("ideal not defined over the domain of the map")
  R = domain(phi)
  S = codomain(phi)
  return ideal(S, phi.(gens(I)))
end

function (phi::MPolyAnyMap{D, C})(I::MPolyQuoIdeal) where {D<:MPolyQuoRing, C<:Ring}
  base_ring(I) === domain(phi) || error("ideal not defined over the domain of the map")
  R = domain(phi)
  S = codomain(phi)
  return ideal(S, phi.(gens(I)))
end

function complement_of_prime_ideal(P::MPolyQuoIdeal)
  return complement_of_prime_ideal(saturated_ideal(P))
end

function complement_of_prime_ideal(P::MPolyQuoLocalizedIdeal)
  return complement_of_prime_ideal(saturated_ideal(P))
end

function complement_of_prime_ideal(P::MPolyLocalizedIdeal)
  return complement_of_prime_ideal(saturated_ideal(P))
end

@attr IdealSheaf function radical(II::IdealSheaf)
  X = scheme(II)
  # If there is a simplified covering, do the calculations there.
  covering = (has_attribute(X, :simplified_covering) ? simplified_covering(X) : default_covering(X))
  ID = IdDict{AbsSpec, Ideal}()
  for U in patches(covering)
    ID[U] = radical(II(U))
  end
  return IdealSheaf(X, ID, check=false)
end

###########################################################################
## show functions for Ideal sheaves
########################################################################### 
function Base.show(io::IO, I::IdealSheaf)
    X = scheme(I)

  # If there is a simplified covering, use it!
  covering = (has_attribute(X, :simplified_covering) ? simplified_covering(X) : default_covering(X))
  n = npatches(covering)
  println(io,"Ideal Sheaf on Covered Scheme with ",n," Charts")
end

function show_details(I::IdealSheaf)
   show_details(stdout,I)
end

function show_details(io::IO, I::IdealSheaf)
  X = scheme(I)

  # If there is a simplified covering, use it!
  covering = (has_attribute(X, :simplified_covering) ? simplified_covering(X) : default_covering(X))
  n = npatches(covering)
  println(io,"Ideal Sheaf on Covered Scheme with ",n," Charts:\n")

  for (i,U) in enumerate(patches(covering))
    println(io,"Chart $i:")
    println(io,"   $(I(U))")
    println(io," ")
  end
end
