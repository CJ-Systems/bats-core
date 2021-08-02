load test_helper
fixtures run

@test "run --keep-empty-lines preserves leading empty lines" {
    run --keep-empty-lines -- echo -n $'\na'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == '' ]
    [ "${lines[1]}" == a ]
    [ ${#lines[@]} -eq 2 ]
}

@test "run --keep-empty-lines preserves inner empty lines" {
    run --keep-empty-lines -- echo -n $'a\n\nb'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ "${lines[2]}" == b ]
    [ ${#lines[@]} -eq 3 ]
}

@test "run --keep-empty-lines preserves trailing empty lines" {
    run --keep-empty-lines -- echo -n $'a\n'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ ${#lines[@]} -eq 2 ]
}

@test "run --keep-empty-lines preserves multiple trailing empty lines" {
    run --keep-empty-lines -- echo -n $'a\n\n'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ "${lines[2]}" == '' ]
    [ ${#lines[@]} -eq 3 ]
}

@test "run --keep-empty-lines preserves non-empty trailing line" {
    run --keep-empty-lines -- echo -n $'a\nb'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == b ]
    [ ${#lines[@]} -eq 2 ]
}

print-stderr-stdout() {
    printf stdout
    printf stderr >&2
}

@test "run --output stdout does not print stderr" {   
    run --output stdout -- print-stderr-stdout
    echo "output='$output' stderr='$stderr'"
    [ "$output" = "stdout" ]
    [ ${#lines[@]} -eq 1 ]

    [ "${stderr-notset}" = notset ]
    [ ${#stderr_lines[@]} -eq 0 ]
}

@test "run --output stderr does not print stdout" {
    run --output stderr -- print-stderr-stdout
    echo "output='$output' stderr='$stderr'"
    [ "${output-notset}" = notset ]
    [ ${#lines[@]} -eq 0 ]

    [ "$stderr" = stderr ]
    [ ${#stderr_lines[@]} -eq 1 ]
}

@test "run --output separate splits output" {
    run --output separate -- print-stderr-stdout
    echo "output='$output' stderr='$stderr'"
    [ "$output" = stdout ]
    [ ${#lines[@]} -eq 1 ]

    [ "$stderr" = stderr ]
    [ ${#stderr_lines[@]} -eq 1 ]
}

@test "run does not change set flags" {
    old_flags="$-"
    run true
    echo -- "$-" == "$old_flags"
    [ "$-" == "$old_flags" ]
}

# Positive assertions: each of these should succeed
@test "basic return-code checking" {
  run      true
  run =0   true
  run '!'  false
  run =1   false
  run =3   exit 3
  run =5   exit 5
  run =111 exit 111
  run =255 exit 255
  run =127 /no/such/command
}

@test "run exit code check output " {
  run ! bats --tap "${FIXTURE_ROOT}/failing.bats"
  echo "$output"
  [ "${lines[0]}" == 1..5 ]
  [ "${lines[1]}" == "not ok 1 run =0 false" ]
  [ "${lines[2]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 1)" ]
  [ "${lines[3]}" == "#   \`@test \"run =0 false\" {' failed" ]
  [ "${lines[4]}" == "#     expected exit code 0, got 1" ]
  [ "${lines[5]}" == "not ok 2 run =1 echo hi" ]
  [ "${lines[6]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 5)" ]
  [ "${lines[7]}" == "#   \`@test \"run =1 echo hi\" {' failed" ]
  [ "${lines[8]}" == "#     expected exit code 1, got 0" ]
  [ "${lines[9]}" == "not ok 3 run =2 exit 3" ]
  [ "${lines[10]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 9)" ]
  [ "${lines[11]}" == "#   \`@test \"run =2 exit 3\" {' failed with status 3" ]
  [ "${lines[12]}" == "#     expected exit code 2, got 3" ]
  [ "${lines[13]}" == "not ok 4 run ! true" ]
  [ "${lines[14]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 13)" ]
  [ "${lines[15]}" == "#   \`@test \"run ! true\" {' failed" ]
  [ "${lines[16]}" == "#     expected nonzero exit code!" ]
  [ "${lines[17]}" == "not ok 5 run multiple pass/fails" ]
  [ "${lines[18]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 17)" ]
  [ "${lines[19]}" == "#   \`@test \"run multiple pass/fails\" {' failed" ]
  [ "${lines[20]}" == "#     expected exit code 1, got 126" ]
}

@test "run invalid exit code check error message" {
  run ! bats --tap "${FIXTURE_ROOT}/invalid.bats"
  echo "$output"
  [ "${lines[0]}" == 1..2 ]
  [ "${lines[1]}" == "not ok 1 run =4evah echo hi" ]
  [ "${lines[2]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/invalid.bats, line 2)" ]
  [ "${lines[3]}" == "#   \`run =4evah echo hi' failed" ]
  [ "${lines[4]}" == "# Usage error: run: '=NNN' requires numeric NNN (got: 4evah)" ]
  [ "${lines[5]}" == "not ok 2 run =256 echo hi" ]
  [ "${lines[6]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/invalid.bats, line 6)" ]
  [ "${lines[7]}" == "#   \`run =256 echo hi' failed" ]
  [ "${lines[8]}" == "# Usage error: run: '=NNN': NNN must be <= 255 (got: 256)" ]
}
