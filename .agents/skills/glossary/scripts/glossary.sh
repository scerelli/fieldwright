#!/usr/bin/env bash
# glossary.sh: keep code and issues speaking the project's ubiquitous language.
#
#   glossary.sh lint                  validate docs/shipwright/GLOSSARY.md
#   glossary.sh terms                 print "<Term><TAB><codes>" per entry
#   glossary.sh scan [<file>|-]       find avoided synonyms in free text
#                                     (an issue body, a drafted criterion)
#   glossary.sh check <base> <head>   find avoided synonyms in the lines a
#                                     diff adds (identifiers, strings, comments)
#
# Exit 0 = clean. Exit 1 = findings, printed on stdout, one per line.
# Exit 2 = usage error or an unresolvable revision.
# Exit 3 = GLOSSARY.md is missing, or malformed (run `glossary.sh lint`).
#
# Matching is word-based and identifier-aware: `sampleId`, `sample_id`,
# `SAMPLE-ID` and "sample id" all normalize to the words "sample id", and a
# phrase also matches its plural. A line containing `glossary:allow` is
# skipped: the escape for a third-party name you cannot rename; say why on
# the same line.
set -uo pipefail
export LC_ALL=C

usage() {
  printf 'usage: glossary.sh {lint | terms | scan [file|-] | check <base> <head>}\n' >&2
  exit 2
}

cmd="${1:-}"; [[ -n "$cmd" ]] || usage; shift
case "$cmd" in lint|terms|scan|check) ;; *) usage ;; esac

git rev-parse --git-dir >/dev/null 2>&1 \
  || { printf 'glossary: not a git repository\n' >&2; exit 2; }
root="$(git rev-parse --show-toplevel)"
glossary="$root/docs/shipwright/GLOSSARY.md"
rel_glossary="docs/shipwright/GLOSSARY.md"

if [[ ! -f "$glossary" ]]; then
  printf 'glossary: %s does not exist; run /model (or /glossary) first\n' "$rel_glossary" >&2
  exit 3
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# ---------- shared awk functions ----------
# norm(): split identifiers into lowercase words, padded with one space on
# each side so " word " matches only whole words.
# phrase_re(): a normalized phrase as a regex that also matches plurals.
AWK_LIB='
function norm(s,   out, i, c, p, n, len) {
  out = ""; len = length(s)
  for (i = 1; i <= len; i++) {
    c = substr(s, i, 1)
    p = (i > 1) ? substr(s, i - 1, 1) : ""
    n = (i < len) ? substr(s, i + 1, 1) : ""
    if (c ~ /[A-Z]/ && (p ~ /[a-z0-9]/ || (p ~ /[A-Z]/ && n ~ /[a-z]/))) out = out " "
    if (c ~ /[A-Za-z0-9]/) out = out c; else out = out " "
  }
  out = tolower(out)
  gsub(/ +/, " ", out); sub(/^ /, "", out); sub(/ $/, "", out)
  return " " out " "
}
function phrase_re(np,   w, k, i, re, stem) {
  k = split(np, w, " "); re = ""
  for (i = 1; i <= k; i++) {
    if (w[i] ~ /[^aeiou]y$/) { stem = substr(w[i], 1, length(w[i]) - 1); re = re " (" w[i] "s?|" stem "ies)" }
    else re = re " " w[i] "(s|es)?"
  }
  return re " "
}
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
'

