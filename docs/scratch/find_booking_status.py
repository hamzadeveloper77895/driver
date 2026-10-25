import zipfile
import re

apk_path = "/Users/test/Desktop/project rea/driveu-12-39-0.apk"

with zipfile.ZipFile(apk_path, "r") as z:
    for name in z.namelist():
        if name.startswith("classes") and name.endswith(".dex"):
            data = z.read(name)
            # Find occurrences of BookingStatus
            idx = 0
            while True:
                idx = data.find(b"BookingStatus", idx)
                if idx == -1:
                    break
                snippet = data[max(0, idx - 500): min(len(data), idx + 1000)]
                # extract printable ascii strings
                words = re.findall(rb"[A-Za-z0-9_]{3,}", snippet)
                decoded_words = [w.decode('ascii', errors='ignore') for w in words]
                for w in decoded_words:
                    if any(term in w.lower() for term in ["created", "confirm", "assign", "allocat", "start", "progress", "cancel", "complet", "reach", "arrived"]):
                        print(f"Match around {name}: {w}")
                idx += len("BookingStatus")
