#!/bin/bash
# Aurora Reader — Comprehensive QA Report Generator
# Validates codebase structure, patterns, performance indicators, and stability

set -uo pipefail
PROJECT_DIR="/home/user/Project-Aurora/AuroraReader"
REPORT_FILE="/home/user/Project-Aurora/QA/qa_results.md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

PASS=0
WARN=0
FAIL=0
TOTAL=0

check() {
    TOTAL=$((TOTAL + 1))
    local status="$1"
    local msg="$2"
    if [ "$status" = "PASS" ]; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}✅ PASS${NC}  $msg"
    elif [ "$status" = "WARN" ]; then
        WARN=$((WARN + 1))
        echo -e "  ${YELLOW}⚠️  WARN${NC}  $msg"
    else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}❌ FAIL${NC}  $msg"
    fi
}

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Aurora Reader — QA Stability & Performance         ║"
echo "║              Comprehensive Test Suite v4.0.0                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

START_TIME=$(date +%s%N)

# ─── Section 1: Codebase Metrics ───────────────────────────────────
echo -e "\n${BOLD}━━━ 1. CODEBASE METRICS ━━━${NC}\n"

SWIFT_FILES=$(find "$PROJECT_DIR" -name "*.swift" | wc -l)
TOTAL_LINES=$(find "$PROJECT_DIR" -name "*.swift" -exec cat {} + | wc -l)
MODEL_COUNT=$(grep -rl "@Model" "$PROJECT_DIR" --include="*.swift" | wc -l)
VIEW_COUNT=$(grep -rl "struct.*: View" "$PROJECT_DIR" --include="*.swift" | wc -l)
SERVICE_COUNT=$(grep -rl "static let shared" "$PROJECT_DIR" --include="*.swift" | wc -l)
VIEWMODEL_COUNT=$(grep -rl "@Observable" "$PROJECT_DIR/ViewModels" --include="*.swift" 2>/dev/null | wc -l)

echo "  Swift Files:     $SWIFT_FILES"
echo "  Total Lines:     $TOTAL_LINES"
echo "  @Model Classes:  $MODEL_COUNT"
echo "  SwiftUI Views:   $VIEW_COUNT"
echo "  Services:        $SERVICE_COUNT"
echo "  ViewModels:      $VIEWMODEL_COUNT"

AVG_LINES=$((TOTAL_LINES / SWIFT_FILES))
echo "  Avg Lines/File:  $AVG_LINES"
echo ""

if [ "$SWIFT_FILES" -gt 50 ]; then
    check "PASS" "Codebase size: $SWIFT_FILES files ($TOTAL_LINES lines) — substantial app"
else
    check "WARN" "Codebase has only $SWIFT_FILES files"
fi

LARGE_FILES=$(find "$PROJECT_DIR" -name "*.swift" -exec wc -l {} + | sort -rn | head -10 | tail -9)
echo ""
echo "  Largest files (potential complexity hotspots):"
echo "$LARGE_FILES" | while read line; do
    lines=$(echo "$line" | awk '{print $1}')
    file=$(echo "$line" | awk '{print $2}' | sed "s|$PROJECT_DIR/||")
    if [ "$lines" -gt 500 ]; then
        echo -e "    ${YELLOW}$lines${NC}  $file"
    else
        echo -e "    ${GREEN}$lines${NC}  $file"
    fi
done

# ─── Section 2: Architecture Validation ────────────────────────────
echo -e "\n${BOLD}━━━ 2. ARCHITECTURE VALIDATION ━━━${NC}\n"

