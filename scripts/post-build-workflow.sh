#!/bin/bash
# Post-project-building workflow: REA analysis + Heretic decensoring
# This script integrates both rea and heretic tools

set -e

echo "========================================="
echo "Post-Project Building Workflow"
echo "========================================="
echo ""

# Step 1: REA ISO Analysis
echo "Step 1: Running REA analysis on ISO files..."
if [ -d "ref" ]; then
    for iso in ref/*.iso; do
        if [ -f "$iso" ]; then
            echo "Found ISO: $iso"
            echo "Analyzing with REA..."
            bash scripts/analyze-iso.sh "$iso"
            echo "---"
        fi
    done
else
    echo "No 'ref' directory found, skipping REA analysis."
fi

echo ""
echo "Step 2: Heretic decensoring..."
echo "Enter model ID to decensor (or press skip):"
read -r model_id

if [ -n "$model_id" ] && [ "$model_id" != "skip" ]; then
    python3 scripts/use-heretic.py "$model_id"
else
    echo "Skipping Heretic decensoring."
fi

echo ""
echo "========================================="
echo "Workflow complete!"
echo "========================================="
