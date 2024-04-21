load helpers/variables
load helpers/hooks
load helpers/main
load helpers/creations
load helpers/assertions

# This suite tests the "install" command

SUITE_NAME=$( test_suite_name )

@test "${SUITE_NAME}: single new PSR-4 library" {
  create_decomposer_json alpha_psr4

  local alpha_lib_revision_hash="$( create_repository alpha-lib )"

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${alpha_lib_revision_hash}"

  assert_lib_autoload_file Alpha-1.0 alpha_psr4

  assert_project_autoload_file Alpha-1.0
}

@test "${SUITE_NAME}: single new PSR-0 library" {
  create_decomposer_json beta_psr0

  local beta_lib_revision_hash="$( create_repository beta-lib )"

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Beta...done" ]

  assert_lib_installed Beta-1.0 "${beta_lib_revision_hash}"

  assert_lib_autoload_file Beta-1.0 beta_psr0

  assert_project_autoload_file Beta-1.0
}

@test "${SUITE_NAME}: multiple new libraries" {
  create_decomposer_json alpha_psr4 beta_psr0

  local alpha_lib_revision_hash="$( create_repository alpha-lib )"
  local beta_lib_revision_hash="$( create_repository beta-lib )"

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]
  [ "${lines[1]}" = "Installing Beta...done" ]

  assert_lib_installed Alpha-1.0 "${alpha_lib_revision_hash}"
  assert_lib_installed Beta-1.0 "${beta_lib_revision_hash}"

  assert_lib_autoload_file Alpha-1.0 alpha_psr4
  assert_lib_autoload_file Beta-1.0 beta_psr0

  assert_project_autoload_file Alpha-1.0 Beta-1.0
}

@test "${SUITE_NAME}: overwrite existing library autoload file" {
  create_decomposer_json alpha_psr4

  create_repository alpha-lib

  # create existing library autoload file with wrong data
  create_lib_autoload_file Alpha-1.0 beta_psr0

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_autoload_file Alpha-1.0 alpha_psr4
}

@test "${SUITE_NAME}: overwrite existing project autoload file" {
  create_decomposer_json alpha_psr4

  create_repository alpha-lib

  # create existing project autoload file with wrong data
  create_project_autoload_file Alpha-1.0 Beta-1.0

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_project_autoload_file Alpha-1.0
}

@test "${SUITE_NAME}: existing library fetches new tag" {
  create_decomposer_json alpha_tag_version

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  # create new commit in repository and tag
  git -C "${TEST_REPOS_DIR}/alpha-lib" commit \
    --allow-empty --message 'extra commit'
  git -C "${TEST_REPOS_DIR}/alpha-lib" tag 1.0

  local tag_alpha_lib_revision_hash=$(
    git -C "${TEST_REPOS_DIR}/alpha-lib" \
      rev-parse HEAD
  )

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${tag_alpha_lib_revision_hash}"
}

@test "${SUITE_NAME}: existing library resets upstream" {
  create_decomposer_json alpha_tag_version

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  # create new commit in repository and tag
  git -C "${TEST_REPOS_DIR}/alpha-lib" remote set-url origin https://moveagency.com

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${tag_alpha_lib_revision_hash}"
}

@test "${SUITE_NAME}: existing library fetches new annotated tag" {
  create_decomposer_json alpha_tag_version

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  # create new commit in repository and tag
  git -C "${TEST_REPOS_DIR}/alpha-lib" commit \
    --allow-empty --message 'extra commit'
  git -C "${TEST_REPOS_DIR}/alpha-lib" tag 1.0 -a -m 'tag'

  local tag_alpha_lib_revision_hash=$(
    git -C "${TEST_REPOS_DIR}/alpha-lib" \
      rev-parse HEAD
  )

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${tag_alpha_lib_revision_hash}"
}