# ---------- parse GLOSSARY.md ----------
# entries.tsv : line, term, codes (comma list), avoid (comma list), has_def
# problems.txt: structural findings (unknown keys)
awk "$AWK_LIB"'
BEGIN { OFS = "\t" }
function flush() {
  if (term != "") print tline, term, codes, avoid, hasdef > entries
  term = ""; codes = ""; avoid = ""; hasdef = 0
}
retired && /^## / { print FNR ": entry \"" trim(substr($0, 4)) "\" follows ## Retired and is ignored; ## Retired must be the last section" > problems; next }
retired { next }
/^## Retired[ \t]*$/ { flush(); retired = 1; next }
/^## / {
  flush(); term = trim(substr($0, 4)); tline = FNR; next
}
/^# / { next }
term != "" && /^- [A-Za-z-]+:/ {
  key = $0; sub(/^- /, "", key); sub(/:.*/, "", key)
  val = $0; sub(/^- [A-Za-z-]+:/, "", val); val = trim(val)
  if (key == "code") { gsub(/`/, "", val); codes = val }
  else if (key == "avoid") avoid = val
  else if (key == "definition") hasdef = (val != "") ? 1 : 0
  else if (key != "source" && key != "concept" && key != "note")
    print FNR ": " term ": unknown field \"" key "\" (allowed: code, definition, avoid, source, concept, note)" > problems
  next
}
END { flush() }
' entries="$tmp/entries.tsv" problems="$tmp/problems.txt" "$glossary"
touch "$tmp/entries.tsv" "$tmp/problems.txt"

# ---------- lint ----------
lint() {
  awk -F '\t' "$AWK_LIB"'
  { line[NR] = $1; term[NR] = $2; codes[NR] = $3; avoid[NR] = $4; hasdef[NR] = $5; n = NR }
  END {
    for (i = 1; i <= n; i++) {
      if (!hasdef[i]) print line[i] ": " term[i] ": missing \"- definition:\""
      if (codes[i] == "") print line[i] ": " term[i] ": missing \"- code:\" (write \"- code: -\" when the concept has no identifier)"
      t = tolower(term[i])
      if (t in seen_term) print line[i] ": " term[i] ": duplicate term (also at line " seen_term[t] ")"
      else seen_term[t] = line[i]
      k = split(codes[i], c, ",")
      for (j = 1; j <= k; j++) {
        cc = trim(c[j]); if (cc == "" || cc == "-" || cc == "—") continue
        if (cc in seen_code) print line[i] ": " term[i] ": code `" cc "` is already used by " seen_code[cc]
        else seen_code[cc] = term[i]
        own[i] = own[i] norm(cc)
      }
      own[i] = own[i] norm(term[i])
    }
    for (i = 1; i <= n; i++) {
      if (avoid[i] == "") continue
      k = split(avoid[i], a, ",")
      for (j = 1; j <= k; j++) {
        p = trim(a[j]); np = norm(p)
        if (np == "  ") { print line[i] ": " term[i] ": avoid entry \"" p "\" has no letters or digits"; continue }
        re = phrase_re(substr(np, 2, length(np) - 2))
        # Plural-insensitive: "taxonomy" and "Taxonomies" are the same word.
        for (q = 1; q <= na; q++)
          if (av_term[q] != term[i] && (av_np[q] ~ re || np ~ av_re[q]))
            print line[i] ": " term[i] ": avoid \"" p "\" is also avoided by " av_term[q] "; a finding could not say which term to use"
        na++; av_np[na] = np; av_re[na] = re; av_term[na] = term[i]
        for (m = 1; m <= n; m++)
          if (own[m] ~ re) print line[i] ": " term[i] ": avoid \"" p "\" matches the name or code of " term[m] " itself; every use of it would be flagged"
      }
    }
  }' "$tmp/entries.tsv" > "$tmp/lint.txt"
  cat "$tmp/problems.txt" >> "$tmp/lint.txt"
  sort -n "$tmp/lint.txt" | sed "s#^#$rel_glossary:#"
  [[ ! -s "$tmp/lint.txt" ]]
}

# avoid.tsv: regex, phrase, term, codes. Built only from a lint-clean glossary.
build_avoid() {
  awk -F '\t' "$AWK_LIB"'
  BEGIN { OFS = "\t" }
  $4 != "" {
    k = split($4, a, ",")
    for (j = 1; j <= k; j++) {
      p = trim(a[j]); np = norm(p)
      print phrase_re(substr(np, 2, length(np) - 2)), p, $2, $3
    }
  }' "$tmp/entries.tsv" > "$tmp/avoid.tsv"
}

# Reads avoid.tsv, then records of "<location><TAB><text>" from a second file.
SCAN_AWK="$AWK_LIB"'
BEGIN { FS = "\t" }
FILENAME == ARGV[1] { re[++r] = $1; phrase[r] = $2; term[r] = $3; codes[r] = $4; next }
{
  loc = $1; text = substr($0, length($1) + 2)
  if (index(text, "glossary:allow")) next
  t = norm(text)
  for (i = 1; i <= r; i++)
    if (t ~ re[i]) {
      hint = (codes[i] != "" && codes[i] != "-") ? " (code: " codes[i] ")" : ""
      print loc ": \"" phrase[i] "\" -> use \"" term[i] "\"" hint
      hits++
    }
}
END { exit hits ? 1 : 0 }'

require_clean_glossary() {
  if ! lint >/dev/null; then
    printf 'glossary: %s is malformed; run glossary.sh lint\n' "$rel_glossary" >&2
    exit 3
  fi
  build_avoid
}

case "$cmd" in
  lint)
    if lint; then
      printf 'ok: %s terms\n' "$(wc -l < "$tmp/entries.tsv" | tr -d ' ')"
      exit 0
    fi
    exit 1
    ;;

  terms)
    require_clean_glossary
    awk -F '\t' '{ print $2 "\t" $3 }' "$tmp/entries.tsv"
    ;;

  scan)
    require_clean_glossary
    src="${1:--}"
    if [[ "$src" == - ]]; then cat > "$tmp/text.txt"
    elif [[ -f "$src" ]]; then cat "$src" > "$tmp/text.txt"
    else printf 'glossary: no such file: %s\n' "$src" >&2; exit 2
    fi
    awk '{ print "line " NR "\t" $0 }' "$tmp/text.txt" > "$tmp/records.txt"
    awk "$SCAN_AWK" "$tmp/avoid.tsv" "$tmp/records.txt"
    exit $?
    ;;

  check)
    [[ $# -eq 2 ]] || usage
    base="$1"; head="$2"
    for rev in "$base" "$head"; do
      git -C "$root" rev-parse --verify --quiet "$rev^{commit}" >/dev/null \
        || { printf 'glossary: cannot resolve revision: %s\n' "$rev" >&2; exit 2; }
    done
    require_clean_glossary

    # Paths never scanned: the pipeline docs (they discuss the vocabulary,
    # avoided words included), decision records, changelog, lockfiles, plus
    # any glob listed in .glossaryignore (generated code, vendored code).
    patterns=('docs/shipwright/*' 'docs/adr/*' 'CHANGELOG.md' '*.lock' \
              'package-lock.json' 'pnpm-lock.yaml' 'yarn.lock')
    if [[ -f "$root/.glossaryignore" ]]; then
      while IFS= read -r p || [[ -n "$p" ]]; do
        p="${p%%#*}"; p="$(printf '%s' "$p" | sed 's/[[:space:]]*$//')"
        [[ -n "$p" ]] && patterns+=("$p")
      done < "$root/.glossaryignore"
    fi
    : > "$tmp/ignored.txt"
    git -C "$root" diff --name-only --no-renames "$base" "$head" > "$tmp/files.txt"
    while IFS= read -r f; do
      for p in "${patterns[@]}"; do
        # shellcheck disable=SC2254  # the pattern is meant to glob
        case "$f" in $p) printf '%s\n' "$f" >> "$tmp/ignored.txt"; break ;; esac
      done
    done < "$tmp/files.txt"

    git -C "$root" diff --unified=0 --no-color --no-ext-diff --no-renames \
      "$base" "$head" > "$tmp/diff.txt"
    awk '
    FILENAME == ARGV[1] { ign[$0] = 1; next }
    /^diff --git / { hdr = 1; file = ""; next }
    hdr && /^\+\+\+ / {
      f = substr($0, 5)
      if (f == "/dev/null") file = ""; else { sub(/^b\//, "", f); file = f }
      next
    }
    hdr && /^(--- |index |new file|deleted file|old mode|new mode|similarity|Binary)/ { next }
    /^@@ / {
      hdr = 0; s = $0; sub(/^@@ -[0-9,]+ \+/, "", s); sub(/[ ,].*/, "", s); ln = s + 0; next
    }
    !hdr && /^\+/ {
      if (file != "" && !(file in ign)) print file ":" ln "\t" substr($0, 2)
      ln++; next
    }' "$tmp/ignored.txt" "$tmp/diff.txt" > "$tmp/records.txt"
    awk "$SCAN_AWK" "$tmp/avoid.tsv" "$tmp/records.txt"
    exit $?
    ;;
esac
