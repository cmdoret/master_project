include config.mk

.PHONY : all
all : $(POP)

# Mapping reads with BWA
$(MAP) : $(PROC)
	rm -rf $@
	mkdir -p $@
	bash $(BWA-SRC) --mm $(MM) \
	                --ref $(REF) \
									--reads $(PROC) \
									--out $(MAP)

# Building stacks from reference with Pstacks
$(PSTACK) : $(MAP)
  bash $(P-SRC) --map $< \
                --m $(M) \
							  --out $@ \
							  --log $(LOG)

# Building loci catalog with Cstacks
$(CSTACK): $(PSTACK)
	rm -fr $@;
	mkdir -p $@;
	bash $(C-SRC) --pst $< \
	              --cst $@ \
								--lm $(LM)

# Running Sstacks
$(SSTACK) : $(CSTACK)
  bash $(S-SRC) --in $(PSTACK) \
                --cat $< \
							  --out $@ \
							  --log $(LOG)
  # Organizing p/c/s stacks files into a common folder
  bash $(GR-SRC) $(PSTACK) $(CSTACK) $(SSTACK) $(GRFAM)

# Running populations on each family
$(POP) : $(SSTACK) $(POP-SRC)
	rm -rf $@
	mkdir -p $@
	# Erasing logs from previous run
	rm -rf $(LOG)/populations
	mkdir -p $(LOG)/populations
	# Changing parameters directly in the file
	bash $(POP-SRC) --sst $< \
	                --thresh $(THRESH) \
									--group $(GRFAM) \
									--md $(D) \
									--r $(R) \
									--out $@ \
									--log $(LOG)
