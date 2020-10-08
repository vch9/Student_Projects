Require Export Bool List Equalities Orders Setoid Morphisms.
Import ListNotations.

(** * Languages are sets of words over some type of letters *)

Module Lang (Letter : Typ).

Definition word := list Letter.t.
Definition t := word -> Prop.

Bind Scope lang_scope with t.
Delimit Scope lang_scope with lang.
Local Open Scope lang_scope.

Implicit Type a : Letter.t.
Implicit Type w : word.
Implicit Type L : t.

Definition eq L L' := forall x, L x <-> L' x.

Definition void : t := fun _ => False.
Definition epsilon : t := fun w => w = [].
Definition singleton a : t := fun w => w = [a].

Definition cat L L' : t :=
  fun x => exists y z, x = y++z /\ L y /\ L' z.

Definition union L L' : t := fun w => L w \/ L' w.

Definition inter L L' : t := fun w => L w /\ L' w.

Fixpoint power L n : t :=
  match n with
  | 0 => epsilon
  | S n' => cat L (power L n')
  end.

(** Kleene's star *)

Definition star L : t := fun w => exists n, power L n w.

(** language complement *)

Definition comp L : t := fun w => ~(L w).

(** Languages : notations **)

Module Notations.
Infix "==" := Lang.eq (at level 70).
Notation "∅" := void : lang_scope. (* \emptyset *)
Notation "'ε'" := epsilon : lang_scope. (* \epsilon *)
Coercion singleton : Letter.t >-> Lang.t.
Infix "·" := cat (at level 35) : lang_scope. (* \cdot *)
Infix "∪" := union (at level 50) : lang_scope. (* \cup *)
Infix "∩" := inter (at level 40) : lang_scope. (* \cap *)
Infix "^" := power : lang_scope.
Notation "L ★" := (star L) (at level 30) : lang_scope. (* \bigstar *)
Notation "¬ L" := (comp L) (at level 65): lang_scope. (* \neg *)
End Notations.
Import Notations.

(** Technical stuff to be able to rewrite with respect to "==" *)

Instance : Equivalence eq.
Proof. firstorder. Qed.

Instance cat_eq : Proper (eq ==> eq ==> eq) cat.
Proof. firstorder. Qed.
Instance inter_eq : Proper (eq ==> eq ==> eq) inter.
Proof. firstorder. Qed.
Instance union_eq : Proper (eq ==> eq ==> eq) union.
Proof. firstorder. Qed.
Instance comp_eq : Proper (eq ==> eq) comp.
Proof. firstorder. Qed.
Instance power_eq : Proper (eq ==> Logic.eq ==> eq) power.
Proof.
 intros x x' Hx n n' <-. induction n; simpl; now rewrite ?IHn, ?Hx.
Qed.

Instance cat_eq' : Proper (eq ==> eq ==> Logic.eq ==> iff) cat.
Proof. intros x x' Hx y y' Hy w w' <-. now apply cat_eq. Qed.
Instance inter_eq' : Proper (eq ==> eq ==> Logic.eq ==> iff) inter.
Proof. intros x x' Hx y y' Hy w w' <-. now apply inter_eq. Qed.
Instance union_eq' : Proper (eq ==> eq ==> Logic.eq ==> iff) union.
Proof. intros x x' Hx y y' Hy w w' <-. now apply union_eq. Qed.
Instance comp_eq' : Proper (eq ==> Logic.eq ==> iff) comp.
Proof. intros x x' Hy w w' <-. now apply comp_eq. Qed.
Instance power_eq' : Proper (eq ==> Logic.eq ==> Logic.eq ==> iff) power.
Proof. intros x x' Hx n n' <- w w' <-. now apply power_eq. Qed.

Instance star_eq : Proper (eq ==> eq) star.
Proof.
 intros x x' Hx w. unfold star. now setoid_rewrite <- Hx.
Qed.

Instance star_eq' : Proper (eq ==> Logic.eq ==> iff) star.
Proof. intros x x' Hx w w' <-. now apply star_eq. Qed.

(** Languages : misc properties *)

Lemma cat_void_l L : ∅ · L == ∅.
Proof.
  unfold void.
  unfold cat.
  unfold eq.
  split.
  + intros.
    repeat destruct H.
    destruct H0.
    intuition.
  + intros.
    intuition.
Qed.

Lemma cat_void_r L :  L · ∅ == ∅.
Proof.
  unfold void.
  unfold cat.
  unfold eq.
  split.
  + intros.
    repeat destruct H.
    destruct H0.
    intuition.
  + intros.
    intuition.
Qed.

Lemma cat_eps_l L : ε · L == L.
Proof.
  unfold epsilon.
  unfold cat.
  unfold eq.
  split.
  + intros.
    destruct H.
    destruct H.
    destruct H.
    rewrite H.
    destruct H0.
    rewrite H0.
    simpl.
    intuition.
  + intros.
    exists [].
    exists x.
    simpl.
    intuition.
Qed.

Lemma cat_eps_r L : L · ε == L.
Proof.
  unfold epsilon.
  unfold cat.
  unfold eq.
  split.
  + intros.
    destruct H. destruct H. destruct H.
    rewrite H.
    destruct H0.
    rewrite H1.
    replace (x0 ++ []) with (x0).
    - intuition.
    - intuition.
  + intros.
    exists x.
    exists [].
    intuition.
    symmetry.
    apply app_nil_r.
Qed.


Lemma cat_assoc L1 L2 L3 : (L1 · L2) · L3 == L1 · (L2 · L3).
Proof.
  unfold cat, eq.
  intros.
  split.
  + intros.
    destruct H, H, H.
    destruct H0, H0, H0, H0, H2.
    rewrite H0 in H.
    rewrite <- app_assoc in H.
    exists x2, (x3 ++ x1).
    intuition.
    exists x3, x1.
    intuition.
  + intros.
    destruct H, H, H.
    destruct H0, H1, H1, H1, H2.
    rewrite H1 in H.
    exists (x0 ++ x2), x3.
    rewrite <- app_assoc.
    intuition.
    exists x0, x2.
    intuition.
Qed.

Lemma star_eqn L : L★ == ε ∪ L · L ★.
Proof.
  unfold union, eq.
  intros. split.
  +
    unfold star. 
    intros. destruct H. induction x0.
    - auto.
    - simpl in H.
      unfold cat in H.
      destruct H, H, H, H0.
      right.
      exists x1, x2.
      intuition.
      exists x0.
      intuition.
  + intros.
    destruct H.
    - exists 0. intuition.
    - destruct H, H, H, H0, H1.
      unfold star in *.
      exists (S x2).
      simpl.
      unfold cat.
      exists x0, x1.
      auto.
Qed.

Lemma star_void : ∅ ★ == ε.
Proof.
  unfold void, star, epsilon, eq.
  intros.
  split.
  + intros.
    destruct H.
    induction x0.
    - simpl in H.
      rewrite H.
      intuition.
    - apply IHx0.
      simpl in H.
      unfold cat in H.
      destruct H, H, H, H0.
      intuition.
  + intros.
    exists 0.
    simpl.
    intuition.
Qed.

Lemma power_eps n : ε ^ n == ε.
Proof.
  induction n.
  + easy.
  + simpl.
    rewrite IHn.
    apply cat_eps_l.
Qed.

Lemma star_eps : ε ★ == ε.
Proof.
  unfold star.
  split.
  + intros.
    destruct H.
    apply power_eps in H.
    intuition.
  + intros.
    exists 0.
    apply power_eps.
    intuition.
Qed.

Lemma power_cat n m L : L^(n+m) == (L^n) · (L^m).
Proof.
  induction n.
  + simpl. rewrite cat_eps_l. easy.
  + simpl. rewrite cat_assoc, IHn. easy.
Qed.

Lemma power_app n m y z L :
 (L^n) y -> (L^m) z -> (L^(n+m)) (y++z).
Proof.
  intros.
  rewrite (power_cat n m L (y++z)).
  unfold cat.
  exists y, z.
  intuition.
Qed. 

Lemma star_star L : (L★)★ == L★.
Proof.
Admitted.

Lemma aux_1 {A:Type}: forall l : list A, l ++ [] = l.

intro. induction l. simpl. reflexivity. simpl. f_equal. assumption. Qed.

Lemma aux_2 L :(L ★) [].
Proof. 
unfold star. exists 0. simpl. easy. Qed.


Lemma cat_star L : (L★)·(L★) == L★.

Proof.
split. intro.
unfold star.
unfold star in H. destruct H.
destruct H. destruct H. destruct H0.
destruct H0.
destruct H1.
exists (x2+x3).
rewrite H.
apply power_app.
easy.
easy.
intro.
unfold cat. exists x. exists []. split.
rewrite aux_1. reflexivity.
split. easy. apply aux_2. Qed.

(** ** Derivative of a language : definition **)

Definition derivative L w : t := fun x => L (w++x).

Instance derivative_eq : Proper (eq ==> Logic.eq ==> eq) derivative.
Proof. intros L L' HL w w' <-. unfold derivative. intro. apply HL. Qed.

(** ** Derivative of a language : properties **)

Lemma derivative_app L w w' :
  derivative L (w++w') == derivative (derivative L w) w'.
Proof.
  unfold derivative, eq.
  intros.
  rewrite app_assoc.
  split.
  + intros. assumption.
  + intros. assumption.
Qed.

Lemma derivative_letter_eps a : derivative a [a] == ε.
Proof.
  split.
  + induction x.
    - intros. unfold epsilon. easy.
    - intros. unfold epsilon. discriminate.
  + induction x.
    - easy.
    - easy.
Qed.

Lemma derivative_letter_void a1 a2 : a1 <> a2 -> derivative a1 [a2] == ∅.
Proof.
  unfold void. intros. split.
  + intros. unfold derivative in H0. red in H0. induction x.
    - simpl in H0. congruence.
    - apply IHx. easy.
  + intros. easy.
Qed.

Lemma derivative_cat_null L L' a : L [] ->
  derivative (L · L') [a] == (derivative L [a] · L') ∪ derivative L' [a].
Proof.
Admitted.

Lemma derivative_cat_nonnull L L' a : ~L [] ->
  derivative (L · L') [a] == derivative L [a] · L'.
Proof.
Admitted.

Lemma derivative_star L a :
  derivative (L★) [a] == (derivative L [a]) · (L★).
Proof.
Admitted.

End Lang.
