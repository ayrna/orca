# $Id: Makefile 2614 2006-02-04 04:42:26Z ling $

LEMGA = ..

objs = nnet bag adabst showlm testsvm lpbst multi

.PHONY: test debug clean $(addsuffix _clean, $(objs))
test:  $(addsuffix r, $(objs))
debug: $(addsuffix d, $(objs))
clean: $(addsuffix _clean, $(objs))

include ${LEMGA}/lemga/Makefile
VPATH = ${LEMGA}/lemga
CC_FLAGS := -I${LEMGA} ${CC_FLAGS}

nnet_src = nnet.cpp $(random_h) $(nnlayer_h) $(feedforwardnn_h)
rnnet.o: $(nnet_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dnnet.o: $(nnet_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

nnet_o  := $(random_o) $(nnlayer_o) $(feedforwardnn_o) nnet.o
nnet_ro := $(addprefix r, $(nnet_o))
nnet_do := $(addprefix d, $(nnet_o))
nnetr: $(nnet_ro)
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
nnetd: $(nnet_do)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_LIB_FLAGS) -o $@ $^
nnet_clean:
	$(RM) $(nnet_ro) $(nnet_do) nnetr nnetd

bag_src = bag.cpp $(stump_h) $(bagging_h)
rbag.o: $(bag_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dbag.o: $(bag_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

bag_o  := $(stump_o) $(bagging_o) bag.o
bag_ro := $(addprefix r, $(bag_o))
bag_do := $(addprefix d, $(bag_o))
bagr: $(bag_ro)
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
bagd: $(bag_do)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_LIB_FLAGS) -o $@ $^
bag_clean:
	$(RM) $(bag_ro) $(bag_do) bagr bagd

adabst_src = adabst.cpp $(pulse_h) $(adaboost_h) $(mgnboost_h)
radabst.o: $(adabst_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dadabst.o: $(adabst_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

adabst_o  := $(pulse_o) $(adaboost_o) $(mgnboost_o) adabst.o
adabst_ro := $(addprefix r, $(adabst_o))
adabst_do := $(addprefix d, $(adabst_o))
adabstr: $(adabst_ro)
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
adabstd: $(adabst_do)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_LIB_FLAGS) -o $@ $^
adabst_clean:
	$(RM) $(adabst_ro) $(adabst_do) adabstr adabstd

showlm_src = showlm.cpp $(object_h)
rshowlm.o: $(showlm_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dshowlm.o: $(showlm_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

showlm_o  := $(stump_o) $(pulse_o) $(perceptron_o) $(feedforwardnn_o) \
	$(bagging_o) $(adaboost_o) $(cgboost_o) $(mgnboost_o) $(lpboost_o) \
	$(multiclass_ecoc_o) $(adaboost_ecoc_o) $(crossval_o) \
	$(kernel_o) $(svm_o) \
	showlm.o
showlm_ro := $(addprefix r, $(showlm_o))
showlm_do := $(addprefix d, $(showlm_o))
showlmr: $(showlm_ro) $(lpboost_lib)
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
showlmd: $(showlm_do) $(lpboost_lib)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_LIB_FLAGS) -o $@ $^
showlm_clean:
	$(RM) $(showlm_ro) $(showlm_do) showlmr showlmd

testsvm_src = testsvm.cpp $(random_h) $(crossval_h) $(svm_h)
rtestsvm.o: $(testsvm_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dtestsvm.o: $(testsvm_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

testsvm_o  := $(random_o) $(crossval_o) $(svm_o) testsvm.o
testsvm_ro := $(addprefix r, $(testsvm_o))
testsvm_do := $(addprefix d, $(testsvm_o))
testsvmr: $(testsvm_ro)
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
testsvmd: $(testsvm_do)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_LIB_FLAGS) -o $@ $^
testsvm_clean:
	$(RM) $(testsvm_ro) $(testsvm_do) testsvmr testsvmd

lpbst_src = lpbst.cpp $(stump_h) $(adaboost_h) $(lpboost_h)
rlpbst.o: $(lpbst_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dlpbst.o: $(lpbst_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

lpbst_o  := $(stump_o) $(adaboost_o) $(lpboost_o) lpbst.o
lpbst_ro := $(addprefix r, $(lpbst_o))
lpbst_do := $(addprefix d, $(lpbst_o))
lpbstr: $(lpbst_ro) $(lpboost_lib)
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
lpbstd: $(lpbst_do) $(lpboost_lib)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_LIB_FLAGS) -o $@ $^
lpbst_clean:
	$(RM) $(lpbst_ro) $(lpbst_do) lpbstr lpbstd

multi_src = multi.cpp $(perceptron_h) $(adaboost_h) $(multiclass_ecoc_h)
rmulti.o: $(multi_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dmulti.o: $(multi_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

multi_o  := $(perceptron_o) $(adaboost_o) $(multiclass_ecoc_o) multi.o
multi_ro := $(addprefix r, $(multi_o))
multi_do := $(addprefix d, $(multi_o))
multir: $(multi_ro)
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
multid: $(multi_do)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) $(CC_LIB_FLAGS) -o $@ $^
multi_clean:
	$(RM) $(multi_ro) $(multi_do) multir multid
