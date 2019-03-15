#!/bin/sh 
# 
# Simple script to use curl to test an app node prior to switching over
#
export http_proxy
http_proxy=
export https_proxy
https_proxy=

tmp_file="/tmp/test_url_$$"

function setup_web {
  # if we have set our special internal testing parameter then we set a
  # bunch of defaults
  # 
  if [ "x$TEST_BASE" != x ]; then
    if [ "x$CONNECT" = x ]; then
      CONNECT=localhost
    fi
    if [ "x$LANDSCAPE" = x ]; then
      LANDSCAPE=test
    fi
  fi

  # determine the landscape one of two ways:
  # 1) explicitly set in environment variable "landscape"
  # 2) implicitly set by hostname
  #
  LANDSCAPE=qa

  # ####
  # determine the main BU web server name for this landscape
  #
  BUWEBHOST="testsp.bu.edu"

  # ####
  # by default we contact localhost if we set the landscape implicitly from the hostname.  Otherwise we leave it
  # blank.
  #
  #if $IMPLICIT ; then
  #  CONTACT=localhost
  #fi
}

function cleanup_web {
  for file in "$tmp_file}"* ; do
    if [ -f "$file" ]; then
      rm "$file"
    fi
  done
}

function dump_web {
  cat "${tmp_file}.output"
  return 1
}

function dump_headers {
  cat "${tmp_file}.headers"
  return 1
}

function assert_backend {
  # primary value is X-Upstream with the secondary value being the old X-BU-Backend

  val=$(get_header "x_upstream" )
  echo "x_bu_backend=$val"
  if [ -z "$val" ]; then
    val=$(get_header "x_bu_backend" | awk '{print $1}')
  fi
  echo "first-ten-characters: ${val:0:10}"

  # convert some old backends to new style
  if [ "x$val" = "xniscms" ]; then
    val=wordpress
  elif [ "x$val" = "x(null)" ]; then
    # (null) means that the front-end handled the request
    val=legacy
  elif [ "x$val" = x ]; then
    # make no header explicit none
    val=none
  elif [ "x$val" = "xist-uiscgi-app" ]; then
    val="uiscgi_app"
  elif [ "x$val" = "xist-uiscgi-content" ]; then
    val="uiscgi_content"
  elif [ "x${val:0:10}" = "xhttp://vsc" ]; then
    val="degree-advice"
  elif [ "x$val" = "xbalancer://django" ]; then
    val="django"
  elif [ "x${val:0:14}" = "xhttp://phpbin-" ]; then
    val="phpbin"
  elif [ "x${val:0:5}" = "xdbin-" ]; then
    val="dbin"
  fi
  # now we loop through all the values and see if any match
  for expected in "$@" ; do 
    if [ "x$expected" = "x$val" ]; then
      return 0
    fi
  done

  # if we got here there was no match so error out
  echo "FAIL assert_backend $@ (instead got $val)"
  return 1
}

function assert_redirect_to_weblogin {
  assert_status 302
  assert_header_contains location 'https://weblogin.*\.bu\.edu/web@login3/'
  assert_header_contains set_cookie 'weblogin3='
}

function assert_does_not_contain {
  if grep -q "$1" "${tmp_file}.output" ; then
    return 1
  else
    return 0
  fi
}

function assert_content {
  gcontent=$(get_content)
  if [ "x$1" != "x$gcontent" ]; then
    echo "FAIL assert_content $1 (does not match $gcontent)"
    return 1
  else
    return 0
  fi
}

function assert_contains {
  if grep -q "$1" "${tmp_file}.output" ; then
    return 0
  else
    return 1
  fi
}

function assert_status {
  assert_header retcode "$1"
}

function assert_header_contains {
  val=$(get_header "$1" )
  if echo "$val" | grep -q "$2" ; then
    return 0
  else
    echo "FAIL assert_header_contains $1 $2 (not found in $val)"
    return 1
  fi
}

function assert_header {
  val=$(get_header "$1" )
  if [ "x$val" != "x$2" ]; then
    echo "FAIL assert_header $1 $2 (instead got $val)"
    return 1
  fi
}

function parse_content {
  local line
  local processed
  local in_content=/bin/false

  while read line ; do
    processed=$( echo "$line" | tr -d "\r\n" ) 
    if $in_content ; then
      echo "$line"
    elif [ -z "$processed" ]; then
      in_content=/bin/true
    fi
  done
}

function get_content {
  cat "${tmp_file}.output" | parse_content
}

function get_header {
  val=$(grep "^$1:" "${tmp_file}.headers" | sed 's/^[^:]*://' )
  echo "$val"
}

function parse_headers {
  local line
  local processed

  while read line ; do
    processed=$( echo "$line" | tr -d "\r\n" ) 
    if [ -z "$processed" ]; then
      break
    elif [ "${processed:0:5}" = "HTTP/" ]; then
      protocol=$(echo "$processed" | awk '{print $1}')
      echo "protocol:$protocol"
      retcode=$(echo "$processed" | awk '{print $2}')
      echo "retcode:$retcode"
    else
      key=$(echo "$processed" | sed 's/:.*$//' | tr A-Z- a-z_ )
      val=$(echo "$processed" | sed 's/^.*: //')
      echo "${key}:${val}"
      #if [ "$key" = "$1" ]; then
      #  echo "$val"
      #  return
      #fi
    fi
  done
}

function test_web {
  local scheme="$1"
  shift
  local host="$1"
  shift
  local url="$1"
  shift
  #local retcode="$1"
  #if [ -z "$retcode" ]; then
  #  retcode="200"
  #else
  #  shift
  #fi
  # anything else will be normal curl URLs

  # determine the host to connect to (if not provided)
  local connect="${CONNECT:-$host}"
  echo "connect=$connect" 
  local url="${scheme}://${connect}${url}"
  echo "###url= $url" 
  echo ""
  echo "###cmd= curl -i $@ --insecure --silent --show-error -H 'Host:$host' '$url'"

  if curl -i "$@" --insecure --silent --show-error -o "${tmp_file}.output" -H "Host:$host" "$url" ; then
    cat "${tmp_file}.output" | parse_headers > "${tmp_file}.headers"
  fi
}

function skip_landscapes {
  for skip_landscape in "$@" ; do
    if [ "x$LANDSCAPE" = "x$skip_landscape" ]; then
      skip "skipping because $LANDSCAPE is in $@"
    fi
  done
}

