import zipfile
import re

apk_path = "/Users/test/Desktop/project rea/driveu-12-39-0.apk"

patterns = [
    rb"api/v[0-9]/[a-zA-Z0-9_\-\/]+",
    rb"v[0-9]/[a-zA-Z0-9_\-\/]+",
    rb"booking/[a-zA-Z0-9_\-\/]+",
    rb"customer/[a-zA-Z0-9_\-\/]+",
    rb"driver/[a-zA-Z0-9_\-\/]+",
    rb"wallet/[a-zA-Z0-9_\-\/]+",
    rb"car/[a-zA-Z0-9_\-\/]+",
    rb"fare/[a-zA-Z0-9_\-\/]+"
]

endpoints = set()

with zipfile.ZipFile(apk_path, "r") as z:
    for name in z.namelist():
        if name.startswith("classes") and name.endswith(".dex"):
            data = z.read(name)
            for pat in patterns:
                matches = re.findall(pat, data)
                for m in matches:
                    try:
                        endpoints.add(m.decode("ascii"))
                    except:
                        pass

print(f"Found {len(endpoints)} endpoint patterns:")
with open("/Users/test/Desktop/project rea/docs/scratch/endpoints.txt", "w") as f:
    for ep in sorted(endpoints):
        f.write(ep + "\n")
        if any(k in ep for k in ["booking", "auth", "login", "otp", "driver", "fare", "estimate", "order", "profile", "user"]):
            print(ep)
