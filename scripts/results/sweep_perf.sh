parallel --progress --bar --resume-failed --joblog ./log --gnu -j4 --header : \
        '   
    sh test.sh {#} {TOPO} {N} {RATE} {PAT} '\
            ::: TOPO BFT0 BFT1 BFT2 BFT3 \
            ::: PAT add20  amazon  bomhof_1  bomhof_2  bomhof_3  google  hamm  human  roadnet  simucad_dac  simucad_ram2k  soc  stanford  wiki \
            ::: N 64 \
            ::: RATE 100 \
