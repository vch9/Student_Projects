#ifndef MATHEXT_H
#define MATHEXT_H

#include "stdbool.h"
#include "assert.h"
#include "pervasives.h"

#include "hept_ffi.h"

DECLARE_HEPT_FUN(Mathext, float, (int), float o);
DECLARE_HEPT_FUN(Mathext, int, (float), int o);
DECLARE_HEPT_FUN(Mathext, floor, (float), float o);

DECLARE_HEPT_FUN(Mathext, sin, (float), float o);
DECLARE_HEPT_FUN(Mathext, cos, (float), float o);
DECLARE_HEPT_FUN(Mathext, atan2, (float, float), float o);
DECLARE_HEPT_FUN(Mathext, hypot, (float, float), float o);
DECLARE_HEPT_FUN(Mathext, sqrt, (float), float o);
DECLARE_HEPT_FUN(Mathext, pow, (float, float), float o);

DECLARE_HEPT_FUN(Mathext, fmod, (float, float), float o);

DECLARE_HEPT_FUN(Mathext, piano_freq_of_key, (int), float f);

static const float Mathext__pi = 3.14115;

#endif  /* MATHEXT_H */
