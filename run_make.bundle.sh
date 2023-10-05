#!/usr/bin/env bash

# 
# create a batch script to run on an HPC compute node, and (optionally) submit it
# can be used to build mpas-bundle or run mpas-bundle ctest
#
# For more information on submitting jobs to Cheyenne, see this documentation:
# https://arc.ucar.edu/knowledge_base/72581258
#
# For more information on submitting jobs to Derecho, see:
# https://arc.ucar.edu/knowledge_base/131596447
#

# name of script to create and submit to compute node
JOB_FILE="make.pbs.sh"

# vars for PBS directives
QUEUE=""
QUEUE_OPTS=""
ACCOUNT=""
NAME="mpas-compile"

# vars for setting the environment
HPC="unknown"
COMPILER=""
MODULES_USE=""
MODULES_PRE_CC=""
MODULES_CC=""
MODULES_POST_CC=""
MODULES=""

# vars for creating the batch script
PRECISION="single"
EXEC=""
DEFAULT_EXEC="make"
SOURCE_MODULES=""

# vars for controlling this script
RUN=""
HELP=""

# derecho params
DERECHO_CC="intel"
DERECHO_Q=("main" "develop" )
LUSTRE_DIR=/lustre/desc1/scratch/epicufsrt/contrib
SPACK_DIR=/glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.5.0/envs/unified-env/install/modulefiles
DERECHO_MOD_USE=( ${LUSTRE_DIR}/modulefiles ${LUSTRE_DIR}/modulefiles_extra $SPACK_DIR/Core )
DERECHO_MODS=( ecflow/5.8.4 mysql/8.0.33 stack-intel/2021.10.0 stack-cray-mpich/8.1.25 stack-python jedi-mpas-env)

# Cheyenne params
CHEYENNE_CC="gnu"
CHEYENNE_Q=("regular" "premium" "economy" "share")
CHEYENNE_MOD_USE=( /glade/work/jedipara/cheyenne/spack-stack/modulefiles/misc /glade/work/epicufsrt/contrib/spack-stack/spack-stack-1.4.0/envs/unified-env-v2/install/modulefiles/Core)
CHEYENNE_MODS_PRE_CC=( miniconda/3.9.12 ecflow/5.8.4 mysql/8.0.31 )
CHEYENNE_MODS_POST_CC=( stack-python/3.9.12 jedi-mpas-env/unified-dev)
# intel on cheyenne
CHEYENNE_CC_INTEL=stack-intel/19.1.1.217
CHEYENNE_CC_INTEL_MPI=stack-intel-mpi/2019.7.217
export F_UFMTENDIAN='big_endian:101-200'
# gnu on cheyenne
CHEYENNE_CC_GNU=stack-gcc/10.1.0
CHEYENNE_CC_GNU_MPI=stack-openmpi/4.1.1
export GFORTRAN_CONVERT_UNIT='big_endian:101-200'


usage()
{
	echo "usage: $0 -A account [-N name] [-q queue]"
	echo "  [-x make|ctest|echo] [-c compiler] [-p precision] [-f job-file] [-d] [-h]"
	echo
	echo "  account is the HPC account number"
	echo "  name is a name for the job, default is $NAME"
	echo "  queue is one of [ ${QUEUE_OPTS[@]} ], default is $QUEUE"
	echo "  -x to specify what to run, default is $DEFAULT_EXEC"
	echo "      use echo to submit a job which only sets the environment (for testing)"
	echo "  compiler is one of [ $DERECHO_CC $CHEYENNE_CC ], default is $COMPILER"
	echo "  precision is one of [ single double ], default is $PRECISION"
	echo "  job file is the file to be created and submitted to a compute node, default is $JOB_FILE"
	echo "  -d: don't submit the job to a compute node"
	echo "  -h: print help and exit"
	exit
}

#
# set up host specific elements
#
echo $HOST | grep -q cheyenne
if [ $? == 0 ]; then
	HPC="cheyenne"
else
	echo $HOST | grep -q derecho
	if [ $? == 0 ]; then
		HPC="derecho"
	fi
fi

if [ "$HPC" = "cheyenne" ]; then
	QUEUE="-q ${CHEYENNE_Q[0]}"
	QUEUE_OPTS=${CHEYENNE_Q[@]}
	COMPILER=$CHEYENNE_CC
	MODULES_USE=${CHEYENNE_MOD_USE[@]}
	MODULES_PRE_CC=${CHEYENNE_MODS_PRE_CC[@]}
	MODULES_POST_CC=${CHEYENNE_MODS_POST_CC[@]}
	SOURCE_MODULES="source /etc/profile.d/modules.sh"
