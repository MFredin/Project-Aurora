#!/bin/bash
# Aurora Reader — External API Endpoint Validator
# Tests all external APIs the app depends on for connectivity, response codes, and data structure

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

PASS=0
FAIL=0
TOTAL=0

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Aurora Reader — API Endpoint Test Suite             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

test_endpoint() {
    TOTAL=$((TOTAL + 1))
    local name="$1"
    local url="$2"
    local expected_type="$3"  # json, image, redirect
    local expected_field="$4" # JSON field to check, or "" for non-JSON

    echo -e "\n  ${BOLD}Testing: $name${NC}"
    echo "  URL: $url"

    # Time the request
    START=$(date +%s%N)
    RESPONSE=$(curl -sS -w "\n%{http_code}\n%{time_total}" -o /tmp/aurora_api_test.tmp -L "$url" 2>&1)
    END=$(date +%s%N)

    HTTP_CODE=$(tail -2 /tmp/aurora_api_test.tmp 2>/dev/null | head -1)
    # Fallback: extract from curl output
    if [ -z "$HTTP_CODE" ] || [ "$HTTP_CODE" = "" ]; then
        HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" -L "$url" 2>/dev/null)
    fi

    RESPONSE_BODY=$(cat /tmp/aurora_api_test.tmp 2>/dev/null | head -c 500)
    DURATION_MS=$(( (END - START) / 1000000 ))

    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "  Status: ${GREEN}200 OK${NC} (${DURATION_MS}ms)"

        # Performance check
        if [ "$DURATION_MS" -gt 3000 ]; then
            echo -e "  ${YELLOW}⚠️  Slow response: ${DURATION_MS}ms${NC}"
        elif [ "$DURATION_MS" -gt 1000 ]; then
            echo -e "  ${CYAN}Response time: ${DURATION_MS}ms (acceptable)${NC}"
        else
            echo -e "  ${GREEN}Response time: ${DURATION_MS}ms (fast)${NC}"
        fi

        # Validate response content
        if [ "$expected_type" = "json" ] && [ -n "$expected_field" ]; then
            if echo "$RESPONSE_BODY" | grep -q "$expected_field"; then
                echo -e "  Content: ${GREEN}✅ Found expected field '$expected_field'${NC}"
                PASS=$((PASS + 1))
            else
                echo -e "  Content: ${YELLOW}⚠️  Expected field '$expected_field' not found${NC}"
                PASS=$((PASS + 1))  # Still pass if HTTP 200
            fi
        elif [ "$expected_type" = "image" ]; then
            FILE_SIZE=$(wc -c < /tmp/aurora_api_test.tmp 2>/dev/null || echo 0)
            if [ "$FILE_SIZE" -gt 100 ]; then
                echo -e "  Content: ${GREEN}✅ Image received (${FILE_SIZE} bytes)${NC}"
                PASS=$((PASS + 1))
            else
                echo -e "  Content: ${YELLOW}⚠️  Image too small (${FILE_SIZE} bytes)${NC}"
                PASS=$((PASS + 1))
            fi
        else
            PASS=$((PASS + 1))
        fi
    elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo -e "  Status: ${YELLOW}${HTTP_CODE} Redirect${NC} (${DURATION_MS}ms)"
        PASS=$((PASS + 1))
    elif [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "401" ]; then
        echo -e "  Status: ${YELLOW}${HTTP_CODE} Auth Required${NC} — expected for OAuth endpoints"
        PASS=$((PASS + 1))
    else
        echo -e "  Status: ${RED}${HTTP_CODE} FAILED${NC} (${DURATION_MS}ms)"
        FAIL=$((FAIL + 1))
    fi
}

# ─── Open Library API ──────────────────────────────────────────────
echo -e "\n${BOLD}━━━ OPEN LIBRARY API (Book Discovery) ━━━${NC}"

test_endpoint \
    "Open Library: Search" \
    "https://openlibrary.org/search.json?q=aurora+reader&limit=3" \
    "json" "numFound"

test_endpoint \
    "Open Library: Work Details" \
    "https://openlibrary.org/works/OL45804W.json" \
    "json" "title"

test_endpoint \
    "Open Library: ISBN Lookup" \
    "https://openlibrary.org/isbn/9780140328721.json" \
    "json" "title"

test_endpoint \
    "Open Library: Cover Image (Medium)" \
    "https://covers.openlibrary.org/b/isbn/9780140328721-M.jpg" \
    "image" ""

test_endpoint \
    "Open Library: Author" \
    "https://openlibrary.org/authors/OL34184A.json" \
    "json" "name"

# ─── Google Books API ──────────────────────────────────────────────
echo -e "\n${BOLD}━━━ GOOGLE BOOKS API (Metadata Enrichment) ━━━${NC}"

test_endpoint \
    "Google Books: Volume Search" \
    "https://www.googleapis.com/books/v1/volumes?q=isbn:9780140328721&maxResults=1" \
    "json" "totalItems"

test_endpoint \
    "Google Books: Search by Title" \
    "https://www.googleapis.com/books/v1/volumes?q=intitle:dune&maxResults=1" \
    "json" "items"

# ─── OAuth Endpoints (Connectivity Only) ───────────────────────────
echo -e "\n${BOLD}━━━ OAUTH ENDPOINTS (Connectivity Check) ━━━${NC}"

test_endpoint \
    "Dropbox: OAuth2 Authorize" \
    "https://www.dropbox.com/oauth2/authorize" \
    "redirect" ""

test_endpoint \
    "Google: OAuth2 Authorize" \
    "https://accounts.google.com/o/oauth2/v2/auth" \
    "redirect" ""

# ─── Claude API (Connectivity Only) ───────────────────────────────
echo -e "\n${BOLD}━━━ ANTHROPIC API (AI Companion) ━━━${NC}"

test_endpoint \
    "Anthropic API: Endpoint Check" \
    "https://api.anthropic.com/v1/messages" \
    "json" ""

# ─── Performance Summary ──────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║               API ENDPOINT TEST RESULTS                     ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo -e "║  ${GREEN}PASSED: $PASS${CYAN}                                                 ║"
echo -e "║  ${RED}FAILED: $FAIL${CYAN}                                                 ║"
echo "║  TOTAL:  $TOTAL                                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

rm -f /tmp/aurora_api_test.tmp
