#Important: All paths must require termination with / 
#Example: gather.sh nodefile /disco1/execute/vs_3u1i_complexo_dm/ /disco1/execute/run_vs/

nodefile=$1
source_path=$2
destination_path=$3

here=$(pwd)

total_nodes=$(wc -l "$nodefile" | awk '{print $1}')

node=1
while [ $node -le $total_nodes ]; do

        node_name=$(head -n $node "$nodefile" | tail -n 1)

        echo -ne "Starting ""$node_name"" ..... \n"
        #coping log
        echo "Coping log .... "
        scp -r $node_name:$source_path"log/" $destination_path > /dev/null
        echo "OK"
        #coping structures
        echo "Coping structures ..... "
        scp -r $node_name:$source_path"structures/" $destination_path > /dev/null 
        echo "OK"
        #coping analysis
        echo "Coping analysis ....... "
        scp -r $node_name:$source_path"analysis/" $destination_path > /dev/null 
        echo "OK"

        echo -ne "Finished ""$node_name""\n"

        let node=$node+1
done