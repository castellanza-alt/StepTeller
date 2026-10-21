"""App Store listing of NEAT through the App Store Connect API (commands of asc.py).

store-prova  Reads the current listing and prints, per area and per language, what would change. Writes nothing.
store        Applies the same changes, then reads everything back and checks that nothing is left to change.
             Idempotent: a second run finds the listing aligned and only reads.
store-invio  Attaches the 1.0 build (latest VALID, or BUILD_NUMBER) and submits the version for review.
             Refuses if the listing still differs from the repository. Only after Will's explicit ok.

Sources in the repository: store/metadata.json (texts, generated from the sheet by scripts/store_metadata.py),
store/screenshots/<language>/01…06.jpg (scripts/store_screenshots.py), store/note_revisore.txt.
Contact for the reviewer and copyright come only from the environment (GitHub secrets ASC_REVIEW_FIRST_NAME,
ASC_REVIEW_LAST_NAME, ASC_REVIEW_PHONE, ASC_REVIEW_EMAIL, ASC_COPYRIGHT) and are never printed.

Not available in the API (done by hand on the website): App Privacy labels, EU trader status (DSA), agreements.
"""
import hashlib
import json
import os
import time
import urllib.request
from pathlib import Path

import asc

IOS = Path(__file__).resolve().parent.parent
STORE = IOS / 'store'

VERSION = '1.0'
PRIMARY_LOCALE = 'en-US'
# App Store locale → language in metadata.json and screenshot folder (the copies share texts and images)
LOCALES = {
    'en-US': 'en', 'it': 'it', 'es-ES': 'es', 'fr-FR': 'fr', 'de-DE': 'de', 'pt-BR': 'pt-BR',
    'ja': 'ja', 'ko': 'ko', 'zh-Hans': 'zh-Hans', 'zh-Hant': 'zh-Hant',
    'es-MX': 'es', 'fr-CA': 'fr',
}
PRIVACY_URL = 'https://castellanza-alt.github.io/StepTeller/neat/privacy/'
SUPPORT_URL = 'https://castellanza-alt.github.io/StepTeller/neat/supporto/'
CATEGORIES = {'primaryCategory': 'HEALTH_AND_FITNESS', 'secondaryCategory': 'LIFESTYLE'}
CONTENT_RIGHTS = 'DOES_NOT_USE_THIRD_PARTY_CONTENT'
# 1320 × 2868 is the iPhone 6.9" size; the API has no «69» type: the 6.9" slot is APP_IPHONE_67.
DISPLAY_TYPE = 'APP_IPHONE_67'
SCREENSHOTS = 6

# Age rating: every question «none» / «no» (Will chose 4+ on 21 October 2026: with «yes» to health or wellness topics
# Apple shows 9+ on iOS 26 and later). Only the keys the API returns are sent.
AGE_NONE = ['alcoholTobaccoOrDrugUseOrReferences', 'contests', 'gamblingSimulated', 'gunsOrOtherWeapons',
            'horrorOrFearThemes', 'matureOrSuggestiveThemes', 'medicalOrTreatmentInformation',
            'profanityOrCrudeHumor', 'sexualContentGraphicAndNudity', 'sexualContentOrNudity',
            'violenceCartoonOrFantasy', 'violenceRealistic', 'violenceRealisticProlongedGraphicOrSadistic']
AGE_YES: list[str] = []
AGE_NO = ['healthOrWellnessTopics', 'advertising', 'ageAssurance', 'gambling', 'lootBox', 'messagingAndChat',
          'parentalControls', 'socialMedia', 'unrestrictedWebAccess', 'userGeneratedContent']
# follow-ups of a «yes» (socialMediaAgeRestricted) or set by Apple / per country: left as they are
# ratings approved by Will: after saving the questionnaire, [store] stops if Apple computes anything else
AGE_ALLOWED = {'FOUR_PLUS'}
AGE_UNTOUCHED = {'kidsAgeBand', 'ageRatingOverride', 'ageRatingOverrideV2', 'koreaAgeRatingOverride',
                 'developerAgeRatingInfoUrl', 'seventeenPlus', 'socialMediaAgeRestricted',
                 'gracRatingClassificationNumber'}

