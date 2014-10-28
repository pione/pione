#
# Eos for 3D reconstrucion from 2D rois using 3D initail reference 
#

.SUFFIXES: .3d .ref3d .ref2d .pad .padtmp .mask .maskfit .fit .fitmask .roi .corinfo .3dinfo .3dlst .3d .corinfo2 .corinfolst .cormap

SHELL=/bin/bash

-include ROIs
-include CORINFOs
-include PADs
-include 3DINFOs
-include 3DLIST

#
# Initial Reference Model 
INITIAL=initial
# Target structure name 
TARGET=all

# Simultaneous Jobs for AutoRotaionCorrelation
JOP_NUM=-j 3

#
# Search Area for 3D
#
ROTMODE=YOYS
# Rot1
ROT1MIN=0
ROT1MAX=359
ROT1D=30
nRot1=12
#
ROT2MIN=0
ROT2MAX=359
ROT2D=30
nRot2=12
# Rot3
ROT3MIN=0
ROT3MAX=0
ROT3D=30
nRot3=1
# For 2D 
STEP=12
ROTMIN=0
ROTMAX=359
nRot=`echo "" | awk 'BEGIN {printf 360 / $(STEP)}'`

# Seletion Step 
COR_THRESHOLD=0.4
Y_SHIFT_THRESHOLD=20

# Pad size for 2D 
PAD_W=64
PAD_H=64

###
### Initial model from PDB
###
REFSOURCE=121p-shift
DELTA=2.5
SIZE_X=64
SIZE_Y=64
SIZE_Z=64
START_X=`awk 'BEGIN { print -1*$(DELTA)*$(SIZE_X)/2}'`
START_Y=`awk 'BEGIN { print -1*$(DELTA)*$(SIZE_Y)/2}'`
START_Z=`awk 'BEGIN { print -1*$(DELTA)*$(SIZE_Z)/2}'`
SNRATIO=3
###############################

all:
	$(MAKE) ROIs;
	$(MAKE) $(JOP_NUM) pad;
	$(MAKE) PADs;
	$(MAKE) $(JOP_NUM) corinfo;
	$(MAKE) CORINFOs;
	$(MAKE) $(JOP_NUM) 3dinfo;
	$(MAKE) 3DINFOs;
	$(MAKE) $(JOP_NUM) 3dlst;
	$(MAKE) 3DLIST;
	$(MAKE) $(TARGET).3d;

clean:
	$(RM) -f *.pad *.padtmp *.mask *.cormap *.fit *.3dinfo *.3dinfolst *.corinfo
	$(RM) -f all.3dcounter all.3d all.3dlst
	$(RM) -f ROIs CORINFOs PADs 3DINFOs 3DLIST
	$(RM) -f .EosLog

##############

pad:$(ROIs:.roi=.pad)
corinfo:$(PADs:.pad=.corinfo)
3dinfo:$(CORINFOs:.corinfo=.3dinfo)
fit:$(ROIs:.roi=.fit)
3dlst:$(3DINFOs:.3dinfo=.3dlst)
3d:$(3DLIST:.3dlst=.3d)

##############

ROIs::
	touch ROIs
	echo "ROIs=\\" > ROIs
	find -name "*.roi" -type f | sed s/..// | xargs ls -1 | sed s/roi/roi\\\\/ >> ROIs
	echo "" >> ROIs

CORINFOs::
	touch CORINFOs
	echo "CORINFOs=\\" > CORINFOs
	find -name "*.corinfo" -type f | sed s/..// | xargs ls -1 | sed s/corinfo/corinfo\\\\/ >> CORINFOs
	echo "" >> CORINFOs

PADs::
	touch PADs
	echo "PADs=\\" > PADs
	find -name "*.pad" -type f | sed s/..// | xargs ls -1 | sed s/pad/pad\\\\/ >> PADs
	echo "" >> PADs

3DINFOs::
	touch 3DINFOs
	echo "3DINFOs=\\" > 3DINFOs
	find -name "*.3dinfo" -type f | sed s/..// | xargs ls -1 | sed s/3dinfo/3dinfo\\\\/ >> 3DINFOs
	echo "" >> 3DINFOs

3DLIST::
	touch 3DLIST
	echo "3DLIST=\\" > 3DLIST
	find -name "*.3dlst" -type f | sed s/..// | xargs ls -1 | sed s/3dlst/3dlst\\\\/ >> 3DLIST
	echo "" >> 3DLIST

#### Prepare Reference ####

.roi.pad:
	mrcImageWindowing -i $*.roi -o $*.mask -W 0.1 0.0 0.05 0.0 -m 18
	mrcImagePad -i $*.mask -o $*.padtmp -W $(PAD_W) -H $(PAD_H) -m 3
	mrcImageWindowing -i $*.padtmp -o $*.pad -W 0.1 0.0 0.1 0.0 -m 2 

.pad.corinfo:
	mrcImageAutoRotationCorrelation -i $*.pad -r $(TARGET).ref2d -O $*.corinfo -fit $*.fit -cor $*.cormap -n $(nRot) -m 18 -range $(ROTMIN) $(ROTMAX) -Iter 2 -nRot2 $(nRot2) -nRot1 $(nRot1) -nRot3 $(nRot3) 2> /dev/null

##############################################################################


.corinfo.3dinfo:
	awk '/Cor/ { print $$7,$$16,$$2,$$3,$$4,$$5,$$9,$$11,$$12}' $*.corinfo | sort -r | sed -e s/.pad/.fit/ > $*.3dinfolst
	head -n 1 $*.3dinfolst | awk '{print $$2,$$3,$$4,$$5,$$6,$$1}' > $*.3dinfo
##   ##18 -> ##7  ##

.3dinfo.3dlst:
	cat $*.3dinfo >> $(TARGET).3dlst

.3dlst.3d:
	mrc2Dto3D -I $(TARGET).3dlst -o $(TARGET).3d -InterpolationMode 2 -Double -DoubleCounter $(TARGET).3dcounter -CounterThreshold 0.5 -m 1 -WeightMode 2

