# Run after simulation (xcelium> prompt) or via: xrun ... -input sim/coverage_report.tcl
coverage -report -detail -file coverage_report.txt
puts "Coverage report written to coverage_report.txt"