EDITABLE_VERSION = {'PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW', 'DEVELOPER_REJECTED', 'REJECTED',
                    'METADATA_REJECTED', 'INVALID_BINARY'}
LIVE_INFO = {'READY_FOR_DISTRIBUTION', 'READY_FOR_SALE', 'REPLACED_WITH_NEW_INFO'}
SECRET_FIELDS = {'contactFirstName', 'contactLastName', 'contactPhone', 'contactEmail', 'copyright'}
LIMITS = {'name': 30, 'subtitle': 30, 'promotionalText': 170, 'description': 4000}


class Stop(RuntimeError):
    """A condition that needs Will (name taken, version in review…): stops before writing anything else."""


# ---------------------------------------------------------------------------------------------- API helpers

def get(path, params=None):
    return asc.call('GET', path, params=params)


def get_all(path, params=None):
    """All pages of a list; returns (data, included)."""
    data, included = [], []
    response = get(path, params)
    while True:
        data += response.get('data') or []
        included += response.get('included') or []
        following = (response.get('links') or {}).get('next')
        if not following:
            return data, included
        response = get(following)


def get_optional(path, params=None):
    """A to-one relationship: None when Apple answers 404 or an empty `data`."""
    try:
        return get(path, params).get('data')
    except asc.ApiError as error:
        if error.status == 404:
            return None
        raise


def create(kind, attributes, relationships=None, included=None, api='v1'):
    body = {'data': {'type': kind}}
    if attributes:
        body['data']['attributes'] = attributes
    if relationships:
        body['data']['relationships'] = {name: {'data': value} for name, value in relationships.items()}
    if included:
        body['included'] = included
    return asc.call('POST', f'/{api}/{kind}', body=body)['data']


def update(kind, ident, attributes=None, relationships=None):
    data = {'type': kind, 'id': ident}
    if attributes:
        data['attributes'] = attributes
    if relationships:
        data['relationships'] = {name: {'data': value} for name, value in relationships.items()}
    return asc.call('PATCH', f'/v1/{kind}/{ident}', body={'data': data})['data']


def ref(kind, ident):
    return {'type': kind, 'id': ident}


# ---------------------------------------------------------------------------------------------- report

def clean(value):
    """Texts compared as Apple stores them (line endings, outer spaces)."""
    if isinstance(value, str):
        return value.replace('\r\n', '\n').strip()
    return value


def shown(field, value):
    if field in SECRET_FIELDS:
        return '(impostato)' if value else '—'
    if value is None or value == '':
        return '—'
    text = str(value).replace('\n', ' ⏎ ')
    return text if len(text) <= 60 else text[:57] + '…'


class Report:
    def __init__(self, apply: bool):
        self.apply = apply
        self.changes = []   # (area, item, field, old, new)
        self.notes = []     # (area, text)

    def change(self, area, item, field, old, new):
        self.changes.append((area, item, field, old, new))

    def note(self, area, text):
        self.notes.append((area, text))

    def markdown(self, title):
        verb = 'Cambiato' if self.apply else 'Cambierebbe'
        lines = [f'## {title}', '']
        areas = []
        for area, *_ in self.changes + [(a, None) for a, _ in self.notes]:
            if area not in areas:
                areas.append(area)
        if not self.changes:
            lines.append('- ✅ Nessuna differenza: la scheda corrisponde al repository.')
        for area in areas:
            rows = [c for c in self.changes if c[0] == area]
            notes = [n for a, n in self.notes if a == area]
            lines += ['', f'### {area}']
            lines += [f'- {n}' for n in notes]
            if rows:  # one line per item (language), fields joined
                lines += ['', f'| Voce | {verb} |', '|---|---|']
                items = []
                for _, item, *_ in rows:
                    if item not in items:
                        items.append(item)
                for item in items:
                    cells = [f'**{field}**: {shown(field, old)} → {shown(field, new)}'
                             for _, i, field, old, new in rows if i == item]
                    lines.append(f"| {item} | {'<br>'.join(cells).replace('|', chr(92) + '|')} |")
        return '\n'.join(lines)


