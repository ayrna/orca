CC = g++
CC_FINAL = -D NDEBUG -O3
CC_DEBUG = -O1
CC_LIB_FLAGS = -lm

ifeq ($(shell uname -s),Darwin)
	CC_FLAGS = -std=c++98 -Wall -Wshadow -Wcast-qual\
		-Wpointer-arith -Wconversion -Wredundant-decls\
		-Wwrite-strings -Woverloaded-virtual
else
	CC_FLAGS = -std=c++98 -static-libgcc -Wall -Wshadow -Wcast-qual\
		-Wpointer-arith -Wconversion -Wredundant-decls\
		-Wwrite-strings -Woverloaded-virtual
endif
CC_FINAL += -funroll-loops

#ifeq ($(CC), g++)        # for GCC >= 3.2.x
#CC_FLAGS = -std=c++98 -Wall -Wshadow -Wcast-qual\
#	-Wpointer-arith -Wconversion -Wredundant-decls\
#	-Wwrite-strings -Woverloaded-virtual
#CC_FINAL += -funroll-loops
##CC_FINAL += -march=pentium3 -mfpmath=sse -msse -mmmx
##CC_FINAL += -march=pentium4 -mfpmath=sse -msse -msse2 -mmmx
#endif

#ifeq ($(CC), icc)        # for ICC 8.0
#CC_FLAGS = -Wall -w1 -pch
#CC_FINAL += -i_dynamic -ipo -unroll
#CC_FINAL += -tpp6 -xK
##CC_FINAL += -tpp7 -xW
#endif

lemga_do_not_exec:
	echo Do not run "make" under this directory.

shared_ptr_h = shared_ptr.h
vectorop_h = vectorop.h
optimize_h = $(vectorop_h) optimize.h

