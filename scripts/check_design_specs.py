#!/usr/bin/env python3
"""Enforce the design-spec contract across every catalog spec.

Invoked by scripts/validate-dod.d/85-design-spec-conformance.sh. Also runnable
standalone: python3 scripts/check_design_specs.py [catalog_dir]

Checks each spec in skills/hackify/references/design-spec/catalog/ against
skills/hackify/references/design-spec/spec-contract.md:

  1. frontmatter present with all nine required blocks
  2. all twelve required typography roles
  3. all ten required components
  4. every {token.ref} resolves to a real token
  5. zero raw hex and zero bare pixel values inside components:
  6. every font stack ends in a generic family
  7. WCAG 2.1 AA contrast on every role rendered as text
  8. line count inside the contract's 380-470 band
  9. all eleven prose sections present

Exit 0 when every spec passes, 1 otherwise. Findings print one per line.
"""
import pathlib
import re
import sys
from typing import NamedTuple

DEFAULT_CATALOG = 'skills/hackify/references/design-spec/catalog'

REQUIRED_BLOCKS = ('colors', 'fonts', 'typography', 'spacing', 'rounded',
                   'elevation', 'motion', 'components', 'platform')
REQUIRED_TYPE_ROLES = ('display-xl', 'display-lg', 'heading-lg', 'heading-md',
                       'heading-sm', 'body-lg', 'body-md', 'body-sm', 'caption',
                       'overline', 'button', 'numeric')
REQUIRED_COMPONENTS = ('button-primary', 'button-secondary', 'button-ghost',
                       'input-text', 'card', 'nav-bar', 'table-row', 'badge',
                       'modal', 'toast')
GENERIC_FAMILIES = ('serif', 'sans-serif', 'monospace', 'cursive', 'fantasy')
# Roles rendered as text, so subject to the AA minimum. text-muted is excluded:
# the contract scopes it to disabled and non-essential copy, which WCAG exempts.
TEXT_ROLES = ('text-primary', 'text-secondary', 'accent', 'positive', 'caution',
              'negative')
AA_MIN = 4.5
MIN_LINES, MAX_LINES = 380, 470
PROSE_SECTIONS = 11


class Spec(NamedTuple):
    """One catalog spec, parsed once and shared by every check."""
    name: str
    text: str
    fm: str
    colors: dict
    tokens: set
    accent_is_fill: bool


def _linear(channel: int) -> float:
    c = channel / 255.0
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def luminance(hex_color: str) -> float:
    """WCAG 2.1 relative luminance of a #rrggbb color."""
    h = hex_color.lstrip('#')
    return (0.2126 * _linear(int(h[0:2], 16))
            + 0.7152 * _linear(int(h[2:4], 16))
            + 0.0722 * _linear(int(h[4:6], 16)))


def contrast(fg: str, bg: str) -> float:
    """WCAG 2.1 contrast ratio between two #rrggbb colors."""
    a, b = luminance(fg), luminance(bg)
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


def block_of(fm: str, name: str) -> str:
    """Raw text of one top-level YAML block."""
    m = re.search(rf'^{name}:.*?(?=^\S|\Z)', fm, re.M | re.S)
    return m.group(0) if m else ''


def nested_keys(block: str) -> set:
    """Keys indented exactly two spaces (numeric keys included)."""
    return set(re.findall(r'^  ([\w-]+):', block, re.M))


def inline_map_keys(block: str) -> set:
    """Keys from an inline `{ a: 1, b: 2 }` map."""
    m = re.search(r'\{(.*)\}', block, re.S)
    return set(re.findall(r'([\w-]+)\s*:', m.group(1))) if m else set()


def build_token_index(fm: str) -> set:
    """Every dotted token path a {ref} may legally resolve to."""
    known = set()
    for name in ('colors', 'fonts', 'typography', 'elevation', 'platform'):
        for key in nested_keys(block_of(fm, name)):
            known.add(f'{name}.{key}')
    for name in ('spacing', 'rounded'):
        for key in inline_map_keys(block_of(fm, name)):
            known.add(f'{name}.{key}')
    motion = block_of(fm, 'motion')
    for group in ('duration', 'easing'):
        sub = re.search(rf'^  {group}:.*?(?=^  \S|\Z)', motion, re.M | re.S)
        if not sub:
            continue
        keys = inline_map_keys(sub.group(0)) | set(
            re.findall(r'^    ([\w-]+):', sub.group(0), re.M))
        known.update(f'motion.{group}.{k}' for k in keys)
    return known