# ---------------------------------------------------------------------------------------------- inputs

def load_inputs():
    metadata = json.loads((STORE / 'metadata.json').read_text(encoding='utf-8'))['languages']
    problems = []
    for locale, lang in LOCALES.items():
        texts = metadata.get(lang)
        if not texts:
            problems.append(f'metadata.json: manca la lingua {lang} ({locale})')
            continue
        for field, limit in LIMITS.items():
            if len(texts.get(field, '')) > limit:
                problems.append(f'{lang} {field}: {len(texts[field])} caratteri > {limit}')
        if len(texts.get('keywords', '').encode()) > 100:
            problems.append(f'{lang} keywords: {len(texts["keywords"].encode())} byte > 100')
    shots = {}
    for lang in sorted(set(LOCALES.values())):
        files = sorted((STORE / 'screenshots' / lang).glob('*.jpg'))
        if len(files) != SCREENSHOTS:
            problems.append(f'store/screenshots/{lang}: {len(files)} immagini, attese {SCREENSHOTS}')
        shots[lang] = [(f, hashlib.md5(f.read_bytes()).hexdigest()) for f in files]
    if problems:
        raise Stop('Dati del repository non validi:\n' + '\n'.join('- ' + p for p in problems))
    notes = (STORE / 'note_revisore.txt').read_text(encoding='utf-8').strip()
    secrets = {name: os.environ.get(env, '').strip() for name, env in [
        ('contactFirstName', 'ASC_REVIEW_FIRST_NAME'), ('contactLastName', 'ASC_REVIEW_LAST_NAME'),
        ('contactPhone', 'ASC_REVIEW_PHONE'), ('contactEmail', 'ASC_REVIEW_EMAIL'), ('copyright', 'ASC_COPYRIGHT')]}
    return metadata, shots, notes, secrets


# ---------------------------------------------------------------------------------------------- sync

def sync_localizations(report, area, kind, parent, existing, wanted):
    """Creates or updates one localization per locale; returns locale → id (None if still to create)."""
    current = {item['attributes']['locale']: item for item in existing}
    ids = {}
    for locale, fields in wanted.items():
        item = current.get(locale)
        if item is None:
            for field, value in fields.items():
                report.change(area, locale, field, None, value)
            ids[locale] = create(kind, {'locale': locale, **fields}, {parent[0]: ref(*parent[1:])})['id'] \
                if report.apply else None
            continue
        attrs = item['attributes']
        changed = {f: v for f, v in fields.items() if clean(attrs.get(f)) != clean(v)}
        for field, value in changed.items():
            report.change(area, locale, field, attrs.get(field), value)
        if changed and report.apply:
            update(kind, item['id'], changed)
        ids[locale] = item['id']
    extra = sorted(set(current) - set(wanted))
    if extra:
        report.note(area, f'Lingue presenti su App Store Connect e non nel repository (lasciate): {", ".join(extra)}')
    return ids


