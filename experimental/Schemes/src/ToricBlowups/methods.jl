@doc raw"""
    strict_transform(f::ToricBlowupMorphism, I::MPolyIdeal) -> MPolyIdeal

Let $f\colon Y \to X$ be the toric blowup corresponding to a star
subdivision along a ray. Let $R$ and $S$ be the Cox rings of $X$ and
$Y$, respectively.
Here "strict transform" means the "scheme-theoretic closure of the
complement of the exceptional divisor in the scheme-theoretic inverse
image".
This function returns a homogeneous ideal in $S$ corresponding to the
strict transform under $f$ of the closed subscheme of $X$ defined by the
homogeneous ideal $I$ in $R$.

This is implemented under the following assumptions:
  * the variety $X$ has no torus factors (meaning the rays span
    $N_{\mathbb{R}}$).

# Examples
```jldoctest
julia> X = affine_space(NormalToricVariety, 2)
Normal toric variety

julia> f = blow_up(X, [2, 3])
Toric blowup morphism

julia> R = cox_ring(X)
Multivariate polynomial ring in 2 variables over QQ graded by the trivial group

julia> (x1, x2) = gens(R)
2-element Vector{MPolyDecRingElem{QQFieldElem, QQMPolyRingElem}}:
 x1
 x2

julia> I = ideal(R, [x1 + x2])
Ideal generated by
  x1 + x2

julia> strict_transform(f, I)
Ideal generated by
  x1 + x2*e
```
"""
function strict_transform(f::ToricBlowupMorphism, I::MPolyIdeal)
  X = codomain(f)
  @req !has_torusfactor(X) "Only implemented when there are no torus factors"
  S = cox_ring(domain(f))
  exceptional_var = S[index_of_exceptional_ray(f)]
  J = cox_ring_module_homomorphism(f, I)
  return saturation(J, ideal(S, exceptional_var))
end

@doc raw"""
    total_transform(f::ToricBlowupMorphism, I::MPolyIdeal) -> MPolyIdeal

Let $f\colon Y \to X$ be the toric blowup corresponding to a star
subdivision along a ray. Let $R$ and $S$ be the Cox rings of $X$ and
$Y$, respectively.
This function returns a homogeneous ideal in $S$ corresponding to the
total transform (meaning the scheme-theoretic inverse image) under $f$
of the closed subscheme of $X$ defined by the homogeneous ideal $I$ in
$R$.

This is implemented under the following assumptions:
  * the variety $X$ has no torus factors (meaning the rays span
    $N_{\mathbb{R}}$), and
  * the variety $X$ is an orbifold (meaning its fan is simplicial).

# Examples
```jldoctest
julia> X = affine_space(NormalToricVariety, 2)
Normal toric variety

julia> f = blow_up(X, [2, 3])
Toric blowup morphism

julia> R = cox_ring(X)
Multivariate polynomial ring in 2 variables over QQ graded by the trivial group

julia> (x1, x2) = gens(R)
2-element Vector{MPolyDecRingElem{QQFieldElem, QQMPolyRingElem}}:
 x1
 x2

julia> I = ideal(R, [x1 + x2])
Ideal generated by
  x1 + x2

julia> total_transform(f, I)
Ideal generated by
  x1*e^2 + x2*e^3
```
"""
function total_transform(f::ToricBlowupMorphism, I::MPolyIdeal)
  X = codomain(f)
  @req !has_torusfactor(X) "Only implemented when there are no torus factors"
  @req is_orbifold(X) "Only implemented when the fan is simplicial"
  return cox_ring_module_homomorphism(f, I)
end

@doc raw"""
    strict_transform_with_index(f::ToricBlowupMorphism, I::MPolyIdeal) -> (MPolyIdeal, Int)

Returns the pair $(J, k)$, where $J$ coincides with `strict_transform(f, I)`
and where $k$ is the multiplicity of the total transform along the
exceptional prime divisor.

This is implemented under the following assumptions:
  * the variety $X$ has no torus factors (meaning the rays span
    $N_{\mathbb{R}}$), and
  * the variety $X$ is smooth.

!!! note
    If the multiplicity $k$ is not needed, we recommend to use
    `strict_transform(f, I)` which is typically faster.

# Examples
```jldoctest
julia> X = affine_space(NormalToricVariety, 2)
Normal toric variety

julia> f = blow_up(X, [2, 3])
Toric blowup morphism

julia> R = cox_ring(X)
Multivariate polynomial ring in 2 variables over QQ graded by the trivial group

julia> (x1, x2) = gens(R)
2-element Vector{MPolyDecRingElem{QQFieldElem, QQMPolyRingElem}}:
 x1
 x2

julia> I = ideal(R, [x1 + x2])
Ideal generated by
  x1 + x2

julia> strict_transform_with_index(f, I)
(Ideal (x1 + x2*e), 2)
```
"""
function strict_transform_with_index(f::ToricBlowupMorphism, I::MPolyIdeal)
  X = codomain(f)
  @req !has_torusfactor(X) "Only implemented when there are no torus factors"
  @req is_smooth(X) "Only implemented when the fan is smooth"
  S = cox_ring(domain(f))
  exceptional_var = S[index_of_exceptional_ray(f)]
  J = total_transform(f, I)
  return saturation_with_index(J, ideal(exceptional_var))
end

