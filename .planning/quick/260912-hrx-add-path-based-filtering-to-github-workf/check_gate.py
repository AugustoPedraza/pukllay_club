import sys, re, yaml

DOCS = ("!**/*.md", "!*.md", "!.planning/**", "!.claude/**", "!docs/**")
f = []

def key(d):  # PyYAML (YAML 1.1) parses a bare `on:` key as boolean True
    return "on" if "on" in d else True

dep = yaml.safe_load(open(".github/workflows/deploy.yml"))
ci = yaml.safe_load(open(".github/workflows/ci.yml"))
j = dep["jobs"]

# 1. quality in deploy.yml must stay unconditional and independent of the gate
q = j["quality"]
if "if" in q: f.append("deploy.yml quality has an `if:` - required check must never be conditional")
if "needs" in q: f.append("deploy.yml quality gained `needs:` - must not depend on the gate")

# 2. ci.yml quality (the job branch protection actually requires on PRs) untouched
cq = ci["jobs"]["quality"]
if "if" in cq: f.append("ci.yml quality has an `if:`")
if "needs" in cq: f.append("ci.yml quality has `needs:`")

# 3. gate job
if "changes" not in j:
    f.append("no `changes` gate job")
else:
    g = j["changes"]
    if g.get("permissions") != {"contents": "read"}: f.append("gate job not scoped to contents:read")
    if "code" not in (g.get("outputs") or {}): f.append("gate job exposes no `code` output")
    elif "!= 'false'" not in g["outputs"]["code"]: f.append("gate output is not fail-open (`!= 'false'`)")
    steps = g.get("steps", [])
    co = [s for s in steps if str(s.get("uses", "")).startswith("actions/checkout@")]
    if not co or (co[0].get("with") or {}).get("fetch-depth") != 0:
        f.append("gate checkout lacks fetch-depth: 0")
    pf = [s for s in steps if str(s.get("uses", "")).startswith("dorny/paths-filter@")]
    if not pf:
        f.append("gate job does not use dorny/paths-filter")
    else:
        s = pf[0]
        if s["uses"] != "dorny/paths-filter@v4": f.append("paths-filter not pinned to @v4: " + s["uses"])
        if s.get("continue-on-error") is not True: f.append("paths-filter step is not continue-on-error (fail-open)")
        w = s.get("with") or {}
        if w.get("predicate-quantifier") != "every":
            f.append("predicate-quantifier is not 'every' - OR'd negations invert the logic")
        pats = tuple((yaml.safe_load(w.get("filters", "")) or {}).get("code", []))
        if pats != DOCS: f.append("filter patterns %r != expected %r" % (pats, DOCS))

# 4. both heavy jobs gated on the gate output, build still gated on quality
for name, extra in (("build-and-push", "quality"), ("deploy", "build-and-push")):
    job = j[name]
    needs = job.get("needs", [])
    needs = [needs] if isinstance(needs, str) else needs
    if "changes" not in needs: f.append("%s does not need `changes`" % name)
    if extra not in needs: f.append("%s lost its `needs: %s`" % (name, extra))
    if "needs.changes.outputs.code == 'true'" not in str(job.get("if", "")):
        f.append("%s is not gated on needs.changes.outputs.code" % name)

# 5. load-bearing invariant: docs paths cannot reach the image (no catch-all COPY)
for line in open("Dockerfile"):
    m = re.match(r"\s*COPY\s+(.*)", line)
    if not m or "--from=" in line: continue
    for src in m.group(1).split()[:-1]:
        if src in (".", "./") or src.startswith(("docs", ".planning", ".claude")) or src.endswith(".md"):
            f.append("Dockerfile COPY pulls a docs path into the image: " + line.strip())

# 6. once the runbook exists it must not drift from the real filter patterns
import os
RB = "docs/runbooks/deploy-path-filtering.md"
if os.path.exists(RB):
    t = open(RB).read()
    for p in DOCS:
        if p not in t: f.append("runbook omits filter pattern " + p)
    for k in ("validate_image", "--skip-push"):
        if k not in t: f.append("runbook does not cover " + k)

print("\n".join("FAIL: " + x for x in f) if f else "OK: path-filter gate wired, quality unconditional")
sys.exit(1 if f else 0)