def app_info_section(report, app_id, metadata):
    area = 'Informazioni app (nome, sottotitolo, privacy)'
    infos, _ = get_all(f'/v1/apps/{app_id}/appInfos')
    editable = [i for i in infos if (i['attributes'].get('state') or i['attributes'].get('appStoreState')) not in LIVE_INFO]
    if not editable:
        raise Stop('Nessuna «App Information» modificabile su App Store Connect')
    info = editable[0]
    age_rating_section(report, info)   # first: a rating Will did not approve stops before anything else
    existing, _ = get_all(f"/v1/appInfos/{info['id']}/appInfoLocalizations", {'limit': 50})
    wanted = {locale: {'name': metadata[lang]['name'], 'subtitle': metadata[lang]['subtitle'],
                       'privacyPolicyUrl': PRIVACY_URL} for locale, lang in LOCALES.items()}
    try:
        sync_localizations(report, area, 'appInfoLocalizations', ('appInfo', 'appInfos', info['id']), existing, wanted)
    except asc.ApiError as error:
        if error.status == 409 and 'name' in error.detail.lower():
            raise Stop(f'Apple ha rifiutato un nome (probabilmente già usato da un\'altra app): {error.detail[:400]}')
        raise

    area = 'Categorie'
    full = get(f"/v1/appInfos/{info['id']}", {'include': 'primaryCategory,secondaryCategory'})['data']
    relations = full.get('relationships') or {}
    changed = {}
    for name, category in CATEGORIES.items():
        current = ((relations.get(name) or {}).get('data') or {}).get('id')
        if current != category:
            report.change(area, 'App', name, current, category)
            changed[name] = ref('appCategories', category)
    if changed and report.apply:
        update('appInfos', info['id'], relationships=changed)


def age_rating_section(report, info):
    area = 'Classificazione per età (tutte le risposte «no»)'
    rating = info['attributes'].get('appStoreAgeRating')
    report.note(area, f'Classificazione calcolata ora da Apple: {rating or "nessuna (questionario non salvato)"}')
    declaration = get_optional(f"/v1/appInfos/{info['id']}/ageRatingDeclaration")
    if declaration is None:
        report.note(area, '⚠️ Dichiarazione non leggibile via API: compilarla dal sito')
        return info
    attrs = declaration['attributes']
    wanted = {k: 'NONE' for k in AGE_NONE if k in attrs}
    wanted.update({k: False for k in AGE_NO if k in attrs})
    wanted.update({k: True for k in AGE_YES if k in attrs})
    changed = {k: v for k, v in wanted.items() if attrs.get(k) != v}
    for field, value in changed.items():
        report.change(area, 'Questionario', field, attrs.get(field), value)
    unknown = sorted(k for k in attrs if k not in wanted and k not in AGE_UNTOUCHED)
    if unknown:
        report.note(area, f'⚠️ Domande nuove non gestite dallo script (lasciate): {", ".join(unknown)}')
    if changed and report.apply:
        update('ageRatingDeclarations', declaration['id'], changed)
        rating = get(f"/v1/appInfos/{info['id']}")['data']['attributes'].get('appStoreAgeRating')
        report.note(area, f'Classificazione calcolata da Apple dopo il salvataggio: {rating}')
        if rating not in AGE_ALLOWED:
            raise Stop(f'Apple calcola {rating}, non approvata ({", ".join(sorted(AGE_ALLOWED))}): '
                       'solo il questionario è stato salvato; chiedere a Will prima di proseguire')
    elif rating and rating not in AGE_ALLOWED:
        if report.apply:
            raise Stop(f'Apple calcola {rating}, non approvata: chiedere a Will prima di proseguire')
        report.note(area, f'⚠️ {rating} non è tra le classificazioni approvate ({", ".join(sorted(AGE_ALLOWED))})')
    return info


