# ============================================================
# Generalized VCS/UVM Makefile
# Drop in any project dir that has file_list.f
# ============================================================

SHELL := /bin/bash   # needed for PIPESTATUS[] and arrays below

FILELIST := file_list.f
SIMV     := simv
VCS      := vcs

COV_DIR  := cov_work
COV_OPTS := -cm line+cond+fsm+branch+tgl -cm_dir $(COV_DIR)

VCS_OPTS := -sverilog -ntb_opts uvm-1.2 -full64 -f $(FILELIST) $(COV_OPTS)

RED   := \033[0;31m
GREEN := \033[0;32m
CYAN  := \033[0;36m
BOLD  := \033[1m
NC    := \033[0m

# --------------------------------------------------------------
# Noise filter for the live terminal view during compile.
# --------------------------------------------------------------
COMPILE_NOISE := ^(Parsing (design|included) file|Back to file|make\[1\]|rm -f _cuarc|if \[ -x \.\./simv|g\+\+|\.\./simv up to date|recompiling (package|module))

# --------------------------------------------------------------
# Track EVERY .sv/.svh in cwd (not just what's in file_list.f).
# --------------------------------------------------------------
SRC_FILES := $(wildcard *.sv) $(wildcard *.svh)

# --------------------------------------------------------------
# Discover test classes: any "class X extends ...*test*" in cwd sources.
# Catches alu_base_test, test_ce, etc. regardless of naming scheme,
# as long as the parent class name contains "test" (case-insensitive).
# --------------------------------------------------------------
TESTS := $(shell grep -hE 'class[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+extends[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[Tt][Ee][Ss][Tt][A-Za-z0-9_]*' $(SRC_FILES) 2>/dev/null | sed -E 's/^[[:space:]]*class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]+extends.*/\1/' | sort -u)

.PHONY: all compile simulate sim coverage merge clean help tests

# --------------------------------------------------------------
# Lets you write:  make simulate 3 medium   OR   make simulate alu_base_test medium
# --------------------------------------------------------------
ifeq (simulate,$(firstword $(MAKECMDGOALS)))
  SIM_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(SIM_ARGS):;@:)
endif

all: compile

# ---- COMPILE (with coverage) -------------------------------------------
$(SIMV): $(FILELIST) $(SRC_FILES)
	@echo -e "$(CYAN)Compiling (coverage enabled)...$(NC)"
	@$(VCS) $(VCS_OPTS) 2>&1 | tee compile.log | grep -vE '$(COMPILE_NOISE)'; \
	status=$${PIPESTATUS[0]}; \
	border=$$(printf '%.0s-' {1..50}); \
	top=$$(grep -A1 "Top Level Modules:" compile.log | tail -1 | xargs); \
	cpu=$$(grep "CPU time:" compile.log); \
	if [ $$status -ne 0 ] || grep -qE "^Error-|Error:" compile.log; then \
		echo -e "$(RED)$$border$(NC)"; \
		echo -e "$(RED)$(BOLD)  COMPILE FAILED$(NC)"; \
		echo -e "$(RED)$$border$(NC)"; \
		grep -E "^Error-|Error:" compile.log | sed 's/^/  /'; \
		echo -e "$(RED)$$border$(NC)"; \
		exit 1; \
	else \
		echo -e "$(GREEN)$$border$(NC)"; \
		echo -e "$(GREEN)$(BOLD)  COMPILE SUCCESS$(NC)"; \
		echo -e "$(GREEN)$$border$(NC)"; \
		echo -e "  Top module : $$top"; \
		echo -e "  $$cpu"; \
		echo -e "$(GREEN)$$border$(NC)"; \
	fi

compile: $(SIMV)

# ---- TESTS (just list discovered test classes, no run) --------------------
tests:
	@tests=($(TESTS)); \
	if [ $${#tests[@]} -eq 0 ]; then \
		echo "No test classes found (looked for 'class X extends *test*' in *.sv/*.svh)."; \
	else \
		echo -e "$(CYAN)Discovered tests:$(NC)"; \
		i=1; \
		for t in "$${tests[@]}"; do \
			printf "  %2d) %s\n" "$$i" "$$t"; \
			i=$$((i+1)); \
		done; \
	fi

# ---- SIMULATE -----------------------------------------------------------
# make simulate                      -> lists tests, prompts for number/name + verbosity
# make simulate 3                    -> runs the 3rd test in the discovered list, UVM_MEDIUM
# make simulate 3 high               -> runs 3rd test at UVM_HIGH
# make simulate alu_base_test medium -> runs by name directly, still works as before
simulate: compile
	@tests=($(TESTS)); \
	arg1=$(word 1,$(SIM_ARGS)); \
	arg2=$(word 2,$(SIM_ARGS)); \
	if [ -z "$$arg1" ]; then \
		if [ $${#tests[@]} -eq 0 ]; then \
			echo "No test classes found (looked for 'class X extends *test*' in *.sv/*.svh)."; \
			read -p "UVM_TESTNAME: " test; \
			read -p "UVM_VERBOSITY [UVM_MEDIUM]: " verbraw; \
		else \
			echo -e "$(CYAN)Available tests:$(NC)"; \
			i=1; \
			for t in "$${tests[@]}"; do \
				printf "  %2d) %s\n" "$$i" "$$t"; \
				i=$$((i+1)); \
			done; \
			read -p "Select test number (or type a name): " sel; \
			if [[ "$$sel" =~ ^[0-9]+$$ ]]; then \
				idx=$$((sel-1)); \
				test=$${tests[$$idx]}; \
			else \
				test=$$sel; \
			fi; \
			read -p "UVM_VERBOSITY [UVM_MEDIUM]: " verbraw; \
		fi; \
	elif [[ "$$arg1" =~ ^[0-9]+$$ ]]; then \
		idx=$$((arg1-1)); \
		test=$${tests[$$idx]}; \
		if [ -z "$$test" ]; then \
			echo -e "$(RED)No test at index $$arg1 (have $${#tests[@]} tests -- run 'make tests' to list them)$(NC)"; \
			exit 1; \
		fi; \
		verbraw=$$arg2; \
	else \
		test=$$arg1; \
		verbraw=$$arg2; \
	fi; \
	case "$$verbraw" in \
		low)    verb=UVM_LOW ;; \
		medium) verb=UVM_MEDIUM ;; \
		high)   verb=UVM_HIGH ;; \
		full)   verb=UVM_FULL ;; \
		debug)  verb=UVM_DEBUG ;; \
		"")     verb=UVM_MEDIUM ;; \
		*)      verb=$$verbraw ;; \
	esac; \
	if [ -z "$$test" ]; then \
		echo -e "$(CYAN)Running ./$(SIMV)$(NC)"; \
		./$(SIMV) +UVM_NO_RELNOTES $(COV_OPTS) 2>&1 | tee sim.log; \
	else \
		echo -e "$(CYAN)Running ./$(SIMV) +UVM_TESTNAME=$$test +UVM_VERBOSITY=$$verb$(NC)"; \
		./$(SIMV) +UVM_TESTNAME=$$test +UVM_VERBOSITY=$$verb +UVM_NO_RELNOTES $(COV_OPTS) 2>&1 | tee sim.log; \
	fi; \
	status=$${PIPESTATUS[0]}; \
	border=$$(printf '%.0s-' {1..50}); \
	err=$$(grep "UVM_ERROR :" sim.log | tail -1 | awk -F: '{print $$2}' | xargs); \
	fatal=$$(grep "UVM_FATAL :" sim.log | tail -1 | awk -F: '{print $$2}' | xargs); \
	warn=$$(grep "UVM_WARNING :" sim.log | tail -1 | awk -F: '{print $$2}' | xargs); \
	info=$$(grep "UVM_INFO :" sim.log | tail -1 | awk -F: '{print $$2}' | xargs); \
	simtime=$$(grep -E "^Time:" sim.log | tail -1); \
	if [ $$status -ne 0 ] || [ "$${err:-0}" -gt 0 ] 2>/dev/null || [ "$${fatal:-0}" -gt 0 ] 2>/dev/null || grep -qE "^Error-" sim.log; then \
		echo -e "$(RED)$$border$(NC)"; \
		echo -e "$(RED)$(BOLD)  SIMULATION FAILED $${test:+: $$test}$(NC)"; \
		echo -e "$(RED)$$border$(NC)"; \
		echo -e "  UVM_INFO:$${info:-?}  UVM_WARNING:$${warn:-?}  UVM_ERROR:$${err:-?}  UVM_FATAL:$${fatal:-?}"; \
		echo -e "$(RED)$$border$(NC)"; \
		exit 1; \
	else \
		echo -e "$(GREEN)$$border$(NC)"; \
		echo -e "$(GREEN)$(BOLD)  SIMULATION SUCCESS $${test:+: $$test}$(NC)"; \
		echo -e "$(GREEN)$$border$(NC)"; \
		echo -e "  UVM_INFO:$${info:-0}  UVM_WARNING:$${warn:-0}  UVM_ERROR:$${err:-0}  UVM_FATAL:$${fatal:-0}"; \
		echo -e "  $$simtime"; \
		echo -e "$(GREEN)$$border$(NC)"; \
	fi

sim: simulate

# ---- COVERAGE -------------------------------------------------------------
coverage:
	@echo -e "$(CYAN)Generating coverage report...$(NC)"
	@rm -rf cov_report; \
	urg -format both -dir $(COV_DIR).vdb -report cov_report 2>&1 | tee coverage.log; \
	status=$${PIPESTATUS[0]}; \
	border=$$(printf '%.0s-' {1..50}); \
	if [ $$status -ne 0 ]; then \
		echo -e "$(RED)$$border$(NC)"; \
		echo -e "$(RED)$(BOLD)  COVERAGE GENERATION FAILED$(NC)"; \
		echo -e "$(RED)$$border$(NC)"; \
		exit 1; \
	else \
		echo -e "$(GREEN)$$border$(NC)"; \
		echo -e "$(GREEN)$(BOLD)  COVERAGE REPORT GENERATED$(NC)"; \
		echo -e "$(GREEN)$$border$(NC)"; \
		txt=$$(find cov_report -maxdepth 1 -iname '*.txt' 2>/dev/null | head -1); \
		if [ -n "$$txt" ]; then \
			cat "$$txt"; \
			echo -e "$(GREEN)$$border$(NC)"; \
		fi; \
		echo -e "  HTML dashboard : cov_report/dashboard.html"; \
		echo -e "  (open via: cd cov_report && python3 -m http.server 8000 -- file:// won't render the score table)"; \
		echo -e "$(GREEN)$$border$(NC)"; \
	fi

# ---- MERGE ------------------------------------------------------------
# Runs every discovered test into the SAME coverage db ($(COV_DIR).vdb).
# VCS automatically appends each run as a separate test entry in one db --
# giving each test its own -cm_dir orphans the design database and makes
# urg unable to score it ("Design not yet loaded"), so don't do that.
merge: compile
	@tests=($(TESTS)); \
	if [ $${#tests[@]} -eq 0 ]; then \
		echo -e "$(RED)No test classes found -- nothing to merge.$(NC)"; \
		exit 1; \
	fi; \
	border=$$(printf '%.0s-' {1..50}); \
	rm -rf cov_report_merged; \
	echo -e "$(CYAN)Running $${#tests[@]} tests into shared coverage db $(COV_DIR).vdb...$(NC)"; \
	pass=0; fail=0; \
	failed_list=""; \
	for t in "$${tests[@]}"; do \
		echo -e "$(CYAN)  -> $$t$(NC)"; \
		./$(SIMV) +UVM_TESTNAME=$$t +UVM_VERBOSITY=UVM_MEDIUM +UVM_NO_RELNOTES $(COV_OPTS) > merge_$$t.log 2>&1; \
		st=$$?; \
		err=$$(grep "UVM_ERROR :" merge_$$t.log | tail -1 | awk -F: '{print $$2}' | xargs); \
		fatal=$$(grep "UVM_FATAL :" merge_$$t.log | tail -1 | awk -F: '{print $$2}' | xargs); \
		if [ $$st -ne 0 ] || [ "$${err:-0}" -gt 0 ] 2>/dev/null || [ "$${fatal:-0}" -gt 0 ] 2>/dev/null; then \
			echo -e "     $(RED)FAILED$(NC) (see merge_$$t.log)"; \
			fail=$$((fail+1)); \
			failed_list="$$failed_list $$t"; \
		else \
			echo -e "     $(GREEN)PASSED$(NC)"; \
			pass=$$((pass+1)); \
		fi; \
	done; \
	echo -e "$(CYAN)Generating merged coverage report...$(NC)"; \
	urg -format both -dir $(COV_DIR).vdb -report cov_report_merged > merge_coverage.log 2>&1; \
	ustatus=$$?; \
	echo -e "$(GREEN)$$border$(NC)"; \
	if [ $$ustatus -ne 0 ]; then \
		echo -e "$(RED)$(BOLD)  COVERAGE REPORT GENERATION FAILED (see merge_coverage.log)$(NC)"; \
	else \
		echo -e "$(BOLD)  MERGE COMPLETE$(NC)"; \
	fi; \
	echo -e "$(GREEN)$$border$(NC)"; \
	echo -e "  Tests run    : $${#tests[@]}   Passed: $(GREEN)$$pass$(NC)   Failed: $(RED)$$fail$(NC)"; \
	if [ -n "$$failed_list" ]; then \
		echo -e "  Failed tests:$$failed_list"; \
	fi; \
	txt=$$(find cov_report_merged -maxdepth 1 -iname '*.txt' 2>/dev/null | head -1); \
	if [ -n "$$txt" ]; then \
		echo -e "$(GREEN)$$border$(NC)"; \
		cat "$$txt"; \
	fi; \
	echo -e "$(GREEN)$$border$(NC)"; \
	echo -e "  HTML dashboard : cov_report_merged/dashboard.html"; \
	echo -e "$(GREEN)$$border$(NC)"

# ---- CLEAN ------------------------------------------------------------
clean:
	rm -rf simv simv.daidir csrc *.log *.vpd *.fsdb ucli.key DVEfiles vc_hdrs.h \
		$(COV_DIR).vdb cov_report urgReport cov_report_merged

help:
	@echo "make compile                    - compile w/ coverage (recompiles if any .sv/.svh in cwd changed)"
	@echo "make tests                      - list discovered test classes with serial numbers"
	@echo "make simulate                   - list tests, prompt for number/name + verbosity"
	@echo "make simulate <N>               - run test #N from the discovered list, UVM_MEDIUM default"
	@echo "make simulate <N> <verbosity>   - e.g. make simulate 3 high"
	@echo "make simulate <name> <verbosity>- e.g. make simulate alu_base_test medium"
	@echo "make coverage                   - generate coverage report from last sim run"
	@echo "make merge                      - run every discovered test and merge their coverage into one report"
	@echo "make clean                      - remove compile/sim/coverage artifacts"
