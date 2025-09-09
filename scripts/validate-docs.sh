#!/bin/bash

# Documentation Validation Script
# Checks for required documentation and quality standards

set -e

echo "📚 Validating Documentation..."
echo "============================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VALIDATION_PASSED=true

# Check for main documentation files
echo ""
echo "📁 Checking required documentation files..."

# Check SOLUTION.md
if [ -f "SOLUTION.md" ]; then
    echo -e "${GREEN}✓${NC} Found SOLUTION.md"
    
    # Check minimum size (at least 1KB)
    size=$(stat -c%s "SOLUTION.md" 2>/dev/null || stat -f%z "SOLUTION.md" 2>/dev/null || echo "0")
    if [ "$size" -gt 1000 ]; then
        echo -e "${GREEN}✓${NC} SOLUTION.md has substantial content ($(echo "scale=1; $size/1024" | bc)KB)"
    else
        echo -e "${RED}✗${NC} SOLUTION.md appears to be too small"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${RED}✗${NC} SOLUTION.md not found - This file should document your complete solution"
    VALIDATION_PASSED=false
fi

# Check README.md
if [ -f "README.md" ]; then
    echo -e "${GREEN}✓${NC} Found README.md"
else
    echo -e "${RED}✗${NC} README.md not found"
    VALIDATION_PASSED=false
fi

# Check for component-specific documentation
echo ""
echo "📋 Checking component documentation..."

# Infrastructure documentation
if [ -f "infrastructure/README.md" ] || grep -q "## Infrastructure" SOLUTION.md 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Infrastructure documentation found"
else
    echo -e "${YELLOW}⚠${NC} Consider adding infrastructure/README.md"
fi

# Kubernetes documentation
if [ -f "k8s-manifests/README.md" ] || grep -q "## Kubernetes" SOLUTION.md 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Kubernetes documentation found"
else
    echo -e "${YELLOW}⚠${NC} Consider adding k8s-manifests/README.md"
fi

# Helm documentation
if [ -f "helm-chart/README.md" ] || [ -f "helm-chart/helm-readme.md" ] || grep -q "## Helm" SOLUTION.md 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Helm documentation found"
else
    echo -e "${YELLOW}⚠${NC} Consider adding helm-chart/README.md"
fi

# Check documentation content quality
echo ""
echo "🔍 Checking documentation quality..."

if [ -f "SOLUTION.md" ]; then
    # Check for required sections (English and Spanish)
    required_sections=(
        "Architecture\|Arquitectura"
        "Deployment\|Despliegue\|Deploy"
        "Security\|Seguridad"
        "Monitoring\|Monitoreo\|Observabilidad"
    )
    
    missing_sections=()
    section_names=("Architecture" "Deployment" "Security" "Monitoring")
    i=0
    for section in "${required_sections[@]}"; do
        if grep -qiE "$section" SOLUTION.md; then
            echo -e "${GREEN}✓${NC} Found section: ${section_names[$i]}"
        else
            missing_sections+=("${section_names[$i]}")
            echo -e "${YELLOW}⚠${NC} Missing section: ${section_names[$i]}"
        fi
        ((i++))
    done
    
    # Check for diagrams or architecture descriptions
    if grep -qi "diagram\|arquitect\|design\|diseño" SOLUTION.md; then
        echo -e "${GREEN}✓${NC} Architecture/design documentation found"
    else
        echo -e "${YELLOW}⚠${NC} Consider adding architecture diagrams or design descriptions"
    fi
    
    # Check for deployment instructions
    if grep -qi "deploy\|installation\|setup" SOLUTION.md; then
        echo -e "${GREEN}✓${NC} Deployment instructions found"
    else
        echo -e "${RED}✗${NC} Missing deployment instructions"
        VALIDATION_PASSED=false
    fi
    
    # Check for troubleshooting guide
    if grep -qi "troubleshoot\|debug\|common issues\|faq" SOLUTION.md; then
        echo -e "${GREEN}✓${NC} Troubleshooting guide found"
    else
        echo -e "${YELLOW}⚠${NC} Consider adding troubleshooting guide"
    fi
fi

# Check for code comments and inline documentation
echo ""
echo "💬 Checking inline documentation..."

# Check Terraform files for descriptions
if find infrastructure -name "*.tf" -type f 2>/dev/null | head -1 | grep -q "."; then
    if grep -r "description" infrastructure/*.tf 2>/dev/null | grep -q "description"; then
        echo -e "${GREEN}✓${NC} Terraform variables have descriptions"
    else
        echo -e "${YELLOW}⚠${NC} Consider adding descriptions to Terraform variables"
    fi
fi

# Check for Helm chart documentation
if [ -f "helm-chart/Chart.yaml" ]; then
    if grep -q "description:" helm-chart/Chart.yaml; then
        echo -e "${GREEN}✓${NC} Helm chart has description"
    else
        echo -e "${YELLOW}⚠${NC} Consider adding description to Chart.yaml"
    fi
fi

# Summary
echo ""
echo "📊 Documentation Validation Summary"
echo "==================================="

if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✅ Documentation validation completed successfully!${NC}"
    echo ""
    echo "💡 Additional recommendations:"
    echo "   - Keep documentation up-to-date with code changes"
    echo "   - Add examples and use cases where applicable"
    echo "   - Include performance benchmarks if available"
    echo "   - Document any known limitations or issues"
    exit 0
else
    echo -e "${RED}❌ Documentation validation failed${NC}"
    echo ""
    echo "📝 Required actions:"
    echo "   1. Create SOLUTION.md with comprehensive documentation"
    echo "   2. Include all required sections (Architecture, Deployment, Security, Monitoring)"
    echo "   3. Add deployment and troubleshooting instructions"
    echo "   4. Ensure documentation is clear and complete"
    exit 1
fi
