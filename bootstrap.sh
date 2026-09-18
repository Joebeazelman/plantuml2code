#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Building plantuml2code"
cd plantuml2code
alr build 2>&1 | tail -3
cd ..

echo
echo "==> Generating state machine into gen_test"
mkdir -p /tmp/bootstrap/gen
( cd plantuml2code && ./bin/plantuml2code dump -f ada \
    -o /tmp/bootstrap/gen ../samples/nested.puml )
cp /tmp/bootstrap/gen/*.ads /tmp/bootstrap/gen/*.adb gen_test/src/

echo
echo "==> Generating class model into class_test"
mkdir -p /tmp/bootstrap/genclass
( cd plantuml2code && ./bin/plantuml2code dump -f ada \
    -o /tmp/bootstrap/genclass ../samples/zoo.puml )
cp /tmp/bootstrap/genclass/*.ads /tmp/bootstrap/genclass/*.adb class_test/src/

echo
echo "==> Building gen_test"
cd gen_test && alr build 2>&1 | tail -3
cd ..

echo
echo "==> Building class_test"
cd class_test && alr build 2>&1 | tail -3
cd ..

echo
echo "==> Running samples"
gen_test/bin/gen_test
echo
class_test/bin/class_test
