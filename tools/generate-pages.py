#!/usr/bin/env python3
"""Regenerate the two data-driven pages from the game's C# source.

    tools/generate-pages.py [path/to/AtGreatCost]

Reads AiTraitRegistry.cs and AugmentNames.cs, fills the templates in tools/pages/, and writes
public/ai-traits.html and public/augment-names.html.

The templates hold ALL the prose — edit those, not the generated pages, or the next run overwrites
your words. The generator only ever fills {{PLACEHOLDERS}}.

Both pages assert that nothing parsed out of the source went unrendered, so adding a trait category
or a fusion table in C# fails loudly here instead of silently vanishing from the page.
"""
import html
import pathlib
import re
import sys
from itertools import chain

ROOT = pathlib.Path(__file__).resolve().parent.parent
GAME = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/Users/wolfe/RiderProjects/AtGreatCost")
PAGES = ROOT / "tools" / "pages"
OUT = ROOT / "public"


def split_pascal(s):
    return re.sub(r"(?<!^)(?=[A-Z])", " ", s)


# ---------------------------------------------------------------- AI traits
def build_traits():
    src = (GAME / "Scripts/InputScripts/AI/AiTraitRegistry.cs").read_text()
    parts = re.split(r"\n\s*public record (\w+)\s*\(", src)
    traits = []
    for i in range(1, len(parts), 2):
        name, body = parts[i], parts[i + 1]

        def grab(field):
            m = re.search(rf'public string {field}\s*{{ get; }}\s*=\s*"((?:[^"\\]|\\.)*)"', body)
            return m.group(1).replace('\\"', '"') if m else None

        traits.append({"name": grab("Name") or name,
                       "category": grab("Category"),
                       "description": grab("Description")})

    # Ordered on purpose; a category added in C# but not listed here trips the assert below.
    cats = [
        ("Aggression", "How much risk it will eat to land damage.", "hot"),
        ("Caution", "What it does when the odds turn.", "cool"),
        ("TargetSelection", "Who it decides is worth shooting.", ""),
        ("Psychology", "The ones that make a unit unreliable.", "odd"),
        ("Tactical", "Preferred shape of a fight.", ""),
        ("Movement", "How willing it is to give up its position.", ""),
        ("Special", "Situational and story-driven states.", "odd"),
    ]

    seen, blocks = set(), []
    for cat, blurb, tone in cats:
        rows = [t for t in traits if t["category"] == cat]
        if not rows:
            continue
        seen.update(r["name"] for r in rows)
        items = "\n".join(
            f'      <div class="trait {tone}">\n'
            f'        <dt>{html.escape(split_pascal(t["name"]))} <code>{html.escape(t["name"])}</code></dt>\n'
            f'        <dd>{html.escape(t["description"])}</dd>\n'
            f"      </div>" for t in rows)
        blocks.append(
            f"  <section>\n"
            f'    <h2>{html.escape(split_pascal(cat))} <span class="count">{len(rows)}</span></h2>\n'
            f'    <p class="blurb">{html.escape(blurb)}</p>\n'
            f'    <dl class="grid">\n{items}\n    </dl>\n'
            f"  </section>")

    dropped = [t["name"] for t in traits if t["name"] not in seen]
    assert not dropped, f"traits with an unlisted category, not rendered: {dropped}"

    tpl = (PAGES / "ai-traits.template.html").read_text()
    (OUT / "ai-traits.html").write_text(
        tpl.replace("{{BLOCKS}}", "\n\n".join(blocks)).replace("{{COUNT}}", str(len(traits))))
    return f"ai-traits.html — {len(traits)} traits in {len(blocks)} categories"


# ------------------------------------------------------------ augment names
def build_names():
    src = (GAME / "Scripts/Augments/AugmentNames.cs").read_text()

    def table(name):
        m = re.search(rf"{name}\s*=\s*new\b.*?\{{(.*?)\n    \}};", src, re.S)
        return dict(re.findall(r'\["([^"]+)"\]\s*=\s*"([^"]*)"', m.group(1)))

    def by_const(name):
        m = re.search(rf"{name}\s*=\s*new\(\)\s*\{{(.*?)\n    \}};", src, re.S)
        return dict(re.findall(r'\[(\w+)\]\s*=\s*"([^"]*)"', m.group(1)))

    up, down, status = by_const("StatWordUp"), by_const("StatWordDown"), table("StatusWords")
    stat, prefix = table("StatFusions"), table("PrefixFusions")
    cross = {**stat, **prefix}          # mirrors CrossModFusions: prefix wins on a shared key
    maxw = re.search(r"MaxWords\s*=\s*(\d+)", src).group(1)

    assert stat and prefix and up and down and status, "a naming table failed to parse"

    def kv(t):
        return "\n".join(
            f'<tr><td class="src"><span class="w">{html.escape(k)}</span></td>'
            f'<td class="arw">&rarr;</td><td class="res">{html.escape(v)}</td></tr>'
            for k, v in t.items())

    def rows(t, mark=False):
        out = []
        for k in sorted(t, key=lambda x: (x.count("|"), x)):
            chips = "".join(f'<span class="w">{html.escape(p)}</span>' for p in k.split("|"))
            tag = ('<span class="tag">override</span>'
                   if mark and k in prefix and k in stat and prefix[k] != stat[k] else "")
            out.append(f'<tr><td class="src">{chips}</td><td class="arw">&rarr;</td>'
                       f'<td class="res">{html.escape(t[k])}{tag}</td></tr>')
        return "\n".join(out)

    tpl = (PAGES / "augment-names.template.html").read_text()
    page = (tpl.replace("{{UP}}", kv(up)).replace("{{DOWN}}", kv(down))
               .replace("{{STATUS}}", kv(status))
               .replace("{{STAT}}", rows(stat)).replace("{{CROSS}}", rows(cross, True))
               .replace("{{NSTAT}}", str(len(stat))).replace("{{NCROSS}}", str(len(cross)))
               .replace("{{MAXW}}", maxw))
    assert "{{" not in page, "a placeholder was left unfilled"
    (OUT / "augment-names.html").write_text(page)
    return f"augment-names.html — {len(stat)} within-mod, {len(cross)} cross-stack"


if __name__ == "__main__":
    if not GAME.exists():
        sys.exit(f"game repo not found: {GAME}")
    for line in (build_traits(), build_names()):
        print("  " + line)
    print("\nprose lives in tools/pages/*.template.html — edit there, not in public/")
