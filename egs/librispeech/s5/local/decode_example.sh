#!/bin/bash

# Copyright 2015  Guoguo Chen
# Apache 2.0
#
# Script that shows how to modify the language model, and how to run the
# decoding from scratch.

. ./cmd.sh || exit 1
. ./path.sh || exit 1

# Data directory, if you want to decode other audio files, change here,
datadir=test_clean_example

# Language model, if you want ot decode with another language model, change
# here.
lm=data/local/lm/lm_tgsmall.arpa.gz

modeldir=exp/nnet2_online/nnet_ms_a_online/
mfccdir=mfcc

# Compiles language model, if you want to modify the language model, change
# here.
lang=data/lang
lang_test=data/lang_test
lang_test_tmp=data/local/lang_test_tmp/
mkdir -p $lang_test_tmp
cp -rT $lang $lang_test
gunzip -c $lm | utils/find_arpa_oovs.pl $lang_test/words.txt \
  > $lang_test_tmp/oovs.txt || exit 1
gunzip -c $lm | \
  grep -v '<s> <s>' | \
  grep -v '</s> <s>' | \
  grep -v '</s> </s>' | \
  arpa2fst - | fstprint | \
  utils/remove_oovs.pl $lang_test_tmp/oovs.txt | \
  utils/eps2disambig.pl | utils/s2eps.pl | \
  fstcompile --isymbols=$lang_test/words.txt --osymbols=$lang_test/words.txt  \
  --keep_isymbols=false --keep_osymbols=false | \
  fstrmepsilon | fstarcsort --sort_type=ilabel > $lang_test/G.fst
utils/validate_lang.pl --skip-determinization-check $lang_test || exit 1;

# Compiles decoding graph.
graphdir=$modeldir/graph_test
utils/mkgraph.sh $lang_test $modeldir $graphdir || exit 1;

steps/online/nnet2/decode.sh --cmd "$decode_cmd" --nj 1 \
  $graphdir data/$datadir $modeldir/decode_${datadir}_test || exit 1;
