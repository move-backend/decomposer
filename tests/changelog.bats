load helpers/variables
load helpers/hooks
load helpers/main
load helpers/creations
load helpers/assertions

# This suite tests the "generate-changelog" command

SUITE_NAME=$( test_suite_name )

@test "${SUITE_NAME}: changelog pointing to inaccessible location" {
  create_decomposer_json alpha_psr4

  run_decomposer generate-changelog --file '/root/changelog.fail'
  [ "${status}" -eq 1 ]
  [ "${lines[0]}" = "decomposer: Changelog file '/root/changelog.fail' is not writable." ]

  [[ ! -f "/root/changelog.fail" ]]
}

@test "${SUITE_NAME}: changelog pointing to non writable file" {
  create_decomposer_json alpha_psr4

  touch "${TEST_WORKING_DIR}/decomposer.diffnotes.md"
  chmod -w "${TEST_WORKING_DIR}/decomposer.diffnotes.md"

  run_decomposer generate-changelog --file "${TEST_WORKING_DIR}/decomposer.diffnotes.md"
  [ "${status}" -eq 1 ]
  [ "${lines[0]}" = "decomposer: Changelog file '${TEST_WORKING_DIR}/decomposer.diffnotes.md' is not writable." ]
}

@test "${SUITE_NAME}: writes lib log, default file" {
  create_decomposer_json alpha_psr4

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  sleep 1

  # new commit in cloned library
  git -C "${DECOMPOSER_TARGET_DIR}/Alpha-1.0" commit \
    --allow-empty --message 'extra commit'

  run_decomposer generate-changelog -t '2 seconds ago'
  [ "${status}" -eq 0 ]

  cat "${TEST_WORKING_DIR}/decomposer.diffnotes.md"
  assert_changelog_file "${TEST_WORKING_DIR}/decomposer.diffnotes.md" changelog_lib_add
}

@test "${SUITE_NAME}: writes lib custom log, absolute path" {
  create_decomposer_json alpha_psr4

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  sleep 1

  # new commit in cloned library
  git -C "${DECOMPOSER_TARGET_DIR}/Alpha-1.0" commit \
    --allow-empty --message 'extra commit'

  run_decomposer generate-changelog  -f "${TEST_WORKING_DIR}/test.file" -t '2 seconds ago'
  [ "${status}" -eq 0 ]

  assert_changelog_file "${TEST_WORKING_DIR}/test.file" changelog_lib_add
}

@test "${SUITE_NAME}: writes lib custom log, relative path" {
  create_decomposer_json alpha_psr4

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  sleep 1

  # new commit in cloned library
  git -C "${DECOMPOSER_TARGET_DIR}/Alpha-1.0" commit \
    --allow-empty --message 'extra commit'

  mkdir "${TEST_WORKING_DIR}/changelogs"

  run_decomposer generate-changelog --file changelogs/test.file -t '2 seconds ago'
  [ "${status}" -eq 0 ]

  assert_changelog_file "${TEST_WORKING_DIR}/changelogs/test.file" changelog_lib_add
}

@test "${SUITE_NAME}: writes lib log, add and remove" {
  create_decomposer_json alpha_psr4

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  sleep 1

  # create new orphan commit in cloned library
  git -C "${DECOMPOSER_TARGET_DIR}/Alpha-1.0" checkout --orphan new_branch
  git -C "${DECOMPOSER_TARGET_DIR}/Alpha-1.0" commit \
    --allow-empty --message 'new commit'

  run_decomposer generate-changelog -t '2 seconds ago'
  [ "${status}" -eq 0 ]

  assert_changelog_file "${TEST_WORKING_DIR}/decomposer.diffnotes.md" changelog_lib_both
}

@test "${SUITE_NAME}: writes project log, add and remove" {
  create_decomposer_json alpha_psr4

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  sleep 1

  # create new orphan commit in the working directory
  git -C "${TEST_WORKING_DIR}" checkout --orphan new_branch
  git -C "${TEST_WORKING_DIR}" commit \
        --allow-empty --message 'new commit'

  run_decomposer generate-changelog -t '2 seconds ago'
  [ "${status}" -eq 0 ]

  assert_changelog_file "${TEST_WORKING_DIR}/decomposer.diffnotes.md" changelog_project_both
}
