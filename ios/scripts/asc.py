#!/usr/bin/env python3
"""Minimal client for the App Store Connect API.

Commands
--------
bootstrap   Checks the API key, registers the Bundle ID `it.castellanza.stepteller` with the
            HealthKit and iCloud capabilities if missing and checks that the app record exists.
certs       Revokes the certificates created by automatic signing through the API («Created via API»): on an
            ephemeral runner the private key is lost at the end of the job, so they are useless and Apple allows few.
distribute  After the upload: waits for Apple to process the build in BUILD_NUMBER, sets the encryption
            compliance if needed and adds the build to the internal group «Personale».
store-prova App Store listing (asc_store.py): reads App Store Connect and prints what would change, writes nothing.
store       Same, then applies the changes (idempotent) and reads everything back.
store-invio Attaches the 1.0 build to the App Store version and submits it for review (only after Will's ok).

Security: no secrets in the logs (public IDs, dates and states only). Dependency: `cryptography`.
"""
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BUNDLE = 'it.castellanza.stepteller'
APP_NAME = 'Step Teller'
GROUP = 'Personale'
API = 'https://api.appstoreconnect.apple.com'


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def token() -> str:
    """ES256 JWT valid for 15 minutes."""
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
    key_id = os.environ['ASC_KEY_ID'].strip()
    issuer = os.environ['ASC_ISSUER_ID'].strip()
    key = serialization.load_pem_private_key(os.environ['ASC_PRIVATE_KEY'].strip().encode(), password=None)
    now = int(time.time())
    header = {'alg': 'ES256', 'kid': key_id, 'typ': 'JWT'}
    payload = {'iss': issuer, 'iat': now, 'exp': now + 15 * 60, 'aud': 'appstoreconnect-v1'}
    signing_input = _b64(json.dumps(header).encode()) + '.' + _b64(json.dumps(payload).encode())
    r, s = decode_dss_signature(key.sign(signing_input.encode(), ec.ECDSA(hashes.SHA256())))
    return signing_input + '.' + _b64(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))


class ApiError(RuntimeError):
    def __init__(self, message: str, status: int, detail: str):
        super().__init__(message)
        self.status = status
        self.detail = detail


