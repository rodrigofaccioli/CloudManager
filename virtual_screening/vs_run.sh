#!/bin/bash -x

#Important 1: All paths must require the termination /  
#Important 2: Create a directory that contains all files
#Example: run_vs is the diretory that contains all files. These files will be copied to all nodes
# ./vs_run.sh nodefile /disco1/execute/run_vs/nubbe/pdbqt/ /disco1/execute/run_vs/receptor/pdbqt/ config_complexo_dm.txt config.ini /disco1/execute/vs_3u1i_complexo_dm/ /root/programs/drugdesign/virtualscreening/

nodefile=$1
path_of_pdbqt_ligands=$2
path_of_pdbqt_receptors=$3
config_vs=$4
config_vina=$5
path_execution_node=$6
path_drugdesign_vs_main=$7

here=$(pwd)

cd "$path_of_pdbqt_receptors"
find . -maxdepth 1 -type f -name "*.pdbqt" | sed 's/.\///g' > "$here""/""temporary_list_pdbqt"
cd "$here"
total_pdbqts=$(wc -l "temporary_list_pdbqt" | awk '{print $1}')


total_nodes=$(wc -l "$nodefile" | awk '{print $1}')

#creates the execution list for all nodes
rm "execution_list_"* 2>/dev/null
node=1
pdbqt=1
while [ $pdbqt -le $total_pdbqts ]; do

	node_name=$(head -n $node "$nodefile" | tail -n 1)
	pdbqt_name=$(head -n $pdbqt "temporary_list_pdbqt" | tail -n 1)

	echo "$pdbqt_name" >> "execution_list_""$node_name"

	if [ $node -eq $total_nodes ]; then
		node=1
	else
		let node=$node+1
	fi

	let pdbqt=$pdbqt+1
done

rm "temporary_list_pdbqt"


#send files necessary to run virtual screening to all nodes 
node=1
while [ $node -le $total_nodes ]; do

	node_name=$(head -n $node "$nodefile" | tail -n 1)
	#creating execution directory in node
	ssh "$node_name" mkdir -p "$path_execution_node"
	#coping the ligands to node
	path_ligand_node=$path_execution_node"ligand/"
	ssh $node_name mkdir -p $path_ligand_node
        all_ligands_source=$path_of_pdbqt_ligands"*"
	scp $all_ligands_source $node_name:$path_ligand_node
	#coping the receptors that will be ran in node
	path_receptor_node="$path_execution_node""receptor/"
	ssh $node_name mkdir -p $path_receptor_node
	total_receptors_node=$(wc -l "execution_list_""$node_name" | awk '{print $1}')
        exec_list_name="execution_list_""$node_name"
	n_recptors=1
	while [ $n_recptors -le $total_receptors_node ]; do
		name=$(head -n $n_recptors "$exec_list_name" | tail -n 1 )
        recep_path_filename=$path_of_pdbqt_receptors$name
		scp $recep_path_filename $node_name:$path_receptor_node
		let n_recptors=$n_recptors+1	
	done
	scp $config_vs $node_name:$path_execution_node
	scp $config_vina $node_name:$path_execution_node

	nohup ssh "$node_name" "cd ""$path_execution_node"" ; python ""$path_drugdesign_vs_main""vs_main.py "> /dev/null 2>&1&

	let node=$node+1
done