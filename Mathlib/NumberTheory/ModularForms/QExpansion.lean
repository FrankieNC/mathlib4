/-
Copyright (c) 2024 David Loeffler. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: David Loeffler
-/
import Mathlib.Analysis.Complex.TaylorSeries
import Mathlib.Analysis.Complex.UpperHalfPlane.Exp
import Mathlib.NumberTheory.ModularForms.Identities
import Mathlib.NumberTheory.ModularForms.SlashCompose
import Mathlib.RingTheory.PowerSeries.Basic

/-!
# q-expansions of modular forms

We show that any modular form of level `Γ` can be written as `τ ↦ F (𝕢 n τ)` where `F` is
analytic on the open unit disc, and `𝕢 n` is the parameter `τ ↦ exp (2 * I * π * τ / n)`, for `n`
divisible by the cusp width of `Γ`. As an application, we show that cusp forms decay exponentially
to 0 as `im τ → ∞`.

We also define the `q`-expansion of a modular form, either as a power series or as a
`FormalMultlinearSeries`, and show that it converges to `f` on the upper half plane.

## Main definitions and results

* `SlashInvariantFormClass.cuspFunction`: for a level `n` slash-invariant form, this is the function
  `F` such that `f τ = F (exp (2 * π * I * τ / n))`, extended by a choice of limit at `0`.
* `ModularFormClass.differentiableAt_cuspFunction`: when `f` is a modular form, its `cuspFunction`
  is differentiable on the open unit disc (including at `0`).
* `ModularFormClass.qExpansion`: the `q`-expansion of a modular form (defined as the Taylor series
  of its `cuspFunction`), bundled as a `PowerSeries`.
* `ModularFormClass.hasSum_qExpansion`: the `q`-expansion evaluated at `𝕢 n τ` sums to `f τ`, for
  `τ` in the upper half plane.

## TO DO:

* define the `q`-expansion map on modular form spaces as a linear map (or even a ring hom from
  the graded ring of all modular forms?)
-/

open ModularForm Complex Filter UpperHalfPlane Function

open scoped Real MatrixGroups CongruenceSubgroup

noncomputable section

variable {k : ℤ} {F : Type*} [FunLike F ℍ ℂ] {Γ : Subgroup SL(2, ℤ)}
  {n : ℕ} (f : F) (τ : ℍ) {z q : ℂ}

local notation "I∞" => comap Complex.im atTop
local notation "𝕢" => Periodic.qParam

namespace SlashInvariantFormClass

variable (n) in
/--
The analytic function `F` such that `f τ = F (exp (2 * π * I * τ / n))`, extended by a choice of
limit at `0`.
-/
def cuspFunction : ℂ → ℂ := Function.Periodic.cuspFunction n (f ∘ ofComplex)

variable [hF : SlashInvariantFormClass F Γ k]
include hF

theorem periodic_comp_ofComplex (hn : Γ.width ∣ n) : Periodic (f ∘ ofComplex) n := by
  intro w
  by_cases hw : 0 < im w
  · have : 0 < im (w + n) := by simp only [add_im, natCast_im, add_zero, hw]
    simp only [comp_apply, ofComplex_apply_of_im_pos this, ofComplex_apply_of_im_pos hw,
      ← vAdd_width_periodic f k (Nat.cast_dvd_cast hn) ⟨w, hw⟩]
    congr 1
    simp [UpperHalfPlane.ext_iff, add_comm]
  · have : im (w + n) ≤ 0 := by simpa only [add_im, natCast_im, add_zero, not_lt] using hw
    simp only [comp_apply, ofComplex_apply_of_im_nonpos this,
      ofComplex_apply_of_im_nonpos (not_lt.mp hw)]

theorem eq_cuspFunction {τ : ℍ} [NeZero n] (hn : Γ.width ∣ n) :
    cuspFunction n f (𝕢 n τ) = f τ := by
  simpa using (periodic_comp_ofComplex f hn).eq_cuspFunction (NeZero.ne _) τ

end SlashInvariantFormClass

open SlashInvariantFormClass

namespace ModularFormClass
-- These declarations don't logically need `f` to be a modular form (although they are pretty
-- useless without!)