object_h = object.h
object_o = object.o
object_src = object.cpp $(object_h)
robject.o: $(object_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dobject.o: $(object_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

random_h = $(object_h) random.h
random_o = $(object_o) random.o
random_src = random.c $(random_h)
rrandom.o: $(random_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
drandom.o: $(random_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

quickfun_h = $(object_h) quickfun.h
quickfun_o = $(object_o) quickfun.o
quickfun_src = quickfun.c $(quickfun_h)
rquickfun.o: $(quickfun_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dquickfun.o: $(quickfun_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

utility_h = $(object_h) utility.h
utility_o = utility.o
utility_src = utility.cpp $(utility_h)
rutility.o: $(utility_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dutility.o: $(utility_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

dataset_h = $(random_h) dataset.h
cost_h = $(object_h) cost.h

kernel_h = $(learnmodel_h) kernel.h
// have to include svm.o since Kernel::pass_params is implemented there
kernel_tmp_o = $(object_o) kernel.o
kernel_o = $(svm_o) $(kernel_tmp_o)
kernel_src = kernel.cpp $(kernel_h)
rkernel.o: $(kernel_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dkernel.o: $(kernel_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

learnmodel_h = $(object_h) $(dataset_h) $(shared_ptr_h) learnmodel.h
learnmodel_o = $(object_o) learnmodel.o
learnmodel_src = learnmodel.cpp $(learnmodel_h)
rlearnmodel.o: $(learnmodel_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dlearnmodel.o: $(learnmodel_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

datafeeder_h = $(learnmodel_h) datafeeder.h
datafeeder_o = $(learnmodel_o) $(random_o) datafeeder.o
datafeeder_src = datafeeder.cpp $(random_h) $(datafeeder_h)
rdatafeeder.o: $(datafeeder_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
ddatafeeder.o: $(datafeeder_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

crossval_h = $(shared_ptr_h) $(learnmodel_h) crossval.h
crossval_o = $(random_o) $(learnmodel_o) crossval.o
crossval_src = crossval.cpp $(vectorop_h) $(random_h) $(crossval_h)
rcrossval.o: $(crossval_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dcrossval.o: $(crossval_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

nnlayer_h = $(learnmodel_h) nnlayer.h
nnlayer_o = $(random_o) $(quickfun_o) $(learnmodel_o) nnlayer.o
nnlayer_src = nnlayer.cpp $(random_h) $(quickfun_h) $(nnlayer_h)
rnnlayer.o: $(nnlayer_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dnnlayer.o: $(nnlayer_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

feedforwardnn_h = $(learnmodel_h) $(nnlayer_h) feedforwardnn.h
feedforwardnn_o = $(learnmodel_o) $(nnlayer_o) feedforwardnn.o
feedforwardnn_src = feedforwardnn.cpp $(feedforwardnn_h) $(optimize_h)
rfeedforwardnn.o: $(feedforwardnn_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dfeedforwardnn.o: $(feedforwardnn_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

aggregating_h = $(learnmodel_h) $(shared_ptr_h) aggregating.h
aggregating_o = $(learnmodel_o) aggregating.o
aggregating_src = aggregating.cpp $(aggregating_h)
raggregating.o: $(aggregating_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
daggregating.o: $(aggregating_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

bagging_h = $(aggregating_h) bagging.h
bagging_o = $(aggregating_o) bagging.o
bagging_src = bagging.cpp $(bagging_h)
rbagging.o: $(bagging_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dbagging.o: $(bagging_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

boosting_h = $(aggregating_h) $(cost_h) boosting.h
boosting_o = $(aggregating_o) boosting.o
boosting_src = boosting.cpp $(vectorop_h) $(optimize_h) $(boosting_h)
rboosting.o: $(boosting_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dboosting.o: $(boosting_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

adaboost_h = $(boosting_h) adaboost.h
adaboost_o = $(boosting_o) adaboost.o
adaboost_src = adaboost.cpp $(adaboost_h)
radaboost.o: $(adaboost_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dadaboost.o: $(adaboost_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

stump_h = $(learnmodel_h) stump.h
stump_o = $(learnmodel_o) stump.o
stump_src = stump.cpp $(stump_h)
rstump.o: $(stump_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dstump.o: $(stump_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

cascade_h = $(aggregating_h) cascade.h
cascade_o = $(aggregating_o) cascade.o
cascade_src = cascade.cpp $(cascade_h)
rcascade.o: $(cascade_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dcascade.o: $(cascade_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

pulse_h = $(learnmodel_h) pulse.h
pulse_o = $(learnmodel_o) pulse.o
pulse_src = pulse.cpp $(pulse_h)
rpulse.o: $(pulse_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dpulse.o: $(pulse_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

cgboost_h = $(boosting_h) cgboost.h
cgboost_o = $(boosting_o) cgboost.o
cgboost_src = cgboost.cpp $(cgboost_h) $(vectorop_h) $(optimize_h)
rcgboost.o: $(cgboost_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dcgboost.o: $(cgboost_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

mgnboost_h = $(boosting_h) mgnboost.h
mgnboost_o = $(boosting_o) mgnboost.o
mgnboost_src = mgnboost.cpp $(optimize_h) $(mgnboost_h)
rmgnboost.o: $(mgnboost_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dmgnboost.o: $(mgnboost_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

## external module: LIBSVM ##
LIBSVM = ../../libsvm-2.81
libsvm_h = ${LIBSVM}/svm.h
libsvm_src = ${LIBSVM}/svm.cpp $(libsvm_h)
rlibsvm.o: $(libsvm_src)
	$(CC) -I${LIBSVM} $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dlibsvm.o: $(libsvm_src)
	$(CC) -I${LIBSVM} $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

svm_h = $(learnmodel_h) $(kernel_h) svm.h
svm_o = $(learnmodel_o) ${kernel_tmp_o} libsvm.o svm.o
svm_src = svm.cpp $(libsvm_h) $(svm_h)
rsvm.o: $(svm_src)
	$(CC) -I${LIBSVM} $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dsvm.o: $(svm_src)
	$(CC) -I${LIBSVM} $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

## external module: GLPK ##
## You'll have to configure/make/install GLPK before use.
GLPK = ../../../glpk-4.8
glpk_h = $(GLPK)/include/glpk.h
glpk_a = $(GLPK)/src/libglpk.a

lpboost_h = $(boosting_h) lpboost.h
lpboost_o = $(boosting_o) lpboost.o
lpboost_lib = $(glpk_a)
lpboost_src = lpboost.cpp $(lpboost_h) $(glpk_h)
rlpboost.o: $(lpboost_src)
	$(CC) -I${GLPK}/include $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dlpboost.o: $(lpboost_src)
	$(CC) -I${GLPK}/include $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

perceptron_h = $(learnmodel_h) $(svm_h) perceptron.h
perceptron_o = $(random_o) $(utility_o) $(svm_o) $(stump_o) perceptron.o
perceptron_src = perceptron.cpp $(random_h) $(utility_h) $(stump_h) \
	$(perceptron_h)
rperceptron.o: $(perceptron_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dperceptron.o: $(perceptron_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

multiclass_ecoc_h = $(aggregating_h) multiclass_ecoc.h
multiclass_ecoc_o = $(aggregating_o) multiclass_ecoc.o
multiclass_ecoc_src = multiclass_ecoc.cpp $(multiclass_ecoc_h)
rmulticlass_ecoc.o: $(multiclass_ecoc_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dmulticlass_ecoc.o: $(multiclass_ecoc_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

adaboost_ecoc_h = $(multiclass_ecoc_h) $(shared_ptr_h) adaboost_ecoc.h
adaboost_ecoc_o = $(multiclass_ecoc_o) $(random_o) adaboost_ecoc.o
adaboost_ecoc_src = adaboost_ecoc.cpp $(random_h) $(utility_h) \
	$(vectorop_h) $(adaboost_ecoc_h)
radaboost_ecoc.o: $(adaboost_ecoc_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dadaboost_ecoc.o: $(adaboost_ecoc_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

adaboost_erp_h = $(adaboost_ecoc_h) adaboost_erp.h
adaboost_erp_o = $(adaboost_ecoc_o) adaboost_erp.o
adaboost_erp_src = adaboost_erp.cpp $(adaboost_erp_h)
radaboost_erp.o: $(adaboost_erp_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dadaboost_erp.o: $(adaboost_erp_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<

ordinal_ble_h = $(learnmodel_h) $(multiclass_ecoc_h) ordinal_ble.h
ordinal_ble_o = $(learnmodel_o) ordinal_ble.o
ordinal_ble_src = ordinal_ble.cpp $(ordinal_ble_h)
rordinal_ble.o: $(ordinal_ble_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
dordinal_ble.o: $(ordinal_ble_src)
	$(CC) $(CC_FLAGS) $(CC_DEBUG) -c -o $@ $<
