/-
Copyright (c) 2025 Calle Sönne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Calle Sönne, Fernando Chu, Christian Merten
-/

import Mathlib.CategoryTheory.Bicategory.Grothendieck
import Mathlib.CategoryTheory.FiberedCategory.HasFibers

/-!
# The fibered category associated to a pseudofunctor

Given a category `𝒮` and any pseudofunctor valued in `Cat` we associate to it a fibered category
category `F.toFibered ⥤ 𝒮`.

The category `F.toFibered` is defined as follows:
* Objects: pairs `(S, a)` where `S` is an object of the base category and `a` is an object of the
  category `F(S)`
* Morphisms: morphisms `(R, b) ⟶ (S, a)` are defined as pairs `(f, h)` where `f : R ⟶ S` is a
  morphism in `𝒮` and `h : b ⟶ F(f)(a)`

The projection functor `F.toFibered ⥤ 𝒮` is then given by projecting to the first factors, i.e.
* On objects, it sends `(S, a)` to `S`
* On morphisms, it sends `(f, h)` to `f`

We also provide a `HasFibers` instance `F.toFibered`, such that the fiber over `S` is the
category `F(S)`.

## References
[Vistoli2008] "Notes on Grothendieck Topologies, Fibered Categories and Descent Theory" by
Angelo Vistoli

-/

namespace CategoryTheory

universe w v₁ v₂ v₃ u₁ u₂ u₃

open CategoryTheory Functor Category Opposite Discrete Bicategory Pseudofunctor.Grothendieck

variable {𝒮 : Type u₁} [Category.{v₁} 𝒮] {F : Pseudofunctor (LocallyDiscrete 𝒮ᵒᵖ) Cat.{v₂, u₂}}

section

variable {R S : 𝒮} (a : F.obj ⟨op S⟩) (f : R ⟶ S)

/-- The domain of the cartesian lift of `f`. -/
abbrev domainCartesianLift : ∫ F := ⟨R, (F.map f.op.toLoc).obj a⟩

/-- The cartesian lift of `f`. -/
abbrev cartesianLift : domainCartesianLift a f ⟶ ⟨S, a⟩ := ⟨f, 𝟙 _⟩

instance isHomLift_cartesianLift : IsHomLift (forget F) f (cartesianLift a f) :=
  -- TODO: name instIsHomLift
  instIsHomLiftMap (forget F) (cartesianLift a f)

/-- Given some lift `g` of `f`, the canonical map from the domain of `g` to the domain of
the cartesian lift of `f`. -/
-- TODO a implicit here?
abbrev homCartesianLift {a : F.obj ⟨op S⟩} (f : R ⟶ S) {a' : ∫ F} (g : a'.1 ⟶ R)
    (φ' : a' ⟶ ⟨S, a⟩) [IsHomLift (forget F) (g ≫ f) φ'] : a' ⟶ domainCartesianLift a f where
  base := g
  fiber :=
    have : φ'.base = g ≫ f := by simpa using IsHomLift.fac' (forget F) (g ≫ f) φ'
    φ'.fiber ≫ eqToHom (by simp [this]) ≫ (F.mapComp f.op.toLoc g.op.toLoc).hom.app a

instance isHomLift_homCartesianLift {a : F.obj ⟨op S⟩} (f : R ⟶ S) {a' : ∫ F}
    {φ' : a' ⟶ ⟨S, a⟩} {g : a'.1 ⟶ R} [IsHomLift (forget F) (g ≫ f) φ'] :
      IsHomLift (forget F) g (homCartesianLift f g φ') :=
  instIsHomLiftMap (forget F) (homCartesianLift f g φ')

lemma isStronglyCartesian_homCartesianLift :
    IsStronglyCartesian (forget F) f (cartesianLift a f) where
  universal_property' {a'} g φ' hφ' := by
    refine ⟨homCartesianLift f g φ', ⟨inferInstance, ?_⟩, ?_⟩
    · exact Hom.ext _ _ (by simpa using IsHomLift.fac (forget F) (g ≫ f) φ') (by simp)
    rintro χ' ⟨hχ'.symm, rfl⟩
    obtain ⟨rfl⟩ : g = χ'.1 := by simpa using IsHomLift.fac (forget F) g χ'
    ext <;> simp

end

/-- `forget F : ∫ F ⥤ 𝒮` is a fibered category. -/
instance : IsFibered (forget F) :=
  IsFibered.of_exists_isStronglyCartesian (fun a _ f ↦
    ⟨domainCartesianLift a.2 f, cartesianLift a.2 f, isStronglyCartesian_homCartesianLift a.2 f⟩)

-- section?
variable (F) (S : 𝒮)

@[simps]
def ι : F.obj ⟨op S⟩ ⥤ ∫ F where
  obj a := { base := S, fiber := a}
  map {a b} φ := { base := 𝟙 S, fiber := φ ≫ (F.mapId ⟨op S⟩).inv.app b}
  map_comp {a b c} φ ψ := by
    ext
    · simp
    · simp [← (F.mapId ⟨op S⟩).inv.naturality_assoc ψ, F.whiskerRight_mapId_inv_app,
        Strict.leftUnitor_eqToIso, Strict.rightUnitor_eqToIso]

@[simps]
def comp_iso : (ι F S) ⋙ forget F ≅ (const (F.obj ⟨op S⟩)).obj S where
  hom := { app := fun a => 𝟙 _ }
  inv := { app := fun a => 𝟙 _ }

lemma comp_const : (ι F S) ⋙ forget F = (const (F.obj ⟨op S⟩)).obj S := by
  apply Functor.ext_of_iso (comp_iso F S) <;> simp

noncomputable instance : Functor.Full (Fiber.inducedFunctor (comp_const F S)) where
  map_surjective {X Y} f := by
    have := f.2 -- TODO: synthesize this
    have hf : f.1.1 = 𝟙 S := by simpa using (IsHomLift.fac (forget F) (𝟙 S) f.1).symm
    use f.1.2 ≫ eqToHom (by simp [hf]) ≫ (F.mapId ⟨op S⟩).hom.app Y
    ext <;> simp [hf]

instance : Functor.Faithful (Fiber.inducedFunctor (comp_const F S)) where
  map_injective := by
    intros a b f g heq
    -- can be made a one liner...
    rw [← Subtype.val_inj] at heq
    obtain ⟨_, heq₂⟩ := (hom_ext_iff _ _).1 heq
    simpa [cancel_mono] using heq₂

noncomputable instance : Functor.EssSurj (Fiber.inducedFunctor (comp_const F S)) := by
  apply essSurj_of_surj
  intro Y
  have hYS : Y.1.1 = S := by simpa using Y.2
  use (hYS.symm ▸ Y.1.2)
  apply Subtype.val_inj.1
  ext <;> simp [hYS]

noncomputable instance : Functor.IsEquivalence (Fiber.inducedFunctor (comp_const F S)) where

noncomputable instance : HasFibers (forget F) where
  Fib S := F.obj ⟨op S⟩
  ι := ι F
  comp_const := comp_const F

end CategoryTheory