elif [ "$HPC" = "derecho" ]; then
	QUEUE="-q ${DERECHO_Q[0]}"
	QUEUE_OPTS=${DERECHO_Q[@]}
	COMPILER=$DERECHO_CC
	MODULES_CC=${DERECHO_MODS[@]}
	MODULES_USE=${DERECHO_MOD_USE[@]}
else
	echo "unsupported HPC, must run on HPC login node"
	exit
fi

if [ $# == 0 ]; then
	usage
fi

# get comamnd line args
while getopts A:x:q:c:p:N:f:dh flag
do
	case "${flag}" in
		A) ACCOUNT=${OPTARG};;
		q) QUEUE="-q ${OPTARG}";;
		c) COMPILER=${OPTARG};;
		p) PRECISION=${OPTARG};;
		N) NAME=${OPTARG};;
		f) JOB_FILE=${OPTARG};;
		x) DEFAULT_EXEC=${OPTARG};;
		d) RUN="echo";;
		h) HELP="help"
	esac
done

if [ "$ACCOUNT" = "" ]; then
	echo "account (-A) is required"
	echo "   something like nmmm0004"
	echo
	usage
fi

if [ "$HELP" != "" ];then
	usage
fi

# check for alternate compiler on cheyenne
# TODO extend for derecho when the gnu toolschain is supported there
if [ "$HPC" == "cheyenne" ]; then
	if [ "$COMPILER" == "gnu" ]; then
		MODULES_CC="$CHEYENNE_CC_GNU $CHEYENNE_CC_GNU_MPI"
	elif [ "$COMPILER" == "intel" ]; then
		MODULES_CC="$CHEYENNE_CC_INTEL $CHEYENNE_CC_INTEL_MPI"
	else
		echo unknown compiler: $COMPILER, must be either "gnu" or "intel"
		echo
		usage
	fi
elif [ "$HPC" == "derecho" ]; then
	if [ "$COMPILER" != "intel" ]; then
		echo
		echo "Only intel is supported on $HPC, ignoring $COMPILER"
		echo
	fi
fi

# combine all of the modules to load, in the correct order
MODULES="$MODULES_PRE_CC $MODULES_CC $MODULES_POST_CC"

# don't overwrite the script file w/o acknowledgement
if [ -f "$JOB_FILE" ]; then
	echo "This will overwrite file: $JOB_FILE"
	echo "You can specify a different filename with -f"
	echo " continue [y/N]"
	read response
	if [ "$response" != "y" ]; then
		exit
	else
		rm -f $JOB_FILE
	fi
fi

if [ "$DEFAULT_EXEC" == "make" ]; then
	EXEC="$DEFAULT_EXEC -j8"
elif [ "$DEFAULT_EXEC" == "ctest" ]; then
	EXEC="export LD_LIBRARY_PATH=`pwd`/lib:$LD_LIBRARY_PATH && cd mpas-jedi && ctest"
elif [ "$DEFAULT_EXEC" == "echo" ]; then
	EXEC="echo finished"
else
	echo "unknown exec: $DEFAULT_EXEC"
	EXEC=""
fi

# inhibit expansion of mod_dir and module variables when creating script
mod_dir_var='$mod_dir'
mod_var='$module'

# create the bash script to run on a compute node
cat > $JOB_FILE << EOF
#!/usr/bin/env bash

#PBS -l walltime=01:00:00
#PBS -j oe
#PBS -k eod
#--- only need 8 cpus to compile
#PBS -l select=1:ncpus=8
#--- 
#PBS -N $NAME
#PBS -A $ACCOUNT
#PBS $QUEUE

date
module list

$SOURCE_MODULES

module purge
export LMOD_TMOD_FIND_FIRST=yes
for mod_dir in ${MODULES_USE}; do
	echo module use $mod_dir_var
	module use $mod_dir_var
done

for module in ${MODULES[@]}; do
	echo module load $mod_var
	module load $mod_var
done

module list

ulimit -s unlimited
export F_UFMTENDIAN='big_endian:101-200'
export GFORTRAN_CONVERT_UNIT='big_endian:101-200'
$EXEC

date
EOF

# submit the job to a compute node
if [ "$RUN" = "" ]; then
	echo Running qsub  $JOB_FILE
	qsub  $JOB_FILE
else
	echo created script $JOB_FILE
	echo To run it: qsub  $JOB_FILE
fi

