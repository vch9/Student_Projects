#!/bin/bash


ocamlc -c types.ml
ocamlc -c sat_solver.mli
ocamlc -c sat_solver.ml
ocamlc -c affichage.ml
ocamlc -c creation.ml
ocamlc -c create_dnf.ml
ocamlc -c dnf_to_cnf.ml
ocamlc -c buttons.ml
ocamlc -c jeu.ml
ocamlc -c lancement.ml

ocamlc -g -o jeu unix.cma graphics.cma types.cmo sat_solver.cmo affichage.cmo creation.cmo create_dnf.cmo dnf_to_cnf.cmo buttons.cmo jeu.cmo lancement.cmo

rm *.cmi *.cmo