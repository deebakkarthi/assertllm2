# JasperGold Mutation Testing Template
# Placeholders will be replaced by runner.py

#For Clearing all previous settings
clear -all

# mkdir
if {![file exists {{WORK_DIR}}/report]} {
  file mkdir {{WORK_DIR}}/report
}

#For coverage purpose
check_cov -init -type all -model {branch toggle statement} -toggle_ports_only

# Analyze mutant RTL file
{{MUTANT_RTL}}

# Analyze assertions
analyze -sv12 {{ASSERTIONS_FILE}}

analyze -sv12 {{BINDING_FILE}}


# Elaborate with parameters
elaborate -top {{TOP_MODULE}} {{PARAMETERS}} {{BBOX_FLAGS}} -create_related_covers {precondition witness}

{{CLK_RST_BLOCK}}

# Run coverage analysis
check_cov -measure -type {coi stimuli proof bound} -time_limit 300s

# ============================================================
# REPORTS
# ============================================================
#     A) Formal Coverage 
check_cov -report -type formal \
  -report_file {{WORK_DIR}}/report/formal_coverage.rpt -force

#     B) Stimuli Coverage 
check_cov -report -type stimuli \
  -report_file {{WORK_DIR}}/report/stimuli_coverage.rpt -force

#     C) COI checker details
check_cov -report -type checker -checker_mode coi \
  -report_file {{WORK_DIR}}/report/checker_coi.rpt -force

#     D) Proof-core checker details
check_cov -report -type checker  \
  -report_file {{WORK_DIR}}/report/checker_proof.rpt -force

#     E) Property result summary (CRITICAL for mutation testing)
report -summary -force -result -file {{WORK_DIR}}/report/design.fpv.rpt

exit