import re

with open("/Users/test/Desktop/project rea/docs/scratch/detailed_classes.txt") as f:
    content = f.read()

classes = re.findall(r"Class: (Lcom/humblemobile/[^\n;]+;)", content)

activities = [c for c in classes if "Activity" in c]
fragments = [c for c in classes if "Fragment" in c]
viewmodels = [c for c in classes if "ViewModel" in c]
presenters = [c for c in classes if "Presenter" in c]
usecases = [c for c in classes if "UseCase" in c]
repositories = [c for c in classes if "Repository" in c or "Repo" in c]

print(f"Activities: {len(activities)}")
for a in sorted(activities):
    print("  ", a)

print(f"\nFragments: {len(fragments)}")
for fr in sorted(fragments):
    print("  ", fr)

print(f"\nViewModels: {len(viewmodels)}")
for vm in sorted(viewmodels):
    print("  ", vm)

print(f"\nUseCases: {len(usecases)}")
for uc in sorted(usecases):
    print("  ", uc)

with open("/Users/test/Desktop/project rea/docs/scratch/arch_components.txt", "w") as out:
    out.write("### ACTIVITIES\n" + "\n".join(sorted(activities)) + "\n\n")
    out.write("### FRAGMENTS\n" + "\n".join(sorted(fragments)) + "\n\n")
    out.write("### VIEWMODELS\n" + "\n".join(sorted(viewmodels)) + "\n\n")
    out.write("### USECASES\n" + "\n".join(sorted(usecases)) + "\n\n")