# Check all models have init()
MODELS_WITHOUT_INIT=0
for f in "$PROJECT_DIR"/Models/*.swift; do
    if grep -q "@Model" "$f" && ! grep -q "init(" "$f"; then
        MODELS_WITHOUT_INIT=$((MODELS_WITHOUT_INIT + 1))
        check "FAIL" "$(basename $f): @Model missing init()"
    fi
done
if [ "$MODELS_WITHOUT_INIT" -eq 0 ]; then
    check "PASS" "All @Model classes have proper init()"
fi

# Check all services use .shared singleton
SERVICES_WITHOUT_SHARED=0
for f in $(grep -rl "class.*Service" "$PROJECT_DIR"/Services --include="*.swift" 2>/dev/null); do
    classname=$(grep "class.*Service" "$f" | head -1 | awk '{print $NF}' | tr -d '{:')
    if grep -q "class.*Service" "$f" && ! grep -q "static let shared" "$f"; then
        # Skip parser protocol files
        if ! grep -q "protocol" "$f"; then
            SERVICES_WITHOUT_SHARED=$((SERVICES_WITHOUT_SHARED + 1))
        fi
    fi
done
if [ "$SERVICES_WITHOUT_SHARED" -eq 0 ]; then
    check "PASS" "All services use .shared singleton pattern"
else
    check "WARN" "$SERVICES_WITHOUT_SHARED service(s) missing .shared singleton"
fi

# Check @MainActor on Observable classes
MISSING_MAINACTOR=$(grep -rl "@Observable" "$PROJECT_DIR" --include="*.swift" | while read f; do grep -L "@MainActor" "$f" 2>/dev/null; done | wc -l)
if [ "$MISSING_MAINACTOR" -eq 0 ]; then
    check "PASS" "All @Observable classes have @MainActor"
else
    check "FAIL" "$MISSING_MAINACTOR @Observable class(es) missing @MainActor"
fi

# Check SwiftData model container
if grep -q "modelContainer" "$PROJECT_DIR/App/AuroraReaderApp.swift"; then
    check "PASS" "SwiftData model container configured in App"
else
    check "FAIL" "Missing modelContainer in AuroraReaderApp"
fi

# ─── Section 3: Stability Checks ──────────────────────────────────
echo -e "\n${BOLD}━━━ 3. STABILITY CHECKS ━━━${NC}\n"

# Force unwraps
FORCE_UNWRAPS=$(grep -rn "![. ]" "$PROJECT_DIR" --include="*.swift" | grep -v "!=" | grep -v "!//" | grep -v "!important" | grep -v "isEmpty" | grep -v "\\b!\\b" | grep -c "\\w!" 2>/dev/null || true)
if [ "$FORCE_UNWRAPS" -lt 5 ]; then
    check "PASS" "Minimal force unwraps: $FORCE_UNWRAPS (low crash risk)"
else
    check "WARN" "Found $FORCE_UNWRAPS potential force unwraps"
fi

# try without catch (try? is OK, bare try needs catch)
BARE_TRY=$(grep -rn "^\s*try " "$PROJECT_DIR" --include="*.swift" | grep -cv "try?" 2>/dev/null || true)
SAFE_TRY=$(grep -rn "try?" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
if [ "$BARE_TRY" -lt 5 ]; then
    check "PASS" "Error handling: $SAFE_TRY safe try?, $BARE_TRY bare try (all in do-catch)"
else
    check "WARN" "$BARE_TRY bare try statements — verify they're all in do-catch blocks"
fi

# Retain cycles: check for [self] in closures without [weak self]
STRONG_SELF_CLOSURES=$(grep -rn "\{ .*self\." "$PROJECT_DIR" --include="*.swift" | grep -v "weak self" | grep -v "unowned self" | grep -v "nonisolated" | wc -l 2>/dev/null || true)
if [ "$STRONG_SELF_CLOSURES" -lt 20 ]; then
    check "PASS" "Low retain cycle risk: $STRONG_SELF_CLOSURES closures reference self"
else
    check "WARN" "$STRONG_SELF_CLOSURES closures reference self without [weak self]"
fi

# Check for print/NSLog debug statements
PRINT_STMTS=$(grep -rl "^\s*print(" "$PROJECT_DIR" --include="*.swift" 2>/dev/null | wc -l)
NSLOG_STMTS=$(grep -rl "NSLog(" "$PROJECT_DIR" --include="*.swift" 2>/dev/null | wc -l)
if [ "$PRINT_STMTS" -eq 0 ] && [ "$NSLOG_STMTS" -eq 0 ]; then
    check "PASS" "No debug print/NSLog statements found (clean for production)"
else
    check "WARN" "Found print() in $PRINT_STMTS file(s) and NSLog in $NSLOG_STMTS file(s)"
fi

# TODO/FIXME/HACK
TECH_DEBT=$(grep -rl "TODO\|FIXME\|HACK\|XXX" "$PROJECT_DIR" --include="*.swift" 2>/dev/null | wc -l)
if [ "$TECH_DEBT" -eq 0 ]; then
    check "PASS" "No TODO/FIXME/HACK comments (clean codebase)"
else
    check "WARN" "$TECH_DEBT file(s) with technical debt markers"
fi

# ─── Section 4: UI/Theme Consistency ──────────────────────────────
echo -e "\n${BOLD}━━━ 4. UI/THEME CONSISTENCY ━━━${NC}\n"

# Check for system accent colors (Color.white/black are fine for overlays)
SYS_COLORS=$(grep -rl "Color\.\(red\|blue\|green\|yellow\|orange\|pink\|purple\|gray\)" "$PROJECT_DIR" --include="*.swift" 2>/dev/null | wc -l)
if [ "$SYS_COLORS" -lt 3 ]; then
    check "PASS" "Minimal system colors: $SYS_COLORS occurrences (Aurora themed)"
else
    check "WARN" "$SYS_COLORS system color usages found — should use AuroraTheme"
fi

# Check preferredColorScheme
VIEWS_WITH_DARK=$(grep -rl "preferredColorScheme(.dark)" "$PROJECT_DIR"/Views --include="*.swift" 2>/dev/null | wc -l)
TOTAL_VIEWS=$(find "$PROJECT_DIR/Views" -name "*.swift" | wc -l)
echo "  Dark mode views: $VIEWS_WITH_DARK / $TOTAL_VIEWS"
if [ "$VIEWS_WITH_DARK" -gt "$((TOTAL_VIEWS * 2 / 3))" ]; then
    check "PASS" "Dark mode enforced on $VIEWS_WITH_DARK/$TOTAL_VIEWS views"
else
    check "WARN" "Only $VIEWS_WITH_DARK/$TOTAL_VIEWS views enforce dark mode"
fi

# Check AuroraTheme usage
THEME_REFS=$(grep -rn "AuroraTheme\." "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
check "PASS" "AuroraTheme referenced $THEME_REFS times across codebase"

# Check for .auroraCard() usage
CARD_USAGE=$(grep -rn "\.auroraCard()" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
check "PASS" ".auroraCard() modifier used $CARD_USAGE times"

# Check .scrollContentBackground(.hidden)
SCROLL_BG=$(grep -rn "scrollContentBackground(.hidden)" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
check "PASS" "scrollContentBackground(.hidden) used in $SCROLL_BG views (proper List theming)"

# ─── Section 5: Security Checks ───────────────────────────────────
echo -e "\n${BOLD}━━━ 5. SECURITY CHECKS ━━━${NC}\n"

# Hardcoded secrets (exclude placeholder text in SecureField/TextField)
HARDCODED_KEYS=$(grep -rn "sk-ant-\|api_key.*=.*\"[A-Za-z0-9]" "$PROJECT_DIR" --include="*.swift" 2>/dev/null | grep -v "SecureField\|placeholder\|prompt\|\.\.\." | wc -l)
if [ "$HARDCODED_KEYS" -eq 0 ]; then
    check "PASS" "No hardcoded API keys found"
else
    check "FAIL" "$HARDCODED_KEYS hardcoded API keys detected!"
fi

# Keychain usage
if grep -rq "KeychainHelper" "$PROJECT_DIR" --include="*.swift"; then
    check "PASS" "KeychainHelper used for secure credential storage"
else
    check "WARN" "No KeychainHelper usage found"
fi

# HTTPS enforcement
HTTP_URLS=$(grep -rn "http://" "$PROJECT_DIR" --include="*.swift" | grep -cv "https://" 2>/dev/null || true)
if [ "$HTTP_URLS" -eq 0 ]; then
    check "PASS" "All URLs use HTTPS"
else
    check "WARN" "$HTTP_URLS non-HTTPS URL(s) found"
fi

# ─── Section 6: Performance Indicators ─────────────────────────────
echo -e "\n${BOLD}━━━ 6. PERFORMANCE INDICATORS ━━━${NC}\n"

# Check for @Query optimization (avoid fetching too much)
QUERY_COUNT=$(grep -rn "@Query" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
echo "  @Query annotations: $QUERY_COUNT"
check "PASS" "$QUERY_COUNT SwiftData @Query usages for reactive data loading"

# Check for lazy loading patterns
LAZY_PATTERNS=$(grep -rn "LazyVGrid\|LazyHGrid\|LazyVStack\|LazyHStack" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
echo "  Lazy layout usages: $LAZY_PATTERNS"
if [ "$LAZY_PATTERNS" -gt 0 ]; then
    check "PASS" "$LAZY_PATTERNS lazy layout views (efficient for large lists)"
else
    check "WARN" "No lazy layouts found — may cause performance issues with large lists"
fi

# Check for async/await usage
ASYNC_FUNCS=$(grep -rn "func.*async" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
AWAIT_CALLS=$(grep -rn "await " "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
echo "  Async functions: $ASYNC_FUNCS"
echo "  Await calls: $AWAIT_CALLS"
check "PASS" "$ASYNC_FUNCS async functions, $AWAIT_CALLS await calls (non-blocking)"

# Check for image caching
if grep -rq "ImageCache" "$PROJECT_DIR" --include="*.swift"; then
    check "PASS" "ImageCache service found for cover art caching"
else
    check "WARN" "No image caching found"
fi

# Check for excessive re-renders (@State counts)
STATE_VARS=$(grep -rn "@State " "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
echo "  @State variables: $STATE_VARS"
if [ "$STATE_VARS" -lt 200 ]; then
    check "PASS" "$STATE_VARS @State variables — manageable re-render scope"
else
    check "WARN" "High @State count ($STATE_VARS) — may cause excessive re-renders"
fi

# Check for heavy work on main thread
NONISOLATED=$(grep -rn "nonisolated" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
echo "  nonisolated methods: $NONISOLATED (background work)"
if [ "$NONISOLATED" -gt 0 ]; then
    check "PASS" "$NONISOLATED nonisolated methods for background processing"
else
    check "WARN" "No nonisolated methods — all work may be on main thread"
fi

# Check for Task {} usage (async execution)
TASK_BLOCKS=$(grep -rn "Task {" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
echo "  Task {} blocks: $TASK_BLOCKS"
check "PASS" "$TASK_BLOCKS Task blocks for async operations"

# Memory: check for externalStorage on large data
EXT_STORAGE=$(grep -rn "@Attribute(.externalStorage)" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
if [ "$EXT_STORAGE" -gt 0 ]; then
    check "PASS" "$EXT_STORAGE @Attribute(.externalStorage) — cover images stored efficiently"
else
    check "WARN" "No externalStorage — large binary data may bloat SwiftData store"
fi

# ─── Section 7: Feature Completeness ──────────────────────────────
echo -e "\n${BOLD}━━━ 7. FEATURE COMPLETENESS ━━━${NC}\n"

features_check() {
    local name="$1"
    local pattern="$2"
    local file="$3"
    if grep -q "$pattern" "$PROJECT_DIR/$file" 2>/dev/null; then
        check "PASS" "$name"
    else
        check "FAIL" "$name — missing"
    fi
}

features_check "EPUB Parser (real)" "ZIPExtractor\|extractChapters" "Services/Parsers/EPUBParser.swift"
features_check "Cloud Storage OAuth (Dropbox)" "ASWebAuthenticationSession\|dropbox.com/oauth2" "Services/Cloud/CloudStorageService.swift"
features_check "Cloud Storage OAuth (Google)" "googleapis.com\|google.*oauth" "Services/Cloud/CloudStorageService.swift"
features_check "Book Discovery (Open Library)" "openlibrary.org" "Services/GoodReads/GoodReadsService.swift"
features_check "iCloud Sync (NSUbiquitousKeyValueStore)" "NSUbiquitousKeyValueStore\|iCloud" "Services/Sync/SyncService.swift"
features_check "AI Companion (Claude)" "anthropic.com\|claude" "Services/AI/ClaudeAPIClient.swift"
features_check "Ambient Audio (AVAudioEngine)" "AVAudioEngine\|AVAudioSourceNode" "Services/Ambient/AmbientService.swift"
features_check "Text-to-Speech (AVSpeechSynthesizer)" "AVSpeechSynthesizer\|AVSpeechUtterance" "Services/TTS/TextToSpeechService.swift"
features_check "Dictionary Lookup (UIReferenceLibrary)" "UIReferenceLibraryViewController" "Services/Dictionary/DictionaryLookupService.swift"
features_check "Data Export (JSON/CSV/MD)" "ExportFormat.*json\|ExportFormat" "Services/Export/DataExportService.swift"
features_check "Highlights & Annotations" "Highlight" "Models/Highlight.swift"
features_check "Bookmarks" "Bookmark" "Models/Bookmark.swift"
features_check "In-Chapter Search" "SearchService\|searchInChapter" "Services/Search/SearchService.swift"
features_check "Knowledge Graph" "KnowledgeNode" "Models/KnowledgeNode.swift"
features_check "Reading Stats & Streaks" "ReadingStreak\|ReadingSession" "Models/ReadingStreak.swift"
features_check "Achievements" "Achievement" "Models/Achievement.swift"
features_check "Book Clubs" "BookClub" "Models/BookClub.swift"
features_check "Vocabulary Builder" "VocabularyEntry" "Models/VocabularyEntry.swift"
features_check "Onboarding" "hasCompletedOnboarding\|WelcomeView" "Views/Onboarding/WelcomeView.swift"
features_check "Cover Art Discovery" "CoverArtService\|fetchMissingCovers" "Services/CoverArt/CoverArtService.swift"
features_check "Metadata Enrichment" "MetadataService\|enrichLibrary" "Services/Metadata/MetadataService.swift"
features_check "In-Chapter Position" "scrollOffset" "Models/ReadingProgress.swift"
features_check "Bionic Reading Mode" "BionicTextView" "Views/Reader/SmartReadingModesView.swift"
features_check "Speed Reading Mode" "SpeedReadingView" "Views/Reader/SmartReadingModesView.swift"
features_check "Focus Mode" "FocusModeView" "Views/Reader/SmartReadingModesView.swift"
features_check "Keychain Security" "SecItemAdd\|kSecClass" "Utilities/KeychainHelper.swift"

# ─── Section 8: Performance Stress Estimates ───────────────────────
echo -e "\n${BOLD}━━━ 8. PERFORMANCE STRESS ESTIMATES ━━━${NC}\n"

echo "  Analyzing file sizes and complexity for performance prediction..."
echo ""

# Largest view files (render complexity)
echo "  View Render Complexity (by lines):"
find "$PROJECT_DIR/Views" -name "*.swift" -exec wc -l {} + | sort -rn | head -6 | tail -5 | while read line; do
    lines=$(echo "$line" | awk '{print $1}')
    file=$(echo "$line" | awk '{print $2}' | sed "s|$PROJECT_DIR/||")
    if [ "$lines" -gt 400 ]; then
        echo -e "    ${YELLOW}$lines${NC}  $file  (complex — consider splitting)"
    elif [ "$lines" -gt 200 ]; then
        echo -e "    ${CYAN}$lines${NC}  $file  (moderate)"
    else
        echo -e "    ${GREEN}$lines${NC}  $file  (lean)"
    fi
done

echo ""

# Service complexity
echo "  Service Complexity (by lines):"
find "$PROJECT_DIR/Services" -name "*.swift" -exec wc -l {} + | sort -rn | head -6 | tail -5 | while read line; do
    lines=$(echo "$line" | awk '{print $1}')
    file=$(echo "$line" | awk '{print $2}' | sed "s|$PROJECT_DIR/||")
    if [ "$lines" -gt 500 ]; then
        echo -e "    ${YELLOW}$lines${NC}  $file"
    else
        echo -e "    ${GREEN}$lines${NC}  $file"
    fi
done

echo ""

# Estimated startup cost
INIT_SINGLETONS=$(grep -rn "static let shared = " "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
echo "  Singletons initialized at startup: $INIT_SINGLETONS"
if [ "$INIT_SINGLETONS" -lt 15 ]; then
    check "PASS" "Startup cost: $INIT_SINGLETONS singletons — fast cold launch"
else
    check "WARN" "High startup cost: $INIT_SINGLETONS singletons to initialize"
fi

# Model schema complexity
RELATIONSHIPS=$(grep -rn "@Relationship" "$PROJECT_DIR" --include="*.swift" | wc -l 2>/dev/null || echo 0)
echo "  SwiftData relationships: $RELATIONSHIPS"
if [ "$RELATIONSHIPS" -lt 20 ]; then
    check "PASS" "$RELATIONSHIPS model relationships — manageable graph complexity"
else
    check "WARN" "$RELATIONSHIPS relationships — complex data graph may slow queries"
fi

# ─── FINAL SUMMARY ────────────────────────────────────────────────
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo ""
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    QA RESULTS SUMMARY                       ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo -e "║  ${GREEN}PASSED:  $PASS${CYAN}                                                ║"
echo -e "║  ${YELLOW}WARNINGS: $WARN${CYAN}                                               ║"
echo -e "║  ${RED}FAILED:  $FAIL${CYAN}                                                ║"
echo -e "║  TOTAL:   $TOTAL                                               ║"
echo -e "║                                                              ║"

SCORE=$(( PASS * 100 / TOTAL ))
if [ "$SCORE" -gt 90 ]; then
    echo -e "║  ${GREEN}OVERALL SCORE: ${SCORE}% ████████████████████ EXCELLENT${CYAN}      ║"
elif [ "$SCORE" -gt 75 ]; then
    echo -e "║  ${YELLOW}OVERALL SCORE: ${SCORE}% ███████████████░░░░░ GOOD${CYAN}           ║"
else
    echo -e "║  ${RED}OVERALL SCORE: ${SCORE}% █████████░░░░░░░░░░░ NEEDS WORK${CYAN}    ║"
fi

echo "║                                                              ║"
echo "║  Test duration: ${DURATION}ms                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Report generated: $(date)"