def parse_spec(path: pathlib.Path):
    """Return a Spec, or None when the file has no frontmatter."""
    text = path.read_text()
    m = re.match(r'^---\n(.*?)\n---\n', text, re.S)
    if not m:
        return None
    fm = m.group(1)
    colors = dict(re.findall(r'^  ([\w-]+):\s*"(#[0-9a-fA-F]{6})"',
                             block_of(fm, 'colors'), re.M))
    return Spec(path.name, text, fm, colors, build_token_index(fm),
                bool(re.search(r'^accentIsFill:\s*true', fm, re.M)))


def check_structure(spec: Spec) -> list:
    """Required blocks, typography roles and components all present."""
    out = []
    present = set(re.findall(r'^([\w-]+):', spec.fm, re.M))
    out += [f'missing block `{b}`' for b in REQUIRED_BLOCKS if b not in present]
    typo = block_of(spec.fm, 'typography')
    out += [f'missing typography role `{r}`' for r in REQUIRED_TYPE_ROLES
            if not re.search(rf'^  {re.escape(r)}:', typo, re.M)]
    comp = block_of(spec.fm, 'components')
    out += [f'missing component `{c}`' for c in REQUIRED_COMPONENTS
            if not re.search(rf'^  {re.escape(c)}:', comp, re.M)]
    return out


def check_refs_and_literals(spec: Spec) -> list:
    """Every {ref} resolves; components carry no raw hex or bare px."""
    out = [f'unresolved token ref `{{{r}}}`'
           for r in sorted(set(re.findall(r'\{([a-z][\w.-]*)\}', spec.fm)))
           if r not in spec.tokens]
    for line in block_of(spec.fm, 'components').splitlines():
        if re.search(r'#[0-9a-fA-F]{3,8}\b', line):
            out.append(f'raw hex in components -> {line.strip()}')
        value = line.split(':', 1)[1] if ':' in line else ''
        if re.search(r'\d+px', value) and '{' not in value:
            out.append(f'bare px in components -> {line.strip()}')
    return out


def check_fonts(spec: Spec) -> list:
    """Every font stack ends in a generic family."""
    out = []
    for stack in re.findall(r'stack:\s*"(.*?)"', spec.fm):
        if stack.split(',')[-1].strip().lower() not in GENERIC_FAMILIES:
            out.append(f'font stack lacks a generic family -> {stack}')
    return out


def check_contrast(spec: Spec) -> list:
    """WCAG AA on every role rendered as text, plus on-accent."""
    colors = spec.colors
    if 'canvas' not in colors:
        return ['no `canvas` color to measure contrast against']
    out = []
    roles = ('text-primary', 'text-secondary') if spec.accent_is_fill else TEXT_ROLES
    for role in roles:
        if role not in colors:
            continue
        ratio = contrast(colors[role], colors['canvas'])
        if ratio < AA_MIN:
            out.append(f'{role} on canvas is {ratio:.2f}:1 (AA needs {AA_MIN})')
    if 'on-accent' in colors and 'accent' in colors:
        ratio = contrast(colors['on-accent'], colors['accent'])
        if ratio < AA_MIN:
            out.append(f'on-accent on accent is {ratio:.2f}:1 (AA needs {AA_MIN})')
    return out


def check_shape(spec: Spec) -> list:
    """Line-count band and prose-section count."""
    out = []
    lines = len(spec.text.splitlines())
    if not MIN_LINES <= lines <= MAX_LINES:
        out.append(f'{lines} lines, outside the {MIN_LINES}-{MAX_LINES} band')
    sections = len(re.findall(r'^## ', spec.text, re.M))
    if sections != PROSE_SECTIONS:
        out.append(f'{sections} prose sections, expected {PROSE_SECTIONS}')
    return out


CHECKS = (check_structure, check_refs_and_literals, check_fonts,
          check_contrast, check_shape)


def main() -> int:
    catalog = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_CATALOG)
    if not catalog.is_dir():
        print(f'  FAIL catalog directory not found: {catalog}')
        return 1
    specs = sorted(p for p in catalog.glob('*.md') if p.name != 'README.md')
    if not specs:
        print(f'  FAIL no catalog specs found under {catalog}')
        return 1

    failures = 0
    for path in specs:
        spec = parse_spec(path)
        if spec is None:
            print(f'  FAIL {path.name}: no YAML frontmatter')
            failures += 1
            continue
        findings = [f for check in CHECKS for f in check(spec)]
        for finding in findings:
            print(f'  FAIL {spec.name}: {finding}')
        failures += len(findings)

    if failures:
        print(f'  FAIL {failures} problem(s) across {len(specs)} catalog specs')
        return 1
    print(f'  ok   {len(specs)} catalog specs pass all 9 contract checks')
    return 0


if __name__ == '__main__':
    sys.exit(main())
