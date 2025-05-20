#!/bin/bash
matlab -nojvm -nodesktop -r "VL_BT('RVE.geom',[5,1,5,1,3]); exit;"
bash VL_BT.sh
