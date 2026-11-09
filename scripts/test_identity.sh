#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
sources=(GestaltX/GestaltDocument.swift GestaltX/Capabilities.swift GestaltX/DeviceCacheOptions.swift GestaltX/MobileGestaltCacheLayout.swift)
swiftc "${sources[@]}" GestaltX/IdentitySpoof.swift GestaltX/IdentitySpoofProfiles.swift tests/IdentitySpoofTests.swift -o build/tests/identity
build/tests/identity
swiftc "${sources[@]}" tests/DocumentTests.swift -o build/tests/documents
build/tests/documents