def version_section(report, app_id, metadata, notes, secrets):
    """Returns (version id or None, locale → version localization id)."""
    area = f'Versione {VERSION}'
    versions, _ = get_all(f'/v1/apps/{app_id}/appStoreVersions', {'filter[platform]': 'IOS', 'limit': 50})
    state = lambda v: v['attributes'].get('appVersionState') or v['attributes'].get('appStoreState')
    same = [v for v in versions if v['attributes'].get('versionString') == VERSION]
    editable = [v for v in versions if state(v) in EDITABLE_VERSION]
    if same and state(same[0]) not in EDITABLE_VERSION:
        raise Stop(f'La versione {VERSION} è nello stato {state(same[0])}: non modificabile ora')
    version = same[0] if same else (editable[0] if editable else None)
    if version is None:
        report.change(area, 'App Store', 'versionString', None, VERSION)
        version = create('appStoreVersions', {'platform': 'IOS', 'versionString': VERSION},
                         {'app': ref('apps', app_id)}) if report.apply else None
    elif version['attributes'].get('versionString') != VERSION:
        report.change(area, 'App Store', 'versionString', version['attributes'].get('versionString'), VERSION)
        if report.apply:
            update('appStoreVersions', version['id'], {'versionString': VERSION})
    if version is not None:
        report.note(area, f"Stato: {state(version) or 'nuova'}")
    if secrets['copyright']:
        current = version['attributes'].get('copyright') if version else None
        if current != secrets['copyright']:
            report.change(area, 'App Store', 'copyright', current, secrets['copyright'])
            if report.apply:
                update('appStoreVersions', version['id'], {'copyright': secrets['copyright']})
    else:
        report.note(area, '⚠️ Segreto ASC_COPYRIGHT assente: copyright non impostato')
    version_id = version['id'] if version else None

    area = 'Testi della versione (descrizione, parole chiave, promozionale, supporto)'
    existing = get_all(f'/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations', {'limit': 50})[0] \
        if version_id else []
    wanted = {locale: {'description': metadata[lang]['description'], 'keywords': metadata[lang]['keywords'],
                       'promotionalText': metadata[lang]['promotionalText'], 'supportUrl': SUPPORT_URL}
              for locale, lang in LOCALES.items()}
    if version_id is None:
        for locale, fields in wanted.items():
            for field, value in fields.items():
                report.change(area, locale, field, None, value)
        localization_ids = {locale: None for locale in wanted}
    else:
        localization_ids = sync_localizations(report, area, 'appStoreVersionLocalizations',
                                              ('appStoreVersion', 'appStoreVersions', version_id), existing, wanted)

    area = 'Note per il revisore e contatto'
    wanted = {'notes': notes, 'demoAccountRequired': False}
    missing = [k for k in ('contactFirstName', 'contactLastName', 'contactPhone', 'contactEmail') if not secrets[k]]
    wanted.update({k: secrets[k] for k in ('contactFirstName', 'contactLastName', 'contactPhone', 'contactEmail')
                   if secrets[k]})
    if missing:
        report.note(area, f'⚠️ Segreti del contatto assenti, campi lasciati com\'erano: {", ".join(missing)}')
    detail = get_optional(f'/v1/appStoreVersions/{version_id}/appStoreReviewDetail') if version_id else None
    attrs = detail['attributes'] if detail else {}
    changed = {k: v for k, v in wanted.items() if clean(attrs.get(k)) != clean(v)}
    for field, value in changed.items():
        report.change(area, 'Revisione', field, attrs.get(field), value)
    if changed and report.apply:
        if detail:
            update('appStoreReviewDetails', detail['id'], changed)
        else:
            create('appStoreReviewDetails', wanted, {'appStoreVersion': ref('appStoreVersions', version_id)})
    return version_id, localization_ids


def app_section(report, app):
    area = 'App'
    attrs = app['attributes']
    if attrs.get('contentRightsDeclaration') != CONTENT_RIGHTS:
        report.change(area, 'App', 'contentRightsDeclaration', attrs.get('contentRightsDeclaration'), CONTENT_RIGHTS)
        if report.apply:
            update('apps', app['id'], {'contentRightsDeclaration': CONTENT_RIGHTS})


def primary_locale_section(report, app):
    current = app['attributes'].get('primaryLocale')
    if current != PRIMARY_LOCALE:
        report.change('App', 'App', 'primaryLocale', current, PRIMARY_LOCALE)
        if report.apply:
            update('apps', app['id'], {'primaryLocale': PRIMARY_LOCALE})


