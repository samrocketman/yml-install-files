#!/bin/bash
# Test script to demonstrate the merge functionality

export TMP_DIR="$(git rev-parse --show-toplevel)/tmp/"
mkdir -p "${TMP_DIR}"

echo "Creating a test merge file that overrides yq version..."

cat > "${TMP_DIR}/demo-merge.yml" << 'EOF'
versions:
  yq: 4.50.0-demo-merged
  demo-tool: 1.0.0

utility:
  demo-tool:
    download: https://example.com/demo-tool
    skip_if: "echo 'Demo tool would be skipped'; true"
    dest: /tmp/demo
EOF

echo "Contents of demo-merge.yml:"
cat "${TMP_DIR}/demo-merge.yml"
echo

echo "=== Test 1: Debug YAML to stdout (with merge) ==="
export yq_version="4.46.1"
set -x;
./download-utilities.sh \
  --yq \
  --debug-yaml \
  --override "${TMP_DIR}/demo-merge.yml" \
  download-utilities.yml | head -10
set +x;

echo
echo "=== Test 2: Debug YAML to file (with merge) ==="
set -x;
./download-utilities.sh \
  --yq \
  --debug-yaml "${TMP_DIR}/merged-debug.yml" \
  --override "${TMP_DIR}/demo-merge.yml" \
  download-utilities.yml
set +x;

echo
echo "Verifying merged file contents:"
if [ -f "${TMP_DIR}/merged-debug.yml" ]; then
  echo "✅ File created successfully"
  echo "Checking for merged version:"
  if grep -q "yq: 4.50.0-demo-merged" "${TMP_DIR}/merged-debug.yml"; then
    echo "✅ Version override successful"
  else
    echo "❌ Version override failed"
  fi
  if grep -q "demo-tool:" "${TMP_DIR}/merged-debug.yml"; then
    echo "✅ New utility added successfully"
  else
    echo "❌ New utility not found"
  fi
else
  echo "❌ Debug file not created"
fi

echo
echo "=== Test 3: Attempting download with merged config ==="
set -x;
./download-utilities.sh \
  --yq \
  --override "${TMP_DIR}/demo-merge.yml" \
  download-utilities.yml \
  demo-tool
set +x;

echo
echo "=== Cleanup ==="
rm -f "${TMP_DIR}/demo-merge.yml" "${TMP_DIR}/merged-debug.yml"
echo "Demo completed!"
