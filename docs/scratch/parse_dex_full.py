import zipfile
import struct
import os

def read_uleb128(data, offset):
    result = 0
    shift = 0
    while True:
        b = data[offset]
        offset += 1
        result |= (b & 0x7f) << shift
        if not (b & 0x80):
            break
        shift += 7
    return result, offset

def parse_dex_full(dex_bytes):
    magic = dex_bytes[:8]
    if not magic.startswith(b"dex\n"):
        return {}
    
    string_ids_size, string_ids_off = struct.unpack_from("<II", dex_bytes, 56)
    type_ids_size, type_ids_off = struct.unpack_from("<II", dex_bytes, 64)
    proto_ids_size, proto_ids_off = struct.unpack_from("<II", dex_bytes, 72)
    field_ids_size, field_ids_off = struct.unpack_from("<II", dex_bytes, 80)
    method_ids_size, method_ids_off = struct.unpack_from("<II", dex_bytes, 88)
    class_defs_size, class_defs_off = struct.unpack_from("<II", dex_bytes, 96)
    
    # strings
    string_offsets = [struct.unpack_from("<I", dex_bytes, string_ids_off + i*4)[0] for i in range(string_ids_size)]
    strings = []
    for off in string_offsets:
        p = off
        length, p = read_uleb128(dex_bytes, p)
        end = dex_bytes.find(b"\0", p)
        try:
            s = dex_bytes[p:end].decode("utf-8", errors="replace")
        except:
            s = ""
        strings.append(s)
        
    # types
    types = [strings[struct.unpack_from("<I", dex_bytes, type_ids_off + i*4)[0]] for i in range(type_ids_size)]
    
    # fields
    fields = []
    for i in range(field_ids_size):
        class_idx, type_idx, name_idx = struct.unpack_from("<HHI", dex_bytes, field_ids_off + i*8)
        fields.append((types[class_idx], types[type_idx], strings[name_idx]))
        
    # methods
    methods = []
    for i in range(method_ids_size):
        class_idx, proto_idx, name_idx = struct.unpack_from("<HHI", dex_bytes, method_ids_off + i*8)
        methods.append((types[class_idx], strings[name_idx]))
        
    # class defs
    classes = {}
    for i in range(class_defs_size):
        class_idx, access_flags, superclass_idx, interfaces_off, source_file_idx, annotations_off, class_data_off, static_values_off = struct.unpack_from("<IIIIIIII", dex_bytes, class_defs_off + i*32)
        cname = types[class_idx]
        if "humblemobile" in cname:
            cfields = []
            cmethods = []
            if class_data_off != 0:
                p = class_data_off
                static_fields_size, p = read_uleb128(dex_bytes, p)
                instance_fields_size, p = read_uleb128(dex_bytes, p)
                direct_methods_size, p = read_uleb128(dex_bytes, p)
                virtual_methods_size, p = read_uleb128(dex_bytes, p)
                
                field_idx = 0
                for _ in range(static_fields_size):
                    field_idx_diff, p = read_uleb128(dex_bytes, p)
                    access_flags, p = read_uleb128(dex_bytes, p)
                    field_idx += field_idx_diff
                    cfields.append(fields[field_idx][2])
                field_idx = 0
                for _ in range(instance_fields_size):
                    field_idx_diff, p = read_uleb128(dex_bytes, p)
                    access_flags, p = read_uleb128(dex_bytes, p)
                    field_idx += field_idx_diff
                    cfields.append(fields[field_idx][2])
                    
                method_idx = 0
                for _ in range(direct_methods_size):
                    method_idx_diff, p = read_uleb128(dex_bytes, p)
                    access_flags, p = read_uleb128(dex_bytes, p)
                    code_off, p = read_uleb128(dex_bytes, p)
                    method_idx += method_idx_diff
                    cmethods.append(methods[method_idx][1])
                method_idx = 0
                for _ in range(virtual_methods_size):
                    method_idx_diff, p = read_uleb128(dex_bytes, p)
                    access_flags, p = read_uleb128(dex_bytes, p)
                    code_off, p = read_uleb128(dex_bytes, p)
                    method_idx += method_idx_diff
                    cmethods.append(methods[method_idx][1])
                    
            classes[cname] = {
                "fields": cfields,
                "methods": cmethods
            }
            
    return classes, strings

apk_path = "/Users/test/Desktop/project rea/driveu-12-39-0.apk"
all_classes = {}
all_strings = set()

with zipfile.ZipFile(apk_path, "r") as z:
    for name in z.namelist():
        if name.startswith("classes") and name.endswith(".dex"):
            c, s = parse_dex_full(z.read(name))
            all_classes.update(c)
            all_strings.update(s)

print(f"Total parsed app classes: {len(all_classes)}")

# Let's inspect enums and data models
with open("/Users/test/Desktop/project rea/docs/scratch/detailed_classes.txt", "w") as f:
    for cname, info in sorted(all_classes.items()):
        f.write(f"Class: {cname}\n")
        f.write(f"  Fields: {', '.join(info['fields'])}\n")
        f.write(f"  Methods: {', '.join(info['methods'])}\n\n")

print("Wrote detailed_classes.txt")