def price_section(report, app_id):
    area = 'Prezzo'
    schedule = get_optional(f'/v1/apps/{app_id}/appPriceSchedule')
    prices = []
    if schedule:
        try:
            _, included = get_all(f"/v1/appPriceSchedules/{schedule['id']}/manualPrices",
                                  {'include': 'appPricePoint', 'limit': 200})
        except asc.ApiError as error:  # an app never priced answers 404 here
            if error.status != 404:
                raise
            included = []
        prices = [float(p['attributes'].get('customerPrice') or 0) for p in included if p['type'] == 'appPricePoints']
    if prices and not any(prices):
        report.note(area, '✅ Gratuita')
        return
    report.change(area, 'App', 'prezzo', 'nessuno' if not prices else f'{max(prices)}', 'Gratuita (0, base USA)')
    if not report.apply:
        return
    points, _ = get_all(f'/v1/apps/{app_id}/appPricePoints', {'filter[territory]': 'USA', 'limit': 200})
    free = next((p for p in points if float(p['attributes'].get('customerPrice') or 0) == 0), None)
    if free is None:
        raise Stop('Fascia di prezzo «gratuita» non trovata per USA')
    create('appPriceSchedules', {}, {
        'app': ref('apps', app_id), 'baseTerritory': ref('territories', 'USA'),
        'manualPrices': [ref('appPrices', '${free}')]},
        included=[{'type': 'appPrices', 'id': '${free}', 'attributes': {'startDate': None},
                   'relationships': {'appPricePoint': {'data': ref('appPricePoints', free['id'])}}}])


def availability_section(report, app_id):
    area = 'Disponibilità (tutti i paesi)'
    availability = get_optional(f'/v1/apps/{app_id}/appAvailabilityV2')
    if availability is None:
        territories, _ = get_all('/v1/territories', {'limit': 200})
        report.change(area, 'App', 'paesi', 'nessuno', f'tutti ({len(territories)}), anche i nuovi')
        if report.apply:
            refs = [f'${{{t["id"]}}}' for t in territories]
            create('appAvailabilities', {'availableInNewTerritories': True},
                   {'app': ref('apps', app_id),
                    'territoryAvailabilities': [ref('territoryAvailabilities', r) for r in refs]},
                   included=[{'type': 'territoryAvailabilities', 'id': r, 'attributes': {'available': True},
                              'relationships': {'territory': {'data': ref('territories', t['id'])}}}
                             for r, t in zip(refs, territories)], api='v2')
        return
    items, included = get_all(f"/v2/appAvailabilities/{availability['id']}/territoryAvailabilities",
                              {'include': 'territory', 'limit': 200})
    off = [i for i in items if not i['attributes'].get('available')]
    if not availability['attributes'].get('availableInNewTerritories'):
        report.note(area, '⚠️ «Disponibile nei nuovi paesi» è spento: si accende solo dal sito (Prezzi e disponibilità)')
    if not off:
        report.note(area, f'✅ Disponibile in tutti i {len(items)} paesi')
        return
    territory = lambda i: ((i.get('relationships') or {}).get('territory', {}).get('data') or {}).get('id', i['id'])
    report.change(area, 'App', 'paesi non disponibili', ', '.join(sorted(territory(i) for i in off)), 'disponibili')
    if report.apply:
        failed = []
        for item in off:
            try:
                update('territoryAvailabilities', item['id'], {'available': True})
            except asc.ApiError as error:
                failed.append(f'{territory(item)} ({error.detail[:120]})')
        if failed:
            report.note(area, '⚠️ Apple non ha attivato: ' + '; '.join(failed))


