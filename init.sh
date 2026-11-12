#!/usr/bin/env bash
# init.sh: environment health check. Run at the start of every session.
set -u
fail=0
ok()  { echo "  OK    $1"; }
bad() { echo "  FAIL  $1"; fail=1; }

echo "Checking environment..."

# 1. .NET 10 SDK
if command -v dotnet >/dev/null && dotnet --list-sdks | grep -q '^10\.'; then
  ok ".NET 10 SDK"; else bad ".NET 10 SDK missing"; fi

# 2. Docker running
if docker info >/dev/null 2>&1; then
  ok "Docker running"; else bad "Docker not running (start Docker Desktop)"; fi

# 3. Aspire CLI
if command -v aspire >/dev/null; then
  ok "Aspire CLI"; else bad "Aspire CLI missing"; fi

# 4. eShop submodule present
if [ -f external/eshop/src/eShop.AppHost/eShop.AppHost.csproj ]; then
  ok "eShop submodule"; else bad "eShop missing (run: git submodule update --init)"; fi

# 5. API key in user-secrets (the value is never printed)
if dotnet user-secrets list --project src/OnCallDeveloper.Playground 2>/dev/null | grep -q '^Anthropic:ApiKey'; then
  ok "Anthropic API key in user-secrets"; else bad "Anthropic:ApiKey missing in user-secrets"; fi

# 6. Personal Git identity (replace yourcompany.com with your employer's domain)
email=$(git config user.email || true)
case "$email" in
  "")               bad "Git email not set" ;;
  *@yourcompany.com) bad "Git email is your work address: $email" ;;
  *)                ok "Git email: $email" ;;
esac

# 7. Solution builds
if dotnet build OnCallDeveloper.slnx -nologo -v q >/dev/null 2>&1; then
  ok "Solution builds"; else bad "Build failed (run: dotnet build to see why)"; fi

echo
if [ $fail -eq 0 ]; then echo "Ready to work."; else echo "Fix the FAIL items first."; exit 1; fi