@doc raw"""
    cox_ring_module_homomorphism(f::ToricBlowupMorphism, g::MPolyDecRingElem) -> MPolyDecRingElem
    cox_ring_module_homomorphism(f::ToricBlowupMorphism, I::MPolyIdeal) -> MPolyIdeal

Let $f\colon Y \to X$ be the toric blowup corresponding to a star
subdivision along a ray with minimal generator $v$. Let $R$ and $S$ be
the Cox rings of $X$ and $Y$, respectively.
Considering $R$ and $S$ with their $\mathbb{C}$-module structures, we
construct a $\mathbb{C}$-module homomorphism $\Phi\colon R \to S$
sending a monomial $g$ to $e^d g$, where $e$ is the variable
corresponding to the ray $\rho$ and where $d = 0$ if $\rho$ belongs to
the fan of $X$ and $d = \lceil a \cdot p \rceil$ otherwise, where $a$ is
the exponent vector of $g$, $p$ is the minimal supercone coordinate
vector of $v$ in the fan of $X$, as returned by
`minimal_supercone_coordinates_of_exceptional_ray(X, v)`, and where $(\cdot)$
denotes the scalar product.

The $\mathbb{C}$-module homomorphism $\Phi$ sends homogeneous ideals to
homogeneous ideals.

# Examples
```jldoctest
julia> X = affine_space(NormalToricVariety, 2)
Normal toric variety

julia> f = blow_up(X, [2, 3])
Toric blowup morphism

julia> R = cox_ring(X)
Multivariate polynomial ring in 2 variables over QQ graded by the trivial group

julia> (x1, x2) = gens(R)
2-element Vector{MPolyDecRingElem{QQFieldElem, QQMPolyRingElem}}:
 x1
 x2

julia> cox_ring_module_homomorphism(f, x1 + x2)
x1*e^2 + x2*e^3
```
"""
cox_ring_module_homomorphism

function cox_ring_module_homomorphism(f::ToricBlowupMorphism, g::MPolyDecRingElem)
  @req parent(g) === cox_ring(codomain(f)) "g must be an element of the Cox ring of the codomain of f"
  R = cox_ring(codomain(f))
  S = cox_ring(domain(f))
  nvars(R) == nvars(S) && return evaluate(g, gens(S))
  ps = minimal_supercone_coordinates_of_exceptional_ray(f)
  if lcm(denominator.(ps)) == 1
    ps_fast = Vector{Int64}(numerator.(ps))
  else
    ps_fast = Vector{Rational{Int64}}(ps)
  end
  exceptional_var = S[index_of_exceptional_ray(f)]
  C = MPolyBuildCtx(S)

  # Core loop
  for m in terms(g)
    exps = first(exponents(m))
    exceptional_exp = ceil(Int64, sum(ps_fast.*exps))
    exps = [exps; exceptional_exp]
    push_term!(C, first(coefficients(m)), exps)
  end

  h = finish(C)
  return h
end

function cox_ring_module_homomorphism(f::ToricBlowupMorphism, I::MPolyIdeal)
  S = cox_ring(domain(f))
  return ideal(S, [cox_ring_module_homomorphism(f, g) for g in gens(I)])
end

@doc raw"""
    minimal_supercone_coordinates_of_exceptional_ray(f::ToricBlowupMorphism) -> Vector{QQFieldElem}

Let $f\colon Y \to X$ be the toric blowup corresponding to a star
subdivision along a ray with minimal generator $v$.
This function returns the minimal supercone coordinate vector of $v$ in the fan of $X$.
See `?minimal_supercone_coordinates` for more details.

# Examples
```jldoctest
julia> X = affine_space(NormalToricVariety, 2)
Normal toric variety

julia> f = blow_up(X, [2, 3])
Toric blowup morphism

julia> minimal_supercone_coordinates_of_exceptional_ray(f)
2-element Vector{QQFieldElem}:
 2
 3
```
"""
@attr Vector{QQFieldElem} function minimal_supercone_coordinates_of_exceptional_ray(f::ToricBlowupMorphism)
  PF = polyhedral_fan(codomain(f))
  v = rays(domain(f))[index_of_exceptional_ray(f), :][1]
  v_ZZ = primitive_generator(v)
  return minimal_supercone_coordinates(PF, v_ZZ)
end

@doc raw"""
    total_transform(f::AbsSimpleBlowupMorphism, II::IdealSheaf)

Computes the total transform of an ideal sheaf along a blowup.

In particular, this applies in the toric setting. However, note that
currently (October 2023), ideal sheaves are only supported on smooth
toric varieties.

# Examples
```jldoctest
julia> P2 = projective_space(NormalToricVariety, 2)
Normal toric variety

julia> bl = blow_up(P2, [1, 1])
Toric blowup morphism

julia> S = cox_ring(P2);

julia> x, y, z = gens(S);

julia> I = ideal_sheaf(P2, ideal([x*y]))
Sheaf of ideals
  on normal, smooth toric variety
with restrictions
  1: Ideal (x_1_1*x_2_1)
  2: Ideal (x_2_2)
  3: Ideal (x_1_3)

julia> total_transform(bl, I)
Sheaf of ideals
  on normal toric variety
with restrictions
  1: Ideal (x_1_1*x_2_1^2)
  2: Ideal (x_1_2^2*x_2_2)
  3: Ideal (x_2_3)
  4: Ideal (x_1_4)
```
"""
function total_transform(f::AbsSimpleBlowupMorphism, II::AbsIdealSheaf)
  return pullback(f, II)
end

function total_transform(f::AbsBlowupMorphism, II::AbsIdealSheaf)
  return pullback(f, II)
end
