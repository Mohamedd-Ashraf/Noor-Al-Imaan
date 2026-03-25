import math, os

cx, cy = 65.0, 65.0
ring_r = 53.0
bead_r = 5.0
divider_r = 6.5
n_beads = 33

beads = []
for i in range(n_beads):
    angle = -math.pi/2 + i * (2*math.pi/n_beads)
    bx = round(cx + ring_r * math.cos(angle), 1)
    by = round(cy + ring_r * math.sin(angle), 1)
    beads.append((bx, by))

# Build combined path for beads 1-32
normal_paths = []
for i in range(1, n_beads):
    bx, by = beads[i]
    r = bead_r
    normal_paths.append(f'M {bx-r},{by} a {r},{r} 0 1,0 {2*r},0 a {r},{r} 0 1,0 {-2*r},0 z')
normal_path_data = ' '.join(normal_paths)

# Shadow paths (offset by +1.2 Y)
shadow_offset = 1.2
shadow_normal_paths = []
for i in range(1, n_beads):
    bx, by = beads[i]
    r = bead_r
    sy = by + shadow_offset
    shadow_normal_paths.append(f'M {bx-r},{sy} a {r},{r} 0 1,0 {2*r},0 a {r},{r} 0 1,0 {-2*r},0 z')
shadow_normal_path_data = ' '.join(shadow_normal_paths)

# Divider bead (index 0)
dbx, dby = beads[0]
dr = divider_r
divider_path = f'M {dbx-dr},{dby} a {dr},{dr} 0 1,0 {2*dr},0 a {dr},{dr} 0 1,0 {-2*dr},0 z'
shadow_divider_path = f'M {dbx-dr},{dby+shadow_offset} a {dr},{dr} 0 1,0 {2*dr},0 a {dr},{dr} 0 1,0 {-2*dr},0 z'

# Highlight dots
highlight_paths = []
for i in range(1, n_beads):
    bx, by = beads[i]
    hx = bx - 1.3
    hy = by - 1.3
    hr = 1.6
    highlight_paths.append(f'M {hx-hr},{hy} a {hr},{hr} 0 1,0 {2*hr},0 a {hr},{hr} 0 1,0 {-2*hr},0 z')
highlight_path_data = ' '.join(highlight_paths)

dhx = dbx - 1.5
dhy = dby - 1.5
dhr = 2.0
divider_highlight_path = f'M {dhx-dhr},{dhy} a {dhr},{dhr} 0 1,0 {2*dhr},0 a {dhr},{dhr} 0 1,0 {-2*dhr},0 z'

# Cord circle
cord_path = f'M {cx-ring_r},{cy} A {ring_r},{ring_r} 0 1,0 {cx+ring_r},{cy} A {ring_r},{ring_r} 0 1,0 {cx-ring_r},{cy} Z'

themes = [
    ('balanced', '#C9A227', '#40C9A227', '#28000000', '#50FFFFFF'),
    ('dark',     '#7AD5B0', '#407AD5B0', '#30000000', '#45FFFFFF'),
    ('light',    '#0D5E3A', '#400D5E3A', '#22000000', '#50FFFFFF'),
]

out_dir = os.path.join('android', 'app', 'src', 'main', 'res', 'drawable')

for name, bead_color, cord_color, shadow_color, highlight_color in themes:
    xml = f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="130dp"
    android:height="130dp"
    android:viewportWidth="130"
    android:viewportHeight="130">

    <!-- Cord circle -->
    <path
        android:pathData="{cord_path}"
        android:strokeColor="{cord_color}"
        android:strokeWidth="1.5"
        android:fillColor="#00000000" />

    <!-- Bead shadows (offset +1.2 Y) -->
    <path
        android:pathData="{shadow_divider_path}"
        android:fillColor="{shadow_color}" />
    <path
        android:pathData="{shadow_normal_path_data}"
        android:fillColor="{shadow_color}" />

    <!-- Normal beads (1-32) -->
    <path
        android:pathData="{normal_path_data}"
        android:fillColor="{bead_color}" />

    <!-- Divider bead (larger, with ring) -->
    <path
        android:pathData="{divider_path}"
        android:fillColor="{bead_color}"
        android:strokeColor="#40FFFFFF"
        android:strokeWidth="0.8" />

    <!-- Specular highlights -->
    <path
        android:pathData="{highlight_path_data}"
        android:fillColor="{highlight_color}" />
    <path
        android:pathData="{divider_highlight_path}"
        android:fillColor="{highlight_color}" />
</vector>'''

    filepath = os.path.join(out_dir, f'tasbeeh_bead_ring_{name}.xml')
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(xml)
    print(f'Created {filepath}')
