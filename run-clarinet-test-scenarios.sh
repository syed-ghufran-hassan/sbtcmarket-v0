#!/usr/bin/env bash

# sBTC Market Test Scenarios Runner
# This script runs predefined test scenarios through Clarinet console

set -e  # Exit on error
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/clarinet-test-scenarios"
RESULTS_DIR="$SCRIPT_DIR/clarinet-test-results"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Available scenarios (number|name|description)
SCENARIOS=(
    "1|scenario1-yes-wins|3 users buy YES shares, then YES wins resolution"
    "2|scenario2-no-wins|3 users buy YES, 4 users buy NO, then NO wins"
    "3|scenario3-edge-cases|Tests boundary conditions and error handling"
    "4|scenario4-amm-pricing|Tests constant-product formula and price impact"
    "5|scenario5-proportional-redemption|Tests over-issuance handling and fair distribution"
    "6|scenario6-fee-collection|Tests protocol fees and treasury mechanics"
    "7|scenario7-mass-redemption|10 users redeem in different orders - fairness test"
    "8|scenario8-redemption-edge-cases|Tests dust, losers, mixed positions, over-issuance"
    "9|scenario9-two-user-redemption|Tests Pyth oracle integration for price feeds"
    "10|scenario10-refund-and-resolution-edge-cases|Tests cancel-market, refund, and resolution timestamp validation"
    "11|scenario11-access-control-security|Tests unauthorized access to privileged functions"
    "12|scenario12-swap-mechanics|Tests swap-shares function edge cases and round trips"
    "13|scenario13-over-issuance-attacks|Tests deliberate attempts to break invariants"
    "14|scenario14-price-manipulation|Tests front-running, sandwich attacks, whale manipulation"
    "15|scenario15-integer-overflow-underflow|Tests extreme values and math edge cases"
    "16|scenario16-complete-state-transitions|Tests all market lifecycle states and transitions"
    "17|scenario17-market-creator-management|Tests add/remove market creator permissions"
    "18|scenario18-resolution-window-and-cancellation|Tests resolution window timing and cancellation logic"
    "19|scenario19-refund-proportional-payout|Tests refund-shares with YES-only, NO-only, and mixed positions"
    "20|scenario20-special-characters-in-questions|Tests market creation with special characters (>=, <=, <, >, =) in question names"
)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}sBTC Market - Test Scenarios${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to get scenario info by number
get_scenario() {
    local num=$1
    for scenario in "${SCENARIOS[@]}"; do
        IFS='|' read -r snum sname sdesc <<< "$scenario"
        if [ "$snum" = "$num" ]; then
            echo "$sname|$sdesc"
            return 0
        fi
    done
    return 1
}

# Function to display menu
show_menu() {
    echo -e "${YELLOW}Available Test Scenarios:${NC}"
    echo ""
    for scenario in "${SCENARIOS[@]}"; do
        IFS='|' read -r num name description <<< "$scenario"
        echo -e "  ${GREEN}[$num]${NC} $name"
        echo -e "      $description"
        echo ""
    done
    echo -e "  ${GREEN}[a]${NC} Run all scenarios"
    echo -e "  ${GREEN}[q]${NC} Quit"
    echo ""
}

# Function to run a scenario
run_scenario() {
    local scenario_name=$1
    local scenario_file="$SCENARIOS_DIR/${scenario_name}.clar"
    local result_file="$RESULTS_DIR/${scenario_name}-result.txt"

    if [ ! -f "$scenario_file" ]; then
        echo -e "${RED}✗ Scenario file not found: $scenario_file${NC}"
        return 1
    fi

    echo -e "${YELLOW}Running: ${scenario_name}${NC}"
    echo "Input file: $scenario_file"
    echo "Output file: $result_file"
    echo ""

    local temp_log
    temp_log="$(mktemp)"

    set +e
    while IFS= read -r line || [ -n "${line}" ]; do
        printf '%s\n' "$line"
    done < "$scenario_file" \
    | tee >(while IFS= read -r cmd_line || [ -n "${cmd_line}" ]; do
                if [ -n "${cmd_line}" ]; then
                    entry=">> ${cmd_line}"
                else
                    entry=">>"
                fi
                printf '%s\n' "$entry" >> "$temp_log"
            done) \
    | clarinet console 2>&1 \
    | tee -a "$temp_log"
    pipeline_status=${PIPESTATUS[2]}
    set -e

    cp "$temp_log" "$result_file"
    rm -f "$temp_log"

    if [ "$pipeline_status" -eq 0 ]; then
        echo -e "${GREEN}✓ ${scenario_name} completed${NC}"

        if grep -q "error:" "$result_file"; then
            echo -e "${RED}  ⚠ Errors detected in output${NC}"
            echo -e "${YELLOW}  Check: $result_file${NC}"
        elif grep -q "Runtime error" "$result_file"; then
            echo -e "${RED}  ⚠ Runtime errors detected${NC}"
            echo -e "${YELLOW}  Check: $result_file${NC}"
        else
            echo -e "${GREEN}  No errors detected${NC}"
        fi
    else
        echo -e "${RED}✗ ${scenario_name} failed to execute${NC}"
    fi

    echo ""
}

# Function to run selected scenarios
run_selected_scenarios() {
    local selection="$1"

    # Handle "all" option
    if [[ "$selection" == "a" ]]; then
        for scenario in "${SCENARIOS[@]}"; do
            IFS='|' read -r num name description <<< "$scenario"
            echo -e "${BLUE}=== Scenario $num: $name ===${NC}"
            echo "$description"
            echo ""
            run_scenario "$name"
        done
        return
    fi

    # Split comma-separated list and run each scenario
    IFS=',' read -ra SELECTED <<< "$selection"
    for num in "${SELECTED[@]}"; do
        num=$(echo "$num" | xargs)  # Trim whitespace
        info=$(get_scenario "$num")
        if [ $? -eq 0 ]; then
            IFS='|' read -r name description <<< "$info"
            echo -e "${BLUE}=== Scenario $num: $name ===${NC}"
            echo "$description"
            echo ""
            run_scenario "$name"
        else
            echo -e "${RED}Invalid scenario number: $num${NC}"
            echo ""
        fi
    done
}

# Main interactive loop
if [ $# -eq 0 ]; then
    # Interactive mode
    while true; do
        show_menu
        read -p "Select scenario(s) to run (e.g., 1, 1,3,7, or a for all): " choice

        case "$choice" in
            q|Q)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo ""
                run_selected_scenarios "$choice"
                ;;
        esac
    done
else
    # Command-line mode: accept arguments
    run_selected_scenarios "$1"
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Results saved in: $RESULTS_DIR"
echo ""
echo "To view detailed results:"
echo "  cat $RESULTS_DIR/scenario1-yes-wins-result.txt"
echo "  cat $RESULTS_DIR/scenario2-no-wins-result.txt"
echo ""

# Generate summary report
SUMMARY_FILE="$RESULTS_DIR/summary.txt"
echo "sBTC Market Test Scenarios - Summary" > "$SUMMARY_FILE"
echo "Generated: $(date)" >> "$SUMMARY_FILE"
echo "========================================" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

for result_file in "$RESULTS_DIR"/*-result.txt; do
    if [ -f "$result_file" ]; then
        scenario_name=$(basename "$result_file" -result.txt)
        echo "Scenario: $scenario_name" >> "$SUMMARY_FILE"

        if grep -q "error:" "$result_file" || grep -q "Runtime error" "$result_file"; then
            echo "Status: FAILED" >> "$SUMMARY_FILE"
            echo "Errors found:" >> "$SUMMARY_FILE"
            grep -i "error" "$result_file" | head -5 >> "$SUMMARY_FILE"
        else
            echo "Status: PASSED" >> "$SUMMARY_FILE"
        fi

        echo "" >> "$SUMMARY_FILE"
    fi
done

echo -e "${GREEN}Summary report: $SUMMARY_FILE${NC}"
echo ""
