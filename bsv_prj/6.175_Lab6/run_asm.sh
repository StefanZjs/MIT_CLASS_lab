#!/bin/bash

asm_tests=(
	jal j  jalr
	add addi
	and andi
	auipc
	beq bge bgeu blt bltu bne
	lw
	lui
	or ori
	sw
	sll slli
	slt slti
	sra srai
	srl srli
	sub
	xor xori
	bpred_bht bpred_j bpred_ras bpred_j_noloop
	cache
	simple
	)

vmh_dir=programs/build/assembly/vmh
log_dir=logs
wait_time=0.1

# create bsim log dir
mkdir -p ${log_dir}

# kill previous bsim if any
pkill bluetcl

echo "Assembly Test" > log

# run each test
for test_name in ${asm_tests[@]}; do
	echo "-- assembly test: ${test_name} --" >> log
	# copy vmh file
	mem_file=${vmh_dir}/${test_name}.riscv.vmh
	if [ ! -f $mem_file ]; then
		echo "ERROR: $mem_file does not exit, you need to first compile"
		exit
	fi
	cp ${mem_file} ./mem.vmh 

	# run test
	# make run.bluesim 1> ${log_dir}/${test_name}.log # run bsim, redirect outputs to log
	bluesim/bin/ubuntu.exe 1> ${log_dir}/${test_name}.log
	sleep ${wait_time}
	echo ""
done

rm ./SWSOCK0
rm ./mem.vmh