#! tcsh -f

if ($#argv != 3) then
	
	echo "Usage $0 build_type num_event number_jobs"
	exit 1;
	
endif

set build_type = $1;
set num_event = $2;
set number_jobs = $3;

set name = test-tracking-low-occupancy-qa_Event${num_event}_Sum${number_jobs}

if (! $?system_config) then       
  echo "system_config is undefined, use x8664_sl7"
  set system_config=x8664_sl7
else
  echo "use predefined system_config = ${system_config}"
endif

setenv OFFLINE_MAIN $WORKSPACE/install
echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.csh  $build_type;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.csh  $build_type;

# setenv PATH 		$WORKSPACE/install/bin:${PATH}
# setenv LD_LIBRARY_PATH 	$WORKSPACE/install/lib:${LD_LIBRARY_PATH}

echo "======================================================="
echo "${name}: Env check";
echo "======================================================="
env;

cd macros/macros/g4simulations/

#ln -svfb $WORKSPACE//coresoftware/offline/QA/macros/* ./

pwd;
ls -lhc

set id_number = 1
while ( $id_number <= $number_jobs )
   set job_name = job${id_number}
   
   	echo "======================================================="
	echo "${job_name}: Start test";
	echo "======================================================="

	(/usr/bin/time -v root -b -q "Fun4All_G4_sPHENIX.C(${num_event},"\"NullInput\"","\"G4sPHENIX_${job_name}\"")"   ; echo $? > exit_code_${id_number}.log ) &;
   
   sleep 1s;
   
   @ id_number++
end

wait;

set id_number = 1
while ( $id_number <= $number_jobs )
	set build_ret = `cat exit_code_${id_number}.log`;

	echo "Build step - build - return $build_ret";
	
	if ($build_ret != 0) then
		echo "======================================================="
		echo "Job index ${id_number}: Failed build with return = ${build_ret}. ";
		echo "======================================================="
		exit $build_ret;
	endif
   @ id_number++
end

ls -lhcrt


echo "======================================================="
echo "${name}: go to QA directory";
echo "======================================================="
cd ../QA/tracking/
pwd
ls -lhv

echo "======================================================="
echo "${name}: Merging output to G4sPHENIX_${name}_qa.root";
echo "======================================================="

hadd -f G4sPHENIX_${name}_qa.root $WORKSPACE/macros/macros/g4simulations/G4sPHENIX_job*_qa.root

echo "======================================================="
echo "${name}: Drawing G4sPHENIX_${name}_qa.root";
echo "======================================================="

echo "Reference file: with reference/G4sPHENIX_${name}_qa.root"
ls -lhvc reference/G4sPHENIX_*Sum*_qa.root

echo "use reference = ${use_reference}"

if (($? == 0) && (${use_reference} == "true")) then
	
	./QA_Draw_ALL.sh G4sPHENIX_${name}_qa.root reference/G4sPHENIX_*Sum*_qa.root

else
	
	./QA_Draw_ALL.sh G4sPHENIX_${name}_qa.root
	
endif


