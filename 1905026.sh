#!/bin/bash

yacc -d -y -Wcounterexamples 1905026.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 1905026.l
echo 'Generated the scanner C file'
g++ -w -c -o l.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -lfl -g -o 1905026
echo 'All ready, running'
valgrind --leak-check=yes --track-origins=yes --log-file=valgrind-out.txt ./1905026 no_error.c