@test "${SUITE_NAME}: existing library fetches new branch" {
  create_decomposer_json alpha_branch_revision

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  # create new branch with new commit in repository
  git -C "${TEST_REPOS_DIR}/alpha-lib" checkout -b rc1
  git -C "${TEST_REPOS_DIR}/alpha-lib" commit \
    --allow-empty --message 'extra commit'

  local branch_alpha_lib_revision_hash=$(
    git -C "${TEST_REPOS_DIR}/alpha-lib" \
      rev-parse HEAD
  )

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${branch_alpha_lib_revision_hash}"
}

@test "${SUITE_NAME}: existing library fetches new commits" {
  create_decomposer_json alpha_psr4

  create_repository alpha-lib

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  # create new commit in repository
  git -C "${TEST_REPOS_DIR}/alpha-lib" commit \
    --allow-empty --message 'extra commit'

  local commit_alpha_lib_revision_hash=$(
    git -C "${TEST_REPOS_DIR}/alpha-lib" \
      rev-parse HEAD
  )

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${commit_alpha_lib_revision_hash}"
}

@test "${SUITE_NAME}: existing library doesn't fetch unrelated changes for commit" {
  local alpha_lib_revision_hash="$( create_repository alpha-lib )"

  # create decomposer.json with current commit
  export TEST_REPOS_COMMIT="${alpha_lib_revision_hash}"
  create_decomposer_json alpha_commit_revision

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  # create new commit on top
  git -C "${TEST_REPOS_DIR}/alpha-lib" commit \
    --allow-empty --message 'extra commit'

  local commit_alpha_lib_revision_hash=$(
    git -C "${TEST_REPOS_DIR}/alpha-lib" \
      rev-parse HEAD
  )

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${alpha_lib_revision_hash}"
  ! assert_lib_contains  Alpha-1.0 "${commit_alpha_lib_revision_hash}"
}

@test "${SUITE_NAME}: existing library doesn't fetch unrelated changes for tag" {
  local alpha_lib_revision_hash="$( create_repository alpha-lib )"

  # create decomposer.json
  create_decomposer_json alpha_tag_revision

  # tag current HEAD
  git -C "${TEST_REPOS_DIR}/alpha-lib" tag alpha-lib-1.0 -a -m 'tag'

  # create usual clone of library
  git clone "${TEST_REPOS_DIR}/alpha-lib" "${DECOMPOSER_TARGET_DIR}/Alpha-1.0"

  # create new commit on top
  git -C "${TEST_REPOS_DIR}/alpha-lib" commit \
    --allow-empty --message 'extra commit'

  local commit_alpha_lib_revision_hash=$(
    git -C "${TEST_REPOS_DIR}/alpha-lib" \
      rev-parse HEAD
  )

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${alpha_lib_revision_hash}"
  ! assert_lib_contains  Alpha-1.0 "${commit_alpha_lib_revision_hash}"
}

@test "${SUITE_NAME}: single new PSR-4 library with multiple paths" {
  create_decomposer_json alpha_psr4_multi

  local alpha_lib_revision_hash="$( create_repository alpha-lib )"

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${alpha_lib_revision_hash}"

  assert_lib_autoload_file Alpha-1.0 alpha_psr4_multi

  assert_project_autoload_file Alpha-1.0
}

@test "${SUITE_NAME}: single new PSR-4 library (not development-only)" {
  create_decomposer_json alpha_nodev

  local alpha_lib_revision_hash="$( create_repository alpha-lib )"

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${alpha_lib_revision_hash}"

  assert_lib_autoload_file Alpha-1.0 alpha_psr4

  assert_project_autoload_file Alpha-1.0
}

@test "${SUITE_NAME}: single new PSR-4 library (development-only)" {
  create_decomposer_json alpha_dev

  local alpha_lib_revision_hash="$( create_repository alpha-lib )"

  run_decomposer install
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "Installing Alpha...done" ]

  assert_lib_installed Alpha-1.0 "${alpha_lib_revision_hash}"

  assert_lib_autoload_file Alpha-1.0 alpha_psr4

  assert_project_autoload_file Alpha-1.0
}
