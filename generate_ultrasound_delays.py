"""
generate_ultrasound_delays.py
=========================================================
Generates 4-Foci Zone-Based Ultrasound Receive Delays for 64 TDM Groups.
Foci Depths: 5.0 mm, 9.0 mm, 19.0 mm, 29.0 mm.

Global Array Reference Calculation:
  R_max,global(g, f) = max_all_elements sqrt((x_e - x_sub,g)^2 + (y_e - y_sub,g)^2 + z_f^2)
  tau_ch(g, f)        = (R_max,global(g, f) - R_ch(g, f)) / c

Quantization: Fixed-point Q8 (8-bit fractional delay, 6-bit integer delay).
Output Files: delay_lut.mem (hex), delay_table.csv (human-readable).
"""

import math, csv, os

# -----------------------------------------------------------------------
# PHYSICAL & ARRAY CONSTANTS
# -----------------------------------------------------------------------
SPEED_OF_SOUND  = 1540.0         # Soft tissue (m/s)
SAMPLING_FREQ   = 20e6           # 20 MHz ADC rate
SAMPLE_PERIOD   = 1.0 / SAMPLING_FREQ # 50 ns
ELEMENT_PITCH   = 125e-6         # 125 um pitch (2.0 mm physical aperture width)
FRAC_BITS       = 8              # 8-bit fractional delay (Q8)

# 4 Specific Focal Depths requested by User
FOCI_MM         = [5.0, 9.0, 19.0, 29.0]
NUM_FOCI        = len(FOCI_MM)   # 4 foci
NUM_GROUPS      = 64             # 64 TDM groups

# Paths
HEX_OUT_SRC     = r"C:\Users\austa\OneDrive\Desktop\HOME_TURF\BFORMER_FINAL\BFORMER_FINAL\BFORMER_FINAL.srcs\sources_1\new\delay_lut.mem"
CSV_OUT_SRC     = r"C:\Users\austa\OneDrive\Desktop\HOME_TURF\BFORMER_FINAL\BFORMER_FINAL\BFORMER_FINAL.srcs\sources_1\new\delay_table.csv"

HEX_OUT_ROOT    = r"C:\Users\austa\OneDrive\Desktop\HOME_TURF\BFORMER_FINAL\BFORMER_FINAL\delay_lut.mem"
CSV_OUT_ROOT    = r"C:\Users\austa\OneDrive\Desktop\HOME_TURF\BFORMER_FINAL\BFORMER_FINAL\delay_table.csv"

# 16x16 Transducer Grid coordinates centered around (0,0)
x_grid = [(i - 7.5) * ELEMENT_PITCH for i in range(16)]
y_grid = [(j - 7.5) * ELEMENT_PITCH for j in range(16)]
all_element_coords = [(x, y) for y in y_grid for x in x_grid]

# Build 64 Groups (2x2 Subarray Grid)
group_subarrays = []
for row in range(8):
    for col in range(8):
        row_sub = row * 2
        col_sub = col * 2
        
        c1 = (x_grid[col_sub],     y_grid[row_sub])
        c2 = (x_grid[col_sub + 1], y_grid[row_sub])
        c3 = (x_grid[col_sub],     y_grid[row_sub + 1])
        c4 = (x_grid[col_sub + 1], y_grid[row_sub + 1])
        
        sub_cx = (x_grid[col_sub] + x_grid[col_sub + 1]) / 2.0
        sub_cy = (y_grid[row_sub] + y_grid[row_sub + 1]) / 2.0
        
        group_subarrays.append({
            'center': (sub_cx, sub_cy),
            'channels': [c1, c2, c3, c4]
        })

print(f"[1/3] Calculating 4-Foci Delays for {NUM_GROUPS} groups x {NUM_FOCI} foci...")

table_rows = []
hex_lines  = []

for g in range(NUM_GROUPS):
    sub = group_subarrays[g]
    sub_cx, sub_cy = sub['center']
    ch_coords      = sub['channels']
    
    for f_idx, z_mm in enumerate(FOCI_MM):
        z_m = z_mm * 1e-3
        
        # 1. Propagation distances to the 4 subarray channels
        dists = [math.sqrt((xe - sub_cx)**2 + (ye - sub_cy)**2 + z_m**2) for (xe, ye) in ch_coords]
        
        # 2. Global Max distance across all 256 array elements to focal point (sub_cx, sub_cy, z_m)
        all_dists = [math.sqrt((ex - sub_cx)**2 + (ey - sub_cy)**2 + z_m**2) for (ex, ey) in all_element_coords]
        r_max_global = max(all_dists)
        
        # 3. Global relative delays
        tau_rel = [(r_max_global - d) / SPEED_OF_SOUND for d in dists]
        
        # 4. Convert to discrete sample delays in Q8 format
        d_samples = [t / SAMPLE_PERIOD for t in tau_rel]
        
        ch_int  = []
        ch_frac = []
        for ds in d_samples:
            d_i = int(math.floor(ds))
            d_f = int(round((ds - d_i) * (2**FRAC_BITS)))
            if d_f == 256:
                d_i += 1
                d_f = 0
            ch_int.append(d_i)
            ch_frac.append(d_f)
        
        # Format CSV row
        table_rows.append({
            'group_sel': g,
            'focus_sel': f_idx,
            'z_mm': z_mm,
            'd1_int': ch_int[0],  'd1_frac': ch_frac[0],
            'd2_int': ch_int[1],  'd2_frac': ch_frac[1],
            'd3_int': ch_int[2],  'd3_frac': ch_frac[2],
            'd4_int': ch_int[3],  'd4_frac': ch_frac[3]
        })
        
        # Build 56-bit Hex word: [d4_int(6), d4_frac(8), d3_int(6), d3_frac(8), d2_int(6), d2_frac(8), d1_int(6), d1_frac(8)]
        word_val = (
            ((ch_int[3]  & 0x3F) << 50) | ((ch_frac[3] & 0xFF) << 42) |
            ((ch_int[2]  & 0x3F) << 36) | ((ch_frac[2] & 0xFF) << 28) |
            ((ch_int[1]  & 0x3F) << 22) | ((ch_frac[1] & 0xFF) << 14) |
            ((ch_int[0]  & 0x3F) << 8)  | ((ch_frac[0] & 0xFF) << 0)
        )
        hex_lines.append(f"{word_val:014X}")

# -----------------------------------------------------------------------
# SAVE MEMORY & CSV FILES
# -----------------------------------------------------------------------
print(f"[2/3] Writing {len(hex_lines)} entries to delay_lut.mem & delay_table.csv...")

for mem_path in [HEX_OUT_SRC, HEX_OUT_ROOT]:
    os.makedirs(os.path.dirname(mem_path), exist_ok=True)
    with open(mem_path, 'w') as f:
        for line in hex_lines:
            f.write(line + '\n')
    print("      Saved: " + mem_path)

fieldnames = ['group_sel', 'focus_sel', 'z_mm',
              'd1_int', 'd1_frac', 'd2_int', 'd2_frac',
              'd3_int', 'd3_frac', 'd4_int', 'd4_frac']

for csv_path in [CSV_OUT_SRC, CSV_OUT_ROOT]:
    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    with open(csv_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(table_rows)
    print("      Saved: " + csv_path)

print("[3/3] 4-Foci Ultrasound Delay Table Generation Complete!")