variable (n) in
/-- The `q`-expansion of a level `n` modular form, bundled as a `PowerSeries`. -/
def qExpansion : PowerSeries ℂ :=
  .mk fun m ↦ (↑m.factorial)⁻¹ * iteratedDeriv m (cuspFunction n f) 0

lemma qExpansion_coeff (m : ℕ) :
    (qExpansion n f).coeff ℂ m = (↑m.factorial)⁻¹ * iteratedDeriv m (cuspFunction n f) 0 := by
  simp [qExpansion]

variable (n) in
/--
The `q`-expansion of a level `n` modular form, bundled as a `FormalMultilinearSeries`.

TODO: Maybe get rid of this and instead define a general API for converting `PowerSeries` to
`FormalMultlinearSeries`.
-/
def qExpansionFormalMultilinearSeries : FormalMultilinearSeries ℂ ℂ ℂ :=
  fun m ↦ (qExpansion n f).coeff ℂ m • ContinuousMultilinearMap.mkPiAlgebraFin ℂ m _

lemma qExpansionFormalMultilinearSeries_apply_norm (m : ℕ) :
    ‖qExpansionFormalMultilinearSeries n f m‖ = ‖(qExpansion n f).coeff ℂ m‖ := by
  rw [qExpansionFormalMultilinearSeries,
    ← (ContinuousMultilinearMap.piFieldEquiv ℂ (Fin m) ℂ).symm.norm_map]
  simp

variable [hF : ModularFormClass F Γ k]
include hF

theorem differentiableAt_comp_ofComplex (hz : 0 < im z) :
    DifferentiableAt ℂ (f ∘ ofComplex) z :=
  mdifferentiableAt_iff_differentiableAt.mp ((holo f _).comp z (mdifferentiableAt_ofComplex hz))

theorem bounded_at_infty_comp_ofComplex :
    BoundedAtFilter I∞ (f ∘ ofComplex) := by
  simpa only [SlashAction.slash_one, ModularForm.toSlashInvariantForm_coe]
    using (ModularFormClass.bdd_at_infty f 1).comp_tendsto tendsto_comap_im_ofComplex

variable [NeZero n] (hn : Γ.width ∣ n)
include hn

theorem differentiableAt_cuspFunction  (hq : ‖q‖ < 1) :
    DifferentiableAt ℂ (cuspFunction n f) q := by
  have npos : 0 < (n : ℝ) := mod_cast (Nat.pos_iff_ne_zero.mpr (NeZero.ne _))
  rcases eq_or_ne q 0 with rfl | hq'
  · exact (periodic_comp_ofComplex f hn).differentiableAt_cuspFunction_zero npos
      (eventually_of_mem (preimage_mem_comap (Ioi_mem_atTop 0))
        (fun _ ↦ differentiableAt_comp_ofComplex f))
      (bounded_at_infty_comp_ofComplex f)
  · exact Periodic.qParam_right_inv npos.ne' hq' ▸
      (periodic_comp_ofComplex f hn).differentiableAt_cuspFunction npos.ne'
        <| differentiableAt_comp_ofComplex _ <| Periodic.im_invQParam_pos_of_norm_lt_one npos hq hq'

lemma analyticAt_cuspFunction_zero :
    AnalyticAt ℂ (cuspFunction n f) 0 :=
  DifferentiableOn.analyticAt
    (fun q hq ↦ (differentiableAt_cuspFunction _ hn hq).differentiableWithinAt)
    (by simpa only [ball_zero_eq] using Metric.ball_mem_nhds (0 : ℂ) zero_lt_one)

lemma hasSum_qExpansion_of_abs_lt (hq : ‖q‖ < 1) :
    HasSum (fun m ↦ (qExpansion n f).coeff ℂ m • q ^ m) (cuspFunction n f q) := by
  simp only [qExpansion_coeff, ← eq_cuspFunction f hn]
  have hdiff : DifferentiableOn ℂ (cuspFunction n f) (Metric.ball 0 1) := by
    refine fun z hz ↦ (differentiableAt_cuspFunction f hn ?_).differentiableWithinAt
    simpa using hz
  have qmem : q ∈ Metric.ball 0 1 := by simpa using hq
  convert hasSum_taylorSeries_on_ball hdiff qmem using 2 with m
  rw [sub_zero, smul_eq_mul, smul_eq_mul, mul_right_comm, smul_eq_mul, mul_assoc]

