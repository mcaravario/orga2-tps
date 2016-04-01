#!/bin/bash

DIFF=../bin/tp2diff
DIFFFLAGS=""
DATADIR=./data
INPUTDIR=$DATADIR/imagenes_a_testear
CATEDRADIR=$DATADIR/resultados_catedra
ALUMNOSDIR=$DATADIR/resultados_nuestros
TP2CAT=../bin/tpcatedra
TP2ALU=../bin/tp2

ROJO="\e[31m"
VERDE="\e[32m"
AZUL="\e[94m"
DEFAULT="\e[39m"

if [ $1 == "catedra" ]; then
	shift
    otro=$TP2CAT
	otrodir=$CATEDRADIR
	implementacion=$2
	otroimplementacion="c"
	filtro=$4
	mensaje="${AZUL}filtro $filtro version catedra contra tu $implementacion${DEFAULT}"
else
    otro=$TP2ALU
	otrodir=$ALUMNOSDIR

	implementacion=$2
	if [ $implementacion != "c" ]; then
		otroimplementacion="c"
	else
		otroimplementacion="asm"
	fi
	filtro=$4
	mensaje="${AZUL}filtro $filtro version c contra assembler${DEFAULT}"
fi

# argumentos que me vienen
archivo_in=$1
tolerancia=$3

shift 4   #descarto los argumentos que ya use

PARAMS=$@   # El resto de los argumentos 

echo -e $mensaje


archivo_out1=$($TP2ALU $filtro -n -i $implementacion     -o $ALUMNOSDIR/ $INPUTDIR/$archivo_in $PARAMS)
$TP2ALU $filtro -i $implementacion -o $ALUMNOSDIR/ $INPUTDIR/$archivo_in $PARAMS


archivo_out2=$($otro   $filtro -n -i $otroimplementacion -o $otrodir/    $INPUTDIR/$archivo_in $PARAMS)
$otro   $filtro -i $otroimplementacion -o $otrodir/    $INPUTDIR/$archivo_in $PARAMS

ALUFILE=$ALUMNOSDIR/$archivo_out1
OTROFILE=$otrodir/$archivo_out2

$DIFF $DIFFFLAGS $OTROFILE $ALUFILE $tolerancia

if [ $? != "0" ]; then
    echo -e "${ROJO}error en $FILENAME"
    exit -1
else
	echo -e "${VERDE}iguales!"
fi




