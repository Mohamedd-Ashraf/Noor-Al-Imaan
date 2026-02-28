import urllib.request, json, re

def strip(html):
    html = re.sub(r'<sup[^>]*>.*?</sup>', '', html, flags=re.DOTALL|re.IGNORECASE)
    html = re.sub(r'<br\s*/?>', '\n', html, flags=re.IGNORECASE)
    html = re.sub(r'</p>', '\n\n', html, flags=re.IGNORECASE)
    html = re.sub(r'<[^>]+>', '', html)
    for e, r in [('&nbsp;',' '),('&amp;','&'),('&lt;','<'),('&gt;','>'),('&quot;','"'),('&#39;',"'")]:
        html = html.replace(e, r)
    html = re.sub(r'\n{3,}', '\n\n', html)
    return html.strip()

for ayah in ['1:1', '2:255', '114:1']:
    req = urllib.request.Request(
        f'https://api.quran.com/api/v4/tafsirs/14/by_ayah/{ayah}',
        headers={'Accept': 'application/json', 'User-Agent': 'Mozilla/5.0'}
    )
    with urllib.request.urlopen(req, timeout=15) as r:
        d = json.load(r)
    raw = d.get('tafsir', {}).get('text', '')
    clean = strip(raw)
    print(f'--- {ayah} ---')
    print(clean[:400])
    print()