lemma hasSum_qExpansion :
    HasSum (fun m : ℕ ↦ (qExpansion n f).coeff ℂ m • 𝕢 n τ ^ m) (f τ) := by
  simpa only [eq_cuspFunction f hn] using
    hasSum_qExpansion_of_abs_lt f hn (τ.norm_qParam_lt_one n)

lemma qExpansionFormalMultilinearSeries_radius :
    1 ≤ (qExpansionFormalMultilinearSeries n f).radius := by
  refine le_of_forall_lt_imp_le_of_dense fun r hr ↦ ?_
  lift r to NNReal using hr.ne_top
  apply FormalMultilinearSeries.le_radius_of_summable
  simp only [qExpansionFormalMultilinearSeries_apply_norm]
  rw [← r.abs_eq]
  simp_rw [← Real.norm_eq_abs, ← Complex.norm_real, ← norm_pow, ← norm_mul]
  exact (hasSum_qExpansion_of_abs_lt f hn (by simpa using hr)).summable.norm

/-- The `q`-expansion of `f` is an `FPowerSeries` representing `cuspFunction n f`. -/
lemma hasFPowerSeries_cuspFunction :
    HasFPowerSeriesOnBall (cuspFunction n f) (qExpansionFormalMultilinearSeries n f) 0 1 := by
  refine ⟨qExpansionFormalMultilinearSeries_radius f hn, zero_lt_one, fun {y} hy ↦ ?_⟩
  replace hy : ‖y‖ < 1 := by simpa [enorm_eq_nnnorm, ← NNReal.coe_lt_one] using hy
  simpa [qExpansionFormalMultilinearSeries] using hasSum_qExpansion_of_abs_lt f hn hy

end ModularFormClass

open ModularFormClass

namespace CuspFormClass

variable [hF : CuspFormClass F Γ k]
include hF

theorem zero_at_infty_comp_ofComplex : ZeroAtFilter I∞ (f ∘ ofComplex) := by
  simpa using (zero_at_infty f 1).comp tendsto_comap_im_ofComplex

theorem cuspFunction_apply_zero [NeZero n] : cuspFunction n f 0 = 0 :=
  Periodic.cuspFunction_zero_of_zero_at_inf (mod_cast (Nat.pos_iff_ne_zero.mpr (NeZero.ne _)))
    (zero_at_infty_comp_ofComplex f)

theorem exp_decay_atImInfty [NeZero n] (hn : Γ.width ∣ n) :
    f =O[atImInfty] fun τ ↦ Real.exp (-2 * π * τ.im / n) := by
  simpa [comp_def] using
    ((periodic_comp_ofComplex f hn).exp_decay_of_zero_at_inf
      (mod_cast (Nat.pos_iff_ne_zero.mpr (NeZero.ne _)))
      (eventually_of_mem (preimage_mem_comap (Ioi_mem_atTop 0))
        fun _ ↦ differentiableAt_comp_ofComplex f)
      (zero_at_infty_comp_ofComplex f)).comp_tendsto tendsto_coe_atImInfty

theorem exp_decay_atImInfty' [Γ.FiniteIndex] :
    ∃ a, 0 < a ∧ f =O[atImInfty] fun τ ↦ Real.exp (-a * τ.im) := by
  have := Γ.width_ne_zero
  have := NeZero.mk this
  refine ⟨2 * π / Γ.width, by positivity, ?_⟩
  convert exp_decay_atImInfty f dvd_rfl using 3
  ring

theorem exp_decay_slash [Γ.FiniteIndex] (γ : SL(2, ℤ)) :
    ∃ a, 0 < a ∧ (f ∣[k] γ) =O[atImInfty] fun τ ↦ Real.exp (-a * τ.im) := by
  suffices (Γ.map <| MulAut.conj γ⁻¹ : Subgroup SL(2, ℤ)).FiniteIndex from
    exp_decay_atImInfty' (CuspFormClass.translate f γ)
  constructor
  rw [Γ.index_map_of_bijective (EquivLike.bijective _)]
  apply Subgroup.FiniteIndex.index_ne_zero

end CuspFormClass
