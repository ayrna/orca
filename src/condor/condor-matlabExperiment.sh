#!/bin/bash
#Check arguments
if [ $# != 1 ]; then
	echo "Usage:" $0 "name-of-experiment-file"
	exit 127
fi
# Capturamos la hora del sistema
DATE=`date +%F-%H.%M.%S`;

# Creamos un directorio especificado por la fecha y hora del sistema y el nombre del script a ejecutar
if [ ! -d "$DATE-$1" ]; then
	mkdir $DATE-$1
fi

# Conseguir el numero de experimentos para pasarselo a la cola del fichero condor-runExperiments
# Se va iterando por los distintos directorios calculando el numero de archivos de train y test con distinta configuracion a ejecutar
LINEAS=`cat $1 | grep dir -n`;
RUTAS=(`cat $1 |  grep dir --after-context=1 | grep -v dir | grep -v --regexp "--" | sed -e 's/\ //g'`)
total=0;
jR=0;
for i in $LINEAS
do
	ii=`echo $i | sed -e 's/:dir//g'`;
	j=`expr $ii + 4`;
	DATASETS=(`sed -n ''$ii','$j'p' $1 | grep datasets --after-context=1 | grep datasets -v | sed -e 's/\,/\n/g'`);
	for iii in `seq 1 ${#DATASETS[@]}`
	do
		iiii=`expr $iii - 1`;
		numFiles=`ls ${RUTAS[$jR]}/${DATASETS[$iiii]}/gpor/train_* -l | wc -l`;
		expresion="expr ( "$total" + "$numFiles" )";
		total=`$expresion`;
	done
	jR=`expr $jR + 1`;
done

# Copiamos los archivos a la carpeta para salvar la configuracion con la que se lanzo
cp *.submit $DATE-$1/
# Modificamos algunas etiquetas en el fichero .dag con las correspondientes a la ejecucion del trabajo actual
sed -e 's/FECHA_ACTUAL/'$DATE'/g' -e 's/SCRIPT_EJECUCION/'$1'/g' -e 's/NUMERO_RUNS/'$total'/g' condor-matlabFramework.dag > ./$DATE-$1/condor-matlabFramework.dag
# Enviamos el arbol de dependencias a utilizar a condor que se encargara finalmente de lanzar todos los procesos
condor_submit_dag ./$DATE-$1/condor-matlabFramework.dag