def screenshot_section(report, localization_ids, shots):
    area = f'Screenshot ({DISPLAY_TYPE}, iPhone 6,9")'
    pending = []
    for locale, lang in LOCALES.items():
        files = shots[lang]
        localization_id = localization_ids.get(locale)
        sets = get_all(f'/v1/appStoreVersionLocalizations/{localization_id}/appScreenshotSets', {'limit': 50})[0] \
            if localization_id else []
        target = next((s for s in sets if s['attributes'].get('screenshotDisplayType') == DISPLAY_TYPE), None)
        others = [s['attributes'].get('screenshotDisplayType') for s in sets if s is not target]
        if others:
            report.note(area, f'{locale}: altri formati presenti, lasciati: {", ".join(others)}')
        current = get_all(f"/v1/appScreenshotSets/{target['id']}/appScreenshots", {'limit': 50})[0] if target else []
        sums = [s['attributes'].get('sourceFileChecksum') for s in current]
        complete = all(((s['attributes'].get('assetDeliveryState') or {}).get('state')) == 'COMPLETE' for s in current)
        if sums == [md5 for _, md5 in files] and complete:
            continue
        before = f'{len(current)} immagini' + ('' if complete else ' (non complete)') if current else 'nessuna'
        report.change(area, locale, 'screenshot', before, f'{len(files)} da {lang}/ ({files[0][0].name}…)')
        if not report.apply:
            continue
        if target is None:
            target = create('appScreenshotSets', {'screenshotDisplayType': DISPLAY_TYPE},
                            {'appStoreVersionLocalization': ref('appStoreVersionLocalizations', localization_id)})
        for shot in current:  # a set holds at most 10: the old ones go first
            asc.call('DELETE', '/v1/appScreenshots/' + shot['id'])
        uploaded = [upload_screenshot(target['id'], path, md5, f'{locale}-{path.name}') for path, md5 in files]
        asc.call('PATCH', f"/v1/appScreenshotSets/{target['id']}/relationships/appScreenshots",
                 body={'data': [ref('appScreenshots', i) for i in uploaded]})
        pending += [(locale, i) for i in uploaded]
    if pending:
        wait_screenshots(report, area, pending)


def upload_screenshot(set_id, path, md5, name):
    data = path.read_bytes()
    shot = create('appScreenshots', {'fileName': name, 'fileSize': len(data)},
                  {'appScreenshotSet': ref('appScreenshotSets', set_id)})
    for operation in shot['attributes']['uploadOperations']:
        chunk = data[operation['offset']:operation['offset'] + operation['length']]
        request = urllib.request.Request(operation['url'], data=chunk, method=operation['method'],
                                         headers={h['name']: h['value'] for h in operation.get('requestHeaders') or []})
        with urllib.request.urlopen(request, timeout=120) as response:
            response.read()
    update('appScreenshots', shot['id'], {'uploaded': True, 'sourceFileChecksum': md5})
    return shot['id']


def wait_screenshots(report, area, pending):
    deadline = time.time() + 15 * 60
    failed = []
    while pending and time.time() < deadline:
        still = []
        for locale, ident in pending:
            state = get(f'/v1/appScreenshots/{ident}')['data']['attributes'].get('assetDeliveryState') or {}
            if state.get('state') == 'FAILED':
                failed.append(f"{locale}: {json.dumps(state.get('errors'))[:200]}")
            elif state.get('state') != 'COMPLETE':
                still.append((locale, ident))
        pending = still
        if pending:
            time.sleep(10)
    if pending:
        report.note(area, f'⚠️ {len(pending)} immagini ancora in elaborazione da Apple dopo 15 minuti')
    if failed:
        report.note(area, '❌ Apple ha rifiutato: ' + '; '.join(failed))


def sync(apply: bool, report: Report = None) -> Report:
    metadata, shots, notes, secrets = load_inputs()
    report = report or Report(apply)
    app = asc.app_record()
    if not app:
        raise Stop(f'App non trovata per il Bundle ID {asc.BUNDLE}')
    report.note('App', f"Record trovato per {asc.BUNDLE} (id {app['id']}, lingua principale ora "
                       f"{app['attributes'].get('primaryLocale')})")
    app_info_section(report, app['id'], metadata)   # first: age rating and names can stop before the rest
    app_section(report, app)
    _, localization_ids = version_section(report, app['id'], metadata, notes, secrets)
    primary_locale_section(report, app)             # after the en-US localizations exist
    price_section(report, app['id'])
    availability_section(report, app['id'])
    screenshot_section(report, localization_ids, shots)
    return report


# ---------------------------------------------------------------------------------------------- commands

def store_prova():
    asc.summary(sync(apply=False).markdown('Scheda App Store — prova (nessuna scrittura)'))


