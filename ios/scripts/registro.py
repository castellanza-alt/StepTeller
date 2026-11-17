#!/usr/bin/env python3
"""Checks the release register (ios/CHANGELOG.md) against project.yml. Standard library only: it runs in CI on Linux.

The register has one section per version, newest first:

    ## 1.1 — in lavorazione
    ## 1.1 — su TestFlight, build 1.95.1
    ## 1.1 — inviata ad Apple il 3 novembre 2026, build 1.95.1
    ## 1.1 — pubblicata il 5 novembre 2026, build 1.95.1

Versions before 1.0 only carry the date of their TestFlight build (`## 0.6.3 — 19 ottobre 2026`): accepted, but
never as the first section. Rules (see RILASCIO.md):
  - the first section is the version in project.yml (MARKETING_VERSION), format MAJOR.MINOR or MAJOR.MINOR.FIX;
  - versions strictly decrease down the file; every section has at least one «- » line;
  - a pull request that changes the app's code must add a line to the first section, which must be «in lavorazione»
    (a version already on TestFlight, sent to Apple or published is closed: open the next one and raise the number).

Usage:
  python3 scripts/registro.py                  structure only (push, before a TestFlight build)
  python3 scripts/registro.py --pr <base ref>   structure + pull-request rules against that git ref (e.g. origin/main)
  python3 scripts/registro.py --testflight      structure + the first section must be «in lavorazione» or «su TestFlight»
Exit code 1 and a message in Italian when something is wrong. Imported by asc_store.py for the same data.
"""
import os
import re
import subprocess
import sys
from pathlib import Path

IOS = Path(__file__).resolve().parent.parent
ROOT = IOS.parent
CHANGELOG = IOS / 'CHANGELOG.md'
PROJECT = IOS / 'project.yml'

# files whose change is a change of the app (relative to the repository root)
CODE_PATHS = ('ios/App/', 'ios/Shared/', 'ios/LiveActivity/', 'ios/Watch/', 'ios/WatchWidgets/', 'ios/Sources/',
              'ios/project.yml', 'ios/Package.swift')

MONTHS = 'gennaio|febbraio|marzo|aprile|maggio|giugno|luglio|agosto|settembre|ottobre|novembre|dicembre'
DATE = rf'\d{{1,2}} (?:{MONTHS}) \d{{4}}'
BUILD = r'build \d+(?:\.\d+)*'
VERSION_RE = re.compile(r'^\d+\.\d+(?:\.\d+)?$')
HEADING_RE = re.compile(r'^## (\S+) — (.+?)\s*$')
STATES = [
    ('lavorazione', re.compile(r'^in lavorazione$')),
    ('testflight', re.compile(rf'^su TestFlight, {BUILD}$')),
    ('inviata', re.compile(rf'^inviata ad Apple il {DATE}, {BUILD}$')),
    ('pubblicata', re.compile(rf'^pubblicata il {DATE}, {BUILD}$')),
    ('legacy', re.compile(rf'^{DATE}\b.*$')),
]
OPEN_STATES = {'lavorazione', 'testflight'}   # the code may still change / be rebuilt


class Problem(Exception):
    pass


def version_tuple(version: str):
    parts = [int(p) for p in version.split('.')]
    return tuple(parts + [0] * (3 - len(parts)))


def marketing_version(text: str = None) -> str:
    text = text if text is not None else PROJECT.read_text(encoding='utf-8')
    match = re.search(r'^\s*MARKETING_VERSION:\s*"?([^"\s]+)"?\s*$', text, re.M)
    if not match:
        raise Problem('project.yml: MARKETING_VERSION non trovata')
    version = match.group(1)
    if not VERSION_RE.match(version):
        raise Problem(f'project.yml: MARKETING_VERSION «{version}» non è nel formato MAGGIORE.MINORE o '
                      'MAGGIORE.MINORE.CORREZIONE (es. 1.1 o 1.0.1)')
    return version


def parse_sections(text: str):
    """Returns the sections in file order: {'version', 'state', 'heading', 'lines'}."""
    sections = []
    for number, line in enumerate(text.splitlines(), start=1):
        if line.startswith('## '):
            match = HEADING_RE.match(line)
            if not match:
                raise Problem(f'CHANGELOG.md riga {number}: intestazione «{line}» non nel formato '
                              '«## VERSIONE — stato» (trattino lungo —)')
            version, rest = match.groups()
            if not VERSION_RE.match(version):
                raise Problem(f'CHANGELOG.md riga {number}: versione «{version}» non nel formato 1.1 o 1.0.1')
            state = next((name for name, pattern in STATES if pattern.match(rest)), None)
            if state is None:
                raise Problem(f'CHANGELOG.md riga {number}: stato «{rest}» non riconosciuto. Ammessi: «in lavorazione», '
                              '«su TestFlight, build N», «inviata ad Apple il D mese AAAA, build N», '
                              '«pubblicata il D mese AAAA, build N»')
            sections.append({'version': version, 'state': state, 'heading': line, 'lines': []})
        elif sections:
            sections[-1]['lines'].append(line)
    if not sections:
        raise Problem('CHANGELOG.md: nessuna sezione «## VERSIONE — stato»')
    return sections


