import re, sys
p = "Waykin.xcodeproj/project.pbxproj"
s = open(p).read()
TEAM, BID = "3MM49AVX9G", "com.waykin.WaykinApp-a"
# WaykinApp build configs are the ones carrying the app entitlements.
blocks = list(re.finditer(r"buildSettings = \{(.*?)\n(\t+)\};", s, re.S))
patched = 0
out, last = [], 0
for m in blocks:
    body = m.group(1)
    if "CODE_SIGN_ENTITLEMENTS = App/Waykin.entitlements" not in body:
        continue
    indent = m.group(2) + "\t"
    new = body
    new = re.sub(r"\n\s*PRODUCT_BUNDLE_IDENTIFIER = [^;]+;", "", new)
    new = re.sub(r"\n\s*(DEVELOPMENT_TEAM|CODE_SIGN_STYLE) = [^;]+;", "", new)
    add = (f"\n{indent}CODE_SIGN_STYLE = Automatic;"
           f"\n{indent}DEVELOPMENT_TEAM = {TEAM};"
           f"\n{indent}PRODUCT_BUNDLE_IDENTIFIER = \"{BID}\";")
    out.append(s[last:m.start(1)]); out.append(new + add); last = m.end(1)
    patched += 1
out.append(s[last:])
open(p, "w").write("".join(out))
print(f"patched {patched} build configurations")
