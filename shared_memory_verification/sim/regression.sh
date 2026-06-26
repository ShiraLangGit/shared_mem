#!/bin/bash
# regression.sh — הרצת coverage regression (טסט אחד שמכיל הכל + IMC)
#
#   ./sim/regression.sh
#   ./sim/regression.sh --clean
#
# מה זה עושה:
#   1. מריץ test_coverage_regression (FAC + WiFi + BT בסימולציה אחת)
#   2. אוסף functional coverage
#   3. פותח IMC
#
# לבדיקת כל טסט בנפרד (בלי coverage):  ./sim/run.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/run.sh" regression "$@"
