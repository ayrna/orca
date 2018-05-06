CC = g++
LEMGA = lemga-20060516/lemga

objs = boostrank-train boostrank-predict

all: $(objs)

.PHONY: clean $(addsuffix _clean, $(objs))
clean: $(addsuffix _clean, $(objs))

include ${LEMGA}/Makefile

VPATH = ${LEMGA}
ifeq ($(shell uname -s),Darwin)
	CC_FLAGS := -std=c++98 -Wno-unused-result -w -I${LEMGA} ${CC_FLAGS}
else
	CC_FLAGS := -std=c++98 -static-libgcc -Wno-unused-result -w -I${LEMGA} ${CC_FLAGS}
endif

softperc.o: softperc.cpp softperc.h
	$(CC) $(CC_FLAGS) -O3 -c -o $@ $<
aggrank.o: aggrank.cpp aggrank.h
	$(CC) $(CC_FLAGS) -O3 -c -o $@ $<
orboost.o: orboost.cpp orboost.h aggrank.h
	$(CC) $(CC_FLAGS) -O3 -c -o $@ $<
rankboost.o: rankboost.cpp rankboost.h aggrank.h
	$(CC) $(CC_FLAGS) -O3 -c -o $@ $<

boostrank_o  := $(stump_o) $(perceptron_o) $(aggregating_o) $(nnlayer_o) $(feedforwardnn_o) $(crossval_o) $(datafeeder_o)
boostrank_ro := $(addprefix  r, $(boostrank_o)) softperc.o \
		aggrank.o orboost.o rankboost.o

boostrank-train_src = boostrank-train.cpp aggrank.h orboost.h rankboost.h \
		$(stump_h) $(perceptron_h) $(nnlayer_h) $(feedforwardnn_h) $(crossval_h) $(datafeeder_h)\
		softperc.h

boostrank-train.o: $(boostrank-train_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
boostrank-train: $(boostrank_ro) boostrank-train.o
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
boostrank-train_clean:
	$(RM) $(boostrank_ro) \
		boostrank-train.o boostrank-train

boostrank-predict_src = boostrank-predict.cpp aggrank.h orboost.h rankboost.h \
		$(object_h) $(stump_h) $(perceptron_h) \
		softperc.h

boostrank-predict.o: $(boostrank-predict_src)
	$(CC) $(CC_FLAGS) $(CC_FINAL) -c -o $@ $<
boostrank-predict: $(boostrank_ro) boostrank-predict.o
	$(CC) $(CC_FLAGS) $(CC_FINAL) $(CC_LIB_FLAGS) -o $@ $^
boostrank-predict_clean:
	$(RM) $(boostrank_ro) \
		boostrank-predict.o boostrank-predict
