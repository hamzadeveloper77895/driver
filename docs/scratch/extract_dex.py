import zipfile
import struct
import re
import os

apk_path = "/Users/test/Desktop/project rea/driveu-12-39-0.apk"

def parse_dex(dex_bytes):
    magic = dex_bytes[:8]
    if not magic.startswith(b"dex\n"):
        return []
    
    string_ids_size, string_ids_off = struct.unpack_from("<II", dex_bytes, 56)
    type_ids_size, type_ids_off = struct.unpack_from("<II", dex_bytes, 64)
    
    # string offsets
    string_offsets = [struct.unpack_from("<I", dex_bytes, string_ids_off + i*4)[0] for i in range(string_ids_size)]
    
    # decode strings
    strings = []
    for off in string_offsets:
        # read uleb128 utf16_size
        p = off
        val = 0
        shift = 0
        while True:
            b = dex_bytes[p]
            p += 1
            val |= (b & 0x7f) << shift
            if not (b & 0x80):
                break
            shift += 7
        # null-terminated modified utf-8
        end = dex_bytes.find(b"\0", p)
        try:
            s = dex_bytes[p:end].decode("utf-8", errors="replace")
        except:
            s = ""
        strings.append(s)
        
    # type_ids
    types = []
    for i in range(type_ids_size):
        str_idx = struct.unpack_from("<I", dex_bytes, type_ids_off + i*4)[0]
        types.append(strings[str_idx])
        
    return types, strings

print("Opening APK...")
with zipfile.ZipFile(apk_path, "r") as z:
    dex_names = [n for n in z.namelist() if n.startswith("classes") and n.endswith(".dex")]
    all_types = set()
    all_app_strings = set()
    
    for name in dex_names:
        print(f"Reading {name}...")
        data = z.read(name)
        types, strings = parse_dex(data)
        for t in types:
            if "humblemobile" in t or "driveu" in t.lower():
                all_types.add(t)
        for s in strings:
            if any(k in s.lower() for k in ["booking_status", "bookingstatus", "trip_status", "bookingstate", "driveu", "humblemobile", "/v1/", "/v2/", "/api/", "pricing"]):
                all_app_strings.add(s)

print(f"Found {len(all_types)} app types/classes")
print(f"Found {len(all_app_strings)} interesting strings")

# Save to output
os.makedirs("/Users/test/Desktop/project rea/docs/scratch", exist_ok=True)
with open("/Users/test/Desktop/project rea/docs/scratch/app_classes.txt", "w") as f:
    for t in sorted(all_types):
        f.write(t + "\n")

with open("/Users/test/Desktop/project rea/docs/scratch/app_strings.txt", "w") as f:
    for s in sorted(all_app_strings):
        if len(s) < 200:
            f.write(s + "\n")

print("Done writing classes and strings.")
