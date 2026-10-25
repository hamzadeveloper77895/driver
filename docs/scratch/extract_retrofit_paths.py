import zipfile
import re

apk_path = "/Users/test/Desktop/project rea/driveu-12-39-0.apk"

with zipfile.ZipFile(apk_path, "r") as z:
    for name in z.namelist():
        if name.startswith("classes") and name.endswith(".dex"):
            data = z.read(name)
            idx = data.find(b"Lcom/humblemobile/consumer/rest/DriveURestService;")
            if idx != -1:
                print(f"Found DriveURestService in {name} at {idx}")
                # Search for annotations in this dex
                # Find all strings in this dex that look like endpoints
                strings = re.findall(rb"[a-zA-Z0-9_\-\/]{4,}", data)
                interesting = []
                for s in strings:
                    try:
                        s_dec = s.decode('ascii')
                        if any(s_dec.startswith(prefix) for prefix in ["api/", "v1/", "v2/", "v3/", "v4/", "v5/", "v6/", "v7/", "v8/", "consumer/", "driver/", "booking/"]):
                            interesting.append(s_dec)
                    except:
                        pass
                print(f"Found {len(interesting)} path strings in {name}")
                with open(f"/Users/test/Desktop/project rea/docs/scratch/paths_{name}.txt", "w") as f:
                    for s in sorted(set(interesting)):
                        f.write(s + "\n")