def store_applica():
    report = Report(apply=True)
    try:
        sync(apply=True, report=report)
    except Exception:
        asc.summary(report.markdown('Scheda App Store — applicazione interrotta') +
                    '\n\nLe modifiche elencate sopra restano; rilanciare `[store]` riprende da qui (idempotente).')
        raise
    asc.summary(report.markdown('Scheda App Store — applicata'))
    check = sync(apply=False)
    asc.summary(check.markdown('Rilettura da App Store Connect'))
    if check.changes:
        raise RuntimeError(f'Dopo l\'applicazione restano {len(check.changes)} differenze (vedi rilettura)')


def store_invio():
    check = sync(apply=False)
    if check.changes:
        asc.summary(check.markdown('Invio rifiutato: la scheda non corrisponde al repository'))
        raise Stop('Lanciare prima [store] e controllare la rilettura')
    app = asc.app_record()
    versions, _ = get_all(f"/v1/apps/{app['id']}/appStoreVersions",
                          {'filter[platform]': 'IOS', 'filter[versionString]': VERSION, 'limit': 5})
    if not versions:
        raise Stop(f'Versione {VERSION} non trovata')
    version = versions[0]
    lines = ['## Invio in revisione']
    wanted = os.environ.get('BUILD_NUMBER', '').strip()
    params = {'filter[app]': app['id'], 'filter[preReleaseVersion.version]': VERSION,
              'filter[processingState]': 'VALID', 'filter[expired]': 'false', 'sort': '-uploadedDate', 'limit': 1}
    if wanted:
        params['filter[version]'] = wanted
    builds = get('/v1/builds', params)['data']
    if not builds:
        raise Stop(f'Nessuna build {VERSION} valida su App Store Connect' + (f' con numero {wanted}' if wanted else '') +
                   ': serve una build con MARKETING_VERSION 1.0 caricata con [testflight]')
    build = builds[0]
    number = build['attributes'].get('version')
    if build['attributes'].get('usesNonExemptEncryption') is None:
        update('builds', build['id'], {'usesNonExemptEncryption': False})
    attached = get_optional(f"/v1/appStoreVersions/{version['id']}/build")
    if not attached or attached['id'] != build['id']:
        asc.call('PATCH', f"/v1/appStoreVersions/{version['id']}/relationships/build",
                 body={'data': ref('builds', build['id'])})
        lines.append(f'- ✅ Build {VERSION} ({number}) collegata alla versione')
    else:
        lines.append(f'- ✅ Build {VERSION} ({number}) già collegata')
    open_states = 'READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW,UNRESOLVED_ISSUES'
    submissions = get('/v1/reviewSubmissions', {'filter[app]': app['id'], 'filter[platform]': 'IOS',
                                                'filter[state]': open_states, 'limit': 5})['data']
    submitted = [s for s in submissions if s['attributes'].get('state') in ('WAITING_FOR_REVIEW', 'IN_REVIEW')]
    if submitted:
        lines.append(f"- ✅ Già inviata: stato {submitted[0]['attributes']['state']}")
        asc.summary('\n'.join(lines))
        return
    submission = next((s for s in submissions if s['attributes'].get('state') == 'READY_FOR_REVIEW'), None) or \
        create('reviewSubmissions', {'platform': 'IOS'}, {'app': ref('apps', app['id'])})
    items, _ = get_all(f"/v1/reviewSubmissions/{submission['id']}/items", {'include': 'appStoreVersion'})
    linked = {((i.get('relationships') or {}).get('appStoreVersion', {}).get('data') or {}).get('id') for i in items}
    if version['id'] not in linked:
        create('reviewSubmissionItems', {}, {'reviewSubmission': ref('reviewSubmissions', submission['id']),
                                             'appStoreVersion': ref('appStoreVersions', version['id'])})
    update('reviewSubmissions', submission['id'], {'submitted': True})
    lines.append(f'- ✅ Versione {VERSION} inviata in revisione ad Apple')
    asc.summary('\n'.join(lines))


COMMANDS = {'store-prova': store_prova, 'store': store_applica, 'store-invio': store_invio}
