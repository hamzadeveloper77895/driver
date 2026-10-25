import zipfile
import re

apk_path = "/Users/test/Desktop/project rea/driveu-12-39-0.apk"

with zipfile.ZipFile(apk_path, "r") as z:
    for name in ["classes4.dex", "classes3.dex", "classes2.dex", "classes.dex", "classes5.dex"]:
        data = z.read(name)
        target = b"Lcom/humblemobile/consumer/type/BookingStatus;"
        idx = data.find(target)
        if idx != -1:
            print(f"Found target in {name} at {idx}")
            chunk = data[max(0, idx - 400): min(len(data), idx + 800)]
            words = re.findall(rb"[A-Z0-9_]{3,}", chunk)
            for w in words:
                print(w.decode('latin1'))