def check_structure(changelog_text: str = None, project_text: str = None):
    """Structure rules; returns (sections, marketing version)."""
    sections = parse_sections(changelog_text if changelog_text is not None else CHANGELOG.read_text(encoding='utf-8'))
    version = marketing_version(project_text)
    top = sections[0]
    if top['state'] == 'legacy':
        raise Problem(f"CHANGELOG.md: la prima sezione ({top['heading']}) deve avere uno stato: «in lavorazione», "
                      '«su TestFlight, build N», «inviata ad Apple il…» o «pubblicata il…»')
    if top['version'] != version:
        raise Problem(f"La prima sezione di CHANGELOG.md è la {top['version']}, project.yml dice MARKETING_VERSION {version}: "
                      'devono coincidere (si alza il numero quando si apre la versione nel registro)')
    for previous, current in zip(sections, sections[1:]):
        if version_tuple(current['version']) >= version_tuple(previous['version']):
            raise Problem(f"CHANGELOG.md: la {current['version']} viene dopo la {previous['version']}: "
                          'le versioni devono scendere dall\'alto in basso, senza ripetizioni')
    for section in sections:
        if not any(line.startswith('- ') for line in section['lines']):
            raise Problem(f"CHANGELOG.md: la sezione «{section['heading']}» non ha nessuna riga «- »: "
                          'ogni versione elenca cosa cambia')
    return sections, version


def top_section(changelog_text: str = None):
    """The first section of the register (version, state, heading) after the structure check."""
    sections, _ = check_structure(changelog_text)
    return sections[0]


def git(*args) -> str:
    return subprocess.run(['git', *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout


def check_pull_request(base: str):
    sections, version = check_structure()
    changed = [line for line in git('diff', '--name-only', f'{base}...HEAD').splitlines() if line.strip()]
    code = [path for path in changed if path.startswith(CODE_PATHS)]
    if not code:
        return f'Nessuna modifica al codice dell\'app ({len(changed)} file toccati): il registro non deve cambiare'
    top = sections[0]
    if top['state'] != 'lavorazione':
        raise Problem(f"La prima sezione del registro è «{top['heading']}»: quella versione è chiusa o già costruita. "
                      f"Per modificare il codice: aprire in cima a CHANGELOG.md «## <versione successiva> — in lavorazione» "
                      f'(1.0.1 se solo correzioni, 1.1 se funzioni nuove) e alzare MARKETING_VERSION in project.yml. '
                      f'Dopo una build TestFlight superata, rimettere la stessa versione «in lavorazione» per continuare.')
    if 'ios/CHANGELOG.md' not in changed:
        raise Problem(f'La PR modifica il codice dell\'app ({", ".join(code[:5])}{"…" if len(code) > 5 else ""}) '
                      f"ma non CHANGELOG.md: aggiungere una riga «- » nella sezione «{top['heading']}»")
    try:
        base_text = git('show', f'{base}:ios/CHANGELOG.md')
    except subprocess.CalledProcessError:
        base_text = ''
    base_sections = parse_sections(base_text) if base_text.strip() else []
    base_top = base_sections[0] if base_sections else None
    if base_top and base_top['version'] == top['version']:
        if [l for l in base_top['lines'] if l.startswith('- ')] == [l for l in top['lines'] if l.startswith('- ')]:
            raise Problem(f"CHANGELOG.md è cambiato ma la sezione «{top['heading']}» ha le stesse righe di prima: "
                          'la riga della PR va aggiunta lì')
    elif base_top and version_tuple(top['version']) <= version_tuple(base_top['version']):
        raise Problem(f"La nuova versione {top['version']} non è più alta della {base_top['version']} già nel registro")
    return (f"Codice dell'app modificato ({len(code)} file): riga presente nella sezione «{top['heading']}», "
            f'MARKETING_VERSION {version}')


def check_testflight():
    sections, version = check_structure()
    top = sections[0]
    if top['state'] not in OPEN_STATES:
        raise Problem(f"Il registro dice «{top['heading']}»: una versione inviata o pubblicata non si ricostruisce. "
                      'Aprire la versione successiva «in lavorazione» e alzare MARKETING_VERSION')
    return f"Build TestFlight della {version} ammessa (registro: «{top['heading']}»)"


def main(argv):
    try:
        if argv[:1] == ['--pr']:
            if len(argv) < 2:
                raise Problem('--pr richiede il riferimento git del ramo base (es. origin/main)')
            message = check_pull_request(argv[1])
        elif argv[:1] == ['--testflight']:
            message = check_testflight()
        elif not argv:
            sections, version = check_structure()
            message = f"Registro in ordine: {len(sections)} versioni, in cima «{sections[0]['heading']}», project.yml {version}"
        else:
            raise Problem(f'Argomento sconosciuto: {" ".join(argv)}')
    except Problem as problem:
        print(f'::error::{problem}' if 'GITHUB_ACTIONS' in os.environ else f'ERRORE: {problem}')
        return 1
    print(message)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