def call(method: str, path: str, body=None, params=None):
    """`path` is relative to the API host, or a full URL (the `links.next` of a paged response)."""
    url = (path if path.startswith('https://') else API + path) + ('?' + urllib.parse.urlencode(params) if params else '')
    data = json.dumps(body).encode() if body is not None else None
    # transient server errors are retried, except on POST (a retried create could duplicate)
    attempts = 1 if method == 'POST' else 4
    for attempt in range(attempts):
        request = urllib.request.Request(url, data=data, method=method, headers={
            'Authorization': 'Bearer ' + token(), 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                raw = response.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as error:
            detail = error.read().decode(errors='replace')[:500]
            if error.code >= 500 and attempt + 1 < attempts:
                time.sleep(5 * (attempt + 1))
                continue
            shown = path.replace(API, '').split('?')[0]
            raise ApiError(f'App Store Connect {method} {shown}: HTTP {error.code} {detail}', error.code, detail) from None


def summary(text: str):
    print(text)
    path = os.environ.get('GITHUB_STEP_SUMMARY')
    if path:
        with open(path, 'a') as file:
            file.write(text + '\n')


def app_record():
    data = call('GET', '/v1/apps', params={'filter[bundleId]': BUNDLE, 'limit': 1})['data']
    return data[0] if data else None


def bootstrap():
    lines = ['## Preparazione Apple']
    # 1. valid key (any GET will do)
    call('GET', '/v1/apps', params={'limit': 1})
    lines.append('- ✅ Chiave API App Store Connect valida')
    # 2. Bundle ID + HealthKit
    found = [b for b in call('GET', '/v1/bundleIds', params={'filter[identifier]': BUNDLE, 'limit': 20})['data']
             if b['attributes'].get('identifier') == BUNDLE]
    if found:
        bundle = found[0]
        lines.append(f'- ✅ Bundle ID {BUNDLE} già registrato')
    else:
        bundle = call('POST', '/v1/bundleIds', body={'data': {'type': 'bundleIds', 'attributes': {
            'identifier': BUNDLE, 'name': APP_NAME, 'platform': 'IOS'}}})['data']
        lines.append(f'- ✅ Bundle ID {BUNDLE} registrato ora')
    caps = {c['attributes'].get('capabilityType') for c in
            call('GET', f"/v1/bundleIds/{bundle['id']}/bundleIdCapabilities")['data']}
    if 'HEALTH_KIT' in caps:
        lines.append('- ✅ Capability HealthKit già attiva')
    else:
        # HealthKit is not among the capability types of the API: it is enabled from the portal or synced by
        # Xcode (automatic signing) from the entitlement. Here we try and, if the API refuses, report
        # without stopping.
        try:
            call('POST', '/v1/bundleIdCapabilities', body={'data': {
                'type': 'bundleIdCapabilities', 'attributes': {'capabilityType': 'HEALTH_KIT'},
                'relationships': {'bundleId': {'data': {'type': 'bundleIds', 'id': bundle['id']}}}}})
            lines.append('- ✅ Capability HealthKit abilitata ora')
        except RuntimeError:
            lines.append('- ⚠️ HealthKit non attivabile via API: la firma automatica prova ad abilitarla; '
                         'se la build si ferma qui, va spuntata a mano nel portale (App ID → HealthKit).')
    # 3. iCloud (key-value store only, `CloudBackup`): without it the 1.1 cannot be signed
    if 'ICLOUD' in caps:
        lines.append('- ✅ Capability iCloud già attiva')
    else:
        try:
            call('POST', '/v1/bundleIdCapabilities', body={'data': {
                'type': 'bundleIdCapabilities', 'attributes': {'capabilityType': 'ICLOUD', 'settings': [
                    {'key': 'ICLOUD_VERSION', 'options': [{'key': 'XCODE_6'}]}]},
                'relationships': {'bundleId': {'data': {'type': 'bundleIds', 'id': bundle['id']}}}}})
            lines.append('- ✅ Capability iCloud abilitata ora')
        except RuntimeError:
            lines.append('- ⚠️ iCloud non attivabile via API: la firma automatica prova ad abilitarla; '
                         'se la build si ferma qui, va spuntata a mano nel portale (App ID → iCloud).')
    # 4. app record (created only from the website)
    if app_record():
        lines.append(f'- ✅ Record app «{APP_NAME}» presente in App Store Connect')
        summary('\n'.join(lines))
    else:
        lines.append(f'- ❌ **Manca il record dell\'app** in App Store Connect (nome «{APP_NAME}», '
                     f'Bundle ID {BUNDLE}). Si crea solo dal sito: appstoreconnect.apple.com → App → +.')
        summary('\n'.join(lines))
        raise RuntimeError('Record app mancante in App Store Connect')


def certs():
    """Frees the Xcode certificates created via the API (never those created by hand or from a Mac)."""
    revoked, kept = 0, 0
    while True:
        data = call('GET', '/v1/certificates', params={'limit': 200})['data']
        mine = [c for c in data if 'created via api' in str(c['attributes'].get('name', '')).lower()]
        kept = len(data) - len(mine)
        if not mine:
            break
        for c in mine:
            call('DELETE', '/v1/certificates/' + c['id'])
            revoked += 1
        if revoked > 200:
            break
    summary(f'## Certificati\n- Revocati {revoked} certificati creati via API; altri certificati lasciati: {kept}')


def distribute():
    build_number = os.environ['BUILD_NUMBER'].strip()
    app = app_record()
    if not app:
        raise RuntimeError('App non trovata in App Store Connect per ' + BUNDLE)
    deadline = time.time() + 40 * 60
    build = None
    while time.time() < deadline:
        data = call('GET', '/v1/builds', params={'filter[app]': app['id'], 'filter[version]': build_number, 'limit': 1})['data']
        if data:
            build = data[0]
            state = build['attributes'].get('processingState')
            if state == 'VALID':
                break
            if state in ('FAILED', 'INVALID'):
                raise RuntimeError(f'Apple ha rifiutato la build {build_number}: stato {state}')
        time.sleep(30)
    else:
        raise RuntimeError(f'Build {build_number} non elaborata entro 40 minuti: controllare TestFlight')
    attrs = build['attributes']
    if attrs.get('usesNonExemptEncryption') is None:
        call('PATCH', '/v1/builds/' + build['id'], body={'data': {
            'type': 'builds', 'id': build['id'], 'attributes': {'usesNonExemptEncryption': False}}})
    groups = [g for g in call('GET', '/v1/betaGroups', params={'filter[app]': app['id'], 'limit': 50})['data']
              if g['attributes'].get('name') == GROUP]
    if not groups:
        raise RuntimeError('Gruppo TestFlight «' + GROUP + '» non trovato: crearlo (interno) in TestFlight')
    target = groups[0]
    if target['attributes'].get('hasAccessToAllBuilds'):
        note = 'gruppo con accesso automatico a tutte le build'
    else:
        call('POST', f"/v1/betaGroups/{target['id']}/relationships/builds",
             body={'data': [{'type': 'builds', 'id': build['id']}]})
        note = 'build aggiunta al gruppo'
    summary(f"## TestFlight\n- Build **{build_number}** elaborata da Apple (VALID)\n"
            f"- Scadenza TestFlight: {attrs.get('expirationDate', '?')}\n- Gruppo «{GROUP}»: {note}")


if __name__ == '__main__':
    try:
        commands = {'bootstrap': bootstrap, 'certs': certs, 'distribute': distribute}
        if sys.argv[1].startswith('store'):
            import asc_store
            commands.update(asc_store.COMMANDS)
        commands[sys.argv[1]]()
    except Exception as error:  # noqa: BLE001
        print('::error::' + str(error)[:500])
        sys.exit(1)
