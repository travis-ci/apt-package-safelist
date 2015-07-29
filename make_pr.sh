#! /usr/bin/env bash

ANSI_RED="\033[31;1m"
ANSI_GREEN="\033[32;1m"
ANSI_RESET="\033[0m"
ANSI_CLEAR="\033[0K"

EXIT_SUCCSS=0
EXIT_SOURCE_NOT_FOUND=1
EXIT_SOURCE_HAS_SETUID=2
EXIT_NOTHING_TO_COMMIT=3

DEFAULT_BRANCH=master

function notice() {
	msg=$1
	echo -e "\n${ANSI_GREEN}${msg}${ANSI_RESET}\n"
}

function warn() {
	msg=$1
	echo -e "\n${ANSI_RED}${msg}${ANSI_RESET}\n"
}

function usage() {
	echo "Usage: $0 [-y] repo issue_number [package [additional_packages …]]"
}

while getopts "sy" opt; do
	case "$opt" in
	s)
		has_setuid=1
		;;
	y)
		create_pr=1
		;;
	esac
done

shift $((OPTIND-1))

echo $create_pr

if [ $# -lt 2 ]; then
	usage
	exit 0
fi

## Process arguments; nothing funcy

ISSUE_REPO=$1
shift
ISSUE_NUMBER=$1
shift

PACKAGES=( $@ )
if [ -z "$PACKAGES"  ]; then
	if [ -f $(dirname $0)/packages ]; then
		notice "Reading from $(dirname $0)/packages"
		PACKAGES=$(< $(dirname $0)/packages)
	else
		warn "Unable to determine packages to add"
		usage
		exit 1
	fi
fi

ISSUE_PACKAGE=$(echo $PACKAGES | cut -f1 -d' ')

notice "Setting up PR with\nRepo: ${ISSUE_REPO}\nNUMBER: ${ISSUE_NUMBER}\nPackages: ${PACKAGES[*]}"

BRANCH="test-${ISSUE_REPO}-${ISSUE_NUMBER}"
notice "Setting up Git"

if [ -z "`git config --get --global credential.helper`" ]; then
	notice "set up credential.helper"
	git config credential.helper "store --file=.git/credentials"
	echo "https://${GITHUB_OAUTH_TOKEN}:@github.com" > .git/credentials 2>/dev/null
fi
if [ -z "`git config --get --global user.email`" ]; then
	notice "set up user.email"
	git config --global user.email "contact@travis-ci.com"
fi
if [ -z "`git config --get --global user.name`" ]; then
	notice "set up user.name"
	git config --global user.name "Travis CI APT package tester"
fi

notice "Creating commit"
git checkout $DEFAULT_BRANCH
git checkout -b $BRANCH
for p in ${PACKAGES[*]}; do
	notice "Adding ${p}"
	env PACKAGE=${p} make add > /dev/null
done
git add ubuntu-precise
git commit -m "Add ${ISSUE_PACKAGE} to ubuntu-precise; resolves travis-ci/${ISSUE_REPO}#${ISSUE_NUMBER}

Packages: ${PACKAGES}"

COMMIT_EXIT_STATUS=$?
if [ $COMMIT_EXIT_STATUS -gt 0 ]; then
	notice "Nothing to commit"
	exit $EXIT_NOTHING_TO_COMMIT
fi

notice "Pushing commit"

if [ -z $GITHUB_OAUTH_TOKEN ]; then
	warn '$GITHUB_OAUTH_TOKEN not set'
	exit 1
fi
git push origin $BRANCH
git checkout $DEFAULT_BRANCH
git branch -D $BRANCH

if [ -z $create_pr ]; then
	# bail before creating a pr
	exit 0
fi

notice "Creating PR"
COMMENT="Add packages: ${PACKAGES[*]}"
if [ -n ${TRAVIS_BUILD_ID} ]; then
	COMMENT="${COMMENT}\n\nSee http://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}."
fi
if [ -n ${has_setuid} ]; then
	COMMENT="***NOTE***\n\nThere are setuid/seteuid/setgid bits found. Be sure to check the check build result.\n\n${COMMENT}"
fi
curl -X POST -sS -H "Content-Type: application/json" -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" \
	-d "{\"title\":\"Pull request for ${ISSUE_PACKAGE}\",\"body\":\"Resolves travis-ci/${ISSUE_REPO}#${ISSUE_NUMBER}.\n${COMMENT}\",\"head\":\"${BRANCH}\",\"base\":\"master\"}" \
	https://api.github.com/repos/travis-ci/apt-package-whitelist/pulls
curl -X POST -sS -H "Content-Type: application/json" -H "Authorization: token ${GITHUB_OAUTH_TOKEN}" \
	-d "[\"apt-whitelist-check-run\"]" \
	https://api.github.com/repos/travis-ci/${ISSUE_REPO}/issues/${ISSUE_NUMBER}/labels
